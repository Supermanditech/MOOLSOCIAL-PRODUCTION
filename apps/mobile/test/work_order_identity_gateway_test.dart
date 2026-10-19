import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_order_identity_gateway.dart';

// Isolated contract fixtures; no native storage, real order or provider calls.
Map<String, dynamic> response({String role = 'buyer'}) {
  final original = {
    'currency': 'INR',
    'amountMinor': 124000,
    'lines': [
      {
        'lineId': 'atta',
        'name': 'Aashirvaad Whole Wheat Atta',
        'detail': '1 kg',
        'quantity': 2,
        'amountMinor': 11000,
      },
    ],
  };
  final fingerprint = sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'storeId': 'workspace-1',
            'orderId': 'MS-2841',
            'original': original,
          }),
        ),
      )
      .toString();
  return {
    'schemaVersion': 1,
    'viewerRole': role,
    'viewerUserId': role == 'buyer' ? 'buyer-1' : 'owner-1',
    'storeId': 'workspace-1',
    'orderId': 'MS-2841',
    'state': 'linked',
    'identity': {
      'buyerId': 'customer-1',
      'purchaseId': 'purchase-1',
      'sourceRevision': 'final-1',
      'serviceRevision': 'a' * 64,
      'originalFingerprint': fingerprint,
      'original': original,
    },
  };
}

class Credentials implements SocialContentCredentials {
  Completer<String>? token;
  final modes = <SocialAppCheckTokenMode>[];
  @override
  Future<String> firebaseIdToken() async =>
      token == null ? 'host-token' : token!.future;
  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    modes.add(mode);
    return 'host-appcheck';
  }
}

class Transport implements SocialContentTransport {
  Map<String, dynamic> data = response();
  Map<String, Object?>? sent;
  Completer<void>? pending;
  int status = 200, calls = 0;
  bool fail = false;
  Map<String, dynamic> Function(Map<String, Object?> body)? respond;
  final requests = <Map<String, Object?>>[];
  @override
  Future<SocialContentResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    calls++;
    requests.add(Map.of(body));
    sent = body;
    await pending?.future;
    if (fail) throw StateError('host network failure');
    return SocialContentResponse(
      statusCode: status,
      body: jsonEncode({'ok': true, 'data': respond?.call(body) ?? data}),
    );
  }
}

