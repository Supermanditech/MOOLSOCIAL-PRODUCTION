import 'dart:async';

import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

/// Isolated payment-route publications; never injected into native review data.
List<BuyV2Product> get testPaymentProducts => [
  for (final product in BuyV2Catalogue.allProducts)
    product.copyWith(storeId: product.storeId ?? 'test-payment-store'),
];

class TestPaymentCommerce implements BuyV2CommerceAdapter {
  BuyV2CommerceSnapshot snapshot = BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: testPaymentProducts,
    paymentMethods: {'UPI', 'Card'},
  );
  Completer<BuyV2CommerceSnapshot>? refreshGate;
  Completer<BuyV2OrderPlacementResult>? placementGate;
  final requests = <BuyV2OrderPlacementRequest>[];

  @override
  Future<BuyV2CommerceSnapshot> refresh() async =>
      refreshGate == null ? snapshot : refreshGate!.future;

  @override
  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  ) async {
    requests.add(request);
    return placementGate == null
        ? const BuyV2OrderPlacementResult(
            outcome: BuyV2OrderPlacementOutcome.paymentPending,
            customerMessage: 'Isolated test payment pending.',
            paymentReference: 'test-pending',
          )
        : placementGate!.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected isolated payment fixture operation');
}

BuyV2PaymentCapability testPaymentCapability(
  BuyV2Session session, {
  String method = 'UPI',
  int? minimumMinor,
  int? maximumMinor,
  int? remainingMinor,
  String currency = 'INR',
  Set<String>? fulfilmentKeys,
  String revision = 'test-route-v1',
  DateTime? validFrom,
  DateTime? validUntil,
  String? collectionStoreId,
}) => BuyV2PaymentCapability(
  method: method,
  sourceId: 'isolated-test-commerce',
  revision: revision,
  fulfilmentKeys:
      fulfilmentKeys ??
      session.checkoutFulfilmentGroups.map((g) => g.key).toSet(),
  validFrom:
      validFrom ?? session.catalogueNow().subtract(const Duration(minutes: 1)),
  validUntil:
      validUntil ?? session.catalogueNow().add(const Duration(hours: 1)),
  currency: currency,
  collectionStoreId: collectionStoreId,
  recipientName: 'Test purchase recipient',
  minimumMinor: minimumMinor,
  maximumMinor: maximumMinor,
  remainingMinor: remainingMinor,
);

BuyV2CommerceSnapshot testPaymentSnapshot(
  List<BuyV2PaymentCapability>? capabilities, {
  Set<String> methods = const {'UPI', 'Card'},
  List<BuyV2Address> addresses = const [],
}) => BuyV2CommerceSnapshot(
  state: BuyV2CommerceLoadState.ready,
  products: testPaymentProducts,
  paymentMethods: methods,
  paymentCapabilities: capabilities,
  businessVerified: true,
  addresses: addresses,
  selectedAddressId: addresses.isEmpty ? null : addresses.first.id,
);

class TestPaymentQuote implements BuyV2CheckoutQuoteAdapter {
  int charge = 0;
  Completer<void>? gate;
  List<BuyV2CheckoutPaymentGroup> Function(
    List<BuyV2CheckoutQuoteLine>,
    String,
  )?
  groupsFor;
  @override
  Future<BuyV2CheckoutQuoteSnapshot> loadQuote({
    required List<BuyV2FulfilmentGroup> groups,
    required BuyV2Address address,
    required String selectedPaymentMethod,
    required List<BuyV2CartBenefit> selectedBenefits,
    required Map<String, int> tipAmountsByFulfilmentKey,
  }) async {
    if (gate != null) await gate!.future;
    final now = DateTime.now();
    final lines = [
      for (var i = 0; i < groups.length; i++)
        BuyV2CheckoutQuoteLine(
          fulfilmentKey: groups[i].key,
          itemSubtotal: groups[i].total,
          couponSaving: 0,
          tax: 0,
          freight: 0,
          deliveryFee: 0,
          tip: tipAmountsByFulfilmentKey[groups[i].key] ?? 0,
          paymentCharge: i == 0 ? charge : 0,
          total:
              groups[i].total +
              (tipAmountsByFulfilmentKey[groups[i].key] ?? 0) +
              (i == 0 ? charge : 0),
        ),
    ];
    return BuyV2CheckoutQuoteSnapshot(
      state: BuyV2CommerceLoadState.ready,
      quote: BuyV2CheckoutQuote(
        id: 'test-current-quote',
        sourceId: 'isolated-test-commerce',
        evaluatedAt: now,
        validUntil: now.add(const Duration(hours: 1)),
        lines: lines,
        total: lines.fold(0, (total, line) => total + line.total),
        paymentGroups: groupsFor?.call(lines, selectedPaymentMethod),
      ),
    );
  }
}

