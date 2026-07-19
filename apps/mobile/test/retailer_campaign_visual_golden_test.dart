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
    void Function(RetailerSession session)? configure,
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
    configure?.call(retailer);
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

  testWidgets('Customers 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/customers',
      golden: 'goldens/retailer-customers-412x915.png',
    );
  });

  testWidgets('Customer detail 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/customers/sharma',
      golden: 'goldens/retailer-customer-detail-412x915.png',
    );
  });

  testWidgets('Campaigns 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/campaigns',
      golden: 'goldens/retailer-campaigns-412x915.png',
    );
  });

  testWidgets('Campaign review 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/campaigns/new',
      golden: 'goldens/retailer-campaign-review-412x915.png',
      configure: (session) => session.campaignBuilderStep = 3,
    );
  });
}
