import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/ride/ride_models.dart';
import 'package:moolsocial/features/ride/ride_services.dart';
import 'package:moolsocial/features/ride/ride_session.dart';

void main() {
  Future<JourneySession> readyJourney() async {
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Sardarpura',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await session.start();
    return session;
  }

  Future<void> mount(
    WidgetTester tester, {
    required String route,
    required JourneySession journey,
    required RideSession ride,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MoolSocialApp(
        key: ValueKey(route),
        session: journey,
        rideSession: ride,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byType(Scrollable);
      for (final element in scrollables.evaluate()) {
        if (finder.evaluate().isNotEmpty) break;
        final scrollable = find.byElementPredicate(
          (candidate) => identical(candidate, element),
        );
        final axis = tester.widget<Scrollable>(scrollable).axisDirection;
        final offset = axis == AxisDirection.left || axis == AxisDirection.right
            ? const Offset(-220, 0)
            : const Offset(0, -260);
        for (
          var attempt = 0;
          attempt < 12 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          await tester.drag(scrollable, offset);
          await tester.pumpAndSettle();
        }
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing tap target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'ride completes booking, arrival, live stop, payment, receipt and rating',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final gateway = ReviewRideGateway(latency: Duration.zero);
      final ride = RideSession(gateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(ride.dispose);
      await mount(
        tester,
        route: '/app/ride/book?type=auto',
        journey: journey,
        ride: ride,
      );

      expect(find.byKey(const Key('ride-booking-screen')), findsOneWidget);
      await tapVisible(tester, const Key('ride-package-auto-plus'));
      expect(ride.fare, 138);
      await tapVisible(tester, const Key('ride-payment-upi'));
      await tapVisible(tester, const Key('ride-book'));
      expect(gateway.bookingCalls, 1);
      expect(find.byKey(const Key('ride-arriving-screen')), findsOneWidget);
      expect(find.text('Arjun Singh'), findsOneWidget);

      await tapVisible(tester, const Key('ride-edit-pickup-note'));
      await tester.enterText(
        find.byKey(const Key('ride-pickup-note-field')),
        'Near the blue gate',
      );
      await tapVisible(tester, const Key('ride-save-pickup-note'));
      expect(ride.pickupNote, 'Near the blue gate');

      await tapVisible(tester, const Key('ride-start-trip'));
      expect(find.byKey(const Key('ride-live-screen')), findsOneWidget);
      await tapVisible(tester, const Key('ride-add-stop'));
      await tester.enterText(
        find.byKey(const Key('ride-added-stop-field')),
        'Paota Circle',
      );
      await tapVisible(tester, const Key('ride-review-stop'));
      expect(find.textContaining('new fare ₹164'), findsOneWidget);
      await tapVisible(tester, const Key('ride-confirm-added-stop'));
      expect(ride.addedStop, 'Paota Circle');

      await tapVisible(tester, const Key('ride-reach-destination'));
      expect(find.byKey(const Key('ride-payment-screen')), findsOneWidget);
      await tapVisible(tester, const Key('ride-approve-payment'));
      expect(gateway.paymentCalls, 1);
      expect(find.byKey(const Key('ride-receipt-screen')), findsOneWidget);
      await tapVisible(tester, const Key('ride-submit-rating'));
      expect(
        find.text('Choose a captain rating before submitting.'),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('dismiss-ride-message'));
      await tapVisible(tester, const Key('ride-rating-5'));
      await tapVisible(tester, const Key('ride-submit-rating'));
      expect(ride.rating, 5);
      expect(find.textContaining('Rating submitted'), findsOneWidget);
    },
  );

  testWidgets(
    'route and schedule invalid, cancelled and valid outcomes remain visible',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final ride = RideSession(
        gateway: ReviewRideGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(ride.dispose);
      await mount(
        tester,
        route: '/app/ride/book',
        journey: journey,
        ride: ride,
      );

      await tapVisible(tester, const Key('ride-edit-route'));
      await tester.enterText(find.byKey(const Key('ride-pickup-field')), 'A');
      await tester.enterText(find.byKey(const Key('ride-drop-field')), 'B');
      await tapVisible(tester, const Key('ride-save-route'));
      expect(
        find.text('Enter a complete pickup and destination.'),
        findsWidgets,
      );

      await tester.enterText(
        find.byKey(const Key('ride-pickup-field')),
        'Sardarpura Circle',
      );
      await tester.enterText(
        find.byKey(const Key('ride-drop-field')),
        'Sardarpura Circle',
      );
      await tapVisible(tester, const Key('ride-save-route'));
      expect(
        find.text('Pickup and destination must be different.'),
        findsWidgets,
      );
      await tester.enterText(
        find.byKey(const Key('ride-drop-field')),
        'Airport Terminal Jodhpur',
      );
      await tapVisible(tester, const Key('ride-save-route'));
      expect(ride.drop, 'Airport Terminal Jodhpur');

      await tapVisible(tester, const Key('ride-time-schedule'));
      await tapVisible(tester, const Key('ride-confirm-schedule'));
      expect(find.byKey(const Key('ride-schedule-error')), findsOneWidget);
      await tapVisible(tester, const Key('ride-schedule-tomorrow'));
      await tapVisible(tester, const Key('ride-schedule-7:30-PM'));
      await tapVisible(tester, const Key('ride-confirm-schedule'));
      expect(ride.rideTime, RideTime.scheduled);
      expect(ride.scheduledTime, '7:30 PM');
    },
  );

  testWidgets('captain matching failure retries without taking payment', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final gateway = ReviewRideGateway(
      failNextBooking: true,
      latency: Duration.zero,
    );
    final ride = RideSession(gateway: gateway);
    addTearDown(journey.dispose);
    addTearDown(ride.dispose);
    await mount(tester, route: '/app/ride/book', journey: journey, ride: ride);

    await tapVisible(tester, const Key('ride-book'));
    expect(find.textContaining('No captain accepted yet'), findsOneWidget);
    expect(find.textContaining('No payment was taken'), findsOneWidget);
    expect(ride.trip, isNull);
    expect(gateway.paymentCalls, 0);
    await tapVisible(tester, const Key('ride-book'));
    expect(ride.trip, isNotNull);
    expect(gateway.bookingCalls, 2);
    expect(find.byKey(const Key('ride-arriving-screen')), findsOneWidget);
  });

  testWidgets('pickup cancellation supports keep and free confirmed cancel', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final ride = RideSession(
      gateway: ReviewRideGateway(latency: Duration.zero),
    );
    await ride.bookRide();
    final tripId = ride.trip!.id;
    addTearDown(journey.dispose);
    addTearDown(ride.dispose);
    await mount(
      tester,
      route: '/app/ride/trip/$tripId',
      journey: journey,
      ride: ride,
    );

    await tapVisible(tester, const Key('ride-cancel'));
    await tapVisible(tester, const Key('ride-keep-ride'));
    expect(ride.rideCancelled, isFalse);
    await tapVisible(tester, const Key('ride-cancel'));
    await tapVisible(tester, const Key('ride-confirm-cancel'));
    expect(ride.rideCancelled, isTrue);
    expect(find.textContaining('No payment taken'), findsWidgets);
    expect(find.byKey(const Key('ride-book-after-cancel')), findsOneWidget);
  });

  testWidgets('live stop validates empty input before showing changed fare', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final ride = RideSession(
      gateway: ReviewRideGateway(latency: Duration.zero),
    );
    await ride.bookRide();
    ride.startTrip();
    final tripId = ride.trip!.id;
    addTearDown(journey.dispose);
    addTearDown(ride.dispose);
    await mount(
      tester,
      route: '/app/ride/trip/$tripId',
      journey: journey,
      ride: ride,
    );

    await tapVisible(tester, const Key('ride-add-stop'));
    await tapVisible(tester, const Key('ride-review-stop'));
    expect(find.text('Enter a landmark or complete address.'), findsOneWidget);
    await tapVisible(tester, const Key('ride-cancel-added-stop'));
    expect(ride.addedStop, isNull);
    expect(ride.fare, ride.selectedPackage.fare);
  });

  testWidgets(
    'payment failure exact retry creates one receipt and no duplicate',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final gateway = ReviewRideGateway(
        failNextPayment: true,
        latency: Duration.zero,
      );
      final ride = RideSession(gateway: gateway);
      await ride.bookRide();
      ride.startTrip();
      ride.reachDestination();
      final tripId = ride.trip!.id;
      addTearDown(journey.dispose);
      addTearDown(ride.dispose);
      await mount(
        tester,
        route: '/app/ride/trip/$tripId',
        journey: journey,
        ride: ride,
      );

      await tapVisible(tester, const Key('ride-approve-payment'));
      expect(find.textContaining('No money was deducted'), findsOneWidget);
      expect(ride.stage, RideTripStage.paymentApproval);
      expect(gateway.paymentCalls, 1);
      await tapVisible(tester, const Key('ride-approve-payment'));
      expect(ride.stage, RideTripStage.receipt);
      expect(gateway.paymentCalls, 2);
      expect(find.byKey(const Key('ride-approve-payment')), findsNothing);
      expect(await ride.approvePayment(), isFalse);
      expect(gateway.paymentCalls, 2);
    },
  );

  testWidgets(
    'support validates detail, retries evidence and avoids duplicate',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final journey = await readyJourney();
      final gateway = ReviewRideGateway(
        failNextSupport: true,
        latency: Duration.zero,
      );
      final ride = RideSession(gateway: gateway);
      await ride.bookRide();
      ride.startTrip();
      ride.reachDestination();
      await ride.approvePayment();
      ride.chooseIssue(RideIssueType.fare);
      final tripId = ride.trip!.id;
      addTearDown(journey.dispose);
      addTearDown(ride.dispose);
      await mount(
        tester,
        route: '/app/ride/trip/$tripId/support',
        journey: journey,
        ride: ride,
      );

      await tapVisible(tester, const Key('ride-submit-support'));
      expect(find.textContaining('Add a short detail'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('ride-support-detail')),
        'Final fare does not match the route shown',
      );
      await tapVisible(tester, const Key('ride-submit-support'));
      expect(
        find.textContaining('could not attach the evidence'),
        findsOneWidget,
      );
      expect(gateway.supportCalls, 1);
      expect(ride.supportTicket, isNull);
      await tapVisible(tester, const Key('ride-submit-support'));
      expect(gateway.supportCalls, 2);
      final ticketId = ride.supportTicket!.id;
      await tapVisible(tester, const Key('ride-submit-support'));
      expect(gateway.supportCalls, 2);
      expect(ride.supportTicket!.id, ticketId);
      await tapVisible(tester, const Key('ride-track-support'));
      expect(
        find.byKey(const Key('ride-support-confirmation')),
        findsOneWidget,
      );
      expect(find.textContaining('assigned to Ride Support'), findsOneWidget);
    },
  );

  testWidgets('safety, receipt and quick actions complete visibly', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final journey = await readyJourney();
    final ride = RideSession(
      gateway: ReviewRideGateway(latency: Duration.zero),
    );
    await ride.bookRide();
    final tripId = ride.trip!.id;
    addTearDown(journey.dispose);
    addTearDown(ride.dispose);
    await mount(
      tester,
      route: '/app/ride/trip/$tripId',
      journey: journey,
      ride: ride,
    );

    await tapVisible(tester, const Key('ride-call-captain'));
    expect(find.textContaining('Calling Arjun'), findsOneWidget);
    await tapVisible(tester, const Key('dismiss-ride-message'));
    await tapVisible(tester, const Key('ride-open-safety'));
    await tapVisible(tester, const Key('ride-safety-share'));
    expect(find.textContaining('safety link'), findsOneWidget);

    ride.startTrip();
    ride.reachDestination();
    await ride.approvePayment();
    await tester.pumpAndSettle();
    await tapVisible(tester, const Key('ride-download-receipt'));
    expect(find.textContaining('Receipt downloaded'), findsOneWidget);
    await tapVisible(tester, const Key('dismiss-ride-message'));
    await tapVisible(tester, const Key('ride-share-receipt'));
    expect(find.textContaining('ready to share'), findsOneWidget);
  });

  testWidgets('compact ride targets remain at least 44 points', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final journey = await readyJourney();
    final ride = RideSession(
      gateway: ReviewRideGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(ride.dispose);
    await mount(
      tester,
      route: '/app/ride/book',
      journey: journey,
      ride: ride,
      size: const Size(360, 800),
    );

    final content = find.byKey(const Key('ride-booking-screen'));
    for (final key in const [
      Key('ride-edit-route'),
      Key('ride-time-now'),
      Key('ride-time-15'),
      Key('ride-time-schedule'),
      Key('ride-type-bike'),
      Key('ride-type-auto'),
      Key('ride-type-cab'),
      Key('ride-dock-mool'),
      Key('ride-dock-book'),
      Key('ride-dock-trip'),
      Key('ride-dock-help'),
      Key('ride-dock-chat'),
    ]) {
      final finder = find.byKey(key);
      for (
        var attempt = 0;
        attempt < 10 && finder.evaluate().isEmpty;
        attempt += 1
      ) {
        await tester.drag(content, const Offset(0, -120), warnIfMissed: false);
        await tester.pumpAndSettle();
      }
      expect(finder, findsOneWidget, reason: '$key missing');
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
    }
    expect(tester.takeException(), isNull);
  });
}
