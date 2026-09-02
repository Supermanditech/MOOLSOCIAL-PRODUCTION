import 'package:flutter/foundation.dart';

import 'buy_v2_cart_contracts.dart';
import 'buy_v2_models.dart';

enum BuyV2FulfilmentMode { quickLocal, standardCourier, bulkFreight }

enum BuyV2StoreOperatingState { unknown, open, closed }

BuyV2FulfilmentMode buyV2CatalogueFulfilmentModeFor(BuyV2Product product) {
  if (product.destination == BuyV2Destination.wholesale) {
    return BuyV2FulfilmentMode.bulkFreight;
  }
  final promise = product.deliveryPromise.toLowerCase();
  if (product.destination == BuyV2Destination.shop &&
      RegExp(r'\d+\s*(?:min|minute)').hasMatch(promise)) {
    return BuyV2FulfilmentMode.quickLocal;
  }
  return BuyV2FulfilmentMode.standardCourier;
}

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
    this.fulfilmentMode,
    this.storeOperatingState = BuyV2StoreOperatingState.unknown,
    this.nextOpeningLabel,
    this.orderCutoffLabel,
    this.deliveryFeeLabel,
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
  final BuyV2FulfilmentMode? fulfilmentMode;
  final BuyV2StoreOperatingState storeOperatingState;
  final String? nextOpeningLabel;
  final String? orderCutoffLabel;
  final String? deliveryFeeLabel;
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
    BuyV2FulfilmentMode? fulfilmentMode,
    BuyV2StoreOperatingState? storeOperatingState,
    String? nextOpeningLabel,
    String? orderCutoffLabel,
    String? deliveryFeeLabel,
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
      fulfilmentMode: fulfilmentMode ?? this.fulfilmentMode,
      storeOperatingState: storeOperatingState ?? this.storeOperatingState,
      nextOpeningLabel: nextOpeningLabel ?? this.nextOpeningLabel,
      orderCutoffLabel: orderCutoffLabel ?? this.orderCutoffLabel,
      deliveryFeeLabel: deliveryFeeLabel ?? this.deliveryFeeLabel,
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
        other.fulfilmentMode == fulfilmentMode &&
        other.storeOperatingState == storeOperatingState &&
        other.nextOpeningLabel == nextOpeningLabel &&
        other.orderCutoffLabel == orderCutoffLabel &&
        other.deliveryFeeLabel == deliveryFeeLabel &&
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
    fulfilmentMode,
    storeOperatingState,
    nextOpeningLabel,
    orderCutoffLabel,
    deliveryFeeLabel,
    observedAt,
    stale,
  );
}

abstract interface class BuyV2ProductFactsAdapter {
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product);
}

enum BuyV2ProductContentState { ready, loading, offline, unavailable }

enum BuyV2ProductContentMediaKind {
  cataloguePackshot,
  asset,
  network,
  networkVideo,
}

@immutable
class BuyV2ProductMediaAsset {
  const BuyV2ProductMediaAsset({
    required this.id,
    required this.label,
    required this.semanticLabel,
    required this.kind,
    this.source,
    this.posterSource,
    this.transcript,
  }) : assert(
         kind == BuyV2ProductContentMediaKind.cataloguePackshot ||
             (source != null && source != ''),
       ),
       assert(
         kind != BuyV2ProductContentMediaKind.networkVideo ||
             (transcript != null && transcript != ''),
       );

  final String id;
  final String label;
  final String semanticLabel;
  final BuyV2ProductContentMediaKind kind;
  final String? source;
  final String? posterSource;
  final String? transcript;
}

@immutable
class BuyV2ProductSpecification {
  const BuyV2ProductSpecification({required this.label, required this.value});

  final String label;
  final String value;
}

@immutable
class BuyV2ProductContentSnapshot {
  const BuyV2ProductContentSnapshot({
    required this.productId,
    required this.state,
    required this.sourceId,
    this.media = const [],
    this.highlights = const [],
    this.specifications = const [],
    this.description,
    this.customerMessage,
    this.observedAt,
  });

  final String productId;
  final BuyV2ProductContentState state;
  final String sourceId;
  final List<BuyV2ProductMediaAsset> media;
  final List<String> highlights;
  final List<BuyV2ProductSpecification> specifications;
  final String? description;
  final String? customerMessage;
  final DateTime? observedAt;
}

abstract interface class BuyV2ProductContentAdapter {
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product);
}

enum BuyV2MarketplaceTrustState { ready, loading, offline, unavailable }

@immutable
class BuyV2MarketplaceTrustSnapshot {
  const BuyV2MarketplaceTrustSnapshot({
    required this.productId,
    required this.state,
    required this.sourceId,
    required this.partnerName,
    required this.partnerType,
    this.productRating,
    this.productRatingCount,
    this.verifiedBuyerRatingCount,
    this.partnerRating,
    this.partnerOrderCount,
    this.partnerLocation,
    this.serviceReliabilityLabel,
    this.returnSummary,
    this.customerMessage,
    this.observedAt,
  });

  final String productId;
  final BuyV2MarketplaceTrustState state;
  final String sourceId;
  final String partnerName;
  final String partnerType;
  final double? productRating;
  final int? productRatingCount;
  final int? verifiedBuyerRatingCount;
  final double? partnerRating;
  final int? partnerOrderCount;
  final String? partnerLocation;
  final String? serviceReliabilityLabel;
  final String? returnSummary;
  final String? customerMessage;
  final DateTime? observedAt;
}

