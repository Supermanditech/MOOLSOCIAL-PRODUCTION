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
          child: Material(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: MoolLocalNavigationRail(
                key: const Key('test-local-rail'),
                familyId: 'ride',
                semanticLabel: 'Test choices',
                activeId: 'action-$selectedIndex',
                actions: [
                  for (var index = 0; index < actionCount; index++)
                    MoolLocalNavigationAction(
                      keyName: 'test-action-$index',
                      id: 'action-$index',
                      label: switch (index) {
                        0 => 'Order Food',
                        1 => 'Wholesale',
                        2 => 'Workspace',
                        _ => 'Medicine',
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
    );
    await tester.pump();
  }

  for (final actionCount in const [2, 3, 4]) {
    testWidgets(
      '$actionCount actions use one centered compact cluster with 48px targets',
      (tester) async {
        await mountRail(tester, actionCount: actionCount, selectedIndex: 1);

        final rail = find.byKey(const Key('test-local-rail'));
        final cluster = find.byKey(
          const Key('moolsocial-local-navigation-compact-cluster'),
        );
        expect(rail, findsOneWidget);
        expect(cluster, findsOneWidget);
        expect(
          find.descendant(of: rail, matching: find.byType(Scrollable)),
          findsNothing,
        );
        expect(
          find.descendant(of: rail, matching: find.byType(Expanded)),
          findsNothing,
        );

        final railRect = tester.getRect(rail);
        final clusterRect = tester.getRect(cluster);
        expect(railRect.height, MoolLocalNavigationTokens.railHeight);
        expect(clusterRect.center.dx, closeTo(railRect.center.dx, .01));
        expect(
          clusterRect.width,
          closeTo(
            MoolLocalNavigationTokens.clusterWidth(412, actionCount),
            .01,
          ),
        );
        expect(clusterRect.width, lessThan(railRect.width));

        for (var index = 0; index < actionCount; index++) {
          final action = find.byKey(Key('test-action-$index'));
          final size = tester.getSize(action);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }

        final selected = find.byKey(const Key('test-action-1'));
        final selectedCenter =
            tester.getRect(selected).center.dx - railRect.left;
        expect(
          selectedCenter,
          closeTo(
            MoolLocalNavigationTokens.selectedCenterX(
              maxWidth: railRect.width,
              actionCount: actionCount,
              selectedIndex: 1,
            ),
            .01,
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'compact large text preserves one row, all labels and hit targets',
    (tester) async {
      await mountRail(
        tester,
        actionCount: 4,
        selectedIndex: 2,
        width: 320,
        textScale: 2,
      );

      final rail = find.byKey(const Key('test-local-rail'));
      final cluster = find.byKey(
        const Key('moolsocial-local-navigation-compact-cluster'),
      );
      expect(
        tester.getSize(cluster).width,
        closeTo(MoolLocalNavigationTokens.clusterWidth(320, 4), .01),
      );
      expect(tester.getSize(rail).height, MoolLocalNavigationTokens.railHeight);
      expect(find.text('Order Food'), findsOneWidget);
      expect(find.text('Wholesale'), findsOneWidget);
      expect(find.text('Workspace'), findsOneWidget);
      expect(find.text('Medicine'), findsOneWidget);
      for (var index = 0; index < 4; index++) {
        final size = tester.getSize(find.byKey(Key('test-action-$index')));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selected state is inert, one tap opens once and motion is finite',
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

      final selection = tester.widget<AnimatedContainer>(
        find.byKey(const Key('moolsocial-local-action-0-selection')),
      );
      expect(selection.duration, MoolMotion.quick);
      await tester.tap(find.byKey(const Key('test-action-1')));
      await tester.pump();
      expect(opens, 1);
    },
  );

  testWidgets(
    'reduced motion settles every shared selected token immediately',
    (tester) async {
      await mountRail(
        tester,
        actionCount: 2,
        selectedIndex: 1,
        reducedMotion: true,
      );
      final selection = tester.widget<AnimatedContainer>(
        find.byKey(const Key('moolsocial-local-action-1-selection')),
      );
      final selectedEmission = tester.widget<AnimatedOpacity>(
        find.byKey(
          const Key('moolsocial-local-action-1-selected-inner-chroma'),
        ),
      );
      expect(selection.duration, Duration.zero);
      expect(selectedEmission.duration, Duration.zero);
      expect(selectedEmission.opacity, 1);
    },
  );

  test('six families share one neutral base and unique inner accents', () {
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
    expect(signals.length, 6);
    for (final family in const [
      'social',
      'buy',
      'eat',
      'ride',
      'book',
      'work',
    ]) {
      expect(signals[family], MoolBrand.identityWhite);
    }
    expect(signals.values.toSet(), hasLength(1));
    expect({
      for (final family in signals.keys)
        MoolLocalNavigationTokens.emissionColorForFamily(family),
    }, hasLength(6));
  });
}
