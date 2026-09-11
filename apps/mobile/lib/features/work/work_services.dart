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
import 'package:crypto/crypto.dart' as crypto;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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
    this.recoveryPath,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
  final String? recoveryPath;

  Map<String, Object?>? get recoveryRecord => recoveryPath == null
      ? null
      : {
          'name': fileName,
          'contentType': contentType,
          'path': recoveryPath!,
          'size': bytes.length,
          'sha256': crypto.sha256.convert(bytes).toString(),
        };
}

abstract interface class WorkProofPicker {
  Future<WorkPickedProof?> pick(WorkProofSource source);
}

abstract interface class WorkRecoverableProofPicker implements WorkProofPicker {
  Future<WorkPickedProof?> recover(WorkProofSource source);
}

abstract interface class WorkRetainedProofPicker implements WorkProofPicker {
  Future<WorkPickedProof?> restoreRecorded(Map<String, Object?> record);
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

abstract interface class WorkIssueDraftStore {
  Future<WorkspaceIssueDraft?> read(WorkspaceIssueDraftKey key);
  Future<void> save(WorkspaceIssueDraft draft);
}

/// Separate encrypted keys per account, Store and case. Drafts contain no OTP,
/// customer collection challenge, payment credential or decision authority.
class SecureWorkIssueDraftStore implements WorkIssueDraftStore {
  SecureWorkIssueDraftStore({
    required this.accountScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  String _key(WorkspaceIssueDraftKey key) =>
      'moolsocial.workspace.issue-draft.v1.'
      '${[key.account, key.store, key.caseId].map(Uri.encodeComponent).join('/')}';

  @override
  Future<WorkspaceIssueDraft?> read(WorkspaceIssueDraftKey key) async {
    if (key.account != accountScope()) return null;
    final value = await _storage
        .read(key: _key(key))
        .timeout(const Duration(seconds: 10));
    if (value == null || key.account != accountScope()) return null;
    final draft = WorkspaceIssueDraft.fromJson(jsonDecode(value));
    if (draft == null || draft.key != key) {
      throw const WorkGatewayException(
        'Your saved response could not be opened.',
      );
    }
    return draft;
  }

  @override
  Future<void> save(WorkspaceIssueDraft draft) async {
    if (!draft.valid || draft.key.account != accountScope()) {
      throw const WorkGatewayException('Sign in again to save your response.');
    }
    await _storage
        .write(key: _key(draft.key), value: jsonEncode(draft.toJson()))
        .timeout(const Duration(seconds: 10));
    if (draft.key.account != accountScope()) {
      throw const WorkGatewayException(
        'Sign in again to check your saved response.',
      );
    }
  }
}

abstract interface class WorkReceiptDraftStore {
  Future<WorkspaceReceiptDraft?> read(WorkspaceReceiptDraftKey key);
  Future<void> save(
    WorkspaceReceiptDraft draft, {
    required int? expectedRevision,
  });
}

/// Encrypted recovery of unsent receiving observations, never receipt authority.
/// Serialize reads/writes across local instances and compare the retained draft
/// revision. A slow native write must finish before a newer edit can be saved.
class SecureWorkReceiptDraftStore implements WorkReceiptDraftStore {
  SecureWorkReceiptDraftStore({
    required this.accountScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  static final Map<String, Future<void>> _pending = {};

  String _key(WorkspaceReceiptDraftKey key) =>
      'moolsocial.workspace.receipt-draft.v1.'
      '${[key.account, key.store, key.shipment].map(Uri.encodeComponent).join('/')}';

  Future<T> _exclusive<T>(String key, Future<T> Function() action) {
    final result = (_pending[key] ?? Future<void>.value()).then(
      (_) => action(),
    );
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_pending[key], tail)) _pending.remove(key);
      }),
    );
    return result;
  }

  void _check(WorkspaceReceiptDraftKey key) {
    if ([
          key.account,
          key.store,
          key.shipment,
        ].any((value) => value.trim().isEmpty) ||
        accountScope() != key.account) {
      throw const WorkGatewayException(
        'Sign in again to open this delivery draft.',
      );
    }
  }

  Future<WorkspaceReceiptDraft?> _read(WorkspaceReceiptDraftKey key) async {
    _check(key);
    final value = await _storage.read(key: _key(key));
    _check(key);
    if (value == null) return null;
    WorkspaceReceiptDraft? draft;
    try {
      draft = WorkspaceReceiptDraft.fromJson(jsonDecode(value));
    } on FormatException {
      // Corrupt retained bytes are not an empty draft that may be overwritten.
    }
    if (draft == null || draft.key != key) {
      throw const WorkGatewayException(
        'Your saved delivery draft could not be opened.',
      );
    }
    return draft;
  }

  @override
  Future<WorkspaceReceiptDraft?> read(WorkspaceReceiptDraftKey key) =>
      _exclusive(_key(key), () => _read(key));

