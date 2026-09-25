import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../work/scan_and_pick_contract.dart';
import 'buy_v2_cart_contracts.dart';
import 'buy_v2_models.dart';

export 'buy_v2_models.dart'
    show
        BuyV2ProductContentMediaKind,
        BuyV2ProductMediaAsset,
        BuyV2MediaFileMetadata,
        BuyV2ProductMediaBinding;

enum BuyV2FulfilmentMode { quickLocal, standardCourier, bulkFreight }

/// Public listing identity only; never include an account or procurement draft.
Uri buyV2SharedProductUri(BuyV2Product product) => Uri.https(
  'moolsocial.com',
  '/app/buy',
  {'sub': product.destination.name, 'view': 'product', 'product': product.id},
);

enum BuyV2StoreOperatingState { unknown, open, closed }

/// Geographic scope is explicit; a destination search does not claim routing.
enum BuyV2CatalogueAreaScope { regional, national, allAreas }

/// A Google Maps place resolved to the catalogue's authoritative region ID.
/// This is a browsing location, never a delivery-serviceability guarantee.
@immutable
class BuyV2ShoppingArea {
  const BuyV2ShoppingArea({
    required this.regionId,
    required this.googlePlaceId,
    required this.label,
    required this.countryCode,
    this.postalCode,
  });

  final String regionId;
  final String googlePlaceId;
  final String label;
  final String countryCode;
  final String? postalCode;

  bool get valid =>
      regionId.trim().isNotEmpty &&
      regionId.length <= 512 &&
      googlePlaceId.trim().isNotEmpty &&
      googlePlaceId.length <= 512 &&
      label.trim().isNotEmpty &&
      label.length <= 240 &&
      countryCode == 'IN' &&
      (postalCode == null || RegExp(r'^[1-9][0-9]{5}$').hasMatch(postalCode!));
}

enum BuyV2ShoppingAreaFailure { unavailable, offline, permissionDenied }

/// The provider owns Google Places/Geocoding, India filtering, session tokens,
/// location permission and the place-to-catalogue-region mapping. Do not infer
/// a PIN or region ID from display text. No API keys belong in this contract.
abstract interface class BuyV2ShoppingAreaSource {
  Future<List<BuyV2ShoppingArea>> search(String query);
  Future<BuyV2ShoppingArea?> locate();
  Future<BuyV2ShoppingArea?> resolve(String googlePlaceId);
}

/// The source authenticates publication authority; a display name never grants it.
enum BuyV2OfferPublisherType { manufacturer, wholesaler, retailer, moolSocial }

/// Immutable request identity shared by Store, category, Offers and Search.
/// A response for another identity must never replace the visible results.
@immutable
class BuyV2CatalogueQuery {
  BuyV2CatalogueQuery({
    required this.destination,
    required this.regionId,
    this.customerLocationKey = '',
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
    this.supplierOffersOnly = false,
    this.procurementContext,
  }) : brands = Set.unmodifiable(brands);

  final BuyV2Destination destination;
  final String? regionId;
  final String customerLocationKey;
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

  /// Applies before counting/paging; supplier publications exclude MoolSocial.
  final bool supplierOffersOnly;

  bool acceptsOfferPublisher(BuyV2OfferPublisherType publisher) =>
      (!supplierOffersOnly ||
          publisher != BuyV2OfferPublisherType.moolSocial) &&
      (offerPublisher == null || offerPublisher == publisher);
  final BuyV2ProcurementContext? procurementContext;

