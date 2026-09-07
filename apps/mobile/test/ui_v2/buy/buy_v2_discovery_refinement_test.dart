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
    await tester.tap(find.byKey(const ValueKey('buy-discovery-refinement')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-discovery-refinement-title')),
      findsOneWidget,
    );
    expect(session.destination, BuyV2Destination.shop);
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-discovery-refinement-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
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
    await tapVisible(tester, const ValueKey('buy-refine-delivery-quickLocal'));
    await tapVisible(tester, const ValueKey('buy-refine-price-250'));
    await tapVisible(tester, const ValueKey('buy-refine-available-products'));
    expect(session.productSort, BuyV2ProductSort.priceLowToHigh);
    expect(session.selectedFulfilmentMode, BuyV2FulfilmentMode.quickLocal);
    expect(session.maximumProductPrice, 250);
    expect(session.availableProductsOnly, isTrue);
    expect(session.visibleProducts, isNotEmpty);
    final prices = session.visibleProducts
        .map((product) => session.productFactsFor(product).price)
        .toList(growable: false);
    expect(prices, orderedEquals([...prices]..sort()));

    await tester.tap(
      find.byKey(const ValueKey('buy-discovery-refinement-done')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
    expect(session.destination, BuyV2Destination.shop);
    expect(session.view, BuyV2View.catalogue);

    await openRefinement(tester, session);
    await tester.tap(
      find.byKey(const ValueKey('buy-discovery-refinement-clear')),
    );
    await tester.pumpAndSettle();
    expect(session.activeDiscoveryRefinementCount, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
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