  @override
  Future<void> save(
    WorkspaceReceiptDraft draft, {
    required int? expectedRevision,
  }) => _exclusive(_key(draft.key), () async {
    _check(draft.key);
    if (!draft.valid ||
        (expectedRevision != null && expectedRevision < 1) ||
        draft.revision != (expectedRevision ?? 0) + 1) {
      throw const WorkGatewayException(
        'This delivery draft could not be saved.',
      );
    }
    final current = await _read(draft.key);
    final value = jsonEncode(draft.toJson());
    if (current != null && jsonEncode(current.toJson()) == value) return;
    if (current?.revision != expectedRevision) {
      throw const WorkGatewayException(
        'This delivery draft changed. Open the saved version first.',
      );
    }
    // Counts/problem/note can change; purchased identity and its source
    // snapshot cannot silently follow today's refreshed supplier catalogue.
    if (current != null) {
      final previous = current.toJson()
        ..remove('revision')
        ..remove('countedPacks')
        ..remove('problems')
        ..remove('note');
      final next = draft.toJson()
        ..remove('revision')
        ..remove('countedPacks')
        ..remove('problems')
        ..remove('note');
      if (jsonEncode(previous) != jsonEncode(next)) {
        throw const WorkGatewayException(
          'Keep the original delivery details with this draft.',
        );
      }
    }
    _check(draft.key);
    await _storage.write(key: _key(draft.key), value: value);
    _check(draft.key);
  });
}

abstract interface class WorkCounterDraftStore {
  Future<WorkspaceCounterDraft?> read(String account, String store);
  Future<void> save(
    WorkspaceCounterDraft draft, {
    required int? expectedRevision,
  });
}

/// Device-local encrypted recovery, not an order/payment completion journal.
/// A submitting draft cannot be restored as editable work. Its exact operation
/// must be reconciled by the caller before retiring it. Keep a revisioned
/// tombstone after discard/completion so delayed edits cannot revive the sale.
class SecureWorkCounterDraftStore implements WorkCounterDraftStore {
  SecureWorkCounterDraftStore({
    required this.accountScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  static final Map<String, Future<void>> _pending = {};

  String _key(String account, String store) =>
      'moolsocial.workspace.counter-draft.v1.'
      '${Uri.encodeComponent(account)}/${Uri.encodeComponent(store)}';

  // Serialize across session/store instances in the UI isolate. Do not time
  // out a native write and release the queue while that write can still land.
  // Distributed/cross-device concurrency belongs to the backend, not this key.
  Future<T> _exclusive<T>(String key, Future<T> Function() action) {
    final result = (_pending[key] ?? Future<void>.value()).then(
      (_) => action(),
    );
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_pending[key], tail)) _pending.remove(key);
      }),
    );
    return result;
  }

  void _checkAccount(String account, String store) {
    if (account.trim().isEmpty ||
        store.trim().isEmpty ||
        accountScope() != account) {
      throw const WorkGatewayException('Sign in again to recover this bill.');
    }
  }

  Future<WorkspaceCounterDraft?> _read(String account, String store) async {
    _checkAccount(account, store);
    final value = await _storage.read(key: _key(account, store));
    _checkAccount(account, store);
    if (value == null) return null;
    WorkspaceCounterDraft? draft;
    try {
      draft = WorkspaceCounterDraft.fromJson(jsonDecode(value));
    } on FormatException {
      // Invalid retained bytes are not an empty bill and must not be replaced.
    }
    if (draft == null || draft.account != account || draft.store != store) {
      throw const WorkGatewayException('Your saved bill could not be opened.');
    }
    return draft;
  }

  @override
  Future<WorkspaceCounterDraft?> read(String account, String store) =>
      _exclusive(_key(account, store), () => _read(account, store));

  @override
  Future<void> save(
    WorkspaceCounterDraft draft, {
    required int? expectedRevision,
  }) => _exclusive(_key(draft.account, draft.store), () async {
    _checkAccount(draft.account, draft.store);
    if (!draft.valid ||
        (expectedRevision != null && expectedRevision < 1) ||
        draft.revision != (expectedRevision ?? 0) + 1) {
      throw const WorkGatewayException('This bill could not be saved.');
    }
    final current = await _read(draft.account, draft.store);
    final value = jsonEncode(draft.toJson());
    if (current != null && jsonEncode(current.toJson()) == value) {
      return; // Same write retried after an uncertain local result.
    }
    if (current?.stage == WorkspaceCounterDraftStage.submitting &&
        draft.stage == WorkspaceCounterDraftStage.reviewRequired &&
        jsonEncode({
              ...current!.toJson(),
              'revision': draft.revision,
              'stage': draft.stage.name,
            }) !=
            value) {
      throw const WorkGatewayException(
        'Keep the saved bill unchanged during recovery.',
      );
    }
    if (current?.revision != expectedRevision ||
        (draft.stage == WorkspaceCounterDraftStage.reviewRequired &&
            current?.stage != WorkspaceCounterDraftStage.submitting) ||
        (current == null &&
            draft.stage != WorkspaceCounterDraftStage.editing) ||
        (current != null &&
            (current.id == draft.id
                ? current.stage == WorkspaceCounterDraftStage.retired ||
                      (current.stage == WorkspaceCounterDraftStage.submitting &&
                          ((draft.stage != WorkspaceCounterDraftStage.retired &&
                                  draft.stage !=
                                      WorkspaceCounterDraftStage
                                          .reviewRequired) ||
                              draft.submissionOrderId !=
                                  current.submissionOrderId)) ||
                      (current.stage ==
                              WorkspaceCounterDraftStage.reviewRequired &&
                          draft.stage != WorkspaceCounterDraftStage.editing &&
                          draft.stage != WorkspaceCounterDraftStage.retired)
                : current.stage != WorkspaceCounterDraftStage.retired ||
                      draft.stage != WorkspaceCounterDraftStage.editing))) {
      throw const WorkGatewayException(
        'This saved bill changed. Reopen it before continuing.',
      );
    }
    _checkAccount(draft.account, draft.store);
    await _storage.write(key: _key(draft.account, draft.store), value: value);
    _checkAccount(draft.account, draft.store);
  });
}

