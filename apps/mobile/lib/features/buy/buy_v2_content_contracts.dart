import 'package:flutter/foundation.dart';

import 'buy_v2_cart_contracts.dart';
import 'buy_v2_models.dart';

@immutable
class BuyV2ProductFactsSnapshot {
  const BuyV2ProductFactsSnapshot({
    required this.productId,
    required this.price,
    required this.deliveryPromise,
    required this.partner,
    required this.orderabilityLabel,
    required this.sourceId,
    this.promisedByLabel,
    this.dispatchPromise,
    this.deliveryProviderName,
    this.deliveryServiceLevel,
    this.observedAt,
    this.stale = false,
  }) : assert(
         observedAt == null || sourceId != '',
         'Changing product facts require a named source.',
       );

  final String productId;
  final int price;
  final String deliveryPromise;
  final String partner;
  final String orderabilityLabel;
  final String sourceId;
  final String? promisedByLabel;
  final String? dispatchPromise;
  final String? deliveryProviderName;
  final String? deliveryServiceLevel;
  final DateTime? observedAt;
  final bool stale;

  bool get isLive => observedAt != null;

  BuyV2ProductFactsSnapshot copyWith({
    int? price,
    String? deliveryPromise,
    String? partner,
    String? orderabilityLabel,
    String? sourceId,
    String? promisedByLabel,
    String? dispatchPromise,
    String? deliveryProviderName,
    String? deliveryServiceLevel,
    DateTime? observedAt,
    bool? stale,
  }) {
    return BuyV2ProductFactsSnapshot(
      productId: productId,
      price: price ?? this.price,
      deliveryPromise: deliveryPromise ?? this.deliveryPromise,
      partner: partner ?? this.partner,
      orderabilityLabel: orderabilityLabel ?? this.orderabilityLabel,
      sourceId: sourceId ?? this.sourceId,
      promisedByLabel: promisedByLabel ?? this.promisedByLabel,
      dispatchPromise: dispatchPromise ?? this.dispatchPromise,
      deliveryProviderName: deliveryProviderName ?? this.deliveryProviderName,
      deliveryServiceLevel: deliveryServiceLevel ?? this.deliveryServiceLevel,
      observedAt: observedAt ?? this.observedAt,
      stale: stale ?? this.stale,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BuyV2ProductFactsSnapshot &&
        other.productId == productId &&
        other.price == price &&
        other.deliveryPromise == deliveryPromise &&
        other.partner == partner &&
        other.orderabilityLabel == orderabilityLabel &&
        other.sourceId == sourceId &&
        other.promisedByLabel == promisedByLabel &&
        other.dispatchPromise == dispatchPromise &&
        other.deliveryProviderName == deliveryProviderName &&
        other.deliveryServiceLevel == deliveryServiceLevel &&
        other.observedAt == observedAt &&
        other.stale == stale;
  }

  @override
  int get hashCode => Object.hash(
    productId,
    price,
    deliveryPromise,
    partner,
    orderabilityLabel,
    sourceId,
    promisedByLabel,
    dispatchPromise,
    deliveryProviderName,
    deliveryServiceLevel,
    observedAt,
    stale,
  );
}

abstract interface class BuyV2ProductFactsAdapter {
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product);
}

enum BuyV2CommerceLoadState { loading, ready, offline, unavailable }

enum BuyV2BusinessVerificationState { verified, pending, rejected, unavailable }

enum BuyV2OrderPlacementOutcome {
  paymentActionRequired,
  confirmed,
  paymentPending,
  paymentUnknown,
  cancelled,
  failed,
  unavailable,
}

enum BuyV2OrderPlacementFailureKind { stockUnavailable, serviceAreaUnavailable }

@immutable
class BuyV2CommerceSnapshot {
  const BuyV2CommerceSnapshot({
    required this.state,
    this.products = const [],
    this.addresses = const [],
    this.orders = const [],
    this.paymentMethods = const {},
    this.selectedAddressId,
    this.businessVerified = false,
    this.businessVerificationState = BuyV2BusinessVerificationState.unavailable,
    this.productReportsAvailable = false,
    this.reviewableProductIds = const {},
    this.customerMessage,
  });

  final BuyV2CommerceLoadState state;
  final List<BuyV2Product> products;
  final List<BuyV2Address> addresses;
  final List<BuyV2Order> orders;
  final Set<String> paymentMethods;
  final String? selectedAddressId;
  final bool businessVerified;
  final BuyV2BusinessVerificationState businessVerificationState;
  final bool productReportsAvailable;
  final Set<String> reviewableProductIds;
  final String? customerMessage;
}

@immutable
class BuyV2OrderPlacementRequest {
  const BuyV2OrderPlacementRequest({
    required this.lines,
    required this.address,
    required this.paymentMethod,
    required this.total,
    required this.amountDueNow,
    required this.idempotencyKey,
    this.commercialPaymentTermIds = const {},
    this.checkoutQuoteId,
  });

