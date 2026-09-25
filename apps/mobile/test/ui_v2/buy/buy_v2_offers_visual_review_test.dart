import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';

class _Source extends BuyV2DevelopmentCatalogueSource {
  _Source(BuyV2Destination destination, {bool variants = false})
    : super(
        destination: destination,
        providerCount: 4,
        skusPerStore: 120,
        includeVariantReviewFixtures: variants,
      );
  Completer<void>? productsWait;
  Completer<void>? storesWait;
  bool failStores = false;
  final pages = <BuyV2CataloguePage<BuyV2Product>>[];

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    if (query.query.isNotEmpty && productsWait != null) {
      await productsWait!.future;
    }
    final page = await super.loadProducts(
      query,
      cursor: cursor,
      pageSize: pageSize,
    );
    pages.add(page);
    return page;
  }

  @override
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    if (query.query.isNotEmpty && storesWait != null) {
      await storesWait!.future;
    }
    if (failStores) throw StateError('Store lookup unavailable');
    return super.loadStores(query, cursor: cursor, pageSize: pageSize);
  }
}

Widget _app(BuyV2Session session, {bool reducedMotion = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: MoolTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
    child: RepaintBoundary(
      key: const ValueKey('pending-review-capture'),
      child: child!,
    ),
  ),
  home: BuyV2Screen(session: session, initialDestination: session.destination),
);

