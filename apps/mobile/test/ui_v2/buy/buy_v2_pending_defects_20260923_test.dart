import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';

void _founderVisualCases() {
  for (final width in [412, 320]) {
    for (var number = 8; number <= 16; number++) {
      final ticket = 'C${number.toString().padLeft(2, '0')}';
      testWidgets('R6634 $ticket visual $width', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width.toDouble(), 892);
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = width == 320
            ? 1.4
            : 1;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final core = BuySession();
        final session = _VisualStoreSession(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        var product = session.product('s-tomato');
        Widget shell(Widget child) => MaterialApp(
          theme: MoolTheme.light(),
          builder: _captureRoot,
          home: Scaffold(body: child),
        );
        if (number == 8) {
          product = session.product('s-milk');
          expect(session.addProduct(product.id, quantity: 2), isTrue);
          await tester.pumpWidget(
            shell(
              BuyV2Screen(
                session: session,
                initialView: BuyV2View.product,
                productId: product.id,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final action = find.byKey(
            ValueKey('buy-product-action-compare-${product.id}'),
          );
          await tester.scrollUntilVisible(
            action,
            180,
            maxScrolls: 40,
            scrollable: find
                .descendant(
                  of: find.byKey(PageStorageKey('buy-product-${product.id}')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(find.text('Refresh comparison'), findsNothing);
          expect(find.textContaining('Complete price ranking'), findsNothing);
          final refresh = find.byKey(const ValueKey('buy-comparison-refresh'));
          expect(refresh.hitTestable(), findsOneWidget);
          expect(tester.getSize(refresh).height, greaterThanOrEqualTo(44));
          final title = tester.getRect(find.text('Compare prices'));
          expect(
            tester.getRect(refresh).center.dy,
            closeTo(title.center.dy, 2),
          );
          final grid = find.byKey(
            const ValueKey('buy-vertical-product-grid-comparison'),
          );
          expect(tester.getTopLeft(grid).dy - title.bottom, lessThan(120));
          await tester.tap(refresh);
          await tester.pumpAndSettle();
          expect(grid, findsOneWidget);
          await _capture(tester, '$ticket-$width');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.quantityFor(product.id), 2);
          expect(session.selectedProductId, product.id);
        } else if ([10, 11, 14].contains(number)) {
          if (number == 10) {
            product = product.copyWith(storeId: 'visual-store-identity');
          }
          if (number == 11) {
            product = product.copyWith(
              seller: 'Sardarpura Family Grocery and Household Supplies',
            );
          }
          String? visited;
          await tester.pumpWidget(
            shell(
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => unawaited(
                    showBuyV2PartnerCatalogue(
                      context,
                      session,
                      product,
                      onAskStore: (_) {},
                      onStoreChanged: (p) => visited = p.storeId,
                    ),
                  ),
                  child: const Text('Open fixture Store'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open fixture Store'));
          await tester.pumpAndSettle();
          expect(find.text('Store products'), findsNothing);
          final heading = find.descendant(
            of: find.byKey(const ValueKey('buy-shop-seller-sheet-header')),
            matching: find.text(product.customerSeller(product.seller)),
          );
          expect(heading, findsOneWidget);
          expect(
            tester.renderObject<RenderParagraph>(heading).didExceedMaxLines,
            isFalse,
          );
          expect(
            find.text(product.customerSeller(product.seller)),
            findsOneWidget,
          );
          final truth = find.byKey(
            ValueKey('buy-public-store-truth-${product.id}'),
          );
          expect(
            tester.getSize(truth).height,
            lessThan(width == 320 ? 240 : 155),
          );
          final identity = find.byKey(
            const ValueKey('buy-shop-seller-identity-card'),
          );
          expect(identity, findsOneWidget);
          expect(
            find.descendant(of: identity, matching: heading),
            findsOneWidget,
          );
          expect(
            find.descendant(of: identity, matching: truth),
            findsOneWidget,
          );
          expect(
            find.byTooltip('MoolSocial fulfilment partner'),
            findsOneWidget,
          );
          expect(find.text('MoolSocial Fulfilment Store'), findsNothing);
          if (number == 11) {
            final empty = find.byKey(
              const ValueKey('buy-public-store-no-products'),
            );
            expect(
              find.descendant(of: identity, matching: empty),
              findsNothing,
            );
            expect(tester.getSize(empty).height, lessThan(70));
            expect(
              tester.getTopLeft(empty).dy,
              greaterThanOrEqualTo(tester.getBottomLeft(identity).dy),
            );
          }
          if (number == 14) {
            final other = session.otherStorePreviewsFor(product).first;
            final visit = find.byKey(
              ValueKey('buy-related-store-visit-${other.id}'),
            );
            await tester.scrollUntilVisible(
              visit,
              150,
              maxScrolls: 40,
              scrollable: find
                  .descendant(
                    of: find.byKey(
                      const ValueKey('buy-shop-seller-sheet-list'),
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.pumpAndSettle();
            final card = tester.widget<Container>(
              find.byKey(ValueKey('buy-related-store-card-${other.id}')),
            );
            expect((card.decoration! as BoxDecoration).gradient, isNotNull);
            expect(visit.hitTestable(), findsOneWidget);
            await _capture(tester, '$ticket-$width');
            await tester.tap(visit);
            await tester.pumpAndSettle();
            expect(visited, other.storeId);
          } else {
            if (number == 10) {
              const renamed = 'Updated Store Workspace Name';
              session.renameStore(product.storeId!, renamed);
              await tester.pumpAndSettle();
              expect(find.text(renamed), findsOneWidget);
              expect(heading, findsNothing);
              expect(
                session.catalogueStore(product.storeId!)!.id,
                product.storeId,
              );
            }
            await _capture(tester, '$ticket-$width');
          }
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        } else if (number == 12 || number == 13) {
          final products = [product, session.product('w-rice')];
          await tester.pumpWidget(
            shell(
              SingleChildScrollView(
                child: Column(
                  children: [
                    for (final item in products)
                      SizedBox(
                        width: width == 320 ? 150 : 270,
                        child: AnimatedBuilder(
                          animation: session,
                          builder: (_, _) => BuyV2ProductCard(
                            session: session,
                            product: item,
                            compact: true,
                            storeContext: true,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final add = find.byKey(ValueKey('buy-add-${product.id}'));
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          expect(tester.getSize(add).width, lessThanOrEqualTo(90));
          expect(tester.getSize(add).width, greaterThanOrEqualTo(44));
          expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
          final price = tester.getRect(
            find.byKey(ValueKey('buy-price-highlight-${product.id}')),
          );
          expect(tester.getRect(add).left, greaterThanOrEqualTo(price.right));
          expect(
            tester.getRect(add).bottom,
            lessThan(
              tester
                      .getRect(
                        find.byKey(ValueKey('buy-product-${product.id}')),
                      )
                      .bottom -
                  4,
            ),
          );
          final title = tester.getRect(find.text(product.customerTitle));
          final pack = tester.getRect(find.text(product.pack));
          expect(pack.top - title.bottom, inInclusiveRange(0, 3));
          await _capture(tester, '$ticket-$width');
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(session.quantityFor(product.id), 1);
          expect(
            find.byKey(ValueKey('buy-quantity-${product.id}')),
            findsOneWidget,
          );
        } else if (number == 15) {
          final scroll = ScrollController();
          addTearDown(scroll.dispose);
          await tester.pumpWidget(
            shell(
              BuyV2VerticalScrollIndicator(
                child: ListView(
                  controller: scroll,
                  children: List.generate(
                    30,
                    (i) =>
                        SizedBox(height: 70, child: Text('Product ${i + 1}')),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          Future<double> dotY() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('pending-native-capture')),
            );
            return (await tester.runAsync(() async {
              final frame = await boundary.toImage();
              try {
                final raw = (await frame.toByteData(
                  format: ImageByteFormat.rawRgba,
                ))!;
                var count = 0, yTotal = 0, trackPixels = 0;
                for (var y = 0; y < frame.height; y++) {
                  for (var x = frame.width - 12; x < frame.width; x++) {
                    final i = (y * frame.width + x) * 4;
                    final r = raw.getUint8(i),
                        g = raw.getUint8(i + 1),
                        b = raw.getUint8(i + 2);
                    if (r == 20 && g == 70 && b == 217) {
                      count++;
                      yTotal += y;
                    }
                    if (r == 137 && g == 147 && b == 162) {
                      trackPixels++;
                    }
                  }
                }
                expect(trackPixels, 0);
                expect(count, greaterThan(10));
                return yTotal / count;
              } finally {
                frame.dispose();
              }
            }))!;
          }

          final top = await dotY();
          scroll.jumpTo(scroll.position.maxScrollExtent / 2);
          await tester.pumpAndSettle();
          final middle = await dotY();
          expect(middle, greaterThan(top + 200));
          await _capture(tester, '$ticket-$width');
          scroll.jumpTo(scroll.position.maxScrollExtent);
          await tester.pumpAndSettle();
          expect(await dotY(), greaterThan(middle + 200));
        } else {
          await tester.pumpWidget(shell(BuyV2Screen(session: session)));
          await tester.pumpAndSettle();
          if (number == 9) {
            final category = find.byKey(const ValueKey('buy-category-picker'));
            final surfaces = find.descendant(
              of: category,
              matching: find.byType(AnimatedContainer),
            );
            for (final e in surfaces.evaluate()) {
              expect((e.widget as AnimatedContainer).decoration, isNull);
            }
            expect(tester.getSize(category).height, greaterThanOrEqualTo(44));
            for (final key in ['buy-change-location', 'buy-open-account']) {
              final button = find.byKey(ValueKey(key));
              expect(button.hitTestable(), findsOneWidget);
              expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
            }
            await _capture(tester, '$ticket-$width');
            await tester.tap(category);
            await tester.pumpAndSettle();
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.catalogue);
          } else {
            for (final route in ['shop', 'wholesale']) {
              if (route == 'wholesale') {
                await tester.tap(
                  find.byKey(const ValueKey('buy-local-tab-wholesale')),
                );
                await tester.pumpAndSettle();
              }
              expect(
                find.byKey(ValueKey('buy-$route-sale-type-track')),
                findsNothing,
              );
              expect(
                tester
                    .getSize(find.byKey(ValueKey('buy-$route-sale-type-thumb')))
                    .height,
                3,
              );
              final target = route == 'shop' ? 'courier' : 'bulk';
              await tester.tap(
                find.byKey(ValueKey('buy-$route-sale-type-$target')),
              );
              await tester.pumpAndSettle();
              if (route == 'shop') {
                expect(session.shopSaleType, BuyV2ShopSaleType.courier);
              } else {
                expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.bulk);
              }
              await _capture(tester, '$ticket-$route-$width');
            }
          }
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }
}

class _VisualStoreSession extends BuyV2Session {
  _VisualStoreSession({required super.core}) : super(reviewDataEnabled: true);

  BuyV2StoreListing? renamedStore;

  void renameStore(String id, String name) {
    renamedStore = BuyV2StoreListing(
      id: id,
      name: name,
      area: 'Sardarpura',
      address: 'Sardarpura, Jodhpur',
      regionId: 'jodhpur',
    );
    notifyListeners();
  }

  @override
  BuyV2StoreListing? catalogueStore(String storeId) =>
      renamedStore?.id == storeId
      ? renamedStore
      : super.catalogueStore(storeId);
}

class _AccountStore implements BuyV2GstInvoiceProfileStore {
  @override
  String? ownerScope = 'test-account-A';
  final snapshots = <String, BuyV2GstInvoiceProfileSnapshot>{};
  bool failRead = false, failWrite = false;
  Completer<BuyV2GstInvoiceProfileSnapshot?>? pending;
  @override
  Future<BuyV2GstInvoiceProfileSnapshot?> read() async {
    if (failRead) throw StateError('controlled read failure');
    if (pending != null) return pending!.future;
    return snapshots[ownerScope];
  }

  @override
  Future<bool> write(BuyV2GstInvoiceProfileSnapshot value) async {
    if (failWrite || ownerScope == null) return false;
    snapshots[ownerScope!] = value;
    return true;
  }
}

BuyV2GstInvoiceController _controller(_AccountStore store) {
  final c = BuyV2GstInvoiceController(store: store);
  addTearDown(c.dispose);
  return c;
}

Future<bool> _save(
  BuyV2GstInvoiceController c, {
  BuyV2Destination destination = BuyV2Destination.shop,
  String name = 'Market Buyer',
  bool remember = true,
}) => c.save(
  destination: destination,
  legalName: name,
  gstin: '08ABCDE1234F1Z5',
  billingAddress: '12 Market Road, Jodhpur',
  remember: remember,
);
Widget _captureRoot(BuildContext context, Widget? child) => RepaintBoundary(
  key: const ValueKey('pending-native-capture'),
  child: child!,
);
Future<void> _capture(WidgetTester tester, String name) async {
  const directory = String.fromEnvironment('PENDING_CAPTURE_DIR');
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
      if (source is! AssetImage) continue;
      Object? decodeError;
      await precacheImage(
        provider,
        element,
        onError: (error, stack) {
          decodeError = error;
        },
      );
      if (decodeError != null) throw StateError('Asset decode: $decodeError');
    }
  });
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('pending-native-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    try {
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File(
        '$directory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Widget _app(Widget child) => MaterialApp(
  builder: _captureRoot,
  theme: MoolTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
const _destinations = [BuyV2Destination.shop, BuyV2Destination.wholesale];
Future<void> _fillGst(
  WidgetTester tester, {
  String name = 'Market Buyer',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('buy-gst-legal-name')),
    name,
  );
  await tester.enterText(
    find.byKey(const ValueKey('buy-gst-gstin')),
    '08ABCDE1234F1Z5',
  );
  await tester.enterText(
    find.byKey(const ValueKey('buy-gst-billing-address')),
    '12 Market Road, Jodhpur',
  );
  await tester.ensureVisible(find.text('Use GST details'));
  await tester.tap(find.text('Use GST details'));
  await tester.pumpAndSettle();
}

void main() {
  _founderVisualCases();
  test('D05 production never receives a review comparison provider', () {
    final session = BuyV2Session(core: BuySession(), reviewDataEnabled: false);
    addTearDown(session.dispose);
    expect(session.comparisonSource, isNull);
  });

  test('D05 review session has a comparison provider', () {
    final session = BuyV2Session(core: BuySession(), reviewDataEnabled: true);
    addTearDown(session.dispose);
    expect(session.comparisonSource, isNotNull);
  });

  final now = DateTime.utc(2026, 9, 23, 12);
  final product = BuyV2Catalogue.allProducts.firstWhere(
    (p) => p.id == 's-milk',
  );
  BuyV2ComparisonQuery query(
    BuyV2ReviewComparisonSource source, {
    String pin = '342001',
    int quantity = 1000,
  }) => BuyV2ComparisonQuery(
    productId: product.id,
    productCanonicalId: product.canonicalId,
    identity: source.identityFor(product)!,
    purchaserScope: 'review-buyer',
    destinationKey: 'review-address',
    pinCode: pin,
    requestedQuantityMilli: quantity,
  );
  test('D05 comparison matches variant pack and supplier product', () async {
    final source = BuyV2ReviewComparisonSource(now: () => now);
    final q = query(source);
    final request = BuyV2ComparisonPageRequest(query: q, pageSize: 2);
    final page = await source.load(request);
    expect(page.validFor(request, now), isTrue);
    expect(page.totalCount, 3);
    expect(page.offers.map((o) => o.storeId).toSet(), hasLength(2));
    for (final o in page.offers) {
      expect(o.product.variant, product.variant);
      expect(o.product.pack, product.pack);
      expect(o.product.canonicalId, product.canonicalId);
      expect(o.product.storeId, o.storeId);
      expect(o.product.price * 100, o.packPriceMinor);
      expect(
        BuyV2ComparisonCalculation.evaluate(
          query: q,
          offer: o,
          now: now,
        ).available,
        isTrue,
      );
    }
    final next = await source.load(
      BuyV2ComparisonPageRequest(
        query: q,
        snapshotId: page.snapshotId,
        cursor: page.nextCursor,
        pageSize: 2,
      ),
    );
    expect(next.offers, hasLength(1));
    expect(next.snapshotId, page.snapshotId);
    expect(next.nextCursor, isNull);
  });
  test(
    'D05 comparison rejects stale mismatched and invalid requests',
    () async {
      var clock = now;
      final source = BuyV2ReviewComparisonSource(now: () => clock);
      final q = query(source);
      final page = await source.load(
        BuyV2ComparisonPageRequest(query: q, pageSize: 1),
      );
      await expectLater(
        source.load(
          BuyV2ComparisonPageRequest(query: query(source, pin: 'bad')),
        ),
        throwsFormatException,
      );
      await expectLater(
        source.load(
          BuyV2ComparisonPageRequest(
            query: q,
            snapshotId: 'wrong',
            cursor: '1',
            pageSize: 1,
          ),
        ),
        throwsFormatException,
      );
      expect(source.identityFor(product.copyWith(pack: 'different')), isNull);
      clock = now.add(const Duration(minutes: 6));
      await expectLater(
        source.load(
          BuyV2ComparisonPageRequest(
            query: q,
            snapshotId: page.snapshotId,
            cursor: '1',
            pageSize: 1,
          ),
        ),
        throwsFormatException,
      );
      final refreshed = await source.load(BuyV2ComparisonPageRequest(query: q));
      expect(refreshed.offers, hasLength(3));
      final empty = await source.load(
        BuyV2ComparisonPageRequest(query: query(source, quantity: 101000)),
      );
      expect(empty.offers, isEmpty);
    },
  );
  testWidgets('D05 comparison sheet returns to product with cart unchanged', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 892);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession(), reviewDataEnabled: true);
    addTearDown(session.dispose);
    expect(session.addProduct(product.id, quantity: 2), isTrue);
    await tester.pumpWidget(
      MaterialApp(
        builder: _captureRoot,
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialView: BuyV2View.product,
          productId: product.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.byKey(
      ValueKey('buy-product-action-compare-${product.id}'),
    );
    await tester.scrollUntilVisible(
      action,
      240,
      maxScrolls: 40,
      scrollable: find
          .descendant(
            of: find.byKey(PageStorageKey('buy-product-${product.id}')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(action.hitTestable(), findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Compare prices'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-vertical-product-grid-comparison')),
      findsOneWidget,
    );
    await _capture(tester, 'comparison-populated');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, product.id);
    expect(session.quantityFor(product.id), 2);
    expect(tester.takeException(), isNull);
  });
  test(
    'D06-B MoolSocial and Suppliers filters return matching publishers',
    () async {
      final source = BuyV2DevelopmentPublishedCatalogueSource(
        providerCount: 12,
        skusPerStore: 120,
        now: () => now,
      );
      for (final publisher in [
        BuyV2OfferPublisherType.moolSocial,
        BuyV2OfferPublisherType.retailer,
        BuyV2OfferPublisherType.wholesaler,
      ]) {
        final page = await source.loadOffers(
          BuyV2CatalogueQuery(
            destination: BuyV2Destination.shop,
            regionId: 'jodhpur',
            offersOnly: true,
            offerPublisher: publisher,
          ),
          pageSize: 12,
        );
        expect(page.items, isNotEmpty);
        expect(
          page.items.every(
            (o) => o.publisherType == publisher && o.isCurrent(now: now),
          ),
          isTrue,
        );
        if (publisher == BuyV2OfferPublisherType.moolSocial) {
          expect(
            page.items.every((o) => o.publisherName == 'MoolSocial'),
            isTrue,
          );
        }
      }
    },
  );
  test(
    'D06-B offers retain supplier identity and product navigation',
    () async {
      final session = BuyV2Session(
        core: BuySession(),
        reviewDataEnabled: true,
        publishedCatalogueSource: BuyV2DevelopmentPublishedCatalogueSource(
          providerCount: 12,
          skusPerStore: 120,
          now: () => now,
        ),
        catalogueNow: () => now,
        initialCatalogueRegionId: 'jodhpur',
      );
      addTearDown(session.dispose);
      final pager = session.acquireCatalogueOffers('test-offers');
      await pager.open(
        session.catalogueOffersQuery(
          publisher: BuyV2OfferPublisherType.moolSocial,
        ),
      );
      expect(pager.page!.items, isNotEmpty);
      final offer = pager.page!.items.first;
      expect(offer.product.seller, isNot('MoolSocial'));
      expect(session.openProduct(offer.product.id), isTrue);
      expect(session.selectedProductId, offer.product.id);
      expect(
        session.findProduct(offer.product.id)!.storeId,
        offer.product.storeId,
      );
      expect(session.cartLines, isEmpty);
    },
  );
  test('D06-B production offers never fall back to review data', () async {
    final session = BuyV2Session(core: BuySession(), reviewDataEnabled: false);
    addTearDown(session.dispose);
    expect(session.pagedOffersEnabled, isFalse);
    final pager = session.acquireCatalogueOffers('production');
    await pager.open(session.catalogueOffersQuery());
    expect(pager.page, isNull);
    expect(pager.message, isNotNull);
  });

  testWidgets('R6634 C07-1 Combined Shop + Wholesale Confirm order', (
    tester,
  ) async {
    final c = _controller(_AccountStore());
    await c.restore();
    await tester.pumpWidget(
      _app(BuyV2CheckoutGstDetails(controller: c, destinations: _destinations)),
    );
    expect(find.text('Add GST details'), findsOneWidget);
    await _save(c);
    await tester.pumpAndSettle();
    expect(
      c.detailsFor(_destinations.first),
      same(c.detailsFor(_destinations.last)),
    );
    expect(find.text('GST details'), findsOneWidget);
    expect(find.text('Add GST details'), findsNothing);
  });
  for (final entry in [
    (2, BuyV2Destination.shop, 'Shop-only Cart > payment > Confirm order'),
    (
      3,
      BuyV2Destination.wholesale,
      'Wholesale-only Cart > payment > Confirm order',
    ),
  ]) {
    testWidgets('R6634 C07-${entry.$1} ${entry.$3}', (tester) async {
      final store = _AccountStore();
      await _save(_controller(store));
      final restored = _controller(store);
      await restored.restore();
      await tester.pumpWidget(
        _app(
          BuyV2CheckoutGstDetails(
            controller: restored,
            destinations: [entry.$2],
          ),
        ),
      );
      expect(restored.requestedFor(entry.$2), isTrue);
      expect(restored.detailsFor(entry.$2)!.gstin, '08ABCDE1234F1Z5');
      expect(find.text('Add GST details'), findsNothing);
      expect(find.text('Edit'), findsOneWidget);
    });
  }
  testWidgets('R6634 C07-4 Combined checkout GST > payment > Back > review', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 892);
    addTearDown(tester.view.reset);
    final store = _AccountStore();
    final c = _controller(store);
    await _save(c);
    final session = BuyV2Session(
      core: BuySession(),
      gstInvoiceProfileStore: store,
    );
    addTearDown(session.dispose);
    expect(session.addProduct('s-milk', quantity: 2), isTrue);
    expect(session.addProduct('w-notebook'), isTrue);
    session.openCart();
    expect(session.openCheckout(), isTrue);
    expect(session.continueCheckoutFromAddress(), isTrue);
    expect(session.choosePayment('PhonePe'), isTrue);
    expect(session.continueCheckoutFromPayment(), isTrue);
    final quantities = {
      for (final line in session.cartLines) line.product.id: line.quantity,
    };
    await tester.pumpWidget(
      MaterialApp(
        builder: _captureRoot,
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session, initialView: BuyV2View.checkout),
      ),
    );
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('buy-gst-invoice-shop'));
    Future<void> reveal() async {
      await tester.scrollUntilVisible(
        card,
        180,
        maxScrolls: 40,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-checkout-confirm')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-gst-invoice-wholesale')),
        findsNothing,
      );
      expect(find.text('Add GST details'), findsNothing);
      expect(find.textContaining('08ABCDE1234F1Z5'), findsOneWidget);
    }

    await reveal();
    await _capture(tester, 'confirm-order-single-gst');
    expect(session.showCheckoutStep(BuyV2CheckoutStep.payment), isTrue);
    await tester.pumpAndSettle();
    expect(session.continueCheckoutFromPayment(), isTrue);
    await tester.pumpAndSettle();
    await reveal();
    expect(session.selectedPayment, 'PhonePe');
    expect({
      for (final line in session.cartLines) line.product.id: line.quantity,
    }, quantities);
    expect(tester.takeException(), isNull);
  });
  testWidgets('R6634 C07-5 Combined checkout GST editing', (tester) async {
    final c = _controller(_AccountStore());
    await _save(c, remember: false, name: 'Shop Buyer');
    await _save(
      c,
      destination: BuyV2Destination.wholesale,
      remember: false,
      name: 'Wholesale Buyer',
    );
    await tester.pumpWidget(
      _app(BuyV2CheckoutGstDetails(controller: c, destinations: _destinations)),
    );
    expect(find.text('Shop · GST details'), findsOneWidget);
    expect(find.text('Wholesale · GST details'), findsOneWidget);
    expect(c.detailsFor(BuyV2Destination.shop)!.legalName, 'Shop Buyer');
    expect(
      c.detailsFor(BuyV2Destination.wholesale)!.legalName,
      'Wholesale Buyer',
    );
  });
  test('R6634 C07-6 GST entry validation and recovery', () async {
    final store = _AccountStore()..failWrite = true;
    final c = _controller(store);
    expect(
      await c.save(
        destination: BuyV2Destination.shop,
        legalName: 'Buyer',
        gstin: 'invalid',
        billingAddress: 'Market Road',
        remember: true,
      ),
      isFalse,
    );
    expect(await _save(c), isFalse);
    expect(c.savedProfiles, isEmpty);
    store.failWrite = false;
    expect(await _save(c), isTrue);
    expect(c.savedProfiles, hasLength(1));
  });
  test('R6634 C07-7 Optional GST preference', () async {
    final c = _controller(_AccountStore());
    await _save(c);
    c.setRequested(BuyV2Destination.shop, false);
    await c.restore(force: true);
    expect(c.requestedFor(BuyV2Destination.shop), isFalse);
    expect(c.requestedFor(BuyV2Destination.wholesale), isTrue);
  });
  testWidgets('R6634 C07-8 Account Profile > GST details', (tester) async {
    final store = _AccountStore();
    var changes = 0;
    await tester.pumpWidget(
      _app(BuyV2GstProfileSection(store: store, onChanged: () => changes++)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Add your GST details for future purchases. Optional.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('profile-gst-edit')));
    await tester.pumpAndSettle();
    await _fillGst(tester);
    expect(changes, 1);
    expect(
      store.snapshots[store.ownerScope]!.profiles.single.legalName,
      'Market Buyer',
    );
    expect(find.text('Edit'), findsOneWidget);
  });
  testWidgets('R6634 C07-9 Account Profile > GST details > edit/remove', (
    tester,
  ) async {
    final store = _AccountStore();
    await _save(_controller(store));
    final historical = store.snapshots[store.ownerScope]!;
    await tester.pumpWidget(
      _app(BuyV2GstProfileSection(store: store, onChanged: () {})),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-gst-edit')));
    await tester.pumpAndSettle();
    await _fillGst(tester, name: 'Updated Buyer');
    expect(
      store.snapshots[store.ownerScope]!.profiles.single.legalName,
      'Updated Buyer',
    );
    expect(historical.profiles.single.legalName, 'Market Buyer');
    await tester.tap(find.byKey(const ValueKey('profile-gst-remove')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-gst-remove-confirm')));
    await tester.pumpAndSettle();
    expect(store.snapshots[store.ownerScope]!.profiles, isEmpty);
    expect(find.text('Add GST details'), findsOneWidget);
  });
  test('R6634 C07-10 Next Shop Cart and next Wholesale Cart', () async {
    final store = _AccountStore();
    await _save(_controller(store));
    for (var i = 0; i < 2; i++) {
      final c = _controller(store);
      await c.restore();
      for (final d in _destinations) {
        expect(c.requestedFor(d), isTrue);
        expect(c.detailsFor(d)!.legalName, 'Market Buyer');
      }
    }
  });
  test('R6634 C07-11 Checkout > add GST details > later Cart', () async {
    final store = _AccountStore();
    final checkout = _controller(store);
    await _save(checkout, destination: BuyV2Destination.wholesale);
    final profile = _controller(store);
    await profile.restore();
    expect(
      profile.savedProfiles.single.id,
      checkout.detailsFor(BuyV2Destination.wholesale)!.id,
    );
    await _save(profile, name: 'Updated via Profile');
    await checkout.restore(force: true);
    expect(
      checkout.detailsFor(BuyV2Destination.wholesale)!.legalName,
      'Updated via Profile',
    );
  });
  test('R6634 C07-12 App restart / same-account re-login', () async {
    // The durable fixture proves the frontend contract, not backend persistence.
    final store = _AccountStore();
    await _save(_controller(store));
    final restartedStore = _AccountStore()..snapshots.addAll(store.snapshots);
    final restarted = _controller(restartedStore);
    await restarted.restore();
    expect(
      restarted.detailsFor(BuyV2Destination.shop)!.legalName,
      'Market Buyer',
    );
    restartedStore.ownerScope = null;
    await restarted.restore();
    expect(restarted.savedProfiles, isEmpty);
    restartedStore.ownerScope = 'test-account-A';
    await restarted.restore();
    expect(restarted.savedProfiles, hasLength(1));
  });
  test('R6634 C07-13 Sign-out / switch account during restore', () async {
    final store = _AccountStore();
    await _save(_controller(store));
    final old = store.snapshots[store.ownerScope];
    store.pending = Completer();
    final c = _controller(store);
    final restoring = c.restore();
    store.ownerScope = 'test-account-B';
    store.pending!.complete(old);
    await restoring;
    expect(c.savedProfiles, isEmpty);
    expect(c.detailsFor(BuyV2Destination.shop), isNull);
    store.pending = null;
    await c.restore();
    expect(c.savedProfiles, isEmpty);
    store.ownerScope = 'test-account-A';
    await c.restore();
    store.ownerScope = 'test-account-B';
    expect(await _save(c, name: 'Must not cross accounts'), isFalse);
    expect(store.snapshots['test-account-B'], isNull);
    final review = BuyV2Session(core: BuySession(), reviewDataEnabled: true);
    addTearDown(review.dispose);
    review.synchronizeReviewGstOwner(Object());
    final first = BuyV2GstInvoiceController(
      store: review.gstInvoiceProfileStore,
    );
    addTearDown(first.dispose);
    await _save(first);
    review.synchronizeReviewGstOwner(Object());
    await first.restore();
    expect(first.savedProfiles, isEmpty);
  });
  testWidgets('R6634 C07-14 Profile or checkout save/load failure', (
    tester,
  ) async {
    final store = _AccountStore();
    await _save(_controller(store));
    store.failRead = true;
    await tester.pumpWidget(
      _app(BuyV2GstProfileSection(store: store, onChanged: () {})),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add GST details'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    store.failRead = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Market Buyer'), findsOneWidget);
    store.failWrite = true;
    await tester.tap(find.byKey(const ValueKey('profile-gst-edit')));
    await tester.pumpAndSettle();
    await _fillGst(tester, name: 'Keep my input');
    expect(
      find.text('GST details could not be saved. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Keep my input'), findsOneWidget);
    store.failWrite = false;
    await tester.tap(find.text('Use GST details'));
    await tester.pumpAndSettle();
    expect(
      store.snapshots[store.ownerScope]!.profiles.single.legalName,
      'Keep my input',
    );
  });

  for (final viewport in [
    (const Size(412, 892), 1.0),
    (const Size(320, 700), 1.4),
  ]) {
    testWidgets(
      'GST and Offers native review ${viewport.$1.width} text ${viewport.$2}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport.$1;
        tester.platformDispatcher.textScaleFactorTestValue = viewport.$2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = _AccountStore();
        final c = _controller(store);
        await _save(c);
        await tester.pumpWidget(
          _app(BuyV2GstProfileSection(store: store, onChanged: () {})),
        );
        await tester.pumpAndSettle();
        expect(find.text('Edit'), findsOneWidget);
        await _capture(tester, 'gst-profile-${viewport.$1.width}');
        await tester.pumpWidget(
          _app(
            BuyV2CheckoutGstDetails(controller: c, destinations: _destinations),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('GST details'), findsOneWidget);
        await _capture(tester, 'gst-combined-${viewport.$1.width}');
        final session = BuyV2Session(
          core: BuySession(),
          reviewDataEnabled: true,
          initialCatalogueRegionId: 'jodhpur',
          publishedCatalogueSource: BuyV2DevelopmentPublishedCatalogueSource(
            providerCount: 20,
            skusPerStore: 120,
          ),
        );
        addTearDown(session.dispose);
        await tester.pumpWidget(
          MaterialApp(
            builder: _captureRoot,
            theme: MoolTheme.light(),
            home: BuyV2Screen(session: session),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-paged-scroll-published-offers')),
          findsOneWidget,
        );
        await _capture(tester, 'offers-suppliers-${viewport.$1.width}');
        await tester.tap(
          find.byKey(const ValueKey('buy-offer-group-moolsocial')),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('No offers'), findsNothing);
        await _capture(tester, 'offers-moolsocial-${viewport.$1.width}');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Profile route saves GST for the next Buy checkout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 892);
    addTearDown(tester.view.reset);
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'current',
          currentAreaLabel: 'Jodhpur',
          setupComplete: true,
          setupExperienceVersion: approvedSetupExperienceVersion,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    addTearDown(journey.dispose);
    await journey.start();
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('pending-native-capture'),
        child: MoolSocialApp(
          session: journey,
          initialLocation: '/app/account/identity',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final edit = find.byKey(const ValueKey('profile-gst-edit'));
    await tester.scrollUntilVisible(
      edit,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await _capture(tester, 'account-profile-gst-prompt');
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await _fillGst(tester);
    expect(
      find.text('Details are kept until you close the app.'),
      findsOneWidget,
    );
    final router = GoRouter.of(
      tester.element(find.byKey(const Key('global-personal-profile-v2'))),
    );
    router.go('/app/buy');
    await tester.pumpAndSettle();
    final buy = tester.widget<BuyV2Screen>(find.byType(BuyV2Screen)).session;
    expect(buy.addProduct('s-milk'), isTrue);
    buy.openCart();
    expect(buy.openCheckout(), isTrue);
    expect(buy.continueCheckoutFromAddress(), isTrue);
    expect(buy.continueCheckoutFromPayment(), isTrue);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-gst-invoice-shop')),
      180,
      maxScrolls: 40,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-checkout-confirm')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('08ABCDE1234F1Z5'), findsOneWidget);
    expect(find.text('Add GST details'), findsNothing);
    final reviewStore = buy.gstInvoiceProfileStore!;
    expect((await reviewStore.read())!.profiles, hasLength(1));
    expect(await journey.signOut(), isTrue);
    await tester.pumpAndSettle();
    expect(await reviewStore.read(), isNull);
    expect(tester.takeException(), isNull);
  });
}
