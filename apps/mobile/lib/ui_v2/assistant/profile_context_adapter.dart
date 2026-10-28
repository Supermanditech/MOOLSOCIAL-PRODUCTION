import '../../features/journey01/account_profile_gateway.dart' show AccountProfileAssistantConsent;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../features/assistant/mool_assistant.dart';
import '../../features/assistant/model_gateway.dart';
import '../../features/assistant/profile_context.dart';
import '../../features/assistant/domain_context_gateway.dart';
import '../../features/buy/buy_v2_session.dart';
import '../../features/buy/buy_v2_models.dart' show BuyV2View;
import '../../features/journey01/journey_session.dart';
import '../../features/work/work_session.dart';
import '../../features/work/work_catalogue_gateway.dart' show WorkspaceCatalogueOwnerGateway;
import '../buy/buy_v2_views.dart';
import '../profile/global_personal_profile_v2.dart';

/// Original authenticated gateways only. No local/profile-plan preference grants.
class AssistantOriginalContextReader {
  const AssistantOriginalContextReader({required this.session, required this.work,
    required this.rootCurrent, this.buy});
  final JourneySession session;
  final WorkSession work;
  final BuyV2Session? buy;
  final bool Function() rootCurrent;

  Future<AssistantCanonicalContextSnapshot> read(MoolAssistantContext context,
      bool Function() current) async {
    final owner = session.authenticatedBuyPersistenceIdentity;
    final generation = session.navigationAuthenticationGeneration;
    bool alive() => current() && rootCurrent() && session.isAuthenticated && owner != null &&
        session.authenticatedBuyPersistenceIdentity == owner &&
        session.navigationAuthenticationGeneration == generation && context.accountScope == owner;
    if (!alive()) throw const AssistantModelFailure('account_scope_mismatch');
    final revisions = <AssistantContextKey, String>{};
    bool Function(String) addressSourceReady = (_) => false;
    var until = DateTime.now().toUtc().add(const Duration(seconds: 60));
    if (!context.inWorkspace) {
      final gateway = session.accountProfileGateway;
      if (gateway == null || gateway.owner != owner) throw const AssistantModelFailure('context_unavailable');
      final profile = await gateway.readForPreparation();
      if (!alive() || profile.ownerUid != owner!.userId) throw const AssistantModelFailure('stale_preparation');
      final revision = 'profile:${profile.revision}';
      addressSourceReady = (sourceRevision) => alive() && buy != null &&
          !buy!.isStoreProcurement &&
          !buyV2AddressFormOpen(buy!) && !buyV2AddressRequestFormOpen(buy!) &&
          sourceRevision == revision &&
          buy!.qualifyAccountProfileAddressSnapshotForPreparation(gateway, profile);
      for (final action in assistantProfileContextActions.where((id) => id != 'AI-ACT-026')) {
        revisions[(action, null)] = revision;
      }
      for (final address in profile.addresses) revisions[('AI-ACT-026', address['id'] as String)] = revision;
    } else {
      if (!context.storeWorkspace || !context.workspaceApproved ||
          !work.workspaceRequiresMembershipReadback ||
          !work.workspaceApprovalMatchesAccount(owner) || work.activeWorkspace?.id != context.workspaceId) {
        throw const AssistantModelFailure('context_unavailable');
      }
      final rows = await work.gateway.loadFeed();
      if (!alive()) throw const AssistantModelFailure('stale_preparation');
      final ids = <String>{};
      final now = DateTime.now().toUtc();
      for (final row in rows) {
        final id = row.workspaceId;
        if (id != null && !ids.add(id)) throw const AssistantModelFailure('context_unavailable');
        final proof = row.access;
        if (proof == null) continue;
        if (!{'approved', 'live'}.contains(row.status.name) ||
            !{'retailer-grocery', 'retailer-speciality', 'wholesaler', 'manufacturer'}.contains(row.profileId) ||
            !proof.current(account: owner!.userId, application: row.caseId,
              workspace: id, profile: row.profileId, at: now) ||
            now.difference(proof.checkedAt).inMilliseconds > 60000) {
          throw const AssistantModelFailure('context_unavailable');
        }
        final expires = proof.expiresAt ?? proof.checkedAt.add(const Duration(seconds: 60));
        final valid = proof.checkedAt.add(const Duration(seconds: 60));
        if (expires.isBefore(until)) until = expires;
        if (valid.isBefore(until)) until = valid;
        revisions[('AI-ACT-317', id)] = assistantWorkspaceSourceRevision(workspaceId: id!,
          membershipId: proof.membershipId, version: proof.version, applicationUpdatedAt: proof.applicationUpdatedAt);
      }
      if (!revisions.containsKey(('AI-ACT-317', context.workspaceId))) {
        throw const AssistantModelFailure('context_unavailable');
      }
    }
    final domainGateway = session.assistantDomainContextGateway;
    List<String>? catalogueListingIds;
    AssistantCanonicalNativeSelection? nativeSelection;
    if (domainGateway != null) {
      try {
        final selected = buy?.selectedProduct;
        final candidates = buy != null && buy!.view == BuyV2View.product && selected != null
          ? [selected] : buy != null && const {BuyV2View.cart, BuyV2View.checkout}.contains(buy!.view)
          ? buy!.cartLines.map((line) => line.product) : buy?.visibleProducts;
        final selection = !context.inWorkspace && buy != null && !buy!.isStoreProcurement
          ? candidates!.where((product) => product.publicListingIdentity != null &&
              product.hasValidPublicListingIdentity && !product.requiresPrescription &&
              product.destination == buy!.destination).map((product) => product.id).toSet().toList()
          : null;
        selection?.sort();
        final domain = await domainGateway.read(context, alive, catalogueListingIds: selection);
        if (!alive() || domain.binding != context.binding) throw const AssistantModelFailure('stale_preparation');
        if (domain.revisions.keys.any((key) =>
            !assistantDomainContextActions.contains(key.$1) || revisions.containsKey(key))) {
          throw const AssistantModelFailure('context_unavailable');
        }
        final ready = <AssistantContextKey, String>{};
          if (domain.revisions.keys.any((key) => assistantStoreProductContextActions.contains(key.$1))) {
            // Read only the original pending journal. Never reconcile or replay
            // a command to make an AI preparation appear ready after restart.
            if (!await work.restoreWorkspaceCatalogueListing() || !alive()) {
              throw const AssistantModelFailure('context_unavailable');
            }
          }
        final productProofs = <String, String>{};
        for (final entry in domain.revisions.entries.where((entry) => assistantStoreProductContextActions.contains(entry.key.$1)&&entry.key.$2!=null)) {
          final id = entry.key.$2!;
          if (productProofs.containsKey(id) && productProofs[id] != entry.value) throw const AssistantModelFailure('stale_preparation');
          productProofs[id] = entry.value;
        }
        final acknowledged = work.workspaceAssistantAcknowledgedProducts(productProofs, current: alive);
        final originalOrders = await work.readWorkspaceAssistantOriginalReferences({
          for(final entry in domain.revisions.entries.where((entry)=>
            assistantStoreOrderOriginalContextActions.contains(entry.key.$1)&&entry.key.$2!=null))entry.key.$2!:entry.value,
        },inputCurrent:alive,validUntil:domain.validUntil);
        if (!alive()) throw const AssistantModelFailure('stale_preparation');
        for (final entry in domain.revisions.entries) {
          // Accept only an unchanged original native cache. Explicit refresh,
          // persistence and native final confirmation remain separate actions.
          if (assistantDomainAddressContextActions.contains(entry.key.$1) &&
              !addressSourceReady(entry.value)) continue;
          if(assistantStoreOrderOriginalContextActions.contains(entry.key.$1)&&!originalOrders.contains(entry.key.$2))continue;
          if(assistantStoreRestockOwnerContextActions.contains(entry.key.$1)&&
              !RegExp(r'^store-restock-source:[a-f0-9]{64}$').hasMatch(entry.value))continue;
          final submissionRoot=entry.key.$1=='AI-ACT-223'&&entry.key.$2==null;
          final stockRoot=assistantStoreStockOwnerContextActions.contains(entry.key.$1);
          if (stockRoot||submissionRoot||const {'AI-ACT-213','AI-ACT-215','AI-ACT-224','AI-ACT-225','AI-ACT-374'}.contains(entry.key.$1)) {
            final gateway=work.catalogueGateway;
            final prefix=stockRoot?'store-stock-owner':switch(entry.key.$1){'AI-ACT-213'=>'store-product-authoring-owner',
              'AI-ACT-215'=>'store-product-variants-owner','AI-ACT-223'=>'store-product-submission-owner','AI-ACT-224'=>'store-product-family-owner',_=>'store-product-original-owner'};
            final realm=RegExp('^$prefix:(evaluation|production):[a-f0-9]{64}\$').firstMatch(entry.value)?.group(1);
            if(gateway is! WorkspaceCatalogueOwnerGateway || realm==null || (gateway as WorkspaceCatalogueOwnerGateway).realm!=realm)continue;
          }
          if (assistantStoreProductContextActions.contains(entry.key.$1) && !submissionRoot && !acknowledged.contains(entry.key.$2)) continue;
          ready[entry.key] = entry.value;
        }
        revisions.addAll(ready);
        nativeSelection = domain.nativeSelection;
        catalogueListingIds = domain.catalogueListingIds;
        if (domain.validUntil.isBefore(until)) until = domain.validUntil;
      } on AssistantModelFailure catch (error) {
        // Mirror backend composition: an unavailable optional domain exposes no
        // tools; it never removes established original Profile capabilities.
        if (error.code != 'context_unavailable') rethrow;
      }
    }
    if (!alive() || !until.isAfter(DateTime.now().toUtc())) throw const AssistantModelFailure('stale_preparation');
    return AssistantCanonicalContextSnapshot(binding: context.binding, revisions: revisions, validUntil: until,
      catalogueListingIds: catalogueListingIds, nativeSelection: nativeSelection);
  }
}

