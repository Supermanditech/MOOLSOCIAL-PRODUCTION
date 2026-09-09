import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../shared/social_content_gateway.dart';
import 'work_models.dart';

const moolSocialWorkspaceUrl = String.fromEnvironment(
  'MOOLSOCIAL_WORKSPACE_URL',
);

class WorkGatewayException implements Exception {
  const WorkGatewayException(
    this.message, {
    this.retryable = false,
    this.cancelled = false,
  });
  final String message;
  final bool retryable;
  final bool cancelled;
  @override
  String toString() => message;
}

enum WorkProofSource { camera, gallery, upload, cloudDrive }

class WorkPickedProof {
  const WorkPickedProof({
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
}

abstract interface class WorkProofPicker {
  Future<WorkPickedProof?> pick(WorkProofSource source);
}

abstract interface class WorkRecoverableProofPicker implements WorkProofPicker {
  Future<WorkPickedProof?> recover(WorkProofSource source);
}

/// A short-lived checkpoint for one external document-picker operation.
/// OTP codes, tokens, document bytes and Workspace approvals are never stored.
abstract interface class WorkPendingProofStore {
  String? get accountScope;
  Future<Map<String, Object?>?> read(String scope);
  Future<void> save(String scope, Map<String, Object?> draft);
  Future<void> clear(String scope);
}

class SecureWorkPendingProofStore implements WorkPendingProofStore {
  SecureWorkPendingProofStore({this.reviewOnly = false})
    : _contactDraft = false;
  SecureWorkPendingProofStore.contactDraft({this.reviewOnly = false})
    : _contactDraft = true;
  final bool reviewOnly;
  final bool _contactDraft;
  static const _storage = FlutterSecureStorage();
  bool get _review =>
      reviewOnly &&
      kDebugMode &&
      const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY') &&
      const bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW');
  String get _key => _review
      ? 'moolsocial.workspace.pending-proof.review.v1'
      : 'moolsocial.workspace.pending-proof.v1';

  String _scopedKey(String scope) => _contactDraft
      ? 'moolsocial.workspace.contact-draft.${_review ? 'review.' : ''}v1.${Uri.encodeComponent(scope)}'
      : _key;

  @override
  String? get accountScope {
    if (_review) return 'isolated-workspace-ui-review';
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } on Object {
      return null;
    }
  }

  @override
  Future<Map<String, Object?>?> read(String scope) async {
    if (scope != accountScope) return null;
    final value = await _storage
        .read(key: _scopedKey(scope))
        .timeout(const Duration(seconds: 10));
    if (value == null || scope != accountScope) return null;
    final decoded = jsonDecode(value);
    if (decoded is! Map ||
        decoded['scope'] != scope ||
        decoded['draft'] is! Map) {
      return null;
    }
    return Map<String, Object?>.from(decoded['draft'] as Map);
  }

  @override
  Future<void> save(String scope, Map<String, Object?> draft) async {
    if (scope != accountScope) {
      throw const WorkGatewayException(
        'Sign in again before adding a document.',
      );
    }
    await _storage
        .write(
          key: _scopedKey(scope),
          value: jsonEncode({'scope': scope, 'draft': draft}),
        )
        .timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> clear(String scope) async {
    if (await read(scope) != null && scope == accountScope) {
      await _storage
          .delete(key: _scopedKey(scope))
          .timeout(const Duration(seconds: 10));
    }
  }
}

class NativeWorkProofPicker implements WorkRecoverableProofPicker {
  NativeWorkProofPicker({ImagePicker? imagePicker, this.documentPicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;
  final Future<XFile?> Function()? documentPicker;
  static const _maxProofBytes = 10 * 1024 * 1024;

  Future<Uint8List> _readDocument(XFile file) async {
    final reportedLength = await file.length();
    if (reportedLength <= 0 || reportedLength > _maxProofBytes) {
      throw const WorkGatewayException('Choose a document up to 10 MB.');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in file.openRead()) {
      if (bytes.length + chunk.length > _maxProofBytes) {
        throw const WorkGatewayException('Choose a document up to 10 MB.');
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  @override
  Future<WorkPickedProof?> pick(WorkProofSource source) async {
    try {
      if (source == WorkProofSource.upload ||
          source == WorkProofSource.cloudDrive) {
        XFile? file;
        String? selectedName;
        if (documentPicker != null) {
          file = await documentPicker!();
        } else {
          final selected = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
          );
          file = selected?.xFile;
          selectedName = selected?.name;
        }
        if (file == null) return null;
        final bytes = await _readDocument(file);
        return _validateProof(selectedName ?? file.name, bytes);
      }
      final image = await _imagePicker.pickImage(
        source: source == WorkProofSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (image == null) return null;
      return _pickedImage(image, source);
    } on WorkGatewayException {
      rethrow;
    } on PlatformException catch (error) {
      final denied =
          error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('permission');
      throw WorkGatewayException(
        denied
            ? 'Camera or photo access was denied. Allow access in device settings, then try again.'
            : 'The device could not open that option. Choose another way to add the document.',
      );
    } on FileSystemException {
      throw const WorkGatewayException(
        'That document could not be read. Choose it again.',
      );
    } on Object {
      throw const WorkGatewayException(
        'The device could not open that option. Choose another way to add the document.',
      );
    }
  }

  Future<WorkPickedProof> _pickedImage(
    XFile image,
    WorkProofSource source,
  ) async {
    final proof = _validateProof(image.name, await _readDocument(image));
    if (source != WorkProofSource.camera) return proof;
    return WorkPickedProof(
      fileName: 'Camera photo.${proof.fileName.split('.').last.toLowerCase()}',
      contentType: proof.contentType,
      bytes: proof.bytes,
    );
  }

  @override
  Future<WorkPickedProof?> recover(WorkProofSource source) async {
    try {
      final result = await _imagePicker.retrieveLostData();
      if (result.exception != null) {
        throw const WorkGatewayException(
          'The camera could not return the document. Please add it again.',
        );
      }
      final file = result.files?.firstOrNull;
      return file == null ? null : await _pickedImage(file, source);
    } on WorkGatewayException {
      rethrow;
    } on Object {
      throw const WorkGatewayException(
        'Your details are restored. Please add the document again.',
      );
    }
  }
}

class ReviewWorkProofPicker implements WorkProofPicker {
  @override
  Future<WorkPickedProof?> pick(
    WorkProofSource source,
  ) async => WorkPickedProof(
    fileName:
        source == WorkProofSource.upload || source == WorkProofSource.cloudDrive
        ? 'review-proof.pdf'
        : 'review-proof.jpg',
    contentType:
        source == WorkProofSource.upload || source == WorkProofSource.cloudDrive
        ? 'application/pdf'
        : 'image/jpeg',
    bytes: Uint8List.fromList(const [0xff, 0xd8, 0xff, 0xd9]),
  );
}

abstract interface class WorkProofUploadTransport {
  Future<void> put({
    required Uri url,
    required Map<String, String> headers,
    required Uint8List bytes,
  });
}

class IoWorkProofUploadTransport implements WorkProofUploadTransport {
  IoWorkProofUploadTransport({HttpClient? client})
    : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<void> put({
    required Uri url,
    required Map<String, String> headers,
    required Uint8List bytes,
  }) async {
    if (url.scheme != 'https' || !url.host.endsWith('googleapis.com')) {
      throw const WorkGatewayException(
        'Document upload could not be prepared. Choose the document again.',
      );
    }
    try {
      final request = await _client
          .putUrl(url)
          .timeout(const Duration(seconds: 15));
      request.contentLength = bytes.length;
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == 'content-length') continue;
        request.headers.set(entry.key, entry.value);
      }
      request.add(bytes);
      final response = await request.close().timeout(
        const Duration(seconds: 45),
      );
      await response.drain<void>();
      if ((response.statusCode >= 200 && response.statusCode < 300) ||
          response.statusCode == HttpStatus.preconditionFailed) {
        return;
      }
      throw WorkGatewayException(
        response.statusCode == HttpStatus.unauthorized ||
                response.statusCode == HttpStatus.forbidden
            ? 'Document upload expired. Choose the document again.'
            : 'Document could not upload. Check your connection and try again.',
        retryable:
            response.statusCode == HttpStatus.requestTimeout ||
            response.statusCode == HttpStatus.tooManyRequests ||
            response.statusCode >= 500,
      );
    } on WorkGatewayException {
      rethrow;
    } on TimeoutException {
      throw const WorkGatewayException(
        'Document upload timed out. Check your connection and try again.',
        retryable: true,
      );
    } on SocketException {
      throw const WorkGatewayException(
        'Document could not upload. Check your connection and try again.',
        retryable: true,
      );
    } on Object {
      throw const WorkGatewayException(
        'Document could not upload. Choose the document again.',
      );
    }
  }
}

class WorkProfileSubmission {
  const WorkProfileSubmission({
    required this.familyId,
    required this.profileId,
    required this.name,
    this.authorizedPersonName = '',
    this.businessRelationship = '',
    required this.area,
    required this.primaryActivity,
    required this.proofReferences,
    this.primaryMobile = '',
    this.email = '',
    this.alternateMobile = '',
    this.connectedProvider = '',
    this.connectedProviderAccount = '',
    required this.alternateMobileVerified,
    required this.idempotencyKey,
  });
  final String familyId;
  final String profileId;
  final String name;
  final String authorizedPersonName;
  final String businessRelationship;
  final String area;
  final String primaryActivity;
  final Map<String, String> proofReferences;
  final String primaryMobile;
  final String email;
  final String alternateMobile;
  final String connectedProvider;
  final String connectedProviderAccount;
  final bool alternateMobileVerified;
  final String idempotencyKey;
}

enum WorkRemoteReviewStatus { pending, approved, rejected, suspended, live }

class WorkReviewResult {
  const WorkReviewResult({
    required this.caseId,
    required this.status,
    required this.plan,
    this.workspaceId,
    this.reason,
    this.profileId,
    this.name,
    this.area,
    this.primaryActivity,
  });
  final String caseId;
  final WorkRemoteReviewStatus status;
  final String plan;
  final String? workspaceId;
  final String? reason;
  final String? profileId;
  final String? name;
  final String? area;
  final String? primaryActivity;
}

/// Version 1 order commands deliberately exclude payment, stock posting and
/// handover. Customer collection continues through its separately owned,
/// authenticated collection contract; a normal order reply cannot authorise it.
enum WorkOrderAction { accept, ready, reject }

enum WorkOrderReplyState { applied, rejected, pending }

enum WorkOrderOperationState { submitting, reconciling, uncertain }

class WorkOrderCommand {
  const WorkOrderCommand({
    required this.accountScope,
    required this.workspaceId,
    required this.orderId,
    required this.operationId,
    required this.expectedRevision,
    required this.action,
    this.reason,
  });

  static const contractVersion = 1;
  final String accountScope, workspaceId, orderId, operationId;
  final int expectedRevision;
  final WorkOrderAction action;
  final String? reason;
}

class WorkOrderReply {
  WorkOrderReply({
    required this.accountScope,
    required this.workspaceId,
    required this.orderId,
    required this.operationId,
    required this.revision,
    required this.state,
    WorkspaceOrderRecord? order,
  }) : order = order?.copyWith();

  final String accountScope, workspaceId, orderId, operationId;
  final int revision;
  final WorkOrderReplyState state;
  final WorkspaceOrderRecord? order;
}

/// Backend adapters must authenticate the account independently, enforce Store
/// permissions, expected revision and legal transitions, and deduplicate the
/// same operation atomically with all business effects. IDs are not credentials.
/// Reconcile is read-only: an unknown operation must not be submitted again
/// unless the authority explicitly resolves the original attempt as rejected.
abstract interface class WorkOrderCommandGateway {
  Future<WorkOrderReply> submitOrderCommand(WorkOrderCommand command);
  Future<WorkOrderReply> reconcileOrderCommand(WorkOrderCommand command);
}

/// A dedicated order journal, never a document draft or proof of success.
abstract interface class WorkOrderPendingStore {
  Future<List<WorkOrderCommand>> readPending(
    String accountScope,
    String workspaceId,
  );
  Future<void> savePending(WorkOrderCommand command);
  Future<void> removePending(WorkOrderCommand command);
}

class SecureWorkOrderPendingStore implements WorkOrderPendingStore {
  SecureWorkOrderPendingStore({
    FlutterSecureStorage? storage,
    String? Function()? currentAccount,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _currentAccount = currentAccount ?? _signedInAccount;

  final FlutterSecureStorage _storage;
  final String? Function() _currentAccount;
  // Across instances: timed-out callers must not release a still-running native
  // read/write and let a later write erase an independently pending order.
  static final Map<String, Future<void>> _tails = {};
  static String? _signedInAccount() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } on Object {
      return null;
    }
  }

  String _key(String account, String store) =>
      'moolsocial.workspace.order-pending.v1.${base64UrlEncode(utf8.encode(jsonEncode([account, store])))}';

  void _checkAccount(String account, String store) {
    if (account.isEmpty || store.isEmpty || _currentAccount() != account) {
      throw const WorkGatewayException('Sign in again to check this order.');
    }
  }

  Future<T> _serial<T>(String key, Future<T> Function() operation) {
    final previous = _tails[key] ?? Future<void>.value();
    final result = previous.then((_) => operation());
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _tails[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_tails[key], tail)) _tails.remove(key);
      }),
    );
    return result;
  }

  static Map<String, Object?> _encode(WorkOrderCommand command) => {
    'orderId': command.orderId,
    'operationId': command.operationId,
    'expectedRevision': command.expectedRevision,
    'action': command.action.name,
    'reason': command.reason,
  };

  static bool _valid(WorkOrderCommand command) =>
      command.orderId.trim().isNotEmpty &&
      command.operationId.trim().isNotEmpty &&
      command.expectedRevision >= 0 &&
      (command.action == WorkOrderAction.reject
          ? command.reason != null && command.reason!.trim().isNotEmpty
          : command.reason == null);

  Future<List<WorkOrderCommand>> _read(String account, String store) async {
    _checkAccount(account, store);
    final raw = await _storage.read(key: _key(account, store));
    _checkAccount(account, store);
    if (raw == null) return [];
    final data = jsonDecode(raw);
    if (data is! Map ||
        data['version'] != WorkOrderCommand.contractVersion ||
        data['accountScope'] != account ||
        data['workspaceId'] != store ||
        data['entries'] is! List) {
      throw const FormatException('Invalid pending order journal');
    }
    final commands = <WorkOrderCommand>[];
    final orders = <String>{}, operations = <String>{};
    for (final entry in data['entries'] as List) {
      if (entry is! Map ||
          entry['orderId'] is! String ||
          entry['operationId'] is! String ||
          entry['expectedRevision'] is! int ||
          entry['action'] is! String ||
          (entry['reason'] != null && entry['reason'] is! String)) {
        throw const FormatException('Invalid pending order entry');
      }
      final command = WorkOrderCommand(
        accountScope: account,
        workspaceId: store,
        orderId: entry['orderId'] as String,
        operationId: entry['operationId'] as String,
        expectedRevision: entry['expectedRevision'] as int,
        action: WorkOrderAction.values.byName(entry['action'] as String),
        reason: entry['reason'] as String?,
      );
      if (!_valid(command) ||
          !orders.add(command.orderId) ||
          !operations.add(command.operationId)) {
        throw const FormatException('Conflicting pending order entry');
      }
      commands.add(command);
    }
    return commands;
  }

  Future<void> _write(
    String account,
    String store,
    List<WorkOrderCommand> commands,
  ) async {
    _checkAccount(account, store);
    // Keep an empty envelope rather than deleting unrelated storage keys.
    await _storage.write(
      key: _key(account, store),
      value: jsonEncode({
        'version': WorkOrderCommand.contractVersion,
        'accountScope': account,
        'workspaceId': store,
        'entries': commands.map(_encode).toList(),
      }),
    );
    _checkAccount(account, store);
  }

  @override
  Future<List<WorkOrderCommand>> readPending(
    String accountScope,
    String workspaceId,
  ) => _serial(
    _key(accountScope, workspaceId),
    () => _read(accountScope, workspaceId),
  );

  @override
  Future<void> savePending(
    WorkOrderCommand command,
  ) => _serial(_key(command.accountScope, command.workspaceId), () async {
    if (!_valid(command)) throw const FormatException('Invalid order command');
    final commands = await _read(command.accountScope, command.workspaceId);
    for (final saved in commands) {
      if (saved.orderId == command.orderId ||
          saved.operationId == command.operationId) {
        if (jsonEncode(_encode(saved)) == jsonEncode(_encode(command))) return;
        throw const FormatException('Pending order cannot be overwritten');
      }
    }
    commands.add(command);
    await _write(command.accountScope, command.workspaceId, commands);
  });

  @override
  Future<void> removePending(WorkOrderCommand command) => _serial(
    _key(command.accountScope, command.workspaceId),
    () async {
      final commands = await _read(command.accountScope, command.workspaceId);
      final matches = commands
          .where((saved) => saved.orderId == command.orderId)
          .toList();
      if (matches.isEmpty) return;
      if (jsonEncode(_encode(matches.single)) != jsonEncode(_encode(command))) {
        throw const FormatException(
          'A different order operation remains pending',
        );
      }
      commands.removeWhere((saved) => saved.orderId == command.orderId);
      await _write(command.accountScope, command.workspaceId, commands);
    },
  );
}

/// Per-Store frontend reconciliation. It never posts inventory, payments,
/// invoices or collection completion. A/B operations may settle independently;
/// an uncertain A keeps its original identity and cannot be submitted twice.
/// The owning session must bind this to its authenticated account lifetime and
/// persist pending commands before enabling durable/relaunch qualification.
class WorkOrderOperations extends ChangeNotifier {
  WorkOrderOperations({
    required this.accountScope,
    required this.workspaceId,
    required this.gateway,
    this.pendingStore,
    this.timeout = const Duration(seconds: 15),
  });

