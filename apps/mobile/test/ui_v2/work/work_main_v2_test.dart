import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/features/journey01/journey_router.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';
import 'package:moolsocial/ui_v2/work/work_main_v2.dart';

void main() {
  Future<GoRouter> pumpWorkMain(
    WidgetTester tester,
    WorkSession session, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/app/work/home',
      routes: [
        GoRoute(
          path: '/app/work/home',
          builder: (context, state) => WorkMainV2(session: session),
        ),
        GoRoute(
          path: '/app/work/earn',
          builder: (context, state) => const Scaffold(
            body: Text('Earn destination', key: Key('earn-destination')),
          ),
        ),
        GoRoute(
          path: '/app/work/my-work',
          builder: (context, state) => const Scaffold(
            body: Text(
              'Workspace destination',
              key: Key('workspace-destination'),
            ),
          ),
        ),
        GoRoute(
          path: '/app/account/profile',
          builder: (context, state) => const Scaffold(
            body: Text(
              'Global profile',
              key: Key('global-profile-destination'),
            ),
          ),
        ),
        GoRoute(
          path: '/app/work/workspace/choose',
          builder: (context, state) => const Scaffold(
            body: Text(
              'Choose workspace',
              key: Key('workspace-application-destination'),
            ),
          ),
        ),
        GoRoute(
          path: '/app/chat/inbox',
          builder: (context, state) =>
              const Scaffold(body: Text('Chat review')),
        ),
        GoRoute(
          path: '/app/mool',
          builder: (context, state) => const Scaffold(body: Text('Mool menu')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  test('Mool Work enters the global Work home', () {
    expect(moolActionFamilyById('work').route, '/app/work/home');
    expect(moolDefaultActionForFamily('work').route, '/app/work/earn');
  });

  test('review-only guest navigation can inspect Chat without sign-in', () {
    expect(
      journeyRouteRequiresAuthentication(
        Uri.parse('/app/chat/inbox?return=/app/work/home'),
        allowGuestReady: true,
      ),
      isFalse,
    );
    expect(
      journeyRouteRequiresAuthentication(
        Uri.parse('/app/chat/inbox?return=/app/work/home'),
        allowGuestReady: false,
      ),
      isTrue,
    );
    expect(
      journeyRouteRequiresAuthentication(
        Uri.parse('/app/social?sub=create'),
        allowGuestReady: false,
      ),
      isTrue,
    );
  });

  testWidgets('Work home has one global profile and no duplicate header Chat', (
    tester,
  ) async {
    final session = WorkSession();
    addTearDown(session.dispose);
    await pumpWorkMain(tester, session);

    expect(find.byKey(const Key('work-main-v2')), findsOne);
    expect(find.text('One global profile'), findsOne);
    expect(find.text('Find paid opportunities'), findsOne);
    expect(find.text('Create a provider workspace'), findsOne);
    expect(find.byKey(const Key('work-global-chat')), findsNothing);
    expect(find.byKey(const Key('mool-global-chat')), findsOne);

    final profileButton = tester.getRect(
      find.byKey(const Key('work-main-global-profile')),
    );
    expect(profileButton.center.dx, greaterThan(300));

    await tester.tap(find.byKey(const Key('work-main-global-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-profile-panel-v2')), findsOne);
    final panel = tester.getRect(
      find.byKey(const Key('global-profile-panel-v2')),
    );
    expect(panel.right, closeTo(390, 1));
    expect(panel.left, greaterThan(90));
    expect(panel.top, greaterThanOrEqualTo(8));
    expect(panel.bottom, lessThanOrEqualTo(836));
    expect(panel.height, greaterThan(800));
    expect(find.text('Your MoolSocial profile'), findsOne);
    expect(find.byKey(const Key('global-profile-access-card')), findsOne);
    expect(find.text('Personal account'), findsOne);
    expect(find.text('Your account'), findsOne);
    expect(find.text('Privacy and preferences'), findsOne);
    expect(find.text('Become a MoolSocial Partner'), findsOne);
    expect(find.byKey(const Key('global-profile-quick-actions')), findsNothing);
    expect(
      find.byKey(const Key('global-profile-active-workspace')),
      findsNothing,
    );
    expect(find.text('Orders'), findsNothing);
    expect(find.text('Payments'), findsNothing);
    expect(
      find.byKey(const Key('global-profile-explore-workspaces')),
      findsOne,
    );
    expect(find.text('Explore workspaces'), findsOne);
    expect(
      find.descendant(
        of: find.byKey(const Key('global-profile-panel-v2')),
        matching: find.textContaining('Mool Partner'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('global-profile-panel-v2')),
        matching: find.textContaining(RegExp('provider', caseSensitive: false)),
      ),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('global-profile-explore-workspaces')),
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('global-profile-panel-v2')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('global-profile-explore-workspaces')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('workspace-application-destination')),
      findsOne,
    );
  });

  testWidgets('workspace controls appear only after live activation', (
    tester,
  ) async {
    final session = WorkSession()..seedVerifiedWorkspace();
    session.reviewStage = WorkReviewStage.live;
    addTearDown(session.dispose);
    await pumpWorkMain(tester, session);

    await tester.tap(find.byKey(const Key('work-main-global-profile')));
    await tester.pumpAndSettle();
    final activeWorkspace = find.byKey(
      const Key('global-profile-active-workspace'),
    );
    expect(activeWorkspace, findsOne);
    expect(
      find.descendant(
        of: activeWorkspace,
        matching: find.text('Mahadev Fresh Mart'),
      ),
      findsOne,
    );
    expect(
      find.descendant(
        of: activeWorkspace,
        matching: find.textContaining('Grocery / Kirana Shop'),
      ),
      findsOne,
    );
    expect(find.text('Workspace access'), findsOne);
    expect(find.byKey(const Key('global-profile-quick-actions')), findsOne);
    expect(find.byKey(const Key('global-profile-quick-operations')), findsOne);
    expect(find.byKey(const Key('global-profile-quick-activity')), findsOne);
    expect(find.byKey(const Key('global-profile-quick-documents')), findsOne);
    expect(find.byKey(const Key('global-profile-quick-plans')), findsOne);
    expect(find.byKey(const Key('global-profile-quick-support')), findsOne);
    expect(find.byKey(const Key('global-profile-access-card')), findsNothing);
    await tester.tap(find.byKey(const Key('global-profile-quick-operations')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('workspace-destination')), findsOne);
  });

  testWidgets('Personal profile opens the exact global profile route', (
    tester,
  ) async {
    final session = WorkSession();
    addTearDown(session.dispose);
    await pumpWorkMain(tester, session);

    await tester.tap(find.byKey(const Key('work-main-global-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-profile-identity')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('global-profile-destination')), findsOne);
  });

  testWidgets('pending application keeps partner controls locked', (
    tester,
  ) async {
    final session = WorkSession()
      ..reviewCaseId = 'WP-PENDING'
      ..reviewStage = WorkReviewStage.gstPending;
    addTearDown(session.dispose);
    await pumpWorkMain(tester, session);

    await tester.tap(find.byKey(const Key('work-main-global-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Workspace application'), findsOne);
    expect(find.text('View application'), findsOne);
    expect(
      find.byKey(const Key('global-profile-active-workspace')),
      findsNothing,
    );
    expect(find.byKey(const Key('global-profile-quick-actions')), findsNothing);

    await tester.tap(
      find.byKey(const Key('global-profile-explore-workspaces')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-destination')), findsOne);
  });

  testWidgets('Work choices open their exact destinations', (tester) async {
    final session = WorkSession();
    addTearDown(session.dispose);
    final router = await pumpWorkMain(tester, session);

    await tester.tap(find.byKey(const Key('work-main-earn')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/app/work/earn');

    router.go('/app/work/home');
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byKey(const Key('work-main-v2')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('work-main-workspace')),
      220,
      scrollable: scrollable,
    );
    await tester.ensureVisible(find.byKey(const Key('work-main-workspace')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-main-workspace')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/app/work/my-work');
  });

  testWidgets('compact 140 percent Work home has no overflow', (tester) async {
    final session = WorkSession();
    addTearDown(session.dispose);
    await pumpWorkMain(
      tester,
      session,
      size: const Size(320, 700),
      textScale: 1.4,
    );

    expect(find.byKey(const Key('work-main-v2')), findsOne);
    expect(find.byKey(const Key('mool-global-chat')), findsOne);
    await tester.tap(find.byKey(const Key('work-main-global-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-profile-panel-v2')), findsOne);
    expect(tester.takeException(), isNull);
  });
}
