import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/ui_v2/workspace/retailer_workspace_onboarding_v2.dart';

void main() {
  Future<GoRouter> pumpOnboarding(
    WidgetTester tester,
    WorkSession session, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/app/work/workspace/retailer',
      routes: [
        GoRoute(
          path: '/app/work/workspace/retailer',
          builder: (context, state) =>
              RetailerWorkspaceOnboardingV2(session: session),
        ),
        GoRoute(
          path: '/app/work/workspace/proof',
          builder: (context, state) => const Scaffold(
            body: Center(
              child: Text(
                'Proof destination',
                key: Key('retailer-proof-destination'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/app/work/my-work',
          builder: (context, state) =>
              const Scaffold(body: Text('Workspace home')),
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

  testWidgets('retailer owner sees one exact workspace-start decision', (
    tester,
  ) async {
    final session = WorkSession();
    await pumpOnboarding(tester, session);

    expect(find.byKey(const Key('retailer-workspace-onboarding-v2')), findsOne);
    expect(find.text('Grocery / Kirana Shop'), findsOne);
    expect(find.text('Speciality Retail Shop'), findsOne);
    expect(find.text('Wholesaler / Distributor'), findsNothing);
    expect(find.textContaining('personal account stays active'), findsOne);
    expect(find.textContaining('Medicine'), findsNothing);

    await tester.tap(find.byKey(const Key('retailer-onboarding-continue')));
    await tester.pump();
    expect(find.text('Enter the work or business name.'), findsOne);
    expect(session.selectedFamilyId, 'products-trade');
    expect(session.selectedProfile, isNull);
  });

  testWidgets('valid retailer details continue to the existing proof route', (
    tester,
  ) async {
    final session = WorkSession();
    await pumpOnboarding(tester, session);

    await tester.tap(
      find.byKey(const Key('retailer-profile-retailer-grocery')),
    );
    final onboardingList = find.byKey(
      const Key('retailer-workspace-onboarding-v2'),
    );
    final scrollable = find
        .descendant(of: onboardingList, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('retailer-onboarding-name')),
      220,
      scrollable: scrollable,
    );
    await tester.enterText(
      find.byKey(const Key('retailer-onboarding-name')),
      'Mahadev Fresh Mart',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('retailer-onboarding-area')),
      160,
      scrollable: scrollable,
    );
    await tester.enterText(
      find.byKey(const Key('retailer-onboarding-area')),
      'Sardarpura 342003',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('retailer-onboarding-activity')),
      160,
      scrollable: scrollable,
    );
    await tester.enterText(
      find.byKey(const Key('retailer-onboarding-activity')),
      'Grocery and household products',
    );
    await tester.tap(find.byKey(const Key('retailer-onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('retailer-proof-destination')), findsOne);
    expect(session.selectedProfile?.id, 'retailer-grocery');
    expect(session.workName, 'Mahadev Fresh Mart');
    expect(session.workArea, 'Sardarpura 342003');
    expect(session.primaryActivity, 'Grocery and household products');
  });

  testWidgets('compact 140 percent layout keeps the action reachable', (
    tester,
  ) async {
    final session = WorkSession();
    await pumpOnboarding(
      tester,
      session,
      size: const Size(320, 700),
      textScale: 1.4,
    );

    expect(find.byKey(const Key('retailer-onboarding-continue')), findsOne);
    expect(tester.takeException(), isNull);
  });
}
