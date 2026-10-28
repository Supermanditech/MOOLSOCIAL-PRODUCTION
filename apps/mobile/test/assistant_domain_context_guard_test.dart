import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/assistant/model_gateway.dart';
import 'package:moolsocial/features/assistant/profile_context.dart';

class _SearchNative implements MoolAssistantNativeAdapter {
  @override String get actionId => 'AI-ACT-001';
  int version = 1, opens = 0;
  bool permitted = true;
  MoolAssistantProposal? reviewed;
  @override Set<String> get allowedFields => {'query'};
  @override String? validateFields(Map<String, Object?> fields) =>
    fields.length == 1 && fields['query'] is String ? null : 'Use the original query field.';
  @override Future<MoolAssistantNativeSnapshot?> snapshot(MoolAssistantContext c, String? entity) async =>
    MoolAssistantNativeSnapshot(binding: c.binding, entityId: entity,
      sourceRevision: 'original-search:$version', permitted: permitted);
  @override Future<MoolAssistantReviewResult> openReview(MoolAssistantProposal p, bool Function() current) async {
    if (!current() || p.sourceRevision != 'original-search:$version') return MoolAssistantReviewResult.stale;
    opens++; reviewed = p; return MoolAssistantReviewResult.opened;
  }
}
class _OriginalCaptureNative extends _SearchNative implements MoolAssistantBatchNativeAdapter {
  String capture='a'*64;
  bool lieAboutCurrent=false;
  @override String get actionId=>'AI-ACT-225';
  @override Set<String> get allowedFields=>{'originalCapture'};
  @override String? validateFields(Map<String,Object?> fields)=>fields.length==1&&fields['originalCapture'] is String?null:'Keep capture';
  @override Future<MoolAssistantNativeSnapshot?> snapshot(MoolAssistantContext c,String? entity)async=>
    entity!=null?null:MoolAssistantNativeSnapshot(binding:c.binding,sourceRevision:'private-original',permitted:true,
      originalRequestCapture:capture);
  @override Future<MoolAssistantNativeBatchSnapshot> snapshots(MoolAssistantContext c,List<String?> entities)async{
    final captured=capture,native=await snapshot(c,null);var retired=false;
    return MoolAssistantNativeBatchSnapshot(owner:this,sourceRevision:'private-original',entries:{null:native},current:(){
      if(!lieAboutCurrent&&capture!=captured)retired=true;return !retired;
    });
  }
  @override Future<MoolAssistantReviewResult> openReview(MoolAssistantProposal p,bool Function() current)async{
    if(!current()||p.fields['originalCapture']!=capture||p.sourceRevision!='private-original')return MoolAssistantReviewResult.stale;
    opens++;reviewed=p;return MoolAssistantReviewResult.opened;
  }
}
class _ProductIdentityNative extends _SearchNative implements MoolAssistantCanonicalProductIdentityAdapter {
  @override String get actionId => 'AI-ACT-214';
  String? identity = 'native-product-alias';
  bool failIdentity = false;
  final identityStarted = Completer<void>();
  Completer<void>? identityWait;
  @override Set<String> get allowedFields => {'sourceCanonicalId', 'price', 'quantity'};
  @override String? validateFields(Map<String, Object?> fields) =>
    fields.length == 3 && fields.keys.every(allowedFields.contains) && fields.values.every((v) => v is String)
      ? null : 'Use original product fields.';
  @override Future<String?> nativeProductIdentity(MoolAssistantProposal proposal, bool Function() current) async {
    if (!identityStarted.isCompleted) identityStarted.complete();
    await identityWait?.future;
    if (failIdentity) throw StateError('Original acknowledgement unavailable');
    return current() ? identity : null;
  }
}
class _OptionalRootProductNative extends _ProductIdentityNative {
  @override String get actionId=>'AI-ACT-223';
  @override String? validateFields(Map<String,Object?> fields)=>fields.isEmpty?null:super.validateFields(fields);
}
class _RegisteredRootProductNative extends _OptionalRootProductNative implements MoolAssistantNativeProductRootReviewAdapter {}
class _BatchProductNative extends _ProductIdentityNative implements MoolAssistantBatchNativeAdapter {
  final batchOwner = Object(), batchStarted = Completer<void>();
  Completer<void>? batchWait;
  int batches = 0, singles = 0;
  String mode = 'ready';
  @override Future<MoolAssistantNativeSnapshot?> snapshot(MoolAssistantContext c, String? entity) {
    singles++; return super.snapshot(c, entity);
  }
  @override Future<MoolAssistantNativeBatchSnapshot> snapshots(MoolAssistantContext c, List<String?> entities) async {
    batches++; final captured = version;
    if (!batchStarted.isCompleted) batchStarted.complete(); await batchWait?.future;
    final entries = <String?, MoolAssistantNativeSnapshot?>{
      if (mode != 'missing') for (final entity in entities) entity: mode == 'not-ready' ? null : MoolAssistantNativeSnapshot(
        binding: mode == 'foreign' ? const MoolAssistantContext(accountScope: 'foreign', authenticationRevision: 1).binding : c.binding,
        entityId: entity, sourceRevision: 'original-search:$captured', permitted: true),
    };
    if (mode == 'extra') entries['foreign-product'] = null;
    return MoolAssistantNativeBatchSnapshot(owner: batchOwner, sourceRevision: 'host-batch:$captured', entries: entries, current: () => version == captured);
  }
}
class _ProductIdentityFixture {
  _ProductIdentityFixture({_ProductIdentityNative? adapter}) : native = adapter ?? _ProductIdentityNative();
  final owner = ValueNotifier(const MoolAssistantContext(accountScope: 'host-owner', authenticationRevision: 1));
  final _ProductIdentityNative native;
  final now = DateTime.utc(2026, 10, 28, 8);
  String revision = 'store-owned-product:production:7:${List.filled(64, 'a').join()}';
  AssistantCanonicalNativeSelection? selection;
  late final guard = AssistantProfileContextGuard(readContext: () => owner.value, ownerChanges: owner,
    nativeAdapters: [native], clock: () => now, canonicalActions: {'AI-ACT-214'}, recoverableActions: {'AI-ACT-214'},
    readCanonical: (context, current) async => AssistantCanonicalContextSnapshot(binding: context.binding,
      revisions: {('AI-ACT-214', 'sku-one'): revision}, validUntil: now.add(const Duration(minutes: 1)), nativeSelection: selection));
  MoolAssistantNativeAdapter get adapter => guard.adapters.single;
  Future<void> capture() => guard.capture(owner.value, () => true);
  MoolAssistantProposal proposal() => MoolAssistantProposal(id: 'host-product-proposal', actionId: native.actionId,
    binding: owner.value.binding, entityId: 'sku-one', requestRevision: 1, entitlementRevision: 'host-paid',
    validUntil: now.add(const Duration(minutes: 1)), sourceRevision: revision, title: 'Review product', summary: 'Host only',
    fields: {'sourceCanonicalId': 'original-catalogue-product', 'price': '0012.50', 'quantity': '0003'});
  void dispose() {guard.dispose(); owner.dispose();}
}
class _Fixture {
  _Fixture({bool register = true}) {
    guard = AssistantProfileContextGuard(readContext: () => owner.value, ownerChanges: owner,
      nativeAdapters: [native], clock: () => now,
      canonicalActions: register ? {'AI-ACT-001'} : null,
      recoverableActions: register ? {'AI-ACT-001'} : null,
      readCanonical: (context, current) async {
        await pending?.future;
        if (!current()) throw const AssistantModelFailure('stale_preparation');
        onRead?.call(++reads);
        return AssistantCanonicalContextSnapshot(binding: context.binding,
          revisions: {('AI-ACT-001', null): revision}, validUntil: now.add(const Duration(seconds: 60)),
          catalogueListingIds: listingIds);
      });
  }
  final owner = ValueNotifier(const MoolAssistantContext(accountScope: 'host-owner', authenticationRevision: 1));
  final native = _SearchNative();
  final now = DateTime.utc(2026, 10, 28, 8);
  String revision = 'catalogue-search:one';
  List<String>? listingIds;
  int reads = 0;
  void Function(int)? onRead;
  Completer<void>? pending;
  late final AssistantProfileContextGuard guard;
  MoolAssistantNativeAdapter get adapter => guard.adapters.single;
  Future<void> capture() => guard.capture(owner.value, () => true);
  MoolAssistantProposal proposal({bool recovered = false, String? originalRevision, Map<String, Object?>? fields}) =>
    MoolAssistantProposal(id: 'host-search-proposal', actionId: native.actionId, binding: owner.value.binding,
      requestRevision: 1, entitlementRevision: 'host-paid-revision', validUntil: now.add(const Duration(seconds: 60)),
      sourceRevision: originalRevision ?? revision, title: 'Review product search', summary: 'Host fixture only',
      fields: fields ?? {'query': 'चावल 5 kg'}, recovered: recovered,
      preparationRequestId: recovered ? 'original-host-preparation' : null,
      preparationSourceRevision: recovered ? originalRevision ?? revision : null);
  void dispose() {guard.dispose(); owner.dispose();}
}
void main() {
  for(final mode in ['ordinary-empty','registered-empty','registered-fields','registered-fixed']) {
    test('Store product root identity exception $mode remains explicitly registered and empty',()async{
      final native=mode=='ordinary-empty'?_OptionalRootProductNative():_RegisteredRootProductNative();
      final owner=ValueNotifier(const MoolAssistantContext(accountScope:'host-root-owner',authenticationRevision:1));
      final now=DateTime.utc(2026,10,28,8),entity=mode=='registered-fixed'?'sku-one':null;
      const proof='host-root-authority';
      final guard=AssistantProfileContextGuard(readContext:()=>owner.value,ownerChanges:owner,nativeAdapters:[native],
        canonicalActions:{'AI-ACT-223'},recoverableActions:{'AI-ACT-223'},clock:()=>now,
        readCanonical:(context,current)async=>AssistantCanonicalContextSnapshot(binding:context.binding,
          revisions:{('AI-ACT-223',entity):proof},validUntil:now.add(const Duration(minutes:1))));
      try{
        await guard.capture(owner.value,()=>true);
        final fields=<String,Object?>{if(mode=='registered-fields'||entity!=null)...{
          'sourceCanonicalId':'catalogue-id','price':'001.50','quantity':'0001'}};
        final proposal=MoolAssistantProposal(id:'host-root-review',actionId:'AI-ACT-223',binding:owner.value.binding,
          entityId:entity,requestRevision:1,entitlementRevision:'host-paid',validUntil:now.add(const Duration(minutes:1)),
          sourceRevision:proof,title:'Host review',summary:'Host only',fields:fields);
        final result=await guard.adapters.single.openReview(proposal,()=>true);
        final allowed=mode=='registered-empty'||mode=='registered-fixed';
        expect(result,allowed?MoolAssistantReviewResult.opened:MoolAssistantReviewResult.unavailable);
        expect(native.opens,allowed?1:0);
        if(mode=='registered-empty')expect(native.identityStarted.isCompleted,isFalse);
        if(mode=='registered-fixed'){
          expect(native.identityStarted.isCompleted,isTrue);
          expect(native.reviewed!.fields,{'sourceCanonicalId':'native-product-alias','price':'001.50','quantity':'0001'});
          expect(proposal.fields['sourceCanonicalId'],'catalogue-id');
        }
      }finally{guard.dispose();owner.dispose();}
    });
  }
  for(final mode in ['inflight','restart','snapshot-mismatch']) {
    test('Frozen original capture $mode cannot rebind a retained proposal to changed payload',()async{
      const account=(environment:'isolated-host',projectId:'fixture-project',tenantId:null,userId:'host-owner');
      final context=MoolAssistantContext(accountScope:account,authenticationRevision:1).withWorkspace(
        const MoolAssistantWorkspace(id:'host-store',name:'Host',profile:'retailer-grocery',revision:1,
          isStore:true,approved:true,approvalAccountScope:account));
      final owner=ValueNotifier(context),native=_OriginalCaptureNative(),now=DateTime.utc(2026,10,28,8);
      const proof='host-original-owner';
      AssistantProfileContextGuard fresh()=>AssistantProfileContextGuard(readContext:()=>owner.value,ownerChanges:owner,
        nativeAdapters:[native],canonicalActions:{native.actionId},recoverableActions:{native.actionId},clock:()=>now,
        readCanonical:(c,current)async=>AssistantCanonicalContextSnapshot(binding:c.binding,
          revisions:{(native.actionId,null):proof},validUntil:now.add(const Duration(minutes:1))));
      var guard=fresh();
      try {
        await guard.capture(context,()=>true);
        final fields={'originalCapture':guard.nativeOriginalCaptures!.single.digest};
        final proposal=MoolAssistantProposal(id:'host-original-proposal',actionId:native.actionId,binding:context.binding,
          requestRevision:1,entitlementRevision:'host-paid',sourceRevision:proof,validUntil:now.add(const Duration(minutes:1)),
          title:'Review original',summary:'Host only',fields:fields,recovered:true,preparationRequestId:'host-model-original',preparationSourceRevision:proof);
        if(mode=='restart') {
          guard.dispose();guard=fresh();await guard.captureRecoveredReview(context,proposal,()=>true);
          expect(await guard.adapters.single.openReview(proposal,()=>true),MoolAssistantReviewResult.opened);
          expect(native.opens,1);
          guard.dispose();guard=fresh();native.capture='b'*64;
          await expectLater(guard.captureRecoveredReview(context,proposal,()=>true),throwsA(isA<AssistantModelFailure>()));
          expect(native.opens,1);
        }else{
          native.lieAboutCurrent=mode=='snapshot-mismatch';native.capture='b'*64;
          if(mode=='inflight') {
            expect(guard.current,isFalse);native.capture='a'*64;expect(guard.current,isFalse);
          }
          expect(await guard.adapters.single.openReview(proposal,()=>true),MoolAssistantReviewResult.stale);
          expect(native.opens,0);
        }
        expect(proposal.fields,fields);
      }finally{guard.dispose();owner.dispose();}
    });
  }
  test('Native batch capture remains read-only and final original single snapshots still protect Review', () async {
    final native = _BatchProductNative();
    final f = _ProductIdentityFixture(adapter: native); addTearDown(f.dispose);
    await f.capture(); expect(native.batches, 1); expect(native.singles, 0);
    expect(await f.adapter.openReview(f.proposal(), () => true), MoolAssistantReviewResult.opened);
    expect(native.singles, 2); expect(native.opens, 1);
  });
  test('Incomplete or foreign native batch entries cannot become readiness claims', () async {
    for (final mode in ['missing', 'extra', 'foreign']) {
      final native = _BatchProductNative()..mode = mode;
      final f = _ProductIdentityFixture(adapter: native); addTearDown(f.dispose);
      await expectLater(f.capture(), throwsA(isA<AssistantModelFailure>())); expect(native.opens, 0);
    }
    final native = _BatchProductNative()..mode = 'not-ready';
    final f = _ProductIdentityFixture(adapter: native); addTearDown(f.dispose); await f.capture();
    expect(f.guard.nativeTargets, isEmpty);
  });
  test('Native mutation across batch await retires capture before any review', () async {
    final native = _BatchProductNative()..batchWait = Completer<void>();
    final f = _ProductIdentityFixture(adapter: native); addTearDown(f.dispose);
    final capture = f.capture(); await native.batchStarted.future; native.version++; native.batchWait!.complete();
    await expectLater(capture, throwsA(isA<AssistantModelFailure>())); expect(native.opens, 0); expect(f.guard.current, false);
  });
  test('Compact readiness pairs immutable Store selection proofs and retires with the actor', () async {
    final f = _ProductIdentityFixture(); addTearDown(f.dispose);
    f.owner.value = f.owner.value.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'Host Store',
      profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: 'host-owner'));
    f.selection = AssistantCanonicalNativeSelection(fingerprint: 'a' * 64, proofs: {('AI-ACT-214', 'sku-one'): f.revision});
    await f.capture(); expect(f.guard.nativeTargets, isEmpty); expect(f.guard.nativeMaskedActionIds, {'AI-ACT-214'});
    expect(f.guard.nativeTargetMask!.bits, 'AQ');
    f.owner.value = const MoolAssistantContext(accountScope: 'other-owner', authenticationRevision: 2);
    expect(f.guard.nativeTargetMask, isNull); expect(f.guard.nativeMaskedActionIds, isEmpty);
  });
  test('Original product identity bridge changes only the native reference and preserves canonical recovery data', () async {
    final f = _ProductIdentityFixture(); addTearDown(f.dispose); await f.capture();
    final proposal = f.proposal(); final original = Map<String, Object?>.of(proposal.fields);
    expect(await f.adapter.openReview(proposal, () => true), MoolAssistantReviewResult.opened);
    expect(f.native.opens, 1);
    expect(f.native.reviewed!.fields, {...original, 'sourceCanonicalId': 'native-product-alias'});
    expect(f.native.reviewed!.sourceRevision, 'original-search:1');
    expect(f.native.reviewed!.entityId, 'sku-one');
    expect(proposal.fields, original); expect(proposal.sourceRevision, f.revision);
  });
  test('Missing or failed original product acknowledgement never opens a native form', () async {
    for (final failure in [false, true]) {
      final f = _ProductIdentityFixture(); addTearDown(f.dispose); await f.capture();
      f.native.identity = null; f.native.failIdentity = failure;
      expect(await f.adapter.openReview(f.proposal(), () => true),
        failure ? MoolAssistantReviewResult.unavailable : MoolAssistantReviewResult.stale);
      expect(f.native.opens, 0);
    }
  });
  test('Identity await revalidates original source, native revision, actor and caller cancellation', () async {
    for (final change in ['source', 'native', 'actor', 'cancel']) {
      final f = _ProductIdentityFixture(); addTearDown(f.dispose); await f.capture();
      var current = true; f.native.identityWait = Completer<void>();
      final pending = f.adapter.openReview(f.proposal(), () => current);
      await f.native.identityStarted.future;
      switch (change) {
        case 'source': f.revision = '${f.revision}-changed';
        case 'native': f.native.version++;
        case 'actor': f.owner.value = const MoolAssistantContext(accountScope: 'other-owner', authenticationRevision: 2);
        case 'cancel': current = false;
      }
      f.native.identityWait!.complete();
      expect(await pending, MoolAssistantReviewResult.stale, reason: change);
      expect(f.native.opens, 0, reason: change);
    }
  });
  test('Native readiness hints expose only admitted permitted captured anchors and retire with their owner', () async {
    final f = _Fixture(); addTearDown(f.dispose); await f.capture();
    expect(f.guard.nativeTargets, [(actionId: 'AI-ACT-001', entityId: null)]);
    expect(() => f.guard.nativeTargets!.clear(), throwsUnsupportedError);
    f.guard.retire(); expect(f.guard.nativeTargets, isNull);
    final denied = _Fixture()..native.permitted = false; addTearDown(denied.dispose); await denied.capture();
    expect(denied.guard.nativeTargets, isEmpty);
    final unregistered = _Fixture(register: false); addTearDown(unregistered.dispose); await unregistered.capture();
    expect(unregistered.guard.nativeTargets, isEmpty);
  });
  test('Original listing selection is captured immutably and retired with its owner', () async {
    final f = _Fixture(); addTearDown(f.dispose);
    final id = 'listing-${List.filled(64, 'a').join()}';
    f.listingIds = [id]; await f.capture(); f.listingIds!.clear();
    expect(f.guard.catalogueListingIds, [id]);
    f.guard.retire(); expect(f.guard.catalogueListingIds, isNull);
  });
  test('Changed listing selection during capture rejects even an unchanged source revision', () async {
    final f = _Fixture(); addTearDown(f.dispose);
    f.listingIds = ['listing-${List.filled(64, 'a').join()}'];
    f.onRead = (n) {if (n == 2) f.listingIds = ['listing-${List.filled(64, 'b').join()}'];};
    await expectLater(f.capture(), throwsA(isA<AssistantModelFailure>()));
    expect(f.guard.current, false); expect(f.native.opens, 0);
  });
  test('Domain canonical guard reviews exact original native source and supplied query', () async {
    final f = _Fixture(); addTearDown(f.dispose); await f.capture();
    expect((await f.adapter.snapshot(f.owner.value, null))!.sourceRevision, f.revision);
    expect(await f.adapter.openReview(f.proposal(), () => true), MoolAssistantReviewResult.opened);
    expect(f.native.opens, 1); expect(f.native.reviewed!.sourceRevision, 'original-search:1');
    expect(f.native.reviewed!.fields, {'query': 'चावल 5 kg'});
  });
  test('Domain stale server revision cannot be relabelled with a fresh native token', () async {
    final f = _Fixture(); addTearDown(f.dispose); await f.capture(); final original = f.proposal();
    f.revision = 'catalogue-search:two';
    expect(await f.adapter.openReview(original, () => true), MoolAssistantReviewResult.stale); expect(f.native.opens, 0);
  });
  test('Domain original native edit or withdrawn permission retires review', () async {
    for (final withdraw in [false, true]) {
      final f = _Fixture(); addTearDown(f.dispose); await f.capture(); final p = f.proposal();
      if (withdraw) {f.native.permitted = false;} else {f.native.version++;}
      expect(await f.adapter.openReview(p, () => true), MoolAssistantReviewResult.stale); expect(f.native.opens, 0);
    }
  });
  test('Domain unknown native fields cannot open the original form', () async {
    final f = _Fixture(); addTearDown(f.dispose); await f.capture();
    expect(await f.adapter.openReview(f.proposal(fields: {'query': 'rice', 'admin': true}), () => true), MoolAssistantReviewResult.unavailable);
    expect(f.native.opens, 0);
  });
  test('Domain account switch across canonical read retires all old anchors', () async {
    final f = _Fixture(); addTearDown(f.dispose); f.pending = Completer<void>(); final capture = f.capture();
    f.owner.value = const MoolAssistantContext(accountScope: 'other-owner', authenticationRevision: 2); f.pending!.complete();
    await expectLater(capture, throwsA(anything)); expect(f.guard.current, false); expect(f.native.opens, 0);
  });
  test('Domain explicitly recovered preparation requires the same fresh original source revision', () async {
    final f = _Fixture(); addTearDown(f.dispose);
    final p = f.proposal(recovered: true); await f.guard.captureRecoveredReview(f.owner.value, p, () => true);
    expect(await f.adapter.openReview(p, () => true), MoolAssistantReviewResult.opened);
    f.revision = 'catalogue-search:two';
    await expectLater(f.guard.captureRecoveredReview(f.owner.value, p, () => true), throwsA(anything));
    expect(f.native.opens, 1);
  });
  test('Domain registration does not broaden the original default Profile recovery set', () async {
    final f = _Fixture(register: false); addTearDown(f.dispose);
    await expectLater(f.guard.captureRecoveredReview(f.owner.value, f.proposal(recovered: true), () => true), throwsA(anything));
    expect(f.native.opens, 0);
  });
}
