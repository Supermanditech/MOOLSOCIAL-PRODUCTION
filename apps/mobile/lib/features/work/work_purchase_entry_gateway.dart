import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../shared/social_content_gateway.dart';
import 'work_models.dart' show WorkspacePurchaseEntryBook, WorkspaceSupplierProfile, WorkspacePurchaseEntryDraft, WorkspacePurchaseSavedCopy, WorkspaceSupplierOpeningRecord;

typedef WorkspacePurchaseEntryScope = ({String account, String store, String realm});
typedef WorkspacePurchaseEntryRequest = Future<SocialContentResponse?> Function(
  Map<String, Object?> body, bool Function() current,
  {required bool mutation, void Function()? onDispatch});

Map<String, Object?> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) throw const FormatException();
  return Map<String, Object?>.from(value);
}
void _keys(Map<String, Object?> value, Set<String> keys) {
  if (value.length != keys.length || !keys.every(value.containsKey)) throw const FormatException();
}
String _id(Object? value) {
  if (value is! String || value.trim().isEmpty || value.length > 2000 ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(value) || utf8.decode(utf8.encode(value)) != value) throw const FormatException();
  return value;
}
int _revision(Object? value) {
  if (value is! int || value < 1 || value > 9007199254740991) throw const FormatException();
  return value;
}
String _fingerprint(Object? value) {
  if (value is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) throw const FormatException();
  return value;
}
DateTime _time(Object? value) {
  if (value is! String || !value.endsWith('Z')) throw const FormatException();
  final parsed = DateTime.parse(value).toUtc();
  if (parsed.toIso8601String() != value) throw const FormatException();
  return parsed;
}
Object? _sorted(Object? value) {
  if (value == null || value is String || value is bool || value is int) return value;
  if (value is List) return value.map(_sorted).toList(growable: false);
  if (value is Map) {
    final values = _object(value), keys = values.keys.toList()..sort();
    return {for (final key in keys) key: _sorted(values[key])};
  }
  throw const FormatException();
}
String _hash(Object? value) => crypto.sha256.convert(utf8.encode(jsonEncode(_sorted(value)))).toString();
Map<String, Object?> _scopeJson(WorkspacePurchaseEntryScope scope) =>
  {'account': scope.account, 'store': scope.store, 'realm': scope.realm};
void _scope(WorkspacePurchaseEntryScope scope) {
  _id(scope.account); _id(scope.store);
  if (!const {'evaluation', 'production'}.contains(scope.realm)) throw const FormatException();
}

/// A frozen original command. Subtypes retain their own data/operation; the
/// account/Store journal is shared so two different operations cannot race.
abstract class WorkspacePurchaseEntrySaveIntent {
  WorkspacePurchaseEntrySaveIntent({required this.scope, required this.expectedRevision,
    required String idempotencyKey, required WorkspaceSupplierProfile profile})
      : idempotencyKey = _id(idempotencyKey), profile = WorkspaceSupplierProfile.fromJson(profile.toJson()) {
    _scope(scope); if (expectedRevision != null) _revision(expectedRevision);
    if (WorkspaceSupplierSaveIntent.validationError(this.profile) != null) throw const FormatException();
  }
  final WorkspacePurchaseEntryScope scope;
  final int? expectedRevision;
  final String idempotencyKey;
  final WorkspaceSupplierProfile profile;
  String get operation;
  Map<String, Object?> get data => {'profile': profile.toJson()};
  Map<String, Object?> get input => {'scope': _scopeJson(scope), 'expectedRevision': expectedRevision,
    'idempotencyKey': idempotencyKey, ...data};
  late final String fingerprint = _hash({'schemaVersion': 1, 'operation': operation, ...input});
  late final String dataFingerprint = _hash({'operation': operation, ...data});
  Map<String, Object?> get receiptFields => const {};
  Map<String, Object?> toJson() => {'schemaVersion': 1,
    if (operation != 'saveSupplierProfile') 'operation': operation, ...input, 'fingerprint': fingerprint};
  WorkspacePurchaseEntrySaveIntent withKey(String key);
  static WorkspacePurchaseEntrySaveIntent fromJson(Object? raw, WorkspacePurchaseEntryScope scope) =>
    _object(raw)['operation'] == 'savePurchaseDraft' ? WorkspacePurchaseDraftSaveIntent.fromJson(raw, scope)
      : _object(raw)['operation'] == 'saveSupplierOpeningEvidence' ? WorkspaceSupplierOpeningSaveIntent.fromJson(raw, scope)
      : WorkspaceSupplierSaveIntent.fromJson(raw, scope);
}

