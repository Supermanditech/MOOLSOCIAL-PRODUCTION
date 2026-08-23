import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

typedef DefaultLandingCase = ({
  String name,
  String id,
  String route,
  Key owner,
  Key localNavigationOwner,
});

const defaultLandings = <DefaultLandingCase>[
  (
    name: 'Social',
    id: 'social',
    route: '/app/social',
    owner: Key('screen04-universal-v2'),
    localNavigationOwner: Key('screen04-context-tabs'),
  ),
  (
    name: 'Shop',
    id: 'buy',
    route: '/app/buy?sub=shop',
    owner: ValueKey('buy-v2-screen'),
    localNavigationOwner: ValueKey('buy-local-destination-tabs'),
  ),
  (
    name: 'Food',
    id: 'eat',
    route: '/app/eat/home',
    owner: Key('eat-home-screen'),
    localNavigationOwner: Key('eat-local-navigation'),
  ),
  (
    name: 'Travel',
    id: 'ride',
    route: '/app/ride/book?type=bike',
    owner: Key('ride-booking-screen'),
    localNavigationOwner: Key('ride-local-navigation'),
  ),
  (
    name: 'Care',
    id: 'book',
    route: '/app/book/doctor',
    owner: Key('book-doctor'),
    localNavigationOwner: Key('care-book-local-navigation'),
  ),
  (
    name: 'Work',
    id: 'work',
    route: '/app/work/earn',
    owner: Key('work-earn-screen'),
    localNavigationOwner: Key('work-local-navigation'),
  ),
];

final retiredChoiceRoots = <String, DefaultLandingCase>{
  '/app/eat': defaultLandings[2],
  '/app/ride': defaultLandings[3],
  '/app/book': defaultLandings[4],
  '/app/work': defaultLandings[5],
};

const chooserHeadlines = <String>[
  'What would you like?',
  'How do you want to ride?',
  'What would you like to book?',
  'What would you like to do?',
];

void main() {
  JourneySession createReadyJourney() {
    return JourneySession(
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
  }

  Future<JourneySession> mount(
    WidgetTester tester, {
    required String initialLocation,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final journey = createReadyJourney();
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        initialLocation: initialLocation,
      ),
    );
    await tester.pumpAndSettle();
    return journey;
  }

  Future<void> unmount(WidgetTester tester, JourneySession journey) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    journey.dispose();
    await tester.binding.setSurfaceSize(null);
  }

  void expectDefaultLanding(
    WidgetTester tester,
    DefaultLandingCase destination,
  ) {
    expect(find.byKey(destination.owner), findsOneWidget);
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    expect(find.byKey(destination.localNavigationOwner), findsOneWidget);
    expect(find.byType(MoolLocalNavigationRail), findsOneWidget);
    for (final headline in chooserHeadlines) {
      expect(find.text(headline), findsNothing);
    }
  }

  test('global main actions name the existing default sub-action routes', () {
    expect(
      personalMoolRootActions.map((action) => (action.id, action.route)),
      defaultLandings.map((destination) => (destination.id, destination.route)),
    );
    expect(
      personalMoolRootActions.map((action) => action.route),
      isNot(containsAll(retiredChoiceRoots.keys)),
    );
  });

  for (final destination in defaultLandings) {
    testWidgets(
      '${destination.name} family and first direct action open its default owner',
      (tester) async {
        final semantics = tester.ensureSemantics();
        JourneySession? journey;
        try {
          journey = await mount(tester, initialLocation: '/app/mool');
          final familyButton = find.byKey(
            ValueKey('mool-home-family-${destination.id}'),
          );
          expect(familyButton, findsOneWidget);
          await tester.tap(familyButton);
          await tester.pumpAndSettle();

          expectDefaultLanding(tester, destination);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
          if (journey != null) await unmount(tester, journey);
        }
      },
    );
  }

  for (final entry in retiredChoiceRoots.entries) {
    testWidgets('${entry.key} resolves before the legacy chooser can render', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      JourneySession? journey;
      try {
        journey = await mount(tester, initialLocation: entry.key);
        expectDefaultLanding(tester, entry.value);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
        if (journey != null) await unmount(tester, journey);
      }
    });
  }
}