  final String accountScope, workspaceId;
  final WorkOrderCommandGateway gateway;
  final WorkOrderPendingStore? pendingStore;
  final Duration timeout;
  final Map<String, WorkOrderReply> _orders = {};
  final Map<String, WorkOrderCommand> _pending = {};
  final Map<String, WorkOrderOperationState> _states = {};
  bool _disposed = false;
  String? _changedOrderId;
  bool _restored = false;
  Future<bool>? _restoring;

  bool get isDisposed => _disposed;
  bool get recoveryReady => pendingStore == null || _restored;
  String? get changedOrderId => _changedOrderId;
  List<WorkOrderReply> get orders => List.unmodifiable(_orders.values);

  void _emit(String orderId) {
    _changedOrderId = orderId;
    notifyListeners();
  }

  WorkOrderReply? order(String id) => _orders[id];
  WorkOrderCommand? pending(String id) => _pending[id];
  WorkOrderOperationState? state(String id) => _states[id];
  List<WorkOrderCommand> get pendingCommands =>
      List.unmodifiable(_pending.values);

  /// Complete before session binding. Corruption/read failure leaves new actions
  /// blocked; no restored command is automatically sent or treated as success.
  Future<bool> restore() {
    if (_disposed) return Future.value(false);
    if (recoveryReady) return Future.value(true);
    return _restoring ??= _restore().whenComplete(() => _restoring = null);
  }

