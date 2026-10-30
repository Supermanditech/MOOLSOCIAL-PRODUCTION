import 'dart:convert';
import 'dart:async';

import 'work_ledger_gateway.dart' show workspaceLedgerCanonical, workspaceLedgerFingerprint;
import 'work_purchase_entry_gateway.dart' show WorkspacePurchaseEntryScope, WorkspacePurchaseEntryRequest;
import 'work_publication_data.dart' show WorkspaceStorePublicationDetails;

/// Inputs to existing private forms, never public listing or membership facts.
enum WorkspacePrivatePreferenceKind { status, pickup, invoice, staff }
WorkspacePrivatePreferenceKind? workspacePrivatePreferenceKindForAction(String action) => switch (action) {
  'AI-ACT-318' || 'AI-ACT-319' || 'AI-ACT-327' => WorkspacePrivatePreferenceKind.status,
  'AI-ACT-322' => WorkspacePrivatePreferenceKind.pickup,
  'AI-ACT-323' => WorkspacePrivatePreferenceKind.invoice,
  'AI-ACT-326' => WorkspacePrivatePreferenceKind.staff,
  _ => null,
};

const _keys = <WorkspacePrivatePreferenceKind, Set<String>>{
  WorkspacePrivatePreferenceKind.status: {'acceptingOrders', 'visibleToCustomers', 'fulfilmentMode', 'busyMinutes',
    'reopensAt', 'openingTime', 'closingTime', 'maximumActiveOrders', 'alertSound', 'alertVibration'},
  WorkspacePrivatePreferenceKind.pickup: {'city', 'area', 'pincode', 'pickupEnabled'},
  WorkspacePrivatePreferenceKind.invoice: {'mode'},
  WorkspacePrivatePreferenceKind.staff: {'staffAccessEnabled', 'counterCount'},
};
const _booleans = {'acceptingOrders', 'visibleToCustomers', 'alertSound', 'alertVibration', 'pickupEnabled', 'staffAccessEnabled'};
const _integers = {'busyMinutes', 'maximumActiveOrders', 'counterCount'};
final _maximum = BigInt.parse('9223372036854775807');
Never _invalid() => throw const FormatException('Check the original Store preferences and account/Store context.');
Map<String, Object?> _object(Object? raw) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) _invalid();
  return Map<String, Object?>.from(raw);
}
void _exact(Map<String, Object?> raw, Set<String> keys) {
  if (raw.length != keys.length || !keys.every(raw.containsKey)) _invalid();
}
String _id(Object? raw) {
  if (raw is! String || raw.trim().isEmpty || raw.length > 2000 ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(raw) || utf8.decode(utf8.encode(raw)) != raw) { _invalid(); }
  return raw;
}
String _fingerprint(Object? raw) {
  if (raw is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(raw)) _invalid();
  return raw;
}
int workspacePrivatePreferenceInteger(Object? raw) {
  if (raw is! String || !RegExp(r'^(0|[1-9][0-9]{0,18})$').hasMatch(raw)) _invalid();
  final exact = BigInt.parse(raw);
  if (exact > _maximum) _invalid();
  final value = exact.toInt(); if (BigInt.from(value) != exact) _invalid(); return value;
}
Map<String, Object?> workspacePrivatePreferenceScopeJson(WorkspacePurchaseEntryScope scope) {
  _id(scope.account); _id(scope.store);
  if (!const {'evaluation', 'production'}.contains(scope.realm)) _invalid();
  return {'account': scope.account, 'store': scope.store, 'realm': scope.realm};
}
Map<String, Object?> workspacePrivatePreferenceFieldsFromWire(WorkspacePrivatePreferenceKind kind, Object? raw) {
  final value = _object(raw); _exact(value, _keys[kind]!);
  for (final key in value.keys.toList()) {
    final field = value[key];
    if (_booleans.contains(key)) { if (field is! bool) _invalid(); }
    else if (_integers.contains(key)) {
      final number = workspacePrivatePreferenceInteger(field);
      if (key == 'counterCount' && (number < 1 || number > 20)) _invalid();
      value[key] = number;
    } else {
      if (field is! String || RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]').hasMatch(field) ||
          utf8.decode(utf8.encode(field)) != field) { _invalid(); }
      if (const {'openingTime', 'closingTime'}.contains(key) && !WorkspaceStorePublicationDetails.validTradingTime(field)) _invalid();
      if (key == 'fulfilmentMode' && !const {'Delivery and pickup', 'Pickup only', 'Delivery only'}.contains(field)) _invalid();
      if (const {'city', 'area'}.contains(key) && field.trim().isEmpty) _invalid();
      if (key == 'pincode' && !RegExp(r'^[1-9][0-9]{5}$').hasMatch(field)) _invalid();
      if (key == 'mode' && !const {'off', 'automatic', 'whatsapp', 'moolSocialChat'}.contains(field)) _invalid();
    }
  }
  if (utf8.encode(workspaceLedgerCanonical(raw)).length > 8 * 1024 * 1024 - 128 * 1024) _invalid();
  return Map.unmodifiable(value);
}
Map<String, Object?> workspacePrivatePreferenceFieldsToWire(WorkspacePrivatePreferenceKind kind, Map<String, Object?> native) {
  final result = Map<String, Object?>.from(native);
  for (final key in _integers.intersection(_keys[kind]!)) {
    final raw = result[key]; if (raw is! int || raw < 0 || BigInt.from(raw) > _maximum) _invalid();
    result[key] = raw.toString();
  }
  workspacePrivatePreferenceFieldsFromWire(kind, result); return Map.unmodifiable(result);
}

