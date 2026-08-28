import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/ui_v2/profile/global_help_support_v2.dart';
import 'package:moolsocial/ui_v2/work/work_main_v2.dart';

void main() {
  Future<GoRouter> pumpFromWork(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final journey = JourneySession(store: MemoryJourneyStore());
    final work = WorkSession();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    final router = GoRouter(
      initialLocation: '/app/work/home',
      routes: [
        GoRoute(
          path: '/app/work/home',
          builder: (context, state) => WorkMainV2(session: work),
        ),
        GoRoute(
          path: '/app/ask',
          builder: (context, state) => GlobalHelpSupportV2(session: journey),
        ),
        GoRoute(
          path: '/app/account/security',
          builder: (context, state) => const Scaffold(
            body: Text(
              'Security destination',
              key: Key('security-destination'),
            ),
          ),
        ),
        GoRoute(
          path: '/app/account/workspaces/preferences',
          builder: (context, state) => const Scaffold(
            body: Text(
              'Preferences destination',
              key: Key('preferences-destination'),
            ),
          ),
        ),
        GoRoute(
          path: '/app/chat',
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                const Text(
                  'Support Chat',
                  key: Key('support-chat-destination'),
                ),
                Text(
                  state.uri.queryParameters['type'] ?? '',
                  key: const Key('support-chat-type'),
                ),
                Text(
                  state.uri.queryParameters['return'] ?? '',
                  key: const Key('support-chat-return'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/app/work/workspace/choose',
          builder: (context, state) =>
              const Scaffold(body: Text('Workspace setup')),
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
    await tester.tap(find.byKey(const Key('work-main-global-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-profile-ask')));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('Work opens one compact global Help destination', (tester) async {
    final router = await pumpFromWork(tester);

    expect(find.byKey(const Key('global-help-support-v2')), findsOne);
    expect(find.text('Help & support'), findsOne);
    expect(find.text('Sign in'), findsNothing);
    expect(find.text('Sign out'), findsNothing);
    expect(find.textContaining('Orders'), findsNothing);
    expect(find.textContaining('Payments'), findsNothing);

    await tester.tap(find.byKey(const Key('global-help-back')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/app/work/home');
    expect(find.byKey(const Key('work-main-v2')), findsOne);
  });

  testWidgets('Help topics open exact approved profile destinations', (
    tester,
  ) async {
    final router = await pumpFromWork(tester);
    expect(find.byKey(const Key('global-help-support-v2')), findsOne);

    await tester.ensureVisible(find.byKey(const Key('global-help-security')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-help-security')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('security-destination')), findsOne);

    router.pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('global-help-preferences')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-help-preferences')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('preferences-destination')), findsOne);
  });

  testWidgets('support CTA opens filtered Chat with Help return continuity', (
    tester,
  ) async {
    await pumpFromWork(tester);
    expect(find.byKey(const Key('global-help-support-v2')), findsOne);

    await tester.ensureVisible(
      find.byKey(const Key('global-help-open-support-chat')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-help-open-support-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('support-chat-destination')), findsOne);
    expect(find.text('support'), findsOne);
    expect(find.text('/app/ask'), findsOne);
  });

  testWidgets('compact Help remains proportional without overflow', (
    tester,
  ) async {
    await pumpFromWork(tester, size: const Size(320, 700), textScale: 1.3);

    expect(find.byKey(const Key('global-help-support-v2')), findsOne);
    await tester.scrollUntilVisible(
      find.byKey(const Key('global-help-open-support-chat')),
      220,
      scrollable: find.descendant(
        of: find.byKey(const Key('global-help-content')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