  Future<bool> _restore() async {
    try {
      final commands = await pendingStore!
          .readPending(accountScope, workspaceId)
          .timeout(timeout);
      if (_disposed) return false;
      final orders = <String>{}, operations = <String>{};
      for (final command in commands) {
        if (command.accountScope != accountScope ||
            command.workspaceId != workspaceId ||
            accountScope.isEmpty ||
            workspaceId.isEmpty ||
            !SecureWorkOrderPendingStore._valid(command) ||
            !orders.add(command.orderId) ||
            !operations.add(command.operationId)) {
          return false;
        }
      }
      for (final command in commands) {
        _pending[command.orderId] = command;
        _states[command.orderId] = WorkOrderOperationState.uncertain;
      }
      _restored = true;
      for (final command in commands) {
        if (!_disposed) _emit(command.orderId);
      }
      return !_disposed;
    } on Object {
      return false;
    }
  }

  /// Restored local data is never success or permission. Only a read-only
  /// authoritative reconciliation may release a recovered operation lock.
  bool restorePending(WorkOrderCommand command) {
    if (_disposed ||
        pendingStore != null ||
        accountScope.isEmpty ||
        workspaceId.isEmpty ||
        command.accountScope != accountScope ||
        command.workspaceId != workspaceId ||
        command.orderId.isEmpty ||
        command.operationId.isEmpty ||
        command.expectedRevision < 0 ||
        _pending.containsKey(command.orderId) ||
        _pending.values.any(
          (item) => item.operationId == command.operationId,
        ) ||
        (command.action == WorkOrderAction.reject &&
            (command.reason == null || command.reason!.trim().isEmpty))) {
      return false;
    }
    _pending[command.orderId] = command;
    _states[command.orderId] = WorkOrderOperationState.uncertain;
    _emit(command.orderId);
    return true;
  }

