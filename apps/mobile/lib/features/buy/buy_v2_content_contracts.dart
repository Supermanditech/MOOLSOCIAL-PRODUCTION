import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../work/scan_and_pick_contract.dart';
import 'buy_v2_cart_contracts.dart';
import 'buy_v2_models.dart';

enum BuyV2FulfilmentMode { quickLocal, standardCourier, bulkFreight }

enum BuyV2StoreOperatingState { unknown, open, closed }

/// Geographic scope is explicit; a destination search does not claim routing.
enum BuyV2CatalogueAreaScope { regional, national, allAreas }

/// The source authenticates publication authority; a display name never grants it.
enum BuyV2OfferPublisherType { manufacturer, wholesaler, retailer, moolSocial }

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
    this.procurementContext,
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
  final BuyV2ProcurementContext? procurementContext;

  String get key => jsonEncode([
    procurementContext == null ? 2 : 3,
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
    if (procurementContext case final context?)
      [
        context.accountId,
        context.storeId,
        context.purpose.name,
        context.originOperationId,
      ],
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

/// The buyer's checkout context. Product IDs identify the product family;
/// listing IDs identify the exact purchased Store SKU and pack.
@immutable
class BuyV2CollectionBasket {
  BuyV2CollectionBasket({
    required this.identity,
    required this.store,
    required Iterable<BuyV2CartLine> lines,
    required this.paymentMethod,
  }) : lines = List.unmodifiable(lines) {
    if (!_collectionText(identity.accountId) ||
        !_collectionText(identity.sessionId) ||
        !_collectionText(store.id) ||
        store.name.trim().isEmpty ||
        store.address.trim().isEmpty ||
        paymentMethod.trim().isEmpty ||
        const {'Cash on Delivery', 'Purchase order'}.contains(paymentMethod) ||
        this.lines.isEmpty ||
        this.lines.map((line) => line.product.id).toSet().length !=
            this.lines.length ||
        this.lines.any((line) {
          final product = line.product;
          return product.storeId != store.id ||
              !_collectionText(product.id) ||
              !_collectionText(product.canonicalId) ||
              product.pack.trim().isEmpty ||
              product.title.trim().isEmpty ||
              product.price < 0 ||
              product.minimumOrder < 1 ||
              line.quantity < 1 ||
              line.quantity < product.minimumOrder ||
              BigInt.from(product.price) *
                      BigInt.from(line.quantity) *
                      BigInt.from(100) >
                  BigInt.from(9007199254740991) ||
              product.requiresPrescription ||
              (product.destination != BuyV2Destination.shop &&
                  product.destination != BuyV2Destination.wholesale);
        })) {
      throw const FormatException('Invalid collection basket');
    }
  }

  final BuyV2CollectionIdentity identity;
  final BuyV2StoreListing store;
  final List<BuyV2CartLine> lines;
  final String paymentMethod;

  /// Stable under row reordering, sensitive to account/session, branch, SKU,
  /// quantity, displayed price and payment changes. It is correlation, not auth.
  String get fingerprint {
    final ordered = [...lines]
      ..sort((a, b) => a.product.id.compareTo(b.product.id));
    return sha256
        .convert(
          utf8.encode(
            jsonEncode([
              'buy-collection-checkout-v1',
              identity.accountId,
              identity.sessionId,
              store.id,
              paymentMethod,
              for (final line in ordered)
                [
                  line.product.canonicalId,
                  line.product.id,
                  line.product.destination.name,
                  line.product.pack,
                  line.product.variant,
                  line.product.price,
                  line.quantity,
                ],
            ]),
          ),
        )
        .toString();
  }

  bool collectionAvailableAt(DateTime now) =>
      store.collection?.isSupportedFor(store.id, now: now) == true;
}

@immutable
class BuyV2CollectionCheckoutQuote {
  BuyV2CollectionCheckoutQuote({
    required this.id,
    required this.sourceId,
    required this.basketFingerprint,
    required this.issuedAt,
    required this.validUntil,
    required Map<String, int> lineAmountsMinor,
    required this.totalMinor,
    this.currency = 'INR',
    this.taxMinor = 0,
    this.paymentChargeMinor = 0,
    this.discountMinor = 0,
  }) : lineAmountsMinor = Map.unmodifiable(lineAmountsMinor);

  final String id;
  final String sourceId;
  final String basketFingerprint;
  final DateTime issuedAt;
  final DateTime validUntil;
  final Map<String, int> lineAmountsMinor;
  final String currency;
  final int totalMinor;
  final int taxMinor;
  final int paymentChargeMinor;
  final int discountMinor;

  /// A changed unit price must refresh the basket before another quote. Taxes,
  /// payment fees and savings retain their exact minor-unit values for review.
  bool matches(BuyV2CollectionBasket basket) =>
      _collectionText(id) &&
      _collectionText(sourceId) &&
      basketFingerprint == basket.fingerprint &&
      currency == 'INR' &&
      issuedAt.isBefore(validUntil) &&
      lineAmountsMinor.length == basket.lines.length &&
      basket.lines.every(
        (line) => lineAmountsMinor[line.product.id] == line.total * 100,
      ) &&
      taxMinor >= 0 &&
      paymentChargeMinor >= 0 &&
      discountMinor >= 0 &&
      totalMinor > 0 &&
      totalMinor <= 9007199254740991 &&
      BigInt.from(totalMinor) ==
          lineAmountsMinor.values.fold<BigInt>(
                BigInt.zero,
                (sum, value) => sum + BigInt.from(value),
              ) +
              BigInt.from(taxMinor) +
              BigInt.from(paymentChargeMinor) -
              BigInt.from(discountMinor);

  bool isCurrentFor(BuyV2CollectionBasket basket, DateTime now) =>
      matches(basket) &&
      !issuedAt.isAfter(now) &&
      now.isBefore(validUntil) &&
      basket.collectionAvailableAt(now);
}

/// Reserve this entire immutable request durably before attempting payment.
/// A new session may reconcile it for the same account, never rewrite it.
@immutable
class BuyV2CollectionPurchaseIntent {
  BuyV2CollectionPurchaseIntent({
    required this.operationId,
    required this.basket,
    required this.quote,
  }) {
    if (!_collectionText(operationId) || !quote.matches(basket)) {
      throw const FormatException('Invalid collection purchase intent');
    }
  }

  final String operationId;
  final BuyV2CollectionBasket basket;
  final BuyV2CollectionCheckoutQuote quote;

  String get fingerprint => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            operationId,
            basket.fingerprint,
            quote.id,
            quote.sourceId,
            quote.issuedAt.toUtc().toIso8601String(),
            quote.validUntil.toUtc().toIso8601String(),
            quote.currency,
            quote.totalMinor,
            quote.taxMinor,
            quote.paymentChargeMinor,
            quote.discountMinor,
          ]),
        ),
      )
      .toString();
}

