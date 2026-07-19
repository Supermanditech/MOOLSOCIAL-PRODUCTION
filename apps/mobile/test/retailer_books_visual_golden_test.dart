import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';

void main() {
  Future<void> verifyScreen(
    WidgetTester tester, {
    required String route,
    required String golden,
  }) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    final retailer = RetailerSession();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      retailer.dispose();
    });
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        retailerSession: retailer,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile(golden));
  }

  testWidgets('Business Book 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/books',
      golden: 'goldens/retailer-business-book-412x915.png',
    );
  });

  testWidgets('Stock Statement 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/books/stock',
      golden: 'goldens/retailer-stock-statement-412x915.png',
    );
  });

  testWidgets('Money control 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/books/money',
      golden: 'goldens/retailer-money-control-412x915.png',
    );
  });
}