  bool _belongs(WorkOrderReply reply) =>
      accountScope.isNotEmpty &&
      workspaceId.isNotEmpty &&
      reply.accountScope == accountScope &&
      reply.workspaceId == workspaceId &&
      reply.orderId.isNotEmpty &&
      reply.revision >= 0 &&
      reply.order?.id == reply.orderId &&
      reply.order!.amount >= 0 &&
      reply.order!.quantities.entries.every(
        (entry) => entry.key.isNotEmpty && entry.value > 0,
      ) &&
      (reply.order?.collectionStoreId == null ||
          reply.order?.collectionStoreId == workspaceId);

  /// Full snapshots can skip revisions; patches cannot use this entry point.
  /// Repeated/older events never replace a newer order or clear a pending action.
  bool observe(WorkOrderReply snapshot) {
    if (_disposed || !_belongs(snapshot)) return false;
    final previous = _orders[snapshot.orderId];
    if (previous != null && snapshot.revision <= previous.revision) {
      return false;
    }
    _orders[snapshot.orderId] = snapshot;
    _emit(snapshot.orderId);
    return true;
  }

  bool _allowed(WorkOrderReply snapshot, WorkOrderAction action) {
    final record = snapshot.order!;
    // Readiness and handover of authenticated customer collection remain under
    // the existing collection controller, not this general-order contract.
    if (record.isCustomerCollection || record.isClosed) return false;
    return switch (action) {
      WorkOrderAction.accept ||
      WorkOrderAction.reject => record.stage == 'Confirmed',
      WorkOrderAction.ready => record.stage == 'Preparing',
    };
  }

  Future<bool> act(String orderId, WorkOrderAction action, {String? reason}) {
    final snapshot = _orders[orderId];
    if (_disposed ||
        !recoveryReady ||
        _pending.containsKey(orderId) ||
        snapshot == null ||
        !_allowed(snapshot, action) ||
        (action == WorkOrderAction.reject &&
            (reason == null || reason.trim().isEmpty))) {
      return Future.value(false);
    }
    final random = Random.secure();
    final nonce = List.generate(16, (_) => random.nextInt(256));
    final command = WorkOrderCommand(
      accountScope: accountScope,
      workspaceId: workspaceId,
      orderId: orderId,
      operationId: 'STORE-ORDER-${base64UrlEncode(nonce)}',
      expectedRevision: snapshot.revision,
      action: action,
      reason: action == WorkOrderAction.reject ? reason!.trim() : null,
    );
    _pending[orderId] = command;
    return _run(command, reconcile: false);
  }

  Future<bool> retry(String orderId) {
    final command = _pending[orderId];
    if (_disposed ||
        !recoveryReady ||
        command == null ||
        _states[orderId] != WorkOrderOperationState.uncertain) {
      return Future.value(false);
    }
    return _run(command, reconcile: true);
  }

  Future<bool> _run(WorkOrderCommand command, {required bool reconcile}) async {
    _states[command.orderId] = reconcile
        ? WorkOrderOperationState.reconciling
        : WorkOrderOperationState.submitting;
    _emit(command.orderId);
    bool current() =>
        !_disposed && identical(_pending[command.orderId], command);
    try {
      if (!current()) return false;
      if (!reconcile && pendingStore != null) {
        await pendingStore!.savePending(command).timeout(timeout);
        if (!current()) return false;
      }
      final reply =
          await (reconcile
                  ? gateway.reconcileOrderCommand(command)
                  : gateway.submitOrderCommand(command))
              .timeout(timeout);
      if (!current()) return false;
      if (!_belongs(reply) ||
          reply.orderId != command.orderId ||
          reply.operationId != command.operationId ||
          reply.order!.isCustomerCollection ||
          reply.revision < command.expectedRevision ||
          (reply.state == WorkOrderReplyState.applied &&
              reply.revision <= command.expectedRevision) ||
          reply.state == WorkOrderReplyState.pending) {
        return false;
      }
      // A later full snapshot wins over this delayed acknowledgement. Resolving
      // its operation must not restore an older stage or replay business effects.
      final latest = _orders[command.orderId];
      if (latest == null || reply.revision > latest.revision) {
        _orders[command.orderId] = reply;
      }
      if (pendingStore != null) {
        await pendingStore!.removePending(command).timeout(timeout);
        if (!current()) return false;
      }
      _pending.remove(command.orderId);
      _states.remove(command.orderId);
      return reply.state == WorkOrderReplyState.applied;
    } catch (_) {
      // Network/parse failures are not authoritative rejections. Keep identity.
      return false;
    } finally {
      if (current()) {
        _states[command.orderId] = WorkOrderOperationState.uncertain;
      }
      if (!_disposed) _emit(command.orderId);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _orders.clear();
    _pending.clear();
    _states.clear();
    _changedOrderId = null;
    super.dispose();
  }
}

class WorkOperationalSnapshot {
  const WorkOperationalSnapshot({
    required this.workspaceId,
    required this.reason,
    required this.state,
    required this.idempotencyKey,
  });

  final String workspaceId;
  final String reason;
  final Map<String, Object?> state;
  final String idempotencyKey;
}

class WorkGroupBuySubmission {
  const WorkGroupBuySubmission({
    required this.workspaceId,
    required this.values,
    required this.idempotencyKey,
  });

  final String workspaceId;
  final Map<String, Object?> values;
  final String idempotencyKey;
}

class WorkPaidRequirementSubmission {
  const WorkPaidRequirementSubmission({
    required this.workspaceId,
    required this.values,
    required this.idempotencyKey,
  });

  final String workspaceId;
  final Map<String, Object?> values;
  final String idempotencyKey;
}

class WorkSettlementResult {
  const WorkSettlementResult({
    required this.reference,
    required this.acceptedAmount,
  });

  final String reference;
  final int acceptedAmount;
}

class WorkDeliveryAssignmentResult {
  const WorkDeliveryAssignmentResult({
    required this.partnerName,
    required this.vehicleLabel,
    required this.eta,
    required this.stage,
  });

