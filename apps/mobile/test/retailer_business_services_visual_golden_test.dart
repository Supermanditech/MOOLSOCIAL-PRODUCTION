import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_business_services_models.dart';
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

  testWidgets('Business Services 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/services',
      golden: 'goldens/retailer-business-services-412x915.png',
    );
  });

  testWidgets('Business Service plan 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/services/growth',
      golden: 'goldens/retailer-business-service-plan-412x915.png',
    );
  });

  testWidgets('Business Service review 412x915 visual baseline', (
    tester,
  ) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/services/ads?stage=review',
      golden: 'goldens/retailer-business-service-review-412x915.png',
      configure: (session) {
        final service = retailerBusinessServiceByName('ads');
        session.selectBusinessService(service);
        session.selectBusinessServicePlan(service.plans.last);
        session.setBusinessServiceLimit(12000, custom: true);
        session.selectBusinessServicePayment(RetailerBusinessPayment.card);
      },
    );
  });

  testWidgets('Active Business Service 412x915 visual baseline', (
    tester,
  ) async {
    await verifyScreen(
      tester,
      route: '/app/retailer/services/ads?stage=active',
      golden: 'goldens/retailer-business-service-active-412x915.png',
      configure: (session) {
        final service = retailerBusinessServiceByName('ads');
        final plan = service.plans.last;
        session.selectBusinessService(service);
        session.selectBusinessServicePlan(plan);
        session.setBusinessServiceLimit(12000, custom: true);
        session.selectBusinessServicePayment(RetailerBusinessPayment.card);
        session.activeBusinessServices[service.type] =
            RetailerActiveBusinessService(
              id: 'MS-BS-240711-ADS',
              offering: service,
              plan: plan,
              monthlyLimit: 12000,
              payment: RetailerBusinessPayment.card,
              readySetup: {'Budget', 'Report'},
            );
      },
    );
  });
}
