import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'buy_v2_cart_contracts.dart';
import 'buy_v2_models.dart';

enum BuyV2FulfilmentMode { quickLocal, standardCourier, bulkFreight }

enum BuyV2StoreOperatingState { unknown, open, closed }

/// Geographic scope is explicit; a destination search does not claim routing.
enum BuyV2CatalogueAreaScope { regional, national, allAreas }

enum BuyV2OfferPublisherType { manufacturer, wholesaler, retailer }

/// Immutable request identity shared by Store, category, Offers and Search.
/// A response for another identity must never replace the visible results.
@immutable
class BuyV2CatalogueQuery {
  BuyV2CatalogueQuery({
    required this.destination,
    required this.regionId,
    this.areaScope = BuyV2CatalogueAreaScope.regional,
    this.storeId,
    this.query = '',
    this.categoryId = 'all',
    this.sort = BuyV2ProductSort.relevance,
    this.shopSaleType,
    this.wholesaleSaleType,
    this.fulfilmentMode,
    this.pack,
    this.filter,
    Set<String> brands = const {},
    this.maximumPrice,
    this.availableOnly = false,
    this.offersOnly = false,
    this.collectionOnly = false,
    this.offerPublisher,
  }) : brands = Set.unmodifiable(brands);

  final BuyV2Destination destination;
  final String? regionId;
  final BuyV2CatalogueAreaScope areaScope;
  final String? storeId;
  final String query;
  final String categoryId;
  final BuyV2ProductSort sort;
  final BuyV2ShopSaleType? shopSaleType;
  final BuyV2WholesaleSaleType? wholesaleSaleType;
  final BuyV2FulfilmentMode? fulfilmentMode;
  final BuyV2PackFilter? pack;
  final String? filter;
  final Set<String> brands;
  final int? maximumPrice;
  final bool availableOnly;
  final bool offersOnly;
  final bool collectionOnly;
  final BuyV2OfferPublisherType? offerPublisher;

  String get key => jsonEncode([
    2,
    destination.name,
    regionId,
    areaScope.name,
    storeId,
    query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
    categoryId,
    sort.name,
    shopSaleType?.name,
    wholesaleSaleType?.name,
    fulfilmentMode?.name,
    pack?.name,
    filter,
    brands.toList()..sort(),
    maximumPrice,
    availableOnly,
    offersOnly,
    collectionOnly,
    offerPublisher?.name,
  ]);

  @override
  bool operator ==(Object other) =>
      other is BuyV2CatalogueQuery && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// Provider/branch identity is independent of its display name or SKU list.
@immutable
class BuyV2StoreListing {
  const BuyV2StoreListing({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    required this.regionId,
    this.distanceMeters,
    this.collection,
    this.previewProduct,
  });

  final String id;
  final String name;
  final String area;
  final String address;
  final String regionId;
  final int? distanceMeters;
  final BuyV2StoreCollectionCapability? collection;
  final BuyV2Product? previewProduct;
}

/// Cursors belong to one query and snapshot. A previous cursor makes backward
/// navigation possible without retaining every earlier page in device memory.
@immutable
class BuyV2CataloguePage<T> {
  BuyV2CataloguePage({
    required this.queryKey,
    required this.snapshotId,
    required Iterable<T> items,
    required this.startIndex,
    this.totalCount,
    this.previousCursor,
    this.nextCursor,
  }) : items = List.unmodifiable(items);

  final String queryKey;
  final String snapshotId;
  final List<T> items;
  final int startIndex;
  final int? totalCount;
  final String? previousCursor;
  final String? nextCursor;
}

/// One source supplies both provider discovery and provider-specific SKU pages.
/// Future transports enforce geography, availability and cursor consistency;
/// local development sources are not proof of those production facts.
abstract interface class BuyV2CataloguePageSource {
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  });

  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  });

  /// Restore exact user-selected IDs after page eviction or process relaunch.
  /// Callers batch at most50 IDs; absent IDs remain unavailable, never guessed.
  Future<List<BuyV2Product>> resolveProducts(Set<String> productIds);
}

/// A published placement owns an exact Store listing and current source facts.
/// Being returned by an offersOnly product filter is not publication evidence.
@immutable
class BuyV2PublishedCatalogueOffer {
  const BuyV2PublishedCatalogueOffer({
    required this.publicationId,
    required this.product,
    required this.publisherType,
    required this.publisherId,
    required this.publisherName,
    required this.headline,
    required this.sourceId,
    required this.observedAt,
    required this.validUntil,
  });

  final String publicationId;
  final BuyV2Product product;
  final BuyV2OfferPublisherType publisherType;
  final String publisherId;
  final String publisherName;
  final String headline;
  final String sourceId;
  final DateTime observedAt;
  final DateTime validUntil;

