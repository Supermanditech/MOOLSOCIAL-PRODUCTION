import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/manufacturer/manufacturer_session.dart';

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
    final manufacturer = ManufacturerSession();
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      manufacturer.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        manufacturerSession: manufacturer,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile(golden));
  }

  testWidgets('Manufacturer home 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/manufacturer',
      golden: 'goldens/manufacturer-107-home-412x915.png',
    );
  });

  testWidgets('Manufacturer business book 412x915 visual baseline', (
    tester,
  ) async {
    await verifyScreen(
      tester,
      route: '/app/manufacturer/books',
      golden: 'goldens/manufacturer-108-book-412x915.png',
    );
  });

  testWidgets('Manufacturer catalogue 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/manufacturer/catalogue?mode=master',
      golden: 'goldens/manufacturer-109-catalogue-412x915.png',
    );
  });

  testWidgets('Manufacturer order review 412x915 visual baseline', (
    tester,
  ) async {
    await verifyScreen(
      tester,
      route: '/app/manufacturer/orders/review',
      golden: 'goldens/manufacturer-110-order-412x915.png',
    );
  });

  testWidgets('Manufacturer procurement 412x915 visual baseline', (
    tester,
  ) async {
    await verifyScreen(
      tester,
      route: '/app/manufacturer/purchases?tab=cart',
      golden: 'goldens/manufacturer-111-procurement-412x915.png',
    );
  });

  testWidgets('Manufacturer dispatch 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/manufacturer/dispatch?tab=transit',
      golden: 'goldens/manufacturer-112-dispatch-412x915.png',
    );
  });

  testWidgets('Manufacturer growth 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/manufacturer/growth?tab=demand',
      golden: 'goldens/manufacturer-113-growth-412x915.png',
    );
  });

  testWidgets('Manufacturer control 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/manufacturer/control?tab=team',
      golden: 'goldens/manufacturer-114-control-412x915.png',
    );
  });

  testWidgets('Manufacturer services 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/manufacturer/services?tab=active',
      golden: 'goldens/manufacturer-115-services-412x915.png',
    );
  });
}