/// Retains the existing supplier-only v1 journal representation.
class WorkspaceSupplierSaveIntent extends WorkspacePurchaseEntrySaveIntent {
  WorkspaceSupplierSaveIntent({required super.scope, required super.expectedRevision,
    required super.idempotencyKey, required super.profile});
  @override String get operation => 'saveSupplierProfile';
  @override WorkspaceSupplierSaveIntent withKey(String key) => WorkspaceSupplierSaveIntent(
    scope: scope, expectedRevision: expectedRevision, idempotencyKey: key, profile: profile);
  static String? validationError(WorkspaceSupplierProfile profile) {
    if (profile.validationError case final error?) return error;
    try {
      _id(profile.id);
      for (final value in [profile.name, profile.address, profile.phone, profile.gstin]) {
        if (RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]').hasMatch(value) || utf8.decode(utf8.encode(value)) != value) {
          throw const FormatException();
        }
      }
      for (final at in [profile.createdAt, profile.updatedAt]) {
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(?:\d{3})?Z$').hasMatch(at.toUtc().toIso8601String())) {
          throw const FormatException();
        }
      }
      return null;
    } on Object {return 'Check the supplier details. Remove unsupported characters before saving.';}
  }
  static WorkspaceSupplierSaveIntent fromJson(Object? raw, WorkspacePurchaseEntryScope expected) {
    final value = _object(raw);
    _keys(value, {'schemaVersion', 'scope', 'expectedRevision', 'idempotencyKey', 'profile', 'fingerprint'});
    if (value['schemaVersion'] != 1 || jsonEncode(_sorted(value['scope'])) != jsonEncode(_sorted(_scopeJson(expected)))) throw const FormatException();
    final result = WorkspaceSupplierSaveIntent(scope: expected,
      expectedRevision: value['expectedRevision'] == null ? null : _revision(value['expectedRevision']),
      idempotencyKey: _id(value['idempotencyKey']), profile: WorkspaceSupplierProfile.fromJson(value['profile']));
    if (_fingerprint(value['fingerprint']) != result.fingerprint) throw const FormatException();
    return result;
  }
}

