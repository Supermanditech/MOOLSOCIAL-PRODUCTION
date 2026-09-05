import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );
      },
      home: BuyV2Screen(session: session),
    );
  }

  Future<void> openFirstProduct(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(app(session, disableAnimations: disableAnimations));
    await tester.pumpAndSettle();
    session.openProduct(session.visibleProducts.first.id);
    await tester.pumpAndSettle();
  }

  for (final offers in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R66 Compare returns through source offers $offers at $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(scale == 2 ? 320 : 390, 844);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          final sourceId = offers ? 'w-oil' : 's-milk';
          final alternateId = offers ? 'w-oil-10l' : 's-milk-500ml';
          session.addProduct(sourceId);
          final quantity = session.quantityFor(sourceId);
          await tester.pumpWidget(app(session, textScale: scale));
          await tester.pumpAndSettle();
          if (offers) {
            await tester.tap(
              find.byKey(const ValueKey('buy-local-tab-offers')),
            );
            await tester.pumpAndSettle();
          } else {
            await tester.tap(find.byKey(const ValueKey('buy-search-control')));
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byKey(const ValueKey('buy-search-field')),
              'milk',
            );
            await tester.pumpAndSettle();
          }
          final sourceCard = find.byKey(ValueKey('buy-product-$sourceId'));
          await tester.ensureVisible(sourceCard);
          await tester.tap(sourceCard);
          await tester.pumpAndSettle();
          expect(session.selectedProductId, sourceId);
          final compare = find.text('Compare');
          await tester.scrollUntilVisible(
            compare,
            180,
            scrollable: find
                .descendant(
                  of: find.byKey(PageStorageKey('buy-product-$sourceId')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.tap(compare);
          await tester.pumpAndSettle();
          final alternate = find.byKey(
            ValueKey('buy-product-compare-view-$alternateId'),
          );
          await tester.scrollUntilVisible(
            alternate,
            180,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.tap(alternate);
          await tester.pumpAndSettle();
          expect(session.selectedProductId, alternateId);
          await tester.tap(
            find.byKey(const ValueKey('buy-compact-cart-indicator')),
          );
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.selectedProductId, alternateId);
          final comparedBack = find.descendant(
            of: find.byKey(PageStorageKey('buy-product-$alternateId')),
            matching: find.widgetWithText(
              InkWell,
              session.product(sourceId).title,
            ),
          );
          await tester.scrollUntilVisible(
            comparedBack,
            -200,
            scrollable: find
                .descendant(
                  of: find.byKey(PageStorageKey('buy-product-$alternateId')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          expect(tester.getSize(comparedBack).height, greaterThanOrEqualTo(44));
          if (scale == 2) {
            await tester.tap(comparedBack);
          } else {
            await tester.binding.handlePopRoute();
          }
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.product);
          expect(session.selectedProductId, sourceId);
          expect(session.quantityFor(sourceId), quantity);
          final returnAction = find.descendant(
            of: find.byKey(PageStorageKey('buy-product-$sourceId')),
            matching: find.widgetWithText(InkWell, offers ? 'Offers' : 'Shop'),
          );
          await tester.scrollUntilVisible(
            returnAction,
            -240,
            scrollable: find
                .descendant(
                  of: find.byKey(PageStorageKey('buy-product-$sourceId')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.tap(returnAction);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          expect(session.destination, BuyV2Destination.shop);
          if (offers) {
            final collection = find.byKey(const PageStorageKey('buy-offers'));
            expect(collection, findsOneWidget);
            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('buy-offers-publisher-summary')),
              -200,
              scrollable: find
                  .descendant(of: collection, matching: find.byType(Scrollable))
                  .first,
            );
          }
          expect(
            find.byKey(const ValueKey('buy-offers-publisher-summary')),
            offers ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final wholesale in [false, true]) {
    testWidgets('R66 compared product isolates nested Store $wholesale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final sourceId = wholesale ? 'w-oil' : 's-milk';
      final alternateId = wholesale ? 'w-oil-10l' : 's-milk-500ml';
      await tester.pumpWidget(app(session, textScale: 2));
      session.openProduct(sourceId);
      await tester.pumpAndSettle();

      Future<void> compareTo(String id) async {
        final currentId = session.selectedProductId!;
        final page = find.byKey(PageStorageKey('buy-product-$currentId')).last;
        final compare = find.descendant(
          of: page,
          matching: find.text('Compare'),
        );
        await tester.scrollUntilVisible(
          compare,
          200,
          scrollable: find
              .descendant(of: page, matching: find.byType(Scrollable))
              .first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(compare);
        await tester.pumpAndSettle();
        expect(compare.hitTestable(), findsOneWidget);
        await tester.tap(compare);
        await tester.pumpAndSettle();
        final option = find.byKey(ValueKey('buy-product-compare-view-$id'));
        await tester.scrollUntilVisible(
          option,
          180,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(option);
        await tester.pumpAndSettle();
      }

      await compareTo(alternateId);
      final store = find.byKey(
        ValueKey(
          '${wholesale ? 'buy-wholesale-store-action' : 'buy-shop-seller-action'}-$alternateId',
        ),
      );
      final page = find.byKey(PageStorageKey('buy-product-$alternateId'));
      await tester.scrollUntilVisible(
        store,
        220,
        scrollable: find
            .descendant(of: page, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(store);
      await tester.pumpAndSettle();
      expect(store.hitTestable(), findsOneWidget);
      await tester.tap(store);
      await tester.pumpAndSettle();
      final prefix = wholesale ? 'buy-wholesale-supplier' : 'buy-shop-seller';
      final sheet = find.byKey(ValueKey('$prefix-sheet-$alternateId'));
      final card = find.descendant(
        of: sheet,
        matching: find.byKey(ValueKey('buy-product-$alternateId')),
      );
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(
        session.canReturnToComparedProduct,
        isFalse,
        reason: 'A new Store product must not inherit its parent comparison',
      );
      await compareTo(sourceId);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.selectedProductId, alternateId);
      expect(session.canReturnToComparedProduct, isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(session.selectedProductId, alternateId);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.canReturnToComparedProduct, isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.selectedProductId, sourceId);
      expect(session.canReturnToComparedProduct, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  test('R66 comparison return survives a nested Cart product', () {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    session.addProduct('w-oil');
    session.openProduct('w-oil');
    session.openProduct('w-oil-10l', preserveComparisonOrigin: true);
    session.openCart(scope: BuyV2CartScope.wholesale);
    session.openProduct('w-oil');
    session.goBack();
    expect(session.view, BuyV2View.cart);
    session.goBack();
    expect(session.selectedProductId, 'w-oil-10l');
    expect(session.canReturnToComparedProduct, isTrue);
    session.goBack();
    expect(session.selectedProductId, 'w-oil');
    session.goBack();
    expect(session.view, BuyV2View.catalogue);
    expect(session.destination, BuyV2Destination.shop);
  });

  test(
    'R66 comparison validates IDs and keeps ordinary variant navigation',
    () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      session.openProduct('s-milk');
      expect(
        session.openProduct('missing', preserveComparisonOrigin: true),
        isFalse,
      );
      expect(session.selectedProductId, 's-milk');
      expect(session.canReturnToComparedProduct, isFalse);
      expect(
        session.openProduct('s-milk', preserveComparisonOrigin: true),
        isTrue,
      );
      expect(session.canReturnToComparedProduct, isFalse);
      session.selectProductVariant('s-milk-500ml');
      expect(session.canReturnToComparedProduct, isFalse);
      session.openProduct('s-milk', preserveComparisonOrigin: true);
      expect(session.canReturnToComparedProduct, isTrue);
      final origin = session.takeProductComparisonOrigin();
      expect(origin, ['s-milk-500ml']);
      expect(session.canReturnToComparedProduct, isFalse);
      session.restoreProductComparisonOrigin([...origin, 'missing']);
      expect(session.productReturnLabel, session.product('s-milk-500ml').title);
      session.closeProduct();
      expect(session.selectedProductId, 's-milk-500ml');
      session.openProduct('s-milk', preserveComparisonOrigin: true);
      session.openDestination(BuyV2Destination.wholesale);
      session.openProduct('w-oil');
      expect(session.canReturnToComparedProduct, isFalse);
      session.closeProduct();
      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.view, BuyV2View.catalogue);
    },
  );

  Future<void> pinchOpen(WidgetTester tester, Finder zoomOwner) async {
    final center = tester.getCenter(zoomOwner);
    final left = await tester.startGesture(center - const Offset(24, 0));
    final right = await tester.startGesture(center + const Offset(24, 0));
    await tester.pump();
    await left.moveTo(center - const Offset(72, 0));
    await right.moveTo(center + const Offset(72, 0));
    await tester.pump();
    await left.up();
    await right.up();
    await tester.pump();
  }

  for (final productId in ['s-tomato', 'w-notebook']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R66 order product Back is contextual for $productId at $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          session.addProduct(productId);
          session.openCart();
          expect(session.openCheckout(), isTrue);
          expect(session.confirmOrder(), isTrue);
          final order = session.confirmedOrders.single;
          await tester.pumpWidget(app(session, textScale: scale));
          expect(session.openTracking(order.id), isTrue);
          await tester.pumpAndSettle();
          final items = find.text('Items');
          await tester.scrollUntilVisible(
            items,
            240,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.tap(items);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.orderItems);
          for (final androidBack in [false, true]) {
            final sku = find.byKey(ValueKey('buy-order-product-$productId'));
            await tester.scrollUntilVisible(
              sku,
              160,
              scrollable: find.byType(Scrollable).last,
            );
            await tester.tap(sku);
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.product);
            final back = find.widgetWithText(InkWell, 'Order items');
            expect(back, findsOneWidget);
            expect(tester.getSize(back).height, greaterThanOrEqualTo(44));
            expect(tester.getRect(back).right, lessThanOrEqualTo(320));
            if (androidBack) {
              await tester.binding.handlePopRoute();
            } else {
              await tester.tap(back);
            }
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.orderItems);
            expect(session.selectedOrderId, order.id);
            expect(session.selectedOrder.total, order.total);
            expect(session.quantityFor(productId), 0);
            expect(find.text('Items in this order'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
          session.openDestination(session.product(productId).destination);
          session.openProduct(productId);
          await tester.pumpAndSettle();
          expect(find.widgetWithText(InkWell, 'Order items'), findsNothing);
          expect(
            find.descendant(
              of: find.byKey(PageStorageKey('buy-product-$productId')),
              matching: find.text(session.product(productId).destination.label),
            ),
            findsOneWidget,
          );
        },
      );
    }
  }

  for (final productId in ['s-tomato', 'w-notebook']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R66 Saved return preserves $productId at text $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        session.toggleSaved(productId);
        session.addProduct(productId);
        await tester.pumpWidget(app(session, textScale: scale));
        await tester.pumpAndSettle();
        final product = session.product(productId);
        session.openDestination(product.destination);
        await tester.pumpAndSettle();
        final savedToggle = find.byKey(
          const ValueKey('buy-saved-products-button'),
        );
        await tester.tap(savedToggle);
        await tester.pumpAndSettle();
        final savedHeading = product.destination == BuyV2Destination.wholesale
            ? 'Saved for Wholesale'
            : 'Saved in Shop';
        expect(find.text(savedHeading), findsOneWidget);

        for (final throughCart in [false, true]) {
          final tile = find.byKey(ValueKey('buy-product-$productId'));
          await tester.ensureVisible(tile);
          await tester.tap(tile);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.product);
          if (throughCart) {
            await tester.tap(
              find.byKey(const ValueKey('buy-compact-cart-indicator')),
            );
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.cart);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.product);
          }
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          expect(session.destination, product.destination);
          expect(find.text(savedHeading), findsOneWidget);
          expect(session.isSaved(productId), isTrue);
        }
        await tester.tap(savedToggle);
        await tester.pumpAndSettle();
        expect(find.text(savedHeading), findsNothing);
        await tester.tap(savedToggle);
        await tester.pumpAndSettle();
        expect(find.text(savedHeading), findsOneWidget);
        session.openDestination(
          product.destination == BuyV2Destination.shop
              ? BuyV2Destination.wholesale
              : BuyV2Destination.shop,
        );
        await tester.pumpAndSettle();
        session.openDestination(product.destination);
        await tester.pumpAndSettle();
        expect(find.text(savedHeading), findsNothing);
        expect(session.isSaved(productId), isTrue);
        expect(session.quantityFor(productId), 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('R66 Saved return retains the horizontal browsing position', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final products = session.visibleProducts.take(6).toList();
    expect(products.length, greaterThanOrEqualTo(4));
    for (final product in products) {
      session.toggleSaved(product.id);
    }
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
    await tester.pumpAndSettle();
    final lane = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.right,
        )
        .last;
    final tile = find.byKey(ValueKey('buy-product-${products[2].id}'));
    await tester.scrollUntilVisible(tile, 200, scrollable: lane);
    await tester.pumpAndSettle();
    final before = tester.state<ScrollableState>(lane).position.pixels;
    expect(before, greaterThan(0));
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(session.selectedProductId, products[2].id);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Saved in Shop'), findsOneWidget);
    expect(
      tester.state<ScrollableState>(lane).position.pixels,
      closeTo(before, 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail media zoom is explicit, bounded and resettable', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await openFirstProduct(tester, session);
    final product = session.selectedProduct!;
    final zoom = find.byKey(ValueKey('buy-product-media-zoom-${product.id}'));
    final reset = find.byKey(ValueKey('buy-product-media-reset-${product.id}'));

    expect(zoom, findsOneWidget);
    expect(reset, findsNothing);
    expect(
      find.byKey(const ValueKey('buy-product-gallery-count')),
      findsNothing,
    );

    await pinchOpen(tester, zoom);

    expect(reset, findsOneWidget);
    final viewer = tester.widget<InteractiveViewer>(zoom);
    expect(viewer.minScale, 1);
    expect(viewer.maxScale, 2.5);
    expect(viewer.panEnabled, isTrue);
    expect(session.selectedProduct, product);
    expect(session.cartLines, isEmpty);

    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(reset, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one-finger drag at 1x remains owned by product page scroll', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await openFirstProduct(tester, session);
    final product = session.selectedProduct!;
    final zoom = find.byKey(ValueKey('buy-product-media-zoom-${product.id}'));
    final reset = find.byKey(ValueKey('buy-product-media-reset-${product.id}'));
    final before = tester.getTopLeft(zoom).dy;

    await tester.drag(zoom, const Offset(0, -180));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(zoom).dy, lessThan(before));
    expect(reset, findsNothing);
    expect(session.selectedProduct, product);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion resets zoom immediately without route change', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await openFirstProduct(tester, session, disableAnimations: true);
    final product = session.selectedProduct!;
    final zoom = find.byKey(ValueKey('buy-product-media-zoom-${product.id}'));
    final reset = find.byKey(ValueKey('buy-product-media-reset-${product.id}'));

    await pinchOpen(tester, zoom);
    expect(reset, findsOneWidget);
    await tester.tap(reset);
    await tester.pumpAndSettle();

    expect(reset, findsNothing);
    expect(session.selectedProduct, product);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('decoded-frame fade is scoped to the truthful detail packshot', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await openFirstProduct(tester, session);
    final product = session.selectedProduct!;
    final packshot = find.byKey(ValueKey('buy-product-packshot-${product.id}'));
    final images = tester.widgetList<Image>(
      find.descendant(of: packshot, matching: find.byType(Image)),
    );

    expect(images, isNotEmpty);
    final image = images.single;
    final frameBuilder = image.frameBuilder;
    expect(frameBuilder, isNotNull);
    final imageContext = tester.element(
      find.descendant(of: packshot, matching: find.byType(Image)).first,
    );
    final pending =
        frameBuilder!(
              imageContext,
              const SizedBox(key: ValueKey('decoded-child')),
              null,
              false,
            )
            as AnimatedOpacity;
    final decoded =
        frameBuilder(
              imageContext,
              const SizedBox(key: ValueKey('decoded-child')),
              0,
              false,
            )
            as AnimatedOpacity;
    expect(pending.opacity, 0);
    expect(decoded.opacity, 1);
    expect(decoded.duration, const Duration(milliseconds: 180));
    expect(
      find.byKey(ValueKey('buy-packshot-decoded-frame-${product.id}')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('product detail continues directly through genuine products', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    session.updateQuery('tomato');
    final origin = session.visibleProducts.first;
    await tester.pumpWidget(app(session));
    session.openProduct(origin.id);
    await tester.pumpAndSettle();

    final firstNext = session.productContinuationsFor(origin).first;
    final firstSection = find.byKey(
      ValueKey('buy-product-continuations-${origin.id}'),
    );
    final firstCard = find.byKey(
      ValueKey('buy-product-continuation-${firstNext.id}'),
    );
    await tester.scrollUntilVisible(
      find.text('You may also like'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        ValueKey('buy-product-continuation-${firstNext.id}'),
        skipOffstage: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(firstSection, findsOneWidget);
    expect(find.text('You may also like'), findsOneWidget);
    expect(find.text('More products selected for you'), findsOneWidget);
    expect(
      find.byKey(ValueKey('buy-product-continuation-${origin.id}')),
      findsNothing,
    );
    final firstCardSemantics = tester
        .getSemantics(firstCard)
        .getSemanticsData();
    expect(firstCardSemantics.label, 'View ${firstNext.title} product details');
    expect(firstCardSemantics.hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(firstCard);
    await tester.pumpAndSettle();
    expect(session.selectedProductId, firstNext.id);
    expect(session.view, BuyV2View.product);

    final secondNext = session.productContinuationsFor(firstNext).first;
    final secondSection = find.byKey(
      ValueKey('buy-product-continuations-${firstNext.id}'),
    );
    final secondCard = find.byKey(
      ValueKey('buy-product-continuation-${secondNext.id}'),
    );
    await tester.scrollUntilVisible(
      find.text('You may also like'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        ValueKey('buy-product-continuation-${secondNext.id}'),
        skipOffstage: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(secondSection, findsOneWidget);
    await tester.tap(secondCard);
    await tester.pumpAndSettle();

    expect(session.selectedProductId, secondNext.id);
    session.closeProduct();
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.shop);
    expect(session.view, BuyV2View.catalogue);
    expect(session.query, 'tomato');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Medicine continuation is isolated and not medical advice', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openDestination(BuyV2Destination.medicine);
    session.openProduct(session.visibleProducts.first.id);
    await tester.pumpAndSettle();
    final product = session.selectedProduct!;
    final section = find.byKey(
      ValueKey('buy-product-continuations-${product.id}'),
    );
    await tester.scrollUntilVisible(
      find.text('More Medicine essentials'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(section, findsOneWidget);

    expect(find.text('More Medicine essentials'), findsOneWidget);
    expect(
      find.text('From the Medicine catalogue · not medical advice'),
      findsOneWidget,
    );
    expect(
      session.productContinuationsFor(product),
      everyElement(
        predicate<BuyV2Product>(
          (candidate) =>
              candidate.destination == BuyV2Destination.medicine &&
              candidate.id != product.id,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wholesale continuation uses only current trade-pack products', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openDestination(BuyV2Destination.wholesale);
    session.openProduct(session.visibleProducts.first.id);
    await tester.pumpAndSettle();
    final product = session.selectedProduct!;
    await tester.scrollUntilVisible(
      find.text('More for business restocking'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('More for business restocking'), findsOneWidget);
    expect(find.text('Trade packs for your next order'), findsOneWidget);
    expect(
      session.productContinuationsFor(product),
      everyElement(
        predicate<BuyV2Product>(
          (candidate) =>
              candidate.destination == BuyV2Destination.wholesale &&
              candidate.id != product.id,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('continuation is static with reduced motion at 320px and 140%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(
      app(session, disableAnimations: true, textScale: 1.4),
    );
    session.openProduct(session.visibleProducts.first.id);
    await tester.pumpAndSettle();
    final product = session.selectedProduct!;
    final section = find.byKey(
      ValueKey('buy-product-continuations-${product.id}'),
    );
    await tester.scrollUntilVisible(
      find.text('You may also like'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(section, findsOneWidget);
    final lane = find.byKey(
      ValueKey('buy-product-continuation-lane-${product.id}'),
    );
    expect(lane, findsOneWidget);
    expect(tester.getSize(lane).width, lessThanOrEqualTo(282));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
