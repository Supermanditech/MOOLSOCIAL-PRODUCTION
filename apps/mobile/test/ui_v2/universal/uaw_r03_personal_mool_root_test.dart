import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/universal/personal_mool_root_v2.dart';

void main() {
  Widget rootHarness({
    Size size = const Size(390, 844),
    double textScale = 1,
    bool reduceMotion = false,
    ValueChanged<PersonalMoolActionSpec>? onAction,
    ValueChanged<String>? onRoute,
    VoidCallback? onChat,
    VoidCallback? onBack,
    String? areaLabel,
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
        child: PersonalMoolRootV2(
          onBack: onBack ?? () {},
          onOpenAction: onAction ?? (_) {},
          onOpenRoute: onRoute,
          onOpenChat: onChat ?? () {},
          areaLabel: areaLabel,
        ),
      ),
    );
  }

  test('runtime root projection matches C25 and retains R03 boundaries', () {
    final historicalContractFile = File.fromUri(
      Directory.current.uri.resolve(
        '../../config/mvp-personal-mool-root-interaction-v1.json',
      ),
    );
    final historicalContract =
        jsonDecode(historicalContractFile.readAsStringSync()) as Map;
    final currentContractFile = File.fromUri(
      Directory.current.uri.resolve(
        '../../config/mvp-personal-domain-navigation-projection-c25.json',
      ),
    );
    final currentContract =
        jsonDecode(currentContractFile.readAsStringSync()) as Map;
    final domains = (currentContract['domains'] as List).cast<Map>();

    expect(
      personalMoolRootActions
          .map((action) => [action.id, action.label, action.route])
          .toList(),
      domains
          .map(
            (domain) => [domain['id'], domain['label'], domain['defaultRoute']],
          )
          .toList(),
    );
    expect(historicalContract['prohibitedVisibleActions'], contains('pay'));
    expect(historicalContract['globalActions'], hasLength(1));
    expect(
      historicalContract['authorityBoundary']['localCapabilityGrant'],
      isFalse,
    );
  });

  test('Buy permits only the exact Mool return route', () {
    final session = JourneySession();
    addTearDown(session.dispose);

    expect(session.buyExitRoute(requestedRoute: '/app/mool'), '/app/mool');
    expect(
      session.buyExitRoute(requestedRoute: '/app/eat'),
      '/app/mool?from=buy',
    );
  });

  testWidgets('durable Mool Home exposes six families and header Chat', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(rootHarness());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
    expect(find.byKey(const Key('mool-home-dashboard')), findsOneWidget);
    expect(find.byKey(const Key('mool-home-area')), findsNothing);
    for (final family in const [
      'social',
      'buy',
      'eat',
      'ride',
      'book',
      'work',
    ]) {
      expect(find.byKey(ValueKey('mool-home-family-$family')), findsOneWidget);
    }
    expect(find.byKey(const Key('mool-home-chat')), findsOneWidget);
    expect(find.bySemanticsLabel('Open Chat'), findsOneWidget);
    expect(find.byKey(const Key('moolsocial-global-navigation')), findsNothing);
    expect(find.text('Pay'), findsNothing);
    expect(find.text('Tiffin'), findsNothing);
    expect(find.text('Get It Done'), findsNothing);
    expect(find.text('Where do you want to go?'), findsNothing);
    expect(find.text('Jump anywhere in one tap'), findsNothing);
    semantics.dispose();
  });

  testWidgets(
    'each family emits its exact route once and Chat remains one tap',
    (tester) async {
      final opened = <String>[];
      var chatTaps = 0;
      await tester.pumpWidget(
        rootHarness(onRoute: opened.add, onChat: () => chatTaps += 1),
      );
      await tester.pumpAndSettle();

      for (final action in personalMoolRootActions) {
        final target = find.byKey(ValueKey('mool-home-family-${action.id}'));
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(opened.last, action.route);
        expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('mool-home-chat')));
      await tester.pump();

      expect(opened, personalMoolRootActions.map((action) => action.route));
      expect(chatTaps, 1);
    },
  );

  testWidgets('Home has no visible Back and platform Back remains exact', (
    tester,
  ) async {
    var backTaps = 0;
    await tester.pumpWidget(rootHarness(onBack: () => backTaps += 1));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mool-root-back')), findsNothing);
    expect(find.bySemanticsLabel('Back'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(backTaps, 1);
  });

  testWidgets('reduced motion renders fixed Home immediately', (tester) async {
    await tester.pumpWidget(rootHarness(reduceMotion: true));
    await tester.pump();

    final homeFade = tester.widget<FadeTransition>(
      find.byKey(const Key('mool-home-route-motion')),
    );
    expect(homeFade.opacity.value, 1);
  });

  for (final viewport in const [
    (size: Size(320, 568), textScale: 1.4),
    (size: Size(390, 844), textScale: 1.0),
    (size: Size(430, 932), textScale: 1.3),
  ]) {
    testWidgets(
      'root fits ${viewport.size.width.toInt()}x${viewport.size.height.toInt()}',
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
        expect(find.byKey(const Key('mool-home-dashboard')), findsOneWidget);
        expect(
          find.byKey(const Key('mool-home-family-social')),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('saved area is not duplicated into fixed Home chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      rootHarness(areaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khema-Ka-Kuwa, Jodhpur, Rajasthan'), findsNothing);
    expect(find.byKey(const Key('mool-home-family-social')), findsOneWidget);
    expect(find.byKey(const Key('mool-home-continue')), findsNothing);
    expect(find.textContaining('Continue '), findsNothing);
    expect(find.byKey(const Key('mool-root-back')), findsNothing);
  });

  testWidgets('existing app route opens native Mool root and restores it', (
    tester,
  ) async {
    final session = JourneySession(
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
    addTearDown(session.dispose);
    await session.start();

    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: '/app/mool'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mool-home-family-buy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
  });
}
