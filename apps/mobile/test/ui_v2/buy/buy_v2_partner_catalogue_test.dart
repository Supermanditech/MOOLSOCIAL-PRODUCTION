import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [const Size(320, 844), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      final profile = '${size.width.toInt()}x${size.height.toInt()}-$scale';
      testWidgets('R5 collection visibility keeps the exact branch $profile', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
        addTearDown(tester.view.reset);
        final setup = await _CollectionHeaderFixture.create(tester);
        addTearDown(setup.dispose);
        final session = setup.session;
        final current = setup.products.first;
        final other = setup.products.last;
        session.addProduct(other.id);
        session.toggleSaved(other.id);
        expect(session.openProduct(current.id), isTrue);
        await tester.pumpWidget(_app(session, textScale: scale));
        await tester.pumpAndSettle();
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
        final seller = find.byKey(
          ValueKey('buy-shop-seller-action-${current.id}'),
        );
        await _revealProductAction(tester, current.id, seller);
        await tester.ensureVisible(seller);
        await tester.pumpAndSettle();
        expect(seller.hitTestable(), findsOneWidget);
        await tester.tap(seller);
        await tester.pumpAndSettle();

        final benefit = find.byKey(
          const ValueKey('buy-public-store-collection-benefit'),
        );
        expect(benefit, findsOneWidget);
        final text = find.descendant(
          of: benefit,
          matching: find.text('Order ahead. Scan & collect.'),
        );
        expect(text, findsOneWidget);
        final bounds = tester.getRect(benefit);
        expect(bounds.top, greaterThanOrEqualTo(24));
        expect(bounds.bottom, lessThanOrEqualTo(size.height - 34));
        final viewport = tester.getRect(
          find.ancestor(of: benefit, matching: find.byType(Scrollable)).first,
        );
        expect(bounds.top, greaterThanOrEqualTo(viewport.top));
        expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom));
        final paragraph = tester.renderObject<RenderParagraph>(text);
        final natural = TextPainter(
          text: paragraph.text,
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
        )..layout(maxWidth: paragraph.size.width);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          paragraph.size.height + .1,
          greaterThanOrEqualTo(natural.height),
        );
        natural.dispose();
        await captureR66Visual(tester, 'collect-header-$profile-supported');

        // Identical display names cannot mix different branches' products.
        expect(
          session.partnerCatalogueFor(current).map((product) => product.id),
          [current.id, setup.products[1].id],
        );
        expect(session.product(current.id).storeId, 'collection-store-a');
        expect(session.product(current.id).pack, '500 ml pouch');
        expect(session.quantityFor(other.id), 1);
        expect(session.isSaved(other.id), isTrue);
        final close = find.byKey(const ValueKey('buy-shop-seller-sheet-close'));
        await tester.ensureVisible(close);
        await tester.pumpAndSettle();
        expect(close.hitTestable(), findsOneWidget);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(benefit, findsNothing);
        expect(session.selectedProductId, current.id);
        expect(session.product(current.id).storeId, 'collection-store-a');
        expect(session.quantityFor(other.id), 1);
        expect(session.isSaved(other.id), isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final invalid in [
    'unsupported',
    'absent',
    'wrong-branch',
    'expired',
    'future-observation',
    'blank-source',
    'stale-facts',
    'wrong-product',
  ]) {
    testWidgets('R5 collection visibility hides $invalid capability', (
      tester,
    ) async {
      final setup = await _CollectionHeaderFixture.create(tester);
      addTearDown(setup.dispose);
      final now = tester.binding.clock.now();
      setup.facts.capability = invalid == 'absent'
          ? null
          : BuyV2StoreCollectionCapability(
              storeId: invalid == 'wrong-branch'
                  ? 'collection-store-b'
                  : 'collection-store-a',
              supportsCollection: invalid != 'unsupported',
              sourceId: invalid == 'blank-source' ? '' : 'collection-header-v1',
              observedAt: invalid == 'future-observation'
                  ? now.add(const Duration(hours: 1))
                  : now.subtract(const Duration(seconds: 1)),
              validUntil: invalid == 'expired'
                  ? now
                  : now.add(const Duration(hours: 2)),
            );
      setup.facts.stale = invalid == 'stale-facts';
      setup.facts.wrongProduct = invalid == 'wrong-product';
      final current = setup.products.first;
      expect(setup.session.openProduct(current.id), isTrue);
      await tester.pumpWidget(_app(setup.session));
      await tester.pumpAndSettle();
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      final seller = find.byKey(
        ValueKey('buy-shop-seller-action-${current.id}'),
      );
      await _revealProductAction(tester, current.id, seller);
      await tester.ensureVisible(seller);
      await tester.pumpAndSettle();
      await tester.tap(seller);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-public-store-name')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-public-store-collection-benefit')),
        findsNothing,
      );
      expect(find.text('Order ahead. Scan & collect.'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'R5 collection visibility updates and expires on the same Store',
    (tester) async {
      final setup = await _CollectionHeaderFixture.create(tester);
      addTearDown(setup.dispose);
      final session = setup.session;
      final current = setup.products.first;
      expect(session.openProduct(current.id), isTrue);
      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      final seller = find.byKey(
        ValueKey('buy-shop-seller-action-${current.id}'),
      );
      await _revealProductAction(tester, current.id, seller);
      await tester.ensureVisible(seller);
      await tester.pumpAndSettle();
      await tester.tap(seller);
      await tester.pumpAndSettle();
      final benefit = find.byKey(
        const ValueKey('buy-public-store-collection-benefit'),
      );
      expect(benefit, findsOneWidget);

      setup.facts.capability = null;
      expect(session.refreshProductFacts(current.id), isTrue);
      await tester.pumpAndSettle();
      expect(benefit, findsNothing);

      setup.facts.capability = setup.supported(
        validUntil: tester.binding.clock.now().add(const Duration(seconds: 5)),
      );
      expect(session.refreshProductFacts(current.id), isTrue);
      await tester.pumpAndSettle();
      expect(benefit, findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(benefit, findsNothing);
      expect(session.selectedProductId, current.id);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('R5 collection visibility withdraws after an invalid refresh', (
    tester,
  ) async {
    final setup = await _CollectionHeaderFixture.create(tester);
    addTearDown(setup.dispose);
    final current = setup.products.first;
    setup.session.addProduct(setup.products.last.id);
    expect(setup.session.openProduct(current.id), isTrue);
    await tester.pumpWidget(_app(setup.session));
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    final seller = find.byKey(ValueKey('buy-shop-seller-action-${current.id}'));
    await _revealProductAction(tester, current.id, seller);
    await tester.ensureVisible(seller);
    await tester.pumpAndSettle();
    await tester.tap(seller);
    await tester.pumpAndSettle();
    final benefit = find.byKey(
      const ValueKey('buy-public-store-collection-benefit'),
    );
    expect(benefit, findsOneWidget);
    setup.facts.wrongProduct = true;
    expect(setup.session.refreshProductFacts(current.id), isFalse);
    await tester.pumpAndSettle();
    expect(benefit, findsNothing);
    expect(setup.session.quantityFor(setup.products.last.id), 1);
    setup.facts.wrongProduct = false;
    expect(setup.session.refreshProductFacts(current.id), isTrue);
    await tester.pumpAndSettle();
    expect(benefit, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R5 collection visibility rechecks capability on app resume', (
    tester,
  ) async {
    var now = tester.binding.clock.now();
    final setup = await _CollectionHeaderFixture.create(tester, now: () => now);
    addTearDown(setup.dispose);
    final current = setup.products.first;
    expect(setup.session.openProduct(current.id), isTrue);
    await tester.pumpWidget(_app(setup.session));
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    final seller = find.byKey(ValueKey('buy-shop-seller-action-${current.id}'));
    await _revealProductAction(tester, current.id, seller);
    await tester.ensureVisible(seller);
    await tester.pumpAndSettle();
    await tester.tap(seller);
    await tester.pumpAndSettle();
    final benefit = find.byKey(
      const ValueKey('buy-public-store-collection-benefit'),
    );
    expect(benefit, findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(hours: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(benefit, findsNothing);
    expect(setup.session.selectedProductId, current.id);
    expect(tester.takeException(), isNull);
  });

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
        void expectCompleteRiceEta(Finder owner) {
          if (id != 'w-rice-50kg') return;
          final unitPrice = find.descendant(
            of: find.descendant(
              of: owner,
              matching: find.byKey(ValueKey('buy-product-$id')),
            ),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is RichText &&
                  widget.text.toPlainText() == product.unitPrice,
            ),
          );
          expect(unitPrice, findsOneWidget);
          final unitParagraph = tester.renderObject<RenderParagraph>(unitPrice);
          expect(
            unitParagraph.didExceedMaxLines,
            isFalse,
            reason: 'Supplier unit price must remain complete at enlarged text',
          );
          final unitNatural = TextPainter(
            text: unitParagraph.text,
            textDirection: unitParagraph.textDirection,
            textScaler: unitParagraph.textScaler,
          )..layout(maxWidth: unitParagraph.size.width);
          expect(
            unitParagraph.size.height + .1,
            greaterThanOrEqualTo(unitNatural.height),
          );
          unitNatural.dispose();
          final promises = find.descendant(
            of: find.descendant(
              of: owner,
              matching: find.byKey(ValueKey('buy-product-$id')),
            ),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is RichText &&
                  widget.text.toPlainText().contains('5:00'),
            ),
          );
          expect(promises, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(promises);
          expect(paragraph.didExceedMaxLines, isFalse);
          final natural = TextPainter(
            text: paragraph.text,
            textDirection: paragraph.textDirection,
            textScaler: paragraph.textScaler,
          )..layout(maxWidth: paragraph.size.width);
          expect(
            paragraph.size.height + .1,
            greaterThanOrEqualTo(natural.height),
          );
          natural.dispose();
        }

        expectCompleteRiceEta(sheet);
        if (id == 'w-rice-50kg') {
          await captureR66Visual(tester, '025-rice-preview-text-$scale');
        }
        expect(
          find.descendant(
            of: sheet,
            matching: find.byKey(ValueKey('buy-product-$id')),
          ),
          findsOneWidget,
        );
        final viewAll = find.byKey(ValueKey('$prefix-view-more-$id'));
        await tester.ensureVisible(viewAll);
        final viewAllLabel = find.descendant(
          of: viewAll,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('View all'),
          ),
        );
        expect(viewAllLabel, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(viewAllLabel).didExceedMaxLines,
          isFalse,
          reason: 'The complete View all label must be visible',
        );
        await tester.tap(viewAll);
        await tester.pumpAndSettle();
        final full = find.byKey(ValueKey('$prefix-full-catalogue-list'));
        expect(full, findsOneWidget);
        expectCompleteRiceEta(full);
        if (id == 'w-rice-50kg') {
          await captureR66Visual(tester, '025-rice-full-text-$scale');
        }
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

final class _CollectionHeaderCommerce implements BuyV2CommerceAdapter {
  _CollectionHeaderCommerce(this.products);
  final List<BuyV2Product> products;

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: products,
  );

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: true,
        enabled: false,
        customerMessage: '',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected commerce call in Store header test');
}

final class _CollectionHeaderFacts implements BuyV2ProductFactsAdapter {
  _CollectionHeaderFacts(this.now);
  final DateTime Function() now;
  BuyV2StoreCollectionCapability? capability;
  bool stale = false;
  bool wrongProduct = false;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final base = const BuyV2CatalogueProductFactsAdapter().snapshotFor(product);
    return BuyV2ProductFactsSnapshot(
      productId: wrongProduct ? 'unrelated-product' : product.id,
      price: base.price,
      deliveryPromise: base.deliveryPromise,
      partner: base.partner,
      orderabilityLabel: base.orderabilityLabel,
      sourceId: 'collection-header-v1',
      storeOperatingState: BuyV2StoreOperatingState.open,
      storeCollection: capability,
      observedAt: now(),
      stale: stale,
    );
  }
}

final class _CollectionHeaderFixture {
  _CollectionHeaderFixture(this.core, this.session, this.facts, this.products);
  final BuySession core;
  final BuyV2Session session;
  final _CollectionHeaderFacts facts;
  final List<BuyV2Product> products;

  BuyV2StoreCollectionCapability supported({DateTime? validUntil}) =>
      BuyV2StoreCollectionCapability(
        storeId: 'collection-store-a',
        supportsCollection: true,
        sourceId: 'collection-header-v1',
        observedAt: facts.now(),
        validUntil: validUntil ?? facts.now().add(const Duration(hours: 1)),
      );

  static Future<_CollectionHeaderFixture> create(
    WidgetTester tester, {
    DateTime Function()? now,
  }) async {
    final core = BuySession();
    final clock = now ?? tester.binding.clock.now;
    final facts = _CollectionHeaderFacts(clock);
    BuyV2Product seed(String id) =>
        BuyV2Catalogue.allProducts.firstWhere((product) => product.id == id);
    final products = [
      seed('s-milk-500ml').copyWith(storeId: 'collection-store-a'),
      seed('s-milk').copyWith(storeId: 'collection-store-a'),
      seed(
        's-milk',
      ).copyWith(id: 'other-branch-milk', storeId: 'collection-store-b'),
    ];
    final session = BuyV2Session(
      core: core,
      commerceAdapter: _CollectionHeaderCommerce(products),
      productFactsAdapter: facts,
      catalogueNow: clock,
      reviewDataEnabled: false,
    );
    final result = _CollectionHeaderFixture(core, session, facts, products);
    facts.capability = result.supported();
    await session.restoreCommerce();
    return result;
  }

  void dispose() {
    session.dispose();
    core.dispose();
  }
}

Widget _app(BuyV2Session session, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: MoolTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: r66VisualCaptureRoot(child!),
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