  bool isCurrent({required DateTime now}) =>
      publicationId.trim().isNotEmpty &&
      publicationId.trim() == publicationId &&
      publisherId.trim().isNotEmpty &&
      publisherId.trim() == publisherId &&
      publisherName.trim().isNotEmpty &&
      sourceId.trim().isNotEmpty &&
      headline.trim().isNotEmpty &&
      product.storeId?.trim().isNotEmpty == true &&
      (product.destination == BuyV2Destination.shop ||
          product.destination == BuyV2Destination.wholesale) &&
      !observedAt.isAfter(now) &&
      observedAt.isBefore(validUntil) &&
      now.isBefore(validUntil);
}

/// Optional bounded publication transport. Existing finite Offers adapters keep
/// their own contract; no missing transport is replaced with published success.
abstract interface class BuyV2PublishedCatalogueSource {
  Future<BuyV2CataloguePage<BuyV2PublishedCatalogueOffer>> loadOffers(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  });
}

/// A sourced Store capability, not proof of stock, payment or order readiness.
/// An absent or expired capability never advertises customer collection.
@immutable
class BuyV2StoreCollectionCapability {
  const BuyV2StoreCollectionCapability({
    required this.storeId,
    required this.supportsCollection,
    required this.sourceId,
    required this.observedAt,
    required this.validUntil,
  });

  final String storeId;
  final bool supportsCollection;
  final String sourceId;
  final DateTime observedAt;
  final DateTime validUntil;

  bool isSupportedFor(String? expectedStoreId, {required DateTime now}) =>
      supportsCollection &&
      expectedStoreId != null &&
      expectedStoreId.isNotEmpty &&
      expectedStoreId.trim() == expectedStoreId &&
      storeId == expectedStoreId &&
      sourceId.trim().isNotEmpty &&
      !observedAt.isAfter(now) &&
      observedAt.isBefore(validUntil) &&
      now.isBefore(validUntil);

  @override
  bool operator ==(Object other) =>
      other is BuyV2StoreCollectionCapability &&
      other.storeId == storeId &&
      other.supportsCollection == supportsCollection &&
      other.sourceId == sourceId &&
      other.observedAt == observedAt &&
      other.validUntil == validUntil;

  @override
  int get hashCode => Object.hash(
    storeId,
    supportsCollection,
    sourceId,
    observedAt,
    validUntil,
  );
}

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
    this.storeCollection,
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
  final BuyV2StoreCollectionCapability? storeCollection;
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
    BuyV2StoreCollectionCapability? storeCollection,
    bool clearStoreCollection = false,
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
      storeCollection: clearStoreCollection
          ? null
          : storeCollection ?? this.storeCollection,
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
        other.storeCollection == storeCollection &&
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
    storeCollection,
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

/// Account context from the authentication adapter, not from an order or QR.
/// A new login/session must publish a new identity, even for the same account.
@immutable
class BuyV2CollectionIdentity {
  const BuyV2CollectionIdentity({
    required this.accountId,
    required this.sessionId,
  });

  final String accountId;
  final String sessionId;
}

/// Durable reconciliation context. The scanned security token is never stored.
@immutable
class BuyV2CollectionPendingIntent {
  const BuyV2CollectionPendingIntent({
    required this.accountId,
    required this.orderId,
    required this.storeId,
    required this.operationId,
    required this.requestFingerprint,
  });

  final String accountId;
  final String orderId;
  final String storeId;
  final String operationId;
  final String requestFingerprint;
}

/// Supplied by the authenticated persistence adapter. There is deliberately no
/// in-memory production default: uncertain scans must survive process death.
abstract interface class BuyV2CollectionPendingStore {
  /// Reads serialize after earlier reservations/clears, including a caller's
  /// timed-out operation. No delayed write may appear after this read settles.
  Future<BuyV2CollectionPendingIntent?> read({
    required String accountId,
    required String orderId,
    required String storeId,
  });

  /// Atomically writes only when this account/order/store has no pending intent.
  /// True means durably committed before the authorisation request can start.
  Future<bool> reserve(BuyV2CollectionPendingIntent intent);

  /// Clears only the exact original operation/fingerprint, never a newer intent.
  /// An already absent intent also succeeds; a different pending intent does not.
  /// False or a storage error leaves reconciliation pending.
  Future<bool> clear(BuyV2CollectionPendingIntent intent);
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
    final closedForReview = product.seller == 'Pet Family Store';
    final noProductsForReview = product.seller == 'Beauty Supply';
    return BuyV2ProductFactsSnapshot(
      productId: product.id,
      price: product.price,
      deliveryPromise: product.deliveryPromise,
      partner: product.seller,
      orderabilityLabel: closedForReview
          ? 'Store closed'
          : noProductsForReview
          ? 'Products unavailable'
          : product.requiresPrescription
          ? 'Prescription required'
          : 'Available to add',
      sourceId: 'approved-buy-catalogue',
      fulfilmentMode: buyV2CatalogueFulfilmentModeFor(product),
      storeOperatingState:
          product.destination == BuyV2Destination.shop ||
              product.destination == BuyV2Destination.wholesale
          ? closedForReview
                ? BuyV2StoreOperatingState.closed
                : BuyV2StoreOperatingState.open
          : BuyV2StoreOperatingState.unknown,
      nextOpeningLabel: closedForReview ? 'tomorrow at 8:00 am' : null,
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
