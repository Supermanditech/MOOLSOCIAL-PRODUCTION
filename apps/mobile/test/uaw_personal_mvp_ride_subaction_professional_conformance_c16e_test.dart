import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/core/design/mool_service_home.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/ride/ride_models.dart';
import 'package:moolsocial/features/ride/ride_services.dart';
import 'package:moolsocial/features/ride/ride_session.dart';

void main() {
  testWidgets(
    'Ride three-action family is contextual and changes booking in place',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final sessions = await _mount(tester);
      addTearDown(sessions.dispose);
      try {
        expect(find.byKey(const Key('ride-local-navigation')), findsOneWidget);
        expect(
          find.byKey(const Key('moolsocial-local-navigation-compact-cluster')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('moolsocial-local-navigation-compact-overflow')),
          findsNothing,
        );
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
        for (final id in const ['bike', 'auto', 'cab', 'bus']) {
          final action = find.byKey(Key('ride-local-$id'));
          expect(action, findsOneWidget);
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.getSize(action).width, greaterThanOrEqualTo(44));
          expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
        }

        await _scrollForward(tester, find.byKey(const Key('ride-type-bike')));
        for (final id in const ['bike', 'auto', 'cab']) {
          final action = find.byKey(Key('ride-type-$id'));
          expect(action, findsOneWidget);
          final size = tester.getSize(action);
          expect(size.width, greaterThanOrEqualTo(44), reason: id);
          expect(size.height, greaterThanOrEqualTo(44), reason: id);
        }

        var node = tester.getSemantics(find.byKey(const Key('ride-type-auto')));
        expect(node.label, contains('Auto'));
        expect(node.flagsCollection.isSelected, Tristate.isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

        final routeBefore = GoRouterState.of(
          tester.element(find.byKey(const Key('ride-booking-screen'))),
        ).uri.toString();
        await tester.tap(find.byKey(const Key('ride-type-cab')));
        await tester.pumpAndSettle();
        expect(sessions.ride.selectedType, RideType.cab);
        expect(find.byKey(const Key('ride-booking-screen')), findsOneWidget);
        final routeAfter = GoRouterState.of(
          tester.element(find.byKey(const Key('ride-booking-screen'))),
        ).uri.toString();
        expect(routeAfter, routeBefore);
        node = tester.getSemantics(find.byKey(const Key('ride-type-cab')));
        expect(node.label, contains('Cab'));
        expect(node.flagsCollection.isSelected, Tristate.isTrue);

        final package = find.byKey(
          ValueKey('ride-package-${sessions.ride.selectedPackage.id}'),
        );
        await _scrollForward(tester, package);
        expect(package.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Ride contextual selection settles immediately under reduced motion',
    (tester) async {
      final sessions = await _mount(tester, reducedMotion: true);
      addTearDown(sessions.dispose);

      final cab = find.byKey(const Key('ride-type-cab'));
      await _scrollForward(tester, cab);
      expect(
        MoolServiceHomeTokens.accessibleDuration(tester.element(cab)),
        Duration.zero,
      );
      await tester.tap(cab);
      await tester.pump();
      expect(sessions.ride.selectedType, RideType.cab);
      expect(find.byKey(const Key('ride-booking-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('four-action local rail overflows only below physical minimum', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 181,
            child: MoolLocalNavigationRail(
              familyId: 'ride',
              semanticLabel: 'Constrained travel choices',
              activeId: 'bike',
              actions: [
                for (final id in const ['bike', 'auto', 'cab', 'bus'])
                  MoolLocalNavigationAction(
                    keyName: 'constrained-ride-$id',
                    id: id,
                    label: id,
                    icon: Icons.circle_outlined,
                    onPressed: id == 'bike' ? null : () {},
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('moolsocial-local-navigation-compact-overflow')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const Key('moolsocial-local-navigation-compact-cluster'),
            ),
          )
          .width,
      182,
    );
    for (final id in const ['bike', 'auto', 'cab', 'bus']) {
      expect(tester.getSize(find.byKey(Key('constrained-ride-$id'))).width, 44);
    }
    expect(tester.takeException(), isNull);
  });
}

Future<_Sessions> _mount(
  WidgetTester tester, {
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.4;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (reducedMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  final journey = JourneySession(
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
  final ride = RideSession(gateway: ReviewRideGateway(latency: Duration.zero));
  await journey.start();
  await tester.pumpWidget(
    MoolSocialApp(
      key: UniqueKey(),
      session: journey,
      rideSession: ride,
      initialLocation: '/app/ride/book?type=auto',
    ),
  );
  await tester.pumpAndSettle();
  return _Sessions(journey, ride);
}

Future<void> _scrollForward(WidgetTester tester, Finder target) async {
  final content = find.byKey(const Key('ride-booking-screen'));
  for (var attempt = 0; attempt < 20 && target.evaluate().isEmpty; attempt++) {
    expect(content, findsOneWidget);
    await tester.drag(content, const Offset(0, -220));
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
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
