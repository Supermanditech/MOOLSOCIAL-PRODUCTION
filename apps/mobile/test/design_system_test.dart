import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/core/design/mool_theme.dart';

void main() {
  test('full-app design tokens protect production interaction sizes', () {
    expect(MoolMetrics.minimumTapTarget, greaterThanOrEqualTo(44));
    expect(MoolMetrics.compactTapTarget, greaterThanOrEqualTo(44));
    expect(MoolRadii.control, lessThan(MoolRadii.card));
    expect(MoolRadii.card, lessThan(MoolRadii.sheet));
  });

  test('component typography keeps the production Inter family', () {
    final theme = MoolTheme.light();
    const states = <WidgetState>{};

    expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(
      theme.filledButtonTheme.style?.textStyle?.resolve(states)?.fontFamily,
      'Inter',
    );
    expect(
      theme.outlinedButtonTheme.style?.textStyle?.resolve(states)?.fontFamily,
      'Inter',
    );
    expect(
      theme.textButtonTheme.style?.textStyle?.resolve(states)?.fontFamily,
      'Inter',
    );
    expect(theme.snackBarTheme.contentTextStyle?.fontFamily, 'Inter');
    expect(theme.chipTheme.labelStyle?.fontFamily, 'Inter');
    expect(theme.chipTheme.secondaryLabelStyle?.fontFamily, 'Inter');
    expect(
      theme.segmentedButtonTheme.style?.textStyle?.resolve(states)?.fontFamily,
      'Inter',
    );
  });

  testWidgets('glass navigation honours reduce-motion and semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: MoolGlassSurface(
              semanticLabel: 'Primary navigation',
              child: SizedBox(width: 180, height: 44),
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Primary navigation'), findsOneWidget);
    final animated = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(animated.duration, Duration.zero);
  });

  testWidgets('outcome dock separates stable and contextual actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var tapped = '';
    MoolDockAction action(String id) => MoolDockAction(
      keyName: 'dock-$id',
      id: id,
      label: id,
      icon: Icons.circle_outlined,
      onPressed: () => tapped = id,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          bottomNavigationBar: MoolOutcomeDock(
            semanticLabel: 'Outcome navigation',
            activeId: 'second',
            mool: action('mool'),
            actions: [action('first'), action('second'), action('third')],
            chat: action('chat'),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Outcome navigation'), findsOneWidget);
    for (final id in const ['mool', 'first', 'second', 'third', 'chat']) {
      final target = find.byKey(Key('dock-$id'));
      expect(target, findsOneWidget);
      expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
    }
    await tester.tap(find.byKey(const Key('dock-third')));
    expect(tapped, 'third');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'card surface gives direct pressed feedback without shrinking tap target',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: MoolCardSurface(
                  semanticLabel: 'Open result',
                  onTap: () {},
                  child: const SizedBox(height: 44),
                ),
              ),
            ),
          ),
        ),
      );

      final target = find.bySemanticsLabel('Open result');
      expect(target, findsOneWidget);
      expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
      final gesture = await tester.startGesture(tester.getCenter(target));
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        .985,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    },
  );
}
