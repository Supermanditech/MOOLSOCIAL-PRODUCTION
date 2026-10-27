import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/assistant/model_gateway.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/assistant/profile_context.dart';
import 'package:moolsocial/features/assistant/preparation_pending_store.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'assistant_model_gateway_test.dart' show modelOwner, modelInput, modelAt, ModelCredentials, ModelTransport, modelResponse;
import 'assistant_model_flow_test.dart' show ModelEntitlements;

/// Explicit host storage/network seams. Nothing is injected into an OPPO app.
class _Journal implements AssistantPreparationPendingStore {
  final values=<String,String>{};
  bool failWrite=false;
  Completer<void>? clearEntered, releaseClear;
  @override Future<String?> read(String key) async=>values[key];
  @override Future<void> write(String key,String value) async {if(failWrite)throw StateError('Host storage unavailable');values[key]=value;}
  @override Future<void> clear(String key)async{clearEntered?.complete();await releaseClear?.future;values.remove(key);}
}
AssistantModelGateway _source(_Journal journal,ModelTransport transport) => AssistantModelGateway(
  owner:modelOwner,isCurrent:()=>true,credentials:ModelCredentials(),transport:transport,pendingStore:journal,clock:()=>modelAt);
const _profileInput=AssistantModelInput(scope:(audience:'personal',storeId:null),requestId:'original-profile-request',requestRevision:7,
  message:'Private original host-only request',language:'English',expectedEntitlementRevision:'personal:null:1:1',actionId:'AI-ACT-197');
Map<String,Object?> _profileReply()=>{
  'state':'ready','reply':{'scope':{'audience':'personal','storeId':null},'requestId':_profileInput.requestId,'requestRevision':7,
    'entitlementRevision':'personal:null:1:1','checkedAt':modelAt.toIso8601String(),'validUntil':modelAt.add(const Duration(minutes:1)).toIso8601String(),
    'outcome':{'kind':'proposal','id':'recovered-profile-proposal','actionId':'AI-ACT-197','entityId':null,'sourceRevision':'profile:0',
      'title':'Review display name','summary':'Host fixture','fields':{'displayName':'Prepared name'}}}};