/// Only the new versioned private source uses decimal integers. Legacy/public
/// settings still go directly through their unchanged native validator.
Map<String, Object?> workspacePrivatePreferenceNativeProposalFields(String action, Map<String, Object?> wire) {
  final allowed = switch (action) {
    'AI-ACT-318' => {'acceptingOrders', 'fulfilmentMode', 'busyMinutes', 'reopensAt'},
    'AI-ACT-319' => {'openingTime', 'closingTime', 'maximumActiveOrders', 'alertSound', 'alertVibration', 'preparationMinutes', 'fulfilmentPreference'},
    'AI-ACT-322' => _keys[WorkspacePrivatePreferenceKind.pickup]!,
    'AI-ACT-323' => _keys[WorkspacePrivatePreferenceKind.invoice]!,
    'AI-ACT-326' => _keys[WorkspacePrivatePreferenceKind.staff]!,
    'AI-ACT-327' => {'visibleToCustomers'},
    _ => <String>{},
  };
  if (wire.isEmpty || wire.keys.any((key) => !allowed.contains(key))) { _invalid(); }
  return Map.unmodifiable({for (final entry in wire.entries) entry.key:
    _integers.contains(entry.key) || entry.key == 'preparationMinutes'
      ? workspacePrivatePreferenceInteger(entry.value) : entry.value});
}

class WorkspacePrivatePreferenceRecord {
  WorkspacePrivatePreferenceRecord.fromJson(Object? raw, {required this.projectId, required this.scope, required this.kind}) {
    final value = _object(raw); _exact(value, {'version', 'projectId', 'scope', 'kind', 'revision', 'fields'});
    if (value['version'] != 1 || value['projectId'] != _id(projectId) || value['kind'] != kind.name ||
        workspaceLedgerCanonical(value['scope']) != workspaceLedgerCanonical(workspacePrivatePreferenceScopeJson(scope))) { _invalid(); }
    revision = workspacePrivatePreferenceInteger(value['revision']); if (revision == 0) _invalid();
    fields = workspacePrivatePreferenceFieldsFromWire(kind, value['fields']);
  }
  final String projectId;
  final WorkspacePurchaseEntryScope scope;
  final WorkspacePrivatePreferenceKind kind;
  late final int revision;
  late final Map<String, Object?> fields;
  Map<String, Object?> toJson() => {'version': 1, 'projectId': projectId, 'scope': workspacePrivatePreferenceScopeJson(scope),
    'kind': kind.name, 'revision': revision.toString(), 'fields': workspacePrivatePreferenceFieldsToWire(kind, fields)};
  String get fingerprint => workspaceLedgerFingerprint(toJson());
}

