import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/assistant/domain_context_gateway.dart';
import 'package:moolsocial/features/assistant/model_gateway.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/work/work_catalogue_gateway.dart';
import 'package:moolsocial/features/work/work_session.dart';
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
  const surplusExport = String.fromEnvironment('AI_DOMAIN_SURPLUS_CONTEXT_EXPORT_PATH');
  for (final action in ['AI-ACT-262', 'AI-ACT-266', 'AI-ACT-267', 'AI-ACT-378']) {
    test('Actual SDK original bill-surplus metadata $action preserves original copy and source ownership', () async {
      final capture = jsonDecode(File('$surplusExport.$action.json').readAsStringSync()) as Map<String, dynamic>;
      expect(capture['label'], 'ISOLATED SDK ORIGINAL BILL SURPLUS; NO RUNTIME AUTHORITY');
      final actor = capture['actor'] as Map<String, dynamic>, request = capture['request'] as Map<String, dynamic>;
      final scope = request['scope'] as Map<String, dynamic>, proposal = capture['proposal'] as Map<String, dynamic>;
      final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String, tenantId: null, userId: actor['uid'] as String);
      final context = MoolAssistantContext(accountScope: owner, authenticationRevision: 1).withWorkspace(
        MoolAssistantWorkspace(id: scope['storeId'] as String, name: 'HOST original bill credit', profile: 'retailer-grocery',
          revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
      final metadata = capture['metadata'] as Map<String, dynamic>, data = metadata['data'] as Map<String, dynamic>;
      final gateway = AssistantDomainContextGateway(owner: owner, isCurrent: () => true, credentials: _Credentials(),
        transport: _CapacityWire(metadata), compactStoreSelection: true,
        clock: () => DateTime.parse(data['validUntil'] as String).subtract(const Duration(seconds: 30)));
      addTearDown(gateway.dispose);
      final result = await gateway.read(context, () => true);
      expect(result.revisions, {(action, proposal['entityId'] as String?): proposal['sourceRevision']});
      expect(assistantNativeTargetSelection([(actionId: action, entityId: proposal['entityId'] as String?)]), hasLength(1));
      final fields = proposal['fields'] as Map<String, dynamic>;
      if (action == 'AI-ACT-262' || action == 'AI-ACT-266') {
        expect(fields['sourceKind'], 'manualBillSurplus'); expect(fields['amount'], '0.50');
        expect(fields['sourceId'], 'HOST-original-bill-draft'); expect(fields['copyRevision'], isA<int>());
        if (action == 'AI-ACT-266') expect(fields['copyId'], 'HOST-original-bill-copy');
        else {expect(fields['copyId'], 'HOST-credit-target-copy'); expect(fields.containsKey('sourceCopyId'), false);}
      } else {expect(fields, isEmpty);}
      expect(jsonEncode(proposal), isNot(contains('idempotencyKey')));
      expect(jsonEncode(metadata), isNot(contains('availableMinor')));
      final other = context.withWorkspace(MoolAssistantWorkspace(id: 'HOST-other-store', name: 'HOST other', profile: 'retailer-grocery',
        revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
      await expectLater(gateway.read(other, () => true), throwsA(isA<AssistantModelFailure>()));
    }, skip: surplusExport.isEmpty ? 'Requires explicit actual local SDK bill-credit context capture' : false);
  }
  const creditExport = String.fromEnvironment('AI_DOMAIN_CREDIT_CONTEXT_EXPORT_PATH');
  for (final kind in ['goodsReturned', 'arrivalDamage', 'shortage']) {
    for (final treatment in ['gst', 'commercial']) {
      for (final action in ['AI-ACT-264', treatment == 'gst' ? 'AI-ACT-375' : 'AI-ACT-376', 'AI-ACT-265', 'AI-ACT-379']) {
        test('Actual SDK original credit metadata $kind $treatment $action preserves document and native request ownership', () async {
          final capture = jsonDecode(File('$creditExport.$kind.$treatment.$action.json').readAsStringSync()) as Map<String, dynamic>;
          expect(capture['label'], 'ISOLATED SDK ORIGINAL CREDIT PREPARATION; NO MODEL REQUEST ID OR FINANCIAL EFFECT');
          final actor = capture['actor'] as Map<String, dynamic>, request = capture['request'] as Map<String, dynamic>;
          final scope = request['scope'] as Map<String, dynamic>, proposal = capture['proposal'] as Map<String, dynamic>;
          final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String, tenantId: null, userId: actor['uid'] as String);
          final context = MoolAssistantContext(accountScope: owner, authenticationRevision: 1).withWorkspace(
            MoolAssistantWorkspace(id: scope['storeId'] as String, name: 'HOST original credit Store', profile: 'retailer-grocery',
              revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
          final metadata = capture['metadata'] as Map<String, dynamic>, data = metadata['data'] as Map<String, dynamic>;
          final gateway = AssistantDomainContextGateway(owner: owner, isCurrent: () => true, credentials: _Credentials(),
            transport: _CapacityWire(metadata), compactStoreSelection: true,
            clock: () => DateTime.parse(data['validUntil'] as String).subtract(const Duration(seconds: 30)));
          addTearDown(gateway.dispose);
          final result = await gateway.read(context, () => true);
          expect(result.revisions, {(action, proposal['entityId'] as String?): proposal['sourceRevision']});
          expect(assistantNativeTargetSelection([(actionId: action, entityId: proposal['entityId'] as String?)]), hasLength(1));
          final fields = proposal['fields'] as Map<String, dynamic>;
          if (const {'AI-ACT-265', 'AI-ACT-379'}.contains(action)) {
            expect(fields, isEmpty, reason: 'Only encrypted native input identifies an interrupted request.');
          } else {
            expect(fields['reference'], 'HOST-CN-ગુજરાતી'); expect(fields['amount'], '1.00');
            final document = fields['documentInput'] as Map<String, dynamic>;
            expect(document['treatment'], treatment); expect(document['version'], 2);
            expect(document['particulars'], {'supplierName': 'HOST printed supplier', 'invoiceReferences': 'HOST-INV-1'});
            final support = (fields['supports'] as List).single as Map<String, dynamic>;
            expect((jsonDecode(support['id'] as String) as List).first, kind); expect(support['quantity'], '0.250');
          }
          expect(jsonEncode(proposal), isNot(contains('idempotencyKey')));
          expect(jsonEncode(metadata), isNot(contains('availableMinor')));
          final other = context.withWorkspace(MoolAssistantWorkspace(id: 'HOST-other-store', name: 'HOST other', profile: 'retailer-grocery',
            revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
          await expectLater(gateway.read(other, () => true), throwsA(isA<AssistantModelFailure>()));
        }, skip: creditExport.isEmpty ? 'Requires explicit actual local SDK credit context capture' : false);
      }
    }
  }
  const refundExport = String.fromEnvironment('AI_DOMAIN_REFUND_CONTEXT_EXPORT_PATH');
  for (final kind in ['openingAdvance', 'accountAdvance']) {
    for (final action in ['AI-ACT-266', 'AI-ACT-267', 'AI-ACT-378']) {
      test('Actual SDK original refund metadata $kind $action preserves source and native request ownership', () async {
        final export = jsonDecode(File('$refundExport.$kind.$action.json').readAsStringSync()) as Map<String, dynamic>;
        expect(export['label'], 'ISOLATED SDK ORIGINAL REFUND PREPARATION; NO MODEL REQUEST ID OR FINANCIAL EFFECT');
        final actor = export['actor'] as Map<String, dynamic>, request = export['request'] as Map<String, dynamic>;
        final scope = request['scope'] as Map<String, dynamic>, proposal = export['proposal'] as Map<String, dynamic>;
        final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String,
          tenantId: null, userId: actor['uid'] as String);
        final context = MoolAssistantContext(accountScope: owner, authenticationRevision: 1).withWorkspace(
          MoolAssistantWorkspace(id: scope['storeId'] as String, name: 'HOST original refund Store', profile: 'retailer-grocery',
            revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
        final metadata = export['metadata'] as Map<String, dynamic>, data = metadata['data'] as Map<String, dynamic>;
        final gateway = AssistantDomainContextGateway(owner: owner, isCurrent: () => true,
          credentials: _Credentials(), transport: _CapacityWire(metadata), compactStoreSelection: true,
          clock: () => DateTime.parse(data['validUntil'] as String).subtract(const Duration(seconds: 30)));
        addTearDown(gateway.dispose);
        final result = await gateway.read(context, () => true);
        expect(result.revisions, {(action, proposal['entityId'] as String?): proposal['sourceRevision']});
        final hint = (actionId: action, entityId: proposal['entityId'] as String?);
        expect(hint.entityId, matches(RegExp(r'^ledger-refund:[a-f0-9]{64}$')));
        expect(assistantNativeTargetSelection([hint]), [hint]);
        expect(() => assistantNativeTargetSelection([(actionId: action, entityId: '["HOST-source"]')]),
          throwsA(isA<AssistantModelFailure>()));
        final fields = proposal['fields'] as Map<String, dynamic>;
        if (action == 'AI-ACT-266') {
          expect(fields.keys.toSet(), {'supplierId', 'copyId', 'copyRevision', 'openingId', 'openingRevision', 'sourceKind', 'sourceId', 'amount', 'reference', 'channel', 'occurredOn'});
          expect(fields['sourceKind'], kind); expect(fields['amount'], '2.50');
          expect(fields['copyId'], isNull); expect(fields['copyRevision'], isNull);
          expect(fields['channel'], 'Cash');
        } else {expect(fields, isEmpty);}
        expect(jsonEncode(proposal), isNot(contains('idempotencyKey')));
        expect(jsonEncode(metadata), isNot(contains('availableMinor')));
        final other = context.withWorkspace(MoolAssistantWorkspace(id: 'HOST-other-store', name: 'HOST other', profile: 'retailer-grocery',
          revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
        await expectLater(gateway.read(other, () => true), throwsA(isA<AssistantModelFailure>()));
      }, skip: refundExport.isEmpty ? 'Requires explicit isolated original refund SDK context export' : false);
    }
  }
  const allocationExport = String.fromEnvironment('AI_DOMAIN_ALLOCATION_CONTEXT_EXPORT_PATH');
  for (final kind in ['openingAdvance', 'accountPayment', 'accountAdvance']) {
    for (final action in ['AI-ACT-262', 'AI-ACT-263', 'AI-ACT-377']) {
      test('Actual SDK original allocation metadata $kind $action preserves source and native request ownership', () async {
        final export = jsonDecode(File('$allocationExport.$kind.$action.json').readAsStringSync()) as Map<String, dynamic>;
        expect(export['label'], 'ISOLATED SDK ORIGINAL ALLOCATION PREPARATION; NO MODEL REQUEST ID OR FINANCIAL EFFECT');
        final actor = export['actor'] as Map<String, dynamic>, request = export['request'] as Map<String, dynamic>;
        final scope = request['scope'] as Map<String, dynamic>, proposal = export['proposal'] as Map<String, dynamic>;
        final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String,
          tenantId: null, userId: actor['uid'] as String);
        final context = MoolAssistantContext(accountScope: owner, authenticationRevision: 1).withWorkspace(
          MoolAssistantWorkspace(id: scope['storeId'] as String, name: 'HOST original allocation Store', profile: 'retailer-grocery',
            revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
        final metadata = export['metadata'] as Map<String, dynamic>, data = metadata['data'] as Map<String, dynamic>;
        final gateway = AssistantDomainContextGateway(owner: owner, isCurrent: () => true,
          credentials: _Credentials(), transport: _CapacityWire(metadata), compactStoreSelection: true,
          clock: () => DateTime.parse(data['validUntil'] as String).subtract(const Duration(seconds: 30)));
        addTearDown(gateway.dispose);
        final result = await gateway.read(context, () => true);
        expect(result.revisions, {(action, proposal['entityId'] as String?): proposal['sourceRevision']});
        final fields = proposal['fields'] as Map<String, dynamic>;
        if (action == 'AI-ACT-262') {
          expect(fields.keys.toSet(), {'supplierId', 'copyId', 'copyRevision', 'openingId', 'openingRevision', 'sourceKind', 'sourceId', 'amount'});
          expect(fields['sourceKind'], kind); expect(fields['amount'], '2.50');
        } else {expect(fields, isEmpty);}
        expect(jsonEncode(proposal), isNot(contains('idempotencyKey')));
        expect(jsonEncode(metadata), isNot(contains('availableMinor')));
        final other = context.withWorkspace(MoolAssistantWorkspace(id: 'HOST-other-store', name: 'HOST other', profile: 'retailer-grocery',
          revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
        await expectLater(gateway.read(other, () => true), throwsA(isA<AssistantModelFailure>()));
      }, skip: allocationExport.isEmpty ? 'Requires explicit isolated original allocation SDK context export' : false);
    }
  }
  const billMoneyExport = String.fromEnvironment('AI_DOMAIN_BILL_MONEY_CONTEXT_EXPORT_PATH');
  for (final action in ['AI-ACT-259', 'AI-ACT-260', 'AI-ACT-261']) {
    test('Actual SDK confirmed-bill money metadata $action decodes through the original mobile source', () async {
      final export = jsonDecode(File('$billMoneyExport.$action.json').readAsStringSync()) as Map<String, dynamic>;
      expect(export['label'], 'ISOLATED SDK ORIGINAL BILL MONEY PREPARATION; NO LIVE MODEL OR AUTHORITY');
      final actor = export['actor'] as Map<String, dynamic>, request = export['request'] as Map<String, dynamic>;
      final scope = request['scope'] as Map<String, dynamic>, proposal = export['proposal'] as Map<String, dynamic>;
      final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String,
        tenantId: null, userId: actor['uid'] as String);
      final context = MoolAssistantContext(accountScope: owner, authenticationRevision: 1).withWorkspace(
        MoolAssistantWorkspace(id: scope['storeId'] as String, name: 'HOST original bill money Store', profile: 'retailer-grocery',
          revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
      final metadata = export['metadata'] as Map<String, dynamic>, data = metadata['data'] as Map<String, dynamic>;
      final gateway = AssistantDomainContextGateway(owner: owner, isCurrent: () => true,
        credentials: _Credentials(), transport: _CapacityWire(metadata), compactStoreSelection: true,
        clock: () => DateTime.parse(data['validUntil'] as String).subtract(const Duration(seconds: 30)));
      final result = await gateway.read(context, () => true);
      expect(result.revisions, {(action, proposal['entityId'] as String?): proposal['sourceRevision']});
      expect(jsonEncode(metadata), isNot(contains('HOST explicit bill money reference')));
      expect(jsonEncode(metadata), isNot(contains('notIncludedInOpening')));
    }, skip: billMoneyExport.isEmpty ? 'Requires explicit isolated SDK bill-money context export' : false);
  }
  const moneyExport = String.fromEnvironment('AI_DOMAIN_ORIGINAL_MONEY_CONTEXT_EXPORT_PATH');
  for (final action in ['AI-ACT-260', 'AI-ACT-261']) {
    test('Actual SDK original supplier money metadata $action decodes through the mobile gateway', () async {
      final export = jsonDecode(File('$moneyExport.$action.json').readAsStringSync()) as Map<String, dynamic>;
      expect(export['label'], 'ISOLATED SDK ORIGINAL MONEY PREPARATION; NO LIVE MODEL OR AUTHORITY');
      final actor = export['actor'] as Map<String, dynamic>, request = export['request'] as Map<String, dynamic>;
      final scope = request['scope'] as Map<String, dynamic>, proposal = export['proposal'] as Map<String, dynamic>;
      final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String,
        tenantId: null, userId: actor['uid'] as String);
      final context = MoolAssistantContext(accountScope: owner, authenticationRevision: 1).withWorkspace(
        MoolAssistantWorkspace(id: scope['storeId'] as String, name: 'HOST original money Store', profile: 'retailer-grocery',
          revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
      final metadata = export['metadata'] as Map<String, dynamic>, data = metadata['data'] as Map<String, dynamic>;
      final credentials = _Credentials();
      final gateway = AssistantDomainContextGateway(owner: owner, isCurrent: () => true,
        credentials: credentials, transport: _CapacityWire(metadata), compactStoreSelection: true,
        clock: () => DateTime.parse(data['validUntil'] as String).subtract(const Duration(seconds: 30)));
      final result = await gateway.read(context, () => true);
      expect(result.revisions, {(action, proposal['entityId'] as String?): proposal['sourceRevision']});
      expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
      expect(jsonEncode(metadata), isNot(contains('HOST originally supplied payment')));
      expect(jsonEncode(metadata), isNot(contains('notIncludedInOpening')));
    }, skip: moneyExport.isEmpty ? 'Requires explicit isolated actual SDK money-context export' : false);
  }
  const ledgerExport = String.fromEnvironment('AI_DOMAIN_LEDGER_CONTEXT_EXPORT_PATH');
  test('Actual SDK original ledger preparation metadata decodes through the mobile gateway', () async {
    final export = jsonDecode(File(ledgerExport).readAsStringSync()) as Map<String, dynamic>;
    expect(export['label'], 'ISOLATED ACTUAL SDK AI CONTEXT; NO RUNTIME AUTHORITY');
    final actor = export['actor'] as Map<String, dynamic>, scope = export['scope'] as Map<String, dynamic>;
    final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String,
      tenantId: null, userId: actor['uid'] as String);
    final context = MoolAssistantContext(accountScope: owner, authenticationRevision: 1).withWorkspace(
      MoolAssistantWorkspace(id: scope['storeId'] as String, name: 'HOST SDK Store', profile: 'retailer-grocery',
        revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
    final credentials = _Credentials();
    final gateway = AssistantDomainContextGateway(owner: owner, isCurrent: () => true,
      credentials: credentials, transport: _CapacityWire(export['metadata'] as Map<String, dynamic>),
      clock: () => DateTime.parse(export['now'] as String), compactStoreSelection: true);
    final result = await gateway.read(context, () => true);
    for (final raw in export['nativeTargets'] as List) {
      final target = raw as Map;
      expect(result.revisions[(target['actionId'] as String, target['entityId'] as String?)], target['sourceRevision']);
    }
    expect(result.revisions.length, (export['nativeTargets'] as List).length);
    expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
    expect(jsonEncode(export['metadata']), isNot(contains('sourceNote')));
    expect(jsonEncode(export['metadata']), isNot(contains('openingMinor')));
  }, skip: ledgerExport.isEmpty ? 'Requires explicit isolated actual SDK ledger-context export' : false);
  for (final action in assistantStoreLedgerContextActions) {
    test('Original ledger metadata $action requires approved Store and exact original proof', () async {
      const storeId = 'store-one';
      final context = _context.withWorkspace(const MoolAssistantWorkspace(id: storeId, name: 'HOST Store',
        profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: _owner));
      final entity = action == 'AI-ACT-270' ? null : action == 'AI-ACT-271' ? 'ledger-register:${'b' * 64}' : 'HOST-original-supplier';
      final row = {'actionId': action, 'entityId': entity, 'sourceRevision': 'store-original-ledger-v1:${'a' * 64}'};
      final data = {..._data(), 'ownerKey': sha256.convert(utf8.encode(jsonEncode([
        _owner.projectId, _owner.userId, 'workspace', storeId]))).toString(),
        'scope': {'audience': 'workspace', 'storeId': storeId}, 'revisions': [row]};
      expect((await _source(_Wire(() => _ok(data))).read(context, () => true)).revisions[(action, entity)], row['sourceRevision']);
      for (final fault in ['personal', 'proof', 'entity', 'foreign owner']) {
        final changed = jsonDecode(jsonEncode(data)) as Map<String, dynamic>, changedRow = (jsonDecode(jsonEncode(row)) as Map<String, dynamic>);
        if (fault == 'proof') changedRow['sourceRevision'] = 'unqualified-source';
        if (fault == 'entity') changedRow['entityId'] = action == 'AI-ACT-270' ? 'HOST-foreign' : null;
        if (fault == 'foreign owner') changed['ownerKey'] = 'b' * 64;
        changed['revisions'] = [changedRow];
        await expectLater(_source(_Wire(() => _ok(changed))).read(fault == 'personal' ? _context : context, () => true), throwsA(anything));
      }
    });
  }
  const priceExport = String.fromEnvironment('AI_DOMAIN_PRICE_REFRESH_EXPORT_PATH');
  test('Actual expired-price catalogue HTTP metadata decodes through the original mobile gateway', () async {
    final data = jsonDecode(File(priceExport).readAsStringSync()) as Map<String, dynamic>;
    expect(data['hostOnly'], true);
    final actor = data['actor'] as Map<String, dynamic>;
    final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String,
      tenantId: null, userId: actor['uid'] as String);
    final listing = data['listingId'] as String;
    final gateway = AssistantDomainContextGateway(owner: owner, isCurrent: () => true, credentials: _Credentials(),
      transport: _BackendReferenceWire(data['metadata'] as Map<String, dynamic>, listingIds: [listing]),
      clock: () => DateTime.parse(data['now'] as String));
    final result = await gateway.read(MoolAssistantContext(accountScope: owner, authenticationRevision: 1),
      () => true, catalogueListingIds: [listing]);
    for (final action in ['AI-ACT-060', 'AI-ACT-352']) {
      expect(result.revisions[(action, listing)], matches(RegExp(r'^catalogue-stale-price:[a-f0-9]{64}$')));
    }
    expect(result.revisions.containsKey(('AI-ACT-001', null)), true);
    expect(result.revisions.containsKey(('AI-ACT-014', listing)), false);
  }, skip: priceExport.isEmpty ? 'Requires explicit isolated original-service expired-price export' : false);
  for (final action in ['AI-ACT-060', 'AI-ACT-352']) {
    test('Expired supplier price $action requires selected personal original and exact source proof', () async {
      final listing = 'listing-${'a' * 64}', proof = 'catalogue-stale-price:${'b' * 64}';
      final data = <String, Object?>{..._data(), 'revisions': [
        {'actionId': action, 'entityId': listing, 'sourceRevision': proof}]};
      final result = await _source(_Wire(() => _ok(data))).read(_context, () => true, catalogueListingIds: [listing]);
      expect(result.revisions, {(action, listing): proof});
      for (final fault in ['unselected', 'root', 'proof', 'foreign-owner', 'store']) {
        final changed = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
        final row = (changed['revisions'] as List).single as Map;
        var context = _context;
        if (fault == 'root') row['entityId'] = null;
        if (fault == 'proof') row['sourceRevision'] = 'catalogue-product:${'b' * 64}';
        if (fault == 'foreign-owner') changed['ownerKey'] = 'c' * 64;
        if (fault == 'store') {
          context = _context.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'HOST Store',
            profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: _owner));
          changed['scope'] = {'audience': 'workspace', 'storeId': 'store-one'};
          changed['ownerKey'] = sha256.convert(utf8.encode(jsonEncode(['fixture-project', 'domain-host-a', 'workspace', 'store-one']))).toString();
        }
        await expectLater(_source(_Wire(() => _ok(changed))).read(context, () => true,
          catalogueListingIds: fault == 'unselected' ? null : [listing]), throwsA(isA<AssistantModelFailure>()));
      }
    });
  }
  const restockExport = String.fromEnvironment('AI_DOMAIN_RESTOCK_SELECTION_EXPORT_PATH');
  test('Original selected Restock service and native product bind exact Unicode pack and price', () async {
    final export = jsonDecode(File(restockExport).readAsStringSync()) as Map<String, dynamic>;
    expect(export['hostOnly'], true);
    final actor = export['actor'] as Map<String, dynamic>;
    final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String,
      tenantId: null, userId: actor['uid'] as String);
    final scope = export['scope'] as Map<String, dynamic>;
    final raw = export['nativeProduct'] as Map<String, dynamic>;
    final id = raw['listingId'] as String;
    final channel = BuyV2OfferClass.values.singleWhere((v) => v.name == raw['channel']);
    final product = BuyV2Product(id: id, canonicalId: raw['canonicalProductId'] as String,
      destination: BuyV2Destination.wholesale, categoryId: 'host-rice', brand: 'HOST',
      title: raw['title'] as String, variant: raw['variant'] as String, pack: raw['pack'] as String,
      priceMinor: raw['priceMinor'] as int, unitPrice: '', badge: '', seller: raw['supplierName'] as String,
      sellerType: 'HOST labelled supplier', deliveryPromise: '', origin: '', confirmedOn: '',
      visualLabel: '', visualKind: '', storeId: raw['storeId'] as String, offerClass: channel,
      minimumOrder: raw['minimumOrder'] as int,
      publicListingIdentity: BuyV2PublicListingIdentity(listingId: id, realm: raw['realm'] as String,
        storeId: raw['storeId'] as String, skuId: raw['skuId'] as String,
        canonicalProductId: raw['canonicalProductId'] as String,
        verifiedPackId: raw['verifiedPackId'] as String, channel: channel),
      packTerms: BuyV2PackTerms(skuId: id, revision: raw['priceRevision'] as String,
        sellUnit: 'bag', sourceLabel: raw['pack'] as String, quantityStep: raw['quantityStep'] as int,
        pricingStoreId: raw['storeId'] as String, priceObservedAt: _at,
        priceValidUntil: DateTime.parse(raw['priceValidUntil'] as String)));
    expect(product.hasValidPublicListingIdentity, true);
    expect(product.hasValidPackTerms, true);
    final binding = WorkSession.workspaceAssistantRestockProductBinding(product);
    expect(binding, isNotNull);
    final context = MoolAssistantContext(accountScope: owner, authenticationRevision: 1)
      .withWorkspace(MoolAssistantWorkspace(id: scope['storeId'] as String, name: 'HOST Store',
        profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: owner));
    final gateway = AssistantDomainContextGateway(owner: owner, isCurrent: () => true,
      credentials: _Credentials(), transport: _CapacityWire(export['metadata'] as Map<String, dynamic>),
      clock: () => _at, compactStoreSelection: true);
    final snapshot = await gateway.read(context, () => true, catalogueListingIds: [id]);
    final root = snapshot.revisions[('AI-ACT-234', null)];
    expect(root, startsWith('store-restock-source:'));
    final expected = 'store-restock-product:${binding!.realm}:'
      '${sha256.convert(utf8.encode(jsonEncode([root, binding.digest])))}';
    expect(snapshot.revisions[('AI-ACT-234', id)], expected);
    expect(product.title, contains('મૂળ'));
  }, skip: restockExport.isEmpty ? 'Requires explicit isolated original-service Restock export' : false);
  test('Selected Restock metadata rejects absent root, wrong listing and malformed proof', () async {
    final id = 'listing-${'a' * 64}';
    final store = _context.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'HOST Store',
      profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: _owner));
    final data = <String, Object?>{..._data(),
      'ownerKey': sha256.convert(utf8.encode(jsonEncode(['fixture-project', 'domain-host-a', 'workspace', 'store-one']))).toString(),
      'scope': {'audience': 'workspace', 'storeId': 'store-one'},
      'revisions': [
        {'actionId': 'AI-ACT-234', 'entityId': null, 'sourceRevision': 'store-restock-source:${'b' * 64}'},
        {'actionId': 'AI-ACT-234', 'entityId': id, 'sourceRevision': 'store-restock-product:evaluation:${'c' * 64}'}]};
    expect((await _source(_Wire(() => _ok(data))).read(store, () => true,
      catalogueListingIds: [id])).revisions.length, 2);
    for (final fault in ['missing-root', 'wrong-listing', 'proof', 'realm', 'root-proof']) {
      final changed = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
      final rows = changed['revisions'] as List;
      final selected = rows.last as Map;
      if (fault == 'missing-root') rows.removeAt(0);
      if (fault == 'wrong-listing') selected['entityId'] = 'listing-${'d' * 64}';
      if (fault == 'proof') selected['sourceRevision'] = 'store-restock-product:evaluation:claimed';
      if (fault == 'realm') selected['sourceRevision'] = 'store-restock-product:unknown:${'c' * 64}';
      if (fault == 'root-proof') (rows.first as Map)['sourceRevision'] = 'store-restock-source:claimed';
      await expectLater(_source(_Wire(() => _ok(changed))).read(store, () => true,
        catalogueListingIds: [id]), throwsA(isA<AssistantModelFailure>()), reason: fault);
    }
  });
  const retainedExport = String.fromEnvironment('AI_DOMAIN_RETAINED_QUOTE_EXPORT_PATH');
  test('Original retained quote service metadata and full Unicode record retain the same mobile proof', () async {
    final export = jsonDecode(File(retainedExport).readAsStringSync()) as Map<String, dynamic>;
    expect(export['hostOnly'], true);
    final actor = export['actor'] as Map<String, dynamic>;
    final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String, tenantId: null, userId: actor['uid'] as String);
    final quote = WorkspaceBulkQuote.decode(export['head'], realm: 'evaluation', now: _at);
    expect(quote.accepted, true);
    Object? ordered(Object? value) {
      if (value is Map) {
        final keys = value.keys.cast<String>().toList()..sort();
        return {for (final key in keys) key: ordered(value[key])};
      }
      if (value is List) return value.map(ordered).toList();
      return value;
    }
    final proof = 'buyer-retained-quote:evaluation:${sha256.convert(utf8.encode(jsonEncode(ordered([
      actor['projectId'], actor['uid'], export['profileRevision'], quote.toJson()]))))}';
    final gateway = AssistantDomainContextGateway(owner: owner, isCurrent: () => true, credentials: _Credentials(),
      transport: _BackendReferenceWire(export['metadata'] as Map<String, dynamic>, retainedIds: [quote.quoteId]), clock: () => _at);
    final result = await gateway.read(MoolAssistantContext(accountScope: owner, authenticationRevision: 1), () => true,
      retainedSupplierQuoteIds: [quote.quoteId]);
    expect(result.revisions[('AI-ACT-348', quote.quoteId)], proof);
    expect(result.revisions[('AI-ACT-349', quote.quoteId)], proof);
    expect(quote.lines.single.variant, contains('મૂળ'));
  }, skip: retainedExport.isEmpty ? 'Requires explicit isolated original-service quote export' : false);
  test('Retained quote metadata requires exact selected buyer identifiers and source namespace', () async {
    final quote = 'bulk-${'a' * 64}', other = 'bulk-${'b' * 64}';
    final proof = 'buyer-retained-quote:evaluation:${'c' * 64}';
    final data = <String, Object?>{..._data(), 'revisions': [
      {'actionId': 'AI-ACT-348', 'entityId': quote, 'sourceRevision': proof},
      {'actionId': 'AI-ACT-349', 'entityId': quote, 'sourceRevision': proof}]};
    final wire = _Wire(() => _ok(data));
    final result = await _source(wire).read(_context, () => true, retainedSupplierQuoteIds: [quote]);
    expect(result.revisions, {('AI-ACT-348', quote): proof, ('AI-ACT-349', quote): proof});
    expect((wire.bodies.single['payload'] as Map)['retainedSupplierQuoteIds'], [quote]);
    for (final fault in ['missing-hint', 'foreign-hint', 'entity', 'namespace', 'realm', 'proof', 'owner']) {
      final changed = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
      final row = (changed['revisions'] as List).first as Map;
      if (fault == 'entity') row['entityId'] = null;
      if (fault == 'namespace') row['sourceRevision'] = 'buy-reference-owner:${'c' * 64}';
      if (fault == 'realm') row['sourceRevision'] = 'buyer-retained-quote:unknown:${'c' * 64}';
      if (fault == 'proof') row['sourceRevision'] = 'buyer-retained-quote:evaluation:claimed';
      if (fault == 'owner') changed['ownerKey'] = 'd' * 64;
      await expectLater(_source(_Wire(() => _ok(changed))).read(_context, () => true,
        retainedSupplierQuoteIds: fault == 'missing-hint' ? null : [fault == 'foreign-hint' ? other : quote]),
        throwsA(isA<AssistantModelFailure>()));
    }
    for (final invalid in [[quote, quote], ['bulk-short'], List.generate(501, (n) => 'bulk-${n.toRadixString(16).padLeft(64, '0')}')]) {
      final credentials = _Credentials();
      await expectLater(_source(_Wire(() => _ok(data)), credentials: credentials).read(_context, () => true,
        retainedSupplierQuoteIds: invalid), throwsA(isA<AssistantModelFailure>()));
      expect(credentials.tokens, 0);
    }
    final store = _context.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'HOST Store',
      profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: _owner));
    final credentials = _Credentials();
    await expectLater(_source(_Wire(() => _ok(data)), credentials: credentials).read(store, () => true,
      retainedSupplierQuoteIds: [quote]), throwsA(isA<AssistantModelFailure>()));
    expect(credentials.tokens, 0);
  });
  test('Clear Cart metadata requires its exact personal root proof, never a claimed Cart or Store target', () async {
    final proof = 'buy-cart-clear-owner:${'c' * 64}';
    final data = <String, Object?>{..._data(), 'revisions': [
      {'actionId': 'AI-ACT-020', 'entityId': null, 'sourceRevision': proof}]};
    expect((await _source(_Wire(() => _ok(data))).read(_context, () => true)).revisions, {('AI-ACT-020', null): proof});
    for (final fault in ['entity', 'namespace', 'proof', 'store', 'foreign-owner']) {
      final changed = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
      final row = (changed['revisions'] as List).single as Map;
      var context = _context;
      if (fault == 'entity') row['entityId'] = 'claimed-cart';
      if (fault == 'namespace') row['sourceRevision'] = 'buy-reference-owner:${'c' * 64}';
      if (fault == 'proof') row['sourceRevision'] = 'buy-cart-clear-owner:claimed';
      if (fault == 'foreign-owner') changed['ownerKey'] = 'd' * 64;
      if (fault == 'store') {
        context = _context.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'HOST Store',
          profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: _owner));
        changed['scope'] = {'audience': 'workspace', 'storeId': 'store-one'};
        changed['ownerKey'] = sha256.convert(utf8.encode(jsonEncode(['fixture-project', 'domain-host-a', 'workspace', 'store-one']))).toString();
      }
      await expectLater(_source(_Wire(() => _ok(changed))).read(context, () => true), throwsA(isA<AssistantModelFailure>()));
    }
  });
  const clearExport = String.fromEnvironment('AI_DOMAIN_CART_CLEAR_EXPORT_PATH');
  test('Original backend Clear Cart permission metadata decodes through actual mobile gateway', () async {
    final export = jsonDecode(File(clearExport).readAsStringSync()) as Map<String, dynamic>;
    expect(export['hostOnly'], true);
    final actor = export['actor'] as Map<String, dynamic>;
    final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String, tenantId: null, userId: actor['uid'] as String);
    final gateway = AssistantDomainContextGateway(owner: owner, isCurrent: () => true, credentials: _Credentials(),
      transport: _BackendReferenceWire(export['metadata'] as Map<String, dynamic>), clock: () => _at);
    final result = await gateway.read(MoolAssistantContext(accountScope: owner, authenticationRevision: 1), () => true);
    expect(result.revisions[('AI-ACT-020', null)], matches(RegExp(r'^buy-cart-clear-owner:[a-f0-9]{64}$')));
    expect(result.revisions.keys.where((key) => key.$1 == 'AI-ACT-020'), hasLength(1));
  }, skip: clearExport.isEmpty ? 'Requires explicit isolated original-backend Clear Cart metadata export' : false);
  test('Purchase reference metadata requires personal root and exact original account proof', () async {
    final proof = 'buy-reference-owner:${'a' * 64}';
    final data = <String, Object?>{..._data(), 'revisions': [
      {'actionId': 'AI-ACT-032', 'entityId': null, 'sourceRevision': proof}]};
    expect((await _source(_Wire(() => _ok(data))).read(_context, () => true)).revisions,
      {('AI-ACT-032', null): proof});
    for (final fault in ['entity', 'namespace', 'proof', 'store', 'foreign-owner']) {
      final changed = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
      final row = (changed['revisions'] as List).single as Map;
      var context = _context;
      if (fault == 'entity') row['entityId'] = 'claimed-cart';
      if (fault == 'namespace') row['sourceRevision'] = 'catalogue-search:${'a' * 64}';
      if (fault == 'proof') row['sourceRevision'] = 'buy-reference-owner:claimed';
      if (fault == 'foreign-owner') changed['ownerKey'] = 'b' * 64;
      if (fault == 'store') {
        context = _context.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'HOST Store',
          profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: _owner));
        changed['scope'] = {'audience': 'workspace', 'storeId': 'store-one'};
        changed['ownerKey'] = sha256.convert(utf8.encode(jsonEncode(['fixture-project', 'domain-host-a', 'workspace', 'store-one']))).toString();
      }
      await expectLater(_source(_Wire(() => _ok(changed))).read(context, () => true), throwsA(isA<AssistantModelFailure>()));
    }
  });
  const referenceExport = String.fromEnvironment('AI_DOMAIN_PURCHASE_REFERENCE_EXPORT_PATH');
  test('Original backend purchase reference metadata decodes through actual mobile gateway', () async {
    final export = jsonDecode(File(referenceExport).readAsStringSync()) as Map<String, dynamic>;
    expect(export['hostOnly'], true);
    final actor = export['actor'] as Map<String, dynamic>;
    final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String, tenantId: null, userId: actor['uid'] as String);
    final gateway = AssistantDomainContextGateway(owner: owner, isCurrent: () => true, credentials: _Credentials(),
      transport: _BackendReferenceWire(export['metadata'] as Map<String, dynamic>), clock: () => _at);
    final result = await gateway.read(MoolAssistantContext(accountScope: owner, authenticationRevision: 1), () => true);
    expect(result.revisions[('AI-ACT-032', null)], matches(RegExp(r'^buy-reference-owner:[a-f0-9]{64}$')));
    expect(result.revisions.keys.where((key) => key.$1 == 'AI-ACT-032'), hasLength(1));
  }, skip: referenceExport.isEmpty ? 'Requires explicit isolated original-backend metadata export' : false);
  for (final actions in [assistantStoreReportOwnerContextActions, assistantStorePublicDetailsContextActions]) {
  for (final compact in [false, true]) {
    test('Store metadata ${actions.first} preserves exact approved namespace compact$compact', () async {
      final store = _context.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'Host Store',
        profile: 'retailer-grocery', revision: 1, isStore: true, approved: true, approvalAccountScope: _owner));
      final proof = '${actions.contains('AI-ACT-320') ? 'store-public-details' : 'store-report-owner'}:evaluation:${'a' * 64}';
      final data = <String, Object?>{..._data(),
        'ownerKey': sha256.convert(utf8.encode(jsonEncode(['fixture-project', 'domain-host-a', 'workspace', 'store-one']))).toString(),
        'scope': {'audience': 'workspace', 'storeId': 'store-one'},
        'revisions': compact ? <Object?>[] : [for (final action in actions)
          {'actionId': action, 'entityId': null, 'sourceRevision': proof}],
        if (compact) 'nativeSelection': {'version': 1, 'fingerprint': 'b' * 64, 'groups': [
          {'entityId': null, 'sourceRevision': proof, 'actionIds': actions.toList()}]}};
      final result = await _source(_Wire(() => _ok(data)), compact: compact).read(store, () => true);
      expect(result.revisions, {for (final action in actions) (action, null): proof});
      for (final fault in ['entity', 'realm', 'proof', 'personal', 'unapproved']) {
        final changed = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
        final rows = compact ? changed['nativeSelection']['groups'] as List : changed['revisions'] as List;
        final row = rows.first as Map;
        if (fault == 'entity') row['entityId'] = 'invented-report';
        if (fault == 'realm') row['sourceRevision'] = '${actions.contains('AI-ACT-320') ? 'store-public-details' : 'store-report-owner'}:unknown:${'a' * 64}';
        if (fault == 'proof') row['sourceRevision'] = 'store-order-board-owner:${'a' * 64}';
        final context = fault == 'personal' ? _context : fault == 'unapproved'
          ? _context.withWorkspace(const MoolAssistantWorkspace(id: 'store-one', name: 'Host Store',
              profile: 'retailer-grocery', revision: 1, isStore: true, approved: false, approvalAccountScope: _owner)) : store;
        await expectLater(_source(_Wire(() => _ok(changed)), compact: compact).read(context, () => true),
          throwsA(isA<AssistantModelFailure>()));
      }
    });
  }
  }
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
  const detailsExport = String.fromEnvironment('AI_DOMAIN_STORE_DETAILS_EXPORT_PATH');
  test('Actual original public-details metadata crosses the real mobile decoder without private draft values', () async {
    final export = jsonDecode(File(detailsExport).readAsStringSync()) as Map<String, dynamic>;
    expect(export['hostOnly'], true);
    final actor = export['actor'] as Map;
    final owner = (environment: 'firebase-service', projectId: actor['projectId'] as String, tenantId: null, userId: actor['uid'] as String);
    final envelope = export['metadata'] as Map<String, dynamic>, scope = export['scope'] as Map;
    final data = envelope['data'] as Map;
    final context = MoolAssistantContext(accountScope: owner, authenticationRevision: 1).withWorkspace(
      MoolAssistantWorkspace(id: scope['storeId'] as String, name: 'HOST original Store', profile: 'retailer-grocery', revision: 1,
        isStore: true, approved: true, approvalAccountScope: owner));
    final source = AssistantDomainContextGateway(owner: owner, isCurrent: () => true, credentials: _Credentials(),
      transport: _CapacityWire(envelope), compactStoreSelection: true,
      clock: () => DateTime.parse(data['validUntil'] as String).subtract(const Duration(seconds: 30)));
    addTearDown(source.dispose);
    final snapshot = await source.read(context, () => true);
    final proofs = snapshot.revisions.entries.where((entry) => assistantStorePublicDetailsContextActions.contains(entry.key.$1)).toList();
    expect(proofs.length, 2);
    for (final proof in proofs) {
      expect(proof.key.$2, isNull);
      expect(proof.value, matches(r'^store-public-details:evaluation:[a-f0-9]{64}$'));
    }
    expect(snapshot.revisions.keys.any((key) => const {'AI-ACT-324', 'AI-ACT-326'}.contains(key.$1)), isFalse);
    expect(jsonEncode(envelope).contains((export['details'] as Map)['details']['street'] as String), isFalse);
  }, skip: detailsExport.isEmpty ? 'Requires explicit isolated original-service public-details export' : false);
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
        {'actionId': action, 'entityId': null, 'sourceRevision': const {'AI-ACT-229', 'AI-ACT-369'}.contains(action)
          ? 'store-master-${action == 'AI-ACT-229' ? 'search' : 'scan'}-owner:evaluation:${'a' * 64}' : assistantStoreSupplierDraftContextActions.contains(action)
          ? 'store-supplier-draft-owner:${'a' * 64}' : assistantStorePurchaseRootContextActions.contains(action)
          ? 'store-purchase-root-owner:${'a' * 64}' : assistantStoreOrderBoardContextActions.contains(action)
          ? 'store-order-board-owner:${'a' * 64}' : assistantStoreReportOwnerContextActions.contains(action)
          ? 'store-report-owner:evaluation:${'a' * 64}' : assistantStorePublicDetailsContextActions.contains(action)
          ? 'store-public-details:evaluation:${'a' * 64}' : assistantStoreRestockOwnerContextActions.contains(action)
          ? 'store-restock-source:${'a' * 64}' : 'native-owned-defaults-owner-proof'},
      ]};
    final value = await _source(_Wire(() => _ok(data))).read(store, () => true);
    expect(value.revisions.keys.single, (action, null));
    if (const {'AI-ACT-229', 'AI-ACT-369'}.contains(action)) {
      final other = action == 'AI-ACT-229' ? 'scan' : 'search';
      for (final proof in ['store-master-$other-owner:evaluation:${'a' * 64}',
        'store-master-search-owner:foreign:${'a' * 64}', 'store-master-search-owner:evaluation:invalid']) {
        final invalid = {...data, 'revisions': [{'actionId': action, 'entityId': null, 'sourceRevision': proof}]};
        await expectLater(_source(_Wire(() => _ok(invalid))).read(store, () => true), throwsA(isA<AssistantModelFailure>()));
      }
    }
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
      {'actionId': action, 'entityId': id, 'sourceRevision': const {'AI-ACT-060', 'AI-ACT-352'}.contains(action)
        ? 'catalogue-stale-price:${'b' * 64}' : 'catalogue-product:original'},
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
  test('AGG02 context read negotiates only the owned typed preview proof', () async {
    const context=MoolAssistantContext(accountScope:_owner,authenticationRevision:1,workspaceId:'store-one',
      workspaceRevision:1,storeWorkspace:true,workspaceApproved:true);
    final proof='store-preview-originals:evaluation:${'a'*64}';
    final data={..._data(),'scope':{'audience':'workspace','storeId':'store-one'},
      'ownerKey':sha256.convert(utf8.encode(jsonEncode(['fixture-project','domain-host-a','workspace','store-one']))).toString(),
      'revisions':[{'actionId':'AI-ACT-230','entityId':'sku-one','sourceRevision':proof}]};
    final wire=_Wire(()=>_ok(data));
    final source=AssistantDomainContextGateway(owner:_owner,isCurrent:()=>true,credentials:_Credentials(),transport:wire,
      clock:()=>_at,productPreviewSupported:true);
    final snapshot=await source.read(context,()=>true);
    expect(snapshot.nativeProductPreviewVersion,1);
    expect(snapshot.revisions,{('AI-ACT-230','sku-one'):proof});
    expect((wire.bodies.single['payload'] as Map)['nativeProductPreviewVersion'],1);
    data['revisions']=[{'actionId':'AI-ACT-230','entityId':'sku-one','sourceRevision':'store-owned-product:evaluation:1:${'a'*64}'}];
    await expectLater(source.read(context,()=>true),throwsA(isA<AssistantModelFailure>()));
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

class _BackendReferenceWire implements SocialContentTransport {
  _BackendReferenceWire(this.metadata, {this.retainedIds, this.listingIds});
  final Map<String, dynamic> metadata;
  final List<String>? retainedIds;
  final List<String>? listingIds;
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers,
      required Map<String, Object?> body}) async {
    expect(endpoint.path, '/moolSocialAssistantContext');
    expect(body, {'operation': 'read', 'payload': {'scope': {'audience': 'personal', 'storeId': null},
      if (retainedIds != null) 'retainedSupplierQuoteIds': retainedIds,
      if (listingIds != null) 'catalogueListingIds': listingIds}});
    return SocialContentResponse(statusCode: 200, body: jsonEncode(metadata));
  }
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
