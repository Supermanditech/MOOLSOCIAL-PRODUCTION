import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'preparation_pending_store.dart';
import '../journey01/account_profile_gateway.dart' show AccountProfileOwner;
import '../shared/social_content_gateway.dart';

typedef AssistantModelScope = ({String audience, String? storeId});
typedef AssistantNativeTargetHint = ({String actionId, String? entityId});

List<AssistantNativeTargetHint> assistantNativeTargetSelection(List<AssistantNativeTargetHint> values) {
  if (values.length > 5000 || values.toSet().length != values.length || values.any((value) =>
      !RegExp(r'^AI-ACT-\d{3}$').hasMatch(value.actionId) || value.entityId != null &&
      (value.entityId!.length > 128 || !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$').hasMatch(value.entityId!)))) {
    throw const AssistantModelFailure('invalid_request');
  }
  return List.unmodifiable(values);
}

class AssistantModelFailure implements Exception {
  const AssistantModelFailure(this.code);
  final String code;
}

List<String> assistantCatalogueListingSelection(Object? value) {
  if (value is! List || value.length > 500 || value.toSet().length != value.length ||
      value.any((id) => id is! String || !RegExp(r'^listing-[a-f0-9]{64}$').hasMatch(id))) {
    throw const AssistantModelFailure('invalid_request');
  }
  return List<String>.unmodifiable(value.cast<String>());
}

class AssistantModelInput {
  const AssistantModelInput({
    required this.scope,
    required this.requestId,
    required this.requestRevision,
    required this.message,
    required this.language,
    required this.expectedEntitlementRevision,
    this.actionId,
    this.entityId,
    this.history = const [],
    this.catalogueListingIds,
    this.nativeTargets,
  });
  final AssistantModelScope scope;
  final String requestId, message, language, expectedEntitlementRevision;
  final int requestRevision;
  final String? actionId, entityId;
  final List<Map<String, String>> history;
  final List<String>? catalogueListingIds;
  final List<AssistantNativeTargetHint>? nativeTargets;
  AssistantModelInput withCatalogueListingIds(List<String>? ids) => AssistantModelInput(
    scope: scope, requestId: requestId, requestRevision: requestRevision, message: message, language: language,
    expectedEntitlementRevision: expectedEntitlementRevision, actionId: actionId, entityId: entityId, history: history,
    catalogueListingIds: ids == null ? null : assistantCatalogueListingSelection(ids), nativeTargets: nativeTargets);
  AssistantModelInput withNativeTargets(List<AssistantNativeTargetHint>? targets) => AssistantModelInput(
    scope: scope, requestId: requestId, requestRevision: requestRevision, message: message, language: language,
    expectedEntitlementRevision: expectedEntitlementRevision, actionId: actionId, entityId: entityId, history: history,
    catalogueListingIds: catalogueListingIds, nativeTargets: targets == null ? null : assistantNativeTargetSelection(targets));
  Map<String, Object?> toJson() => {
    'scope': {'audience': scope.audience, 'storeId': scope.storeId},
    'requestId': requestId,
    'requestRevision': requestRevision,
    'message': message,
    'expectedEntitlementRevision': expectedEntitlementRevision,
    'language': language,
    'history': history,
    'actionId': actionId,
    'entityId': entityId,
    if (catalogueListingIds != null) 'catalogueListingIds': assistantCatalogueListingSelection(catalogueListingIds),
    if (nativeTargets != null) 'nativeTargets': assistantNativeTargetSelection(nativeTargets!)
      .map((value) => {'actionId': value.actionId, 'entityId': value.entityId}).toList(growable: false),
  };
}

class AssistantModelReply {
  const AssistantModelReply({
    required this.state,
    this.requestId,
    this.requestRevision,
    this.entitlementRevision,
    this.validUntil,
    this.outcome,
  });
  final String state;
  final String? requestId, entitlementRevision;
  final int? requestRevision;
  final DateTime? validUntil;
  final Map<String, Object?>? outcome;
}

abstract interface class AssistantModelSource {
  Object get owner;
  bool get available;
  Future<AssistantModelReply> prepare(
    AssistantModelInput input,
    bool Function() current,
  );
  Future<AssistantModelReply> status(
    AssistantModelInput input,
    bool Function() current,
  );
  Future<AssistantModelReply> cancel(AssistantModelInput input);
}

abstract interface class RecoverableAssistantModelSource implements AssistantModelSource {
  Future<AssistantModelInput?> pending(AssistantModelScope scope, bool Function() current);
  Future<void> acknowledge(AssistantModelInput input);
}

abstract interface class AssistantModelGatewaySource {
  AssistantModelGateway? assistantModelGateway(
    AccountProfileOwner owner,
    bool Function() current,
  );
}

/// Owner-bound transport only. No model key, entitlement issuance or domain writes.
class AssistantModelGateway implements RecoverableAssistantModelSource {
  AssistantModelGateway({
    required this.owner,
    required this.isCurrent,
    required SocialContentCredentials credentials,
    SocialContentTransport? transport,
    AssistantPreparationPendingStore? pendingStore,
    DateTime Function()? clock,
  }) : _credentials = credentials,
       _pendingStore = pendingStore ?? SecureAssistantPreparationPendingStore(),
       _transport =
           transport ??
           IoSocialContentTransport(
             followRedirects: false,
             maximumResponseBytes: 1024 * 1024,
           ),
       _clock = clock ?? DateTime.now {
    if (owner.tenantId != null ||
        owner.userId.isEmpty ||
        !RegExp(r'^[a-z][a-z0-9-]{4,62}$').hasMatch(owner.projectId)) {
      throw const AssistantModelFailure('account_scope_mismatch');
    }
  }
  @override
  final AccountProfileOwner owner;
  final bool Function() isCurrent;
  final SocialContentCredentials _credentials;
  final AssistantPreparationPendingStore _pendingStore;
  final SocialContentTransport _transport;
  final DateTime Function() _clock;
  Future<void> Function(AssistantModelScope)? refreshAuthority;
  bool _disposed = false, _denied = false;
  @override
  bool get available => !_disposed && !_denied && isCurrent();
  void dispose() {
    _disposed = true;
    refreshAuthority = null;
  }

  static final Map<String,Future<void>> _pendingTails={};
  Future<T> _pendingLock<T>(AssistantModelScope scope, Future<T> Function() operation) async {
    final key=_pendingKey(scope),previous=_pendingTails[_pendingKey(scope)],done=Completer<void>();
    _pendingTails[key]=done.future;
    try {await previous;return await operation();}
    finally {done.complete();if(identical(_pendingTails[key],done.future))_pendingTails.remove(key);}
  }
  String _pendingKey(AssistantModelScope scope) => sha256.convert(utf8.encode(jsonEncode([
    owner.environment,owner.projectId,owner.tenantId,owner.userId,scope.audience,scope.storeId]))).toString();
  Future<Map<String,Object?>?> _pendingMetadata(AssistantModelScope scope, bool Function() current) async {
    _check(current);
    final raw=await _pendingStore.read(_pendingKey(scope));_check(current);
    if(raw==null)return null;
    if(utf8.encode(raw).length>4096)throw const AssistantModelFailure('original_request_pending');
    final data=_map(jsonDecode(raw),{'schemaVersion','ownerKey','scope','requestId','requestRevision','expectedEntitlementRevision','actionId','entityId','fingerprint'});
    final savedScope=_map(data['scope'],{'audience','storeId'});
    if(data['schemaVersion']!=1 || data['ownerKey']!=_pendingKey(scope) || savedScope['audience']!=scope.audience || savedScope['storeId']!=scope.storeId ||
       !_id(data['requestId']) || data['requestRevision'] is! int || (data['requestRevision'] as int)<0 ||
       data['expectedEntitlementRevision'] is! String || (data['expectedEntitlementRevision'] as String).length>256 ||
       data['fingerprint'] is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(data['fingerprint'] as String)) {
      throw const AssistantModelFailure('original_request_pending');
    }
    return data;
  }
  @override Future<AssistantModelInput?> pending(AssistantModelScope scope, bool Function() current) async {
    final data=await _pendingLock(scope,()=>_pendingMetadata(scope,current));if(data==null)return null;
    return AssistantModelInput(scope:scope,requestId:data['requestId'] as String,requestRevision:data['requestRevision'] as int,
      message:'Recovered request',language:'Auto',expectedEntitlementRevision:data['expectedEntitlementRevision'] as String,
      actionId:data['actionId'] as String?,entityId:data['entityId'] as String?);
  }
  Future<void> _journal(AssistantModelInput input,bool Function() current) => _pendingLock(input.scope,()=>_journalUnlocked(input,current));
  Future<void> _journalUnlocked(AssistantModelInput input,bool Function() current) async {
    final previous=await _pendingMetadata(input.scope,current);
    final fingerprint=sha256.convert(utf8.encode(jsonEncode(input.toJson()))).toString();
    if(previous!=null){
      if(previous['requestId']!=input.requestId || previous['fingerprint']!=fingerprint)throw const AssistantModelFailure('original_request_pending');
      return;
    }
    final data={'schemaVersion':1,'ownerKey':_pendingKey(input.scope),'scope':{'audience':input.scope.audience,'storeId':input.scope.storeId},
      'requestId':input.requestId,'requestRevision':input.requestRevision,'expectedEntitlementRevision':input.expectedEntitlementRevision,
      'actionId':input.actionId,'entityId':input.entityId,'fingerprint':fingerprint};
    await _pendingStore.write(_pendingKey(input.scope),jsonEncode(data));_check(current);
  }
  @override Future<void> acknowledge(AssistantModelInput input) => _clearOriginal(input);
  Future<void> _clearOriginal(AssistantModelInput input) => _pendingLock(input.scope,()=>_clearOriginalUnlocked(input));
  Future<void> _clearOriginalUnlocked(AssistantModelInput input) async {
    if(!available)return;
    final previous=await _pendingMetadata(input.scope,()=>true);
    if(previous?['requestId']==input.requestId)await _pendingStore.clear(_pendingKey(input.scope));
  }

  void _check(bool Function() current) {
    if (!available || !current())
      throw const AssistantModelFailure('retired_request');
  }

  @override
  Future<AssistantModelReply> prepare(
    AssistantModelInput input,
    bool Function() current,
  ) => _post('prepare', input, current);
  @override
  Future<AssistantModelReply> status(
    AssistantModelInput input,
    bool Function() current,
  ) => _post('status', input, current);
  @override
  Future<AssistantModelReply> cancel(AssistantModelInput input) =>
      _post('cancel', input, () => true);

  Future<AssistantModelReply> _post(
    String operation,
    AssistantModelInput input,
    bool Function() current,
  ) async {
    _check(current);
    if (input.catalogueListingIds != null) input = input.withCatalogueListingIds(input.catalogueListingIds);
    if (input.nativeTargets != null) input = input.withNativeTargets(input.nativeTargets);
    if (input.scope.audience != 'personal' &&
            input.scope.audience != 'workspace' ||
        (input.scope.audience == 'personal'
            ? input.scope.storeId != null
            : input.scope.storeId?.isNotEmpty != true) ||
        !_id(input.requestId) ||
        input.requestRevision < 0 ||
        input.message.trim().isEmpty ||
        input.message.length > 8000 ||
        input.language.trim().isEmpty ||
        input.language.length > 80 ||
        input.expectedEntitlementRevision.isEmpty ||
        input.expectedEntitlementRevision.length > 256) {
      throw const AssistantModelFailure('invalid_request');
    }
    if(operation=='prepare')await _journal(input,current);
    final elapsed = Stopwatch()..start();
    try {
      final token = await _credentials.firebaseIdToken();
      _check(current);
      final proof = await _credentials.appCheckToken(
        SocialAppCheckTokenMode.standard,
      );
      _check(current);
      if (token.trim().isEmpty || proof.trim().isEmpty)
        throw const AssistantModelFailure('authentication_required');
      final response = await _transport.postJson(
        Uri.https(
          'asia-south1-${owner.projectId}.cloudfunctions.net',
          '/moolSocialAssistantPreparation',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Firebase-AppCheck': proof,
        },
        body: {
          'operation': operation,
          'payload': operation == 'prepare'
              ? input.toJson()
              : {
                  'scope': {
                    'audience': input.scope.audience,
                    'storeId': input.scope.storeId,
                  },
                  'requestId': input.requestId,
                },
        },
      );
      _check(current);
      if (utf8.encode(response.body).length > 1024 * 1024) {
        throw const AssistantModelFailure('invalid_response');
      }
      if (response.statusCode != 200) {
        var code = 'assistant_unavailable';
        try {
          final error = _map(jsonDecode(response.body));
          final item = _map(error['error']);
          if (const {
            'ai_access_required',
            'authentication_required',
            'account_scope_mismatch',
            'account_restricted',
            'stale_preparation',
            'stale_entitlement',
            'request_not_found',
            'request_identity_conflict',
          }.contains(item['code'])) {
            code = item['code'] as String;
          }
        } on Object {
          /* Never expose arbitrary provider/server messages. */
        }
        if (response.statusCode == 401 ||
            response.statusCode == 403 &&
                const {
                  'account_scope_mismatch',
                  'account_restricted',
                }.contains(code))
          _denied = true;
        if (const {'stale_entitlement', 'ai_access_required'}.contains(code) &&
            available) {
          try {
            await refreshAuthority?.call(input.scope);
          } on Object {
            /* Remain unavailable; never grant from a failed refresh. */
          }
        }
        if(const {'invalid_request','request_not_found','request_identity_conflict','stale_preparation','stale_entitlement','ai_access_required'}.contains(code)) {
          await _clearOriginal(input);
        }
        throw AssistantModelFailure(code);
      }
      final envelope = _map(jsonDecode(response.body), {'ok', 'data'});
      if (envelope['ok'] != true)
        throw const AssistantModelFailure('assistant_unavailable');
      final data = _map(envelope['data']);
      final state = data['state'];
      if (state is! String ||
          !{'pending', 'uncertain', 'cancelled', 'failed', 'ready'}.contains(state))
        throw const AssistantModelFailure('invalid_response');
      if (state != 'ready') {
        _map(data, {'state'});
        if(state=='cancelled'||state=='failed')await _clearOriginal(input);
        return AssistantModelReply(state: state);
      }
      _map(data, {'state', 'reply'});
      final r = _map(data['reply'], {
        'requestId',
        'requestRevision',
        'scope',
        'entitlementRevision',
        'checkedAt',
        'validUntil',
        'outcome',
      });
      final scope = _map(r['scope'], {'audience', 'storeId'});
      final checked = _stamp(r['checkedAt']), until = _stamp(r['validUntil']);
      final remaining = until.difference(checked) - elapsed.elapsed;
      if (r['requestRevision'] is! int ||
          r['requestId'] != input.requestId ||
          r['requestRevision'] != input.requestRevision ||
          scope['audience'] != input.scope.audience ||
          scope['storeId'] != input.scope.storeId ||
          remaining <= Duration.zero ||
          until.difference(checked) > const Duration(minutes: 1) ||
          r['entitlementRevision'] is! String ||
          (r['entitlementRevision'] as String).isEmpty)
        throw const AssistantModelFailure('stale_preparation');
      final outcome = _map(r['outcome']);
      if (outcome['kind'] == 'clarification') {
        _map(outcome, {'kind', 'text'});
        _text(outcome['text'], 2000);
      } else if (outcome['kind'] == 'proposal') {
        _map(outcome, {
          'kind',
          'id',
          'actionId',
          'entityId',
          'sourceRevision',
          'title',
          'summary',
          'fields',
        });
        if (!_id(outcome['id']) ||
            !_id(outcome['actionId']) ||
            outcome['entityId'] != null && !_id(outcome['entityId']))
          throw const AssistantModelFailure('invalid_response');
        _text(outcome['sourceRevision'], 256);
        _text(outcome['title'], 1000);
        _text(outcome['summary'], 2000);
        _map(outcome['fields']);
      } else {
        throw const AssistantModelFailure('invalid_response');
      }
      return AssistantModelReply(
        state: state,
        requestId: input.requestId,
        requestRevision: input.requestRevision,
        entitlementRevision: r['entitlementRevision'] as String,
        validUntil: _clock().add(remaining),
        outcome: outcome,
      );
    } on AssistantModelFailure {
      rethrow;
    } on Object {
      throw const AssistantModelFailure('assistant_unavailable');
    }
  }
}

Map<String, Object?> _map(Object? value, [Set<String>? keys]) {
  if (value is! Map ||
      value.keys.any((k) => k is! String) ||
      keys != null &&
          (value.length != keys.length || !value.keys.every(keys.contains)))
    throw const AssistantModelFailure('invalid_response');
  return Map<String, Object?>.from(value);
}

bool _id(Object? value) =>
    value is String &&
    RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$').hasMatch(value);
void _text(Object? value, int max) {
  if (value is! String || value.trim().isEmpty || value.length > max)
    throw const AssistantModelFailure('invalid_response');
}

DateTime _stamp(Object? value) {
  if (value is! String) throw const AssistantModelFailure('invalid_response');
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc || parsed.toIso8601String() != value)
    throw const AssistantModelFailure('invalid_response');
  return parsed;
}