List<MoolAssistantNativeAdapter> assistantOriginalProfileAdapters({
  required JourneySession session, required BuyV2Session buy, required NavigatorState navigator,
  required MoolAssistantContext Function() currentContext, required bool Function() rootCurrent,
  required Object Function() routeIdentity, required bool Function() nameEditorAlreadyOpen,
  required Listenable changes, required Future<void> Function() openPersonalPlans,
}) => [for (final id in assistantProfileContextActions)
  _OriginalProfileAdapter(actionId: id, session: session, buy: buy, navigator: navigator,
    currentContext: currentContext, rootCurrent: rootCurrent, routeIdentity: routeIdentity,
    nameEditorAlreadyOpen: nameEditorAlreadyOpen, changes: changes, openPersonalPlans: openPersonalPlans)];

class _OriginalProfileAdapter implements MoolAssistantOwnerAwareNativeAdapter {
  _OriginalProfileAdapter({required this.actionId, required this.session, required this.buy,
    required this.navigator, required this.currentContext, required this.rootCurrent,
    required this.routeIdentity, required this.nameEditorAlreadyOpen, required this.changes,
    required this.openPersonalPlans});
  @override final String actionId;
  final JourneySession session;
  final BuyV2Session buy;
  final NavigatorState navigator;
  final MoolAssistantContext Function() currentContext;
  final bool Function() rootCurrent, nameEditorAlreadyOpen;
  final Object Function() routeIdentity;
  final Listenable changes;
  final Future<void> Function() openPersonalPlans;
  Object? _signature;
  int _version = 0;
  bool _open = false;
  bool get _address => actionId == 'AI-ACT-025' || actionId == 'AI-ACT-026';
  bool get _buyProfileCurrent => !buy.isStoreProcurement && buy.accountProfileAddressesEnabled &&
      session.accountProfileGateway?.ownerScope != null &&
      buy.customerStateStore?.ownerScope == session.accountProfileGateway?.ownerScope;
  bool get _actorCurrent => navigator.mounted && rootCurrent() && session.isAuthenticated &&
      session.accountIdentity?.firebasePrincipal != null && !currentContext().inWorkspace &&
      session.authenticatedBuyPersistenceIdentity == currentContext().accountScope;
  @override Set<String> get allowedFields => switch (actionId) {
    'AI-ACT-196' => {'section'}, 'AI-ACT-197' => {'displayName'},
    'AI-ACT-210' => {}, _ => BuyV2AddressInitialData.allowedFields,
  };
  @override String? validateFields(Map<String, Object?> fields) {
    if (fields.keys.any((key) => !allowedFields.contains(key))) return 'Review these details again.';
    if (actionId == 'AI-ACT-196') {
      if (fields.length != 1 || !{'identity', 'delivery', 'invoices'}.contains(fields['section'])) return 'Choose the details to view.';
      return fields['section'] != 'identity' && !_buyProfileCurrent ? 'Your account details are unavailable.' : null;
    }
    if (actionId == 'AI-ACT-197') {
      final value = fields['displayName'];
      if (fields.length != 1 || value is! String) return 'Enter your display name.';
      final name = value.trim().replaceAll(RegExp(r'\s+'), ' ');
      return name.length >= 2 && name.length <= 60 ? null : 'Enter a display name from 2 to 60 characters.';
    }
    if (actionId == 'AI-ACT-210') return fields.isEmpty ? null : 'Review the plan request again.';
    try {
      final data = BuyV2AddressInitialData.fromFields(fields);
      return actionId == 'AI-ACT-025' && !data.hasSuppliedValue ? 'Add an address detail to review.' : null;
    } on FormatException catch (error) {return error.message;}
  }
  @override Future<MoolAssistantNativeSnapshot?> snapshot(MoolAssistantContext context, String? entityId) async {
    final profile = session.accountProfileGateway?.snapshot;
    if (!_actorCurrent || _open || context.binding != currentContext().binding || profile == null ||
        (actionId == 'AI-ACT-197' && nameEditorAlreadyOpen()) ||
        (_address && (!_buyProfileCurrent || buy.cartChangesBlocked || buyV2AddressFormOpen(buy))) ||
        (actionId == 'AI-ACT-026' ? !profile.addresses.any((a) => a['id'] == entityId) : entityId != null)) return null;
    final signature = (context.binding, routeIdentity(), profile.revision,
      _address ? jsonEncode([buy.navigationMotionSequence, buy.selectedAddressId,
        for (final a in buy.addresses) [a.id, a.recipient, a.phone, a.line, a.area, a.pinCode, a.landmark]]) : null);
    if (_signature != signature) {_signature = signature; _version++;}
    return MoolAssistantNativeSnapshot(binding: context.binding, sourceRevision: 'native-profile:$actionId:$_version', permitted: true, entityId: entityId);
  }
  @override Future<MoolAssistantReviewResult> openReview(MoolAssistantProposal proposal, bool Function() current) =>
      openOwnedReview(proposal, isCurrent: current, ownerChanges: changes);
  @override Future<MoolAssistantReviewResult> openOwnedReview(MoolAssistantProposal proposal,
      {required bool Function() isCurrent, required Listenable ownerChanges}) async {
    final context = currentContext(), native = await snapshot(currentContext(), proposal.entityId);
    if (!isCurrent() || native == null || native.sourceRevision != proposal.sourceRevision ||
        proposal.binding != context.binding || validateFields(proposal.fields) != null) return MoolAssistantReviewResult.stale;
    bool current() => isCurrent() && _actorCurrent && context.binding == currentContext().binding;
    final profile = session.accountProfileGateway!.snapshot!;
    AccountProfileAssistantConsent? consent;
    if (_address || actionId=='AI-ACT-197') {
      if(proposal.preparationRequestId==null || proposal.preparationSourceRevision!='profile:${profile.revision}') {
        return MoolAssistantReviewResult.unavailable;
      }
      consent=AccountProfileAssistantConsent(preparationRequestId:proposal.preparationRequestId!,proposalId:proposal.id,
        actionId:actionId,entityId:proposal.entityId,sourceRevision:proposal.preparationSourceRevision!,entitlementRevision:proposal.entitlementRevision);
      consent.toJson();
    }
    final owner = Listenable.merge([changes, ownerChanges, session, buy]);
    if (!navigator.mounted) return MoolAssistantReviewResult.stale;
    _open = true;
    try {
      if (actionId == 'AI-ACT-210') {
        if (current()) await openPersonalPlans();
      } else if (_address || actionId == 'AI-ACT-196' && proposal.fields['section'] == 'delivery') {
        if (_address) {
          await showBuyV2AddressInitialReview(navigator.context, buy,
            initialData: BuyV2AddressInitialData.fromFields(proposal.fields), scopeOwner: owner, isCurrent: current, assistant:consent,
            existingAddress: actionId == 'AI-ACT-026' ? profile.deliveryAddresses.where((a) => a.id == proposal.entityId).singleOrNull : null);
        } else {
          await showBuyV2AddressSheet(navigator.context, buy);
        }
      } else {
        late final MaterialPageRoute<void> route;
        void close() {if (route.isCurrent && navigator.mounted) navigator.pop();}
        route = MaterialPageRoute<void>(builder: (_) => actionId == 'AI-ACT-197'
          ? GlobalPersonalProfileNameEditorV2(session: session, onSaveDisplayName: (name) => session.saveAccountProfileName(name,assistant:consent),
              preparation: AssistantProfileNamePrefill(owner: session.authenticatedBuyPersistenceIdentity!, revision: profile.revision,
                displayName: proposal.fields['displayName'] as String), preparationCurrent: current, onPreparedClose: close)
          : GlobalPersonalProfileV2(session: session, onPreparedClose: close,
              onOpenAddresses: () {if (current()) showBuyV2AddressSheet(navigator.context, buy);},
              gstDetails: _buyProfileCurrent
                ? BuyV2GstProfileSection(store: buy.gstInvoiceProfileStore, onChanged: buy.refreshGstProfile) : null));
        if (current()) await navigator.push<void>(route);
      }
      return _actorCurrent ? MoolAssistantReviewResult.opened : MoolAssistantReviewResult.stale;
    } finally {_open = false;}
  }
}
