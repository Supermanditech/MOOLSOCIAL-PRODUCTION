import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
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
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(textScale),
        ),
        child: RepaintBoundary(
          key: const ValueKey('buy-coupon-offer-review-boundary'),
          child: child!,
        ),
      );
    },
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      initialCartScope: session.cartScope,
    ),
  );
}

BuyV2Product shopProduct() => BuyV2Catalogue.products.firstWhere(
  (product) => product.destination == BuyV2Destination.shop,
);

Future<void> openCoupons(WidgetTester tester) async {
  final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
  await tester.scrollUntilVisible(
    coupons,
    450,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 40,
  );
  await tester.pumpAndSettle();
  await tester.tap(coupons);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Coupons and offers selection review phases', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(
      core: BuySession(),
      cartBenefitsAdapter: const BuyV2SeededCartBenefitsAdapter(),
    );
    session.addProduct(shopProduct().id);
    session.openCart();
    await tester.pumpWidget(reviewHost(session));
    await tester.pumpAndSettle();
    await openCoupons(tester);

    await expectLater(
      find.byKey(const ValueKey('buy-coupon-offer-review-boundary')),
      matchesGoldenFile('goldens/buy-coupon-offer-start.png'),
    );

    await tester.tap(
      find.byKey(const ValueKey('buy-cart-benefit-select-shop-coupon')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    await expectLater(
      find.byKey(const ValueKey('buy-coupon-offer-review-boundary')),
      matchesGoldenFile('goldens/buy-coupon-offer-selected-mid.png'),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('buy-coupon-offer-review-boundary')),
      matchesGoldenFile('goldens/buy-coupon-offer-selected-settled.png'),
    );

    final replacement = find.byKey(
      const ValueKey('buy-cart-benefit-select-shop-coupon-2'),
    );
    await tester.ensureVisible(replacement);
    await tester.pumpAndSettle();
    await tester.tap(replacement);
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('buy-coupon-offer-review-boundary')),
      matchesGoldenFile('goldens/buy-coupon-offer-replaced-settled.png'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fail-closed reduced review at 320 and 140 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    session.addProduct(shopProduct().id);
    session.openCart();
    await tester.pumpWidget(reviewHost(session, reduced: true, textScale: 1.4));
    await tester.pumpAndSettle();
    await openCoupons(tester);

    await expectLater(
      find.byKey(const ValueKey('buy-coupon-offer-review-boundary')),
      matchesGoldenFile('goldens/buy-coupon-offer-empty-reduced-320-140.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
