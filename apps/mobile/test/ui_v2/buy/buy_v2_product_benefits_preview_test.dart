import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(BuyV2Session session) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MoolTheme.light(),
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
      productId: session.selectedProductId,
    ),
  );

  BuyV2PublishedStoreCoupon publishedCoupon(DateTime observed, {int revision = 1}) => BuyV2PublishedStoreCoupon(
    realm: 'evaluation', storeId: 'host-store-one', couponId: 'host-diwali', revision: revision,
    name: 'Diwali savings from Host Store', publisherName: 'Host Store', publisherType: BuyV2OfferPublisherType.retailer,
    sourceId: 'store-coupon:evaluation:host-store-one:host-diwali:$revision', observedAt: observed,
    validFrom: observed.subtract(const Duration(hours: 1)), validUntil: observed.add(const Duration(days: 1)),
    configuredTotalUses: 20, configuredUsesPerCustomer: 1,
    terms: BuyV2AdvertisedBenefitTerms(kind: 'flat', flatAmountMinor: 1050, flatBasis: 'per_order',
      maximumSavingMinor: 1050, minimumSpendMinor: 10000));
  for (final scale in [1.0, 2.0]) {
    testWidgets('LF04 PUBLISHED COUPON real-listing Store terms render without Cart authority at $scale', (tester) async {
      tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset); addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var clock = DateTime.utc(2026, 10, 20, 1);
      final source = _PublishedCouponSource()..values = [publishedCoupon(clock)], commerce = _PublishedCouponCommerce();
      final core = BuySession(), session = BuyV2Session(core: core, reviewDataEnabled: false,
        commerceAdapter: commerce, cataloguePageSource: source, catalogueNow: () => clock);
      addTearDown(core.dispose); addTearDown(session.dispose);
      await session.restoreCommerce(); final product = commerce.product;
      expect(session.openProduct(product.id), isTrue);
      const hostCapture = Key('host-only-coupon-preview-capture');
      await tester.pumpWidget(RepaintBoundary(key: hostCapture, child: app(session))); await tester.pumpAndSettle();
      expect(session.publishedStoreCouponsFor(product), hasLength(1),
        reason: 'Normal product entry must load published terms while live benefit eligibility remains disabled.');
      expect(session.liveCartBenefitsEnabled, isFalse);
      final tile = find.byKey(ValueKey('buy-published-store-coupon-${source.values.single.identity}'));
      await tester.scrollUntilVisible(tile, 200, scrollable: find.descendant(
        of: find.byKey(PageStorageKey('buy-product-${product.id}')), matching: find.byType(Scrollable)).first);
      await tester.pumpAndSettle(); await tester.ensureVisible(find.text(source.values.single.name)); await tester.pumpAndSettle();
      await tester.tap(find.text(source.values.single.name)); await tester.pumpAndSettle();
      expect(find.text('Store-wide coupon · View terms'), findsOneWidget);
      expect(find.text('₹10.50 off'), findsOneWidget);
      expect(find.textContaining('maximum saving ₹10.50'), findsNothing);
      expect(find.text('Minimum Store purchase ₹100'), findsOneWidget);
      expect(find.textContaining('This information does not apply a discount'), findsOneWidget);
      expect(session.cartLines, isEmpty); expect(session.scopedCouponSaving, 0);
      expect(session.selectedCartBenefitsFor({BuyV2Destination.shop}), isEmpty);
      expect(session.productBenefitsFor(product), isEmpty);
      // Optional labelled host render, never phone/provider acceptance or golden replacement.
      final captureRoot = Platform.environment['MOOLSOCIAL_HOST_COUPON_CAPTURE_ROOT'];
      if (captureRoot != null) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(hostCapture));
        await tester.runAsync(() async {
          final file = File('$captureRoot/lf04-public-coupon-host-${scale == 1 ? 'normal' : '2x'}-20261020-v3.png');
          if (await file.exists()) throw StateError('Preserve the earlier host capture; choose a new evidence filename.');
          final rendered = await boundary.toImage(pixelRatio: 1);
          try {
            final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
            await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
          } finally {rendered.dispose();}
        });
      }
      clock = clock.add(const Duration(minutes: 1)); await tester.pump(const Duration(minutes: 1)); await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('buy-published-store-coupon-${source.values.single.identity}')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  test('LF04 PUBLISHED COUPON refresh failure and retired reads cannot retain old advertised terms', () async {
    final clock = DateTime.utc(2026, 10, 20, 1), source = _PublishedCouponSource(), commerce = _PublishedCouponCommerce();
    source.values = [publishedCoupon(clock)];
    final core = BuySession(), session = BuyV2Session(core: core, reviewDataEnabled: false,
      commerceAdapter: commerce, cataloguePageSource: source, catalogueNow: () => clock);
    addTearDown(core.dispose); addTearDown(session.dispose);
    await session.restoreCommerce(); final product = commerce.product;
    expect(await session.refreshPublishedStoreCoupons(product.id), isTrue);
    expect(session.publishedStoreCouponsFor(product).length, 1);
    source.fail = true; expect(await session.refreshPublishedStoreCoupons(product.id), isFalse);
    expect(session.publishedStoreCouponsFor(product), isEmpty);
    source.fail = false; source.held = Completer<List<BuyV2PublishedStoreCoupon>>();
    final pending = session.refreshPublishedStoreCoupons(product.id); await Future<void>.delayed(Duration.zero);
    source.active = false; source.held!.complete([publishedCoupon(clock)]);
    expect(await pending, isFalse); expect(session.publishedStoreCouponsFor(product), isEmpty);
    expect(session.scopedCouponSaving, 0);
  });
  test('LF04 PUBLISHED COUPON newer read wins and another real Store listing receives no coupon', () async {
    final clock = DateTime.utc(2026, 10, 20, 1), source = _PublishedCouponSource(), commerce = _PublishedCouponCommerce();
    final core = BuySession(), session = BuyV2Session(core: core, reviewDataEnabled: false,
      commerceAdapter: commerce, cataloguePageSource: source, catalogueNow: () => clock);
    addTearDown(core.dispose); addTearDown(session.dispose); await session.restoreCommerce();
    final firstResult = Completer<List<BuyV2PublishedStoreCoupon>>(); source.held = firstResult;
    final first = session.refreshPublishedStoreCoupons(commerce.product.id); await Future<void>.delayed(Duration.zero);
    source.held = null; source.values = [publishedCoupon(clock, revision: 2)];
    expect(await session.refreshPublishedStoreCoupons(commerce.product.id), isTrue);
    firstResult.complete([publishedCoupon(clock)]); expect(await first, isFalse);
    expect(session.publishedStoreCouponsFor(commerce.product).single.revision, 2);
    final other = _PublishedCouponCommerce(store: 'host-store-two').product;
    expect(other.publicListingIdentity!.matches(other), isTrue);
    expect(session.publishedStoreCouponsFor(other), isEmpty);
    expect(session.scopedCouponSaving, 0); expect(session.cartLines, isEmpty);
  });

  testWidgets('Store-wide named coupon disclosure expands without applying per-SKU savings', (tester) async {
    tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final core = BuySession();
    final adapter = _ProductBenefitsAdapter(BuyV2CartBenefitsSnapshot(
      state: BuyV2CartBenefitsLoadState.ready, evaluatedAt: DateTime.utc(2026, 8, 31, 12)));
    final session = BuyV2Session(core: core, cartBenefitsAdapter: adapter,
      commerceAdapter: _StoreCouponCommerce(), reviewDataEnabled: false,
      productFactsAdapter: const BuyV2CatalogueProductFactsAdapter(includeReviewFixtures: true));
    addTearDown(session.dispose); addTearDown(core.dispose);
    await session.restoreCommerce();
    final product = session.findProduct('s-milk')!;
    adapter.snapshot = BuyV2CartBenefitsSnapshot(state: BuyV2CartBenefitsLoadState.ready,
      evaluatedAt: DateTime.utc(2026, 8, 31, 12), benefits: [BuyV2CartBenefit(
        id: 'host-diwali', kind: BuyV2CartBenefitKind.coupon, destination: product.destination,
        title: 'Diwali savings', detail: 'Host provider terms: save on the eligible Store basket.',
        sourceId: 'host-campaign-revision', sponsor: BuyV2CartBenefitSponsor.retailer,
        sponsorName: product.seller, scope: BuyV2CartBenefitScope.store, storeId: product.storeId,
        revision: 2, savingAmountMinor: 1050, minimumSpendMinor: 3025)]);
    expect(session.openProduct('s-milk'), isTrue);
    await tester.pumpWidget(app(session)); await tester.pumpAndSettle();
    expect(session.productBenefitsFor(product).map((b) => b.id), contains('host-diwali'));
    final tile = find.byKey(const ValueKey('buy-product-store-coupon-host-diwali'));
    await tester.scrollUntilVisible(tile, 240, scrollable: find.descendant(
      of: find.byKey(const PageStorageKey('buy-product-s-milk')), matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Diwali savings')); await tester.pumpAndSettle();
    expect(find.text('Diwali savings'), findsOneWidget);
    expect(find.text('Store-wide coupon · View terms'), findsOneWidget);
    await tester.tap(find.text('Diwali savings')); await tester.pumpAndSettle();
    expect(find.text('Minimum Store purchase ₹30.25'), findsOneWidget);
    expect(find.textContaining('Applies once to this Store’s eligible basket.'), findsOneWidget);
    expect(session.cartLines, isEmpty);
    expect(session.selectedCartBenefitsFor({BuyV2Destination.shop}), isEmpty);
    expect(session.scopedCouponSaving, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product offers show live eligibility without applying a saving', (
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

    final evaluatedAt = DateTime.utc(2026, 8, 31, 12);
    final adapter = _ProductBenefitsAdapter(
      BuyV2CartBenefitsSnapshot(
        state: BuyV2CartBenefitsLoadState.ready,
        evaluatedAt: evaluatedAt,
        benefits: [
          BuyV2CartBenefit(
            id: 'fresh-price-drop',
            kind: BuyV2CartBenefitKind.coupon,
            destination: BuyV2Destination.shop,
            title: 'Fresh price drop',
            detail: 'Available on this pack today.',
            sourceId: 'family-dairy-sale',
            strategy: BuyV2CartBenefitStrategy.timedSale,
            sponsor: BuyV2CartBenefitSponsor.retailer,
            sponsorName: 'Family Dairy & Bake',
            savingAmount: 20,
            validUntil: evaluatedAt.add(const Duration(days: 1)),
          ),
          const BuyV2CartBenefit(
            id: 'upi-bank-offer',
            kind: BuyV2CartBenefitKind.paymentOffer,
            destination: BuyV2Destination.shop,
            title: 'UPI bank offer',
            detail: 'Pay with an eligible UPI account.',
            sourceId: 'bank-upi-campaign',
            strategy: BuyV2CartBenefitStrategy.financialProduct,
            sponsor: BuyV2CartBenefitSponsor.bank,
            sponsorName: 'HDFC Bank',
            eligiblePaymentMethods: {'UPI'},
          ),
          const BuyV2CartBenefit(
            id: 'other-method-offer',
            kind: BuyV2CartBenefitKind.paymentOffer,
            destination: BuyV2Destination.shop,
            title: 'Other payment method offer',
            detail: 'Available only with the listed payment method.',
            sourceId: 'other-method-campaign',
            strategy: BuyV2CartBenefitStrategy.financialProduct,
            sponsor: BuyV2CartBenefitSponsor.bank,
            sponsorName: 'Other bank',
            eligiblePaymentMethods: {'Card'},
          ),
        ],
      ),
    );
    final core = BuySession();
    final session = BuyV2Session(core: core, cartBenefitsAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final panel = find.byKey(
      const ValueKey('buy-product-benefits-ready-s-milk'),
    );
    await tester.scrollUntilVisible(
      panel,
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    expect(find.text('Additional checkout benefits'), findsOneWidget);
    expect(
      find.text(
        'Separate from the listed seller price. Eligibility is checked again at Checkout.',
      ),
      findsOneWidget,
    );
    expect(find.text('Save ₹20'), findsOneWidget);
    expect(find.textContaining('Family Dairy & Bake'), findsWidgets);
    expect(find.textContaining('HDFC Bank'), findsOneWidget);
    expect(find.textContaining('With UPI'), findsOneWidget);
    expect(find.textContaining('Other bank'), findsNothing);
    expect(find.textContaining('Until'), findsOneWidget);
    expect(session.cartLines, isEmpty);
    expect(session.selectedCartBenefitsFor({BuyV2Destination.shop}), isEmpty);

    expect(session.addProduct('s-milk'), isTrue);
    await tester.pumpAndSettle();
    expect(adapter.requests.length, greaterThanOrEqualTo(2));
    expect(adapter.requests.first.lines.single.quantity, 1);
    expect(adapter.requests.last.lines.single.product.id, 's-milk');
    expect(session.scopedCouponSaving, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product offer recovery stays on the selected product', (
    tester,
  ) async {
    final evaluatedAt = DateTime.utc(2026, 8, 31, 12);
    final adapter = _ProductBenefitsAdapter(
      BuyV2CartBenefitsSnapshot(
        state: BuyV2CartBenefitsLoadState.offline,
        evaluatedAt: evaluatedAt,
        customerMessage: 'Reconnect to check current offers.',
      ),
    );
    final core = BuySession();
    final session = BuyV2Session(core: core, cartBenefitsAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final retry = find.byKey(
      const ValueKey('buy-product-benefits-retry-s-milk'),
    );
    final productScroll = find
        .descendant(
          of: find.byKey(const PageStorageKey('buy-product-s-milk')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(retry, 240, scrollable: productScroll);
    expect(find.text('Additional benefits unavailable'), findsOneWidget);
    expect(find.text('Reconnect to check current offers.'), findsOneWidget);

    adapter.snapshot = BuyV2CartBenefitsSnapshot(
      state: BuyV2CartBenefitsLoadState.ready,
      evaluatedAt: evaluatedAt,
      benefits: const [
        BuyV2CartBenefit(
          id: 'free-local-delivery',
          kind: BuyV2CartBenefitKind.coupon,
          destination: BuyV2Destination.shop,
          title: 'Free local delivery',
          detail: 'Delivery is free for this order.',
          sourceId: 'local-delivery-campaign',
          strategy: BuyV2CartBenefitStrategy.freeDelivery,
          sponsor: BuyV2CartBenefitSponsor.moolSocial,
          sponsorName: 'MoolSocial',
          freeDelivery: true,
        ),
      ],
    );
    expect(await session.refreshProductBenefits('s-milk'), isTrue);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-product-benefits-ready-s-milk')),
      findsOneWidget,
    );
    expect(find.text('Free local delivery'), findsOneWidget);
    expect(session.selectedProductId, 's-milk');
    expect(session.cartLines, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

final class _ProductBenefitsAdapter implements BuyV2LiveCartBenefitsAdapter {
  _ProductBenefitsAdapter(this.snapshot);

  BuyV2CartBenefitsSnapshot snapshot;
  final List<BuyV2CartBenefitsRequest> requests = [];

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) => const [];

  @override
  Future<BuyV2CartBenefitsSnapshot> loadEligibility(
    BuyV2CartBenefitsRequest request,
  ) async {
    requests.add(request);
    return snapshot;
  }
}

// Isolated host catalogue only: actual Store IDs must precede Store-wide scope.
final class _StoreCouponCommerce implements BuyV2CommerceAdapter {
  @override Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: [for (final product in BuyV2Catalogue.allProducts)
      product.copyWith(storeId: product.id == 's-milk' ? 'host-store-one' : 'host-store-two')]);
  @override dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError('Host read-only fixture');
}

// Explicitly isolated published-listing/advertisement fixtures; never phone data.
class _PublishedCouponSource implements BuyV2CataloguePageSource, BuyV2StoreCouponSource {
  bool active = true, fail = false;
  List<BuyV2PublishedStoreCoupon> values = [];
  Completer<List<BuyV2PublishedStoreCoupon>>? held;
  @override bool get storeCouponsActive => active;
  @override Future<List<BuyV2PublishedStoreCoupon>> loadStoreCoupons({required String storeId}) async {
    if (fail) throw StateError('Host unavailable public source');
    return held?.future ?? values;
  }
  @override dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError('No fixture catalogue page');
}
class _PublishedCouponCommerce implements BuyV2CommerceAdapter {
  _PublishedCouponCommerce({this.store = 'host-store-one'});
  final String store;
  late final identity = BuyV2PublicListingIdentity(listingId: 'listing-${(store == 'host-store-one' ? 'd' : 'e') * 64}', realm: 'evaluation',
    storeId: store, skuId: 'host-sku-one', canonicalProductId: 'host-milk-one',
    verifiedPackId: 'host-pack-one', channel: BuyV2OfferClass.retail);
  late final product = BuyV2Product(id: identity.listingId, canonicalId: identity.canonicalProductId,
    publicListingIdentity: identity, storeId: identity.storeId, offerClass: BuyV2OfferClass.retail,
    destination: BuyV2Destination.shop, categoryId: 'dairy', brand: 'Host', title: 'Host milk', variant: 'Plain',
    pack: '1 litre', priceMinor: 7050, unitPrice: '₹70.50/litre', badge: '', seller: 'Host Store',
    sellerType: 'Retailer', deliveryPromise: '', origin: '', confirmedOn: '', visualLabel: '', visualKind: 'milk');
  @override Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(state: BuyV2CommerceLoadState.ready, products: [product]);
  @override dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError('Host read-only commerce fixture');
}