  final List<BuyV2CartLine> lines;
  final BuyV2Address address;
  final String paymentMethod;
  final int total;
  final int amountDueNow;
  final String idempotencyKey;
  final Map<String, String> commercialPaymentTermIds;
  final String? checkoutQuoteId;
}

@immutable
class BuyV2OrderPlacementResult {
  const BuyV2OrderPlacementResult({
    required this.outcome,
    required this.customerMessage,
    this.purchaseReference,
    this.paymentReference,
    this.paymentActionUri,
    this.orders = const [],
    this.failureKind,
    this.affectedProductId,
  });

  final BuyV2OrderPlacementOutcome outcome;
  final String customerMessage;
  final String? purchaseReference;
  final String? paymentReference;
  final Uri? paymentActionUri;
  final List<BuyV2Order> orders;
  final BuyV2OrderPlacementFailureKind? failureKind;
  final String? affectedProductId;
}

@immutable
class BuyV2OrderRefreshResult {
  const BuyV2OrderRefreshResult({
    required this.state,
    required this.customerMessage,
    this.order,
  });

  final BuyV2CommerceLoadState state;
  final String customerMessage;
  final BuyV2Order? order;
}

@immutable
class BuyV2OrderAlertsResult {
  const BuyV2OrderAlertsResult({
    required this.available,
    required this.enabled,
    required this.customerMessage,
  });

  final bool available;
  final bool enabled;
  final String customerMessage;
}

@immutable
class BuyV2MutationResult {
  const BuyV2MutationResult({
    required this.accepted,
    required this.customerMessage,
  });

  final bool accepted;
  final String customerMessage;
}

@immutable
class BuyV2AddressRequestResult {
  const BuyV2AddressRequestResult({
    required this.customerMessage,
    this.shareUri,
  });

  final Uri? shareUri;
  final String customerMessage;

  bool get available => shareUri != null;
}

typedef BuyV2PaymentHandoff = Future<bool> Function(Uri uri);

enum BuyV2CommercialPaymentTermKind {
  retailAdvance,
  wholesaleAdvance,
  bookingBalanceBeforeDispatch,
  bookingBalanceOnDelivery,
  supplierCredit,
  regulatedCredit,
}

@immutable
class BuyV2CommercialPaymentTerm {
  const BuyV2CommercialPaymentTerm({
    required this.id,
    required this.fulfilmentKey,
    required this.destination,
    required this.supplierName,
    required this.kind,
    required this.orderTotal,
    required this.amountDueNow,
    required this.balanceDue,
    required this.balanceDueLabel,
    required this.sourceId,
    this.supplierIsMicroOrSmall = false,
    this.netDays,
    this.financierName,
    this.annualPercentageRate,
    this.keyFactsUri,
  });

  final String id;
  final String fulfilmentKey;
  final BuyV2Destination destination;
  final String supplierName;
  final BuyV2CommercialPaymentTermKind kind;
  final int orderTotal;
  final int amountDueNow;
  final int balanceDue;
  final String balanceDueLabel;
  final String sourceId;
  final bool supplierIsMicroOrSmall;
  final int? netDays;
  final String? financierName;
  final double? annualPercentageRate;
  final Uri? keyFactsUri;
}

@immutable
class BuyV2CommercialPaymentTermsSnapshot {
  const BuyV2CommercialPaymentTermsSnapshot({
    required this.state,
    this.terms = const [],
    this.customerMessage,
  });

  final BuyV2CommerceLoadState state;
  final List<BuyV2CommercialPaymentTerm> terms;
  final String? customerMessage;
}

abstract interface class BuyV2CommercialPaymentTermsAdapter {
  const BuyV2CommercialPaymentTermsAdapter();

  Future<BuyV2CommercialPaymentTermsSnapshot> loadTerms({
    required List<BuyV2FulfilmentGroup> groups,
    required String selectedPaymentMethod,
    required Map<String, int> quotedTotalsByFulfilmentKey,
  });
}

@immutable
class BuyV2CheckoutQuoteLine {
  const BuyV2CheckoutQuoteLine({
    required this.fulfilmentKey,
    required this.itemSubtotal,
    required this.couponSaving,
    required this.tax,
    required this.freight,
    required this.deliveryFee,
    required this.tip,
    required this.paymentCharge,
    required this.total,
  });

  final String fulfilmentKey;
  final int itemSubtotal;
  final int couponSaving;
  final int tax;
  final int freight;
  final int deliveryFee;
  final int tip;
  final int paymentCharge;
  final int total;
}

@immutable
class BuyV2CheckoutQuote {
  const BuyV2CheckoutQuote({
    required this.id,
    required this.sourceId,
    required this.evaluatedAt,
    required this.validUntil,
    required this.lines,
    required this.total,
  });

  final String id;
  final String sourceId;
  final DateTime evaluatedAt;
  final DateTime validUntil;
  final List<BuyV2CheckoutQuoteLine> lines;
  final int total;
}

