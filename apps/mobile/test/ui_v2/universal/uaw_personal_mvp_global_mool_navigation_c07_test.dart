import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/universal/personal_mool_root_v2.dart';

void main() {
  JourneySession signedInSession() => JourneySession(
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

  Future<void> pumpApp(
    WidgetTester tester,
    JourneySession journey,
    String location,
  ) async {
    await tester.pumpWidget(
      MoolSocialApp(session: journey, initialLocation: location),
    );
    await tester.pumpAndSettle();
  }

  test('C07 freezes ordered U01-U22 and the durable-home outcome', () {
    final ledger =
        jsonDecode(
              File.fromUri(
                Directory.current.uri.resolve(
                  '../../config/'
                  'mvp-personal-global-mool-navigation-scenario-ledger-v3.json',
                ),
              ).readAsStringSync(),
            )
            as Map;
    final outcome = ledger['productionOutcome'] as Map;
    final scenarios = (ledger['scenarios'] as List).cast<Map>();

    expect(ledger['status'], 'blocking_until_host_and_oppo_green');
    expect(outcome['moolDestination'], 'first_class_durable_mool_home');
    expect(outcome['moolRail'], [
      'mool',
      'social',
      'buy',
      'eat',
      'ride',
      'book',
      'work',
      'chat',
    ]);
    expect(
      scenarios.map((scenario) => scenario['id']),
      List.generate(
        22,
        (index) => 'U${(index + 1).toString().padLeft(2, '0')}',
      ),
    );
    for (final scenario in scenarios) {
      expect((scenario['forbiddenAlternatives'] as List), isNotEmpty);
      expect(scenario['hostAssertion'], isNotEmpty);
    }
  });

  test('C32U source freezes connected menu and fixed Mool Home owners', () {
    final source =
        [
              'lib/ui_v2/universal/personal_mool_root_v2.dart',
              'lib/ui_v2/universal/mool_global_navigation_v2.dart',
            ]
            .map((path) {
              return File.fromUri(
                Directory.current.uri.resolve(path),
              ).readAsStringSync();
            })
            .join('\n');

    for (final rejected in const [
      'Where do you want to go?',
      'Choose once. Move forward instantly.',
      'Jump anywhere in one tap',
      'mool-root-action-grid',
      '_MoolOrbit',
      '_MoolActionArrival',
      'mool-home-area',
      'mool-home-primary-actions',
      'mool-root-main-actions',
      'mool-root-selected',
    ]) {
      expect(source, isNot(contains(rejected)), reason: rejected);
    }
    for (final required in const [
      'mool-home-dashboard',
      "keyPrefix: 'mool-home'",
      'MoolMainDomainMenu(',
      'mool-compact-launcher',
      'MoolConnectedActionNavigator',
      'moolsocial-home-has-no-bottom-navigation',
    ]) {
      expect(source, contains(required), reason: required);
    }
  });

  testWidgets(
    'Social Feed Mool opens connected menu and Back restores Feed',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final journey = signedInSession();
      addTearDown(journey.dispose);
      await journey.start();
      await pumpApp(tester, journey, '/app/social?sub=feed');

      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      for (final family in moolActionFamilies) {
        expect(
          find.byKey(ValueKey('mool-navigator-family-${family.id}')),
          findsOneWidget,
        );
      }
      expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsNothing,
      );
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byKey(const Key('screen04-rail-feed')))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      semantics.dispose();
    },
  );

  testWidgets('direct Mool is a durable home with no invented origin', (
    tester,
  ) async {
    final journey = signedInSession();
    addTearDown(journey.dispose);
    await journey.start();
    await pumpApp(tester, journey, '/app/mool');

    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
    expect(find.byKey(const Key('mool-home-dashboard')), findsOneWidget);
    for (final family in moolActionFamilies) {
      expect(
        find.byKey(ValueKey('mool-home-family-${family.id}')),
        findsOneWidget,
      );
    }
    expect(find.byKey(const Key('mool-home-continue')), findsNothing);
    expect(find.text('Continue Social'), findsNothing);
    expect(find.byKey(const Key('mool-root-back')), findsNothing);
    expect(
      find.byKey(const Key('moolsocial-global-navigation')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('mool-home-family-buy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
    expect(find.byKey(const Key('mool-home-dashboard')), findsOneWidget);
  });

  testWidgets('compact fixed Home keeps all six families reachable', (
    tester,
  ) async {
    const size = Size(320, 568);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final opened = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(1.4),
          ),
          child: PersonalMoolRootV2(
            onBack: () {},
            onOpenAction: (_) {},
            onOpenChat: () {},
            onOpenRoute: opened.add,
            areaLabel: 'Jodhpur, Rajasthan',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mool-home-dashboard')), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    for (final family in moolActionFamilies) {
      final target = find.byKey(ValueKey('mool-home-family-${family.id}'));
      expect(target, findsOneWidget);
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(find.bySemanticsLabel('Open ${family.label}'), findsOneWidget);
      await tester.tap(target);
      await tester.pump();
    }

    expect(opened, moolActionFamilies.map((family) => family.route));
    expect(tester.takeException(), isNull);
  });
}
