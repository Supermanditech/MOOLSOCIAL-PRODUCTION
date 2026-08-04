import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BuyV2CartScope scopeFor(BuyV2Destination destination) =>
      switch (destination) {
        BuyV2Destination.shop => BuyV2CartScope.shop,
        BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
        BuyV2Destination.medicine => BuyV2CartScope.medicine,
        BuyV2Destination.orders => BuyV2CartScope.all,
      };

  Future<void> capture(
    WidgetTester tester, {
    required Size size,
    required BuyV2Destination destination,
    required BuyV2CartBenefitKind kind,
    required double textScale,
    required String fileName,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BuyV2Session(
      core: BuySession(),
      cartBenefitsAdapter: const BuyV2SeededCartBenefitsAdapter(),
    );
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) =>
          candidate.destination == destination &&
          !candidate.requiresPrescription,
    );
    expect(session.addProduct(product.id), isTrue);
    final scope = scopeFor(destination);
    session.openCart(scope: scope);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          );
        },
        home: BuyV2Screen(
          session: session,
          initialDestination: destination,
          initialView: BuyV2View.cart,
          initialCartScope: scope,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
    await tester.scrollUntilVisible(
      coupons,
      420,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await tester.pumpAndSettle();
    await tester.tap(coupons);
    await tester.pumpAndSettle();
    if (kind == BuyV2CartBenefitKind.paymentOffer) {
      await tester.tap(
        find.byKey(const ValueKey('buy-cart-benefit-kind-payment')),
      );
      await tester.pumpAndSettle();
    }
    final id = '${destination.name}-${kind.name}';
    final select = find.byKey(ValueKey('buy-cart-benefit-select-$id'));
    await tester.ensureVisible(select);
    await tester.tap(select);
    await tester.pumpAndSettle();
    expect(find.text('Review 1 selection in Cart'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('buy-cart-benefits-page')),
      matchesGoldenFile(
        '../../../artifacts/quality/'
        'buy-offers-coupons-continuation-r58-4-audit-20260803-127/'
        'captures/$fileName',
      ),
    );
  }

  testWidgets('capture Shop coupon completion at iOS portrait size', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(390, 844),
      destination: BuyV2Destination.shop,
      kind: BuyV2CartBenefitKind.coupon,
      textScale: 1,
      fileName: 'shop-coupon-completion-390x844.png',
    );
  });

  testWidgets('capture Wholesale payment completion at Android portrait size', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(360, 800),
      destination: BuyV2Destination.wholesale,
      kind: BuyV2CartBenefitKind.paymentOffer,
      textScale: 1,
      fileName: 'wholesale-payment-completion-360x800.png',
    );
  });

  testWidgets('capture Medicine completion at 320px and 140 percent', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(320, 700),
      destination: BuyV2Destination.medicine,
      kind: BuyV2CartBenefitKind.coupon,
      textScale: 1.4,
      fileName: 'medicine-coupon-completion-320x700-140.png',
    );
  });
}
