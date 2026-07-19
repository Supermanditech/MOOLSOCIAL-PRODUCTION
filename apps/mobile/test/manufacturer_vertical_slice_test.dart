import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/manufacturer/manufacturer_models.dart';
import 'package:moolsocial/features/manufacturer/manufacturer_services.dart';
import 'package:moolsocial/features/manufacturer/manufacturer_session.dart';

void main() {
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );

  Future<ManufacturerSession> mount(
    WidgetTester tester, {
    required String route,
    ManufacturerSession? manufacturerSession,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
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
    final manufacturer = manufacturerSession ?? ManufacturerSession();
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      manufacturer.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        manufacturerSession: manufacturer,
        initialLocation: route,
      ),
    );
    await settle(tester);
    return manufacturer;
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
      for (final state
          in scrollables
              .evaluate()
              .whereType<StatefulElement>()
              .map((element) => element.state)
              .whereType<ScrollableState>()) {
        if (state.position.maxScrollExtent <= state.position.minScrollExtent) {
          continue;
        }
        state.position.jumpTo(state.position.minScrollExtent);
        await tester.pump();
        for (
          var attempt = 0;
          attempt < 50 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          state.position.jumpTo(
            (state.position.pixels + 260).clamp(
              state.position.minScrollExtent,
              state.position.maxScrollExtent,
            ),
          );
          await tester.pump();
        }
        if (finder.evaluate().isNotEmpty) break;
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing target $key');
    await tester.ensureVisible(finder);
    await settle(tester);
    return finder;
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await settle(tester);
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    await tester.enterText(await reveal(tester, key), value);
    await settle(tester);
  }

  Future<void> go(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await settle(tester);
  }

  Future<void> closeSheet(WidgetTester tester, Key doneKey) async {
    await tap(tester, doneKey);
  }

  testWidgets(
    'screen 107 exposes every operating owner, filters orders and exactly retries supply',
    (tester) async {
      final gateway = ReviewManufacturerGateway()..failSupply = true;
      final session = ManufacturerSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/manufacturer',
        manufacturerSession: session,
      );
      expect(find.byKey(const Key('manufacturer-home-screen')), findsOneWidget);
      await tap(tester, const Key('manufacturer-alerts'));
      expect(session.noticeMessage, contains('6 orders'));
      await tap(tester, const Key('manufacturer-supply-toggle'));
      expect(session.supplyOn, isTrue);
      await tap(tester, const Key('manufacturer-supply-toggle'));
      expect(session.supplyOn, isFalse);
      expect(gateway.supplyCalls, 2);
      await tap(tester, const Key('manufacturer-scan'));
      await closeSheet(tester, const Key('manufacturer-sheet-done'));
      await tap(tester, const Key('manufacturer-voice'));
      expect(session.searchQuery, 'Sunflower Oil');
      session.clearSearch();
      await settle(tester);

      final routeOwners = <Key, String>{
        const Key('manufacturer-business-book'): '/app/manufacturer/books',
        const Key('manufacturer-classification'):
            '/app/manufacturer/control?tab=settings',
        const Key('manufacturer-view-order'): '/app/manufacturer/orders/review',
        const Key('manufacturer-add-products'):
            '/app/manufacturer/catalogue?mode=master',
        const Key('manufacturer-update-stock'): '/app/manufacturer/catalogue',
        const Key('manufacturer-dispatch'): '/app/manufacturer/dispatch',
        const Key('manufacturer-gst-invoice'): '/app/manufacturer/books',
        const Key('manufacturer-services'): '/app/manufacturer/services',
        const Key('manufacturer-demand-pool'):
            '/app/manufacturer/growth?tab=demand',
        const Key('manufacturer-input-matches'): '/app/manufacturer/purchases',
      };
      for (final entry in routeOwners.entries) {
        await go(tester, '/app/manufacturer');
        await tap(tester, entry.key);
        expect(
          GoRouterState.of(
            tester.element(find.byType(Scaffold).first),
          ).uri.toString(),
          entry.value,
        );
      }

      await go(tester, '/app/manufacturer?view=orders');
      expect(
        find.byKey(const Key('manufacturer-orders-screen')),
        findsOneWidget,
      );
      for (final filter in [
        'need-action',
        'retailers',
        'hotels',
        'restaurants',
        'distributors',
      ]) {
        await tap(tester, Key('manufacturer-order-filter-$filter'));
      }
      await enter(tester, const Key('manufacturer-search'), 'no such buyer');
      expect(
        find.byKey(const Key('manufacturer-orders-empty')),
        findsOneWidget,
      );
      await tap(tester, const Key('manufacturer-orders-clear'));
      for (final order in reviewManufacturerOrders) {
        expect(
          find.byKey(Key('manufacturer-order-${order.id}')),
          findsOneWidget,
        );
      }
      await tap(tester, const Key('manufacturer-export-orders'));
      expect(session.noticeMessage, contains('export'));
    },
  );

  testWidgets(
    'screen 108 opens every book, tool, period, position and tax boundary',
    (tester) async {
      final session = await mount(tester, route: '/app/manufacturer/books');
      expect(find.byKey(const Key('manufacturer-book-screen')), findsOneWidget);
      await tap(tester, const Key('manufacturer-book-period'));
      await tap(tester, const Key('manufacturer-book-period-this-week'));
      expect(session.bookPeriod, 'This week');
      await tap(tester, const Key('manufacturer-book-position'));
      expect(session.showBookPosition, isTrue);
      await tap(tester, const Key('manufacturer-book-attention'));
      await closeSheet(tester, const Key('manufacturer-detail-done'));
      for (final row in reviewManufacturerBookRows) {
        await tap(tester, Key('manufacturer-book-${row.id}'));
        expect(session.selectedBookId, row.id);
        await closeSheet(tester, const Key('manufacturer-detail-done'));
      }
      for (final tool in [
        'cash',
        'expenses',
        'notes',
        'reconcile',
        'documents',
        'reports',
      ]) {
        await tap(tester, Key('manufacturer-book-tool-$tool'));
        await closeSheet(tester, const Key('manufacturer-detail-done'));
      }
      await tap(tester, const Key('manufacturer-book-tax'));
      expect(
        find.byKey(const Key('manufacturer-services-screen')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'screen 109 covers master, stock, import tools, invalid product, failure replay and duplicate',
    (tester) async {
      final gateway = ReviewManufacturerGateway()..failProduct = true;
      final session = ManufacturerSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/manufacturer/catalogue?mode=master',
        manufacturerSession: session,
      );
      expect(
        find.byKey(const Key('manufacturer-catalogue-screen')),
        findsOneWidget,
      );
      for (final tool in ['master', 'template', 'scan', 'not-listed']) {
        await tap(tester, Key('manufacturer-catalogue-tool-$tool'));
        await closeSheet(tester, const Key('manufacturer-tool-done'));
      }
      await tap(tester, const Key('manufacturer-catalogue-filters'));
      await tap(
        tester,
        const Key('manufacturer-catalogue-filter-needs-action'),
      );
      await tap(tester, const Key('manufacturer-product-masala-tea'));
      expect(
        find.byKey(const Key('manufacturer-product-sheet')),
        findsOneWidget,
      );
      await enter(tester, const Key('manufacturer-product-quantity'), '100');
      await enter(tester, const Key('manufacturer-product-price'), '188');
      await enter(tester, const Key('manufacturer-product-moq'), '101');
      await tap(tester, const Key('manufacturer-product-publish'));
      expect(gateway.productCalls, 0);
      await enter(tester, const Key('manufacturer-product-moq'), '20');
      await tap(tester, const Key('manufacturer-product-input-map'));
      await tap(tester, const Key('manufacturer-product-publish'));
      expect(session.productPublishedId, isNull);
      await tap(tester, const Key('manufacturer-product-publish'));
      expect(session.productPublishedId, 'SKU-109-0719');
      expect(gateway.productCalls, 2);
      expect(await tester.runAsync(session.publishProduct), isTrue);
      expect(gateway.productCalls, 2);

      await go(tester, '/app/manufacturer/catalogue');
      await enter(tester, const Key('manufacturer-search'), 'not found');
      expect(
        find.byKey(const Key('manufacturer-catalogue-empty')),
        findsOneWidget,
      );
      await tap(tester, const Key('manufacturer-catalogue-clear'));
      expect(
        find.byKey(const Key('manufacturer-product-sunflower-oil')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'screen 110 covers all decisions, validation, exact order retry, duplicate and fulfilment',
    (tester) async {
      final gateway = ReviewManufacturerGateway()..failOrder = true;
      final session = ManufacturerSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/manufacturer/orders/review',
        manufacturerSession: session,
      );
      for (final decision in ManufacturerOrderDecision.values) {
        await tap(tester, Key('manufacturer-order-decision-${decision.name}'));
        expect(session.orderDecision, decision);
      }
      session.setOrderDecision(ManufacturerOrderDecision.cannotFulfil);
      session.setOrderNote('short');
      expect(await tester.runAsync(session.confirmOrder), isFalse);
      expect(gateway.orderCalls, 0);
      session.setOrderDecision(ManufacturerOrderDecision.partial);
      session.setConfirmedCases(120);
      await settle(tester);
      await tap(tester, const Key('manufacturer-order-confirm'));
      expect(session.orderConfirmationId, isNull);
      await tap(tester, const Key('manufacturer-order-confirm'));
      expect(session.orderConfirmationId, 'CONF-110-4821');
      expect(gateway.orderCalls, 2);
      await tap(tester, const Key('manufacturer-order-confirm'));
      expect(gateway.orderCalls, 2);
      await tap(tester, const Key('manufacturer-order-production'));
      await tap(tester, const Key('manufacturer-order-packed'));
      expect(session.orderStage, ManufacturerOrderStage.packed);
      await tap(tester, const Key('manufacturer-order-documents'));
      await closeSheet(tester, const Key('manufacturer-tool-done'));
      await tap(tester, const Key('manufacturer-order-transport'));
      expect(
        find.byKey(const Key('manufacturer-dispatch-screen')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'screen 111 compares every input and completes protected PO and receipt after exact retry',
    (tester) async {
      final gateway = ReviewManufacturerGateway()..failPurchase = true;
      final session = ManufacturerSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/manufacturer/purchases',
        manufacturerSession: session,
      );
      for (final filter in [
        'matched-inputs',
        'raw-material',
        'packaging',
        'machinery',
      ]) {
        await tap(tester, Key('manufacturer-input-filter-$filter'));
      }
      for (final offer in reviewManufacturerInputs) {
        await tap(tester, Key('manufacturer-input-terms-${offer.id}'));
        await closeSheet(tester, const Key('manufacturer-tool-done'));
        await tap(tester, Key('manufacturer-input-add-${offer.id}'));
      }
      expect(session.purchaseCart.length, reviewManufacturerInputs.length);
      await tap(tester, const Key('manufacturer-purchase-tab-cart'));
      await tap(tester, const Key('manufacturer-cart-carton'));
      expect(session.purchaseCart, isNot(contains('carton')));
      await tap(tester, const Key('manufacturer-place-po'));
      expect(session.purchaseOrderId, isNull);
      await tap(tester, const Key('manufacturer-place-po'));
      expect(session.purchaseOrderId, 'PO-IN-111-0719');
      expect(gateway.purchaseCalls, 2);
      expect(await tester.runAsync(session.placePurchaseOrder), isTrue);
      expect(gateway.purchaseCalls, 2);
      await tap(tester, const Key('manufacturer-purchase-receipt'));
      expect(session.purchaseReceiptId, 'GRN-111-0719');
      await tap(tester, const Key('manufacturer-purchase-receipt'));
      expect(session.purchaseReceiptId, 'GRN-111-0719');
    },
  );

  testWidgets(
    'screen 112 requires documents and fleet identity then replays dispatch and receipt once',
    (tester) async {
      final gateway = ReviewManufacturerGateway()..failDispatch = true;
      final session = ManufacturerSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/manufacturer/dispatch',
        manufacturerSession: session,
      );
      await tap(tester, const Key('manufacturer-dispatch-confirm'));
      expect(gateway.dispatchCalls, 0);
      await tap(tester, const Key('manufacturer-document-lr'));
      await tap(tester, const Key('manufacturer-transport-moolSocial'));
      await tap(tester, const Key('manufacturer-transport-ownFleet'));
      session.setVehicleNumber('x');
      expect(await tester.runAsync(session.confirmDispatch), isFalse);
      expect(gateway.dispatchCalls, 0);
      session.setVehicleNumber('RJ19 GC 4821');
      await settle(tester);
      await tap(tester, const Key('manufacturer-dispatch-confirm'));
      expect(session.dispatchId, isNull);
      await tap(tester, const Key('manufacturer-dispatch-confirm'));
      expect(session.dispatchId, 'DSP-112-4821');
      expect(gateway.dispatchCalls, 2);
      expect(await tester.runAsync(session.confirmDispatch), isTrue);
      expect(gateway.dispatchCalls, 2);
      await tap(tester, const Key('manufacturer-open-tracking'));
      await closeSheet(tester, const Key('manufacturer-tool-done'));
      await tap(tester, const Key('manufacturer-mark-delivered'));
      await tap(tester, const Key('manufacturer-delivery-receipt'));
      expect(session.deliveryReceiptId, 'POD-112-4821');
    },
  );

  testWidgets(
    'screen 113 covers every growth tab and publishes one capped campaign after exact retry',
    (tester) async {
      final gateway = ReviewManufacturerGateway()..failCampaign = true;
      final session = ManufacturerSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/manufacturer/growth',
        manufacturerSession: session,
      );
      for (final tab in ManufacturerGrowthTab.values) {
        await tap(tester, Key('manufacturer-growth-tab-${tab.name}'));
        expect(session.growthTab, tab);
      }
      session.setGrowthTab(ManufacturerGrowthTab.buyers);
      await settle(tester);
      await tap(tester, const Key('manufacturer-buyer-raj'));
      await closeSheet(tester, const Key('manufacturer-growth-detail-done'));
      session.setGrowthTab(ManufacturerGrowthTab.demand);
      await settle(tester);
      await tap(tester, const Key('manufacturer-demand-oil'));
      await closeSheet(tester, const Key('manufacturer-growth-detail-done'));
      await tap(tester, const Key('manufacturer-growth-create'));
      session.setCampaignTarget(0);
      expect(await tester.runAsync(session.reviewOrPublishCampaign), isTrue);
      session.setCampaignTarget(100);
      session.setCampaignBudget(42000);
      session.campaignReviewed = false;
      await settle(tester);
      await tap(tester, const Key('manufacturer-campaign-publish'));
      expect(session.campaignReviewed, isTrue);
      await tap(tester, const Key('manufacturer-campaign-publish'));
      expect(session.campaignId, isNull);
      await tap(tester, const Key('manufacturer-campaign-publish'));
      expect(session.campaignId, 'MFG-CMP-113-0719');
      expect(gateway.campaignCalls, 2);
      expect(await tester.runAsync(session.reviewOrPublishCampaign), isTrue);
      expect(gateway.campaignCalls, 2);
    },
  );

  testWidgets(
    'screen 114 completes claim, team, settings and support branches with exact replays',
    (tester) async {
      final gateway = ReviewManufacturerGateway()
        ..failClaim = true
        ..failInvite = true
        ..failSettings = true;
      final session = ManufacturerSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/manufacturer/control',
        manufacturerSession: session,
      );
      await tap(tester, const Key('manufacturer-claim-CLM-BUY-4771'));
      await tap(tester, const Key('manufacturer-claim-evidence'));
      await tap(tester, const Key('manufacturer-claim-resolve'));
      expect(gateway.claimCalls, 0);
      await tap(tester, const Key('manufacturer-claim-evidence'));
      await tap(tester, const Key('manufacturer-claim-resolve'));
      expect(session.claimResolutionId, isNull);
      await tap(tester, const Key('manufacturer-claim-resolve'));
      expect(session.claimResolutionId, 'MFG-RES-114-0719');
      expect(gateway.claimCalls, 2);
      expect(await tester.runAsync(session.resolveClaim), isTrue);
      expect(gateway.claimCalls, 2);

      await tap(tester, const Key('manufacturer-control-tab-team'));
      await tap(tester, const Key('manufacturer-team-invite'));
      await enter(tester, const Key('manufacturer-team-mobile'), '123');
      await tap(tester, const Key('manufacturer-team-send'));
      expect(gateway.inviteCalls, 0);
      await enter(tester, const Key('manufacturer-team-mobile'), '98765 88221');
      await tap(tester, const Key('manufacturer-team-send'));
      expect(session.teamInviteId, isNull);
      await tap(tester, const Key('manufacturer-team-send'));
      expect(session.teamInviteId, 'MFG-INV-114-0719');
      expect(gateway.inviteCalls, 2);

      await tap(tester, const Key('manufacturer-control-tab-settings'));
      for (final setting in [
        'business',
        'model',
        'capacity',
        'fleet',
        'security',
        'alerts',
      ]) {
        await tap(tester, Key('manufacturer-setting-$setting'));
        await closeSheet(tester, const Key('manufacturer-growth-detail-done'));
      }
      await tap(tester, const Key('manufacturer-settings-save'));
      expect(session.settingsVersion, isNull);
      await tap(tester, const Key('manufacturer-settings-save'));
      expect(session.settingsVersion, 'MFG-SET-114-0719');
      expect(await tester.runAsync(session.saveWorkspaceSettings), isTrue);
      expect(gateway.settingsCalls, 2);
      await tap(tester, const Key('manufacturer-control-tab-support'));
      expect(
        find.byKey(const Key('manufacturer-support-order')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'screen 115 reviews all services and submits one approved request after exact replay',
    (tester) async {
      final gateway = ReviewManufacturerGateway()..failService = true;
      final session = ManufacturerSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/manufacturer/services',
        manufacturerSession: session,
      );
      for (final service in reviewManufacturerServices) {
        await tap(tester, Key('manufacturer-service-${service.id}'));
        expect(
          find.byKey(const Key('manufacturer-service-sheet')),
          findsOneWidget,
        );
        Navigator.pop(
          tester.element(find.byKey(const Key('manufacturer-service-sheet'))),
        );
        await settle(tester);
      }
      await tap(tester, const Key('manufacturer-service-sales'));
      await tap(tester, const Key('manufacturer-service-request'));
      expect(gateway.serviceCalls, 0);
      await tap(tester, const Key('manufacturer-service-terms'));
      await tap(tester, const Key('manufacturer-service-request'));
      expect(session.serviceRequestId, isNull);
      await tap(tester, const Key('manufacturer-service-request'));
      expect(session.serviceRequestId, 'MFG-SVC-115-0719');
      expect(gateway.serviceCalls, 2);
      expect(await tester.runAsync(session.requestService), isTrue);
      expect(gateway.serviceCalls, 2);
      await tap(tester, const Key('manufacturer-services-tab-active'));
      expect(
        find.byKey(const Key('manufacturer-service-active-logistics')),
        findsOneWidget,
      );
      await tap(tester, const Key('manufacturer-services-tab-requests'));
      expect(
        find.byKey(const Key('manufacturer-service-request-current')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'offline and unauthorized manufacturer actions preserve every protected outcome',
    (tester) async {
      final gateway = ReviewManufacturerGateway();
      final session = ManufacturerSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/manufacturer',
        manufacturerSession: session,
      );
      session.purchaseCart['oil-bulk'] = 18;
      session.inputMappingConfirmed = true;
      session.campaignReviewed = true;
      session.serviceTermsAccepted = true;
      session.setOnline(false);
      expect(await tester.runAsync(session.toggleSupply), isFalse);
      expect(await tester.runAsync(session.publishProduct), isFalse);
      expect(await tester.runAsync(session.confirmOrder), isFalse);
      expect(await tester.runAsync(session.placePurchaseOrder), isFalse);
      expect(await tester.runAsync(session.confirmDispatch), isFalse);
      expect(await tester.runAsync(session.reviewOrPublishCampaign), isFalse);
      expect(await tester.runAsync(session.resolveClaim), isFalse);
      expect(await tester.runAsync(session.sendTeamInvite), isFalse);
      expect(await tester.runAsync(session.saveWorkspaceSettings), isFalse);
      expect(await tester.runAsync(session.requestService), isFalse);
      session.setOnline(true);
      session.authorized = false;
      expect(await tester.runAsync(session.confirmOrder), isFalse);
      expect(await tester.runAsync(session.resolveClaim), isFalse);
      expect([
        gateway.supplyCalls,
        gateway.productCalls,
        gateway.orderCalls,
        gateway.purchaseCalls,
        gateway.dispatchCalls,
        gateway.campaignCalls,
        gateway.claimCalls,
        gateway.inviteCalls,
        gateway.settingsCalls,
        gateway.serviceCalls,
      ], everyElement(0));
    },
  );
}
