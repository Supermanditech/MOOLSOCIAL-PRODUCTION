import 'dart:async';

import 'buy_v2_qualified_provider_fixture.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

final class _PackCustomerStore implements BuyV2CustomerStateStore {
  _PackCustomerStore(this.snapshot);
  BuyV2CustomerStateSnapshot snapshot;
  @override
  String get ownerScope => 'cat04-pack-customer';
  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => snapshot;
  @override
  Future<bool> write(BuyV2CustomerStateSnapshot value) async {
    snapshot = value;
    return true;
  }
}

final class _MediaHttpClient extends Fake implements HttpClient {
  _MediaHttpClient(
    this.bytes, {
    this.responses = const {},
    this.delayedResponses = const {},
  });
  final Uint8List bytes;
  final Map<Uri, Uint8List> responses;
  final Map<Uri, Future<Uint8List>> delayedResponses;
  final requested = <Uri>[];
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requested.add(url);
    final delayed = delayedResponses[url];
    return _MediaHttpRequest(
      delayed == null ? responses[url] ?? bytes : await delayed,
    );
  }
}

final class _MediaCommerce extends Fake implements BuyV2CommerceAdapter {
  _MediaCommerce(this.product, {this.otherProducts = const []});
  final BuyV2Product product;
  final List<BuyV2Product> otherProducts;
  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: [product, ...otherProducts],
    orders: const [],
    paymentMethods: const {'Cash on Delivery'},
  );
  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: false,
        enabled: false,
        customerMessage: '',
      );
}

final class _MediaHttpRequest extends Fake implements HttpClientRequest {
  _MediaHttpRequest(this.bytes);
  final Uint8List bytes;
  @override
  Future<HttpClientResponse> close() async => _MediaHttpResponse(bytes);
}

