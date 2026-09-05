import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_shopping_alerts.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scenario in [(true, 1.4), (false, 1.4), (true, 2.0)]) {
    final (systemBack, textScale) = scenario;
    testWidgets(
      'R66 033 alert return retains sheets and scroll system=$systemBack scale=$textScale',
      (tester) async {
        final core = BuySession();
        final adapter = _AlertsAdapter();
        final session = BuyV2Session(
          core: core,
          shoppingAlertsAdapter: adapter,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final order = session.orders.first;
        adapter.snapshot = BuyV2ShoppingAlertsSnapshot(
          state: BuyV2ShoppingAlertsState.ready,
          sourceId: 'shopping-alert-service',
          alerts: [
            for (var i = 0; i < 18; i++)
              BuyV2ShoppingAlert(
                id: 'delivery-$i',
                kind: BuyV2ShoppingAlertKind.delivery,
                title: 'Delivery update $i',
                detail: 'Review your order delivery.',
                updatedLabel: 'Today',
                destination: BuyV2Destination.orders,
                orderId: order.id,
              ),
          ],
        );
        final router = await _mountAlertRouter(
          tester,
          session,
          textScale: textScale,
        );
        addTearDown(router.dispose);
        session.showOrdersTab(BuyV2OrdersTab.delivered);
        await tester.pumpAndSettle();
        unawaited(
          showBuyV2ShoppingSettings(
            tester.element(find.byType(BuyV2Screen)),
            session,
          ),
        );
        await tester.pumpAndSettle();
        final settingsRow = find.byKey(
          const ValueKey('buy-settings-shopping-alerts'),
        );
        await tester.ensureVisible(settingsRow);
        await tester.pumpAndSettle();
        final settingsPosition = Scrollable.of(
          tester.element(settingsRow),
        ).position;
        final settingsOffset = settingsPosition.pixels;
        await tester.tap(settingsRow);
        await tester.pumpAndSettle();
        final alertRow = find.byKey(
          const ValueKey('buy-shopping-alert-delivery-10'),
        );
        await tester.ensureVisible(alertRow);
        await tester.pumpAndSettle();
        final alertsPosition = Scrollable.of(tester.element(alertRow)).position;
        final alertsOffset = alertsPosition.pixels;
        expect(alertsOffset, greaterThan(0));
        for (var visit = 0; visit < 2; visit++) {
          await tester.tap(alertRow);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.tracking);
          expect(session.selectedOrderOrNull?.id, order.id);
          if (systemBack) {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tap(
              find.byKey(const ValueKey('buy-tracking-return-orders')),
            );
          }
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-shopping-alerts')),
            findsOneWidget,
          );
          expect(alertsPosition.pixels, alertsOffset);
          expect(session.view, BuyV2View.catalogue);
          expect(session.destination, BuyV2Destination.orders);
          expect(session.ordersTab, BuyV2OrdersTab.delivered);
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-shopping-settings')),
          findsOneWidget,
        );
        expect(settingsPosition.pixels, settingsOffset);
        final help = find.byKey(const ValueKey('buy-settings-help'));
        await tester.ensureVisible(help);
        await tester.pumpAndSettle();
        final helpOffset = settingsPosition.pixels;
        await tester.tap(help);
        await tester.pumpAndSettle();
        expect(find.text('Help destination'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-shopping-settings')),
          findsOneWidget,
        );
        expect(settingsPosition.pixels, helpOffset);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final productAlert in [true, false]) {
    testWidgets(
      'R66 033 product and offer alerts return product=$productAlert',
      (tester) async {
        final core = BuySession();
        final adapter = _AlertsAdapter();
        final session = BuyV2Session(
          core: core,
          shoppingAlertsAdapter: adapter,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        adapter.snapshot = BuyV2ShoppingAlertsSnapshot(
          state: BuyV2ShoppingAlertsState.ready,
          sourceId: 'shopping-alert-service',
          alerts: [
            BuyV2ShoppingAlert(
              id: 'target',
              kind: productAlert
                  ? BuyV2ShoppingAlertKind.priceDrop
                  : BuyV2ShoppingAlertKind.offer,
              title: productAlert ? 'Price update' : 'Shop offers',
              detail: 'Review current prices.',
              updatedLabel: 'Today',
              destination: BuyV2Destination.shop,
              productId: productAlert ? 's-milk' : null,
            ),
          ],
        );
        final router = await _mountAlertRouter(tester, session);
        addTearDown(router.dispose);
        session.showOrdersTab(BuyV2OrdersTab.delivered);
        await tester.pumpAndSettle();
        unawaited(
          showBuyV2ShoppingAlerts(
            tester.element(find.byType(BuyV2Screen)),
            session,
          ),
        );
        await tester.pumpAndSettle();
        for (var visit = 0; visit < 2; visit++) {
          await tester.tap(
            find.byKey(const ValueKey('buy-shopping-alert-target')),
          );
          await tester.pumpAndSettle();
          expect(session.destination, BuyV2Destination.shop);
          expect(
            session.view,
            productAlert ? BuyV2View.product : BuyV2View.catalogue,
          );
          if (productAlert) {
            expect(session.selectedProduct?.id, 's-milk');
            expect(find.text('Shopping alerts'), findsOneWidget);
          }
          if (productAlert && visit == 1) {
            await tester.tap(find.text('Shopping alerts'));
          } else {
            await tester.binding.handlePopRoute();
          }
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-shopping-alerts')),
            findsOneWidget,
          );
          expect(session.destination, BuyV2Destination.orders);
          expect(session.ordersTab, BuyV2OrdersTab.delivered);
          expect(session.view, BuyV2View.catalogue);
        }
        await tester.tap(
          find.byKey(const ValueKey('buy-shopping-alert-target')),
        );
        await tester.pumpAndSettle();
        session.openDestination(BuyV2Destination.wholesale);
        router.go('/app/ask');
        await tester.pumpAndSettle();
        expect(find.text('Help destination'), findsOneWidget);
        expect(session.destination, BuyV2Destination.wholesale);
        expect(session.hasShoppingAlertReturnOrigin, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  test(
    'R66 033 direct order Back and abandoned alert cannot restore stale state',
    () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final order = session.orders.first;
      session.showOrdersTab(BuyV2OrdersTab.delivered);
      session.openTracking(order.id);
      session.goBack();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.ordersTab, BuyV2OrdersTab.delivered);
      expect(session.view, BuyV2View.catalogue);
      final alert = BuyV2ShoppingAlert(
        id: 'delivery',
        kind: BuyV2ShoppingAlertKind.delivery,
        title: 'Delivery update',
        detail: 'Review your order.',
        updatedLabel: 'Today',
        destination: BuyV2Destination.orders,
        orderId: order.id,
      );
      final oldVisit = session.beginShoppingAlertVisit(alert, () {});
      session.openTracking(order.id);
      session.finishShoppingAlertVisit(oldVisit, restore: false);
      session.openDestination(BuyV2Destination.wholesale);
      final nextVisit = session.beginShoppingAlertVisit(alert, () {});
      session.openTracking(order.id);
      session.finishShoppingAlertVisit(oldVisit, restore: true);
      expect(session.view, BuyV2View.tracking);
      session.finishShoppingAlertVisit(nextVisit, restore: true);
      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.view, BuyV2View.catalogue);
      expect(session.hasShoppingAlertReturnOrigin, isFalse);
    },
  );

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

Future<GoRouter> _mountAlertRouter(
  WidgetTester tester,
  BuyV2Session session, {
  double textScale = 1.4,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 700);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final router = GoRouter(
    initialLocation: '/app/buy?sub=orders',
    routes: [
      GoRoute(
        path: '/app/buy',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return BuyV2Screen(
            key: state.pageKey,
            session: session,
            initialDestination: query['sub'] == 'orders'
                ? BuyV2Destination.orders
                : BuyV2Destination.shop,
            initialView: query['view'] == 'tracking'
                ? BuyV2View.tracking
                : query['view'] == 'product'
                ? BuyV2View.product
                : BuyV2View.catalogue,
            initialOffersActive: query['sub'] == 'offers',
            orderId: query['order'],
            productId: query['product'],
            onExit: () => context.pop(),
          );
        },
      ),
      GoRoute(
        path: '/app/ask',
        builder: (_, _) => const Scaffold(body: Text('Help destination')),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
  return router;
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
