import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/social/screen04_universal_components.dart';

void main() {
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

  test(
    'shared live dock matches the locked Personal MVP projection exactly',
    () {
      final projection =
          jsonDecode(
                File.fromUri(
                  Directory.current.uri.resolve(
                    '../../config/mvp-personal-action-projection-v1.json',
                  ),
                ).readAsStringSync(),
              )
              as Map;
      final expectedWorlds = (projection['mainActions'] as List).cast<Map>();

      expect(
        screen04Worlds
            .map(
              (world) => [
                world.id,
                world.label,
                world.choices
                    .map((choice) => [choice.id, choice.label])
                    .toList(),
              ],
            )
            .toList(),
        expectedWorlds
            .map(
              (world) => [
                world['id'],
                world['label'],
                (world['subActions'] as List)
                    .cast<Map>()
                    .map((choice) => [choice['id'], choice['label']])
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
    },
  );

  testWidgets('Social Mool opens the stable hub and Back restores its rail', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = signedInSession();
    addTearDown(session.dispose);
    await session.start();

    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: '/app/social'),
    );
    await tester.pumpAndSettle();

    for (final id in const ['shorts', 'videos', 'feed', 'create']) {
      expect(find.byKey(Key('screen04-rail-$id')), findsOneWidget);
    }
    for (final id in const ['social', 'buy', 'eat', 'ride', 'book', 'work']) {
      expect(find.byKey(Key('screen04-rail-$id')), findsNothing);
    }
    expect(
      tester.getSemantics(find.byKey(const Key('mool-root-selected'))).label,
      allOf(contains('Open Mool home'), contains('Mool')),
    );

    await tester.tap(find.byKey(const Key('mool-root-selected')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
    expect(find.byKey(const Key('screen04-universal-v2')), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    for (final id in const ['shorts', 'videos', 'feed', 'create']) {
      expect(find.byKey(Key('screen04-rail-$id')), findsOneWidget);
    }
    expect(find.byKey(const Key('mool-root-chat')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const Key('screen04-rail-shorts')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final subAction in const ['shorts', 'videos', 'feed', 'create']) {
    testWidgets('Social $subAction survives Mool hub and exact Back', (
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

      await tester.pumpWidget(
        MoolSocialApp(
          session: session,
          initialLocation: '/app/social?sub=$subAction',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.byKey(Key('screen04-rail-$subAction')))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );

      await tester.tap(find.byKey(const Key('mool-root-selected')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byKey(Key('screen04-rail-$subAction')))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
