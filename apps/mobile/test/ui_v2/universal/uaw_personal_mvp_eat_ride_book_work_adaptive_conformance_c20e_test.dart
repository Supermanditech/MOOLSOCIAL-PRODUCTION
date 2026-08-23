import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/core/design/mool_theme.dart';

const _widths = [320.0, 360.0, 390.0, 412.0, 430.0];
const _textScales = [1.0, 1.3];

const _families = <_FamilySpec>[
  _FamilySpec('eat', [
    _ActionSpec('order', 'Order Food', Icons.restaurant_menu_rounded),
    _ActionSpec('table', 'Book Table', Icons.table_restaurant_outlined),
  ]),
  _FamilySpec('ride', [
    _ActionSpec('bike', 'Bike', Icons.two_wheeler_outlined),
    _ActionSpec('auto', 'Auto', Icons.electric_rickshaw_outlined),
    _ActionSpec('cab', 'Cab', Icons.local_taxi_outlined),
  ]),
  _FamilySpec('book', [
    _ActionSpec('doctor', 'Doctor', Icons.medical_services_outlined),
    _ActionSpec('salon', 'Salon', Icons.content_cut_rounded),
  ]),
  _FamilySpec('work', [
    _ActionSpec('earn', 'Earn Today', Icons.currency_rupee_rounded),
    _ActionSpec('workspace', 'Workspace', Icons.work_outline_rounded),
  ]),
];

void main() {
  test(
    'adaptive inventory owns four real families and nine selected states',
    () {
      expect(_families, hasLength(4));
      expect(
        {for (final family in _families) family.id: family.actions.length},
        {'eat': 2, 'ride': 3, 'book': 2, 'work': 2},
      );
      expect(_families.expand((family) => family.actions), hasLength(9));
      expect(MoolLocalNavigationTokens.clusterWidth(320, 2), 152);
      expect(MoolLocalNavigationTokens.clusterWidth(320, 3), 232);
      expect(MoolLocalNavigationTokens.clusterWidth(412, 2), 152);
      expect(MoolLocalNavigationTokens.clusterWidth(412, 3), 232);
      expect(MoolLocalNavigationTokens.destinationRailHeight, 58);
      expect(MoolLocalNavigationTokens.destinationMinimumFixedCellWidth, 44);
    },
  );

  for (final family in _families) {
    testWidgets(
      '${family.id} keeps ${family.actions.length} compact leading destination actions across widths and scales',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        for (final width in _widths) {
          for (final textScale in _textScales) {
            for (
              var selectedIndex = 0;
              selectedIndex < family.actions.length;
              selectedIndex += 1
            ) {
              await _mountFamily(
                tester,
                family: family,
                selectedIndex: selectedIndex,
                width: width,
                textScale: textScale,
              );
              _expectAdaptiveFamily(
                tester,
                family: family,
                selectedIndex: selectedIndex,
                width: width,
              );
            }
          }
        }
      },
    );
  }

  testWidgets(
    'all four families keep inert selection one-tap outcomes and immediate reduced motion',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final family in _families) {
        var opens = 0;
        await _mountFamily(
          tester,
          family: family,
          selectedIndex: 0,
          width: 320,
          textScale: 1.3,
          reducedMotion: true,
          onOpen: (_) => opens += 1,
        );

        final selected = family.actions.first;
        final selectedNode = tester.getSemantics(
          find.byKey(Key('${family.id}-c20e-${selected.id}')),
        );
        expect(selectedNode.flagsCollection.isSelected, Tristate.isTrue);
        expect(
          selectedNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isFalse,
        );
        final available = family.actions.last;
        final availableNode = tester.getSemantics(
          find.byKey(Key('${family.id}-c20e-${available.id}')),
        );
        expect(availableNode.flagsCollection.isSelected, Tristate.isFalse);
        expect(
          availableNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );

        expect(
          tester
              .widget<AnimatedScale>(
                find.byKey(
                  Key('moolsocial-local-${available.id}-pressed-scale'),
                ),
              )
              .duration,
          Duration.zero,
        );
        expect(
          tester.widget<SizedBox>(
            find.byKey(Key('moolsocial-local-${selected.id}-selection')),
          ),
          isA<SizedBox>(),
        );
        expect(
          tester
              .widget<AnimatedContainer>(
                find.byKey(
                  Key('moolsocial-local-${selected.id}-selected-indicator'),
                ),
              )
              .duration,
          Duration.zero,
        );
        expect(
          find.byKey(Key('moolsocial-local-${selected.id}-glass-control')),
          findsNothing,
        );
        expect(
          find.byKey(
            Key('moolsocial-local-${selected.id}-selected-inner-chroma'),
          ),
          findsNothing,
        );

        await tester.tap(find.byKey(Key('${family.id}-c20e-${available.id}')));
        await tester.pump();
        expect(opens, 1);
        expect(tester.takeException(), isNull);
      }
    },
  );
}

