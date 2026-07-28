import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountRoute(WidgetTester tester, String route) async {
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
    expect(find.text('Medicines & health'), findsOneWidget);
    expect(find.byKey(const Key('buy-medicine-screen')), findsNothing);
  });

  testWidgets('query routes expose the approved Wholesale and Orders states', (
    tester,
  ) async {
    await mountRoute(tester, '/app/buy?sub=wholesale');
    expect(find.text('Wholesale prices'), findsOneWidget);

    await tester.tap(find.byKey(const Key('buy-dock-orders')));
    await tester.pumpAndSettle();
    expect(find.text('PURCHASES AND DELIVERY'), findsOneWidget);
    expect(find.text('Orders'), findsWidgets);
  });
}
