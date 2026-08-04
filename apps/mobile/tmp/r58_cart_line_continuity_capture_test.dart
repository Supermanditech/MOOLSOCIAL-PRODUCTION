import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
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
    required double textScale,
    required String fileName,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BuyV2Session(core: BuySession());
    final products = BuyV2Catalogue.products
        .where(
          (product) =>
              product.destination == destination &&
              !product.requiresPrescription,
        )
        .take(2);
    for (final product in products) {
      expect(session.addProduct(product.id), isTrue);
    }
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
    expect(
      find.byKey(ValueKey('buy-cart-product-details-${products.first.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('buy-v2-screen')),
      matchesGoldenFile(
        '../../../artifacts/quality/'
        'buy-cart-line-product-continuity-r58-3-1-20260803-126/'
        'captures/$fileName',
      ),
    );
  }

  testWidgets('capture Shop Cart line at iOS portrait size', (tester) async {
    await capture(
      tester,
      size: const Size(390, 844),
      destination: BuyV2Destination.shop,
      textScale: 1,
      fileName: 'shop-cart-line-390x844.png',
    );
  });

  testWidgets('capture Medicine Cart line at Android portrait size', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(360, 800),
      destination: BuyV2Destination.medicine,
      textScale: 1,
      fileName: 'medicine-cart-line-360x800.png',
    );
  });

  testWidgets('capture Wholesale Cart line at 320px and 140 percent', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(320, 700),
      destination: BuyV2Destination.wholesale,
      textScale: 1.4,
      fileName: 'wholesale-cart-line-320x700-140.png',
    );
  });
}
