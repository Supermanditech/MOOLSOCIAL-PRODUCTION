import 'dart:convert';
import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'work_ledger_gateway.dart' show WorkspaceLedgerScope, workspaceLedgerCanonical, workspaceLedgerFingerprint;
import 'work_purchase_entry_gateway.dart' show WorkspacePurchaseEntryRequest;
import 'work_models.dart' show WorkspaceCounterDraft;

/// Customer originals use the same actor/Store/realm boundary as other original
/// records. A format conversion alone grants no access or financial authority.
typedef WorkspaceCustomerScope = WorkspaceLedgerScope;

Map<String, Object?> _customerObject(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Invalid original customer record.');
  }
  return Map<String, Object?>.from(value);
}

void _customerScope(WorkspaceCustomerScope scope) {
  if (scope.account.trim().isEmpty || scope.store.trim().isEmpty ||
      !const {'evaluation', 'production'}.contains(scope.realm)) {
    throw const FormatException('Invalid original customer context.');
  }
}

const _counterEncoding = 'native-counter-int64-v1';
final _counterMaxInteger = BigInt.parse('9223372036854775807');
String _counterIntegerToWire(Object? value) {
  if (value is! int || value < 0 || BigInt.from(value) > _counterMaxInteger) {
    throw const FormatException('Invalid original Counter integer.');
  }
  return value.toString();
}

int _counterIntegerFromWire(Object? value) {
  if (value is! String || !RegExp(r'^(0|[1-9][0-9]{0,18})$').hasMatch(value)) {
    throw const FormatException('Invalid original Counter integer.');
  }
  final exact = BigInt.parse(value);
  if (exact > _counterMaxInteger) {
    throw const FormatException('Original Counter integer is out of range.');
  }
  final decoded = exact.toInt();
  if (BigInt.from(decoded) != exact) {
    throw const FormatException('Original Counter integer cannot be represented exactly.');
  }
  return decoded;
}

/// Preserve native Counter int64 draft inputs across JavaScript/JSON boundaries.
/// Only known integer fields are encoded. Billing text, GSTIN, SKU and reference
/// strings are never translated, parsed as numbers or given invented defaults.
Map<String, Object?> workspaceCounterDraftToOriginalWire(
  WorkspaceCounterDraft draft, WorkspaceCustomerScope scope,
) {
  _customerScope(scope);
  if (!draft.valid || draft.account != scope.account || draft.store != scope.store) {
    throw const FormatException('Original Counter draft context changed.');
  }
  final raw = draft.toJson();
  raw['revision'] = _counterIntegerToWire(raw['revision']);
  final discount = _customerObject(raw['discount']);
  discount['value'] = _counterIntegerToWire(discount['value']);
  raw['discount'] = discount;
  raw['lines'] = [for (final value in raw['lines'] as List)
    (() {
      final line = _customerObject(value);
      for (final field in const ['quantity', 'unitPricePaise', 'lineTotalPaise']) {
        line[field] = _counterIntegerToWire(line[field]);
      }
      return line;
    })()];
  return {'encoding': _counterEncoding, 'draft': raw};
}

WorkspaceCounterDraft workspaceCounterDraftFromOriginalWire(
  Object? value, WorkspaceCustomerScope scope,
) {
  _customerScope(scope);
  final envelope = _customerObject(value);
  if (envelope.length != 2 || envelope['encoding'] != _counterEncoding ||
      !envelope.containsKey('draft')) {
    throw const FormatException('Unsupported original Counter record.');
  }
  final raw = _customerObject(envelope['draft']);
  raw['revision'] = _counterIntegerFromWire(raw['revision']);
  final discount = _customerObject(raw['discount']);
  discount['value'] = _counterIntegerFromWire(discount['value']);
  raw['discount'] = discount;
  if (raw['lines'] is! List) throw const FormatException('Invalid original Counter lines.');
  raw['lines'] = [for (final value in raw['lines'] as List)
    (() {
      final line = _customerObject(value);
      for (final field in const ['quantity', 'unitPricePaise', 'lineTotalPaise']) {
        line[field] = _counterIntegerFromWire(line[field]);
      }
      return line;
    })()];
  final draft = WorkspaceCounterDraft.fromJson(raw);
  if (draft == null || draft.account != scope.account || draft.store != scope.store ||
      workspaceLedgerCanonical(workspaceCounterDraftToOriginalWire(draft, scope)) !=
          workspaceLedgerCanonical(value)) {
    throw const FormatException('Original Counter record could not be verified.');
  }
  return draft;
}

