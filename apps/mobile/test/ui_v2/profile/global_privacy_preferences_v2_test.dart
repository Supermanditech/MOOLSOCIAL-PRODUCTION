import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/ui_v2/profile/global_privacy_preferences_v2.dart';
import 'package:moolsocial/ui_v2/work/work_main_v2.dart';

void main() {
  Future<GoRouter> pumpFromWork(
    WidgetTester tester, {
    required JourneySession journey,
    required WorkSession work,
    required Future<bool> Function() openNotifications,
    required Future<bool> Function() openPrivacy,
    Size size = const Size(390, 844),
    double textScale = 1,
    double bottomInset = 0,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/app/work/home',
      routes: [
        GoRoute(
          path: '/app/work/home',
          builder: (context, state) => WorkMainV2(session: work),
        ),
        GoRoute(
          path: '/app/account/workspaces/preferences',
          builder: (context, state) => GlobalPrivacyPreferencesV2(
            session: journey,
            openNotificationSettings: openNotifications,
            openPrivacyPolicy: openPrivacy,
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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: EdgeInsets.only(bottom: bottomInset),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-main-global-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-profile-preferences')));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('Work opens one global preferences screen and saves choices', (
    tester,
  ) async {
    final store = MemoryJourneyStore();
    final journey = JourneySession(store: store)
      ..selectArea(AreaChoice.manual, label: 'Sardarpura');
    final work = WorkSession();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    final router = await pumpFromWork(
      tester,
      journey: journey,
      work: work,
      openNotifications: () async => true,
      openPrivacy: () async => true,
    );

    expect(find.byKey(const Key('global-privacy-preferences-v2')), findsOne);
    expect(find.text('English'), findsOne);
    expect(find.text('Sardarpura'), findsOne);
    expect(
      find.text(
        'Choose your language and service area for a more relevant experience.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('main action'), findsNothing);

    await tester.tap(find.byKey(const Key('global-preferences-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-preferences-language-hi')));
    await tester.pumpAndSettle();
    expect(journey.languageCode, 'hi');
    expect(store.snapshot?.languageCode, 'hi');

    await tester.tap(find.byKey(const Key('global-preferences-area')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('global-preferences-area-input')),
      'Jodhpur 342001',
    );
    await tester.tap(find.byKey(const Key('global-preferences-area-save')));
    await tester.pumpAndSettle();
    expect(journey.manualArea, 'Jodhpur 342001');
    expect(store.snapshot?.areaLabel, 'Jodhpur 342001');

    await tester.tap(find.byKey(const Key('global-preferences-back')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/app/work/home');
    expect(find.byKey(const Key('work-main-v2')), findsOne);
  });

  testWidgets('invalid area remains editable and exact retry succeeds', (
    tester,
  ) async {
    final journey = JourneySession(store: MemoryJourneyStore());
    final work = WorkSession();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    await pumpFromWork(
      tester,
      journey: journey,
      work: work,
      openNotifications: () async => true,
      openPrivacy: () async => true,
    );

    await tester.tap(find.byKey(const Key('global-preferences-area')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('global-preferences-area-input')),
      'A',
    );
    await tester.tap(find.byKey(const Key('global-preferences-area-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-preferences-area-error')), findsOne);
    expect(journey.manualArea, isNull);

    await tester.enterText(
      find.byKey(const Key('global-preferences-area-input')),
      'Jodhpur',
    );
    await tester.tap(find.byKey(const Key('global-preferences-area-save')));
    await tester.pumpAndSettle();
    expect(journey.manualArea, 'Jodhpur');
    expect(
      find.byKey(const Key('global-preferences-area-input')),
      findsNothing,
    );
  });

  testWidgets('notification and privacy actions use their real boundaries', (
    tester,
  ) async {
    var notificationCalls = 0;
    var privacyCalls = 0;
    final journey = JourneySession(store: MemoryJourneyStore());
    final work = WorkSession();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    await pumpFromWork(
      tester,
      journey: journey,
      work: work,
      openNotifications: () async {
        notificationCalls += 1;
        return true;
      },
      openPrivacy: () async {
        privacyCalls += 1;
        return true;
      },
    );

    await tester.tap(find.byKey(const Key('global-preferences-notifications')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('global-preferences-privacy-policy')),
    );
    await tester.pumpAndSettle();
    expect(notificationCalls, 1);
    expect(privacyCalls, 1);
  });

  test('debug hot reload reconstructs the router at its current location', () {
    final source = File('lib/app/moolsocial_app.dart').readAsStringSync();
    expect(source, contains('late GoRouter _router = _createRouter'));
    expect(source, contains('void reassemble()'));
    expect(
      source,
      contains('_router.routeInformationProvider.value.uri.toString()'),
    );
    expect(source, contains('_router = _createRouter(location)'));
    expect(source, contains('previousRouter.dispose()'));
  });

  testWidgets('compact preferences stay proportional without overflow', (
    tester,
  ) async {
    final journey = JourneySession(store: MemoryJourneyStore())
      ..selectArea(
        AreaChoice.manual,
        label: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
      );
    final work = WorkSession();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    await pumpFromWork(
      tester,
      journey: journey,
      work: work,
      openNotifications: () async => true,
      openPrivacy: () async => true,
      size: const Size(320, 700),
      textScale: 1.3,
    );

    expect(find.byKey(const Key('global-privacy-preferences-v2')), findsOne);
    await tester.scrollUntilVisible(
      find.byKey(const Key('global-preferences-privacy-policy')),
      220,
      scrollable: find.descendant(
        of: find.byKey(const Key('global-preferences-content')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Language choices remain fully visible above compact phone insets',
    (tester) async {
      const cases = <({Size size, double scale, double bottomInset})>[
        (size: Size(320, 568), scale: 1.4, bottomInset: 34),
        (size: Size(360, 640), scale: 1.4, bottomInset: 48),
        (size: Size(360, 720), scale: 1, bottomInset: 0),
        (size: Size(430, 932), scale: 1, bottomInset: 34),
      ];

      for (final testCase in cases) {
        final journey = JourneySession(store: MemoryJourneyStore());
        final work = WorkSession();
        await pumpFromWork(
          tester,
          journey: journey,
          work: work,
          openNotifications: () async => true,
          openPrivacy: () async => true,
          size: testCase.size,
          textScale: testCase.scale,
          bottomInset: testCase.bottomInset,
        );

        await tester.tap(find.byKey(const Key('global-preferences-language')));
        await tester.pumpAndSettle();

        final english = find.byKey(const Key('global-preferences-language-en'));
        final hindi = find.byKey(const Key('global-preferences-language-hi'));
        expect(english, findsOneWidget);
        expect(hindi, findsOneWidget);
        expect(tester.getTopLeft(english).dy, greaterThanOrEqualTo(0));
        expect(
          tester.getBottomRight(hindi).dy,
          lessThanOrEqualTo(testCase.size.height - testCase.bottomInset - 16),
        );
        expect(tester.getSize(english).height, greaterThanOrEqualTo(56));
        expect(tester.getSize(hindi).height, greaterThanOrEqualTo(56));
        expect(
          tester.getSize(hindi).height,
          closeTo(tester.getSize(english).height, .1),
        );
        expect(tester.takeException(), isNull);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('global-privacy-preferences-v2')),
          findsOneWidget,
        );
        journey.dispose();
        work.dispose();
      }
    },
  );
}
