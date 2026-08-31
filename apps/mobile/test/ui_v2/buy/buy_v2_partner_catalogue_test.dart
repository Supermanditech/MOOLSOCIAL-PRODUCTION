import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

Widget _app(BuyV2Session session) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: MoolTheme.light(),
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
