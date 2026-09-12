import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';

void main() {
  Widget app(BuyV2Session session) => MaterialApp(
    theme: MoolTheme.light(),
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
    ),
  );

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'monthly basket intent reaches curated products and persists through Checkout',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      await tapVisible(tester, const ValueKey('buy-promotion-shop-basket'));
      expect(session.activeShoppingIntent, BuyV2ShoppingIntent.monthlyBasket);
      expect(
        find.byKey(const ValueKey('buy-household-basket-info-sheet')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-household-see-products')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-shopping-intent-bar')),
        findsOneWidget,
      );
      expect(find.text('Monthly basket'), findsOneWidget);
      expect(find.text('Clear'), findsNothing);
      expect(find.byTooltip('Dismiss Monthly basket'), findsOneWidget);
      expect(session.visibleProducts, hasLength(12));
      final product = session.visibleProducts.first;
      expect(session.openProduct(product.id), isTrue);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shopping-intent-bar')),
        findsNothing,
      );
      expect(session.activeShoppingIntent, BuyV2ShoppingIntent.monthlyBasket);
      expect(session.selectedProductId, product.id);
      session.closeProduct();
      expect(session.addProduct(product.id), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shopping-intent-bar')),
        findsOneWidget,
      );
      expect(session.openCheckout(), isTrue);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shopping-intent-bar')),
        findsOneWidget,
      );
      expect(session.activeShoppingIntent, BuyV2ShoppingIntent.monthlyBasket);

      await tester.tap(find.byKey(const ValueKey('buy-shopping-intent-clear')));
      await tester.pumpAndSettle();
      expect(session.activeShoppingIntent, isNull);
      expect(
        find.byKey(const ValueKey('buy-shopping-intent-bar')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'R668 paged monthly review shows exactly the plan across both delivery groups',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        cataloguePageSource: BuyV2DevelopmentCatalogueSource(
          destination: BuyV2Destination.shop,
          providerCount: 100,
          skusPerStore: 84,
        ),
        catalogueAreas: const {'jodhpur': 'Jodhpur'},
        initialCatalogueRegionId: 'jodhpur',
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      expect(find.byType(BuyV2PagedProductCatalogue), findsOneWidget);
      unawaited(
        showBuyV2HouseholdBasket(
          tester.element(find.byType(BuyV2CatalogueView)),
          session,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-household-see-products')),
      );
      await tester.pumpAndSettle();
      final planIds = session.monthlyBasketPlan
          .map((line) => line.product.id)
          .toSet();
      final reviewedIds = <String>{};
      for (final mode in ['quick', 'courier']) {
        await tester.tap(find.byKey(ValueKey('buy-shop-sale-type-$mode')));
        await tester.pumpAndSettle();
        expect(find.byType(BuyV2PagedProductCatalogue), findsNothing);
        expect(
          find.byKey(const ValueKey('buy-page-next-catalogue-shop')),
          findsNothing,
        );
        final expected = session.monthlyBasketPlan
            .where(
              (line) =>
                  session.fulfilmentModeFor(line.product) ==
                  (mode == 'quick'
                      ? BuyV2FulfilmentMode.quickLocal
                      : BuyV2FulfilmentMode.standardCourier),
            )
            .map((line) => line.product.id)
            .toSet();
        expect(
          session.catalogueSaleTypeProducts
              .map((product) => product.id)
              .toSet(),
          expected,
        );
        final cards = tester
            .widgetList<BuyV2ProductCard>(find.byType(BuyV2ProductCard))
            .toList();
        expect(cards, isNotEmpty);
        expect(
          cards.map((card) => card.product.id),
          everyElement(isIn(expected)),
        );
        reviewedIds.addAll(expected);
        await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('buy-discovery-refinement-count')),
              )
              .data,
          '${expected.length} products found',
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        final firstCard = find.byKey(
          ValueKey('buy-product-${cards.first.product.id}'),
        );
        await tester.ensureVisible(firstCard);
        await tester.pumpAndSettle();
        await tester.tap(firstCard);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, cards.first.product.id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.showingMonthlyBasketProducts, isTrue);
        expect(find.byType(BuyV2PagedProductCatalogue), findsNothing);
      }
      expect(reviewedIds, planIds);
      session.addMonthlyBasket();
      expect(session.cartLines.map((line) => line.product.id).toSet(), planIds);
      for (final line in session.monthlyBasketPlan) {
        expect(session.quantityFor(line.product.id), line.quantity);
      }
      await tester.tap(find.byKey(const ValueKey('buy-shopping-intent-clear')));
      await tester.pumpAndSettle();
      expect(find.byType(BuyV2PagedProductCatalogue), findsOneWidget);
      expect(session.cartLines.map((line) => line.product.id).toSet(), planIds);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('monthly basket actions clear the OPPO bottom navigation inset', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewPadding = const FakeViewPadding(bottom: 44);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tapVisible(tester, const ValueKey('buy-promotion-shop-basket'));

    final seeProducts = find.byKey(
      const ValueKey('buy-household-see-products'),
    );
    final addBasket = find.byKey(const ValueKey('buy-household-add-to-cart'));
    expect(
      find.byKey(const ValueKey('buy-household-basket-bottom-safe-area')),
      findsOneWidget,
    );
    for (final action in [seeProducts, addBasket]) {
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      final rect = tester.getRect(action);
      expect(rect.height, greaterThanOrEqualTo(44));
      expect(rect.bottom, lessThanOrEqualTo(756));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('business and home cards switch exact catalogues with intent', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tapVisible(tester, const ValueKey('buy-promotion-shop-wholesale'));
    expect(session.destination, BuyV2Destination.wholesale);
    expect(session.activeShoppingIntent, BuyV2ShoppingIntent.businessBuying);
    expect(find.text('Buying for business'), findsOneWidget);
    expect(
      session.visibleProducts,
      everyElement(
        isA<BuyV2Product>().having(
          (product) => product.destination,
          'destination',
          BuyV2Destination.wholesale,
        ),
      ),
    );

    await tapVisible(tester, const ValueKey('buy-shopping-intent-clear'));
    await tapVisible(tester, const ValueKey('buy-promotion-wholesale-shop'));
    expect(session.destination, BuyV2Destination.shop);
    expect(session.activeShoppingIntent, BuyV2ShoppingIntent.homeShopping);
    expect(find.text('Shopping for home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flexible restocking filters real products and survives Back', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession())
      ..openDestination(BuyV2Destination.wholesale);
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tapVisible(tester, const ValueKey('buy-promotion-wholesale-restock'));
    expect(
      session.activeShoppingIntent,
      BuyV2ShoppingIntent.flexibleRestocking,
    );
    expect(session.selectedFilter, 'moq');
    expect(session.visibleProducts, isNotEmpty);
    expect(
      session.visibleProducts.every((product) => product.minimumOrder <= 2),
      isTrue,
    );
    final product = session.visibleProducts.first;
    expect(session.openProduct(product.id), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Flexible restocking'), findsOneWidget);
    session.closeProduct();
    await tester.pumpAndSettle();
    expect(session.selectedFilter, 'moq');
    expect(
      session.activeShoppingIntent,
      BuyV2ShoppingIntent.flexibleRestocking,
    );
    expect(tester.takeException(), isNull);
  });
}
