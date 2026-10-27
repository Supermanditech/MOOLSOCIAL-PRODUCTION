import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'buy_v2_qualified_provider_fixture.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_address_sheet_motion.dart';
import 'dart:io';
import 'dart:ui' show SemanticsAction, Tristate, ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/ui_v2/assistant/mool_assistant_v2.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_order_resolution_contracts.dart';
import 'package:moolsocial/features/work/scan_and_pick_contract.dart';
import 'package:moolsocial/features/work/work_order_identity_gateway.dart';
import '../../work_order_identity_gateway_test.dart' as host_stars;
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_chat_route_adapter.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_scanner.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';
import 'package:moolsocial/ui_v2/profile/global_help_support_v2.dart';
import 'package:moolsocial/ui_v2/profile/global_privacy_preferences_v2.dart';
import 'package:moolsocial/ui_v2/profile/global_security_v2.dart';

class _CartReturnOwnerStore implements BuyV2CustomerStateStore {
  @override
  String? ownerScope = 'cart-return-owner-a';

  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => null;

  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async => true;
}

class _R6634TrackingSession extends BuyV2Session {
  _R6634TrackingSession(this.fixture) : super(core: BuySession());
  final BuyV2Order fixture;
  @override
  BuyV2Order? get selectedOrderOrNull => fixture;
  @override
  List<BuyV2Order> get visibleOrders => [fixture];
  @override
  List<BuyV2Order> get orders => [fixture];
}

// Isolated presentation records; no live order/payment outcomes.
class _T14MixedHistorySession extends BuyV2Session {
  _T14MixedHistorySession() : super(core: BuySession());
  @override
  List<BuyV2Order> get orders => [
    for (final (id, status, destination) in [
      ('T14-HISTORY-A', BuyV2OrderStatus.preparing, BuyV2Destination.shop),
      ('T14-HISTORY-D', BuyV2OrderStatus.delivered, BuyV2Destination.wholesale),
      ('T14-HISTORY-M', BuyV2OrderStatus.preparing, BuyV2Destination.medicine),
    ])
      BuyV2Order(
        id: id,
        status: status,
        destination: destination,
        purchaseId: 'T14-SPLIT-PURCHASE',
        title: 'Recorded order',
        itemSummary: 'Recorded item',
        total: 100,
        partner: 'Recorded Store',
        partnerType: 'Store',
        promise: 'Estimate unavailable',
        destinationLabel: 'Recorded address',
        progress: status == BuyV2OrderStatus.delivered ? 1 : .5,
        paymentStatusLabel: 'Payment needs checking',
      ),
  ];
}

// Layout-only fixture: preserve lines, totals and delivery facts while testing
// supplier publication extremes. This does not represent an accepted live quote.
class _T14ReceiptLayoutSession extends BuyV2Session {
  _T14ReceiptLayoutSession() : super(core: BuySession());

  static const longStore =
      'Rajasthan Fresh Produce and Household Wholesale Distribution Centre';

  @override
  List<BuyV2FulfilmentGroup> get checkoutFulfilmentGroups {
    final groups = super.checkoutFulfilmentGroups;
    return [
      for (var index = 0; index < groups.length; index++)
        BuyV2FulfilmentGroup(
          groupKey: groups[index].groupKey,
          destination: groups[index].destination,
          partner: index == 0 ? longStore : '',
          partnerType: groups[index].partnerType,
          promise: groups[index].promise,
          lines: groups[index].lines,
          promisedByLabel: groups[index].promisedByLabel,
          dispatchPromise: groups[index].dispatchPromise,
          deliveryProviderName: groups[index].deliveryProviderName,
          deliveryServiceLevel: groups[index].deliveryServiceLevel,
        ),
    ];
  }
}

class _InvoiceRecoverySession extends BuyV2Session {
  _InvoiceRecoverySession({this.missingConfirmation = false})
    : super(core: BuySession()) {
    if (missingConfirmation) {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.confirmed;
    }
  }

  final bool missingConfirmation;
  int refreshCalls = 0;

  // Invoice recovery fixtures represent an accepted purchase with missing
  // invoice data, not an unsubmitted confirmation link.
  @override
  String? get confirmedPurchaseId => missingConfirmation
      ? 'invoice-recovery-purchase'
      : super.confirmedPurchaseId;

  @override
  int get confirmedProductCount =>
      missingConfirmation ? 1 : super.confirmedProductCount;

  @override
  bool get confirmedOrderReferencesMatch {
    if (!missingConfirmation) return super.confirmedOrderReferencesMatch;
    final reference = confirmedPurchaseId, saved = confirmedOrders;
    return reference != null && reference.trim().isNotEmpty && saved.isNotEmpty &&
      saved.map((order) => order.id).toSet().length == saved.length &&
      saved.every((order) => order.id.trim().isNotEmpty && order.purchaseId == reference);
  }

  @override
  List<BuyV2Order> get confirmedOrders {
    if (!missingConfirmation) return super.confirmedOrders;
    final order = orders.first;
    return [
      BuyV2Order(
        id: order.id,
        destination: order.destination,
        title: order.title,
        itemSummary: order.itemSummary,
        total: order.total,
        partner: order.partner,
        partnerType: order.partnerType,
        promise: order.promise,
        destinationLabel: order.destinationLabel,
        progress: order.progress,
        status: order.status,
        purchaseId: 'invoice-recovery-purchase',
        recipient: 'Confirmed recipient',
        addressLine: 'Confirmed order address',
      ),
    ];
  }

  @override
  Future<void> retryCommerce({bool Function()? isCurrent}) async {
    refreshCalls++;
    await super.retryCommerce(isCurrent:isCurrent);
  }
}

class _D009InvalidConfirmationSession extends _InvoiceRecoverySession {
  _D009InvalidConfirmationSession(this.failure)
    : super(missingConfirmation: true) {
    if (failure == 'unconfirmed') {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.idle;
    }
  }
  final String failure;
  @override
  String? get confirmedPurchaseId => switch (failure) {
    'missing reference' => null,
    'blank reference' => ' ',
    'mismatched purchase' => 'different-purchase',
    _ => super.confirmedPurchaseId,
  };
  @override
  List<BuyV2Order> get confirmedOrders =>
      failure == 'empty orders' ? [] : super.confirmedOrders;
  @override
  int get confirmedProductCount =>
      failure == 'no products' ? 0 : super.confirmedProductCount;
}

class _D011SupplierDetailsAdapter implements BuyV2ProductContentAdapter {
  const _D011SupplierDetailsAdapter();
  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) {
    final base = const BuyV2CatalogueProductContentAdapter().snapshotFor(
      product,
    );
    return BuyV2ProductContentSnapshot(
      productId: product.id,
      state: base.state,
      sourceId: 'd011-supplier-fixture',
      media: base.media,
      highlights: [...base.highlights, 'Graded and sorted before dispatch'],
      specifications: [
        ...base.specifications,
        const BuyV2ProductSpecification(
          label: 'Handling',
          value: 'Keep crates ventilated',
        ),
      ],
      description:
          'Supplier sorts this lot before packing. Keep away from direct heat.',
    );
  }
}

class _D012StoreFactsAdapter implements BuyV2ProductFactsAdapter {
  const _D012StoreFactsAdapter(this.mode);
  final String mode;
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final closed =
        mode == 'closed' || (mode == 'mixed' && product.id == 's-cat-food');
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          storeOperatingState: closed
              ? BuyV2StoreOperatingState.closed
              : BuyV2StoreOperatingState.open,
        );
  }
}

// Isolated source states for delivery-status presentation, not live promises.
class _ProductDeliveryCueFacts implements BuyV2ProductFactsAdapter {
  const _ProductDeliveryCueFacts(this.mode);
  final String mode;
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) =>
      const BuyV2CatalogueProductFactsAdapter().snapshotFor(product).copyWith(
        deliveryPromise: mode == 'missing' ? 'Delivery time confirmed at checkout' : 'Delivery in 12 min',
        orderabilityLabel: mode == 'checking' ? 'Checking availability' : 'Available now',
        stale: mode == 'stale',
        nextOpeningLabel: 'tomorrow at 9 AM',
        storeOperatingState: mode == 'closed'
            ? BuyV2StoreOperatingState.closed : BuyV2StoreOperatingState.open,
      );
}

class _R5ScreenArrivalSound implements BuyV2DeliveryArrivalSound {
  @override
  Future<bool> prepare() async => true;
  @override
  Future<bool> play() async => true;
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

Widget r66VisualCaptureRoot(Widget child) =>
    const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')
    ? RepaintBoundary(key: const ValueKey('r66-cart-capture'), child: child)
    : child;

Future<void> captureR66Visual(WidgetTester tester, String label) async {
  if (!const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) return;
  // Real asset decoding runs outside the widget test's fake clock. Wait for
  // the mounted assets, then settle their existing decoded-frame transitions.
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
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  await tester.runAsync(() async {
    final directory = Directory(
      const String.fromEnvironment(
        'BUY_R663_VISUAL_DIRECTORY',
        defaultValue: 'build/r66-3-local-visual-20260906',
      ),
    );
    await directory.create(recursive: true);
    final output = File('${directory.path}/$label.png');
    if (await output.exists()) {
      throw StateError('Visual capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      if (bytes == null) throw StateError('Visual capture encoding failed');
      await output.writeAsBytes(bytes.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

final _forbiddenBuyCopy = RegExp(
  r'\b(?:production|prototype|founder review|review build|sample|example|demo|'
  r'mock|placeholder|working note|internal plan|implementation|workflow|'
  r'state machine|endpoint|payload|backend|provider callback|next screen|'
  r'for (?:review|testing)|source route|product compliance|'
  r'fulfiller assigned|route owner|internal identifier|'
  r'debug build|ui review|source id|adapter|review data|not-connected|'
  r'invalid-details|connection-unavailable)\b',
  caseSensitive: false,
);

final class _FixedOffersSource implements BuyV2PublishedOffersSource {
  const _FixedOffersSource(this.publishedOffers);

  @override
  final List<BuyV2PublishedOffer> publishedOffers;
}

// Host-only mutable public-copy response, never native provider data.
class _Lf04SellerCopySession extends BuyV2Session {
  _Lf04SellerCopySession(BuySession core) : super(core: core);
  BuyV2Product? _changed;
  @override
  BuyV2Product? findProduct(String id) => id == 's-tomato' && _changed != null ? _changed : super.findProduct(id);
  void renameSeller() {
    _changed = super.findProduct('s-tomato')!.copyWith(seller: 'Host renamed seller');
    notifyListeners();
  }
}

final class _LiveOffersSource implements BuyV2LivePublishedOffersSource {
  BuyV2PublishedOffersSnapshot snapshot;
  int calls = 0;

  _LiveOffersSource(this.snapshot);

  @override
  List<BuyV2PublishedOffer> get publishedOffers => snapshot.offers;

  @override
  Future<BuyV2PublishedOffersSnapshot> load() async {
    calls += 1;
    return snapshot;
  }
}

// Host-only typed Store source; never inserted into runtime provider/storage.
class _Lf04StoreOffers implements BuyV2CataloguePageSource, BuyV2StorePublishedOffersSource {
  _Lf04StoreOffers() {
    final now = DateTime.now().toUtc();
    final identity = BuyV2PublicListingIdentity(listingId: 'listing-${'a' * 64}', realm: 'evaluation',
      storeId: 'host-store', skuId: 'host-sku', canonicalProductId: 'host-product', verifiedPackId: 'host-pack',
      channel: BuyV2OfferClass.retail);
    product = BuyV2Catalogue.products.firstWhere((p) => p.id == 's-tomato').copyWith(id: identity.listingId,
      canonicalId: 'host-product', storeId: 'host-store', publicListingIdentity: identity,
      title: 'Host Store tomato', seller: 'Host Store', offerClass: BuyV2OfferClass.retail,
      packTerms: BuyV2PackTerms(skuId: identity.listingId, revision: 'host-term', sellUnit: 'piece',
        sourceLabel: '1 piece', netContentMilli: 1000, contentUnit: 'piece', pricingStoreId: 'host-store',
        priceObservedAt: now.subtract(const Duration(minutes: 1)), priceValidUntil: now.add(const Duration(hours: 1))));
    offers = [BuyV2PublishedCatalogueOffer(publicationId: 'host-placement', revision: 1, product: product,
      publisherType: BuyV2OfferPublisherType.retailer, publisherId: 'host-store', publisherName: 'Host Store',
      headline: 'Host Store promotion', detail: 'Host published product details.', sourceId: 'host-publication',
      observedAt: now.subtract(const Duration(minutes: 1)), validUntil: now.add(const Duration(minutes: 30)))];
  }
  late BuyV2Product product;
  late List<BuyV2PublishedCatalogueOffer> offers;
  bool active = true, fail = false;
  BuyV2Product? storePreview;
  int calls = 0;
  Completer<List<BuyV2PublishedCatalogueOffer>>? pending;
  @override
  bool get storeOffersActive => active;
  @override
  Future<List<BuyV2PublishedCatalogueOffer>> loadStoreOffers({required String storeId,
    required BuyV2Destination destination}) async {
    calls++;
    if (!active || fail || storeId != 'host-store') throw const FormatException();
    return pending?.future ?? offers;
  }
  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(BuyV2CatalogueQuery query, {String? cursor,
    required int pageSize}) async => BuyV2CataloguePage(queryKey: query.key, snapshotId: 'host-products',
      items: [product], startIndex: 0, totalCount: 1);
  @override
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(BuyV2CatalogueQuery query, {String? cursor,
    required int pageSize}) async => BuyV2CataloguePage(queryKey: query.key, snapshotId: 'host-stores',
      items: [if (storePreview != null) BuyV2StoreListing(id: 'host-store', name: 'Host Store',
        area: 'Host City', address: 'Host street', regionId: 'jodhpur', previewProduct: storePreview)],
      startIndex: 0, totalCount: storePreview == null ? 0 : 1);
  @override
  Future<List<BuyV2Product>> resolveProducts(Set<String> productIds) async =>
    [if (productIds.contains(product.id)) product];
}

final class _FixedDeliveryPromiseFactsAdapter
    implements BuyV2ProductFactsAdapter {
  const _FixedDeliveryPromiseFactsAdapter(this.deliveryPromise);

  final String deliveryPromise;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          deliveryPromise: deliveryPromise,
          orderabilityLabel: 'Available to add',
          sourceId: 'b01-t02-server-assignment',
          stale: false,
        );
  }
}

final class _StoreStatusFactsAdapter implements BuyV2ProductFactsAdapter {
  const _StoreStatusFactsAdapter({required this.state, this.nextOpeningLabel});

  final BuyV2StoreOperatingState state;
  final String? nextOpeningLabel;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          storeOperatingState: product.destination == BuyV2Destination.shop
              ? state
              : BuyV2StoreOperatingState.unknown,
          nextOpeningLabel: nextOpeningLabel,
        );
  }
}

final class _T01CMutableDeliveryFactsAdapter
    implements BuyV2ProductFactsAdapter {
  final promises = <BuyV2Destination, (String, String)>{
    BuyV2Destination.shop: ('within 5 min', 'by 6:35 PM'),
    BuyV2Destination.wholesale: ('within 1 day', 'by tomorrow 4:00 PM'),
  };

  void updateShop({required String promise, required String promisedBy}) {
    promises[BuyV2Destination.shop] = (promise, promisedBy);
  }

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final quote = promises[product.destination];
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          deliveryPromise: quote?.$1 ?? product.deliveryPromise,
          promisedByLabel: quote?.$2,
          sourceId: 'b01-t01c-ui-quote',
        );
  }
}

// Isolated descriptive-location fixture, not live publication/verification.
class _Lf07LocationSession extends BuyV2Session {
  _Lf07LocationSession(this.location) : super(core: BuySession());
  final BuyV2StoreListing? location;

  @override
  BuyV2StoreListing? catalogueStore(String storeId) => location;
}

// Host-only tax presentation records; not published products or issued invoices.
class _Batch01TaxSession extends BuyV2Session {
  _Batch01TaxSession(this.fixture, DateTime now, this.staleFacts)
    : super(core: BuySession(), catalogueNow: () => now);

  final BuyV2Product fixture;
  final bool staleFacts;

  @override
  BuyV2Product? findProduct(String id) =>
      id == fixture.id ? fixture : super.findProduct(id);

  @override
  BuyV2ProductFactsSnapshot productFactsFor(BuyV2Product product) =>
      super.productFactsFor(product).copyWith(stale: staleFacts);
}

// Isolated address-request fixture; no real links, accounts or provider calls.
class _Lf08AddressSession extends BuyV2Session {
  _Lf08AddressSession(_CartReturnOwnerStore owner, this.buyerIdentity)
    : super(
        core: BuySession(),
        customerStateStore: owner,
        collectionIdentity: buyerIdentity,
      );
  final ValueNotifier<BuyV2CollectionIdentity?> buyerIdentity;
  final response = Completer<BuyV2AddressRequestResult>();
  int requests = 0;
  @override
  Future<BuyV2AddressRequestResult> createAddressRequest({
    String recipient = '',
  }) {
    requests++;
    return response.future;
  }
}



// Paste before main() in ui_v2/buy/buy_v2_screen_test.dart and register inside
// main() with _registerAiAct018RouterDepartureTest(). Existing real imports and
// _AiAct018Session suffice. No business/provider fixture or grant is introduced.
void _registerAiAct018RouterDepartureTest() {
  testWidgets('AI-ACT-018 router departure retires only original quantity route with Cart retained', (tester) async {
    final session = _AiAct018Session();
    final navigator = GlobalKey<NavigatorState>();
    late BuildContext nativeContext;
    final context = MoolAssistantContext(accountScope: 'HOST-router-owner', authenticationRevision: 1);
    session.destination = BuyV2Destination.wholesale;
    const productId = 'w-rice-50kg';
    session.fixtureProduct = session.product(productId).copyWith(pack: 'sack', unitPrice: '',
      packTerms: const BuyV2PackTerms(skuId: productId, revision: 'HOST-router-pack-v1', sellUnit: 'sack'));
    expect(session.addProduct(productId), isTrue);
    session.openCart();
    final original = session.cartLineFor(productId)!;
    final quantity = original.quantity;
    final requested = quantity + original.product.quantityStep;
    final router = GoRouter(navigatorKey: navigator, initialLocation: '/app/buy', routes: [
      GoRoute(path: '/app/buy', builder: (context, _) => Builder(builder: (context) {
        nativeContext = context;
        return const Scaffold(body: Center(child: Text('HOST original Buy route')));
      })),
      GoRoute(path: '/other', builder: (_, _) => const Scaffold(body: Center(child: Text('HOST other route')))),
    ]);
    try {
      await tester.pumpWidget(MaterialApp.router(theme: MoolTheme.light(), routerConfig: router));
      await tester.pumpAndSettle();
      final retainedBuyContext = nativeContext;
      final ownerUri = router.state.uri;
      final ownerPageKey = router.state.pageKey;
      bool currentBuyRoute() => navigator.currentState?.mounted == true &&
        ownerUri.path.startsWith('/app/buy') && router.state.uri == ownerUri && router.state.pageKey == ownerPageKey;
      BuyCartQuantityNativeAdapter adapter() => BuyCartQuantityNativeAdapter(
        context: retainedBuyContext, session: session, navigator: navigator.currentState!,
        currentContext: () => context, isRootCurrent: currentBuyRoute,
        scopeOwner: Listenable.merge([session, router.routerDelegate]));
      final receiver = adapter();
      final snapshot = (await receiver.snapshot(context, productId))!;
      final proposal = MoolAssistantProposal(id: 'HOST-router-departure', actionId: receiver.actionId,
        binding: context.binding, requestRevision: 1, entitlementRevision: 'HOST-native-contract',
        sourceRevision: snapshot.sourceRevision, entityId: productId,
        validUntil: DateTime.now().add(const Duration(minutes: 1)),
        title: 'Review quantity', summary: 'Use the original native Cart quantity form.',
        fields: {'quantity': requested});
      final review = receiver.openReview(proposal, () => true);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-quantity-input')).hitTestable(), findsOneWidget);
      expect(session.setQuantityCalls, 0);
      final departure = router.push<void>('/other');
      await tester.pumpAndSettle();
      expect(retainedBuyContext.mounted, isTrue,
        reason: 'Push retains the Buy route, so context disposal cannot mask a missing URI guard.');
      expect(session.view, BuyV2View.cart,
        reason: 'The retained Cart view alone cannot prove the active router owner.');
      expect(router.state.uri.path, '/other');
      expect(router.state.pageKey, isNot(ownerPageKey));
      expect(find.text('HOST other route'), findsOneWidget,
        reason: 'Retirement must remove only its own quantity sheet, not the new route.');
      expect(find.byKey(const ValueKey('buy-quantity-input'), skipOffstage: false), findsNothing);
      expect(await review, MoolAssistantReviewResult.stale);
      expect(await adapter().snapshot(context, productId), isNull);
      expect(session.setQuantityCalls, 0);
      expect(session.cartLineFor(productId), same(original));
      expect(session.quantityFor(productId), quantity);
      router.pop();
      await tester.pumpAndSettle();
      await departure;
      expect(find.text('HOST original Buy route'), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-quantity-input')), findsNothing);
      expect(session.setQuantityCalls, 0);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      session.dispose();
      session.core.dispose();
    }
  });
}

// External insertion draft for ui_v2/buy/buy_v2_screen_test.dart.
// All required imports already exist there. Reuses its real LF08 owner/session
// fixtures. Paste before main(), call registerShop03NativeFormTests() in main().

class _Shop03OwnerStore extends _CartReturnOwnerStore {
  int writes = 0;
  @override Future<bool> write(BuyV2CustomerStateSnapshot snapshot) {
    writes++;
    return super.write(snapshot);
  }
}

class _Shop03Session extends _Lf08AddressSession {
  _Shop03Session(_CartReturnOwnerStore owner, ValueNotifier<BuyV2CollectionIdentity?> identity)
      : super(owner, identity);
  int addressAdds = 0, addressUpdates = 0, addressChoices = 0;
  BuyV2Product? hostProduct;
  @override BuyV2Product? findProduct(String id) => hostProduct?.id == id ? hostProduct : super.findProduct(id);
  @override void addAddress(BuyV2Address address) { addressAdds++; super.addAddress(address); }
  @override bool updateAddress(BuyV2Address address) { addressUpdates++; return super.updateAddress(address); }
  @override bool chooseAddress(String id) { addressChoices++; return super.chooseAddress(id); }
}

class _Shop03NativeHarness {
  final owner = _Shop03OwnerStore();
  final identity = ValueNotifier<BuyV2CollectionIdentity?>(const BuyV2CollectionIdentity(
    accountId: 'HOST-shop03-buyer', sessionId: 'HOST-shop03-session'));
  final scope = ValueNotifier<int>(0);
  final navigator = GlobalKey<NavigatorState>();
  late final session = _Shop03Session(owner, identity);
  MoolAssistantContext context = const MoolAssistantContext(
    accountScope: (environment: 'HOST', projectId: 'HOST-project', tenantId: null,
      userId: 'HOST-user'), authenticationRevision: 1);
  static const principal = AuthenticatedAccountIdentity(firebaseProjectId: 'HOST-project',
    firebaseUserId: 'HOST-user', displayName: 'HOST own contact', phoneNumber: '+919876543210');
  int sequence = 0;

  Future<void> mount(WidgetTester tester) async {
    await session.restoreCustomerState();
    expect(session.customerStateRecoveryPending, isFalse);
    await tester.pumpWidget(MaterialApp(navigatorKey: navigator, theme: MoolTheme.light(),
      home: const Scaffold(body: Center(child: Text('HOST Buyer form review')))));
    await tester.pumpAndSettle();
  }
  BuyShopFormNativeAdapter adapter(String action) => BuyShopFormNativeAdapter(
    actionId: action, session: session, navigator: navigator.currentState!,
    currentContext: () => context, isRootCurrent: () => navigator.currentState?.mounted == true,
    scopeOwner: scope, accountIdentity: () => principal, accountAuthenticated: () => true);

  Future<Completer<MoolAssistantReviewResult>> open(String action, Map<String, Object?> fields,
    {String? entity}) async {
    final receiver = adapter(action);
    final snapshot = await receiver.snapshot(context, entity);
    expect(snapshot, isNotNull, reason: action);
    final binding = context.binding;
    final result = Completer<MoolAssistantReviewResult>();
    final proposal = MoolAssistantProposal(id: 'HOST-shop03-${++sequence}', actionId: action,
      binding: binding, requestRevision: sequence, entitlementRevision: 'HOST-paid-contract',
      sourceRevision: snapshot!.sourceRevision, entityId: entity,
      validUntil: DateTime.now().add(const Duration(minutes: 5)),
      title: 'Review original Buyer form', summary: 'Use the supplied values in the existing native form.',
      fields: fields);
    unawaited(receiver.openReview(proposal, () => context.binding == binding)
      .then(result.complete, onError: result.completeError));
    return result;
  }
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    session.dispose(); session.core.dispose(); identity.dispose(); scope.dispose();
  }
}

void registerShop03NativeFormTests() {
  String text(WidgetTester tester, String id) => tester.widget<TextField>(
    find.byKey(ValueKey('buy-address-add-$id'))).controller!.text;
  Future<void> save(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('buy-address-add-submit'));
    await tester.scrollUntilVisible(button, 180,
      scrollable: find.descendant(of: find.byKey(const ValueKey('buy-address-add-form-list')),
        matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  test('FE-SHOP-03 typed address values preserve Unicode and reject invented ownership/geo fields', () {
    final input = <String, Object?>{'recipient': 'જયા शाह', 'line': 'घर १२, Test Road',
      'area': 'જોધપુર', 'phone': '9876543210', 'pinCode': '342001', 'kind': 'thirdParty'};
    final initial = BuyV2AddressInitialData.fromFields(input);
    input['recipient'] = 'changed';
    expect(initial.inputs['recipient'], 'જયા शाह');
    expect(initial.kind, BuyV2AddressKind.thirdParty);
    expect(() => initial.inputs['line'] = 'changed', throwsUnsupportedError);
    for (final fields in <Map<String, Object?>>[
      {}, {'id': 'invented'}, {'latitude': 26.2}, {'serviceable': true},
      {'recipient': null}, {'recipient': 1}, {'recipient': ' '},
      {'phone': '+919876543210'}, {'phone': '९८७६५४३२१०'},
      {'pinCode': '३४२००१'}, {'pinCode': '12345'}, {'kind': 'Home'},
    ]) {
      expect(() => BuyV2AddressInitialData.fromFields(fields), throwsFormatException);
    }
  });

  testWidgets('FE-SHOP-03 Add populates original controls and only native Save adds once', (tester) async {
    final h = _Shop03NativeHarness();
    try {
      await h.mount(tester);
      expect(h.adapter('AI-ACT-025').validateFields({'kind': 'home'}), isNotNull);
      final before = List<BuyV2Address>.of(h.session.addresses);
      final selected = h.session.selectedAddressId, writes = h.owner.writes;
      final result = await h.open('AI-ACT-025', {
        'recipient': 'જયા शाह', 'phone': '9876543210', 'line': '12 Test Road',
        'area': 'Jodhpur', 'pinCode': '342001', 'landmark': 'Near host gate', 'kind': 'work',
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-address-add-form-route')), findsOneWidget);
      expect(text(tester, 'recipient'), 'જયા शाह'); expect(text(tester, 'phone'), '9876543210');
      expect(text(tester, 'line'), '12 Test Road'); expect(text(tester, 'area'), 'Jodhpur');
      expect(text(tester, 'pin'), '342001'); expect(text(tester, 'landmark'), 'Near host gate');
      expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('buy-address-add-kind-Work'))).selected, isTrue);
      expect(h.session.addresses, before); expect(h.session.selectedAddressId, selected);
      expect((h.session.addressAdds, h.session.addressUpdates, h.session.addressChoices), (0, 0, 0));
      expect(h.owner.writes, writes);
      await save(tester);
      expect(await result.future, MoolAssistantReviewResult.opened);
      expect((h.session.addressAdds, h.session.addressUpdates, h.session.addressChoices), (1, 0, 0));
      expect(h.session.addresses, hasLength(before.length + 1));
      final added = h.session.addresses.singleWhere((value) => !before.contains(value));
      expect(added.recipient, 'જયા शाह'); expect(added.kind, BuyV2AddressKind.work);
      expect(h.session.selectedAddressId, added.id);
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  testWidgets('FE-SHOP-03 Edit pins exact native address and preserves dirty input on another proposal', (tester) async {
    final h = _Shop03NativeHarness();
    try {
      await h.mount(tester);
      final original = h.session.addresses.singleWhere((value) => value.id == 'work');
      final result = await h.open('AI-ACT-026', {'recipient': 'Supplied edited name'}, entity: original.id);
      await tester.pumpAndSettle();
      expect(text(tester, 'recipient'), 'Supplied edited name');
      expect(text(tester, 'phone'), original.phone); expect(text(tester, 'line'), original.line);
      await tester.enterText(find.byKey(const ValueKey('buy-address-add-recipient')), 'My newer native edit');
      expect(await h.adapter('AI-ACT-026').snapshot(h.context, original.id), isNull);
      expect(text(tester, 'recipient'), 'My newer native edit');
      expect(h.session.addresses.singleWhere((value) => value.id == original.id), same(original));
      expect((h.session.addressAdds, h.session.addressUpdates, h.session.addressChoices), (0, 0, 0));
      await save(tester);
      expect(await result.future, MoolAssistantReviewResult.opened);
      final updated = h.session.addresses.singleWhere((value) => value.id == original.id);
      expect(updated.recipient, 'My newer native edit'); expect(updated.id, original.id);
      expect((h.session.addressAdds, h.session.addressUpdates, h.session.addressChoices), (0, 1, 0));
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  testWidgets('FE-SHOP-03 actor change retires prefilled address without any mutation', (tester) async {
    final h = _Shop03NativeHarness();
    try {
      await h.mount(tester);
      final before = List<BuyV2Address>.of(h.session.addresses);
      final result = await h.open('AI-ACT-025', {'recipient': 'Private host name'});
      await tester.pumpAndSettle();
      h.context = const MoolAssistantContext(accountScope:
        (environment: 'HOST', projectId: 'HOST-project', tenantId: null, userId: 'HOST-replacement'),
        authenticationRevision: 2);
      h.scope.value++;
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-address-add-recipient')), findsNothing);
      expect(find.byKey(const ValueKey('buy-address-add-submit')), findsNothing);
      expect(h.session.addresses, before);
      expect((h.session.addressAdds, h.session.addressUpdates, h.session.addressChoices), (0, 0, 0));
      await tester.tap(find.byKey(const ValueKey('buy-address-add-form-close')));
      await tester.pumpAndSettle();
      expect(await result.future, MoolAssistantReviewResult.stale);
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  testWidgets('FE-SHOP-03 exact changed address rejects an older edit proposal', (tester) async {
    final h = _Shop03NativeHarness();
    try {
      await h.mount(tester);
      final receiver = h.adapter('AI-ACT-026');
      final original = h.session.addresses.singleWhere((value) => value.id == 'work');
      final snapshot = await receiver.snapshot(h.context, original.id);
      expect(snapshot, isNotNull);
      final replacement = BuyV2Address(id: original.id, kind: original.kind, label: original.label,
        recipient: 'A newer native edit', phone: original.phone, line: original.line,
        area: original.area, pinCode: original.pinCode, landmark: original.landmark);
      expect(h.session.updateAddress(replacement), isTrue); // Simulated concurrent native user edit.
      final updates = h.session.addressUpdates;
      final proposal = MoolAssistantProposal(id: 'HOST-old-address-record', actionId: 'AI-ACT-026',
        binding: h.context.binding, requestRevision: 1, entitlementRevision: 'HOST-paid-contract',
        sourceRevision: snapshot!.sourceRevision, entityId: original.id,
        validUntil: DateTime.now().add(const Duration(minutes: 5)),
        title: 'Review address', summary: 'Keep the original native owner.', fields: {'recipient': 'Old proposal'});
      expect(await receiver.openReview(proposal, () => true), MoolAssistantReviewResult.stale);
      expect(find.byKey(const ValueKey('buy-address-add-form-route')), findsNothing);
      expect(h.session.addressUpdates, updates);
      expect(h.session.addresses.singleWhere((value) => value.id == original.id), same(replacement));
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  testWidgets('FE-SHOP-03 Buyer adapter factory does not register Workspace capabilities', (tester) async {
    final h = _Shop03NativeHarness();
    try {
      await h.mount(tester);
      List<MoolAssistantNativeAdapter> adapters() => buyShopFormNativeAdapters(
        session: h.session, navigator: h.navigator.currentState!, currentContext: () => h.context,
        isRootCurrent: () => true, scopeOwner: h.scope,
        accountIdentity: () => _Shop03NativeHarness.principal, accountAuthenticated: () => true).toList();
      expect(adapters().map((value) => value.actionId),
        unorderedEquals(['AI-ACT-025', 'AI-ACT-026', 'AI-ACT-340', 'AI-ACT-341']));
      h.context = h.context.withWorkspace(MoolAssistantWorkspace(id: 'HOST-store', name: 'HOST Store',
        profile: 'retailer-grocery', revision: 1, isStore: true, approved: true,
        approvalAccountScope: h.context.accountScope));
      expect(adapters(), isEmpty);
      expect((h.session.addressAdds, h.session.addressUpdates, h.session.addressChoices), (0, 0, 0));
    } finally { await h.dispose(tester); }
  });

  test('FE-SHOP-03 request recipient is exact Unicode text, without invented delivery facts', () {
    expect(BuyV2AddressRequestInitialData.fromFields({'recipient': '  મેઘા शाह  '}).recipient, '  મેઘા शाह  ');
    for (final fields in <Map<String, Object?>>[
      {}, {'recipient': ''}, {'recipient': ' '}, {'recipient': null},
      {'recipient': 12}, {'recipient': 'Name', 'phone': '9876543210'},
      {'recipient': 'Name', 'shareUri': 'https://example.invalid'},
    ]) {
      expect(() => BuyV2AddressRequestInitialData.fromFields(fields), throwsFormatException);
    }
  });

  testWidgets('FE-SHOP-03 request recipient reaches original form and Add it myself without sending', (tester) async {
    final h = _Shop03NativeHarness();
    try {
      await h.mount(tester);
      final before = List<BuyV2Address>.of(h.session.addresses), writes = h.owner.writes;
      final result = await h.open('AI-ACT-341', {'recipient': 'મેઘા शाह'});
      await tester.pumpAndSettle();
      final recipient = find.byKey(const ValueKey('buy-address-request-recipient'));
      expect(tester.widget<TextField>(recipient).controller!.text, 'મેઘા शाह');
      expect(h.session.requests, 0);
      expect(h.owner.writes, writes);
      expect(h.session.addresses, before);
      await tester.enterText(recipient, 'My newer recipient');
      expect(await h.adapter('AI-ACT-341').snapshot(h.context, null), isNull);
      expect(tester.widget<TextField>(recipient).controller!.text, 'My newer recipient');
      final manual = find.byKey(const ValueKey('buy-address-request-enter-manually'));
      await tester.ensureVisible(manual);
      await tester.tap(manual);
      await tester.pumpAndSettle();
      expect(text(tester, 'recipient'), 'My newer recipient');
      expect(h.session.requests, 0);
      expect((h.session.addressAdds, h.session.addressUpdates, h.session.addressChoices), (0, 0, 0));
      await tester.tap(find.byKey(const ValueKey('buy-address-add-form-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-address-request-form-close')));
      await tester.pumpAndSettle();
      expect(await result.future, MoolAssistantReviewResult.opened);
      expect(h.session.addresses, before);
      expect(h.owner.writes, writes);
      expect(h.session.requests, 0);
    } finally { await h.dispose(tester); }
  });

  testWidgets('FE-SHOP-03 request recipient hides after actor retirement without creating a request', (tester) async {
    final h = _Shop03NativeHarness();
    try {
      await h.mount(tester);
      final result = await h.open('AI-ACT-341', {'recipient': 'Private recipient'});
      await tester.pumpAndSettle();
      h.context = const MoolAssistantContext(accountScope:
        (environment: 'HOST', projectId: 'HOST-project', tenantId: null, userId: 'HOST-replacement'),
        authenticationRevision: 2);
      h.scope.value++;
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-address-request-recipient')), findsNothing);
      expect(find.byKey(const ValueKey('buy-address-request-copy')), findsNothing);
      expect(find.byKey(const ValueKey('buy-address-request-device-share')), findsNothing);
      expect(h.session.requests, 0);
      expect((h.session.addressAdds, h.session.addressUpdates, h.session.addressChoices), (0, 0, 0));
      await tester.tap(find.byKey(const ValueKey('buy-address-request-form-close')));
      await tester.pumpAndSettle();
      expect(await result.future, MoolAssistantReviewResult.stale);
    } finally { await h.dispose(tester); }
  });

  testWidgets('FE-SHOP-03 nested manual address retains request owner after principal retirement', (tester) async {
    final h = _Shop03NativeHarness();
    try {
      await h.mount(tester);
      final before = List<BuyV2Address>.of(h.session.addresses);
      final result = await h.open('AI-ACT-341', {'recipient': 'Private recipient'});
      await tester.pumpAndSettle();
      final manual = find.byKey(const ValueKey('buy-address-request-enter-manually'));
      await tester.ensureVisible(manual);
      await tester.tap(manual);
      await tester.pumpAndSettle();
      final submit = tester.widget<FilledButton>(find.byKey(const ValueKey('buy-address-add-submit'))).onPressed;
      h.context = const MoolAssistantContext(accountScope:
        (environment: 'HOST', projectId: 'HOST-project', tenantId: null, userId: 'HOST-replacement'),
        authenticationRevision: 2);
      h.scope.value++;
      submit?.call();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-address-add-recipient')), findsNothing);
      expect(find.byKey(const ValueKey('buy-address-add-submit')), findsNothing);
      expect(h.session.addresses, before);
      expect((h.session.addressAdds, h.session.addressUpdates, h.session.addressChoices), (0, 0, 0));
      await tester.tap(find.byKey(const ValueKey('buy-address-add-form-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-address-request-form-close')));
      await tester.pumpAndSettle();
      expect(await result.future, MoolAssistantReviewResult.stale);
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  testWidgets('FE-SHOP-03 Buyer finance uses actual wholesale context and leaves callback unavailable', (tester) async {
    final h = _Shop03NativeHarness();
    try {
      await h.mount(tester);
      expect(await h.adapter('AI-ACT-340').snapshot(h.context, null), isNull);
      h.session.destination = BuyV2Destination.wholesale;
      h.session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
      // Existing ACT018 host qualification pattern; finance gets a real native
      // Cart line without treating the legacy catalogue's missing pack terms
      // as a runtime grant or finance/pricing claim.
      const id = 'w-rice-50kg';
      h.session.hostProduct = h.session.product(id).copyWith(pack: 'sack', unitPrice: '',
        packTerms: const BuyV2PackTerms(skuId: id, revision: 'HOST-shop03-finance-pack', sellUnit: 'sack'));
      expect(h.session.addProduct(id), isTrue);
      h.session.view = BuyV2View.cart;
      await tester.pumpAndSettle();
      final cart = List<BuyV2CartLine>.of(h.session.cartLines), addresses = List<BuyV2Address>.of(h.session.addresses);
      final result = await h.open('AI-ACT-340', {'purposeIds': ['working-capital'],
        'contactName': 'HOST supplied contact', 'callbackNumber': '+919876543210', 'note': 'જરૂરી stock finance'});
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('business-finance-sheet')), findsOneWidget);
      for (final entry in {'name': 'HOST supplied contact', 'number': '+919876543210', 'note': 'જરૂરી stock finance'}.entries) {
        expect(tester.widget<TextFormField>(find.byKey(Key('business-finance-${entry.key}'))).controller!.text, entry.value);
      }
      expect(find.byKey(const Key('business-finance-unavailable')), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('business-finance-request'))).onPressed, isNull);
      expect(find.byKey(const Key('business-finance-confirmed')), findsNothing);
      expect(h.session.cartLines, cart); expect(h.session.addresses, addresses);
      expect((h.session.addressAdds, h.session.addressUpdates, h.session.addressChoices), (0, 0, 0));
      await tester.tap(find.byKey(const Key('business-finance-close')));
      await tester.pumpAndSettle();
      expect(await result.future, MoolAssistantReviewResult.opened);
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });
}


// Insert before main() in ui_v2/buy/buy_v2_screen_test.dart; call
// registerShop03RemainingNativeTests() inside main(). Requires the earlier
// Shop03 _Shop03OwnerStore and native adapter imports, without duplicating them.
// Isolated frontend source snapshots below never enter runtime composition.
class _Shop03ReviewTipPolicy implements BuyV2TipPolicy {
  const _Shop03ReviewTipPolicy();
  @override List<BuyV2TipOption> optionsFor(BuyV2Destination destination) =>
    destination == BuyV2Destination.wholesale ? const [BuyV2TipOption(amount: 7), BuyV2TipOption(amount: 13)] : const [];
  @override bool accepts(BuyV2Destination destination, int amount) => amount == 0 ||
    optionsFor(destination).any((value) => value.amount == amount);
}
class _Shop03ReviewSession extends BuyV2Session {
  _Shop03ReviewSession(_Shop03OwnerStore owner, ValueNotifier<BuyV2CollectionIdentity?> identity)
    : super(core: BuySession(), customerStateStore: owner, collectionIdentity: identity,
        tipPolicy: const _Shop03ReviewTipPolicy());
  BuyV2Product? hostProduct;
  final hostExtraProducts = <String, BuyV2Product>{};
  List<BuyV2CartLine>? hostAllLines, hostCheckoutLines;
  @override List<BuyV2CartLine> get allCartLines => hostAllLines ?? super.allCartLines;
  @override List<BuyV2CartLine> get checkoutLines => hostCheckoutLines ?? super.checkoutLines;
  int choices = 0, removals = 0, collections = 0, instructions = 0, tips = 0, accepts = 0;
  List<BuyV2DeliveryPromiseChange> hostPendingPromises = [];
  @override BuyV2Product? findProduct(String id) => hostProduct?.id == id ? hostProduct : hostExtraProducts[id] ?? super.findProduct(id);
  @override List<BuyV2StoreListing> get collectionCheckoutStores => cartLines.isEmpty ? const [] : [
    BuyV2StoreListing(id: cartLines.first.product.storeId!, name: 'HOST native collection Store',
      area: 'HOST area', address: 'HOST original collection address', regionId: 'HOST-region')];
  @override bool chooseAddress(String id) { choices++; return super.chooseAddress(id); }
  @override bool removeAddress(String id) { removals++; return super.removeAddress(id); }
  @override bool chooseCheckoutCollection(bool selected, {String? storeId}) {
    collections++; return super.chooseCheckoutCollection(selected, storeId: storeId);
  }
  @override bool setCustomDeliveryInstruction({required BuyV2Destination destination, required String text}) {
    instructions++; return super.setCustomDeliveryInstruction(destination: destination, text: text);
  }
  @override bool chooseTip({required String fulfilmentKey, required BuyV2Destination destination, required int amount}) {
    tips++; return super.chooseTip(fulfilmentKey: fulfilmentKey, destination: destination, amount: amount);
  }
  // Exact host presentation snapshot of a pending native promise review. Real
  // domain acceptance is already covered by buy_v2_session_test.dart LF08.
  @override bool get checkoutPromiseReviewRequired => hostPendingPromises.isNotEmpty;
  @override List<BuyV2DeliveryPromiseChange> get checkoutDeliveryPromiseChanges => List.unmodifiable(hostPendingPromises);
  @override bool acceptCheckoutPromiseChanges() {
    if (hostPendingPromises.isEmpty) return false;
    accepts++; hostPendingPromises = []; notifyListeners(); return true;
  }
  Object get effects => (choices, removals, collections, instructions, tips, accepts);
}
class _Shop03ReviewHarness {
  final owner = _Shop03OwnerStore();
  final identity = ValueNotifier<BuyV2CollectionIdentity?>(const BuyV2CollectionIdentity(
    accountId: 'HOST-shop-review', sessionId: 'HOST-shop-review-session'));
  final scope = ValueNotifier<int>(0);
  final navigator = GlobalKey<NavigatorState>();
  late final session = _Shop03ReviewSession(owner, identity);
  MoolAssistantContext context = const MoolAssistantContext(accountScope:
    (environment: 'HOST', projectId: 'HOST-project', tenantId: null, userId: 'HOST-user'), authenticationRevision: 1);
  int sequence = 0;
  Future<void> mount(WidgetTester tester) async {
    await session.restoreCustomerState();
    expect(session.customerStateRecoveryPending, isFalse);
    session.destination = BuyV2Destination.wholesale;
    const id = 'w-rice-50kg';
    // Same existing host pack qualification pattern as ACT018; never runtime.
    session.hostProduct = session.product(id).copyWith(storeId: 'HOST-native-store', pack: 'sack', unitPrice: '',
      packTerms: const BuyV2PackTerms(skuId: id, revision: 'HOST-shop-review-pack', sellUnit: 'sack'));
    expect(session.addProduct(id), isTrue);
    session.openCart();
    await tester.pumpWidget(MaterialApp(navigatorKey: navigator, theme: MoolTheme.light(),
      home: const Scaffold(body: Center(child: Text('HOST current native Buyer')))));
    await tester.pumpAndSettle();
  }
  BuyShopReviewNativeAdapter adapter(String action) => BuyShopReviewNativeAdapter(actionId: action,
    session: session, navigator: navigator.currentState!, currentContext: () => context,
    isRootCurrent: () => navigator.currentState?.mounted == true, scopeOwner: scope,
    accountIdentity: () => _Shop03NativeHarness.principal, accountAuthenticated: () => true);
  Future<({Future<MoolAssistantReviewResult> result})> open(String action, Map<String, Object?> fields,
    {String? entity, DateTime? validUntil}) async {
    final receiver = adapter(action), binding = context.binding;
    final snapshot = await receiver.snapshot(context, entity);
    expect(snapshot, isNotNull, reason: action);
    final proposal = MoolAssistantProposal(id: 'HOST-native-review-${++sequence}', actionId: action,
      binding: binding, requestRevision: sequence, entitlementRevision: 'HOST-native-contract',
      sourceRevision: snapshot!.sourceRevision, entityId: entity,
      validUntil: validUntil ?? DateTime.now().add(const Duration(minutes: 5)), title: 'Review original controls',
      summary: 'Keep the final action in its original native control.', fields: fields);
    return (result: receiver.openReview(proposal, () => context.binding == binding));
  }
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose(); session.core.dispose(); identity.dispose(); scope.dispose();
  }
}

void registerShop03RemainingNativeTests() {
  test('Shop03 remaining typed values retain Unicode and reject invented targets/options', () {
    expect(BuyShopReviewInitialData.fromFields('AI-ACT-030', {'text': '  બાજુના દરવાજે दें  '}).text, '  બાજુના દરવાજે दें  ');
    for (final input in [
      ('AI-ACT-024', <String, Object?>{'addressId': 'invented'}),
      ('AI-ACT-028', <String, Object?>{'mode': 'automatic'}),
      ('AI-ACT-030', <String, Object?>{'text': ''}),
      ('AI-ACT-030', <String, Object?>{'text': List.filled(201, 'ક').join()}),
      ('AI-ACT-031', <String, Object?>{'amount': '7'}),
      ('AI-ACT-031', <String, Object?>{'amount': -1}),
      ('AI-ACT-039', <String, Object?>{'accept': true}),
    ]) { expect(() => BuyShopReviewInitialData.fromFields(input.$1, input.$2), throwsFormatException); }
  });

  testWidgets('Shop03 exact address row selection and removal require original native actions', (tester) async {
    final h = _Shop03ReviewHarness();
    try {
      await h.mount(tester);
      final address = h.session.addresses.singleWhere((value) => value.id == 'work');
      final before = h.session.selectedAddressId, writes = h.owner.writes;
      var review = (await h.open('AI-ACT-024', {}, entity: address.id)).result;
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('buy-address-${address.id}')), findsOneWidget);
      expect(h.session.selectedAddressId, before); expect(h.session.choices, 0); expect(h.owner.writes, writes);
      await tester.tap(find.byKey(ValueKey('buy-address-${address.id}')));
      await tester.pumpAndSettle();
      expect(await review, MoolAssistantReviewResult.opened);
      expect(h.session.choices, 1); expect(h.session.selectedAddressId, address.id);
      review = (await h.open('AI-ACT-027', {}, entity: address.id)).result;
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-address-delete-confirm')), findsOneWidget);
      expect(h.session.removals, 0);
      await tester.tap(find.byKey(const ValueKey('buy-address-delete-cancel')));
      await tester.pumpAndSettle();
      expect(await review, MoolAssistantReviewResult.opened); expect(h.session.removals, 0);
      expect(h.session.addresses, contains(address));
      review = (await h.open('AI-ACT-027', {}, entity: address.id)).result;
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-address-delete-confirm')));
      await tester.pumpAndSettle();
      expect(await review, MoolAssistantReviewResult.opened);
      expect(h.session.removals, 1); expect(h.session.addresses, isNot(contains(address)));
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  testWidgets('Shop03 delivery/collection draft is local until native choice', (tester) async {
    final h = _Shop03ReviewHarness();
    try {
      await h.mount(tester); h.session.view = BuyV2View.checkout;
      final selected = h.session.collectionCheckoutSelected, writes = h.owner.writes;
      final review = (await h.open('AI-ACT-028', {'mode': 'collection'})).result;
      await tester.pumpAndSettle();
      final choice = find.byKey(const ValueKey('buy-checkout-collection-choice'));
      expect(tester.widget<ChoiceChip>(choice).selected, isTrue);
      expect(h.session.collectionCheckoutSelected, selected); expect(h.session.collections, 0); expect(h.owner.writes, writes);
      await tester.tap(choice); await tester.pumpAndSettle();
      expect(await review, MoolAssistantReviewResult.opened);
      expect(h.session.collections, 1); expect(h.session.collectionCheckoutSelected, isTrue);
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  testWidgets('Shop03 instructions use original controller/Save and protect an open dirty composer', (tester) async {
    final h = _Shop03ReviewHarness();
    try {
      await h.mount(tester);
      final saved = h.session.publicDeliveryInstruction, writes = h.owner.writes;
      final review = (await h.open('AI-ACT-030', {'text': 'બાજુના दरवाजे दें'}, entity: 'delivery')).result;
      await tester.pumpAndSettle();
      final note = find.byKey(const ValueKey('buy-cart-instruction-note-delivery'));
      expect(tester.widget<TextField>(note).controller!.text, 'બાજુના दरवाजे दें');
      expect(h.session.publicDeliveryInstruction, saved); expect(h.session.instructions, 0); expect(h.owner.writes, writes);
      await tester.enterText(note, 'My newer native instruction');
      expect(await h.adapter('AI-ACT-030').snapshot(h.context, 'delivery'), isNull);
      final save = find.byKey(const ValueKey('buy-cart-instruction-save-delivery'));
      await tester.ensureVisible(save); await tester.tap(save); await tester.pumpAndSettle();
      expect(await review, MoolAssistantReviewResult.opened);
      expect(h.session.instructions, 1); expect(h.session.publicDeliveryInstruction, 'My newer native instruction');
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  testWidgets('Shop03 tip uses current group/options and commits only native chip', (tester) async {
    final h = _Shop03ReviewHarness();
    try {
      await h.mount(tester);
      final group = h.session.scopedCartFulfilmentGroups.single;
      final before = h.session.tipForGroup(group), writes = h.owner.writes;
      final review = (await h.open('AI-ACT-031', {'amount': 13}, entity: group.key)).result;
      await tester.pumpAndSettle();
      final choice = find.byKey(ValueKey('buy-cart-tip-${group.key}-13'));
      expect(tester.widget<ChoiceChip>(choice).selected, isTrue);
      expect(h.session.tipForGroup(group), before); expect(h.session.tips, 0); expect(h.owner.writes, writes);
      await tester.tap(choice); await tester.pumpAndSettle();
      expect(await review, MoolAssistantReviewResult.opened);
      expect(h.session.tips, 1); expect(h.session.tipForGroup(group), 13);
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  testWidgets('Shop03 instruction cancellation retains local edits until explicit discard and never saves', (tester) async {
    final h = _Shop03ReviewHarness();
    try {
      await h.mount(tester);
      final saved = h.session.publicDeliveryInstruction, writes = h.owner.writes;
      final review = (await h.open('AI-ACT-030', {'text': 'HOST supplied instruction'}, entity: 'delivery')).result;
      await tester.pumpAndSettle();
      final note = find.byKey(const ValueKey('buy-cart-instruction-note-delivery'));
      await tester.enterText(note, 'My unsaved native change');
      await tester.tap(find.byType(BackButton)); await tester.pumpAndSettle();
      expect(find.text('Discard instruction changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing')); await tester.pumpAndSettle();
      expect(tester.widget<TextField>(note).controller!.text, 'My unsaved native change');
      expect(h.session.instructions, 0); expect(h.owner.writes, writes);
      await tester.tap(find.byType(BackButton)); await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes')); await tester.pumpAndSettle();
      expect(await review, MoolAssistantReviewResult.opened);
      expect(h.session.instructions, 0); expect(h.owner.writes, writes);
      expect(h.session.publicDeliveryInstruction, saved);
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  testWidgets('Shop03 promise review shows actual changes and only native Accept consumes them', (tester) async {
    final h = _Shop03ReviewHarness();
    try {
      await h.mount(tester); h.session.view = BuyV2View.checkout;
      expect(await h.adapter('AI-ACT-039').snapshot(h.context, null), isNull);
      h.session.hostPendingPromises = [(groupKey: h.session.scopedCartFulfilmentGroups.single.key,
        previousPromise: 'HOST previous promise', previousPromisedByLabel: null,
        currentPromise: 'HOST revised promise', currentPromisedByLabel: 'HOST source')];
      final review = (await h.open('AI-ACT-039', {})).result;
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-checkout-promise-change-review')), findsOneWidget);
      expect(find.textContaining('HOST previous promise'), findsOneWidget);
      expect(find.textContaining('HOST revised promise'), findsOneWidget);
      expect(h.session.accepts, 0); expect(h.session.checkoutPromiseReviewRequired, isTrue);
      await tester.tap(find.byKey(const ValueKey('buy-accept-updated-delivery-times')));
      await tester.pumpAndSettle();
      expect(await review, MoolAssistantReviewResult.opened);
      expect(h.session.accepts, 1); expect(h.session.checkoutPromiseReviewRequired, isFalse);
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  testWidgets('Shop03 actual Cart dirty instruction composer declines a new prefill', (tester) async {
    final h = _Shop03ReviewHarness();
    try {
      await h.mount(tester);
      await tester.pumpWidget(MaterialApp(navigatorKey: h.navigator, theme: MoolTheme.light(),
        home: Scaffold(body: BuyV2CartView(session: h.session, onBrowseMore: () {}))));
      await tester.pumpAndSettle();
      final open = find.byKey(const ValueKey('buy-cart-instruction-custom-delivery'));
      final scroll = find.byWidgetPredicate((widget) => widget is Scrollable &&
        widget.axisDirection == AxisDirection.down).first;
      await tester.scrollUntilVisible(open.hitTestable(), 150, maxScrolls: 40, scrollable: scroll);
      await tester.ensureVisible(open); await tester.pumpAndSettle();
      await tester.tap(open); await tester.pumpAndSettle();
      final note = find.byKey(const ValueKey('buy-cart-instruction-note-delivery'));
      await tester.enterText(note, 'My actual unfinished Cart instruction');
      final effects = h.session.effects, writes = h.owner.writes;
      expect(await h.adapter('AI-ACT-030').snapshot(h.context, 'delivery'), isNull);
      expect(tester.widget<TextField>(note).controller!.text, 'My actual unfinished Cart instruction');
      expect(h.session.effects, effects); expect(h.owner.writes, writes);
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  testWidgets('Shop03 absent native targets/options never open an empty successful review', (tester) async {
    final h = _Shop03ReviewHarness();
    try {
      await h.mount(tester);
      expect(await h.adapter('AI-ACT-024').snapshot(h.context, 'HOST-missing-address'), isNull);
      expect(await h.adapter('AI-ACT-027').snapshot(h.context, null), isNull);
      expect(await h.adapter('AI-ACT-028').snapshot(h.context, null), isNull,
        reason: 'Native checkout choices require the actual checkout surface.');
      expect(await h.adapter('AI-ACT-039').snapshot(h.context, null), isNull);
      final group = h.session.scopedCartFulfilmentGroups.single;
      final adapter = h.adapter('AI-ACT-031');
      final snapshot = (await adapter.snapshot(h.context, group.key))!;
      final proposal = MoolAssistantProposal(id: 'HOST-unsupported-tip', actionId: adapter.actionId,
        binding: h.context.binding, requestRevision: 1, entitlementRevision: 'HOST-contract',
        sourceRevision: snapshot.sourceRevision, entityId: group.key,
        validUntil: DateTime.now().add(const Duration(minutes: 5)), title: 'Review tip',
        summary: 'Current options only.', fields: {'amount': 99});
      final before = h.session.effects, writes = h.owner.writes;
      expect(await adapter.openReview(proposal, () => true), MoolAssistantReviewResult.unavailable);
      expect(find.text('Review delivery details'), findsNothing);
      expect(h.session.effects, before); expect(h.owner.writes, writes);
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });

  for (final action in ['AI-ACT-024', 'AI-ACT-027', 'AI-ACT-028', 'AI-ACT-030', 'AI-ACT-031', 'AI-ACT-039']) {
    testWidgets('Shop03 $action actor retirement removes native review without any final effect', (tester) async {
      final h = _Shop03ReviewHarness();
      try {
        await h.mount(tester);
        if (action == 'AI-ACT-028' || action == 'AI-ACT-039') h.session.view = BuyV2View.checkout;
        if (action == 'AI-ACT-039') h.session.hostPendingPromises = [(groupKey: 'HOST-promise',
          previousPromise: 'HOST old', previousPromisedByLabel: null, currentPromise: 'HOST new', currentPromisedByLabel: null)];
        final entity = switch (action) {
          'AI-ACT-024' || 'AI-ACT-027' => 'work', 'AI-ACT-030' => 'delivery',
          'AI-ACT-031' => h.session.scopedCartFulfilmentGroups.single.key, _ => null,
        };
        final fields = switch (action) {
          'AI-ACT-028' => <String, Object?>{'mode': 'collection'},
          'AI-ACT-030' => <String, Object?>{'text': 'Private native instruction'},
          'AI-ACT-031' => <String, Object?>{'amount': 7}, _ => <String, Object?>{},
        };
        final before = h.session.effects, writes = h.owner.writes;
        final review = (await h.open(action, fields, entity: entity)).result;
        await tester.pumpAndSettle();
        h.context = const MoolAssistantContext(accountScope:
          (environment: 'HOST', projectId: 'HOST-project', tenantId: null, userId: 'HOST-other-account'),
          authenticationRevision: 2);
        h.scope.value++; await tester.pumpAndSettle();
        expect(await review, MoolAssistantReviewResult.stale);
        expect(find.text('Review delivery details', skipOffstage: false), findsNothing);
        expect(find.byKey(const ValueKey('buy-address-delete-confirm'), skipOffstage: false), findsNothing);
        expect(h.session.effects, before); expect(h.owner.writes, writes);
        expect(tester.takeException(), isNull);
      } finally { await h.dispose(tester); }
    });
  }

  for (final change in ['owner', 'Cart']) {
    testWidgets('Shop03 changed native $change retires instructions without saving the staged text', (tester) async {
      final h = _Shop03ReviewHarness();
      try {
        await h.mount(tester);
        final original = h.session.publicDeliveryInstruction;
        final review = (await h.open('AI-ACT-030', {'text': 'Uncommitted native instruction'}, entity: 'delivery')).result;
        await tester.pumpAndSettle();
        if (change == 'owner') {
          h.owner.ownerScope = 'HOST-replaced-native-customer-owner'; h.scope.value++;
        } else {
          final line = h.session.cartLines.single;
          expect(h.session.setCartQuantity(line.product.id, '${line.quantity + line.product.quantityStep}'), isTrue);
        }
        await tester.pumpAndSettle();
        expect(await review, MoolAssistantReviewResult.stale);
        expect(find.byKey(const ValueKey('buy-cart-instruction-note-delivery'), skipOffstage: false), findsNothing);
        expect(h.session.instructions, 0);
        expect(h.session.publicDeliveryInstruction, original);
        expect(tester.takeException(), isNull);
      } finally { await h.dispose(tester); }
    });
  }
}

void registerShop03RemainingSafetyTests() {
  BuyV2Product excludedProduct(BuyV2Product p, {String? id,
    BuyV2Destination? destination, bool requiresPrescription = true}) => BuyV2Product(
      id: id ?? p.id, canonicalId: p.canonicalId, destination: destination ?? p.destination,
      categoryId: p.categoryId, brand: p.brand, title: p.title, variant: p.variant,
      pack: p.pack, priceMinor: p.priceMinor, unitPrice: p.unitPrice, badge: p.badge,
      seller: p.seller, sellerType: p.sellerType, deliveryPromise: p.deliveryPromise,
      origin: p.origin, confirmedOn: p.confirmedOn, visualLabel: p.visualLabel,
      visualKind: p.visualKind, storeId: p.storeId, packTerms: p.packTerms,
      publicListingIdentity: p.publicListingIdentity, minimumOrder: p.minimumOrder,
      offerClass: p.offerClass, requiresPrescription: requiresPrescription);
  const actions = ['AI-ACT-024', 'AI-ACT-027', 'AI-ACT-028', 'AI-ACT-030', 'AI-ACT-031', 'AI-ACT-039'];
  String? entity(_Shop03ReviewHarness h, String action) => switch (action) {
    'AI-ACT-024' || 'AI-ACT-027' => 'work', 'AI-ACT-030' => 'delivery',
    'AI-ACT-031' => h.session.scopedCartFulfilmentGroups.single.key, _ => null,
  };
  void pending(_Shop03ReviewHarness h) {
    h.session.view = BuyV2View.checkout;
    h.session.hostPendingPromises = [(groupKey: h.session.scopedCartFulfilmentGroups.single.key,
      previousPromise: 'HOST old', previousPromisedByLabel: null,
      currentPromise: 'HOST new', currentPromisedByLabel: null)];
  }
  for (final excluded in ['Medicine actor', 'fresh Rx']) {
    testWidgets('Shop03 remaining excludes $excluded across all native reviews', (tester) async {
      final h = _Shop03ReviewHarness();
      try {
        await h.mount(tester); pending(h);
        for (final action in actions) {
          expect(await h.adapter(action).snapshot(h.context, entity(h, action)), isNotNull, reason: action);
        }
        final before = h.session.effects, writes = h.owner.writes;
        if (excluded == 'Medicine actor') h.session.destination = BuyV2Destination.medicine;
        else h.session.hostProduct = excludedProduct(h.session.hostProduct!);
        for (final action in actions) {
          expect(await h.adapter(action).snapshot(h.context, entity(h, action)), isNull, reason: action);
        }
        expect(h.session.effects, before); expect(h.owner.writes, writes);
      } finally { await h.dispose(tester); }
    });
  }
  for (final excluded in ['Medicine', 'Rx']) {
    testWidgets('Shop03 remaining global address/instruction sees hidden retained $excluded lines', (tester) async {
      final h = _Shop03ReviewHarness();
      try {
        await h.mount(tester); pending(h);
        final retained = excludedProduct(h.session.hostProduct!, id: 'HOST-hidden-$excluded',
          destination: excluded == 'Medicine' ? BuyV2Destination.medicine : BuyV2Destination.wholesale,
          requiresPrescription: excluded == 'Rx');
        h.session.hostExtraProducts[retained.id] = retained;
        final hidden = BuyV2CartLine(product: retained, quantity: 1);
        h.session.hostAllLines = [...h.session.allCartLines, hidden];
        h.session.cartDisplayFilter = 'wholesale';
        expect(h.session.cartLines.any((line) => line.product.id == retained.id), isFalse);
        final before = h.session.effects, writes = h.owner.writes;
        for (final action in ['AI-ACT-024', 'AI-ACT-027', 'AI-ACT-030']) {
          expect(await h.adapter(action).snapshot(h.context, entity(h, action)), isNull, reason: action);
        }
        // Targeted tip remains scoped to the original eligible native group.
        expect(await h.adapter('AI-ACT-031').snapshot(h.context, entity(h, 'AI-ACT-031')), isNotNull);
        h.session.hostCheckoutLines = [...h.session.checkoutLines, hidden];
        for (final action in ['AI-ACT-028', 'AI-ACT-039']) {
          expect(await h.adapter(action).snapshot(h.context, null), isNull, reason: action);
        }
        expect(h.session.effects, before); expect(h.owner.writes, writes);
      } finally { await h.dispose(tester); }
    });
  }
  testWidgets('Shop03 real expiry removes exact address review and delete dialog while retaining another route', (tester) async {
    final h = _Shop03ReviewHarness();
    try {
      await h.mount(tester);
      final before = h.session.effects, writes = h.owner.writes;
      final result = (await h.open('AI-ACT-027', {}, entity: 'work',
        validUntil: DateTime.now().add(const Duration(seconds: 3)))).result;
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-address-delete-confirm')), findsOneWidget);
      unawaited(h.navigator.currentState!.push<void>(MaterialPageRoute<void>(builder: (_) =>
        const Scaffold(body: Text('HOST unrelated current route')))));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3200)));
      await tester.pump(const Duration(seconds: 4)); await tester.pumpAndSettle();
      expect(await result, MoolAssistantReviewResult.stale);
      expect(find.byKey(const ValueKey('buy-address-delete-confirm'), skipOffstage: false), findsNothing);
      expect(find.text('Review delivery details', skipOffstage: false), findsNothing);
      expect(find.text('HOST unrelated current route'), findsOneWidget);
      expect(h.session.effects, before); expect(h.owner.writes, writes);
      expect(tester.takeException(), isNull);
    } finally { await h.dispose(tester); }
  });
  testWidgets('Shop03 dirty original instruction card transfers session registry without losing text', (tester) async {
    final h = _Shop03ReviewHarness(), next = _Shop03ReviewHarness();
    try {
      await h.mount(tester);
      Widget cart(BuyV2Session session) => MaterialApp(navigatorKey: h.navigator, theme: MoolTheme.light(),
        home: Scaffold(body: BuyV2CartView(key: const ValueKey('HOST-same-cart-owner'), session: session, onBrowseMore: () {})));
      await tester.pumpWidget(cart(h.session)); await tester.pumpAndSettle();
      final open = find.byKey(const ValueKey('buy-cart-instruction-custom-delivery'));
      final scroll = find.byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down).first;
      await tester.scrollUntilVisible(open.hitTestable(), 150, maxScrolls: 40, scrollable: scroll);
      await tester.ensureVisible(open); await tester.pumpAndSettle();
      await tester.tap(open); await tester.pumpAndSettle();
      final note = find.byKey(const ValueKey('buy-cart-instruction-note-delivery'));
      await tester.enterText(note, 'HOST unchanged dirty local text');
      Finder card() => find.ancestor(of: note, matching: find.byWidgetPredicate((widget) =>
        widget.runtimeType.toString() == '_CartDeliveryInstructionCard'));
      final originalState = tester.state(card());
      expect(await h.adapter('AI-ACT-030').snapshot(h.context, 'delivery'), isNull);
      await next.session.restoreCustomerState();
      next.session.destination = BuyV2Destination.wholesale;
      next.session.hostProduct = h.session.hostProduct;
      expect(next.session.addProduct(next.session.hostProduct!.id), isTrue);
      next.session.openCart();
      await tester.pumpWidget(cart(next.session)); await tester.pumpAndSettle();
      expect(tester.state(card()), same(originalState));
      expect(tester.widget<TextField>(note).controller!.text, 'HOST unchanged dirty local text');
      final receiver = BuyShopReviewNativeAdapter(actionId: 'AI-ACT-030', session: next.session,
        navigator: h.navigator.currentState!, currentContext: () => next.context, isRootCurrent: () => true,
        scopeOwner: next.scope, accountIdentity: () => _Shop03NativeHarness.principal, accountAuthenticated: () => true);
      expect(await receiver.snapshot(next.context, 'delivery'), isNull);
      expect(await h.adapter('AI-ACT-030').snapshot(h.context, 'delivery'), isNotNull);
      expect(h.session.instructions, 0); expect(next.session.instructions, 0);
      expect(tester.takeException(), isNull);
    } finally {
      await h.dispose(tester); next.session.dispose(); next.session.core.dispose(); next.identity.dispose(); next.scope.dispose();
    }
  });
}

BuyV2Product _browseExcludedProduct(BuyV2Product p, {bool rx = false, BuyV2Destination? destination}) => BuyV2Product(
  id:p.id,canonicalId:p.canonicalId,destination:destination??p.destination,categoryId:p.categoryId,
  brand:p.brand,title:p.title,variant:p.variant,pack:p.pack,priceMinor:p.priceMinor,mrpMinor:p.mrpMinor,
  unitPrice:p.unitPrice,badge:p.badge,seller:p.seller,sellerType:p.sellerType,deliveryPromise:p.deliveryPromise,
  origin:p.origin,confirmedOn:p.confirmedOn,visualLabel:p.visualLabel,visualKind:p.visualKind,
  storeId:p.storeId,packTerms:p.packTerms,minimumOrder:p.minimumOrder,offerClass:p.offerClass,
  publicListingIdentity:p.publicListingIdentity,requiresPrescription:rx,
  mediaAssets:p.mediaAssets,variantAttributes:p.variantAttributes,variantFamilyId:p.variantFamilyId);
// Isolated original-source contracts, not runtime providers or listing grants.
class _BrowseSavedStore implements BuyV2SavedProductsStore {
  @override String? ownerScope = 'HOST-browse-owner';
  Set<String> keys = {};
  int writes = 0;
  @override Future<Set<String>?> read() async => Set.of(keys);
  @override Future<bool> write(Set<String> values) async { writes++; keys = Set.of(values); return true; }
}
class _BrowseAreaSource implements BuyV2ShoppingAreaSource {
  final queries = <String>[];
  int locates = 0;
  Completer<List<BuyV2ShoppingArea>>? gate;
  bool unavailable = false;
  static const candidate = BuyV2ShoppingArea(regionId: 'HOST-region', googlePlaceId: 'HOST-place',
    label: 'HOST મૂળ વિસ્તાર', countryCode: 'IN');
  @override Future<List<BuyV2ShoppingArea>> search(String query) async {
    queries.add(query); if (unavailable) throw BuyV2ShoppingAreaFailure.unavailable;
    return gate == null ? const [candidate] : gate!.future;
  }
  @override Future<BuyV2ShoppingArea?> locate() async { locates++; return candidate; }
  @override Future<BuyV2ShoppingArea?> resolve(String id) async => id == candidate.googlePlaceId ? candidate : null;
}
class _BrowseReadSource implements BuyV2CataloguePageSource {
  final products = <String, BuyV2Product>{};
  String? phone = '+919900000000';
  int storeReads = 0;
  @override Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(BuyV2CatalogueQuery query,
    {String? cursor, required int pageSize}) async => BuyV2CataloguePage(queryKey: query.key,
      snapshotId: 'HOST-browse-products', startIndex: 0, totalCount: query.query.isEmpty ? products.length : 0,
      items: query.query.isEmpty ? products.values : const []);
  @override Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(BuyV2CatalogueQuery query,
    {String? cursor, required int pageSize}) async => BuyV2CataloguePage(queryKey: query.key,
      snapshotId: 'HOST-browse-stores-${++storeReads}', startIndex: 0, totalCount: 1, items: [
        BuyV2StoreListing(id: 'HOST-native-store', name: 'HOST original Store', area: 'HOST area',
          address: 'HOST original Store address', regionId: 'HOST-region', publicContactPhone: phone)]);
  @override Future<List<BuyV2Product>> resolveProducts(Set<String> ids) async =>
    [for (final id in ids) if (products[id] case final product?) product];
}
class _BrowseFamilySource implements BuyV2VariantFamilySource {
  final products = <BuyV2Product>[];
  @override Future<BuyV2VariantFamilySnapshot> loadVariantFamily(BuyV2Product selected, BuyV2CatalogueQuery query) async {
    final now = DateTime.now();
    return BuyV2VariantFamilySnapshot(productId: selected.id, canonicalId: selected.canonicalId,
      variantFamilyId: selected.variantFamilyId, categoryId: selected.categoryId, offerClass: selected.offerClass,
      realm: selected.publicListingIdentity?.realm, storeId: selected.storeId!, destination: selected.destination,
      queryKey: query.key, sourceId: 'HOST-family-source', revision: 'HOST-family-1',
      observedAt: now.subtract(const Duration(seconds: 1)), validUntil: now.add(const Duration(hours: 1)),
      complete: true, selectedAvailable: true,
      options: products.expand((p) => p.variantAttributes), candidates: products);
  }
}
class _BrowseComparisonSource implements BuyV2ComparisonSource {
  String? productId;
  BuyV2Product? offered; BuyV2ComparisonPage? lastPage;
  final requests=<BuyV2ComparisonPageRequest>[];
  @override BuyV2ComparisonIdentity? identityFor(BuyV2Product product) => product.id==productId || product.id==offered?.id
    ? const BuyV2ComparisonIdentity(specificationId:'HOST-published-specification',packId:'HOST-published-pack',
        unit:BuyV2ComparisonUnit.kilogram,packQuantityMilli:1000) : null;
  @override Future<BuyV2ComparisonPage> load(BuyV2ComparisonPageRequest request)async{
    requests.add(request);final now=DateTime.now();
    final candidate=offered;
    final offers=<BuyV2ComparisonOffer>[
      if(candidate!=null) BuyV2ComparisonOffer(id:'HOST-offer',revision:'HOST-r1',queryKey:request.query.key,
        snapshotId:'HOST-empty-comparison',product:candidate,identity:request.query.identity,
        supplierWorkspaceId:'HOST-supplier',storeId:candidate.storeId!,channel:request.query.channel??
          (request.query.standardPurchase?BuyV2ComparisonChannel.retail:BuyV2ComparisonChannel.wholesale),
        fulfilment:request.query.fulfilment??BuyV2FulfilmentMode.bulkFreight,originLabel:'HOST source origin',
        local:true,serviceable:true,customerEligible:true,availablePacks:1000000,minimumPacks:1,incrementPacks:1,
        packPriceMinor:candidate.priceMinor,charges:const BuyV2ComparisonCharges(taxMinor:0,freightMinor:0,
          mandatoryFeesMinor:0,immediateDiscountMinor:0),observedAt:now.subtract(const Duration(seconds:1)),
        validUntil:now.add(const Duration(hours:1)))];
    return lastPage=BuyV2ComparisonPage(queryKey:request.query.key,snapshotId:'HOST-empty-comparison',
      observedAt:now.subtract(const Duration(seconds:1)),validUntil:now.add(const Duration(hours:1)),
      offers:offers,globallyRanked:false,totalCount:offers.length);
  }
}
class _BrowseDetailedContent implements BuyV2ProductContentAdapter {
  @override BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) => BuyV2ProductContentSnapshot(
    productId:product.id,state:BuyV2ProductContentState.ready,sourceId:'HOST-native-detail-source',observedAt:DateTime.now(),
    description:'HOST original sourced product description',
    specifications:[for(var i=0;i<16;i++)BuyV2ProductSpecification(attributeId:'HOST-field-$i',label:'HOST field $i',value:'HOST original value $i')],
    media:const [BuyV2ProductMediaAsset(id:'HOST-media-1',label:'HOST original illustration 1',semanticLabel:'HOST native illustration 1',kind:BuyV2ProductContentMediaKind.cataloguePackshot),
      BuyV2ProductMediaAsset(id:'HOST-media-2',label:'HOST original illustration 2',semanticLabel:'HOST native illustration 2',kind:BuyV2ProductContentMediaKind.cataloguePackshot)]);
}
// Isolated HOST read source: supplies factual price data, never eligibility or an operational grant.
class _BrowsePriceFacts implements BuyV2ProductFactsAdapter {
  const _BrowsePriceFacts();
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) => BuyV2ProductFactsSnapshot(
    productId: product.id, priceMinor: product.priceMinor,
    deliveryPromise: 'HOST delivery availability unconfirmed', partner: product.seller,
    orderabilityLabel: 'HOST eligibility unavailable', sourceId: 'HOST-browse-price-facts',
    observedAt: DateTime.now());
}
class _BrowseNativeSession extends BuyV2Session {
  _BrowseNativeSession(_Shop03OwnerStore owner, ValueNotifier<BuyV2CollectionIdentity?> identity,
    _BrowseReadSource pages, _BrowseAreaSource areas, _BrowseFamilySource family, _BrowseSavedStore saved,
    {BuyV2ComparisonSource? comparisons, BuyV2ProductContentAdapter? detailContent, BuyV2ProductFactsAdapter? priceFacts})
    : _pages = pages, super(core: BuySession(), customerStateStore: owner, collectionIdentity: identity,
        cataloguePageSource: pages, shoppingAreaSource: areas, variantFamilySource: family, savedProductsStore: saved,
        comparisonSource:comparisons, productContentAdapter:detailContent, productFactsAdapter:priceFacts, reviewDataEnabled:true);
  final _BrowseReadSource _pages;
  int categoryChoices = 0, filters = 0, modes = 0, areaChoices = 0, opens = 0, variants = 0;
  int savedToggles = 0, savedClears = 0, viewedClears = 0, searchClears = 0, priceRequests = 0;
  @override BuyV2Product? findProduct(String id) => _pages.products[id] ?? super.findProduct(id);
  @override void chooseCategory(String id) { categoryChoices++; super.chooseCategory(id); }
  @override void applyDiscoveryRefinements(BuyV2DiscoveryRefinements value) { filters++; super.applyDiscoveryRefinements(value); }
  @override void chooseWholesaleSaleType(BuyV2WholesaleSaleType value) { modes++; super.chooseWholesaleSaleType(value); }
  @override bool chooseShoppingArea(BuyV2ShoppingArea value, BuyV2CatalogueAreaScope scope) {
    areaChoices++; return super.chooseShoppingArea(value, scope);
  }
  @override bool openProduct(String id, {bool preserveComparisonOrigin = false, bool reviewScheduledWindow = false,
    BuyV2ProductEntrySurface entrySurface = BuyV2ProductEntrySurface.unknown}) {
    opens++; return super.openProduct(id, preserveComparisonOrigin: preserveComparisonOrigin,
      reviewScheduledWindow: reviewScheduledWindow, entrySurface: entrySurface);
  }
  @override bool selectProductVariant(String id) { variants++; return super.selectProductVariant(id); }
  @override void toggleSaved(String id) { savedToggles++; super.toggleSaved(id); }
  @override void clearSavedProducts(BuyV2Destination value) { savedClears++; super.clearSavedProducts(value); }
  @override void clearRecentlyViewed(BuyV2Destination value) { viewedClears++; super.clearRecentlyViewed(value); }
  @override void clearRecentSearches(BuyV2Destination value) { searchClears++; super.clearRecentSearches(value); }
  @override Future<bool> requestCommodityPriceRefresh(BuyV2Product product, {bool Function()? isCurrent}) async {
    priceRequests++; return super.requestCommodityPriceRefresh(product, isCurrent: isCurrent);
  }
  Object get effects => (categoryChoices, filters, modes, areaChoices, opens, variants,
    savedToggles, savedClears, viewedClears, searchClears, priceRequests);
}
class _BrowseHarness {
  final owner = _Shop03OwnerStore(), saved = _BrowseSavedStore(), pages = _BrowseReadSource();
  final areas = _BrowseAreaSource(), family = _BrowseFamilySource();
  final comparison=_BrowseComparisonSource();bool comparisonEnabled=false, detailed=false, acceptedPriceFacts=false;
  final identity = ValueNotifier<BuyV2CollectionIdentity?>(const BuyV2CollectionIdentity(
    accountId: 'HOST-browse-owner', sessionId: 'HOST-browse-session'));
  final scope = ValueNotifier<int>(0), navigator = GlobalKey<NavigatorState>();
  late final session = _BrowseNativeSession(owner, identity, pages, areas, family, saved,
    comparisons:comparison,detailContent:detailed?_BrowseDetailedContent():null,
    priceFacts:acceptedPriceFacts?const _BrowsePriceFacts():null);
  MoolAssistantContext context = const MoolAssistantContext(accountScope:
    (environment: 'HOST', projectId: 'HOST-project', tenantId: null, userId: 'HOST-user'), authenticationRevision: 1);
  bool root = true;
  Future<bool> Function(Uri)? contactLauncher;
  int sequence = 0;
  late BuyV2Product product;
  Future<void> mount(WidgetTester tester, {bool stalePrice = false, bool commodity = false, bool variant = false, bool publicStore = false, bool compare=false, bool detailedContent=false, bool acceptedFacts=false}) async {
    comparisonEnabled=compare;detailed=detailedContent;acceptedPriceFacts=acceptedFacts;
    await session.restoreCustomerState(); await session.restoreSavedProducts();
    session.destination = BuyV2Destination.wholesale;
    final base = session.product('w-rice-50kg'), now = DateTime.now();
    final published = publicStore || stalePrice || commodity;
    final id = published ? 'listing-${List.filled(64, 'a').join()}' : base.id;
    final listing = published ? BuyV2PublicListingIdentity(listingId: id, realm: 'evaluation',
      storeId: 'HOST-native-store', skuId: 'HOST-sku', canonicalProductId: base.canonicalId,
      verifiedPackId: 'HOST-pack', channel: BuyV2OfferClass.wholesale) : null;
    final terms = BuyV2PackTerms(skuId: id, revision: 'HOST-pack-1', sellUnit: 'sack',
      pricingStoreId: stalePrice || commodity || publicStore ? 'HOST-native-store' : null,
      priceObservedAt: stalePrice || commodity || publicStore ? now.subtract(const Duration(hours: 1)) : null,
      priceValidUntil: stalePrice ? now.subtract(const Duration(minutes: 1)) : commodity || publicStore ? now.add(const Duration(hours: 1)) : null,
      commodityPriceRevision: stalePrice || commodity ? 1 : null, priceChangesFrequently: stalePrice || commodity ? true : null);
    product = base.copyWith(id: id, storeId: 'HOST-native-store', publicListingIdentity: listing,
      offerClass: BuyV2OfferClass.wholesale, pack: 'sack', unitPrice: '', packTerms: terms, catalogueListing: true,
      compliance:detailedContent?const BuyV2ProductCompliance(manufacturerName:'HOST original manufacturer',consumerCare:'HOST original public care details'):null,
      variantAttributes: variant ? const [BuyV2VariantAttribute(dimensionId: 'pack', dimensionLabel: 'Pack',
        optionId: 'sack', optionLabel: 'sack', kind: BuyV2VariantDimensionKind.pack)] : const []);
    pages.products[product.id] = product;
    comparison.productId=compare?product.id:null;
    final pager = session.acquireCatalogueProducts('HOST-browse-seed');
    await pager.open(session.catalogueQuery(catalogueDestination:product.destination,search:'')); expect(pager.page,isNotNull,reason:pager.message); expect(pager.page!.items.map((p)=>p.id),contains(product.id)); session.releaseCatalogueProducts('HOST-browse-seed');
    expect(session.findProduct(product.id), product); expect(product.hasValidPackTerms, isTrue);
    if (variant) {
      final next = product.copyWith(id: 'HOST-next-pack', pack: 'bag',
        packTerms: const BuyV2PackTerms(skuId: 'HOST-next-pack', revision: 'HOST-pack-2', sellUnit: 'bag'),
        variantAttributes: const [BuyV2VariantAttribute(dimensionId: 'pack', dimensionLabel: 'Pack',
          optionId: 'bag', optionLabel: 'bag', kind: BuyV2VariantDimensionKind.pack)]);
      pages.products[next.id] = next; family.products.addAll([product, next]);
    }
    expect(session.openProduct(product.id), isTrue);
    if (variant) { await tester.pumpAndSettle(); expect(await session.refreshVariantFamily(product, force: false), isTrue,reason:session.variantFamilyMessageFor(product)); }
    else session.view = BuyV2View.catalogue;
    await tester.pumpWidget(MaterialApp(navigatorKey: navigator, theme: MoolTheme.light(),
      home: const Scaffold(body: Text('HOST original Buy owner'))));
    await tester.pumpAndSettle();
  }
  BuyBrowseNativeAdapter adapter(String action) => BuyBrowseNativeAdapter(actionId: action, session: session,
    navigator: navigator.currentState!, currentContext: () => context, isRootCurrent: () => root,
    scopeOwner: scope, accountIdentity: () => _Shop03NativeHarness.principal, accountAuthenticated: () => true,
    contactLauncher: contactLauncher);
  Future<void> readStore() async {
    final pager=session.acquireCatalogueStores('HOST-browse-store-seed');
    await pager.open(session.catalogueQuery());session.releaseCatalogueStores('HOST-browse-store-seed');
  }
  Future<({Future<MoolAssistantReviewResult> result})> open(String action, Map<String, Object?> fields,
    {String? entity, DateTime? until}) async {
    final receiver = adapter(action);
    // Snapshot and review must use the same adapter's exact opaque revision.
    final snapshot = await receiver.snapshot(context, entity);
    expect(snapshot, isNotNull, reason: action);
    final binding = context.binding;
    return (result: receiver.openReview(MoolAssistantProposal(id: 'HOST-browse-${++sequence}', actionId: action,
      binding: binding, requestRevision: sequence, entitlementRevision: 'HOST', sourceRevision: snapshot!.sourceRevision,
      validUntil: until ?? DateTime.now().add(const Duration(minutes: 5)), title: 'HOST native browse review',
      summary: 'Original native controls own the result', entityId: entity, fields: fields), () => context.binding == binding));
  }
  Future<MoolAssistantNativeSnapshot?> receiverSnapshot(String action, String? entity) => adapter(action).snapshot(context, entity);
  Future<void> dispose(WidgetTester tester) async {
    if (areas.gate?.isCompleted == false) areas.gate!.complete(const []);
    await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpAndSettle();
    session.dispose(); session.core.dispose(); identity.dispose(); scope.dispose();
  }
}

void registerBuyBrowseNativeTests() {
  test('FE-SHOP-01 browse proposal schema freezes facts and excludes unknown fields', () {
    final brands = <String>['મૂળ brand'];
    final parsed = BuyBrowseInitialData.fromFields('AI-ACT-003', {'brands': brands, 'availableOnly': true});
    brands.clear(); expect(parsed.fields['brands'], ['મૂળ brand']);
    expect(() => (parsed.fields['brands']! as List).clear(), throwsUnsupportedError);
    for (final input in [('AI-ACT-005', <String,Object?>{'query':'x'}),
      ('AI-ACT-004', <String,Object?>{'saleType':'guessed-channel'}),
      ('AI-ACT-009', <String,Object?>{'saved':'yes'}), ('AI-ACT-999', <String,Object?>{})]) {
      expect(() => BuyBrowseInitialData.fromFields(input.$1,input.$2), throwsFormatException);
    }
  });
  testWidgets('FE-SHOP-01 category highlight and sale choice never mutate before native tap', (tester) async {
    final h = _BrowseHarness();
    try {
      await h.mount(tester);
      final category = h.session.categoriesFor(h.session.destination).firstWhere((c) => c.id != h.session.selectedCategoryId);
      final before = h.session.effects, writes = h.owner.writes;
      var result = (await h.open('AI-ACT-002', {'categoryId':category.id})).result;
      await tester.pumpAndSettle(); expect(h.session.effects,before); expect(h.owner.writes,writes);
      final row = find.byKey(ValueKey('buy-category-${category.id}'));
      await tester.scrollUntilVisible(row,200,maxScrolls:30,scrollable:find.descendant(
        of:find.byKey(const ValueKey('buy-category-draggable-sheet')),matching:find.byType(Scrollable)).last);
      await tester.tap(row); await tester.pumpAndSettle(); expect(await result,MoolAssistantReviewResult.opened);
      expect(h.session.categoryChoices,1); expect(h.session.selectedCategoryId,category.id);
      final modes = h.session.modes;
      result=(await h.open('AI-ACT-004',{'saleType':'bulk'})).result; await tester.pumpAndSettle();
      expect(h.session.modes,modes); expect(h.session.wholesaleSaleType,BuyV2WholesaleSaleType.wholesale);
      await tester.tap(find.byKey(const ValueKey('buy-wholesale-sale-type-bulk'))); await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.opened); expect(h.session.modes,modes+1);
    } finally { await h.dispose(tester); }
  });
  testWidgets('FE-SHOP-01 exact original filter draft applies only original Apply', (tester) async {
    final h=_BrowseHarness();
    try {
      await h.mount(tester); final original=h.session.discoveryRefinements, before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-003',{'maximumPrice':h.session.discoveryPriceLimits.first,
        'sort':'priceLowToHigh','availableOnly':true})).result; await tester.pumpAndSettle();
      expect(h.session.discoveryRefinements.maximumPrice,original.maximumPrice);expect(h.session.effects,before);expect(h.owner.writes,writes);
      expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('buy-refine-available-products'))).value,isTrue);
      await tester.tap(find.byKey(const ValueKey('buy-discovery-refinement-done')));await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.opened);expect(h.session.filters,1);
      expect(h.session.discoveryRefinements.availableOnly,isTrue);expect(h.session.discoveryRefinements.sort,BuyV2ProductSort.priceLowToHigh);
    } finally {await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 existing native filter and area input own their drafts before AI prefill', (tester) async {
    final h=_BrowseHarness();
    try{
      await h.mount(tester);final before=h.session.effects,writes=h.owner.writes;
      unawaited(showBuyV2DiscoveryRefinementSheet(h.navigator.currentContext!,h.session));await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-refine-section-sort')));await tester.pumpAndSettle();
      final sort=find.byKey(const ValueKey('buy-sort-priceLowToHigh'));await tester.ensureVisible(sort);await tester.pumpAndSettle();expect(sort.hitTestable(),findsOneWidget);
      await tester.tap(sort);await tester.pumpAndSettle();
      expect(await h.receiverSnapshot('AI-ACT-003',null),isNull);expect(h.session.effects,before);expect(h.owner.writes,writes);
      await tester.tap(find.byKey(const ValueKey('buy-discovery-refinement-close')));await tester.pumpAndSettle();
      expect(await h.receiverSnapshot('AI-ACT-003',null),isNotNull);
      h.areas.gate=Completer<List<BuyV2ShoppingArea>>();
      unawaited(showBuyV2CatalogueArea(h.navigator.currentContext!,h.session,initialQuery:'HOST original unfinished area'));
      await tester.pump();await tester.pump(const Duration(milliseconds:600));expect(await h.receiverSnapshot('AI-ACT-005',null),isNull);
      expect(tester.widget<TextField>(find.byKey(const ValueKey('buy-area-search-query'))).controller!.text,'HOST original unfinished area');
      expect(h.session.effects,before);expect(h.owner.writes,writes);expect(h.areas.locates,0);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 area raw query uses native read and original final confirmation', (tester) async {
    final h=_BrowseHarness();
    try {
      await h.mount(tester);final before=h.session.effects,writes=h.owner.writes,region=h.session.catalogueRegionId;
      final result=(await h.open('AI-ACT-005',{'query':'  મૂળ વિસ્તાર  '})).result;await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const ValueKey('buy-area-search-query'))).controller!.text,'  મૂળ વિસ્તાર  ');
      expect(h.areas.queries,['મૂળ વિસ્તાર']);expect(h.areas.locates,0);expect(h.session.effects,before);expect(h.owner.writes,writes);
      expect(h.session.catalogueRegionId,region);
      final confirm=find.byKey(const ValueKey('buy-current-location-confirm'));await tester.ensureVisible(confirm);await tester.tap(confirm);await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.opened);expect(h.session.areaChoices,1);expect(h.session.catalogueRegionId,'HOST-region');
    } finally {await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 unavailable and held area reads retain query without false location', (tester) async {
    final h=_BrowseHarness();
    try {
      await h.mount(tester);h.areas.gate=Completer<List<BuyV2ShoppingArea>>();final before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-005',{'query':'HOST area'})).result;await tester.pump();await tester.pump(const Duration(milliseconds:600));
      h.root=false;h.scope.value++;await tester.pumpAndSettle();h.areas.gate!.complete(const [_BrowseAreaSource.candidate]);await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.stale);expect(h.session.effects,before);expect(h.owner.writes,writes);expect(h.areas.locates,0);
      expect(find.byKey(const ValueKey('buy-current-location-confirm'),skipOffstage:false),findsNothing);
    } finally {await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 missing area provider remains truthful with editable supplied query', (tester) async {
    final h=_BrowseHarness();
    try{
      await h.mount(tester);h.areas.unavailable=true;final before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-005',{'query':'HOST unavailable area'})).result;await tester.pumpAndSettle();
      expect(find.textContaining('Shopping area search is unavailable'),findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const ValueKey('buy-area-search-query'))).controller!.text,'HOST unavailable area');
      expect(find.byKey(const ValueKey('buy-current-location-confirm')),findsNothing);expect(h.areas.locates,0);
      expect(h.session.effects,before);expect(h.owner.writes,writes);
      await tester.tap(find.byType(BackButton));await tester.pumpAndSettle();expect(await result,MoolAssistantReviewResult.opened);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 held old area query cannot replace newer raw input or stage old candidate', (tester) async {
    final h=_BrowseHarness();
    try{
      await h.mount(tester);h.areas.gate=Completer<List<BuyV2ShoppingArea>>();final before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-005',{'query':'HOST first query'})).result;await tester.pump();await tester.pump(const Duration(milliseconds:600));
      final field=find.byKey(const ValueKey('buy-area-search-query'));
      tester.widget<TextField>(field).controller!.text='HOST newer raw query';await tester.pump();
      h.areas.gate!.complete(const [_BrowseAreaSource.candidate]);await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text,'HOST newer raw query');
      expect(find.byKey(const ValueKey('buy-current-location-confirm')),findsNothing);expect(h.session.effects,before);expect(h.owner.writes,writes);
      await tester.tap(find.byType(BackButton));await tester.pumpAndSettle();await result;
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 native details and saved list read while missing comparison identity stays unavailable', (tester) async {
    final h=_BrowseHarness();
    try {
      await h.mount(tester);final before=h.session.effects,writes=h.owner.writes;
      final details=(await h.open('AI-ACT-006',{},entity:h.product.id)).result;await tester.pumpAndSettle();
      expect(find.text(h.product.customerTitle),findsWidgets);expect(h.session.effects,before);expect(h.owner.writes,writes);
      await tester.tap(find.byType(BackButton));await tester.pumpAndSettle();expect(await details,MoolAssistantReviewResult.opened);
      expect(h.session.comparisonSource,same(h.comparison));expect(h.comparison.identityFor(h.product),isNull);expect(h.comparison.requests,isEmpty);
      expect(await h.receiverSnapshot('AI-ACT-008',h.product.id),isNull);
      final saved=(await h.open('AI-ACT-010',{})).result;await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-saved-products-info-sheet')),findsOneWidget);expect(h.session.effects,before);
      await tester.tap(find.byType(BackButton));await tester.pumpAndSettle();expect(await saved,MoolAssistantReviewResult.opened);
    } finally {await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 actual full details target is read-only and uses its own theme and captured product', (tester) async {
    final h=_BrowseHarness();
    try {
      await h.mount(tester);h.session.selectedProductId='HOST-unrelated-native-selection';
      final selected=h.session.selectedProductId,before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-006',{},entity:h.product.id)).result;await tester.pumpAndSettle();
      expect(find.byType(BuyV2ProductView),findsOneWidget);
      final native=tester.widget<BuyV2ProductView>(find.byType(BuyV2ProductView));
      expect(native.capturedProduct,same(h.product));expect(h.session.selectedProductId,selected);
      expect(find.byKey(ValueKey('buy-product-title-${h.product.id}')),findsOneWidget);
      expect(find.byKey(const ValueKey('buy-product-captured-read-only')),findsOneWidget);
      final element=tester.element(find.byType(BuyV2ProductView));
      expect(BuyV2ThemeScope.refinedOf(element),isTrue);
      expect(BuyV2ThemeScope.of(element).accent,BuyV2ThemeSpec.resolve(BuyV2Destination.wholesale,BuyV2View.product).accent);
      final save=find.byKey(ValueKey('buy-product-action-save-${h.product.id}'));
      await tester.ensureVisible(save);await tester.tap(save,warnIfMissed:false);await tester.pump();
      expect(h.session.effects,before);expect(h.owner.writes,writes);expect(h.session.selectedProductId,selected);
      await tester.tap(find.byType(BackButton));await tester.pumpAndSettle();await result;
    } finally {await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 captured native details keep gallery drag lower scrolling tabs and payment reading', (tester) async {
    final h=_BrowseHarness();
    try {
      await h.mount(tester,detailedContent:true);h.session.view=BuyV2View.product;
      expect(h.session.selectedProductId,h.product.id);
      final before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-006',{},entity:h.product.id)).result;await tester.pumpAndSettle();
      final gallery=find.byKey(ValueKey('buy-product-gallery-${h.product.id}'));
      await tester.ensureVisible(gallery);await tester.drag(gallery,const Offset(-420,0));await tester.pumpAndSettle();
      expect(tester.widget<PageView>(gallery).controller!.page,closeTo(1,0.01));
      final list=find.byKey(PageStorageKey('buy-product-${h.product.id}'));
      final scroll=find.descendant(of:list,matching:find.byType(Scrollable)).first;
      final position=tester.state<ScrollableState>(scroll).position,beforeOffset=tester.state<ScrollableState>(scroll).position.pixels;
      await tester.drag(list,const Offset(0,-440));await tester.pumpAndSettle();expect(position.pixels,greaterThan(beforeOffset));
      final payment=find.byKey(ValueKey('buy-product-assurance-payment-${h.product.id}'));
      await tester.scrollUntilVisible(payment,300,scrollable:scroll);await tester.ensureVisible(payment);await tester.tap(payment);await tester.pumpAndSettle();
      expect(find.text('Review payment terms and available methods at checkout.'),findsOneWidget);
      await tester.tap(find.byTooltip('Close').last);await tester.pumpAndSettle();
      final pack=find.byKey(ValueKey('buy-product-details-tab-2-${h.product.id}'));
      await tester.scrollUntilVisible(pack,300,scrollable:scroll);await tester.ensureVisible(pack);await tester.tap(pack);await tester.pumpAndSettle();
      expect(find.text('HOST original manufacturer'),findsOneWidget);
      expect(h.session.effects,before);expect(h.owner.writes,writes);expect(h.session.selectedProductId,h.product.id);
      await tester.tap(find.byType(BackButton));await tester.pumpAndSettle();await result;
    } finally {await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 captured commodity details preserve fresh and expired native price guards', (tester) async {
    for (final expired in [false, true]) {
      final h=_BrowseHarness();
      try {
        await h.mount(tester,commodity:true,stalePrice:expired,acceptedFacts:true);
        h.session.view=BuyV2View.product;
        final facts=h.session.productFactsFor(h.product);
        expect(facts.sourceId,'HOST-browse-price-facts');
        expect(facts.eligibility,isNull); // No operational eligibility is fabricated by this read source.
        expect(facts.stale,expired);
        expect(h.product.packTerms!.pricingCurrentAt(h.session.catalogueNow()),!expired);
        final before=h.session.effects,writes=h.owner.writes;
        final result=(await h.open('AI-ACT-006',{},entity:h.product.id)).result;
        await tester.pumpAndSettle();
        final list=find.byKey(PageStorageKey('buy-product-${h.product.id}'));
        final scroll=find.descendant(of:list,matching:find.byType(Scrollable)).first;
        final details=find.byKey(ValueKey('buy-product-price-details-${h.product.id}'));
        await tester.scrollUntilVisible(details,250,scrollable:scroll);
        await tester.ensureVisible(details);await tester.pumpAndSettle();
        expect(details.hitTestable(),findsOneWidget);
        await tester.tap(details);await tester.pumpAndSettle();
        final inline=find.byKey(ValueKey('buy-product-price-details-inline-${h.product.id}'));
        expect(inline,findsOneWidget);
        final freshness=find.descendant(of:inline,matching:find.byType(BuyV2PriceFreshness));
        if (expired) {
          // Original native ProductPriceExtras suppresses freshness when native facts are stale.
          expect(freshness,findsNothing);
          expect(find.descendant(of:inline,matching:find.text('Check availability to confirm the current price.')),findsOneWidget);
        } else {
          expect(freshness,findsOneWidget);
          final widget=tester.widget<BuyV2PriceFreshness>(freshness);
          expect(widget.product,h.product);
          expect(widget.onRequestRefresh,isNull);
          expect(find.byKey(ValueKey('buy-price-freshness-${h.product.id}')),findsOneWidget);
        }
        expect(find.byKey(ValueKey('buy-request-price-refresh-${h.product.id}')),findsNothing);
        expect(h.session.priceRequests,0);
        expect(h.session.effects,before);expect(h.owner.writes,writes);
        final address=find.byKey(ValueKey('buy-product-change-address-${h.product.id}'));
        if(address.evaluate().isNotEmpty)expect(tester.widget<TextButton>(address).onPressed,isNull);
        await tester.tap(find.byType(BackButton));await tester.pumpAndSettle();await result;
      } finally {await h.dispose(tester);}
    }
  });
  testWidgets('FE-SHOP-01 captured Returns reads actual reviewed policy despite a different native selection', (tester) async {
    final h=_BrowseHarness();
    try {
      await h.mount(tester);
      h.product=h.product.copyWith(purchaseProtection:const BuyV2PurchaseProtection(summary:'HOST reviewed original return policy'));
      h.pages.products[h.product.id]=h.product;h.session.selectedProductId='HOST-other-native-selection';
      final before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-006',{},entity:h.product.id)).result;await tester.pumpAndSettle();
      final list=find.byKey(PageStorageKey('buy-product-${h.product.id}'));
      final scroll=find.descendant(of:list,matching:find.byType(Scrollable)).first;
      final returns=find.byKey(ValueKey('buy-product-assurance-returns-${h.product.id}'));
      await tester.scrollUntilVisible(returns,300,scrollable:scroll);await tester.ensureVisible(returns);await tester.pumpAndSettle();expect(returns.hitTestable(),findsOneWidget);await tester.tap(returns);await tester.pumpAndSettle();
      expect(find.descendant(of:find.byType(BottomSheet),matching:find.text('HOST reviewed original return policy')),findsOneWidget);
      expect(find.descendant(of:find.byType(BottomSheet),matching:find.text('Return policy unavailable')),findsNothing);
      expect(tester.widget<TextButton>(find.byKey(const ValueKey('buy-product-how-to-return'))).onPressed,isNull);
      expect(h.session.selectedProductId,'HOST-other-native-selection');expect(h.session.effects,before);expect(h.owner.writes,writes);
      await tester.tap(find.byTooltip('Close').last);await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));await tester.pumpAndSettle();await result;
    } finally {await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 captured nested Store Copy cannot write Clipboard after retirement', (tester) async {
    final h=_BrowseHarness();int copies=0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,(call)async{
      if(call.method=='Clipboard.setData')copies++;return null;
    });
    try {
      await h.mount(tester,publicStore:true);
      final result=(await h.open('AI-ACT-337',{},entity:h.product.id)).result;await tester.pumpAndSettle();
      final copy=find.byKey(ValueKey('buy-product-copy-store-${h.product.id}'));
      final callback=tester.widget<IconButton>(copy).onPressed!;
      expect(copies,0);h.root=false;h.scope.value++;await tester.pumpAndSettle();
      callback();await tester.pumpAndSettle();expect(copies,0);expect(await result,MoolAssistantReviewResult.stale);
    } finally {tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,null);await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 Share platform failure retains original review and permits explicit retry', (tester) async {
    final h=_BrowseHarness();int shares=0;bool fail=true;
    const channel=MethodChannel('dev.fluttercommunity.plus/share');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,(call)async{
      shares++;if(fail)throw PlatformException(code:'HOST-share-failed');return 'HOST-selected-target';
    });
    try {
      await h.mount(tester,publicStore:true);
      final result=(await h.open('AI-ACT-337',{},entity:h.product.id)).result;await tester.pumpAndSettle();expect(shares,0);
      final share=find.byKey(ValueKey('buy-product-action-share-${h.product.id}'));
      await tester.ensureVisible(share);await tester.tap(share);await tester.pumpAndSettle();
      expect(shares,1);expect(share,findsOneWidget);expect(find.text('Sharing is unavailable right now. Try again.'),findsWidgets);
      fail=false;await tester.tap(share);await tester.pumpAndSettle();expect(shares,2);expect(await result,MoolAssistantReviewResult.opened);
    } finally {tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,null);await h.dispose(tester);}
  });
  for(final excluded in ['Medicine','Rx']) {
    testWidgets('FE-SHOP-01 comparison rejects native-valid returned $excluded candidate', (tester) async {
      final h=_BrowseHarness();
      try {
        await h.mount(tester,compare:true);
        final candidate=h.product.copyWith(id:'HOST-candidate',title:'HOST excluded candidate',storeId:'HOST-other-store',
          packTerms:const BuyV2PackTerms(skuId:'HOST-candidate',revision:'HOST-r1',sellUnit:'sack'));
        h.comparison.offered=_browseExcludedProduct(candidate,rx:excluded=='Rx',
          destination:excluded=='Medicine'?BuyV2Destination.medicine:null);
        final before=h.session.effects,writes=h.owner.writes;
        final result=(await h.open('AI-ACT-008',{},entity:h.product.id)).result;await tester.pumpAndSettle();
        final request=h.comparison.requests.single,page=h.comparison.lastPage!;
        expect(page.validFor(request,DateTime.now()),isTrue,reason:'The original native page accepts this fixture; AI MVP supplies the missing boundary.');
        expect(h.session.comparisonOfferPermitted(page.offers.single),isTrue);
        expect(find.byKey(const ValueKey('buy-vertical-product-grid-comparison')),findsNothing);
        expect(find.byKey(const ValueKey('buy-comparison-item-price-HOST-offer')),findsNothing);
        expect(h.session.effects,before);expect(h.owner.writes,writes);
        await tester.tap(find.byType(BackButton));await tester.pumpAndSettle();await result;
      } finally {await h.dispose(tester);}
    });
  }
  testWidgets('FE-SHOP-01 original manual comparison keeps its null predicate behavior', (tester) async {
    final h=_BrowseHarness();
    try {
      await h.mount(tester,compare:true);
      final candidate=h.product.copyWith(id:'HOST-candidate',title:'HOST native candidate',storeId:'HOST-other-store',
        packTerms:const BuyV2PackTerms(skuId:'HOST-candidate',revision:'HOST-r1',sellUnit:'sack'));
      h.comparison.offered=_browseExcludedProduct(candidate,rx:true);h.session.view=BuyV2View.product;
      await tester.pumpWidget(MaterialApp(navigatorKey:h.navigator,theme:MoolTheme.light(),home:Scaffold(
        body:BuyV2ThemeScope(spec:BuyV2ThemeSpec.resolve(BuyV2Destination.wholesale,BuyV2View.product),refinedCommerce:true,
          child:BuyV2ProductView(session:h.session)))));await tester.pumpAndSettle();
      final compare=find.byKey(ValueKey('buy-product-action-compare-${h.product.id}'));
      await tester.ensureVisible(compare);await tester.pumpAndSettle();expect(compare.hitTestable(),findsOneWidget);await tester.tap(compare);await tester.pumpAndSettle();
      expect(h.comparison.lastPage!.validFor(h.comparison.requests.last,DateTime.now()),isTrue);
      expect(find.byKey(const ValueKey('buy-vertical-product-grid-comparison')),findsOneWidget);
    } finally {await h.dispose(tester);}
  });
  for(final action in ['AI-ACT-030','AI-ACT-031']) {
    testWidgets('FE-SHOP-01 parity correction gives applied $action original inline Cart target theme', (tester) async {
      final h=_Shop03ReviewHarness();
      try {
        await h.mount(tester);final group=h.session.scopedCartFulfilmentGroups.single;
        final before=h.session.effects,writes=h.owner.writes;
        await h.open(action,action=='AI-ACT-030'?{'text':'HOST native instruction'}:{'amount':13},
          entity:action=='AI-ACT-030'?'delivery':group.key);await tester.pumpAndSettle();
        final target=action=='AI-ACT-030'?find.byKey(const ValueKey('buy-cart-instruction-note-delivery')):find.byKey(ValueKey('buy-cart-tip-${group.key}-13'));
        final element=tester.element(target.first);
        expect(BuyV2ThemeScope.refinedOf(element),isTrue);
        expect(BuyV2ThemeScope.of(element).accent,BuyV2ThemeSpec.resolve(BuyV2Destination.wholesale,BuyV2View.cart).accent);
        expect(h.session.effects,before);expect(h.owner.writes,writes);
      } finally {await h.dispose(tester);}
    });
  }
  testWidgets('FE-SHOP-01 actual source variant uses original exact candidate control', (tester) async {
    final h=_BrowseHarness();
    try {
      await h.mount(tester,variant:true);final before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-007',{'variantId':'HOST-next-pack'},entity:h.product.id)).result;await tester.pumpAndSettle();
      expect(h.session.effects,before);expect(h.owner.writes,writes);expect(h.session.selectedProductId,h.product.id);
      final option=find.byKey(const ValueKey('buy-product-variant-HOST-next-pack'));
      await tester.ensureVisible(option);await tester.pumpAndSettle();expect(option.hitTestable(),findsOneWidget);await tester.tap(option);await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.opened);expect(h.session.variants,1);expect(h.session.selectedProductId,'HOST-next-pack');
    } finally {await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 native comparison retains supplied exact quantity without a Cart effect', (tester) async {
    final h=_BrowseHarness();
    try{
      await h.mount(tester,compare:true);final before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-008',{'quantityMilli':10125},entity:h.product.id)).result;await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-product-comparison-sheet')),findsOneWidget);
      expect(find.text('Quantity: 10.125 kilogram'),findsOneWidget);
      expect(h.comparison.requests.single.query.requestedQuantityMilli,10125);expect(h.session.effects,before);expect(h.owner.writes,writes);
      await tester.tap(find.byType(BackButton));await tester.pumpAndSettle();expect(await result,MoolAssistantReviewResult.opened);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 saved toggle and all three clears require original final controls', (tester) async {
    final h=_BrowseHarness();
    try {
      await h.mount(tester);final toggles=h.session.savedToggles;
      var result=(await h.open('AI-ACT-009',{'saved':true},entity:h.product.id)).result;await tester.pumpAndSettle();
      expect(h.session.savedToggles,toggles);await tester.tap(find.byKey(ValueKey('buy-product-action-save-${h.product.id}')));await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.opened);expect(h.session.isSaved(h.product.id),isTrue);
      for(final action in ['AI-ACT-011','AI-ACT-012','AI-ACT-013']){
        if(action=='AI-ACT-013')h.session.submitSearch('HOST original recent search');
        final before=h.session.effects,writes=h.owner.writes;result=(await h.open(action,{})).result;await tester.pumpAndSettle();
        expect(h.session.effects,before);expect(h.owner.writes,writes);
        final clear=action=='AI-ACT-011'?find.byKey(const ValueKey('buy-saved-confirm-clear')):
          find.byKey(ValueKey(action=='AI-ACT-012'?'buy-settings-recently-viewed-confirm':'buy-recent-searches-confirm'));
        await tester.ensureVisible(clear);await tester.tap(clear);await tester.pumpAndSettle();expect(await result,MoolAssistantReviewResult.opened);
      }
      expect(h.session.savedClears,1);expect(h.session.viewedClears,1);expect(h.session.searchClears,1);
    } finally {await h.dispose(tester);}
  });
  for(final action in ['AI-ACT-060','AI-ACT-352']){
    testWidgets('FE-SHOP-01 $action price request never runs during Review', (tester) async {
      final h=_BrowseHarness();
      try{
        await h.mount(tester,stalePrice:true);final before=h.session.effects,writes=h.owner.writes;
        final result=(await h.open(action,{},entity:h.product.id)).result;await tester.pumpAndSettle();
        expect(h.session.effects,before);expect(h.owner.writes,writes);
        final request=find.byKey(ValueKey('buy-request-price-refresh-${h.product.id}'));await tester.ensureVisible(request);await tester.pumpAndSettle();expect(request.hitTestable(),findsOneWidget);await tester.tap(request);await tester.pumpAndSettle();
        expect(h.session.priceRequests,1);expect(find.textContaining('Price refresh request not confirmed'),findsOneWidget);
        await tester.tap(find.byType(BackButton));await tester.pumpAndSettle();await result;
      }finally{await h.dispose(tester);}
    });
  }
  testWidgets('FE-SHOP-01 fresh native commodity metadata cannot open a stale-only refresh control', (tester) async {
    final h=_BrowseHarness();
    try {await h.mount(tester,commodity:true);
      expect(h.product.packTerms!.pricingCurrentAt(h.session.catalogueNow()),isTrue);
      for(final id in ['AI-ACT-060','AI-ACT-352'])expect(await h.receiverSnapshot(id,h.product.id),isNull);
      expect(h.session.priceRequests,0);
    } finally {await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 share remains an explicit original control and retires before callback', (tester) async {
    final h=_BrowseHarness();
    try{
      await h.mount(tester,publicStore:true);final before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-337',{},entity:h.product.id)).result;await tester.pumpAndSettle();
      final dynamic button=tester.widget(find.byKey(ValueKey('buy-product-action-share-${h.product.id}')));
      final callback=button.onPressed as VoidCallback;
      expect(h.session.effects,before);expect(h.owner.writes,writes);
      h.root=false;h.scope.value++;await tester.pumpAndSettle();callback();await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.stale);expect(h.session.effects,before);expect(h.session.notice,isNot('Sharing is unavailable right now. Try again.'));
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 product Copy platform failure remains visible and explicit retry succeeds', (tester) async {
    final h=_BrowseHarness();int copies=0;bool fail=true;String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,(call)async{
      if(call.method=='Clipboard.setData') {copies++;if(fail)throw PlatformException(code:'HOST-copy-failed');copied=(call.arguments as Map)['text'] as String;}
      return null;
    });
    try {
      await h.mount(tester,publicStore:true);
      final result=(await h.open('AI-ACT-336',{},entity:h.product.id)).result;await tester.pumpAndSettle();expect(copies,0);
      final copy=find.byKey(ValueKey('buy-product-action-copy-link-${h.product.id}'));
      await tester.ensureVisible(copy);await tester.tap(copy);await tester.pumpAndSettle();
      expect(copies,1);expect(copy,findsOneWidget);expect(find.byKey(const ValueKey('buy-browse-native-error')),findsOneWidget);
      expect(find.text('Could not copy the product link. Try again.'),findsOneWidget);expect(tester.takeException(),isNull);
      fail=false;await tester.tap(copy);await tester.pumpAndSettle();
      expect(copies,2);expect(copied,buyV2SharedProductUri(h.product).toString());expect(await result,MoolAssistantReviewResult.opened);
    } finally {tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,null);await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 product Copy uses exact native URI only after one user tap', (tester) async {
    final h=_BrowseHarness();int copies=0;String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,(call)async{
      if(call.method=='Clipboard.setData'){copies++;copied=(call.arguments as Map)['text'] as String;}return null;
    });
    try{
      await h.mount(tester,publicStore:true);final before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-336',{},entity:h.product.id)).result;await tester.pumpAndSettle();
      expect(copies,0);expect(h.session.effects,before);expect(h.owner.writes,writes);
      final dynamic button=tester.widget(find.byKey(ValueKey('buy-product-action-copy-link-${h.product.id}')));
      final callback=button.onPressed as VoidCallback;callback();callback();await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.opened);expect(copies,1);expect(copied,buyV2SharedProductUri(h.product).toString());
      final retired=(await h.open('AI-ACT-336',{},entity:h.product.id)).result;await tester.pumpAndSettle();
      final dynamic old=tester.widget(find.byKey(ValueKey('buy-product-action-copy-link-${h.product.id}')));final oldCallback=old.onPressed as VoidCallback;
      h.root=false;h.scope.value++;await tester.pumpAndSettle();oldCallback();await tester.pumpAndSettle();
      expect(await retired,MoolAssistantReviewResult.stale);expect(copies,1);expect(h.owner.writes,writes);
    }finally{tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,null);await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 actual Store contact opens only exact tel URI on native Call', (tester) async {
    final h=_BrowseHarness();final calls=<Uri>[];h.contactLauncher=(uri)async{calls.add(uri);return true;};
    try{
      await h.mount(tester,publicStore:true);await h.readStore();await tester.pumpAndSettle();
      expect(h.session.catalogueStore(h.product.storeId!)?.publicContactPhone,h.pages.phone);
      final before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-339',{},entity:h.product.id)).result;await tester.pumpAndSettle();
      expect(calls,isEmpty);expect(h.session.effects,before);expect(h.owner.writes,writes);
      expect(find.text('Contact: ${h.pages.phone}'),findsOneWidget);
      final call=find.byKey(ValueKey('buy-store-call-${h.product.storeId}'));await tester.ensureVisible(call);await tester.tap(call);await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.opened);expect(calls,[Uri(scheme:'tel',path:h.pages.phone!)]);
      expect(h.session.effects,before);expect(h.owner.writes,writes);
      final retired=(await h.open('AI-ACT-339',{},entity:h.product.id)).result;await tester.pumpAndSettle();
      final old=tester.widget<TextButton>(find.byKey(ValueKey('buy-store-call-${h.product.storeId}'))).onPressed!;
      h.pages.phone='+919900000001';
      expect(await h.session.refreshCatalogueStore(h.product.storeId!,h.product.destination),isNotNull);
      expect(h.session.catalogueStore(h.product.storeId!)?.publicContactPhone,h.pages.phone);
      h.scope.value++;await tester.pumpAndSettle();old();await tester.pumpAndSettle();
      expect(await retired,MoolAssistantReviewResult.stale);expect(calls.length,1);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 absent public product link/contact source never invents a target', (tester) async {
    final h=_BrowseHarness();
    try{
      await h.mount(tester);expect(await h.receiverSnapshot('AI-ACT-336',h.product.id),isNull);
      expect(await h.receiverSnapshot('AI-ACT-337',h.product.id),isNull);expect(await h.receiverSnapshot('AI-ACT-339',h.product.id),isNull);
      expect(await h.receiverSnapshot('AI-ACT-006',h.product.id),isNotNull);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 exact mounted Store search prefill preserves global query and refuses active original input', (tester) async {
    final h=_BrowseHarness();
    try{
      await h.mount(tester,publicStore:true);
      expect(await h.receiverSnapshot('AI-ACT-338',h.product.id),isNull);
      unawaited(showBuyV2PartnerCatalogue(h.navigator.currentContext!,h.session,h.product));await tester.pumpAndSettle();
      expect(buyV2BrowseStoreOwner(h.session,h.product),isNotNull);
      final originalStoreQuery=h.session.retainedCatalogueQuery('store-wholesale-HOST-native-store')?.query;
      final query=h.session.query,before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-338',{'query':'મૂળ Store query'},entity:h.product.id)).result;await tester.pumpAndSettle();
      final field=find.byKey(const ValueKey('buy-store-product-search'));
      expect(tester.widget<TextField>(field).controller!.text,'મૂળ Store query');expect(h.session.query,query);expect(h.session.effects,before);expect(h.owner.writes,writes);
      expect(h.session.retainedCatalogueQuery('store-wholesale-HOST-native-store')?.query,originalStoreQuery);
      await tester.tap(find.byType(BackButton));await tester.pumpAndSettle();expect(await result,MoolAssistantReviewResult.opened);
      final original=find.byKey(const ValueKey('buy-store-product-search'));await tester.enterText(original,'HOST unfinished native query');await tester.pumpAndSettle();
      expect(await h.receiverSnapshot('AI-ACT-338',h.product.id),isNull);expect(tester.widget<TextField>(original).controller!.text,'HOST unfinished native query');
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 Medicine actor exposes none of the frozen browse receivers', (tester) async {
    final h=_BrowseHarness();
    try{
      await h.mount(tester);expect(await h.receiverSnapshot('AI-ACT-003',null),isNotNull);
      expect(await h.receiverSnapshot('AI-ACT-006',h.product.id),isNotNull);
      final before=h.session.effects,writes=h.owner.writes;h.session.destination=BuyV2Destination.medicine;
      for(final action in BuyBrowseInitialData.actions){expect(await h.receiverSnapshot(action,h.product.id),isNull,reason:action);}
      expect(h.session.effects,before);expect(h.owner.writes,writes);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-01 real expiry retires original nested filter and preserves unrelated root route', (tester) async {
    final h=_BrowseHarness();
    try{
      await h.mount(tester);final before=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-003',{'availableOnly':true},until:DateTime.now().add(const Duration(seconds:3)))).result;
      await tester.pumpAndSettle();expect(find.byKey(const ValueKey('buy-discovery-refinement-title')),findsOneWidget);
      unawaited(h.navigator.currentState!.push<void>(MaterialPageRoute<void>(builder:(_)=>const Scaffold(body:Text('HOST unrelated browse route')))));
      await tester.pumpAndSettle();await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:3200)));
      await tester.pump(const Duration(seconds:4));await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.stale);
      expect(find.byKey(const ValueKey('buy-discovery-refinement-title'),skipOffstage:false),findsNothing);
      expect(find.text('Review product discovery',skipOffstage:false),findsNothing);expect(find.text('HOST unrelated browse route'),findsOneWidget);
      expect(h.session.effects,before);expect(h.owner.writes,writes);expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
  for(final kind in ['actor','Rx','listing','root']){
    testWidgets('FE-SHOP-01 $kind retirement preserves saved rows and blocks captured final tap', (tester) async {
      final h=_BrowseHarness();
      try{
        await h.mount(tester);final before=h.session.effects,writes=h.owner.writes;
        final result=(await h.open('AI-ACT-009',{'saved':true},entity:h.product.id)).result;await tester.pumpAndSettle();
        final dynamic button=tester.widget(find.byKey(ValueKey('buy-product-action-save-${h.product.id}')));final callback=button.onPressed as VoidCallback;
        if(kind=='actor')h.context=const MoolAssistantContext(accountScope:(environment:'HOST',projectId:'HOST-project',tenantId:null,userId:'HOST-other'),authenticationRevision:2);
        else if(kind=='Rx')h.pages.products[h.product.id]=_browseExcludedProduct(h.product,rx:true);
        else if(kind=='listing')h.pages.products[h.product.id]=h.product.copyWith(packTerms:BuyV2PackTerms(skuId:h.product.id,revision:'HOST-changed-pack',sellUnit:'sack'));
        else h.root=false;
        h.scope.value++;await tester.pumpAndSettle();callback();await tester.pumpAndSettle();
        expect(await result,MoolAssistantReviewResult.stale);expect(h.session.effects,before);expect(h.owner.writes,writes);expect(h.saved.keys,isEmpty);
      }finally{await h.dispose(tester);}
    });
  }
}

// Isolated HOST source contracts and original native controls only; never installed on a device.
class _CartNativeFacts implements BuyV2ProductFactsAdapter {
  _CartNativeFacts(this.now);final DateTime now;
  String slot='HOST-cart-slot-1',revision='HOST-cart-facts-1';bool available=true;int? priceMinorOverride;
  @override BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product p){
    if(p.publicListingIdentity==null)return const BuyV2CatalogueProductFactsAdapter().snapshotFor(p);
    return BuyV2ProductFactsSnapshot(
    productId:p.id,priceMinor:priceMinorOverride??p.priceMinor,deliveryPromise:'HOST original delivery',partner:p.seller,
    orderabilityLabel:available?'Available to add':'Out of stock',sourceId:'HOST-cart-facts',observedAt:now,
    storeOperatingState:BuyV2StoreOperatingState.open,eligibility:BuyV2OfferEligibility(
      productId:p.id,storeId:p.storeId!,sourceRevision:revision,customerLocationKey:'||0',
      observedAt:now.subtract(const Duration(seconds:1)),expiresAt:now.add(const Duration(hours:1)),offerClass:p.offerClass!,
      channelEnabled:true,storeReady:true,fleetAvailable:true,customerLocationConfirmed:true,
      options:const {BuyV2DeliveryOption.courier,BuyV2DeliveryOption.scheduled},scheduledSlotId:slot,
      scheduledStart:now.add(const Duration(hours:2)),scheduledEnd:now.add(const Duration(hours:3))));
  }
}
class _CartNativeContent implements BuyV2ProductContentAdapter {
  _CartNativeContent(this.now);final DateTime now;bool requirePolicy=false;
  @override BuyV2ProductContentSnapshot snapshotFor(BuyV2Product p)=>BuyV2ProductContentSnapshot(
    productId:p.id,state:BuyV2ProductContentState.ready,sourceId:'HOST-cart-content',observedAt:now,
    supplierPolicyAcceptanceRequired:requirePolicy,
    supplierPolicy:requirePolicy?BuyV2SupplierPolicy(id:'HOST-cart-policy',storeId:p.storeId!,revision:'HOST-policy-1',
      title:'HOST original Store policy',body:'HOST original delivery and return terms',productIds:{p.sourceSkuId},
      sourceRealm:p.publicListingIdentity?.realm,requiresAcceptance:true):null);
}
class _CartNativeBenefits extends BuyV2SeededCartBenefitsAdapter {
  _CartNativeBenefits(this.now);final DateTime now;
  late final value=BuyV2CartBenefit(id:'HOST-cart-benefit',kind:BuyV2CartBenefitKind.coupon,
    destination:BuyV2Destination.shop,title:'HOST બચત offer',detail:'HOST original offer terms',sourceId:'HOST-cart-benefit-source',
    revision:1,savingAmountMinor:1,validFrom:now.subtract(const Duration(hours:1)),validUntil:now.add(const Duration(hours:1)));
  @override List<BuyV2CartBenefit> benefitsFor({required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,required int itemTotal})=>
    kind==value.kind && destinations.contains(value.destination)?[value]:const [];
}
String _cartNativeHash(Object? value){
  Object? sorted(Object? v)=>v is Map?{for(final k in (v.keys.cast<String>().toList()..sort()))k:sorted(v[k])}:
    v is List?v.map(sorted).toList():v;
  return sha256.convert(utf8.encode(jsonEncode(sorted(value)))).toString().toUpperCase();
}
class _CartNativePages extends _BrowseReadSource implements BuyV2StructuredStoreCouponSource,BuyV2StoreCouponEligibilitySource {
  final coupons=<BuyV2PublishedStoreCoupon>[];int checks=0;Completer<void>? checkGate;
  @override bool get storeCouponsActive=>true;
  @override bool get structuredStoreCouponDisplayActive=>true;
  @override bool get storeCouponEligibilityActive=>true;
  @override Future<List<BuyV2PublishedStoreCoupon>> loadStoreCoupons({required String storeId})async=>
    coupons.where((c)=>c.storeId==storeId).toList();
  @override Future<BuyV2StoreCouponEligibility> evaluateStoreCoupon({required BuyV2PublishedStoreCoupon coupon,
    required List<BuyV2CartLine> lines,required bool Function() current})async{
    checks++;await checkGate?.future;
    if(!current())throw const FormatException('HOST retired coupon read');
    final now=DateTime.now().toUtc();
    final query=<String,Object?>{'storeId':coupon.storeId,'couponId':coupon.couponId,'couponRevision':coupon.revision,
      'selectionPolicy':'exclusive_store_basket','lines':[for(final l in lines){'lineId':l.product.id,
        'listing':l.product.publicListingIdentity!.toJson(),'skuRevision':1,'offerId':'HOST-public-offer',
        'offerRevision':1,'quantity':l.quantity}]};
    // Explicit accepted HOST reply, not a runtime eligibility calculation or grant.
    final subtotal=lines.fold<int>(0,(sum,l)=>sum+l.totalMinor);
    final response={'schemaVersion':1,'storeCouponEligibilityVersion':1,'realm':coupon.realm,'viewerUserId':'HOST-cart-owner',
      'storeId':coupon.storeId,'selectionPolicy':'exclusive_store_basket','exclusiveSelectionRequired':true,
      'state':'ready','eligible':true,'reason':null,'observedAt':now.toIso8601String(),
      'validUntil':now.add(const Duration(seconds:30)).toIso8601String(),
      'requestFingerprint':_cartNativeHash({'operation':'storeCouponEligibilityV1','realm':coupon.realm,
        'actor':'HOST-cart-owner','query':query,'exclusiveSelectionRequired':true}),
      'orderingAvailable':false,'reservationCreated':false,
      'evaluation':{'schemaVersion':1,'realm':coupon.realm,'storeId':coupon.storeId,'buyerUserId':'HOST-cart-owner',
        'couponId':coupon.couponId,'couponRevision':coupon.revision,'name':coupon.name,'basketSourceId':'B'*64,
        'basketSourceRevision':1,'basketFingerprint':'C'*64,'eligibleSubtotalMinor':subtotal,'savingMinor':1,
        'allocations':[for(var i=0;i<lines.length;i++){'lineId':lines[i].product.id,
          'skuId':lines[i].product.publicListingIdentity!.skuId,'packId':lines[i].product.publicListingIdentity!.verifiedPackId,
          'offerId':'HOST-public-offer','offerRevision':1,'subtotalMinor':lines[i].totalMinor,'savingMinor':i==0?1:0}]},
      'attribution':{'benefitRevision':'store-coupon-v${coupon.revision}',
        'sourceReference':_cartNativeHash(['storeCouponCampaignV1',coupon.realm,coupon.storeId,coupon.couponId,coupon.revision]),
        'funderReference':_cartNativeHash(['storeCouponFunderV1',coupon.realm,coupon.storeId])}};
    return BuyV2StoreCouponEligibility.decode(response,coupon:coupon,accountId:'HOST-cart-owner',query:query,lines:lines,now:now);
  }
}
class _CartNativeOwner extends _Shop03OwnerStore {
  Completer<void>? writeGate,writeEntered;
  bool rejectWrites=false;
  BuyV2CustomerStateSnapshot? lastSnapshot,initialSnapshot;
  @override Future<BuyV2CustomerStateSnapshot?> read()async=>initialSnapshot;
  @override Future<bool> write(BuyV2CustomerStateSnapshot snapshot)async{
    if(writeEntered?.isCompleted==false)writeEntered!.complete();
    await writeGate?.future;
    if(rejectWrites)return false;
    lastSnapshot=snapshot;
    return super.write(snapshot);
  }
}
class _CartNativeSession extends BuyV2Session {
  _CartNativeSession(_CartNativeOwner owner,ValueNotifier<BuyV2CollectionIdentity?> identity,
    this.pages,_CartNativeFacts facts,_CartNativeContent content,_CartNativeBenefits benefits,TestPaymentCommerce commerce,{bool reviewDataEnabled=true,BuyV2CheckoutQuoteAdapter? checkoutQuoteAdapter,BuyV2DeliveryExceptionAdapter? delivery,BuyV2OrderResolutionAdapter? resolution,BuyV2BalancePaymentAdapter? balance,ScanPickGateway? collection,BuyV2CollectionPendingStore? pending,AuthenticatedWorkspaceOrderIdentityGateway? reader}):
    super(core:BuySession(),customerStateStore:owner,collectionIdentity:identity,cataloguePageSource:pages,
      productFactsAdapter:facts,productContentAdapter:content,cartBenefitsAdapter:benefits,commerceAdapter:commerce,checkoutQuoteAdapter:checkoutQuoteAdapter,reviewDataEnabled:reviewDataEnabled,deliveryExceptionAdapter:delivery,orderResolutionAdapter:resolution,balancePaymentAdapter:balance,collectionGateway:collection,collectionPendingStore:pending,purchaseReader:reader,purchaseRealm:'evaluation');
  final _CartNativePages pages;
  List<BuyV2CartLine>? observedLines;
  @override List<BuyV2CartLine> get allCartLines=>observedLines??super.allCartLines;
  int adds=0,buys=0,removes=0,clears=0,schedules=0,baskets=0,retries=0;
  bool held=false;
  @override BuyV2Product? findProduct(String id)=>pages.products[id]??super.findProduct(id);
  @override bool get checkoutRequiresResolution=>held || super.checkoutRequiresResolution;
  @override bool addProduct(String id,{int? quantity}){adds++;return super.addProduct(id,quantity:quantity);}
  @override bool buyProductNow(String id){buys++;return super.buyProductNow(id);}
  @override void remove(String id){removes++;super.remove(id);}
  @override bool clearCartScope(BuyV2CartScope scope){clears++;return super.clearCartScope(scope);}
  @override Future<bool> addProductForScheduledWindow(String id,BuyV2ScheduledFulfilment selected,
    {int? quantity,BuyV2CartLine? replaceLine}){schedules++;return super.addProductForScheduledWindow(id,selected,quantity:quantity,replaceLine:replaceLine);}
  @override void addMonthlyBasket(){baskets++;super.addMonthlyBasket();}
  @override bool retryCheckoutAvailability(){retries++;return super.retryCheckoutAvailability();}
  Object get effects=>(adds,buys,removes,clears,schedules,baskets,retries,pages.checks);
}
class _CartNativeHarness {
  _CartNativeHarness({TestPaymentCommerce? commerce,this.reviewDataEnabled=true,this.checkoutQuoteAdapter,this.delivery,this.resolution,this.balance,this.collection,this.pending,this.reader}):commerce=commerce??TestPaymentCommerce();
  final bool reviewDataEnabled;
  final BuyV2DeliveryExceptionAdapter? delivery;final BuyV2OrderResolutionAdapter? resolution;
  final BuyV2BalancePaymentAdapter? balance;final ScanPickGateway? collection;final BuyV2CollectionPendingStore? pending;final AuthenticatedWorkspaceOrderIdentityGateway? reader;
  final BuyV2CheckoutQuoteAdapter? checkoutQuoteAdapter;
  final owner=_CartNativeOwner(),pages=_CartNativePages();final instant=DateTime.now();
  final identity=ValueNotifier<BuyV2CollectionIdentity?>(const BuyV2CollectionIdentity(accountId:'HOST-cart-owner',sessionId:'HOST-cart-session'));
  final changes=ValueNotifier<int>(0),scope=ValueNotifier<int>(0),navigator=GlobalKey<NavigatorState>();
  late final facts=_CartNativeFacts(instant),content=_CartNativeContent(instant),benefits=_CartNativeBenefits(instant);
  final TestPaymentCommerce commerce;
  late final session=_CartNativeSession(owner,identity,pages,facts,content,benefits,commerce,reviewDataEnabled:reviewDataEnabled,checkoutQuoteAdapter:checkoutQuoteAdapter,delivery:delivery,resolution:resolution,balance:balance,collection:collection,pending:pending,reader:reader);
  MoolAssistantContext context=const MoolAssistantContext(accountScope:
    (environment:'HOST',projectId:'HOST-project',tenantId:null,userId:'HOST-user'),authenticationRevision:1);
  bool root=true,paid=true;int sequence=0;late BuyV2Product product;
  Future<void> mount(WidgetTester tester,{bool inCart=false,bool coupon=false,bool structured=false,BuyV2Destination destination=BuyV2Destination.shop,bool restoreAfterSource=false})async{
    if(!restoreAfterSource)await session.restoreCustomerState();session.destination=destination;
    final channel=destination==BuyV2Destination.wholesale?BuyV2OfferClass.wholesale:BuyV2OfferClass.retail;
    final base=BuyV2Catalogue.products.firstWhere((p)=>p.destination==destination && p.offerClass==channel && !p.requiresPrescription);
    final id='listing-${'d'*64}';
    product=base.copyWith(id:id,storeId:'HOST-native-store',minimumOrder:1,offerClass:channel,
      catalogueListing:true,pack:'pack',unitPrice:'',publicListingIdentity:BuyV2PublicListingIdentity(listingId:id,
        realm:'evaluation',storeId:'HOST-native-store',skuId:'HOST-cart-sku',canonicalProductId:base.canonicalId,
        verifiedPackId:'HOST-cart-pack',channel:channel),
      packTerms:BuyV2PackTerms(skuId:id,revision:'HOST-cart-pack-r1',sellUnit:'pack',pricingStoreId:'HOST-native-store',
        priceObservedAt:instant.subtract(const Duration(minutes:1)),priceValidUntil:instant.add(const Duration(hours:1))));
    pages.products[id]=product;
    // This source supplies courier/scheduled eligibility, not a Quick grant.
    // Production-mode query validation must use its actual native channel.
    if(!reviewDataEnabled && destination==BuyV2Destination.shop){
      session.chooseShopSaleType(BuyV2ShopSaleType.courier);
      expect(session.shopSaleType,BuyV2ShopSaleType.courier);
    }
    final pager=session.acquireCatalogueProducts('HOST-cart-source');
    await pager.open(session.catalogueQuery(catalogueDestination:product.destination,search:''));
    expect(pager.page,isNotNull,reason:pager.message);expect(pager.page!.items.map((p)=>p.id),contains(id));session.releaseCatalogueProducts('HOST-cart-source');
    expect(product.hasValidPackTerms,isTrue);expect(session.productFactsFor(product).stale,isFalse);
    if(restoreAfterSource)await session.restoreCustomerState();
    if(inCart){expect(session.addProduct(id),isTrue,reason:session.notice);session.openCart();}
    if(coupon){
      final listing=product.publicListingIdentity!;
      pages.coupons.add(structured?BuyV2PublishedStoreCoupon.offer(realm:'evaluation',storeId:product.storeId!,couponId:'HOST-coupon',revision:1,
        name:'HOST મૂળ offer',publisherName:'HOST Store',publisherType:BuyV2OfferPublisherType.retailer,
        sourceId:'store-offer-v2:evaluation:${product.storeId}:HOST-coupon:1',observedAt:instant,
        validFrom:instant.subtract(const Duration(hours:1)),validUntil:instant.add(const Duration(hours:1)),configuredTotalUses:20,configuredUsesPerCustomer:1,
        structuredTerms:BuyV2StoreOfferTerms(storeId:product.storeId!,kind:BuyV2StoreOfferKind.productDiscount,
          skus:[BuyV2StoreOfferSku(storeId:product.storeId!,skuId:listing.skuId,title:product.title,sellUnit:product.pack,listings:[listing])],
          channels:const ['retail'],discountKind:'flat',discountValue:1,maximumSavingMinor:1)):
        BuyV2PublishedStoreCoupon(realm:'evaluation',storeId:product.storeId!,couponId:'HOST-coupon',revision:1,
          name:'HOST મૂળ coupon',publisherName:'HOST Store',publisherType:BuyV2OfferPublisherType.retailer,
          sourceId:'store-coupon:evaluation:${product.storeId}:HOST-coupon:1',observedAt:instant,
          validFrom:instant.subtract(const Duration(hours:1)),validUntil:instant.add(const Duration(hours:1)),configuredTotalUses:20,configuredUsesPerCustomer:1,
          terms:BuyV2AdvertisedBenefitTerms(kind:'flat',flatAmountMinor:1,flatBasis:'per_order',maximumSavingMinor:1,minimumSpendMinor:0)));
      expect(await session.refreshPublishedStoreCoupons(product.id),isTrue);
      expect(session.cartStoreCoupons,isNotEmpty);
    }
    await tester.pumpWidget(MaterialApp(navigatorKey:navigator,theme:MoolTheme.light(),
      home:const Scaffold(body:Text('HOST original Cart owner'))));await tester.pumpAndSettle();
  }
  BuyCartReviewNativeAdapter adapter(String action)=>BuyCartReviewNativeAdapter(actionId:action,session:session,navigator:navigator.currentState!,
    currentContext:()=>context,isRootCurrent:()=>root,scopeOwner:scope,
    accountIdentity:()=>_Shop03NativeHarness.principal,accountAuthenticated:()=>true);
  Future<({Future<MoolAssistantReviewResult> result})> open(String action,{Map<String,Object?> fields=const {},String? entity,DateTime? until})async{
    final a=adapter(action),binding=context.binding,snapshot=await a.snapshot(context,entity);expect(snapshot,isNotNull,reason:action);
    final p=MoolAssistantProposal(id:'HOST-cart-${++sequence}',actionId:action,binding:binding,requestRevision:sequence,
      entitlementRevision:'HOST-paid-contract',sourceRevision:snapshot!.sourceRevision,validUntil:until??DateTime.now().add(const Duration(minutes:5)),
      title:'HOST original Cart review',summary:'Native final controls own the operation',entityId:entity,fields:fields);
    return(result:a.openOwnedReview(p,isCurrent:()=>paid && context.binding==binding,ownerChanges:changes));
  }
  void retire(){paid=false;changes.value++;}
  Future<void> dispose(WidgetTester tester)async{
    if(pages.checkGate?.isCompleted==false)pages.checkGate!.complete();
    if(owner.writeGate?.isCompleted==false)owner.writeGate!.complete();
    await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();
    session.dispose();session.core.dispose();identity.dispose();changes.dispose();scope.dispose();
  }
}

void registerShop02RemainingNativeTests(){
  Future<void> tap(WidgetTester tester,Finder f)async{
    await tester.ensureVisible(f);await tester.pumpAndSettle();expect(f.hitTestable(),findsOneWidget);await tester.tap(f);await tester.pumpAndSettle();
  }
  test('FE-SHOP-02 closes typed fields without inventing eligibility or scheduling facts',(){
    final fields=<String,Object?>{'quantity':3};final v=BuyCartReviewInitialData.fromFields('AI-ACT-014',fields);
    fields['quantity']=99;expect(v.quantity,3);
    for(final entry in [('AI-ACT-014',<String,Object?>{'quantity':'3'}),('AI-ACT-014',<String,Object?>{'quantity':0}),
      ('AI-ACT-015',<String,Object?>{'slotId':' '}),('AI-ACT-021',<String,Object?>{'savingMinor':1}),
      ('AI-ACT-023',<String,Object?>{'eligible':true}),('AI-ACT-059',<String,Object?>{'retryPayment':true})]){
      expect(()=>BuyCartReviewInitialData.fromFields(entry.$1,entry.$2),throwsFormatException);
    }
  });
  for(final action in ['AI-ACT-014','AI-ACT-017'])testWidgets('FE-SHOP-02 $action uses original editable packs and dispatches only its native final control',(tester)async{
    final h=_CartNativeHarness();try{
      await h.mount(tester);final effects=h.session.effects,writes=h.owner.writes,selection=h.session.selectedProductId;
      final result=(await h.open(action,entity:h.product.id,fields:{'quantity':3})).result;await tester.pumpAndSettle();
      final input=find.byKey(const ValueKey('buy-quantity-input'));
      expect(tester.widget<TextField>(input).controller!.text,'3');expect(h.session.effects,effects);expect(h.owner.writes,writes);
      expect(h.session.selectedProductId,selection);
      expect(await h.adapter(action).snapshot(h.context,h.product.id),isNull);await tester.enterText(input,'2');
      await tap(tester,find.byKey(const ValueKey('buy-quantity-save')));await result;
      expect(h.session.adds,1);expect(h.session.quantityFor(h.product.id),2);expect(h.session.buys,action=='AI-ACT-017'?1:0);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 Add cancellation preserves the original Cart and persisted state',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester);final effects=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-014',entity:h.product.id,fields:{'quantity':4})).result;await tester.pumpAndSettle();
      await tap(tester,find.text('Cancel'));await result;expect(h.session.effects,effects);expect(h.owner.writes,writes);expect(h.session.quantityFor(h.product.id),0);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 captured quantity callback is inert after paid owner retirement',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester);final result=(await h.open('AI-ACT-014',entity:h.product.id,fields:{'quantity':2})).result;
      await tester.pumpAndSettle();final callback=tester.widget<FilledButton>(find.byKey(const ValueKey('buy-quantity-save'))).onPressed!;
      final effects=h.session.effects,writes=h.owner.writes;h.retire();await tester.pumpAndSettle();callback();await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.stale);expect(h.session.effects,effects);expect(h.owner.writes,writes);expect(find.byKey(const ValueKey('buy-quantity-input')),findsNothing);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 source replacement retires supplied packs without switching selection',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester);final selected=h.session.selectedProductId;
      final result=(await h.open('AI-ACT-014',entity:h.product.id,fields:{'quantity':2})).result;await tester.pumpAndSettle();
      h.pages.products[h.product.id]=h.product.copyWith(title:'HOST replaced exact source');h.scope.value++;await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.stale);expect(h.session.adds,0);expect(h.session.selectedProductId,selected);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 native schedule stages exact slot and holds its original save after one tap',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester);final effects=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-015',entity:h.product.id,fields:{'quantity':2,'slotId':h.facts.slot})).result;await tester.pumpAndSettle();
      expect(find.textContaining('Requested window only.'),findsOneWidget);expect(h.session.effects,effects);expect(h.owner.writes,writes);
      final callback=tester.widget<FilledButton>(find.byKey(const ValueKey('buy-quantity-save'))).onPressed!;
      h.owner.writeGate=Completer<void>();callback();callback();await tester.pump();expect(h.session.schedules,1);
      h.owner.writeGate!.complete();await tester.pumpAndSettle();await result;
      final line=h.session.cartLineFor(h.product.id)!;expect(line.quantity,2);expect(line.scheduledFulfilment!.slotId,h.facts.slot);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 principal retirement during an owned scheduled save retains the native Cart operation and awaits it',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester);final result=(await h.open('AI-ACT-015',entity:h.product.id,fields:{'quantity':2})).result;
      var returned=false;unawaited(result.then((_) {returned=true;}));await tester.pumpAndSettle();h.owner.writeGate=Completer<void>();
      await tester.tap(find.byKey(const ValueKey('buy-quantity-save')));await tester.pump();expect(h.session.schedules,1);
      expect(h.session.quantityFor(h.product.id),2);final nativeOwner=h.owner.ownerScope;
      h.context=const MoolAssistantContext(accountScope:(environment:'HOST',projectId:'HOST-project',tenantId:null,userId:'HOST-next-user'),authenticationRevision:2);
      h.scope.value++;await tester.pumpAndSettle();expect(h.owner.ownerScope,nativeOwner);expect(returned,isFalse);
      expect(find.byKey(const ValueKey('buy-quantity-input')),findsNothing);h.owner.writeGate!.complete();await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.stale);expect(h.session.schedules,1);expect(h.session.quantityFor(h.product.id),2);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 an existing original manual quantity draft cannot be replaced by a proposal',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true);final effects=h.session.effects,writes=h.owner.writes;
      final manual=showBuyV2QuantityEditor(h.navigator.currentState!.overlay!.context,h.session,h.product);
      await tester.pumpAndSettle();await tester.enterText(find.byKey(const ValueKey('buy-quantity-input')),'7');
      expect(await h.adapter('AI-ACT-014').snapshot(h.context,h.product.id),isNull);
      expect(tester.widget<TextField>(find.byKey(const ValueKey('buy-quantity-input'))).controller!.text,'7');
      expect(find.text('Edit quantity'),findsOneWidget);expect(find.text('Update quantity'),findsOneWidget);
      expect(h.session.effects,effects);expect(h.owner.writes,writes);await tap(tester,find.text('Cancel'));await manual;
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 native replacement confirmation preserves all existing units and an unrelated late route',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true);final original=h.session.cartLineFor(h.product.id)!;
      final result=(await h.open('AI-ACT-015',entity:h.product.id,fields:{'quantity':original.quantity,'slotId':h.facts.slot})).result;await tester.pumpAndSettle();
      await tap(tester,find.byKey(const ValueKey('buy-quantity-save')));expect(find.text('Replace delivery choice?'),findsOneWidget);
      expect(h.session.schedules,0);expect(h.session.cartLineFor(h.product.id),same(original));
      final old=tester.widget<TextButton>(find.widgetWithText(TextButton,'Replace choice')).onPressed!;
      final unrelated=h.navigator.currentState!.push<void>(MaterialPageRoute(builder:(_)=>const Scaffold(body:Text('HOST later unrelated route'))));
      await tester.pumpAndSettle();h.retire();await tester.pumpAndSettle();old();await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.stale);expect(find.text('HOST later unrelated route'),findsOneWidget);
      expect(h.session.schedules,0);expect(h.session.cartLineFor(h.product.id),same(original));
      h.navigator.currentState!.pop();await tester.pumpAndSettle();await unrelated;
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 replacement rejects conflicting supplied units before showing a quantity form',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true);expect(h.session.setCartQuantity(h.product.id,'2'),isTrue);await tester.pumpAndSettle();
      final effects=h.session.effects,writes=h.owner.writes,original=h.session.cartLineFor(h.product.id)!;
      final result=(await h.open('AI-ACT-015',entity:h.product.id,fields:{'quantity':5,'slotId':h.facts.slot})).result;
      expect(await result,MoolAssistantReviewResult.unavailable);expect(find.byKey(const ValueKey('buy-quantity-input')),findsNothing);
      expect(h.session.cartLineFor(h.product.id),same(original));expect(original.quantity,2);expect(h.session.effects,effects);expect(h.owner.writes,writes);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 successful native replacement fixes the original two packs through the final outcome',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true);expect(h.session.setCartQuantity(h.product.id,'2'),isTrue);await tester.pumpAndSettle();
      final result=(await h.open('AI-ACT-015',entity:h.product.id,fields:{'quantity':2,'slotId':h.facts.slot})).result;await tester.pumpAndSettle();
      final field=tester.widget<TextField>(find.byKey(const ValueKey('buy-quantity-input')));
      expect(field.controller!.text,'2');expect(field.readOnly,isTrue);
      expect(find.textContaining('All 2 packs will use this window. Quantity stays unchanged.'),findsOneWidget);
      await tap(tester,find.byKey(const ValueKey('buy-quantity-save')));expect(h.session.schedules,0);
      expect(find.text('Replace delivery choice?'),findsOneWidget);await tap(tester,find.widgetWithText(TextButton,'Replace choice'));
      expect(await result,MoolAssistantReviewResult.opened);final line=h.session.cartLineFor(h.product.id)!;
      expect(line.quantity,2);expect(line.scheduledFulfilment!.slotId,h.facts.slot);expect(h.session.schedules,1);expect(h.session.buys,0);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 scheduled policy consent returns its actual native Add result without Buy or Checkout',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester);h.content.requirePolicy=true;final view=h.session.view;
      final result=(await h.open('AI-ACT-015',entity:h.product.id,fields:{'quantity':2,'slotId':h.facts.slot})).result;await tester.pumpAndSettle();
      await tap(tester,find.byKey(const ValueKey('buy-quantity-save')));
      expect(find.byKey(const ValueKey('buy-supplier-policy-sheet')),findsOneWidget);expect(h.session.quantityFor(h.product.id),0);
      await tap(tester,find.byKey(const ValueKey('buy-supplier-policy-accept-and-add')));
      expect(await result,MoolAssistantReviewResult.opened);final line=h.session.cartLineFor(h.product.id)!;
      expect(line.quantity,2);expect(line.scheduledFulfilment!.slotId,h.facts.slot);
      expect(h.session.schedules,2); // First attempt requires policy; the original consent control performs the one committed Add.
      expect(h.session.buys,0);expect(h.session.view,view);expect(find.byKey(const ValueKey('buy-quantity-input')),findsNothing);
    }finally{await h.dispose(tester);}
  });
  for(final destination in [BuyV2Destination.shop,BuyV2Destination.wholesale]){
    for(final action in ['AI-ACT-014','AI-ACT-015','AI-ACT-017'])testWidgets('FE-SHOP-02 $action quantity modal inherits actual ${destination.name} Product theme',(tester)async{
      final h=_CartNativeHarness();try{await h.mount(tester,destination:destination);h.session.view=BuyV2View.product;
        final expected=BuyV2ThemeSpec.resolve(h.product.destination,h.session.view),effects=h.session.effects,writes=h.owner.writes;
        final result=(await h.open(action,entity:h.product.id,fields:{'quantity':2})).result;await tester.pumpAndSettle();
        final context=tester.element(find.byKey(const ValueKey('buy-quantity-input'))),actual=BuyV2ThemeScope.of(tester.element(find.byKey(const ValueKey('buy-quantity-input'))));
        expect(BuyV2ThemeScope.refinedOf(context),isTrue);expect(actual.accent,expected.accent);expect(actual.softAccent,expected.softAccent);
        expect(actual.headerEnd,expected.headerEnd);expect(actual.headerGradient,expected.headerGradient);
        expect(h.session.effects,effects);expect(h.owner.writes,writes);await tap(tester,find.text('Cancel'));await result;
      }finally{await h.dispose(tester);}
    });
  }
  testWidgets('FE-SHOP-02 unknown window identity cannot replace the native accepted slot',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester);final effects=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-015',entity:h.product.id,fields:{'slotId':'HOST-not-the-source-slot'})).result;
      expect(await result,MoolAssistantReviewResult.unavailable);expect(h.session.effects,effects);expect(h.owner.writes,writes);
      expect(find.byKey(const ValueKey('buy-quantity-input')),findsNothing);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 monthly basket is the original read-only plan until an original final action',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester);final effects=h.session.effects,writes=h.owner.writes,intent=h.session.activeShoppingIntent;
      final result=(await h.open('AI-ACT-016')).result;await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-household-basket-info-sheet')),findsOneWidget);
      expect(h.session.effects,effects);expect(h.owner.writes,writes);expect(h.session.activeShoppingIntent,intent);
      await tap(tester,find.byType(BackButton));await result;expect(h.session.effects,effects);expect(h.owner.writes,writes);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 Remove uses the original Cart line and one captured whole-line action',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true);final effects=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-019',entity:h.product.id)).result;await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('buy-cart-line-${h.product.id}')),findsOneWidget);expect(h.session.effects,effects);expect(h.owner.writes,writes);
      await tap(tester,find.byTooltip('Remove ${h.product.customerTitle} from Cart'));await result;
      expect(h.session.removes,1);expect(h.session.cartLineFor(h.product.id),isNull);
    }finally{await h.dispose(tester);}
  });
  for(final confirm in [false,true])testWidgets('FE-SHOP-02 Clear preserves native confirmation $confirm',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true);final effects=h.session.effects,writes=h.owner.writes;
      final result=(await h.open('AI-ACT-020')).result;await tester.pumpAndSettle();expect(find.byKey(const ValueKey('buy-cart-clear-sheet')),findsOneWidget);
      expect(h.session.effects,effects);expect(h.owner.writes,writes);
      await tap(tester,find.byKey(ValueKey(confirm?'buy-cart-clear-confirm':'buy-cart-clear-cancel')));await result;
      expect(h.session.clears,confirm?1:0);expect(h.session.quantityFor(h.product.id),confirm?0:1);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 real expiry removes only its owned quantity/modal routes',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester);final result=(await h.open('AI-ACT-014',entity:h.product.id,
      until:DateTime.now().add(const Duration(seconds:2)))).result;await tester.pumpAndSettle();
      final unrelated=h.navigator.currentState!.push<void>(MaterialPageRoute(builder:(_)=>const Scaffold(body:Text('HOST unrelated route'))));
      await tester.pumpAndSettle();await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds:2200)));await tester.pump(const Duration(seconds:3));await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.stale);expect(find.text('HOST unrelated route'),findsOneWidget);
      expect(h.session.adds,0);h.navigator.currentState!.pop();await tester.pumpAndSettle();await unrelated;
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 structured Store offer keeps original Apply disabled and truthful',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true,coupon:true,structured:true);final effects=h.session.effects,writes=h.owner.writes;
      final c=h.session.cartStoreCoupons.single,result=(await h.open('AI-ACT-021',entity:h.session.cartStoreCoupons.single.identity)).result;
      await tester.pumpAndSettle();expect(find.text('Applying this offer is not connected yet.'),findsOneWidget);
      final apply=find.widgetWithText(TextButton,'Apply');expect(tester.widget<TextButton>(apply).onPressed,isNull);
      expect(h.session.effects,effects);expect(h.owner.writes,writes);expect(h.session.selectedStoreCouponFor(c),isNull);
      await tap(tester,find.byType(BackButton));await result;
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 coupon eligibility is read only after native Apply and stale results cannot select',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true,coupon:true);final c=h.session.cartStoreCoupons.single;
      final result=(await h.open('AI-ACT-021',entity:c.identity)).result;await tester.pumpAndSettle();expect(h.pages.checks,0);
      h.pages.checkGate=Completer<void>();await tester.tap(find.widgetWithText(TextButton,'Apply'));await tester.pump();expect(h.pages.checks,1);
      final writes=h.owner.writes;h.retire();await tester.pumpAndSettle();h.pages.checkGate!.complete();await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.stale);expect(h.session.selectedStoreCouponFor(c),isNull);expect(h.owner.writes,writes);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 Remove coupon uses exact native checked selection without another eligibility request',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true,coupon:true);final c=h.session.cartStoreCoupons.single;
      expect(await h.session.chooseStoreCoupon(c),isTrue,reason:h.session.storeCouponMessage(c));final selected=h.session.selectedStoreCouponFor(c);
      final effects=h.session.effects,writes=h.owner.writes,result=(await h.open('AI-ACT-022',entity:c.identity)).result;await tester.pumpAndSettle();
      expect(h.session.selectedStoreCouponFor(c),same(selected));expect(h.session.effects,effects);expect(h.owner.writes,writes);
      await tap(tester,find.widgetWithText(TextButton,'Remove'));await result;expect(h.session.selectedStoreCouponFor(c),isNull);expect(h.pages.checks,1);
    }finally{await h.dispose(tester);}
  });
  for(final removing in [false,true])testWidgets('FE-SHOP-02 original offer card ${removing?'removes':'chooses'} only on native final tap',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true);final b=h.session.cartBenefits(kind:BuyV2CartBenefitKind.coupon,destination:BuyV2Destination.shop).single;
      if(removing)expect(h.session.chooseCartBenefit(b),isTrue);
      final effects=h.session.effects,writes=h.owner.writes,result=(await h.open(removing?'AI-ACT-347':'AI-ACT-023',entity:BuyV2Session.benefitIdentity(b))).result;
      await tester.pumpAndSettle();expect(h.session.effects,effects);expect(h.owner.writes,writes);expect(h.session.isCartBenefitSelected(b),removing);
      await tap(tester,find.byKey(ValueKey('buy-cart-benefit-${removing?'remove':'select'}-${b.id}')));await result;
      expect(h.session.isCartBenefitSelected(b),!removing);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 native policy consent remains awaited after retirement and cannot add after its held read',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester);h.content.requirePolicy=true;
      final result=(await h.open('AI-ACT-014',entity:h.product.id,fields:{'quantity':2})).result;
      var returned=false;unawaited(result.then((_) {returned=true;}));await tester.pumpAndSettle();
      await tap(tester,find.byKey(const ValueKey('buy-quantity-save')));
      final consent=find.byKey(const ValueKey('buy-supplier-policy-accept-and-add'));expect(consent,findsOneWidget);
      h.owner.writeGate=Completer<void>();await tester.tap(consent);await tester.pump();
      expect(h.session.supplierPolicyConsentBusy,isTrue);final adds=h.session.adds;
      h.retire();await tester.pumpAndSettle();expect(find.byKey(const ValueKey('buy-supplier-policy-sheet')),findsNothing);
      expect(returned,isFalse);h.owner.writeGate!.complete();await tester.pumpAndSettle();
      expect(await result,MoolAssistantReviewResult.stale);expect(h.session.adds,adds);expect(h.session.quantityFor(h.product.id),0);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 recovery uses actual native availability issue and only its native Retry control',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true);expect(h.session.openCheckout(),isTrue);
      expect(h.session.selectedAddressOrNull,isNotNull);
      h.commerce.snapshot=BuyV2CommerceSnapshot(state:BuyV2CommerceLoadState.ready,products:[h.product],paymentMethods:const {'UPI'},
        paymentCapabilities:[testPaymentCapability(h.session)],businessVerified:true,addresses:h.session.addresses,
        selectedAddressId:h.session.selectedAddressId);
      await h.session.restoreCommerce();
      expect(h.session.setCustomDeliveryInstruction(destination:BuyV2Destination.shop,text:'HOST original delivery instruction'),isTrue);
      h.facts.available=false;expect(h.session.confirmOrder(),isFalse);
      expect(h.session.checkoutAvailabilityIssue?.productId,h.product.id,reason:h.session.notice);
      expect(h.session.recoveryKind,BuyV2RecoveryKind.stockUnavailable);expect(h.commerce.requests,isEmpty);
      h.facts.available=true;await tester.pumpAndSettle();final effects=h.session.effects,writes=h.owner.writes,retries=h.session.retries;
      final result=(await h.open('AI-ACT-059',entity:h.product.id)).result;await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-recovery-affected-product')),findsOneWidget);expect(h.session.effects,effects);expect(h.owner.writes,writes);
      expect(h.session.retries,retries);expect(tester.widget<OutlinedButton>(find.byKey(const ValueKey('buy-recovery-remove-product'))).onPressed,isNull);
      await tap(tester,find.byKey(const ValueKey('buy-recovery-retry-availability')));await result;
      expect(h.session.retries,retries+1);expect(h.session.checkoutAvailabilityIssue,isNull);expect(h.commerce.requests,isEmpty);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 Medicine and Rx retained Cart contexts cannot enter an otherwise permitted public action',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true);final effects=h.session.effects,writes=h.owner.writes;
      final nativeLine=h.session.cartLineFor(h.product.id)!;
      final medicine=BuyV2Catalogue.products.firstWhere((p)=>p.destination==BuyV2Destination.medicine);
      final p=h.product;
      final rx=BuyV2Product(id:p.id,canonicalId:p.canonicalId,destination:p.destination,
        categoryId:p.categoryId,brand:p.brand,title:p.title,variant:p.variant,pack:p.pack,
        priceMinor:p.priceMinor,unitPrice:p.unitPrice,badge:p.badge,seller:p.seller,sellerType:p.sellerType,
        deliveryPromise:p.deliveryPromise,origin:p.origin,confirmedOn:p.confirmedOn,visualLabel:p.visualLabel,
        visualKind:p.visualKind,storeId:p.storeId,packTerms:p.packTerms,publicListingIdentity:p.publicListingIdentity,
        minimumOrder:p.minimumOrder,offerClass:p.offerClass,requiresPrescription:true);
      expect(rx.destination,BuyV2Destination.shop);expect(rx.requiresPrescription,isTrue);
      expect(rx.hasValidPackTerms,isTrue);expect(rx.hasValidPublicListingIdentity,isTrue);
      expect(rx.publicListingIdentity,p.publicListingIdentity);
      for(final excluded in [medicine,rx]){
        h.session.observedLines=[nativeLine,BuyV2CartLine(product:excluded,quantity:1)];
        expect(await h.adapter('AI-ACT-014').snapshot(h.context,h.product.id),isNull);
        expect(await h.adapter('AI-ACT-020').snapshot(h.context,null),isNull);
      }
      h.session.observedLines=null;
      h.context=MoolAssistantContext(accountScope:h.context.accountScope,authenticationRevision:1,
        workspaceId:'HOST-approved-Store',workspaceRevision:1,storeWorkspace:true,workspaceApproved:true);
      expect(await h.adapter('AI-ACT-014').snapshot(h.context,h.product.id),isNull);
      expect(h.session.effects,effects);expect(h.owner.writes,writes);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-02 all native actions refuse held payments and no Clear helper branch runs on Review',(tester)async{
    final h=_CartNativeHarness();try{await h.mount(tester,inCart:true);h.session.held=true;final effects=h.session.effects,writes=h.owner.writes;
      for(final id in const ['AI-ACT-014','AI-ACT-015','AI-ACT-016','AI-ACT-017','AI-ACT-019','AI-ACT-020','AI-ACT-021','AI-ACT-022','AI-ACT-023','AI-ACT-059','AI-ACT-347']){
        expect(await h.adapter(id).snapshot(h.context,h.product.id),isNull,reason:id);
      }
      expect(h.session.effects,effects);expect(h.owner.writes,writes);expect(h.session.quantityFor(h.product.id),1);
    }finally{await h.dispose(tester);}
  });
}

void main() {
  registerShop06NativeHostTests();
  registerShop05NativeTests();
  registerPublicProductFeedbackTests();
  registerPublicReviewDraftRecoveryTests();
  registerShop04NativeHostTests();
  registerShop02RemainingNativeTests();
  registerBuyBrowseNativeTests();
  registerShop03RemainingNativeTests();
  registerShop03RemainingSafetyTests();
  registerShop03NativeFormTests();
  registerHandoffCurrentBuyerTests();
  _registerAiAct018RouterDepartureTest();
  _registerAiAct001Tests();
  _registerAiAct018Tests();
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_Lf08AddressSession> openLf08Picker(
    WidgetTester tester,
    _CartReturnOwnerStore owner,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final identity = ValueNotifier<BuyV2CollectionIdentity?>(
      const BuyV2CollectionIdentity(
        accountId: 'lf08-a',
        sessionId: 'lf08-session-a',
      ),
    );
    addTearDown(identity.dispose);
    final session = _Lf08AddressSession(owner, identity);
    addTearDown(session.dispose);
    addTearDown(session.core.dispose);
    expect(session.addProduct('s-tomato'), isTrue);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  unawaited(showBuyV2AddressSheet(context, session)),
              child: const Text('Open evaluation addresses'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open evaluation addresses'));
    await tester.pumpAndSettle();
    return session;
  }

  for (final drift in ['none', 'owner', 'navigation', 'auth', 'auth-aba']) {
    testWidgets('LF08 address selection after reverse $drift', (tester) async {
      final owner = _CartReturnOwnerStore();
      final session = await openLf08Picker(tester, owner);
      final original = session.selectedAddressId;
      final total = session.cartTotal;
      await tester.tap(find.byKey(const ValueKey('buy-address-work')));
      if (drift == 'owner') owner.ownerScope = 'lf08-owner-b';
      if (drift.startsWith('auth')) {
        session.buyerIdentity.value = const BuyV2CollectionIdentity(
          accountId: 'lf08-b',
          sessionId: 'lf08-session-b',
        );
        if (drift == 'auth-aba') {
          session.buyerIdentity.value = const BuyV2CollectionIdentity(
            accountId: 'lf08-a',
            sessionId: 'lf08-session-a-new',
          );
        }
      }
      if (drift == 'navigation') {
        session.openDestination(BuyV2Destination.wholesale);
        session.openDestination(BuyV2Destination.shop);
      }
      await tester.pumpAndSettle();
      expect(session.selectedAddressId, drift == 'none' ? 'work' : original);
      expect(session.cartTotal, total);
      expect(session.quantityFor('s-tomato'), 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final drift in [false, true]) {
    testWidgets('LF08 address removal confirmation owner drift $drift', (
      tester,
    ) async {
      final owner = _CartReturnOwnerStore();
      final session = await openLf08Picker(tester, owner);
      final before = session.addresses.length;
      await tester.tap(find.byKey(const ValueKey('buy-address-actions-work')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-address-delete-work')));
      await tester.pumpAndSettle();
      if (drift) owner.ownerScope = 'lf08-owner-b';
      await tester.tap(
        find.byKey(const ValueKey('buy-address-delete-confirm')),
      );
      await tester.pumpAndSettle();
      expect(session.addresses.length, before - (drift ? 0 : 1));
      expect(session.quantityFor('s-tomato'), 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final action in ['add', 'direct-edit-work', 'request']) {
    testWidgets('LF08 stale picker prevents $action entry', (tester) async {
      final owner = _CartReturnOwnerStore();
      final session = await openLf08Picker(tester, owner);
      owner.ownerScope = 'lf08-owner-b';
      await tester.tap(find.byKey(ValueKey('buy-address-$action')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-address-add-form-route')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-address-request-form-route')),
        findsNothing,
      );
      expect(session.addresses.length, 2);
      expect(session.requests, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final changedIdentity in [false, true]) {
    testWidgets(
      'LF08 address edit retains original identity $changedIdentity',
      (tester) async {
        final owner = _CartReturnOwnerStore();
        final session = await openLf08Picker(tester, owner);
        final original = session.addresses.singleWhere((a) => a.id == 'work');
        await tester.tap(
          find.byKey(const ValueKey('buy-address-direct-edit-work')),
        );
        await tester.pumpAndSettle();
        final name = find.byKey(const ValueKey('buy-address-add-recipient'));
        await tester.enterText(name, 'Evaluation edited recipient');
        if (changedIdentity) {
          session.buyerIdentity.value = const BuyV2CollectionIdentity(
            accountId: 'lf08-b',
            sessionId: 'lf08-session-b',
          );
        }
        final submit = find.byKey(const ValueKey('buy-address-add-submit'));
        await tester.scrollUntilVisible(
          submit,
          180,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('buy-address-add-form-list')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(
          session.addresses.singleWhere((a) => a.id == 'work').recipient,
          changedIdentity ? original.recipient : 'Evaluation edited recipient',
        );
        expect(
          find.byKey(const ValueKey('buy-address-add-form-route')),
          changedIdentity ? findsOneWidget : findsNothing,
        );
        expect(session.quantityFor('s-tomato'), 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final outcome in [
    'ready',
    'late-owner',
    'late-auth',
    'failure',
    'stale-copy',
    'stale-manual',
  ]) {
    testWidgets('LF08 address request $outcome preserves owner and input', (
      tester,
    ) async {
      final owner = _CartReturnOwnerStore();
      final session = await openLf08Picker(tester, owner);
      var copies = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') copies++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('buy-address-request')));
      await tester.pumpAndSettle();
      final name = find.byKey(const ValueKey('buy-address-request-recipient'));
      await tester.enterText(name, 'Evaluation recipient');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      if (outcome.startsWith('stale')) owner.ownerScope = 'lf08-owner-b';
      await tester.tap(
        find.byKey(
          ValueKey(
            outcome == 'stale-manual'
                ? 'buy-address-request-enter-manually'
                : 'buy-address-request-copy',
          ),
        ),
      );
      await tester.pump();
      if (outcome == 'late-owner') owner.ownerScope = 'lf08-owner-b';
      if (outcome == 'late-auth') {
        session.buyerIdentity.value = const BuyV2CollectionIdentity(
          accountId: 'lf08-b',
          sessionId: 'lf08-session-b',
        );
      }
      if (!outcome.startsWith('stale')) {
        if (outcome == 'failure') {
          session.response.completeError(
            StateError('isolated request failure'),
          );
        } else {
          session.response.complete(
            BuyV2AddressRequestResult(
              shareUri: Uri.parse('https://example.invalid/lf08-address'),
              customerMessage: 'Isolated host fixture',
            ),
          );
        }
      }
      await tester.pumpAndSettle();
      expect(copies, outcome == 'ready' ? 1 : 0);
      expect(session.requests, outcome.startsWith('stale') ? 0 : 1);
      expect(
        find.byKey(const ValueKey('buy-address-add-form-route')),
        findsNothing,
      );
      expect(
        tester.widget<TextField>(name).controller!.text,
        'Evaluation recipient',
      );
      expect(session.addresses.length, 2);
      expect(session.quantityFor('s-tomato'), 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 2.0]) {
    for (final location in ['missing', 'matching', 'foreign']) {
      testWidgets('LF07 Store location $location text $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 844);
        addTearDown(tester.view.reset);
        final product = BuyV2Catalogue.products
            .firstWhere((item) => item.id == 's-eggs')
            .copyWith(storeId: 'lf07-evaluation-store');
        final session = _Lf07LocationSession(
          location == 'missing'
              ? null
              : BuyV2StoreListing(
                  id: location == 'matching' ? product.storeId! : 'other-store',
                  name: product.seller,
                  area: 'Evaluation Store locality',
                  address: 'Evaluation Store address',
                  regionId: 'evaluation-region',
                ),
        );
        addTearDown(session.dispose);
        expect(product.origin, isNotEmpty);
        expect(
          session.marketplaceTrustFor(product).state,
          BuyV2MarketplaceTrustState.ready,
        );
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
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => unawaited(
                    showBuyV2PartnerCatalogue(context, session, product),
                  ),
                  child: const Text('Open evaluation Store'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open evaluation Store'));
        await tester.pumpAndSettle();
        final label = tester
            .widget<Text>(
              find.byKey(const ValueKey('buy-public-store-location')),
            )
            .data!;
        expect(label, isNot(contains('Address confirmed')));
        expect(
          label,
          contains(
            location == 'matching'
                ? 'Evaluation Store locality'
                : 'Store location unavailable',
          ),
        );
        expect(label, isNot(contains(product.origin)));
        final semantics = tester
            .widget<Semantics>(
              find.byKey(const ValueKey('buy-public-store-truth-s-eggs')),
            )
            .properties
            .label!;
        expect(semantics, isNot(contains('Address confirmed')));
        expect(tester.takeException(), isNull);
      });
    }

    for (final (aggregate, destination, scope) in [
      (false, BuyV2Destination.shop, 'Shop · all Stores'),
      (false, BuyV2Destination.wholesale, 'Wholesale · all suppliers'),
      (false, BuyV2Destination.medicine, 'Care · all pharmacies'),
      (true, BuyV2Destination.shop, 'All Cart items'),
    ]) {
      testWidgets('LF07 Cart scope $scope text $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 844);
        addTearDown(tester.view.reset);
        final session = BuyV2Session(core: BuySession());
        addTearDown(session.dispose);
        expect(session.addProduct('s-tomato'), isTrue);
        expect(session.addProduct('s-eggs'), isTrue);
        expect(session.addProduct('w-rice'), isTrue);
        final before = session.itemCount;
        final expected = aggregate
            ? session.cartTotal
            : session.totalForDestination(destination);
        var opened = 0;
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
              body: Align(
                alignment: Alignment.bottomRight,
                child: BuyV2StoreCartBar(
                  session: session,
                  destination: destination,
                  aggregate: aggregate,
                  onOpenCart: () => opened++,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(scope), findsOneWidget);
        final total = find.byKey(const ValueKey('buy-store-cart-total'));
        expect(tester.widget<Text>(total).data, buyV2Money(expected));
        expect(
          tester.renderObject<RenderParagraph>(total).didExceedMaxLines,
          isFalse,
        );
        final bar = find.byKey(const ValueKey('buy-store-cart-bar'));
        expect(tester.widget<Semantics>(bar).properties.label, contains(scope));
        await tester.tap(bar);
        await tester.pumpAndSettle();
        expect(opened, 1);
        expect(session.itemCount, before);
        expect(session.quantityFor('w-rice'), greaterThan(0));
        expect(tester.takeException(), isNull);
      });
    }
  }

  Finder scrollableWithin(Key ownerKey) => find.descendant(
    of: find.byKey(ownerKey),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
    ),
  );

  Widget app(
    BuyV2Session session, {
    BuyV2Destination initialDestination = BuyV2Destination.shop,
    double textScale = 1,
    EdgeInsets safePadding = EdgeInsets.zero,
    bool disableAnimations = false,
    bool captureCart = false,
    bool embeddedStore = false,
    BuyV2ScannerLauncher scannerLauncher = showBuyV2ProductScanner,
    BuyV2DeliveryArrivalSound? deliveryArrivalSound,
    VoidCallback? onOpenMool,
    VoidCallback? onOpenChat,
    BuyV2InvoiceDownloader? invoiceDownloader,
    AuthenticatedAccountIdentity? accountIdentity,
    bool accountAuthenticated = false,
    BuyV2PublishedOffersSource offersSource =
        const BuyV2CataloguePublishedOffersSource(),
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: safePadding,
            viewPadding: safePadding,
            disableAnimations: disableAnimations,
          ),
          child: captureCart
              ? RepaintBoundary(
                  key: const ValueKey('r66-cart-capture'),
                  child: child!,
                )
              : r66VisualCaptureRoot(child!),
        );
      },
      home: BuyV2Screen(
        session: session,
        embeddedStore: embeddedStore,
        initialDestination: initialDestination,
        accountIdentity: accountIdentity,
        accountAuthenticated: accountAuthenticated,
        scannerLauncher: scannerLauncher,
        deliveryArrivalSound: deliveryArrivalSound,
        onOpenMool: onOpenMool,
        onOpenChat: onOpenChat,
        invoiceDownloader: invoiceDownloader,
        offersSource: offersSource,
        onOpenMainAction: (action) {
          final uri = Uri.parse(action.route);
          if (uri.path != '/app/buy') return;
          switch (uri.queryParameters['sub']) {
            case 'wholesale':
              session.openDestination(BuyV2Destination.wholesale);
              return;
            case 'medicine':
              session.openDestination(BuyV2Destination.medicine);
              return;
            case 'orders':
              session.openOrders();
              return;
            default:
              session.openDestination(BuyV2Destination.shop);
              return;
          }
        },
      ),
    );
  }

  Future<void> captureReadability(WidgetTester tester, String label) async {
    if (!const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) return;
    final root = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('r66-cart-capture')),
    );
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    final previous = debugDisableShadows;
    debugDisableShadows = false;
    try {
      repaint(root);
      await captureR66Visual(tester, label);
    } finally {
      debugDisableShadows = previous;
      repaint(root);
      await tester.pump();
    }
  }

  void expectReadable(
    WidgetTester tester,
    Finder label, {
    Finder? action,
    bool wholeWords = false,
  }) {
    expect(label, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(label);
    final text = paragraph.text.toPlainText();
    final natural = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
    )..layout(maxWidth: paragraph.size.width);
    expect(paragraph.didExceedMaxLines, isFalse, reason: text);
    expect(
      paragraph.size.height + .5,
      greaterThanOrEqualTo(natural.height),
      reason: text,
    );
    natural.dispose();
    if (wholeWords) {
      for (final match in RegExp(r'\S+').allMatches(text)) {
        final word = match.group(0)!;
        final wordBoxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: match.start, extentOffset: match.end),
        );
        expect(
          wordBoxes.map((box) => box.top).toSet(),
          hasLength(1),
          reason: 'Painted word $word stays on one line in $text',
        );
        final measured = TextPainter(
          text: TextSpan(text: word, style: paragraph.text.style),
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
        )..layout();
        expect(
          measured.width,
          lessThanOrEqualTo(paragraph.size.width + .5),
          reason: 'Whole word $word in $text',
        );
        measured.dispose();
      }
    }
    if (action != null) {
      final bounds = tester.getRect(action);
      final content = tester.getRect(label);
      expect(content.top, greaterThanOrEqualTo(bounds.top - .5), reason: text);
      expect(
        content.bottom,
        lessThanOrEqualTo(bounds.bottom + .5),
        reason: text,
      );
      expect(bounds.height, greaterThanOrEqualTo(44));
      expect(action.hitTestable(), findsOneWidget);
    }
  }

  for (final width in [320.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('T14 premium mixed Store receipt extremes $width $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final session = _T14ReceiptLayoutSession();
        await tester.pumpWidget(app(session, textScale: scale));
        await tester.pumpAndSettle();
        expect(session.addProduct('s-tomato'), isTrue);
        expect(session.addProduct('w-notebook'), isTrue);
        final total = session.cartTotal;
        session.openCart();
        expect(session.openCheckout(), isTrue);
        await tester.pumpAndSettle();
        expect(find.text(_T14ReceiptLayoutSession.longStore), findsOneWidget);
        expect(find.text('Store details unavailable'), findsOneWidget);
        expect(find.text('Delivery estimate'), findsNWidgets(2));
        expect(find.textContaining('Minimum order 1 pack ·'), findsOneWidget);
        expect(find.textContaining('Minimum order 1 packs ·'), findsNothing);
        final groups = session.checkoutFulfilmentGroups;
        expect(groups, hasLength(2));
        for (final group in groups) {
          final toggle = find.byKey(
            ValueKey('buy-checkout-items-toggle-${group.key}'),
          );
          await tester.ensureVisible(toggle);
          await tester.pumpAndSettle();
          expect(toggle.hitTestable(), findsOneWidget);
          expect(tester.getSize(toggle).height, greaterThanOrEqualTo(44));
          expect(tester.widget<IconButton>(toggle).tooltip, 'Hide items');
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(tester.widget<IconButton>(toggle).tooltip, 'Show items');
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(session.cartTotal, total);
        }
        expect(session.checkoutLines.map((line) => line.product.id).toSet(), {
          's-tomato',
          'w-notebook',
        });
        await captureR66Visual(
          tester,
          't14-premium-mixed-receipt-$width-$scale',
        );
        session.openCart();
        expect(session.addProduct('w-rice'), isTrue);
        expect(session.openCheckout(), isTrue);
        await tester.pumpAndSettle();
        final pluralMinimum = find.textContaining('Minimum order 4 packs ·');
        expect(pluralMinimum, findsOneWidget);
        await tester.ensureVisible(pluralMinimum);
        await tester.pumpAndSettle();
        expect(pluralMinimum.hitTestable(), findsOneWidget);
        await captureR66Visual(
          tester,
          't14-premium-mixed-receipt-plural-$width-$scale',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        session.dispose();
      });
    }
  }

  Future<void> openFinanceCallbackFixture(WidgetTester tester, {
    required ValueNotifier<bool> owner,
    BuyV2FinanceCallbackSubmit? submit,
    String name = 'Host owner', String number = '+919876543210',
    Size viewport = const Size(360, 800), double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = viewport;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), home: Builder(
      builder: (context) => Scaffold(body: TextButton(onPressed: () =>
        showMoolBusinessFinanceSheet(context, scopeOwner: owner,
          isCurrent: () => owner.value, storeName: 'Host finance Store',
          origin: 'store', buyingStoreId: 'host-store', productIds: const ['host-sku'],
          contactName: name, callbackNumber: number, onRequestCallback: submit),
        child: const Text('Open finance'))))));
    await tester.tap(find.text('Open finance'));
    await tester.pumpAndSettle();
  }

  BuyV2FinanceCallbackReceipt financeReceipt(BuyV2FinanceCallbackRequest request,
      {String? requestId}) {
    final at = DateTime.utc(2026, 10, 24, 17);
    return BuyV2FinanceCallbackReceipt(requestId: requestId ?? request.requestId,
      reference: 'HOST-FIN-1', acceptedAt: at,
      callbackDueAt: at.add(const Duration(minutes: 30)));
  }

  test('FINANCE06 curated discovery has ten distinct product families', () {
    expect(BuyV2BusinessFinanceNeed.values, hasLength(10));
    expect(BuyV2BusinessFinanceNeed.values.map((v) => v.id).toSet(), hasLength(10));
    expect(BuyV2BusinessFinanceNeed.values.map((v) => v.label).toSet(), hasLength(10));
  });

  test('FINANCE06 legacy searches find one family without rewriting requests', () {
    final originalIds = BuyV2BusinessFinanceNeed.legacyLabels.keys.toList();
    for (final entry in BuyV2BusinessFinanceNeed.legacyLabels.entries) {
      final results = BuyV2BusinessFinanceNeed.values.where((need) =>
        need.searchText.contains(entry.value.toLowerCase()));
      expect(results.map((need) => need.id),
        [BuyV2BusinessFinanceNeed.legacyFamilies[entry.key]], reason: entry.value);
      expect(BuyV2BusinessFinanceNeed.labelFor(entry.key), entry.value);
    }
    expect(BuyV2BusinessFinanceNeed.values.where((need) =>
      need.searchText.contains('working capital')).map((need) => need.id), ['working-capital']);
    for (final (query, family) in [('inventory finance', 'purchase'), ('supply chain finance', 'invoice-finance')]) {
      expect(BuyV2BusinessFinanceNeed.values.where((need) =>
        need.searchText.contains(query)).map((need) => need.id), [family]);
    }
    final original = BuyV2FinanceCallbackRequest(requestId: 'FIN-${'c' * 32}',
      origin: 'store', buyingStoreId: 'host-store', contactName: 'Host owner',
      callbackNumber: '+919876543210', purposeIds: originalIds);
    expect(original.purposeIds, originalIds);
    expect(() => original.purposeIds.clear(), throwsUnsupportedError);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('FINANCE06 short enlarged viewport shows a complete first choice $width', (tester) async {
      final owner = ValueNotifier(true); addTearDown(owner.dispose);
      await openFinanceCallbackFixture(tester, owner: owner,
        viewport: Size(width, 568), scale: 2);
      final first = find.byKey(ValueKey('business-finance-purpose-${BuyV2BusinessFinanceNeed.values.first.label}'));
      final footer = find.byKey(const Key('business-finance-footer'));
      expect(tester.getRect(first).bottom, lessThanOrEqualTo(tester.getRect(footer).top + 1),
        reason: 'A short enlarged screen must show one complete choice before scrolling.');
      for (final key in ['business-finance-name', 'business-finance-number', 'business-finance-note']) {
        final field = find.byKey(Key(key));
        await tester.ensureVisible(field); await tester.pumpAndSettle();
        expect(field.hitTestable(), findsOneWidget);
      }
      expect(tester.getSize(find.byKey(const Key('business-finance-close'))).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    for (final scale in [1.0, 2.0]) {
      testWidgets('FINANCE06 compact header and footer retain usable form $width $scale', (tester) async {
        final owner = ValueNotifier(true); addTearDown(owner.dispose);
        await openFinanceCallbackFixture(tester, owner: owner,
          viewport: Size(width, 800), scale: scale);
        final body = find.byKey(const Key('business-finance-form-scroll'));
        final first = find.byKey(ValueKey('business-finance-purpose-${BuyV2BusinessFinanceNeed.values.first.label}'));
        expect(tester.getRect(first).top - tester.getRect(body).top,
          lessThanOrEqualTo(scale == 1 ? 200 : 260),
          reason: 'Context and service copy must not displace the product choices.');
        expect(first.hitTestable(), findsOneWidget);
        expect(find.text('For Host finance Store').hitTestable(), findsOneWidget);
        final footer = find.byKey(const Key('business-finance-footer'));
        expect(find.descendant(of: footer,
          matching: find.byKey(const Key('business-finance-unavailable'))), findsOneWidget);
        final button = find.byKey(const Key('business-finance-request'));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        final number = find.byKey(const Key('business-finance-number'));
        await tester.ensureVisible(number);
        await tester.showKeyboard(number);
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        final editable = find.descendant(of: number, matching: find.byType(EditableText));
        await tester.ensureVisible(editable); await tester.pumpAndSettle();
        expect(tester.getRect(editable).bottom, lessThanOrEqualTo(tester.getRect(footer).top + 1));
        expect(tester.getRect(button).bottom, lessThanOrEqualTo(800 - 280));
        tester.view.viewInsets = const FakeViewPadding();
        FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
        final note = find.byKey(const Key('business-finance-note'));
        await tester.ensureVisible(note); await tester.pumpAndSettle();
        expect(tester.getRect(note).bottom, lessThanOrEqualTo(tester.getRect(footer).top + 1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  test('FINANCE05 handoff retains immutable scope and rejects unrelated receipts', () {
    final purposes = ['working-capital', 'sales-invoice'], products = ['host-sku'];
    final request = BuyV2FinanceCallbackRequest(requestId: 'FIN-${'a' * 32}',
      origin: 'store', buyingStoreId: 'host-store', contactName: 'Host owner',
      callbackNumber: '+919876543210', purposeIds: purposes, productIds: products);
    purposes.clear(); products.clear();
    expect(request.purposeIds, ['working-capital', 'sales-invoice']);
    expect(request.productIds, ['host-sku']);
    expect(() => request.productIds.clear(), throwsUnsupportedError);
    expect(financeReceipt(request).matches(request), isTrue);
    expect(financeReceipt(request, requestId: 'FIN-${'b' * 32}').matches(request), isFalse);
    final at = DateTime.utc(2026, 10, 24, 17);
    expect(BuyV2FinanceCallbackReceipt(requestId: request.requestId, reference: 'HOST-FIN-1',
      acceptedAt: at, callbackDueAt: at.add(const Duration(minutes: 31))).matches(request), isFalse);
  });

  testWidgets('FINANCE05 validates then blocks duplicate taps until exact receipt', (tester) async {
    final owner = ValueNotifier(true); addTearDown(owner.dispose);
    final calls = <BuyV2FinanceCallbackRequest>[];
    final pending = Completer<BuyV2FinanceCallbackReceipt>();
    await openFinanceCallbackFixture(tester, owner: owner, name: '', number: '',
      submit: (request) { calls.add(request); return pending.future; });
    final button = find.byKey(const Key('business-finance-request'));
    await tester.tap(button); await tester.pumpAndSettle();
    expect(calls, isEmpty);
    for (final (key, value) in [
      ('business-finance-name', 'Host owner'),
      ('business-finance-number', '(+91) 98765-43210'),
    ]) {
      final field = find.byKey(Key(key));
      await tester.ensureVisible(field); await tester.enterText(field, value);
    }
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    await tester.tap(button); await tester.pumpAndSettle();
    expect(calls, hasLength(1));
    expect(calls.single.origin, 'store');
    expect(calls.single.buyingStoreId, 'host-store');
    expect(calls.single.productIds, ['host-sku']);
    expect(calls.single.callbackNumber, '+919876543210');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(tester.widget<TextFormField>(find.byKey(const Key('business-finance-name'))).enabled, isFalse);
    await tester.tap(button); await tester.pump();
    expect(calls, hasLength(1));
    pending.complete(financeReceipt(calls.single)); await tester.pumpAndSettle();
    expect(find.byKey(const Key('business-finance-confirmed')), findsOneWidget);
    expect(find.text('Reference: HOST-FIN-1'), findsOneWidget);
    expect(find.text('Loan approved'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('FINANCE05 unknown result retries the same frozen enquiry', (tester) async {
    final owner = ValueNotifier(true); addTearDown(owner.dispose);
    final calls = <BuyV2FinanceCallbackRequest>[];
    await openFinanceCallbackFixture(tester, owner: owner, submit: (request) async {
      calls.add(request);
      if (calls.length == 1) throw StateError('HOST lost response');
      return financeReceipt(request);
    });
    final button = find.byKey(const Key('business-finance-request'));
    await tester.tap(button); await tester.pumpAndSettle();
    expect(find.byKey(const Key('business-finance-submit-error')), findsOneWidget);
    expect(find.byKey(const Key('business-finance-confirmed')), findsNothing);
    expect(tester.widget<TextFormField>(find.byKey(const Key('business-finance-number'))).enabled, isFalse);
    await tester.tap(button); await tester.pumpAndSettle();
    expect(calls, hasLength(2));
    expect(identical(calls[0], calls[1]), isTrue);
    expect(find.byKey(const Key('business-finance-confirmed')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final ending in ['retired', 'disposed', 'wrong receipt']) {
    testWidgets('FINANCE05 late response cannot confirm $ending', (tester) async {
      final owner = ValueNotifier(true); addTearDown(owner.dispose);
      final pending = Completer<BuyV2FinanceCallbackReceipt>();
      late BuyV2FinanceCallbackRequest sent;
      await openFinanceCallbackFixture(tester, owner: owner,
        submit: (request) { sent = request; return pending.future; });
      await tester.tap(find.byKey(const Key('business-finance-request')));
      await tester.pumpAndSettle();
      if (ending == 'retired') { owner.value = false; owner.value = true; }
      if (ending == 'disposed') {
        await tester.tap(find.byKey(const Key('business-finance-close')));
        await tester.pumpAndSettle();
      }
      pending.complete(financeReceipt(sent,
        requestId: ending == 'wrong receipt' ? 'FIN-${'b' * 32}' : null));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('business-finance-confirmed')), findsNothing);
      if (ending == 'retired') {
        expect(find.byKey(const Key('business-finance-owner-changed')), findsOneWidget);
        expect(find.byKey(const Key('business-finance-buyer')), findsNothing);
      }
      if (ending == 'wrong receipt') expect(find.byKey(const Key('business-finance-submit-error')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('FINANCE04 referenced products are searchable and multi-select $scale', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final owner = ValueNotifier(true);
      addTearDown(owner.dispose);
      await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), home: Builder(
        builder: (context) => Scaffold(body: TextButton(onPressed: () =>
          showMoolBusinessFinanceSheet(context, scopeOwner: owner,
            isCurrent: () => owner.value, storeName: 'Host finance Store'),
          child: const Text('Open finance'))))));
      await tester.tap(find.text('Open finance'));
      await tester.pumpAndSettle();
      for (final label in const [
        'Purchase / dealer finance', 'Purchase order finance', 'Invoice / bill discounting',
        'Working capital (CC / OD)', 'Unsecured business loan',
        'Loan against property', 'Machinery / equipment finance',
        'Export finance', 'Import finance', 'Other finance requirement',
      ]) {
        expect(find.byKey(ValueKey('business-finance-purpose-$label')), findsOneWidget);
      }
      final search = find.byKey(const Key('business-finance-search'));
      await tester.ensureVisible(search);
      await tester.enterText(search, 'S2S');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('business-finance-purpose-Invoice / bill discounting')), findsOneWidget);
      expect(find.byKey(const ValueKey('business-finance-purpose-Working capital (CC / OD)')), findsNothing);
      await tester.enterText(search, 'no matching finance option');
      await tester.pumpAndSettle();
      expect(find.text('No finance options match your search.'), findsOneWidget);
      await tester.enterText(search, '');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_box_outlined), findsOneWidget);
      for (final label in ['Invoice / bill discounting', 'Working capital (CC / OD)']) {
        final choice = find.byKey(ValueKey('business-finance-purpose-$label'));
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
        expect(find.descendant(of: choice, matching: find.byIcon(Icons.check_box_outlined)), findsOneWidget);
      }
      expect(find.byIcon(Icons.check_box_outlined), findsNWidgets(3));
      expect(tester.widget<FilledButton>(find.byKey(const Key('business-finance-request'))).onPressed, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('FINANCE01 product and Cart share private contact form $scale', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 24);
      tester.view.padding = const FakeViewPadding(top: 41, bottom: 24);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      const identity = AuthenticatedAccountIdentity(firebaseUserId: 'finance-test-owner',
        firebaseProjectId: 'isolated-finance-test', displayName: 'Own buyer contact', phoneNumber: '+919876543210');
      await tester.pumpWidget(app(session, textScale: scale,
        safePadding: const EdgeInsets.only(top: 41, bottom: 24),
        accountIdentity: identity, accountAuthenticated: true));
      await tester.pumpAndSettle();
      expect(session.openProduct('w-tomato'), isTrue);
      expect(session.addProduct('w-tomato'), isTrue);
      await tester.pumpAndSettle();
      final quantity = session.itemCount, total = session.cartTotal;
      Future<void> revealFinance(Finder target, String page) async {
        await tester.scrollUntilVisible(target, 160, maxScrolls: 60,
          scrollable: find.descendant(of: find.byKey(PageStorageKey(page)),
            matching: find.byType(Scrollable)).first);
        await tester.pumpAndSettle();
      }
      final productEntry = find.byKey(const Key('buy-product-finance-open'));
      await revealFinance(productEntry, 'buy-product-w-tomato');
      expect(find.byKey(const Key('buy-product-finance')), findsOneWidget);
      await tester.tap(productEntry);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('business-finance-sheet')), findsOneWidget);
      expect(tester.widget<TextFormField>(find.byKey(const Key('business-finance-name'))).controller!.text,
        'Own buyer contact');
      expect(tester.widget<TextFormField>(find.byKey(const Key('business-finance-number'))).controller!.text,
        '+919876543210');
      expect(find.byKey(const Key('business-finance-purpose-Invoice / bill discounting')), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('business-finance-request'))).onPressed, isNull);
      final requestBounds = tester.getRect(find.byKey(const Key('business-finance-request')));
      expect(requestBounds.height, greaterThanOrEqualTo(48));
      expect(requestBounds.bottom, lessThanOrEqualTo(700 - 41 - 24),
        reason: 'The whole action stays inside Android exported accessibility bounds.');
      for (final (key, label) in [
        ('business-finance-name', 'Contact name'),
        ('business-finance-number', 'Callback number'),
        ('business-finance-note', 'Note (optional)'),
      ]) {
        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.showKeyboard(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        final field = find.bySemanticsLabel(RegExp(RegExp.escape(label)));
        expect(field, findsOneWidget);
        expect(tester.getSemantics(field).getSemanticsData().hasAction(SemanticsAction.setText), isTrue,
          reason: 'Named fields keep their accessible editing action.');
      }
      await tester.ensureVisible(find.byKey(const Key('business-finance-number')));
      await tester.enterText(find.byKey(const Key('business-finance-number')), 'bad');
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid callback number'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('business-finance-number')), '+919111111111');
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid callback number'), findsNothing);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.tap(find.byKey(const Key('business-finance-close')));
      await tester.pumpAndSettle();
      expect(session.itemCount, quantity);
      expect(session.cartTotal, total);
      session.openCart(scope: BuyV2CartScope.wholesale);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-cart-scope-bar')), findsOneWidget,
        reason: 'Public Cart retains its existing Shop/Wholesale basket controls.');
      final cartEntry = find.byKey(const Key('buy-cart-finance-open'));
      await revealFinance(cartEntry, 'buy-cart-wholesale');
      expect(cartEntry, findsOneWidget);
      expect(find.byKey(const Key('buy-product-finance')), findsNothing);
      await tester.tap(cartEntry);
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(find.byKey(const Key('business-finance-number'))).controller!.text,
        '+919876543210', reason: 'An unsent alternate number is not persisted.');
      const otherIdentity = AuthenticatedAccountIdentity(firebaseUserId: 'other-finance-owner',
        firebaseProjectId: 'isolated-finance-test', displayName: 'Other buyer');
      await tester.pumpWidget(app(session, textScale: scale,
        safePadding: const EdgeInsets.only(top: 41, bottom: 24),
        accountIdentity: otherIdentity, accountAuthenticated: true));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('business-finance-owner-changed')), findsOneWidget);
      expect(find.byKey(const Key('business-finance-number')), findsNothing);
      await tester.pumpWidget(app(session, textScale: scale,
        safePadding: const EdgeInsets.only(top: 41, bottom: 24),
        accountIdentity: identity, accountAuthenticated: true));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('business-finance-owner-changed')), findsOneWidget,
        reason: 'An account return cannot revive a retired contact draft.');
      expect(session.itemCount, quantity);
      expect(session.cartTotal, total);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('PRODUCTSTATUS delivery cues reflect current source state $scale', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final (mode, label) in [
        ('missing', 'Delivery schedule unavailable'),
        ('fresh', 'Delivery in 12 min'),
        ('stale', 'Check delivery availability'),
        ('checking', 'Checking delivery time'),
        ('closed', 'Check delivery availability'),
      ]) {
        final core = BuySession();
        final session = BuyV2Session(core: core, productFactsAdapter: _ProductDeliveryCueFacts(mode));
        try {
          await tester.pumpWidget(app(session, textScale: scale));
          await tester.pumpAndSettle();
          expect(session.openProduct('w-tomato'), isTrue);
          await tester.pumpAndSettle();
          final copies = find.text(label);
          final productScroll = find.descendant(
            of: find.byKey(const PageStorageKey('buy-product-w-tomato')),
            matching: find.byType(Scrollable)).first;
          await tester.scrollUntilVisible(copies.first, 160, maxScrolls: 20, scrollable: productScroll);
          await tester.pumpAndSettle();
          expect(copies, findsWidgets, reason: mode);
          final colours = tester.widgetList<Text>(copies).map((text) => text.style?.color).toList();
          expect(colours, contains(mode == 'fresh' ? BuyV2Colors.green : BuyV2Colors.muted), reason: mode);
          if (mode != 'fresh') expect(colours, isNot(contains(BuyV2Colors.green)), reason: mode);
          expect(session.cartLines, isEmpty);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          session.dispose(); core.dispose();
        }
      }
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'T14 public Product and Cart missing schedule stays unavailable $scale',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(app(session, textScale: scale));
        await tester.pumpAndSettle();
        expect(session.openProduct('w-tomato'), isTrue);
        await tester.pumpAndSettle();
        void checkPlaceholder([
          String expected = 'Delivery schedule unavailable',
        ]) {
          expect(
            find.text(expected),
            findsWidgets,
          );
          expect(find.textContaining('after Store acceptance'), findsNothing);
          expect(
            find.text('Delivery time confirmed at checkout'),
            findsNothing,
          );
        }

        checkPlaceholder();
        for (final (key, label) in [
          ('buy-product-price-details-w-tomato', 'Price details'),
          ('buy-product-change-address-w-tomato', 'Change'),
        ]) {
          final caption = find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.text(label),
          );
          expect(caption, findsOneWidget);
          expect(
            tester
                .renderObject<RenderParagraph>(caption)
                .text
                .style
                ?.fontFamily,
            'Inter',
            reason: 'Public Product actions retain the app font.',
          );
        }
        await captureR66Visual(tester, 't14-public-placeholder-product-$scale');
        expect(session.addProduct('w-tomato'), isTrue);
        final quantities = session.itemCount;
        final total = session.cartTotal;
        session.openCart(scope: BuyV2CartScope.all);
        await tester.pumpAndSettle();
        checkPlaceholder();
        await captureR66Visual(tester, 't14-public-placeholder-cart-$scale');
        final checkout = find.widgetWithText(FilledButton, 'Checkout');
        await tester.ensureVisible(checkout);
        await tester.tap(checkout);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.checkout);
        checkPlaceholder();
        await captureR66Visual(
          tester,
          't14-public-placeholder-checkout-$scale',
        );
        expect(session.itemCount, quantities);
        expect(session.cartTotal, total);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('T14 premium public journey preserves Cart actions $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: scale));
      await tester.pumpAndSettle();
      BuyV2ThemeScope scope() =>
          tester.widget<BuyV2ThemeScope>(find.byType(BuyV2ThemeScope));
      expect(scope().refinedCommerce, isTrue);
      await captureR66Visual(tester, 't14-premium-discovery-$scale');
      expect(session.openProduct('s-tomato'), isTrue);
      await tester.pumpAndSettle();
      expect(scope().refinedCommerce, isTrue);
      expect(session.addProduct('s-tomato'), isTrue);
      await captureR66Visual(tester, 't14-premium-product-$scale');
      final quantity = session.itemCount;
      final total = session.cartTotal;
      session.openCart();
      await tester.pumpAndSettle();
      expect(scope().refinedCommerce, isTrue);
      await captureR66Visual(tester, 't14-premium-cart-$scale');
      final checkout = find.widgetWithText(FilledButton, 'Checkout');
      await tester.ensureVisible(checkout);
      await tester.tap(checkout);
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.checkout);
      expect(scope().refinedCommerce, isTrue);
      expect(session.itemCount, quantity);
      expect(session.cartTotal, total);
      final invoiceChange = find.descendant(
        of: find.byKey(const ValueKey('buy-invoice-change')),
        matching: find.text('Change'),
      );
      expect(invoiceChange, findsOneWidget);
      expect(find.byKey(const ValueKey('buy-checkout-heading')), findsNothing);
      final cartReturn = find.byKey(const ValueKey('buy-checkout-return-cart'));
      expect(cartReturn, findsOneWidget);
      expect(
        tester
            .renderObject<RenderParagraph>(invoiceChange)
            .text
            .style
            ?.fontFamily,
        'Inter',
        reason:
            'Public invoice action retains the app font instead of platform fallback.',
      );
      await captureR66Visual(tester, 't14-premium-checkout-$scale');
      await tester.ensureVisible(cartReturn);
      await tester.tap(cartReturn);
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.cart);
      expect(session.itemCount, quantity);
      expect(session.cartTotal, total);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    });

    testWidgets('T14 premium treatment leaves Care unchanged $scale', (
      tester,
    ) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(
        app(
          session,
          initialDestination: BuyV2Destination.medicine,
          textScale: scale,
        ),
      );
      await tester.pumpAndSettle();
      session.openCart();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BuyV2ThemeScope>(find.byType(BuyV2ThemeScope))
            .refinedCommerce,
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    });

    testWidgets(
      'T14 premium excludes Profile Assist and embedded Store $scale',
      (tester) async {
        final session = BuyV2Session(core: BuySession());
        await tester.pumpWidget(app(session, textScale: scale));
        await tester.pumpAndSettle();
        for (final open in [session.openAccount, session.openAssist]) {
          open();
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<BuyV2ThemeScope>(find.byType(BuyV2ThemeScope))
                .refinedCommerce,
            isFalse,
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
        session.dispose();

        final store = BuyV2Session(core: BuySession());
        await tester.pumpWidget(
          app(store, textScale: scale, embeddedStore: true),
        );
        await tester.pumpAndSettle();
        expect(store.addProduct('w-tomato'), isTrue);
        store.openCart();
        await tester.pumpAndSettle();
        expect(find.text('Delivery time confirmed at checkout'), findsWidgets);
        expect(
          find.text('Delivery schedule unavailable'),
          findsNothing,
        );
        expect(
          tester
              .widget<BuyV2ThemeScope>(find.byType(BuyV2ThemeScope))
              .refinedCommerce,
          isFalse,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        store.dispose();
      },
    );

    testWidgets(
      'compact Offers radio popup visible options select dismiss $scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.padding = const FakeViewPadding(bottom: 34);
        addTearDown(tester.view.resetPadding);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        session.addProduct('s-tomato');
        final total = session.cartTotal;
        await tester.pumpWidget(
          app(
            session,
            textScale: scale,
            safePadding: const EdgeInsets.only(bottom: 34),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
        await tester.pumpAndSettle();
        final filter = find.byKey(const ValueKey('buy-offers-filter'));
        await tester.tap(filter);
        await tester.pumpAndSettle();
        final sheet = find.byKey(const ValueKey('buy-offers-filter-sheet'));
        final row = find.byKey(const ValueKey('buy-offers-publisher-options'));
        expect(tester.getSize(sheet).width, 360);
        expect(tester.getSize(sheet).height, lessThan(640));
        expect(tester.widget<Wrap>(row).direction, Axis.horizontal);
        expect(
          find.descendant(of: sheet, matching: find.byType(ChoiceChip)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.byIcon(Icons.radio_button_checked),
          ),
          findsOneWidget,
        );
        final all = find.byKey(const ValueKey('buy-offer-filter-all'));
        final allLabel = find.descendant(
          of: all,
          matching: find.text('All suppliers'),
        );
        expect(
          tester.getSize(all).width - tester.getSize(allLabel).width,
          lessThanOrEqualTo(34),
        );
        expect(tester.getSize(all).height, greaterThanOrEqualTo(44));
        for (final type in [
          'all',
          'manufacturer',
          'wholesaler',
          'retailer',
          'moolSocial',
        ]) {
          final option = find.byKey(ValueKey('buy-offer-filter-$type'));
          expect(option.hitTestable(), findsOneWidget);
          expect(tester.getRect(option).bottom, lessThanOrEqualTo(766));
        }
        final mool = find.byKey(const ValueKey('buy-offer-filter-moolSocial'));
        await tester.ensureVisible(mool);
        await tester.pumpAndSettle();
        expect(mool.hitTestable(), findsOneWidget);
        await tester.tap(mool);
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        expect(session.featuredOffersMoolSocial, isTrue);
        await tester.tap(filter);
        await tester.pumpAndSettle();
        expect(mool.hitTestable(), findsOneWidget);
        expect(
          find.descendant(
            of: mool,
            matching: find.byIcon(Icons.radio_button_checked),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('buy-offers-filter-close')));
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        expect(session.featuredOffersMoolSocial, isTrue);
        expect(session.cartTotal, total);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('quiet current selection across public catalogue $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.addProduct('s-tomato');
      final total = session.cartTotal;
      await tester.pumpWidget(app(session, textScale: scale));
      await tester.pumpAndSettle();
      Finder control(String key) => find.byKey(ValueKey(key));
      void checkCue(String active, String inactive) {
        final owner = control(active);
        final dot = find.descendant(
          of: owner,
          matching: find.byKey(const ValueKey('buy-current-selection-surface')),
        );
        expect(dot, findsOneWidget);
        expect(tester.getRect(owner).contains(tester.getCenter(dot)), isTrue);
        expect(
          find.descendant(
            of: control(inactive),
            matching: find.byKey(
              const ValueKey('buy-current-selection-surface'),
            ),
          ),
          findsNothing,
        );
        expect(
          tester
              .getSemantics(
                active.startsWith('buy-offer-group-')
                    ? find
                          .ancestor(
                            of: owner,
                            matching: find.byType(MergeSemantics),
                          )
                          .first
                    : owner,
              )
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        expect(
          tester
              .getSemantics(
                inactive.startsWith('buy-offer-group-')
                    ? find
                          .ancestor(
                            of: control(inactive),
                            matching: find.byType(MergeSemantics),
                          )
                          .first
                    : control(inactive),
              )
              .flagsCollection
              .isSelected,
          Tristate.isFalse,
        );
      }

      checkCue('buy-shop-sale-type-quick', 'buy-shop-sale-type-courier');
      await tester.tap(control('buy-shop-sale-type-courier'));
      await tester.pumpAndSettle();
      checkCue('buy-shop-sale-type-courier', 'buy-shop-sale-type-quick');
      final category = session.categories.firstWhere((c) => c.id != 'all').id;
      BoxDecoration? categoryDecoration() =>
          tester
                  .widget<AnimatedContainer>(
                    find.descendant(
                      of: control('buy-category-picker'),
                      matching: find.byType(AnimatedContainer),
                    ),
                  )
                  .decoration
              as BoxDecoration?;
      session.chooseCategory(category);
      await tester.pumpAndSettle();
      expect(categoryDecoration()?.boxShadow, isNotEmpty);
      expect(categoryDecoration()?.border, isNull);
      session.chooseCategory('all');
      await tester.pumpAndSettle();
      expect(categoryDecoration(), isNull);
      await tester.tap(control('buy-local-tab-wholesale'));
      await tester.pumpAndSettle();
      checkCue(
        'buy-wholesale-sale-type-wholesale',
        'buy-wholesale-sale-type-bulk',
      );
      await tester.tap(control('buy-wholesale-sale-type-bulk'));
      await tester.pumpAndSettle();
      checkCue(
        'buy-wholesale-sale-type-bulk',
        'buy-wholesale-sale-type-wholesale',
      );
      await tester.tap(control('buy-local-tab-offers'));
      await tester.pumpAndSettle();
      checkCue('buy-offer-group-suppliers', 'buy-offer-group-moolsocial');
      await tester.tap(control('buy-offer-group-moolsocial'));
      await tester.pumpAndSettle();
      checkCue('buy-offer-group-moolsocial', 'buy-offer-group-suppliers');
      semantics.dispose();
      expect(session.cartTotal, total);
      expect(tester.takeException(), isNull);
    });
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    testWidgets(
      'R669 forwarded catalogue empty and populated 320x568 2x ${destination.name}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        session.openDestination(destination);
        final retainedProduct = session.catalogueSaleTypeProducts.first;
        expect(session.addProduct(retainedProduct.id), isTrue);
        final retainedQuantity = session.quantityFor(retainedProduct.id);
        session.updateQuery('unmatched-catalogue-query');
        await tester.pumpWidget(
          app(session, initialDestination: destination, textScale: 2),
        );
        await tester.pumpAndSettle();
        expect(session.destination, destination);
        expect(find.text('No matching products'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final clear = find.widgetWithText(TextButton, 'Clear search');
        await tester.ensureVisible(clear);
        await tester.pumpAndSettle();
        expect(clear.hitTestable(), findsOneWidget);
        await captureR66Visual(
          tester,
          'r669-forwarded-${destination.name}-empty',
        );
        await tester.tap(clear);
        await tester.pumpAndSettle();
        expect(session.query, isEmpty);
        expect(session.catalogueSaleTypeProducts, isNotEmpty);
        final catalogueScroll = find
            .descendant(
              of: find.byType(CustomScrollView).first,
              matching: find.byType(Scrollable),
            )
            .first;
        for (
          var step = 0;
          step < 100 && find.byType(BuyV2ProductCard).evaluate().isEmpty;
          step++
        ) {
          final touchPoint =
              const [
                Alignment(-.85, 0),
                Alignment(.85, 0),
                Alignment(-.85, -.5),
                Alignment(.85, -.5),
              ].firstWhere(
                (point) => catalogueScroll
                    .hitTestable(at: point)
                    .evaluate()
                    .isNotEmpty,
              );
          await tester.dragFrom(
            touchPoint.withinRect(tester.getRect(catalogueScroll)),
            const Offset(0, -160),
          );
          await tester.pumpAndSettle();
        }
        await tester.pumpAndSettle();
        expect(find.byType(BuyV2ProductCard), findsWidgets);
        expect(tester.takeException(), isNull);
        final card = find.byType(BuyV2ProductCard).first;
        final product = tester.widget<BuyV2ProductCard>(card).product;
        final title = find
            .descendant(of: card, matching: find.text(product.title))
            .first;
        await tester.ensureVisible(title);
        await tester.pumpAndSettle();
        expect(title.hitTestable(), findsOneWidget);
        await captureR66Visual(
          tester,
          'r669-forwarded-${destination.name}-populated',
        );
        await tester.tap(title);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(session.selectedProduct?.id, product.id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.catalogue);
        expect(session.destination, destination);
        expect(session.quantityFor(retainedProduct.id), retainedQuantity);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [320.0, 390.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final channel in BuyV2OfferClass.values) {
        testWidgets('PROFILE-F06 original recipient $width $scale channel=${channel.name}', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core)..chooseAddress('work');
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          final original = session.selectedAddress;
          final wholesale = channel != BuyV2OfferClass.retail;
          final productId = switch (channel) {
            BuyV2OfferClass.retail => 's-tomato',
            BuyV2OfferClass.wholesale => 'w-notebook',
            BuyV2OfferClass.bulk => 'w-rice',
          };
          if (channel == BuyV2OfferClass.bulk) {
            session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
          }
          expect(session.addProduct(productId), isTrue);
          session.openCart(scope: wholesale ? BuyV2CartScope.wholesale : BuyV2CartScope.shop);
          expect(session.openCheckout(), isTrue);
          // Isolated host order fixture only; no runtime financial outcome.
          expect(session.confirmOrder(), isTrue);
          final order = session.confirmedOrders.single;
          expect(order.lines.single.product.offerClass, channel);
          session.chooseAddress('home');
          await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 24, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
                disableAnimations: false,
              ), child: child!),
            home: BuyV2Screen(session: session,
              initialDestination: order.destination,
              initialView: BuyV2View.tracking, orderId: order.id),
          ));
          await tester.pumpAndSettle();
          final action = find.byKey(const ValueKey('buy-tracking-address'));
          await tester.scrollUntilVisible(action, 160,
            scrollable: scrollableWithin(PageStorageKey('buy-tracking-${order.id}')).first);
          await Scrollable.ensureVisible(tester.element(action), alignment: .5);
          await tester.pumpAndSettle();
          expect(action.hitTestable(), findsOneWidget);
          await tester.tap(action);
          await tester.pumpAndSettle();
          final facts = find.byKey(const ValueKey('buy-order-delivery-facts'));
          expect(facts, findsOneWidget);
          expect(find.descendant(of: facts, matching: find.text(order.recipient!)), findsOneWidget);
          expect(find.descendant(of: facts, matching: find.text('${original.line}, ${original.area} ${original.pinCode}')), findsOneWidget);
          expect(find.descendant(of: facts, matching: find.textContaining(session.selectedAddress.line)), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final size in [const Size(320, 844), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}-$scale';
      for (final delivered in [false, true]) {
        testWidgets('R5 readability tracking $delivered $label', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          session.addProduct('s-milk');
          final originalTotal = session.cartTotal;
          await tester.pumpWidget(
            app(
              session,
              textScale: scale,
              safePadding: const EdgeInsets.only(top: 24, bottom: 34),
              disableAnimations: true,
            ),
          );
          await tester.pumpAndSettle();
          final order = session.orders.firstWhere(
            (candidate) =>
                candidate.destination == BuyV2Destination.shop &&
                (candidate.status == BuyV2OrderStatus.delivered) == delivered,
          );
          expect(session.openTracking(order.id), isTrue);
          await tester.pumpAndSettle();
          final tracking = find.byKey(
            PageStorageKey('buy-tracking-${order.id}'),
          );
          final scroll = scrollableWithin(
            PageStorageKey('buy-tracking-${order.id}'),
          ).first;
          final address = find.byKey(const ValueKey('buy-tracking-address'));
          await tester.scrollUntilVisible(address, 160, scrollable: scroll);
          await Scrollable.ensureVisible(
            tester.element(address),
            alignment: .5,
          );
          await tester.pumpAndSettle();
          expectReadable(
            tester,
            find.descendant(of: address, matching: find.text('Address')),
            action: address,
            wholeWords: true,
          );
          await captureReadability(
            tester,
            'r5-readable-tracking-$delivered-$label-actions',
          );
          await tester.tap(address);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-order-delivery-sheet')),
            findsOneWidget,
          );
          expect(session.selectedOrderId, order.id);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.tracking);
          final items = find.descendant(
            of: tracking,
            matching: find.text('Items'),
          );
          await Scrollable.ensureVisible(tester.element(items), alignment: .5);
          await tester.pumpAndSettle();
          expectReadable(tester, items, wholeWords: true);
          await tester.tap(items);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.orderItems);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.selectedOrderId, order.id);
          final manage = find.byKey(
            ValueKey('buy-tracking-manage-order-${order.id}'),
          );
          await tester.scrollUntilVisible(manage, 160, scrollable: scroll);
          await Scrollable.ensureVisible(tester.element(manage), alignment: .5);
          await tester.pumpAndSettle();
          expectReadable(
            tester,
            find.descendant(
              of: manage,
              matching: find.text(
                delivered ? 'Return, replace or refund' : 'Manage order',
              ),
            ),
            action: manage,
            wholeWords: true,
          );
          await captureReadability(
            tester,
            'r5-readable-tracking-$delivered-$label-manage',
          );
          await tester.tap(manage);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-order-resolution-sheet')),
            findsOneWidget,
          );
          final close = find.byTooltip('Close order options');
          expect(close, findsOneWidget);
          expect(tester.getSize(close).shortestSide, greaterThanOrEqualTo(44));
          await tester.tap(close);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-order-resolution-sheet')),
            findsNothing,
          );
          expect(session.view, BuyV2View.tracking);
          expect(session.selectedOrderId, order.id);
          expect(session.quantityFor('s-milk'), 1);
          expect(session.cartTotal, originalTotal);
          await tester.tap(manage);
          await tester.pumpAndSettle();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.tracking);
          expect(session.selectedOrderId, order.id);
          expect(session.quantityFor('s-milk'), 1);
          expect(session.cartTotal, originalTotal);
          expect(tester.takeException(), isNull);
        });
      }

      for (final id in ['s-milk', 'w-oil-10l', 'm-paracetamol-500']) {
        testWidgets('R5 readability cart $id $label', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await tester.pumpWidget(
            app(
              session,
              textScale: scale,
              safePadding: const EdgeInsets.only(top: 24, bottom: 34),
              disableAnimations: true,
            ),
          );
          await tester.pumpAndSettle();
          session.addProduct(id);
          session.openCart();
          await tester.pumpAndSettle();
          final product = session.product(id);
          final total = session.cartTotal;
          final quantity = session.quantityFor(id);
          final summary = find.byKey(ValueKey('buy-cart-product-summary-$id'));
          if (summary.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              summary,
              100,
              scrollable: find
                  .descendant(
                    of: find.byKey(
                      PageStorageKey('buy-cart-${session.cartScope.name}'),
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.pumpAndSettle();
          }
          final fields = find.descendant(
            of: summary,
            matching: find.byType(Text),
          );
          expect(fields, findsWidgets);
          for (final field in fields.evaluate().toList()) {
            final target = find.byWidget(field.widget);
            await Scrollable.ensureVisible(field, alignment: .5);
            await tester.pumpAndSettle();
            expectReadable(tester, target, wholeWords: true);
          }
          final detail = find.descendant(
            of: summary,
            matching: find.text('${product.variant} · ${product.pack}'),
          );
          await Scrollable.ensureVisible(tester.element(detail), alignment: .5);
          await tester.pumpAndSettle();
          await captureReadability(
            tester,
            'r5-readable-cart-$id-$label-detail',
          );
          final promise = fields.last;
          await Scrollable.ensureVisible(
            tester.element(promise),
            alignment: .5,
          );
          await tester.pumpAndSettle();
          expect(promise.hitTestable(), findsOneWidget);
          await captureReadability(
            tester,
            'r5-readable-cart-$id-$label-promise',
          );
          await tester.tap(promise);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.product);
          expect(session.selectedProductId, id);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          expect(session.quantityFor(id), quantity);
          expect(session.cartTotal, total);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('R5 readability prescription $label', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(
          app(
            session,
            textScale: scale,
            safePadding: const EdgeInsets.only(top: 24, bottom: 34),
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();
        session.openDestination(BuyV2Destination.medicine);
        session.submitSearch('Metformin');
        await tester.pumpAndSettle();
        final action = find.byKey(const ValueKey('buy-add-m-metformin-500'));
        await Scrollable.ensureVisible(tester.element(action), alignment: .5);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        await tester.tap(action);
        await tester.pumpAndSettle();
        final title = find.byKey(
          const ValueKey('buy-prescription-sheet-title'),
        );
        expectReadable(tester, title, wholeWords: true);
        final close = find.byKey(const ValueKey('buy-prescription-close'));
        expect(close.hitTestable(), findsOneWidget);
        expect(tester.getSize(close).height, greaterThanOrEqualTo(44));
        await captureReadability(
          tester,
          'r5-readable-prescription-$label-heading',
        );
        final explanation = find.textContaining(
          'Pharmacist review is still required before payment.',
        );
        await Scrollable.ensureVisible(
          tester.element(explanation),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        expectReadable(tester, explanation);
        await captureReadability(
          tester,
          'r5-readable-prescription-$label-explanation',
        );
        if (scale == 2) {
          await tester.binding.handlePopRoute();
        } else {
          await Scrollable.ensureVisible(tester.element(close), alignment: .5);
          await tester.pumpAndSettle();
          await tester.tap(close);
        }
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-prescription-sheet-route')),
          findsNothing,
        );
        expect(session.prescriptionAttached, isFalse);
        expect(session.quantityFor('m-metformin-500'), 0);
        expect(session.destination, BuyV2Destination.medicine);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final owner in ['hint', 'history']) {
    testWidgets('R5 search 029A enlarged $owner is fully painted', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      session.submitSearch('tomato');
      session.updateQuery('');
      await tester.pumpWidget(app(session, textScale: 2));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('buy-search-field'));
      final text = owner == 'hint'
          ? tester.widget<TextField>(field).decoration!.hintText!
          : 'Recent searches';
      final paintedText = find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == text,
      );
      expect(paintedText, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(paintedText);
      final painter = TextPainter(
        text: paragraph.text,
        textDirection: paragraph.textDirection,
        textScaler: paragraph.textScaler,
        locale: paragraph.locale,
        textHeightBehavior: paragraph.textHeightBehavior,
      )..layout(maxWidth: paragraph.size.width);
      final requiredHeight = painter.height;
      painter.dispose();
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(
        paragraph.size.height + .1,
        greaterThanOrEqualTo(requiredHeight),
        reason: '$owner must paint every line at the actual Inter text scale',
      );
      final textRect = tester.getRect(paintedText);
      if (owner == 'history') {
        expect(
          textRect.bottom,
          lessThanOrEqualTo(
            tester
                .getRect(find.byKey(const ValueKey('buy-recent-search-0')))
                .top,
          ),
          reason: 'History heading cannot overlap the first search row',
        );
      } else {
        expect(tester.getRect(field).contains(textRect.topLeft), isTrue);
        expect(
          tester.getRect(field).bottom,
          greaterThanOrEqualTo(textRect.bottom),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  void expectSearchTextPainted(WidgetTester tester, Finder scope, String text) {
    final painted = find.descendant(
      of: scope,
      matching: find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == text,
      ),
    );
    expect(painted, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(painted);
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      locale: paragraph.locale,
      textHeightBehavior: paragraph.textHeightBehavior,
    )..layout(maxWidth: paragraph.size.width);
    final height = painter.height;
    painter.dispose();
    expect(paragraph.didExceedMaxLines, isFalse, reason: text);
    expect(
      paragraph.size.height + .1,
      greaterThanOrEqualTo(height),
      reason: text,
    );
    final bounds = tester.getRect(painted);
    final owner = tester.getRect(scope);
    expect(bounds.left + .1, greaterThanOrEqualTo(owner.left), reason: text);
    expect(bounds.right, lessThanOrEqualTo(owner.right + .1), reason: text);
    expect(bounds.top + .1, greaterThanOrEqualTo(owner.top), reason: text);
    expect(bounds.bottom, lessThanOrEqualTo(owner.bottom + .1), reason: text);
  }

  for (final size in [
    const Size(320, 780),
    const Size(360, 800),
    const Size(430, 932),
    const Size(640, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      final label =
          '${size.width.toInt()}x${size.height.toInt()}-${scale.toInt()}';
      testWidgets('R5 search 029A keyboard and history actions $label', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        session.submitSearch('tomato');
        session.submitSearch('milk');
        session.updateQuery('');
        await tester.pumpWidget(
          app(
            session,
            textScale: scale,
            safePadding: const EdgeInsets.only(top: 24, bottom: 24),
          ),
        );
        await tester.pumpAndSettle();
        final control = find.byKey(const ValueKey('buy-search-control'));
        final field = find.byKey(const ValueKey('buy-search-field'));
        final history = find.byKey(
          const ValueKey('buy-search-suggestion-list'),
        );
        final finish = find.byKey(const ValueKey('buy-search-close'));
        final clear = find.byKey(const ValueKey('buy-search-clear'));
        final recentClear = find.byKey(
          const ValueKey('buy-recent-searches-clear'),
        );
        final firstRecent = find.byKey(const ValueKey('buy-recent-search-0'));
        final restingText = tester
            .widget<Text>(
              find.descendant(of: control, matching: find.byType(Text)),
            )
            .data!;
        expectSearchTextPainted(tester, control, restingText);
        await captureR66Visual(tester, 'r5-search-$label-closed');
        await tester.tap(control);
        await tester.pumpAndSettle();
        void expectBlankSearch() {
          expectSearchTextPainted(
            tester,
            field,
            tester.widget<TextField>(field).decoration!.hintText!,
          );
          expectSearchTextPainted(tester, history, 'Recent searches');
          expect(
            tester.getRect(find.text('Recent searches')).bottom,
            lessThanOrEqualTo(tester.getRect(firstRecent).top),
          );
          for (final action in [finish, recentClear, firstRecent]) {
            expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
            expect(tester.getSize(action).width, greaterThanOrEqualTo(44));
          }
        }

        expectBlankSearch();
        await captureR66Visual(tester, 'r5-search-$label-history');
        final keyboardHeight = size.height < 400 ? 140.0 : 260.0;
        tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
        await tester.pumpAndSettle();
        expectBlankSearch();
        expect(
          tester.getRect(field).bottom,
          lessThanOrEqualTo(size.height - keyboardHeight),
        );
        await captureR66Visual(tester, 'r5-search-$label-keyboard-inset');
        await tester.ensureVisible(firstRecent);
        await tester.pumpAndSettle();
        await tester.tap(firstRecent);
        await tester.pumpAndSettle();
        expect(session.query, 'milk');
        if (size.width > size.height) {
          // The landscape catalogue scrolls its header to give results space.
          // Bring the same mounted field back before editing the next query.
          final mountedField = find.byKey(
            const ValueKey('buy-search-field'),
            skipOffstage: false,
          );
          expect(mountedField, findsOneWidget);
          await tester.ensureVisible(mountedField);
          await tester.pumpAndSettle();
        }
        expect(tester.widget<TextField>(field).controller!.text, 'milk');
        await tester.tap(clear);
        await tester.pumpAndSettle();
        await tester.tap(recentClear);
        await tester.pumpAndSettle();
        expect(session.recentSearchesFor(BuyV2Destination.shop), isEmpty);
        expect(find.text('Recent searches'), findsNothing);
        await captureR66Visual(tester, 'r5-search-$label-empty-history');
        await tester.enterText(field, 'tomato');
        await tester.pumpAndSettle();
        expect(session.visibleProducts, isNotEmpty);
        await tester.tap(finish);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(session.query, 'tomato');
        expect(
          session.recentSearchesFor(BuyV2Destination.shop).first,
          'tomato',
        );
        expect(field, findsNothing);
        await captureR66Visual(tester, 'r5-search-$label-results');
        await tester.tap(control);
        await tester.pumpAndSettle();
        await tester.tap(clear);
        await tester.pumpAndSettle();
        await tester.tap(finish);
        await tester.pumpAndSettle();
        expect(session.query, isEmpty);
        expect(session.itemCount, 0);
        for (final destination in BuyV2Destination.values) {
          session.openDestination(destination);
          await tester.pumpAndSettle();
          final hint = tester
              .widget<Text>(
                find.descendant(of: control, matching: find.byType(Text)),
              )
              .data!;
          expectSearchTextPainted(tester, control, hint);
          await tester.tap(control);
          await tester.pumpAndSettle();
          expectSearchTextPainted(
            tester,
            field,
            tester.widget<TextField>(field).decoration!.hintText!,
          );
          if (destination != BuyV2Destination.shop) {
            await captureR66Visual(
              tester,
              'r5-search-$label-${destination.name}',
            );
          }
          await tester.tap(finish);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
        await tester.pumpAndSettle();
        await tester.tap(control);
        await tester.pumpAndSettle();
        expectSearchTextPainted(
          tester,
          field,
          tester.widget<TextField>(field).decoration!.hintText!,
        );
        await captureR66Visual(tester, 'r5-search-$label-offers');
        expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('R5 search submit and Back preserve both carts $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final shop = session.visibleProducts.first;
      expect(session.addProduct(shop.id), isTrue);
      expect(session.addProduct('w-notebook'), isTrue);
      final quantities = (
        session.quantityFor(shop.id),
        session.quantityFor('w-notebook'),
      );
      final totals = (
        session.totalForDestination(BuyV2Destination.shop),
        session.totalForDestination(BuyV2Destination.wholesale),
      );
      session.clearNotice();
      session.clearCartAcknowledgement();
      await tester.pumpWidget(app(session, textScale: scale));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('buy-search-field'));
      await tester.enterText(field, 'tomato');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(session.query, 'tomato');
      expect(session.recentSearchesFor(BuyV2Destination.shop).first, 'tomato');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(field, findsNothing);
      expect(session.query, 'tomato');
      expect(session.view, BuyV2View.catalogue);
      expect((
        session.quantityFor(shop.id),
        session.quantityFor('w-notebook'),
      ), quantities);
      expect((
        session.totalForDestination(BuyV2Destination.shop),
        session.totalForDestination(BuyV2Destination.wholesale),
      ), totals);
      expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> revealPurchaseTarget(
    WidgetTester tester,
    Finder target, {
    bool towardStart = false,
  }) async {
    if (target.evaluate().isEmpty) {
      final checkoutList = find.descendant(
        of: find.byKey(const PageStorageKey('buy-checkout-unified')),
        matching: find.byType(Scrollable),
      );
      final cartList = find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is ListView &&
              widget.key is PageStorageKey &&
              (widget.key as PageStorageKey).value.toString().startsWith(
                'buy-cart-',
              ),
        ),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      final scrollable = checkoutList.evaluate().isNotEmpty
          ? checkoutList.first
          : cartList.evaluate().isNotEmpty
          ? cartList.first
          : find
                .byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.down,
                )
                .first;
      final height = tester.getSize(scrollable).height;
      await tester.scrollUntilVisible(
        target,
        (towardStart ? -1 : 1) * 180.0.clamp(1.0, height * .6),
        scrollable: scrollable,
        maxScrolls: 80,
      );
    }
    expect(target, findsOneWidget);
    await Scrollable.ensureVisible(tester.element(target), alignment: .35);
    await tester.pumpAndSettle();
    expect(
      target.hitTestable(),
      findsOneWidget,
      reason: 'Purchase target bounds: ${tester.getRect(target)}',
    );
  }

  for (final size in [const Size(320, 844), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      final profile = '${size.width.toInt()}x${size.height.toInt()}-$scale';
      testWidgets('R5 purchase decisions payment recovery $profile', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        final core = BuySession();
        final commerce = TestLegacyRecoveryCommerce()
          ..onPlace = (request) => testGroupedPlacement(
            request,
            outcome: BuyV2OrderPlacementOutcome.paymentActionRequired,
          );
        final session = BuyV2Session(
          core: core,
          commerceAdapter: commerce,
          productFactsAdapter: const _FixedDeliveryPromiseFactsAdapter(
            'Delivery in 2 days',
          ),
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(
          app(
            session,
            textScale: scale,
            safePadding: const EdgeInsets.only(top: 24, bottom: 34),
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(session.addProduct('s-milk'), isTrue);
        expect(session.addProduct('w-rice-50kg'), isTrue);
        final expectedMixedTotal =
            BuyV2Catalogue.allProducts
                .firstWhere((p) => p.id == 's-milk')
                .price +
            BuyV2Catalogue.allProducts
                .firstWhere((p) => p.id == 'w-rice-50kg')
                .price;
        session.openCart(scope: BuyV2CartScope.wholesale);
        expect(session.openCheckout(), isTrue);
        await tester.pumpAndSettle();
        final paymentCard = find.byKey(
          const ValueKey('buy-checkout-confirm-payment'),
        );
        await revealPurchaseTarget(tester, paymentCard);
        await tester.tap(paymentCard);
        await tester.pumpAndSettle();
        final phonePe = find.byKey(const ValueKey('buy-payment-UPI'));
        await revealPurchaseTarget(tester, phonePe);
        await tester.tap(phonePe);
        await tester.pumpAndSettle();
        final placeOrder = find.byKey(
          ValueKey('buy-checkout-primary-${session.checkoutStep.name}'),
        );
        expect(
          find.descendant(of: placeOrder, matching: find.text('Place order')),
          findsOneWidget,
        );
        await tester.tap(placeOrder);
        await tester.pumpAndSettle();
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentActionRequired,
        );
        final reference = session.paymentReference;
        final attempt = session.checkoutIdempotencyKey;
        expect(commerce.requests.single.total, expectedMixedTotal);
        expect(commerce.requests.single.amountDueNow, expectedMixedTotal);
        final state = find.byKey(
          const ValueKey('buy-checkout-payment-state-paymentActionRequired'),
        );
        final heading = find.descendant(
          of: state,
          matching: find.text('Payment unavailable right now'),
        );
        final explanation = find.descendant(
          of: state,
          matching: find.text(
            'Check the original payment before choosing again. You can leave safely.',
          ),
        );
        for (final field in [heading, explanation]) {
          await revealPurchaseTarget(tester, field);
          expectReadable(tester, field, wholeWords: true);
        }
        await revealPurchaseTarget(tester, heading);
        await captureReadability(
          tester,
          'r5-decision-payment-$profile-heading',
        );
        final primary = find.byKey(
          const ValueKey('buy-checkout-primary-payment'),
        );
        expect(tester.widget<FilledButton>(primary).onPressed, isNull);
        final paymentNotice = find.byKey(const ValueKey('buy-live-notice'));
        expect(paymentNotice, findsOneWidget);
        expect(
          tester.widget<Semantics>(paymentNotice).properties.label,
          'Check the original payment before choosing again. Your Cart is retained.',
        );
        expect(session.paymentReference, reference);
        expect(session.checkoutIdempotencyKey, attempt);
        expect(session.confirmedOrders, isEmpty);
        final cancel = find.byKey(
          const ValueKey('buy-checkout-cancel-payment'),
        );
        await revealPurchaseTarget(tester, cancel);
        expectReadable(
          tester,
          find.descendant(of: cancel, matching: find.text('Leave payment')),
          action: cancel,
          wholeWords: true,
        );
        await captureReadability(tester, 'r5-decision-payment-$profile-cancel');
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentUnknown,
        );
        final needsChecking = find.text('Payment status needs checking');
        await revealPurchaseTarget(tester, needsChecking);
        expectReadable(tester, needsChecking, wholeWords: true);
        await captureReadability(
          tester,
          'r5-decision-payment-$profile-cancelled',
        );
        expect(session.paymentReference, reference);
        expect(session.checkoutIdempotencyKey, attempt);
        expect(session.choosePayment('Card'), isFalse);
        expect(session.retryCheckoutPayment(), isFalse);
        expect(await session.submitOrder(), isFalse);
        expect(commerce.requests, hasLength(1));
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(primary).onPressed, isNotNull);
        expect(
          find.descendant(of: primary, matching: find.text('Check payment')),
          findsOneWidget,
        );
        await tester.tap(primary);
        await tester.pumpAndSettle();
        expect(commerce.reconciledKeys, [attempt]);
        expect(commerce.requests, hasLength(1));
        expect(session.paymentReference, reference);
        expect(session.checkoutIdempotencyKey, attempt);
        expect(session.checkoutPaymentActionAmount, expectedMixedTotal);
        expect(session.confirmedOrders, isEmpty);
        final cart = find.byKey(const ValueKey('buy-checkout-return-cart'));
        await revealPurchaseTarget(tester, cart, towardStart: true);
        await tester.tap(cart);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(session.cartScope, BuyV2CartScope.wholesale);
        expect(session.scopedCartTotal, expectedMixedTotal);
        expect(session.checkoutScope, BuyV2CartScope.all);
        expect(session.quantityFor('w-rice-50kg'), 1);
        expect(session.quantityFor('s-milk'), 1);
        expect(session.totalForDestination(BuyV2Destination.shop), 66);
        expect(session.confirmedOrders, isEmpty);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'R5 purchase decisions full benefit terms and totals $profile',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          final semantics = tester.ensureSemantics();
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            cartBenefitsAdapter: const ActiveTestCartBenefits(),
          );
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await tester.pumpWidget(
            app(
              session,
              textScale: scale,
              safePadding: const EdgeInsets.only(top: 24, bottom: 34),
              disableAnimations: true,
            ),
          );
          await tester.pumpAndSettle();
          session.addProduct('s-milk');
          session.addProduct('w-rice-50kg');
          session.openCart(scope: BuyV2CartScope.wholesale);
          session.selectCartProduct('s-milk', false);
          await tester.pumpAndSettle();
          expect(session.scopedPayableTotal, 3200);
          for (final kind in BuyV2CartBenefitKind.values) {
            final entry = find.byKey(const ValueKey('buy-cart-coupons'));
            await revealPurchaseTarget(
              tester,
              entry,
              towardStart: kind == BuyV2CartBenefitKind.paymentOffer,
            );
            if (find
                .byTooltip('Collapse coupons and offers')
                .evaluate()
                .isEmpty) {
              await tester.tap(entry);
              await tester.pumpAndSettle();
            }
            expect(
              find.byKey(const ValueKey('buy-cart-benefits-inline')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('buy-cart-benefits-page')),
              findsNothing,
            );
            expect(session.view, BuyV2View.cart);
            if (kind == BuyV2CartBenefitKind.paymentOffer) {
              final paymentKind = find.byKey(
                const ValueKey('buy-cart-benefit-kind-payment'),
              );
              await revealPurchaseTarget(tester, paymentKind);
              await tester.tap(paymentKind);
              await tester.pumpAndSettle();
              session.clearNotice();
              await tester.pumpAndSettle();
              final mainScroll = find.descendant(
                of: find.byKey(const PageStorageKey('buy-cart-wholesale')),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.down,
                ),
              );
              expect(mainScroll, findsOneWidget);
              final position = tester
                  .state<ScrollableState>(mainScroll)
                  .position;
              final offset = position.pixels;
              session.showNotice('Offers are unchanged.');
              await tester.pumpAndSettle();
              expect(
                tester.state<ScrollableState>(mainScroll).position,
                same(position),
              );
              expect(position.pixels, closeTo(offset, .5));
              session.clearNotice();
              await tester.pumpAndSettle();
              expect(
                tester.state<ScrollableState>(mainScroll).position,
                same(position),
              );
              expect(position.pixels, closeTo(offset, .5));
            }
            final benefit = session
                .cartBenefits(
                  kind: kind,
                  destination: BuyV2Destination.wholesale,
                )
                .last;
            expect(benefit.savingAmount, 300);
            final card = find.byKey(ValueKey('buy-cart-benefit-${benefit.id}'));
            await revealPurchaseTarget(tester, card);
            final fields = find.descendant(
              of: card,
              matching: find.byType(Text),
            );
            final labels = fields
                .evaluate()
                .map((field) => (field.widget as Text).data!)
                .toList();
            for (final label in labels) {
              final target = find.descendant(
                of: card,
                matching: find.text(label),
              );
              await revealPurchaseTarget(tester, target);
              expectReadable(tester, target, wholeWords: true);
            }
            final title = find.descendant(
              of: card,
              matching: find.text(benefit.title),
            );
            await revealPurchaseTarget(tester, title);
            await captureReadability(
              tester,
              'r5-decision-${kind.name}-$profile-title',
            );
            final select = find.byKey(
              ValueKey('buy-cart-benefit-select-${benefit.id}'),
            );
            await revealPurchaseTarget(tester, select);
            await captureReadability(
              tester,
              'r5-decision-${kind.name}-$profile-terms',
            );
            await tester.tap(select);
            await tester.pumpAndSettle();
            expect(
              session
                  .selectedCartBenefit(
                    kind: kind,
                    destination: BuyV2Destination.wholesale,
                  )
                  ?.id,
              benefit.id,
            );
            expect(session.scopedPayableTotal, 2900);
            final remove = find.byKey(
              ValueKey('buy-cart-benefit-remove-${benefit.id}'),
            );
            await revealPurchaseTarget(tester, remove);
            final removeSemantics = tester
                .getSemantics(remove)
                .getSemanticsData();
            expect(removeSemantics.label, 'Remove ${benefit.title}');
            expect(removeSemantics.flagsCollection.isSelected, Tristate.isTrue);
            expect(removeSemantics.hasAction(SemanticsAction.tap), isTrue);
            expect(tester.getSize(remove).height, greaterThanOrEqualTo(44));
            expect(remove.hitTestable(), findsOneWidget);
            final status = find.byKey(
              ValueKey('buy-cart-benefit-status-motion-${benefit.id}'),
            );
            final statusText = find.descendant(
              of: status,
              matching: find.byType(Text),
            );
            await revealPurchaseTarget(tester, statusText);
            expectReadable(tester, statusText, wholeWords: true);
            final statusBounds = tester.getRect(status);
            final textBounds = tester.getRect(statusText);
            expect(textBounds.top, greaterThanOrEqualTo(statusBounds.top - .5));
            expect(
              textBounds.bottom,
              lessThanOrEqualTo(statusBounds.bottom + .5),
            );
            await captureReadability(
              tester,
              'r5-decision-${kind.name}-$profile-selected',
            );
            if (kind == BuyV2CartBenefitKind.paymentOffer) {
              final pending = find.byKey(
                ValueKey('buy-payment-offer-selection-status-${benefit.id}'),
              );
              await revealPurchaseTarget(tester, pending);
              expectReadable(tester, pending, wholeWords: true);
              expect(
                tester.widget<Text>(pending).data,
                contains('not included'),
              );
              await revealPurchaseTarget(tester, remove);
              await tester.tap(remove);
              await tester.pumpAndSettle();
              expect(session.scopedPayableTotal, 2900);
            }
            await revealPurchaseTarget(tester, entry, towardStart: true);
            await tester.tap(entry);
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.cart);
            expect(session.cartScope, BuyV2CartScope.wholesale);
            expect(session.scopedPayableTotal, 2900);
          }
          final coupons = find.byKey(const ValueKey('buy-cart-coupons'));
          await revealPurchaseTarget(tester, coupons);
          await tester.tap(coupons);
          await tester.pumpAndSettle();
          final coupon = session.selectedCartBenefit(
            kind: BuyV2CartBenefitKind.coupon,
            destination: BuyV2Destination.wholesale,
          )!;
          final remove = find.byKey(
            ValueKey('buy-cart-benefit-remove-${coupon.id}'),
          );
          await revealPurchaseTarget(tester, remove);
          await tester.tap(remove);
          await tester.pumpAndSettle();
          await revealPurchaseTarget(tester, coupons);
          await tester.tap(coupons);
          await tester.pumpAndSettle();
          expect(session.scopedPayableTotal, 3200);
          expect(session.quantityFor('w-rice-50kg'), 1);
          expect(session.quantityFor('s-milk'), 1);
          expect(session.totalForDestination(BuyV2Destination.shop), 66);
          expect(session.confirmedOrders, isEmpty);
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );

      for (final destination in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        testWidgets(
          'R5 purchase decisions complete Saved notice ${destination.name} $profile',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            await tester.pumpWidget(
              app(
                session,
                textScale: scale,
                safePadding: const EdgeInsets.only(top: 24, bottom: 34),
                disableAnimations: true,
              ),
            );
            await tester.pumpAndSettle();
            session.toggleSaved('s-milk');
            session.toggleSaved('w-rice-50kg');
            final other = destination == BuyV2Destination.shop
                ? BuyV2Destination.wholesale
                : BuyV2Destination.shop;
            final otherSavedIds = session
                .savedProductsFor(other)
                .map((product) => product.id)
                .toList(growable: false);
            session.addProduct('s-milk');
            session.addProduct('w-rice-50kg');
            session.openDestination(destination);
            session.chooseCategory('all');
            session.chooseShopSaleType(
              buyV2CatalogueFulfilmentModeFor(session.product('s-milk')) ==
                      BuyV2FulfilmentMode.quickLocal
                  ? BuyV2ShopSaleType.quickDelivery
                  : BuyV2ShopSaleType.courier,
            );
            session.chooseWholesaleSaleType(
              session
                          .savedProductsFor(BuyV2Destination.wholesale)
                          .firstWhere((product) => product.catalogueListing)
                          .minimumOrder >
                      2
                  ? BuyV2WholesaleSaleType.bulk
                  : BuyV2WholesaleSaleType.wholesale,
            );
            session.clearNotice();
            await tester.pumpAndSettle();
            final saved = find.byKey(
              const ValueKey('buy-saved-products-button'),
            );
            await revealPurchaseTarget(tester, saved);
            await tester.tap(saved);
            await tester.pumpAndSettle();
            final clear = find.byKey(const ValueKey('buy-saved-clear'));
            await revealPurchaseTarget(tester, clear);
            await tester.tap(clear);
            await tester.pumpAndSettle();
            final confirm = find.byKey(
              const ValueKey('buy-saved-confirm-clear'),
            );
            await revealPurchaseTarget(tester, confirm);
            await tester.tap(confirm);
            await tester.pumpAndSettle();
            expect(session.savedCountFor(destination), 0);
            expect(
              session.savedProductsFor(other).map((product) => product.id),
              otherSavedIds,
            );
            final notice = find.byKey(const ValueKey('buy-live-notice'));
            final message = find.descendant(
              of: notice,
              matching: find.text(
                '${destination.label} Saved products cleared.',
              ),
            );
            expectReadable(tester, message, wholeWords: true);
            await captureReadability(
              tester,
              'r5-decision-notice-${destination.name}-$profile',
            );
            expect(session.quantityFor('s-milk'), 1);
            expect(session.quantityFor('w-rice-50kg'), 1);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  Future<void> expectBuySystemBarPaint(WidgetTester tester) async {
    final root = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('r66-cart-capture')),
    );
    await tester.runAsync(() async {
      final frame = await root.toImage(pixelRatio: 1);
      try {
        final bytes = await frame.toByteData(format: ImageByteFormat.rawRgba);
        expect(bytes, isNotNull);
        final rgba = bytes!;
        Color at(int x, int y) {
          final index = (y * frame.width + x) * 4;
          return Color.fromARGB(
            rgba.getUint8(index + 3),
            rgba.getUint8(index),
            rgba.getUint8(index + 1),
            rgba.getUint8(index + 2),
          );
        }

        for (final x in [4, frame.width ~/ 2, frame.width - 5]) {
          final top = at(x, 10);
          expect(top.computeLuminance(), greaterThan(.7));
          expect(top, isNot(Colors.white));
          expect(
            (top.computeLuminance() + .05) / .05,
            greaterThanOrEqualTo(4.5),
          );
          final bottom = at(x, frame.height - 10);
          expect(
            (bottom.computeLuminance() + .05) / .05,
            greaterThanOrEqualTo(4.5),
          );
        }
      } finally {
        frame.dispose();
      }
    });
  }

  for (final size in [const Size(320, 844), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      final profile = '${size.width.toInt()}x${size.height.toInt()}-$scale';
      testWidgets('R5 system bars restore after global routes $profile', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
        addTearDown(tester.view.reset);
        final overlays = <Map<String, Object?>>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'SystemChrome.setSystemUIOverlayStyle') {
              overlays.add(Map<String, Object?>.from(call.arguments as Map));
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        // Match the previously good Buy state before a light global page opens.
        // The return assertion must fail if Buy merely inherits that page's style.
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
        await tester.idle();
        final core = BuySession();
        final session = BuyV2Session(core: core);
        final journey = JourneySession(store: MemoryJourneyStore());
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        addTearDown(journey.dispose);
        session.addProduct('s-milk');
        session.addProduct('w-rice-50kg');
        session.openDestination(BuyV2Destination.wholesale);
        final orderIds = session.orders.map((order) => order.id).toList();
        final router = GoRouter(
          initialLocation: '/app/buy',
          routes: [
            GoRoute(
              path: '/app/buy',
              builder: (context, state) => BuyV2Screen(
                session: session,
                initialDestination: BuyV2Destination.wholesale,
                accountAuthenticated: true,
              ),
            ),
            GoRoute(
              path: '/app/account/workspaces/preferences',
              builder: (context, state) =>
                  GlobalPrivacyPreferencesV2(session: journey),
            ),
            GoRoute(
              path: '/app/account/security',
              builder: (context, state) => GlobalSecurityV2(session: journey),
            ),
            GoRoute(
              path: '/app/ask',
              builder: (context, state) =>
                  GlobalHelpSupportV2(session: journey),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: MoolTheme.light(),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: RepaintBoundary(
                key: const ValueKey('r66-cart-capture'),
                child: child!,
              ),
            ),
          ),
        );
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
        final renderView = tester.binding.renderViews.single;
        final previousAdjustment = renderView.automaticSystemUiAdjustment;
        renderView.automaticSystemUiAdjustment = true;
        addTearDown(
          () => renderView.automaticSystemUiAdjustment = previousAdjustment,
        );
        await tester.pumpAndSettle();
        void expectIcons(Brightness brightness) {
          expect(overlays, isNotEmpty);
          expect(
            overlays.last['statusBarIconBrightness'],
            brightness.toString(),
            reason: 'Platform overlay after settled route: ${overlays.last}',
          );
        }

        for (final route in [
          (
            name: 'preferences',
            entry: 'global-profile-preferences',
            page: 'global-privacy-preferences-v2',
            back: 'global-preferences-back',
          ),
          (
            name: 'security',
            entry: 'global-profile-security',
            page: 'global-security-v2',
            back: 'global-security-back',
          ),
          (
            name: 'help',
            entry: 'buy-settings-help',
            page: 'buy-shopping-help',
            back: 'buy-shopping-help-close',
          ),
        ]) {
          for (final platformBack in [false, true]) {
            final fromSettings = route.name == 'help';
            if (fromSettings) {
              final filters = find.byKey(const ValueKey('buy-filter-button'));
              await tester.ensureVisible(filters);
              await tester.pumpAndSettle();
              expect(filters.hitTestable(), findsOneWidget);
              await tester.tap(filters);
              await tester.pumpAndSettle();
              final tools = find.byKey(
                const ValueKey('buy-refine-section-tools'),
              );
              final refinementScroll = find.descendant(
                of: find.byKey(const ValueKey('buy-discovery-refinement-list')),
                matching: find.byType(Scrollable),
              );
              await tester.scrollUntilVisible(
                tools,
                160,
                scrollable: refinementScroll,
                maxScrolls: 30,
              );
              final heading = find
                  .descendant(of: tools, matching: find.byType(ListTile))
                  .first;
              await tester.ensureVisible(heading);
              await tester.pumpAndSettle();
              expect(heading.hitTestable(), findsOneWidget);
              await tester.tap(heading);
              await tester.pumpAndSettle();
              final settings = find.byKey(
                const ValueKey('buy-shopping-settings-button'),
              );
              await tester.scrollUntilVisible(
                settings,
                160,
                scrollable: refinementScroll,
                maxScrolls: 30,
              );
              await tester.ensureVisible(settings);
              await tester.pumpAndSettle();
              expect(settings.hitTestable(), findsOneWidget);
              await tester.tap(settings);
              await tester.pumpAndSettle();
              expect(
                find.byKey(const ValueKey('buy-shopping-settings')),
                findsOneWidget,
              );
            } else {
              final account = find.byKey(const ValueKey('buy-open-account'));
              await tester.ensureVisible(account);
              await tester.pumpAndSettle();
              expect(account.hitTestable(), findsOneWidget);
              await tester.tap(account);
              await tester.pumpAndSettle();
            }
            final entry = find.byKey(ValueKey(route.entry));
            await tester.scrollUntilVisible(
              entry,
              180,
              scrollable: find
                  .descendant(
                    of: find.byKey(
                      ValueKey(
                        fromSettings
                            ? 'buy-shopping-settings'
                            : 'global-profile-panel-v2',
                      ),
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
              maxScrolls: 30,
            );
            await tester.ensureVisible(entry);
            await tester.pumpAndSettle();
            expect(entry.hitTestable(), findsOneWidget);
            await tester.tap(entry);
            await tester.pumpAndSettle();
            expect(find.byKey(ValueKey(route.page)), findsOneWidget);
            expectIcons(Brightness.dark);
            if (!platformBack) {
              await captureReadability(
                tester,
                'r5-bars-${route.name}-$profile-open',
              );
            }
            if (platformBack) {
              await tester.binding.handlePopRoute();
            } else {
              final back = find.byKey(ValueKey(route.back));
              expect(back.hitTestable(), findsOneWidget);
              await tester.tap(back);
            }
            await tester.pumpAndSettle();
            expect(find.byKey(ValueKey(route.page)), findsNothing);
            expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
            expectIcons(Brightness.dark);
            expect(session.destination, BuyV2Destination.wholesale);
            expect(session.view, BuyV2View.catalogue);
            expect(session.quantityFor('s-milk'), 1);
            expect(session.quantityFor('w-rice-50kg'), 1);
            expect(session.orders.map((order) => order.id), orderIds);
            if (!platformBack) {
              await captureReadability(
                tester,
                'r5-bars-${route.name}-$profile-return',
              );
            }
            if (fromSettings) {
              expect(
                find.byKey(const ValueKey('buy-shopping-settings')),
                findsOneWidget,
              );
              await tester.binding.handlePopRoute();
              await tester.pumpAndSettle();
              expect(
                find.byKey(const ValueKey('buy-shopping-settings')),
                findsNothing,
              );
              expectIcons(Brightness.dark);
            }
          }
        }
        for (final destination in BuyV2Destination.values) {
          session.openDestination(destination);
          await tester.pumpAndSettle();
          expectIcons(Brightness.dark);
          await expectBuySystemBarPaint(tester);
          await captureReadability(
            tester,
            'r5-bars-${destination.name}-$profile-paint',
          );
        }
        session.openDestination(BuyV2Destination.wholesale);
        await tester.pumpAndSettle();
        tester.view.physicalSize = Size(size.height, size.width);
        await tester.pumpAndSettle();
        expectIcons(Brightness.dark);
        await expectBuySystemBarPaint(tester);
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expectIcons(Brightness.dark);
        expect(session.quantityFor('s-milk'), 1);
        expect(session.quantityFor('w-rice-50kg'), 1);
        expect(session.orders.map((order) => order.id), orderIds);
        expect(tester.takeException(), isNull);
      });
    }
  }

  Future<void> completeReviewPayment(
    WidgetTester tester,
    BuyV2Session session,
  ) async {
    expect(
      session.checkoutSubmissionState,
      BuyV2CheckoutSubmissionState.paymentActionRequired,
    );
    expect(await session.continuePayment((_) async => true), isTrue);
    await tester.pumpAndSettle();
    expect(
      session.checkoutSubmissionState,
      BuyV2CheckoutSubmissionState.paymentPending,
    );
    expect(await session.reconcilePayment(), isTrue);
    await tester.pumpAndSettle();
  }

  TestLegacyRecoveryCommerce isolatedConfirmationCommerce({
    BuyV2ProductFactsAdapter factsAdapter =
        const BuyV2CatalogueProductFactsAdapter(),
  }) {
    final commerce = TestLegacyRecoveryCommerce();
    final committedFacts = <String, Map<String, BuyV2ProductFactsSnapshot>>{};
    commerce.onPlace = (request) {
      committedFacts[request.idempotencyKey] = {
        for (final line in request.lines)
          line.product.id: factsAdapter.snapshotFor(line.product),
      };
      return testGroupedPlacement(
        request,
        outcome: BuyV2OrderPlacementOutcome.paymentActionRequired,
      );
    };
    commerce.onReconcile = (request) {
      // These named fixtures cover full advance with no quote charges. Reject
      // unrelated financial cases rather than constructing their allocations.
      expect(request.amountDueNow, request.total);
      expect(
        request.lines.fold<int>(0, (sum, line) => sum + line.total),
        request.total,
      );
      final facts = committedFacts[request.idempotencyKey]!;
      final purchase = 'test-purchase-${request.idempotencyKey}';
      return testGroupedPlacement(
        request,
        reference: purchase,
        orders: [
          for (final line in request.lines)
            BuyV2Order(
              id: 'test-order-${request.idempotencyKey}-${line.product.id}',
              destination: line.product.destination,
              title: 'Isolated confirmation order',
              itemSummary: 'Isolated test lines',
              total: line.total,
              partner: line.product.seller,
              partnerType: line.product.sellerType,
              promise: facts[line.product.id]!.deliveryPromise,
              promisedByLabel: facts[line.product.id]!.promisedByLabel,
              destinationLabel: request.address.shortLine,
              progress: 0,
              status: BuyV2OrderStatus.confirmed,
              purchaseId: purchase,
              productIds: [line.product.id],
              lines: [line],
              paymentMethod: request.paymentMethod,
              amountPaidNow: line.total,
              balanceDue: 0,
              recipient: request.address.recipient,
              addressLine: request.address.line,
            ),
        ],
      );
    };
    return commerce;
  }

  // Technical pre-commit setup. The public UI is one Checkout page; this
  // validates the retained model transition without tapping Place order.
  Future<void> prepareCheckoutPaymentState(
    WidgetTester tester,
    BuyV2Session session,
  ) async {
    expect(session.checkoutStep, BuyV2CheckoutStep.address);
    final total = session.checkoutAmountDueNow;
    final orderIds = session.orders.map((order) => order.id).toList();
    expect(session.checkoutSubmissionState, BuyV2CheckoutSubmissionState.idle);
    expect(session.checkoutIdempotencyKey, isNull);
    expect(session.continueCheckoutFromAddress(), isTrue);
    await tester.pumpAndSettle();
    expect(session.checkoutStep, BuyV2CheckoutStep.payment);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-checkout-payment-stage')),
      220,
      scrollable: scrollableWithin(
        const PageStorageKey('buy-checkout-unified'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-checkout-payment-stage')),
      findsOneWidget,
    );
    expect(session.checkoutSubmissionState, BuyV2CheckoutSubmissionState.idle);
    expect(session.checkoutIdempotencyKey, isNull);
    expect(session.confirmedOrders, isEmpty);
    expect(session.orders.map((order) => order.id).toList(), orderIds);
    expect(session.checkoutAmountDueNow, total);
  }

  Future<void> prepareCheckoutReviewState(
    WidgetTester tester,
    BuyV2Session session,
  ) async {
    await prepareCheckoutPaymentState(tester, session);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-checkout-order-details')),
      -220,
      scrollable: scrollableWithin(
        const PageStorageKey('buy-checkout-unified'),
      ),
    );
    await tester.pumpAndSettle();
    expect(session.checkoutStep, BuyV2CheckoutStep.payment);
    expect(session.checkoutSubmissionState, BuyV2CheckoutSubmissionState.idle);
    expect(session.checkoutIdempotencyKey, isNull);
    expect(session.confirmedOrders, isEmpty);
  }

  test('payment handoff provider labels preserve customer brand casing', () {
    expect(
      buyV2CustomerPaymentProviderLabel('phonepe', fallback: ''),
      'PhonePe',
    );
    expect(buyV2CustomerPaymentProviderLabel('paytm', fallback: ''), 'Paytm');
    expect(
      buyV2CustomerPaymentProviderLabel('pine-labs', fallback: ''),
      'Pine Labs',
    );
    expect(
      buyV2CustomerPaymentProviderLabel('', fallback: 'Cash on Delivery'),
      'Cash on Delivery',
    );
  });

  test('Cart total supports the full approved Indian amount range', () {
    expect(buyV2Money(1), '₹1');
    expect(buyV2Money(10000000), '₹1,00,00,000');
  });

  testWidgets('persistent Buy navigation preserves one destination surface', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );
    session.openDestination(BuyV2Destination.medicine);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.medicine);
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
  });

  testWidgets('vertical changes transition the real surface without a wait', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.medicine);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('buy-destination-progress')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-current')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-outgoing')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-shared-header')), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsNothing,
    );

    await tester.pumpAndSettle();

    final settledSequence = session.navigationMotionSequence;
    session.openDestination(BuyV2Destination.medicine);
    await tester.pump();
    expect(session.navigationMotionSequence, settledSequence);
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-outgoing')),
      findsNothing,
    );

    session.openOrders();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-orders-assist')), findsNothing);
    session.openAssist();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('buy-destination-progress')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
    expect(
      find.byKey(PageStorageKey('buy-tracking-${session.assistOrder.id}')),
      findsOneWidget,
    );
    expect(
      session.navigationMotionDirection,
      BuyV2NavigationMotionDirection.forward,
    );
  });

  testWidgets('MoolSocial opens connected actions without replacing Buy', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var moolTaps = 0;
    await tester.pumpWidget(app(session, onOpenMool: () => moolTaps += 1));
    await tester.pumpAndSettle();
    session.openDestination(BuyV2Destination.medicine);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.medicine);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();

    expect(moolTaps, 0);
    expect(session.destination, BuyV2Destination.medicine);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.byKey(const ValueKey('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mool-navigator-family-buy')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-mool-social')), findsNothing);
    expect(find.byKey(const ValueKey('buy-mool-buy')), findsNothing);
    expect(find.text('Pay'), findsNothing);
    await tester.drag(
      find.byKey(const Key('mool-connected-action-navigator-drag-surface')),
      const Offset(0, 80),
    );
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.medicine);
    expect(
      find.byKey(const ValueKey('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
  });

  testWidgets(
    'approved Buy shell fits representative small and large devices',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      final session = BuyV2Session(core: BuySession());

      for (final size in const [
        Size(320, 568),
        Size(360, 640),
        Size(360, 800),
        Size(375, 667),
        Size(384, 854),
        Size(390, 844),
        Size(393, 852),
        Size(412, 915),
        Size(430, 932),
        Size(480, 960),
        Size(600, 960),
        Size(768, 1024),
        Size(844, 390),
        Size(932, 430),
        Size(1024, 768),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'viewport $size');
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      }
    },
  );

  testWidgets('discovery hierarchy leads with three-column product rows', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-featured-products')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-featured-product-list')),
      findsOneWidget,
    );
    final products = session.catalogueSaleTypeProducts.take(3).toList();
    final rects = [
      for (final product in products)
        tester.getRect(find.byKey(ValueKey('buy-product-${product.id}'))),
    ];
    expect(
      rects[0].top,
      lessThanOrEqualTo(304),
      reason: 'the expanded motion stage must remain compact',
    );
    expect(rects[1].top, rects[0].top);
    expect(rects[2].top, rects[0].top);
    expect(rects[2].left, greaterThan(rects[1].right));
    expect(rects[0].left, lessThan(rects[1].left));
    final featuredPhoto = find.byKey(
      ValueKey('buy-featured-packshot-${products.first.id}'),
    );
    expect(tester.getSize(featuredPhoto).width, greaterThanOrEqualTo(44));
    expect(
      tester.getRect(featuredPhoto).right,
      lessThanOrEqualTo(
        tester
            .getRect(find.byKey(ValueKey('buy-product-${products.first.id}')))
            .right,
      ),
    );
    final addRect = tester.getRect(
      find.byKey(ValueKey('buy-add-${products.first.id}')),
    );
    final photoRect = tester.getRect(featuredPhoto);
    expect(photoRect.height, greaterThan(addRect.height));
    expect(photoRect.bottom, lessThanOrEqualTo(addRect.top));
    final moreHeading = find.byKey(const ValueKey('buy-more-products-heading'));
    final discoveryScroll = scrollableWithin(
      PageStorageKey(
        'buy-${session.destination.name}-${session.selectedCategoryId}-${session.saleTypeSignature}-all',
      ),
    );
    for (
      var attempt = 0;
      attempt < 100 && moreHeading.hitTestable().evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(discoveryScroll, const Offset(0, -160));
      await tester.pumpAndSettle();
    }
    expect(moreHeading.hitTestable(), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-more-products-heading')),
      findsOneWidget,
    );

    final category = session.categories[1];
    expect(find.byKey(const ValueKey('buy-category-rail')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-category-grid')), findsOneWidget);
    final categoryLabel = find.byKey(
      ValueKey('buy-category-label-${category.id}'),
    );
    expect(categoryLabel, findsOneWidget);
    expect(tester.getSize(categoryLabel).width, greaterThanOrEqualTo(70));
    expect(tester.widget<Text>(categoryLabel).textAlign, TextAlign.center);
    expect(find.byKey(ValueKey('buy-category-${category.id}')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('buy-category-${category.id}')));
    await tester.pumpAndSettle();
    expect(session.selectedCategoryId, category.id);
    expect(find.byKey(const ValueKey('buy-category-picker')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-category-grid')), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-catalogue-promotions')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-featured-products')), findsNothing);
    expect(find.byType(BuyV2ProductCard), findsWidgets);
  });

  testWidgets('search expands into a dedicated responsive results owner', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final viewport in const [
      (
        size: Size(360, 800),
        safePadding: EdgeInsets.symmetric(vertical: 24),
        label: 'Android 360x800',
      ),
      (
        size: Size(390, 844),
        safePadding: EdgeInsets.only(top: 47, bottom: 34),
        label: 'iOS 390x844',
      ),
      (
        size: Size(430, 932),
        safePadding: EdgeInsets.only(top: 59, bottom: 34),
        label: 'iOS 430x932',
      ),
    ]) {
      tester.view.physicalSize = viewport.size;
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, safePadding: viewport.safePadding));
      await tester.pumpAndSettle();

      final searchBand = tester.getRect(
        find.byKey(const ValueKey('buy-search-band')),
      );
      final toolbar = tester.getRect(
        find.byKey(const ValueKey('buy-catalogue-toolbar')),
      );
      final restingSearch = tester.getRect(
        find.byKey(const ValueKey('buy-search-control')),
      );
      final dock = tester.getRect(
        find.byKey(const Key('moolsocial-compact-destination-rail')),
      );
      final dockSurface = tester.getRect(
        find.byKey(const Key('mool-compact-launcher')),
      );
      final safeBodyHeight =
          viewport.size.height -
          viewport.safePadding.top -
          viewport.safePadding.bottom;
      final topChromeHeight = toolbar.bottom - searchBand.top;
      final productRegionHeight = dock.top - toolbar.bottom;

      expect(
        searchBand.top,
        tester.getBottomLeft(find.byType(BuyV2DemoCatalogueLabel)).dy,
        reason: '${viewport.label} search follows the review-data provenance label',
      );

      expect(
        topChromeHeight / safeBodyHeight,
        lessThanOrEqualTo(.25),
        reason: '${viewport.label} top chrome',
      );
      expect(
        restingSearch.width / viewport.size.width,
        inInclusiveRange(.65, .76),
        reason:
            '${viewport.label} resting search width with location and account',
      );
      expect(
        restingSearch.height,
        44,
        reason: '${viewport.label} resting search target',
      );
      final restingSearchDecoration =
          tester
                  .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('buy-search-control')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(restingSearchDecoration.color, Colors.transparent);
      expect(restingSearchDecoration.border, isNull);
      expect(restingSearchDecoration.boxShadow, isNull);
      expect(
        find.byKey(const ValueKey('buy-open-scanner')),
        findsNothing,
        reason: '${viewport.label} scanning belongs to a paid collection order',
      );
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      final activeSearch = tester.getRect(
        find.byKey(const ValueKey('buy-search-control')),
      );
      expect(
        activeSearch.width / viewport.size.width,
        greaterThanOrEqualTo(.90),
        reason: '${viewport.label} active search width',
      );
      expect(activeSearch.height, 70);
      final activeSearchDecoration =
          tester
                  .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('buy-search-control')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(activeSearchDecoration.color, Colors.transparent);
      expect(activeSearchDecoration.border, isNull);
      expect(activeSearchDecoration.boxShadow, isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-search-band')),
          matching: find.byIcon(Icons.arrow_back_rounded),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-search-close')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-close'))).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('buy-search-field'))).width /
            activeSearch.width,
        greaterThanOrEqualTo(.60),
        reason: '${viewport.label} active search typing width',
      );
      expect(
        find.byKey(const ValueKey('buy-open-scanner')),
        findsNothing,
        reason: '${viewport.label} scanner yields to active query',
      );
      expect(
        find.byKey(const ValueKey('buy-search-results-surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-search-suggestion-list')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-search-ready-card')), findsNothing);
      expect(find.text('Shop suggestions'), findsNothing);
      expect(
        find.text('Find products, brands, sellers and product codes.'),
        findsNothing,
      );
      expect(find.byIcon(Icons.manage_search_rounded), findsNothing);
      expect(find.byIcon(Icons.north_west_rounded), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-search-suggestion-list')),
          matching: find.byIcon(Icons.history_rounded),
        ),
        findsNothing,
      );
      for (var index = 0; index < 4; index++) {
        final suggestion = find.byKey(
          ValueKey('buy-search-suggestion-shop-$index'),
        );
        expect(suggestion, findsOneWidget);
        expect(
          tester.getSize(suggestion).height,
          44,
          reason:
              '${viewport.label} suggestion $index uses the dense accessible target',
        );
      }
      expect(find.byKey(const ValueKey('buy-catalogue-toolbar')), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const ValueKey('buy-search-field')),
        'milk',
      );
      await tester.pumpAndSettle();
      expect(session.query, 'milk');
      expect(find.textContaining('match'), findsWidgets);
      expect(find.byType(BuyV2ProductCard), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('buy-search-close')));
      await tester.pumpAndSettle();
      expect(session.query, 'milk');
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-control'))),
        restingSearch.size,
      );
      expect(
        find.byKey(const ValueKey('buy-catalogue-toolbar')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
      await tester.pumpAndSettle();
      expect(session.query, isEmpty);
      expect(
        find.byKey(const ValueKey('buy-search-suggestion-list')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-search-close')));
      await tester.pumpAndSettle();
      expect(
        dockSurface.height / safeBodyHeight,
        lessThanOrEqualTo(.14),
        reason: '${viewport.label} navigation',
      );
      expect(
        productRegionHeight / safeBodyHeight,
        greaterThanOrEqualTo(.67),
        reason: '${viewport.label} product region',
      );
      expect(tester.takeException(), isNull, reason: viewport.label);
    }
  });

  testWidgets(
    'expanded search offers flat separate Shop Wholesale and Medicine lists',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        session.openDestination(destination);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-search-control')));
        await tester.pumpAndSettle();

        final suggestions = session.searchSuggestions;
        expect(suggestions, hasLength(4), reason: destination.name);
        expect(
          find.byKey(const ValueKey('buy-search-suggestion-list')),
          findsOneWidget,
        );
        expect(find.text('${destination.label} suggestions'), findsNothing);
        final first = find.byKey(
          ValueKey('buy-search-suggestion-${destination.name}-0'),
        );
        expect(first, findsOneWidget);
        expect(tester.getSize(first).height, greaterThanOrEqualTo(44));
        await tester.ensureVisible(first);
        await tester.tap(first);
        await tester.pumpAndSettle();

        expect(session.query, suggestions.first);
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('buy-search-field')))
              .controller
              ?.text,
          suggestions.first,
        );
        expect(session.visibleProducts, isNotEmpty);
        expect(
          session.visibleProducts.every(
            (product) => product.destination == destination,
          ),
          isTrue,
        );
        expect(find.byType(BuyV2ProductCard), findsWidgets);

        await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
        await tester.pumpAndSettle();
        expect(session.query, isEmpty);
        expect(
          find.byKey(ValueKey('buy-search-suggestion-${destination.name}-0')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('buy-search-close')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: destination.name);
      }

      session.openDestination(BuyV2Destination.orders);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Orders suggestions'), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-search-suggestion-list')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-search-suggestion-orders-0')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'responsive search surface is shared across every Buy destination',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      for (final destination in BuyV2Destination.values) {
        session.openDestination(destination);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-open-scanner')),
          findsNothing,
          reason: '${destination.name} has no generic scanner entry',
        );
        await tester.tap(find.byKey(const ValueKey('buy-search-control')));
        await tester.pumpAndSettle();

        final activeSearch = tester.getRect(
          find.byKey(const ValueKey('buy-search-control')),
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('buy-search-field'))).width /
              activeSearch.width,
          greaterThanOrEqualTo(.60),
          reason: '${destination.name} typing width at 320 / 140 percent',
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('buy-search-band')),
            matching: find.byIcon(Icons.arrow_back_rounded),
          ),
          findsNothing,
          reason: destination.name,
        );
        expect(find.byKey(const ValueKey('buy-search-close')), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        expect(
          find.byKey(const ValueKey('buy-open-scanner')),
          findsNothing,
          reason: '${destination.name} scanner yields to active query',
        );

        await tester.enterText(
          find.byKey(const ValueKey('buy-search-field')),
          'a long product sentence that must remain readable without hiding its beginning',
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('buy-search-field')))
              .maxLines,
          6,
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('buy-search-control')))
              .height,
          162,
          reason: '${destination.name} long-query control grows progressively',
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('buy-search-band'))).height,
          174,
          reason: '${destination.name} long-query band owns all wrapped text',
        );
        expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
        expect(find.byKey(const ValueKey('buy-search-clear')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const ValueKey('buy-search-clear'))).height,
          greaterThanOrEqualTo(44),
          reason: destination.name,
        );
        await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
        await tester.pumpAndSettle();
        expect(session.query, isEmpty);
        await tester.tap(find.byKey(const ValueKey('buy-search-close')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('buy-search-field')), findsNothing);
        expect(tester.takeException(), isNull, reason: destination.name);
      }

      session.openDestination(BuyV2Destination.shop);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-search-field')),
        'milk',
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-search-field')), findsNothing);
      expect(session.query, 'milk');
      expect(session.destination, BuyV2Destination.shop);

      session.updateQuery('');
      await tester.pumpWidget(
        app(session, textScale: 1.4, disableAnimations: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pump();
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-control'))).height,
        70,
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const ValueKey('buy-search-band')),
            )
            .duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const ValueKey('buy-search-control')),
            )
            .duration,
        Duration.zero,
      );
    },
  );

  testWidgets('Account and product depth close the active search owner', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      'milk',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsOneWidget,
    );

    session.openAccount();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.account);
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-account-orders')), findsOneWidget);

    session.closeAccount();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.catalogue);
    expect(session.query, 'milk');
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    final product = session.visibleProducts.first;
    await tester.tap(find.byKey(ValueKey('buy-product-${product.id}')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-product-packshot-${product.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'category action is compact and Shop sale types reuse its toolbar space',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      await captureR66Visual(tester, 'r669-three-line-shop-category');
      final categoryAction = find.byKey(const ValueKey('buy-category-picker'));
      expect(tester.getSize(categoryAction), const Size(44, 44));
      expect(
        find.descendant(
          of: categoryAction,
          matching: find.byIcon(Icons.menu_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-saved-products-button')),
          matching: find.byIcon(Icons.bookmark_border_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-filter-button')),
          matching: find.byIcon(Icons.tune_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-sale-type-selector')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-shop-sale-type-quick')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is BuyV2DeliveryModeIcon &&
                widget.artwork == BuyV2DeliveryArtwork.quick,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-shop-sale-type-courier')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is BuyV2DeliveryModeIcon &&
                widget.artwork == BuyV2DeliveryArtwork.courier,
          ),
        ),
        findsOneWidget,
      );
      for (final title in const ['Quick', 'Scheduled']) {
        final iconSurface = tester.widget<AnimatedContainer>(
          find.byKey(ValueKey('buy-sale-type-icon-surface-$title')),
        );
        expect(iconSurface.decoration, isNull);
        expect(
          tester.getSize(
            find.byKey(ValueKey('buy-sale-type-icon-surface-$title')),
          ),
          const Size(20, 20),
        );
      }
      expect(
        find.byKey(const ValueKey('buy-shop-sale-type-track')),
        findsNothing,
      );
      final selector = tester.getRect(
        find.byKey(const ValueKey('buy-shop-sale-type-selector')),
      );
      final thumb = tester.getRect(
        find.byKey(const ValueKey('buy-shop-sale-type-thumb')),
      );
      expect(thumb.bottom, selector.bottom);
      expect(thumb.left, selector.left);
      expect(thumb.width, selector.width / 2);
      expect(thumb.height, 44);
      final thumbMotion = tester.widget<AnimatedPositioned>(
        find.byKey(const ValueKey('buy-shop-sale-type-thumb')),
      );
      expect(thumbMotion.duration, BuyV2Motion.contentChange);
      expect(thumbMotion.curve, Curves.easeOutQuart);
      final thumbSurface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('buy-shop-sale-type-thumb-surface')),
      );
      final thumbDecoration = thumbSurface.decoration as BoxDecoration;
      expect(thumbDecoration.gradient, isNull);
      expect(thumbDecoration.color, Colors.white);
      expect(thumbDecoration.borderRadius, isNull);
      expect(thumbDecoration.border, isNull);
      expect(thumbDecoration.boxShadow, isNull);
      expect(
        find.byKey(const ValueKey('buy-shop-sale-type-active-indicator')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-shop-sale-type-active-indicator-0')),
        findsNothing,
      );
      final segmentTransition = tester.widget<AnimatedSwitcher>(
        find.byKey(const ValueKey('buy-sale-type-segment-transition-Quick')),
      );
      expect(segmentTransition.duration, BuyV2Motion.stateChange);
      final quickTypography = tester.widget<AnimatedDefaultTextStyle>(
        find.byKey(const ValueKey('buy-shop-sale-type-quick-label-style')),
      );
      expect(quickTypography.style.fontSize, 11.25);
      expect(quickTypography.style.color, BuyV2ActionStyle.primaryForeground);
      expect(quickTypography.duration, BuyV2Motion.selection);
      final catalogueMotion = tester.widget<TweenAnimationBuilder<double>>(
        find.byKey(const ValueKey('buy-catalogue-motion-tween-shop')),
      );
      expect(catalogueMotion.duration, BuyV2Motion.contentChange);
      expect(catalogueMotion.curve, Curves.easeOutQuart);

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-sale-type-courier')),
      );
      await tester.pumpAndSettle();
      expect(session.shopSaleType, BuyV2ShopSaleType.courier);
      await tester.tap(find.byKey(const ValueKey('buy-shop-sale-type-quick')));
      await tester.pumpAndSettle();
      expect(session.shopSaleType, BuyV2ShopSaleType.quickDelivery);

      await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
      await tester.pumpAndSettle();
      final wholesaleSelector = find.byKey(
        const ValueKey('buy-wholesale-sale-type-selector'),
      );
      expect(
        find.descendant(
          of: wholesaleSelector,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is BuyV2DeliveryModeIcon &&
                widget.artwork == BuyV2DeliveryArtwork.wholesale,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: wholesaleSelector,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is BuyV2DeliveryModeIcon &&
                widget.artwork == BuyV2DeliveryArtwork.bulk,
          ),
        ),
        findsOneWidget,
      );
      for (final title in const ['Wholesale', 'Bulk']) {
        final iconSurface = tester.widget<AnimatedContainer>(
          find.byKey(ValueKey('buy-sale-type-icon-surface-$title')),
        );
        expect(iconSurface.decoration, isNull);
      }
    },
  );

  testWidgets(
    'commerce toolbar stays spacious at compact width and larger text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);

      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      final toolbar = tester.getRect(
        find.byKey(const ValueKey('buy-catalogue-toolbar')),
      );
      final category = tester.getRect(
        find.byKey(const ValueKey('buy-category-picker')),
      );
      final selector = tester.getRect(
        find.byKey(const ValueKey('buy-shop-sale-type-selector')),
      );
      final saved = tester.getRect(
        find.byKey(const ValueKey('buy-saved-products-button')),
      );
      final filters = tester.getRect(
        find.byKey(const ValueKey('buy-filter-button')),
      );

      expect(toolbar.height, 44);
      expect(category.size, const Size(44, 44));
      expect(saved.size, const Size(44, 44));
      expect(filters.size, const Size(44, 44));
      expect(category.right, lessThan(selector.left));
      expect(selector.right, lessThan(saved.left));
      expect(saved.right, lessThan(filters.left));
      expect(find.text('Quick'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
      await tester.pumpAndSettle();
      final wholesaleSelector = find.byKey(
        const ValueKey('buy-wholesale-sale-type-selector'),
      );
      expect(
        find.descendant(
          of: wholesaleSelector,
          matching: find.text('Wholesale'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: wholesaleSelector, matching: find.text('Bulk')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('commerce toolbar motion respects reduced-motion preference', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();

    final thumbMotion = tester.widget<AnimatedPositioned>(
      find.byKey(const ValueKey('buy-shop-sale-type-thumb')),
    );
    final quickTypography = tester.widget<AnimatedDefaultTextStyle>(
      find.byKey(const ValueKey('buy-shop-sale-type-quick-label-style')),
    );
    final segmentTransition = tester.widget<AnimatedSwitcher>(
      find.byKey(const ValueKey('buy-sale-type-segment-transition-Quick')),
    );
    final catalogueMotion = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey('buy-catalogue-motion-tween-shop')),
    );
    final category = find.byKey(const ValueKey('buy-category-picker'));
    final categoryPress = find.descendant(
      of: category,
      matching: find.byType(AnimatedScale),
    );
    final categoryLift = find.descendant(
      of: category,
      matching: find.byType(AnimatedSlide),
    );

    expect(thumbMotion.duration, Duration.zero);
    expect(quickTypography.duration, Duration.zero);
    expect(segmentTransition.duration, Duration.zero);
    expect(segmentTransition.reverseDuration, Duration.zero);
    expect(catalogueMotion.duration, Duration.zero);
    expect(categoryPress, findsOneWidget);
    expect(categoryLift, findsOneWidget);
    expect(tester.widget<AnimatedScale>(categoryPress).duration, Duration.zero);
    expect(tester.widget<AnimatedSlide>(categoryLift).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'every Buy destination keeps one global profile and exact Back return',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      const safePadding = EdgeInsets.only(top: 24, bottom: 24);
      final session = BuyV2Session(core: BuySession());

      await tester.pumpWidget(
        app(session, safePadding: safePadding, disableAnimations: true),
      );
      await tester.pumpAndSettle();

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
        BuyV2Destination.orders,
      ]) {
        if (destination == BuyV2Destination.orders) {
          session.openOrders();
        } else {
          session.openDestination(destination);
        }
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('buy-shared-header')),
          findsNothing,
          reason: destination.name,
        );
        expect(
          find.byKey(const ValueKey('buy-contextual-glass-header')),
          findsNothing,
          reason: destination.name,
        );
        expect(
          find.byKey(const ValueKey('buy-header-visual-creative-reel')),
          findsNothing,
          reason: destination.name,
        );
        final searchBand = find.byKey(const ValueKey('buy-search-band'));
        expect(searchBand, findsOneWidget, reason: destination.name);
        expect(
          tester.getTopLeft(searchBand).dy,
          find.byType(BuyV2DemoCatalogueLabel).evaluate().isEmpty
              ? safePadding.top
              : tester.getBottomLeft(find.byType(BuyV2DemoCatalogueLabel)).dy,
          reason: '${destination.name} follows only the applicable provenance label',
        );
        final accountAction = find.byKey(const ValueKey('buy-open-account'));
        expect(accountAction, findsOneWidget, reason: destination.name);
        expect(
          tester.getSize(accountAction),
          const Size(44, 44),
          reason: '${destination.name} account target remains accessible',
        );
        final searchBandRect = tester.getRect(searchBand);
        final accountRect = tester.getRect(accountAction);
        expect(
          accountRect.right,
          searchBandRect.right - 8,
          reason: '${destination.name} keeps account access at top right',
        );
        expect(
          accountRect.top,
          closeTo(searchBandRect.top + 5, 1),
          reason: '${destination.name} keeps account access in the top row',
        );

        await tester.tap(accountAction);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.catalogue, reason: destination.name);
        expect(
          find.byKey(const Key('global-profile-panel-v2')),
          findsOneWidget,
          reason: destination.name,
        );
        expect(
          find.text('Your account'),
          findsOneWidget,
          reason: destination.name,
        );
        expect(
          find.byKey(const ValueKey('buy-profile-avatar')),
          findsNothing,
          reason: destination.name,
        );
        final contextId = switch (destination) {
          BuyV2Destination.shop => 'shop-active-orders',
          BuyV2Destination.wholesale => 'wholesale-discovery',
          BuyV2Destination.medicine => 'medicine-discovery',
          BuyV2Destination.orders => 'shop-orders',
        };
        expect(
          find.byKey(Key('global-profile-context-$contextId')),
          findsNothing,
          reason: destination.name,
        );
        for (final id in ['identity', 'plans', 'workspaces', 'preferences', 'security']) {
          expect(find.byKey(Key('global-profile-$id')), findsOneWidget,
            reason: '${destination.name} keeps the same five account destinations');
        }
        expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.destination, destination);
        expect(session.view, BuyV2View.catalogue);
      }

      expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Shop uses the shared global profile and exact Back recovery', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());

    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();

    final profileAction = find.byKey(const ValueKey('buy-open-account'));
    expect(find.byTooltip('Open your MoolSocial profile'), findsOneWidget);
    expect(profileAction, findsOneWidget);
    expect(tester.getSize(profileAction), const Size(44, 44));
    expect(find.byKey(const ValueKey('buy-profile-avatar')), findsNothing);

    await tester.tap(profileAction);
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.catalogue);
    expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
    expect(find.text('Your account'), findsOneWidget);
    expect(
      find.byKey(const Key('global-profile-context-shop-active-orders')),
      findsNothing,
    );
    expect(find.text('Open orders'), findsNothing);
    expect(find.byKey(const Key('global-profile-identity')), findsOneWidget);
    expect(find.byKey(const Key('global-profile-workspaces')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(session.destination, BuyV2Destination.shop);
    expect(session.view, BuyV2View.catalogue);
    expect(find.byKey(const Key('global-profile-panel-v2')), findsNothing);
    expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-open-account')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Shop Orders remain available after dismissing compact Profile', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-open-account')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('global-profile-context-action-shop-active-orders')),
      findsNothing,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global-profile-panel-v2')), findsNothing);
    final orders = find.byKey(const Key('buy-local-tab-orders'));
    expect(orders.hitTestable(), findsOneWidget);
    await tester.tap(orders);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.orders);
    expect(session.view, BuyV2View.catalogue);
    expect(
      find.byKey(const PageStorageKey<String>('buy-orders')),
      findsOneWidget,
    );
  });

  testWidgets('inactive sponsored placement consumes no catalogue height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: const Scaffold(
          body: Column(
            children: [
              BuyV2SponsoredSlot(
                key: ValueKey('inactive-sponsored-slot'),
                content: null,
              ),
              Text('Products continue'),
            ],
          ),
        ),
      ),
    );

    final slot = find.byKey(const ValueKey('inactive-sponsored-slot'));
    expect(slot, findsOneWidget);
    expect(tester.getSize(slot).height, 0);
    expect(find.text('Products continue'), findsOneWidget);
    expect(find.text('Sponsored'), findsNothing);
    expect(find.text('Advertisement'), findsNothing);
  });

  testWidgets(
    'category modal reaches the safe bottom with compact heading and close',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
      await tester.pumpAndSettle();

      expect(find.text('Find a category'), findsOneWidget);
      expect(find.text('Shop categories'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('buy-category-search')))
            .height,
        44,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-category-close'))),
        const Size(44, 44),
      );
      final surface = tester.getRect(
        find.byKey(const ValueKey('buy-category-sheet-surface')),
      );
      expect(
        surface.bottom,
        closeTo(
          tester.view.physicalSize.height / tester.view.devicePixelRatio -
              BuyV2AddressSheetMotion.resolveBottomSafeInset(
                tester.element(
                  find.byKey(const ValueKey('buy-category-sheet-surface')),
                ),
              ),
          1,
        ),
      );
      expect(
        find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
        findsOneWidget,
      );
    },
  );

  test('every approved Buy category has a specific visual icon', () {
    final categories = {
      ...BuyV2Catalogue.shopCategories,
      ...BuyV2Catalogue.wholesaleCategories,
      ...BuyV2Catalogue.medicineCategories,
    };
    for (final category in categories) {
      expect(
        buyV2CategoryIconFor(category.id),
        isNot(Icons.category_outlined),
        reason: category.id,
      );
    }
  });

  testWidgets(
    'category selector fits 320 at 140 percent and finds a late category',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
      await tester.pumpAndSettle();
      final categoryGrid = find.byKey(const ValueKey('buy-category-grid'));
      expect(categoryGrid, findsOneWidget);
      expect(
        tester.widget<GridView>(categoryGrid).scrollDirection,
        Axis.vertical,
      );
      expect(find.byKey(const ValueKey('buy-category-rail')), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('buy-category-search')),
        'shop supplies',
      );
      await tester.pumpAndSettle();
      final lateCategory = find.byKey(
        const ValueKey('buy-category-shop-supplies'),
      );
      expect(lateCategory, findsOneWidget);
      expect(tester.getSize(lateCategory).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalogue exposes complete vertical product rows and its last product',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-featured-products')),
        findsOneWidget,
      );
      final grid = find.byKey(
        ValueKey(
          'buy-vertical-product-grid-buy-products-${session.destination.name}-${session.selectedCategoryId}-all',
        ),
      );
      final scroll = scrollableWithin(
        PageStorageKey(
          'buy-${session.destination.name}-${session.selectedCategoryId}-${session.saleTypeSignature}-all',
        ),
      );
      final remaining = session.catalogueSaleTypeProducts.skip(6).toList();
      expect(remaining.length, greaterThan(3));
      final last = find.byKey(ValueKey('buy-product-${remaining.last.id}'));
      for (
        var attempt = 0;
        attempt < 200 && last.hitTestable().evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(scroll, const Offset(0, -240));
        await tester.pumpAndSettle();
      }
      expect(last.hitTestable(), findsOneWidget);
      expect(grid, findsOneWidget);
      expect(
        tester.state<ScrollableState>(scroll).position.pixels,
        greaterThan(0),
      );
      for (final product in remaining) {
        expect(
          find.descendant(
            of: grid,
            matching: find.byKey(ValueKey('buy-product-${product.id}')),
          ),
          findsOneWidget,
        );
      }
      final rects = [
        for (final product in remaining.take(4))
          tester.getRect(find.byKey(ValueKey('buy-product-${product.id}'))),
      ];
      expect(rects[1].top, closeTo(rects[0].top, .1));
      // The approved inline price/Add layout uses two readable columns here.
      expect(rects[1].left, greaterThan(rects[0].right));
      expect(rects[2].top, greaterThan(rects[0].bottom));
      expect(rects[2].left, closeTo(rects[0].left, .1));
      expect(rects[3].top, greaterThan(rects[1].bottom));
      expect(rects[3].left, closeTo(rects[1].left, .1));
      for (final rect in rects) {
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(360));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('single-product results show one complete vertical result', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.chooseShopSaleType(BuyV2ShopSaleType.courier);
    session.updateQuery('Rice and milk baby cereal');
    await tester.pumpAndSettle();

    expect(session.visibleProducts, hasLength(1));
    final product = session.visibleProducts.single;
    expect(find.byType(BuyV2ProductCard), findsOneWidget);
    final card = find.byKey(ValueKey('buy-product-${product.id}'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text(product.customerTitle)),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'buy-vertical-product-grid-',
            ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('140 percent text keeps navigation reachable', (tester) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final entry in const [
      (keyName: 'mool-compact-launcher', label: 'Mool'),
      (keyName: 'moolsocial-family-root-buy-tap', label: 'Shop'),
      (keyName: 'buy-local-tab-wholesale', label: 'Wholesale'),
      (keyName: 'buy-local-tab-orders', label: 'Orders'),
      (keyName: 'buy-local-tab-offers', label: 'Offers'),
      (keyName: 'mool-global-chat-tap', label: 'Chat'),
    ]) {
      final cell = find.byKey(ValueKey(entry.keyName));
      final visibleLabel = find.descendant(
        of: cell,
        matching: find.text(entry.label),
      );
      expect(cell, findsOneWidget);
      expect(visibleLabel, findsOneWidget);
      final cellRect = tester.getRect(cell);
      final labelRect = tester.getRect(visibleLabel);
      expect(cellRect.contains(labelRect.topLeft), isTrue, reason: entry.label);
      expect(
        cellRect.contains(labelRect.bottomRight),
        isTrue,
        reason: entry.label,
      );
      expect(
        labelRect.left,
        greaterThanOrEqualTo(cellRect.left + 2),
        reason: '${entry.label} left separation',
      );
      expect(
        labelRect.right,
        lessThanOrEqualTo(cellRect.right - 2),
        reason: '${entry.label} right separation',
      );
    }
  });

  testWidgets('accessible featured cards keep purchase actions in bounds', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    final product = session.visibleProducts.first;
    final card = tester.getRect(
      find.byKey(ValueKey('buy-product-${product.id}')),
    );
    final action = tester.getRect(
      find.byKey(ValueKey('buy-add-${product.id}')),
    );
    expect(action.height, 44);
    expect(action.width, greaterThanOrEqualTo(44));
    expect(card.contains(action.center), isTrue);
    expect(action.right, lessThanOrEqualTo(card.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('destination tool menus remain usable at 140 percent text', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    for (final entry in const [
      (BuyV2Destination.shop, 'returns'),
      (BuyV2Destination.wholesale, 'manufacturer'),
      (BuyV2Destination.medicine, 'manufacturer'),
    ]) {
      session.openDestination(entry.$1);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
      await tester.pumpAndSettle();
      if (entry.$1 != BuyV2Destination.medicine) {
        expect(
          find.byKey(const ValueKey('buy-discovery-refinement-title')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('buy-filter-lowest')), findsNothing);
        expect(
          find.byKey(const ValueKey('buy-sort-deliveryFastest')),
          findsNothing,
        );
        final sortSection = find.byKey(
          const ValueKey('buy-refine-section-sort'),
        );
        await tester.tap(
          find
              .descendant(of: sortSection, matching: find.byType(ListTile))
              .first,
        );
        await tester.pumpAndSettle();
        final sort = find.byKey(const ValueKey('buy-sort-priceLowToHigh'));
        await tester.scrollUntilVisible(
          sort,
          100,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('buy-discovery-refinement-list')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(sort);
        await tester.pumpAndSettle();
        expect(session.productSort, BuyV2ProductSort.relevance);
        await tester.tap(
          find.byKey(const ValueKey('buy-discovery-refinement-done')),
        );
        await tester.pumpAndSettle();
        expect(session.productSort, BuyV2ProductSort.priceLowToHigh);
        expect(session.catalogueSaleTypeProducts, isNotEmpty);
        expect(tester.takeException(), isNull);
        continue;
      }
      final option = find.byKey(ValueKey('buy-filter-${entry.$2}'));
      await tester.scrollUntilVisible(
        option,
        160,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('buy-filter-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(option, findsOneWidget);
      expect(tester.takeException(), isNull, reason: entry.$1.label);
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(session.selectedFilter, entry.$2);
      expect(session.visibleProducts, isNotEmpty);
    }
  });

  testWidgets('purchase and navigation actions meet the 44 pixel target', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final product = session.visibleProducts.first;

    final add = find.byKey(ValueKey('buy-add-${product.id}'));
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    expect(
      tester.getSize(find.byKey(const Key('mool-compact-launcher'))).height,
      greaterThanOrEqualTo(44),
    );
    for (final keyName in const [
      'mool-compact-launcher',
      'moolsocial-family-root-buy-tap',
      'buy-local-tab-wholesale',
      'buy-local-tab-orders',
      'buy-local-tab-offers',
      'mool-global-chat-tap',
    ]) {
      expect(
        tester.getSize(find.byKey(ValueKey(keyName))).height,
        greaterThanOrEqualTo(44),
      );
    }
  });

  testWidgets('critical Buy journeys fit compact and large phone widths', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(320, 568), Size(430, 932)]) {
      tester.view.physicalSize = size;
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      final shop = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      final medicine = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.medicine &&
            !item.requiresPrescription,
      );

      for (final action in <VoidCallback>[
        () => session.openDestination(BuyV2Destination.wholesale),
        () => session.openDestination(BuyV2Destination.medicine),
        () => session.openProduct(shop.id),
        () {
          session.addProduct(shop.id);
          session.addProduct(wholesale.id);
          session.addProduct(medicine.id);
          session.openCart();
        },
        session.openCheckout,
        session.openOrders,
        () => session.openTracking('MS-240782'),
        session.openAssist,
      ]) {
        action();
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'critical Buy view at $size',
        );
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
      }
    }
  });

  for (final scenario in [
    'missing', 'included', 'excluded', 'unknown', 'wrong-sku',
    'wrong-store', 'future', 'expired', 'stale',
  ]) {
    for (final scale in [1.0, 1.4]) {
      testWidgets('Batch01 Wholesale tax $scenario at text $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.reset);
        final now = DateTime.utc(2026, 10, 17, 12);
        final seed = BuyV2Catalogue.products.firstWhere(
          (product) => product.destination == BuyV2Destination.wholesale,
        );
        final product = seed.copyWith(
          storeId: 'batch01-store',
          packTerms: scenario == 'missing' ? null : BuyV2PackTerms(
            skuId: scenario == 'wrong-sku' ? 'another-sku' : seed.id,
            revision: 'batch01-host-terms',
            sellUnit: 'case',
            pricingStoreId: scenario == 'wrong-store' ? 'another-store' : 'batch01-store',
            priceObservedAt: scenario == 'future'
                ? now.add(const Duration(minutes: 1))
                : now.subtract(const Duration(hours: 1)),
            priceValidUntil: scenario == 'expired'
                ? now : now.add(const Duration(hours: 2)),
            pricesIncludeTax: scenario == 'unknown' ? null : scenario != 'excluded',
            priceTiers: [BuyV2PackPriceTier(
              minimumPacks: seed.minimumOrder, priceMinor: seed.priceMinor,
            )],
          ),
        );
        final session = _Batch01TaxSession(product, now, scenario == 'stale');
        addTearDown(session.core.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(app(session, textScale: scale));
        session.openProduct(product.id);
        await tester.pumpAndSettle();
        final expected = switch (scenario) {
          'included' => 'Tax included · Invoice not confirmed',
          'excluded' => 'Tax excluded · Invoice not confirmed',
          _ => 'Tax and invoice not confirmed',
        };
        await tester.scrollUntilVisible(
          find.text('Wholesale terms'), 180,
          scrollable: scrollableWithin(PageStorageKey('buy-product-${product.id}')),
        );
        expect(find.text('GST included · invoice provided'), findsNothing);
        expect(find.text('Tax & invoice'), findsOneWidget);
        expect(find.text(expected), findsOneWidget);
        await tester.ensureVisible(find.byKey(
          ValueKey('buy-wholesale-commercial-terms-${product.id}'),
        ));
        expect(tester.takeException(), isNull);
        if (scenario == 'missing') {
          await captureR66Visual(tester, 'batch01-tax-unconfirmed-$scale');
        }
      });
    }
  }

  testWidgets('product detail exposes purchase decision information', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.wholesale,
    );
    session.openProduct(product.id);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.wholesale,
          initialView: BuyV2View.product,
          productId: product.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(ValueKey('buy-product-purchase-hero-${product.id}')),
        matching: find.text(product.title),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('buy-product-inline-action-${product.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('buy-wholesale-action-dock-${product.id}')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-product-action-bar')), findsNothing);
    final productScrollable = scrollableWithin(
      PageStorageKey('buy-product-${product.id}'),
    );
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('buy-wholesale-trade-decision-${product.id}')),
      220,
      scrollable: productScrollable,
    );
    expect(
      find.byKey(ValueKey('buy-wholesale-price-summary-${product.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('buy-wholesale-trade-decision-${product.id}')),
      findsOneWidget,
    );
    final primary = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    expect(primary, findsOneWidget);
    expect(
      find.descendant(of: primary, matching: find.byIcon(Icons.add_rounded)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: primary, matching: find.text(product.title)),
      findsNothing,
    );
    expect(
      find.descendant(of: primary, matching: find.text('Add')),
      findsNothing,
    );
    expect(find.text('Buy now'), findsNothing);
  });

  for (final viewport in [const Size(320, 711), const Size(711, 320)]) {
    for (final scale in [1.0, 2.0]) {
      for (final editing in [false, true]) {
        testWidgets(
          'R669 address layout keeps focus and actions visible $viewport $scale edit $editing',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = viewport;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            final before = session.addresses.toList();
            final selected = session.selectedAddressId;
            await tester.pumpWidget(
              app(
                session,
                textScale: scale,
                safePadding: const EdgeInsets.only(top: 24, bottom: 24),
              ),
            );
            await tester.pumpAndSettle();
            unawaited(
              showBuyV2AddressSheet(
                tester.element(find.byType(BuyV2Screen)),
                session,
              ),
            );
            await tester.pumpAndSettle();
            Future<void> reveal(
              String target,
              String list, {
              double delta = 160,
            }) async {
              await tester.scrollUntilVisible(
                find.byKey(ValueKey(target)),
                delta,
                scrollable: find
                    .descendant(
                      of: find.byKey(ValueKey(list)),
                      matching: find.byType(Scrollable),
                    )
                    .first,
                maxScrolls: 50,
              );
              await tester.pumpAndSettle();
              expect(
                find.byKey(ValueKey(target)).hitTestable(),
                findsOneWidget,
              );
            }

            if (editing) {
              await reveal(
                'buy-address-actions-work',
                'buy-address-sheet-list',
              );
              await tester.tap(
                find.byKey(const ValueKey('buy-address-actions-work')),
              );
              await tester.pumpAndSettle();
              await tester.tap(
                find.byKey(const ValueKey('buy-address-edit-work')),
              );
            } else {
              await reveal('buy-address-add', 'buy-address-sheet-list');
              await tester.tap(find.byKey(const ValueKey('buy-address-add')));
            }
            await tester.pumpAndSettle();
            final firstType = find.byKey(
              const ValueKey('buy-address-add-kind-Home'),
            );
            final lastType = find.byKey(
              const ValueKey('buy-address-add-kind-Other place'),
            );
            if (scale == 1) {
              expect(
                tester.getRect(firstType).top,
                closeTo(tester.getRect(lastType).top, .1),
              );
            }
            for (final type in ['Home', 'Work', 'Third party', 'Other place']) {
              final key = 'buy-address-add-kind-$type';
              await reveal(key, 'buy-address-add-form-list');
              final chip = find.byKey(ValueKey(key));
              expect(tester.getSize(chip).height, greaterThanOrEqualTo(44));
              await tester.tap(chip);
              await tester.pumpAndSettle();
              expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
            }
            if (editing) {
              await reveal(
                'buy-address-add-kind-Home',
                'buy-address-add-form-list',
                delta: -160,
              );
              await captureR66Visual(
                tester,
                'r669-address-types-${viewport.width}-$scale',
              );
            }
            final keyboard = viewport.width > viewport.height ? 120.0 : 260.0;
            for (final field in const [
              ('recipient', 'Meera Sharma'),
              ('phone', '9876543210'),
              ('line', '24 Market Road'),
              ('area', 'Basni, Jodhpur'),
              ('pin', '342005'),
              ('landmark', 'Near school'),
            ]) {
              final id = 'buy-address-add-${field.$1}';
              await reveal(id, 'buy-address-add-form-list');
              final input = find.byKey(ValueKey(id));
              await tester.tap(input);
              await tester.pump();
              tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
              await tester.pumpAndSettle();
              await tester.enterText(input, field.$2);
              await tester.pumpAndSettle();
              final editable = tester.state<EditableTextState>(
                find.descendant(of: input, matching: find.byType(EditableText)),
              );
              final renderer = editable.renderEditable;
              final caret = renderer
                  .getLocalRectForCaret(TextPosition(offset: field.$2.length))
                  .shift(renderer.localToGlobal(Offset.zero));
              final visible = tester.getRect(
                find.byKey(const ValueKey('buy-address-add-form-list')),
              );
              expect(
                visible.bottom,
                lessThanOrEqualTo(viewport.height - keyboard + .1),
              );
              expect(
                caret.top,
                greaterThanOrEqualTo(visible.top - .1),
                reason: field.$1,
              );
              expect(
                caret.bottom,
                lessThanOrEqualTo(visible.bottom + .1),
                reason: field.$1,
              );
              expect(
                caret.bottom,
                lessThanOrEqualTo(viewport.height - keyboard),
                reason: field.$1,
              );
              if (editing && field.$1 == 'recipient') {
                await captureR66Visual(
                  tester,
                  'r669-address-keyboard-${viewport.width}-$scale',
                );
              }
              tester.testTextInput.hide();
              tester.view.viewInsets = FakeViewPadding.zero;
              await tester.pumpAndSettle();
            }
            await reveal('buy-address-add-submit', 'buy-address-add-form-list');
            final save = find.byKey(const ValueKey('buy-address-add-submit'));
            expect(tester.getSize(save).height, greaterThanOrEqualTo(44));
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: save, matching: find.byType(RichText)).first,
            );
            expect(paragraph.didExceedMaxLines, isFalse);
            expect(
              paragraph.localToGlobal(Offset.zero).dy + paragraph.size.height,
              lessThanOrEqualTo(tester.getRect(save).bottom + .1),
            );
            if (editing) {
              await captureR66Visual(
                tester,
                'r669-address-save-${viewport.width}-$scale',
              );
            }
            await tester.tap(save);
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('buy-address-add-form-route')),
              findsNothing,
            );
            expect(session.addresses.length, before.length + (editing ? 0 : 1));
            final saved = editing
                ? session.addresses.singleWhere((a) => a.id == 'work')
                : session.selectedAddress;
            expect(saved.recipient, 'Meera Sharma');
            expect(saved.phone, '9876543210');
            expect(saved.kind, BuyV2AddressKind.other);
            if (editing) expect(session.selectedAddressId, selected);
            expect(session.itemCount, 0);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final scale in [1.0, 2.0]) {
    for (final name in ['', 'Aarav Shah']) {
      testWidgets(
        'R669 address request preserves manual recipient $scale ${name.isEmpty ? 'blank' : 'named'}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 711);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          final originalAddresses = session.addresses.toList();
          final selected = session.selectedAddressId;
          await tester.pumpWidget(app(session, textScale: scale));
          await tester.pumpAndSettle();
          unawaited(
            showBuyV2AddressSheet(
              tester.element(find.byType(BuyV2Screen)),
              session,
            ),
          );
          await tester.pumpAndSettle();
          Future<void> reveal(
            String target,
            String list, {
            double delta = 200,
          }) async {
            await tester.scrollUntilVisible(
              find.byKey(ValueKey(target)),
              delta,
              scrollable: find
                  .descendant(
                    of: find.byKey(ValueKey(list)),
                    matching: find.byType(Scrollable),
                  )
                  .first,
              maxScrolls: 40,
            );
            await tester.pumpAndSettle();
            expect(find.byKey(ValueKey(target)).hitTestable(), findsOneWidget);
          }

          await reveal('buy-address-request', 'buy-address-sheet-list');
          await tester.tap(find.byKey(const ValueKey('buy-address-request')));
          await tester.pumpAndSettle();
          await reveal(
            'buy-address-request-recipient',
            'buy-address-request-form-list',
          );
          final requestName = find.byKey(
            const ValueKey('buy-address-request-recipient'),
          );
          await tester.enterText(requestName, name);
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          await reveal(
            'buy-address-request-enter-manually',
            'buy-address-request-form-list',
          );
          await tester.tap(
            find.byKey(const ValueKey('buy-address-request-enter-manually')),
          );
          await tester.pumpAndSettle();
          await reveal(
            'buy-address-add-recipient',
            'buy-address-add-form-list',
          );
          final manualName = find.byKey(
            const ValueKey('buy-address-add-recipient'),
          );
          expect(tester.widget<TextField>(manualName).controller!.text, name);
          if (name.isNotEmpty) {
            await captureR66Visual(tester, 'r669-address-recipient-$scale');
          }
          await tester.enterText(manualName, 'Changed draft');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await reveal(
            'buy-address-request-recipient',
            'buy-address-request-form-list',
            delta: -200,
          );
          expect(tester.widget<TextField>(requestName).controller!.text, name);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.addresses, originalAddresses);
          expect(session.selectedAddressId, selected);
          expect(session.itemCount, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final viewport in [const Size(320, 711), const Size(711, 320)]) {
    testWidgets('R665 D04 enlarged SKU excludes post-purchase actions at $viewport', (tester) async {
      tester.view.devicePixelRatio = 1; tester.view.physicalSize = viewport;
      addTearDown(tester.view.reset);
      final core = BuySession(), session = BuyV2Session(core: core);
      addTearDown(core.dispose); addTearDown(session.dispose);
      await tester.pumpWidget(app(session, textScale: 2,
        safePadding: const EdgeInsets.only(top: 24, bottom: 24)));
      await tester.pumpAndSettle();
      final before = session.itemCount;
      const productId = 's-tomato';
      session.openProduct(productId); await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-product-reviews-s-tomato')), findsNothing);
      expect(find.byKey(const ValueKey('buy-report-product-s-tomato')), findsNothing);
      expect(find.byKey(const ValueKey('buy-review-product-s-tomato')), findsNothing);
      expect(find.byKey(const ValueKey('buy-product-review-sheet')), findsNothing);
      expect(session.hasReportedProduct(productId), isFalse);
      expect(session.selectedProduct?.id, productId); expect(session.view, BuyV2View.product);
      expect(session.itemCount, before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'product detail uses automatic fulfilment without post-purchase actions',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      session.openProduct(product.id);
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('buy-product-packshot-${product.id}')),
        findsOneWidget,
      );
      final productScrollable = scrollableWithin(
        PageStorageKey('buy-product-${product.id}'),
      );
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}')),
        220,
        scrollable: productScrollable,
      );
      expect(find.textContaining(product.seller), findsWidgets);
      expect(find.textContaining('Verified'), findsNothing);

      expect(find.byKey(ValueKey('buy-product-reviews-${product.id}')), findsNothing);
      expect(find.byKey(ValueKey('buy-review-product-${product.id}')), findsNothing);
      expect(find.byKey(ValueKey('buy-report-product-${product.id}')), findsNothing);
      expect(find.byKey(const ValueKey('buy-product-review-sheet')), findsNothing);
      expect(session.hasReportedProduct(product.id), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final testCase in const [
    (productId: 's-tomato', minutes: 12),
    (productId: 's-noodles', minutes: 18),
  ]) {
    testWidgets(
      'R66 019 Quick category retains ${testCase.minutes} minute product and Cart promise',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final product = session.product(testCase.productId);
        expect(product.deliveryPromise, 'Delivery in ${testCase.minutes} min');
        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();
        final selector = find.byKey(
          const ValueKey('buy-shop-sale-type-selector'),
        );
        expect(
          find.descendant(of: selector, matching: find.text('Quick')),
          findsOneWidget,
        );
        expect(find.text('Quick 10m'), findsNothing);
        expect(
          tester.widget<Semantics>(selector).properties.label,
          'Choose Quick or scheduled Shop products',
        );
        await tester.tap(
          find.byKey(const ValueKey('buy-shop-sale-type-courier')),
        );
        await tester.pumpAndSettle();
        expect(session.shopSaleType, BuyV2ShopSaleType.courier);
        await tester.tap(
          find.byKey(const ValueKey('buy-shop-sale-type-quick')),
        );
        await tester.pumpAndSettle();
        expect(session.shopSaleType, BuyV2ShopSaleType.quickDelivery);
        session.openProduct(product.id);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}')),
          220,
          scrollable: scrollableWithin(
            PageStorageKey('buy-product-${product.id}'),
          ),
        );
        expect(find.text('Delivery in ${testCase.minutes} min'), findsWidgets);
        expect(session.addProduct(product.id), isTrue);
        session.openCart();
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(ValueKey('buy-cart-product-summary-${product.id}')),
            matching: find.textContaining(
              'Delivery in ${testCase.minutes} min',
            ),
          ),
          findsOneWidget,
        );
        expect(session.quantityFor(product.id), 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'B01 T02 keeps one product while server promises 3 5 and 10 minutes',
    (tester) async {
      for (final testCase in const [
        (productId: 's-oil', destination: BuyV2Destination.shop, minutes: 3),
        (productId: 's-tomato', destination: BuyV2Destination.shop, minutes: 5),
        (
          productId: 'w-oil',
          destination: BuyV2Destination.wholesale,
          minutes: 10,
        ),
      ]) {
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          productFactsAdapter: _FixedDeliveryPromiseFactsAdapter(
            'within ${testCase.minutes} min',
          ),
        );
        final product = session.product(testCase.productId);

        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();
        session.openDestination(testCase.destination);
        session.openProduct(product.id);
        await tester.pumpAndSettle();
        final productScrollable = scrollableWithin(
          PageStorageKey('buy-product-${product.id}'),
        );
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}')),
          220,
          scrollable: productScrollable,
        );

        expect(find.text('Delivery in ${testCase.minutes} min'), findsWidgets);
        expect(find.textContaining(product.seller), findsWidgets);
        expect(
          find.byKey(ValueKey('buy-shop-seller-action-${product.id}')),
          testCase.destination == BuyV2Destination.shop
              ? findsOneWidget
              : findsNothing,
        );
        expect(
          find.byKey(ValueKey('buy-wholesale-supplier-action-${product.id}')),
          findsNothing,
        );

        expect(session.addProduct(product.id), isTrue);
        session.openCart();
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Delivery in ${testCase.minutes} min'),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(ValueKey('buy-cart-line-${product.id}')),
            matching: find.text(product.seller),
          ),
          findsOneWidget,
        );
        expect(session.quantityFor(product.id), product.minimumOrder);
        expect(session.cartTotal, product.price * product.minimumOrder);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        session.dispose();
        core.dispose();
      }
    },
  );

  test(
    'B01 T02 promise copy fails closed for checking stale and unavailable',
    () {
      final product = BuyV2Catalogue.products;
      final base = const BuyV2CatalogueProductFactsAdapter().snapshotFor(
        product.first,
      );
      expect(
        buyV2BuyerDeliveryPromise(
          base.copyWith(orderabilityLabel: 'Checking serviceability'),
        ),
        'Checking delivery time',
      );
      expect(
        buyV2BuyerDeliveryPromise(base.copyWith(stale: true)),
        'Delivery time needs review',
      );
      expect(
        buyV2BuyerDeliveryPromise(
          base.copyWith(orderabilityLabel: 'Currently unavailable'),
        ),
        'Currently unavailable',
      );
      for (final missing in ['', 'Delivery time confirmed at checkout']) {
        final facts = base.copyWith(deliveryPromise: missing);
        expect(
          buyV2BuyerDeliveryPromise(facts, confirmAfterStoreAcceptance: true),
          'Delivery schedule unavailable',
        );
        expect(facts.deliveryPromise, missing);
      }
      expect(
        buyV2BuyerDeliveryPromise(base, confirmAfterStoreAcceptance: true),
        buyV2BuyerDeliveryPromise(base),
        reason: 'Keep the genuine supplier estimate.',
      );
      for (final (facts, expected) in [
        (base.copyWith(stale: true), 'Delivery time needs review'),
        (
          base.copyWith(orderabilityLabel: 'Checking serviceability'),
          'Checking delivery time',
        ),
        (
          base.copyWith(orderabilityLabel: 'Currently unavailable'),
          'Currently unavailable',
        ),
      ]) {
        expect(
          buyV2BuyerDeliveryPromise(facts, confirmAfterStoreAcceptance: true),
          expected,
        );
      }
      expect(
        buyV2DeliveryPromiseSummary(
          promise: 'Delivery time confirmed at checkout',
        ),
        'Delivery time confirmed at checkout',
        reason: 'Recorded order promises are not rewritten by public copy.',
      );
    },
  );

  testWidgets('packshot atlas isolates one exact cell per product', (
    tester,
  ) async {
    final tomato = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.shop &&
          item.canonicalId == 'tomato',
    );
    final rice = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.shop &&
          item.canonicalId == 'rice',
    );
    final medicine = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          item.visualKind == 'medicine-box',
    );
    final milk = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.shop &&
          item.title.toLowerCase().contains('milk'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            for (final product in [tomato, rice, medicine, milk])
              SizedBox(
                width: 128,
                height: 192,
                child: BuyV2ProductPackshot(product: product),
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    Positioned cellFor(BuyV2Product product) {
      final source = BuyV2ProductPackshot.resolveMedia(product)!;
      return tester.widget<Positioned>(
        find.byKey(
          ValueKey(
            'buy-packshot-sprite-${product.id}-'
            '${source.assetPath}-${source.cell}',
          ),
        ),
      );
    }

    final tomatoCell = cellFor(tomato);
    final riceCell = cellFor(rice);
    final medicineCell = cellFor(medicine);
    final milkCell = cellFor(milk);
    expect(tomatoCell.left! / tomatoCell.width!, closeTo(-16 / 1536, .0001));
    expect(tomatoCell.top! / tomatoCell.height!, closeTo(-56 / 1024, .0001));
    expect(riceCell.left! / riceCell.width!, closeTo(-432 / 1536, .0001));
    expect((medicineCell.left, medicineCell.top), (0, 0));
    expect(milkCell.left! / milkCell.width!, closeTo(-810 / 1536, .0001));
    expect(milkCell.top! / milkCell.height!, closeTo(-374 / 1024, .0001));
    for (final cell in [tomatoCell, riceCell, medicineCell, milkCell]) {
      expect(
        cell.width! / cell.height!,
        closeTo(identical(cell, medicineCell) ? 4 / 3 : 1.5, .0001),
        reason: 'Atlas pixels must not stretch to the thumbnail aspect ratio',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'every seeded product resolves to exact or truthful category media',
    (tester) async {
      final eggs = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.shop &&
            item.canonicalId == 'eggs',
      );
      final resolutions = {
        for (final product in BuyV2Catalogue.products)
          product.id: BuyV2ProductPackshot.resolveMedia(product),
      };
      expect(resolutions.values, isNot(contains(null)));
      expect(
        resolutions.values.where(
          (source) => source?.kind == BuyV2ProductMediaKind.exactProduct,
        ),
        isNotEmpty,
      );
      expect(
        resolutions.values.where(
          (source) => source?.kind == BuyV2ProductMediaKind.category,
        ),
        isNotEmpty,
      );
      final eggsSource = resolutions[eggs.id]!;
      expect(eggsSource.kind, BuyV2ProductMediaKind.category);
      expect(eggsSource.assetPath, BuyV2ProductPackshot.categoryAtlasAPath);
      expect(eggsSource.cell, 2);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 86,
            height: 64,
            child: BuyV2ProductPackshot(product: eggs),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('buy-product-media-fallback-${eggs.id}')),
        findsNothing,
      );
      expect(
        find.byKey(
          ValueKey(
            'buy-packshot-sprite-${eggs.id}-'
            '${eggsSource.assetPath}-${eggsSource.cell}',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'featured products keep compact photos and readable filtered cards',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      final product = session.visibleProducts.first;
      final photo = find.byKey(ValueKey('buy-featured-packshot-${product.id}'));
      expect(photo, findsOneWidget);
      expect(tester.getSize(photo).width, greaterThanOrEqualTo(44));
      expect(
        tester.getRect(photo).right,
        lessThanOrEqualTo(
          tester
              .getRect(find.byKey(ValueKey('buy-product-${product.id}')))
              .right,
        ),
      );
      final addRect = tester.getRect(
        find.byKey(ValueKey('buy-add-${product.id}')),
      );
      final photoRect = tester.getRect(photo);
      expect(photoRect.height, greaterThan(addRect.height));
      expect(photoRect.bottom, lessThanOrEqualTo(addRect.top));

      await tester.tap(find.byKey(ValueKey('buy-add-${product.id}')));
      await tester.pumpAndSettle();
      expect(session.quantityFor(product.id), 1);
      expect(
        find.byKey(ValueKey('buy-quantity-${product.id}')),
        findsOneWidget,
      );

      session.chooseCategory(product.categoryId);
      await tester.pumpAndSettle();
      final densePhoto = find.byKey(
        ValueKey('buy-grid-packshot-${product.id}'),
      );
      expect(densePhoto, findsOneWidget);
      final denseSize = tester.getSize(densePhoto);
      expect(denseSize.width, greaterThanOrEqualTo(44));
      expect(denseSize.height, denseSize.width);
      final denseCard = tester.getRect(
        find.byKey(ValueKey('buy-product-${product.id}')),
      );
      expect(
        tester.getRect(densePhoto).left,
        greaterThanOrEqualTo(denseCard.left),
      );
      expect(
        tester.getRect(densePhoto).right,
        lessThanOrEqualTo(denseCard.right),
      );
      expect(session.quantityFor(product.id), 1);
      expect(find.byType(BuyV2ProductCard), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('featured press and quantity motion respect reduced motion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();

    final product = session.visibleProducts.first;
    final animatedCard = find.byKey(
      ValueKey('buy-featured-product-${product.id}'),
    );
    expect(tester.widget<AnimatedScale>(animatedCard).duration, Duration.zero);

    await tester.tap(find.byKey(ValueKey('buy-add-${product.id}')));
    await tester.pump();
    expect(session.quantityFor(product.id), 1);
    expect(find.byKey(ValueKey('buy-quantity-${product.id}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product detail keeps a large upload-ready media tile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openProduct(product.id);
    await tester.pumpAndSettle();

    final gallery = find.byKey(ValueKey('buy-product-gallery-${product.id}'));
    final firstImage = find.byKey(
      const ValueKey('buy-product-gallery-image-0'),
    );
    expect(gallery, findsOneWidget);
    expect(tester.getSize(firstImage).width, greaterThanOrEqualTo(270));
    expect(tester.getSize(firstImage).height, greaterThanOrEqualTo(180));
    expect(
      find.byKey(const ValueKey('buy-product-gallery-count')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-product-gallery-dot-0')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tracking Items opens an order item and returns to that order', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final selectedProduct = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    expect(session.addProduct(selectedProduct.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    final order = session.confirmedOrders.single;
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openTracking(order.id);
    await tester.pumpAndSettle();

    final invoiceAction = find.byKey(
      ValueKey('buy-tracking-invoice-${order.id}'),
    );
    await tester.scrollUntilVisible(
      invoiceAction,
      220,
      scrollable: scrollableWithin(PageStorageKey('buy-tracking-${order.id}')),
    );
    await tester.tap(invoiceAction);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('buy-invoice-page-${order.id}')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, order.id);

    final itemsAction = find.text('Items');
    await tester.scrollUntilVisible(
      itemsAction,
      220,
      scrollable: scrollableWithin(PageStorageKey('buy-tracking-${order.id}')),
    );
    await tester.tap(itemsAction);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.orderItems);
    expect(find.byKey(ValueKey('buy-order-items-${order.id}')), findsOneWidget);
    final product = session.productsForOrder(session.selectedOrder).first;
    await tester.tap(find.byKey(ValueKey('buy-order-product-${product.id}')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, product.id);

    session.goBack();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.orderItems);
    expect(session.selectedOrder.id, order.id);
  });

  testWidgets(
    'Shop Wholesale and Medicine details fit compact Android and iOS sizes',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      for (final viewport in const [
        Size(320, 568),
        Size(390, 844),
        Size(430, 932),
      ]) {
        tester.view.physicalSize = viewport;
        for (final destination in const [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        ]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          final session = BuyV2Session(core: BuySession());
          final product = BuyV2Catalogue.products.firstWhere(
            (item) =>
                item.destination == destination && !item.requiresPrescription,
          );
          await tester.pumpWidget(app(session, textScale: 1.4));
          await tester.pumpAndSettle();
          session.openProduct(product.id);
          await tester.pumpAndSettle();

          expect(
            find.byKey(ValueKey('buy-product-packshot-${product.id}')),
            findsOneWidget,
            reason: '$destination at $viewport',
          );
          final productScrollable = scrollableWithin(
            PageStorageKey('buy-product-${product.id}'),
          );
          final decisionOwner = destination == BuyV2Destination.medicine
              ? find.text(product.partnerRole)
              : find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}'));
          await tester.scrollUntilVisible(
            decisionOwner,
            140,
            scrollable: productScrollable,
          );
          expect(
            decisionOwner,
            findsOneWidget,
            reason: '$destination at $viewport',
          );
          expect(find.textContaining('Verified'), findsNothing);
          expect(find.byKey(ValueKey('buy-product-reviews-${product.id}')), findsNothing);
          expect(find.byKey(ValueKey('buy-review-product-${product.id}')), findsNothing);
          expect(find.byKey(ValueKey('buy-report-product-${product.id}')), findsNothing);
          expect(
            tester.takeException(),
            isNull,
            reason: '$destination at $viewport',
          );
        }
      }
    },
  );

  testWidgets('Account and shared Chat preserve the exact purchase depth', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var chatOpens = 0;
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.wholesale,
    );
    await tester.pumpWidget(app(session, onOpenChat: () => chatOpens += 1));
    session.openProduct(product.id);
    await tester.pumpAndSettle();

    session.openAccount();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.account);
    session.closeAccount();
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, product.id);

    session.openTracking('MS-240782');
    await tester.pumpAndSettle();
    final trackingHelp = find.byKey(const ValueKey('buy-tracking-help'));
    final trackingScroll = scrollableWithin(
      const PageStorageKey('buy-tracking-MS-240782'),
    );
    await tester.scrollUntilVisible(
      trackingHelp,
      180,
      scrollable: trackingScroll,
    );
    await tester.drag(trackingScroll, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(trackingHelp);
    await tester.pumpAndSettle();
    expect(chatOpens, 1);
    expect(session.destination, BuyV2Destination.orders);
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240782');
  });

  for (final verified in [false, true]) {
    testWidgets('LF08 account business status never invents a business identity $verified', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();
      session.businessVerified = verified;
      session.openAccount();
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('buy-account-workspace'));
      await tester.ensureVisible(action);
      expect(find.descendant(of: action, matching: find.textContaining('Shree Balaji')), findsNothing);
      expect(find.descendant(of: action, matching: find.text(
        verified ? 'Business verification confirmed' : 'Business profile required')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Account Orders and Wholesale actions complete and return', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.openAccount();
    await tester.pumpAndSettle();
    expect(find.textContaining('Verified'), findsNothing);
    expect(find.textContaining('VERIFIED'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('buy-account-orders')));
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.orders);
    expect(session.canReturnToAccount, isTrue);
    final ordersReturn = find.byKey(
      const ValueKey('buy-orders-return-account'),
    );
    await tester.tapAt(tester.getTopLeft(ordersReturn) + const Offset(24, 20));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.account);

    final wholesaleWorkspace = find.byKey(
      const ValueKey('buy-account-workspace'),
    );
    await tester.ensureVisible(wholesaleWorkspace);
    await tester.tap(wholesaleWorkspace);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(session.view, BuyV2View.catalogue);
    expect(
      find.byKey(const ValueKey('buy-catalogue-return-account')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-catalogue-return-account')),
    );
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.account);

    session.closeAccount();
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.shop);
    expect(session.view, BuyV2View.catalogue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each Buy category exposes products through vertical scrolling', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      session.openDestination(destination);
      final category = session.categories.firstWhere(
        (item) => item.id != 'all',
      );
      session.chooseCategory(category.id);
      await tester.pumpAndSettle();

      final grid = find.byKey(
        ValueKey(
          'buy-vertical-product-grid-buy-products-${destination.name}-${category.id}-all',
        ),
      );
      expect(grid, findsOneWidget, reason: destination.name);
      final scrollable = find
          .ancestor(of: grid, matching: find.byType(Scrollable))
          .first;
      expect(
        tester.state<ScrollableState>(scrollable).position.axis,
        Axis.vertical,
        reason: destination.name,
      );
      for (final product in session.catalogueSaleTypeProducts) {
        expect(
          find.descendant(
            of: grid,
            matching: find.byKey(ValueKey('buy-product-${product.id}')),
          ),
          findsOneWidget,
          reason: '${destination.name}/${product.id}',
        );
      }
      expect(tester.takeException(), isNull, reason: destination.name);
    }
  });

  testWidgets('catalogue plus becomes an inline quantity stepper and returns', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final product = session.visibleProducts.first;
    final add = find.byKey(ValueKey('buy-add-${product.id}'));

    expect(find.text('ADD'), findsNothing);
    expect(
      find.descendant(of: add, matching: find.byIcon(Icons.add_rounded)),
      findsOneWidget,
    );
    await tester.tap(add);
    await tester.pumpAndSettle();
    final quantity = find.byKey(ValueKey('buy-quantity-${product.id}'));
    expect(quantity, findsOneWidget);
    expect(session.quantityFor(product.id), 1);

    await tester.tap(
      find
          .descendant(
            of: find.byKey(ValueKey('buy-product-${product.id}')),
            matching: find.byTooltip('Remove from Cart'),
          )
          .hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 0);
    expect(add, findsOneWidget);
  });

  testWidgets('product and Cart keep plus and minus quantity controls', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    session.openProduct(product.id);
    await tester.pumpAndSettle();

    final primary = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    final productScroll = find
        .descendant(
          of: find.byKey(PageStorageKey('buy-product-${product.id}')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(primary, 180, scrollable: productScroll);
    await tester.pumpAndSettle();
    await tester.tap(primary);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('buy-product-quantity-${product.id}')),
      findsOneWidget,
    );

    session.openCart(scope: BuyV2CartScope.shop);
    await tester.pumpAndSettle();
    final line = find.byKey(ValueKey('buy-cart-line-${product.id}'));
    expect(line, findsOneWidget);
    await tester.tap(
      find.descendant(of: line, matching: find.byTooltip('Add one')),
    );
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 2);
    await tester.tap(
      find.descendant(of: line, matching: find.byTooltip('Remove one')),
    );
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 1);
  });

  testWidgets('add confirmation is owned by the Cart bar, not the top toast', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );

    session.addProduct(product.id);
    await tester.pump();

    expect(session.notice, isNull);
    expect(session.cartAcknowledgement, '${product.title} added');
    expect(
      find.byKey(const ValueKey('buy-cart-navigation-button')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('buy-cart-navigation-button')),
        matching: find.byIcon(Icons.shopping_cart_outlined),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('buy-compact-cart-indicator')),
          )
          .label,
      contains(session.cartAcknowledgement!),
    );
    expect(find.byKey(const ValueKey('buy-live-notice')), findsNothing);
  });

  testWidgets('non-empty Cart becomes a compact conversion control', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('buy-navigation-overlay-stack'));
    final surfaceHeight = tester.getSize(surface).height;

    session.addProduct(product.id);
    await tester.pump();

    final miniCart = find.byKey(const ValueKey('buy-compact-cart-indicator'));
    expect(miniCart, findsOneWidget);
    expect(tester.getSize(surface).height, surfaceHeight);
    expect(tester.getSize(miniCart), const Size(44, 44));
    expect(
      find.byKey(const ValueKey('buy-cart-navigation-button')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('buy-cart-navigation-button')),
        matching: find.byIcon(Icons.shopping_cart_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: miniCart, matching: find.text('1')),
      findsOneWidget,
    );
    expect(tester.getSemantics(miniCart).label, contains('1 item'));
    expect(
      tester.getSemantics(miniCart).label,
      contains(buyV2Money(product.price)),
    );
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: miniCart,
        matching: find.byIcon(Icons.shopping_cart_outlined),
      ),
      findsOneWidget,
    );
    expect(tester.getSemantics(miniCart).label, contains('1 item ready'));

    final initialRect = tester.getRect(miniCart);
    await tester.drag(
      find.byKey(const ValueKey('buy-mini-cart-drag-handle')),
      const Offset(-100, -120),
    );
    await tester.pumpAndSettle();
    final movedRect = tester.getRect(miniCart);
    final surfaceRect = tester
        .getRect(find.byKey(const Key('moolsocial-compact-destination-rail')))
        .inflate(.1);
    expect(movedRect, initialRect);
    expect(surfaceRect.contains(movedRect.topLeft), isTrue);
    expect(surfaceRect.contains(movedRect.bottomRight), isTrue);

    await tester.tap(miniCart);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(miniCart.hitTestable(), findsOneWidget);
    expect(tester.getSize(miniCart), const Size(44, 44));
    expect(tester.widget<Semantics>(miniCart).properties.selected, isTrue);
    final cartQuantity = session.quantityFor(product.id);
    final cartTotal = session.cartTotal;
    await tester.tap(miniCart);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(session.quantityFor(product.id), cartQuantity);
    expect(session.cartTotal, cartTotal);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'R66 fixed Cart ignores repeated pointer movement and still opens',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      session.addProduct('s-tomato');
      session.clearCartAcknowledgement();
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final cart = find.byKey(const ValueKey('buy-mini-cart-drag-handle'));
      final gesture = await tester.startGesture(tester.getCenter(cart));
      await gesture.moveBy(const Offset(-30, -30));
      await tester.pump();
      final before = tester.getTopLeft(cart);
      for (var update = 0; update < 5; update++) {
        await gesture.moveBy(const Offset(-8, -12));
      }
      await tester.pump();
      expect(tester.getTopLeft(cart).dx, closeTo(before.dx, .1));
      expect(tester.getTopLeft(cart).dy, closeTo(before.dy, .1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
      await tester.tap(cart);
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.shop);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('R66 store cart only intercepts its visible compact control', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    session.addProduct('s-tomato');
    var opened = 0;
    var background = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => background++,
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: BuyV2StoreCartBar(
                  session: session,
                  destination: BuyV2Destination.shop,
                  onOpenCart: () => opened++,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bar = find.byKey(const ValueKey('buy-store-cart-bar'));
    await tester.tapAt(Offset(12, tester.getCenter(bar).dy));
    expect(background, 1);
    expect(opened, 0);
    expect(tester.getSize(bar).width, lessThan(300));
    await tester.tap(bar);
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  bool expectCartSummary(WidgetTester tester, int count, int total) {
    final summary = '$count ${count == 1 ? 'item' : 'items'}';
    final indicator = find.byKey(const ValueKey('buy-compact-cart-indicator'));
    final parked = find.byKey(const ValueKey('buy-cart-navigation-button'));
    if (parked.evaluate().isNotEmpty) {
      expect(parked.hitTestable(), findsOneWidget);
      expect(tester.getSize(parked), const Size(44, 44));
      final tooltip = tester.widget<Tooltip>(
        find.descendant(of: indicator, matching: find.byType(Tooltip)),
      );
      expect(tooltip.message, contains(summary));
      expect(tooltip.message, contains(buyV2Money(total)));
      expect(tester.getSemantics(indicator).label, tooltip.message);
      return true;
    }
    expect(
      tester
          .widget<BuyV2FiniteValueTransition>(
            find.byKey(const ValueKey('buy-cart-summary')),
          )
          .text,
      summary,
    );
    expect(
      tester
          .widget<BuyV2FiniteValueTransition>(
            find.byKey(const ValueKey('buy-cart-total')),
          )
          .text,
      buyV2Money(total),
    );
    return false;
  }

  for (final total in [1, 10000, 10000000, 1000000000]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R66 cart display fixture INR$total fits complete text at $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(360, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final session = _R66CartDisplayFixture(total);
          expect(session.cartTotalMinor, total * 100);
          expect(session.totalMinorForDestination(BuyV2Destination.wholesale), total * 100);
          addTearDown(session.dispose);
          session.addProduct('w-notebook');
          session.clearCartAcknowledgement();
          await tester.pumpWidget(
            app(
              session,
              textScale: scale,
              captureCart: const bool.fromEnvironment('BUY_R66_CART_CAPTURE'),
            ),
          );
          await tester.pumpAndSettle();
          session.openDestination(BuyV2Destination.wholesale);
          await tester.pumpAndSettle();
          await _captureR66Cart(tester, 'root-inr$total-text$scale');
          final cartRect = tester.getRect(
            find.byKey(const ValueKey('buy-mini-cart-drag-handle')),
          );
          final contentRect = tester.getRect(
            find.byKey(const ValueKey('buy-cart-content-viewport')),
          );
          for (final promotion in find.byType(BuyV2PromotionCard).evaluate()) {
            final visible = tester
                .getRect(
                  find.byElementPredicate((element) => element == promotion),
                )
                .intersect(contentRect);
            if (visible.width > 0 && visible.height > 0) {
              expect(cartRect.overlaps(visible), isFalse);
            }
          }
          final parked = expectCartSummary(
            tester,
            session.countForDestination(BuyV2Destination.wholesale),
            total,
          );
          if (parked) {
            final tooltip = find.descendant(
              of: find.byKey(const ValueKey('buy-compact-cart-indicator')),
              matching: find.byType(Tooltip),
            );
            await tester.longPress(
              find.byKey(const ValueKey('buy-cart-navigation-button')),
            );
            await tester.pumpAndSettle();
            final message = find.text(tester.widget<Tooltip>(tooltip).message!);
            expect(message, findsOneWidget);
            expect(
              tester.renderObject<RenderParagraph>(message).didExceedMaxLines,
              isFalse,
            );
          }
          for (final key
              in parked ? <String>[] : ['buy-cart-summary', 'buy-cart-total']) {
            final value = tester.widget<BuyV2FiniteValueTransition>(
              find.byKey(ValueKey(key)),
            );
            final painter = TextPainter(
              text: TextSpan(
                text: value.text,
                style: value.style.copyWith(fontFamily: 'Inter'),
              ),
              textDirection: TextDirection.ltr,
              textScaler: TextScaler.linear(scale),
              maxLines: 1,
            )..layout();
            expect(
              value.ownerSize.height,
              greaterThanOrEqualTo(painter.height),
            );
            expect(value.ownerSize.width, greaterThanOrEqualTo(painter.width));
            painter.dispose();
          }
          expect(
            tester
                .getSize(
                  find.byKey(const ValueKey('buy-compact-cart-indicator')),
                )
                .width,
            lessThanOrEqualTo(344),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: const bool.fromEnvironment('BUY_R66_CART_CAPTURE')
                    ? RepaintBoundary(
                        key: const ValueKey('r66-cart-capture'),
                        child: child!,
                      )
                    : r66VisualCaptureRoot(child!),
              ),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomRight,
                  child: BuyV2StoreCartBar(
                    session: session,
                    destination: BuyV2Destination.wholesale,
                    onOpenCart: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final store = find.byKey(const ValueKey('buy-store-cart-bar'));
          await _captureR66Cart(tester, 'store-inr$total-text$scale');
          final amount = find.byKey(const ValueKey('buy-store-cart-total'));
          expect(tester.widget<Text>(amount).data, buyV2Money(total));
          expect(
            tester.renderObject<RenderParagraph>(amount).didExceedMaxLines,
            isFalse,
          );
          expect(
            tester.getRect(store).contains(tester.getTopLeft(amount)),
            isTrue,
          );
          expect(
            tester.getBottomRight(amount).dy,
            lessThanOrEqualTo(tester.getRect(store).bottom),
          );
          expect(tester.getSize(store).width, lessThanOrEqualTo(344));
          expect(tester.getSize(store).height, greaterThanOrEqualTo(44));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Cart stays destination-scoped in Shop and Wholesale and aggregate in Orders',
    (tester) async {
      // Historical ledger name retained. Public discovery now previews the
      // existing mixed Cart; Store procurement and Care remain scoped below.
      final session = BuyV2Session(core: BuySession());
      final shop = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      final medicine = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.medicine &&
            !item.requiresPrescription,
      );
      session.addProduct(shop.id);
      session.addProduct(wholesale.id);
      session.addProduct(medicine.id);
      session.clearCartAcknowledgement();
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      session.openDestination(BuyV2Destination.wholesale);
      await tester.pumpAndSettle();
      expectCartSummary(tester, session.itemCount, session.cartTotal);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('buy-compact-cart-indicator')),
            )
            .label,
        contains(
          '${session.itemCount} '
          '${session.itemCount == 1 ? 'item' : 'items'} ready',
        ),
      );
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('buy-compact-cart-indicator')),
            )
            .label,
        contains(buyV2Money(session.cartTotal)),
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-compact-cart-indicator')),
      );
      await tester.pumpAndSettle();
      expect(session.cartScope, BuyV2CartScope.wholesale);
      expect(session.cartLines, hasLength(3));

      session.openDestination(BuyV2Destination.orders);
      await tester.pumpAndSettle();
      expectCartSummary(tester, session.itemCount, session.cartTotal);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('buy-compact-cart-indicator')),
            )
            .label,
        contains(
          '${session.itemCount} '
          '${session.itemCount == 1 ? 'item' : 'items'} ready',
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-compact-cart-indicator')),
      );
      await tester.pumpAndSettle();
      expect(session.cartScope, BuyV2CartScope.all);
      expect(session.cartLines, hasLength(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('T01A Cart hides Medicine in Shop and preserves Care Medicine', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == destination && !item.requiresPrescription,
      );
      session.addProduct(product.id);
    }
    session.openDestination(BuyV2Destination.wholesale);
    session.openCart(scope: BuyV2CartScope.wholesale);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.text('Medicine'), findsNothing);

    session.openDestination(BuyV2Destination.medicine);
    session.openCart(scope: BuyV2CartScope.medicine);
    await tester.pumpAndSettle();
    expect(find.text('Medicine'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Care Medicine never exposes an unrelated Shop basket', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final shop = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    final medicine = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          !item.requiresPrescription,
    );
    session.addProduct(shop.id);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openDestination(BuyV2Destination.medicine);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-compact-cart-indicator')),
      findsNothing,
    );

    session.addProduct(medicine.id);
    await tester.pumpAndSettle();
    final miniCart = find.byKey(const ValueKey('buy-compact-cart-indicator'));
    expect(miniCart, findsOneWidget);
    expect(
      tester.getSemantics(miniCart).label,
      contains(buyV2Money(medicine.price)),
    );
    expect(
      tester.getSemantics(miniCart).label,
      isNot(contains(buyV2Money(shop.price + medicine.price))),
    );

    await tester.tap(miniCart);
    await tester.pumpAndSettle();
    expect(session.cartScope, BuyV2CartScope.medicine);
    expect(session.cartLines, hasLength(1));
    expect(session.cartLines.single.product.id, medicine.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact Buy surface and Cart total remain whole at 320 and 140 percent',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      final products = BuyV2Catalogue.products
          .where((item) => item.destination == BuyV2Destination.shop)
          .take(2);
      for (final product in products) {
        session.addProduct(product.id);
      }
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('buy-change-location')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('buy-search-band'))).dy,
        tester.getBottomLeft(find.byType(BuyV2DemoCatalogueLabel)).dy,
      );

      session.openCart();
      await tester.pumpAndSettle();
      final actionBar = find.byKey(const ValueKey('buy-cart-action-bar'));
      final total = find.descendant(
        of: actionBar,
        matching: find.text(buyV2Money(session.scopedCartTotal)),
      );
      expect(total, findsOneWidget);
      expect(tester.widget<Text>(total).maxLines, 1);
      final actionRect = tester.getRect(actionBar);
      final totalRect = tester.getRect(total);
      expect(actionRect.contains(totalRect.topLeft), isTrue);
      expect(actionRect.contains(totalRect.bottomRight), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('saved destination and payment remain separate decisions', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.addProduct(product.id);
    session.openCheckout();
    session.clearNotice();
    await tester.pumpAndSettle();
    final quantity = session.quantityFor(product.id);
    final total = session.cartTotal;
    final payment = session.selectedPayment;
    final alternate = session.addresses.firstWhere(
      (address) => address.id != session.selectedAddressId,
    );
    final addressCard = find.byKey(
      const ValueKey('buy-checkout-confirm-address'),
    );
    expect(addressCard, findsOneWidget);
    await tester.tap(addressCard);
    await tester.pumpAndSettle();
    expect(find.text('Delivery address'), findsOneWidget);
    final alternateAddress = find.byKey(
      ValueKey('buy-checkout-address-${alternate.id}'),
    );
    await revealPurchaseTarget(tester, alternateAddress);
    await tester.tap(alternateAddress);
    await tester.pumpAndSettle();
    expect(session.selectedAddressId, alternate.id);
    expect(session.selectedPayment, payment);

    final paymentCard = find.byKey(
      const ValueKey('buy-checkout-confirm-payment'),
    );
    await revealPurchaseTarget(tester, paymentCard);
    await tester.tap(paymentCard);
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('buy-payment-Card'));
    await revealPurchaseTarget(tester, card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(session.selectedPayment, 'Card');
    expect(session.selectedAddressId, alternate.id);
    expect(session.quantityFor(product.id), quantity);
    expect(session.cartTotal, total);
    expect(session.checkoutIdempotencyKey, isNull);
    expect(session.confirmedOrders, isEmpty);
    expect(find.textContaining('Delivery & payment'), findsNothing);
    expect(find.textContaining('delivery and payment'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tracking shows current progress, next step and working alerts', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openTracking('MS-240782');
    await tester.pumpAndSettle();

    expect(find.text('LAST KNOWN'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    expect(find.text('54%'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('buy-tracking-progress')),
          )
          .value,
      .54,
    );
    expect(find.text('RECORDED'), findsOneWidget);
    final nextStep = find.text('What happens next');
    final trackingScrollable = scrollableWithin(
      const PageStorageKey('buy-tracking-MS-240782'),
    );
    await tester.scrollUntilVisible(
      nextStep,
      180,
      scrollable: trackingScrollable,
    );
    expect(nextStep, findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-tracking-alerts')),
      180,
      scrollable: trackingScrollable,
    );
    expect(find.text('Order updates'), findsOneWidget);
    expect(find.text('Order alerts are on'), findsOneWidget);

    final alertsToggle = find.byKey(
      const ValueKey('buy-tracking-alerts-toggle'),
    );
    await tester.scrollUntilVisible(
      alertsToggle,
      180,
      scrollable: trackingScrollable,
    );
    await tester.drag(trackingScrollable, const Offset(0, -72));
    await tester.pumpAndSettle();
    await tester.tap(alertsToggle);
    await tester.pump();
    expect(session.trackingAlertsEnabled, isFalse);
    expect(find.text('Order alerts are paused'), findsOneWidget);
  });

  testWidgets('compact cart never covers tracking or support actions', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    var helpOpens = 0;
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    session.addProduct(product.id);
    final originalQuantity = session.quantityFor(product.id);
    final originalTotal = session.cartTotal;
    await tester.pumpWidget(app(session, onOpenChat: () => helpOpens += 1));
    await tester.pumpAndSettle();

    session.openTracking('MS-240782');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Help'),
      260,
      scrollable: scrollableWithin(
        const PageStorageKey('buy-tracking-MS-240782'),
      ),
    );
    expect(find.text('Help'), findsOneWidget);
    final miniCart = find.byKey(const ValueKey('buy-compact-cart-indicator'));
    final help = find.byKey(const ValueKey('buy-tracking-help'));
    expect(miniCart.hitTestable(), findsOneWidget);
    expect(help.hitTestable(), findsOneWidget);
    expect(tester.getRect(miniCart).overlaps(tester.getRect(help)), isFalse);
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(helpOpens, 1);
    expect(session.selectedOrderId, 'MS-240782');

    await tester.tap(miniCart);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    await tester.tap(miniCart);
    await tester.pumpAndSettle();
    expect(session.openProduct('missing-cart-return-product'), isFalse);
    expect(session.view, BuyV2View.cart);
    expect(session.openCheckout(), isTrue);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.checkout);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrderId, 'MS-240782');

    session.openAssist();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
    expect(
      find.byKey(PageStorageKey('buy-tracking-${session.assistOrder.id}')),
      findsOneWidget,
    );
    expect(miniCart.hitTestable(), findsOneWidget);
    await tester.scrollUntilVisible(
      help,
      240,
      scrollable: scrollableWithin(
        PageStorageKey('buy-tracking-${session.assistOrder.id}'),
      ),
    );
    await tester.pumpAndSettle();
    expect(help.hitTestable(), findsOneWidget);
    expect(tester.getRect(miniCart).overlaps(tester.getRect(help)), isFalse);
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(helpOpens, 2);
    final selectedOrder = session.selectedOrder.id;
    final originalView = session.view;
    await tester.tap(miniCart);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, originalView);
    expect(session.selectedOrder.id, selectedOrder);
    expect(session.quantityFor(product.id), originalQuantity);
    expect(session.cartTotal, originalTotal);
    expect(tester.takeException(), isNull);

    session.openDestination(BuyV2Destination.shop);
    session.openCart();
    session.goBack();
    expect(session.view, BuyV2View.catalogue);
    expect(session.destination, BuyV2Destination.shop);
  });

  test('Cart order return rejects a changed customer owner', () {
    final store = _CartReturnOwnerStore();
    final session = BuyV2Session(core: BuySession(), customerStateStore: store);
    addTearDown(session.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    session.addProduct(product.id);
    session.openTracking('MS-240782');
    session.openCart();
    store.ownerScope = 'cart-return-owner-b';
    session.goBack();
    expect(session.view, BuyV2View.catalogue);
    expect(session.quantityFor(product.id), 1);
  });

  for (final removed in [false, true]) {
    test(
      'Cart order return rejects ${removed ? 'removed' : 'replaced'} order',
      () async {
        BuyV2Order order(String title) => BuyV2Order(
          id: 'cart-return-order',
          destination: BuyV2Destination.shop,
          title: title,
          itemSummary: 'Isolated navigation fixture',
          total: 37,
          partner: 'Test Store',
          partnerType: 'Store',
          promise: 'Awaiting Store acceptance',
          destinationLabel: 'Test address',
          progress: 0,
          status: BuyV2OrderStatus.confirmed,
        );
        final commerce = TestPaymentCommerce();
        final original = order('Original order');
        BuyV2CommerceSnapshot snapshot(List<BuyV2Order> orders) =>
            BuyV2CommerceSnapshot(
              state: BuyV2CommerceLoadState.ready,
              products: testPaymentProducts,
              orders: orders,
            );
        commerce.snapshot = snapshot([original]);
        final session = BuyV2Session(
          core: BuySession(),
          commerceAdapter: commerce,
          reviewDataEnabled: false,
          productFactsAdapter: QualifiedTestProductFacts(
            testPaymentProducts.map((product) => product.id).toSet(),
          ),
        );
        addTearDown(session.dispose);
        await session.restoreCommerce();
        final product = testPaymentProducts.firstWhere(
          (item) => item.destination == BuyV2Destination.shop,
        );
        expect(session.addProduct(product.id), isTrue, reason: session.notice);
        final total = session.cartTotal;
        expect(session.openTracking(original.id), isTrue);
        session.openCart();
        commerce.snapshot = snapshot(removed ? [] : [order('Refreshed order')]);
        await session.restoreCommerce();
        session.goBack();
        expect(session.view, BuyV2View.catalogue);
        expect(session.destination, BuyV2Destination.orders);
        expect(session.quantityFor(product.id), 1);
        expect(session.cartTotal, total);
        expect(commerce.requests, isEmpty);
        expect(session.orders, hasLength(removed ? 0 : 1));
        if (!removed) expect(session.orders.single.title, 'Refreshed order');
      },
    );
  }

  testWidgets('retired Assist state uses tracking and shared Chat only', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var chatOpens = 0;
    await tester.pumpWidget(app(session, onOpenChat: () => chatOpens += 1));
    await tester.pumpAndSettle();

    session.openAssist();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
    expect(
      find.byKey(PageStorageKey('buy-tracking-${session.assistOrder.id}')),
      findsOneWidget,
    );
    final help = find.byKey(const ValueKey('buy-tracking-help'));
    await tester.scrollUntilVisible(
      help,
      240,
      scrollable: scrollableWithin(
        PageStorageKey('buy-tracking-${session.assistOrder.id}'),
      ),
    );
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(chatOpens, 1);
    expect(find.text('Call in app'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cart item count uses correct singular and plural copy', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final products = BuyV2Catalogue.products
        .where((item) => item.destination == BuyV2Destination.shop)
        .take(2)
        .toList();
    session.addProduct(products.first.id);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openCart();
    await tester.pumpAndSettle();

    expect(find.textContaining('1 product ·'), findsOneWidget);
    expect(find.textContaining('1 products'), findsNothing);

    session.addProduct(products.last.id);
    await tester.pumpAndSettle();
    expect(find.textContaining('2 products ·'), findsOneWidget);
  });

  testWidgets('Buy prices use locked Indian currency grouping', (tester) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openOrders();
    await tester.pumpAndSettle();

    expect(find.text('₹4,839'), findsOneWidget);
    expect(find.text('₹4,200'), findsOneWidget);
    expect(find.text('₹4839'), findsNothing);
    expect(find.text('₹4200'), findsNothing);
  });

  for (final total in [4839, 1000000, 10000000, 100000000]) {
    for (final completed in [false, true]) {
      for (final layout in [
        (320.0, 1.0),
        (360.0, 1.0),
        (430.0, 1.0),
        (320.0, 2.0),
        (360.0, 2.0),
      ]) {
        testWidgets(
          'T14 recomposed Orders disclosure ${layout.$1}-${layout.$2} completed$completed amount$total',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(layout.$1, 900);
            addTearDown(tester.view.reset);
            final order = BuyV2Order(
              id: 'T14-RECOMPOSED',
              purchaseId: 'T14-LAYOUT-PURCHASE',
              destination: BuyV2Destination.wholesale,
              title: 'Wholesale order',
              itemSummary: '13 products · Work receiving · Sardarpura',
              total: total,
              partner:
                  'Rajasthan Fresh Produce and Household Distribution Centre',
              partnerType: 'MoolSocial Fulfilment Partner',
              promise: 'Delivery schedule awaiting live confirmation',
              destinationLabel: 'Sardarpura',
              progress: completed ? 1 : .54,
              status: completed
                  ? BuyV2OrderStatus.delivered
                  : BuyV2OrderStatus.preparing,
              balanceDue: 2940,
              balanceDueLabel: 'Due at confirmed delivery',
              paymentStatusLabel:
                  'Booking amount paid · balance due at delivery',
            );
            final session = _R6634TrackingSession(order);
            addTearDown(session.dispose);
            session.addProduct('s-tomato');
            final initialView = session.view;
            Widget render(BuyV2Session owner) => MaterialApp(
              theme: MoolTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(layout.$2),
                  disableAnimations: true,
                ),
                child: r66VisualCaptureRoot(child!),
              ),
              home: Scaffold(
                body: BuyV2OrdersView(session: owner, onOpenOrderHelp: (_) {}),
              ),
            );
            final semanticsHandle = tester.ensureSemantics();
            try {
              await tester.pumpWidget(render(session));
              await tester.pumpAndSettle();
              const phase = String.fromEnvironment(
                'BUY_T14_ORDERS_CAPTURE_PHASE',
                defaultValue: 'after',
              );
              await captureR66Visual(
                tester,
                'orders-$phase-${layout.$1}-${layout.$2}-completed$completed-amount$total',
              );
              final card = find.byKey(
                const ValueKey('buy-order-card-T14-RECOMPOSED'),
              );
              final details = find.byKey(
                const ValueKey('buy-order-details-T14-RECOMPOSED'),
              );
              expect(details, findsOneWidget);
              expect(tester.getSize(details).width, greaterThanOrEqualTo(44));
              expect(tester.getSize(details).height, greaterThanOrEqualTo(44));
              expect(
                tester
                    .getRect(details)
                    .overlaps(tester.getRect(find.text('₹2,940 balance'))),
                isFalse,
                reason:
                    'The separate details target must not overlap payment facts',
              );
              expect(
                find.byKey(
                  const ValueKey('buy-purchase-group-T14-LAYOUT-PURCHASE'),
                ),
                findsNothing,
              );
              expect(find.text('Purchase T14-LAYOUT-PURCHASE'), findsNothing);
              expect(
                find.byKey(const ValueKey('buy-orders-filter')),
                findsNothing,
              );
              expect(
                tester
                    .getSemantics(find.text('₹2,940 balance'))
                    .getSemanticsData()
                    .label,
                contains('₹2,940 balance'),
              );
              expect(
                tester.getSemantics(details).rect.height,
                lessThanOrEqualTo(tester.getSize(details).height + 1),
              );
              Semantics disclosureSemantics() => tester
                  .widgetList<Semantics>(find.byType(Semantics))
                  .singleWhere(
                    (node) =>
                        node.properties.label ==
                        'Order details for ${order.id}',
                  );
              expect(disclosureSemantics().properties.expanded, isFalse);
              expect(
                find.byKey(ValueKey('buy-order-invoice-${order.id}')),
                findsNothing,
              );
              expect(find.byType(FilledButton), findsNothing);
              expect(find.text(order.itemSummary), findsNothing);
              expect(find.text(order.partnerType), findsNothing);
              expect(find.text(order.paymentStatusLabel!), findsNothing);
              expect(find.text('₹2,940 balance'), findsOneWidget);
              expect(find.text(buyV2Money(total)), findsOneWidget);
              if (layout.$2 == 2) {
                final title = find.text(order.title);
                final text = tester.widget<Text>(title);
                final longestWord = TextPainter(
                  text: TextSpan(text: 'Wholesale', style: text.style),
                  textDirection: TextDirection.ltr,
                  textScaler: const TextScaler.linear(2),
                )..layout();
                expect(
                  tester.getSize(title).width,
                  greaterThanOrEqualTo(longestWord.width),
                  reason: 'Enlarged order type must not split inside a word',
                );
                longestWord.dispose();
              }
              if (layout.$2 == 1) {
                expect(tester.getSize(card).height, lessThan(260));
              }
              await tester.ensureVisible(details);
              await tester.tap(details);
              await tester.pumpAndSettle();
              expect(disclosureSemantics().properties.expanded, isTrue);
              expect(find.text('Purchase T14-LAYOUT-PURCHASE'), findsOneWidget);
              expect(session.view, initialView);
              expect(session.quantityFor('s-tomato'), 1);
              expect(find.text(order.itemSummary), findsOneWidget);
              expect(find.text(order.partnerType), findsOneWidget);
              expect(find.text(order.paymentStatusLabel!), findsOneWidget);
              expect(find.byTooltip('Hide order details'), findsOneWidget);
              expect(
                find.byKey(ValueKey('buy-order-invoice-${order.id}')),
                findsOneWidget,
              );
              final replacement = _R6634TrackingSession(order);
              addTearDown(replacement.dispose);
              await tester.pumpWidget(render(replacement));
              await tester.pumpAndSettle();
              expect(find.text(order.itemSummary), findsNothing);
              expect(find.byTooltip('Hide order details'), findsNothing);
              expect(tester.takeException(), isNull);
            } finally {
              semanticsHandle.dispose();
            }
          },
        );
      }
    }
  }
  for (final reduceMotion in [false, true]) {
    testWidgets('T14 premium Orders disclosure motion reduced$reduceMotion', (
      tester,
    ) async {
      final order = BuyV2Order(
        id: 'PREMIUM-MOTION',
        destination: BuyV2Destination.shop,
        title: 'Shop order',
        itemSummary: '2 products',
        total: 100000000,
        partner: 'Store',
        partnerType: 'Store',
        promise: 'Schedule awaiting confirmation',
        destinationLabel: 'Home',
        progress: .54,
        status: BuyV2OrderStatus.preparing,
      );
      final session = _R6634TrackingSession(order);
      addTearDown(session.dispose);
      final initialView = session.view;
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: Scaffold(
            body: BuyV2OrdersView(session: session, onOpenOrderHelp: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('buy-order-card-PREMIUM-MOTION'));
      final details = find.byKey(
        const ValueKey('buy-order-details-PREMIUM-MOTION'),
      );
      final sizeAnimation = find.descendant(
        of: card,
        matching: find.byType(AnimatedSize),
      );
      final rotation = find.descendant(
        of: details,
        matching: find.byType(AnimatedRotation),
      );
      if (reduceMotion) {
        expect(sizeAnimation, findsNothing);
      } else {
        expect(
          tester.widget<AnimatedSize>(sizeAnimation).duration,
          BuyV2Motion.stateChange,
        );
      }
      expect(
        tester.widget<AnimatedRotation>(rotation).duration,
        reduceMotion ? Duration.zero : BuyV2Motion.stateChange,
      );
      final statusIcon = find.descendant(
        of: card,
        matching: find.byType(AnimatedSwitcher),
      );
      final storeIcon = find.descendant(
        of: statusIcon,
        matching: find.byIcon(Icons.storefront_rounded),
      );
      expect(tester.widget<Icon>(storeIcon).color, BuyV2Colors.muted);
      expect(
        tester.widget<AnimatedSwitcher>(statusIcon).duration,
        reduceMotion ? Duration.zero : BuyV2Motion.stateChange,
      );
      expect(tester.hasRunningAnimations, isFalse);
      final collapsedHeight = tester.getSize(card).height;
      await tester.tap(details);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final turns = tester
          .widget<RotationTransition>(
            find.descendant(
              of: rotation,
              matching: find.byType(RotationTransition),
            ),
          )
          .turns
          .value;
      expect(turns, reduceMotion ? .5 : allOf(greaterThan(0), lessThan(.5)));
      await tester.pumpAndSettle();
      expect(tester.getSize(card).height, greaterThan(collapsedHeight));
      expect(find.text('Invoice'), findsOneWidget);
      expect(session.view, initialView);
      expect(session.selectedOrder.progress, .54);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('order card body performs its advertised primary action', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openOrders();
    await tester.pumpAndSettle();

    final activeCard = find.byKey(const ValueKey('buy-order-card-MS-240782'));
    final activeRect = tester.getRect(activeCard);
    await tester.tapAt(activeRect.topLeft + const Offset(60, 60));
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240782');

    session.openOrders();
    session.showOrdersTab(BuyV2OrdersTab.delivered);
    await tester.pumpAndSettle();
    final deliveredCard = find.byKey(
      const ValueKey('buy-order-card-MS-240741'),
    );
    await tester.ensureVisible(deliveredCard);
    await tester.pumpAndSettle();
    final deliveredRect = tester.getRect(deliveredCard);
    await tester.tapAt(deliveredRect.topLeft + const Offset(60, 60));
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240741');
    expect(session.ordersTab, BuyV2OrdersTab.delivered);
    expect(session.cartLines, isEmpty);
  });

  testWidgets('Orders opens at the top after Checkout was scrolled', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.addProduct(product.id);
    session.openCheckout();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    session.openOrders();
    await tester.pumpAndSettle();

    expect(find.text('PURCHASES'), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-orders-section-active')),
      findsOneWidget,
    );
    expect(find.text('Orders'), findsWidgets);
    expect(find.text('Active · ${session.activeOrderCount}'), findsOneWidget);
  });

  testWidgets('saved and typed product-code search complete visibly', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var scannerCalls = 0;
    final savedProduct = session.visibleProducts.first;
    session.toggleSaved(savedProduct.id);
    await tester.pumpWidget(
      app(
        session,
        scannerLauncher: (_) async {
          scannerCalls += 1;
          return savedProduct.id;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byKey(ValueKey('buy-product-${savedProduct.id}')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);

    session.returnToCatalogue();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      savedProduct.id,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('buy-product-${savedProduct.id}')));
    await tester.pumpAndSettle();

    expect(scannerCalls, 0);
    expect(session.query, savedProduct.id);
    expect(session.selectedProductId, savedProduct.id);
    expect(session.view, BuyV2View.product);
  });

  testWidgets('R5 search 022A every catalogue retires the generic scanner', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var scannerCalls = 0;
    await tester.pumpWidget(
      app(
        session,
        scannerLauncher: (_) async {
          scannerCalls += 1;
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    for (final destination in BuyV2Destination.values) {
      session.openDestination(destination);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
      expect(find.byTooltip('Open camera barcode scanner'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-search-field')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('buy-search-close')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
    expect(scannerCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('products save at the grid and appear in the Saved owner', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = session.visibleProducts.first;
    if (session.isSaved(product.id)) {
      session.toggleSaved(product.id);
    }
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final card = find.byKey(ValueKey('buy-product-${product.id}'));
    final save = find.byKey(ValueKey('buy-save-${product.id}'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    expect(tester.getRect(card).contains(tester.getCenter(save)), isTrue);

    await tester.tap(save);
    await tester.pump();
    expect(session.isSaved(product.id), isTrue);
    final notice = find.byKey(const ValueKey('buy-live-notice'));
    expect(notice, findsOneWidget);
    final noticeRect = tester.getRect(notice);
    final contentRight = tester
        .getRect(find.byKey(const ValueKey('buy-theme-canvas')))
        .right;
    expect(noticeRect.width, lessThanOrEqualTo(248));
    expect(noticeRect.right, contentRight - 8);

    await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(ValueKey('buy-product-${product.id}')), findsOneWidget);
  });

  testWidgets('category and search actions cannot strand the Saved grid', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-category-rail')), findsNothing);
    expect(find.byKey(const ValueKey('buy-category-picker')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-category-search')),
      'shop supplies',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-category-shop-supplies')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('buy-category-shop-supplies')));
    await tester.pumpAndSettle();
    expect(session.selectedCategoryId, 'shop-supplies');
    expect(find.byKey(const ValueKey('buy-category-grid')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-search-field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-saved-products-button')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('buy-search-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
    await tester.pumpAndSettle();
    for (final product in session.savedProductsFor(BuyV2Destination.shop)) {
      expect(find.byKey(ValueKey('buy-product-${product.id}')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual scanner recovery is compact and returns a code', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showBuyV2ManualCodeSheet(context);
              },
              child: const Text('Open scanner fallback'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open scanner fallback'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('buy-manual-code-panel')))
          .height,
      lessThanOrEqualTo(238),
    );
    await tester.enterText(
      find.byKey(const ValueKey('buy-product-code-field')),
      'shop-atta',
    );
    await tester.tap(find.byKey(const ValueKey('buy-use-product-code')));
    await tester.pumpAndSettle();
    expect(result, 'shop-atta');
  });

  testWidgets(
    'featured card exposes automatic delivery and a stable purchase action',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final product = session.visibleProducts.first;
      final card = find.byKey(ValueKey('buy-product-${product.id}'));
      final add = find.byKey(ValueKey('buy-add-${product.id}'));
      final promise = find.descendant(
        of: card,
        matching: find.text(
          buyV2BuyerDeliveryPromise(session.productFactsFor(product)),
        ),
      );

      expect(add, findsOneWidget);
      expect(promise, findsOneWidget);
      expect(find.textContaining(product.seller), findsOneWidget);
      final cardRect = tester.getRect(card);
      expect(cardRect.contains(tester.getCenter(add)), isTrue);
      expect(cardRect.contains(tester.getCenter(promise)), isTrue);
      expect(tester.getSize(add).height, 44);
      expect(tester.getSize(add).width, greaterThanOrEqualTo(44));
    },
  );

  testWidgets('PAY-07 success settles once with customer actions only', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(session.addProduct('s-tomato'), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    await tester.pump();

    expect(
      find.byKey(ValueKey('buy-order-success-${session.confirmedPurchaseId}')),
      findsOneWidget,
    );
    expect(find.text('Order placed'), findsOneWidget);
    expect(find.text('Track delivery'), findsNothing);
    expect(find.text('View purchase in Orders'), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-confirmation-order-details')),
      findsOneWidget,
    );
    final continueShopping = find.byKey(
      const ValueKey('buy-confirmation-continue-shopping'),
    );
    await tester.scrollUntilVisible(
      continueShopping,
      180,
      scrollable: scrollableWithin(const ValueKey('buy-confirmation')),
    );
    expect(continueShopping, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PAY-08 Quick status is compact with restorable preferences', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(
      app(session, deliveryArrivalSound: _R5ScreenArrivalSound()),
    );
    await tester.pumpAndSettle();
    expect(session.addProduct('s-tomato'), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-quick-delivery-status-minimized')),
      findsOneWidget,
    );
    final minimizedContentTop = tester
        .getTopLeft(find.byKey(const ValueKey('buy-confirmation')))
        .dy;
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('buy-quick-delivery-status-minimized')),
          )
          .width,
      lessThanOrEqualTo(48),
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('buy-quick-delivery-status-minimized')),
          )
          .height,
      inInclusiveRange(44, 48),
    );
    await tester.tap(find.byKey(const ValueKey('buy-quick-delivery-expand')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
      findsOneWidget,
    );
    expect(find.text('Keep'), findsOneWidget);
    expect(find.text('Arrival sound'), findsNothing);
    expect(
      find.byTooltip('Enable arrival sound for this delivery'),
      findsOneWidget,
    );
    expect(find.text('Hide'), findsOneWidget);
    final controlCenters = [
      tester
          .getCenter(find.byKey(const ValueKey('buy-quick-delivery-keep')))
          .dy,
      tester
          .getCenter(find.byKey(const ValueKey('buy-quick-delivery-sound')))
          .dy,
      tester
          .getCenter(find.byKey(const ValueKey('buy-quick-delivery-hide')))
          .dy,
    ];
    controlCenters.sort();
    expect(controlCenters.last - controlCenters.first, lessThan(6));
    await tester.tap(find.byKey(const ValueKey('buy-quick-delivery-sound')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('buy-quick-delivery-sound')),
          )
          .isSelected,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('buy-quick-delivery-hide')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-quick-delivery-toggle')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('buy-confirmation'))).dy,
      minimizedContentTop,
    );
    expect(session.openTracking(session.activeQuickDeliveryOrder!.id), isTrue);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-quick-delivery-restore')));
    await tester.pumpAndSettle();
    session.returnToOrders();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-quick-delivery-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-quick-delivery-keep')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
      findsOneWidget,
    );
    expect(find.text('Kept'), findsOneWidget);
  });

  testWidgets('PAY-08 scheduled and courier delivery uses quiet status', (
    tester,
  ) async {
    final session = BuyV2Session(
      core: BuySession(),
      productFactsAdapter: const _FixedDeliveryPromiseFactsAdapter(
        'Delivery in 2 days',
      ),
    );
    addTearDown(session.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) =>
          candidate.destination == BuyV2Destination.shop &&
          session.fulfilmentModeFor(candidate) ==
              BuyV2FulfilmentMode.standardCourier,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(session.addProduct(product.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-quick-delivery-status-minimized')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
      findsNothing,
    );
  });

  for (final amount in [1000000, 10000000, 100001280]) {
    for (final layout in [
      (size: const Size(360, 800), scale: 1.0, label: 'normal'),
      (size: const Size(320, 711), scale: 2.0, label: 'enlarged-portrait'),
      (size: const Size(711, 320), scale: 2.0, label: 'enlarged-landscape'),
    ]) {
      testWidgets(
        'R668 cart payable INR$amount is complete at ${layout.label}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = layout.size;
          addTearDown(tester.view.reset);
          final session = _R668CartPayableFixture(amount);
          expect(session.scopedPayableTotalMinor, amount * 100);
          addTearDown(session.dispose);
          await tester.pumpWidget(app(session, textScale: layout.scale));
          await tester.pumpAndSettle();
          session.addProduct('w-notebook');
          session.openCart(scope: BuyV2CartScope.all);
          await tester.pumpAndSettle();
          final actionBar = find.byKey(const ValueKey('buy-cart-action-bar'));
          if (layout.label == 'enlarged-landscape') {
            await tester.scrollUntilVisible(
              actionBar,
              240,
              scrollable: scrollableWithin(
                const PageStorageKey('buy-cart-all'),
              ),
            );
            await tester.pumpAndSettle();
          }
          final amountOwner = find.byKey(
            const ValueKey('buy-cart-payable-total-motion'),
          );
          final displayedAmount = find.descendant(
            of: amountOwner,
            matching: find.byType(Text),
          );
          expect(displayedAmount, findsOneWidget);
          final amountText = tester.widget<Text>(displayedAmount).data!;
          expect(
            amountText,
            isIn([
              buyV2Money(amount),
              buyV2Money(amount).replaceFirst('₹', ''),
            ]),
          );
          if (!amountText.contains('₹')) {
            final currencyLabel = find.descendant(
              of: actionBar,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Text && (widget.data?.endsWith(' (₹)') ?? false),
              ),
            );
            expect(currencyLabel, findsOneWidget);
            expectReadable(tester, currencyLabel, wholeWords: true);
            final currencyBounds = tester.getRect(currencyLabel);
            final actionBounds = tester.getRect(actionBar);
            expect(actionBounds.contains(currencyBounds.topLeft), isTrue);
            expect(
              actionBounds.contains(
                currencyBounds.bottomRight - const Offset(.1, .1),
              ),
              isTrue,
            );
          }
          final amountSemantics = tester.ensureSemantics();
          try {
            await tester.pump();
            final announcedAmount = find
                .ancestor(
                  of: amountOwner,
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Semantics &&
                        widget.properties.label == buyV2Money(amount),
                  ),
                )
                .first;
            expect(
              tester
                  .getSemantics(announcedAmount)
                  .label
                  .split('\n')
                  .where((line) => RegExp(r'^₹[0-9,]+$').hasMatch(line)),
              orderedEquals([buyV2Money(amount)]),
            );
          } finally {
            amountSemantics.dispose();
          }
          final paragraph = tester.renderObject<RenderParagraph>(
            displayedAmount,
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          final amountRect = tester.getRect(displayedAmount);
          expect(
            amountRect.left,
            greaterThanOrEqualTo(tester.getRect(actionBar).left),
          );
          expect(
            amountRect.right,
            lessThanOrEqualTo(tester.getRect(actionBar).right),
          );
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: amountText.length),
          );
          expect(boxes, isNotEmpty);
          final visibleAmountBoundary = tester.getRect(actionBar);
          for (final box in boxes) {
            final topLeft = paragraph.localToGlobal(Offset(box.left, box.top));
            final bottomRight = paragraph.localToGlobal(
              Offset(box.right, box.bottom),
            );
            expect(
              topLeft.dx,
              greaterThanOrEqualTo(visibleAmountBoundary.left),
            );
            expect(
              bottomRight.dx,
              lessThanOrEqualTo(visibleAmountBoundary.right),
            );
            expect(
              bottomRight.dy,
              lessThanOrEqualTo(visibleAmountBoundary.bottom),
            );
            expect(
              box.top,
              closeTo(boxes.first.top, .1),
              reason: 'Keep the numeric amount together on one line.',
            );
          }
          final review = find.descendant(
            of: actionBar,
            matching: find.text('Checkout'),
          );
          await tester.ensureVisible(review);
          await tester.pumpAndSettle();
          expect(review.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          await captureR66Visual(tester, 'r669-cart-$amount-${layout.label}');
          await tester.tap(review);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.checkout);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('PAY-09 Cart summary clears the fixed action bar', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) => candidate.destination == BuyV2Destination.wholesale,
    );
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();
    expect(session.addProduct(product.id), isTrue);
    session.openCart(scope: BuyV2CartScope.wholesale);
    await tester.pumpAndSettle();

    final summary = find.byKey(const ValueKey('buy-cart-bill-summary'));
    final cartList = scrollableWithin(
      const PageStorageKey('buy-cart-wholesale'),
    );
    await tester.scrollUntilVisible(summary, 220, scrollable: cartList);
    await tester.pumpAndSettle();
    final actionBar = find.byKey(const ValueKey('buy-cart-action-bar'));
    final dockTotal = find.descendant(
      of: actionBar,
      matching: find.text(buyV2Money(session.scopedPayableTotal)),
    );
    final reviewAction = find.descendant(
      of: actionBar,
      matching: find.text('Checkout'),
    );
    expect(
      tester.getRect(summary).bottom,
      lessThanOrEqualTo(tester.getRect(actionBar).top),
    );
    expect(dockTotal, findsOneWidget);
    expect(reviewAction, findsOneWidget);
    expect(
      tester.getRect(actionBar).contains(tester.getRect(dockTotal).bottomRight),
      isTrue,
    );
    expect(
      tester
          .getRect(actionBar)
          .contains(tester.getRect(reviewAction).bottomRight),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('PAY-01 through PAY-09 fit Android and iOS viewport matrix', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    const viewports =
        <({String label, Size size, EdgeInsets safe, double scale})>[
          (
            label: 'compact Android',
            size: Size(320, 568),
            safe: EdgeInsets.symmetric(vertical: 24),
            scale: 1.4,
          ),
          (
            label: 'Redmi Android',
            size: Size(360, 800),
            safe: EdgeInsets.only(top: 34, bottom: 81),
            scale: 1,
          ),
          (
            label: 'large Android',
            size: Size(412, 915),
            safe: EdgeInsets.only(top: 32, bottom: 24),
            scale: 1.15,
          ),
          (
            label: 'iPhone SE',
            size: Size(375, 667),
            safe: EdgeInsets.only(top: 20),
            scale: 1,
          ),
          (
            label: 'iPhone',
            size: Size(390, 844),
            safe: EdgeInsets.only(top: 47, bottom: 34),
            scale: 1,
          ),
          (
            label: 'large iPhone',
            size: Size(430, 932),
            safe: EdgeInsets.only(top: 59, bottom: 34),
            scale: 1.2,
          ),
          (
            label: 'Android tablet',
            size: Size(600, 960),
            safe: EdgeInsets.only(top: 24, bottom: 24),
            scale: 1,
          ),
        ];

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport.size;
      final session = BuyV2Session(core: BuySession());

      await tester.pumpWidget(
        app(
          session,
          textScale: viewport.scale,
          safePadding: viewport.safe,
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(session.addProduct('s-tomato'), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-checkout-address-stage')),
        findsOneWidget,
        reason: viewport.label,
      );
      expect(
        find.byKey(const ValueKey('buy-checkout-primary-address')),
        findsOneWidget,
        reason: viewport.label,
      );
      expect(tester.takeException(), isNull, reason: viewport.label);

      expect(session.continueCheckoutFromAddress(), isTrue);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('buy-checkout-payment-stage')),
        220,
        scrollable: scrollableWithin(
          const PageStorageKey('buy-checkout-unified'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-checkout-payment-stage')),
        findsOneWidget,
        reason: viewport.label,
      );
      expect(
        find.byKey(const ValueKey('buy-checkout-primary-payment')),
        findsOneWidget,
        reason: viewport.label,
      );
      final dueNow = find.byKey(const ValueKey('buy-checkout-amount-due-now'));
      expect(dueNow, findsOneWidget);
      expect(
        tester.widget<Text>(dueNow).data,
        buyV2Money(session.checkoutAmountDueNow),
      );
      expect(tester.takeException(), isNull, reason: viewport.label);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('buy-checkout-order-details')),
        -220,
        scrollable: scrollableWithin(
          const PageStorageKey('buy-checkout-unified'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-checkout-order-details')),
        findsOneWidget,
        reason: viewport.label,
      );
      expect(
        session.checkoutSubmissionState,
        BuyV2CheckoutSubmissionState.idle,
      );
      expect(session.checkoutIdempotencyKey, isNull);
      expect(session.confirmedOrders, isEmpty);
      final confirmAction = find.byKey(
        ValueKey('buy-checkout-primary-${session.checkoutStep.name}'),
      );
      expect(confirmAction, findsOneWidget, reason: viewport.label);
      expect(
        tester.getRect(confirmAction).bottom,
        lessThanOrEqualTo(viewport.size.height - viewport.safe.bottom),
        reason: viewport.label,
      );
      expect(tester.takeException(), isNull, reason: viewport.label);

      expect(session.showCheckoutStep(BuyV2CheckoutStep.payment), isTrue);
      session.checkoutSubmissionState = BuyV2CheckoutSubmissionState.cancelled;
      session.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Choose again'), findsOneWidget, reason: viewport.label);
      expect(find.textContaining('…'), findsNothing, reason: viewport.label);
      expect(tester.takeException(), isNull, reason: viewport.label);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
    }
  });

  testWidgets('Payment primary action requires a currently available method', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);

    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();
    expect(session.addProduct('s-tomato'), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.continueCheckoutFromAddress(), isTrue);
    await tester.pumpAndSettle();
    session.selectedPayment = '';
    session.notifyListeners();
    await tester.pumpAndSettle();

    final action = find.byKey(const ValueKey('buy-checkout-primary-payment'));
    expect(session.selectedPayment, isEmpty);
    expect(session.checkoutSubmissionState, BuyV2CheckoutSubmissionState.idle);
    expect(session.checkoutBusy, isFalse);
    final disabledAction = tester.widget<FilledButton>(action);
    expect(disabledAction.child, isA<Text>());
    expect((disabledAction.child! as Text).data, 'Choose payment method');
    expect(disabledAction.onPressed, isNull);
    expect(
      tester
          .getSemantics(action)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );

    session.selectedPayment = 'Purchase order';
    session.notifyListeners();
    await tester.pumpAndSettle();
    final ineligibleAction = tester.widget<FilledButton>(action);
    expect(ineligibleAction.child, isA<Text>());
    expect((ineligibleAction.child! as Text).data, 'Choose payment method');
    expect(ineligibleAction.onPressed, isNull);

    expect(session.choosePayment('UPI'), isTrue);
    await tester.pumpAndSettle();
    final enabledAction = tester.widget<FilledButton>(action);
    expect(enabledAction.child, isA<Text>());
    expect((enabledAction.child! as Text).data, 'Place order');
    expect(enabledAction.onPressed, isNotNull);
    expect(
      tester
          .getSemantics(action)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'checkout payment recovery states stay actionable at compact size',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();
      session.addProduct('s-tomato');
      session.openCart(scope: BuyV2CartScope.shop);
      session.openCheckout();
      await tester.pumpAndSettle();
      await prepareCheckoutPaymentState(tester, session);

      for (final state in const [
        BuyV2CheckoutSubmissionState.submitting,
        BuyV2CheckoutSubmissionState.paymentActionRequired,
        BuyV2CheckoutSubmissionState.paymentPending,
        BuyV2CheckoutSubmissionState.paymentUnknown,
        BuyV2CheckoutSubmissionState.cancelled,
        BuyV2CheckoutSubmissionState.failed,
        BuyV2CheckoutSubmissionState.unavailable,
      ]) {
        session.checkoutSubmissionState = state;
        session.notifyListeners();
        await tester.pump(const Duration(milliseconds: 120));

        expect(
          find.byKey(ValueKey('buy-checkout-payment-state-${state.name}')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: state.name);
        const actionKey = ValueKey('buy-checkout-primary-payment');
        expect(find.byKey(actionKey), findsOneWidget);
        expect(
          tester.getSize(find.byKey(actionKey)).height,
          greaterThanOrEqualTo(44),
        );
        if (state == BuyV2CheckoutSubmissionState.cancelled) {
          expect(find.text('Choose again'), findsOneWidget);
          expect(find.textContaining('…'), findsNothing);
        }
        if (state != BuyV2CheckoutSubmissionState.submitting) {
          if (!session.checkoutRecoveryAmountKnown) {
            expect(
              tester
                  .getSize(
                    find.byKey(const ValueKey('buy-checkout-action-bar')),
                  )
                  .height,
              lessThan(130),
              reason: 'Unknown amount must leave room to read recovery details',
            );
          }
          await captureR66Visual(tester, 't14-payment-recovery-${state.name}');
        }
      }
    },
  );

  testWidgets('checkout renders only the fulfilment families being purchased', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final shop = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.addProduct(shop.id);
    session.increase(shop.id);
    session.openCart(scope: BuyV2CartScope.shop);
    session.openCheckout();
    await tester.pumpAndSettle();
    expect(find.text('2 items'), findsOneWidget);
    await prepareCheckoutReviewState(tester, session);

    expect(find.text('Order items'), findsOneWidget);
    expect(find.text('1 product · 2 items'), findsOneWidget);
    expect(session.checkoutDestinations, {BuyV2Destination.shop});
    expect(session.checkoutFulfilmentGroups, hasLength(1));
    expect(
      find.byKey(
        ValueKey(
          'buy-checkout-confirm-delivery-${session.checkoutFulfilmentGroups.single.key}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'T01C carries exact mixed delivery promises through one purchase',
    (tester) async {
      final adapter = _T01CMutableDeliveryFactsAdapter();
      final session = BuyV2Session(
        core: BuySession(),
        productFactsAdapter: adapter,
        commerceAdapter: isolatedConfirmationCommerce(factsAdapter: adapter),
      );
      final shop = session.product('s-tomato');
      final wholesale = session.product('w-oil');
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      expect(session.addProduct(shop.id), isTrue);
      expect(session.addProduct(wholesale.id), isTrue);
      session.openCart();
      expect(session.openCheckout(), isTrue);
      await tester.pumpAndSettle();
      await prepareCheckoutReviewState(tester, session);

      expect(find.text('Order items'), findsOneWidget);
      expect(
        find.textContaining('Delivery in 5 min · by 6:35 PM'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Delivery in 1 day · by tomorrow 4:00 PM'),
        findsOneWidget,
      );
      for (final group in session.checkoutFulfilmentGroups) {
        expect(find.text(group.customerPartner), findsOneWidget);
      }
      expect(
        find.byKey(
          ValueKey('buy-checkout-primary-${session.checkoutStep.name}'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          ValueKey('buy-checkout-primary-${session.checkoutStep.name}'),
        ),
      );
      await tester.pumpAndSettle();
      await completeReviewPayment(tester, session);

      expect(find.text('Order placed'), findsOneWidget);
      expect(find.textContaining('2 products ·'), findsOneWidget);
      expect(find.textContaining('3 products ·'), findsNothing);
      expect(find.text('Your deliveries'), findsOneWidget);
      expect(find.text('Delivery 1 of 2'), findsOneWidget);
      expect(find.text('Delivery 2 of 2'), findsOneWidget);
      expect(
        find.text('Timing · Delivery in 5 min · by 6:35 PM'),
        findsOneWidget,
      );
      expect(
        find.text('Timing · Delivery in 1 day · by tomorrow 4:00 PM'),
        findsOneWidget,
      );
      expect(find.textContaining(shop.seller), findsWidgets);
      expect(find.textContaining(wholesale.seller), findsWidgets);
      final purchaseId = session.confirmedPurchaseId;
      expect(purchaseId, isNotNull);
      expect(session.confirmedOrders.map((order) => order.purchaseId).toSet(), {
        purchaseId,
      });
    },
  );

  testWidgets('T01C blocks and explains a changed pre-commit promise', (
    tester,
  ) async {
    final adapter = _T01CMutableDeliveryFactsAdapter();
    final session = BuyV2Session(
      core: BuySession(),
      productFactsAdapter: adapter,
      commerceAdapter: isolatedConfirmationCommerce(factsAdapter: adapter),
    );
    final shop = session.product('s-tomato');
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(session.addProduct(shop.id), isTrue);
    session.openCart();
    expect(session.openCheckout(), isTrue);
    await tester.pumpAndSettle();
    await prepareCheckoutReviewState(tester, session);

    adapter.updateShop(promise: 'within 10 min', promisedBy: 'by 6:40 PM');
    await tester.tap(
      find.byKey(ValueKey('buy-checkout-primary-${session.checkoutStep.name}')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-checkout-promise-change-review')),
      findsOneWidget,
    );
    expect(
      find.text('Previous · Delivery in 5 min · by 6:35 PM'),
      findsOneWidget,
    );
    expect(
      find.text('Updated · Delivery in 10 min · by 6:40 PM'),
      findsOneWidget,
    );
    expect(session.confirmedOrders, isEmpty);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Place order'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(const ValueKey('buy-accept-updated-delivery-times')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-checkout-promise-change-review')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(ValueKey('buy-checkout-primary-${session.checkoutStep.name}')),
    );
    await tester.pumpAndSettle();
    await completeReviewPayment(tester, session);
    expect(find.text('Order placed'), findsOneWidget);
    expect(
      find.text('Timing · Delivery in 10 min · by 6:40 PM'),
      findsOneWidget,
    );
  });

  for (final failure in [
    'missing reference',
    'blank reference',
    'mismatched purchase',
    'empty orders',
    'unconfirmed',
    'no products',
  ]) {
    testWidgets('RV6 D009 rejects inconsistent confirmation $failure', (
      tester,
    ) async {
      final session = _D009InvalidConfirmationSession(failure);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: Scaffold(body: BuyV2ConfirmationView(session: session)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Order placed'), findsNothing);
      expect(find.text('Order confirmation unavailable'), findsOneWidget);
      expect(find.textContaining('Delivering to '), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('RV6 D009 accepted confirmation uses recorded delivery address', (
    tester,
  ) async {
    final session = _InvoiceRecoverySession(missingConfirmation: true);
    final savedAddress = session.selectedAddressOrNull;
    expect(savedAddress, isNotNull);
    expect(savedAddress!.recipient, isNot('Confirmed recipient'));
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(body: BuyV2ConfirmationView(session: session)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Order placed'), findsOneWidget);
    expect(
      find.text('Delivering to Confirmed recipient · Confirmed order address'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Delivering to ${savedAddress.recipient}'),
      findsNothing,
    );
    expect(session.selectedAddressOrNull, same(savedAddress));
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    for (final hasCart in [false, true]) {
      for (final ordersAction in [false, true]) {
        testWidgets(
          'RV6 D009 unsubmitted confirmation text $scale cart $hasCart orders $ordersAction',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(320, 568);
            addTearDown(tester.view.reset);
            final session = BuyV2Session(core: BuySession());
            if (hasCart) {
              expect(
                session.addProduct(session.visibleProducts.first.id),
                isTrue,
              );
            }
            final retainedCart = session.cartLines
                .map((line) => (line.product.id, line.quantity))
                .toList();
            final retainedOrders = session.orders
                .map((order) => order.id)
                .toList();
            final address = session.selectedAddressOrNull;
            await tester.pumpWidget(
              MaterialApp(
                theme: MoolTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: r66VisualCaptureRoot(child!),
                ),
                home: BuyV2Screen(
                  session: session,
                  initialView: BuyV2View.confirmation,
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('Order placed'), findsNothing);
            expect(
              find.byKey(const ValueKey('buy-confirmation-success')),
              findsNothing,
            );
            expect(find.text('Your deliveries'), findsNothing);
            expect(find.text('Order confirmation unavailable'), findsOneWidget);
            expect(find.textContaining('Delivering to '), findsNothing);
            expect(session.confirmedPurchaseId, isNull);
            expect(session.confirmedOrders, isEmpty);
            expect(tester.takeException(), isNull);
            if (!hasCart && !ordersAction) {
              await captureR66Visual(
                tester,
                'rv6-d009-unsubmitted-text-$scale',
              );
            }
            final action = find.byKey(
              ValueKey(
                ordersAction
                    ? 'buy-confirmation-view-orders'
                    : 'buy-confirmation-continue-shopping',
              ),
            );
            await tester.scrollUntilVisible(
              action,
              140,
              scrollable: scrollableWithin(
                const ValueKey('buy-confirmation'),
              ).first,
            );
            await tester.tap(action);
            await tester.pumpAndSettle();
            expect(
              session.destination,
              ordersAction ? BuyV2Destination.orders : BuyV2Destination.shop,
            );
            expect(session.view, BuyV2View.catalogue);
            expect(
              session.cartLines
                  .map((line) => (line.product.id, line.quantity))
                  .toList(),
              retainedCart,
            );
            expect(
              session.orders.map((order) => order.id).toList(),
              retainedOrders,
            );
            expect(session.selectedAddressOrNull, same(address));
            expect(session.confirmedPurchaseId, isNull);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'order confirmation preserves family identifiers then opens Orders',
    (tester) async {
      final session = BuyV2Session(
        core: BuySession(),
        commerceAdapter: isolatedConfirmationCommerce(
          factsAdapter: const _FixedDeliveryPromiseFactsAdapter(
            'Delivery in 2 days',
          ),
        ),
        productFactsAdapter: const _FixedDeliveryPromiseFactsAdapter(
          'Delivery in 2 days',
        ),
      );
      final products = [
        BuyV2Catalogue.products.firstWhere(
          (item) => item.destination == BuyV2Destination.shop,
        ),
        BuyV2Catalogue.products.firstWhere(
          (item) => item.destination == BuyV2Destination.wholesale,
        ),
      ];
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      for (final product in products) {
        session.addProduct(product.id);
      }
      session.increase(products.first.id);
      session.openCart();
      session.openCheckout();
      await tester.pumpAndSettle();
      await prepareCheckoutReviewState(tester, session);

      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          ValueKey('buy-checkout-primary-${session.checkoutStep.name}'),
        ),
      );
      await tester.pumpAndSettle();
      await completeReviewPayment(tester, session);
      final purchaseId = session.confirmedPurchaseId!;

      expect(find.byKey(const ValueKey('buy-confirmation')), findsOneWidget);
      expect(find.text('Your deliveries'), findsOneWidget);
      expect(find.text('Delivery 1 of 2'), findsOneWidget);
      expect(find.text('Delivery 2 of 2'), findsOneWidget);
      expect(find.text('Delivery 3 of 3'), findsNothing);
      for (final order in session.confirmedOrders) {
        final placedOrder = find.byKey(
          ValueKey('buy-placed-order-${order.id}'),
        );
        expect(placedOrder, findsOneWidget);
        expect(
          find.descendant(
            of: placedOrder,
            matching: find.textContaining('Timing · '),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: placedOrder,
            matching: find.textContaining('Delivered in'),
          ),
          findsNothing,
        );
      }
      expect(
        find.textContaining('Order reference · $purchaseId'),
        findsOneWidget,
      );
      expect(
        find.textContaining(session.confirmedOrders.first.partner),
        findsWidgets,
      );
      final shopOrder = session.confirmedOrders.firstWhere(
        (order) => order.destination == BuyV2Destination.shop,
      );
      final wholesaleOrder = session.confirmedOrders.firstWhere(
        (order) => order.destination == BuyV2Destination.wholesale,
      );
      expect(shopOrder.lines.single.product.id, products.first.id);
      expect(shopOrder.lines.single.quantity, 2);
      expect(wholesaleOrder.lines.single.product.id, products.last.id);
      expect(wholesaleOrder.lines.single.quantity, products.last.minimumOrder);

      final invoiceAction = find.byKey(
        ValueKey('buy-confirmation-invoice-${shopOrder.id}'),
      );
      await tester.ensureVisible(invoiceAction);
      await tester.tap(invoiceAction);
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('buy-invoice-page-${shopOrder.id}')),
        findsOneWidget,
      );
      expect(find.text(products.first.title), findsOneWidget);
      expect(find.text('2×'), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-confirmation')), findsOneWidget);

      final ordersAction = find.byKey(
        const ValueKey('buy-confirmation-order-details'),
      );
      await tester.ensureVisible(ordersAction);
      await tester.tap(ordersAction);
      await tester.pumpAndSettle();
      expect(find.text('PURCHASES'), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-orders-section-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('buy-purchase-group-$purchaseId')),
        findsOneWidget,
      );
      final details = find.byKey(
        ValueKey('buy-order-details-${session.confirmedOrders.first.id}'),
      );
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(
        find.textContaining(session.confirmedOrders.first.id),
        findsWidgets,
      );
    },
  );

  test('Orders row keys stay unique when retained delivery IDs repeat', () {
    final keys = {
      buyV2OrderRowKey(
        groupIndex: 0,
        purchaseId: 'MS-PURCHASE-1',
        orderIndex: 0,
        orderId: 'MS-NEW-01',
      ),
      buyV2OrderRowKey(
        groupIndex: 1,
        purchaseId: 'MS-PURCHASE-2',
        orderIndex: 0,
        orderId: 'MS-NEW-01',
      ),
      buyV2OrderRowKey(
        groupIndex: 1,
        purchaseId: 'MS-PURCHASE-2',
        orderIndex: 1,
        orderId: 'MS-NEW-01',
      ),
    };

    expect(keys, hasLength(3));
    expect(keys.every((key) => key.endsWith('MS-NEW-01')), isTrue);
  });

  testWidgets('invoice download uses the placed-order document contract', (
    tester,
  ) async {
    BuyV2InvoiceDocument? requestedInvoice;
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(
      app(
        session,
        disableAnimations: true,
        invoiceDownloader: (invoice) async {
          requestedInvoice = invoice;
          return BuyV2InvoiceDownloadOutcome.saved;
        },
      ),
    );
    await tester.pumpAndSettle();

    session.addProduct(product.id);
    session.increase(product.id);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    await tester.pumpAndSettle();
    final order = session.confirmedOrders.single;

    final invoiceAction = find.byKey(
      ValueKey('buy-confirmation-invoice-${order.id}'),
    );
    await tester.ensureVisible(invoiceAction);
    await tester.tap(invoiceAction);
    await tester.pumpAndSettle();

    final download = find.byKey(ValueKey('buy-download-invoice-${order.id}'));
    await tester.scrollUntilVisible(
      download,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(download, findsOneWidget);
    expect(tester.getSize(download).height, 48);
    await tester.tap(download);
    await tester.pumpAndSettle();

    expect(requestedInvoice, isNotNull);
    expect(requestedInvoice!.order.id, order.id);
    expect(requestedInvoice!.order.lines.single.quantity, 2);
    expect(
      requestedInvoice!.suggestedFileName,
      'MoolSocial-invoice-${order.id}.pdf',
    );
    expect(find.text('Invoice saved to this device.'), findsOneWidget);
  });

  testWidgets(
    'R669 invoice missing history explains recovery and preserves Orders',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = _InvoiceRecoverySession();
      await tester.pumpWidget(
        app(session, textScale: 1.4, disableAnimations: true),
      );
      await tester.pumpAndSettle();
      session.openOrders();
      await tester.pumpAndSettle();
      final order = session.visibleOrders.first;

      final details = find.byKey(ValueKey('buy-order-details-${order.id}'));
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      final invoiceAction = find.byKey(
        ValueKey('buy-order-invoice-${order.id}'),
      );
      await tester.ensureVisible(invoiceAction);
      await tester.tap(invoiceAction);
      await tester.pumpAndSettle();

      final invoicePage = find.byKey(
        ValueKey('buy-invoice-items-unavailable-${order.id}'),
      );
      expect(order.lines, isEmpty);
      expect(invoicePage, findsOneWidget);
      expect(find.text('Invoice details missing'), findsOneWidget);
      expect(find.byType(BuyV2InvoicePage), findsNothing);
      final invoiceCopy = tester
          .widgetList<Text>(
            find.descendant(of: invoicePage, matching: find.byType(Text)),
          )
          .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
          .join(' ');
      expect(_forbiddenBuyCopy.hasMatch(invoiceCopy), isFalse);
      expect(tester.takeException(), isNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.refreshCalls, 0);
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.catalogue);
      expect(find.byKey(const PageStorageKey('buy-orders')), findsOneWidget);
    },
  );

  for (final scale in [1.0, 2.0]) {
    for (final id in ['MS-240741', 'PO-240728']) {
      testWidgets('R669 invoice missing $id fits and refreshes at $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.reset);
        final session = _InvoiceRecoverySession();
        var downloads = 0;
        await tester.pumpWidget(
          app(
            session,
            textScale: scale,
            disableAnimations: true,
            invoiceDownloader: (_) async {
              downloads++;
              return BuyV2InvoiceDownloadOutcome.saved;
            },
          ),
        );
        await tester.pumpAndSettle();
        final retainedProduct = session.visibleProducts.first;
        expect(session.addProduct(retainedProduct.id), isTrue);
        session.openOrders();
        session.showOrdersTab(BuyV2OrdersTab.delivered);
        session.updateQuery(id);
        await tester.pumpAndSettle();
        final order = session.visibleOrders.single;
        final details = find.byKey(ValueKey('buy-order-details-$id'));
        await tester.scrollUntilVisible(
          details,
          200,
          scrollable: scrollableWithin(const PageStorageKey('buy-orders')),
        );
        await tester.tap(details);
        await tester.pumpAndSettle();
        final action = find.byKey(ValueKey('buy-order-invoice-$id'));
        await tester.scrollUntilVisible(
          action,
          200,
          scrollable: scrollableWithin(const PageStorageKey('buy-orders')),
        );
        await Scrollable.ensureVisible(tester.element(action), alignment: .4);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byType(BuyV2InvoicePage), findsNothing);
        expect(find.text('Invoice details missing'), findsOneWidget);
        final refresh = find.byKey(ValueKey('buy-invoice-refresh-$id'));
        expect(refresh.hitTestable(), findsOneWidget);
        expect(tester.getRect(refresh).bottom, lessThanOrEqualTo(568));
        expect(tester.getSize(refresh).height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull);
        await captureR66Visual(tester, 'r669-invoice-missing-$id-$scale');
        await tester.tap(refresh);
        await tester.pumpAndSettle();
        expect(session.refreshCalls, 1);
        expect(downloads, 0);
        expect(session.quantityFor(retainedProduct.id), 1);
        expect(session.ordersTab, BuyV2OrdersTab.delivered);
        expect(session.visibleOrders.single, same(order));
        expect(session.view, BuyV2View.catalogue);
        expect(session.destination, BuyV2Destination.orders);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.text('Invoice details missing'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.refreshCalls, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('R669 invoice missing tracking returns to exact order', (
    tester,
  ) async {
    final session = _InvoiceRecoverySession();
    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();
    session.openTracking('MS-240741');
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('buy-tracking-invoice-MS-240741'));
    await tester.scrollUntilVisible(
      action,
      220,
      scrollable: scrollableWithin(
        const PageStorageKey('buy-tracking-MS-240741'),
      ),
    );
    await Scrollable.ensureVisible(tester.element(action), alignment: .5);
    await tester.pumpAndSettle();
    expect(action.hitTestable(), findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Invoice details missing'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(session.selectedOrder.id, 'MS-240741');
    expect(session.view, BuyV2View.tracking);
    expect(session.refreshCalls, 0);
  });

  testWidgets('R669 invoice missing confirmation uses the same recovery', (
    tester,
  ) async {
    final session = _InvoiceRecoverySession(missingConfirmation: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(body: BuyV2ConfirmationView(session: session)),
      ),
    );
    await tester.pumpAndSettle();
    final id = session.confirmedOrders.single.id;
    final action = find.byKey(ValueKey('buy-confirmation-invoice-$id'));
    await tester.scrollUntilVisible(action, 220);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Invoice details missing'), findsOneWidget);
    expect(find.byType(BuyV2InvoicePage), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BuyV2ConfirmationView), findsOneWidget);
    expect(session.refreshCalls, 0);
  });

  testWidgets('R669 invoice refresh rejects an unmounted originating session', (
    tester,
  ) async {
    final oldSession = _InvoiceRecoverySession(missingConfirmation: true);
    final replacement = _InvoiceRecoverySession(missingConfirmation: true);
    final active = ValueNotifier<BuyV2Session>(oldSession);
    addTearDown(active.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: ValueListenableBuilder<BuyV2Session>(
          valueListenable: active,
          builder: (_, session, _) => Scaffold(
            body: BuyV2ConfirmationView(
              key: ObjectKey(session),
              session: session,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final id = oldSession.confirmedOrders.single.id;
    final action = find.byKey(ValueKey('buy-confirmation-invoice-$id'));
    await tester.scrollUntilVisible(action, 220);
    await tester.tap(action);
    await tester.pumpAndSettle();
    active.value = replacement;
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('buy-invoice-refresh-$id')));
    await tester.pumpAndSettle();
    expect(oldSession.refreshCalls, 0);
    expect(replacement.refreshCalls, 0);
    expect(find.byType(BuyV2InvoicePage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('RV6 D008 buyer identity separation $width text $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.reset);
        final session = BuyV2Session(core: BuySession());
        await tester.pumpWidget(
          app(session, textScale: scale, disableAnimations: true),
        );
        await tester.pumpAndSettle();
        session.openOrders();
        session.showOrdersTab(BuyV2OrdersTab.delivered);
        session.updateQuery('PO-240728');
        await tester.pumpAndSettle();
        final order = session.visibleOrders.single;
        expect(order.buyerType, 'Retailer business');
        expect(order.buyerName, 'Shree Balaji Retail');
        final action = find.byKey(
          const ValueKey('buy-order-primary-PO-240728'),
        );
        await tester.scrollUntilVisible(
          action,
          160,
          scrollable: scrollableWithin(
            const PageStorageKey('buy-orders'),
          ).first,
        );
        await tester.tap(action);
        await tester.pumpAndSettle();
        final buyer = find.text(order.buyerName!);
        await tester.scrollUntilVisible(
          buyer,
          160,
          scrollable: scrollableWithin(
            const PageStorageKey('buy-tracking-PO-240728'),
          ).first,
        );
        await Scrollable.ensureVisible(tester.element(buyer), alignment: .5);
        await tester.pumpAndSettle();
        final label = find.text(order.buyerType!);
        final labelRect = tester.getRect(label);
        final valueRect = tester.getRect(buyer);
        if (scale == 1) {
          expect(
            valueRect.left - labelRect.right,
            greaterThanOrEqualTo(8),
            reason:
                'The buyer label and business name need an explicit visible gap.',
          );
        } else {
          expect(
            valueRect.top - labelRect.bottom,
            greaterThanOrEqualTo(3),
            reason:
                'Enlarged text must keep the label above the complete business name.',
          );
        }
        for (final field in [label, buyer]) {
          final paragraph = tester.renderObject<RenderParagraph>(field);
          expect(paragraph.didExceedMaxLines, isFalse);
          final rect = tester.getRect(field);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(800));
        }
        expect(tester.takeException(), isNull);
        await captureR66Visual(tester, 'rv6-d008-buyer-$width-text-$scale');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.destination, BuyV2Destination.orders);
        expect(session.view, BuyV2View.catalogue);
        expect(session.ordersTab, BuyV2OrdersTab.delivered);
        expect(session.query, 'PO-240728');
        expect(session.visibleOrders.single, same(order));
        expect(session.cartLines, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'Orders automatically shows active and delivered without selectors',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 900);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      session.openOrders();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-orders-filter')), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-orders-section-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-orders-section-delivered')),
        findsOneWidget,
      );
      for (final order in session.visibleOrderHistory) {
        expect(
          find.byKey(ValueKey('buy-order-card-${order.id}')),
          findsOneWidget,
        );
      }
      await captureR66Visual(tester, 'orders-feed-active-delivered');
      expect(find.text('Reorder'), findsNothing);
      final cartBefore = session.cartLines.length;
      session.showOrdersTab(BuyV2OrdersTab.delivered);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-orders-section-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-orders-section-delivered')),
        findsOneWidget,
      );
      final delivered = session.visibleOrderHistory.firstWhere(
        session.orderIsCompleted,
      );
      final open = find.byKey(ValueKey('buy-order-primary-${delivered.id}'));
      await tester.scrollUntilVisible(
        open,
        200,
        scrollable: scrollableWithin(const PageStorageKey('buy-orders')),
      );
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(session.selectedOrder.id, delivered.id);
      expect(session.view, BuyV2View.tracking);
      expect(session.cartLines.length, cartBefore);
    },
  );

  testWidgets(
    'T14 combined history preserves split purchases and search guards',
    (tester) async {
      final session = _T14MixedHistorySession();
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      session.openOrders();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('buy-order-card-T14-HISTORY-A')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-order-card-T14-HISTORY-D')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-order-card-T14-HISTORY-M')),
        findsNothing,
      );
      expect(find.text('Payment needs checking'), findsNWidgets(2));
      session.updateQuery('T14-HISTORY-D');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-order-card-T14-HISTORY-A')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-order-card-T14-HISTORY-D')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-orders-section-active')),
        findsNothing,
      );
      session.updateQuery('unmatched history');
      await tester.pumpAndSettle();
      expect(find.text('No orders match this search'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shared search filters Orders by an existing order ID', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.orders);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
    expect(find.text('Search orders or ID'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      'MS-240782',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-order-card-MS-240782')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-order-card-MS-240783')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-order-card-MS-240784')),
      findsNothing,
    );
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets('R66 032 basket preview price and actions fit $textScale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      await tester.pumpWidget(
        app(
          session,
          textScale: textScale,
          safePadding: const EdgeInsets.only(bottom: 32),
          captureCart: const bool.fromEnvironment(
            'BUY_R66_MONTHLY_BASKET_CAPTURE',
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        showBuyV2HouseholdBasket(
          tester.element(find.byType(BuyV2Screen)),
          session,
        ),
      );
      await tester.pumpAndSettle();
      final sheet = find.byKey(
        const ValueKey('buy-household-basket-info-sheet'),
      );
      expect(find.text('Product subtotal ₹5,145'), findsOneWidget);
      expect(find.text('Save ₹415'), findsNothing);
      expect(find.text('12 products'), findsOneWidget);
      expect(find.text('21 packs'), findsOneWidget);
      expect(find.text('Quick · 6 products'), findsOneWidget);
      expect(find.text('Scheduled · 6 products'), findsOneWidget);
      for (final richText
          in find
              .descendant(of: sheet, matching: find.byType(RichText))
              .evaluate()) {
        final paragraph = richText.renderObject! as RenderParagraph;
        final painter = TextPainter(
          text: paragraph.text,
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
        )..layout(maxWidth: paragraph.size.width);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          paragraph.size.height + .1,
          greaterThanOrEqualTo(painter.height),
        );
        painter.dispose();
      }
      await _captureR66MonthlyBasket(tester, '$textScale-price');
      final add = find.byKey(const ValueKey('buy-household-add-to-cart'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      expect(tester.getRect(add).bottom, lessThanOrEqualTo(748));
      expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
      await _captureR66MonthlyBasket(tester, '$textScale-actions');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.itemCount, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 2.0]) {
    for (final mode in ['quick', 'courier']) {
      testWidgets('R669 Monthly vertical discovery $mode text $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        expect(session.addProduct('w-notebook'), isTrue);
        final retainedWholesale = session.quantityFor('w-notebook');
        await tester.pumpWidget(
          app(
            session,
            textScale: scale,
            safePadding: const EdgeInsets.only(top: 24, bottom: 34),
          ),
        );
        await tester.pumpAndSettle();
        final monthly = find.byKey(const ValueKey('buy-promotion-shop-basket'));
        await tester.ensureVisible(monthly);
        await tester.tap(monthly);
        await tester.pumpAndSettle();
        final see = find.byKey(const ValueKey('buy-household-see-products'));
        await tester.ensureVisible(see);
        await tester.tap(see);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('buy-shop-sale-type-$mode')));
        await tester.pumpAndSettle();
        final expected = session.catalogueSaleTypeProducts
            .map((p) => p.id)
            .toSet();
        expect(expected, hasLength(6));
        final visited = <String>{};
        final scrollView = find.descendant(
          of: find.byType(BuyV2CatalogueView),
          matching: find.byType(CustomScrollView),
        );
        expect(scrollView, findsOneWidget);
        for (var step = 0; step < 35; step++) {
          for (final id in expected) {
            final add = find.byKey(ValueKey('buy-add-$id'));
            if (add.hitTestable().evaluate().isNotEmpty) {
              final box = tester.getRect(add);
              if (box.left >= 0 && box.right <= 360) visited.add(id);
            }
          }
          final viewport = tester.getRect(scrollView);
          await tester.dragFrom(
            Offset(viewport.right - 12, viewport.bottom - 70),
            const Offset(0, -220),
          );
          await tester.pumpAndSettle();
        }
        await captureR66Visual(tester, 'r669-monthly-$mode-$scale-bottom');
        expect(
          visited,
          expected,
          reason:
              'Every Monthly SKU Add action must be discoverable with vertical scrolling alone.',
        );
        final id = expected.last;
        final add = find.byKey(ValueKey('buy-add-$id'));
        await tester.ensureVisible(add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        final quantity = session.quantityFor(id);
        if (mode == 'quick') {
          expect(quantity, greaterThan(0));
          final card = find.byKey(ValueKey('buy-product-$id'));
          await tester.ensureVisible(card);
          await tester.tap(card);
          await tester.pumpAndSettle();
        } else {
          expect(quantity, 0, reason: 'Scheduled review must not invent a selected slot or add a Cart line.');
          expect(session.view, BuyV2View.product);
        }
        expect(session.selectedProductId, id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.showingMonthlyBasketProducts, isTrue);
        expect(session.quantityFor(id), quantity);
        expect(session.quantityFor('w-notebook'), retainedWholesale);
        expect(
          session.catalogueSaleTypeProducts.map((p) => p.id).toSet(),
          expected,
        );
        await captureR66Visual(tester, 'r669-monthly-$mode-$scale-return');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('R66 032 monthly basket keeps price groups and Shop Cart scope', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.addProduct('w-notebook'), isTrue);
    final wholesaleQuantity = session.quantityFor('w-notebook');
    final wholesaleTotal = session.totalForDestination(
      BuyV2Destination.wholesale,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-promotion-shop-basket')));
    await tester.pumpAndSettle();
    final see = find.byKey(const ValueKey('buy-household-see-products'));
    await tester.ensureVisible(see);
    await tester.pumpAndSettle();
    await tester.tap(see);
    await tester.pumpAndSettle();
    expect(find.text('6 of 12 basket products · Quick'), findsOneWidget);
    expect(session.catalogueSaleTypeProducts.length, 6);
    await tester.tap(find.byKey(const ValueKey('buy-shop-sale-type-courier')));
    await tester.pumpAndSettle();
    expect(find.text('6 of 12 basket products · Scheduled'), findsOneWidget);
    expect(session.catalogueSaleTypeProducts.length, 6);

    Future<void> addBasket() async {
      unawaited(
        showBuyV2HouseholdBasket(
          tester.element(find.byType(BuyV2Screen)),
          session,
        ),
      );
      await tester.pumpAndSettle();
      final add = find.byKey(const ValueKey('buy-household-add-to-cart'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
    }

    await addBasket();
    expect(session.countForDestination(BuyV2Destination.shop), 21);
    expect(session.totalForDestination(BuyV2Destination.shop), 5145);
    expect(
      session.cartAcknowledgementForDestination(BuyV2Destination.shop),
      'Monthly basket ready · 12 products',
    );
    await addBasket();
    expect(session.countForDestination(BuyV2Destination.shop), 21);
    expect(session.quantityFor('w-notebook'), wholesaleQuantity);
    expect(
      session.totalForDestination(BuyV2Destination.wholesale),
      wholesaleTotal,
    );
    session.openCart(scope: BuyV2CartScope.shop);
    await tester.pumpAndSettle();
    expect(find.text('Monthly basket'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-shopping-intent-bar')),
      findsOneWidget,
    );
    session.openCart(scope: BuyV2CartScope.wholesale);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Checkout'));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.checkout);
    for (final step in BuyV2CheckoutStep.values) {
      session.showCheckoutStep(step);
      await tester.pumpAndSettle();
      expect(session.checkoutScope, BuyV2CartScope.all);
      expect(session.checkoutAmountDueNow, 5145 + wholesaleTotal);
      expect(session.checkoutLines, hasLength(13));
      expect(session.quantityFor('w-notebook'), wholesaleQuantity);
      expect(
        find.byKey(const ValueKey('buy-shopping-intent-bar')),
        findsNothing,
      );
      await captureR66Visual(tester, '032-wholesale-checkout-${step.name}');
      tester.view.physicalSize = const Size(800, 360);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shopping-intent-bar')),
        findsNothing,
      );
      expect(session.checkoutAmountDueNow, 5145 + wholesaleTotal);
      expect(session.checkoutLines, hasLength(13));
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
    }
    session.openCart(scope: BuyV2CartScope.shop);
    await tester.pumpAndSettle();
    expect(find.text('Monthly basket'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-shopping-intent-bar')),
      findsOneWidget,
    );
    expect(session.clearCartScope(BuyV2CartScope.shop), isTrue);
    await tester.pumpAndSettle();
    expect(session.quantityFor('w-notebook'), wholesaleQuantity);
    expect(find.byKey(const ValueKey('buy-shopping-intent-bar')), findsNothing);
    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    expect(session.catalogueSaleTypeProducts, isNotEmpty);
    expect(find.byKey(const ValueKey('buy-shopping-intent-bar')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final saved in [false, true]) {
    // Follow-up device cases preserve a manually moved Cart across actions.
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R66 R2 Cart clears retained actions saved=$saved scale=$scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(360, 800);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          session.addProduct('w-notebook');
          if (saved) session.addProduct('s-tomato');
          await tester.pumpWidget(app(session, textScale: scale));
          await tester.pumpAndSettle();
          if (saved) {
            session.toggleSaved('s-tomato');
            session.showSavedProducts(true);
          } else {
            session.openOrders();
            session.showOrdersTab(BuyV2OrdersTab.delivered);
          }
          await tester.pumpAndSettle();
          final order = session.orders.firstWhere(
            (order) => order.status == BuyV2OrderStatus.delivered,
          );
          final action = find.byKey(
            ValueKey(
              saved ? 'buy-saved-clear' : 'buy-order-primary-${order.id}',
            ),
          );
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          final cart = find.byKey(const ValueKey('buy-compact-cart-indicator'));
          await tester.dragFrom(
            tester.getCenter(cart),
            tester.getCenter(action) - tester.getCenter(cart),
          );
          await tester.pumpAndSettle();
          expect(
            tester.getRect(cart).overlaps(tester.getRect(action)),
            isFalse,
          );
          await captureR66Visual(tester, '004-action-saved-$saved-text-$scale');
          await tester.tap(action);
          await tester.pumpAndSettle();
          if (saved) {
            expect(
              find.byKey(const ValueKey('buy-saved-clear-sheet')),
              findsOneWidget,
            );
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
          } else {
            expect(session.selectedOrderOrNull?.id, order.id);
            expect(session.view, BuyV2View.tracking);
          }
          expect(session.quantityFor('w-notebook'), 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
    BuyV2Destination.medicine,
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R66 R3 Cart permits Save and Remove ${destination.name} $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(800, 360);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          session.addProduct('w-notebook');
          await tester.pumpWidget(app(session, textScale: scale));
          await tester.pumpAndSettle();
          session.openDestination(destination);
          final product = session.visibleProducts.first;
          expect(session.addProduct(product.id), isTrue);
          await tester.pumpAndSettle();
          for (final remove in [false, true]) {
            if (remove) session.showSavedProducts(true);
            await tester.pumpAndSettle();
            final actions = find.byKey(ValueKey('buy-save-${product.id}'));
            final action = actions.first;
            final scrollable = find
                .descendant(
                  of: find.byType(BuyV2CatalogueView),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        widget.axisDirection == AxisDirection.down,
                  ),
                )
                .first;
            await tester.drag(scrollable, const Offset(0, -240));
            await tester.pumpAndSettle();
            for (var attempt = 0; attempt < 40; attempt += 1) {
              if (actions.evaluate().isEmpty) {
                await tester.drag(scrollable, const Offset(0, -60));
                await tester.pumpAndSettle();
                continue;
              }
              final rect = tester.getRect(action);
              final viewport = tester.getRect(
                find.byKey(const ValueKey('buy-cart-content-viewport')),
              );
              final toolbarBottom = tester
                  .getRect(find.byKey(const ValueKey('buy-catalogue-toolbar')))
                  .bottom;
              final top = toolbarBottom > viewport.top
                  ? toolbarBottom
                  : viewport.top;
              final bottom = viewport.bottom;
              if (rect.top >= top && rect.bottom <= bottom) break;
              await tester.drag(
                scrollable,
                Offset(0, rect.top < top ? 60 : -60),
              );
              await tester.pumpAndSettle();
            }
            expect(
              action.hitTestable(),
              findsOneWidget,
              reason: 'Reveal the action below the sticky catalogue controls',
            );
            final cart = find.byKey(
              const ValueKey('buy-compact-cart-indicator'),
            );
            final scrollBeforeDrag = tester
                .state<ScrollableState>(scrollable)
                .position
                .pixels;
            await tester.dragFrom(
              tester.getCenter(cart),
              tester.getCenter(action) - tester.getCenter(cart),
            );
            await tester.pumpAndSettle();
            expect(
              tester.state<ScrollableState>(scrollable).position.pixels,
              closeTo(scrollBeforeDrag, .01),
              reason: 'Dragging Cart must not scroll the catalogue beneath it',
            );
            expect(action.hitTestable(), findsOneWidget);
            final contentBounds = tester.getRect(
              find.byKey(const ValueKey('buy-cart-content-viewport')),
            );
            for (final region
                in find.byType(BuyV2CartAvoidanceRegion).evaluate()) {
              final box = region.renderObject! as RenderBox;
              if (!box.hasSize) continue;
              final visible = (box.localToGlobal(Offset.zero) & box.size)
                  .intersect(contentBounds);
              if (visible.isEmpty) continue;
              expect(
                tester.getRect(cart).overlaps(visible),
                isFalse,
                reason:
                    'Cart must clear every visible registered fact and action',
              );
            }
            await captureR66Visual(
              tester,
              '004-r3-${destination.name}-remove-$remove-text-$scale',
            );
            final overlapped = tester
                .getRect(cart)
                .overlaps(tester.getRect(action));
            expect(
              tester
                  .getRect(cart)
                  .overlaps(
                    tester.getRect(
                      find.byKey(const ValueKey('buy-catalogue-toolbar')),
                    ),
                  ),
              isFalse,
            );
            await tester.tapAt(tester.getCenter(action));
            await tester.pumpAndSettle();
            expect(
              session.isSaved(product.id),
              !remove,
              reason:
                  'The visible Save/Remove tap must reach the product action',
            );
            expect(session.view, BuyV2View.catalogue);
            expect(overlapped, isFalse);
            expect(session.quantityFor('w-notebook'), 1);
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (var route = 0; route < 3; route++) {
    for (var scenario = 0; scenario < 4; scenario++) {
      final routeName = [
        'active tracking',
        'delivered tracking',
        'Orders history',
      ][route];
      final stateName = [
        'missing payment',
        'paid',
        'balance due',
        'long text 200 percent',
      ][scenario];
      testWidgets(
        'R6634 C04-${route * 4 + scenario + 1} $routeName $stateName',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 844);
          addTearDown(tester.view.reset);
          final order = BuyV2Order(
            id: 'R6634-TRACK',
            destination: BuyV2Destination.shop,
            title: 'Shop order',
            itemSummary: '1 product',
            total: 100,
            partner: scenario == 3
                ? 'Sardarpura Family Grocery and Household Supplies'
                : 'Store',
            partnerType: 'Retailer',
            promise: 'Delivery in 20 min',
            destinationLabel: 'Jodhpur',
            progress: route == 1 ? 1 : .4,
            status: route == 1
                ? BuyV2OrderStatus.delivered
                : BuyV2OrderStatus.preparing,
            paymentMethod: scenario == 0 ? null : 'UPI',
            amountPaidNow: scenario == 0
                ? null
                : scenario == 2
                ? 40
                : 100,
            balanceDue: scenario == 2 ? 60 : 0,
            paymentStatusLabel: scenario == 0
                ? null
                : scenario == 2
                ? 'Part paid'
                : 'Paid',
          );
          final session = _R6634TrackingSession(order);
          addTearDown(session.dispose);
          final semantics = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              MaterialApp(
                builder: (context, child) => r66VisualCaptureRoot(child!),
                theme: MoolTheme.light(),
                home: MediaQuery(
                  data: MediaQueryData(
                    textScaler: TextScaler.linear(scenario == 3 ? 2 : 1),
                    padding: const EdgeInsets.only(bottom: 24),
                  ),
                  child: Scaffold(
                    body: route == 2
                        ? BuyV2OrdersView(
                            session: session,
                            onOpenOrderHelp: (_) {},
                          )
                        : BuyV2TrackingView(
                            session: session,
                            onOpenOrderHelp: (_) {},
                          ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            if (route == 2) {
              final card = find.byKey(
                const ValueKey('buy-order-card-R6634-TRACK'),
              );
              expect(card, findsOneWidget);
              final label = tester.getSemantics(card).label;
              expect('Preparing your order'.allMatches(label).length, 1);
            } else {
              final payment = find.text('Payment');
              if (scenario == 0) {
                expect(payment, findsNothing);
              } else {
                await tester.scrollUntilVisible(
                  payment,
                  180,
                  scrollable: find.byType(Scrollable).first,
                );
                expect(payment, findsOneWidget);
                expect(find.text('Payment method'), findsOneWidget);
              }
              if (scenario == 2) {
                expect(find.text('Upcoming balance'), findsOneWidget);
              }
            }
            await captureR66Visual(tester, 'r6634-c04-$route-$scenario');
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -600),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  test('R66 R2 catalogue promises describe future delivery', () {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    expect(session.product('s-tomato').deliveryPromise, 'Delivery in 12 min');
    expect(buyV2BuyerDeliveryPromiseSource('5 minutes'), 'Delivery in 5 min');
    expect(buyV2BuyerDeliveryPromiseSource('1 day'), 'Delivery in 1 day');
    for (final dispatch in ['Dispatch in one day', 'Dispatch in 2 days']) {
      expect(
        buyV2BuyerDeliveryPromiseSource(dispatch),
        dispatch,
        reason: 'Dispatch must not become an arrival promise',
      );
    }
    expect(
      buyV2BuyerDeliveryPromiseSource('Delivered in 12 min'),
      'Delivery in 12 min',
    );
    for (final product in BuyV2Catalogue.products) {
      expect(product.deliveryPromise.startsWith('Delivered'), isFalse);
    }
    session.chooseFilter('fast');
    expect(session.visibleProducts.map((p) => p.id), contains('s-tomato'));
    expect(
      session.orders
          .where((o) => o.status == BuyV2OrderStatus.delivered)
          .every((o) => o.promise.startsWith('Delivered')),
      isTrue,
    );
    for (final order in session.orders.where(
      (o) => o.status == BuyV2OrderStatus.delivered,
    )) {
      expect(
        buyV2OrderPromiseSummary(order).startsWith('Original promise: '),
        isTrue,
      );
      expect(buyV2OrderPromiseSummary(order), isNot(contains('Delivered in')));
    }
  });

  for (final missingCatalogue in [true, false]) {
    testWidgets(
      'R66 032 basket rejects unavailable products $missingCatalogue',
      (tester) async {
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: !missingCatalogue,
          productFactsAdapter: const _StoreStatusFactsAdapter(
            state: BuyV2StoreOperatingState.closed,
            nextOpeningLabel: 'tomorrow at 8:00 am',
          ),
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        if (!missingCatalogue) {
          expect(session.addProduct('w-notebook'), isTrue);
        }
        final beforeCount = session.itemCount;
        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();
        unawaited(
          showBuyV2HouseholdBasket(
            tester.element(find.byType(BuyV2Screen)),
            session,
          ),
        );
        await tester.pumpAndSettle();
        expect(session.monthlyBasketCanAdd, isFalse);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('buy-household-add-to-cart')),
              )
              .onPressed,
          isNull,
        );
        if (missingCatalogue) {
          expect(session.monthlyBasketPlan, isEmpty);
          expect(
            find.text('Basket prices are unavailable right now'),
            findsOneWidget,
          );
          expect(find.text('Product subtotal ₹5,145'), findsNothing);
        }
        session.addMonthlyBasket();
        expect(session.itemCount, beforeCount);
        expect(session.countForDestination(BuyV2Destination.shop), 0);
        expect(
          session.notice,
          'Some basket products are unavailable. Review products first.',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
    BuyV2Destination.medicine,
  ]) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets(
        'R66 landscape ${destination.name} $textScale retains usable product actions',
        (tester) async {
          final originalErrorHandler = FlutterError.onError;
          FlutterError.onError = (details) {
            debugPrint(details.toString());
            originalErrorHandler?.call(details);
          };
          addTearDown(() => FlutterError.onError = originalErrorHandler);
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(800, 360);
          final session = BuyV2Session(core: BuySession());
          await tester.pumpWidget(
            app(
              session,
              textScale: textScale,
              safePadding: const EdgeInsets.only(bottom: 32),
              captureCart: const bool.fromEnvironment(
                'BUY_R66_LANDSCAPE_CAPTURE',
              ),
            ),
          );
          await tester.pumpAndSettle();
          session.openDestination(destination);
          await tester.pumpAndSettle();

          final product = session.visibleProducts.first;
          session.openProduct(product.id);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'landscape product');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);

          final catalogue = find.byType(BuyV2CatalogueView);
          expect(tester.getSize(catalogue).width, greaterThan(700));
          final scrollable = find
              .descendant(
                of: catalogue,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.down,
                ),
              )
              .first;
          await tester.drag(scrollable, const Offset(0, -240));
          await tester.pumpAndSettle();
          final dockTop = tester
              .getRect(
                find.byKey(const Key('moolsocial-compact-destination-rail')),
              )
              .top;
          expect(
            dockTop - tester.getRect(scrollable).top,
            greaterThanOrEqualTo(180),
          );
          final add = find.byKey(ValueKey('buy-add-${product.id}'));
          for (var attempt = 0; attempt < 40; attempt += 1) {
            final visibleTop = tester.getRect(scrollable).top;
            var drag = -100.0;
            if (add.evaluate().isNotEmpty) {
              final rect = tester.getRect(add);
              if (rect.top >= visibleTop &&
                  rect.bottom <= dockTop &&
                  add.hitTestable().evaluate().isNotEmpty) {
                break;
              }
              if (rect.top < visibleTop) drag = 100;
            }
            await tester.drag(scrollable, Offset(0, drag));
            await tester.pumpAndSettle();
          }
          final selectedCard = tester.getRect(
            find.byKey(ValueKey('buy-product-${product.id}')),
          );
          expect(selectedCard.left, greaterThanOrEqualTo(0));
          expect(selectedCard.right, lessThanOrEqualTo(800));
          final action = tester.getRect(add);
          expect(action.height, greaterThanOrEqualTo(44));
          expect(action.width, greaterThanOrEqualTo(44));
          expect(
            action.top,
            greaterThanOrEqualTo(tester.getRect(scrollable).top),
          );
          expect(action.bottom, lessThanOrEqualTo(dockTop));
          expect(add.hitTestable(), findsOneWidget);
          await _captureR66Landscape(
            tester,
            '${destination.name}-$textScale-product-action',
          );
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(session.quantityFor(product.id), product.minimumOrder);
          final miniCart = find.byKey(
            const ValueKey('buy-compact-cart-indicator'),
          );
          expect(miniCart.hitTestable(), findsOneWidget);
          final navigationCart = find.byKey(
            const ValueKey('buy-cart-navigation-button'),
          );
          if (navigationCart.evaluate().isNotEmpty) {
            expect(
              find.descendant(of: miniCart, matching: navigationCart),
              findsOneWidget,
            );
            expect(navigationCart.hitTestable(), findsOneWidget);
            final cartBounds = tester.getRect(navigationCart);
            expect(cartBounds.width, greaterThanOrEqualTo(44));
            expect(cartBounds.height, greaterThanOrEqualTo(44));
            expect(cartBounds.top, greaterThanOrEqualTo(dockTop));
            expect(cartBounds.bottom, lessThanOrEqualTo(360 - 32));
            expect(cartBounds.right, lessThanOrEqualTo(800));
            final navigationScroll = find.byKey(
              const PageStorageKey('buy-compact-cart-local-navigation-scroll'),
            );
            expect(navigationScroll, findsOneWidget);
            expect(
              cartBounds.left,
              greaterThanOrEqualTo(tester.getRect(navigationScroll).right),
            );
            expect(
              cartBounds.overlaps(tester.getRect(navigationScroll)),
              isFalse,
            );
          } else {
            expect(tester.getRect(miniCart).bottom, lessThanOrEqualTo(dockTop));
          }
          expect(
            tester.getRect(miniCart).top,
            greaterThanOrEqualTo(tester.getRect(catalogue).top),
          );
          List<BuyV2Product> visibleNeighbours() =>
              session.visibleProducts.where((candidate) {
                if (candidate.id == product.id) return false;
                final control = find.byKey(ValueKey('buy-add-${candidate.id}'));
                if (control.evaluate().isEmpty) return false;
                final rect = tester.getRect(control);
                return rect.left >= 0 &&
                    rect.right <= 800 &&
                    rect.top >= tester.getRect(scrollable).top &&
                    rect.bottom <= dockTop;
              }).toList();
          var neighbours = visibleNeighbours();
          if (neighbours.isEmpty) {
            final nextProduct = session.visibleProducts.firstWhere(
              (candidate) =>
                  candidate.id != product.id &&
                  find
                      .byKey(ValueKey('buy-add-${candidate.id}'))
                      .evaluate()
                      .isNotEmpty,
            );
            final nextAction = find.byKey(
              ValueKey('buy-add-${nextProduct.id}'),
            );
            await Scrollable.ensureVisible(
              tester.element(nextAction),
              alignment: .4,
            );
            await tester.pumpAndSettle();
            neighbours = visibleNeighbours();
          }
          expect(neighbours, isNotEmpty);
          final neighbour = neighbours.first;
          final neighbourAdd = find.byKey(ValueKey('buy-add-${neighbour.id}'));
          expect(neighbourAdd, findsOneWidget);
          final neighbourAction = tester.getRect(neighbourAdd);
          expect(neighbourAction.left, greaterThanOrEqualTo(0));
          expect(neighbourAction.right, lessThanOrEqualTo(800));
          expect(
            neighbourAction.top,
            greaterThanOrEqualTo(tester.getRect(scrollable).top),
          );
          expect(neighbourAction.bottom, lessThanOrEqualTo(dockTop));
          for (final candidate in session.visibleProducts) {
            for (final key in [
              'buy-add-${candidate.id}',
              'buy-review-offer-${candidate.id}',
              'buy-featured-quantity-shell-${candidate.id}',
            ]) {
              final control = find.byKey(ValueKey(key));
              if (control.evaluate().isEmpty) continue;
              final rect = tester.getRect(control);
              if (rect.left < 0 ||
                  rect.right > 800 ||
                  rect.top < tester.getRect(scrollable).top ||
                  rect.bottom > dockTop) {
                continue;
              }
              expect(
                tester.getRect(miniCart).overlaps(rect),
                isFalse,
                reason: 'Floating Cart must leave $key available',
              );
            }
          }
          expect(neighbourAdd.hitTestable(), findsOneWidget);
          await _captureR66Landscape(
            tester,
            '${destination.name}-$textScale-cart-added',
          );
          await tester.tap(neighbourAdd);
          await tester.pumpAndSettle();
          expect(session.quantityFor(neighbour.id), neighbour.minimumOrder);
          expect(session.quantityFor(product.id), product.minimumOrder);
          final title = find.descendant(
            of: find.byKey(ValueKey('buy-product-${product.id}')),
            matching: find.text(product.title),
          );
          final facts = find
              .ancestor(of: title, matching: find.byType(Column))
              .first;
          await tester.drag(
            scrollable,
            Offset(
              0,
              tester.getRect(scrollable).top + 4 - tester.getRect(facts).top,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.getRect(facts).top,
            greaterThanOrEqualTo(tester.getRect(scrollable).top),
          );
          // Enlarged full metadata can exceed the short landscape viewport.
          // Verify every paragraph can be brought above the dock independently.
          final paragraphs = find.descendant(
            of: facts,
            matching: find.byType(RichText),
          );
          for (var index = 0; index < paragraphs.evaluate().length; index++) {
            final paragraph = paragraphs.at(index);
            await tester.ensureVisible(paragraph);
            await tester.pumpAndSettle();
            final rect = tester.getRect(paragraph);
            expect(
              rect.top,
              greaterThanOrEqualTo(tester.getRect(scrollable).top),
            );
            expect(rect.bottom, lessThanOrEqualTo(dockTop));
          }
          for (final text
              in find
                  .descendant(of: facts, matching: find.byType(RichText))
                  .evaluate()) {
            final paragraph = text.renderObject! as RenderParagraph;
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: paragraph.text.toPlainText(),
            );
          }
          await _captureR66Landscape(
            tester,
            '${destination.name}-$textScale-product-facts',
          );
          if (destination == BuyV2Destination.wholesale) {
            final eta = find
                .descendant(of: facts, matching: find.byType(RichText))
                .last;
            expect(
              tester.renderObject<RenderParagraph>(eta).text.toPlainText(),
              contains(
                RegExp(
                  r'day|min|dispatch|delivery|at checkout',
                  caseSensitive: false,
                ),
              ),
            );
            await tester.scrollUntilVisible(eta, 60, scrollable: scrollable);
            await tester.pumpAndSettle();
            final visibleContent = tester.getRect(
              find.byKey(const ValueKey('buy-cart-content-viewport')),
            );
            final etaRect = tester.getRect(eta);
            expect(etaRect.top, greaterThanOrEqualTo(visibleContent.top));
            expect(etaRect.bottom, lessThanOrEqualTo(visibleContent.bottom));
            expect(tester.getRect(miniCart).overlaps(etaRect), isFalse);
            await _captureR66Landscape(
              tester,
              '${destination.name}-$textScale-delivery-visible',
            );
          }
          final nestedBefore = tester.state<NestedScrollViewState>(
            find.byType(NestedScrollView),
          );
          final outerOffset = nestedBefore.outerController.offset;
          final innerOffset = nestedBefore.innerController.offset;
          final factsTop = tester.getRect(facts).top;
          await tester.tap(miniCart);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'landscape Cart');
          expect(session.view, BuyV2View.cart);
          expect(find.byType(NestedScrollView), findsNothing);
          final cartScroll = scrollableWithin(
            PageStorageKey('buy-cart-${session.cartScope.name}'),
          );
          final review = find.widgetWithText(FilledButton, 'Checkout');
          await tester.scrollUntilVisible(
            review,
            180,
            maxScrolls: 60,
            scrollable: cartScroll,
          );
          await tester.pumpAndSettle();
          final reviewRect = tester.getRect(review);
          expect(reviewRect.height, greaterThanOrEqualTo(44));
          expect(reviewRect.bottom, lessThanOrEqualTo(dockTop));
          expect(
            reviewRect.top,
            greaterThanOrEqualTo(tester.getRect(cartScroll).top),
          );
          expect(review.hitTestable(), findsOneWidget);
          await _captureR66Landscape(
            tester,
            '${destination.name}-$textScale-cart-review',
          );
          await tester.tap(review);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.checkout);
          expect(tester.takeException(), isNull, reason: 'landscape checkout');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          expect(session.destination, destination);
          expect(session.quantityFor(product.id), product.minimumOrder);

          final nestedAfter = tester.state<NestedScrollViewState>(
            find.byType(NestedScrollView),
          );
          expect(nestedAfter.outerController.offset, closeTo(outerOffset, 1));
          expect(nestedAfter.innerController.offset, closeTo(innerOffset, 1));
          expect(tester.getRect(facts).top, closeTo(factsTop, 1));

          final search = find.byKey(const ValueKey('buy-search-control'));
          final restoredScroll = find
              .descendant(
                of: find.byType(NestedScrollView),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            search,
            -160,
            scrollable: restoredScroll,
          );
          await tester.pumpAndSettle();
          expect(search.hitTestable(), findsOneWidget);
          await tester.tap(search);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('buy-search-field')),
            product.title,
          );
          await tester.pumpAndSettle();
          expect(session.query, product.title);
          expect(tester.takeException(), isNull, reason: 'landscape search');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          session.updateQuery('');
          await tester.pumpAndSettle();

          tester.view.physicalSize = const Size(360, 800);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'portrait rotation');
          expect(find.byType(NestedScrollView), findsNothing);
          expect(tester.getSize(catalogue).width, 360);
          expect(session.quantityFor(product.id), product.minimumOrder);
          tester.view.physicalSize = const Size(800, 360);
          await tester.pumpAndSettle();
          expect(tester.getSize(catalogue).width, greaterThan(700));
          expect(session.quantityFor(product.id), product.minimumOrder);
          session.clearCart();
          session.openCart();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          final otherProductId = destination == BuyV2Destination.shop
              ? 'w-notebook'
              : 's-tomato';
          session.addProduct(otherProductId);
          session.openCart(
            scope: BuyV2CartScope.values.byName(destination.name),
          );
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          final browse = find.byKey(const ValueKey('buy-empty-cart-browse'));
          if (destination == BuyV2Destination.medicine) {
            expect(session.cartLines, isEmpty);
            await tester.scrollUntilVisible(
              browse,
              120,
              scrollable: scrollableWithin(
                PageStorageKey('buy-cart-${session.cartScope.name}'),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.getRect(browse).height, greaterThanOrEqualTo(44));
            expect(tester.getRect(browse).bottom, lessThanOrEqualTo(dockTop));
            expect(browse.hitTestable(), findsOneWidget);
            await tester.tap(browse);
          } else {
            final retained = session.product(otherProductId);
            expect(session.cartLines, hasLength(1));
            expect(session.cartLines.single.product.id, otherProductId);
            expect(session.quantityFor(otherProductId), retained.minimumOrder);
            expect(session.cartTotal, retained.price * retained.minimumOrder);
            expect(browse, findsNothing);
            await tester.binding.handlePopRoute();
          }
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          expect(session.quantityFor(otherProductId), greaterThan(0));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('first-party promotions use established Buy actions', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-promotion-shop-basket')));
    await tester.pumpAndSettle();
    expect(find.text('Monthly home basket'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-promotion-wholesale-restock')),
    );
    await tester.pumpAndSettle();
    expect(session.selectedFilter, 'moq');

    session.openDestination(BuyV2Destination.medicine);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-promotion-medicine-prescription')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Prescription centre'), findsWidgets);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.orders);
    await tester.pumpAndSettle();
    final firstOrder = session.visibleOrders.first;
    expect(
      find.byKey(ValueKey('buy-order-card-${firstOrder.id}')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-orders-promotions')),
      180,
      scrollable: scrollableWithin(const PageStorageKey('buy-orders')),
    );
    expect(find.byKey(const ValueKey('buy-orders-promotions')), findsOneWidget);
  });

  testWidgets(
    'promotion and featured product remain usable at 320 and 140 percent',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-featured-products')),
        findsOneWidget,
      );
      final product = session.visibleProducts.first;
      final dockTop = tester
          .getRect(find.byKey(const Key('moolsocial-compact-destination-rail')))
          .top;
      final card = find.byKey(ValueKey('buy-product-${product.id}'));
      expect(tester.getRect(card).top, lessThan(dockTop));
      final add = find.byKey(ValueKey('buy-add-${product.id}'));
      await tester.scrollUntilVisible(
        add,
        160,
        scrollable: find
            .descendant(
              of: find.byType(BuyV2CatalogueView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(card);
      final action = tester.getRect(add);
      expect(action.height, 44);
      expect(action.width, greaterThanOrEqualTo(44));
      expect(rect.contains(action.center), isTrue);
      expect(action.bottom, lessThanOrEqualTo(dockTop));
      expect(add.hitTestable(), findsOneWidget);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(session.quantityFor(product.id), 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    for (final exit in ['button', 'back', 'help']) {
      testWidgets(
        'RV6 D010 recovery preserves Orders context text $scale via $exit',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(360, 800);
          addTearDown(tester.view.reset);
          final session = BuyV2Session(core: BuySession());
          Widget route(bool recovery) => MaterialApp(
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: r66VisualCaptureRoot(child!),
            ),
            home: BuyV2Screen(
              session: session,
              initialView: recovery ? BuyV2View.recovery : BuyV2View.tracking,
              orderId: recovery ? null : 'MS-240782',
              recoveryKind: recovery ? BuyV2RecoveryKind.deliveryDelay : null,
            ),
          );
          await tester.pumpWidget(route(false));
          await tester.pumpAndSettle();
          expect(session.destination, BuyV2Destination.orders);
          final order = session.selectedOrder;
          final orders = session.orders.map((item) => item.id).toList();
          await tester.pumpWidget(route(true));
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.recovery);
          if (exit == 'back') {
            await tester.binding.handlePopRoute();
          } else {
            final action = exit == 'help'
                ? find.text('Get help')
                : find.byKey(const ValueKey('buy-recovery-primary'));
            await tester.scrollUntilVisible(
              action,
              140,
              scrollable: find
                  .descendant(
                    of: find.byType(BuyV2RecoveryView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.tap(action);
          }
          await tester.pumpAndSettle();
          if (exit == 'help') {
            // This MaterialApp has no Chat router: the existing honest fallback
            // must still leave the exact originating order selected.
            expect(session.notice, contains('Shop Chat is unavailable'));
          }
          expect(session.view, BuyV2View.tracking);
          expect(session.destination, BuyV2Destination.orders);
          expect(session.selectedOrder, same(order));
          expect(session.selectedOrder.id, 'MS-240782');
          expect(session.orders.map((item) => item.id).toList(), orders);
          expect(session.cartLines, isEmpty);
          expect(tester.takeException(), isNull);
          if (exit == 'button') {
            await captureR66Visual(
              tester,
              'rv6-d010-orders-return-text-$scale',
            );
          }
        },
      );
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'RV6 D010 routed Help Back retains recovery order text $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        addTearDown(tester.view.reset);
        final session = BuyV2Session(core: BuySession());
        Uri? helpUri;
        final router = GoRouter(
          initialLocation: '/app/buy?view=tracking&order=MS-240782',
          routes: [
            GoRoute(
              path: '/app/buy',
              builder: (context, state) {
                final recovery =
                    state.uri.queryParameters['view'] == 'recovery';
                return BuyV2Screen(
                  session: session,
                  initialView: recovery
                      ? BuyV2View.recovery
                      : BuyV2View.tracking,
                  orderId: recovery ? null : state.uri.queryParameters['order'],
                  recoveryKind: recovery
                      ? BuyV2RecoveryKind.deliveryDelay
                      : null,
                );
              },
            ),
            GoRoute(
              path: '/app/chat/thread/:threadId',
              builder: (context, state) {
                helpUri = state.uri;
                return const Scaffold(
                  key: ValueKey('d010-help-route'),
                  body: Text('Conversation'),
                );
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: MoolTheme.light(),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final order = session.selectedOrder;
        router.go('/app/buy?view=recovery&recovery=delay');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Get help'),
          140,
          scrollable: find
              .descendant(
                of: find.byType(BuyV2RecoveryView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(find.text('Get help'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('d010-help-route')), findsOneWidget);
        final returnUri = Uri.parse(helpUri!.queryParameters['return']!);
        expect(returnUri.queryParameters['sub'], 'orders');
        expect(returnUri.queryParameters['order'], 'MS-240782');
        expect(returnUri.queryParameters['view'], 'tracking');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.tracking);
        expect(session.destination, BuyV2Destination.orders);
        expect(session.selectedOrder, same(order));
        expect(session.cartLines, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('RV6 D010 cold recovery retains existing Wholesale origin', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    session.openDestination(BuyV2Destination.wholesale);
    session.updateQuery('rice');
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialView: BuyV2View.recovery,
          recoveryKind: BuyV2RecoveryKind.deliveryDelay,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-recovery-primary')));
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(session.view, BuyV2View.catalogue);
    expect(session.query, 'rice');
    expect(tester.takeException(), isNull);
  });

  for (final mode in ['shop', 'wholesale', 'bulk']) {
    for (final distinct in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'RV6 D011 $mode content preserves unique facts $distinct text $scale',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(360, 800);
            addTearDown(tester.view.reset);
            final session = BuyV2Session(
              core: BuySession(),
              productContentAdapter: distinct
                  ? const _D011SupplierDetailsAdapter()
                  : const BuyV2CatalogueProductContentAdapter(),
            );
            final destination = mode == 'shop'
                ? BuyV2Destination.shop
                : BuyV2Destination.wholesale;
            await tester.pumpWidget(
              app(
                session,
                initialDestination: destination,
                textScale: scale,
                disableAnimations: true,
              ),
            );
            await tester.pumpAndSettle();
            if (mode == 'bulk') {
              session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
            }
            final product = mode == 'bulk'
                ? session.visibleProducts.first
                : session.visibleProducts.firstWhere(
                    (p) => p.title == 'Fresh tomatoes',
                  );
            expect(session.openProduct(product.id), isTrue);
            await tester.pumpAndSettle();
            final hero = find.byKey(
              ValueKey('buy-product-purchase-hero-${product.id}'),
            );
            expect(
              find.descendant(
                of: hero,
                matching: find.textContaining(product.pack),
              ),
              findsWidgets,
            );
            final content = find.byKey(
              ValueKey('buy-product-content-ready-${product.id}'),
            );
            await tester.scrollUntilVisible(
              content,
              240,
              scrollable: scrollableWithin(
                PageStorageKey('buy-product-${product.id}'),
              ).first,
            );
            await Scrollable.ensureVisible(
              tester.element(content),
              alignment: .3,
            );
            await tester.pumpAndSettle();
            Finder inContent(String text) =>
                find.descendant(of: content, matching: find.text(text));
            for (final repeated in [
              product.brandLabel,
              product.pack,
              product.variant,
              product.unitPrice,
              '${product.title} · ${product.variant}. ${product.pack} at ${product.unitPrice}.',
            ]) {
              expect(
                inContent(repeated),
                findsNothing,
                reason: 'Summary-only data must not create repeated sections.',
              );
            }
            if (distinct) {
              expect(
                inContent('Graded and sorted before dispatch'),
                findsOneWidget,
              );
              expect(inContent('Keep crates ventilated'), findsOneWidget);
              expect(inContent('Product highlights'), findsOneWidget);
              expect(inContent('All details'), findsOneWidget);
              expect(inContent('Specifications'), findsOneWidget);
              final descriptionTab = find.byKey(
                ValueKey('buy-product-details-tab-1-${product.id}'),
              );
              await tester.ensureVisible(descriptionTab);
              await tester.pumpAndSettle();
              expect(descriptionTab.hitTestable(), findsOneWidget);
              await tester.tap(descriptionTab);
              await tester.pumpAndSettle();
              expect(
                inContent(
                  'Supplier sorts this lot before packing. Keep away from direct heat.',
                ),
                findsOneWidget,
              );
            } else {
              expect(
                tester.getSize(content).height,
                greaterThan(0),
                reason: 'Supplied product origin and details must survive summary deduplication.',
              );
              expect(product.origin.trim(), isNotEmpty);
              expect(inContent('Product origin'), findsOneWidget);
              expect(inContent(product.origin.trim()), findsOneWidget);
            }
            expect(
              find.text('Product and pack information'),
              product.compliance != null || product.mrp != null
                  ? findsOneWidget
                  : findsNothing,
            );
            expect(session.selectedProductId, product.id);
            expect(tester.takeException(), isNull);
            if (mode == 'wholesale') {
              await captureR66Visual(
                tester,
                'rv6-d011-wholesale-unique-$distinct-text-$scale',
              );
            }
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.catalogue);
            expect(session.destination, destination);
            expect(session.cartLines, isEmpty);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('all six recovery states fit and return without an extra page', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    for (final kind in BuyV2RecoveryKind.values) {
      session.openRecovery(kind);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('buy-recovery-${kind.name}')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: kind.name);
      await captureR66Visual(tester, 't14-order-recovery-${kind.name}');
      await tester.tap(find.byKey(const ValueKey('buy-recovery-primary')));
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
    }
  });

  testWidgets('140 percent text fits every primary Buy state at 320 width', (
    tester,
  ) async {
    final originalErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint(details.toString());
      originalErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalErrorHandler);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    final shop = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    final medicine = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          !item.requiresPrescription,
    );
    for (final entry in <(String, VoidCallback)>[
      ('Shop', () => session.openDestination(BuyV2Destination.shop)),
      ('Wholesale', () => session.openDestination(BuyV2Destination.wholesale)),
      ('Medicine', () => session.openDestination(BuyV2Destination.medicine)),
      ('Product', () => session.openProduct(shop.id)),
      (
        'Cart',
        () {
          session.addProduct(shop.id);
          session.addProduct(medicine.id);
          session.openCart();
        },
      ),
      ('Checkout', session.openCheckout),
      ('Confirmation', session.confirmOrder),
      ('Orders', session.openOrders),
      (
        'Delivered Orders',
        () => session.showOrdersTab(BuyV2OrdersTab.delivered),
      ),
      ('Tracking', () => session.openTracking('MS-240782')),
      ('Assist', session.openAssist),
      (
        'Recovery',
        () => session.openRecovery(BuyV2RecoveryKind.networkInterruption),
      ),
    ]) {
      entry.$2();
      await tester.pumpAndSettle();
      final failure = tester.takeException();
      if (failure is FlutterError) {
        debugPrint(failure.toStringDeep());
      }
      expect(failure, isNull, reason: entry.$1);
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    }
  });

  testWidgets('every primary Buy state contains only customer-facing copy', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final shop = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    final wholesale = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.wholesale,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    for (final action in <VoidCallback>[
      () => session.openDestination(BuyV2Destination.shop),
      () => session.openDestination(BuyV2Destination.wholesale),
      () => session.openProduct(shop.id),
      () {
        session.addProduct(shop.id);
        session.addProduct(wholesale.id);
        session.openCart();
      },
      session.openCheckout,
      session.confirmOrder,
      session.openOrders,
      () => session.showOrdersTab(BuyV2OrdersTab.delivered),
      () => session.openTracking('MS-240782'),
      session.openAssist,
      () => session.openRecovery(BuyV2RecoveryKind.paymentFailed),
    ]) {
      action();
      await tester.pumpAndSettle();
      _expectCustomerFacingBuyCopy(
        tester,
        isolatedReview: session.reviewDataEnabled,
      );
    }
  });

  testWidgets(
    'Buy footer subactions keep adaptive accessible interaction geometry',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      final wholesale = find.byKey(const ValueKey('buy-local-tab-wholesale'));
      final orders = find.byKey(const ValueKey('buy-local-tab-orders'));
      final offers = find.byKey(const ValueKey('buy-local-tab-offers'));
      final rectangles = [
        tester.getRect(wholesale),
        tester.getRect(orders),
        tester.getRect(offers),
      ];

      for (final rectangle in rectangles.skip(1)) {
        expect(rectangle.width, greaterThanOrEqualTo(44));
        expect(rectangle.height, closeTo(rectangles.first.height, .01));
      }
      expect(
        rectangles.every((rect) => rect.height >= 44 && rect.width >= 44),
        isTrue,
      );
      expect(
        rectangles.first.width,
        greaterThanOrEqualTo(rectangles.last.width),
      );
      expect(rectangles[0].right, lessThanOrEqualTo(rectangles[1].left));
      expect(rectangles[1].right, lessThanOrEqualTo(rectangles[2].left));
      expect(
        rectangles[1].left - rectangles[0].right,
        closeTo(rectangles[2].left - rectangles[1].right, .01),
      );

      await tester.tap(wholesale);
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.wholesale);
      expect(tester.widget<InkWell>(wholesale).onTap, isNotNull);
      await tester.tap(wholesale);
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.wholesale);

      await tester.tap(orders);
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.orders);
      expect(tester.widget<InkWell>(orders).onTap, isNotNull);
      await tester.tap(orders);
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.orders);

      await tester.tap(offers);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-offers-publisher-summary')),
        findsOneWidget,
      );
      expect(tester.widget<InkWell>(offers).onTap, isNotNull);
      await tester.tap(offers);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-offers-publisher-summary')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'live Offers recover from offline without static production data',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      final source = _LiveOffersSource(
        const BuyV2PublishedOffersSnapshot(
          state: BuyV2PublishedOffersLoadState.offline,
          customerMessage: 'Offers could not refresh.',
        ),
      );
      await tester.pumpWidget(app(session, offersSource: source));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
      await tester.pumpAndSettle();

      expect(find.text('Offers could not refresh'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-live-offers-retry')),
        findsOneWidget,
      );
      source.snapshot = const BuyV2PublishedOffersSnapshot(
        state: BuyV2PublishedOffersLoadState.ready,
        offers: [
          BuyV2PublishedOffer(
            productId: 's-tomato',
            publisherType: BuyV2OfferPublisherType.retailer,
            headline: 'Fresh price',
          ),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('buy-live-offers-retry')));
      await tester.pumpAndSettle();

      expect(source.calls, 2);
      expect(
        find.byKey(const ValueKey('buy-offers-publisher-summary')),
        findsOneWidget,
      );
      expect(find.text('Fresh tomatoes'), findsWidgets);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('LF04 STORE UI exact off-page product action detail and fit scale=$scale', (tester) async {
      tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(320, 844); addTearDown(tester.view.reset);
      final core = BuySession(), source = _Lf04StoreOffers();
      final session = BuyV2Session(core: core, cataloguePageSource: source);
      addTearDown(core.dispose); addTearDown(session.dispose);
      BuyV2Product? opened;
      await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: r66VisualCaptureRoot(child!)),
        home: Scaffold(body: SingleChildScrollView(child: BuyV2StorePublishedPromotions(session: session,
          storeId: 'host-store', destination: BuyV2Destination.shop, onOpenProduct: (p) => opened = p)))));
      await tester.pumpAndSettle();
      expect(find.text('Promotions from this Store'), findsOneWidget);
      expect(session.findProduct(source.product.id), isNull, reason: 'Feed loading must not admit/off-page cache a product');
      await captureR66Visual(tester, 'lf04-store-section-card-$scale');
      final detail = find.byKey(ValueKey('buy-offer-details-${BuyV2PublishedOffer(productId: source.product.id,
        publisherType: BuyV2OfferPublisherType.retailer, publisherId: 'host-store',
        publicationId: 'host-placement', revision: 1, headline: 'Host Store promotion').identity}'));
      await tester.ensureVisible(detail); await tester.tap(detail); await tester.pumpAndSettle();
      expect(find.text('Host published product details.'), findsOneWidget);
      await captureR66Visual(tester, 'lf04-store-section-$scale');
      await tester.tap(find.byKey(const ValueKey('buy-offer-detail-product'))); await tester.pumpAndSettle();
      expect(opened?.id, source.product.id); expect(session.findProduct(source.product.id), same(source.product));
      expect(session.itemCount, 0); expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('LF04 STORE UI unavailable retry empty and retired dialog remain truthful', (tester) async {
    final core = BuySession(), source = _Lf04StoreOffers()..fail = true;
    final session = BuyV2Session(core: core, cataloguePageSource: source);
    addTearDown(core.dispose); addTearDown(session.dispose);
    var opened = false;
    await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(), home: Scaffold(body: SingleChildScrollView(
      child: BuyV2StorePublishedPromotions(session: session, storeId: 'host-store', destination: BuyV2Destination.shop,
        onOpenProduct: (_) => opened = true)))));
    await tester.pumpAndSettle();
    expect(find.text('Store promotions could not be checked.'), findsOneWidget);
    expect(find.text('No promotions'), findsNothing);
    source.fail = false;
    await tester.tap(find.byKey(const ValueKey('buy-store-promotions-retry'))); await tester.pumpAndSettle();
    expect(source.calls, 2);
    final detail = find.text('Offer details'); await tester.ensureVisible(detail); await tester.tap(detail);
    await tester.pumpAndSettle(); source.active = false;
    await tester.tap(find.byKey(const ValueKey('buy-offer-detail-product'))); await tester.pumpAndSettle();
    expect(opened, isFalse); expect(session.findProduct(source.product.id), isNull); expect(session.itemCount, 0);
    expect(find.text('This offer changed. Close and refresh the offers.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buy-offer-detail-close'))); await tester.pumpAndSettle();
    source.active = true; source.offers = [];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed); await tester.pumpAndSettle();
    expect(find.text('Promotions from this Store'), findsNothing);
    expect(find.text('Store promotions could not be checked.'), findsNothing); expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test('LF04 STORE UI admission replaces old same-ID cache without changing saved Cart', () {
    final core = BuySession(), source = _Lf04StoreOffers();
    final session = BuyV2Session(core: core, cataloguePageSource: source);
    addTearDown(core.dispose); addTearDown(session.dispose);
    final old = source.product.copyWith(priceMinor: source.product.priceMinor - 1);
    session.retainCatalogueStoreBrowse(old);
    expect(session.product(old.id).priceMinor, old.priceMinor);
    expect(session.admitStorePromotion(source, source.offers.single), isTrue);
    expect(session.product(old.id).priceMinor, source.product.priceMinor);
    final other = _Lf04StoreOffers();
    expect(session.admitStorePromotion(other, other.offers.single), isFalse);
    source.active = false;
    expect(session.admitStorePromotion(source, source.offers.single), isFalse);
    expect(session.itemCount, 0);
  });
  testWidgets('LF04 STORE UI actual Visit Store opens exact promoted product and returns', (tester) async {
    tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(390, 844); addTearDown(tester.view.reset);
    final core = BuySession(), source = _Lf04StoreOffers();
    final session = BuyV2Session(core: core, cataloguePageSource: source);
    addTearDown(core.dispose); addTearDown(session.dispose);
    expect(await session.openLinkedProduct(source.product.id), isTrue);
    await tester.pumpWidget(app(session)); await tester.pumpAndSettle();
    expect(session.openProduct(source.product.id), isTrue); await tester.pumpAndSettle();
    expect(find.byKey(PageStorageKey('buy-product-${source.product.id}')), findsOneWidget);
    final action = find.byKey(ValueKey('buy-shop-seller-action-${source.product.id}'));
    await tester.scrollUntilVisible(action, 220, scrollable: scrollableWithin(PageStorageKey('buy-product-${source.product.id}')));
    await tester.tap(action); await tester.pumpAndSettle();
    final section = find.byKey(const ValueKey('buy-store-promotions-host-store'));
    await tester.ensureVisible(section); await tester.pumpAndSettle();
    expect(ModalRoute.of(tester.element(section))!.settings.name, 'buy-public-store');
    final detail = find.text('Offer details'); await tester.ensureVisible(detail); await tester.tap(detail); await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-offer-detail-product'))); await tester.pumpAndSettle();
    expect(session.selectedProductId, source.product.id);
    await tester.binding.handlePopRoute(); await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-store-promotions-host-store')), findsOneWidget);
    expect(session.itemCount, 0); expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test('LF04 STORE UI cache survives later old page retention while selected and reopened', () async {
    final core = BuySession(), source = _Lf04StoreOffers(), newest = source.product;
    final session = BuyV2Session(core: core, cataloguePageSource: source);
    addTearDown(core.dispose); addTearDown(session.dispose);
    source.product = newest.copyWith(priceMinor: newest.priceMinor - 1);
    final pager = session.acquireCatalogueProducts('host-promotion-cache');
    final query = session.catalogueQuery(storeId: 'host-store');
    await pager.open(query);
    expect(session.product(newest.id).priceMinor, newest.priceMinor - 1);
    source.product = newest;
    expect(session.admitStorePromotion(source, source.offers.single), isTrue);
    expect(session.openProduct(newest.id), isTrue);
    session.releaseCatalogueProducts('host-promotion-cache'); // Lease release runs actual cached-page retention.
    expect(session.product(newest.id).priceMinor, newest.priceMinor);
    expect(session.selectedProductId, newest.id);
    session.openDestination(BuyV2Destination.shop); session.openProduct(newest.id);
    expect(session.product(newest.id).priceMinor, newest.priceMinor);
    expect(session.itemCount, 0);
  });
  for (final change in ['newer page', 'rejected input', 'two lease update']) {
    test('LF04 STORE UI retained promotion permits $change safely', () async {
      final core = BuySession(), source = _Lf04StoreOffers(), original = source.product;
      final session = BuyV2Session(core: core, cataloguePageSource: source);
      addTearDown(core.dispose); addTearDown(session.dispose);
      source.product = original.copyWith(priceMinor: original.priceMinor - 1);
      final pager = session.acquireCatalogueProducts('host-retained-promotion');
      await pager.open(session.catalogueQuery(storeId: 'host-store'));
      if (change == 'two lease update') {
        await session.acquireCatalogueProducts('host-later-old-page').open(session.catalogueQuery(storeId: 'host-store'));
      }
      source.product = original;
      expect(session.admitStorePromotion(source, source.offers.single), isTrue);
      if (change != 'rejected input') {
        source.product = original.copyWith(priceMinor: original.priceMinor + 100);
        await pager.refresh();
        expect(session.product(original.id).priceMinor, original.priceMinor + 100);
        if (change == 'two lease update') {
          session.releaseCatalogueProducts('host-later-old-page');
          expect(session.product(original.id).priceMinor, original.priceMinor + 100);
        }
      } else {
        final originalOffer = source.offers.single;
        final invalid = BuyV2PublishedCatalogueOffer(publicationId: originalOffer.publicationId, revision: 2,
          product: original.copyWith(minimumOrder: 0), publisherType: originalOffer.publisherType,
          publisherId: originalOffer.publisherId, publisherName: originalOffer.publisherName,
          headline: originalOffer.headline, sourceId: originalOffer.sourceId,
          observedAt: originalOffer.observedAt, validUntil: originalOffer.validUntil);
        expect(session.admitStorePromotion(source, invalid), isFalse);
        session.releaseCatalogueProducts('host-retained-promotion');
        expect(session.product(original.id).minimumOrder, original.minimumOrder);
        expect(session.product(original.id).priceMinor, original.priceMinor);
      }
      expect(session.itemCount, 0);
    });
  }
  test('LF04 STORE UI ordinary Store preview cannot overwrite a fresh page without any opened promotion', () async {
    final core = BuySession(), source = _Lf04StoreOffers(), original = source.product;
    source.storePreview = original.copyWith(priceMinor: original.priceMinor - 1);
    final session = BuyV2Session(core: core, cataloguePageSource: source);
    addTearDown(core.dispose); addTearDown(session.dispose);
    final query = session.catalogueQuery(storeId: 'host-store');
    await session.acquireCatalogueStores('host-old-preview').open(query);
    expect(session.product(original.id).priceMinor, original.priceMinor - 1);
    source.product = original.copyWith(priceMinor: original.priceMinor + 100);
    await session.acquireCatalogueProducts('host-fresh-page').open(query);
    expect(session.product(original.id).priceMinor, original.priceMinor + 100);
    expect(session.itemCount, 0);
  });
  test('LF04 COPY publication metadata preserves legacy identities and issuer revisions', () {
    const legacy = BuyV2PublishedOffer(productId: 's-tomato', publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Host headline', publicationId: 'host-placement');
    expect(legacy.identity, 'host-placement'); expect(legacy.hasValidPublicationMetadata, isTrue);
    BuyV2PublishedOffer source(String issuer, int revision) => BuyV2PublishedOffer(productId: 's-tomato',
      publisherType: BuyV2OfferPublisherType.retailer, headline: 'Host headline',
      publicationId: 'host-placement', publisherId: issuer, revision: revision, detail: 'Host source details');
    expect(source('host-a', 1).identity, isNot(source('host-b', 1).identity));
    expect(source('host-a', 1).identity, isNot(source('host-a', 2).identity));
    expect(source('host-a', 0).hasValidPublicationMetadata, isFalse);
    final now = DateTime.utc(2026, 10, 18), product = BuyV2Catalogue.products.first.copyWith(storeId: 'host-store');
    BuyV2PublishedCatalogueOffer entry({int? revision, String? detail}) => BuyV2PublishedCatalogueOffer(
      publicationId: 'host-placement', product: product, publisherType: BuyV2OfferPublisherType.retailer,
      publisherId: 'host-store', publisherName: 'Host Store', headline: 'Host headline', sourceId: 'host-source',
      observedAt: now.subtract(const Duration(minutes: 1)), validUntil: now.add(const Duration(minutes: 5)),
      revision: revision, detail: detail);
    expect(entry().isCurrent(now: now), isTrue);
    expect(entry(revision: 1, detail: 'Host details').isCurrent(now: now), isTrue);
    expect(entry(revision: 0).isCurrent(now: now), isFalse);
    expect(entry(revision: 1000000001).isCurrent(now: now), isFalse);
    expect(entry(detail: List.filled(2001, 'x').join()).isCurrent(now: now), isFalse);
  });
  for (final size in [const Size(320, 844), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('LF04 COPY full offer details product and Back $size scale=$scale', (tester) async {
        tester.view.devicePixelRatio = 1; tester.view.physicalSize = size; addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose); addTearDown(session.dispose);
        final detail = List.filled(12, 'Host published detail, supplied by this issuer.').join('\n');
        final placement = BuyV2PublishedOffer(productId: 's-tomato', publisherType: BuyV2OfferPublisherType.retailer,
          publisherId: 'host-store', publisherName: 'Host Store', publicationId: 'host-placement', revision: 3,
          headline: 'Host scoped promotion', detail: detail);
        await tester.pumpWidget(app(session, offersSource: _FixedOffersSource([placement]), textScale: scale));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers'))); await tester.pumpAndSettle();
        final group = find.byKey(const ValueKey('buy-offer-group-suppliers'));
        await tester.ensureVisible(group); await tester.tap(group); await tester.pumpAndSettle();
        final button = find.byKey(ValueKey('buy-offer-details-${placement.identity}'));
        await tester.ensureVisible(button); await tester.pumpAndSettle();
        final selected = session.selectedProductId, price = session.product('s-tomato').priceMinor,
          total = session.cartTotalMinor;
        await tester.tap(button); await tester.pumpAndSettle();
        expect(find.text(detail), findsOneWidget); expect(find.text('From Host Store'), findsWidgets);
        expect(session.selectedProductId, selected); expect(session.cartTotalMinor, total);
        expect(session.product('s-tomato').priceMinor, price);
        expect(find.text('Viewing this promotion does not apply a discount.'), findsOneWidget);
        for (final label in ['Close', 'View product']) {
          final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
          expect(paragraph.text.style?.fontFamily, 'Inter');
          expect(paragraph.didExceedMaxLines, isFalse);
        }
        await captureR66Visual(tester, 'lf04-offer-copy-${size.width.toInt()}-$scale');
        await tester.tap(find.byKey(const ValueKey('buy-offer-detail-product'))); await tester.pumpAndSettle();
        expect(session.selectedProductId, 's-tomato'); expect(session.itemCount, 0);
        await tester.binding.handlePopRoute(); await tester.pumpAndSettle();
        expect(session.featuredOfferPublicationId, placement.identity);
        expect(find.text('Host scoped promotion'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('LF04 COPY blank details omitted and two same-SKU placements retained without duplicate grid', (tester) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(core.dispose); addTearDown(session.dispose);
    const first = BuyV2PublishedOffer(productId: 's-tomato', publisherType: BuyV2OfferPublisherType.retailer,
      publisherId: 'host-store', publisherName: 'Host Store', publicationId: 'host-a', revision: 1,
      headline: 'Host first placement', detail: '  ');
    const second = BuyV2PublishedOffer(productId: 's-tomato', publisherType: BuyV2OfferPublisherType.retailer,
      publisherId: 'host-store', publisherName: 'Host Store', publicationId: 'host-b', revision: 1,
      headline: 'Host second placement', detail: 'Host second detail');
    await tester.pumpWidget(app(session, offersSource: const _FixedOffersSource([first, second])));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers'))); await tester.pumpAndSettle();
    final group = find.byKey(const ValueKey('buy-offer-group-suppliers'));
    await tester.ensureVisible(group); await tester.tap(group); await tester.pumpAndSettle();
    final pages = find.descendant(of: find.byKey(const ValueKey('buy-published-offer-facts')), matching: find.byType(PageView));
    expect(tester.widget<PageView>(pages).childrenDelegate.estimatedChildCount, 2);
    expect(find.byKey(ValueKey('buy-offer-details-${first.identity}')), findsNothing);
    expect(find.byKey(const ValueKey('buy-product-s-tomato')), findsOneWidget);
    await tester.drag(pages, const Offset(-300, 0)); await tester.pumpAndSettle();
    final details = find.byKey(ValueKey('buy-offer-details-${second.identity}'));
    await tester.ensureVisible(details); await tester.tap(details); await tester.pumpAndSettle();
    expect(find.text('Host second detail'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buy-offer-detail-close'))); await tester.pumpAndSettle();
    expect(session.itemCount, 0); expect(tester.takeException(), isNull);
  });
  for (final change in ['revision', 'account', 'invalid', 'issuer', 'oversized', 'seller']) {
    testWidgets('LF04 COPY stale details cannot open after $change change', (tester) async {
      final core = BuySession();
      final session = change == 'seller' ? _Lf04SellerCopySession(core) : BuyV2Session(core: core);
      addTearDown(core.dispose); addTearDown(session.dispose);
      final original = BuyV2PublishedOffer(productId: 's-tomato', publisherType: BuyV2OfferPublisherType.retailer,
        publisherId: 'host-store', publisherName: change == 'seller' ? null : 'Host Store', publicationId: 'host-placement', revision: 1,
        headline: 'Host promotion', detail: 'Host original detail');
      await tester.pumpWidget(app(session, offersSource: _FixedOffersSource([original])));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers'))); await tester.pumpAndSettle();
      final group = find.byKey(const ValueKey('buy-offer-group-suppliers'));
      await tester.ensureVisible(group); await tester.tap(group); await tester.pumpAndSettle();
      final detail = find.byKey(ValueKey('buy-offer-details-${original.identity}'));
      await tester.ensureVisible(detail); await tester.tap(detail); await tester.pumpAndSettle();
      final next = change == 'account' ? BuyV2Session(core: BuySession()) : session;
      if (next != session) { addTearDown(next.core.dispose); addTearDown(next.dispose); }
      if (change == 'seller') (session as _Lf04SellerCopySession).renameSeller();
      final revised = change == 'seller' ? original : BuyV2PublishedOffer(productId: 's-tomato', publisherType: BuyV2OfferPublisherType.retailer,
        publisherId: 'host-store', publisherName: change == 'issuer' ? 'Host renamed Store' : 'Host Store',
        publicationId: 'host-placement', revision: change == 'invalid' ? 0 :
          {'issuer', 'oversized'}.contains(change) ? 1 : 2, headline: 'Host promotion',
        detail: change == 'issuer' ? 'Host original detail' :
          change == 'oversized' ? List.filled(2001, 'x').join() : 'Host revised detail');
      await tester.pumpWidget(app(next, offersSource: _FixedOffersSource([revised]))); await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-offer-detail-product'))); await tester.pumpAndSettle();
      expect(next.selectedProductId, isNull); expect(next.itemCount, 0); expect(session.itemCount, 0);
      expect(find.text('This offer changed. Close and refresh the offers.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('buy-offer-detail-close'))); await tester.pumpAndSettle();
      if (change == 'invalid' || change == 'oversized') {
        expect(find.text('Offer information could not be verified.'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Offers accepts an ordered published catalogue seam', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    const source = _FixedOffersSource([
      BuyV2PublishedOffer(
        productId: 'w-rice',
        publisherType: BuyV2OfferPublisherType.wholesaler,
        headline: 'Published trade price',
      ),
      BuyV2PublishedOffer(
        productId: 'missing-product',
        publisherType: BuyV2OfferPublisherType.retailer,
        headline: 'Unavailable placement',
      ),
    ]);
    await tester.pumpWidget(app(session, offersSource: source));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-product-w-rice')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-product-missing-product')),
      findsNothing,
    );
    final grid = tester.widget<Semantics>(
      find.byKey(
        const ValueKey('buy-vertical-product-summary-buy-offers-products'),
      ),
    );
    expect(grid.properties.label, contains('Showing 1 of 1'));
    expect(grid.properties.label, contains('Showing 1 of 1 product.'));
    expect(grid.properties.label, isNot(contains('loaded')));
  });

  testWidgets('Offers completes product Cart and Checkout navigation', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-product-w-oil')));
    await tester.pumpAndSettle();
    expect(session.selectedProduct?.id, 'w-oil');
    expect(session.view, BuyV2View.product);
    expect(find.text('Offers'), findsWidgets);
    expect(find.text('Wholesale'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-product-primary-w-oil')));
    await tester.pumpAndSettle();
    expect(session.quantityFor('w-oil'), 2);

    await tester.tap(find.byKey(const ValueKey('buy-compact-cart-indicator')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(find.byKey(const ValueKey('buy-cart-browse-more')), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Checkout'));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.checkout);
    expect(
      find.byKey(const ValueKey('buy-checkout-action-bar')),
      findsOneWidget,
    );
  });

  for (final reducedMotion in [false, true]) {
    for (final size in [const Size(320, 844), const Size(640, 360)]) {
      testWidgets(
        'R669 Offers promotion category CTA Back $size reduced $reducedMotion',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          const source = _FixedOffersSource([
            BuyV2PublishedOffer(
              publicationId: 'test-admin-rice',
              productId: 'w-rice',
              publisherType: BuyV2OfferPublisherType.moolSocial,
              publisherName: 'MoolSocial',
              headline: 'Rice buying offer',
            ),
            BuyV2PublishedOffer(
              publicationId: 'test-supplier-tomato',
              productId: 's-tomato',
              publisherType: BuyV2OfferPublisherType.retailer,
              publisherName: 'Test produce supplier',
              headline: 'Fresh produce offer',
            ),
          ]);
          await tester.pumpWidget(
            app(
              session,
              offersSource: source,
              textScale: 2,
              disableAnimations: reducedMotion,
              safePadding: const EdgeInsets.only(top: 24, bottom: 34),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
          await tester.pumpAndSettle();
          Future<void> selectSource(bool mool) async {
            final target = find.byKey(
              ValueKey('buy-offer-group-${mool ? 'moolsocial' : 'suppliers'}'),
            );
            await tester.scrollUntilVisible(
              target,
              -150,
              scrollable: find
                  .descendant(
                    of: find.byKey(const PageStorageKey('buy-offers')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.ensureVisible(target);
            await tester.pumpAndSettle();
            await tester.tap(target);
            await tester.pumpAndSettle();
          }

          await selectSource(true);
          expect(find.text('Rice buying offer'), findsOneWidget);
          expect(find.text('From MoolSocial'), findsOneWidget);
          expect(find.text('Makers'), findsNothing);
          expect(find.text('Categories'), findsNothing);
          expect(
            find.byKey(const ValueKey('buy-offer-promotion-next')),
            findsNothing,
          );
          await selectSource(false);
          expect(find.text('Fresh produce offer'), findsOneWidget);
          expect(find.text('From Test produce supplier'), findsOneWidget);
          final cta = find.byKey(
            const ValueKey('buy-offer-promotion-cta-s-tomato'),
          );
          await tester.ensureVisible(cta);
          await tester.pumpAndSettle();
          expect(cta.hitTestable(), findsOneWidget);
          expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));
          await captureR66Visual(
            tester,
            'r669-offers-promotion-${size.width.toInt()}-$reducedMotion-cta',
          );
          await tester.tap(cta);
          await tester.pumpAndSettle();
          expect(session.selectedProductId, 's-tomato');
          expect(
            session.selectedProduct?.price,
            session.product('s-tomato').price,
          );
          expect(session.itemCount, 0);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.featuredOfferPublicationId, 'test-supplier-tomato');
          expect(find.text('Fresh produce offer'), findsOneWidget);
          await selectSource(true);
          expect(find.text('Rice buying offer'), findsOneWidget);
          await selectSource(false);
          final categoryControl = find.byKey(
            const ValueKey('buy-offers-category-control'),
          );
          await tester.scrollUntilVisible(
            categoryControl,
            -120,
            scrollable: find
                .descendant(
                  of: find.byKey(const PageStorageKey('buy-offers')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(categoryControl);
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: categoryControl,
              matching: find.byIcon(Icons.menu_rounded),
            ),
            findsOneWidget,
          );
          await captureR66Visual(
            tester,
            'r669-three-line-offers-${size.width.toInt()}-$reducedMotion',
          );
          final shopCategory = session.selectedCategoryId;
          await tester.tap(categoryControl);
          await tester.pumpAndSettle();
          final categoryId = session.product('s-tomato').categoryId;
          expect(categoryId, isNot(session.product('w-rice').categoryId));
          final category = find.byKey(
            ValueKey('buy-offers-category-$categoryId'),
          );
          await tester.scrollUntilVisible(
            category,
            100,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('buy-offers-category-list')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(category);
          await tester.pumpAndSettle();
          expect(category.hitTestable(), findsOneWidget);
          await tester.tap(category);
          await tester.pumpAndSettle();
          expect(session.finiteOffersCategoryId, categoryId);
          expect(session.selectedCategoryId, shopCategory);
          expect(find.text('Fresh produce offer'), findsOneWidget);
          expect(find.text('Rice buying offer'), findsNothing);
          expect(
            find.byKey(const ValueKey('buy-offer-promotion-next')),
            findsNothing,
          );
          await tester.ensureVisible(categoryControl);
          await tester.pumpAndSettle();
          await tester.tap(categoryControl);
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('buy-offers-category-all')),
          );
          await tester.pumpAndSettle();
          expect(session.finiteOffersCategoryId, 'all');
          expect(find.text('Fresh produce offer'), findsOneWidget);
          expect(session.itemCount, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('Shop Orders excludes Care-owned Medicine and stale promises', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-local-tab-orders')));
    await tester.pumpAndSettle();

    expect(session.activeOrderCount, 2);
    expect(session.deliveredOrderCount, 2);
    expect(find.text('Medicine order'), findsNothing);
    expect(find.textContaining('29 Jul'), findsNothing);
    expect(find.textContaining('30 Jul'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cart can return to Offers and add another product', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    final oilAdd = find.byKey(const ValueKey('buy-add-w-oil'));
    await tester.ensureVisible(oilAdd);
    await tester.pumpAndSettle();
    expect(oilAdd.hitTestable(), findsOneWidget);
    await tester.tap(oilAdd);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-compact-cart-indicator')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-cart-browse-more')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.catalogue);
    final offerSummary = find.byKey(
      const ValueKey('buy-offers-publisher-summary'),
    );
    await tester.scrollUntilVisible(
      offerSummary,
      -180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-offers')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
    expect(session.quantityFor('w-oil'), 2);

    final tomatoAdd = find.byKey(const ValueKey('buy-add-s-tomato'));
    await tester.scrollUntilVisible(
      tomatoAdd,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-offers')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(tomatoAdd);
    await tester.pumpAndSettle();
    await tester.tap(tomatoAdd);
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-tomato'), 1);
    expect(session.itemCount, 3);
  });

  testWidgets(
    'Shop Wholesale Orders and Offers expose vertical product discovery',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-featured-products')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey('buy-featured-product-${session.visibleProducts.first.id}'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-featured-products')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey('buy-featured-product-${session.visibleProducts.first.id}'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('buy-local-tab-orders')));
      await tester.pumpAndSettle();
      Future<void> verifyVerticalProducts(
        String storageKey,
        Finder scroll,
        List<BuyV2Product> products,
      ) async {
        final summary = find.byKey(
          ValueKey('buy-vertical-product-summary-$storageKey'),
        );
        final grid = find.byKey(
          ValueKey('buy-vertical-product-grid-$storageKey'),
        );
        final last = find.descendant(
          of: grid,
          matching: find.byKey(ValueKey('buy-product-${products.last.id}')),
        );
        for (
          var attempt = 0;
          attempt < 200 && last.hitTestable().evaluate().isEmpty;
          attempt++
        ) {
          await tester.drag(scroll, const Offset(0, -180));
          await tester.pumpAndSettle();
        }
        expect(last.hitTestable(), findsOneWidget);
        final label = tester.widget<Semantics>(summary).properties.label!;
        expect(
          label,
          contains('Showing ${products.length} of ${products.length}'),
        );
        expect(label, contains('Scroll up or down'));
        final position = tester.state<ScrollableState>(scroll).position;
        expect(position.axis, Axis.vertical);
        expect(position.pixels, greaterThan(0));
        for (final product in products) {
          expect(
            find.descendant(
              of: grid,
              matching: find.byKey(ValueKey('buy-product-${product.id}')),
            ),
            findsOneWidget,
          );
        }
      }

      final orderProducts = session.visibleProducts.toList();
      expect(orderProducts, hasLength(18));
      await verifyVerticalProducts(
        'buy-orders-products',
        scrollableWithin(const PageStorageKey('buy-orders')),
        orderProducts,
      );

      await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
      await tester.pumpAndSettle();
      final offerProducts = const BuyV2CataloguePublishedOffersSource()
          .publishedOffers
          .map((offer) => session.product(offer.productId))
          .toList();
      expect(offerProducts, hasLength(24));
      await verifyVerticalProducts(
        'buy-offers-products',
        scrollableWithin(const PageStorageKey('buy-offers')),
        offerProducts,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Offers search stays inside the published mixed catalogue', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    expect(find.text('Search current offers'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      'rice',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-product-w-rice')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-product-w-oil')), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
  });

  testWidgets(
    'store Add feedback Cart access and product return keep one browse path',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      var storeChatOpens = 0;
      await tester.pumpWidget(
        app(session, onOpenChat: () => storeChatOpens += 1),
      );
      await tester.pumpAndSettle();
      expect(session.openProduct('s-eggs'), isTrue);
      await tester.pumpAndSettle();
      final storeAction = find.byKey(
        const ValueKey('buy-shop-seller-action-s-eggs'),
      );
      await tester.scrollUntilVisible(
        storeAction,
        220,
        scrollable: scrollableWithin(
          const PageStorageKey('buy-product-s-eggs'),
        ),
      );
      await tester.pumpAndSettle();
      expect(storeAction.hitTestable(), findsOneWidget);
      await tester.tap(storeAction);
      await tester.pumpAndSettle();

      final storeSheet = find.byKey(
        const ValueKey('buy-shop-seller-sheet-s-eggs'),
      );
      expect(storeSheet, findsOneWidget);
      expect(
        find.descendant(
          of: storeSheet,
          matching: find.text('Safe Protein Store'),
        ),
        findsOneWidget,
      );
      expect(find.text('MoolSocial Fulfilment Store'), findsNothing);
      expect(find.textContaining('Address confirmed'), findsNothing);
      expect(find.textContaining('Store location unavailable'), findsOneWidget);
      final storeTruth = find.byKey(
        const ValueKey('buy-public-store-truth-s-eggs'),
      );
      expect(
        tester.widget<Semantics>(storeTruth).properties.label,
        contains('MoolSocial Fulfilment Store. Safe Protein Store.'),
      );
      expect(
        find.descendant(of: storeTruth, matching: find.text('Open')),
        findsNothing,
      );
      await tester.tap(
        find.descendant(
          of: storeTruth,
          matching: find.byKey(
            const ValueKey('buy-public-store-fulfilment-toggle'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Quick'), findsWidgets);
      final askStore = find.byKey(const ValueKey('buy-public-store-ask'));
      expect(askStore, findsOneWidget);
      expect(tester.getSize(askStore), const Size(62, 44));
      expect(
        tester
            .getSize(find.byKey(const ValueKey('buy-public-store-ask-visible')))
            .height,
        30,
      );
      await tester.tap(askStore);
      await tester.pumpAndSettle();
      expect(storeChatOpens, 1);
      expect(storeSheet, findsNothing);
      await tester.tap(storeAction);
      await tester.pumpAndSettle();
      expect(storeSheet, findsOneWidget);
      final storeScroll = find
          .descendant(of: storeSheet, matching: find.byType(Scrollable))
          .first;
      final emptyCartSku = find.byKey(const ValueKey('buy-product-s-chicken'));
      await tester.scrollUntilVisible(
        emptyCartSku,
        160,
        scrollable: storeScroll,
      );
      await tester.tap(emptyCartSku);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-store-cart-bar')), findsNothing);
      expect(find.text('Cart is empty'), findsNothing);
      await tester.tap(find.text('Back to Safe Protein Store'));
      await tester.pumpAndSettle();
      expect(storeSheet, findsOneWidget);
      final addChicken = find.byKey(const ValueKey('buy-add-s-chicken'));
      await tester.scrollUntilVisible(addChicken, 180, scrollable: storeScroll);
      await tester.tap(addChicken);
      await tester.pumpAndSettle();

      expect(session.quantityFor('s-chicken'), 1);
      expect(find.byKey(const ValueKey('buy-store-cart-bar')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-store-cart-entrance-motion')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-product-action-motion-s-chicken')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<BuyV2FiniteValueTransition>(
              find.byKey(const ValueKey('buy-store-cart-feedback')),
            )
            .text,
        '1 item',
      );

      final chicken = find.byKey(const ValueKey('buy-product-s-chicken'));
      final chickenTitle = find.descendant(
        of: chicken,
        matching: find.text(
          BuyV2Catalogue.products
              .firstWhere((p) => p.id == 's-chicken')
              .customerTitle,
        ),
      );
      await Scrollable.ensureVisible(
        tester.element(chickenTitle),
        alignment: .4,
      );
      await tester.pumpAndSettle();
      expect(chickenTitle.hitTestable(), findsOneWidget);
      await tester.tap(chickenTitle);
      await tester.pumpAndSettle();
      expect(session.selectedProductId, 's-chicken');
      expect(
        find.byKey(const ValueKey('buy-store-product-route-motion')),
        findsOneWidget,
      );
      expect(find.text('Back to Safe Protein Store'), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-store-cart-bar')), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-cart-navigation-button')).hitTestable(),
        findsOneWidget,
      );

      await tester.tap(find.text('Back to Safe Protein Store'));
      await tester.pumpAndSettle();
      expect(storeSheet, findsOneWidget);
      expect(session.selectedProductId, 's-eggs');

      await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.cart);
      expect(
        find.byKey(const ValueKey('buy-cart-continue-store')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-cart-continue-store')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-cart-continue-store-name')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('buy-cart-continue-store-name')),
            )
            .data,
        'Safe Protein Store',
      );

      await tester.tap(find.byKey(const ValueKey('buy-cart-continue-store')));
      await tester.pumpAndSettle();
      expect(storeSheet, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'store Chat keeps supplier context, Admin visibility and Buy return',
    () {
      final storeProduct = BuyV2Catalogue.products.firstWhere(
        (product) => product.id == 's-eggs',
      );
      final location = const BuyV2ChatRouteAdapter().storeQuestionLocationFor(
        anchor: storeProduct,
      );
      final uri = Uri.parse(location);

      expect(uri.path, contains('/app/chat/thread/'));
      expect(uri.queryParameters['context'], 'supplier-store');
      expect(uri.queryParameters['supplier'], 'Safe Protein Store');
      expect(uri.queryParameters['storeAnchorSku'], 's-eggs');
      expect(uri.queryParameters['adminVisible'], 'true');
      expect(uri.queryParameters['escalationReason'], 'supplier-non-response');
      expect(uri.queryParameters['callAuthority'], 'moolsocial-admin-only');
      final returnUri = Uri.parse(uri.queryParameters['return']!);
      expect(returnUri.path, '/app/buy');
      expect(returnUri.queryParameters['sub'], 'shop');
      expect(returnUri.queryParameters['view'], 'product');
      expect(returnUri.queryParameters['product'], 's-eggs');
    },
  );

  testWidgets('Chat return restores the exact store instead of product depth', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    expect(session.rememberStoreReturnAnchor('s-tomato'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.shop,
          initialView: BuyV2View.product,
          productId: 's-tomato',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.catalogue);
    expect(session.selectedProductId, isNull);
    expect(
      find.byKey(const ValueKey('buy-shop-seller-sheet-s-tomato')),
      findsOneWidget,
    );
    expect(find.textContaining('Shree Balaji Fresh'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    for (final id in ['s-dog-food', 's-shampoo', 'w-notebook']) {
      testWidgets('RV6 D015 recent availability and recovery $id text $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.reset);
        final session = BuyV2Session(core: BuySession());
        addTearDown(session.dispose);
        final destination = id.startsWith('w-')
            ? BuyV2Destination.wholesale
            : BuyV2Destination.shop;
        session.openDestination(destination);
        expect(session.openProduct(id), isTrue);
        session.goBack();
        final history = session
            .recentlyViewedProductsFor(destination)
            .map((p) => p.id)
            .toList();
        final address = session.selectedAddress.id;
        if (id == 'w-notebook') session.businessVerified = false;
        await tester.pumpWidget(
          app(
            session,
            initialDestination: destination,
            textScale: scale,
            safePadding: const EdgeInsets.only(bottom: 48),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
        await tester.pumpAndSettle();
        final filterScroll = find
            .descendant(
              of: find.byKey(const ValueKey('buy-discovery-refinement-list')),
              matching: find.byType(Scrollable),
            )
            .first;
        final tools = find.byKey(const ValueKey('buy-refine-section-tools'));
        await tester.scrollUntilVisible(tools, 160, scrollable: filterScroll);
        await tester.pumpAndSettle();
        final toolsTitle = find.descendant(
          of: tools,
          matching: find.text('Shopping tools'),
        );
        await Scrollable.ensureVisible(
          tester.element(toolsTitle),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        expect(toolsTitle.hitTestable(), findsOneWidget);
        await tester.tap(toolsTitle);
        await tester.pumpAndSettle();
        final recent = find.byKey(const ValueKey('buy-recently-viewed-button'));
        await tester.scrollUntilVisible(recent, 100, scrollable: filterScroll);
        await tester.pumpAndSettle();
        await Scrollable.ensureVisible(tester.element(recent), alignment: .5);
        await tester.pumpAndSettle();
        expect(recent.hitTestable(), findsOneWidget);
        await tester.tap(recent);
        await tester.pumpAndSettle();
        final sheet = find.byKey(
          const ValueKey('buy-recently-viewed-info-sheet'),
        );
        expect(sheet, findsOneWidget);
        final scroll = find
            .descendant(of: sheet, matching: find.byType(Scrollable))
            .last;
        final action = find.byKey(
          ValueKey(
            id == 'w-notebook'
                ? 'buy-recently-viewed-add-$id'
                : 'buy-recently-viewed-review-$id',
          ),
        );
        if (scale == 2.0) {
          await captureR66Visual(tester, 'rv6-d015-$id-row-start-text-$scale');
        }
        await tester.scrollUntilVisible(action, 100, scrollable: scroll);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        expect(tester.getRect(action).bottom, lessThanOrEqualTo(520));
        if (id != 'w-notebook') {
          expect(
            find.byKey(ValueKey('buy-recently-viewed-add-$id')),
            findsNothing,
          );
          final availability = tester.widget<Text>(
            find.byKey(ValueKey('buy-recently-viewed-availability-$id')),
          );
          expect(
            availability.data,
            contains(id == 's-dog-food' ? 'closed' : 'cannot be added to Cart'),
          );
        }
        await captureR66Visual(tester, 'rv6-d015-$id-row-text-$scale');
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(session.quantityFor(id), 0);
        if (id == 'w-notebook') {
          final dialog = find.byKey(
            ValueKey('buy-recently-viewed-rejection-$id'),
          );
          expect(dialog, findsOneWidget);
          expect(
            find.descendant(
              of: dialog,
              matching: find.text(
                'Complete your business profile to place a wholesale order.',
              ),
            ),
            findsOneWidget,
          );
          await captureR66Visual(tester, 'rv6-d015-$id-rejection-text-$scale');
          final explanation = find.descendant(
            of: dialog,
            matching: find.text(
              'Complete your business profile to place a wholesale order.',
            ),
          );
          await Scrollable.ensureVisible(
            tester.element(explanation),
            alignment: 1,
          );
          await tester.pumpAndSettle();
          final close = find.descendant(
            of: dialog,
            matching: find.text('Close'),
          );
          expect(
            tester.getRect(explanation).bottom,
            lessThanOrEqualTo(tester.getRect(close).top),
          );
          if (scale == 2.0) {
            await captureR66Visual(
              tester,
              'rv6-d015-$id-rejection-end-text-$scale',
            );
          }
          await tester.tap(
            find.descendant(of: dialog, matching: find.text('Close')),
          );
          await tester.pumpAndSettle();
          expect(sheet, findsOneWidget);
          await tester.tap(action);
          await tester.pumpAndSettle();
          await tester.tap(
            find.descendant(of: dialog, matching: find.text('View product')),
          );
          await tester.pumpAndSettle();
        }
        expect(session.selectedProductId, id);
        expect(session.view, BuyV2View.product);
        expect(sheet.hitTestable(), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(sheet, findsOneWidget);
        expect(
          session.recentlyViewedProductsFor(destination).map((p) => p.id),
          history,
        );
        expect(session.quantityFor(id), 0);
        expect(session.selectedAddress.id, address);
        expect(tester.takeException(), isNull);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        expect(session.destination, destination);
      });
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'RV6 D016 real app offer alert opens Offers and returns text $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final journey = JourneySession(
          store: MemoryJourneyStore(
            snapshot: const JourneySnapshot(
              languageCode: 'en',
              areaMode: 'manual',
              areaLabel: 'Sardarpura',
              setupComplete: true,
            ),
          ),
          otpGateway: ReviewOtpGateway(signedIn: true),
        );
        addTearDown(journey.dispose);
        await journey.start();
        await tester.pumpWidget(
          r66VisualCaptureRoot(
            MoolSocialApp(
              session: journey,
              initialLocation: '/app/buy?sub=shop',
            ),
          ),
        );
        await tester.pumpAndSettle();
        final session = tester
            .widget<BuyV2Screen>(find.byType(BuyV2Screen))
            .session;
        expect(session.addProduct('s-milk'), isTrue);
        final saved = session
            .savedProductsFor(BuyV2Destination.shop)
            .map((p) => p.id)
            .toList();
        final address = session.selectedAddress.id;
        unawaited(
          showBuyV2ShoppingAlerts(
            tester.element(find.byType(BuyV2Screen)),
            session,
          ),
        );
        await tester.pumpAndSettle();
        final alerts = find.byKey(const ValueKey('buy-shopping-alerts'));
        final alert = find.byKey(
          const ValueKey('buy-shopping-alert-offers-shop'),
        );
        final scroll = find
            .descendant(of: alerts, matching: find.byType(Scrollable))
            .first;
        await tester.scrollUntilVisible(alert, 160, scrollable: scroll);
        await tester.pumpAndSettle();
        for (var visit = 0; visit < 2; visit++) {
          await Scrollable.ensureVisible(tester.element(alert), alignment: .5);
          await tester.pumpAndSettle();
          expect(alert.hitTestable(), findsOneWidget);
          await tester.tap(alert);
          await tester.pumpAndSettle();
          expect(find.byType(BuyV2OffersView), findsOneWidget);
          expect(
            find.byKey(const ValueKey('buy-offers-publisher-summary')),
            findsOneWidget,
          );
          expect(session.quantityFor('s-milk'), 1);
          if (visit == 0) {
            await captureR66Visual(tester, 'rv6-d016-offers-text-$scale');
          }
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(alerts, findsOneWidget);
          expect(alert.hitTestable(), findsOneWidget);
          expect(session.quantityFor('s-milk'), 1);
          expect(session.selectedAddress.id, address);
          expect(
            session.savedProductsFor(BuyV2Destination.shop).map((p) => p.id),
            saved,
          );
        }
        await captureR66Visual(tester, 'rv6-d016-alert-return-text-$scale');
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final offers in [true, false]) {
    testWidgets(
      'RV6 D016 initial Offers flag renders before session notification $offers',
      (tester) async {
        final session = BuyV2Session(core: BuySession());
        addTearDown(session.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: BuyV2Screen(session: session, initialOffersActive: offers),
          ),
        );
        expect(
          find.byType(BuyV2OffersView),
          offers ? findsOneWidget : findsNothing,
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(BuyV2OffersView),
          offers ? findsOneWidget : findsNothing,
        );
        expect(session.cartLines, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'RV6 D017 GST profile contrast and selection ${destination.name} text $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 844);
          addTearDown(tester.view.reset);
          final session = BuyV2Session(core: BuySession());
          addTearDown(session.dispose);
          await tester.pumpWidget(
            app(
              session,
              initialDestination: destination,
              textScale: scale,
              safePadding: const EdgeInsets.only(bottom: 48),
            ),
          );
          await tester.pumpAndSettle();
          final product = destination == BuyV2Destination.shop
              ? 's-atta'
              : 'w-notebook';
          expect(session.addProduct(product), isTrue);
          session.openCart();
          expect(session.openCheckout(), isTrue);
          await tester.pumpAndSettle();
          await prepareCheckoutReviewState(tester, session);
          final controller = tester
              .widget<BuyV2CheckoutView>(find.byType(BuyV2CheckoutView))
              .gstInvoiceController;
          final other = destination == BuyV2Destination.shop
              ? BuyV2Destination.wholesale
              : BuyV2Destination.shop;
          expect(
            await controller.save(
              destination: other,
              legalName: 'Market Retail',
              gstin: '08ABCDE1234F1Z5',
              billingAddress: 'Test billing address',
              remember: true,
            ),
            isTrue,
          );
          // Defaults now reuse the first account profile in both baskets.
          // Choose a distinct order recipient before remembering a second one.
          expect(
            await controller.save(
              destination: destination,
              legalName: 'AuditRedmiTest',
              gstin: '08ABCDE1234F1Z5',
              billingAddress: 'Test billing address',
              remember: false,
            ),
            isTrue,
          );
          expect(
            await controller.save(
              destination: destination,
              legalName: 'AuditRedmiTest',
              gstin: '08ABCDE1234F1Z5',
              billingAddress: 'Test billing address',
              remember: true,
            ),
            isTrue,
          );
          await tester.pumpAndSettle();
          final selectedProfile = controller.detailsFor(destination)!;
          final otherProfile = controller.savedProfiles.firstWhere(
            (p) => p.id != selectedProfile.id,
          );
          final selected = find.byKey(
            ValueKey('buy-invoice-profile-${selectedProfile.id}'),
          );
          final semantics = tester.ensureSemantics();
          try {
            final originalTotal = session.cartTotal;
            final originalQuantity = session.quantityFor(product);
            Future<void> openRecipients() async {
              final change = find.byKey(const ValueKey('buy-invoice-change'));
              await tester.ensureVisible(change);
              await tester.pumpAndSettle();
              await tester.tap(change);
              await tester.pumpAndSettle();
              expect(find.text('Invoice recipient'), findsOneWidget);
            }

            await openRecipients();
            await captureR66Visual(
              tester,
              'rv6-d017-${destination.name}-selected-text-$scale',
            );
            double contrast(Color a, Color b) {
              final x = a.computeLuminance(), y = b.computeLuminance();
              return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
            }

            void expectReadable(Finder tile, String label, bool isSelected) {
              expect(tester.widget<ListTile>(tile).selected, isSelected);
              expect(
                tester
                    .getSemantics(tile)
                    .getSemanticsData()
                    .flagsCollection
                    .isSelected,
                isSelected ? Tristate.isTrue : Tristate.isFalse,
              );
              final theme = Theme.of(tester.element(tile));
              final background =
                  theme.bottomSheetTheme.backgroundColor ??
                  theme.colorScheme.surface;
              final rich = tester.widget<RichText>(
                find.descendant(
                  of: find.descendant(of: tile, matching: find.text(label)),
                  matching: find.byType(RichText),
                ),
              );
              expect(rich.text.toPlainText(), label);
              expect(
                contrast(rich.text.style!.color!, background),
                greaterThanOrEqualTo(4.5),
              );
              if (isSelected) {
                final icon = tester.widget<Icon>(
                  find.descendant(of: tile, matching: find.byIcon(Icons.check)),
                );
                expect(
                  contrast(icon.color!, background),
                  greaterThanOrEqualTo(3),
                );
              }
            }

            expectReadable(selected, selectedProfile.legalName, true);
            final unselected = find.byKey(
              ValueKey('buy-invoice-profile-${otherProfile.id}'),
            );
            expectReadable(unselected, otherProfile.legalName, false);
            await Scrollable.ensureVisible(
              tester.element(unselected),
              alignment: .5,
            );
            await tester.pumpAndSettle();
            await tester.tap(
              find.descendant(
                of: unselected,
                matching: find.text(otherProfile.legalName),
              ),
            );
            await tester.pumpAndSettle();
            expect(controller.detailsFor(destination)?.id, otherProfile.id);
            expect(find.text('Invoice recipient'), findsNothing);
            await openRecipients();
            expectReadable(unselected, otherProfile.legalName, true);
            expectReadable(selected, selectedProfile.legalName, false);
            await captureR66Visual(
              tester,
              'rv6-d017-${destination.name}-switched-text-$scale',
            );
            // Dismissing the selector does not mutate the purchase or Profile.
            await tester.tapAt(const Offset(12, 60));
            await tester.pumpAndSettle();
            expect(find.text('Invoice recipient'), findsNothing);
            expect(controller.savedProfiles, hasLength(2));
            expect(controller.detailsFor(destination)?.id, otherProfile.id);
            await openRecipients();
            final personal = find.byKey(const ValueKey('buy-invoice-personal'));
            await tester.ensureVisible(personal);
            await tester.pumpAndSettle();
            await tester.tap(personal);
            await tester.pumpAndSettle();
            expect(controller.requestedFor(destination), isFalse);
            expect(controller.savedProfiles, hasLength(2));
            await openRecipients();
            expectReadable(personal, 'Personal purchase', true);
            expectReadable(unselected, otherProfile.legalName, false);
            await tester.tapAt(const Offset(12, 60));
            await tester.pumpAndSettle();
            expect(session.cartLines, hasLength(1));
            expect(session.quantityFor(product), originalQuantity);
            expect(session.cartTotal, originalTotal);
            expect(session.checkoutStep, BuyV2CheckoutStep.payment);
            expect(
              session.checkoutSubmissionState,
              BuyV2CheckoutSubmissionState.idle,
            );
            expect(session.checkoutPaymentAttempt, isNull);
            expect(session.confirmedOrders, isEmpty);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets('T14 invoice mixed recipient has no false selected default', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final controller = BuyV2GstInvoiceController(
      store: session.gstInvoiceProfileStore,
    );
    addTearDown(controller.dispose);
    expect(
      await controller.save(
        destination: BuyV2Destination.shop,
        legalName: 'Saved Business',
        gstin: '08ABCDE1234F1Z5',
        billingAddress: 'Test billing address',
        remember: true,
      ),
      isTrue,
    );
    controller.setRequested(BuyV2Destination.wholesale, false);
    Widget invoice(List<BuyV2Destination> destinations) => MaterialApp(
      theme: MoolTheme.light(),
      home: Scaffold(
        body: BuyV2CheckoutGstDetails(
          destinations: destinations,
          controller: controller,
        ),
      ),
    );
    await tester.pumpWidget(
      invoice(const [BuyV2Destination.shop, BuyV2Destination.wholesale]),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Choose one invoice recipient for this purchase'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('buy-invoice-change')));
    await tester.pumpAndSettle();
    final personal = find.byKey(const ValueKey('buy-invoice-personal'));
    final profile = find.byKey(
      ValueKey('buy-invoice-profile-${controller.savedProfiles.single.id}'),
    );
    expect(tester.widget<ListTile>(personal).selected, isFalse);
    expect(tester.widget<ListTile>(profile).selected, isFalse);
    expect(find.byIcon(Icons.check), findsNothing);
    await tester.tap(profile);
    await tester.pumpAndSettle();
    expect(controller.requestedFor(BuyV2Destination.shop), isTrue);
    expect(controller.requestedFor(BuyV2Destination.wholesale), isTrue);
    await tester.tap(find.byKey(const ValueKey('buy-invoice-change')));
    await tester.pumpAndSettle();
    expect(tester.widget<ListTile>(profile).selected, isTrue);
    expect(tester.widget<ListTile>(personal).selected, isFalse);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tapAt(const Offset(12, 60));
    await tester.pumpAndSettle();
    expect(controller.savedProfiles, hasLength(1));
    await tester.pumpWidget(invoice(const []));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-invoice-change')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('RV6 D019 minimize restores delivery identity text $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final journey = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'manual',
            areaLabel: 'Sardarpura',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      addTearDown(journey.dispose);
      await journey.start();
      await tester.pumpWidget(
        r66VisualCaptureRoot(
          MoolSocialApp(session: journey, initialLocation: '/app/buy?sub=shop'),
        ),
      );
      await tester.pumpAndSettle();
      // A fresh app must not activate historical review orders.
      expect(
        find.byKey(const ValueKey('buy-delivery-compact-artwork')),
        findsNothing,
      );
      final deliverySession = _R6633ActiveDeliveries(core: BuySession());
      addTearDown(deliverySession.dispose);
      await tester.pumpWidget(app(deliverySession, textScale: scale));
      await tester.pumpAndSettle();
      final artwork = find.byKey(
        const ValueKey('buy-delivery-compact-artwork'),
      );
      final toggle = find.byKey(const ValueKey('buy-quick-delivery-expand'));
      expect(artwork, findsOneWidget);
      final count = tester
          .widget<Text>(find.byKey(const ValueKey('buy-delivery-count')))
          .data;
      for (var round = 0; round < 2; round++) {
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
          findsOneWidget,
        );
        final minimize = find.byKey(
          const ValueKey('buy-quick-delivery-minimize'),
        );
        await tester.ensureVisible(minimize);
        await tester.tap(minimize);
        await tester.pumpAndSettle();
        await captureR66Visual(tester, 'rv6-d019-minimized-$round-text-$scale');
        expect(
          find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
          findsNothing,
        );
        expect(artwork, findsOneWidget);
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('buy-delivery-count')))
              .data,
          count,
        );
        expect(tester.widget<IconButton>(toggle).tooltip, startsWith('Show '));
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('RV6 D020 audience explanation clears Android inset $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final journey = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'manual',
            areaLabel: 'Sardarpura',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      addTearDown(journey.dispose);
      await journey.start();
      await tester.pumpWidget(
        r66VisualCaptureRoot(
          MoolSocialApp(
            session: journey,
            initialLocation: '/app/chat/inbox?return=%2Fapp%2Fbuy%3Fsub%3Dshop',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-more-settings')));
      await tester.pumpAndSettle();
      final setting = find.byKey(const Key('chat-settings-who-can-message'));
      await tester.scrollUntilVisible(
        setting,
        180,
        scrollable: find.descendant(
          of: find.byKey(const Key('chat-settings-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(setting);
      await tester.pumpAndSettle();
      await tester.tap(setting);
      await tester.pumpAndSettle();
      final explanation = find.text(
        'Existing conversations stay available; no one new can start.',
      );
      await tester.ensureVisible(explanation);
      await tester.pumpAndSettle();
      await captureR66Visual(tester, 'rv6-d020-audience-text-$scale');
      expect(tester.getBottomRight(explanation).dy, lessThanOrEqualTo(796));
      expect(explanation.hitTestable(), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('chat-message-permission-picker')),
        findsNothing,
      );
      expect(find.byKey(const Key('chat-settings-screen')), findsOneWidget);
      expect(find.text('Message permission saved.'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('RV6 D021 empty cart restores grid height text $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(
        core: BuySession(),
        reviewDataEnabled: true,
        initialCatalogueRegionId: 'jodhpur',
        cataloguePageSource: BuyV2DevelopmentCatalogueSource(
          destination: BuyV2Destination.shop,
          providerCount: 10,
          skusPerStore: 5000,
        ),
      );
      addTearDown(session.dispose);
      session.chooseShopSaleType(BuyV2ShopSaleType.courier);
      session.chooseFulfilmentMode(BuyV2FulfilmentMode.standardCourier);
      await tester.pumpWidget(app(session, textScale: scale));
      await tester.pumpAndSettle();
      final card = find.byType(BuyV2ProductCard).first;
      final product = tester.widget<BuyV2ProductCard>(card).product;
      final initialHeight = tester.getSize(card).height;
      final address = session.selectedAddress.id;
      session.toggleSaved(product.id);
      await captureR66Visual(tester, 'rv6-d021-before-text-$scale');
      expect(session.addProduct(product.id), isTrue);
      expect(session.addProduct(product.id), isTrue);
      await tester.pumpAndSettle();
      final populatedHeight = tester.getSize(card).height;
      expect(populatedHeight, greaterThanOrEqualTo(initialHeight));
      final quantityControl = find.byKey(
        ValueKey('buy-quantity-${product.id}'),
      );
      expect(quantityControl, findsOneWidget);
      expect(
        tester.getRect(card).contains(tester.getCenter(quantityControl)),
        isTrue,
      );
      session.decrease(product.id);
      await tester.pumpAndSettle();
      expect(tester.getSize(card).height, populatedHeight);
      session.decrease(product.id);
      await tester.pumpAndSettle();
      await captureR66Visual(tester, 'rv6-d021-empty-text-$scale');
      expect(session.quantityFor(product.id), 0);
      expect(tester.getSize(card).height, closeTo(initialHeight, .1));
      expect(session.selectedAddress.id, address);
      expect(
        session
            .savedProductsFor(BuyV2Destination.shop)
            .any((p) => p.id == product.id),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('RV6 D022 area chooser retains visible selection $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final location = TestCurrentLocationSource('jaipur', 'Jaipur');
      final session = BuyV2Session(
        core: BuySession(),
        shoppingAreaSource: location,
        reviewDataEnabled: true,
        initialCatalogueRegionId: 'jodhpur',
        catalogueAreas: const {'jodhpur': 'Jodhpur', 'jaipur': 'Jaipur'},
        cataloguePageSource: BuyV2DevelopmentCatalogueSource(
          destination: BuyV2Destination.shop,
          providerCount: 10,
          skusPerStore: 5000,
        ),
      );
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session, textScale: scale));
      await tester.pumpAndSettle();
      final address = session.selectedAddress.id;
      for (final region in ['jaipur', 'jodhpur']) {
        location.area = BuyV2ShoppingArea(
          regionId: region,
          googlePlaceId: 'test-$region',
          label: region,
          countryCode: 'IN',
        );
        unawaited(
          showBuyV2CatalogueArea(
            tester.element(find.byType(BuyV2Screen)),
            session,
          ),
        );
        await tester.pumpAndSettle();
        final confirm = find.byKey(
          const ValueKey('buy-current-location-confirm'),
        );
        await Scrollable.ensureVisible(tester.element(confirm), alignment: .5);
        await tester.pumpAndSettle();
        expect(confirm.hitTestable(), findsOneWidget);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(session.catalogueRegionId, region);
        unawaited(
          showBuyV2CatalogueArea(
            tester.element(find.byType(BuyV2Screen)),
            session,
          ),
        );
        await tester.pumpAndSettle();
        final result = find.byKey(
          const ValueKey('buy-current-location-result'),
        );
        expect(
          find.descendant(of: result, matching: find.text(region)),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('buy-catalogue-area-search')),
          findsNothing,
        );
        await captureR66Visual(tester, 'rv6-d022-current-$region-text-$scale');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.selectedAddress.id, address);
        expect(session.catalogueRegionId, region);
      }
      expect(tester.takeException(), isNull);
    });
  }

  final d018Cases = [
    for (final scale in [1.0, 2.0])
      for (final systemBack in [true, false])
        (scale: scale, systemBack: systemBack, change: 'none'),
    for (final change in ['cart', 'account', 'query', 'mode'])
      (scale: 1.0, systemBack: true, change: change),
  ];
  for (final entry in d018Cases) {
    final scale = entry.scale;
    final systemBack = entry.systemBack;
    testWidgets(
      'RV6 D018 paginated search Back retains visible page system $systemBack text $scale change ${entry.change}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final session = BuyV2Session(
          core: BuySession(),
          reviewDataEnabled: true,
          initialCatalogueRegionId: 'jodhpur',
          cataloguePageSource: BuyV2DevelopmentCatalogueSource(
            destination: BuyV2Destination.shop,
            providerCount: 10,
            skusPerStore: 5000,
          ),
        );
        addTearDown(session.dispose);
        session.chooseShopSaleType(BuyV2ShopSaleType.courier);
        session.chooseFulfilmentMode(BuyV2FulfilmentMode.standardCourier);
        expect(session.addProduct('w-notebook'), isTrue);
        await tester.pumpWidget(app(session, textScale: scale));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-search-control')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('buy-search-field')),
          'milk',
        );
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        final search = find.byType(BuyV2SearchResultsView);
        expect(search, findsOneWidget);
        final rangeFinder = find.byKey(
          const ValueKey('buy-page-status-search-shop'),
        );
        final actions = tester
            .widget<Semantics>(rangeFinder)
            .properties
            .customSemanticsActions!;
        final next = actions.keys.singleWhere(
          (action) => action.label == 'Next products',
        );
        actions[next]!();
        await tester.pumpAndSettle();
        final range = tester.widget<Semantics>(rangeFinder).properties.label!;
        expect(range, startsWith('41'));
        final card = find
            .descendant(of: search, matching: find.byType(BuyV2ProductCard))
            .first;
        final product = tester.widget<BuyV2ProductCard>(card).product;
        expect(product.title.toLowerCase(), contains('milk'));
        await Scrollable.ensureVisible(tester.element(card), alignment: .35);
        await tester.pumpAndSettle();
        final vertical = find
            .descendant(
              of: find.byKey(const ValueKey('buy-paged-scroll-search-shop')),
              matching: find.byType(Scrollable),
            )
            .first;
        final offset = tester.state<ScrollableState>(vertical).position.pixels;
        final query = session.query;
        final mode = session.saleTypeSignature;
        final retainedQuantity = session.quantityFor('w-notebook');
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, product.id,
          reason: 'Search card open: blocked=${session.cartChangesBlocked}; '
            'notice=${session.notice}; commerce=${session.commerceMessage}');
        expect(find.byType(BuyV2ProductView), findsOneWidget);
        if (entry.change == 'cart') {
          session.openCart();
          await tester.pumpAndSettle();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.selectedProductId, product.id);
          expect(session.view, BuyV2View.product);
        } else if (entry.change == 'account') {
          await tester.pumpWidget(
            app(session, textScale: scale, accountAuthenticated: true),
          );
          await tester.pumpAndSettle();
        } else if (entry.change == 'query') {
          session.updateQuery('rice');
          await tester.pumpAndSettle();
        } else if (entry.change == 'mode') {
          session.chooseShopSaleType(BuyV2ShopSaleType.quickDelivery);
          await tester.pumpAndSettle();
        }
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(
            find
                .descendant(
                  of: find.byType(BuyV2ProductView),
                  matching: find.text('Shop'),
                )
                .first,
          );
        }
        await tester.pumpAndSettle();
        if (entry.change == 'none' || entry.change == 'cart') {
          expect(search, findsOneWidget);
          expect(tester.testTextInput.isVisible, isFalse);
          expect(tester.widget<Semantics>(rangeFinder).properties.label, range);
          expect(
            find.byKey(ValueKey('buy-paged-card-${product.id}')),
            findsOneWidget,
          );
          expect(
            tester.state<ScrollableState>(vertical).position.pixels,
            closeTo(offset, 1),
          );
          expect(session.query, query);
          expect(session.saleTypeSignature, mode);
          await captureR66Visual(
            tester,
            'rv6-d018-search-return-system-$systemBack-text-$scale-${entry.change}',
          );
        } else {
          expect(search, findsNothing);
          expect(session.view, BuyV2View.catalogue);
        }
        expect(session.quantityFor('w-notebook'), retainedQuantity);
        expect(tester.takeException(), isNull);
      },
    );
  }

  final d014Cases = [
    for (final id in ['s-dog-food', 'w-notebook'])
      for (final scale in [1.0, 2.0])
        (id: id, overlay: 'repeat-store', scale: scale, orderId: 'MS-240782'),
    for (final scale in [1.0, 2.0])
      (
        id: 's-dog-food',
        overlay: 'recent-other-return',
        scale: scale,
        orderId: 'MS-240782',
      ),
    for (final id in ['s-dog-food', 'w-notebook'])
      for (final overlay in ['store', 'other-open', 'other-return', 'full'])
        for (final scale in [1.0, 2.0])
          (id: id, overlay: overlay, scale: scale, orderId: 'MS-240782'),
    for (final scale in [1.0, 2.0])
      (
        id: 's-dog-food',
        overlay: 'full',
        scale: scale,
        orderId: 'missing-order',
      ),
    (id: 's-dog-food', overlay: 'opening', scale: 1.0, orderId: 'MS-240782'),
  ];
  for (final entry in d014Cases) {
    testWidgets(
      'RV6 D014 warm order link ${entry.id} ${entry.overlay} ${entry.orderId} text ${entry.scale}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = entry.scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final journey = JourneySession(
          store: MemoryJourneyStore(
            snapshot: const JourneySnapshot(
              languageCode: 'en',
              areaMode: 'manual',
              areaLabel: 'Sardarpura',
              setupComplete: true,
            ),
          ),
          otpGateway: ReviewOtpGateway(signedIn: true),
        );
        addTearDown(journey.dispose);
        await journey.start();
        final shop = entry.id.startsWith('s-');
        final destination = shop ? 'shop' : 'wholesale';
        await tester.pumpWidget(
          r66VisualCaptureRoot(
            MoolSocialApp(
              session: journey,
              initialLocation: '/app/buy?sub=$destination',
            ),
          ),
        );
        await tester.pumpAndSettle();
        final session = tester
            .widget<BuyV2Screen>(find.byType(BuyV2Screen))
            .session;
        expect(session.addProduct('s-milk'), isTrue);
        session.toggleSaved('s-milk');
        final addressId = session.selectedAddress.id;
        if (entry.overlay == 'repeat-store') {
          var firstReplyReceived = false;
          final firstDelivery = tester.binding.defaultBinaryMessenger
              .handlePlatformMessage(
                SystemChannels.navigation.name,
                SystemChannels.navigation.codec.encodeMethodCall(
                  MethodCall('pushRouteInformation', {
                    'location':
                        'https://moolsocial.com/app/buy/order/${entry.orderId}',
                    'state': null,
                  }),
                ),
                (_) => firstReplyReceived = true,
              );
          await tester.pumpAndSettle();
          await firstDelivery;
          expect(firstReplyReceived, isTrue);
          expect(session.view, BuyV2View.tracking);
          await tester.tap(
            find.byKey(
              ValueKey(
                shop
                    ? 'moolsocial-family-root-buy-tap'
                    : 'buy-local-tab-wholesale',
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          expect(
            session.destination,
            shop ? BuyV2Destination.shop : BuyV2Destination.wholesale,
          );
        }
        if (entry.overlay == 'recent-other-return') {
          // Recently viewed opens a temporary product route. Its pending
          // return must not restore browsing over a newer platform link.
          final visit = tester
              .widget<BuyV2CatalogueView>(find.byType(BuyV2CatalogueView))
              .onVisitProduct!;
          unawaited(visit(session.product(entry.id), 'Recently viewed'));
        } else {
          expect(session.openProduct(entry.id), isTrue);
        }
        await tester.pumpAndSettle();
        final storeAction = find.byKey(
          ValueKey(
            '${shop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-${entry.id}',
          ),
        );
        await tester.scrollUntilVisible(
          storeAction,
          220,
          scrollable: scrollableWithin(
            PageStorageKey('buy-product-${entry.id}'),
          ),
        );
        await Scrollable.ensureVisible(
          tester.element(storeAction),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        expect(storeAction.hitTestable(), findsOneWidget);
        await tester.tap(storeAction);
        if (entry.overlay == 'opening') {
          await tester.pump(const Duration(milliseconds: 16));
        } else {
          await tester.pumpAndSettle();
        }
        final prefix = shop ? 'buy-shop-seller' : 'buy-wholesale-supplier';
        final storeSheet = find.byKey(ValueKey('$prefix-sheet-${entry.id}'));
        expect(storeSheet, findsOneWidget);
        final visitedStoreIds = <String>{entry.id};
        if (entry.overlay.contains('other-')) {
          final other = session
              .otherStorePreviewsFor(session.product(entry.id))
              .first;
          visitedStoreIds.add(other.id);
          final otherCard = find.byKey(
            ValueKey('$prefix-other-store-${other.id}'),
          );
          await tester.scrollUntilVisible(
            otherCard,
            220,
            scrollable: scrollableWithin(ValueKey('$prefix-sheet-list')),
          );
          await tester.ensureVisible(otherCard);
          await tester.pumpAndSettle();
          expect(otherCard.hitTestable(), findsOneWidget);
          await tester.tap(otherCard);
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('$prefix-sheet-${other.id}')),
            findsOneWidget,
          );
          if (entry.overlay.endsWith('other-return')) {
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(storeSheet, findsOneWidget);
          }
        } else if (entry.overlay == 'full') {
          final more = find.byKey(ValueKey('$prefix-view-more-${entry.id}'));
          await tester.ensureVisible(more);
          await tester.tap(more);
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('$prefix-full-catalogue-list')),
            findsOneWidget,
          );
        }
        final savedIds = session
            .savedProductsFor(BuyV2Destination.shop)
            .map((p) => p.id)
            .toList();
        expect(session.isSaved('s-milk'), isTrue);
        var linkReplyReceived = false;
        final linkDelivery = tester.binding.defaultBinaryMessenger
            .handlePlatformMessage(
              SystemChannels.navigation.name,
              SystemChannels.navigation.codec.encodeMethodCall(
                MethodCall('pushRouteInformation', {
                  'location':
                      'https://moolsocial.com/app/buy/order/${entry.orderId}',
                  'state': null,
                }),
              ),
              (_) => linkReplyReceived = true,
            );
        await tester.pumpAndSettle();
        expect(linkReplyReceived, isTrue);
        await linkDelivery;
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
        for (final id in visitedStoreIds) {
          expect(find.byKey(ValueKey('$prefix-sheet-$id')), findsNothing);
        }
        expect(
          find.byKey(ValueKey('$prefix-full-catalogue-list')),
          findsNothing,
        );
        expect(
          tester.widget<BuyV2Screen>(find.byType(BuyV2Screen)).session,
          same(session),
        );
        final missingOrder = entry.orderId == 'missing-order';
        if (missingOrder) {
          expect(find.text('This order could not be found.'), findsOneWidget);
          expect(find.byKey(const Key('buy-order-tracking')), findsNothing);
        } else {
          expect(
            find.byKey(PageStorageKey('buy-tracking-${entry.orderId}')),
            findsOneWidget,
          );
          expect(session.view, BuyV2View.tracking);
        }
        expect(session.quantityFor('s-milk'), 1);
        expect(
          session.savedProductsFor(BuyV2Destination.shop).map((p) => p.id),
          unorderedEquals(savedIds),
        );
        expect(session.selectedAddress.id, addressId);
        if (entry.overlay == 'repeat-store' ||
            (shop && entry.overlay.endsWith('other-return')) ||
            missingOrder ||
            (!shop && entry.overlay == 'full')) {
          await captureR66Visual(
            tester,
            'rv6-d014-${entry.id}-${entry.overlay}-${entry.orderId}-text-${entry.scale}',
          );
        }
        if (missingOrder) {
          await tester.tap(
            find.byKey(const ValueKey('moolsocial-family-root-buy-tap')),
          );
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
        expect(find.byType(ErrorWidget), findsNothing);
        expect(tester.takeException(), isNull);
        expect(session.quantityFor('s-milk'), 1);
        expect(
          session.savedProductsFor(BuyV2Destination.shop).map((p) => p.id),
          unorderedEquals(savedIds),
        );
        expect(session.selectedAddress.id, addressId);
      },
    );
  }

  testWidgets('RV6 D013 Store return rejects a changed account context', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    final authenticated = ValueNotifier(true);
    addTearDown(session.dispose);
    addTearDown(authenticated.dispose);
    final router = GoRouter(
      initialLocation: '/buy',
      routes: [
        GoRoute(
          path: '/buy',
          builder: (context, state) => ValueListenableBuilder<bool>(
            valueListenable: authenticated,
            builder: (context, value, _) =>
                BuyV2Screen(session: session, accountAuthenticated: value),
          ),
        ),
        GoRoute(
          path: '/app/chat/thread/:threadId',
          builder: (context, state) => const Scaffold(
            key: ValueKey('d013-context-chat'),
            body: Text('Conversation'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: MoolTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(session.openProduct('s-eggs'), isTrue);
    await tester.pumpAndSettle();
    final storeAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-eggs'),
    );
    await tester.scrollUntilVisible(
      storeAction,
      220,
      scrollable: scrollableWithin(const PageStorageKey('buy-product-s-eggs')),
    );
    await tester.pumpAndSettle();
    await tester.tap(storeAction);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-public-store-ask')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('d013-context-chat')), findsOneWidget);
    authenticated.value = false;
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final storeSheet = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    expect(storeSheet, findsNothing);
    expect(session.takeStoreReturnAnchor(routeProductId: 's-eggs'), isNull);
    authenticated.value = true;
    await tester.pumpAndSettle();
    expect(storeSheet, findsNothing);
    expect(session.cartLines, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android Back from store Chat restores the Cart-origin store', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final router = GoRouter(
      initialLocation: '/buy',
      routes: [
        GoRoute(
          path: '/buy',
          builder: (context, state) => BuyV2Screen(session: session),
        ),
        GoRoute(
          path: '/app/chat/thread/:threadId',
          builder: (context, state) => const Scaffold(
            key: ValueKey('store-chat-route'),
            body: Text('Conversation'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: MoolTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(session.openProduct('s-eggs'), isTrue);
    await tester.pumpAndSettle();
    final storeAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-eggs'),
    );
    await tester.scrollUntilVisible(
      storeAction,
      220,
      scrollable: scrollableWithin(const PageStorageKey('buy-product-s-eggs')),
    );
    await tester.pumpAndSettle();
    expect(storeAction.hitTestable(), findsOneWidget);
    await tester.tap(storeAction);
    await tester.pumpAndSettle();

    final storeSheet = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    final storeScroll = find
        .descendant(of: storeSheet, matching: find.byType(Scrollable))
        .first;
    final addChicken = find.byKey(const ValueKey('buy-add-s-chicken'));
    await tester.scrollUntilVisible(addChicken, 180, scrollable: storeScroll);
    await tester.tap(addChicken);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(session.cartScope, BuyV2CartScope.shop);

    await tester.tap(find.byKey(const ValueKey('buy-cart-continue-store')));
    await tester.pumpAndSettle();
    expect(storeSheet, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buy-public-store-ask')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('store-chat-route')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('store-chat-route')), findsNothing);
    expect(storeSheet, findsOneWidget);
    expect(session.view, BuyV2View.cart);
    expect(session.cartScope, BuyV2CartScope.shop);
    expect(session.quantityFor('s-chicken'), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-SKU Shop products expose owner and Visit store wiring', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final tomato = session.product('s-tomato');
    expect(session.partnerCatalogueFor(tomato), hasLength(1));
    expect(session.openProduct(tomato.id), isTrue);
    await tester.pumpAndSettle();
    final storeAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-tomato'),
    );
    await tester.scrollUntilVisible(
      storeAction,
      220,
      scrollable: scrollableWithin(
        const PageStorageKey('buy-product-s-tomato'),
      ),
    );

    expect(storeAction, findsOneWidget);
    expect(
      find.textContaining(session.productFactsFor(tomato).partner),
      findsWidgets,
    );
    expect(storeAction.hitTestable(), findsOneWidget);
    await tester.tap(storeAction);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-shop-seller-sheet-s-tomato')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('buy-public-store-truth-s-tomato')),
        matching: find.textContaining('Retailer'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Verified retailer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('master Shop and Wholesale cards show real provider owners', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final shopCard = find.byKey(const ValueKey('buy-product-s-tomato'));
    expect(shopCard, findsOneWidget);
    expect(
      find.descendant(of: shopCard, matching: find.text('Shree Balaji Fresh')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: shopCard, matching: find.text('Retailer')),
      findsOneWidget,
    );

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    final wholesaleCard = find.byKey(const ValueKey('buy-product-w-tomato'));
    expect(wholesaleCard, findsOneWidget);
    expect(
      find.descendant(
        of: wholesaleCard,
        matching: find.text('Jodhpur Fresh Supply'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: wholesaleCard, matching: find.text('Wholesaler')),
      findsOneWidget,
    );
    expect(find.textContaining('Verified retailer'), findsNothing);
    expect(find.textContaining('Verified wholesaler'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('View all keeps browsing depth and surfaces live Cart feedback', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(session.openProduct('s-eggs'), isTrue);
    await tester.pumpAndSettle();

    final storeAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-eggs'),
    );
    await tester.scrollUntilVisible(
      storeAction,
      220,
      scrollable: scrollableWithin(const PageStorageKey('buy-product-s-eggs')),
    );
    await tester.pumpAndSettle();
    expect(storeAction.hitTestable(), findsOneWidget);
    await tester.tap(storeAction);
    await tester.pumpAndSettle();

    final storeSheet = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    final storeScroll = find
        .descendant(of: storeSheet, matching: find.byType(Scrollable))
        .first;
    final viewAll = find.byKey(
      const ValueKey('buy-shop-seller-view-more-s-eggs'),
    );
    await tester.scrollUntilVisible(viewAll, 180, scrollable: storeScroll);
    await tester.tap(viewAll);
    await tester.pumpAndSettle();

    final fullCatalogue = find.byKey(
      const ValueKey('buy-shop-seller-full-catalogue-list'),
    );
    final fullCatalogueSheet = find.byKey(
      const ValueKey('buy-shop-seller-full-catalogue-sheet'),
    );
    expect(fullCatalogue, findsOneWidget);
    expect(fullCatalogueSheet, findsOneWidget);
    await tester.tap(
      find.descendant(
        of: fullCatalogueSheet,
        matching: find.byKey(const ValueKey('buy-add-s-eggs')),
      ),
    );
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-eggs'), 1);
    final fullCatalogueCart = find.descendant(
      of: fullCatalogueSheet,
      matching: find.byKey(const ValueKey('buy-store-cart-bar')),
    );
    expect(fullCatalogueCart, findsOneWidget);

    await tester.tap(
      find.descendant(
        of: fullCatalogueSheet,
        matching: find.byKey(const ValueKey('buy-product-s-eggs')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Back to Safe Protein Store'), findsOneWidget);
    await tester.tap(find.text('Back to Safe Protein Store'));
    await tester.pumpAndSettle();
    expect(fullCatalogue, findsOneWidget);

    await tester.tap(fullCatalogueCart);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Other stores cards carry decisions, motion and Back continuity',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      var storeChatOpens = 0;
      await tester.pumpWidget(
        app(session, onOpenChat: () => storeChatOpens += 1),
      );
      await tester.pumpAndSettle();
      expect(session.openProduct('s-eggs'), isTrue);
      await tester.pumpAndSettle();

      final storeAction = find.byKey(
        const ValueKey('buy-shop-seller-action-s-eggs'),
      );
      await tester.scrollUntilVisible(
        storeAction,
        220,
        scrollable: scrollableWithin(
          const PageStorageKey('buy-product-s-eggs'),
        ),
      );
      await tester.pumpAndSettle();
      expect(storeAction.hitTestable(), findsOneWidget);
      await tester.tap(storeAction);
      await tester.pumpAndSettle();

      final originalStore = find.byKey(
        const ValueKey('buy-shop-seller-sheet-s-eggs'),
      );
      final storeScroll = find
          .descendant(of: originalStore, matching: find.byType(Scrollable))
          .first;
      final relatedStore = find.byKey(
        const ValueKey('buy-shop-seller-other-store-s-tomato'),
      );
      await tester.scrollUntilVisible(
        relatedStore,
        180,
        scrollable: storeScroll,
      );
      final relatedStoreMotion = find.descendant(
        of: originalStore,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is BuyV2CinematicCardReveal &&
              widget.stateKey == 'buy-shop-seller-other-store-s-tomato-motion',
        ),
      );
      expect(relatedStoreMotion, findsOneWidget);
      expect(
        tester.widget<BuyV2CinematicCardReveal>(relatedStoreMotion).duration,
        const Duration(milliseconds: 780),
      );
      expect(
        tester.widget<BuyV2CinematicCardReveal>(relatedStoreMotion).delay,
        Duration.zero,
      );
      expect(
        tester
            .widget<BuyV2IntentDepth>(
              find.descendant(
                of: relatedStore,
                matching: find.byType(BuyV2IntentDepth),
              ),
            )
            .spatial,
        isFalse,
      );
      expect(
        tester
            .widget<Material>(
              find.byKey(const ValueKey('buy-related-store-surface-s-tomato')),
            )
            .color,
        Colors.transparent,
      );
      final relatedCard = tester.widget<Container>(
        find.byKey(const ValueKey('buy-related-store-card-s-tomato')),
      );
      final priceHighlight = find.byKey(
        const ValueKey('buy-related-store-price-s-tomato'),
      );
      final priceText = find.descendant(
        of: priceHighlight,
        matching: find.byType(Text),
      );
      expect(
        (tester.widget<Container>(priceHighlight).decoration! as BoxDecoration)
            .color,
        Colors.transparent,
      );
      expect(
        tester.getSize(priceHighlight).width,
        closeTo(tester.getSize(priceText).width + 8, .1),
      );
      expect(tester.widget<Text>(priceText).style!.color, BuyV2Colors.ink);
      final relatedDecoration = relatedCard.decoration! as BoxDecoration;
      expect(relatedDecoration.gradient, isA<LinearGradient>());
      expect(relatedDecoration.gradient!.stops, [0, .6, 1]);
      expect(relatedDecoration.color, Colors.white);
      expect(relatedDecoration.border, isNotNull);
      for (final foreground in [
        BuyV2ActionStyle.primaryForeground,
        BuyV2Colors.ink,
        BuyV2Colors.muted,
      ]) {
        expect(
          1.05 / (foreground.computeLuminance() + .05),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(
        find.descendant(of: relatedStore, matching: find.byType(Icon)),
        findsNothing,
      );
      expect(
        find.descendant(of: relatedStore, matching: find.text('Visit →')),
        findsOneWidget,
      );
      for (final tint in [
        const Color(0xFFAA78C8),
        const Color(0xFF639BC4),
        const Color(0xFFD89579),
      ]) {
        final background = Color.alphaBlend(
          tint.withValues(alpha: .26),
          Colors.white,
        );
        expect(
          (background.computeLuminance() + .05) /
              (const Color(0xFF505568).computeLuminance() + .05),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(relatedDecoration.boxShadow, hasLength(1));
      expect(relatedDecoration.boxShadow!.single.offset, const Offset(0, 3));
      expect(
        tester
            .widget<Container>(
              find.byKey(const ValueKey('buy-related-store-header-s-tomato')),
            )
            .decoration,
        isNull,
      );
      expect(tester.getSize(relatedStore).width, inInclusiveRange(208, 390));
      expect(tester.getSize(relatedStore).height, lessThan(170));
      expect(
        find.descendant(
          of: relatedStore,
          matching: find.byTooltip('MoolSocial Fulfilment Store'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: relatedStore, matching: find.text('₹37')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: relatedStore,
          matching: find.textContaining(
            session
                .productFactsFor(session.product('s-tomato'))
                .deliveryPromise,
          ),
        ),
        findsOneWidget,
      );

      await Scrollable.ensureVisible(
        tester.element(relatedStore),
        alignment: .4,
      );
      await tester.pumpAndSettle();
      expect(relatedStore.hitTestable(), findsOneWidget);
      await tester.tap(relatedStore);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-seller-sheet-s-tomato')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(originalStore, findsOneWidget);

      expect(relatedStore.hitTestable(), findsOneWidget);
      await tester.tap(relatedStore);
      await tester.pumpAndSettle();
      final nestedStore = find.byKey(
        const ValueKey('buy-shop-seller-sheet-s-tomato'),
      );
      expect(nestedStore, findsOneWidget);
      await tester.tap(
        find.descendant(
          of: nestedStore,
          matching: find.byKey(const ValueKey('buy-public-store-ask')),
        ),
      );
      await tester.pumpAndSettle();
      expect(storeChatOpens, 1);
      expect(nestedStore, findsNothing);
      expect(originalStore, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Other store Cart closes both storefronts and opens Cart', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final storeProduct = session.product('s-eggs');
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-other-store-cart'),
              onPressed: () => unawaited(
                showBuyV2PartnerCatalogue(context, session, storeProduct),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-other-store-cart')));
    await tester.pumpAndSettle();

    final originalStore = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    final storeScroll = find
        .descendant(of: originalStore, matching: find.byType(Scrollable))
        .first;
    final relatedStore = find.byKey(
      const ValueKey('buy-shop-seller-other-store-s-tomato'),
    );
    await tester.scrollUntilVisible(relatedStore, 180, scrollable: storeScroll);
    await Scrollable.ensureVisible(tester.element(relatedStore), alignment: .4);
    await tester.pumpAndSettle();
    expect(relatedStore.hitTestable(), findsOneWidget);
    await tester.tap(relatedStore);
    await tester.pumpAndSettle();

    final nestedStore = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-tomato'),
    );
    final nestedRoute = find.byKey(
      const ValueKey('buy-shop-seller-route-s-tomato'),
    );
    final nestedAdd = find.descendant(
      of: nestedStore,
      matching: find.byKey(const ValueKey('buy-add-s-tomato')),
    );
    await Scrollable.ensureVisible(tester.element(nestedAdd), alignment: .4);
    await tester.pumpAndSettle();
    expect(nestedAdd.hitTestable(), findsOneWidget);
    await tester.tap(nestedAdd);
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-tomato'), 1);
    final nestedCart = find.descendant(
      of: nestedRoute,
      matching: find.byKey(const ValueKey('buy-store-cart-bar')),
    );
    expect(nestedCart, findsOneWidget);
    await tester.tap(nestedCart);
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.cart);
    expect(nestedStore, findsNothing);
    expect(originalStore, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Other stores decisions fit 320px at 140 percent text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final storeProduct = session.product('s-eggs');
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: const TextScaler.linear(1.4)),
            child: r66VisualCaptureRoot(child!),
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-related-store-fitment'),
              onPressed: () => unawaited(
                showBuyV2PartnerCatalogue(context, session, storeProduct),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-related-store-fitment')));
    await tester.pumpAndSettle();

    final storeSheet = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    final storeScroll = find
        .descendant(of: storeSheet, matching: find.byType(Scrollable))
        .first;
    final relatedStore = find.byKey(
      const ValueKey('buy-shop-seller-other-store-s-tomato'),
    );
    await tester.scrollUntilVisible(relatedStore, 150, scrollable: storeScroll);

    expect(
      find.byKey(const ValueKey('buy-shop-seller-other-stores')),
      findsOneWidget,
    );
    final stores = find.byKey(const ValueKey('buy-shop-seller-other-stores'));
    expect(tester.widget(stores), isA<Column>());
    expect(tester.getSize(relatedStore).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(relatedStore).width, tester.getSize(stores).width);
    expect(tester.getSize(relatedStore).width, lessThanOrEqualTo(320));
    final storeCards = find.descendant(
      of: stores,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'buy-related-store-card-',
            ),
      ),
    );
    Rect? previous;
    for (final element in storeCards.evaluate()) {
      final card = find.byElementPredicate(
        (candidate) => identical(candidate, element),
      );
      final bounds = tester.getRect(card);
      if (previous != null) expect(bounds.top, greaterThan(previous.bottom));
      previous = bounds;
      for (final textElement
          in find
              .descendant(of: card, matching: find.byType(RichText))
              .evaluate()) {
        final paragraph = textElement.renderObject;
        if (paragraph is RenderParagraph) {
          expect(paragraph.didExceedMaxLines, isFalse);
          final textFinder = find.byElementPredicate(
            (candidate) => identical(candidate, textElement),
          );
          expect(bounds.contains(tester.getRect(textFinder).topLeft), isTrue);
          expect(
            bounds.contains(tester.getRect(textFinder).bottomRight),
            isTrue,
          );
        }
      }
    }
    await captureR66Visual(tester, 'sku-related-stores-320-1.4');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Other stores cinematic reveal respects reduced motion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final storeProduct = session.product('s-eggs');
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-related-store-reduced-motion'),
              onPressed: () => unawaited(
                showBuyV2PartnerCatalogue(context, session, storeProduct),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('open-related-store-reduced-motion')),
    );
    await tester.pumpAndSettle();

    final storeSheet = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    final storeScroll = find
        .descendant(of: storeSheet, matching: find.byType(Scrollable))
        .first;
    final relatedStore = find.byKey(
      const ValueKey('buy-shop-seller-other-store-s-tomato'),
    );
    await tester.scrollUntilVisible(relatedStore, 150, scrollable: storeScroll);

    expect(
      tester
          .widget<Opacity>(
            find.byKey(
              const ValueKey(
                'buy-cinematic-card-content-'
                'buy-shop-seller-other-store-s-tomato-motion',
              ),
            ),
          )
          .opacity,
      1,
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(
              const ValueKey(
                'buy-cinematic-card-sheen-'
                'buy-shop-seller-other-store-s-tomato-motion',
              ),
            ),
          )
          .opacity,
      0,
    );
    expect(tester.takeException(), isNull);
  });

  for (final mode in ['closed', 'open', 'mixed']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('RV6 D012 full Store count is listings $mode text $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        addTearDown(tester.view.reset);
        final session = BuyV2Session(
          core: BuySession(),
          productFactsAdapter: _D012StoreFactsAdapter(mode),
        );
        await tester.pumpWidget(
          app(session, textScale: scale, disableAnimations: true),
        );
        await tester.pumpAndSettle();
        expect(session.openProduct('s-dog-food'), isTrue);
        await tester.pumpAndSettle();
        final storeAction = find.byKey(
          const ValueKey('buy-shop-seller-action-s-dog-food'),
        );
        await tester.scrollUntilVisible(
          storeAction,
          180,
          scrollable: scrollableWithin(
            const PageStorageKey('buy-product-s-dog-food'),
          ).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(storeAction);
        await tester.pumpAndSettle();
        expect(storeAction.hitTestable(), findsOneWidget);
        await tester.tap(storeAction);
        await tester.pumpAndSettle();
        if (mode == 'closed') {
          final status = find.byKey(const ValueKey('buy-public-store-status'));
          final statusText = find.descendant(
            of: status,
            matching: find.byType(Text),
          );
          expect(
            tester.renderObject<RenderParagraph>(statusText).didExceedMaxLines,
            isFalse,
          );
          expect(
            tester.getRect(statusText).right,
            lessThanOrEqualTo(tester.getRect(status).right),
          );
          expect(tester.takeException(), isNull);
          await captureR66Visual(tester, 'rv6-d012-closed-status-text-$scale');
        }
        final more = find.byKey(
          const ValueKey('buy-shop-seller-view-more-s-dog-food'),
        );
        await tester.ensureVisible(more);
        await tester.tap(more);
        await tester.pumpAndSettle();
        final full = find.byKey(
          const ValueKey('buy-shop-seller-full-catalogue-list'),
        );
        expect(full, findsOneWidget);
        final count = find.descendant(
          of: full,
          matching: find.text('Retailer · 4 products listed'),
        );
        expect(count, findsOneWidget);
        expect(
          find.descendant(
            of: full,
            matching: find.textContaining('available products'),
          ),
          findsNothing,
        );
        expect(
          tester.widget<Text>(count).style!.color,
          isNot(BuyV2Colors.green),
        );
        final blocked = find.descendant(
          of: full,
          matching: find.byKey(const ValueKey('buy-review-offer-s-cat-food')),
        );
        final add = find.descendant(
          of: full,
          matching: find.byKey(const ValueKey('buy-add-s-cat-food')),
        );
        expect(blocked, mode == 'open' ? findsNothing : findsOneWidget);
        expect(add, mode == 'open' ? findsOneWidget : findsNothing);
        expect(tester.takeException(), isNull);
        if (mode == 'closed') {
          await captureR66Visual(
            tester,
            'rv6-d012-closed-store-count-text-$scale',
          );
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-shop-seller-sheet-s-dog-food')),
          findsOneWidget,
        );
        expect(session.cartLines, isEmpty);
        expect(session.selectedProductId, 's-dog-food');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('closed store preserves truth and blocks unavailable Add', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(
      core: BuySession(),
      productFactsAdapter: const _StoreStatusFactsAdapter(
        state: BuyV2StoreOperatingState.closed,
        nextOpeningLabel: 'tomorrow at 8:00 am',
      ),
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(session.openProduct('s-eggs'), isTrue);
    await tester.pumpAndSettle();
    final storeAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-eggs'),
    );
    final productScroll = scrollableWithin(
      const PageStorageKey('buy-product-s-eggs'),
    );
    await tester.scrollUntilVisible(
      storeAction,
      220,
      scrollable: productScroll,
    );
    await tester.pumpAndSettle();
    expect(storeAction.hitTestable(), findsOneWidget);
    expect(tester.getCenter(storeAction).dy, lessThan(740));
    await tester.tap(storeAction);
    await tester.pumpAndSettle();

    expect(find.text('MoolSocial Fulfilment Store'), findsNothing);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('buy-public-store-truth-s-eggs')),
          )
          .properties
          .label,
      contains('MoolSocial Fulfilment Store. Safe Protein Store.'),
    );
    expect(find.text('Closed · Opens tomorrow at 8:00 am'), findsOneWidget);
    final storeSheet = find.byKey(
      const ValueKey('buy-shop-seller-sheet-s-eggs'),
    );
    final storeScroll = find
        .descendant(of: storeSheet, matching: find.byType(Scrollable))
        .first;
    final reviewChicken = find.byKey(
      const ValueKey('buy-review-offer-s-chicken'),
    );
    await tester.scrollUntilVisible(
      reviewChicken,
      160,
      scrollable: storeScroll,
    );
    expect(reviewChicken, findsOneWidget);
    expect(find.byKey(const ValueKey('buy-add-s-chicken')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no-products store preserves identity, status and Ask store', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession(), reviewDataEnabled: false);
    addTearDown(session.dispose);
    final storeProduct = BuyV2Catalogue.products.firstWhere(
      (product) => product.id == 's-eggs',
    );
    var askCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-empty-public-store'),
              onPressed: () => unawaited(
                showBuyV2PartnerCatalogue(
                  context,
                  session,
                  storeProduct,
                  onAskStore: (_) => askCount += 1,
                ),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-empty-public-store')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Safe Protein Store'), findsWidgets);
    expect(find.text('MoolSocial Fulfilment Store'), findsNothing);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('buy-public-store-truth-s-eggs')),
          )
          .properties
          .label,
      contains('MoolSocial Fulfilment Store. Safe Protein Store.'),
    );
    expect(session.productFactsFor(storeProduct).storeOperatingState, BuyV2StoreOperatingState.unknown);
    expect(find.text('Open'), findsNothing);
    expect(find.text('Store hours unavailable right now'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buy-public-store-fulfilment-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-public-store-fulfilment-details')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('buy-public-store-fulfilment-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Store hours unavailable right now'), findsOneWidget);
    expect(find.text('Open'), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-public-store-no-products')),
      findsOneWidget,
    );
    expect(find.text('No products available right now.'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-add-s-eggs')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('buy-public-store-ask')));
    await tester.pumpAndSettle();
    expect(askCount, 1);
    expect(
      find.byKey(const ValueKey('buy-public-store-no-products')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('public store truth fits 320px at 140 percent text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final storeProduct = BuyV2Catalogue.products.firstWhere(
      (product) => product.id == 's-eggs',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-compact-public-store'),
              onPressed: () => unawaited(
                showBuyV2PartnerCatalogue(
                  context,
                  session,
                  storeProduct,
                  onAskStore: (_) {},
                ),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-compact-public-store')));
    await tester.pumpAndSettle();

    final truth = find.byKey(const ValueKey('buy-public-store-truth-s-eggs'));
    expect(truth, findsOneWidget);
    final sheet = find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs'));
    final sheetScroll = find
        .descendant(of: sheet, matching: find.byType(Scrollable))
        .first;
    final ask = find.byKey(const ValueKey('buy-public-store-ask'));
    await tester.scrollUntilVisible(ask, 160, scrollable: sheetScroll);
    expect(tester.getSize(ask).height, greaterThanOrEqualTo(44));
    expect(find.text('MoolSocial Fulfilment Store'), findsNothing);
    expect(
      tester.widget<Semantics>(truth).properties.label,
      contains('MoolSocial Fulfilment Store. Safe Protein Store.'),
    );
    expect(find.textContaining('Address confirmed'), findsNothing);
    expect(find.textContaining('Store location unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Masala Ghar storefront is compact and product-led', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final storeProduct = session.product('s-turmeric');
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-compact-masala-store'),
              onPressed: () => unawaited(
                showBuyV2PartnerCatalogue(
                  context,
                  session,
                  storeProduct,
                  onAskStore: (_) {},
                ),
              ),
              child: const Text('Open store'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-compact-masala-store')));
    await tester.pumpAndSettle();

    final title = find.descendant(
      of: find.byKey(const ValueKey('buy-shop-seller-sheet-header')),
      matching: find.text(storeProduct.customerSeller(storeProduct.seller)),
    );
    expect(tester.widget<Text>(title).style?.fontSize, 14);
    final route = find.byKey(
      const ValueKey('buy-shop-seller-route-s-turmeric'),
    );
    expect(tester.getTopLeft(route).dy, 0);
    expect(tester.getSize(route).height, 844);
    final header = find.byKey(const ValueKey('buy-shop-seller-sheet-header'));
    expect(tester.getSize(header).height, lessThanOrEqualTo(58));
    final truth = find.byKey(
      const ValueKey('buy-public-store-truth-s-turmeric'),
    );
    expect(tester.getSize(truth).height, lessThanOrEqualTo(112));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('buy-public-store-ask'))).dy,
      lessThanOrEqualTo(tester.getTopLeft(truth).dy + 12),
    );
    final storeName = tester.widget<Text>(title);
    expect(find.byKey(const ValueKey('buy-public-store-name')), findsNothing);
    final storeLocation = tester.widget<Text>(
      find.byKey(const ValueKey('buy-public-store-location')),
    );
    expect(storeName.data, 'Masala Ghar');
    expect(storeName.maxLines, isNull);
    expect(storeLocation.maxLines, isNull);
    expect(
      find.byKey(const ValueKey('buy-public-store-fulfilment-details')),
      findsNothing,
    );
    final grid = find.descendant(
      of: route,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'buy-vertical-product-grid-',
            ),
      ),
    );
    expect(grid, findsOneWidget);
    expect(
      tester.getTopLeft(grid).dy - tester.getBottomLeft(truth).dy,
      lessThanOrEqualTo(12),
    );
    for (final product in session.partnerCatalogueFor(storeProduct).take(3)) {
      final productCard = find.byKey(ValueKey('buy-product-${product.id}'));
      if (productCard.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          productCard,
          150,
          scrollable: find
              .ancestor(of: grid, matching: find.byType(Scrollable))
              .first,
        );
        await tester.pumpAndSettle();
      }
      final card = find
          .descendant(
            of: grid,
            matching: find.byKey(ValueKey('buy-product-${product.id}')),
          )
          .first;
      expect(card, findsOneWidget);
      final add = find.descendant(
        of: card,
        matching: find.byKey(ValueKey('buy-add-${product.id}')),
      );
      expect(add, findsOneWidget);
      expect(tester.getSize(card).height, lessThanOrEqualTo(340));
      expect(tester.getRect(card).contains(tester.getCenter(add)), isTrue);
    }
    final viewAll = find.byKey(
      const ValueKey('buy-shop-seller-view-more-s-turmeric'),
    );
    expect(tester.getSize(viewAll).height, inInclusiveRange(44, 58));
    final visibleViewAll = find.byKey(
      const ValueKey('buy-shop-seller-view-more-visible-s-turmeric'),
    );
    expect(tester.getSize(visibleViewAll).height, lessThanOrEqualTo(18));
    expect(
      tester.getRect(header).contains(tester.getCenter(visibleViewAll)),
      isTrue,
    );
    final relatedTitle = tester.widget<Text>(find.text('Other stores'));
    expect(relatedTitle.style?.fontSize, 11.5);
    expect(
      tester.getTopLeft(find.text('Other stores')).dy -
          tester.getBottomLeft(grid).dy,
      lessThanOrEqualTo(14),
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-public-store-fulfilment-toggle')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-public-store-fulfilment-details')),
      findsOneWidget,
    );
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Quick'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey('buy-public-store-fulfilment-toggle')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-public-store-fulfilment-details')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Wholesale and Bulk provider storefront keeps Cart on SKU depth',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      session.openDestination(BuyV2Destination.wholesale);
      session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
      expect(session.openProduct('w-rice'), isTrue);
      await tester.pumpAndSettle();

      final supplierAction = find.byKey(
        const ValueKey('buy-wholesale-store-action-w-rice'),
      );
      final wholesaleProductScroll = scrollableWithin(
        const PageStorageKey('buy-product-w-rice'),
      );
      await tester.scrollUntilVisible(
        supplierAction,
        220,
        scrollable: wholesaleProductScroll,
      );
      await tester.ensureVisible(supplierAction);
      await tester.pumpAndSettle();
      expect(supplierAction.hitTestable(), findsOneWidget);
      expect(tester.getCenter(supplierAction).dy, lessThan(700));
      await tester.tap(supplierAction);
      await tester.pumpAndSettle();

      final supplierSheet = find.byKey(
        const ValueKey('buy-wholesale-supplier-sheet-w-rice'),
      );
      expect(supplierSheet, findsOneWidget);
      expect(find.text('MoolSocial Fulfilment Partner'), findsNothing);
      expect(find.textContaining('Wholesaler'), findsWidgets);
      final supplierTruth = find.byKey(
        const ValueKey('buy-public-store-truth-w-rice'),
      );
      expect(
        tester.widget<Semantics>(supplierTruth).properties.label,
        startsWith('MoolSocial Fulfilment Partner. '),
      );
      expect(
        find.descendant(of: supplierTruth, matching: find.text('Open')),
        findsNothing,
      );
      await tester.tap(
        find.descendant(
          of: supplierTruth,
          matching: find.byKey(
            const ValueKey('buy-public-store-fulfilment-toggle'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(
        find.descendant(
          of: supplierTruth,
          matching: find.text('Bulk delivery'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-public-store-ask-visible')),
          matching: find.text('Ask'),
        ),
        findsOneWidget,
      );

      final supplierSku = find.byKey(const ValueKey('buy-product-w-rice'));
      expect(supplierSku, findsOneWidget);
      await tester.tap(supplierSku);
      await tester.pumpAndSettle();
      expect(supplierSheet, findsNothing);
      expect(session.selectedProductId, 'w-rice');
      expect(find.byKey(const ValueKey('buy-store-cart-bar')), findsNothing);
      expect(find.text('Cart is empty'), findsNothing);
      final primary = find.byKey(const ValueKey('buy-product-primary-w-rice'));
      final productScroll = scrollableWithin(
        const PageStorageKey('buy-product-w-rice'),
      );
      await tester.scrollUntilVisible(primary, 220, scrollable: productScroll);
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(tester.element(primary), alignment: .4);
      await tester.pumpAndSettle();
      expect(primary.hitTestable(), findsOneWidget);
      await tester.tap(primary);
      await tester.pumpAndSettle();
      expect(session.quantityFor('w-rice'), greaterThanOrEqualTo(1));
      expect(find.byKey(const ValueKey('buy-store-cart-bar')), findsNothing);
      final productCart = find.byKey(
        const ValueKey('buy-cart-navigation-button'),
      );
      expect(productCart.hitTestable(), findsOneWidget);
      await tester.tap(productCart);
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.wholesale);
      expect(
        find.byKey(const ValueKey('buy-cart-continue-store')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('buy-cart-continue-store')))
            .height,
        greaterThanOrEqualTo(48),
      );
      final returnName = tester.widget<Text>(
        find.byKey(const ValueKey('buy-cart-continue-store-name')),
      );
      expect(returnName.data, 'Thar Grains Wholesale');
      final returnNameFinder = find.byKey(
        const ValueKey('buy-cart-continue-store-name'),
      );
      expect(returnName.maxLines, isNull);
      expect(
        tester
            .renderObject<RenderParagraph>(returnNameFinder)
            .didExceedMaxLines,
        isFalse,
      );
      final returnBounds = tester.getRect(
        find.byKey(const ValueKey('buy-cart-continue-store')),
      );
      final nameBounds = tester.getRect(returnNameFinder);
      expect(nameBounds.left, greaterThanOrEqualTo(returnBounds.left));
      expect(nameBounds.right, lessThanOrEqualTo(returnBounds.right));
      expect(nameBounds.top, greaterThanOrEqualTo(returnBounds.top));
      expect(nameBounds.bottom, lessThanOrEqualTo(returnBounds.bottom));
      await tester.tap(find.byKey(const ValueKey('buy-cart-continue-store')));
      await tester.pumpAndSettle();
      expect(supplierSheet, findsOneWidget);
      expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.bulk);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Shop Quick Scheduled and Wholesale Bulk swipe selectors wire catalogues',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final shopSelector = find.byKey(
        const ValueKey('buy-shop-sale-type-selector'),
      );
      final shopThumb = find.byKey(const ValueKey('buy-shop-sale-type-thumb'));
      expect(shopSelector, findsOneWidget);
      expect(tester.getSize(shopSelector).height, 44);
      final quickThumbLeft = tester.getTopLeft(shopThumb).dx;
      expect(session.shopSaleType, BuyV2ShopSaleType.quickDelivery);
      expect(
        find.byKey(const ValueKey('buy-product-s-tomato')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-product-s-atta')), findsNothing);
      expect(find.text('Quick'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);

      await tester.fling(shopSelector, const Offset(-140, 0), 800);
      await tester.pumpAndSettle();
      expect(session.shopSaleType, BuyV2ShopSaleType.courier);
      expect(tester.getTopLeft(shopThumb).dx, greaterThan(quickThumbLeft));
      expect(find.byKey(const ValueKey('buy-product-s-tomato')), findsNothing);
      expect(find.byKey(const ValueKey('buy-product-s-atta')), findsOneWidget);
      expect(find.textContaining('Delivery today'), findsNothing);
      expect(find.text('Delivery schedule unavailable'), findsWidgets);
      expect(find.textContaining('after Store acceptance'), findsNothing);
      expect(find.textContaining('at checkout'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
      await tester.pumpAndSettle();
      final wholesaleSelector = find.byKey(
        const ValueKey('buy-wholesale-sale-type-selector'),
      );
      expect(wholesaleSelector, findsOneWidget);
      expect(tester.getSize(wholesaleSelector).height, 44);
      expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.wholesale);
      expect(
        find.byKey(const ValueKey('buy-product-w-tomato')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-product-w-rice')), findsNothing);

      await tester.fling(wholesaleSelector, const Offset(-140, 0), 800);
      await tester.pumpAndSettle();
      expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.bulk);
      expect(find.byKey(const ValueKey('buy-product-w-tomato')), findsNothing);
      expect(find.byKey(const ValueKey('buy-product-w-rice')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _captureR66Landscape(WidgetTester tester, String label) async {
  if (const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) {
    return captureR66Visual(tester, '001-$label');
  }
  if (!const bool.fromEnvironment('BUY_R66_LANDSCAPE_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  await tester.runAsync(() async {
    final directory = Directory('build/r66-landscape-v4-20260906');
    await directory.create(recursive: true);
    final output = File('${directory.path}/$label.png');
    if (await output.exists()) {
      throw StateError('Landscape capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) throw StateError('Landscape capture encoding failed');
      await output.writeAsBytes(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Future<void> _captureR66MonthlyBasket(WidgetTester tester, String label) async {
  if (const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) {
    return captureR66Visual(tester, '032-$label');
  }
  if (!const bool.fromEnvironment('BUY_R66_MONTHLY_BASKET_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  await tester.runAsync(() async {
    final directory = Directory('build/r66-monthly-basket-v1-20260905');
    await directory.create(recursive: true);
    final output = File('${directory.path}/$label.png');
    if (await output.exists()) {
      throw StateError('Monthly basket capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) {
        throw StateError('Monthly basket capture encoding failed');
      }
      await output.writeAsBytes(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

// Display geometry only; real session arithmetic is covered by connected tests.
Future<void> _captureR66Cart(WidgetTester tester, String label) async {
  if (const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) {
    return captureR66Visual(tester, 'cart-$label');
  }
  if (!const bool.fromEnvironment('BUY_R66_CART_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  await tester.runAsync(() async {
    final directory = Directory('build/r66-cart-review-v1-20260905');
    await directory.create(recursive: true);
    final output = File('${directory.path}/$label.png');
    if (await output.exists()) {
      throw StateError('Cart capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) throw StateError('Cart capture encoding failed');
      await output.writeAsBytes(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });

}

void _registerAiAct001Tests() {
  testWidgets(
    'AI-ACT-001 keeps prefill ephemeral, bound to the original Buy search owner',
    (tester) async {
      final session = _AiAct001SearchSession();
      addTearDown(session.dispose);
      addTearDown(session.core.dispose);
      session.destination = BuyV2Destination.wholesale;
      session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
      expect(session.addProduct('w-rice'), isTrue);
      session.toggleSaved('w-rice');
      final originalSaved = session
          .savedProductsFor(BuyV2Destination.wholesale)
          .map((product) => product.id)
          .toList();
      final originalCart = List<BuyV2CartLine>.of(session.cartLines);
      final navigatorKey = GlobalKey<NavigatorState>();
      final owner = ChangeNotifier();
      addTearDown(owner.dispose);
      var current = MoolAssistantContext(
        accountScope: 'assistant-search-account-a',
        authenticationRevision: 4,
      );
      var proposalSequence = 0;

      BuySearchNativeAdapter adapter() => BuySearchNativeAdapter(
        session: session,
        navigator: navigatorKey.currentState!,
        currentContext: () => current,
        isRootCurrent: () => navigatorKey.currentState?.mounted == true,
        scopeOwner: owner,
        accountIdentity: () => null,
        accountAuthenticated: () => true,
      );

      Future<Future<MoolAssistantReviewResult>> prepare(
        String query, {
        Duration lifetime = const Duration(minutes: 1),
        VoidCallback? afterSnapshot,
      }) async {
        final receiver = adapter();
        final snapshot = await receiver.snapshot(current, null);
        expect(snapshot, isNotNull);
        afterSnapshot?.call();
        final binding = current.binding;
        final proposal = MoolAssistantProposal(
          id: 'ai-act-001-${++proposalSequence}',
          actionId: 'AI-ACT-001',
          binding: binding,
          requestRevision: proposalSequence,
          entitlementRevision: 'host-paid-revision-1',
          sourceRevision: snapshot!.sourceRevision,
          validUntil: DateTime.now().add(lifetime),
          title: 'Find a product',
          summary: 'Search the current Buy catalogue',
          fields: {'query': query},
        );
        return receiver.openReview(
          proposal,
          () => current.binding == binding,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: MoolTheme.light(),
          home: const Scaffold(body: Center(child: Text('Assistant host fixture'))),
        ),
      );

      final initialReview = await prepare('whole grain rice');
      await tester.pumpAndSettle();
      expect(find.byType(BuyV2Screen), findsOneWidget);
      final searchField = find.byKey(const ValueKey('buy-search-field'));
      expect(searchField, findsOneWidget);
      expect(tester.widget<TextField>(searchField).controller!.text,
          'whole grain rice');
      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.saleTypeSignature, 'wholesale-bulk');
      expect(session.view, BuyV2View.catalogue);
      expect(session.query, isEmpty);
      expect(session.recentSearchesFor(BuyV2Destination.wholesale), isEmpty);
      expect(session.queryUpdates, 0);
      expect(session.searchSubmissions, 0);
      expect(session.cartLines, originalCart);
      expect(
        session.savedProductsFor(BuyV2Destination.wholesale)
            .map((product) => product.id),
        originalSaved,
      );
      navigatorKey.currentState!.pop(); // Cancel the original native form.
      await tester.pumpAndSettle();
      expect(await initialReview, MoolAssistantReviewResult.opened);
      expect(session.query, isEmpty);
      expect(session.recentSearchesFor(BuyV2Destination.wholesale), isEmpty);
      expect(session.cartLines, originalCart);
      expect(
        session.savedProductsFor(BuyV2Destination.wholesale)
            .map((product) => product.id),
        originalSaved,
      );

      // Only the original native Search/close control commits the proposal.
      final committedReview = await prepare('white basmati rice');
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'white basmati rice');
      await tester.pump();
      // Re-entering identical text changes no field value and must not persist
      // the proposed query before the original native Search submission.
      expect(session.query, isEmpty);
      expect(session.searchSubmissions, 0);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(session.searchSubmissions, 1);
      await tester.tap(find.byKey(const ValueKey('buy-search-close')));
      await tester.pumpAndSettle();
      expect(session.searchSubmissions, 1);
      expect(session.query, 'white basmati rice');
      expect(session.recentSearchesFor(BuyV2Destination.wholesale),
          ['white basmati rice']);
      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.saleTypeSignature, 'wholesale-bulk');
      expect(session.cartLines, originalCart);
      expect(
        session.savedProductsFor(BuyV2Destination.wholesale)
            .map((product) => product.id),
        originalSaved,
      );
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(await committedReview, MoolAssistantReviewResult.opened);

      // A clean generated value expires out of the field without changing Buy.
      session.updateQuery('');
      session.clearRecentSearches(BuyV2Destination.wholesale);
      session.queryUpdates = 0;
      session.searchSubmissions = 0;
      final expiresReview = await prepare(
        'expired generated query',
        lifetime: const Duration(milliseconds: 800),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(searchField).controller!.text,
          'expired generated query');
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.byKey(const ValueKey('buy-search-field')), findsNothing);
      expect(session.query, isEmpty);
      expect(session.queryUpdates, 0);
      expect(session.searchSubmissions, 0);
      expect(session.recentSearchesFor(BuyV2Destination.wholesale), isEmpty);
      expect(session.cartLines, originalCart);
      expect(
        session.savedProductsFor(BuyV2Destination.wholesale)
            .map((product) => product.id),
        originalSaved,
      );
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(await expiresReview, MoolAssistantReviewResult.opened);

      // Manual edits survive proposal expiry; an account change removes the
      // still-open route instead of exposing that old account's text.
      final dirtyReview = await prepare(
        'generated query to edit',
        lifetime: const Duration(milliseconds: 800),
      );
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'manual correction');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(tester.widget<TextField>(searchField).controller!.text,
          'manual correction');
      expect(session.query, 'manual correction');
      expect(session.searchSubmissions, 0);
      current = MoolAssistantContext(
        accountScope: 'assistant-search-account-b',
        authenticationRevision: 5,
      );
      owner.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(BuyV2Screen), findsNothing);
      expect(session.cartLines, originalCart);
      expect(
        session.savedProductsFor(BuyV2Destination.wholesale)
            .map((product) => product.id),
        originalSaved,
      );
      expect(await dirtyReview, MoolAssistantReviewResult.stale);

      // A nonempty original query and channel drift make the proposal stale.
      session.updateQuery('existing customer query');
      final existingStale = await prepare('different generated query');
      expect(await existingStale, MoolAssistantReviewResult.stale);
      expect(find.byType(BuyV2Screen), findsNothing);
      expect(session.query, 'existing customer query');
      session.updateQuery('');
      final channelStale = await prepare(
        'bulk item',
        afterSnapshot: () => session.chooseWholesaleSaleType(
          BuyV2WholesaleSaleType.wholesale,
        ),
      );
      expect(await channelStale, MoolAssistantReviewResult.stale);
      expect(find.byType(BuyV2Screen), findsNothing);
      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.saleTypeSignature, 'wholesale-wholesale');
      expect(session.cartLines, originalCart);
      expect(
        session.savedProductsFor(BuyV2Destination.wholesale)
            .map((product) => product.id),
        originalSaved,
      );
      session.destination = BuyV2Destination.medicine;
      expect(await adapter().snapshot(current, null), isNull);
      session.destination = BuyV2Destination.orders;
      expect(await adapter().snapshot(current, null), isNull);
      expect(tester.takeException(), isNull);
    },
  );

}

class _R66CartDisplayFixture extends BuyV2Session {
  _R66CartDisplayFixture(this.displayTotal) : super(core: BuySession());
  final int displayTotal;

  @override
  int totalForDestination(BuyV2Destination value) => displayTotal;

  @override
  int totalMinorForDestination(BuyV2Destination value) => displayTotal * 100;

  @override
  int get cartTotal => displayTotal;

  @override
  int get cartTotalMinor => displayTotal * 100;
}

// Layout-only totals; arithmetic and real quantities use the session suites.
class _R668CartPayableFixture extends _R66CartDisplayFixture {
  _R668CartPayableFixture(super.displayTotal);

  @override
  int get scopedPayableTotal => displayTotal;

  @override
  int get scopedPayableTotalMinor => displayTotal * 100;
}

void _expectCustomerFacingBuyCopy(
  WidgetTester tester, {
  bool isolatedReview = false,
}) {
  final root = find.byKey(const ValueKey('buy-v2-screen'));
  expect(root, findsOneWidget);
  final copy = <String>[];
  for (final text in tester.widgetList<Text>(
    find.descendant(of: root, matching: find.byType(Text)),
  )) {
    final value = text.data ?? text.textSpan?.toPlainText() ?? '';
    // The founder requires synthetic order fixtures to identify their provenance.
    if (isolatedReview && const {'Review data',
      'Demo catalogue · Not live inventory'}.contains(value)) {
      continue;
    }
    copy.add(value);
  }
  for (final field in tester.widgetList<TextField>(
    find.descendant(of: root, matching: find.byType(TextField)),
  )) {
    copy.addAll([
      field.decoration?.labelText ?? '',
      field.decoration?.hintText ?? '',
      field.decoration?.helperText ?? '',
    ]);
  }
  for (final semantics in tester.widgetList<Semantics>(
    find.descendant(of: root, matching: find.byType(Semantics)),
  )) {
    copy.add(semantics.properties.label ?? '');
    copy.add(semantics.properties.hint ?? '');
  }
  final visible = copy.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final match = _forbiddenBuyCopy.firstMatch(visible);
  expect(
    match,
    isNull,
    reason:
        'Forbidden customer-facing wording "${match?.group(0)}". '
        'Visible Buy copy: $visible',
  );
  expect(tester.takeException(), isNull);
}

class _R6633ActiveDeliveries extends BuyV2Session {
  _R6633ActiveDeliveries({required super.core});
  @override
  List<BuyV2Order> get activeDeliveryOrders => orders
      .where(
        (o) =>
            o.collection == null &&
            o.destination != BuyV2Destination.medicine &&
            !orderIsCompleted(o),
      )
      .toList(growable: false);
}

class _AiAct001SearchSession extends BuyV2Session {
  _AiAct001SearchSession() : super(core: BuySession());
  int queryUpdates = 0;
  int searchSubmissions = 0;

  @override
  void updateQuery(String value) {
    queryUpdates++;
    super.updateQuery(value);
  }

  @override
  bool submitSearch(String value) {
    searchSubmissions++;
    return super.submitSearch(value);
  }
}


void _registerAiAct018Tests() {
  testWidgets(
    'AI-ACT-018 opens the native Cart quantity editor with an ephemeral draft',
    (tester) async {
      final session = _AiAct018Session();
      addTearDown(session.dispose);
      addTearDown(session.core.dispose);
      session.destination = BuyV2Destination.wholesale;
      const productId = 'w-rice-50kg';
      // The seeded catalogue row has no current pack terms. This isolated
      // fixture qualifies only the exact sack whose native quantity form is
      // under test; production keeps requiring a current source pack contract.
      session.fixtureProduct = session.product(productId).copyWith(
        pack: 'sack', unitPrice: '',
        packTerms: const BuyV2PackTerms(
          skuId: productId, revision: 'isolated-act018-v1', sellUnit: 'sack'),
      );
      expect(session.addProduct(productId), isTrue);
      session.openCart();
      final originalLine = session.cartLineFor(productId)!;
      final originalQuantity = originalLine.quantity;
      final requestedQuantity = originalQuantity + originalLine.product.quantityStep;
      final manualQuantity = requestedQuantity + originalLine.product.quantityStep;
      expect(session.cartQuantityError(productId, '$requestedQuantity'), isNull);
      expect(session.cartQuantityError(productId, '$manualQuantity'), isNull);

      final navigatorKey = GlobalKey<NavigatorState>();
      final scopeOwner = ChangeNotifier();
      addTearDown(scopeOwner.dispose);
      var current = MoolAssistantContext(
        accountScope: 'assistant-cart-account-a',
        authenticationRevision: 1,
      );
      late BuildContext nativeContext;
      var sequence = 0;

      BuyCartQuantityNativeAdapter adapter() => BuyCartQuantityNativeAdapter(
        context: nativeContext,
        session: session,
        navigator: navigatorKey.currentState!,
        currentContext: () => current,
        isRootCurrent: () => navigatorKey.currentState?.mounted == true,
        scopeOwner: scopeOwner,
      );

      Future<({Future<MoolAssistantReviewResult> result})> prepare({Duration ttl = const Duration(minutes: 1)}) async {
        final receiver = adapter();
        final snapshot = await receiver.snapshot(current, productId);
        expect(snapshot, isNotNull);
        expect(snapshot!.entityId, productId);
        expect(snapshot.sourceRevision, contains(buyCartQuantityFormRevision));
        final binding = current.binding;
        final proposal = MoolAssistantProposal(
          id: 'ai-act-018-${++sequence}',
          actionId: 'AI-ACT-018',
          binding: binding,
          requestRevision: sequence,
          entitlementRevision: 'host-paid-revision-1',
          sourceRevision: snapshot.sourceRevision,
          validUntil: DateTime.now().add(ttl),
          title: 'Change quantity',
          summary: 'Edit the current Cart line',
          entityId: productId,
          fields: {'quantity': requestedQuantity},
        );
        return (result: receiver.openReview(proposal, () => current.binding == binding));
      }

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: MoolTheme.light(),
          home: Builder(
            builder: (context) {
              nativeContext = context;
              return const Scaffold(body: Center(child: Text('Assistant host')));
            },
          ),
        ),
      );

      // The proposed number is only a TextEditingController value until Update.
      final cancelledReview = (await prepare()).result;
      await tester.pumpAndSettle();
      final quantityField = find.byKey(const ValueKey('buy-quantity-input'));
      expect(quantityField, findsOneWidget);
      expect(tester.widget<TextField>(quantityField).controller!.text, '$requestedQuantity');
      expect(BuyV2ThemeScope.refinedOf(nativeContext), isFalse);
      expect(BuyV2ThemeScope.refinedOf(tester.element(quantityField)), isTrue);
      expect(session.setQuantityCalls, 0);
      expect(session.cartLineFor(productId), same(originalLine));
      expect(session.quantityFor(productId), originalQuantity);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await cancelledReview, MoolAssistantReviewResult.opened);
      expect(session.setQuantityCalls, 0);
      expect(session.cartLineFor(productId), same(originalLine));

      // A person can revise the prefilled draft; session updates do not overwrite it.
      final editedReview = (await prepare()).result;
      await tester.pumpAndSettle();
      await tester.enterText(quantityField, '$manualQuantity');
      session.notifyListeners();
      scopeOwner.notifyListeners();
      await tester.pump();
      expect(quantityField, findsOneWidget);
      expect(tester.widget<TextField>(quantityField).controller!.text, '$manualQuantity');
      expect(session.setQuantityCalls, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await editedReview, MoolAssistantReviewResult.opened);
      expect(session.quantityFor(productId), originalQuantity);

      // Only the original Update quantity control applies the proposed value once.
      final confirmedReview = (await prepare()).result;
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(quantityField).controller!.text, '$requestedQuantity');
      expect(session.setQuantityCalls, 0);
      await tester.tap(find.byKey(const ValueKey('buy-quantity-save')));
      await tester.pumpAndSettle();
      expect(session.setQuantityCalls, 1);
      expect(session.quantityFor(productId), requestedQuantity);
      expect(await confirmedReview, MoolAssistantReviewResult.opened);

      // Expired proposal removes the open editor without changing the Cart.
      final afterSaveLine = session.cartLineFor(productId)!;
      final expiredReview = (await prepare(ttl: const Duration(seconds: 1))).result;
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-quantity-input')), findsOneWidget);
      // The expiry owner uses the real wall clock; pump advances only timers.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1100)));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-quantity-input')), findsNothing);
      expect(session.setQuantityCalls, 1);
      expect(session.cartLineFor(productId), same(afterSaveLine));
      expect(await expiredReview, MoolAssistantReviewResult.stale);

      // Account change retires the native editor before the original Save can run.
      final staleReview = (await prepare()).result;
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-quantity-input')), findsOneWidget);
      current = MoolAssistantContext(
        accountScope: 'assistant-cart-account-b',
        authenticationRevision: 2,
      );
      scopeOwner.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-quantity-input')), findsNothing);
      expect(session.setQuantityCalls, 1);
      expect(session.cartLineFor(productId), same(afterSaveLine));
      expect(await staleReview, MoolAssistantReviewResult.stale);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AI-ACT-018 rejects Medicine context and prescription-required products before opening',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final session = _AiAct018Session();
      addTearDown(session.dispose);
      addTearDown(session.core.dispose);
      final scopeOwner = ChangeNotifier();
      addTearDown(scopeOwner.dispose);
      late BuildContext nativeContext;
      final context = MoolAssistantContext(
        accountScope: 'assistant-cart-account-a',
        authenticationRevision: 1,
      );
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        home: Builder(builder: (context) {
          nativeContext = context;
          return const Scaffold(body: Text('Assistant host'));
        }),
      ));

      BuyV2Product candidate({
        required String id,
        required BuyV2Destination destination,
        required bool requiresPrescription,
      }) => BuyV2Product(
        id: id,
        destination: destination,
        categoryId: 'test',
        brand: 'Test',
        title: 'Test product',
        variant: 'Test pack',
        pack: '1 pack',
        price: 100,
        unitPrice: '₹100/pack',
        badge: '',
        seller: 'Test store',
        sellerType: 'Store',
        deliveryPromise: 'Current promise',
        origin: 'Test area',
        confirmedOn: 'Test source',
        visualLabel: 'T',
        visualKind: 'pack',
        requiresPrescription: requiresPrescription,
      );

      Future<void> expectRejected({
        required BuyV2Product product,
        required BuyV2Destination sessionDestination,
      }) async {
        session.destination = sessionDestination;
        session.view = BuyV2View.cart;
        session.fixtureProduct = product;
        session.fixtureLine = BuyV2CartLine(product: product, quantity: 1);
        final receiver = BuyCartQuantityNativeAdapter(
          context: nativeContext,
          session: session,
          navigator: navigatorKey.currentState!,
          currentContext: () => context,
          isRootCurrent: () => navigatorKey.currentState?.mounted == true,
          scopeOwner: scopeOwner,
        );
        expect(await receiver.snapshot(context, product.id), isNull);
        expect(find.byKey(const ValueKey('buy-quantity-input')), findsNothing);
        expect(session.setQuantityCalls, 0);
        expect(session.quantityFor(product.id), 1);
      }

      await expectRejected(
        product: candidate(
          id: 'medicine-otc-test',
          destination: BuyV2Destination.medicine,
          requiresPrescription: false,
        ),
        sessionDestination: BuyV2Destination.medicine,
      );
      await expectRejected(
        product: candidate(
          id: 'shop-rx-test',
          destination: BuyV2Destination.shop,
          requiresPrescription: true,
        ),
        sessionDestination: BuyV2Destination.shop,
      );
      await expectRejected(
        product: candidate(
          id: 'shop-nonrx-medicine-context-test',
          destination: BuyV2Destination.shop,
          requiresPrescription: false,
        ),
        sessionDestination: BuyV2Destination.medicine,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _AiAct018Session extends BuyV2Session {
  _AiAct018Session() : this._(BuySession());
  _AiAct018Session._(BuySession value) : core = value,
    super(core: value, customerStateStore: _CartReturnOwnerStore());
  final BuySession core;
  int setQuantityCalls = 0;
  BuyV2Product? fixtureProduct;
  BuyV2CartLine? fixtureLine;

  @override
  BuyV2Product? findProduct(String id) =>
      fixtureProduct?.id == id ? fixtureProduct : super.findProduct(id);

  @override
  BuyV2CartLine? cartLineFor(String id) =>
      fixtureLine?.product.id == id ? fixtureLine : super.cartLineFor(id);

  @override
  int quantityFor(String id) =>
      fixtureLine?.product.id == id ? fixtureLine!.quantity : super.quantityFor(id);

  @override
  String? cartQuantityError(String id, String input) =>
      fixtureLine?.product.id == id ? null : super.cartQuantityError(id, input);

  @override
  bool setCartQuantity(String id, String input) {
    setQuantityCalls++;
    return super.setCartQuantity(id, input);
  }
}

// Isolated offline HOST fixtures. They exercise the actual Host/controller route,
// native Buy screen resource owner and existing methods, without model/device IO.
class _Shop04Paid extends ChangeNotifier implements MoolAssistantEntitlementSource {
  MoolAssistantAccess access=MoolAssistantAccess.active;
  void revoke(){access=MoolAssistantAccess.revoked;notifyListeners();}
  @override Future<MoolAssistantEntitlement> read(Object account) async =>
      MoolAssistantEntitlement(accountScope:account,access:access,
        revision:'HOST-shop04-paid',validUntil:DateTime.now().add(const Duration(hours:1)));
}
class _Shop04Commerce extends TestPaymentCommerce implements BuyV2MinorOrderPlacementAdapter {
  @override Future<BuyV2OrderPlacementResult> placeOrderMinor(BuyV2OrderPlacementRequest request)=>placeOrder(request);
  final reconciled=<(String,String)>[];
  @override Future<BuyV2OrderPlacementResult> reconcileOrder({required String idempotencyKey,required String paymentReference})async{
    reconciled.add((idempotencyKey,paymentReference));
    return BuyV2OrderPlacementResult(outcome:BuyV2OrderPlacementOutcome.paymentPending,customerMessage:'HOST original payment status',paymentReference:paymentReference);
  }
  BuyV2Order? order;
  Completer<BuyV2OrderRefreshResult>? orderGate;
  int orderReads=0,alertWrites=0;
  @override Future<BuyV2OrderRefreshResult> refreshOrder({required String orderId})async{
    orderReads++;
    if(orderGate!=null)return orderGate!.future;
    return BuyV2OrderRefreshResult(state:BuyV2CommerceLoadState.ready,
      customerMessage:'HOST original order status',order:order?.id==orderId?order:null);
  }
  @override Future<BuyV2OrderAlertsResult> loadOrderAlerts()async => const
    BuyV2OrderAlertsResult(available:true,enabled:true,customerMessage:'HOST original alert preference');
  @override Future<BuyV2OrderAlertsResult> setOrderAlerts({required bool enabled})async{
    alertWrites++;return BuyV2OrderAlertsResult(available:true,enabled:enabled,customerMessage:'HOST original preference saved');
  }
}
class _Shop04Quote extends TestPaymentQuote {
  int reads=0;
  @override Future<BuyV2CheckoutQuoteSnapshot> loadQuote({required List<BuyV2FulfilmentGroup> groups,
    required BuyV2Address address,required String selectedPaymentMethod,
    required List<BuyV2CartBenefit> selectedBenefits,required Map<String,int> tipAmountsByFulfilmentKey})async{
    reads++;
    return super.loadQuote(groups:groups,address:address,selectedPaymentMethod:selectedPaymentMethod,
      selectedBenefits:selectedBenefits,tipAmountsByFulfilmentKey:tipAmountsByFulfilmentKey);
  }
}
class _Shop04GroupedCommerce extends _Shop04Commerce implements BuyV2GroupedOrderPlacementAdapter,
    BuyV2MinorGroupedOrderPlacementAdapter,BuyV2PendingOrderRecoveryAdapter {
  final originalRequests=<String,BuyV2OrderPlacementRequest>{};
  bool fail=false,close=false;
  @override Future<BuyV2OrderPlacementResult> placePaymentGroupMinor(BuyV2OrderPlacementRequest request)=>placePaymentGroup(request);
  @override Future<BuyV2OrderPlacementResult> placePaymentGroup(BuyV2OrderPlacementRequest request)async{
    requests.add(request);originalRequests[request.idempotencyKey]=request;
    return testGroupedPlacement(request,outcome:fail?BuyV2OrderPlacementOutcome.failed:BuyV2OrderPlacementOutcome.confirmed);
  }
  @override Future<BuyV2OrderPlacementResult> reconcileOrder({required String idempotencyKey,required String paymentReference})async{
    reconciled.add((idempotencyKey,paymentReference));
    return testGroupedPlacement(originalRequests[idempotencyKey]!,outcome:BuyV2OrderPlacementOutcome.failed,retryAllowed:close);
  }
  @override Future<BuyV2OrderPlacementResult> recoverOrder({required String idempotencyKey})=>
    reconcileOrder(idempotencyKey:idempotencyKey,paymentReference:originalRequests[idempotencyKey]!.idempotencyKey);
}

class _Shop04HostHarness {
  _Shop04HostHarness({_Shop04Commerce? commerce,BuyV2CheckoutQuoteAdapter? quote,this.shop05=false,this.shop05Order,this.shop05Camera,this.shop05Principal,BuyV2DeliveryExceptionAdapter? delivery,BuyV2OrderResolutionAdapter? resolution,BuyV2BalancePaymentAdapter? balance,ScanPickGateway? collection,BuyV2CollectionPendingStore? pending,AuthenticatedWorkspaceOrderIdentityGateway? reader}):commerce=commerce??_Shop04Commerce(){cart=_CartNativeHarness(commerce:this.commerce,reviewDataEnabled:false,checkoutQuoteAdapter:quote,delivery:delivery,resolution:resolution,balance:balance,collection:collection,pending:pending,reader:reader);}
  final bool shop05;final BuyV2Order Function(BuyV2Product)? shop05Order;final BuyV2CollectionCameraBuilder? shop05Camera;final AuthenticatedAccountIdentity? shop05Principal;
  final _Shop04Commerce commerce;
  late final _CartNativeHarness cart;
  final paid=_Shop04Paid();
  List<MoolAssistantNativeAdapter> adapters=const [];
  MoolAssistantController? controller;
  int adapterReads=0,downloads=0,handoffs=0;
  Completer<BuyV2InvoiceDownloadOutcome>? downloadGate;
  BuyV2Order? order;
  Future<MoolAssistantReviewResult>? review;
  Object get effects=>(cart.session.effects,cart.owner.writes,commerce.requests.length,
      commerce.alertWrites,downloads,handoffs);

  Future<void> prepare(WidgetTester tester,{bool savedOrder=false,
      BuyV2View view=BuyV2View.checkout,BuyV2Destination destination=BuyV2Destination.shop,bool retainedBank=false})async{
    await cart.mount(tester,inCart:false,destination:destination,restoreAfterSource:retainedBank);
    final session=cart.session;
    const addresses=[BuyV2Address(id:'HOST-shop04-address',kind:BuyV2AddressKind.home,
      label:'HOST original Home',recipient:'HOST buyer',phone:'919876543210',line:'HOST original address',
      area:'HOST area',pinCode:'342003',landmark:'HOST landmark')];
    commerce.snapshot=BuyV2CommerceSnapshot(state:BuyV2CommerceLoadState.ready,
      products:[cart.product],addresses:addresses,selectedAddressId:addresses.single.id,
      paymentMethods:const {'UPI','Card'},businessVerified:true,upiQrAvailable:true);
    await session.restoreCommerce();
    if(destination==BuyV2Destination.wholesale)expect(session.businessVerified,isTrue);
    if(!retainedBank)expect(session.addProduct(cart.product.id),isTrue,reason:session.notice);
    session.openCart();if(view!=BuyV2View.cart)expect(session.openCheckout(),isTrue,reason:session.notice);
    if(savedOrder){
      order=BuyV2Order.minor(id:'HOST-shop04-order',purchaseId:'HOST-shop04-purchase',
        destination:destination,title:'HOST મૂળ saved order',itemSummary:'1 supplied product',
        totalMinor:cart.product.priceMinor,partner:'HOST supplied Store',partnerType:'Retailer',
        promise:'HOST supplied delivery',destinationLabel:'HOST supplied destination',progress:1,
        status:BuyV2OrderStatus.delivered,productIds:[cart.product.id],
        lines:[BuyV2CartLine(product:cart.product,quantity:1)],paymentMethod:'UPI',
        amountPaidNowMinor:cart.product.priceMinor,recipient:'HOST original recipient',
        addressLine:'HOST original saved address');
      if(shop05Order!=null)order=shop05Order!(cart.product);
      commerce.order=order;
    }
    commerce.snapshot=BuyV2CommerceSnapshot(state:BuyV2CommerceLoadState.ready,
      products:[cart.product],addresses:addresses,selectedAddressId:session.selectedAddressId,
      orders:order==null?const []:[order!],paymentMethods:const {'UPI','Card'},businessVerified:true,
      paymentCapabilities:[testPaymentCapability(session),testPaymentCapability(session,method:'Card')],
      upiQrAvailable:true);
    await session.restoreCommerce();
    if(savedOrder){
      if(order!.collection!=null){
        expect(session.openTracking(order!.id),isTrue);
        await tester.pumpAndSettle();
        expect(session.collectionSnapshotFor(order!.id),isNotNull,
          reason:session.collectionMessageFor(order!.id));
      }else{expect(await session.refreshOrder(order!.id),isTrue);}
    }
    final stores=session.acquireCatalogueStores('HOST-shop04-original-stores');
    await stores.open(session.catalogueQuery(catalogueDestination:destination,search:''));
    expect(stores.page,isNotNull,reason:stores.message);
    session.releaseCatalogueStores('HOST-shop04-original-stores');
    await mountNative(tester,view:view,destination:destination);
  }

  Future<void> prepareOriginalAttempt(WidgetTester tester)async{
    commerce.placementGate=Completer<BuyV2OrderPlacementResult>()..complete(
      BuyV2OrderPlacementResult(outcome:BuyV2OrderPlacementOutcome.paymentActionRequired,
        customerMessage:'HOST original payment authorization required',paymentReference:'HOST-original-payment-reference',
        paymentActionUri:Uri.https('payments.example.test','/HOST-original-payment')));
    await cart.session.submitOrder();await tester.pumpAndSettle();
    expect(cart.session.checkoutSubmissionState,BuyV2CheckoutSubmissionState.paymentActionRequired,
      reason:cart.session.notice);
    expect(cart.session.legacyCheckoutAttempt,isNotNull);
  }
  Future<void> mountNative(WidgetTester tester,{BuyV2View view=BuyV2View.checkout,
      BuyV2Destination destination=BuyV2Destination.shop})async{
    final session=cart.session;
    await tester.pumpWidget(MaterialApp(navigatorKey:cart.navigator,theme:MoolTheme.light(),
      builder:(_,child)=>MoolAssistantHost(readContext:()=>cart.context,contextChanges:cart.scope,
        entitlements:paid,child:child!),
      home:MoolAssistantNativeScope(readAdapters:(context){
        adapterReads++;
        adapters=(shop05?buyShop05NativeAdapters:buyShop04NativeAdapters)(session:session,navigator:cart.navigator.currentState!,
          currentContext:()=>cart.context,isRootCurrent:()=>cart.root,
          scopeOwner:Listenable.merge([cart.scope,session]),
          accountIdentity:()=>shop05Principal??_Shop03NativeHarness.principal,accountAuthenticated:()=>true).toList();
        return adapters;
      },child:Stack(children:[
        BuyV2Screen(session:session,accountIdentity:shop05Principal??_Shop03NativeHarness.principal,
          accountAuthenticated:true,initialDestination:destination,initialView:view,
          orderId:const {BuyV2View.tracking,BuyV2View.orderItems}.contains(view)?order?.id:null,
          recoveryKind:view==BuyV2View.recovery?session.recoveryKind:null,
          collectionCameraBuilder:shop05Camera,
          paymentHandoff:(uri)async{handoffs++;return true;},
          invoiceDownloader:(document)async{downloads++;return downloadGate==null?BuyV2InvoiceDownloadOutcome.saved:await downloadGate!.future;}),
        Positioned(top:0,right:0,child:Builder(builder:(context)=>Material(child:TextButton(
          key:const ValueKey('HOST-shop04-open-ai'),onPressed:()=>unawaited(MoolAssistantHost.maybeOf(context)!.open(context)),
          child:const Text('HOST open AI'))))),
      ])),
    ));
    await tester.pumpAndSettle();
    if(order!=null)expect(session.orders.any((v)=>v.id==order!.id),isTrue);
  }
  Future<MoolAssistantNativeAdapter> openAI(WidgetTester tester,String action)async{
    await tester.tap(find.byKey(const ValueKey('HOST-shop04-open-ai')));
    await tester.pumpAndSettle();
    controller=tester.widget<MoolAssistantPage>(find.byType(MoolAssistantPage)).controller;
    await controller!.refreshAccess();controller!.setDraft('HOST original Checkout request');
    await tester.pumpAndSettle();
    expect(adapterReads,1);
    return adapters.singleWhere((a)=>a.actionId==action);
  }
  Future<void> startReview(WidgetTester tester,String action,{String? entity,
      Map<String,Object?> fields=const {},Duration lifetime=const Duration(minutes:3),bool throughUi=false})async{
    final adapter=await openAI(tester,action);
    final snapshot=await adapter.snapshot(cart.context,entity);
    expect(snapshot,isNotNull,reason:action);
    expect(snapshot!.permitted,isTrue);
    expect(controller!.receiveProposal(MoolAssistantProposal(
      id:'HOST-shop04-$action',actionId:action,binding:cart.context.binding,
      requestRevision:controller!.requestRevision,entitlementRevision:controller!.entitlementRevision!,
      sourceRevision:snapshot.sourceRevision,entityId:entity,validUntil:DateTime.now().add(lifetime),
      title:'HOST supplied original order action',summary:'Use the actual native final control.',fields:fields)),isTrue);
    if(throughUi){
      await tester.pump(); // receiveProposal notifies before the UI can rebuild.
      final card=find.byType(MoolAssistantProposalCard);await _shop04RevealNativeControl(tester,card);
      await tester.tap(find.descendant(of:card,matching:find.text('Review')));
    }else{review=controller!.reviewProposal();}
    await tester.pumpAndSettle();
  }
  void retire(){
    cart.context=MoolAssistantContext(accountScope:cart.context.accountScope,authenticationRevision:2);
    cart.scope.value++;
  }
  Future<void> finishReview(WidgetTester tester)async{
    await tester.binding.handlePopRoute();await tester.pumpAndSettle();
    if(find.byType(BuyV2InvoicePage).evaluate().isNotEmpty){
      await tester.binding.handlePopRoute();await tester.pumpAndSettle();
    }
    if(review!=null)await review;
  }
  Future<void> dispose(WidgetTester tester)async{
    if(commerce.orderGate?.isCompleted==false)commerce.orderGate!.complete(
      BuyV2OrderRefreshResult(state:BuyV2CommerceLoadState.ready,customerMessage:'HOST completed read',order:order));
    if(downloadGate?.isCompleted==false)downloadGate!.complete(BuyV2InvoiceDownloadOutcome.cancelled);
    if(commerce.placementGate?.isCompleted==false)commerce.placementGate!.complete(const BuyV2OrderPlacementResult(
      outcome:BuyV2OrderPlacementOutcome.paymentUnknown,customerMessage:'HOST original status unavailable'));
    if(commerce.refreshGate?.isCompleted==false)commerce.refreshGate!.complete(commerce.snapshot);
    await cart.dispose(tester);paid.dispose();
  }
}

Future<void> _shop04RevealNativeControl(WidgetTester tester,Finder target)async{
  // All owners are the actual visible native widgets; covered root pages are
  // excluded by Finder's normal skipOffstage behavior. No synthetic control.
  final owners=[find.byType(BuyV2InvoicePage),find.byType(BuyV2TrackingView),
    find.byType(BuyV2RecoveryView),find.byType(BuyV2CheckoutView),find.byType(MoolAssistantPage)];
  if(target.evaluate().isEmpty){
    final owner=owners.firstWhere((candidate)=>candidate.evaluate().isNotEmpty);
    final scrollables=find.descendant(of:owner,matching:find.byWidgetPredicate((w)=>
      w is Scrollable && (w.axisDirection==AxisDirection.down || w.axisDirection==AxisDirection.up)));
    expect(scrollables,findsWidgets,reason:'The native owner must expose its real vertical scrollable.');
    await tester.scrollUntilVisible(target,240,scrollable:scrollables.last,maxScrolls:40);
  }
  expect(target,findsOneWidget);
  await tester.ensureVisible(target);await tester.pump();
}

void registerShop04NativeHostTests(){
  Future<void> tap(WidgetTester tester,Finder target)async{
    await _shop04RevealNativeControl(tester,target);await tester.pump();
    expect(target.hitTestable(),findsOneWidget);await tester.tap(target);await tester.pumpAndSettle();
  }
  test('FE-SHOP-04 closed native scalars never accept payment claims or document bytes',(){
    for(final action in const ['AI-ACT-029','AI-ACT-033','AI-ACT-037','AI-ACT-038','AI-ACT-040','AI-ACT-041','AI-ACT-042',
      'AI-ACT-043','AI-ACT-044','AI-ACT-045','AI-ACT-046','AI-ACT-047','AI-ACT-057','AI-ACT-058','AI-ACT-342','AI-ACT-343',
      'AI-ACT-344','AI-ACT-345','AI-ACT-346','AI-ACT-413','AI-ACT-414']){
      expect(()=>BuyShop04InitialData.fromFields(action,{'verifiedPaid':true}),throwsFormatException);
      expect(()=>BuyShop04InitialData.fromFields(action,{'paymentUri':'upi://invented'}),throwsFormatException);
    }
    for(final entry in [('AI-ACT-033',<String,Object?>{'method':' UPI'}),('AI-ACT-047',<String,Object?>{'enabled':'false'}),
      ('AI-ACT-342',<String,Object?>{'profileId':null}),('AI-ACT-343',<String,Object?>{'useQr':1})]){
      expect(()=>BuyShop04InitialData.fromFields(entry.$1,entry.$2),throwsFormatException);
    }
    final fields=<String,Object?>{'method':'Card'};
    final initial=BuyShop04InitialData.fromFields('AI-ACT-033',fields);fields['method']='UPI';expect(initial.method,'Card');
  });
  for(final destination in [BuyV2Destination.shop,BuyV2Destination.wholesale]){
    testWidgets('FE-SHOP-04 actual Host 033 stages current method under $destination without selecting it',(tester)async{
      final h=_Shop04HostHarness();try{
        await h.prepare(tester,destination:destination);
        final original=h.cart.session.selectedPayment,before=h.effects;
        await h.startReview(tester,'AI-ACT-033',fields:const {'method':'Card'});
        expect(h.effects,before);expect(h.cart.session.selectedPayment,original);
        expect(find.byType(MoolAssistantPage,skipOffstage:false),findsOneWidget);
        final choice=find.byKey(const ValueKey('buy-payment-Card'));
        expect(choice,findsOneWidget);
        final theme=BuyV2ThemeScope.of(tester.element(choice));
        final expected=BuyV2ThemeSpec.resolve(destination,BuyV2View.checkout);
        expect(theme.headerStart,expected.headerStart);expect(theme.headerGradient,expected.headerGradient);
        expect(BuyV2ThemeScope.refinedOf(tester.element(choice)),isTrue);
        await tap(tester,choice);expect(h.cart.session.selectedPayment,'Card');
        expect(h.commerce.requests,isEmpty);expect(h.handoffs,0);
        await h.finishReview(tester);expect(tester.takeException(),isNull);
      }finally{await h.dispose(tester);}
    });
  }
  testWidgets('FE-SHOP-04 029 shows exact original Store and keeps collection unselected until native tap',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester);final before=h.effects;
      expect(h.cart.session.collectionCheckoutSelected,isFalse);
      await h.startReview(tester,'AI-ACT-029',entity:'HOST-native-store');
      expect(h.effects,before);expect(h.cart.session.collectionCheckoutSelected,isFalse);
      expect(find.textContaining('HOST original Store'),findsWidgets);
      final collect=find.byKey(const ValueKey('buy-checkout-collection-choice'));
      await tap(tester,collect);
      expect(h.cart.session.collectionCheckoutSelected,isTrue);
      expect(h.cart.session.collectionCheckoutStore?.id,'HOST-native-store');
      expect(h.commerce.requests,isEmpty);await h.finishReview(tester);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 343 stages actual QR mode without generating or dispatching a payment',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester);final before=h.effects,mode=h.cart.session.useUpiQr;
      await h.startReview(tester,'AI-ACT-343',fields:const {'useQr':true});
      expect(h.effects,before);expect(h.cart.session.useUpiQr,mode);
      expect(h.cart.session.upiQrAction,isNull);
      await tap(tester,find.byKey(const ValueKey('buy-upi-use-qr')));
      expect(h.cart.session.useUpiQr,isTrue);expect(h.commerce.requests,isEmpty);
      expect(h.cart.session.upiQrAction,isNull);await h.finishReview(tester);
    }finally{await h.dispose(tester);}
  });
  for(final action in ['AI-ACT-043','AI-ACT-044','AI-ACT-045','AI-ACT-413','AI-ACT-414']){
    testWidgets('FE-SHOP-04 $action uses actual saved goods without selecting/reordering/downloading on Review',(tester)async{
      final h=_Shop04HostHarness();try{
        await h.prepare(tester,savedOrder:true);
        final before=h.effects,selected=h.cart.session.selectedOrderOrNull?.id;
        await h.startReview(tester,action,entity:action=='AI-ACT-043'?null:h.order!.id);
        expect(h.effects,before);expect(h.cart.session.selectedOrderOrNull?.id,selected);
        expect(h.commerce.requests,isEmpty);expect(h.downloads,0);
        expect(find.textContaining(const {'AI-ACT-043','AI-ACT-044'}.contains(action)?h.order!.title:h.cart.product.customerTitle),findsWidgets);
        if(action=='AI-ACT-413'){
          final download=find.byKey(ValueKey('buy-download-invoice-${h.order!.id}'));
          await _shop04RevealNativeControl(tester,download);
          expect(tester.widget<FilledButton>(download).onPressed,isNull);
        }
        await h.finishReview(tester);expect(tester.takeException(),isNull);
      }finally{await h.dispose(tester);}
    });
  }
  testWidgets('FE-SHOP-04 047 supplied false is staged and only original Apply changes the preference',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester,savedOrder:true);
      expect(h.cart.session.trackingAlertsAvailable,isTrue);expect(h.cart.session.trackingAlertsEnabled,isTrue);
      final before=h.effects;
      await h.startReview(tester,'AI-ACT-047',entity:h.order!.id,fields:const {'enabled':false});
      expect(h.effects,before);expect(h.cart.session.trackingAlertsEnabled,isTrue);
      final toggle=find.byKey(const ValueKey('buy-tracking-alerts-toggle'));
      await _shop04RevealNativeControl(tester,toggle);expect(tester.widget<Switch>(toggle).value,isFalse);
      await tap(tester,find.byKey(const ValueKey('buy-tracking-alerts-apply')));
      expect(h.cart.session.trackingAlertsEnabled,isFalse);
      expect(h.commerce.requests,isEmpty);await h.finishReview(tester);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 342 original populated picker remains inert after same-namespace principal retirement',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester);final before=h.effects,namespace=h.cart.owner.ownerScope;
      await h.startReview(tester,'AI-ACT-342',fields:const {'profileId':'personal'});
      final target=find.byKey(const ValueKey('buy-invoice-personal'));
      final retained=tester.widget<ListTile>(target).onTap!;
      expect(h.effects,before);h.retire();await tester.pumpAndSettle();retained();await tester.pump();
      expect(h.cart.owner.ownerScope,namespace);expect(h.effects,before);
      expect(target,findsNothing);expect(await h.review,MoolAssistantReviewResult.stale);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 expiry removes exact recipient dialog and review while preserving unrelated root route',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester);final before=h.effects;
      await h.startReview(tester,'AI-ACT-342',fields:const {'profileId':'personal'},lifetime:const Duration(seconds:2));
      final retained=tester.widget<ListTile>(find.byKey(const ValueKey('buy-invoice-personal'))).onTap!;
      unawaited(h.cart.navigator.currentState!.push<void>(MaterialPageRoute<void>(builder:(_)=>const Scaffold(body:Text('HOST unrelated root route')))));
      await tester.pump(const Duration(seconds:3));await tester.pumpAndSettle();retained();await tester.pump();
      expect(find.text('HOST unrelated root route'),findsOneWidget);
      expect(find.byKey(const ValueKey('buy-invoice-personal'),skipOffstage:false),findsNothing);
      expect(h.effects,before);expect(await h.review,MoolAssistantReviewResult.stale);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 actual Host binding refuses arbitrary same-name cover and rebinding',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester);final adapter=await h.openAI(tester,'AI-ACT-033');
      expect(await adapter.snapshot(h.cart.context,null),isNotNull);
      unawaited(h.cart.navigator.currentState!.push<void>(MaterialPageRoute<void>(settings:const RouteSettings(name:'mool-assistant'),builder:(_)=>const Scaffold(body:Text('HOST foreign cover')))));
      await tester.pumpAndSettle();expect(await adapter.snapshot(h.cart.context,null),isNull);
      h.cart.navigator.currentState!.pop();await tester.pumpAndSettle();
      expect(await adapter.snapshot(h.cart.context,null),isNotNull);
      (adapter as MoolAssistantRouteBoundNativeAdapter).bindAssistantRoute(MaterialPageRoute<void>(builder:(_)=>const Scaffold()),h.cart.navigator.currentState!);
      expect(await adapter.snapshot(h.cart.context,null),isNull);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 ordinary cold Checkout adapters do not prevent actual Host opening',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester,view:BuyV2View.catalogue);
      final adapter=await h.openAI(tester,'AI-ACT-033');
      expect(find.byType(MoolAssistantPage),findsOneWidget);
      expect(await adapter.snapshot(h.cart.context,null),isNull);
      expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 native payment preparation retires during held original durable write without connector dispatch',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester);await h.startReview(tester,'AI-ACT-037');
      h.cart.owner.writeGate=Completer<void>();h.cart.owner.writeEntered=Completer<void>();
      final button=find.byKey(ValueKey('buy-checkout-primary-${h.cart.session.checkoutStep.name}'));
      await _shop04RevealNativeControl(tester,button);await tester.tap(button);await tester.pump(const Duration(milliseconds:100));
      expect(h.cart.owner.writeEntered!.isCompleted,isTrue);
      expect(h.commerce.requests,isEmpty);final namespace=h.cart.owner.ownerScope;
      h.retire();await tester.pump();h.cart.owner.writeGate!.complete();await tester.pumpAndSettle();
      expect(h.cart.owner.ownerScope,namespace);expect(h.commerce.requests,isEmpty);expect(h.handoffs,0);
      expect(await h.review,MoolAssistantReviewResult.stale);
      expect(h.cart.session.checkoutBusy,isFalse);expect(h.cart.session.confirmedOrders,isEmpty);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 actual Host from Cart renders original populated Checkout fields without admission or writes',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester,view:BuyV2View.cart);
      final before=h.effects,scope=h.cart.session.checkoutScope,step=h.cart.session.checkoutStep;
      final lines=List<BuyV2CartLine>.of(h.cart.session.cartLines);
      await h.startReview(tester,'AI-ACT-037',throughUi:true);
      expect(h.effects,before);expect(h.cart.session.view,BuyV2View.cart);
      expect(h.cart.session.checkoutScope,scope);expect(h.cart.session.checkoutStep,step);
      expect(h.cart.session.pendingCheckoutPresentationToken,isNull);
      expect(find.textContaining(h.cart.product.customerTitle),findsWidgets);
      expect(find.textContaining('HOST original address'),findsWidgets);
      expect(find.text('Total pending'),findsOneWidget);
      await tap(tester,find.text('Continue to Checkout'));
      expect(h.cart.session.view,BuyV2View.checkout);
      expect(h.cart.session.checkoutLines,orderedEquals(lines));
      expect(h.commerce.requests,isEmpty);expect(h.handoffs,0);
      // The existing shared close barrier owns the unsaved request.
      expect(find.text('Discard draft'),findsOneWidget);
      await tap(tester,find.text('Discard draft'));
      expect(find.byType(MoolAssistantPage),findsNothing);
      expect(find.byType(BuyV2CheckoutView),findsOneWidget);
      expect(h.cart.session.checkoutLines,orderedEquals(lines));
      expect(h.commerce.requests,isEmpty);expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 Cart projection refuses source retirement before native Continue',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester,view:BuyV2View.cart);final before=h.effects;
      await h.startReview(tester,'AI-ACT-037');
      final continueButton=find.widgetWithText(FilledButton,'Continue to Checkout');
      final retained=tester.widget<FilledButton>(continueButton).onPressed!;
      h.retire();await tester.pumpAndSettle();retained();await tester.pump();
      expect(h.cart.session.view,BuyV2View.cart);expect(h.effects,before);
      expect(h.commerce.requests,isEmpty);expect(await h.review,MoolAssistantReviewResult.stale);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 original attempt survives retirement after connector dispatch without a second request',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester);h.commerce.placementGate=Completer<BuyV2OrderPlacementResult>();
      await h.startReview(tester,'AI-ACT-037');
      final target=find.byKey(ValueKey('buy-checkout-primary-${h.cart.session.checkoutStep.name}'));
      await _shop04RevealNativeControl(tester,target);final retained=tester.widget<FilledButton>(target).onPressed!;
      retained();retained();await tester.pump(const Duration(milliseconds:100));
      expect(h.commerce.requests,hasLength(1));final original=h.commerce.requests.single;
      h.retire();await tester.pump();
      h.commerce.placementGate!.complete(const BuyV2OrderPlacementResult(outcome:BuyV2OrderPlacementOutcome.paymentPending,
        customerMessage:'HOST original payment awaiting verification',paymentReference:'HOST-original-reference'));
      await tester.pumpAndSettle();expect(await h.review,MoolAssistantReviewResult.stale);
      expect(h.commerce.requests,hasLength(1));expect(h.handoffs,0);
      expect(h.cart.session.checkoutRequiresResolution,isTrue);
      expect(h.cart.session.legacyCheckoutAttempt!.payment.request.idempotencyKey,original.idempotencyKey);
      expect(h.cart.session.legacyCheckoutAttempt!.payment.request.lines,orderedEquals(original.lines));
      expect(h.cart.session.confirmedOrders,isEmpty);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 414 actual native Download is the sole device boundary and stale completion has no feedback',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester,savedOrder:true);h.downloadGate=Completer<BuyV2InvoiceDownloadOutcome>();
      await h.startReview(tester,'AI-ACT-414',entity:h.order!.id);
      expect(h.downloads,0);
      final target=find.byKey(ValueKey('buy-download-invoice-${h.order!.id}'));
      await _shop04RevealNativeControl(tester,target);final retained=tester.widget<FilledButton>(target).onPressed!;
      retained();retained();await tester.pump();expect(h.downloads,1);
      h.retire();await tester.pump();h.downloadGate!.complete(BuyV2InvoiceDownloadOutcome.saved);
      await tester.pumpAndSettle();expect(await h.review,MoolAssistantReviewResult.stale);
      expect(h.downloads,1);expect(find.text('Invoice saved to this device.'),findsNothing);
      expect(h.commerce.requests,isEmpty);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 057 held original refresh cannot replace source after principal retirement',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester,savedOrder:true,view:BuyV2View.tracking);
      final original=h.cart.session.orders.singleWhere((o)=>o.id==h.order!.id);
      final oldReads=h.commerce.orderReads;
      await h.startReview(tester,'AI-ACT-057',entity:original.id);
      expect(h.commerce.orderReads,oldReads);h.commerce.orderGate=Completer<BuyV2OrderRefreshResult>();
      await tester.tap(find.byKey(ValueKey('buy-tracking-refresh-${original.id}')));await tester.pump();
      expect(h.commerce.orderReads,oldReads+1);h.retire();await tester.pump();
      final late=BuyV2Order.minor(id:original.id,purchaseId:original.purchaseId,destination:original.destination,
        title:'HOST newer verified order',itemSummary:original.itemSummary,totalMinor:original.totalMinor!,
        partner:original.partner,partnerType:original.partnerType,promise:original.promise,destinationLabel:original.destinationLabel,
        progress:original.progress,status:original.status,lines:original.lines,productIds:original.productIds,
        paymentMethod:original.paymentMethod,amountPaidNowMinor:original.amountPaidNowMinor);
      h.commerce.orderGate!.complete(BuyV2OrderRefreshResult(state:BuyV2CommerceLoadState.ready,customerMessage:'HOST late verified response',order:late));
      await tester.pumpAndSettle();expect(await h.review,MoolAssistantReviewResult.stale);
      expect(h.cart.session.orders.singleWhere((o)=>o.id==original.id),same(original));
      expect(h.cart.session.orderRefreshBusy(original.id),isFalse);
      expect(find.text('HOST newer verified order'),findsNothing);
    }finally{await h.dispose(tester);}
  });

  for(final action in ['AI-ACT-040','AI-ACT-041','AI-ACT-344']){
    testWidgets('FE-SHOP-04 $action retains the exact original native payment and has no Review dispatch',(tester)async{
      final h=_Shop04HostHarness();try{
        await h.prepare(tester);await h.prepareOriginalAttempt(tester);
        final attempt=h.cart.session.legacyCheckoutAttempt!,key=h.cart.session.checkoutIdempotencyKey;
        if(action=='AI-ACT-041'){
          expect(h.cart.session.cancelPaymentAttempt(),isTrue);
          // Native Leave queues its original durable state write. Finish setup
          // before measuring whether Review itself creates any new write.
          await tester.pumpAndSettle();
          expect(h.cart.owner.lastSnapshot!.checkoutSubmissionState,'paymentUnknown');
        }
        final before=h.effects;
        await h.startReview(tester,action,entity:key);
        expect(h.effects,before);expect(h.commerce.reconciled,isEmpty);
        if(action=='AI-ACT-344'){
          await tap(tester,find.byKey(const ValueKey('buy-checkout-cancel-payment')));
          expect(h.cart.session.checkoutSubmissionState,BuyV2CheckoutSubmissionState.paymentUnknown);
          expect(h.handoffs,0);expect(h.commerce.reconciled,isEmpty);
        }else{
          final target=find.byKey(ValueKey('buy-checkout-primary-${h.cart.session.checkoutStep.name}'));
          await tap(tester,target);
          if(action=='AI-ACT-040'){
            expect(h.handoffs,1);expect(h.commerce.reconciled,isEmpty);
          }else{
            expect(h.handoffs,0);
            expect(h.commerce.reconciled,[(key!,'HOST-original-payment-reference')]);
          }
        }
        expect(h.commerce.requests,hasLength(1));
        expect(h.cart.session.legacyCheckoutAttempt!.payment.request.idempotencyKey,attempt.payment.request.idempotencyKey);
        expect(h.cart.session.checkoutRequiresResolution,isTrue);
        expect(h.cart.session.confirmedOrders,isEmpty);await h.finishReview(tester);
      }finally{await h.dispose(tester);}
    });
  }
  testWidgets('FE-SHOP-04 046 uses the original native Reorder only after the saved record is reviewed',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester,savedOrder:true);
      final before=h.effects,selected=h.cart.session.selectedOrderOrNull?.id;
      await h.startReview(tester,'AI-ACT-046',entity:h.order!.id);
      expect(h.effects,before);expect(h.cart.session.selectedOrderOrNull?.id,selected);
      await tap(tester,find.byKey(const ValueKey('buy-tracking-reorder')));
      expect(h.cart.session.cartLines.map((line)=>line.product.id),contains(h.cart.product.id));
      expect(h.cart.session.view,BuyV2View.cart);expect(h.commerce.requests,isEmpty);
      expect(h.cart.session.confirmedOrders,isEmpty);await h.finishReview(tester);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 047 Apply reads the latest native staged edit rather than an older captured value',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester,savedOrder:true);
      await h.startReview(tester,'AI-ACT-047',entity:h.order!.id,fields:const {'enabled':false});
      final apply=find.byKey(const ValueKey('buy-tracking-alerts-apply'));
      await _shop04RevealNativeControl(tester,apply);final retained=tester.widget<TextButton>(apply).onPressed!;
      final toggle=find.byKey(const ValueKey('buy-tracking-alerts-toggle'));
      await tester.tap(toggle);await tester.pump();
      expect(tester.widget<Switch>(toggle).value,isTrue);expect(h.commerce.alertWrites,0);
      retained();await tester.pumpAndSettle();expect(h.commerce.alertWrites,1);
      expect(h.cart.session.trackingAlertsEnabled,isTrue);await h.finishReview(tester);
    }finally{await h.dispose(tester);}
  });
  for(final action in ['AI-ACT-033','AI-ACT-037','AI-ACT-043']){
    testWidgets('FE-SHOP-04 $action refuses an active excluded Medicine commerce context',(tester)async{
      final h=_Shop04HostHarness();try{
        await h.prepare(tester);final before=h.effects;
        h.cart.session.observedLines=[BuyV2CartLine(product:BuyV2Catalogue.products.firstWhere((p)=>p.destination==BuyV2Destination.medicine),quantity:1)];
        final adapter=await h.openAI(tester,action);
        expect(await adapter.snapshot(h.cart.context,null),isNull);expect(h.effects,before);
      }finally{await h.dispose(tester);}
    });
  }

  testWidgets('FE-SHOP-04 actual Host paid-access retirement blocks a captured native QR-mode callback',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester);final before=h.effects,mode=h.cart.session.useUpiQr;
      await h.startReview(tester,'AI-ACT-343',fields:const {'useQr':true});
      final retained=tester.widget<TextButton>(find.byKey(const ValueKey('buy-upi-use-qr'))).onPressed!;
      h.paid.revoke();await tester.pumpAndSettle();retained();await tester.pump();
      expect(h.effects,before);expect(h.cart.session.useUpiQr,mode);
      expect(await h.review,MoolAssistantReviewResult.stale);expect(h.commerce.requests,isEmpty);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 genuine Shop Rx and approved Store contexts do not inherit public capabilities',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester);final p=h.cart.product,before=h.effects;
      final rx=BuyV2Product(id:p.id,canonicalId:p.canonicalId,destination:p.destination,
        categoryId:p.categoryId,brand:p.brand,title:p.title,variant:p.variant,pack:p.pack,
        priceMinor:p.priceMinor,unitPrice:p.unitPrice,badge:p.badge,seller:p.seller,sellerType:p.sellerType,
        deliveryPromise:p.deliveryPromise,origin:p.origin,confirmedOn:p.confirmedOn,visualLabel:p.visualLabel,
        visualKind:p.visualKind,storeId:p.storeId,packTerms:p.packTerms,publicListingIdentity:p.publicListingIdentity,
        minimumOrder:p.minimumOrder,offerClass:p.offerClass,requiresPrescription:true);
      expect(rx.destination,BuyV2Destination.shop);expect(rx.requiresPrescription,isTrue);
      expect(rx.hasValidPackTerms,isTrue);expect(rx.hasValidPublicListingIdentity,isTrue);
      final adapter=await h.openAI(tester,'AI-ACT-037');
      expect(h.cart.context.accountScope,isNot(h.cart.owner.ownerScope));
      h.cart.session.observedLines=[BuyV2CartLine(product:rx,quantity:1)];
      expect(await adapter.snapshot(h.cart.context,null),isNull);
      h.cart.session.observedLines=null;
      h.cart.context=MoolAssistantContext(accountScope:h.cart.context.accountScope,authenticationRevision:1,
        workspaceId:'HOST-approved-Store',workspaceRevision:1,storeWorkspace:true,workspaceApproved:true);
      h.cart.scope.value++;await tester.pump();
      expect(await adapter.snapshot(h.cart.context,null),isNull);expect(h.effects,before);
    }finally{await h.dispose(tester);}
  });

  testWidgets('FE-SHOP-04 038 uses original verified price-change records and only native Accept writes',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester);
      h.cart.facts.priceMinorOverride=h.cart.product.priceMinor+100;h.cart.facts.revision='HOST-new-price-r2';
      expect(await h.cart.session.submitOrder(),isFalse);await tester.pumpAndSettle();
      expect(h.cart.session.checkoutPriceReviewRequired,isTrue,reason:h.cart.session.notice);
      final change=h.cart.session.checkoutPriceChanges.single;
      expect(change.previousPriceMinor,h.cart.product.priceMinor);expect(change.currentPriceMinor,h.cart.product.priceMinor+100);
      expect(h.commerce.requests,isEmpty);final before=h.effects;
      await h.startReview(tester,'AI-ACT-038');expect(h.effects,before);
      expect(h.cart.session.checkoutPriceReviewRequired,isTrue);
      await tap(tester,find.byKey(const ValueKey('buy-checkout-accept-prices')));
      expect(h.cart.session.checkoutPriceReviewRequired,isFalse);expect(h.commerce.requests,isEmpty);
      await h.finishReview(tester);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 346 removes only the actual native unavailable item after its original final tap',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester);h.cart.facts.available=false;
      expect(await h.cart.session.submitOrder(),isFalse);await tester.pumpAndSettle();
      expect(h.cart.session.checkoutAvailabilityIssue?.productId,h.cart.product.id,reason:h.cart.session.notice);
      expect(h.cart.session.view,BuyV2View.recovery);final before=h.effects;
      await h.startReview(tester,'AI-ACT-346',entity:h.cart.product.id);
      expect(h.effects,before);expect(h.cart.session.quantityFor(h.cart.product.id),1);
      await tap(tester,find.byKey(const ValueKey('buy-recovery-remove-product')));
      expect(h.cart.session.quantityFor(h.cart.product.id),0);
      expect(h.cart.session.checkoutAvailabilityIssue,isNull);expect(h.commerce.requests,isEmpty);
      await h.finishReview(tester);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 058 invokes original interrupted-journey return without starting a payment',(tester)async{
    final h=_Shop04HostHarness();try{
      await h.prepare(tester);final quantity=h.cart.session.quantityFor(h.cart.product.id);
      h.cart.session.openRecovery(BuyV2RecoveryKind.networkInterruption);await tester.pumpAndSettle();
      final before=h.effects;await h.startReview(tester,'AI-ACT-058');expect(h.effects,before);
      expect(h.cart.session.view,BuyV2View.recovery);
      await tap(tester,find.byKey(const ValueKey('buy-recovery-primary')));
      expect(h.cart.session.view,BuyV2View.checkout);
      expect(h.cart.session.quantityFor(h.cart.product.id),quantity);
      expect(h.commerce.requests,isEmpty);expect(h.handoffs,0);await h.finishReview(tester);
    }finally{await h.dispose(tester);}
  });

  for(final action in ['AI-ACT-042','AI-ACT-345']){
    testWidgets('FE-SHOP-04 $action cannot invent an original transfer or financial closure on a fresh Checkout',(tester)async{
      final h=_Shop04HostHarness();try{
        await h.prepare(tester);final before=h.effects;
        final adapter=await h.openAI(tester,action);
        expect(await adapter.snapshot(h.cart.context,'HOST-invented-original-attempt'),isNull);
        expect(h.effects,before);expect(h.commerce.requests,isEmpty);
        expect(h.cart.session.checkoutPaymentAttempt,isNull);
        expect(h.cart.session.legacyCheckoutAttempt,isNull);
        expect(find.byType(MoolAssistantPage),findsOneWidget);
      }finally{await h.dispose(tester);}
    });
  }

  for(final retirement in ['paid','request']){
    testWidgets('FE-SHOP-04 342 $retirement retirement on native quote loading dispatches no quote IO',(tester)async{
      final quote=_Shop04Quote(),h=_Shop04HostHarness(quote:quote);var retired=false;
      void retireOnLoading(){if(!retired && h.cart.session.checkoutQuoteLoadState==BuyV2CommerceLoadState.loading){
        retired=true;if(retirement=='paid'){h.paid.revoke();}else{h.controller!.setDraft('HOST replacement request');}
      }}
      try{
        await h.prepare(tester);await h.cart.session.refreshCheckoutQuote();
        expect(h.cart.session.checkoutQuoteLoadState,BuyV2CommerceLoadState.ready,reason:h.cart.session.checkoutQuoteMessage);
        await h.startReview(tester,'AI-ACT-342',fields:const {'profileId':'personal'});
        final reads=quote.reads;h.cart.session.addListener(retireOnLoading);
        await tester.tap(find.byKey(const ValueKey('buy-invoice-personal')));await tester.pumpAndSettle();
        expect(retired,isTrue);expect(quote.reads,reads);expect(h.cart.session.checkoutQuote,isNull);
        expect(h.cart.session.checkoutQuoteLoadState,isNot(BuyV2CommerceLoadState.loading));
        expect(h.commerce.requests,isEmpty);expect(await h.review,MoolAssistantReviewResult.stale);
      }finally{h.cart.session.removeListener(retireOnLoading);await h.dispose(tester);}
    });
  }
  testWidgets('FE-SHOP-04 342 held quote response cannot enter native state after captured request retirement',(tester)async{
    final quote=_Shop04Quote(),h=_Shop04HostHarness(quote:quote);
    try{
      await h.prepare(tester);await h.cart.session.refreshCheckoutQuote();
      expect(h.cart.session.checkoutQuoteLoadState,BuyV2CommerceLoadState.ready,reason:h.cart.session.checkoutQuoteMessage);
      await h.startReview(tester,'AI-ACT-342',fields:const {'profileId':'personal'});
      final reads=quote.reads;quote.gate=Completer<void>();
      await tester.tap(find.byKey(const ValueKey('buy-invoice-personal')));await tester.pump();
      expect(quote.reads,reads+1);expect(h.cart.session.checkoutQuoteLoadState,BuyV2CommerceLoadState.loading);
      h.controller!.setDraft('HOST replacement after original quote read');await tester.pump();
      quote.gate!.complete();await tester.pumpAndSettle();
      expect(h.cart.session.checkoutQuote,isNull);expect(h.cart.session.checkoutQuoteLoadState,isNot(BuyV2CommerceLoadState.loading));
      expect(quote.reads,reads+1);expect(h.commerce.requests,isEmpty);expect(await h.review,MoolAssistantReviewResult.stale);
    }finally{if(quote.gate?.isCompleted==false)quote.gate!.complete();await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 042 restores original bank instructions and only native transfer confirmation records a pending claim',(tester)async{
    final h=_Shop04HostHarness();
    try{
      h.cart.owner.initialSnapshot=BuyV2CustomerStateSnapshot(cartQuantities:{'listing-${'d'*64}':1},
        selectedPayment:'Bank transfer',checkoutIdempotencyKey:'HOST-original-bank-attempt',
        paymentReference:'HOST-original-bank-reference',checkoutSubmissionState:'paymentActionRequired',
        bankTransferInstructions:const BuyV2BankTransferInstructions(beneficiaryName:'HOST original beneficiary',
          bankName:'HOST original bank',accountNumber:'000000004821',ifsc:'MOOL0000482',transferReference:'HOST-original-bank-reference'));
      await h.prepare(tester,retainedBank:true);
      expect(h.cart.session.checkoutSubmissionState,BuyV2CheckoutSubmissionState.paymentActionRequired);
      final original=h.cart.session.bankTransferInstructions!,key=h.cart.session.checkoutIdempotencyKey;
      final before=h.effects;
      await h.startReview(tester,'AI-ACT-042',entity:key);
      expect(h.effects,before);expect(find.text(original.accountNumber),findsOneWidget);
      expect(h.cart.session.checkoutSubmissionState,BuyV2CheckoutSubmissionState.paymentActionRequired);
      await tap(tester,find.byKey(const ValueKey('buy-checkout-bank-transfer-sent')));
      expect(h.cart.session.checkoutSubmissionState,BuyV2CheckoutSubmissionState.paymentActionRequired);
      await tap(tester,find.byKey(const ValueKey('buy-checkout-bank-transfer-confirm')));
      expect(h.cart.session.checkoutSubmissionState,BuyV2CheckoutSubmissionState.paymentPending);
      expect(h.cart.session.checkoutIdempotencyKey,key);expect(h.cart.session.paymentReference,original.transferReference);
      expect(h.cart.session.bankTransferInstructions,same(original));expect(h.cart.owner.writes,greaterThan(0));
      expect(h.commerce.requests,isEmpty);expect(h.commerce.reconciled,isEmpty);expect(h.handoffs,0);
      expect(h.cart.session.confirmedOrders,isEmpty);await h.finishReview(tester);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-04 345 uses native reconciled financial closure and preserves already completed supplier orders',(tester)async{
    final quote=_Shop04Quote(),commerce=_Shop04GroupedCommerce();
    quote.groupsFor=(lines,method)=>[for(var i=0;i<lines.length;i++)BuyV2CheckoutPaymentGroup(
      id:'HOST-original-group-$i',fulfilmentKeys:{lines[i].fulfilmentKey},paymentMethod:method,total:lines[i].total,amountDueNow:lines[i].total)];
    final h=_Shop04HostHarness(commerce:commerce,quote:quote);
    try{
      await h.prepare(tester);final session=h.cart.session,first=h.cart.product;
      final secondId='listing-${'e'*64}';
      final second=first.copyWith(id:secondId,storeId:'HOST-second-store',
        publicListingIdentity:BuyV2PublicListingIdentity(listingId:secondId,realm:'evaluation',storeId:'HOST-second-store',
          skuId:'HOST-second-sku',canonicalProductId:first.canonicalId,verifiedPackId:'HOST-second-pack',channel:BuyV2OfferClass.retail),
        packTerms:BuyV2PackTerms(skuId:secondId,revision:'HOST-second-pack-r1',sellUnit:'pack',pricingStoreId:'HOST-second-store',
          priceObservedAt:h.cart.instant.subtract(const Duration(minutes:1)),priceValidUntil:h.cart.instant.add(const Duration(hours:1))));
      h.cart.pages.products[secondId]=second;
      expect(session.addProduct(secondId),isTrue,reason:session.notice);session.openCart();expect(session.openCheckout(),isTrue);
      commerce.snapshot=BuyV2CommerceSnapshot(state:BuyV2CommerceLoadState.ready,products:[first,second],
        addresses:session.addresses,selectedAddressId:session.selectedAddressId,paymentMethods:const {'UPI','Card'},
        paymentCapabilities:[testPaymentCapability(session),testPaymentCapability(session,method:'Card')]);
      await session.restoreCommerce();expect(await session.refreshCheckoutQuote(),isTrue,reason:session.checkoutQuoteMessage);
      expect(session.checkoutQuote!.paymentGroups,hasLength(2));
      await session.submitOrder();expect(commerce.requests,hasLength(1));expect(session.orders,hasLength(1));
      final completed=session.orders.single.id;commerce.fail=true;
      await session.submitOrder();expect(commerce.requests,hasLength(2));
      commerce.close=true;await session.reconcilePayment();
      expect(session.currentCheckoutPaymentGroup!.financiallyClosed,isTrue);await tester.pumpAndSettle();
      final original=session.checkoutPaymentAttempt!,remaining=session.checkoutLines.toList(),before=h.effects;
      await h.startReview(tester,'AI-ACT-345',entity:original.id);
      expect(h.effects,before);expect(session.checkoutPaymentAttempt,same(original));
      await tap(tester,find.widgetWithText(FilledButton,'Review remaining checkout'));
      expect(session.checkoutPaymentAttempt,isNull);expect(session.orders.map((o)=>o.id),contains(completed));
      expect(session.checkoutLines,remaining);expect(commerce.requests,hasLength(2));expect(h.handoffs,0);
      expect(h.cart.owner.lastSnapshot!.retainedCheckoutPaymentAttempts.single.id,original.id);
      expect(h.cart.owner.lastSnapshot!.retainedCheckoutPaymentAttempts.single.groups.last.financiallyClosed,isTrue);
      await h.finishReview(tester);
    }finally{await h.dispose(tester);}
  });

}

// Isolated HOST fixtures only; never installed in the native app/runtime.
class _Shop06StateStore implements BuyV2CustomerStateStore{
  @override final String ownerScope='HOST-shop06-native-state';
  int writes=0;BuyV2CustomerStateSnapshot? saved;
  @override Future<BuyV2CustomerStateSnapshot?> read()async=>saved;
  @override Future<bool> write(BuyV2CustomerStateSnapshot value)async{writes++;saved=value;return true;}
}
class _Shop06Paid extends ChangeNotifier implements MoolAssistantEntitlementSource{
  MoolAssistantAccess access=MoolAssistantAccess.active;
  void revoke(){access=MoolAssistantAccess.revoked;notifyListeners();}
  @override Future<MoolAssistantEntitlement> read(Object account)async=>MoolAssistantEntitlement(
    accountScope:account,access:access,revision:'HOST-shop06-entitlement',validUntil:DateTime.now().add(const Duration(hours:1)));
}
class _Shop06Terms extends TestGroupedPaymentTerms{
  int reads=0;
  bool assigned=true;
  @override Future<BuyV2CommercialPaymentTermsSnapshot> loadTerms({required List<BuyV2FulfilmentGroup> groups,
    required String selectedPaymentMethod,required Map<String,int> quotedTotalsByFulfilmentKey})async{
    reads++;final result=await super.loadTerms(groups:groups,selectedPaymentMethod:selectedPaymentMethod,
      quotedTotalsByFulfilmentKey:quotedTotalsByFulfilmentKey);
    return BuyV2CommercialPaymentTermsSnapshot(state:result.state,terms:result.terms,
      assignedTermIdsByFulfilmentKey:assigned?{for(final term in result.terms)term.fulfilmentKey:term.id}:const {});
  }
}
class _Shop06Po implements BuyV2PurchaseOrderAdapter{
  _Shop06Po(this.account);
  final String account;
  List<BuyV2CartLine> lines=const [];BuyV2Address? address;BuyV2StoreListing? store;
  int reads=0,issues=0,approvals=0,statusReads=0;
  Duration lifetime=const Duration(minutes:10);
  String revision='HOST-po-r1';BuyV2PurchaseOrderState state=BuyV2PurchaseOrderState.draft;
  Completer<void>? readGate,issueGate;bool uncertain=false;
  BuyV2PurchaseOrderReview snapshot()=>BuyV2PurchaseOrderReview(requestId:'HOST-po-original-request',revision:revision,
    buyerAccountId:account,buyerName:'HOST original buyer',address:address,collectionStore:store,
    validUntil:DateTime.now().add(lifetime),documents:[
      BuyV2PurchaseOrderDocument(id:'HOST-po-original-document',revision:'HOST-document-$revision',
        supplierStoreId:lines.first.product.storeId!,supplierName:lines.first.product.seller,state:state,
        lines:[for(final line in lines)BuyV2PurchaseOrderLine(productId:line.product.id,variant:line.product.variant,
          pack:line.product.pack,quantity:line.quantity,unitPriceMinor:line.product.priceMinor)],
        itemSubtotalMinor:lines.fold<int>(0,(total,line)=>total+line.totalMinor),chargesMinor:0,
        totalMinor:lines.fold<int>(0,(total,line)=>total+line.totalMinor),terms:'HOST original supplier terms',
        reference:state==BuyV2PurchaseOrderState.draft?null:'HOST-PO-ORIGINAL',
        decisionMessage:state==BuyV2PurchaseOrderState.revised?'HOST supplier revision needs approval':null),
    ]);
  @override Future<BuyV2PurchaseOrderReview> review({required List<BuyV2CartLine> lines,BuyV2Address? address,BuyV2StoreListing? collectionStore})async{
    reads++;this.lines=List.unmodifiable(lines);this.address=address;store=collectionStore;await readGate?.future;return snapshot();
  }
  @override Future<BuyV2PurchaseOrderReview> issue({required String requestId,required String expectedRevision})async{
    expect(requestId,'HOST-po-original-request');expect(expectedRevision,revision);issues++;await issueGate?.future;
    if(uncertain)throw StateError('HOST original provider status unknown');state=BuyV2PurchaseOrderState.awaitingSupplier;return snapshot();
  }
  @override Future<BuyV2PurchaseOrderReview> approveRevision({required String requestId,required String expectedRevision,
    required String documentId,required String documentRevision})async{
    expect(requestId,'HOST-po-original-request');expect(expectedRevision,revision);
    expect(documentId,'HOST-po-original-document');expect(documentRevision,'HOST-document-$revision');
    expect(state,BuyV2PurchaseOrderState.revised);approvals++;state=BuyV2PurchaseOrderState.accepted;return snapshot();
  }
  @override Future<BuyV2PurchaseOrderReview> refresh({required String requestId})async{
    expect(requestId,'HOST-po-original-request');statusReads++;return snapshot();
  }
}

/// Public test helper so the existing canonical quote-contract test owner can
/// exercise the same real Host route with its already-qualified native source.
class FixtureShop06HostRig{
  FixtureShop06HostRig(this.session,{this.user='HOST-user'});
  final BuyV2Session session;final String user;
  final scope=ValueNotifier<int>(0),navigator=GlobalKey<NavigatorState>();final paid=_Shop06Paid();
  late MoolAssistantContext context=MoolAssistantContext(accountScope:
    (environment:'HOST',projectId:'HOST-project',tenantId:null,userId:user),authenticationRevision:1);
  late final principal=AuthenticatedAccountIdentity(firebaseProjectId:'HOST-project',firebaseUserId:user,displayName:'HOST buyer');
  List<MoolAssistantNativeAdapter> adapters=const [];MoolAssistantController? controller;
  Future<MoolAssistantReviewResult>? review;int adapterReads=0;
  Future<void> mount(WidgetTester tester,{BuyV2View view=BuyV2View.checkout})async{
    await tester.pumpWidget(MaterialApp(navigatorKey:navigator,theme:MoolTheme.light(),
      builder:(_,child)=>MoolAssistantHost(readContext:()=>context,contextChanges:scope,entitlements:paid,child:child!),
      home:MoolAssistantNativeScope(readAdapters:(_){adapterReads++;adapters=buyShop06NativeAdapters(session:session,
        navigator:navigator.currentState!,currentContext:()=>context,isRootCurrent:()=>true,
        scopeOwner:Listenable.merge([scope,session]),accountIdentity:()=>principal,accountAuthenticated:()=>true).toList();return adapters;},
        child:Stack(children:[BuyV2Screen(session:session,initialDestination:session.destination,initialView:view,
          accountIdentity:principal,accountAuthenticated:true),Positioned(top:0,right:0,child:Builder(builder:(context)=>Material(
            child:TextButton(key:const ValueKey('HOST-shop06-open-ai'),onPressed:()=>unawaited(MoolAssistantHost.maybeOf(context)!.open(context)),child:const Text('HOST open AI')))))]))));
    await tester.pumpAndSettle();
  }
  Future<MoolAssistantNativeAdapter> openAI(WidgetTester tester,String action)async{
    await tester.tap(find.byKey(const ValueKey('HOST-shop06-open-ai')));await tester.pumpAndSettle();
    controller=tester.widget<MoolAssistantPage>(find.byType(MoolAssistantPage)).controller;
    await controller!.refreshAccess();controller!.setDraft('HOST supplied purchase request');await tester.pumpAndSettle();
    expect(adapterReads,1);return adapters.singleWhere((value)=>value.actionId==action);
  }
  Future<void> start(WidgetTester tester,String action,{String? entity,Map<String,Object?> fields=const {},Duration? lifetime,bool throughUi=false})async{
    final adapter=await openAI(tester,action),snapshot=await adapter.snapshot(context,entity);
    expect(snapshot,isNotNull,reason:action);
    expect(controller!.receiveProposal(MoolAssistantProposal(id:'HOST-shop06-$action',actionId:action,binding:context.binding,
      requestRevision:controller!.requestRevision,entitlementRevision:controller!.entitlementRevision!,sourceRevision:snapshot!.sourceRevision,
      entityId:entity,validUntil:DateTime.now().add(lifetime??const Duration(minutes:3)),title:'HOST original purchase details',summary:'Use the original native control.',fields:fields)),isTrue);
    if(throughUi){
      await tester.pump();final card=find.byType(MoolAssistantProposalCard);await _shop04RevealNativeControl(tester,card);
      await tester.tap(find.descendant(of:card,matching:find.text('Review')));
    }else{review=controller!.reviewProposal();}
    await tester.pumpAndSettle();
  }
  void retire(){context=MoolAssistantContext(accountScope:context.accountScope,authenticationRevision:2);scope.value++;}
  Future<void> tap(WidgetTester tester,Finder target)async{await _shop04RevealNativeControl(tester,target);expect(target.hitTestable(),findsOneWidget);await tester.tap(target);await tester.pumpAndSettle();}
  Future<void> close(WidgetTester tester)async{await tester.binding.handlePopRoute();await tester.pumpAndSettle();if(review!=null)await review;}
  Future<void> dispose(WidgetTester tester)async{await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();paid.dispose();scope.dispose();}
}

class _Shop06Fixture{
  _Shop06Fixture({this.withPo=false});
  final bool withPo;
  final store=_Shop06StateStore(),commerce=TestPaymentCommerce(),terms=_Shop06Terms(),quote=TestPaymentQuote();
  final po=_Shop06Po('HOST-shop06-owner');
  final identity=ValueNotifier<BuyV2CollectionIdentity?>(const BuyV2CollectionIdentity(accountId:'HOST-shop06-owner',sessionId:'HOST-shop06-session'));
  late final session=BuyV2Session(core:BuySession(),reviewDataEnabled:false,customerStateStore:store,
    collectionIdentity:identity,commerceAdapter:commerce,checkoutQuoteAdapter:quote,commercialPaymentTermsAdapter:terms,
    productFactsAdapter:const QualifiedTestProductFacts({'w-notebook'}),purchaseOrderAdapter:withPo?po:null);
  late final rig=FixtureShop06HostRig(session);
  Object get effects=>(store.writes,commerce.requests.length,terms.reads,po.reads,po.issues,po.approvals,po.statusReads);
  Future<void> prepare(WidgetTester tester)async{
    commerce.snapshot=BuyV2CommerceSnapshot(state:BuyV2CommerceLoadState.ready,products:testPaymentProducts,
      businessVerified:true,paymentMethods:const {'UPI','Card'},addresses:const [BuyV2Address(id:'HOST-shop06-address',kind:BuyV2AddressKind.home,
        label:'HOST supplied Home',recipient:'HOST buyer',phone:'919876543210',line:'HOST exact native address',area:'HOST area',pinCode:'342003',landmark:'')],
      selectedAddressId:'HOST-shop06-address');
    await session.restoreCustomerState();await session.restoreCommerce();
    expect(session.businessVerified,isTrue);
    expect(session.addProduct('w-notebook'),isTrue,reason:session.notice);
    session.openCart(scope:BuyV2CartScope.wholesale);expect(session.openCheckout(),isTrue,reason:session.notice);
    expect(await session.refreshCheckoutQuote(),isTrue,reason:session.checkoutQuoteMessage);
    expect(await session.refreshCommercialPaymentTerms(),isTrue,reason:session.commercialPaymentTermsMessage);
    await rig.mount(tester);expect(session.commercialPaymentTermsLoadState,BuyV2CommerceLoadState.ready);
  }
  Future<void> dispose(WidgetTester tester)async{
    if(po.readGate?.isCompleted==false)po.readGate!.complete();
    if(po.issueGate?.isCompleted==false)po.issueGate!.complete();
    await rig.dispose(tester);session.dispose();session.core.dispose();identity.dispose();
  }
}
void registerShop06NativeHostTests(){
  testWidgets('FE-SHOP-06 032 stages raw Unicode reference and only original Save persists once',(tester)async{
    final h=_Shop06Fixture();try{
      await h.prepare(tester);final before=h.effects,writes=h.store.writes;
      const reference='  PO-\u0aae\u0ac2\u0ab3-\u0928\u092e\u0938\u094d\u0924\u0947 12.50  ';
      await h.rig.start(tester,'AI-ACT-032',fields:const {'reference':reference});
      expect(h.effects,before);expect(h.session.purchaseOrderReference,'');
      final field=find.byKey(const ValueKey('buy-checkout-purchase-order-reference'));
      expect(tester.widget<TextField>(field).controller!.text,reference);
      final save=find.byKey(const ValueKey('buy-checkout-purchase-order-reference-save'));
      final retained=tester.widget<TextButton>(save).onPressed!;retained();retained();await tester.pumpAndSettle();
      expect(h.session.purchaseOrderReference,reference);expect(h.store.saved!.purchaseOrderReference,reference.trim());
      expect(h.store.writes,writes+1);expect(h.commerce.requests,isEmpty);await h.rig.close(tester);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 032 Cancel keeps the original reference and no pending Save',(tester)async{
    final h=_Shop06Fixture();try{
      await h.prepare(tester);final before=h.effects;
      await h.rig.start(tester,'AI-ACT-032',fields:const {'reference':'HOST proposed only'});
      await tester.enterText(find.byKey(const ValueKey('buy-checkout-purchase-order-reference')),'HOST edited but unsaved');
      expect(h.effects,before);await h.rig.close(tester);expect(h.effects,before);expect(h.session.purchaseOrderReference,'');
    }finally{await h.dispose(tester);}
  });
  for(final cause in ['paid','principal']){
    testWidgets('FE-SHOP-06 032 $cause retirement blocks a captured original Save',(tester)async{
      final h=_Shop06Fixture();try{
        await h.prepare(tester);await h.rig.start(tester,'AI-ACT-032',fields:const {'reference':'HOST private proposed reference'});
        final retained=tester.widget<TextButton>(find.byKey(const ValueKey('buy-checkout-purchase-order-reference-save'))).onPressed!;
        final before=h.effects,namespace=h.store.ownerScope;
        if(cause=='paid'){h.rig.paid.revoke();}else{h.rig.retire();}
        await tester.pumpAndSettle();retained();await tester.pump();
        expect(h.effects,before);expect(h.store.ownerScope,namespace);expect(h.session.purchaseOrderReference,'');
        expect(find.text('HOST private proposed reference'),findsNothing);expect(await h.rig.review,MoolAssistantReviewResult.stale);
      }finally{await h.dispose(tester);}
    });
  }
  testWidgets('FE-SHOP-06 032 newer native reference source cannot be overwritten by an older Save',(tester)async{
    final h=_Shop06Fixture();try{
      await h.prepare(tester);await h.rig.start(tester,'AI-ACT-032',fields:const {'reference':'HOST older proposal'});
      final retained=tester.widget<TextButton>(find.byKey(const ValueKey('buy-checkout-purchase-order-reference-save'))).onPressed!;
      h.session.updatePurchaseOrderReference('HOST newer native reference');await tester.pumpAndSettle();final writes=h.store.writes;
      retained();await tester.pump();expect(h.store.writes,writes);
      expect(h.session.purchaseOrderReference,'HOST newer native reference');expect(await h.rig.review,MoolAssistantReviewResult.stale);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 032 retains local dirty native text across a same-owner rebuild without saving',(tester)async{
    final h=_Shop06Fixture();try{
      await h.prepare(tester);final before=h.effects;
      await h.rig.start(tester,'AI-ACT-032',fields:const {'reference':'HOST initial proposal'});
      final field=find.byKey(const ValueKey('buy-checkout-purchase-order-reference'));
      await tester.enterText(field,'HOST user edited native draft');h.rig.scope.value++;await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text,'HOST user edited native draft');
      expect(h.effects,before);expect(h.session.purchaseOrderReference,'');await h.rig.close(tester);expect(h.effects,before);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 032 adds no field to the ordinary approved Checkout presentation',(tester)async{
    final h=_Shop06Fixture();try{
      await h.prepare(tester);expect(find.byType(BuyV2CheckoutView),findsOneWidget);
      expect(find.byKey(const ValueKey('buy-checkout-purchase-order-reference')),findsNothing);
      h.session.updatePurchaseOrderReference('HOST existing native source value');await tester.pumpAndSettle();
      final before=h.effects;await h.rig.start(tester,'AI-ACT-032');
      expect(tester.widget<TextField>(find.byKey(const ValueKey('buy-checkout-purchase-order-reference'))).controller!.text,'HOST existing native source value');
      expect(h.effects,before);await h.rig.close(tester);
    }finally{await h.dispose(tester);}
  });
  for(final action in ['AI-ACT-034','AI-ACT-035']){
    testWidgets('FE-SHOP-06 $action shows actual assigned native terms without accepting or refreshing',(tester)async{
      final h=_Shop06Fixture();try{
        await h.prepare(tester);final group=h.session.checkoutFulfilmentGroups.single;
        final assigned=h.session.supplierAssignedPaymentTermFor(group.key)!;final before=h.effects;
        await h.rig.start(tester,action,entity:group.key);expect(h.effects,before);
        expect(find.byKey(ValueKey('buy-payment-term-summary-${group.key}')),findsOneWidget);
        expect(find.text('Full advance'),findsWidgets);
        expect(h.session.supplierAssignedPaymentTermFor(group.key),same(assigned));await h.rig.close(tester);
      }finally{await h.dispose(tester);}
    });
  }
  testWidgets('FE-SHOP-06 034 never infers assignment from a singleton native option',(tester)async{
    final h=_Shop06Fixture();try{
      await h.prepare(tester);h.terms.assigned=false;await h.session.refreshCommercialPaymentTerms();await tester.pumpAndSettle();
      final group=h.session.checkoutFulfilmentGroups.single;expect(h.session.commercialPaymentTermsFor(group.key),hasLength(1));
      expect(h.session.supplierAssignedPaymentTermFor(group.key),isNull);
      final adapter=await h.rig.openAI(tester,'AI-ACT-034');expect(await adapter.snapshot(h.rig.context,group.key),isNull);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 terms source replacement retires the exact displayed native review',(tester)async{
    final h=_Shop06Fixture();try{
      await h.prepare(tester);final group=h.session.checkoutFulfilmentGroups.single;
      await h.rig.start(tester,'AI-ACT-035',entity:group.key);
      h.terms.credit=true;await h.session.refreshCommercialPaymentTerms();await tester.pumpAndSettle();
      expect(await h.rig.review,MoolAssistantReviewResult.stale);
      expect(find.byKey(ValueKey('buy-payment-term-summary-${group.key}')),findsNothing);expect(h.commerce.requests,isEmpty);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 350 cold original Check prepares only on native tap and returns to actual Checkout owner',(tester)async{
    final h=_Shop06Fixture(withPo:true);try{
      await h.prepare(tester);final before=h.effects;expect(h.session.purchaseOrder!.review,isNull);
      await h.rig.start(tester,'AI-ACT-350',throughUi:true);expect(h.effects,before);expect(h.po.reads,0);
      expect(find.textContaining(h.session.purchaseOrderLines.single.product.customerTitle),findsWidgets);
      expect(find.text('HOST exact native address'),findsWidgets);
      await h.rig.tap(tester,find.byKey(const ValueKey('buy-po-review')));
      expect(h.po.reads,1);expect(h.po.issues,0);expect(h.po.approvals,0);
      expect(h.session.purchaseOrder!.review!.requestId,'HOST-po-original-request');
      expect(find.text('Discard draft'),findsOneWidget);await h.rig.tap(tester,find.text('Discard draft'));
      expect(find.byType(MoolAssistantPage),findsNothing);expect(find.byType(BuyV2CheckoutView),findsOneWidget);
      expect(h.commerce.requests,isEmpty);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 350 original Confirm sends the exact current request revision once',(tester)async{
    final h=_Shop06Fixture(withPo:true);try{
      await h.prepare(tester);expect(await h.session.reviewPurchaseOrder(),isTrue);await tester.pumpAndSettle();
      final original=h.session.purchaseOrder!.review!,before=h.effects;
      await h.rig.start(tester,'AI-ACT-350',entity:original.requestId);expect(h.effects,before);
      final button=find.byKey(const ValueKey('buy-po-issue'));final retained=tester.widget<TextButton>(button).onPressed!;
      retained();retained();await tester.pumpAndSettle();expect(h.po.issues,1);expect(h.po.reads,1);
      expect(h.session.purchaseOrder!.review!.requestId,original.requestId);
      expect(h.session.purchaseOrder!.review!.documents.single.state,BuyV2PurchaseOrderState.awaitingSupplier);
      expect(h.commerce.requests,isEmpty);await h.rig.close(tester);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 351 original revised-document approval preserves request and document revisions',(tester)async{
    final h=_Shop06Fixture(withPo:true);try{
      await h.prepare(tester);expect(await h.session.reviewPurchaseOrder(),isTrue);
      h.po.state=BuyV2PurchaseOrderState.revised;h.po.revision='HOST-po-r2';expect(await h.session.purchaseOrder!.refresh(),isTrue);
      await tester.pumpAndSettle();final original=h.session.purchaseOrder!.review!,doc=h.session.purchaseOrder!.review!.documents.single,before=h.effects;
      await h.rig.start(tester,'AI-ACT-351',entity:doc.id);expect(h.effects,before);
      expect(find.text('HOST supplier revision needs approval'),findsOneWidget);
      await h.rig.tap(tester,find.byKey(ValueKey('buy-po-approve-${doc.id}')));
      expect(h.po.approvals,1);expect(h.po.issues,0);expect(h.session.purchaseOrder!.review!.requestId,original.requestId);
      expect(h.session.purchaseOrder!.review!.documents.single.state,BuyV2PurchaseOrderState.accepted);
      expect(h.commerce.requests,isEmpty);await h.rig.close(tester);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 351 later native revision blocks the captured older approval',(tester)async{
    final h=_Shop06Fixture(withPo:true);try{
      await h.prepare(tester);expect(await h.session.reviewPurchaseOrder(),isTrue);h.po.state=BuyV2PurchaseOrderState.revised;
      h.po.revision='HOST-po-r2';expect(await h.session.purchaseOrder!.refresh(),isTrue);await tester.pumpAndSettle();
      final doc=h.session.purchaseOrder!.review!.documents.single;await h.rig.start(tester,'AI-ACT-351',entity:doc.id);
      final retained=tester.widget<TextButton>(find.byKey(ValueKey('buy-po-approve-${doc.id}'))).onPressed!;
      h.po.revision='HOST-po-r3';expect(await h.session.purchaseOrder!.refresh(),isTrue);await tester.pumpAndSettle();retained();await tester.pump();
      expect(h.po.approvals,0);expect(h.session.purchaseOrder!.review!.revision,'HOST-po-r3');expect(await h.rig.review,MoolAssistantReviewResult.stale);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 exact original PO expiry retires the captured approval before proposal expiry',(tester)async{
    final h=_Shop06Fixture(withPo:true);try{
      await h.prepare(tester);h.po.lifetime=const Duration(seconds:2);expect(await h.session.reviewPurchaseOrder(),isTrue);
      h.po.state=BuyV2PurchaseOrderState.revised;expect(await h.session.purchaseOrder!.refresh(),isTrue);await tester.pumpAndSettle();
      final doc=h.session.purchaseOrder!.review!.documents.single;await h.rig.start(tester,'AI-ACT-351',entity:doc.id,lifetime:const Duration(minutes:1));
      final retained=tester.widget<TextButton>(find.byKey(ValueKey('buy-po-approve-${doc.id}'))).onPressed!;
      await tester.pump(const Duration(seconds:3));await tester.pumpAndSettle();retained();await tester.pump();
      expect(h.po.approvals,0);expect(h.po.issues,0);expect(await h.rig.review,MoolAssistantReviewResult.stale);
      expect(find.byKey(ValueKey('buy-po-approve-${doc.id}')),findsNothing);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 PO consent retirement on native busy notification sends no issue and preserves original draft',(tester)async{
    final h=_Shop06Fixture(withPo:true);var retired=false;
    void retire(){if(!retired && h.session.purchaseOrder!.busy){retired=true;h.rig.paid.revoke();}}
    try{
      await h.prepare(tester);expect(await h.session.reviewPurchaseOrder(),isTrue);await tester.pumpAndSettle();
      final original=h.session.purchaseOrder!.review!;await h.rig.start(tester,'AI-ACT-350',entity:original.requestId);
      h.session.purchaseOrder!.addListener(retire);await h.rig.tap(tester,find.byKey(const ValueKey('buy-po-issue')));
      expect(retired,isTrue);expect(h.po.issues,0);expect(h.session.purchaseOrder!.needsReconciliation,isFalse);
      expect(h.session.purchaseOrder!.busy,isFalse);expect(h.session.purchaseOrder!.review,same(original));expect(await h.rig.review,MoolAssistantReviewResult.stale);
    }finally{h.session.purchaseOrder!.removeListener(retire);await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 dispatched unknown PO retains original recovery after captured request retirement',(tester)async{
    final h=_Shop06Fixture(withPo:true);try{
      await h.prepare(tester);expect(await h.session.reviewPurchaseOrder(),isTrue);await tester.pumpAndSettle();
      final original=h.session.purchaseOrder!.review!;await h.rig.start(tester,'AI-ACT-350',entity:original.requestId);
      h.po.issueGate=Completer<void>();h.po.uncertain=true;
      final retained=tester.widget<TextButton>(find.byKey(const ValueKey('buy-po-issue'))).onPressed!;retained();await tester.pump();
      expect(h.po.issues,1);retained();h.rig.controller!.setDraft('HOST replacement request');await tester.pump();
      h.po.issueGate!.complete();await tester.pumpAndSettle();expect(await h.rig.review,MoolAssistantReviewResult.stale);
      expect(h.po.issues,1);expect(h.po.statusReads,0);expect(h.session.purchaseOrder!.review,same(original));
      expect(h.session.purchaseOrder!.needsReconciliation,isTrue);expect(h.session.purchaseOrder!.busy,isFalse);expect(h.commerce.requests,isEmpty);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 held original PO preparation cannot adopt a changed purchase input',(tester)async{
    final h=_Shop06Fixture(withPo:true);try{
      await h.prepare(tester);await h.rig.start(tester,'AI-ACT-350');h.po.readGate=Completer<void>();
      tester.widget<TextButton>(find.byKey(const ValueKey('buy-po-review'))).onPressed!();await tester.pump();expect(h.po.reads,1);
      h.session.updatePurchaseOrderReference('HOST later native reference');await tester.pump();h.po.readGate!.complete();await tester.pumpAndSettle();
      expect(h.session.purchaseOrder!.review,isNull);expect(h.po.issues,0);expect(h.po.approvals,0);
      expect(h.session.purchaseOrder!.busy,isFalse);expect(await h.rig.review,MoolAssistantReviewResult.stale);
      expect(find.text('Discard draft'),findsNothing);
    }finally{await h.dispose(tester);}
  });
  testWidgets('FE-SHOP-06 original provider absence remains unavailable and unknown payloads are rejected',(tester)async{
    final h=_Shop06Fixture();try{
      await h.prepare(tester);final adapter=await h.rig.openAI(tester,'AI-ACT-350');expect(await adapter.snapshot(h.rig.context,null),isNull);
      expect(adapter.validateFields(const {'approve':true}),isNotNull);
      final reference=h.rig.adapters.singleWhere((a)=>a.actionId=='AI-ACT-032');
      expect(reference.validateFields(const {'reference':'  HOST exact raw  '}),isNull);
      expect(reference.validateFields(const {'reference':null}),isNotNull);expect(reference.validateFields(const {'reference':17}),isNotNull);
      expect(reference.validateFields(const {'reference':'valid','amountMinor':1}),isNotNull);expect(h.po.issues,0);
    }finally{await h.dispose(tester);}
  });
}

// Isolated HOST current-controller qualification; no runtime grants or data.
class _HandoffCurrentBuyer {
  _HandoffCurrentBuyer({required MoolAssistantContext Function() context,required Listenable changes,
    required MoolAssistantNativeAdapter adapter}) {
      controller=MoolAssistantController(currentContext:context,contextChanges:changes,
        entitlements:paid,nativeAdapters:[adapter]);
  }
  final paid=_Shop04Paid();
  late final MoolAssistantController controller;
  Future<Future<MoolAssistantReviewResult> Function()> prepare(MoolAssistantNativeAdapter adapter,
      {String? entity,required Map<String,Object?> fields}) async {
    await controller.refreshAccess();controller.setDraft('HOST review my original supplied input');
    final snapshot=await adapter.snapshot(controller.context,entity);expect(snapshot,isNotNull);
    expect(controller.receiveProposal(MoolAssistantProposal(id:'HOST-real-controller-${adapter.actionId}',actionId:adapter.actionId,
      binding:controller.context.binding,requestRevision:controller.requestRevision,entitlementRevision:controller.entitlementRevision!,
      sourceRevision:snapshot!.sourceRevision,entityId:entity,validUntil:DateTime.now().add(const Duration(minutes:5)),
      title:'Original native input',summary:'HOST only preparation',fields:fields)),isTrue);
    return controller.reviewProposal;
  }
  void retire(String kind){
    switch(kind){
      case 'Cancel':controller.cancelProposal();break;
      case 'request':controller.setDraft('HOST newer request remains');break;
      case 'background':controller.setForeground(false);break;
      case 'access':paid.revoke();break;
    }
  }
  void dispose(){controller.dispose();paid.dispose();}
}

void registerHandoffCurrentBuyerTests(){
  testWidgets('HANDOFF-CURRENT retained original instruction Save cannot mutate beneath an unrelated cover',(tester)async{
    final h=_Shop03ReviewHarness();_HandoffCurrentBuyer? live;
    try{
      await h.mount(tester);final adapter=h.adapter('AI-ACT-030');
      live=_HandoffCurrentBuyer(context:()=>h.context,changes:h.scope,adapter:adapter);
      final start=await live.prepare(adapter,entity:'delivery',fields:{'text':'મૂળ delivery instruction'});
      final future=start();await tester.pumpAndSettle();
      final save=find.byKey(const ValueKey('buy-cart-instruction-save-delivery'));await tester.ensureVisible(save);
      final callback=tester.widget<TextButton>(save).onPressed!;
      final effects=h.session.effects,writes=h.owner.writes,original=h.session.publicDeliveryInstruction;
      unawaited(h.navigator.currentState!.push<void>(MaterialPageRoute(builder:(_)=>const Scaffold(body:Text('HOST unrelated live review cover')))));
      await tester.pumpAndSettle();callback();await tester.pumpAndSettle();
      expect(find.text('HOST unrelated live review cover'),findsOneWidget);expect(h.session.effects,effects);
      expect(h.owner.writes,writes);expect(h.session.publicDeliveryInstruction,original);expect(live.controller.reviewBusy,isTrue);
      h.navigator.currentState!.pop();await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const ValueKey('buy-cart-instruction-note-delivery'))).controller!.text,'મૂળ delivery instruction');
      await tester.tap(find.byKey(const ValueKey('buy-cart-instruction-save-delivery')));await tester.pumpAndSettle();
      expect(h.session.instructions,1);expect(h.session.publicDeliveryInstruction,'મૂળ delivery instruction');
      expect(await future,MoolAssistantReviewResult.opened);expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);live?.dispose();}
  });
  testWidgets('HANDOFF-CURRENT actual controller original Save remains explicit and old manual adapter entry stays usable',(tester)async{
    final h=_Shop03NativeHarness();_HandoffCurrentBuyer? live;
    try{
      await h.mount(tester);final adapter=h.adapter('AI-ACT-025');
      live=_HandoffCurrentBuyer(context:()=>h.context,changes:h.scope,adapter:adapter);
      final start=await live.prepare(adapter,fields:{'recipient':'મૂળ owner','phone':'9876543210','line':'12 Native road','area':'Original locality','pinCode':'342003'});
      final before=h.session.addresses.length,writes=h.owner.writes;final future=start();await tester.pumpAndSettle();
      expect(h.session.addresses.length,before);expect(h.owner.writes,writes);expect(h.session.addressAdds,0);
      final save=find.byKey(const ValueKey('buy-address-add-submit'));
      await tester.scrollUntilVisible(save,180,scrollable:find.descendant(of:find.byKey(const ValueKey('buy-address-add-form-list')),matching:find.byType(Scrollable)).first);
      await tester.pumpAndSettle();await tester.tap(save);await tester.pumpAndSettle();
      expect(await future,MoolAssistantReviewResult.opened);expect(h.session.addressAdds,1);expect(h.session.addresses.length,before+1);
      live.dispose();live=null;
      final manual=await h.open('AI-ACT-025',{'recipient':'Manual original still works'});await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const ValueKey('buy-address-add-recipient'))).controller!.text,'Manual original still works');
      await tester.tap(find.byKey(const ValueKey('buy-address-add-form-close')));await tester.pumpAndSettle();
      expect(await manual.future,MoolAssistantReviewResult.opened);expect(h.session.addressAdds,1);expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);live?.dispose();}
  });
  for(final kind in ['Cancel','request','background','access']){
    testWidgets('HANDOFF-CURRENT original address form immediately hides private input on actual controller $kind',(tester) async {
      final h=_Shop03NativeHarness();_HandoffCurrentBuyer? live;
      try{
        await h.mount(tester);final adapter=h.adapter('AI-ACT-025');
        live=_HandoffCurrentBuyer(context:()=>h.context,changes:h.scope,adapter:adapter);
        final start=await live.prepare(adapter,fields:{'recipient':'મૂળ private owner','phone':'9876543210',
          'line':'12 Native road','area':'Original locality','pinCode':'342003'});
        final future=start();await tester.pumpAndSettle();
        final field=find.byKey(const ValueKey('buy-address-add-recipient'));
        expect(tester.widget<TextField>(field).controller!.text,'મૂળ private owner');
        final retained=tester.widget<TextField>(field).controller!;
        final save=find.byKey(const ValueKey('buy-address-add-submit'));await tester.ensureVisible(save);
        final callback=tester.widget<FilledButton>(save).onPressed!;
        final before=h.owner.writes;live.retire(kind);await tester.pumpAndSettle();
        expect(field,findsNothing);expect(find.byKey(const ValueKey('buy-address-add-submit')),findsNothing);
        expect(retained.text,'મૂળ private owner');callback();await tester.pumpAndSettle();
        expect(h.owner.writes,before);expect(h.session.addressAdds,0);
        await tester.tap(find.byKey(const ValueKey('buy-address-add-form-close')));await tester.pumpAndSettle();
        expect(await future,MoolAssistantReviewResult.stale);
        if(kind=='request')expect(live.controller.draft,'HOST newer request remains');
        expect(tester.takeException(),isNull);
      }finally{await h.dispose(tester);live?.dispose();}
    });
  }
  for(final kind in ['Cancel','request','background','access']){
    testWidgets('HANDOFF-CURRENT original instructions retire through actual controller $kind without popping a cover',(tester) async {
      final h=_Shop03ReviewHarness();_HandoffCurrentBuyer? live;
      try{
        await h.mount(tester);final adapter=h.adapter('AI-ACT-030');
        live=_HandoffCurrentBuyer(context:()=>h.context,changes:h.scope,adapter:adapter);
        final start=await live.prepare(adapter,entity:'delivery',fields:{'text':'મૂળ delivery instruction'});
        final future=start();await tester.pumpAndSettle();
        final note=find.byKey(const ValueKey('buy-cart-instruction-note-delivery'));
        expect(tester.widget<TextField>(note).controller!.text,'મૂળ delivery instruction');
        final save=find.byKey(const ValueKey('buy-cart-instruction-save-delivery'));await tester.ensureVisible(save);
        final callback=tester.widget<TextButton>(save).onPressed!;
        final effects=h.session.effects,writes=h.owner.writes;
        unawaited(h.navigator.currentState!.push<void>(MaterialPageRoute(builder:(_)=>const Scaffold(body:Text('HOST unrelated instruction cover')))));
        await tester.pumpAndSettle();live.retire(kind);await tester.pumpAndSettle();callback();await tester.pumpAndSettle();
        expect(find.text('HOST unrelated instruction cover'),findsOneWidget);expect(note,findsNothing);
        expect(h.session.effects,effects);expect(h.owner.writes,writes);expect(await future,MoolAssistantReviewResult.stale);
        expect(tester.takeException(),isNull);
      }finally{await h.dispose(tester);live?.dispose();}
    });
  }
  for(final kind in ['Cancel','request','background','access']){
    testWidgets('HANDOFF-CURRENT original quantity retires through actual controller $kind with no Cart write',(tester) async {
      final h=_CartNativeHarness();_HandoffCurrentBuyer? live;
      try{
        await h.mount(tester);final adapter=h.adapter('AI-ACT-014');
        live=_HandoffCurrentBuyer(context:()=>h.context,changes:h.scope,adapter:adapter);
        final start=await live.prepare(adapter,entity:h.product.id,fields:{'quantity':3});
        final future=start();await tester.pumpAndSettle();
        expect(tester.widget<TextField>(find.byKey(const ValueKey('buy-quantity-input'))).controller!.text,'3');
        final callback=tester.widget<FilledButton>(find.byKey(const ValueKey('buy-quantity-save'))).onPressed!;
        final effects=h.session.effects,writes=h.owner.writes;live.retire(kind);await tester.pumpAndSettle();
        callback();await tester.pumpAndSettle();expect(find.byKey(const ValueKey('buy-quantity-input')),findsNothing);
        expect(h.session.effects,effects);expect(h.owner.writes,writes);expect(h.session.quantityFor(h.product.id),0);
        expect(await future,MoolAssistantReviewResult.stale);expect(tester.takeException(),isNull);
      }finally{await h.dispose(tester);live?.dispose();}
    });
  }
}

// Isolated HOST records; never runtime providers or live business outcomes.
class _Shop05Delivery implements BuyV2DeliveryExceptionAdapter {
  bool proof=false,loseAck=false,available=true;String id='HOST-exception-original';int loads=0,changes=0;
  Completer<BuyV2DeliveryExceptionSnapshot>? gate;
  BuyV2DeliveryExceptionSnapshot snapshot({bool submitted=false})=>!available
    ?const BuyV2DeliveryExceptionSnapshot(state:BuyV2CommerceLoadState.unavailable,customerMessage:'HOST original source unavailable')
    :BuyV2DeliveryExceptionSnapshot(
    state:BuyV2CommerceLoadState.ready,customerMessage:'HOST original delivery facts',exceptionId:id,
    kind:proof?(submitted?BuyV2DeliveryExceptionKind.proofOfDeliveryDisputed:BuyV2DeliveryExceptionKind.proofOfDeliveryAvailable):
      submitted?BuyV2DeliveryExceptionKind.dispatchDelayed:BuyV2DeliveryExceptionKind.rescheduleAvailable,
    headline:'HOST verified delivery update',detail:'HOST original exception',rescheduleSlots:proof||submitted?const []:const ['Tomorrow · 10–12','Tomorrow · 14–16'],
    proofReference:proof?'HOST original proof':null);
  @override Future<BuyV2DeliveryExceptionSnapshot> loadException({required String orderId})async{loads++;return snapshot();}
  Future<BuyV2DeliveryExceptionSnapshot> submit()async{changes++;if(loseAck)throw StateError('HOST acknowledgement lost');return gate==null?snapshot(submitted:true):await gate!.future;}
  @override Future<BuyV2DeliveryExceptionSnapshot> rescheduleDelivery({required String orderId,required String exceptionId,required String slot})async{
    expect(exceptionId,id);expect(snapshot().rescheduleSlots,contains(slot));return submit();}
  @override Future<BuyV2DeliveryExceptionSnapshot> disputeProofOfDelivery({required String orderId,required String exceptionId,required String proofReference})async{
    expect(exceptionId,id);expect(proofReference,'HOST original proof');return submit();}
}
class _Shop05Resolution implements BuyV2OrderResolutionAdapter,BuyV2ReplacementConsentAdapter {
  int loads=0,sends=0,replacements=0;BuyV2OrderResolutionRequest? last;BuyV2ReplacementConsentRequest? replacement;bool loseAck=false;
  @override Future<BuyV2OrderResolutionSnapshot> load(BuyV2Order order)async{loads++;return BuyV2OrderResolutionSnapshot(
    orderId:order.id,state:BuyV2OrderResolutionState.ready,sourceId:'HOST original policy source',
    options:const [BuyV2OrderResolutionOption(kind:BuyV2OrderResolutionKind.cancel,title:'Cancel order',detail:'HOST supplied option',reasons:['Changed mind','Incorrect item'])]);}
  @override Future<BuyV2OrderResolutionResult> submit(BuyV2OrderResolutionRequest request)async{sends++;last=request;
    if(loseAck)throw StateError('HOST request acknowledgement lost');return const BuyV2OrderResolutionResult(accepted:true,reference:'HOST original request',customerMessage:'HOST request recorded');}
  @override Future<BuyV2ReplacementConsentResult> decideReplacement(BuyV2ReplacementConsentRequest request)async{
    replacements++;replacement=request;return BuyV2ReplacementConsentResult(request:request,recorded:true,reference:'HOST recorded original choice');}
}
class _Shop05Harness extends _Shop04HostHarness {
  _Shop05Harness({required _Shop05Delivery delivery,required _Shop05Resolution resolution,BuyV2Order Function(BuyV2Product)? orderFactory,
    BuyV2BalancePaymentAdapter? balance,ScanPickGateway? collection,BuyV2CollectionPendingStore? pending,AuthenticatedWorkspaceOrderIdentityGateway? reader,BuyV2CollectionCameraBuilder? camera}):
    super(shop05:true,delivery:delivery,resolution:resolution,shop05Order:orderFactory,balance:balance,collection:collection,pending:pending,reader:reader,shop05Camera:camera,
      shop05Principal:reader==null?null:AuthenticatedAccountIdentity(firebaseProjectId:'HOST-project',firebaseUserId:reader.accountUserId)){
      if(reader!=null)cart.context=MoolAssistantContext(accountScope:(environment:'HOST',projectId:'HOST-project',tenantId:null,userId:reader.accountUserId),authenticationRevision:1);
    }
  Future<void> ready(WidgetTester tester)async{await prepare(tester,savedOrder:true,view:BuyV2View.tracking);}
}
BuyV2Order _shop05Order(BuyV2Product p,{bool replacement=false,bool collection=false,bool balance=false,bool confirmed=false,String id='HOST-shop04-order',String purchase='HOST-shop04-purchase'})=>BuyV2Order.minor(
  id:id,purchaseId:purchase,destination:BuyV2Destination.shop,title:'HOST original order',itemSummary:'1 purchased item',totalMinor:p.priceMinor,
  partner:'HOST original Store',partnerType:'Retailer',promise:'HOST original delivery',destinationLabel:'HOST original destination',progress:1,
  status:collection||confirmed?BuyV2OrderStatus.confirmed:BuyV2OrderStatus.delivered,productIds:[p.id],lines:[BuyV2CartLine(product:p,quantity:1)],paymentMethod:'UPI',
  amountPaidNowMinor:balance?0:p.priceMinor,balanceDueMinor:balance?p.priceMinor:0,balanceDueLabel:balance?'At delivery':null,
  collection:collection?const BuyV2CollectionOrderReference(storeId:'HOST-native-store',purchaserAccountId:'HOST-cart-owner'):null,
  supplyProgress:replacement?BuyV2OrderSupplyProgress(orderId:id,purchaseId:purchase,sourceId:'HOST original supply',revision:1,state:BuyV2SupplyState.replacementOffered,
    lines:[BuyV2SupplyLine(productId:p.id,variant:p.variant,pack:p.pack,orderedQuantity:1,availableQuantity:0,unavailableQuantity:1)],
    replacementOffer:BuyV2ReplacementOffer(id:'HOST replacement original',revision:1,lines:[BuyV2ReplacementLine(originalProductId:p.id,originalVariant:p.variant,
      originalPack:p.pack,originalQuantity:1,productTitle:'HOST proposed replacement',pack:p.pack,quantity:1,unitPriceMinor:p.priceMinor)],
      customerTotalMinor:p.priceMinor,deliveryCommitment:'HOST tomorrow',expiresAt:DateTime.now().add(const Duration(hours:1)))):null);
class _Shop05Balance implements BuyV2BalancePaymentAdapter,BuyV2MinorBalancePaymentAdapter {
  int amount=0,starts=0,checks=0;int? receivedAmount;String? key;Completer<void>? entered,gate;
  BuyV2BalancePaymentResult result(BuyV2BalancePaymentState state)=>BuyV2BalancePaymentResult.minor(state:state,amountDueMinor:state==BuyV2BalancePaymentState.paid?0:amount,
    dueLabel:'At delivery',customerMessage:'HOST original balance',paymentReference:state==BuyV2BalancePaymentState.due?null:'HOST original balance reference',
    paymentActionUri:state==BuyV2BalancePaymentState.paymentActionRequired?Uri.https('payments.example.test','/HOST-original-balance'):null);
  @override Future<BuyV2BalancePaymentResult> loadBalance({required String orderId})async=>result(BuyV2BalancePaymentState.due);
  @override Future<BuyV2BalancePaymentResult> startPayment({required String orderId,required int amountDue,required String idempotencyKey})=>startPaymentMinor(orderId:orderId,amountDueMinor:amountDue*100,idempotencyKey:idempotencyKey);
  @override Future<BuyV2BalancePaymentResult> startPaymentMinor({required String orderId,required int amountDueMinor,required String idempotencyKey})async{
    starts++;receivedAmount=amountDueMinor;key=idempotencyKey;entered?.complete();await gate?.future;return result(BuyV2BalancePaymentState.paymentActionRequired);}
  @override Future<BuyV2BalancePaymentResult> reconcilePayment({required String orderId,required String paymentReference})async{checks++;expect(paymentReference,'HOST original balance reference');return result(BuyV2BalancePaymentState.paid);}
}
class _Shop05CollectionPending implements BuyV2CollectionPendingStore {
  BuyV2CollectionPendingIntent? value;int writes=0;
  @override Future<BuyV2CollectionPendingIntent?> read({required String accountId,required String orderId,required String storeId})async=>value;
  @override Future<bool> reserve(BuyV2CollectionPendingIntent intent)async{if(value!=null)return false;writes++;value=intent;return true;}
  @override Future<bool> clear(BuyV2CollectionPendingIntent original)async{if(value?.operationId!=original.operationId)return false;value=null;return true;}
}
class _Shop05Collection implements ScanPickGateway {
  _Shop05Collection(this.pending);final _Shop05CollectionPending pending;final requests=<ScanPickRequest>[];BuyV2Product? product;bool matched=false;
  String? observedRequestOperation,observedRetainedOperation;
  @override Future<ScanPickResult> execute(ScanPickRequest request)async{
    requests.add(request);if(request.operation==ScanPickOperation.authorise){observedRequestOperation=request.operationId;observedRetainedOperation=pending.value?.operationId;matched=true;}
    final now=DateTime.now().toUtc(),expires=now.add(const Duration(minutes:5));
    return ScanPickResult.fromJson({'protocolVersion':scanPickProtocolVersion,'requestId':request.requestId,'operation':request.operation.name,
      if(request.operationId!=null)'operationId':request.operationId,'outcome':'snapshot','snapshot':{
        'purpose':scanPickPurpose,'orderId':request.orderId,'storeId':request.storeId,'purchaserAccountId':'HOST-cart-owner','customerName':'HOST buyer','storeName':'HOST supplied Store',
        'revision':matched?'HOST approved revision':'HOST ready revision','serverTime':now.toIso8601String(),'state':matched?'matched':'awaitingCustomer','payment':'paid','readiness':'ready',
        'currency':'INR','totalMinor':product!.priceMinor,'lines':[{'lineId':'HOST-original-line','productId':product!.id,'skuId':'HOST-cart-sku','name':product!.customerTitle,
          'pack':product!.pack,'quantity':'1','amountMinor':product!.priceMinor}],
        if(!matched)'challenge':{'id':'HOST original challenge','expiresAt':expires.toIso8601String()},
        if(matched)'approval':{'id':'HOST original approval','expiresAt':expires.toIso8601String()},
      }});
  }
}
class _Shop05Stars {
  final wire=host_stars.Transport();
  late final reader=host_stars.projectionGateway(wire);
  late Map<String,dynamic> purchase,page,target;
  int sends=0;bool loseAck=false;
  BuyV2Order order(BuyV2Product p){
    final supplied=p.publicListingIdentity!;
    final listingId='listing-${sha256.convert(utf8.encode(jsonEncode([1,supplied.realm,supplied.storeId,supplied.skuId,supplied.channel.name])))}';
    p=p.copyWith(id:listingId,publicListingIdentity:BuyV2PublicListingIdentity(listingId:listingId,
      realm:supplied.realm,storeId:supplied.storeId,skuId:supplied.skuId,
      canonicalProductId:supplied.canonicalProductId,verifiedPackId:supplied.verifiedPackId,channel:supplied.channel));
    purchase=host_stars.publicListingPurchaseResponse();final row=purchase['orders'][0] as Map<String,dynamic>;
    final line=row['original']['lines'][0] as Map<String,dynamic>;
    line.addAll({'skuId':p.publicListingIdentity!.skuId,'canonicalProductId':p.canonicalId,'verifiedPackId':p.publicListingIdentity!.verifiedPackId,
      'publicListing':p.publicListingIdentity!.toJson(),'scheduledFulfilment':null,'name':p.customerTitle,'packLabel':p.pack,
      'variant':p.variant,'unitPriceMinor':p.priceMinor,'lineTotalMinor':p.priceMinor});
    row['original']['benefitAttribution']={'schemaVersion':1,'components':<Object>[]};
    row['storeId']=p.storeId;row['original']['totals']={'itemsMinor':p.priceMinor,'discountMinor':0,'taxMinor':0,'deliveryMinor':0,'freightMinor':0,'paymentFeeMinor':0,'tipMinor':0,'totalMinor':p.priceMinor};
    host_stars.rehashPurchaseOrder(row);page=host_stars.feedbackTargetPage(purchase:purchase);target=page['targets'][0];
    wire.respond=(body){switch(body['operation']){
      case 'readBuyerPurchaseProjection':return purchase;
      case 'listBuyerProductFeedbackTargets':return page;
      case 'readBuyerProductFeedbackTarget':return Map<String,dynamic>.from(page)..remove('coverage')..remove('targets')..remove('nextCursor')..['target']=target;
      case 'readBuyerProductStars':return {'schemaVersion':1,'realm':'evaluation','authNamespace':'firebase-default','viewerRole':'buyer','viewerUserId':'buyer-1','targetId':target['id'],'rating':null};
      case 'submitBuyerProductStars':sends++;if(loseAck)throw StateError('HOST lost original rating acknowledgement');return host_stars.starResult()
        ..['operationId']=body['operationId']..['rating']['stars']=body['stars']..['rating']['target']=target;
      case 'reconcileBuyerProductStars':return host_stars.starResult()..['operationId']=body['operationId']..['state']='not_recorded'..['rating']=null;
      default:throw StateError('Unexpected HOST stars operation');
    }};
    return _shop05Order(p,id:row['orderId'],purchase:purchase['purchaseId']);
  }
  Future<void> load(_Shop05Harness h)async{
    final projection=await reader.readPurchaseProjection(role:WorkspaceOrderIdentityRole.buyer,realm:'evaluation',purchaseId:purchase['purchaseId']);expect(projection,isNotNull);
    final restored=AuthenticatedWorkspaceOrderOperationsGateway(reader).restoreProductFeedbackTarget(target,realm:'evaluation');expect(restored,isNotNull);
    expect(await h.cart.session.loadPrivateStarsFor(restored!.reference,projection!.orders.single.lines.single),isTrue);
  }
}
Future<void> _shop05Reveal(WidgetTester tester,Finder finder)async{
  if(finder.evaluate().isEmpty){final list=find.byType(ListView).last;
    final scroll=find.descendant(of:list,matching:find.byType(Scrollable)).last;
    await tester.scrollUntilVisible(finder,160,scrollable:scroll,maxScrolls:30);}
  expect(finder,findsOneWidget);await tester.ensureVisible(finder);await tester.pump();
}
class _PublicFeedbackCommerce extends _Shop04Commerce implements BuyV2VerifiedRatingAdapter {
  final reports=<(BuyV2Product,String)>[];
  int reviewSends=0;
  bool loseAck=false;
  Completer<BuyV2MutationResult>? reportGate;
  @override Future<BuyV2RatingResult> submitRating(BuyV2RatingRequest request)async{
    reviewSends++;return const BuyV2RatingResult(customerMessage:'HOST unexpected review send');
  }
  @override Future<BuyV2MutationResult> reportProduct({required BuyV2Product product,required String reason})async{
    reports.add((product,reason));
    if(reportGate!=null)return reportGate!.future;
    if(loseAck)throw StateError('HOST report acknowledgement unavailable');
    return const BuyV2MutationResult(accepted:true,customerMessage:'HOST original report received');
  }
}
bool _eightHostFontsLoaded=false;
Future<void> _loadEightHostFonts(WidgetTester tester) async {
  if(const String.fromEnvironment('MOOL_AI_EIGHT_CAPTURE_DIR').isEmpty||_eightHostFontsLoaded)return;
  await tester.runAsync(() async {
    final font=FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await font.load();
  });
  _eightHostFontsLoaded=true;
}

Future<void> _captureEightHost(WidgetTester tester,Finder target,String name) async {
  const folder=String.fromEnvironment('MOOL_AI_EIGHT_CAPTURE_DIR');
  if(folder.isEmpty)return;
  expect(target,findsOneWidget);
  RenderObject boundary=tester.element(target).findRenderObject()!;
  while(!boundary.isRepaintBoundary){final parent=boundary.parent;if(parent==null)throw StateError('No painted capture boundary');boundary=parent;}
  final layer=boundary.debugLayer;
  if(layer is! OffsetLayer||boundary.debugNeedsPaint)throw StateError('Native HOST frame is not ready for capture');
  final image=(await tester.runAsync(()=>layer.toImage(boundary.paintBounds,pixelRatio:1)))!;
  try {await tester.runAsync(() async {
    final png=await image.toByteData(format:ImageByteFormat.png);
    final directory=Directory(folder);await directory.create(recursive:true);
    final file=File('${directory.path}/$name.png');if(await file.exists())throw StateError('Preserve prior HOST capture');
    await file.writeAsBytes(png!.buffer.asUint8List(),flush:true);
  });}finally{image.dispose();}
}

class _PublicFeedbackHost extends _Shop04HostHarness {
  _PublicFeedbackHost():super(commerce:_PublicFeedbackCommerce(),shop05:true);
  _PublicFeedbackCommerce get feedback=>commerce as _PublicFeedbackCommerce;
  late BuyV2RatingTarget target;
  Future<void> ready(WidgetTester tester,{bool reviewTarget=true,bool reporting=true,
      BuyV2Destination destination=BuyV2Destination.shop,bool restoreExistingCustomerState=false})async{
    await prepare(tester,savedOrder:true,view:BuyV2View.tracking,destination:destination,retainedBank:restoreExistingCustomerState);
    final p=cart.product,base=feedback.snapshot;
    target=BuyV2RatingTarget(id:'HOST-text-review-original',ownerScope:cart.session.reviewDraftOwnerScope!,
      orderId:order!.id,orderLineId:'HOST-authorized-purchased-line',storeId:p.storeId!,productId:p.id,
      purchaseLabel:'HOST original delivered purchase',purchasedListing:p.publicListingIdentity);
    feedback.snapshot=BuyV2CommerceSnapshot(state:BuyV2CommerceLoadState.ready,products:base.products,
      addresses:base.addresses,selectedAddressId:base.selectedAddressId,orders:[order!],
      paymentMethods:base.paymentMethods,businessVerified:base.businessVerified,
      ratingTargets:[if(reviewTarget)target],productReportsAvailable:reporting);
    await cart.session.restoreCommerce();await tester.pumpAndSettle();
  }
  Map<String,Object?> fields(String action)=>action=='AI-ACT-054'
    ?{'targetId':target.id,'stars':4,'comment':'મૂળ review · अच्छा product'}
    :{'reason':'મૂળ pack label गलत है'};
  Future<void> begin(WidgetTester tester,String action,{Duration lifetime=const Duration(minutes:3)})async{
    final adapter=await openAI(tester,action),snapshot=await adapters.singleWhere((a)=>a.actionId==action).snapshot(cart.context,cart.product.id);
    expect(snapshot,isNotNull);
    expect(controller!.receiveProposal(MoolAssistantProposal(id:'HOST-public-feedback-$action',actionId:action,
      binding:cart.context.binding,requestRevision:controller!.requestRevision,entitlementRevision:controller!.entitlementRevision!,
      sourceRevision:snapshot!.sourceRevision,entityId:cart.product.id,validUntil:DateTime.now().add(lifetime),
      title:'Review product feedback',summary:'Use the exact original listing.',fields:fields(action))),isTrue);
    await tester.pumpAndSettle();
    final review=find.descendant(of:find.byType(MoolAssistantProposalCard),matching:find.widgetWithText(FilledButton,'Review'));
    await _shop04RevealNativeControl(tester,review);await tester.pumpAndSettle();
    expect(review.hitTestable(),findsOneWidget);await tester.tap(review);await tester.pumpAndSettle();
    expect(adapter.actionId,action);
  }
  @override Future<void> dispose(WidgetTester tester)async{
    if(feedback.reportGate?.isCompleted==false)feedback.reportGate!.complete(
      const BuyV2MutationResult(accepted:false,customerMessage:'HOST unknown result kept'));
    await super.dispose(tester);
  }
}
Future<void> _revealPublicFeedbackControl(WidgetTester tester,Finder control)async{
  final form=find.byType(BuyProductFeedbackPage);
  final scroll=find.descendant(of:form,matching:find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(control,120,maxScrolls:30,scrollable:scroll);
  await tester.pumpAndSettle();await tester.ensureVisible(control);await tester.pumpAndSettle();
  expect(control.hitTestable(),findsOneWidget);
}
Future<void> _openManualPublicReview(WidgetTester tester,_PublicFeedbackHost h)async{
  unawaited(showBuyV2ProductFeedback(h.cart.navigator.currentContext!,session:h.cart.session,
    product:h.cart.product,report:false));await tester.pumpAndSettle();
  expect(find.byType(BuyProductFeedbackPage),findsOneWidget);
}
Future<void> _tapReviewDraft(WidgetTester tester,String label)async{
  final control=find.widgetWithText(TextButton,label).evaluate().isNotEmpty?
    find.widgetWithText(TextButton,label):find.widgetWithText(FilledButton,label);
  expect(control,findsOneWidget);await tester.tap(control);await tester.pumpAndSettle();
}
void registerPublicReviewDraftRecoveryTests(){
  testWidgets('AI-SHOP05 054 native user edits Back Save draft reopens exact original purchase',(tester)async{
    final h=_PublicFeedbackHost();try{
      await h.ready(tester);await h.begin(tester,'AI-ACT-054');final baseline=h.cart.owner.writes;
      expect(h.cart.session.productReviewDraft(h.cart.product.id,targetId:h.target.id),isNull);
      await tester.enterText(find.byKey(const ValueKey('buy-product-text-review-comment')),'मेरा edited review');
      await tester.tap(find.byType(BackButton).last);await tester.pumpAndSettle();
      expect(h.cart.owner.writes,baseline);await _tapReviewDraft(tester,'Save draft');
      expect(find.byType(BuyProductFeedbackPage),findsNothing);
      expect(h.cart.session.productReviewDraft(h.cart.product.id,targetId:h.target.id)?.comment,'मेरा edited review');
      await _openManualPublicReview(tester,h);
      expect(tester.widget<TextField>(find.byKey(const ValueKey('buy-product-text-review-comment'))).controller!.text,'मेरा edited review');
      expect(tester.widget<FilledButton>(find.byKey(const ValueKey('buy-product-text-review-send'))).onPressed,isNull);
      expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
  for(final choice in ['Keep editing','Discard changes']){
    testWidgets('AI-SHOP05 054 dirty Back $choice never retains AI preparation',(tester)async{
      final h=_PublicFeedbackHost();try{
        await h.ready(tester);await h.begin(tester,'AI-ACT-054');final before=h.cart.owner.writes;
        await tester.enterText(find.byKey(const ValueKey('buy-product-text-review-comment')),'Unsaved edited review');
        await tester.tap(find.byType(BackButton).last);await tester.pumpAndSettle();await _tapReviewDraft(tester,choice);
        expect(find.byType(BuyProductFeedbackPage),choice=='Keep editing'?findsOneWidget:findsNothing);
        expect(h.cart.owner.writes,before);expect(h.cart.session.productReviewDraft(h.cart.product.id,targetId:h.target.id),isNull);
        expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
      }finally{await h.dispose(tester);}
    });
  }
  testWidgets('AI-SHOP05 054 explicit Save draft waits original failed writer and keeps input for retry',(tester)async{
    final h=_PublicFeedbackHost();try{
      await h.ready(tester);await h.begin(tester,'AI-ACT-054');
      await tester.enterText(find.byKey(const ValueKey('buy-product-text-review-comment')),'Retain this edited review');
      h.cart.owner.rejectWrites=true;
      var save=find.byKey(const ValueKey('buy-product-review-save-draft'));await _revealPublicFeedbackControl(tester,save);
      await tester.tap(save);await tester.pumpAndSettle();
      expect(find.text('Draft save is not confirmed. Keep this review and try again.'),findsOneWidget);
      expect(find.byType(BuyProductFeedbackPage),findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const ValueKey('buy-product-text-review-comment'))).controller!.text,'Retain this edited review');
      h.cart.owner.rejectWrites=false;await tester.tap(save);await tester.pumpAndSettle();
      if(find.text('Replace saved draft?').evaluate().isNotEmpty)await _tapReviewDraft(tester,'Replace draft');
      expect(find.text('Draft saved.'),findsOneWidget);expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
  for(final replace in [false,true]){
    testWidgets('AI-SHOP05 054 AI proposal existing draft replacement requires explicit ${replace?'confirm':'cancel'}',(tester)async{
      final h=_PublicFeedbackHost();try{
        await h.ready(tester);expect(await h.cart.session.retainProductReviewDraft(productId:h.cart.product.id,
          rating:2,comment:'Original saved text',ownerScope:h.cart.session.reviewDraftOwnerScope,targetId:h.target.id,
          feedbackContext:h.cart.session.productFeedbackContext),isTrue);
        await h.begin(tester,'AI-ACT-054');final before=h.cart.owner.writes;
        await tester.enterText(find.byKey(const ValueKey('buy-product-text-review-comment')),'Edited AI proposal');
        final save=find.byKey(const ValueKey('buy-product-review-save-draft'));await _revealPublicFeedbackControl(tester,save);
        await tester.tap(save);await tester.pumpAndSettle();expect(h.cart.owner.writes,before);
        await _tapReviewDraft(tester,replace?'Replace draft':'Keep editing');
        expect(h.cart.session.productReviewDraft(h.cart.product.id,targetId:h.target.id)?.comment,
          replace?'Edited AI proposal':'Original saved text');expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
      }finally{await h.dispose(tester);}
    });
  }
  testWidgets('AI-SHOP05 054 replacement rechecks changed retained draft before original write',(tester)async{
    final h=_PublicFeedbackHost();try{
      await h.ready(tester);Future<bool> keep(String text)=>h.cart.session.retainProductReviewDraft(productId:h.cart.product.id,
        rating:3,comment:text,ownerScope:h.cart.session.reviewDraftOwnerScope,targetId:h.target.id,
        feedbackContext:h.cart.session.productFeedbackContext);
      expect(await keep('First retained draft'),isTrue);await h.begin(tester,'AI-ACT-054');
      await tester.enterText(find.byKey(const ValueKey('buy-product-text-review-comment')),'My replacement');
      final save=find.byKey(const ValueKey('buy-product-review-save-draft'));await _revealPublicFeedbackControl(tester,save);
      await tester.tap(save);await tester.pumpAndSettle();expect(await keep('Newer separate edit'),isTrue);
      final before=h.cart.owner.writes;await _tapReviewDraft(tester,'Replace draft');
      expect(h.cart.owner.writes,before);expect(h.cart.session.productReviewDraft(h.cart.product.id,targetId:h.target.id)?.comment,'Newer separate edit');
      expect(find.byType(BuyProductFeedbackPage),findsOneWidget);expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
  for(final cause in ['actor','source','covered','disposed']){
    testWidgets('AI-SHOP05 054 retained Save draft callback refuses $cause',(tester)async{
      final h=_PublicFeedbackHost();try{
        await h.ready(tester);await h.begin(tester,'AI-ACT-054');
        await tester.enterText(find.byKey(const ValueKey('buy-product-text-review-comment')),'Private edited text');
        final save=find.byKey(const ValueKey('buy-product-review-save-draft'));await _revealPublicFeedbackControl(tester,save);
        final callback=tester.widget<OutlinedButton>(save).onPressed!;final before=h.cart.owner.writes;
        if(cause=='actor')h.retire();
        else if(cause=='source'){h.cart.session.updateQuery('HOST original source changed');}
        else if(cause=='covered'){unawaited(h.cart.navigator.currentState!.push<void>(MaterialPageRoute(builder:(_)=>const Scaffold(body:Text('HOST foreign cover')))));}
        else await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();callback();await tester.pumpAndSettle();
        expect(h.cart.owner.writes,before);expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
      }finally{await h.dispose(tester);}
    });
  }
  for(final cause in ['actor','source']){
    testWidgets('AI-SHOP05 054 private draft decision retires without saving on $cause change',(tester)async{
      final h=_PublicFeedbackHost();try{
        await h.ready(tester);await h.begin(tester,'AI-ACT-054');
        await tester.enterText(find.byKey(const ValueKey('buy-product-text-review-comment')),'Private unsaved decision');
        await tester.tap(find.byType(BackButton).last);await tester.pumpAndSettle();
        final callback=tester.widget<FilledButton>(find.widgetWithText(FilledButton,'Save draft')).onPressed!;
        final before=h.cart.owner.writes;
        if(cause=='actor')h.retire();else{h.cart.session.updateQuery('HOST original source changed');}
        await tester.pumpAndSettle();expect(find.text('Keep your review?'),findsNothing);
        expect(find.byType(BuyProductFeedbackPage),findsNothing);callback();await tester.pumpAndSettle();
        expect(h.cart.owner.writes,before);expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
      }finally{await h.dispose(tester);}
    });
  }
  testWidgets('AI-SHOP05 054 unchanged AI preparation is not auto saved but supports explicit native Save',(tester)async{
    final h=_PublicFeedbackHost();try{
      await h.ready(tester);await h.begin(tester,'AI-ACT-054');final before=h.cart.owner.writes;
      expect(h.cart.session.productReviewDraft(h.cart.product.id,targetId:h.target.id),isNull);
      final save=find.byKey(const ValueKey('buy-product-review-save-draft'));await _revealPublicFeedbackControl(tester,save);
      expect(h.cart.owner.writes,before);expect(tester.widget<OutlinedButton>(save).onPressed,isNotNull);
      await tester.tap(save);await tester.pumpAndSettle();
      expect(h.cart.session.productReviewDraft(h.cart.product.id,targetId:h.target.id)?.comment,h.fields('AI-ACT-054')['comment']);
      expect(find.text('Draft saved.'),findsOneWidget);expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
  testWidgets('AI-SHOP05 054 retained first decision callback cannot target a later decision',(tester)async{
    final h=_PublicFeedbackHost();try{
      await h.ready(tester);await h.begin(tester,'AI-ACT-054');
      await tester.enterText(find.byKey(const ValueKey('buy-product-text-review-comment')),'Private edited review');
      await tester.tap(find.byType(BackButton).last);await tester.pumpAndSettle();
      final retained=tester.widget<FilledButton>(find.widgetWithText(FilledButton,'Save draft')).onPressed!;
      await _tapReviewDraft(tester,'Keep editing');await tester.tap(find.byType(BackButton).last);await tester.pumpAndSettle();
      final before=h.cart.owner.writes;retained();await tester.pumpAndSettle();
      expect(find.text('Keep your review?'),findsOneWidget);expect(h.cart.owner.writes,before);
      await _tapReviewDraft(tester,'Discard changes');expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
  for(final retired in [false,true]){
    testWidgets('AI-SHOP05 054 held original draft writer ${retired?'retires private UI':'waits for actual ACK'}',(tester)async{
      final h=_PublicFeedbackHost();final gate=Completer<void>();try{
        await h.ready(tester);await h.begin(tester,'AI-ACT-054');
        final save=find.byKey(const ValueKey('buy-product-review-save-draft'));await _revealPublicFeedbackControl(tester,save);
        h.cart.owner.writeGate=gate;await tester.tap(save);await tester.pump();
        expect(find.text('Draft saved.'),findsNothing);expect(find.byType(BuyProductFeedbackPage),findsOneWidget);
        expect(tester.widget<OutlinedButton>(save).onPressed,isNull);
        if(retired){h.retire();await tester.pumpAndSettle();expect(find.byType(BuyProductFeedbackPage),findsNothing);}
        gate.complete();await tester.pumpAndSettle();
        expect(find.text('Draft saved.'),retired?findsNothing:findsOneWidget);
        if(retired)expect(find.byType(BuyProductFeedbackPage),findsNothing);
        expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
      }finally{if(!gate.isCompleted)gate.complete();await h.dispose(tester);}
    });
  }
  testWidgets('AI-SHOP05 054 actor retirement before first decision frame removes only owned prompt',(tester)async{
    final h=_PublicFeedbackHost();try{
      await h.ready(tester);await h.begin(tester,'AI-ACT-054');
      await tester.enterText(find.byKey(const ValueKey('buy-product-text-review-comment')),'Private pre-frame edit');
      final before=h.cart.owner.writes;await tester.tap(find.byType(BackButton).last);
      h.retire();await tester.pumpAndSettle();
      expect(find.byType(BuyProductFeedbackPage,skipOffstage:false),findsNothing);
      expect(find.text('Keep your review?',skipOffstage:false),findsNothing);
      expect(h.cart.owner.writes,before);expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
  testWidgets('AI-SHOP05 054 existing draft writer remains synchronous for ignored callers and isolates target owner',(tester)async{
    final h=_PublicFeedbackHost();try{
      await h.ready(tester);final owner=h.cart.session.reviewDraftOwnerScope,scope=h.cart.session.productFeedbackContext;
      final write=h.cart.session.retainProductReviewDraft(productId:h.cart.product.id,rating:3,comment:'Exact target text',ownerScope:owner,targetId:h.target.id,feedbackContext:scope);
      expect(h.cart.session.productReviewDraft(h.cart.product.id,targetId:h.target.id)?.comment,'Exact target text');expect(await write,isTrue);
      expect(h.cart.session.productReviewDraft(h.cart.product.id,targetId:'unrelated-target'),isNull);
      expect(await h.cart.session.retainProductReviewDraft(productId:h.cart.product.id,rating:5,comment:'Wrong owner',ownerScope:'another-owner',targetId:h.target.id,feedbackContext:scope),isFalse);
      expect(h.cart.session.productReviewDraft(h.cart.product.id,targetId:h.target.id)?.comment,'Exact target text');
      final gate=Completer<void>();h.cart.owner.writeGate=gate;
      final pending=h.cart.session.retainProductReviewDraft(productId:h.cart.product.id,rating:4,comment:'Original owner pending',ownerScope:owner,targetId:h.target.id,feedbackContext:scope);
      h.cart.owner.ownerScope='HOST-other-owner';gate.complete();expect(await pending,isFalse);
      expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
}

void registerPublicProductFeedbackTests(){
  test('AI-SHOP05 feedback scalars preserve exact target and reject invented fields',(){
    for(final fields in <Map<String,Object?>>[{'targetId':'x','stars':0,'comment':'text'},
      {'targetId':'x','stars':4,'comment':'text','published':true},{'stars':4,'comment':'text'}]){
      expect(()=>BuyProductFeedbackInitialData.fromFields('AI-ACT-054',fields),throwsFormatException);
    }
    expect(()=>BuyProductFeedbackInitialData.fromFields('AI-ACT-056',{'reason':'  '}),throwsFormatException);
    expect(()=>BuyProductFeedbackInitialData.fromFields('AI-ACT-056',{'reason':'text','reportId':'invented'}),throwsFormatException);
    expect(BuyProductFeedbackInitialData.fromFields('AI-ACT-056',{'reason':' મૂળ कारण '}).reason,' મૂળ कारण ');
  });
  for(final action in ['AI-ACT-054','AI-ACT-056']){
    for(final scale in [1.0,2.0]){
      testWidgets('AI-SHOP05 $action actual prepared form narrow text$scale cancels without writes',(tester)async{
        await _loadEightHostFonts(tester);
        tester.view.devicePixelRatio=1;tester.view.physicalSize=const Size(320,568);
        tester.platformDispatcher.textScaleFactorTestValue=scale;
        addTearDown((){tester.view.reset();tester.platformDispatcher.clearTextScaleFactorTestValue();});
        final h=_PublicFeedbackHost();try{
          await h.ready(tester);final writes=h.cart.owner.writes;await h.begin(tester,action);
          expect(find.byType(BuyProductFeedbackPage),findsOneWidget);
          final input=find.byKey(ValueKey(action=='AI-ACT-054'?'buy-product-text-review-comment':'buy-product-report-reason'));
          await _revealPublicFeedbackControl(tester,input);
          expect(tester.widget<TextField>(input).controller!.text,action=='AI-ACT-054'?h.fields(action)['comment']:h.fields(action)['reason']);
          if(action=='AI-ACT-054'){
            expect(find.text(h.target.purchaseLabel),findsOneWidget);
            final send=find.byKey(const ValueKey('buy-product-text-review-send'));await _revealPublicFeedbackControl(tester,send);
            expect(tester.widget<FilledButton>(send).onPressed,isNull,
              reason:'Public text review has no durable unknown attempt contract; preparation is not effect readiness.');
          }
          expect(h.feedback.reports,isEmpty);expect(h.feedback.reviewSends,0);expect(h.cart.owner.writes,writes);
          await _captureEightHost(tester,find.byType(BuyProductFeedbackPage),'HOST-$action-feedback-scale$scale');
          expect(tester.takeException(),isNull);await tester.pageBack();await tester.pumpAndSettle();
          expect(find.byType(BuyProductFeedbackPage),findsNothing);expect(h.cart.owner.writes,writes);
        }finally{await h.dispose(tester);}
      });
    }
    for(final cause in ['actor ABA','paid','request','expiry','source ABA','covered']){
      testWidgets('AI-SHOP05 $action $cause retires or covers exact native form and retained Send cannot dispatch',(tester)async{
        final h=_PublicFeedbackHost();try{
          await h.ready(tester);final writes=h.cart.owner.writes;
          await h.begin(tester,action,lifetime:cause=='expiry'?const Duration(seconds:5):const Duration(minutes:3));
          final send=find.byKey(ValueKey(action=='AI-ACT-054'?'buy-product-text-review-send':'buy-product-report-send'));
          await _revealPublicFeedbackControl(tester,send);final callback=tester.widget<FilledButton>(send).onPressed;
          Route<void>? cover;
          if(cause=='actor ABA'){final original=h.cart.context;h.retire();await tester.pump();h.cart.context=original;h.cart.scope.value++;}
          if(cause=='paid'){h.paid.revoke();await h.controller!.refreshAccess();}
          if(cause=='request')h.controller!.setDraft('A different task');
          if(cause=='expiry')await tester.pump(const Duration(seconds:6));
          if(cause=='source ABA'){final q=h.cart.session.query;h.cart.session.updateQuery('changed original source');await tester.pump();h.cart.session.updateQuery(q);}
          if(cause=='covered'){
            cover=MaterialPageRoute<void>(builder:(_)=>const Scaffold(body:Text('HOST unrelated feedback cover')));
            unawaited(h.cart.navigator.currentState!.push(cover));
          }
          await tester.pumpAndSettle();callback?.call();await tester.pumpAndSettle();
          if(cover!=null)expect(cover.isCurrent,isTrue);else{
            expect(find.byType(BuyProductFeedbackPage,skipOffstage:false),findsNothing);
            expect(find.text('મૂળ pack label गलत है',skipOffstage:false),findsNothing);
          }
          expect(h.feedback.reports,isEmpty);expect(h.feedback.reviewSends,0);expect(h.cart.owner.writes,writes);
          expect(tester.takeException(),isNull);
        }finally{await h.dispose(tester);}
      });
    }
  }
  for(final cause in ['missing product','missing review target','reporting unavailable','wrong review target']){
    testWidgets('AI-SHOP05 feedback $cause never opens a blank claimed handoff',(tester)async{
      final h=_PublicFeedbackHost();try{
        await h.ready(tester,reviewTarget:cause!='missing review target',reporting:cause!='reporting unavailable');
        final action=cause=='reporting unavailable'?'AI-ACT-056':'AI-ACT-054';
        final adapter=await h.openAI(tester,action);
        final snapshot=await adapter.snapshot(h.cart.context,cause=='missing product'?'missing-product':h.cart.product.id);
        if(cause=='wrong review target'){
          expect(snapshot,isNotNull);
          final p=MoolAssistantProposal(id:'HOST-wrong-feedback-target',actionId:action,binding:h.cart.context.binding,
            requestRevision:h.controller!.requestRevision,entitlementRevision:h.controller!.entitlementRevision!,
            sourceRevision:snapshot!.sourceRevision,entityId:h.cart.product.id,validUntil:DateTime.now().add(const Duration(minutes:3)),
            title:'Review product',summary:'Use original purchase',fields:{...h.fields(action),'targetId':'different-original'});
          expect(h.controller!.receiveProposal(p),isTrue);expect(await h.controller!.reviewProposal(),MoolAssistantReviewResult.unavailable);
        }else expect(snapshot,isNull);
        expect(find.byType(BuyProductFeedbackPage),findsNothing);expect(h.feedback.reports,isEmpty);expect(h.feedback.reviewSends,0);
      }finally{await h.dispose(tester);}
    });
  }
  for(final destination in [BuyV2Destination.shop,BuyV2Destination.wholesale]){
    testWidgets('AI-SHOP05 product report final once sends exact original listing and reason $destination',(tester)async{
      final h=_PublicFeedbackHost();try{
        await h.ready(tester,destination:destination);await h.begin(tester,'AI-ACT-056');
        final send=find.byKey(const ValueKey('buy-product-report-send'));await _revealPublicFeedbackControl(tester,send);
        final retained=tester.widget<FilledButton>(send).onPressed!;h.feedback.reportGate=Completer<BuyV2MutationResult>();
        await tester.tap(send);retained();await tester.pump();
        expect(h.feedback.reports,hasLength(1));expect(h.feedback.reports.single.$1,same(h.cart.product));
        expect(h.feedback.reports.single.$2,h.fields('AI-ACT-056')['reason']);
        h.feedback.reportGate!.complete(const BuyV2MutationResult(accepted:true,customerMessage:'HOST authoritative report acknowledgement'));
        await tester.pumpAndSettle();expect(find.text('HOST authoritative report acknowledgement'),findsOneWidget);
        retained();await tester.pumpAndSettle();expect(h.feedback.reports,hasLength(1));expect(h.cart.session.hasReportedProduct(h.cart.product.id),isTrue);
        expect(tester.widget<FilledButton>(send).onPressed,isNull);expect(tester.takeException(),isNull);
      }finally{await h.dispose(tester);}
    });
  }
  testWidgets('AI-SHOP05 report unknown survives original form reopen and never resends',(tester)async{
    final h=_PublicFeedbackHost();try{
      await h.ready(tester);h.feedback.loseAck=true;await h.begin(tester,'AI-ACT-056');
      final send=find.byKey(const ValueKey('buy-product-report-send'));await _revealPublicFeedbackControl(tester,send);
      await tester.tap(send);await tester.pumpAndSettle();
      expect(h.feedback.reports,hasLength(1));expect(h.cart.session.canReportProduct(h.cart.product.id),isFalse);
      expect(h.cart.session.productReportRetentionMessage(h.cart.product.id),contains('not confirmed'));
      await tester.pageBack();await tester.pumpAndSettle();
      final context=tester.element(find.byType(MoolAssistantPage));
      unawaited(showBuyV2ProductFeedback(context,session:h.cart.session,product:h.cart.product,report:true));await tester.pumpAndSettle();
      final reopened=find.byKey(const ValueKey('buy-product-report-send'));await _revealPublicFeedbackControl(tester,reopened);
      expect(tester.widget<FilledButton>(reopened).onPressed,isNull);expect(h.feedback.reports,hasLength(1));
      expect(find.textContaining('not confirmed'),findsWidgets);
      expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
  testWidgets('AI-SHOP05 synchronous actor retirement after report notification prevents native dispatch',(tester)async{
    final h=_PublicFeedbackHost();try{
      await h.ready(tester);await h.begin(tester,'AI-ACT-056');var changed=false;
      void retire(){if(!changed&&h.cart.session.productFeedbackBusy(h.cart.product.id)){changed=true;h.retire();}}
      h.cart.session.addListener(retire);
      final send=find.byKey(const ValueKey('buy-product-report-send'));await _revealPublicFeedbackControl(tester,send);
      await tester.tap(send);await tester.pumpAndSettle();h.cart.session.removeListener(retire);
      expect(changed,isTrue);expect(h.feedback.reports,isEmpty);expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
  testWidgets('AI-SHOP05 unknown report original saved journal blocks resend after reconstructed Session',(tester)async{
    final first=_PublicFeedbackHost();BuyV2CustomerStateSnapshot? original;
    try{
      await first.ready(tester);first.feedback.loseAck=true;await first.begin(tester,'AI-ACT-056');
      final send=find.byKey(const ValueKey('buy-product-report-send'));await _revealPublicFeedbackControl(tester,send);
      await tester.tap(send);await tester.pumpAndSettle();original=first.cart.owner.lastSnapshot;
      expect(original,isNotNull);expect(first.feedback.reports,hasLength(1));
    }finally{await first.dispose(tester);}
    final next=_PublicFeedbackHost();try{
      next.cart.owner.initialSnapshot=original;await next.ready(tester,restoreExistingCustomerState:true);
      expect(next.cart.session.canReportProduct(next.cart.product.id),isFalse);
      expect(next.cart.session.productReportRetentionMessage(next.cart.product.id),contains('not confirmed'));
      final adapter=await next.openAI(tester,'AI-ACT-056');
      expect(await adapter.snapshot(next.cart.context,next.cart.product.id),isNull);
      expect(next.feedback.reports,isEmpty);expect(find.byType(BuyProductFeedbackPage),findsNothing);
    }finally{await next.dispose(tester);}
  });
  for(final action in ['AI-ACT-054','AI-ACT-056']){
    for(final cause in ['disposed','covered']){
      testWidgets('AI-SHOP05 $action retained edit callbacks after $cause cannot change native input',(tester)async{
        final h=_PublicFeedbackHost();try{
          await h.ready(tester);await h.begin(tester,action);
          final input=find.byKey(ValueKey(action=='AI-ACT-054'?'buy-product-text-review-comment':'buy-product-report-reason'));
          await _revealPublicFeedbackControl(tester,input);final edit=tester.widget<TextField>(input).onChanged!;
          final star=action=='AI-ACT-054'?tester.widget<IconButton>(find.byKey(const ValueKey('buy-text-review-star-1'))).onPressed:null;
          Route<void>? cover;
          if(cause=='disposed'){await tester.pageBack();await tester.pumpAndSettle();}
          else{cover=MaterialPageRoute<void>(builder:(_)=>const Scaffold(body:Text('HOST other edit surface')));
            unawaited(h.cart.navigator.currentState!.push(cover));await tester.pumpAndSettle();}
          edit('stale retained value');star?.call();await tester.pumpAndSettle();
          if(cover!=null){expect(cover.isCurrent,isTrue);h.cart.navigator.currentState!.pop();await tester.pumpAndSettle();
            expect(tester.widget<TextField>(input).controller!.text,action=='AI-ACT-054'?h.fields(action)['comment']:h.fields(action)['reason']);
            if(action=='AI-ACT-054')expect(tester.widget<Icon>(find.descendant(of:find.byKey(const ValueKey('buy-text-review-star-4')),
              matching:find.byType(Icon))).icon,Icons.star_rounded);
          }
          expect(h.feedback.reports,isEmpty);expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
        }finally{await h.dispose(tester);}
      });
    }
  }
  testWidgets('AI-SHOP05 retained original purchase dropdown rejects covered and disposed edits',(tester)async{
    final h=_PublicFeedbackHost();try{
      await h.ready(tester);final p=h.cart.product,base=h.feedback.snapshot;
      final second=BuyV2RatingTarget(id:'HOST-second-original-target',ownerScope:h.target.ownerScope,
        orderId:h.target.orderId,orderLineId:'HOST-second-line',storeId:p.storeId!,productId:p.id,
        purchaseLabel:'HOST second delivered purchase',purchasedListing:p.publicListingIdentity);
      h.feedback.snapshot=BuyV2CommerceSnapshot(state:BuyV2CommerceLoadState.ready,products:base.products,
        addresses:base.addresses,orders:base.orders,paymentMethods:base.paymentMethods,ratingTargets:[h.target,second]);
      await h.cart.session.restoreCommerce();await tester.pumpAndSettle();
      final context=tester.element(find.byType(BuyV2Screen));
      unawaited(showBuyV2ProductFeedback(context,session:h.cart.session,product:p,report:false));await tester.pumpAndSettle();
      final dropdown=find.byType(DropdownButtonFormField<BuyV2RatingTarget>);
      expect(dropdown,findsOneWidget);final edit=tester.widget<DropdownButtonFormField<BuyV2RatingTarget>>(dropdown).onChanged!;
      final cover=MaterialPageRoute<void>(builder:(_)=>const Scaffold(body:Text('HOST other dropdown surface')));
      unawaited(h.cart.navigator.currentState!.push(cover));await tester.pumpAndSettle();edit(second);await tester.pumpAndSettle();
      expect(cover.isCurrent,isTrue);h.cart.navigator.currentState!.pop();await tester.pumpAndSettle();
      expect(dropdown,findsOneWidget,reason:'A covered callback cannot select another original purchase.');
      await tester.pageBack();await tester.pumpAndSettle();edit(second);await tester.pumpAndSettle();
      expect(h.feedback.reviewSends,0);expect(tester.takeException(),isNull);
    }finally{await h.dispose(tester);}
  });
  for(final cause in ['request','source']){
    testWidgets('AI-SHOP05 held original pending persistence $cause change blocks endpoint dispatch',(tester)async{
      final h=_PublicFeedbackHost();try{
        await h.ready(tester);await h.begin(tester,'AI-ACT-056');
        h.cart.owner.writeGate=Completer<void>();
        final send=find.byKey(const ValueKey('buy-product-report-send'));await _revealPublicFeedbackControl(tester,send);
        final retained=tester.widget<FilledButton>(send).onPressed!;
        await tester.tap(send);await tester.pump();expect(h.cart.session.productFeedbackBusy(h.cart.product.id),isTrue);
        expect(h.feedback.reports,isEmpty);
        if(cause=='request')h.controller!.setDraft('Another request');else h.cart.session.updateQuery('Different current source');
        await tester.pump();retained();h.cart.owner.writeGate!.complete();
        for(var i=0;i<20&&h.cart.session.productFeedbackBusy(h.cart.product.id);i++)await tester.pump();
        await tester.pumpAndSettle();expect(h.feedback.reports,isEmpty);
        expect(h.cart.session.productReportRetentionMessage(h.cart.product.id),isNull,
          reason:'This exact attempt was not sent; native unsent cleanup must not create an unknown report.');
        expect(tester.takeException(),isNull);
      }finally{if(h.cart.owner.writeGate?.isCompleted==false)h.cart.owner.writeGate!.complete();await h.dispose(tester);}
    });
  }
  for(final cause in ['request','paid']){
    testWidgets('AI-SHOP05 already issued report keeps exact acknowledgement after $cause retirement',(tester)async{
      final h=_PublicFeedbackHost();try{
        await h.ready(tester);await h.begin(tester,'AI-ACT-056');h.feedback.reportGate=Completer<BuyV2MutationResult>();
        final send=find.byKey(const ValueKey('buy-product-report-send'));await _revealPublicFeedbackControl(tester,send);
        await tester.tap(send);await tester.pumpAndSettle();expect(h.feedback.reports,hasLength(1));
        if(cause=='request')h.controller!.setDraft('Another request');else{h.paid.revoke();await h.controller!.refreshAccess();}
        await tester.pumpAndSettle();expect(find.byType(BuyProductFeedbackPage,skipOffstage:false),findsNothing);
        h.feedback.reportGate!.complete(const BuyV2MutationResult(accepted:true,customerMessage:'HOST original late report acknowledgement'));
        await tester.pumpAndSettle();expect(h.feedback.reports,hasLength(1));
        expect(h.cart.session.hasReportedProduct(h.cart.product.id),isTrue,
          reason:'Retiring the AI UI does not erase an already-issued original report acknowledgement.');
        expect(tester.takeException(),isNull);
      }finally{await h.dispose(tester);}
    });
  }
}

void registerShop05NativeTests(){
  testWidgets('AI-SHOP05 052 Continue uses original retained action and never starts a second payment',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution(),balance=_Shop05Balance();
    final h=_Shop05Harness(delivery:delivery,resolution:resolution,balance:balance,orderFactory:(p){balance.amount=p.priceMinor;return _shop05Order(p,balance:true);});
    await h.ready(tester);await h.cart.session.restoreBalancePayment(h.order!.id);expect(await h.cart.session.startBalancePayment(h.order!.id),isTrue);final key=balance.key;
    await h.startReview(tester,'AI-ACT-052',entity:h.order!.id);expect(h.handoffs,0);
    final control=find.byKey(const ValueKey('buy-tracking-balance-continue-payment'));await _shop05Reveal(tester,control);await tester.tap(control);await tester.pumpAndSettle();
    expect(balance.starts,1);expect(balance.receivedAmount,balance.amount);expect(balance.key,key);expect(h.handoffs,1);expect(h.cart.session.balancePaymentFor(h.order!.id)?.state,BuyV2BalancePaymentState.paymentPending);
    await h.finishReview(tester);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 052 Check preserves native paid status and its exact retained original attempt',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution(),balance=_Shop05Balance();
    final h=_Shop05Harness(delivery:delivery,resolution:resolution,balance:balance,orderFactory:(p){balance.amount=p.priceMinor;return _shop05Order(p,balance:true);});
    await h.ready(tester);await h.cart.session.restoreBalancePayment(h.order!.id);await h.cart.session.startBalancePayment(h.order!.id);
    await h.cart.session.continueBalancePayment(h.order!.id,(_)async=>false);
    final retainedHold=h.cart.owner.lastSnapshot!.balancePaymentHolds.single.toJson();
    await h.startReview(tester,'AI-ACT-052',entity:h.order!.id);
    expect(balance.checks,0);final control=find.byKey(const ValueKey('buy-tracking-balance-check-payment'));await _shop05Reveal(tester,control);await tester.tap(control);await tester.pumpAndSettle();
    expect(balance.starts,1);expect(balance.checks,1);expect(h.cart.session.balancePaymentFor(h.order!.id)?.state,BuyV2BalancePaymentState.paid);
    expect(h.cart.owner.lastSnapshot!.balancePaymentHolds.single.toJson(),retainedHold);
    expect(balance.receivedAmount,balance.amount);await h.finishReview(tester);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 055 original purchased SKU receives proposed private stars and native Send once',(tester)async{
    final stars=_Shop05Stars(),delivery=_Shop05Delivery(),resolution=_Shop05Resolution();
    final h=_Shop05Harness(delivery:delivery,resolution:resolution,reader:stars.reader,orderFactory:stars.order);
    await h.ready(tester);await stars.load(h);final before=stars.wire.calls,writes=h.cart.owner.writes;
    await h.startReview(tester,'AI-ACT-055',entity:h.order!.id,fields:{'lineId':stars.target['orderLineId'],'stars':4});
    expect(find.byKey(const ValueKey('buy-product-review-sheet')),findsOneWidget);expect(stars.sends,0);expect(h.cart.owner.writes,writes);
    expect(stars.wire.calls,before+1,reason:'Only the existing authenticated original is re-read; no feedback save is dispatched.');
    final control=find.byKey(const ValueKey('buy-submit-private-stars'));await _shop05Reveal(tester,control);
    final callback=tester.widget<ButtonStyleButton>(control).onPressed!;callback();callback();await tester.pumpAndSettle();
    expect(stars.sends,1);expect(h.cart.session.privateStarRating(stars.target['id'])!.stars,4);expect(h.cart.owner.lastSnapshot!.productStarAttempts,isEmpty);
    await h.finishReview(tester);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 055 original unconfirmed rating remains recoverable without sending another value',(tester)async{
    final stars=_Shop05Stars()..loseAck=true,delivery=_Shop05Delivery(),resolution=_Shop05Resolution();
    final h=_Shop05Harness(delivery:delivery,resolution:resolution,reader:stars.reader,orderFactory:stars.order);await h.ready(tester);await stars.load(h);
    await h.startReview(tester,'AI-ACT-055',entity:h.order!.id,fields:{'lineId':stars.target['orderLineId'],'stars':3});
    final control=find.byKey(const ValueKey('buy-submit-private-stars'));await _shop05Reveal(tester,control);await tester.tap(control);await tester.pumpAndSettle();
    expect(stars.sends,1);expect(h.cart.session.privateStarAttempt(stars.target['id'])!.stars,3);expect(h.cart.owner.lastSnapshot!.productStarAttempts,isNotEmpty);
    await h.finishReview(tester);expect(stars.sends,1);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 055 cancellation during original rating write prevents remote dispatch',(tester)async{
    final stars=_Shop05Stars(),delivery=_Shop05Delivery(),resolution=_Shop05Resolution();
    final h=_Shop05Harness(delivery:delivery,resolution:resolution,reader:stars.reader,orderFactory:stars.order);await h.ready(tester);await stars.load(h);
    await h.startReview(tester,'AI-ACT-055',entity:h.order!.id,fields:{'lineId':stars.target['orderLineId'],'stars':2});
    final control=find.byKey(const ValueKey('buy-submit-private-stars'));await _shop05Reveal(tester,control);
    final gate=Completer<void>(),entered=Completer<void>();h.cart.owner.writeGate=gate;h.cart.owner.writeEntered=entered;
    await tester.tap(control);await tester.pump();await entered.future;h.controller!.cancelProposal();gate.complete();await tester.pumpAndSettle();
    expect(stars.sends,0);expect(h.cart.owner.lastSnapshot!.productStarAttempts,isNotEmpty);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 049 populated replacement opens original sheet and native Accept sends exact offer',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution();final h=_Shop05Harness(delivery:delivery,resolution:resolution,orderFactory:(p)=>_shop05Order(p,replacement:true));
    await h.ready(tester);expect(h.cart.session.orderSupplyProgressFor(h.order!.id),isNotNull);
    final before=h.effects;await h.startReview(tester,'AI-ACT-049',entity:h.order!.id);
    expect(find.text('HOST proposed replacement'),findsOneWidget);expect(h.effects,before);expect(resolution.replacements,0);
    final control=find.byKey(const ValueKey('buy-accept-replacement'));await _shop05Reveal(tester,control);
    final callback=tester.widget<ButtonStyleButton>(control).onPressed!;callback();callback();await tester.pumpAndSettle();
    expect(resolution.replacements,1);expect(resolution.replacement!.offerId,'HOST replacement original');expect(resolution.replacement!.accept,isTrue);
    expect(h.cart.session.replacementConsentResult(h.order!.id)?.recorded,isTrue);await h.finishReview(tester);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 049 expired captured replacement cannot send a retained choice',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution();final h=_Shop05Harness(delivery:delivery,resolution:resolution,orderFactory:(p)=>_shop05Order(p,replacement:true));
    await h.ready(tester);await h.startReview(tester,'AI-ACT-049',entity:h.order!.id);
    final control=find.byKey(const ValueKey('buy-decline-replacement'));await _shop05Reveal(tester,control);final callback=tester.widget<ButtonStyleButton>(control).onPressed!;
    h.paid.revoke();await tester.pumpAndSettle();callback();await tester.pumpAndSettle();expect(resolution.replacements,0);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 052 original balance native Pay preserves paise and original retained hold',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution(),balance=_Shop05Balance();
    final h=_Shop05Harness(delivery:delivery,resolution:resolution,balance:balance,orderFactory:(p){balance.amount=p.priceMinor;return _shop05Order(p,balance:true);});
    await h.ready(tester);expect(await h.cart.session.restoreBalancePayment(h.order!.id),isTrue);
    final before=h.effects;await h.startReview(tester,'AI-ACT-052',entity:h.order!.id);expect(balance.starts,0);expect(h.effects,before);
    final control=find.byKey(const ValueKey('buy-tracking-balance-pay-balance'));await _shop05Reveal(tester,control);
    final callback=tester.widget<ButtonStyleButton>(control).onPressed!;callback();callback();await tester.pumpAndSettle();
    expect(balance.starts,1);expect(balance.receivedAmount,balance.amount);expect(balance.key,isNotEmpty);expect(h.cart.owner.lastSnapshot!.balancePaymentHolds,isNotEmpty);
    expect(h.cart.session.balancePaymentFor(h.order!.id)?.state,BuyV2BalancePaymentState.paymentActionRequired);expect(h.handoffs,0);
    await h.finishReview(tester);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 052 owner retirement during retained hold write prevents payment dispatch',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution(),balance=_Shop05Balance();
    final h=_Shop05Harness(delivery:delivery,resolution:resolution,balance:balance,orderFactory:(p){balance.amount=p.priceMinor;return _shop05Order(p,balance:true);});
    await h.ready(tester);await h.cart.session.restoreBalancePayment(h.order!.id);await h.startReview(tester,'AI-ACT-052',entity:h.order!.id);
    final control=find.byKey(const ValueKey('buy-tracking-balance-pay-balance'));await _shop05Reveal(tester,control);
    final gate=Completer<void>(),entered=Completer<void>();h.cart.owner.writeGate=gate;h.cart.owner.writeEntered=entered;
    await tester.tap(control);await tester.pump();await entered.future;h.controller!.cancelProposal();gate.complete();await tester.pumpAndSettle();
    expect(balance.starts,0);expect(h.cart.owner.lastSnapshot!.balancePaymentHolds,isNotEmpty);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 053 native scanner retains actual original and authorises only supplied scan',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution(),pending=_Shop05CollectionPending();final collection=_Shop05Collection(pending);
    ValueChanged<String>? detected;
    final h=_Shop05Harness(delivery:delivery,resolution:resolution,collection:collection,pending:pending,
      orderFactory:(p){collection.product=p;return _shop05Order(p,collection:true);},camera:(context,callback){detected=callback;return const SizedBox(key:ValueKey('HOST-original-collection-camera'),height:80);});
    await h.ready(tester);expect(await h.cart.session.refreshCollectionOrder(h.order!.id),isTrue);
    final reads=collection.requests.length;await h.startReview(tester,'AI-ACT-053',entity:h.order!.id);
    expect(collection.requests.length,reads);expect(pending.writes,0);
    final scan=find.byKey(const ValueKey('buy-collection-scan'));await _shop05Reveal(tester,scan);await tester.tap(scan);await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('HOST-original-collection-camera')),findsOneWidget);expect(detected,isNotNull);expect(pending.writes,0);
    detected!('HOST physical collection QR');await tester.pumpAndSettle();
    expect(pending.writes,1);expect(collection.requests.where((v)=>v.operation==ScanPickOperation.authorise),hasLength(1));
    expect(collection.observedRetainedOperation,collection.observedRequestOperation,
      reason:'The original transport may run only after retaining this exact operation.');
    expect(h.cart.session.collectionSnapshotFor(h.order!.id)?.state,ScanPickState.matched,
      reason:'Native outcome must be admitted: fixtureMatched=${collection.matched}, pending=${pending.value?.operationId}, message=${h.cart.session.collectionMessageFor(h.order!.id)}');await h.finishReview(tester);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 053 cancelled camera and retired scan callback cannot authorise',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution(),pending=_Shop05CollectionPending();final collection=_Shop05Collection(pending);ValueChanged<String>? detected;
    final h=_Shop05Harness(delivery:delivery,resolution:resolution,collection:collection,pending:pending,
      orderFactory:(p){collection.product=p;return _shop05Order(p,collection:true);},camera:(context,callback){detected=callback;return const SizedBox(height:80);});
    await h.ready(tester);await h.cart.session.refreshCollectionOrder(h.order!.id);await h.startReview(tester,'AI-ACT-053',entity:h.order!.id);
    final scan=find.byKey(const ValueKey('buy-collection-scan'));await _shop05Reveal(tester,scan);await tester.tap(scan);await tester.pumpAndSettle();
    final close=find.byKey(const ValueKey('buy-collection-close-camera'));await _shop05Reveal(tester,close);await tester.tap(close);await tester.pumpAndSettle();
    detected!('HOST original QR');await tester.pumpAndSettle();expect(pending.writes,0);
    h.retire();await tester.pumpAndSettle();detected!('HOST original QR');await tester.pumpAndSettle();expect(pending.writes,0);await h.dispose(tester);
  });
  test('AI-SHOP05 schemas preserve exact Unicode slot/reason and reject invented authorities',(){
    final slot=BuyShop04InitialData.fromFields('AI-ACT-048',{'slot':'कल · 10–12'});expect(slot.slot,'कल · 10–12');
    final resolution=BuyShop04InitialData.fromFields('AI-ACT-050',{'kind':'cancel','reason':'ખોટી વસ્તુ','quantities':<String,Object?>{}});
    expect(resolution.reason,'ખોટી વસ્તુ');expect(resolution.kind,'cancel');
    expect(()=>BuyShop04InitialData.fromFields('AI-ACT-052',{'amount':0}),throwsFormatException);
    expect(()=>BuyShop04InitialData.fromFields('AI-ACT-048',{'proofReference':'invented'}),throwsFormatException);
    expect(()=>BuyShop04InitialData.fromFields('AI-ACT-055',{'lineId':'original','stars':6}),throwsFormatException);
    expect(()=>BuyShop04InitialData.fromFields('AI-ACT-050',{'quantities':<String,Object?>{'sku':0}}),throwsFormatException);
  });
  for(final action in ['048','051']){
    testWidgets('AI-SHOP05 $action exact native Review reads without effect or selection write',(tester)async{
      final delivery=_Shop05Delivery()..proof=action=='051',resolution=_Shop05Resolution();final h=_Shop05Harness(delivery:delivery,resolution:resolution);
      await h.ready(tester);expect(await h.cart.session.restoreDeliveryException(h.order!.id),isTrue);
      final effects=h.effects,reads=delivery.loads;
      await h.startReview(tester,'AI-ACT-$action',entity:h.order!.id,fields:action=='048'?{'slot':'Tomorrow · 14–16'}:const {});
      expect(find.byKey(ValueKey('buy-delivery-exception-${action=='048'?'rescheduleAvailable':'proofOfDeliveryAvailable'}')),findsOneWidget);
      expect(delivery.changes,0);expect(delivery.loads,reads);expect(h.cart.session.selectedDeliveryRescheduleSlot(h.order!.id),isNull);expect(h.effects,effects);
      await h.finishReview(tester);await h.dispose(tester);
    });
    testWidgets('AI-SHOP05 $action original final control sends exact retained source once',(tester)async{
      final delivery=_Shop05Delivery()..proof=action=='051',resolution=_Shop05Resolution();final h=_Shop05Harness(delivery:delivery,resolution:resolution);
      await h.ready(tester);expect(await h.cart.session.restoreDeliveryException(h.order!.id),isTrue);
      await h.startReview(tester,'AI-ACT-$action',entity:h.order!.id,fields:action=='048'?{'slot':'Tomorrow · 14–16'}:const {});
      final finalControl=find.byKey(ValueKey(action=='048'?'buy-delivery-confirm-reschedule':'buy-delivery-dispute-proof'));await _shop05Reveal(tester,finalControl);
      final callback=tester.widget<ButtonStyleButton>(finalControl).onPressed!;callback();callback();await tester.pumpAndSettle();
      expect(delivery.changes,1);expect(h.cart.session.deliveryExceptionFor(h.order!.id)?.kind,action=='048'?BuyV2DeliveryExceptionKind.dispatchDelayed:BuyV2DeliveryExceptionKind.proofOfDeliveryDisputed);
      await h.finishReview(tester);await h.dispose(tester);
    });
    testWidgets('AI-SHOP05 $action stale account and source cannot invoke retained callback',(tester)async{
      final delivery=_Shop05Delivery()..proof=action=='051',resolution=_Shop05Resolution();final h=_Shop05Harness(delivery:delivery,resolution:resolution);
      await h.ready(tester);expect(await h.cart.session.restoreDeliveryException(h.order!.id),isTrue);
      await h.startReview(tester,'AI-ACT-$action',entity:h.order!.id,fields:action=='048'?{'slot':'Tomorrow · 14–16'}:const {});
      final control=find.byKey(ValueKey(action=='048'?'buy-delivery-confirm-reschedule':'buy-delivery-dispute-proof'));await _shop05Reveal(tester,control);
      final callback=tester.widget<ButtonStyleButton>(control).onPressed!;h.retire();await tester.pumpAndSettle();callback();await tester.pumpAndSettle();expect(delivery.changes,0);
      await h.dispose(tester);
    });
    testWidgets('AI-SHOP05 $action unknown original result is held and not retried',(tester)async{
      final delivery=_Shop05Delivery()..proof=action=='051'..loseAck=true,resolution=_Shop05Resolution();final h=_Shop05Harness(delivery:delivery,resolution:resolution);
      await h.ready(tester);expect(await h.cart.session.restoreDeliveryException(h.order!.id),isTrue);
      await h.startReview(tester,'AI-ACT-$action',entity:h.order!.id,fields:action=='048'?{'slot':'Tomorrow · 14–16'}:const {});
      final control=find.byKey(ValueKey(action=='048'?'buy-delivery-confirm-reschedule':'buy-delivery-dispute-proof'));await _shop05Reveal(tester,control);await tester.tap(control);await tester.pumpAndSettle();
      expect(delivery.changes,1);expect(h.cart.session.deliveryExceptionFor(h.order!.id)?.state,isNot(BuyV2CommerceLoadState.ready));
      await h.finishReview(tester);expect(delivery.changes,1);await h.dispose(tester);
    });
  }
  testWidgets('AI-SHOP05 captured delivery callback beneath unrelated modal cannot send',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution();final h=_Shop05Harness(delivery:delivery,resolution:resolution);
    await h.ready(tester);await h.cart.session.restoreDeliveryException(h.order!.id);
    await h.startReview(tester,'AI-ACT-048',entity:h.order!.id,fields:{'slot':'Tomorrow · 14–16'});
    final control=find.byKey(const ValueKey('buy-delivery-confirm-reschedule'));await _shop05Reveal(tester,control);
    final callback=tester.widget<ButtonStyleButton>(control).onPressed!;
    final route=MaterialPageRoute<void>(builder:(_)=>const Scaffold(body:Text('HOST unrelated cover')));h.cart.navigator.currentState!.push(route);await tester.pumpAndSettle();
    callback();await tester.pumpAndSettle();expect(delivery.changes,0);h.cart.navigator.currentState!.pop();await tester.pumpAndSettle();
    await h.finishReview(tester);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 absent original source rejects proposals instead of opening blank forms',(tester)async{
    final delivery=_Shop05Delivery()..available=false,resolution=_Shop05Resolution();final h=_Shop05Harness(delivery:delivery,resolution:resolution);await h.ready(tester);
    final adapter=await h.openAI(tester,'AI-ACT-048');expect(await adapter.snapshot(h.cart.context,h.order!.id),isNull);
    final feedback=h.adapters.where((v)=>const ['AI-ACT-054','AI-ACT-056'].contains(v.actionId)).toList();
    expect(feedback.map((v)=>v.actionId).toSet(),{'AI-ACT-054','AI-ACT-056'});
    for(final reader in feedback)expect(await reader.snapshot(h.cart.context,'HOST-missing-product'),isNull);
    for(final action in ['AI-ACT-049','AI-ACT-052','AI-ACT-053','AI-ACT-055'])expect(await h.adapters.singleWhere((v)=>v.actionId==action).snapshot(h.cart.context,h.order!.id),isNull,reason:action);
    expect(delivery.changes,0);expect(resolution.sends,0);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 original resolution form displays supplied reason and no auto refresh/write',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution();final h=_Shop05Harness(delivery:delivery,resolution:resolution,orderFactory:(p)=>_shop05Order(p,confirmed:true));await h.ready(tester);
    expect(await h.cart.session.refreshOrderResolution(h.order!.id),isTrue);final loads=resolution.loads,effects=h.effects;
    await h.startReview(tester,'AI-ACT-050',entity:h.order!.id,fields:{'kind':'cancel','reason':'Changed mind'});
    expect(find.text('Changed mind'),findsWidgets);expect(resolution.loads,loads);expect(resolution.sends,0);expect(h.effects,effects);
    await h.finishReview(tester);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 original resolution final submits exact source and reason',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution();final h=_Shop05Harness(delivery:delivery,resolution:resolution,orderFactory:(p)=>_shop05Order(p,confirmed:true));await h.ready(tester);
    expect(await h.cart.session.refreshOrderResolution(h.order!.id),isTrue);
    await h.startReview(tester,'AI-ACT-050',entity:h.order!.id,fields:{'kind':'cancel','reason':'Changed mind'});
    final submit=find.byKey(const ValueKey('buy-order-resolution-submit'));await _shop05Reveal(tester,submit);await tester.tap(submit);await tester.pumpAndSettle();
    expect(resolution.sends,1);expect(resolution.last!.orderId,h.order!.id);expect(resolution.last!.reason,'Changed mind');expect(resolution.last!.eligibilitySourceId,'HOST original policy source');
    await h.finishReview(tester);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 unknown request retains original hold and never auto repeats',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution()..loseAck=true;final h=_Shop05Harness(delivery:delivery,resolution:resolution,orderFactory:(p)=>_shop05Order(p,confirmed:true));await h.ready(tester);
    await h.cart.session.refreshOrderResolution(h.order!.id);
    await h.startReview(tester,'AI-ACT-050',entity:h.order!.id,fields:{'kind':'cancel','reason':'Changed mind'});
    final submit=find.byKey(const ValueKey('buy-order-resolution-submit'));await _shop05Reveal(tester,submit);await tester.tap(submit);await tester.pumpAndSettle();expect(resolution.sends,1);
    await h.finishReview(tester);expect(resolution.sends,1);expect(h.cart.owner.lastSnapshot,isNotNull);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 manual native delivery retains default session selection path',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution();final h=_Shop05Harness(delivery:delivery,resolution:resolution);await h.ready(tester);
    await h.cart.session.restoreDeliveryException(h.order!.id);expect(h.cart.session.chooseDeliveryRescheduleSlot(h.order!.id,'Tomorrow · 10–12'),isTrue);
    expect(await h.cart.session.confirmDeliveryReschedule(h.order!.id),isTrue);expect(delivery.changes,1);await h.dispose(tester);
  });
  testWidgets('AI-SHOP05 current-source change then restoration retires captured exact exception',(tester)async{
    final delivery=_Shop05Delivery(),resolution=_Shop05Resolution();final h=_Shop05Harness(delivery:delivery,resolution:resolution);await h.ready(tester);
    await h.cart.session.restoreDeliveryException(h.order!.id);await h.startReview(tester,'AI-ACT-048',entity:h.order!.id,fields:{'slot':'Tomorrow · 10–12'});
    final control=find.byKey(const ValueKey('buy-delivery-confirm-reschedule'));await _shop05Reveal(tester,control);final callback=tester.widget<ButtonStyleButton>(control).onPressed!;
    delivery.id='HOST changed exception';await h.cart.session.restoreDeliveryException(h.order!.id);delivery.id='HOST-exception-original';await h.cart.session.restoreDeliveryException(h.order!.id);
    await tester.pumpAndSettle();callback();await tester.pumpAndSettle();expect(delivery.changes,0);await h.dispose(tester);
  });
}
