import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/retailer/retailer_models.dart';
import 'package:moolsocial/features/retailer/retailer_services.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';

void main() {
  test('release app uses fail-closed production retailer state', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('retailerSession: RetailerSession.production(),'));
  });

  test(
    'authenticated retailer gateway loads toggles and saves exact state',
    () async {
      final transport = _RecordingTransport([
        _store(enabled: true, stock: 24, price: 55),
        _store(enabled: false, stock: 24, price: 55),
        _store(enabled: false, stock: 8, price: 58),
      ]);
      final credentials = _RecordingCredentials();
      final gateway = AuthenticatedRetailerGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        credentials: credentials,
        transport: transport,
        random: Random(3),
      );

      final loaded = await gateway.loadStore();
      final paused = await gateway.setAvailability(false);
      final saved = await gateway.saveProduct(
        productId: 'atta',
        stock: 8,
        buyPrice: 48,
        sellPrice: 58,
      );

      expect(loaded.name, 'Mahadev Fresh Mart');
      expect(loaded.products.single.stock, 24);
      expect(paused.ordersEnabled, isFalse);
      expect(saved.products.single.stock, 8);
      expect(saved.products.single.price, 58);
      expect(transport.bodies.map((body) => body['operation']), [
        'retailerStoreState',
        'setRetailerAvailability',
        'saveRetailerProduct',
      ]);
      expect(transport.bodies.last, containsPair('buyPrice', 48));
      expect(credentials.modes, [
        SocialAppCheckTokenMode.standard,
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.limitedUse,
      ]);
    },
  );

  test(
    'production session restores and rolls back failed availability',
    () async {
      final gateway = ReviewRetailerGateway()..failAvailability = true;
      final session = RetailerSession.production(gateway: gateway);
      addTearDown(session.dispose);

      await session.loadInitialStore();
      expect(session.ordersOnline, isTrue);
      expect(session.catalogueProducts, isNotEmpty);

      await session.setOrdersOnline(false);
      expect(session.ordersOnline, isTrue);
      expect(session.errorMessage, contains('previous setting remains active'));

      await session.setOrdersOnline(false);
      expect(session.ordersOnline, isFalse);
      expect(gateway.availabilityCalls, 2);
    },
  );

  test('production gateway decodes persisted retailer order states', () async {
    final transport = _RecordingTransport([
      SocialContentResponse(
        statusCode: 200,
        body: jsonEncode({
          'ok': true,
          'data': {
            'orders': [_order(stage: 'returned')],
          },
        }),
      ),
      SocialContentResponse(
        statusCode: 200,
        body: jsonEncode({'ok': true, 'data': _order(stage: 'accepted')}),
      ),
    ]);
    final gateway = AuthenticatedRetailerGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
      ),
      credentials: _RecordingCredentials(),
      transport: transport,
      random: Random(4),
    );

    final orders = await gateway.refreshOrders();
    await gateway.acceptOrder('MS-2841');

    expect(orders.single.stage, RetailerOrderStage.returned);
    expect(orders.single.lines.single.name, 'Aashirvaad Atta');
    expect(transport.bodies.map((body) => body['operation']), [
      'listRetailerOrders',
      'acceptRetailerOrder',
    ]);
  });

  test(
    'product save validates margin before sending and then updates stock',
    () async {
      final gateway = ReviewRetailerGateway();
      final session = RetailerSession.production(gateway: gateway);
      addTearDown(session.dispose);
      await session.loadInitialStore();

      expect(
        await session.saveCatalogueProduct(
          productId: 'atta',
          stock: 8,
          buyPrice: 60,
          sellPrice: 58,
        ),
        isFalse,
      );
      expect(gateway.productCalls, 0);

      expect(
        await session.saveCatalogueProduct(
          productId: 'atta',
          stock: 8,
          buyPrice: 48,
          sellPrice: 58,
        ),
        isTrue,
      );
      expect(gateway.productCalls, 1);
      final product = session.catalogueProducts.firstWhere(
        (item) => item.id == 'atta',
      );
      expect(product.stock, 8);
      expect(product.price, 58);
    },
  );

  test(
    'production delivery stops at real captain and OTP boundaries',
    () async {
      final gateway = ReviewRetailerGateway();
      final session = RetailerSession.production(gateway: gateway);
      addTearDown(session.dispose);
      await session.loadInitialStore();
      final order = session.openOrder('MS-2841')
        ..stage = RetailerOrderStage.packed;

      expect(await session.requestDelivery(), isTrue);
      expect(order.stage, RetailerOrderStage.deliveryRequested);
      expect(order.captainName, isNull);

      order.stage = RetailerOrderStage.captainArrived;
      expect(session.verifyHandoverOtp('2841'), isFalse);
      expect(order.stage, RetailerOrderStage.captainArrived);
      expect(session.errorMessage, contains('unavailable right now'));
    },
  );
}

class _RecordingCredentials implements SocialContentCredentials {
  final List<SocialAppCheckTokenMode> modes = [];
  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    modes.add(mode);
    return 'app-check-test';
  }

  @override
  Future<String> firebaseIdToken() async => 'firebase-id-test';
}

class _RecordingTransport implements SocialContentTransport {
  _RecordingTransport(this.responses);
  final List<SocialContentResponse> responses;
  final List<Map<String, Object?>> bodies = [];
  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    expect(endpoint.path, '/moolSocialWorkspace');
    expect(headers['authorization'], 'Bearer firebase-id-test');
    bodies.add(Map<String, Object?>.from(body));
    return responses.removeAt(0);
  }
}

SocialContentResponse _store({
  required bool enabled,
  required int stock,
  required int price,
}) => SocialContentResponse(
  statusCode: 200,
  body: jsonEncode({
    'ok': true,
    'data': {
      'workspaceId': 'workspace-1',
      'name': 'Mahadev Fresh Mart',
      'area': 'Sardarpura, Jodhpur',
      'ordersEnabled': enabled,
      'products': [
        {
          'id': 'atta',
          'name': 'Aashirvaad Whole Wheat Atta',
          'pack': '1 kg',
          'sku': 'AAT-1K',
          'price': price,
          'stock': stock,
        },
      ],
    },
  }),
);

Map<String, Object?> _order({required String stage}) => {
  'id': 'MS-2841',
  'customer': 'Amit Sharma',
  'area': 'Sardarpura · 2.1 km',
  'payment': 'Paid online · ₹1,240 protected',
  'fulfilment': 'Home delivery',
  'deliveryPromise': 'Deliver by 8:15 PM',
  'amount': 1240,
  'stage': stage,
  'lines': [
    {
      'id': 'atta',
      'name': 'Aashirvaad Atta',
      'detail': '1 kg',
      'quantity': 2,
      'amount': 110,
      'packed': stage != 'received',
    },
  ],
};
