import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';

Widget reviewHost(
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
        body: RepaintBoundary(
          key: const ValueKey('buy-query-results-review-boundary'),
          child: AnimatedBuilder(
            animation: session,
            builder: (context, _) => BuyV2SearchResultsView(session: session),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('query result review phases', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(reviewHost(session));
    await tester.pumpAndSettle();
    final context = tester.element(
      find.byKey(const ValueKey('buy-query-results-review-boundary')),
    );
    await tester.runAsync(() async {
      for (final asset in const {
        BuyV2ProductPackshot.productAtlasPath,
        BuyV2ProductPackshot.categoryAtlasAPath,
        BuyV2ProductPackshot.categoryAtlasBPath,
        BuyV2ProductPackshot.categoryAtlasCPath,
        BuyV2ProductPackshot.medicineAtlasPath,
      }) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('buy-query-results-review-boundary')),
      matchesGoldenFile('goldens/buy-query-results-ready.png'),
    );

    session.updateQuery('tomato');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    await expectLater(
      find.byKey(const ValueKey('buy-query-results-review-boundary')),
      matchesGoldenFile('goldens/buy-query-results-mid.png'),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('buy-query-results-review-boundary')),
      matchesGoldenFile('goldens/buy-query-results-settled.png'),
    );

    session.updateQuery('no-such-owned-product');
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('buy-query-results-review-boundary')),
      matchesGoldenFile('goldens/buy-query-results-empty.png'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced results at 320 and 140 percent', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession())..updateQuery('tomato');
    await tester.pumpWidget(reviewHost(session, reduced: true, textScale: 1.4));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('buy-query-results-review-boundary')),
      matchesGoldenFile('goldens/buy-query-results-reduced-320-140.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
