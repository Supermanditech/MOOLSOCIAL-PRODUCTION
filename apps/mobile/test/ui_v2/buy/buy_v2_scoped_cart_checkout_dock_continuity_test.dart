import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

class _R66StoreStatusSession extends BuyV2Session {
  _R66StoreStatusSession({required super.core, required this.quiet}) {
    order = visibleOrders.firstWhere(
      (value) =>
          value.destination ==
          (quiet ? BuyV2Destination.wholesale : BuyV2Destination.shop),
    );
  }

  final bool quiet;
  late final BuyV2Order order;

  @override
  BuyV2Order? get activeQuickDeliveryOrder => quiet ? null : order;

  @override
  BuyV2Order? get activeQuietDeliveryOrder => quiet ? order : null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settleVisibleImages(WidgetTester tester) async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await tester.runAsync(
        () => precacheImage(image.image, tester.element(find.byWidget(image))),
      );
    }
    await tester.pumpAndSettle();
  }

  Widget app(
    BuyV2Session session, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool reducedMotion = false,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) {
    return RepaintBoundary(
      key: const ValueKey('r66-cart-feedback-capture'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: size,
            padding: safeArea,
            viewPadding: safeArea,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: child!,
        ),
        home: BuyV2Screen(
          session: session,
          initialDestination: session.destination,
          initialView: session.view,
          initialCartScope: session.cartScope,
        ),
      ),
    );
  }

  Future<void> capture(
    WidgetTester tester,
    String name, {
    bool store = false,
    bool obstruction = false,
  }) async {
    if (!(obstruction
        ? const bool.fromEnvironment('BUY_R66_CART_OBSTRUCTION_CAPTURE')
        : store
        ? const bool.fromEnvironment('BUY_R66_STORE_RETURN_CAPTURE')
        : const bool.fromEnvironment('BUY_R66_CART_FEEDBACK_CAPTURE'))) {
      return;
    }
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('r66-cart-feedback-capture')),
    );
    boundary.markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      final directory = Directory(
        obstruction
            ? 'build/r66-cart-obstruction-v3-20260905'
            : store
            ? 'build/r66-store-return-v2-20260905'
            : 'build/r66-cart-feedback-v1-20260905',
      );
      await directory.create(recursive: true);
      final file = File('${directory.path}/$name.png');
      if (await file.exists()) throw StateError('Capture already exists');
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  }

  BuyV2Product productFor(BuyV2Destination destination) =>
      BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == destination && !product.requiresPrescription,
      );

  for (final mixed in [false, true]) {
    for (final id in ['s-tomato', 's-atta', 'w-tomato', 'w-rice']) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'R66 floating Cart avoids product controls $id at $scale mixed=$mixed',
          (tester) async {
            final size = Size(scale == 1 ? 360 : 320, 800);
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            final product = session.product(id);
            final retainedId = product.destination == BuyV2Destination.shop
                ? 'w-tomato'
                : 's-tomato';
            if (mixed) expect(session.addProduct(retainedId), isTrue);
            final retained = session.quantityFor(retainedId);
            session.openDestination(product.destination);
            if (product.destination == BuyV2Destination.shop) {
              session.chooseShopSaleType(
                id == 's-tomato'
                    ? BuyV2ShopSaleType.quickDelivery
                    : BuyV2ShopSaleType.courier,
              );
            } else {
              session.chooseWholesaleSaleType(
                id == 'w-rice'
                    ? BuyV2WholesaleSaleType.bulk
                    : BuyV2WholesaleSaleType.wholesale,
              );
            }
            session.openProduct(id);
            await tester.pumpWidget(app(session, size: size, textScale: scale));
            await tester.pumpAndSettle();
            final allActions = find.byKey(
              ValueKey('buy-product-action-slot-$id'),
            );
            final productScroll = find
                .descendant(
                  of: find.byType(BuyV2ProductView),
                  matching: find.byType(Scrollable),
                )
                .first;
            for (
              var attempt = 0;
              attempt < 30 && allActions.evaluate().isEmpty;
              attempt++
            ) {
              await tester.drag(productScroll, const Offset(0, -240));
              await tester.pumpAndSettle();
            }
            expect(allActions, findsWidgets);
            final actions = allActions.first;
            await tester.ensureVisible(actions);
            await tester.pumpAndSettle();
            final scroll = tester.state<ScrollableState>(
              find
                  .descendant(
                    of: find.byType(BuyV2ProductView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            final overlay = find.byKey(
              const ValueKey('buy-navigation-overlay-stack'),
            );
            final targetBottom = tester.getRect(overlay).bottom - 16;
            scroll.position.jumpTo(
              (scroll.position.pixels +
                      tester.getRect(actions).bottom -
                      targetBottom)
                  .clamp(0.0, scroll.position.maxScrollExtent),
            );
            await tester.pumpAndSettle();
            final add = find.descendant(
              of: actions,
              matching: find.byKey(ValueKey('buy-product-primary-$id')),
            );
            await tester.tap(add);
            await tester.pump();
            expect(session.quantityFor(id), product.minimumOrder);
            final cart = find.byKey(
              const ValueKey('buy-mini-cart-drag-handle'),
            );
            expect(cart, findsOneWidget);
            final increase = find.descendant(
              of: actions,
              matching: find.byTooltip('Add one'),
            );
            expect(increase, findsOneWidget);
            expect(
              tester.getRect(cart).overlaps(tester.getRect(increase)),
              isFalse,
            );
            await tester.pumpAndSettle();
            void expectRegionsClear() {
              for (final region
                  in find.byType(BuyV2CartAvoidanceRegion).evaluate()) {
                final rect = tester.getRect(
                  find.byElementPredicate((element) => element == region),
                );
                if (rect.overlaps(tester.getRect(overlay))) {
                  expect(tester.getRect(cart).overlaps(rect), isFalse);
                }
              }
            }

            expectRegionsClear();
            await capture(
              tester,
              '$id-$scale-$mixed-default',
              obstruction: true,
            );
            await tester.tapAt(tester.getCenter(increase));
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.product);
            expect(session.quantityFor(id), product.minimumOrder + 1);
            expect(session.quantityFor(retainedId), retained);
            for (final delta in [32.0, -64.0, 32.0]) {
              scroll.position.jumpTo(
                (scroll.position.pixels + delta).clamp(
                  0.0,
                  scroll.position.maxScrollExtent,
                ),
              );
              await tester.pumpAndSettle();
              expect(
                tester.getRect(cart).overlaps(tester.getRect(increase)),
                isFalse,
              );
              expectRegionsClear();
            }
            final beforeDrag = tester.getTopLeft(cart);
            await tester.drag(cart, const Offset(-48, -110));
            await tester.pumpAndSettle();
            final dragged = tester.getTopLeft(cart);
            expect(dragged.dx, lessThan(beforeDrag.dx - 25));
            expect(dragged.dy, lessThan(beforeDrag.dy - 75));
            final productOffset = scroll.position.pixels;
            await tester.tap(cart);
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.cart);
            expect(session.activeDockDestination, product.destination);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.product);
            expect(session.selectedProduct?.id, id);
            expect(tester.getTopLeft(cart), dragged);
            final restoredScroll = tester.state<ScrollableState>(
              find
                  .descendant(
                    of: find.byType(BuyV2ProductView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            expect(restoredScroll.position.pixels, closeTo(productOffset, .01));
            expect(session.quantityFor(id), product.minimumOrder + 1);
            expect(session.quantityFor(retainedId), retained);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  BuyV2Session mixedSession() {
    final session = BuyV2Session(core: BuySession());
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      expect(session.addProduct(productFor(destination).id), isTrue);
    }
    return session;
  }

  void expectConnectedOwner(
    WidgetTester tester,
    BuyV2Session session,
    BuyV2Destination expected,
  ) {
    expect(session.activeDockDestination, expected);
    expect(find.byKey(const Key('mool-home-launcher')), findsOneWidget);
    expect(find.byKey(const Key('buy-scoped-purchase-owner')), findsNothing);
    if (expected == BuyV2Destination.medicine) {
      expect(
        find.byKey(const Key('care-local-destination-tabs')),
        findsOneWidget,
      );
      for (final key in const [
        'care-local-tab-doctor',
        'care-local-tab-medicine',
        'care-local-tab-salon',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
      }
    } else {
      expect(
        find.byKey(const Key('buy-local-destination-tabs')),
        findsOneWidget,
      );
      for (final key in const [
        'buy-local-tab-wholesale',
        'buy-local-tab-orders',
        'buy-local-tab-offers',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
      }
    }
  }

  const cases = [
    (
      scope: BuyV2CartScope.shop,
      last: BuyV2Destination.medicine,
      expected: BuyV2Destination.shop,
    ),
    (
      scope: BuyV2CartScope.wholesale,
      last: BuyV2Destination.shop,
      expected: BuyV2Destination.wholesale,
    ),
    (
      scope: BuyV2CartScope.medicine,
      last: BuyV2Destination.wholesale,
      expected: BuyV2Destination.medicine,
    ),
  ];

  for (final lane in [
    'shop',
    'wholesale',
    'bulk',
    'shop-all',
    'shop-live',
    'wholesale-quiet',
    'shop-wide',
    'shop-root-return',
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R66 nested Store Cart returns $lane at $scale', (
        tester,
      ) async {
        final size = lane == 'shop-wide'
            ? const Size(1024, 768)
            : const Size(320, 844);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.view.resetViewInsets);
        final core = BuySession();
        final hasStatus = lane == 'shop-live' || lane == 'wholesale-quiet';
        final session = hasStatus
            ? _R66StoreStatusSession(
                core: core,
                quiet: lane == 'wholesale-quiet',
              )
            : BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        final isShop = lane.startsWith('shop');
        final destination = isShop
            ? BuyV2Destination.shop
            : BuyV2Destination.wholesale;
        final product = session.product(
          lane == 'shop-all'
              ? 's-turmeric'
              : isShop
              ? 's-tomato'
              : 'w-rice',
        );
        final retained = session.product(isShop ? 'w-tomato' : 's-tomato');
        session.addProduct(retained.id);
        final retainedQuantity = session.quantityFor(retained.id);
        session.openDestination(destination);
        if (lane == 'bulk') {
          session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
        }
        await tester.pumpWidget(
          app(
            session,
            size: size,
            textScale: scale,
            reducedMotion: lane == 'bulk',
          ),
        );
        session.openProduct(product.id);
        await tester.pumpAndSettle();
        Finder productScroll() => find
            .descendant(
              of: find.byKey(PageStorageKey('buy-product-${product.id}')),
              matching: find.byType(Scrollable),
            )
            .first;
        final supplier = find.byKey(
          ValueKey(
            '${isShop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-${product.id}',
          ),
        );
        await tester.scrollUntilVisible(
          supplier,
          180,
          scrollable: productScroll(),
        );
        await tester.ensureVisible(supplier);
        await tester.pumpAndSettle();
        final rootProductOffset = tester
            .state<ScrollableState>(productScroll())
            .position
            .pixels;
        await tester.tap(supplier);
        await tester.pumpAndSettle();
        var store = find.byKey(
          ValueKey(
            '${isShop ? 'buy-shop-seller' : 'buy-wholesale-supplier'}-sheet-${product.id}',
          ),
        );
        expect(store, findsOneWidget);
        if (lane == 'shop-all') {
          await tester.tap(
            find.byKey(ValueKey('buy-shop-seller-view-more-${product.id}')),
          );
          await tester.pumpAndSettle();
          store = find.byKey(
            const ValueKey('buy-shop-seller-full-catalogue-sheet'),
          );
          expect(store, findsOneWidget);
        }
        final storeSku = find.descendant(
          of: store,
          matching: find.byKey(ValueKey('buy-product-${product.id}')),
        );
        await tester.ensureVisible(storeSku);
        await tester.pumpAndSettle();
        final storeScroll = tester.state<ScrollableState>(
          find.descendant(of: store, matching: find.byType(Scrollable)).first,
        );
        final storeOffset = storeScroll.position.pixels;
        await tester.tap(storeSku);
        await tester.pumpAndSettle();
        final primary = find.byKey(
          ValueKey('buy-product-primary-${product.id}'),
        );
        await tester.scrollUntilVisible(
          primary,
          180,
          scrollable: productScroll(),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(primary);
        await tester.pumpAndSettle();
        expect(primary.hitTestable(), findsOneWidget);
        await tester.tap(primary);
        await tester.pumpAndSettle();
        final productState = tester.state<ScrollableState>(productScroll());
        final productOffset = productState.position.pixels;
        final count = session.quantityFor(product.id);
        await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(find.byType(BuyV2CartView, skipOffstage: false), findsOneWidget);
        expect(
          session.cartScope,
          isShop ? BuyV2CartScope.shop : BuyV2CartScope.wholesale,
        );
        expect(
          find.byKey(const ValueKey('buy-local-destination-tabs')),
          findsOneWidget,
        );
        expect(
          tester
              .getSize(
                find.byKey(const ValueKey('buy-store-product-surface-owner')),
              )
              .width,
          lessThanOrEqualTo(BuyV2Metrics.maxWidth),
        );
        if (lane == 'bulk') {
          tester.view.viewInsets = FakeViewPadding(
            bottom: 280 * tester.view.devicePixelRatio,
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-local-destination-tabs')),
            findsNothing,
          );
          expect(
            find.widgetWithText(FilledButton, 'Review order').hitTestable(),
            findsOneWidget,
          );
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-local-destination-tabs')),
            findsOneWidget,
          );
        }
        if (lane == 'shop-live') {
          final expand = find.byKey(
            const ValueKey('buy-quick-delivery-expand'),
          );
          expect(expand, findsOneWidget);
          await tester.tap(expand);
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('buy-quick-delivery-hide')),
          );
          await tester.pumpAndSettle();
          final restore = find.byKey(
            const ValueKey('buy-quick-delivery-restore'),
          );
          expect(restore, findsOneWidget);
          await tester.tap(restore);
          await tester.pumpAndSettle();
          expect(restore, findsNothing);
          expect(
            find.byKey(const ValueKey('buy-quick-delivery-open')),
            findsOneWidget,
          );
          await tester.tap(
            find.byKey(const ValueKey('buy-quick-delivery-minimize')),
          );
          await tester.pumpAndSettle();
        } else if (lane == 'wholesale-quiet') {
          expect(
            find.byKey(const ValueKey('buy-quiet-delivery-status')),
            findsOneWidget,
          );
        }
        await capture(tester, '$lane-cart-$scale', store: true);
        session.showNotice('Your products are unchanged.');
        await tester.pumpAndSettle();
        expect(find.text('Your products are unchanged.'), findsOneWidget);
        session.clearNotice();
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Review order'));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.checkout);
        expect(
          find.byType(BuyV2CheckoutView, skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('buy-checkout-address-stage')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('buy-checkout-return-cart')),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, product.id);
        expect(
          find.byKey(const ValueKey('buy-local-destination-tabs')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('buy-store-cart-bar')),
          findsOneWidget,
        );
        expect(
          tester.state<ScrollableState>(productScroll()).position.pixels,
          closeTo(productOffset, .1),
        );
        await capture(tester, '$lane-return-product-$scale', store: true);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(store, findsOneWidget);
        expect(storeScroll.mounted, isTrue);
        expect(storeScroll.position.pixels, closeTo(storeOffset, .1));
        await capture(tester, '$lane-return-store-$scale', store: true);
        if (lane == 'shop-root-return') {
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(store, findsNothing);
          expect(session.view, BuyV2View.product);
          expect(session.selectedProductId, product.id);
          expect(
            find.byKey(const ValueKey('buy-local-destination-tabs')),
            findsOneWidget,
          );
          expect(
            tester.state<ScrollableState>(productScroll()).position.pixels,
            closeTo(rootProductOffset, .1),
          );
          expect(tester.takeException(), isNull);
          return;
        }
        await tester.tap(storeSku);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
        await tester.pumpAndSettle();
        final continueStore = find.byKey(
          const ValueKey('buy-cart-continue-store'),
        );
        await tester.ensureVisible(continueStore);
        await tester.pumpAndSettle();
        await tester.tap(continueStore);
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            ValueKey(
              '${isShop ? 'buy-shop-seller' : 'buy-wholesale-supplier'}-sheet-${product.id}',
            ),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(ValueKey('buy-product-${product.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(find.byType(BuyV2CartView, skipOffstage: false), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(find.byType(BuyV2CartView, skipOffstage: false), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('buy-local-tab-orders')));
        await tester.pumpAndSettle();
        expect(session.destination, BuyV2Destination.orders);
        expect(session.view, BuyV2View.catalogue);
        expect(store, findsNothing);
        expect(storeScroll.mounted, isFalse);
        expect(session.quantityFor(product.id), count);
        expect(session.quantityFor(retained.id), retainedQuantity);
        if (lane == 'bulk') {
          expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.bulk);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R66 scoped add feedback and Cart return ${destination.name} at $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          final other = destination == BuyV2Destination.shop
              ? BuyV2Destination.wholesale
              : BuyV2Destination.shop;
          final product = productFor(destination);
          final retained = productFor(other);
          expect(session.addProduct(retained.id), isTrue);
          final retainedQuantity = session.quantityFor(retained.id);
          session.openDestination(destination);
          await tester.pumpWidget(
            app(session, size: const Size(320, 844), textScale: scale),
          );
          session.openProduct(product.id);
          await tester.pumpAndSettle();
          final primary = find.byKey(
            ValueKey('buy-product-primary-${product.id}'),
          );
          final scroll = find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-${product.id}')),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(primary, 180, scrollable: scroll);
          await tester.pumpAndSettle();
          await tester.tap(primary);
          await tester.pumpAndSettle();
          final count = session.countForDestination(destination);
          final items = '$count ${count == 1 ? 'item' : 'items'}';
          final total = session.totalForDestination(destination);
          final dock = find.byKey(const ValueKey('buy-compact-cart-indicator'));
          final semantics = tester.ensureSemantics();
          try {
            expect(
              tester.getSemantics(dock).label,
              contains('${product.title} added · $items'),
            );
            expect(
              tester.getSemantics(dock).label,
              contains(buyV2Money(total)),
            );
            expect(
              find.descendant(of: dock, matching: find.text(items)),
              findsOneWidget,
            );
            await capture(tester, '${destination.name}-added-$scale');
            await tester.tap(dock);
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.cart);
            expect(
              session.cartScope,
              destination == BuyV2Destination.shop
                  ? BuyV2CartScope.shop
                  : BuyV2CartScope.wholesale,
            );
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.product);
            expect(session.selectedProductId, product.id);
            expect(session.countForDestination(destination), count);
            expect(session.totalForDestination(destination), total);
            expect(session.quantityFor(retained.id), retainedQuantity);
            session.openDestination(other);
            await tester.pumpAndSettle();
            expect(
              tester.getSemantics(dock).label,
              isNot(contains(product.title)),
            );
            expect(
              find.byKey(const ValueKey('buy-mini-cart-added-icon')),
              findsNothing,
            );
            await tester.tap(
              find.byKey(const ValueKey('buy-local-tab-offers')),
            );
            await tester.pumpAndSettle();
            final factsRail = find.byKey(
              const ValueKey('buy-published-offer-facts'),
            );
            final offerCards = find.descendant(
              of: factsRail,
              matching: find.byType(InkWell),
            );
            expect(offerCards, findsWidgets);
            for (final element in offerCards.evaluate()) {
              final card = find.byWidget(element.widget);
              final bounds = tester.getRect(card);
              final facts = find.descendant(
                of: card,
                matching: find.byType(Text),
              );
              expect(facts, findsNWidgets(4));
              for (final factElement in facts.evaluate()) {
                final fact = find.byWidget(factElement.widget);
                final paragraph = tester.renderObject<RenderParagraph>(fact);
                expect(paragraph.didExceedMaxLines, isFalse);
                expect(paragraph.maxLines, isNull);
                final factBounds = tester.getRect(fact);
                expect(factBounds.bottom, lessThanOrEqualTo(bounds.bottom - 7));
                expect(factBounds.right, lessThanOrEqualTo(bounds.right - 10));
              }
            }
            await capture(tester, '${destination.name}-offers-$scale');
            final allItems = '${session.itemCount} items';
            expect(tester.getSemantics(dock).label, contains(allItems));
            expect(
              tester.getSemantics(dock).label,
              contains(buyV2Money(session.cartTotal)),
            );
            await tester.tap(dock);
            await tester.pumpAndSettle();
            expect(session.cartScope, BuyV2CartScope.all);
            expect(session.quantityFor(retained.id), retainedQuantity);
          } finally {
            semantics.dispose();
          }
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'R66 Store Cart feedback stays scoped ${destination.name} at $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          final other = destination == BuyV2Destination.shop
              ? BuyV2Destination.wholesale
              : BuyV2Destination.shop;
          final product = productFor(destination);
          final retained = productFor(other);
          expect(session.addProduct(retained.id), isTrue);
          final scope = destination == BuyV2Destination.shop
              ? BuyV2CartScope.shop
              : BuyV2CartScope.wholesale;
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: AnimatedBuilder(
                    animation: session,
                    builder: (context, child) => BuyV2StoreCartBar(
                      session: session,
                      destination: destination,
                      onOpenCart: () => session.openCart(scope: scope),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(session.addProduct(product.id), isTrue);
          await tester.pumpAndSettle();
          final count = session.countForDestination(destination);
          final items = '$count ${count == 1 ? 'item' : 'items'}';
          final bar = find.byKey(const ValueKey('buy-store-cart-bar'));
          final semantics = tester.ensureSemantics();
          try {
            expect(
              tester.getSemantics(bar).label,
              contains('${product.title} added · $items'),
            );
            expect(
              find.descendant(of: bar, matching: find.text(items)),
              findsOneWidget,
            );
            expect(tester.getSize(bar).height, greaterThanOrEqualTo(44));
            await tester.tap(bar);
            await tester.pumpAndSettle();
            expect(session.cartScope, scope);
            session.increase(retained.id);
            await tester.pumpAndSettle();
            expect(
              tester.getSemantics(bar).label,
              isNot(contains(retained.title)),
            );
            expect(
              find.descendant(of: bar, matching: find.text(items)),
              findsOneWidget,
            );
            expect(session.quantityFor(product.id), count);
          } finally {
            semantics.dispose();
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  test(
    'derived dock owner follows scoped Cart and Checkout without routing',
    () {
      for (final testCase in cases) {
        final session = mixedSession();
        addTearDown(session.dispose);
        session.openDestination(testCase.last);
        session.openCart(scope: testCase.scope);

        expect(session.destination, testCase.last);
        expect(session.activeDockDestination, testCase.expected);
        expect(session.openCheckout(), isTrue);
        expect(session.destination, testCase.last);
        expect(session.checkoutScope, testCase.scope);
        expect(session.activeDockDestination, testCase.expected);

        session.openCart(scope: session.checkoutScope);
        expect(session.destination, testCase.last);
        expect(session.cartScope, testCase.scope);
        expect(session.activeDockDestination, testCase.expected);
      }

      final combined = mixedSession();
      addTearDown(combined.dispose);
      combined.openDestination(BuyV2Destination.shop);
      combined.openCart();
      expect(combined.activeDockDestination, BuyV2Destination.shop);
      expect(combined.openCheckout(), isTrue);
      expect(combined.activeDockDestination, BuyV2Destination.shop);
      expect(combined.destination, BuyV2Destination.shop);
    },
  );

  testWidgets('scoped Cart and Checkout retain every established rail action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();

    for (final testCase in cases) {
      final session = mixedSession();
      addTearDown(session.dispose);
      session.openDestination(testCase.last);
      session.openCart(scope: testCase.scope);

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      expectConnectedOwner(tester, session, testCase.expected);
      expect(session.destination, testCase.last);

      expect(session.openCheckout(), isTrue);
      await tester.pumpAndSettle();
      expectConnectedOwner(tester, session, testCase.expected);
      expect(session.destination, testCase.last);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.cart);
      expect(session.destination, testCase.last);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
      expect(session.destination, testCase.last);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    semantics.dispose();
  });

  testWidgets('combined scope retains its valid entry vertical', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final session = mixedSession();
    addTearDown(session.dispose);
    session.openDestination(BuyV2Destination.shop);
    session.openCart();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expectConnectedOwner(tester, session, BuyV2Destination.shop);
    expect(session.openCheckout(), isTrue);
    await tester.pumpAndSettle();
    expectConnectedOwner(tester, session, BuyV2Destination.shop);
    expect(session.destination, BuyV2Destination.shop);
    semantics.dispose();
  });

  testWidgets(
    'compact Mool launcher opens and Back closes the menu without losing Cart',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      final session = mixedSession();
      addTearDown(session.dispose);
      session.openDestination(BuyV2Destination.shop);
      session.openCart(scope: BuyV2CartScope.wholesale);
      final cartIds = session.cartLines.map((line) => line.product.id).toList();

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final launcher = find.byKey(const Key('mool-home-launcher'));
      expect(launcher, findsOneWidget);
      expect(tester.getSemantics(launcher).label, 'Open MoolSocial main menu');

      await tester.tap(launcher);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('moolsocial-main-menu-arrival-motion')),
        findsOneWidget,
      );
      expect(tester.getSemantics(launcher).label, 'Close MoolSocial main menu');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('moolsocial-main-menu-arrival-motion')),
        findsNothing,
      );
      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.wholesale);
      expect(
        session.cartLines.map((line) => line.product.id),
        orderedEquals(cartIds),
      );
      semantics.dispose();
    },
  );

  testWidgets('320px 140% reduced motion is immediate and semantically exact', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final session = mixedSession();
    addTearDown(session.dispose);
    session.openDestination(BuyV2Destination.medicine);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);

    await tester.pumpWidget(
      app(
        session,
        size: const Size(320, 568),
        textScale: 1.4,
        reducedMotion: true,
      ),
    );
    await tester.pump();
    expectConnectedOwner(tester, session, BuyV2Destination.shop);
    expect(session.destination, BuyV2Destination.medicine);
    expect(find.textContaining('Shop delivery ·'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final viewport in const [
    (
      size: Size(320, 568),
      safe: EdgeInsets.symmetric(vertical: 24),
      textScale: 1.0,
      reduced: false,
      checkout: true,
      label: '320x568-android-checkout',
    ),
    (
      size: Size(360, 800),
      safe: EdgeInsets.symmetric(vertical: 24),
      textScale: 1.0,
      reduced: false,
      checkout: false,
      label: '360x800-android-cart',
    ),
    (
      size: Size(390, 844),
      safe: EdgeInsets.only(top: 47, bottom: 34),
      textScale: 1.0,
      reduced: false,
      checkout: true,
      label: '390x844-ios-checkout',
    ),
    (
      size: Size(430, 932),
      safe: EdgeInsets.only(top: 59, bottom: 34),
      textScale: 1.0,
      reduced: false,
      checkout: false,
      label: '430x932-ios-cart',
    ),
    (
      size: Size(320, 568),
      safe: EdgeInsets.symmetric(vertical: 24),
      textScale: 1.4,
      reduced: true,
      checkout: true,
      label: '320x568-a11y140-reduced',
    ),
  ]) {
    testWidgets(
      'R58.8.7 responsive ${viewport.label} candidate capture',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.view.physicalSize = viewport.size;
        final session = mixedSession();
        addTearDown(session.dispose);
        session.openDestination(BuyV2Destination.medicine);
        session.openCart(scope: BuyV2CartScope.shop);
        if (viewport.checkout) {
          expect(session.openCheckout(), isTrue);
        }

        await tester.pumpWidget(
          app(
            session,
            size: viewport.size,
            textScale: viewport.textScale,
            reducedMotion: viewport.reduced,
            safeArea: viewport.safe,
          ),
        );
        await tester.pumpAndSettle();
        await settleVisibleImages(tester);
        expectConnectedOwner(tester, session, BuyV2Destination.shop);
        await expectLater(
          find.byType(BuyV2Screen),
          matchesGoldenFile(
            'candidate_captures/buy-v2-r58-8-7-c24f-${viewport.label}.png',
          ),
        );
      },
      tags: 'protected-reference',
    );
  }
}