void _customerKeys(Map<String, Object?> value, Set<String> keys) {
  if (value.length != keys.length || !keys.every(value.containsKey)) {
    throw const FormatException('Invalid original customer fields.');
  }
}
String _customerId(Object? value) {
  if (value is! String || value.trim().isEmpty || value.length > 2000 ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(value) || utf8.decode(utf8.encode(value)) != value) {
    throw const FormatException('Invalid original customer identity.');
  }
  return value;
}
Map<String, Object?> _customerScopeJson(WorkspaceCustomerScope scope) =>
  {'account': scope.account, 'store': scope.store, 'realm': scope.realm};
String workspaceCounterOriginalBindingKey(WorkspaceCustomerScope scope) =>
  'moolsocial.workspace.counter-original-attempt.v1.${workspaceLedgerFingerprint(_customerScopeJson(scope))}';
String _customerFingerprint(Object? value) {
  if (value is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw const FormatException('Invalid original customer fingerprint.');
  }
  return value;
}
DateTime _customerTime(Object? value) {
  if (value is! String || !value.endsWith('Z')) throw const FormatException();
  final parsed = DateTime.parse(value).toUtc();
  if (parsed.toIso8601String() != value) throw const FormatException();
  return parsed;
}

/// Native-owned frozen recovery command. Model output never supplies the key.
/// All int64 fields remain strings in the immutable transport snapshot.
class WorkspaceCounterOriginalIntent {
  WorkspaceCounterOriginalIntent._(this.scope, this._json);
  final WorkspaceCustomerScope scope;
  final String _json;
  factory WorkspaceCounterOriginalIntent({required WorkspaceCustomerScope scope,
    required WorkspaceCounterDraft draft, required int? expectedRevision, required String idempotencyKey}) {
    final input = {'operation': 'saveStoreCounterDraft', 'scope': _customerScopeJson(scope),
      'expectedRevision': expectedRevision == null ? null : _counterIntegerToWire(expectedRevision),
      'idempotencyKey': _customerId(idempotencyKey), 'wire': workspaceCounterDraftToOriginalWire(draft, scope)};
    return WorkspaceCounterOriginalIntent.fromJson({...input, 'fingerprint': workspaceLedgerFingerprint(input)}, scope);
  }
  factory WorkspaceCounterOriginalIntent.fromJson(Object? raw, WorkspaceCustomerScope scope) {
    _customerScope(scope);
    final value = _customerObject(raw);
    _customerKeys(value, {'operation', 'scope', 'expectedRevision', 'idempotencyKey', 'wire', 'fingerprint'});
    final expected = value['expectedRevision'] == null ? null : _counterIntegerFromWire(value['expectedRevision']);
    final draft = workspaceCounterDraftFromOriginalWire(value['wire'], scope);
    if (value['operation'] != 'saveStoreCounterDraft' ||
        workspaceLedgerCanonical(value['scope']) != workspaceLedgerCanonical(_customerScopeJson(scope)) ||
        expected != null && expected < 1 || BigInt.from(draft.revision) != BigInt.from(expected ?? 0) + BigInt.one) {
      throw const FormatException('Original Counter revision changed.');
    }
    _customerId(value['idempotencyKey']);
    final fingerprint = _customerFingerprint(value['fingerprint']), input = {...value}..remove('fingerprint');
    if (workspaceLedgerFingerprint(input) != fingerprint) throw const FormatException('Original Counter input changed.');
    return WorkspaceCounterOriginalIntent._(scope, workspaceLedgerCanonical(value));
  }
  Map<String, Object?> toJson() => _customerObject(jsonDecode(_json));
  String get fingerprint => toJson()['fingerprint']! as String;
  String get idempotencyKey => toJson()['idempotencyKey']! as String;
  int? get expectedRevision => toJson()['expectedRevision'] == null ? null : _counterIntegerFromWire(toJson()['expectedRevision']);
  WorkspaceCounterDraft get draft => workspaceCounterDraftFromOriginalWire(toJson()['wire'], scope);
}

