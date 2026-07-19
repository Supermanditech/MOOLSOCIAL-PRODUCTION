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
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      retailer.dispose();
    });
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

  testWidgets('Slow stock 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/home?view=stock&panel=recovery',
      golden: 'goldens/retailer-slow-stock-412x915.png',
    );
  });

  testWidgets('Retailer AI 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer?panel=ai',
      golden: 'goldens/retailer-ai-412x915.png',
    );
  });

  testWidgets('Staff access 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/settings/team',
      golden: 'goldens/retailer-staff-412x915.png',
    );
  });

  testWidgets('Store settings 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/settings',
      golden: 'goldens/retailer-settings-412x915.png',
    );
  });

  testWidgets('Customer issues 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/orders/issues',
      golden: 'goldens/retailer-issues-412x915.png',
    );
  });
}
