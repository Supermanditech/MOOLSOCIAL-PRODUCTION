import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_order_resolution_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

class _R669TrackingOwnerStore implements BuyV2CustomerStateStore {
  @override
  String? ownerScope = 'tracking-owner-a';
  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => null;
  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async => true;
}

class _R669DeliveryCommerce implements BuyV2CommerceAdapter {
  _R669DeliveryCommerce() {
    final quick = BuyV2Catalogue.products.firstWhere((p) => p.id == 's-tomato');
    final scheduled = BuyV2Catalogue.products.firstWhere(
      (p) =>
          p.destination == BuyV2Destination.shop &&
          buyV2CatalogueFulfilmentModeFor(p) ==
              BuyV2FulfilmentMode.standardCourier,
    );
    final wholesale = BuyV2Catalogue.products.firstWhere(
      (p) => p.destination == BuyV2Destination.wholesale,
    );
    final bulk = BuyV2Catalogue.products.firstWhere((p) => p.id == 'w-rice');
    records = [
      make('quick-1', quick, 'Work', 'Delivery in 15 min'),
      make('scheduled-2', scheduled, 'Home', 'Delivery tomorrow'),
      make('wholesale-3', wholesale, 'Warehouse', 'Delivery in 2 days'),
      make('bulk-4', bulk, 'Warehouse receiving bay', 'Delivery in 4 days'),
    ];
  }
  late List<BuyV2Order> records;
  BuyV2CommerceLoadState state = BuyV2CommerceLoadState.ready;
  BuyV2Order make(
    String id,
    BuyV2Product product,
    String destination,
    String promise, {
    BuyV2OrderStatus status = BuyV2OrderStatus.preparing,
  }) => BuyV2Order(
    id: id,
    destination: product.destination,
    title: product.title,
    itemSummary: product.title,
    total: product.price * product.minimumOrder,
    partner: product.seller,
    partnerType: 'Supplier',
    promise: promise,
    destinationLabel: destination,
    progress: status == BuyV2OrderStatus.delivered ? 1 : .4,
    status: status,
    purchaseId: product.destination == BuyV2Destination.wholesale
        ? 'purchase-bulk'
        : 'purchase-split',
    lines: [BuyV2CartLine(product: product, quantity: product.minimumOrder)],
    productIds: [product.id],
  );
  void advance(String id, BuyV2OrderStatus status) {
    records = [
      for (final order in records)
        if (order.id == id)
          make(
            order.id,
            order.lines.single.product,
            order.destinationLabel,
            order.promise,
            status: status,
          )
        else
          order,
    ];
  }

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: state,
    products: BuyV2Catalogue.products,
    orders: records,
    businessVerified: true,
    businessVerificationState: BuyV2BusinessVerificationState.verified,
  );
  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: true,
        enabled: false,
        customerMessage: '',
      );
  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({
    required String orderId,
  }) async => BuyV2OrderRefreshResult(
    state: state,
    customerMessage: state == BuyV2CommerceLoadState.ready
        ? ''
        : 'Tracking could not refresh.',
    order: records.where((o) => o.id == orderId).firstOrNull,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

// Host-only connected journey fixture. Never supplied to native/live commerce.
class _T14ConnectedJourneyCommerce extends _R669DeliveryCommerce {
  _T14ConnectedJourneyCommerce() {
    records = [];
  }
  String readyMessage = '';

  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({
    required String orderId,
  }) async {
    final result = await super.refreshOrder(orderId: orderId);
    return BuyV2OrderRefreshResult(
      state: result.state,
      order: result.order,
      customerMessage: result.state == BuyV2CommerceLoadState.ready
          ? readyMessage
          : result.customerMessage,
    );
  }

  void advanceConfirmed(BuyV2Order original, BuyV2OrderStatus next) {
    records = [
      for (final order in records)
        if (order.id == original.id)
          BuyV2Order(
            id: original.id,
            destination: original.destination,
            title: original.title,
            itemSummary: original.itemSummary,
            total: original.total,
            totalMinor: original.totalMinor,
            partner: original.partner,
            partnerType: original.partnerType,
            promise: next == BuyV2OrderStatus.delivered
                ? 'Delivered'
                : original.promise,
            destinationLabel: original.destinationLabel,
            progress: next == BuyV2OrderStatus.delivered ? 1 : .85,
            status: next,
            collection: original.collection,
            purchaseId: original.purchaseId,
            promisedByLabel: original.promisedByLabel,
            updatedDeliveryEstimate: original.updatedDeliveryEstimate,
            productIds: original.productIds,
            lines: original.lines,
            paymentMethod: original.paymentMethod,
            purchaseOrderReference: original.purchaseOrderReference,
            recipient: original.recipient,
            addressLine: original.addressLine,
            deliveryInstruction: original.deliveryInstruction,
            tip: original.tip,
            discount: original.discount,
            paymentTermLabel: original.paymentTermLabel,
            amountPaidNow: original.amountPaidNow,
            balanceDue: original.balanceDue,
            balanceDueLabel: original.balanceDueLabel,
            paymentStatusLabel: original.paymentStatusLabel,
            buyerName: original.buyerName,
            buyerType: original.buyerType,
            tax: original.tax,
            freight: original.freight,
            deliveryFee: original.deliveryFee,
            paymentCharge: original.paymentCharge,
            dispatchPromise: original.dispatchPromise,
            deliveryPartnerName: original.deliveryPartnerName,
            deliveryPartnerType: original.deliveryPartnerType,
            trackingReference: original.trackingReference,
            deliveryServiceLevel: original.deliveryServiceLevel,
            proofOfDeliveryStatus: original.proofOfDeliveryStatus,
            taxInvoiceState: original.taxInvoiceState,
            taxInvoiceDetails: original.taxInvoiceDetails,
            platformTaxInvoiceDetails: original.platformTaxInvoiceDetails,
            invoiceAvailable: original.invoiceAvailable,
            receiptReference: original.receiptReference,
            supplyProgress: original.supplyProgress,
          )
        else
          order,
    ];
  }
}

class _TrackingEligibleCommerce extends _R669DeliveryCommerce {
  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: state,
    products: [
      for (final product in BuyV2Catalogue.products)
        product.copyWith(storeId: 'tracking-test-store'),
    ],
    orders: records,
    businessVerified: true,
    businessVerificationState: BuyV2BusinessVerificationState.verified,
  );
}

class _TrackingEligibleFacts implements BuyV2ProductFactsAdapter {
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final now = DateTime.now();
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          eligibility: BuyV2OfferEligibility(
            productId: product.id,
            storeId: product.storeId!,
            sourceRevision: 'tracking-navigation-test-v1',
            customerLocationKey: '||0',
            observedAt: now.subtract(const Duration(seconds: 1)),
            expiresAt: now.add(const Duration(minutes: 5)),
            offerClass: product.offerClass!,
            channelEnabled: true,
            storeReady: true,
            fleetAvailable: false,
            customerLocationConfirmed: true,
            options: {BuyV2DeliveryOption.freight},
          ),
        );
  }
}

class _R669PendingDeliveryCommerce extends _R669DeliveryCommerce {
  Completer<BuyV2OrderRefreshResult>? pending;
  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({required String orderId}) =>
      pending?.future ?? super.refreshOrder(orderId: orderId);
}

class _R669DeliveryIconFacts implements BuyV2ProductFactsAdapter {
  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final facts = const BuyV2CatalogueProductFactsAdapter().snapshotFor(
      product,
    );
    return product.destination == BuyV2Destination.wholesale ||
            product.destination == BuyV2Destination.medicine
        ? facts.copyWith(
            deliveryPromise: 'Delivery in 2 days',
            sourceId: 'delivery-icon-test-fixture',
          )
        : facts;
  }
}

class _R5ArrivalSound implements BuyV2DeliveryArrivalSound {
  int preparations = 0;
  int plays = 0;
  int stops = 0;
  int disposals = 0;
  bool ready = true;
  bool playable = true;
  Completer<bool>? preparation;
  Completer<bool>? playback;

  @override
  Future<bool> prepare() async {
    preparations++;
    return preparation == null ? ready : preparation!.future;
  }