/// Isolated group connector. Never installed in native review or live commerce.
class TestLegacyRecoveryCommerce extends TestPaymentCommerce
    implements BuyV2PendingOrderRecoveryAdapter {
  final originalRequests = <String, BuyV2OrderPlacementRequest>{};
  final reconciledKeys = <String>[];
  final recoveredKeys = <String>[];
  FutureOr<BuyV2OrderPlacementResult> Function(BuyV2OrderPlacementRequest)?
  onPlace;
  FutureOr<BuyV2OrderPlacementResult> Function(BuyV2OrderPlacementRequest)?
  onReconcile;

  @override
  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  ) async {
    requests.add(request);
    originalRequests[request.idempotencyKey] = request;
    return onPlace == null
        ? testGroupedPlacement(
            request,
            outcome: BuyV2OrderPlacementOutcome.paymentPending,
            reference: 'test-legacy-${request.idempotencyKey}',
          )
        : await onPlace!(request);
  }

  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  }) async {
    reconciledKeys.add(idempotencyKey);
    return _recover(idempotencyKey);
  }

  @override
  Future<BuyV2OrderPlacementResult> recoverOrder({
    required String idempotencyKey,
  }) async {
    recoveredKeys.add(idempotencyKey);
    return _recover(idempotencyKey);
  }

  Future<BuyV2OrderPlacementResult> _recover(String key) async {
    final request = originalRequests[key];
    if (request == null) {
      return BuyV2OrderPlacementResult(
        outcome: BuyV2OrderPlacementOutcome.paymentUnknown,
        customerMessage: 'Original agreement unavailable in isolated fixture.',
        idempotencyKey: key,
      );
    }
    return onReconcile == null
        ? testGroupedPlacement(
            request,
            outcome: BuyV2OrderPlacementOutcome.paymentPending,
            reference: 'test-legacy-$key',
          )
        : await onReconcile!(request);
  }
}

/// Explicitly opted-in grouped fixture; no native/live injection.
class TestGroupedPaymentCommerce extends TestPaymentCommerce
    implements
        BuyV2GroupedOrderPlacementAdapter,
        BuyV2PendingOrderRecoveryAdapter {
  final originalRequests = <String, BuyV2OrderPlacementRequest>{};
  final reconciledKeys = <String>[];
  final recoveredKeys = <String>[];
  FutureOr<BuyV2OrderPlacementResult> Function(BuyV2OrderPlacementRequest)?
  onGroup;
  FutureOr<BuyV2OrderPlacementResult> Function(BuyV2OrderPlacementRequest)?
  onReconcile;

  @override
  Future<BuyV2OrderPlacementResult> placePaymentGroup(
    BuyV2OrderPlacementRequest request,
  ) async {
    requests.add(request);
    originalRequests[request.idempotencyKey] = request;
    return onGroup == null
        ? testGroupedPlacement(
            request,
            outcome: BuyV2OrderPlacementOutcome.paymentPending,
          )
        : await onGroup!(request);
  }

  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  }) async {
    reconciledKeys.add(idempotencyKey);
    final request = originalRequests[idempotencyKey]!;
    return onReconcile == null
        ? testGroupedPlacement(
            request,
            outcome: BuyV2OrderPlacementOutcome.paymentPending,
          )
        : await onReconcile!(request);
  }

  @override
  Future<BuyV2OrderPlacementResult> recoverOrder({
    required String idempotencyKey,
  }) async {
    recoveredKeys.add(idempotencyKey);
    final request = originalRequests[idempotencyKey]!;
    return onReconcile == null
        ? testGroupedPlacement(
            request,
            outcome: BuyV2OrderPlacementOutcome.paymentPending,
          )
        : await onReconcile!(request);
  }
}