enum WorkIssueReplyState { applied, rejected, pending, notRecorded }

enum WorkIssueResponseError {
  permissionDenied,
  caseChanged,
  caseClosed,
  responseUnavailable,
  invalidDetails;

  String get instruction => switch (this) {
    permissionDenied => 'You do not have permission to respond to this case.',
    caseChanged =>
      'This case changed. Review the latest update before responding.',
    caseClosed => 'This case is closed. Your draft has been kept.',
    responseUnavailable =>
      'This response is no longer available. Review the case.',
    invalidDetails => 'Check your response details and try again.',
  };
}

/// V1 case-response command. The purchasing line snapshot is immutable, and
/// this command never doubles as a refund, receipt, substitution or handover.
class WorkIssueCommand {
  WorkIssueCommand({
    required this.operationId,
    required this.draft,
    required this.kind,
    required List<WorkspaceIssueLine> lines,
  }) : lines = List.unmodifiable(lines);
  final String operationId;
  final WorkspaceIssueDraft draft;
  final WorkspaceIssueKind kind;
  final List<WorkspaceIssueLine> lines;
  WorkspaceIssueDraftKey get key => draft.key;
  bool get valid =>
      draft.valid &&
      draft.response != null &&
      RegExp(r'^STORE-ISSUE-[A-Za-z0-9_-]{22,64}$').hasMatch(operationId) &&
      (draft.response == WorkspaceIssueResponse.acceptRequest ||
          draft.note.trim().isNotEmpty) &&
      lines.isNotEmpty &&
      lines.every((line) => line.valid) &&
      lines.map((line) => line.lineId).toSet().length == lines.length;

  Map<String, Object?> toJson() => {
    'version': 1,
    'operationId': operationId,
    'draft': draft.toJson(),
    'kind': kind.name,
    'lines': [
      for (final line in lines)
        {
          'lineId': line.lineId,
          'productId': line.productId,
          'name': line.name,
          'pack': line.pack,
          'orderedQuantity': line.orderedQuantity,
          'affectedQuantity': line.affectedQuantity,
        },
    ],
  };

  /// SHA-256 over UTF-8 JSON in the exact V1 field order above. Not a credential.
  String get digest =>
      crypto.sha256.convert(utf8.encode(jsonEncode(toJson()))).toString();

  static WorkIssueCommand? fromJson(Object? value) {
    if (value is! Map ||
        value['version'] != 1 ||
        value['operationId'] is! String ||
        value['lines'] is! List) {
      return null;
    }
    final draft = WorkspaceIssueDraft.fromJson(value['draft']);
    final kind = WorkspaceIssueKind.values
        .where((k) => k.name == value['kind'])
        .firstOrNull;
    if (draft == null || kind == null) return null;
    final lines = <WorkspaceIssueLine>[];
    for (final line in value['lines'] as List) {
      if (line is! Map ||
          line['lineId'] is! String ||
          line['productId'] is! String ||
          line['name'] is! String ||
          line['pack'] is! String ||
          line['orderedQuantity'] is! int ||
          line['affectedQuantity'] is! int) {
        return null;
      }
      lines.add(
        WorkspaceIssueLine(
          lineId: line['lineId'],
          productId: line['productId'],
          name: line['name'],
          pack: line['pack'],
          orderedQuantity: line['orderedQuantity'],
          affectedQuantity: line['affectedQuantity'],
        ),
      );
    }
    final command = WorkIssueCommand(
      operationId: value['operationId'],
      draft: draft,
      kind: kind,
      lines: lines,
    );
    return command.valid ? command : null;
  }
}

