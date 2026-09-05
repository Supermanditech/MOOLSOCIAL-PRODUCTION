import 'dart:io';
import 'dart:ui' show SemanticsAction, ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
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
          child: RepaintBoundary(
            key: const ValueKey('r66-sparse-search-capture'),
            child: child!,
          ),
        );
      },
      home: BuyV2Screen(
        session: session,
        initialDestination: session.destination,
      ),
    );
  }

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final keyboard in [0.0, 280.0]) {
        testWidgets('R66 sparse search $width $scale keyboard $keyboard', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await tester.pumpWidget(app(session, textScale: scale));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('buy-search-control')));
          await tester.pumpAndSettle();
          tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
          await tester.enterText(
            find.byKey(const ValueKey('buy-search-field')),
            'tomato',
          );
          await tester.pumpAndSettle();
          final products = session.visibleProducts;
          expect(products, hasLength(2));
          final first = find.byKey(ValueKey('buy-product-${products[0].id}'));
          final second = find.byKey(ValueKey('buy-product-${products[1].id}'));
          final firstRect = tester.getRect(first);
          final secondRect = tester.getRect(second);
          expect(firstRect.top, closeTo(secondRect.top, 0.01));
          expect(secondRect.left, greaterThan(firstRect.right));
          expect(secondRect.right, lessThanOrEqualTo(width));
          expect(
            find.byKey(const ValueKey('buy-horizontal-product-lane-1')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
          if (const bool.fromEnvironment('BUY_R66_SPARSE_CAPTURE')) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('r66-sparse-search-capture')),
            );
            boundary.markNeedsPaint();
            await tester.pump();
            await tester.runAsync(() async {
              final directory = Directory(
                'build/r66-sparse-search-v2-20260905',
              );
              await directory.create(recursive: true);
              final file = File(
                '${directory.path}/$width-$scale-$keyboard.png',
              );
              if (await file.exists()) throw StateError('Capture exists');
              final image = await boundary.toImage(pixelRatio: 1);
              try {
                final bytes = await image.toByteData(format: ImageByteFormat.png);
                await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
              } finally {
                image.dispose();
              }
            });
          }
          final add = find.byKey(ValueKey('buy-add-${products[1].id}'));
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
          expect(tester.getRect(add).bottom, lessThanOrEqualTo(844 - keyboard));
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(session.quantityFor(products[1].id), 1);
          await tester.ensureVisible(second);
          await tester.tap(second);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.product);
          expect(session.selectedProduct?.id, products[1].id);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final mode in ['quick', 'scheduled', 'wholesale', 'bulk']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R66 no-results clears refinements for $mode at $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(scale == 2 ? 320 : 390, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        final retail = mode == 'quick' || mode == 'scheduled';
        final destination = retail
            ? BuyV2Destination.shop
            : BuyV2Destination.wholesale;
        session.openDestination(destination);
        if (retail) {
          session.chooseShopSaleType(
            mode == 'quick'
                ? BuyV2ShopSaleType.quickDelivery
                : BuyV2ShopSaleType.courier,
          );
          session.chooseFulfilmentMode(
            mode == 'quick'
                ? BuyV2FulfilmentMode.quickLocal
                : BuyV2FulfilmentMode.standardCourier,
          );
        } else {
          session.chooseWholesaleSaleType(
            mode == 'bulk'
                ? BuyV2WholesaleSaleType.bulk
                : BuyV2WholesaleSaleType.wholesale,
          );
          session.chooseFulfilmentMode(BuyV2FulfilmentMode.bulkFreight);
        }
        final saleType = session.saleTypeSignature;
        session.chooseCategory('fruits-vegetables');
        session.chooseFilter('lowest');
        session.choosePackFilter(BuyV2PackFilter.multipack);
        session.chooseMaximumProductPrice(session.discoveryPriceLimits.first);
        session.toggleDiscoveryBrand(session.discoveryBrands.first);
        session.chooseProductSort(BuyV2ProductSort.priceLowToHigh);
        session.setAvailableProductsOnly(true);
        final retainedId = retail ? 'w-notebook' : 's-eggs';
        session.addProduct(retainedId);
        final retainedQuantity = session.quantityFor(retainedId);
        expect(session.catalogueSaleTypeProducts, isEmpty);
        expect(session.activeDiscoveryRefinementCount, 6);
        await tester.pumpWidget(app(session, textScale: scale));
        await tester.pumpAndSettle();
        expect(find.text('No matching products'), findsOneWidget);
        final actionText = find.textContaining(
          RegExp(r'^(Show all products|Clear filters)$'),
        );
        expect(actionText, findsOneWidget);
        await tester.ensureVisible(actionText);
        await tester.tap(actionText);
        await tester.pumpAndSettle();
        expect(session.activeDiscoveryRefinementCount, 0);
        expect(session.selectedFilter, isNull);
        expect(session.selectedCategoryId, 'all');
        expect(session.query, isEmpty);
        expect(session.saleTypeSignature, saleType);
        expect(session.destination, destination);
        expect(session.catalogueSaleTypeProducts, isNotEmpty);
        expect(session.quantityFor(retainedId), retainedQuantity);
        expect(find.text('No matching products'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    test('R66 search broadening clears extra refinements in $destination', () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      session.openDestination(destination);
      session.chooseCategory('fruits-vegetables');
      session.choosePackFilter(BuyV2PackFilter.multipack);
      session.chooseMaximumProductPrice(session.discoveryPriceLimits.first);
      session.toggleDiscoveryBrand(session.discoveryBrands.first);
      session.updateQuery('tomato');
      expect(session.visibleProducts, isEmpty);
      expect(session.broadenProductSearchScope(), isTrue);
      expect(session.activeDiscoveryRefinementCount, 0);
      expect(session.query, 'tomato');
      expect(session.destination, destination);
      expect(session.selectedCategoryId, 'all');
      expect(session.visibleProducts, isNotEmpty);
      expect(
        session.visibleProducts.every(
          (product) => product.destination == destination,
        ),
        isTrue,
      );
    });
  }

  for (final keyboard in [0.0, 280.0]) {
    testWidgets('R66 combined query recovery fits compact keyboard $keyboard', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      tester.view.viewPadding = const FakeViewPadding(bottom: 32);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      session.chooseCategory('fruits-vegetables');
      session.choosePackFilter(BuyV2PackFilter.multipack);
      session.updateQuery('tomato');
      expect(session.catalogueSaleTypeProducts, isEmpty);
      await tester.pumpWidget(app(session, textScale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final action = find.widgetWithText(
        TextButton,
        'Clear search and filters',
      );
      expect(action, findsOneWidget);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      final bounds = tester.getRect(action);
      expect(
        bounds.bottom,
        lessThanOrEqualTo(700 - (keyboard > 0 ? keyboard : 32)),
      );
      expect(bounds.height, greaterThanOrEqualTo(44));
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(320));
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(session.query, isEmpty);
      expect(session.activeDiscoveryRefinementCount, 0);
      expect(session.catalogueSaleTypeProducts, isNotEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> openScopedNoMatch(
    WidgetTester tester,
    BuyV2Session session, {
    String query = 'tomato',
  }) async {
    session.chooseCategory('school-office');
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      query,
    );
    await tester.pumpAndSettle();
  }

  test('scope broadening preserves query and never crosses verticals', () {
    final session = BuyV2Session(core: BuySession());
    session.chooseCategory('school-office');
    session.chooseFilter('lowest');
    session.updateQuery('tomato');

    expect(session.visibleProducts, isEmpty);
    expect(session.hasNarrowedProductSearchScope, isTrue);
    expect(session.broadenProductSearchScope(), isTrue);
    expect(session.query, 'tomato');
    expect(session.selectedCategoryId, 'all');
    expect(session.selectedFilter, isNull);
    expect(session.visibleProducts, isNotEmpty);
    expect(
      session.visibleProducts.every(
        (product) => product.destination == BuyV2Destination.shop,
      ),
      isTrue,
    );

    session.openDestination(BuyV2Destination.orders);
    session.updateQuery('ORD-240731');
    expect(session.hasNarrowedProductSearchScope, isFalse);
    expect(session.broadenProductSearchScope(), isFalse);
    expect(session.query, 'ORD-240731');
  });

  testWidgets('no-match result broadens to a genuine current-vertical result', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await openScopedNoMatch(tester, session);

    expect(find.text('No matches for “tomato”'), findsOneWidget);
    final action = find.byKey(const ValueKey('buy-search-all-shop'));
    expect(action, findsOneWidget);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
    final semantics = tester.getSemantics(action).getSemanticsData();
    expect(semantics.label, contains('Search all Shop'));
    expect(semantics.hasAction(SemanticsAction.tap), isTrue);
    expect(find.byKey(const ValueKey('buy-search-clear')), findsOneWidget);

    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(session.query, 'tomato');
    expect(session.selectedCategoryId, 'all');
    expect(
      session.visibleProducts.map((product) => product.id),
      contains('s-tomato'),
    );
    expect(
      session.visibleProducts.every(
        (product) => product.destination == BuyV2Destination.shop,
      ),
      isTrue,
    );
    expect(find.byKey(const ValueKey('buy-product-s-tomato')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-search-all-shop')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scope recovery is static at 320px and 140% reduced motion', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);

    final session = BuyV2Session(core: BuySession());
    session.chooseCategory('school-office');
    await tester.pumpWidget(
      app(session, disableAnimations: true, textScale: 1.4),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      'tomato',
    );
    await tester.pump();

    final action = find.byKey(const ValueKey('buy-search-all-shop'));
    expect(action, findsOneWidget);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);

    await tester.tap(action);
    await tester.pump();
    expect(
      session.visibleProducts.map((product) => product.id),
      contains('s-tomato'),
    );
    expect(find.byKey(const ValueKey('buy-product-s-tomato')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