  String get key => jsonEncode([
    customerLocationKey.isNotEmpty ? 4 : (procurementContext == null ? 2 : 3),
    destination.name,
    regionId,
    if (customerLocationKey.isNotEmpty) customerLocationKey,
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
    if (supplierOffersOnly) 'supplierOffersOnly',
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

  /// Pickup is offered by every Store. Legacy opt-in capability metadata is
  /// not an ordering gate; a real branch identity and collection address are.
  bool get hasCollectionAddress =>
      id.isNotEmpty &&
      id.trim() == id &&
      name.trim().isNotEmpty &&
      address.trim().isNotEmpty;
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

/// Complete dimension choices for one selected SKU, plus only its selectable
/// neighbours. Providers resolve combinations; clients never build a Cartesian
/// catalogue or infer missing choices from the current discovery page.
abstract interface class BuyV2VariantFamilySource {
  Future<BuyV2VariantFamilySnapshot> loadVariantFamily(
    BuyV2Product selected,
    BuyV2CatalogueQuery context,
  );
}

class BuyV2VariantFamilySnapshot {
  BuyV2VariantFamilySnapshot({
    required this.productId,
    required this.canonicalId,
    required this.storeId,
    required this.destination,
    required this.queryKey,
    required this.sourceId,
    required this.revision,
    required this.observedAt,
    required this.validUntil,
    required this.complete,
    required this.selectedAvailable,
    required Iterable<BuyV2VariantAttribute> options,
    required Iterable<BuyV2Product> candidates,
  }) : options = List.unmodifiable(options),
       candidates = List.unmodifiable(candidates);

  final String productId;
  final String canonicalId;
  final String storeId;
  final BuyV2Destination destination;
  final String queryKey;
  final String sourceId;
  final String revision;
  final DateTime observedAt;
  final DateTime validUntil;
  final bool complete;
  /// Publication membership, not a stock or delivery promise. Offer facts and
  /// checkout still authorize availability for the selected location.
  final bool selectedAvailable;
  final List<BuyV2VariantAttribute> options;
  final List<BuyV2Product> candidates;

  bool isValidFor(
    BuyV2Product selected,
    BuyV2CatalogueQuery context,
    DateTime now,
  ) {
    bool identity(String value) =>
        value.trim().isNotEmpty && value.trim() == value;
    if (!complete ||
        !selected.hasStructuredVariants ||
        !identity(productId) ||
        !identity(canonicalId) ||
        !identity(storeId) ||
        productId != selected.id ||
        canonicalId != selected.canonicalId ||
        storeId != selected.storeId ||
        destination != selected.destination ||
        context.storeId != storeId ||
        context.destination != destination ||
        queryKey != context.key ||
        !identity(sourceId) ||
        !identity(revision) ||
        observedAt.isAfter(now) ||
        !now.isBefore(validUntil) ||
        !observedAt.isBefore(validUntil)) {
      return false;
    }
    final dimensions = {
      for (final a in selected.variantAttributes) a.dimensionId: a,
    };
    final choices = <(String, String), BuyV2VariantAttribute>{};
    for (final option in options) {
      if (!option.isValid ||
          dimensions[option.dimensionId]?.kind != option.kind ||
          choices.containsKey((option.dimensionId, option.optionId))) {
        return false;
      }
      choices[(option.dimensionId, option.optionId)] = option;
    }
    if (selectedAvailable &&
        selected.variantAttributes.any(
          (a) => !choices.containsKey((a.dimensionId, a.optionId)),
        )) {
      return false;
    }
    final ids = <String>{};
    final combinations = <String>{};
    for (final candidate in candidates) {
      if (!identity(candidate.id) ||
          !ids.add(candidate.id) ||
          !candidate.hasStructuredVariants ||
          !candidate.isFromSameStoreAs(selected) ||
          candidate.destination != destination ||
          candidate.canonicalId != canonicalId ||
          candidate.categoryId != selected.categoryId ||
          candidate.offerClass != selected.offerClass ||
          !candidate.catalogueListing ||
          candidate.variantAttributes.length != dimensions.length) {
        return false;
      }
      var changed = 0;
      final combination = <String, String>{};
      for (final attribute in candidate.variantAttributes) {
        final dimension = dimensions[attribute.dimensionId];
        if (dimension == null ||
            dimension.kind != attribute.kind ||
            !choices.containsKey((attribute.dimensionId, attribute.optionId))) {
          return false;
        }
        if (dimension.optionId != attribute.optionId) changed++;
        combination[attribute.dimensionId] = attribute.optionId;
      }
      final ordered = combination.keys.toList()..sort();
      if (changed > 1 ||
          (candidate.id == selected.id && changed != 0) ||
          (candidate.id != selected.id && changed == 0) ||
          !combinations.add(
            jsonEncode([
              for (final id in ordered) [id, combination[id]],
            ]),
          )) {
        return false;
      }
    }
    return selectedAvailable == ids.contains(selected.id);
  }
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

/// Public provider contract v1. Never derive these grants from display copy,
/// MOQ, Store switches alone, or the transport used for a different service.

@immutable
class BuyV2OfferEligibility {
  BuyV2OfferEligibility({
    required this.productId,
    required this.storeId,
    required this.sourceRevision,
    required this.customerLocationKey,
    required this.observedAt,
    required this.expiresAt,
    required this.offerClass,
    required this.channelEnabled,
    required this.storeReady,
    required this.fleetAvailable,
    required this.customerLocationConfirmed,
    required Set<BuyV2DeliveryOption> options,
    this.scheduledSlotId,
    this.scheduledStart,
    this.scheduledEnd,
    this.reviewFixture = false,
  }) : options = Set.unmodifiable(options);

  static const schemaVersion = 1;
  final String productId, storeId, sourceRevision, customerLocationKey;
  final DateTime observedAt, expiresAt;
  final BuyV2OfferClass offerClass;
  final bool channelEnabled, storeReady, fleetAvailable, reviewFixture;
  final bool customerLocationConfirmed;
  final Set<BuyV2DeliveryOption> options;
  final String? scheduledSlotId;
  final DateTime? scheduledStart, scheduledEnd;

  Set<BuyV2DeliveryOption> availableFor({
    required BuyV2Product product,
    required String locationKey,
    required DateTime now,
    bool allowReviewFixture = false,
  }) {
    if ((reviewFixture && !allowReviewFixture) ||
        product.id != productId ||
        product.storeId != storeId ||
        storeId.trim().isEmpty ||
        sourceRevision.trim().isEmpty ||
        customerLocationKey.isEmpty ||
        locationKey != customerLocationKey ||
        product.offerClass != offerClass ||
        !channelEnabled ||
        !storeReady ||
        observedAt.isAfter(now) ||
        !expiresAt.isAfter(observedAt) ||
        !now.isBefore(expiresAt)) {
      return const {};
    }
    return Set.unmodifiable(
      options.where(
        (option) => switch (option) {
          BuyV2DeliveryOption.quick =>
            fleetAvailable && customerLocationConfirmed,
          BuyV2DeliveryOption.scheduled =>
            fleetAvailable &&
                customerLocationConfirmed &&
                scheduledSlotId?.trim().isNotEmpty == true &&
                scheduledStart != null &&
                scheduledEnd != null &&
                scheduledStart!.isAfter(now) &&
                scheduledEnd!.isAfter(scheduledStart!),
          _ => true,
        },
      ),
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'productId': productId,
    'storeId': storeId,
    'sourceRevision': sourceRevision,
    'customerLocationKey': customerLocationKey,
    'observedAt': observedAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'offerClass': offerClass.name,
    'channelEnabled': channelEnabled,
    'storeReady': storeReady,
    'fleetAvailable': fleetAvailable,
    'customerLocationConfirmed': customerLocationConfirmed,
    'options': options.map((option) => option.name).toList()..sort(),
    'scheduledSlotId': scheduledSlotId,
    'scheduledStart': scheduledStart?.toUtc().toIso8601String(),
    'scheduledEnd': scheduledEnd?.toUtc().toIso8601String(),
    'reviewFixture': reviewFixture,
  };

  /// An incomplete/unknown payload provides no eligibility; callers must not
  /// replace it with a permissive default or manufacture provider evidence.
  static BuyV2OfferEligibility? fromJson(Map<String, dynamic> json) {
    try {
      if (json['schemaVersion'] != schemaVersion) return null;
      DateTime date(Object? value) {
        final text = value as String;
        if (!text.endsWith('Z')) throw const FormatException('UTC required');
        return DateTime.parse(text);
      }

      return BuyV2OfferEligibility(
        productId: json['productId'] as String,
        storeId: json['storeId'] as String,
        sourceRevision: json['sourceRevision'] as String,
        customerLocationKey: json['customerLocationKey'] as String,
        observedAt: date(json['observedAt']),
        expiresAt: date(json['expiresAt']),
        offerClass: BuyV2OfferClass.values.byName(json['offerClass'] as String),
        channelEnabled: json['channelEnabled'] as bool,
        storeReady: json['storeReady'] as bool,
        fleetAvailable: json['fleetAvailable'] as bool,
        customerLocationConfirmed: json['customerLocationConfirmed'] as bool,
        options: (json['options'] as List)
            .map((value) => BuyV2DeliveryOption.values.byName(value as String))
            .toSet(),
        scheduledSlotId: json['scheduledSlotId'] as String?,
        scheduledStart: json['scheduledStart'] == null
            ? null
            : date(json['scheduledStart']),
        scheduledEnd: json['scheduledEnd'] == null
            ? null
            : date(json['scheduledEnd']),
        reviewFixture: json['reviewFixture'] as bool? ?? false,
      );
    } on Object {
      return null;
    }
  }
}

BuyV2FulfilmentMode buyV2CatalogueFulfilmentModeFor(BuyV2Product product) {
  // Legacy display grouping for review fixtures. Eligibility is a separate,
  // location-bound provider contract and must be checked before ordering.
  if (product.reviewDeliveryOptions.contains(BuyV2DeliveryOption.quick)) {
    return BuyV2FulfilmentMode.quickLocal;
  }
  if (product.reviewDeliveryOptions.contains(BuyV2DeliveryOption.freight)) {
    return BuyV2FulfilmentMode.bulkFreight;
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
    this.eligibility,
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
  final BuyV2OfferEligibility? eligibility;
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
    BuyV2OfferEligibility? eligibility,
    bool clearEligibility = false,
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
      eligibility: clearEligibility ? null : eligibility ?? this.eligibility,
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
        other.eligibility == eligibility &&
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
    eligibility,
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

enum BuyV2AttributeType {
  text,
  number,
  boolean,
  measurement,
  textList,
  unknown,
}

/// Product information is separate from selectable options and seller terms.
enum BuyV2AttributeScope { product, variant, offer, lot }

class BuyV2CategoryAttribute {
  const BuyV2CategoryAttribute({
    required this.id,
    required this.label,
    required this.type,
    this.value,
    this.unit,
    this.groupLabel,
    this.categoryIds = const {},
    this.scope = BuyV2AttributeScope.product,
    this.isPublic = true,
    this.requiredForDisplay = false,
  });

  final String id;
  final String label;
  final BuyV2AttributeType type;
  final Object? value;
  final String? unit;
  final String? groupLabel;
  final Set<String> categoryIds;
  final BuyV2AttributeScope scope;
  final bool isPublic;
  final bool requiredForDisplay;

  bool appliesTo(String categoryId) =>
      isPublic &&
      (scope == BuyV2AttributeScope.product ||
          scope == BuyV2AttributeScope.variant) &&
      (categoryIds.isEmpty || categoryIds.contains(categoryId));

  bool get hasValidValue {
    final supplied = value;
    if (unit != null && (unit!.trim().isEmpty || unit != unit!.trim())) {
      return false;
    }
    if (type != BuyV2AttributeType.measurement && unit != null) return false;
    return switch (type) {
      BuyV2AttributeType.text =>
        supplied is String && supplied.trim().isNotEmpty,
      BuyV2AttributeType.number => supplied is num && supplied.isFinite,
      BuyV2AttributeType.boolean => supplied is bool,
      BuyV2AttributeType.measurement =>
        supplied is num && supplied.isFinite && unit != null,
      BuyV2AttributeType.textList =>
        supplied is List<String> &&
            supplied.isNotEmpty &&
            supplied.every((item) => item.trim().isNotEmpty),
      BuyV2AttributeType.unknown => false,
    };
  }

  BuyV2ProductSpecification get specification {
    final supplied = value;
    final display = switch (type) {
      BuyV2AttributeType.boolean => supplied == true ? 'Yes' : 'No',
      BuyV2AttributeType.measurement => '$supplied $unit',
      BuyV2AttributeType.textList => (supplied as List<String>).join(', '),
      _ => '$supplied',
    };
    return BuyV2ProductSpecification(
      attributeId: id,
      label: label,
      value: display,
      groupLabel: groupLabel,
    );
  }
}

/// An adapter supplies a versioned public schema for the selected category.
/// Unknown optional fields stay hidden; invalid required facts reject readiness.
class BuyV2CategoryFacts {
  const BuyV2CategoryFacts({
    required this.categoryId,
    required this.fields,
    this.schemaVersion = 1,
  });

  final String categoryId;
  final int schemaVersion;
  final List<BuyV2CategoryAttribute> fields;

  bool isValidFor(BuyV2Product product) {
    if (schemaVersion != 1 ||
        categoryId != product.categoryId ||
        categoryId.trim().isEmpty) {
      return false;
    }
    final ids = <String>{};
    for (final field in fields) {
      if (field.id.trim().isEmpty ||
          field.id != field.id.trim() ||
          !ids.add(field.id)) {
        return false;
      }
      if (!field.appliesTo(categoryId)) continue;
      if (field.label.trim().isEmpty ||
          (field.groupLabel != null && field.groupLabel!.trim().isEmpty) ||
          (field.requiredForDisplay && !field.hasValidValue)) {
        return false;
      }
    }
    return true;
  }

  List<BuyV2ProductSpecification> specificationsFor(BuyV2Product product) =>
      !isValidFor(product)
      ? const []
      : List.unmodifiable(
          fields
              .where(
                (field) => field.appliesTo(categoryId) && field.hasValidValue,
              )
              .map((field) => field.specification),
        );
}

@immutable
class BuyV2ProductSpecification {
  // Public legal attribute IDs consumed by the existing compliance owner:
  // generic_name, manufacturer_name/address, packer_name/address,
  // importer_name/address, country_of_origin, manufactured_or_packed_on,
  // best_before_or_use_by, fssai_license_number and consumer_care.
  // A supplied structured compliance value takes precedence for its field.
  // net_quantity stays a technical attribute unless structured compliance owns
  // it; pack_count is independent. Other IDs remain source-defined attributes.
  const BuyV2ProductSpecification({
    required this.label,
    required this.value,
    this.attributeId,
    this.groupLabel,
  });

  /// Stable public schema field identity, shared across highlights/specifications.
  /// Absent legacy identity must not be inferred from the displayed value.
  final String? attributeId;
  final String? groupLabel;
  final String label;
  final String value;
}

/// The initial supplier publication contract, not proof of a successful upload
/// or of bytes decoded by a backend. Sources must inspect/normalize the file
/// and publish an immutable HTTPS URI for each asset revision.
abstract final class BuyV2SupplierMediaPolicy {
  static const imageMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};
  static const maximumImageBytes = 10 * 1024 * 1024;
  static const maximumVideoBytes = 50 * 1024 * 1024;
  static const maximumAssets = 10;

  static String? inputMessage({
    required bool video,
    required BuyV2MediaFileMetadata file,
  }) {
    if (file.width <= 0 || file.height <= 0 || file.byteLength <= 0) {
      return 'The file dimensions and size could not be confirmed.';
    }
    if (video) return _videoMessage(file);
    if (!imageMimeTypes.contains(file.mimeType)) {
      return 'Provide a static JPEG, PNG or WebP product photo.';
    }
    if (file.frameCount != 1 ||
        file.duration != null ||
        file.frameRate != null ||
        file.videoCodec != null ||
        file.videoProfile != null ||
        file.audioCodec != null) {
      return 'Provide a static product photo without animation or audio.';
    }
    if (file.byteLength > maximumImageBytes) {
      return 'Each product photo must be 10 MiB or smaller.';
    }
    if (file.width < 512 ||
        file.height < 512 ||
        file.width > 8192 ||
        file.height > 8192 ||
        file.width * file.height > 24000000) {
      return 'Use photos with both sides at least 512 pixels, no side above 8192 pixels, and at most 24 megapixels.';
    }
    return null;
  }

  static String? _videoMessage(BuyV2MediaFileMetadata file) {
    if (file.mimeType != 'video/mp4' ||
        file.videoCodec != 'h264' ||
        file.videoProfile != 'baseline' ||
        (file.audioCodec != null && file.audioCodec != 'aac-lc')) {
      return 'Provide an MP4 video with H.264 Baseline video and optional AAC-LC audio.';
    }
    if (file.byteLength > maximumVideoBytes) {
      return 'Each product video must be 50 MiB or smaller.';
    }
    final duration = file.duration;
    final rate = file.frameRate;
    if (duration == null ||
        duration <= Duration.zero ||
        duration > const Duration(seconds: 60) ||
        rate == null ||
        !rate.isFinite ||
        rate <= 0 ||
        rate > 30) {
      return 'Use a video up to 60 seconds long and 30 frames per second.';
    }
    final longSide = file.width > file.height ? file.width : file.height;
    final shortSide = file.width < file.height ? file.width : file.height;
    if (shortSide <= 0 || longSide > 1280 || shortSide > 720) {
      return 'Use video up to 1280 by 720 pixels, in portrait or landscape.';
    }
    return null;
  }

  static String? _publishedFileMessage({
    required bool video,
    required BuyV2MediaFileMetadata file,
  }) {
    if (!file.normalized) {
      return 'This supplier file has not been prepared for display.';
    }
    if (file.byteLength <= 0 || file.width <= 0 || file.height <= 0) {
      return 'The supplier file size could not be confirmed.';
    }
    if (video) return _videoMessage(file);
    if (!imageMimeTypes.contains(file.mimeType) ||
        file.byteLength > maximumImageBytes ||
        file.width < 128 ||
        file.height < 128 ||
        file.width > 2048 ||
        file.height > 2048 ||
        file.width * file.height > 4000000 ||
        file.frameCount != 1 ||
        file.duration != null ||
        file.frameRate != null ||
        file.videoCodec != null ||
        file.videoProfile != null ||
        file.audioCodec != null) {
      return 'This supplier photo does not meet the display format or size limits.';
    }
    return null;
  }

  static bool _identity(String value) =>
      value.isNotEmpty && value.trim() == value;

  static bool _https(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        uri.fragment.isEmpty;
  }

  static String? publicationMessage(
    BuyV2Product product,
    BuyV2ProductMediaAsset asset,
  ) {
    final binding = asset.binding;
    if (!_identity(asset.id) ||
        asset.label.trim().isEmpty ||
        asset.semanticLabel.trim().isEmpty ||
        binding == null ||
        !_identity(binding.supplierWorkspaceId) ||
        !_identity(binding.assetRevision) ||
        !_identity(binding.storeId) ||
        binding.storeId != product.storeId ||
        !_identity(binding.productId) ||
        !_identity(binding.skuId) ||
        binding.productId != product.canonicalId ||
        binding.skuId != product.id) {
      return 'This supplier photo or video could not be matched to the selected pack.';
    }
    final supplier = product.procurementSupplierGrant;
    if (supplier != null &&
        supplier.workspaceId != binding.supplierWorkspaceId) {
      return 'This media belongs to a different supplier workspace.';
    }
    final video = asset.kind == BuyV2ProductContentMediaKind.networkVideo;
    if ((!video && asset.kind != BuyV2ProductContentMediaKind.network) ||
        !_https(asset.source)) {
      return 'This supplier photo or video has no valid secure source.';
    }
    final fileMessage = _publishedFileMessage(video: video, file: binding.file);
    if (fileMessage != null) return fileMessage;
    if (video) {
      final poster = binding.posterFile;
      if (!_https(asset.posterSource) ||
          poster == null ||
          _publishedFileMessage(video: false, file: poster) != null ||
          asset.transcript?.trim().isNotEmpty != true) {
        return 'This supplier video needs a valid still preview and transcript.';
      }
    }
    return null;
  }

  static List<BuyV2ProductMediaAsset> admittedAssets(BuyV2Product product) {
    final seen = <String>{};
    return List.unmodifiable(
      product.mediaAssets
          .where((asset) => publicationMessage(product, asset) == null)
          .where((asset) => seen.add(asset.id))
          .take(maximumAssets),
    );
  }
}

/// Public category data. The publishing workspace supplies labels and units;
/// Buy never invents category conversions or measurement instructions.
@immutable
class BuyV2ProductSizeChart {
  BuyV2ProductSizeChart({
    required this.categoryId,
    required this.sourceRevision,
    required this.dimensionLabel,
    required List<String> columns,
    required List<List<String>> rows,
    List<String> instructions = const [],
  }) : columns = List.unmodifiable(columns),
       rows = List.unmodifiable(
         rows.map((row) => List<String>.unmodifiable(row)),
       ),
       instructions = List.unmodifiable(instructions);

  final String categoryId;
  final String sourceRevision;
  final String dimensionLabel;
  final List<String> columns;
  final List<List<String>> rows;
  final List<String> instructions;

  bool appliesTo(BuyV2Product product) =>
      categoryId == product.categoryId &&
      categoryId.trim().isNotEmpty &&
      sourceRevision.trim().isNotEmpty &&
      dimensionLabel.trim().isNotEmpty &&
      columns.isNotEmpty &&
      columns.every((value) => value.trim().isNotEmpty) &&
      columns.toSet().length == columns.length &&
      rows.isNotEmpty &&
      rows.every(
        (row) =>
            row.length == columns.length &&
            row.every((value) => value.trim().isNotEmpty),
      );
}

/// Comparable selling prices, not an MRP markdown. All amounts are minor INR
/// units. Publication owns provenance, effective times and expiry; the consumer
/// additionally matches the current Store, SKU, pack, offer and selling price.
@immutable
class BuyV2ProductPriceHistory {
  const BuyV2ProductPriceHistory({
    required this.storeId,
    required this.canonicalProductId,
    required this.skuId,
    required this.pack,
    required this.variant,
    required this.sourceRevision,
    required this.currency,
    required this.previousSellingPriceMinor,
    required this.currentSellingPriceMinor,
    required this.previousEffectiveAt,
    required this.currentEffectiveAt,
    required this.validUntil,
    this.offerId,
  });

  final String storeId;
  final String canonicalProductId;
  final String skuId;
  final String pack;
  final String variant;
  final String sourceRevision;
  final String currency;
  final String? offerId;
  final int previousSellingPriceMinor;
  final int currentSellingPriceMinor;
  final DateTime previousEffectiveAt;
  final DateTime currentEffectiveAt;
  final DateTime validUntil;

  bool isCurrentFor(
    BuyV2Product product, {
    required BuyV2ProductFactsSnapshot facts,
    required DateTime now,
  }) =>
      storeId.isNotEmpty &&
      storeId == product.storeId &&
      canonicalProductId == product.canonicalId &&
      skuId == product.id &&
      pack == product.pack &&
      variant == product.variant &&
      sourceRevision.trim().isNotEmpty &&
      currency == 'INR' &&
      (offerId == null || offerId!.trim().isNotEmpty) &&
      offerId == product.procurementSupplierGrant?.offerId &&
      facts.productId == product.id &&
      !facts.stale &&
      facts.price > 0 &&
      facts.price <= 90071992547409 &&
      previousSellingPriceMinor > 0 &&
      previousSellingPriceMinor <= 9007199254740991 &&
      currentSellingPriceMinor == facts.price * 100 &&
      previousEffectiveAt.isBefore(currentEffectiveAt) &&
      !currentEffectiveAt.isAfter(now) &&
      validUntil.isAfter(now);
}

@immutable
class BuyV2ProductContentSnapshot {
  const BuyV2ProductContentSnapshot({
    required this.productId,
    required this.state,
    required this.sourceId,
    this.media = const [],
    this.highlights = const [],
    this.highlightFields = const [],
    this.specifications = const [],
    this.categoryFacts,
    this.description,
    this.customerMessage,
    this.observedAt,
    this.sizeChart,
    this.priceHistory,
    this.retryable = false,
  });

  final String productId;
  final BuyV2ProductContentState state;
  final String sourceId;
  final List<BuyV2ProductMediaAsset> media;
  final List<String> highlights;
  final List<BuyV2ProductSpecification> highlightFields;
  final List<BuyV2ProductSpecification> specifications;
  final BuyV2CategoryFacts? categoryFacts;

  /// Typed IDs own their fields, including unknown values: never revive an old
  /// legacy value for the same ID when the current provider cannot confirm it.
  List<BuyV2ProductSpecification> specificationsFor(BuyV2Product product) {
    final facts = categoryFacts;
    if (facts == null) return specifications;
    if (!facts.isValidFor(product)) return const [];
    final ownedIds = facts.fields.map((field) => field.id).toSet();
    return [
      ...facts.specificationsFor(product),
      ...specifications.where((field) => !ownedIds.contains(field.attributeId)),
    ];
  }

  List<BuyV2ProductSpecification> highlightsFor(BuyV2Product product) {
    final facts = categoryFacts;
    if (facts == null) return highlightFields;
    if (!facts.isValidFor(product)) return const [];
    final ownedIds = facts.fields.map((field) => field.id).toSet();
    return highlightFields
        .where((field) => !ownedIds.contains(field.attributeId))
        .toList();
  }

  final String? description;
  final String? customerMessage;
  final DateTime? observedAt;
  final BuyV2ProductSizeChart? sizeChart;
  final BuyV2ProductPriceHistory? priceHistory;
  final bool retryable;
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
    this.purchaseOrderRequestId,
    this.purchaseOrderRevision,
    this.purchaseOrderReference,
  }) : lines = List.unmodifiable(lines) {
    if ((purchaseOrderReference != null &&
            (purchaseOrderRequestId == null ||
                !_collectionText(purchaseOrderReference!))) ||
        (purchaseOrderRequestId == null) != (purchaseOrderRevision == null) ||
        (purchaseOrderRequestId != null &&
            (!_collectionText(purchaseOrderRequestId!) ||
                !_collectionText(purchaseOrderRevision!))) ||
        !_collectionText(identity.accountId) ||
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
  final String? purchaseOrderRequestId;
  final String? purchaseOrderRevision;

  /// Provider-issued display reference retained with the durable purchase intent.
  /// It does not replace the request/revision authorization binding.
  final String? purchaseOrderReference;

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
              if (purchaseOrderRequestId != null) ...[
                purchaseOrderRequestId,
                purchaseOrderRevision,
                if (purchaseOrderReference != null) purchaseOrderReference,
              ],
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

  bool collectionAvailableAt(DateTime now) => store.hasCollectionAddress;
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
    this.purchaseOrderRequestId,
    this.purchaseOrderRevision,
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
  final String? purchaseOrderRequestId;
  final String? purchaseOrderRevision;
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

/// Supplier decisions are document states, never evidence of payment.
enum BuyV2PurchaseOrderState {
  draft,
  awaitingSupplier,
  accepted,
  revised,
  rejected,
}

@immutable
class BuyV2PurchaseOrderLine {
  const BuyV2PurchaseOrderLine({
    required this.productId,
    required this.variant,
    required this.pack,
    required this.quantity,
    required this.unitPriceMinor,
    this.requestedQuantity,
  });
  final String productId;
  final String variant;
  final String pack;
  final int quantity;

  /// Original basket quantity, retained when the supplier proposes a change.
  final int? requestedQuantity;
  final int unitPriceMinor;
  int get totalMinor => quantity * unitPriceMinor;
}

@immutable
class BuyV2PurchaseOrderDocument {
  BuyV2PurchaseOrderDocument({
    required this.id,
    required this.revision,
    required this.supplierStoreId,
    required this.supplierName,
    required this.state,
    required List<BuyV2PurchaseOrderLine> lines,
    required this.itemSubtotalMinor,
    required this.chargesMinor,
    required this.totalMinor,
    required this.terms,
    this.reference,
    this.decisionMessage,
  }) : lines = List.unmodifiable(lines);

  final String id;
  final String revision;
  final String supplierStoreId;
  final String supplierName;
  final BuyV2PurchaseOrderState state;
  final List<BuyV2PurchaseOrderLine> lines;
  final int itemSubtotalMinor;
  final int chargesMinor;
  final int totalMinor;
  final String terms;
  final String? reference;
  final String? decisionMessage;

  bool get valid {
    bool text(String value) => value.trim().isNotEmpty;
    final ids = <String>{};
    return text(id) &&
        text(revision) &&
        text(supplierStoreId) &&
        text(supplierName) &&
        text(terms) &&
        lines.isNotEmpty &&
        (state == BuyV2PurchaseOrderState.draft ||
            (reference != null && text(reference!))) &&
        (state != BuyV2PurchaseOrderState.revised &&
                state != BuyV2PurchaseOrderState.rejected ||
            (decisionMessage != null && text(decisionMessage!))) &&
        lines.every(
          (line) =>
              text(line.productId) &&
              text(line.variant) &&
              text(line.pack) &&
              ids.add(line.productId) &&
              line.quantity > 0 &&
              (line.requestedQuantity == null || line.requestedQuantity! > 0) &&
              line.unitPriceMinor >= 0 &&
              line.totalMinor <= 9007199254740991,
        ) &&
        itemSubtotalMinor ==
            lines.fold<int>(0, (sum, line) => sum + line.totalMinor) &&
        chargesMinor >= 0 &&
        totalMinor >= 0 &&
        totalMinor <= 9007199254740991 &&
        totalMinor == itemSubtotalMinor + chargesMinor;
  }
}

@immutable
class BuyV2PurchaseOrderReview {
  BuyV2PurchaseOrderReview({
    required this.requestId,
    required this.revision,
    required this.buyerAccountId,
    required this.buyerName,
    this.address,
    this.collectionStore,
    required this.validUntil,
    required List<BuyV2PurchaseOrderDocument> documents,
  }) : documents = List.unmodifiable(documents);

  final String requestId;
  final String revision;
  final String buyerAccountId;
  final String buyerName;
  final BuyV2Address? address;
  final BuyV2StoreListing? collectionStore;
  final DateTime validUntil;
  final List<BuyV2PurchaseOrderDocument> documents;

  /// Match exact purchased SKU/store/quantity; a label is not an identity.
  bool matches(List<BuyV2CartLine> basket, DateTime now) {
    if (requestId.trim().isEmpty ||
        revision.trim().isEmpty ||
        buyerAccountId.trim().isEmpty ||
        buyerName.trim().isEmpty ||
        !now.isBefore(validUntil) ||
        basket.isEmpty ||
        documents.isEmpty ||
        (address == null) == (collectionStore == null) ||
        (collectionStore != null &&
            (!collectionStore!.hasCollectionAddress ||
                basket.any(
                  (line) => line.product.storeId != collectionStore!.id,
                )))) {
      return false;
    }
    final expected = {for (final line in basket) line.product.id: line};
    if (expected.length != basket.length) return false;
    final seen = <String>{};
    final documentsSeen = <String>{};
    for (final document in documents) {
      if (!document.valid || !documentsSeen.add(document.id)) return false;
      for (final line in document.lines) {
        final purchased = expected[line.productId];
        if (purchased == null ||
            !seen.add(line.productId) ||
            purchased.product.destination != BuyV2Destination.wholesale ||
            purchased.product.storeId != document.supplierStoreId ||
            purchased.product.variant != line.variant ||
            purchased.product.pack != line.pack ||
            (purchased.quantity != (line.requestedQuantity ?? line.quantity) &&
                !(document.state == BuyV2PurchaseOrderState.accepted &&
                    purchased.quantity == line.quantity))) {
          return false;
        }
      }
    }
    return seen.length == expected.length;
  }
}

/// Authenticated provider operations. Repeating the same review revision must
/// reconcile one issuance; implementations must not create a second PO.
abstract interface class BuyV2PurchaseOrderAdapter {
  Future<BuyV2PurchaseOrderReview> review({
    required List<BuyV2CartLine> lines,
    BuyV2Address? address,
    BuyV2StoreListing? collectionStore,
  });
  Future<BuyV2PurchaseOrderReview> issue({
    required String requestId,
    required String expectedRevision,
  });
  Future<BuyV2PurchaseOrderReview> refresh({required String requestId});
  Future<BuyV2PurchaseOrderReview> approveRevision({
    required String requestId,
    required String expectedRevision,
    required String documentId,
    required String documentRevision,
  });
}

enum BuyV2CommercialPaymentTermKind {
  retailAdvance,
  wholesaleAdvance,
  bookingBalanceBeforeDispatch,
  bookingBalanceOnDelivery,
  paymentOnDelivery,
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
    this.advancePercent,
    this.upiTransactionLimit,
    this.acceptedPaymentMethods = const {},
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
  final int? advancePercent;

  /// Current bank/provider-approved limit in the same units as amountDueNow.
  final int? upiTransactionLimit;
  final Set<String> acceptedPaymentMethods;
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
class BuyV2ReceiptLine {
  const BuyV2ReceiptLine({
    required this.productId,
    required this.variant,
    required this.pack,
    required this.orderedQuantity,
    required this.receivedQuantity,
  });

  final String productId;
  final String variant;
  final String pack;
  final int orderedQuantity;
  final int receivedQuantity;

  int get missingQuantity => orderedQuantity - receivedQuantity;
}

/// Authoritative quantities for the entire purchased order, not a shipment
/// fragment. This is receipt evidence; it does not settle or refund payment.
@immutable
class BuyV2ItemisedReceipt {
  BuyV2ItemisedReceipt({
    required this.orderId,
    required this.purchaseId,
    required List<BuyV2ReceiptLine> lines,
  }) : lines = List.unmodifiable(lines);

  final String orderId;
  final String purchaseId;
  final List<BuyV2ReceiptLine> lines;

  bool matchesOrder(BuyV2Order order) {
    if (orderId != order.id ||
        purchaseId.trim().isEmpty ||
        purchaseId != order.purchaseId ||
        lines.isEmpty ||
        lines.length != order.lines.length) {
      return false;
    }
    final matched = <int>{};
    for (final line in lines) {
      if (line.productId.trim().isEmpty ||
          line.orderedQuantity <= 0 ||
          line.receivedQuantity < 0 ||
          line.receivedQuantity > line.orderedQuantity) {
        return false;
      }
      final index = order.lines.indexWhere(
        (purchased) =>
            purchased.product.id == line.productId &&
            purchased.product.variant == line.variant &&
            purchased.product.pack == line.pack &&
            purchased.quantity == line.orderedQuantity,
      );
      if (index < 0 || !matched.add(index)) return false;
    }
    return true;
  }
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
    this.itemisedReceipt,
  });

  final BuyV2CommerceLoadState state;
  final String customerMessage;
  final String? exceptionId;
  final BuyV2DeliveryExceptionKind? kind;
  final String? headline;
  final String? detail;
  final List<String> rescheduleSlots;
  final String? proofReference;
  final BuyV2ItemisedReceipt? itemisedReceipt;
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

/// Optional authenticated lookup for an interrupted placement whose first
/// response never reached the buyer. This operation must not place or pay again.
/// The provider resolves the original immutable attempt by its idempotency key;
/// unavailable/unknown results are not proof of failure or permission to retry.
abstract interface class BuyV2PendingOrderRecoveryAdapter {
  Future<BuyV2OrderPlacementResult> recoverOrder({
    required String idempotencyKey,
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
  const BuyV2CatalogueProductContentAdapter({
    this.includeVariantReviewFixtures = false,
    this.now = DateTime.now,
  });
  final bool includeVariantReviewFixtures;
  final DateTime Function() now;

  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) {
    final returnDetail = product.returnPolicy;
    final supplierMedia = BuyV2SupplierMediaPolicy.admittedAssets(product);
    if (includeVariantReviewFixtures &&
        product.canonicalId == 'review-phone-16' &&
        product.mediaAssets.any(
          (asset) =>
              asset.binding?.supplierWorkspaceId == 'review-phone-workspace',
        ) &&
        product.hasStructuredVariants &&
        product.storeId != null) {
      final storage = product.variantAttributes
          .where((value) => value.dimensionId == 'storage')
          .firstOrNull;
      final bundle = switch (storage?.optionId) {
        '512' => 'Studio review kit',
        '256' => 'Extended review kit',
        _ => 'Basic review kit',
      };
      final observed = now();
      return BuyV2ProductContentSnapshot(
        productId: product.id,
        state: BuyV2ProductContentState.ready,
        sourceId: 'device-review-variant-content',
        observedAt: observed,
        media: supplierMedia,
        highlightFields: [
          BuyV2ProductSpecification(
            attributeId: 'review_bundle',
            label: 'Review bundle',
            value: bundle,
          ),
        ],
        specifications: [
          for (final value in product.variantAttributes)
            BuyV2ProductSpecification(
              attributeId: value.dimensionId,
              label: value.dimensionLabel,
              value: value.optionLabel,
              groupLabel: 'Selected configuration',
            ),
          BuyV2ProductSpecification(
            attributeId: 'review_bundle',
            label: 'Review bundle',
            value: bundle,
            groupLabel: 'In the box',
          ),
        ],
        description: switch (storage?.optionId) {
          '512' =>
            'Review description: expanded offline-library use case. Synthetic content for interface testing.',
          '256' =>
            'Review description: everyday media-library use case. Synthetic content for interface testing.',
          _ =>
            'Review description: lightweight everyday use case. Synthetic content for interface testing.',
        },
        priceHistory: BuyV2ProductPriceHistory(
          storeId: product.storeId!,
          canonicalProductId: product.canonicalId,
          skuId: product.id,
          pack: product.pack,
          variant: product.variant,
          sourceRevision: 'review-history-20260925',
          currency: 'INR',
          previousSellingPriceMinor:
              (product.price + (storage?.optionId == '512' ? 2000 : 1000)) *
              100,
          currentSellingPriceMinor: product.price * 100,
          previousEffectiveAt: observed.subtract(const Duration(days: 7)),
          currentEffectiveAt: observed.subtract(const Duration(hours: 1)),
          validUntil: observed.add(const Duration(hours: 1)),
        ),
      );
    }
    return BuyV2ProductContentSnapshot(
      productId: product.id,
      state: BuyV2ProductContentState.ready,
      sourceId: 'approved-buy-catalogue',
      media: supplierMedia.isNotEmpty
          ? List.unmodifiable(supplierMedia)
          : [
              BuyV2ProductMediaAsset(
                id: '${product.id}-packshot',
                label: 'Catalogue illustration',
                semanticLabel:
                    'Illustration for ${product.title}. '
                    'Supplier photo of this pack is unavailable.',
                kind: BuyV2ProductContentMediaKind.cataloguePackshot,
              ),
            ],
      customerMessage: supplierMedia.length < product.mediaAssets.length
          ? 'Some supplier photos or videos could not be displayed for this pack.'
          : null,
      highlights: [product.variant, product.unitPrice, ?returnDetail],
      specifications: [
        BuyV2ProductSpecification(
          attributeId: 'brand',
          label: 'Brand',
          value: product.brandLabel,
        ),
        BuyV2ProductSpecification(
          attributeId: 'pack',
          label: 'Pack',
          value: product.pack,
        ),
        BuyV2ProductSpecification(
          attributeId: 'variant',
          label: 'Variant',
          value: product.variant,
        ),
      ],
      // A catalogue identity/price summary is not a supplied description.
      // Leave this absent until the content provider publishes actual copy.
      description: null,
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
