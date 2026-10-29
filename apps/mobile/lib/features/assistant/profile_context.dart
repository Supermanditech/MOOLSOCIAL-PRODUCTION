import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'mool_assistant.dart';
import 'model_gateway.dart';

const assistantProfileContextActions = {
  'AI-ACT-025', 'AI-ACT-026', 'AI-ACT-196', 'AI-ACT-197', 'AI-ACT-210',
};
const assistantWorkspaceContextActions = {'AI-ACT-317'};
typedef AssistantContextKey = (String actionId, String? entityId);

String assistantWorkspaceSourceRevision({required String workspaceId,
    required String membershipId, required int version, required DateTime applicationUpdatedAt}) =>
    'workspace:${sha256.convert(utf8.encode(jsonEncode({
      'applicationUpdatedAt': applicationUpdatedAt.toUtc().toIso8601String(),
      'membershipId': membershipId, 'version': version, 'workspaceId': workspaceId,
    })))}';

class AssistantProfileNamePrefill {
  const AssistantProfileNamePrefill({required this.owner, required this.revision,
    required this.displayName});
  final Object owner;
  final int revision;
  final String displayName;
}

/// Canonical revisions only. No private Profile fields are copied into chat.
class AssistantCanonicalNativeSelection {
  factory AssistantCanonicalNativeSelection({required String fingerprint, required Map<AssistantContextKey, String> proofs}) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(fingerprint) || proofs.length > assistantNativeTargetLimit) throw const AssistantModelFailure('context_unavailable');
    final entries = proofs.entries.toList()..sort((a, b) {
      final action = a.key.$1.compareTo(b.key.$1);
      if (action != 0 || a.key.$2 == b.key.$2) return action;
      return a.key.$2 == null ? -1 : b.key.$2 == null ? 1 : a.key.$2!.compareTo(b.key.$2!);
    });
    final ordered = {for (final entry in entries) entry.key: entry.value};
    return AssistantCanonicalNativeSelection._(fingerprint, Map.unmodifiable(ordered), List.unmodifiable(ordered.keys));
  }
  const AssistantCanonicalNativeSelection._(this.fingerprint, this.proofs, this.keys);
  final String fingerprint;
  final Map<AssistantContextKey, String> proofs;
  final List<AssistantContextKey> keys;
}
class AssistantCanonicalContextSnapshot {
  AssistantCanonicalContextSnapshot({required this.binding,
    required Map<AssistantContextKey, String> revisions, required this.validUntil,
    List<String>? catalogueListingIds, this.nativeSelection, this.nativeProductPreviewVersion})
    : revisions = Map.unmodifiable(revisions),
      catalogueListingIds = catalogueListingIds == null ? null : assistantCatalogueListingSelection(catalogueListingIds);
  final Object binding;
  final Map<AssistantContextKey, String> revisions;
  final DateTime validUntil;
  final List<String>? catalogueListingIds;
  final AssistantCanonicalNativeSelection? nativeSelection;
  final int? nativeProductPreviewVersion;
}
typedef AssistantCanonicalContextReader = Future<AssistantCanonicalContextSnapshot>
    Function(MoolAssistantContext context, bool Function() current);

class _NativeAnchor {
  const _NativeAnchor(this.canonical, this.native);
  final String canonical;
  final MoolAssistantNativeSnapshot native;
}