abstract interface class BuyV2MarketplaceTrustAdapter {
  BuyV2MarketplaceTrustSnapshot snapshotFor(BuyV2Product product);
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
class BuyV2BankTransferInstructions {
  const BuyV2BankTransferInstructions({
    required this.beneficiaryName,
    required this.bankName,
    required this.accountNumber,
    required this.ifsc,
    required this.transferReference,
  });

  final String beneficiaryName;
  final String bankName;
  final String accountNumber;
  final String ifsc;
  final String transferReference;
}

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
    this.bankTransferInstructions,
    this.orders = const [],
    this.failureKind,
    this.affectedProductId,
  });

  final BuyV2OrderPlacementOutcome outcome;
  final String customerMessage;
  final String? purchaseReference;
  final String? paymentReference;
  final Uri? paymentActionUri;
  final BuyV2BankTransferInstructions? bankTransferInstructions;
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

enum BuyV2DeliveryExceptionKind {
  carrierChanged,
  dispatchDelayed,
  deliveryAttemptFailed,
  recipientUnavailable,
  rescheduleAvailable,
  returnToSender,
  proofOfDeliveryAvailable,
  proofOfDeliveryDisputed,
}

@immutable
class BuyV2DeliveryExceptionSnapshot {
  const BuyV2DeliveryExceptionSnapshot({
    required this.state,
    required this.customerMessage,
    this.exceptionId,
    this.kind,
    this.headline,
    this.detail,
    this.rescheduleSlots = const [],
    this.proofReference,
  });

  final BuyV2CommerceLoadState state;
  final String customerMessage;
  final String? exceptionId;
  final BuyV2DeliveryExceptionKind? kind;
  final String? headline;
  final String? detail;
  final List<String> rescheduleSlots;
  final String? proofReference;
}

abstract interface class BuyV2DeliveryExceptionAdapter {
  const BuyV2DeliveryExceptionAdapter();

  Future<BuyV2DeliveryExceptionSnapshot> loadException({
    required String orderId,
  });

  Future<BuyV2DeliveryExceptionSnapshot> rescheduleDelivery({
    required String orderId,
    required String exceptionId,
    required String slot,
  });

  Future<BuyV2DeliveryExceptionSnapshot> disputeProofOfDelivery({
    required String orderId,
    required String exceptionId,
    required String proofReference,
  });
}

enum BuyV2LiveDeliveryState { ready, delivered, offline, unavailable }

@immutable
class BuyV2GeoPoint {
  const BuyV2GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

@immutable
class BuyV2LiveDeliverySnapshot {
  const BuyV2LiveDeliverySnapshot({
    required this.orderId,
    required this.state,
    required this.customerMessage,
    required this.sourceId,
    this.courierPosition,
    this.destinationPosition,
    this.driverName,
    this.vehicleLabel,
    this.etaLabel,
    this.lastUpdatedAt,
    this.routeProgress,
    this.trackingReference,
  });

  final String orderId;
  final BuyV2LiveDeliveryState state;
  final String customerMessage;
  final String sourceId;
  final BuyV2GeoPoint? courierPosition;
  final BuyV2GeoPoint? destinationPosition;
  final String? driverName;
  final String? vehicleLabel;
  final String? etaLabel;
  final DateTime? lastUpdatedAt;
  final double? routeProgress;
  final String? trackingReference;
}

abstract interface class BuyV2LiveDeliveryAdapter {
  const BuyV2LiveDeliveryAdapter();

  Future<BuyV2LiveDeliverySnapshot> load({required String orderId});
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
      fulfilmentMode: buyV2CatalogueFulfilmentModeFor(product),
      storeOperatingState:
          product.destination == BuyV2Destination.shop ||
              product.destination == BuyV2Destination.wholesale
          ? BuyV2StoreOperatingState.open
          : BuyV2StoreOperatingState.unknown,
    );
  }
}

final class BuyV2CatalogueProductContentAdapter
    implements BuyV2ProductContentAdapter {
  const BuyV2CatalogueProductContentAdapter();

  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) {
    final returnDetail = product.returnPolicy;
    return BuyV2ProductContentSnapshot(
      productId: product.id,
      state: BuyV2ProductContentState.ready,
      sourceId: 'approved-buy-catalogue',
      media: [
        BuyV2ProductMediaAsset(
          id: '${product.id}-packshot',
          label: 'Product image',
          semanticLabel: '${product.title}, ${product.pack}',
          kind: BuyV2ProductContentMediaKind.cataloguePackshot,
        ),
      ],
      highlights: [product.variant, product.unitPrice, ?returnDetail],
      specifications: [
        BuyV2ProductSpecification(label: 'Brand', value: product.brand),
        BuyV2ProductSpecification(label: 'Pack', value: product.pack),
        BuyV2ProductSpecification(label: 'Variant', value: product.variant),
      ],
      description:
          '${product.title} · ${product.variant}. '
          '${product.pack} at ${product.unitPrice}.',
    );
  }
}

final class BuyV2CatalogueMarketplaceTrustAdapter
    implements BuyV2MarketplaceTrustAdapter {
  const BuyV2CatalogueMarketplaceTrustAdapter();

  @override
  BuyV2MarketplaceTrustSnapshot snapshotFor(BuyV2Product product) =>
      BuyV2MarketplaceTrustSnapshot(
        productId: product.id,
        state: BuyV2MarketplaceTrustState.ready,
        sourceId: 'approved-buy-catalogue',
        partnerName: product.seller,
        partnerType: product.partnerRole,
        partnerLocation: product.origin,
        returnSummary: product.returnPolicy,
      );
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