enum BuyV2CollectionPurchaseState {
  actionRequired,
  pending,
  paid,
  notCharged,
  unknown,
}

/// Authenticated transport outcome. Local construction is never payment proof.
@immutable
class BuyV2CollectionPurchaseResult {
  const BuyV2CollectionPurchaseResult({
    required this.operationId,
    required this.intentFingerprint,
    required this.state,
    this.orderId,
    this.purchaseId,
    this.paymentReference,
    this.paymentActionUri,
    this.paidAmountMinor,
    this.currency,
  });

  final String operationId;
  final String intentFingerprint;
  final BuyV2CollectionPurchaseState state;
  final String? orderId;
  final String? purchaseId;
  final String? paymentReference;
  final Uri? paymentActionUri;
  final int? paidAmountMinor;
  final String? currency;

  bool matches(BuyV2CollectionPurchaseIntent intent) {
    if (operationId != intent.operationId ||
        intentFingerprint != intent.fingerprint) {
      return false;
    }
    if (state == BuyV2CollectionPurchaseState.paid) {
      return _collectionText(orderId) &&
          _collectionText(purchaseId) &&
          _collectionText(paymentReference) &&
          paymentActionUri == null &&
          currency == intent.quote.currency &&
          paidAmountMinor == intent.quote.totalMinor;
    }
    if (state == BuyV2CollectionPurchaseState.actionRequired) {
      final uri = paymentActionUri;
      return _collectionText(paymentReference) &&
          uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'upi') &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty &&
          paidAmountMinor == null;
    }
    return paymentActionUri == null &&
        paidAmountMinor == null &&
        (state != BuyV2CollectionPurchaseState.notCharged || orderId == null);
  }

  /// The existing shared collection read independently supplies the paid order.
  /// No delivery order, different branch/SKU, QR token or rounded total qualifies.
  bool matchesPaidOrder(
    BuyV2CollectionPurchaseIntent intent,
    ScanPickSnapshot snapshot,
  ) =>
      state == BuyV2CollectionPurchaseState.paid &&
      matches(intent) &&
      snapshot.orderId == orderId &&
      snapshot.storeId == intent.basket.store.id &&
      snapshot.purchaserAccountId == intent.basket.identity.accountId &&
      snapshot.currency == intent.quote.currency &&
      snapshot.totalMinor == intent.quote.totalMinor &&
      snapshot.payment == ScanPickPayment.paid &&
      snapshot.state != ScanPickState.cancelled &&
      snapshot.challenge?.qrPayload == null &&
      snapshot.lines.length == intent.basket.lines.length &&
      intent.basket.lines.every((line) {
        final matches = snapshot.lines.where(
          (value) =>
              value.skuId == line.product.id &&
              value.productId == line.product.canonicalId &&
              value.pack == line.product.pack &&
              RegExp(
                '^${line.quantity}(?:\\.0+)?\$',
              ).hasMatch(value.quantity) &&
              value.amountMinor ==
                  intent.quote.lineAmountsMinor[line.product.id],
        );
        return matches.length == 1;
      });
}

