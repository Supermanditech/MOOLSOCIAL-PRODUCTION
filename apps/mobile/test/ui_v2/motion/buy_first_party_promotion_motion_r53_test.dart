import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R53 entry and acknowledgement are finite and action-immediate', (
    tester,
  ) async {
    var actions = 0;
    await tester.pumpWidget(
      _app(
        BuyV2PromotionCard(
          key: const ValueKey('promotion-under-test'),
          title: 'Plan the monthly basket',
          detail: 'Review a ready household product list',
          icon: Icons.shopping_basket_outlined,
          onTap: () => actions += 1,
        ),
      ),
    );

    expect(_translationY(tester, 'buy-promotion-entry-transform'), 7);
    await tester.pump(const Duration(milliseconds: 150));
    final middleEntry = _translationY(tester, 'buy-promotion-entry-transform');
    expect(middleEntry, greaterThan(0));
    expect(middleEntry, lessThan(7));
    await tester.pumpAndSettle();
    expect(_translationY(tester, 'buy-promotion-entry-transform'), 0);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('promotion-under-test')))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('promotion-under-test')));
    expect(actions, 1, reason: 'Acknowledgement must not delay the action.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    expect(_scaleX(tester, 'buy-promotion-action-icon'), greaterThan(1));
    expect(_translationX(tester, 'buy-promotion-action-arrow'), greaterThan(0));
    await tester.pumpAndSettle();
    expect(_scaleX(tester, 'buy-promotion-action-icon'), 1);
    expect(_translationX(tester, 'buy-promotion-action-arrow'), 0);
    expect(actions, 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('R53 off-screen pause and reduced motion stay static', (
    tester,
  ) async {
    var actions = 0;
    Widget card({required bool ticker, required bool reduced}) => _app(
      TickerMode(
        enabled: ticker,
        child: BuyV2PromotionCard(
          key: const ValueKey('paused-promotion'),
          title: 'Flexible restocking',
          detail: 'See products with flexible minimum packs',
          icon: Icons.inventory_2_outlined,
          sequenceIndex: 1,
          onTap: () => actions += 1,
        ),
      ),
      disableAnimations: reduced,
    );

    await tester.pumpWidget(card(ticker: false, reduced: false));
    await tester.pump(const Duration(seconds: 1));
    expect(_translationY(tester, 'buy-promotion-entry-transform'), 7);

    await tester.pumpWidget(card(ticker: true, reduced: false));
    await tester.pumpAndSettle();
    expect(_translationY(tester, 'buy-promotion-entry-transform'), 0);

    await tester.pumpWidget(card(ticker: true, reduced: true));
    await tester.pump();
    expect(_translationY(tester, 'buy-promotion-entry-transform'), 0);
    await tester.tap(find.byKey(const ValueKey('paused-promotion')));
    await tester.pump();
    expect(actions, 1);
    expect(_scaleX(tester, 'buy-promotion-action-icon'), 1);
    expect(_translationX(tester, 'buy-promotion-action-arrow'), 0);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });
}

Widget _app(Widget child, {bool disableAnimations = false}) => MaterialApp(
  theme: MoolTheme.light(),
  home: MediaQuery(
    data: const MediaQueryData().copyWith(
      disableAnimations: disableAnimations,
      textScaler: const TextScaler.linear(1.4),
    ),
    child: Scaffold(body: Center(child: child)),
  ),
);

double _translationX(WidgetTester tester, String key) => tester
    .widget<Transform>(find.byKey(ValueKey<String>(key)))
    .transform
    .getTranslation()
    .x;

double _translationY(WidgetTester tester, String key) => tester
    .widget<Transform>(find.byKey(ValueKey<String>(key)))
    .transform
    .getTranslation()
    .y;

double _scaleX(WidgetTester tester, String key) => tester
    .widget<Transform>(find.byKey(ValueKey<String>(key)))
    .transform
    .entry(0, 0);
