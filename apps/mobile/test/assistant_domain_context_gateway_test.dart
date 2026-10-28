import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/assistant/domain_context_gateway.dart';
import 'package:moolsocial/features/assistant/model_gateway.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';

// Explicit host-only credential and network seams; never phone authority/data.
const _owner = (environment: 'firebase-service', projectId: 'fixture-project', tenantId: null, userId: 'domain-host-a');
const _context = MoolAssistantContext(accountScope: _owner, authenticationRevision: 1);
final _at = DateTime.utc(2026, 10, 28, 8);
const _scope = {'audience': 'personal', 'storeId': null};
class _Credentials implements SocialContentCredentials {
  int tokens = 0;
  void Function()? onToken;
  final modes = <SocialAppCheckTokenMode>[];
  @override Future<String> firebaseIdToken() async {tokens++; onToken?.call(); return 'isolated-host-token';}
  @override Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {modes.add(mode); return 'isolated-host-proof';}
}
class _Wire implements SocialContentTransport {
  _Wire(this.reply);
  final FutureOr<SocialContentResponse> Function() reply;
  final bodies = <Map<String, Object?>>[];
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers,
      required Map<String, Object?> body}) async {
    expect(endpoint.toString(), 'https://asia-south1-fixture-project.cloudfunctions.net/moolSocialAssistantContext');
    bodies.add(body); return await reply();
  }
}
Map<String, Object?> _data() => {
  'ownerKey': sha256.convert(utf8.encode(jsonEncode(['fixture-project', 'domain-host-a', 'personal', null]))).toString(),
  'scope': _scope, 'validUntil': '2026-10-28T08:01:00.000Z',
  'revisions': [{'actionId': 'AI-ACT-001', 'entityId': null, 'sourceRevision': 'catalogue-search:host-source'}],
};
SocialContentResponse _ok(Map<String, Object?> data) => SocialContentResponse(
  statusCode: 200, body: jsonEncode({'ok': true, 'data': data}));
AssistantDomainContextGateway _source(_Wire wire, {_Credentials? credentials, bool Function()? current,bool compact=false}) =>
  AssistantDomainContextGateway(owner: _owner, isCurrent: current ?? () => true,
    credentials: credentials ?? _Credentials(), transport: wire, clock: () => _at,compactStoreSelection:compact);
