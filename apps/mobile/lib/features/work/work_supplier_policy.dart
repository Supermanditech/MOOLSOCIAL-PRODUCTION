import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../shared/social_content_gateway.dart';

typedef StorePolicyScope = ({String account, String store, String realm});

Map<String, dynamic> _map(Object? value, List<String> keys) {
  if (value is! Map<String, dynamic> ||
      value.length != keys.length ||
      keys.any((k) => !value.containsKey(k))) {
    throw const FormatException('Store policy details could not be checked.');
  }
  return value;
}

String _text(Object? value, int maximum, {bool blank = false}) {
  if (value is! String ||
      value.length > maximum ||
      value.trim() != value ||
      (!blank && value.isEmpty) ||
      RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]').hasMatch(value)) {
    throw const FormatException('Check the policy text.');
  }
  return value;
}

String _id(Object? value) {
  final result = _text(value, 128);
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$').hasMatch(result)) {
    throw const FormatException('Check the selected products.');
  }
  return result;
}

int _version(Object? value, [int minimum = 0]) {
  if (value is! int || value < minimum || value > 1000000001) {
    throw const FormatException('Refresh the current policy.');
  }
  return value;
}

DateTime _time(Object? value) {
  final raw = _text(value, 32), parsed = DateTime.parse(raw).toUtc();
  if (parsed.toIso8601String() != raw) {
    throw const FormatException('Check the policy date.');
  }
  return parsed;
}

void _scope(StorePolicyScope value) {
  _text(value.account, 128);
  _id(value.store);
  if (!{'evaluation', 'production'}.contains(value.realm)) {
    throw const FormatException('Check the Store connection.');
  }
}

/// Private drafts may be incomplete/expired; only explicit publication requires completeness.
@immutable
class StorePolicyDraft {
  StorePolicyDraft({
    required String title,
    required String body,
    required Set<String> productIds,
    required bool requiresAcceptance,
    DateTime? validUntil,
  }) : _json = jsonEncode({
         'title': _text(title.trim(), 160, blank: true),
         'body': _text(body.trim(), 12000, blank: true),
         'productIds': productIds.map(_id).toList()..sort(),
         'requiresAcceptance': requiresAcceptance,
         'validUntil': validUntil == null
             ? null
             : DateTime.fromMillisecondsSinceEpoch(
                 validUntil.millisecondsSinceEpoch,
                 isUtc: true,
               ).toIso8601String(),
       }) {
    if (productIds.length > 500) {
      throw const FormatException('Choose up to 500 saved products.');
    }
  }
  final String _json;
  String get fingerprint => _json;
  Map<String, dynamic> toJson() => jsonDecode(_json) as Map<String, dynamic>;
  String get title => toJson()['title'] as String;
  String get body => toJson()['body'] as String;
  Set<String> get productIds =>
      Set.unmodifiable((toJson()['productIds'] as List).cast<String>());
  bool get requiresAcceptance => toJson()['requiresAcceptance'] as bool;
  DateTime? get validUntil =>
      toJson()['validUntil'] == null ? null : _time(toJson()['validUntil']);
  void validateForPublication(DateTime now) {
    if (title.isEmpty || body.isEmpty || productIds.isEmpty) {
      throw const FormatException(
        'Add a title, policy text and saved products.',
      );
    }
    if (validUntil?.isAfter(now.toUtc()) == false) {
      throw const FormatException('Choose a future expiry or clear it.');
    }
  }

  factory StorePolicyDraft.fromJson(Object? raw) {
    final data = _map(raw, [
      'title',
      'body',
      'productIds',
      'requiresAcceptance',
      'validUntil',
    ]);
    final ids = data['productIds'];
    if (ids is! List ||
        ids.length > 500 ||
        ids.toSet().length != ids.length ||
        data['requiresAcceptance'] is! bool) {
      throw const FormatException(
        'Check the selected products and policy requirement.',
      );
    }
    return StorePolicyDraft(
      title: _text(data['title'], 160, blank: true),
      body: _text(data['body'], 12000, blank: true),
      productIds: ids.map(_id).toSet(),
      requiresAcceptance: data['requiresAcceptance'] as bool,
      validUntil: data['validUntil'] == null ? null : _time(data['validUntil']),
    );
  }
}

