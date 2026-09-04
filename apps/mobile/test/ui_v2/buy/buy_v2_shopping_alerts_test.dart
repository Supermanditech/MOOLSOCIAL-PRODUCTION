import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_shopping_alerts.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shopping alerts retain exact identities and routes', () async {
    final adapter = _AlertsAdapter();
    final core = BuySession();
    final session = BuyV2Session(core: core, shoppingAlertsAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final order = session.orders.first;
    adapter.snapshot = BuyV2ShoppingAlertsSnapshot(
      state: BuyV2ShoppingAlertsState.ready,
      sourceId: 'shopping-alert-service',
      alerts: [
        BuyV2ShoppingAlert(
          id: 'order-update',
          kind: BuyV2ShoppingAlertKind.delivery,
          title: 'Delivery update',
          detail: 'Your order is moving.',
          updatedLabel: 'Just now',
          destination: BuyV2Destination.orders,
          orderId: order.id,
        ),
        const BuyV2ShoppingAlert(
          id: 'stale-order',
          kind: BuyV2ShoppingAlertKind.refund,
          title: 'Refund update',
          detail: 'Review the refund.',
          updatedLabel: 'Today',
          destination: BuyV2Destination.orders,
          orderId: 'missing-order',
        ),
      ],
    );

    expect(await session.restoreShoppingAlerts(), isTrue);
    expect(session.shoppingAlerts, hasLength(1));
    final location = buyV2ShoppingAlertLocation(session.shoppingAlerts.single);
    final uri = Uri.parse(location);
    expect(uri.path, '/app/buy');
    expect(uri.queryParameters['sub'], 'orders');
    expect(uri.queryParameters['view'], 'tracking');
    expect(uri.queryParameters['order'], order.id);

    const productAlert = BuyV2ShoppingAlert(
      id: 'price',
      kind: BuyV2ShoppingAlertKind.priceDrop,
      title: 'Price update',
      detail: 'Price changed.',
      updatedLabel: 'Today',
      destination: BuyV2Destination.shop,
      productId: 's-milk',
    );
    final productUri = Uri.parse(buyV2ShoppingAlertLocation(productAlert));
    expect(productUri.queryParameters['view'], 'product');
    expect(productUri.queryParameters['product'], 's-milk');

    const offerAlert = BuyV2ShoppingAlert(
      id: 'offer',
      kind: BuyV2ShoppingAlertKind.offer,
      title: 'Offer',
      detail: 'Review offers.',
      updatedLabel: 'Today',
      destination: BuyV2Destination.shop,
    );
    expect(
      Uri.parse(buyV2ShoppingAlertLocation(offerAlert)).queryParameters['sub'],
      'offers',
    );
  });

  testWidgets('shopping alert previews fit at 320 large text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(await session.restoreShoppingAlerts(), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showBuyV2ShoppingAlerts(context, session),
                child: const Text('Open alerts'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open alerts'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-shopping-alerts')), findsOneWidget);
    expect(find.text('Shopping alerts'), findsOneWidget);
    expect(session.shoppingAlerts, isNotEmpty);
    for (final alert in session.shoppingAlerts) {
      expect(
        find.byKey(ValueKey('buy-shopping-alert-${alert.id}')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });
}

final class _AlertsAdapter implements BuyV2ShoppingAlertsAdapter {
  BuyV2ShoppingAlertsSnapshot snapshot = const BuyV2ShoppingAlertsSnapshot(
    state: BuyV2ShoppingAlertsState.unavailable,
    sourceId: 'shopping-alert-service',
  );

  @override
  Future<BuyV2ShoppingAlertsSnapshot> load(
    BuyV2ShoppingAlertsRequest request,
  ) async => snapshot;
}