class WorkspaceCounterOriginalReadback {
  WorkspaceCounterOriginalReadback._({required this.currentDraft, required Map<String, Object?>? attempt, required this.observedAt})
    : _attemptJson = attempt == null ? null : workspaceLedgerCanonical(attempt);
  final WorkspaceCounterDraft? currentDraft;
  final String? _attemptJson;
  Map<String, Object?>? get attempt => _attemptJson == null ? null : _customerObject(jsonDecode(_attemptJson));
  final DateTime observedAt;
  bool get saved => attempt?['status'] == 'saved';
  bool get refused => attempt?['status'] == 'not_saved';
  factory WorkspaceCounterOriginalReadback.decode(Object? raw, WorkspaceCustomerScope scope, DateTime now,
    {WorkspaceCounterOriginalIntent? original}) {
    _customerScope(scope);
    final value = _customerObject(raw);
    _customerKeys(value, {'schemaVersion', 'customerOriginalVersion', 'actorAccountId', 'realm', 'storeId',
      'observedAt', 'state', 'draftJson', 'draftFingerprint', 'attempt'});
    final observedAt = _customerTime(value['observedAt']);
    if (value['schemaVersion'] != 1 || value['customerOriginalVersion'] != 1 ||
        value['actorAccountId'] != scope.account || value['storeId'] != scope.store || value['realm'] != scope.realm ||
        now.toUtc().difference(observedAt).abs() > const Duration(minutes: 5) || original != null && original.scope != scope) {
      throw const FormatException('Original Counter context changed.');
    }
    WorkspaceCounterDraft? draft;
    if (value['state'] == 'empty') {
      if (value['draftJson'] != null || value['draftFingerprint'] != null) throw const FormatException();
    } else if (value['state'] == 'ready' && value['draftJson'] is String) {
      final text = value['draftJson']! as String, wire = jsonDecode(text);
      if (workspaceLedgerCanonical(wire) != text || workspaceLedgerFingerprint(wire) != _customerFingerprint(value['draftFingerprint'])) {
        throw const FormatException('Original Counter data changed.');
      }
      draft = workspaceCounterDraftFromOriginalWire(wire, scope);
    } else {
      throw const FormatException('Original Counter status is unavailable.');
    }
    Map<String, Object?>? attempt;
    if (value['attempt'] != null) {
      if (original == null) throw const FormatException('Unexpected original Counter attempt.');
      final row = _customerObject(value['attempt']);
      _customerKeys(row, {'schemaVersion', 'scope', 'operation', 'idempotencyKey', 'fingerprint',
        'status', 'reason', 'changed', 'resultRevision', 'recordedAt'});
      final resultRevision = row['resultRevision'] == null ? null : _counterIntegerFromWire(row['resultRevision']);
      if (row['schemaVersion'] != 1 || row['operation'] != 'saveStoreCounterDraft' ||
          workspaceLedgerCanonical(row['scope']) != workspaceLedgerCanonical(_customerScopeJson(scope)) ||
          row['idempotencyKey'] != original.idempotencyKey || row['fingerprint'] != original.fingerprint ||
          row['changed'] is! bool || resultRevision != null && resultRevision < 1 ||
          _customerTime(row['recordedAt']).isAfter(observedAt) ||
          resultRevision != null && (draft == null || draft.revision < resultRevision)) throw const FormatException();
      if (row['status'] == 'saved') {
        if (row['reason'] != null || resultRevision != original.draft.revision) throw const FormatException();
        if (draft?.revision == resultRevision &&
            workspaceLedgerCanonical(workspaceCounterDraftToOriginalWire(draft!, scope)) !=
              workspaceLedgerCanonical(original.toJson()['wire'])) {
          throw const FormatException('The original Counter acknowledgement has different input.');
        }
      } else if (row['status'] == 'not_saved') {
        if (!const {'stale_draft', 'recovery_input_changed'}.contains(row['reason']) || row['changed'] != false) throw const FormatException();
      } else {
        throw const FormatException();
      }
      attempt = Map<String, Object?>.unmodifiable(row);
    }
    return WorkspaceCounterOriginalReadback._(currentDraft: draft, attempt: attempt, observedAt: observedAt);
  }
}

class WorkspaceCounterOriginalRequestFailure implements Exception {
  const WorkspaceCounterOriginalRequestFailure({required this.mayHaveCommitted});
  final bool mayHaveCommitted;
  @override String toString() => 'The original Counter draft could not be confirmed. Entered details are kept.';
}