  final String partnerName;
  final String vehicleLabel;
  final DateTime eta;
  final String stage;
}

/// Optional authenticated timing adapter. A request is not an order acceptance.
/// Implementations must reconcile repeated operation IDs and validate the
/// expected deadline, order state, store permission and current store workload.
abstract interface class WorkOrderTimeGateway {
  Future<WorkOrderTimeResult> requestOrderTime(WorkOrderTimeRequest request);
}

class WorkOrderTimeRequest {
  const WorkOrderTimeRequest({
    required this.workspaceId,
    required this.orderId,
    required this.operationId,
    required this.expectedAcceptanceDeadline,
    required this.additionalMinutes,
  });
  final String workspaceId, orderId, operationId;
  final DateTime expectedAcceptanceDeadline;
  final int additionalMinutes;
}

class WorkOrderTimeResult {
  const WorkOrderTimeResult({
    required this.workspaceId,
    required this.orderId,
    required this.operationId,
    required this.approved,
    this.acceptanceDeadline,
    this.fulfilmentDeadline,
  });
  final String workspaceId, orderId, operationId;
  final bool approved;
  final DateTime? acceptanceDeadline, fulfilmentDeadline;
}

abstract interface class WorkGateway {
  Future<List<WorkReviewResult>> loadFeed();
  Future<String> apply(String opportunityId);
  Future<void> withdraw(String applicationId, String opportunityId);
  Future<void> sendContactOtp({
    required WorkContactChannel channel,
    required String value,
  });
  Future<void> verifyContactOtp({
    required WorkContactChannel channel,
    required String value,
    required String code,
  });
  Future<String> saveProof(String proofId, WorkPickedProof proof);
  Future<WorkReviewResult> submitProfile(WorkProfileSubmission submission);
  Future<WorkReviewResult> submitCorrection(
    String caseId,
    WorkProfileSubmission submission,
  );
  Future<WorkReviewResult> checkReview(String caseId);
  Future<String> submitGst(String caseId, String gstin, String proofReference);
  Future<void> finishSetup({
    required String workspaceId,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    required bool homeDelivery,
    required bool storeCollection,
  });
  Future<void> saveOperationalState(WorkOperationalSnapshot snapshot);
  Future<String> createGroupBuy(WorkGroupBuySubmission submission);
  Future<String> createPaidRequirement(
    WorkPaidRequirementSubmission submission,
  );
  Future<WorkSettlementResult> requestSettlement({
    required String workspaceId,
    required int amount,
    required String idempotencyKey,
  });
  Future<void> verifyOrderHandover({
    required String workspaceId,
    required String orderId,
    required String otp,
    required String idempotencyKey,
  });
  Future<WorkDeliveryAssignmentResult> requestDeliveryAssignment({
    required String workspaceId,
    required String orderId,
    required String address,
    required String idempotencyKey,
  });
}

WorkGateway buildWorkGateway() {
  final endpoint = Uri.tryParse(moolSocialWorkspaceUrl.trim());
  if (endpoint == null ||
      endpoint.scheme != 'https' ||
      endpoint.host != 'asia-south1-moolsocial-dev-503018.cloudfunctions.net' ||
      endpoint.path != '/moolSocialWorkspace' ||
      endpoint.hasQuery ||
      endpoint.hasFragment) {
    return const UnavailableWorkGateway();
  }
  return AuthenticatedWorkGateway(
    endpoint: endpoint,
    credentials: FirebaseSocialContentCredentials(),
    transport: IoSocialContentTransport(),
  );
}

class UnavailableWorkGateway implements WorkGateway {
  const UnavailableWorkGateway();
  WorkGatewayException get _error => const WorkGatewayException(
    'Workspace service is unavailable right now. Your personal account remains active.',
    retryable: true,
  );
  @override
  Future<String> apply(String opportunityId) async => throw _error;
  @override
  Future<void> withdraw(String applicationId, String opportunityId) async =>
      throw _error;
  @override
  Future<WorkReviewResult> checkReview(String caseId) async => throw _error;
  @override
  Future<WorkReviewResult> submitCorrection(
    String caseId,
    WorkProfileSubmission submission,
  ) async => throw _error;
  @override
  Future<void> finishSetup({
    required String workspaceId,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    required bool homeDelivery,
    required bool storeCollection,
  }) async => throw _error;
  @override
  Future<void> saveOperationalState(WorkOperationalSnapshot snapshot) async =>
      throw _error;
  @override
  Future<String> createGroupBuy(WorkGroupBuySubmission submission) async =>
      throw _error;
  @override
  Future<String> createPaidRequirement(
    WorkPaidRequirementSubmission submission,
  ) async => throw _error;
  @override
  Future<WorkSettlementResult> requestSettlement({
    required String workspaceId,
    required int amount,
    required String idempotencyKey,
  }) async => throw _error;
  @override
  Future<void> verifyOrderHandover({
    required String workspaceId,
    required String orderId,
    required String otp,
    required String idempotencyKey,
  }) async => throw _error;
  @override
  Future<WorkDeliveryAssignmentResult> requestDeliveryAssignment({
    required String workspaceId,
    required String orderId,
    required String address,
    required String idempotencyKey,
  }) async => throw _error;
  @override
  Future<List<WorkReviewResult>> loadFeed() async => throw _error;
  @override
  Future<String> saveProof(String proofId, WorkPickedProof proof) async =>
      throw _error;
  @override
  Future<void> sendContactOtp({
    required WorkContactChannel channel,
    required String value,
  }) async => throw _error;
  @override
  Future<void> verifyContactOtp({
    required WorkContactChannel channel,
    required String value,
    required String code,
  }) async => throw _error;
  @override
  Future<WorkReviewResult> submitProfile(
    WorkProfileSubmission submission,
  ) async => throw _error;
  @override
  Future<String> submitGst(
    String caseId,
    String gstin,
    String proofReference,
  ) async => throw _error;
}

class AuthenticatedWorkGateway implements WorkGateway {
  AuthenticatedWorkGateway({
    required this.endpoint,
    required this.credentials,
    required this.transport,
    WorkProofUploadTransport? proofUploadTransport,
    Random? random,
  }) : proofUploadTransport =
           proofUploadTransport ?? IoWorkProofUploadTransport(),
       random = random ?? Random.secure();
  final Uri endpoint;
  final SocialContentCredentials credentials;
  final SocialContentTransport transport;
  final WorkProofUploadTransport proofUploadTransport;
  final Random random;

  @override
  Future<List<WorkReviewResult>> loadFeed() async {
    final data = _map(await _invoke('listWorkspaces', const {}));
    final items = data['workspaces'];
    if (items is! List) {
      throw const WorkGatewayException(
        'Workspace returned an invalid response. Try again.',
        retryable: true,
      );
    }
    return items.map((item) => _decodeReview(_map(item))).toList();
  }

