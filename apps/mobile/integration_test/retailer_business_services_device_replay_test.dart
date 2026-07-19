import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_business_services_models.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            {
              AxisDirection.down,
              AxisDirection.up,
            }.contains(widget.axisDirection),
      );
      expect(scrollables, findsWidgets, reason: 'No scrollable for $key');
      final states = scrollables
          .evaluate()
          .whereType<StatefulElement>()
          .map((element) => element.state)
          .whereType<ScrollableState>();
      final scrollable = states.firstWhere(
        (state) =>
            state.position.maxScrollExtent > state.position.minScrollExtent,
      );
      scrollable.position.jumpTo(scrollable.position.minScrollExtent);
      await tester.pump();
      for (
        var attempt = 0;
        attempt < 40 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        scrollable.position.jumpTo(
          (scrollable.position.pixels + 260).clamp(
            scrollable.position.minScrollExtent,
            scrollable.position.maxScrollExtent,
          ),
        );
        await tester.pump();
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    return finder;
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = await reveal(tester, key);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    final finder = await reveal(tester, key);
    await tester.enterText(finder, value);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical retailer activates one capped campaign service and completes first setup',
    (tester) async {
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
      addTearDown(journey.dispose);
      addTearDown(retailer.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          retailerSession: retailer,
          initialLocation: '/app/retailer/services',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('business-services-screen')), findsOneWidget);
      await binding.takeScreenshot('retailer-93-business-services');

      await tapVisible(tester, const Key('business-service-ads'));
      await tapVisible(tester, const Key('business-service-view-plans'));
      expect(
        find.byKey(const Key('business-service-plan-screen')),
        findsOneWidget,
      );
      await binding.takeScreenshot('retailer-94-service-plan');

      await tapVisible(tester, const Key('business-plan-growth'));
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      await enter(tester, const Key('business-custom-limit-input'), '12000');
      await tapVisible(tester, const Key('business-custom-limit-save'));
      expect(retailer.businessServiceMonthlyLimit, 12000);
      await tapVisible(tester, const Key('business-plan-review'));

      expect(
        find.byKey(const Key('business-service-review-screen')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('business-payment-card'));
      await tapVisible(tester, const Key('business-service-terms-link'));
      await tapVisible(tester, const Key('business-commercial-consent'));
      await binding.takeScreenshot('retailer-95-service-review');
      await tapVisible(tester, const Key('business-service-activate'));

      expect(
        find.byKey(const Key('business-service-active-screen')),
        findsOneWidget,
      );
      final active = retailer.activeBusinessService(
        RetailerBusinessServiceType.ads,
      );
      expect(active, isNotNull);
      expect(active?.plan.id, 'growth');
      expect(active?.monthlyLimit, 12000);
      expect(active?.payment, RetailerBusinessPayment.card);
      await binding.takeScreenshot('retailer-96-service-active');

      await tapVisible(tester, const Key('business-setup-offer'));
      expect(active?.readySetup.contains('Offer'), isTrue);
      await tapVisible(tester, const Key('business-primary-work'));
      expect(
        find.byKey(const Key('business-primary-work-sheet')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('business-primary-work-complete'));
      expect(active?.readySetup.length, greaterThanOrEqualTo(3));
      await binding.takeScreenshot('retailer-96-first-campaign-ready');
    },
  );
}
