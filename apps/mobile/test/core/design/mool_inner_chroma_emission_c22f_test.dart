import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/core/design/mool_theme.dart';

const _families = <(String, String)>[
  ('social', 'Social'),
  ('buy', 'Buy'),
  ('eat', 'Eat'),
  ('ride', 'Ride'),
  ('book', 'Book'),
  ('work', 'Work'),
];

void main() {
  test('C22F freezes six unique internal-only family accents and timing', () {
    final accents = {
      for (final family in _families)
        MoolLocalNavigationTokens.emissionColorForFamily(family.$1).toARGB32(),
    };
    expect(accents, hasLength(6));
    expect(
      MoolLocalNavigationTokens.pressDuration,
      const Duration(milliseconds: 100),
    );
    expect(
      MoolLocalNavigationTokens.selectionDuration,
      const Duration(milliseconds: 180),
    );
    expect(
      MoolLocalNavigationTokens.disclosureDuration,
      const Duration(milliseconds: 180),
    );

    for (final family in _families) {
      final accent = MoolLocalNavigationTokens.emissionColorForFamily(
        family.$1,
      );
      final emission = MoolLocalNavigationTokens.innerEmissionGradient(
        family.$1,
      );
      expect(emission, isA<RadialGradient>());
      expect(emission.colors.first.r, closeTo(accent.r, .001));
      expect(emission.colors.first.g, closeTo(accent.g, .001));
      expect(emission.colors.first.b, closeTo(accent.b, .001));
      expect(
        emission.colors.first.a,
        closeTo(MoolLocalNavigationTokens.innerEmissionCenterAlpha, .001),
      );
      expect(
        emission.colors.first.a,
        lessThanOrEqualTo(MoolLocalNavigationTokens.maximumInnerEmissionAlpha),
      );
      expect(
        emission.colors[1].a,
        closeTo(MoolLocalNavigationTokens.innerEmissionMiddleAlpha, .001),
      );
      final neutralBase = MoolLocalNavigationTokens.glassGradient(
        tone: MoolLocalNavigationSurfaceTone.media,
        selected: false,
        pressed: false,
      );
      expect(
        neutralBase.colors.map((color) => color.toARGB32()),
        isNot(contains(accent.toARGB32())),
      );
    }
  });

  for (final family in _families) {
    testWidgets(
      'C32S ${family.$2} local indicator and dock chroma use current owners',
      (tester) async {
        await _mount(tester, family: family.$1);

        final localButton = find.byKey(const Key('c22f-local-primary'));
        final mainButton = find.byKey(Key('mool-action-${family.$1}'));
        expect(
          tester.getSize(localButton),
          const Size(
            MoolLocalNavigationTokens.capsuleWidth,
            MoolLocalNavigationTokens.destinationRailHeight,
          ),
        );
        expect(
          tester.getSize(mainButton),
          const Size(
            MoolLocalNavigationTokens.capsuleWidth,
            MoolLocalNavigationTokens.controlHeight,
          ),
        );

        final localIndicator = find.byKey(
          const ValueKey('moolsocial-local-primary-selected-indicator'),
        );
        final mainEmission = find.byKey(
          ValueKey('mool-action-${family.$1}-selected-inner-chroma'),
        );
        expect(
          tester.getSize(localIndicator),
          const Size(
            MoolLocalNavigationTokens.destinationSelectedIndicatorWidth,
            MoolLocalNavigationTokens.destinationSelectedIndicatorHeight,
          ),
        );
        expect(
          tester.widget<AnimatedContainer>(localIndicator).duration,
          MoolLocalNavigationTokens.stateDuration,
        );
        expect(
          find.byKey(
            const ValueKey('moolsocial-local-primary-selected-inner-chroma'),
          ),
          findsNothing,
        );
        expect(tester.widget<AnimatedOpacity>(mainEmission).opacity, 1);
        expect(
          tester.widget<AnimatedOpacity>(mainEmission).duration,
          MoolLocalNavigationTokens.selectionDuration,
        );
        expect(
          find.ancestor(of: mainEmission, matching: find.byType(ClipRRect)),
          findsWidgets,
        );

        final mainGradient = _gradient(
          tester,
          ValueKey('mool-action-${family.$1}-selected-inner-chroma-source'),
        );
        expect(
          mainGradient.colors.first.toARGB32(),
          MoolLocalNavigationTokens.innerEmissionGradient(
            family.$1,
          ).colors.first.toARGB32(),
        );

        expect(
          tester.getSemantics(localButton).flagsCollection.isSelected,
          Tristate.isTrue,
        );
        expect(
          tester.getSemantics(mainButton).flagsCollection.isSelected,
          Tristate.isTrue,
        );
        final localText = tester.widget<Text>(
          find.descendant(of: localButton, matching: find.text('Primary')),
        );
        expect(
          localText.style?.color,
          MoolColors.navy,
        );
        expect(
          localText.style?.fontSize,
          MoolLocalNavigationTokens.destinationLabelSize,
        );
        expect(
          localText.style?.fontWeight,
          MoolLocalNavigationTokens.destinationSelectedLabelWeight,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('C32S local press scale and dock chroma use 100ms motion', (
    tester,
  ) async {
    await _mount(tester, family: 'buy');

    final localPressScale = find.byKey(
      const ValueKey('moolsocial-local-secondary-pressed-scale'),
    );
    final localGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('c22f-local-secondary'))),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      tester.widget<AnimatedScale>(localPressScale).scale,
      .975,
    );
    expect(
      tester.widget<AnimatedScale>(localPressScale).duration,
      MoolLocalNavigationTokens.pressDuration,
    );
    expect(
      find.byKey(
        const ValueKey('moolsocial-local-secondary-pressed-inner-chroma'),
      ),
      findsNothing,
    );
    await localGesture.up();
    await tester.pump();
    expect(tester.widget<AnimatedScale>(localPressScale).scale, 1);

    final mainPress = find.byKey(
      const ValueKey('mool-action-buy-pressed-inner-chroma'),
    );
    final mainGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('mool-action-buy'))),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      tester.widget<AnimatedOpacity>(mainPress).opacity,
      MoolLocalNavigationTokens.pressedEmissionOpacity,
    );
    expect(
      tester.widget<AnimatedOpacity>(mainPress).duration,
      MoolLocalNavigationTokens.pressDuration,
    );
    await mainGesture.up();
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(mainPress).opacity, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('C32S reduced motion snaps local indicator and press scale', (
    tester,
  ) async {
    await _mount(tester, family: 'work', reducedMotion: true);
    final selected = tester.widget<AnimatedContainer>(
      find.byKey(
        const ValueKey('moolsocial-local-primary-selected-indicator'),
      ),
    );
    expect(selected.duration, Duration.zero);

    final pressScale = find.byKey(
      const ValueKey('moolsocial-local-secondary-pressed-scale'),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('c22f-local-secondary'))),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.widget<AnimatedScale>(pressScale).scale, .975);
    expect(tester.widget<AnimatedScale>(pressScale).duration, Duration.zero);
    await gesture.up();
    await tester.pump();
    expect(tester.widget<AnimatedScale>(pressScale).scale, 1);
    expect(tester.takeException(), isNull);
  });
}

