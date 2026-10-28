import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:moolsocial/features/assistant/domain_context_gateway.dart';
import 'package:moolsocial/features/journey01/account_plans_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/assistant/model_gateway.dart';
import 'package:moolsocial/features/assistant/profile_context.dart';
import 'package:moolsocial/features/assistant/preparation_pending_store.dart';
import 'package:moolsocial/features/journey01/account_profile_gateway.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/ui_v2/assistant/profile_context_adapter.dart';
import 'account_profile_gateway_test.dart' show Rig, profile, receipt, receiptFor, ProfileIdentity, sessionFixture, CustomerStore, Credentials, Journal;


const _localContextPort = int.fromEnvironment('THIN_B07_LOCAL_PORT',defaultValue:int.fromEnvironment('THIN_B03_LOCAL_PORT'));
const _clientPhase=String.fromEnvironment('THIN_B07_CLIENT_PHASE');
const _clientStorage=String.fromEnvironment('THIN_B07_CLIENT_STORAGE');
// Isolated metadata transport; never supplies authority or records to a phone.
class _AddressChoiceMetadata implements SocialContentTransport {
  _AddressChoiceMetadata(this.owner);
  final AccountProfileOwner owner;int reads=0;
  @override Future<SocialContentResponse> postJson(Uri endpoint,{required Map<String,String> headers,required Map<String,Object?> body})async{
    reads++;
    return SocialContentResponse(statusCode:200,body:jsonEncode({'ok':true,'data':{
      'ownerKey':crypto.sha256.convert(utf8.encode(jsonEncode([owner.projectId,owner.userId,'personal',null]))).toString(),
      'scope':{'audience':'personal','storeId':null},'validUntil':DateTime.now().toUtc().add(const Duration(minutes:1)).toIso8601String(),
      'revisions':[for(final action in assistantDomainAddressContextActions){'actionId':action,'entityId':'address-one','sourceRevision':'profile:1'}]}}));
  }
}
class _AddressChoiceIdentity extends ProfileIdentity implements AssistantDomainContextGatewaySource {
  _AddressChoiceIdentity(super.rig);
  _AddressChoiceMetadata? metadata;
  @override AssistantDomainContextGateway assistantDomainContextGateway(AccountProfileOwner owner,bool Function() current){
    metadata=_AddressChoiceMetadata(owner);
    return AssistantDomainContextGateway(owner:owner,isCurrent:current,credentials:Credentials(),transport:metadata!);
  }
}
// External host-only storage seams for independently launched client processes.
class _DiskProfileJournal extends Journal {
 _DiskProfileJournal(this.file){if(file.existsSync())values.addAll(Map<String,String>.from(jsonDecode(file.readAsStringSync()) as Map));}
 final File file;
 void persist(){file.parent.createSync(recursive:true);file.writeAsStringSync(jsonEncode(values),flush:true);}
 @override Future<void> write(String key,String value)async{await super.write(key,value);persist();}
 @override Future<void> clear(String key)async{await super.clear(key);persist();}
}
class _DurableRig extends Rig {
 _DurableRig():journal=_DiskProfileJournal(File('$_clientStorage/profile-pending.json'));
 @override final Journal journal;
}
class _DiskAssistantJournal implements AssistantPreparationPendingStore {
 _DiskAssistantJournal():file=File('$_clientStorage/assistant-pending.json'){if(file.existsSync())values.addAll(Map<String,String>.from(jsonDecode(file.readAsStringSync()) as Map));}
 final File file;final values=<String,String>{};
 void persist(){file.parent.createSync(recursive:true);file.writeAsStringSync(jsonEncode(values),flush:true);}
 @override Future<String?> read(String key)async=>values[key];
 @override Future<void> write(String key,String value)async{values[key]=value;persist();}
 @override Future<void> clear(String key)async{values.remove(key);persist();}
}
class _LocalHttp extends HttpOverrides {}
class _LocalTransport implements SocialContentTransport {
  _LocalTransport({Duration timeout=const Duration(seconds:10)}) : inner = IoSocialContentTransport(client: HttpOverrides.runWithHttpOverrides(() => HttpClient(), _LocalHttp()), followRedirects: false, timeout: timeout, maximumResponseBytes: 1024 * 1024);
  final IoSocialContentTransport inner;
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String,String> headers, required Map<String,Object?> body}) => inner.postJson(Uri.http('127.0.0.1:$_localContextPort', endpoint.path), headers: headers, body: body);
}
Future<Map<String,dynamic>> _control(Map<String,String> query) async {
 final client=HttpOverrides.runWithHttpOverrides(() => HttpClient(), _LocalHttp());
 try {final response=await (await client.getUrl(Uri.http('127.0.0.1:$_localContextPort','/__fixture__',query))).close();
 expect(response.statusCode,200);return jsonDecode(await response.transform(utf8.decoder).join()) as Map<String,dynamic>;
 } finally {client.close(force:true);}
}
class _LocalIdentity extends ProfileIdentity {
 _LocalIdentity(super.rig, this.wire);
 final _LocalTransport wire;
 @override AccountProfileGateway? profileGateway(AccountProfileOwner owner, bool Function() current) => AccountProfileGateway(owner:owner,isCurrent:current,credentials:rig.credentials,pendingStore:rig.journal,transport:wire);
}
class _PushObserver extends NavigatorObserver {
 Completer<void>? pushed;
 @override void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {super.didPush(route,previousRoute);pushed?.complete();pushed=null;}
}