/// Binds original local snapshots BEFORE inference. A later fresh native token
/// can never be substituted to make an older server preparation look current.
class AssistantProfileContextGuard implements MoolAssistantPreparationGuard, MoolAssistantRecoveredReviewGuard, MoolAssistantNativeSelectionGuard, MoolAssistantCompactNativeSelectionGuard, MoolAssistantOriginalRequestSelectionGuard, MoolAssistantProductPreviewSelectionGuard {
  AssistantProfileContextGuard({required this.readCanonical,
    required this.readContext, required this.ownerChanges,
    required Iterable<MoolAssistantNativeAdapter> nativeAdapters,
    DateTime Function()? clock, Set<String>? canonicalActions, Set<String>? recoverableActions})
      : _clock = clock ?? DateTime.now,
        _canonicalActions = Set.unmodifiable(canonicalActions ??
          {...assistantProfileContextActions, ...assistantWorkspaceContextActions}),
        _recoverableActions = Set.unmodifiable(recoverableActions ?? assistantProfileContextActions) {
    _original = List.unmodifiable(nativeAdapters);
    adapters = List.unmodifiable(_original.map((adapter) =>
      _canonicalActions.contains(adapter.actionId)
          ? _CanonicalNativeAdapter(this, adapter) : adapter));
    _observedBinding = readContext().binding;
    ownerChanges.addListener(_ownerChanged);
  }
  final AssistantCanonicalContextReader readCanonical;
  final MoolAssistantContext Function() readContext;
  final Listenable ownerChanges;
  final DateTime Function() _clock;
  final Set<String> _canonicalActions;
  final Set<String> _recoverableActions;
  late final List<MoolAssistantNativeAdapter> _original;
  late final List<MoolAssistantNativeAdapter> adapters;
  Map<AssistantContextKey, _NativeAnchor> _anchors = const {};
  List<bool Function()> _originalRequestChecks = const [];
  AssistantCanonicalContextSnapshot? _canonical;
  int _generation = 0;
  late Object _observedBinding;
  bool _disposed = false;
  @override int? get nativeProductPreviewVersion => current ? _canonical?.nativeProductPreviewVersion : null;
  @override List<String>? get catalogueListingIds => current ? _canonical?.catalogueListingIds : null;
  @override List<AssistantNativeTargetHint>? get nativeTargets => current
    ? assistantNativeTargetSelection([for (final key in _anchors.keys.where((key) => _canonicalActions.contains(key.$1) && _canonical?.nativeSelection?.proofs.containsKey(key) != true))
        (actionId: key.$1, entityId: key.$2)]) : null;
  @override List<AssistantNativeOriginalCapture>? get nativeOriginalCaptures => !current ? null :
    assistantNativeOriginalCaptureSelection([for(final entry in _anchors.entries)
      if(const {'AI-ACT-225','AI-ACT-374'}.contains(entry.key.$1)&&entry.key.$2==null&&entry.value.native.originalRequestCapture!=null)
        (actionId:entry.key.$1,digest:entry.value.native.originalRequestCapture!)]);
  @override Set<String> get nativeMaskedActionIds => !current ? const <String>{} : Set.unmodifiable([
    for (final key in _canonical?.nativeSelection?.keys ?? const <AssistantContextKey>[])
      if (_canonicalActions.contains(key.$1) && _anchors[key]?.canonical == _canonical!.nativeSelection!.proofs[key]) key.$1,
  ]);
  @override AssistantNativeTargetMask? get nativeTargetMask {
    final selection = _canonical?.nativeSelection;
    if (!current || selection == null) return null;
    final bytes = List<int>.filled((selection.keys.length + 7) ~/ 8, 0);
    for (var index = 0; index < selection.keys.length; index++) {
      final key = selection.keys[index];
      if (_canonicalActions.contains(key.$1) && _anchors[key]?.canonical == selection.proofs[key]) bytes[index >> 3] |= 1 << (index % 8);
    }
    return AssistantNativeTargetMask(fingerprint: selection.fingerprint, bits: base64Url.encode(bytes).replaceAll('=', ''));
  }
  void _ownerChanged() {
    final binding = readContext().binding;
    if (binding != _observedBinding) { _observedBinding = binding; retire(); }
    else if(_canonical!=null&&!_originalRequestsCurrent()) {retire();}
  }
  bool _originalRequestsCurrent(){try{return _originalRequestChecks.every((check)=>check());}on Object{return false;}}
  void dispose() {
    if (_disposed) return;
    _disposed = true; ownerChanges.removeListener(_ownerChanged); retire();
  }

