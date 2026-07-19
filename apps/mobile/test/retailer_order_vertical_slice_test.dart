import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_models.dart';
import 'package:moolsocial/features/retailer/retailer_services.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';

void main() {
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

  Future<(JourneySession, RetailerSession)> mount(
    WidgetTester tester, {
    required String route,
    RetailerSession? retailerSession,
    Size size = const Size(412, 915),
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
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        retailerSession: retailer,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
    return (journey, retailer);
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final vertical = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            {
              AxisDirection.down,
              AxisDirection.up,
            }.contains(widget.axisDirection),
      );
      expect(vertical, findsWidgets, reason: 'No scrollable for $key');
      await tester.drag(vertical.last, const Offset(0, 900));
      await tester.pumpAndSettle();
      for (
        var attempt = 0;
        attempt < 14 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        await tester.drag(vertical.last, const Offset(0, -280));
        await tester.pumpAndSettle();
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing tap target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final vertical = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            {
              AxisDirection.down,
              AxisDirection.up,
            }.contains(widget.axisDirection),
      );
      expect(vertical, findsWidgets, reason: 'No scrollable for $key');
      await tester.drag(vertical.last, const Offset(0, 900));
      await tester.pumpAndSettle();
      for (
        var attempt = 0;
        attempt < 14 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        await tester.drag(vertical.last, const Offset(0, -280));
        await tester.pumpAndSettle();
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing input $key');
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'paid order completes review packing safe handover delivery and book entry',
    (tester) async {
      final (_, retailer) = await mount(tester, route: '/app/retailer/home');

      expect(find.byKey(const Key('retailer-home-screen')), findsOneWidget);
      await tapVisible(tester, const Key('retailer-alerts'));
      expect(find.byKey(const Key('retailer-alert-sheet')), findsOneWidget);
      await tapVisible(tester, const Key('retailer-alert-review-order'));
      expect(
        find.byKey(const Key('retailer-order-review-screen')),
        findsOneWidget,
      );

      await tapVisible(tester, const Key('retailer-accept-order'));
      expect(retailer.selectedOrder?.stage, RetailerOrderStage.accepted);
      await tapVisible(tester, const Key('retailer-start-packing'));
      await tapVisible(tester, const Key('retailer-mark-order-packed'));
      expect(find.textContaining('Check every product'), findsOneWidget);

      await tapVisible(tester, const Key('retailer-pack-oil'));
      await tapVisible(tester, const Key('retailer-pack-atta'));
      await tapVisible(tester, const Key('retailer-pack-salt'));
      await tapVisible(tester, const Key('retailer-show-remaining-lines'));
      await tapVisible(tester, const Key('retailer-pack-remaining'));
      await tapVisible(tester, const Key('retailer-mark-order-packed'));
      expect(retailer.selectedOrder?.stage, RetailerOrderStage.packed);

      await tapVisible(tester, const Key('retailer-request-delivery'));
      expect(
        find.byKey(const Key('retailer-delivery-assignment-screen')),
        findsOneWidget,
      );
      expect(retailer.selectedOrder?.stage, RetailerOrderStage.captainAssigned);
      await tapVisible(tester, const Key('retailer-parcel-ready'));
      await tapVisible(tester, const Key('retailer-captain-here'));
      await tapVisible(tester, const Key('retailer-confirm-handover'));
      await enter(tester, const Key('retailer-handover-otp'), '1111');
      await tapVisible(tester, const Key('retailer-verify-handover-otp'));
      expect(find.textContaining('4-digit handover OTP'), findsOneWidget);
      await enter(tester, const Key('retailer-handover-otp'), '2841');
      await tapVisible(tester, const Key('retailer-verify-handover-otp'));
      expect(
        retailer.selectedOrder?.stage,
        RetailerOrderStage.handoverVerified,
      );
      await tapVisible(tester, const Key('retailer-hand-over-parcel'));
      expect(retailer.selectedOrder?.stage, RetailerOrderStage.handedOver);
      await tapVisible(tester, const Key('retailer-track-delivery'));
      expect(
        find.byKey(const Key('retailer-delivery-tracking-screen')),
        findsOneWidget,
      );

      await tapVisible(tester, const Key('retailer-refresh-tracking'));
      expect(retailer.selectedOrder?.stage, RetailerOrderStage.nearby);
      await tapVisible(tester, const Key('retailer-refresh-tracking'));
      expect(retailer.selectedOrder?.stage, RetailerOrderStage.delivered);
      await tapVisible(tester, const Key('retailer-delivery-receipt'));
      expect(
        find.byKey(const Key('retailer-delivery-receipt')),
        findsOneWidget,
      );
      expect(retailer.businessBookRecorded, isTrue);
      await tapVisible(tester, const Key('retailer-delivery-open-book'));
      expect(find.textContaining('recorded in Business Book'), findsOneWidget);

      final trackingCalls = retailer.gateway.trackingCalls;
      expect(await retailer.refreshTracking(), isTrue);
      expect(retailer.gateway.trackingCalls, trackingCalls);
    },
  );

  testWidgets('order acceptance failure replays once without duplication', (
    tester,
  ) async {
    final gateway = ReviewRetailerGateway()..failAccept = true;
    final retailer = RetailerSession(gateway: gateway);
    await mount(
      tester,
      route: '/app/retailer/orders/MS-2841',
      retailerSession: retailer,
    );

    await tapVisible(tester, const Key('retailer-accept-order'));
    expect(find.textContaining('Order was not accepted'), findsOneWidget);
    expect(retailer.selectedOrder?.stage, RetailerOrderStage.newOrder);
    await tapVisible(tester, const Key('retailer-accept-order'));
    expect(retailer.selectedOrder?.stage, RetailerOrderStage.accepted);
    expect(gateway.acceptCalls, 2);

    expect(await retailer.acceptSelectedOrder(), isTrue);
    expect(gateway.acceptCalls, 2);
  });

  testWidgets('packing failure preserves every checked product for retry', (
    tester,
  ) async {
    final gateway = ReviewRetailerGateway()..failPacking = true;
    final retailer = RetailerSession(gateway: gateway)..openOrder('MS-2841');
    retailer.selectedOrder!.stage = RetailerOrderStage.packing;
    for (final line in retailer.selectedOrder!.lines) {
      line.packed = true;
    }
    await mount(
      tester,
      route: '/app/retailer/orders/MS-2841',
      retailerSession: retailer,
    );

    await tapVisible(tester, const Key('retailer-mark-order-packed'));
    expect(find.textContaining('checked items remain'), findsOneWidget);
    expect(retailer.selectedOrder!.allPacked, isTrue);
    expect(retailer.selectedOrder!.stage, RetailerOrderStage.packing);
    await tapVisible(tester, const Key('retailer-mark-order-packed'));
    expect(retailer.selectedOrder!.stage, RetailerOrderStage.packed);
    expect(gateway.packingCalls, 2);
  });

  testWidgets('delivery request failure keeps packed order then assigns once', (
    tester,
  ) async {
    final gateway = ReviewRetailerGateway()..failDeliveryRequest = true;
    final retailer = RetailerSession(gateway: gateway)..openOrder('MS-2841');
    retailer.selectedOrder!.stage = RetailerOrderStage.packed;
    for (final line in retailer.selectedOrder!.lines) {
      line.packed = true;
    }
    await mount(
      tester,
      route: '/app/retailer/orders/MS-2841',
      retailerSession: retailer,
    );

    await tapVisible(tester, const Key('retailer-request-delivery'));
    expect(find.textContaining('Delivery was not assigned'), findsOneWidget);
    expect(retailer.selectedOrder!.stage, RetailerOrderStage.packed);
    await tapVisible(tester, const Key('retailer-request-delivery'));
    expect(
      find.byKey(const Key('retailer-delivery-assignment-screen')),
      findsOneWidget,
    );
    expect(gateway.deliveryRequestCalls, 2);
    final reference = retailer.selectedOrder!.deliveryReference;
    expect(await retailer.requestDelivery(), isTrue);
    expect(retailer.selectedOrder!.deliveryReference, reference);
    expect(gateway.deliveryRequestCalls, 2);
  });

  testWidgets('handover failure keeps parcel with retailer for exact retry', (
    tester,
  ) async {
    final gateway = ReviewRetailerGateway()..failHandover = true;
    final retailer = RetailerSession(gateway: gateway)..openOrder('MS-2841');
    retailer.selectedOrder!
      ..stage = RetailerOrderStage.handoverVerified
      ..deliveryReference = 'DEL-MS-2841-421'
      ..captainName = 'Rakesh Kumar'
      ..captainVehicle = 'RJ 19 SX 4821';
    await mount(
      tester,
      route: '/app/retailer/orders/MS-2841/delivery',
      retailerSession: retailer,
    );

    await tapVisible(tester, const Key('retailer-hand-over-parcel'));
    expect(find.textContaining('Keep the parcel'), findsOneWidget);
    expect(retailer.selectedOrder!.stage, RetailerOrderStage.handoverVerified);
    await tapVisible(tester, const Key('retailer-hand-over-parcel'));
    expect(retailer.selectedOrder!.stage, RetailerOrderStage.handedOver);
    expect(gateway.handoverCalls, 2);
  });

  testWidgets(
    'tracking failure keeps existing state and retry completes once',
    (tester) async {
      final gateway = ReviewRetailerGateway()..failTracking = true;
      final retailer = RetailerSession(gateway: gateway)..openOrder('MS-2841');
      retailer.selectedOrder!
        ..stage = RetailerOrderStage.handedOver
        ..handoverReference = 'HAND-MS-2841-811'
        ..captainName = 'Rakesh Kumar'
        ..captainVehicle = 'RJ 19 SX 4821';
      await mount(
        tester,
        route: '/app/retailer/orders/MS-2841/tracking',
        retailerSession: retailer,
      );

      expect(retailer.selectedOrder!.stage, RetailerOrderStage.outForDelivery);
      await tapVisible(tester, const Key('retailer-refresh-tracking'));
      expect(find.textContaining('update is unavailable'), findsOneWidget);
      expect(retailer.selectedOrder!.stage, RetailerOrderStage.outForDelivery);
      await tapVisible(tester, const Key('retailer-refresh-tracking'));
      expect(retailer.selectedOrder!.stage, RetailerOrderStage.nearby);
      await tapVisible(tester, const Key('retailer-refresh-tracking'));
      expect(retailer.selectedOrder!.stage, RetailerOrderStage.delivered);
      expect(gateway.trackingCalls, 3);
    },
  );

  testWidgets(
    'cannot fulfil handles empty cancel failure retry and refund-safe outcome',
    (tester) async {
      final gateway = ReviewRetailerGateway()..failCannotFulfil = true;
      final retailer = RetailerSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/orders/MS-2841',
        retailerSession: retailer,
      );

      await tapVisible(tester, const Key('retailer-cannot-fulfil'));
      await tapVisible(tester, const Key('retailer-cannot-confirm'));
      expect(find.textContaining('Choose why'), findsOneWidget);
      await tapVisible(tester, const Key('retailer-cannot-reason-0'));
      await tapVisible(tester, const Key('retailer-cannot-confirm'));
      expect(find.textContaining('order was not declined'), findsOneWidget);
      expect(retailer.selectedOrder!.stage, RetailerOrderStage.newOrder);
      await tapVisible(tester, const Key('retailer-cannot-confirm'));
      expect(retailer.selectedOrder!.stage, RetailerOrderStage.cannotFulfil);
      await tapVisible(tester, const Key('retailer-cannot-fulfil-result'));
      expect(
        find.byKey(const Key('retailer-cannot-fulfil-result')),
        findsOneWidget,
      );
      expect(gateway.cannotFulfilCalls, 2);
    },
  );

  testWidgets('delivery issue validates retries and preserves order state', (
    tester,
  ) async {
    final gateway = ReviewRetailerGateway()..failIssue = true;
    final retailer = RetailerSession(gateway: gateway)..openOrder('MS-2841');
    retailer.selectedOrder!
      ..stage = RetailerOrderStage.captainAssigned
      ..deliveryReference = 'DEL-MS-2841-421'
      ..captainName = 'Rakesh Kumar'
      ..captainVehicle = 'RJ 19 SX 4821';
    await mount(
      tester,
      route: '/app/retailer/orders/MS-2841/delivery',
      retailerSession: retailer,
    );

    await tapVisible(tester, const Key('retailer-delivery-issue'));
    await tapVisible(tester, const Key('retailer-delivery-issue-submit'));
    expect(find.textContaining('Choose the delivery issue'), findsOneWidget);
    await tapVisible(tester, const Key('retailer-delivery-issue-1'));
    await tapVisible(tester, const Key('retailer-delivery-issue-submit'));
    expect(find.textContaining('issue was not sent'), findsOneWidget);
    expect(retailer.selectedOrder!.stage, RetailerOrderStage.captainAssigned);
    await tapVisible(tester, const Key('retailer-delivery-issue-submit'));
    expect(retailer.selectedOrder!.issueReference, isNotNull);
    expect(gateway.issueCalls, 2);
  });

  testWidgets(
    'home search availability refresh and alternate tabs recover safely',
    (tester) async {
      final gateway = ReviewRetailerGateway()
        ..failAvailability = true
        ..failRefresh = true;
      final retailer = RetailerSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/retailer/home',
        retailerSession: retailer,
      );

      await tapVisible(tester, const Key('retailer-orders-online'));
      expect(find.textContaining('previous setting'), findsOneWidget);
      expect(retailer.ordersOnline, isTrue);
      await tapVisible(tester, const Key('retailer-orders-online'));
      expect(retailer.ordersOnline, isFalse);

      await enter(
        tester,
        const Key('retailer-home-search'),
        'no matching order',
      );
      expect(find.byKey(const Key('retailer-home-empty')), findsOneWidget);
      await tapVisible(tester, const Key('retailer-home-empty-action'));
      expect(find.byKey(const Key('retailer-order-MS-2841')), findsOneWidget);

      await tapVisible(tester, const Key('retailer-open-orders'));
      await tapVisible(tester, const Key('retailer-refresh-orders'));
      expect(find.textContaining('could not be refreshed'), findsOneWidget);
      await tapVisible(tester, const Key('retailer-refresh-orders'));
      expect(find.textContaining('Orders are current'), findsOneWidget);

      await tapVisible(tester, const Key('retailer-dock-stock'));
      expect(
        find.byKey(const Key('retailer-stock-preview-screen')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('retailer-stock-review'));
      expect(find.textContaining('Stock review is open'), findsOneWidget);
      await tapVisible(tester, const Key('retailer-dock-wholesale'));
      expect(
        find.byKey(const Key('wholesale-catalog-screen')),
        findsOneWidget,
      );
    },
  );

  testWidgets('retailer Chat and Mool return to the exact operating screen', (
    tester,
  ) async {
    await mount(tester, route: '/app/retailer/orders');

    await tapVisible(tester, const Key('retailer-order-MS-2841'));
    await tapVisible(tester, const Key('retailer-message-customer'));
    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    await tapVisible(tester, const Key('chat-back'));
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    await tapVisible(tester, const Key('chat-back'));
    expect(
      find.byKey(const Key('retailer-order-review-screen')),
      findsOneWidget,
    );

    await tapVisible(tester, const Key('retailer-dock-mool'));
    expect(find.byKey(const Key('mool-command-palette')), findsOneWidget);
    await tapVisible(tester, const Key('close-mool'));
    expect(find.byKey(const Key('retailer-home-screen')), findsOneWidget);
  });

  testWidgets('retailer order flow remains usable on compact larger text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await mount(
      tester,
      route: '/app/retailer/orders/MS-2841',
      size: const Size(360, 800),
    );
    for (final key in const [
      Key('retailer-order-book'),
      Key('retailer-order-alerts'),
      Key('retailer-message-customer'),
      Key('retailer-call-customer'),
      Key('retailer-toggle-order-lines'),
      Key('retailer-accept-order'),
      Key('retailer-dock-mool'),
      Key('retailer-dock-orders'),
      Key('retailer-dock-stock'),
      Key('retailer-dock-wholesale'),
      Key('retailer-dock-chat'),
    ]) {
      final finder = find.byKey(key);
      if (finder.evaluate().isEmpty) {
        final vertical = find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              {
                AxisDirection.down,
                AxisDirection.up,
              }.contains(widget.axisDirection),
        );
        expect(vertical, findsWidgets, reason: 'No scrollable for $key');
        await tester.drag(vertical.last, const Offset(0, 900));
        await tester.pumpAndSettle();
        for (
          var attempt = 0;
          attempt < 14 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          await tester.drag(vertical.last, const Offset(0, -280));
          await tester.pumpAndSettle();
        }
      }
      expect(finder, findsOneWidget, reason: 'Missing $key');
    }
    expect(tester.takeException(), isNull);
  });
}
