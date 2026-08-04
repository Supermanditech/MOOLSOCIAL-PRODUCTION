import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

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
      child: RepaintBoundary(
        key: const ValueKey('buy-saved-cart-review-boundary'),
        child: BuyV2Screen(session: session),
      ),
    ),
  );
}

void main() {
  testWidgets('Saved quantity and Cart motion review phases', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    session.addProduct(product.id);
    session.clearCartAcknowledgement();
    await tester.pumpWidget(reviewHost(session));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('buy-saved-cart-review-boundary')),
      matchesGoldenFile('goldens/buy-saved-cart-catalogue-start.png'),
    );

    session.toggleSaved(product.id);
    session.increase(product.id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 135));
    await expectLater(
      find.byKey(const ValueKey('buy-saved-cart-review-boundary')),
      matchesGoldenFile('goldens/buy-saved-cart-catalogue-mid.png'),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('buy-saved-cart-review-boundary')),
      matchesGoldenFile('goldens/buy-saved-cart-catalogue-settled.png'),
    );

    session.openCart();
    await tester.pumpAndSettle();
    session.increase(product.id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 135));
    await expectLater(
      find.byKey(const ValueKey('buy-saved-cart-review-boundary')),
      matchesGoldenFile('goldens/buy-saved-cart-cart-mid.png'),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('buy-saved-cart-review-boundary')),
      matchesGoldenFile('goldens/buy-saved-cart-cart-settled.png'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion Cart review at 320 and 140 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    session.addProduct(product.id);
    await tester.pumpWidget(reviewHost(session, reduced: true, textScale: 1.4));
    await tester.pumpAndSettle();
    session.openCart();
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('buy-saved-cart-review-boundary')),
      matchesGoldenFile('goldens/buy-saved-cart-reduced-320-140.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