/// Existing authenticated transport; no local outcome, membership or adoption
/// fallback. Status never dispatches Save and stale callbacks are retired.
class WorkspaceCounterOriginalRemoteSource {
  WorkspaceCounterOriginalRemoteSource({required this.scope, required this.connectionId,
    required WorkspacePurchaseEntryRequest request, required bool Function() current, DateTime Function()? now})
    : _request = request, _current = current, _now = now ?? DateTime.now {
    _customerScope(scope); _customerId(connectionId);
  }
  final WorkspaceCustomerScope scope;
  final String connectionId;
  final WorkspacePurchaseEntryRequest _request;
  final bool Function() _current;
  final DateTime Function() _now;
  bool _retired = false;
  bool get current => !_retired && _current();
  void retire() { _retired = true; }
  Future<WorkspaceCounterOriginalReadback> _call(String operation, {WorkspaceCounterOriginalIntent? original, bool mutation = false}) async {
    var dispatched = false;
    try {
      if (!current || original != null && original.scope != scope) throw const FormatException();
      final command = original?.toJson();
      final response = await _request({'operation': operation, 'schemaVersion': 1, 'customerOriginalVersion': 1,
        'actorAccountId': scope.account, 'realm': scope.realm, 'storeId': scope.store,
        if (original != null) 'idempotencyKey': original.idempotencyKey,
        if (original != null) 'fingerprint': original.fingerprint,
        if (mutation) 'expectedRevision': command!['expectedRevision'],
        if (mutation) 'wire': command!['wire']}, () => current, mutation: mutation, onDispatch: () {dispatched = true;});
      if (!current || response?.statusCode != 200) throw const FormatException();
      final envelope = _customerObject(jsonDecode(response!.body)); _customerKeys(envelope, {'ok', 'data'});
      if (envelope['ok'] != true) throw const FormatException();
      final result = WorkspaceCounterOriginalReadback.decode(envelope['data'], scope, _now(), original: original);
      if (mutation && result.attempt == null) throw const FormatException();
      return result;
    } on Object {
      throw WorkspaceCounterOriginalRequestFailure(mayHaveCommitted: mutation && dispatched);
    }
  }
  Future<WorkspaceCounterOriginalReadback> read() => _call('readStoreCounterDraft');
  Future<WorkspaceCounterOriginalReadback> save(WorkspaceCounterOriginalIntent original) =>
    _call('saveStoreCounterDraft', original: original, mutation: true);
  Future<WorkspaceCounterOriginalReadback> status(WorkspaceCounterOriginalIntent original) =>
    _call('readStoreCounterDraftAttempt', original: original);
}

abstract interface class WorkspaceCounterOriginalJournal {
  Future<WorkspaceCounterOriginalIntent?> pending();
  Future<void> retain(WorkspaceCounterOriginalIntent original);
  Future<void> resolve(WorkspaceCounterOriginalIntent original, WorkspaceCounterOriginalReadback result);
}