RadialGradient _gradient(WidgetTester tester, Key key) {
  final decoration = tester.widget<DecoratedBox>(find.byKey(key)).decoration;
  return (decoration as BoxDecoration).gradient! as RadialGradient;
}

Future<void> _mount(
  WidgetTester tester, {
  required String family,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = const Size(360, 220);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF315B70),
        body: Column(
          children: [
            MoolLocalNavigationRail(
              familyId: family,
              semanticLabel: '$family options',
              activeId: 'primary',
              actions: [
                const MoolLocalNavigationAction(
                  keyName: 'c22f-local-primary',
                  id: 'primary',
                  label: 'Primary',
                  icon: Icons.circle,
                ),
                MoolLocalNavigationAction(
                  keyName: 'c22f-local-secondary',
                  id: 'secondary',
                  label: 'Secondary',
                  icon: Icons.circle_outlined,
                  onPressed: () {},
                ),
              ],
            ),
            const Spacer(),
            MoolOutcomeDock(
              semanticLabel: 'MoolSocial navigation',
              activeId: family,
              showOverflowCue: true,
              mool: const MoolDockAction(
                keyName: 'c22f-mool',
                id: 'mool',
                label: 'Mool',
                icon: Icons.grid_view_rounded,
              ),
              actions: [
                for (final entry in _families)
                  MoolDockAction(
                    keyName: 'mool-action-${entry.$1}',
                    id: entry.$1,
                    label: entry.$2,
                    icon: Icons.circle_outlined,
                    onPressed: () {},
                  ),
              ],
              chat: const MoolDockAction(
                keyName: 'c22f-chat',
                id: 'chat',
                label: 'Chat',
                icon: Icons.chat_bubble_outline_rounded,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