Future<void> _mountFamily(
  WidgetTester tester, {
  required _FamilySpec family,
  required int selectedIndex,
  required double width,
  required double textScale,
  bool reducedMotion = false,
  ValueChanged<int>? onOpen,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 180));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 180),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: Material(
          color: const Color(0xFFF4F6FB),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MoolLocalNavigationRail(
              key: Key('${family.id}-c20e-rail'),
              familyId: family.id,
              semanticLabel: '${family.id} choices',
              activeId: family.actions[selectedIndex].id,
              actions: [
                for (var index = 0; index < family.actions.length; index += 1)
                  MoolLocalNavigationAction(
                    keyName: '${family.id}-c20e-${family.actions[index].id}',
                    id: family.actions[index].id,
                    label: family.actions[index].label,
                    icon: family.actions[index].icon,
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
  );
  await tester.pumpAndSettle();
}

void _expectAdaptiveFamily(
  WidgetTester tester, {
  required _FamilySpec family,
  required int selectedIndex,
  required double width,
}) {
  final rail = find.byKey(Key('${family.id}-c20e-rail'));
  final cluster = find.descendant(
    of: rail,
    matching: find.byKey(
      const Key('moolsocial-local-navigation-compact-cluster'),
    ),
  );
  expect(tester.getSize(rail).height, MoolLocalNavigationTokens.railHeight);
  expect(
    tester.getSize(cluster).width,
    MoolLocalNavigationTokens.clusterWidth(width, family.actions.length),
  );
  expect(tester.getTopLeft(cluster).dx, tester.getTopLeft(rail).dx);
  expect(tester.getSize(cluster).width, lessThan(tester.getSize(rail).width));
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
    findsNothing,
  );
  expect(
    find.descendant(of: rail, matching: find.byType(FittedBox)),
    findsNothing,
  );

  for (var index = 0; index < family.actions.length; index += 1) {
    final action = family.actions[index];
    final actionFinder = find.byKey(Key('${family.id}-c20e-${action.id}'));
    expect(tester.getSize(actionFinder).width, greaterThanOrEqualTo(44));
    expect(
      tester.getSize(actionFinder).height,
      MoolLocalNavigationTokens.destinationRailHeight,
    );
    final label = find.descendant(of: rail, matching: find.text(action.label));
    final text = tester.widget<Text>(label);
    expect(text.maxLines, 2);
    expect(
      text.style?.fontSize,
      MoolLocalNavigationTokens.destinationLabelSize,
    );
    expect(
      text.style?.fontFamily,
      MoolLocalNavigationTokens.destinationFontFamily,
    );

    final selected = index == selectedIndex;
    final foreground = selected ? MoolColors.navy : MoolColors.muted;
    expect(text.style?.fontWeight, selected ? FontWeight.w800 : FontWeight.w700);
    expect(text.style?.color, foreground);
    expect(
      _contrastRatio(
        foreground,
        MoolLocalNavigationTokens.destinationCanvas,
      ),
      greaterThanOrEqualTo(4.5),
    );
    final node = tester.getSemantics(actionFinder);
    expect(
      node.flagsCollection.isSelected,
      selected ? Tristate.isTrue : Tristate.isFalse,
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), !selected);
    expect(
      find.byKey(Key('moolsocial-local-${action.id}-glass-control')),
      findsNothing,
    );
    expect(
      find.byKey(Key('moolsocial-local-${action.id}-selected-inner-chroma')),
      findsNothing,
    );
    final indicator = find.byKey(
      Key('moolsocial-local-${action.id}-selected-indicator'),
    );
    expect(
      tester.getSize(indicator).width,
      selected
          ? MoolLocalNavigationTokens.destinationSelectedIndicatorWidth
          : 0,
    );
    expect(
      tester.getSize(indicator).height,
      MoolLocalNavigationTokens.destinationSelectedIndicatorHeight,
    );
  }
  expect(tester.takeException(), isNull);
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
  const _FamilySpec(this.id, this.actions);

  final String id;
  final List<_ActionSpec> actions;
}

class _ActionSpec {
  const _ActionSpec(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}
