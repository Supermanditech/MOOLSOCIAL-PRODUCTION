import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final count in [1, 4, 8, 9]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R669 full catalogue small and progressive boundary $count scale $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 711);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          final products = BuyV2Catalogue.products
              .where((product) => product.destination == BuyV2Destination.shop)
              .take(count)
              .toList(growable: false);
          expect(products, hasLength(count));
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: BuyV2ProgressiveProductGrid(
                    session: session,
                    products: products,
                    storageKey: 'r669-full-catalogue-boundary',
                    semanticLabel: 'Full store catalogue',
                    fitSmallCatalogue: true,
                    storeContext: true,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final grid = find.byKey(
            const ValueKey(
              'buy-vertical-product-summary-r669-full-catalogue-boundary',
            ),
          );
          final horizontal = find.descendant(
            of: grid,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.right,
            ),
          );
          final initialLabel = tester.widget<Semantics>(grid).properties.label!;
          final last = products.last;
          final add = find.byKey(ValueKey('buy-add-${last.id}'));
          expect(horizontal, findsNothing);
          expect(initialLabel, contains('Showing $count of $count'));
          expect(initialLabel, isNot(contains('Swipe left or right')));
          if (count >= 4) {
            final first = tester.getRect(
              find.byKey(ValueKey('buy-product-${products.first.id}')),
            );
            final second = tester.getRect(
              find.byKey(ValueKey('buy-product-${products[1].id}')),
            );
            final nextRowIndex = scale == 1 ? 3 : 1;
            if (scale == 1) {
              expect(second.top, closeTo(first.top, .1));
              expect(second.left, greaterThan(first.left));
            } else {
              expect(second.top, greaterThan(first.bottom));
              expect(second.left, closeTo(first.left, .1));
            }
            expect(
              tester
                  .getRect(
                    find.byKey(
                      ValueKey('buy-product-${products[nextRowIndex].id}'),
                    ),
                  )
                  .top,
              greaterThan(first.bottom),
            );
          }
          for (final element in horizontal.evaluate()) {
            expect(
              tester
                  .state<ScrollableState>(find.byWidget(element.widget))
                  .position
                  .maxScrollExtent,
              lessThanOrEqualTo(.5),
            );
          }
          for (final product in products) {
            final card = find.byKey(ValueKey('buy-product-${product.id}'));
            expect(card, findsOneWidget);
            expect(tester.getRect(card).left, greaterThanOrEqualTo(10));
            expect(tester.getRect(card).right, lessThanOrEqualTo(310));
          }
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          expect(add.hitTestable(), findsOneWidget);
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(session.quantityFor(last.id), last.minimumOrder);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final store in [false, true]) {
    for (final size in [const Size(320, 711), const Size(711, 320)]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'R669 complete grid quantity store $store $size scale $scale',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            const id = 'w-notebook';
            final product = session.product(id);
            expect(session.addProduct(id), isTrue);
            expect(session.setCartQuantity(id, '28736'), isTrue);
            await tester.pumpWidget(
              r66VisualCaptureRoot(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: MoolTheme.light(),
                  home: Scaffold(
                    body: SingleChildScrollView(
                      child: AnimatedBuilder(
                        animation: session,
                        builder: (context, _) => BuyV2ProgressiveProductGrid(
                          session: session,
                          products: [product],
                          storageKey: 'r669-quantity-grid',
                          semanticLabel: store ? 'Store products' : 'Products',
                          storeContext: store,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final edit = find.byKey(
              const ValueKey('buy-grid-edit-quantity-w-notebook'),
            );
            await tester.ensureVisible(edit);
            await tester.pumpAndSettle();
            expect(edit.hitTestable(), findsOneWidget);
            final number = find.text('28736');
            expect(number, findsOneWidget);
            final paragraph = tester.renderObject<RenderParagraph>(number);
            expect(paragraph.didExceedMaxLines, isFalse);
            final boxes = paragraph.getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 5),
            );
            expect(boxes, isNotEmpty);
            final owner = tester.getRect(edit);
            for (final box in boxes) {
              final topLeft = paragraph.localToGlobal(
                Offset(box.left, box.top),
              );
              final bottomRight = paragraph.localToGlobal(
                Offset(box.right, box.bottom),
              );
              expect(topLeft.dx, greaterThanOrEqualTo(owner.left - .1));
              expect(topLeft.dy, greaterThanOrEqualTo(owner.top - .1));
              expect(bottomRight.dx, lessThanOrEqualTo(owner.right + .1));
              expect(bottomRight.dy, lessThanOrEqualTo(owner.bottom + .1));
            }
            expect(tester.getSize(edit).height, greaterThanOrEqualTo(44));
            await captureR66Visual(
              tester,
              'r669-grid-$store-${size.width.toInt()}-$scale',
            );
            await tester.tap(edit);
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.catalogue);
            await tester.enterText(
              find.byKey(const ValueKey('buy-quantity-input')),
              '1000',
            );
            final save = find.byKey(const ValueKey('buy-quantity-save'));
            await tester.ensureVisible(save);
            await tester.pumpAndSettle();
            await tester.tap(save);
            await tester.pumpAndSettle();
            expect(session.quantityFor(id), 1000);
            expect(session.view, BuyV2View.catalogue);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final destination in const [
    BuyV2Destination.medicine,
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final size in const [Size(360, 800), Size(800, 360)]) {
      for (final productIndex in const [0, 2]) {
        testWidgets(
          'REG4548 featured ${destination.name} item$productIndex return at $size',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(session.dispose);
            addTearDown(core.dispose);
            await tester.pumpWidget(
              MaterialApp(
                theme: MoolTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: BuyV2Screen(
                  session: session,
                  initialDestination: destination,
                ),
              ),
            );
            await tester.pumpAndSettle();
            final rail = find.byKey(
              const ValueKey('buy-featured-product-list'),
            );
            expect(rail, findsOneWidget);
            final horizontal = find.descendant(
              of: rail,
              matching: find.byType(Scrollable),
            );
            final catalogue = find
                .ancestor(of: rail, matching: find.byType(CustomScrollView))
                .first;
            final vertical = find
                .descendant(
                  of: catalogue,
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        widget.axisDirection == AxisDirection.down,
                  ),
                )
                .first;
            expect(horizontal, findsNothing);
            final product = session.catalogueSaleTypeProducts[productIndex];
            final card = find.byKey(
              ValueKey('buy-featured-product-${product.id}'),
            );
            await tester.ensureVisible(card);
            await tester.pumpAndSettle();
            final verticalBefore = tester
                .state<ScrollableState>(vertical)
                .position
                .pixels;
            expect(verticalBefore, greaterThanOrEqualTo(0));
            final image = find.descendant(
              of: card,
              matching: find.byKey(
                ValueKey('buy-featured-packshot-${product.id}'),
              ),
            );
            await tester.ensureVisible(image);
            await tester.pumpAndSettle();
            final returnOffset = tester
                .state<ScrollableState>(vertical)
                .position
                .pixels;
            const imagePoint = Alignment(-.5, .55);
            expect(image.hitTestable(at: imagePoint), findsOneWidget);
            await tester.tapAt(imagePoint.withinRect(tester.getRect(image)));
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.product);
            expect(session.selectedProductId, product.id);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.catalogue);
            expect(
              tester.state<ScrollableState>(vertical).position.pixels,
              closeTo(returnOffset, .1),
            );
            session.openDestination(
              destination == BuyV2Destination.medicine
                  ? BuyV2Destination.shop
                  : BuyV2Destination.medicine,
            );
            await tester.pumpAndSettle();
            expect(
              tester.state<ScrollableState>(vertical).position.pixels,
              0,
              reason: 'An unvisited destination starts at its own first item',
            );
            tester.state<ScrollableState>(vertical).position.jumpTo(230);
            await tester.pumpAndSettle();
            session.openDestination(destination);
            await tester.pumpAndSettle();
            expect(
              tester.state<ScrollableState>(vertical).position.pixels,
              closeTo(returnOffset, .1),
              reason:
                  'Another destination cannot replace this catalogue position',
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final fixture in [
    for (final width in [320.0, 360.0])
      for (final featured in [false, true]) (width: width, featured: featured),
  ]) {
    testWidgets('R665 O05 full medicine identity at text2 $fixture', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(fixture.width, 800);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core)
        ..openDestination(BuyV2Destination.medicine);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final product = session.product('m-paracetamol-500');
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: fixture.featured
                ? BuyV2CatalogueView(session: session)
                : SingleChildScrollView(
                    child: BuyV2ProgressiveProductGrid(
                      session: session,
                      products: [product],
                      storageKey: 'r665-medicine-identity',
                      semanticLabel: 'Medicine products',
                    ),
                  ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(ValueKey('buy-product-${product.id}'));
      final title = find.descendant(
        of: card,
        matching: find.text(product.title),
      );
      expect(title, findsOneWidget);
      await tester.ensureVisible(title);
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(title);
      expect(paragraph.text.toPlainText(), contains('tablets'));
      expect(paragraph.didExceedMaxLines, isFalse);
      final measured = TextPainter(
        text: paragraph.text,
        textDirection: paragraph.textDirection,
        textScaler: paragraph.textScaler,
      )..layout(maxWidth: paragraph.size.width);
      expect(paragraph.size.height, greaterThanOrEqualTo(measured.height - .1));
      measured.dispose();
      expect(
        tester.getRect(title).bottom,
        lessThanOrEqualTo(tester.getRect(card).bottom),
      );
      if (fixture.featured) {
        final action = find.descendant(
          of: card,
          matching: find.byKey(ValueKey('buy-add-${product.id}')),
        );
        expect(action, findsOneWidget);
        final actionBounds = tester.getRect(action);
        expect(actionBounds.width, greaterThanOrEqualTo(44));
        expect(actionBounds.height, greaterThanOrEqualTo(44));
        expect(
          actionBounds.top,
          greaterThanOrEqualTo(tester.getRect(card).top),
        );
        expect(
          actionBounds.bottom,
          lessThanOrEqualTo(tester.getRect(title).top),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final store in [false, true]) {
      for (final count in [1, 2, 3, 18]) {
        testWidgets(
          'R66 customer catalogue announcements $destination $store $count',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(390, 844);
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            final semantics = tester.ensureSemantics();
            try {
              final products = BuyV2Catalogue.products
                  .where((product) => product.destination == destination)
                  .take(count)
                  .toList();
              expect(products.length, count);
              await tester.pumpWidget(
                MaterialApp(
                  theme: MoolTheme.light(),
                  home: Scaffold(
                    body: SingleChildScrollView(
                      child: BuyV2ProgressiveProductGrid(
                        session: session,
                        products: products,
                        storageKey: 'r66-customer-announcements',
                        semanticLabel: store ? 'Store products' : 'Products',
                        storeContext: store,
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final grid = find.byKey(
                const ValueKey(
                  'buy-vertical-product-summary-r66-customer-announcements',
                ),
              );
              expect(
                find.byKey(const ValueKey('buy-horizontal-product-lane-1')),
                findsNothing,
              );
              String announcement() =>
                  tester.getSemantics(grid).getSemanticsData().label;
              expect(
                announcement(),
                contains(
                  'Showing $count of $count ${count == 1 ? 'product' : 'products'}.',
                ),
              );
              expect(
                announcement(),
                isNot(
                  matches(
                    RegExp(
                      r'independently|\blanes?\b|load',
                      caseSensitive: false,
                    ),
                  ),
                ),
              );
              expect(announcement(), contains('Scroll up or down'));
              final last = find.byKey(
                ValueKey('buy-product-${products.last.id}'),
              );
              expect(last, findsOneWidget);
              await tester.ensureVisible(last);
              await tester.pumpAndSettle();
              expect(announcement(), contains('Showing $count of $count'));
              expect(tester.takeException(), isNull);
            } finally {
              semantics.dispose();
            }
          },
        );
      }
    }
  }

  Future<void> captureQuantity(WidgetTester tester, String name) async {
    const phase = String.fromEnvironment('BUY_R66_QUANTITY_CAPTURE');
    if (phase.isEmpty) return;
    if (!['before', 'after'].contains(phase)) {
      throw StateError('Unknown capture phase');
    }
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('r66-quantity-capture')),
    );
    boundary.markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      const override = String.fromEnvironment('BUY_R66_QUANTITY_DIRECTORY');
      final directory = Directory(
        override.isEmpty
            ? 'build/r66-quantity-targets-$phase-20260905'
            : override,
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

  for (final surface in ['store', 'main', 'featured']) {
    for (final lane in ['quick', 'scheduled', 'wholesale', 'bulk']) {
      for (final width in [320.0, 360.0, 430.0]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets('R66 quantity targets $surface $lane at $width / $scale', (
            tester,
          ) async {
            final size = Size(width, 844);
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            final retail = lane == 'quick' || lane == 'scheduled';
            session.openDestination(
              retail ? BuyV2Destination.shop : BuyV2Destination.wholesale,
            );
            if (retail) {
              session.chooseShopSaleType(
                lane == 'quick'
                    ? BuyV2ShopSaleType.quickDelivery
                    : BuyV2ShopSaleType.courier,
              );
            } else {
              session.chooseWholesaleSaleType(
                lane == 'bulk'
                    ? BuyV2WholesaleSaleType.bulk
                    : BuyV2WholesaleSaleType.wholesale,
              );
            }
            final products = session.catalogueSaleTypeProducts.take(3).toList();
            expect(products, isNotEmpty);
            final product = products.first;
            if (retail) {
              expect(
                session.fulfilmentModeFor(product),
                lane == 'quick'
                    ? BuyV2FulfilmentMode.quickLocal
                    : BuyV2FulfilmentMode.standardCourier,
              );
            } else {
              expect(
                product.minimumOrder,
                lane == 'bulk' ? greaterThan(2) : lessThanOrEqualTo(2),
              );
            }
            final retainedId = retail ? 'w-tomato' : 's-tomato';
            expect(session.addProduct(retainedId), isTrue);
            final retained = session.quantityFor(retainedId);
            expect(session.addProduct(product.id), isTrue);
            final initial = session.quantityFor(product.id);
            await tester.pumpWidget(
              RepaintBoundary(
                key: const ValueKey('r66-quantity-capture'),
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: MoolTheme.light(),
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: size,
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: Scaffold(
                      body: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnimatedBuilder(
                          animation: session,
                          builder: (context, _) => surface == 'featured'
                              ? BuyV2CatalogueView(session: session)
                              : SingleChildScrollView(
                                  child: BuyV2ProgressiveProductGrid(
                                    session: session,
                                    products: products,
                                    storageKey: 'r66-quantity-$lane',
                                    semanticLabel: 'Store products',
                                    storeContext: surface == 'store',
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final card = find.byKey(
              ValueKey(
                surface == 'featured'
                    ? 'buy-featured-product-${product.id}'
                    : 'buy-product-${product.id}',
              ),
            );
            if (surface == 'featured') {
              await tester.ensureVisible(card);
              await tester.pumpAndSettle();
            }
            Finder action(String verb, int quantity) => find.descendant(
              of: card,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label ==
                        '$verb ${product.title} quantity from $quantity',
              ),
            );
            final decrease = action('Decrease', initial);
            final increase = action('Increase', initial);
            expect(decrease, findsOneWidget);
            expect(increase, findsOneWidget);
            await Scrollable.ensureVisible(
              tester.element(increase),
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
            );
            await tester.pumpAndSettle();
            expect(increase.hitTestable(), findsOneWidget);
            if (surface == 'store' || surface == 'featured') {
              await captureQuantity(
                tester,
                '${surface == 'featured' ? 'featured-' : ''}$lane-${product.id}-$width-$scale',
              );
            }
            if (surface == 'featured' && product.badge.trim().isNotEmpty) {
              final badge = find.descendant(
                of: card,
                matching: find.byKey(
                  ValueKey('buy-compact-product-badge-${product.id}'),
                ),
              );
              final label = find.descendant(
                of: badge,
                matching: find.byType(Text),
              );
              expect(label, findsOneWidget);
              final paragraph = tester.renderObject<RenderParagraph>(label);
              for (final word in paragraph.text.toPlainText().split(
                RegExp(r'\s+'),
              )) {
                final measured = TextPainter(
                  text: TextSpan(text: word, style: paragraph.text.style),
                  textDirection: paragraph.textDirection,
                  textScaler: paragraph.textScaler,
                )..layout();
                expect(
                  measured.width,
                  lessThanOrEqualTo(paragraph.size.width + .1),
                  reason: 'Featured badge words must remain intact: $word',
                );
                measured.dispose();
              }
            }
            final cardBounds = tester.getRect(card);
            final decreaseBounds = tester.getRect(decrease);
            final increaseBounds = tester.getRect(increase);
            for (final bounds in [decreaseBounds, increaseBounds]) {
              expect(
                bounds.width,
                greaterThanOrEqualTo(28),
                reason:
                    'Compact SKU controls keep separate 28x44 or larger targets',
              );
              expect(bounds.height, greaterThanOrEqualTo(44));
              expect(bounds.left, greaterThanOrEqualTo(cardBounds.left));
              expect(bounds.right, lessThanOrEqualTo(cardBounds.right));
              expect(bounds.top, greaterThanOrEqualTo(cardBounds.top));
              expect(bounds.bottom, lessThanOrEqualTo(cardBounds.bottom));
            }
            expect(decreaseBounds.overlaps(increaseBounds), isFalse);
            await tester.tapAt(increaseBounds.topLeft + const Offset(2, 2));
            await tester.pumpAndSettle();
            expect(session.quantityFor(product.id), initial + 1);
            expect(session.view, BuyV2View.catalogue);
            await tester.tapAt(
              tester.getRect(action('Decrease', initial + 1)).bottomRight -
                  const Offset(2, 2),
            );
            await tester.pumpAndSettle();
            expect(session.quantityFor(product.id), initial);
            expect(session.quantityFor(retainedId), retained);
            expect(session.view, BuyV2View.catalogue);
            await tester.tap(action('Decrease', initial));
            await tester.pumpAndSettle();
            expect(session.quantityFor(product.id), 0);
            final add = find.descendant(
              of: card,
              matching: find.byKey(ValueKey('buy-add-${product.id}')),
            );
            await Scrollable.ensureVisible(
              tester.element(add),
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
            );
            await tester.pumpAndSettle();
            expect(add.hitTestable(), findsOneWidget);
            await tester.tap(add);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 16));
            final transitioning = action('Increase', initial);
            expect(
              tester.getRect(transitioning).width,
              greaterThanOrEqualTo(28),
            );
            expect(
              tester.getRect(transitioning).height,
              greaterThanOrEqualTo(44),
            );
            await tester.tapAt(
              tester.getRect(transitioning).topLeft + const Offset(2, 2),
            );
            await tester.pumpAndSettle();
            expect(session.quantityFor(product.id), initial + 1);
            expect(session.quantityFor(retainedId), retained);
            expect(session.view, BuyV2View.catalogue);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  for (final destination in const [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
    BuyV2Destination.medicine,
  ]) {
    for (final size in const [Size(320, 700), Size(430, 932)]) {
      for (final scale in const [1.0, 1.4, 2.0]) {
        testWidgets(
          'featured ${destination.name} cards fit $size at $scale text',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core)
              ..openDestination(destination);
            addTearDown(session.dispose);
            addTearDown(core.dispose);
            await tester.pumpWidget(
              MaterialApp(
                theme: MoolTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: Scaffold(body: BuyV2CatalogueView(session: session)),
              ),
            );
            await tester.pumpAndSettle();
            final rail = find.byKey(
              const ValueKey('buy-featured-product-list'),
            );
            expect(rail, findsOneWidget);
            expect(
              find.descendant(
                of: rail,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.right,
                ),
              ),
              findsNothing,
            );
            final seen = <String>{};
            final cards = find.byWidgetPredicate(
              (widget) =>
                  widget is AnimatedScale &&
                  widget.key is ValueKey<String> &&
                  (widget.key! as ValueKey<String>).value.startsWith(
                    'buy-featured-product-',
                  ),
            );
            expect(cards, findsWidgets);
            if (scale == 1 && size.width >= 300 && size.width <= 600) {
              final rowCards = cards
                  .evaluate()
                  .map(
                    (element) => tester.getRect(
                      find.byElementPredicate(
                        (candidate) => identical(candidate, element),
                      ),
                    ),
                  )
                  .toList();
              rowCards.sort((a, b) {
                final top = a.top.compareTo(b.top);
                return top == 0 ? a.left.compareTo(b.left) : top;
              });
              expect(rowCards.length, greaterThanOrEqualTo(4));
              expect(rowCards[1].top, closeTo(rowCards[0].top, .1));
              expect(rowCards[2].top, closeTo(rowCards[0].top, .1));
              expect(rowCards[1].left, greaterThanOrEqualTo(rowCards[0].right));
              expect(rowCards[2].left, greaterThanOrEqualTo(rowCards[1].right));
              final firstColumn = rowCards
                  .where((r) => (r.left - rowCards[0].left).abs() < .1)
                  .toList();
              expect(
                firstColumn[1].top - firstColumn[0].bottom,
                closeTo(10, .1),
              );
            }
            for (final element in cards.evaluate().toList()) {
              final key = element.widget.key! as ValueKey<String>;
              final id = key.value.substring('buy-featured-product-'.length);
              seen.add(id);
              final product = session.product(id);
              final facts = session.productFactsFor(product);
              final card = find.byKey(key);
              final bounds = tester.getRect(card);
              expect(bounds.left, greaterThanOrEqualTo(0));
              expect(bounds.right, lessThanOrEqualTo(size.width));
              if (scale == 1 && size.width >= 300 && size.width <= 600) {
                final gridBounds = tester.getRect(
                  find.byKey(
                    ValueKey(
                      'buy-vertical-product-grid-buy-featured-${destination.name}',
                    ),
                  ),
                );
                expect(bounds.width, closeTo((gridBounds.width - 14) / 3, .1));
              }
              for (final text in [product.title, product.pack, facts.partner]) {
                final field = find.descendant(
                  of: card,
                  matching: find.text(text),
                );
                expect(field, findsOneWidget);
                if (text == product.title) {
                  final paragraph = tester.renderObject<RenderParagraph>(field);
                  expect(
                    paragraph.didExceedMaxLines,
                    isFalse,
                    reason: '$id retains the full medicine identity',
                  );
                  final fullTitle = TextPainter(
                    text: paragraph.text,
                    textDirection: paragraph.textDirection,
                    textScaler: paragraph.textScaler,
                  )..layout(maxWidth: paragraph.size.width);
                  expect(
                    paragraph.size.height,
                    greaterThanOrEqualTo(fullTitle.height - .1),
                  );
                  fullTitle.dispose();
                }
                final fieldBounds = tester.getRect(field);
                expect(fieldBounds.top, greaterThanOrEqualTo(bounds.top));
                expect(
                  fieldBounds.bottom,
                  lessThanOrEqualTo(bounds.bottom + .01),
                  reason: '$id: $text stays inside the card',
                );
              }
              final photoBounds = tester.getRect(
                find.byKey(ValueKey('buy-featured-packshot-$id')),
              );
              expect(
                photoBounds.overlaps(
                  tester.getRect(find.byKey(ValueKey('buy-save-$id'))),
                ),
                isFalse,
              );
              final badge = find.byKey(
                ValueKey('buy-compact-product-badge-$id'),
              );
              if (badge.evaluate().isNotEmpty) {
                expect(photoBounds.overlaps(tester.getRect(badge)), isFalse);
              }
              final action = find.descendant(
                of: card,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget.key == ValueKey('buy-add-$id') ||
                      widget.key == ValueKey('buy-review-offer-$id'),
                ),
              );
              expect(action, findsOneWidget);
              final actionBounds = tester.getRect(action);
              expect(actionBounds.height, greaterThanOrEqualTo(44));
              expect(actionBounds.width, greaterThanOrEqualTo(44));
              expect(actionBounds.top, greaterThanOrEqualTo(bounds.top));
              expect(actionBounds.bottom, lessThanOrEqualTo(bounds.bottom));
              await tester.ensureVisible(action);
              await tester.pumpAndSettle();
              expect(action.hitTestable(), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
            expect(seen.length, greaterThan(1));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  Widget app({
    required BuyV2Session session,
    required List<BuyV2Product> products,
    required Size size,
    required double textScale,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: BuyV2ProgressiveProductGrid(
              session: session,
              products: products,
              storageKey: 'responsive-product-grid-test',
              semanticLabel: 'Responsive product cards',
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'phone widths keep three readable product cards with all products reachable',
    (tester) async {
      for (final size in const [
        Size(320, 700),
        Size(360, 800),
        Size(430, 932),
      ]) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        final core = BuySession();
        final session = BuyV2Session(core: core);
        final products = BuyV2Catalogue.products
            .where((product) => product.destination == BuyV2Destination.shop)
            .take(6)
            .toList(growable: false);

        await tester.pumpWidget(
          app(session: session, products: products, size: size, textScale: 1),
        );
        await tester.pumpAndSettle();

        final firstCard = find.byKey(ValueKey('buy-product-${products[0].id}'));
        expect(firstCard, findsOneWidget, reason: '$size first card');
        final firstRect = tester.getRect(firstCard);
        expect(firstRect.width, closeTo((size.width - 34) / 3, .1));
        final secondRect = tester.getRect(
          find.byKey(ValueKey('buy-product-${products[1].id}')),
        );
        final thirdRect = tester.getRect(
          find.byKey(ValueKey('buy-product-${products[2].id}')),
        );
        final nextRow = tester.getRect(
          find.byKey(ValueKey('buy-product-${products[3].id}')),
        );
        expect(secondRect.top, closeTo(firstRect.top, .1));
        expect(thirdRect.top, closeTo(firstRect.top, .1));
        expect(secondRect.left, greaterThanOrEqualTo(firstRect.right));
        expect(thirdRect.left, greaterThanOrEqualTo(secondRect.right));
        expect(nextRow.top, greaterThan(firstRect.bottom));
        for (final product in products) {
          final card = find.byKey(ValueKey('buy-product-${product.id}'));
          await tester.ensureVisible(card);
          await tester.pumpAndSettle();
          expect(card, findsOneWidget, reason: '$size ${product.id} reachable');
          final bounds = tester.getRect(card);
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(size.width));
          expect(bounds.top, greaterThanOrEqualTo(0));
          expect(bounds.bottom, lessThanOrEqualTo(size.height));
        }
        await tester.ensureVisible(firstCard);
        await tester.pumpAndSettle();
        expect(firstRect.height, lessThan(size.height));

        final title = tester.widget<Text>(
          find
              .descendant(of: firstCard, matching: find.text(products[0].title))
              .first,
        );
        final pack = tester.widget<Text>(
          find
              .descendant(of: firstCard, matching: find.text(products[0].pack))
              .first,
        );
        expect(title.style?.fontSize, greaterThanOrEqualTo(13));
        expect(title.maxLines, isNull);
        expect(title.overflow, isNot(TextOverflow.ellipsis));
        expect(pack.style?.fontSize, greaterThanOrEqualTo(11));
        expect(
          find.descendant(
            of: firstCard,
            matching: find.text(products[0].seller),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: firstCard,
            matching: find.text(products[0].unitPrice),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: firstCard,
            matching: find.text(
              buyV2BuyerDeliveryPromise(session.productFactsFor(products[0])),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: firstCard, matching: find.textContaining('10m')),
          findsNothing,
        );
        final add = find.descendant(
          of: firstCard,
          matching: find.byKey(ValueKey('buy-add-shell-${products[0].id}')),
        );
        final price = find.descendant(
          of: firstCard,
          matching: find.byKey(
            ValueKey('buy-price-highlight-${products[0].id}'),
          ),
        );
        expect(
          tester.getRect(add).left,
          greaterThanOrEqualTo(tester.getRect(price).right),
        );
        final lastDetail = find.descendant(
          of: firstCard,
          matching: find.text(
            buyV2BuyerDeliveryPromise(session.productFactsFor(products[0])),
          ),
        );
        expect(
          firstRect.bottom -
              tester
                  .getRect(
                    find
                        .ancestor(
                          of: lastDetail,
                          matching: find.byType(Padding),
                        )
                        .first,
                  )
                  .bottom,
          lessThanOrEqualTo(4),
          reason: '$size must not leave a dead block below SKU details',
        );
        expect(tester.takeException(), isNull, reason: '$size overflow');

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        session.dispose();
        core.dispose();
      }
      tester.view.reset();
    },
  );

  testWidgets(
    'large text retains vertical rows and complete minimum tap actions',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final products = BuyV2Catalogue.products
          .where((product) => product.destination == BuyV2Destination.wholesale)
          .take(6)
          .toList(growable: false);

      await tester.pumpWidget(
        app(
          session: session,
          products: products,
          size: const Size(320, 700),
          textScale: 1.4,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey(
            'buy-vertical-product-grid-responsive-product-grid-test',
          ),
        ),
        findsOneWidget,
      );
      final firstCard = find.byKey(ValueKey('buy-product-${products[0].id}'));
      expect(tester.getSize(firstCard).height, lessThan(700));
      final add = find.descendant(
        of: firstCard,
        matching: find.byKey(ValueKey('buy-add-shell-${products[0].id}')),
      );
      expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
      final completePromise = tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: firstCard,
              matching: find.textContaining('at checkout'),
            )
            .first,
      );
      expect(completePromise.didExceedMaxLines, isFalse);
      final fullPromise = TextPainter(
        text: completePromise.text,
        textDirection: completePromise.textDirection,
        textScaler: completePromise.textScaler,
      )..layout(maxWidth: completePromise.size.width);
      expect(
        completePromise.size.height + 0.1,
        greaterThanOrEqualTo(fullPromise.height),
      );
      fullPromise.dispose();
      final oneDayCard = find.byKey(ValueKey('buy-product-${products[2].id}'));
      await tester.ensureVisible(oneDayCard);
      await tester.pumpAndSettle();
      final fullDeliveryText = buyV2BuyerDeliveryPromise(
        session.productFactsFor(products[2]),
      );
      final oneDayPromise = find.descendant(
        of: oneDayCard,
        matching: find.text(fullDeliveryText),
      );
      expect(oneDayPromise, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(oneDayPromise);
      expect(paragraph.didExceedMaxLines, isFalse);
      final measuredPromise = TextPainter(
        text: paragraph.text,
        textDirection: paragraph.textDirection,
        textScaler: paragraph.textScaler,
      )..layout(maxWidth: paragraph.size.width);
      expect(
        paragraph.size.height + .1,
        greaterThanOrEqualTo(measuredPromise.height),
      );
      measuredPromise.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('wide catalogue admits three cards without compressing content', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(520, 900);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final products = BuyV2Catalogue.products
        .where((product) => product.destination == BuyV2Destination.shop)
        .take(6)
        .toList(growable: false);

    await tester.pumpWidget(
      app(
        session: session,
        products: products,
        size: const Size(520, 900),
        textScale: 1,
      ),
    );
    await tester.pumpAndSettle();

    for (final index in const [0, 2, 4]) {
      final card = find.byKey(ValueKey('buy-product-${products[index].id}'));
      expect(card, findsOneWidget);
      expect(tester.getSize(card).width, greaterThanOrEqualTo(160));
      expect(tester.getSize(card).height, lessThan(450));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Fresh picks keeps store and delivery on separate complete lines',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(session: session),
        ),
      );
      await tester.pumpAndSettle();

      final product = session.product('s-tomato');
      final card = find.byKey(ValueKey('buy-product-${product.id}')).first;
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text(product.seller)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Retailer')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(product.unitPrice)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text(
            buyV2BuyerDeliveryPromise(session.productFactsFor(product)),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.textContaining('10m')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Fresh picks preserves complete seller facts at 140 percent text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.4),
            ),
            child: BuyV2Screen(session: session),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final product = session.product('s-tomato');
      final card = find.byKey(ValueKey('buy-product-${product.id}')).first;
      expect(
        find.descendant(of: card, matching: find.text(product.seller)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Retailer')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(product.unitPrice)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
