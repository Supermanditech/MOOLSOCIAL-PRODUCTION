import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/captain/captain_models.dart';
import 'package:moolsocial/features/captain/captain_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<void> verifyScreen(
    WidgetTester tester, {
    required String route,
    required String golden,
    void Function(CaptainSession session)? prepare,
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
    final captain = CaptainSession();
    prepare?.call(captain);
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
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile(golden));
  }

  testWidgets('Captain home 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/captain',
      golden: 'goldens/captain-116-home-412x915.png',
    );
  });

  testWidgets('Captain request 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/captain/requests',
      golden: 'goldens/captain-117-request-412x915.png',
    );
  });

  testWidgets('Captain pickup 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/captain/trips/MS-R4821/pickup',
      golden: 'goldens/captain-118-pickup-412x915.png',
      prepare: (session) {
        session
          ..availableForRides = true
          ..assignmentId = 'CAP-ASG-117-4821'
          ..tripState = CaptainTripState.pickup;
      },
    );
  });

  testWidgets('Captain live trip 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/captain/trips/MS-R4821',
      golden: 'goldens/captain-119-live-412x915.png',
      prepare: (session) {
        session
          ..availableForRides = true
          ..assignmentId = 'CAP-ASG-117-4821'
          ..captainArrivedAtPickup = true
          ..pickupOtp = '4821'
          ..tripStartId = 'CAP-START-118-4821'
          ..tripState = CaptainTripState.live;
      },
    );
  });

  testWidgets('Captain fare completion 412x915 visual baseline', (
    tester,
  ) async {
    await verifyScreen(
      tester,
      route: '/app/captain/trips/MS-R4821/complete',
      golden: 'goldens/captain-120-complete-412x915.png',
      prepare: (session) {
        session
          ..availableForRides = true
          ..assignmentId = 'CAP-ASG-117-4821'
          ..tripStartId = 'CAP-START-118-4821'
          ..arrivalId = 'CAP-ARR-119-4821'
          ..tripState = CaptainTripState.paymentPending;
      },
    );
  });

  testWidgets('Captain earnings 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/captain/earnings',
      golden: 'goldens/captain-121-earnings-412x915.png',
    );
  });

  testWidgets('Captain compliance 412x915 visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/captain/compliance',
      golden: 'goldens/captain-122-compliance-412x915.png',
    );
  });

  testWidgets('Captain support and work 412x915 visual baseline', (
    tester,
  ) async {
    await verifyScreen(
      tester,
      route: '/app/captain/support-work',
      golden: 'goldens/captain-123-support-412x915.png',
    );
  });
}
