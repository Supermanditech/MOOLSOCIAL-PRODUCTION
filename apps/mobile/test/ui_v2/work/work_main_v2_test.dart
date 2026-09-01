import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_router.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  Future<(JourneySession, WorkSession)> mountWork(
    WidgetTester tester, {
    String initialLocation = '/app/work/earn',
    Size size = const Size(390, 844),
    double textScale = 1,
    WorkSession? workSession,
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
    final work = workSession ?? WorkSession();
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

  Future<void> openSearch(WidgetTester tester, String value) async {
    await tester.tap(find.byKey(const Key('work-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('work-search')), value);
    await tester.pumpAndSettle();
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

  testWidgets('retired Work Home redirects to a four-cell Earn rail', (
    tester,
  ) async {
    await mountWork(tester, initialLocation: '/app/work/home');

    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
    expect(find.byKey(const Key('work-main-v2')), findsNothing);
    expect(
      find.byKey(const ValueKey('moolsocial-family-root-work')),
      findsNothing,
    );
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
    final gap = centers[1] - centers[0];
    expect(centers[2] - centers[1], closeTo(gap, 1));
    expect(centers[3] - centers[2], closeTo(gap, 1));
  });

  testWidgets('Earn uses inline Search, Filter and Profile with no old UI', (
    tester,
  ) async {
    await mountWork(tester);

    expect(find.byKey(const Key('work-page-title')), findsNothing);
    expect(find.byKey(const Key('work-earn-inline-header')), findsOneWidget);
    expect(find.byKey(const Key('work-search')), findsOneWidget);
    expect(find.byKey(const Key('work-filter-button')), findsOneWidget);
    expect(find.byKey(const Key('work-earn-global-profile')), findsOneWidget);
    expect(find.byKey(const Key('work-earn-hero')), findsNothing);
    expect(find.text('Find paid work with clear terms'), findsNothing);
    expect(find.text('Opportunities'), findsNothing);

    final card = find.byKey(const Key('work-opportunity-quick-delivery-biker'));
    expect(card, findsOneWidget);
    expect(
      find.byKey(const Key('work-opportunity-owner-quick-delivery-biker')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key(
          'work-opportunity-candidate-requirements-quick-delivery-biker',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('work-opportunity-pay-monthly-quick-delivery-biker'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('work-opportunity-pay-hourly-quick-delivery-biker')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('work-opportunity-pay-assignment-quick-delivery-biker'),
      ),
      findsOneWidget,
    );
    final surface = tester.widget<Material>(card);
    expect(surface.color, isNot(Colors.transparent));

    await tester.tap(find.byKey(const Key('work-earn-global-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
  });

  testWidgets('inline search matches position, requirements and poster', (
    tester,
  ) async {
    await mountWork(tester);
    await openSearch(tester, 'doctor');

    expect(
      find.byKey(const Key('work-opportunity-doctor-onboarding-specialist')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('work-opportunity-quick-delivery-biker')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('work-clear-search')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('work-opportunity-quick-delivery-biker')),
      findsOneWidget,
    );
  });

  testWidgets('compact Profile opens from the inline header without overflow', (
    tester,
  ) async {
    await mountWork(tester, size: const Size(320, 700), textScale: 1.3);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('work-earn-global-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('city area and pincode filters combine exactly', (tester) async {
    final (_, work) = await mountWork(tester);
    await tester.tap(find.byKey(const Key('work-filter-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('work-filter-sheet-route')), findsOneWidget);
    await tester.tap(find.byKey(const Key('work-filter-city')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jodhpur').last);
    await tester.enterText(
      find.byKey(const Key('work-filter-area')),
      'Ratanada',
    );
    await tester.enterText(
      find.byKey(const Key('work-filter-pincode')),
      '342011',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('work-filter-apply')),
      220,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('work-filter-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('work-filter-apply')));
    await tester.pumpAndSettle();

    expect(work.selectedCity, 'Jodhpur');
    expect(work.selectedArea, 'Ratanada');
    expect(work.selectedPincode, '342011');
    expect(
      find.byKey(const Key('work-opportunity-retailer-onboarding-specialist')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('work-opportunity-quick-delivery-biker')),
      findsNothing,
    );
  });

  testWidgets('opportunity detail is role-specific and complete', (
    tester,
  ) async {
    await mountWork(tester);
    await openSearch(tester, 'doctor');
    await tester.tap(
      find.byKey(
        const Key('work-opportunity-apply-doctor-onboarding-specialist'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('work-opportunity-screen')), findsOneWidget);
    expect(find.byKey(const Key('work-detail-about-role')), findsOneWidget);
    expect(find.byKey(const Key('work-detail-what-youll-do')), findsOneWidget);
    final detailScroll = find
        .descendant(
          of: find.byKey(const Key('work-opportunity-screen')),
          matching: find.byType(Scrollable),
        )
        .first;
    for (final key in const [
      Key('work-detail-who-you-are'),
      Key('work-detail-nice-to-have'),
      Key('work-detail-why-join'),
      Key('work-detail-payment'),
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(key),
        220,
        scrollable: detailScroll,
      );
      expect(find.byKey(key), findsOneWidget);
    }
    expect(find.textContaining('Medical representative'), findsWidgets);
  });

  testWidgets('successful Apply can be cancelled or confirmed Withdraw', (
    tester,
  ) async {
    final gateway = ReviewWorkGateway();
    final work = WorkSession(gateway: gateway);
    await mountWork(tester, workSession: work);
    await openSearch(tester, 'social content creator');
    await tester.tap(
      find.byKey(const Key('work-opportunity-apply-social-content-creator')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('work-apply-opportunity')));
    await tester.pumpAndSettle();
    expect(gateway.applicationCalls, 1);
    expect(find.byKey(const Key('work-withdraw-application')), findsOneWidget);

    await tester.tap(find.byKey(const Key('work-withdraw-application')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-withdraw-cancel')));
    await tester.pumpAndSettle();
    expect(gateway.withdrawalCalls, 0);

    await tester.tap(find.byKey(const Key('work-withdraw-application')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-withdraw-confirm')));
    await tester.pumpAndSettle();
    expect(gateway.withdrawalCalls, 1);
    expect(find.byKey(const Key('work-apply-opportunity')), findsOneWidget);
  });

  testWidgets('Workspace and Chat return to the exact filtered Earn state', (
    tester,
  ) async {
    final (_, work) = await mountWork(tester);
    work.search('doctor');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('work-local-workspace')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('my-work-screen')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(work.searchQuery, 'doctor');

    await tester.tap(find.byKey(const Key('mool-global-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(work.searchQuery, 'doctor');
    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
  });

  testWidgets('compact large-text card remains reachable without overflow', (
    tester,
  ) async {
    await mountWork(tester, size: const Size(320, 700), textScale: 1.4);

    expect(find.byKey(const Key('work-earn-inline-header')), findsOneWidget);
    expect(find.byKey(const Key('work-filter-button')), findsOneWidget);
    final firstCard = find.byKey(
      const Key('work-opportunity-quick-delivery-biker'),
    );
    expect(firstCard, findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('work-opportunity-apply-quick-delivery-biker')),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('work-earn-screen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.byKey(
        const Key('work-opportunity-pay-monthly-quick-delivery-biker'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