Future<void> _capture(WidgetTester tester, String name) async {
  const directory = String.fromEnvironment('FOUNDER_PENDING_CAPTURE_DIR');
  if (directory.isEmpty) return;
  final images = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    for (final element in images) {
      if (!element.mounted) continue;
      final provider = (element.widget as Image).image;
      ImageProvider source = provider;
      while (source is ResizeImage) {
        source = source.imageProvider;
      }
      if (source is AssetImage) await precacheImage(provider, element);
    }
  });
  await tester.pump(const Duration(milliseconds: 200));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('pending-review-capture')),
  );
  await tester.runAsync(() async {
    await Directory(directory).create(recursive: true);
    final image = await boundary.toImage(pixelRatio: 1.5);
    try {
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      await File(
        '$directory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

class _OffersSource implements BuyV2PublishedCatalogueSource {
  _OffersSource({this.price});
  final int? price;
  final now = DateTime.utc(2026, 9, 18);
  @override
  Future<BuyV2CataloguePage<BuyV2PublishedCatalogueOffer>> loadOffers(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    final shop = await _Source(BuyV2Destination.shop).loadProducts(
      BuyV2CatalogueQuery(
        destination: BuyV2Destination.shop,
        regionId: 'jodhpur',
      ),
      pageSize: 6,
    );
    final wholesale = await _Source(BuyV2Destination.wholesale).loadProducts(
      BuyV2CatalogueQuery(
        destination: BuyV2Destination.wholesale,
        regionId: 'jodhpur',
      ),
      pageSize: 6,
    );
    final products = [
      for (var i = 0; i < 6; i++) ...[shop.items[i], wholesale.items[i]],
    ];
    final offers = <BuyV2PublishedCatalogueOffer>[];
    for (final (index, product) in products.indexed) {
      final publisher = index >= 8
          ? BuyV2OfferPublisherType.moolSocial
          : product.destination == BuyV2Destination.shop
          ? BuyV2OfferPublisherType.retailer
          : BuyV2OfferPublisherType.manufacturer;
      if (!query.acceptsOfferPublisher(publisher)) {
        continue;
      }
      if (query.categoryId != 'all' && product.categoryId != query.categoryId) {
        continue;
      }
      offers.add(
        BuyV2PublishedCatalogueOffer(
          publicationId: 'visual-offer-$index',
          product: product.copyWith(price: price),
          publisherType: publisher,
          publisherId: 'publisher-$index',
          publisherName: index >= 8 ? 'MoolSocial' : product.seller,
          headline: index >= 8
              ? 'MoolSocial selection'
              : 'Fresh offers, direct to you',
          sourceId: 'local-visual-fixture',
          observedAt: now,
          validUntil: now.add(const Duration(hours: 1)),
        ),
      );
    }
    return BuyV2CataloguePage(
      queryKey: query.key,
      snapshotId: 'visual-offers-v1',
      startIndex: 0,
      totalCount: offers.length,
      items: offers,
    );
  }
}

void main() {
  for (final scale in [1.0, 2.0]) {
    for (final amount in [50000, 1000000, 10000000, 10000001]) {
      testWidgets('A04 Offers banner price $amount stays complete at $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 720);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final core = BuySession();
        final source = _OffersSource(price: amount);
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: true,
          publishedCatalogueSource: source,
          initialCatalogueRegionId: 'jodhpur',
          catalogueNow: () => source.now,
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(_app(session));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
        await tester.pumpAndSettle();
        final price = find
            .byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.key.toString().contains('buy-offer-banner-price-'),
            )
            .first;
        expect(price, findsOneWidget);
        final text = tester.widget<Text>(price);
        expect(text.semanticsLabel, buyV2Money(amount));
        expect(text.style!.fontSize, greaterThanOrEqualTo(12));
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: price, matching: find.byType(RichText)),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        final measured = TextPainter(
          text: paragraph.text,
          textScaler: paragraph.textScaler,
          textDirection: TextDirection.ltr,
        )..layout();
        expect(measured.width, lessThanOrEqualTo(paragraph.size.width + .5));
        expect(measured.height, lessThanOrEqualTo(paragraph.size.height + .5));
        measured.dispose();
        expect(tester.takeException(), isNull);
      });
    }
  }

  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await font.load();
  });
  testWidgets(
    'D06-B-A01 supplier tab filters before paging and retains Cart return',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final now = DateTime.utc(2026, 9, 24);
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        reviewDataEnabled: true,
        cataloguePageSource: _Source(BuyV2Destination.shop, variants: true),
        publishedCatalogueSource: BuyV2DevelopmentPublishedCatalogueSource(
          includeVariantReviewFixtures: true,
          providerCount: 20,
          skusPerStore: 500,
          now: () => now,
        ),
        initialCatalogueRegionId: 'jodhpur',
        catalogueNow: () => now,
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final previews = session.acquireCatalogueProducts(
        'review-phone-previews',
      );
      addTearDown(
        () => session.releaseCatalogueProducts('review-phone-previews'),
      );
      await previews.open(
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: 'jodhpur',
          query: 'phone',
        ),
      );
      expect(previews.page!.items, isNotEmpty);
      for (final phone in previews.page!.items) {
        expect(
          buyV2BuyerDeliveryPromiseSource(phone.deliveryPromise),
          'Delivery for review only',
        );
      }
      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
      await tester.pumpAndSettle();
      final pager = session.acquireCatalogueOffers('published-offers');
      addTearDown(() => session.releaseCatalogueOffers('published-offers'));
      expect(pager.query!.supplierOffersOnly, isTrue);
      expect(pager.page!.items, isNotEmpty);
      expect(
        pager.page!.items.every(
          (o) => o.publisherType != BuyV2OfferPublisherType.moolSocial,
        ),
        isTrue,
      );
      expect(find.text('No current offers from this publisher.'), findsNothing);
      expect(find.text('Offers need refreshing'), findsNothing);
      final id = pager.page!.items.first.product.id;
      final add = find.byKey(ValueKey('buy-add-$id'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(session.quantityFor(id), greaterThan(0));
      await tester.tap(
        find.byKey(const ValueKey('buy-cart-navigation-button')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('buy-cart-line-$id')), findsOneWidget);
      final quantity = session.quantityFor(id);
      await tester.tap(find.byKey(ValueKey('buy-cart-product-details-$id')));
      await tester.pumpAndSettle();
      expect(session.productReturnLabel, 'Cart');
      expect(find.text('Cart'), findsOneWidget);
      await tester.tap(find.text('Cart'));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('buy-cart-line-$id')), findsOneWidget);
      expect(session.quantityFor(id), quantity);
      await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
      await tester.pumpAndSettle();
      for (final mool in [true, false]) {
        tester
            .widget<ListView>(
              find.byKey(const ValueKey('buy-paged-scroll-published-offers')),
            )
            .controller!
            .jumpTo(0);
        await tester.pumpAndSettle();
        final tab = find.byKey(
          ValueKey('buy-offer-group-${mool ? 'moolsocial' : 'suppliers'}'),
        );
        await tester.ensureVisible(tab);
        await tester.pumpAndSettle();
        await tester.tap(tab);
        await tester.pumpAndSettle();
        expect(pager.query!.supplierOffersOnly, !mool);
        expect(
          pager.page!.items.every(
            (o) =>
                (o.publisherType == BuyV2OfferPublisherType.moolSocial) == mool,
          ),
          isTrue,
        );
        expect(
          find.text('No current offers from this publisher.'),
          findsNothing,
        );
        expect(session.quantityFor(id), greaterThan(0));
      }
      await _capture(tester, 'D06-B-A01-suppliers-after-return');
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [
    const Size(390, 844),
    const Size(320, 720),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Offers cinema toolbar media ${size.width} $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final core = BuySession();
        final source = _OffersSource();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: true,
          cataloguePageSource: _Source(BuyV2Destination.shop),
          publishedCatalogueSource: source,
          initialCatalogueRegionId: 'jodhpur',
          catalogueNow: () => source.now,
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(_app(session));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final category = find.byKey(
          const ValueKey('buy-offers-category-control'),
        );
        final saved = find.byKey(const ValueKey('buy-offers-saved'));
        final filter = find.byKey(const ValueKey('buy-offers-filter'));
        expect(
          tester.getCenter(category).dx,
          lessThan(tester.getCenter(saved).dx),
        );
        expect(
          tester.getCenter(saved).dx,
          lessThan(tester.getCenter(filter).dx),
        );
        expect(
          find.byKey(const ValueKey('buy-offer-promotion-next')),
          findsNothing,
        );
        await _capture(tester, 'offers-${size.width}-$scale-suppliers');
        final carousel = find.byType(PageView);
        await tester.ensureVisible(carousel);
        await tester.pumpAndSettle();
        final first = session.featuredOfferPublicationId;
        final viewport = tester.getRect(
          find.byKey(const ValueKey('buy-paged-scroll-published-offers')),
        );
        final visible = tester.getRect(carousel).intersect(viewport);
        await tester.dragFrom(
          Offset(visible.right - 30, visible.top + 35),
          Offset(-visible.width * .7, 0),
        );
        await tester.pumpAndSettle();
        expect(session.featuredOfferPublicationId, isNot(first));
        final mool = find.byKey(const ValueKey('buy-offer-group-moolsocial'));
        tester
            .widget<ListView>(
              find.byKey(const ValueKey('buy-paged-scroll-published-offers')),
            )
            .controller!
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.ensureVisible(mool);
        await tester.pumpAndSettle();
        await tester.tap(mool);
        await tester.pumpAndSettle();
        expect(find.text('MoolSocial selection'), findsWidgets);
        expect(
          session
              .retainedCatalogueOffersQuery('published-offers')!
              .offerPublisher,
          BuyV2OfferPublisherType.moolSocial,
        );
        await _capture(tester, 'offers-${size.width}-$scale-moolsocial');
        final grid = find.byKey(
          const ValueKey('buy-paged-vertical-grid-published-offers'),
        );
        await tester.scrollUntilVisible(
          grid,
          160,
          scrollable: find
              .descendant(
                of: find.byKey(
                  const ValueKey('buy-paged-scroll-published-offers'),
                ),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        final packshots = find.descendant(
          of: grid,
          matching: find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key as ValueKey<String>).value.startsWith(
                  'buy-grid-packshot-',
                ),
          ),
        );
        final orderedPackshots = packshots.evaluate().toList()
          ..sort((a, b) {
            final ar = tester.getRect(find.byWidget(a.widget));
            final br = tester.getRect(find.byWidget(b.widget));
            final row = ar.top.compareTo(br.top);
            return row == 0 ? ar.left.compareTo(br.left) : row;
          });
        final firstRects = orderedPackshots
            .take(3)
            .map((e) => tester.getRect(find.byWidget(e.widget)))
            .toList();
        if (scale == 1) {
          for (final rect in firstRects) {
            expect(rect.height, greaterThan(70));
            expect(rect.height, closeTo(rect.width, 1));
          }
          if (size.width == 320) {
            expect(
              firstRects[1].top,
              greaterThan(firstRects.first.bottom),
              reason:
                  'Narrow Offers keeps complete prices and inline quantity readable in one column.',
            );
          } else {
            expect(firstRects[1].top, closeTo(firstRects.first.top, 1));
          }
          if (size.width <= 390) {
            expect(firstRects[2].top, greaterThan(firstRects.first.bottom));
          } else {
            expect(firstRects[2].top, closeTo(firstRects.first.top, 1));
          }
        }
        final ids = orderedPackshots
            .take(3)
            .map(
              (e) => ((e.widget.key as ValueKey<String>).value).substring(
                'buy-grid-packshot-'.length,
              ),
            )
            .toList();
        for (final id in ids) {
          final cardFinder = find.byKey(ValueKey('buy-product-$id'));
          final card = tester.getRect(cardFinder);
          final action = tester.getRect(
            find.byKey(ValueKey('buy-add-shell-$id')),
          );
          final price = tester.getRect(
            find.byKey(ValueKey('buy-price-highlight-$id')),
          );
          final priceRow = tester.getRect(
            find.byKey(ValueKey('buy-price-action-row-$id')),
          );
          expect(action.left, greaterThanOrEqualTo(price.right));
          expect(action.center.dy, closeTo(priceRow.center.dy, .1));
          expect(action.height, 44);
          final textBottoms = find
              .descendant(of: cardFinder, matching: find.byType(Text))
              .evaluate()
              .map((e) {
                final box = e.renderObject! as RenderBox;
                return box.localToGlobal(Offset(0, box.size.height)).dy;
              });
          final contentBottom = textBottoms.fold<double>(
            action.bottom,
            (bottom, next) => next > bottom ? next : bottom,
          );
          expect(
            card.bottom - contentBottom,
            // Two pixels of line padding, two of body padding and the border.
            inInclusiveRange(0, 5),
            reason:
                'SKU card must end at its last detail, without row-height filler',
          );
        }
        final gridCards = find
            .descendant(
              of: grid,
              matching: find.byWidgetPredicate(
                (w) =>
                    w.key is ValueKey<String> &&
                    (w.key as ValueKey<String>).value.startsWith(
                      'buy-product-',
                    ),
              ),
            )
            .evaluate()
            .where((e) => e.widget is InkWell)
            .map((e) => tester.getRect(find.byWidget(e.widget)))
            .toList();
        for (final upper in gridCards) {
          final below =
              gridCards
                  .where(
                    (r) => (r.left - upper.left).abs() < 1 && r.top > upper.top,
                  )
                  .toList()
                ..sort((a, b) => a.top.compareTo(b.top));
          if (below.isNotEmpty) {
            expect(
              below.first.top - upper.bottom,
              closeTo(10, 1),
              reason:
                  'Next SKU must follow its own column, not the tallest neighbour',
            );
          }
        }
        await _capture(tester, 'offers-${size.width}-$scale-grid');
        final firstCard = find.byKey(ValueKey('buy-product-${ids.first}'));
        final originalHeight = tester.getSize(firstCard).height;
        final neighbour = find.byKey(ValueKey('buy-product-${ids[1]}'));
        final neighbourHeight = tester.getSize(neighbour).height;
        final add = find.byKey(ValueKey('buy-add-${ids.first}'));
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(session.quantityFor(ids.first), 1);
        if (scale == 1) {
          final quantity = find.byKey(ValueKey('buy-quantity-${ids.first}'));
          expect(
            tester.getSize(quantity).height,
            44,
            reason: 'Normal quantity must not become a tall two-row box',
          );
          await _capture(tester, 'offers-${size.width}-$scale-quantity');
        }
        expect(tester.getSize(neighbour).height, closeTo(neighbourHeight, .1));
        final increase = find.descendant(
          of: firstCard,
          matching: find.byTooltip('Add one'),
        );
        await tester.ensureVisible(increase);
        await tester.pumpAndSettle();
        await tester.tap(increase);
        await tester.pumpAndSettle();
        expect(session.quantityFor(ids.first), 2);
        final decrease = find.descendant(
          of: firstCard,
          matching: find.byTooltip('Remove one'),
        );
        await tester.tap(decrease);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: firstCard,
            matching: find.byTooltip('Remove from Cart'),
          ),
        );
        await tester.pumpAndSettle();
        expect(session.quantityFor(ids.first), 0);
        expect(tester.getSize(firstCard).height, closeTo(originalHeight, .1));
        expect(tester.takeException(), isNull);

        tester
            .widget<ListView>(
              find.byKey(const ValueKey('buy-paged-scroll-published-offers')),
            )
            .controller!
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.ensureVisible(filter);
        await tester.pumpAndSettle();
        await tester.tap(filter);
        await tester.pumpAndSettle();
        final moolFilter = find.byKey(
          const ValueKey('buy-offer-filter-moolSocial'),
        );
        await tester.ensureVisible(moolFilter);
        await tester.tap(moolFilter);
        await tester.pumpAndSettle();
        expect(
          session
              .retainedCatalogueOffersQuery('published-offers')!
              .offerPublisher,
          BuyV2OfferPublisherType.moolSocial,
        );
        if (size.width == 390 && scale == 1) {
          final cta = find
              .byWidgetPredicate(
                (w) =>
                    w.key is ValueKey<String> &&
                    (w.key as ValueKey<String>).value.startsWith(
                      'buy-offer-promotion-cta-',
                    ),
              )
              .first;
          await tester.ensureVisible(cta);
          await tester.pumpAndSettle();
          await tester.tap(cta);
          await tester.pumpAndSettle();
          expect(session.selectedProductId, isNotNull);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.featuredOffersMoolSocial, true);
          expect(
            session
                .retainedCatalogueOffersQuery('published-offers')!
                .offerPublisher,
            BuyV2OfferPublisherType.moolSocial,
          );
          tester
              .widget<ListView>(
                find.byKey(const ValueKey('buy-paged-scroll-published-offers')),
              )
              .controller!
              .jumpTo(0);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('buy-offers-saved')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-saved-products-info-sheet')),
            findsNothing,
          );
          expect(find.text('No saved offers on this page'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('buy-offers-saved')));
          await tester.pumpAndSettle();
          expect(find.text('No saved offers on this page'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
