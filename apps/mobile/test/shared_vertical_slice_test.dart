import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/shared/shared_models.dart';
import 'package:moolsocial/features/shared/shared_services.dart';
import 'package:moolsocial/features/shared/shared_session.dart';

void main() {
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 8),
  );

  Future<SharedSession> mount(
    WidgetTester tester, {
    required String route,
    SharedSession? sharedSession,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
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
    final shared = sharedSession ?? SharedSession();
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      shared.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        sharedSession: shared,
        initialLocation: route,
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

  const routes = <int, String>{
    157: '/app/activity',
    158: '/app/account/identity',
    159: '/app/ask',
    160: '/app/files',
    161: '/app/account/security',
    162: '/app/account/workspaces',
    165: '/app/account/workspaces/preferences',
  };

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
    'screen 159 covers invalid, no match, scan, voice, permissions and retry',
    (tester) async {
      final gateway = ReviewSharedGateway();
      final session = SharedSession(gateway: gateway);
      await mount(tester, route: '/app/ask', sharedSession: session);
      await tap(tester, const Key('shared-159-submit'));
      expect(gateway.calls, isEmpty);
      await enter(tester, const Key('shared-159-input'), 'something unknown');
      await tap(tester, const Key('shared-159-submit'));
      expect(gateway.calls, isEmpty);

      session.cameraAllowed = false;
      await tap(tester, const Key('shared-159-scan'));
      await tap(tester, const Key('shared-camera-use-keyboard'));
      session.cameraAllowed = true;
      await tap(tester, const Key('shared-159-scan'));
      expect(session.noticeMessage, contains('Nothing is paid automatically'));

      session.microphoneAllowed = false;
      await tap(tester, const Key('shared-159-voice'));
      await tap(tester, const Key('shared-microphone-use-keyboard'));
      session.microphoneAllowed = true;
      await tap(tester, const Key('shared-159-voice'));
      expect(session.input, contains('atta'));

      gateway
        ..failNext = true
        ..failActionId = 'SHARED-159-ASK-BUY';
      await tap(tester, const Key('shared-159-submit'));
      expect(gateway.calls['SHARED-159-ASK-BUY'], 1);
      expect(session.inputResult, isNull);
      await tap(tester, const Key('shared-159-submit'));
      expect(gateway.calls['SHARED-159-ASK-BUY'], 2);
      expect(session.inputResult?.route, '/app/buy/grocery');
      await tap(tester, const Key('shared-159-result-open'));
      expect(location(tester), '/app/buy/grocery');
    },
  );

  testWidgets('screen 160 completes all file-source and cancel choices', (
    tester,
  ) async {
    final session = await mount(tester, route: '/app/files');
    for (final source in const ['camera', 'scan', 'gallery', 'file']) {
      await tap(tester, const Key('shared-160-top-action'));
      await tap(tester, Key('shared-file-add-$source'));
      expect(session.noticeMessage, contains('opened'));
    }
    await tap(tester, const Key('shared-160-top-action'));
    await tap(tester, const Key('shared-file-add-cancel'));
    expect(find.byKey(const Key('shared-file-add-sheet')), findsNothing);
  });

  testWidgets(
    'screen 165 tests every control, locked boundary and pause duration',
    (tester) async {
      final session = await mount(
        tester,
        route: '/app/account/workspaces/preferences',
      );
      final spec = sharedScreenSpec(165);
      for (final item in spec.items) {
        await tap(tester, Key('shared-165-item-${item.id}'));
        for (final control in item.controls) {
          final before = session.controlValue(item, control);
          await tap(tester, Key('shared-165-${item.id}-control-${control.id}'));
          final after = session.controlValue(item, control);
          if (control.locked || control.subscriptionRequired) {
            expect(after, before);
            expect(session.errorMessage, isNotNull);
            session.dismissMessages();
            await settle(tester);
          } else {
            expect(after, isNot(before));
          }
        }
        if (item.secondary?.startsWith('Pause') ?? false) {
          for (final duration in const [
            '30 minutes',
            '1 hour',
            'Until tomorrow',
          ]) {
            await tap(
              tester,
              Key('shared-165-${item.id}-pause-${_slug(duration)}'),
            );
            expect(session.pauseDuration, duration);
          }
        }
        if (item.id == 'agent') {
          expect(find.text('Runs automatically'), findsOneWidget);
          expect(find.text('Asks before action'), findsOneWidget);
          expect(find.text('Never delegated'), findsOneWidget);
        }
        await tap(tester, Key('shared-165-detail-${item.id}-close'));
      }
    },
  );

  for (final mode in ['offline', 'denied']) {
    testWidgets('protected shared actions preserve state when $mode', (
      tester,
    ) async {
      final gateway = ReviewSharedGateway();
      final session = SharedSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/account/security',
        sharedSession: session,
      );
      if (mode == 'offline') {
        session.setOnline(false);
      } else {
        session.setAuthorized(false);
      }
      await tap(tester, const Key('shared-161-item-emergency-lock'));
      await tap(tester, const Key('shared-161-emergency-lock-confirm-primary'));
      await tap(tester, const Key('shared-161-emergency-lock-primary'));
      expect(gateway.calls, isEmpty);
      expect(
        session.actionComplete(
          session.actionId(161, 'emergency-lock', 'primary'),
        ),
        isFalse,
      );
    });
  }

  testWidgets(
    'universal profile and shared dock reach every shared owner and return',
    (tester) async {
      await mount(tester, route: '/app/social');
      await tap(tester, const Key('open-profile'));
      await tap(tester, const Key('profile-workspace'));
      expect(location(tester), '/app/account/workspaces');
      await tap(tester, const Key('shared-dock-activity'));
      expect(location(tester), '/app/activity');
      await tap(tester, const Key('shared-dock-settings'));
      expect(location(tester), '/app/account/workspaces/preferences');
      await tap(tester, const Key('shared-dock-workspaces'));
      expect(location(tester), '/app/account/workspaces');
      await tap(tester, const Key('shared-dock-chat'));
      expect(location(tester), contains('/app/chat/inbox'));
    },
  );
}

String _slug(String value) => value
    .toLowerCase()
    .replaceAll('&', 'and')
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp('(^-+|-+\$)'), '');