class WorkspacePurchaseDraftSaveIntent extends WorkspacePurchaseEntrySaveIntent {
  WorkspacePurchaseDraftSaveIntent({required super.scope, required super.expectedRevision,
    required super.idempotencyKey, required super.profile, required WorkspacePurchaseEntryDraft draft,
    WorkspacePurchaseSavedCopy? reviewedCopy, this.replaceReviewedDraftId})
      : _draftJson = jsonEncode(WorkspacePurchaseEntryDraft.fromJson(draft.toJson()).toJson()),
        _copyJson = reviewedCopy == null ? null : jsonEncode(WorkspacePurchaseSavedCopy.fromJson(reviewedCopy.toJson()).toJson()) {
    if (validationError(profile, this.draft, reviewedCopy: this.reviewedCopy, replaceReviewedDraftId: replaceReviewedDraftId) != null) {
      throw const FormatException();
    }
  }
  final String _draftJson;
  final String? _copyJson;
  final String? replaceReviewedDraftId;
  late final String draftFingerprint = _hash(jsonDecode(_draftJson));
  late final String? copyFingerprint = _copyJson == null ? null : _hash(jsonDecode(_copyJson));
  WorkspacePurchaseEntryDraft get draft => WorkspacePurchaseEntryDraft.fromJson(jsonDecode(_draftJson));
  WorkspacePurchaseSavedCopy? get reviewedCopy => _copyJson == null ? null : WorkspacePurchaseSavedCopy.fromJson(jsonDecode(_copyJson));
  @override String get operation => 'savePurchaseDraft';
  @override Map<String, Object?> get data => {...super.data, 'draft': jsonDecode(_draftJson),
    'reviewedCopy': _copyJson == null ? null : jsonDecode(_copyJson), 'replaceReviewedDraftId': replaceReviewedDraftId};
  @override Map<String, Object?> get receiptFields => {'draftId': draft.id, 'draftFingerprint': draftFingerprint,
    'copyId': reviewedCopy?.id, 'copyFingerprint': copyFingerprint};
  bool matchesDraft(WorkspacePurchaseEntryDraft value) => _hash(value.toJson()) == draftFingerprint;
  bool matchesReviewedCopy(WorkspacePurchaseSavedCopy value) => copyFingerprint != null && _hash(value.toJson()) == copyFingerprint;
  bool matchesInput(WorkspaceSupplierProfile profile, WorkspacePurchaseEntryDraft draft,
    {WorkspacePurchaseSavedCopy? reviewedCopy, String? replaceReviewedDraftId}) => dataFingerprint == _hash({
      'operation': operation, 'profile': profile.toJson(), 'draft': draft.toJson(),
      'reviewedCopy': reviewedCopy?.toJson(), 'replaceReviewedDraftId': replaceReviewedDraftId});
  @override WorkspacePurchaseDraftSaveIntent withKey(String key) => WorkspacePurchaseDraftSaveIntent(scope: scope,
    expectedRevision: expectedRevision, idempotencyKey: key, profile: profile, draft: draft,
    reviewedCopy: reviewedCopy, replaceReviewedDraftId: replaceReviewedDraftId);
  static String? validationError(WorkspaceSupplierProfile profile, WorkspacePurchaseEntryDraft draft,
    {WorkspacePurchaseSavedCopy? reviewedCopy, String? replaceReviewedDraftId}) {
    if (WorkspaceSupplierSaveIntent.validationError(profile) case final error?) return error;
    try {
      if (!draft.valid || draft.supplierId != profile.id) throw const FormatException();
      _id(draft.id); _id(draft.supplierId); if (replaceReviewedDraftId != null) _id(replaceReviewedDraftId);
      void text(Object? value) {
        if (value is String) {
          if (RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]').hasMatch(value) || utf8.decode(utf8.encode(value)) != value) throw const FormatException();
        } else if (value is int) {
          if (value.abs() > 9007199254740991) throw const FormatException();
        } else if (value is List) {for (final item in value) {text(item);}}
        else if (value is Map) {for (final entry in value.entries) {text(entry.key); text(entry.value);}}
      }
      final raw = draft.toJson()..remove('attachments'); text(raw);
      for (final date in [draft.createdAt, draft.updatedAt, if (reviewedCopy != null) reviewedCopy.savedAt]) {
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(?:\d{3})?Z$').hasMatch(date.toUtc().toIso8601String())) throw const FormatException();
      }
      if (reviewedCopy != null) {
        if (!reviewedCopy.valid || !reviewedCopy.savedAt.isUtc ||
            jsonEncode(_sorted(reviewedCopy.supplier.toJson())) != jsonEncode(_sorted(profile.toJson())) ||
            jsonEncode(_sorted(reviewedCopy.draft.toJson())) != jsonEncode(_sorted(draft.toJson()))) throw const FormatException();
        _id(reviewedCopy.id); _revision(reviewedCopy.revision); text(reviewedCopy.storeName); text(reviewedCopy.labels);
        if (reviewedCopy.labels.entries.any((entry) => entry.key.trim().isEmpty || entry.value.trim().isEmpty)) throw const FormatException();
        _time(reviewedCopy.savedAt.toIso8601String());
      }
      return null;
    } on Object {return 'Check the purchase details before saving. Your entries are kept.';}
  }
  static WorkspacePurchaseDraftSaveIntent fromJson(Object? raw, WorkspacePurchaseEntryScope expected) {
    final value = _object(raw);
    _keys(value, {'schemaVersion', 'operation', 'scope', 'expectedRevision', 'idempotencyKey', 'profile',
      'draft', 'reviewedCopy', 'replaceReviewedDraftId', 'fingerprint'});
    if (value['schemaVersion'] != 1 || value['operation'] != 'savePurchaseDraft' ||
        jsonEncode(_sorted(value['scope'])) != jsonEncode(_sorted(_scopeJson(expected)))) throw const FormatException();
    final result = WorkspacePurchaseDraftSaveIntent(scope: expected,
      expectedRevision: value['expectedRevision'] == null ? null : _revision(value['expectedRevision']),
      idempotencyKey: _id(value['idempotencyKey']), profile: WorkspaceSupplierProfile.fromJson(value['profile']),
      draft: WorkspacePurchaseEntryDraft.fromJson(value['draft']),
      reviewedCopy: value['reviewedCopy'] == null ? null : WorkspacePurchaseSavedCopy.fromJson(value['reviewedCopy']),
      replaceReviewedDraftId: value['replaceReviewedDraftId'] == null ? null : _id(value['replaceReviewedDraftId']));
    if (_fingerprint(value['fingerprint']) != result.fingerprint) throw const FormatException();
    return result;
  }
}
class WorkspaceSupplierOpeningSaveIntent extends WorkspacePurchaseEntrySaveIntent {
  WorkspaceSupplierOpeningSaveIntent({required super.scope, required super.expectedRevision,
    required super.idempotencyKey, required super.profile, required WorkspaceSupplierOpeningRecord opening})
      : _openingJson = jsonEncode(WorkspaceSupplierOpeningRecord.fromJson(opening.toJson()).toJson()) {
    final value = this.opening;
    if (!value.valid || value.qa || value.account != scope.account || value.store != scope.store ||
        value.supplierId != profile.id || !value.savedAt.isUtc ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.asOfDate) ||
        DateTime.parse('${value.asOfDate}T00:00:00.000Z').toIso8601String().substring(0, 10) != value.asOfDate) throw const FormatException();
    _revision(value.revision); _time(value.savedAt.toIso8601String());
    for (final text in [value.id, value.basisId, value.account, value.store, value.supplierId, value.sourceNote,
      for (final bill in value.bills) ...[bill.copyId, bill.draftId]]) {
      if (RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]').hasMatch(text) || utf8.decode(utf8.encode(text)) != text) throw const FormatException();
    }
    for (final bill in value.bills) {_revision(bill.copyRevision);}
  }
  final String _openingJson;
  WorkspaceSupplierOpeningRecord get opening => WorkspaceSupplierOpeningRecord.fromJson(jsonDecode(_openingJson));
  late final String openingFingerprint = _hash(jsonDecode(_openingJson));
  @override String get operation => 'saveSupplierOpeningEvidence';
  @override Map<String, Object?> get data => {...super.data, 'opening': jsonDecode(_openingJson)};
  @override Map<String, Object?> get receiptFields => {'openingId': opening.id, 'openingFingerprint': openingFingerprint};
  @override WorkspaceSupplierOpeningSaveIntent withKey(String key) => WorkspaceSupplierOpeningSaveIntent(
    scope: scope, expectedRevision: expectedRevision, idempotencyKey: key, profile: profile, opening: opening);
  static WorkspaceSupplierOpeningSaveIntent fromJson(Object? raw, WorkspacePurchaseEntryScope expected) {
    final value = _object(raw); _keys(value, {'schemaVersion', 'operation', 'scope', 'expectedRevision',
      'idempotencyKey', 'profile', 'opening', 'fingerprint'});
    if (value['schemaVersion'] != 1 || value['operation'] != 'saveSupplierOpeningEvidence' ||
        jsonEncode(_sorted(value['scope'])) != jsonEncode(_sorted(_scopeJson(expected)))) throw const FormatException();
    final result = WorkspaceSupplierOpeningSaveIntent(scope: expected,
      expectedRevision: value['expectedRevision'] == null ? null : _revision(value['expectedRevision']),
      idempotencyKey: _id(value['idempotencyKey']), profile: WorkspaceSupplierProfile.fromJson(value['profile']),
      opening: WorkspaceSupplierOpeningRecord.fromJson(value['opening']));
    if (_fingerprint(value['fingerprint']) != result.fingerprint) throw const FormatException();
    return result;
  }
}
Set<String> _terminalReasons(WorkspacePurchaseEntrySaveIntent original) => {
  'stale_book', 'duplicate_supplier', 'capacity_exceeded',
  if (original is WorkspacePurchaseDraftSaveIntent) ...{
    'stale_draft', 'immutable_copy_conflict', 'incomplete_reviewed_copy', 'duplicate_invoice', 'private_original_unavailable'},
  if (original is WorkspaceSupplierOpeningSaveIntent) ...{'supplier_unavailable', 'immutable_opening_conflict', 'stale_opening'},
};