class _Native implements MoolAssistantNativeAdapter {
  @override final String actionId = 'AI-ACT-197';
  int version = 1, opened = 0;
  MoolAssistantProposal? reviewed;
  @override Set<String> get allowedFields => {'displayName'};
  @override String? validateFields(Map<String, Object?> fields) =>
      fields.length == 1 && fields['displayName'] is String ? null : 'Invalid name';
  @override Future<MoolAssistantNativeSnapshot?> snapshot(MoolAssistantContext context, String? entityId) async =>
      MoolAssistantNativeSnapshot(binding: context.binding,
        sourceRevision: 'original-local:$version', permitted: true, entityId: entityId);
  @override Future<MoolAssistantReviewResult> openReview(MoolAssistantProposal proposal, bool Function() current) async {
    if (!current() || proposal.sourceRevision != 'original-local:$version') return MoolAssistantReviewResult.stale;
    opened++; reviewed = proposal; return MoolAssistantReviewResult.opened;
  }
}
class _GuardFixture {
  final owner = ValueNotifier(const MoolAssistantContext(accountScope: 'host-owner-a', authenticationRevision: 1));
  final original = _Native();
  DateTime now = DateTime.utc(2026, 10, 27, 8);
  String revision = 'profile:3';
  Completer<void>? delay;
  late final guard = AssistantProfileContextGuard(readContext: () => owner.value, ownerChanges: owner,
    nativeAdapters: [original], clock: () => now, readCanonical: (context, current) async {
      await delay?.future;
      if (!current()) throw const AssistantModelFailure('stale_preparation');
      return AssistantCanonicalContextSnapshot(binding: context.binding,
        revisions: {(original.actionId, null): revision}, validUntil: DateTime.utc(2026, 10, 27, 8, 1));
    });
  MoolAssistantNativeAdapter get adapter => guard.adapters.single;
  Future<void> capture() => guard.capture(owner.value, () => true);
  MoolAssistantProposal proposal() => MoolAssistantProposal(id: 'host-preparation', actionId: original.actionId,
    binding: owner.value.binding, requestRevision: 1, entitlementRevision: 'host-paid-revision',
    sourceRevision: revision, validUntil: now.add(const Duration(seconds: 60)),
    title: 'Review name', summary: 'Host fixture only', fields: {'displayName': 'मोहन'});
  void dispose() {guard.dispose(); owner.dispose();}
}

