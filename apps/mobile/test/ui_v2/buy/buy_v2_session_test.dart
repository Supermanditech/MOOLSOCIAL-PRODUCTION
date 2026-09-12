import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_catalogue_data.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/work/scan_and_pick_contract.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart'
    show showBuyV2CatalogueArea;

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;
import 'buy_v2_discovery_refinement_test.dart'
    show R669BrandCommerce, r669BrandedSession;

final class _R669ProcurementCommerce implements BuyV2CommerceAdapter {
  _R669ProcurementCommerce(this.snapshot);
  BuyV2CommerceSnapshot snapshot;
  Completer<BuyV2CommerceSnapshot>? refreshGate;
  Completer<BuyV2OrderPlacementResult>? placementGate;
  Completer<BuyV2OrderPlacementResult>? reconciliationGate;
  final placements = <BuyV2OrderPlacementRequest>[];
  int reconciliations = 0;
  BuyV2OrderPlacementResult placement = const BuyV2OrderPlacementResult(
    outcome: BuyV2OrderPlacementOutcome.paymentPending,
    customerMessage: 'Payment confirmation is pending.',
    paymentReference: 'procurement-payment',
  );

  @override
  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  ) {
    placements.add(request);
    return placementGate?.future ?? Future.value(placement);
  }

  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  }) {
    reconciliations++;
    return reconciliationGate?.future ?? Future.value(placement);
  }

  @override
  Future<BuyV2CommerceSnapshot> refresh() {
    final gate = refreshGate;
    refreshGate = null;
    return gate?.future ?? Future.value(snapshot);
  }

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: false,
        enabled: false,
        customerMessage: 'Order alerts are unavailable.',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected procurement fixture operation');
}

final class _R669ProcurementCatalogue implements BuyV2CataloguePageSource {
  _R669ProcurementCatalogue(this.products);
  final List<BuyV2Product> products;
  Completer<void>? gate;
  Completer<void>? resolutionGate;
  BuyV2CatalogueQuery? lastQuery;

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    lastQuery = query;
    await gate?.future;
    return BuyV2CataloguePage(
      queryKey: query.key,
      snapshotId: 'procurement-page',
      items: products,
      startIndex: 0,
      totalCount: products.length,
    );
  }

  @override
  Future<List<BuyV2Product>> resolveProducts(Set<String> productIds) async {
    await resolutionGate?.future;
    return products
        .where((product) => productIds.contains(product.id))
        .toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected procurement catalogue fixture operation');
}

final class _R669OrderReadyFacts implements BuyV2ProductFactsAdapter {
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) =>
      const BuyV2CatalogueProductFactsAdapter()
          .snapshotFor(product)
          .copyWith(
            promisedByLabel: '11 September, 2–4 PM',
            sourceId: 'r669-order-ready-fixture',
          );
}

BuyV2Session _r669OrderReadySession() {
  final core = BuySession();
  final session = BuyV2Session(
    core: core,
    productFactsAdapter: _R669OrderReadyFacts(),
  );
  addTearDown(core.dispose);
  addTearDown(session.dispose);
  return session;
}

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
  Completer<BuyV2OrderRefreshResult>? orderRefreshGate;
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
    return orderRefreshGate == null
        ? orderRefreshResult
        : orderRefreshGate!.future;
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

final class _R669PreferenceWriteState {
  Completer<void>? hold;
  int started = 0;
}

final class _R669StringPreferences implements SharedPreferencesAsync {
  final Map<String, String> values = {};
  final _writeState = _R669PreferenceWriteState();
  Completer<void>? get holdNextWrite => _writeState.hold;
  set holdNextWrite(Completer<void>? value) => _writeState.hold = value;
  int get writesStarted => _writeState.started;

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    final hold = holdNextWrite;
    holdNextWrite = null;
    _writeState.started++;
    if (hold != null) await hold.future;
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected preferences fixture operation');
}

final class _MemoryCustomerStateStore implements BuyV2CustomerStateStore {
  _MemoryCustomerStateStore(this.ownerScope);

  @override
  final String ownerScope;

  BuyV2CustomerStateSnapshot? snapshot;
  Completer<BuyV2CustomerStateSnapshot?>? pendingRead;
  Completer<void>? pendingWrite;
  int writeCalls = 0;
  bool rejectWrites = false;

