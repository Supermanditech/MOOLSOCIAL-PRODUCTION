import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  testWidgets('FIX16 promo aperture owns the top hit path and semantic tap', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BuyV2Screen(session: session)),
      ),
    );
    await tester.pumpAndSettle();

    const semanticKey = ValueKey('buy-header-promo-stage-action-shop-4');
    const tapKey = ValueKey('buy-header-promo-stage-tap-shop-4');
    final promo = find.byKey(semanticKey);
    final tapSurface = find.byKey(tapKey);
    expect(promo, findsOneWidget);
    expect(tapSurface, findsOneWidget);
    expect(
      tester
          .getSemantics(promo)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    final hitResult = HitTestResult();
    tester.binding.hitTestInView(
      hitResult,
      tester.getCenter(promo),
      tester.view.viewId,
    );
    final tapRenderObject = tester.renderObject(tapSurface);
    expect(
      hitResult.path.any((entry) => entry.target == tapRenderObject),
      isTrue,
      reason: 'The transparent promo InkWell must be in the real hit path.',
    );

    await tester.tapAt(tester.getCenter(promo));
    await tester.pumpAndSettle();
    expect(find.text('Monthly home basket'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
