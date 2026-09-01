import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_chat_route_adapter.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('product question opens shared Chat with exact product return', () {
    final product = BuyV2Catalogue.allProducts.firstWhere(
      (candidate) => candidate.id == 's-milk-2l',
    );
    final location = const BuyV2ChatRouteAdapter().productQuestionLocationFor(
      product: product,
    );
    final uri = Uri.parse(location);

    expect(uri.path, startsWith('/app/chat/thread/shop-partner-shop-'));
    expect(uri.queryParameters['supplier'], product.seller);
    expect(uri.queryParameters['draft'], contains('Toned fresh milk'));
    expect(uri.queryParameters['draft'], contains('2 × 1 L pouches'));
    expect(uri.queryParameters['directReturn'], 'true');
    final returnUri = Uri.parse(uri.queryParameters['return']!);
    expect(returnUri.path, '/app/buy');
    expect(returnUri.queryParameters['sub'], 'shop');
    expect(returnUri.queryParameters['view'], 'product');
    expect(returnUri.queryParameters['product'], 's-milk-2l');
  });

  test('Cart keeps the exact product origin before checkout', () {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk-2l'), isTrue);

    expect(session.addProduct('s-milk-2l'), isTrue);
    expect(session.view, BuyV2View.product);
    expect(session.quantityFor('s-milk-2l'), 1);
    expect(session.quantityFor('s-milk'), 0);

    session.openCart();
    expect(session.view, BuyV2View.cart);
    session.goBack();
    expect(session.view, BuyV2View.product);
    expect(session.destination, BuyV2Destination.shop);
    expect(session.selectedProductId, 's-milk-2l');
  });

  testWidgets('Shop Wholesale and Offers use one Cart-first product action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    for (final entry
        in <({String productId, BuyV2Destination destination, bool offers})>[
          (
            productId: 's-milk',
            destination: BuyV2Destination.shop,
            offers: false,
          ),
          (
            productId: 'w-onion',
            destination: BuyV2Destination.wholesale,
            offers: false,
          ),
          (
            productId: 's-milk',
            destination: BuyV2Destination.shop,
            offers: true,
          ),
        ]) {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: entry.destination,
            initialOffersActive: entry.offers,
            initialView: BuyV2View.product,
            productId: entry.productId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find
          .descendant(
            of: find.byKey(PageStorageKey('buy-product-${entry.productId}')),
            matching: find.byType(Scrollable),
          )
          .first;
      final add = find.byKey(
        ValueKey('buy-product-primary-${entry.productId}'),
      );
      await tester.scrollUntilVisible(add, 220, scrollable: scrollable);
      await tester.pumpAndSettle();

      expect(add, findsOneWidget);
      expect(find.text('Buy now'), findsNothing);
      expect(
        tester
            .getSemantics(add)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(tester.takeException(), isNull, reason: '$entry');

      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
      core.dispose();
    }
  });

  testWidgets('product actions fit, compare and retain exact Back at 320', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    var chatOpened = false;
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.shop,
          initialView: BuyV2View.product,
          productId: 's-milk',
          onOpenChat: () => chatOpened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final productScroll = find
        .descendant(
          of: find.byKey(const PageStorageKey('buy-product-s-milk')),
          matching: find.byType(Scrollable),
        )
        .first;
    final actions = find.byKey(
      const ValueKey('buy-product-quick-actions-s-milk'),
    );
    await tester.scrollUntilVisible(actions, 180, scrollable: productScroll);
    expect(actions, findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-product-action-save-s-milk')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-product-action-share-s-milk')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-product-action-compare-s-milk')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-product-action-ask-seller-s-milk')),
      findsOneWidget,
    );
    for (final label in const ['Save', 'Share', 'Compare', 'Ask seller']) {
      final semanticAction = find.descendant(
        of: actions,
        matching: find.bySemanticsLabel(label),
      );
      expect(semanticAction, findsOneWidget);
      expect(
        tester
            .getSemantics(semanticAction)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
    }

    final save = find.byKey(const ValueKey('buy-product-action-save-s-milk'));
    await tester.ensureVisible(save);
    await tester.drag(productScroll, const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(session.isSaved('s-milk'), isTrue);
    expect(
      find.byKey(const ValueKey('buy-product-action-saved-s-milk')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('buy-product-action-compare-s-milk')),
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-product-action-compare-s-milk')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Compare products'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-product-compare-s-milk')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-product-compare-s-milk-500ml')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('buy-product-action-ask-seller-s-milk')),
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-product-action-ask-seller-s-milk')),
    );
    await tester.pumpAndSettle();
    expect(chatOpened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'manufacturer Chat action stays readable and fails safely at 140 percent',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final product = BuyV2Catalogue.products.firstWhere(
        (candidate) =>
            candidate.destination == BuyV2Destination.wholesale &&
            candidate.sellerType.toLowerCase().contains('manufacturer'),
      );
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct(product.id), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: product.destination,
            initialView: BuyV2View.product,
            productId: product.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final productScroll = find
          .descendant(
            of: find.byKey(PageStorageKey('buy-product-${product.id}')),
            matching: find.byType(Scrollable),
          )
          .first;
      final actions = find.byKey(
        ValueKey('buy-product-quick-actions-${product.id}'),
      );
      final ask = find.byKey(
        ValueKey('buy-product-action-ask-manufacturer-${product.id}'),
      );
      await tester.scrollUntilVisible(ask, 220, scrollable: productScroll);
      await tester.drag(productScroll, const Offset(0, -160));
      await tester.pumpAndSettle();

      expect(actions, findsOneWidget);
      expect(tester.getSize(actions).height, 56);
      expect(find.bySemanticsLabel('Ask manufacturer'), findsOneWidget);
      await tester.tap(ask);
      await tester.pumpAndSettle();
      expect(
        session.notice,
        'Supplier Chat is unavailable right now. Your product is unchanged.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Cart action remains reachable and Back restores product at 320',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-milk'), isTrue);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: BuyV2Destination.shop,
            initialView: BuyV2View.product,
            productId: 's-milk',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final productScroll = find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first;
      final add = find.byKey(const ValueKey('buy-product-primary-s-milk'));
      await tester.dragUntilVisible(add, productScroll, const Offset(0, -220));
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.product);
      expect(session.quantityFor('s-milk'), 1);

      session.openCart();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.product);
      expect(session.selectedProductId, 's-milk');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Wholesale Cart action preserves MOQ and exact product return', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('w-rice-50kg'), isTrue);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.wholesale,
          initialView: BuyV2View.product,
          productId: 'w-rice-50kg',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final add = find.byKey(const ValueKey('buy-product-primary-w-rice-50kg'));
    expect(add, findsOneWidget);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.quantityFor('w-rice-50kg'), 1);

    session.openCart();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, 'w-rice-50kg');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shop seller products open and return to the exact product', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) =>
          candidate.destination == BuyV2Destination.shop &&
          session.sellerContinuationsFor(candidate).isNotEmpty,
    );
    expect(session.openProduct(product.id), isTrue);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.shop,
          initialView: BuyV2View.product,
          productId: product.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final productScroll = find
        .descendant(
          of: find.byKey(PageStorageKey('buy-product-${product.id}')),
          matching: find.byType(Scrollable),
        )
        .first;
    final seller = find.byKey(ValueKey('buy-shop-seller-action-${product.id}'));
    await tester.scrollUntilVisible(seller, 220, scrollable: productScroll);
    await tester.ensureVisible(seller);
    await tester.pumpAndSettle();
    for (var attempt = 0; attempt < 3; attempt += 1) {
      final rect = tester.getRect(seller);
      if (rect.top >= 0 && rect.bottom <= 600) break;
      await tester.drag(productScroll, Offset(0, rect.top < 0 ? 180 : -180));
      await tester.pumpAndSettle();
    }
    expect(tester.getRect(seller).top, greaterThanOrEqualTo(0));
    expect(tester.getRect(seller).bottom, lessThanOrEqualTo(600));
    await tester.tap(seller);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('buy-shop-seller-sheet-${product.id}')),
      findsOneWidget,
    );
    expect(
      find.text('Browse this store’s available products and delivery times'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-horizontal-product-grid')),
      findsOneWidget,
    );
    final continuation = session.sellerContinuationsFor(product).first;
    expect(
      find.byKey(ValueKey('buy-product-${continuation.id}')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, product.id);
    expect(tester.takeException(), isNull);
  });
}
