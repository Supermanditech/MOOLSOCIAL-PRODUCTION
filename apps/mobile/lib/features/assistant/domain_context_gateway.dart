import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../journey01/account_profile_gateway.dart' show AccountProfileOwner;
import '../shared/social_content_gateway.dart';
import 'model_gateway.dart';
import 'mool_assistant.dart';
import 'profile_context.dart';

// Match only original readers actually registered in the current backend.
const assistantDomainProductContextActions = {'AI-ACT-006', 'AI-ACT-007', 'AI-ACT-009', 'AI-ACT-014', 'AI-ACT-017', 'AI-ACT-018', 'AI-ACT-019',
  'AI-ACT-336', 'AI-ACT-337', 'AI-ACT-338', 'AI-ACT-339'};
const assistantDomainPreferenceContextActions = {'AI-ACT-010', 'AI-ACT-011', 'AI-ACT-012', 'AI-ACT-013'};
const assistantDomainAddressContextActions = {'AI-ACT-024', 'AI-ACT-027'};
const assistantPrivateStarsContextActions={'AI-ACT-055'};
const assistantStoreProductContextActions = {'AI-ACT-214', 'AI-ACT-221', 'AI-ACT-370', 'AI-ACT-220', 'AI-ACT-230', 'AI-ACT-222', 'AI-ACT-223', 'AI-ACT-226', 'AI-ACT-227', 'AI-ACT-371'};
const assistantStoreDefaultContextActions = {'AI-ACT-218', 'AI-ACT-219'};
const assistantStoreOwnerReadContextActions = {'AI-ACT-213', 'AI-ACT-215', 'AI-ACT-224', 'AI-ACT-372', 'AI-ACT-225', 'AI-ACT-374'};
const assistantStoreStockOwnerContextActions={'AI-ACT-231','AI-ACT-232','AI-ACT-233','AI-ACT-407','AI-ACT-408'};
const assistantStoreRestockOwnerContextActions={'AI-ACT-234'};
const assistantStoreOrderOriginalContextActions={'AI-ACT-274'};
const assistantStoreOperationalContextActions={'AI-ACT-275','AI-ACT-280','AI-ACT-281','AI-ACT-285'};
const assistantStoreOrderBoardContextActions={'AI-ACT-273'};
const assistantStoreSupplierDraftContextActions={'AI-ACT-235','AI-ACT-236'};
const assistantStorePurchaseRootContextActions={'AI-ACT-253','AI-ACT-269'};
const assistantStoreReceivingOriginalContextActions={'AI-ACT-243'};
const assistantStoreCouponContextActions={'AI-ACT-308','AI-ACT-309','AI-ACT-310'};
const assistantStoreOwnerContextActions = {...assistantStoreDefaultContextActions, ...assistantStoreOwnerReadContextActions,...assistantStoreStockOwnerContextActions,...assistantStoreRestockOwnerContextActions,...assistantStoreSupplierDraftContextActions,...assistantStorePurchaseRootContextActions,...assistantStoreOrderBoardContextActions};
const assistantDomainContextActions = {'AI-ACT-001', 'AI-ACT-002', 'AI-ACT-003', 'AI-ACT-004', 'AI-ACT-005',
  ...assistantDomainProductContextActions, ...assistantDomainPreferenceContextActions,
  ...assistantDomainAddressContextActions,...assistantPrivateStarsContextActions,
  ...assistantStoreProductContextActions, ...assistantStoreOwnerContextActions,...assistantStoreOrderOriginalContextActions,...assistantStoreOperationalContextActions,...assistantStoreReceivingOriginalContextActions,...assistantStoreCouponContextActions};

abstract interface class AssistantDomainContextGatewaySource {
  AssistantDomainContextGateway? assistantDomainContextGateway(
      AccountProfileOwner owner, bool Function() current);
}

