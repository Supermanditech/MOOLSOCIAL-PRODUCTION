import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/ui_v2/profile/global_personal_profile_v2.dart';

void main() {
  Future<GoRouter> pumpProfile(
    WidgetTester tester, {
    required AuthenticatedAccountIdentity? identity,
    required bool isAuthenticated,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/app/account/profile',
      routes: [
        GoRoute(
          path: '/app/account/profile',
          builder: (context, state) => GlobalPersonalProfileV2(
            identity: identity,
            isAuthenticated: isAuthenticated,
          ),
        ),
        GoRoute(
          path: '/app/account/security',
          builder: (context, state) => const Scaffold(
            body: Text('Security', key: Key('security-destination')),
          ),
        ),
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => const Scaffold(
            body: Text('Sign in', key: Key('sign-in-destination')),
          ),
        ),
        GoRoute(
          path: '/app/work/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Work', key: Key('work-destination'))),
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

  testWidgets('guest profile uses truthful empty state and sign-in recovery', (
    tester,
  ) async {
    await pumpProfile(tester, identity: null, isAuthenticated: false);

    expect(find.byKey(const Key('global-personal-profile-v2')), findsOne);
    expect(find.text('Personal account'), findsOne);
    expect(find.text('Not added'), findsNWidgets(3));
    expect(find.text('Sign in to view'), findsOne);
    expect(find.textContaining('Rahul'), findsNothing);
    expect(find.textContaining('+91 92518'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('global-personal-profile-primary-action')),
    );
    await tester.tap(
      find.byKey(const Key('global-personal-profile-primary-action')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sign-in-destination')), findsOne);
  });

  testWidgets(
    'authenticated profile renders exact identity and security path',
    (tester) async {
      const identity = AuthenticatedAccountIdentity(
        displayName: 'Asha Mehta',
        emailAddress: 'asha@example.com',
        phoneNumber: '+91 90000 00000',
        providerAccountLabel: 'Google account',
        signInMethods: ['Google', 'Mobile'],
      );
      await pumpProfile(tester, identity: identity, isAuthenticated: true);

      expect(find.text('Asha Mehta'), findsWidgets);
      expect(find.text('asha@example.com'), findsOne);
      expect(find.text('+91 90000 00000'), findsOne);
      expect(find.text('Google · Mobile'), findsOne);
      expect(find.text('Google account'), findsOne);
      expect(find.text('Active'), findsOne);

      await tester.ensureVisible(
        find.byKey(const Key('global-personal-profile-primary-action')),
      );
      await tester.tap(
        find.byKey(const Key('global-personal-profile-primary-action')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('security-destination')), findsOne);
    },
  );

  testWidgets('compact large-text personal profile remains scroll-safe', (
    tester,
  ) async {
    await pumpProfile(
      tester,
      identity: null,
      isAuthenticated: false,
      size: const Size(320, 700),
      textScale: 1.4,
    );

    expect(find.byKey(const Key('global-personal-profile-v2')), findsOne);
    expect(tester.takeException(), isNull);
  });
}