/// Optional buyer checkout transport; the existing delivery adapter is intact.
/// The adapter must authenticate the current caller, enforce the quoted Store,
/// stock and amount, and make place/reconcile idempotent by operationId.
/// It must validate provider handoff origins, never trust a returned URL alone.
abstract interface class BuyV2CollectionCheckoutGateway {
  Future<BuyV2CollectionCheckoutQuote> quote(BuyV2CollectionBasket basket);
  Future<BuyV2CollectionPurchaseResult> place(
    BuyV2CollectionPurchaseIntent intent,
  );
  Future<BuyV2CollectionPurchaseResult> reconcile(
    BuyV2CollectionPurchaseIntent intent,
  );
}

/// Dedicated durable payment journal, distinct from the QR-authorisation store.
/// There is no in-memory or review-mode production default.
abstract interface class BuyV2CollectionPurchaseStore {
  /// Linearizable after prior reserve/settle operations, including timed-out
  /// writes. Missing/corrupt storage must throw, not look like an empty account.
  Future<BuyV2CollectionPurchaseIntent?> read(String accountId);

  /// Atomic compare-and-set: at most one unresolved purchase for this account.
  /// True is returned only after the entire intent is durably committed.
  Future<bool> reserve(BuyV2CollectionPurchaseIntent intent);

  /// Remove only this exact intent, atomically with durable admission of the
  /// validated paid order into account order history and an idempotent Cart
  /// reconciliation checkpoint for its original quantities. Repeating the same
  /// settlement succeeds. notCharged has no snapshot; paid requires its exact
  /// validated snapshot. Pending/unknown results must never clear a reservation.
  Future<bool> settle(
    BuyV2CollectionPurchaseIntent intent,
    BuyV2CollectionPurchaseResult result, {
    ScanPickSnapshot? paidOrder,
  });
}