void main() {
  test('B07 independent client process recovers original Profile receipt after backend restart',()async{
    final wire=_LocalTransport(),rig=_DurableRig();
    final identity=_LocalIdentity(rig,wire);
    final current=sessionFixture(identity);await current.start();
    final pending=_DiskAssistantJournal(),owner=current.authenticatedBuyPersistenceIdentity!;
    final gateway=AssistantModelGateway(owner:owner,isCurrent:()=>true,credentials:Credentials(),transport:wire,pendingStore:pending);
    try{
      expect(rig.journal.values,isNotEmpty);expect(pending.values,isNotEmpty);
      expect(await current.refreshAccountProfile(),true);
      expect(current.accountProfileGateway!.snapshot!.displayName,'\u092e\u094b\u0939\u0928');expect(rig.journal.values,isEmpty);
      final original=await gateway.pending((audience:'personal',storeId:null),()=>true);expect(original,isNotNull);
      await expectLater(gateway.status(original!,()=>true),throwsA(isA<AssistantModelFailure>().having((e)=>e.code,'code','stale_preparation')));
      expect(pending.values,isEmpty);final stats=await _control({});expect(stats['modelCalls'],1);expect(stats['sqlWrites'],1);
      File('$_clientStorage/recovery-result.json').writeAsStringSync(jsonEncode({'clientPid':pid,'originalReceiptRecovered':true,'modelCalls':stats['modelCalls'],
        'profileWrites':stats['sqlWrites'],'profilePendingCleared':rig.journal.values.isEmpty,'assistantPendingCleared':pending.values.isEmpty,
        'realGoogle':false,'realModel':false}),flush:true);
    }finally{gateway.dispose();current.dispose();await identity.changes.close();wire.inner.close(force:true);}
  },skip:_clientPhase!='recover'||_localContextPort==0);

  test('B04 unchanged native name remains a no-effect Save without invented receipt',()async{
    final rig=Rig();
    final identity=ProfileIdentity(rig),session=sessionFixture(identity);await session.start();
    rig.transport.responses.add(profile());expect(await session.refreshAccountProfileForPreparation(),true);
    final count=rig.transport.calls.length;
    expect(await session.saveAccountProfileName('Original name',assistant:const AccountProfileAssistantConsent(preparationRequestId:'host-prep',proposalId:'host-proposal',actionId:'AI-ACT-197',entityId:null,sourceRevision:'profile:0',entitlementRevision:'host-paid')),true);
    expect(rig.transport.calls.length,count);expect(rig.journal.values,isEmpty);
    session.dispose();await identity.changes.close();
  });
  test('B04 AI address refresh cannot replay a pending original save',()async{
    final rig=Rig();await rig.read();rig.transport.responses.add(Exception('Host lost save response'));
    await expectLater(rig.gateway.save({'kind':'name','displayName':'Pending name'}),throwsA(isA<AccountProfileFailure>()));
    final before=Map<String,String>.of(rig.journal.values),calls=rig.transport.calls.length;
    final buy=BuyV2Session(core:BuySession(),reviewDataEnabled:false,customerStateStore:CustomerStore(rig.gateway.ownerScope));
    buy.synchronizeAccountProfile(rig.gateway);
    expect(await buy.refreshAccountProfileAddresses(preparationOnly:true),false);
    expect(rig.transport.calls.length,calls);expect(rig.journal.values,before);buy.dispose();
  });


  test('THIN-B03 loopback Profile timeout recovers one original preparation without second model spend',()async{
   await _control({'reset':'1','delay':'1'});
   final wire=_LocalTransport(),modelWire=_LocalTransport(timeout:const Duration(milliseconds:150)),rig=Rig();
   final identity=_LocalIdentity(rig,wire),session=sessionFixture(identity);await session.start();
   final context=ValueNotifier(MoolAssistantContext(accountScope:session.authenticatedBuyPersistenceIdentity,authenticationRevision:session.navigationAuthenticationGeneration));
   final work=WorkSession(gateway:ReviewWorkGateway());
   final reader=AssistantOriginalContextReader(session:session,work:work,rootCurrent:()=>true);
   final guard=AssistantProfileContextGuard(readCanonical:reader.read,readContext:()=>context.value,ownerChanges:context,nativeAdapters:[_Native()]);
   final owner=session.authenticatedBuyPersistenceIdentity!;
   final plans=AccountPlansGateway(owner:owner,isCurrent:()=>true,credentials:Credentials(),transport:wire);
   final paid=AccountPlansAssistantEntitlements(readGateway:()=>plans);
   final gateway=AssistantModelGateway(owner:owner,isCurrent:()=>true,credentials:Credentials(),transport:modelWire);
   final c=MoolAssistantController(currentContext:()=>context.value,contextChanges:context,entitlements:paid,nativeAdapters:guard.adapters,preparationGuard:guard,readModelSource:()=>gateway);
   try {await c.refreshAccess();c.chooseAction('AI-ACT-197');c.setDraft('Update my name');
    expect(await c.sendRequest(),false);expect(c.proposal,isNull);
    expect(await c.sendRequest(),true);expect(c.proposal?.sourceRevision,'profile:0');
    final stats=await _control({});expect(stats['modelCalls'],1);expect(stats['sqlWrites'],0);expect(rig.journal.values,isEmpty);
   }finally{c.dispose();guard.dispose();gateway.dispose();paid.dispose();plans.dispose();context.dispose();work.dispose();session.dispose();await identity.changes.close();wire.inner.close(force:true);modelWire.inner.close(force:true);}
  },skip:_localContextPort==0);


  for(final address in [false,true]) for (final changed in [false,true]) {
   testWidgets('THIN-B03 loopback original SQL source to native Profile; address=$address changed=$changed', (tester) async {
    tester.view.devicePixelRatio=1;tester.view.physicalSize=const Size(412,915);addTearDown(tester.view.reset);
    await tester.runAsync(() => _control({'reset':'1'}));
    final wire=_LocalTransport();final rig=_clientPhase=='prepare'?_DurableRig():Rig();final identity=_LocalIdentity(rig,wire),session=sessionFixture(identity);
    await session.start();
    final buy=BuyV2Session(core:BuySession(),reviewDataEnabled:false,customerStateStore:CustomerStore(session.accountProfileGateway!.ownerScope));
    buy.synchronizeAccountProfile(session.accountProfileGateway);
    if(address)await buy.restoreCustomerState();
    final work=WorkSession(gateway:ReviewWorkGateway()),navigator=GlobalKey<NavigatorState>(),observer=_PushObserver();
    await tester.pumpWidget(MaterialApp(navigatorKey:navigator,navigatorObservers:[observer],home:const Scaffold(body:Text('Original Profile owner'))));
    final changes=Listenable.merge([session,work,buy]);
    MoolAssistantContext context()=>MoolAssistantContext(accountScope:session.authenticatedBuyPersistenceIdentity,authenticationRevision:session.navigationAuthenticationGeneration);
    final native=assistantOriginalProfileAdapters(session:session,buy:buy,navigator:navigator.currentState!,currentContext:context,rootCurrent:()=>navigator.currentState?.mounted==true,routeIdentity:()=> 'host-original',nameEditorAlreadyOpen:()=>false,changes:changes,openPersonalPlans:()async{});
    final reader=AssistantOriginalContextReader(session:session,work:work,rootCurrent:()=>true);
    final guard=AssistantProfileContextGuard(readCanonical:reader.read,readContext:context,ownerChanges:changes,nativeAdapters:native);
    final owner=session.authenticatedBuyPersistenceIdentity!;
    final plans=AccountPlansGateway(owner:owner,isCurrent:()=>true,credentials:Credentials(),transport:wire);
    final paid=AccountPlansAssistantEntitlements(readGateway:()=>plans);
    final gateway=AssistantModelGateway(owner:owner,isCurrent:()=>true,credentials:Credentials(),transport:wire,pendingStore:_clientPhase=='prepare'?_DiskAssistantJournal():null);
    final controller=(await tester.runAsync(()async{final c=MoolAssistantController(currentContext:context,contextChanges:changes,entitlements:paid,nativeAdapters:guard.adapters,preparationGuard:guard,readModelSource:()=>gateway);await c.refreshAccess().timeout(const Duration(seconds:10));return c;}))!;
    try {
     expect(controller.paidAccessCurrent,true);expect(controller.chooseAction(address?'AI-ACT-025':'AI-ACT-197'),true);
     expect(await tester.runAsync(()=>controller.sendRequest().timeout(const Duration(seconds:10))),true);expect(controller.proposal?.sourceRevision,'profile:0');expect(controller.proposal?.actionId,address?'AI-ACT-025':'AI-ACT-197');
     if(changed){await tester.runAsync(()=>_control({'change':'1','reopen':'1'}));
      expect(await tester.runAsync(controller.reviewProposal),MoolAssistantReviewResult.stale);expect(controller.proposal,isNull);
      expect(find.byKey(const Key('global-personal-profile-name-field')),findsNothing);
     }else{
      final pushed=Completer<void>();observer.pushed=pushed;Future<MoolAssistantReviewResult>? review;MoolAssistantReviewResult? reviewState;
      await tester.runAsync(()async{review=controller.reviewProposal().then((value){reviewState=value;return value;});});
      final reviewField=Key(address?'buy-address-add-form-route':'global-personal-profile-name-field');
      for(var i=0;i<100;i++){await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:20)));await tester.pump(const Duration(milliseconds:30));if(find.byKey(reviewField).evaluate().isNotEmpty){if(address)break;final f=tester.widget<TextField>(find.byKey(reviewField));if(f.controller?.text=='\u092e\u094b\u0939\u0928')break;}}
      if(address && find.byKey(reviewField).evaluate().isEmpty){debugPrint(jsonEncode({'hostDiagnosticOnly':true,'routePushed':pushed.isCompleted,'review':reviewState?.name,'buyNotice':buy.notice,'cartBlocked':buy.cartChangesBlocked,'texts':tester.widgetList<Text>(find.byType(Text)).map((t)=>t.data).whereType<String>().take(15).toList()}));}
      expect(find.byKey(reviewField),findsOneWidget,reason:'Original review result: $reviewState; ${controller.proposalNotice}');
      if(address){await tester.scrollUntilVisible(find.byKey(const Key('buy-address-add-line')),180,scrollable:find.descendant(of:find.byKey(reviewField),matching:find.byType(Scrollable)).first);expect(tester.widget<TextField>(find.byKey(const Key('buy-address-add-line'))).controller!.text,'Host test road');}else{expect(tester.widget<TextField>(find.byKey(reviewField)).controller!.text,'\u092e\u094b\u0939\u0928');}
      final beforeSave=(await tester.runAsync(()=>_control({})))!;expect(beforeSave['sqlWrites'],0);
      final saveButton=Key(address?'buy-address-add-submit':'global-personal-profile-name-save');
      if(address){await tester.scrollUntilVisible(find.byKey(saveButton),200,scrollable:find.descendant(of:find.byKey(reviewField),matching:find.byType(Scrollable)).first);}else{await tester.ensureVisible(find.byKey(saveButton));}
      await tester.ensureVisible(find.byKey(saveButton));await tester.pumpAndSettle();
      expect(tester.getCenter(find.byKey(saveButton)).dy,lessThan(915));
      if(_clientPhase=='prepare')await tester.runAsync(()=>_control({'loseSave':'1'}));
      await tester.tap(find.byKey(saveButton));await tester.tap(find.byKey(saveButton));
      for(var i=0;i<100;i++){await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:20)));await tester.pump(const Duration(milliseconds:30));if(find.byKey(reviewField).evaluate().isEmpty)break;}
      if(_clientPhase=='prepare'){
        expect(rig.journal.values,isNotEmpty);expect(find.byKey(reviewField),findsOneWidget);
        final committed=(await tester.runAsync(()=>_control({})))!;expect(committed['sqlWrites'],1);
        gateway.dispose();navigator.currentState!.pop();await tester.pumpAndSettle();await tester.runAsync(()=>review!);
      }else{
      expect(find.byKey(reviewField),findsNothing);
      if(address){expect(session.accountProfileGateway!.snapshot!.deliveryAddresses.single.line,'Host test road');}else{expect(session.accountProfileGateway!.snapshot!.displayName,'\u092e\u094b\u0939\u0928');}
      await tester.runAsync(()=>review!);
      }
     }
     final stats=(await tester.runAsync(()=>_control({})))!;expect(stats['modelCalls'],1);expect(stats['sqlWrites'],1);expect(rig.journal.values,_clientPhase=='prepare'?isNotEmpty:isEmpty);
     if(_clientPhase=='prepare'){File('$_clientStorage/prepare-result.json').writeAsStringSync(jsonEncode({'clientPid':pid,'originalSaveJournalRetained':rig.journal.values.isNotEmpty,'assistantJournalRetained':File('$_clientStorage/assistant-pending.json').existsSync(),'modelCalls':stats['modelCalls'],'profileWrites':stats['sqlWrites']}),flush:true);}
    }finally{controller.dispose();gateway.dispose();paid.dispose();plans.dispose();guard.dispose();await tester.pumpWidget(const SizedBox.shrink());buy.dispose();work.dispose();session.dispose();await identity.changes.close();wire.inner.close(force:true);}
   },skip:_localContextPort==0);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  for(final changedAddress in [false,true]) {
    test('Domain saved address capture withholds stale native cache, address changed $changedAddress, without refreshing or saving',()async{
      final rig=Rig();
      // Keep every Profile read on the same explicit host source.
      final source=_AddressChoiceIdentity(rig),session=sessionFixture(source);await session.start();
      final store=CustomerStore(session.accountProfileGateway!.ownerScope),core=BuySession();
      final buy=BuyV2Session(core:core,reviewDataEnabled:false,customerStateStore:store);
      buy.synchronizeAccountProfile(session.accountProfileGateway);
      final work=WorkSession(gateway:ReviewWorkGateway());
      Map<String,Object?> saved(int revision,String line)=>{...profile(revision:revision),
        'selectedAddressId':'address-one','addresses':[{'id':'address-one','kind':'home','label':'Home',
          'recipient':'HOST recipient','phone':'9999999999','line':line,'area':'Jodhpur','pinCode':'342001','landmark':''}]};
      try{
        rig.transport.responses.add(saved(0,'HOST original street'));
        expect(await buy.refreshAccountProfileAddresses(preparationOnly:true),isTrue);
        final cache=store.saved,address=buy.addresses.single;
        rig.transport.responses.add(saved(1,changedAddress?'HOST changed street':'HOST original street'));
        final context=MoolAssistantContext(accountScope:session.authenticatedBuyPersistenceIdentity,
          authenticationRevision:session.navigationAuthenticationGeneration);
        final reader=AssistantOriginalContextReader(session:session,work:work,buy:buy,rootCurrent:()=>true);
        final captured=await reader.read(context,()=>true);
        expect(source.metadata!.reads,1);expect(session.accountProfileGateway!.snapshot!.revision,1);
        expect(captured.revisions.keys.where((key)=>assistantDomainAddressContextActions.contains(key.$1)),isEmpty);
        expect(identical(buy.addresses.single,address),isTrue);expect(identical(store.saved,cache),isTrue);
        expect(buy.addresses.single.line,'HOST original street');expect(buy.selectedAddressId,'address-one');
        expect(rig.transport.calls.every((call)=>call['operation']=='read'),isTrue);expect(rig.journal.values,isEmpty);
      }finally{buy.dispose();core.dispose();work.dispose();session.dispose();await source.changes.close();}
    });
  }
  test('THIN-B03 read-only Profile refresh calls only original read and accepts canonical revision', () async {
    final f = Rig(); f.transport.responses.add(profile());
    final value = await f.gateway.readForPreparation();
    expect(value.revision, 0);
    expect(f.transport.calls.map((v) => v['operation']), ['read']);
    expect(f.journal.values, isEmpty);
  });
  test('THIN-B03 pending confirmed Profile save is not replayed or cleared by AI capture', () async {
    final f = Rig(); await f.read();
    f.transport.responses.add(Exception('host timeout'));
    await expectLater(f.gateway.save({'kind': 'name', 'displayName': 'New name'}), throwsA(isA<AccountProfileFailure>()));
    final pending = Map<String, String>.of(f.journal.values), calls = f.transport.calls.length;
    expect(pending, isNotEmpty);
    await expectLater(f.gateway.readForPreparation(), throwsA(isA<AccountProfileFailure>().having((v) => v.uncertain, 'uncertain', true)));
    expect(f.transport.calls.length, calls); expect(f.journal.values, pending);
    // The established manual recovery path is preserved.
    f.transport.responses.addAll([receipt(), profile(revision: 1, name: 'New name')]);
    await f.gateway.read();
    expect(f.transport.calls[f.transport.calls.length - 2]['operation'], 'reconcile');
    expect(f.transport.calls.last['operation'], 'read'); expect(f.journal.values, isEmpty);
  });
  test('THIN-B03 read-only Profile refresh rejects foreign owner and account retirement', () async {
    final f = Rig(); await f.read(); f.transport.responses.add(profile(uid: 'owner-b'));
    await expectLater(f.gateway.readForPreparation(), throwsA(isA<AccountProfileFailure>()));
    expect(f.gateway.snapshot, isNull);
    f.current = false; final count = f.transport.calls.length;
    await expectLater(f.gateway.readForPreparation(), throwsA(isA<AccountProfileFailure>()));
    expect(f.transport.calls.length, count);
  });
  test('THIN-B03 read-only Profile refresh never joins an unknown in-flight writer', () async {
    final f = Rig(), response = Completer<SocialContentResponse>();
    f.transport.responses.add(response);
    final first = f.gateway.readForPreparation();
    await Future<void>.delayed(Duration.zero);
    await expectLater(f.gateway.readForPreparation(), throwsA(isA<AccountProfileFailure>()));
    response.complete(SocialContentResponse(statusCode: 503, body: '{}'));
    await expectLater(first, throwsA(isA<AccountProfileFailure>()));
    expect(f.transport.calls.length, 1);
  });
  test('THIN-B03 canonical and original native revisions are validated independently', () async {
    final f = _GuardFixture(); addTearDown(f.dispose); await f.capture();
    final snapshot = await f.adapter.snapshot(f.owner.value, null);
    expect(snapshot?.sourceRevision, 'profile:3');
    expect(await f.adapter.openReview(f.proposal(), () => true), MoolAssistantReviewResult.opened);
    expect(f.original.reviewed?.sourceRevision, 'original-local:1');
    expect(f.original.reviewed?.fields, {'displayName': 'मोहन'});
  });
  test('THIN-B03 fresh native token cannot relabel an old server preparation', () async {
    final f = _GuardFixture(); addTearDown(f.dispose); await f.capture();
    f.original.version++;
    expect((await f.adapter.snapshot(f.owner.value, null))?.permitted, false);
    expect(await f.adapter.openReview(f.proposal(), () => true), MoolAssistantReviewResult.stale);
    expect(f.original.opened, 0);
  });
  test('THIN-B03 canonical source change rejects unchanged local form', () async {
    final f = _GuardFixture(); addTearDown(f.dispose); await f.capture(); final old = f.proposal();
    f.revision = 'profile:4';
    expect((await f.adapter.snapshot(f.owner.value, null))?.permitted, false);
    expect(await f.adapter.openReview(old, () => true), MoolAssistantReviewResult.stale);
    expect(f.original.opened, 0);
  });
  test('THIN-B03 account A-B-A permanently retires the earlier anchors', () async {
    final f = _GuardFixture(); addTearDown(f.dispose); await f.capture(); final a = f.owner.value;
    f.owner.value = const MoolAssistantContext(accountScope: 'host-owner-b', authenticationRevision: 2);
    f.owner.value = a;
    expect(f.guard.current, false);
    expect(await f.adapter.snapshot(a, null), isNull); expect(f.original.opened, 0);
  });
  test('THIN-B03 account switch during canonical read discards late context', () async {
    final f = _GuardFixture(); addTearDown(f.dispose); f.delay = Completer<void>();
    final pending = f.capture();
    f.owner.value = const MoolAssistantContext(accountScope: 'host-owner-b', authenticationRevision: 2);
    f.delay!.complete(); await expectLater(pending, throwsA(isA<AssistantModelFailure>()));
    expect(f.guard.current, false);
  });
  test('THIN-B03 cancelled, expired and disposed context cannot open native review', () async {
    final f = _GuardFixture(); await f.capture(); f.guard.retire();
    expect(await f.adapter.snapshot(f.owner.value, null), isNull);
    await f.capture(); f.now = f.now.add(const Duration(minutes: 2));
    expect(f.guard.current, false); expect(await f.adapter.snapshot(f.owner.value, null), isNull);
    f.dispose(); expect(f.guard.current, false);
  });
  testWidgets('THIN-B03 actual original name form receives prefill without saving; only native Save writes', (tester) async {
    final rig = Rig();
    // Use one explicitly isolated original account source for every native read.
    final source = ProfileIdentity(rig), session = sessionFixture(source);
    await session.start();
    final buy = BuyV2Session(core: BuySession(), reviewDataEnabled: false,
      customerStateStore: CustomerStore(session.accountProfileGateway!.ownerScope));
    buy.synchronizeAccountProfile(session.accountProfileGateway);
    final work = WorkSession(gateway: ReviewWorkGateway());
    final navigator = GlobalKey<NavigatorState>();
    final changes = Listenable.merge([session, work, buy]);
    MoolAssistantContext context() => MoolAssistantContext(accountScope: session.authenticatedBuyPersistenceIdentity,
      authenticationRevision: session.navigationAuthenticationGeneration);
    late AssistantProfileContextGuard guard;
    Future<MoolAssistantReviewResult>? opened;
    final proposal = MoolAssistantProposal(id: 'host-native-name', actionId: 'AI-ACT-197',
      preparationRequestId:'host-preparation-name',preparationSourceRevision:'profile:0',
      binding: context().binding, requestRevision: 1, entitlementRevision: 'host-paid', sourceRevision: 'profile:0',
      validUntil: DateTime.now().add(const Duration(minutes: 1)), title: 'Review display name', summary: 'Host fixture',
      fields: {'displayName': 'Suggested name'});
    await tester.pumpWidget(MaterialApp(navigatorKey: navigator, home: Scaffold(body: TextButton(
      onPressed: () {opened = guard.adapters.singleWhere((a) => a.actionId == 'AI-ACT-197').openReview(proposal, () => true);},
      child: const Text('Review prepared name')))));
    final native = assistantOriginalProfileAdapters(session: session, buy: buy, navigator: navigator.currentState!,
      currentContext: context, rootCurrent: () => navigator.currentState?.mounted == true,
      routeIdentity: () => 'host-original-route', nameEditorAlreadyOpen: () => false,
      changes: changes, openPersonalPlans: () async {});
    final reader = AssistantOriginalContextReader(session: session, work: work, rootCurrent: () => navigator.currentState?.mounted == true);
    guard = AssistantProfileContextGuard(readCanonical: reader.read, readContext: context,
      ownerChanges: changes, nativeAdapters: native);
    rig.transport.responses.addAll(List.generate(10, (_) => profile()));
    await guard.capture(context(), () => true);
    await tester.tap(find.text('Review prepared name')); await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byKey(const Key('global-personal-profile-name-field')));
    expect(field.controller!.text, 'Suggested name');
    expect(rig.transport.calls.every((v) => v['operation'] == 'read'), true);
    expect(session.accountProfileGateway!.snapshot!.displayName, 'Original name');
    expect(rig.journal.values, isEmpty);
    rig.transport.responses.clear();
    rig.transport.responses.addAll([
      receiptFor({'kind': 'name', 'displayName': 'Suggested name'}, profile(revision: 1, name: 'Suggested name')),
      profile(revision: 1, name: 'Suggested name'),
    ]);
    await tester.ensureVisible(find.byKey(const Key('global-personal-profile-name-save')));
    await tester.tap(find.byKey(const Key('global-personal-profile-name-save'))); await tester.pumpAndSettle();
    expect(await opened, MoolAssistantReviewResult.opened);
    expect(rig.transport.calls.where((v) => v['operation'] == 'save').length, 1);
    final nativeRequest=Map<String,Object?>.from(rig.transport.calls.singleWhere((v)=>v['operation']=='save')['payload'] as Map);
    expect((nativeRequest['assistant'] as Map)['preparationRequestId'],'host-preparation-name');
    expect((nativeRequest['assistant'] as Map)['proposalId'],'host-native-name');
    expect(session.accountProfileGateway!.snapshot!.displayName, 'Suggested name');
    expect(find.text('Review prepared name'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    guard.dispose(); buy.dispose(); work.dispose(); session.dispose();
    await source.changes.close();
  });
}
