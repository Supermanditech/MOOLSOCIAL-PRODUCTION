import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/shared/shared_models.dart';
import 'package:moolsocial/features/shared/shared_services.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/features/shared/screens/shared_screens.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/ui_v2/profile/global_profile_panel_v2.dart';

void main() {
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 8),
  );

  MemoryJourneyStore readyStore() => MemoryJourneyStore(
    snapshot: const JourneySnapshot(
      languageCode: 'en',
      areaMode: 'manual',
      areaLabel: 'Jodhpur',
      setupComplete: true,
      profileDisplayName: 'Test Member',
    ),
  );

  JourneySession currentJourney({
    MemoryJourneyStore? store,
    AccountBootstrapGateway? accountBootstrapGateway,
  }) => JourneySession(
    store: store ?? readyStore(),
    otpGateway: ReviewOtpGateway(signedIn: true),
    accountBootstrapGateway: accountBootstrapGateway,
    accountIdentityGateway: ReviewAuthenticatedAccountIdentityGateway(
      identity: const AuthenticatedAccountIdentity(
        displayName: 'Test Member',
        emailAddress: 'member@example.com',
        phoneNumber: '+91 90000 00000',
        signInMethods: ['Phone'],
      ),
    ),
  );

  Future<SharedSession> mount(
    WidgetTester tester, {
    required String route,
    SharedSession? sharedSession,
    JourneySession? journeySession,
    ChatSession? chatSession,
    bool legacyPresentation = true,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
    final journey =
        journeySession ??
        JourneySession(
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
    final shared = sharedSession ?? SharedSession();
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      shared.dispose();
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('current-shared-screen-capture'),
        child: MoolSocialApp(
          key: UniqueKey(),
          session: journey,
          sharedSession: shared,
          chatSession: chatSession,
          initialLocation: route,
          legacyPresentationForTestsOnly: legacyPresentation,
        ),
      ),
    );
    await settle(tester);
    return shared;
  }

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            {
              AxisDirection.down,
              AxisDirection.up,
            }.contains(widget.axisDirection),
      );
      for (final state
          in scrollables
              .evaluate()
              .whereType<StatefulElement>()
              .map((element) => element.state)
              .whereType<ScrollableState>()) {
        if (state.position.maxScrollExtent <= state.position.minScrollExtent) {
          continue;
        }
        state.position.jumpTo(state.position.minScrollExtent);
        await tester.pump();
        for (
          var attempt = 0;
          attempt < 80 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          state.position.jumpTo(
            (state.position.pixels + 220).clamp(
              state.position.minScrollExtent,
              state.position.maxScrollExtent,
            ),
          );
          await tester.pump();
        }
        if (finder.evaluate().isNotEmpty) break;
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing target $key');
    await tester.ensureVisible(finder);
    await settle(tester);
    return finder;
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await settle(tester);
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    await tester.enterText(await reveal(tester, key), value);
    await settle(tester);
  }

  Future<void> go(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await settle(tester);
  }

  String location(WidgetTester tester) => GoRouterState.of(
    tester.element(find.byType(Scaffold).first),
  ).uri.toString();

  // These routes still own SharedSession item/filter/action contracts. Profile,
  // Help, Security and Preferences use their current production screens below.
  const routes = <int, String>{
    157: '/app/activity',
    160: '/app/files',
    162: '/app/account/workspaces',
  };

  testWidgets('Security exposes confirmed sign-out and returns to Sign in', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    final otp = ReviewOtpGateway(signedIn: true);
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      ),
      otpGateway: otp,
    );
    final shared = SharedSession();
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      shared.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        sharedSession: shared,
        initialLocation: '/app/account/security',
      ),
    );
    await settle(tester);

    await tap(tester, const Key('global-security-sign-out'));
    expect(find.text('End this session?'), findsOneWidget);
    expect(
      find.text('Your language and service area remain saved on this device.'),
      findsOneWidget,
    );
    expect(otp.signOutCount, 0);
    await tap(tester, const Key('global-security-sign-out-cancel'));
    expect(otp.signOutCount, 0);
    expect(journey.isAuthenticated, isTrue);
    expect(location(tester), '/app/account/security');
    await tap(tester, const Key('global-security-sign-out'));
    await tap(tester, const Key('global-security-sign-out-confirm'));

    expect(otp.signOutCount, 1);
    expect(journey.stage, JourneyStage.signIn);
    expect(find.byKey(const Key('screen03-login-v5')), findsOneWidget);
    expect(location(tester), '/sign-in');
    expect(journey.languageCode, 'en');
    expect(journey.manualArea, 'Jodhpur');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'current Profile exposes actual identity and exact account destinations',
    (tester) async {
      final journey = currentJourney();
      await mount(
        tester,
        route: '/app/account/identity',
        journeySession: journey,
        legacyPresentation: false,
      );
      expect(
        find.byKey(const Key('global-personal-profile-v2')),
        findsOneWidget,
      );
      for (final fact in const [
        (key: 'global-personal-profile-name', value: 'Test Member'),
        (key: 'global-personal-profile-email', value: 'member@example.com'),
        (key: 'global-personal-profile-phone', value: '+91 90000 00000'),
        (key: 'global-personal-profile-language', value: 'English'),
        (key: 'global-personal-profile-area', value: 'Jodhpur'),
        (key: 'global-personal-profile-status', value: 'Active'),
        (key: 'global-personal-profile-methods', value: 'Phone'),
      ]) {
        final row = await reveal(tester, Key(fact.key));
        expect(
          find.descendant(of: row, matching: find.text(fact.value)),
          findsOneWidget,
        );
      }
      for (final target in const [
        (
          action: 'global-personal-profile-email',
          path: '/app/account/security',
          back: 'global-security-back',
        ),
        (
          action: 'global-personal-profile-phone',
          path: '/app/account/security',
          back: 'global-security-back',
        ),
        (
          action: 'global-personal-profile-status',
          path: '/app/account/security',
          back: 'global-security-back',
        ),
        (
          action: 'global-personal-profile-methods',
          path: '/app/account/security',
          back: 'global-security-back',
        ),
        (
          action: 'global-personal-profile-language',
          path: '/app/account/workspaces/preferences',
          back: 'global-preferences-back',
        ),
        (
          action: 'global-personal-profile-area',
          path: '/app/account/workspaces/preferences',
          back: 'global-preferences-back',
        ),
      ]) {
        await tap(tester, Key(target.action));
        expect(Uri.parse(location(tester)).path, target.path);
        expect(
          Uri.parse(location(tester)).queryParameters['return'],
          '/app/account/identity',
        );
        await tap(tester, Key(target.back));
        expect(location(tester), '/app/account/identity');
        expect(journey.accountIdentity?.emailAddress, 'member@example.com');
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Profile name validates, cancels and retries storage without losing identity',
    (tester) async {
      final store = readyStore();
      final journey = currentJourney(store: store);
      await mount(
        tester,
        route: '/app/account/identity',
        journeySession: journey,
        legacyPresentation: false,
      );
      await tap(tester, const Key('global-personal-profile-name'));
      await enter(
        tester,
        const Key('global-personal-profile-name-field'),
        'Changed but not saved',
      );
      await tap(tester, const Key('global-personal-profile-name-back'));
      expect(journey.profileDisplayName, 'Test Member');
      expect(store.snapshot?.profileDisplayName, 'Test Member');
      await tap(tester, const Key('global-personal-profile-name'));
      await enter(tester, const Key('global-personal-profile-name-field'), 'A');
      await tap(tester, const Key('global-personal-profile-name-save'));
      expect(
        find.text('Enter a display name from 2 to 60 characters.'),
        findsOneWidget,
      );
      expect(journey.profileDisplayName, 'Test Member');
      store.writeFailure = StateError('test storage unavailable');
      await enter(
        tester,
        const Key('global-personal-profile-name-field'),
        'Updated Member',
      );
      await tap(tester, const Key('global-personal-profile-name-save'));
      expect(
        find.text('Display name could not be saved. Try again.'),
        findsOneWidget,
      );
      expect(journey.profileDisplayName, 'Test Member');
      expect(store.snapshot?.profileDisplayName, 'Test Member');
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('global-personal-profile-name-field')),
            )
            .controller
            ?.text,
        'Updated Member',
      );
      store.writeFailure = null;
      await tap(tester, const Key('global-personal-profile-name-save'));
      expect(location(tester), '/app/account/identity');
      expect(journey.profileDisplayName, 'Updated Member');
      expect(store.snapshot?.profileDisplayName, 'Updated Member');
      expect(journey.accountIdentity?.emailAddress, 'member@example.com');
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Profile return validation admits only the exact account Profile route',
    () {
      final profile = Uri(
        path: '/app/account/identity',
        queryParameters: {'return': '/app/work/earn', 'surface': 'social'},
      ).toString();
      expect(globalProfileSafeReturnLocation(profile), profile);
      for (final invalid in [
        '/app/account/identity/name',
        '/app/account/identity/anything',
        '/app/account/security',
        '/app/account/workspaces/preferences',
        '/app/account/identity/../security',
        '//example.com/app/account/identity',
        'https://example.com/app/account/identity',
        'app/account/identity',
      ]) {
        expect(
          globalProfileSafeReturnLocation(invalid),
          isNull,
          reason: invalid,
        );
      }
    },
  );

  for (final target in const [
    (
      action: 'global-personal-profile-email',
      path: '/app/account/security',
      back: 'global-security-back',
    ),
    (
      action: 'global-personal-profile-language',
      path: '/app/account/workspaces/preferences',
      back: 'global-preferences-back',
    ),
    (
      action: 'global-personal-profile-name',
      path: '/app/account/identity/name',
      back: 'global-personal-profile-name-back',
    ),
  ]) {
    for (final restored in [false, true]) {
      testWidgets(
        'Profile ${target.path} ${restored ? "restored toolbar" : "system"} Back keeps nested Work return',
        (tester) async {
          const workOrigin = '/app/work/earn';
          final profile = Uri(
            path: '/app/account/identity',
            queryParameters: {'return': workOrigin},
          ).toString();
          await mount(
            tester,
            route: profile,
            journeySession: currentJourney(),
            legacyPresentation: false,
          );
          await tap(tester, Key(target.action));
          final child = location(tester);
          expect(Uri.parse(child).path, target.path);
          expect(Uri.parse(child).queryParameters['return'], profile);
          if (restored) {
            await mount(
              tester,
              route: child,
              journeySession: currentJourney(),
              legacyPresentation: false,
            );
            await tap(tester, Key(target.back));
          } else {
            FocusManager.instance.primaryFocus?.unfocus();
            await settle(tester);
            await tester.binding.handlePopRoute();
            await settle(tester);
          }
          expect(location(tester), profile);
          expect(
            find.byKey(const Key('global-personal-profile-v2')),
            findsOneWidget,
          );
          await tap(tester, const Key('global-personal-profile-back'));
          expect(location(tester), workOrigin);
          expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'name save returns to exact social Profile with its surface and origin',
    (tester) async {
      const origin = '/app/social?sub=feed';
      final profile = Uri(
        path: '/app/account/identity',
        queryParameters: {'return': origin, 'surface': 'social'},
      ).toString();
      final journey = currentJourney();
      await mount(
        tester,
        route: profile,
        journeySession: journey,
        legacyPresentation: false,
      );
      await tap(tester, const Key('global-personal-profile-name'));
      expect(Uri.parse(location(tester)).queryParameters['surface'], 'social');
      await enter(
        tester,
        const Key('global-personal-profile-name-field'),
        'Saved Member',
      );
      await tap(tester, const Key('global-personal-profile-name-save'));
      expect(location(tester), profile);
      expect(journey.profileDisplayName, 'Saved Member');
      await tap(tester, const Key('global-personal-profile-back'));
      expect(location(tester), origin);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('current Profile security return stays readable at $scale text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final profile = Uri(
        path: '/app/account/identity',
        queryParameters: {'return': '/app/work/earn'},
      ).toString();
      await mount(
        tester,
        route: profile,
        journeySession: currentJourney(),
        legacyPresentation: false,
        size: scale == 1 ? const Size(412, 915) : const Size(320, 568),
      );
      Future<void> capture(String state) async {
        if (!const bool.fromEnvironment('MOOL_CAPTURE_STORE_VIEW_V2')) return;
        const folder = String.fromEnvironment('MOOL_STORE_VIEW_CAPTURE_DIR');
        expect(RegExp(r'^[a-z0-9-]+$').hasMatch(folder), isTrue);
        await expectLater(
          find.byKey(const Key('current-shared-screen-capture')),
          matchesGoldenFile(
            '../../../../MOOLSOCIAL-POST-UI-AUDIT-20260905/$folder/profile-$state-$scale.png',
          ),
        );
      }

      await tap(tester, const Key('global-personal-profile-email'));
      expect(find.byKey(const Key('global-security-v2')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture('security');
      await tap(tester, const Key('global-security-back'));
      expect(location(tester), profile);
      await tester.drag(
        find.byKey(const Key('global-personal-profile-content')),
        const Offset(0, 1200),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      final heroBounds = tester.getRect(
        find.byKey(const Key('global-personal-profile-hero')),
      );
      for (final suffix in ['name', 'detail', 'setup', 'completion']) {
        final text = find.byKey(Key('global-personal-profile-hero-$suffix'));
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: text, matching: find.byType(RichText)),
        );
        expect(paragraph.didExceedMaxLines, isFalse, reason: suffix);
        final bounds = tester.getRect(text);
        expect(heroBounds.contains(bounds.topLeft), isTrue, reason: suffix);
        expect(heroBounds.contains(bounds.bottomRight), isTrue, reason: suffix);
      }
      await capture('returned');
      final back = find.byKey(const Key('global-personal-profile-back'));
      expect(back.hitTestable(), findsOneWidget);
      final bounds = tester.getRect(back);
      expect(bounds.width, greaterThanOrEqualTo(44));
      expect(bounds.height, greaterThanOrEqualTo(44));
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(location(tester), '/app/work/earn');
      expect(tester.takeException(), isNull);
    });
  }

  for (final entry in routes.entries) {
    testWidgets(
      'screen ${entry.key} covers every filter, empty recovery and detail',
      (tester) async {
        final session = await mount(tester, route: entry.value);
        final spec = sharedScreenSpec(entry.key);
        expect(find.byKey(Key('shared-screen-${entry.key}')), findsOneWidget);
        for (final filter in spec.filters) {
          await tap(tester, Key('shared-${entry.key}-filter-${_slug(filter)}'));
          expect(session.filterFor(spec), filter);
        }
        session
          ..setFilter(entry.key, spec.filters.first)
          ..setSearch(entry.key, 'a result that cannot exist');
        await settle(tester);
        expect(find.byKey(Key('shared-${entry.key}-empty')), findsOneWidget);
        await tap(tester, Key('shared-${entry.key}-reset'));
        expect(session.visibleItems(spec).length, spec.items.length);

        for (final item in spec.items) {
          await tap(tester, Key('shared-${entry.key}-item-${item.id}'));
          expect(
            find.byKey(Key('shared-${entry.key}-detail-${item.id}')),
            findsOneWidget,
          );
          expect(find.text(item.why), findsOneWidget);
          for (final fact in item.facts) {
            expect(find.text(fact.label), findsWidgets);
            expect(find.text(fact.value), findsWidgets);
          }
          await tap(tester, Key('shared-${entry.key}-detail-${item.id}-close'));
        }
      },
    );
  }

  for (final entry in routes.entries) {
    testWidgets(
      'screen ${entry.key} completes every primary and secondary exact retry',
      (tester) async {
        final gateway = ReviewSharedGateway();
        final session = SharedSession(gateway: gateway);
        await mount(tester, route: entry.value, sharedSession: session);
        final spec = sharedScreenSpec(entry.key);

        for (final item in spec.items) {
          await go(tester, entry.value);
          await tap(tester, Key('shared-${entry.key}-item-${item.id}'));
          final primaryId = session.actionId(entry.key, item.id, 'primary');
          if (item.confirmation != null) {
            await tap(tester, Key('shared-${entry.key}-${item.id}-primary'));
            expect(gateway.calls[primaryId] ?? 0, 0);
            await tap(
              tester,
              Key('shared-${entry.key}-${item.id}-confirm-primary'),
            );
          }
          gateway
            ..failNext = true
            ..failActionId = primaryId;
          await tap(tester, Key('shared-${entry.key}-${item.id}-primary'));
          expect(gateway.calls[primaryId], 1);
          expect(session.actionComplete(primaryId), isFalse);
          await tap(tester, Key('shared-${entry.key}-${item.id}-primary'));
          expect(gateway.calls[primaryId], 2);
          expect(session.actionComplete(primaryId), isTrue);

          if (item.primaryRoute == null) {
            await tap(tester, Key('shared-${entry.key}-${item.id}-primary'));
            expect(gateway.calls[primaryId], 2);
            await tap(
              tester,
              Key('shared-${entry.key}-detail-${item.id}-close'),
            );
          } else {
            expect(location(tester), item.primaryRoute);
          }

          if (item.secondary != null) {
            await go(tester, entry.value);
            await tap(tester, Key('shared-${entry.key}-item-${item.id}'));
            final secondaryId = session.actionId(
              entry.key,
              item.id,
              'secondary',
            );
            if (item.secondaryConfirmation != null) {
              await tap(
                tester,
                Key('shared-${entry.key}-${item.id}-secondary'),
              );
              expect(gateway.calls[secondaryId] ?? 0, 0);
              await tap(
                tester,
                Key('shared-${entry.key}-${item.id}-confirm-secondary'),
              );
            }
            gateway
              ..failNext = true
              ..failActionId = secondaryId;
            await tap(tester, Key('shared-${entry.key}-${item.id}-secondary'));
            expect(gateway.calls[secondaryId], 1);
            await tap(tester, Key('shared-${entry.key}-${item.id}-secondary'));
            expect(gateway.calls[secondaryId], 2);
            expect(session.actionComplete(secondaryId), isTrue);
            if (item.secondaryRoute == null) {
              await tap(
                tester,
                Key('shared-${entry.key}-${item.id}-secondary'),
              );
              expect(gateway.calls[secondaryId], 2);
              await tap(
                tester,
                Key('shared-${entry.key}-detail-${item.id}-close'),
              );
            } else {
              expect(location(tester), item.secondaryRoute);
            }
          }
        }
      },
    );
  }

  testWidgets(
    'current Help topics and support Chat preserve exact origin and draft',
    (tester) async {
      final chat = ChatSession();
      addTearDown(chat.dispose);
      final origin = Uri(
        path: '/app/ask',
        queryParameters: {'return': '/app/work/earn'},
      ).toString();
      await mount(
        tester,
        route: origin,
        chatSession: chat,
        legacyPresentation: false,
      );
      expect(find.byKey(const Key('global-help-support-v2')), findsOneWidget);
      expect(find.byKey(const Key('shared-159-scan')), findsNothing);
      expect(find.byKey(const Key('shared-159-voice')), findsNothing);
      for (final target in const [
        (
          action: 'global-help-security',
          screen: 'global-security-v2',
          back: 'global-security-back',
          path: '/app/account/security',
        ),
        (
          action: 'global-help-preferences',
          screen: 'global-privacy-preferences-v2',
          back: 'global-preferences-back',
          path: '/app/account/workspaces/preferences',
        ),
      ]) {
        await tap(tester, Key(target.action));
        expect(find.byKey(Key(target.screen)), findsOneWidget);
        expect(Uri.parse(location(tester)).path, target.path);
        expect(Uri.parse(location(tester)).queryParameters['return'], origin);
        await tap(tester, Key(target.back));
        expect(location(tester), origin);
      }
      await tap(tester, const Key('global-help-open-support-chat'));
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      expect(chat.selectedFilter, ChatThreadType.support);
      expect(Uri.parse(location(tester)).queryParameters['return'], origin);
      await tap(tester, const Key('chat-open-thread-order-support'));
      await enter(
        tester,
        const Key('chat-message-field'),
        'Please review my application.',
      );
      expect(
        chat.draftTextForSession('order-support'),
        'Please review my application.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester);
      await tap(tester, const Key('chat-back'));
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      await tap(tester, const Key('chat-inbox-back'));
      expect(location(tester), origin);
      await tap(tester, const Key('global-help-open-support-chat'));
      await tap(tester, const Key('chat-open-thread-order-support'));
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-message-field')))
            .controller
            ?.text,
        'Please review my application.',
      );
      expect(chat.messages('order-support'), hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'screen 160 invokes file sources without claiming cancelled selection',
    (tester) async {
      final session = SharedSession();
      addTearDown(session.dispose);
      final picker = _CancelledFilePicker();
      await tester.pumpWidget(
        MaterialApp(
          home: SharedHubScreen(
            session: session,
            screen: 160,
            filePicker: picker,
          ),
        ),
      );
      await settle(tester);
      for (final source in const ['camera', 'scan', 'gallery', 'file']) {
        await tap(tester, const Key('shared-160-top-action'));
        await tap(tester, Key('shared-file-add-$source'));
        expect(session.noticeMessage, isNull);
      }
      expect(picker.sources, [
        WorkProofSource.camera,
        WorkProofSource.camera,
        WorkProofSource.gallery,
        WorkProofSource.upload,
      ]);
      await tap(tester, const Key('shared-160-top-action'));
      await tap(tester, const Key('shared-file-add-cancel'));
      expect(find.byKey(const Key('shared-file-add-sheet')), findsNothing);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('R6617 Files preview replace and error retry stay local $scale', (
      tester,
    ) async {
      final session = SharedSession();
      addTearDown(session.dispose);
      final picker = _ControlledFilePicker();
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(
              key: const Key('files-review-capture'),
              child: child!,
            ),
          ),
          home: SharedHubScreen(
            session: session,
            screen: 160,
            filePicker: picker,
          ),
        ),
      );
      await settle(tester);
      await tester.drag(
        find.byKey(const Key('shared-160-list')),
        const Offset(0, -350),
      );
      await settle(tester);
      await tap(tester, const Key('shared-160-top-action'));
      await tap(tester, const Key('shared-file-add-file'));
      picker.pending.completeError(
        const WorkGatewayException('Choose a PDF or image up to 10 MB.'),
      );
      await settle(tester);
      expect(find.text('Choose a PDF or image up to 10 MB.'), findsOneWidget);
      expect(
        find.byKey(const Key('shared-file-error')).hitTestable(),
        findsOneWidget,
      );
      expect(session.noticeMessage, isNull);
      picker.pending = Completer<WorkPickedProof?>();
      await tap(tester, const Key('shared-160-top-action'));
      await tap(tester, const Key('shared-file-add-gallery'));
      picker.pending.complete(
        WorkPickedProof(
          fileName: 'test.png',
          contentType: 'image/png',
          bytes: base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aS1sAAAAASUVORK5CYII=',
          ),
        ),
      );
      await settle(tester);
      expect(find.byKey(const Key('work-document-preview')), findsOneWidget);
      expect(
        find.text('Local preview · not uploaded or shared'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('shared-file-error')), findsNothing);
      if (const bool.fromEnvironment('MOOL_CAPTURE_STORE_VIEW_V2')) {
        const folder = String.fromEnvironment('MOOL_STORE_VIEW_CAPTURE_DIR');
        expect(RegExp(r'^[a-z0-9-]+$').hasMatch(folder), isTrue);
        await expectLater(
          find.byKey(const Key('files-review-capture')),
          matchesGoldenFile(
            '../../../../MOOLSOCIAL-POST-UI-AUDIT-20260905/$folder/files-preview-$scale.png',
          ),
        );
      }
      await tap(tester, const Key('work-document-replace'));
      expect(find.byKey(const Key('shared-file-add-sheet')), findsOneWidget);
      await tap(tester, const Key('shared-file-add-cancel'));
      expect(find.byKey(const Key('work-document-preview')), findsNothing);
      expect(session.noticeMessage, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('R6617 Files ignores picker completion after screen disposal', (
    tester,
  ) async {
    final session = SharedSession();
    addTearDown(session.dispose);
    final picker = _ControlledFilePicker();
    await tester.pumpWidget(
      MaterialApp(
        home: SharedHubScreen(
          session: session,
          screen: 160,
          filePicker: picker,
        ),
      ),
    );
    await settle(tester);
    await tap(tester, const Key('shared-160-top-action'));
    await tap(tester, const Key('shared-file-add-file'));
    await tester.pumpWidget(const SizedBox());
    picker.pending.complete(null);
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(session.noticeMessage, isNull);
  });

  testWidgets(
    'current Preferences persist language and recover invalid or failed area edits',
    (tester) async {
      final store = readyStore();
      final journey = currentJourney(store: store);
      const route = '/app/account/workspaces/preferences';
      await mount(
        tester,
        route: route,
        journeySession: journey,
        legacyPresentation: false,
      );
      expect(
        find.byKey(const Key('global-privacy-preferences-v2')),
        findsOneWidget,
      );
      for (final language in ['hi', 'en']) {
        await tap(tester, const Key('global-preferences-language'));
        await tap(tester, Key('global-preferences-language-$language'));
        expect(journey.languageCode, language);
        expect(store.snapshot?.languageCode, language);
        expect(
          find.byKey(const Key('global-preferences-language-sheet')),
          findsNothing,
        );
      }
      await tap(tester, const Key('global-preferences-area'));
      await enter(
        tester,
        const Key('global-preferences-area-input'),
        'Not saved',
      );
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(journey.manualArea, 'Jodhpur');
      expect(store.snapshot?.areaLabel, 'Jodhpur');
      await tap(tester, const Key('global-preferences-area'));
      await enter(tester, const Key('global-preferences-area-input'), 'A');
      await tap(tester, const Key('global-preferences-area-save'));
      expect(
        find.text('Enter at least 3 characters for your area.'),
        findsOneWidget,
      );
      expect(journey.manualArea, 'Jodhpur');
      store.writeFailure = StateError('test storage unavailable');
      await enter(
        tester,
        const Key('global-preferences-area-input'),
        'Sardarpura',
      );
      await tap(tester, const Key('global-preferences-area-save'));
      expect(
        find.text('Service area could not be saved. Try again.'),
        findsOneWidget,
      );
      expect(journey.manualArea, 'Jodhpur');
      expect(store.snapshot?.areaLabel, 'Jodhpur');
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('global-preferences-area-input')),
            )
            .controller
            ?.text,
        'Sardarpura',
      );
      store.writeFailure = null;
      await tap(tester, const Key('global-preferences-area-save'));
      expect(journey.manualArea, 'Sardarpura');
      expect(store.snapshot?.areaLabel, 'Sardarpura');
      expect(
        find.byKey(const Key('global-preferences-area-sheet')),
        findsNothing,
      );
      final restored = currentJourney(store: store);
      await mount(
        tester,
        route: route,
        journeySession: restored,
        legacyPresentation: false,
      );
      expect(restored.manualArea, 'Sardarpura');
      expect(restored.languageCode, 'en');
      expect(find.text('Sardarpura'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final target in const [
    (
      route: '/app/account/security',
      screen: 'global-security-v2',
      action: 'global-security-device-settings',
    ),
    (
      route: '/app/account/workspaces/preferences',
      screen: 'global-privacy-preferences-v2',
      action: 'global-preferences-notifications',
    ),
  ]) {
    testWidgets(
      '${target.screen} uses the actual device permission boundary with retry',
      (tester) async {
        const channel = MethodChannel(
          'flutter.baseflow.com/permissions/methods',
        );
        final calls = <String>[];
        var available = false;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            calls.add(call.method);
            if (call.method != 'openAppSettings') {
              throw StateError('Unexpected permission mutation ${call.method}');
            }
            return available;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        final journey = currentJourney();
        await mount(
          tester,
          route: target.route,
          journeySession: journey,
          legacyPresentation: false,
        );
        await tap(tester, Key(target.action));
        expect(calls, ['openAppSettings']);
        expect(
          find.text('Device settings could not be opened.'),
          findsOneWidget,
        );
        expect(location(tester), target.route);
        expect(journey.isAuthenticated, isTrue);
        available = true;
        await tap(tester, Key(target.action));
        expect(calls, ['openAppSettings', 'openAppSettings']);
        expect(find.byKey(Key(target.screen)), findsOneWidget);
        expect(journey.isAuthenticated, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final mode in ['offline', 'denied']) {
    testWidgets(
      'Security does not claim safe sign-out when local invalidation is $mode',
      (tester) async {
        final gateway = ReviewAccountBootstrapGateway(
          invalidationFailure: StateError('test $mode'),
        );
        final journey = currentJourney(accountBootstrapGateway: gateway);
        await mount(
          tester,
          route: '/app/account/security',
          journeySession: journey,
          legacyPresentation: false,
        );
        expect(gateway.invalidationCount, 0);
        await tap(tester, const Key('global-security-sign-out'));
        expect(gateway.invalidationCount, 0);
        await tap(tester, const Key('global-security-sign-out-confirm'));
        expect(gateway.invalidationCount, 1);
        expect(
          find.text(
            'Sign-out could not be completed safely. Check the connection and try again.',
          ),
          findsOneWidget,
        );
        expect(location(tester), '/app/account/security');
        expect(journey.isAuthenticated, isTrue);
        gateway.invalidationFailure = null;
        await tap(tester, const Key('global-security-sign-out'));
        await tap(tester, const Key('global-security-sign-out-confirm'));
        expect(gateway.invalidationCount, 2);
        expect(journey.isAuthenticated, isFalse);
        expect(location(tester), '/sign-in');
        expect(journey.languageCode, 'en');
        expect(journey.manualArea, 'Jodhpur');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'universal profile and shared dock reach every shared owner and return',
    (tester) async {
      await mount(tester, route: '/app/social');
      await tap(tester, const Key('open-profile'));
      await tap(tester, const Key('profile-workspace'));
      expect(location(tester), '/app/account/workspaces');
      await tap(tester, const Key('shared-local-activity'));
      expect(location(tester), '/app/activity');
      await tap(tester, const Key('shared-local-settings'));
      expect(location(tester), '/app/account/workspaces/preferences');
      await tap(tester, const Key('global-preferences-back'));
      expect(location(tester), '/app/activity');
      await tap(tester, const Key('shared-local-workspaces'));
      expect(location(tester), '/app/account/workspaces');
      await tap(tester, const Key('mool-global-chat'));
      expect(location(tester), contains('/app/chat/inbox'));
    },
  );

  testWidgets('compact shared hub keeps Mool and Chat distinct and tappable', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(
      tester,
      route: '/app/account/workspaces',
      size: const Size(320, 568),
    );

    const moolKey = Key('mool-home-launcher');
    const chatKey = Key('mool-global-chat');
    expect(find.byKey(moolKey), findsOneWidget);
    expect(find.byKey(chatKey), findsOneWidget);
    final moolRect = tester.getRect(find.byKey(moolKey));
    final chatRect = tester.getRect(find.byKey(chatKey));
    expect(moolRect.width, greaterThanOrEqualTo(48));
    expect(moolRect.height, greaterThanOrEqualTo(48));
    expect(chatRect.width, greaterThanOrEqualTo(48));
    expect(chatRect.height, greaterThanOrEqualTo(48));
    expect(moolRect.overlaps(chatRect), isFalse);

    await tap(tester, chatKey);
    expect(location(tester), contains('/app/chat/inbox'));
    expect(tester.takeException(), isNull);
  });
}

class _CancelledFilePicker implements WorkProofPicker {
  final sources = <WorkProofSource>[];
  @override
  Future<WorkPickedProof?> pick(WorkProofSource source) async {
    sources.add(source);
    return null;
  }
}

class _ControlledFilePicker implements WorkProofPicker {
  Completer<WorkPickedProof?> pending = Completer<WorkPickedProof?>();
  @override
  Future<WorkPickedProof?> pick(WorkProofSource source) => pending.future;
}

String _slug(String value) => value
    .toLowerCase()
    .replaceAll('&', 'and')
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp('(^-+|-+\$)'), '');