void main() {
  for (final role in WorkspaceOrderIdentityRole.values) {
    for (final allNull in [false, true]) {
      test('LF-LISTING strict originals retain version6 and nullable provenance ${role.name} $allNull', () async {
        final data = publicListingPurchaseResponse(role: role.name, allNull: allNull), wire = Transport()..data = data;
        final result = await projectionGateway(wire, account: role == WorkspaceOrderIdentityRole.buyer ? 'buyer-1' : 'owner-1').readPurchaseProjection(
          role: role, realm: 'evaluation', purchaseId: data['purchaseId'], storeId: role == WorkspaceOrderIdentityRole.seller ? 'store-one' : null,
          orderId: role == WorkspaceOrderIdentityRole.seller ? data['orders'][0]['orderId'] : null);
        expect(result, isNotNull); final order = result!.orders.single;
        expect(order.factsVersion, 6);
        expect(order.lines.single.toJson(), data['orders'][0]['original']['lines'][0]);
        expect(order.lines.single.toJson().containsKey('publicListing'), isTrue);
      });
    }
  }
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'missing': (d) => d['orders'][0]['original']['lines'][0].remove('publicListing'),
    'realm': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['realm'] = 'production',
    'Store': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['storeId'] = 'other-store',
    'SKU': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['skuId'] = 'other-sku',
    'canonical': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['canonicalProductId'] = 'other-product',
    'pack': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['verifiedPackId'] = 'other-pack',
    'stable ID': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['listingId'] = 'listing-${'a' * 64}',
    'extra field': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['purchaseCost'] = 50,
    'inherited Schedule': (d) => d['orders'][0]['original']['lines'][0].remove('scheduledFulfilment'),
    'old marker': (d) {d['schemaVersion'] = 5; d['orders'][0]['factsVersion'] = 5;},
  }.entries) {
    test('LF-LISTING rejects rehashed ${fault.key} rather than substituting current catalogue identity', () async {
      final data = publicListingPurchaseResponse(); fault.value(data); rehashPurchaseOrder(data['orders'][0]);
      expect(await projectionGateway(Transport()..data = data).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: data['purchaseId']), isNull);
    });
  }
  Map<String, dynamic> completionResponse({String role = 'buyer', bool supplied = true}) {
    final original = operationalResponse(role: role);
    return {for (final key in const ['schemaVersion', 'realm', 'authNamespace', 'viewerRole', 'viewerUserId',
      'purchaseId', 'storeId', 'orderId', 'sourceRevision', 'originalFingerprint']) key: original[key],
      'state': supplied ? 'recorded' : 'not_supplied',
      'completion': supplied ? {'id': 'completion-${'a' * 64}', 'revision': 'completion-v1', 'outcome': 'delivered',
        'occurredAt': '2026-10-16T12:01:00.000Z', 'recordedAt': '2026-10-16T12:01:01.000Z'} : null};
  }
  for (final role in WorkspaceOrderIdentityRole.values) {
    for (final supplied in [false, true]) {
      test('LF-COMPLETE strict ${role.name} projection distinguishes absent evidence supplied=$supplied', () async {
        final wire = Transport()..data = completionResponse(role: role.name, supplied: supplied);
        final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire,
          account: role == WorkspaceOrderIdentityRole.buyer ? 'buyer-1' : 'owner-1'), now: () => DateTime.utc(2026, 10, 19));
        final result = await gateway.readCompletion(role: role, realm: 'evaluation', reference: operationalReference());
        expect(result, isNotNull); expect(result!.reference.orderId, operationalReference().orderId);
        expect(result.completion != null, supplied);
        if (supplied) {expect(result.completion!.outcome, 'delivered'); expect(result.completion!.revision, 'completion-v1');}
        expect(wire.sent!['operation'], role == WorkspaceOrderIdentityRole.buyer ? 'readBuyerOrderCompletion' : 'readStoreOrderCompletion');
      });
    }
  }
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'schema type': (d) => d['schemaVersion'] = 1.0,
    'realm': (d) => d['realm'] = 'production',
    'namespace': (d) => d['authNamespace'] = 'tenant-other',
    'viewer': (d) => d['viewerUserId'] = 'another-account',
    'role': (d) => d['viewerRole'] = 'seller',
    'purchase': (d) => d['purchaseId'] = 'another-purchase',
    'Store': (d) => d['storeId'] = 'another-store',
    'order': (d) => d['orderId'] = 'another-order',
    'fingerprint': (d) => d['originalFingerprint'] = 'b' * 64,
    'source revision': (d) => d['sourceRevision'] = 'another-original',
    'unknown state': (d) => d['state'] = 'delivered',
    'missing evidence': (d) => d['completion'] = null,
    'absent with evidence': (d) => d['state'] = 'not_supplied',
    'unknown outcome': (d) => d['completion']['outcome'] = 'ready',
    'unknown ID': (d) => d['completion']['id'] = 'owner-confirmed',
    'blank revision': (d) => d['completion']['revision'] = '',
    'future': (d) => d['completion']['recordedAt'] = '2099-10-16T12:01:01.000Z',
    'reversed dates': (d) => d['completion']['recordedAt'] = '2026-10-16T12:00:00.000Z',
    'time precision': (d) => d['completion']['occurredAt'] = '2026-10-16T12:01:00.000001Z',
    'private proof': (d) => d['completion']['proof'] = 'private-provider-proof',
    'invented payment': (d) => d['paymentVerified'] = true,
  }.entries) {
    test('LF-COMPLETE rejects ${fault.key}', () async {
      final data = completionResponse(); fault.value(data);
      final wire = Transport()..data = data;
      expect(await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire)).readCompletion(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: operationalReference()), isNull);
    });
  }
  test('LF-COMPLETE retired A B A response cannot enter the replacement session', () async {
    Object? generation = Object();
    final wire = Transport()..data = completionResponse()..pending = Completer<void>();
    final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, lifetime: () => generation));
    final pending = gateway.readCompletion(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: operationalReference());
    for (var i = 0; i < 100 && wire.calls == 0; i++) {await Future<void>.delayed(Duration.zero);}
    expect(wire.calls, 1); generation = Object(); generation = Object();
    wire.pending!.complete(); expect(await pending, isNull);
    expect(await gateway.readCompletion(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: operationalReference()), isNull);
    expect(wire.calls, 1);
  });
  if (Platform.environment['LF_LISTING_PROJECTION_LOG'] case final path?) {
    test('LF-LISTING actual local producer crosses both original readers and operational decoder', () async {
      const marker = 'LF_LISTING_PROJECTION=';
      final rows = File(path).readAsLinesSync().where((line) => line.contains(marker)).toList();
      expect(rows, hasLength(2));
      for (final row in rows) {
        final payload = (jsonDecode(row.substring(row.indexOf(marker) + marker.length)) as Map).cast<String, dynamic>();
        for (final role in WorkspaceOrderIdentityRole.values) {
          final data = (payload[role.name] as Map).cast<String, dynamic>();
          final firstOrder = data['orders'][0];
          final result = await projectionGateway(Transport()..data = data, account: data['viewerUserId']).readPurchaseProjection(
            role: role, realm: 'evaluation', purchaseId: data['purchaseId'],
            storeId: role == WorkspaceOrderIdentityRole.seller ? firstOrder['storeId'] : null,
            orderId: role == WorkspaceOrderIdentityRole.seller ? firstOrder['orderId'] : null);
          expect(result, isNotNull);
          for (final order in result!.orders) {
            final raw = (data['orders'] as List).singleWhere((r) => r['orderId'] == order.orderId);
            expect(order.factsVersion, 6);
            expect(order.lines.map((line) => line.toJson()).toList(), raw['original']['lines']);
          }
        }
        final data = (payload['operational'] as Map).cast<String, dynamic>();
        final ref = WorkspacePurchaseReference(purchaseId: data['purchaseId'], storeId: data['storeId'],
          orderId: data['orderId'], sourceRevision: data['sourceRevision'], originalFingerprint: data['originalFingerprint']);
        final result = await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(Transport()..data = data,
          account: data['viewerUserId'])).read(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: ref);
        expect(result, isNotNull);
        expect(result!.original.factsVersion, 6);
        expect(result.original.lines.map((line) => line.toJson()).toList(), data['original']['lines']);
      }
    });
  }
  if (Platform.environment['LF_COMPLETION_PROJECTION_LOG'] case final path?) {
    test('LF-COMPLETE actual local completion producer crosses strict Dart readback for both roles and fulfilments', () async {
      const marker = 'LF_COMPLETION_PROJECTION=';
      final rows = File(path).readAsLinesSync().where((line) => line.contains(marker)).toList();
      expect(rows, hasLength(2)); final outcomes = <String>{};
      for (final row in rows) {
        final payload = (jsonDecode(row.substring(row.indexOf(marker) + marker.length)) as Map).cast<String, dynamic>();
        for (final role in WorkspaceOrderIdentityRole.values) {
          final data = (payload[role == WorkspaceOrderIdentityRole.buyer ? 'buyer' : 'seller'] as Map).cast<String, dynamic>();
          final wire = Transport()..data = data;
          final ref = WorkspacePurchaseReference(purchaseId: data['purchaseId'], storeId: data['storeId'],
            orderId: data['orderId'], sourceRevision: data['sourceRevision'], originalFingerprint: data['originalFingerprint']);
          final result = await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: data['viewerUserId'])).readCompletion(
            role: role, realm: 'evaluation', reference: ref);
          expect(result, isNotNull); expect(result!.completion, isNotNull);
          outcomes.add(result.completion!.outcome);
          expect(result.completion!.id, data['completion']['id']);
        }
      }
      expect(outcomes, {'delivered', 'collected'});
    });
  }
  if (Platform.environment['LF_SCHEDULE_PROJECTION_LOG'] case final path?) {
    test('LF-SCHEDULE actual emulator originals preserve exact requested context across Dart', () async {
      const marker = 'LF_SCHEDULE_PROJECTION=';
      final captured = File(path).readAsLinesSync().singleWhere((line) => line.contains(marker));
      final data = (jsonDecode(captured.split(marker).last) as Map).cast<String, dynamic>();
      final wire = Transport()..data = data;
      final result = await projectionGateway(wire, account: data['viewerUserId'] as String).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: data['purchaseId'] as String);
      expect(result, isNotNull);
      var selected = 0, unselected = 0;
      for (final order in result!.orders) {
        expect(order.factsVersion, 5);
        final raw = (data['orders'] as List).singleWhere((row) => row['orderId'] == order.orderId);
        for (final line in order.lines) {
          final original = (raw['original']['lines'] as List).singleWhere((row) => row['lineId'] == line.lineId);
          expect(line.toJson(), original);
          expect(line.hasScheduledFulfilmentSnapshot, isTrue);
          if (line.scheduledFulfilment == null) { unselected++; } else {
            selected++;
            expect(line.scheduledFulfilment!.startsAt.microsecond, 456);
            expect(line.scheduledFulfilment!.listing.storeId, order.storeId);
            final copy = line.scheduledFulfilment!.toJson();
            copy['slotId'] = 'later-mutable-feed';
            expect(line.scheduledFulfilment!.slotId, 'slot-original-one');
          }
        }
      }
      expect(selected, 1); expect(unselected, 2);
    });
  }
  test('LF-SCHEDULE all-null originals preserve new-version presence while legacy stays unknown', () async {
    final wire = Transport()..data = scheduledPurchaseResponse(selected: false);
    final gateway = projectionGateway(wire);
    final result = (await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'))!.orders.single;
    expect(result.factsVersion, 5);
    expect(result.lines.single.hasScheduledFulfilmentSnapshot, isTrue);
    expect(result.lines.single.toJson().containsKey('scheduledFulfilment'), isTrue);
    expect(result.lines.single.scheduledFulfilment, isNull);
    wire.data = variantPurchaseResponse();
    final legacy = (await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'))!.orders.single;
    expect(legacy.factsVersion, 4);
    expect(legacy.lines.single.hasScheduledFulfilmentSnapshot, isFalse);
    expect(legacy.lines.single.toJson().containsKey('scheduledFulfilment'), isFalse);
  });
  for (final dates in [
    ('2026-10-15T23:59:59.123456Z', '2026-10-15T23:59:59.123457Z'),
    ('2026-10-15T23:59:59.123Z', '2026-10-16T00:00:00.000Z'),
    ('0000-02-29T23:59:59.000001Z', '0000-03-01T00:00:00.000Z'),
    ('-0001-01-01T00:00:00.000001Z', '-0001-01-01T00:00:00.000002Z'),
    ('+010000-01-01T00:00:00.123456Z', '+010000-01-01T00:00:00.123457Z'),
    ('+275760-09-12T23:59:59.999999Z', '+275760-09-13T00:00:00.000Z'),
  ]) {
    test('LF-SCHEDULE canonical microsecond range remains exact ${dates.$1}', () async {
      final data = scheduledPurchaseResponse(), order = data['orders'][0];
      final selected = order['original']['lines'][0]['scheduledFulfilment'];
      selected['startsAt'] = dates.$1; selected['endsAt'] = dates.$2;
      rehashPurchaseOrder(order as Map<String, dynamic>);
      final wire = Transport()..data = data;
      final result = await projectionGateway(wire).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: 'purchase-v2');
      expect(result, isNotNull);
      expect(result!.orders.single.lines.single.scheduledFulfilment!.toJson(), selected);
    });
  }
  for (final fault in ['missing', 'boolean', 'array', 'object', 'version', 'method', 'nested-version', 'realm', 'store', 'sku', 'product', 'pack', 'listing', 'channel', 'revision', 'location', 'slot', 'extra', 'invalid-day', 'invalid-hour', 'offset', 'precision', 'redundant-zero', 'equal', 'micro-before', 'range-overflow', 'old-version', 'mixed-version']) {
    test('LF-SCHEDULE rejects $fault even with recomputed original hash', () async {
      final data = scheduledPurchaseResponse(), order = data['orders'][0];
      final line = order['original']['lines'][0], s = line['scheduledFulfilment'];
      if (fault == 'missing') line.remove('scheduledFulfilment');
      if (fault == 'boolean') line['scheduledFulfilment'] = false;
      if (fault == 'array') line['scheduledFulfilment'] = [];
      if (fault == 'object') line['scheduledFulfilment'] = {};
      if (fault == 'version') s['schemaVersion'] = true;
      if (fault == 'method') s['method'] = 'quick';
      if (fault == 'nested-version') s['listing']['schemaVersion'] = 2;
      if (fault == 'realm') s['listing']['realm'] = 'production';
      if (fault == 'store') s['listing']['storeId'] = 'other-store';
      if (fault == 'sku') s['listing']['skuId'] = 'other-sku';
      if (fault == 'product') s['listing']['canonicalProductId'] = 'other-product';
      if (fault == 'pack') s['listing']['verifiedPackId'] = 'other-pack';
      if (fault == 'listing') s['listing']['listingId'] = 'made-up';
      if (fault == 'channel') s['listing']['channel'] = 'unknown';
      if (fault == 'revision') s['sourceRevision'] = ' ';
      if (fault == 'location') s.remove('locationKey');
      if (fault == 'slot') s['slotId'] = null;
      if (fault == 'extra') s['booked'] = true;
      if (fault == 'invalid-day') s['startsAt'] = '2026-02-30T00:00:00.000Z';
      if (fault == 'invalid-hour') s['startsAt'] = '2026-10-15T24:00:00.000Z';
      if (fault == 'offset') s['startsAt'] = '2026-10-15T23:59:59.123456+00:00';
      if (fault == 'precision') s['startsAt'] = '2026-10-15T23:59:59.1234567Z';
      if (fault == 'redundant-zero') s['startsAt'] = '2026-10-15T23:59:59.123000Z';
      if (fault == 'equal') s['endsAt'] = s['startsAt'];
      if (fault == 'micro-before') s['endsAt'] = '2026-10-15T23:59:59.123455Z';
      if (fault == 'range-overflow') {s['startsAt'] = '+275760-09-12T23:59:59.999999Z'; s['endsAt'] = '+275760-09-13T00:00:00.000001Z';}
      if (fault == 'old-version') {data['schemaVersion'] = 4; order['factsVersion'] = 4;}
      if (fault == 'mixed-version') data['schemaVersion'] = 4;
      rehashPurchaseOrder(order as Map<String, dynamic>);
      final wire = Transport()..data = data;
      expect(await projectionGateway(wire).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: 'purchase-v2'), isNull);
    });
  }
  test('LF-SCHEDULE changing a requested slot cannot reuse the original fingerprint', () async {
    final data = scheduledPurchaseResponse();
    data['orders'][0]['original']['lines'][0]['scheduledFulfilment']['slotId'] = 'changed-slot';
    final wire = Transport()..data = data;
    expect(await projectionGateway(wire).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'), isNull);
  });
  test('LF-SCHEDULE original consumes exact supplied desired window without current eligibility', () async {
    final wire = Transport()..data = scheduledPurchaseResponse();
    final result = await projectionGateway(wire).readPurchaseProjection(
      role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: 'purchase-v2');
    expect(result, isNotNull);
    expect(result!.orders.single.factsVersion, 5);
    expect((result.orders.single.lines.single.toJson()['scheduledFulfilment'] as Map)['startsAt'], '2026-10-15T23:59:59.123456Z');
  });
  if (Platform.environment['LF_VARIANT_PROJECTION_LOG'] case final path?) {
    test('LF-VARIANT actual emulator originals cross the strict Dart boundary with immutable descriptions', () async {
      const marker = 'LF_VARIANT_PROJECTION=';
      final captured = File(path).readAsLinesSync().singleWhere((line) => line.contains(marker));
      final data = (jsonDecode(captured.split(marker).last) as Map).cast<String, dynamic>();
      final wire = Transport()..data = data;
      final result = await projectionGateway(wire, account: data['viewerUserId'] as String).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: data['purchaseId'] as String);
      expect(result, isNotNull);
      expect(result!.orders, hasLength(2));
      final variants = <String?>[];
      for (final order in result.orders) {
        expect(order.factsVersion, 4);
        final source = (data['orders'] as List).singleWhere((raw) => raw['orderId'] == order.orderId);
        for (final line in order.lines) {
          final raw = (source['original']['lines'] as List).singleWhere((row) => row['lineId'] == line.lineId);
          expect(line.toJson(), raw);
          variants.add(line.variant);
          raw['variant'] = 'Later catalogue text';
          expect(line.variant, isNot('Later catalogue text'));
        }
      }
      expect(variants, unorderedEquals(['गुलाबी\n128 GB', 'Blue · 512 GB', '']));
    });
  }
  for (final variant in ['', 'गुलाबी\n128 GB', 'Pink\t128 GB', 'x' * 240]) {
    test('LF-VARIANT valid optional original text remains exact ${variant.length}', () async {
      final wire = Transport()..data = variantPurchaseResponse(variant: variant);
      final result = await projectionGateway(wire).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: 'purchase-v2');
      expect(result!.orders.single.lines.single.variant, variant);
      expect(result.orders.single.factsVersion, 4);
    });
  }
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'missing': (d) => d['orders'][0]['original']['lines'][0].remove('variant'),
    'null': (d) => d['orders'][0]['original']['lines'][0]['variant'] = null,
    'boolean': (d) => d['orders'][0]['original']['lines'][0]['variant'] = false,
    'array': (d) => d['orders'][0]['original']['lines'][0]['variant'] = ['Pink'],
    'object': (d) => d['orders'][0]['original']['lines'][0]['variant'] = {'label': 'Pink'},
    'outer whitespace': (d) => d['orders'][0]['original']['lines'][0]['variant'] = ' Pink',
    'whitespace': (d) => d['orders'][0]['original']['lines'][0]['variant'] = '\n',
    'control': (d) => d['orders'][0]['original']['lines'][0]['variant'] = 'Pink\u0000',
    'oversize': (d) => d['orders'][0]['original']['lines'][0]['variant'] = 'x' * 241,
    'legacy downgrade': (d) {d['schemaVersion'] = 3; d['orders'][0]['factsVersion'] = 3;},
    'mixed versions': (d) => d['schemaVersion'] = 3,
    'missing benefits': (d) => d['orders'][0]['original'].remove('benefitAttribution'),
  }.entries) {
    test('LF-VARIANT rejects ${fault.key} even with recomputed original hash', () async {
      final data = (jsonDecode(jsonEncode(variantPurchaseResponse())) as Map).cast<String, dynamic>(); fault.value(data);
      rehashPurchaseOrder(data['orders'][0] as Map<String, dynamic>);
      final wire = Transport()..data = data;
      expect(await projectionGateway(wire).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: 'purchase-v2'), isNull);
    });
  }
  test('LF-VARIANT supplied variant cannot change beneath the original fingerprint', () async {
    final data = variantPurchaseResponse(); data['orders'][0]['original']['lines'][0]['variant'] = 'Blue · 512 GB';
    final wire = Transport()..data = data;
    expect(await projectionGateway(wire).readPurchaseProjection(
      role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: 'purchase-v2'), isNull);
  });
  test('LF-VARIANT original purchased descriptions decode without current catalogue lookup', () async {
    final wire = Transport()..data = variantPurchaseResponse();
    final result = await projectionGateway(wire).readPurchaseProjection(
      role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: 'purchase-v2');
    expect(result, isNotNull);
    expect(result!.orders.single.lines.single.toJson()['variant'], 'Pink · 128 GB');
    expect(result.orders.single.factsVersion, 4);
  });
  if (Platform.environment['LF_ATTR_PROJECTION_LOG'] case final path?) {
    test('LF-ATTR actual emulator response crosses the strict Dart fingerprint boundary', () async {
      const marker = 'LF_ATTR_PROJECTION=';
      final row = File(path).readAsLinesSync().singleWhere((line) => line.contains(marker));
      final data = (jsonDecode(row.substring(row.indexOf(marker) + marker.length)) as Map).cast<String, dynamic>();
      final wire = Transport()..data = data;
      final result = await projectionGateway(wire, account: data['viewerUserId'] as String).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: data['purchaseId'] as String);
      expect(result, isNotNull); expect(result!.orders, hasLength(2));
      for (final order in result.orders) {
        final original = (data['orders'] as List).singleWhere((raw) => raw['orderId'] == order.orderId);
        expect(order.benefitAttribution!.toJson(), original['original']['benefitAttribution']);
        expect(order.originalFingerprint, original['originalFingerprint']);
      }
    });
  }
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'missing attribution': (d) => d['orders'][0]['original'].remove('benefitAttribution'),
    'null attribution': (d) => d['orders'][0]['original']['benefitAttribution'] = null,
    'unknown attribution version': (d) => d['orders'][0]['original']['benefitAttribution']['schemaVersion'] = 2,
    'unlabelled cashback basis': (d) => d['orders'][0]['original']['benefitAttribution']['components'][1]['amountBasis'] = 'applied',
    'discount basis': (d) => d['orders'][0]['original']['benefitAttribution']['components'][0]['amountBasis'] = 'quoted',
    'cross-line allocation': (d) => d['orders'][0]['original']['benefitAttribution']['components'][0]['allocations'][0]['lineId'] = 'foreign-line',
    'fractional paise': (d) => d['orders'][0]['original']['benefitAttribution']['components'][0]['amountMinor'] = 51.5,
    'negative paise': (d) => d['orders'][0]['original']['benefitAttribution']['components'][0]['amountMinor'] = -1,
    'inconsistent component sum': (d) => d['orders'][0]['original']['benefitAttribution']['components'][0]['allocations'][0]['amountMinor'] = 50,
    'extra claimed payment': (d) => d['orders'][0]['original']['benefitAttribution']['components'][1]['paid'] = true,
    'legacy downgrade': (d) {d['schemaVersion'] = 2; d['orders'][0]['factsVersion'] = 2;},
    'contradictory envelope version': (d) => d['schemaVersion'] = 2,
  }.entries) {
    test('LF-ATTR rejects ${fault.key} even with a recomputed untrusted envelope hash', () async {
      final data = (jsonDecode(jsonEncode(attributedPurchaseResponse())) as Map).cast<String, dynamic>();
      fault.value(data);
      rehashPurchaseOrder(data['orders'][0] as Map<String, dynamic>);
      final wire = Transport()..data = data;
      expect(await projectionGateway(wire).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: 'purchase-v2'), isNull);
    });
  }
  for (final marker in [null, 2, true, 3.0]) {
    test('LF-ATTR invalid operational original version cannot silently downgrade $marker', () async {
      final raw = attributedOperationalResponse()..['originalFactsVersion'] = marker;
      final order = attributedPurchaseResponse()['orders'][0];
      final reference = WorkspacePurchaseReference(purchaseId: 'purchase-v2', storeId: 'store-one', orderId: 'order-v2',
        sourceRevision: 'revision-1', originalFingerprint: order['originalFingerprint']);
      final wire = Transport()..data = raw;
      expect(await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire)).read(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference), isNull);
    });
  }
  test('LF-ATTR known none and unknown legacy remain distinct and immutable', () async {
    final wire = Transport()..data = attributedPurchaseResponse(empty: true);
    final gateway = projectionGateway(wire);
    final known = (await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'))!;
    expect(known.orders.single.benefitAttribution!.components, isEmpty);
    expect(() => known.orders.single.benefitAttribution!.components.clear(), throwsUnsupportedError);
    wire.data = purchaseResponse();
    final legacy = (await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'))!;
    expect(legacy.orders.single.benefitAttribution, isNull);
    wire.data = attributedPurchaseResponse();
    final supplied = (await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'))!;
    expect(() => supplied.orders.single.benefitAttribution!.components.first.allocations.clear(), throwsUnsupportedError);
  });
  for (final role in ['buyer', 'seller']) {
    test('LF-SCHEDULE operational $role readback retains only requested context', () async {
      final raw = scheduledOperationalResponse(role: role);
      final reference = WorkspacePurchaseReference(purchaseId: 'purchase-v2', storeId: 'store-one', orderId: 'order-v2',
        sourceRevision: 'revision-1', originalFingerprint: raw['originalFingerprint']);
      final wire = Transport()..data = raw;
      final result = await AuthenticatedWorkspaceOrderOperationsGateway(
        projectionGateway(wire, account: role == 'buyer' ? 'buyer-1' : 'owner-1')).read(
          role: role == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation', reference: reference);
      expect(result, isNotNull);
      expect(result!.original.factsVersion, 5);
      expect(result.original.lines.single.scheduledFulfilment!.slotId, 'slot-original-one');
      expect(result.original.totals['totalMinor'], 10015);
    });
    test('LF-VARIANT operational $role consumer preserves exact original variant', () async {
      final raw = variantOperationalResponse(role: role);
      final reference = WorkspacePurchaseReference(purchaseId: 'purchase-v2', storeId: 'store-one', orderId: 'order-v2',
        sourceRevision: 'revision-1', originalFingerprint: raw['originalFingerprint']);
      final wire = Transport()..data = raw;
      final result = await AuthenticatedWorkspaceOrderOperationsGateway(
        projectionGateway(wire, account: role == 'buyer' ? 'buyer-1' : 'owner-1')).read(
          role: role == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation', reference: reference);
      expect(result, isNotNull);
      expect(result!.original.lines.single.variant, 'Pink · 128 GB');
      expect(result.original.factsVersion, 4);
      expect(result.original.totals['totalMinor'], 10015);
    });
    test('LF-ATTR original $role consumer admits source supplied attribution without changing money', () async {
      final wire = Transport()..data = attributedPurchaseResponse(role: role);
      final value = await projectionGateway(wire, account: role == 'buyer' ? 'buyer-1' : 'owner-1').readPurchaseProjection(
        role: role == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
        realm: 'evaluation', purchaseId: 'purchase-v2', storeId: role == 'seller' ? 'store-one' : null,
        orderId: role == 'seller' ? 'order-v2' : null);
      expect(value, isNotNull);
      expect(value!.orders.single.totals['totalMinor'], 10015);
    });
    test('LF-ATTR operational $role consumer retains original new-version facts', () async {
      final purchase = attributedPurchaseResponse(role: role), order = purchase['orders'][0];
      final raw = operationalResponse(role: role)..['originalFactsVersion'] = 3
        ..['original'] = order['original'] ..['originalFingerprint'] = order['originalFingerprint'];
      final wire = Transport()..data = raw;
      final reference = WorkspacePurchaseReference(purchaseId: 'purchase-v2', storeId: 'store-one', orderId: 'order-v2',
        sourceRevision: 'revision-1', originalFingerprint: order['originalFingerprint']);
      final result = await AuthenticatedWorkspaceOrderOperationsGateway(
        projectionGateway(wire, account: role == 'buyer' ? 'buyer-1' : 'owner-1')).read(
          role: role == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation', reference: reference);
      expect(result, isNotNull);
      expect(result!.original.totals['totalMinor'], 10015);
    });
  }
  for (final reconcile in [false, true]) {
    for (final action in ['accept', 'ready', 'reject']) {
      test(
        'operational acknowledgment must match action=$action reconcile=$reconcile',
        () async {
          final response = operationalResponse(role: 'seller')
            ..['revision'] = 2
            ..['stage'] = action == 'reject' ? 'Rejected' : 'Confirmed'
            ..['permittedActions'] = <String>[];
          if (action == 'reject') {
            response['rejectionReason'] = 'A different reason';
          }
          final wire = Transport()
            ..data = {
              'schemaVersion': 1,
              'operationId': 'bound-operation',
              'state': 'applied',
              'snapshot': response,
            };
          final gateway = AuthenticatedWorkspaceOrderOperationsGateway(
            projectionGateway(wire, account: 'owner-1'),
          );
          expect(
            await gateway.command(
              realm: 'evaluation',
              reference: operationalReference(),
              operationId: 'bound-operation',
              expectedRevision: 1,
              action: action,
              reason: action == 'reject' ? 'Original reason' : null,
              reconcile: reconcile,
            ),
            isNull,
          );
        },
      );
    }
  }
  test(
    'operational reader preserves exact originals and unknown financial authority',
    () async {
      final wire = Transport()..data = operationalResponse();
      final identity = projectionGateway(wire);
      final gateway = AuthenticatedWorkspaceOrderOperationsGateway(identity);
      final order = await gateway.read(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        reference: operationalReference(),
      );
      expect(order, isNotNull);
      expect(order!.original.totals['totalMinor'], 10015);
      expect(order.original.lines.single.verifiedPackId, 'pack-one');
      expect(order.customerLabel, isNull);
      expect(order.permittedActions, isEmpty);
      expect(wire.sent!['operation'], 'readBuyerOperationalOrder');
      expect(
        (identity.credentials as Credentials).modes.single,
        SocialAppCheckTokenMode.standard,
      );
    },
  );
  for (final entry in <String, void Function(Map<String, dynamic>)>{
    'cross account': (d) => d['viewerUserId'] = 'foreign-user',
    'cross Store': (d) => d['storeId'] = 'foreign-store',
    'different original': (d) => d['original']['totals']['totalMinor']++,
    'wrong source revision': (d) => d['sourceRevision'] = 'foreign-revision',
    'array stage': (d) => d['stage'] = ['Confirmed'],
    'array action': (d) => d['permittedActions'] = [
      ['accept'],
    ],
    'buyer recipient leak': (d) => d['address'] = 'Private recipient address',
    'claimed payment authority': (d) => d['paymentVerification'] = 'paid',
    'claimed Stock authority': (d) => d['stockVerification'] = 'reserved',
  }.entries) {
    test('operational reader rejects ${entry.key}', () async {
      final wire = Transport()..data = operationalResponse();
      entry.value(wire.data);
      final gateway = AuthenticatedWorkspaceOrderOperationsGateway(
        projectionGateway(wire),
      );
      expect(
        await gateway.read(
          role: WorkspaceOrderIdentityRole.buyer,
          realm: 'evaluation',
          reference: operationalReference(),
        ),
        isNull,
      );
    });
  }
  test(
    'operational command uses limited token; reconciliation retains original identity',
    () async {
      final snapshot = operationalResponse(role: 'seller')
        ..['revision'] = 2
        ..['stage'] = 'Preparing'
        ..['permittedActions'] = ['ready'];
      final wire = Transport()
        ..data = {
          'schemaVersion': 1,
          'operationId': 'STORE-ORDER-host_nonce==',
          'state': 'applied',
          'snapshot': snapshot,
        };
      final identity = projectionGateway(wire, account: 'owner-1');
      final gateway = AuthenticatedWorkspaceOrderOperationsGateway(identity);
      final first = await gateway.command(
        realm: 'evaluation',
        reference: operationalReference(),
        operationId: 'STORE-ORDER-host_nonce==',
        expectedRevision: 1,
        action: 'accept',
      );
      expect(first?.state, 'applied');
      final originalBody = Map<String, Object?>.from(wire.sent!)
        ..remove('operation');
      expect(
        (identity.credentials as Credentials).modes.last,
        SocialAppCheckTokenMode.limitedUse,
      );
      final recovered = await gateway.command(
        realm: 'evaluation',
        reference: operationalReference(),
        operationId: 'STORE-ORDER-host_nonce==',
        expectedRevision: 1,
        action: 'accept',
        reconcile: true,
      );
      expect(recovered?.snapshot.revision, 2);
      expect(wire.sent!['operation'], 'reconcileStoreOrderCommand');
      expect(
        Map<String, Object?>.from(wire.sent!)..remove('operation'),
        originalBody,
      );
      expect(
        (identity.credentials as Credentials).modes.last,
        SocialAppCheckTokenMode.standard,
      );
      wire.data['operationId'] = 'wrong-operation';
      expect(
        await gateway.command(
          realm: 'evaluation',
          reference: operationalReference(),
          operationId: 'STORE-ORDER-host_nonce==',
          expectedRevision: 1,
          action: 'accept',
          reconcile: true,
        ),
        isNull,
      );
    },
  );
  test(
    'operational read ignores retired lifetime and unknown command response',
    () async {
      Object? owner = Object();
      final wire = Transport()
        ..data = operationalResponse()
        ..pending = Completer<void>();
      final identity = projectionGateway(wire, lifetime: () => owner);
      final gateway = AuthenticatedWorkspaceOrderOperationsGateway(identity);
      final pending = gateway.read(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        reference: operationalReference(),
      );
      await Future<void>.delayed(Duration.zero);
      owner = null;
      wire.pending!.complete();
      expect(await pending, isNull);
      final before = wire.calls;
      expect(
        await gateway.command(
          realm: 'evaluation',
          reference: operationalReference(),
          operationId: 'STORE-ORDER-host_nonce==',
          expectedRevision: 1,
          action: 'accept',
        ),
        isNull,
      );
      expect(wire.calls, before);
    },
  );
  for (final entry in <String, void Function(Map<String, dynamic>)>{
    'other account': (d) => d['viewerUserId'] = 'other-buyer',
    'other realm': (d) => d['realm'] = 'production',
    'wrong coverage': (d) => d['coverage'] = 'all_orders',
    'foreign Store': (d) => d['storeId'] = 'other-store',
    'private fields': (d) => d['buyerUserId'] = 'private-user',
    'duplicate reference': (d) => d['references'].add(d['references'][0]),
    'bad fingerprint': (d) =>
        d['references'][0]['originalFingerprint'] = 'not-a-hash',
  }.entries) {
    test('reference discovery rejects ${entry.key}', () async {
      final wire = Transport()..data = referenceResponse();
      entry.value(wire.data);
      expect(
        await projectionGateway(wire).listPurchaseReferences(
          role: WorkspaceOrderIdentityRole.buyer,
          realm: 'evaluation',
        ),
        isNull,
      );
    });
  }
  test(
    'reference discovery can advance an empty scanned page without claiming no orders',
    () async {
      final wire = Transport()
        ..data = referenceResponse()
        ..data['references'] = []
        ..data['nextCursor'] = 'next-page';
      final page = await projectionGateway(wire).listPurchaseReferences(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
      );
      expect(page!.references, isEmpty);
      expect(page.nextCursor, 'next-page');
      expect(page.coverage, 'saved_original_facts');
    },
  );
  test('reference discovery discards response after owner retires', () async {
    Object? lifetime = Object();
    final wire = Transport()
      ..data = referenceResponse()
      ..pending = Completer<void>();
    final gateway = projectionGateway(wire, lifetime: () => lifetime);
    final pending = gateway.listPurchaseReferences(
      role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation',
    );
    await Future<void>.delayed(Duration.zero);
    lifetime = Object();
    wire.pending!.complete();
    expect(await pending, isNull);
  });
  test(
    'discovers scoped references without converting them into legacy orders',
    () async {
      final wire = Transport()..data = referenceResponse();
      final client = projectionGateway(wire);
      final page = await client.listPurchaseReferences(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
      );
      expect(page!.references.single.orderId, 'order-v2');
      expect(page.coverage, 'saved_original_facts');
      expect(wire.sent!['operation'], 'listBuyerPurchaseReferences');
      wire.data = purchaseResponse();
      final details = await client.readReferencedOrder(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        reference: page.references.single,
      );
      expect(details!.totals['totalMinor'], 10015);
      wire.data['orders'][0]['orderId'] = 'another-order';
      expect(
        await client.readReferencedOrder(
          role: WorkspaceOrderIdentityRole.buyer,
          realm: 'evaluation',
          reference: page.references.single,
        ),
        isNull,
      );
    },
  );
  test(
    'actual Firestore service v2 response decodes both immutable Store partitions',
    () async {
      // Captured from readBuyer on the actual local emulator, not generated in Dart.
      const raw =
          r'''{"schemaVersion":2,"realm":"evaluation","authNamespace":"firebase-default","viewerRole":"buyer","viewerUserId":"new-buyer-c013b044-e69f-42f5-b5c9-82a70e35fbaf","purchaseId":"purchase-2f7efd65-b8fa-48df-a81d-87322f929825","buyerId":"buyer-87291824-42fb-4368-a74f-c0e0b2c098e8","sourceRevision":"revision-1","state":"original_facts","orders":[{"factsVersion":2,"storeId":"store-c013b044-e69f-42f5-b5c9-82a70e35fbaf-0","orderId":"order-f742ce0f-9bc6-4e4f-92bd-08520cf504a6","original":{"currency":"INR","lines":[{"lineId":"line-b8405fac-3efd-47b6-b951-64b1cfe1934c","skuId":"sku-one","canonicalProductId":"product-one","verifiedPackId":"pack-one","offerId":"offer-one","offerRevision":"offer-revision-1","name":"दाल","packLabel":"1 kg","quantityMilli":1000,"quantityUnit":"pack","unitPriceMinor":10051,"lineTotalMinor":10051}],"totals":{"itemsMinor":10051,"discountMinor":51,"taxMinor":5,"deliveryMinor":10,"freightMinor":0,"paymentFeeMinor":0,"tipMinor":0,"totalMinor":10015}},"originalFingerprint":"df39f39c6753d00554d8380ec8942e0893da4bae3b4b84d2e5bc4c24e631844f"},{"factsVersion":2,"storeId":"store-c013b044-e69f-42f5-b5c9-82a70e35fbaf-1","orderId":"order-6f1e7540-8d9e-4f10-8cc0-6c3168e690d5","original":{"currency":"INR","lines":[{"lineId":"line-154f8a75-863f-4239-8105-9d371750f2cb","skuId":"sku-two","canonicalProductId":"product-two","verifiedPackId":"pack-two","offerId":"offer-two","offerRevision":"offer-revision-1","name":"दाल","packLabel":"1 kg","quantityMilli":1000,"quantityUnit":"pack","unitPriceMinor":10051,"lineTotalMinor":10051}],"totals":{"itemsMinor":10051,"discountMinor":51,"taxMinor":5,"deliveryMinor":10,"freightMinor":0,"paymentFeeMinor":0,"tipMinor":0,"totalMinor":10015}},"originalFingerprint":"b12424b5fe481aa3c164692b27e2cda71862aa9d08e713cae5ae2df7ba032130"}]}''';
      final wire = Transport()
        ..data = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final gateway = projectionGateway(
        wire,
        account: wire.data['viewerUserId'] as String,
      );
      final result = await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: wire.data['purchaseId'] as String,
      );
      expect(result!.orders.length, 2);
      expect(result.orders.first.lines.single.name, 'दाल');
      expect(result.orders.last.lines.single.verifiedPackId, 'pack-two');
      expect(
        result.orders.every((o) => o.totals['totalMinor'] == 10015),
        isTrue,
      );
      expect(() => result.orders.clear(), throwsUnsupportedError);
      expect(() => result.orders.first.totals.clear(), throwsUnsupportedError);
    },
  );
  for (final entry in <String, void Function(Map<String, dynamic>)>{
    'wrong account': (d) => d['viewerUserId'] = 'other-buyer',
    'wrong purchase': (d) => d['purchaseId'] = 'other-purchase',
    'wrong realm': (d) => d['realm'] = 'production',
    'tenant namespace': (d) => d['authNamespace'] = 'tenant-one',
    'legacy response': (d) => d['schemaVersion'] = 1,
    'private owner leak': (d) => d['ownerUserId'] = 'owner-other',
    'empty success': (d) => d['orders'] = [],
    'duplicate Store': (d) =>
        (d['orders'] as List).add((d['orders'] as List).first),
    'tampered fingerprint': (d) =>
        d['orders'][0]['originalFingerprint'] = '0' * 64,
    'money mismatch': (d) =>
        d['orders'][0]['original']['totals']['totalMinor']++,
    'unit price mismatch': (d) =>
        d['orders'][0]['original']['lines'][0]['unitPriceMinor'] = 1,
    'malformed quantity unit': (d) =>
        d['orders'][0]['original']['lines'][0]['quantityUnit'] = ['pack'],
    'missing pack': (d) =>
        d['orders'][0]['original']['lines'][0].remove('verifiedPackId'),
  }.entries) {
    test(
      'v2 rejects ${entry.key} without falling back to legacy orders',
      () async {
        final wire = Transport()..data = purchaseResponse();
        entry.value(wire.data);
        expect(
          await projectionGateway(wire).readPurchaseProjection(
            role: WorkspaceOrderIdentityRole.buyer,
            realm: 'evaluation',
            purchaseId: 'purchase-v2',
          ),
          isNull,
        );
        expect(wire.calls, 1);
      },
    );
  }
  test(
    'v2 seller requires exact purchase Store and order, with no other partition',
    () async {
      final wire = Transport()..data = purchaseResponse(role: 'seller');
      final gateway = projectionGateway(wire, account: 'owner-1');
      expect(
        await gateway.readPurchaseProjection(
          role: WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation',
          purchaseId: 'purchase-v2',
          storeId: 'store-one',
          orderId: 'order-v2',
        ),
        isNotNull,
      );
      expect(wire.sent!['operation'], 'readStorePurchaseProjection');
      expect(
        await gateway.readPurchaseProjection(
          role: WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation',
          purchaseId: 'purchase-v2',
          storeId: 'store-other',
          orderId: 'order-v2',
        ),
        isNull,
      );
      expect(
        await gateway.readPurchaseProjection(
          role: WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation',
          purchaseId: 'purchase-v2',
          storeId: 'store-one',
          orderId: 'order-other',
        ),
        isNull,
      );
      wire.data['orders'].add(wire.data['orders'][0]);
      expect(
        await gateway.readPurchaseProjection(
          role: WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation',
          purchaseId: 'purchase-v2',
          storeId: 'store-one',
          orderId: 'order-v2',
        ),
        isNull,
      );
    },
  );
  test(
    'v2 fences late responses and all future calls after original lifetime retires',
    () async {
      Object? lifetime = Object();
      final wire = Transport()
        ..data = purchaseResponse()
        ..pending = Completer<void>();
      final gateway = projectionGateway(wire, lifetime: () => lifetime);
      final pending = gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
      );
      await Future<void>.delayed(Duration.zero);
      lifetime = Object();
      wire.pending!.complete();
      expect(await pending, isNull);
      final calls = wire.calls;
      expect(
        await gateway.readPurchaseProjection(
          role: WorkspaceOrderIdentityRole.buyer,
          realm: 'evaluation',
          purchaseId: 'purchase-v2',
        ),
        isNull,
      );
      expect(wire.calls, calls);
    },
  );
  test('v2 invalid request scope never reaches transport', () async {
    final wire = Transport()..data = purchaseResponse();
    final gateway = projectionGateway(wire);
    expect(
      await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
        storeId: 'store-one',
      ),
      isNull,
    );
    expect(
      await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.seller,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
      ),
      isNull,
    );
    expect(
      await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'unknown',
        purchaseId: 'purchase-v2',
      ),
      isNull,
    );
    expect(wire.calls, 0);
  });
  test(
    'v2 retires during credentials before any request is dispatched',
    () async {
      Object? owner = Object();
      final credentials = Credentials()..token = Completer<String>();
      final wire = Transport()..data = purchaseResponse();
      final gateway = AuthenticatedWorkspaceOrderIdentityGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        accountUserId: 'buyer-1',
        lifetime: () => owner,
        credentials: credentials,
        transport: wire,
      );
      final pending = gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
      );
      owner = Object();
      credentials.token!.complete('host-token');
      expect(await pending, isNull);
      expect(wire.calls, 0);
      expect(credentials.modes, isEmpty);
    },
  );
  test('v2 unavailable transport is not an empty purchase', () async {
    final wire = Transport()
      ..data = purchaseResponse()
      ..fail = true;
    final gateway = projectionGateway(wire);
    expect(
      await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
      ),
      isNull,
    );
    wire.fail = false;
    wire.status = 503;
    expect(
      await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
      ),
      isNull,
    );
  });
  test(
    'v2 reader consumes exact Store references and paise without legacy ID inference',
    () async {
      final transport = Transport()..data = purchaseResponse();
      final owner = Object();
      final gateway = AuthenticatedWorkspaceOrderIdentityGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        accountUserId: 'buyer-1',
        lifetime: () => owner,
        credentials: Credentials(),
        transport: transport,
      );
      final result = await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
      );
      expect(result!.orders.single.orderId, 'order-v2');
      expect(result.orders.single.totals['totalMinor'], 10015);
      expect(result.orders.single.lines.single.verifiedPackId, 'pack-one');
      expect(transport.sent, {
        'operation': 'readBuyerPurchaseProjection',
        'purchaseId': 'purchase-v2',
      });
    },
  );
  test(
    'backend-produced Unicode response preserves cross-language fingerprint',
    () async {
      // Generated by the actual TypeScript bindFinalPurchase/readIdentity service.
      // Isolated source fixture; this is not native/live-order acceptance.
      const raw =
          r'''{"ok":true,"data":{"schemaVersion":1,"viewerRole":"buyer","viewerUserId":"buyer-1","storeId":"workspace-1","orderId":"MS-interop","state":"linked","identity":{"buyerId":"customer-1","purchaseId":"purchase-1","sourceRevision":"final-1","serviceRevision":"574cd1c2006b279b774537e9052ef5507c573f9916930e1c4f9981dadfaaaecd","originalFingerprint":"08053f9c98991dc380083d62f9fd02361a35fd390f49f6527c4efa4f7026e135","original":{"currency":"INR","amountMinor":124000,"lines":[{"lineId":"a-1","name":"É oil","detail":"500 ml","quantity":1,"amountMinor":5000},{"lineId":"z-1","name":"दाल \"A\"","detail":"1 kg\nsealed","quantity":2,"amountMinor":11000}]}}}}''';
      final wire = Transport()
        ..data = (jsonDecode(raw)['data'] as Map).cast<String, dynamic>();
      final life = Object();
      final client = AuthenticatedWorkspaceOrderIdentityGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        accountUserId: 'buyer-1',
        lifetime: () => life,
        credentials: Credentials(),
        transport: wire,
      );
      final result = await client.read(
        role: WorkspaceOrderIdentityRole.buyer,
        storeId: 'workspace-1',
        orderId: 'MS-interop',
        purchaseId: 'purchase-1',
      );
      expect(result.state, WorkspaceOrderIdentityState.linked);
      expect(
        result.identity!.originalFingerprint,
        '08053f9c98991dc380083d62f9fd02361a35fd390f49f6527c4efa4f7026e135',
      );
      expect(result.identity!.lines.last.name, 'दाल "A"');
      expect(result.identity!.lines.last.detail, '1 kg\nsealed');
    },
  );
  late Object? context;
  late Transport transport;
  late Credentials credentials;
  late AuthenticatedWorkspaceOrderIdentityGateway gateway;
  setUp(() {
    context = Object();
    transport = Transport();
    credentials = Credentials();
    gateway = AuthenticatedWorkspaceOrderIdentityGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
      ),
      accountUserId: 'buyer-1',
      lifetime: () => context,
      credentials: credentials,
      transport: transport,
    );
  });
  Future<WorkspaceOrderIdentityResult> read() => gateway.read(
    role: WorkspaceOrderIdentityRole.buyer,
    storeId: 'workspace-1',
    orderId: 'MS-2841',
    purchaseId: 'purchase-1',
  );

  test(
    'an old gateway cannot start a read after its lifetime is retired',
    () async {
      context = Object(); // New A generation after A-B-A, same actor ID.
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
      expect(transport.calls, 0);
    },
  );

  test(
    'exact buyer tuple and immutable original facts decode without commerce mutation',
    () async {
      final result = await read();
      expect(result.state, WorkspaceOrderIdentityState.linked);
      expect(result.identity!.buyerId, 'customer-1');
      expect(result.identity!.amountMinor, 124000);
      expect(result.identity!.lines.single.quantity, 2);
      expect(transport.sent, {
        'operation': 'readBuyerOrderIdentity',
        'storeId': 'workspace-1',
        'orderId': 'MS-2841',
        'purchaseId': 'purchase-1',
      });
      expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
      expect(() => result.identity!.lines.clear(), throwsUnsupportedError);
    },
  );

  for (final key in [
    'schemaVersion',
    'viewerRole',
    'viewerUserId',
    'storeId',
    'orderId',
    'state',
  ]) {
    test('mismatched $key is unavailable, never a different order', () async {
      transport.data[key] = 'wrong';
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
    });
  }
  for (final key in [
    'purchaseId',
    'buyerId',
    'sourceRevision',
    'serviceRevision',
    'originalFingerprint',
  ]) {
    test('missing identity $key is unavailable', () async {
      (transport.data['identity'] as Map).remove(key);
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
    });
  }
  test(
    'changed purchased facts or different expected fingerprint cannot bind',
    () async {
      ((transport.data['identity'] as Map)['original'] as Map)['amountMinor'] =
          0;
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
      transport.data = response();
      expect(
        (await gateway.read(
          role: WorkspaceOrderIdentityRole.buyer,
          storeId: 'workspace-1',
          orderId: 'MS-2841',
          purchaseId: 'purchase-1',
          expectedOriginalFingerprint: 'b' * 64,
        )).state,
        WorkspaceOrderIdentityState.unavailable,
      );
    },
  );
  test(
    'seller may read legacy unlinked; buyer cannot treat it as linked',
    () async {
      final seller = AuthenticatedWorkspaceOrderIdentityGateway(
        endpoint: gateway.endpoint,
        accountUserId: 'owner-1',
        lifetime: () => context,
        credentials: credentials,
        transport: transport,
      );
      transport.data = response(role: 'seller')..remove('identity');
      transport.data['state'] = 'unlinked';
      expect(
        (await seller.read(
          role: WorkspaceOrderIdentityRole.seller,
          storeId: 'workspace-1',
          orderId: 'MS-2841',
        )).state,
        WorkspaceOrderIdentityState.unlinked,
      );
      transport.data = response()..remove('identity');
      transport.data['state'] = 'unlinked';
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
    },
  );
  test('retirement during credentials prevents dispatch', () async {
    final token = Completer<String>();
    credentials.token = token;
    final pending = read();
    context = null;
    token.complete('host-token');
    expect((await pending).state, WorkspaceOrderIdentityState.unavailable);
    expect(transport.calls, 0);
  });
  test('late response after A-B-A generation change is discarded', () async {
    transport.pending = Completer<void>();
    final pending = read();
    await Future<void>.delayed(Duration.zero);
    context = Object();
    transport.pending!.complete();
    expect((await pending).state, WorkspaceOrderIdentityState.unavailable);
  });
  test(
    'network failure, HTTP denial and invalid request do not become empty success',
    () async {
      transport.fail = true;
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
      transport.fail = false;
      transport.status = 404;
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
      transport.status = 200;
      expect(
        (await gateway.read(
          role: WorkspaceOrderIdentityRole.buyer,
          storeId: 'workspace-1',
          orderId: 'MS-2841',
        )).state,
        WorkspaceOrderIdentityState.unavailable,
      );
      expect(transport.calls, 2);
    },
  );
}

