import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/core/design/mool_theme.dart';

const _families = <_FamilyCase>[
  _FamilyCase('eat', [('order', 'Order Food'), ('table', 'Book Table')]),
  _FamilyCase('ride', [('bike', 'Bike'), ('auto', 'Auto'), ('cab', 'Cab')]),
  _FamilyCase('book', [('doctor', 'Doctor'), ('salon', 'Salon')]),
  _FamilyCase('work', [('earn', 'Earn Today'), ('workspace', 'Workspace')]),
];

void main() {
  for (final family in _families) {
    for (final selectedAction in family.actions) {
      testWidgets(
        '${family.id}/${selectedAction.$1} keeps ${family.actions.length} compact leading destination actions',
        (tester) async {
          var opens = 0;
          await tester.binding.setSurfaceSize(const Size(412, 180));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(412, 180),
                  textScaler: TextScaler.linear(2),
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFE6ECF5)],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: MoolLocalNavigationRail(
                        key: Key('${family.id}-test-rail'),
                        familyId: family.id,
                        surfaceTone: MoolLocalNavigationSurfaceTone.light,
                        semanticLabel: '${family.id} choices',
                        activeId: selectedAction.$1,
                        actions: [
                          for (final action in family.actions)
                            MoolLocalNavigationAction(
                              keyName: '${family.id}-test-${action.$1}',
                              id: action.$1,
                              label: action.$2,
                              icon: Icons.circle_outlined,
                              onPressed: action == selectedAction
                                  ? null
                                  : () => opens += 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final rail = find.byKey(Key('${family.id}-test-rail'));
          final cluster = find.byKey(
            const Key('moolsocial-local-navigation-compact-cluster'),
          );
          expect(
            tester.getSize(cluster).width,
            MoolLocalNavigationTokens.clusterWidth(412, family.actions.length),
          );
          expect(tester.getTopLeft(cluster).dx, tester.getTopLeft(rail).dx);
          expect(
            find.descendant(of: rail, matching: find.byType(BackdropFilter)),
            findsNothing,
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
            find.descendant(of: rail, matching: find.byType(ColoredBox)),
            findsNothing,
          );
          expect(
            find.descendant(of: rail, matching: find.byType(FittedBox)),
            findsNothing,
          );

          for (final action in family.actions) {
            final actionFinder = find.byKey(
              Key('${family.id}-test-${action.$1}'),
            );
            expect(
              tester.getSize(actionFinder).width,
              greaterThanOrEqualTo(44),
            );
            expect(
              tester.getSize(actionFinder).height,
              MoolLocalNavigationTokens.destinationRailHeight,
            );
            final label = find.descendant(
              of: rail,
              matching: find.text(action.$2),
            );
            final text = tester.widget<Text>(label);
            final style = text.style!;
            final isSelected = action == selectedAction;
            expect(text.maxLines, 2);
            expect(
              style.fontSize,
              MoolLocalNavigationTokens.destinationLabelSize,
            );
            expect(
              style.fontFamily,
              MoolLocalNavigationTokens.destinationFontFamily,
            );
            expect(
              style.fontWeight,
              isSelected ? FontWeight.w800 : FontWeight.w700,
            );
            expect(style.color, isSelected ? MoolColors.navy : MoolColors.muted);
            expect(
              find.byKey(Key('moolsocial-local-${action.$1}-glass-control')),
              findsNothing,
            );
            expect(
              find.byKey(Key('moolsocial-local-${action.$1}-specular-edge')),
              findsNothing,
            );
            expect(
              tester.widget<SizedBox>(
                find.byKey(Key('moolsocial-local-${action.$1}-selection')),
              ),
              isA<SizedBox>(),
            );
            final indicator = find.byKey(
              Key('moolsocial-local-${action.$1}-selected-indicator'),
            );
            expect(
              tester.getSize(indicator).width,
              isSelected
                  ? MoolLocalNavigationTokens
                        .destinationSelectedIndicatorWidth
                  : 0,
            );
            expect(
              tester.getSize(indicator).height,
              MoolLocalNavigationTokens.destinationSelectedIndicatorHeight,
            );
          }

          final selected = tester.getSemantics(
            find.byKey(Key('${family.id}-test-${selectedAction.$1}')),
          );
          expect(selected.flagsCollection.isSelected, Tristate.isTrue);
          expect(
            selected.getSemanticsData().hasAction(SemanticsAction.tap),
            isFalse,
          );
          final availableAction = family.actions.first == selectedAction
              ? family.actions.last
              : family.actions.first;
          await tester.tap(
            find.byKey(Key('${family.id}-test-${availableAction.$1}')),
          );
          await tester.pumpAndSettle();
          expect(opens, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  test('variable family counts stay compact without fake symmetry', () {
    expect(MoolLocalNavigationTokens.clusterWidth(412, 2), 152);
    expect(MoolLocalNavigationTokens.clusterWidth(412, 3), 232);
    expect(_families.expand((family) => family.actions), hasLength(9));
  });
}

class _FamilyCase {
  const _FamilyCase(this.id, this.actions);

  final String id;
  final List<(String, String)> actions;
}