BuyV2OrderPlacementResult testGroupedPlacement(
  BuyV2OrderPlacementRequest request, {
  BuyV2OrderPlacementOutcome outcome = BuyV2OrderPlacementOutcome.confirmed,
  String? groupId,
  int? paidNow,
  List<BuyV2Order>? orders,
  Map<String, (int, int)>? allocations,
  bool retryAllowed = false,
  String? reference,
}) => BuyV2OrderPlacementResult(
  outcome: outcome,
  customerMessage: 'Isolated grouped provider response.',
  checkoutAttemptId: request.checkoutAttemptId,
  paymentGroupId: groupId ?? request.paymentGroupId,
  idempotencyKey: request.idempotencyKey,
  retryAllowed: retryAllowed,
  purchaseReference: reference ?? request.checkoutAttemptId,
  paymentReference: 'test-${request.paymentGroupId ?? request.idempotencyKey}',
  paymentActionUri: outcome == BuyV2OrderPlacementOutcome.paymentActionRequired
      ? Uri.https('payments.example.test', '/group')
      : null,
  orders:
      orders ??
      (outcome == BuyV2OrderPlacementOutcome.confirmed
          ? [
              for (final lines
                  in allocations == null
                      ? [request.lines]
                      : [
                          for (final line in request.lines) [line],
                        ])
                BuyV2Order(
                  id: 'test-order-${request.idempotencyKey}-${lines.first.product.id}',
                  destination: lines.first.product.destination,
                  title: 'Test group order',
                  itemSummary: 'Isolated test lines',
                  total:
                      allocations?[lines.first.product.id]?.$1 ?? request.total,
                  partner: lines.first.product.seller,
                  partnerType: lines.first.product.sellerType,
                  promise: 'Test delivery promise',
                  destinationLabel: request.address.shortLine,
                  progress: 0,
                  status: BuyV2OrderStatus.preparing,
                  purchaseId: reference ?? request.checkoutAttemptId,
                  productIds: lines.map((line) => line.product.id).toList(),
                  lines: lines,
                  paymentMethod: request.paymentMethod,
                  amountPaidNow:
                      paidNow ??
                      allocations?[lines.first.product.id]?.$2 ??
                      request.amountDueNow,
                  balanceDue:
                      (allocations?[lines.first.product.id]?.$1 ??
                          request.total) -
                      (allocations?[lines.first.product.id]?.$2 ??
                          request.amountDueNow),
                  recipient: request.address.recipient,
                  addressLine: request.address.line,
                ),
            ]
          : const []),
);

class TestGroupedPaymentTerms implements BuyV2CommercialPaymentTermsAdapter {
  bool credit = false;
  @override
  Future<BuyV2CommercialPaymentTermsSnapshot> loadTerms({
    required List<BuyV2FulfilmentGroup> groups,
    required String selectedPaymentMethod,
    required Map<String, int> quotedTotalsByFulfilmentKey,
  }) async => BuyV2CommercialPaymentTermsSnapshot(
    state: BuyV2CommerceLoadState.ready,
    terms: [
      for (final group in groups)
        BuyV2CommercialPaymentTerm(
          id: 'test-term-${group.key}',
          fulfilmentKey: group.key,
          destination: group.destination,
          supplierName: group.partner,
          kind: group.destination != BuyV2Destination.wholesale
              ? BuyV2CommercialPaymentTermKind.retailAdvance
              : credit
              ? BuyV2CommercialPaymentTermKind.supplierCredit
              : BuyV2CommercialPaymentTermKind.wholesaleAdvance,
          orderTotal: quotedTotalsByFulfilmentKey[group.key]!,
          amountDueNow:
              credit && group.destination == BuyV2Destination.wholesale
              ? 0
              : quotedTotalsByFulfilmentKey[group.key]!,
          balanceDue: credit && group.destination == BuyV2Destination.wholesale
              ? quotedTotalsByFulfilmentKey[group.key]!
              : 0,
          balanceDueLabel: 'Test agreed balance',
          sourceId: 'isolated-test-terms',
          netDays: credit && group.destination == BuyV2Destination.wholesale
              ? 30
              : null,
        ),
    ],
  );
}

