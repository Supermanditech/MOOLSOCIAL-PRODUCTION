import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Shop and Wholesale product heroes expose complete purchase decisions',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      for (final productId in const ['s-atta', 'w-atta']) {
        final core = BuySession();
        final session = BuyV2Session(core: core);
        final product = session.product(productId);
        expect(session.openProduct(productId), isTrue);
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: BuyV2Screen(
              session: session,
              initialDestination: session.destination,
              initialView: session.view,
              productId: productId,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final hero = find.byKey(
          ValueKey('buy-product-purchase-hero-$productId'),
        );
        expect(hero, findsOneWidget);
        expect(
          find.descendant(of: hero, matching: find.text(product.title)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: hero,
            matching: find.textContaining(product.seller),
          ),
          findsWidgets,
        );
        expect(
          find.descendant(
            of: hero,
            matching: find.textContaining(
              product.destination == BuyV2Destination.wholesale
                  ? 'Tomorrow'
                  : '7:30',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('buy-product-hero-price-$productId')),
          findsOneWidget,
        );
        final compliance = find.byKey(
          ValueKey('buy-product-compliance-$productId'),
        );
        await tester.scrollUntilVisible(
          compliance,
          220,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$productId')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(compliance, findsOneWidget);
        expect(find.text('Buy now'), findsNothing);
        expect(tester.takeException(), isNull);

        session.dispose();
        core.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );

  testWidgets('product compliance shows supplied facts and hides no data', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final product = BuyV2Catalogue.products.first.copyWith(
      compliance: const BuyV2ProductCompliance(
        genericName: 'Refined sunflower oil',
        netQuantity: '5 L',
        manufacturerName: 'Surya Oils India',
        packerName: 'Surya Oils India',
        importerName: 'Mool Imports India',
        countryOfOrigin: 'India',
        manufacturedOrPackedOnLabel: 'Packed August 2026',
        bestBeforeOrUseByLabel: 'Best before 12 months from packing',
        fssaiLicenseNumber: '10000000000000',
        consumerCare: 'Surya Oils Consumer Care',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: BuyV2ProductCompliancePanel(product: product),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final value in const [
      'Product and pack information',
      'Generic name',
      'Net quantity',
      'Refined sunflower oil',
      '5 L',
      'Surya Oils India',
      'Mool Imports India',
      'India',
      'Packed August 2026',
      'Best before 12 months from packing',
      '10000000000000',
      'Surya Oils Consumer Care',
    ]) {
      expect(find.text(value), findsWidgets, reason: value);
    }
    expect(find.textContaining('Not provided'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing optional compliance facts stay hidden', (tester) async {
    final product = BuyV2Catalogue.products.first.copyWith(
      compliance: const BuyV2ProductCompliance(
        genericName: '  ',
        netQuantity: '',
        manufacturerName: '   ',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(body: BuyV2ProductCompliancePanel(product: product)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(product.title), findsOneWidget);
    expect(find.text(product.pack), findsOneWidget);
    expect(find.text(product.unitPrice), findsOneWidget);
    expect(find.text('Product'), findsOneWidget);
    expect(find.text('Pack'), findsOneWidget);
    for (final label in const [
      'Generic name',
      'Net quantity',
      'Manufacturer',
      'Packer',
      'Importer',
      'Country of origin',
      'Manufactured or packed',
      'Best before / use by',
      'FSSAI licence',
      'Consumer care',
    ]) {
      expect(find.text(label), findsNothing, reason: label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'published protection fields remain complete at compact large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final product = BuyV2Catalogue.products.first.copyWith(
        purchaseProtection: const BuyV2PurchaseProtection(
          summary: 'Replacement or refund available',
          remedies: ['Replacement', 'Refund', '  '],
          windowLabel: 'Within 7 days of delivery',
          conditionsLabel: 'Unused with original packaging',
          verificationLabel: 'Photo or pickup inspection',
          initiationLabel: 'Open the order and select Get help',
          approvalLabel: 'After condition review',
          pickupLabel: 'Pickup in original packaging',
          refundMethodLabel: 'Original payment method',
          refundTimelineLabel: 'After verification',
          warrantyLabel: 'One-year manufacturer warranty',
          nonReturnableReason: 'Change-of-mind return unavailable',
          policyVersion: 'POLICY-7',
          effectiveFromLabel: '1 September 2026',
        ),
      );
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        commerceAdapter: _SingleProductCommerceAdapter(product),
        reviewDataEnabled: false,
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      await session.restoreCommerce();
      expect(session.openProduct(product.id), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: product.destination,
            initialView: BuyV2View.product,
            productId: product.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final productScroll = find
          .descendant(
            of: find.byKey(PageStorageKey('buy-product-${product.id}')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Applies from'),
        220,
        scrollable: productScroll,
      );
      for (final value in const [
        'Replacement or refund available',
        'Available options',
        'Replacement · Refund',
        'Request window',
        'How to request',
        'Refund method',
        'Refund timeline',
        'Warranty',
        'Policy reference',
        'POLICY-7',
        'Applies from',
        '1 September 2026',
      ]) {
        expect(find.text(value), findsOneWidget, reason: value);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'product gallery and details use one authoritative content owner',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final core = BuySession();
      final adapter = _ContentAdapter();
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-milk'), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: session.destination,
            initialView: session.view,
            productId: session.selectedProductId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-product-gallery-count')),
        findsOneWidget,
      );
      expect(find.text('1 of 2'), findsOneWidget);
      final ready = find.byKey(
        const ValueKey('buy-product-content-ready-s-milk'),
      );
      await tester.scrollUntilVisible(
        ready,
        220,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-product-s-milk')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Highlights'), findsOneWidget);
      expect(find.text('Cold-chain quality checked'), findsOneWidget);
      expect(find.text('Specifications'), findsOneWidget);
      expect(find.text('Shelf life'), findsOneWidget);
      expect(find.text('2 days'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(
        find.text('Fresh toned milk supplied in a sealed pouch.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unavailable product details retry without changing Cart', (
    tester,
  ) async {
    final core = BuySession();
    final adapter = _ContentAdapter()..available = false;
    final session = BuyV2Session(core: core, productContentAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: session.destination,
          initialView: session.view,
          productId: session.selectedProductId,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final retry = find.byKey(
      const ValueKey('buy-product-content-retry-s-milk'),
    );
    await tester.scrollUntilVisible(
      retry,
      220,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Product details unavailable'), findsOneWidget);
    expect(
      find.text('Product information could not be loaded.'),
      findsOneWidget,
    );
    adapter.available = true;
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-product-content-ready-s-milk')),
      findsOneWidget,
    );
    expect(session.cartLines, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'authoritative product video enters the gallery and preserves Back',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        productContentAdapter: const _VideoContentAdapter(),
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-milk'), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: session.destination,
            initialView: session.view,
            productId: session.selectedProductId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-product-video-s-milk-video')),
        findsOneWidget,
      );
      expect(
        find.text('This product video is unavailable right now.'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey('buy-product-video-error-transcript-s-milk-video'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Video transcript'), findsOneWidget);
      expect(find.textContaining('sealed milk pouch'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-product-video-transcript-close')),
      );
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
      expect(session.destination, BuyV2Destination.shop);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _SingleProductCommerceAdapter implements BuyV2CommerceAdapter {
  const _SingleProductCommerceAdapter(this.product);

  final BuyV2Product product;

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: [product],
  );

  @override
  Future<BuyV2AddressRequestResult> createAddressRequest({
    String recipient = '',
  }) => throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() =>
      throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  ) => throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  }) => throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({required String orderId}) =>
      throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2MutationResult> reportProduct({
    required BuyV2Product product,
    required String reason,
  }) => throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2OrderAlertsResult> setOrderAlerts({required bool enabled}) =>
      throw UnsupportedError('Not used by this focused test.');

  @override
  Future<BuyV2MutationResult> submitProductReview({
    required BuyV2Product product,
    required int rating,
    required String comment,
  }) => throw UnsupportedError('Not used by this focused test.');
}

final class _ContentAdapter implements BuyV2ProductContentAdapter {
  bool available = true;

  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) {
    if (!available) {
      return BuyV2ProductContentSnapshot(
        productId: product.id,
        state: BuyV2ProductContentState.offline,
        sourceId: 'product-content-test',
        customerMessage: 'Product information could not be loaded.',
      );
    }
    return BuyV2ProductContentSnapshot(
      productId: product.id,
      state: BuyV2ProductContentState.ready,
      sourceId: 'product-content-test',
      media: [
        for (final id in const ['front', 'pack'])
          BuyV2ProductMediaAsset(
            id: '${product.id}-$id',
            label: id == 'front' ? 'Front of pack' : 'Pack details',
            semanticLabel:
                '${product.title}, ${id == 'front' ? 'front of pack' : 'pack details'}',
            kind: BuyV2ProductContentMediaKind.cataloguePackshot,
          ),
      ],
      highlights: const ['Cold-chain quality checked', 'Sealed pouch'],
      specifications: const [
        BuyV2ProductSpecification(label: 'Shelf life', value: '2 days'),
        BuyV2ProductSpecification(label: 'Processing', value: 'Pasteurized'),
      ],
      description: 'Fresh toned milk supplied in a sealed pouch.',
    );
  }
}

final class _VideoContentAdapter implements BuyV2ProductContentAdapter {
  const _VideoContentAdapter();

  @override
  BuyV2ProductContentSnapshot snapshotFor(
    BuyV2Product product,
  ) => BuyV2ProductContentSnapshot(
    productId: product.id,
    state: BuyV2ProductContentState.ready,
    sourceId: 'firebase-product-media-contract-test',
    media: [
      BuyV2ProductMediaAsset(
        id: '${product.id}-video',
        label: 'See the sealed pack',
        semanticLabel: '${product.title} sealed-pack product video',
        kind: BuyV2ProductContentMediaKind.networkVideo,
        source: 'pending-firebase-product-video',
        transcript:
            'The video shows the sealed milk pouch from the front and back.',
      ),
    ],
  );
}
