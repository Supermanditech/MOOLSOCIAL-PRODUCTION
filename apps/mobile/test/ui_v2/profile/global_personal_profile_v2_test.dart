import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/profile/global_personal_profile_v2.dart';
import 'package:moolsocial/ui_v2/profile/global_profile_panel_v2.dart';

import '../buy/buy_v2_screen_test.dart'
    show captureR66Visual, r66VisualCaptureRoot;

void main() {
  Future<JourneySession> signedInJourney() async {
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
      displayName: 'Host member',
      emailAddress: 'host@example.com',
      signInMethods: ['Email'],
    );
    return session;
  }

  Future<GoRouter> pumpProfile(
    WidgetTester tester,
    JourneySession session, {
    Size size = const Size(390, 844),
    double textScale = 1,
    Widget? gstDetails,
    VoidCallback? onOpenAddresses,
    Future<bool> Function(String name)? nameWriter,
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
            gstDetails: gstDetails,
            onOpenAddresses: onOpenAddresses,
          ),
        ),
        GoRoute(
          path: '/app/account/identity/name',
          builder: (_, _) => GlobalPersonalProfileNameEditorV2(
            session: session,
            onSaveDisplayName: nameWriter,
          ),
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
        theme: MoolTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: r66VisualCaptureRoot(child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-personal-profile')));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('guest Profile hides stale identity and unowned device alias', (
    tester,
  ) async {
    final session = JourneySession(store: MemoryJourneyStore())
      ..profileDisplayName = 'Unowned old alias'
      ..accountIdentity = const AuthenticatedAccountIdentity(
        displayName: 'Old identity',
        emailAddress: 'old@example.com',
        signInMethods: ['Email'],
      );
    addTearDown(session.dispose);
    await pumpProfile(tester, session);
    expect(find.text('Unowned old alias'), findsNothing);
    expect(find.text('Old identity'), findsNothing);
    expect(find.text('old@example.com'), findsNothing);
    await tester.tap(find.byKey(const Key('global-personal-profile-name')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('profile-security-destination')),
      findsOneWidget,
    );
  });

  testWidgets(
    'buying details reuse the provided address action and collapsed invoice form',
    (tester) async {
      final session = JourneySession(store: MemoryJourneyStore());
      addTearDown(session.dispose);
      var addresses = 0;
      await pumpProfile(
        tester,
        session,
        gstDetails: const Text('Original invoice form fixture'),
        onOpenAddresses: () => addresses++,
      );
      expect(find.text('Original invoice form fixture'), findsNothing);
      await tester.tap(
        find.byKey(const Key('global-personal-profile-addresses')),
      );
      expect(addresses, 1);
      final invoice = find.byKey(
        const Key('global-personal-profile-invoice-details'),
      );
      await tester.ensureVisible(invoice);
      await tester.tap(find.text('Invoice details'));
      await tester.pumpAndSettle();
      expect(find.text('Original invoice form fixture'), findsOneWidget);
    },
  );

  testWidgets('name editor rejects a draft after account identity changes', (
    tester,
  ) async {
    final session = await signedInJourney();
    addTearDown(session.dispose);
    var calls = 0;
    await pumpProfile(
      tester,
      session,
      nameWriter: (_) async {
        calls++;
        return true;
      },
    );
    await tester.tap(find.byKey(const Key('global-personal-profile-name')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('global-personal-profile-name-field')),
      'Previous account draft',
    );
    final originalName = session.profileDisplayName;
    session.accountIdentity = const AuthenticatedAccountIdentity(
      displayName: 'Different account',
      emailAddress: 'other@example.com',
      signInMethods: ['Email'],
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(session.profileDisplayName, originalName);
    expect(calls, 0);
    expect(
      find.byKey(const Key('global-personal-profile-name-editor')),
      findsOneWidget,
    );
  });

  testWidgets(
    'unconnected account name writer cannot report a device alias save',
    (tester) async {
      final session = await signedInJourney();
      addTearDown(session.dispose);
      await pumpProfile(tester, session);
      await tester.tap(find.byKey(const Key('global-personal-profile-name')));
      await tester.pumpAndSettle();
      expect(
        find.text('Account name updates are not available right now.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('global-personal-profile-name-field')),
            )
            .readOnly,
        isTrue,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('global-personal-profile-name-save')),
            )
            .onPressed,
        isNull,
      );
      expect(session.profileDisplayName, isNull);
    },
  );

  for (final result in ['ack', 'reject', 'throw', 'actor-change']) {
    testWidgets(
      'account name writer $result preserves acknowledgement and navigation',
      (tester) async {
        final session = await signedInJourney();
        addTearDown(session.dispose);
        final completion = Completer<bool>();
        var calls = 0;
        final router = await pumpProfile(
          tester,
          session,
          nameWriter: (name) {
            expect(name, 'Reviewed name');
            calls++;
            return completion.future;
          },
        );
        await tester.tap(find.byKey(const Key('global-personal-profile-name')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('global-personal-profile-name-field')),
          '  Reviewed name  ',
        );
        final save = tester
            .widget<FilledButton>(
              find.byKey(const Key('global-personal-profile-name-save')),
            )
            .onPressed!;
        save();
        save();
        await tester.pump();
        expect(calls, 1);
        expect(
          find.byKey(const Key('global-personal-profile-name-editor')),
          findsOneWidget,
        );
        if (result == 'actor-change') {
          session.accountIdentity = const AuthenticatedAccountIdentity(
            displayName: 'New actor',
            signInMethods: ['Email'],
          );
          router.go('/app/account/security');
          await tester.pumpAndSettle();
        }
        if (result == 'throw') {
          completion.completeError(StateError('host writer failed'));
        } else {
          completion.complete(result != 'reject');
        }
        await tester.pumpAndSettle();
        if (result == 'ack') {
          expect(
            find.byKey(const Key('global-personal-profile-v2')),
            findsOneWidget,
          );
        } else if (result == 'actor-change') {
          expect(
            find.byKey(const Key('profile-security-destination')),
            findsOneWidget,
          );
        } else {
          expect(
            find.text(
              'Could not save your name. Check your account and try again.',
            ),
            findsOneWidget,
          );
          expect(
            tester
                .widget<TextField>(
                  find.byKey(const Key('global-personal-profile-name-field')),
                )
                .controller!
                .text,
            '  Reviewed name  ',
          );
        }
        expect(session.profileDisplayName, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final textScale in [1.0, 2.0]) {
    for (final size in [const Size(390, 844), const Size(320, 568)]) {
      testWidgets('D004 complete name validation ${size.width} text $textScale', (
        tester,
      ) async {
        final session = await signedInJourney();
        addTearDown(session.dispose);
        final originalName = session.profileDisplayName;
        final router = await pumpProfile(
          tester,
          session,
          size: size,
          textScale: textScale,
          nameWriter: (_) async =>
              throw StateError('Invalid name must not reach writer'),
        );
        await tester.scrollUntilVisible(
          find.byKey(const Key('global-personal-profile-name')),
          180,
          scrollable: find.descendant(
            of: find.byKey(const Key('global-personal-profile-content')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('global-personal-profile-name')));
        await tester.pumpAndSettle();
        final field = find.byKey(
          const Key('global-personal-profile-name-field'),
        );
        await tester.enterText(field, '   ');
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        await tester.pumpAndSettle();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        const message = 'Enter a display name from 2 to 60 characters.';
        expect(find.text(message), findsOneWidget);
        expect(session.profileDisplayName, originalName);
        for (final keyboard in [true, false]) {
          if (!keyboard) {
            tester.view.viewInsets = FakeViewPadding.zero;
            await tester.pumpAndSettle();
          }
          final error = find.text(message);
          await tester.ensureVisible(error);
          await tester.pumpAndSettle();
          final paragraph = tester.renderObject<RenderParagraph>(error);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(tester.takeException(), isNull);
          await captureR66Visual(
            tester,
            'rv6-d004-${size.width.toInt()}-text-$textScale-keyboard-$keyboard',
          );
        }
        await tester.tap(
          find.byKey(const Key('global-personal-profile-name-back')),
        );
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/app/account/identity',
        );
        expect(session.profileDisplayName, originalName);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('one personal profile shows only global account information', (
    tester,
  ) async {
    final session = JourneySession(
      store: MemoryJourneyStore(),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await session.start();
    session.accountIdentity = const AuthenticatedAccountIdentity(
      displayName: 'Test Member',
      emailAddress: 'member@example.com',
      phoneNumber: '+91 90000 00000',
      signInMethods: ['Google', 'Phone'],
    );
    session
      ..languageCode = 'en'
      ..currentAreaLabel = 'Jodhpur';
    addTearDown(session.dispose);
    final router = await pumpProfile(tester, session);

    expect(find.byKey(const Key('global-personal-profile-v2')), findsOne);
    expect(find.text('Test Member'), findsWidgets);
    expect(find.text('member@example.com'), findsWidgets);
    expect(find.text('+91 90000 00000'), findsOne);
    expect(find.byKey(const Key('global-personal-profile-area')), findsNothing);
    expect(find.text('Google · Phone'), findsNothing);
    expect(
      find.byKey(const Key('global-personal-profile-progress')),
      findsNothing,
    );
    expect(find.text('My Workspaces'), findsNothing);
    expect(
      find.byKey(const Key('global-profile-active-workspace')),
      findsNothing,
    );
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

    expect(find.text('Sign in with email or mobile OTP'), findsOneWidget);
    expect(
      find.byKey(const Key('global-personal-profile-status')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('global-personal-profile-methods')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('global-personal-profile-progress-detail')),
      findsNothing,
    );

    final nameRow = find.byKey(const Key('global-personal-profile-name'));
    expect(nameRow.hitTestable(), findsOneWidget);
    await tester.tap(nameRow);
    await tester.pumpAndSettle();
    expect(
      GoRouterState.of(
        tester.element(find.byKey(const Key('profile-security-destination'))),
      ).uri.path,
      '/app/account/security',
    );
    expect(session.profileDisplayName, isNull);
    router.go('/app/account/identity');
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('global-personal-profile-email')),
    );
    await tester.pumpAndSettle();
    tester
        .widget<InkWell>(find.byKey(const Key('global-personal-profile-email')))
        .onTap!();
    await tester.pumpAndSettle();
    expect(
      GoRouterState.of(
        tester.element(find.byKey(const Key('profile-security-destination'))),
      ).uri.path,
      '/app/account/security',
    );
    expect(
      find.byKey(const Key('profile-security-destination')),
      findsOneWidget,
    );
    router.go('/app/account/identity');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('global-personal-profile-language')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('global-personal-profile-plans')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('global-personal-profile-workspaces')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact personal profile remains readable without overflow', (
    tester,
  ) async {
    final session = await signedInJourney();
    session.accountIdentity = const AuthenticatedAccountIdentity(
      displayName: 'A long authenticated MoolSocial member name',
      emailAddress: 'a.long.account.address@example.com',
      signInMethods: ['Email'],
    );
    session
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
