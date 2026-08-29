import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/ui_v2/profile/global_profile_panel_v2.dart';
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

  Future<JourneySession> pumpReadyGuestApp(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(),
      allowGuestReady: true,
    );
    final work = WorkSession();
    await journey.start();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        workSession: work,
        initialLocation: '/app/work/home',
      ),
    );
    await tester.pumpAndSettle();
    expect(journey.stage, JourneyStage.ready);
    expect(journey.isAuthenticated, isFalse);
    return journey;
  }

  Future<void> openSecurityFromWork(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('work-main-global-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-profile-security')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-security-v2')), findsOneWidget);
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
    expect(journey.stage, JourneyStage.signIn);
    final returnUri = Uri.parse(journey.returnTo!);
    expect(returnUri.path, '/app/account/security');
    expect(returnUri.queryParameters['return'], '/app/work/home');
  });

  testWidgets('real router keeps Security sign-in open and Back recovers', (
    tester,
  ) async {
    final journey = await pumpReadyGuestApp(tester);
    await openSecurityFromWork(tester);
    final securityLocation = GoRouterState.of(
      tester.element(find.byKey(const Key('global-security-v2'))),
    ).uri.toString();

    await tester.tap(find.byKey(const Key('global-security-sign-in')));
    await tester.pumpAndSettle();

    expect(journey.stage, JourneyStage.signIn);
    expect(journey.returnTo, securityLocation);
    expect(journey.canCancelSignIn, isTrue);
    expect(find.byKey(const Key('screen03-login-v5')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-route-recovery')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(journey.stage, JourneyStage.ready);
    expect(find.byKey(const Key('global-security-v2')), findsOneWidget);
    final recovered = GoRouterState.of(
      tester.element(find.byKey(const Key('global-security-v2'))),
    ).uri;
    expect(recovered.path, '/app/account/security');
    expect(recovered.queryParameters['return'], '/app/work/home');

    await tester.tap(find.byKey(const Key('global-security-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-main-v2')), findsOneWidget);
  });

  testWidgets('successful Security sign-in returns to Security then Work', (
    tester,
  ) async {
    final journey = await pumpReadyGuestApp(tester);
    await openSecurityFromWork(tester);

    await tester.tap(find.byKey(const Key('global-security-sign-in')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen03-login-v5')), findsOneWidget);

    expect(await journey.requestEmailOtp('person@example.com'), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen03-otp-v2')), findsOneWidget);
    expect(await journey.verifyOtp('123456'), isTrue);
    await tester.pumpAndSettle();

    expect(journey.stage, JourneyStage.ready);
    expect(journey.isAuthenticated, isTrue);
    expect(find.byKey(const Key('global-security-v2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('global-security-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-main-v2')), findsOneWidget);
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

  testWidgets('direct Security restore returns to its exact safe origin', (
    tester,
  ) async {
    final journey = JourneySession(store: MemoryJourneyStore());
    addTearDown(journey.dispose);
    final router = GoRouter(
      initialLocation: Uri(
        path: '/app/account/security',
        queryParameters: const {'return': '/app/eat/home?cuisine=cafe'},
      ).toString(),
      routes: [
        GoRoute(
          path: '/app/account/security',
          builder: (context, state) => GlobalSecurityV2(
            session: journey,
            onSignOut: () async => true,
            openDeviceSettings: () async => true,
          ),
        ),
        GoRoute(
          path: '/app/eat/home',
          builder: (context, state) =>
              const Scaffold(key: Key('eat-origin-return')),
        ),
        GoRoute(
          path: '/app/mool',
          builder: (context, state) =>
              const Scaffold(key: Key('global-safe-return')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-security-back')));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/app/eat/home?cuisine=cafe',
    );
    expect(find.byKey(const Key('eat-origin-return')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Social Security keeps its surface and exact return together', () {
    final uri = Uri.parse(
      globalSecurityLocationForReturn(
        '/app/social?sub=videos',
        surfaceTone: GlobalProfileSurfaceTone.socialDark,
      ),
    );

    expect(uri.path, '/app/account/security');
    expect(uri.queryParameters['return'], '/app/social?sub=videos');
    expect(uri.queryParameters['surface'], 'social');
  });

  testWidgets('unsafe Security return uses the neutral Mool destination', (
    tester,
  ) async {
    final journey = JourneySession(store: MemoryJourneyStore());
    addTearDown(journey.dispose);
    final router = GoRouter(
      initialLocation: Uri(
        path: '/app/account/security',
        queryParameters: const {'return': 'https://example.com/account'},
      ).toString(),
      routes: [
        GoRoute(
          path: '/app/account/security',
          builder: (context, state) => GlobalSecurityV2(
            session: journey,
            onSignOut: () async => true,
            openDeviceSettings: () async => true,
          ),
        ),
        GoRoute(
          path: '/app/mool',
          builder: (context, state) =>
              const Scaffold(key: Key('global-safe-return')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global-security-back')));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/app/mool');
    expect(find.byKey(const Key('global-safe-return')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
