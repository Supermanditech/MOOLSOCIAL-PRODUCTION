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
}