@immutable
class StorePolicyRecord {
  const StorePolicyRecord._(
    this.scope,
    this.id,
    this.revision,
    this.publishedAt,
    this.draft,
  );
  final StorePolicyScope scope;
  final String id;
  final int revision;
  final DateTime publishedAt;
  final StorePolicyDraft draft;
  static StorePolicyRecord decode(
    Object? raw,
    StorePolicyScope scope,
    DateTime now,
  ) {
    final value = _map(raw, [
      'schemaVersion',
      'realm',
      'storeId',
      'id',
      'revision',
      'publishedAt',
      'title',
      'body',
      'productIds',
      'requiresAcceptance',
      'validUntil',
    ]);
    final at = _time(value['publishedAt']);
    if (value['schemaVersion'] != 1 ||
        value['realm'] != scope.realm ||
        value['storeId'] != scope.store ||
        at.isAfter(now.toUtc())) {
      throw const FormatException(
        'Store policy details changed. Refresh them.',
      );
    }
    final draft = StorePolicyDraft.fromJson({
      for (final key in [
        'title',
        'body',
        'productIds',
        'requiresAcceptance',
        'validUntil',
      ])
        key: value[key],
    });
    if (draft.title.isEmpty || draft.body.isEmpty || draft.productIds.isEmpty) {
      throw const FormatException('Store policy is incomplete.');
    }
    return StorePolicyRecord._(
      scope,
      _id(value['id']),
      _version(value['revision'], 1),
      at,
      draft,
    );
  }
}

@immutable
class StorePolicyIntent {
  StorePolicyIntent({
    required this.scope,
    required this.expectedRevision,
    required this.idempotencyKey,
    required this.draft,
  }) {
    _scope(scope);
    _id(idempotencyKey);
    _version(expectedRevision);
    if (expectedRevision > 1000000000 ||
        utf8
                .encode(
                  jsonEncode({'operation': 'saveStoreSupplierPolicy', ...body}),
                )
                .length >
            60000) {
      throw const FormatException(
        'Policy text or product selection is too large.',
      );
    }
  }
  final StorePolicyScope scope;
  final int expectedRevision;
  final String idempotencyKey;
  final StorePolicyDraft draft;
  Map<String, dynamic> get body => {
    'storeId': scope.store,
    'expectedRevision': expectedRevision,
    'idempotencyKey': idempotencyKey,
    'policy': draft.toJson(),
  };
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'accountId': scope.account,
    'realm': scope.realm,
    ...body,
  };
  String get fingerprint => jsonEncode(toJson());
  factory StorePolicyIntent.fromJson(Object? raw) {
    final value = _map(raw, [
      'schemaVersion',
      'accountId',
      'realm',
      'storeId',
      'expectedRevision',
      'idempotencyKey',
      'policy',
    ]);
    if (value['schemaVersion'] != 1) {
      throw const FormatException('Saved policy update needs checking.');
    }
    return StorePolicyIntent(
      scope: (
        account: _text(value['accountId'], 128),
        store: _id(value['storeId']),
        realm: _text(value['realm'], 16),
      ),
      expectedRevision: _version(value['expectedRevision']),
      idempotencyKey: _id(value['idempotencyKey']),
      draft: StorePolicyDraft.fromJson(value['policy']),
    );
  }
}

enum StorePolicyResultState { saved, notSent, rejected, unknown }

class StorePolicyResult {
  const StorePolicyResult(this.state, {this.record});
  final StorePolicyResultState state;
  final StorePolicyRecord? record;
}

abstract interface class StorePolicyGateway {
  Future<StorePolicyRecord?> read(
    StorePolicyScope scope,
    bool Function() current,
  );
  Future<StorePolicyResult> publish(
    StorePolicyIntent original,
    bool Function() current,
  );
  Future<StorePolicyResult> reconcile(
    StorePolicyIntent original,
    bool Function() current,
  );
}

class _PolicyNotSent implements Exception {}