/// Simulated provider grants for named test SKUs only. These are not live
/// eligibility and do not enable the session's unrelated review-data shortcuts.
class QualifiedTestProductFacts implements BuyV2ProductFactsAdapter {
  const QualifiedTestProductFacts(this.productIds);
  final Set<String> productIds;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final facts = const BuyV2CatalogueProductFactsAdapter().snapshotFor(
      product,
    );
    if (!productIds.contains(product.id)) return facts;
    final now = DateTime.now();
    return facts.copyWith(
      eligibility: BuyV2OfferEligibility(
        productId: product.id,
        storeId: product.storeId!,
        sourceRevision: 'simulated-test-provider-v1',
        customerLocationKey: '||0',
        observedAt: now.subtract(const Duration(minutes: 1)),
        expiresAt: now.add(const Duration(hours: 1)),
        offerClass: product.offerClass!,
        channelEnabled: true,
        storeReady: true,
        fleetAvailable: false,
        customerLocationConfirmed: true,
        options: const {BuyV2DeliveryOption.courier},
      ),
    );
  }
}

/// Active campaigns for positive behavior tests only. Native review campaign
/// dates and live provider eligibility are never changed by this fixture.
class ActiveTestCartBenefits extends BuyV2SeededCartBenefitsAdapter {
  const ActiveTestCartBenefits();

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) => [
    for (final benefit in super.benefitsFor(
      kind: kind,
      destinations: destinations,
      itemTotal: itemTotal,
    ))
      BuyV2CartBenefit(
        id: benefit.id,
        kind: benefit.kind,
        destination: benefit.destination,
        title: benefit.title,
        detail: benefit.detail,
        sourceId: benefit.sourceId,
        strategy: benefit.strategy,
        sponsor: benefit.sponsor,
        sponsorName: benefit.sponsorName,
        savingAmount: benefit.savingAmount,
        validFrom: benefit.validFrom,
        validUntil: DateTime.now().add(const Duration(days: 1)),
        freeDelivery: benefit.freeDelivery,
        offerId: benefit.offerId,
        minimumSpend: benefit.minimumSpend,
        minimumQuantity: benefit.minimumQuantity,
        eligiblePaymentMethods: {
          for (final method in benefit.eligiblePaymentMethods)
            switch (method) {
              'PhonePe' => 'UPI',
              'Paytm' || 'Pine Labs' => 'Card',
              _ => method,
            },
        },
        scope: benefit.scope,
        storeId: benefit.storeId,
        productIds: benefit.productIds,
        revision: benefit.revision,
      ),
  ];
}

/// Deterministic substitute for the deferred Google location provider.
class TestCurrentLocationSource implements BuyV2ShoppingAreaSource {
  TestCurrentLocationSource(String region, String label)
    : area = BuyV2ShoppingArea(
        regionId: region,
        googlePlaceId: 'test-place-$region',
        label: label,
        countryCode: 'IN',
      );
  BuyV2ShoppingArea area;

  @override
  Future<BuyV2ShoppingArea?> locate() async => area;
  @override
  Future<BuyV2ShoppingArea?> resolve(String id) async =>
      id == area.googlePlaceId ? area : null;
  @override
  Future<List<BuyV2ShoppingArea>> search(String query) async =>
      throw StateError('The approved popup must request current location.');
}
