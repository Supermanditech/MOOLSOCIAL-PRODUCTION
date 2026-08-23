import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';

void main() {
  Future<void> mountRail(
    WidgetTester tester, {
    required int actionCount,
    int selectedIndex = 0,
    double width = 412,
    double textScale = 1,
    bool reducedMotion = false,
    MoolLocalNavigationSurfaceTone surfaceTone =
        MoolLocalNavigationSurfaceTone.light,
    ValueChanged<int>? onOpen,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 180),
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF4F6FB), Color(0xFFCCD8EC)],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: MoolLocalNavigationRail(
                  key: const Key('test-local-rail'),
                  familyId: surfaceTone == MoolLocalNavigationSurfaceTone.media
                      ? 'social'
                      : 'buy',
                  semanticLabel: 'Test choices',
                  activeId: 'action-$selectedIndex',
                  surfaceTone: surfaceTone,
                  actions: [
                    for (var index = 0; index < actionCount; index++)
                      MoolLocalNavigationAction(
                        keyName: 'test-action-$index',
                        id: 'action-$index',
                        label: switch (index) {
                          0 => 'Discover',
                          1 => 'Deals',
                          2 => 'Orders',
                          _ => 'Saved',
                        },
                        icon: Icons.circle_outlined,
                        onPressed: index == selectedIndex
                            ? null
                            : () => onOpen?.call(index),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final actionCount in const [2, 3, 4]) {
    testWidgets('$actionCount actions remain individual 48px glass controls', (
      tester,
    ) async {
      await mountRail(
        tester,
        actionCount: actionCount,
        selectedIndex: actionCount - 1,
      );

      final rail = find.byKey(const Key('test-local-rail'));
      final cluster = find.byKey(
        const Key('moolsocial-local-navigation-compact-cluster'),
      );
      expect(tester.getSize(rail).height, 52);
      expect(tester.getRect(cluster).center.dx, tester.getRect(rail).center.dx);
      expect(
        tester.getSize(cluster).width,
        MoolLocalNavigationTokens.clusterWidth(412, actionCount),
      );
      expect(
        find.descendant(of: rail, matching: find.byType(Scrollable)),
        findsNothing,
      );
      expect(
        find.descendant(of: rail, matching: find.byType(Expanded)),
        findsNothing,
      );
      expect(
        find.descendant(of: rail, matching: find.byType(BackdropFilter)),
        findsNWidgets(actionCount),
      );

      for (var index = 0; index < actionCount; index++) {
        final action = find.byKey(Key('test-action-$index'));
        expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        expect(
          find.byKey(Key('moolsocial-local-action-$index-glass-control')),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large system text stays legible without shrinking or clipping', (
    tester,
  ) async {
    await mountRail(
      tester,
      actionCount: 4,
      selectedIndex: 2,
      width: 320,
      textScale: 2,
    );

    expect(
      tester
          .getSize(
            find.byKey(
              const Key('moolsocial-local-navigation-compact-cluster'),
            ),
          )
          .width,
      MoolLocalNavigationTokens.clusterWidth(320, 4),
    );
    for (final label in const ['Discover', 'Deals', 'Orders', 'Saved']) {
      final text = find.text(label);
      expect(text, findsOneWidget);
      expect(
        tester.widget<Text>(text).style?.fontSize,
        MoolLocalNavigationTokens.labelFontSize,
      );
      expect(
        tester.widget<Text>(text).style?.fontWeight,
        MoolLocalNavigationTokens.labelFontWeight,
      );
      expect(
        find.ancestor(of: text, matching: find.byType(FittedBox)),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('light and media tones keep backgrounds visible and text clear', (
    tester,
  ) async {
    for (final tone in MoolLocalNavigationSurfaceTone.values) {
      await mountRail(
        tester,
        actionCount: 2,
        selectedIndex: 0,
        surfaceTone: tone,
      );
      final selected = tester.widget<AnimatedContainer>(
        find.byKey(const Key('moolsocial-local-action-0-glass-control')),
      );
      final available = tester.widget<AnimatedContainer>(
        find.byKey(const Key('moolsocial-local-action-1-glass-control')),
      );
      final selectedDecoration = selected.decoration! as BoxDecoration;
      final availableDecoration = available.decoration! as BoxDecoration;
      final selectedForeground =
          selected.foregroundDecoration! as BoxDecoration;
      final availableForeground =
          available.foregroundDecoration! as BoxDecoration;
      final availableGradient = availableDecoration.gradient! as LinearGradient;
      final selectedGradient = selectedDecoration.gradient! as LinearGradient;
      expect(availableDecoration.color, isNull);
      expect(selectedDecoration.color, isNull);
      expect(
        availableGradient,
        MoolLocalNavigationTokens.glassGradient(
          tone: tone,
          selected: false,
          pressed: false,
        ),
      );
      expect(
        selectedGradient,
        MoolLocalNavigationTokens.glassGradient(
          tone: tone,
          selected: true,
          pressed: false,
        ),
      );
      expect(
        selectedGradient.colors.first.a,
        greaterThan(availableGradient.colors.first.a),
      );
      expect(
        selectedForeground.border!.top.color,
        MoolLocalNavigationTokens.borderColor(
          tone: tone,
          selected: true,
          pressed: false,
        ),
      );
      expect(
        availableForeground.border!.top.color,
        MoolLocalNavigationTokens.borderColor(
          tone: tone,
          selected: false,
          pressed: false,
        ),
      );
      for (final stop in availableGradient.colors) {
        expect(stop.a, lessThan(1));
        expect(
          _contrastRatio(
            MoolLocalNavigationTokens.foreground(tone),
            Color.alphaBlend(
              stop,
              tone == MoolLocalNavigationSurfaceTone.light
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          greaterThan(4.5),
        );
      }
    }
  });

  testWidgets(
    'selected is inert and available press gives one finite response',
    (tester) async {
      var opens = 0;
      await mountRail(
        tester,
        actionCount: 3,
        selectedIndex: 0,
        onOpen: (_) => opens += 1,
      );

      final selectedNode = tester.getSemantics(
        find.byKey(const Key('test-action-0')),
      );
      expect(selectedNode.flagsCollection.isSelected, Tristate.isTrue);
      expect(
        selectedNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      final availableNode = tester.getSemantics(
        find.byKey(const Key('test-action-1')),
      );
      expect(availableNode.flagsCollection.isSelected, Tristate.isFalse);
      expect(
        availableNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('test-action-1'))),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const Key('moolsocial-local-action-1-pressed-scale')),
            )
            .scale,
        .975,
      );
      await gesture.up();
      await tester.pump();
      expect(opens, 1);
    },
  );

  testWidgets('reduced motion makes glass, selection and press immediate', (
    tester,
  ) async {
    await mountRail(
      tester,
      actionCount: 2,
      selectedIndex: 1,
      reducedMotion: true,
    );
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const Key('moolsocial-local-action-0-pressed-scale')),
          )
          .duration,
      Duration.zero,
    );
    for (final suffix in const [
      'selection',
      'glass-control',
      'selected-indicator',
    ]) {
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(Key('moolsocial-local-action-1-$suffix')),
            )
            .duration,
        Duration.zero,
      );
    }
  });

  test('all six families share two accessible brand selection signals', () {
    final signals = {
      for (final family in const [
        'social',
        'buy',
        'eat',
        'ride',
        'book',
        'work',
      ])
        family: MoolLocalNavigationTokens.selectionColorForFamily(family),
    };
    expect(signals['social'], MoolBrand.identityWhite);
    for (final family in const ['buy', 'eat', 'ride', 'book', 'work']) {
      expect(signals[family], MoolBrand.identityNavy);
    }
    expect(signals.values.toSet(), hasLength(2));
  });
}

double _contrastRatio(Color first, Color second) {
  final light = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final dark = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (light + .05) / (dark + .05);
}