/// Applied means the response was recorded once, not that the case was approved.
/// The case feed separately supplies its next status. Unknown/timeout stays pending.
class WorkIssueReply {
  const WorkIssueReply({
    required this.key,
    required this.operationId,
    required this.commandDigest,
    required this.state,
    this.revision,
    this.error,
  });
  final WorkspaceIssueDraftKey key;
  final String operationId, commandDigest;
  final WorkIssueReplyState state;
  final int? revision;
  final WorkIssueResponseError? error;
  bool matches(WorkIssueCommand command) =>
      key == command.key &&
      operationId == command.operationId &&
      commandDigest == command.digest &&
      switch (state) {
        WorkIssueReplyState.applied =>
          error == null &&
              revision != null &&
              revision! > command.draft.expectedRevision,
        WorkIssueReplyState.rejected => error != null,
        WorkIssueReplyState.pending ||
        WorkIssueReplyState.notRecorded => error == null,
      };
  Map<String, Object?> toJson() => {
    'account': key.account,
    'store': key.store,
    'caseId': key.caseId,
    'operationId': operationId,
    'commandDigest': commandDigest,
    'state': state.name,
    'revision': revision,
    'error': error?.name,
  };
  static WorkIssueReply? fromJson(Object? value) {
    if (value is! Map ||
        value['account'] is! String ||
        value['store'] is! String ||
        value['caseId'] is! String ||
        value['operationId'] is! String ||
        value['commandDigest'] is! String ||
        (value['revision'] != null && value['revision'] is! int)) {
      return null;
    }
    final state = WorkIssueReplyState.values
        .where((s) => s.name == value['state'])
        .firstOrNull;
    final error = WorkIssueResponseError.values
        .where((s) => s.name == value['error'])
        .firstOrNull;
    if (state == null || (value['error'] != null && error == null)) return null;
    return WorkIssueReply(
      key: (
        account: value['account'],
        store: value['store'],
        caseId: value['caseId'],
      ),
      operationId: value['operationId'],
      commandDigest: value['commandDigest'],
      state: state,
      revision: value['revision'],
      error: error,
    );
  }
}

class WorkIssueSubmission {
  const WorkIssueSubmission(this.command, [this.reply]);
  final WorkIssueCommand command;
  final WorkIssueReply? reply;
  bool get pending =>
      reply == null ||
      {
        WorkIssueReplyState.pending,
        WorkIssueReplyState.notRecorded,
      }.contains(reply!.state);
  bool get valid => command.valid && (reply == null || reply!.matches(command));
  Map<String, Object?> toJson() => {
    'version': 1,
    'command': command.toJson(),
    'reply': reply?.toJson(),
  };
  static WorkIssueSubmission? fromJson(Object? value) {
    if (value is! Map || value['version'] != 1) return null;
    final command = WorkIssueCommand.fromJson(value['command']);
    final reply = WorkIssueReply.fromJson(value['reply']);
    if (command == null || (value['reply'] != null && reply == null)) {
      return null;
    }
    final submission = WorkIssueSubmission(command, reply);
    return submission.valid ? submission : null;
  }
}

/// Authenticate independently; validate Store role, exact case/line/revision and
/// permitted response; atomically deduplicate operation+digest with the response.
/// Reconcile is read-only. Unknown is pending, never permission for a fresh ID.
/// A notRecorded reply permits retry of the SAME operation and payload only;
/// atomic deduplication must protect a racing/delayed original attempt as well.
/// A rejected receipt guarantees this operation recorded no case response.
abstract interface class WorkIssueCommandGateway {
  Future<WorkIssueReply> submitIssueResponse(WorkIssueCommand command);
  Future<WorkIssueReply> reconcileIssueResponse(WorkIssueCommand command);
}

abstract interface class WorkIssueCommandStore {
  Future<WorkIssueSubmission?> read(WorkspaceIssueDraftKey key);
  Future<void> save(WorkIssueSubmission submission);
}

