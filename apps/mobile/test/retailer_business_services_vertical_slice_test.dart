import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_business_services_models.dart';
import 'package:moolsocial/features/retailer/retailer_business_services_services.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';

void main() {
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );

  Future<T> completeFuture<T>(WidgetTester tester, Future<T> future) async {
    await tester.pump(const Duration(milliseconds: 40));
    final result = await future;
    await settle(tester);
    return result;
  }

  Future<JourneySession> readyJourney() async {
    final session = JourneySession(
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
    await session.start();
    return session;
  }

  Future<RetailerSession> mount(
    WidgetTester tester, {
    required String route,
    RetailerSession? retailerSession,
    Size size = const Size(412, 915),
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    final journey = await readyJourney();
    final retailer = retailerSession ?? RetailerSession();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      retailer.dispose();
    });
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MoolSocialApp(
          key: UniqueKey(),
          session: journey,
          retailerSession: retailer,
          initialLocation: route,
        ),
      ),
    );
    await settle(tester);
    return retailer;
  }

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
          (scrollable.position.pixels + 240).clamp(
            scrollable.position.minScrollExtent,
            scrollable.position.maxScrollExtent,
          ),
        );
        await tester.pump();
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing target $key');
    await tester.ensureVisible(finder);
    await settle(tester);
    return finder;
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = await reveal(tester, key);
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    final finder = await reveal(tester, key);
    await tester.enterText(finder, value);
    await settle(tester);
  }

  Future<void> dismissSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(8, 90));
    await settle(tester);
  }

  Future<RetailerSession> activeService(
    WidgetTester tester,
    RetailerBusinessServiceType type, {
    ReviewRetailerBusinessServicesGateway? gateway,
  }) async {
    final retailer = RetailerSession(businessServicesGateway: gateway);
    final service = retailerBusinessServiceByName(type.name);
    retailer.selectBusinessService(service);
    retailer.setBusinessServiceCommercialConsent(true);
    if (service.requiresDataConsent) {
      retailer.setBusinessServiceDataConsent(true);
    }
    expect(await tester.runAsync(retailer.activateBusinessService), isTrue);
    return retailer;
  }

  testWidgets(
    'screen 93 completes every service detail, dismiss path, help, plan route and exact refresh replay',
    (tester) async {
      final gateway = ReviewRetailerBusinessServicesGateway()
        ..failRefreshCatalogue = true;
      final retailer = RetailerSession(businessServicesGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/services',
        retailerSession: retailer,
      );

      expect(find.byKey(const Key('business-services-screen')), findsOneWidget);
      for (final service in retailerBusinessServiceOfferings) {
        await tapVisible(tester, Key('business-service-${service.type.name}'));
        expect(
          find.byKey(Key('business-service-detail-${service.type.name}')),
          findsOneWidget,
        );
        expect(find.text(service.title), findsWidgets);
        expect(find.text(service.variableCharge), findsWidgets);
        await tapVisible(tester, const Key('business-service-not-now'));
      }

      await tapVisible(tester, const Key('business-services-help'));
      expect(
        find.byKey(const Key('business-service-detail-growth')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('business-service-close'));

      await tapVisible(tester, const Key('business-service-delivery'));
      await tapVisible(tester, const Key('business-service-view-plans'));
      expect(
        find.byKey(const Key('business-service-plan-screen')),
        findsOneWidget,
      );

      await tapVisible(tester, const Key('retailer-back'));
      expect(
        await completeFuture(tester, retailer.refreshBusinessServices()),
        isFalse,
      );
      expect(find.textContaining('could not refresh'), findsOneWidget);
      expect(
        await completeFuture(tester, retailer.refreshBusinessServices()),
        isTrue,
      );
      expect(gateway.refreshCatalogueCalls, 2);
    },
  );

  testWidgets(
    'screen 94 selects every plan and limit, validates custom amount and retains choice after plan-load failure',
    (tester) async {
      final gateway = ReviewRetailerBusinessServicesGateway()
        ..failLoadPlans = true;
      final retailer = RetailerSession(businessServicesGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/services/growth',
        retailerSession: retailer,
      );

      expect(find.textContaining('could not load'), findsOneWidget);
      expect(retailer.selectedBusinessPlan?.id, 'starter');
      expect(
        await completeFuture(
          tester,
          retailer.loadBusinessServicePlans(
            retailerBusinessServiceByName('growth'),
          ),
        ),
        isTrue,
      );
      expect(gateway.loadPlansCalls, 2);

      await tapVisible(tester, const Key('business-plan-growth'));
      expect(retailer.selectedBusinessPlan?.id, 'growth');
      expect(find.text('₹999 + GST'), findsWidgets);

      await tester.tap(find.text('₹1,500'));
      await settle(tester);
      expect(retailer.businessServiceMonthlyLimit, 1500);

      await tester.tap(find.text('Custom'));
      await settle(tester);
      expect(
        find.byKey(const Key('business-custom-limit-sheet')),
        findsOneWidget,
      );
      await enter(tester, const Key('business-custom-limit-input'), 'abc');
      await tapVisible(tester, const Key('business-custom-limit-save'));
      expect(find.text('Enter a valid amount.'), findsOneWidget);
      await enter(tester, const Key('business-custom-limit-input'), '500');
      await tapVisible(tester, const Key('business-custom-limit-save'));
      expect(find.textContaining('at least ₹1,000'), findsWidgets);
      await enter(tester, const Key('business-custom-limit-input'), '12500');
      await tapVisible(tester, const Key('business-custom-limit-save'));
      expect(retailer.businessServiceMonthlyLimit, 12500);
      expect(retailer.businessServiceCustomLimit, isTrue);
      expect(find.text('₹12,500'), findsWidgets);

      await tapVisible(tester, const Key('business-plan-help'));
      expect(find.text('Charge protection'), findsOneWidget);
      await dismissSheet(tester);

      await tapVisible(tester, const Key('business-plan-review'));
      expect(
        find.byKey(const Key('business-service-review-screen')),
        findsOneWidget,
      );
      expect(find.text('₹12,500'), findsWidgets);
    },
  );

  testWidgets(
    'screen 95 enforces consent, supports every payment and replays one failed activation without duplicate charge',
    (tester) async {
      final gateway = ReviewRetailerBusinessServicesGateway()
        ..failActivate = true;
      final retailer = RetailerSession(businessServicesGateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/services/delivery?stage=review',
        retailerSession: retailer,
      );

      final activate = tester.widget<FilledButton>(
        find.byKey(const Key('business-service-activate')),
      );
      expect(activate.onPressed, isNull);

      for (final payment in RetailerBusinessPayment.values) {
        await tapVisible(tester, Key('business-payment-${payment.name}'));
        expect(retailer.businessServicePayment, payment);
      }
      await tapVisible(tester, const Key('business-payment-upi'));
      await tapVisible(tester, const Key('business-service-terms-link'));
      expect(find.byKey(const Key('business-terms-reviewed')), findsOneWidget);
      await tapVisible(tester, const Key('business-commercial-consent'));

      await tapVisible(tester, const Key('business-service-activate'));
      expect(find.textContaining('Payment was not completed'), findsOneWidget);
      expect(retailer.activeBusinessServiceCount, 0);
      expect(retailer.businessServiceCommercialConsent, isTrue);
      expect(retailer.businessServicePayment, RetailerBusinessPayment.upi);

      await tapVisible(tester, const Key('business-service-activate'));
      expect(
        find.byKey(const Key('business-service-active-screen')),
        findsOneWidget,
      );
      expect(retailer.activeBusinessServiceCount, 1);
      expect(gateway.activateCalls, 2);

      expect(
        await completeFuture(tester, retailer.activateBusinessService()),
        isTrue,
      );
      expect(gateway.activateCalls, 2);
      expect(retailer.activeBusinessServiceCount, 1);
      expect(find.textContaining('No duplicate'), findsOneWidget);
    },
  );

  testWidgets(
    'screen 95 requires separate purpose-limited data consent only for Tax and Books',
    (tester) async {
      final retailer = await mount(
        tester,
        route: '/app/retailer/services/books?stage=review',
      );
      await reveal(tester, const Key('business-data-consent'));
      await tapVisible(tester, const Key('business-commercial-consent'));
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('business-service-activate')),
            )
            .onPressed,
        isNull,
      );
      await tapVisible(tester, const Key('business-data-consent'));
      expect(retailer.businessServiceCanActivate, isTrue);
      await tapVisible(tester, const Key('business-service-activate'));
      expect(retailer.activeBusinessServiceCount, 1);
      expect(
        find.byKey(const Key('business-service-active-screen')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'screen 96 completes setup with exact retry, opens useful work, support and cancellation lifecycle',
    (tester) async {
      final gateway = ReviewRetailerBusinessServicesGateway()
        ..failSetup = true
        ..failSupport = true
        ..failCancel = true;
      final retailer = await activeService(
        tester,
        RetailerBusinessServiceType.growth,
        gateway: gateway,
      );
      await mount(
        tester,
        route: '/app/retailer/services/growth?stage=active',
        retailerSession: retailer,
      );

      expect(
        find.byKey(const Key('business-service-active-screen')),
        findsOneWidget,
      );
      expect(find.textContaining('MS-BS-240711-GROWTH'), findsOneWidget);
      await tapVisible(tester, const Key('business-setup-offer'));
      expect(find.textContaining('setup was not saved'), findsOneWidget);
      expect(
        retailer
            .activeBusinessService(RetailerBusinessServiceType.growth)
            ?.readySetup
            .contains('Offer'),
        isFalse,
      );
      await tapVisible(tester, const Key('business-setup-offer'));
      expect(
        retailer
            .activeBusinessService(RetailerBusinessServiceType.growth)
            ?.readySetup
            .contains('Offer'),
        isTrue,
      );
      expect(gateway.setupCalls, 2);

      await tapVisible(tester, const Key('business-primary-work'));
      expect(
        find.byKey(const Key('business-primary-work-sheet')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('business-primary-work-complete'));
      expect(
        retailer
            .activeBusinessService(RetailerBusinessServiceType.growth)
            ?.readySetup
            .contains('Team'),
        isTrue,
      );

      await tapVisible(tester, const Key('business-service-support'));
      expect(find.textContaining('could not open'), findsOneWidget);
      await tapVisible(tester, const Key('business-service-support'));
      expect(find.text('Order Support'), findsWidgets);
      expect(gateway.supportCalls, 2);

      await tapVisible(tester, const Key('chat-back'));
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      await tapVisible(tester, const Key('chat-back'));
      await tapVisible(tester, const Key('business-service-menu'));
      await tapVisible(tester, const Key('business-menu-cancel'));
      await tapVisible(tester, const Key('business-cancel-confirm'));
      expect(find.textContaining('not completed'), findsOneWidget);
      expect(retailer.activeBusinessServiceCount, 1);
      await tapVisible(tester, const Key('business-cancel-confirm'));
      expect(retailer.activeBusinessServiceCount, 0);
      expect(find.byKey(const Key('business-services-screen')), findsOneWidget);
      expect(gateway.cancelCalls, 2);
    },
  );

  testWidgets(
    'all four services activate independently and keep separate plan entitlements',
    (tester) async {
      final gateway = ReviewRetailerBusinessServicesGateway();
      final retailer = RetailerSession(businessServicesGateway: gateway);
      addTearDown(retailer.dispose);
      for (final service in retailerBusinessServiceOfferings) {
        retailer.selectBusinessService(service);
        retailer.setBusinessServiceCommercialConsent(true);
        if (service.requiresDataConsent) {
          retailer.setBusinessServiceDataConsent(true);
        }
        expect(
          await tester.runAsync(retailer.activateBusinessService),
          isTrue,
          reason: service.title,
        );
      }
      expect(retailer.activeBusinessServiceCount, 4);
      expect(gateway.activateCalls, 4);
      expect(
        retailer.activeBusinessService(RetailerBusinessServiceType.delivery),
        isNotNull,
      );
      expect(
        retailer.activeBusinessService(RetailerBusinessServiceType.growth),
        isNotNull,
      );
      expect(
        retailer.activeBusinessService(RetailerBusinessServiceType.books),
        isNotNull,
      );
      expect(
        retailer.activeBusinessService(RetailerBusinessServiceType.ads),
        isNotNull,
      );
    },
  );

  testWidgets(
    'services protect role and offline state and fit compact accessible screens',
    (tester) async {
      final retailer = RetailerSession()
        ..businessServicesAuthorized = false
        ..setBusinessServicesOnline(false);
      await mount(
        tester,
        route: '/app/retailer/services',
        retailerSession: retailer,
        size: const Size(320, 700),
        textScale: 1.3,
      );
      expect(
        find.byKey(const Key('business-services-role-denied')),
        findsOneWidget,
      );

      retailer.businessServicesAuthorized = true;
      retailer.notifyListeners();
      await settle(tester);
      expect(find.byKey(const Key('business-services-screen')), findsOneWidget);
      expect(await retailer.refreshBusinessServices(), isFalse);

      final service = retailerBusinessServiceByName('delivery');
      retailer.selectBusinessService(service);
      retailer.setBusinessServiceCommercialConsent(true);
      expect(await retailer.activateBusinessService(), isFalse);
      expect(retailer.activeBusinessServiceCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'retailer home Business Services card opens the production service hub',
    (tester) async {
      await mount(tester, route: '/app/retailer/home');
      await tapVisible(tester, const Key('retailer-business-services'));
      expect(find.byKey(const Key('business-services-screen')), findsOneWidget);
    },
  );
}
