import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/ride/ride_models.dart';
import 'package:moolsocial/features/ride/ride_session.dart';
import 'package:moolsocial/ui_v2/universal/mvp_action_choice_root_v2.dart';

void main() {
  test('runtime Ride choices match the versioned R07 contract', () {
    final contractFile = File.fromUri(
      Directory.current.uri.resolve(
        '../../config/mvp-personal-ride-exposure-interaction-v1.json',
      ),
    );
    final contract = jsonDecode(contractFile.readAsStringSync()) as Map;
    final actions = (contract['actions'] as List).cast<Map>();

    expect(
      personalRideActionChoices
          .map((action) => [action.id, action.label, action.route])
          .toList(),
      actions
          .map((action) => [action['id'], action['label'], action['route']])
          .toList(),
    );
    expect(personalRideActionChoices.map((action) => action.id), [
      'bike',
      'auto',
      'cab',
    ]);
    expect(contract['presentationOwner'], 'MvpActionChoiceRootV2');
    expect(contract['newScreenOwners'], 0);
    expect(contract['newRouteOwners'], 0);
    expect(contract['newBackendOwners'], 0);
  });

  for (final vehicle in const [
    (id: 'bike', type: RideType.bike),
    (id: 'auto', type: RideType.auto),
    (id: 'cab', type: RideType.cab),
  ]) {
    testWidgets(
      'production Ride root switches to ${vehicle.id} without returning Home',
      (tester) async {
        final sessions = await _mount(tester, '/app/ride');
        addTearDown(sessions.dispose);

        _expectCurrentRideShell();
        await _selectConnectedRide(tester, vehicle.id);
        expect(sessions.ride.selectedType, vehicle.type);
        _expectCurrentRideShell();

        await tester.tap(find.byKey(const Key('mool-compact-launcher')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsNothing,
        );
        expect(find.byKey(const Key('ride-booking-screen')), findsOneWidget);
        expect(sessions.ride.selectedType, vehicle.type);
      },
    );
  }

  for (final vehicle in const [
    (id: 'bike', type: RideType.bike),
    (id: 'auto', type: RideType.auto),
    (id: 'cab', type: RideType.cab),
  ]) {
    testWidgets('direct ${vehicle.id} exposes the exact Ride owner', (
      tester,
    ) async {
      final sessions = await _mount(
        tester,
        '/app/ride/book?type=${vehicle.id}',
      );
      addTearDown(sessions.dispose);

      _expectCurrentRideShell();
      expect(sessions.ride.selectedType, vehicle.type);
      final uri = GoRouterState.of(
        tester.element(find.byKey(const Key('ride-booking-screen'))),
      ).uri;
      expect(uri.path, '/app/ride/book');
      expect(uri.queryParameters['type'], vehicle.id);
    });
  }

  testWidgets('Ride connected chooser Back restores the exact default owner', (
    tester,
  ) async {
    final sessions = await _mount(tester, '/app/ride');
    addTearDown(sessions.dispose);
    _expectCurrentRideShell();

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ride-booking-screen')), findsOneWidget);
    expect(sessions.ride.selectedType, RideType.bike);
    expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
  });
}

Future<_Sessions> _mount(WidgetTester tester, String location) async {
  final journey = JourneySession(
    store: MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'current',
        currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
        setupComplete: true,
      ),
    ),
    otpGateway: ReviewOtpGateway(signedIn: true),
  );
  final ride = RideSession();
  await journey.start();
  await tester.pumpWidget(
    MoolSocialApp(
      session: journey,
      rideSession: ride,
      initialLocation: location,
    ),
  );
  await tester.pumpAndSettle();
  return _Sessions(journey, ride);
}

Future<void> _selectConnectedRide(WidgetTester tester, String id) async {
  if (id != 'bike') {
    await tester.tap(find.byKey(Key('ride-local-$id')));
    await tester.pumpAndSettle();
  }
}

void _expectCurrentRideShell() {
  expect(find.byKey(const Key('ride-booking-screen')), findsOneWidget);
  expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
  expect(find.byKey(const Key('mvp-action-root-ride')), findsNothing);
  expect(find.byKey(const Key('ride-local-navigation')), findsOneWidget);
  for (final action in const ['bike', 'auto', 'cab', 'bus']) {
    expect(find.byKey(Key('ride-local-$action')), findsOneWidget);
  }
  expect(
    find.byKey(
      const ValueKey('moolsocial-ride-translucent-subaction-family-rail'),
    ),
    findsNothing,
  );
  expect(find.byKey(const Key('mool-root-selected')), findsNothing);
  expect(find.text('Tiffin'), findsNothing);
  expect(find.text('Pay'), findsNothing);
  expect(find.text('Get It Done'), findsNothing);
}

class _Sessions {
  const _Sessions(this.journey, this.ride);

  final JourneySession journey;
  final RideSession ride;

  void dispose() {
    journey.dispose();
    ride.dispose();
  }
}