class WorkspacePrivatePreferenceIntent {
  WorkspacePrivatePreferenceIntent({required this.projectId, required this.scope, required this.kind,
    required this.expectedRevision, required String idempotencyKey, required Map<String, Object?> fields})
    : idempotencyKey = _id(idempotencyKey), fields = workspacePrivatePreferenceFieldsFromWire(kind,
        workspacePrivatePreferenceFieldsToWire(kind, fields)) {
    _id(projectId); workspacePrivatePreferenceScopeJson(scope);
    if (expectedRevision < 0 || BigInt.from(expectedRevision) >= _maximum) _invalid();
  }
  factory WorkspacePrivatePreferenceIntent.fromJson(Object? raw) {
    final value = _object(raw); _exact(value, {'version', 'projectId', 'scope', 'kind', 'expectedRevision', 'idempotencyKey', 'fields', 'fingerprint'});
    final context = _object(value['scope']); _exact(context, {'account', 'store', 'realm'});
    if (value['version'] != 1) _invalid();
    final kinds = WorkspacePrivatePreferenceKind.values.where((kind) => kind.name == value['kind']).toList();
    if (kinds.length != 1) _invalid();
    final kind = kinds.single;
    final result = WorkspacePrivatePreferenceIntent(projectId: _id(value['projectId']),
      scope: (account: _id(context['account']), store: _id(context['store']), realm: _id(context['realm'])), kind: kind,
      expectedRevision: workspacePrivatePreferenceInteger(value['expectedRevision']), idempotencyKey: _id(value['idempotencyKey']),
      fields: workspacePrivatePreferenceFieldsFromWire(kind, value['fields']));
    if (result.fingerprint != _fingerprint(value['fingerprint'])) _invalid(); return result;
  }
  final String projectId;
  final WorkspacePurchaseEntryScope scope;
  final WorkspacePrivatePreferenceKind kind;
  final int expectedRevision;
  final String idempotencyKey;
  final Map<String, Object?> fields;
  Map<String, Object?> get _input => {'version': 1, 'projectId': projectId, 'scope': workspacePrivatePreferenceScopeJson(scope),
    'kind': kind.name, 'expectedRevision': expectedRevision.toString(), 'idempotencyKey': idempotencyKey,
    'fields': workspacePrivatePreferenceFieldsToWire(kind, fields)};
  String get fingerprint => workspaceLedgerFingerprint(_input);
  Map<String, Object?> toJson() => {..._input, 'fingerprint': fingerprint};
}

