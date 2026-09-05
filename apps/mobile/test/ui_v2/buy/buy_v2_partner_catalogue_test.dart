import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final id in ['s-milk-500ml', 's-milk-2l', 'w-rice-50kg', 'w-oil-10l']) {
    test('R66 supplier catalogue retains exact entry variant $id', () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final product = session.product(id);
      expect(product.catalogueListing, isFalse);
      final products = session.partnerCatalogueFor(product);
      expect(products.map((item) => item.id), contains(id));
      expect(products.first, same(product));
      expect(session.partnerCatalogueFor(product, limit: 1), [product]);
      expect(session.partnerCatalogueFor(product, limit: 0), isEmpty);
      expect(products.map((item) => item.id).toSet().length, products.length);
      for (final item in products) {
        expect(item, same(session.product(item.id)));
        expect(item.seller, product.seller);
        expect(item.destination, product.destination);
        expect(item.catalogueListing || item.id == id, isTrue);
        if (product.destination == BuyV2Destination.wholesale) {
          expect(item.minimumOrder > 2, product.minimumOrder > 2);
        }
      }
      expect(product.catalogueListing, isFalse);
      final main = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.canonicalId == product.canonicalId &&
            item.destination == product.destination,
      );
      expect(
        session
            .partnerCatalogueFor(main)
            .every((item) => item.catalogueListing),
        isTrue,
        reason: 'A variant visit must not change the main catalogue listing',
      );
      expect(
        session
            .partnerCatalogueFor(product.copyWith(id: 'unlisted-$id'))
            .any((item) => item.id == 'unlisted-$id'),
        isFalse,
        reason: 'Never manufacture a catalogue entry from a caller object',
      );
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('R66 supplier variant journey $id text $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(scale == 2 ? 320 : 390, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final product = session.product(id);
        final otherId = product.destination == BuyV2Destination.shop
            ? 'w-notebook'
            : 's-eggs';
        session.addProduct(otherId);
        final otherQuantity = session.quantityFor(otherId);
        expect(session.openProduct(id), isTrue);
        await tester.pumpWidget(_app(session, textScale: scale));
        await tester.pumpAndSettle();
        final shop = product.destination == BuyV2Destination.shop;
        final prefix = shop ? 'buy-shop-seller' : 'buy-wholesale-supplier';
        final action = find.byKey(
          ValueKey(
            '${shop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-$id',
          ),
        );
        await _revealProductAction(tester, id, action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        final sheet = find.byKey(ValueKey('$prefix-sheet-$id'));
        expect(sheet, findsOneWidget);
        expect(
          find.descendant(
            of: sheet,
            matching: find.byKey(ValueKey('buy-product-$id')),
          ),
          findsOneWidget,
        );
        final viewAll = find.byKey(ValueKey('$prefix-view-more-$id'));
        await tester.ensureVisible(viewAll);
        await tester.tap(viewAll);
        await tester.pumpAndSettle();
        final full = find.byKey(ValueKey('$prefix-full-catalogue-list'));
        expect(full, findsOneWidget);
        final card = find.descendant(
          of: full,
          matching: find.byKey(ValueKey('buy-product-$id')),
        );
        expect(card, findsOneWidget);
        final add = find.descendant(
          of: card,
          matching: find.byKey(ValueKey('buy-add-$id')),
        );
        await tester.ensureVisible(add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(session.quantityFor(id), product.minimumOrder);
        expect(session.quantityFor(otherId), otherQuantity);
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(PageStorageKey('buy-product-$id')), findsWidgets);
        await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(
          session.cartScope,
          shop ? BuyV2CartScope.shop : BuyV2CartScope.wholesale,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(PageStorageKey('buy-product-$id')), findsWidgets);
        expect(
          find.byKey(const ValueKey('buy-store-cart-bar')),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(full, findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byKey(ValueKey('$prefix-full-catalogue-sheet')),
            matching: find.byKey(const ValueKey('buy-store-cart-bar')),
          ),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(
          session.cartScope,
          shop ? BuyV2CartScope.shop : BuyV2CartScope.wholesale,
        );
        final cartProduct = find.byKey(
          ValueKey('buy-cart-product-details-$id'),
        );
        await tester.ensureVisible(cartProduct);
        await tester.tap(cartProduct);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        await tester.tap(find.widgetWithText(FilledButton, 'Review order'));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.checkout);
        await tester.tap(
          find.byKey(const ValueKey('buy-checkout-return-cart')),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(full, findsOneWidget);
        await tester.tap(find.byKey(ValueKey('$prefix-full-catalogue-close')));
        await tester.pumpAndSettle();
        expect(sheet, findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byKey(ValueKey('$prefix-route-$id')),
            matching: find.byKey(const ValueKey('buy-store-cart-bar')),
          ),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(sheet, findsOneWidget);
        await tester.tap(find.byKey(ValueKey('$prefix-sheet-close')));
        await tester.pumpAndSettle();
        expect(session.selectedProductId, id);
        expect(session.quantityFor(id), product.minimumOrder);
        expect(session.quantityFor(otherId), otherQuantity);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final firstId in ['s-eggs', 'w-notebook']) {
    testWidgets('R66 Cart store continuation stays scoped after $firstId', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.addProduct('s-eggs');
      session.addProduct('w-notebook');
      final first = session.product(firstId);
      final other = session.product(
        firstId == 's-eggs' ? 'w-notebook' : 's-eggs',
      );
      expect(session.openProduct(first.id), isTrue);
      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();

      Future<void> visitAndClose(BuyV2Product product) async {
        final prefix = product.destination == BuyV2Destination.shop
            ? 'buy-shop-seller'
            : 'buy-wholesale-supplier';
        final action = find.byKey(
          ValueKey(
            '${product.destination == BuyV2Destination.shop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-${product.id}',
          ),
        );
        await _revealProductAction(tester, product.id, action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('$prefix-sheet-${product.id}')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(ValueKey('$prefix-sheet-close')));
        await tester.pumpAndSettle();
      }

      await visitAndClose(first);
      session.openCart();
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('buy-cart-scope-${other.destination.name}')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-cart-continue-store')),
        findsNothing,
        reason: 'An unvisited scope must not offer the other scope store',
      );

      expect(session.openProduct(other.id), isTrue);
      await tester.pumpAndSettle();
      await visitAndClose(other);
      session.openCart();
      await tester.pumpAndSettle();
      for (final product in [first, other]) {
        await tester.tap(
          find.byKey(ValueKey('buy-cart-scope-${product.destination.name}')),
        );
        await tester.pumpAndSettle();
        final action = find.byKey(const ValueKey('buy-cart-continue-store'));
        expect(action, findsOneWidget);
        expect(
          find.descendant(of: action, matching: find.text(product.seller)),
          findsOneWidget,
        );
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        final prefix = product.destination == BuyV2Destination.shop
            ? 'buy-shop-seller'
            : 'buy-wholesale-supplier';
        expect(
          find.byKey(ValueKey('$prefix-sheet-${product.id}')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(ValueKey('$prefix-sheet-close')));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
      }
      await tester.tap(find.byKey(const ValueKey('buy-cart-scope-all')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-cart-continue-store')),
          matching: find.text(other.seller),
        ),
        findsOneWidget,
        reason: 'All-scope Cart retains the most recently visited store',
      );
      expect(session.quantityFor('s-eggs'), 1);
      expect(session.quantityFor('w-notebook'), 1);
      expect(tester.takeException(), isNull);
    });
  }

  test('store and brand catalogues remain exact and destination-scoped', () {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    final eggs = session.product('s-eggs');
    final storeProducts = session.partnerCatalogueFor(eggs);
    expect(storeProducts.first.id, eggs.id);
    expect(
      storeProducts.map((product) => product.id),
      containsAll(['s-eggs', 's-chicken']),
    );
    expect(
      storeProducts.every(
        (product) =>
            product.destination == BuyV2Destination.shop &&
            product.seller == 'Safe Protein Store' &&
            product.catalogueListing,
      ),
      isTrue,
    );

    final tomato = session.product('s-tomato');
    final brandProducts = session.brandCatalogueFor(tomato);
    expect(brandProducts.first.id, tomato.id);
    expect(brandProducts.length, greaterThan(1));
    expect(
      brandProducts.every(
        (product) =>
            product.destination == BuyV2Destination.shop &&
            product.brand == tomato.brand &&
            product.catalogueListing,
      ),
      isTrue,
    );
    expect(
      session.partnerCatalogueFor(session.product('m-paracetamol-500')),
      isEmpty,
    );
  });

  testWidgets('Shop store catalogue reuses product cards and opens one item', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-eggs'), isTrue);

    await tester.pumpWidget(_app(session));
    await tester.pumpAndSettle();
    final sellerAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-eggs'),
    );
    await _revealProductAction(tester, 's-eggs', sellerAction);
    await tester.tap(sellerAction);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs')),
      findsOneWidget,
    );
    expect(find.text('More from Safe Protein Store'), findsWidgets);
    expect(
      find.byKey(const ValueKey('buy-horizontal-product-grid')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-product-s-eggs')), findsOneWidget);
    final chicken = find.byKey(const ValueKey('buy-product-s-chicken'));
    expect(chicken, findsOneWidget);
    await tester.tap(chicken);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs')),
      findsNothing,
    );
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, 's-chicken');
    expect(tester.takeException(), isNull);
  });

  testWidgets('product details keeps Visit store as the single store route', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = session.product('s-eggs');
    expect(session.openProduct(product.id), isTrue);

    await tester.pumpWidget(_app(session));
    await tester.pumpAndSettle();
    final sellerAction = find.byKey(
      ValueKey('buy-shop-seller-action-${product.id}'),
    );
    await _revealProductAction(tester, product.id, sellerAction);

    expect(find.text('Visit store'), findsOneWidget);
    expect(
      find.byKey(ValueKey('buy-brand-action-${product.id}')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('store grid keeps one full-size Add action', (tester) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-eggs'), isTrue);

    await tester.pumpWidget(_app(session));
    await tester.pumpAndSettle();
    final sellerAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-eggs'),
    );
    await _revealProductAction(tester, 's-eggs', sellerAction);
    await tester.tap(sellerAction);
    await tester.pumpAndSettle();

    final add = find.byKey(const ValueKey('buy-add-s-chicken'));
    await tester.scrollUntilVisible(
      add,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  (widget.axisDirection == AxisDirection.down ||
                      widget.axisDirection == AxisDirection.up),
            ),
          )
          .first,
    );
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    expect(add, findsOneWidget);
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    expect(
      find.byKey(const ValueKey('buy-grid-buy-now-s-chicken')),
      findsNothing,
    );

    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-chicken'), 1);
    expect(
      find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'store grid Add keeps the shopper in the store and updates Cart',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-eggs'), isTrue);

      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      final sellerAction = find.byKey(
        const ValueKey('buy-shop-seller-action-s-eggs'),
      );
      await _revealProductAction(tester, 's-eggs', sellerAction);
      await tester.tap(sellerAction);
      await tester.pumpAndSettle();

      final add = find.byKey(const ValueKey('buy-add-s-chicken'));
      await tester.scrollUntilVisible(
        add,
        180,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs')),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    (widget.axisDirection == AxisDirection.down ||
                        widget.axisDirection == AxisDirection.up),
              ),
            )
            .first,
      );
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();

      expect(session.quantityFor('s-chicken'), 1);
      expect(
        find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'store catalogue exposes full products and exact related-store continuation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-eggs'), isTrue);

      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      final sellerAction = find.byKey(
        const ValueKey('buy-shop-seller-action-s-eggs'),
      );
      await _revealProductAction(tester, 's-eggs', sellerAction);
      await tester.tap(sellerAction);
      await tester.pumpAndSettle();

      final storeSheet = find.byKey(
        const ValueKey('buy-shop-seller-sheet-s-eggs'),
      );
      final storeScroll = find
          .descendant(of: storeSheet, matching: find.byType(Scrollable))
          .first;
      final viewMore = find.byKey(
        const ValueKey('buy-shop-seller-view-more-s-eggs'),
      );
      await tester.scrollUntilVisible(viewMore, 220, scrollable: storeScroll);
      await tester.tap(viewMore);
      await tester.pumpAndSettle();
      final fullCatalogue = find.byKey(
        const ValueKey('buy-shop-seller-full-catalogue-list'),
      );
      expect(fullCatalogue, findsOneWidget);
      expect(tester.getSize(fullCatalogue).height, lessThan(650));
      expect(find.text('Safe Protein Store'), findsWidgets);
      final fullEggs = find
          .descendant(
            of: fullCatalogue,
            matching: find.byKey(const ValueKey('buy-product-s-eggs')),
          )
          .first;
      expect(fullEggs, findsOneWidget);
      expect(tester.getSize(fullEggs).width, lessThan(130));

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-seller-full-catalogue-close')),
      );
      await tester.pumpAndSettle();
      final relatedStores = find.byKey(
        const ValueKey('buy-shop-seller-other-stores'),
      );
      await tester.scrollUntilVisible(
        relatedStores,
        220,
        scrollable: storeScroll,
      );
      expect(relatedStores, findsOneWidget);
      final related = find.byKey(
        const ValueKey('buy-shop-seller-other-store-s-tomato'),
      );
      await tester.tap(related);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-seller-sheet-s-tomato')),
        findsOneWidget,
      );
      expect(find.text('More from Shree Balaji Fresh'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('four-product store fills one three-SKU row without dead width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-curd'), isTrue);

    await tester.pumpWidget(_app(session));
    await tester.pumpAndSettle();
    final sellerAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-curd'),
    );
    await _revealProductAction(tester, 's-curd', sellerAction);
    await tester.tap(sellerAction);
    await tester.pumpAndSettle();

    final products = session.partnerCatalogueFor(session.product('s-curd'));
    expect(products.length, 4);
    final sheet = find.byKey(const ValueKey('buy-shop-seller-sheet-s-curd'));
    expect(
      find.descendant(
        of: sheet,
        matching: find.byKey(const ValueKey('buy-horizontal-product-lane-0')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.byKey(const ValueKey('buy-horizontal-product-lane-1')),
      ),
      findsNothing,
    );
    for (final product in products.take(3)) {
      final card = find
          .descendant(
            of: sheet,
            matching: find.byKey(ValueKey('buy-product-${product.id}')),
          )
          .first;
      expect(card, findsOneWidget);
      expect(tester.getRect(card).right, lessThanOrEqualTo(378));
    }
    expect(
      find.byKey(const ValueKey('buy-shop-seller-view-more-s-curd')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app(BuyV2Session session, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: MoolTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: BuyV2Screen(
    session: session,
    initialDestination: session.destination,
    initialView: session.view,
    productId: session.selectedProductId,
  ),
);

Future<void> _revealProductAction(
  WidgetTester tester,
  String productId,
  Finder action,
) async {
  final scrollable = find
      .descendant(
        of: find.byKey(PageStorageKey('buy-product-$productId')),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(action, 220, scrollable: scrollable);
  await tester.pumpAndSettle();
  expect(action, findsOneWidget);
}
