import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/captain/captain_models.dart';
import 'package:moolsocial/features/captain/captain_services.dart';
import 'package:moolsocial/features/captain/captain_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );

  Future<CaptainSession> mount(
    WidgetTester tester, {
    required String route,
    CaptainSession? captainSession,
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
    final captain = captainSession ?? CaptainSession();
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      captain.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        captainSession: captain,
        initialLocation: route,
      ),
    );
    await settle(tester);
    return captain;
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

  String location(WidgetTester tester) => GoRouterState.of(
    tester.element(find.byType(Scaffold).first),
  ).uri.toString();

  testWidgets(
    'screen 116 completes availability retry and opens every owner route',
    (tester) async {
      final gateway = ReviewCaptainGateway()..failAvailability = true;
      final session = CaptainSession(gateway: gateway);
      await mount(tester, route: '/app/captain', captainSession: session);
      expect(find.byKey(const Key('captain-home-screen')), findsOneWidget);
      expect(find.byKey(const Key('captain-open-request')), findsNothing);
      await tap(tester, const Key('captain-online-toggle'));
      expect(session.availableForRides, isFalse);
      await tap(tester, const Key('captain-online-toggle'));
      expect(session.availableForRides, isTrue);
      expect(gateway.availabilityCalls, 2);
      expect(find.byKey(const Key('captain-open-request')), findsOneWidget);

      await tap(tester, const Key('captain-controls'));
      expect(find.byKey(const Key('captain-controls-sheet')), findsOneWidget);
      await tap(tester, const Key('captain-controls-close'));
      await tap(tester, const Key('captain-controls'));
      await tap(tester, const Key('captain-controls-support'));
      expect(location(tester), '/app/captain/support-work');

      final routeOwners = <Key, String>{
        const Key('captain-open-request'): '/app/captain/requests',
        const Key('captain-priority-trips'):
            '/app/captain/trips/MS-R4821/pickup',
        const Key('captain-priority-earnings'): '/app/captain/earnings',
        const Key('captain-priority-documents'): '/app/captain/compliance',
        const Key('captain-dock-requests'): '/app/captain/requests',
        const Key('captain-dock-trips'): '/app/captain/trips/MS-R4821/pickup',
        const Key('captain-dock-earnings'): '/app/captain/earnings',
      };
      for (final entry in routeOwners.entries) {
        await go(tester, '/app/captain');
        await tap(tester, entry.key);
        expect(location(tester), entry.value);
      }

      session.tripState = CaptainTripState.live;
      await go(tester, '/app/captain');
      await tap(tester, const Key('captain-dock-trips'));
      expect(location(tester), '/app/captain/trips/MS-R4821');

      session.tripState = CaptainTripState.paymentPending;
      await go(tester, '/app/captain');
      await tap(tester, const Key('captain-priority-trips'));
      expect(location(tester), '/app/captain/trips/MS-R4821/complete');

      session.tripState = CaptainTripState.completed;
      await go(tester, '/app/captain');
      await tap(tester, const Key('captain-dock-trips'));
      expect(location(tester), '/app/captain/trips/MS-R4821/complete');
    },
  );

  testWidgets(
    'screen 117 pauses safely then exactly retries one ride acceptance',
    (tester) async {
      final gateway = ReviewCaptainGateway()..failAccept = true;
      final session = CaptainSession(gateway: gateway)
        ..availableForRides = true;
      await mount(
        tester,
        route: '/app/captain/requests',
        captainSession: session,
      );
      expect(find.byKey(const Key('captain-request-screen')), findsOneWidget);
      await tap(tester, const Key('captain-pause-requests'));
      await tap(tester, const Key('captain-pause-cancel'));
      expect(session.requestsPaused, isFalse);
      await tap(tester, const Key('captain-pause-requests'));
      await tap(tester, const Key('captain-pause-confirm'));
      expect(session.requestsPaused, isTrue);
      await tap(tester, const Key('captain-accept-ride'));
      expect(gateway.acceptCalls, 0);
      await tap(tester, const Key('captain-pause-requests'));
      await tap(tester, const Key('captain-pause-confirm'));
      expect(session.requestsPaused, isFalse);
      await tap(tester, const Key('captain-accept-ride'));
      expect(session.assignmentId, isNull);
      await tap(tester, const Key('captain-accept-ride'));
      expect(session.assignmentId, 'CAP-ASG-117-4821');
      expect(gateway.acceptCalls, 2);
      expect(location(tester), '/app/captain/trips/MS-R4821/pickup');
      expect(await tester.runAsync(session.acceptRide), isTrue);
      expect(gateway.acceptCalls, 2);
    },
  );

  testWidgets(
    'screen 117 decline failure and exact retry create no assignment',
    (tester) async {
      final gateway = ReviewCaptainGateway()..failDecline = true;
      final session = CaptainSession(gateway: gateway)
        ..availableForRides = true;
      await mount(
        tester,
        route: '/app/captain/requests',
        captainSession: session,
      );
      await tap(tester, const Key('captain-decline-ride'));
      expect(session.declineId, isNull);
      await tap(tester, const Key('captain-decline-ride'));
      expect(session.declineId, 'CAP-DEC-117-4821');
      expect(session.assignmentId, isNull);
      expect(gateway.declineCalls, 2);
      expect(location(tester), '/app/captain?declined=MS-R4821');
      expect(await tester.runAsync(session.declineRide), isTrue);
      expect(gateway.declineCalls, 2);
    },
  );

  testWidgets(
    'screen 118 covers contact, stale location, OTP validation and exact start retry',
    (tester) async {
      final gateway = ReviewCaptainGateway()..failStart = true;
      final session = CaptainSession(gateway: gateway)
        ..assignmentId = 'CAP-ASG-117-4821'
        ..tripState = CaptainTripState.pickup;
      await mount(
        tester,
        route: '/app/captain/trips/MS-R4821/pickup',
        captainSession: session,
      );
      expect(find.byKey(const Key('captain-pickup-screen')), findsOneWidget);
      await tap(tester, const Key('captain-pickup-call'));
      await tap(tester, const Key('captain-masked-call-cancel'));
      await tap(tester, const Key('captain-pickup-call'));
      await tap(tester, const Key('captain-masked-call-connect'));
      expect(session.noticeMessage, contains('Masked'));
      await tap(tester, const Key('captain-pickup-chat'));
      expect(location(tester), contains('/app/chat/thread/order-support'));
      await go(tester, '/app/captain/trips/MS-R4821/pickup');
      await tap(tester, const Key('captain-pickup-support'));
      expect(location(tester), '/app/captain/support-work?case=pickup');
      await go(tester, '/app/captain/trips/MS-R4821/pickup');

      session.setPickupGeofenceFresh(false);
      await settle(tester);
      await tap(tester, const Key('captain-pickup-arrived'));
      expect(session.captainArrivedAtPickup, isFalse);
      session.setPickupGeofenceFresh(true);
      await settle(tester);
      await tap(tester, const Key('captain-pickup-arrived'));
      expect(find.byKey(const Key('captain-otp-sheet')), findsOneWidget);
      await enter(tester, const Key('captain-trip-otp'), '12');
      await tap(tester, const Key('captain-trip-start'));
      expect(gateway.startCalls, 0);
      await enter(tester, const Key('captain-trip-otp'), '1111');
      await tap(tester, const Key('captain-trip-start'));
      expect(gateway.startCalls, 0);
      await enter(tester, const Key('captain-trip-otp'), '4821');
      await tap(tester, const Key('captain-trip-start'));
      expect(session.tripStartId, isNull);
      await tap(tester, const Key('captain-trip-start'));
      expect(session.tripStartId, 'CAP-START-118-4821');
      expect(gateway.startCalls, 2);
      expect(location(tester), '/app/captain/trips/MS-R4821');
      expect(await tester.runAsync(session.startTrip), isTrue);
      expect(gateway.startCalls, 2);
    },
  );

  testWidgets(
    'screen 119 covers every safety branch and exact destination retry',
    (tester) async {
      final gateway = ReviewCaptainGateway()..failArrival = true;
      final session = CaptainSession(gateway: gateway)
        ..assignmentId = 'CAP-ASG-117-4821'
        ..tripStartId = 'CAP-START-118-4821'
        ..tripState = CaptainTripState.live;
      await mount(
        tester,
        route: '/app/captain/trips/MS-R4821',
        captainSession: session,
      );
      expect(find.byKey(const Key('captain-live-trip-screen')), findsOneWidget);
      for (final key in [
        const Key('captain-trip-more'),
        const Key('captain-trip-sos'),
        const Key('captain-trip-issue'),
      ]) {
        await tap(tester, key);
        expect(
          find.byKey(const Key('captain-trip-option-sheet')),
          findsOneWidget,
        );
        await tap(tester, const Key('captain-trip-option-close'));
      }
      await tap(tester, const Key('captain-trip-sos'));
      await tap(tester, const Key('captain-trip-open-support'));
      expect(
        location(tester),
        '/app/captain/support-work?case=sos&trip=MS-R4821',
      );
      await go(tester, '/app/captain/trips/MS-R4821');
      await tap(tester, const Key('captain-trip-contact'));
      expect(location(tester), contains('/app/chat/thread/order-support'));
      await go(tester, '/app/captain/trips/MS-R4821');

      session.setDestinationGeofenceFresh(false);
      await settle(tester);
      await tap(tester, const Key('captain-arrive-destination'));
      expect(gateway.arrivalCalls, 0);
      session.setDestinationGeofenceFresh(true);
      await settle(tester);
      await tap(tester, const Key('captain-arrive-destination'));
      expect(session.arrivalId, isNull);
      await tap(tester, const Key('captain-arrive-destination'));
      expect(session.arrivalId, 'CAP-ARR-119-4821');
      expect(gateway.arrivalCalls, 2);
      expect(location(tester), '/app/captain/trips/MS-R4821/complete');
      expect(await tester.runAsync(session.confirmDestinationArrival), isTrue);
      expect(gateway.arrivalCalls, 2);
    },
  );

  testWidgets(
    'screen 120 checks record-backed payment once and opens earnings',
    (tester) async {
      final gateway = ReviewCaptainGateway()..failPayment = true;
      final session = CaptainSession(gateway: gateway)
        ..assignmentId = 'CAP-ASG-117-4821'
        ..tripStartId = 'CAP-START-118-4821'
        ..arrivalId = 'CAP-ARR-119-4821'
        ..tripState = CaptainTripState.paymentPending;
      await mount(
        tester,
        route: '/app/captain/trips/MS-R4821/complete',
        captainSession: session,
      );
      expect(
        find.byKey(const Key('captain-completion-screen')),
        findsOneWidget,
      );
      await tap(tester, const Key('captain-payment-help'));
      expect(location(tester), '/app/captain/support-work?case=payment');
      await go(tester, '/app/captain/trips/MS-R4821/complete');
      await tap(tester, const Key('captain-check-payment'));
      expect(session.paymentReceiptId, isNull);
      await tap(tester, const Key('captain-check-payment'));
      expect(session.paymentReceiptId, 'CAP-PAY-120-4821');
      expect(gateway.paymentCalls, 2);
      expect(find.byKey(const Key('captain-payment-sheet')), findsOneWidget);
      await tap(tester, const Key('captain-payment-close'));
      await tap(tester, const Key('captain-check-payment'));
      expect(gateway.paymentCalls, 2);
      await tap(tester, const Key('captain-payment-view-earnings'));
      expect(location(tester), '/app/captain/earnings');
    },
  );

  testWidgets('screen 121 opens every tab, trip, payout and statement action', (
    tester,
  ) async {
    final session = await mount(tester, route: '/app/captain/earnings');
    expect(find.byKey(const Key('captain-earnings-screen')), findsOneWidget);
    for (final tab in CaptainEarningsTab.values) {
      await tap(tester, Key('captain-earnings-tab-${tab.name}'));
      expect(session.earningsTab, tab);
    }
    await tap(tester, const Key('captain-earnings-download'));
    await tap(tester, const Key('captain-payout-close'));
    await tap(tester, const Key('captain-earnings-download'));
    await tap(tester, const Key('captain-open-statement'));
    expect(session.noticeMessage, contains('statement'));
    await tap(tester, const Key('captain-payout-details'));
    await tap(tester, const Key('captain-open-statement'));
    for (final earning in reviewCaptainEarnings) {
      await tap(tester, Key('captain-earning-${earning.id}'));
      expect(session.selectedEarningId, earning.id);
      await tap(tester, const Key('captain-earning-close'));
    }
  });

  testWidgets(
    'screen 122 opens every record then exactly retries one verification',
    (tester) async {
      final gateway = ReviewCaptainGateway()..failVerification = true;
      final session = CaptainSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/captain/compliance',
        captainSession: session,
      );
      expect(
        find.byKey(const Key('captain-compliance-screen')),
        findsOneWidget,
      );
      await tap(tester, const Key('captain-compliance-add'));
      await tap(tester, const Key('captain-verification-close'));
      for (final document in reviewCaptainDocuments) {
        await tap(tester, Key('captain-document-${document.id}'));
        expect(session.selectedDocumentId, document.id);
        await tap(tester, const Key('captain-verification-close'));
      }
      await tap(tester, const Key('captain-document-insurance'));
      await tap(tester, const Key('captain-verification-start'));
      expect(gateway.verificationCalls, 0);
      await tap(tester, const Key('captain-verification-consent'));
      await tap(tester, const Key('captain-verification-start'));
      expect(session.verificationId, isNull);
      await tap(tester, const Key('captain-verification-start'));
      expect(session.verificationId, 'CAP-VER-122-0719');
      expect(gateway.verificationCalls, 2);
      await tap(tester, const Key('captain-verification-start'));
      expect(gateway.verificationCalls, 2);
    },
  );

  testWidgets(
    'screen 123 covers all support, paid-work and vehicle-help branches',
    (tester) async {
      final gateway = ReviewCaptainGateway()
        ..failSupport = true
        ..failApplication = true;
      final session = CaptainSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/captain/support-work',
        captainSession: session,
      );
      expect(
        find.byKey(const Key('captain-support-work-screen')),
        findsOneWidget,
      );
      await tap(tester, const Key('captain-support-new'));
      await tap(tester, const Key('captain-support-close'));
      for (final option in reviewCaptainSupport) {
        await tap(tester, Key('captain-support-${option.id}'));
        expect(session.selectedSupportId, option.id);
        await tap(tester, const Key('captain-support-close'));
      }
      await tap(tester, const Key('captain-support-trip'));
      await enter(tester, const Key('captain-support-message'), 'short');
      await tap(tester, const Key('captain-support-create'));
      expect(gateway.supportCalls, 0);
      await enter(
        tester,
        const Key('captain-support-message'),
        'The pickup route changed and I need help.',
      );
      await tap(tester, const Key('captain-support-create'));
      expect(session.supportCaseId, isNull);
      await tap(tester, const Key('captain-support-create'));
      expect(session.supportCaseId, 'CAP-CASE-123-0719');
      expect(gateway.supportCalls, 2);
      await tap(tester, const Key('captain-support-create'));
      expect(gateway.supportCalls, 2);
      await tap(tester, const Key('captain-support-close'));

      await tap(tester, const Key('captain-support-tab-paidWork'));
      for (final work in reviewCaptainPaidWork) {
        await tap(tester, Key('captain-work-review-${work.id}'));
        expect(session.selectedWorkId, work.id);
        await tap(tester, const Key('captain-work-close'));
      }
      await tap(tester, const Key('captain-work-review-captain-onboarding'));
      await tap(tester, const Key('captain-work-apply'));
      expect(gateway.applicationCalls, 0);
      await tap(tester, const Key('captain-work-terms'));
      await tap(tester, const Key('captain-work-apply'));
      expect(session.workApplicationId, isNull);
      await tap(tester, const Key('captain-work-apply'));
      expect(session.workApplicationId, 'CAP-WORK-123-0719');
      expect(gateway.applicationCalls, 2);
      await tap(tester, const Key('captain-work-apply'));
      expect(gateway.applicationCalls, 2);
      await tap(tester, const Key('captain-work-close'));

      await tap(tester, const Key('captain-support-tab-vehicle'));
      for (final option in reviewCaptainVehicleHelp) {
        await tap(tester, Key('captain-vehicle-${option.id}'));
        expect(
          find.byKey(const Key('captain-vehicle-help-sheet')),
          findsOneWidget,
        );
        await tap(tester, const Key('captain-vehicle-help-close'));
      }
      await tap(tester, const Key('captain-vehicle-insurance-renewal'));
      await tap(tester, const Key('captain-vehicle-help-continue'));
      expect(location(tester), '/app/captain/compliance');
    },
  );

  testWidgets(
    'offline and unauthorized captain commands preserve every outcome',
    (tester) async {
      final gateway = ReviewCaptainGateway();
      final session = CaptainSession(gateway: gateway)
        ..availableForRides = true
        ..captainArrivedAtPickup = true
        ..pickupOtp = '4821'
        ..selectedDocumentId = 'insurance'
        ..verificationConsent = true
        ..workTermsAccepted = true;
      await mount(tester, route: '/app/captain', captainSession: session);
      session.setOnline(false);
      expect(await tester.runAsync(session.toggleAvailability), isFalse);
      expect(await tester.runAsync(session.acceptRide), isFalse);
      expect(await tester.runAsync(session.declineRide), isFalse);
      expect(await tester.runAsync(session.startTrip), isFalse);
      session.tripStartId = 'CAP-START-118-4821';
      session.tripState = CaptainTripState.live;
      expect(await tester.runAsync(session.confirmDestinationArrival), isFalse);
      session.arrivalId = 'CAP-ARR-119-4821';
      session.tripState = CaptainTripState.paymentPending;
      expect(await tester.runAsync(session.checkPayment), isFalse);
      expect(await tester.runAsync(session.startDocumentVerification), isFalse);
      expect(await tester.runAsync(session.createSupportCase), isFalse);
      expect(await tester.runAsync(session.applyForWork), isFalse);
      session.setOnline(true);
      session.authorized = false;
      expect(await tester.runAsync(session.acceptRide), isFalse);
      expect(await tester.runAsync(session.createSupportCase), isFalse);
      expect([
        gateway.availabilityCalls,
        gateway.acceptCalls,
        gateway.declineCalls,
        gateway.startCalls,
        gateway.arrivalCalls,
        gateway.paymentCalls,
        gateway.verificationCalls,
        gateway.supportCalls,
        gateway.applicationCalls,
      ], everyElement(0));
    },
  );
}