@immutable
class BuyV2CheckoutQuoteSnapshot {
  const BuyV2CheckoutQuoteSnapshot({
    required this.state,
    this.quote,
    this.customerMessage,
  });

  final BuyV2CommerceLoadState state;
  final BuyV2CheckoutQuote? quote;
  final String? customerMessage;
}

abstract interface class BuyV2CheckoutQuoteAdapter {
  const BuyV2CheckoutQuoteAdapter();

  Future<BuyV2CheckoutQuoteSnapshot> loadQuote({
    required List<BuyV2FulfilmentGroup> groups,
    required BuyV2Address address,
    required String selectedPaymentMethod,
    required List<BuyV2CartBenefit> selectedBenefits,
    required Map<String, int> tipAmountsByFulfilmentKey,
  });
}

enum BuyV2BalancePaymentState {
  upcoming,
  due,
  overdue,
  paymentActionRequired,
  paymentPending,
  paid,
  unknown,
  offline,
  unavailable,
}

@immutable
class BuyV2BalancePaymentResult {
  const BuyV2BalancePaymentResult({
    required this.state,
    required this.amountDue,
    required this.dueLabel,
    required this.customerMessage,
    this.paymentReference,
    this.paymentActionUri,
  });

  final BuyV2BalancePaymentState state;
  final int amountDue;
  final String dueLabel;
  final String customerMessage;
  final String? paymentReference;
  final Uri? paymentActionUri;
}

abstract interface class BuyV2BalancePaymentAdapter {
  const BuyV2BalancePaymentAdapter();

  Future<BuyV2BalancePaymentResult> loadBalance({required String orderId});

  Future<BuyV2BalancePaymentResult> startPayment({
    required String orderId,
    required int amountDue,
    required String idempotencyKey,
  });

  Future<BuyV2BalancePaymentResult> reconcilePayment({
    required String orderId,
    required String paymentReference,
  });
}

abstract interface class BuyV2CommerceAdapter {
  const BuyV2CommerceAdapter();

  Future<BuyV2CommerceSnapshot> refresh();

  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  );

  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  });

  Future<BuyV2OrderRefreshResult> refreshOrder({required String orderId});

  Future<BuyV2OrderAlertsResult> loadOrderAlerts();

  Future<BuyV2OrderAlertsResult> setOrderAlerts({required bool enabled});

  Future<BuyV2MutationResult> submitProductReview({
    required BuyV2Product product,
    required int rating,
    required String comment,
  });

  Future<BuyV2MutationResult> reportProduct({
    required BuyV2Product product,
    required String reason,
  });

  Future<BuyV2AddressRequestResult> createAddressRequest({String recipient});
}

final class BuyV2CatalogueProductFactsAdapter
    implements BuyV2ProductFactsAdapter {
  const BuyV2CatalogueProductFactsAdapter();

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    return BuyV2ProductFactsSnapshot(
      productId: product.id,
      price: product.price,
      deliveryPromise: product.deliveryPromise,
      partner: product.seller,
      orderabilityLabel: product.requiresPrescription
          ? 'Prescription required'
          : 'Available to add',
      sourceId: 'approved-buy-catalogue',
    );
  }
}

enum BuyV2SponsoredPlacement {
  catalogueAfterDiscovery,
  ordersAfterHistory,
  cartBeforeSummary,
}

enum BuyV2SponsoredFormat { card, inlineVideo }

@immutable
class BuyV2SponsoredContent {
  const BuyV2SponsoredContent({
    required this.id,
    required this.placement,
    required this.format,
    required this.disclosure,
    required this.title,
    required this.detail,
    this.posterAsset,
    this.captions,
    this.transcript,
  }) : assert(disclosure == 'Sponsored' || disclosure == 'Advertisement'),
       assert(
         format != BuyV2SponsoredFormat.inlineVideo ||
             (posterAsset != null && captions != null && transcript != null),
         'Inline video requires a poster, captions and transcript.',
       );

  final String id;
  final BuyV2SponsoredPlacement placement;
  final BuyV2SponsoredFormat format;
  final String disclosure;
  final String title;
  final String detail;
  final String? posterAsset;
  final String? captions;
  final String? transcript;
}

abstract interface class BuyV2SponsoredContentAdapter {
  BuyV2SponsoredContent? contentFor(BuyV2SponsoredPlacement placement);
}

final class BuyV2DisabledSponsoredContentAdapter
    implements BuyV2SponsoredContentAdapter {
  const BuyV2DisabledSponsoredContentAdapter();

  @override
  BuyV2SponsoredContent? contentFor(BuyV2SponsoredPlacement placement) => null;
}

abstract final class BuyV2ExperienceBudgets {
  static const targetFrame = Duration(microseconds: 16667);
  static const slowFrameCeiling = Duration(milliseconds: 33);
  static const maximumSponsoredCardsPerCatalogue = 1;
  static const maximumInlineVideosPerViewport = 1;
  static const maximumPreloadedInlineVideos = 0;
  static const autoplayAudioAllowed = false;
  static const perpetualDecorativeMotionAllowed = false;
}