/// Encrypted pending input and terminal identity only, never sale/customer
/// finance authority. Binding is explicit and cannot silently import or replace
/// retained local bills or an earlier endpoint's pending request.
class SecureWorkspaceCounterOriginalJournal implements WorkspaceCounterOriginalJournal {
  SecureWorkspaceCounterOriginalJournal({required this.scope, required this.connectionId,
    required bool Function() current, FlutterSecureStorage? storage})
    : _current = current, _storage = storage ?? const FlutterSecureStorage() {
    _customerScope(scope); _customerId(connectionId);
  }
  final WorkspaceCustomerScope scope;
  final String connectionId;
  final bool Function() _current;
  final FlutterSecureStorage _storage;
  static final _tails = <String, Future<void>>{};
  String get _key => workspaceCounterOriginalBindingKey(scope);
  void _check() { if (!_current()) throw StateError('Return to the original Store.'); }
  Future<T> _serial<T>(Future<T> Function() action) {
    final key = _key, result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) {if (identical(_tails[key], tail)) _tails.remove(key);}));
    return result;
  }
  Future<Map<String, Object?>?> _read() async {
    _check(); final raw = await _storage.read(key: _key); _check();
    if (raw == null) return null;
    final value = _customerObject(jsonDecode(raw));
    _customerKeys(value, {'schemaVersion', 'scope', 'connectionId', 'pending', 'lastResolved'});
    if (value['schemaVersion'] != 1 || value['connectionId'] != connectionId ||
        workspaceLedgerCanonical(value['scope']) != workspaceLedgerCanonical(_customerScopeJson(scope))) throw const FormatException();
    if (value['pending'] != null) WorkspaceCounterOriginalIntent.fromJson(value['pending'], scope);
    if (value['lastResolved'] != null) {
      final last = _customerObject(value['lastResolved']);
      _customerKeys(last, {'idempotencyKey', 'fingerprint', 'status', 'reason', 'resultRevision'});
      _customerId(last['idempotencyKey']); _customerFingerprint(last['fingerprint']);
      if (last['resultRevision'] != null && _counterIntegerFromWire(last['resultRevision']) < 1) throw const FormatException();
      if (last['status'] == 'saved') {
        if (last['reason'] != null || last['resultRevision'] == null) throw const FormatException();
      } else if (last['status'] == 'not_saved') {
        if (!const {'stale_draft', 'recovery_input_changed'}.contains(last['reason'])) throw const FormatException();
      } else {throw const FormatException();}
    }
    return value;
  }
  Future<void> _write(Map<String, Object?> value) async {
    _check(); final raw = jsonEncode(value);
    try {await _storage.write(key: _key, value: raw);} on Object {
      _check(); if (await _storage.read(key: _key) != raw) rethrow;
    }
    _check();
  }
  /// Caller must first read the original source and prove that local recovery
  /// is pristine. There is no migration/clear or endpoint-rebinding operation.
  Future<void> bindConfirmedOriginal() => _serial(() async {
    if (await _read() != null) return;
    await _write({'schemaVersion': 1, 'scope': _customerScopeJson(scope), 'connectionId': connectionId,
      'pending': null, 'lastResolved': null});
  });
  Future<bool> get bound => _serial(() async => await _read() != null);
  @override Future<WorkspaceCounterOriginalIntent?> pending() => _serial(() async {
    final value = await _read();
    if (value == null) throw StateError('Confirm the original Counter source first.');
    return value['pending'] == null ? null : WorkspaceCounterOriginalIntent.fromJson(value['pending'], scope);
  });
  @override Future<void> retain(WorkspaceCounterOriginalIntent original) => _serial(() async {
    if (original.scope != scope) throw const FormatException();
    final value = await _read();
    if (value == null) throw StateError('Confirm the original Counter source first.');
    if (value['pending'] != null) {
      if (workspaceLedgerCanonical(value['pending']) != workspaceLedgerCanonical(original.toJson())) {
        throw StateError('Check the earlier Counter save before changing this bill.');
      }
      return;
    }
    if (value['lastResolved'] != null) {
      final last = _customerObject(value['lastResolved']);
      if (last['idempotencyKey'] == original.idempotencyKey) {
        throw StateError('This request was already resolved. Refresh the original bill.');
      }
    }
    await _write({...value, 'pending': original.toJson()});
  });
  @override Future<void> resolve(WorkspaceCounterOriginalIntent original, WorkspaceCounterOriginalReadback result) => _serial(() async {
    final value = await _read(), attempt = result.attempt;
    if (original.scope != scope || value == null || attempt == null ||
        workspaceLedgerCanonical(value['pending']) != workspaceLedgerCanonical(original.toJson()) ||
        attempt['idempotencyKey'] != original.idempotencyKey || attempt['fingerprint'] != original.fingerprint) {
      throw StateError('The original Counter request is still unresolved.');
    }
    await _write({...value, 'pending': null, 'lastResolved': {for (final key in
      ['idempotencyKey', 'fingerprint', 'status', 'reason', 'resultRevision']) key: attempt[key]}});
  });
}

class WorkspaceCounterOriginalController {
  WorkspaceCounterOriginalController({required this.source, required this.journal});
  final WorkspaceCounterOriginalRemoteSource source;
  final WorkspaceCounterOriginalJournal journal;
  bool _busy = false;
  Future<WorkspaceCounterOriginalReadback> _exclusive(Future<WorkspaceCounterOriginalReadback> Function() action) async {
    if (_busy || !source.current) throw StateError('Counter recovery is in progress or its Store changed.');
    _busy = true;
    try {return await action();} finally {_busy = false;}
  }
  Future<WorkspaceCounterOriginalReadback> read() => _exclusive(() async {
    final pending = await journal.pending();
    if (pending == null) return source.read();
    final result = await source.status(pending);
    if (result.attempt == null) throw StateError('Check or retry the earlier Counter save. Entered details are kept.');
    await journal.resolve(pending, result); return result;
  });
  Future<WorkspaceCounterOriginalReadback> save(WorkspaceCounterOriginalIntent original) => _exclusive(() async {
    await journal.retain(original);
    final result = await source.save(original);
    await journal.resolve(original, result); return result;
  });
  /// An automatic read never retries a write. Explicit retry first reconciles
  /// the same frozen identity; only confirmed absence may resend that input.
  Future<WorkspaceCounterOriginalReadback> recover({bool retry = false}) => _exclusive(() async {
    final original = await journal.pending();
    if (original == null) return source.read();
    var result = await source.status(original);
    if (result.attempt == null && retry && source.current) result = await source.save(original);
    if (result.attempt != null) await journal.resolve(original, result);
    return result;
  });
}
