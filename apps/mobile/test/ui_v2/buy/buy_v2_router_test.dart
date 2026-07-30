import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountRoute(WidgetTester tester, String route) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Sardarpura',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    final buy = BuySession();
    addTearDown(journey.dispose);
    addTearDown(buy.dispose);
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(session: journey, buySession: buy, initialLocation: route),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('production Buy entry mounts V2 and never the legacy shell', (
    tester,
  ) async {
    await mountRoute(tester, '/app/buy');

    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.byKey(const Key('buy-catalog-screen')), findsNothing);
    for (final label in ['shop', 'wholesale', 'medicine', 'orders']) {
      expect(find.byKey(Key('buy-dock-$label')), findsOneWidget);
    }
  });

  testWidgets('historical Buy deep links resolve to V2 destinations', (
    tester,
  ) async {
    await mountRoute(tester, '/app/buy/medicine');

    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.text('Search medicines and wellness'), findsOneWidget);
    expect(find.byKey(const Key('buy-medicine-screen')), findsNothing);
  });

  testWidgets('query routes expose the approved Wholesale and Orders states', (
    tester,
  ) async {
    await mountRoute(tester, '/app/buy?sub=wholesale');
    expect(find.text('Search bulk products and suppliers'), findsOneWidget);

    await tester.tap(find.byKey(const Key('buy-dock-orders')));
    await tester.pumpAndSettle();
    expect(find.text('PURCHASES'), findsOneWidget);
    expect(find.text('Orders'), findsWidgets);
  });

  testWidgets('Buy account owner opens from a destination without losing V2', (
    tester,
  ) async {
    await mountRoute(tester, '/app/buy?sub=wholesale');
    expect(find.text('Search bulk products and suppliers'), findsOneWidget);

    await tester.tap(find.byKey(const Key('buy-open-account')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('buy-account-hub')), findsOneWidget);
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.text('Search bulk products and suppliers'), findsOneWidget);
  });

  testWidgets('Buy account is reachable from tertiary purchase states', (
    tester,
  ) async {
    for (final route in const [
      '/app/buy/product/s-rice',
      '/app/buy/order/MS-240782',
      '/app/buy/order/MS-240782/problem',
    ]) {
      await mountRoute(tester, route);
      expect(
        find.byKey(const Key('buy-open-account')),
        findsOneWidget,
        reason: route,
      );

      await tester.tap(find.byKey(const Key('buy-open-account')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('buy-account-hub')),
        findsOneWidget,
        reason: route,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('buy-v2-screen')),
        findsOneWidget,
        reason: route,
      );
    }
  });

  testWidgets('Screen 04 Mool Buy action opens only the native Buy V2', (
    tester,
  ) async {
    await mountRoute(tester, '/app/social');

    await tester.tap(find.byKey(const Key('screen04-mool')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('screen04-rail-buy')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.byKey(const Key('buy-catalog-screen')), findsNothing);
  });

  testWidgets('every historical Buy order route stays inside V2', (
    tester,
  ) async {
    for (final route in const [
      '/app/buy/order/MS-240782/collection',
      '/app/buy/order/MS-240782/collection-completed',
      '/app/buy/order/MS-240782/completed',
      '/app/buy/order/MS-240782/problem',
    ]) {
      await mountRoute(tester, route);
      expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
      expect(find.byKey(const Key('buy-catalog-screen')), findsNothing);
    }
  });

  testWidgets('all approved recovery routes mount their native state', (
    tester,
  ) async {
    for (final recovery in const [
      'price',
      'stock',
      'service',
      'payment',
      'network',
      'delay',
    ]) {
      await mountRoute(tester, '/app/buy?view=recovery&recovery=$recovery');
      expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
      expect(find.byKey(const Key('buy-recovery-primary')), findsOneWidget);
    }
  });

  testWidgets(
    'stale Buy deep links never substitute another product or order',
    (tester) async {
      await mountRoute(tester, '/app/buy/product/missing-product');

      expect(find.text('This product could not be found.'), findsOneWidget);
      expect(find.byKey(const Key('buy-product-detail')), findsNothing);

      await mountRoute(tester, '/app/buy/order/missing-order');

      expect(find.text('This order could not be found.'), findsOneWidget);
      expect(find.byKey(const Key('buy-order-tracking')), findsNothing);
      expect(find.text('PURCHASES'), findsOneWidget);
    },
  );
}
