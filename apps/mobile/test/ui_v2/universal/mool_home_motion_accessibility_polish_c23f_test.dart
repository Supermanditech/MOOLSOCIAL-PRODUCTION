import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';
import 'package:moolsocial/ui_v2/universal/personal_mool_root_v2.dart';

void main() {
  test('C23F freezes bounded Home motion tokens', () {
    expect(
      MoolHomeHubTokens.arrivalDuration,
      const Duration(milliseconds: 220),
    );
    expect(MoolHomeHubTokens.pressDuration, const Duration(milliseconds: 100));
  });

  testWidgets('C23F Home keeps Back and reachable header Chat continuity', (
    tester,
  ) async {
    var backTaps = 0;
    var chatTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PersonalMoolRootV2(
          onBack: () => backTaps++,
          onOpenAction: (_) {},
          onOpenChat: () => chatTaps++,
          onOpenRoute: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chat = find.byKey(const Key('mool-home-chat'));
    expect(chat, findsOneWidget);
    expect(tester.getSize(chat).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(chat).height, greaterThanOrEqualTo(44));
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Open Chat'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(chat);
    await tester.pump();
    expect(chatTaps, 1);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(backTaps, 1);
  });

  testWidgets('C24B all Home family and direct actions expose tap semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PersonalMoolRootV2(
          onBack: () {},
          onOpenAction: (_) {},
          onOpenChat: () {},
          onOpenRoute: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final family in moolActionFamilies) {
      final familyControl = find.byKey(
        ValueKey('mool-home-family-${family.id}'),
      );
      expect(familyControl, findsOneWidget, reason: family.label);
      expect(
        tester
            .getSemantics(familyControl)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
        reason: family.label,
      );
      await tester.tap(find.byKey(ValueKey('mool-home-family-${family.id}')));
      await tester.pumpAndSettle();
      for (final action in family.actions) {
        final actionControl = find.byKey(
          ValueKey('mool-home-${family.id}-${action.id}'),
        );
        expect(actionControl, findsOneWidget, reason: action.label);
        expect(
          tester
              .getSemantics(actionControl)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
          reason: action.label,
        );
      }
    }
  });

  testWidgets('C23F reduced motion settles Home and launcher immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          disableAnimations: true,
          accessibleNavigation: true,
        ),
        child: MaterialApp(
          home: PersonalMoolRootV2(
            onBack: () {},
            onOpenAction: (_) {},
            onOpenChat: () {},
            onOpenRoute: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final homeFade = tester.widget<FadeTransition>(
      find.byKey(const Key('mool-home-route-motion')),
    );
    expect(homeFade.opacity.value, 1);

    expect(
      MoolHomeHubTokens.accessibleDuration(
        tester.element(find.byKey(const Key('personal-mool-root-v2'))),
        MoolHomeHubTokens.pressDuration,
      ),
      Duration.zero,
    );
  });

  testWidgets('C23F large text stacks without a horizontal action scroller', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: MaterialApp(
          home: PersonalMoolRootV2(
            onBack: () {},
            onOpenAction: (_) {},
            onOpenChat: () {},
            onOpenRoute: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MoolHomeHubFamilyRow), findsNothing);
    for (final family in moolActionFamilies) {
      expect(
        find.byKey(ValueKey('mool-home-family-${family.id}')),
        findsOneWidget,
      );
    }
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('mool-home-social-shorts')))
          .height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('C23F launcher opens the connected chooser in one tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MoolGlobalNavigationV2(
            activeId: 'social',
            onOpenMool: () => taps++,
            onOpenAction: (_) {},
            onOpenChat: () {},
          ),
        ),
      ),
    );

    final launcher = find.byKey(const Key('mool-home-launcher'));
    final gesture = await tester.startGesture(tester.getCenter(launcher));
    await tester.pump(MoolHomeHubTokens.pressDuration);
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const Key('mool-home-launcher-press-motion')),
          )
          .scale,
      .975,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
  });
}