Map<String, dynamic> purchaseResponse({String role = 'buyer'}) {
  final original = <String, Object>{
    'currency': 'INR',
    'lines': [
      <String, Object>{
        'lineId': 'line-one',
        'skuId': 'sku-one',
        'canonicalProductId': 'product-one',
        'verifiedPackId': 'pack-one',
        'offerId': 'offer-one',
        'offerRevision': 'offer-revision-1',
        'name': 'दाल',
        'packLabel': '1 kg',
        'quantityMilli': 1000,
        'quantityUnit': 'pack',
        'unitPriceMinor': 10051,
        'lineTotalMinor': 10051,
      },
    ],
    'totals': <String, int>{
      'itemsMinor': 10051,
      'discountMinor': 51,
      'taxMinor': 5,
      'deliveryMinor': 10,
      'freightMinor': 0,
      'paymentFeeMinor': 0,
      'tipMinor': 0,
      'totalMinor': 10015,
    },
  };
  return {
    'schemaVersion': 2,
    'realm': 'evaluation',
    'authNamespace': 'firebase-default',
    'viewerRole': role,
    'viewerUserId': role == 'buyer' ? 'buyer-1' : 'owner-1',
    'purchaseId': 'purchase-v2',
    'buyerId': 'opaque-buyer',
    'sourceRevision': 'revision-1',
    'state': 'original_facts',
    'orders': [
      {
        'factsVersion': 2,
        'storeId': 'store-one',
        'orderId': 'order-v2',
        'original': original,
        'originalFingerprint': sha256
            .convert(
              utf8.encode(
                jsonEncode({
                  'factsVersion': 2,
                  'storeId': 'store-one',
                  'orderId': 'order-v2',
                  'original': original,
                }),
              ),
            )
            .toString(),
      },
    ],
  };
}

