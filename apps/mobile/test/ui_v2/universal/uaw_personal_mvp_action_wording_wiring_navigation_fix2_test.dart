import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/ride/ride_models.dart';
import 'package:moolsocial/features/ride/ride_services.dart';
import 'package:moolsocial/features/ride/ride_session.dart';
import 'package:moolsocial/ui_v2/universal/mvp_action_choice_root_v2.dart';

void main() {
  JourneySession signedInSession() {
    return JourneySession(
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
  }

  Widget chooserHarness(
    MvpActionChoiceRootSpec spec, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool reduceMotion = false,
    ValueChanged<MvpActionChoiceSpec>? onAction,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
          accessibleNavigation: reduceMotion,
        ),
        child: MvpActionChoiceRootV2(
          sectionLabel: spec.sectionLabel,
          headline: spec.headline,
          supportingText: spec.supportingText,
          actions: spec.actions,
          onBack: () {},
          onOpenAction: onAction ?? (_) {},
          onOpenMainAction: (_) {},
          onOpenMool: () {},
          onOpenChat: () {},
        ),
      ),
    );
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final target = find.byKey(key);
    expect(target, findsOneWidget, reason: 'Missing $key');
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  test(
    'FIX2 contract pins the shared dock and creates no new runtime owner',
    () {
      final contractFile = File.fromUri(
        Directory.current.uri.resolve(
          '../../config/mvp-personal-action-navigation-continuity-fix2.json',
        ),
      );
      final contract = jsonDecode(contractFile.readAsStringSync()) as Map;
      final owners = contract['implementationOwners'] as Map;
      final navigation = contract['navigation'] as Map;
      final motion = contract['motion'] as Map;

      expect(
        contract['ticketId'],
        'UAW-PERSONAL-MVP-ACTION-WORDING-WIRING-NAVIGATION-FIX2',
      );
      expect(owners['persistentDock'], 'MoolGlobalNavigationV2');
      expect(owners['newScreenOwners'], 0);
      expect(owners['newRouteOwners'], 0);
      expect(owners['newBackendOwners'], 0);
      expect(navigation['chooserSubActionsRemainInContent'], isTrue);
      expect(navigation['destinationSubActionsNeverReplaceGlobalDock'], isTrue);
      expect(navigation['topLevelVisibleBackAllowed'], isFalse);
      expect(navigation['activeLifecycleMayBeSilentlyReset'], isFalse);
      expect(motion['chooserArrivalMilliseconds'], 240);
      expect(motion['dockSelectionMilliseconds'], 160);
      expect(motion['reducedMotionRequired'], isTrue);
    },
  );

  for (final entry in personalMvpActionChoiceRoots.entries) {
    testWidgets(
      '${entry.value.sectionLabel} keeps direct choices with one connected launcher',
      (tester) async {
        final opened = <String>[];
        await tester.pumpWidget(
          chooserHarness(
            entry.value,
            onAction: (action) => opened.add(action.route),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel('Open MoolSocial main menu'),
          findsOneWidget,
        );
        for (final action in entry.value.actions) {
          await tester.tap(find.byKey(Key('mvp-action-choice-${action.id}')));
          await tester.pump();
        }
        expect(find.byKey(Key('mvp-action-${entry.key}-back')), findsNothing);
        expect(opened, entry.value.actions.map((action) => action.route));

        await tester.tap(find.byKey(const Key('mool-home-launcher')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(Key('mvp-action-root-${entry.key}')), findsOneWidget);
        expect(find.byKey(const Key('mool-root-selected')), findsNothing);
        expect(find.byKey(const Key('mool-root-chat')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Ride main-only menu fits 320 px at scaled text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      chooserHarness(
        personalMvpActionChoiceRoots['ride']!,
        size: const Size(320, 568),
        textScale: 1.4,
      ),
    );
    await tester.pumpAndSettle();

    final launcher = find.byKey(const Key('mool-home-launcher'));
    expect(tester.getSize(launcher).height, greaterThanOrEqualTo(44));
    await tester.tap(launcher);
    await tester.pumpAndSettle();
    for (final family in const [
      'social',
      'buy',
      'eat',
      'ride',
      'book',
      'work',
    ]) {
      final target = find.byKey(Key('mool-navigator-family-$family'));
      expect(target, findsOneWidget);
      expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
    }
    expect(find.byKey(const Key('mool-navigator-ride-bike')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chooser and launcher resolve immediately for reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      chooserHarness(personalMvpActionChoiceRoots['ride']!, reduceMotion: true),
    );
    await tester.pump();

    for (final action in personalRideActionChoices) {
      final opacity = tester.widget<Opacity>(
        find.byKey(Key('mvp-action-arrival-${action.id}')),
      );
      expect(opacity.opacity, 1);
    }
    await tester.tap(find.byKey(const Key('mool-home-launcher')));
    await tester.pump();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(350, 100));
    await tester.pump();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  for (final destination in const [
    (
      section: 'eat',
      action: 'order',
      localKey: 'eat-local-order',
      owner: Key('eat-home-screen'),
      rideType: null,
    ),
    (
      section: 'eat',
      action: 'table',
      localKey: 'eat-local-table',
      owner: Key('eat-table-screen'),
      rideType: null,
    ),
    (
      section: 'ride',
      action: 'bike',
      localKey: 'ride-local-bike',
      owner: Key('ride-booking-screen'),
      rideType: RideType.bike,
    ),
    (
      section: 'ride',
      action: 'auto',
      localKey: 'ride-local-auto',
      owner: Key('ride-booking-screen'),
      rideType: RideType.auto,
    ),
    (
      section: 'ride',
      action: 'cab',
      localKey: 'ride-local-cab',
      owner: Key('ride-booking-screen'),
      rideType: RideType.cab,
    ),
    (
      section: 'book',
      action: 'doctor',
      localKey: 'care-local-doctor',
      owner: Key('book-doctor'),
      rideType: null,
    ),
    (
      section: 'book',
      action: 'salon',
      localKey: 'care-local-salon',
      owner: Key('salon-service-haircut'),
      rideType: null,
    ),
    (
      section: 'ride',
      action: 'bus',
      localKey: 'ride-local-bus',
      owner: Key('bus-booking-home'),
      rideType: null,
    ),
    (
      section: 'work',
      action: 'earn',
      localKey: 'work-local-earn',
      owner: Key('work-earn-screen'),
      rideType: null,
    ),
    (
      section: 'work',
      action: 'workspace',
      localKey: 'work-local-workspace',
      owner: Key('my-work-screen'),
      rideType: null,
    ),
  ]) {
    testWidgets(
      '${destination.section} ${destination.action} opens from its local rail',
      (tester) async {
        final journey = signedInSession();
        final ride = RideSession(
          gateway: ReviewRideGateway(latency: Duration.zero),
        );
        addTearDown(journey.dispose);
        addTearDown(ride.dispose);
        await journey.start();

        await tester.pumpWidget(
          MoolSocialApp(
            session: journey,
            rideSession: ride,
            initialLocation: '/app/${destination.section}',
          ),
        );
        await tester.pumpAndSettle();
        await tapVisible(tester, Key(destination.localKey));

        expect(find.byKey(destination.owner), findsOneWidget);
        expect(
          find.byKey(Key('mvp-action-root-${destination.section}')),
          findsNothing,
        );
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
        if (destination.rideType != null) {
          expect(ride.selectedType, destination.rideType);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final journeyCase in const [
    (section: 'eat', route: '/app/eat/table', owner: Key('eat-table-screen')),
    (
      section: 'ride',
      route: '/app/ride/book?type=auto',
      owner: Key('ride-booking-screen'),
    ),
    (
      section: 'book',
      route: '/app/book/salon',
      owner: Key('salon-service-haircut'),
    ),
    (section: 'work', route: '/app/work/my-work', owner: Key('my-work-screen')),
  ]) {
    testWidgets(
      '${journeyCase.section} chooser Back preserves the exact non-default owner',
      (tester) async {
        final journey = signedInSession();
        addTearDown(journey.dispose);
        await journey.start();
        await tester.pumpWidget(
          MoolSocialApp(session: journey, initialLocation: journeyCase.route),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(journeyCase.owner), findsOneWidget);
        await tapVisible(tester, const Key('mool-compact-launcher'));
        expect(find.byKey(journeyCase.owner), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.byKey(journeyCase.owner), findsOneWidget);
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsNothing,
        );
      },
    );
  }

  for (final rideType in const [RideType.bike, RideType.auto, RideType.cab]) {
    testWidgets('Ride ${rideType.name} chooser Back preserves exact type', (
      tester,
    ) async {
      final journey = signedInSession();
      final ride = RideSession(
        gateway: ReviewRideGateway(latency: Duration.zero),
      );
      addTearDown(journey.dispose);
      addTearDown(ride.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          rideSession: ride,
          initialLocation: '/app/ride/book?type=${rideType.name}',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ride-booking-screen')), findsOneWidget);
      expect(ride.selectedType, rideType);

      await tapVisible(tester, const Key('mool-compact-launcher'));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ride-booking-screen')), findsOneWidget);
      expect(ride.selectedType, rideType);
    });
  }

  testWidgets('active ride blocks unsafe connected cross-type reset', (
    tester,
  ) async {
    final journey = signedInSession();
    final ride = RideSession(
      gateway: ReviewRideGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(ride.dispose);
    await journey.start();
    ride.chooseType(RideType.auto);
    expect(await ride.bookRide(), isTrue);
    final originalTrip = ride.trip;

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        rideSession: ride,
        initialLocation: '/app/ride/trip/${originalTrip!.id}',
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, const Key('ride-local-cab'));

    expect(ride.trip, same(originalTrip));
    expect(ride.selectedType, RideType.auto);
    expect(find.byKey(const Key('ride-arriving-screen')), findsOneWidget);
    expect(find.byKey(const Key('ride-booking-screen')), findsNothing);
    expect(find.textContaining('Auto ride is still active'), findsOneWidget);
  });
}