final class _MediaHttpResponse extends Fake implements HttpClientResponse {
  _MediaHttpResponse(this.bytes);
  final Uint8List bytes;
  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

Future<Uint8List> _mediaFitFixture(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFE6F2FA),
  );
  canvas.drawRect(
    Rect.fromLTWH(4, 4, width - 8.0, height - 8.0),
    Paint()
      ..color = const Color(0xFF152D5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8,
  );
  for (final corner in [
    (const Color(0xFFD52D35), Offset(14, 14)),
    (const Color(0xFF27964E), Offset(width - 38.0, 14)),
    (const Color(0xFF245CC4), Offset(14, height - 38.0)),
    (const Color(0xFFE8B52B), Offset(width - 38.0, height - 38.0)),
  ]) {
    canvas.drawRect(corner.$2 & const Size(24, 24), Paint()..color = corner.$1);
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<void> expectThumbnailCornersVisible(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  final frame = tester.getRect(
    find.byKey(const ValueKey('media-thumbnail-frame')),
  );
  final localTopLeft = boundary.globalToLocal(frame.topLeft);
  final counts = await tester.runAsync(() async {
    const ratio = 2.0;
    final rendered = await boundary.toImage(pixelRatio: ratio);
    try {
      final pixels = (await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final counts = <int>[];
      for (final marker in [
        (0, 0, [213, 45, 53]),
        (1, 0, [39, 150, 78]),
        (0, 1, [36, 92, 196]),
        (1, 1, [232, 181, 43]),
      ]) {
        final left = ((localTopLeft.dx + marker.$1 * frame.width / 2) * ratio)
            .floor();
        final top = ((localTopLeft.dy + marker.$2 * frame.height / 2) * ratio)
            .floor();
        final right = (left + frame.width * ratio / 2).floor();
        final bottom = (top + frame.height * ratio / 2).floor();
        var count = 0;
        for (var y = top; y < bottom; y++) {
          for (var x = left; x < right; x++) {
            final offset = (y * rendered.width + x) * 4;
            if (List.generate(
              3,
              (channel) =>
                  (pixels.getUint8(offset + channel) - marker.$3[channel])
                      .abs() <=
                  20,
            ).every((matches) => matches)) {
              count++;
            }
          }
        }
        counts.add(count);
      }
      return counts;
    } finally {
      rendered.dispose();
    }
  });
  expect(
    counts,
    everyElement(greaterThan(0)),
    reason: 'All four image corners must survive the rounded thumbnail frame.',
  );
}

Future<void> capturePack(WidgetTester tester, String label) async {
  if (!const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  final previousShadows = debugDisableShadows;
  debugDisableShadows = false;
  try {
    repaint(boundary);
    await captureR66Visual(tester, label);
  } finally {
    debugDisableShadows = previousShadows;
    repaint(boundary);
    await tester.pump();
  }
}

final class _VariantFamilyAdapter implements BuyV2VariantFamilySource {
  _VariantFamilyAdapter(this.products);
  final List<BuyV2Product> products;
  String fault = '';
  final Set<String> withdrawn = {};
  int requests = 0;
  Future<BuyV2VariantFamilySnapshot> Function(
    BuyV2Product,
    BuyV2CatalogueQuery,
  )?
  handler;

  BuyV2VariantFamilySnapshot snapshot(
    BuyV2Product current,
    BuyV2CatalogueQuery context,
  ) {
    final choices = <(String, String), BuyV2VariantAttribute>{};
    for (final product in products) {
      if (fault == 'removed-choice' && withdrawn.contains(product.id)) continue;
      for (final option in product.variantAttributes) {
        choices[(option.dimensionId, option.optionId)] = option;
      }
    }
    final candidates = products
        .where(
          (product) =>
              !withdrawn.contains(product.id) &&
              product.variantAttributes
                      .where(
                        (a) => !current.variantAttributes.any(
                          (v) =>
                              v.dimensionId == a.dimensionId &&
                              v.optionId == a.optionId,
                        ),
                      )
                      .length <=
                  1,
        )
        .toList();
    if (fault == 'foreign') {
      candidates[0] = candidates[0].copyWith(storeId: 'foreign-store');
    }
    if (fault == 'duplicate') candidates.add(candidates.first);
    if (fault == 'ambiguous') {
      candidates.add(candidates.first.copyWith(id: 'same-options-other-id'));
    }
    final now = DateTime.now();
    return BuyV2VariantFamilySnapshot(
      productId: current.id,
      canonicalId: current.canonicalId,
      storeId: current.storeId!,
      destination: current.destination,
      queryKey: fault == 'context' ? 'wrong-context' : context.key,
      sourceId: 'family-test',
      revision: 'family-test-1',
      observedAt: fault == 'stale'
          ? now.subtract(const Duration(days: 1))
          : now,
      validUntil: fault == 'expired'
          ? now.subtract(const Duration(seconds: 1))
          : now.add(const Duration(hours: 1)),
      complete: fault != 'incomplete',
      selectedAvailable: !withdrawn.contains(current.id),
      options: [
        ...choices.values,
        if (fault == 'options') choices.values.first,
      ],
      candidates: candidates,
    );
  }

  @override
  Future<BuyV2VariantFamilySnapshot> loadVariantFamily(
    BuyV2Product selected,
    BuyV2CatalogueQuery context,
  ) async {
    requests++;
    if (fault == 'offline') throw StateError('Offline test source');
    return handler == null
        ? snapshot(selected, context)
        : await handler!(selected, context);
  }
}

void main() {
  testWidgets(
    'Public polish discovery cards expose validated Add and quantity controls',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      for (final scale in [1.0, 2.0]) {
        for (final id in ['s-milk', 'w-rice']) {
          final core = BuySession();
          final session = BuyV2Session(core: core);
          final current = session.product(id);
          session.openProduct(id);
          final other = session
              .productDiscoveryFor(
                current,
                includeVariants: true,
                excludedProductIds: session
                    .productContinuationsFor(current)
                    .map((p) => p.id)
                    .toSet(),
              )
              .first;
          session.openProduct(other.id);
          session.openProduct(id);
          expect(
            session
                .productDiscoveryFor(
                  current,
                  source: session.recentlyViewedProductsFor(
                    current.destination,
                  ),
                  excludedProductIds: session
                      .productContinuationsFor(current)
                      .map((p) => p.id)
                      .toSet(),
                  includeVariants: true,
                )
                .map((p) => p.id),
            contains(other.id),
            reason: '$id $scale',
          );
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
              home: BuyV2Screen(
                session: session,
                initialDestination: current.destination,
                initialView: BuyV2View.product,
                productId: id,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final card = find.byKey(
            ValueKey('buy-product-continuation-${other.id}'),
          );
          final scroll = find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$id')),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            card,
            350,
            scrollable: scroll,
            maxScrolls: 60,
          );
          final add = find.descendant(
            of: card,
            matching: find.byKey(ValueKey('buy-product-primary-${other.id}')),
          );
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          expect(add.hitTestable(), findsOneWidget);
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(session.quantityFor(other.id), other.minimumOrder);
          expect(session.quantityFor(id), 0);
          expect(
            session.selectedProductId,
            id,
            reason: 'Adding must not navigate to a different product.',
          );
          expect(
            find.descendant(
              of: card,
              matching: find.byKey(
                ValueKey('buy-product-quantity-${other.id}'),
              ),
            ),
            findsOneWidget,
          );
          expect(session.cartLines.single.product.storeId, other.storeId);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          session.dispose();
          core.dispose();
        }
      }
    },
  );

  testWidgets('Public polish hero and actions remain compact and readable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    for (final scale in [1.0, 2.0]) {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      session.openProduct('s-milk');
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
          home: BuyV2Screen(
            session: session,
            initialView: BuyV2View.product,
            productId: 's-milk',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final price = find.byKey(const ValueKey('buy-product-hero-price-s-milk'));
      final add = find.byKey(const ValueKey('buy-product-primary-s-milk'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(price).style!.color, const Color(0xFF24272B));
      final addFace = find.descendant(
        of: add,
        matching: find.byType(BuyV2AddFace),
      );
      expect(addFace, findsOneWidget);
      expect(tester.getSize(addFace), const Size(44, 32));
      if (scale == 1) {
        final hero = tester.getRect(
          find.byKey(const ValueKey('buy-product-purchase-hero-s-milk')),
        );
        expect(hero.width, greaterThan(300));
        expect(hero.height, lessThan(145));
        expect(tester.getRect(add).right, lessThanOrEqualTo(hero.right));
        final title = tester.getRect(
          find.byKey(const ValueKey('buy-product-title-s-milk')),
        );
        expect(tester.getRect(add).top, closeTo(title.top, 1));
        expect(tester.getRect(price).left, greaterThan(title.right));
      }
      expect(
        tester.getRect(add).left - tester.getRect(price).right,
        lessThanOrEqualTo(16),
      );
      final scroll = find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first;
      for (final key in [
        'buy-product-actions-scroll-s-milk',
        'buy-product-assurance-scroll-s-milk',
      ]) {
        final row = find.byKey(ValueKey(key));
        await tester.scrollUntilVisible(row, 250, scrollable: scroll);
        await tester.pumpAndSettle();
        expect(
          tester.widget<SingleChildScrollView>(row).scrollDirection,
          Axis.horizontal,
        );
        for (final label in [
          'Compare prices',
          'Cash on Delivery',
          'Customer support',
        ]) {
          final texts = find.descendant(of: row, matching: find.text(label));
          for (final text in tester.widgetList<Text>(texts)) {
            expect(text.softWrap, isFalse);
          }
        }
        await tester.drag(row, const Offset(-240, 0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      session.dispose();
      core.dispose();
    }
  });

  testWidgets('CAT08 paths retain exact variant through Cart and Saved', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    for (final scale in [1.0, 2.0]) {
      for (final entry in ['Shop', 'Wholesale', 'Bulk', 'Offers', 'Store']) {
        final core = BuySession();
        final store = _PackCustomerStore(const BuyV2CustomerStateSnapshot());
        final session = BuyV2Session(core: core, customerStateStore: store);
        await session.restoreCustomerState();
        final trade = entry == 'Wholesale' || entry == 'Bulk';
        final sourceId = trade
            ? 'w-rice'
            : entry == 'Offers'
            ? 'w-oil'
            : 's-milk';
        final variantId = trade
            ? 'w-rice-50kg'
            : entry == 'Offers'
            ? 'w-oil-10l'
            : 's-milk-500ml';
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
            home: BuyV2Screen(session: session),
          ),
        );
        await tester.pumpAndSettle();
        if (trade || entry == 'Offers') {
          await tester.tap(
            find.byKey(
              ValueKey(
                trade ? 'buy-local-tab-wholesale' : 'buy-local-tab-offers',
              ),
            ),
          );
          await tester.pumpAndSettle();
        }
        if (entry == 'Bulk') {
          await tester.tap(
            find.byKey(const ValueKey('buy-wholesale-sale-type-bulk')),
          );
          await tester.pumpAndSettle();
          expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.bulk);
        }
        if (entry != 'Offers') {
          await tester.tap(find.byKey(const ValueKey('buy-search-control')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('buy-search-field')),
            trade ? 'rice' : 'milk',
          );
          await tester.pumpAndSettle();
        }
        final sourceCard = find.byKey(ValueKey('buy-product-$sourceId'));
        if (entry == 'Offers') {
          await tester.scrollUntilVisible(
            sourceCard,
            180,
            scrollable: find
                .descendant(
                  of: find.byKey(const PageStorageKey('buy-offers')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
        }
        await tester.ensureVisible(sourceCard);
        await tester.pumpAndSettle();
        await tester.tap(sourceCard);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, sourceId, reason: '$entry $scale');
        if (entry == 'Store') {
          final action = find.byKey(
            ValueKey('buy-shop-seller-action-$sourceId'),
          );
          await tester.scrollUntilVisible(
            action,
            180,
            scrollable: find
                .descendant(
                  of: find.byKey(PageStorageKey('buy-product-$sourceId')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          await tester.tap(action);
          await tester.pumpAndSettle();
          final sheet = find.byKey(ValueKey('buy-shop-seller-sheet-$sourceId'));
          expect(sheet, findsOneWidget);
          final storeCard = find.descendant(of: sheet, matching: sourceCard);
          await tester.ensureVisible(storeCard);
          await tester.pumpAndSettle();
          await tester.tap(storeCard);
          await tester.pumpAndSettle();
        }
        final option = find
            .byKey(ValueKey('buy-product-variant-$variantId'))
            .last;
        final scroll = find
            .descendant(
              of: find.byKey(PageStorageKey('buy-product-$sourceId')).last,
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(option, 160, scrollable: scroll);
        await tester.ensureVisible(option);
        await tester.pumpAndSettle();
        await tester.tap(option);
        await tester.pumpAndSettle();
        final selected = session.selectedProduct!;
        expect(selected.id, variantId);
        expect(selected.storeId, session.product(sourceId).storeId);
        final add = find.byKey(ValueKey('buy-product-primary-$variantId')).last;
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(session.quantityFor(variantId), selected.minimumOrder);
        expect(session.quantityFor(sourceId), 0);
        final save = find.byKey(ValueKey('buy-product-action-save-$variantId'));
        await tester.scrollUntilVisible(
          save,
          -200,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$variantId')).last,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(session.isSaved(variantId), isTrue);
        final cart = find
            .byKey(const ValueKey('buy-cart-navigation-button'))
            .last;
        await tester.tap(cart);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(session.cartLines.single.product.id, variantId);
        expect(session.cartLines.single.product.storeId, selected.storeId);
        expect(session.cartLines.single.product.pack, selected.pack);
        expect(session.cartLines.single.product.price, selected.price);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.selectedProductId, variantId);
        expect(session.view, BuyV2View.product);
        expect(tester.takeException(), isNull, reason: '$entry $scale');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        session.dispose();
        core.dispose();
        final restoredCore = BuySession();
        final restored = BuyV2Session(
          core: restoredCore,
          customerStateStore: store,
        );
        await restored.restoreCustomerState();
        expect(restored.quantityFor(variantId), selected.minimumOrder);
        expect(restored.isSaved(variantId), isTrue);
        expect(restored.cartLines.single.product.id, variantId);
        expect(restored.cartLines.single.product.storeId, selected.storeId);
        expect(restored.openProduct(variantId), isTrue);
        expect(restored.selectedProduct?.pack, selected.pack);
        restored.dispose();
        restoredCore.dispose();
      }
    }
  });

  BuyV2Product packProduct({BuyV2PackTerms? terms}) =>
      BuyV2Catalogue.products.first.copyWith(
        id: 'case-review',
        storeId: 'case-store',
        minimumOrder: 2,
        packTerms:
            terms ??
            const BuyV2PackTerms(
              skuId: 'case-review',
              revision: '1',
              sellUnit: 'Case',
              containedUnits: 10,
              netContentMilli: 500000,
              contentUnit: 'g',
              quantityStep: 3,
            ),
      );

  Future<BuyV2Session> packSession(
    BuyV2Product product, {
    DateTime Function()? now,
    BuyV2CustomerStateStore? stateStore,
  }) async {
    final core = BuySession();
    final session = BuyV2Session(
      core: core,
      commerceAdapter: _MediaCommerce(product),
      reviewDataEnabled: false,
      productFactsAdapter: QualifiedTestProductFacts({product.id}),
      catalogueNow: now ?? DateTime.now,
      customerStateStore: stateStore,
    );
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    await session.restoreCommerce();
    return session;
  }

  test(
    'CAT04 provider pack terms preserve composition and legal quantities',
    () async {
      final product = packProduct();
      expect(product.pack, '10 × 500 g · Case');
      expect(product.unitPrice, isEmpty);
      final session = await packSession(product);
      expect(session.addProduct(product.id), isTrue);
      expect(session.quantityFor(product.id), 2);
      session.increase(product.id);
      expect(session.quantityFor(product.id), 5);
      expect(session.setCartQuantity(product.id, '4'), isFalse);
      expect(session.quantityFor(product.id), 5);
      expect(session.setCartQuantity(product.id, '8'), isTrue);
      session.decrease(product.id);
      expect(session.quantityFor(product.id), 5);
      expect(session.addProduct(product.id), isTrue);
      expect(session.quantityFor(product.id), 8);
      expect(
        session.cartLines.single.product.packTerms,
        same(product.packTerms),
      );
      expect(session.cartTotal, product.price * 8);
      expect(session.setCartQuantity(product.id, '2'), isTrue);
      session.decrease(product.id);
      expect(session.cartLines, isEmpty);
      for (final (value, unit, label) in [
        (500000, 'g', '500 g'),
        (1000, 'kg', '1 kg'),
        (1000, 'piece', '1 piece'),
      ]) {
        final terms = BuyV2PackTerms(
          skuId: 'one',
          revision: '1',
          sellUnit: 'Pack',
          netContentMilli: value,
          contentUnit: unit,
        );
        expect(terms.isValidFor('one'), isTrue);
        expect(terms.label, '$label · Pack');
      }
    },
  );

  test(
    'CAT04 pack validation rejects missing units and unconfirmed measurement',
    () async {
      for (final terms in [
        const BuyV2PackTerms(skuId: 'other', revision: '1', sellUnit: 'Case'),
        const BuyV2PackTerms(
          skuId: 'case-review',
          revision: '1',
          sellUnit: 'Case',
          quantityStep: 0,
        ),
        const BuyV2PackTerms(
          skuId: 'case-review',
          revision: '1',
          sellUnit: 'Case',
          netContentMilli: 500000,
        ),
        const BuyV2PackTerms(
          skuId: 'case-review',
          revision: '1',
          sellUnit: 'Case',
          contentUnit: 'g',
        ),
        const BuyV2PackTerms(
          skuId: 'case-review',
          revision: '1',
          sellUnit: 'Case',
          netContentMilli: 500,
          contentUnit: 'piece',
        ),
        const BuyV2PackTerms(
          skuId: 'case-review',
          revision: '1',
          sellUnit: 'Case',
          requiresMeasurement: true,
        ),
      ]) {
        final product = packProduct(terms: terms);
        final session = await packSession(product);
        expect(session.addProduct(product.id), isFalse);
        expect(session.cartLines, isEmpty);
        expect(session.productFactsFor(product).stale, isTrue);
      }
    },
  );

  BuyV2Product tierProduct(
    DateTime now, {
    String storeId = 'case-store',
    List<BuyV2PackPriceTier> tiers = const [
      BuyV2PackPriceTier(minimumPacks: 2, price: 400),
      BuyV2PackPriceTier(minimumPacks: 5, price: 380),
      BuyV2PackPriceTier(minimumPacks: 8, price: 360),
    ],
  }) => packProduct(
    terms: BuyV2PackTerms(
      skuId: 'case-review',
      revision: 'tier-1',
      sellUnit: 'Case',
      containedUnits: 4,
      netContentMilli: 1000,
      contentUnit: 'L',
      quantityStep: 3,
      pricingStoreId: storeId,
      priceObservedAt: now.subtract(const Duration(minutes: 1)),
      priceValidUntil: now.add(const Duration(minutes: 10)),
      priceTiers: tiers,
    ),
  ).copyWith(price: 400);

  test('CAT04 tiers reprice complete Cart line in both directions', () async {
    final now = DateTime.now();
    final product = tierProduct(now);
    final session = await packSession(product, now: () => now);
    expect(session.addProduct(product.id), isTrue);
    expect(session.cartTotal, 800);
    session.increase(product.id);
    expect(session.quantityFor(product.id), 5);
    expect(session.cartLines.single.product.price, 380);
    expect(session.cartTotal, 1900);
    expect(session.productFactsFor(product).price, 380);
    expect(session.setCartQuantity(product.id, '4'), isFalse);
    expect(session.cartTotal, 1900);
    expect(session.addProduct(product.id), isTrue);
    expect(session.cartTotal, 2880);
    session.decrease(product.id);
    expect(session.cartTotal, 1900);
    session.decrease(product.id);
    expect(session.cartTotal, 800);
    expect(session.cartLines.single.product.packTerms!.revision, 'tier-1');
    expect(session.cartLines.single.product.storeId, 'case-store');
  });

  test(
    'CAT04 invalid and expired tiers cannot authorize Add or checkout',
    () async {
      var now = DateTime.now();
      for (final product in [
        tierProduct(now, storeId: 'foreign-store'),
        tierProduct(
          now,
          tiers: const [
            BuyV2PackPriceTier(minimumPacks: 2, price: 400),
            BuyV2PackPriceTier(minimumPacks: 2, price: 380),
          ],
        ),
        tierProduct(
          now,
          tiers: const [
            BuyV2PackPriceTier(minimumPacks: 2, price: 400),
            BuyV2PackPriceTier(minimumPacks: 5, price: -1),
          ],
        ),
      ]) {
        final session = await packSession(product, now: () => now);
        expect(session.addProduct(product.id), isFalse);
        expect(session.cartLines, isEmpty);
      }
      final product = tierProduct(now);
      final session = await packSession(product, now: () => now);
      expect(session.addProduct(product.id), isTrue);
      now = now.add(const Duration(minutes: 11));
      expect(session.productFactsFor(product).stale, isTrue);
      expect(session.addProduct(product.id), isFalse);
      expect(session.setCartQuantity(product.id, '5'), isFalse);
      expect(session.openCheckout(), isFalse);
      expect(session.cartTotal, 800);
      session.remove(product.id);
      expect(session.cartLines, isEmpty);
    },
  );

  test(
    'CAT04 tier prices keep offer controls available without masking real price changes',
    () async {
      final product = tierProduct(DateTime.now());
      final session = await packSession(product);
      expect(session.addProduct(product.id), isTrue);
      for (final quantity in [2, 5, 8, 5, 2]) {
        expect(session.setCartQuantity(product.id, '$quantity'), isTrue);
        final facts = session.productFactsFor(product);
        expect(
          buyV2ResolveProductOfferDecision(
            product: product,
            facts: facts,
            quantity: quantity,
          ).canAdd,
          isTrue,
        );
        expect(
          buyV2ResolveProductOfferDecision(
            product: product,
            facts: facts.copyWith(price: facts.price + 1),
            quantity: quantity,
          ).state,
          BuyV2ProductOfferDecisionState.changedPrice,
        );
        expect(
          buyV2ResolveProductOfferDecision(
            product: product,
            facts: facts.copyWith(stale: true),
            quantity: quantity,
          ).canAdd,
          isFalse,
        );
      }
    },
  );

  testWidgets(
    'CAT04 tier table and Cart totals stay consistent at enlarged text',
    (tester) async {
      for (final scale in [1.0, 2.0]) {
        final product = tierProduct(DateTime.now());
        final session = await packSession(product);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: BuyV2Screen(session: session, productId: product.id),
          ),
        );
        await tester.pumpAndSettle();
        final details = find.byKey(
          ValueKey('buy-product-price-details-${product.id}'),
        );
        await tester.scrollUntilVisible(
          details,
          140,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-${product.id}')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(details);
        await tester.pumpAndSettle();
        expect(find.text('5+ packs'), findsOneWidget);
        expect(find.text('₹380 / Case'), findsOneWidget);
        expect(find.text('Not yet confirmed'), findsNWidgets(2));
        expect(find.text('Total'), findsNothing);
        expect(session.addProduct(product.id), isTrue);
        session.increase(product.id);
        await tester.pumpAndSettle();
        expect(session.productFactsFor(product).price, 380);
        final quantityControl = find.byKey(
          ValueKey('buy-product-quantity-${product.id}'),
        );
        await tester.ensureVisible(quantityControl);
        await tester.pumpAndSettle();
        expect(quantityControl.hitTestable(), findsOneWidget);
        expect(find.text('Price changed'), findsNothing);
        session.openCart();
        await tester.pumpAndSettle();
        expect(session.cartTotal, 1900);
        expect(find.text('₹1,900'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  test(
    'CAT04 restored Cart uses exact pack tier and preserves Saved identity',
    () async {
      final product = tierProduct(DateTime.now());
      final key = 'shop|listing:${Uri.encodeComponent(product.id)}';
      final store = _PackCustomerStore(
        BuyV2CustomerStateSnapshot(
          cartQuantities: {product.id: 5},
          savedProductKeys: {key},
        ),
      );
      final session = await packSession(product, stateStore: store);
      await session.restoreCustomerState();
      expect(session.cartLines.single.product.id, product.id);
      expect(session.cartLines.single.product.storeId, product.storeId);
      expect(session.cartLines.single.product.pack, '4 × 1 L · Case');
      expect(session.quantityFor(product.id), 5);
      expect(session.cartTotal, 1900);
      expect(session.cartLines.single.product.price, 380);
      expect(store.snapshot.savedProductKeys, contains(key));
    },
  );

  test(
    'CAT04 reorder uses current tier without rewriting historical order',
    () async {
      final product = tierProduct(DateTime.now());
      final session = await packSession(product);
      final order = BuyV2Order(
        id: 'historical-tier-order',
        destination: product.destination,
        title: product.title,
        itemSummary: product.pack,
        total: 2100,
        partner: 'Previous supplier',
        partnerType: 'Retailer',
        promise: 'Delivered',
        destinationLabel: 'Shop',
        progress: 1,
        status: BuyV2OrderStatus.delivered,
        productIds: [product.id],
        lines: [
          BuyV2CartLine(product: product.copyWith(price: 420), quantity: 5),
        ],
      );
      expect(session.reorder(order), isTrue);
      expect(session.quantityFor(product.id), 2);
      expect(session.cartTotal, 800);
      expect(session.reorder(order), isTrue);
      expect(session.quantityFor(product.id), 5);
      expect(session.cartTotal, 1900);
      expect(order.total, 2100);
      expect(order.lines.single.product.price, 420);
      expect(order.lines.single.total, 2100);
    },
  );

  testWidgets(
    'CAT04 pack step controls preserve exact SKU in product and Cart',
    (tester) async {
      for (final scale in [1.0, 2.0]) {
        final product = packProduct();
        final session = await packSession(product);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: BuyV2Screen(session: session, productId: product.id),
          ),
        );
        await tester.pumpAndSettle();
        final add = find.byKey(ValueKey('buy-product-primary-${product.id}'));
        await tester.scrollUntilVisible(
          add,
          120,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-${product.id}')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(session.quantityFor(product.id), 2);
        expect(find.text('Minimum 2 packs · Step 3'), findsOneWidget);
        await tester.tap(find.byTooltip('Add 3 packs'));
        await tester.pumpAndSettle();
        expect(session.quantityFor(product.id), 5);
        session.openCart();
        await tester.pumpAndSettle();
        expect(session.cartLines.single.product.id, product.id);
        expect(find.textContaining('10 × 500 g'), findsWidgets);
        final cartIncrease = find.byTooltip('Add 3 packs');
        await tester.ensureVisible(cartIncrease);
        await tester.pumpAndSettle();
        await tester.tap(cartIncrease);
        await tester.pumpAndSettle();
        expect(session.quantityFor(product.id), 8);
        session.goBack();
        await tester.pumpAndSettle();
        expect(session.selectedProductId, product.id);
        expect(session.quantityFor(product.id), 8);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  test('CAT08 restore rejects same SKU reassigned to another Store', () async {
    final product = BuyV2Catalogue.products.first.copyWith(
      storeId: 'original-store',
    );
    final store = _PackCustomerStore(const BuyV2CustomerStateSnapshot());
    final first = await packSession(product, stateStore: store);
    await first.restoreCustomerState();
    expect(first.addProduct(product.id), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(store.snapshot.cartQuantities[product.id], product.minimumOrder);
    final restored = await packSession(
      product.copyWith(storeId: 'foreign-store'),
      stateStore: store,
    );
    await restored.restoreCustomerState();
    expect(restored.customerStateRecoveryPending, isTrue);
    expect(restored.cartLines, isEmpty);
    expect(store.snapshot.cartQuantities[product.id], product.minimumOrder);
  });

  test(
    'CAT08 restore allows display and price updates for exact identity',
    () async {
      final product = BuyV2Catalogue.products.first.copyWith(
        storeId: 'original-store',
      );
      final store = _PackCustomerStore(const BuyV2CustomerStateSnapshot());
      final first = await packSession(product, stateStore: store);
      await first.restoreCustomerState();
      expect(first.addProduct(product.id), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(store.snapshot.productIdentityKeys, contains(product.id));
      final restored = await packSession(
        product.copyWith(
          title: 'Updated product label',
          price: product.price + 1,
        ),
        stateStore: store,
      );
      await restored.restoreCustomerState();
      expect(restored.customerStateRecoveryPending, isFalse);
      expect(restored.cartLines.single.product.title, 'Updated product label');
      expect(restored.cartLines.single.product.price, product.price + 1);
      expect(restored.quantityFor(product.id), product.minimumOrder);
    },
  );

  test(
    'CAT08 restore rejects same SKU reassigned to another product family',
    () async {
      final product = BuyV2Catalogue.products.first.copyWith(
        storeId: 'original-store',
      );
      final store = _PackCustomerStore(const BuyV2CustomerStateSnapshot());
      final first = await packSession(product, stateStore: store);
      await first.restoreCustomerState();
      expect(first.addProduct(product.id), isTrue);
      await Future<void>.delayed(Duration.zero);
      final restored = await packSession(
        product.copyWith(canonicalId: 'different-product-family'),
        stateStore: store,
      );
      await restored.restoreCustomerState();
      expect(restored.customerStateRecoveryPending, isTrue);
      expect(restored.cartLines, isEmpty);
      expect(restored.openProduct(product.id), isFalse);
      expect(restored.addProduct(product.id), isFalse);
      expect(store.snapshot.cartQuantities[product.id], product.minimumOrder);
    },
  );

  test(
    'CAT04 restored invalid pack step requires correction before checkout',
    () async {
      final product = tierProduct(DateTime.now());
      final store = _PackCustomerStore(
        BuyV2CustomerStateSnapshot(cartQuantities: {product.id: 4}),
      );
      final session = await packSession(product, stateStore: store);
      await session.restoreCustomerState();
      expect(session.quantityFor(product.id), 4);
      expect(session.openCheckout(), isFalse);
      expect(session.setCartQuantity(product.id, '5'), isTrue);
      expect(session.cartTotal, 1900);
      expect(session.openCheckout(), isTrue);
    },
  );

  List<BuyV2Product> structuredFamily() {
    final base = BuyV2Catalogue.products.first;
    return [
      for (final colour in ['blue', 'black'])
        for (final storage in ['128', '256'])
          base.copyWith(
            id: 'phone-$colour-$storage',
            canonicalId: 'test-phone-family',
            storeId: 'variant-store',
            title: 'Review phone',
            variant: '$colour $storage GB',
            pack: 'One unit',
            price:
                (storage == '128' ? 10000 : 14000) +
                (colour == 'blue' ? 500 : 0),
            variantAttributes: [
              BuyV2VariantAttribute(
                dimensionId: 'colour',
                dimensionLabel: 'Colour',
                optionId: colour,
                optionLabel: colour,
                kind: BuyV2VariantDimensionKind.colour,
                swatchArgb: colour == 'blue' ? 0xff3366aa : 0xff222222,
              ),
              BuyV2VariantAttribute(
                dimensionId: 'storage',
                dimensionLabel: 'Storage',
                optionId: storage,
                optionLabel: '$storage GB',
                kind: BuyV2VariantDimensionKind.storage,
              ),
            ],
          ),
    ];
  }

  List<BuyV2Product> completeFamily() {
    final base = structuredFamily().first;
    return [
      for (var colour = 0; colour < 3; colour++)
        for (var storage = 0; storage < 5; storage++)
          base.copyWith(
            id: 'complete-$colour-$storage',
            price: 10000 + colour * 100 + storage * 1000,
            variant: 'Colour $colour / Storage $storage',
            variantAttributes: [
              BuyV2VariantAttribute(
                dimensionId: 'colour',
                dimensionLabel: 'Colour',
                optionId: '$colour',
                optionLabel: 'Colour $colour',
                kind: BuyV2VariantDimensionKind.colour,
                swatchArgb: 0xff224466 + colour * 3000,
              ),
              BuyV2VariantAttribute(
                dimensionId: 'storage',
                dimensionLabel: 'Storage',
                optionId: '$storage',
                optionLabel: '${128 * (storage + 1)} GB',
                kind: BuyV2VariantDimensionKind.storage,
              ),
            ],
          ),
    ];
  }

  test(
    'CAT02 complete family resolves later-page choices without changing other options',
    () async {
      final family = completeFamily();
      final adapter = _VariantFamilyAdapter(family);
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        variantFamilySource: adapter,
        commerceAdapter: _MediaCommerce(family.first),
        reviewDataEnabled: false,
        productFactsAdapter: QualifiedTestProductFacts(
          family.map((p) => p.id).toSet(),
        ),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      expect(session.findProduct('complete-0-4'), isNull);
      session.openProduct(family.first.id);
      expect(await session.refreshVariantFamily(family.first), isTrue);
      final snapshot = session.variantFamilyFor(session.selectedProduct!)!;
      expect(
        snapshot.options.where((o) => o.dimensionId == 'colour').length,
        3,
      );
      expect(
        snapshot.options.where((o) => o.dimensionId == 'storage').length,
        5,
      );
      expect(
        snapshot.candidates.length,
        7,
      ); // Selected plus 2 colours and 4 storage choices, not 15 combinations.
      final target = session.selectedProduct!.resolveVariantOption(
        session.productVariantsFor(session.selectedProduct!),
        'storage',
        '4',
      )!;
      expect(target.id, 'complete-0-4');
      expect(session.selectProductVariant(target.id), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(
        await session.refreshVariantFamily(session.selectedProduct!),
        isTrue,
      );
      expect(session.selectedProduct!.variantAttributes.first.optionId, '0');
      expect(session.addProduct(target.id), isTrue);
      expect(session.cartLines.single.product.id, target.id);
      expect(session.cartLines.single.product.price, target.price);
    },
  );

  test(
    'CAT02 development family lookup stays bounded in a million SKU catalogue',
    () async {
      for (final destination in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        final source = BuyV2DevelopmentCatalogueSource(
          destination: destination,
          providerCount: 1000,
          skusPerStore: 1000,
          includeVariantReviewFixtures: true,
        );
        final context = BuyV2CatalogueQuery(
          destination: destination,
          regionId: 'jodhpur',
          storeId: source.storeIdAt(0),
          query: 'iphone',
        );
        final page = await source.loadProducts(context, pageSize: 1);
        expect(page.items.length, 1);
        final before = source.productObjectsCreated;
        final family = await source.loadVariantFamily(
          page.items.single,
          context,
        );
        expect(
          family.isValidFor(page.items.single, context, DateTime.now()),
          isTrue,
        );
        expect(
          family.options
              .where((option) => option.dimensionId == 'colour')
              .length,
          2,
        );
        expect(
          family.options
              .where((option) => option.dimensionId == 'storage')
              .length,
          3,
        );
        expect(family.candidates.length, 4);
        expect(source.productObjectsCreated - before, 4);
        expect(source.variantFamilyRequests, 1);
      }
    },
  );

  test(
    'CAT02 rejects incomplete foreign duplicate and stale family responses',
    () async {
      final family = completeFamily();
      final adapter = _VariantFamilyAdapter(family);
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        variantFamilySource: adapter,
        commerceAdapter: _MediaCommerce(family.first),
        reviewDataEnabled: false,
        productFactsAdapter: QualifiedTestProductFacts(
          family.map((p) => p.id).toSet(),
        ),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      session.openProduct(family.first.id);
      expect(await session.refreshVariantFamily(family.first), isTrue);
      for (final fault in [
        'incomplete',
        'foreign',
        'duplicate',
        'ambiguous',
        'options',
        'context',
        'stale',
        'expired',
        'offline',
      ]) {
        adapter.fault = fault;
        expect(
          await session.refreshVariantFamily(family.first),
          isFalse,
          reason: fault,
        );
        expect(session.selectedProductId, family.first.id);
        expect(session.productVariantsFor(family.first).length, 7);
        expect(session.variantFamilyMessageFor(family.first), isNotNull);
      }
      adapter.fault = '';
      final oldResponse = Completer<BuyV2VariantFamilySnapshot>();
      late BuyV2CatalogueQuery oldContext;
      var delayed = false;
      adapter.handler = (selected, context) {
        if (!delayed && selected.id == family.first.id) {
          delayed = true;
          oldContext = context;
          return oldResponse.future;
        }
        return Future.value(adapter.snapshot(selected, context));
      };
      final oldRequest = session.refreshVariantFamily(family.first);
      await Future<void>.delayed(Duration.zero);
      expect(session.selectProductVariant('complete-0-4'), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(
        session.variantFamilyFor(session.selectedProduct!)?.productId,
        'complete-0-4',
      );
      oldResponse.complete(adapter.snapshot(family.first, oldContext));
      expect(await oldRequest, isFalse);
      expect(session.selectedProductId, 'complete-0-4');
      expect(
        session.variantFamilyFor(session.selectedProduct!)?.productId,
        'complete-0-4',
      );
      adapter.handler = null;
      adapter.fault = 'removed-choice';
      adapter.withdrawn.addAll(
        family.where((p) => p.id.endsWith('-4')).map((p) => p.id),
      );
      expect(
        await session.refreshVariantFamily(session.selectedProduct!),
        isTrue,
      );
      expect(session.addProduct('complete-0-4'), isFalse);
      expect(
        session.productFactsFor(session.selectedProduct!).orderabilityLabel,
        'Unavailable',
      );
      adapter.withdrawn.clear();
      adapter.fault = '';
      expect(
        await session.refreshVariantFamily(session.selectedProduct!),
        isTrue,
      );
      expect(session.variantWithdrawn(session.selectedProduct!), isFalse);
      expect(session.addProduct(session.selectedProductId!), isTrue);
    },
  );

  testWidgets(
    'CAT02 shared selectors show complete family and preserve cart on retry',
    (tester) async {
      for (final scale in [1.0, 2.0]) {
        final family = completeFamily();
        final adapter = _VariantFamilyAdapter(family);
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          variantFamilySource: adapter,
          commerceAdapter: _MediaCommerce(family.first),
          reviewDataEnabled: false,
          productFactsAdapter: QualifiedTestProductFacts(
            family.map((p) => p.id).toSet(),
          ),
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await session.restoreCommerce();
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: BuyV2Screen(session: session, productId: family.first.id),
          ),
        );
        await tester.pumpAndSettle();
        final option = find.byKey(
          const ValueKey('buy-product-option-storage-4'),
        );
        final scroll = find
            .descendant(
              of: find.byKey(PageStorageKey('buy-product-${family.first.id}')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.byKey(
            ValueKey('buy-product-variants-${family.first.canonicalId}'),
          ),
          160,
          scrollable: scroll,
        );
        await tester.ensureVisible(option);
        await tester.pumpAndSettle();
        await tester.tap(option);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, 'complete-0-4');
        expect(session.addProduct(session.selectedProductId!), isTrue);
        session.openCart();
        await tester.pumpAndSettle();
        session.goBack();
        await tester.pumpAndSettle();
        expect(session.selectedProductId, 'complete-0-4');
        expect(session.cartLines.single.product.id, 'complete-0-4');
        adapter.fault = 'offline';
        await session.refreshVariantFamily(session.selectedProduct!);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, 'complete-0-4');
        expect(session.cartLines.single.product.id, 'complete-0-4');
        adapter.fault = '';
        expect(
          await session.refreshVariantFamily(session.selectedProduct!),
          isTrue,
        );
        await tester.pumpAndSettle();
        expect(
          session.variantFamilyMessageFor(session.selectedProduct!),
          isNull,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets('CAT02 six colour size and storage choices stay reachable', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      final base = structuredFamily().first;
      final family = [
        for (var colour = 0; colour < 6; colour++)
          for (var size = 0; size < 6; size++)
            for (var storage = 0; storage < 6; storage++)
              base.copyWith(
                id: 'six-$colour-$size-$storage',
                variant: '$colour / $size / $storage',
                price: 10000 + storage * 1000 + size * 100 + colour * 10,
                variantAttributes: [
                  BuyV2VariantAttribute(
                    dimensionId: 'colour',
                    dimensionLabel: 'Colour',
                    optionId: '$colour',
                    optionLabel: 'Colour $colour',
                    kind: BuyV2VariantDimensionKind.colour,
                    swatchArgb: 0xff3366aa + colour * 8000,
                  ),
                  BuyV2VariantAttribute(
                    dimensionId: 'size',
                    dimensionLabel: 'Size',
                    optionId: '$size',
                    optionLabel: ['XS', 'S', 'M', 'L', 'XL', 'XXL'][size],
                    kind: BuyV2VariantDimensionKind.size,
                  ),
                  BuyV2VariantAttribute(
                    dimensionId: 'storage',
                    dimensionLabel: 'Storage',
                    optionId: '$storage',
                    optionLabel: '${128 * (storage + 1)} GB',
                    kind: BuyV2VariantDimensionKind.storage,
                  ),
                ],
              ),
      ];
      final adapter = _VariantFamilyAdapter(family);
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        variantFamilySource: adapter,
        commerceAdapter: _MediaCommerce(family.first),
        reviewDataEnabled: false,
        productFactsAdapter: QualifiedTestProductFacts(
          family.map((p) => p.id).toSet(),
        ),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 800);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await session.restoreCommerce();
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(session: session, productId: family.first.id),
        ),
      );
      await tester.pumpAndSettle();
      for (final dimension in ['colour', 'size', 'storage']) {
        final current = session.selectedProduct!;
        expect(session.variantFamilyFor(current)!.options.length, 18);
        expect(session.variantFamilyFor(current)!.candidates.length, 16);
        final section = find.byKey(
          ValueKey('buy-product-variants-${current.canonicalId}'),
        );
        final scroll = find
            .descendant(
              of: find.byKey(PageStorageKey('buy-product-${current.id}')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(section, 140, scrollable: scroll);
        final option = find.byKey(ValueKey('buy-product-option-$dimension-5'));
        await tester.ensureVisible(option);
        await tester.pumpAndSettle();
        expect(option.hitTestable(), findsOneWidget);
        await tester.tap(option);
        await tester.pumpAndSettle();
        expect(
          session.selectedProduct!.variantAttributes
              .firstWhere((a) => a.dimensionId == dimension)
              .optionId,
          '5',
        );
        expect(tester.takeException(), isNull);
      }
      expect(session.selectedProductId, 'six-5-5-5');
      expect(session.addProduct(session.selectedProductId!), isTrue);
      expect(session.cartLines.single.product.id, 'six-5-5-5');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  test(
    'structured variants preserve dimensions and reject ambiguous or foreign offers',
    () {
      final family = structuredFamily();
      final current = family.first;
      expect(
        current.copyWith(price: 999).variantAttributes,
        current.variantAttributes,
      );
      expect(
        current.resolveVariantOption(family, 'colour', 'black')?.id,
        'phone-black-128',
      );
      expect(
        current.resolveVariantOption(family, 'storage', '256')?.id,
        'phone-blue-256',
      );
      expect(current.resolveVariantOption(family, 'storage', '512'), isNull);
      expect(
        current.resolveVariantOption(
          [current, family[1].copyWith(storeId: 'foreign')],
          'storage',
          '256',
        ),
        isNull,
      );
      expect(
        current.resolveVariantOption(
          [...family, family[1].copyWith(id: 'duplicate-offer')],
          'storage',
          '256',
        ),
        isNull,
      );
      final malformed = current.copyWith(
        variantAttributes: [
          current.variantAttributes.first,
          current.variantAttributes.first,
        ],
      );
      expect(malformed.hasStructuredVariants, isFalse);
      expect(malformed.resolveVariantOption(family, 'storage', '256'), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'structured variant controls preserve exact selected SKU and cart $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final bytes = (await tester.runAsync(
          () => _mediaFitFixture(512, 512),
        ))!;
        final previousClient = debugNetworkImageHttpClientProvider;
        final client = _MediaHttpClient(bytes);
        debugNetworkImageHttpClientProvider = () => client;
        try {
          final family = structuredFamily()
              .map(
                (product) => product.copyWith(
                  mediaAssets: [
                    BuyV2ProductMediaAsset(
                      id: 'photo-${product.id}',
                      label: 'Exact variant photo',
                      semanticLabel: 'Photo of ${product.variant}',
                      kind: BuyV2ProductContentMediaKind.network,
                      source: 'https://media.example.com/${product.id}.png',
                      binding: BuyV2ProductMediaBinding(
                        supplierWorkspaceId: 'variant-workspace',
                        storeId: product.storeId!,
                        productId: product.canonicalId,
                        skuId: product.id,
                        assetRevision: 'variant-1',
                        file: BuyV2MediaFileMetadata(
                          mimeType: 'image/png',
                          width: 512,
                          height: 512,
                          byteLength: bytes.length,
                          normalized: true,
                          frameCount: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList();
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            productFactsAdapter: QualifiedTestProductFacts(
              family.map((p) => p.id).toSet(),
            ),
            commerceAdapter: _MediaCommerce(
              family.first,
              otherProducts: family.skip(1).toList(),
            ),
            reviewDataEnabled: false,
          );
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          await session.restoreCommerce();
          expect(session.openProduct(family.first.id), isTrue);
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              home: BuyV2Screen(
                session: session,
                initialDestination: session.destination,
                initialView: session.view,
                productId: family.first.id,
              ),
            ),
          );
          await tester.runAsync(() async {
            for (final product in family) {
              await precacheImage(
                NetworkImage(product.mediaAssets.single.source!),
                tester.element(find.byType(BuyV2Screen)),
              );
            }
          });
          await tester.pumpAndSettle();
          void expectPhoto(String sku) {
            final image = tester.widget<Image>(
              find.descendant(
                of: find.byKey(ValueKey('buy-product-packshot-$sku')),
                matching: find.byType(Image),
              ),
            );
            expect(
              (image.image as NetworkImage).url,
              'https://media.example.com/$sku.png',
            );
          }

          expectPhoto('phone-blue-128');
          Future<void> choose(String dimension, String option) async {
            final target = find.byKey(
              ValueKey('buy-product-option-$dimension-$option'),
            );
            await tester.scrollUntilVisible(
              target,
              150,
              scrollable: find
                  .descendant(
                    of: find.byKey(
                      PageStorageKey(
                        'buy-product-${session.selectedProductId}',
                      ),
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.ensureVisible(target);
            await tester.pumpAndSettle();
            expect(target.hitTestable(), findsOneWidget);
            await tester.tap(target);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }

          await choose('storage', '256');
          expect(session.selectedProductId, 'phone-blue-256');
          expect(session.selectedProduct!.price, 14500);
          expectPhoto('phone-blue-256');
          expect(session.addProduct(session.selectedProductId!), isTrue);
          await tester.pumpAndSettle();
          await choose('colour', 'black');
          expect(session.selectedProductId, 'phone-black-256');
          expect(session.selectedProduct!.price, 14000);
          expectPhoto('phone-black-256');
          expect(session.addProduct(session.selectedProductId!), isTrue);
          expect(session.quantityFor('phone-blue-256'), 1);
          expect(session.quantityFor('phone-black-256'), 1);
          expect(session.cartLines.map((line) => line.product.id).toSet(), {
            'phone-blue-256',
            'phone-black-256',
          });
          expect(tester.takeException(), isNull);
        } finally {
          debugNetworkImageHttpClientProvider = previousClient;
          imageCache.clear();
          imageCache.clearLiveImages();
        }
      },
    );
  }
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'missing variant combination preserves selection and cart $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final family = structuredFamily()
            .where((p) => p.id != 'phone-black-128')
            .toList();
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          productFactsAdapter: QualifiedTestProductFacts(
            family.map((p) => p.id).toSet(),
          ),
          commerceAdapter: _MediaCommerce(
            family.first,
            otherProducts: family.skip(1).toList(),
          ),
          reviewDataEnabled: false,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        await session.restoreCommerce();
        expect(session.openProduct(family.first.id), isTrue);
        expect(session.addProduct(family.first.id), isTrue);
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: BuyV2Screen(
              session: session,
              initialDestination: session.destination,
              initialView: session.view,
              productId: family.first.id,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final unavailable = find.byKey(
          const ValueKey('buy-product-option-colour-black'),
        );
        final fallback = find.byKey(
          const ValueKey('buy-product-option-colour-blue'),
        );
        expect(fallback, findsOneWidget);
        expect(
          find.descendant(of: fallback, matching: find.byType(Image)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: fallback,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is DecoratedBox &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration as BoxDecoration).color ==
                      const Color(0xff3366aa),
            ),
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(unavailable);
        await tester.pumpAndSettle();
        expect(tester.widget<InkResponse>(unavailable).onTap, isNull);
        expect(
          find.descendant(of: unavailable, matching: find.byIcon(Icons.close)),
          findsOneWidget,
        );
        await tester.tap(unavailable);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, 'phone-blue-128');
        expect(session.cartLines.single.product.id, 'phone-blue-128');
        expect(session.quantityFor('phone-blue-128'), 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final count in [1, 2, 3, 4, 5, 6, 12]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('many variant options keep selection visible $count $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 800);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final base = structuredFamily().first;
        final family = [
          for (var i = 0; i < count; i++)
            base.copyWith(
              id: 'many-$i',
              price: 10000 + i * 1000,
              variantAttributes: [
                BuyV2VariantAttribute(
                  dimensionId: 'storage',
                  dimensionLabel: 'Storage',
                  optionId: '$i',
                  optionLabel: '${(i + 1) * 64} GB',
                  kind: BuyV2VariantDimensionKind.storage,
                ),
              ],
            ),
        ];
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          productFactsAdapter: QualifiedTestProductFacts(
            family.map((p) => p.id).toSet(),
          ),
          commerceAdapter: _MediaCommerce(
            family.first,
            otherProducts: family.skip(1).toList(),
          ),
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        await session.restoreCommerce();
        expect(session.addProduct(family.first.id), isTrue);
        expect(session.openProduct(family.last.id), isTrue);
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: BuyV2Screen(
              session: session,
              initialDestination: session.destination,
              initialView: session.view,
              productId: family.last.id,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final optionRow = find.byKey(const ValueKey('buy-variant-row-storage'));
        final horizontalChoices = find.descendant(
          of: optionRow,
          matching: find.byType(SingleChildScrollView),
        );
        expect(horizontalChoices, findsOneWidget);
        expect(
          tester
              .widget<SingleChildScrollView>(horizontalChoices)
              .scrollDirection,
          Axis.horizontal,
        );
        final last = find.byKey(
          ValueKey('buy-product-option-storage-${count - 1}'),
        );
        // Verify initial horizontal visibility before ensureVisible can change it.
        expect(tester.getRect(last).left, greaterThanOrEqualTo(0));
        expect(tester.getRect(last).right, lessThanOrEqualTo(320));
        expect(tester.getSize(last).width, lessThan(200));
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        expect(last.hitTestable(), findsOneWidget);
        if (count > 1) {
          final first = find.byKey(
            const ValueKey('buy-product-option-storage-0'),
          );
          await tester.ensureVisible(first);
          await tester.pumpAndSettle();
          await tester.tap(first);
          await tester.pumpAndSettle();
          expect(session.selectedProductId, family.first.id);
          expect(session.selectedProduct!.price, 10000);
        }
        expect(session.cartLines.single.product.id, family.first.id);
        expect(session.quantityFor(family.first.id), 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scale in [1.0, 2.0]) {
    for (final storeContext in [false, true]) {
      testWidgets(
        'compact grid identifies storage variants $scale store=$storeContext',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(360, 800);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final products = structuredFamily().take(2).toList();
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            productFactsAdapter: QualifiedTestProductFacts(
              products.map((p) => p.id).toSet(),
            ),
            commerceAdapter: _MediaCommerce(
              products.first,
              otherProducts: products.skip(1).toList(),
            ),
            reviewDataEnabled: false,
          );
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          await session.restoreCommerce();
          expect(session.addProduct(products.first.id), isTrue);
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: BuyV2ProgressiveProductGrid(
                    session: session,
                    products: products,
                    storageKey: 'variant-identity-grid',
                    semanticLabel: 'Products',
                    alignMediaAtTop: true,
                    storeContext: storeContext,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final storage in ['128', '256']) {
            final card = find.byKey(
              ValueKey('buy-product-phone-blue-$storage'),
            );
            final summary = find.descendant(
              of: card,
              matching: find.text('blue · $storage GB · One unit'),
            );
            expect(summary, findsOneWidget);
            await tester.ensureVisible(summary);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final box = tester.getRect(summary);
            final bounds = tester.getRect(card);
            expect(box.left, greaterThanOrEqualTo(bounds.left));
            expect(box.right, lessThanOrEqualTo(bounds.right));
          }
          final target = find.text('blue · 256 GB · One unit');
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(session.selectedProductId, products.last.id);
          expect(session.cartLines.single.product.id, products.first.id);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  group('R669 supplier media contract', () {
    final product = BuyV2Catalogue.products.first.copyWith(
      storeId: 'supplier-store',
    );

    BuyV2MediaFileMetadata photo({
      String mime = 'image/jpeg',
      int width = 1200,
      int height = 1200,
      int bytes = 1000000,
      int? frames = 1,
      bool normalized = true,
    }) => BuyV2MediaFileMetadata(
      mimeType: mime,
      width: width,
      height: height,
      byteLength: bytes,
      frameCount: frames,
      normalized: normalized,
    );

    BuyV2MediaFileMetadata video({
      String mime = 'video/mp4',
      int width = 1280,
      int height = 720,
      int bytes = 10000000,
      Duration? duration = const Duration(seconds: 60),
      double? rate = 30,
      String? codec = 'h264',
      String? profile = 'baseline',
      String? audio = 'aac-lc',
      bool normalized = true,
    }) => BuyV2MediaFileMetadata(
      mimeType: mime,
      width: width,
      height: height,
      byteLength: bytes,
      normalized: normalized,
      duration: duration,
      frameRate: rate,
      videoCodec: codec,
      videoProfile: profile,
      audioCodec: audio,
    );

    BuyV2ProductMediaAsset asset({
      String id = 'supplier-photo',
      String revision = 'revision-1',
      String? sku,
      String? canonical,
      String? store,
      String workspace = 'supplier-workspace',
      String? source,
      BuyV2MediaFileMetadata? file,
      BuyV2ProductContentMediaKind kind = BuyV2ProductContentMediaKind.network,
      bool bound = true,
      bool hasPoster = true,
      bool hasTranscript = true,
      BuyV2MediaFileMetadata? poster,
    }) {
      final isVideo = kind == BuyV2ProductContentMediaKind.networkVideo;
      return BuyV2ProductMediaAsset(
        id: id,
        label: isVideo ? 'Product demonstration' : 'Supplier pack photo',
        semanticLabel: 'Supplier media of the exact selected pack',
        kind: kind,
        source: source ?? 'https://media.example.com/$id/$revision',
        posterSource: isVideo && hasPoster
            ? 'https://media.example.com/$id/$revision/poster'
            : null,
        transcript: isVideo
            ? (hasTranscript
                  ? 'The supplier shows the pack and its label.'
                  : ' ')
            : null,
        binding: bound
            ? BuyV2ProductMediaBinding(
                supplierWorkspaceId: workspace,
                storeId: store ?? product.storeId!,
                productId: canonical ?? product.canonicalId,
                skuId: sku ?? product.id,
                assetRevision: revision,
                file: file ?? (isVideo ? video() : photo()),
                posterFile: isVideo && hasPoster ? poster ?? photo() : null,
              )
            : null,
      );
    }

    Widget mediaApp(BuyV2Product current, double scale) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(
          key: const ValueKey('r66-cart-capture'),
          child: child!,
        ),
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SKU / variant preview',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              SizedBox(
                key: const ValueKey('media-thumbnail-frame'),
                width: 96,
                height: 96,
                child: BuyV2ProductPackshot(product: current),
              ),
              const SizedBox(height: 12),
              const Text('Product image', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                key: const ValueKey('media-detail-frame'),
                width: 280,
                height: 220,
                child: BuyV2ProductPackshot(product: current),
              ),
            ],
          ),
        ),
      ),
    );

    ({_MediaHttpClient client, VoidCallback restore}) installMediaClient(
      Uint8List bytes, {
      Map<Uri, Uint8List> responses = const {},
      Map<Uri, Future<Uint8List>> delayedResponses = const {},
    }) {
      final previous = debugNetworkImageHttpClientProvider;
      final client = _MediaHttpClient(
        bytes,
        responses: responses,
        delayedResponses: delayedResponses,
      );
      imageCache.clear();
      imageCache.clearLiveImages();
      debugNetworkImageHttpClientProvider = () => client;
      void restore() {
        debugNetworkImageHttpClientProvider = previous;
        imageCache.clear();
        imageCache.clearLiveImages();
      }

      addTearDown(restore);
      return (client: client, restore: restore);
    }

    Future<void> awaitMedia(WidgetTester tester, bool Function() ready) async {
      for (var tick = 0; tick < 100 && !ready(); tick++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(
        ready(),
        isTrue,
        reason:
            'The local image response must reach its decoded or error state.',
      );
      await tester.pumpAndSettle();
    }

    for (final destination in [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
    ]) {
      testWidgets(
        'CAT03 late photo cannot replace selected variant ${destination.name}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(360, 800);
          addTearDown(tester.view.reset);
          final oldBytes = (await tester.runAsync(
            () => _mediaFitFixture(128, 256),
          ))!;
          final newBytes = (await tester.runAsync(
            () => _mediaFitFixture(256, 128),
          ))!;
          final delayed = Completer<Uint8List>();
          final base = BuyV2Catalogue.products
              .firstWhere((item) => item.destination == destination)
              .copyWith(storeId: 'supplier-store');
          final oldAsset = asset(
            id: 'late-original',
            sku: base.id,
            canonical: base.canonicalId,
            file: photo(mime: 'image/png', width: 128, height: 256),
          );
          final nextAsset = asset(
            id: 'current-variant',
            sku: 'cat03-next-sku',
            canonical: base.canonicalId,
            file: photo(mime: 'image/png', width: 256, height: 128),
          );
          final first = base.copyWith(mediaAssets: [oldAsset]);
          final second = first.copyWith(
            id: 'cat03-next-sku',
            variant: 'Second exact pack',
            mediaAssets: [nextAsset],
          );
          final media = installMediaClient(
            newBytes,
            delayedResponses: {Uri.parse(oldAsset.source!): delayed.future},
          );
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            commerceAdapter: _MediaCommerce(first, otherProducts: [second]),
            reviewDataEnabled: false,
            productFactsAdapter: QualifiedTestProductFacts({
              first.id,
              second.id,
            }),
          );
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          try {
            await session.restoreCommerce();
            await tester.pumpWidget(
              MaterialApp(
                theme: MoolTheme.light(),
                home: BuyV2Screen(session: session, onExit: () {}),
              ),
            );
            await tester.pumpAndSettle();
            expect(session.openProduct(first.id), isTrue);
            await tester.pump();
            for (
              var tick = 0;
              tick < 30 &&
                  !media.client.requested.contains(Uri.parse(oldAsset.source!));
              tick++
            ) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 20)),
              );
              await tester.pump();
            }
            expect(
              media.client.requested,
              contains(Uri.parse(oldAsset.source!)),
            );
            expect(delayed.isCompleted, isFalse);
            expect(session.openProduct(second.id), isTrue);
            await tester.pump();
            final current = find.byKey(
              const ValueKey('buy-product-gallery-network-current-variant'),
            );
            await awaitMedia(
              tester,
              () => tester
                  .widgetList<RawImage>(
                    find.descendant(
                      of: current,
                      matching: find.byType(RawImage),
                    ),
                  )
                  .any((raw) => raw.image != null),
            );
            delayed.complete(oldBytes);
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)),
            );
            await tester.pumpAndSettle();
            final image = tester
                .widget<RawImage>(
                  find.descendant(of: current, matching: find.byType(RawImage)),
                )
                .image!;
            expect(image.width, 256);
            expect(image.height, 128);
            expect(session.selectedProductId, second.id);
            expect(
              find.byKey(
                const ValueKey('buy-product-gallery-network-late-original'),
              ),
              findsNothing,
            );
            expect(session.cartLines, isEmpty);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          } finally {
            if (!delayed.isCompleted) delayed.complete(oldBytes);
            media.restore();
          }
        },
      );
    }

    testWidgets(
      'CAT03 gallery counter matches visible photo after Cart return',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final bytes = (await tester.runAsync(
          () => _mediaFitFixture(128, 256),
        ))!;
        final media = installMediaClient(bytes);
        final current = product.copyWith(
          mediaAssets: [
            asset(
              id: 'front',
              file: photo(mime: 'image/png', width: 128, height: 256),
            ),
            asset(
              id: 'back',
              file: photo(mime: 'image/png', width: 128, height: 256),
            ),
          ],
        );
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          commerceAdapter: _MediaCommerce(current),
          reviewDataEnabled: false,
          productFactsAdapter: QualifiedTestProductFacts({current.id}),
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        try {
          await session.restoreCommerce();
          session.openProduct(current.id);
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              home: BuyV2Screen(
                session: session,
                initialDestination: session.destination,
                initialView: session.view,
                productId: current.id,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          final gallery = find.byKey(
            ValueKey('buy-product-gallery-${current.id}'),
          );
          await tester.drag(gallery, const Offset(-320, 0));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(
            tester.widget<PageView>(gallery).controller!.page,
            closeTo(1, .001),
          );
          expect(find.text('2 of 2'), findsOneWidget);
          expect(session.addProduct(current.id), isTrue);
          session.openCart();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          session.goBack();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(session.selectedProductId, current.id);
          expect(find.text('1 of 2'), findsOneWidget);
          expect(
            tester.widget<PageView>(gallery).controller!.page,
            closeTo(0, .001),
          );
          expect(session.quantityFor(current.id), current.minimumOrder);
          expect(tester.takeException(), isNull);
        } finally {
          media.restore();
        }
      },
    );

    testWidgets('CAT03 same media ID revision replaces image and resets zoom', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final oldBytes = (await tester.runAsync(
        () => _mediaFitFixture(128, 256),
      ))!;
      final newBytes = (await tester.runAsync(
        () => _mediaFitFixture(256, 128),
      ))!;
      final first = asset(
        id: 'stable-photo-id',
        file: photo(mime: 'image/png', width: 128, height: 256),
      );
      final revised = asset(
        id: 'stable-photo-id',
        revision: 'revision-2',
        file: photo(mime: 'image/png', width: 256, height: 128),
      );
      final inputs = [first];
      final current = product.copyWith(mediaAssets: inputs);
      final media = installMediaClient(
        newBytes,
        responses: {
          Uri.parse(first.source!): oldBytes,
          Uri.parse(revised.source!): newBytes,
        },
      );
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        commerceAdapter: _MediaCommerce(current),
        reviewDataEnabled: false,
        productFactsAdapter: QualifiedTestProductFacts({current.id}),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      try {
        await session.restoreCommerce();
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: BuyV2Screen(session: session, onExit: () {}),
          ),
        );
        await tester.pumpAndSettle();
        expect(session.openProduct(current.id), isTrue);
        await tester.pump();
        final image = find.byKey(
          const ValueKey('buy-product-gallery-network-stable-photo-id'),
        );
        RawImage? decoded() => tester
            .widgetList<RawImage>(
              find.descendant(of: image, matching: find.byType(RawImage)),
            )
            .where((raw) => raw.image != null)
            .firstOrNull;
        await awaitMedia(tester, () => decoded()?.image?.width == 128);
        final zoom = find.descendant(
          of: find.byKey(ValueKey('buy-product-gallery-${current.id}')),
          matching: find.byType(InteractiveViewer),
        );
        tester.widget<InteractiveViewer>(zoom).transformationController!.value =
            Matrix4.diagonal3Values(2, 2, 1);
        await tester.pump();
        inputs[0] = revised;
        expect(session.refreshProductContent(current.id), isTrue);
        await tester.pump();
        await awaitMedia(tester, () => decoded()?.image?.width == 256);
        expect(decoded()!.image!.height, 128);
        expect(
          tester
              .widget<InteractiveViewer>(zoom)
              .transformationController!
              .value
              .getMaxScaleOnAxis(),
          1,
        );
        expect(media.client.requested, contains(Uri.parse(revised.source!)));
        inputs.clear();
        expect(session.refreshProductContent(current.id), isTrue);
        await tester.pumpAndSettle();
        expect(image, findsNothing);
        expect(session.selectedProductId, current.id);
        expect(session.cartLines, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        media.restore();
      }
    });

    final encodedPhotos = [
      (
        name: 'jpeg-portrait',
        mime: 'image/jpeg',
        width: 800,
        height: 1600,
        data:
            '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAIBAQEBAQIBAQECAgICAgQDAgICAgUEBAMEBgUGBgYFBgYGBwkIBgcJBwYGCAsICQoKCgoKBggLDAsKDAkKCgr/2wBDAQICAgICAgUDAwUKBwYHCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgr/wAARCAZAAyADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD4vooor+Uz/fwKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPwbooor/tMP8AVgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA//2Q==',
      ),
      (
        name: 'webp-portrait',
        mime: 'image/webp',
        width: 800,
        height: 1600,
        data:
            'UklGRhIKAABXRUJQVlA4IAYKAAAQKAGdASogA0AGPhkMhUIhBCEABABhLS3cLv/AAzv1BfgH4AaoVwD8AP0A/sHOGaBdgP0AzvsAi1Eq81tfTp06dOjpKXc3mtr6dOnTp06dOnTp06dOnTp0338hAyq+nuNRKvNbX06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTfWnxnjPGeM8Z4zxnjPGeM8Z4zxnjPGeM8Z4zxnjPGeM8Z4yQjeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3h0ynuNRKvNbX06dN9/IQMqvp7jUSrzW19OnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp03wAAP7/AsOU7mwcdyGuyuVR2cf4qC8b+AqNb3aqnNQw6gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC0/rtj78auDreEl0/wPsvOO0j/v6Bync2DjuQ12VyqOwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
      ),
      (
        name: 'jpeg-landscape',
        mime: 'image/jpeg',
        width: 1600,
        height: 800,
        data:
            '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAIBAQEBAQIBAQECAgICAgQDAgICAgUEBAMEBgUGBgYFBgYGBwkIBgcJBwYGCAsICQoKCgoKBggLDAsKDAkKCgr/2wBDAQICAgICAgUDAwUKBwYHCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgr/wAARCAMgBkADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD4vooor+Uz/fwKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD8G6KKK/7TD/VgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP/Z',
      ),
      (
        name: 'webp-landscape',
        mime: 'image/webp',
        width: 1600,
        height: 800,
        data:
            'UklGRhQKAABXRUJQVlA4IAgKAABwKAGdASpABiADPhkMhUIhBCEABABhLS3cLv/AAzv1BfgH4AaoVwD8AP0A/sHOGaBdgP0AzvsAi1Eq81tfTp06dOnTp06dOnTp06dOm+9FOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06ObJvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hu/qWmtNaa01prTWmtNaa01prTWmtNaa01prTWmtNaa01prTWmtNaa01prTWmtNaa01prTWmtNaa01prTWmtNaa01prTXHTT3GolXmtr6dOnTp06dOnTp06dOm+/kIGVX09xqJV5ra+nTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo4AAP7/AsOU7mwcdyGuyuVR2A7fxUF438BUa3u1VOahh1AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC2/rtj78auDreEl0/wPsvOOwJv/f0DlO5sHHchrsrlUdgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      ),
    ];

    for (final destination in [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
    ]) {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        for (final scale in [1.0, 2.0]) {
          for (final surface in ['catalogue', 'store', 'offers']) {
            final storeContext = surface == 'store';
            final offersContext = surface == 'offers';
            final savedContext = width == 430;
            if (savedContext &&
                (destination != BuyV2Destination.shop ||
                    scale != 1.0 ||
                    storeContext)) {
              continue;
            }
            testWidgets(
              'SKU media grid ${destination.name} $width $scale store $storeContext'
              '${savedContext ? ' saved long badge' : ''}${offersContext ? ' offers aligned' : ''}',
              (tester) async {
                tester.view.devicePixelRatio = 1;
                tester.view.physicalSize = Size(width, 844);
                addTearDown(tester.view.reset);
                final shapes = [(800, 1600), (1600, 800), (800, 800)];
                final responses = <Uri, Uint8List>{};
                final products = <BuyV2Product>[];
                final bases = BuyV2Catalogue.allProducts
                    .where((item) => item.destination == destination)
                    .take(3)
                    .toList();
                expect(bases, hasLength(3));
                for (var i = 0; i < 3; i++) {
                  final shape = shapes[i];
                  final bytes = (await tester.runAsync(
                    () => _mediaFitFixture(shape.$1, shape.$2),
                  ))!;
                  final base = bases[i];
                  final supplied = asset(
                    id: 'grid-photo-${base.id}',
                    sku: base.id,
                    canonical: base.canonicalId,
                    store: 'supplier-store',
                    file: photo(
                      mime: 'image/png',
                      width: shape.$1,
                      height: shape.$2,
                      bytes: bytes.length,
                    ),
                  );
                  responses[Uri.parse(supplied.source!)] = bytes;
                  products.add(
                    base.copyWith(
                      storeId: 'supplier-store',
                      mediaAssets: [supplied],
                      badge: savedContext
                          ? 'Verified offer with complete product and pack information '
                                'supplied by the provider store for the selected item '
                                'and its available quantity'
                          : base.badge,
                    ),
                  );
                }
                final media = installMediaClient(
                  responses.values.first,
                  responses: responses,
                );
                final core = BuySession();
                final session = BuyV2Session(
                  core: core,
                  reviewDataEnabled: false,
                  commerceAdapter: _MediaCommerce(
                    products.first,
                    otherProducts: products.skip(1).toList(),
                  ),
                );
                addTearDown(core.dispose);
                addTearDown(session.dispose);
                try {
                  await session.restoreCommerce();
                  session.destination = destination;
                  if (savedContext) {
                    for (final product in products) {
                      session.toggleSaved(product.id);
                    }
                  }
                  await tester.pumpWidget(
                    MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: MoolTheme.light(),
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: TextScaler.linear(scale)),
                        child: RepaintBoundary(
                          key: const ValueKey('r66-cart-capture'),
                          child: child!,
                        ),
                      ),
                      home: Scaffold(
                        body: SingleChildScrollView(
                          child: BuyV2ProgressiveProductGrid(
                            session: session,
                            products: products,
                            storageKey: 'sku-media-grid',
                            semanticLabel: 'Products',
                            alignMediaAtTop: true,
                            productCardBuilder: offersContext
                                ? (product) => BuyV2ProductCard(
                                    session: session,
                                    product: product,
                                    compact: true,
                                    alignMediaAtTop: true,
                                    savedContext: savedContext,
                                  )
                                : null,
                            storeContext: storeContext,
                            savedContext: savedContext,
                          ),
                        ),
                      ),
                    ),
                  );
                  await tester.pumpAndSettle();
                  for (var i = 0; i < products.length; i++) {
                    final product = products[i];
                    final frame = find.byKey(
                      ValueKey('buy-grid-packshot-${product.id}'),
                    );
                    await tester.ensureVisible(frame);
                    await tester.pump();
                    final decoded = find.descendant(
                      of: frame,
                      matching: find.byType(RawImage),
                    );
                    await awaitMedia(
                      tester,
                      () => tester
                          .widgetList<RawImage>(decoded)
                          .any((raw) => raw.image != null),
                    );
                    final raw = tester
                        .widgetList<RawImage>(decoded)
                        .singleWhere((raw) => raw.image != null);
                    expect(raw.fit, BoxFit.contain);
                    // The existing thumbnail cache decodes to the frame width.
                    // Preserve that memory bound and verify the full aspect ratio.
                    expect(raw.image!.width, inInclusiveRange(1, shapes[i].$1));
                    expect(
                      raw.image!.height,
                      closeTo(
                        raw.image!.width * shapes[i].$2 / shapes[i].$1,
                        1,
                      ),
                    );
                    expect(tester.getSize(frame).width, greaterThan(0));
                    expect(
                      tester.getSize(frame).height,
                      greaterThanOrEqualTo(70),
                    );
                    final photoBounds = tester.getRect(frame);
                    expect(
                      photoBounds.height,
                      closeTo(photoBounds.width, 1),
                      reason: 'Every SKU grid needs a square media frame',
                    );
                    expect(photoBounds.height, greaterThan(70));
                    expect(
                      photoBounds.overlaps(
                        tester.getRect(
                          find.byKey(ValueKey('buy-save-${product.id}')),
                        ),
                      ),
                      isFalse,
                      reason: 'Save must not obscure the supplier photo',
                    );
                    final badge = find.byKey(
                      ValueKey('buy-product-card-badge-${product.id}'),
                    );
                    if (badge.evaluate().isNotEmpty) {
                      if (savedContext) {
                        final badgeBounds = tester.getRect(badge);
                        final removeBounds = tester.getRect(
                          find.byKey(ValueKey('buy-save-${product.id}')),
                        );
                        expect(
                          badgeBounds.top,
                          greaterThanOrEqualTo(removeBounds.bottom),
                          reason:
                              'A thin footer may share a boundary without overlapping Save',
                        );
                        expect(
                          badgeBounds.width,
                          greaterThanOrEqualTo(photoBounds.width),
                          reason: 'Long provider facts must use the card width',
                        );
                      }
                      expect(
                        photoBounds.overlaps(tester.getRect(badge)),
                        isFalse,
                        reason: 'The product badge must not obscure the photo',
                      );
                    }
                    expect(
                      find.descendant(
                        of: frame,
                        matching: find.text('Illustration'),
                      ),
                      findsNothing,
                    );
                    expect(
                      find.descendant(
                        of: frame,
                        matching: find.text('Photo unavailable'),
                      ),
                      findsNothing,
                    );
                    expect(
                      media.client.requested,
                      contains(Uri.parse(product.mediaAssets.single.source!)),
                    );
                    expect(tester.takeException(), isNull);
                  }
                  final frames = [
                    for (final product in products)
                      tester.getRect(
                        find.byKey(ValueKey('buy-grid-packshot-${product.id}')),
                      ),
                  ];
                  if (scale == 1) {
                    final columns =
                        destination == BuyV2Destination.wholesale &&
                            width == 320
                        ? 1
                        : 2;
                    if (columns == 2) {
                      expect(
                        frames[1].left,
                        greaterThanOrEqualTo(frames[0].right),
                      );
                    } else {
                      expect(frames[1].top, greaterThan(frames[0].bottom));
                    }
                    final cards = [
                      for (final product in products)
                        tester.getRect(
                          find.byKey(
                            ValueKey('buy-product-compare-${product.id}'),
                          ),
                        ),
                    ];
                    if (columns == 2) {
                      expect(cards[1].top, closeTo(cards[0].top, .1));
                      expect(cards[2].left, closeTo(cards[0].left, .1));
                      expect(cards[2].top, closeTo(cards[0].bottom + 10, .1));
                    } else {
                      for (var i = 1; i < cards.length; i++) {
                        expect(cards[i].left, closeTo(cards[0].left, .1));
                        expect(
                          cards[i].top,
                          closeTo(cards[i - 1].bottom + 10, .1),
                        );
                      }
                    }
                    for (var i = 0; i < cards.length; i++) {
                      expect(frames[i].top, greaterThanOrEqualTo(cards[i].top));
                      expect(
                        frames[i].bottom,
                        lessThanOrEqualTo(cards[i].bottom),
                      );
                    }
                  }
                  await tester.ensureVisible(
                    find.byKey(
                      ValueKey('buy-grid-packshot-${products.first.id}'),
                    ),
                  );
                  await tester.pumpAndSettle();
                  if (width == 320 || savedContext) {
                    await capturePack(
                      tester,
                      'sku-media-grid-${destination.name}-$scale-store-$storeContext'
                      '${savedContext ? '-saved-long-badge' : ''}',
                    );
                  }
                  expect(session.itemCount, 0);
                  await tester.pumpWidget(const SizedBox.shrink());
                } finally {
                  media.restore();
                }
              },
            );
          }
        }
      }
    }

    for (final encoded in encodedPhotos) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('decoded ${encoded.name} supplier photo fits at $scale', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 568);
          addTearDown(tester.view.reset);
          final bytes = base64Decode(encoded.data);
          final decodedSize = await tester.runAsync(() async {
            final codec = await ui.instantiateImageCodec(bytes);
            try {
              final frame = await codec.getNextFrame();
              final size = Size(
                frame.image.width.toDouble(),
                frame.image.height.toDouble(),
              );
              frame.image.dispose();
              return size;
            } finally {
              codec.dispose();
            }
          });
          expect(
            decodedSize,
            Size(encoded.width.toDouble(), encoded.height.toDouble()),
          );
          final media = installMediaClient(bytes);
          try {
            final supplied = asset(
              id: 'encoded-${encoded.name}',
              file: photo(
                mime: encoded.mime,
                width: encoded.width,
                height: encoded.height,
                bytes: bytes.length,
              ),
            );
            await tester.pumpWidget(
              mediaApp(product.copyWith(mediaAssets: [supplied]), scale),
            );
            await awaitMedia(
              tester,
              () =>
                  tester
                      .widgetList<RawImage>(find.byType(RawImage))
                      .where((raw) => raw.image != null)
                      .length ==
                  2,
            );
            for (final raw in tester.widgetList<RawImage>(
              find.byType(RawImage),
            )) {
              expect(raw.fit, BoxFit.contain);
              expect(
                raw.image!.height,
                closeTo(raw.image!.width * encoded.height / encoded.width, 1),
              );
            }
            expect(
              tester.getSize(
                find.byKey(const ValueKey('media-thumbnail-frame')),
              ),
              const Size(96, 96),
            );
            expect(
              tester.getSize(find.byKey(const ValueKey('media-detail-frame'))),
              const Size(280, 220),
            );
            expect(find.text('Photo unavailable'), findsNothing);
            expect(
              media.client.requested,
              contains(Uri.parse(supplied.source!)),
            );
            expect(tester.takeException(), isNull);
            await capturePack(tester, 'r669-encoded-${encoded.name}-$scale');
            await tester.pumpWidget(const SizedBox.shrink());
          } finally {
            media.restore();
          }
        });
      }
    }

    for (final scale in [1.0, 2.0]) {
      for (final shape in [(800, 800), (800, 1600), (1600, 800), (2048, 128)]) {
        testWidgets(
          'decoded supplier photo fits ${shape.$1}x${shape.$2} at $scale',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(320, 568);
            addTearDown(tester.view.reset);
            final bytes = (await tester.runAsync(
              () => _mediaFitFixture(shape.$1, shape.$2),
            ))!;
            final media = installMediaClient(bytes);
            final client = media.client;
            try {
              final supplied = asset(
                file: photo(
                  mime: 'image/png',
                  width: shape.$1,
                  height: shape.$2,
                  bytes: bytes.length,
                ),
              );
              final current = product.copyWith(mediaAssets: [supplied]);
              await tester.pumpWidget(mediaApp(current, scale));
              await awaitMedia(
                tester,
                () =>
                    tester
                        .widgetList<RawImage>(find.byType(RawImage))
                        .where((image) => image.image != null)
                        .length ==
                    2,
              );
              for (final raw in tester.widgetList<RawImage>(
                find.byType(RawImage),
              )) {
                expect(raw.fit, BoxFit.contain);
                expect(
                  raw.image!.height,
                  closeTo(raw.image!.width * shape.$2 / shape.$1, 1),
                );
              }
              expect(
                tester.getSize(
                  find.byKey(const ValueKey('media-thumbnail-frame')),
                ),
                const Size(96, 96),
              );
              expect(
                tester.getSize(
                  find.byKey(const ValueKey('media-detail-frame')),
                ),
                const Size(280, 220),
              );
              expect(client.requested, isNotEmpty);
              expect(tester.takeException(), isNull);
              if (shape.$1 == shape.$2) {
                await expectThumbnailCornersVisible(tester);
              }
              await capturePack(
                tester,
                'r669-supplier-media-${shape.$1}x${shape.$2}-$scale',
              );
              final requests = client.requested.length;
              await tester.pumpWidget(
                mediaApp(current.copyWith(id: 'other-variant'), scale),
              );
              await tester.pumpAndSettle();
              expect(
                find.byKey(
                  ValueKey(
                    'buy-supplier-photo-${product.id}-${supplied.id}-${supplied.binding!.assetRevision}',
                  ),
                ),
                findsNothing,
              );
              expect(client.requested.length, requests);
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            } finally {
              media.restore();
            }
          },
        );
      }

      testWidgets(
        'corrupt supplier photo preserves frames and honest fallback $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 568);
          addTearDown(tester.view.reset);
          final media = installMediaClient(Uint8List.fromList([0, 1, 2, 3]));
          try {
            final current = product.copyWith(
              mediaAssets: [asset(file: photo(mime: 'image/png'))],
            );
            await tester.pumpWidget(mediaApp(current, scale));
            final unavailable = find.byKey(
              ValueKey('buy-product-photo-unavailable-${product.id}'),
            );
            await awaitMedia(tester, () => unavailable.evaluate().length == 2);
            expect(
              tester.getSize(
                find.byKey(const ValueKey('media-thumbnail-frame')),
              ),
              const Size(96, 96),
            );
            expect(
              tester.getSize(find.byKey(const ValueKey('media-detail-frame'))),
              const Size(280, 220),
            );
            expect(find.text('Photo unavailable'), findsWidgets);
            expect(tester.takeException(), isNull);
            await capturePack(tester, 'r669-supplier-media-corrupt-$scale');
            await tester.pumpWidget(const SizedBox.shrink());
          } finally {
            media.restore();
          }
        },
      );

      testWidgets(
        'supplier photos follow product variant zoom Cart and Back $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 568);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final portrait = (await tester.runAsync(
            () => _mediaFitFixture(800, 1600),
          ))!;
          final landscape = (await tester.runAsync(
            () => _mediaFitFixture(1600, 800),
          ))!;
          final responses = <Uri, Uint8List>{};
          final suppliedProducts = <BuyV2Product>[];
          final fixtureCore = BuySession();
          final fixtureSession = BuyV2Session(core: fixtureCore);
          addTearDown(fixtureCore.dispose);
          addTearDown(fixtureSession.dispose);
          for (final pair in [
            ('s-milk', portrait, 800, 1600),
            ('s-milk-500ml', landscape, 1600, 800),
          ]) {
            final base = fixtureSession.product(pair.$1);
            final supplied = asset(
              id: 'photo-${base.id}',
              sku: base.id,
              canonical: base.canonicalId,
              store: 'supplier-store',
              file: photo(
                mime: 'image/png',
                bytes: pair.$2.length,
                width: pair.$3,
                height: pair.$4,
              ),
            );
            responses[Uri.parse(supplied.source!)] = pair.$2;
            suppliedProducts.add(
              base.copyWith(storeId: 'supplier-store', mediaAssets: [supplied]),
            );
          }
          final media = installMediaClient(portrait, responses: responses);
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            productFactsAdapter: QualifiedTestProductFacts(
              suppliedProducts.map((p) => p.id).toSet(),
            ),
            commerceAdapter: _MediaCommerce(
              suppliedProducts.first,
              otherProducts: [suppliedProducts.last],
            ),
            reviewDataEnabled: false,
          );
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          try {
            await session.restoreCommerce();
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: MoolTheme.light(),
                builder: (context, child) => r66VisualCaptureRoot(child!),
                home: BuyV2Screen(session: session, onExit: () {}),
              ),
            );
            await tester.pumpAndSettle();
            expect(session.openProduct('s-milk'), isTrue);
            await tester.pump();
            Future<void> verifyGallery(String id, int width, int height) async {
              final gallery = find.byKey(ValueKey('buy-product-gallery-$id'));
              final badge = find.byKey(
                ValueKey('buy-product-gallery-badge-$id'),
              );
              expect(
                badge,
                findsNothing,
                reason: 'Reference gallery removes the old promotional badge.',
              );
              await tester.ensureVisible(gallery);
              await tester.pump();
              final image = find.byKey(
                ValueKey('buy-product-gallery-network-photo-$id'),
              );
              await awaitMedia(
                tester,
                () => tester
                    .widgetList<RawImage>(
                      find.descendant(
                        of: image,
                        matching: find.byType(RawImage),
                      ),
                    )
                    .any((raw) => raw.image != null),
              );
              final raw = tester.widget<RawImage>(
                find.descendant(of: image, matching: find.byType(RawImage)),
              );
              expect(raw.fit, BoxFit.contain);
              expect(raw.image!.width, width);
              expect(raw.image!.height, height);
              expect(tester.getSize(gallery).height, greaterThan(0));
              // Save/Share live above the photo. Scrolling a short viewport to
              // the gallery can evict that row from the lazy product list.
              final productScroll = find
                  .descendant(
                    of: find.byKey(PageStorageKey('buy-product-$id')),
                    matching: find.byType(Scrollable),
                  )
                  .first;
              await tester.scrollUntilVisible(
                find.byKey(ValueKey('buy-product-action-save-$id')),
                -120,
                scrollable: productScroll,
              );
              await tester.pump();
              expect(
                find.byKey(ValueKey('buy-product-action-save-$id')),
                findsOneWidget,
              );
              expect(
                find.byKey(ValueKey('buy-product-action-share-$id')),
                findsOneWidget,
              );
              expect(
                media.client.requested,
                contains(
                  Uri.parse(
                    session.selectedProduct!.mediaAssets.single.source!,
                  ),
                ),
              );
              expect(tester.takeException(), isNull);
              await tester.ensureVisible(gallery);
              await tester.pump();
              await capturePack(tester, 'r669-supplier-product-$id-$scale');
            }

            await verifyGallery('s-milk', 800, 1600);
            final zoom = find.byKey(
              const ValueKey('buy-product-media-zoom-s-milk'),
            );
            final center = tester.getCenter(zoom);
            final first = await tester.startGesture(
              center - const Offset(20, 0),
              pointer: 1,
            );
            final second = await tester.startGesture(
              center + const Offset(20, 0),
              pointer: 2,
            );
            await tester.pump();
            for (final distance in [30.0, 45.0, 60.0]) {
              await first.moveTo(center - Offset(distance, 0));
              await second.moveTo(center + Offset(distance, 0));
              await tester.pump(const Duration(milliseconds: 16));
            }
            await first.up();
            await second.up();
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<InteractiveViewer>(zoom)
                  .transformationController!
                  .value
                  .getMaxScaleOnAxis(),
              greaterThan(1),
            );
            await tester.tap(
              find.byKey(const ValueKey('buy-product-media-reset-s-milk')),
            );
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<InteractiveViewer>(zoom)
                  .transformationController!
                  .value
                  .getMaxScaleOnAxis(),
              closeTo(1, .001),
            );
            final variant = find.byKey(
              const ValueKey('buy-product-variant-s-milk-500ml'),
            );
            await tester.scrollUntilVisible(
              variant,
              180,
              scrollable: find
                  .descendant(
                    of: find.byKey(const PageStorageKey('buy-product-s-milk')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.ensureVisible(variant);
            await tester.pumpAndSettle();
            await tester.tap(variant);
            await tester.pump();
            expect(session.selectedProductId, 's-milk-500ml');
            await verifyGallery('s-milk-500ml', 1600, 800);
            expect(
              find.byKey(
                const ValueKey('buy-product-gallery-network-photo-s-milk'),
              ),
              findsNothing,
            );
            final add = find.byKey(
              const ValueKey('buy-product-primary-s-milk-500ml'),
            );
            await tester.scrollUntilVisible(
              add,
              180,
              scrollable: find
                  .descendant(
                    of: find.byKey(
                      const PageStorageKey('buy-product-s-milk-500ml'),
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.ensureVisible(add);
            await tester.pumpAndSettle();
            await tester.tap(add);
            await tester.pumpAndSettle();
            expect(session.quantityFor('s-milk-500ml'), 1);
            expect(session.quantityFor('s-milk'), 0);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.catalogue);
            expect(session.quantityFor('s-milk-500ml'), 1);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          } finally {
            media.restore();
          }
        },
      );

      testWidgets('product discloses rejected supplier media at $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final current = product.copyWith(
          mediaAssets: [asset(sku: 'different-pack')],
        );
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          commerceAdapter: _MediaCommerce(current),
          reviewDataEnabled: false,
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await session.restoreCommerce();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => r66VisualCaptureRoot(child!),
            home: BuyV2Screen(session: session, onExit: () {}),
          ),
        );
        await tester.pumpAndSettle();
        expect(session.openProduct(current.id), isTrue);
        await tester.pumpAndSettle();
        final notice = find.byKey(
          ValueKey('buy-product-media-notice-${current.id}'),
        );
        await tester.scrollUntilVisible(
          notice,
          120,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-${current.id}')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(notice.hitTestable(), findsOneWidget);
        expect(
          find.textContaining('could not be displayed for this pack'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await capturePack(
          tester,
          'r669-supplier-media-rejected-product-$scale',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    for (final mime in ['image/jpeg', 'image/png', 'image/webp']) {
      for (final shape in [(1200, 1200), (800, 1600), (1600, 800)]) {
        test('accepts declared static $mime ${shape.$1}x${shape.$2}', () {
          final file = photo(mime: mime, width: shape.$1, height: shape.$2);
          expect(
            BuyV2SupplierMediaPolicy.inputMessage(video: false, file: file),
            isNull,
          );
          expect(
            BuyV2SupplierMediaPolicy.publicationMessage(
              product,
              asset(file: file),
            ),
            isNull,
          );
        });
      }
    }

    final invalidPhotos = <String, BuyV2MediaFileMetadata>{
      'HEIC': photo(mime: 'image/heic'),
      'SVG': photo(mime: 'image/svg+xml'),
      'animated WebP': photo(mime: 'image/webp', frames: 2),
      'unknown frame count': photo(frames: null),
      'missing bytes': photo(bytes: 0),
      'too many bytes': photo(
        bytes: BuyV2SupplierMediaPolicy.maximumImageBytes + 1,
      ),
      'zero width': photo(width: 0),
      'negative height': photo(height: -1),
    };
    for (final entry in invalidPhotos.entries) {
      test('rejects ${entry.key} input and publication', () {
        expect(
          BuyV2SupplierMediaPolicy.inputMessage(
            video: false,
            file: entry.value,
          ),
          isNotNull,
        );
        expect(
          BuyV2SupplierMediaPolicy.publicationMessage(
            product,
            asset(file: entry.value),
          ),
          isNotNull,
        );
      });
    }
    for (final entry in <String, BuyV2MediaFileMetadata>{
      'low resolution': photo(width: 511),
      'oversize side': photo(width: 8193, height: 512),
      'excess decoded pixels': photo(width: 6000, height: 5000),
    }.entries) {
      test('rejects ${entry.key} supplier input', () {
        expect(
          BuyV2SupplierMediaPolicy.inputMessage(
            video: false,
            file: entry.value,
          ),
          isNotNull,
        );
      });
    }
    test('raw input requires a normalized bounded display derivative', () {
      final input = photo(width: 6000, height: 4000, normalized: false);
      expect(
        BuyV2SupplierMediaPolicy.inputMessage(video: false, file: input),
        isNull,
      );
      expect(
        BuyV2SupplierMediaPolicy.publicationMessage(
          product,
          asset(file: input),
        ),
        isNotNull,
      );
      expect(
        BuyV2SupplierMediaPolicy.publicationMessage(
          product,
          asset(file: photo(width: 2049)),
        ),
        isNotNull,
      );
      expect(
        BuyV2SupplierMediaPolicy.publicationMessage(
          product,
          asset(file: photo(width: 2048, height: 2048)),
        ),
        isNotNull,
      );
    });

    for (final shape in [(1280, 720), (720, 1280)]) {
      test('accepts complete MP4 video ${shape.$1}x${shape.$2}', () {
        final file = video(width: shape.$1, height: shape.$2, audio: null);
        expect(
          BuyV2SupplierMediaPolicy.inputMessage(video: true, file: file),
          isNull,
        );
        expect(
          BuyV2SupplierMediaPolicy.publicationMessage(
            product,
            asset(kind: BuyV2ProductContentMediaKind.networkVideo, file: file),
          ),
          isNull,
        );
      });
    }
    for (final entry in <String, BuyV2MediaFileMetadata>{
      'MOV': video(mime: 'video/quicktime'),
      'wrong codec': video(codec: 'hevc'),
      'unknown profile': video(profile: null),
      'wrong audio': video(audio: 'opus'),
      'long video': video(duration: const Duration(seconds: 61)),
      'missing duration': video(duration: null),
      'missing fps': video(rate: null),
      'invalid fps': video(rate: double.nan),
      'high fps': video(rate: 60),
      'large frame': video(width: 1920, height: 1080),
      'too many video bytes': video(
        bytes: BuyV2SupplierMediaPolicy.maximumVideoBytes + 1,
      ),
    }.entries) {
      test('rejects ${entry.key}', () {
        expect(
          BuyV2SupplierMediaPolicy.inputMessage(video: true, file: entry.value),
          isNotNull,
        );
        expect(
          BuyV2SupplierMediaPolicy.publicationMessage(
            product,
            asset(
              kind: BuyV2ProductContentMediaKind.networkVideo,
              file: entry.value,
            ),
          ),
          isNotNull,
        );
      });
    }
    test(
      'video requires matched normalized poster and readable transcript',
      () {
        for (final candidate in [
          asset(
            kind: BuyV2ProductContentMediaKind.networkVideo,
            hasPoster: false,
          ),
          asset(
            kind: BuyV2ProductContentMediaKind.networkVideo,
            hasTranscript: false,
          ),
          asset(
            kind: BuyV2ProductContentMediaKind.networkVideo,
            poster: photo(normalized: false),
          ),
        ]) {
          expect(
            BuyV2SupplierMediaPolicy.publicationMessage(product, candidate),
            isNotNull,
          );
        }
      },
    );

    test(
      'wrong pack supplier source or missing metadata never becomes a supplier photo',
      () {
        for (final candidate in [
          asset(sku: 'another-variant'),
          asset(canonical: 'another-product'),
          asset(store: 'another-store'),
          asset(workspace: ''),
          asset(revision: ''),
          asset(bound: false),
          asset(source: 'http://media.example.com/photo'),
          asset(source: 'https://user:password@media.example.com/photo'),
          asset(kind: BuyV2ProductContentMediaKind.asset),
        ]) {
          expect(
            BuyV2SupplierMediaPolicy.publicationMessage(product, candidate),
            isNotNull,
          );
          final snapshot = const BuyV2CatalogueProductContentAdapter()
              .snapshotFor(product.copyWith(mediaAssets: [candidate]));
          expect(
            snapshot.media.single.kind,
            BuyV2ProductContentMediaKind.cataloguePackshot,
          );
          expect(snapshot.customerMessage, contains('could not be displayed'));
        }
      },
    );
    test(
      'product copy preserves media but another variant cannot inherit its association',
      () {
        final supplied = asset();
        final current = product.copyWith(mediaAssets: [supplied]);
        expect(
          current.copyWith(price: current.price + 1).mediaAssets.single,
          same(supplied),
        );
        final changedVariant = current.copyWith(id: 'another-variant');
        expect(
          const BuyV2CatalogueProductContentAdapter()
              .snapshotFor(changedVariant)
              .media
              .single
              .kind,
          BuyV2ProductContentMediaKind.cataloguePackshot,
        );
      },
    );
    test(
      'gallery takes valid exact-pack media with unique IDs and a bounded list',
      () {
        final valid = asset();
        final snapshot = const BuyV2CatalogueProductContentAdapter()
            .snapshotFor(
              product.copyWith(
                mediaAssets: [
                  valid,
                  valid,
                  asset(sku: 'other'),
                  for (var i = 0; i < 15; i++) asset(id: 'photo-$i'),
                ],
              ),
            );
        expect(snapshot.media.length, BuyV2SupplierMediaPolicy.maximumAssets);
        expect(snapshot.media.first, same(valid));
        expect(
          snapshot.media.map((item) => item.id).toSet().length,
          snapshot.media.length,
        );
        expect(snapshot.customerMessage, isNotNull);
      },
    );
    test('CAT03 cached media cannot cross Store or canonical identity', () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final supplied = asset();
      final current = product.copyWith(mediaAssets: [supplied]);
      expect(session.productContentFor(current).media.single, same(supplied));
      for (final changed in [
        current.copyWith(storeId: 'another-store'),
        current.copyWith(canonicalId: 'another-family'),
      ]) {
        final foreign = session.productContentFor(changed);
        expect(foreign.media.where((item) => item.binding != null), isEmpty);
        expect(session.productContentFor(current).media.single, same(supplied));
      }
    });

    test('content cache replaces withdrawn or revised exact-SKU media', () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final first = asset();
      final second = asset(revision: 'revision-2');
      final inputs = [first];
      final current = product.copyWith(mediaAssets: inputs);
      expect(session.productContentFor(current).media.single, same(first));
      inputs[0] = second;
      expect(session.productContentFor(current).media.single, same(second));
      expect(
        session
            .productContentFor(current.copyWith(mediaAssets: const []))
            .media
            .single
            .kind,
        BuyV2ProductContentMediaKind.cataloguePackshot,
      );
    });
  });

  for (final offers in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R5 singular trade pack from offers $offers at $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(scale == 2 ? 320 : 390, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        session.addProduct('s-milk');
        final otherQuantity = session.quantityFor('s-milk');
        final otherTotal = session.totalForDestination(BuyV2Destination.shop);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 24, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
                disableAnimations: true,
              ),
              child: r66VisualCaptureRoot(child!),
            ),
            home: BuyV2Screen(session: session),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            ValueKey(
              offers ? 'buy-local-tab-offers' : 'buy-local-tab-wholesale',
            ),
          ),
        );
        await tester.pumpAndSettle();
        final sourceId = offers ? 'w-oil' : 'w-rice';
        final selectedId = offers ? 'w-oil-10l' : 'w-rice-50kg';
        if (!offers) {
          await tester.tap(find.byKey(const ValueKey('buy-search-control')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('buy-search-field')),
            'rice',
          );
          await tester.pumpAndSettle();
        }
        final source = session.product(sourceId);
        final sourceCard = find.byKey(ValueKey('buy-product-$sourceId'));
        if (offers) {
          await tester.scrollUntilVisible(
            sourceCard,
            180,
            scrollable: find
                .descendant(
                  of: find.byKey(const PageStorageKey('buy-offers')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
        }
        await Scrollable.ensureVisible(
          tester.element(sourceCard),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        expect(sourceCard.hitTestable(), findsOneWidget);
        await tester.tap(sourceCard);
        await tester.pumpAndSettle();
        final selector = find.byKey(
          ValueKey('buy-product-variants-${source.canonicalId}'),
        );
        await tester.scrollUntilVisible(
          selector,
          160,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$sourceId')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        final variant = find.byKey(ValueKey('buy-product-variant-$selectedId'));
        await tester.ensureVisible(variant);
        await tester.pumpAndSettle();
        await tester.tap(variant);
        await tester.pumpAndSettle();
        final selected = session.selectedProduct!;
        expect(selected.id, selectedId);
        expect(selected.minimumOrder, 1);
        expect(selected.price, offers ? 1580 : 3200);
        expect(selected.seller, source.seller);
        expect(session.quantityFor(sourceId), 0);
        final label = find.text(
          'Minimum 1 pack · ${buyV2Money(selected.price)}',
        );
        await tester.scrollUntilVisible(
          label,
          160,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$selectedId')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(label, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
          isFalse,
        );
        final addLabel = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.label ?? '').startsWith(
                'Add minimum order of 1 pack of ',
              ),
        );
        expect(addLabel, findsOneWidget);
        expect(find.textContaining(RegExp(r'\b1 packs\b')), findsNothing);
        await capturePack(tester, 'r5-pack-$offers-$scale-minimum');
        final trade = label;
        await tester.scrollUntilVisible(
          trade,
          160,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$selectedId')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        final priceSummary = find.byKey(
          ValueKey('buy-product-purchase-hero-$selectedId'),
        );
        expect(
          find.descendant(
            of: priceSummary,
            matching: find.text('${selected.pack} · ${selected.unitPrice}'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: priceSummary, matching: trade),
          findsOneWidget,
        );
        final tradeSemantics = find.byKey(
          ValueKey('buy-wholesale-trade-decision-$selectedId'),
        );
        await tester.scrollUntilVisible(
          tradeSemantics,
          160,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$selectedId')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<Semantics>(tradeSemantics).properties.label,
          contains('Minimum order 1 pack.'),
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-trade');
        final add = find.byKey(ValueKey('buy-product-primary-$selectedId'));
        await tester.scrollUntilVisible(
          add,
          -160,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$selectedId')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(add.hitTestable(), findsOneWidget);
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(session.quantityFor(selectedId), 1);
        expect(
          session.totalForDestination(BuyV2Destination.wholesale),
          selected.price,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == 'Edit quantity, 1 pack in Cart',
          ),
          findsOneWidget,
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-one-in-cart');
        final stepper = find.byKey(
          ValueKey('buy-product-quantity-$selectedId'),
        );
        await tester.tap(
          find.descendant(of: stepper, matching: find.byTooltip('Add one')),
        );
        await tester.pumpAndSettle();
        expect(session.quantityFor(selectedId), 2);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == 'Edit quantity, 2 packs in Cart',
          ),
          findsOneWidget,
        );
        expect(
          session.totalForDestination(BuyV2Destination.wholesale),
          selected.price * 2,
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-two-in-cart');
        await tester.tap(
          find.byKey(const ValueKey('buy-cart-navigation-button')),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        final cartFacts = find.byKey(
          ValueKey('buy-wholesale-cart-line-facts-$selectedId'),
        );
        final cartScroll = find
            .descendant(
              of: find.byKey(
                PageStorageKey('buy-cart-${session.cartScope.name}'),
              ),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          cartFacts,
          180,
          scrollable: cartScroll,
          maxScrolls: 30,
        );
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label ?? '').contains(
                  'Minimum order 1 packs.',
                ),
          ),
          findsNothing,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label ?? '').contains(
                  'Minimum order 1 pack.',
                ),
          ),
          findsWidgets,
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-cart');
        await Scrollable.ensureVisible(
          tester.element(cartFacts),
          alignment: .45,
        );
        await tester.pumpAndSettle();
        final cartPackLabel = find.descendant(
          of: cartFacts,
          matching: find.textContaining('Minimum order 1 pack'),
        );
        expect(cartPackLabel.hitTestable(), findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(cartPackLabel).didExceedMaxLines,
          isFalse,
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-cart-moq');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.selectedProductId, selectedId);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.catalogue);
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
        expect(session.quantityFor('s-milk'), otherQuantity);
        expect(session.totalForDestination(BuyV2Destination.shop), otherTotal);
        expect(session.quantityFor(selectedId), 2);
        await capturePack(tester, 'r5-pack-$offers-$scale-return');
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final scale in [1.0, 1.4, 2.0]) {
    testWidgets(
      'product options preserve exact pack Cart and Back state at $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 700);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        expect(session.openProduct('s-milk'), isTrue);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (_, child) => r66VisualCaptureRoot(child!),
            home: BuyV2Screen(
              session: session,
              initialDestination: session.destination,
              initialView: session.view,
              productId: session.selectedProductId,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final selector = find.byKey(
          const ValueKey('buy-product-variants-milk'),
        );
        await tester.scrollUntilVisible(
          selector,
          180,
          scrollable: find
              .descendant(
                of: find.byKey(const PageStorageKey('buy-product-s-milk')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(selector, findsOneWidget);
        for (final id in const ['s-milk', 's-milk-500ml', 's-milk-2l']) {
          expect(
            find.byKey(ValueKey('buy-product-variant-$id')),
            findsOneWidget,
          );
        }

        final halfLitre = find.byKey(
          const ValueKey('buy-product-variant-s-milk-500ml'),
        );
        await tester.ensureVisible(halfLitre);
        await tester.pumpAndSettle();
        await tester.tap(halfLitre);
        await tester.pumpAndSettle();
        expect(session.selectedProduct?.id, 's-milk-500ml');
        expect(session.selectedProduct?.pack, '500 ml pouch');
        expect(session.selectedProduct?.price, 35);
        expect(session.selectedProduct?.unitPrice, '₹70/L');
        final packFacts = find.text('500 ml pouch · ₹70/L');
        await tester.scrollUntilVisible(
          packFacts,
          180,
          scrollable: find
              .descendant(
                of: find.byKey(
                  const PageStorageKey('buy-product-s-milk-500ml'),
                ),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(packFacts, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(packFacts).didExceedMaxLines,
          isFalse,
        );
        expect(find.text('Quick local choice'), findsNothing);
        await capturePack(tester, 'r669-milk-variant-badge-$scale');

        final add = find.byKey(
          const ValueKey('buy-product-primary-s-milk-500ml'),
        );
        await tester.scrollUntilVisible(
          add,
          180,
          scrollable: find
              .descendant(
                of: find.byKey(
                  const PageStorageKey('buy-product-s-milk-500ml'),
                ),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        final delivery = find.byKey(
          const ValueKey('buy-automatic-fulfilment-s-milk-500ml'),
        );
        final productScroll = find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-product-s-milk-500ml')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          delivery,
          120,
          scrollable: productScroll,
        );
        expect(delivery, findsOneWidget);
        expect(
          find.descendant(
            of: delivery,
            matching: find.textContaining('MoolSocial Courier Delivery'),
          ),
          findsWidgets,
        );
        expect(find.text('Quick local choice'), findsNothing);
        await tester.scrollUntilVisible(add, -120, scrollable: productScroll);
        await Scrollable.ensureVisible(tester.element(add), alignment: .4);
        await tester.pumpAndSettle();
        expect(add.hitTestable(), findsOneWidget);
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(session.quantityFor('s-milk-500ml'), 1);
        expect(session.quantityFor('s-milk'), 0);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view.name, 'catalogue');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
