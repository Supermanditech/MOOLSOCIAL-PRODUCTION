import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

typedef DestinationCase = ({
  String name,
  String familyId,
  String route,
  Key sourceOwner,
  Key localNavigationOwner,
  Key localAction,
  Key destinationOwner,
  Key retiredRailOwner,
});

const destinations = <DestinationCase>[
  (
    name: 'Social',
    familyId: 'social',
    route: '/app/social?sub=feed',
    sourceOwner: Key('screen04-feed-thumb-composer'),
    localNavigationOwner: Key('screen04-context-tabs'),
    localAction: Key('screen04-rail-create'),
    destinationOwner: Key('screen04-create-workbench'),
    retiredRailOwner: ValueKey(
      'moolsocial-social-translucent-subaction-family-rail',
    ),
  ),
  (
    name: 'Shop',
    familyId: 'buy',
    route: '/app/buy?sub=shop',
    sourceOwner: ValueKey('buy-v2-screen'),
    localNavigationOwner: ValueKey('buy-local-destination-tabs'),
    localAction: Key('buy-local-tab-orders'),
    destinationOwner: PageStorageKey('buy-orders'),
    retiredRailOwner: ValueKey(
      'moolsocial-buy-translucent-subaction-family-rail',
    ),
  ),
  (
    name: 'Food',
    familyId: 'eat',
    route: '/app/eat/home',
    sourceOwner: Key('eat-home-screen'),
    localNavigationOwner: Key('eat-local-navigation'),
    localAction: Key('eat-local-table'),
    destinationOwner: Key('eat-table-screen'),
    retiredRailOwner: ValueKey(
      'moolsocial-eat-translucent-subaction-family-rail',
    ),
  ),
  (
    name: 'Travel',
    familyId: 'ride',
    route: '/app/ride/book?type=auto',
    sourceOwner: Key('ride-booking-screen'),
    localNavigationOwner: Key('ride-local-navigation'),
    localAction: Key('ride-local-cab'),
    destinationOwner: Key('ride-booking-screen'),
    retiredRailOwner: ValueKey(
      'moolsocial-ride-translucent-subaction-family-rail',
    ),
  ),
  (
    name: 'Care',
    familyId: 'book',
    route: '/app/book/doctor',
    sourceOwner: Key('doctor-discovery-home'),
    localNavigationOwner: Key('care-book-local-navigation'),
    localAction: Key('care-local-salon'),
    destinationOwner: Key('salon-discovery-home'),
    retiredRailOwner: ValueKey(
      'moolsocial-book-translucent-subaction-family-rail',
    ),
  ),
  (
    name: 'Work',
    familyId: 'work',
    route: '/app/work/my-work',
    sourceOwner: Key('work-choose-screen'),
    localNavigationOwner: Key('work-local-navigation'),
    localAction: Key('work-local-earn'),
    destinationOwner: Key('work-earn-screen'),
    retiredRailOwner: ValueKey(
      'moolsocial-work-translucent-subaction-family-rail',
    ),
  ),
];

void main() {
  Future<JourneySession> mount(
    WidgetTester tester,
    DestinationCase destination, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool reducedMotion = false,
  }) async {
    await tester.binding.setSurfaceSize(size);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    if (reducedMotion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
    }
    final journey = JourneySession(
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
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        initialLocation: destination.route,
      ),
    );
    await tester.pumpAndSettle();
    return journey;
  }

  void resetEnvironment(WidgetTester tester) {
    tester.binding.setSurfaceSize(null);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  }

  for (final destination in destinations) {
    testWidgets(
      '${destination.name} keeps direct local actions and a compact main menu',
      (tester) async {
        final journey = await mount(tester, destination);
        addTearDown(journey.dispose);
        addTearDown(() => resetEnvironment(tester));

        expect(find.byKey(destination.sourceOwner), findsOneWidget);
        expect(find.byKey(destination.localNavigationOwner), findsOneWidget);
        expect(find.byKey(destination.retiredRailOwner), findsNothing);
        final localAction = find.byKey(destination.localAction);
        expect(localAction, findsOneWidget);
        expect(tester.getSize(localAction).height, greaterThanOrEqualTo(44));
        final launcher = find.byKey(const Key('mool-compact-launcher'));
        expect(tester.getSize(launcher).height, greaterThanOrEqualTo(44));

        await tester.tap(launcher);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsOneWidget,
        );
        expect(find.byKey(destination.sourceOwner), findsOneWidget);
        final familyAction = find.byKey(
          ValueKey('mool-navigator-family-${destination.familyId}'),
        );
        expect(tester.getSize(familyAction).height, greaterThanOrEqualTo(44));

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsNothing,
        );
        expect(find.byKey(destination.sourceOwner), findsOneWidget);

        await tester.tap(localAction);
        await tester.pumpAndSettle();
        expect(find.byKey(destination.destinationOwner), findsOneWidget);
        expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'all connected family actions fit compact large text with reduced motion',
    (tester) async {
      for (final destination in destinations) {
        final journey = await mount(
          tester,
          destination,
          size: const Size(320, 568),
          textScale: 1.4,
          reducedMotion: true,
        );
        final localAction = find.byKey(destination.localAction);
        expect(localAction, findsOneWidget, reason: destination.name);
        expect(tester.getSize(localAction).height, greaterThanOrEqualTo(44));
        final launcher = find.byKey(const Key('mool-compact-launcher'));
        expect(tester.getSize(launcher).height, greaterThanOrEqualTo(44));
        await tester.tap(launcher);
        await tester.pump();
        final action = find.byKey(
          ValueKey('mool-navigator-family-${destination.familyId}'),
        );
        expect(action, findsOneWidget, reason: destination.name);
        expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull, reason: destination.name);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        journey.dispose();
      }
      resetEnvironment(tester);
    },
  );
}