Map<String, dynamic> publicListingPurchaseResponse({String role = 'buyer', bool allNull = false}) {
  final data = scheduledPurchaseResponse(role: role)..['schemaVersion'] = 6;
  final order = data['orders'][0] as Map<String, dynamic>;
  order['factsVersion'] = 6;
  for (final line in order['original']['lines']) {
    line['publicListing'] = allNull ? null : jsonDecode(jsonEncode(line['scheduledFulfilment']['listing']));
  }
  rehashPurchaseOrder(order);
  return data;
}

Map<String, dynamic> scheduledPurchaseResponse({String role = 'buyer', bool selected = true}) {
  final response = (jsonDecode(jsonEncode(variantPurchaseResponse(role: role))) as Map).cast<String, dynamic>();
  response['schemaVersion'] = 5;
  final order = response['orders'][0] as Map<String, dynamic>;
  order['factsVersion'] = 5;
  final line = order['original']['lines'][0] as Map<String, dynamic>;
  line['scheduledFulfilment'] = selected ? {
    'schemaVersion': 1, 'method': 'scheduled', 'listing': {
      'schemaVersion': 1, 'realm': 'evaluation',
      'listingId': 'listing-${sha256.convert(utf8.encode(jsonEncode([1, 'evaluation', order['storeId'], line['skuId'], 'retail'])))}',
      'storeId': order['storeId'], 'skuId': line['skuId'], 'canonicalProductId': line['canonicalProductId'],
      'verifiedPackId': line['verifiedPackId'], 'channel': 'retail'},
    'sourceRevision': 'eligibility-original-one', 'locationKey': 'opaque-destination-one', 'slotId': 'slot-original-one',
    'startsAt': '2026-10-15T23:59:59.123456Z', 'endsAt': '2026-10-16T00:00:00.000001Z',
  } : null;
  rehashPurchaseOrder(order);
  // Represent actual decoded JSON, including malformed nullable fields in tests.
  return (jsonDecode(jsonEncode(response)) as Map).cast<String, dynamic>();
}