  @override bool get current => switch (_canonical) {
    final value? when !_disposed && value.binding == readContext().binding && value.validUntil.isAfter(_clock()) && _originalRequestsCurrent() => true,
    _ => false,
  };
  @override void retire() {
    _generation++; _anchors = const {}; _canonical = null; _originalRequestChecks=const [];
  }
  @override Future<void> captureRecoveredReview(MoolAssistantContext context,
      MoolAssistantProposal proposal, bool Function() valid) async {
    if(!valid() || !proposal.recovered || proposal.preparationRequestId==null ||
       !_recoverableActions.contains(proposal.actionId) ||
       proposal.preparationSourceRevision!=proposal.sourceRevision) throw const AssistantModelFailure('stale_preparation');
    final canonical=await readCanonical(context,valid);
    if(!valid() || canonical.binding!=context.binding || canonical.revisions[(proposal.actionId,proposal.entityId)]!=proposal.sourceRevision) {
      throw const AssistantModelFailure('stale_preparation');
    }
    // The user explicitly requested a NEW native review of the original result.
    // Existing editors/drafts must still satisfy each original adapter snapshot;
    // no old token is relabelled and no form is opened or saved during capture.
    await capture(context,valid);
    if(!valid() || _canonical?.revisions[(proposal.actionId,proposal.entityId)]!=proposal.sourceRevision ||
       !_anchors.containsKey((proposal.actionId,proposal.entityId))) throw const AssistantModelFailure('stale_preparation');
    final retainedCapture=_anchors[(proposal.actionId,proposal.entityId)]?.native.originalRequestCapture;
    if(retainedCapture!=null&&proposal.fields['originalCapture']!=retainedCapture)throw const AssistantModelFailure('stale_preparation');
  }
  @override Future<void> capture(MoolAssistantContext context, bool Function() valid) async {
    retire(); final generation = _generation;
    bool alive() => !_disposed && valid() && generation == _generation &&
        context.binding == readContext().binding;
    final source = await readCanonical(context, alive);
    if (!alive() || source.binding != context.binding || !source.validUntil.isAfter(_clock()) || source.nativeSelection != null && !context.inWorkspace) {
      throw const AssistantModelFailure('stale_preparation');
    }
    final anchors = <AssistantContextKey, _NativeAnchor>{}, originalChecks=<bool Function()>[];
    final batches = <MoolAssistantNativeBatchSnapshot>[], batchRevisions = <Object, String>{};
    for (final adapter in _original) {
      final entries = source.revisions.entries.where((entry) => entry.key.$1 == adapter.actionId).toList(growable: false);
      final entities = entries.map((entry) => entry.key.$2).toList(growable: false);
      final entitySet = entities.toSet();
      final batch = adapter is MoolAssistantBatchNativeAdapter && entries.isNotEmpty ? await adapter.snapshots(context, entities) : null;
      if (!alive()) throw const AssistantModelFailure('stale_preparation');
      if (batch != null) {
        if (batch.sourceRevision.isEmpty || !batch.current() || batchRevisions.containsKey(batch.owner) && batchRevisions[batch.owner] != batch.sourceRevision) {
          throw const AssistantModelFailure('stale_preparation');
        }
        if (batch.entries.length != entitySet.length || batch.entries.keys.any((entity) => !entitySet.contains(entity))) throw const AssistantModelFailure('context_unavailable');
        batchRevisions[batch.owner] = batch.sourceRevision; batches.add(batch);
      }
      for (final entry in entries) {
        final native = batch == null ? await adapter.snapshot(context, entry.key.$2) : batch.entries[entry.key.$2];
        if (!alive()) throw const AssistantModelFailure('stale_preparation');
        if (batch != null && native != null && (native.binding != context.binding || native.entityId != entry.key.$2)) throw const AssistantModelFailure('context_unavailable');
        if (native == null || !native.permitted || native.binding != context.binding ||
            native.entityId != entry.key.$2 || native.sourceRevision.isEmpty) continue;
        if(native.originalRequestCapture!=null) {
          if(batch==null||!const {'AI-ACT-225','AI-ACT-374'}.contains(entry.key.$1)||entry.key.$2!=null||
              !RegExp(r'^[a-f0-9]{64}$').hasMatch(native.originalRequestCapture!))throw const AssistantModelFailure('context_unavailable');
          originalChecks.add(batch.current);
        }
        anchors[entry.key] = _NativeAnchor(entry.value, native);
      }
    }
    final fresh = await readCanonical(context, alive);
    if (!alive() || batches.any((batch) => !batch.current()) || fresh.binding != context.binding ||
        !mapEquals(source.revisions, fresh.revisions) ||
        source.nativeSelection?.fingerprint != fresh.nativeSelection?.fingerprint ||
        !mapEquals(source.nativeSelection?.proofs, fresh.nativeSelection?.proofs) ||
        source.nativeProductPreviewVersion != fresh.nativeProductPreviewVersion ||
        !listEquals(source.catalogueListingIds, fresh.catalogueListingIds) || !fresh.validUntil.isAfter(_clock())) {
      throw const AssistantModelFailure('stale_preparation');
    }
    _canonical = AssistantCanonicalContextSnapshot(binding: context.binding,
      revisions: fresh.revisions,
      catalogueListingIds: fresh.catalogueListingIds,
      nativeSelection: fresh.nativeSelection,
      nativeProductPreviewVersion: fresh.nativeProductPreviewVersion,
      validUntil: source.validUntil.isBefore(fresh.validUntil) ? source.validUntil : fresh.validUntil);
    _anchors = Map.unmodifiable(anchors);
    _originalRequestChecks=List.unmodifiable(originalChecks);
  }

  Future<_NativeAnchor?> _verify(MoolAssistantNativeAdapter adapter,
      MoolAssistantContext context, String? entity, {VoidCallback? onStale}) async {
    if (!current || context.binding != readContext().binding) return null;
    final generation = _generation, key = (adapter.actionId, entity);
    final anchor = _anchors[key]; if (anchor == null) return null;
    bool alive() => current && generation == _generation && context.binding == readContext().binding;
    final fresh = await readCanonical(context, alive);
    if (!alive()) return null;
    if (fresh.binding != context.binding || !fresh.validUntil.isAfter(_clock()) ||
        fresh.revisions[key] != anchor.canonical) {onStale?.call(); return null;}
    final native = await adapter.snapshot(context, entity);
    if (!alive() || native == null) return null;
    if (!native.permitted || native.entityId != entity ||
        native.binding != anchor.native.binding || native.sourceRevision != anchor.native.sourceRevision ||
        native.originalRequestCapture != anchor.native.originalRequestCapture) {onStale?.call(); return null;}
    return anchor;
  }
}