  @override
  Future<String> apply(String opportunityId) async => _requiredString(
    _map(
      await _invoke('applyOpportunity', {
        'opportunityId': opportunityId,
      }, mutation: true),
    )['applicationId'],
  );
  @override
  Future<void> withdraw(String applicationId, String opportunityId) => _invoke(
    'withdrawOpportunity',
    {'applicationId': applicationId, 'opportunityId': opportunityId},
    mutation: true,
  );
  @override
  Future<void> sendContactOtp({
    required WorkContactChannel channel,
    required String value,
  }) => _invoke('sendWorkspaceContactOtp', {
    'channel': channel.apiValue,
    'value': value,
  }, mutation: true);
  @override
  Future<void> verifyContactOtp({
    required WorkContactChannel channel,
    required String value,
    required String code,
  }) => _invoke('verifyWorkspaceContactOtp', {
    'channel': channel.apiValue,
    'value': value,
    'code': code,
  }, mutation: true);
  @override
  Future<String> saveProof(String proofId, WorkPickedProof proof) async {
    final prepared = _map(
      await _invoke('prepareProofUpload', {
        'proofId': proofId,
        'fileName': proof.fileName,
        'contentType': proof.contentType,
        'sizeBytes': proof.bytes.length,
      }, mutation: true),
    );
    final uploadUrl = Uri.tryParse(_requiredString(prepared['uploadUrl']));
    final expiresAt = DateTime.tryParse(_requiredString(prepared['expiresAt']));
    if (uploadUrl == null ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now())) {
      throw const WorkGatewayException(
        'Document upload could not be prepared. Choose the document again.',
        retryable: true,
      );
    }
    final headers = _map(
      prepared['requiredHeaders'],
    ).map((key, value) => MapEntry(key, _requiredString(value)));
    await proofUploadTransport.put(
      url: uploadUrl,
      headers: headers,
      bytes: proof.bytes,
    );
    return _requiredString(
      _map(
        await _invoke('confirmProofUpload', {
          'proofId': proofId,
          'uploadId': _requiredString(prepared['uploadId']),
          'fileName': proof.fileName,
          'contentType': proof.contentType,
          'sizeBytes': proof.bytes.length,
        }, mutation: true),
      )['proofReference'],
    );
  }

  @override
  Future<WorkReviewResult> submitProfile(WorkProfileSubmission value) async =>
      _decodeReview(
        _map(
          await _invoke('submitProfile', {
            'familyId': value.familyId,
            'profileId': value.profileId,
            'name': value.name,
            'authorizedPersonName': value.authorizedPersonName,
            'businessRelationship': value.businessRelationship,
            'area': value.area,
            'primaryActivity': value.primaryActivity,
            'proofReferences': value.proofReferences,
            'primaryMobile': value.primaryMobile,
            'email': value.email,
            'alternateMobile': value.alternateMobile,
            'connectedProvider': value.connectedProvider,
            'connectedProviderAccount': value.connectedProviderAccount,
            'alternateMobileVerified': value.alternateMobileVerified,
            'idempotencyKey': value.idempotencyKey,
          }, mutation: true),
        ),
      );
  @override
  Future<WorkReviewResult> submitCorrection(
    String caseId,
    WorkProfileSubmission value,
  ) async => throw const WorkGatewayException(
    'Sending corrections to an existing review is not available yet. Your changes remain saved; contact MoolSocial Support for this review.',
    retryable: false,
  );
  @override
  Future<WorkReviewResult> checkReview(String caseId) async =>
      _decodeReview(_map(await _invoke('reviewStatus', {'caseId': caseId})));
  @override
  Future<String> submitGst(
    String caseId,
    String gstin,
    String proofReference,
  ) async => _requiredString(
    _map(
      await _invoke('submitGst', {
        'caseId': caseId,
        'gstin': gstin,
        'proofReference': proofReference,
      }, mutation: true),
    )['gstReference'],
  );
  @override
  Future<void> finishSetup({
    required String workspaceId,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    required bool homeDelivery,
    required bool storeCollection,
  }) => _invoke('finishRetailerSetup', {
    'workspaceId': workspaceId,
    'quantity': quantity,
    'buyPrice': buyPrice,
    'sellPrice': sellPrice,
    'homeDelivery': homeDelivery,
    'storeCollection': storeCollection,
  }, mutation: true);

  @override
  Future<void> saveOperationalState(WorkOperationalSnapshot snapshot) =>
      _invoke('saveWorkspaceOperations', {
        'workspaceId': snapshot.workspaceId,
        'reason': snapshot.reason,
        'state': snapshot.state,
        'idempotencyKey': snapshot.idempotencyKey,
      }, mutation: true);

  @override
  Future<String> createGroupBuy(WorkGroupBuySubmission submission) async =>
      _requiredString(
        _map(
          await _invoke('createWorkspaceGroupBuy', {
            'workspaceId': submission.workspaceId,
            'values': submission.values,
            'idempotencyKey': submission.idempotencyKey,
          }, mutation: true),
        )['paymentReference'],
      );

  @override
  Future<String> createPaidRequirement(
    WorkPaidRequirementSubmission submission,
  ) async => _requiredString(
    _map(
      await _invoke('createWorkspacePaidRequirement', {
        'workspaceId': submission.workspaceId,
        'values': submission.values,
        'idempotencyKey': submission.idempotencyKey,
      }, mutation: true),
    )['reference'],
  );

  @override
  Future<WorkSettlementResult> requestSettlement({
    required String workspaceId,
    required int amount,
    required String idempotencyKey,
  }) async {
    final result = _map(
      await _invoke('requestWorkspaceSettlement', {
        'workspaceId': workspaceId,
        'amount': amount,
        'idempotencyKey': idempotencyKey,
      }, mutation: true),
    );
    return WorkSettlementResult(
      reference: _requiredString(result['reference']),
      acceptedAmount: (result['acceptedAmount'] as num?)?.round() ?? amount,
    );
  }

  @override
  Future<void> verifyOrderHandover({
    required String workspaceId,
    required String orderId,
    required String otp,
    required String idempotencyKey,
  }) => _invoke('verifyWorkspaceOrderHandover', {
    'workspaceId': workspaceId,
    'orderId': orderId,
    'otp': otp,
    'idempotencyKey': idempotencyKey,
  }, mutation: true);

  @override
  Future<WorkDeliveryAssignmentResult> requestDeliveryAssignment({
    required String workspaceId,
    required String orderId,
    required String address,
    required String idempotencyKey,
  }) async {
    final result = _map(
      await _invoke('requestWorkspaceDelivery', {
        'workspaceId': workspaceId,
        'orderId': orderId,
        'address': address,
        'idempotencyKey': idempotencyKey,
      }, mutation: true),
    );
    final eta = DateTime.tryParse(_requiredString(result['eta']));
    if (eta == null) {
      throw const WorkGatewayException(
        'Delivery assignment returned an invalid arrival time.',
        retryable: true,
      );
    }
    return WorkDeliveryAssignmentResult(
      partnerName: _requiredString(result['partnerName']),
      vehicleLabel: _requiredString(result['vehicleLabel']),
      eta: eta,
      stage: _requiredString(result['stage']),
    );
  }