  @override
  Future<BuyV2CustomerStateSnapshot?> read() async =>
      pendingRead == null ? snapshot : pendingRead!.future;

  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async {
    writeCalls++;
    if (pendingWrite case final pending?) await pending.future;
    if (rejectWrites) return false;
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
  bool wrongResolution = false;
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
    return super.resolveProducts(
      wrongResolution ? {productIdAt(999, 7)} : productIds,
    );
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

Future<BuyV2Session> _openOrderSearchFixture({
  BuyV2OrderStatus tomatoStatus = BuyV2OrderStatus.preparing,
  String? deliveryPartnerName,
}) async {
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
    promise: 'Delivery in 12 min',
    deliveryPartnerName: deliveryPartnerName,
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
          order('MS-SEARCH-TOMATO', tomato, status: tomatoStatus),
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

final class _R669ShoppingAreas implements BuyV2ShoppingAreaSource {
  List<BuyV2ShoppingArea> areas = [];
  Object? failure;
  final queries = <String>[];
  final pending = <String, Completer<List<BuyV2ShoppingArea>>>{};
  @override
  Future<List<BuyV2ShoppingArea>> search(String query) async {
    queries.add(query);
    if (failure case final error?) throw error;
    return pending[query]?.future ?? Future.value(areas);
  }

  @override
  Future<BuyV2ShoppingArea?> locate() async {
    if (failure case final error?) throw error;
    return areas.firstOrNull;
  }

  @override
  Future<BuyV2ShoppingArea?> resolve(String googlePlaceId) async =>
      areas.where((area) => area.googlePlaceId == googlePlaceId).firstOrNull;
}

void r669ShoppingAreaTests() {
  group('R669 India shopping area', () {
    const area = BuyV2ShoppingArea(
      regionId: 'region-up-village',
      googlePlaceId: 'google-up-village',
      label: 'Rural locality, Uttar Pradesh',
      countryCode: 'IN',
      postalCode: '221005',
    );
    BuyV2Session makeSession(
      _R669ShoppingAreas? source, {
      BuyV2CustomerStateStore? store,
    }) {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        shoppingAreaSource: source,
        customerStateStore: store,
        catalogueAreas: const {'jodhpur': 'Jodhpur'},
        initialCatalogueRegionId: 'jodhpur',
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      return session;
    }

    for (final place in [
      ('221005', 'Rural locality, Uttar Pradesh'),
      ('700001', 'Kolkata, West Bengal'),
      ('380001', 'Ahmedabad, Gujarat'),
      ('560001', 'Bengaluru, Karnataka'),
    ]) {
      test('finds new ${place.$1} without a bundled city entry', () async {
        final found = BuyV2ShoppingArea(
          regionId: 'region-${place.$1}',
          googlePlaceId: 'google-${place.$1}',
          label: place.$2,
          countryCode: 'IN',
          postalCode: place.$1,
        );
        final source = _R669ShoppingAreas()..areas = [found];
        final session = makeSession(source);
        final matches = await session.searchShoppingAreas(place.$1);
        expect(source.queries, [place.$1]);
        expect(session.catalogueRegionId, 'jodhpur');
        expect(
          session.chooseShoppingArea(
            matches.single,
            BuyV2CatalogueAreaScope.national,
          ),
          isTrue,
        );
        expect(session.catalogueRegionId, found.regionId);
        expect(session.catalogueAreaLabel, found.label);
        expect(session.catalogueQuery().regionId, found.regionId);
        expect(session.catalogueOffersQuery().regionId, found.regionId);
        expect(
          session
              .catalogueQuery(catalogueDestination: BuyV2Destination.wholesale)
              .areaScope,
          BuyV2CatalogueAreaScope.national,
        );
      });
    }
    for (final invalid in [
      const BuyV2ShoppingArea(
        regionId: 'foreign',
        googlePlaceId: 'foreign',
        label: 'Outside India',
        countryCode: 'GB',
      ),
      const BuyV2ShoppingArea(
        regionId: 'bad-pin',
        googlePlaceId: 'bad-pin',
        label: 'Invalid PIN',
        countryCode: 'IN',
        postalCode: '000000',
      ),
      const BuyV2ShoppingArea(
        regionId: '',
        googlePlaceId: 'missing-region',
        label: 'No mapped region',
        countryCode: 'IN',
      ),
    ]) {
      test('rejects invalid ${invalid.googlePlaceId}', () async {
        final session = makeSession(_R669ShoppingAreas()..areas = [invalid]);
        await expectLater(
          session.searchShoppingAreas('area'),
          throwsA(BuyV2ShoppingAreaFailure.unavailable),
        );
        expect(session.catalogueRegionId, 'jodhpur');
      });
    }
    test('rejects unreturned and duplicate places', () async {
      final session = makeSession(_R669ShoppingAreas()..areas = [area, area]);
      expect(
        session.chooseShoppingArea(area, BuyV2CatalogueAreaScope.regional),
        isFalse,
      );
      await expectLater(
        session.searchShoppingAreas('area'),
        throwsA(BuyV2ShoppingAreaFailure.unavailable),
      );
    });
    test(
      'current location requires selection and permission failure keeps Cart',
      () async {
        final source = _R669ShoppingAreas()..areas = [area];
        final session = makeSession(source);
        final product = BuyV2Catalogue.products.first;
        session.addProduct(product.id);
        final quantity = session.quantityFor(product.id);
        final found = await session.locateShoppingArea();
        expect(session.catalogueRegionId, 'jodhpur');
        source.failure = BuyV2ShoppingAreaFailure.permissionDenied;
        await expectLater(
          session.locateShoppingArea(),
          throwsA(BuyV2ShoppingAreaFailure.permissionDenied),
        );
        expect(session.catalogueRegionId, 'jodhpur');
        expect(session.quantityFor(product.id), quantity);
        source.failure = null;
        expect(
          session.chooseShoppingArea(
            found.single,
            BuyV2CatalogueAreaScope.regional,
          ),
          isTrue,
        );
      },
    );
    test('late search cannot replace a newer selection', () async {
      final source = _R669ShoppingAreas()..areas = [area];
      source.pending['old'] = Completer<List<BuyV2ShoppingArea>>();
      final session = makeSession(source);
      final old = session.searchShoppingAreas('old');
      final fresh = await session.searchShoppingAreas('new');
      expect(
        session.chooseShoppingArea(
          fresh.single,
          BuyV2CatalogueAreaScope.regional,
        ),
        isTrue,
      );
      source.pending['old']!.complete([area]);
      expect(await old, isEmpty);
      expect(session.catalogueRegionId, area.regionId);
    });
    test('retains selection IDs and Cart through codec and relaunch', () async {
      final preferences = _R669StringPreferences();
      final store = BuyV2SharedPreferencesCustomerStateStore(
        preferences,
        ownerScope: 'area-buyer',
      );
      final source = _R669ShoppingAreas()..areas = [area];
      final session = makeSession(source, store: store);
      await session.restoreCustomerState();
      final product = BuyV2Catalogue.products.first;
      session.addProduct(product.id);
      final quantity = session.quantityFor(product.id);
      final found = await session.searchShoppingAreas('221005');
      session.chooseShoppingArea(
        found.single,
        BuyV2CatalogueAreaScope.regional,
      );
      await Future<void>.delayed(Duration.zero);
      final encoded = preferences.values.values.single;
      expect(encoded, contains(area.googlePlaceId));
      expect(encoded, isNot(contains(area.label)));
      final restored = makeSession(source, store: store);
      await restored.restoreCustomerState();
      await Future<void>.delayed(Duration.zero);
      expect(restored.catalogueRegionId, area.regionId);
      expect(restored.shoppingGooglePlaceId, area.googlePlaceId);
      expect(restored.catalogueAreaLabel, area.label);
      expect(restored.quantityFor(product.id), quantity);
    });
    test(
      'manual area during Cart restore survives the late snapshot',
      () async {
        final source = _R669ShoppingAreas()..areas = [area];
        final store = _MemoryCustomerStateStore('area-delayed-restore');
        final product = BuyV2Catalogue.products.first;
        final prior = BuyV2CustomerStateSnapshot(
          cartQuantities: {product.id: 3},
          shoppingRegionId: 'jodhpur',
          shoppingAreaScope: BuyV2CatalogueAreaScope.regional.name,
        );
        store.snapshot = prior;
        store.pendingRead = Completer<BuyV2CustomerStateSnapshot?>();
        final session = makeSession(source, store: store);
        final restoring = session.restoreCustomerState();
        await Future<void>.delayed(Duration.zero);
        final found = await session.searchShoppingAreas('221005');
        expect(
          session.chooseShoppingArea(
            found.single,
            BuyV2CatalogueAreaScope.regional,
          ),
          isTrue,
        );
        expect(store.snapshot!.cartQuantities[product.id], 3);
        store.pendingRead!.complete(prior);
        await restoring;
        await Future<void>.delayed(Duration.zero);
        expect(session.catalogueRegionId, area.regionId);
        expect(session.quantityFor(product.id), 3);
        expect(store.snapshot!.shoppingRegionId, area.regionId);
        expect(store.snapshot!.cartQuantities[product.id], 3);
      },
    );
    test(
      'provider absence is recoverable and does not select a guessed PIN',
      () async {
        final session = makeSession(null);
        await expectLater(
          session.searchShoppingAreas('221005'),
          throwsA(BuyV2ShoppingAreaFailure.unavailable),
        );
        expect(session.catalogueRegionId, 'jodhpur');
        session.chooseCatalogueArea(null, BuyV2CatalogueAreaScope.allAreas);
        expect(session.catalogueAreaLabel, 'Any area');
      },
    );
    for (final scale in [1.0, 2.0]) {
      testWidgets('sheet search keyboard retry selection and Back $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final source = _R669ShoppingAreas()..areas = [area];
        final session = makeSession(source);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (_, child) => r66VisualCaptureRoot(child!),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showBuyV2CatalogueArea(context, session),
                  child: const Text('Choose shopping area'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Choose shopping area'));
        await tester.pumpAndSettle();
        final search = find.byKey(const ValueKey('buy-catalogue-area-search'));
        await tester.enterText(search, '221005');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(source.queries, ['221005']);
        await captureR66Visual(tester, 'r669-location-search-$scale');
        await tester.scrollUntilVisible(
          find.text('Google Maps'),
          140,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('buy-catalogue-area-list')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Google Maps'), findsOneWidget);
        final result = find.byKey(
          ValueKey('buy-google-area-${area.googlePlaceId}'),
        );
        Future<void> revealResult() async {
          final scrollable = find
              .descendant(
                of: find.byKey(const ValueKey('buy-catalogue-area-list')),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            find.text('Shopping area'),
            -180,
            scrollable: scrollable,
          );
          await tester.scrollUntilVisible(result, 100, scrollable: scrollable);
          await tester.pumpAndSettle();
        }

        tester.view.viewInsets = const FakeViewPadding(bottom: 230);
        await tester.pumpAndSettle();
        await revealResult();
        expect(tester.takeException(), isNull);
        await captureR66Visual(tester, 'r669-location-keyboard-$scale');
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        await revealResult();
        await tester.tap(result);
        await tester.pumpAndSettle();
        expect(session.catalogueRegionId, area.regionId);
        expect(find.text('Shopping area'), findsNothing);
        await tester.tap(find.text('Choose shopping area'));
        await tester.pumpAndSettle();
        source.failure = BuyV2ShoppingAreaFailure.permissionDenied;
        final locate = find.byKey(const ValueKey('buy-catalogue-current-area'));
        await tester.ensureVisible(locate);
        await tester.tap(locate);
        await tester.pumpAndSettle();
        final retry = find.byKey(const ValueKey('buy-area-lookup-retry'));
        await tester.ensureVisible(retry);
        await tester.pumpAndSettle();
        await captureR66Visual(tester, 'r669-location-permission-$scale');
        expect(session.catalogueRegionId, area.regionId);
        source.failure = null;
        await tester.tap(retry);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Google Maps'),
          120,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('buy-catalogue-area-list')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.text('Google Maps'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.catalogueRegionId, area.regionId);
        source.pending['700001'] = Completer<List<BuyV2ShoppingArea>>();
        await tester.tap(find.text('Choose shopping area'));
        await tester.pumpAndSettle();
        await tester.enterText(search, '700001');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.binding.handlePopRoute();
        await tester.pump(const Duration(milliseconds: 500));
        source.pending['700001']!.complete([area]);
        await tester.pumpAndSettle();
        expect(find.text('Shopping area'), findsNothing);
        expect(session.catalogueRegionId, area.regionId);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

void r669SharedProductTests() {
  group('R669 shared product', () {
    BuyV2Session makeSession(_PagingRecoverySource? source) {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        reviewDataEnabled: true,
        cataloguePageSource: source,
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      return session;
    }

    test('URL carries exact encoded public listing identity only', () {
      final product = BuyV2Catalogue.products.first.copyWith(
        id: 'store/sku ?&=हिंदी#variant',
      );
      final uri = buyV2SharedProductUri(product);
      expect(uri.scheme, 'https');
      expect(uri.host, 'moolsocial.com');
      expect(uri.path, '/app/buy');
      expect(uri.fragment, isEmpty);
      expect(Uri.parse(uri.toString()).queryParameters, {
        'sub': product.destination.name,
        'view': 'product',
        'product': product.id,
      });
    });

    test('known product opens without a resolver and retains Cart', () async {
      final session = makeSession(null);
      session.addProduct('s-tomato');
      expect(await session.openLinkedProduct('s-oil'), isTrue);
      expect(session.selectedProductId, 's-oil');
      expect(session.linkedProductRecoveryId, isNull);
      expect(session.quantityFor('s-tomato'), 1);
      session.goBack();
      expect(session.view, BuyV2View.catalogue);
    });

    test('cold listing keeps exact supplier pack search and Cart', () async {
      final source = _PagingRecoverySource();
      final session = makeSession(source);
      final id = source.productIdAt(12, 4);
      final expected = (await source.resolveProducts({id})).single;
      source.resolutionRequests.clear();
      session.addProduct('s-tomato');
      session.updateQuery('retained groceries');
      expect(session.findProduct(id), isNull);
      expect(await session.openLinkedProduct(id), isTrue);
      expect(source.resolutionRequests, [
        {id},
      ]);
      expect(session.selectedProductId, id);
      expect(session.selectedProduct!.storeId, expected.storeId);
      expect(session.selectedProduct!.pack, expected.pack);
      expect(session.quantityFor('s-tomato'), 1);
      expect(session.addProduct(id), isTrue);
      expect(session.quantityFor(id), expected.minimumOrder);
      session.goBack();
      expect(session.view, BuyV2View.catalogue);
      expect(session.query, 'retained groceries');
      expect(session.quantityFor('s-tomato'), 1);
    });

    test(
      'failed resolution retries the same listing without clearing Cart',
      () async {
        final source = _PagingRecoverySource()..failResolution = true;
        final session = makeSession(source);
        final id = source.productIdAt(12, 4);
        session.addProduct('s-tomato');
        expect(await session.openLinkedProduct(id), isFalse);
        expect(session.linkedProductRecoveryId, id);
        expect(session.linkedProductLoading, isFalse);
        expect(session.quantityFor('s-tomato'), 1);
        source.failResolution = false;
        expect(await session.openLinkedProduct(id), isTrue);
        expect(session.selectedProductId, id);
        expect(session.quantityFor('s-tomato'), 1);
      },
    );

    for (final id in ['', 'removed-listing']) {
      test('unavailable identity "$id" never opens a substitute', () async {
        final session = makeSession(_PagingRecoverySource());
        expect(await session.openLinkedProduct(id), isFalse);
        expect(session.selectedProduct, isNull);
        expect(session.linkedProductRecoveryId, id);
        expect(session.linkedProductLoading, isFalse);
        session.goBack();
        expect(session.view, BuyV2View.catalogue);
      });
    }

    test('Back rejects a late resolved listing and keeps search', () async {
      final source = _PagingRecoverySource()
        ..resolutionGate = Completer<void>();
      final session = makeSession(source);
      final id = source.productIdAt(12, 4);
      session.updateQuery('keep search');
      final pending = session.openLinkedProduct(id);
      expect(session.linkedProductLoading, isTrue);
      session.goBack();
      source.resolutionGate!.complete();
      expect(await pending, isFalse);
      expect(session.findProduct(id), isNull);
      expect(session.view, BuyV2View.catalogue);
      expect(session.query, 'keep search');
    });

    test('provider cannot substitute a different supplier listing', () async {
      final source = _PagingRecoverySource()..wrongResolution = true;
      final session = makeSession(source);
      final id = source.productIdAt(12, 4);
      expect(await session.openLinkedProduct(id), isFalse);
      expect(session.findProduct(id), isNull);
      expect(session.findProduct(source.productIdAt(999, 7)), isNull);
      expect(session.linkedProductRecoveryId, id);
    });

    test('disposed recipient session ignores a late listing', () async {
      final source = _PagingRecoverySource()
        ..resolutionGate = Completer<void>();
      final core = BuySession();
      final session = BuyV2Session(core: core, cataloguePageSource: source);
      addTearDown(core.dispose);
      final pending = session.openLinkedProduct(source.productIdAt(12, 4));
      session.dispose();
      source.resolutionGate!.complete();
      expect(await pending, isFalse);
    });

    test('new product link wins over a pending older link', () async {
      final source = _PagingRecoverySource()
        ..resolutionGate = Completer<void>();
      final session = makeSession(source);
      final firstId = source.productIdAt(12, 4);
      final secondId = source.productIdAt(13, 5);
      final first = session.openLinkedProduct(firstId);
      final second = session.openLinkedProduct(secondId);
      source.resolutionGate!.complete();
      expect(await first, isFalse);
      expect(await second, isTrue);
      expect(session.selectedProductId, secondId);
      expect(session.findProduct(firstId), isNull);
    });

    testWidgets('ordinary Shop replacement preserves its supplied Cart view', (
      tester,
    ) async {
      final first = makeSession(null);
      final second = makeSession(null)
        ..addProduct('s-oil')
        ..openCart(scope: BuyV2CartScope.shop);
      Widget app(BuyV2Session session) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session, onExit: () {}),
      );
      await tester.pumpWidget(app(first));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(second));
      await tester.pumpAndSettle();
      expect(second.view, BuyV2View.cart);
      expect(second.quantityFor('s-oil'), 1);
      expect(second.linkedProductRecoveryId, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('recipient session replacement reapplies the same link', (
      tester,
    ) async {
      final oldSource = _PagingRecoverySource()
        ..resolutionGate = Completer<void>();
      final oldSession = makeSession(oldSource)..addProduct('s-tomato');
      final newSession = makeSession(_PagingRecoverySource())
        ..addProduct('s-oil');
      final id = oldSource.productIdAt(12, 4);
      Widget app(BuyV2Session session) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session, productId: id, onExit: () {}),
      );
      await tester.pumpWidget(app(oldSession));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Opening product'), findsOneWidget);
      await tester.pumpWidget(app(newSession));
      await tester.pumpAndSettle();
      expect(newSession.selectedProductId, id);
      expect(newSession.quantityFor('s-oil'), 1);
      expect(newSession.quantityFor('s-tomato'), 0);
      oldSource.resolutionGate!.complete();
      await tester.pumpAndSettle();
      expect(
        tester.widget<BuyV2Screen>(find.byType(BuyV2Screen)).session,
        same(newSession),
      );
      expect(newSession.selectedProductId, id);
      expect(newSession.quantityFor('s-oil'), 1);
      expect(tester.takeException(), isNull);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('recipient loading Retry product and Back 320x568 $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.reset);
        final source = _PagingRecoverySource()
          ..resolutionGate = Completer<void>()
          ..failResolution = true;
        final session = makeSession(source);
        final id = source.productIdAt(12, 4);
        session.addProduct('s-tomato');
        Widget app(String productId) => r66VisualCaptureRoot(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 24, bottom: 24),
              ),
              child: child!,
            ),
            home: BuyV2Screen(
              session: session,
              productId: productId,
              onExit: () {},
            ),
          ),
        );
        await tester.pumpWidget(app(id));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Opening product'), findsOneWidget);
        expect(tester.takeException(), isNull);
        source.resolutionGate!.complete();
        await tester.pumpAndSettle();
        expect(find.text('Product unavailable'), findsOneWidget);
        await captureR66Visual(tester, 'r669-share-unavailable-$scale');
        source.failResolution = false;
        await tester.ensureVisible(
          find.byKey(const ValueKey('buy-catalogue-retry')),
        );
        await tester.tap(find.byKey(const ValueKey('buy-catalogue-retry')));
        await tester.pumpAndSettle();
        expect(session.selectedProductId, id);
        expect(session.linkedProductRecoveryId, isNull);
        expect(session.quantityFor('s-tomato'), 1);
        expect(tester.takeException(), isNull);
        await captureR66Visual(tester, 'r669-share-product-$scale');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.catalogue);
        expect(session.quantityFor('s-tomato'), 1);
        await tester.pumpWidget(app('s-oil'));
        await tester.pumpAndSettle();
        expect(session.selectedProductId, 's-oil');
        expect(tester.takeException(), isNull);
      });
    }
  });
}

void main() {
  test('R669 review draft codec relaunch keeps cart and isolates customer', () async {
    final preferences = _R669StringPreferences();
    BuyV2Session make(String owner) {
      final core = BuySession();
      final session = BuyV2Session(core: core, customerStateStore:
        BuyV2SharedPreferencesCustomerStateStore(preferences, ownerScope: owner));
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      return session;
    }
    final session = make('draft-customer-a');
    await session.restoreCustomerState();
    session.addProduct('s-milk');
    final quantity = session.quantityFor('s-milk');
    session.retainProductReviewDraft(productId: 's-milk', rating: 4,
      comment: 'Keep my unsent review.', ownerScope: session.reviewDraftOwnerScope);
    session.retainProductReviewDraft(productId: 's-tomato', rating: 2,
      comment: 'A separate product.', ownerScope: session.reviewDraftOwnerScope);
    await Future<void>.delayed(Duration.zero);
    final restarted = make('draft-customer-a');
    await restarted.restoreCustomerState();
    expect(restarted.productReviewDraft('s-milk')?.rating, 4);
    expect(restarted.productReviewDraft('s-milk')?.comment, 'Keep my unsent review.');
    expect(restarted.productReviewDraft('s-tomato')?.comment, 'A separate product.');
    expect(restarted.customerReviewFor('s-milk'), isNull);
    expect(restarted.quantityFor('s-milk'), quantity);
    final other = make('draft-customer-b');
    await other.restoreCustomerState();
    expect(other.productReviewDraft('s-milk'), isNull);
    other.retainProductReviewDraft(productId: 's-milk', rating: 5,
      comment: 'Stale owner edit', ownerScope: 'draft-customer-a');
    expect(other.productReviewDraft('s-milk'), isNull);
    expect(restarted.submitProductReview(productId: 's-milk', rating: 0, comment: ''), isFalse);
    expect(restarted.productReviewDraft('s-milk'), isNotNull);
    expect(restarted.submitProductReview(productId: 's-milk', rating: 4, comment: 'Keep my unsent review.'), isTrue);
    expect(restarted.productReviewDraft('s-milk'), isNull);
    expect(restarted.productReviewDraft('s-tomato'), isNotNull);
    await Future<void>.delayed(Duration.zero);
    final afterSubmission = make('draft-customer-a');
    await afterSubmission.restoreCustomerState();
    expect(afterSubmission.productReviewDraft('s-milk'), isNull);
    expect(afterSubmission.productReviewDraft('s-tomato'), isNotNull);
  });

  r669SharedProductTests();
  r669ShoppingAreaTests();
  r669ComparisonContractTests();
  group('STORE-PROCUREMENT-ELIGIBILITY-01 contract', () {
    final now = DateTime.utc(2026, 9, 10, 10);
    final expiry = now.add(const Duration(minutes: 10));
    final product = BuyV2Catalogue.products
        .firstWhere((item) => item.destination == BuyV2Destination.wholesale)
        .copyWith(storeId: 'supplier-branch', sellerType: 'Manufacturer');

    BuyV2ProcurementContext scope({
      String account = 'buyer-account',
      String store = 'purchasing-store',
      BuyV2ProcurementPurpose purpose = BuyV2ProcurementPurpose.restock,
      String origin = 'restock-operation',
    }) => BuyV2ProcurementContext(
      accountId: account,
      storeId: store,
      purpose: purpose,
      originOperationId: origin,
    );

    BuyV2ProcurementBuyerGrant buyer({
      String account = 'buyer-account',
      String store = 'purchasing-store',
      bool approved = true,
      DateTime? until,
    }) => BuyV2ProcurementBuyerGrant(
      accountId: account,
      storeId: store,
      approved: approved,
      validUntil: until ?? expiry,
    );

    BuyV2ProcurementSupplierGrant supplier({
      BuyV2SupplierWorkspaceRole role = BuyV2SupplierWorkspaceRole.wholesaler,
      BuyV2SupplierListingChannel channel =
          BuyV2SupplierListingChannel.wholesale,
      bool approved = true,
      bool published = true,
      String workspace = 'approved-supply-workspace',
      String store = 'supplier-branch',
      String? listing,
      String? canonical,
      String offer = 'offer-1',
      String revision = 'revision-2',
      DateTime? until,
    }) => BuyV2ProcurementSupplierGrant(
      workspaceId: workspace,
      storeId: store,
      role: role,
      approved: approved,
      listingId: listing ?? product.id,
      productCanonicalId: canonical ?? product.canonicalId,
      offerId: offer,
      offerRevision: revision,
      channel: channel,
      published: published,
      validUntil: until ?? expiry,
    );

    BuyV2ProcurementEligibility evaluate({
      BuyV2ProcurementContext? context,
      BuyV2ProcurementBuyerGrant? buyerGrant,
      BuyV2ProcurementSupplierGrant? supplierGrant,
      String account = 'buyer-account',
      String store = 'purchasing-store',
      String? expectedOfferId,
      String? expectedOfferRevision,
    }) => buyV2ProcurementEligibility(
      context: context ?? scope(),
      activeAccountId: account,
      activeStoreId: store,
      buyer: buyerGrant ?? buyer(),
      supplier: supplierGrant ?? supplier(),
      product: product,
      now: now,
      expectedOfferId: expectedOfferId,
      expectedOfferRevision: expectedOfferRevision,
    );

    BuyV2CommerceSnapshot commerceSnapshot({
      List<BuyV2Product>? products,
      List<BuyV2Order> orders = const [],
      BuyV2ProcurementBuyerGrant? grant,
      bool omitGrant = false,
    }) => BuyV2CommerceSnapshot(
      state: BuyV2CommerceLoadState.ready,
      products:
          products ?? [product.copyWith(procurementSupplierGrant: supplier())],
      orders: orders,
      businessVerified: true,
      businessVerificationState: BuyV2BusinessVerificationState.verified,
      paymentMethods: const {'Cash on Delivery', 'PhonePe'},
      addresses: const [
        BuyV2Address(
          id: 'receiving-store',
          kind: BuyV2AddressKind.work,
          label: 'Store receiving',
          recipient: 'Store purchasing team',
          phone: '9000000000',
          line: '12, Central Avenue',
          area: 'Sardarpura, Jodhpur',
          pinCode: '342003',
          landmark: 'Near the market',
        ),
      ],
      selectedAddressId: 'receiving-store',
      procurementBuyerGrant: omitGrant ? null : (grant ?? buyer()),
    );

    Future<
      ({
        BuyV2Session session,
        ValueNotifier<BuyV2ProcurementContext?> identity,
        BuyV2CustomerStateStore store,
        _R669ProcurementCommerce adapter,
      })
    >
    scopedSession({
      BuyV2ProcurementContext? context,
      BuyV2CommerceSnapshot? snapshot,
      BuyV2CustomerStateStore? retainedStore,
      BuyV2CataloguePageSource? catalogueSource,
    }) async {
      final entry = context ?? scope();
      final core = BuySession();
      final identity = ValueNotifier<BuyV2ProcurementContext?>(entry);
      final store =
          retainedStore ??
          _MemoryCustomerStateStore(entry.customerStateOwnerScope);
      final adapter = _R669ProcurementCommerce(snapshot ?? commerceSnapshot());
      final session = BuyV2Session(
        core: core,
        procurementIdentity: identity,
        customerStateStore: store,
        commerceAdapter: adapter,
        reviewDataEnabled: false,
        productFactsAdapter: _R669OrderReadyFacts(),
        cataloguePageSource: catalogueSource,
        catalogueNow: () => now,
      );
      addTearDown(core.dispose);
      addTearDown(identity.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      session.openDestination(BuyV2Destination.wholesale);
      return (
        session: session,
        identity: identity,
        store: store,
        adapter: adapter,
      );
    }

    for (final role in [
      BuyV2SupplierWorkspaceRole.wholesaler,
      BuyV2SupplierWorkspaceRole.mandi,
      BuyV2SupplierWorkspaceRole.manufacturer,
      BuyV2SupplierWorkspaceRole.retailer,
    ]) {
      for (final purpose in [
        BuyV2ProcurementPurpose.restock,
        BuyV2ProcurementPurpose.buyDirect,
      ]) {
        test('R669 shared product enforces $role for $purpose', () async {
          final id = 'shared-${role.name}-${purpose.name}';
          final offered = product.copyWith(
            id: id,
            procurementSupplierGrant: supplier(role: role, listing: id),
          );
          final source = _R669ProcurementCatalogue([offered]);
          final fixture = await scopedSession(
            context: scope(purpose: purpose),
            snapshot: commerceSnapshot(products: []),
            catalogueSource: source,
          );
          final session = fixture.session;
          await session.restoreCustomerState();
          final expected = purpose == BuyV2ProcurementPurpose.buyDirect
              ? role == BuyV2SupplierWorkspaceRole.manufacturer
              : role != BuyV2SupplierWorkspaceRole.retailer;
          expect(await session.openLinkedProduct(id), expected);
          if (expected) {
            expect(session.selectedProductId, id);
            expect(session.linkedProductRecoveryId, isNull);
          } else {
            expect(session.linkedProductRecoveryId, id);
            expect(session.addProduct(id), isFalse);
          }
          session.goBack();
          expect(session.view, BuyV2View.catalogue);
          expect(session.destination, BuyV2Destination.wholesale);
          expect(
            session.procurementContext!.originOperationId,
            'restock-operation',
          );
        });
      }
    }

    test(
      'R669 shared product Retry refreshes a rejected cached offer',
      () async {
        final id = 'shared-eligibility-refresh';
        final offered = product.copyWith(
          id: id,
          procurementSupplierGrant: supplier(
            listing: id,
            role: BuyV2SupplierWorkspaceRole.retailer,
          ),
        );
        final source = _R669ProcurementCatalogue([offered]);
        final fixture = await scopedSession(
          snapshot: commerceSnapshot(products: []),
          catalogueSource: source,
        );
        await fixture.session.restoreCustomerState();
        expect(await fixture.session.openLinkedProduct(id), isFalse);
        expect(fixture.session.linkedProductRecoveryId, id);
        source.products
          ..clear()
          ..add(
            offered.copyWith(procurementSupplierGrant: supplier(listing: id)),
          );
        expect(await fixture.session.openLinkedProduct(id), isTrue);
        expect(fixture.session.selectedProductId, id);
        expect(fixture.session.linkedProductRecoveryId, isNull);
      },
    );

    test(
      'R669 shared product discards late response after Store switch',
      () async {
        final id = 'shared-store-switch';
        final offered = product.copyWith(
          id: id,
          procurementSupplierGrant: supplier(listing: id),
        );
        final source = _R669ProcurementCatalogue([offered])
          ..resolutionGate = Completer<void>();
        final fixture = await scopedSession(
          snapshot: commerceSnapshot(products: []),
          catalogueSource: source,
        );
        await fixture.session.restoreCustomerState();
        final pending = fixture.session.openLinkedProduct(id);
        fixture.identity.value = scope(store: 'different-store');
        source.resolutionGate!.complete();
        expect(await pending, isFalse);
        expect(fixture.session.findProduct(id), isNull);
        expect(fixture.session.procurementScopeCurrent, isFalse);
      },
    );

    test(
      'R669 persistence restores browsing and exact Cart product Back chain',
      () async {
        final preferences = _R669StringPreferences();
        BuyV2SharedPreferencesCustomerStateStore reopen() =>
            BuyV2SharedPreferencesCustomerStateStore(
              preferences,
              ownerScope: scope().customerStateOwnerScope,
            );
        final first = await scopedSession(retainedStore: reopen());
        await first.session.restoreCustomerState();
        first.session.chooseCategory(product.categoryId);
        first.session.updateQuery(product.title);
        first.session.applyDiscoveryRefinements(
          BuyV2DiscoveryRefinements(
            brands: {product.brand},
            maximumPrice: 10000,
            pack: BuyV2PackFilter.bulk,
            fulfilmentMode: BuyV2FulfilmentMode.bulkFreight,
            sort: BuyV2ProductSort.priceLowToHigh,
            availableOnly: true,
          ),
        );
        expect(first.session.addProduct(product.id), isTrue);
        expect(first.session.openProduct(product.id), isTrue);
        first.session.openCart(scope: BuyV2CartScope.wholesale);
        first.session.rememberCartScrollOffset(BuyV2CartScope.wholesale, 140);
        first.session.retainProcurementNavigation();
        await Future<void>.delayed(Duration.zero);
        final fresh = await scopedSession(retainedStore: reopen());
        await fresh.session.restoreCustomerState();
        expect(fresh.session.view, BuyV2View.cart);
        expect(fresh.session.destination, BuyV2Destination.wholesale);
        expect(fresh.session.query, product.title);
        expect(fresh.session.selectedCategoryId, product.categoryId);
        expect(fresh.session.selectedBrands, {product.brand});
        expect(fresh.session.maximumProductPrice, 10000);
        expect(fresh.session.selectedPackFilter, BuyV2PackFilter.bulk);
        expect(
          fresh.session.selectedFulfilmentMode,
          BuyV2FulfilmentMode.bulkFreight,
        );
        expect(fresh.session.productSort, BuyV2ProductSort.priceLowToHigh);
        expect(fresh.session.availableProductsOnly, isTrue);
        expect(
          fresh.session.cartScrollOffsetFor(BuyV2CartScope.wholesale),
          140,
        );
        fresh.session.goBack();
        expect(fresh.session.view, BuyV2View.product);
        expect(fresh.session.selectedProductId, product.id);
        fresh.session.goBack();
        expect(fresh.session.view, BuyV2View.catalogue);
        expect(fresh.session.query, product.title);
        expect(fresh.session.selectedCategoryId, product.categoryId);
      },
    );

    test(
      'R669 persistence delayed restore retains Cart but preserves a newer query',
      () async {
        final store = _MemoryCustomerStateStore(
          scope().customerStateOwnerScope,
        );
        final cached = BuyV2CustomerStateSnapshot(
          cartQuantities: {product.id: 20},
          procurementDraft: BuyV2ProcurementDraftSnapshot(
            ownerScope: scope().customerStateOwnerScope,
            cartProducts: {
              product.id: product.copyWith(
                procurementSupplierGrant: supplier(),
              ),
            },
            navigation: const BuyV2ProcurementNavigationSnapshot(
              query: 'older query',
            ),
          ),
        );
        store.pendingRead = Completer<BuyV2CustomerStateSnapshot?>();
        final fresh = await scopedSession(retainedStore: store);
        final pending = fresh.session.restoreCustomerState();
        fresh.session.updateQuery('newer query');
        store.pendingRead!.complete(cached);
        await pending;
        expect(fresh.session.query, 'newer query');
        expect(fresh.session.quantityFor(product.id), 20);
        expect(
          store.snapshot,
          isNull,
          reason: 'A pending read must not be overwritten by navigation',
        );
      },
    );

    for (final accountSwitch in [false, true]) {
      for (final failedRead in [false, true]) {
        test(
          'R669 persistence rejects late read account $accountSwitch failure $failedRead',
          () async {
            final store = _MemoryCustomerStateStore(
              scope().customerStateOwnerScope,
            );
            store.pendingRead = Completer<BuyV2CustomerStateSnapshot?>();
            final fresh = await scopedSession(retainedStore: store);
            final pending = fresh.session.restoreCustomerState();
            fresh.identity.value = accountSwitch
                ? scope(account: 'different-account')
                : scope(store: 'different-store');
            final noticeAfterSwitch = fresh.session.notice;
            if (failedRead) {
              store.pendingRead!.completeError(
                StateError('old Store unavailable'),
              );
            } else {
              store.pendingRead!.complete(
                BuyV2CustomerStateSnapshot(cartQuantities: {product.id: 20}),
              );
            }
            await pending;
            expect(fresh.session.procurementScopeCurrent, isFalse);
            expect(fresh.session.quantityFor(product.id), 0);
            expect(fresh.session.notice, noticeAfterSwitch);
            expect(store.snapshot, isNull);
          },
        );
      }
    }

    for (final switchScope in [false, true]) {
      test(
        'R669 persistence serial writes retain latest intent scope switch $switchScope',
        () async {
          final preferences = _R669StringPreferences();
          final store = BuyV2SharedPreferencesCustomerStateStore(
            preferences,
            ownerScope: scope().customerStateOwnerScope,
          );
          final fixture = await scopedSession(retainedStore: store);
          await fixture.session.restoreCustomerState();
          final hold = Completer<void>();
          preferences.holdNextWrite = hold;
          fixture.session.updateQuery('first query');
          await Future<void>.delayed(Duration.zero);
          fixture.session.updateQuery('second query');
          expect(preferences.writesStarted, 1);
          if (switchScope) {
            fixture.identity.value = scope(store: 'different-store');
          }
          hold.complete();
          await Future<void>.delayed(Duration.zero);
          final persisted = await store.read();
          expect(
            persisted!.procurementDraft!.navigation!.query,
            switchScope ? 'first query' : 'second query',
          );
          expect(preferences.writesStarted, switchScope ? 1 : 2);
          if (switchScope) {
            expect(fixture.session.notice, contains('Return to your Store'));
          }
        },
      );
    }

    test(
      'R669 persistence normal consumer query does not create procurement state',
      () async {
        final preferences = _R669StringPreferences();
        final store = BuyV2SharedPreferencesCustomerStateStore(
          preferences,
          ownerScope: 'ordinary-consumer',
        );
        final core = BuySession();
        final session = BuyV2Session(core: core, customerStateStore: store);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await session.restoreCustomerState();
        expect(session.addProduct('s-tomato'), isTrue);
        final writes = preferences.writesStarted;
        session.updateQuery('consumer search');
        session.retainProcurementNavigation();
        await Future<void>.delayed(Duration.zero);
        expect(preferences.writesStarted, writes);
        expect((await store.read())!.procurementDraft, isNull);
        expect(session.quantityFor('s-tomato'), 1);
      },
    );

    for (final scale in [1.0, 2.0]) {
      for (final explicitLink in [false, true]) {
        testWidgets(
          'R669 persistence native relaunch Back link $explicitLink scale $scale',
          (tester) async {
            tester.view.physicalSize = const Size(320, 568);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final preferences = _R669StringPreferences();
            BuyV2SharedPreferencesCustomerStateStore reopen() =>
                BuyV2SharedPreferencesCustomerStateStore(
                  preferences,
                  ownerScope: scope().customerStateOwnerScope,
                );
            final first = await scopedSession(retainedStore: reopen());
            await first.session.restoreCustomerState();
            first.session.updateQuery(product.title);
            expect(first.session.addProduct(product.id), isTrue);
            expect(first.session.openProduct(product.id), isTrue);
            first.session.openCart(scope: BuyV2CartScope.wholesale);
            first.session.retainProcurementNavigation();
            await tester.pump();
            final target = product.copyWith(
              id: 'explicit-link-product',
              title: 'Explicit linked stock',
              procurementSupplierGrant: supplier(
                listing: 'explicit-link-product',
                offer: 'explicit-offer',
              ),
            );
            final fresh = await scopedSession(
              retainedStore: reopen(),
              snapshot: commerceSnapshot(
                products: [
                  product.copyWith(procurementSupplierGrant: supplier()),
                  target,
                ],
              ),
            );
            var exits = 0;
            await tester.pumpWidget(
              MaterialApp(
                theme: MoolTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: r66VisualCaptureRoot(
                  BuyV2Screen(
                    session: fresh.session,
                    initialDestination: BuyV2Destination.wholesale,
                    initialView: explicitLink
                        ? BuyV2View.product
                        : BuyV2View.catalogue,
                    productId: explicitLink ? target.id : null,
                    onExit: () {
                      exits++;
                    },
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(fresh.session.quantityFor(product.id), product.minimumOrder);
            if (explicitLink) {
              expect(fresh.session.view, BuyV2View.product);
              expect(fresh.session.selectedProductId, target.id);
              expect(fresh.session.query, isEmpty);
            } else {
              expect(fresh.session.view, BuyV2View.cart);
              expect(fresh.session.query, product.title);
              await tester.binding.handlePopRoute();
              await tester.pumpAndSettle();
              expect(fresh.session.selectedProductId, product.id);
              expect(fresh.session.view, BuyV2View.product);
            }
            await tester.pump(const Duration(seconds: 4));
            await tester.pumpAndSettle();
            await captureR66Visual(
              tester,
              'r669-procurement-relaunch-link-$explicitLink-scale-$scale',
            );
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(fresh.session.view, BuyV2View.catalogue);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(exits, 1);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    test('R669 persistence codec retains identity without approval', () async {
      final preferences = _R669StringPreferences();
      final store = BuyV2SharedPreferencesCustomerStateStore(
        preferences,
        ownerScope: scope().customerStateOwnerScope,
      );
      final original = product.copyWith(procurementSupplierGrant: supplier());
      expect(
        await store.write(
          BuyV2CustomerStateSnapshot(
            cartQuantities: {product.id: 20},
            procurementDraft: BuyV2ProcurementDraftSnapshot(
              ownerScope: scope().customerStateOwnerScope,
              cartProducts: {product.id: original},
            ),
          ),
        ),
        isTrue,
      );
      final serialized = preferences.values.values.single;
      expect(serialized, isNot(contains('"approved"')));
      final decoded = await BuyV2SharedPreferencesCustomerStateStore(
        preferences,
        ownerScope: scope().customerStateOwnerScope,
      ).read();
      final retained = decoded!.procurementDraft!.cartProducts[product.id]!;
      expect(retained.id, original.id);
      expect(retained.canonicalId, original.canonicalId);
      expect(retained.storeId, original.storeId);
      expect(retained.pack, original.pack);
      expect(retained.price, original.price);
      expect(retained.procurementSupplierGrant!.offerId, 'offer-1');
      expect(retained.procurementSupplierGrant!.offerRevision, 'revision-2');
      expect(retained.procurementSupplierGrant!.approved, isFalse);
      expect(retained.procurementSupplierGrant!.published, isFalse);
      expect(
        retained.procurementSupplierGrant!.role,
        BuyV2SupplierWorkspaceRole.unknown,
      );
    });

    for (final change in [
      'unchanged',
      'revision',
      'revoked',
      'missing',
      'price',
      'store',
    ]) {
      test(
        'R669 persistence relaunch validates $change against original offer',
        () async {
          final preferences = _R669StringPreferences();
          BuyV2SharedPreferencesCustomerStateStore reopenStore() =>
              BuyV2SharedPreferencesCustomerStateStore(
                preferences,
                ownerScope: scope().customerStateOwnerScope,
              );
          final first = await scopedSession(retainedStore: reopenStore());
          expect(first.session.addProduct(product.id), isTrue);
          await Future<void>.delayed(Duration.zero);
          final before = await reopenStore().read();
          final quantity = before!.cartQuantities[product.id]!;
          expect(
            before
                .procurementDraft!
                .cartProducts[product.id]!
                .procurementSupplierGrant!
                .offerRevision,
            'revision-2',
          );
          final current = product.copyWith(
            price: change == 'price' ? product.price + 1 : product.price,
            storeId: change == 'store' ? 'different-store' : product.storeId,
            procurementSupplierGrant: supplier(
              revision: change == 'revision' ? 'revision-3' : 'revision-2',
              approved: change != 'revoked',
              store: change == 'store' ? 'different-store' : 'supplier-branch',
            ),
          );
          final fresh = await scopedSession(
            retainedStore: reopenStore(),
            snapshot: commerceSnapshot(
              products: change == 'missing' ? [] : [current],
            ),
          );
          await fresh.session.restoreCustomerState();
          expect(fresh.session.quantityFor(product.id), quantity);
          final retained = fresh.session.cartLines.single.product;
          expect(retained.price, product.price);
          expect(retained.pack, product.pack);
          expect(retained.storeId, product.storeId);
          expect(
            retained.procurementSupplierGrant!.offerRevision,
            'revision-2',
          );
          fresh.session.openCart(scope: BuyV2CartScope.wholesale);
          if (change == 'unchanged') {
            expect(fresh.session.procurementCheckoutUnavailableMessage, isNull);
            expect(fresh.session.openCheckout(), isTrue);
          } else {
            expect(
              fresh.session.procurementCheckoutUnavailableMessage,
              isNotNull,
            );
            expect(fresh.session.openCheckout(), isFalse);
            expect(
              fresh.session.setCartQuantity(product.id, '${quantity + 1}'),
              isFalse,
            );
            expect(fresh.session.quantityFor(product.id), quantity);
          }
          fresh.session.remove(product.id);
          expect(fresh.session.quantityFor(product.id), 0);
        },
      );
    }

    test(
      'R669 persistence legacy cart keeps missing line without minting an offer',
      () async {
        final preferences = _R669StringPreferences();
        final ownerScope = scope().customerStateOwnerScope;
        preferences.values['moolsocial.buy.customer-state.$ownerScope.v1'] =
            jsonEncode({
              'cartQuantities': {product.id: 20, 'removed-legacy-sku': 7},
            });
        final store = BuyV2SharedPreferencesCustomerStateStore(
          preferences,
          ownerScope: ownerScope,
        );
        final fixture = await scopedSession(retainedStore: store);
        await fixture.session.restoreCustomerState();
        expect(fixture.session.quantityFor(product.id), 20);
        expect(fixture.session.quantityFor('removed-legacy-sku'), 7);
        expect(
          fixture.session.cartLines.every(
            (line) => line.product.procurementSupplierGrant!.offerId.isEmpty,
          ),
          isTrue,
        );
        fixture.session.openCart(scope: BuyV2CartScope.wholesale);
        expect(
          fixture.session.procurementCheckoutUnavailableMessage,
          isNotNull,
        );
        expect(fixture.session.setCartQuantity(product.id, '21'), isFalse);
        fixture.session.remove('removed-legacy-sku');
        expect(fixture.session.quantityFor(product.id), 20);
      },
    );

    for (final scale in [1.0, 2.0]) {
      testWidgets('R669 persistence legacy unavailable price scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final preferences = _R669StringPreferences();
        final ownerScope = scope().customerStateOwnerScope;
        preferences.values['moolsocial.buy.customer-state.$ownerScope.v1'] =
            jsonEncode({
              'cartQuantities': {'removed-legacy-sku': 7},
            });
        final fixture = await scopedSession(
          retainedStore: BuyV2SharedPreferencesCustomerStateStore(
            preferences,
            ownerScope: ownerScope,
          ),
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
            home: r66VisualCaptureRoot(
              BuyV2Screen(
                session: fixture.session,
                initialDestination: BuyV2Destination.wholesale,
                initialView: BuyV2View.cart,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(fixture.session.quantityFor('removed-legacy-sku'), 7);
        expect(fixture.session.scopedProcurementPricesUnavailable, isTrue);
        expect(
          fixture.session.procurementCheckoutUnavailableMessage,
          isNotNull,
        );
        expect(find.textContaining('Price pending'), findsWidgets);
        expect(find.textContaining('₹0'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        await captureR66Visual(
          tester,
          'r669-procurement-legacy-price-scale-$scale',
        );
      });
    }

    test(
      'R669 persistence rejects cross-operation cache reads and writes',
      () async {
        final preferences = _R669StringPreferences();
        final currentScope = scope().customerStateOwnerScope;
        final store = BuyV2SharedPreferencesCustomerStateStore(
          preferences,
          ownerScope: currentScope,
        );
        final other = BuyV2CustomerStateSnapshot(
          cartQuantities: {product.id: 20},
          procurementDraft: BuyV2ProcurementDraftSnapshot(
            ownerScope: scope(
              origin: 'another-operation',
            ).customerStateOwnerScope,
          ),
        );
        expect(await store.write(other), isFalse);
        expect(preferences.values, isEmpty);
        preferences.values['moolsocial.buy.customer-state.$currentScope.v1'] =
            jsonEncode({
              'cartQuantities': {product.id: 20},
              'procurementDraft': {
                'version': 1,
                'ownerScope': 'another-scope',
                'cartProducts': {},
              },
            });
        expect(await store.read(), isNull);
        expect(preferences.values, hasLength(1));
      },
    );

    test(
      'R669 persistence commerce refresh cannot retain removed paged authority',
      () async {
        final fixture = await scopedSession();
        expect(fixture.session.addProduct(product.id), isTrue);
        final quantity = fixture.session.quantityFor(product.id);
        fixture.adapter.snapshot = commerceSnapshot(products: []);
        await fixture.session.restoreCommerce();
        fixture.session.openCart(scope: BuyV2CartScope.wholesale);
        expect(
          fixture.session.procurementCheckoutUnavailableMessage,
          isNotNull,
        );
        expect(fixture.session.openCheckout(), isFalse);
        expect(fixture.session.addProduct(product.id), isFalse);
        expect(fixture.session.quantityFor(product.id), quantity);
      },
    );

    test(
      'session keeps eligibility after search filters Saved and direct entry',
      () async {
        final rejected = product.copyWith(
          id: 'retailer-listing',
          procurementSupplierGrant: supplier(
            role: BuyV2SupplierWorkspaceRole.retailer,
            listing: 'retailer-listing',
          ),
        );
        final fixture = await scopedSession(
          snapshot: commerceSnapshot(
            products: [
              product.copyWith(procurementSupplierGrant: supplier()),
              rejected,
            ],
          ),
        );
        final session = fixture.session;
        expect(session.procurementUnavailableMessage, isNull);
        session.toggleSaved(rejected.id);
        session.query = 'unmatched query';
        session.applyDiscoveryRefinements(
          session.discoveryRefinements.copyWith(brands: {'unmatched brand'}),
        );
        session.clearDiscoveryRefinements();
        session.query = '';
        for (final mode in BuyV2WholesaleSaleType.values) {
          session.chooseWholesaleSaleType(mode);
          expect(
            session.visibleProducts.map((item) => item.id),
            isNot(contains(rejected.id)),
          );
          expect(session.visibleSavedProducts, isEmpty);
        }
        expect(session.openProduct(rejected.id), isFalse);
        expect(session.addProduct(rejected.id), isFalse);
        expect(session.openProduct(product.id), isTrue);
        expect(session.addProduct(product.id), isTrue);
        expect(session.quantityFor(product.id), product.minimumOrder);
        expect(
          session.catalogueQuery().procurementContext,
          same(session.procurementContext),
        );
        expect(
          session.catalogueQuery(storeId: 'supplier-branch').procurementContext,
          same(session.procurementContext),
        );
        expect(
          session.catalogueOffersQuery().procurementContext,
          same(session.procurementContext),
        );
      },
    );

    test(
      'session Buy Direct rejects wholesaler and admits manufacturer',
      () async {
        final fixture = await scopedSession(
          context: scope(purpose: BuyV2ProcurementPurpose.buyDirect),
        );
        expect(fixture.session.addProduct(product.id), isFalse);
        fixture.adapter.snapshot = commerceSnapshot(
          products: [
            product.copyWith(
              procurementSupplierGrant: supplier(
                role: BuyV2SupplierWorkspaceRole.manufacturer,
              ),
            ),
          ],
        );
        await fixture.session.restoreCommerce();
        expect(fixture.session.addProduct(product.id), isTrue);
      },
    );

    test(
      'session revocation retains Cart and historical order but blocks purchase',
      () async {
        const historical = BuyV2Order(
          id: 'accepted-historical-order',
          destination: BuyV2Destination.wholesale,
          title: 'Stock purchase',
          itemSummary: 'Accepted stock',
          total: 4200,
          partner: 'Supplier',
          partnerType: 'Wholesaler',
          promise: 'Recorded delivery',
          destinationLabel: 'Store receiving',
          progress: 1,
          status: BuyV2OrderStatus.delivered,
        );
        final fixture = await scopedSession(
          snapshot: commerceSnapshot(orders: [historical]),
        );
        final session = fixture.session;
        expect(session.addProduct(product.id), isTrue);
        final quantity = session.quantityFor(product.id);
        fixture.adapter.snapshot = commerceSnapshot(
          products: [
            product.copyWith(
              procurementSupplierGrant: supplier(approved: false),
            ),
          ],
        );
        await session.restoreCommerce();
        expect(session.addProduct(product.id), isFalse);
        session.increase(product.id);
        expect(session.setCartQuantity(product.id, '${quantity + 1}'), isFalse);
        session.openCart(scope: BuyV2CartScope.wholesale);
        expect(session.openCheckout(), isFalse);
        expect(session.confirmOrder(), isFalse);
        expect(session.quantityFor(product.id), quantity);
        expect(
          session.orders.map((order) => order.id),
          contains(historical.id),
        );
        session.remove(product.id);
        expect(session.quantityFor(product.id), 0);
      },
    );

    test(
      'session changed offer cannot replace a retained cart revision',
      () async {
        final fixture = await scopedSession();
        final session = fixture.session;
        expect(session.addProduct(product.id), isTrue);
        fixture.adapter.snapshot = commerceSnapshot(
          products: [
            product.copyWith(
              procurementSupplierGrant: supplier(revision: 'revision-3'),
            ),
          ],
        );
        await session.restoreCommerce();
        expect(session.openProduct(product.id), isTrue);
        expect(session.addProduct(product.id), isFalse);
        expect(session.notice, contains('Remove this item from Cart'));
        session.remove(product.id);
        expect(session.addProduct(product.id), isTrue);
        expect(
          session
              .cartLines
              .single
              .product
              .procurementSupplierGrant!
              .offerRevision,
          'revision-3',
        );
      },
    );

    test(
      'session restores ineligible items without converting or deleting them',
      () async {
        final store = _MemoryCustomerStateStore(scope().customerStateOwnerScope)
          ..snapshot = BuyV2CustomerStateSnapshot(
            cartQuantities: {product.id: 20},
          );
        final fixture = await scopedSession(
          retainedStore: store,
          snapshot: commerceSnapshot(
            products: [
              product.copyWith(
                procurementSupplierGrant: supplier(approved: false),
              ),
            ],
          ),
        );
        await fixture.session.restoreCustomerState();
        expect(fixture.session.quantityFor(product.id), 20);
        fixture.session.openCart(scope: BuyV2CartScope.wholesale);
        expect(fixture.session.openCheckout(), isFalse);
        expect(store.snapshot!.cartQuantities[product.id], 20);
      },
    );

    test(
      'session cannot read or overwrite the ordinary consumer cart scope',
      () async {
        final consumer = _MemoryCustomerStateStore('consumer-account-state')
          ..snapshot = BuyV2CustomerStateSnapshot(
            cartQuantities: {product.id: 31},
          );
        final before = consumer.snapshot;
        final fixture = await scopedSession(retainedStore: consumer);
        await fixture.session.restoreCustomerState();
        expect(fixture.session.procurementScopeCurrent, isFalse);
        expect(fixture.session.addProduct(product.id), isFalse);
        expect(fixture.session.cartLines, isEmpty);
        expect(consumer.snapshot, same(before));
      },
    );

    test(
      'session rejects an old refresh after account and Store change',
      () async {
        final fixture = await scopedSession();
        final session = fixture.session;
        expect(session.addProduct(product.id), isTrue);
        final quantity = session.quantityFor(product.id);
        final delayed = Completer<BuyV2CommerceSnapshot>();
        fixture.adapter.refreshGate = delayed;
        final pending = session.restoreCommerce();
        fixture.identity.value = scope(
          account: 'other-account',
          store: 'other-store',
        );
        delayed.complete(commerceSnapshot());
        await pending;
        expect(session.procurementScopeCurrent, isFalse);
        expect(session.visibleProducts, isEmpty);
        expect(session.addProduct(product.id), isFalse);
        expect(session.quantityFor(product.id), quantity);
        fixture.identity.value = scope();
        expect(session.addProduct(product.id), isFalse);
        await session.restoreCommerce();
        expect(session.addProduct(product.id), isTrue);
      },
    );

    test('session missing buyer grant stays explicitly unavailable', () async {
      final fixture = await scopedSession(
        snapshot: commerceSnapshot(omitGrant: true),
      );
      expect(
        fixture.session.commerceLoadState,
        BuyV2CommerceLoadState.unavailable,
      );
      expect(
        fixture.session.procurementUnavailableMessage,
        contains('approval'),
      );
      expect(fixture.session.addProduct(product.id), isFalse);
    });

    test(
      'session variants and continuation shelves enforce supplier admission',
      () async {
        final eligible = product.copyWith(
          brand: 'Declared supplier brand',
          procurementSupplierGrant: supplier(),
        );
        final rejected = eligible.copyWith(
          id: 'retailer-variant',
          procurementSupplierGrant: supplier(
            listing: 'retailer-variant',
            role: BuyV2SupplierWorkspaceRole.retailer,
          ),
        );
        final fixture = await scopedSession(
          snapshot: commerceSnapshot(products: [eligible, rejected]),
        );
        final session = fixture.session;
        expect(session.openProduct(eligible.id), isTrue);
        expect(session.productVariantsFor(eligible).map((p) => p.id), [
          eligible.id,
        ]);
        expect(session.selectProductVariant(rejected.id), isFalse);
        expect(session.selectedProductId, eligible.id);
        for (final shelf in [
          session.productContinuationsFor(eligible),
          session.supplierContinuationsFor(eligible),
          session.partnerCatalogueFor(eligible),
          session.brandCatalogueFor(eligible),
        ]) {
          expect(shelf.map((p) => p.id), isNot(contains(rejected.id)));
        }
        fixture.adapter.snapshot = commerceSnapshot(
          products: [
            eligible.copyWith(
              procurementSupplierGrant: supplier(approved: false),
            ),
            rejected,
          ],
        );
        await session.restoreCommerce();
        expect(
          session.recentlyViewedProductsFor(BuyV2Destination.wholesale),
          isEmpty,
        );
        expect(session.productVariantsFor(eligible), isEmpty);
        expect(
          session.procurementDiscoveryUnavailableMessage,
          contains('No eligible'),
        );
      },
    );

    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'recovery hides changed Store session and returns to origin $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 568);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final fixture = await scopedSession();
          final session = fixture.session;
          expect(session.addProduct(product.id), isTrue);
          final quantity = session.quantityFor(product.id);
          var exits = 0;
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: MoolTheme.light(),
              builder: (context, child) => r66VisualCaptureRoot(child!),
              home: BuyV2Screen(
                session: session,
                initialDestination: BuyV2Destination.wholesale,
                onExit: () => exits++,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('buy-change-location')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-address-sheet-route')),
            findsOneWidget,
          );
          fixture.identity.value = scope(
            account: 'other-account',
            store: 'other-store',
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-procurement-scope-recovery')),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('buy-v2-screen')), findsNothing);
          expect(
            find.byKey(const ValueKey('buy-address-sheet-route')),
            findsNothing,
          );
          expect(find.text(product.title), findsNothing);
          expect(
            find.byKey(const ValueKey('buy-catalogue-retry')),
            findsNothing,
          );
          expect(session.quantityFor(product.id), quantity);
          expect(tester.takeException(), isNull);
          await captureR66Visual(
            tester,
            'r669-procurement-scope-recovery-$scale',
          );
          final back = find.byKey(const ValueKey('buy-procurement-return'));
          await tester.ensureVisible(back);
          await tester.tap(back);
          await tester.pumpAndSettle();
          expect(exits, 1);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(exits, 2);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      testWidgets(
        'recovery explains revoked product and preserves Cart $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 568);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final fixture = await scopedSession();
          final session = fixture.session;
          expect(session.addProduct(product.id), isTrue);
          final quantity = session.quantityFor(product.id);
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: MoolTheme.light(),
              builder: (context, child) => r66VisualCaptureRoot(child!),
              home: BuyV2Screen(
                session: session,
                initialDestination: BuyV2Destination.wholesale,
                onExit: () {},
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(session.openProduct(product.id), isTrue);
          await tester.pumpAndSettle();
          fixture.adapter.snapshot = commerceSnapshot(
            products: [
              product.copyWith(
                procurementSupplierGrant: supplier(approved: false),
              ),
            ],
          );
          await session.restoreCommerce();
          await tester.pumpAndSettle();
          expect(find.text('Store purchase unavailable'), findsOneWidget);
          expect(find.textContaining('could not be confirmed'), findsWidgets);
          expect(session.quantityFor(product.id), quantity);
          expect(tester.takeException(), isNull);
          await captureR66Visual(
            tester,
            'r669-procurement-product-recovery-$scale',
          );
          final back = find.byKey(const ValueKey('buy-procurement-return'));
          await tester.ensureVisible(back);
          await tester.tap(back);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          session.openCart(scope: BuyV2CartScope.wholesale);
          expect(session.openCheckout(), isFalse);
          expect(session.quantityFor(product.id), quantity);
          fixture.adapter.snapshot = commerceSnapshot();
          await session.restoreCommerce();
          expect(session.openCheckout(), isTrue);
          await tester.pumpAndSettle();
          fixture.adapter.snapshot = commerceSnapshot(
            products: [
              product.copyWith(
                procurementSupplierGrant: supplier(approved: false),
              ),
            ],
          );
          await session.restoreCommerce();
          await tester.pumpAndSettle();
          expect(find.text('Store purchase unavailable'), findsOneWidget);
          expect(find.text('Back to Cart'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await captureR66Visual(
            tester,
            'r669-procurement-checkout-recovery-$scale',
          );
          await tester.ensureVisible(back);
          await tester.tap(back);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          expect(session.quantityFor(product.id), quantity);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    void prepareProcurementPayment(BuyV2Session session) {
      expect(session.addProduct(product.id), isTrue);
      session.openCart(scope: BuyV2CartScope.wholesale);
      expect(session.openCheckout(), isTrue);
      expect(session.choosePayment('PhonePe'), isTrue);
    }

    test(
      'payment placement carries exact scope and rejects late account result',
      () async {
        final fixture = await scopedSession();
        final session = fixture.session;
        prepareProcurementPayment(session);
        final quantity = session.quantityFor(product.id);
        final gate = Completer<BuyV2OrderPlacementResult>();
        fixture.adapter.placementGate = gate;
        final pending = session.submitOrder();
        expect(fixture.adapter.placements, hasLength(1));
        expect(
          fixture.adapter.placements.single.procurementContext,
          same(session.procurementContext),
        );
        fixture.identity.value = scope(account: 'another-account');
        gate.complete(fixture.adapter.placement);
        expect(await pending, isFalse);
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentUnknown,
        );
        expect(session.quantityFor(product.id), quantity);
        expect(await session.reconcilePayment(), isFalse);
        expect(fixture.adapter.reconciliations, 0);
      },
    );

    test(
      'payment reconciliation rejects late Store result and retains pending cart',
      () async {
        final fixture = await scopedSession();
        final session = fixture.session;
        prepareProcurementPayment(session);
        expect(await session.submitOrder(), isFalse);
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentPending,
        );
        final quantity = session.quantityFor(product.id);
        final gate = Completer<BuyV2OrderPlacementResult>();
        fixture.adapter.reconciliationGate = gate;
        final pending = session.reconcilePayment();
        expect(fixture.adapter.reconciliations, 1);
        fixture.identity.value = scope(store: 'another-store');
        gate.complete(fixture.adapter.placement);
        expect(await pending, isFalse);
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentUnknown,
        );
        expect(session.quantityFor(product.id), quantity);
        expect(session.orders, isEmpty);
      },
    );

    test(
      'original purchaser can check an existing payment after supplier revocation',
      () async {
        final fixture = await scopedSession();
        final session = fixture.session;
        prepareProcurementPayment(session);
        expect(await session.submitOrder(), isFalse);
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentPending,
        );
        fixture.adapter.snapshot = commerceSnapshot(
          products: [
            product.copyWith(
              procurementSupplierGrant: supplier(approved: false),
            ),
          ],
        );
        await session.restoreCommerce();
        expect(session.procurementCheckoutUnavailableMessage, isNull);
        expect(await session.reconcilePayment(), isFalse);
        expect(fixture.adapter.reconciliations, 1);
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentPending,
        );
        expect(await session.submitOrder(), isFalse);
        expect(fixture.adapter.placements, hasLength(1));
      },
    );

    test(
      'payment handoff cannot resume after originating operation changes',
      () async {
        final fixture = await scopedSession();
        final session = fixture.session;
        prepareProcurementPayment(session);
        fixture.adapter.placement = BuyV2OrderPlacementResult(
          outcome: BuyV2OrderPlacementOutcome.paymentActionRequired,
          customerMessage: 'Continue to the payment app.',
          paymentReference: 'procurement-payment',
          paymentActionUri: Uri.parse('upi://pay?pa=test%40example'),
        );
        expect(await session.submitOrder(), isFalse);
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentActionRequired,
        );
        final gate = Completer<bool>();
        final pending = session.continuePayment((_) => gate.future);
        fixture.identity.value = scope(origin: 'another-operation');
        gate.complete(true);
        expect(await pending, isFalse);
        expect(
          session.checkoutSubmissionState,
          BuyV2CheckoutSubmissionState.paymentUnknown,
        );
        expect(session.cancelPaymentAttempt(), isFalse);
        expect(session.quantityFor(product.id), product.minimumOrder);
      },
    );

    test(
      'restored procurement quantity survives an increased MOQ and can be corrected',
      () async {
        final store = _MemoryCustomerStateStore(scope().customerStateOwnerScope)
          ..snapshot = BuyV2CustomerStateSnapshot(
            cartQuantities: {product.id: 20},
            procurementDraft: BuyV2ProcurementDraftSnapshot(
              ownerScope: scope().customerStateOwnerScope,
              cartProducts: {
                product.id: product.copyWith(
                  procurementSupplierGrant: supplier(),
                ),
              },
            ),
          );
        final fixture = await scopedSession(
          retainedStore: store,
          snapshot: commerceSnapshot(
            products: [
              product.copyWith(
                minimumOrder: 25,
                procurementSupplierGrant: supplier(),
              ),
            ],
          ),
        );
        final session = fixture.session;
        await session.restoreCustomerState();
        expect(session.quantityFor(product.id), 20);
        expect(store.snapshot!.cartQuantities[product.id], 20);
        session.openCart(scope: BuyV2CartScope.wholesale);
        expect(session.openCheckout(), isFalse);
        expect(session.notice, contains('25 packs'));
        expect(session.setCartQuantity(product.id, '24'), isFalse);
        expect(session.setCartQuantity(product.id, '25'), isTrue);
        expect(session.quantityFor(product.id), 25);
        expect(session.openCheckout(), isTrue);
      },
    );

    test(
      'existing procurement cart uses current MOQ during quantity and checkout checks',
      () async {
        final fixture = await scopedSession();
        final session = fixture.session;
        expect(session.addProduct(product.id), isTrue);
        final retained = session.quantityFor(product.id);
        fixture.adapter.snapshot = commerceSnapshot(
          products: [
            product.copyWith(
              minimumOrder: 25,
              procurementSupplierGrant: supplier(),
            ),
          ],
        );
        await session.restoreCommerce();
        expect(session.quantityFor(product.id), retained);
        expect(session.setCartQuantity(product.id, '24'), isFalse);
        session.openCart(scope: BuyV2CartScope.wholesale);
        expect(session.openCheckout(), isFalse);
        expect(session.notice, contains('25 packs'));
        expect(session.setCartQuantity(product.id, '25'), isTrue);
        expect(session.openCheckout(), isTrue);
      },
    );

    test(
      'paged catalogue admits approved supplier and retains typed purchase context',
      () async {
        final source = _R669ProcurementCatalogue([
          product.copyWith(procurementSupplierGrant: supplier()),
        ]);
        final fixture = await scopedSession(
          catalogueSource: source,
          snapshot: commerceSnapshot(products: const []),
        );
        final session = fixture.session;
        final pager = session.acquireCatalogueProducts('procurement-page');
        await pager.open(session.catalogueQuery());
        expect(
          source.lastQuery!.procurementContext,
          same(session.procurementContext),
        );
        expect(pager.message, isNull);
        expect(pager.page!.items.single.id, product.id);
        expect(session.openProduct(product.id), isTrue);
        expect(session.addProduct(product.id), isTrue);
        session.releaseCatalogueProducts('procurement-page');
      },
    );

    for (final rejected in [
      'retailer',
      'consumer-only',
      'unknown',
      'expired',
    ]) {
      test(
        'paged catalogue rejects $rejected product admission and direct entry',
        () async {
          final grant = switch (rejected) {
            'retailer' => supplier(role: BuyV2SupplierWorkspaceRole.retailer),
            'consumer-only' => supplier(
              channel: BuyV2SupplierListingChannel.consumer,
            ),
            'expired' => supplier(until: now),
            _ => null,
          };
          final source = _R669ProcurementCatalogue([
            product.copyWith(procurementSupplierGrant: grant),
          ]);
          final fixture = await scopedSession(
            catalogueSource: source,
            snapshot: commerceSnapshot(products: const []),
          );
          final session = fixture.session;
          final pager = session.acquireCatalogueProducts('procurement-reject');
          await pager.open(session.catalogueQuery());
          expect(pager.page, isNull);
          expect(pager.message, isNotNull);
          expect(session.findProduct(product.id), isNull);
          expect(session.openProduct(product.id), isFalse);
          expect(session.addProduct(product.id), isFalse);
          session.releaseCatalogueProducts('procurement-reject');
        },
      );
    }

    test('paged catalogue rejects omitted procurement query context', () async {
      final source = _R669ProcurementCatalogue([
        product.copyWith(procurementSupplierGrant: supplier()),
      ]);
      final fixture = await scopedSession(
        catalogueSource: source,
        snapshot: commerceSnapshot(products: const []),
      );
      final session = fixture.session;
      final pager = session.acquireCatalogueProducts('procurement-no-context');
      await pager.open(
        BuyV2CatalogueQuery(
          destination: BuyV2Destination.wholesale,
          regionId: null,
          areaScope: BuyV2CatalogueAreaScope.allAreas,
        ),
      );
      expect(pager.page, isNull);
      expect(pager.message, isNotNull);
      expect(session.findProduct(product.id), isNull);
      session.releaseCatalogueProducts('procurement-no-context');
    });

    test(
      'paged catalogue rejects old operation results after scope switch',
      () async {
        final source = _R669ProcurementCatalogue([
          product.copyWith(procurementSupplierGrant: supplier()),
        ])..gate = Completer<void>();
        final fixture = await scopedSession(
          catalogueSource: source,
          snapshot: commerceSnapshot(products: const []),
        );
        final session = fixture.session;
        final pager = session.acquireCatalogueProducts('procurement-delayed');
        final pending = pager.open(session.catalogueQuery());
        fixture.identity.value = scope(origin: 'different-origin');
        source.gate!.complete();
        await pending;
        expect(pager.page, isNull);
        expect(pager.message, isNotNull);
        expect(session.findProduct(product.id), isNull);
        session.releaseCatalogueProducts('procurement-delayed');
      },
    );

    test(
      'paged restored cart retains an ineligible SKU without allowing purchase',
      () async {
        final source = _R669ProcurementCatalogue([
          product.copyWith(procurementSupplierGrant: supplier(approved: false)),
        ]);
        final store = _MemoryCustomerStateStore(scope().customerStateOwnerScope)
          ..snapshot = BuyV2CustomerStateSnapshot(
            cartQuantities: {product.id: 20},
          );
        final fixture = await scopedSession(
          catalogueSource: source,
          retainedStore: store,
          snapshot: commerceSnapshot(products: const []),
        );
        await fixture.session.restoreCustomerState();
        expect(fixture.session.quantityFor(product.id), 20);
        expect(fixture.session.openProduct(product.id), isFalse);
        fixture.session.openCart(scope: BuyV2CartScope.wholesale);
        expect(fixture.session.openCheckout(), isFalse);
        expect(store.snapshot!.cartQuantities[product.id], 20);
      },
    );

    const allowedRoles = {
      BuyV2ProcurementPurpose.restock: {
        BuyV2SupplierWorkspaceRole.wholesaler,
        BuyV2SupplierWorkspaceRole.mandi,
        BuyV2SupplierWorkspaceRole.manufacturer,
      },
      BuyV2ProcurementPurpose.groupBulkBuying: {
        BuyV2SupplierWorkspaceRole.wholesaler,
        BuyV2SupplierWorkspaceRole.mandi,
        BuyV2SupplierWorkspaceRole.manufacturer,
      },
      BuyV2ProcurementPurpose.buyDirect: {
        BuyV2SupplierWorkspaceRole.manufacturer,
      },
    };
    for (final purpose in BuyV2ProcurementPurpose.values) {
      for (final role in BuyV2SupplierWorkspaceRole.values) {
        for (final channel in [
          BuyV2SupplierListingChannel.wholesale,
          BuyV2SupplierListingChannel.bulk,
        ]) {
          test('${purpose.name} ${role.name} ${channel.name}', () {
            expect(
              evaluate(
                context: scope(purpose: purpose),
                supplierGrant: supplier(role: role, channel: channel),
              ),
              allowedRoles[purpose]!.contains(role)
                  ? BuyV2ProcurementEligibility.eligible
                  : BuyV2ProcurementEligibility.roleNotPermitted,
            );
          });
        }
      }
    }

    test('paged response identity separates purchasing contexts', () {
      BuyV2CatalogueQuery query(BuyV2ProcurementContext? context) =>
          BuyV2CatalogueQuery(
            destination: BuyV2Destination.wholesale,
            regionId: 'receiving-region',
            procurementContext: context,
          );
      final ordinary = query(null);
      final legacyKey = jsonDecode(ordinary.key) as List<dynamic>;
      expect(legacyKey.first, 2);
      expect(legacyKey, hasLength(19));
      expect(query(scope()), query(scope()));
      expect({
        ordinary.key,
        query(scope()).key,
        query(scope(account: 'different-account')).key,
        query(scope(store: 'different-store')).key,
        query(scope(origin: 'different-operation')).key,
        query(scope(purpose: BuyV2ProcurementPurpose.buyDirect)).key,
      }, hasLength(6));
    });

    test('product copies retain authority without deriving it from labels', () {
      expect(product.procurementSupplierGrant, isNull);
      final grant = supplier(role: BuyV2SupplierWorkspaceRole.retailer);
      final supplied = product.copyWith(procurementSupplierGrant: grant);
      final relabelled = supplied.copyWith(
        seller: 'Approved Wholesale Manufacturer',
        sellerType: 'Manufacturer',
        price: supplied.price + 10,
      );
      expect(relabelled.procurementSupplierGrant, same(grant));
      expect(
        evaluate(supplierGrant: relabelled.procurementSupplierGrant),
        BuyV2ProcurementEligibility.roleNotPermitted,
      );
      expect(
        supplied
            .copyWith(procurementSupplierGrant: supplier(approved: false))
            .procurementSupplierGrant!
            .approved,
        isFalse,
      );
    });

    test('ordinary Shop does not acquire Store restrictions', () {
      expect(
        buyV2ProcurementEligibility(
          context: null,
          activeAccountId: null,
          activeStoreId: null,
          buyer: null,
          supplier: null,
          product: product,
          now: now,
        ),
        BuyV2ProcurementEligibility.notRequested,
      );
    });

    test('unknown authority never grants purchase eligibility', () {
      for (final missingBuyer in [true, false]) {
        expect(
          buyV2ProcurementEligibility(
            context: scope(),
            activeAccountId: 'buyer-account',
            activeStoreId: 'purchasing-store',
            buyer: missingBuyer ? null : buyer(),
            supplier: missingBuyer ? supplier() : null,
            product: product,
            now: now,
          ),
          missingBuyer
              ? BuyV2ProcurementEligibility.buyerUnavailable
              : BuyV2ProcurementEligibility.supplierUnavailable,
        );
      }
    });

    test('account Store and malformed origin reject late contexts', () {
      expect(
        evaluate(account: 'another-account'),
        BuyV2ProcurementEligibility.contextUnavailable,
      );
      expect(
        evaluate(store: 'another-store'),
        BuyV2ProcurementEligibility.contextUnavailable,
      );
      expect(
        evaluate(context: scope(origin: ' ')),
        BuyV2ProcurementEligibility.contextUnavailable,
      );
      expect(
        evaluate(context: scope(account: ' buyer-account')),
        BuyV2ProcurementEligibility.contextUnavailable,
      );
    });

    test('buyer approval is exact and expires at its deadline', () {
      for (final grant in [
        buyer(approved: false),
        buyer(account: 'other-account'),
        buyer(store: 'other-store'),
        buyer(until: now),
        buyer(until: now.subtract(const Duration(seconds: 1))),
      ]) {
        expect(
          evaluate(buyerGrant: grant),
          BuyV2ProcurementEligibility.buyerUnavailable,
        );
      }
    });

    test('revoked expired or incomplete supplier grant is unavailable', () {
      for (final grant in [
        supplier(approved: false),
        supplier(until: now),
        supplier(workspace: ''),
        supplier(offer: ''),
        supplier(revision: ' '),
      ]) {
        expect(
          evaluate(supplierGrant: grant),
          BuyV2ProcurementEligibility.supplierUnavailable,
        );
      }
    });

    test(
      'approved manufacturer cannot expose consumer or unpublished stock',
      () {
        for (final grant in [
          supplier(
            role: BuyV2SupplierWorkspaceRole.manufacturer,
            channel: BuyV2SupplierListingChannel.consumer,
          ),
          supplier(channel: BuyV2SupplierListingChannel.unknown),
          supplier(published: false),
        ]) {
          expect(
            evaluate(supplierGrant: grant),
            BuyV2ProcurementEligibility.listingNotPermitted,
          );
        }
      },
    );

    test(
      'different seller product or restored offer cannot substitute silently',
      () {
        for (final grant in [
          supplier(store: 'other-supplier-branch'),
          supplier(listing: 'different-listing'),
          supplier(canonical: 'different-product'),
        ]) {
          expect(
            evaluate(supplierGrant: grant),
            BuyV2ProcurementEligibility.offerChanged,
          );
        }
        expect(
          evaluate(expectedOfferId: 'previous-offer'),
          BuyV2ProcurementEligibility.offerChanged,
        );
        expect(
          evaluate(expectedOfferRevision: 'revision-1'),
          BuyV2ProcurementEligibility.offerChanged,
        );
        expect(
          evaluate(
            expectedOfferId: 'offer-1',
            expectedOfferRevision: 'revision-2',
          ),
          BuyV2ProcurementEligibility.eligible,
        );
      },
    );

    test(
      'purchase state scopes stay distinct without losing return identity',
      () {
        final original = scope();
        expect(
          original.customerStateOwnerScope,
          scope().customerStateOwnerScope,
        );
        expect(original.originOperationId, 'restock-operation');
        expect({
          original.customerStateOwnerScope,
          scope(account: 'another-account').customerStateOwnerScope,
          scope(store: 'another-store').customerStateOwnerScope,
          scope(origin: 'another-operation').customerStateOwnerScope,
          scope(
            purpose: BuyV2ProcurementPurpose.buyDirect,
          ).customerStateOwnerScope,
        }, hasLength(5));
        expect(
          scope(account: 'a:b', store: 'c').customerStateOwnerScope,
          isNot(scope(account: 'a', store: 'b:c').customerStateOwnerScope),
        );
      },
    );
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('R669 tracking freshness fails closed and recovers $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 711);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final session = await _openOrderSearchFixture();
      final adapter = session.commerceAdapter as _ShopCommerceAdapter;
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          builder: (context, child) => r66VisualCaptureRoot(child!),
          home: BuyV2Screen(
            session: session,
            initialDestination: BuyV2Destination.orders,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(session.openTracking('MS-SEARCH-TOMATO'), isTrue);
      await tester.pumpAndSettle();
      final original = session.selectedOrder;
      final refresh = find.byKey(
        const ValueKey('buy-tracking-refresh-MS-SEARCH-TOMATO'),
      );
      final estimate = find.byKey(
        const ValueKey('buy-tracking-estimate-MS-SEARCH-TOMATO'),
      );
      void expectRetained({bool updateUnavailable = false}) {
        expect(find.text('LAST KNOWN'), findsOneWidget);
        expect(find.text('CURRENT'), findsNothing);
        expect(find.text('NOW'), findsNothing);
        expect(
          tester.widget<Text>(estimate).data,
          startsWith(updateUnavailable
              ? 'Last recorded estimate (update unavailable) · '
              : 'Last recorded estimate · '),
        );
        expect(session.selectedOrder, same(original));
      }

      expectRetained();
      adapter.orderRefreshGate = Completer<BuyV2OrderRefreshResult>();
      expect(refresh.hitTestable(), findsOneWidget);
      await tester.tap(refresh);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('REFRESHING'), findsOneWidget);
      expect(tester.widget<IconButton>(refresh).onPressed, isNull);
      adapter.orderRefreshGate!.complete(
        const BuyV2OrderRefreshResult(
          state: BuyV2CommerceLoadState.unavailable,
          customerMessage: 'Order updates are unavailable right now.',
        ),
      );
      await tester.pumpAndSettle();
      expectRetained(updateUnavailable: true);
      await captureR66Visual(tester, 'r669-order-status-failed-$scale');
      adapter.orderRefreshGate = null;
      adapter.orderRefreshResult = const BuyV2OrderRefreshResult(
        state: BuyV2CommerceLoadState.ready,
        customerMessage: 'Updated',
      );
      await tester.tap(refresh);
      await tester.pumpAndSettle();
      expect(
        session.orderRefreshState(original.id),
        BuyV2CommerceLoadState.unavailable,
      );
      expectRetained(updateUnavailable: true);
      expect(
        find.text(
          'Order update could not be verified. Last known details are still shown.',
        ),
        findsOneWidget,
      );
      adapter.orderRefreshResult = BuyV2OrderRefreshResult(
        state: BuyV2CommerceLoadState.ready,
        order: original,
        customerMessage: 'Order refreshed.',
      );
      await tester.tap(refresh);
      await tester.pumpAndSettle();
      expect(find.text('UPDATED'), findsOneWidget);
      expect(tester.widget<Text>(estimate).data, 'Updated estimate · Delivery in 12 min');
      expect(
        find.byKey(const ValueKey('buy-tracking-refresh-unavailable')),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('UPDATED').hitTestable(), findsOneWidget);
      await captureR66Visual(tester, 'r669-order-status-updated-$scale');
      adapter.orderRefreshGate = Completer<BuyV2OrderRefreshResult>();
      await tester.tap(refresh);
      await tester.pump(const Duration(milliseconds: 200));
      adapter.orderRefreshGate!.completeError(
        StateError('Network unavailable'),
      );
      await tester.pumpAndSettle();
      expect(
        session.orderRefreshState(original.id),
        BuyV2CommerceLoadState.offline,
      );
      expectRetained(updateUnavailable: true);
      await tester.scrollUntilVisible(
        find.text('RECORDED'),
        240,
        scrollable: find
            .descendant(
              of: find.byKey(
                const PageStorageKey('buy-tracking-MS-SEARCH-TOMATO'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();
      expect(find.text('RECORDED'), findsOneWidget);
      expect(find.text('NOW'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('buy-tracking-return-orders')),
        -240,
        scrollable: find
            .descendant(
              of: find.byKey(
                const PageStorageKey('buy-tracking-MS-SEARCH-TOMATO'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-tracking-return-orders')),
      );
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.itemCount, 0);
      expect(tester.takeException(), isNull);
    });

    for (final status in BuyV2OrderStatus.values) {
      testWidgets('R669 delivery partner details match ${status.name} $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 711);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final partnerName = status == BuyV2OrderStatus.arriving
            ? '  Trusted courier  '
            : status == BuyV2OrderStatus.dispatched
            ? '  '
            : null;
        final session = await _openOrderSearchFixture(
          tomatoStatus: status,
          deliveryPartnerName: partnerName,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            builder: (context, child) => r66VisualCaptureRoot(child!),
            home: BuyV2Screen(
              session: session,
              initialDestination: BuyV2Destination.orders,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(session.openTracking('MS-SEARCH-TOMATO'), isTrue);
        await tester.pumpAndSettle();
        final pending =
            status == BuyV2OrderStatus.confirmed ||
            status == BuyV2OrderStatus.preparing;
        final label = status == BuyV2OrderStatus.arriving
            ? 'Trusted courier'
            : pending
            ? 'Not assigned yet'
            : 'Delivery partner details unavailable';
        expect(find.text(label), findsOneWidget);
        final address = find.byKey(const ValueKey('buy-tracking-address'));
        await tester.scrollUntilVisible(
          address,
          240,
          scrollable: find
              .descendant(
                of: find.byKey(
                  const PageStorageKey('buy-tracking-MS-SEARCH-TOMATO'),
                ),
                matching: find.byType(Scrollable),
              )
              .first,
          maxScrolls: 40,
        );
        await tester.pumpAndSettle();
        expect(address.hitTestable(), findsOneWidget);
        await tester.tap(address);
        await tester.pumpAndSettle();
        final sheet = find.byKey(const ValueKey('buy-order-delivery-sheet'));
        final partner = find.descendant(of: sheet, matching: find.text(label));
        expect(partner, findsOneWidget);
        await tester.ensureVisible(partner);
        await tester.pumpAndSettle();
        if (status == BuyV2OrderStatus.delivered) {
          expect(
            find.descendant(of: sheet, matching: find.text('Not assigned yet')),
            findsNothing,
          );
          await captureR66Visual(tester, 'r669-order-partner-delivered-$scale');
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.tracking);
        expect(session.selectedOrder.id, 'MS-SEARCH-TOMATO');
        expect(session.itemCount, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }

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

    test(
      'R669 collection discovery preserves branch and explicit delivery choice',
      () async {
        final session = await checkoutSession(openCheckout: false);
        expect(session.beginStoreCollection('sku-a'), isTrue);
        expect(session.openCheckout(), isTrue);
        expect(session.collectionCheckoutSelected, isTrue);
        expect(session.collectionCheckoutStore!.id, 'store-a');
        expect(session.checkoutLines.single.product.id, 'sku-a');
        expect(session.quantityFor('sku-b'), 1);
        expect(session.quantityFor('wholesale-sku'), 2);
        expect(harness.placements, 0);
        session.openCart(scope: BuyV2CartScope.wholesale);
        expect(session.openCheckout(), isTrue);
        expect(session.collectionCheckoutSelected, isFalse);
        expect(session.checkoutLines.single.product.id, 'wholesale-sku');
        session.openCart();
        expect(session.openCheckout(), isTrue);
        expect(session.collectionCheckoutSelected, isTrue);
        expect(session.collectionCheckoutStore!.id, 'store-a');
        expect(session.chooseCheckoutCollection(false), isTrue);
        session.openCart();
        expect(session.openCheckout(), isTrue);
        expect(session.collectionCheckoutSelected, isFalse);
        expect(session.checkoutLines, hasLength(3));
      },
    );

    test(
      'R669 collection discovery expiry cannot silently become delivery',
      () async {
        final session = await checkoutSession(openCheckout: false);
        expect(session.beginStoreCollection('sku-a'), isTrue);
        harness.clock = harness.clock.add(const Duration(days: 2));
        expect(session.openCheckout(), isTrue);
        expect(session.collectionCheckoutSelected, isTrue);
        expect(session.collectionCheckoutStore!.id, 'store-a');
        expect(session.collectionCheckoutMessage, contains('availability'));
        expect(await session.prepareCollectionCheckout(), isFalse);
        expect(session.quantityFor('sku-a'), 1);
        expect(harness.placements, 0);
      },
    );

    test(
      'R669 collection discovery does not select an unrelated basket scope',
      () async {
        final session = await checkoutSession(openCheckout: false);
        expect(session.beginStoreCollection('sku-a'), isTrue);
        session.openCart(scope: BuyV2CartScope.wholesale);
        expect(session.openCheckout(), isTrue);
        expect(session.collectionCheckoutSelected, isFalse);
        expect(session.checkoutLines.single.product.id, 'wholesale-sku');
        expect(harness.placements, 0);
      },
    );

    test(
      'R669 collection discovery refuses invalid identity and capability',
      () async {
        final session = await checkoutSession(openCheckout: false);
        expect(session.beginStoreCollection('missing-sku'), isFalse);
        harness.clock = harness.clock.add(const Duration(days: 2));
        expect(session.beginStoreCollection('sku-a'), isFalse);
        expect(session.openCheckout(), isTrue);
        expect(session.collectionCheckoutSelected, isFalse);
        expect(harness.placements, 0);
      },
    );

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
          expect(page.totalCount, switch (publisher) {
            BuyV2OfferPublisherType.retailer => 20,
            BuyV2OfferPublisherType.moolSocial => 0,
            _ => 10,
          });
          if (publisher == BuyV2OfferPublisherType.moolSocial) {
            expect(
              page.items,
              isEmpty,
              reason: 'The review generator must not invent admin publications',
            );
          }
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
          if (!dispose) {
            final localId = BuyV2Catalogue.products.first.id;
            expect(store.snapshot!.cartQuantities, {id: 1, localId: 1});
            expect(session.customerStateRecoveryPending, isTrue);
            expect(session.customerStateRestoring, isFalse);
            await session.retryCommerce();
            expect(session.quantityFor(id), 1);
            expect(session.quantityFor(localId), 1);
            expect(session.customerStateRecoveryPending, isFalse);
          }
        },
      );
    }

    for (final failedWrite in [false, true]) {
      test(
        'late restore retains new Cart through ${failedWrite ? 'failed' : 'delayed'} writes',
        () async {
          final source = _PagingRecoverySource()
            ..resolutionGate = Completer<void>();
          final remoteId = source.productIdAt(0, 0);
          final localId = BuyV2Catalogue.products.first.id;
          final store = _MemoryCustomerStateStore('late-write-account')
            ..snapshot = BuyV2CustomerStateSnapshot(
              cartQuantities: {remoteId: 3, localId: 2},
              recentSearches: {
                BuyV2Destination.shop: ['retained search'],
              },
            );
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            reviewDataEnabled: true,
            cataloguePageSource: source,
            customerStateStore: store,
          );
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          final restore = session.restoreCustomerState();
          await Future<void>.delayed(Duration.zero);
          expect(session.quantityFor(localId), 2);
          store.rejectWrites = failedWrite;
          if (!failedWrite) store.pendingWrite = Completer<void>();
          expect(session.addProduct(localId), isTrue);
          expect(session.addProduct(localId), isTrue);
          expect(session.quantityFor(localId), 4);
          expect(session.openCheckout(), isFalse);
          expect(session.confirmOrder(), isFalse);
          expect(await session.submitOrder(), isFalse);
          expect(await session.submitCollectionPurchase(), isFalse);
          source.resolutionGate!.complete();
          await restore;
          expect(session.quantityFor(remoteId), 0);
          expect(session.customerStateRestoring, isFalse);
          var retryDone = false;
          final retry = session.retryCommerce().then((_) => retryDone = true);
          await Future<void>.delayed(Duration.zero);
          if (!failedWrite) {
            expect(retryDone, isFalse);
            expect(store.writeCalls, 1);
            store.pendingWrite!.complete();
          }
          await retry;
          if (failedWrite) {
            expect(session.customerStateRecoveryPending, isTrue);
            expect(session.quantityFor(localId), 4);
            expect(store.snapshot!.cartQuantities[localId], 2);
            store.rejectWrites = false;
            await session.retryCommerce();
          }
          expect(session.customerStateRecoveryPending, isFalse);
          expect(session.quantityFor(localId), 4);
          expect(session.quantityFor(remoteId), 3);
          expect(store.snapshot!.cartQuantities, {remoteId: 3, localId: 4});
          expect(store.snapshot!.recentSearches[BuyV2Destination.shop], [
            'retained search',
          ]);
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

    test(
      'R5 020 brand facets describe the current category and search',
      () async {
        final core = BuySession();
        final session = await r669BrandedSession(core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
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
      },
    );

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
      final session = _r669OrderReadySession();
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
        final session = _r669OrderReadySession();
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
        final session = _r669OrderReadySession();
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

    test(
      'discovery refinements combine and sort without crossing Shop',
      () async {
        final core = BuySession();
        final session = await r669BrandedSession(core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
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
      },
    );

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
          commerceAdapter: R669BrandCommerce(),
          reviewDataEnabled: false,
        );
        await first.restoreCommerce();
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
          commerceAdapter: R669BrandCommerce(),
          reviewDataEnabled: false,
        );
        await restored.restoreCommerce();
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
          final session = BuyV2Session(
            core: core,
            customerStateStore: store,
            productFactsAdapter: _R669OrderReadyFacts(),
          );
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
        expect(fixture.session.orders.first, same(updated));
        expect(
          fixture.session.orderRefreshState(fixture.order.id),
          BuyV2CommerceLoadState.unavailable,
        );
        expect(
          fixture.session.orderRefreshMessage(fixture.order.id),
          'Order update could not be verified. Last known details are still shown.',
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

void r669ComparisonContractTests() {
  group('R669 supplier comparison contract', () {
    final now = DateTime.utc(2026, 9, 10, 12);
    final expiry = now.add(const Duration(minutes: 10));
    final product = BuyV2Catalogue.products.first.copyWith(
      id: 'atta-retail',
      canonicalId: 'atta-spec',
      storeId: 'store-a',
    );
    const zeroCharges = BuyV2ComparisonCharges(
      taxMinor: 0,
      freightMinor: 0,
      mandatoryFeesMinor: 0,
      immediateDiscountMinor: 0,
    );
    BuyV2ComparisonIdentity identity({
      String specification = 'brand-a:whole-wheat:grade-a',
      String pack = 'bag-5kg',
      String? contained,
      int size = 5000,
      BuyV2ComparisonUnit unit = BuyV2ComparisonUnit.kilogram,
    }) => BuyV2ComparisonIdentity(
      specificationId: specification,
      packId: pack,
      unit: unit,
      packQuantityMilli: size,
      containedRetailUnitId: contained,
    );
    BuyV2ComparisonQuery query({
      BuyV2ComparisonIdentity? specification,
      int quantity = 20000,
      bool samePack = true,
      BuyV2ComparisonPurpose purpose = BuyV2ComparisonPurpose.bulkPurchase,
      bool allowExtra = true,
      String account = 'buyer-a',
      String destination = 'address-a:revision-1',
      String pin = '342003',
      BuyV2ComparisonChannel? channel,
      BuyV2FulfilmentMode? fulfilment,
      BuyV2ComparisonScope scope = BuyV2ComparisonScope.allServiceable,
      BuyV2ComparisonSort sort = BuyV2ComparisonSort.deliveredCost,
      DateTime? deadline,
      BuyV2ProcurementContext? procurement,
    }) => BuyV2ComparisonQuery(
      productId: product.id,
      productCanonicalId: product.canonicalId,
      identity: specification ?? identity(),
      purchaserScope: account,
      destinationKey: destination,
      pinCode: pin,
      requestedQuantityMilli: quantity,
      samePack: samePack,
      purpose: procurement == null
          ? purpose
          : BuyV2ComparisonPurpose.storeProcurement,
      allowExtraQuantity: allowExtra,
      channel: channel,
      fulfilment: fulfilment,
      scope: scope,
      sort: sort,
      arriveBy: deadline,
      procurementContext: procurement,
    );
    BuyV2ComparisonOffer offer(
      BuyV2ComparisonQuery request, {
      BuyV2Product? listing,
      BuyV2ComparisonIdentity? specification,
      String id = 'offer-a',
      String revision = '1',
      String snapshot = 'snapshot-a',
      String? key,
      String workspace = 'workspace-a',
      String store = 'store-a',
      String origin = 'Jodhpur',
      BuyV2ComparisonChannel channel = BuyV2ComparisonChannel.retail,
      BuyV2FulfilmentMode fulfilment = BuyV2FulfilmentMode.quickLocal,
      bool local = true,
      bool serviceable = true,
      bool eligible = true,
      int stock = 100,
      int minimum = 1,
      int increment = 1,
      int price = 30000,
      BuyV2ComparisonCharges charges = zeroCharges,
      DateTime? observed,
      DateTime? until,
      DateTime? arrivalStart,
      DateTime? arrivalEnd,
      List<BuyV2ComparisonPriceTier> tiers = const [],
    }) => BuyV2ComparisonOffer(
      id: id,
      revision: revision,
      queryKey: key ?? request.key,
      snapshotId: snapshot,
      product: listing ?? product,
      identity: specification ?? identity(),
      supplierWorkspaceId: workspace,
      storeId: store,
      channel: channel,
      fulfilment: fulfilment,
      originLabel: origin,
      local: local,
      serviceable: serviceable,
      customerEligible: eligible,
      availablePacks: stock,
      minimumPacks: minimum,
      incrementPacks: increment,
      packPriceMinor: price,
      charges: charges,
      observedAt: observed ?? now,
      validUntil: until ?? expiry,
      arrivalStart: arrivalStart,
      arrivalEnd: arrivalEnd,
      tiers: tiers,
    );
    BuyV2ComparisonCalculation calculate(
      BuyV2ComparisonQuery request,
      BuyV2ComparisonOffer value,
    ) => BuyV2ComparisonCalculation.evaluate(
      query: request,
      offer: value,
      now: now,
    );
    BuyV2ComparisonPage page(
      BuyV2ComparisonQuery request,
      List<BuyV2ComparisonOffer> offers, {
      String snapshot = 'snapshot-a',
      String? key,
      DateTime? observed,
      DateTime? until,
      String? next,
      String? previous,
      int start = 0,
      int? total,
      bool ranked = true,
      String? itemCheapest,
      String? cheapest,
      String? fastest,
    }) => BuyV2ComparisonPage(
      queryKey: key ?? request.key,
      snapshotId: snapshot,
      observedAt: observed ?? now,
      validUntil: until ?? expiry,
      offers: offers,
      globallyRanked: ranked,
      startIndex: start,
      totalCount: total,
      previousCursor: previous,
      nextCursor: next,
      lowestItemPriceOfferId: itemCheapest,
      lowestDeliveredOfferId: cheapest,
      earliestArrivalOfferId: fastest,
    );

    test('consumer defaults fix exact pack and item-price intent', () {
      final request = BuyV2ComparisonQuery(
        productId: product.id,
        productCanonicalId: product.canonicalId,
        identity: identity(),
        purchaserScope: 'buyer-a',
        destinationKey: 'address-a',
        pinCode: '342003',
        requestedQuantityMilli: 5000,
      );
      expect(request.valid, isTrue);
      expect(request.standardPurchase, isTrue);
      expect(request.samePack, isTrue);
      expect(request.allowExtraQuantity, isFalse);
      expect(request.sort, BuyV2ComparisonSort.itemPrice);
    });

    test(
      'biscuit C90 A100 B110 ranks item price separately from delivery',
      () async {
        final biscuit = identity(
          specification: 'biscuit-brand:original',
          pack: 'sealed-biscuit-pack',
          size: 1000,
          unit: BuyV2ComparisonUnit.count,
        );
        final request = query(
          specification: biscuit,
          quantity: 1000,
          purpose: BuyV2ComparisonPurpose.standardPurchase,
          allowExtra: false,
          sort: BuyV2ComparisonSort.itemPrice,
        );
        BuyV2ComparisonOffer store(String name, int price, int delivery) =>
            offer(
              request,
              id: name,
              listing: product.copyWith(id: 'biscuit-$name', storeId: name),
              store: name,
              specification: biscuit,
              price: price,
              charges: BuyV2ComparisonCharges(
                taxMinor: 0,
                freightMinor: delivery,
                mandatoryFeesMinor: 0,
                immediateDiscountMinor: 0,
              ),
            );
        final c = store('store-c', 9000, 3000);
        final a = store('store-a', 10000, 0);
        final b = store('store-b', 11000, 0);
        final result = page(
          request,
          [c, a, b],
          itemCheapest: c.id,
          cheapest: a.id,
        );
        final controller = BuyV2ComparisonController(
          source: _R669ComparisonSource(biscuit, (_) async => result),
          isCurrent: (_) => true,
          offerPermitted: (_) => true,
          now: () => now,
        );
        addTearDown(controller.dispose);
        await controller.open(request);
        expect(controller.page!.offers.map((offer) => offer.storeId), [
          'store-c',
          'store-a',
          'store-b',
        ]);
        expect(calculate(request, c).itemSubtotalMinor, 9000);
        expect(calculate(request, c).payableMinor, 12000);
        expect(result.isLowestItemPrice(c, calculate(request, c)), isTrue);
        expect(result.isLowestDelivered(c, calculate(request, c)), isFalse);
        expect(result.isLowestDelivered(a, calculate(request, a)), isTrue);
      },
    );

    test('consumer cannot admit wholesale by clearing channel filters', () {
      final request = query(
        purpose: BuyV2ComparisonPurpose.standardPurchase,
        allowExtra: false,
      );
      expect(
        calculate(
          request,
          offer(request, channel: BuyV2ComparisonChannel.wholesale),
        ).unavailable,
        BuyV2ComparisonUnavailable.filtered,
      );
      expect(
        query(
          purpose: BuyV2ComparisonPurpose.standardPurchase,
          allowExtra: false,
          channel: BuyV2ComparisonChannel.wholesale,
        ).valid,
        isFalse,
      );
    });

    test('larger requested amount never changes consumer eligibility', () {
      final request = query(
        quantity: 500000,
        purpose: BuyV2ComparisonPurpose.standardPurchase,
        allowExtra: false,
      );
      expect(
        calculate(
          request,
          offer(request, channel: BuyV2ComparisonChannel.wholesale),
        ).unavailable,
        BuyV2ComparisonUnavailable.filtered,
      );
    });

    test('consumer cannot silently increase packs to meet MOQ', () {
      final request = query(
        quantity: 5000,
        purpose: BuyV2ComparisonPurpose.standardPurchase,
        allowExtra: false,
      );
      expect(
        calculate(request, offer(request, minimum: 2)).unavailable,
        BuyV2ComparisonUnavailable.unwantedQuantity,
      );
      expect(
        query(
          purpose: BuyV2ComparisonPurpose.standardPurchase,
          allowExtra: true,
        ).valid,
        isFalse,
      );
    });

    test('bulk extra quantity requires separately bound consent', () {
      final exact = query(quantity: 5001, allowExtra: false);
      final consent = query(quantity: 5001, allowExtra: true);
      expect(exact.key, isNot(consent.key));
      expect(
        calculate(exact, offer(exact)).unavailable,
        BuyV2ComparisonUnavailable.unwantedQuantity,
      );
      expect(calculate(consent, offer(consent)).excessQuantityMilli, 4999);
    });

    test(
      'consumer other packs remain retail and must meet exact requirement',
      () {
        final request = query(
          samePack: false,
          purpose: BuyV2ComparisonPurpose.standardPurchase,
          allowExtra: false,
        );
        expect(
          calculate(
            request,
            offer(
              request,
              specification: identity(pack: 'bag-10kg', size: 10000),
            ),
          ).packCount,
          2,
        );
        expect(
          calculate(
            request,
            offer(
              request,
              specification: identity(pack: 'bag-12kg', size: 12000),
            ),
          ).unavailable,
          BuyV2ComparisonUnavailable.unwantedQuantity,
        );
        expect(
          calculate(
            request,
            offer(
              request,
              channel: BuyV2ComparisonChannel.wholesale,
              specification: identity(pack: 'bag-10kg', size: 10000),
            ),
          ).unavailable,
          BuyV2ComparisonUnavailable.filtered,
        );
      },
    );

    test(
      'unknown delivery can win item price but cannot win delivered cost',
      () {
        final request = query(
          purpose: BuyV2ComparisonPurpose.standardPurchase,
          allowExtra: false,
        );
        final value = offer(request, charges: const BuyV2ComparisonCharges());
        final result = page(request, [value], itemCheapest: value.id);
        expect(
          result.validFor(BuyV2ComparisonPageRequest(query: request), now),
          isTrue,
        );
        expect(
          result.isLowestItemPrice(value, calculate(request, value)),
          isTrue,
        );
        expect(
          result.isLowestDelivered(value, calculate(request, value)),
          isFalse,
        );
        expect(calculate(request, value).payableMinor, isNull);
      },
    );

    test(
      'provider item winner cannot contradict cheaper visible item price',
      () {
        final request = query();
        final cheap = offer(request, id: 'cheap', price: 9000);
        final expensive = offer(request, id: 'expensive', price: 10000);
        expect(
          page(
            request,
            [cheap, expensive],
            itemCheapest: expensive.id,
          ).validFor(BuyV2ComparisonPageRequest(query: request), now),
          isFalse,
        );
        expect(
          page(
            request,
            [cheap],
            ranked: false,
            itemCheapest: cheap.id,
          ).isLowestItemPrice(cheap, calculate(request, cheap)),
          isFalse,
        );
      },
    );

    test(
      'Store alternate cartons require same contained sealed resale unit',
      () {
        const procurement = BuyV2ProcurementContext(
          accountId: 'buyer-a',
          storeId: 'retailer-a',
          purpose: BuyV2ProcurementPurpose.restock,
          originOperationId: 'op-a',
        );
        final request = query(
          samePack: false,
          procurement: procurement,
          specification: identity(contained: 'sealed-brand-a-1kg'),
        );
        final compatible = offer(
          request,
          channel: BuyV2ComparisonChannel.wholesale,
          specification: identity(
            pack: 'carton-10kg',
            size: 10000,
            contained: 'sealed-brand-a-1kg',
          ),
        );
        expect(calculate(request, compatible).packCount, 2);
        final sack = offer(
          request,
          channel: BuyV2ComparisonChannel.wholesale,
          specification: identity(pack: 'loose-sack-20kg', size: 20000),
        );
        expect(
          calculate(request, sack).unavailable,
          BuyV2ComparisonUnavailable.differentProduct,
        );
        expect(
          calculate(request, offer(request)).unavailable,
          BuyV2ComparisonUnavailable.filtered,
        );
      },
    );

    test(
      'Store comparison cannot run without authoritative procurement context',
      () {
        expect(
          query(purpose: BuyV2ComparisonPurpose.storeProcurement).valid,
          isFalse,
        );
      },
    );

    ({
      BuyV2Session session,
      BuyV2Product product,
      List<BuyV2ComparisonPageRequest> calls,
    })
    consumerFixture({
      DateTime Function()? clock,
      BuyV2CustomerStateStore? customerStateStore,
      BuyV2CataloguePageSource? cataloguePageSource,
    }) {
      final base = BuyV2Catalogue.products.firstWhere(
        (value) => value.title.toLowerCase().contains('biscuits'),
      );
      final pack = identity(
        specification: 'published:${base.canonicalId}:${base.variant}',
        pack: 'published:${base.id}',
        size: 1000,
        unit: BuyV2ComparisonUnit.count,
      );
      final calls = <BuyV2ComparisonPageRequest>[];
      final source = _R669ComparisonSource(pack, (load) async {
        calls.add(load);
        final request = load.query;
        BuyV2ComparisonOffer priced(String name, int price, int? freight) =>
            offer(
              request,
              id: 'offer-$name',
              listing: base.copyWith(
                id: 'comparison-$name',
                storeId: name,
                seller: 'Store ${name.toUpperCase()}',
                price: price,
                unitPrice: '₹$price per pack',
                badge: '',
              ),
              store: name,
              workspace: 'workspace-$name',
              specification: pack,
              price: price * 100,
              charges: BuyV2ComparisonCharges(
                taxMinor: 0,
                freightMinor: freight,
                mandatoryFeesMinor: 0,
                immediateDiscountMinor: 0,
              ),
              arrivalStart: now.add(const Duration(minutes: 20)),
              arrivalEnd: now.add(const Duration(minutes: 40)),
            );
        final c = priced('c', 90, 3000);
        final a = priced('a', 100, 0);
        final b = priced('b', 110, null);
        final values = request.sort == BuyV2ComparisonSort.itemPrice
            ? [c, a, b]
            : [a, c, b];
        final packs =
            request.requestedQuantityMilli ~/
            request.identity.packQuantityMilli;
        return page(
          request,
          values,
          itemCheapest: c.id,
          cheapest: 90 * packs + 30 < 100 * packs ? c.id : a.id,
        );
      });
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        comparisonSource: source,
        customerStateStore: customerStateStore,
        cataloguePageSource: cataloguePageSource,
        catalogueNow: clock ?? () => now,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      return (session: session, product: base, calls: calls);
    }

    for (final recovery in ['resolved', 'no resolver', 'missing listing']) {
      test(
        'consumer comparison relaunch retains Cart with $recovery',
        () async {
          final store = _MemoryCustomerStateStore('consumer-relaunch');
          final first = consumerFixture(customerStateStore: store);
          await first.session.restoreCustomerState();
          final controller = BuyV2ComparisonController(
            source: first.session.comparisonSource!,
            isCurrent: first.session.comparisonQueryIsCurrent,
            offerPermitted: first.session.comparisonOfferPermitted,
            now: () => now,
          );
          addTearDown(controller.dispose);
          await controller.open(
            first.session.comparisonQueryFor(first.product)!,
          );
          final chosen = controller.page!.offers.first;
          expect(
            first.session.admitComparisonProduct(controller, chosen),
            isTrue,
          );
          expect(
            first.session.addProduct(chosen.product.id, quantity: 3),
            isTrue,
          );
          await Future<void>.delayed(Duration.zero);
          expect(store.snapshot!.cartQuantities[chosen.product.id], 3);
          final retainedSnapshot = store.snapshot!;
          final products = <BuyV2Product>[
            if (recovery == 'resolved') chosen.product,
          ];
          final restored = consumerFixture(
            customerStateStore: store,
            cataloguePageSource: recovery == 'no resolver'
                ? null
                : _R669ProcurementCatalogue(products),
          );
          await restored.session.restoreCustomerState();
          if (recovery == 'resolved') {
            expect(restored.session.quantityFor(chosen.product.id), 3);
            expect(
              restored.session.product(chosen.product.id).storeId,
              chosen.product.storeId,
            );
            expect(
              restored.session.product(chosen.product.id).price,
              chosen.product.price,
            );
            expect(restored.session.notice, isNull);
          } else {
            expect(restored.session.notice, contains('could not be restored'));
            expect(restored.session.catalogueAvailable, isFalse);
            expect(restored.session.addProduct(restored.product.id), isFalse);
            expect(store.snapshot, same(retainedSnapshot));
            restored.session.submitSearch('biscuits');
            await Future<void>.delayed(Duration.zero);
            expect(
              store.snapshot!.cartQuantities[chosen.product.id],
              3,
              reason:
                  'A later choice must not erase an unresolved retained Cart.',
            );
            if (recovery == 'missing listing') {
              products.add(chosen.product);
              await restored.session.retryCommerce();
              expect(restored.session.catalogueAvailable, isTrue);
              expect(restored.session.quantityFor(chosen.product.id), 3);
            }
          }
        },
      );
    }

    test(
      'consumer comparison relaunch holds Cart while restore is delayed',
      () async {
        final listing = product.copyWith(id: 'retained-external');
        final store = _MemoryCustomerStateStore('consumer-delayed');
        final snapshot = BuyV2CustomerStateSnapshot(
          cartQuantities: {listing.id: 3},
        );
        store.snapshot = snapshot;
        final gate = Completer<BuyV2CustomerStateSnapshot?>();
        store.pendingRead = gate;
        final fixture = consumerFixture(
          customerStateStore: store,
          cataloguePageSource: _R669ProcurementCatalogue([listing]),
        );
        final restoring = fixture.session.restoreCustomerState();
        expect(fixture.session.addProduct(fixture.product.id), isFalse);
        fixture.session.submitSearch('biscuits');
        expect(store.snapshot, same(snapshot));
        gate.complete(snapshot);
        await restoring;
        expect(fixture.session.quantityFor(listing.id), 3);
        expect(fixture.session.catalogueAvailable, isTrue);
      },
    );

    for (final scale in [1.0, 2.0]) {
      testWidgets('consumer comparison relaunch Retry restores Cart $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final listing = product.copyWith(id: 'retained-external');
        final store = _MemoryCustomerStateStore('consumer-retry');
        store.snapshot = BuyV2CustomerStateSnapshot(
          cartQuantities: {listing.id: 3},
        );
        final products = <BuyV2Product>[];
        final fixture = consumerFixture(
          customerStateStore: store,
          cataloguePageSource: _R669ProcurementCatalogue(products),
        );
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => r66VisualCaptureRoot(child!),
            home: BuyV2Screen(session: fixture.session, onExit: () {}),
          ),
        );
        await tester.pumpAndSettle();
        final retry = find.byKey(const ValueKey('buy-catalogue-retry'));
        expect(retry, findsOneWidget);
        await tester.ensureVisible(retry);
        await tester.pumpAndSettle();
        expect(find.textContaining('It is still retained.'), findsOneWidget);
        expect(store.snapshot!.cartQuantities[listing.id], 3);
        expect(tester.takeException(), isNull);
        // Inspect the persistent recovery panel after its existing transient notice.
        await tester.pump(const Duration(milliseconds: 2700));
        await tester.pumpAndSettle();
        await captureR66Visual(tester, 'r669-consumer-relaunch-retry-$scale');
        products.add(listing);
        await tester.tap(retry);
        await tester.pumpAndSettle();
        expect(fixture.session.quantityFor(listing.id), 3);
        expect(fixture.session.catalogueAvailable, isTrue);
        expect(find.byKey(const ValueKey('buy-catalogue-retry')), findsNothing);
        expect(tester.takeException(), isNull);
        await captureR66Visual(
          tester,
          'r669-consumer-relaunch-restored-$scale',
        );
      });
    }

    test(
      'session binds consumer entry and explicit Wholesale entry separately',
      () {
        final fixture = consumerFixture();
        final session = fixture.session;
        final consumer = session.comparisonQueryFor(fixture.product)!;
        expect(consumer.standardPurchase, isTrue);
        expect(consumer.sort, BuyV2ComparisonSort.itemPrice);
        expect(
          session.comparisonQueryFor(
            fixture.product,
            channel: BuyV2ComparisonChannel.wholesale,
          ),
          isNull,
        );
        expect(
          session.comparisonQueryFor(fixture.product, allowExtraQuantity: true),
          isNull,
        );
        session.destination = BuyV2Destination.wholesale;
        final bulk = session.comparisonQueryFor(fixture.product)!;
        expect(bulk.purpose, BuyV2ComparisonPurpose.bulkPurchase);
        expect(bulk.sort, BuyV2ComparisonSort.itemPrice);
        expect(session.comparisonQueryIsCurrent(consumer), isFalse);
        expect(session.openProduct(fixture.product.id), isTrue);
        expect(session.comparisonPurpose, BuyV2ComparisonPurpose.bulkPurchase);
        expect(session.comparisonQueryIsCurrent(bulk), isTrue);
      },
    );

    for (final viewport in [
      (size: const Size(320, 568), scale: 1.0, label: 'compact', quantity: 1),
      (
        size: const Size(320, 568),
        scale: 2.0,
        label: 'large-text',
        quantity: 1,
      ),
      (size: const Size(568, 320), scale: 2.0, label: 'landscape', quantity: 1),
      (
        size: const Size(320, 568),
        scale: 1.0,
        label: 'three-packs',
        quantity: 3,
      ),
    ]) {
      testWidgets(
        'consumer stores prices navigation cart and Back ${viewport.label}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport.size;
          tester.platformDispatcher.textScaleFactorTestValue = viewport.scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          var currentTime = now;
          final fixture = consumerFixture(clock: () => currentTime);
          final session = fixture.session;
          expect(
            session.addProduct(fixture.product.id, quantity: viewport.quantity),
            isTrue,
          );
          final retained = session.quantityFor(fixture.product.id);
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: MoolTheme.light(),
              builder: (context, child) => r66VisualCaptureRoot(child!),
              home: BuyV2Screen(
                session: session,
                initialView: BuyV2View.product,
                productId: fixture.product.id,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(session.selectedProductId, fixture.product.id);
          expect(session.view, BuyV2View.product);
          final productList = find.byKey(
            PageStorageKey('buy-product-${fixture.product.id}'),
          );
          expect(productList, findsOneWidget);
          await tester.scrollUntilVisible(
            find.text('Compare'),
            240,
            maxScrolls: 80,
            scrollable: find
                .descendant(of: productList, matching: find.byType(Scrollable))
                .first,
          );
          await tester.pumpAndSettle();
          expect(find.text('Compare').hitTestable(), findsOneWidget);
          await tester.tap(find.text('Compare'));
          await tester.pumpAndSettle();
          expect(find.text('Compare prices'), findsOneWidget);
          expect(fixture.calls.last.query.sort, BuyV2ComparisonSort.itemPrice);
          for (final id in ['comparison-a', 'comparison-b', 'comparison-c']) {
            expect(
              find.byKey(ValueKey('buy-product-card-badge-$id')),
              findsNothing,
              reason: 'An empty supplier badge must not paint a coloured pill.',
            );
          }
          expect(fixture.calls.last.query.standardPurchase, isTrue);
          expect(find.text('View in product list'), findsNothing);
          expect(find.text('Retail and wholesale'), findsNothing);
          expect(tester.takeException(), isNull);
          await captureR66Visual(
            tester,
            'r669-consumer-stores-${viewport.label}-entry',
          );

          final priceC = find.byKey(
            const ValueKey('buy-comparison-item-price-offer-c'),
          );
          await tester.ensureVisible(priceC);
          await tester.pumpAndSettle();
          expect(
            find.text('₹${90 * viewport.quantity} item price'),
            findsOneWidget,
          );
          expect(find.text('Delivery: ₹30'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byKey(
                const ValueKey('buy-product-compare-comparison-c'),
              ),
              matching: find.text('₹${90 * viewport.quantity + 30} delivered'),
            ),
            findsOneWidget,
          );
          expect(find.text('Lowest item price'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await captureR66Visual(
            tester,
            'r669-consumer-stores-${viewport.label}-price',
          );

          final saveC = find.byKey(const ValueKey('buy-save-comparison-c'));
          await tester.ensureVisible(saveC);
          await tester.tap(saveC);
          await tester.pumpAndSettle();
          expect(session.isSaved('comparison-c'), isTrue);
          expect(session.quantityFor('comparison-c'), 0);
          await tester.tap(saveC);
          await tester.pumpAndSettle();
          expect(session.isSaved('comparison-c'), isFalse);

          final addC = find.byKey(const ValueKey('buy-add-comparison-c'));
          await tester.ensureVisible(addC);
          await tester.tap(addC);
          await tester.pumpAndSettle();
          expect(session.quantityFor('comparison-c'), viewport.quantity);
          expect(session.quantityFor(fixture.product.id), retained);
          expect(session.selectedProductId, fixture.product.id);
          expect(find.text('Compare prices'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('buy-vertical-product-grid-comparison')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await captureR66Visual(
            tester,
            'r669-consumer-stores-${viewport.label}-added',
          );

          final supplierCard = find.byKey(
            const ValueKey('buy-product-compare-comparison-c'),
          );
          final plus = find.descendant(
            of: supplierCard,
            matching: find.byTooltip('Add one'),
          );
          await tester.ensureVisible(plus);
          await tester.tap(plus);
          await tester.pumpAndSettle();
          expect(session.quantityFor('comparison-c'), viewport.quantity + 1);
          final minus = find.descendant(
            of: supplierCard,
            matching: find.byTooltip('Remove one'),
          );
          await tester.ensureVisible(minus);
          await tester.tap(minus);
          await tester.pumpAndSettle();
          expect(session.quantityFor('comparison-c'), viewport.quantity);
          final edit = find.byKey(
            const ValueKey('buy-grid-edit-quantity-comparison-c'),
          );
          await tester.ensureVisible(edit);
          await tester.tap(edit);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('buy-quantity-input')),
            '${viewport.quantity + 2}',
          );
          final saveQuantity = find.byKey(const ValueKey('buy-quantity-save'));
          await tester.ensureVisible(saveQuantity);
          await tester.tap(saveQuantity);
          await tester.pumpAndSettle();
          expect(session.quantityFor('comparison-c'), viewport.quantity + 2);
          expect(session.quantityFor(fixture.product.id), retained);
          expect(session.selectedProductId, fixture.product.id);
          expect(find.text('Compare prices'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.ensureVisible(find.text('Store C'));
          await tester.tap(find.text('Store C'));
          await tester.pumpAndSettle();
          expect(session.selectedProductId, 'comparison-c');
          expect(
            find.byKey(const ValueKey('buy-product-comparison-sheet')),
            findsNothing,
          );
          expect(session.quantityFor(fixture.product.id), retained);
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(
              const ValueKey('buy-product-gallery-badge-comparison-c'),
            ),
            findsNothing,
            reason: 'The nested product must also hide its empty badge.',
          );
          await captureR66Visual(
            tester,
            'r669-consumer-stores-${viewport.label}-product',
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Compare prices'), findsOneWidget);
          expect(session.selectedProductId, fixture.product.id);
          expect(
            fixture.calls
                .map((call) => call.query.requestedQuantityMilli)
                .toList(),
            [
              viewport.quantity * 1000,
              (viewport.quantity + 1) * 1000,
              viewport.quantity * 1000,
              (viewport.quantity + 2) * 1000,
            ],
          );
          expect(session.quantityFor(fixture.product.id), retained);

          expect(find.text('Compare options'), findsNothing);
          expect(
            find.byKey(const ValueKey('buy-comparison-quantity')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('buy-comparison-allow-extra')),
            findsNothing,
          );
          expect(
            fixture.calls.last.query.fulfilment,
            BuyV2FulfilmentMode.quickLocal,
          );
          expect(fixture.calls.last.query.samePack, isTrue);
          expect(fixture.calls.last.query.allowExtraQuantity, isFalse);
          expect(tester.takeException(), isNull);
          final staleSave = find.byKey(const ValueKey('buy-save-comparison-b'));
          await tester.ensureVisible(staleSave);
          await tester.pumpAndSettle();
          currentTime = now.add(const Duration(hours: 2));
          await tester.tap(staleSave);
          await tester.pumpAndSettle();
          expect(session.isSaved('comparison-b'), isFalse);
          expect(session.quantityFor('comparison-b'), 0);
          expect(session.quantityFor(fixture.product.id), retained);
          expect(
            find.text(
              'This offer changed. Refresh the comparison before continuing.',
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }

    test(
      'controller pages all offers and returns to the previous snapshot',
      () async {
        final request = query();
        final rows = List.generate(
          25,
          (index) => offer(request, id: index.toString().padLeft(2, '0')),
        );
        final calls = <BuyV2ComparisonPageRequest>[];
        final source = _R669ComparisonSource(identity(), (load) async {
          calls.add(load);
          return load.cursor == 'second'
              ? page(
                  request,
                  rows.skip(20).toList(),
                  start: 20,
                  previous: 'first',
                  total: 25,
                )
              : page(
                  request,
                  rows.take(20).toList(),
                  next: 'second',
                  total: 25,
                );
        });
        final controller = BuyV2ComparisonController(
          source: source,
          isCurrent: (_) => true,
          offerPermitted: (_) => true,
          now: () => now,
        );
        addTearDown(controller.dispose);
        await controller.open(request);
        expect(controller.page!.offers, hasLength(20));
        expect(controller.canGoNext, isTrue);
        await controller.next();
        expect(controller.page!.offers.map((value) => value.id), [
          '20',
          '21',
          '22',
          '23',
          '24',
        ]);
        expect(controller.canGoPrevious, isTrue);
        expect(controller.canGoNext, isFalse);
        await controller.previous();
        expect(controller.page!.offers.first.id, '00');
        expect(calls.map((value) => value.snapshotId), [
          null,
          'snapshot-a',
          'snapshot-a',
        ]);
        expect(calls.every((value) => value.pageSize == 20), isTrue);
      },
    );
    test(
      'controller serializes a changed query and rejects the late first response',
      () async {
        final old = query();
        final changed = query(quantity: 30000);
        final pending = Completer<BuyV2ComparisonPage>();
        final calls = <BuyV2ComparisonPageRequest>[];
        final source = _R669ComparisonSource(identity(), (load) {
          calls.add(load);
          return calls.length == 1
              ? pending.future
              : Future.value(page(changed, [offer(changed)]));
        });
        final controller = BuyV2ComparisonController(
          source: source,
          isCurrent: (_) => true,
          offerPermitted: (_) => true,
          now: () => now,
        );
        addTearDown(controller.dispose);
        final first = controller.open(old);
        final second = controller.open(changed);
        expect(calls, hasLength(1));
        pending.complete(page(old, [offer(old)]));
        await Future.wait([first, second]);
        expect(calls, hasLength(2));
        expect(controller.page!.queryKey, changed.key);
        expect(controller.query!.requestedQuantityMilli, 30000);
      },
    );
    test(
      'controller rejects account Store or address changes during loading',
      () async {
        final request = query();
        var current = true;
        final pending = Completer<BuyV2ComparisonPage>();
        final controller = BuyV2ComparisonController(
          source: _R669ComparisonSource(identity(), (_) => pending.future),
          isCurrent: (_) => current,
          offerPermitted: (_) => true,
          now: () => now,
        );
        addTearDown(controller.dispose);
        final loading = controller.open(request);
        current = false;
        controller.checkContext();
        pending.complete(page(request, [offer(request)]));
        await loading;
        expect(controller.page, isNull);
        expect(controller.loading, isFalse);
        expect(controller.message, contains('shopping details changed'));
      },
    );
    test(
      'controller retains the valid prior page after a next-page failure',
      () async {
        final request = query();
        var calls = 0;
        final controller = BuyV2ComparisonController(
          source: _R669ComparisonSource(identity(), (load) async {
            if (++calls == 2) {
              throw StateError('provider diagnostic must not leak');
            }
            return page(request, [offer(request)], next: 'second');
          }),
          isCurrent: (_) => true,
          offerPermitted: (_) => true,
          now: () => now,
        );
        addTearDown(controller.dispose);
        await controller.open(request);
        await controller.next();
        expect(controller.page!.offers.single.id, 'offer-a');
        expect(
          controller.message,
          'Supplier prices could not be refreshed. Try again.',
        );
        await controller.refresh();
        expect(controller.message, isNull);
        expect(calls, 3);
      },
    );
    test(
      'controller expires displayed quotes and prevents product selection',
      () async {
        final request = query();
        final value = offer(request);
        var clock = now;
        final controller = BuyV2ComparisonController(
          source: _R669ComparisonSource(
            identity(),
            (_) async => page(request, [value]),
          ),
          isCurrent: (_) => true,
          offerPermitted: (_) => true,
          now: () => clock,
        );
        addTearDown(controller.dispose);
        await controller.open(request);
        expect(controller.canOpen(value), isTrue);
        clock = expiry;
        expect(controller.page, isNull);
        expect(controller.canOpen(value), isFalse);
        expect(controller.message, contains('refreshed'));
      },
    );
    test(
      'controller rechecks mandatory Store eligibility after results arrive',
      () async {
        final request = query();
        final value = offer(request);
        var permitted = true;
        final controller = BuyV2ComparisonController(
          source: _R669ComparisonSource(
            identity(),
            (_) async => page(request, [value]),
          ),
          isCurrent: (_) => true,
          offerPermitted: (_) => permitted,
          now: () => now,
        );
        addTearDown(controller.dispose);
        await controller.open(request);
        expect(controller.canOpen(value), isTrue);
        permitted = false;
        expect(controller.page, isNull);
        expect(controller.canOpen(value), isFalse);
        await controller.refresh();
        expect(controller.page, isNull);
        expect(controller.message, contains('could not be refreshed'));
      },
    );
    for (final failure in ['gap', 'duplicate', 'snapshot', 'ranking']) {
      test('controller rejects next-page $failure', () async {
        final request = query();
        final first = offer(request, id: 'a', price: 30000);
        final controller = BuyV2ComparisonController(
          source: _R669ComparisonSource(identity(), (load) async {
            if (load.cursor == null) {
              return page(request, [first], next: 'second');
            }
            return page(
              request,
              [
                failure == 'duplicate'
                    ? first
                    : offer(
                        request,
                        id: 'b',
                        price: failure == 'ranking' ? 20000 : 40000,
                        snapshot: failure == 'snapshot'
                            ? 'other'
                            : 'snapshot-a',
                      ),
              ],
              start: failure == 'gap' ? 2 : 1,
              previous: 'first',
              snapshot: failure == 'snapshot' ? 'other' : 'snapshot-a',
            );
          }),
          isCurrent: (_) => true,
          offerPermitted: (_) => true,
          now: () => now,
        );
        addTearDown(controller.dispose);
        await controller.open(request);
        await controller.next();
        expect(controller.page!.offers.single, same(first));
        expect(controller.message, contains('could not be refreshed'));
      });
    }
    test(
      'controller requires source ranking across the complete eligible query',
      () async {
        final request = query();
        final controller = BuyV2ComparisonController(
          source: _R669ComparisonSource(
            identity(),
            (_) async => page(request, [
              offer(request, id: 'expensive', price: 40000),
              offer(request, id: 'cheap', price: 30000),
            ]),
          ),
          isCurrent: (_) => true,
          offerPermitted: (_) => true,
          now: () => now,
        );
        addTearDown(controller.dispose);
        await controller.open(request);
        expect(controller.page, isNull);
        expect(controller.message, contains('could not be refreshed'));
      },
    );
    test('controller arrival ordering is independent of item cost', () async {
      final request = query(sort: BuyV2ComparisonSort.arrival);
      final expensive = offer(
        request,
        id: 'fast',
        price: 40000,
        arrivalStart: now,
        arrivalEnd: now.add(const Duration(hours: 1)),
      );
      final cheap = offer(
        request,
        id: 'slow',
        price: 20000,
        arrivalStart: now,
        arrivalEnd: now.add(const Duration(hours: 2)),
      );
      final unknown = offer(request, id: 'unknown');
      final controller = BuyV2ComparisonController(
        source: _R669ComparisonSource(
          identity(),
          (_) async => page(
            request,
            [expensive, cheap, unknown],
            fastest: expensive.id,
            cheapest: cheap.id,
          ),
        ),
        isCurrent: (_) => true,
        offerPermitted: (_) => true,
        now: () => now,
      );
      addTearDown(controller.dispose);
      await controller.open(request);
      expect(controller.page!.offers.map((value) => value.id), [
        'fast',
        'slow',
        'unknown',
      ]);
      expect(
        controller.page!.isEarliestArrival(
          expensive,
          calculate(request, expensive),
        ),
        isTrue,
      );
      expect(
        controller.page!.isLowestDelivered(cheap, calculate(request, cheap)),
        isTrue,
      );
    });
    test(
      'controller disposal rejects an in-flight result without notification',
      () async {
        final request = query();
        final pending = Completer<BuyV2ComparisonPage>();
        final controller = BuyV2ComparisonController(
          source: _R669ComparisonSource(identity(), (_) => pending.future),
          isCurrent: (_) => true,
          offerPermitted: (_) => true,
          now: () => now,
        );
        var notifications = 0;
        controller.addListener(() => notifications++);
        final loading = controller.open(request);
        expect(notifications, 1);
        controller.dispose();
        pending.complete(page(request, [offer(request)]));
        await loading;
        expect(notifications, 1);
        expect(controller.page, isNull);
      },
    );
    test(
      'controller never calls the provider for an invalid request',
      () async {
        var calls = 0;
        final controller = BuyV2ComparisonController(
          source: _R669ComparisonSource(identity(), (load) async {
            calls++;
            return page(load.query, []);
          }),
          isCurrent: (_) => true,
          offerPermitted: (_) => true,
          now: () => now,
        );
        addTearDown(controller.dispose);
        await controller.open(query(quantity: 0));
        expect(calls, 0);
        expect(controller.page, isNull);
      },
    );

    test(
      'a claimed cheapest result cannot contradict complete delivered costs',
      () {
        final request = query();
        final cheap = offer(request, id: 'cheap', price: 20000);
        final expensive = offer(request, id: 'expensive', price: 30000);
        expect(
          page(
            request,
            [cheap, expensive],
            cheapest: expensive.id,
          ).validFor(BuyV2ComparisonPageRequest(query: request), now),
          isFalse,
        );
        expect(
          page(
            request,
            [cheap, expensive],
            cheapest: cheap.id,
          ).validFor(BuyV2ComparisonPageRequest(query: request), now),
          isTrue,
        );
      },
    );
    test('a claimed fastest result cannot contradict arrival windows', () {
      final request = query();
      final fast = offer(
        request,
        id: 'fast',
        arrivalStart: now,
        arrivalEnd: now.add(const Duration(hours: 1)),
      );
      final slow = offer(
        request,
        id: 'slow',
        arrivalStart: now,
        arrivalEnd: now.add(const Duration(hours: 2)),
      );
      expect(
        page(
          request,
          [fast, slow],
          fastest: slow.id,
        ).validFor(BuyV2ComparisonPageRequest(query: request), now),
        isFalse,
      );
      expect(
        page(
          request,
          [fast, slow],
          fastest: fast.id,
        ).validFor(BuyV2ComparisonPageRequest(query: request), now),
        isTrue,
      );
    });
    test(
      'bounded pages reject oversized and empty endless provider responses',
      () {
        final request = query();
        final load = BuyV2ComparisonPageRequest(query: request);
        expect(page(request, [], next: 'endless').validFor(load, now), isFalse);
        final oversized = List.generate(
          21,
          (index) => offer(request, id: index.toString()),
        );
        expect(page(request, oversized).validFor(load, now), isFalse);
        expect(
          BuyV2ComparisonPageRequest(query: request, pageSize: 41).valid,
          isFalse,
        );
        expect(
          page(request, [offer(request)], total: 2).validFor(load, now),
          isFalse,
        );
      },
    );

    test(
      'same requirement compares actual delivered totals across pack sizes',
      () {
        final request = query(samePack: false);
        final retail = calculate(
          request,
          offer(
            request,
            charges: const BuyV2ComparisonCharges(
              taxMinor: 0,
              freightMinor: 4000,
              mandatoryFeesMinor: 0,
              immediateDiscountMinor: 0,
            ),
          ),
        );
        final wholesale = calculate(
          request,
          offer(
            request,
            id: 'wholesale',
            channel: BuyV2ComparisonChannel.wholesale,
            specification: identity(pack: 'bag-10kg', size: 10000),
            price: 55000,
            charges: const BuyV2ComparisonCharges(
              taxMinor: 0,
              freightMinor: 18000,
              mandatoryFeesMinor: 0,
              immediateDiscountMinor: 0,
            ),
          ),
        );
        expect(retail.packCount, 4);
        expect(wholesale.packCount, 2);
        expect(retail.suppliedQuantityMilli, 20000);
        expect(wholesale.suppliedQuantityMilli, 20000);
        expect(retail.payableMinor, 124000);
        expect(wholesale.payableMinor, 128000);
        expect(retail.comparableUnitMinor, 6200);
        expect(wholesale.comparableUnitMinor, 6400);
      },
    );
    for (final alternate in [
      identity(specification: 'brand-b:whole-wheat:grade-a'),
      identity(specification: 'brand-a:whole-wheat:grade-b'),
      identity(specification: 'brand-a:rice:grade-a'),
      identity(unit: BuyV2ComparisonUnit.litre),
    ]) {
      test(
        'rejects non-equivalent ${alternate.specificationId}/${alternate.unit.name}',
        () {
          final request = query(samePack: false);
          expect(
            calculate(
              request,
              offer(request, specification: alternate),
            ).unavailable,
            BuyV2ComparisonUnavailable.differentProduct,
          );
        },
      );
    }
    test('canonical product cannot disagree with declared specification', () {
      final request = query();
      expect(
        calculate(
          request,
          offer(request, listing: product.copyWith(canonicalId: 'rice')),
        ).unavailable,
        BuyV2ComparisonUnavailable.differentProduct,
      );
    });
    test('same pack fixes pack identity and normalized contents', () {
      final request = query();
      for (final alternate in [
        identity(pack: 'carton-5kg'),
        identity(size: 10000),
      ]) {
        expect(
          calculate(
            request,
            offer(request, specification: alternate),
          ).unavailable,
          BuyV2ComparisonUnavailable.differentProduct,
        );
      }
    });
    test('MOQ plus increments discloses excess quantity and reached tier', () {
      final request = query(quantity: 20001);
      final value = calculate(
        request,
        offer(
          request,
          minimum: 3,
          increment: 4,
          tiers: const [
            BuyV2ComparisonPriceTier(minimumPacks: 10, packPriceMinor: 22000),
            BuyV2ComparisonPriceTier(minimumPacks: 7, packPriceMinor: 25000),
          ],
        ),
      );
      expect(value.packCount, 7);
      expect(value.suppliedQuantityMilli, 35000);
      expect(value.excessQuantityMilli, 14999);
      expect(value.packPriceMinor, 25000);
      expect(value.itemSubtotalMinor, 175000);
    });
    test('tier boundary changes only at the purchased count', () {
      for (final quantity in [15000, 15001]) {
        final request = query(quantity: quantity);
        final value = calculate(
          request,
          offer(
            request,
            tiers: const [
              BuyV2ComparisonPriceTier(minimumPacks: 4, packPriceMinor: 28000),
            ],
          ),
        );
        expect(value.packPriceMinor, quantity == 15000 ? 30000 : 28000);
      }
    });
    test('minimum order honors requirements smaller than one pack', () {
      final request = query(quantity: 1000);
      final value = calculate(request, offer(request, minimum: 5));
      expect(value.packCount, 5);
      expect(value.excessQuantityMilli, 24000);
    });
    test('fixed minor-unit arithmetic rounds per-unit cost half up', () {
      final request = query(
        quantity: 2000,
        specification: identity(size: 2000),
      );
      final value = calculate(
        request,
        offer(request, specification: identity(size: 2000), price: 101),
      );
      expect(value.payableMinor, 101);
      expect(value.comparableUnitMinor, 51);
    });
    test('large wholesale amounts remain exact', () {
      final request = query(quantity: 5000000);
      final value = calculate(
        request,
        offer(request, stock: 1000, price: 98765432),
      );
      expect(value.packCount, 1000);
      expect(value.payableMinor, 98765432000);
      expect(value.comparableUnitMinor, 19753086);
    });
    test('arithmetic rejects common integer precision overflow', () {
      final request = query(quantity: 10000);
      expect(
        calculate(request, offer(request, price: 9007199254740991)).unavailable,
        BuyV2ComparisonUnavailable.invalidTerms,
      );
    });
    test('unknown charges retain goods quote without a final payable', () {
      final request = query();
      for (final charges in [
        const BuyV2ComparisonCharges(),
        const BuyV2ComparisonCharges(
          taxMinor: 0,
          mandatoryFeesMinor: 0,
          immediateDiscountMinor: 0,
        ),
        const BuyV2ComparisonCharges(
          taxMinor: 0,
          freightMinor: 0,
          mandatoryFeesMinor: 0,
        ),
      ]) {
        final value = calculate(request, offer(request, charges: charges));
        expect(value.available, isTrue);
        expect(value.itemSubtotalMinor, 120000);
        expect(value.payableMinor, isNull);
        expect(value.comparableUnitMinor, isNull);
      }
    });
    test('disclosed charges and immediate discount determine payable', () {
      final request = query();
      final value = calculate(
        request,
        offer(
          request,
          charges: const BuyV2ComparisonCharges(
            taxMinor: 6000,
            freightMinor: 4000,
            mandatoryFeesMinor: 300,
            immediateDiscountMinor: 2000,
          ),
        ),
      );
      expect(value.payableMinor, 128300);
    });
    test('discount cannot yield negative payable', () {
      final request = query();
      expect(
        calculate(
          request,
          offer(
            request,
            charges: const BuyV2ComparisonCharges(
              taxMinor: 0,
              freightMinor: 0,
              mandatoryFeesMinor: 0,
              immediateDiscountMinor: 120001,
            ),
          ),
        ).unavailable,
        BuyV2ComparisonUnavailable.invalidTerms,
      );
    });
    final invalidOffers =
        <String, BuyV2ComparisonOffer Function(BuyV2ComparisonQuery)>{
          'blank workspace': (q) => offer(q, workspace: ''),
          'store mismatch': (q) => offer(q, store: 'other-store'),
          'missing revision': (q) => offer(q, revision: ''),
          'missing origin': (q) => offer(q, origin: ''),
          'zero MOQ': (q) => offer(q, minimum: 0),
          'zero increment': (q) => offer(q, increment: 0),
          'negative stock': (q) => offer(q, stock: -1),
          'negative price': (q) => offer(q, price: -1),
          'future observation': (q) => offer(q, observed: expiry),
          'negative charge': (q) =>
              offer(q, charges: const BuyV2ComparisonCharges(freightMinor: -1)),
          'duplicate tiers': (q) => offer(
            q,
            tiers: const [
              BuyV2ComparisonPriceTier(minimumPacks: 2, packPriceMinor: 2),
              BuyV2ComparisonPriceTier(minimumPacks: 2, packPriceMinor: 1),
            ],
          ),
          'bad tier': (q) => offer(
            q,
            tiers: const [
              BuyV2ComparisonPriceTier(minimumPacks: 0, packPriceMinor: 1),
            ],
          ),
          'partial arrival': (q) => offer(q, arrivalEnd: expiry),
          'reversed arrival': (q) => offer(
            q,
            arrivalStart: expiry,
            arrivalEnd: now.add(const Duration(minutes: 5)),
          ),
        };
    for (final entry in invalidOffers.entries) {
      test('invalid terms: ${entry.key}', () {
        final request = query();
        expect(
          calculate(request, entry.value(request)).unavailable,
          BuyV2ComparisonUnavailable.invalidTerms,
        );
      });
    }
    test('serviceability, approval, stock and expiry fail closed', () {
      final request = query();
      final cases = [
        (
          offer(request, serviceable: false),
          BuyV2ComparisonUnavailable.unserviceable,
        ),
        (
          offer(request, eligible: false),
          BuyV2ComparisonUnavailable.customerIneligible,
        ),
        (
          offer(request, stock: 3),
          BuyV2ComparisonUnavailable.insufficientStock,
        ),
        (
          offer(
            request,
            observed: now.subtract(const Duration(minutes: 5)),
            until: now,
          ),
          BuyV2ComparisonUnavailable.expired,
        ),
      ];
      for (final (value, reason) in cases) {
        expect(calculate(request, value).unavailable, reason);
      }
    });
    test('local, channel and fulfilment filters remain independent', () {
      final local = query(scope: BuyV2ComparisonScope.local);
      final retail = query(channel: BuyV2ComparisonChannel.retail);
      final quick = query(fulfilment: BuyV2FulfilmentMode.quickLocal);
      for (final (request, value) in [
        (local, offer(local, local: false)),
        (retail, offer(retail, channel: BuyV2ComparisonChannel.wholesale)),
        (quick, offer(quick, fulfilment: BuyV2FulfilmentMode.standardCourier)),
      ]) {
        expect(
          calculate(request, value).unavailable,
          BuyV2ComparisonUnavailable.filtered,
        );
      }
    });
    test('unknown or late arrival fails a requested deadline', () {
      final request = query();
      expect(calculate(request, offer(request)).arrivalEnd, isNull);
      final deadline = query(deadline: now.add(const Duration(hours: 2)));
      expect(
        calculate(deadline, offer(deadline)).unavailable,
        BuyV2ComparisonUnavailable.arrivalUnavailable,
      );
      expect(
        calculate(
          deadline,
          offer(
            deadline,
            arrivalStart: now.add(const Duration(hours: 1)),
            arrivalEnd: now.add(const Duration(hours: 3)),
          ),
        ).unavailable,
        BuyV2ComparisonUnavailable.arrivalUnavailable,
      );
    });
    test('arrival window in progress remains valid', () {
      final request = query();
      expect(
        calculate(
          request,
          offer(
            request,
            observed: now.subtract(const Duration(minutes: 10)),
            arrivalStart: now.subtract(const Duration(minutes: 5)),
            arrivalEnd: now.add(const Duration(minutes: 5)),
          ),
        ).available,
        isTrue,
      );
    });
    test(
      'query binds purchaser, destination revision, quantity and filters',
      () {
        final original = query();
        for (final changed in [
          query(account: 'buyer-b'),
          query(destination: 'address-a:revision-2'),
          query(pin: '560001'),
          query(quantity: 20001),
          query(samePack: false),
          query(channel: BuyV2ComparisonChannel.wholesale),
          query(sort: BuyV2ComparisonSort.arrival),
          query(
            procurement: const BuyV2ProcurementContext(
              accountId: 'buyer-a',
              storeId: 'retailer-a',
              purpose: BuyV2ProcurementPurpose.restock,
              originOperationId: 'op-a',
            ),
          ),
        ]) {
          expect(changed.key, isNot(original.key));
          expect(
            calculate(changed, offer(original)).unavailable,
            BuyV2ComparisonUnavailable.wrongQuery,
          );
        }
      },
    );
    test('count quantities exclude fractional items and invalid PINs', () {
      for (final invalid in [
        query(quantity: 0),
        query(quantity: -1),
        query(pin: '000000'),
        query(pin: '56000'),
        query(
          specification: identity(unit: BuyV2ComparisonUnit.count, size: 1500),
        ),
        query(
          specification: identity(unit: BuyV2ComparisonUnit.count),
          quantity: 1500,
        ),
      ]) {
        expect(invalid.valid, isFalse);
      }
    });
    test('unbranded products require a published commodity specification', () {
      expect(query(specification: identity(specification: '')).valid, isFalse);
      expect(
        query(
          specification: identity(
            specification: 'unbranded:wheat:sharbati:grade-a',
          ),
        ).valid,
        isTrue,
      );
    });
    test('page binds the snapshot and copies its immutable offers', () {
      final request = query();
      final rows = [offer(request)];
      final value = page(request, rows, next: 'page-2');
      rows.clear();
      expect(value.offers, hasLength(1));
      expect(
        value.validFor(BuyV2ComparisonPageRequest(query: request), now),
        isTrue,
      );
      expect(() => value.offers.clear(), throwsUnsupportedError);
    });
    test(
      'page rejects duplicates, mixed snapshots, foreign queries and expiry',
      () {
        final request = query();
        final first = offer(request);
        for (final value in [
          page(request, [first, first]),
          page(request, [offer(request, snapshot: 'other-snapshot')]),
          page(request, [first], key: query(account: 'buyer-b').key),
          page(request, [first], until: now),
          page(request, [
            offer(request, observed: now.subtract(const Duration(seconds: 1))),
          ]),
        ]) {
          expect(
            value.validFor(BuyV2ComparisonPageRequest(query: request), now),
            isFalse,
          );
        }
      },
    );
    test('continuation requires exact snapshot and non-repeating cursor', () {
      final request = query();
      expect(
        BuyV2ComparisonPageRequest(query: request, cursor: '2').valid,
        isFalse,
      );
      final continuation = BuyV2ComparisonPageRequest(
        query: request,
        snapshotId: 'snapshot-a',
        cursor: '2',
      );
      expect(
        page(request, [offer(request)], next: '2').validFor(continuation, now),
        isFalse,
      );
      expect(
        page(request, [
          offer(request),
        ], snapshot: 'snapshot-b').validFor(continuation, now),
        isFalse,
      );
      expect(
        page(request, [offer(request)], next: '3').validFor(continuation, now),
        isTrue,
      );
    });
    test('partial ranking or missing facts cannot earn winner badges', () {
      final request = query();
      final incomplete = offer(
        request,
        charges: const BuyV2ComparisonCharges(),
      );
      final complete = offer(
        request,
        arrivalStart: now,
        arrivalEnd: now.add(const Duration(hours: 1)),
      );
      final incompletePage = page(
        request,
        [incomplete],
        cheapest: incomplete.id,
        fastest: incomplete.id,
      );
      expect(
        incompletePage.isLowestDelivered(
          incomplete,
          calculate(request, incomplete),
        ),
        isFalse,
      );
      expect(
        incompletePage.isEarliestArrival(
          incomplete,
          calculate(request, incomplete),
        ),
        isFalse,
      );
      final partial = page(
        request,
        [complete],
        ranked: false,
        cheapest: complete.id,
        fastest: complete.id,
      );
      expect(
        partial.isLowestDelivered(complete, calculate(request, complete)),
        isFalse,
      );
      expect(
        partial.isEarliestArrival(complete, calculate(request, complete)),
        isFalse,
      );
      final ranked = page(
        request,
        [complete],
        cheapest: complete.id,
        fastest: complete.id,
      );
      expect(
        ranked.isLowestDelivered(complete, calculate(request, complete)),
        isTrue,
      );
      expect(
        ranked.isEarliestArrival(complete, calculate(request, complete)),
        isTrue,
      );
    });
  });
}

final class _R669ComparisonSource implements BuyV2ComparisonSource {
  _R669ComparisonSource(this.identity, this.loader);
  final BuyV2ComparisonIdentity identity;
  final Future<BuyV2ComparisonPage> Function(BuyV2ComparisonPageRequest) loader;
  @override
  BuyV2ComparisonIdentity? identityFor(BuyV2Product product) => identity;
  @override
  Future<BuyV2ComparisonPage> load(BuyV2ComparisonPageRequest request) =>
      loader(request);
}
