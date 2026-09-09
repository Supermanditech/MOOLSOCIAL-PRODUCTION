import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_catalogue_data.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/work/scan_and_pick_contract.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

final class _T01CDeliveryFactsAdapter implements BuyV2ProductFactsAdapter {
  final promises = <BuyV2Destination, (String, String)>{
    BuyV2Destination.shop: ('within 5 min', 'by 6:35 PM'),
    BuyV2Destination.wholesale: ('within 1 day', 'by tomorrow 4:00 PM'),
  };

  void update(
    BuyV2Destination destination, {
    required String promise,
    required String promisedBy,
  }) {
    promises[destination] = (promise, promisedBy);
  }

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final quote = promises[product.destination];
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          deliveryPromise: quote?.$1 ?? product.deliveryPromise,
          promisedByLabel: quote?.$2,
          sourceId: 'b01-t01c-delivery-quote',
        );
  }
}

final class _ShopCommerceAdapter implements BuyV2CommerceAdapter {
  _ShopCommerceAdapter({required this.snapshot, required this.placement});

  final BuyV2CommerceSnapshot snapshot;
  BuyV2OrderPlacementResult placement;
  BuyV2OrderPlacementResult? reconciliation;
  int placementCalls = 0;
  int reconciliationCalls = 0;
  int reviewCalls = 0;
  int reportCalls = 0;
  int orderRefreshCalls = 0;
  final requests = <BuyV2OrderPlacementRequest>[];
  BuyV2MutationResult reviewResult = const BuyV2MutationResult(
    accepted: true,
    customerMessage: 'Review added.',
  );
  BuyV2MutationResult reportResult = const BuyV2MutationResult(
    accepted: true,
    customerMessage: 'Report received.',
  );
  BuyV2OrderRefreshResult orderRefreshResult = const BuyV2OrderRefreshResult(
    state: BuyV2CommerceLoadState.unavailable,
    customerMessage: 'Order updates are unavailable right now.',
  );
  BuyV2OrderAlertsResult alertsResult = const BuyV2OrderAlertsResult(
    available: true,
    enabled: false,
    customerMessage: 'Order alerts are paused.',
  );

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => snapshot;

  @override
  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  ) async {
    placementCalls += 1;
    requests.add(request);
    return placement;
  }

  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  }) async {
    reconciliationCalls += 1;
    return reconciliation ?? placement;
  }

  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({
    required String orderId,
  }) async {
    orderRefreshCalls += 1;
    return orderRefreshResult;
  }

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async => alertsResult;

  @override
  Future<BuyV2OrderAlertsResult> setOrderAlerts({required bool enabled}) async {
    alertsResult = BuyV2OrderAlertsResult(
      available: true,
      enabled: enabled,
      customerMessage: enabled
          ? 'Order alerts are on.'
          : 'Order alerts are paused.',
    );
    return alertsResult;
  }

  @override
  Future<BuyV2AddressRequestResult> createAddressRequest({
    String recipient = '',
  }) async => const BuyV2AddressRequestResult(
    customerMessage: 'Address requests are unavailable right now.',
  );

  @override
  Future<BuyV2MutationResult> reportProduct({
    required BuyV2Product product,
    required String reason,
  }) async {
    reportCalls += 1;
    return reportResult;
  }

  @override
  Future<BuyV2MutationResult> submitProductReview({
    required BuyV2Product product,
    required int rating,
    required String comment,
  }) async {
    reviewCalls += 1;
    return reviewResult;
  }
}

final class _MemoryCustomerStateStore implements BuyV2CustomerStateStore {
  _MemoryCustomerStateStore(this.ownerScope);

  @override
  final String ownerScope;

  BuyV2CustomerStateSnapshot? snapshot;

  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => snapshot;

  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async {
    this.snapshot = snapshot;
    return true;
  }
}

final class _MutableCommerceFactsAdapter implements BuyV2ProductFactsAdapter {
  int? price;
  String orderabilityLabel = 'Available to add';
  bool stale = false;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          price: price ?? product.price,
          orderabilityLabel: orderabilityLabel,
          sourceId: 'shop-live-facts',
          observedAt: DateTime(2026, 8, 29),
          stale: stale,
        );
  }
}

Future<
  ({
    BuyV2Session session,
    _ShopCommerceAdapter adapter,
    BuyV2Product product,
    BuyV2Order order,
  })
>
_openProductionCheckout({
  required BuyV2OrderPlacementOutcome outcome,
  Uri? paymentActionUri,
  String? paymentReference,
  BuyV2ProductFactsAdapter? factsAdapter,
  BuyV2CustomerStateStore? customerStateStore,
  bool productReportsAvailable = false,
  bool productReviewAvailable = false,
  BuyV2BusinessVerificationState businessVerificationState =
      BuyV2BusinessVerificationState.unavailable,
}) async {
  final product = BuyV2Catalogue.products.firstWhere(
    (candidate) => candidate.destination == BuyV2Destination.shop,
  );
  const address = BuyV2Address(
    id: 'server-home',
    kind: BuyV2AddressKind.home,
    label: 'Home',
    recipient: 'Aarav Sharma',
    phone: '9000000000',
    line: '12, Central Avenue',
    area: 'Sardarpura, Jodhpur',
    pinCode: '342003',
    landmark: 'Near the market',
  );
  final order = BuyV2Order(
    id: 'MS-SERVER-1',
    destination: BuyV2Destination.shop,
    title: 'Shop order',
    itemSummary: '1 product',
    total: product.price,
    partner: product.seller,
    partnerType: product.partnerRole,
    promise: product.deliveryPromise,
    destinationLabel: address.shortLine,
    progress: .2,
    status: BuyV2OrderStatus.preparing,
    purchaseId: 'BUY-SERVER-1',
    productIds: [product.id],
    lines: [BuyV2CartLine(product: product, quantity: 1)],
    paymentMethod: 'UPI',
  );
  final placement = BuyV2OrderPlacementResult(
    outcome: outcome,
    customerMessage: switch (outcome) {
      BuyV2OrderPlacementOutcome.paymentActionRequired =>
        'Continue to your payment app.',
      BuyV2OrderPlacementOutcome.paymentPending =>
        'Payment confirmation is pending.',
      BuyV2OrderPlacementOutcome.paymentUnknown =>
        'Payment status could not be confirmed.',
      BuyV2OrderPlacementOutcome.cancelled => 'Payment was cancelled.',
      BuyV2OrderPlacementOutcome.failed => 'Payment failed.',
      BuyV2OrderPlacementOutcome.unavailable => 'Ordering is unavailable.',
      BuyV2OrderPlacementOutcome.confirmed => 'Your order is confirmed.',
    },
    purchaseReference: outcome == BuyV2OrderPlacementOutcome.confirmed
        ? 'BUY-SERVER-1'
        : null,
    paymentReference: paymentReference,
    paymentActionUri: paymentActionUri,
    orders: outcome == BuyV2OrderPlacementOutcome.confirmed
        ? [order]
        : const [],
  );
  final adapter = _ShopCommerceAdapter(
    snapshot: BuyV2CommerceSnapshot(
      state: BuyV2CommerceLoadState.ready,
      products: [product],
      addresses: const [address],
      selectedAddressId: address.id,
      paymentMethods: const {'UPI'},
      businessVerificationState: businessVerificationState,
      productReportsAvailable: productReportsAvailable,
      reviewableProductIds: productReviewAvailable ? {product.id} : const {},
    ),
    placement: placement,
  );
  final session = BuyV2Session(
    core: BuySession(),
    productFactsAdapter:
        factsAdapter ?? const BuyV2CatalogueProductFactsAdapter(),
    commerceAdapter: adapter,
    customerStateStore: customerStateStore,
    reviewDataEnabled: false,
  );
  await session.restoreCommerce();
  session.addProduct(product.id);
  session.openCart(scope: BuyV2CartScope.shop);
  session.openCheckout();
  return (session: session, adapter: adapter, product: product, order: order);
}

class _PagingRecoverySource extends BuyV2DevelopmentCatalogueSource {
  _PagingRecoverySource()
    : super(destination: BuyV2Destination.shop, providerCount: 1000);

  bool failStores = false;
  bool failResolution = false;
  Completer<void>? resolutionGate;
  final resolutionRequests = <Set<String>>[];
  bool holdProducts = false;
  bool wrongBranch = false;
  int active = 0;
  int peak = 0;
  final productRequests = <BuyV2CatalogueQuery>[];
  final productGates = <Completer<void>>[];

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    active += 1;
    if (active > peak) peak = active;
    productRequests.add(query);
    try {
      if (holdProducts) {
        final gate = Completer<void>();
        productGates.add(gate);
        await gate.future;
      }
      final page = await super.loadProducts(
        query,
        cursor: cursor,
        pageSize: pageSize,
      );
      if (!wrongBranch) return page;
      return BuyV2CataloguePage(
        queryKey: page.queryKey,
        snapshotId: page.snapshotId,
        items: page.items.map((p) => p.copyWith(storeId: 'another-branch')),
        startIndex: page.startIndex,
        totalCount: page.totalCount,
        nextCursor: page.nextCursor,
        previousCursor: page.previousCursor,
      );
    } finally {
      active -= 1;
    }
  }

  @override
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    if (failStores) throw StateError('Store source unavailable');
    return super.loadStores(query, cursor: cursor, pageSize: pageSize);
  }

  @override
  Future<List<BuyV2Product>> resolveProducts(Set<String> productIds) async {
    resolutionRequests.add(Set.of(productIds));
    if (resolutionGate != null) await resolutionGate!.future;
    if (failResolution) throw StateError('Products could not restore');
    return super.resolveProducts(productIds);
  }
}

class _PublishedFixtureSource extends BuyV2DevelopmentPublishedCatalogueSource {
  _PublishedFixtureSource({super.now}) : super(providerCount: 1000);
  bool fail = false;
  Completer<void>? gate;
  int calls = 0;
  BuyV2PublishedCatalogueOffer Function(BuyV2PublishedCatalogueOffer)? rewrite;

  @override
  Future<BuyV2CataloguePage<BuyV2PublishedCatalogueOffer>> loadOffers(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    calls++;
    if (gate != null) await gate!.future;
    if (fail) throw StateError('Publication source unavailable');
    final page = await super.loadOffers(
      query,
      cursor: cursor,
      pageSize: pageSize,
    );
    return BuyV2CataloguePage(
      queryKey: page.queryKey,
      snapshotId: page.snapshotId,
      startIndex: page.startIndex,
      totalCount: page.totalCount,
      previousCursor: page.previousCursor,
      nextCursor: page.nextCursor,
      items: page.items.map((offer) => rewrite?.call(offer) ?? offer),
    );
  }
}

BuyV2PublishedCatalogueOffer _copyPublication(
  BuyV2PublishedCatalogueOffer value, {
  String? publicationId,
  String? publisherId,
  String? publisherName,
  String? sourceId,
  String? headline,
  BuyV2Product? product,
  BuyV2OfferPublisherType? publisher,
  DateTime? observedAt,
  DateTime? validUntil,
}) => BuyV2PublishedCatalogueOffer(
  publicationId: publicationId ?? value.publicationId,
  product: product ?? value.product,
  publisherType: publisher ?? value.publisherType,
  publisherId: publisherId ?? value.publisherId,
  publisherName: publisherName ?? value.publisherName,
  headline: headline ?? value.headline,
  sourceId: sourceId ?? value.sourceId,
  observedAt: observedAt ?? value.observedAt,
  validUntil: validUntil ?? value.validUntil,
);

class _CollectionPurchaseHarness
    implements
        BuyV2CollectionCheckoutGateway,
        BuyV2CollectionPurchaseStore,
        ScanPickGateway {
  final identity = ValueNotifier<BuyV2CollectionIdentity?>(
    const BuyV2CollectionIdentity(accountId: 'buyer-a', sessionId: 'session-a'),
  );
  DateTime clock = DateTime.utc(2026, 9, 8);
  BuyV2CollectionPurchaseIntent? pending;
  BuyV2CollectionPurchaseIntent? lastRequest;
  ScanPickSnapshot? admittedOrder;
  int quotes = 0, placements = 0, reconciliations = 0, settlements = 0;
  bool failRead = false, rejectReserve = false, rejectSettle = false;
  bool wrongOperation = false;
  String paidOrderId = 'order-a';
  String quoteFault = '';
  BuyV2CollectionPurchaseState outcome = BuyV2CollectionPurchaseState.paid;
  Completer<bool>? reservationGate;
  Completer<void>? placementGate;
  Future<bool>? _reservation;
  void Function(Map<String, Object?>)? mutateSnapshot;

  BuyV2CollectionBasket basket({
    int quantity = 1,
    String storeId = 'store-a',
    String? sku,
    String payment = 'PhonePe',
  }) {
    final product = BuyV2Catalogue.allProducts
        .firstWhere((p) => p.destination == BuyV2Destination.shop)
        .copyWith(
          id: sku ?? 'sku-a',
          canonicalId: 'product-a',
          storeId: storeId,
          minimumOrder: 1,
          price: 100,
        );
    return BuyV2CollectionBasket(
      identity: identity.value!,
      paymentMethod: payment,
      store: BuyV2StoreListing(
        id: storeId,
        name: storeId == 'store-c' ? 'City Wholesale' : 'Market Store',
        area: switch (storeId) {
          'store-b' => 'Station branch',
          'store-c' => 'Industrial Area',
          _ => 'West branch',
        },
        address: switch (storeId) {
          'store-b' => '48 Station Road',
          'store-c' => '7 Industrial Road',
          _ => '12 Market Road',
        },
        regionId: 'jodhpur',
        collection: BuyV2StoreCollectionCapability(
          storeId: storeId,
          supportsCollection: true,
          sourceId: 'store-capability',
          observedAt: clock.subtract(const Duration(minutes: 1)),
          validUntil: clock.add(const Duration(minutes: 15)),
        ),
      ),
      lines: [BuyV2CartLine(product: product, quantity: quantity)],
    );
  }

  BuyV2CollectionCheckoutController controller({Duration? timeout}) =>
      BuyV2CollectionCheckoutController(
        identity: identity,
        gateway: this,
        pendingStore: this,
        collectionGateway: this,
        now: () => clock,
        timeout: timeout ?? const Duration(seconds: 15),
      );

  @override
  Future<BuyV2CollectionCheckoutQuote> quote(
    BuyV2CollectionBasket basket,
  ) async {
    quotes++;
    final amounts = {
      for (final line in basket.lines)
        line.product.id: line.total * 100 + (quoteFault == 'price' ? 1 : 0),
    };
    return BuyV2CollectionCheckoutQuote(
      id: 'quote-1',
      sourceId: 'quote-service',
      basketFingerprint: quoteFault == 'basket'
          ? 'another'
          : basket.fingerprint,
      issuedAt: clock.subtract(const Duration(seconds: 1)),
      validUntil: quoteFault == 'expiry'
          ? clock
          : clock.add(const Duration(minutes: 2)),
      lineAmountsMinor: amounts,
      totalMinor: amounts.values.fold<int>(0, (sum, value) => sum + value) + 25,
      taxMinor: 25,
    );
  }

  BuyV2CollectionPurchaseResult response(
    BuyV2CollectionPurchaseIntent intent,
  ) => BuyV2CollectionPurchaseResult(
    operationId: wrongOperation ? 'other-operation' : intent.operationId,
    intentFingerprint: intent.fingerprint,
    state: outcome,
    orderId: outcome == BuyV2CollectionPurchaseState.paid ? paidOrderId : null,
    purchaseId: outcome == BuyV2CollectionPurchaseState.paid
        ? 'purchase-a'
        : null,
    paymentReference: 'payment-a',
    paymentActionUri: outcome == BuyV2CollectionPurchaseState.actionRequired
        ? Uri.parse('upi://pay?tr=payment-a')
        : null,
    paidAmountMinor: outcome == BuyV2CollectionPurchaseState.paid
        ? intent.quote.totalMinor
        : null,
    currency: outcome == BuyV2CollectionPurchaseState.paid ? 'INR' : null,
  );

  @override
  Future<BuyV2CollectionPurchaseResult> place(
    BuyV2CollectionPurchaseIntent intent,
  ) async {
    placements++;
    lastRequest = intent;
    if (placementGate != null) await placementGate!.future;
    return response(intent);
  }

  @override
  Future<BuyV2CollectionPurchaseResult> reconcile(
    BuyV2CollectionPurchaseIntent intent,
  ) async {
    reconciliations++;
    lastRequest = intent;
    return response(intent);
  }

  @override
  Future<BuyV2CollectionPurchaseIntent?> read(String accountId) async {
    if (_reservation != null) await _reservation;
    if (failRead) throw StateError('storage unavailable');
    return pending?.basket.identity.accountId == accountId ? pending : null;
  }

  @override
  Future<bool> reserve(BuyV2CollectionPurchaseIntent intent) {
    return _reservation = () async {
      if (reservationGate != null && !await reservationGate!.future) {
        return false;
      }
      if (rejectReserve || pending != null) return false;
      pending = intent;
      return true;
    }();
  }

  @override
  Future<bool> settle(
    BuyV2CollectionPurchaseIntent intent,
    BuyV2CollectionPurchaseResult result, {
    ScanPickSnapshot? paidOrder,
  }) async {
    settlements++;
    if (rejectSettle || pending?.fingerprint != intent.fingerprint) {
      return false;
    }
    admittedOrder = paidOrder;
    pending = null;
    return true;
  }

  @override
  Future<ScanPickResult> execute(ScanPickRequest request) async {
    final intent = lastRequest!;
    final snapshot = <String, Object?>{
      'purpose': scanPickPurpose,
      'orderId': request.orderId,
      'storeId': intent.basket.store.id,
      'purchaserAccountId': intent.basket.identity.accountId,
      'customerName': 'Customer',
      'storeName': intent.basket.store.name,
      'revision': 'revision-1',
      'serverTime': clock.toIso8601String(),
      'state': 'preparing',
      'payment': 'paid',
      'readiness': 'preparing',
      'currency': 'INR',
      'totalMinor': intent.quote.totalMinor,
      'lines': [
        for (final line in intent.basket.lines)
          <String, Object?>{
            'lineId': line.product.id,
            'skuId': line.product.id,
            'productId': line.product.canonicalId,
            'name': line.product.title,
            'pack': line.product.pack,
            'quantity': line.quantity.toString(),
            'amountMinor': intent.quote.lineAmountsMinor[line.product.id],
          },
      ],
    };
    mutateSnapshot?.call(snapshot);
    return ScanPickResult.fromJson({
      'protocolVersion': scanPickProtocolVersion,
      'requestId': request.requestId,
      'operation': 'read',
      'outcome': 'snapshot',
      'snapshot': snapshot,
    });
  }
}

class _CollectionScannerPending implements BuyV2CollectionPendingStore {
  BuyV2CollectionPendingIntent? pending;
  @override
  Future<BuyV2CollectionPendingIntent?> read({
    required String accountId,
    required String orderId,
    required String storeId,
  }) async => pending;
  @override
  Future<bool> reserve(BuyV2CollectionPendingIntent intent) async {
    if (pending != null) return false;
    pending = intent;
    return true;
  }

  @override
  Future<bool> clear(BuyV2CollectionPendingIntent intent) async {
    if (pending != null && pending!.operationId != intent.operationId) {
      return false;
    }
    pending = null;
    return true;
  }
}

class _CollectionPurchaseCatalogueSource implements BuyV2CataloguePageSource {
  _CollectionPurchaseCatalogueSource(this.harness);
  final _CollectionPurchaseHarness harness;
  List<BuyV2Product> get products => [
    harness.basket().lines.single.product,
    harness.basket(storeId: 'store-b', sku: 'sku-b').lines.single.product,
    BuyV2Catalogue.allProducts
        .firstWhere((p) => p.destination == BuyV2Destination.wholesale)
        .copyWith(
          id: 'wholesale-sku',
          canonicalId: 'whole-product',
          storeId: 'store-c',
          minimumOrder: 2,
        ),
  ];

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    final items = products
        .where(
          (p) =>
              p.destination == query.destination &&
              (query.storeId == null || query.storeId == p.storeId),
        )
        .toList();
    return BuyV2CataloguePage(
      queryKey: query.key,
      snapshotId: 'checkout-products',
      items: items,
      startIndex: 0,
      totalCount: items.length,
    );
  }

  @override
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    final ids = products
        .where(
          (p) =>
              p.destination == query.destination &&
              (query.storeId == null || query.storeId == p.storeId),
        )
        .map((p) => p.storeId!)
        .toSet();
    return BuyV2CataloguePage(
      queryKey: query.key,
      snapshotId: 'checkout-stores',
      items: ids.map((id) => harness.basket(storeId: id).store),
      startIndex: 0,
      totalCount: ids.length,
    );
  }

  @override
  Future<List<BuyV2Product>> resolveProducts(Set<String> productIds) async =>
      products.where((p) => productIds.contains(p.id)).toList();
}

Future<BuyV2Session> _openOrderSearchFixture() async {
  final tomato = BuyV2Catalogue.products.firstWhere((p) => p.id == 's-tomato');
  final milk = BuyV2Catalogue.products.firstWhere((p) => p.id == 's-milk');
  BuyV2Order order(
    String id,
    BuyV2Product product, {
    String? purchaseId = 'BUY-SPLIT-04',
    BuyV2OrderStatus status = BuyV2OrderStatus.preparing,
    BuyV2Destination destination = BuyV2Destination.shop,
    bool hasLines = true,
  }) => BuyV2Order(
    id: id,
    destination: destination,
    title: 'Shop order',
    itemSummary: '1 product · 2 items',
    total: product.price * 2,
    partner: product.seller,
    partnerType: product.partnerRole,
    promise: 'Delivery time unavailable',
    destinationLabel: 'Sardarpura',
    progress: status == BuyV2OrderStatus.delivered ? 1 : .2,
    status: status,
    purchaseId: purchaseId,
    purchaseOrderReference: 'PO-BUYER-047',
    productIds: hasLines ? [product.id] : const [],
    lines: hasLines ? [BuyV2CartLine(product: product, quantity: 2)] : const [],
  );
  final core = BuySession();
  final session = BuyV2Session(
    core: core,
    reviewDataEnabled: false,
    commerceAdapter: _ShopCommerceAdapter(
      snapshot: BuyV2CommerceSnapshot(
        state: BuyV2CommerceLoadState.ready,
        // Historical titles must not come from a renamed live listing.
        products: [
          tomato.copyWith(title: 'Seasonal produce'),
          milk,
        ],
        orders: [
          order('MS-SEARCH-TOMATO', tomato),
          order('MS-SEARCH-MILK', milk),
          order(
            'MS-SEARCH-DELIVERED',
            tomato,
            status: BuyV2OrderStatus.delivered,
          ),
          order('MS-SEARCH-OTHER', milk, purchaseId: 'BUY-OTHER-05'),
          order(
            'RX-SEARCH-HIDDEN',
            tomato,
            destination: BuyV2Destination.medicine,
          ),
          order('MS-SEARCH-LEGACY', tomato, purchaseId: null, hasLines: false),
        ],
      ),
      placement: const BuyV2OrderPlacementResult(
        outcome: BuyV2OrderPlacementOutcome.unavailable,
        customerMessage: 'Test ordering is disabled.',
      ),
    ),
  );
  addTearDown(core.dispose);
  addTearDown(session.dispose);
  await session.restoreCommerce();
  session.openDestination(BuyV2Destination.orders);
  return session;
}

