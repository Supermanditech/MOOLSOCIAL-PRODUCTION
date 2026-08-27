import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/features/journey01/journey_router.dart';
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
          path: '/app/account/identity',
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
          path: '/app/pay/home',
          builder: (context, state) => const Scaffold(
            body: Text('Payments', key: Key('profile-payments-destination')),
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
    expect(panel.left, greaterThan(0));
    expect(find.text('Your MoolSocial profile'), findsOne);
    expect(find.byKey(const Key('global-profile-access-card')), findsOne);
    expect(find.text('Personal account'), findsOne);
    expect(find.text('Your account'), findsOne);
    expect(find.text('Privacy and preferences'), findsOne);
    expect(find.text('Your essentials'), findsOne);
    expect(find.text('Grow with MoolSocial'), findsOne);
    expect(find.text('Create and earn'), findsOne);
    expect(find.text('Build your business'), findsOne);
    expect(find.text('Delivery and field work'), findsOne);
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

  testWidgets('profile quick access opens the existing payments route', (
    tester,
  ) async {
    final session = WorkSession();
    addTearDown(session.dispose);
    await pumpWorkMain(tester, session);

    await tester.tap(find.byKey(const Key('work-main-global-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-profile-quick-actions')), findsOne);
    expect(find.byKey(const Key('global-profile-quick-orders')), findsOne);
    expect(find.byKey(const Key('global-profile-quick-payments')), findsOne);
    expect(find.byKey(const Key('global-profile-quick-activity')), findsOne);
    expect(find.byKey(const Key('global-profile-quick-documents')), findsOne);
    await tester.tap(find.byKey(const Key('global-profile-quick-payments')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-payments-destination')), findsOne);
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