  Future<Object?> _invoke(
    String operation,
    Map<String, Object?> body, {
    bool mutation = false,
  }) async {
    final response = await transport.postJson(
      endpoint,
      headers: {
        'accept': 'application/json',
        'authorization': 'Bearer ${await credentials.firebaseIdToken()}',
        'x-firebase-appcheck': await credentials.appCheckToken(
          mutation
              ? SocialAppCheckTokenMode.limitedUse
              : SocialAppCheckTokenMode.standard,
        ),
        'x-request-id': List<int>.generate(
          16,
          (_) => random.nextInt(256),
        ).map((value) => value.toRadixString(16).padLeft(2, '0')).join(),
      },
      body: {'operation': operation, ...body},
    );
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const WorkGatewayException(
        'Workspace returned an invalid response. Try again.',
        retryable: true,
      );
    }
    final envelope = _map(decoded);
    if (envelope['ok'] == true) return envelope['data'];
    final error = _map(envelope['error']);
    throw WorkGatewayException(
      _requiredString(error['message']),
      retryable: error['retryable'] == true,
    );
  }
}

enum WorkReviewTestCase { pending, clarification, rejected, approved }

class ReviewWorkGateway implements WorkGateway {
  ReviewWorkGateway({WorkRemoteReviewStatus? initialReviewStatus})
    : reviewResultStatus =
          initialReviewStatus ??
          (kDebugMode &&
                  const bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
                  const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY')
              ? WorkRemoteReviewStatus.pending
              : WorkRemoteReviewStatus.approved);

  bool failFeed = false;
  bool failApplication = false;
  bool failWithdrawal = false;
  bool failOtp = false;
  bool failProof = false;
  bool failSubmission = false;
  bool failReview = false;
  WorkRemoteReviewStatus reviewResultStatus;
  final Map<String, String> _reviewWorkspaceIds = {};
  final Set<String> _submittedReviewCases = {};
  final Map<String, WorkReviewTestCase> _selectedReviewCases = {};
  late final String _deviceReviewIdentity =
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
      '${Random.secure().nextInt(1 << 32).toRadixString(36)}';

  bool get deviceReviewControlsEnabled =>
      kDebugMode &&
      const bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
      const bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY');

  bool canSelectDeviceReviewCase(String caseId) =>
      deviceReviewControlsEnabled && _submittedReviewCases.contains(caseId);

  void selectDeviceReviewCase(String caseId, WorkReviewTestCase scenario) {
    if (!canSelectDeviceReviewCase(caseId)) {
      throw const WorkGatewayException('Review test cases are unavailable.');
    }
    _selectedReviewCases[caseId] = scenario;
  }

