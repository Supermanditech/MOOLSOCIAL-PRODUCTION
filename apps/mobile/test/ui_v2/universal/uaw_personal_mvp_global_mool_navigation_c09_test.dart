import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/ui_v2/universal/personal_mool_root_v2.dart';

void main() {
  Widget harness({
    Size size = const Size(390, 844),
    double textScale = 1,
    bool reduceMotion = false,
    String? areaLabel = 'Jodhpur, Rajasthan',
    VoidCallback? onBack,
    ValueChanged<PersonalMoolActionSpec>? onAction,
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
          onOpenChat: () {},
          areaLabel: areaLabel,
        ),
      ),
    );
  }

  test('C09 freezes first-class Home, motion and overflow outcomes', () {
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

    expect(ledger['schemaVersion'], 3);
    expect(
      ledger['ticketId'],
      'UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-'
      'C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION',
    );
    final outcome = ledger['productionOutcome'] as Map;
    expect(outcome['moolDestination'], 'first_class_durable_mool_home');
    expect(
      outcome['moolBody'],
      'truthful_home_content_without_origin_return_sheet',
    );
    expect(outcome['overflow'], 'persistent_position_and_next_action_cue');
    expect(outcome['motion'], contains('reduced_motion'));
  });

  testWidgets('selected Home is visibly first-class and retap is inert', (
    tester,
  ) async {
    final platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
    expect(find.byKey(const Key('mool-root-back')), findsNothing);
    expect(find.byKey(const Key('mool-home-continue')), findsNothing);
    expect(find.textContaining('Continue '), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Mool Home, current')), findsOneWidget);
    expect(find.byKey(const Key('mool-home-primary-actions')), findsOneWidget);
    expect(find.text('Your area'), findsOneWidget);
    expect(find.text('Jodhpur, Rajasthan'), findsOneWidget);
    expect(
      find.text('See nearby options based on your saved area.'),
      findsOneWidget,
    );
    expect(find.text('Everything you need'), findsOneWidget);
    expect(
      find.text(
        'Connect, shop, order food, book rides and services, or find work—all in one place.',
      ),
      findsOneWidget,
    );
    expect(find.text('Swipe to explore more'), findsOneWidget);
    for (final forbidden in [
      'main rail',
      'navigation available',
      'without inventing',
      'stay fixed',
      'real area context',
      'scrollable main actions',
    ]) {
      expect(
        find.textContaining(forbidden, findRichText: true),
        findsNothing,
        reason: 'internal copy must stay out of visible text: $forbidden',
      );
      expect(
        find.bySemanticsLabel(RegExp(forbidden, caseSensitive: false)),
        findsNothing,
        reason: 'internal copy must stay out of semantics: $forbidden',
      );
    }

    await tester.tap(find.byKey(const Key('mool-root-selected')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
    expect(
      platformCalls.where((call) => call.method == 'HapticFeedback.vibrate'),
      isEmpty,
    );
  });

  testWidgets(
    'missing area uses customer wording without engineering rationale',
    (tester) async {
      await tester.pumpWidget(harness(areaLabel: null));
      await tester.pumpAndSettle();

      expect(find.text('Your area'), findsOneWidget);
      expect(find.text('Add your area'), findsOneWidget);
      expect(
        find.text('Set your area in Account to see what is available nearby.'),
        findsOneWidget,
      );
      expect(find.textContaining('invent'), findsNothing);
      expect(find.textContaining('navigation'), findsNothing);
      expect(find.textContaining('rail'), findsNothing);
    },
  );

  testWidgets('untouched compact rail announces and shows overflow', (
    tester,
  ) async {
    const size = Size(320, 568);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness(size: size, textScale: 1.4));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        'More MoolSocial options. Swipe horizontally to explore all 6.',
      ),
      findsOneWidget,
    );
    final forwardCue = tester.widget<AnimatedOpacity>(
      find.byKey(const Key('mool-main-rail-overflow-cue')),
    );
    expect(forwardCue.opacity, 1);
    expect(find.byKey(const Key('mool-action-social')), findsOneWidget);
    expect(find.byKey(const Key('mool-action-work')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('mool-root-main-actions')),
      const Offset(-240, 0),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getCenter(find.byKey(const Key('mool-action-work'))).dx,
      inInclusiveRange(0, size.width),
    );
  });

  testWidgets(
    'route arrival is finite and reduced motion settles immediately',
    (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 80));
      final moving = tester.widget<SlideTransition>(
        find
            .descendant(
              of: find.byKey(const Key('mool-home-route-motion')),
              matching: find.byType(SlideTransition),
            )
            .first,
      );
      expect(moving.position.value.dx, lessThanOrEqualTo(0));
      await tester.pumpAndSettle();
      expect(moving.position.value, Offset.zero);

      await tester.pumpWidget(harness(reduceMotion: true));
      await tester.pump();
      final settled = tester.widget<SlideTransition>(
        find
            .descendant(
              of: find.byKey(const Key('mool-home-route-motion')),
              matching: find.byType(SlideTransition),
            )
            .first,
      );
      expect(settled.position.value, Offset.zero);
    },
  );
}
