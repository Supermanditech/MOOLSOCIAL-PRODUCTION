import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/eat/eat_services.dart';
import 'package:moolsocial/features/eat/eat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<(JourneySession, EatSession)> mount(
    WidgetTester tester, {
    bool reducedMotion = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    if (reducedMotion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
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
    final eat = EatSession(
      gateway: ReviewEatOrderGateway(latency: Duration.zero),
    );
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        eatSession: eat,
        initialLocation: '/app/eat/home',
      ),
    );
    await tester.pumpAndSettle();
    return (journey, eat);
  }

  void resetEnvironment(WidgetTester tester) {
    tester.binding.setSurfaceSize(null);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  }

  testWidgets(
    'Eat two-action family is connected, direct and Back continuous',
    (tester) async {
      final semantics = tester.ensureSemantics();
      JourneySession? journey;
      EatSession? eat;
      try {
        (journey, eat) = await mount(tester);
        expect(find.byKey(const Key('eat-local-navigation')), findsOneWidget);
        final launcher = find.byKey(const Key('mool-compact-launcher'));
        expect(tester.getSize(launcher).height, greaterThanOrEqualTo(44));
        final search = find.byKey(const Key('eat-home-search'));
        expect(search.hitTestable(), findsOneWidget);

        for (final id in const ['order', 'table']) {
          final action = find.byKey(Key('eat-local-$id'));
          expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
          if (id == 'table') {
            expect(
              tester
                  .getSemantics(find.bySemanticsLabel('Open Book Table'))
                  .getSemanticsData()
                  .hasAction(SemanticsAction.tap),
              isTrue,
            );
          }
        }

        await tester.tap(find.byKey(const Key('eat-local-table')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('eat-table-screen')), findsOneWidget);
        expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);
        expect(
          find.byKey(const Key('eat-home-search')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
        journey?.dispose();
        eat?.dispose();
        resetEnvironment(tester);
      }
    },
  );

  testWidgets('Eat connected chooser is immediate under reduced motion', (
    tester,
  ) async {
    JourneySession? journey;
    EatSession? eat;
    try {
      (journey, eat) = await mount(tester, reducedMotion: true);
      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pump();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsNothing,
      );
      expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      journey?.dispose();
      eat?.dispose();
      resetEnvironment(tester);
    }
  });
}