  String? reviewResultReason;
  bool failGst = false;
  bool failSetup = false;
  int applicationCalls = 0;
  int withdrawalCalls = 0;
  int otpCalls = 0;
  int otpVerificationCalls = 0;
  WorkContactChannel? lastOtpChannel;
  String? lastOtpValue;
  WorkProfileSubmission? lastSubmission;
  int proofCalls = 0;
  int submissionCalls = 0;
  int correctionCalls = 0;
  int reviewCalls = 0;
  int gstCalls = 0;
  int setupCalls = 0;
  int operationalSaveCalls = 0;
  int groupBuyCalls = 0;
  int paidRequirementCalls = 0;
  int settlementCalls = 0;
  int handoverCalls = 0;
  int deliveryAssignmentCalls = 0;
  WorkOperationalSnapshot? lastOperationalSnapshot;
  WorkGroupBuySubmission? lastGroupBuySubmission;
  WorkPaidRequirementSubmission? lastPaidRequirementSubmission;
  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 24));
  @override
  Future<List<WorkReviewResult>> loadFeed() async {
    await _wait();
    if (failFeed) {
      failFeed = false;
      throw const WorkGatewayException(
        'Work could not be refreshed. Check your connection and try again.',
      );
    }
    return const [];
  }

  @override
  Future<String> apply(String opportunityId) async {
    applicationCalls++;
    await _wait();
    if (failApplication) {
      failApplication = false;
      throw const WorkGatewayException(
        'Application was not sent. Your opportunity is still saved.',
      );
    }
    return 'APP-${opportunityId.toUpperCase()}-${1200 + applicationCalls}';
  }

  @override
  Future<void> withdraw(String applicationId, String opportunityId) async {
    withdrawalCalls++;
    await _wait();
    if (failWithdrawal) {
      failWithdrawal = false;
      throw const WorkGatewayException(
        'Application could not be withdrawn. It remains active; try again.',
        retryable: true,
      );
    }
  }

  @override
  Future<void> sendContactOtp({
    required WorkContactChannel channel,
    required String value,
  }) async {
    otpCalls++;
    lastOtpChannel = channel;
    lastOtpValue = value;
    await _wait();
    if (failOtp) {
      failOtp = false;
      throw const WorkGatewayException(
        'OTP could not be sent. Check the number and try again.',
      );
    }
  }

  @override
  Future<void> verifyContactOtp({
    required WorkContactChannel channel,
    required String value,
    required String code,
  }) async {
    otpVerificationCalls++;
    lastOtpChannel = channel;
    lastOtpValue = value;
    await _wait();
    if (code != '123456') {
      throw const WorkGatewayException('That code does not match. Try again.');
    }
  }

  @override
  Future<String> saveProof(String proofId, WorkPickedProof proof) async {
    proofCalls++;
    await _wait();
    if (failProof) {
      failProof = false;
      throw const WorkGatewayException(
        'Document not added. Choose the same file or another option and try again.',
      );
    }
    return 'PROOF-${proofId.toUpperCase()}-$proofCalls';
  }

  @override
  Future<WorkReviewResult> submitProfile(WorkProfileSubmission value) async {
    submissionCalls++;
    lastSubmission = value;
    await _wait();
    if (failSubmission) {
      failSubmission = false;
      throw const WorkGatewayException(
        'Workspace profile was not submitted. Your details and documents remain saved.',
      );
    }
    final caseId = deviceReviewControlsEnabled
        ? 'WP-$_deviceReviewIdentity-$submissionCalls'
        : 'WP-${240700 + submissionCalls}';
    _submittedReviewCases.add(caseId);
    return WorkReviewResult(
      caseId: caseId,
      status: WorkRemoteReviewStatus.pending,
      plan: 'free',
    );
  }

  @override
  Future<WorkReviewResult> submitCorrection(
    String caseId,
    WorkProfileSubmission value,
  ) async {
    correctionCalls++;
    lastSubmission = value;
    await _wait();
    if (failSubmission) {
      failSubmission = false;
      throw const WorkGatewayException(
        'Workspace corrections were not sent. Your changes remain saved.',
      );
    }
    _selectedReviewCases.remove(caseId);
    return WorkReviewResult(
      caseId: caseId,
      status: WorkRemoteReviewStatus.pending,
      plan: 'free',
    );
  }

  @override
  Future<WorkReviewResult> checkReview(String caseId) async {
    reviewCalls++;
    await _wait();
    if (failReview) {
      failReview = false;
      throw const WorkGatewayException(
        'Review update is unavailable. No duplicate request was created.',
      );
    }
    final scenario = deviceReviewControlsEnabled
        ? _selectedReviewCases[caseId]
        : null;
    final status = switch (scenario) {
      WorkReviewTestCase.pending ||
      WorkReviewTestCase.clarification => WorkRemoteReviewStatus.pending,
      WorkReviewTestCase.rejected => WorkRemoteReviewStatus.rejected,
      WorkReviewTestCase.approved => WorkRemoteReviewStatus.approved,
      null => reviewResultStatus,
    };
    final reason = switch (scenario) {
      WorkReviewTestCase.clarification =>
        'Please add a readable shop address document and check the business name.',
      WorkReviewTestCase.rejected =>
        'The submitted business details could not be verified. Contact MoolSocial for help.',
      WorkReviewTestCase.pending || WorkReviewTestCase.approved => null,
      null => reviewResultReason,
    };
    return WorkReviewResult(
      caseId: caseId,
      status: status,
      reason: reason,
      plan: 'free',
      workspaceId:
          status == WorkRemoteReviewStatus.approved ||
              status == WorkRemoteReviewStatus.live
          ? _reviewWorkspaceIds.putIfAbsent(
              caseId,
              () => deviceReviewControlsEnabled
                  ? 'WK-$_deviceReviewIdentity-${_reviewWorkspaceIds.length + 1}'
                  : 'WK-${510001 + _reviewWorkspaceIds.length}',
            )
          : null,
    );
  }

  @override
  Future<String> submitGst(
    String caseId,
    String gstin,
    String proofReference,
  ) async {
    gstCalls++;
    await _wait();
    if (failGst) {
      failGst = false;
      throw const WorkGatewayException(
        'GST certificate was not submitted. Your Workspace review is still active.',
      );
    }
    return 'GST-$gstCalls';
  }

  @override
  Future<void> finishSetup({
    required String workspaceId,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    required bool homeDelivery,
    required bool storeCollection,
  }) async {
    setupCalls++;
    await _wait();
    if (failSetup) {
      failSetup = false;
      throw const WorkGatewayException(
        'Shop setup was not completed. Product and fulfilment choices remain saved.',
      );
    }
  }

  @override
  Future<void> saveOperationalState(WorkOperationalSnapshot snapshot) async {
    operationalSaveCalls++;
    lastOperationalSnapshot = snapshot;
    await _wait();
  }

  @override
  Future<String> createGroupBuy(WorkGroupBuySubmission submission) async {
    groupBuyCalls++;
    lastGroupBuySubmission = submission;
    await _wait();
    return 'PAY-GROUP-${1200 + groupBuyCalls}';
  }

  @override
  Future<String> createPaidRequirement(
    WorkPaidRequirementSubmission submission,
  ) async {
    paidRequirementCalls++;
    lastPaidRequirementSubmission = submission;
    await _wait();
    return 'WORK-REQ-${1200 + paidRequirementCalls}';
  }

  @override
  Future<WorkSettlementResult> requestSettlement({
    required String workspaceId,
    required int amount,
    required String idempotencyKey,
  }) async {
    settlementCalls++;
    await _wait();
    return WorkSettlementResult(
      reference: 'SET-${1200 + settlementCalls}',
      acceptedAmount: amount,
    );
  }

  @override
  Future<void> verifyOrderHandover({
    required String workspaceId,
    required String orderId,
    required String otp,
    required String idempotencyKey,
  }) async {
    handoverCalls++;
    await _wait();
    if (otp != '123456') {
      throw const WorkGatewayException(
        'Enter the 6-digit delivery OTP shared by the customer.',
      );
    }
  }

  @override
  Future<WorkDeliveryAssignmentResult> requestDeliveryAssignment({
    required String workspaceId,
    required String orderId,
    required String address,
    required String idempotencyKey,
  }) async {
    deliveryAssignmentCalls++;
    await _wait();
    return WorkDeliveryAssignmentResult(
      partnerName: 'Review delivery partner',
      vehicleLabel: 'Review vehicle',
      eta: DateTime.now().add(const Duration(minutes: 15)),
      stage: 'Assigned',
    );
  }
}

WorkPickedProof _validateProof(String fileName, Uint8List bytes) {
  final extension = fileName.split('.').last.toLowerCase();
  final contentType = switch (extension) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => throw const WorkGatewayException(
      'Choose a PDF, JPG, PNG or WebP document.',
    ),
  };
  if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
    throw const WorkGatewayException('Choose a document up to 10 MB.');
  }
  // Match the existing local preview boundary before replacing an attachment.
  // A signature is not proof of readability or server-side document validity.
  if (contentType == 'application/pdf' &&
      (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-')) {
    throw const WorkGatewayException(
      'This PDF could not be opened. Choose another copy.',
    );
  }
  return WorkPickedProof(
    fileName: fileName,
    contentType: contentType,
    bytes: bytes,
  );
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) {
    throw const WorkGatewayException(
      'Workspace returned an invalid response. Try again.',
      retryable: true,
    );
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _requiredString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const WorkGatewayException(
      'Workspace returned an invalid response. Try again.',
      retryable: true,
    );
  }
  return value.trim();
}

WorkReviewResult _decodeReview(Map<String, Object?> data) => WorkReviewResult(
  caseId: _requiredString(data['caseId']),
  status: switch (_requiredString(data['status'])) {
    'approved' => WorkRemoteReviewStatus.approved,
    'rejected' => WorkRemoteReviewStatus.rejected,
    'suspended' => WorkRemoteReviewStatus.suspended,
    'live' => WorkRemoteReviewStatus.live,
    _ => WorkRemoteReviewStatus.pending,
  },
  plan: _requiredString(data['plan']),
  workspaceId: data['workspaceId'] is String
      ? _requiredString(data['workspaceId'])
      : null,
  reason: data['reason'] is String ? _requiredString(data['reason']) : null,
  profileId: data['profileId'] is String
      ? _requiredString(data['profileId'])
      : null,
  name: data['name'] is String ? _requiredString(data['name']) : null,
  area: data['area'] is String ? _requiredString(data['area']) : null,
  primaryActivity: data['primaryActivity'] is String
      ? _requiredString(data['primaryActivity'])
      : null,
);
