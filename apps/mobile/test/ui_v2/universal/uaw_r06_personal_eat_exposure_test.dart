import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/universal/mvp_action_choice_root_v2.dart';

void main() {
  Widget rootHarness({
    Size size = const Size(390, 844),
    double textScale = 1,
    bool reduceMotion = false,
    ValueChanged<MvpActionChoiceSpec>? onAction,
    VoidCallback? onBack,
    VoidCallback? onMool,
    VoidCallback? onChat,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
          accessibleNavigation: reduceMotion,
        ),
        child: MvpActionChoiceRootV2(
          sectionLabel: 'Eat',
          headline: 'What would you like?',
          supportingText: 'Order now or plan a table in one tap.',
          actions: personalEatActionChoices,
          onBack: onBack ?? () {},
          onOpenAction: onAction ?? (_) {},
          onOpenMainAction: (_) {},
          onOpenMool: onMool ?? () {},
          onOpenChat: onChat ?? () {},
        ),
      ),
    );
  }

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

  test('runtime Eat choices match the versioned R06 contract', () {
    final contractFile = File.fromUri(
      Directory.current.uri.resolve(
        '../../config/mvp-personal-eat-exposure-interaction-v1.json',
      ),
    );
    final contract = jsonDecode(contractFile.readAsStringSync()) as Map;
    final actions = (contract['actions'] as List).cast<Map>();

    expect(
      personalEatActionChoices
          .map((action) => [action.id, action.label, action.route])
          .toList(),
      actions
          .map((action) => [action['id'], action['label'], action['route']])
          .toList(),
    );
    expect(contract['excludedActions'], ['tiffin']);
    expect(contract['presentation']['sharedConfigurationOwner'], isTrue);
    expect(contract['presentation']['arrivalDurationMs'], 240);
  });

  testWidgets('Eat exposes exactly Order Food and Book Table', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(rootHarness());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mvp-action-root-eat')), findsOneWidget);
    expect(
      find.byKey(const Key('mvp-action-choice-order-food')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mvp-action-choice-book-table')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Open Order Food'), findsOneWidget);
    expect(find.bySemanticsLabel('Open Book Table'), findsOneWidget);
    expect(find.text('Tiffin'), findsNothing);
    expect(find.text('Pay'), findsNothing);
    expect(find.text('Get It Done'), findsNothing);
    semantics.dispose();
  });

  testWidgets('each Eat choice completes through one tap', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(
      rootHarness(onAction: (action) => opened.add(action.route)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mvp-action-choice-order-food')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('mvp-action-choice-book-table')));
    await tester.pump();

    expect(opened, ['/app/eat/home', '/app/eat/table']);
  });

  testWidgets(
    'system Back and embedded switcher outside dismissal are deterministic',
    (tester) async {
      var backTaps = 0;
      var moolTaps = 0;
      var chatTaps = 0;
      await tester.pumpWidget(
        rootHarness(
          onBack: () => backTaps += 1,
          onMool: () => moolTaps += 1,
          onChat: () => chatTaps += 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mvp-action-eat-back')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.tap(find.byKey(const Key('mool-home-launcher')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(350, 100));
      await tester.pumpAndSettle();

      expect(backTaps, 1);
      expect(moolTaps, 0);
      expect(chatTaps, 0);
      expect(find.byKey(const Key('mvp-action-root-eat')), findsOneWidget);
    },
  );

  testWidgets('reduced motion renders every Eat choice immediately', (
    tester,
  ) async {
    await tester.pumpWidget(rootHarness(reduceMotion: true));
    await tester.pump();

    for (final action in personalEatActionChoices) {
      final opacity = tester.widget<Opacity>(
        find.byKey(Key('mvp-action-arrival-${action.id}')),
      );
      expect(opacity.opacity, 1);
    }
  });

  for (final viewport in const [
    (size: Size(320, 568), textScale: 1.4),
    (size: Size(390, 844), textScale: 1.0),
    (size: Size(430, 932), textScale: 1.3),
  ]) {
    testWidgets(
      'Eat root fits ${viewport.size.width.toInt()}x${viewport.size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = viewport.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          rootHarness(size: viewport.size, textScale: viewport.textScale),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('mvp-action-eat-list')), findsOneWidget);
        expect(find.byKey(const Key('mool-home-launcher')), findsOneWidget);
      },
    );
  }

  testWidgets(
    'production Eat root lands on Order Food and returns from Table',
    (tester) async {
      final session = signedInSession();
      addTearDown(session.dispose);
      await session.start();

      await tester.pumpWidget(
        MoolSocialApp(session: session, initialLocation: '/app/eat'),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('moolsocial-eat-translucent-subaction-family-rail'),
        ),
        findsNothing,
      );
      expect(find.byKey(const Key('eat-local-navigation')), findsOneWidget);
      expect(find.byKey(const Key('eat-local-order')), findsOneWidget);
      expect(find.byKey(const Key('eat-local-table')), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      expect(find.byKey(const Key('mvp-action-root-eat')), findsNothing);
      expect(find.text('Order Food'), findsWidgets);
      expect(find.byKey(const Key('eat-local-tiffin')), findsNothing);
      expect(find.textContaining('tiffin', findRichText: true), findsNothing);

      await tester.tap(find.byKey(const Key('eat-local-table')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eat-table-screen')), findsOneWidget);
      expect(find.text('Book Table'), findsWidgets);

      expect(find.byKey(const Key('eat-back')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);
      expect(find.byKey(const Key('eat-local-order')), findsOneWidget);
      expect(find.byKey(const Key('mvp-action-root-eat')), findsNothing);
    },
  );

  for (final destination in const [
    (route: '/app/eat/home', ownerKey: Key('eat-home-screen')),
    (route: '/app/eat/table', ownerKey: Key('eat-table-screen')),
  ]) {
    testWidgets(
      'direct ${destination.route} exposes its owner and connected launcher',
      (tester) async {
        final session = signedInSession();
        addTearDown(session.dispose);
        await session.start();

        await tester.pumpWidget(
          MoolSocialApp(session: session, initialLocation: destination.route),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(destination.ownerKey), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey('moolsocial-eat-translucent-subaction-family-rail'),
          ),
          findsNothing,
        );
        expect(find.byKey(const Key('eat-local-navigation')), findsOneWidget);
        expect(find.byKey(const Key('eat-local-order')), findsOneWidget);
        expect(find.byKey(const Key('eat-local-table')), findsOneWidget);
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
        expect(find.byKey(const Key('mvp-action-root-eat')), findsNothing);
      },
    );
  }

  testWidgets('Eat connected chooser Back restores the exact default owner', (
    tester,
  ) async {
    final session = signedInSession();
    addTearDown(session.dispose);
    await session.start();

    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: '/app/eat'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);
    expect(find.byKey(const Key('eat-local-order')), findsOneWidget);
  });
}
