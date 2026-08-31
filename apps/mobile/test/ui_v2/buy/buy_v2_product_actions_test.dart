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

    expect(uri.path, '/app/chat/thread/shop-partner');
    expect(uri.queryParameters['draft'], contains('Toned fresh milk'));
    expect(uri.queryParameters['draft'], contains('2 × 1 L pouches'));
    expect(uri.queryParameters['directReturn'], 'true');
    final returnUri = Uri.parse(uri.queryParameters['return']!);
    expect(returnUri.path, '/app/buy');
    expect(returnUri.queryParameters['sub'], 'shop');
    expect(returnUri.queryParameters['view'], 'product');
    expect(returnUri.queryParameters['product'], 's-milk-2l');
  });

  test('Buy now reaches scoped Checkout and Back restores exact product', () {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk-2l'), isTrue);

    expect(session.buyProductNow('s-milk-2l'), isTrue);
    expect(session.view, BuyV2View.checkout);
    expect(session.checkoutScope, BuyV2CartScope.shop);
    expect(session.quantityFor('s-milk-2l'), 1);
    expect(session.quantityFor('s-milk'), 0);

    session.goBack();
    expect(session.view, BuyV2View.cart);
    session.goBack();
    expect(session.view, BuyV2View.product);
    expect(session.destination, BuyV2Destination.shop);
    expect(session.selectedProductId, 's-milk-2l');
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

    await tester.tap(
      find.byKey(const ValueKey('buy-product-action-save-s-milk')),
    );
    await tester.pumpAndSettle();
    expect(session.isSaved('s-milk'), isTrue);
    expect(
      find.byKey(const ValueKey('buy-product-action-saved-s-milk')),
      findsOneWidget,
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

    await tester.tap(
      find.byKey(const ValueKey('buy-product-action-ask-seller-s-milk')),
    );
    await tester.pumpAndSettle();
    expect(chatOpened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Buy now remains reachable and Back restores product at 320', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

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
    final buyNow = find.byKey(const ValueKey('buy-product-buy-now-s-milk'));
    await tester.dragUntilVisible(buyNow, productScroll, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(buyNow);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.checkout);
    expect(session.quantityFor('s-milk'), 1);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, 's-milk');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wholesale Buy now preserves MOQ and exact product return', (
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
    final buyNow = find.byKey(
      const ValueKey('buy-wholesale-buy-now-w-rice-50kg'),
    );
    expect(buyNow, findsOneWidget);
    await tester.tap(buyNow);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.checkout);
    expect(session.checkoutScope, BuyV2CartScope.wholesale);
    expect(session.quantityFor('w-rice-50kg'), 1);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, 'w-rice-50kg');
    expect(tester.takeException(), isNull);
  });
}
