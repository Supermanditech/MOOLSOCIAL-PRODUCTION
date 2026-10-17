import 'dart:async';
import 'dart:convert';
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