class WorkspaceSupplierSaveReceipt {
  const WorkspaceSupplierSaveReceipt({required this.original, required this.resultRevision,
    required this.status, required this.reason, required this.changed, required this.profile, required this.recordedAt});
  final WorkspacePurchaseEntrySaveIntent original;
  final int? resultRevision;
  final String status;
  final String? reason;
  bool get saved => status == 'saved';
  final bool changed;
  final WorkspaceSupplierProfile profile;
  final DateTime recordedAt;
}
class WorkspacePurchaseEntryReadback {
  const WorkspacePurchaseEntryReadback({required this.book, required this.bookFingerprint,
    required this.observedAt, required this.receipt});
  final WorkspacePurchaseEntryBook? book;
  final String? bookFingerprint;
  final DateTime observedAt;
  final WorkspaceSupplierSaveReceipt? receipt;
  static WorkspacePurchaseEntryReadback decode(Object? raw, WorkspacePurchaseEntryScope scope,
    DateTime now, {WorkspacePurchaseEntrySaveIntent? original}) {
    _scope(scope);
    final value = _object(raw);
    _keys(value, {'schemaVersion', 'purchaseEntryVersion', 'actorAccountId', 'realm', 'storeId',
      'observedAt', 'state', 'bookJson', 'bookFingerprint', 'attempt'});
    final at = _time(value['observedAt']);
    if (value['schemaVersion'] is! int || value['purchaseEntryVersion'] is! int ||
        value['schemaVersion'] != 1 || value['purchaseEntryVersion'] != 1 ||
        value['actorAccountId'] != scope.account || value['storeId'] != scope.store || value['realm'] != scope.realm ||
        at.isAfter(now.toUtc()) || now.toUtc().difference(at) > const Duration(minutes: 1)) throw const FormatException();
    WorkspacePurchaseEntryBook? book;
    String? fingerprint;
    if (value['state'] == 'empty') {
      if (value['bookJson'] != null || value['bookFingerprint'] != null) throw const FormatException();
    } else if (value['state'] == 'ready') {
      final payload = value['bookJson'];
      if (payload is! String || utf8.encode(payload).length > 10 * 1024 * 1024) throw const FormatException();
      fingerprint = _fingerprint(value['bookFingerprint']);
      // Verify the server's exact bytes, not a second numeric serialization.
      if (crypto.sha256.convert(utf8.encode(payload)).toString() != fingerprint) throw const FormatException();
      book = WorkspacePurchaseEntryBook.fromJson(jsonDecode(payload));
      if (book.account != scope.account || book.store != scope.store || book.qa) throw const FormatException();
    } else {throw const FormatException();}
    WorkspaceSupplierSaveReceipt? receipt;
    if (value['attempt'] != null) {
      if (original == null) throw const FormatException();
      final saved = _object(value['attempt']);
      _keys(saved, {'schemaVersion', 'scope', 'operation', 'idempotencyKey', 'fingerprint',
        'status', 'reason', 'changed', 'resultRevision', 'profile', 'recordedAt', ...original.receiptFields.keys});
      final profile = WorkspaceSupplierProfile.fromJson(saved['profile']), recorded = _time(saved['recordedAt']),
        revision = saved['resultRevision'] == null ? null : _revision(saved['resultRevision']);
      final status = saved['status'], reason = saved['reason'];
      if (status == 'saved') {
        if (reason != null || revision == null || book == null) throw const FormatException();
      } else if (status == 'not_saved') {
        if (saved['changed'] != false || !_terminalReasons(original).contains(reason)) throw const FormatException();
      } else {throw const FormatException();}
      if (saved['schemaVersion'] != 1 || saved['operation'] != original.operation || saved['changed'] is! bool ||
          jsonEncode(_sorted(saved['scope'])) != jsonEncode(_sorted(_scopeJson(scope))) || original.scope != scope ||
          saved['idempotencyKey'] != original.idempotencyKey || saved['fingerprint'] != original.fingerprint ||
          jsonEncode(_sorted(profile.toJson())) != jsonEncode(_sorted(original.profile.toJson())) ||
          recorded.isAfter(at) || revision != null && (book == null || revision > book.revision) ||
          original.receiptFields.entries.any((entry) => saved[entry.key] != entry.value)) throw const FormatException();
      receipt = WorkspaceSupplierSaveReceipt(original: original, resultRevision: revision, status: status! as String, reason: reason as String?,
        changed: saved['changed']! as bool, profile: profile, recordedAt: recorded);
    }
    return WorkspacePurchaseEntryReadback(book: book, bookFingerprint: fingerprint, observedAt: at, receipt: receipt);
  }
}
class WorkspacePurchaseEntryRequestFailure implements Exception {
  const WorkspacePurchaseEntryRequestFailure({required this.mayHaveCommitted});
  final bool mayHaveCommitted;
  @override String toString() => 'The original purchase source could not be confirmed. Saved details are kept.';
}

