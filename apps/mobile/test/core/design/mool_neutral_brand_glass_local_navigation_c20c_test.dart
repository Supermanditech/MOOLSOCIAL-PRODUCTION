import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';

void main() {
  Future<void> mountRail(
    WidgetTester tester, {
    required int actionCount,
    int selectedIndex = 0,
    double width = 412,
    double textScale = 1,
    bool reducedMotion = false,
    bool includeProviderAsset = false,
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
            accessibleNavigation: reducedMotion,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF6F0E8), Color(0xFF7188A8)],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: MoolLocalNavigationRail(
                  key: const Key('c20c-test-rail'),
                  familyId: surfaceTone == MoolLocalNavigationSurfaceTone.media
                      ? 'social'
                      : 'buy',
                  semanticLabel: 'C20C choices',
                  activeId: 'action-$selectedIndex',
                  surfaceTone: surfaceTone,
                  actions: [
                    for (var index = 0; index < actionCount; index++)
                      MoolLocalNavigationAction(
                        keyName: 'c20c-action-$index',
                        id: 'action-$index',
                        label: switch (index) {
                          0 => 'Wholesale',
                          1 => 'Medicine',
                          2 => 'Book Table',
                          _ => 'Workspace',
                        },
                        icon: Icons.circle_outlined,
                        iconAsset: includeProviderAsset && index == 0
                            ? 'assets/prototype/provider-youtube.svg'
                            : null,
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

  test('tokens use one optical liquid-glass Mool identity grammar', () {
    expect(MoolLocalNavigationTokens.controlHeight, 48);
    expect(MoolLocalNavigationTokens.controlRadius, 15);
    expect(MoolLocalNavigationTokens.backdropBlurSigma, 20);
    expect(MoolLocalNavigationTokens.iconSize, 20);
    expect(MoolLocalNavigationTokens.providerIconWidth, 20);
    expect(MoolLocalNavigationTokens.providerIconHeight, 20);
    expect(MoolLocalNavigationTokens.providerGlyphSize, 18);
    expect(MoolLocalNavigationTokens.labelFontSize, 13);
    expect(MoolLocalNavigationTokens.labelFontWeight, FontWeight.w700);
    expect(MoolLocalNavigationTokens.itemGap, 8);
    expect(MoolLocalNavigationTokens.selectedIndicatorWidth, 12);
    expect(
      MoolLocalNavigationTokens.pressDuration,
      const Duration(milliseconds: 100),
    );
    expect(MoolLocalNavigationTokens.stateDuration, MoolMotion.quick);

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
    expect(signals.values.map(_rgb).toSet(), hasLength(2));
  });

  for (final actionCount in const [2, 3, 4]) {
    testWidgets('$actionCount actions stay centered, individual and 48px', (
      tester,
    ) async {
      await mountRail(
        tester,
        actionCount: actionCount,
        selectedIndex: actionCount - 1,
        width: 320,
        textScale: 1.3,
      );

      final rail = find.byKey(const Key('c20c-test-rail'));
      final cluster = find.byKey(
        const Key('moolsocial-local-navigation-compact-cluster'),
      );
      expect(tester.getSize(rail).height, 52);
      expect(tester.getRect(cluster).center.dx, tester.getRect(rail).center.dx);
      expect(
        tester.getSize(cluster).width,
        MoolLocalNavigationTokens.clusterWidth(320, actionCount),
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
        final action = find.byKey(Key('c20c-action-$index'));
        expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(action).height, 48);
        final text = find.text(switch (index) {
          0 => 'Wholesale',
          1 => 'Medicine',
          2 => 'Book Table',
          _ => 'Workspace',
        });
        final style = tester.widget<Text>(text).style!;
        expect(style.fontSize, 13);
        expect(style.fontWeight, FontWeight.w700);
        expect(
          find.ancestor(of: text, matching: find.byType(FittedBox)),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'light and media lenses use gradients specular edges and readable contrast',
    (tester) async {
      for (final tone in MoolLocalNavigationSurfaceTone.values) {
        await mountRail(
          tester,
          actionCount: 2,
          selectedIndex: 0,
          surfaceTone: tone,
        );
        final selectedGlass = tester.widget<AnimatedContainer>(
          find.byKey(const Key('moolsocial-local-action-0-glass-control')),
        );
        final availableGlass = tester.widget<AnimatedContainer>(
          find.byKey(const Key('moolsocial-local-action-1-glass-control')),
        );
        final selectedDecoration = selectedGlass.decoration! as BoxDecoration;
        final availableDecoration = availableGlass.decoration! as BoxDecoration;
        final selectedBorder =
            (selectedGlass.foregroundDecoration! as BoxDecoration).border!.top;
        final availableBorder =
            (availableGlass.foregroundDecoration! as BoxDecoration).border!.top;
        final selectedGradient = selectedDecoration.gradient! as LinearGradient;
        final availableGradient =
            availableDecoration.gradient! as LinearGradient;

        expect(selectedDecoration.color, isNull);
        expect(availableDecoration.color, isNull);
        expect(selectedGradient.colors, hasLength(2));
        expect(availableGradient.colors, hasLength(2));
        for (var index = 0; index < 2; index++) {
          expect(
            _rgb(selectedGradient.colors[index]),
            _rgb(availableGradient.colors[index]),
          );
          expect(
            selectedGradient.colors[index].a,
            greaterThan(availableGradient.colors[index].a),
          );
        }
        expect(selectedBorder.width, 1);
        expect(availableBorder.width, 1);
        final selectedShadow =
            ((tester
                            .widget<AnimatedContainer>(
                              find.byKey(
                                const Key(
                                  'moolsocial-local-action-0-selection',
                                ),
                              ),
                            )
                            .decoration!
                        as BoxDecoration)
                    .boxShadow)!
                .single;
        final availableShadow =
            ((tester
                            .widget<AnimatedContainer>(
                              find.byKey(
                                const Key(
                                  'moolsocial-local-action-1-selection',
                                ),
                              ),
                            )
                            .decoration!
                        as BoxDecoration)
                    .boxShadow)!
                .single;
        expect(
          selectedShadow.blurRadius,
          greaterThan(availableShadow.blurRadius),
        );
        expect(
          find.byKey(const Key('moolsocial-local-action-0-specular-edge')),
          findsOneWidget,
        );

        final backgrounds = tone == MoolLocalNavigationSurfaceTone.media
            ? const [Colors.white, Color(0xFFFFA24A), Color(0xFF111827)]
            : const [Colors.white, Color(0xFFFF8A00), MoolBrand.identityNavy];
        for (final background in backgrounds) {
          for (final glassStop in availableGradient.colors) {
            expect(
              _contrastRatio(
                MoolLocalNavigationTokens.foreground(tone),
                Color.alphaBlend(glassStop, background),
              ),
              greaterThanOrEqualTo(4.5),
              reason: '$tone over ${background.toARGB32().toRadixString(16)}',
            );
          }
        }
      }
    },
  );

  testWidgets('selected stays inert and neutral press is finite', (
    tester,
  ) async {
    var opens = 0;
    await mountRail(
      tester,
      actionCount: 3,
      selectedIndex: 0,
      onOpen: (_) => opens += 1,
    );

    final selectedNode = tester.getSemantics(
      find.byKey(const Key('c20c-action-0')),
    );
    expect(selectedNode.flagsCollection.isSelected, Tristate.isTrue);
    expect(
      selectedNode.getSemanticsData().hasAction(SemanticsAction.tap),
      isFalse,
    );
    final availableNode = tester.getSemantics(
      find.byKey(const Key('c20c-action-1')),
    );
    expect(availableNode.flagsCollection.isSelected, Tristate.isFalse);
    expect(
      availableNode.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );

    final availableGlass = find.byKey(
      const Key('moolsocial-local-action-1-glass-control'),
    );
    final before =
        ((tester.widget<AnimatedContainer>(availableGlass).decoration!
                        as BoxDecoration)
                    .gradient!
                as LinearGradient)
            .colors
            .last;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('c20c-action-1'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final pressed =
        ((tester.widget<AnimatedContainer>(availableGlass).decoration!
                        as BoxDecoration)
                    .gradient!
                as LinearGradient)
            .colors
            .last;
    expect(_rgb(pressed), _rgb(before));
    expect(pressed.a, greaterThan(before.a));
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const Key('moolsocial-local-action-1-pressed-scale')),
          )
          .scale,
      .975,
    );
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const Key('moolsocial-local-action-1-pressed-scale')),
          )
          .duration,
      const Duration(milliseconds: 100),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(opens, 1);
  });

  testWidgets('provider glyph is normalized inside the same 20px optical box', (
    tester,
  ) async {
    await mountRail(tester, actionCount: 2, includeProviderAsset: true);
    final provider = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(provider.width, 18);
    expect(provider.height, 18);
    expect(
      tester.getSize(
        find.byKey(const Key('moolsocial-local-action-0-icon-optical-box')),
      ),
      const Size(20, 20),
    );
  });

  testWidgets('reduced motion settles every shared state immediately', (
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
}

int _rgb(Color color) => color.toARGB32() & 0x00FFFFFF;

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
