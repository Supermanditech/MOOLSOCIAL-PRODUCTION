import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/social/screen04_universal_components.dart';
import 'package:moolsocial/ui_v2/universal/personal_mool_root_v2.dart';

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
    'all live projection owners expose the C25 six plus 18 action words',
    () {
      final projectionFile = File.fromUri(
        Directory.current.uri.resolve(
          '../../config/mvp-personal-domain-navigation-projection-c25.json',
        ),
      );
      final projection = jsonDecode(projectionFile.readAsStringSync()) as Map;
      final mainActions = (projection['domains'] as List).cast<Map>();
      final expectedMain = [
        for (final action in mainActions) (action['id'], action['label']),
      ];
      final expectedSubActions = <String, List<(Object?, Object?)>>{
        for (final action in mainActions)
          action['id'] as String: [
            for (final subAction in (action['actions'] as List).cast<Map>())
              (subAction['id'], subAction['label']),
          ],
      };

      expect(
        personalMoolRootActions.map((action) => (action.id, action.label)),
        expectedMain,
      );
      expect(
        screen04Worlds.map((world) => (world.id, world.label)),
        expectedMain,
      );

      for (final world in screen04Worlds) {
        expect(
          world.choices.map((choice) => choice.label),
          expectedSubActions[world.id]!.map((choice) => choice.$2),
          reason:
              '${world.label} action words must match the locked projection',
        );
      }
      expect(
        expectedSubActions.values.expand((actions) => actions),
        hasLength(18),
      );
    },
  );

  for (final destination in const [
    (id: 'social', ownerKey: Key('screen04-universal-v2')),
    (id: 'buy', ownerKey: Key('buy-v2-screen')),
    (id: 'eat', ownerKey: Key('eat-home-screen')),
    (id: 'ride', ownerKey: Key('ride-booking-screen')),
    (id: 'book', ownerKey: Key('book-doctor')),
    (id: 'work', ownerKey: Key('work-earn-screen')),
  ]) {
    testWidgets('Home ${destination.id} opens its direct production owner', (
      tester,
    ) async {
      final journey = signedInSession();
      addTearDown(journey.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(session: journey, initialLocation: '/app/mool'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('mool-home-family-${destination.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(destination.ownerKey), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    });
  }

  for (final origin in const [
    (id: 'eat', route: '/app/eat/home', returnKey: Key('eat-home-screen')),
    (
      id: 'ride',
      route: '/app/ride/book?type=auto',
      returnKey: Key('ride-booking-screen'),
    ),
    (id: 'book', route: '/app/book/doctor', returnKey: Key('book-doctor')),
    (
      id: 'work',
      route: '/app/work/my-work',
      returnKey: Key('work-choose-screen'),
    ),
  ]) {
    testWidgets('${origin.id} connected chooser Back preserves its owner', (
      tester,
    ) async {
      final journey = signedInSession();
      addTearDown(journey.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(session: journey, initialLocation: origin.route),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      expect(find.byKey(origin.returnKey), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(origin.returnKey), findsOneWidget);
    });
  }

  testWidgets('Home header Chat returns to the exact Home owner', (
    tester,
  ) async {
    final journey = signedInSession();
    addTearDown(journey.dispose);
    await journey.start();

    await tester.pumpWidget(
      MoolSocialApp(session: journey, initialLocation: '/app/mool'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mool-home-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);

    expect(find.byKey(const Key('chat-back')), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
    expect(find.byKey(const Key('mool-home-dashboard')), findsOneWidget);
  });
}