Map<String, dynamic> variantPurchaseResponse({String role = 'buyer', String variant = 'Pink · 128 GB'}) {
  final response = attributedPurchaseResponse(role: role)..['schemaVersion'] = 4;
  final order = response['orders'][0] as Map<String, dynamic>;
  order['factsVersion'] = 4;
  ((order['original'] as Map)['lines'] as List).single['variant'] = variant;
  rehashPurchaseOrder(order);
  return response;
}

Map<String, dynamic> attributedPurchaseResponse({String role = 'buyer', bool empty = false}) {
  final response = purchaseResponse(role: role)..['schemaVersion'] = 3;
  final order = response['orders'][0] as Map<String, dynamic>;
  order['factsVersion'] = 3;
  final original = order['original'] as Map<String, Object>;
  original['benefitAttribution'] = {'schemaVersion': 1, 'components': empty ? <Object>[] : [
    {'componentId': 'discount-component', 'benefitId': 'supplier-coupon', 'benefitRevision': 'benefit-v1',
      'label': 'Supplier saving', 'publisherType': 'supplier', 'effect': 'instant_discount', 'amountBasis': 'applied',
      'sourceReference': 'trusted-benefit-one', 'funderReference': 'private-funder-one', 'amountMinor': 51,
      'allocations': [{'lineId': 'line-one', 'amountMinor': 51}]},
    {'componentId': 'cashback-component', 'benefitId': 'payment-offer', 'benefitRevision': 'benefit-v2',
      'label': 'Payment cashback offer', 'publisherType': 'payment', 'effect': 'cashback_offer', 'amountBasis': 'maximum',
      'sourceReference': 'trusted-benefit-two', 'funderReference': 'private-funder-two', 'amountMinor': 25,
      'allocations': [{'lineId': 'line-one', 'amountMinor': 25}]},
  ]};
  if (empty) {
    final totals = original['totals'] as Map<String, int>;
    totals['discountMinor'] = 0; totals['totalMinor'] = 10066;
  }
  rehashPurchaseOrder(order);
  return response;
}

