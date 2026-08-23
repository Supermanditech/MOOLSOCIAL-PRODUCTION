import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_session.dart';

void main() {
  Future<(JourneySession, WorkSession)> mount(
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
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    final work = WorkSession();
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        workSession: work,
        initialLocation: '/app/work/earn',
      ),
    );
    await tester.pumpAndSettle();
    return (journey, work);
  }

  void resetEnvironment(WidgetTester tester) {
    tester.binding.setSurfaceSize(null);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  }

  testWidgets('Work two-action family stays one tap in its local rail', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    JourneySession? journey;
    WorkSession? work;
    try {
      (journey, work) = await mount(tester);
      expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
      expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
      expect(find.byKey(const Key('work-local-earn')), findsOneWidget);
      expect(find.byKey(const Key('work-local-workspace')), findsOneWidget);

      final launcher = find.byKey(const Key('mool-compact-launcher'));
      expect(tester.getSize(launcher).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(launcher).height, greaterThanOrEqualTo(44));
      expect(
        tester
            .getSemantics(launcher)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      for (final id in const ['earn', 'workspace']) {
        final action = find.byKey(Key('work-local-$id'));
        final size = tester.getSize(action);
        expect(size.width, greaterThanOrEqualTo(44), reason: id);
        expect(size.height, greaterThanOrEqualTo(44), reason: id);
        if (id == 'workspace') {
          expect(
            tester
                .getSemantics(find.bySemanticsLabel('Open Workspace'))
                .getSemanticsData()
                .hasAction(SemanticsAction.tap),
            isTrue,
          );
        }
      }

      await tester.tap(find.byKey(const Key('work-local-workspace')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('my-work-screen')), findsOneWidget);
      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);

      await tester.tap(find.byKey(const Key('work-local-earn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      journey?.dispose();
      work?.dispose();
      resetEnvironment(tester);
    }
  });

  testWidgets(
    'Work connected launcher settles immediately under reduced motion',
    (tester) async {
      JourneySession? journey;
      WorkSession? work;
      try {
        (journey, work) = await mount(tester, reducedMotion: true);
        final motion = tester.widget<AnimatedScale>(
          find.byKey(const Key('mool-compact-launcher-press-motion')),
        );
        expect(motion.duration, Duration.zero);
        await tester.tap(find.byKey(const Key('mool-compact-launcher')));
        await tester.pump();
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        journey?.dispose();
        work?.dispose();
        resetEnvironment(tester);
      }
    },
  );
}
