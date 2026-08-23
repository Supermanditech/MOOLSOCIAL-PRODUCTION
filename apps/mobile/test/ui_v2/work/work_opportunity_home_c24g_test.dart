import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_service_home.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

void main() {
  testWidgets(
    'C24G Earn Today candidate capture at OPPO-class viewport',
    (tester) async {
      final sessions = await _mount(
        tester,
        route: '/app/work/earn',
        size: const Size(360, 800),
        devicePixelRatio: 3,
      );
      addTearDown(sessions.dispose);
      await expectLater(
        find.byType(Overlay).first,
        matchesGoldenFile(
          'candidate_captures/work-earn-home-c24g-oppo-360x800.png',
        ),
      );
    },
    // Run explicitly with --run-skipped --update-goldens for visual evidence.
    skip: true,
  );

  testWidgets(
    'C24G Workspace candidate capture at OPPO-class viewport',
    (tester) async {
      final sessions = await _mount(
        tester,
        route: '/app/work/my-work',
        size: const Size(360, 800),
        devicePixelRatio: 3,
      );
      addTearDown(sessions.dispose);
      await expectLater(
        find.byType(Overlay).first,
        matchesGoldenFile(
          'candidate_captures/work-workspace-home-c24g-oppo-360x800.png',
        ),
      );
    },
    // Run explicitly with --run-skipped --update-goldens for visual evidence.
    skip: true,
  );

  for (final viewport in const [
    (Size(320, 568), 1.4),
    (Size(390, 844), 1.0),
    (Size(430, 932), 1.3),
  ]) {
    testWidgets(
      'C24G Earn Today adapts at ${viewport.$1.width.toInt()}x${viewport.$1.height.toInt()} text ${viewport.$2}',
      (tester) async {
        final sessions = await _mount(
          tester,
          route: '/app/work/earn',
          size: viewport.$1,
          textScale: viewport.$2,
        );
        addTearDown(sessions.dispose);

        expect(find.byKey(const Key('work-search')), findsOneWidget);
        expect(find.byKey(const Key('work-filter-list')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('work-filter-list')),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
        );
        expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
        for (final key in const ['work-local-earn', 'work-local-workspace']) {
          final control = find.byKey(Key(key));
          expect(control, findsOneWidget);
          expect(tester.getSize(control).height, greaterThanOrEqualTo(44));
        }
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
        expect(find.text('Updated live'), findsNothing);
        expect(find.textContaining('Monthly earning potential'), findsNothing);
        expect(find.textContaining('10,248'), findsNothing);
        expect(find.text('18 orders'), findsNothing);
        expect(find.text('₹12,840'), findsNothing);

        expect(
          tester
              .widget<ListView>(find.byKey(const Key('work-earn-screen')))
              .scrollDirection,
          Axis.vertical,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'C24G work search and visible terms lead directly to opportunity review',
    (tester) async {
      final sessions = await _mount(
        tester,
        route: '/app/work/earn',
        size: const Size(390, 844),
      );
      addTearDown(sessions.dispose);

      await tester.enterText(find.byKey(const Key('work-search')), 'Jodhpur');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-filter-nearby')));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('work-opportunity-mahadev-orders'));
      await _scrollTo(tester, card, const Key('work-earn-screen'));
      expect(find.text('₹20 per delivered order'), findsOneWidget);
      expect(find.text('Jodhpur · 4 km'), findsOneWidget);
      expect(find.text('Ends 21 Jul · 9:00 PM'), findsOneWidget);
      expect(find.text('Funded · maximum payout ₹400'), findsOneWidget);

      final review = find.byKey(const Key('work-review-mahadev-orders'));
      await _scrollTo(tester, review, const Key('work-earn-screen'));
      expect(tester.getSize(review).height, greaterThanOrEqualTo(48));
      final semantics = tester
          .getSemantics(
            find.descendant(of: review, matching: find.byType(FilledButton)),
          )
          .getSemanticsData();
      expect(semantics.hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(review);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('work-opportunity-screen')), findsOneWidget);
      expect(sessions.work.selectedOpportunity?.id, 'mahadev-orders');
    },
  );

  testWidgets(
    'C24G Workspace has one direct setup action and no fake metrics',
    (tester) async {
      final sessions = await _mount(
        tester,
        route: '/app/work/my-work',
        size: const Size(320, 568),
        textScale: 1.4,
      );
      addTearDown(sessions.dispose);

      expect(find.byKey(const Key('my-work-screen')), findsOneWidget);
      expect(find.byKey(const Key('my-work-start')), findsOneWidget);
      expect(find.byKey(const Key('my-work-choice-earn')), findsNothing);
      expect(find.byKey(const Key('my-work-choice-business')), findsNothing);
      expect(find.byKey(const Key('my-work-choice-create')), findsNothing);
      expect(find.text('18 orders'), findsNothing);
      expect(find.text('₹12,840'), findsNothing);
      expect(find.text('7 items'), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('my-work-start'))).height,
        greaterThanOrEqualTo(48),
      );
      final semantics = tester
          .getSemantics(
            find.descendant(
              of: find.byKey(const Key('my-work-start')),
              matching: find.byType(FilledButton),
            ),
          )
          .getSemanticsData();
      expect(semantics.hasAction(SemanticsAction.tap), isTrue);

      await tester.tap(find.byKey(const Key('my-work-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('C24G shared Work motion settles immediately when reduced', (
    tester,
  ) async {
    final sessions = await _mount(
      tester,
      route: '/app/work/earn',
      size: const Size(390, 844),
      reducedMotion: true,
    );
    addTearDown(sessions.dispose);

    final context = tester.element(find.byKey(const Key('work-search')));
    expect(MoolServiceHomeTokens.accessibleDuration(context), Duration.zero);
    expect(tester.takeException(), isNull);
  });
}

Future<_Sessions> _mount(
  WidgetTester tester, {
  required String route,
  required Size size,
  double textScale = 1,
  double devicePixelRatio = 1,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = size * devicePixelRatio;
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  if (reducedMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

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
  final work = WorkSession(gateway: ReviewWorkGateway());
  await journey.start();
  await tester.pumpWidget(
    MoolSocialApp(
      key: UniqueKey(),
      session: journey,
      workSession: work,
      initialLocation: route,
    ),
  );
  await tester.pumpAndSettle();
  return _Sessions(journey, work);
}

Future<void> _scrollTo(WidgetTester tester, Finder target, Key listKey) async {
  final scrollable = find.descendant(
    of: find.byKey(listKey),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(
    target,
    260,
    scrollable: scrollable.first,
    maxScrolls: 20,
  );
  await tester.pumpAndSettle();
}

class _Sessions {
  const _Sessions(this.journey, this.work);

  final JourneySession journey;
  final WorkSession work;

  void dispose() {
    journey.dispose();
    work.dispose();
  }
}