class WorkspacePrivatePreferenceResult {
  WorkspacePrivatePreferenceResult.fromJson(Object? raw, this.intent) {
    final value = _object(raw); _exact(value, {'receipt', 'original', 'current'});
    WorkspacePrivatePreferenceRecord? parse(Object? raw) => raw == null ? null : WorkspacePrivatePreferenceRecord.fromJson(raw,
      projectId: intent.projectId, scope: intent.scope, kind: intent.kind);
    original = parse(value['original']); current = parse(value['current']);
    if (value['receipt'] == null) {
      if (original != null) _invalid();
      receipt = null; return;
    }
    final r = _object(value['receipt']);
    _exact(r, {'version', 'projectId', 'scope', 'kind', 'idempotencyKey', 'fingerprint', 'expectedRevision',
      'status', 'reason', 'input', 'recordedAt'});
    if (r['version'] != 1 || r['projectId'] != intent.projectId || r['kind'] != intent.kind.name ||
        workspaceLedgerCanonical(r['scope']) != workspaceLedgerCanonical(workspacePrivatePreferenceScopeJson(intent.scope)) ||
        r['idempotencyKey'] != intent.idempotencyKey || r['fingerprint'] != intent.fingerprint ||
        r['expectedRevision'] != intent.expectedRevision.toString() || !const {'saved', 'not_saved'}.contains(r['status']) ||
        r['reason'] != (r['status'] == 'saved' ? null : 'stale_preferences') || original == null) { _invalid(); }
    final time = r['recordedAt'];
    if (time is! String || !time.endsWith('Z') || DateTime.parse(time).toUtc().toIso8601String() != time) _invalid();
    if (original!.revision != intent.expectedRevision + 1 || workspaceLedgerCanonical(original!.fields) != workspaceLedgerCanonical(intent.fields)) _invalid();
    final pointer = _object(r['input']); _exact(pointer, {'id', 'fingerprint', 'revision', 'byteLength', 'parts'});
    final bytes = utf8.encode(workspaceLedgerCanonical(original!.toJson())).length;
    if (pointer['fingerprint'] != original!.fingerprint || pointer['revision'] != original!.revision.toString() ||
        pointer['byteLength'] != bytes || pointer['parts'] != (bytes / (192 * 1024)).ceil() ||
        pointer['id'] != workspaceLedgerFingerprint({'scope': workspacePrivatePreferenceScopeJson(intent.scope), 'kind': intent.kind.name,
          'revision': original!.revision.toString(), 'fingerprint': original!.fingerprint}) ||
        r['status'] == 'saved' && (current == null || current!.revision < original!.revision)) { _invalid(); }
    receipt = Map.unmodifiable({...r, 'scope': Map<String, Object?>.unmodifiable(_object(r['scope'])),
      'input': Map<String, Object?>.unmodifiable(pointer)});
  }
  final WorkspacePrivatePreferenceIntent intent;
  late final WorkspacePrivatePreferenceRecord? original, current;
  late final Map<String, Object?>? receipt;
  bool get confirmed => receipt != null;
  bool get saved => receipt?['status'] == 'saved';
  Map<String, Object?> toJson() => {'receipt': receipt, 'original': original?.toJson(), 'current': current?.toJson()};
}

abstract interface class WorkspacePrivatePreferenceSource {
  bool get current;
  Future<WorkspacePrivatePreferenceRecord?> read();
  Future<WorkspacePrivatePreferenceResult> save(WorkspacePrivatePreferenceIntent original);
  Future<WorkspacePrivatePreferenceResult> status(WorkspacePrivatePreferenceIntent original);
}

class WorkspacePrivatePreferenceRequestFailure implements Exception {
  const WorkspacePrivatePreferenceRequestFailure({required this.mayHaveCommitted});
  final bool mayHaveCommitted;
  @override String toString() => 'Store preferences could not be confirmed. Entered details are kept.';
}