void main() {
  for (final actions in [assistantStoreSupplierDraftContextActions, assistantStorePurchaseRootContextActions, assistantStoreOrderBoardContextActions]) {
  for (final compact in [false, true]) {
    test('Store roots ${actions.first} metadata needs exact proof approved Store and root target compact$compact', () async {
      final store = _context.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'Host Store', profile: 'retailer-grocery',
        revision: 1, isStore: true, approved: true, approvalAccountScope: _owner));
      final proof = '${actions.contains('AI-ACT-253') ? 'store-purchase-root-owner' : actions.contains('AI-ACT-273') ? 'store-order-board-owner' : 'store-supplier-draft-owner'}:${'a' * 64}';
      final data = <String, Object?>{..._data(),
        'ownerKey': sha256.convert(utf8.encode(jsonEncode(['fixture-project', 'domain-host-a', 'workspace', 'store-one']))).toString(),
        'scope': {'audience': 'workspace', 'storeId': 'store-one'},
        'revisions': compact ? <Object?>[] : [for (final action in actions)
          {'actionId': action, 'entityId': null, 'sourceRevision': proof}],
        if (compact) 'nativeSelection': {'version': 1, 'fingerprint': 'b' * 64, 'groups': [
          {'entityId': null, 'sourceRevision': proof, 'actionIds': actions.toList()}]} };
      final result = await _source(_Wire(() => _ok(data)), compact: compact).read(store, () => true);
      expect(result.revisions, {for (final action in actions) (action, null): proof});
      if (compact) expect(result.nativeSelection!.proofs, result.revisions);
      for (final fault in ['record-id', 'wrong-proof', 'edit-action', 'personal']) {
        final changed = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
        final rows = compact ? changed['nativeSelection']['groups'] as List : changed['revisions'] as List;
        final row = rows.first as Map;
        if (fault == 'record-id') row['entityId'] = 'invented-supplier';
        if (fault == 'wrong-proof') row['sourceRevision'] = 'store-product-defaults-owner:${'a' * 64}';
        if (fault == 'edit-action') {if (compact) {row['actionIds'] = ['AI-ACT-237'];} else {row['actionId'] = 'AI-ACT-237';}}
        await expectLater(_source(_Wire(() => _ok(changed)), compact: compact).read(fault == 'personal' ? _context : store, () => true),
          throwsA(isA<AssistantModelFailure>()));
      }
    });
  }
  }
  for(final compact in [false,true]) for (final action in ['AI-ACT-274','AI-ACT-243','AI-ACT-275','AI-ACT-280','AI-ACT-281','AI-ACT-285']) {
    test('Original Store $action metadata requires exact owned order proof compact$compact',()async{
      final store=_context.withWorkspace(const MoolAssistantWorkspace(id:'store-one',name:'Host Store',profile:'retailer-grocery',
        revision:1,isStore:true,approved:true,approvalAccountScope:_owner));
      final proof='${action == 'AI-ACT-274' ? 'store-order-original' : action == 'AI-ACT-243' ? 'store-receiving-original' : 'store-order-operational'}:evaluation:${'a'*64}';
      final data=<String,Object?>{..._data(),'ownerKey':sha256.convert(utf8.encode(jsonEncode([
        'fixture-project','domain-host-a','workspace','store-one']))).toString(),
        'scope':{'audience':'workspace','storeId':'store-one'},'revisions':compact?<Object?>[]:[
          {'actionId':action,'entityId':'order-one','sourceRevision':proof}],
        if(compact)'nativeSelection':{'version':1,'fingerprint':'b'*64,'groups':[
          {'entityId':'order-one','sourceRevision':proof,'actionIds':[action]}]}};
      final result=await _source(_Wire(()=>_ok(data)),compact:compact).read(store,()=>true);
      expect(result.revisions,{(action,'order-one'):proof});
      if(compact)expect(result.nativeSelection!.proofs,result.revisions);
      for(final fault in ['missing-order','wrong-proof','personal']){
        final changed=jsonDecode(jsonEncode(data)) as Map<String,dynamic>;
        final row=compact?(changed['nativeSelection']['groups'] as List).single as Map:(changed['revisions'] as List).single as Map;
        if(fault=='missing-order')row['entityId']=null;
        if(fault=='wrong-proof')row['sourceRevision']='catalogue-product:unrelated';
        await expectLater(_source(_Wire(()=>_ok(changed)),compact:compact).read(fault=='personal'?_context:store,()=>true),
          throwsA(isA<AssistantModelFailure>()));
      }
    });
  }
  for (final action in assistantDomainAddressContextActions) {
    test('Original saved address $action needs a personal exact address identity', () async {
      final data = {..._data(), 'revisions': [
        {'actionId': action, 'entityId': 'address-one', 'sourceRevision': 'profile:3'}]};
      final result = await _source(_Wire(() => _ok(data))).read(_context, () => true);
      expect(result.revisions, {(action, 'address-one'): 'profile:3'});
      final missing = {...data, 'revisions': [
        {'actionId': action, 'entityId': null, 'sourceRevision': 'profile:3'}]};
      await expectLater(_source(_Wire(() => _ok(missing))).read(_context, () => true), throwsA(isA<AssistantModelFailure>()));
      final store = _context.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'HOST Store',
        profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: _owner));
      final wrong = {...data, 'scope': {'audience': 'workspace', 'storeId': 'store-one'},
        'ownerKey': sha256.convert(utf8.encode(jsonEncode(['fixture-project', 'domain-host-a', 'workspace', 'store-one']))).toString()};
      await expectLater(_source(_Wire(() => _ok(wrong))).read(store, () => true), throwsA(isA<AssistantModelFailure>()));
    });
  }
  const capacityExport = String.fromEnvironment('AI_DOMAIN_STORE_NATIVE_EXPORT_PATH');
  test('Actual original 2500-product metadata crosses the real mobile decoder without trimming', () async {
    final export = jsonDecode(File(capacityExport).readAsStringSync()) as Map<String, dynamic>;
    expect(export['hostOnly'], true);
    final actor = export['capacityActor'] as Map;
    final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String,
      tenantId: null, userId: actor['uid'] as String);
    final envelope = export['capacityMetadata'] as Map<String, dynamic>;
    final data = envelope['data'] as Map<String, dynamic>;
    final scope = data['scope'] as Map;
    final context = MoolAssistantContext(accountScope: owner, authenticationRevision: 1).withWorkspace(
      MoolAssistantWorkspace(id: scope['storeId'] as String, name: 'Isolated original service Store',
        profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
    final source = AssistantDomainContextGateway(owner: owner, isCurrent: () => true,
      credentials: _Credentials(), transport: _CapacityWire(envelope), compactStoreSelection: true,
      clock: () => DateTime.parse(data['validUntil'] as String).subtract(const Duration(seconds: 30)));
    addTearDown(source.dispose);
    final snapshot = await source.read(context, () => true);
    expect(snapshot.nativeSelection!.keys.length, export['capacityTargetCount']);
    expect(snapshot.nativeSelection!.keys.length, 25014);
    expect(snapshot.nativeSelection!.keys.where((key)=>assistantStoreStockOwnerContextActions.contains(key.$1)).toSet(),
      {for(final action in assistantStoreStockOwnerContextActions)(action,null)});
    expect(export['nativeVariantKinds'],BuyV2VariantDimensionKind.values.map((kind)=>kind.name).toList());
    expect(snapshot.nativeSelection!.keys.where((key) => key.$1 == 'AI-ACT-214').length, 2500);
    expect(snapshot.nativeSelection!.keys.where((key) => key.$1 == 'AI-ACT-221').length, 2500);
    expect(utf8.encode(jsonEncode(envelope)).length, lessThan(2 * 1024 * 1024));
  }, skip: capacityExport.isEmpty ? 'Requires explicit isolated original-service export' : false);
  test('Opt-in Store metadata keeps original proofs and deterministic compact order', () async {
    final context = _context.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'Host Store',
      profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: _owner));
    final data = {..._data(), 'ownerKey': sha256.convert(utf8.encode(jsonEncode([
      'fixture-project', 'domain-host-a', 'workspace', 'store-one']))).toString(),
      'scope': {'audience': 'workspace', 'storeId': 'store-one'}, 'revisions': [],
      'nativeSelection': {'version': 1, 'fingerprint': 'a' * 64, 'groups': [
        {'actionIds': ['AI-ACT-214', 'AI-ACT-221'], 'entityId': 'sku-one', 'sourceRevision': 'original-proof'},
        {'actionIds': ['AI-ACT-218'], 'entityId': null, 'sourceRevision': 'owner-proof'},
      ]}};
    final wire = _Wire(() => _ok(data)), source = AssistantDomainContextGateway(owner: _owner, isCurrent: () => true,
      credentials: _Credentials(), transport: wire, clock: () => _at, compactStoreSelection: true);
    addTearDown(source.dispose);
    final value = await source.read(context, () => true);
    expect(value.nativeSelection!.keys, [('AI-ACT-214', 'sku-one'), ('AI-ACT-218', null), ('AI-ACT-221', 'sku-one')]);
    expect(value.nativeSelection!.proofs[('AI-ACT-221', 'sku-one')], 'original-proof');
    expect(() => value.nativeSelection!.proofs.clear(), throwsUnsupportedError);
    expect((wire.bodies.single['payload'] as Map)['nativeSelectionVersion'], 1);
    for (final bad in <Object?>[
      {'version': 2, 'fingerprint': 'a' * 64, 'groups': []},
      {'version': 1, 'fingerprint': 'bad', 'groups': []},
      {'version': 1, 'fingerprint': 'a' * 64, 'groups': [{'actionIds': ['AI-ACT-214', 'AI-ACT-214'], 'entityId': 'sku-one', 'sourceRevision': 'original'}]},
      {'version': 1, 'fingerprint': 'a' * 64, 'groups': [{'actionIds': ['AI-ACT-001'], 'entityId': null, 'sourceRevision': 'original'}]},
      {'version': 1, 'fingerprint': 'a' * 64, 'groups': [{'actionIds': ['AI-ACT-214'], 'entityId': null, 'sourceRevision': 'original'}]},
      {'version': 1, 'fingerprint': 'a' * 64, 'groups': [for (var n = 0; n < 2; n++) {'actionIds': ['AI-ACT-214'], 'entityId': 'sku-one', 'sourceRevision': 'original-$n'}]},
    ]) {
      data['nativeSelection'] = bad;
      await expectLater(source.read(context, () => true), throwsA(isA<AssistantModelFailure>()));
    }
  });
  for (final action in assistantStoreOwnerContextActions) {
  test('Owned Store $action native owner metadata cannot claim a product or personal context', () async {
    final store = _context.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'Host fixture Store',
      profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: _owner));
    final data = {..._data(), 'ownerKey': sha256.convert(utf8.encode(jsonEncode([
      'fixture-project', 'domain-host-a', 'workspace', 'store-one']))).toString(),
      'scope': {'audience': 'workspace', 'storeId': 'store-one'}, 'revisions': [
        {'actionId': action, 'entityId': null, 'sourceRevision': assistantStoreSupplierDraftContextActions.contains(action)
          ? 'store-supplier-draft-owner:${'a' * 64}' : assistantStorePurchaseRootContextActions.contains(action)
          ? 'store-purchase-root-owner:${'a' * 64}' : assistantStoreOrderBoardContextActions.contains(action)
          ? 'store-order-board-owner:${'a' * 64}' : 'native-owned-defaults-owner-proof'},
      ]};
    final value = await _source(_Wire(() => _ok(data))).read(store, () => true);
    expect(value.revisions.keys.single, (action, null));
    final wrongEntity = {...data, 'revisions': [
      {'actionId': action, 'entityId': 'owned-sku-one', 'sourceRevision': 'wrong-domain'},
    ]};
    await expectLater(_source(_Wire(() => _ok(wrongEntity))).read(store, () => true), throwsA(isA<AssistantModelFailure>()));
    final personal = {..._data(), 'revisions': data['revisions']};
    await expectLater(_source(_Wire(() => _ok(personal))).read(_context, () => true), throwsA(isA<AssistantModelFailure>()));
  });
  }
  for (final action in assistantStoreProductContextActions) {
  test('Owned Store $action metadata stays in the approved Store context and rejects personal or foreign scope', () async {
    final store = _context.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'Host fixture Store',
      profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: _owner));
    final data = {..._data(), 'ownerKey': sha256.convert(utf8.encode(jsonEncode([
      'fixture-project', 'domain-host-a', 'workspace', 'store-one']))).toString(),
      'scope': {'audience': 'workspace', 'storeId': 'store-one'}, 'revisions': [
        {'actionId': 'AI-ACT-317', 'entityId': 'store-one', 'sourceRevision': 'original-workspace-authority'},
        {'actionId': action, 'entityId': 'owned-sku-one', 'sourceRevision': 'original-owned-product'},
      ]};
    final wire = _Wire(() => _ok(data));
    final result = await _source(wire).read(store, () => true);
    expect(result.revisions, {(action, 'owned-sku-one'): 'original-owned-product'});
    expect((wire.bodies.single['payload'] as Map)['scope'], {'audience': 'workspace', 'storeId': 'store-one'});
    final personal = {..._data(), 'revisions': [
      {'actionId': action, 'entityId': 'owned-sku-one', 'sourceRevision': 'forged-personal-product'},
    ]};
    await expectLater(_source(_Wire(() => _ok(personal))).read(_context, () => true), throwsA(isA<AssistantModelFailure>()));
    final missing = {...data, 'revisions': [
      {'actionId': action, 'entityId': null, 'sourceRevision': 'missing-original-SKU'},
    ]};
    await expectLater(_source(_Wire(() => _ok(missing))).read(store, () => true), throwsA(isA<AssistantModelFailure>()));
    final foreign = {...data, 'scope': {'audience': 'workspace', 'storeId': 'foreign-store'}};
    await expectLater(_source(_Wire(() => _ok(foreign))).read(store, () => true), throwsA(isA<AssistantModelFailure>()));
    const pending = MoolAssistantContext(accountScope: _owner, authenticationRevision: 1, workspaceId: 'store-one',
      workspaceRevision: 1, storeWorkspace: true, workspaceApproved: false);
    final unavailableWire = _Wire(() => _ok(data));
    await expectLater(_source(unavailableWire).read(pending, () => true), throwsA(isA<AssistantModelFailure>()));
    expect(unavailableWire.bodies, isEmpty);
  });
  }
  for (final action in assistantDomainProductContextActions) {
  test('Domain $action metadata must belong to the immutable original selection sent', () async {
    final id = 'listing-${List.filled(64, 'a').join()}';
    final selected = <String>[id];
    final wire = _Wire(() => _ok({..._data(), 'revisions': [
      {'actionId': action, 'entityId': id, 'sourceRevision': 'catalogue-product:original'},
    ]}));
    final value = await _source(wire).read(_context, () => true, catalogueListingIds: selected);
    selected.clear();
    expect(value.catalogueListingIds, [id]);
    expect(value.revisions.keys.single, (action, id));
    expect((wire.bodies.single['payload'] as Map)['catalogueListingIds'], [id]);
    await expectLater(_source(wire).read(_context, () => true), throwsA(isA<AssistantModelFailure>()));
  });
  }
  test('Category channel and area read metadata remains personal and has no invented entity', () async {
    for (final action in ['AI-ACT-002', 'AI-ACT-003', 'AI-ACT-004', 'AI-ACT-005',
      ...assistantDomainPreferenceContextActions]) {
      final data = {..._data(), 'revisions': [
        {'actionId': action, 'entityId': null, 'sourceRevision': 'catalogue-choice:original'},
      ]};
      final value = await _source(_Wire(() => _ok(data))).read(_context, () => true);
      expect(value.revisions.keys.single, (action, null));
      final invalid = {...data, 'revisions': [
        {'actionId': action, 'entityId': 'invented-entity', 'sourceRevision': 'catalogue-choice:original'},
      ]};
      await expectLater(_source(_Wire(() => _ok(invalid))).read(_context, () => true), throwsA(isA<AssistantModelFailure>()));
    }
  });
  test('Private stars metadata requires a personal exact order and original rating proof',()async{
    final proof='buyer-product-stars:evaluation:${'a'*64}',data={..._data(),
      'revisions':[{'actionId':'AI-ACT-055','entityId':'host-purchased-order','sourceRevision':'buyer-product-stars:evaluation:${'a'*64}'}]};
    final value=await _source(_Wire(()=>_ok(data))).read(_context,()=>true);
    expect(value.revisions,{('AI-ACT-055','host-purchased-order'):proof});
    for(final row in [
      {'actionId':'AI-ACT-055','entityId':null,'sourceRevision':proof},
      {'actionId':'AI-ACT-055','entityId':'host-purchased-order','sourceRevision':'catalogue:invented'},
    ])await expectLater(_source(_Wire(()=>_ok({..._data(),'revisions':[row]}))).read(_context,()=>true),throwsA(isA<AssistantModelFailure>()));
    const workspace=MoolAssistantContext(accountScope:_owner,authenticationRevision:1,workspaceId:'store-one',
      workspaceRevision:1,storeWorkspace:true,workspaceApproved:true);
    final foreign={...data,'scope':{'audience':'workspace','storeId':'store-one'},
      'ownerKey':sha256.convert(utf8.encode(jsonEncode(['fixture-project','domain-host-a','workspace','store-one']))).toString()};
    await expectLater(_source(_Wire(()=>_ok(foreign))).read(workspace,()=>true),throwsA(isA<AssistantModelFailure>()));
  });
  test('Domain gateway exact read-only request returns bound registered revisions with standard proof', () async {
    final credentials = _Credentials(), wire = _Wire(() => _ok(_data()));
    final value = await _source(wire, credentials: credentials).read(_context, () => true);
    expect(value.binding, _context.binding); expect(value.revisions, {('AI-ACT-001', null): 'catalogue-search:host-source'});
    expect(wire.bodies, [{'operation': 'read', 'payload': {'scope': _scope}}]);
    expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
  });
  test('Domain gateway unsigned or foreign account cannot read source or credentials', () async {
    final credentials = _Credentials(), wire = _Wire(() => _ok(_data())), source = _source(wire, credentials: credentials);
    for (final c in [const MoolAssistantContext(accountScope: null, authenticationRevision: null),
      const MoolAssistantContext(accountScope: 'foreign', authenticationRevision: 1)]) {
      await expectLater(source.read(c, () => true), throwsA(isA<AssistantModelFailure>()));
    }
    expect(credentials.tokens, 0); expect(wire.bodies, isEmpty);
  });
  test('Domain gateway retired identity while awaiting credential stops before network', () async {
    var current = true; final credentials = _Credentials()..onToken = () {current = false;};
    final wire = _Wire(() => _ok(_data()));
    await expectLater(_source(wire, credentials: credentials, current: () => current).read(_context, () => current), throwsA(anything));
    expect(wire.bodies, isEmpty);
  });
  test('Domain gateway foreign owner response retires this source and never becomes a grant', () async {
    final wire = _Wire(() => _ok({..._data(), 'ownerKey': 'another-owner'})), source = _source(wire);
    await expectLater(source.read(_context, () => true), throwsA(anything));
    await expectLater(source.read(_context, () => true), throwsA(anything));
    expect(wire.bodies.length, 1); expect(source.available, false);
  });
  test('Domain gateway rejects malformed unknown and duplicate tool metadata', () async {
    for (final data in [{..._data(), 'toolInstructions': 'run arbitrary code'},
      {..._data(), 'revisions': [{'actionId': 'AI-ACT-235', 'entityId': null, 'sourceRevision': 'fake'}]},
      {..._data(), 'revisions': [for (var i = 0; i < 2; i++) {'actionId': 'AI-ACT-001', 'entityId': null, 'sourceRevision': 'same'}]},
      {..._data(), 'revisions': [{'actionId': 'AI-ACT-001', 'entityId': 'guessed-product', 'sourceRevision': 'same'}]}]) {
      await expectLater(_source(_Wire(() => _ok(data))).read(_context, () => true), throwsA(anything));
    }
  });
  test('Domain gateway expired or unbounded validity never opens a native action', () async {
    for (final stamp in ['2026-10-28T07:59:00.000Z', '2026-10-29T08:00:00.000Z', 'not-a-stamp']) {
      await expectLater(_source(_Wire(() => _ok({..._data(), 'validUntil': stamp}))).read(_context, () => true), throwsA(anything));
    }
  });
  test('Domain gateway temporary access failure can revalidate without private cached metadata', () async {
    var deny = true; final wire = _Wire(() => deny ? const SocialContentResponse(statusCode: 403, body: '{}') : _ok(_data()));
    final source = _source(wire); await expectLater(source.read(_context, () => true), throwsA(anything));
    deny = false; expect((await source.read(_context, () => true)).revisions.length, 1); expect(wire.bodies.length, 2);
  });
  test('Domain gateway scope switch while awaiting response retires stale metadata', () async {
    var current = true; final wire = _Wire(() {current = false; return _ok(_data());});
    await expectLater(_source(wire).read(_context, () => current), throwsA(anything));
  });
  test('Domain gateway cross-Store response cannot bind a personal source', () async {
    final source = _source(_Wire(() => _ok({..._data(), 'scope': {'audience': 'workspace', 'storeId': 'store-a'}})));
    await expectLater(source.read(_context, () => true), throwsA(anything)); expect(source.available, false);
  });
  test('Domain gateway disposal prevents fresh credential and source reads', () async {
    final credentials = _Credentials(), wire = _Wire(() => _ok(_data()));
    final source = _source(wire, credentials: credentials)..dispose();
    await expectLater(source.read(_context, () => true), throwsA(anything)); expect(credentials.tokens, 0);
  });
}

class _CapacityWire implements SocialContentTransport {
  _CapacityWire(this.envelope);
  final Map<String, dynamic> envelope;
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers,
    required Map<String, Object?> body}) async {
    expect((body['payload'] as Map)['nativeSelectionVersion'], 1);
    return SocialContentResponse(statusCode: 200, body: jsonEncode(envelope));
  }
}
