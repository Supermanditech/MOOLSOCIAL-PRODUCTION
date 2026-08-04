import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/review/mool_motion_primitives_review_main.dart';

Widget host(Widget child, {bool reduced = false}) {
  return MaterialApp(
    theme: MoolTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  test('brand gradients contain exactly the four identity colours', () {
    final used = MoolBrandGradient.values
        .expand((gradient) => gradient.colors)
        .toSet();
    expect(used, MoolBrand.identityPalette.toSet());
    expect(used.every(MoolBrand.isIdentityColor), isTrue);
  });

  testWidgets('gradient transition is finite and reduced motion is zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const MoolFiniteGradientTransition(
          gradient: MoolBrandGradient.saffron,
          child: SizedBox(width: 120, height: 60),
        ),
      ),
    );
    expect(
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).duration,
      MoolMotion.deliberate,
    );

    await tester.pumpWidget(
      host(
        const MoolFiniteGradientTransition(
          gradient: MoolBrandGradient.green,
          child: SizedBox(width: 120, height: 60),
        ),
        reduced: true,
      ),
    );
    expect(
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).duration,
      Duration.zero,
    );
  });

  testWidgets('text transition keeps one final semantic owner', (tester) async {
    await tester.pumpWidget(
      host(
        const MoolFiniteTextTransition(
          stateKey: 1,
          text: 'Second state',
          ownerSize: Size(180, 44),
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Second state'), findsOneWidget);
    expect(
      tester.getSize(find.byType(MoolFiniteTextTransition)),
      const Size(180, 44),
    );
  });

  testWidgets('icon transition keeps one final semantic owner', (tester) async {
    await tester.pumpWidget(
      host(
        const MoolFiniteIconTransition(
          stateKey: 1,
          icon: Icons.check_rounded,
          semanticLabel: 'Complete icon',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Complete icon'), findsOneWidget);
    expect(
      tester.getSize(find.byType(MoolFiniteIconTransition)),
      const Size.square(44),
    );
  });

  testWidgets('generic state resolves immediately under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const MoolFiniteStateTransition(
          stateKey: 'complete',
          ownerSize: Size(200, 48),
          semanticLabel: 'Complete state',
          child: Text('Complete'),
        ),
        reduced: true,
      ),
    );
    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);
    expect(find.bySemanticsLabel('Complete state'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
  });

  testWidgets('review harness fits at 320 pixels and 140 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: const MoolMotionPrimitivesReviewApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('motion-primitives-next')), findsOneWidget);
    await tester.tap(find.byKey(const Key('motion-primitives-next')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Text changed'), findsOneWidget);
  });
}