/// Existing authenticated Workspace transport, with no private-source fallback.
/// The caller must opt in to this exact contract before constructing it.
class WorkspacePrivatePreferenceRemoteSource implements WorkspacePrivatePreferenceSource {
  WorkspacePrivatePreferenceRemoteSource({required this.projectId, required this.scope, required this.kind,
    required this.connectionId, required WorkspacePurchaseEntryRequest request, required bool Function() current})
    : _request = request, _current = current {
    _id(projectId); _fingerprint(connectionId); workspacePrivatePreferenceScopeJson(scope);
  }
  final String projectId, connectionId;
  final WorkspacePurchaseEntryScope scope;
  final WorkspacePrivatePreferenceKind kind;
  final WorkspacePurchaseEntryRequest _request;
  final bool Function() _current;
  bool _retired = false;
  @override bool get current => !_retired && _current();
  void retire() { _retired = true; }
  Future<Map<String, Object?>> _call(String operation, {WorkspacePrivatePreferenceIntent? original, bool mutation = false}) async {
    var dispatched = false;
    try {
      if (!current || original != null && (original.projectId != projectId || original.scope != scope || original.kind != kind)) _invalid();
      final response = await _request({'operation': operation, 'schemaVersion': 1, 'storePrivatePreferencesVersion': 1,
        'actorAccountId': scope.account, 'projectId': projectId, 'realm': scope.realm, 'storeId': scope.store, 'kind': kind.name,
        if (mutation) 'command': original!.toJson(),
        if (!mutation && original != null) 'idempotencyKey': original.idempotencyKey,
        if (!mutation && original != null) 'fingerprint': original.fingerprint}, () => current,
        mutation: mutation, onDispatch: () {dispatched = true;}).timeout(const Duration(seconds: 30));
      if (!current || response?.statusCode != 200 || utf8.encode(response!.body).length > 8 * 1024 * 1024) _invalid();
      final envelope = _object(jsonDecode(response.body)); _exact(envelope, {'ok', 'data'});
      if (envelope['ok'] != true) _invalid();
      final data = _object(envelope['data']);
      _exact(data, {'schemaVersion', 'storePrivatePreferencesVersion', 'actorAccountId', 'projectId', 'realm', 'storeId', 'kind',
        if (original == null) 'record' else 'result'});
      if (data['schemaVersion'] != 1 || data['storePrivatePreferencesVersion'] != 1 || data['actorAccountId'] != scope.account ||
          data['projectId'] != projectId || data['realm'] != scope.realm || data['storeId'] != scope.store || data['kind'] != kind.name) _invalid();
      return data;
    } on Object {
      throw WorkspacePrivatePreferenceRequestFailure(mayHaveCommitted: mutation && dispatched);
    }
  }
  @override Future<WorkspacePrivatePreferenceRecord?> read() async {
    final data = await _call('readStorePrivatePreferences');
    return data['record'] == null ? null : WorkspacePrivatePreferenceRecord.fromJson(data['record'], projectId: projectId, scope: scope, kind: kind);
  }
  Future<WorkspacePrivatePreferenceResult> _recovery(String operation, WorkspacePrivatePreferenceIntent intent, {bool mutation = false}) async {
    final data = await _call(operation, original: intent, mutation: mutation), wire = _object(data['result']);
    _exact(wire, {'receipt', 'original', 'currentRevision', 'currentFingerprint'});
    final revision = workspacePrivatePreferenceInteger(wire['currentRevision']);
    final original = wire['original'] == null ? null : WorkspacePrivatePreferenceRecord.fromJson(wire['original'], projectId: projectId, scope: scope, kind: kind);
    WorkspacePrivatePreferenceRecord? present;
    if (revision == 0) { if (wire['currentFingerprint'] != null) _invalid(); }
    else {
      final expected = _fingerprint(wire['currentFingerprint']);
      present = original?.revision == revision && original?.fingerprint == expected ? original : await read();
      if (!current || present?.revision != revision || present?.fingerprint != expected) _invalid();
    }
    final result = WorkspacePrivatePreferenceResult.fromJson({'receipt': wire['receipt'], 'original': original?.toJson(), 'current': present?.toJson()}, intent);
    if (!current || mutation && !result.confirmed) _invalid(); return result;
  }
  @override Future<WorkspacePrivatePreferenceResult> save(WorkspacePrivatePreferenceIntent original) =>
    _recovery('saveStorePrivatePreferences', original, mutation: true);
  @override Future<WorkspacePrivatePreferenceResult> status(WorkspacePrivatePreferenceIntent original) =>
    _recovery('checkStorePrivatePreferencesSave', original);
}

/// Implementations bind account/project/realm/Store/group and endpoint. Retain
/// is durable before dispatch; resolve is a same-original compare-and-set and
/// retains the complete resolved input/result for recovery. No endpoint reset.
abstract interface class WorkspacePrivatePreferenceJournal {
  Future<WorkspacePrivatePreferenceIntent?> pending();
  Future<void> retain(WorkspacePrivatePreferenceIntent original);
  Future<void> resolve(WorkspacePrivatePreferenceIntent original, WorkspacePrivatePreferenceResult result);
}

