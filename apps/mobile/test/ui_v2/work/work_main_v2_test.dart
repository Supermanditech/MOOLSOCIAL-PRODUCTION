import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_router.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  Future<(JourneySession, WorkSession)> mountWork(
    WidgetTester tester, {
    String initialLocation = '/app/work/earn',
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

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
    final work = WorkSession();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        workSession: work,
        initialLocation: initialLocation,
      ),
    );
    await tester.pumpAndSettle();
    return (journey, work);
  }

  test('Work opens Earn Today as its stable default action', () {
    final family = moolActionFamilyById('work');
    expect(family.route, '/app/work/earn');
    expect(moolDefaultActionForFamily('work').route, '/app/work/earn');
    expect(family.actions.map((action) => (action.label, action.route)), const [
      ('Earn Today', '/app/work/earn'),
      ('Workspace', '/app/work/my-work'),
    ]);
  });

  test('review-only guests retain the existing Work Chat boundary', () {
    expect(
      journeyRouteRequiresAuthentication(
        Uri.parse('/app/chat/inbox?return=/app/work/earn'),
        allowGuestReady: true,
      ),
      isFalse,
    );
    expect(
      journeyRouteRequiresAuthentication(
        Uri.parse('/app/chat/inbox?return=/app/work/earn'),
        allowGuestReady: false,
      ),
      isTrue,
    );
  });

  testWidgets('the retired Work Home route redirects to Earn Today', (
    tester,
  ) async {
    await mountWork(tester, initialLocation: '/app/work/home');

    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
    expect(find.byKey(const Key('work-main-v2')), findsNothing);
    expect(
      find.byKey(const ValueKey('moolsocial-family-root-work')),
      findsNothing,
    );
    expect(find.byKey(const Key('work-local-earn')), findsOneWidget);
    expect(find.byKey(const Key('work-local-workspace')), findsOneWidget);
    expect(find.byKey(const Key('mool-global-chat')), findsOneWidget);

    final cells = [
      find.byKey(const Key('mool-compact-launcher')),
      find.byKey(const Key('work-local-earn')),
      find.byKey(const Key('work-local-workspace')),
      find.byKey(const Key('mool-global-chat')),
    ];
    final widths = cells.map((cell) => tester.getSize(cell).width).toList();
    for (final width in widths.skip(1)) {
      expect(width, closeTo(widths.first, 1));
    }
    final centers = cells.map((cell) => tester.getCenter(cell).dx).toList();
    final firstGap = centers[1] - centers[0];
    expect(centers[2] - centers[1], closeTo(firstGap, 1));
    expect(centers[3] - centers[2], closeTo(firstGap, 1));
  });

  testWidgets('Earn Today is the complete first Work surface', (tester) async {
    await mountWork(tester);

    expect(find.byKey(const Key('work-earn-hero')), findsOneWidget);
    expect(find.text('Find paid work with clear terms'), findsOneWidget);
    expect(find.byKey(const Key('work-search')), findsOneWidget);
    expect(find.byKey(const Key('work-filter-list')), findsOneWidget);
    expect(find.byKey(const Key('work-refresh-feed')), findsOneWidget);
    expect(
      find.byKey(const Key('work-opportunity-mool-explainer')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('work-start-my-work')), findsNothing);
    expect(find.text('Need a verified Workspace?'), findsNothing);
    expect(find.byKey(const Key('work-global-chat')), findsNothing);
    expect(find.byKey(const Key('work-earn-global-profile')), findsOneWidget);

    await tester.tap(find.byKey(const Key('work-earn-global-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('global-profile-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
  });

  testWidgets('Earn Today reaches Workspace and native Back returns exactly', (
    tester,
  ) async {
    await mountWork(tester);

    await tester.tap(find.byKey(const Key('work-local-workspace')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('my-work-screen')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
  });

  testWidgets('Work Chat returns to the exact Earn Today origin', (
    tester,
  ) async {
    await mountWork(tester);

    await tester.tap(find.byKey(const Key('mool-global-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
  });

  testWidgets('compact large-text Earn Today has no layout exception', (
    tester,
  ) async {
    await mountWork(tester, size: const Size(320, 700), textScale: 1.4);

    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
    expect(find.byKey(const Key('work-earn-hero')), findsOneWidget);
    expect(find.byKey(const Key('work-local-earn')), findsOneWidget);
    expect(find.byKey(const Key('work-local-workspace')), findsOneWidget);
    final firstCard = find.byKey(const Key('work-opportunity-mool-explainer'));
    await tester.scrollUntilVisible(
      firstCard,
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('work-earn-screen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(firstCard, findsOneWidget);
    expect(
      find.byKey(const Key('work-opportunity-pay-mool-explainer')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('work-review-mool-explainer')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
