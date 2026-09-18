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

class _Source extends BuyV2DevelopmentCatalogueSource {
  _Source(BuyV2Destination destination)
    : super(destination: destination, providerCount: 4, skusPerStore: 120);
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
      if (query.offerPublisher != null && publisher != query.offerPublisher) {
        continue;
      }
      if (query.categoryId != 'all' && product.categoryId != query.categoryId) {
        continue;
      }
      offers.add(
        BuyV2PublishedCatalogueOffer(
          publicationId: 'visual-offer-$index',
          product: product,
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
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await font.load();
  });
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
        final firstRects = packshots
            .evaluate()
            .take(3)
            .map((e) => tester.getRect(find.byWidget(e.widget)))
            .toList();
        if (scale == 1) {
          for (final rect in firstRects) {
            expect(rect.height, greaterThan(70));
            expect(rect.height, closeTo(rect.width, 1));
            expect(rect.top, closeTo(firstRects.first.top, 1));
          }
        }
        await _capture(tester, 'offers-${size.width}-$scale-grid');
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
            findsOneWidget,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
