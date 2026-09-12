import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  BuyV2Session newSession() => BuyV2Session(core: BuySession());

  Widget app(BuyV2Session session, {bool reducedMotion = false}) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reducedMotion,
          textScaler: const TextScaler.linear(1.4),
        ),
        child: child!,
      ),
      home: BuyV2Screen(session: session),
    );
  }

  test('historical orders retain exact products and reorder into Cart', () {
    final session = newSession();
    final order = session.orders.firstWhere(
      (candidate) => candidate.id == 'MS-240741',
    );

    expect(order.productIds, hasLength(8));
    expect(session.productsForOrder(order), hasLength(8));
    expect(session.openTracking(order.id), isTrue);
    expect(session.reorder(order), isTrue);
    expect(session.view, BuyV2View.cart);
    expect(session.cartScope, BuyV2CartScope.shop);
    expect(session.cartLines, hasLength(8));
    expect(session.notice, 'Previous products are ready to edit.');
  });

  test('stale duplicate and cross-vertical identities fail atomically', () {
    final session = newSession();
    final shop = BuyV2Catalogue.products.firstWhere(
      (product) => product.destination == BuyV2Destination.shop,
    );
    final wholesale = BuyV2Catalogue.products.firstWhere(
      (product) => product.destination == BuyV2Destination.wholesale,
    );

    for (final ids in <List<String>>[
      [shop.id, 'missing-product'],
      [shop.id, shop.id],
      [shop.id, wholesale.id],
    ]) {
      final order = BuyV2Order(
        id: 'ORDER-${ids.join('-')}',
        destination: BuyV2Destination.shop,
        title: 'Owned order',
        itemSummary: 'Owned products',
        total: shop.price,
        partner: shop.seller,
        partnerType: shop.partnerRole,
        promise: shop.deliveryPromise,
        destinationLabel: 'Sardarpura · 342003',
        progress: 1,
        status: BuyV2OrderStatus.delivered,
        productIds: ids,
      );

      expect(session.reorder(order), isFalse, reason: ids.join(','));
      expect(session.cartLines, isEmpty, reason: ids.join(','));
    }
  });

  test('exact current-session order retains item and product return depth', () {
    final session = newSession();
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    expect(session.addProduct(product.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    final order = session.confirmedOrders.single;

    session.openOrders();
    expect(session.openTracking(order.id), isTrue);
    expect(session.openOrderItems(order.id), isTrue);
    expect(session.productsForOrder(order).map((item) => item.id), [
      product.id,
    ]);
    expect(session.openProduct(product.id), isTrue);
    expect(session.view, BuyV2View.product);
    session.goBack();
    expect(session.view, BuyV2View.orderItems);
    expect(session.selectedOrder.id, order.id);
    session.goBack();
    expect(session.view, BuyV2View.tracking);
    session.goBack();
    expect(session.destination, BuyV2Destination.orders);
    expect(session.view, BuyV2View.catalogue);
    expect(session.ordersTab, BuyV2OrdersTab.active);
  });

  test('Delivered tab and query survive tracking return and Back', () {
    final session = newSession();
    session.openOrders();
    session.showOrdersTab(BuyV2OrdersTab.delivered);
    session.updateQuery('MS-240741');
    expect(session.openTracking('MS-240741'), isTrue);

    session.returnToOrders();
    expect(session.destination, BuyV2Destination.orders);
    expect(session.view, BuyV2View.catalogue);
    expect(session.ordersTab, BuyV2OrdersTab.delivered);
    expect(session.query, 'MS-240741');
    expect(session.visibleOrders.map((order) => order.id), ['MS-240741']);

    expect(session.openTracking('MS-240741'), isTrue);
    session.goBack();
    expect(session.ordersTab, BuyV2OrdersTab.delivered);
    expect(session.query, 'MS-240741');
  });

  testWidgets(
    'compact large-text reduced-motion Delivered action stays reachable',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);
      final session = newSession();

      await tester.pumpWidget(app(session, reducedMotion: true));
      await tester.pump();
      session.openOrders();
      session.showOrdersTab(BuyV2OrdersTab.delivered);
      await tester.pump();

      final action = find.byKey(const ValueKey('buy-order-primary-MS-240741'));
      await tester.scrollUntilVisible(
        action,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(action, findsOneWidget);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
      final layoutException = tester.takeException();
      expect(
        layoutException,
        isNull,
        reason: layoutException is FlutterError
            ? layoutException.diagnostics
                  .map((diagnostic) => diagnostic.toStringDeep())
                  .join('\n')
            : '$layoutException',
      );

      await tester.tap(action);
      await tester.pump();
      expect(session.view, BuyV2View.tracking);
      expect(session.cartLines, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'R58.7 Orders responsive founder captures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final viewport in const [
        (
          size: Size(320, 568),
          safe: EdgeInsets.symmetric(vertical: 24),
          textScale: 1.0,
          reduced: false,
          label: '320x568-android',
        ),
        (
          size: Size(360, 800),
          safe: EdgeInsets.symmetric(vertical: 24),
          textScale: 1.0,
          reduced: false,
          label: '360x800-android',
        ),
        (
          size: Size(390, 844),
          safe: EdgeInsets.only(top: 47, bottom: 34),
          textScale: 1.0,
          reduced: false,
          label: '390x844-ios',
        ),
        (
          size: Size(430, 932),
          safe: EdgeInsets.only(top: 59, bottom: 34),
          textScale: 1.0,
          reduced: false,
          label: '430x932-ios',
        ),
        (
          size: Size(320, 568),
          safe: EdgeInsets.symmetric(vertical: 24),
          textScale: 1.4,
          reduced: true,
          label: '320x568-a11y140-reduced',
        ),
      ]) {
        tester.view.physicalSize = viewport.size;
        final session = newSession();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: viewport.safe,
                viewPadding: viewport.safe,
                textScaler: TextScaler.linear(viewport.textScale),
                disableAnimations: viewport.reduced,
              ),
              child: child!,
            ),
            home: BuyV2Screen(session: session),
          ),
        );
        await tester.pumpAndSettle();
        session.openOrders();
        session.showOrdersTab(BuyV2OrdersTab.delivered);
        await tester.pumpAndSettle();

        final action = find.byKey(
          const ValueKey('buy-order-primary-MS-240741'),
        );
        await tester.scrollUntilVisible(
          action,
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('buy-v2-screen')),
          matchesGoldenFile(
            'candidate_captures/buy-v2-r58-7-orders-${viewport.label}.png',
          ),
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        session.dispose();
      }
    },
    // Run explicitly with --run-skipped --update-goldens for evidence.
    skip: true,
  );
}
