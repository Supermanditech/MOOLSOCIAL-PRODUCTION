import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

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

  Future<void> scrollToClearBottomAndTap(
    WidgetTester tester,
    Finder finder,
  ) async {
    final verticalScrollable = find.descendant(
      of: find.byType(ListView),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: verticalScrollable.last,
    );
    await tester.pumpAndSettle();
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final rect = tester.getRect(finder);
    final clearBottom = viewportHeight - 132;
    if (rect.bottom > clearBottom) {
      await tester.drag(
        verticalScrollable.last,
        Offset(0, -(rect.bottom - clearBottom + 16)),
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test('C03 removes every Social-hosted Mool main-action mode', () {
    final contract =
        jsonDecode(
              File.fromUri(
                Directory.current.uri.resolve(
                  '../../config/'
                  'mvp-personal-global-mool-bottom-rail-navigation-fix1.json',
                ),
              ).readAsStringSync(),
            )
            as Map;
    final rules = contract['rules'] as Map;
    expect(rules['moolIsStableHub'], isTrue);
    expect(rules['moolMayAliasSocial'], isFalse);
    expect(rules['moolMayToggleMainActionRibbon'], isFalse);

    final socialSource = File.fromUri(
      Directory.current.uri.resolve('lib/ui_v2/social/social_v2_consumer.dart'),
    ).readAsStringSync();
    final railSource = File.fromUri(
      Directory.current.uri.resolve(
        'lib/ui_v2/social/screen04_universal_components.dart',
      ),
    ).readAsStringSync();
    for (final forbidden in const [
      'initialMoolOpen',
      '_moolOpen',
      'moolOpen',
      'onWorld',
      'screen04-world-ribbon',
    ]) {
      expect('$socialSource\n$railSource', isNot(contains(forbidden)));
    }
  });

  for (final subAction in const ['shorts', 'videos', 'feed', 'create']) {
    testWidgets('Social $subAction Mool hub Back preserves exact selection', (
      tester,
    ) async {
      final journey = signedInSession();
      addTearDown(journey.dispose);
      await journey.start();
      await pumpApp(tester, journey, '/app/social?sub=$subAction');

      final selected = find.byKey(Key('screen04-rail-$subAction'));
      expect(
        tester.getSemantics(selected).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      for (final mainAction in const [
        'social',
        'buy',
        'eat',
        'ride',
        'book',
        'work',
      ]) {
        expect(find.byKey(Key('screen04-rail-$mainAction')), findsNothing);
      }

      await tester.tap(find.byKey(const Key('mool-root-selected')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(
        tester.getSemantics(selected).flagsCollection.isSelected,
        Tristate.isTrue,
      );
    });
  }

  testWidgets('active Social video closes before Mool route history', (
    tester,
  ) async {
    final journey = signedInSession();
    addTearDown(journey.dispose);
    await journey.start();
    await pumpApp(tester, journey, '/app/social?sub=videos');
    final navigator = Navigator.of(
      tester.element(find.byKey(const Key('screen04-universal-v2'))),
    );

    final video = find.text('5-minute morning mobility');
    await scrollToClearBottomAndTap(tester, video);
    expect(find.byKey(const Key('screen04-video-watch')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
    expect(navigator.canPop(), isFalse);
    expect(
      tester
          .widget<PopScope<Object?>>(
            find.ancestor(
              of: find.byKey(const Key('screen04-universal-v2')),
              matching: find.byType(PopScope<Object?>),
            ),
          )
          .canPop,
      isTrue,
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('screen04-rail-videos')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await tester.tap(find.byKey(const Key('mool-root-selected')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
    expect(navigator.canPop(), isTrue);
    expect(
      tester
          .widget<PopScope<Object?>>(
            find.ancestor(
              of: find.byKey(const Key('personal-mool-root-v2')),
              matching: find.byType(PopScope<Object?>),
            ),
          )
          .canPop,
      isFalse,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final ownerAfterSystemBack = <String, Object>{
      'socialOwners': find
          .byKey(const Key('screen04-universal-v2'))
          .evaluate()
          .length,
      'moolOwners': find
          .byKey(const Key('personal-mool-root-v2'))
          .evaluate()
          .length,
      'canPop': navigator.canPop(),
    };
    expect(ownerAfterSystemBack, <String, Object>{
      'socialOwners': 1,
      'moolOwners': 0,
      'canPop': false,
    });
    expect(find.byKey(const Key('screen04-video-watch')), findsNothing);
    expect(
      tester
          .getSemantics(find.byKey(const Key('screen04-rail-videos')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('hub Social Mool Back Back follows exact route history', (
    tester,
  ) async {
    final journey = signedInSession();
    addTearDown(journey.dispose);
    await journey.start();
    await pumpApp(tester, journey, '/app/mool');

    await tester.tap(find.byKey(const Key('mool-action-social')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mool-root-selected')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
  });
}