void rehashPurchaseOrder(Map<String, dynamic> order) {
  order['originalFingerprint'] = sha256.convert(utf8.encode(jsonEncode({
    'factsVersion': order['factsVersion'], 'storeId': order['storeId'], 'orderId': order['orderId'], 'original': order['original'],
  }))).toString();
}

Map<String, dynamic> attributedOperationalResponse({String role = 'buyer'}) {
  final order = attributedPurchaseResponse(role: role)['orders'][0];
  return operationalResponse(role: role)..['originalFactsVersion'] = 3
    ..['original'] = order['original'] ..['originalFingerprint'] = order['originalFingerprint'];
}

Map<String, dynamic> variantOperationalResponse({String role = 'buyer'}) {
  final order = variantPurchaseResponse(role: role)['orders'][0];
  return operationalResponse(role: role)..['originalFactsVersion'] = 4
    ..['original'] = order['original'] ..['originalFingerprint'] = order['originalFingerprint'];
}

Map<String, dynamic> scheduledOperationalResponse({String role = 'buyer'}) {
  final order = scheduledPurchaseResponse(role: role)['orders'][0];
  return operationalResponse(role: role)..['originalFactsVersion'] = 5
    ..['original'] = order['original'] ..['originalFingerprint'] = order['originalFingerprint'];
}

