import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/ui_v2/profile/global_security_v2.dart';
import 'package:moolsocial/ui_v2/work/work_main_v2.dart';

void main() {
  Future<JourneySession> readyJourney() async {
    final session = JourneySession(
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
    await session.start();
    session.accountIdentity = const AuthenticatedAccountIdentity(
      displayName: 'Test Member',
      emailAddress: 'member@example.com',
      signInMethods: ['Google', 'Email'],
    );
    return session;
  }

  Future<GoRouter> pumpFromWork(
    WidgetTester tester, {
    required JourneySession journey,
    required WorkSession work,
    required Future<bool> Function() signOut,
    required Future<bool> Function() openSettings,
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
          builder: (context, state) => WorkMainV2(session: work),
        ),
        GoRoute(
          path: '/app/account/security',
          builder: (context, state) => GlobalSecurityV2(
            session: journey,
            onSignOut: signOut,
            openDeviceSettings: openSettings,
          ),
        ),
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => const Scaffold(
            body: Text('Sign-in destination', key: Key('sign-in-destination')),
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
    await tester.tap(find.byKey(const Key('global-profile-security')));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('Work opens one compact global Security destination', (
    tester,
  ) async {
    var settingsCalls = 0;
    final journey = await readyJourney();
    final work = WorkSession();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    await pumpFromWork(
      tester,
      journey: journey,
      work: work,
      signOut: () async => true,
      openSettings: () async {
        settingsCalls += 1;
        return true;
      },
    );

    expect(find.byKey(const Key('global-security-v2')), findsOne);
    expect(find.text('Test Member'), findsOne);
    expect(find.text('Google · Email'), findsOne);
    expect(find.text('member@example.com'), findsOne);
    expect(find.textContaining('Orders'), findsNothing);
    expect(find.textContaining('Payments'), findsNothing);
    expect(find.textContaining('Workspace'), findsNothing);
    expect(find.text('Sign out'), findsOne);
    expect(find.text('Sign in'), findsNothing);

    await tester.tap(find.byKey(const Key('global-security-device-settings')));
    await tester.pumpAndSettle();
    expect(settingsCalls, 1);
  });

  testWidgets('signed-out Security exposes one sign-in action in context', (
    tester,
  ) async {
    final journey = JourneySession(store: MemoryJourneyStore());
    final work = WorkSession();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    final router = await pumpFromWork(
      tester,
      journey: journey,
      work: work,
      signOut: () async => true,
      openSettings: () async => true,
    );

    expect(find.text('Sign in'), findsOne);
    expect(find.text('Sign out'), findsNothing);
    expect(find.byKey(const Key('global-security-methods')), findsNothing);
    expect(find.byKey(const Key('global-security-recovery')), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const Key('global-security-sign-in'))).dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const Key('global-security-device-settings')),
            )
            .dy,
      ),
    );

    await tester.tap(find.byKey(const Key('global-security-sign-in')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/sign-in');
  });

  testWidgets('sign-out cancellation is safe and confirmation exits once', (
    tester,
  ) async {
    var signOutCalls = 0;
    final journey = await readyJourney();
    final work = WorkSession();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    final router = await pumpFromWork(
      tester,
      journey: journey,
      work: work,
      signOut: () async {
        signOutCalls += 1;
        return true;
      },
      openSettings: () async => true,
    );

    await tester.tap(find.byKey(const Key('global-security-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-security-sign-out-cancel')));
    await tester.pumpAndSettle();
    expect(signOutCalls, 0);
    expect(find.byKey(const Key('global-security-v2')), findsOne);

    await tester.tap(find.byKey(const Key('global-security-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-security-sign-out-confirm')));
    await tester.pumpAndSettle();
    expect(signOutCalls, 1);
    expect(router.routeInformationProvider.value.uri.path, '/sign-in');
    expect(find.byKey(const Key('sign-in-destination')), findsOne);
  });

  testWidgets('failed sign-out preserves the active Security screen', (
    tester,
  ) async {
    final journey = await readyJourney();
    final work = WorkSession();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    await pumpFromWork(
      tester,
      journey: journey,
      work: work,
      signOut: () async => false,
      openSettings: () async => true,
    );

    await tester.tap(find.byKey(const Key('global-security-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-security-sign-out-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-security-v2')), findsOne);
    expect(
      find.text('Sign-out could not be completed. Please try again.'),
      findsOne,
    );
  });

  testWidgets('compact Security remains proportional without overflow', (
    tester,
  ) async {
    final journey = await readyJourney();
    journey.accountIdentity = const AuthenticatedAccountIdentity(
      displayName: 'A long authenticated MoolSocial member name',
      emailAddress: 'a.long.account.address@example.com',
      signInMethods: ['Google', 'Email', 'Phone'],
    );
    final work = WorkSession();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    await pumpFromWork(
      tester,
      journey: journey,
      work: work,
      signOut: () async => true,
      openSettings: () async => true,
      size: const Size(320, 700),
      textScale: 1.3,
    );

    expect(find.byKey(const Key('global-security-v2')), findsOne);
    await tester.scrollUntilVisible(
      find.byKey(const Key('global-security-sign-out')),
      220,
      scrollable: find.descendant(
        of: find.byKey(const Key('global-security-content')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