/// Original authenticated transport only. This has no local fallback, synthetic
/// records, book writer, membership grant or subscription decision.
class WorkspacePurchaseEntryRemoteSource {
  WorkspacePurchaseEntryRemoteSource({required this.scope, required this.connectionId,
    required WorkspacePurchaseEntryRequest request, required bool Function() current,
    this.purchaseDraftSupported = false, this.openingEvidenceSupported = false, DateTime Function()? now}) : _request = request, _current = current, _now = now ?? DateTime.now {
    _scope(scope); _id(connectionId);
  }
  final WorkspacePurchaseEntryScope scope;
  final String connectionId;
  final bool purchaseDraftSupported;
  final bool openingEvidenceSupported;
  final WorkspacePurchaseEntryRequest _request;
  final bool Function() _current;
  final DateTime Function() _now;
  bool _retired = false;
  bool get current => !_retired && _current();
  void retire() {_retired = true;}
  Map<String, Object?> get _common => {'schemaVersion': 1, 'purchaseEntryVersion': 1,
    'actorAccountId': scope.account, 'realm': scope.realm, 'storeId': scope.store};
  Future<WorkspacePurchaseEntryReadback> _call(String operation, Map<String, Object?> fields,
    {bool mutation = false, WorkspacePurchaseEntrySaveIntent? original}) async {
    var dispatched = false;
    try {
      if (!current) throw const FormatException();
      final response = await _request({'operation': operation, ..._common, ...fields}, () => current,
        mutation: mutation, onDispatch: () {dispatched = true;});
      if (!current || response?.statusCode != 200) throw const FormatException();
      final envelope = _object(jsonDecode(response!.body)); _keys(envelope, {'ok', 'data'});
      if (envelope['ok'] != true) throw const FormatException();
      final result = WorkspacePurchaseEntryReadback.decode(envelope['data'], scope, _now(), original: original);
      if (mutation && result.receipt == null) throw const FormatException();
      return result;
    } on Object {
      throw WorkspacePurchaseEntryRequestFailure(mayHaveCommitted: mutation && dispatched);
    }
  }
  Future<WorkspacePurchaseEntryReadback> readBook() => _call('readStorePurchaseEntryBook', const {});
  Future<WorkspacePurchaseEntryReadback> saveSupplier(WorkspaceSupplierSaveIntent original) {
    if (original.scope != scope) throw const WorkspacePurchaseEntryRequestFailure(mayHaveCommitted: false);
    return _call('saveStoreSupplierProfile', {'expectedRevision': original.expectedRevision,
      'idempotencyKey': original.idempotencyKey, 'fingerprint': original.fingerprint,
      'profile': original.profile.toJson()}, mutation: true, original: original);
  }
  Future<WorkspacePurchaseEntryReadback> savePurchaseDraft(WorkspacePurchaseDraftSaveIntent original) {
    if (original.scope != scope || !purchaseDraftSupported) throw const WorkspacePurchaseEntryRequestFailure(mayHaveCommitted: false);
    return _call('saveStorePurchaseDraft', {'expectedRevision': original.expectedRevision,
      'idempotencyKey': original.idempotencyKey, 'fingerprint': original.fingerprint, ...original.data}, mutation: true, original: original);
  }
  Future<WorkspacePurchaseEntryReadback> saveOpeningEvidence(WorkspaceSupplierOpeningSaveIntent original) {
    if (original.scope != scope || !openingEvidenceSupported) throw const WorkspacePurchaseEntryRequestFailure(mayHaveCommitted: false);
    return _call('saveStoreSupplierOpeningEvidence', {'expectedRevision': original.expectedRevision,
      'idempotencyKey': original.idempotencyKey, 'fingerprint': original.fingerprint, ...original.data}, mutation: true, original: original);
  }
  Future<WorkspacePurchaseEntryReadback> readAttempt(WorkspacePurchaseEntrySaveIntent original) {
    if (original.scope != scope) throw const WorkspacePurchaseEntryRequestFailure(mayHaveCommitted: false);
    return _call('readStorePurchaseEntryAttempt', {'idempotencyKey': original.idempotencyKey,
      'fingerprint': original.fingerprint}, original: original);
  }
}


