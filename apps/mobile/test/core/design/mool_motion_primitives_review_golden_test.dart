import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moolsocial/review/mool_motion_primitives_review_main.dart';

void main() {
  Future<void> mount(WidgetTester tester, {bool reduced = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: const RepaintBoundary(
          key: Key('motion-primitives-review-boundary'),
          child: MoolMotionPrimitivesReviewApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shared primitives initial review', (tester) async {
    await mount(tester);
    await expectLater(
      find.byKey(const Key('motion-primitives-review-boundary')),
      matchesGoldenFile('goldens/mool-motion-primitives-initial.png'),
    );
  });

  testWidgets('shared primitives intermediate review', (tester) async {
    await mount(tester);
    await tester.tap(find.byKey(const Key('motion-primitives-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    await expectLater(
      find.byKey(const Key('motion-primitives-review-boundary')),
      matchesGoldenFile('goldens/mool-motion-primitives-intermediate.png'),
    );
  });

  testWidgets('shared primitives settled review', (tester) async {
    await mount(tester);
    await tester.tap(find.byKey(const Key('motion-primitives-next')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('motion-primitives-review-boundary')),
      matchesGoldenFile('goldens/mool-motion-primitives-settled.png'),
    );
  });

  testWidgets('shared primitives reduced-motion review', (tester) async {
    await mount(tester, reduced: true);
    await tester.tap(find.byKey(const Key('motion-primitives-next')));
    await tester.pump();
    await expectLater(
      find.byKey(const Key('motion-primitives-review-boundary')),
      matchesGoldenFile('goldens/mool-motion-primitives-reduced.png'),
    );
  });
}