Map<String, dynamic> referenceResponse({String role = 'buyer'}) {
  final purchase = purchaseResponse(role: role);
  final order = purchase['orders'][0];
  return {
    'schemaVersion': 2,
    'realm': 'evaluation',
    'authNamespace': 'firebase-default',
    'viewerRole': role,
    'viewerUserId': role == 'buyer' ? 'buyer-1' : 'owner-1',
    'storeId': role == 'seller' ? 'store-one' : null,
    'coverage': role == 'buyer'
        ? 'saved_original_facts'
        : 'indexed_original_facts',
    'references': [
      {
        'purchaseId': purchase['purchaseId'],
        'storeId': order['storeId'],
        'orderId': order['orderId'],
        'originalFingerprint': order['originalFingerprint'],
        'sourceRevision': purchase['sourceRevision'],
      },
    ],
    'nextCursor': null,
  };
}

AuthenticatedWorkspaceOrderIdentityGateway projectionGateway(
  Transport wire, {
  String account = 'buyer-1',
  Object? Function()? lifetime,
}) => AuthenticatedWorkspaceOrderIdentityGateway(
  endpoint: Uri.parse(
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
  ),
  accountUserId: account,
  lifetime: lifetime ?? () => 'fixed-host-lifetime',
  credentials: Credentials(),
  transport: wire,
);

