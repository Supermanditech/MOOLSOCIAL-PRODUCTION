import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/profile/global_personal_profile_v2.dart';
import 'package:moolsocial/ui_v2/profile/global_profile_panel_v2.dart';

void main() {
  Future<GoRouter> pumpProfile(
    WidgetTester tester,
    JourneySession session, {
    Size size = const Size(390, 844),
    double textScale = 1,
    GlobalProfileSurfaceTone surfaceTone = GlobalProfileSurfaceTone.light,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/origin',
      routes: [
        GoRoute(
          path: '/origin',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('open-personal-profile'),
                onPressed: () => context.push('/app/account/identity'),
                child: const Text('Open profile'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/app/account/identity',
          builder: (context, state) => GlobalPersonalProfileV2(
            session: session,
            surfaceTone: surfaceTone,
          ),
        ),
        GoRoute(
          path: '/app/account/identity/name',
          builder: (_, _) =>
              GlobalPersonalProfileNameEditorV2(session: session),
        ),
        GoRoute(
          path: '/app/account/security',
          builder: (_, _) =>
              const Scaffold(key: Key('profile-security-destination')),
        ),
        GoRoute(
          path: '/app/account/workspaces/preferences',
          builder: (_, _) =>
              const Scaffold(key: Key('profile-preferences-destination')),
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
    await tester.tap(find.byKey(const Key('open-personal-profile')));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('one personal profile shows only global account information', (
    tester,
  ) async {
    final session = JourneySession(store: MemoryJourneyStore())
      ..accountIdentity = const AuthenticatedAccountIdentity(
        displayName: 'Test Member',
        emailAddress: 'member@example.com',
        phoneNumber: '+91 90000 00000',
        signInMethods: ['Google', 'Phone'],
      )
      ..languageCode = 'en'
      ..currentAreaLabel = 'Jodhpur';
    addTearDown(session.dispose);
    final router = await pumpProfile(tester, session);

    expect(find.byKey(const Key('global-personal-profile-v2')), findsOne);
    expect(find.text('Test Member'), findsWidgets);
    expect(find.text('member@example.com'), findsWidgets);
    expect(find.text('+91 90000 00000'), findsOne);
    expect(find.text('Jodhpur'), findsOne);
    expect(find.text('Google · Phone'), findsOne);
    expect(find.text('3 of 3 complete'), findsOne);
    expect(find.textContaining('Workspace'), findsNothing);
    expect(find.textContaining('Orders'), findsNothing);
    expect(find.textContaining('Payments'), findsNothing);

    await tester.tap(find.byKey(const Key('global-personal-profile-back')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/origin');
    expect(find.byKey(const Key('open-personal-profile')), findsOne);
  });

  testWidgets('incomplete profile explains progress and every row acts', (
    tester,
  ) async {
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      ),
    )..manualArea = 'Jodhpur';
    addTearDown(session.dispose);
    final router = await pumpProfile(tester, session);

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Not signed in'), findsOneWidget);
    expect(find.text('Add a sign-in method'), findsOneWidget);
    expect(find.text('Next: display name · contact'), findsOneWidget);

    await tester.tap(find.byKey(const Key('global-personal-profile-name')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('global-personal-profile-name-field')),
      'Aarav Sharma',
    );
    await tester.ensureVisible(
      find.byKey(const Key('global-personal-profile-name-save')),
    );
    await tester.pumpAndSettle();
    tester
        .widget<FilledButton>(
          find.byKey(const Key('global-personal-profile-name-save')),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(session.profileDisplayName, 'Aarav Sharma');
    expect(find.text('Aarav Sharma'), findsWidgets);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/app/account/identity',
    );

    await tester.ensureVisible(
      find.byKey(const Key('global-personal-profile-email')),
    );
    await tester.pumpAndSettle();
    tester
        .widget<InkWell>(
          find.byKey(const Key('global-personal-profile-email')),
        )
        .onTap!();
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/app/account/security',
    );
    expect(
      find.byKey(const Key('profile-security-destination')),
      findsOneWidget,
    );
    router.go('/app/account/identity');
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('global-personal-profile-language')),
    );
    await tester.pumpAndSettle();
    tester
        .widget<InkWell>(
          find.byKey(const Key('global-personal-profile-language')),
        )
        .onTap!();
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/app/account/workspaces/preferences',
    );
    expect(
      find.byKey(const Key('profile-preferences-destination')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact personal profile remains readable without overflow', (
    tester,
  ) async {
    final session = JourneySession(store: MemoryJourneyStore())
      ..accountIdentity = const AuthenticatedAccountIdentity(
        displayName: 'A long authenticated MoolSocial member name',
        emailAddress: 'a.long.account.address@example.com',
        signInMethods: ['Email'],
      )
      ..languageCode = 'hi'
      ..manualArea = 'Khema-Ka-Kuwa, Jodhpur, Rajasthan';
    addTearDown(session.dispose);
    await pumpProfile(
      tester,
      session,
      size: const Size(320, 700),
      textScale: 1.3,
      surfaceTone: GlobalProfileSurfaceTone.socialDark,
    );

    expect(find.byKey(const Key('global-personal-profile-v2')), findsOne);
    expect(
      tester
          .widget<Scaffold>(find.byKey(const Key('global-personal-profile-v2')))
          .backgroundColor,
      const Color(0xFF0F0F0F),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('global-personal-profile-methods')),
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('global-personal-profile-content')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Email'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'direct Personal profile restore returns to its exact safe origin',
    (tester) async {
      final session = JourneySession(store: MemoryJourneyStore());
      addTearDown(session.dispose);
      final router = GoRouter(
        initialLocation: Uri(
          path: '/app/account/identity',
          queryParameters: const {'return': '/app/ride?sub=cab'},
        ).toString(),
        routes: [
          GoRoute(
            path: '/app/account/identity',
            builder: (context, state) =>
                GlobalPersonalProfileV2(session: session),
          ),
          GoRoute(
            path: '/app/ride',
            builder: (context, state) =>
                const Scaffold(key: Key('ride-origin-return')),
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
      await tester.tap(find.byKey(const Key('global-personal-profile-back')));
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/app/ride?sub=cab',
      );
      expect(find.byKey(const Key('ride-origin-return')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'profile panel binds Personal profile to the exact originating location',
    () {
      expect(
        globalPersonalProfileLocationForReturn('/app/social?sub=feed'),
        Uri(
          path: '/app/account/identity',
          queryParameters: const {'return': '/app/social?sub=feed'},
        ).toString(),
      );
    },
  );

  test(
    'Social Personal profile keeps its surface and exact return together',
    () {
      final uri = Uri.parse(
        globalPersonalProfileLocationForReturn(
          '/app/social?sub=videos',
          surfaceTone: GlobalProfileSurfaceTone.socialDark,
        ),
      );

      expect(uri.path, '/app/account/identity');
      expect(uri.queryParameters['return'], '/app/social?sub=videos');
      expect(uri.queryParameters['surface'], 'social');
    },
  );

  testWidgets(
    'unsafe Personal profile return uses the neutral Mool destination',
    (tester) async {
      final session = JourneySession(store: MemoryJourneyStore());
      addTearDown(session.dispose);
      final router = GoRouter(
        initialLocation: Uri(
          path: '/app/account/identity',
          queryParameters: const {'return': 'https://example.com/account'},
        ).toString(),
        routes: [
          GoRoute(
            path: '/app/account/identity',
            builder: (context, state) =>
                GlobalPersonalProfileV2(session: session),
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
      await tester.tap(find.byKey(const Key('global-personal-profile-back')));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/app/mool');
      expect(find.byKey(const Key('global-safe-return')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
