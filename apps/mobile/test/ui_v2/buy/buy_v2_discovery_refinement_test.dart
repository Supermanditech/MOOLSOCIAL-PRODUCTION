import 'dart:async';
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
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

class _R671RefinementSource extends BuyV2DevelopmentCatalogueSource {
  _R671RefinementSource()
    : super(
        destination: BuyV2Destination.shop,
        providerCount: 100,
        skusPerStore: 84,
      );
  bool holdNext = false;
  bool failNext = false;
  Completer<void>? pending;
  final requests = <BuyV2CatalogueQuery>[];

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    requests.add(query);
    if (holdNext) {
      holdNext = false;
      pending = Completer<void>();
      await pending!.future;
    }
    if (failNext) {
      failNext = false;
      throw StateError('Review count unavailable');
    }
    return super.loadProducts(query, cursor: cursor, pageSize: pageSize);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<Offset>> readScrollBall(
    WidgetTester tester,
    Finder boundaryFinder,
    String name,
  ) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(boundaryFinder);
    boundary.markNeedsPaint();
    await tester.pump();
    return (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        const capture = String.fromEnvironment('BUY_SCROLL_CAPTURE');
        if (capture.isNotEmpty) {
          if (!RegExp(r'^[a-z0-9-]+$').hasMatch(capture)) {
            throw StateError('Invalid capture name');
          }
          final directory = Directory('build/r66-scroll001-$capture-20260907');
          await directory.create(recursive: true);
          final file = File('${directory.path}/$name.png');
          if (await file.exists()) throw StateError('Capture already exists');
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          await file.writeAsBytes(png!.buffer.asUint8List());
        }
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final pixels = data!.buffer.asUint8List();
        final ball = <Offset>[];
        for (var y = 0; y < image.height; y++) {
          for (var x = image.width - 12; x < image.width; x++) {
            final index = (y * image.width + x) * 4;
            if (pixels[index] == 20 &&
                pixels[index + 1] == 70 &&
                pixels[index + 2] == 217 &&
                pixels[index + 3] == 255) {
              ball.add(Offset(x.toDouble(), y.toDouble()));
            }
          }
        }
        return ball;
      } finally {
        image.dispose();
      }
    }))!;
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final layout in [
      (size: const Size(360, 800), scale: 1.0),
      (size: const Size(320, 700), scale: 1.0),
      (size: const Size(430, 900), scale: 2.0),
      (size: const Size(800, 360), scale: 1.0),
      (size: const Size(700, 320), scale: 2.0),
    ]) {
      final prefix =
          '${destination.name}-${layout.size.width.toInt()}-'
          '${layout.size.height.toInt()}-${layout.scale.toInt()}';
      testWidgets(
        'SCROLL-001 category ball follows scrolling and search $prefix',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = layout.size;
          tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
          final core = BuySession();
          final session = BuyV2Session(core: core)
            ..openDestination(destination);
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              home: BuyV2Screen(
                session: session,
                initialDestination: destination,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(session.destination, destination);
          await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
          await tester.pumpAndSettle();
          expect(find.text('${destination.label} categories'), findsOneWidget);
          expect(
            tester
                .renderObject<RenderParagraph>(
                  find.byKey(const ValueKey('buy-category-sheet-title')),
                )
                .didExceedMaxLines,
            isFalse,
          );
          final boundary = find.byKey(
            const ValueKey('buy-category-sheet-repaint-boundary'),
          );
          final top = await readScrollBall(
            tester,
            boundary,
            '$prefix-category-top',
          );
          expect(
            top.length,
            greaterThan(40),
            reason: 'A visible round blue ball',
          );
          final grid = find.byKey(const ValueKey('buy-category-grid'));
          final scrollable = find.descendant(
            of: grid,
            matching: find.byType(Scrollable),
          );
          final position = tester.state<ScrollableState>(scrollable).position;
          expect(position.maxScrollExtent, greaterThan(0));
          await tester.drag(grid, const Offset(0, -150));
          await tester.pumpAndSettle();
          final moved = await readScrollBall(
            tester,
            boundary,
            '$prefix-category-scrolled',
          );
          expect(moved.first.dy, greaterThan(top.first.dy));
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          final bottom = await readScrollBall(
            tester,
            boundary,
            '$prefix-category-bottom',
          );
          expect(bottom.first.dy, greaterThanOrEqualTo(moved.first.dy));
          final ballWidth =
              bottom.map((p) => p.dx).reduce((a, b) => a > b ? a : b) -
              bottom.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
          final ballHeight = bottom.last.dy - bottom.first.dy;
          expect(
            ballWidth,
            closeTo(ballHeight, 1),
            reason: 'Round, not elongated',
          );
          await tester.enterText(
            find.byKey(const ValueKey('buy-category-search')),
            'oil',
          );
          await tester.pumpAndSettle();
          final filtered = await readScrollBall(
            tester,
            boundary,
            '$prefix-category-search',
          );
          expect(filtered.isNotEmpty, position.maxScrollExtent > 0.5);
          final oil = session.categories.singleWhere(
            (c) => c.label.toLowerCase().contains('oil'),
          );
          final oilTile = find.byKey(ValueKey('buy-category-${oil.id}'));
          await tester.ensureVisible(oilTile);
          await tester.pumpAndSettle();
          await tester.tapAt(
            tester.getRect(oilTile).intersect(tester.getRect(grid)).center,
          );
          await tester.pumpAndSettle();
          expect(session.selectedCategoryId, oil.id);
          expect(
            find.byKey(const ValueKey('buy-category-sheet-route')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'SCROLL-001 position survives resize, pagination and empty content',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 400);
      addTearDown(tester.view.reset);
      final controller = ScrollController(initialScrollOffset: 4000);
      final count = ValueNotifier(5000);
      addTearDown(controller.dispose);
      addTearDown(count.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey('scroll-extent-capture'),
              child: BuyV2VerticalScrollIndicator(
                child: ValueListenableBuilder<int>(
                  valueListenable: count,
                  builder: (context, total, _) => ListView.builder(
                    controller: controller,
                    itemExtent: 44,
                    itemCount: total,
                    itemBuilder: (_, index) => Text('Product ${index + 1}'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary = find.byKey(const ValueKey('scroll-extent-capture'));
      final restored = await readScrollBall(
        tester,
        boundary,
        'long-list-restored',
      );
      expect(restored.first.dy, greaterThan(1));
      controller.jumpTo(controller.position.maxScrollExtent * .8);
      await tester.pumpAndSettle();
      final beforeAppend = await readScrollBall(
        tester,
        boundary,
        'long-list-before-page',
      );
      final previousExtent = controller.position.maxScrollExtent;
      count.value = 10000;
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ListView>(find.byType(ListView))
            .childrenDelegate
            .estimatedChildCount,
        10000,
      );
      // A fixed-extent lazy list can defer its extent update until layout is
      // invalidated by scrolling. This checks the cue against actual metrics;
      // page-arrival invalidation is acceptance work for the paging adapter.
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -1),
        touchSlopY: 0,
      );
      await tester.pumpAndSettle();
      expect(controller.position.maxScrollExtent, greaterThan(previousExtent));
      final appended = await readScrollBall(
        tester,
        boundary,
        'long-list-after-page',
      );
      expect(appended.first.dy, lessThan(beforeAppend.first.dy));
      tester.view.physicalSize = const Size(700, 320);
      await tester.pumpAndSettle();
      final resized = await readScrollBall(
        tester,
        boundary,
        'long-list-resized',
      );
      expect(resized.first.dy, lessThan(appended.first.dy));
      count.value = 1;
      await tester.pumpAndSettle();
      expect(await readScrollBall(tester, boundary, 'short-list'), isEmpty);
      count.value = 0;
      await tester.pumpAndSettle();
      expect(await readScrollBall(tester, boundary, 'empty-list'), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final destination in ['shop', 'wholesale', 'offers']) {
    testWidgets('SCROLL-001 connected $destination catalogue scroll cue', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final core = BuySession();
      final session = BuyV2Session(core: core);
      if (destination == 'wholesale') {
        session.openDestination(BuyV2Destination.wholesale);
      }
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: RepaintBoundary(
            key: const ValueKey('catalogue-scroll-capture'),
            child: BuyV2Screen(
              session: session,
              initialDestination: destination == 'wholesale'
                  ? BuyV2Destination.wholesale
                  : BuyV2Destination.shop,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        session.destination,
        destination == 'wholesale'
            ? BuyV2Destination.wholesale
            : BuyV2Destination.shop,
      );
      if (destination == 'offers') {
        await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
        await tester.pumpAndSettle();
      }
      final boundary = find.byKey(const ValueKey('catalogue-scroll-capture'));
      final top = await readScrollBall(
        tester,
        boundary,
        '$destination-catalogue-top',
      );
      expect(top, isNotEmpty);
      final list = find.byType(CustomScrollView).first;
      await tester.drag(list, const Offset(0, -200));
      await tester.pumpAndSettle();
      final moved = await readScrollBall(
        tester,
        boundary,
        '$destination-catalogue-moved',
      );
      expect(moved.first.dy, greaterThan(top.first.dy));
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> openRefinement(WidgetTester tester, BuyV2Session session) async {
    await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-discovery-refinement-title')),
      findsOneWidget,
    );
    expect(session.destination, BuyV2Destination.shop);
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    final name = (key as ValueKey<String>).value;
    final section = name.startsWith('buy-sort-')
        ? 'sort'
        : name.startsWith('buy-refine-price-')
        ? 'price'
        : name.startsWith('buy-refine-brand-')
        ? 'brand'
        : name.startsWith('buy-refine-pack-')
        ? 'pack'
        : null;
    if (section != null && finder.evaluate().isEmpty) {
      final heading = find.byKey(ValueKey('buy-refine-section-$section'));
      final headingAction = find
          .descendant(of: heading, matching: find.byType(ListTile))
          .first;
      await tester.scrollUntilVisible(
        heading,
        160,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('buy-discovery-refinement-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await Scrollable.ensureVisible(
        tester.element(headingAction),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      expect(headingAction.hitTestable(), findsOneWidget);
      await tester.tap(headingAction);
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-discovery-refinement-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'R665 O03 paged refinement count follows its source without applying drafts',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final source = _R671RefinementSource();
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        cataloguePageSource: source,
        catalogueAreas: const {'jodhpur': 'Jodhpur'},
        initialCatalogueRegionId: 'jodhpur',
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final expected = await source.loadProducts(
        session.catalogueQuery(),
        pageSize: 1,
      );
      expect(
        expected.totalCount,
        isNot(
          session.previewDiscoveryProducts(BuyV2DiscoveryRefinements()).length,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(session: session),
        ),
      );
      await tester.pumpAndSettle();
      source.holdNext = true;
      await openRefinement(tester, session);
      final count = find.byKey(
        const ValueKey('buy-discovery-refinement-count'),
      );
      expect(tester.widget<Text>(count).data, 'Checking matching products…');
      expect(source.pending, isNotNull);
      source.pending!.complete();
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(count).data,
        '${expected.totalCount} products found',
      );
      expect(source.requests.last, session.catalogueQuery());
      source.failNext = true;
      await tapVisible(tester, const ValueKey('buy-refine-price-250'));
      expect(source.requests.last.maximumPrice, 250);
      expect(session.maximumProductPrice, isNull);
      expect(
        tester.widget<Text>(count).data,
        'Count unavailable. Apply to view results.',
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-discovery-refinement-close')),
      );
      await tester.pumpAndSettle();
      expect(session.maximumProductPrice, isNull);
      await openRefinement(tester, session);
      expect(
        tester.widget<Text>(count).data,
        '${expected.totalCount} products found',
      );
      source.holdNext = true;
      await tapVisible(tester, const ValueKey('buy-refine-price-250'));
      expect(tester.widget<Text>(count).data, 'Checking matching products…');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      source.pending!.complete();
      await tester.pumpAndSettle();
      expect(session.maximumProductPrice, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final check in [
    'cancel',
    'outside',
    'changed-scope',
    'selected-brand',
  ]) {
    testWidgets('R5 020 035 refinement $check', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      session.addProduct('w-rice');
      final otherQuantity = session.quantityFor('w-rice');
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(session: session),
        ),
      );
      await tester.pumpAndSettle();
      await openRefinement(tester, session);
      if (check != 'selected-brand') {
        await tapVisible(tester, const ValueKey('buy-refine-price-250'));
        if (check == 'changed-scope') {
          session.updateQuery('milk');
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<FilledButton>(
                  find.byKey(const ValueKey('buy-discovery-refinement-done')),
                )
                .onPressed,
            isNull,
          );
        }
        if (check == 'outside') {
          await tester.tapAt(const Offset(8, 32));
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pumpAndSettle();
        expect(session.maximumProductPrice, isNull);
        expect(
          find.byKey(const ValueKey('buy-discovery-refinement-title')),
          findsNothing,
        );
        if (check == 'changed-scope') expect(session.query, 'milk');
      } else {
        final brand = session.discoveryBrands.first;
        final key = ValueKey(
          'buy-refine-brand-${brand.toLowerCase().replaceAll(' ', '-')}',
        );
        await tapVisible(tester, key);
        final label = find.descendant(
          of: find.byKey(key),
          matching: find.text(brand),
        );
        final paragraph = tester.renderObject<RenderParagraph>(label);
        expect(paragraph.text.style?.color, Colors.white);
        expect(paragraph.didExceedMaxLines, isFalse);
      }
      expect(session.quantityFor('w-rice'), otherQuantity);
      expect(tester.takeException(), isNull);
    });
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final secondMode in [false, true]) {
      for (final viewport in [
        const Size(320, 700),
        const Size(360, 800),
        const Size(430, 900),
        const Size(640, 360),
      ]) {
        for (final scale in [1.0, 2.0]) {
          final name =
              '${destination.name}-${secondMode ? 2 : 1}-'
              '${viewport.width.toInt()}x${viewport.height.toInt()}-$scale';
          testWidgets('R5 020 035 responsive draft $name', (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = viewport;
            tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
            tester.view.viewPadding = const FakeViewPadding(
              top: 24,
              bottom: 24,
            );
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final core = BuySession();
            final session = BuyV2Session(core: core)
              ..openDestination(destination);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            session.addProduct(
              destination == BuyV2Destination.shop ? 'w-rice' : 's-milk',
            );
            final quantity = session.itemCount;
            if (secondMode) {
              if (destination == BuyV2Destination.shop) {
                session.chooseShopSaleType(BuyV2ShopSaleType.courier);
              } else {
                session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
              }
            }
            final mode = session.saleTypeSignature;
            await tester.pumpWidget(
              r66VisualCaptureRoot(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: MoolTheme.light(),
                  home: BuyV2Screen(
                    session: session,
                    initialDestination: destination,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            Future<void> open() async {
              await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
              await tester.pumpAndSettle();
              expect(
                find.byKey(const ValueKey('buy-discovery-refinement-title')),
                findsOneWidget,
              );
              for (final key in [
                'buy-discovery-refinement-clear',
                'buy-discovery-refinement-done',
              ]) {
                final action = find.byKey(ValueKey(key));
                final bounds = tester.getRect(action);
                expect(bounds.height, greaterThanOrEqualTo(44));
                expect(bounds.bottom, lessThanOrEqualTo(viewport.height - 24));
                expect(action.hitTestable(), findsOneWidget);
                final label = find.descendant(
                  of: action,
                  matching: find.byType(RichText),
                );
                for (final paragraph
                    in tester.renderObjectList<RenderParagraph>(label)) {
                  final natural = TextPainter(
                    text: paragraph.text,
                    textDirection: paragraph.textDirection,
                    textScaler: paragraph.textScaler,
                  )..layout();
                  expect(
                    natural.width,
                    lessThanOrEqualTo(paragraph.size.width + .1),
                    reason:
                        'Footer words must remain intact: ${paragraph.text.toPlainText()}',
                  );
                  natural.dispose();
                }
              }
            }

            await open();
            await captureR66Visual(tester, 'refine-$name-open');
            final brand = session.discoveryBrands.first;
            final brandKey = ValueKey(
              'buy-refine-brand-${brand.toLowerCase().replaceAll(' ', '-')}',
            );
            await tapVisible(tester, brandKey);
            final label = find.descendant(
              of: find.byKey(brandKey),
              matching: find.text(brand),
            );
            final paragraph = tester.renderObject<RenderParagraph>(label);
            expect(paragraph.text.style?.fontFamily, 'Inter');
            expect(paragraph.text.style?.color, Colors.white);
            expect(paragraph.didExceedMaxLines, isFalse);
            final natural = TextPainter(
              text: paragraph.text,
              textDirection: paragraph.textDirection,
              textScaler: paragraph.textScaler,
            )..layout(maxWidth: paragraph.size.width);
            expect(
              paragraph.size.height,
              greaterThanOrEqualTo(natural.height - .1),
            );
            natural.dispose();
            expect(
              tester.getSize(find.byKey(brandKey)).height,
              greaterThanOrEqualTo(44),
            );
            expect(session.selectedBrands, isEmpty);
            await captureR66Visual(tester, 'refine-$name-brand');
            if (secondMode) {
              await tester.tap(
                find.byKey(const ValueKey('buy-discovery-refinement-close')),
              );
            } else {
              await tester.binding.handlePopRoute();
            }
            await tester.pumpAndSettle();
            expect(session.selectedBrands, isEmpty);
            await open();
            final limit = session.discoveryPriceLimits.last;
            await tapVisible(tester, ValueKey('buy-refine-price-$limit'));
            expect(session.maximumProductPrice, isNull);
            final preview = session
                .previewDiscoveryProducts(
                  BuyV2DiscoveryRefinements(maximumPrice: limit),
                )
                .map((p) => p.id)
                .toList();
            await tester.tap(
              find.byKey(const ValueKey('buy-discovery-refinement-done')),
            );
            await tester.pumpAndSettle();
            expect(session.maximumProductPrice, limit);
            expect(
              session.catalogueSaleTypeProducts.map((p) => p.id),
              orderedEquals(preview),
            );
            await open();
            await tester.tap(
              find.byKey(const ValueKey('buy-discovery-refinement-clear')),
            );
            await tester.pumpAndSettle();
            expect(session.maximumProductPrice, limit);
            await tester.tap(
              find.byKey(const ValueKey('buy-discovery-refinement-done')),
            );
            await tester.pumpAndSettle();
            expect(session.activeDiscoveryRefinementCount, 0);
            expect(session.saleTypeSignature, mode);
            expect(session.itemCount, quantity);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final layout in [
      (size: const Size(320, 700), scale: 1.0),
      (size: const Size(320, 700), scale: 2.0),
      (size: const Size(640, 360), scale: 2.0),
    ]) {
      final name =
          '${destination.name}-${layout.size.width.toInt()}x${layout.size.height.toInt()}-${layout.scale}';
      testWidgets('R5 035 long and multiple selected brands $name', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = layout.size;
        tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final core = BuySession();
        final session = BuyV2Session(core: core)..openDestination(destination);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            r66VisualCaptureRoot(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: MoolTheme.light(),
                home: BuyV2Screen(
                  session: session,
                  initialDestination: destination,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final brands = [...session.discoveryBrands]
            ..sort((a, b) => b.length.compareTo(a.length));
          final selected = brands.take(2).toSet();
          expect(selected.length, 2);
          await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
          await tester.pumpAndSettle();
          for (final brand in selected) {
            final key = ValueKey(
              'buy-refine-brand-${brand.toLowerCase().replaceAll(' ', '-')}',
            );
            await tapVisible(tester, key);
            final node = tester.getSemantics(find.byKey(key));
            expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
            expect(node.label, contains(brand));
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: find.byKey(key), matching: find.text(brand)),
            );
            expect(paragraph.text.style?.color, Colors.white);
            expect(paragraph.didExceedMaxLines, isFalse);
            for (final word in brand.split(' ')) {
              final natural = TextPainter(
                text: TextSpan(text: word, style: paragraph.text.style),
                textDirection: paragraph.textDirection,
                textScaler: paragraph.textScaler,
              )..layout();
              expect(
                natural.width,
                lessThanOrEqualTo(paragraph.size.width + .1),
              );
              natural.dispose();
            }
          }
          expect(find.text('2 selected'), findsOneWidget);
          expect(session.selectedBrands, isEmpty);
          await captureR66Visual(tester, 'refine-multiple-$name');
          await tester.tap(
            find.byKey(const ValueKey('buy-discovery-refinement-done')),
          );
          await tester.pumpAndSettle();
          expect(session.selectedBrands, selected);
          expect(session.catalogueSaleTypeProducts, isNotEmpty);
          expect(
            session.catalogueSaleTypeProducts.every(
              (p) => selected.contains(p.brand),
            ),
            isTrue,
          );
          await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
          await tester.pumpAndSettle();
          final removed = selected.first;
          await tapVisible(
            tester,
            ValueKey(
              'buy-refine-brand-${removed.toLowerCase().replaceAll(' ', '-')}',
            ),
          );
          await tester.tap(
            find.byKey(const ValueKey('buy-discovery-refinement-done')),
          );
          await tester.pumpAndSettle();
          expect(session.selectedBrands, selected.difference({removed}));
          expect(session.destination, destination);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  testWidgets('sort and filters combine, clear and return to exact Shop', (
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

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    await openRefinement(tester, session);

    await tapVisible(tester, const ValueKey('buy-sort-priceLowToHigh'));
    await tapVisible(tester, const ValueKey('buy-refine-price-250'));
    await tapVisible(tester, const ValueKey('buy-refine-available-products'));
    expect(session.activeDiscoveryRefinementCount, 0);
    await tester.tap(
      find.byKey(const ValueKey('buy-discovery-refinement-done')),
    );
    await tester.pumpAndSettle();
    expect(session.productSort, BuyV2ProductSort.priceLowToHigh);
    expect(session.selectedFulfilmentMode, isNull);
    expect(session.shopSaleType, BuyV2ShopSaleType.quickDelivery);
    expect(session.maximumProductPrice, 250);
    expect(session.availableProductsOnly, isTrue);
    expect(session.visibleProducts, isNotEmpty);
    final prices = session.visibleProducts
        .map((product) => session.productFactsFor(product).price)
        .toList(growable: false);
    expect(prices, orderedEquals([...prices]..sort()));

    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(session.destination, BuyV2Destination.shop);
    expect(session.view, BuyV2View.catalogue);

    await openRefinement(tester, session);
    await tester.tap(
      find.byKey(const ValueKey('buy-discovery-refinement-clear')),
    );
    await tester.pumpAndSettle();
    expect(session.activeDiscoveryRefinementCount, 3);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.activeDiscoveryRefinementCount, 3);
    await openRefinement(tester, session);
    await tester.tap(
      find.byKey(const ValueKey('buy-discovery-refinement-clear')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-discovery-refinement-done')),
    );
    await tester.pumpAndSettle();
    expect(session.activeDiscoveryRefinementCount, 0);
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(session.destination, BuyV2Destination.shop);
    expect(session.view, BuyV2View.catalogue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discovery browse actions open the category destination', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('buy-featured-browse-categories')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-category-sheet-route')), findsOne);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final browseMore = find.byKey(
      const ValueKey('buy-more-products-browse-categories'),
    );
    final semantics = tester.ensureSemantics();
    await tester.scrollUntilVisible(
      browseMore,
      220,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    tester.semantics.tap(find.semantics.byLabel('Browse categories').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-category-sheet-route')), findsOne);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