class _Native implements MoolAssistantNativeAdapter {
  bool editing=false;
  int opened=0;
  @override String get actionId=>'AI-ACT-197';
  @override Set<String> get allowedFields=>{'displayName'};
  @override String? validateFields(Map<String,Object?> fields)=>fields['displayName'] is String?null:'Invalid';
  @override Future<MoolAssistantNativeSnapshot?> snapshot(MoolAssistantContext context,String? entityId)async=>editing?null:
    MoolAssistantNativeSnapshot(binding:context.binding,sourceRevision:'pristine-original-form',permitted:true);
  @override Future<MoolAssistantReviewResult> openReview(MoolAssistantProposal proposal,bool Function() current)async{
    if(!current()||editing||proposal.sourceRevision!='pristine-original-form')return MoolAssistantReviewResult.stale;
    opened++;return MoolAssistantReviewResult.opened;
  }
}
void main(){
 test('B07 journal persists only owner-bound identity/hash before sending and restores status after gateway recreation',()async{
  final journal=_Journal(),wire=ModelTransport((_)=>modelResponse({'state':'pending'}));
  final first=_source(journal,wire);
  await first.prepare(_profileInput,()=>true);first.dispose();
  expect(journal.values.length,1);expect(journal.values.values.single, isNot(contains(_profileInput.message)));
  expect(journal.values.values.single,isNot(contains('fixture-token')));expect(journal.values.values.single,isNot(contains('history')));
  final secondWire=ModelTransport((b){expect(b['operation'],'status');return modelResponse(_profileReply());});
  final second=_source(journal,secondWire),pending=await _source(journal,secondWire).pending(_profileInput.scope,()=>true);
  expect(pending!.requestId,_profileInput.requestId);expect(pending.message,'Recovered request');
  expect((await second.status(pending,()=>true)).state,'ready');expect(secondWire.calls.length,1);expect(journal.values.length,1);
  await second.acknowledge(pending);expect(journal.values,isEmpty);second.dispose();
 });
 test('B07 failed local journal blocks all preparation traffic',()async{
  final journal=_Journal()..failWrite=true,wire=ModelTransport((_)=>throw StateError('No network allowed'));
  final source=_source(journal,wire);addTearDown(source.dispose);
  await expectLater(source.prepare(modelInput,()=>true),throwsA(anything));expect(wire.calls,isEmpty);
 });
 test('B07 a new identity cannot overwrite an unresolved original preparation',()async{
  final journal=_Journal(),wire=ModelTransport((_)=>modelResponse({'state':'pending'})),source=_source(journal,wire);
  addTearDown(source.dispose);await source.prepare(modelInput,()=>true);
  await expectLater(source.prepare(_profileInput,()=>true),throwsA(isA<AssistantModelFailure>().having((e)=>e.code,'code','original_request_pending')));
  expect(wire.calls.length,1);expect((await source.pending(modelInput.scope,()=>true))!.requestId,modelInput.requestId);
 });
 test('B07 pending metadata stays isolated by account and Store and cannot grant permissions',()async{
  final journal=_Journal(),wire=ModelTransport((_)=>modelResponse({'state':'pending'})),source=_source(journal,wire);
  addTearDown(source.dispose);await source.prepare(modelInput,()=>true);
  expect(await source.pending((audience:'workspace',storeId:'other-store'),()=>true),isNull);
  final foreign=AssistantModelGateway(owner:(environment:modelOwner.environment,projectId:modelOwner.projectId,tenantId:null,userId:'another-owner'),isCurrent:()=>true,credentials:ModelCredentials(),transport:wire,pendingStore:journal,clock:()=>modelAt);
  expect(await foreign.pending(modelInput.scope,()=>true),isNull);foreign.dispose();
  expect(wire.calls.length,1);
 });
 test('B07 late original acknowledgement cannot erase a newer request across gateway instances',()async{
  final journal=_Journal(),wire=ModelTransport((_)=>modelResponse({'state':'pending'}));
  final first=_source(journal,wire),second=_source(journal,wire);
  addTearDown(first.dispose);addTearDown(second.dispose);
  await first.prepare(modelInput,()=>true);
  journal.clearEntered=Completer<void>();journal.releaseClear=Completer<void>();
  final clearing=first.acknowledge(modelInput);await journal.clearEntered!.future;
  final preparing=second.prepare(_profileInput,()=>true);
  expect(wire.calls.length,1);journal.releaseClear!.complete();await clearing;
  journal.clearEntered=null;journal.releaseClear=null;await preparing;
  await first.acknowledge(modelInput);
  expect((await second.pending(_profileInput.scope,()=>true))!.requestId,_profileInput.requestId);
  expect(wire.calls.length,2);
 });
 test('B07 authoritative missing original status clears only its pending slot',()async{
  final journal=_Journal(),source=_source(journal,ModelTransport((_)=>modelResponse({'state':'pending'})));
  await source.prepare(modelInput,()=>true);source.dispose();
  final next=_source(journal,ModelTransport((_)=>SocialContentResponse(statusCode:404,body:jsonEncode({'ok':false,'error':{'code':'request_not_found'}}))));
  await expectLater(next.status(modelInput,()=>true),throwsA(isA<AssistantModelFailure>()));expect(journal.values,isEmpty);next.dispose();
 });
 for(final scenario in [(editing:false,changed:false),(editing:true,changed:false),(editing:false,changed:true)]){
  final editing=scenario.editing,changed=scenario.changed;
  test('B07 recovered Profile result requires explicit fresh Review; existing editor=$editing changed source=$changed',()async{
   final journal=_Journal(),first=_source(journal,ModelTransport((_)=>modelResponse({'state':'pending'})));
   await first.prepare(_profileInput,()=>true);first.dispose();
   final wire=ModelTransport((b)=>modelResponse(b['operation']=='cancel'?{'state':'cancelled'}:_profileReply())),source=_source(journal,wire);
   final context=ValueNotifier(const MoolAssistantContext(accountScope:modelOwner,authenticationRevision:1)),paid=ModelEntitlements(),native=_Native()..editing=editing;
   final guard=AssistantProfileContextGuard(readContext:()=>context.value,ownerChanges:context,nativeAdapters:[native],clock:()=>modelAt,
    readCanonical:(c,current)async=>AssistantCanonicalContextSnapshot(binding:c.binding,revisions:{('AI-ACT-197',null):changed?'profile:1':'profile:0'},validUntil:modelAt.add(const Duration(minutes:1))));
   final c=MoolAssistantController(currentContext:()=>context.value,contextChanges:context,entitlements:paid,readModelSource:()=>source,nativeAdapters:guard.adapters,preparationGuard:guard,clock:()=>modelAt);
   try{
    await c.refreshAccess();expect(c.canSend,true);expect(guard.current,false);expect(native.opened,0);
    expect(await c.sendRequest(),true);expect(wire.calls.single['operation'],'status');expect(c.proposal!.recovered,true);
    expect(c.proposal!.requestRevision,c.requestRevision);expect(c.proposal!.preparationRequestId,_profileInput.requestId);expect(guard.current,false);
    final result=await c.reviewProposal();
    expect(native.opened,editing||changed?0:1);expect(result,editing||changed?MoolAssistantReviewResult.unavailable:MoolAssistantReviewResult.opened);
    if(changed){expect(guard.current,false);expect(c.proposalNotice,isNotNull);}
   }finally{c.dispose();guard.dispose();paid.dispose();context.dispose();source.dispose();}
  });
 }
}