abstract interface class WorkspacePrivatePreferenceJournalStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// A closed, endpoint-bound recovery journal, not preference/source authority.
/// Production supplies the existing secure storage. There is no delete, reset,
/// endpoint migration or automatic request replay operation.
class StoredWorkspacePrivatePreferenceJournal implements WorkspacePrivatePreferenceJournal {
  StoredWorkspacePrivatePreferenceJournal({required this.projectId, required this.scope, required this.kind,
    required this.connectionId, required WorkspacePrivatePreferenceJournalStorage storage, required bool Function() current})
    : _storage = storage, _current = current {
    _id(projectId); _fingerprint(connectionId); workspacePrivatePreferenceScopeJson(scope);
  }
  final String projectId, connectionId;
  final WorkspacePurchaseEntryScope scope;
  final WorkspacePrivatePreferenceKind kind;
  final WorkspacePrivatePreferenceJournalStorage _storage;
  final bool Function() _current;
  static final _tails = <String, Future<void>>{};
  String get storageKey => 'moolsocial.work.private-preferences.v1.${workspaceLedgerFingerprint({
    'projectId': projectId, 'scope': workspacePrivatePreferenceScopeJson(scope), 'kind': kind.name})}';
  void _check() { if (!_current()) throw StateError('Return to the original Store. Entered details are kept.'); }
  void _intent(WorkspacePrivatePreferenceIntent input) {
    if (input.projectId != projectId || input.scope != scope || input.kind != kind) _invalid();
  }
  Future<T> _serial<T>(Future<T> Function() action) {
    final key = storageKey, result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) {if (identical(_tails[key], tail)) _tails.remove(key);})); return result;
  }
  Future<Map<String, Object?>?> _read() async {
    _check(); final raw = await _storage.read(storageKey); _check();
    if (raw == null) return null;
    final value = _object(jsonDecode(raw));
    _exact(value, {'version', 'projectId', 'scope', 'kind', 'connectionId', 'pending', 'lastResolved'});
    if (value['version'] != 1 || value['projectId'] != projectId || value['kind'] != kind.name || value['connectionId'] != connectionId ||
        workspaceLedgerCanonical(value['scope']) != workspaceLedgerCanonical(workspacePrivatePreferenceScopeJson(scope))) _invalid();
    if (value['pending'] != null) _intent(WorkspacePrivatePreferenceIntent.fromJson(value['pending']));
    if (value['lastResolved'] != null) {
      final last = _object(value['lastResolved']); _exact(last, {'intent', 'result'});
      final input = WorkspacePrivatePreferenceIntent.fromJson(last['intent']); _intent(input);
      if (!WorkspacePrivatePreferenceResult.fromJson(last['result'], input).confirmed) _invalid();
    }
    return value;
  }
  Future<void> _write(Map<String, Object?> value) async {
    _check(); final raw = jsonEncode(value);
    try {await _storage.write(storageKey, raw);} on Object {
      _check(); if (await _storage.read(storageKey) != raw) rethrow;
    }
    _check(); if (await _storage.read(storageKey) != raw) throw StateError('Store preference recovery could not be retained.');
    _check();
  }
  Future<bool> get bound => _serial(() async => await _read() != null);
  /// Caller must have completed the original remote read, before opening an
  /// edited form. Null is allowed only for that successful empty original.
  Future<void> bindConfirmedOriginal(WorkspacePrivatePreferenceRecord? record) => _serial(() async {
    if (record != null && (record.projectId != projectId || record.scope != scope || record.kind != kind)) _invalid();
    if (await _read() != null) return;
    await _write({'version': 1, 'projectId': projectId, 'scope': workspacePrivatePreferenceScopeJson(scope),
      'kind': kind.name, 'connectionId': connectionId, 'pending': null, 'lastResolved': null});
  });
  @override Future<WorkspacePrivatePreferenceIntent?> pending() => _serial(() async {
    final value = await _read();
    if (value == null) throw StateError('Confirm the original Store preference source first.');
    return value['pending'] == null ? null : WorkspacePrivatePreferenceIntent.fromJson(value['pending']);
  });
  @override Future<void> retain(WorkspacePrivatePreferenceIntent input) => _serial(() async {
    _intent(input); final value = await _read();
    if (value == null) throw StateError('Confirm the original Store preference source first.');
    if (value['pending'] != null) {
      if (workspaceLedgerCanonical(value['pending']) != workspaceLedgerCanonical(input.toJson())) {
        throw StateError('Check the earlier Save before changing these preferences.');
      }
      return;
    }
    if (value['lastResolved'] != null && _object(_object(value['lastResolved'])['intent'])['idempotencyKey'] == input.idempotencyKey) {
      throw StateError('This Save was already resolved. Refresh the original preferences.');
    }
    await _write({...value, 'pending': input.toJson()});
  });
  @override Future<void> resolve(WorkspacePrivatePreferenceIntent input, WorkspacePrivatePreferenceResult result) => _serial(() async {
    _intent(input); final value = await _read();
    if (value == null || !result.confirmed || workspaceLedgerCanonical(value['pending']) != workspaceLedgerCanonical(input.toJson()) ||
        workspaceLedgerCanonical(result.intent.toJson()) != workspaceLedgerCanonical(input.toJson())) {
      throw StateError('The original Store preference request is still unresolved.');
    }
    await _write({...value, 'pending': null, 'lastResolved': {'intent': input.toJson(), 'result': result.toJson()}});
  });
}