  @override
  Future<bool> play() async {
    plays++;
    return playback == null ? playable : playback!.future;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

class _R5CuePlayer implements AudioPlayer {
  int plays = 0;
  int disposals = 0;
  String? loadedPath;
  List<int>? wave;
  Completer<Duration?>? loadGate;
  final loaded = Completer<void>();
  bool failPlayback = false;
  ProcessingState state = ProcessingState.idle;

  @override
  ProcessingState get processingState => state;

  @override
  Future<Duration?> setFilePath(
    String filePath, {
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    loadedPath = filePath;
    wave = await File(filePath).readAsBytes();
    loaded.complete();
    final gate = loadGate;
    if (gate != null) await gate.future;
    state = ProcessingState.ready;
    return const Duration(milliseconds: 400);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {}

  @override
  Future<void> play() async {
    plays++;
    if (failPlayback) throw StateError('Audio device unavailable');
    state = ProcessingState.completed;
  }

  @override
  Future<void> dispose() async {
    disposals++;
    state = ProcessingState.idle;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _R66TrackingSession extends BuyV2Session {
  _R66TrackingSession({required super.core, required this.order});
  BuyV2Order order;

  void updateOrder(BuyV2Order value) {
    order = value;
    notifyListeners();
  }

  @override
  List<BuyV2Order> get orders => [order];

  // This tracking double represents an explicitly current provider order.
  // Retained review seeds in a normal session are not delivery confirmation.
  @override
  List<BuyV2Order> get activeDeliveryOrders =>
      order.collection == null &&
          order.destination != BuyV2Destination.medicine &&
          order.status != BuyV2OrderStatus.delivered
      ? [order]
      : const [];

  @override
  List<BuyV2Order> get visibleOrders {
    final completed = order.status == BuyV2OrderStatus.delivered;
    final showCompleted = ordersTab == BuyV2OrdersTab.delivered;
    final normalizedQuery = query.trim().toLowerCase();
    if (order.destination == BuyV2Destination.medicine ||
        completed != showCompleted ||
        (destination == BuyV2Destination.orders &&
            normalizedQuery.isNotEmpty &&
            ![
              order.id,
              order.title,
              order.partner,
              order.partnerType,
              order.itemSummary,
            ].any((value) => value.toLowerCase().contains(normalizedQuery)))) {
      return const [];
    }
    return orders;
  }

  @override
  int get activeOrderCount =>
      order.destination != BuyV2Destination.medicine &&
          order.status != BuyV2OrderStatus.delivered
      ? 1
      : 0;

  @override
  int get deliveredOrderCount =>
      order.destination != BuyV2Destination.medicine &&
          order.status == BuyV2OrderStatus.delivered
      ? 1
      : 0;

  @override
  BuyV2Order get selectedOrderOrNull => order;

  @override
  BuyV2Order? get activeQuickDeliveryOrder =>
      order.destination == BuyV2Destination.shop &&
          order.status != BuyV2OrderStatus.delivered
      ? order
      : null;
}

BuyV2Order _r66Order(BuyV2OrderStatus status, BuyV2Destination destination) =>
    BuyV2Order(
      id: destination == BuyV2Destination.shop ? 'MS-240782' : 'PO-240783',
      destination: destination,
      title: '${destination.label} order',
      itemSummary: '1 product',
      total: 74,
      partner: 'Shree Balaji Fresh and Provisions',
      partnerType: 'Retailer',
      promise: 'Delivered in 12 min',
      promisedByLabel: 'by 6:35 PM',
      destinationLabel: 'Sardarpura, Jodhpur · 342003',
      progress: switch (status) {
        BuyV2OrderStatus.confirmed => .1,
        BuyV2OrderStatus.preparing => .4,
        BuyV2OrderStatus.dispatched => .7,
        BuyV2OrderStatus.arriving => .9,
        BuyV2OrderStatus.delivered => 1,
      },
      status: status,
      deliveryPartnerName:
          status == BuyV2OrderStatus.dispatched ||
              status == BuyV2OrderStatus.arriving
          ? 'Assigned delivery partner'
          : null,
    );

class _T11DeferredOrderRefreshCommerce extends _R669DeliveryCommerce {
  final pending = <Completer<BuyV2OrderRefreshResult>>[];

  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({required String orderId}) {
    final request = Completer<BuyV2OrderRefreshResult>();
    pending.add(request);
    return request.future;
  }

  void finish(int request, BuyV2Order order) => pending[request].complete(
    BuyV2OrderRefreshResult(
      state: BuyV2CommerceLoadState.ready,
      customerMessage: '',
      order: order,
    ),
  );

  BuyV2Order changed(BuyV2Order order, BuyV2OrderStatus status) => make(
    order.id,
    order.lines.single.product,
    order.destinationLabel,
    order.promise,
    status: status,
  );
}

class _T12SupplyCommerce extends _R669DeliveryCommerce {
  _T12SupplyCommerce() {
    records = [orderWith(null)];
  }
  BuyV2OrderStatus status = BuyV2OrderStatus.preparing;
  BuyV2Order orderWith(BuyV2OrderSupplyProgress? progress, {int total = 90}) {
    final product = BuyV2Catalogue.products.firstWhere(
      (p) => p.id == 's-tomato',
    );
    return BuyV2Order(
      id: 'supply-1',
      purchaseId: 'purchase-1',
      destination: BuyV2Destination.shop,
      title: product.customerTitle,
      itemSummary: '1 product · 3 items',
      total: total,
      amountPaidNow: 90,
      partner: 'Store A',
      partnerType: 'Store',
      promise: 'Delivery tomorrow',
      destinationLabel: 'Home',
      progress: status == BuyV2OrderStatus.delivered ? 1 : .4,
      status: status,
      productIds: [product.id],
      lines: [BuyV2CartLine(product: product, quantity: 3)],
      supplyProgress: progress,
    );
  }

  void supply(BuyV2OrderSupplyProgress? progress, {int total = 90}) {
    records = [orderWith(progress, total: total)];
  }
}

BuyV2OrderSupplyProgress _t12Progress({
  String orderId = 'supply-1',
  String purchaseId = 'purchase-1',
  String source = 'store-service',
  int revision = 1,
  int available = 1,
  int unavailable = 2,
  int ordered = 3,
  String? supplier = 'Store A',
  String currency = 'INR',
  BuyV2SupplyState state = BuyV2SupplyState.replacementOffered,
  String title = 'Fresh replacement tomatoes',
  int quantity = 2,
  int price = 3000,
  int originalQuantity = 2,
  int total = 9000,
  DateTime? expiresAt,
  BuyV2SupplyRefundState? refund,
  int? refundAmount,
  String? route,
  String? reference,
}) {
  final p = BuyV2Catalogue.products.firstWhere((p) => p.id == 's-tomato');
  return BuyV2OrderSupplyProgress(
    orderId: orderId,
    purchaseId: purchaseId,
    sourceId: source,
    revision: revision,
    currency: currency,
    state: state,
    lines: [
      BuyV2SupplyLine(
        productId: p.id,
        variant: p.variant,
        pack: p.pack,
        orderedQuantity: ordered,
        availableQuantity: available,
        unavailableQuantity: unavailable,
        supplierId: 'store-a',
        supplierName: supplier,
      ),
    ],
    replacementOffer: state != BuyV2SupplyState.replacementOffered
        ? null
        : BuyV2ReplacementOffer(
            id: 'offer-1',
            revision: 1,
            lines: [
              BuyV2ReplacementLine(
                originalProductId: p.id,
                originalVariant: p.variant,
                originalPack: p.pack,
                originalQuantity: originalQuantity,
                productTitle: title,
                pack: '1 kg',
                quantity: quantity,
                unitPriceMinor: price,
              ),
            ],
            customerTotalMinor: total,
            deliveryCommitment: 'Delivery tomorrow by 6 pm',
            expiresAt: expiresAt ?? DateTime.utc(2099),
          ),
    refundState: refund,
    refundAmountMinor: refundAmount,
    refundRoute: route,
    refundReference: reference,
  );
}

class _T12ConsentAdapter
    implements BuyV2OrderResolutionAdapter, BuyV2ReplacementConsentAdapter {
  final requests = <BuyV2ReplacementConsentRequest>[];
  Future<BuyV2ReplacementConsentResult> Function(
    BuyV2ReplacementConsentRequest,
  )?
  respond;
  @override
  Future<BuyV2ReplacementConsentResult> decideReplacement(
    BuyV2ReplacementConsentRequest r,
  ) async {
    requests.add(r);
    return respond == null
        ? BuyV2ReplacementConsentResult(
            request: r,
            recorded: true,
            reference: 'choice-1',
          )
        : await respond!(r);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final _t12CaptureRun = DateTime.now().microsecondsSinceEpoch;

Future<void> _t12Capture(
  WidgetTester tester,
  String name,
  String boundaryKey,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(ValueKey(boundaryKey)),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File(
      'build/t06-t07-cart-20261002/t12-visual-$_t12CaptureRun/$name.png',
    );
    await file.parent.create(recursive: true);
    expect(await file.exists(), isFalse);
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
}

void _t12SupplyCases() {
  Future<
    ({
      BuyV2Session session,
      _T12SupplyCommerce commerce,
      _T12ConsentAdapter adapter,
      _R669TrackingOwnerStore store,
      ValueNotifier<BuyV2CollectionIdentity?> identity,
      VoidCallback dispose,
    })
  >
  fixture({bool capability = true}) async {
    final core = BuySession();
    final commerce = _T12SupplyCommerce();
    final adapter = _T12ConsentAdapter();
    final store = _R669TrackingOwnerStore();
    final identity = ValueNotifier<BuyV2CollectionIdentity?>(
      const BuyV2CollectionIdentity(accountId: 'buyer-a', sessionId: 'a'),
    );
    final session = BuyV2Session(
      core: core,
      commerceAdapter: commerce,
      orderResolutionAdapter: capability
          ? adapter
          : const BuyV2UnavailableOrderResolutionAdapter(),
      customerStateStore: store,
      collectionIdentity: identity,
      reviewDataEnabled: false,
    );
    var disposed = false;
    void dispose() {
      if (disposed) return;
      disposed = true;
      session.dispose();
      identity.dispose();
      core.dispose();
    }

    addTearDown(dispose);
    await session.restoreCommerce();
    commerce.supply(_t12Progress());
    expect(await session.refreshOrder('supply-1'), isTrue);
    return (
      session: session,
      commerce: commerce,
      adapter: adapter,
      store: store,
      identity: identity,
      dispose: dispose,
    );
  }

  final invalid = <String, BuyV2OrderSupplyProgress>{
    'wrong order': _t12Progress(orderId: 'other'),
    'wrong purchase': _t12Progress(purchaseId: 'other'),
    'missing source': _t12Progress(source: ''),
    'invalid revision': _t12Progress(revision: 0),
    'wrong currency': _t12Progress(currency: 'USD'),
    'excess allocation': _t12Progress(available: 2, unavailable: 2),
    'negative allocation': _t12Progress(available: -1),
    'wrong ordered quantity': _t12Progress(ordered: 4),
    'missing supplier': _t12Progress(supplier: null),
    'replacement exceeds unavailable': _t12Progress(originalQuantity: 3),
    'empty replacement': _t12Progress(title: ''),
    'zero replacement quantity': _t12Progress(quantity: 0),
    'negative replacement price': _t12Progress(price: -1),
    'changed customer total': _t12Progress(total: 9500),
    'incomplete ready': _t12Progress(state: BuyV2SupplyState.ready),
    'false unavailable': _t12Progress(state: BuyV2SupplyState.unavailable),
    'refund missing route': _t12Progress(
      refund: BuyV2SupplyRefundState.processing,
      refundAmount: 6000,
    ),
    'refund exceeds payment': _t12Progress(
      refund: BuyV2SupplyRefundState.refunded,
      refundAmount: 9500,
      route: 'UPI',
      reference: 'refund-1',
    ),
    'refund missing reference': _t12Progress(
      refund: BuyV2SupplyRefundState.refunded,
      refundAmount: 6000,
      route: 'UPI',
    ),
  };
  for (final entry in invalid.entries) {
    test('T12 supply rejects ${entry.key}', () {
      expect(
        entry.value.matchesOrder(_T12SupplyCommerce().records.single),
        isFalse,
      );
    });
  }
  test('T12 supply keeps unknown quantities pending and refund exact', () {
    final order = _T12SupplyCommerce().records.single;
    final partial = _t12Progress(
      state: BuyV2SupplyState.partiallyAvailable,
      available: 1,
      unavailable: 1,
      refund: BuyV2SupplyRefundState.processing,
      refundAmount: 3000,
      route: 'UPI',
    );
    expect(partial.matchesOrder(order), isTrue);
    expect(partial.lines.single.awaitingQuantity, 1);
    expect(() => partial.lines.clear(), throwsUnsupportedError);
    expect(
      _t12Progress(
        refund: BuyV2SupplyRefundState.refunded,
        refundAmount: 6000,
        route: 'UPI',
        reference: 'refund-1',
      ).matchesOrder(order),
      isTrue,
    );
  });
  test(
    'T12 replacement receipt preserves original order and prevents duplicates',
    () async {
      final f = await fixture();
      final key = buyV2ReplacementReviewKey(
        f.session.orderSupplyProgressFor('supply-1')!,
      );
      expect(
        await f.session.decideOrderReplacement(
          orderId: 'supply-1',
          reviewedKey: key,
          reviewedScopeKey: f.session.replacementReviewScopeKey,
          accept: true,
        ),
        isTrue,
      );
      final order = f.session.orders.single;
      expect(order.total, 90);
      expect(order.lines.single.product.id, 's-tomato');
      expect(order.status, BuyV2OrderStatus.preparing);
      expect(f.session.replacementConsentResult('supply-1')?.recorded, isTrue);
      expect(
        await f.session.decideOrderReplacement(
          orderId: 'supply-1',
          reviewedKey: key,
          reviewedScopeKey: f.session.replacementReviewScopeKey,
          accept: false,
        ),
        isFalse,
      );
      expect(f.adapter.requests, hasLength(1));
    },
  );
  for (final changed in ['contents', 'expiry', 'total', 'capability']) {
    test('T12 replacement rejects changed $changed', () async {
      final f = await fixture(capability: changed != 'capability');
      final key = buyV2ReplacementReviewKey(
        f.session.orderSupplyProgressFor('supply-1')!,
      );
      if (changed == 'contents') {
        f.commerce.supply(_t12Progress(title: 'A different product'));
      }
      if (changed == 'expiry') {
        f.commerce.supply(_t12Progress(expiresAt: DateTime.utc(2020)));
      }
      if (changed == 'total') {
        f.commerce.supply(_t12Progress(total: 9500), total: 95);
      }
      expect(
        await f.session.decideOrderReplacement(
          orderId: 'supply-1',
          reviewedKey: key,
          reviewedScopeKey: f.session.replacementReviewScopeKey,
          accept: true,
        ),
        isFalse,
      );
      expect(f.adapter.requests, isEmpty);
    });
  }
  test('T12 replacement unknown retry reuses decision identity', () async {
    final f = await fixture();
    final key = buyV2ReplacementReviewKey(
      f.session.orderSupplyProgressFor('supply-1')!,
    );
    f.adapter.respond = (_) async =>
        throw StateError('Connection lost after request');
    expect(
      await f.session.decideOrderReplacement(
        orderId: 'supply-1',
        reviewedKey: key,
        reviewedScopeKey: f.session.replacementReviewScopeKey,
        accept: true,
      ),
      isFalse,
    );
    expect(
      await f.session.decideOrderReplacement(
        orderId: 'supply-1',
        reviewedKey: key,
        reviewedScopeKey: f.session.replacementReviewScopeKey,
        accept: false,
      ),
      isFalse,
    );
    f.adapter.respond = (r) async => BuyV2ReplacementConsentResult(
      request: r,
      recorded: true,
      reference: 'choice-1',
    );
    expect(
      await f.session.decideOrderReplacement(
        orderId: 'supply-1',
        reviewedKey: key,
        reviewedScopeKey: f.session.replacementReviewScopeKey,
        accept: true,
      ),
      isTrue,
    );
    expect(f.adapter.requests, hasLength(2));
    expect(
      f.adapter.requests.first.idempotencyKey,
      f.adapter.requests.last.idempotencyKey,
    );
  });
  for (final stale in [
    'buyer',
    'disposal',
    'new offer',
    'mismatched receipt',
  ]) {
    test('T12 replacement ignores $stale response', () async {
      final f = await fixture();
      final pending = Completer<BuyV2ReplacementConsentResult>();
      final key = buyV2ReplacementReviewKey(
        f.session.orderSupplyProgressFor('supply-1')!,
      );
      f.adapter.respond = (_) => pending.future;
      final flight = f.session.decideOrderReplacement(
        orderId: 'supply-1',
        reviewedKey: key,
        reviewedScopeKey: f.session.replacementReviewScopeKey,
        accept: true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(f.adapter.requests, hasLength(1));
      expect(
        await f.session.decideOrderReplacement(
          orderId: 'supply-1',
          reviewedKey: key,
          reviewedScopeKey: f.session.replacementReviewScopeKey,
          accept: true,
        ),
        isFalse,
      );
      if (stale == 'buyer') {
        f.identity.value = const BuyV2CollectionIdentity(
          accountId: 'buyer-b',
          sessionId: 'b',
        );
        f.identity.value = const BuyV2CollectionIdentity(
          accountId: 'buyer-a',
          sessionId: 'a',
        );
      }
      if (stale == 'disposal') f.dispose();
      if (stale == 'new offer') {
        f.commerce.supply(
          _t12Progress(title: 'Updated replacement', revision: 2),
        );
        await f.session.refreshOrder('supply-1');
      }
      final r = f.adapter.requests.single;
      pending.complete(
        BuyV2ReplacementConsentResult(
          request: r,
          recorded: true,
          reference: stale == 'mismatched receipt' ? '' : 'choice-1',
        ),
      );
      expect(await flight, isFalse);
      expect(f.session.replacementConsentResult('supply-1'), isNull);
    });
  }
  for (final path in ['order', 'commerce']) {
    for (final change in ['older revision', 'reused version']) {
      test('T12 supply $path rejects $change', () async {
        final f = await fixture();
        f.commerce.supply(_t12Progress(revision: 2));
        expect(await f.session.refreshOrder('supply-1'), isTrue);
        f.commerce.supply(
          change == 'older revision'
              ? _t12Progress()
              : _t12Progress(revision: 2, title: 'Changed without version'),
        );
        if (path == 'order') {
          expect(await f.session.refreshOrder('supply-1'), isFalse);
        } else {
          await f.session.restoreCommerce();
          expect(
            f.session.commerceLoadState,
            BuyV2CommerceLoadState.unavailable,
          );
        }
        expect(f.session.orderSupplyProgressFor('supply-1')!.revision, 2);
        expect(
          f.session
              .orderSupplyProgressFor('supply-1')!
              .replacementOffer!
              .lines
              .single
              .productTitle,
          'Fresh replacement tomatoes',
        );
      });
    }
  }
  test(
    'T12 replacement later reviewed offer releases acknowledged choice',
    () async {
      final f = await fixture();
      var key = buyV2ReplacementReviewKey(
        f.session.orderSupplyProgressFor('supply-1')!,
      );
      expect(
        await f.session.decideOrderReplacement(
          orderId: 'supply-1',
          reviewedKey: key,
          reviewedScopeKey: f.session.replacementReviewScopeKey,
          accept: false,
        ),
        isTrue,
      );
      f.commerce.supply(
        _t12Progress(revision: 2, title: 'A later replacement'),
      );
      expect(await f.session.refreshOrder('supply-1'), isTrue);
      key = buyV2ReplacementReviewKey(
        f.session.orderSupplyProgressFor('supply-1')!,
      );
      expect(
        await f.session.decideOrderReplacement(
          orderId: 'supply-1',
          reviewedKey: key,
          reviewedScopeKey: f.session.replacementReviewScopeKey,
          accept: true,
        ),
        isTrue,
      );
      expect(f.adapter.requests, hasLength(2));
      expect(
        f.adapter.requests.first.idempotencyKey,
        isNot(f.adapter.requests.last.idempotencyKey),
      );
    },
  );
  test('T12 supply missing update retains highest revision guard', () async {
    final f = await fixture();
    f.commerce.supply(_t12Progress(revision: 2));
    expect(await f.session.refreshOrder('supply-1'), isTrue);
    f.commerce.supply(null);
    expect(await f.session.refreshOrder('supply-1'), isTrue);
    expect(f.session.orderSupplyProgressFor('supply-1'), isNull);
    f.commerce.supply(_t12Progress());
    expect(await f.session.refreshOrder('supply-1'), isFalse);
    expect(f.session.orderSupplyProgressFor('supply-1'), isNull);
    f.commerce.supply(_t12Progress(revision: 3));
    expect(await f.session.refreshOrder('supply-1'), isTrue);
    expect(f.session.orderSupplyProgressFor('supply-1')!.revision, 3);
  });
  for (final previous in ['recorded', 'uncertain']) {
    test('T12 replacement $previous survives unrelated progress', () async {
      final f = await fixture();
      final key = buyV2ReplacementReviewKey(
        f.session.orderSupplyProgressFor('supply-1')!,
      );
      if (previous == 'uncertain') {
        f.adapter.respond = (_) async => throw StateError('Lost response');
      }
      expect(
        await f.session.decideOrderReplacement(
          orderId: 'supply-1',
          reviewedKey: key,
          reviewedScopeKey: f.session.replacementReviewScopeKey,
          accept: true,
        ),
        previous == 'recorded',
      );
      f.commerce.supply(
        _t12Progress(
          revision: 2,
          refund: BuyV2SupplyRefundState.processing,
          refundAmount: 3000,
          route: 'UPI',
        ),
      );
      expect(await f.session.refreshOrder('supply-1'), isTrue);
      expect(
        buyV2ReplacementReviewKey(
          f.session.orderSupplyProgressFor('supply-1')!,
        ),
        key,
      );
      if (previous == 'recorded') {
        expect(
          f.session.replacementConsentResult('supply-1')?.recorded,
          isTrue,
        );
        expect(
          await f.session.decideOrderReplacement(
            orderId: 'supply-1',
            reviewedKey: key,
            reviewedScopeKey: f.session.replacementReviewScopeKey,
            accept: true,
          ),
          isFalse,
        );
        expect(f.adapter.requests, hasLength(1));
      } else {
        f.adapter.respond = (r) async => BuyV2ReplacementConsentResult(
          request: r,
          recorded: true,
          reference: 'choice-1',
        );
        expect(
          await f.session.decideOrderReplacement(
            orderId: 'supply-1',
            reviewedKey: key,
            reviewedScopeKey: f.session.replacementReviewScopeKey,
            accept: true,
          ),
          isTrue,
        );
        expect(f.adapter.requests, hasLength(2));
        expect(
          f.adapter.requests.first.idempotencyKey,
          f.adapter.requests.last.idempotencyKey,
        );
        expect(f.adapter.requests.last.supplyRevision, 1);
      }
    });
  }
  for (final change in ['buyer', 'round trip', 'owner scope']) {
    test('T12 replacement old review rejects $change callback', () async {
      final f = await fixture();
      final key = buyV2ReplacementReviewKey(
        f.session.orderSupplyProgressFor('supply-1')!,
      );
      final scopeKey = f.session.replacementReviewScopeKey;
      if (change == 'owner scope') {
        f.store.ownerScope = 'tracking-owner-b';
      } else {
        f.identity.value = const BuyV2CollectionIdentity(
          accountId: 'buyer-b',
          sessionId: 'b',
        );
        if (change == 'round trip') {
          f.identity.value = const BuyV2CollectionIdentity(
            accountId: 'buyer-a',
            sessionId: 'a',
          );
        }
      }
      expect(
        await f.session.decideOrderReplacement(
          orderId: 'supply-1',
          reviewedKey: key,
          reviewedScopeKey: scopeKey,
          accept: true,
        ),
        isFalse,
      );
      expect(f.adapter.requests, isEmpty);
    });
  }
  for (final scale in [1.0, 2.0]) {
    testWidgets('T12 replacement review at ${scale.toInt()}x text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final f = await fixture();
      late BuildContext sheetContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          builder: (context, child) => RepaintBoundary(
            key: const ValueKey('t12-review-capture'),
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
          home: Builder(
            builder: (context) {
              sheetContext = context;
              return const Scaffold(body: Text('Order'));
            },
          ),
        ),
      );
      unawaited(
        showBuyV2ReplacementReviewSheet(
          sheetContext,
          session: f.session,
          orderId: 'supply-1',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fresh replacement tomatoes'), findsOneWidget);
      expect(find.text('Order total ₹90.00'), findsOneWidget);
      await _t12Capture(
        tester,
        'review-top-${scale.toInt()}x',
        't12-review-capture',
      );
      await tester.ensureVisible(find.text('Close'));
      await tester.pumpAndSettle();
      for (final key in ['buy-accept-replacement', 'buy-decline-replacement']) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(700));
        expect(rect.height, greaterThanOrEqualTo(44));
      }
      await _t12Capture(
        tester,
        'review-controls-${scale.toInt()}x',
        't12-review-capture',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('buy-accept-replacement')),
      );
      await tester.tap(find.byKey(const ValueKey('buy-accept-replacement')));
      await tester.pumpAndSettle();
      expect(f.session.replacementConsentResult('supply-1')?.recorded, isTrue);
      expect(
        find.text('Choice received. Refresh this order for the next update.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _t12Capture(
        tester,
        'choice-received-${scale.toInt()}x',
        't12-review-capture',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets(
      'T12 supply and refund public states at ${scale.toInt()}x text',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final f = await fixture();
        f.session.openTracking('supply-1');
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            builder: (context, child) => RepaintBoundary(
              key: const ValueKey('t12-progress-capture'),
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
            ),
            home: Scaffold(
              body: AnimatedBuilder(
                animation: f.session,
                builder: (context, _) => BuyV2TrackingView(
                  session: f.session,
                  onOpenOrderHelp: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        var revision = 2;
        final stages = <String, BuyV2OrderSupplyProgress?>{
          'awaiting': _t12Progress(
            revision: revision++,
            state: BuyV2SupplyState.awaitingSupply,
            available: 0,
            unavailable: 0,
          ),
          'partial': _t12Progress(
            revision: revision++,
            state: BuyV2SupplyState.partiallyAvailable,
            available: 1,
            unavailable: 1,
          ),
          'ready': _t12Progress(
            revision: revision++,
            state: BuyV2SupplyState.ready,
            available: 3,
            unavailable: 0,
          ),
          'unavailable': _t12Progress(
            revision: revision++,
            state: BuyV2SupplyState.unavailable,
            available: 0,
            unavailable: 3,
          ),
          'replacement': _t12Progress(revision: revision++),
          for (final refund in BuyV2SupplyRefundState.values)
            'refund-${refund.name}': _t12Progress(
              revision: revision++,
              refund: refund,
              refundAmount: 6000,
              route: 'UPI',
              reference: refund == BuyV2SupplyRefundState.refunded
                  ? 'refund-1'
                  : null,
            ),
          'missing': null,
        };
        for (final entry in stages.entries) {
          f.commerce.supply(entry.value);
          expect(await f.session.refreshOrder('supply-1'), isTrue);
          await tester.pumpAndSettle();
          final scrollable = find
              .descendant(
                of: find.byType(BuyV2TrackingView),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.drag(
            find.byType(BuyV2TrackingView),
            const Offset(0, 5000),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('buy-tracking-next-step')),
            250,
            scrollable: scrollable,
          );
          final next = tester
              .widget<Text>(
                find.byKey(const ValueKey('buy-tracking-next-step')),
              )
              .data!;
          if (entry.key == 'unavailable') {
            expect(next, contains('These items are unavailable'));
          }
          if (entry.key == 'replacement') {
            expect(next, contains('Review the replacement offer'));
          }
          if (entry.key == 'partial') {
            expect(next, contains('remaining items'));
          }
          await _t12Capture(
            tester,
            'next-${entry.key}-${scale.toInt()}x',
            't12-progress-capture',
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('buy-order-supply-supply-1')),
            250,
            scrollable: find
                .descendant(
                  of: find.byType(BuyV2TrackingView),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: entry.key);
          if (entry.key == 'partial') {
            expect(find.text('Awaiting confirmation: 1'), findsOneWidget);
          }
          if (entry.key == 'missing') {
            expect(find.text('Supply updates unavailable'), findsOneWidget);
          }
          if (entry.key.startsWith('refund-')) {
            expect(find.text('₹60.00 · UPI'), findsOneWidget);
            expect(
              find.text('Refund completed'),
              entry.key == 'refund-refunded' ? findsOneWidget : findsNothing,
            );
          }
          await _t12Capture(
            tester,
            '${entry.key}-${scale.toInt()}x',
            't12-progress-capture',
          );
          expect(f.session.orders.single.status, BuyV2OrderStatus.preparing);
          expect(f.session.orders.single.total, 90);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

class _T13ReceiptAdapter implements BuyV2DeliveryExceptionAdapter {
  @override
  Future<BuyV2DeliveryExceptionSnapshot> loadException({
    required String orderId,
  }) async {
    final product = BuyV2Catalogue.products.firstWhere(
      (p) => p.id == 's-tomato',
    );
    return BuyV2DeliveryExceptionSnapshot(
      state: BuyV2CommerceLoadState.ready,
      customerMessage: 'Check your received items.',
      exceptionId: 'receipt-1',
      kind: BuyV2DeliveryExceptionKind.proofOfDeliveryAvailable,
      headline: 'Delivery receipt',
      detail: 'Received quantities are shown below.',
      proofReference: 'receipt-proof-1',
      itemisedReceipt: BuyV2ItemisedReceipt(
        orderId: orderId,
        purchaseId: 'purchase-1',
        lines: [
          BuyV2ReceiptLine(
            productId: product.id,
            variant: product.variant,
            pack: product.pack,
            orderedQuantity: 3,
            receivedQuantity: 1,
          ),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

void _t13ReceiptCases() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'T13 partial delivery receipt stays honest at ${scale.toInt()}x text',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final core = BuySession();
        final commerce = _T12SupplyCommerce();
        commerce.status = BuyV2OrderStatus.delivered;
        commerce.supply(null);
        final session = BuyV2Session(
          core: core,
          commerceAdapter: commerce,
          deliveryExceptionAdapter: _T13ReceiptAdapter(),
          reviewDataEnabled: false,
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        await session.restoreCommerce();
        expect(await session.restoreDeliveryException('supply-1'), isTrue);
        session.openTracking('supply-1');
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            builder: (context, child) => RepaintBoundary(
              key: const ValueKey('t13-receipt-capture'),
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
            ),
            home: Scaffold(
              body: BuyV2TrackingView(
                session: session,
                onOpenOrderHelp: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final scrollable = find
            .descendant(
              of: find.byType(BuyV2TrackingView),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('buy-tracking-next-step')),
          250,
          scrollable: scrollable,
        );
        expect(
          find.text(
            'Delivery recorded with missing items. Review the receipt and get help with this order.',
          ),
          findsOneWidget,
        );
        await _t12Capture(
          tester,
          'partial-delivered-next-${scale.toInt()}x',
          't13-receipt-capture',
        );
        await tester.scrollUntilVisible(
          find.text('Received 1 of 3 · Missing 2'),
          -250,
          scrollable: scrollable,
        );
        expect(find.text('Received 1 of 3 · Missing 2'), findsOneWidget);
        expect(find.text('Supply updates unavailable'), findsNothing);
        await _t12Capture(
          tester,
          'partial-delivered-receipt-${scale.toInt()}x',
          't13-receipt-capture',
        );
        expect(session.orderIsCompleted(session.orders.single), isTrue);
        expect(session.orders.single.total, 90);
        expect(session.orders.single.supplyProgress?.refundState, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

class _T14AcceptanceAdapter implements BuyV2ProductAcceptanceAdapter {
  _T14AcceptanceAdapter(this.value);
  BuyV2ProductAcceptanceSnapshot value;
  bool failAccept = false;
  bool failLoad = false;
  int calls = 0;
  BuyV2ProductAcceptanceRequest? lastRequest;
  BuyV2ProductAcceptanceRequest? reconciled;
  String? reconciledKey;
  Completer<BuyV2ProductAcceptanceSnapshot>? pending;
  @override
  Future<BuyV2ProductAcceptanceSnapshot> load({
    required String ownerScope,
    required String orderId,
    required String purchaseId,
    required String? unresolvedRequestKey,
    required BuyV2ProductAcceptanceRequest? unresolvedRequest,
  }) async {
    reconciled = unresolvedRequest;
    reconciledKey = unresolvedRequestKey;
    if (failLoad) throw StateError('offline');
    return value;
  }

  @override
  Future<BuyV2ProductAcceptanceSnapshot> accept(
    BuyV2ProductAcceptanceRequest request,
  ) async {
    calls++;
    lastRequest = request;
    if (failAccept) throw StateError('unknown response');
    return pending?.future ?? value;
  }
}

BuyV2Order _t14AcceptedOrder() {
  final product = BuyV2Catalogue.products.firstWhere((p) => p.id == 's-tomato');
  return BuyV2Order(
    id: 'acceptance-order',
    purchaseId: 'acceptance-purchase',
    destination: BuyV2Destination.shop,
    title: 'Shop order',
    itemSummary: '1 product',
    total: 37,
    partner: 'Neighbourhood Store',
    partnerType: 'Retailer',
    promise: '',
    destinationLabel: 'Home',
    progress: 1,
    status: BuyV2OrderStatus.delivered,
    lines: [BuyV2CartLine(product: product, quantity: 1)],
  );
}

BuyV2ProductAcceptanceSnapshot _t14Acceptance(
  BuyV2Order order, {
  BuyV2ProductAcceptanceState state = BuyV2ProductAcceptanceState.ready,
  int revision = 1,
  int received = 1,
  String owner = 'tracking-owner-a',
  String source = 'qualified-test-acceptance',
}) {
  final product = order.lines.single.product;
  final receipt = BuyV2ItemisedReceipt(
    orderId: order.id,
    purchaseId: order.purchaseId!,
    lines: [
      BuyV2ReceiptLine(
        productId: product.id,
        variant: product.variant,
        pack: product.pack,
        orderedQuantity: 1,
        receivedQuantity: received,
      ),
    ],
  );
  return BuyV2ProductAcceptanceSnapshot(
    ownerScope: owner,
    orderId: order.id,
    purchaseId: order.purchaseId!,
    sourceId: source,
    revision: revision,
    state: state,
    requestKey: buyV2ProductAcceptanceKey(owner, receipt),
    receipt: receipt,
  );
}

void main() {
  test(
    'T14 acceptance cold pending keeps original receipt for reconciliation',
    () async {
      final order = _t14AcceptedOrder();
      final adapter = _T14AcceptanceAdapter(
        _t14Acceptance(order, state: BuyV2ProductAcceptanceState.pending),
      );
      final controller = BuyV2ProductAcceptanceController(
        adapter: adapter,
        ownerScope: 'tracking-owner-a',
        currentOrder: () => order,
        ownerCurrent: () => true,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.canAccept, isFalse);
      adapter.failLoad = true;
      expect(await controller.refresh(), isFalse);
      expect(adapter.reconciledKey, adapter.value.requestKey);
      expect(adapter.reconciled, isNull);
      expect(controller.unknownOutcome, isTrue);
      expect(adapter.calls, 0);
    },
  );

  test(
    'T14 acceptance changed confirmation revision and malformed submit cannot record',
    () async {
      final order = _t14AcceptedOrder();
      final adapter = _T14AcceptanceAdapter(_t14Acceptance(order));
      final controller = BuyV2ProductAcceptanceController(
        adapter: adapter,
        ownerScope: 'tracking-owner-a',
        currentOrder: () => order,
        ownerCurrent: () => true,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      final oldReview = controller.reviewKey!;
      adapter.value = _t14Acceptance(order, revision: 2);
      await controller.refresh();
      expect(await controller.accept(oldReview), isFalse);
      expect(adapter.calls, 0);
      final currentReview = controller.reviewKey!;
      adapter.value = _t14Acceptance(
        order,
        owner: 'other-account',
        revision: 3,
        state: BuyV2ProductAcceptanceState.accepted,
      );
      expect(await controller.accept(currentReview), isFalse);
      expect(controller.unknownOutcome, isTrue);
      expect(controller.canAccept, isFalse);
      expect(controller.snapshot!.state, BuyV2ProductAcceptanceState.ready);
      expect(await controller.accept(currentReview), isFalse);
      expect(adapter.calls, 1);
    },
  );

  test(
    'T14 acceptance cold load and authoritative accepted response',
    () async {
      final order = _t14AcceptedOrder();
      final adapter = _T14AcceptanceAdapter(_t14Acceptance(order));
      final controller = BuyV2ProductAcceptanceController(
        adapter: adapter,
        ownerScope: 'tracking-owner-a',
        currentOrder: () => order,
        ownerCurrent: () => true,
      );
      addTearDown(controller.dispose);
      expect(controller.canAccept, isFalse);
      expect(await controller.accept('unreviewed'), isFalse);
      expect(adapter.calls, 0);
      expect(await controller.refresh(), isTrue);
      final review = controller.reviewKey!;
      adapter.value = _t14Acceptance(
        order,
        state: BuyV2ProductAcceptanceState.accepted,
        revision: 2,
      );
      expect(await controller.accept(review), isTrue);
      expect(controller.snapshot!.state, BuyV2ProductAcceptanceState.accepted);
      expect(controller.canAccept, isFalse);
      expect(adapter.lastRequest!.snapshot.receipt.matchesOrder(order), isTrue);
    },
  );

  test(
    'T14 acceptance unknown keeps original key through restart and checking',
    () async {
      final order = _t14AcceptedOrder();
      final adapter = _T14AcceptanceAdapter(_t14Acceptance(order));
      final controller = BuyV2ProductAcceptanceController(
        adapter: adapter,
        ownerScope: 'tracking-owner-a',
        currentOrder: () => order,
        ownerCurrent: () => true,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      final reviewed = controller.reviewKey!;
      adapter.failAccept = true;
      expect(await controller.accept(reviewed), isFalse);
      final key = adapter.lastRequest!.idempotencyKey;
      expect(controller.unknownOutcome, isTrue);
      expect(await controller.accept(reviewed), isFalse);
      expect(adapter.calls, 1);
      adapter.value = _t14Acceptance(
        order,
        state: BuyV2ProductAcceptanceState.pending,
        revision: 2,
      );
      expect(await controller.refresh(), isTrue);
      expect(adapter.reconciled!.idempotencyKey, key);
      expect(controller.canAccept, isFalse);
      final restarted = BuyV2ProductAcceptanceController(
        adapter: adapter,
        ownerScope: 'tracking-owner-a',
        currentOrder: () => order,
        ownerCurrent: () => true,
      );
      addTearDown(restarted.dispose);
      expect(restarted.canAccept, isFalse);
      await restarted.refresh();
      expect(restarted.snapshot!.requestKey, key);
      expect(restarted.canAccept, isFalse);
      adapter.value = _t14Acceptance(
        order,
        state: BuyV2ProductAcceptanceState.accepted,
        revision: 3,
      );
      expect(await restarted.refresh(), isTrue);
      expect(restarted.snapshot!.state, BuyV2ProductAcceptanceState.accepted);
    },
  );

  for (final invalid in [
    'partial',
    'owner',
    'source',
    'older',
    'equal-conflict',
    'offline',
  ]) {
    test(
      'T14 acceptance rejects $invalid without stale ready action',
      () async {
        final order = _t14AcceptedOrder();
        final adapter = _T14AcceptanceAdapter(
          _t14Acceptance(order, revision: 2),
        );
        final controller = BuyV2ProductAcceptanceController(
          adapter: adapter,
          ownerScope: 'tracking-owner-a',
          currentOrder: () => order,
          ownerCurrent: () => true,
        );
        addTearDown(controller.dispose);
        await controller.refresh();
        adapter.value = _t14Acceptance(
          order,
          revision: invalid == 'older'
              ? 1
              : invalid == 'equal-conflict'
              ? 2
              : 3,
          received: invalid == 'partial' ? 0 : 1,
          owner: invalid == 'owner' ? 'other-account' : 'tracking-owner-a',
          source: invalid == 'source'
              ? 'unexpected-source'
              : 'qualified-test-acceptance',
          state: invalid == 'equal-conflict'
              ? BuyV2ProductAcceptanceState.accepted
              : BuyV2ProductAcceptanceState.ready,
        );
        adapter.failLoad = invalid == 'offline';
        expect(await controller.refresh(), isFalse);
        expect(controller.canAccept, isFalse);
        expect(adapter.calls, 0);
      },
    );
  }

  test(
    'T14 acceptance serializes duplicate and rejects old owner callback',
    () async {
      final order = _t14AcceptedOrder();
      final adapter = _T14AcceptanceAdapter(_t14Acceptance(order));
      var current = true;
      final controller = BuyV2ProductAcceptanceController(
        adapter: adapter,
        ownerScope: 'tracking-owner-a',
        currentOrder: () => order,
        ownerCurrent: () => current,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      final review = controller.reviewKey!;
      adapter.pending = Completer();
      final future = controller.accept(review);
      expect(await controller.accept(review), isFalse);
      expect(adapter.calls, 1);
      current = false;
      adapter.pending!.complete(
        _t14Acceptance(
          order,
          state: BuyV2ProductAcceptanceState.accepted,
          revision: 2,
        ),
      );
      expect(await future, isFalse);
      expect(controller.snapshot, isNull);
    },
  );

  test(
    'T14 acceptance changed receipt cannot replace unresolved request',
    () async {
      final order = _t14AcceptedOrder();
      final adapter = _T14AcceptanceAdapter(_t14Acceptance(order));
      final controller = BuyV2ProductAcceptanceController(
        adapter: adapter,
        ownerScope: 'tracking-owner-a',
        currentOrder: () => order,
        ownerCurrent: () => true,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      adapter.failAccept = true;
      await controller.accept(controller.reviewKey!);
      final original = adapter.lastRequest!.idempotencyKey;
      adapter.value = _t14Acceptance(
        order,
        received: 0,
        state: BuyV2ProductAcceptanceState.pending,
        revision: 2,
      );
      expect(await controller.refresh(), isFalse);
      expect(controller.unknownOutcome, isTrue);
      expect(adapter.reconciled!.idempotencyKey, original);
      expect(controller.canAccept, isFalse);
    },
  );

  test(
    'T14 acceptance definitive ready retry uses original identity with new revision',
    () async {
      final order = _t14AcceptedOrder();
      final adapter = _T14AcceptanceAdapter(_t14Acceptance(order));
      final controller = BuyV2ProductAcceptanceController(
        adapter: adapter,
        ownerScope: 'tracking-owner-a',
        currentOrder: () => order,
        ownerCurrent: () => true,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      adapter.failAccept = true;
      await controller.accept(controller.reviewKey!);
      final original = adapter.lastRequest!.idempotencyKey;
      adapter.failAccept = false;
      adapter.value = _t14Acceptance(order, revision: 2);
      expect(await controller.refresh(), isTrue);
      expect(controller.canAccept, isTrue);
      final review = controller.reviewKey!;
      adapter.value = _t14Acceptance(
        order,
        state: BuyV2ProductAcceptanceState.accepted,
        revision: 3,
      );
      expect(await controller.accept(review), isTrue);
      expect(adapter.lastRequest!.idempotencyKey, original);
      expect(adapter.lastRequest!.snapshot.revision, 2);
    },
  );
  _t13ReceiptCases();
  _t12SupplyCases();
  Future<
    ({
      BuyV2Session session,
      _T11DeferredOrderRefreshCommerce commerce,
      _R669TrackingOwnerStore store,
      ValueNotifier<BuyV2CollectionIdentity?> identity,
      VoidCallback dispose,
    })
  >
  refreshFixture() async {
    final core = BuySession();
    final commerce = _T11DeferredOrderRefreshCommerce();
    final store = _R669TrackingOwnerStore();
    final identity = ValueNotifier<BuyV2CollectionIdentity?>(
      const BuyV2CollectionIdentity(
        accountId: 'buyer-a',
        sessionId: 'session-a',
      ),
    );
    final session = BuyV2Session(
      core: core,
      commerceAdapter: commerce,
      customerStateStore: store,
      collectionIdentity: identity,
      reviewDataEnabled: false,
    );
    var disposed = false;
    void dispose() {
      if (disposed) return;
      disposed = true;
      session.dispose();
      identity.dispose();
      core.dispose();
    }

    addTearDown(dispose);
    await session.restoreCommerce();
    return (
      session: session,
      commerce: commerce,
      store: store,
      identity: identity,
      dispose: dispose,
    );
  }

  test('T11 order refresh accepts current owner', () async {
    final f = await refreshFixture();
    final original = f.session.orders.first;
    final flight = f.session.refreshOrder(original.id);
    expect(f.session.orderRefreshBusy(original.id), isTrue);
    f.commerce.finish(
      0,
      f.commerce.changed(original, BuyV2OrderStatus.dispatched),
    );
    expect(await flight, isTrue);
    expect(f.session.orders.first.status, BuyV2OrderStatus.dispatched);
    expect(f.session.orderRefreshBusy(original.id), isFalse);
    expect(
      f.session.orderRefreshState(original.id),
      BuyV2CommerceLoadState.ready,
    );
  });

  test('T11 order refresh follows index shift', () async {
    final f = await refreshFixture();
    final original = f.session.orders.first;
    final flight = f.session.refreshOrder(original.id);
    final other = f.commerce.records[1];
    f.commerce.records = [other, original, ...f.commerce.records.skip(2)];
    await f.session.restoreCommerce();
    f.commerce.finish(
      0,
      f.commerce.changed(original, BuyV2OrderStatus.dispatched),
    );
    expect(await flight, isTrue);
    expect(f.session.orders.map((o) => o.id).toSet().length, 4);
    expect(f.session.orders.first, same(other));
    expect(f.session.orders[1].id, original.id);
    expect(f.session.orders[1].status, BuyV2OrderStatus.dispatched);
  });

  test('T11 order refresh retains superseding progress', () async {
    final f = await refreshFixture();
    final original = f.session.orders.first;
    final flight = f.session.refreshOrder(original.id);
    f.commerce.advance(original.id, BuyV2OrderStatus.delivered);
    await f.session.restoreCommerce();
    f.commerce.finish(0, original);
    expect(await flight, isFalse);
    expect(f.session.orders.first.status, BuyV2OrderStatus.delivered);
    expect(f.session.orderRefreshBusy(original.id), isFalse);
    final retry = f.session.refreshOrder(original.id);
    f.commerce.finish(1, f.session.orders.first);
    expect(await retry, isTrue);
  });

  test('T11 order refresh rejects different order ID', () async {
    final f = await refreshFixture();
    final original = f.session.orders.first;
    final flight = f.session.refreshOrder(original.id);
    f.commerce.finish(
      0,
      BuyV2Order(
        id: 'different-order',
        destination: original.destination,
        title: original.title,
        itemSummary: original.itemSummary,
        total: original.total,
        partner: original.partner,
        partnerType: original.partnerType,
        promise: original.promise,
        destinationLabel: original.destinationLabel,
        progress: original.progress,
        status: original.status,
        purchaseId: original.purchaseId,
      ),
    );
    expect(await flight, isFalse);
    expect(f.session.orders.first, same(original));
    expect(f.session.orderRefreshBusy(original.id), isFalse);
  });

  test('T11 order refresh rejects removed order', () async {
    final f = await refreshFixture();
    final original = f.session.orders.first;
    final flight = f.session.refreshOrder(original.id);
    f.commerce.records.removeAt(0);
    await f.session.restoreCommerce();
    final remaining = f.session.orders;
    f.commerce.finish(0, original);
    expect(await flight, isFalse);
    expect(f.session.orders, remaining);
    expect(f.session.orders.any((o) => o.id == original.id), isFalse);
  });

  test('T11 order refresh rejects mismatched purchase', () async {
    final f = await refreshFixture();
    final original = f.session.orders.first;
    final flight = f.session.refreshOrder(original.id);
    f.commerce.finish(
      0,
      BuyV2Order(
        id: original.id,
        destination: original.destination,
        title: original.title,
        itemSummary: original.itemSummary,
        total: original.total,
        partner: original.partner,
        partnerType: original.partnerType,
        promise: original.promise,
        destinationLabel: original.destinationLabel,
        progress: original.progress,
        status: original.status,
        purchaseId: 'different-purchase',
      ),
    );
    expect(await flight, isFalse);
    expect(f.session.orders.first, same(original));
  });

  test('T11 order refresh rejects identity round trip', () async {
    final f = await refreshFixture();
    final original = f.session.orders.first;
    final identity = f.identity.value;
    final flight = f.session.refreshOrder(original.id);
    f.identity.value = const BuyV2CollectionIdentity(
      accountId: 'buyer-b',
      sessionId: 'session-b',
    );
    f.identity.value = identity;
    f.commerce.finish(
      0,
      f.commerce.changed(original, BuyV2OrderStatus.dispatched),
    );
    expect(await flight, isFalse);
    expect(f.session.orders.first, same(original));
    expect(f.session.orderRefreshState(original.id), isNull);
  });

  test('T11 order refresh rejects restored owner round trip', () async {
    final f = await refreshFixture();
    final original = f.session.orders.first;
    final flight = f.session.refreshOrder(original.id);
    f.store.ownerScope = 'tracking-owner-b';
    await f.session.restoreCustomerState();
    f.store.ownerScope = 'tracking-owner-a';
    await f.session.restoreCustomerState();
    f.commerce.finish(
      0,
      f.commerce.changed(original, BuyV2OrderStatus.dispatched),
    );
    expect(await flight, isFalse);
    expect(f.session.orders.first, same(original));
    expect(f.session.orderRefreshState(original.id), isNull);
  });

  for (final throws in [false, true]) {
    test(
      throws
          ? 'T11 order refresh ignores stale exception'
          : 'T11 order refresh keeps newer request busy',
      () async {
        final f = await refreshFixture();
        final original = f.session.orders.first;
        final old = f.session.refreshOrder(original.id);
        f.identity.value = const BuyV2CollectionIdentity(
          accountId: 'buyer-b',
          sessionId: 'session-b',
        );
        f.store.ownerScope = 'tracking-owner-b';
        final newer = f.session.refreshOrder(original.id);
        final started = f.commerce.pending.length == 2;
        if (throws) {
          f.commerce.pending[0].completeError(StateError('Old request failed'));
        } else {
          f.commerce.finish(
            0,
            f.commerce.changed(original, BuyV2OrderStatus.dispatched),
          );
        }
        final oldAccepted = await old;
        if (started) {
          expect(oldAccepted, isFalse);
          expect(f.session.orderRefreshBusy(original.id), isTrue);
          expect(
            f.session.orderRefreshState(original.id),
            BuyV2CommerceLoadState.loading,
          );
          expect(f.session.orders.first, same(original));
          f.commerce.finish(
            1,
            f.commerce.changed(original, BuyV2OrderStatus.confirmed),
          );
          expect(await newer, isTrue);
          expect(f.session.orders.first.status, BuyV2OrderStatus.confirmed);
        } else {
          await newer;
        }
        expect(started, isTrue, reason: 'New owner must own a new request');
      },
    );
  }

  test('T11 order refresh rejects disposal', () async {
    final f = await refreshFixture();
    final original = f.session.orders.first;
    final flight = f.session.refreshOrder(original.id);
    f.dispose();
    f.commerce.finish(
      0,
      f.commerce.changed(original, BuyV2OrderStatus.dispatched),
    );
    expect(await flight, isFalse);
    expect(f.session.orders.first, same(original));
  });

  test('T11 order refresh serializes same-account duplicate', () async {
    final f = await refreshFixture();
    final original = f.session.orders.first;
    final flight = f.session.refreshOrder(original.id);
    expect(await f.session.refreshOrder(original.id), isFalse);
    expect(f.commerce.pending, hasLength(1));
    f.commerce.finish(
      0,
      f.commerce.changed(original, BuyV2OrderStatus.dispatched),
    );
    expect(await flight, isTrue);
  });
  test(
    'R669 rail tracking nested Cart return and stale owner rejection',
    () async {
      final core = BuySession();
      final store = _R669TrackingOwnerStore();
      final session = BuyV2Session(
        core: core,
        commerceAdapter: _TrackingEligibleCommerce(),
        productFactsAdapter: _TrackingEligibleFacts(),
        customerStateStore: store,
        reviewDataEnabled: false,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      session.openDestination(BuyV2Destination.wholesale);
      expect(session.addProduct('w-notebook'), isTrue);
      session.openCart(scope: BuyV2CartScope.wholesale);
      final quantity = session.quantityFor('w-notebook');
      expect(session.openDeliveryTracking('quick-1'), isTrue);
      expect(session.openOrderItems('quick-1'), isTrue);
      session.goBack();
      expect(session.view, BuyV2View.tracking);
      session.goBack();
      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.wholesale);
      expect(session.quantityFor('w-notebook'), quantity);
      expect(session.openDeliveryTracking('quick-1'), isTrue);
      store.ownerScope = 'tracking-owner-b';
      session.goBack();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.catalogue);
      session.openDestination(BuyV2Destination.wholesale);
      expect(session.openDeliveryTracking('quick-1'), isTrue);
      session.openOrders();
      session.openTracking('quick-1');
      session.goBack();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.catalogue);
    },
  );
  Widget app(
    BuyV2Session session,
    double scale, {
    BuyV2DeliveryArrivalSound? sound,
    EdgeInsets insets = EdgeInsets.zero,
  }) => RepaintBoundary(
    key: const ValueKey('r66-order-state-app-capture'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          viewInsets: insets,
          padding: const EdgeInsets.only(top: 24, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
        ),
        child: child!,
      ),
      home: BuyV2Screen(session: session, deliveryArrivalSound: sound),
    ),
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('T14 acceptance receipt review cancel and confirm at $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final order = _t14AcceptedOrder();
      final adapter = _T14AcceptanceAdapter(_t14Acceptance(order));
      final commerce = _R669DeliveryCommerce()..records = [order];
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        reviewDataEnabled: false,
        commerceAdapter: commerce,
        customerStateStore: _R669TrackingOwnerStore(),
        productAcceptanceAdapter: adapter,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      await tester.pumpWidget(app(session, scale));
      expect(session.openTracking(order.id), isTrue);
      await tester.pumpAndSettle();
      final review = find.byKey(
        const ValueKey('buy-product-acceptance-review'),
      );
      await tester.scrollUntilVisible(
        review,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(review), alignment: .35);
      await tester.pumpAndSettle();
      expect(review.hitTestable(), findsOneWidget);
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(find.text('Check received products'), findsOneWidget);
      expect(
        find.textContaining(order.lines.single.product.title),
        findsWidgets,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(adapter.calls, 0);
      expect(session.selectedOrder.total, 37);
      await Scrollable.ensureVisible(tester.element(review), alignment: .35);
      await tester.pumpAndSettle();
      expect(review.hitTestable(), findsOneWidget);
      await tester.tap(review);
      await tester.pumpAndSettle();
      adapter.value = _t14Acceptance(
        order,
        state: BuyV2ProductAcceptanceState.accepted,
        revision: 2,
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-product-acceptance-confirm')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Products accepted'), findsOneWidget);
      expect(adapter.calls, 1);
      expect(session.selectedOrder.status, BuyV2OrderStatus.delivered);
      expect(session.selectedOrder.total, 37);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  Future<void> capture(WidgetTester tester, String name) async {
    const currentDirectory = String.fromEnvironment(
      'BUY_R664_VISUAL_DIRECTORY',
    );
    if (currentDirectory.isEmpty &&
        !const bool.fromEnvironment('BUY_R66_ORDER_STATE_CAPTURE')) {
      return;
    }
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await tester.runAsync(
        () => precacheImage(image.image, tester.element(find.byWidget(image))),
      );
    }
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('r66-order-state-app-capture')),
    );
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      repaint(boundary);
      await tester.pump();
      await tester.runAsync(() async {
        final directory = Directory(
          currentDirectory.isNotEmpty
              ? currentDirectory
              : 'build/r66-order-state-v1-20260905',
        );
        await directory.create(recursive: true);
        final file = File('${directory.path}/$name.png');
        if (await file.exists()) {
          throw StateError('Capture already exists');
        }
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
    } finally {
      debugDisableShadows = previousShadows;
      repaint(boundary);
      await tester.pump();
    }
  }

  for (final scale in [1.0, 2.0]) {
    for (final status in [
      BuyV2OrderStatus.delivered,
      BuyV2OrderStatus.preparing,
    ]) {
      for (final estimate in ['missing', 'retained', 'revised']) {
        testWidgets(
          'T14 completion hierarchy ${status.name} $estimate at $scale',
          (tester) async {
            final semantics = tester.ensureSemantics();
            try {
              await tester.binding.setSurfaceSize(const Size(320, 800));
              addTearDown(() => tester.binding.setSurfaceSize(null));
              final core = BuySession();
              final adapter = _R669DeliveryCommerce();
              final order = BuyV2Order(
                id: 'completion-hierarchy',
                destination: BuyV2Destination.shop,
                title: 'Shop order',
                itemSummary: '1 product',
                total: 37,
                partner: 'Neighbourhood Store',
                partnerType: 'Retailer',
                promise: estimate == 'missing' ? '' : 'Delivery in 15 min',
                updatedDeliveryEstimate: estimate == 'revised'
                    ? 'Delivery in 30 min'
                    : null,
                destinationLabel: 'Home',
                progress: status == BuyV2OrderStatus.delivered ? 1 : .4,
                status: status,
              );
              adapter.records = [order];
              final session = BuyV2Session(
                core: core,
                commerceAdapter: adapter,
                reviewDataEnabled: false,
              );
              addTearDown(core.dispose);
              addTearDown(session.dispose);
              await session.restoreCommerce();
              await tester.pumpWidget(app(session, scale));
              expect(session.openTracking(order.id), isTrue);
              await tester.pumpAndSettle();
              final complete = status == BuyV2OrderStatus.delivered;
              final heading = find.byKey(
                ValueKey(
                  'buy-tracking-${complete ? 'completion' : 'estimate'}-${order.id}',
                ),
              );
              expect(heading, findsOneWidget);
              expect(
                tester.widget<Text>(heading).data,
                complete
                    ? 'Delivered'
                    : buyV2OrderArrivalSummary(session, order),
              );
              expect(
                tester.renderObject<RenderParagraph>(heading).didExceedMaxLines,
                isFalse,
              );
              expect(tester.widget<Text>(heading).style!.fontSize, 13);
              final header = find
                  .ancestor(of: heading, matching: find.byType(Container))
                  .first;
              if (complete) {
                expect(
                  find.descendant(of: header, matching: find.text('Delivered')),
                  findsOneWidget,
                );
                expect(
                  find.descendant(
                    of: header,
                    matching: find.textContaining('estimate'),
                  ),
                  findsNothing,
                );
              } else {
                adapter.state = BuyV2CommerceLoadState.offline;
                expect(await session.refreshOrder(order.id), isFalse);
                await tester.pumpAndSettle();
                expect(
                  tester.widget<Text>(heading).data,
                  contains('update unavailable'),
                );
                if (estimate == 'revised') {
                  expect(
                    find.descendant(
                      of: header,
                      matching: find.textContaining('Delivery in 30 min'),
                    ),
                    findsOneWidget,
                  );
                }
              }
              expect(
                find.byKey(ValueKey('buy-tracking-refresh-${order.id}')),
                findsOneWidget,
              );
              expect(
                find.byKey(const ValueKey('buy-tracking-return-orders')),
                findsOneWidget,
              );
              expect(session.selectedOrderOrNull!.status, status);
              expect(session.selectedOrderOrNull!.promise, order.promise);
              final trackingScroll = find
                  .descendant(
                    of: find.byKey(PageStorageKey('buy-tracking-${order.id}')),
                    matching: find.byType(Scrollable),
                  )
                  .first;
              final originalScroll = tester
                  .state<ScrollableState>(trackingScroll)
                  .position
                  .pixels;
              await tester.scrollUntilVisible(
                find.text('Item checking and packing'),
                180,
                scrollable: trackingScroll,
                maxScrolls: 20,
              );
              await Scrollable.ensureVisible(
                tester.element(find.text('Item checking and packing')),
                alignment: .5,
              );
              await tester.pumpAndSettle();
              expect(find.text('Item checking and packing'), findsOneWidget);
              expect(
                find.text('Journey to the delivery address'),
                findsOneWidget,
              );
              expect(
                find.text('Items are being checked and packed'),
                findsNothing,
              );
              expect(
                find.text('Delivery is travelling to the address'),
                findsNothing,
              );
              expect(
                tester
                    .getSemantics(
                      find
                          .ancestor(
                            of: find.text('Item checking and packing'),
                            matching: find.byType(Semantics),
                          )
                          .first,
                    )
                    .getSemanticsData()
                    .label,
                contains(
                  'Packing. Item checking and packing. '
                  '${complete ? 'Complete' : 'Last recorded stage'}',
                ),
              );
              await Scrollable.ensureVisible(
                tester.element(find.text('Journey to the delivery address')),
                alignment: .5,
              );
              await tester.pumpAndSettle();
              expect(
                tester
                    .getSemantics(
                      find
                          .ancestor(
                            of: find.text('Journey to the delivery address'),
                            matching: find.byType(Semantics),
                          )
                          .first,
                    )
                    .getSemanticsData()
                    .label,
                contains(
                  'Arriving. Journey to the delivery address. '
                  '${complete ? 'Complete' : 'Upcoming'}',
                ),
              );
              await capture(
                tester,
                't14-timeline-${status.name}-$estimate-$scale',
              );
              tester
                  .state<ScrollableState>(trackingScroll)
                  .position
                  .jumpTo(originalScroll);
              await tester.pumpAndSettle();
              await capture(
                tester,
                't14-completion-${status.name}-$estimate-$scale',
              );
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            } finally {
              semantics.dispose();
            }
          },
        );
      }
    }
  }

  for (final scale in [1.0, 2.0]) {
    for (final scenario in const {
      'Shop': ['s-tomato'],
      'Wholesale': ['w-notebook'],
      'Offers': ['s-rice'],
      'Shop+Wholesale': ['s-tomato', 'w-notebook'],
      'Shop+Offers': ['s-tomato', 's-rice'],
      'Wholesale+Offers': ['w-notebook', 's-rice'],
      'Shop+Wholesale+Offers': ['s-tomato', 'w-notebook', 's-rice'],
    }.entries) {
      testWidgets('T14 isolated connected fulfilment ${scenario.key} at $scale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final core = BuySession();
        final commerce = _T14ConnectedJourneyCommerce();
        final session = BuyV2Session(
          core: core,
          commerceAdapter: commerce,
          reviewDataEnabled: true,
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        for (final id in scenario.value) {
          expect(session.addProduct(id), isTrue, reason: session.notice);
        }
        final total = session.cartTotal;
        // Mount before navigation: screen initialization chooses its entry route.
        await tester.pumpWidget(app(session, scale));
        await tester.pumpAndSettle();
        session.openCart();
        expect(session.openCheckout(), isTrue);
        expect(
          session.continueCheckoutFromAddress(),
          isTrue,
          reason: session.notice,
        );
        expect(
          session.continueCheckoutFromPayment(),
          isTrue,
          reason: session.notice,
        );
        // Explicit development confirmation fixture; no payment handoff/server call.
        expect(session.confirmOrder(), isTrue, reason: session.notice);
        final originals = List<BuyV2Order>.of(session.confirmedOrders);
        expect(originals, isNotEmpty);
        expect(
          originals.fold<int>(0, (sum, order) => sum + order.total),
          total,
        );
        expect(
          originals.expand((order) => order.productIds).toSet(),
          scenario.value.toSet(),
        );
        final purchase = originals.first.purchaseId;
        expect(
          originals.every((order) => order.purchaseId == purchase),
          isTrue,
        );
        commerce.records = originals;
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.confirmation);
        expect(find.byKey(const ValueKey('buy-confirmation')), findsOneWidget);
        await capture(
          tester,
          't14-frontend-${scenario.key}-$scale-confirmation',
        );
        session.showOrdersTab(BuyV2OrdersTab.active);
        await tester.pumpAndSettle();
        final ids = originals.map((order) => order.id).toSet();
        expect(
          session.visibleOrders.map((order) => order.id).toSet(),
          containsAll(ids),
        );
        await capture(tester, 't14-frontend-${scenario.key}-$scale-orders');
        for (final original in originals) {
          expect(session.openTracking(original.id), isTrue);
          await tester.pumpAndSettle();
          expect(session.selectedOrder.total, original.total);
          expect(
            session.selectedOrder.status,
            isNot(BuyV2OrderStatus.delivered),
          );
          await capture(
            tester,
            't14-frontend-${scenario.key}-$scale-${originals.indexOf(original)}-${original.destination.name}-preparing',
          );
          for (final next in [
            BuyV2OrderStatus.arriving,
            BuyV2OrderStatus.delivered,
          ]) {
            commerce.advanceConfirmed(original, next);
            expect(await session.refreshOrder(original.id), isTrue);
            await tester.pumpAndSettle();
            expect(session.selectedOrder.status, next);
            expect(find.byKey(const ValueKey('buy-live-notice')), findsNothing);
            expect(session.selectedOrder.total, original.total);
            expect(session.selectedOrder.productIds, original.productIds);
            expect(session.selectedOrder.purchaseId, purchase);
            expect(
              session.selectedOrder.lines.map((line) => line.quantity),
              original.lines.map((line) => line.quantity),
            );
          }
          await capture(
            tester,
            't14-frontend-${scenario.key}-$scale-${originals.indexOf(original)}-${original.destination.name}-delivered',
          );
          expect(tester.takeException(), isNull);
        }
        session.showOrdersTab(BuyV2OrdersTab.delivered);
        await tester.pumpAndSettle();
        expect(
          session.visibleOrders.map((order) => order.id).toSet(),
          containsAll(ids),
        );
        expect(
          session.orders
              .where((order) => ids.contains(order.id))
              .fold<int>(0, (sum, order) => sum + order.total),
          total,
        );
        await capture(
          tester,
          't14-frontend-${scenario.key}-$scale-delivered-history',
        );
        commerce.readyMessage = 'Order details updated.';
        expect(await session.refreshOrder(originals.first.id), isTrue);
        await tester.pumpAndSettle();
        final notice = find.byKey(const ValueKey('buy-live-notice'));
        expect(notice, findsOneWidget);
        expect(
          tester.widget<Semantics>(notice).properties.label,
          commerce.readyMessage,
        );
        expect(
          find.descendant(
            of: notice,
            matching: find.text(commerce.readyMessage),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  Future<void> tapDelivery(WidgetTester tester, String action) async {
    final target = find.byKey(ValueKey('buy-quick-delivery-$action'));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('R669 delivery selector stays open while reading $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        commerceAdapter: _R669DeliveryCommerce(),
        reviewDataEnabled: false,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      await tester.pumpWidget(app(session, scale));
      await tester.pumpAndSettle();
      await tapDelivery(tester, 'toggle');
      final picker = find.byKey(const ValueKey('buy-delivery-picker-toggle'));
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      final choice = find.byKey(const ValueKey('buy-delivery-select-bulk-4'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      final before = tester.getRect(choice);
      await tester.pump(const Duration(seconds: 90));
      await tester.pumpAndSettle();
      expect(choice, findsOneWidget);
      expect(
        tester.getRect(choice),
        before,
        reason: 'Reading must not hide or reset the delivery list.',
      );
      await capture(tester, 'r669-delivery-picker-reading-$scale');
      await tester.tap(choice);
      await tester.pumpAndSettle();
      final panel = find.byKey(
        const ValueKey('buy-quick-delivery-status-expanded'),
      );
      expect(
        find.descendant(of: panel, matching: find.text('bulk-4')),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 46));
      await tester.pumpAndSettle();
      expect(
        panel,
        findsNothing,
        reason: 'After selection, the ordinary quiet-rail timer resumes.',
      );
      expect(
        find.byKey(const ValueKey('buy-quick-delivery-toggle')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final origin in [BuyV2Destination.shop, BuyV2Destination.wholesale]) {
    testWidgets('R669 rail tracking Back restores ${origin.name} shopping', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        commerceAdapter: _R669DeliveryCommerce(),
        reviewDataEnabled: false,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      final mode = origin == BuyV2Destination.wholesale
          ? BuyV2FulfilmentMode.bulkFreight
          : BuyV2FulfilmentMode.quickLocal;
      session.addProduct('w-notebook');
      final quantity = session.quantityFor('w-notebook');
      await tester.pumpWidget(app(session, 1));
      await tester.pumpAndSettle();
      session.openDestination(origin);
      if (origin == BuyV2Destination.wholesale) {
        session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
      }
      session.chooseFulfilmentMode(mode);
      session.query = 'retained supplier search';
      session.selectedFilter = 'retained filter';
      await tester.pumpAndSettle();
      expect(session.destination, origin);
      await tapDelivery(tester, 'toggle');
      await tapDelivery(tester, 'open');
      expect(session.view, BuyV2View.tracking);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.destination, origin);
      expect(session.view, BuyV2View.catalogue);
      expect(session.query, 'retained supplier search');
      expect(session.selectedFulfilmentMode, mode);
      if (origin == BuyV2Destination.wholesale) {
        expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.bulk);
      }
      expect(session.quantityFor('w-notebook'), quantity);
      await capture(tester, 'r669-rail-tracking-return-${origin.name}');
      session.openOrders();
      session.increase('w-notebook');
      final updatedQuantity = session.quantityFor('w-notebook');
      expect(session.openTracking('quick-1'), isTrue);
      session.goBack();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.catalogue);
      session.showOrdersTab(BuyV2OrdersTab.delivered);
      session.openOrders();
      session.goBack();
      expect(session.destination, origin);
      expect(session.view, BuyV2View.catalogue);
      expect(session.query, 'retained supplier search');
      expect(session.selectedFilter, 'retained filter');
      expect(session.selectedFulfilmentMode, mode);
      expect(session.quantityFor('w-notebook'), updatedQuantity);
      session.openOrders();
      final other = origin == BuyV2Destination.shop
          ? BuyV2Destination.wholesale
          : BuyV2Destination.shop;
      session.openDestination(other);
      session.openOrders();
      session.goBack();
      expect(session.destination, other);
      session.openAccount();
      session.openOrdersFromAccount();
      session.goBack();
      expect(session.view, BuyV2View.account);
      session.closeAccount();
      expect(session.destination, other);
      expect(session.quantityFor('w-notebook'), updatedQuantity);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final changeIdentity in [false, true]) {
    test('T14 Orders return rejects stale owner identity $changeIdentity', () {
      final core = BuySession();
      final store = _R669TrackingOwnerStore();
      final identity = ValueNotifier<BuyV2CollectionIdentity?>(
        const BuyV2CollectionIdentity(accountId: 'buyer-a', sessionId: 'a'),
      );
      final session = BuyV2Session(
        core: core,
        customerStateStore: store,
        collectionIdentity: identity,
      );
      addTearDown(core.dispose);
      addTearDown(identity.dispose);
      addTearDown(session.dispose);
      session.openDestination(BuyV2Destination.wholesale);
      session.query = 'old owner search';
      session.openOrders();
      if (changeIdentity) {
        identity.value = const BuyV2CollectionIdentity(
          accountId: 'buyer-a',
          sessionId: 'new-session',
        );
      } else {
        store.ownerScope = 'tracking-owner-b';
      }
      session.goBack();
      expect(session.destination, BuyV2Destination.shop);
      expect(session.query, isNot('old owner search'));
    });
  }

  for (final scale in [1.0, 2.0]) {
    for (final androidBack in [true, false]) {
      testWidgets(
        'R669 Orders retains scroll after tracking $scale Android$androidBack',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(360, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            commerceAdapter: _R669DeliveryCommerce(),
            reviewDataEnabled: false,
          );
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await session.restoreCommerce();
          await tester.pumpWidget(app(session, scale));
          await tester.pumpAndSettle();
          session.openOrders();
          await tester.pumpAndSettle();
          final list = find.byKey(const PageStorageKey('buy-orders'));
          Finder scroll() => find
              .descendant(of: list, matching: find.byType(Scrollable))
              .first;
          final action = find.byKey(const ValueKey('buy-order-primary-bulk-4'));
          await tester.scrollUntilVisible(
            action,
            300,
            scrollable: scroll(),
            maxScrolls: 100,
          );
          await tester.pumpAndSettle();
          final before = tester
              .state<ScrollableState>(scroll())
              .position
              .pixels;
          final beforeExtent = tester
              .state<ScrollableState>(scroll())
              .position
              .maxScrollExtent;
          final beforeCount = session.visibleOrders.length;
          expect(before, greaterThan(100));
          await capture(
            tester,
            'r669-orders-scroll-before-$scale-$androidBack',
          );
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.tracking);
          if (androidBack) {
            await tester.binding.handlePopRoute();
          } else {
            final back = find.byKey(
              const ValueKey('buy-tracking-return-orders'),
            );
            await tester.ensureVisible(back);
            await tester.tap(back);
          }
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          expect(session.destination, BuyV2Destination.orders);
          final after = tester.state<ScrollableState>(scroll()).position.pixels;
          expect(
            after,
            closeTo(before, 1),
            reason:
                'Orders should return to the same place after viewing tracking. Extent $beforeExtent -> ${tester.state<ScrollableState>(scroll()).position.maxScrollExtent}; orders $beforeCount -> ${session.visibleOrders.length}.',
          );
          await capture(
            tester,
            'r669-orders-scroll-return-$scale-$androidBack',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('R669 arrival summaries preserve freshness $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final core = BuySession();
      final adapter = _R669PendingDeliveryCommerce();
      final session = BuyV2Session(
        core: core,
        commerceAdapter: adapter,
        reviewDataEnabled: false,
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await session.restoreCommerce();
      await tester.pumpWidget(app(session, scale));
      await tester.pumpAndSettle();
      await tapDelivery(tester, 'toggle');
      final panel = find.byKey(
        const ValueKey('buy-quick-delivery-status-expanded'),
      );
      Finder panelText(String text) =>
          find.descendant(of: panel, matching: find.textContaining(text));
      expect(panelText('Last recorded estimate'), findsOneWidget);
      expect(panelText('Delivery in 15 min'), findsOneWidget);
      await capture(tester, 'r669-arrival-last-recorded-$scale');
      await tapDelivery(tester, 'open');
      expect(session.view, BuyV2View.tracking);
      expect(
        find.text('Last recorded estimate · Delivery in 15 min'),
        findsWidgets,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      session.openOrders();
      await tester.pumpAndSettle();
      final quickCard = find.byKey(const ValueKey('buy-order-card-quick-1'));
      Finder cardText(String text) =>
          find.descendant(of: quickCard, matching: find.textContaining(text));
      expect(cardText('Last recorded estimate'), findsNothing);
      final quickDetails = find.byKey(
        const ValueKey('buy-order-details-quick-1'),
      );
      await tester.ensureVisible(quickDetails);
      await tester.tap(quickDetails);
      await tester.pumpAndSettle();
      expect(cardText('Last recorded estimate'), findsOneWidget);
      adapter.pending = Completer<BuyV2OrderRefreshResult>();
      final pending = session.refreshOrder('quick-1');
      await tester.pump();
      expect(cardText('Updating · last recorded estimate'), findsOneWidget);
      adapter.pending!.complete(
        const BuyV2OrderRefreshResult(
          state: BuyV2CommerceLoadState.offline,
          customerMessage: 'Update unavailable',
        ),
      );
      expect(await pending, isFalse);
      adapter.pending = null;
      await tester.pumpAndSettle();
      expect(
        cardText('Last recorded estimate (update unavailable)'),
        findsOneWidget,
      );
      await capture(tester, 'r669-arrival-unavailable-$scale');
      expect(await session.refreshOrder('quick-1'), isTrue);
      await tester.pumpAndSettle();
      expect(cardText('Updated estimate · Delivery in 15 min'), findsOneWidget);
      final scheduledCard = find.byKey(
        const ValueKey('buy-order-card-scheduled-2'),
      );
      final scheduledDetails = find.byKey(
        const ValueKey('buy-order-details-scheduled-2'),
      );
      await tester.scrollUntilVisible(
        scheduledDetails,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(scheduledDetails);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: scheduledCard,
          matching: find.textContaining('Last recorded estimate'),
        ),
        findsOneWidget,
      );
      await capture(tester, 'r669-arrival-updated-$scale');
      session.openDestination(BuyV2Destination.shop);
      await tester.pumpAndSettle();
      await tapDelivery(tester, 'toggle');
      expect(panelText('Updated estimate'), findsOneWidget);
      final picker = find.byKey(const ValueKey('buy-delivery-picker-toggle'));
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      final quickChoice = find.byKey(
        const ValueKey('buy-delivery-select-quick-1'),
      );
      final scheduledChoice = find.byKey(
        const ValueKey('buy-delivery-select-scheduled-2'),
      );
      expect(
        find.descendant(
          of: quickChoice,
          matching: find.textContaining('Updated estimate'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: scheduledChoice,
          matching: find.textContaining('Last recorded estimate'),
        ),
        findsOneWidget,
      );
      await capture(tester, 'r669-arrival-selector-$scale');
      await tester.ensureVisible(quickChoice);
      await tester.tap(quickChoice);
      await tester.pumpAndSettle();
      await tapDelivery(tester, 'hide');
      final quiet = tester.widget<Semantics>(
        find.byKey(const ValueKey('buy-quick-delivery-status-minimized')),
      );
      expect(quiet.properties.label, contains('Updated estimate'));

      expect(session.orders, hasLength(4));
      expect(
        session.orders.firstWhere((o) => o.id == 'quick-1').promise,
        'Delivery in 15 min',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('R669 delivery recovery with twelve simultaneous deliveries', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final core = BuySession();
    final adapter = _R669DeliveryCommerce();
    final product = adapter.records.first.lines.single.product;
    adapter.records.addAll([
      for (var index = 5; index <= 12; index++)
        adapter.make('split-$index', product, 'Work', 'Delivery tomorrow'),
    ]);
    final session = BuyV2Session(
      core: core,
      commerceAdapter: adapter,
      reviewDataEnabled: false,
    );
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    await session.restoreCommerce();
    await tester.pumpWidget(app(session, 2, sound: _R5ArrivalSound()));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('buy-quick-delivery-toggle'));
    expect(toggle.hitTestable(), findsOneWidget);
    expect(find.byTooltip('Show 12 deliveries'), findsOneWidget);
    expect(find.text('9+'), findsOneWidget);
    final artworkRect = tester.getRect(
      find.byKey(const ValueKey('buy-delivery-compact-artwork')),
    );
    final countRect = tester.getRect(
      find.byKey(const ValueKey('buy-delivery-count')),
    );
    expect(artworkRect.overlaps(countRect), isFalse);
    final toggleRect = tester.getRect(toggle);
    expect(countRect.right, lessThanOrEqualTo(toggleRect.right));
    expect(countRect.bottom, lessThanOrEqualTo(toggleRect.bottom));
    expect(countRect.left, greaterThanOrEqualTo(toggleRect.left));
    expect(countRect.top, greaterThanOrEqualTo(toggleRect.top));
    final countText = find.descendant(
      of: find.byKey(const ValueKey('buy-delivery-count')),
      matching: find.byType(RichText),
    );
    expect(
      tester.renderObject<RenderParagraph>(countText).didExceedMaxLines,
      isFalse,
      reason: 'The complete 9+ count must remain visible at enlarged text.',
    );
    await capture(tester, 'r669-deliveries-twelve-hidden-rail');
    await tapDelivery(tester, 'toggle');
    await tester.tap(find.byKey(const ValueKey('buy-delivery-picker-toggle')));
    await tester.pumpAndSettle();
    final last = find.byKey(const ValueKey('buy-delivery-select-split-12'));
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    expect(last.hitTestable(), findsOneWidget);
    await capture(tester, 'r669-deliveries-twelve-last-choice');
    await tester.tap(last);
    await tester.pumpAndSettle();
    await tapDelivery(tester, 'open');
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrderId, 'split-12');
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 780), const Size(711, 360)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R669 delivery recovery and multiple identities ${size.width} $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final core = BuySession();
          final adapter = _R669DeliveryCommerce();
          final session = BuyV2Session(
            core: core,
            commerceAdapter: adapter,
            reviewDataEnabled: false,
          );
          final sound = _R5ArrivalSound();
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await session.restoreCommerce();
          await tester.pumpWidget(app(session, scale, sound: sound));
          await tester.pumpAndSettle();
          expect(session.activeDeliveryOrders.map((o) => o.id), [
            'quick-1',
            'scheduled-2',
            'wholesale-3',
            'bulk-4',
          ]);
          final toggle = find.byKey(
            const ValueKey('buy-quick-delivery-toggle'),
          );
          final panel = find.byKey(
            const ValueKey('buy-quick-delivery-status-expanded'),
          );
          final prefix = 'r669-deliveries-${size.width.toInt()}-$scale';
          await tapDelivery(tester, 'toggle');
          expect(
            find.descendant(of: panel, matching: find.text('quick-1')),
            findsOneWidget,
          );
          expect(find.text('Arrival sound'), findsNothing);
          await tapDelivery(tester, 'sound');
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const ValueKey('buy-quick-delivery-sound')),
                )
                .isSelected,
            isTrue,
          );
          await tapDelivery(tester, 'hide');
          expect(toggle.hitTestable(), findsOneWidget);
          expect(panel, findsNothing);
          adapter.records = adapter.records.reversed.toList();
          await session.restoreCommerce();
          session.openDestination(BuyV2Destination.wholesale);
          await tester.pumpAndSettle();
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();
          expect(panel, findsNothing);
          expect(toggle.hitTestable(), findsOneWidget);
          expect(find.byTooltip('Show 4 deliveries'), findsOneWidget);
          final artworkRect = tester.getRect(
            find.byKey(const ValueKey('buy-delivery-compact-artwork')),
          );
          final countRect = tester.getRect(
            find.byKey(const ValueKey('buy-delivery-count')),
          );
          final toggleRect = tester.getRect(toggle);
          expect(artworkRect.overlaps(countRect), isFalse);
          expect(toggleRect.contains(artworkRect.topLeft), isTrue);
          expect(toggleRect.contains(countRect.bottomRight), isTrue);
          await capture(tester, '$prefix-hidden-rail');
          await tapDelivery(tester, 'toggle');
          expect(
            find.descendant(of: panel, matching: find.text('quick-1')),
            findsOneWidget,
          );
          final picker = find.byKey(
            const ValueKey('buy-delivery-picker-toggle'),
          );
          await tester.ensureVisible(picker);
          await tester.pumpAndSettle();
          await tester.tap(picker);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-delivery-select-quick-1')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('buy-delivery-select-scheduled-2')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('buy-delivery-select-wholesale-3')),
            findsOneWidget,
          );
          await capture(tester, '$prefix-picker');
          for (final id in [
            'scheduled-2',
            'wholesale-3',
            'bulk-4',
            'quick-1',
          ]) {
            if (find
                .byKey(ValueKey('buy-delivery-select-$id'))
                .evaluate()
                .isEmpty) {
              await tester.ensureVisible(picker);
              await tester.pumpAndSettle();
              await tester.tap(picker);
              await tester.pumpAndSettle();
            }
            final choice = find.byKey(ValueKey('buy-delivery-select-$id'));
            await Scrollable.ensureVisible(
              tester.element(choice),
              alignment: .5,
            );
            await tester.pumpAndSettle();
            expect(choice.hitTestable(), findsOneWidget);
            await tester.tap(choice);
            await tester.pumpAndSettle();
            expect(
              find.descendant(of: panel, matching: find.text(id)),
              findsOneWidget,
            );
            await tester.ensureVisible(
              find.byKey(const ValueKey('buy-quick-delivery-sound')),
            );
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<IconButton>(
                    find.byKey(const ValueKey('buy-quick-delivery-sound')),
                  )
                  .isSelected,
              id == 'quick-1',
            );
            if (id == 'wholesale-3') await tapDelivery(tester, 'sound');
            await capture(tester, '$prefix-$id');
            await tapDelivery(tester, 'open');
            expect(session.view, BuyV2View.tracking);
            expect(session.selectedOrderId, id);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, isNot(BuyV2View.tracking));
            await tapDelivery(tester, 'toggle');
          }
          await tapDelivery(tester, 'hide');
          adapter.advance('quick-1', BuyV2OrderStatus.arriving);
          await session.restoreCommerce();
          await tester.pumpAndSettle();
          expect(sound.plays, 1);
          expect(panel, findsNothing);
          adapter.advance('quick-1', BuyV2OrderStatus.delivered);
          await session.restoreCommerce();
          await tester.pumpAndSettle();
          expect(sound.plays, 1);
          expect(toggle.hitTestable(), findsOneWidget);
          await tapDelivery(tester, 'toggle');
          expect(
            find.descendant(of: panel, matching: find.text('quick-1')),
            findsNothing,
          );
          expect(
            find.descendant(
              of: panel,
              matching: find.text(session.activeDeliveryOrders.first.id),
            ),
            findsOneWidget,
          );
          final delivered = session.orders.firstWhere(
            (order) => order.id == 'quick-1',
          );
          expect(delivered.status, BuyV2OrderStatus.delivered);
          expect(
            buyV2OrderPromiseSummary(delivered),
            'Original promise: Delivery in 15 min',
          );
          expect(
            buyV2OrderPromiseSummary(delivered),
            isNot(contains('Delivered in 15 min')),
          );
          await capture(tester, '$prefix-completed');
          await tapDelivery(tester, 'hide');
          adapter.advance('wholesale-3', BuyV2OrderStatus.arriving);
          await session.restoreCommerce();
          await tester.pumpAndSettle();
          expect(
            sound.plays,
            2,
            reason:
                'An enabled nonselected delivery has its own arrival transition',
          );
          expect(panel, findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final failure in [
    BuyV2CommerceLoadState.offline,
    BuyV2CommerceLoadState.unavailable,
  ]) {
    testWidgets(
      'R669 delivery recovery keeps ${failure.name} quiet and retries exact order',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 780));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final core = BuySession();
        final adapter = _R669DeliveryCommerce();
        final session = BuyV2Session(
          core: core,
          commerceAdapter: adapter,
          reviewDataEnabled: false,
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await session.restoreCommerce();
        await tester.pumpWidget(app(session, 2));
        await tester.pumpAndSettle();
        await tapDelivery(tester, 'toggle');
        await tapDelivery(tester, 'hide');
        adapter.state = failure;
        expect(await session.refreshOrder('quick-1'), isFalse);
        await tester.pumpAndSettle();
        final panel = find.byKey(
          const ValueKey('buy-quick-delivery-status-expanded'),
        );
        expect(panel, findsNothing);
        expect(
          find.byKey(const ValueKey('buy-quick-delivery-toggle')).hitTestable(),
          findsOneWidget,
        );
        await tapDelivery(tester, 'toggle');
        final retry = find.byKey(const ValueKey('buy-delivery-retry'));
        await tester.ensureVisible(retry);
        await tester.pumpAndSettle();
        expect(
          find.text('Status could not refresh. Last known details are shown.'),
          findsOneWidget,
        );
        expect(retry.hitTestable(), findsOneWidget);
        await capture(tester, 'r669-deliveries-refresh-${failure.name}');
        adapter.state = BuyV2CommerceLoadState.ready;
        await tester.tap(retry);
        await tester.pumpAndSettle();
        expect(
          session.orderRefreshState('quick-1'),
          BuyV2CommerceLoadState.ready,
        );
        expect(
          find.byKey(const ValueKey('buy-delivery-refresh-message')),
          findsNothing,
        );
        expect(
          find.descendant(of: panel, matching: find.text('quick-1')),
          findsOneWidget,
        );
        expect(session.orders, hasLength(4));
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'R669 delivery artwork follows catalogue modes and supplied fulfilment',
    () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      session.openDestination(BuyV2Destination.wholesale);
      for (final type in BuyV2WholesaleSaleType.values) {
        session.chooseWholesaleSaleType(type);
        final products = session.catalogueSaleTypeProducts;
        expect(products, isNotEmpty);
        for (final product in products) {
          final expected = type == BuyV2WholesaleSaleType.wholesale
              ? BuyV2DeliveryArtwork.wholesale
              : BuyV2DeliveryArtwork.bulk;
          expect(buyV2DeliveryArtworkFor(product), expected);
          for (final quantity in [product.minimumOrder, 999999999]) {
            expect(
              buyV2DeliveryArtworkForLines([
                BuyV2CartLine(product: product, quantity: quantity),
              ], fulfilmentModeFor: session.fulfilmentModeFor),
              expected,
            );
          }
        }
      }
      final quick = session.product('s-tomato');
      expect(buyV2DeliveryArtworkFor(quick), BuyV2DeliveryArtwork.quick);
      expect(
        buyV2DeliveryArtworkFor(
          quick,
          fulfilmentMode: BuyV2FulfilmentMode.standardCourier,
        ),
        BuyV2DeliveryArtwork.courier,
      );
      expect(
        buyV2DeliveryArtworkForLines(
          const [],
          fulfilmentModeFor: session.fulfilmentModeFor,
        ),
        BuyV2DeliveryArtwork.courier,
      );
      expect(
        buyV2DeliveryArtworkForLines([
          BuyV2CartLine(product: quick, quantity: 1),
          BuyV2CartLine(product: session.product('w-rice'), quantity: 4),
        ], fulfilmentModeFor: session.fulfilmentModeFor),
        BuyV2DeliveryArtwork.courier,
      );
    },
  );

  testWidgets('R669 delivery artwork actual-size visual reference', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('r66-order-state-app-capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          home: Scaffold(
            body: Column(
              children: [
                for (final artwork in BuyV2DeliveryArtwork.values)
                  for (final dark in [false, true])
                    ColoredBox(
                      color: dark ? BuyV2Colors.navy : Colors.white,
                      child: SizedBox(
                        height: 50,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Text(
                                artwork.name,
                                style: TextStyle(
                                  color: dark ? Colors.white : BuyV2Colors.navy,
                                ),
                              ),
                            ),
                            for (final size in [
                              14.0,
                              16.0,
                              18.0,
                              20.0,
                              32.0,
                              48.0,
                            ]) ...[
                              BuyV2DeliveryModeIcon(
                                artwork: artwork,
                                size: size,
                                color: dark ? Colors.white : BuyV2Colors.navy,
                              ),
                              const SizedBox(width: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'r669-delivery-artwork-reference');
  });

  for (final entry in [
    ('s-tomato', BuyV2DeliveryArtwork.quick),
    ('w-notebook', BuyV2DeliveryArtwork.wholesale),
    ('w-rice', BuyV2DeliveryArtwork.bulk),
  ]) {
    for (final size in [const Size(320, 711), const Size(711, 320)]) {
      for (final scale in [1.0, 2.0]) {
        final profile = '${entry.$1}-${size.width.toInt()}-$scale';
        testWidgets(
          'R669 delivery artwork product checkout tracking $profile',
          (tester) async {
            await tester.binding.setSurfaceSize(size);
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final core = BuySession();
            final session = BuyV2Session(
              core: core,
              productFactsAdapter: _R669DeliveryIconFacts(),
            );
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            final product = session.product(entry.$1);
            Finder artworkWithin(Finder owner) => find.descendant(
              of: owner,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is BuyV2DeliveryModeIcon &&
                    widget.artwork == entry.$2,
              ),
            );
            await tester.pumpWidget(app(session, scale));
            await tester.pumpAndSettle();
            expect(session.openProduct(product.id), isTrue);
            await tester.pumpAndSettle();
            final hero = find.byKey(
              ValueKey('buy-automatic-fulfilment-${product.id}'),
            );
            await tester.scrollUntilVisible(
              hero,
              140,
              scrollable: find
                  .descendant(
                    of: find.byKey(PageStorageKey('buy-product-${product.id}')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.pumpAndSettle();
            expect(
              find.descendant(
                of: hero,
                matching: find.text(
                  buyV2FulfilmentModeLabel(session.fulfilmentModeFor(product)),
                ),
              ),
              findsOneWidget,
            );
            await capture(tester, 'r669-delivery-$profile-product');
            expect(session.addProduct(product.id), isTrue);
            session.openCart(
              scope: product.destination == BuyV2Destination.shop
                  ? BuyV2CartScope.shop
                  : BuyV2CartScope.wholesale,
            );
            expect(session.openCheckout(), isTrue);
            expect(session.continueCheckoutFromAddress(), isTrue);
            expect(session.continueCheckoutFromPayment(), isTrue);
            await tester.pumpAndSettle();
            final group = session.checkoutFulfilmentGroups.single;
            final shipment = find.byKey(
              ValueKey('buy-checkout-confirm-delivery-${group.key}'),
            );
            await tester.scrollUntilVisible(
              shipment,
              100,
              scrollable: find
                  .descendant(
                    of: find.byKey(
                      const PageStorageKey('buy-checkout-unified'),
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.pumpAndSettle();
            expect(artworkWithin(shipment), findsOneWidget);
            expect(tester.getSize(artworkWithin(shipment)), const Size(18, 18));
            await capture(tester, 'r669-delivery-$profile-checkout');
            // Development checkout fixture only; no payment handoff is invoked.
            expect(session.confirmOrder(), isTrue);
            final order = session.confirmedOrders.single;
            expect(order.deliveryPartnerName, isNull);
            session.openDestination(product.destination);
            await tester.pumpAndSettle();
            final control = find.byKey(
              const ValueKey('buy-quick-delivery-toggle'),
            );
            expect(control.hitTestable(), findsOneWidget);
            expect(artworkWithin(control), findsOneWidget);
            await capture(tester, 'r669-delivery-$profile-control');
            await tester.tap(control);
            await tester.pumpAndSettle();
            {
              final expanded = find.byKey(
                const ValueKey('buy-quick-delivery-status-expanded'),
              );
              expect(artworkWithin(expanded), findsOneWidget);
              await capture(tester, 'r669-delivery-$profile-expanded');
              final keep = find.byKey(
                const ValueKey('buy-quick-delivery-keep'),
              );
              await tester.ensureVisible(keep);
              await tester.pumpAndSettle();
              expect(keep.hitTestable(), findsOneWidget);
              await tester.tap(keep);
              await tester.pumpAndSettle();
              expect(find.text('Kept'), findsOneWidget);
              final hide = find.byKey(
                const ValueKey('buy-quick-delivery-hide'),
              );
              await tester.ensureVisible(hide);
              await tester.pumpAndSettle();
              expect(hide.hitTestable(), findsOneWidget);
              await capture(tester, 'r669-delivery-$profile-scrolled-controls');
              final open = find.byKey(
                const ValueKey('buy-quick-delivery-open'),
              );
              await tester.ensureVisible(open);
              await tester.pumpAndSettle();
              expect(open.hitTestable(), findsOneWidget);
              await tester.tap(open);
              await tester.pumpAndSettle();
            }
            expect(session.view, BuyV2View.tracking);
            expect(session.selectedOrderOrNull?.id, order.id);
            expect(session.selectedOrderOrNull?.deliveryPartnerName, isNull);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }

  for (final behavior in ['progress', 'keep', 'hide']) {
    testWidgets('R5 delivery 011 reproduces $behavior', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final core = BuySession();
      final session = _R66TrackingSession(
        core: core,
        order: _r66Order(BuyV2OrderStatus.preparing, BuyV2Destination.shop),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session, 1));
      await tester.pumpAndSettle();
      if (behavior == 'progress') {
        final progress = find.byKey(
          const ValueKey('buy-quick-delivery-compact-progress'),
        );
        expect(progress, findsOneWidget);
        expect(
          tester.widget<BuyV2HonestProgressIndicator>(progress).progress,
          .4,
        );
      } else {
        await tester.tap(
          find.byKey(const ValueKey('buy-quick-delivery-toggle')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('buy-quick-delivery-$behavior')));
        await tester.pumpAndSettle();
        if (behavior == 'keep') {
          await tester.pump(const Duration(seconds: 46));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
            findsOneWidget,
          );
        } else {
          expect(
            find.byKey(const ValueKey('buy-quick-delivery-toggle')),
            findsOneWidget,
          );
          expect(session.openTracking(session.order.id), isTrue);
          await tester.pumpAndSettle();
          final restore = find.byKey(
            const ValueKey('buy-quick-delivery-restore'),
          );
          expect(restore, findsOneWidget);
          await tester.tap(restore);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.tracking);
          session.returnToOrders();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-quick-delivery-toggle')),
            findsOneWidget,
          );
        }
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(320, 780),
    const Size(360, 800),
    const Size(430, 932),
    const Size(640, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R5 delivery 011 choices ${size.width}x${size.height} at $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final core = BuySession();
          final session = _R66TrackingSession(
            core: core,
            order: _r66Order(BuyV2OrderStatus.preparing, BuyV2Destination.shop),
          );
          final sound = _R5ArrivalSound();
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await tester.pumpWidget(app(session, scale, sound: sound));
          await tester.pumpAndSettle();
          final prefix =
              'r5-delivery-${size.width.toInt()}x${size.height.toInt()}-$scale';
          final toggle = find.byKey(
            const ValueKey('buy-quick-delivery-toggle'),
          );
          expect(tester.getSize(toggle), const Size(44, 44));
          await capture(tester, '$prefix-compact');
          await tapDelivery(tester, 'toggle');
          await capture(tester, '$prefix-expanded');
          await tapDelivery(tester, 'keep');
          await tester.pump(const Duration(seconds: 46));
          await tester.pumpAndSettle();
          expect(find.text('Kept'), findsOneWidget);
          expect(session.addProduct('s-tomato'), isTrue);
          final quantity = session.quantityFor('s-tomato');
          session.openDestination(BuyV2Destination.wholesale);
          await tester.pumpAndSettle();
          expect(find.text('Kept'), findsOneWidget);
          await capture(tester, '$prefix-kept-wholesale-cart');
          await tapDelivery(tester, 'sound');
          expect(sound.preparations, 1);
          expect(sound.plays, 0);
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const ValueKey('buy-quick-delivery-sound')),
                )
                .isSelected,
            isTrue,
          );
          await capture(tester, '$prefix-sound-on');
          await tapDelivery(tester, 'hide');
          expect(toggle, findsOneWidget);
          expect(session.quantityFor('s-tomato'), quantity);
          await capture(tester, '$prefix-hidden');
          expect(session.openTracking(session.order.id), isTrue);
          await tester.pumpAndSettle();
          expect(toggle, findsNothing);
          await capture(tester, '$prefix-tracking-restore');
          await tapDelivery(tester, 'restore');
          expect(session.view, BuyV2View.tracking);
          session.returnToOrders();
          await tester.pumpAndSettle();
          expect(toggle, findsOneWidget);
          await tapDelivery(tester, 'toggle');
          expect(find.text('Keep'), findsOneWidget);
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const ValueKey('buy-quick-delivery-sound')),
                )
                .isSelected,
            isTrue,
          );
          await tapDelivery(tester, 'sound');
          expect(sound.plays, 0);
          expect(sound.stops, greaterThan(0));
          await capture(tester, '$prefix-restored-sound-off');
          final panel = find.byKey(
            const ValueKey('buy-quick-delivery-status-expanded'),
          );
          final progressSurface = find.descendant(
            of: panel,
            matching: find.byType(BuyV2HonestProgressIndicator),
          );
          await tester.ensureVisible(progressSurface);
          await tester.pumpAndSettle();
          final gesture = await tester.startGesture(
            tester.getCenter(progressSurface),
          );
          await tester.pump(const Duration(seconds: 46));
          expect(panel, findsOneWidget);
          await gesture.up();
          await tester.pump(const Duration(seconds: 44));
          expect(panel, findsOneWidget);
          await tester.pump(const Duration(seconds: 2));
          await tester.pumpAndSettle();
          expect(panel, findsNothing);
          expect(
            tester
                .widget<BuyV2HonestProgressIndicator>(
                  find.byKey(
                    const ValueKey('buy-quick-delivery-compact-progress'),
                  ),
                )
                .progress,
            .4,
          );
          expect(session.quantityFor('s-tomato'), quantity);
          await capture(tester, '$prefix-automatic-collapse');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final scenario in [
    'arriving',
    'delivered',
    'off',
    'background',
    'already-arriving',
    'failure',
    'pending-background',
    'pending-dispose',
    'prepare-unavailable',
    'prepare-timeout',
  ]) {
    testWidgets('R5 delivery 011 sound $scenario', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final core = BuySession();
      final session = _R66TrackingSession(
        core: core,
        order: _r66Order(
          scenario == 'already-arriving'
              ? BuyV2OrderStatus.arriving
              : BuyV2OrderStatus.dispatched,
          BuyV2Destination.shop,
        ),
      );
      final sound = _R5ArrivalSound()
        ..playable = scenario != 'failure'
        ..ready = scenario != 'prepare-unavailable';
      if (scenario.startsWith('pending') || scenario == 'prepare-timeout') {
        sound.preparation = Completer<bool>();
      }
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session, 1, sound: sound));
      await tester.pumpAndSettle();
      await tapDelivery(tester, 'toggle');
      await tapDelivery(tester, 'sound');
      expect(sound.plays, 0, reason: 'Selecting sound is not an arrival.');
      if (scenario.startsWith('pending')) {
        expect(find.byTooltip('Setting arrival sound'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(
                find.byKey(const ValueKey('buy-quick-delivery-sound')),
              )
              .onPressed,
          isNull,
        );
        if (scenario == 'pending-dispose') {
          await tester.pumpWidget(const SizedBox.shrink());
        } else {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pump();
        }
        sound.preparation!.complete(true);
        await tester.pumpAndSettle();
        expect(sound.plays, 0);
        if (scenario == 'pending-background') {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const ValueKey('buy-quick-delivery-sound')),
                )
                .isSelected,
            isFalse,
          );
        } else {
          expect(sound.disposals, 1);
        }
      } else if (scenario == 'prepare-timeout' ||
          scenario == 'prepare-unavailable') {
        if (scenario == 'prepare-timeout') {
          await tester.pump(const Duration(seconds: 9));
          await tester.pumpAndSettle();
          sound.preparation!.complete(true);
          await tester.pumpAndSettle();
        }
        expect(find.text('Sound unavailable. Try again.'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(
                find.byKey(const ValueKey('buy-quick-delivery-sound')),
              )
              .isSelected,
          isFalse,
        );
        expect(sound.plays, 0);
        await capture(tester, 'r5-delivery-sound-$scenario');
      } else {
        if (scenario == 'off') await tapDelivery(tester, 'sound');
        if (scenario == 'background') {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
        }
        session.updateOrder(
          _r66Order(
            scenario == 'delivered'
                ? BuyV2OrderStatus.delivered
                : BuyV2OrderStatus.arriving,
            BuyV2Destination.shop,
          ),
        );
        await tester.pumpAndSettle();
        final expected =
            ['off', 'background', 'already-arriving'].contains(scenario)
            ? 0
            : 1;
        expect(sound.plays, expected);
        session.updateOrder(session.order);
        await tester.pumpAndSettle();
        if (scenario == 'background') {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();
        }
        session.openOrders();
        await tester.pumpAndSettle();
        expect(
          sound.plays,
          expected,
          reason: 'Rebuild, Back and resume must not replay.',
        );
        if (scenario == 'failure') {
          await tapDelivery(tester, 'toggle');
          expect(find.text('Sound unavailable. Try again.'), findsOneWidget);
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const ValueKey('buy-quick-delivery-sound')),
                )
                .isSelected,
            isFalse,
          );
          await capture(tester, 'r5-delivery-sound-playback-unavailable');
        }
        if (scenario == 'arriving') {
          session.updateOrder(
            _r66Order(BuyV2OrderStatus.dispatched, BuyV2Destination.shop),
          );
          session.updateOrder(
            _r66Order(BuyV2OrderStatus.arriving, BuyV2Destination.shop),
          );
          session.updateOrder(
            _r66Order(BuyV2OrderStatus.delivered, BuyV2Destination.shop),
          );
          await tester.pumpAndSettle();
          expect(sound.plays, 1, reason: 'One arrival cue for this order.');
        }
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final failure in [false, true]) {
    test(
      'R5 delivery 011 local cue file and cleanup playbackFailure=$failure',
      () async {
        final root = await Directory(
          'build/r66-r5-delivery-audio-fixtures',
        ).create(recursive: true);
        final player = _R5CuePlayer()..failPlayback = failure;
        final sound = BuyV2LocalDeliveryArrivalSound(
          temporaryDirectory: () async => root,
          playerFactory: () => player,
          supportedPlatform: true,
        );
        expect(await sound.prepare(), isTrue);
        expect(player.plays, 0);
        final wave = player.wave!;
        expect(wave.length, 12844);
        expect(String.fromCharCodes(wave.take(4)), 'RIFF');
        expect(String.fromCharCodes(wave.sublist(8, 12)), 'WAVE');
        expect(String.fromCharCodes(wave.sublist(36, 40)), 'data');
        expect(wave.sublist(20, 24), [1, 0, 1, 0]);
        expect(wave.sublist(34, 36), [16, 0]);
        expect(wave.skip(44).any((value) => value != 0), isTrue);
        expect(await sound.play(), !failure);
        expect(player.plays, 1);
        expect(player.disposals, 1);
        expect(await File(player.loadedPath!).exists(), isFalse);
        await sound.dispose();
        expect(await sound.prepare(), isFalse);
      },
    );
  }

  test('R5 delivery 011 unsupported platform never loads or plays', () async {
    final sound = BuyV2LocalDeliveryArrivalSound(
      supportedPlatform: false,
      temporaryDirectory: () => throw StateError('Must not read storage'),
      playerFactory: () => throw StateError('Must not create a player'),
    );
    expect(await sound.prepare(), isFalse);
    expect(await sound.play(), isFalse);
    await sound.dispose();
  });

  for (final size in [const Size(320, 780), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R5 delivery 011 keyboard ${size.width} at $scale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final core = BuySession();
        final session = _R66TrackingSession(
          core: core,
          order: _r66Order(BuyV2OrderStatus.preparing, BuyV2Destination.shop),
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        final bottom = size.width > size.height ? 140.0 : 260.0;
        final sound = _R5ArrivalSound();
        await tester.pumpWidget(
          app(
            session,
            scale,
            sound: sound,
            insets: EdgeInsets.only(bottom: bottom),
          ),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(const ValueKey('buy-quick-delivery-toggle'));
        expect(toggle.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(toggle).bottom,
          lessThanOrEqualTo(size.height - bottom),
        );
        await tapDelivery(tester, 'toggle');
        await tapDelivery(tester, 'keep');
        await tester.pump(const Duration(seconds: 46));
        await tester.pumpAndSettle();
        final kept = find.byKey(const ValueKey('buy-quick-delivery-keep'));
        await tester.ensureVisible(kept);
        await tester.pumpAndSettle();
        expect(kept.hitTestable(), findsOneWidget);
        await capture(
          tester,
          'r5-delivery-keyboard-${size.width.toInt()}-$scale-kept',
        );
        await tapDelivery(tester, 'hide');
        expect(toggle, findsOneWidget);
        await tester.pumpWidget(app(session, scale, sound: sound));
        await tester.pumpAndSettle();
        expect(toggle, findsOneWidget);
        expect(session.openTracking(session.order.id), isTrue);
        await tester.pumpAndSettle();
        await tapDelivery(tester, 'restore');
        session.returnToOrders();
        await tester.pumpAndSettle();
        expect(toggle.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final interruption in ['background', 'dispose', 'session']) {
    testWidgets('R5 delivery 011 playing cancellation $interruption', (
      tester,
    ) async {
      final core = BuySession();
      final session = _R66TrackingSession(
        core: core,
        order: _r66Order(BuyV2OrderStatus.dispatched, BuyV2Destination.shop),
      );
      final sound = _R5ArrivalSound()..playback = Completer<bool>();
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session, 1, sound: sound));
      await tester.pumpAndSettle();
      await tapDelivery(tester, 'toggle');
      await tapDelivery(tester, 'sound');
      session.updateOrder(
        _r66Order(BuyV2OrderStatus.arriving, BuyV2Destination.shop),
      );
      await tester.pumpAndSettle();
      expect(sound.plays, 1);
      if (interruption == 'background') {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        expect(sound.stops, greaterThan(0));
      } else if (interruption == 'dispose') {
        await tester.pumpWidget(const SizedBox.shrink());
        expect(sound.disposals, 1);
      } else {
        final replacementCore = BuySession();
        final replacement = _R66TrackingSession(
          core: replacementCore,
          order: _r66Order(BuyV2OrderStatus.arriving, BuyV2Destination.shop),
        );
        addTearDown(replacementCore.dispose);
        addTearDown(replacement.dispose);
        await tester.pumpWidget(app(replacement, 1, sound: sound));
        await tester.pumpAndSettle();
        await tapDelivery(tester, 'toggle');
        expect(
          tester
              .widget<IconButton>(
                find.byKey(const ValueKey('buy-quick-delivery-sound')),
              )
              .isSelected,
          isFalse,
        );
      }
      sound.playback!.complete(false);
      await tester.pumpAndSettle();
      if (interruption == 'background') {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
      }
      expect(sound.plays, 1);
      expect(
        find.text('Sound unavailable. Try again.'),
        findsNothing,
        reason: 'A cancelled old operation cannot change the current UI.',
      );
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'R5 delivery 011 cancellation retires a pending native load once',
    () async {
      final root = await Directory(
        'build/r66-r5-delivery-audio-fixtures',
      ).create(recursive: true);
      final player = _R5CuePlayer()..loadGate = Completer<Duration?>();
      final sound = BuyV2LocalDeliveryArrivalSound(
        temporaryDirectory: () async => root,
        playerFactory: () => player,
        supportedPlatform: true,
      );
      final preparation = sound.prepare();
      await player.loaded.future.timeout(const Duration(seconds: 3));
      await sound.stop();
      player.loadGate!.complete(const Duration(milliseconds: 400));
      expect(await preparation, isFalse);
      expect(player.plays, 0);
      expect(player.disposals, 1);
      expect(await File(player.loadedPath!).exists(), isFalse);
      await sound.dispose();
    },
  );

  for (final status in BuyV2OrderStatus.values) {
    for (final scale in [1.0, 2.0]) {
      if (status != BuyV2OrderStatus.delivered) {
        testWidgets(
          'R66 active delivery stays truthful for ${status.name} at $scale',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(320, 844));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final core = BuySession();
            final order = _r66Order(status, BuyV2Destination.shop);
            final session = _R66TrackingSession(core: core, order: order);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            await tester.pumpWidget(app(session, scale));
            await tester.pumpAndSettle();
            final bar = find.byKey(
              const ValueKey('buy-quick-delivery-status-minimized'),
            );
            expect(bar, findsOneWidget);
            final toggle = find.byKey(
              const ValueKey('buy-quick-delivery-toggle'),
            );
            expect(tester.getSize(toggle), const Size(44, 44));
            final semantics = tester.ensureSemantics();
            late String announcement;
            try {
              announcement = tester.getSemantics(bar).getSemanticsData().label;
            } finally {
              semantics.dispose();
            }
            expect(announcement, contains('Delivery in 12 min · by 6:35 PM'));
            expect(announcement, isNot(contains('Delivered')));
            expect(announcement, contains(order.id));
            expect(tester.getSize(bar).width, lessThanOrEqualTo(48));
            await capture(tester, 'active-${status.name}-$scale-collapsed');
            await tester.tap(toggle);
            await tester.pumpAndSettle();
            final expanded = find.byKey(
              const ValueKey('buy-quick-delivery-status-expanded'),
            );
            expect(expanded, findsOneWidget);
            expect(find.text(order.id), findsOneWidget);
            expect(
              find.textContaining('Delivery in 12 min · by 6:35 PM'),
              findsOneWidget,
            );
            final labels = find.descendant(
              of: expanded,
              matching: find.byType(Text),
            );
            expect(labels, findsWidgets);
            for (final text in tester.widgetList<Text>(labels)) {
              expect(text.data, isNot(contains('Delivered')));
            }
            for (final element in labels.evaluate()) {
              final paragraph = element.renderObject! as RenderParagraph;
              expect(
                paragraph.didExceedMaxLines,
                isFalse,
                reason:
                    'label=${paragraph.text.toPlainText()} available=${paragraph.size.width} '
                    'panel=${tester.getSize(expanded).width}',
              );
            }
            await capture(tester, 'active-${status.name}-$scale-expanded');
            final hide = find.byKey(const ValueKey('buy-quick-delivery-hide'));
            await tester.tap(hide);
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('buy-quick-delivery-toggle')),
              findsOneWidget,
            );
            expect(session.openTracking(order.id), isTrue);
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('buy-quick-delivery-restore')),
            );
            await tester.pumpAndSettle();
            session.returnToOrders();
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('buy-quick-delivery-toggle')),
            );
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('buy-quick-delivery-open')),
            );
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.tracking);
            expect(session.selectedOrderId, order.id);
            expect(order.promise, 'Delivered in 12 min');
            expect(order.promisedByLabel, 'by 6:35 PM');
            expect(tester.takeException(), isNull);
          },
        );
      }
      for (final destination in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        testWidgets(
          'R66 route is not travel progress for ${destination.name} ${status.name} at $scale',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(320, 844));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final core = BuySession();
            final order = _r66Order(status, destination);
            final session = _R66TrackingSession(core: core, order: order);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            await tester.pumpWidget(app(session, scale));
            expect(session.openTracking(order.id), isTrue);
            await tester.pumpAndSettle();
            final route = find.byKey(const ValueKey('buy-tracking-route'));
            await tester.scrollUntilVisible(
              route,
              220,
              scrollable: find
                  .descendant(
                    of: find.byKey(PageStorageKey('buy-tracking-${order.id}')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            expect(
              find.descendant(
                of: route,
                matching: find.byType(BuyV2HonestProgressIndicator),
              ),
              findsNothing,
            );
            expect(
              find.descendant(
                of: route,
                matching: find.byType(LinearProgressIndicator),
              ),
              findsNothing,
            );
            for (final value in [order.partner, order.destinationLabel]) {
              final text = find.descendant(
                of: route,
                matching: find.text(value),
              );
              expect(text, findsOneWidget);
              expect(
                tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
                isFalse,
              );
            }
            expect(session.selectedOrderOrNull.status, status);
            expect(session.selectedOrderOrNull.progress, order.progress);
            await capture(
              tester,
              'route-${destination.name}-${status.name}-$scale',
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  group('Buy V2 order progress integrity', () {
    late BuyV2Session session;

    setUp(() {
      session = BuyV2Session(core: BuySession());
    });

    test('every established order is complete and progress is truthful', () {
      final ids = <String>{};

      for (final order in session.orders) {
        expect(order.id.trim(), isNotEmpty);
        expect(ids.add(order.id), isTrue, reason: order.id);
        expect(
          order.destination,
          isNot(BuyV2Destination.orders),
          reason: order.id,
        );
        expect(order.title.trim(), isNotEmpty, reason: order.id);
        expect(order.itemSummary.trim(), isNotEmpty, reason: order.id);
        expect(order.total, greaterThan(0), reason: order.id);
        expect(order.partner.trim(), isNotEmpty, reason: order.id);
        expect(order.partnerType, startsWith('Mool'), reason: order.id);
        expect(order.promise.trim(), isNotEmpty, reason: order.id);
        expect(order.destinationLabel.trim(), isNotEmpty, reason: order.id);
        expect(order.progress, greaterThan(0), reason: order.id);
        expect(order.progress, lessThanOrEqualTo(1), reason: order.id);

        if (order.status == BuyV2OrderStatus.delivered) {
          expect(order.progress, 1, reason: order.id);
        } else {
          expect(order.progress, lessThan(1), reason: order.id);
        }

        for (final productId in order.productIds) {
          final product = session.findProduct(productId);
          expect(product, isNotNull, reason: '${order.id}: $productId');
          expect(
            product!.destination,
            order.destination,
            reason: '${order.id}: $productId',
          );
        }
      }
    });

    test('Active and Delivered partition history without loss', () {
      final shopOrders = session.orders
          .where((order) => order.destination != BuyV2Destination.medicine)
          .toList(growable: false);
      final allIds = shopOrders.map((order) => order.id).toSet();
      final expectedActive = shopOrders
          .where((order) => order.status != BuyV2OrderStatus.delivered)
          .map((order) => order.id)
          .toSet();
      final expectedDelivered = shopOrders
          .where((order) => order.status == BuyV2OrderStatus.delivered)
          .map((order) => order.id)
          .toSet();

      session.showOrdersTab(BuyV2OrdersTab.active);
      final activeIds = session.visibleOrders.map((order) => order.id).toSet();
      session.showOrdersTab(BuyV2OrdersTab.delivered);
      final deliveredIds = session.visibleOrders
          .map((order) => order.id)
          .toSet();

      expect(activeIds, expectedActive);
      expect(deliveredIds, expectedDelivered);
      expect(activeIds.intersection(deliveredIds), isEmpty);
      expect(activeIds.union(deliveredIds), allIds);
      expect(session.activeOrderCount, activeIds.length);
      expect(session.deliveredOrderCount, deliveredIds.length);

      expect(
        session.visibleOrders,
        everyElement(
          isA<BuyV2Order>().having(
            (order) => order.destination,
            'destination',
            isNot(BuyV2Destination.medicine),
          ),
        ),
      );

      for (final order in shopOrders) {
        session.showOrdersTab(
          order.status == BuyV2OrderStatus.delivered
              ? BuyV2OrdersTab.delivered
              : BuyV2OrdersTab.active,
        );
        session.updateQuery(order.id.toLowerCase());
        expect(session.visibleOrders.map((candidate) => candidate.id), [
          order.id,
        ], reason: order.id);
      }

      session.updateQuery('missing-order-id');
      expect(session.visibleOrders, isEmpty);
    });

    test('mixed confirmation creates exact live vertical orders', () {
      final core = BuySession();
      final session = BuyV2Session(
        core: core,
        productFactsAdapter: _R669DeliveryIconFacts(),
      );
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final selected = {
        for (final destination in const [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        ])
          destination: BuyV2Catalogue.products.firstWhere(
            (product) =>
                product.destination == destination &&
                !product.requiresPrescription,
          ),
      };
      for (final product in selected.values) {
        expect(session.addProduct(product.id), isTrue);
      }
      session.openCart();
      session.openCheckout();

      final expectedTotals = {
        for (final entry in selected.entries)
          entry.key: entry.value.price * entry.value.minimumOrder,
      };

      expect(session.confirmOrder(), isTrue, reason: session.notice);

      expect(session.confirmedOrders, hasLength(3));
      expect(session.confirmedDestinations, selected.keys.toSet());
      for (final order in session.confirmedOrders) {
        final product = selected[order.destination]!;
        final expectedPrefix = switch (order.destination) {
          BuyV2Destination.shop => 'MS-NEW-',
          BuyV2Destination.wholesale => 'PO-NEW-',
          BuyV2Destination.medicine => 'RX-NEW-',
          BuyV2Destination.orders => throw StateError(
            'Orders cannot own a product order.',
          ),
        };
        expect(order.id, startsWith(expectedPrefix));
        expect(order.productIds, [product.id]);
        expect(order.total, expectedTotals[order.destination]);
        expect(order.progress, greaterThan(0));
        expect(order.progress, lessThan(1));
        expect(order.status, isNot(BuyV2OrderStatus.delivered));
        expect(session.productsForOrder(order).map((item) => item.id), [
          product.id,
        ]);
        expect(session.openTracking(order.id), isTrue);
        expect(session.selectedOrder.id, order.id);
        expect(session.selectedOrder.progress, order.progress);
      }

      session.showOrdersTab(BuyV2OrdersTab.active);
      final shopConfirmedIds = session.confirmedOrders
          .where((order) => order.destination != BuyV2Destination.medicine)
          .map((order) => order.id)
          .toSet();
      expect(
        session.visibleOrders.map((order) => order.id).toSet(),
        containsAll(shopConfirmedIds),
      );
      expect(
        session.visibleOrders,
        everyElement(
          isA<BuyV2Order>().having(
            (order) => order.destination,
            'destination',
            isNot(BuyV2Destination.medicine),
          ),
        ),
      );
      session.showOrdersTab(BuyV2OrdersTab.delivered);
      expect(
        session.visibleOrders
            .map((order) => order.id)
            .toSet()
            .intersection(shopConfirmedIds),
        isEmpty,
      );
    });
  });
}