/// Read-only canonical metadata. No model request, journal, transcript or write.
class AssistantDomainContextGateway {
  AssistantDomainContextGateway({required this.owner, required this.isCurrent,
      required SocialContentCredentials credentials, SocialContentTransport? transport,
      DateTime Function()? clock, this.compactStoreSelection = false})
      : _credentials = credentials, _clock = clock ?? DateTime.now,
        _transport = transport ?? IoSocialContentTransport(
          followRedirects: false, maximumResponseBytes: 2 * 1024 * 1024) {
    if (owner.tenantId != null || owner.userId.isEmpty ||
        !RegExp(r'^[a-z][a-z0-9-]{4,62}$').hasMatch(owner.projectId)) {
      throw const AssistantModelFailure('account_scope_mismatch');
    }
  }
  final AccountProfileOwner owner;
  final bool Function() isCurrent;
  final bool compactStoreSelection;
  final SocialContentCredentials _credentials;
  final SocialContentTransport _transport;
  final DateTime Function() _clock;
  bool _disposed = false, _foreign = false;
  bool get available => !_disposed && !_foreign && isCurrent();
  void dispose() { _disposed = true; }
  Never _invalid() => throw const AssistantModelFailure('context_unavailable');
  Map<String, Object?> _map(Object? value, Set<String> keys) {
    if (value is! Map || value.length != keys.length ||
        value.keys.any((key) => key is! String || !keys.contains(key))) _invalid();
    return Map<String, Object?>.from(value);
  }
  String _text(Object? value, int max) {
    if (value is! String || value.isEmpty || value.length > max ||
        RegExp(r'[\x00-\x1f]').hasMatch(value) || utf8.decode(utf8.encode(value)) != value) _invalid();
    return value;
  }
  Future<AssistantCanonicalContextSnapshot> read(MoolAssistantContext context,
      bool Function() current, {List<String>? catalogueListingIds}) async {
    final selection = catalogueListingIds == null ? null : assistantCatalogueListingSelection(catalogueListingIds);
    void check() {
      if (!available || !current() || !context.signedIn || context.accountScope != owner ||
          context.workspaceId != null && !context.inWorkspace || context.inWorkspace && !context.storeWorkspace) {
        throw const AssistantModelFailure('account_scope_mismatch');
      }
    }
    check();
    final scope = {'audience': context.inWorkspace ? 'workspace' : 'personal',
      'storeId': context.inWorkspace ? context.workspaceId : null};
    final compact = compactStoreSelection && context.inWorkspace;
    final token = await _credentials.firebaseIdToken(); check();
    final proof = await _credentials.appCheckToken(SocialAppCheckTokenMode.standard); check();
    if (token.trim().isEmpty || proof.trim().isEmpty) {
      throw const AssistantModelFailure('authentication_required');
    }
    final response = await _transport.postJson(
      Uri.https('asia-south1-${owner.projectId}.cloudfunctions.net', '/moolSocialAssistantContext'),
      headers: {'Authorization': 'Bearer $token', 'X-Firebase-AppCheck': proof},
      body: {'operation': 'read', 'payload': {'scope': scope,
        if (compact) 'nativeSelectionVersion': 1,
        if (selection != null) 'catalogueListingIds': selection}});
    check();
    if (response.statusCode == 401 || response.statusCode == 403) {
      // A later explicit read may use refreshed access. No private cache exists.
      throw const AssistantModelFailure('ai_access_required');
    }
    if (utf8.encode(response.body).length > 2 * 1024 * 1024 || response.statusCode != 200) _invalid();
    final envelope = _map(jsonDecode(response.body), {'ok', 'data'});
    if (envelope['ok'] != true) _invalid();
    final data = _map(envelope['data'], {'ownerKey', 'scope', 'validUntil', 'revisions', if (compact) 'nativeSelection'});
    final where = _map(data['scope'], {'audience', 'storeId'});
    final expectedOwner = sha256.convert(utf8.encode(jsonEncode([
      owner.projectId, owner.userId, scope['audience'], scope['storeId']]))).toString();
    if (data['ownerKey'] != expectedOwner || where['audience'] != scope['audience'] ||
        where['storeId'] != scope['storeId']) {
      _foreign = true;
      throw const AssistantModelFailure('account_scope_mismatch');
    }
    final stamp = _text(data['validUntil'], 40), until = DateTime.tryParse(stamp)?.toUtc();
    final now = _clock().toUtc();
    if (until == null || until.toIso8601String() != stamp || !until.isAfter(now) ||
        until.isAfter(now.add(const Duration(seconds: 65)))) _invalid();
    if (data['revisions'] is! List || (data['revisions'] as List).length > 5000) _invalid();
    final rows = List<Object?>.of(data['revisions'] as List);
    final masked = <AssistantContextKey, String>{};
    String? selectionFingerprint;
    const maskActions = {...assistantStoreProductContextActions, ...assistantStoreOwnerContextActions,...assistantStoreOrderOriginalContextActions,...assistantStoreOperationalContextActions,...assistantStoreReceivingOriginalContextActions,...assistantStoreCouponContextActions};
    if (compact) {
      final selected = _map(data['nativeSelection'], {'version', 'fingerprint', 'groups'});
      if (selected['version'] != 1 || selected['fingerprint'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(selected['fingerprint'] as String) || selected['groups'] is! List ||
          (selected['groups'] as List).length > 5000) _invalid();
      selectionFingerprint = selected['fingerprint'] as String;
      for (final raw in rows) {
        final row = _map(raw, {'actionId', 'entityId', 'sourceRevision'});
        if (maskActions.contains(row['actionId'])) _invalid();
      }
      for (final raw in selected['groups'] as List) {
        final group = _map(raw, {'actionIds', 'entityId', 'sourceRevision'}), ids = group['actionIds'];
        if (ids is! List || ids.isEmpty || ids.length > maskActions.length || ids.toSet().length != ids.length ||
            rows.length + ids.length > assistantNativeTargetLimit || ids.any((action) => !maskActions.contains(action))) _invalid();
        for (final action in ids) {
          rows.add({'actionId': action, 'entityId': group['entityId'], 'sourceRevision': group['sourceRevision']});
        }
      }
    }
    final revisions = <AssistantContextKey, String>{}, seen = <AssistantContextKey>{};
    const known = {...assistantProfileContextActions, ...assistantWorkspaceContextActions,
      ...assistantDomainContextActions};
    for (final raw in rows) {
      final row = _map(raw, {'actionId', 'entityId', 'sourceRevision'});
      final action = _text(row['actionId'], 32);
      if (!known.contains(action)) _invalid();
      final entity = row['entityId'] == null ? null : _text(row['entityId'], 128);
      final key = (action, entity), revision = _text(row['sourceRevision'], 256);
      if (!seen.add(key) || const {'AI-ACT-001', 'AI-ACT-002', 'AI-ACT-003', 'AI-ACT-004', 'AI-ACT-005',
          ...assistantDomainPreferenceContextActions}.contains(action) &&
          (entity != null || context.inWorkspace)) _invalid();
      if (assistantDomainProductContextActions.contains(action) && (context.inWorkspace || entity == null ||
          selection == null || !selection.contains(entity))) _invalid();
      if (assistantDomainAddressContextActions.contains(action) && (context.inWorkspace || entity == null)) _invalid();
      if(assistantPrivateStarsContextActions.contains(action)&&(context.inWorkspace||entity==null||
        !RegExp(r'^buyer-product-stars:(evaluation|production):[a-f0-9]{64}$').hasMatch(revision)))_invalid();
      if (assistantStoreProductContextActions.contains(action) && (!context.inWorkspace ||
          entity == null && !(action=='AI-ACT-223'&&RegExp(r'^store-product-submission-owner:(evaluation|production):[a-f0-9]{64}$').hasMatch(revision)))) _invalid();
      if (assistantStoreOwnerContextActions.contains(action) && (!context.inWorkspace || entity != null)) _invalid();
      if(assistantStoreCouponContextActions.contains(action)&&(!context.workspaceApproved||!context.storeWorkspace||
        (entity==null?!const {'AI-ACT-308','AI-ACT-309'}.contains(action)||!RegExp(r'^store-coupon-authoring-owner:(evaluation|production):[a-f0-9]{64}$').hasMatch(revision):
        !const {'AI-ACT-309','AI-ACT-310'}.contains(action)||!RegExp(r'^store-coupon-original:(evaluation|production):[a-f0-9]{64}$').hasMatch(revision))))_invalid();
      if (assistantStoreSupplierDraftContextActions.contains(action) &&
          (!context.workspaceApproved || !context.storeWorkspace ||
           !RegExp(r'^store-supplier-draft-owner:[a-f0-9]{64}$').hasMatch(revision))) _invalid();
      if (assistantStorePurchaseRootContextActions.contains(action) &&
          (!context.workspaceApproved || !context.storeWorkspace ||
           !RegExp(r'^store-purchase-root-owner:[a-f0-9]{64}$').hasMatch(revision))) _invalid();
      if (assistantStoreOrderBoardContextActions.contains(action) &&
          (!context.workspaceApproved || !context.storeWorkspace ||
           !RegExp(r'^store-order-board-owner:[a-f0-9]{64}$').hasMatch(revision))) _invalid();
      if (assistantStoreOrderOriginalContextActions.contains(action) && (!context.inWorkspace ||
          !context.storeWorkspace || !context.workspaceApproved || entity == null ||
          !RegExp(r'^store-order-original:(evaluation|production):[a-f0-9]{64}$').hasMatch(revision))) _invalid();
      if (assistantStoreOperationalContextActions.contains(action) && (!context.inWorkspace ||
          !context.storeWorkspace || !context.workspaceApproved || entity == null ||
          !RegExp(r'^store-order-operational:(evaluation|production):[a-f0-9]{64}$').hasMatch(revision))) _invalid();
      if (assistantStoreReceivingOriginalContextActions.contains(action) && (!context.inWorkspace ||
          !context.storeWorkspace || !context.workspaceApproved || entity == null ||
          !RegExp(r'^store-receiving-original:(evaluation|production):[a-f0-9]{64}$').hasMatch(revision))) _invalid();
      if (assistantDomainContextActions.contains(action)) revisions[key] = revision;
      if (compact && maskActions.contains(action)) {
        if (entity != null && !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$').hasMatch(entity)) _invalid();
        masked[key] = revision;
      }
    }
    check();
    return AssistantCanonicalContextSnapshot(binding: context.binding,
      revisions: revisions, validUntil: until, catalogueListingIds: selection,
      nativeSelection: compact ? AssistantCanonicalNativeSelection(fingerprint: selectionFingerprint!, proofs: masked) : null);
  }
}
