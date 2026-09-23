import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/shared/social_create_draft_repository.dart';
import 'package:moolsocial/ui_v2/social/screen04_universal_components.dart';

void main() {
  late SocialCreateDraftStateCache draftState;
  JourneySession signedInSession() {
    return JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'current',
          currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
  }

  test('shared live dock matches the locked Personal MVP projection exactly', () {
    final projection =
        jsonDecode(
              File.fromUri(
                Directory.current.uri.resolve(
                  '../../config/mvp-personal-action-projection-v1.json',
                ),
              ).readAsStringSync(),
            )
            as Map;
    // C25 moved Medicine to Care; C29E/C32I accepted Home-first Social.
    final successor =
        jsonDecode(
              File.fromUri(
                Directory.current.uri.resolve(
                  '../../config/mvp-personal-domain-navigation-projection-c25.json',
                ),
              ).readAsStringSync(),
            )
            as Map;
    final expectedWorlds = (successor['domains'] as List).cast<Map>();
    String compatibilityId(String id) => switch (id) {
      'order' => 'order-food',
      'table' => 'book-table',
      'earn' => 'earn-today',
      _ => id,
    };

    expect(
      screen04Worlds
          .map(
            (world) => [
              world.id,
              world.label,
              world.choices.map((choice) => [choice.id, choice.label]).toList(),
            ],
          )
          .toList(),
      expectedWorlds
          .map(
            (world) => [
              world['id'],
              world['label'],
              if (world['id'] == 'social')
                [
                  ['videos', 'Home'],
                  ['shorts', 'Shorts'],
                  ['create', 'Create'],
                  ['feed', 'Feed'],
                ]
              else
                (world['actions'] as List)
                    .cast<Map>()
                    .map(
                      (choice) => [
                        compatibilityId(choice['id'] as String),
                        choice['label'],
                      ],
                    )
                    .toList(),
            ],
          )
          .toList(),
    );

    final exposedIds = <String>{
      for (final world in screen04Worlds) world.id,
      for (final world in screen04Worlds)
        for (final choice in world.choices) choice.id,
    };
    final removedIds = (projection['removedActions'] as List).cast<Map>().map(
      (action) => action['id'],
    );
    expect(exposedIds.intersection(removedIds.toSet()), isEmpty);
    expect(
      (projection['globalActions'] as List).single,
      containsPair('id', 'chat'),
    );
  });

  testWidgets('Social Mool menu Back preserves the Home rail', (tester) async {
    final semantics = tester.ensureSemantics();
    final session = signedInSession();
    addTearDown(session.dispose);
    await session.start();
    draftState = SocialCreateDraftStateCache();

    await tester.pumpWidget(
      MoolSocialApp(
        createDraftStateCache: draftState,
        session: session,
        initialLocation: '/app/social',
      ),
    );
    await tester.pumpAndSettle();

    for (final id in const ['shorts', 'videos', 'feed', 'create']) {
      expect(find.byKey(Key('screen04-rail-$id')), findsOneWidget);
    }
    for (final id in const ['social', 'buy', 'eat', 'ride', 'book', 'work']) {
      expect(find.byKey(Key('screen04-rail-$id')), findsNothing);
    }
    final launcher = find.byKey(const Key('mool-compact-launcher'));
    expect(tester.getSize(launcher).height, greaterThanOrEqualTo(44));
    await tester.tap(launcher);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    for (final id in const ['shorts', 'videos', 'feed', 'create']) {
      expect(find.byKey(Key('screen04-rail-$id')), findsOneWidget);
    }
    expect(find.byKey(const Key('social-global-chat')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const Key('screen04-rail-videos')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final subAction in const ['shorts', 'videos', 'feed', 'create']) {
    testWidgets('Social $subAction survives connected menu and exact Back', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final session = signedInSession();
      addTearDown(session.dispose);
      await session.start();
      draftState = SocialCreateDraftStateCache();
      if (subAction == 'create') await _bindNavigationDraft(draftState);

      await tester.pumpWidget(
        MoolSocialApp(
          createDraftStateCache: draftState,
          session: session,
          initialLocation: '/app/social?sub=$subAction',
        ),
      );
      await tester.pumpAndSettle();
      if (subAction == 'create') {
        expect(
          find.byKey(const ValueKey('social-creator-gateway')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('screen04-context-tabs')), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('social-creator-gateway')),
          findsNothing,
        );
      }
      final retainedSubAction = subAction == 'create' ? 'feed' : subAction;
      expect(
        tester
            .getSemantics(find.byKey(Key('screen04-rail-$retainedSubAction')))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );

      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsNothing,
      );
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byKey(Key('screen04-rail-$retainedSubAction')))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      if (subAction == 'create') {
        await tester.tap(find.byKey(const Key('screen04-rail-create')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('social-creator-gateway')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('screen04-context-tabs')), findsNothing);
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}

Future<_NavigationDraftRepository> _bindNavigationDraft(
  SocialCreateDraftStateCache cache,
) async {
  final repository = _NavigationDraftRepository();
  final binding = cache.beginPrincipalBindingAttempt();
  await cache.configureDurability(repository, bindingAttempt: binding);
  addTearDown(() {
    cache.beginPrincipalBindingAttempt();
  });
  return repository;
}

final class _NavigationDraftRepository implements SocialCreateDraftRepository {
  SocialCreateDraftSnapshot? snapshot;
  bool failWrites = false;
  @override
  Future<SocialCreateDraftRead> read() async => SocialCreateDraftRead(
    freshness: snapshot == null
        ? SocialCreateDraftFreshness.missing
        : SocialCreateDraftFreshness.fresh,
    snapshot: snapshot,
  );
  @override
  Future<void> write(SocialCreateDraftSnapshot value) async {
    if (failWrites) throw StateError('Controlled draft write failure');
    snapshot = value;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}
