import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    required String route,
    bool reduceMotion = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    if (reduceMotion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
    }
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
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      if (reduceMotion) {
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      }
      journey.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(key: UniqueKey(), session: journey, initialLocation: route),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final target = find.byKey(key);
    expect(target, findsOneWidget, reason: 'Missing $key');
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'deep Eat contextual switch and connected Work switch preserve one anchor',
    (tester) async {
      await mount(tester, route: '/app/eat/home');

      expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);
      expect(
        find.byKey(const Key('moolsocial-single-home-launcher-shell')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('eat-local-navigation')), findsOneWidget);
      expect(
        find.byKey(const Key('moolsocial-global-navigation')),
        findsNothing,
      );
      final eatLauncherRect = tester.getRect(
        find.byKey(const Key('moolsocial-compact-destination-rail')),
      );

      await tapVisible(tester, const Key('eat-local-table'));
      expect(find.byKey(const Key('eat-table-screen')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);

      await tapVisible(tester, const Key('mool-compact-launcher'));
      await tapVisible(tester, const Key('mool-navigator-family-work'));
      expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
      expect(
        find.byKey(const Key('moolsocial-single-home-launcher-shell')),
        findsOneWidget,
      );
      final workLauncherRect = tester.getRect(
        find.byKey(const Key('moolsocial-compact-destination-rail')),
      );
      expect(workLauncherRect, eatLauncherRect);
      expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Social connected self-route and Back keep exact ownership', (
    tester,
  ) async {
    await mount(tester, route: '/app/social');
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);

    await tapVisible(tester, const Key('mool-compact-launcher'));
    await tapVisible(tester, const Key('mool-navigator-family-social'));
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    expect(
      find.byKey(const Key('moolsocial-compact-destination-rail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('moolsocial-single-home-launcher-shell')),
      findsNothing,
    );

    await tapVisible(tester, const Key('mool-compact-launcher'));
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
  });

  for (final destination in const [
    (name: 'Eat', route: '/app/eat/home', owner: Key('eat-home-screen')),
    (
      name: 'Ride',
      route: '/app/ride/book?type=auto',
      owner: Key('ride-booking-screen'),
    ),
    (name: 'Book', route: '/app/book/doctor', owner: Key('book-doctor')),
    (
      name: 'Work',
      route: '/app/work/my-work',
      owner: Key('work-choose-screen'),
    ),
  ]) {
    testWidgets('${destination.name} keeps one connected shell owner', (
      tester,
    ) async {
      await mount(tester, route: destination.route);
      expect(find.byKey(destination.owner), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      expect(
        find.byKey(const Key('moolsocial-single-home-launcher-shell')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('moolsocial-global-navigation')),
        findsNothing,
      );
      expect(find.byKey(const Key('mool-root-selected')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reduced motion changes destination without visual transition', (
    tester,
  ) async {
    await mount(tester, route: '/app/eat/home', reduceMotion: true);
    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pump();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('mool-navigator-family-work')));
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const Key('moolsocial-main-destination-motion')),
      findsNothing,
    );
    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'main destination motion is finite and within the approved interval',
    () {
      expect(MoolMotion.standard, const Duration(milliseconds: 240));
      expect(MoolMotion.standard.inMilliseconds, inInclusiveRange(180, 320));
    },
  );
}
