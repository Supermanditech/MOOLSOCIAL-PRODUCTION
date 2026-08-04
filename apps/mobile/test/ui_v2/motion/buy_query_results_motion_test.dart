import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

Widget resultsHost(
  BuyV2Session session, {
  bool reduced = false,
  double textScale = 1,
}) {
  return MaterialApp(
    theme: MoolTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: reduced,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: AnimatedBuilder(
          animation: session,
          builder: (context, _) => BuyV2SearchResultsView(session: session),
        ),
      ),
    ),
  );
}

Widget screenHost(BuyV2Session session) {
  return MaterialApp(
    theme: MoolTheme.light(),
    home: BuyV2Screen(session: session),
  );
}

void main() {
  testWidgets('current query replaces results finitely without stale copy', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(resultsHost(session));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('buy-search-results-surface'));
    expect(
      tester.widget<BuyV2FiniteIncomingTransition>(surface).duration,
      BuyV2Motion.contentChange,
    );
    expect(find.byKey(const ValueKey('buy-search-suggestion-list')), findsOne);

    session.updateQuery('tomato');
    await tester.pump();
    expect(find.text('Fresh tomatoes'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-search-suggestion-list')),
      findsNothing,
    );
    expect(find.textContaining('match'), findsOneWidget);

    session.updateQuery('atta');
    await tester.pump();
    expect(find.text('Stone-ground wheat atta'), findsOneWidget);
    expect(find.text('Fresh tomatoes'), findsNothing);

    session.updateQuery('no-such-owned-product');
    await tester.pump();
    expect(find.text('No matches for “no-such-owned-product”'), findsOneWidget);
    expect(find.text('Stone-ground wheat atta'), findsNothing);

    session.updateQuery('');
    await tester.pump();
    expect(find.byKey(const ValueKey('buy-search-suggestion-list')), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid result changes preserve the real search keyboard owner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(screenHost(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('buy-search-field'));
    expect(field, findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.enterText(field, 'tomato');
    await tester.pump(const Duration(milliseconds: 70));
    expect(session.query, 'tomato');
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(field, 'atta');
    await tester.pump(const Duration(milliseconds: 70));
    expect(session.query, 'atta');
    expect(find.text('Stone-ground wheat atta'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
    await tester.pump();
    expect(session.query, isEmpty);
    expect(find.byKey(const ValueKey('buy-search-suggestion-list')), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced results are zero-duration at 320 and 140 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession())..updateQuery('tomato');
    await tester.pumpWidget(
      resultsHost(session, reduced: true, textScale: 1.4),
    );
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('buy-search-results-surface'));
    final tween = find.descendant(
      of: surface,
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    expect(
      tester.widget<TweenAnimationBuilder<double>>(tween.first).duration,
      Duration.zero,
    );
    expect(find.text('Fresh tomatoes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