class _CanonicalNativeAdapter implements MoolAssistantOwnerAwareNativeAdapter {
  const _CanonicalNativeAdapter(this.guard, this.original);
  final AssistantProfileContextGuard guard;
  final MoolAssistantNativeAdapter original;
  @override String get actionId => original.actionId;
  @override Set<String> get allowedFields => original.allowedFields;
  @override String? validateFields(Map<String, Object?> fields) => original.validateFields(fields);
  @override Future<MoolAssistantNativeSnapshot?> snapshot(
      MoolAssistantContext context, String? entityId) async {
    var stale = false;
    final anchor = await guard._verify(original, context, entityId, onStale: () => stale = true);
    if (anchor == null) return stale ? MoolAssistantNativeSnapshot(binding: context.binding,
      sourceRevision: 'retired-profile-context', permitted: false, entityId: entityId) : null;
    return MoolAssistantNativeSnapshot(binding: context.binding,
      sourceRevision: anchor.canonical, permitted: true, entityId: entityId, originalRequestCapture:anchor.native.originalRequestCapture);
  }
  @override Future<MoolAssistantReviewResult> openReview(MoolAssistantProposal proposal,
      bool Function() isCurrent) => openOwnedReview(proposal,
        isCurrent: isCurrent, ownerChanges: guard.ownerChanges);
  @override Future<MoolAssistantReviewResult> openOwnedReview(MoolAssistantProposal proposal,
      {required bool Function() isCurrent, required Listenable ownerChanges}) async {
    if (!isCurrent() || proposal.actionId != actionId || validateFields(proposal.fields) != null) {
      return MoolAssistantReviewResult.unavailable;
    }
    final anchor = await guard._verify(original, guard.readContext(), proposal.entityId);
    if (!isCurrent() || anchor == null || anchor.canonical != proposal.sourceRevision ||
        anchor.native.binding != proposal.binding) return MoolAssistantReviewResult.stale;
    if(anchor.native.originalRequestCapture!=null&&proposal.fields['originalCapture']!=anchor.native.originalRequestCapture) {
      return MoolAssistantReviewResult.stale;
    }
    bool current() => isCurrent() && guard.current;
    var fields = proposal.fields;
    final nativeProductRoot=original is MoolAssistantNativeProductRootReviewAdapter&&proposal.entityId==null;
    if(nativeProductRoot&&proposal.fields.isNotEmpty)return MoolAssistantReviewResult.unavailable;
    if (original case final MoolAssistantCanonicalProductIdentityAdapter identity when !nativeProductRoot) {
      if (fields['sourceCanonicalId'] is! String) return MoolAssistantReviewResult.unavailable;
      String? nativeId;
      try {nativeId = await identity.nativeProductIdentity(proposal, current);}
      on Object {return MoolAssistantReviewResult.unavailable;}
      if (!current() || nativeId == null || nativeId.trim().isEmpty) return MoolAssistantReviewResult.stale;
      // Only this one registered identity field changes. The canonical
      // proposal/journal and every price, quantity and input retain their data.
      fields = {...fields, 'sourceCanonicalId': nativeId};
      if (original.validateFields(fields) != null) return MoolAssistantReviewResult.unavailable;
      final fresh = await guard._verify(original, guard.readContext(), proposal.entityId);
      if (!current() || fresh == null || fresh.canonical != proposal.sourceRevision ||
          fresh.native.sourceRevision != anchor.native.sourceRevision || fresh.native.binding != proposal.binding) {
        return MoolAssistantReviewResult.stale;
      }
    }
    final native = MoolAssistantProposal(id: proposal.id, actionId: actionId,
      binding: proposal.binding, requestRevision: proposal.requestRevision,
      entitlementRevision: proposal.entitlementRevision, validUntil: proposal.validUntil,
      sourceRevision: anchor.native.sourceRevision, entityId: proposal.entityId,
      preparationRequestId: proposal.preparationRequestId, recovered:proposal.recovered,
      preparationSourceRevision: proposal.preparationSourceRevision,
      title: proposal.title, summary: proposal.summary, fields: fields);
    final owner = Listenable.merge([guard.ownerChanges, ownerChanges]);
    if (original case final MoolAssistantOwnerAwareNativeAdapter adapter) {
      return adapter.openOwnedReview(native, isCurrent: current, ownerChanges: owner);
    }
    return original.openReview(native, current);
  }
}
