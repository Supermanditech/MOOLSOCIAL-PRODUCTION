import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/ride/ride_models.dart';
import 'package:moolsocial/features/ride/ride_session.dart';

void main() {
  JourneySession signedInSession() => JourneySession(
    store: MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'current',
        currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
        setupComplete: true,
        setupExperienceVersion: approvedSetupExperienceVersion,
      ),
    ),
    otpGateway: ReviewOtpGateway(signedIn: true),
  );

  Future<void> pumpApp(
    WidgetTester tester,
    JourneySession journey,
    String location, {
    RideSession? ride,
  }) async {
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        rideSession: ride,
        initialLocation: location,
      ),
    );
    await tester.pumpAndSettle();
  }

  test('C02 retained a stable Home owner and created no duplicate owner', () {
    final contract =
        jsonDecode(
              File.fromUri(
                Directory.current.uri.resolve(
                  '../../config/'
                  'mvp-personal-global-mool-bottom-rail-navigation-fix1.json',
                ),
              ).readAsStringSync(),
            )
            as Map;
    final rules = contract['rules'] as Map;
    final implementation = contract['implementation'] as Map;
    expect(rules['moolIsStableHub'], isTrue);
    expect(rules['moolMayAliasSocial'], isFalse);
    expect(rules['moolMayOpenModalMenu'], isFalse);
    expect(implementation['newScreens'], 0);
    expect(implementation['newNamedRoutes'], 0);
    expect(implementation['newBackendOwners'], 0);
  });

  testWidgets('Home is the fixed six-family entry owner without a dock', (
    tester,
  ) async {
    final journey = signedInSession();
    addTearDown(journey.dispose);
    await journey.start();
    await pumpApp(tester, journey, '/app/mool');

    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
    expect(find.byKey(const Key('mool-home-dashboard')), findsOneWidget);
    expect(
      find.byKey(const Key('moolsocial-home-has-no-bottom-navigation')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mool-home-launcher')), findsNothing);
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    for (final family in const [
      'social',
      'buy',
      'eat',
      'ride',
      'book',
      'work',
    ]) {
      expect(find.byKey(Key('mool-home-family-$family')), findsOneWidget);
    }
  });

  for (final destination in const [
    (id: 'eat', owner: Key('eat-home-screen')),
    (id: 'ride', owner: Key('ride-booking-screen')),
    (id: 'book', owner: Key('doctor-discovery-home')),
    (id: 'work', owner: Key('work-earn-screen')),
  ]) {
    testWidgets(
      '${destination.id} connected chooser Back restores exact owner',
      (tester) async {
        final journey = signedInSession();
        addTearDown(journey.dispose);
        await journey.start();
        await pumpApp(tester, journey, '/app/${destination.id}');

        expect(find.byKey(destination.owner), findsOneWidget);
        await tester.tap(find.byKey(const Key('mool-compact-launcher')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsOneWidget,
        );
        expect(find.byKey(destination.owner), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsNothing,
        );
        expect(find.byKey(destination.owner), findsOneWidget);
      },
    );
  }

  for (final downstream in const [
    (
      id: 'eat',
      route: '/app/eat/home',
      owner: Key('eat-home-screen'),
      currentAction: Key('mool-navigator-family-eat'),
      localAction: Key('eat-local-order'),
    ),
    (
      id: 'book',
      route: '/app/book/doctor',
      owner: Key('doctor-discovery-home'),
      currentAction: Key('mool-navigator-family-book'),
      localAction: Key('care-local-doctor'),
    ),
    (
      id: 'work',
      route: '/app/work/my-work',
      owner: Key('work-choose-screen'),
      currentAction: Key('mool-navigator-family-work'),
      localAction: Key('work-local-workspace'),
    ),
  ]) {
    testWidgets('${downstream.id} deep owner keeps its connected action', (
      tester,
    ) async {
      final journey = signedInSession();
      addTearDown(journey.dispose);
      await journey.start();
      await pumpApp(tester, journey, downstream.route);

      expect(find.byKey(downstream.owner), findsOneWidget);
      expect(find.byKey(downstream.localAction), findsOneWidget);
      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();
      expect(find.byKey(downstream.currentAction), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(downstream.owner), findsOneWidget);
    });
  }

  testWidgets('Ride Auto survives connected chooser dismissal', (tester) async {
    final journey = signedInSession();
    final ride = RideSession();
    addTearDown(journey.dispose);
    addTearDown(ride.dispose);
    await journey.start();
    await pumpApp(tester, journey, '/app/ride/book?type=auto', ride: ride);
    expect(ride.selectedType, RideType.auto);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(ride.selectedType, RideType.auto);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ride-booking-screen')), findsOneWidget);
    expect(ride.selectedType, RideType.auto);
    expect(find.byKey(const Key('ride-local-auto')), findsOneWidget);
  });

  testWidgets('direct Home origin Back uses the safe Ride default fallback', (
    tester,
  ) async {
    final journey = signedInSession();
    addTearDown(journey.dispose);
    await journey.start();
    await pumpApp(tester, journey, '/app/mool?from=ride');

    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ride-booking-screen')), findsOneWidget);
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
  });

  testWidgets('Home main action keeps route history back to fixed Home', (
    tester,
  ) async {
    final journey = signedInSession();
    addTearDown(journey.dispose);
    await journey.start();
    await pumpApp(tester, journey, '/app/mool');

    await tester.tap(find.byKey(const Key('mool-home-family-work')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
  });
}