class WorkspaceSupplierSaveResolution {
  const WorkspaceSupplierSaveResolution({required this.original, required this.status,
    required this.reason, required this.resultRevision});
  final WorkspacePurchaseEntrySaveIntent original;
  final String status;
  final String? reason;
  final int? resultRevision;
  bool get saved => status == 'saved';
  Map<String, Object?> toJson() => {'original': original.toJson(), 'status': status,
    'reason': reason, 'resultRevision': resultRevision};
  static WorkspaceSupplierSaveResolution decode(Object? raw, WorkspacePurchaseEntryScope scope) {
    final value = _object(raw); _keys(value, {'original', 'status', 'reason', 'resultRevision'});
    final original = WorkspacePurchaseEntrySaveIntent.fromJson(value['original'], scope), status = value['status'], reason = value['reason'],
      revision = value['resultRevision'] == null ? null : _revision(value['resultRevision']);
    if (status == 'saved') {
      if (reason != null || revision == null) throw const FormatException();
    } else if (status == 'not_saved') {
      if (!_terminalReasons(original).contains(reason)) throw const FormatException();
    } else {throw const FormatException();}
    return WorkspaceSupplierSaveResolution(original: original, status: status! as String,
      reason: reason as String?, resultRevision: revision);
  }
}

/// Local operation metadata only. A durable marker survives pending cleanup:
/// an adopted original never silently becomes a separate local canonical writer.
class WorkspacePurchaseEntryJournal {
  WorkspacePurchaseEntryJournal({required this.scope, required this.connectionId,
    required bool Function() current, FlutterSecureStorage? storage})
      : _current = current, _storage = storage ?? const FlutterSecureStorage() {
    _scope(scope); _id(connectionId);
  }
  final WorkspacePurchaseEntryScope scope;
  final String connectionId;
  final bool Function() _current;
  final FlutterSecureStorage _storage;
  static final _tails = <String, Future<void>>{};
  static String _storageKey(WorkspacePurchaseEntryScope scope) =>
    'moolsocial.workspace.purchase-entry-original.v1.${_hash(_scopeJson(scope))}';
  void _check() {if (!_current()) throw const WorkspaceSupplierSaveRecoveryRequired('source_changed');}
  Future<T> _serial<T>(Future<T> Function() action) {
    final key = _storageKey(scope), result = (_tails[key] ?? Future<void>.value()).then((_) => action());
    final tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tails[key] = tail;
    unawaited(tail.then((_) {if (identical(_tails[key], tail)) _tails.remove(key);}));
    return result;
  }
  Map<String, Object?> _decode(String raw) {
    final value = _object(jsonDecode(raw));
    _keys(value, {'schemaVersion', 'scope', 'connectionId', 'pending', 'lastResolved'});
    if (value['schemaVersion'] != 1 || value['connectionId'] != connectionId ||
        jsonEncode(_sorted(value['scope'])) != jsonEncode(_sorted(_scopeJson(scope)))) throw const FormatException();
    if (value['pending'] != null) WorkspacePurchaseEntrySaveIntent.fromJson(value['pending'], scope);
    if (value['lastResolved'] != null) WorkspaceSupplierSaveResolution.decode(value['lastResolved'], scope);
    return value;
  }
  Future<Map<String, Object?>?> _read() async {
    _check(); final raw = await _storage.read(key: _storageKey(scope)); _check();
    return raw == null ? null : _decode(raw);
  }
  Future<void> _write(Map<String, Object?> value) async {
    _check(); final raw = jsonEncode(value);
    try {await _storage.write(key: _storageKey(scope), value: raw);} on Object {
      _check(); if (await _storage.read(key: _storageKey(scope)) != raw) rethrow;
    }
    _check();
  }
  Future<void> adoptConfirmedOriginal() => _serial(() async {
    final existing = await _read(); if (existing != null) return;
    await _write({'schemaVersion': 1, 'scope': _scopeJson(scope), 'connectionId': connectionId,
      'pending': null, 'lastResolved': null});
  });
  Future<({WorkspacePurchaseEntrySaveIntent? pending, WorkspaceSupplierSaveResolution? resolved})> readState() => _serial(() async {
    final value = await _read();
    return (pending: value?['pending'] == null ? null : WorkspacePurchaseEntrySaveIntent.fromJson(value!['pending'], scope),
      resolved: value?['lastResolved'] == null ? null : WorkspaceSupplierSaveResolution.decode(value!['lastResolved'], scope));
  });
  Future<WorkspacePurchaseEntrySaveIntent?> readPending() async => (await readState()).pending;
  Future<void> retain(WorkspacePurchaseEntrySaveIntent original) => _serial(() async {
    if (original.scope != scope) throw const FormatException();
    final value = await _read();
    if (value == null) throw StateError('Confirm the original purchase source first.');
    final pending = value['pending'] == null ? null : WorkspacePurchaseEntrySaveIntent.fromJson(value['pending'], scope);
    if (pending != null) {
      if (pending.fingerprint != original.fingerprint || pending.idempotencyKey != original.idempotencyKey) {
        throw StateError('Recover the original supplier Save first.');
      }
      return;
    }
    await _write({...value, 'pending': original.toJson()});
  });
  Future<void> resolve(WorkspaceSupplierSaveReceipt receipt) => _serial(() async {
    final value = await _read(); if (value == null) throw const FormatException();
    final original = receipt.original;
    if (original.scope != scope) throw const FormatException();
    if (value['pending'] == null) {
      final prior = value['lastResolved'] == null ? null : WorkspaceSupplierSaveResolution.decode(value['lastResolved'], scope);
      if (prior?.original.fingerprint == original.fingerprint && prior?.original.idempotencyKey == original.idempotencyKey) return;
      throw StateError('Keep the current original supplier resolution.');
    }
    final pending = WorkspacePurchaseEntrySaveIntent.fromJson(value['pending'], scope);
    if (pending.fingerprint != original.fingerprint || pending.idempotencyKey != original.idempotencyKey) {
      throw StateError('Keep the other original supplier Save.');
    }
    final resolution = WorkspaceSupplierSaveResolution(original: original, status: receipt.status,
      reason: receipt.reason, resultRevision: receipt.resultRevision);
    await _write({...value, 'pending': null, 'lastResolved': resolution.toJson()});
  });
  static Future<bool> hasOriginalBinding(WorkspacePurchaseEntryScope scope,
    {required bool Function() current, FlutterSecureStorage? storage}) async {
    _scope(scope); if (!current()) throw const FormatException();
    final raw = await (storage ?? const FlutterSecureStorage()).read(key: _storageKey(scope));
    if (!current()) throw const FormatException(); if (raw == null) return false;
    final value = _object(jsonDecode(raw));
    _keys(value, {'schemaVersion', 'scope', 'connectionId', 'pending', 'lastResolved'});
    if (value['schemaVersion'] != 1 || jsonEncode(_sorted(value['scope'])) != jsonEncode(_sorted(_scopeJson(scope)))) throw const FormatException();
    _id(value['connectionId']);
    return true;
  }
}

