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
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

final class _MediaHttpClient extends Fake implements HttpClient {
  _MediaHttpClient(this.bytes, {this.responses = const {}});
  final Uint8List bytes;
  final Map<Uri, Uint8List> responses;
  final requested = <Uri>[];
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requested.add(url);
    return _MediaHttpRequest(responses[url] ?? bytes);
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
    }) {
      final previous = debugNetworkImageHttpClientProvider;
      final client = _MediaHttpClient(bytes, responses: responses);
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
          ValueKey('buy-wholesale-price-summary-$selectedId'),
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
