import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';

const _families = <_FamilySpec>[
  _FamilySpec('social', MoolLocalNavigationSurfaceTone.media, [
    ('shorts', 'Shorts'),
    ('videos', 'Videos'),
    ('feed', 'Feed'),
    ('create', 'Create'),
  ]),
  _FamilySpec('buy', MoolLocalNavigationSurfaceTone.light, [
    ('shop', 'Shop'),
    ('wholesale', 'Wholesale'),
    ('medicine', 'Medicine'),
    ('orders', 'Orders'),
  ]),
  _FamilySpec('eat', MoolLocalNavigationSurfaceTone.light, [
    ('order', 'Order Food'),
    ('table', 'Book Table'),
  ]),
  _FamilySpec('ride', MoolLocalNavigationSurfaceTone.light, [
    ('bike', 'Bike'),
    ('auto', 'Auto'),
    ('cab', 'Cab'),
  ]),
  _FamilySpec('book', MoolLocalNavigationSurfaceTone.light, [
    ('doctor', 'Doctor'),
    ('salon', 'Salon'),
  ]),
  _FamilySpec('work', MoolLocalNavigationSurfaceTone.light, [
    ('earn', 'Earn Today'),
    ('workspace', 'Workspace'),
  ]),
];

void main() {
  final selectedStates = [
    for (final family in _families)
      for (var index = 0; index < family.actions.length; index++)
        (family: family, selectedIndex: index),
  ];

  test('matrix owns exactly the 17 founder-approved selected states', () {
    expect(selectedStates, hasLength(17));
    expect(
      selectedStates
          .map(
            (state) =>
                '${state.family.id}:${state.family.actions[state.selectedIndex].$1}',
          )
          .toSet(),
      hasLength(17),
    );
  });

  for (final state in selectedStates) {
    final family = state.family;
    final selectedAction = family.actions[state.selectedIndex];
    testWidgets(
      '${family.id}/${selectedAction.$1} is professional selected glass',
      (tester) async {
        var opens = 0;
        await _mount(
          tester,
          family: family,
          selectedIndex: state.selectedIndex,
          onOpen: () => opens += 1,
        );

        final rail = find.byKey(Key('matrix-${family.id}-rail'));
        final cluster = find.byKey(
          const Key('moolsocial-local-navigation-compact-cluster'),
        );
        expect(
          tester.getSize(rail).height,
          MoolLocalNavigationTokens.railHeight,
        );
        expect(
          tester.getSize(cluster).width,
          MoolLocalNavigationTokens.clusterWidth(320, family.actions.length),
        );
        expect(
          tester.getRect(cluster).center.dx,
          tester.getRect(rail).center.dx,
        );
        expect(
          find.descendant(of: rail, matching: find.byType(BackdropFilter)),
          findsNWidgets(family.actions.length),
        );
        expect(
          find.descendant(of: rail, matching: find.byType(Scrollable)),
          findsNothing,
        );
        expect(
          find.descendant(of: rail, matching: find.byType(Expanded)),
          findsNothing,
        );

        for (var index = 0; index < family.actions.length; index++) {
          final action = family.actions[index];
          final actionFinder = find.byKey(
            Key('matrix-${family.id}-${action.$1}'),
          );
          expect(tester.getSize(actionFinder).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(actionFinder).height, greaterThanOrEqualTo(48));
          final label = find.descendant(
            of: rail,
            matching: find.text(action.$2),
          );
          expect(label, findsOneWidget);
          final text = tester.widget<Text>(label);
          expect(text.maxLines, 1);
          expect(text.overflow, isNull);
          expect(text.style?.fontSize, MoolLocalNavigationTokens.labelFontSize);
          expect(
            text.style?.fontWeight,
            MoolLocalNavigationTokens.labelFontWeight,
          );
          expect(
            text.style?.color,
            MoolLocalNavigationTokens.foreground(family.tone),
          );
          expect(
            find.ancestor(of: label, matching: find.byType(FittedBox)),
            findsOneWidget,
          );

          final glass = tester.widget<AnimatedContainer>(
            find.byKey(Key('moolsocial-local-${action.$1}-glass-control')),
          );
          final decoration = glass.decoration! as BoxDecoration;
          final gradient = decoration.gradient! as LinearGradient;
          expect(decoration.color, isNull);
          expect(
            gradient,
            MoolLocalNavigationTokens.glassGradient(
              tone: family.tone,
              selected: index == state.selectedIndex,
              pressed: false,
            ),
          );
          final background = family.tone == MoolLocalNavigationSurfaceTone.media
              ? Colors.black
              : Colors.white;
          for (final stop in gradient.colors) {
            expect(stop.a, lessThan(1));
            expect(
              _contrastRatio(
                MoolLocalNavigationTokens.foreground(family.tone),
                Color.alphaBlend(stop, background),
              ),
              greaterThanOrEqualTo(4.5),
            );
          }
        }

        final selectedFinder = find.byKey(
          Key('matrix-${family.id}-${selectedAction.$1}'),
        );
        final selectedNode = tester.getSemantics(selectedFinder);
        expect(selectedNode.flagsCollection.isSelected, Tristate.isTrue);
        expect(
          selectedNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isFalse,
        );
        final selectedIndicator = tester.widget<AnimatedContainer>(
          find.byKey(
            Key('moolsocial-local-${selectedAction.$1}-selected-indicator'),
          ),
        );
        final selectedIndicatorSize = tester.getSize(
          find.byKey(
            Key('moolsocial-local-${selectedAction.$1}-selected-indicator'),
          ),
        );
        expect(
          selectedIndicatorSize.width,
          MoolLocalNavigationTokens.selectedIndicatorWidth,
        );
        expect(
          selectedIndicatorSize.height,
          MoolLocalNavigationTokens.selectedIndicatorHeight,
        );
        expect(selectedIndicator.duration, MoolMotion.quick);

        if (family.actions.length > 1) {
          final availableIndex = state.selectedIndex == 0 ? 1 : 0;
          final available = family.actions[availableIndex];
          final availableFinder = find.byKey(
            Key('matrix-${family.id}-${available.$1}'),
          );
          final availableNode = tester.getSemantics(availableFinder);
          expect(availableNode.flagsCollection.isSelected, Tristate.isFalse);
          expect(
            availableNode.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
          await tester.tap(availableFinder);
          await tester.pump();
          expect(opens, 1);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('all 17 selected states settle immediately with reduced motion', (
    tester,
  ) async {
    for (final state in selectedStates) {
      final family = state.family;
      final selected = family.actions[state.selectedIndex];
      await _mount(
        tester,
        family: family,
        selectedIndex: state.selectedIndex,
        reducedMotion: true,
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(Key('moolsocial-local-${selected.$1}-glass-control')),
            )
            .duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(
                Key('moolsocial-local-${selected.$1}-selected-indicator'),
              ),
            )
            .duration,
        Duration.zero,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${family.id}/${selected.$1}',
      );
    }
  });
}

Future<void> _mount(
  WidgetTester tester, {
  required _FamilySpec family,
  required int selectedIndex,
  bool reducedMotion = false,
  VoidCallback? onOpen,
}) async {
  await tester.binding.setSurfaceSize(const Size(320, 180));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final selectedId = family.actions[selectedIndex].$1;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 180),
          textScaler: const TextScaler.linear(2),
          disableAnimations: reducedMotion,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: family.tone == MoolLocalNavigationSurfaceTone.media
                  ? const [Color(0xFF070914), Color(0xFF4A175C)]
                  : const [Color(0xFFFFFFFF), Color(0xFFE5EBF4)],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: MoolLocalNavigationRail(
                key: Key('matrix-${family.id}-rail'),
                familyId: family.id,
                semanticLabel: '${family.id} choices',
                activeId: selectedId,
                surfaceTone: family.tone,
                actions: [
                  for (final action in family.actions)
                    MoolLocalNavigationAction(
                      keyName: 'matrix-${family.id}-${action.$1}',
                      id: action.$1,
                      label: action.$2,
                      icon: Icons.circle_outlined,
                      onPressed: action.$1 == selectedId ? null : onOpen,
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

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final light = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final dark = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (light + .05) / (dark + .05);
}

class _FamilySpec {
  const _FamilySpec(this.id, this.tone, this.actions);

  final String id;
  final MoolLocalNavigationSurfaceTone tone;
  final List<(String, String)> actions;
}