bool _collectionText(String? value) =>
    value != null && value.isNotEmpty && value.trim() == value;

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
    this.procurementBuyerGrant,
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
  final BuyV2ProcurementBuyerGrant? procurementBuyerGrant;
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
    this.procurementContext,
  });

  final List<BuyV2CartLine> lines;
  final BuyV2Address address;
  final String paymentMethod;
  final int total;
  final int amountDueNow;
  final String idempotencyKey;
  final Map<String, String> commercialPaymentTermIds;
  final String? checkoutQuoteId;
  final BuyV2ProcurementContext? procurementContext;
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
          label: 'Catalogue illustration',
          semanticLabel:
              'Illustration for ${product.title}. '
              'Supplier photo of this pack is unavailable.',
          kind: BuyV2ProductContentMediaKind.cataloguePackshot,
        ),
      ],
      highlights: [product.variant, product.unitPrice, ?returnDetail],
      specifications: [
        BuyV2ProductSpecification(label: 'Brand', value: product.brandLabel),
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

enum BuyV2ComparisonUnit { kilogram, litre, count }

enum BuyV2ComparisonChannel { retail, wholesale }

enum BuyV2ComparisonSort { itemPrice, deliveredCost, arrival }

/// Chosen entry purpose, never inferred from quantity or a supplier name.
enum BuyV2ComparisonPurpose { standardPurchase, bulkPurchase, storeProcurement }

enum BuyV2ComparisonScope { allServiceable, local }

/// Published identity includes brand/model or commodity specification, grade
/// and variant. Neither category, display title nor a blank brand can create it.
/// Quantities use thousandths of [unit]; count products require whole items.
@immutable
class BuyV2ComparisonIdentity {
  const BuyV2ComparisonIdentity({
    required this.specificationId,
    required this.packId,
    required this.unit,
    required this.packQuantityMilli,
    this.containedRetailUnitId,
  });

  final String specificationId;
  final String packId;
  final BuyV2ComparisonUnit unit;
  final int packQuantityMilli;

  /// Published identity of each sealed resale unit inside an outer carton.
  /// Equal total mass alone does not establish equivalent resale inventory.
  final String? containedRetailUnitId;

  bool get valid =>
      _comparisonId(specificationId) &&
      _comparisonId(packId) &&
      _comparisonPositive(packQuantityMilli) &&
      (containedRetailUnitId == null ||
          _comparisonId(containedRetailUnitId!)) &&
      (unit != BuyV2ComparisonUnit.count || packQuantityMilli % 1000 == 0);

  bool equivalentTo(BuyV2ComparisonIdentity other, {required bool samePack}) =>
      valid &&
      other.valid &&
      specificationId == other.specificationId &&
      unit == other.unit &&
      (!samePack ||
          (packId == other.packId &&
              packQuantityMilli == other.packQuantityMilli));
}

@immutable
class BuyV2ComparisonQuery {
  const BuyV2ComparisonQuery({
    required this.productId,
    required this.productCanonicalId,
    required this.identity,
    required this.purchaserScope,
    required this.destinationKey,
    required this.pinCode,
    required this.requestedQuantityMilli,
    this.samePack = true,
    this.scope = BuyV2ComparisonScope.allServiceable,
    this.channel,
    this.fulfilment,
    this.sort = BuyV2ComparisonSort.itemPrice,
    this.purpose = BuyV2ComparisonPurpose.standardPurchase,
    this.allowExtraQuantity = false,
    this.arriveBy,
    this.procurementContext,
  });

  final String productId;
  final String productCanonicalId;
  final BuyV2ComparisonIdentity identity;

  /// Exact authenticated account scope or isolated guest session identity.
  final String purchaserScope;

  /// Stable revision/hash of the selected delivery address, not its label.
  final String destinationKey;
  final String pinCode;
  final int requestedQuantityMilli;
  final bool samePack;
  final BuyV2ComparisonScope scope;
  final BuyV2ComparisonChannel? channel;
  final BuyV2FulfilmentMode? fulfilment;
  final BuyV2ComparisonSort sort;
  final BuyV2ComparisonPurpose purpose;
  final bool allowExtraQuantity;
  bool get standardPurchase =>
      purpose == BuyV2ComparisonPurpose.standardPurchase;
  final DateTime? arriveBy;
  final BuyV2ProcurementContext? procurementContext;

  bool get valid =>
      _comparisonId(productId) &&
      _comparisonId(productCanonicalId) &&
      identity.valid &&
      _comparisonId(purchaserScope) &&
      _comparisonId(destinationKey) &&
      RegExp(r'^[1-9][0-9]{5}$').hasMatch(pinCode) &&
      _comparisonPositive(requestedQuantityMilli) &&
      (identity.unit != BuyV2ComparisonUnit.count ||
          requestedQuantityMilli % 1000 == 0) &&
      (standardPurchase
          ? (channel == null || channel == BuyV2ComparisonChannel.retail) &&
                !allowExtraQuantity
          : true) &&
      (purpose == BuyV2ComparisonPurpose.storeProcurement
          ? procurementContext?.hasIdentity == true &&
                (channel == null || channel == BuyV2ComparisonChannel.wholesale)
          : procurementContext == null);

  String get key => jsonEncode([
    2,
    productId,
    productCanonicalId,
    identity.specificationId,
    identity.packId,
    identity.unit.name,
    identity.packQuantityMilli,
    identity.containedRetailUnitId,
    purpose.name,
    allowExtraQuantity,
    purchaserScope,
    destinationKey,
    pinCode,
    requestedQuantityMilli,
    samePack,
    scope.name,
    channel?.name,
    fulfilment?.name,
    sort.name,
    arriveBy?.toUtc().toIso8601String(),
    procurementContext?.customerStateOwnerScope,
  ]);
}

@immutable
class BuyV2ComparisonPriceTier {
  const BuyV2ComparisonPriceTier({
    required this.minimumPacks,
    required this.packPriceMinor,
  });
  final int minimumPacks;
  final int packPriceMinor;
}

/// These values are a provider quote for the exact query/quantity, never rates
/// extrapolated from another basket. Null means unknown; zero means confirmed
/// zero. Immediate discounts exclude speculative cashback and recoverable tax.
@immutable
class BuyV2ComparisonCharges {
  const BuyV2ComparisonCharges({
    this.taxMinor,
    this.freightMinor,
    this.mandatoryFeesMinor,
    this.immediateDiscountMinor,
  });
  final int? taxMinor;
  final int? freightMinor;
  final int? mandatoryFeesMinor;
  final int? immediateDiscountMinor;

  bool get valid => [
    taxMinor,
    freightMinor,
    mandatoryFeesMinor,
    immediateDiscountMinor,
  ].every((amount) => amount == null || _comparisonNonnegative(amount));
  bool get complete => [
    taxMinor,
    freightMinor,
    mandatoryFeesMinor,
    immediateDiscountMinor,
  ].every((amount) => amount != null);
}

@immutable
class BuyV2ComparisonOffer {
  BuyV2ComparisonOffer({
    required this.id,
    required this.revision,
    required this.queryKey,
    required this.snapshotId,
    required this.product,
    required this.identity,
    required this.supplierWorkspaceId,
    required this.storeId,
    required this.channel,
    required this.fulfilment,
    required this.originLabel,
    required this.local,
    required this.serviceable,
    required this.customerEligible,
    required this.availablePacks,
    required this.minimumPacks,
    required this.incrementPacks,
    required this.packPriceMinor,
    required this.charges,
    required this.observedAt,
    required this.validUntil,
    this.arrivalStart,
    this.arrivalEnd,
    this.dispatchLabel,
    List<BuyV2ComparisonPriceTier> tiers = const [],
  }) : tiers = List.unmodifiable(tiers);

  final String id;
  final String revision;
  final String queryKey;
  final String snapshotId;
  final BuyV2Product product;
  final BuyV2ComparisonIdentity identity;
  final String supplierWorkspaceId;
  final String storeId;
  final BuyV2ComparisonChannel channel;
  final BuyV2FulfilmentMode fulfilment;
  final String originLabel;
  final bool local;
  final bool serviceable;
  final bool customerEligible;
  final int availablePacks;
  final int minimumPacks;

  /// Legal counts are minimumPacks + n * incrementPacks, for integer n >= 0.
  final int incrementPacks;
  final int packPriceMinor;
  final List<BuyV2ComparisonPriceTier> tiers;
  final BuyV2ComparisonCharges charges;
  final DateTime observedAt;
  final DateTime validUntil;
  final DateTime? arrivalStart;
  final DateTime? arrivalEnd;
  final String? dispatchLabel;
}

enum BuyV2ComparisonUnavailable {
  invalidTerms,
  wrongQuery,
  differentProduct,
  filtered,
  unserviceable,
  customerIneligible,
  expired,
  insufficientStock,
  arrivalUnavailable,
  unwantedQuantity,
}

/// Safe comparison arithmetic only. This is not a checkout authorization.
/// The existing cart/checkout must obtain fresh terms before a purchase.
@immutable
class BuyV2ComparisonCalculation {
  const BuyV2ComparisonCalculation._({
    this.unavailable,
    this.packCount,
    this.suppliedQuantityMilli,
    this.excessQuantityMilli,
    this.packPriceMinor,
    this.itemSubtotalMinor,
    this.payableMinor,
    this.comparableUnitMinor,
    this.arrivalEnd,
  });

  final BuyV2ComparisonUnavailable? unavailable;
  final int? packCount;
  final int? suppliedQuantityMilli;
  final int? excessQuantityMilli;
  final int? packPriceMinor;
  final int? itemSubtotalMinor;
  final int? payableMinor;

  /// Final payable per supplied base unit, rounded half-up to one minor unit.
  /// Rank by final payable for the requested requirement, not this unit value.
  final int? comparableUnitMinor;
  final DateTime? arrivalEnd;
  bool get available => unavailable == null;

  static BuyV2ComparisonCalculation evaluate({
    required BuyV2ComparisonQuery query,
    required BuyV2ComparisonOffer offer,
    required DateTime now,
  }) {
    BuyV2ComparisonCalculation reject(BuyV2ComparisonUnavailable reason) =>
        BuyV2ComparisonCalculation._(unavailable: reason);
    if (!query.valid ||
        !offer.identity.valid ||
        [
          offer.id,
          offer.revision,
          offer.snapshotId,
          offer.supplierWorkspaceId,
          offer.storeId,
          offer.originLabel,
        ].any((id) => !_comparisonId(id)) ||
        offer.product.storeId != offer.storeId ||
        !_comparisonPositive(offer.minimumPacks) ||
        !_comparisonPositive(offer.incrementPacks) ||
        !_comparisonNonnegative(offer.availablePacks) ||
        !_comparisonNonnegative(offer.packPriceMinor) ||
        !offer.charges.valid ||
        !offer.validUntil.isAfter(offer.observedAt) ||
        offer.observedAt.isAfter(now)) {
      return reject(BuyV2ComparisonUnavailable.invalidTerms);
    }
    if (offer.queryKey != query.key) {
      return reject(BuyV2ComparisonUnavailable.wrongQuery);
    }
    if (query.productCanonicalId != offer.product.canonicalId ||
        !query.identity.equivalentTo(
          offer.identity,
          samePack: query.samePack,
        )) {
      return reject(BuyV2ComparisonUnavailable.differentProduct);
    }
    if ((query.standardPurchase &&
            offer.channel != BuyV2ComparisonChannel.retail) ||
        (query.purpose == BuyV2ComparisonPurpose.storeProcurement &&
            offer.channel != BuyV2ComparisonChannel.wholesale) ||
        (query.channel != null && offer.channel != query.channel) ||
        (query.fulfilment != null && offer.fulfilment != query.fulfilment) ||
        (query.scope == BuyV2ComparisonScope.local && !offer.local)) {
      return reject(BuyV2ComparisonUnavailable.filtered);
    }
    if (query.purpose == BuyV2ComparisonPurpose.storeProcurement &&
        !query.samePack &&
        (query.identity.containedRetailUnitId == null ||
            query.identity.containedRetailUnitId !=
                offer.identity.containedRetailUnitId)) {
      return reject(BuyV2ComparisonUnavailable.differentProduct);
    }
    if (!offer.serviceable) {
      return reject(BuyV2ComparisonUnavailable.unserviceable);
    }
    if (!offer.customerEligible) {
      return reject(BuyV2ComparisonUnavailable.customerIneligible);
    }
    if (!now.isBefore(offer.validUntil)) {
      return reject(BuyV2ComparisonUnavailable.expired);
    }
    final arrivalStart = offer.arrivalStart;
    final arrivalEnd = offer.arrivalEnd;
    if ((arrivalStart == null) != (arrivalEnd == null) ||
        (arrivalStart != null &&
            arrivalEnd != null &&
            (arrivalEnd.isBefore(arrivalStart) || !now.isBefore(arrivalEnd)))) {
      return reject(BuyV2ComparisonUnavailable.invalidTerms);
    }
    if (query.arriveBy != null &&
        (arrivalEnd == null || arrivalEnd.isAfter(query.arriveBy!))) {
      return reject(BuyV2ComparisonUnavailable.arrivalUnavailable);
    }
    final requested = BigInt.from(query.requestedQuantityMilli);
    final packSize = BigInt.from(offer.identity.packQuantityMilli);
    final minimum = BigInt.from(offer.minimumPacks);
    final increment = BigInt.from(offer.incrementPacks);
    final needed = (requested + packSize - BigInt.one) ~/ packSize;
    final count = needed <= minimum
        ? minimum
        : minimum +
              ((needed - minimum + increment - BigInt.one) ~/ increment) *
                  increment;
    if (count > BigInt.from(offer.availablePacks)) {
      return reject(BuyV2ComparisonUnavailable.insufficientStock);
    }
    var price = offer.packPriceMinor;
    var applicableMinimum = 0;
    final tierMinimums = <int>{};
    for (final tier in offer.tiers) {
      if (!_comparisonPositive(tier.minimumPacks) ||
          !_comparisonNonnegative(tier.packPriceMinor) ||
          !tierMinimums.add(tier.minimumPacks)) {
        return reject(BuyV2ComparisonUnavailable.invalidTerms);
      }
      if (BigInt.from(tier.minimumPacks) <= count &&
          tier.minimumPacks > applicableMinimum) {
        price = tier.packPriceMinor;
        applicableMinimum = tier.minimumPacks;
      }
    }
    final supplied = count * packSize;
    if (supplied != requested && !query.allowExtraQuantity) {
      return reject(BuyV2ComparisonUnavailable.unwantedQuantity);
    }
    final subtotal = count * BigInt.from(price);
    BigInt? payable;
    BigInt? unitPrice;
    if (offer.charges.complete) {
      payable =
          subtotal +
          BigInt.from(offer.charges.taxMinor!) +
          BigInt.from(offer.charges.freightMinor!) +
          BigInt.from(offer.charges.mandatoryFeesMinor!) -
          BigInt.from(offer.charges.immediateDiscountMinor!);
      if (payable.isNegative) {
        return reject(BuyV2ComparisonUnavailable.invalidTerms);
      }
      final numerator = payable * BigInt.from(1000);
      unitPrice =
          (numerator * BigInt.two + supplied) ~/ (supplied * BigInt.two);
    }
    final maximum = BigInt.from(9007199254740991);
    if ([
      count,
      supplied,
      subtotal,
      ?payable,
      ?unitPrice,
    ].any((value) => value > maximum)) {
      return reject(BuyV2ComparisonUnavailable.invalidTerms);
    }
    return BuyV2ComparisonCalculation._(
      packCount: count.toInt(),
      suppliedQuantityMilli: supplied.toInt(),
      excessQuantityMilli: (supplied - requested).toInt(),
      packPriceMinor: price,
      itemSubtotalMinor: subtotal.toInt(),
      payableMinor: payable?.toInt(),
      comparableUnitMinor: unitPrice?.toInt(),
      arrivalEnd: arrivalEnd,
    );
  }
}

@immutable
class BuyV2ComparisonPageRequest {
  const BuyV2ComparisonPageRequest({
    required this.query,
    this.snapshotId,
    this.cursor,
    this.pageSize = 20,
  });
  final BuyV2ComparisonQuery query;
  final String? snapshotId;
  final String? cursor;
  final int pageSize;
  bool get valid =>
      query.valid &&
      pageSize > 0 &&
      pageSize <= 40 &&
      ((snapshotId == null && cursor == null) ||
          (_comparisonId(snapshotId ?? '') && _comparisonId(cursor ?? '')));
}

/// The provider must rank the complete eligible query before pagination.
/// Ranking a downloaded page cannot establish a cheapest/fastest result.
@immutable
class BuyV2ComparisonPage {
  BuyV2ComparisonPage({
    required this.queryKey,
    required this.snapshotId,
    required this.observedAt,
    required this.validUntil,
    required List<BuyV2ComparisonOffer> offers,
    required this.globallyRanked,
    this.startIndex = 0,
    this.totalCount,
    this.previousCursor,
    this.nextCursor,
    this.lowestItemPriceOfferId,
    this.lowestDeliveredOfferId,
    this.earliestArrivalOfferId,
  }) : offers = List.unmodifiable(offers);

  final String queryKey;
  final String snapshotId;
  final DateTime observedAt;
  final DateTime validUntil;
  final List<BuyV2ComparisonOffer> offers;
  final bool globallyRanked;
  final int startIndex;
  final int? totalCount;
  final String? previousCursor;
  final String? nextCursor;
  final String? lowestItemPriceOfferId;
  final String? lowestDeliveredOfferId;
  final String? earliestArrivalOfferId;

  bool validFor(BuyV2ComparisonPageRequest request, DateTime now) {
    if (!request.valid ||
        queryKey != request.query.key ||
        !_comparisonId(snapshotId) ||
        (request.snapshotId != null && request.snapshotId != snapshotId) ||
        observedAt.isAfter(now) ||
        !validUntil.isAfter(observedAt) ||
        !now.isBefore(validUntil) ||
        startIndex < 0 ||
        (request.cursor == null && startIndex != 0) ||
        offers.length > request.pageSize ||
        (offers.isEmpty && nextCursor != null) ||
        (startIndex == 0 && previousCursor != null) ||
        (startIndex > 0 && previousCursor == null) ||
        (previousCursor != null &&
            (!_comparisonId(previousCursor!) ||
                previousCursor == request.cursor ||
                previousCursor == nextCursor)) ||
        (totalCount != null &&
            (totalCount! < startIndex + offers.length ||
                (nextCursor == null &&
                    totalCount != startIndex + offers.length) ||
                (nextCursor != null &&
                    totalCount! <= startIndex + offers.length))) ||
        (nextCursor != null &&
            (!_comparisonId(nextCursor!) || nextCursor == request.cursor))) {
      return false;
    }
    final ids = <String>{};
    final calculations = <String, BuyV2ComparisonCalculation>{};
    for (final offer in offers) {
      final calculation = BuyV2ComparisonCalculation.evaluate(
        query: request.query,
        offer: offer,
        now: now,
      );
      if (!ids.add(offer.id) ||
          offer.snapshotId != snapshotId ||
          offer.observedAt != observedAt ||
          offer.validUntil.isAfter(validUntil) ||
          !calculation.available) {
        return false;
      }
      calculations[offer.id] = calculation;
    }
    if (globallyRanked) {
      final cheapestItem = calculations[lowestItemPriceOfferId];
      if (cheapestItem != null &&
          calculations.values.any(
            (value) =>
                value.itemSubtotalMinor! < cheapestItem.itemSubtotalMinor!,
          )) {
        return false;
      }
      final cheapest = calculations[lowestDeliveredOfferId];
      final fastest = calculations[earliestArrivalOfferId];
      if (cheapest != null &&
          (cheapest.payableMinor == null ||
              calculations.values.any(
                (value) =>
                    value.payableMinor != null &&
                    value.payableMinor! < cheapest.payableMinor!,
              ))) {
        return false;
      }
      if (fastest != null &&
          (fastest.arrivalEnd == null ||
              calculations.values.any(
                (value) =>
                    value.arrivalEnd != null &&
                    value.arrivalEnd!.isBefore(fastest.arrivalEnd!),
              ))) {
        return false;
      }
    }
    return true;
  }

  bool isLowestItemPrice(
    BuyV2ComparisonOffer offer,
    BuyV2ComparisonCalculation calculation,
  ) =>
      globallyRanked &&
      offers.contains(offer) &&
      calculation.available &&
      calculation.itemSubtotalMinor != null &&
      offer.id == lowestItemPriceOfferId;

  bool isLowestDelivered(
    BuyV2ComparisonOffer offer,
    BuyV2ComparisonCalculation calculation,
  ) =>
      globallyRanked &&
      offers.contains(offer) &&
      calculation.available &&
      calculation.payableMinor != null &&
      offer.id == lowestDeliveredOfferId;

  bool isEarliestArrival(
    BuyV2ComparisonOffer offer,
    BuyV2ComparisonCalculation calculation,
  ) =>
      globallyRanked &&
      offers.contains(offer) &&
      calculation.available &&
      calculation.arrivalEnd != null &&
      offer.id == earliestArrivalOfferId;
}

/// Authentication, supplier eligibility, geographical serviceability and
/// complete-query ranking belong to this provider, not display-label parsing.
/// A successful response is not payment or cart authority.
abstract interface class BuyV2ComparisonSource {
  /// Returns published metadata for this exact listing, or null when the
  /// product's specification or pack conversion has not been established.
  BuyV2ComparisonIdentity? identityFor(BuyV2Product product);

  Future<BuyV2ComparisonPage> load(BuyV2ComparisonPageRequest request);
}

bool _comparisonId(String value) => value.isNotEmpty && value.trim() == value;
bool _comparisonNonnegative(int value) =>
    value >= 0 && value <= 9007199254740991;
bool _comparisonPositive(int value) =>
    value > 0 && _comparisonNonnegative(value);