class WorkspaceSupplierSaveRecoveryRequired implements Exception {
  const WorkspaceSupplierSaveRecoveryRequired(this.reason);
  final String reason;
  @override String toString() => 'Review the original save. Your details are kept.';
}

/// Coordinates explicit supplier Save only. Only terminal original receipts
/// resolve a pending request; no result is inferred from a book revision.
class WorkspaceSupplierSaveController {
  WorkspaceSupplierSaveController({required this.source, required this.journal, String Function()? newKey})
      : _newKey = newKey ?? _identity {
    if (journal.scope != source.scope || journal.connectionId != source.connectionId) {
      throw ArgumentError('Use the same original purchase source and journal.');
    }
  }
  final WorkspacePurchaseEntryRemoteSource source;
  final WorkspacePurchaseEntryJournal journal;
  final String Function() _newKey;
  WorkspacePurchaseEntrySaveIntent? _pending;
  WorkspaceSupplierSaveResolution? _resolved;
  Future<WorkspacePurchaseEntryReadback>? _saving;
  String? _savingSignature;
  bool get current => source.current;
  WorkspacePurchaseEntrySaveIntent? get pending => current ? _pending : null;
  WorkspaceSupplierSaveResolution? get lastResolution => current ? _resolved : null;
  bool get busy => _saving != null;
  static String _identity() {
    final random = Random.secure();
    return 'supplier-save-${DateTime.now().microsecondsSinceEpoch}-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  }
  void _check() {if (!current) throw const WorkspaceSupplierSaveRecoveryRequired('source_changed');}
  Future<void> _restore() async {
    _check(); final state = await journal.readState(); _check(); _pending = state.pending; _resolved = state.resolved;
  }
  Future<void> _resolve(WorkspaceSupplierSaveReceipt receipt) async {
    _check(); await journal.resolve(receipt); _check();
    _resolved = WorkspaceSupplierSaveResolution(original: receipt.original, status: receipt.status,
      reason: receipt.reason, resultRevision: receipt.resultRevision); _pending = null;
  }
  Future<WorkspacePurchaseEntryReadback> readCurrent() async {
    if (busy) throw const WorkspaceSupplierSaveRecoveryRequired('save_in_progress');
    await _restore(); final original = _pending;
    final result = original == null ? await source.readBook() : await source.readAttempt(original);
    _check(); if (result.receipt != null) await _resolve(result.receipt!);
    return result;
  }
  Future<WorkspacePurchaseEntryReadback?> _recover(WorkspacePurchaseEntrySaveIntent requested) async {
    if (busy) return null;
    await _restore(); final original = _pending ?? _resolved?.original;
    if (original == null || original.expectedRevision != requested.expectedRevision ||
        original.dataFingerprint != requested.dataFingerprint) return null;
    final result = await source.readAttempt(original); _check();
    if (result.receipt == null) return null;
    if (_pending != null) await _resolve(result.receipt!);
    return result;
  }
  Future<WorkspacePurchaseEntryReadback> readRetainedAttempt(WorkspacePurchaseEntrySaveIntent original) async {
    if (busy) throw const WorkspaceSupplierSaveRecoveryRequired('save_in_progress');
    await _restore(); final result = await source.readAttempt(original); _check();
    // A historical UI's status read must not clear a newer pending operation.
    if (result.receipt != null && _pending?.idempotencyKey == original.idempotencyKey && _pending?.fingerprint == original.fingerprint) {
      await _resolve(result.receipt!);
    }
    return result;
  }
  Future<WorkspacePurchaseEntryReadback?> recoverOnly(WorkspaceSupplierProfile profile, int? expectedRevision) async =>
    _recover(WorkspaceSupplierSaveIntent(scope: source.scope, expectedRevision: expectedRevision,
      idempotencyKey: 'recovery-selector', profile: profile));
  Future<WorkspacePurchaseEntryReadback?> recoverPurchaseDraft(WorkspaceSupplierProfile profile, WorkspacePurchaseEntryDraft draft,
    {required int? expectedRevision, WorkspacePurchaseSavedCopy? reviewedCopy, String? replaceReviewedDraftId}) async =>
    _recover(WorkspacePurchaseDraftSaveIntent(scope: source.scope, expectedRevision: expectedRevision,
      idempotencyKey: 'recovery-selector', profile: profile, draft: draft, reviewedCopy: reviewedCopy, replaceReviewedDraftId: replaceReviewedDraftId));
  Future<WorkspacePurchaseEntryReadback> save(WorkspaceSupplierProfile profile, int? expectedRevision) async =>
    _save(WorkspaceSupplierSaveIntent(scope: source.scope, expectedRevision: expectedRevision,
      idempotencyKey: 'request-shape', profile: profile));
  Future<WorkspacePurchaseEntryReadback> savePurchaseDraft(WorkspaceSupplierProfile profile, WorkspacePurchaseEntryDraft draft,
    {required int? expectedRevision, WorkspacePurchaseSavedCopy? reviewedCopy, String? replaceReviewedDraftId}) async =>
    _save(WorkspacePurchaseDraftSaveIntent(scope: source.scope, expectedRevision: expectedRevision,
      idempotencyKey: 'request-shape', profile: profile, draft: draft, reviewedCopy: reviewedCopy, replaceReviewedDraftId: replaceReviewedDraftId));
  Future<WorkspacePurchaseEntryReadback> retryPurchaseDraft(WorkspacePurchaseDraftSaveIntent original) =>
    _save(original, retained: original);
  Future<WorkspacePurchaseEntryReadback> saveOpeningEvidence(WorkspaceSupplierProfile profile, WorkspaceSupplierOpeningRecord opening,
    {required int? expectedRevision}) => _save(WorkspaceSupplierOpeningSaveIntent(scope: source.scope,
      expectedRevision: expectedRevision, idempotencyKey: 'request-shape', profile: profile, opening: opening));
  Future<WorkspacePurchaseEntryReadback> retryOpeningEvidence(WorkspaceSupplierOpeningSaveIntent original) => _save(original, retained: original);
  Future<WorkspacePurchaseEntryReadback> _save(WorkspacePurchaseEntrySaveIntent requested, {WorkspacePurchaseEntrySaveIntent? retained}) {
    final signature = _hash([requested.dataFingerprint, requested.expectedRevision, retained?.idempotencyKey]);
    if (_saving != null) {
      if (_savingSignature == signature) return _saving!;
      throw const WorkspaceSupplierSaveRecoveryRequired('save_in_progress');
    }
    late final Future<WorkspacePurchaseEntryReadback> operation;
    _savingSignature = signature;
    operation = Future(() async {
      await _restore(); var original = _pending;
      if (retained != null) {
        if (original == null) {
          // A late Retry must read its known identity, never mint a new Save.
          final status = await source.readAttempt(retained); _check();
          if (status.receipt != null) return status;
          throw const WorkspaceSupplierSaveRecoveryRequired('review_original_save');
        }
        if (original.idempotencyKey != retained.idempotencyKey || original.fingerprint != retained.fingerprint) {
          throw const WorkspaceSupplierSaveRecoveryRequired('review_original_save');
        }
      }
      if (original != null) {
        final status = await source.readAttempt(original); _check();
        if (status.receipt != null) {
          await _resolve(status.receipt!);
          if (original.dataFingerprint != requested.dataFingerprint) {
            throw const WorkspaceSupplierSaveRecoveryRequired('previous_save_resolved');
          }
          return status;
        }
        if (requested.expectedRevision != original.expectedRevision || requested.dataFingerprint != original.dataFingerprint) {
          throw const WorkspaceSupplierSaveRecoveryRequired('review_original_save');
        }
      }
      if (requested is WorkspacePurchaseDraftSaveIntent && !source.purchaseDraftSupported) {
        throw const WorkspacePurchaseEntryRequestFailure(mayHaveCommitted: false);
      }
      if (requested is WorkspaceSupplierOpeningSaveIntent && !source.openingEvidenceSupported) {
        throw const WorkspacePurchaseEntryRequestFailure(mayHaveCommitted: false);
      }
      if (original == null) {
        original = requested.withKey(_newKey());
        await journal.retain(original); _check(); _pending = original;
      }
      final result = original is WorkspacePurchaseDraftSaveIntent ? await source.savePurchaseDraft(original)
        : original is WorkspaceSupplierOpeningSaveIntent ? await source.saveOpeningEvidence(original)
        : await source.saveSupplier(original as WorkspaceSupplierSaveIntent);
      _check(); await _resolve(result.receipt!);
      return result;
    }).whenComplete(() {
      if (identical(_saving, operation)) {_saving = null; _savingSignature = null;}
    });
    return _saving = operation;
  }
}