class SecureWorkIssueCommandStore implements WorkIssueCommandStore {
  SecureWorkIssueCommandStore({
    required this.accountScope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();
  final String? Function() accountScope;
  final FlutterSecureStorage _storage;
  String _key(WorkspaceIssueDraftKey key) =>
      'moolsocial.workspace.issue-command.v1.'
      '${[key.account, key.store, key.caseId].map(Uri.encodeComponent).join('/')}';
  @override
  Future<WorkIssueSubmission?> read(WorkspaceIssueDraftKey key) async {
    if (key.account != accountScope()) return null;
    final value = await _storage
        .read(key: _key(key))
        .timeout(const Duration(seconds: 10));
    if (value == null || key.account != accountScope()) return null;
    final submission = WorkIssueSubmission.fromJson(jsonDecode(value));
    if (submission == null || submission.command.key != key) {
      throw const WorkGatewayException(
        'Your response status could not be opened.',
      );
    }
    return submission;
  }

  @override
  Future<void> save(WorkIssueSubmission submission) async {
    if (!submission.valid || submission.command.key.account != accountScope()) {
      throw const WorkGatewayException('Sign in again to check your response.');
    }
    await _storage
        .write(
          key: _key(submission.command.key),
          value: jsonEncode(submission.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    if (submission.command.key.account != accountScope()) {
      throw const WorkGatewayException('Sign in again to check your response.');
    }
  }
}

/// Read-only, authenticated stock history. Cursors and the immutable snapshot
/// are bound to this exact account/Store/date/product scope. Never apply the
/// returned deltas to local stock, and never include private purchase costs.
abstract interface class WorkStockHistoryGateway {
  Future<WorkspaceStockHistoryPage> readStockHistory(
    WorkspaceStockHistoryQuery query, {
    String? cursor,
    String? snapshotId,
  });
}

class NativeWorkProofPicker
    implements WorkRecoverableProofPicker, WorkRetainedProofPicker {
  NativeWorkProofPicker({
    ImagePicker? imagePicker,
    this.documentPicker,
    Future<Directory> Function()? temporaryDirectory,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final ImagePicker _imagePicker;
  final Future<XFile?> Function()? documentPicker;
  final Future<Directory> Function() _temporaryDirectory;
  static const _maxProofBytes = 10 * 1024 * 1024;

  @override
  Future<WorkPickedProof?> restoreRecorded(Map<String, Object?> record) async {
    final path = record['path'];
    final name = record['name'];
    final type = record['contentType'];
    final size = record['size'];
    final digest = record['sha256'];
    if (path is! String ||
        name is! String ||
        type is! String ||
        size is! int ||
        size <= 0 ||
        size > _maxProofBytes ||
        digest is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
      return null;
    }
    try {
      final root = await (await _temporaryDirectory()).resolveSymbolicLinks();
      final file = File(path);
      final resolved = await file.resolveSymbolicLinks();
      // Never reopen arbitrary provider paths, shared storage or symlink escapes.
      if (!resolved.startsWith('$root${Platform.pathSeparator}')) return null;
      final bytes = await _readDocument(XFile(resolved));
      if (bytes.length != size ||
          crypto.sha256.convert(bytes).toString() != digest) {
        return null;
      }
      final proof = _validateProof(name, bytes);
      if (proof.contentType != type) return null;
      return WorkPickedProof(
        fileName: proof.fileName,
        contentType: proof.contentType,
        bytes: proof.bytes,
        recoveryPath: resolved,
      );
    } on Object {
      return null;
    }
  }

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
        final proof = _validateProof(selectedName ?? file.name, bytes);
        return WorkPickedProof(
          fileName: proof.fileName,
          contentType: proof.contentType,
          bytes: proof.bytes,
          recoveryPath: file.path,
        );
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
    return WorkPickedProof(
      fileName: source == WorkProofSource.camera
          ? 'Camera photo.${proof.fileName.split('.').last.toLowerCase()}'
          : proof.fileName,
      contentType: proof.contentType,
      bytes: proof.bytes,
      recoveryPath: image.path,
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

/// Version 2 adds authoritative time requests; commands exclude payment, stock posting and
/// handover. Customer collection continues through its separately owned,
/// authenticated collection contract; a normal order reply cannot authorise it.
enum WorkOrderAction { accept, ready, reject, requestTime }

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
    this.additionalMinutes,
    this.expectedAcceptanceDeadline,
    this.version = contractVersion,
  });

  static const contractVersion = 2;
  final String accountScope, workspaceId, orderId, operationId;
  final int expectedRevision;
  final WorkOrderAction action;
  final String? reason;
  final int version;
  final int? additionalMinutes;
  final DateTime? expectedAcceptanceDeadline;
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
    this.delivery,
  }) : order = order?.copyWith();

  final String accountScope, workspaceId, orderId, operationId;
  final int revision;
  final WorkOrderReplyState state;
  final WorkspaceOrderRecord? order;

  /// Full order-scoped projection. Null removes a previous assignment; callers
  /// must not submit partial order events here. Collection uses its own contract.
  final WorkspaceDeliveryAssignment? delivery;
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

/// Explicit capability: legacy timing endpoints are not revisioned commands.
abstract interface class WorkOrderTimeCommandGateway
    implements WorkOrderCommandGateway {
  bool get supportsOrderTimeRequests;
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
  static const _journalVersion = 1;
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
    'version': command.version,
    'orderId': command.orderId,
    'operationId': command.operationId,
    'expectedRevision': command.expectedRevision,
    'action': command.action.name,
    'reason': command.reason,
    'additionalMinutes': command.additionalMinutes,
    'expectedAcceptanceDeadline': command.expectedAcceptanceDeadline
        ?.toUtc()
        .toIso8601String(),
  };

  static bool _valid(WorkOrderCommand command) =>
      {1, WorkOrderCommand.contractVersion}.contains(command.version) &&
      command.orderId.trim().isNotEmpty &&
      command.operationId.trim().isNotEmpty &&
      command.expectedRevision >= 0 &&
      (command.action == WorkOrderAction.reject
          ? command.reason != null && command.reason!.trim().isNotEmpty
          : command.reason == null) &&
      (command.action == WorkOrderAction.requestTime
          ? command.version == 2 &&
                {2, 5}.contains(command.additionalMinutes) &&
                command.expectedAcceptanceDeadline != null
          : command.additionalMinutes == null &&
                command.expectedAcceptanceDeadline == null);

  Future<List<WorkOrderCommand>> _read(String account, String store) async {
    _checkAccount(account, store);
    final raw = await _storage.read(key: _key(account, store));
    _checkAccount(account, store);
    if (raw == null) return [];
    final data = jsonDecode(raw);
    if (data is! Map ||
        data['version'] != _journalVersion ||
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
          (entry['reason'] != null && entry['reason'] is! String) ||
          (entry['version'] != null && entry['version'] is! int) ||
          (entry['additionalMinutes'] != null &&
              entry['additionalMinutes'] is! int) ||
          (entry['expectedAcceptanceDeadline'] != null &&
              entry['expectedAcceptanceDeadline'] is! String)) {
        throw const FormatException('Invalid pending order entry');
      }
      final deadlineText = entry['expectedAcceptanceDeadline'] as String?;
      final deadline = deadlineText == null
          ? null
          : DateTime.tryParse(deadlineText);
      if (deadlineText != null &&
          deadline?.toUtc().toIso8601String() != deadlineText) {
        throw const FormatException('Invalid pending order deadline');
      }
      final command = WorkOrderCommand(
        accountScope: account,
        workspaceId: store,
        orderId: entry['orderId'] as String,
        operationId: entry['operationId'] as String,
        expectedRevision: entry['expectedRevision'] as int,
        action: WorkOrderAction.values.byName(entry['action'] as String),
        reason: entry['reason'] as String?,
        version: (entry['version'] as int?) ?? 1,
        additionalMinutes: entry['additionalMinutes'] as int?,
        expectedAcceptanceDeadline: deadline,
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
        'version': _journalVersion,
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
  bool get timeRequestsAvailable =>
      gateway is WorkOrderTimeCommandGateway &&
      (gateway as WorkOrderTimeCommandGateway).supportsOrderTimeRequests;
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
        !SecureWorkOrderPendingStore._valid(command) ||
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
      (reply.delivery == null ||
          (!reply.order!.isCustomerCollection &&
              reply.delivery!.orderId == reply.orderId)) &&
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
      WorkOrderAction.requestTime =>
        timeRequestsAvailable && record.stage == 'Confirmed',
    };
  }

  Future<bool> act(
    String orderId,
    WorkOrderAction action, {
    String? reason,
    int? additionalMinutes,
  }) {
    final snapshot = _orders[orderId];
    if (_disposed ||
        !recoveryReady ||
        _pending.containsKey(orderId) ||
        snapshot == null ||
        !_allowed(snapshot, action) ||
        (action == WorkOrderAction.requestTime &&
            (!{2, 5}.contains(additionalMinutes) ||
                snapshot.order!.actionDeadline?.isAfter(DateTime.now()) !=
                    true)) ||
        (action != WorkOrderAction.requestTime && additionalMinutes != null) ||
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
      additionalMinutes: additionalMinutes,
      expectedAcceptanceDeadline: action == WorkOrderAction.requestTime
          ? snapshot.order!.actionDeadline
          : null,
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
      if (command.action == WorkOrderAction.requestTime &&
          reply.state == WorkOrderReplyState.applied) {
        final deadline = reply.order!.actionDeadline;
        final fulfilment = reply.order!.fulfilmentDeadline;
        final expected = command.expectedAcceptanceDeadline!;
        // A late but valid acknowledgement may already be expired. Display its
        // real deadline, never extend it from the client's receipt time.
        if (reply.order!.stage != 'Confirmed' ||
            deadline == null ||
            fulfilment == null ||
            !deadline.isAfter(expected) ||
            deadline.isAfter(
              expected.add(Duration(minutes: command.additionalMinutes!)),
            ) ||
            !fulfilment.isAfter(deadline)) {
          return false;
        }
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

/// Versioned, synthetic projections for frontend UAT and future adapter tests.
/// Pure data only: no network, approval, payment or collection authority.
/// The runtime loader separately requires both review defines and debug mode.
class StoreReviewSeed {
  StoreReviewSeed({
    required this.accountScope,
    required this.orderCount,
    required DateTime now,
  }) : now = now.toUtc() {
    if (accountScope.trim().isEmpty || !{12, 100, 1000}.contains(orderCount)) {
      throw ArgumentError('Unsupported Store review scenario');
    }
  }

  static const version = 1;
  final String accountScope;
  final int orderCount;
  final DateTime now;
  String get storeId =>
      'QA-STORE-V1-$orderCount-'
      '${crypto.sha256.convert(utf8.encode(accountScope)).toString().substring(0, 16)}';
  String get label => 'TEST Store · $orderCount orders';
  WorkWorkspace get workspace => WorkWorkspace(
    id: storeId,
    name: label,
    profileLabel: 'Grocery / Kirana Shop',
    profileId: 'retailer-grocery',
    area: 'Synthetic test data',
    verified: true,
  );

  late final List<WorkspaceCatalogueItem> products = List.unmodifiable([
    for (final product in workspaceMasterCatalogue.take(6))
      product.copyWith(stock: 10000, available: true, publicListing: true),
  ]);

  late final List<WorkspaceOrderRecord> orders = List.unmodifiable([
    for (var i = 0; i < orderCount; i++) _order(i),
  ]);

  WorkspaceOrderRecord _order(int i) {
    final product = products[i % products.length];
    final quantity = 1 + i % 3;
    final stage = const [
      'Confirmed',
      'Preparing',
      'Ready',
      'Delivery requested',
    ][i % 4];
    return WorkspaceOrderRecord(
      id: 'QA-ORDER-${i.toString().padLeft(4, '0')}',
      customer: 'Test customer ${i + 1}',
      items: '${product.title} × $quantity',
      quantities: Map.unmodifiable({product.id: quantity}),
      amount: product.sellingPrice * quantity,
      source: 'App',
      fulfilment: 'Mool delivery',
      payment: i % 3 == 0 ? 'Payment due' : 'Paid online',
      address: 'Test address ${i + 1}, QA locality',
      stage: stage,
      needsDelivery: true,
      createdAt: now.subtract(Duration(seconds: i)),
      actionDeadline: stage == 'Confirmed'
          ? now.add(const Duration(seconds: 60))
          : null,
      fulfilmentDeadline: now.add(const Duration(minutes: 10)),
      stockReserved: stage != 'Confirmed',
      itemSnapshots: List.unmodifiable([
        WorkspaceOrderItemSnapshot(
          productId: product.id,
          name: product.title,
          pack: product.pack,
          quantity: quantity,
          unitPricePaise: product.sellingPrice * 100,
          lineTotalPaise: product.sellingPrice * quantity * 100,
        ),
      ]),
    );
  }

  WorkspaceFinanceSnapshot get finance => WorkspaceFinanceSnapshot(
    accountScope: accountScope,
    workspaceId: storeId,
    revision: 1,
    asOf: now,
    // Large-ledger totals intentionally exceed the visible payment sample.
    salesTodayMinor: orderCount == 1000
        ? 1000000000000
        : orders.fold<int>(0, (total, order) => total + order.amount * 100),
    duesMinor: [
      for (var i = 0; i < orders.length; i += 3) orders[i],
    ].fold<int>(0, (total, order) => total + order.amount * 100),
    availableMinor: orderCount == 1000 ? 100000000000 : 250000,
    heldMinor: 125000,
    requestedMinor: 0,
    paidOutMinor: 450000,
    feesMinor: 1200,
    deliveryAdjustmentsMinor: -300,
    refundsMinor: 0,
    taxWithheldMinor: 0,
    payments: [
      for (var i = 0; i < orders.length; i++)
        WorkspacePaymentRecord(
          orderId: orders[i].id,
          customerId: 'QA-CUSTOMER-$i',
          customerName: orders[i].customer,
          revision: 1,
          updatedAt: now,
          amountMinor: orders[i].amount * 100,
          paidMinor: i % 3 == 0 ? 0 : orders[i].amount * 100,
          dueMinor: i % 3 == 0 ? orders[i].amount * 100 : 0,
          refundedMinor: 0,
          state: i % 3 == 0
              ? WorkspacePaymentState.unpaid
              : WorkspacePaymentState.paid,
          channel: i % 3 == 0
              ? WorkspacePaymentChannel.credit
              : WorkspacePaymentChannel.platform,
          invoiceId: 'QA-INVOICE-$i',
        ),
    ],
    payouts: const [],
    historyComplete: false,
  );

  List<WorkspacePurchaseRecord> get purchases => List.unmodifiable([
    for (var i = 0; i < WorkspaceSupplyStage.values.length; i++)
      WorkspacePurchaseRecord(
        accountScope: accountScope,
        workspaceId: storeId,
        supplierId: 'QA-SUPPLIER-${i % 3}',
        supplierName: 'Test ${WorkspaceStockSupplierType.values[i % 3].label}',
        orderId: 'QA-PURCHASE-$i',
        shipmentId: 'QA-SHIPMENT-$i',
        revision: 1,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
        stage: WorkspaceSupplyStage.values[i],
        amountMinor: products.first.purchasePrice * 20 * 100,
        itemSummary: '${products.first.title} × 20',
        paymentLabel: i.isEven ? 'Paid to supplier' : 'Payment pending',
        expectedArrival: 'Test estimate · today',
        address: 'QA receiving counter',
        trackingReference: 'QA-TRACK-$i',
        lines: [
          WorkspacePurchaseLine(
            id: 'QA-LINE-$i',
            productId: products.first.id,
            name: products.first.title,
            pack: products.first.pack,
            orderedPacks: 20,
            unitPriceMinor: products.first.purchasePrice * 100,
          ),
        ],
      ),
  ]);

  List<WorkspaceGroupOffer> get offers => List.unmodifiable([
    for (var i = 0; i < 3; i++)
      WorkspaceGroupOffer(
        accountScope: accountScope,
        workspaceId: storeId,
        supplierId: 'QA-SUPPLIER-$i',
        supplierName: 'Test ${WorkspaceStockSupplierType.values[i].label}',
        supplierType: WorkspaceStockSupplierType.values[i],
        productId: products[i].id,
        revision: 1,
        updatedAt: now,
        closingAt: now.add(const Duration(days: 1)),
        stage: WorkspaceGroupOfferStage.collecting,
        publicationConfirmed: true,
        details: WorkspaceGroupBuy(
          id: 'QA-OFFER-$i',
          productName: products[i].title,
          specification: products[i].pack,
          leadRetailer: 'Test group organiser',
          confirmedRetailers: const ['Test participating store'],
          targetQuantity: 1000,
          securedQuantity: 300 + i * 100,
          unitLabel: 'packs',
          regularUnitPrice: 100,
          groupUnitPrice: 80,
          facilitationFee: 100,
          deliveryFee: 200,
          confirmationAmount: 0,
          closingLabel: 'Test offer · closes tomorrow',
          storeDeliveryLabel: 'Test delivery · after offer closes',
          paymentConfirmed: false,
        ),
        participation: const WorkspaceGroupParticipation(
          state: WorkspaceGroupParticipationState.notJoined,
        ),
        note: 'Simulated offer. No purchase or payment will be made.',
      ),
  ]);
}

/// In-memory response simulator. It proves UI handling, never backend security.
/// A lost reply retains one result for reconciliation without replaying effects.
enum StoreReviewOrderResponse { applied, rejected, lostReply }

class StoreReviewOrderGateway implements WorkOrderTimeCommandGateway {
  StoreReviewOrderGateway(this.seed) {
    for (final order in seed.orders) {
      _orders[order.id] = WorkOrderReply(
        accountScope: seed.accountScope,
        workspaceId: seed.storeId,
        orderId: order.id,
        operationId: 'QA-SEED-${order.id}',
        revision: 1,
        state: WorkOrderReplyState.applied,
        order: order,
      );
    }
  }
  final StoreReviewSeed seed;
  final _orders = <String, WorkOrderReply>{};
  final _results = <String, WorkOrderReply>{};
  final _commands = <String, WorkOrderCommand>{};
  StoreReviewOrderResponse nextResponse = StoreReviewOrderResponse.applied;
  List<WorkOrderReply> get snapshots => List.unmodifiable(_orders.values);
  @override
  bool get supportsOrderTimeRequests => true;

  void _checkScope(WorkOrderCommand command) {
    if (command.accountScope != seed.accountScope ||
        command.workspaceId != seed.storeId ||
        !_orders.containsKey(command.orderId) ||
        !SecureWorkOrderPendingStore._valid(command)) {
      throw StateError('Invalid synthetic order command');
    }
    final previous = _commands[command.operationId];
    if (previous != null &&
        (previous.orderId != command.orderId ||
            previous.action != command.action ||
            previous.expectedRevision != command.expectedRevision ||
            previous.reason != command.reason ||
            previous.additionalMinutes != command.additionalMinutes ||
            previous.expectedAcceptanceDeadline !=
                command.expectedAcceptanceDeadline)) {
      throw StateError('Synthetic operation identity changed');
    }
  }

  @override
  Future<WorkOrderReply> submitOrderCommand(WorkOrderCommand command) async {
    _checkScope(command);
    final previous = _results[command.operationId];
    if (previous != null) return previous;
    final mode = nextResponse;
    nextResponse = StoreReviewOrderResponse.applied;
    final snapshot = _orders[command.orderId]!;
    var order = snapshot.order!;
    final legalStage = switch (command.action) {
      WorkOrderAction.accept ||
      WorkOrderAction.reject ||
      WorkOrderAction.requestTime => order.stage == 'Confirmed',
      WorkOrderAction.ready => order.stage == 'Preparing',
    };
    final rejected =
        mode == StoreReviewOrderResponse.rejected ||
        snapshot.revision != command.expectedRevision ||
        !legalStage ||
        order.isCustomerCollection ||
        (command.action == WorkOrderAction.requestTime &&
            command.expectedAcceptanceDeadline != order.actionDeadline) ||
        (order.stage == 'Confirmed' &&
            order.actionDeadline?.isAfter(DateTime.now()) != true);
    if (!rejected) {
      order = switch (command.action) {
        WorkOrderAction.accept => order.copyWith(
          stage: 'Preparing',
          clearActionDeadline: true,
          stockReserved: true,
        ),
        WorkOrderAction.ready => order.copyWith(stage: 'Ready'),
        WorkOrderAction.reject => order.copyWith(
          stage: 'Cancelled',
          rejectionReason: command.reason,
          clearActionDeadline: true,
        ),
        WorkOrderAction.requestTime => order.copyWith(
          actionDeadline: order.actionDeadline!.add(
            Duration(minutes: command.additionalMinutes!),
          ),
          extraMinutes: order.extraMinutes + command.additionalMinutes!,
        ),
      };
    }
    final result = WorkOrderReply(
      accountScope: seed.accountScope,
      workspaceId: seed.storeId,
      orderId: command.orderId,
      operationId: command.operationId,
      revision: snapshot.revision + 1,
      state: rejected
          ? WorkOrderReplyState.rejected
          : WorkOrderReplyState.applied,
      order: order,
    );
    _results[command.operationId] = result;
    _commands[command.operationId] = command;
    _orders[command.orderId] = result;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mode == StoreReviewOrderResponse.lostReply) {
      throw TimeoutException(
        'Simulated lost response; reconcile the operation',
      );
    }
    return result;
  }

  @override
  Future<WorkOrderReply> reconcileOrderCommand(WorkOrderCommand command) async {
    _checkScope(command);
    final result = _results[command.operationId];
    if (result == null || result.orderId != command.orderId) {
      throw StateError('Synthetic operation is not known');
    }
    return result;
  }
}

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

  /// Restore only the test selector, never an approval or Workspace authority.
  bool restoreDeviceReviewCase(String caseId, {required String accountScope}) {
    if (!deviceReviewControlsEnabled ||
        accountScope != 'isolated-workspace-ui-review' ||
        !RegExp(r'^WP-[a-z0-9]+-[a-z0-9]+-[1-9][0-9]*$').hasMatch(caseId)) {
      return false;
    }
    _submittedReviewCases.add(caseId);
    return true;
  }

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