class AuthenticatedStorePolicyGateway implements StorePolicyGateway {
  AuthenticatedStorePolicyGateway({
    required this.endpoint,
    required this.credentials,
    required this.transport,
    required this.ownerAccountId,
    required this.realm,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now {
    if (endpoint.scheme != 'https' ||
        endpoint.host !=
            'asia-south1-moolsocial-dev-503018.cloudfunctions.net' ||
        endpoint.path != '/moolSocialWorkspace' ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasPort ||
        !{'evaluation', 'production'}.contains(realm) ||
        ownerAccountId.trim().isEmpty) {
      throw ArgumentError('Invalid Store policy connection.');
    }
  }
  final Uri endpoint;
  final SocialContentCredentials credentials;
  final SocialContentTransport transport;
  final String ownerAccountId, realm;
  final DateTime Function() now;
  void _check(StorePolicyScope scope, bool Function() current) {
    _scope(scope);
    if (scope.account != ownerAccountId || scope.realm != realm || !current()) {
      throw _PolicyNotSent();
    }
  }

  Future<SocialContentResponse> _request(
    StorePolicyScope scope,
    String operation,
    Map<String, dynamic> body,
    bool Function() current, {
    required bool mutation,
    required void Function() onSend,
    void Function()? beforeSend,
  }) async {
    _check(scope, current);
    final token = await credentials.firebaseIdToken();
    _check(scope, current);
    final appCheck = await credentials.appCheckToken(
      mutation
          ? SocialAppCheckTokenMode.limitedUse
          : SocialAppCheckTokenMode.standard,
    );
    _check(scope, current);
    beforeSend?.call();
    onSend();
    return transport
        .postJson(
          endpoint,
          headers: {
            'accept': 'application/json',
            'authorization': 'Bearer $token',
            'x-firebase-appcheck': appCheck,
            'x-request-id': _key(),
          },
          body: {'operation': operation, ...body},
        )
        .timeout(const Duration(seconds: 20));
  }

  StorePolicyRecord? _decode(
    SocialContentResponse response,
    StorePolicyScope scope,
  ) {
    if (response.statusCode != 200) {
      throw const FormatException('Store policy could not be checked.');
    }
    final envelope = jsonDecode(response.body);
    if (envelope is! Map || envelope['ok'] != true) {
      throw const FormatException('Store policy could not be checked.');
    }
    final data = _map(envelope['data'], [
      'schemaVersion',
      'realm',
      'storeId',
      'record',
      'publicAvailabilityConfirmed',
    ]);
    if (data['schemaVersion'] != 1 ||
        data['realm'] != scope.realm ||
        data['storeId'] != scope.store ||
        data['publicAvailabilityConfirmed'] != false) {
      throw const FormatException('Store policy response changed.');
    }
    return data['record'] == null
        ? null
        : StorePolicyRecord.decode(data['record'], scope, now());
  }

  @override
  Future<StorePolicyRecord?> read(
    StorePolicyScope scope,
    bool Function() current,
  ) async {
    final response = await _request(
      scope,
      'readStoreSupplierPolicy',
      {'storeId': scope.store},
      current,
      mutation: false,
      onSend: () {},
    );
    _check(scope, current);
    return _decode(response, scope);
  }

  @override
  Future<StorePolicyResult> publish(
    StorePolicyIntent original,
    bool Function() current,
  ) => _write(original, current, recovery: false);
  @override
  Future<StorePolicyResult> reconcile(
    StorePolicyIntent original,
    bool Function() current,
  ) => _write(original, current, recovery: true);
  Future<StorePolicyResult> _write(
    StorePolicyIntent original,
    bool Function() current, {
    required bool recovery,
  }) async {
    var sent = false;
    try {
      if (!recovery) original.draft.validateForPublication(now());
      final response = await _request(
        original.scope,
        recovery ? 'reconcileStoreSupplierPolicy' : 'saveStoreSupplierPolicy',
        original.body,
        current,
        mutation: !recovery,
        onSend: () => sent = true,
        beforeSend: recovery
            ? null
            : () => original.draft.validateForPublication(now()),
      );
      if (!current()) {
        return const StorePolicyResult(StorePolicyResultState.unknown);
      }
      if (!recovery &&
          response.statusCode >= 400 &&
          response.statusCode < 500) {
        final error = jsonDecode(response.body);
        if (error is Map &&
            error['ok'] == false &&
            error['error'] is Map &&
            {
              'invalid_input',
              'conflict',
              'not_found',
              'invalid_state',
              'forbidden',
              'authentication_required',
            }.contains(error['error']['code'])) {
          return const StorePolicyResult(StorePolicyResultState.rejected);
        }
      }
      final record = _decode(response, original.scope);
      if (record == null ||
          record.revision != original.expectedRevision + 1 ||
          record.draft.fingerprint != original.draft.fingerprint) {
        return const StorePolicyResult(StorePolicyResultState.unknown);
      }
      return StorePolicyResult(StorePolicyResultState.saved, record: record);
    } on Object {
      return StorePolicyResult(
        sent || recovery
            ? StorePolicyResultState.unknown
            : StorePolicyResultState.notSent,
      );
    }
  }
}

String _key() =>
    'policy-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

class StorePolicyRecovery {
  const StorePolicyRecovery({this.draft, this.pending});
  final StorePolicyDraft? draft;
  final StorePolicyIntent? pending;
}

abstract interface class StorePolicyJournal {
  Future<StorePolicyRecovery> read(StorePolicyScope scope);
  Future<void> saveDraft(StorePolicyScope scope, StorePolicyDraft draft);
  Future<void> savePending(StorePolicyIntent original);
  Future<void> clearPending(StorePolicyIntent original);
}

/// Draft, current policy and original acknowledgement are deliberately separate.
class StorePolicyController extends ChangeNotifier {
  StorePolicyController({
    required this.scope,
    required this.journal,
    required this.gateway,
    required this.context,
    required this.validateSelection,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now,
       _lifetime = context() {
    _scope(scope);
  }
  final StorePolicyScope scope;
  final StorePolicyJournal journal;
  final StorePolicyGateway? gateway;
  final Object? Function() context;
  final Future<bool> Function(StorePolicyDraft draft, bool Function() current)
  validateSelection;
  final DateTime Function() now;
  final Object? _lifetime;
  StorePolicyDraft? draft;
  StorePolicyIntent? pending;
  StorePolicyRecord? published, lastAcknowledged;
  bool ready = false, busy = false, currentLoaded = false, _closed = false;
  String? message;
  Future<bool>? _restoring;
  bool _current(Object? owner) =>
      !_closed &&
      _lifetime != null &&
      owner == _lifetime &&
      context() == _lifetime;
  bool get active => _current(_lifetime);
  void _notify() {
    if (!_closed) notifyListeners();
  }

  Future<bool> restore() {
    if (!active) return Future.value(false);
    if (ready) return Future.value(true);
    return _restoring ??= _restore().whenComplete(() => _restoring = null);
  }

  Future<bool> _restore() async {
    final owner = context();
    try {
      final retained = await journal
          .read(scope)
          .timeout(const Duration(seconds: 10));
      if (!_current(owner)) return false;
      if (retained.pending != null && retained.pending!.scope != scope) {
        throw const FormatException();
      }
      draft = retained.draft;
      pending = retained.pending;
      ready = true;
      message = null;
      return true;
    } on Object {
      if (_current(owner)) {
        ready = false;
        message = 'Saved policy details could not be opened. Try again.';
      }
      return false;
    } finally {
      if (_current(owner)) _notify();
    }
  }

  Future<bool> refresh() async {
    if (!active || busy) return false;
    final owner = context();
    busy = true;
    _notify();
    try {
      if (!await restore() || !_current(owner)) return false;
      if (pending != null) {
        message = 'Check your saved policy update before publishing another.';
        return false;
      }
      if (gateway == null) {
        message =
            'Policy publishing is not connected. Your private draft is kept.';
        return false;
      }
      currentLoaded = false;
      final record = await gateway!
          .read(scope, () => _current(owner))
          .timeout(const Duration(seconds: 25));
      if (!_current(owner)) return false;
      if (record != null && record.scope != scope) {
        throw const FormatException();
      }
      if (published != null &&
          (record == null ||
              record.revision < published!.revision ||
              record.revision == published!.revision &&
                  record.draft.fingerprint != published!.draft.fingerprint)) {
        throw const FormatException();
      }
      published = record;
      currentLoaded = true;
      draft ??= record?.draft;
      message = null;
      return true;
    } on Object {
      if (_current(owner)) {
        currentLoaded = false;
        message = 'Current policy could not be checked. Your draft is kept.';
      }
      return false;
    } finally {
      busy = false;
      if (_current(owner)) _notify();
    }
  }

  Future<bool> saveDraft(StorePolicyDraft value) async {
    if (!active || busy) return false;
    final owner = context();
    busy = true;
    _notify();
    try {
      if (!await restore() || !_current(owner)) return false;
      await journal
          .saveDraft(scope, value)
          .timeout(const Duration(seconds: 10));
      if (!_current(owner)) return false;
      draft = value;
      message = 'Private policy draft saved on this device. Not published.';
      return true;
    } on Object {
      if (_current(owner)) {
        message =
            'Draft could not be saved. Keep this screen open and try again.';
      }
      return false;
    } finally {
      busy = false;
      if (_current(owner)) _notify();
    }
  }

  Future<StorePolicyResult> publish(
    StorePolicyDraft value, {
    bool Function()? inputCurrent,
  }) async {
    if (!active || busy) {
      return const StorePolicyResult(StorePolicyResultState.notSent);
    }
    final owner = context();
    bool live() => _current(owner) && (inputCurrent?.call() ?? true);
    busy = true;
    _notify();
    try {
      if (!await restore() ||
          !live() ||
          !currentLoaded ||
          gateway == null ||
          pending != null) {
        return const StorePolicyResult(StorePolicyResultState.notSent);
      }
      value.validateForPublication(now());
      await journal
          .saveDraft(scope, value)
          .timeout(const Duration(seconds: 10));
      if (!live()) {
        return const StorePolicyResult(StorePolicyResultState.notSent);
      }
      draft = value;
      if (!await validateSelection(value, live) || !live()) {
        message =
            'Some selected products need their saved details confirmed. Your complete selection and draft are kept.';
        return const StorePolicyResult(StorePolicyResultState.notSent);
      }
      value.validateForPublication(now());
      final original = StorePolicyIntent(
        scope: scope,
        expectedRevision: published?.revision ?? 0,
        idempotencyKey: _key(),
        draft: value,
      );
      pending = original;
      await journal.savePending(original).timeout(const Duration(seconds: 10));
      if (!live()) {
        return const StorePolicyResult(StorePolicyResultState.unknown);
      }
      final result = await gateway!
          .publish(original, live)
          .timeout(const Duration(seconds: 25));
      if (!_current(owner)) {
        return const StorePolicyResult(StorePolicyResultState.unknown);
      }
      return await _finish(original, result, owner, recovery: false);
    } on FormatException catch (error) {
      if (_current(owner)) message = error.message;
      return StorePolicyResult(
        pending == null
            ? StorePolicyResultState.notSent
            : StorePolicyResultState.unknown,
      );
    } on Object {
      if (_current(owner)) {
        ready = pending == null ? ready : false;
        message =
            'Policy update is not confirmed. Check the original before trying another.';
      }
      return StorePolicyResult(
        pending == null
            ? StorePolicyResultState.notSent
            : StorePolicyResultState.unknown,
      );
    } finally {
      busy = false;
      if (_current(owner)) _notify();
    }
  }

  Future<StorePolicyResult> reconcile() async {
    if (!active || busy) {
      return const StorePolicyResult(StorePolicyResultState.unknown);
    }
    final owner = context();
    busy = true;
    _notify();
    try {
      if (!await restore() ||
          !_current(owner) ||
          pending == null ||
          gateway == null) {
        return const StorePolicyResult(StorePolicyResultState.unknown);
      }
      final original = pending!;
      final result = await gateway!
          .reconcile(original, () => _current(owner))
          .timeout(const Duration(seconds: 25));
      if (!_current(owner)) {
        return const StorePolicyResult(StorePolicyResultState.unknown);
      }
      return await _finish(original, result, owner, recovery: true);
    } on Object {
      if (_current(owner)) {
        message =
            'Original policy update is not confirmed. Your draft and request are kept.';
      }
      return const StorePolicyResult(StorePolicyResultState.unknown);
    } finally {
      busy = false;
      if (_current(owner)) _notify();
    }
  }

  Future<StorePolicyResult> _finish(
    StorePolicyIntent original,
    StorePolicyResult result,
    Object? owner, {
    required bool recovery,
  }) async {
    final record = result.record;
    final exact =
        record != null &&
        record.scope == scope &&
        record.revision == original.expectedRevision + 1 &&
        record.draft.fingerprint == original.draft.fingerprint;
    final definitive =
        result.state == StorePolicyResultState.saved && exact ||
        !recovery &&
            {
              StorePolicyResultState.notSent,
              StorePolicyResultState.rejected,
            }.contains(result.state);
    if (!definitive) {
      message =
          'Policy update is not confirmed. Your original request is kept.';
      return const StorePolicyResult(StorePolicyResultState.unknown);
    }
    await journal.clearPending(original).timeout(const Duration(seconds: 10));
    if (!_current(owner)) {
      return const StorePolicyResult(StorePolicyResultState.unknown);
    }
    pending = null;
    currentLoaded = false;
    if (exact && result.state == StorePolicyResultState.saved) {
      lastAcknowledged = record;
    }
    message = result.state == StorePolicyResultState.saved
        ? 'Policy update recorded. Refresh to check the current version; online availability is not confirmed.'
        : 'Policy was not published. Your private draft is kept; refresh before trying again.';
    return result;
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