void main() {
  test(
    'R669 order search uses historical titles and split purchase references',
    () async {
      final session = await _openOrderSearchFixture();
      final ordersBefore = session.visibleOrders.map((o) => o.id).toList();
      session.updateQuery('  ToMaTo  ');
      expect(session.visibleOrders.map((o) => o.id), ['MS-SEARCH-TOMATO']);
      session.updateQuery('seasonal produce');
      expect(session.visibleOrders, isEmpty);
      session.updateQuery('buy-split-04');
      expect(session.visibleOrders.map((o) => o.id), [
        'MS-SEARCH-TOMATO',
        'MS-SEARCH-MILK',
      ]);
      session.showOrdersTab(BuyV2OrdersTab.delivered);
      expect(session.query, 'buy-split-04');
      expect(session.visibleOrders.map((o) => o.id), ['MS-SEARCH-DELIVERED']);
      session.updateQuery('tomato');
      expect(session.visibleOrders.map((o) => o.id), ['MS-SEARCH-DELIVERED']);
      session.showOrdersTab(BuyV2OrdersTab.active);
      session.updateQuery('SPLIT-04');
      expect(session.visibleOrders.length, 2);
      session.updateQuery('po-buyer-047');
      expect(session.visibleOrders.map((o) => o.id), ordersBefore);
      session.updateQuery('no-such-purchase');
      expect(session.visibleOrders, isEmpty);
      session.updateQuery('');
      expect(session.visibleOrders.map((o) => o.id), ordersBefore);
      expect(session.itemCount, 0);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'R669 order search opens the matching purchase and returns $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 711);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final session = await _openOrderSearchFixture();
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: BuyV2Screen(
              session: session,
              initialDestination: BuyV2Destination.orders,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-search-control')));
        await tester.pumpAndSettle();
        final field = find.byKey(const ValueKey('buy-search-field'));
        await tester.enterText(field, 'tomato');
        await tester.pumpAndSettle();
        expect(session.visibleOrders.map((o) => o.id), ['MS-SEARCH-TOMATO']);
        final card = find.byKey(
          const ValueKey('buy-order-card-MS-SEARCH-TOMATO'),
        );
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        expect(card.hitTestable(), findsOneWidget);
        expect(find.text('No orders match this search'), findsNothing);
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.tracking);
        expect(session.selectedOrder.id, 'MS-SEARCH-TOMATO');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.destination, BuyV2Destination.orders);
        expect(session.query, 'tomato');
        expect(card, findsOneWidget);
        expect(field, findsNothing);
        final search = find.byKey(const ValueKey('buy-search-control'));
        expect(search.hitTestable(), findsOneWidget);
        await tester.tap(search);
        await tester.pumpAndSettle();
        await tester.enterText(field, 'BUY-SPLIT-04');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-purchase-group-BUY-SPLIT-04')),
          findsOneWidget,
        );
        expect(session.visibleOrders.map((o) => o.id), [
          'MS-SEARCH-TOMATO',
          'MS-SEARCH-MILK',
        ]);
        session.showOrdersTab(BuyV2OrdersTab.delivered);
        await tester.pumpAndSettle();
        expect(session.visibleOrders.single.id, 'MS-SEARCH-DELIVERED');
        expect(session.itemCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'R669 bulk quantity entry enforces the published minimum pack order',
    () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final product = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.wholesale &&
            item.minimumOrder > 2,
      );
      expect(session.addProduct(product.id), isTrue);
      expect(
        session.setCartQuantity(product.id, '${product.minimumOrder - 1}'),
        isFalse,
      );
      expect(session.quantityFor(product.id), product.minimumOrder);
      expect(session.setCartQuantity(product.id, '1000'), isTrue);
      expect(session.quantityFor(product.id), 1000);
      expect(session.cartTotal, product.price * 1000);
    },
  );

  test(
    'R669 bulk quantity entry is atomic and preserves exact large totals',
    () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      const id = 'w-notebook';
      expect(session.addProduct(id), isTrue);
      session.openProduct(id);
      final previousQuantity = session.quantityFor(id);
      for (final input in [
        '',
        '0',
        '-1',
        '1.5',
        '1,000',
        '999999999999999999999',
      ]) {
        expect(session.setCartQuantity(id, input), isFalse, reason: input);
        expect(session.quantityFor(id), previousQuantity);
      }
      var notifications = 0;
      session.addListener(() => notifications++);
      expect(session.setCartQuantity(id, '28736'), isTrue);
      expect(notifications, 1);
      expect(session.quantityFor(id), 28736);
      expect(session.cartTotal, 100001280);
      expect(session.selectedProductId, id);
      expect(session.view, BuyV2View.product);
      expect(session.setCartQuantity(id, '1000'), isTrue);
      expect(session.quantityFor(id), 1000);
      session.increase(id);
      expect(session.quantityFor(id), 1001);
      session.decrease(id);
      expect(session.quantityFor(id), 1000);
      expect(
        session.setCartQuantity(id, '${session.product(id).minimumOrder}'),
        isTrue,
      );
      session.decrease(id);
      expect(session.quantityFor(id), 0);
      expect(session.setCartQuantity(id, '1000'), isFalse);
      expect(session.quantityFor(id), 0);
    },
  );

  test('R669 quantity entry respects prescription approval limits', () {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    session.approveSavedPrescription('meera');
    const id = 'm-telmisartan-40';
    expect(session.addProduct(id), isTrue);
    expect(session.setCartQuantity(id, '2'), isFalse);
    expect(session.quantityFor(id), 1);
    expect(session.notice, contains('prescription'));
    expect(session.setCartQuantity(id, '1'), isTrue);
  });

  for (final now in [
    DateTime(2026, 9, 8, 18, 29),
    DateTime(2026, 9, 8, 23, 59),
    DateTime(2026, 9, 9),
  ]) {
    test('R665 D05 undated catalogue promises stay honest at $now', () {
      final core = BuySession();
      final session = BuyV2Session(core: core, catalogueNow: () => now);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final relativeDeadline = RegExp(
        r'\b(today|tomorrow)\s+by\b',
        caseSensitive: false,
      );
      expect(
        BuyV2Catalogue.products.any(
          (product) => relativeDeadline.hasMatch(product.deliveryPromise),
        ),
        isFalse,
      );
      expect(session.product('s-tomato').deliveryPromise, 'Delivery in 12 min');
      for (final id in ['s-atta', 's-oil', 's-notebook', 'w-atta']) {
        final product = session.product(id);
        expect(product.deliveryPromise, 'Delivery time confirmed at checkout');
        expect(
          session.productFactsFor(product).deliveryPromise,
          product.deliveryPromise,
        );
        expect(session.addProduct(id), isTrue);
      }
      session.openCart();
      expect(session.scopedCartFulfilmentGroups, isNotEmpty);
      for (final group in session.scopedCartFulfilmentGroups) {
        expect(group.promise, 'Delivery time confirmed at checkout');
        expect(group.promisedByLabel, isNull);
      }
      expect(session.openCheckout(), isTrue);
      for (final group in session.checkoutFulfilmentGroups) {
        expect(group.promise, 'Delivery time confirmed at checkout');
        expect(group.promisedByLabel, isNull);
      }
    });
  }

  group('R5 collection purchase', () {
    late _CollectionPurchaseHarness harness;
    late BuyV2CollectionCheckoutController checkout;
    setUp(() {
      harness = _CollectionPurchaseHarness();
      checkout = harness.controller();
    });
    tearDown(() {
      checkout.dispose();
      harness.identity.dispose();
    });

    Future<BuyV2Session> checkoutSession({
      bool openCheckout = true,
      bool purchaseServices = true,
    }) async {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        reviewDataEnabled: true,
        cataloguePageSource: _CollectionPurchaseCatalogueSource(harness),
        catalogueNow: () => harness.clock,
        collectionIdentity: harness.identity,
        collectionGateway: harness,
        collectionPendingStore: _CollectionScannerPending(),
        collectionCheckoutGateway: purchaseServices ? harness : null,
        collectionPurchaseStore: purchaseServices ? harness : null,
      );
      addTearDown(() {
        session.dispose();
        core.dispose();
      });
      for (final destination in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        final pager = session.acquireCatalogueProducts(
          'collection-${destination.name}',
        );
        await pager.open(
          session.catalogueQuery(catalogueDestination: destination),
        );
      }
      for (final product in _CollectionPurchaseCatalogueSource(
        harness,
      ).products) {
        await session.refreshCatalogueStore(
          product.storeId!,
          product.destination,
        );
        expect(session.addProduct(product.id), isTrue);
      }
      session.openCart();
      if (openCheckout) expect(session.openCheckout(), isTrue);
      return session;
    }

    Future<void> mountCheckout(
      WidgetTester tester,
      BuyV2Session session, {
      required Size size,
      required double scale,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: r66VisualCaptureRoot(child!),
          ),
          home: BuyV2Screen(
            session: session,
            initialDestination: session.destination,
            initialView: session.view,
          ),
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    }

    for (final fault in ['services', 'identity', 'capability', 'quote']) {
      testWidgets('checkout failure recovery visual $fault', (tester) async {
        final session = await checkoutSession(
          purchaseServices: fault != 'services',
        );
        session.chooseCheckoutCollection(true, storeId: 'store-a');
        session.continueCheckoutFromAddress();
        final orderCount = session.orders.length;
        if (fault == 'identity') harness.identity.value = null;
        if (fault == 'capability') {
          harness.clock = harness.clock.add(const Duration(minutes: 16));
        }
        if (fault == 'quote') harness.quoteFault = 'expiry';
        await mountCheckout(
          tester,
          session,
          size: const Size(320, 844),
          scale: 2,
        );
        final primary = find.byKey(
          const ValueKey('buy-checkout-primary-payment'),
        );
        if (fault == 'services' || fault == 'identity') {
          expect(tester.widget<FilledButton>(primary).onPressed, isNull);
        } else {
          expect(primary.hitTestable(), findsOneWidget);
          await tester.tap(primary);
          await tester.pumpAndSettle();
        }
        final expectedMessage = switch (fault) {
          'services' =>
            'Store collection is unavailable right now. Your Cart has not changed.',
          'identity' => 'Sign in to place a store collection order.',
          'capability' =>
            'Check this store’s collection availability to continue.',
          _ =>
            'The collection total could not be checked. Your Cart has not changed.',
        };
        expect(find.text(expectedMessage), findsOneWidget);
        await tester.ensureVisible(find.text(expectedMessage));
        await tester.pumpAndSettle();
        expect(find.text(expectedMessage).hitTestable(), findsOneWidget);
        expect(harness.placements, 0);
        expect(harness.pending, isNull);
        expect(session.orders.length, orderCount);
        await captureR66Visual(tester, 'r5-collection-checkout-failure-$fault');
        final back = find.byKey(const ValueKey('buy-checkout-back'));
        if (back.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            back,
            -180,
            scrollable: find
                .descendant(
                  of: find.byKey(const PageStorageKey('buy-checkout-payment')),
                  matching: find.byType(Scrollable),
                )
                .first,
            maxScrolls: 20,
          );
        }
        await tester.ensureVisible(back);
        await tester.pumpAndSettle();
        expect(back.hitTestable(), findsOneWidget);
        await tester.tap(back);
        await tester.pumpAndSettle();
        expect(session.checkoutStep, BuyV2CheckoutStep.address);
        final cart = find.byKey(const ValueKey('buy-checkout-return-cart'));
        await tester.ensureVisible(cart);
        await tester.pumpAndSettle();
        expect(cart.hitTestable(), findsOneWidget);
        await tester.tap(cart);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(session.quantityFor('sku-a'), 1);
        expect(session.quantityFor('sku-b'), 1);
        expect(session.quantityFor('wholesale-sku'), 2);
        expect(tester.takeException(), isNull);
      });
    }

    test(
      'existing delivery order ID cannot admit a collection payment',
      () async {
        final session = await checkoutSession();
        final originalOrder = session.orders.first;
        harness.paidOrderId = originalOrder.id;
        session.chooseCheckoutCollection(true, storeId: 'store-a');
        session.continueCheckoutFromAddress();
        await session.prepareCollectionCheckout();
        expect(await session.submitOrder(), isFalse);
        expect(harness.settlements, 0);
        expect(session.quantityFor('sku-a'), 1);
        expect(session.collectionCheckout!.unresolved, isTrue);
        expect(session.orders.first, same(originalOrder));
        expect(session.view, BuyV2View.checkout);
      },
    );

    test(
      'late paid completion preserves navigation away from checkout',
      () async {
        final session = await checkoutSession();
        session.chooseCheckoutCollection(true, storeId: 'store-a');
        session.continueCheckoutFromAddress();
        await session.prepareCollectionCheckout();
        harness.placementGate = Completer<void>();
        final placing = session.submitOrder();
        await Future<void>.delayed(Duration.zero);
        session.openOrders();
        harness.placementGate!.complete();
        expect(await placing, isTrue);
        expect(session.view, BuyV2View.catalogue);
        expect(session.destination, BuyV2Destination.orders);
        expect(
          session.orders.where((order) => order.id == 'order-a'),
          hasLength(1),
        );
        expect(session.quantityFor('sku-a'), 0);
        expect(session.quantityFor('sku-b'), 1);
      },
    );

    test(
      'admission changing during settlement keeps payment blocked from retry',
      () async {
        checkout.dispose();
        var admissions = 0;
        checkout = BuyV2CollectionCheckoutController(
          identity: harness.identity,
          gateway: harness,
          pendingStore: harness,
          collectionGateway: harness,
          now: () => harness.clock,
          acceptPaidOrder: (_, _) => ++admissions == 1,
        );
        final basket = harness.basket();
        await checkout.prepare(basket);
        expect(await checkout.place(basket), isFalse);
        expect(checkout.paidOrder, isNull);
        expect(checkout.unresolved, isTrue);
        expect(await checkout.place(basket), isFalse);
        expect(await checkout.prepare(basket), isFalse);
        expect(harness.placements, 1);
      },
    );

    test('overflowing fee arithmetic cannot produce a small payable total', () {
      final basket = harness.basket();
      final quote = BuyV2CollectionCheckoutQuote(
        id: 'q',
        sourceId: 'source',
        basketFingerprint: basket.fingerprint,
        issuedAt: harness.clock,
        validUntil: harness.clock.add(const Duration(minutes: 1)),
        lineAmountsMinor: const {'sku-a': 10000},
        totalMinor: 9998,
        taxMinor: 9223372036854775807,
        paymentChargeMinor: 9223372036854775807,
      );
      expect(quote.matches(basket), isFalse);
    });

    for (final size in [const Size(320, 844), const Size(640, 360)]) {
      for (final scale in [1.0, 2.0]) {
        final profile = '${size.width.toInt()}x${size.height.toInt()}-$scale';
        testWidgets('checkout taps and visual $profile', (tester) async {
          final session = await checkoutSession(openCheckout: false);
          await mountCheckout(tester, session, size: size, scale: scale);
          Future<void> tap(Finder target) async {
            expect(target, findsOneWidget);
            await tester.ensureVisible(target);
            await tester.pumpAndSettle();
            expect(target.hitTestable(), findsOneWidget);
            await tester.tap(target);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }

          Future<void> capture(String state) async {
            expect(tester.takeException(), isNull);
            await captureR66Visual(
              tester,
              'r5-collection-checkout-$profile-$state',
            );
          }

          final cartReview = find.descendant(
            of: find.byKey(const ValueKey('buy-cart-action-bar')),
            matching: find.widgetWithText(FilledButton, 'Review order'),
          );
          if (cartReview.evaluate().isEmpty) {
            final cartScroll = find
                .descendant(
                  of: find.byKey(const PageStorageKey('buy-cart-all')),
                  matching: find.byType(Scrollable),
                )
                .first;
            await tester.scrollUntilVisible(
              cartReview,
              160,
              scrollable: cartScroll,
              maxScrolls: 40,
            );
            await tester.pumpAndSettle();
          }
          await tap(cartReview);
          await capture('delivery-choice');
          await tap(
            find.byKey(const ValueKey('buy-checkout-collection-choice')),
          );
          expect(find.text('Market Store · West branch'), findsOneWidget);
          expect(find.text('Market Store · Station branch'), findsOneWidget);
          expect(find.text('City Wholesale · Industrial Area'), findsOneWidget);
          final secondStore = find.byKey(
            const ValueKey('buy-checkout-collection-store-store-b'),
          );
          await tap(
            find.descendant(of: secondStore, matching: find.byType(Icon)).first,
          );
          expect(session.collectionCheckoutStore!.id, 'store-b');
          await capture('other-branch');
          final firstStore = find.byKey(
            const ValueKey('buy-checkout-collection-store-store-a'),
          );
          await tap(
            find.descendant(of: firstStore, matching: find.byType(Icon)).first,
          );
          expect(session.collectionCheckoutStore!.id, 'store-a');
          await capture('store-choice');
          await tap(find.byKey(const ValueKey('buy-checkout-primary-address')));
          await tap(find.byKey(const ValueKey('buy-payment-Paytm')));
          expect(session.selectedPayment, 'Paytm');
          await capture('payment-choice');
          expect(find.text('Cash on Delivery'), findsNothing);
          expect(find.text('Purchase order'), findsNothing);
          await tap(find.byKey(const ValueKey('buy-checkout-primary-payment')));
          expect(session.checkoutStep, BuyV2CheckoutStep.confirm);
          expect(find.text('₹100.25'), findsWidgets);
          await capture('review');
          final reviewedLine = find.byKey(
            const ValueKey('buy-checkout-collection-line-sku-a'),
          );
          await tester.ensureVisible(
            find
                .descendant(of: reviewedLine, matching: find.byType(Icon))
                .first,
          );
          await tester.pumpAndSettle();
          await capture('review-items');
          harness.clock = harness.clock.add(const Duration(minutes: 3));
          await tap(find.byKey(const ValueKey('buy-checkout-primary-confirm')));
          expect(harness.placements, 0);
          expect(harness.pending, isNull);
          expect(session.checkoutStep, BuyV2CheckoutStep.confirm);
          expect(find.text('Update total'), findsOneWidget);
          final expiredNotice = find.text(
            'Your total needs updating. Review it before paying.',
          );
          await tester.ensureVisible(expiredNotice);
          await tester.pumpAndSettle();
          expect(expiredNotice.hitTestable(), findsOneWidget);
          await capture('expired-total');
          await tap(find.byKey(const ValueKey('buy-checkout-primary-confirm')));
          expect(find.text('Place order'), findsOneWidget);
          expect(harness.quotes, 2);
          harness.outcome = BuyV2CollectionPurchaseState.unknown;
          await tap(find.byKey(const ValueKey('buy-checkout-primary-confirm')));
          expect(session.quantityFor('sku-a'), 1);
          expect(session.checkoutStep, BuyV2CheckoutStep.payment);
          await capture('payment-pending');
          expect(
            find.byKey(const ValueKey('buy-payment-PhonePe')),
            findsNothing,
          );
          expect(find.byKey(const ValueKey('buy-payment-Paytm')), findsNothing);
          expect(
            find.byKey(const ValueKey('buy-payment-Pine Labs')),
            findsNothing,
          );
          final recoveryText = find.descendant(
            of: find.byKey(const ValueKey('buy-checkout-collection-notice')),
            matching: find.byType(Text),
          );
          final recoveryViewport = tester.getRect(
            find.byKey(const PageStorageKey('buy-checkout-payment-recovery')),
          );
          final recoveryRect = tester.getRect(recoveryText);
          expect(recoveryRect.top, greaterThanOrEqualTo(recoveryViewport.top));
          expect(
            recoveryRect.bottom,
            lessThanOrEqualTo(recoveryViewport.bottom),
          );
          await capture('payment-recovery');
          harness.outcome = BuyV2CollectionPurchaseState.paid;
          await tap(find.byKey(const ValueKey('buy-checkout-primary-payment')));
          expect(session.view, BuyV2View.tracking);
          expect(session.selectedOrderOrNull!.id, 'order-a');
          expect(session.quantityFor('sku-a'), 0);
          expect(session.quantityFor('sku-b'), 1);
          expect(session.quantityFor('wholesale-sku'), 2);
          expect(harness.placements, 1);
          expect(harness.lastRequest!.basket.paymentMethod, 'Paytm');
          await capture('same-paid-order');
          await tester.ensureVisible(find.text('Paid ₹100.25'));
          await tester.pumpAndSettle();
          expect(find.text('Paid ₹100.25').hitTestable(), findsOneWidget);
          await capture('same-paid-order-amount');
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        });
      }
    }

    test(
      'existing checkout creates one collection order and preserves other carts',
      () async {
        final session = await checkoutSession();
        expect(
          session.chooseCheckoutCollection(true, storeId: 'store-a'),
          isTrue,
        );
        expect(session.checkoutLines.single.product.id, 'sku-a');
        expect(session.continueCheckoutFromAddress(), isTrue);
        expect(await session.prepareCollectionCheckout(), isTrue);
        expect(session.checkoutStep, BuyV2CheckoutStep.confirm);
        expect(session.confirmOrder(), isFalse);
        expect(await session.submitOrder(), isTrue);
        expect(session.view, BuyV2View.tracking);
        expect(session.selectedOrderOrNull!.id, 'order-a');
        expect(session.selectedOrderOrNull!.totalMinor, 10025);
        expect(session.selectedOrderOrNull!.collection!.storeId, 'store-a');
        expect(session.quantityFor('sku-a'), 0);
        expect(session.quantityFor('sku-b'), 1);
        expect(session.quantityFor('wholesale-sku'), 2);
        expect(harness.placements, 1);
      },
    );

    test(
      'unresolved collection cannot switch branch delivery or payment',
      () async {
        final session = await checkoutSession();
        session.chooseCheckoutCollection(true, storeId: 'store-a');
        session.continueCheckoutFromAddress();
        await session.prepareCollectionCheckout();
        harness.outcome = BuyV2CollectionPurchaseState.unknown;
        expect(await session.submitOrder(), isFalse);
        expect(session.chooseCheckoutCollection(false), isFalse);
        expect(
          session.chooseCheckoutCollection(true, storeId: 'store-b'),
          isFalse,
        );
        expect(session.choosePayment('Paytm'), isFalse);
        expect(session.addProduct('sku-b'), isFalse);
        expect(session.confirmOrder(), isFalse);
        expect(session.quantityFor('sku-a'), 1);
        harness.outcome = BuyV2CollectionPurchaseState.paid;
        expect(await session.reconcilePayment(), isTrue);
        expect(session.quantityFor('sku-b'), 1);
        expect(harness.placements, 1);
      },
    );

    test(
      'switching a ready collection branch withdraws the earlier amount',
      () async {
        final session = await checkoutSession();
        session.chooseCheckoutCollection(true, storeId: 'store-a');
        session.continueCheckoutFromAddress();
        await session.prepareCollectionCheckout();
        expect(session.collectionCheckoutQuote, isNotNull);
        session.chooseCheckoutCollection(true, storeId: 'store-b');
        expect(session.collectionCheckoutQuote, isNull);
        expect(session.checkoutLines.single.product.id, 'sku-b');
        expect(harness.placements, 0);
        session.chooseCheckoutCollection(false);
        expect(session.checkoutLines, hasLength(3));
      },
    );

    test(
      'timed-out reservation serializes before recovery and never charges',
      () async {
        checkout.dispose();
        checkout = harness.controller(
          timeout: const Duration(milliseconds: 30),
        );
        final basket = harness.basket();
        await checkout.prepare(basket);
        harness.reservationGate = Completer<bool>();
        expect(await checkout.place(basket), isFalse);
        expect(checkout.unresolved, isTrue);
        expect(harness.pending, isNull);
        expect(harness.placements, 0);
        final checking = checkout.checkPayment();
        harness.outcome = BuyV2CollectionPurchaseState.notCharged;
        harness.reservationGate!.complete(true);
        expect(await checking, isFalse);
        expect(harness.reconciliations, 1);
        expect(harness.placements, 0);
        expect(harness.pending, isNull);
        expect(checkout.unresolved, isFalse);
      },
    );

    test(
      'late placement after timeout reconciles its original operation',
      () async {
        checkout.dispose();
        checkout = harness.controller(
          timeout: const Duration(milliseconds: 30),
        );
        final basket = harness.basket();
        await checkout.prepare(basket);
        harness.placementGate = Completer<void>();
        expect(await checkout.place(basket), isFalse);
        final original = harness.pending!;
        harness.placementGate!.complete();
        await Future<void>.delayed(Duration.zero);
        expect(checkout.paidOrder, isNull);
        expect(await checkout.checkPayment(), isTrue);
        expect(harness.lastRequest, same(original));
        expect(harness.placements, 1);
      },
    );

    test('disposed coordinator cannot expose a late paid reply', () async {
      final basket = harness.basket();
      await checkout.prepare(basket);
      harness.placementGate = Completer<void>();
      final placing = checkout.place(basket);
      await Future<void>.delayed(Duration.zero);
      final disposed = checkout;
      disposed.dispose();
      checkout = harness.controller();
      harness.placementGate!.complete();
      expect(await placing, isFalse);
      expect(disposed.paidOrder, isNull);
      expect(harness.pending, isNotNull);
      expect(await checkout.checkPayment(), isTrue);
    });

    test('another operation cannot settle this payment', () async {
      final basket = harness.basket();
      await checkout.prepare(basket);
      harness.wrongOperation = true;
      expect(await checkout.place(basket), isFalse);
      expect(checkout.paidOrder, isNull);
      expect(harness.settlements, 0);
      expect(harness.pending, isNotNull);
    });

    test('paid order matches exact branch SKU and retains 25 paise', () async {
      final basket = harness.basket();
      expect(await checkout.prepare(basket), isTrue);
      expect(checkout.quote!.totalMinor, 10025);
      expect(await checkout.place(basket), isTrue);
      expect(checkout.phase, BuyV2CollectionCheckoutPhase.paid);
      expect(checkout.paidOrder!.totalMinor, 10025);
      expect(harness.admittedOrder, same(checkout.paidOrder));
      expect(harness.pending, isNull);
      expect(harness.placements, 1);
      expect(await checkout.place(basket), isFalse);
      expect(await checkout.prepare(basket), isTrue);
      expect(checkout.intent, isNull);
    });

    test(
      'basket is immutable and cannot combine branches or deferred payment',
      () {
        final first = harness.basket();
        final lines = [...first.lines];
        final copied = BuyV2CollectionBasket(
          identity: first.identity,
          store: first.store,
          paymentMethod: first.paymentMethod,
          lines: lines,
        );
        lines.clear();
        expect(copied.lines, hasLength(1));
        expect(() => copied.lines.clear(), throwsUnsupportedError);
        expect(
          () => BuyV2CollectionBasket(
            identity: first.identity,
            store: first.store,
            paymentMethod: first.paymentMethod,
            lines: [
              ...first.lines,
              ...harness.basket(storeId: 'other', sku: 'sku-b').lines,
            ],
          ),
          throwsFormatException,
        );
        for (final payment in ['Cash on Delivery', 'Purchase order']) {
          expect(() => harness.basket(payment: payment), throwsFormatException);
        }
        expect(() => harness.basket(quantity: 0), throwsFormatException);
      },
    );

    test(
      'fingerprints retain exact quantity session branch and pack identity',
      () {
        final first = harness.basket();
        expect(first.fingerprint, harness.basket().fingerprint);
        for (final changed in [
          harness.basket(quantity: 2),
          harness.basket(storeId: 'b'),
          harness.basket(sku: 'sku-b'),
          harness.basket(payment: 'Paytm'),
        ]) {
          expect(changed.fingerprint, isNot(first.fingerprint));
        }
        harness.identity.value = const BuyV2CollectionIdentity(
          accountId: 'buyer-a',
          sessionId: 'new',
        );
        expect(harness.basket().fingerprint, isNot(first.fingerprint));
      },
    );

    for (final fault in ['basket', 'expiry', 'price']) {
      test('rejects $fault quote before payment', () async {
        harness.quoteFault = fault;
        expect(await checkout.prepare(harness.basket()), isFalse);
        expect(await checkout.place(harness.basket()), isFalse);
        expect(harness.placements, 0);
        expect(harness.pending, isNull);
      });
    }

    test('missing capability and storage failure never submit', () async {
      final unavailable = BuyV2CollectionCheckoutController(
        identity: harness.identity,
      );
      expect(await unavailable.prepare(harness.basket()), isFalse);
      unavailable.dispose();
      harness.failRead = true;
      expect(await checkout.prepare(harness.basket()), isFalse);
      expect(harness.quotes, 0);
      expect(harness.placements, 0);
    });

    test('changed cart and expired quote cannot place', () async {
      final basket = harness.basket();
      await checkout.prepare(basket);
      expect(await checkout.place(harness.basket(quantity: 2)), isFalse);
      harness.clock = harness.clock.add(const Duration(minutes: 3));
      expect(await checkout.place(basket), isFalse);
      expect(harness.placements, 0);
    });

    test(
      'duplicate taps wait for one durable reservation and one payment',
      () async {
        final basket = harness.basket();
        await checkout.prepare(basket);
        harness.reservationGate = Completer<bool>();
        final placing = checkout.place(basket);
        expect(await checkout.place(basket), isFalse);
        expect(await checkout.prepare(harness.basket(quantity: 2)), isFalse);
        expect(harness.placements, 0);
        harness.reservationGate!.complete(true);
        expect(await placing, isTrue);
        expect(harness.placements, 1);
      },
    );

    test(
      'expired during reservation requires recovery without charging',
      () async {
        final basket = harness.basket();
        await checkout.prepare(basket);
        harness.reservationGate = Completer<bool>();
        final placing = checkout.place(basket);
        harness.clock = harness.clock.add(const Duration(minutes: 3));
        harness.reservationGate!.complete(true);
        expect(await placing, isFalse);
        expect(harness.placements, 0);
        expect(checkout.unresolved, isTrue);
        harness.outcome = BuyV2CollectionPurchaseState.notCharged;
        expect(await checkout.checkPayment(), isFalse);
        expect(checkout.unresolved, isFalse);
        expect(harness.pending, isNull);
      },
    );

    test(
      'unknown payment recovers original basket after cart changes and restart',
      () async {
        final basket = harness.basket();
        await checkout.prepare(basket);
        harness.outcome = BuyV2CollectionPurchaseState.unknown;
        expect(await checkout.place(basket), isFalse);
        final original = harness.pending!;
        checkout.dispose();
        checkout = harness.controller();
        harness.outcome = BuyV2CollectionPurchaseState.paid;
        expect(
          await checkout.prepare(harness.basket(quantity: 3, storeId: 'other')),
          isTrue,
        );
        expect(harness.lastRequest, same(original));
        expect(checkout.paidOrder!.storeId, 'store-a');
        expect(checkout.paidOrder!.lines.single.quantity, '1');
        expect(harness.quotes, 1);
        expect(harness.placements, 1);
        expect(harness.reconciliations, 1);
      },
    );

    test(
      'account/session change discards late payment but keeps durable intent',
      () async {
        final basket = harness.basket();
        await checkout.prepare(basket);
        harness.placementGate = Completer<void>();
        final placing = checkout.place(basket);
        await Future<void>.delayed(Duration.zero);
        harness.identity.value = const BuyV2CollectionIdentity(
          accountId: 'buyer-b',
          sessionId: 'b',
        );
        harness.placementGate!.complete();
        expect(await placing, isFalse);
        expect(checkout.paidOrder, isNull);
        expect(harness.pending!.basket.identity.accountId, 'buyer-a');
        harness.identity.value = const BuyV2CollectionIdentity(
          accountId: 'buyer-a',
          sessionId: 'new',
        );
        expect(await checkout.checkPayment(), isTrue);
        expect(harness.lastRequest!.basket.identity.sessionId, 'session-a');
        expect(harness.placements, 1);
      },
    );

    test(
      'settlement failure retains payment and does not expose a paid order',
      () async {
        final basket = harness.basket();
        await checkout.prepare(basket);
        harness.rejectSettle = true;
        expect(await checkout.place(basket), isFalse);
        expect(checkout.paidOrder, isNull);
        expect(harness.pending, isNotNull);
        harness.rejectSettle = false;
        expect(await checkout.checkPayment(), isTrue);
        expect(harness.placements, 1);
      },
    );

    for (final fault in [
      'store',
      'account',
      'sku',
      'pack',
      'quantity',
      'lineAmount',
      'total',
      'unpaid',
      'token',
    ]) {
      test('paid response with $fault mismatch stays unconfirmed', () async {
        final basket = harness.basket();
        await checkout.prepare(basket);
        harness.mutateSnapshot = (snapshot) {
          final line =
              (snapshot['lines']! as List).single as Map<String, Object?>;
          switch (fault) {
            case 'store':
              snapshot['storeId'] = 'another';
            case 'account':
              snapshot['purchaserAccountId'] = 'another';
            case 'sku':
              line['skuId'] = 'another';
            case 'pack':
              line['pack'] = 'another';
            case 'quantity':
              line['quantity'] = '2';
            case 'lineAmount':
              line['amountMinor'] = 10001;
            case 'total':
              snapshot['totalMinor'] = 10026;
            case 'unpaid':
              snapshot['payment'] = 'unpaid';
            case 'token':
              snapshot['state'] = 'awaitingCustomer';
              snapshot['readiness'] = 'ready';
              snapshot['challenge'] = {
                'id': 'qr-1',
                'qrPayload': 'private-token',
                'expiresAt': harness.clock
                    .add(const Duration(seconds: 30))
                    .toIso8601String(),
              };
          }
        };
        expect(await checkout.place(basket), isFalse);
        expect(checkout.paidOrder, isNull);
        expect(harness.pending, isNotNull);
        expect(harness.settlements, 0);
      });
    }

    test(
      'equivalent decimal quantity is accepted without floating point',
      () async {
        final basket = harness.basket();
        await checkout.prepare(basket);
        harness.mutateSnapshot = (snapshot) {
          ((snapshot['lines']! as List).single
                  as Map<String, Object?>)['quantity'] =
              '1.000';
        };
        expect(await checkout.place(basket), isTrue);
      },
    );

    test(
      'failed external handoff reconciles same operation without a new charge',
      () async {
        final basket = harness.basket();
        await checkout.prepare(basket);
        harness.outcome = BuyV2CollectionPurchaseState.actionRequired;
        expect(await checkout.place(basket), isFalse);
        final operation = harness.pending!.operationId;
        harness.outcome = BuyV2CollectionPurchaseState.paid;
        expect(await checkout.continuePayment((uri) async => false), isTrue);
        expect(harness.lastRequest!.operationId, operation);
        expect(harness.placements, 1);
      },
    );
  });

  group('R5 published catalogue', () {
    final now = DateTime.utc(2026, 9, 8);
    BuyV2CatalogueQuery query({
      BuyV2OfferPublisherType? publisher,
      String? region = 'jodhpur',
      BuyV2CatalogueAreaScope scope = BuyV2CatalogueAreaScope.regional,
      String text = '',
      String category = 'all',
      String? storeId,
    }) => BuyV2CatalogueQuery(
      destination: BuyV2Destination.shop,
      regionId: region,
      areaScope: scope,
      query: text,
      categoryId: category,
      offersOnly: true,
      offerPublisher: publisher,
      storeId: storeId,
    );

    test(
      'unsupported channel filters cannot silently broaden Offers',
      () async {
        final source = BuyV2DevelopmentPublishedCatalogueSource(now: () => now);
        final requests = [
          for (final value in BuyV2ShopSaleType.values)
            BuyV2CatalogueQuery(
              destination: BuyV2Destination.shop,
              regionId: 'jodhpur',
              offersOnly: true,
              shopSaleType: value,
            ),
          for (final value in BuyV2WholesaleSaleType.values)
            BuyV2CatalogueQuery(
              destination: BuyV2Destination.shop,
              regionId: 'jodhpur',
              offersOnly: true,
              wholesaleSaleType: value,
            ),
        ];
        for (final request in requests) {
          await expectLater(
            source.loadOffers(request, pageSize: 40),
            throwsFormatException,
          );
        }
        expect(source.productObjectsCreated, 0);
      },
    );

    test(
      'large mixed feed allocates only requested exact Store products',
      () async {
        final source = BuyV2DevelopmentPublishedCatalogueSource(now: () => now);
        final first = await source.loadOffers(query(), pageSize: 40);
        expect(first.totalCount, 20000000);
        expect(first.items.length, 40);
        expect(source.productObjectsCreated, 40);
        expect(first.items.map((o) => o.product.destination).toSet(), {
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
        });
        expect(first.items.every((o) => o.isCurrent(now: now)), isTrue);
        final next = await source.loadOffers(
          query(),
          cursor: first.nextCursor,
          pageSize: 40,
        );
        expect(next.startIndex, 40);
        expect(source.productObjectsCreated, 80);
        expect(
          {
            ...first.items.map((o) => o.product.id),
            ...next.items.map((o) => o.product.id),
          }.length,
          80,
        );
        for (final destination in [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
        ]) {
          final catalogue = BuyV2DevelopmentCatalogueSource(
            destination: destination,
          );
          final ids = first.items
              .where((o) => o.product.destination == destination)
              .map((o) => o.product.id)
              .toSet();
          final restored = await catalogue.resolveProducts(ids);
          expect(restored.map((p) => p.id).toSet(), ids);
          for (final product in restored) {
            final offer = first.items.singleWhere(
              (o) => o.product.id == product.id,
            );
            expect(product.storeId, offer.product.storeId);
            expect(product.pack, offer.product.pack);
            expect(product.price, offer.product.price);
          }
        }
      },
    );

    for (final publisher in BuyV2OfferPublisherType.values) {
      test(
        '${publisher.name} filter has source counts and exact publisher rows',
        () async {
          final source = BuyV2DevelopmentPublishedCatalogueSource(
            providerCount: 20,
            skusPerStore: 50,
            now: () => now,
          );
          final page = await source.loadOffers(
            query(publisher: publisher),
            pageSize: 40,
          );
          expect(
            page.totalCount,
            publisher == BuyV2OfferPublisherType.retailer ? 20 : 10,
          );
          expect(page.items.every((o) => o.publisherType == publisher), isTrue);
          expect(page.nextCursor, isNull);
          expect(
            page.items.every(
              (o) =>
                  o.product.destination ==
                  (publisher == BuyV2OfferPublisherType.retailer
                      ? BuyV2Destination.shop
                      : BuyV2Destination.wholesale),
            ),
            isTrue,
          );
        },
      );
    }

    test(
      'end/back and changed query cursors are bounded and independent',
      () async {
        final source = BuyV2DevelopmentPublishedCatalogueSource(
          providerCount: 3,
          skusPerStore: 50,
          now: () => now,
        );
        final all = query(
          region: null,
          scope: BuyV2CatalogueAreaScope.allAreas,
        );
        final first = await source.loadOffers(all, pageSize: 40);
        final last = await source.loadOffers(
          all,
          cursor: first.nextCursor,
          pageSize: 40,
        );
        expect(last.totalCount, 60);
        expect(last.items.length, 20);
        expect(last.nextCursor, isNull);
        final back = await source.loadOffers(
          all,
          cursor: last.previousCursor,
          pageSize: 40,
        );
        expect(
          back.items.map((o) => o.product.id),
          first.items.map((o) => o.product.id),
        );
        await expectLater(
          source.loadOffers(
            query(publisher: BuyV2OfferPublisherType.retailer),
            cursor: first.nextCursor,
            pageSize: 40,
          ),
          throwsFormatException,
        );
        await expectLater(
          source.loadOffers(all, pageSize: 51),
          throwsArgumentError,
        );
        final productSource = BuyV2DevelopmentCatalogueSource(
          destination: BuyV2Destination.shop,
        );
        final products = await productSource.loadProducts(all, pageSize: 40);
        await expectLater(
          source.loadOffers(all, cursor: products.nextCursor, pageSize: 40),
          throwsFormatException,
        );
      },
    );

    test(
      'Store name SKU category and area requests retain their own result identity',
      () async {
        final source = BuyV2DevelopmentPublishedCatalogueSource(
          providerCount: 20,
          skusPerStore: 50,
          now: () => now,
        );
        final named = await source.loadOffers(
          query(text: 'Mool Market 000011'),
          pageSize: 40,
        );
        expect(named.totalCount, 20);
        expect(
          named.items.every((o) => o.product.storeId!.contains('store-000011')),
          isTrue,
        );
        final sku = await source.loadOffers(
          query(text: 'sku 46'),
          pageSize: 40,
        );
        expect(sku.items, isNotEmpty);
        expect(
          sku.items.every((o) => o.product.id.endsWith('sku-0046')),
          isTrue,
        );
        final region = await source.loadOffers(
          query(region: 'mumbai'),
          pageSize: 40,
        );
        expect(
          region.items.every((o) => o.product.origin.contains('mumbai')),
          isTrue,
        );
        final category = sku.items.first.product.categoryId;
        final filtered = await source.loadOffers(
          query(category: category),
          pageSize: 40,
        );
        expect(filtered.items, isNotEmpty);
        expect(
          filtered.items.every((o) => o.product.categoryId == category),
          isTrue,
        );
      },
    );

    test(
      'page retry eviction and shared inactive context budget preserve Cart and Saved',
      () async {
        final source = _PublishedFixtureSource(now: () => now);
        final catalogue = _PagingRecoverySource();
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          cataloguePageSource: catalogue,
          publishedCatalogueSource: source,
          catalogueNow: () => now,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final pager = session.acquireCatalogueOffers('offers');
        await pager.open(query());
        final first = pager.page!;
        final cart = first.items.first.product;
        final saved = first.items[1].product;
        expect(session.addProduct(cart.id), isTrue);
        session.toggleSaved(saved.id);
        source.fail = true;
        await pager.next();
        expect(pager.page, same(first));
        expect(pager.message, isNotNull);
        source.fail = false;
        await pager.retry();
        expect(pager.page!.startIndex, 40);
        for (var page = 0; page < 6; page++) {
          await pager.next();
        }
        expect(session.quantityFor(cart.id), 1);
        expect(session.isSaved(saved.id), isTrue);
        expect(session.pagedProductCount, lessThanOrEqualTo(122));
        session.releaseCatalogueOffers('offers');
        for (var index = 0; index < 5; index++) {
          final key = 'store-$index';
          final products = session.acquireCatalogueProducts(key);
          await products.open(
            BuyV2CatalogueQuery(
              destination: BuyV2Destination.shop,
              regionId: null,
              areaScope: BuyV2CatalogueAreaScope.allAreas,
              storeId: catalogue.storeIdAt(index),
            ),
          );
          session.releaseCatalogueProducts(key);
        }
        expect(pager.isDisposed, isTrue);
        expect(session.quantityFor(cart.id), 1);
        expect(session.product(saved.id).storeId, saved.storeId);
        expect(session.pagedProductCount, lessThanOrEqualTo(162));
      },
    );

    for (final invalid in [
      'source',
      'publisher-id',
      'publisher-name',
      'headline',
      'expired',
      'future',
      'publisher',
      'duplicate',
      'store',
    ]) {
      test(
        'rejects $invalid publication facts before product admission',
        () async {
          final source = _PublishedFixtureSource(now: () => now);
          source.rewrite = (offer) => switch (invalid) {
            'source' => _copyPublication(offer, sourceId: ' '),
            'publisher-id' => _copyPublication(offer, publisherId: ' '),
            'publisher-name' => _copyPublication(offer, publisherName: ' '),
            'headline' => _copyPublication(offer, headline: ' '),
            'expired' => _copyPublication(offer, validUntil: now),
            'future' => _copyPublication(
              offer,
              observedAt: now.add(const Duration(minutes: 1)),
            ),
            'publisher' => _copyPublication(
              offer,
              publisher: BuyV2OfferPublisherType.wholesaler,
            ),
            'duplicate' => _copyPublication(
              offer,
              publicationId: 'duplicate-publication',
            ),
            _ => _copyPublication(
              offer,
              product: offer.product.copyWith(storeId: ' '),
            ),
          };
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            publishedCatalogueSource: source,
            catalogueNow: () => now,
            reviewDataEnabled: false,
          );
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          final pager = session.acquireCatalogueOffers('offers');
          await pager.open(query(publisher: BuyV2OfferPublisherType.retailer));
          expect(pager.page, isNull);
          expect(pager.message, isNotNull);
          expect(session.pagedProductCount, 0);
        },
      );
    }

    test(
      'pending publications share two request slots and cannot admit after disposal',
      () async {
        final source = _PublishedFixtureSource(now: () => now)
          ..gate = Completer<void>();
        final catalogue = _PagingRecoverySource()..holdProducts = true;
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          cataloguePageSource: catalogue,
          publishedCatalogueSource: source,
          catalogueNow: () => now,
        );
        addTearDown(core.dispose);
        final offers = session.acquireCatalogueOffers('offers');
        final other = session.acquireCatalogueOffers('other');
        final products = session.acquireCatalogueProducts('shop');
        final pending = offers.open(query());
        final productPending = products.open(
          BuyV2CatalogueQuery(
            destination: BuyV2Destination.shop,
            regionId: 'jodhpur',
          ),
        );
        final queued = other.open(
          query(publisher: BuyV2OfferPublisherType.retailer),
        );
        await Future<void>.delayed(Duration.zero);
        expect(session.catalogueRequestsInFlight, 2);
        expect(source.calls, 1);
        expect(catalogue.active, 1);
        session.dispose();
        source.gate!.complete();
        catalogue.productGates.single.complete();
        await Future.wait([pending, productPending, queued]);
        expect(session.catalogueRequestsInFlight, 0);
        expect(session.pagedProductCount, 0);
        expect(source.calls, 1);
        expect(offers.isDisposed, isTrue);
      },
    );
  });

  group('R5 catalogue session', () {
    BuyV2CatalogueQuery storeQuery(_PagingRecoverySource source, int store) =>
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: null,
          areaScope: BuyV2CatalogueAreaScope.allAreas,
          storeId: source.storeIdAt(store),
        );

    test(
      'page eviction retains Cart Saved current detail and recent product only',
      () async {
        final source = _PagingRecoverySource();
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          cataloguePageSource: source,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final pager = session.acquireCatalogueProducts('shop');
        await pager.open(storeQuery(source, 0));
        final first = pager.page!.items;
        expect(session.addProduct(first[0].id), isTrue);
        session.toggleSaved(first[1].id);
        expect(session.openProduct(first[2].id), isTrue);
        session.productFactsFor(first[3]);
        for (var i = 0; i < 7; i++) {
          await pager.next();
        }
        expect(session.pagedProductCount, lessThanOrEqualTo(123));
        expect(session.quantityFor(first[0].id), 1);
        expect(session.isSaved(first[1].id), isTrue);
        expect(session.selectedProduct!.id, first[2].id);
        expect(
          session.recentlyViewedProductsFor(BuyV2Destination.shop).single.id,
          first[2].id,
        );
        expect(session.findProduct(first[3].id), isNull);
        expect(
          session.savedProductsFor(BuyV2Destination.shop).map((p) => p.id),
          [first[1].id],
        );
        session.clearRecentlyViewed(BuyV2Destination.shop);
        expect(
          session.recentlyViewedProductsFor(BuyV2Destination.shop),
          isEmpty,
        );
        session.releaseCatalogueProducts('shop');
      },
    );

    test(
      'same canonical product in another branch is not Saved implicitly',
      () async {
        final source = _PagingRecoverySource();
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          cataloguePageSource: source,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final first = session.acquireCatalogueProducts('store-a');
        final second = session.acquireCatalogueProducts('store-b');
        await first.open(storeQuery(source, 0));
        await second.open(storeQuery(source, 1));
        final a = first.page!.items.first;
        final b = second.page!.items.first;
        expect(a.canonicalId, b.canonicalId);
        session.toggleSaved(a.id);
        expect(session.isSaved(a.id), isTrue);
        expect(session.isSaved(b.id), isFalse);
        expect(session.savedProductsFor(BuyV2Destination.shop).single.id, a.id);
      },
    );

    test(
      'Cart Saved and recent products restore by exact listing IDs after relaunch',
      () async {
        final source = _PagingRecoverySource();
        final store = _MemoryCustomerStateStore('catalogue-account');
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          cataloguePageSource: source,
          customerStateStore: store,
        );
        final pager = session.acquireCatalogueProducts('store-a');
        await pager.open(storeQuery(source, 1));
        final ids = pager.page!.items.take(3).map((p) => p.id).toList();
        expect(session.addProduct(ids[0]), isTrue);
        session.toggleSaved(ids[1]);
        expect(session.openProduct(ids[2]), isTrue);
        await Future<void>.delayed(Duration.zero);
        final saved = store.snapshot!;
        session.dispose();
        core.dispose();
        final nextCore = BuySession();
        final next = BuyV2Session(
          core: nextCore,
          reviewDataEnabled: false,
          cataloguePageSource: _PagingRecoverySource(),
          customerStateStore: store,
        );
        addTearDown(next.dispose);
        addTearDown(nextCore.dispose);
        expect(next.findProduct(ids[0]), isNull);
        await next.restoreCustomerState();
        expect(next.quantityFor(ids[0]), 1);
        expect(next.isSaved(ids[1]), isTrue);
        expect(next.savedProductsFor(BuyV2Destination.shop).single.id, ids[1]);
        expect(
          next.recentlyViewedProductsFor(BuyV2Destination.shop).single.id,
          ids[2],
        );
        expect(next.product(ids[0]).storeId, source.storeIdAt(1));
        expect(saved.cartQuantities[ids[0]], 1);
      },
    );

    test('all page controllers share two source request slots', () async {
      final source = _PagingRecoverySource()..holdProducts = true;
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        reviewDataEnabled: false,
        cataloguePageSource: source,
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final a = session.acquireCatalogueProducts('a');
      final b = session.acquireCatalogueProducts('b');
      final c = session.acquireCatalogueProducts('c');
      final first = a.open(storeQuery(source, 0));
      final second = b.open(storeQuery(source, 1));
      final third = c.open(storeQuery(source, 2));
      final changed = c.open(storeQuery(source, 3));
      expect(source.productRequests.length, 2);
      expect(session.catalogueRequestsInFlight, 2);
      source.productGates.first.complete();
      await Future<void>.delayed(Duration.zero);
      expect(source.productRequests.length, 3);
      expect(source.productRequests.last.storeId, source.storeIdAt(3));
      expect(source.peak, 2);
      source.productGates[1].complete();
      source.productGates[2].complete();
      await Future.wait([first, second, third, changed]);
      expect(session.catalogueRequestsInFlight, 0);
      expect(c.page!.items.first.storeId, source.storeIdAt(3));
    });

    test(
      'wrong branch response is rejected before it enters product identity cache',
      () async {
        final source = _PagingRecoverySource()..wrongBranch = true;
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          cataloguePageSource: source,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final pager = session.acquireCatalogueProducts('store');
        await pager.open(storeQuery(source, 0));
        expect(pager.page, isNull);
        expect(pager.message, isNotNull);
        expect(session.pagedProductCount, 0);
        source.wrongBranch = false;
        await pager.retry();
        expect(pager.page!.items.first.storeId, source.storeIdAt(0));
      },
    );

    test(
      'failed Store refresh withdraws capability without an older cached page restoring it',
      () async {
        final source = _PagingRecoverySource();
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          cataloguePageSource: source,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final stores = session.acquireCatalogueStores('stores');
        await stores.open(storeQuery(source, 0));
        final store = stores.page!.items.single;
        final product = store.previewProduct!;
        expect(
          session.productFactsFor(product).storeCollection!.supportsCollection,
          isTrue,
        );
        source.failStores = true;
        expect(
          await session.refreshCatalogueStore(store.id, product.destination),
          isNull,
        );
        expect(session.productFactsFor(product).storeCollection, isNull);
        final products = session.acquireCatalogueProducts('products');
        await products.open(storeQuery(source, 0));
        expect(session.productFactsFor(product).storeCollection, isNull);
        source.failStores = false;
        expect(
          await session.refreshCatalogueStore(store.id, product.destination),
          isNotNull,
        );
        expect(
          session.productFactsFor(product).storeCollection!.supportsCollection,
          isTrue,
        );
      },
    );

    test(
      'inactive query windows stay bounded and retain their active return offset',
      () async {
        final source = _PagingRecoverySource();
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          cataloguePageSource: source,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final current = session.acquireCatalogueProducts('current');
        await current.open(storeQuery(source, 0));
        current.scrollOffset = 123;
        for (var i = 1; i <= 7; i++) {
          final key = 'store-$i';
          final pager = session.acquireCatalogueProducts(key);
          await pager.open(storeQuery(source, i));
          session.releaseCatalogueProducts(key);
        }
        expect(session.pagedProductCount, lessThanOrEqualTo(200));
        session.releaseCatalogueProducts('current');
        final restored = session.acquireCatalogueProducts('current');
        expect(restored, same(current));
        expect(restored.scrollOffset, 123);
        expect(restored.page!.items.first.storeId, source.storeIdAt(0));
      },
    );

    test(
      'Store browse return retains one exact branch after page eviction',
      () async {
        final source = _PagingRecoverySource();
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          cataloguePageSource: source,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final firstPage = session.acquireCatalogueProducts('first-store');
        await firstPage.open(storeQuery(source, 0));
        final first = firstPage.page!.items.first;
        session.retainCatalogueStoreBrowse(first);
        session.releaseCatalogueProducts('first-store');
        BuyV2Product? replacement;
        for (var index = 1; index <= 7; index++) {
          final key = 'store-$index';
          final pager = session.acquireCatalogueProducts(key);
          final query = storeQuery(source, index);
          await pager.open(query);
          replacement = pager.page!.items.first;
          expect(session.retainedCatalogueQuery(key), query);
          session.releaseCatalogueProducts(key);
        }
        expect(firstPage.isDisposed, isTrue);
        expect(session.product(first.id).storeId, first.storeId);
        expect(session.pagedProductCount, lessThanOrEqualTo(161));
        final otherBranch = replacement!.copyWith(seller: first.seller);
        expect(otherBranch.isFromSameStoreAs(first), isFalse);
        session.retainCatalogueStoreBrowse(otherBranch);
        expect(session.findProduct(first.id), isNull);
        final catalogue = session.partnerCatalogueFor(otherBranch);
        expect(catalogue, isNotEmpty);
        expect(
          catalogue.every((item) => item.storeId == otherBranch.storeId),
          isTrue,
        );
        expect(session.pagedProductCount, lessThanOrEqualTo(160));
        final destination = session.destination;
        expect(session.categoriesFor(BuyV2Destination.wholesale), isNotEmpty);
        expect(session.destination, destination);
      },
    );
  });

  group('R5 catalogue session recovery', () {
    test(
      'failed restore retains the durable snapshot and retries in batches of 50',
      () async {
        final source = _PagingRecoverySource()..failResolution = true;
        final ids = List.generate(123, (index) => source.productIdAt(0, index));
        final snapshot = BuyV2CustomerStateSnapshot(
          cartQuantities: {for (final id in ids) id: 1},
          savedProductKeys: {'shop|listing:${Uri.encodeComponent(ids.last)}'},
          recentlyViewedProductIds: [ids.first],
        );
        final store = _MemoryCustomerStateStore('batch-account')
          ..snapshot = snapshot;
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          cataloguePageSource: source,
          customerStateStore: store,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        await session.restoreCustomerState();
        expect(store.snapshot, same(snapshot));
        expect(session.pagedProductCount, 0);
        expect(session.notice, contains('could not be restored'));
        source.failResolution = false;
        source.resolutionRequests.clear();
        await session.restoreCustomerState();
        expect(source.resolutionRequests.map((ids) => ids.length), [
          50,
          50,
          23,
        ]);
        expect(ids.every((id) => session.quantityFor(id) == 1), isTrue);
        expect(
          session.savedProductsFor(BuyV2Destination.shop).single.id,
          ids.last,
        );
        expect(
          session.recentlyViewedProductsFor(BuyV2Destination.shop).single.id,
          ids.first,
        );
      },
    );

    for (final dispose in [false, true]) {
      test(
        'late restore is discarded after ${dispose ? 'dispose' : 'new customer action'}',
        () async {
          final source = _PagingRecoverySource()
            ..resolutionGate = Completer<void>();
          final id = source.productIdAt(0, 0);
          final store = _MemoryCustomerStateStore('late-account')
            ..snapshot = BuyV2CustomerStateSnapshot(cartQuantities: {id: 1});
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            reviewDataEnabled: true,
            cataloguePageSource: source,
            customerStateStore: store,
          );
          addTearDown(core.dispose);
          final restore = session.restoreCustomerState();
          await Future<void>.delayed(Duration.zero);
          expect(source.resolutionRequests.length, 1);
          if (dispose) {
            session.dispose();
          } else {
            addTearDown(session.dispose);
            final localId = BuyV2Catalogue.products.first.id;
            expect(session.addProduct(localId), isTrue);
            expect(session.quantityFor(localId), 1);
          }
          source.resolutionGate!.complete();
          await restore;
          expect(session.pagedProductCount, 0);
          expect(session.quantityFor(id), 0);
        },
      );
    }

    test(
      'a recent product return survives older inactive Store contexts',
      () async {
        final source = _PagingRecoverySource();
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          cataloguePageSource: source,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final stores = <BuyV2CataloguePager<BuyV2StoreListing>>[];
        for (var i = 0; i < 4; i++) {
          final pager = session.acquireCatalogueStores('stores-$i');
          await pager.open(
            BuyV2CatalogueQuery(
              destination: BuyV2Destination.shop,
              regionId: null,
              storeId: source.storeIdAt(i),
            ),
          );
          stores.add(pager);
          session.releaseCatalogueStores('stores-$i');
        }
        final products = session.acquireCatalogueProducts('products');
        await products.open(
          BuyV2CatalogueQuery(
            destination: BuyV2Destination.shop,
            regionId: null,
            storeId: source.storeIdAt(5),
          ),
        );
        products.scrollOffset = 88;
        session.releaseCatalogueProducts('products');
        expect(stores.first.isDisposed, isTrue);
        expect(products.isDisposed, isFalse);
        expect(session.acquireCatalogueProducts('products'), same(products));
        expect(products.scrollOffset, 88);
      },
    );
  });

  group('R5 development catalogue source', () {
    BuyV2CatalogueQuery all(
      BuyV2Destination destination, {
      String? storeId,
      String categoryId = 'all',
      bool offersOnly = false,
      String query = '',
    }) => BuyV2CatalogueQuery(
      destination: destination,
      regionId: null,
      areaScope: BuyV2CatalogueAreaScope.allAreas,
      storeId: storeId,
      categoryId: categoryId,
      offersOnly: offersOnly,
      query: query,
    );

    test('100000 providers materialize only each requested page', () async {
      final source = BuyV2DevelopmentCatalogueSource(
        destination: BuyV2Destination.shop,
      );
      final query = all(BuyV2Destination.shop);
      var page = await source.loadStores(query, pageSize: 50);
      expect(page.totalCount, 100000);
      expect(source.storeObjectsCreated, 50);
      expect(source.productObjectsCreated, 50);
      var index = 0;
      while (true) {
        for (final store in page.items) {
          expect(store.id, source.storeIdAt(index));
          expect(store.previewProduct!.storeId, store.id);
          expect(store.distanceMeters, isNull);
          index += 1;
        }
        if (page.nextCursor == null) break;
        page = await source.loadStores(
          query,
          cursor: page.nextCursor,
          pageSize: 50,
        );
      }
      expect(index, 100000);
      expect(page.items.last.id, source.storeIdAt(99999));
      expect(source.storeObjectsCreated, 100000);
      expect(source.productObjectsCreated, 100000);
    });

    for (final destination in [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
    ]) {
      test(
        '5000 exact SKUs and category/offer pages for ${destination.name}',
        () async {
          final source = BuyV2DevelopmentCatalogueSource(
            destination: destination,
          );
          final store = source.storeIdAt(99999);
          final query = all(destination, storeId: store);
          var page = await source.loadProducts(query, pageSize: 50);
          expect(page.totalCount, 5000);
          expect(source.productObjectsCreated, 50);
          final categoryCounts = <String, int>{};
          var index = 0;
          while (true) {
            for (final product in page.items) {
              expect(product.id, source.productIdAt(99999, index));
              expect(product.storeId, store);
              expect(product.destination, destination);
              categoryCounts.update(
                product.categoryId,
                (value) => value + 1,
                ifAbsent: () => 1,
              );
              index += 1;
            }
            if (page.nextCursor == null) break;
            page = await source.loadProducts(
              query,
              cursor: page.nextCursor,
              pageSize: 50,
            );
          }
          expect(index, 5000);
          final last = page.items.last;
          final resolved = await source.resolveProducts({
            last.id,
            'unknown-product',
          });
          expect(resolved.single.id, last.id);
          expect(resolved.single.storeId, store);
          expect(resolved.single.pack, last.pack);
          for (final entry in categoryCounts.entries) {
            final category = all(
              destination,
              storeId: store,
              categoryId: entry.key,
            );
            var categoryPage = await source.loadProducts(
              category,
              pageSize: 50,
            );
            expect(categoryPage.totalCount, entry.value);
            var seen = 0;
            final ids = <String>{};
            while (true) {
              for (final product in categoryPage.items) {
                expect(product.categoryId, entry.key);
                expect(ids.add(product.id), isTrue);
                seen += 1;
              }
              if (categoryPage.nextCursor == null) break;
              categoryPage = await source.loadProducts(
                category,
                cursor: categoryPage.nextCursor,
                pageSize: 50,
              );
            }
            expect(seen, entry.value);
          }
          final offers = await source.loadProducts(
            all(destination, storeId: store, offersOnly: true),
            pageSize: 50,
          );
          expect(offers.totalCount, 1000);
          expect(offers.items.map((p) => p.id), [
            for (var i = 0; i < 50; i++) source.productIdAt(99999, i * 5),
          ]);
        },
      );
    }

    test(
      '500 million logical listings create just 40 product objects',
      () async {
        final source = BuyV2DevelopmentCatalogueSource(
          destination: BuyV2Destination.shop,
        );
        final page = await source.loadProducts(
          all(BuyV2Destination.shop),
          pageSize: 40,
        );
        expect(page.totalCount, 500000000);
        expect(page.items.length, 40);
        expect(source.productObjectsCreated, 40);
        expect(source.storeObjectsCreated, 0);
      },
    );

    test(
      'regional and national serviceability are explicit and unknown area stays empty',
      () async {
        final source = BuyV2DevelopmentCatalogueSource(
          destination: BuyV2Destination.shop,
          providerCount: 20,
        );
        BuyV2CatalogueQuery query(
          String? region,
          BuyV2CatalogueAreaScope scope,
        ) => BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: region,
          areaScope: scope,
        );
        final local = await source.loadStores(
          query('jaipur', BuyV2CatalogueAreaScope.regional),
          pageSize: 50,
        );
        expect(local.items.map((s) => s.id), [
          source.storeIdAt(1),
          source.storeIdAt(11),
        ]);
        final national = await source.loadStores(
          query('jaipur', BuyV2CatalogueAreaScope.national),
          pageSize: 50,
        );
        final ids = national.items.map((s) => s.id);
        expect(ids, contains(source.storeIdAt(3)));
        // Provider0 is nationwide except Jaipur in this versioned fixture.
        expect(ids, isNot(contains(source.storeIdAt(0))));
        expect(ids, isNot(contains(source.storeIdAt(2))));
        final unknown = await source.loadStores(
          query(null, BuyV2CatalogueAreaScope.national),
          pageSize: 50,
        );
        expect(unknown.totalCount, 0);
        expect(unknown.items, isEmpty);
        expect(unknown.nextCursor, isNull);
      },
    );

    test(
      'store-name search and collection capability use exact branch',
      () async {
        final source = BuyV2DevelopmentCatalogueSource(
          destination: BuyV2Destination.shop,
          providerCount: 20,
        );
        final stores = await source.loadStores(
          all(BuyV2Destination.shop, query: 'Mool Market 000004'),
          pageSize: 40,
        );
        expect(stores.items.single.id, source.storeIdAt(3));
        expect(stores.items.single.collection!.supportsCollection, isFalse);
        final supported = await source.loadStores(
          BuyV2CatalogueQuery(
            destination: BuyV2Destination.shop,
            regionId: null,
            areaScope: BuyV2CatalogueAreaScope.allAreas,
            collectionOnly: true,
          ),
          pageSize: 40,
        );
        expect(
          supported.items.any((s) => s.id == source.storeIdAt(3)),
          isFalse,
        );
        expect(
          supported.items.every((s) => s.collection!.supportsCollection),
          isTrue,
        );
        final empty = await source.loadProducts(
          all(BuyV2Destination.shop, storeId: 'unknown-store'),
          pageSize: 40,
        );
        expect(empty.items, isEmpty);
      },
    );

    test(
      'cursor cannot cross query, page size, cohort or product identities',
      () async {
        final source = BuyV2DevelopmentCatalogueSource(
          destination: BuyV2Destination.shop,
        );
        final query = all(BuyV2Destination.shop, storeId: source.storeIdAt(0));
        final first = await source.loadProducts(query, pageSize: 40);
        final another = all(
          BuyV2Destination.shop,
          storeId: source.storeIdAt(1),
        );
        await expectLater(
          source.loadProducts(another, cursor: first.nextCursor, pageSize: 40),
          throwsFormatException,
        );
        await expectLater(
          source.loadProducts(query, cursor: first.nextCursor, pageSize: 50),
          throwsFormatException,
        );
        final changed = BuyV2DevelopmentCatalogueSource(
          destination: BuyV2Destination.shop,
          providerCount: 10,
        );
        await expectLater(
          changed.loadProducts(query, cursor: first.nextCursor, pageSize: 40),
          throwsFormatException,
        );
        await expectLater(
          source.loadProducts(query, cursor: 'not-a-cursor', pageSize: 40),
          throwsFormatException,
        );
        await expectLater(
          source.resolveProducts({
            for (var i = 0; i < 51; i++) source.productIdAt(0, i),
          }),
          throwsArgumentError,
        );
        final wrongDestination = BuyV2DevelopmentCatalogueSource(
          destination: BuyV2Destination.wholesale,
        );
        expect(
          await wrongDestination.resolveProducts({source.productIdAt(0, 0)}),
          isEmpty,
        );
      },
    );
  });

  group('R5 bounded catalogue paging', () {
    final query = BuyV2CatalogueQuery(
      destination: BuyV2Destination.shop,
      regionId: 'jodhpur',
    );

    BuyV2CataloguePage<String> pageFor(
      BuyV2CatalogueQuery query, {
      String? cursor,
      required int pageSize,
      int count = 125,
      String snapshot = 'catalogue-v1',
      bool unknownTotal = false,
    }) {
      final start = cursor == null ? 0 : int.parse(cursor);
      final end = (start + pageSize).clamp(0, count);
      return BuyV2CataloguePage(
        queryKey: query.key,
        snapshotId: snapshot,
        startIndex: start,
        totalCount: unknownTotal ? null : count,
        previousCursor: start == 0
            ? null
            : '${(start - pageSize).clamp(0, count)}',
        nextCursor: end < count ? '$end' : null,
        items: [for (var i = start; i < end; i++) 'listing-$i'],
      );
    }

    test(
      'keeps page viewport on Back and forgets evicted or refreshed pages',
      () async {
        final pager = BuyV2CataloguePager<String>(
          identityOf: (item) => item,
          load: (q, {cursor, required pageSize}) async =>
              pageFor(q, cursor: cursor, pageSize: pageSize, count: 5000),
        );
        addTearDown(pager.dispose);
        await pager.open(query);
        pager.scrollOffset = 88;
        pager.rememberLaneOffset(0, 140);
        pager.rememberLaneOffset(1, 75);
        await pager.next();
        expect(pager.scrollOffset, 0);
        expect(pager.laneOffset(0), 0);
        pager.scrollOffset = 34;
        pager.rememberLaneOffset(0, 200);
        // The opaque previous cursor '0' aliases the original null-cursor page.
        await pager.previous();
        expect(pager.scrollOffset, 88);
        expect(pager.laneOffset(0), 140);
        expect(pager.laneOffset(1), 75);
        pager.scrollOffset = double.nan;
        pager.rememberLaneOffset(0, -1);
        expect(pager.scrollOffset, 88);
        expect(pager.laneOffset(0), 140);
        await pager.next();
        expect(pager.scrollOffset, 34);
        expect(pager.laneOffset(0), 200);
        await pager.next();
        await pager.next();
        await pager.open(query, cursor: '0');
        expect(pager.cachedPageCount, lessThanOrEqualTo(3));
        expect(pager.scrollOffset, 0);
        expect(pager.laneOffset(0), 0);
        pager.scrollOffset = 45;
        pager.rememberLaneOffset(1, 60);
        await pager.refresh();
        expect(pager.scrollOffset, 0);
        expect(pager.laneOffset(1), 0);
        pager.scrollOffset = 15;
        await pager.open(
          BuyV2CatalogueQuery(
            destination: BuyV2Destination.shop,
            regionId: 'mumbai',
          ),
        );
        expect(pager.scrollOffset, 0);
      },
    );

    for (final count in [5000, 100000]) {
      test('reaches every one of $count listings with bounded pages', () async {
        var requests = 0;
        final pager = BuyV2CataloguePager<String>(
          identityOf: (item) => item,
          load: (q, {cursor, required pageSize}) async {
            requests += 1;
            return pageFor(q, cursor: cursor, pageSize: pageSize, count: count);
          },
        );
        addTearDown(pager.dispose);
        await pager.open(query);
        var expected = 0;
        while (true) {
          final page = pager.page!;
          expect(page.startIndex, expected);
          for (final item in page.items) {
            expect(item, 'listing-$expected');
            expected += 1;
          }
          expect(pager.cachedPageCount, lessThanOrEqualTo(3));
          expect(pager.retainedItemCount, lessThanOrEqualTo(120));
          if (page.nextCursor == null) break;
          await pager.next();
        }
        expect(expected, count);
        expect(requests, (count / 40).ceil());
        final lastRequests = requests;
        await pager.next();
        expect(requests, lastRequests);
        // Back across an evicted boundary reloads its exact previous page.
        for (var i = 0; i < 4; i++) {
          await pager.previous();
        }
        expect(pager.page!.startIndex, count - 200);
        expect(pager.page!.items.first, 'listing-${count - 200}');
        expect(pager.retainedItemCount, lessThanOrEqualTo(120));
        expect(requests, greaterThan(lastRequests));
      });
    }

    test(
      'coalesces filter changes and discards the obsolete response',
      () async {
        final requests = <BuyV2CatalogueQuery>[];
        final completions = <Completer<BuyV2CataloguePage<String>>>[];
        final pager = BuyV2CataloguePager<String>(
          identityOf: (item) => item,
          load: (q, {cursor, required pageSize}) {
            requests.add(q);
            final result = Completer<BuyV2CataloguePage<String>>();
            completions.add(result);
            return result.future;
          },
        );
        addTearDown(pager.dispose);
        final first = pager.open(query);
        final intermediate = BuyV2CatalogueQuery(
          destination: BuyV2Destination.wholesale,
          regionId: 'jaipur',
          categoryId: 'rice',
        );
        final latest = BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: 'delhi',
          areaScope: BuyV2CatalogueAreaScope.national,
          storeId: 'branch-b',
          query: 'milk',
          offersOnly: true,
        );
        final second = pager.open(intermediate);
        final third = pager.open(latest);
        expect(requests, [query]);
        expect(pager.page, isNull);
        completions.first.complete(pageFor(query, pageSize: 40));
        await Future<void>.delayed(Duration.zero);
        expect(requests, [query, latest]);
        expect(pager.page, isNull);
        completions.last.complete(pageFor(latest, pageSize: 40, count: 3));
        await Future.wait([first, second, third]);
        expect(pager.page!.queryKey, latest.key);
        expect(pager.page!.items.length, 3);
        expect(pager.cachedPageCount, 1);
        expect(pager.loading, isFalse);
      },
    );

    test('deduplicates next requests and preserves rows on retry', () async {
      var calls = 0;
      var fail = true;
      final pager = BuyV2CataloguePager<String>(
        identityOf: (item) => item,
        load: (q, {cursor, required pageSize}) async {
          calls += 1;
          if (cursor == '40' && fail) {
            fail = false;
            throw StateError('Connection unavailable');
          }
          return pageFor(q, cursor: cursor, pageSize: pageSize);
        },
      );
      addTearDown(pager.dispose);
      await pager.open(query);
      final original = pager.page;
      final first = pager.next();
      final duplicate = pager.next();
      await Future.wait([first, duplicate]);
      expect(calls, 2);
      expect(pager.page, same(original));
      expect(pager.message, isNotNull);
      await pager.retry();
      expect(calls, 3);
      expect(pager.page!.startIndex, 40);
      expect(pager.message, isNull);
      await pager.previous();
      // The previous cursor is opaque; "0" is not the initial null cursor.
      expect(calls, 4);
      expect(pager.page!.startIndex, original!.startIndex);
      expect(pager.page!.items, original.items);
    });

    for (final invalid in [
      'query',
      'snapshot',
      'gap',
      'duplicate',
      'too-many',
      'loop',
      'count',
      'missing-next',
      'missing-previous',
      'empty-with-next',
    ]) {
      test('rejects $invalid page without losing current rows', () async {
        final pager = BuyV2CataloguePager<String>(
          identityOf: (item) => item,
          load: (q, {cursor, required pageSize}) async {
            if (cursor == null) return pageFor(q, pageSize: pageSize);
            return BuyV2CataloguePage(
              queryKey: invalid == 'query' ? 'another-query' : q.key,
              snapshotId: invalid == 'snapshot' ? 'changed' : 'catalogue-v1',
              startIndex: invalid == 'gap' ? 41 : 40,
              totalCount: invalid == 'count' ? 79 : 125,
              previousCursor: invalid == 'missing-previous' ? null : '0',
              nextCursor: invalid == 'missing-next'
                  ? null
                  : invalid == 'loop'
                  ? '40'
                  : '80',
              items: invalid == 'empty-with-next'
                  ? []
                  : [
                      for (
                        var i = 40;
                        i < (invalid == 'too-many' ? 81 : 80);
                        i++
                      )
                        invalid == 'duplicate' && i == 40
                            ? 'listing-0'
                            : 'listing-$i',
                    ],
            );
          },
        );
        addTearDown(pager.dispose);
        await pager.open(query);
        final original = pager.page;
        await pager.next();
        expect(pager.page, same(original));
        expect(pager.message, isNotNull);
        expect(pager.cachedPageCount, 1);
      });
    }

    test(
      'unknown totals end only at the final cursor and refresh resets snapshot',
      () async {
        var snapshot = 'catalogue-v1';
        final pager = BuyV2CataloguePager<String>(
          identityOf: (item) => item,
          load: (q, {cursor, required pageSize}) async => pageFor(
            q,
            cursor: cursor,
            pageSize: pageSize,
            count: 43,
            snapshot: snapshot,
            unknownTotal: true,
          ),
        );
        addTearDown(pager.dispose);
        await pager.open(query);
        expect(pager.page!.totalCount, isNull);
        await pager.next();
        expect(pager.page!.items.length, 3);
        expect(pager.page!.nextCursor, isNull);
        snapshot = 'catalogue-v2';
        await pager.refresh();
        expect(pager.page!.snapshotId, snapshot);
        expect(pager.page!.startIndex, 0);
        expect(pager.cachedPageCount, 1);
      },
    );

    test('query identity covers geography and commerce refinements', () {
      final same = BuyV2CatalogueQuery(
        destination: BuyV2Destination.shop,
        regionId: 'jodhpur',
        query: ' MILK  POUCH ',
        brands: {'B', 'A'},
      );
      final reordered = BuyV2CatalogueQuery(
        destination: BuyV2Destination.shop,
        regionId: 'jodhpur',
        query: 'milk pouch',
        brands: {'A', 'B'},
      );
      expect(same, reordered);
      final changed = [
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.wholesale,
          regionId: 'jodhpur',
        ),
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: 'jaipur',
        ),
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: 'jodhpur',
          storeId: 'store-a',
        ),
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: 'jodhpur',
          categoryId: 'milk',
        ),
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: 'jodhpur',
          sort: BuyV2ProductSort.priceLowToHigh,
        ),
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: 'jodhpur',
          offersOnly: true,
        ),
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: 'jodhpur',
          collectionOnly: true,
        ),
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: 'jodhpur',
          maximumPrice: 100,
        ),
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: 'jodhpur',
          availableOnly: true,
        ),
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.shop,
          regionId: 'jodhpur',
          areaScope: BuyV2CatalogueAreaScope.allAreas,
        ),
      ];
      expect(changed.map((q) => q.key).toSet().length, changed.length);
      expect(changed.any((q) => q == query), isFalse);
    });

    test('dispose prevents late source completion from notifying', () async {
      final completion = Completer<BuyV2CataloguePage<String>>();
      final pager = BuyV2CataloguePager<String>(
        identityOf: (item) => item,
        load: (q, {cursor, required pageSize}) => completion.future,
      );
      var notifications = 0;
      pager.addListener(() => notifications += 1);
      final pending = pager.open(query);
      expect(notifications, 1);
      pager.dispose();
      completion.complete(pageFor(query, pageSize: 40));
      await pending;
      expect(notifications, 1);
      expect(pager.page, isNull);
      expect(pager.cachedPageCount, 0);
    });
  });

  group('BuyV2Session approved contract', () {
    late BuyV2Session session;

    setUp(() {
      session = BuyV2Session(core: BuySession());
    });

    test(
      'R5 020 changing purchase mode removes conflicting delivery state',
      () {
        session.addProduct('w-rice');
        final otherQuantity = session.quantityFor('w-rice');
        session.chooseMaximumProductPrice(250);
        session.chooseFulfilmentMode(BuyV2FulfilmentMode.standardCourier);
        session.chooseShopSaleType(BuyV2ShopSaleType.quickDelivery);
        expect(session.selectedFulfilmentMode, isNull);
        expect(session.catalogueSaleTypeProducts, isNotEmpty);
        expect(session.maximumProductPrice, 250);
        expect(session.quantityFor('w-rice'), otherQuantity);
        expect(
          session.catalogueSaleTypeProducts.every(
            (product) =>
                session.fulfilmentModeFor(product) ==
                BuyV2FulfilmentMode.quickLocal,
          ),
          isTrue,
        );
      },
    );

    test('R5 020 Any clears legacy delivery state while preserving price', () {
      session.chooseMaximumProductPrice(250);
      session.chooseFulfilmentMode(BuyV2FulfilmentMode.standardCourier);
      session.chooseFilter(null);
      expect(session.selectedFilter, isNull);
      expect(session.selectedFulfilmentMode, isNull);
      expect(session.maximumProductPrice, 250);
      expect(session.shopSaleType, BuyV2ShopSaleType.courier);
    });

    test('R5 020 brand facets describe the current category and search', () {
      final product = session.product('s-milk');
      session.chooseShopSaleType(
        session.fulfilmentModeFor(product) == BuyV2FulfilmentMode.quickLocal
            ? BuyV2ShopSaleType.quickDelivery
            : BuyV2ShopSaleType.courier,
      );
      session.chooseCategory(product.categoryId);
      session.updateQuery(product.title);
      final actualBrands = session.catalogueSaleTypeProducts
          .map((product) => product.brand)
          .toSet();
      expect(actualBrands, isNotEmpty);
      expect(session.discoveryBrands.toSet(), actualBrands);
    });

    test('R5 020 draft preview is pure and Apply emits one update', () async {
      final store = _MemoryCustomerStateStore('refinement-draft');
      final core = BuySession();
      final current = BuyV2Session(core: core, customerStateStore: store);
      addTearDown(core.dispose);
      addTearDown(current.dispose);
      await current.restoreCustomerState();
      current.addProduct('w-rice');
      await Future<void>.delayed(Duration.zero);
      final stored = store.snapshot;
      final quantity = current.quantityFor('w-rice');
      var notifications = 0;
      current.addListener(() => notifications++);
      final draft = BuyV2DiscoveryRefinements(
        maximumPrice: 250,
        sort: BuyV2ProductSort.priceLowToHigh,
      );
      final expected = BuyV2Catalogue.allProducts
          .where(
            (product) =>
                product.destination == BuyV2Destination.shop &&
                product.catalogueListing &&
                current.fulfilmentModeFor(product) ==
                    BuyV2FulfilmentMode.quickLocal &&
                current.productFactsFor(product).price <= 250,
          )
          .map((p) => p.id)
          .toSet();
      final preview = current.previewDiscoveryProducts(draft);
      expect(preview.map((p) => p.id).toSet(), expected);
      expect(preview, isNotEmpty);
      expect(current.maximumProductPrice, isNull);
      expect(current.productSort, BuyV2ProductSort.relevance);
      expect(notifications, 0);
      expect(identical(store.snapshot, stored), isTrue);
      current.applyDiscoveryRefinements(draft);
      expect(notifications, 1);
      expect(
        current.catalogueSaleTypeProducts.map((p) => p.id),
        orderedEquals(preview.map((p) => p.id)),
      );
      expect(current.quantityFor('w-rice'), quantity);
      expect(identical(store.snapshot, stored), isTrue);
    });

    test('R5 020 Wholesale mode clears a contradictory legacy pack filter', () {
      session.openDestination(BuyV2Destination.wholesale);
      session.choosePackFilter(BuyV2PackFilter.bulk);
      session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.wholesale);
      expect(session.selectedPackFilter, isNull);
      expect(session.catalogueSaleTypeProducts, isNotEmpty);
      expect(
        session.catalogueSaleTypeProducts.every((p) => p.minimumOrder <= 2),
        isTrue,
      );
    });

    test(
      'R5 020 old account filters do not hide the fresh catalogue',
      () async {
        final store = _MemoryCustomerStateStore('old-refinement-account')
          ..snapshot = const BuyV2CustomerStateSnapshot(
            cartQuantities: {'s-milk': 1},
            selectedPayment: 'Paytm',
            selectedBrands: {'UNAVAILABLE OLD BRAND'},
            maximumPrice: 1,
            packFilter: 'bulk',
            fulfilmentMode: 'bulkFreight',
            productSort: 'deliveryFastest',
            availableOnly: true,
            recentlyViewedProductIds: ['s-milk'],
          );
        final core = BuySession();
        final restored = BuyV2Session(core: core, customerStateStore: store);
        addTearDown(core.dispose);
        addTearDown(restored.dispose);
        await restored.restoreCustomerState();
        expect(restored.activeDiscoveryRefinementCount, 0);
        expect(restored.catalogueSaleTypeProducts, isNotEmpty);
        expect(restored.quantityFor('s-milk'), 1);
        expect(restored.selectedPayment, 'Paytm');
        expect(
          restored
              .recentlyViewedProductsFor(BuyV2Destination.shop)
              .map((p) => p.id),
          ['s-milk'],
        );
      },
    );

    test('keeps definitive Shop, Wholesale and Medicine taxonomies', () {
      expect(BuyV2Catalogue.shopCategories.length, 35);
      expect(BuyV2Catalogue.wholesaleCategories.length, 35);
      expect(BuyV2Catalogue.medicineCategories.length, 14);
      expect(
        sha256.convert(utf8.encode(buyV2CommerceSeedRows.trim())).toString(),
        'b591438729cd4d0eb2a44101ffd6701c7892abd6e53596f9d1019b322e7e30ac',
      );

      const approvedCommerceIds = <String>[
        'tomato',
        'atta',
        'oil',
        'rice',
        'soap',
        'notebook',
        'onion',
        'milk',
        'bread',
        'eggs',
        'chicken',
        'ghee',
        'turmeric',
        'cumin',
        'poha',
        'oats',
        'noodles',
        'pasta',
        'biscuits',
        'namkeen',
        'tea',
        'juice',
        'peas',
        'ice-cream',
        'toothpaste',
        'shampoo',
        'face-wash',
        'floor-cleaner',
        'toilet-cleaner',
        'detergent',
        'dishwash',
        'diapers',
        'baby-wipes',
        'chyawanprash',
        'protein',
        'dog-food',
        'cat-food',
        'foil',
        'paper-cups',
        'thermal-rolls',
        'price-labels',
        'pencils',
        'banana',
        'potato',
        'curd',
        'paneer',
        'fish-fillet',
        'mutton',
        'toor-dal',
        'sugar',
        'mustard-oil',
        'groundnut-oil',
        'red-chilli',
        'coriander-seeds',
        'corn-flakes',
        'idli-mix',
        'ketchup',
        'jam',
        'potato-chips',
        'chocolate',
        'coffee',
        'water',
        'frozen-fries',
        'cheese-slices',
        'toothbrush',
        'handwash',
        'moisturizer',
        'hair-oil',
        'garbage-bags',
        'air-freshener',
        'fabric-conditioner',
        'liquid-detergent',
        'baby-lotion',
        'baby-cereal',
        'glucose',
        'sanitary-pads',
        'dog-treats',
        'cat-litter',
        'tissues',
        'takeaway-containers',
        'barcode-labels',
        'carry-bags',
        'printer-paper',
        'ball-pens',
      ];
      final shopProducts = BuyV2Catalogue.products
          .where((item) => item.destination == BuyV2Destination.shop)
          .toList();
      final wholesaleProducts = BuyV2Catalogue.products
          .where((item) => item.destination == BuyV2Destination.wholesale)
          .toList();
      expect(
        shopProducts.map((item) => item.canonicalId).toSet(),
        approvedCommerceIds.toSet(),
      );
      expect(
        wholesaleProducts.map((item) => item.canonicalId).toSet(),
        approvedCommerceIds.toSet(),
      );
      for (final canonicalId in approvedCommerceIds) {
        final offers = BuyV2Catalogue.products
            .where((item) => item.canonicalId == canonicalId)
            .toList();
        expect(offers.length, greaterThanOrEqualTo(2), reason: canonicalId);
        expect(offers.map((item) => item.destination).toSet(), {
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
        }, reason: canonicalId);
      }

      final identities = BuyV2Catalogue.products
          .map((item) => item.id)
          .toList();
      expect(identities.toSet().length, identities.length);
      expect(
        BuyV2Catalogue.shopCategories
            .skip(1)
            .every(
              (category) => BuyV2Catalogue.products.any(
                (product) =>
                    product.destination == BuyV2Destination.shop &&
                    product.categoryId == category.id,
              ),
            ),
        isTrue,
      );
      expect(
        BuyV2Catalogue.wholesaleCategories
            .skip(1)
            .every(
              (category) => BuyV2Catalogue.products.any(
                (product) =>
                    product.destination == BuyV2Destination.wholesale &&
                    product.categoryId == category.id,
              ),
            ),
        isTrue,
      );
    });

    test('supports Shop, Wholesale and Medicine in one cart', () {
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

      expect(session.addProduct(shop.id), isTrue);
      expect(session.addProduct(wholesale.id), isTrue);
      expect(session.addProduct(medicine.id), isTrue);

      expect(session.countForDestination(BuyV2Destination.shop), 1);
      expect(
        session.countForDestination(BuyV2Destination.wholesale),
        wholesale.minimumOrder,
      );
      expect(session.countForDestination(BuyV2Destination.medicine), 1);
      expect(
        session.cartLines.map((line) => line.product.id),
        containsAll([shop.id, wholesale.id, medicine.id]),
      );
    });

    test('maps every Buy offer to a customer-facing partner role', () {
      for (final product in BuyV2Catalogue.products) {
        expect(product.partnerRole, startsWith('Mool'), reason: product.id);
        expect(
          product.partnerRole.toLowerCase(),
          isNot(contains('verified')),
          reason: product.id,
        );
      }
      expect(
        BuyV2Catalogue.products
            .firstWhere((item) => item.destination == BuyV2Destination.medicine)
            .regulatoryTrustFact,
        'Licensed pharmacy',
      );
    });

    test('customer reviews and product reports validate and persist', () {
      final product = BuyV2Catalogue.products.first;
      expect(
        session.submitProductReview(
          productId: product.id,
          rating: 0,
          comment: '',
        ),
        isFalse,
      );
      expect(
        session.submitProductReview(
          productId: product.id,
          rating: 5,
          comment: '  Pack arrived in good condition.  ',
        ),
        isTrue,
      );
      expect(session.customerReviewFor(product.id)?.rating, 5);
      expect(
        session.customerReviewFor(product.id)?.comment,
        'Pack arrived in good condition.',
      );
      expect(
        session.reportProduct(
          productId: product.id,
          reason: 'Product image does not match',
        ),
        isTrue,
      );
      expect(session.hasReportedProduct(product.id), isTrue);
    });

    test('order items retain the exact return depth into product detail', () {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      expect(session.addProduct(product.id), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      expect(session.confirmOrder(), isTrue);
      final order = session.confirmedOrders.single;

      expect(session.openTracking(order.id), isTrue);
      expect(session.openOrderItems(order.id), isTrue);
      final item = session.productsForOrder(session.selectedOrder).first;

      expect(session.openProduct(item.id), isTrue);
      expect(session.view, BuyV2View.product);
      session.goBack();

      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.orderItems);
      expect(session.selectedOrder.id, order.id);
    });

    test('one Shop checkout splits orders by fulfilling store', () {
      final first = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      final second = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.shop &&
            item.seller != first.seller,
      );
      expect(session.addProduct(first.id), isTrue);
      expect(session.addProduct(second.id), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      expect(session.confirmOrder(), isTrue);

      expect(session.confirmedOrders, hasLength(2));
      expect(session.confirmedOrders.map((order) => order.partner).toSet(), {
        first.seller,
        second.seller,
      });
      expect(
        session.confirmedOrders.expand((order) => order.productIds).toSet(),
        {first.id, second.id},
      );
      expect(
        session.confirmedOrders.map((order) => order.purchaseId).toSet(),
        hasLength(1),
      );
      for (final product in [first, second]) {
        final purchased = session.confirmedOrders
            .expand((order) => order.lines)
            .singleWhere((line) => line.product.id == product.id)
            .product;
        expect(purchased.canonicalId, product.canonicalId);
        expect(purchased.title, product.title);
        expect(purchased.variant, product.variant);
        expect(purchased.pack, product.pack);
        expect(purchased.price, product.price);
        expect(purchased.unitPrice, product.unitPrice);
        expect(purchased.seller, product.seller);
        expect(purchased.sellerType, product.sellerType);
        expect(purchased.deliveryPromise, product.deliveryPromise);
        expect(purchased.returnPolicy, product.returnPolicy);
      }
    });

    test(
      'product continuations are deterministic, local and same-catalogue',
      () {
        final current = BuyV2Catalogue.products.firstWhere((product) {
          if (product.destination != BuyV2Destination.shop) return false;
          return BuyV2Catalogue.products
              .where(
                (candidate) =>
                    candidate.destination == product.destination &&
                    candidate.categoryId == product.categoryId &&
                    candidate.id != product.id,
              )
              .isNotEmpty;
        });

        final first = session.productContinuationsFor(current);
        final second = session.productContinuationsFor(current);

        expect(first, isNotEmpty);
        expect(first, hasLength(6));
        expect(first.map((product) => product.id), second.map((p) => p.id));
        expect(first, everyElement(isNot(same(current))));
        expect(
          first,
          everyElement(
            predicate<BuyV2Product>(
              (product) =>
                  product.destination == current.destination &&
                  product.id != current.id,
            ),
          ),
        );
        expect(first.first.categoryId, current.categoryId);
        expect(session.productContinuationsFor(current, limit: 0), isEmpty);
      },
    );

    test('a product chain retains its original query and return depth', () {
      session.updateQuery('tomato');
      final origin = session.visibleProducts.first;
      expect(session.openProduct(origin.id), isTrue);

      final next = session.productContinuationsFor(origin).first;
      expect(session.openProduct(next.id), isTrue);
      final third = session.productContinuationsFor(next).first;
      expect(session.openProduct(third.id), isTrue);

      expect(session.selectedProductId, third.id);
      session.closeProduct();
      expect(session.destination, BuyV2Destination.shop);
      expect(session.view, BuyV2View.catalogue);
      expect(session.query, 'tomato');
      expect(
        session.visibleProducts.map((product) => product.id),
        contains(origin.id),
      );
    });

    test('variant selection replaces only the current product depth', () {
      final original = session.product('s-milk');
      final variants = session.productVariantsFor(original);
      expect(
        variants.map((product) => product.id),
        containsAll(['s-milk', 's-milk-500ml', 's-milk-2l']),
      );

      expect(session.openProduct(original.id), isTrue);
      expect(session.selectProductVariant('s-milk-500ml'), isTrue);
      expect(session.selectedProduct?.id, 's-milk-500ml');
      expect(session.view, BuyV2View.product);
      expect(session.destination, BuyV2Destination.shop);
      expect(session.addProduct('s-milk-500ml'), isTrue);
      expect(session.quantityFor('s-milk-500ml'), 1);
      expect(session.quantityFor('s-milk'), 0);

      expect(session.selectProductVariant('w-milk'), isFalse);
      expect(session.selectedProduct?.id, 's-milk-500ml');
      session.closeProduct();
      expect(session.view, BuyV2View.catalogue);
      expect(session.destination, BuyV2Destination.shop);
    });

    test('one saved prescription unlocks only its matched medicine lines', () {
      const telmisartan = 'm-telmisartan-40';
      const atorvastatin = 'm-atorvastatin-10';
      const metformin = 'm-metformin-500';

      expect(session.addProduct(telmisartan), isFalse);
      expect(session.pendingPrescriptionProductId, telmisartan);

      session.approveSavedPrescription('meera');

      expect(session.quantityFor(telmisartan), 1);
      expect(session.addProduct(atorvastatin), isTrue);
      expect(session.addProduct(metformin), isFalse);
      expect(session.pendingPrescriptionProductId, metformin);
    });

    test(
      'unknown saved prescription IDs authorize nothing and preserve retry',
      () {
        const metformin = 'm-metformin-500';
        expect(session.addProduct(metformin), isFalse);
        expect(session.pendingPrescriptionProductId, metformin);

        expect(
          session.approveSavedPrescription('missing-prescription'),
          isFalse,
        );

        expect(session.prescriptionAttached, isFalse);
        expect(session.isPrescriptionApproved(metformin), isFalse);
        expect(session.isPrescriptionApproved('m-pantoprazole-40'), isFalse);
        expect(session.quantityFor(metformin), 0);
        expect(session.pendingPrescriptionProductId, metformin);
        expect(session.notice, 'This saved prescription could not be found.');

        expect(session.approveSavedPrescription('arvind'), isTrue);
        expect(session.prescriptionAttached, isTrue);
        expect(session.pendingPrescriptionProductId, isNull);
        expect(session.quantityFor(metformin), 1);
      },
    );

    test('prescription quantity cannot exceed the approved medicine line', () {
      const telmisartan = 'm-telmisartan-40';
      session.approveSavedPrescription('meera');
      expect(session.addProduct(telmisartan), isTrue);

      session.increase(telmisartan);

      expect(session.quantityFor(telmisartan), 1);
      expect(session.notice, contains('Prescription quantity reached'));
    });

    test('new prescription never authorizes every prescription medicine', () {
      session.attachNewPrescription();
      final approved = BuyV2Catalogue.products
          .where(
            (product) =>
                product.requiresPrescription &&
                session.isPrescriptionApproved(product.id),
          )
          .length;
      final allRx = BuyV2Catalogue.products
          .where((product) => product.requiresPrescription)
          .length;

      expect(approved, greaterThan(0));
      expect(approved, lessThan(allRx));
    });

    test('removing the final item returns directly to its catalogue', () {
      final medicine = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.medicine &&
            !item.requiresPrescription,
      );
      session.openDestination(BuyV2Destination.medicine);
      session.addProduct(medicine.id);
      session.openCart(scope: BuyV2CartScope.medicine);

      session.decrease(medicine.id);

      expect(session.itemCount, 0);
      expect(session.destination, BuyV2Destination.medicine);
      expect(session.view, BuyV2View.catalogue);
    });

    test('all four Buy destinations remain independent from cart scope', () {
      session.openDestination(BuyV2Destination.wholesale);
      session.openCart(scope: BuyV2CartScope.wholesale);
      session.openDestination(BuyV2Destination.shop);

      expect(session.destination, BuyV2Destination.shop);
      expect(session.view, BuyV2View.catalogue);
      expect(BuyV2Destination.values, contains(BuyV2Destination.medicine));
      expect(BuyV2Destination.values, contains(BuyV2Destination.orders));
    });

    test(
      'scope checkout confirms only that family and preserves other cart lines',
      () {
        final shop = BuyV2Catalogue.products.firstWhere(
          (item) => item.destination == BuyV2Destination.shop,
        );
        final wholesale = BuyV2Catalogue.products.firstWhere(
          (item) => item.destination == BuyV2Destination.wholesale,
        );
        session.addProduct(shop.id);
        session.addProduct(wholesale.id);

        session.openCart(scope: BuyV2CartScope.wholesale);
        session.openCheckout();
        session.confirmOrder();

        expect(session.confirmedDestinations, {BuyV2Destination.wholesale});
        expect(session.quantityFor(wholesale.id), 0);
        expect(session.quantityFor(shop.id), 1);
      },
    );

    test(
      'mixed checkout projects exact seller groups into traceable orders',
      () {
        final selected = <BuyV2Product>[
          BuyV2Catalogue.products.firstWhere(
            (item) => item.destination == BuyV2Destination.shop,
          ),
          BuyV2Catalogue.products.firstWhere(
            (item) =>
                item.destination == BuyV2Destination.shop &&
                item.seller !=
                    BuyV2Catalogue.products
                        .firstWhere(
                          (candidate) =>
                              candidate.destination == BuyV2Destination.shop,
                        )
                        .seller,
          ),
          BuyV2Catalogue.products.firstWhere(
            (item) => item.destination == BuyV2Destination.wholesale,
          ),
          BuyV2Catalogue.products.firstWhere(
            (item) =>
                item.destination == BuyV2Destination.medicine &&
                !item.requiresPrescription,
          ),
        ];
        for (final product in selected) {
          expect(session.addProduct(product.id), isTrue);
        }
        session.openCart();
        session.openCheckout();

        final checkoutLines = session.checkoutLines;
        final groups = session.checkoutFulfilmentGroups;
        final checkoutItemCount = session.checkoutItemCount;
        final checkoutTotal = session.checkoutTotal;
        final expectedKeys = checkoutLines
            .map(
              (line) =>
                  '${line.product.destination.name}|${line.product.seller}',
            )
            .toSet();

        expect(
          groups
              .map((group) => '${group.destination.name}|${group.partner}')
              .toSet(),
          expectedKeys,
        );
        expect(
          groups.fold<int>(0, (total, group) => total + group.itemCount),
          checkoutItemCount,
        );
        expect(
          groups.fold<int>(0, (total, group) => total + group.total),
          checkoutTotal,
        );
        for (final group in groups) {
          final expectedLines = checkoutLines
              .where(
                (line) =>
                    line.product.destination == group.destination &&
                    line.product.seller == group.partner,
              )
              .toList();
          expect(
            group.productIds,
            expectedLines.map((line) => line.product.id).toList(),
          );
          expect(
            group.itemCount,
            expectedLines.fold<int>(0, (total, line) => total + line.quantity),
          );
          expect(
            group.total,
            expectedLines.fold<int>(0, (total, line) => total + line.total),
          );
          expect(group.partnerType, expectedLines.first.product.partnerRole);
        }

        session.confirmOrder();

        expect(session.confirmedOrders, hasLength(groups.length));
        expect(
          session.confirmedOrders.map((order) => order.id).toSet(),
          hasLength(groups.length),
        );
        expect(session.confirmedProductCount, checkoutLines.length);
        expect(session.confirmedItemCount, checkoutItemCount);
        expect(session.confirmedTotal, checkoutTotal);
        expect(session.itemCount, 0);
        for (final group in groups) {
          final order = session.confirmedOrders.singleWhere(
            (candidate) =>
                candidate.destination == group.destination &&
                candidate.partner == group.partner,
          );
          final prefix = switch (group.destination) {
            BuyV2Destination.shop => 'MS-NEW-',
            BuyV2Destination.wholesale => 'PO-NEW-',
            BuyV2Destination.medicine => 'RX-NEW-',
            BuyV2Destination.orders => 'MS-NEW-',
          };
          expect(order.id, startsWith(prefix));
          expect(order.productIds, group.productIds);
          expect(
            order.lines
                .map((line) => (line.product.id, line.quantity, line.total))
                .toList(),
            group.lines
                .map((line) => (line.product.id, line.quantity, line.total))
                .toList(),
          );
          expect(order.total, group.total);
          expect(order.partnerType, group.partnerType);
          expect(order.paymentMethod, 'PhonePe');
          expect(order.recipient, session.selectedAddress.recipient);
          expect(order.addressLine, contains(session.selectedAddress.pinCode));
        }
      },
    );

    test(
      'T01C preserves one purchase and exact accepted delivery promises',
      () {
        final adapter = _T01CDeliveryFactsAdapter();
        final quoted = BuyV2Session(
          core: BuySession(),
          productFactsAdapter: adapter,
        );
        addTearDown(quoted.dispose);
        final shop = quoted.product('s-tomato');
        final wholesale = quoted.product('w-oil');
        expect(quoted.addProduct(shop.id), isTrue);
        expect(quoted.addProduct(wholesale.id), isTrue);
        quoted.openCart();
        expect(quoted.openCheckout(), isTrue);

        final checkout = quoted.checkoutFulfilmentGroups;
        expect(checkout, hasLength(2));
        expect(
          checkout.singleWhere((group) => group.destination == .shop).promise,
          'within 5 min',
        );
        expect(
          checkout
              .singleWhere((group) => group.destination == .wholesale)
              .promisedByLabel,
          'by tomorrow 4:00 PM',
        );

        expect(quoted.confirmOrder(), isTrue);
        expect(quoted.confirmedPurchaseId, 'BUY-NEW-01');
        expect(quoted.confirmedOrders, hasLength(2));
        expect(
          quoted.confirmedOrders.map((order) => order.purchaseId).toSet(),
          {'BUY-NEW-01'},
        );
        expect(
          quoted.confirmedOrders
              .singleWhere((order) => order.destination == .shop)
              .promise,
          'within 5 min',
        );
        expect(
          quoted.confirmedOrders
              .singleWhere((order) => order.destination == .wholesale)
              .promisedByLabel,
          'by tomorrow 4:00 PM',
        );
      },
    );

    test('T01C blocks a changed promise until the buyer accepts it', () {
      final adapter = _T01CDeliveryFactsAdapter();
      final quoted = BuyV2Session(
        core: BuySession(),
        productFactsAdapter: adapter,
      );
      addTearDown(quoted.dispose);
      final shop = quoted.product('s-tomato');
      expect(quoted.addProduct(shop.id), isTrue);
      quoted.openCart();
      expect(quoted.openCheckout(), isTrue);

      adapter.update(
        BuyV2Destination.shop,
        promise: 'within 10 min',
        promisedBy: 'by 6:40 PM',
      );
      expect(quoted.confirmOrder(), isFalse);
      expect(quoted.checkoutPromiseReviewRequired, isTrue);
      expect(quoted.itemCount, 1);
      expect(quoted.confirmedOrders, isEmpty);
      expect(quoted.checkoutDeliveryPromiseChanges, hasLength(1));
      final change = quoted.checkoutDeliveryPromiseChanges.single;
      expect(change.previousPromise, 'within 5 min');
      expect(change.currentPromise, 'within 10 min');
      expect(change.previousPromisedByLabel, 'by 6:35 PM');
      expect(change.currentPromisedByLabel, 'by 6:40 PM');

      expect(quoted.acceptCheckoutPromiseChanges(), isTrue);
      expect(quoted.checkoutPromiseReviewRequired, isFalse);
      expect(quoted.confirmOrder(), isTrue);
      expect(quoted.confirmedOrders.single.promise, 'within 10 min');
      expect(quoted.confirmedOrders.single.promisedByLabel, 'by 6:40 PM');
    });

    test('confirmation creates traceable orders and exact reorder lines', () {
      final shop = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.shop &&
            item.canonicalId == 'onion',
      );
      final secondShop = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.shop &&
            item.id != shop.id &&
            item.seller == shop.seller,
      );
      session.addProduct(shop.id);
      session.addProduct(secondShop.id);
      session.openCart(scope: BuyV2CartScope.shop);
      session.openCheckout();

      session.confirmOrder();

      final confirmed = session.confirmedOrders.single;
      expect(confirmed.id, startsWith('MS-NEW-'));
      expect(confirmed.productIds, {shop.id, secondShop.id});
      expect(session.orders.first.id, confirmed.id);
      session.rememberCartScrollOffset(BuyV2CartScope.shop, 640);

      session.reorder(confirmed);

      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.shop);
      expect(session.cartScrollOffsetFor(BuyV2CartScope.shop), 0);
      expect(session.cartLines.map((line) => line.product.id).toSet(), {
        shop.id,
        secondShop.id,
      });
    });

    test(
      'reorder rejects stale or cross-vertical IDs before cart mutation',
      () {
        final medicine = BuyV2Catalogue.products.firstWhere(
          (product) =>
              product.destination == BuyV2Destination.medicine &&
              !product.requiresPrescription,
        );
        final wholesale = BuyV2Catalogue.products.firstWhere(
          (product) => product.destination == BuyV2Destination.wholesale,
        );
        session.addProduct(medicine.id);

        final invalidOrder = BuyV2Order(
          id: 'MS-INVALID',
          destination: BuyV2Destination.shop,
          title: 'Shop order',
          itemSummary: 'Invalid restoration fixture',
          total: wholesale.price,
          partner: wholesale.seller,
          partnerType: wholesale.sellerType,
          promise: wholesale.deliveryPromise,
          destinationLabel: 'Sardarpura · 342003',
          progress: 1,
          status: BuyV2OrderStatus.delivered,
          productIds: [wholesale.id, 'missing-product'],
        );

        expect(session.reorder(invalidOrder), isFalse);

        expect(session.destination, BuyV2Destination.shop);
        expect(session.view, BuyV2View.catalogue);
        expect(session.quantityFor(wholesale.id), 0);
        expect(session.quantityFor(medicine.id), 1);
        expect(session.itemCount, 1);
        expect(session.notice, 'Products from this order could not be found.');
      },
    );

    test('Saved ownership stays independent across Buy verticals', () {
      final shop = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.wholesale &&
            item.canonicalId == shop.canonicalId,
      );

      expect(session.isSaved(shop.id), isFalse);
      expect(session.isSaved(wholesale.id), isFalse);
      expect(session.savedCountFor(BuyV2Destination.medicine), 0);

      session.toggleSaved(wholesale.id);
      expect(session.isSaved(shop.id), isFalse);
      expect(session.isSaved(wholesale.id), isTrue);

      session.toggleSaved(shop.id);
      expect(session.isSaved(shop.id), isTrue);
      expect(session.isSaved(wholesale.id), isTrue);

      session.toggleSaved(wholesale.id);
      expect(session.isSaved(shop.id), isTrue);
      expect(session.isSaved(wholesale.id), isFalse);
    });

    test('scanned catalogue IDs resolve through production search', () {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );

      session.updateQuery(product.id);

      expect(session.visibleProducts, hasLength(1));
      expect(session.visibleProducts.single.id, product.id);
    });

    test(
      'search suggestions are read-only, truthful and vertical-specific',
      () {
        for (final destination in const [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        ]) {
          session.openDestination(destination);
          session.chooseCategory('all');

          final suggestions = session.searchSuggestions;
          expect(suggestions, hasLength(4), reason: destination.name);
          expect(
            () => suggestions.add('Unapproved search'),
            throwsUnsupportedError,
          );

          for (final suggestion in suggestions) {
            expect(
              BuyV2Catalogue.products.any(
                (product) =>
                    product.destination == destination &&
                    product.title == suggestion,
              ),
              isTrue,
              reason: '${destination.name}: $suggestion',
            );
            session.updateQuery(suggestion);
            expect(session.visibleProducts, isNotEmpty);
            expect(
              session.visibleProducts.every(
                (product) => product.destination == destination,
              ),
              isTrue,
              reason: '${destination.name}: $suggestion',
            );
            expect(session.searchSuggestions, isEmpty);
            session.updateQuery('');
          }
        }

        session.openDestination(BuyV2Destination.orders);
        expect(session.searchSuggestions, isEmpty);
      },
    );

    test('every destination filter returns a real matching catalogue', () {
      const filters = {
        BuyV2Destination.shop: [
          'fast',
          'today',
          'quick-local',
          'standard-courier',
          'lowest',
          'nearby',
          'returns',
        ],
        BuyV2Destination.wholesale: [
          'fast',
          'two-days',
          'bulk-freight',
          'lowest',
          'freight',
          'moq',
          'manufacturer',
        ],
        BuyV2Destination.medicine: [
          'fast',
          'lowest',
          'otc',
          'nearby',
          'manufacturer',
        ],
      };

      for (final entry in filters.entries) {
        session.openDestination(entry.key);
        session.chooseCategory('all');
        for (final filter in entry.value) {
          session.chooseFilter(filter);
          expect(
            session.visibleProducts,
            isNotEmpty,
            reason: '${entry.key.name} filter $filter',
          );
        }
      }
    });

    test('discovery refinements combine and sort without crossing Shop', () {
      session.openDestination(BuyV2Destination.shop);
      final brand = session.discoveryBrands.first;
      session.toggleDiscoveryBrand(brand);
      expect(session.visibleProducts, isNotEmpty);
      expect(
        session.visibleProducts,
        everyElement(
          isA<BuyV2Product>().having(
            (product) => product.brand,
            'brand',
            brand,
          ),
        ),
      );

      session.clearDiscoveryRefinements();
      session.chooseMaximumProductPrice(250);
      expect(
        session.visibleProducts.every(
          (product) => session.productFactsFor(product).price <= 250,
        ),
        isTrue,
      );
      session.chooseFulfilmentMode(BuyV2FulfilmentMode.quickLocal);
      expect(
        session.visibleProducts.every(
          (product) =>
              session.fulfilmentModeFor(product) ==
              BuyV2FulfilmentMode.quickLocal,
        ),
        isTrue,
      );
      session.chooseProductSort(BuyV2ProductSort.priceHighToLow);
      final prices = session.visibleProducts
          .map((product) => session.productFactsFor(product).price)
          .toList(growable: false);
      expect(
        prices,
        orderedEquals([...prices]..sort((a, b) => b.compareTo(a))),
      );
      expect(session.activeDiscoveryRefinementCount, 3);

      session.clearDiscoveryRefinements();
      expect(session.activeDiscoveryRefinementCount, 0);
      expect(session.productSort, BuyV2ProductSort.relevance);
      expect(session.selectedBrands, isEmpty);
    });

    test('Buy account returns to the exact originating purchase depth', () {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      session.openProduct(product.id);

      session.openAccount();
      expect(session.view, BuyV2View.account);

      session.closeAccount();
      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.view, BuyV2View.product);
      expect(session.selectedProductId, product.id);

      session.openTracking('MS-240782');
      session.openAccount();
      session.goBack();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.tracking);
      expect(session.selectedOrder.id, 'MS-240782');
    });

    test('Medicine Tracking and Items remain Care-owned', () {
      expect(session.openTracking('RX-240784'), isTrue);
      expect(session.destination, BuyV2Destination.medicine);
      expect(session.view, BuyV2View.tracking);

      expect(session.openOrderItems('RX-240784'), isTrue);
      expect(session.destination, BuyV2Destination.medicine);
      expect(session.view, BuyV2View.orderItems);

      session.goBack();
      expect(session.destination, BuyV2Destination.medicine);
      expect(session.view, BuyV2View.tracking);
      session.goBack();
      expect(session.destination, BuyV2Destination.medicine);
      expect(session.view, BuyV2View.catalogue);
    });

    test(
      'Account child journeys return through Account to the exact origin',
      () {
        final origin = BuyV2Catalogue.products.firstWhere(
          (item) => item.destination == BuyV2Destination.medicine,
        );
        session.openProduct(origin.id);
        session.updateQuery('paracetamol');
        session.chooseFilter('Under ₹100');
        session.openAccount();

        session.openOrdersFromAccount();
        expect(session.destination, BuyV2Destination.orders);
        expect(session.view, BuyV2View.catalogue);
        expect(session.canReturnToAccount, isTrue);
        expect(session.query, isEmpty);
        expect(session.selectedFilter, isNull);

        expect(session.openTracking('MS-240782'), isTrue);
        session.goBack();
        expect(session.destination, BuyV2Destination.orders);
        expect(session.view, BuyV2View.catalogue);
        expect(session.canReturnToAccount, isTrue);

        session.goBack();
        expect(session.view, BuyV2View.account);
        expect(session.canReturnToAccount, isFalse);
        expect(session.query, 'paracetamol');
        expect(session.selectedFilter, 'Under ₹100');

        session.openWholesaleFromAccount();
        expect(session.destination, BuyV2Destination.wholesale);
        expect(session.view, BuyV2View.catalogue);
        expect(session.canReturnToAccount, isTrue);
        session.goBack();
        expect(session.view, BuyV2View.account);

        session.closeAccount();
        expect(session.destination, BuyV2Destination.medicine);
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, origin.id);
      },
    );

    test('bottom Orders does not acquire an Account parent', () {
      session.updateQuery('milk');
      session.chooseFilter('Under ₹100');
      session.openOrders();

      expect(session.canReturnToAccount, isFalse);
      expect(session.query, isEmpty);
      expect(session.selectedFilter, isNull);
      session.goBack();
      expect(session.destination, BuyV2Destination.shop);
      expect(session.view, BuyV2View.catalogue);
    });

    test('successful cart mutations use a dedicated Cart acknowledgement', () {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );

      expect(session.addProduct(product.id), isTrue);
      expect(session.notice, isNull);
      expect(session.cartAcknowledgement, '${product.title} added');

      session.increase(product.id);
      expect(session.notice, isNull);
      expect(session.cartAcknowledgement, '${product.title} · 2 in cart');

      session.clearCartAcknowledgement();
      expect(session.cartAcknowledgement, isNull);
    });

    test('R66 Cart acknowledgement keeps its mutation destination', () {
      final shop = session.product('s-tomato');
      final wholesale = session.product('w-tomato');
      expect(session.addProduct(shop.id), isTrue);
      expect(session.addProduct(wholesale.id), isTrue);
      expect(session.cartAcknowledgement, '${wholesale.title} added');
      expect(
        session.cartAcknowledgementForDestination(BuyV2Destination.shop),
        isNull,
      );
      expect(
        session.cartAcknowledgementForDestination(BuyV2Destination.wholesale),
        session.cartAcknowledgement,
      );
      session.increase(shop.id);
      expect(
        session.cartAcknowledgementForDestination(BuyV2Destination.shop),
        '${shop.title} · 2 in cart',
      );
      session.decrease(shop.id);
      expect(
        session.cartAcknowledgementForDestination(BuyV2Destination.shop),
        '${shop.title} · 1 in cart',
      );
      session.remove(wholesale.id);
      expect(
        session.cartAcknowledgementForDestination(BuyV2Destination.wholesale),
        '${wholesale.title} removed',
      );
      expect(
        session.cartAcknowledgementForDestination(BuyV2Destination.shop),
        isNull,
      );
      expect(session.quantityFor(shop.id), 1);
      session.clearCartAcknowledgement();
      expect(session.cartAcknowledgement, isNull);
      expect(
        session.cartAcknowledgementForDestination(BuyV2Destination.wholesale),
        isNull,
      );
    });

    for (final operation in ['decrease', 'remove']) {
      for (final origin in [BuyV2View.catalogue, BuyV2View.product]) {
        for (final id in ['s-tomato', 'w-notebook']) {
          test('R5 023 $operation last $id preserves inline $origin', () {
            final item = session.product(id);
            session.addProduct(id);
            session.openDestination(BuyV2Destination.shop);
            session.updateQuery('notebook');
            session.chooseMaximumProductPrice(250);
            expect(session.maximumProductPrice, 250);
            if (origin == BuyV2View.product) session.openProduct('s-tomato');
            final productId = session.selectedProductId;
            final motion = session.navigationMotionSequence;
            if (operation == 'decrease') {
              session.decrease(id);
            } else {
              session.remove(id);
            }
            expect(session.quantityFor(id), 0);
            expect(session.destination, BuyV2Destination.shop);
            expect(session.view, origin);
            expect(session.selectedProductId, productId);
            expect(session.query, 'notebook');
            expect(session.maximumProductPrice, 250);
            expect(session.navigationMotionSequence, motion);
            expect(session.cartAcknowledgement, '${item.title} removed');
          });
        }
      }
    }

    for (final operation in ['decrease', 'remove']) {
      for (final destination in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        test(
          'R5 023 $operation mixed Cart preserves $destination browsing',
          () {
            final first = destination == BuyV2Destination.shop
                ? 's-tomato'
                : 'w-notebook';
            final last = destination == BuyV2Destination.shop
                ? 'w-notebook'
                : 's-tomato';
            session.addProduct(first);
            session.addProduct(last);
            session.openDestination(destination);
            session.updateQuery('rice');
            final retained = session.quantityFor(last);
            void removeItem(String id) => operation == 'decrease'
                ? session.decrease(id)
                : session.remove(id);
            removeItem(first);
            expect(session.quantityFor(first), 0);
            expect(session.quantityFor(last), retained);
            expect(session.destination, destination);
            expect(session.view, BuyV2View.catalogue);
            expect(session.query, 'rice');
            removeItem(last);
            expect(session.itemCount, 0);
            expect(session.destination, destination);
            expect(session.view, BuyV2View.catalogue);
            expect(session.query, 'rice');
          },
        );
      }
      for (final origin in [BuyV2View.cart, BuyV2View.checkout]) {
        test('R5 023 $operation from empty $origin retains Cart recovery', () {
          session.addProduct('w-notebook');
          session.openCart(scope: BuyV2CartScope.wholesale);
          if (origin == BuyV2View.checkout) session.openCheckout();
          expect(session.view, origin);
          if (operation == 'decrease') {
            session.decrease('w-notebook');
          } else {
            session.remove('w-notebook');
          }
          expect(session.itemCount, 0);
          expect(session.destination, BuyV2Destination.wholesale);
          expect(session.view, BuyV2View.catalogue);
          expect(session.cartScope, BuyV2CartScope.all);
        });
      }
    }
    test('Buy assist returns to the exact originating purchase depth', () {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      session.openProduct(product.id);

      session.openAssist();
      expect(session.view, BuyV2View.assist);

      session.closeAssist();
      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.view, BuyV2View.product);
      expect(session.selectedProductId, product.id);

      session.openTracking('MS-240782');
      session.openAssist();
      session.goBack();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.tracking);
      expect(session.selectedOrder.id, 'MS-240782');
    });

    test('saved address and payment selections change independently', () {
      session.chooseAddress('work');
      expect(session.selectedAddressId, 'work');
      expect(session.selectedPayment, 'PhonePe');

      expect(session.choosePayment('Paytm'), isTrue);
      expect(session.selectedAddressId, 'work');
      expect(session.selectedPayment, 'Paytm');

      session.chooseAddress('home');
      expect(session.selectedAddressId, 'home');
      expect(session.selectedPayment, 'Paytm');
    });

    test('staged Checkout Back returns Confirm Payment Address then Cart', () {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      expect(session.addProduct(product.id), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      expect(session.checkoutStep, BuyV2CheckoutStep.address);

      expect(session.continueCheckoutFromAddress(), isTrue);
      expect(session.checkoutStep, BuyV2CheckoutStep.payment);
      expect(session.continueCheckoutFromPayment(), isTrue);
      expect(session.checkoutStep, BuyV2CheckoutStep.confirm);

      session.goBack();
      expect(session.view, BuyV2View.checkout);
      expect(session.checkoutStep, BuyV2CheckoutStep.payment);
      session.goBack();
      expect(session.view, BuyV2View.checkout);
      expect(session.checkoutStep, BuyV2CheckoutStep.address);
      session.goBack();
      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.shop);
    });

    test('saved address update preserves identity count and selection', () {
      final before = session.addresses.length;
      final home = session.addresses.firstWhere(
        (address) => address.id == 'home',
      );
      session.chooseAddress('work');

      expect(
        session.updateAddress(
          BuyV2Address(
            id: home.id,
            kind: home.kind,
            label: home.label,
            recipient: 'Asha Verma',
            phone: home.phone,
            line: home.line,
            area: home.area,
            pinCode: home.pinCode,
            landmark: home.landmark,
          ),
        ),
        isTrue,
      );

      expect(session.addresses.length, before);
      expect(session.selectedAddressId, 'work');
      expect(
        session.addresses
            .firstWhere((address) => address.id == 'home')
            .recipient,
        'Asha Verma',
      );
      expect(session.notice, 'Home address updated');
    });

    test('stale saved address update fails without mutation', () {
      final beforeIds = session.addresses.map((address) => address.id).toList();

      expect(
        session.updateAddress(
          const BuyV2Address(
            id: 'missing-address',
            kind: BuyV2AddressKind.other,
            label: 'Other place',
            recipient: 'Meera Sharma',
            phone: '9876543210',
            line: '12 Market Road',
            area: 'Jodhpur',
            pinCode: '342001',
            landmark: 'No nearby landmark',
          ),
        ),
        isFalse,
      );

      expect(session.addresses.map((address) => address.id), beforeIds);
      expect(session.notice, 'This saved address is no longer available.');
    });

    test('unsupported payment identifiers fail closed', () {
      session.chooseAddress('work');
      expect(session.choosePayment('Purchase order'), isTrue);

      expect(session.choosePayment('Card<script>'), isFalse);
      expect(session.choosePayment('UPI'), isFalse);
      expect(session.choosePayment('Bank transfer'), isFalse);

      expect(session.selectedAddressId, 'work');
      expect(session.selectedPayment, 'Purchase order');
      expect(session.notice, 'This payment method is not available.');
      expect(BuyV2Session.paymentMethods, {
        'PhonePe',
        'Paytm',
        'Pine Labs',
        'Cash on Delivery',
        'Purchase order',
      });
    });

    test('Orders search filters only the current order tab', () {
      session.openDestination(BuyV2Destination.orders);

      session.updateQuery('MS-240782');
      expect(session.visibleOrders.map((order) => order.id), ['MS-240782']);

      session.updateQuery('sardarpura');
      expect(session.visibleOrders, isNotEmpty);
      expect(
        session.visibleOrders.every(
          (order) =>
              '${order.id} ${order.title} ${order.partner} '
                      '${order.partnerType} ${order.itemSummary}'
                  .toLowerCase()
                  .contains('sardarpura'),
        ),
        isTrue,
      );

      session.updateQuery('MS-240782');
      session.showOrdersTab(BuyV2OrdersTab.delivered);
      expect(session.visibleOrders, isEmpty);

      session.updateQuery('');
      expect(
        session.visibleOrders.every(
          (order) => order.status == BuyV2OrderStatus.delivered,
        ),
        isTrue,
      );
    });

    test(
      'unknown external identifiers fail closed without substituting data',
      () {
        final firstProduct = BuyV2Catalogue.products.first;
        final firstProductWasSaved = session.isSaved(firstProduct.id);

        expect(session.openProduct('missing-product'), isFalse);
        expect(session.view, BuyV2View.catalogue);
        expect(session.selectedProductId, isNull);
        expect(session.notice, 'This product could not be found.');

        expect(session.addProduct('missing-product'), isFalse);
        expect(session.itemCount, 0);
        expect(session.quantityFor(firstProduct.id), 0);

        session.toggleSaved('missing-product');
        expect(session.isSaved('missing-product'), isFalse);
        expect(session.isSaved(firstProduct.id), firstProductWasSaved);

        expect(session.openTracking('missing-order'), isFalse);
        expect(session.destination, BuyV2Destination.orders);
        expect(session.view, BuyV2View.catalogue);
        expect(session.selectedOrderId, isNull);
        expect(session.notice, 'This order could not be found.');

        session.chooseAddress('work');
        expect(session.chooseAddress('missing-address'), isFalse);
        expect(session.selectedAddressId, 'work');
        expect(session.notice, 'This saved address could not be found.');
      },
    );

    test(
      'normal runtime starts with no review commerce or customer data',
      () async {
        final production = BuyV2Session(
          core: BuySession(),
          reviewDataEnabled: false,
        );

        expect(production.visibleProducts, isEmpty);
        expect(production.addresses, isEmpty);
        expect(production.orders, isEmpty);
        expect(production.businessVerified, isFalse);
        expect(production.availablePaymentMethods, isEmpty);

        await production.restoreCommerce();

        expect(
          production.commerceLoadState,
          BuyV2CommerceLoadState.unavailable,
        );
        expect(production.confirmOrder(), isFalse);
        expect(production.view, isNot(BuyV2View.confirmation));
        expect(
          production.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.unavailable,
        );
      },
    );

    test(
      'authoritative commerce snapshot and order result own production success',
      () async {
        final product = BuyV2Catalogue.products.firstWhere(
          (candidate) => candidate.destination == BuyV2Destination.shop,
        );
        const address = BuyV2Address(
          id: 'server-home',
          kind: BuyV2AddressKind.home,
          label: 'Home',
          recipient: 'Aarav Sharma',
          phone: '9000000000',
          line: '12, Central Avenue',
          area: 'Sardarpura, Jodhpur',
          pinCode: '342003',
          landmark: 'Near the market',
        );
        final order = BuyV2Order(
          id: 'MS-SERVER-1',
          destination: BuyV2Destination.shop,
          title: 'Shop order',
          itemSummary: '1 product',
          total: product.price,
          partner: product.seller,
          partnerType: product.partnerRole,
          promise: product.deliveryPromise,
          destinationLabel: address.shortLine,
          progress: .2,
          status: BuyV2OrderStatus.preparing,
          purchaseId: 'BUY-SERVER-1',
          productIds: [product.id],
          lines: [BuyV2CartLine(product: product, quantity: 1)],
          paymentMethod: 'UPI',
        );
        final adapter = _ShopCommerceAdapter(
          snapshot: BuyV2CommerceSnapshot(
            state: BuyV2CommerceLoadState.ready,
            products: [product],
            addresses: const [address],
            selectedAddressId: address.id,
            paymentMethods: const {'UPI'},
          ),
          placement: BuyV2OrderPlacementResult(
            outcome: BuyV2OrderPlacementOutcome.confirmed,
            customerMessage: 'Your order is confirmed.',
            purchaseReference: 'BUY-SERVER-1',
            orders: [order],
          ),
        );
        final production = BuyV2Session(
          core: BuySession(),
          commerceAdapter: adapter,
          reviewDataEnabled: false,
        );

        await production.restoreCommerce();
        expect(production.addProduct(product.id), isTrue);
        production.openCart(scope: BuyV2CartScope.shop);
        expect(production.openCheckout(), isTrue);

        expect(await production.submitOrder(), isTrue);
        expect(adapter.placementCalls, 1);
        expect(production.view, BuyV2View.confirmation);
        expect(production.confirmedOrders.single.id, order.id);
        expect(production.itemCount, 0);
      },
    );

    test(
      'customer state restores cart address saved and payment choices',
      () async {
        final store = _MemoryCustomerStateStore('account-1');
        final first = BuyV2Session(
          core: BuySession(),
          customerStateStore: store,
        );
        final product = first.visibleProducts.first;
        first.addProduct(product.id);
        first.toggleSaved(product.id);
        first.addAddress(
          const BuyV2Address(
            id: 'family',
            kind: BuyV2AddressKind.thirdParty,
            label: 'Third party',
            recipient: 'Family recipient',
            phone: '9000000001',
            line: '21, Market Road',
            area: 'Ratanada, Jodhpur',
            pinCode: '342011',
            landmark: 'Near the park',
          ),
        );
        first.choosePayment('Paytm');
        final brand = first.discoveryBrands.first;
        first.toggleDiscoveryBrand(brand);
        first.chooseMaximumProductPrice(500);
        first.choosePackFilter(BuyV2PackFilter.standard);
        first.chooseFulfilmentMode(BuyV2FulfilmentMode.quickLocal);
        first.chooseProductSort(BuyV2ProductSort.priceLowToHigh);
        first.setAvailableProductsOnly(true);
        await Future<void>.delayed(Duration.zero);

        final restored = BuyV2Session(
          core: BuySession(),
          customerStateStore: store,
        );
        await restored.restoreCustomerState();

        expect(restored.quantityFor(product.id), product.minimumOrder);
        expect(restored.isSaved(product.id), isTrue);
        expect(restored.selectedAddressId, 'family');
        expect(restored.selectedPayment, 'Paytm');
        expect(restored.selectedBrands, isEmpty);
        expect(restored.maximumProductPrice, isNull);
        expect(restored.selectedPackFilter, isNull);
        expect(restored.selectedFulfilmentMode, isNull);
        expect(restored.productSort, BuyV2ProductSort.relevance);
        expect(restored.availableProductsOnly, isFalse);
      },
    );

    test('confirmed order survives a customer-session restart', () async {
      final store = _MemoryCustomerStateStore('account-orders');
      final first = BuyV2Session(core: BuySession(), customerStateStore: store);
      addTearDown(first.dispose);
      final product = first.product('s-tomato');

      expect(first.addProduct(product.id), isTrue);
      first.openCart(scope: BuyV2CartScope.shop);
      expect(first.openCheckout(), isTrue);
      expect(first.continueCheckoutFromAddress(), isTrue);
      expect(first.choosePayment('Cash on Delivery'), isTrue);
      expect(first.continueCheckoutFromPayment(), isTrue);
      expect(await first.submitOrder(), isTrue);
      expect(first.confirmedOrders, isNotEmpty);
      final orderId = first.confirmedOrders.first.id;
      await Future<void>.delayed(Duration.zero);

      final restored = BuyV2Session(
        core: BuySession(),
        customerStateStore: store,
      );
      addTearDown(restored.dispose);
      await restored.restoreCustomerState();

      expect(restored.orders.any((order) => order.id == orderId), isTrue);
      expect(
        restored.productsForOrder(
          restored.orders.firstWhere((order) => order.id == orderId),
        ),
        isNotEmpty,
      );
    });

    test(
      'R66 new review purchases stay isolated across customer restarts',
      () async {
        final store = _MemoryCustomerStateStore('account-r66-order-identity');
        final purchases = <String, List<BuyV2Order>>{};
        final deliveryIds = <String>{};
        for (final wholesale in [true, false, true, false]) {
          final core = BuySession();
          final session = BuyV2Session(core: core, customerStateStore: store);
          try {
            await session.restoreCustomerState();
            for (final entry in purchases.entries) {
              final retained = session.orders
                  .where((order) => order.purchaseId == entry.key)
                  .toList();
              expect(
                retained.map((order) => order.id),
                unorderedEquals(entry.value.map((order) => order.id)),
              );
            }
            if (wholesale) {
              expect(session.addProduct('w-notebook'), isTrue);
              session.openCart(scope: BuyV2CartScope.wholesale);
            } else {
              final retail = session.product('s-tomato');
              final anotherStore = BuyV2Catalogue.products.firstWhere(
                (product) =>
                    product.destination == BuyV2Destination.shop &&
                    product.seller != retail.seller &&
                    !product.requiresPrescription,
              );
              expect(session.addProduct(retail.id), isTrue);
              expect(session.addProduct(anotherStore.id), isTrue);
              session.openCart(scope: BuyV2CartScope.shop);
            }
            expect(session.openCheckout(), isTrue);
            expect(session.continueCheckoutFromAddress(), isTrue);
            expect(
              session.choosePayment(
                wholesale ? 'Purchase order' : 'Cash on Delivery',
              ),
              isTrue,
            );
            if (wholesale) session.purchaseOrderReference = 'R66-LOCAL-PO';
            expect(session.continueCheckoutFromPayment(), isTrue);
            final groups = session.checkoutFulfilmentGroups;
            expect(groups, hasLength(wholesale ? 1 : 2));
            final total = session.checkoutPayableTotal;
            expect(await session.submitOrder(), isTrue);
            final purchaseId = session.confirmedPurchaseId!;
            expect(
              purchases.containsKey(purchaseId),
              isFalse,
              reason: 'A new purchase must not join retained deliveries',
            );
            expect(session.confirmedOrders, hasLength(groups.length));
            for (final order in session.confirmedOrders) {
              expect(
                deliveryIds.add(order.id),
                isTrue,
                reason: 'Delivery identity reused: ${order.id}',
              );
            }
            final actualGroup = session.orders
                .where((order) => order.purchaseId == purchaseId)
                .toList();
            expect(
              actualGroup.map((order) => order.id),
              unorderedEquals(session.confirmedOrders.map((order) => order.id)),
            );
            expect(
              actualGroup.fold<int>(0, (sum, order) => sum + order.total),
              total,
            );
            expect(
              actualGroup.map((order) => order.partner),
              unorderedEquals(groups.map((group) => group.partner)),
            );
            purchases[purchaseId] = List.of(session.confirmedOrders);
            for (final entry in purchases.entries) {
              for (final previous in entry.value) {
                final retained = session.orders
                    .where((order) => order.id == previous.id)
                    .single;
                expect(retained.purchaseId, entry.key);
                expect(retained.total, previous.total);
                expect(retained.productIds, previous.productIds);
              }
            }
            await Future<void>.delayed(Duration.zero);
          } finally {
            session.dispose();
            core.dispose();
          }
        }
        expect(purchases, hasLength(4));
        expect(deliveryIds, hasLength(6));
        expect(
          store.snapshot!.orders.map((order) => order.id).toSet(),
          containsAll(deliveryIds),
        );
      },
    );

    test('delivery refinement keeps the visible Shop segment truthful', () {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);

      session.chooseShopSaleType(BuyV2ShopSaleType.courier);
      session.chooseFulfilmentMode(BuyV2FulfilmentMode.quickLocal);

      expect(session.shopSaleType, BuyV2ShopSaleType.quickDelivery);
      expect(
        session.catalogueSaleTypeProducts.every(
          (product) =>
              session.fulfilmentModeFor(product) ==
              BuyV2FulfilmentMode.quickLocal,
        ),
        isTrue,
      );
    });

    test('closed and no-products stores cannot add unavailable products', () {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      final closedProduct = session.product('s-dog-food');
      final unavailableProduct = session.product('s-shampoo');

      expect(session.addProduct(closedProduct.id), isFalse);
      expect(session.notice, contains('closed'));
      expect(session.partnerCatalogueFor(unavailableProduct), isEmpty);
      expect(session.addProduct(unavailableProduct.id), isFalse);
      expect(session.notice, 'This product is unavailable right now.');
    });

    test(
      'payment handoff locks one attempt and reconciliation confirms once',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.paymentActionRequired,
          paymentActionUri: Uri.parse('upi://pay?pa=merchant@mool'),
          paymentReference: 'PAY-1',
        );
        addTearDown(fixture.session.dispose);

        expect(await fixture.session.submitOrder(), isFalse);
        expect(
          fixture.session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentActionRequired,
        );
        final idempotencyKey = fixture.session.checkoutIdempotencyKey;
        expect(idempotencyKey, isNotEmpty);
        expect(await fixture.session.submitOrder(), isFalse);
        expect(fixture.adapter.placementCalls, 1);
        fixture.session.increase(fixture.product.id);
        expect(fixture.session.quantityFor(fixture.product.id), 1);

        Uri? openedUri;
        expect(
          await fixture.session.continuePayment((uri) async {
            openedUri = uri;
            return true;
          }),
          isTrue,
        );
        expect(openedUri, Uri.parse('upi://pay?pa=merchant@mool'));
        expect(
          fixture.session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentPending,
        );

        fixture.adapter.reconciliation = BuyV2OrderPlacementResult(
          outcome: BuyV2OrderPlacementOutcome.confirmed,
          customerMessage: 'Your order is confirmed.',
          purchaseReference: 'BUY-SERVER-1',
          paymentReference: 'PAY-1',
          orders: [fixture.order],
        );
        expect(await fixture.session.reconcilePayment(), isTrue);
        expect(fixture.adapter.reconciliationCalls, 1);
        expect(fixture.session.view, BuyV2View.confirmation);
        expect(fixture.session.confirmedOrders.single.id, 'MS-SERVER-1');
        expect(fixture.session.checkoutIdempotencyKey, isNull);
      },
    );

    test(
      'failed retry reuses its idempotency key and cannot duplicate',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.failed,
        );
        addTearDown(fixture.session.dispose);

        expect(await fixture.session.submitOrder(), isFalse);
        final firstKey = fixture.adapter.requests.single.idempotencyKey;
        fixture.adapter.placement = BuyV2OrderPlacementResult(
          outcome: BuyV2OrderPlacementOutcome.confirmed,
          customerMessage: 'Your order is confirmed.',
          purchaseReference: 'BUY-SERVER-1',
          orders: [fixture.order],
        );

        expect(await fixture.session.submitOrder(), isTrue);
        expect(fixture.adapter.requests, hasLength(2));
        expect(fixture.adapter.requests.last.idempotencyKey, firstKey);
        expect(fixture.session.confirmedOrders, hasLength(1));
      },
    );

    test(
      'cancelled payment creates a new attempt only after customer retry',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.cancelled,
        );
        addTearDown(fixture.session.dispose);

        expect(await fixture.session.submitOrder(), isFalse);
        final cancelledKey = fixture.adapter.requests.single.idempotencyKey;
        expect(fixture.session.checkoutIdempotencyKey, isNull);
        expect(
          fixture.session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.cancelled,
        );
        fixture.adapter.placement = BuyV2OrderPlacementResult(
          outcome: BuyV2OrderPlacementOutcome.confirmed,
          customerMessage: 'Your order is confirmed.',
          purchaseReference: 'BUY-SERVER-1',
          orders: [fixture.order],
        );

        expect(await fixture.session.submitOrder(), isTrue);
        expect(
          fixture.adapter.requests.last.idempotencyKey,
          isNot(cancelledKey),
        );
      },
    );

    test(
      'price change updates the Cart and requires explicit acceptance',
      () async {
        final facts = _MutableCommerceFactsAdapter();
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.confirmed,
          factsAdapter: facts,
        );
        addTearDown(fixture.session.dispose);
        facts.price = fixture.product.price + 12;

        expect(await fixture.session.submitOrder(), isFalse);
        expect(fixture.adapter.placementCalls, 0);
        expect(fixture.session.checkoutPriceReviewRequired, isTrue);
        expect(
          fixture.session.checkoutPriceChanges.single.previousPrice,
          fixture.product.price,
        );
        expect(
          fixture.session.checkoutPayableTotal,
          fixture.product.price + 12,
        );

        fixture.session.acceptCheckoutPriceChanges();
        final currentLine = fixture.session.checkoutLines.single;
        fixture.adapter.placement = BuyV2OrderPlacementResult(
          outcome: BuyV2OrderPlacementOutcome.confirmed,
          customerMessage: 'Your order is confirmed.',
          purchaseReference: 'BUY-SERVER-1',
          orders: [
            BuyV2Order(
              id: fixture.order.id,
              destination: fixture.order.destination,
              title: fixture.order.title,
              itemSummary: fixture.order.itemSummary,
              total: currentLine.total,
              partner: fixture.order.partner,
              partnerType: fixture.order.partnerType,
              promise: fixture.order.promise,
              destinationLabel: fixture.order.destinationLabel,
              progress: fixture.order.progress,
              status: fixture.order.status,
              purchaseId: fixture.order.purchaseId,
              productIds: [currentLine.product.id],
              lines: [currentLine],
              paymentMethod: fixture.order.paymentMethod,
            ),
          ],
        );
        expect(await fixture.session.submitOrder(), isTrue);
        expect(fixture.adapter.placementCalls, 1);
      },
    );

    test('pending payment survives restart and keeps the Cart locked', () async {
      final store = _MemoryCustomerStateStore('account-payment');
      final fixture = await _openProductionCheckout(
        outcome: BuyV2OrderPlacementOutcome.paymentPending,
        paymentReference: 'PAY-RESTORE-1',
        customerStateStore: store,
      );
      addTearDown(fixture.session.dispose);

      expect(await fixture.session.submitOrder(), isFalse);
      await Future<void>.delayed(Duration.zero);
      final restored = BuyV2Session(
        core: BuySession(),
        commerceAdapter: fixture.adapter,
        customerStateStore: store,
        reviewDataEnabled: false,
      );
      addTearDown(restored.dispose);
      await restored.restoreCommerce();
      await restored.restoreCustomerState();
      restored.openCart(scope: BuyV2CartScope.shop);
      restored.openCheckout();

      expect(
        restored.checkoutSubmissionState,
        BuyV2CheckoutSubmissionState.paymentPending,
      );
      final quantity = restored.quantityFor(fixture.product.id);
      expect(
        restored.setCartQuantity(fixture.product.id, '${quantity + 10}'),
        isFalse,
      );
      expect(restored.quantityFor(fixture.product.id), quantity);
      restored.increase(fixture.product.id);
      expect(restored.quantityFor(fixture.product.id), quantity);
      expect(
        restored.notice,
        'Check the current payment before changing your Cart or payment method.',
      );
    });

    test(
      'verified purchase review and product report require real acceptance',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.failed,
          productReportsAvailable: true,
          productReviewAvailable: true,
        );
        addTearDown(fixture.session.dispose);

        expect(
          await fixture.session.submitProductReviewOnline(
            productId: fixture.product.id,
            rating: 5,
            comment: 'Fresh and packed carefully.',
          ),
          isTrue,
        );
        expect(fixture.adapter.reviewCalls, 1);
        expect(
          fixture.session.customerReviewFor(fixture.product.id)?.rating,
          5,
        );
        expect(
          await fixture.session.reportProductOnline(
            productId: fixture.product.id,
            reason: 'Product information is incorrect',
          ),
          isTrue,
        );
        expect(fixture.adapter.reportCalls, 1);
        expect(fixture.session.hasReportedProduct(fixture.product.id), isTrue);
      },
    );

    test(
      'ineligible or rejected feedback never records local success',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.failed,
          productReportsAvailable: true,
        );
        addTearDown(fixture.session.dispose);

        expect(
          await fixture.session.submitProductReviewOnline(
            productId: fixture.product.id,
            rating: 4,
            comment: 'Useful product.',
          ),
          isFalse,
        );
        expect(fixture.adapter.reviewCalls, 0);
        fixture.adapter.reportResult = const BuyV2MutationResult(
          accepted: false,
          customerMessage: 'This report could not be sent. Try again.',
        );
        expect(
          await fixture.session.reportProductOnline(
            productId: fixture.product.id,
            reason: 'Product image does not match',
          ),
          isFalse,
        );
        expect(fixture.adapter.reportCalls, 1);
        expect(fixture.session.hasReportedProduct(fixture.product.id), isFalse);
        expect(
          fixture.session.notice,
          'This report could not be sent. Try again.',
        );
      },
    );

    test(
      'Workspace verification status remains authoritative for Wholesale',
      () async {
        for (final state in const [
          BuyV2BusinessVerificationState.pending,
          BuyV2BusinessVerificationState.rejected,
          BuyV2BusinessVerificationState.unavailable,
        ]) {
          final fixture = await _openProductionCheckout(
            outcome: BuyV2OrderPlacementOutcome.failed,
            businessVerificationState: state,
          );
          addTearDown(fixture.session.dispose);
          expect(fixture.session.businessVerified, isFalse);
          expect(fixture.session.businessVerificationState, state);
        }
      },
    );

    test(
      'order refresh accepts exact identity and preserves last known failure',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.confirmed,
        );
        addTearDown(fixture.session.dispose);
        expect(await fixture.session.submitOrder(), isTrue);
        final updated = BuyV2Order(
          id: fixture.order.id,
          destination: fixture.order.destination,
          title: fixture.order.title,
          itemSummary: fixture.order.itemSummary,
          total: fixture.order.total + 90,
          partner: fixture.order.partner,
          partnerType: fixture.order.partnerType,
          promise: 'Arriving today by 6:30 pm',
          destinationLabel: fixture.order.destinationLabel,
          progress: .8,
          status: BuyV2OrderStatus.arriving,
          purchaseId: fixture.order.purchaseId,
          productIds: fixture.order.productIds,
          lines: fixture.order.lines,
          paymentMethod: fixture.order.paymentMethod,
          invoiceAvailable: true,
          receiptReference: 'PAY-RECEIPT-1',
          dispatchPromise: 'Dispatch completed at 2:10 pm',
          deliveryPartnerName: 'Rajasthan Freight Network',
          deliveryPartnerType: 'Freight carrier',
          trackingReference: 'RFN-TRACK-1001',
          deliveryServiceLevel: 'Business freight · tracked',
          proofOfDeliveryStatus: 'Required at handover',
          tax: 90,
          taxInvoiceState: BuyV2TaxInvoiceState.corrected,
          taxInvoiceDetails: BuyV2TaxInvoiceDetails(
            invoiceNumber: 'TAX-INV-1001-R1',
            issuedAt: DateTime(2026, 8, 29, 18, 30),
            sellerLegalName: 'Mool Retail Partner Private Limited',
            sellerAddress: 'Jodhpur, Rajasthan 342003',
            sellerGstin: '08ABCDE1234F1Z5',
            buyerGstin: '08AAAAA0000A1Z5',
            placeOfSupply: 'Rajasthan (08)',
            sourceId: 'seller-tax-invoice-source',
            revisionLabel: 'Corrected seller address',
            lines: const [
              BuyV2TaxInvoiceLine(
                description: 'Shop products',
                hsnSac: '19059090',
                taxableValue: 1000,
                gstRate: 9,
                cgst: 45,
                sgst: 45,
                igst: 0,
                cess: 0,
              ),
            ],
          ),
        );
        fixture.adapter.orderRefreshResult = BuyV2OrderRefreshResult(
          state: BuyV2CommerceLoadState.ready,
          customerMessage: 'Order updated.',
          order: updated,
        );

        expect(await fixture.session.refreshOrder(fixture.order.id), isTrue);
        expect(fixture.adapter.orderRefreshCalls, 1);
        expect(fixture.session.orders.first.promise, updated.promise);
        expect(fixture.session.orders.first.invoiceAvailable, isTrue);
        expect(
          fixture.session.orders.first.deliveryPartnerName,
          'Rajasthan Freight Network',
        );
        expect(
          fixture.session.orders.first.trackingReference,
          'RFN-TRACK-1001',
        );
        expect(
          fixture.session.orders.first.taxInvoiceDetails?.invoiceNumber,
          'TAX-INV-1001-R1',
        );

        fixture.adapter.orderRefreshResult = BuyV2OrderRefreshResult(
          state: BuyV2CommerceLoadState.ready,
          customerMessage: 'Order identity could not be verified.',
          order: BuyV2Order(
            id: 'OTHER-ORDER',
            destination: updated.destination,
            title: updated.title,
            itemSummary: updated.itemSummary,
            total: updated.total,
            partner: updated.partner,
            partnerType: updated.partnerType,
            promise: 'Different promise',
            destinationLabel: updated.destinationLabel,
            progress: .9,
            status: BuyV2OrderStatus.arriving,
          ),
        );
        expect(await fixture.session.refreshOrder(fixture.order.id), isFalse);
        expect(fixture.session.orders.first.promise, updated.promise);
        expect(
          fixture.session.orderRefreshMessage(fixture.order.id),
          'Order identity could not be verified.',
        );
        expect(fixture.session.notice, isNull);
      },
    );

    test(
      'order alerts change only after authoritative acknowledgement',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.failed,
        );
        addTearDown(fixture.session.dispose);

        await fixture.session.restoreOrderAlerts();
        expect(fixture.session.trackingAlertsAvailable, isTrue);
        expect(fixture.session.trackingAlertsEnabled, isFalse);

        expect(await fixture.session.setTrackingAlerts(true), isTrue);
        expect(fixture.session.trackingAlertsEnabled, isTrue);

        fixture.adapter.alertsResult = const BuyV2OrderAlertsResult(
          available: false,
          enabled: false,
          customerMessage: 'Order alerts are unavailable right now.',
        );
        await fixture.session.restoreOrderAlerts();
        expect(fixture.session.trackingAlertsAvailable, isFalse);
        expect(fixture.session.trackingAlertsEnabled, isFalse);
      },
    );

    test(
      'stock recovery identifies one product and revalidates without ordering',
      () async {
        final facts = _MutableCommerceFactsAdapter();
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.failed,
          factsAdapter: facts,
        );
        addTearDown(fixture.session.dispose);
        facts.orderabilityLabel = 'Out of stock';

        expect(await fixture.session.submitOrder(), isFalse);
        expect(fixture.adapter.placementCalls, 0);
        expect(fixture.session.view, BuyV2View.recovery);
        expect(
          fixture.session.checkoutAvailabilityIssue?.productId,
          fixture.product.id,
        );

        facts
          ..orderabilityLabel = 'Available to add'
          ..price = fixture.product.price + 10;
        expect(fixture.session.retryCheckoutAvailability(), isTrue);
        expect(fixture.session.view, BuyV2View.checkout);
        expect(fixture.session.checkoutAvailabilityIssue, isNull);
        expect(fixture.session.checkoutPriceReviewRequired, isTrue);
        expect(fixture.adapter.placementCalls, 0);
      },
    );

    test(
      'server stock rejection removes only its exact Cart product',
      () async {
        final fixture = await _openProductionCheckout(
          outcome: BuyV2OrderPlacementOutcome.unavailable,
        );
        addTearDown(fixture.session.dispose);
        fixture.adapter.placement = BuyV2OrderPlacementResult(
          outcome: BuyV2OrderPlacementOutcome.unavailable,
          customerMessage: '${fixture.product.title} is out of stock.',
          failureKind: BuyV2OrderPlacementFailureKind.stockUnavailable,
          affectedProductId: fixture.product.id,
        );

        expect(await fixture.session.submitOrder(), isFalse);
        expect(fixture.adapter.placementCalls, 1);
        expect(fixture.session.view, BuyV2View.recovery);
        expect(
          fixture.session.checkoutAvailabilityIssue?.title,
          fixture.product.title,
        );
        expect(fixture.session.removeCheckoutIssueProduct(), isTrue);
        expect(fixture.session.cartLines, isEmpty);
        expect(fixture.session.view, BuyV2View.catalogue);
      },
    );

    test('service-area rejection returns to exact Checkout address', () async {
      final fixture = await _openProductionCheckout(
        outcome: BuyV2OrderPlacementOutcome.unavailable,
      );
      addTearDown(fixture.session.dispose);
      final addressId = fixture.session.selectedAddress.id;
      fixture.adapter.placement = const BuyV2OrderPlacementResult(
        outcome: BuyV2OrderPlacementOutcome.unavailable,
        customerMessage: 'Delivery is unavailable at this address.',
        failureKind: BuyV2OrderPlacementFailureKind.serviceAreaUnavailable,
      );

      expect(await fixture.session.submitOrder(), isFalse);
      expect(fixture.session.view, BuyV2View.recovery);
      expect(fixture.session.canResolveCheckoutAddress, isTrue);
      fixture.session.retryRecovery();
      expect(fixture.session.view, BuyV2View.checkout);
      expect(fixture.session.selectedAddress.id, addressId);
      expect(fixture.session.cartLines, isNotEmpty);
    });

    test('Shop sale type separates Quick delivery and Courier products', () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      expect(session.shopSaleType, BuyV2ShopSaleType.quickDelivery);
      expect(session.catalogueSaleTypeProducts, isNotEmpty);
      expect(
        session.catalogueSaleTypeProducts.every(
          (product) =>
              session.fulfilmentModeFor(product) ==
              BuyV2FulfilmentMode.quickLocal,
        ),
        isTrue,
      );

      session.chooseShopSaleType(BuyV2ShopSaleType.courier);
      expect(session.shopSaleType, BuyV2ShopSaleType.courier);
      expect(session.catalogueSaleTypeProducts, isNotEmpty);
      expect(
        session.catalogueSaleTypeProducts.every(
          (product) =>
              session.fulfilmentModeFor(product) ==
              BuyV2FulfilmentMode.standardCourier,
        ),
        isTrue,
      );
    });

    test('Wholesale sale type separates regular and higher-volume MOQ', () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.openDestination(BuyV2Destination.wholesale);

      expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.wholesale);
      expect(session.catalogueSaleTypeProducts, isNotEmpty);
      expect(
        session.catalogueSaleTypeProducts.every(
          (product) => product.minimumOrder <= 2,
        ),
        isTrue,
      );

      session.addProduct(session.catalogueSaleTypeProducts.first.id);
      final itemCount = session.itemCount;
      session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
      expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.bulk);
      expect(session.catalogueSaleTypeProducts, isNotEmpty);
      expect(
        session.catalogueSaleTypeProducts.every(
          (product) => product.minimumOrder > 2,
        ),
        isTrue,
      );
      expect(session.itemCount, itemCount);
    });

    test('placed Shop order distinguishes products from item quantity', () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      expect(session.addProduct('s-tomato'), isTrue);
      session.increase('s-tomato');
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      expect(session.confirmOrder(), isTrue);

      expect(session.confirmedOrders, hasLength(1));
      expect(
        session.confirmedOrders.single.itemSummary,
        startsWith('1 product · 2 items ·'),
      );
    });
  });
}