WorkspacePurchaseReference operationalReference() {
  final raw = referenceResponse()['references'][0];
  return WorkspacePurchaseReference(
    purchaseId: raw['purchaseId'],
    storeId: raw['storeId'],
    orderId: raw['orderId'],
    originalFingerprint: raw['originalFingerprint'],
    sourceRevision: raw['sourceRevision'],
  );
}

Map<String, dynamic> operationalResponse({String role = 'buyer'}) {
  final original = purchaseResponse(role: role);
  final order = original['orders'][0];
  return {
    'schemaVersion': 1,
    'realm': 'evaluation',
    'authNamespace': 'firebase-default',
    'viewerRole': role,
    'viewerUserId': role == 'buyer' ? 'buyer-1' : 'owner-1',
    'purchaseId': original['purchaseId'],
    'storeId': order['storeId'],
    'orderId': order['orderId'],
    'sourceRevision': original['sourceRevision'],
    'originalFingerprint': order['originalFingerprint'],
    'original': order['original'],
    'operationalSourceRevision': 'operational-v1',
    'revision': 1,
    'stage': 'Confirmed',
    'fulfilment': 'delivery',
    'placedAt': '2026-10-16T12:00:00.000Z',
    'acceptanceDeadline': '2026-10-16T12:05:00.000Z',
    'fulfilmentDeadline': '2026-10-16T13:00:00.000Z',
    'permittedActions': role == 'seller' ? ['accept', 'reject'] : <String>[],
    'paymentVerification': 'not_supplied',
    'stockVerification': 'not_supplied',
    'rejectionReason': null,
    if (role == 'seller') 'customerLabel': 'Evaluation buyer',
    if (role == 'seller') 'address': 'Evaluation address',
  };
}