class WorkspacePrivatePreferenceController {
  WorkspacePrivatePreferenceController({required this.projectId, required this.scope, required this.kind,
    required this.source, required this.journal});
  final String projectId;
  final WorkspacePurchaseEntryScope scope;
  final WorkspacePrivatePreferenceKind kind;
  final WorkspacePrivatePreferenceSource source;
  final WorkspacePrivatePreferenceJournal journal;
  bool _busy = false, _retired = false;
  void retire() { _retired = true; }
  bool get current => !_retired && source.current;
  void _requireCurrent() {
    if (!current) throw StateError('The original account or Store changed. Entered details are kept.');
  }
  void _requireIntent(WorkspacePrivatePreferenceIntent original) {
    if (original.projectId != projectId || original.scope != scope || original.kind != kind) _invalid();
  }
  Future<T> _exclusive<T>(Future<T> Function() action) async {
    _requireCurrent();
    if (_busy) throw StateError('Check the current Store preference request first.');
    _busy = true;
    try { return await action(); } finally { _busy = false; }
  }
  Future<WorkspacePrivatePreferenceRecord?> read() => _exclusive(() async {
    final pending = await journal.pending(); _requireCurrent();
    if (pending != null) throw StateError('Check the earlier Save. Entered details are kept.');
    final result = await source.read(); _requireCurrent();
    if (result != null && (result.projectId != projectId || result.scope != scope || result.kind != kind)) _invalid();
    return result;
  });
  void _requireResult(WorkspacePrivatePreferenceIntent original, WorkspacePrivatePreferenceResult result) {
    _requireCurrent(); _requireIntent(original);
    if (workspaceLedgerCanonical(result.intent.toJson()) != workspaceLedgerCanonical(original.toJson())) _invalid();
  }
  Future<WorkspacePrivatePreferenceResult> _finish(WorkspacePrivatePreferenceIntent original,
      WorkspacePrivatePreferenceResult result) async {
    _requireResult(original, result);
    if (result.confirmed) { await journal.resolve(original, result); _requireCurrent(); }
    return result;
  }
  Future<WorkspacePrivatePreferenceResult> save(WorkspacePrivatePreferenceIntent original) => _exclusive(() async {
    _requireIntent(original);
    final pending = await journal.pending(); _requireCurrent();
    if (pending != null) throw StateError('Check or retry the earlier Save before starting another.');
    await journal.retain(original); _requireCurrent();
    return _finish(original, await source.save(original));
  });
  /// Explicit check is observational. Only an explicit retry after confirmed
  /// absence may resend the frozen original; no new identity or revision fetch.
  Future<WorkspacePrivatePreferenceResult> check({bool retry = false}) => _exclusive(() async {
    final original = await journal.pending(); _requireCurrent();
    if (original == null) throw StateError('There is no pending Store preference Save.');
    _requireIntent(original);
    var result = await source.status(original); _requireResult(original, result);
    if (!result.confirmed && retry) { result = await source.save(original); _requireCurrent(); }
    return _finish(original, result);
  });
}
