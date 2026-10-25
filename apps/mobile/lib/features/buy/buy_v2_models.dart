import 'dart:convert';

import 'buy_v2_catalogue_data.dart';

/// Shared owner/public configuration, never a computed eligibility or saving.
enum BuyV2StoreOfferKind {
  billDiscount, productDiscount, quantityPrice, nextPurchase,
  buyerDiscount, dealerIntro, extraQuantity;

  String get label => switch (this) {
    billDiscount => 'Bill discount', productDiscount => 'Product discount',
    quantityPrice => 'Quantity pricing', nextPurchase => 'Next-purchase coupon',
    buyerDiscount => 'Selected buyers', dealerIntro => 'First business order',
    extraQuantity => 'Extra quantity',
  };
  String get guide => switch (this) {
    billDiscount => 'A saving above your minimum purchase amount.',
    productDiscount => 'A saving on the exact products you select.',
    quantityPrice => 'Publish prices for quantities of one selling SKU.',
    nextPurchase => 'Reward a buyer’s next eligible purchase from this Store.',
    buyerDiscount => 'Offer a saving to selected customer records.',
    dealerIntro => 'An introductory saving for an eligible new business buyer.',
    extraQuantity => 'Specify the purchased and additional product quantities.',
  };
}

String _storeOfferText(Object? value, int maximum, {bool id = false}) {
  if (value is! String || value.isEmpty || value != value.trim() || value.length > maximum ||
      RegExp(r'[\x00-\x1f]').hasMatch(value) ||
      id && !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$').hasMatch(value)) {
    throw const FormatException('Check the offer identity and product details.');
  }
  return value;
}

Map _storeOfferMap(Object? raw, Set<String> keys) {
  if (raw is! Map || raw.length != keys.length || raw.keys.any((key) => !keys.contains(key))) {
    throw const FormatException('Offer details need a compatible app version.');
  }
  return raw;
}

/// A private selection may lack published identities. Only source-issued exact
/// listing identities can make it match a public SKU; names are never authority.
class BuyV2StoreOfferSku {
  BuyV2StoreOfferSku({required this.storeId, required this.skuId, required this.title,
    required this.sellUnit, Iterable<BuyV2PublicListingIdentity> listings = const []})
    : listings = List.unmodifiable(listings) {
    _storeOfferText(storeId, 128, id: true); _storeOfferText(skuId, 128, id: true);
    _storeOfferText(title, 240); _storeOfferText(sellUnit, 240);
    if (this.listings.length > 3 || this.listings.any((listing) => !listing.valid ||
        listing.storeId != storeId || listing.skuId != skuId) ||
        this.listings.map((listing) => listing.channel).toSet().length != this.listings.length) {
      throw const FormatException('Refresh the selected selling SKU.');
    }
  }
  final String storeId, skuId, title, sellUnit;
  final List<BuyV2PublicListingIdentity> listings;
  Map<String, Object?> toJson() => {'storeId': storeId, 'skuId': skuId,
    'title': title, 'sellUnit': sellUnit, 'listings': listings.map((value) => value.toJson()).toList()};
  factory BuyV2StoreOfferSku.fromJson(Object? raw) {
    final row = _storeOfferMap(raw, {'storeId', 'skuId', 'title', 'sellUnit', 'listings'});
    if (row['listings'] is! List) throw const FormatException('Check the product listing.');
    final listings = <BuyV2PublicListingIdentity>[];
    for (final value in row['listings'] as List) {
      final identity = BuyV2PublicListingIdentity.fromJson(value);
      if (identity == null) throw const FormatException('Check the product listing.');
      listings.add(identity);
    }
    return BuyV2StoreOfferSku(storeId: _storeOfferText(row['storeId'], 128, id: true),
      skuId: _storeOfferText(row['skuId'], 128, id: true), title: _storeOfferText(row['title'], 240),
      sellUnit: _storeOfferText(row['sellUnit'], 240), listings: listings);
  }
  bool matches(BuyV2Product product) => product.hasValidPublicListingIdentity &&
    product.publicListingIdentity != null && product.storeId == storeId &&
    product.sourceSkuId == skuId && product.pack == sellUnit && listings.contains(product.publicListingIdentity);
}

class BuyV2StoreOfferTier {
  const BuyV2StoreOfferTier({required this.minimumQuantity, required this.priceMinor});
  final int minimumQuantity, priceMinor;
  Map<String, int> toJson() => {'minimumQuantity': minimumQuantity, 'priceMinor': priceMinor};
  factory BuyV2StoreOfferTier.fromJson(Object? raw) {
    final row = _storeOfferMap(raw, {'minimumQuantity', 'priceMinor'});
    if (row['minimumQuantity'] is! int || row['priceMinor'] is! int) throw const FormatException('Check the price slabs.');
    return BuyV2StoreOfferTier(minimumQuantity: row['minimumQuantity'] as int, priceMinor: row['priceMinor'] as int);
  }
}

/// Proposed structured terms. No customer IDs/history, evaluated savings,
/// stock commitment or public-publishing status belongs in this projection.
class BuyV2StoreOfferTerms {
  BuyV2StoreOfferTerms({required this.storeId, required this.kind,
    Iterable<BuyV2StoreOfferSku> skus = const [], required Iterable<String> channels,
    this.discountKind, this.discountValue, this.minimumSpendMinor = 0, this.maximumSavingMinor,
    Iterable<BuyV2StoreOfferTier> tiers = const [], this.buyQuantity,
    this.rewardSku, this.rewardQuantity, this.nextPurchaseDays})
    : skus = List.unmodifiable(skus), channels = Set.unmodifiable(channels), tiers = List.unmodifiable(tiers) {
    _storeOfferText(storeId, 128, id: true);
    if (this.skus.length > 1000 || this.skus.any((sku) => sku.storeId != storeId) ||
        this.skus.map((sku) => sku.skuId).toSet().length != this.skus.length ||
        this.channels.isEmpty || this.channels.any((channel) => !{'retail', 'wholesale', 'bulk'}.contains(channel)) ||
        minimumSpendMinor < 0 || minimumSpendMinor > 9000000000000) {
      throw const FormatException('Choose products and selling modes from this Store.');
    }
    if (hasMonetaryDiscount) {
      if (!{'flat', 'percentage'}.contains(discountKind) || discountValue == null || discountValue! <= 0 ||
          discountValue! > (discountKind == 'percentage' ? 10000 : 9000000000000) ||
          maximumSavingMinor == null || maximumSavingMinor! <= 0 || maximumSavingMinor! > 9000000000000 ||
          discountKind == 'flat' && maximumSavingMinor != discountValue || this.tiers.isNotEmpty ||
          buyQuantity != null || rewardSku != null || rewardQuantity != null) {
        throw const FormatException('Check the saving, maximum saving and offer type.');
      }
      if (kind == BuyV2StoreOfferKind.productDiscount && this.skus.isEmpty) {
        throw const FormatException('Select the eligible selling SKUs.');
      }
    } else {
      if (discountKind != null || discountValue != null || maximumSavingMinor != null || this.skus.length != 1) {
        throw const FormatException('Choose one selling SKU and its quantity rules.');
      }
      if (kind == BuyV2StoreOfferKind.quantityPrice) {
        if (this.tiers.isEmpty || this.tiers.length > 100 || buyQuantity != null || rewardSku != null || rewardQuantity != null) {
          throw const FormatException('Add quantity and price slabs for this selling unit.');
        }
        var previous = 0;
        for (final tier in this.tiers) {
          if (tier.minimumQuantity <= previous || tier.minimumQuantity > 1000000000 ||
              tier.priceMinor <= 0 || tier.priceMinor > 9000000000000) {
            throw const FormatException('Use increasing quantity thresholds and valid unit prices.');
          }
          previous = tier.minimumQuantity;
        }
      } else if (this.tiers.isNotEmpty || buyQuantity == null || buyQuantity! <= 0 || buyQuantity! > 1000000000 ||
          rewardSku == null || rewardSku!.storeId != storeId || rewardQuantity == null ||
          rewardQuantity! <= 0 || rewardQuantity! > 1000000000) {
        throw const FormatException('Select the purchased and additional quantities from this Store.');
      }
    }
    if (kind == BuyV2StoreOfferKind.nextPurchase
        ? nextPurchaseDays == null || nextPurchaseDays! < 1 || nextPurchaseDays! > 365
        : nextPurchaseDays != null) {
      throw const FormatException('Check the next-purchase validity window.');
    }
  }
  final String storeId;
  final BuyV2StoreOfferKind kind;
  final List<BuyV2StoreOfferSku> skus;
  final Set<String> channels;
  final String? discountKind;
  final int? discountValue, maximumSavingMinor, buyQuantity, rewardQuantity, nextPurchaseDays;
  final int minimumSpendMinor;
  final List<BuyV2StoreOfferTier> tiers;
  final BuyV2StoreOfferSku? rewardSku;
  bool get hasMonetaryDiscount => kind != BuyV2StoreOfferKind.quantityPrice && kind != BuyV2StoreOfferKind.extraQuantity;
  static String amount(int minor) => '${minor ~/ 100}${minor % 100 == 0 ? '' : '.${(minor % 100).toString().padLeft(2, '0')}'}';
  String get savingLabel => switch (kind) {
    BuyV2StoreOfferKind.quantityPrice => '${tiers.length} quantity price ${tiers.length == 1 ? 'slab' : 'slabs'}',
    BuyV2StoreOfferKind.extraQuantity => 'Buy $buyQuantity · Get $rewardQuantity extra',
    _ => discountKind == 'flat' ? '₹${amount(discountValue!)} off'
      : '${amount(discountValue!)}% off · up to ₹${amount(maximumSavingMinor!)}',
  };
  String get scopeLabel => skus.isEmpty ? 'Eligible Store products' : skus.length == 1
    ? '${skus.single.title} · ${skus.single.sellUnit}' : '${skus.length} selected SKUs';
  List<String> get conditions => List.unmodifiable([
    scopeLabel,
    'One promotional offer per supplier in this Cart. Offers cannot be combined.',
    [for (final value in ['retail', 'wholesale', 'bulk']) if (channels.contains(value))
      value == 'retail' ? 'Retail' : value == 'wholesale' ? 'Wholesale' : 'Bulk'].join(' · '),
    if (minimumSpendMinor > 0) 'Minimum eligible purchase ₹${amount(minimumSpendMinor)}',
    if (kind == BuyV2StoreOfferKind.quantityPrice)
      for (final tier in tiers) '${tier.minimumQuantity}+ × ${skus.single.sellUnit}: ₹${amount(tier.priceMinor)} per selling unit',
    if (kind == BuyV2StoreOfferKind.nextPurchase)
      'Next eligible purchase within $nextPurchaseDays days of a qualifying completed purchase.',
    if (kind == BuyV2StoreOfferKind.buyerDiscount) 'For approved buyers. Eligibility is checked for the signed-in buyer.',
    if (kind == BuyV2StoreOfferKind.dealerIntro) 'For an eligible business buyer’s first order from this Store.',
    if (kind == BuyV2StoreOfferKind.extraQuantity)
      'Buy $buyQuantity × ${skus.single.sellUnit}; additional $rewardQuantity × ${rewardSku!.title} (${rewardSku!.sellUnit}).',
    if (kind == BuyV2StoreOfferKind.extraQuantity)
      'One scheme per order. Additional units do not qualify for another reward.',
  ]);
  bool appliesTo(BuyV2Product product) => product.hasValidPublicListingIdentity && product.publicListingIdentity?.valid == true &&
    product.storeId == storeId && channels.contains(product.publicListingIdentity!.channel.name) &&
    (skus.isEmpty || skus.any((sku) => sku.matches(product)));
  String get fingerprint => jsonEncode(toJson());
  Map<String, Object?> toJson() => {'schemaVersion': 1, 'storeId': storeId, 'kind': kind.name,
    'skus': skus.map((sku) => sku.toJson()).toList(), 'channels': channels.toList()..sort(),
    'discountKind': discountKind, 'discountValue': discountValue, 'minimumSpendMinor': minimumSpendMinor,
    'maximumSavingMinor': maximumSavingMinor, 'tiers': tiers.map((tier) => tier.toJson()).toList(),
    'buyQuantity': buyQuantity, 'rewardSku': rewardSku?.toJson(), 'rewardQuantity': rewardQuantity,
    'nextPurchaseDays': nextPurchaseDays};
  factory BuyV2StoreOfferTerms.fromJson(Object? raw) {
    final row = _storeOfferMap(raw, {'schemaVersion', 'storeId', 'kind', 'skus', 'channels',
      'discountKind', 'discountValue', 'minimumSpendMinor', 'maximumSavingMinor', 'tiers',
      'buyQuantity', 'rewardSku', 'rewardQuantity', 'nextPurchaseDays'});
    if (row['schemaVersion'] != 1 || row['schemaVersion'] is! int || row['skus'] is! List ||
        row['channels'] is! List || (row['channels'] as List).any((value) => value is! String) ||
        (row['channels'] as List).toSet().length != (row['channels'] as List).length || row['tiers'] is! List ||
        row['minimumSpendMinor'] is! int || row['discountKind'] != null && row['discountKind'] is! String ||
        ['discountValue', 'maximumSavingMinor', 'buyQuantity', 'rewardQuantity', 'nextPurchaseDays']
          .any((key) => row[key] != null && row[key] is! int)) {
      throw const FormatException('Check the structured offer fields.');
    }
    final kinds = BuyV2StoreOfferKind.values.where((kind) => kind.name == row['kind']);
    if (kinds.length != 1) throw const FormatException('Check the offer type.');
    return BuyV2StoreOfferTerms(storeId: _storeOfferText(row['storeId'], 128, id: true), kind: kinds.single,
      skus: (row['skus'] as List).map(BuyV2StoreOfferSku.fromJson), channels: (row['channels'] as List).cast<String>(),
      discountKind: row['discountKind'] as String?, discountValue: row['discountValue'] as int?,
      minimumSpendMinor: row['minimumSpendMinor'] as int, maximumSavingMinor: row['maximumSavingMinor'] as int?,
      tiers: (row['tiers'] as List).map(BuyV2StoreOfferTier.fromJson), buyQuantity: row['buyQuantity'] as int?,
      rewardSku: row['rewardSku'] == null ? null : BuyV2StoreOfferSku.fromJson(row['rewardSku']),
      rewardQuantity: row['rewardQuantity'] as int?, nextPurchaseDays: row['nextPurchaseDays'] as int?);
  }
}

/// Canonical INR paise. A present minor amount never falls back to legacy
/// whole rupees. BigInt intermediates prevent native multiplication overflow.
int buyV2ExactMinorAmount({int? minor, int? legacyRupees}) {
  final amount = minor == null
      ? legacyRupees == null ? null : BigInt.from(legacyRupees) * BigInt.from(100)
      : BigInt.from(minor);
  if (amount == null || amount < BigInt.zero || amount > BigInt.from(9007199254740991) ||
      minor != null && legacyRupees != null && amount != BigInt.from(legacyRupees) * BigInt.from(100)) {
    throw const FormatException('Invalid or conflicting exact price');
  }
  return amount.toInt();
}

/// Compatibility access only; fractional money must use the exact accessor.
/// Never truncate a new public price into a plausible legacy whole-rupee price.
int buyV2WholeRupees(int minor) {
  buyV2ExactMinorAmount(minor: minor);
  if (minor % 100 != 0) throw const FormatException('Exact paise amount requires a minor-unit consumer');
  return minor ~/ 100;
}

int buyV2MultiplyMinor(int minor, int quantity) {
  buyV2ExactMinorAmount(minor: minor);
  final result = BigInt.from(minor) * BigInt.from(quantity);
  if (quantity < 0 || result > BigInt.from(9007199254740991)) {
    throw const FormatException('Amount exceeds the exact money range');
  }
  return result.toInt();
}

int buyV2SumMinor(Iterable<int> amounts) {
  final total = amounts.fold<BigInt>(BigInt.zero,
    (sum, amount) => sum + BigInt.from(buyV2ExactMinorAmount(minor: amount)));
  if (total > BigInt.from(9007199254740991)) throw const FormatException('Amount exceeds the exact money range');
  return total.toInt();
}

enum BuyV2Destination { shop, wholesale, medicine, orders }

/// Immediate rendered entry surface, never inferred from delivery promises,
/// search text or product metadata. Not persisted with the customer's Cart.
enum BuyV2ProductEntrySurface {
  quick, scheduled, wholesale, bulk, offers, visitStore, unknown;
  String get wireValue => this == visitStore ? 'visit_store' : name;
}

/// Identity is this immutable instance: two opens of the same SKU are distinct.
final class BuyV2ProductVisitContext {
  BuyV2ProductVisitContext(this.surface);
  final BuyV2ProductEntrySurface surface;
}

typedef BuyV2ProductOrigin = ({String productId, BuyV2ProductVisitContext visit});

enum BuyV2ShoppingIntent {
  monthlyBasket,
  businessBuying,
  flexibleRestocking,
  homeShopping,
}

/// Presentation-only direction for a genuine Buy surface replacement.
///
/// Route, Back and restoration outcomes remain owned by [BuyV2Session]. This
/// value lets the fixed Buy body communicate that already-decided outcome; it
/// must never be used to choose, delay or persist navigation.
enum BuyV2NavigationMotionDirection { forward, back, replace }

enum BuyV2View {
  catalogue,
  product,
  cart,
  checkout,
  confirmation,
  tracking,
  orderItems,
  assist,
  account,
  recovery,
}

enum BuyV2CheckoutStep { address, payment, confirm }

enum BuyV2CartScope { all, shop, wholesale, medicine }

enum BuyV2ProcurementPurpose { restock, groupBulkBuying, buyDirect }

enum BuyV2SupplierWorkspaceRole {
  unknown,
  consumer,
  retailer,
  wholesaler,
  mandi,
  manufacturer,
}

enum BuyV2SupplierListingChannel { unknown, consumer, wholesale, bulk }

/// Store-owned entry identity, not a public URL or a grant of purchase access.
/// The originating Store wrapper owns restoration of [originOperationId].
class BuyV2ProcurementContext {
  const BuyV2ProcurementContext({
    required this.accountId,
    required this.storeId,
    required this.purpose,
    required this.originOperationId,
  });

  final String accountId;
  final String storeId;
  final BuyV2ProcurementPurpose purpose;
  final String originOperationId;

  bool get hasIdentity => [
    accountId,
    storeId,
    originOperationId,
  ].every((value) => value.isNotEmpty && value.trim() == value);

  /// Reuses the existing customer-state owner scope without mixing carts.
  /// A wrapper must still verify the current account and approved Store.
  String get customerStateOwnerScope =>
      'buy-procurement:${Uri.encodeComponent(accountId)}:'
      '${Uri.encodeComponent(storeId)}:${purpose.name}:'
      '${Uri.encodeComponent(originOperationId)}';
}

/// Provider-supplied approval for the purchasing account's exact Store.
class BuyV2ProcurementBuyerGrant {
  const BuyV2ProcurementBuyerGrant({
    required this.accountId,
    required this.storeId,
    required this.approved,
    required this.validUntil,
  });

  final String accountId;
  final String storeId;
  final bool approved;
  final DateTime validUntil;
}

/// Supplier workspace authority for one published offer. Display seller names,
/// category labels and group participants cannot supply this authority.
/// Stock, pack/MOQ, serviceability and charges still require the existing
/// product/quote checks; an eligible role alone never makes checkout ready.
class BuyV2ProcurementSupplierGrant {
  const BuyV2ProcurementSupplierGrant({
    required this.workspaceId,
    required this.storeId,
    required this.role,
    required this.approved,
    required this.listingId,
    required this.productCanonicalId,
    required this.offerId,
    required this.offerRevision,
    required this.channel,
    required this.published,
    required this.validUntil,
  });

  final String workspaceId;
  final String storeId;
  final BuyV2SupplierWorkspaceRole role;
  final bool approved;
  final String listingId;
  final String productCanonicalId;
  final String offerId;
  final String offerRevision;
  final BuyV2SupplierListingChannel channel;
  final bool published;
  final DateTime validUntil;
}

enum BuyV2ProcurementEligibility {
  notRequested,
  eligible,
  contextUnavailable,
  buyerUnavailable,
  supplierUnavailable,
  roleNotPermitted,
  listingNotPermitted,
  offerChanged,
}

/// The Store-bound public catalogue retains its own source admissions. Saved
/// products and caller-supplied flags cannot stand in for this current readback.
abstract interface class BuyV2PublicRestockSource {
  BuyV2ProcurementContext? get publicRestockContext;
  bool publicRestockProductCurrent(BuyV2Product product);
}

/// Shared mandatory eligibility decision. It does not apply customer filters,
/// mutate a cart, admit payment, or authorize historical order visibility.
BuyV2ProcurementEligibility buyV2ProcurementEligibility({
  required BuyV2ProcurementContext? context,
  required String? activeAccountId,
  required String? activeStoreId,
  required BuyV2ProcurementBuyerGrant? buyer,
  required BuyV2ProcurementSupplierGrant? supplier,
  required BuyV2Product product,
  required DateTime now,
  String? expectedOfferId,
  String? expectedOfferRevision,
}) {
  if (context == null) return BuyV2ProcurementEligibility.notRequested;
  if (!context.hasIdentity ||
      activeAccountId != context.accountId ||
      activeStoreId != context.storeId) {
    return BuyV2ProcurementEligibility.contextUnavailable;
  }
  if (buyer == null ||
      !buyer.approved ||
      buyer.accountId != context.accountId ||
      buyer.storeId != context.storeId ||
      !now.isBefore(buyer.validUntil)) {
    return BuyV2ProcurementEligibility.buyerUnavailable;
  }
  if (supplier == null ||
      !supplier.approved ||
      !now.isBefore(supplier.validUntil) ||
      [
        supplier.workspaceId,
        supplier.storeId,
        supplier.listingId,
        supplier.productCanonicalId,
        supplier.offerId,
        supplier.offerRevision,
      ].any((value) => value.isEmpty || value.trim() != value)) {
    return BuyV2ProcurementEligibility.supplierUnavailable;
  }
  final rolePermitted = switch (context.purpose) {
    BuyV2ProcurementPurpose.buyDirect =>
      supplier.role == BuyV2SupplierWorkspaceRole.manufacturer,
    BuyV2ProcurementPurpose.restock ||
    BuyV2ProcurementPurpose.groupBulkBuying => const {
      BuyV2SupplierWorkspaceRole.wholesaler,
      BuyV2SupplierWorkspaceRole.mandi,
      BuyV2SupplierWorkspaceRole.manufacturer,
    }.contains(supplier.role),
  };
  if (!rolePermitted) return BuyV2ProcurementEligibility.roleNotPermitted;
  if (!supplier.published ||
      product.destination != BuyV2Destination.wholesale ||
      !const {
        BuyV2SupplierListingChannel.wholesale,
        BuyV2SupplierListingChannel.bulk,
      }.contains(supplier.channel)) {
    return BuyV2ProcurementEligibility.listingNotPermitted;
  }
  if (supplier.storeId != product.storeId ||
      supplier.listingId != product.id ||
      supplier.productCanonicalId != product.canonicalId ||
      (expectedOfferId != null && expectedOfferId != supplier.offerId) ||
      (expectedOfferRevision != null &&
          expectedOfferRevision != supplier.offerRevision)) {
    return BuyV2ProcurementEligibility.offerChanged;
  }
  return BuyV2ProcurementEligibility.eligible;
}

enum BuyV2ProductSort {
  relevance,
  priceLowToHigh,
  priceHighToLow,
  deliveryFastest,
}

enum BuyV2PackFilter { standard, multipack, bulk }

enum BuyV2ShopSaleType { quickDelivery, courier }

enum BuyV2WholesaleSaleType { wholesale, bulk }

enum BuyV2AddressKind { home, work, thirdParty, other }

enum BuyV2OrderStatus { preparing, confirmed, dispatched, arriving, delivered }

enum BuyV2OrdersTab { active, delivered }

enum BuyV2RecoveryKind {
  priceUpdate,
  stockUnavailable,
  serviceAreaUnavailable,
  paymentFailed,
  networkInterruption,
  deliveryDelay,
}

class BuyV2Category {
  const BuyV2Category({
    required this.id,
    required this.label,
    required this.glyph,
  });

  final String id;
  final String label;
  final String glyph;
}

class BuyV2PurchaseProtection {
  const BuyV2PurchaseProtection({
    required this.summary,
    this.remedies = const [],
    this.windowLabel,
    this.conditionsLabel,
    this.verificationLabel,
    this.initiationLabel,
    this.approvalLabel,
    this.pickupLabel,
    this.refundMethodLabel,
    this.refundTimelineLabel,
    this.warrantyLabel,
    this.nonReturnableReason,
    this.policyVersion,
    this.effectiveFromLabel,
  });

  final String summary;
  final List<String> remedies;
  final String? windowLabel;
  final String? conditionsLabel;
  final String? verificationLabel;
  final String? initiationLabel;
  final String? approvalLabel;
  final String? pickupLabel;
  final String? refundMethodLabel;
  final String? refundTimelineLabel;
  final String? warrantyLabel;
  final String? nonReturnableReason;
  final String? policyVersion;
  final String? effectiveFromLabel;
}

class BuyV2ProductCompliance {
  const BuyV2ProductCompliance({
    this.genericName,
    this.netQuantity,
    this.manufacturerName,
    this.manufacturerAddress,
    this.packerName,
    this.packerAddress,
    this.importerName,
    this.importerAddress,
    this.countryOfOrigin,
    this.manufacturedOrPackedOnLabel,
    this.bestBeforeOrUseByLabel,
    this.fssaiLicenseNumber,
    this.consumerCare,
  });

  final String? genericName;
  final String? netQuantity;
  final String? manufacturerName;
  final String? manufacturerAddress;
  final String? packerName;
  final String? packerAddress;
  final String? importerName;
  final String? importerAddress;
  final String? countryOfOrigin;
  final String? manufacturedOrPackedOnLabel;
  final String? bestBeforeOrUseByLabel;
  final String? fssaiLicenseNumber;
  final String? consumerCare;
}

enum BuyV2ProductContentMediaKind {
  cataloguePackshot,
  asset,
  network,
  networkVideo,
}

/// Provider-inspected file facts. Client validation cannot verify file bytes.
class BuyV2MediaFileMetadata {
  const BuyV2MediaFileMetadata({
    required this.mimeType,
    required this.byteLength,
    required this.width,
    required this.height,
    this.normalized = false,
    this.frameCount,
    this.duration,
    this.frameRate,
    this.videoCodec,
    this.videoProfile,
    this.audioCodec,
  });

  final String mimeType;
  final int byteLength;
  final int width;
  final int height;
  final bool normalized;
  final int? frameCount;
  final Duration? duration;
  final double? frameRate;
  final String? videoCodec;
  final String? videoProfile;
  final String? audioCodec;
}

/// Explicit publication identity, never inferred from a product title/category.
class BuyV2ProductMediaBinding {
  const BuyV2ProductMediaBinding({
    required this.supplierWorkspaceId,
    required this.storeId,
    required this.productId,
    required this.skuId,
    required this.assetRevision,
    required this.file,
    this.posterFile,
  });

  final String supplierWorkspaceId;
  final String storeId;
  final String productId;
  final String skuId;
  final String assetRevision;
  final BuyV2MediaFileMetadata file;
  final BuyV2MediaFileMetadata? posterFile;
}

class BuyV2ProductMediaAsset {
  const BuyV2ProductMediaAsset({
    required this.id,
    required this.label,
    required this.semanticLabel,
    required this.kind,
    this.source,
    this.posterSource,
    this.transcript,
    this.binding,
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
  final BuyV2ProductMediaBinding? binding;
}

enum BuyV2OfferClass { retail, wholesale, bulk }

enum BuyV2DeliveryOption { quick, scheduled, courier, freight, collection }

enum BuyV2VariantDimensionKind { colour, size, storage, pack, other }

/// Published option identity for one SKU, never inferred from its title.
class BuyV2VariantAttribute {
  const BuyV2VariantAttribute({
    required this.dimensionId,
    required this.dimensionLabel,
    required this.optionId,
    required this.optionLabel,
    this.kind = BuyV2VariantDimensionKind.other,
    this.swatchArgb,
  });
  final String dimensionId;
  final String dimensionLabel;
  final String optionId;
  final String optionLabel;
  final BuyV2VariantDimensionKind kind;
  final int? swatchArgb;

  bool get isValid =>
      [
        dimensionId,
        dimensionLabel,
        optionId,
        optionLabel,
      ].every((value) => value.trim().isNotEmpty && value.trim() == value) &&
      (swatchArgb == null ||
          (kind == BuyV2VariantDimensionKind.colour &&
              swatchArgb! >= 0 &&
              swatchArgb! <= 0xffffffff));
}

enum BuyV2SupplierTaxBasis { included, additional }

/// One owner-confirmed SKU rate, not automatic HSN classification or a verified
/// payable quote. Calculate against the actual line subtotal, not a cached price.
class BuyV2SupplierGstRate {
  const BuyV2SupplierGstRate({required this.rateBasisPoints, required this.basis});
  final int rateBasisPoints;
  final BuyV2SupplierTaxBasis basis;
  bool get valid => rateBasisPoints >= 0 && rateBasisPoints <= 10000;
  String get percentageText {
    final whole = rateBasisPoints ~/ 100, fraction = rateBasisPoints % 100;
    return fraction == 0 ? '$whole' : '$whole.${fraction.toString().padLeft(2, '0').replaceFirst(RegExp(r'0$'), '')}';
  }
  int taxMinorForSubtotal(int subtotalMinor) {
    if (!valid || subtotalMinor < 0 || subtotalMinor > BuyV2SupplierTaxAmount.maximumMinor) {
      throw const FormatException('Check the GST rate and actual selling subtotal.');
    }
    // Exact integer arithmetic; round once per supplied line subtotal to the
    // nearest paise, half up. Included GST is extracted, never added again.
    final denominator = BigInt.from(basis == BuyV2SupplierTaxBasis.included
      ? 10000 + rateBasisPoints : 10000);
    final numerator = BigInt.from(subtotalMinor) * BigInt.from(rateBasisPoints);
    return ((numerator + denominator ~/ BigInt.two) ~/ denominator).toInt();
  }
  int additionalMinorForSubtotal(int subtotalMinor) {
    final amount = taxMinorForSubtotal(subtotalMinor);
    if (basis == BuyV2SupplierTaxBasis.included) return 0;
    if (amount > BuyV2SupplierTaxAmount.maximumMinor - subtotalMinor) {
      throw const FormatException('The GST-inclusive total is too large.');
    }
    return amount;
  }
  Map<String, Object?> toJson() {
    if (!valid) throw const FormatException('Check the supplier-confirmed GST percentage.');
    return {'version': 1, 'rateBasisPoints': rateBasisPoints, 'basis': basis.name};
  }
  Map<String, Object?> toChannelJson() => {...toJson(), 'version': 2};
  static BuyV2SupplierGstRate? fromChannelJson(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map || raw['version'] is! int || raw['version'] != 2) {
      throw const FormatException('This supplier GST declaration needs review.');
    }
    return fromJson({...raw, 'version': 1});
  }
  static BuyV2SupplierGstRate? fromJson(Object? raw) {
    if (raw == null) return null;
    const invalid = FormatException('Saved GST details need recovery.');
    if (raw is! Map || raw.length != 3 || raw['version'] is! int || raw['version'] != 1 ||
        raw['rateBasisPoints'] is! int || !const ['included', 'additional'].contains(raw['basis'])) {
      throw invalid;
    }
    final value = BuyV2SupplierGstRate(rateBasisPoints: raw['rateBasisPoints'] as int,
      basis: BuyV2SupplierTaxBasis.values.byName(raw['basis'] as String));
    if (!value.valid) throw invalid;
    return value;
  }
}

/// Supplier-declared exact money for one selling pack, never a statutory rate.
/// Null at the owning SKU means unknown; an explicit zero is still supplied.
class BuyV2SupplierTaxAmount {
  const BuyV2SupplierTaxAmount({required this.amountMinor, required this.basis});
  static const maximumMinor = 9007199254740991;
  final int amountMinor;
  final BuyV2SupplierTaxBasis basis;
  bool get valid => amountMinor >= 0 && amountMinor <= maximumMinor;
  bool validForPrice(int unitPriceMinor) => valid && unitPriceMinor >= 0 &&
      unitPriceMinor <= maximumMinor && (basis == BuyV2SupplierTaxBasis.included
        ? amountMinor <= unitPriceMinor : amountMinor <= maximumMinor - unitPriceMinor);
  int taxMinorForPacks(int packs) {
    if (!valid || packs < 1 || packs > maximumMinor ||
        amountMinor != 0 && packs > maximumMinor ~/ amountMinor) {
      throw const FormatException('Supplier tax quantity needs review.');
    }
    return amountMinor * packs;
  }
  int additionalMinorForPacks(int packs) {
    final declared = taxMinorForPacks(packs);
    return basis == BuyV2SupplierTaxBasis.additional ? declared : 0;
  }
  Map<String, Object?> toJson() {
    if (!valid) throw const FormatException('Supplier tax amount needs review.');
    return {'version': 1, 'amountMinor': amountMinor, 'basis': basis.name};
  }
  static BuyV2SupplierTaxAmount? fromJson(Object? raw) {
    if (raw == null) return null;
    const invalid = FormatException('Saved supplier tax needs recovery.');
    if (raw is! Map || raw.length != 3 || raw['version'] is! int || raw['version'] != 1 ||
        raw['amountMinor'] is! int || !const ['included', 'additional'].contains(raw['basis'])) {
      throw invalid;
    }
    final result = BuyV2SupplierTaxAmount(amountMinor: raw['amountMinor'] as int,
        basis: BuyV2SupplierTaxBasis.values.byName(raw['basis'] as String));
    if (!result.valid) throw invalid;
    return result;
  }
}

/// Provider definition of one sellable SKU, independent of order quantity.
/// Net content describes each contained unit, never the entire outer case.
class BuyV2PackPriceTier {
  const BuyV2PackPriceTier({required this.minimumPacks, int? price, int? priceMinor})
    // Public named arguments must not become private initializing formals.
    // ignore: prefer_initializing_formals
    : _legacyPrice = price, _priceMinor = priceMinor;

  final int minimumPacks;

  final int? _legacyPrice, _priceMinor;
  int get priceMinor => buyV2ExactMinorAmount(minor: _priceMinor, legacyRupees: _legacyPrice);
  int get price => _priceMinor == null
      ? _legacyPrice ?? (throw const FormatException('Price is missing'))
      : buyV2WholeRupees(priceMinor);
}

class BuyV2PackTerms {
  const BuyV2PackTerms({
    required this.skuId,
    required this.revision,
    required this.sellUnit,
    this.sourceLabel,
    this.containedUnits = 1,
    this.netContentMilli,
    this.contentUnit,
    this.quantityStep = 1,
    this.requiresMeasurement = false,
    this.unitPriceLabel,
    this.priceTiers = const [],
    this.pricingStoreId,
    this.priceObservedAt,
    this.priceValidUntil,
    this.pricesIncludeTax,
    this.pricesIncludeFreight,
    this.supplierGst,
    this.supplierTax,
    this.commodityPriceRevision,
    this.priceChangesFrequently,
  });

  final String skuId;
  final String revision;
  final String sellUnit;
  /// Exact reviewed selling-pack label; structured quantities remain separate.
  /// Only a product with a matching server listing identity may use this.
  final String? sourceLabel;
  final int containedUnits;
  final int? netContentMilli;
  final String? contentUnit;
  final int quantityStep;
  final bool requiresMeasurement;
  final String? unitPriceLabel;
  final List<BuyV2PackPriceTier> priceTiers;
  final String? pricingStoreId;
  final DateTime? priceObservedAt;
  final DateTime? priceValidUntil;
  final bool? pricesIncludeTax;
  final bool? pricesIncludeFreight;
  final BuyV2SupplierGstRate? supplierGst;
  /// Legacy exact amount; never converted into a GST rate.
  final BuyV2SupplierTaxAmount? supplierTax;
  final int? commodityPriceRevision;
  final bool? priceChangesFrequently;
  String? priceFreshnessLabel(DateTime now) {
    if (commodityPriceRevision == null || priceObservedAt == null) return null;
    final age = now.toUtc().difference(priceObservedAt!.toUtc());
    if (age.isNegative) return 'Price confirmation pending';
    final elapsed = age.inMinutes < 1 ? 'just now' : age.inMinutes < 60 ? '${age.inMinutes} min ago'
      : age.inHours < 24 ? '${age.inHours} hr ago' : '${age.inDays} days ago';
    return pricingCurrentAt(now) ? 'Price confirmed $elapsed' : 'Price confirmation pending · last confirmed $elapsed';
  }
  Map<String, Object?>? get supplierTaxDeclaration =>
      supplierGst?.toChannelJson() ?? supplierTax?.toJson();

  /// Frozen terms only. Expiry is retained, never extended for an old payment.
  Map<String, Object?> toRetainedJson() => {
    'version': commodityPriceRevision == null ? 1 : 2, 'skuId': skuId, 'revision': revision, 'sellUnit': sellUnit,
    if (commodityPriceRevision != null) 'commodityPrice': {'version': 1, 'revision': commodityPriceRevision, 'frequent': priceChangesFrequently},
    'sourceLabel': sourceLabel, 'containedUnits': containedUnits,
    'netContentMilli': netContentMilli, 'contentUnit': contentUnit,
    'quantityStep': quantityStep, 'requiresMeasurement': requiresMeasurement,
    'unitPriceLabel': unitPriceLabel, 'pricingStoreId': pricingStoreId,
    'priceObservedAt': priceObservedAt?.toUtc().toIso8601String(),
    'priceValidUntil': priceValidUntil?.toUtc().toIso8601String(),
    'pricesIncludeTax': pricesIncludeTax, 'pricesIncludeFreight': pricesIncludeFreight,
    'priceTiers': [for (final tier in priceTiers)
      {'minimumPacks': tier.minimumPacks, 'priceMinor': tier.priceMinor}],
    'supplierTax': supplierTaxDeclaration,
  };
  static BuyV2PackTerms? fromRetainedJson(Object? raw) {
    if (raw == null) return null;
    const invalid = FormatException('Saved selling terms need recovery.');
    const strings = ['skuId', 'revision', 'sellUnit'];
    const optionalStrings = ['sourceLabel', 'contentUnit', 'unitPriceLabel', 'pricingStoreId'];
    final commodity = raw is Map && raw['version'] == 2;
    final keys = {'version', 'skuId', 'revision', 'sellUnit', 'sourceLabel', 'containedUnits',
      'netContentMilli', 'contentUnit', 'quantityStep', 'requiresMeasurement', 'unitPriceLabel',
      'pricingStoreId', 'priceObservedAt', 'priceValidUntil', 'pricesIncludeTax',
      'pricesIncludeFreight', 'priceTiers', 'supplierTax', if (commodity) 'commodityPrice'};
    if (raw is! Map || raw.length != keys.length || raw.keys.any((k) => !keys.contains(k)) ||
        raw['version'] is! int || raw['version'] != (commodity ? 2 : 1) ||
        strings.any((k) => raw[k] is! String) ||
        optionalStrings.any((k) => raw[k] != null && raw[k] is! String) ||
        raw['containedUnits'] is! int || raw['quantityStep'] is! int ||
        raw['netContentMilli'] != null && raw['netContentMilli'] is! int ||
        raw['requiresMeasurement'] is! bool ||
        ['pricesIncludeTax', 'pricesIncludeFreight'].any((k) => raw[k] != null && raw[k] is! bool) ||
        raw['priceTiers'] is! List || (raw['priceTiers'] as List).length > 20) { throw invalid; }
    DateTime? time(String key) {
      if (raw[key] == null) return null;
      if (raw[key] is! String) throw invalid;
      final at = DateTime.tryParse(raw[key] as String)?.toUtc();
      if (at == null || at.toIso8601String() != raw[key]) throw invalid;
      return at;
    }
    final declaration = raw['supplierTax'];
    final confirmation = raw['commodityPrice'];
    if (commodity && (confirmation is! Map || confirmation.length != 3 || confirmation['version'] is! int ||
        confirmation['version'] != 1 || confirmation['revision'] is! int || confirmation['frequent'] is! bool)) throw invalid;
    final gst = declaration is Map && declaration['version'] == 2
      ? BuyV2SupplierGstRate.fromChannelJson(declaration) : null;
    final result = BuyV2PackTerms(skuId: raw['skuId'] as String, revision: raw['revision'] as String,
      sellUnit: raw['sellUnit'] as String, sourceLabel: raw['sourceLabel'] as String?,
      containedUnits: raw['containedUnits'] as int, netContentMilli: raw['netContentMilli'] as int?,
      contentUnit: raw['contentUnit'] as String?, quantityStep: raw['quantityStep'] as int,
      requiresMeasurement: raw['requiresMeasurement'] as bool, unitPriceLabel: raw['unitPriceLabel'] as String?,
      pricingStoreId: raw['pricingStoreId'] as String?, priceObservedAt: time('priceObservedAt'),
      priceValidUntil: time('priceValidUntil'), pricesIncludeTax: raw['pricesIncludeTax'] as bool?,
      pricesIncludeFreight: raw['pricesIncludeFreight'] as bool?, supplierGst: gst,
      supplierTax: declaration != null && gst == null ? BuyV2SupplierTaxAmount.fromJson(declaration) : null,
      commodityPriceRevision: commodity ? confirmation['revision'] as int : null,
      priceChangesFrequently: commodity ? confirmation['frequent'] as bool : null,
      priceTiers: List.unmodifiable((raw['priceTiers'] as List).map((t) {
        if (t is! Map || t.length != 2 || t['minimumPacks'] is! int || t['priceMinor'] is! int) throw invalid;
        return BuyV2PackPriceTier(minimumPacks: t['minimumPacks'] as int, priceMinor: t['priceMinor'] as int);
      })));
    if (!result.isValidFor(result.skuId)) throw invalid;
    return result;
  }

  bool validPricingFor(String? storeId, int minimumOrder, {bool requireSourceMetadata = false}) {
    if (priceTiers.isEmpty && !requireSourceMetadata) {
      return pricingStoreId == null &&
          priceObservedAt == null &&
          priceValidUntil == null &&
          pricesIncludeTax == null &&
          pricesIncludeFreight == null;
    }
    // A single converted-unit label cannot describe several changing prices.
    // Until per-tier unit quotes are supplied, show the exact pack basis only.
    if (unitPriceLabel != null ||
        storeId == null ||
        storeId.trim().isEmpty ||
        pricingStoreId != storeId ||
        priceObservedAt == null ||
        priceValidUntil == null ||
        !priceValidUntil!.isAfter(priceObservedAt!) ||
        (priceTiers.isNotEmpty && priceTiers.first.minimumPacks != minimumOrder)) {
      return false;
    }
    var previousMinimum = 0;
    int? previousPrice;
    for (final tier in priceTiers) {
      final int price;
      try { price = tier.priceMinor; } on FormatException { return false; }
      if (tier.minimumPacks <= previousMinimum ||
          tier.minimumPacks > 9007199254740991 ||
          (previousPrice != null && price > previousPrice)) {
        return false;
      }
      previousMinimum = tier.minimumPacks;
      previousPrice = price;
    }
    return true;
  }

  bool pricingCurrentAt(DateTime now) =>
      (priceTiers.isEmpty && pricingStoreId == null && priceObservedAt == null &&
          priceValidUntil == null && pricesIncludeTax == null && pricesIncludeFreight == null) ||
      (priceObservedAt != null &&
          pricingStoreId != null && pricingStoreId!.trim().isNotEmpty &&
          !priceObservedAt!.isAfter(now) &&
          priceValidUntil != null &&
          priceValidUntil!.isAfter(priceObservedAt!) &&
          now.isBefore(priceValidUntil!));

  int priceForQuantity(int quantity, int fallback) {
    var result = fallback;
    for (final tier in priceTiers) {
      if (quantity < tier.minimumPacks) break;
      result = tier.price;
    }
    return result;
  }

  int priceMinorForQuantity(int quantity, int fallbackMinor) {
    var result = buyV2ExactMinorAmount(minor: fallbackMinor);
    for (final tier in priceTiers) {
      if (quantity < tier.minimumPacks) break;
      result = tier.priceMinor;
    }
    return result;
  }

  bool isValidFor(String id) =>
      skuId == id &&
      ((commodityPriceRevision == null && priceChangesFrequently == null) ||
        (commodityPriceRevision != null && commodityPriceRevision! > 0 && commodityPriceRevision! <= 1000000000 &&
          priceChangesFrequently != null && priceObservedAt != null && priceValidUntil != null &&
          priceValidUntil!.isAfter(priceObservedAt!))) &&
      (supplierGst?.valid ?? true) && (supplierTax?.valid ?? true) &&
      (supplierGst == null || supplierTax == null) &&
      (supplierGst == null || pricesIncludeTax == null ||
        pricesIncludeTax == (supplierGst!.basis == BuyV2SupplierTaxBasis.included)) &&
      (supplierTax == null || pricesIncludeTax == null ||
        pricesIncludeTax == (supplierTax!.basis == BuyV2SupplierTaxBasis.included)) &&
      [
        skuId,
        revision,
        sellUnit,
      ].every((value) => value.trim().isNotEmpty && value.trim() == value) &&
      containedUnits > 0 &&
      quantityStep > 0 &&
      containedUnits <= 9007199254740991 &&
      quantityStep <= 9007199254740991 &&
      (sourceLabel == null || (sourceLabel!.trim().isNotEmpty &&
          sourceLabel!.trim() == sourceLabel && sourceLabel!.length <= 240)) &&
      ((netContentMilli == null && contentUnit == null) ||
          (netContentMilli != null &&
              netContentMilli! > 0 &&
              {
                'g',
                'kg',
                'mL',
                'L',
                'mm',
                'cm',
                'm',
                'piece',
              }.contains(contentUnit) &&
              (contentUnit != 'piece' || netContentMilli! % 1000 == 0) &&
              BigInt.from(netContentMilli!) * BigInt.from(containedUnits) <=
                  BigInt.from(9007199254740991))) &&
      (unitPriceLabel == null ||
          (unitPriceLabel!.trim().isNotEmpty &&
              unitPriceLabel!.trim() == unitPriceLabel));

  String get label {
    if (sourceLabel != null) return sourceLabel!;
    final amount = netContentMilli;
    if (amount == null) {
      return containedUnits == 1
          ? sellUnit
          : '$containedUnits units · $sellUnit';
    }
    final fraction = (amount % 1000)
        .toString()
        .padLeft(3, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    final number = '${amount ~/ 1000}${fraction.isEmpty ? '' : '.$fraction'}';
    final content = '$number $contentUnit';
    return '${containedUnits == 1 ? content : '$containedUnits × $content'} · $sellUnit';
  }
}

/// Server-issued public listing identity. It does not grant Stock, delivery,
/// consent, payment or order authority; the original Store SKU is kept intact.
class BuyV2PublicListingIdentity {
  const BuyV2PublicListingIdentity({required this.listingId, required this.realm,
    required this.storeId, required this.skuId, required this.canonicalProductId,
    required this.verifiedPackId, required this.channel});
  final String listingId, realm, storeId, skuId, canonicalProductId, verifiedPackId;
  final BuyV2OfferClass channel;
  bool get valid => listingId == listingId.trim() && RegExp(r'^listing-[a-f0-9]{64}$').hasMatch(listingId) &&
      const {'evaluation', 'production'}.contains(realm) &&
      [storeId, skuId, canonicalProductId, verifiedPackId].every(
        (value) => value == value.trim() && RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$').hasMatch(value));
  bool matches(BuyV2Product product) => valid && listingId == product.id &&
      storeId == product.storeId && canonicalProductId == product.canonicalId &&
      channel == product.offerClass && product.destination ==
        (channel == BuyV2OfferClass.retail ? BuyV2Destination.shop : BuyV2Destination.wholesale);
  Map<String, Object?> toJson() => {'schemaVersion': 1, 'realm': realm, 'listingId': listingId,
    'storeId': storeId, 'skuId': skuId, 'canonicalProductId': canonicalProductId,
    'verifiedPackId': verifiedPackId, 'channel': channel.name};
  static BuyV2PublicListingIdentity? fromJson(Object? value) {
    const keys = {'schemaVersion', 'realm', 'listingId', 'storeId', 'skuId',
      'canonicalProductId', 'verifiedPackId', 'channel'};
    if (value is! Map || value.length != keys.length || value['schemaVersion'] is! int || value['schemaVersion'] != 1 ||
        value.keys.any((key) => !keys.contains(key)) ||
        keys.where((key) => key != 'schemaVersion').any((key) => value[key] is! String)) { return null; }
    final channels = BuyV2OfferClass.values.where((channel) => channel.name == value['channel']);
    if (channels.length != 1) return null;
    final result = BuyV2PublicListingIdentity(listingId: value['listingId'] as String,
      realm: value['realm'] as String, storeId: value['storeId'] as String,
      skuId: value['skuId'] as String, canonicalProductId: value['canonicalProductId'] as String,
      verifiedPackId: value['verifiedPackId'] as String, channel: channels.single);
    return result.valid ? result : null;
  }
  @override
  bool operator ==(Object other) => other is BuyV2PublicListingIdentity &&
      listingId == other.listingId && realm == other.realm && storeId == other.storeId &&
      skuId == other.skuId && canonicalProductId == other.canonicalProductId &&
      verifiedPackId == other.verifiedPackId && channel == other.channel;
  @override
  int get hashCode => Object.hash(listingId, realm, storeId, skuId, canonicalProductId, verifiedPackId, channel);
}

class BuyV2Product {
  const BuyV2Product({
    required this.id,
    String? canonicalId,
    required this.destination,
    required this.categoryId,
    required this.brand,
    required this.title,
    required this.variant,
    required this.pack,
    int? price,
    int? priceMinor,
    required this.unitPrice,
    required this.badge,
    required this.seller,
    required this.sellerType,
    required this.deliveryPromise,
    required this.origin,
    required this.confirmedOn,
    required this.visualLabel,
    required this.visualKind,
    this.merchandisingLabel = '',
    this.procurementSupplierGrant,
    this.mediaAssets = const [],
    this.variantAttributes = const [],
    this.variantFamilyId,
    this.storeId,
    this.publicListingIdentity,
    int? mrp,
    int? mrpMinor,
    this.requiresPrescription = false,
    this.composition,
    this.regulatoryNote,
    this.minimumOrder = 1,
    this.packTerms,
    this.offerClass,
    this.reviewDeliveryOptions = const {},
    this.returnPolicy,
    this.purchaseProtection,
    this.compliance,
    this.freightIncluded = false,
    this.manufacturerVerified = false,
    this.catalogueListing = true,
  }) : canonicalId = canonicalId ?? id,
       // Keep public named compatibility arguments and private backing amounts.
       // ignore: prefer_initializing_formals
       _legacyPrice = price, _priceMinor = priceMinor,
       // ignore: prefer_initializing_formals
       _legacyMrp = mrp, _mrpMinor = mrpMinor;

  final String id;
  final String canonicalId;

  /// Provider-supplied family membership, not the exact canonical SKU identity.
  /// Absent on legacy records; never inferred from product or seller text.
  final String? variantFamilyId;

  /// Stable branch identity from the catalogue source; never a seller label.
  final String? storeId;
  final BuyV2PublicListingIdentity? publicListingIdentity;
  String get sourceSkuId => publicListingIdentity?.skuId ?? id;
  bool get hasValidPublicListingIdentity => publicListingIdentity == null || publicListingIdentity!.matches(this);
  bool get requiresSupplierQuote => publicListingIdentity?.channel == BuyV2OfferClass.bulk && packTerms?.commodityPriceRevision == null;
  final BuyV2Destination destination;
  final String categoryId;
  final String brand;

  /// A catalogue grouping is not a brand or manufacturer identity.
  final String merchandisingLabel;
  final BuyV2ProcurementSupplierGrant? procurementSupplierGrant;
  final List<BuyV2ProductMediaAsset> mediaAssets;
  final List<BuyV2VariantAttribute> variantAttributes;

  bool get hasStructuredVariants =>
      variantAttributes.isNotEmpty &&
      variantAttributes.every((attribute) => attribute.isValid) &&
      variantAttributes
              .map((attribute) => attribute.dimensionId)
              .toSet()
              .length ==
          variantAttributes.length;

  bool get hasValidVariantFamilyIdentity => variantFamilyId == null ||
      (variantFamilyId!.trim().isNotEmpty && variantFamilyId == variantFamilyId!.trim() &&
          storeId != null && storeId!.isNotEmpty && storeId == storeId!.trim() &&
          hasStructuredVariants);

  /// Family grouping never replaces exact SKU/pack/publication validation.
  /// Explicit families require branch identity, not the legacy seller fallback.
  bool isInSameVariantFamilyAs(BuyV2Product other) {
    if (destination != other.destination || categoryId != other.categoryId ||
        !isFromSameStoreAs(other) || !hasValidVariantFamilyIdentity ||
        !other.hasValidVariantFamilyIdentity) { return false; }
    if (variantFamilyId == null && other.variantFamilyId == null) {
      return canonicalId == other.canonicalId;
    }
    return variantFamilyId != null && variantFamilyId == other.variantFamilyId &&
        offerClass == other.offerClass && hasValidPublicListingIdentity &&
        other.hasValidPublicListingIdentity &&
        (publicListingIdentity == null) == (other.publicListingIdentity == null) &&
        publicListingIdentity?.realm == other.publicListingIdentity?.realm;
  }

  /// Resolve a unique SKU without silently changing the other selected options.
  BuyV2Product? resolveVariantOption(
    Iterable<BuyV2Product> family,
    String dimensionId,
    String optionId,
  ) {
    if (!hasStructuredVariants ||
        !variantAttributes.any((value) => value.dimensionId == dimensionId)) {
      return null;
    }
    final matches = family
        .where(
          (candidate) =>
              candidate.isInSameVariantFamilyAs(this) &&
              candidate.destination == destination &&
              candidate.isFromSameStoreAs(this) &&
              candidate.hasStructuredVariants &&
              candidate.variantAttributes.length == variantAttributes.length &&
              variantAttributes.every(
                (selected) => candidate.variantAttributes.any(
                  (value) =>
                      value.dimensionId == selected.dimensionId &&
                      value.kind == selected.kind &&
                      value.optionId ==
                          (selected.dimensionId == dimensionId
                              ? optionId
                              : selected.optionId),
                ),
              ),
        )
        .toList(growable: false);
    return matches.length == 1 ? matches.single : null;
  }

  String get brandLabel =>
      brand.trim().isEmpty ? 'Brand not provided' : brand.trim();
  final String title;
  final String variant;
  final String pack;
  final BuyV2PackTerms? packTerms;
  bool get hasValidPackTerms =>
      packTerms == null ||
      (packTerms!.isValidFor(id) &&
          (packTerms!.sourceLabel == null ||
              (publicListingIdentity != null && hasValidPublicListingIdentity)) &&
          packTerms!.validPricingFor(storeId, minimumOrder,
            requireSourceMetadata: publicListingIdentity != null) &&
          pack == packTerms!.label &&
          unitPrice == (packTerms!.unitPriceLabel ?? ''));
  int get quantityStep => packTerms?.quantityStep ?? 1;
  int minimumOrderTotal(int currentPrice) =>
      (hasValidPackTerms
          ? packTerms?.priceForQuantity(minimumOrder, currentPrice) ??
                currentPrice
          : currentPrice) *
      minimumOrder;
  final int? _legacyPrice, _priceMinor, _legacyMrp, _mrpMinor;
  bool get hasExplicitPriceMinor => _priceMinor != null;
  bool get hasExplicitMrpMinor => _mrpMinor != null;
  int get priceMinor => buyV2ExactMinorAmount(minor: _priceMinor, legacyRupees: _legacyPrice);
  int? get mrpMinor => _mrpMinor == null && _legacyMrp == null ? null
      : buyV2ExactMinorAmount(minor: _mrpMinor, legacyRupees: _legacyMrp);
  bool get hasValidMoney {
    try { priceMinor; mrpMinor; return true; } on FormatException { return false; }
  }
  int minimumOrderTotalMinor([int? currentPriceMinor]) => buyV2MultiplyMinor(
    hasValidPackTerms ? packTerms?.priceMinorForQuantity(minimumOrder, currentPriceMinor ?? priceMinor)
      ?? currentPriceMinor ?? priceMinor : currentPriceMinor ?? priceMinor, minimumOrder);
  /// Legacy whole-rupee access remains exact or throws; it never rounds paise.
  int get price => _priceMinor == null
      ? _legacyPrice ?? (throw const FormatException('Price is missing'))
      : buyV2WholeRupees(priceMinor);
  final String unitPrice;
  final String badge;
  final String seller;
  final String sellerType;
  final String deliveryPromise;
  final String origin;
  final String confirmedOn;
  final String visualLabel;
  final String visualKind;
  int? get mrp => _mrpMinor == null ? _legacyMrp : buyV2WholeRupees(mrpMinor!);
  final bool requiresPrescription;
  final String? composition;
  final String? regulatoryNote;
  final int minimumOrder;

  /// Explicit public offer classification, independent of MOQ and freight.
  final BuyV2OfferClass? offerClass;

  /// Screenbook fixtures only, never authoritative provider eligibility.
  final Set<BuyV2DeliveryOption> reviewDeliveryOptions;
  final String? returnPolicy;
  final BuyV2PurchaseProtection? purchaseProtection;
  final BuyV2ProductCompliance? compliance;
  final bool freightIncluded;
  final bool manufacturerVerified;
  final bool catalogueListing;

  BuyV2Product copyWith({
    String? id,
    String? canonicalId,
    String? variantFamilyId,
    String? storeId,
    BuyV2PublicListingIdentity? publicListingIdentity,
    String? brand,
    String? merchandisingLabel,
    BuyV2ProcurementSupplierGrant? procurementSupplierGrant,
    List<BuyV2ProductMediaAsset>? mediaAssets,
    List<BuyV2VariantAttribute>? variantAttributes,
    String? title,
    String? origin,
    String? variant,
    String? pack,
    int? price,
    int? priceMinor,
    int? mrp,
    int? mrpMinor,
    String? unitPrice,
    String? badge,
    String? deliveryPromise,
    String? seller,
    String? sellerType,
    String? confirmedOn,
    int? minimumOrder,
    BuyV2PackTerms? packTerms,
    BuyV2OfferClass? offerClass,
    Set<BuyV2DeliveryOption>? reviewDeliveryOptions,
    bool? catalogueListing,
    BuyV2PurchaseProtection? purchaseProtection,
    BuyV2ProductCompliance? compliance,
  }) => BuyV2Product(
    id: id ?? this.id,
    canonicalId: canonicalId ?? this.canonicalId,
    variantFamilyId: variantFamilyId ?? this.variantFamilyId,
    storeId: storeId ?? this.storeId,
    publicListingIdentity: publicListingIdentity ?? this.publicListingIdentity,
    destination: destination,
    categoryId: categoryId,
    brand: brand ?? this.brand,
    merchandisingLabel: merchandisingLabel ?? this.merchandisingLabel,
    procurementSupplierGrant:
        procurementSupplierGrant ?? this.procurementSupplierGrant,
    mediaAssets: mediaAssets ?? this.mediaAssets,
    variantAttributes: variantAttributes ?? this.variantAttributes,
    title: title ?? this.title,
    variant: variant ?? this.variant,
    pack: packTerms?.label ?? pack ?? this.pack,
    packTerms: packTerms ?? this.packTerms,
    price: price ?? (priceMinor == null ? _legacyPrice : null),
    priceMinor: priceMinor ?? (price == null ? _priceMinor : null),
    unitPrice: packTerms != null
        ? packTerms.unitPriceLabel ?? ''
        : unitPrice ?? this.unitPrice,
    badge: badge ?? this.badge,
    seller: seller ?? this.seller,
    sellerType: sellerType ?? this.sellerType,
    deliveryPromise: deliveryPromise ?? this.deliveryPromise,
    origin: origin ?? this.origin,
    confirmedOn: confirmedOn ?? this.confirmedOn,
    visualLabel: visualLabel,
    visualKind: visualKind,
    mrp: mrp ?? (mrpMinor == null ? _legacyMrp : null),
    mrpMinor: mrpMinor ?? (mrp == null ? _mrpMinor : null),
    requiresPrescription: requiresPrescription,
    composition: composition,
    regulatoryNote: regulatoryNote,
    minimumOrder: minimumOrder ?? this.minimumOrder,
    offerClass: offerClass ?? this.offerClass,
    reviewDeliveryOptions: reviewDeliveryOptions ?? this.reviewDeliveryOptions,
    returnPolicy: returnPolicy,
    purchaseProtection: purchaseProtection ?? this.purchaseProtection,
    compliance: compliance ?? this.compliance,
    freightIncluded: freightIncluded,
    manufacturerVerified: manufacturerVerified,
    catalogueListing: catalogueListing ?? this.catalogueListing,
  );

  String get partnerRole => buyV2PartnerRoleFor(destination, sellerType);

  /// Legacy catalogues without branch IDs retain their existing grouping.
  /// Once either listing has an ID, display names cannot match a branch.
  bool isFromSameStoreAs(BuyV2Product other) {
    final identity = storeId;
    if (identity != null || other.storeId != null) {
      return identity != null &&
          identity.isNotEmpty &&
          identity.trim() == identity &&
          identity == other.storeId;
    }
    return seller == other.seller;
  }

  String? get regulatoryTrustFact =>
      destination == BuyV2Destination.medicine ? 'Licensed pharmacy' : null;
}

String buyV2PartnerRoleFor(BuyV2Destination destination, String sourceRole) {
  final normalized = sourceRole.toLowerCase();
  if (normalized.contains('manufacturer')) {
    return 'MoolSocial Fulfilment Partner';
  }
  return switch (destination) {
    BuyV2Destination.shop => 'MoolSocial Fulfilment Store',
    BuyV2Destination.wholesale => 'MoolSocial Fulfilment Partner',
    BuyV2Destination.medicine => 'Mool Pharmacy Partner',
    BuyV2Destination.orders => 'MoolSocial Delivery Partner',
  };
}

class BuyV2CustomerReview {
  const BuyV2CustomerReview({
    required this.productCanonicalId,
    required this.rating,
    required this.comment,
    required this.updatedLabel,
  });

  final String productCanonicalId;
  final int rating;
  final String comment;
  final String updatedLabel;
}

/// A buyer's desired single Scheduled window, not a reservation or provider
/// acknowledgement. Past windows remain valid historical data; current
/// eligibility and quantity-aware acknowledgement are separate checks.
class BuyV2ScheduledFulfilment {
  const BuyV2ScheduledFulfilment({required this.listing, required this.sourceRevision,
    required this.locationKey, required this.slotId, required this.startsAt, required this.endsAt});
  final BuyV2PublicListingIdentity listing;
  final String sourceRevision, locationKey, slotId;
  final DateTime startsAt, endsAt;
  bool get valid => listing.valid && [sourceRevision, locationKey, slotId].every(
    (value) => value.isNotEmpty && value.trim() == value) &&
    startsAt.isUtc && endsAt.isUtc && endsAt.isAfter(startsAt);
  bool matches(BuyV2Product product) => valid && listing.matches(product) && product.publicListingIdentity == listing;
  Map<String, Object?> toJson() => {'schemaVersion': 1, 'method': 'scheduled',
    'listing': listing.toJson(), 'sourceRevision': sourceRevision, 'locationKey': locationKey,
    'slotId': slotId, 'startsAt': startsAt.toIso8601String(), 'endsAt': endsAt.toIso8601String()};
  static BuyV2ScheduledFulfilment fromJson(Object? value) {
    const keys = {'schemaVersion', 'method', 'listing', 'sourceRevision', 'locationKey', 'slotId', 'startsAt', 'endsAt'};
    if (value is! Map || value.length != keys.length || value.keys.any((key) => !keys.contains(key)) ||
        value['schemaVersion'] is! int || value['schemaVersion'] != 1 || value['method'] != 'scheduled' ||
        const ['sourceRevision', 'locationKey', 'slotId', 'startsAt', 'endsAt'].any((key) => value[key] is! String)) {
      throw const FormatException('Saved Scheduled choice needs checking.');
    }
    final listing = BuyV2PublicListingIdentity.fromJson(value['listing']);
    final startsAt = DateTime.tryParse(value['startsAt'] as String), endsAt = DateTime.tryParse(value['endsAt'] as String);
    if (listing == null || startsAt == null || endsAt == null ||
        startsAt.toIso8601String() != value['startsAt'] || endsAt.toIso8601String() != value['endsAt']) {
      throw const FormatException('Saved Scheduled choice needs checking.');
    }
    final result = BuyV2ScheduledFulfilment(listing: listing, sourceRevision: value['sourceRevision'] as String,
      locationKey: value['locationKey'] as String, slotId: value['slotId'] as String, startsAt: startsAt, endsAt: endsAt);
    if (!result.valid) throw const FormatException('Saved Scheduled choice needs checking.');
    return result;
  }
  @override
  bool operator ==(Object other) => other is BuyV2ScheduledFulfilment && listing == other.listing &&
    sourceRevision == other.sourceRevision && locationKey == other.locationKey && slotId == other.slotId &&
    startsAt == other.startsAt && endsAt == other.endsAt;
  @override
  int get hashCode => Object.hash(listing, sourceRevision, locationKey, slotId, startsAt, endsAt);
}

class BuyV2CartLine {
  const BuyV2CartLine({required this.product, required this.quantity, this.scheduledFulfilment});

  final BuyV2Product product;
  final int quantity;
  final BuyV2ScheduledFulfilment? scheduledFulfilment;
  bool get hasValidScheduledFulfilment => scheduledFulfilment?.matches(product) ?? true;

  int get total => product.price * quantity;
  int get totalMinor => buyV2MultiplyMinor(product.priceMinor, quantity);

  BuyV2CartLine copyWith({BuyV2Product? product, int? quantity,
    BuyV2ScheduledFulfilment? scheduledFulfilment, bool clearScheduledFulfilment = false}) =>
      BuyV2CartLine(
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
        scheduledFulfilment: clearScheduledFulfilment ? null : scheduledFulfilment ?? this.scheduledFulfilment,
      );
}

class BuyV2FulfilmentGroup {
  const BuyV2FulfilmentGroup({
    required this.groupKey,
    required this.destination,
    required this.partner,
    required this.partnerType,
    required this.promise,
    required this.lines,
    this.promisedByLabel,
    this.dispatchPromise,
    this.deliveryProviderName,
    this.deliveryServiceLevel,
  });

  final String groupKey;
  final BuyV2Destination destination;
  final String partner;
  final String partnerType;
  final String promise;
  final List<BuyV2CartLine> lines;
  final String? promisedByLabel;
  final String? dispatchPromise;
  final String? deliveryProviderName;
  final String? deliveryServiceLevel;

  /// A pre-checkout placeholder is not a delivery estimate at final review.
  bool get hasPlaceholderDeliveryPromise {
    final value = promise.trim().toLowerCase();
    return value.isEmpty || value == 'delivery time confirmed at checkout';
  }

  bool get hasDeliveryEstimate =>
      !hasPlaceholderDeliveryPromise ||
      (promisedByLabel?.trim().isNotEmpty ?? false);

  int get itemCount => lines.fold(0, (total, line) => total + line.quantity);

  int get total => lines.fold(0, (total, line) => total + line.total);
  int get totalMinor => buyV2SumMinor(lines.map((line) => line.totalMinor));

  String get key => groupKey;

  List<String> get productIds =>
      lines.map((line) => line.product.id).toList(growable: false);
}

class BuyV2Address {
  const BuyV2Address({
    required this.id,
    required this.kind,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.line,
    required this.area,
    required this.pinCode,
    required this.landmark,
  });

  final String id;
  final BuyV2AddressKind kind;
  final String label;
  final String recipient;
  final String phone;
  final String line;
  final String area;
  final String pinCode;
  final String landmark;

  String get shortLine => '$area · $pinCode';

  String get compactLine => '${area.split(',').first.trim()} · $pinCode';
}

enum BuyV2TaxInvoiceState { pending, ready, corrected, unavailable }

class BuyV2TaxInvoiceLine {
  const BuyV2TaxInvoiceLine({
    required this.description,
    required this.hsnSac,
    int? taxableValue,
    int? taxableValueMinor,
    required this.gstRate,
    int? cgst,
    int? sgst,
    int? igst,
    int? cess,
    int? cgstMinor,
    int? sgstMinor,
    int? igstMinor,
    int? cessMinor,
    this.quantity,
    this.unit,
    int? unitPrice,
    int? unitPriceMinor,
    // Keep public named arguments compatible while backing the legacy getters.
    // ignore: prefer_initializing_formals
  }) : _taxableValue = taxableValue, _taxableValueMinor = taxableValueMinor,
       // ignore: prefer_initializing_formals
       _cgst = cgst, _sgst = sgst, _igst = igst, _cess = cess,
       // ignore: prefer_initializing_formals
       _cgstMinor = cgstMinor, _sgstMinor = sgstMinor, _igstMinor = igstMinor, _cessMinor = cessMinor,
       // ignore: prefer_initializing_formals
       _unitPrice = unitPrice, _unitPriceMinor = unitPriceMinor;

  final String description;
  final String hsnSac;
  final int? _taxableValue, _taxableValueMinor;
  final double gstRate;
  final int? _cgst, _sgst, _igst, _cess;
  final int? _cgstMinor, _sgstMinor, _igstMinor, _cessMinor;
  final int? quantity;
  final String? unit;
  final int? _unitPrice, _unitPriceMinor;

  bool get usesMinorAmounts => [_taxableValueMinor, _cgstMinor, _sgstMinor, _igstMinor, _cessMinor, _unitPriceMinor]
    .any((amount) => amount != null);
  int get taxableValueMinor => buyV2ExactMinorAmount(minor: _taxableValueMinor, legacyRupees: _taxableValue);
  int get cgstMinor => buyV2ExactMinorAmount(minor: _cgstMinor, legacyRupees: _cgst);
  int get sgstMinor => buyV2ExactMinorAmount(minor: _sgstMinor, legacyRupees: _sgst);
  int get igstMinor => buyV2ExactMinorAmount(minor: _igstMinor, legacyRupees: _igst);
  int get cessMinor => buyV2ExactMinorAmount(minor: _cessMinor, legacyRupees: _cess);
  int? get unitPriceMinor => _unitPrice == null && _unitPriceMinor == null ? null
    : buyV2ExactMinorAmount(minor: _unitPriceMinor, legacyRupees: _unitPrice);
  // Legacy APIs retain rupee semantics; no truncation of a new paise amount.
  int get taxableValue => _taxableValue ?? buyV2WholeRupees(taxableValueMinor);
  int get cgst => _cgst ?? buyV2WholeRupees(cgstMinor);
  int get sgst => _sgst ?? buyV2WholeRupees(sgstMinor);
  int get igst => _igst ?? buyV2WholeRupees(igstMinor);
  int get cess => _cess ?? buyV2WholeRupees(cessMinor);
  int? get unitPrice => _unitPrice ?? (unitPriceMinor == null ? null : buyV2WholeRupees(unitPriceMinor!));
  int get totalTaxMinor => buyV2SumMinor([cgstMinor, sgstMinor, igstMinor, cessMinor]);
  int get totalTax => buyV2WholeRupees(totalTaxMinor);
  bool get hasValidAmounts {
    try {
      taxableValueMinor; unitPriceMinor; totalTaxMinor;
      return gstRate.isFinite;
    } on FormatException { return false; }
  }
}

class BuyV2TaxInvoiceDetails {
  const BuyV2TaxInvoiceDetails({
    required this.invoiceNumber,
    required this.issuedAt,
    required this.sellerLegalName,
    required this.sellerAddress,
    required this.sellerGstin,
    required this.placeOfSupply,
    required this.sourceId,
    required this.lines,
    this.buyerGstin,
    this.revisionLabel,
    this.recipientLegalName,
    this.recipientBillingAddress,
    this.sellerPan,
    this.sellerCin,
    this.sellerFssaiNumber,
    this.reverseCharge = false,
    this.irn,
    this.acknowledgementNumber,
    this.authorizedSignatory,
    this.supplyStatement,
  });

  final String invoiceNumber;
  final DateTime issuedAt;
  final String sellerLegalName;
  final String sellerAddress;
  final String sellerGstin;
  final String? buyerGstin;
  final String placeOfSupply;
  final String sourceId;
  final List<BuyV2TaxInvoiceLine> lines;
  final String? revisionLabel;
  final String? recipientLegalName;
  final String? recipientBillingAddress;
  final String? sellerPan;
  final String? sellerCin;
  final String? sellerFssaiNumber;
  final bool reverseCharge;
  final String? irn;
  final String? acknowledgementNumber;
  final String? authorizedSignatory;
  final String? supplyStatement;

  bool get usesMinorAmounts => lines.any((line) => line.usesMinorAmounts);
  int get totalTaxMinor => buyV2SumMinor(lines.map((line) => line.totalTaxMinor));
  int get totalTax => buyV2WholeRupees(totalTaxMinor);
  bool get hasValidAmounts {
    try { totalTaxMinor; return lines.every((line) => line.hasValidAmounts); }
    on FormatException { return false; }
  }
}

/// A customer-collection reference supplied by the authenticated commerce
/// adapter. It is routing context, never evidence of payment or collection.
class BuyV2CollectionOrderReference {
  const BuyV2CollectionOrderReference({
    required this.storeId,
    required this.purchaserAccountId,
  });

  final String storeId;
  final String purchaserAccountId;
}

enum BuyV2SupplyState {
  awaitingSupply,
  partiallyAvailable,
  replacementOffered,
  ready,
  unavailable,
}

enum BuyV2SupplyRefundState { pending, processing, refunded, failed }

class BuyV2SupplyLine {
  const BuyV2SupplyLine({
    required this.productId,
    required this.variant,
    required this.pack,
    required this.orderedQuantity,
    required this.availableQuantity,
    required this.unavailableQuantity,
    this.supplierId,
    this.supplierName,
  });
  final String productId;
  final String variant;
  final String pack;
  final int orderedQuantity;
  final int availableQuantity;
  final int unavailableQuantity;
  final String? supplierId;
  final String? supplierName;
  int get awaitingQuantity =>
      orderedQuantity - availableQuantity - unavailableQuantity;
}

class BuyV2ReplacementLine {
  const BuyV2ReplacementLine({
    required this.originalProductId,
    required this.originalVariant,
    required this.originalPack,
    required this.originalQuantity,
    required this.productTitle,
    required this.pack,
    required this.quantity,
    required this.unitPriceMinor,
  });
  final String originalProductId;
  final String originalVariant;
  final String originalPack;
  final int originalQuantity;
  final String productTitle;
  final String pack;
  final int quantity;
  final int unitPriceMinor;
}

class BuyV2ReplacementOffer {
  BuyV2ReplacementOffer({
    required this.id,
    required this.revision,
    required List<BuyV2ReplacementLine> lines,
    required this.customerTotalMinor,
    required this.deliveryCommitment,
    required this.expiresAt,
  }) : lines = List.unmodifiable(lines);
  final String id;
  final int revision;
  final List<BuyV2ReplacementLine> lines;
  final int customerTotalMinor;
  final String deliveryCommitment;
  final DateTime expiresAt;
}

/// Optional provider facts. Absence is unknown, never allocation or settlement.
/// This Retail Shop delivery contract does not define wholesale/collection rules.
class BuyV2OrderSupplyProgress {
  BuyV2OrderSupplyProgress({
    required this.orderId,
    required this.purchaseId,
    required this.sourceId,
    required this.revision,
    required this.state,
    required List<BuyV2SupplyLine> lines,
    this.replacementOffer,
    this.refundState,
    this.refundAmountMinor,
    this.refundRoute,
    this.refundReference,
    this.currency = 'INR',
  }) : lines = List.unmodifiable(lines);
  final String orderId;
  final String purchaseId;
  final String sourceId;
  final int revision;
  final BuyV2SupplyState state;
  final List<BuyV2SupplyLine> lines;
  final BuyV2ReplacementOffer? replacementOffer;
  final BuyV2SupplyRefundState? refundState;
  final int? refundAmountMinor;
  final String? refundRoute;
  final String? refundReference;
  final String currency;

  bool matchesOrder(BuyV2Order order) {
    if (!order.hasValidMoney || order.destination != BuyV2Destination.shop ||
        order.collection != null ||
        orderId != order.id ||
        purchaseId.trim().isEmpty ||
        purchaseId != order.purchaseId ||
        sourceId.trim().isEmpty ||
        revision <= 0 ||
        currency != 'INR' ||
        lines.isEmpty ||
        lines.length != order.lines.length) {
      return false;
    }
    final matched = <int>{};
    for (final line in lines) {
      final index = order.lines.indexWhere(
        (original) =>
            original.product.id == line.productId &&
            original.product.variant == line.variant &&
            original.product.pack == line.pack &&
            original.quantity == line.orderedQuantity,
      );
      if (index < 0 ||
          !matched.add(index) ||
          line.orderedQuantity <= 0 ||
          line.availableQuantity < 0 ||
          line.unavailableQuantity < 0 ||
          line.awaitingQuantity < 0 ||
          (line.availableQuantity > 0 &&
              (line.supplierId?.trim().isNotEmpty != true ||
                  line.supplierName?.trim().isNotEmpty != true))) {
        return false;
      }
    }
    final available = lines.fold<int>(
      0,
      (sum, line) => sum + line.availableQuantity,
    );
    final ordered = lines.fold<int>(
      0,
      (sum, line) => sum + line.orderedQuantity,
    );
    if (state == BuyV2SupplyState.ready && available != ordered) return false;
    if (state == BuyV2SupplyState.awaitingSupply &&
        lines.any(
          (line) =>
              line.availableQuantity != 0 || line.unavailableQuantity != 0,
        )) {
      return false;
    }
    if (state == BuyV2SupplyState.partiallyAvailable &&
        (available <= 0 || available >= ordered)) {
      return false;
    }
    if (state == BuyV2SupplyState.unavailable &&
        lines.any((line) => line.unavailableQuantity != line.orderedQuantity)) {
      return false;
    }
    final offer = replacementOffer;
    if ((state == BuyV2SupplyState.replacementOffered) != (offer != null)) {
      return false;
    }
    if (offer != null) {
      if (offer.id.trim().isEmpty ||
          offer.revision <= 0 ||
          offer.lines.isEmpty ||
          offer.deliveryCommitment.trim().isEmpty ||
          offer.customerTotalMinor != order.payableTotalMinor) {
        return false;
      }
      final replaced = <int>{};
      for (final proposed in offer.lines) {
        final index = lines.indexWhere(
          (original) =>
              original.productId == proposed.originalProductId &&
              original.variant == proposed.originalVariant &&
              original.pack == proposed.originalPack,
        );
        if (index < 0 ||
            !replaced.add(index) ||
            proposed.originalQuantity <= 0 ||
            proposed.originalQuantity > lines[index].unavailableQuantity ||
            proposed.productTitle.trim().isEmpty ||
            proposed.pack.trim().isEmpty ||
            proposed.quantity <= 0 ||
            proposed.unitPriceMinor < 0) {
          return false;
        }
      }
    }
    if (refundState != null) {
      final amount = refundAmountMinor;
      if (amount == null ||
          amount <= 0 ||
          amount > order.payableTotalMinor ||
          refundRoute?.trim().isNotEmpty != true) {
        return false;
      }
      if (refundState == BuyV2SupplyRefundState.refunded &&
          (order.amountPaidNowMinor == null ||
              amount > order.amountPaidNowMinor! ||
              refundReference?.trim().isNotEmpty != true)) {
        return false;
      }
    } else if (refundAmountMinor != null ||
        refundRoute != null ||
        refundReference != null) {
      return false;
    }
    return true;
  }
}

class BuyV2ReplacementConsentRequest {
  const BuyV2ReplacementConsentRequest({
    required this.orderId,
    required this.purchaseId,
    required this.sourceId,
    required this.supplyRevision,
    required this.offerId,
    required this.offerRevision,
    required this.reviewKey,
    required this.accept,
    required this.idempotencyKey,
  });
  final String orderId;
  final String purchaseId;
  final String sourceId;
  final int supplyRevision;
  final String offerId;
  final int offerRevision;
  final String reviewKey;
  final bool accept;
  final String idempotencyKey;
}

class BuyV2ReplacementConsentResult {
  const BuyV2ReplacementConsentResult({
    required this.request,
    required this.recorded,
    this.reference,
  });
  final BuyV2ReplacementConsentRequest request;
  final bool recorded;
  final String? reference;
}

class BuyV2Order {
  const BuyV2Order({
    required this.id,
    required this.destination,
    required this.title,
    required this.itemSummary,
    required int total,
    required this.partner,
    required this.partnerType,
    required this.promise,
    required this.destinationLabel,
    required this.progress,
    required this.status,
    this.totalMinor,
    this.collection,
    this.purchaseId,
    this.promisedByLabel,
    this.updatedDeliveryEstimate,
    this.productIds = const [],
    this.lines = const [],
    this.paymentMethod,
    this.purchaseOrderReference,
    this.recipient,
    this.addressLine,
    this.deliveryInstruction,
    int tip = 0,
    int discount = 0,
    this.paymentTermLabel,
    int? amountPaidNow,
    int balanceDue = 0,
    this.balanceDueLabel,
    this.paymentStatusLabel,
    this.buyerName,
    this.buyerType,
    int tax = 0,
    int freight = 0,
    int deliveryFee = 0,
    int paymentCharge = 0,
    this.dispatchPromise,
    this.deliveryPartnerName,
    this.deliveryPartnerType,
    this.trackingReference,
    this.deliveryServiceLevel,
    this.proofOfDeliveryStatus,
    this.taxInvoiceState,
    this.taxInvoiceDetails,
    this.platformTaxInvoiceDetails,
    this.invoiceAvailable = true,
    this.receiptReference,
    this.supplyProgress,
    // Preserve the original required-int constructor and raw legacy values.
    // ignore: prefer_initializing_formals
  }) : _legacyTotal = total, _legacyTip = tip, _legacyDiscount = discount,
       // ignore: prefer_initializing_formals
       _legacyPaidNow = amountPaidNow, _legacyBalance = balanceDue,
       // ignore: prefer_initializing_formals
       _legacyTax = tax, _legacyFreight = freight,
       // ignore: prefer_initializing_formals
       _legacyDeliveryFee = deliveryFee, _legacyPaymentCharge = paymentCharge,
       _minorTip = null, _minorDiscount = null, _minorPaidNow = null, _minorBalance = null,
       _minorTax = null, _minorFreight = null, _minorDeliveryFee = null, _minorPaymentCharge = null;

  const BuyV2Order.minor({
    required this.id,
    required this.destination,
    required this.title,
    required this.itemSummary,
    required int totalMinor,
    required this.partner,
    required this.partnerType,
    required this.promise,
    required this.destinationLabel,
    required this.progress,
    required this.status,
    this.collection,
    this.purchaseId,
    this.promisedByLabel,
    this.updatedDeliveryEstimate,
    this.productIds = const [],
    this.lines = const [],
    this.paymentMethod,
    this.purchaseOrderReference,
    this.recipient,
    this.addressLine,
    this.deliveryInstruction,
    int tipMinor = 0,
    int discountMinor = 0,
    this.paymentTermLabel,
    int? amountPaidNowMinor,
    int balanceDueMinor = 0,
    this.balanceDueLabel,
    this.paymentStatusLabel,
    this.buyerName,
    this.buyerType,
    int taxMinor = 0,
    int freightMinor = 0,
    int deliveryFeeMinor = 0,
    int paymentChargeMinor = 0,
    this.dispatchPromise,
    this.deliveryPartnerName,
    this.deliveryPartnerType,
    this.trackingReference,
    this.deliveryServiceLevel,
    this.proofOfDeliveryStatus,
    this.taxInvoiceState,
    this.taxInvoiceDetails,
    this.platformTaxInvoiceDetails,
    this.invoiceAvailable = true,
    this.receiptReference,
    this.supplyProgress,
    // An exact order never manufactures the old collection compatibility total.
    // ignore: prefer_initializing_formals
  }) : totalMinor = totalMinor, _minorTip = tipMinor, _minorDiscount = discountMinor,
       // ignore: prefer_initializing_formals
       _minorPaidNow = amountPaidNowMinor, _minorBalance = balanceDueMinor,
       // ignore: prefer_initializing_formals
       _minorTax = taxMinor, _minorFreight = freightMinor,
       // ignore: prefer_initializing_formals
       _minorDeliveryFee = deliveryFeeMinor, _minorPaymentCharge = paymentChargeMinor,
       _legacyTotal = null, _legacyTip = null, _legacyDiscount = null, _legacyPaidNow = null,
       _legacyBalance = null, _legacyTax = null, _legacyFreight = null,
       _legacyDeliveryFee = null, _legacyPaymentCharge = null;

  final String id;
  final BuyV2Destination destination;
  final String title;
  final String itemSummary;

  /// Legacy whole-rupee compatibility value. Collection amounts are exact in
  /// totalMinor and validated against the authenticated collection snapshot.
  final int? _legacyTotal, _legacyTip, _legacyDiscount, _legacyPaidNow, _legacyBalance,
      _legacyTax, _legacyFreight, _legacyDeliveryFee, _legacyPaymentCharge,
      _minorTip, _minorDiscount, _minorPaidNow, _minorBalance,
      _minorTax, _minorFreight, _minorDeliveryFee, _minorPaymentCharge;
  final int? totalMinor;
  bool get usesMinorAmounts => _legacyTotal == null;

  /// The historical optional override is intentionally independent of the old
  /// collection floor in total. Do not populate an absent override on migration.
  int get payableTotalMinor => totalMinor != null
      ? buyV2ExactMinorAmount(minor: totalMinor)
      : buyV2ExactMinorAmount(legacyRupees: _legacyTotal);
  int get total => _legacyTotal ?? buyV2WholeRupees(payableTotalMinor);
  int get tipMinor => buyV2ExactMinorAmount(minor: _minorTip, legacyRupees: _legacyTip);
  int get discountMinor => buyV2ExactMinorAmount(minor: _minorDiscount, legacyRupees: _legacyDiscount);
  int? get amountPaidNowMinor => _minorPaidNow == null && _legacyPaidNow == null ? null :
      buyV2ExactMinorAmount(minor: _minorPaidNow, legacyRupees: _legacyPaidNow);
  int get balanceDueMinor => buyV2ExactMinorAmount(minor: _minorBalance, legacyRupees: _legacyBalance);
  int get taxMinor => buyV2ExactMinorAmount(minor: _minorTax, legacyRupees: _legacyTax);
  int get freightMinor => buyV2ExactMinorAmount(minor: _minorFreight, legacyRupees: _legacyFreight);
  int get deliveryFeeMinor => buyV2ExactMinorAmount(minor: _minorDeliveryFee, legacyRupees: _legacyDeliveryFee);
  int get paymentChargeMinor => buyV2ExactMinorAmount(minor: _minorPaymentCharge, legacyRupees: _legacyPaymentCharge);
  int get tip => _legacyTip ?? buyV2WholeRupees(tipMinor);
  int get discount => _legacyDiscount ?? buyV2WholeRupees(discountMinor);
  int? get amountPaidNow => amountPaidNowMinor == null ? null : _legacyPaidNow ?? buyV2WholeRupees(amountPaidNowMinor!);
  int get balanceDue => _legacyBalance ?? buyV2WholeRupees(balanceDueMinor);
  int get tax => _legacyTax ?? buyV2WholeRupees(taxMinor);
  int get freight => _legacyFreight ?? buyV2WholeRupees(freightMinor);
  int get deliveryFee => _legacyDeliveryFee ?? buyV2WholeRupees(deliveryFeeMinor);
  int get paymentCharge => _legacyPaymentCharge ?? buyV2WholeRupees(paymentChargeMinor);
  bool get hasValidMoney {
    try {
      payableTotalMinor; tipMinor; discountMinor; amountPaidNowMinor; balanceDueMinor;
      taxMinor; freightMinor; deliveryFeeMinor; paymentChargeMinor;
      if (_legacyTotal != null) buyV2ExactMinorAmount(legacyRupees: _legacyTotal);
      return true;
    } on FormatException { return false; }
  }
  final String partner;
  final String partnerType;
  final String promise;
  final String destinationLabel;
  final double progress;
  final BuyV2OrderStatus status;
  final BuyV2CollectionOrderReference? collection;
  final String? purchaseId;
  final String? promisedByLabel;
  final String? updatedDeliveryEstimate;
  final List<String> productIds;
  final List<BuyV2CartLine> lines;
  final String? paymentMethod;
  final String? purchaseOrderReference;
  final String? recipient;
  final String? addressLine;
  final String? deliveryInstruction;
  final String? paymentTermLabel;
  final String? balanceDueLabel;
  final String? paymentStatusLabel;
  final String? buyerName;
  final String? buyerType;
  final String? dispatchPromise;
  final String? deliveryPartnerName;
  final String? deliveryPartnerType;
  final String? trackingReference;
  final String? deliveryServiceLevel;
  final String? proofOfDeliveryStatus;
  final BuyV2TaxInvoiceState? taxInvoiceState;
  final BuyV2TaxInvoiceDetails? taxInvoiceDetails;
  final BuyV2TaxInvoiceDetails? platformTaxInvoiceDetails;
  final bool invoiceAvailable;
  final String? receiptReference;
  final BuyV2OrderSupplyProgress? supplyProgress;
}

class _BuyV2CommerceSeed {
  const _BuyV2CommerceSeed({
    required this.id,
    required this.title,
    required this.merchandisingLabel,
    required this.shopCategory,
    required this.wholesaleCategory,
    required this.variant,
    required this.shopPack,
    required this.shopPrice,
    required this.shopUnit,
    required this.shopBadge,
    required this.shopSeller,
    required this.shopSellerType,
    required this.shopDelivery,
    required this.shopReturnPolicy,
    required this.wholesalePack,
    required this.wholesalePrice,
    required this.wholesaleUnit,
    required this.wholesaleBadge,
    required this.wholesaleSeller,
    required this.wholesaleSellerType,
    required this.wholesaleDelivery,
    required this.wholesaleReturnPolicy,
  });

  factory _BuyV2CommerceSeed.fromRow(String row) {
    final values = row.split('|');
    if (values.length != 22) {
      throw FormatException(
        'Buy V2 commerce seed ${values.firstOrNull ?? '<empty>'} '
        'has ${values.length} fields; expected 22.',
      );
    }
    return _BuyV2CommerceSeed(
      id: values[0],
      title: values[1],
      merchandisingLabel: values[2],
      shopCategory: values[3],
      wholesaleCategory: values[4],
      variant: values[5],
      shopPack: values[6],
      shopPrice: int.parse(values[7]),
      shopUnit: values[8],
      shopBadge: values[9],
      shopSeller: values[10],
      shopSellerType: values[11],
      shopDelivery: values[12],
      shopReturnPolicy: values[13],
      wholesalePack: values[14],
      wholesalePrice: int.parse(values[15]),
      wholesaleUnit: values[16],
      wholesaleBadge: values[17],
      wholesaleSeller: values[18],
      wholesaleSellerType: values[19],
      wholesaleDelivery: values[20],
      wholesaleReturnPolicy: values[21],
    );
  }

  final String id;
  final String title;
  final String merchandisingLabel;
  final String shopCategory;
  final String wholesaleCategory;
  final String variant;
  final String shopPack;
  final int shopPrice;
  final String shopUnit;
  final String shopBadge;
  final String shopSeller;
  final String shopSellerType;
  final String shopDelivery;
  final String shopReturnPolicy;
  final String wholesalePack;
  final int wholesalePrice;
  final String wholesaleUnit;
  final String wholesaleBadge;
  final String wholesaleSeller;
  final String wholesaleSellerType;
  final String wholesaleDelivery;
  final String wholesaleReturnPolicy;
}

abstract final class BuyV2Catalogue {
  static const shopCategories = <BuyV2Category>[
    BuyV2Category(id: 'all', label: 'For you', glyph: '✦'),
    BuyV2Category(
      id: 'fruits-vegetables',
      label: 'Fruits & vegetables',
      glyph: '●',
    ),
    BuyV2Category(id: 'dairy-bakery', label: 'Dairy & bakery', glyph: '◒'),
    BuyV2Category(id: 'eggs-poultry', label: 'Eggs & poultry', glyph: '◉'),
    BuyV2Category(id: 'meat-seafood', label: 'Meat & seafood', glyph: '◍'),
    BuyV2Category(
      id: 'flour-rice-grains',
      label: 'Flour, rice & grains',
      glyph: '◇',
    ),
    BuyV2Category(id: 'dals-staples', label: 'Dals & staples', glyph: '◆'),
    BuyV2Category(id: 'oils-ghee', label: 'Oil & ghee', glyph: '◐'),
    BuyV2Category(id: 'ground-spices', label: 'Ground spices', glyph: '✧'),
    BuyV2Category(id: 'whole-spices', label: 'Whole spices', glyph: '✣'),
    BuyV2Category(
      id: 'breakfast-cereals',
      label: 'Breakfast & cereals',
      glyph: '☀',
    ),
    BuyV2Category(id: 'instant-foods', label: 'Instant foods', glyph: '▣'),
    BuyV2Category(id: 'sauces-spreads', label: 'Sauces & spreads', glyph: '◈'),
    BuyV2Category(
      id: 'biscuits-chocolate',
      label: 'Biscuits & chocolate',
      glyph: '○',
    ),
    BuyV2Category(id: 'namkeen-chips', label: 'Namkeen & chips', glyph: '◌'),
    BuyV2Category(id: 'tea-coffee', label: 'Tea & coffee', glyph: '◫'),
    BuyV2Category(id: 'juices-water', label: 'Juices & water', glyph: '◧'),
    BuyV2Category(id: 'frozen-foods', label: 'Frozen foods', glyph: '❄'),
    BuyV2Category(
      id: 'icecream-cheese',
      label: 'Ice cream & cheese',
      glyph: '◓',
    ),
    BuyV2Category(id: 'bath-hand-care', label: 'Bath & hand care', glyph: '✚'),
    BuyV2Category(id: 'oral-care', label: 'Oral care', glyph: '⌁'),
    BuyV2Category(id: 'hair-care', label: 'Hair care', glyph: '♢'),
    BuyV2Category(id: 'skin-care', label: 'Skin care', glyph: '◊'),
    BuyV2Category(
      id: 'surface-cleaners',
      label: 'Surface cleaners',
      glyph: '⌂',
    ),
    BuyV2Category(id: 'air-waste-care', label: 'Air & waste care', glyph: '◎'),
    BuyV2Category(
      id: 'laundry-dishwash',
      label: 'Laundry & dishwash',
      glyph: '≋',
    ),
    BuyV2Category(id: 'diapers-wipes', label: 'Diapers & wipes', glyph: '◉'),
    BuyV2Category(id: 'baby-care', label: 'Baby care', glyph: '◎'),
    BuyV2Category(
      id: 'health-wellness',
      label: 'Health & wellness',
      glyph: '＋',
    ),
    BuyV2Category(id: 'dog-care', label: 'Dog care', glyph: '♡'),
    BuyV2Category(id: 'cat-care', label: 'Cat care', glyph: '♧'),
    BuyV2Category(
      id: 'food-storage-packs',
      label: 'Food storage & packs',
      glyph: '▤',
    ),
    BuyV2Category(id: 'cups-tissues', label: 'Cups & tissues', glyph: '◒'),
    BuyV2Category(id: 'school-office', label: 'School & office', glyph: '□'),
    BuyV2Category(id: 'shop-supplies', label: 'Shop supplies', glyph: '▦'),
  ];

  static const wholesaleCategories = <BuyV2Category>[
    BuyV2Category(id: 'all', label: 'Best prices', glyph: '✦'),
    BuyV2Category(id: 'retail-supplies', label: 'Retail supplies', glyph: '▦'),
    BuyV2Category(
      id: 'horeca-food-packs',
      label: 'HoReCa food packs',
      glyph: '▤',
    ),
    BuyV2Category(
      id: 'horeca-tableware',
      label: 'HoReCa tableware',
      glyph: '◒',
    ),
    BuyV2Category(
      id: 'stationery-office',
      label: 'Stationery & office',
      glyph: '□',
    ),
    BuyV2Category(
      id: 'fruits-vegetables',
      label: 'Fruits & vegetables',
      glyph: '●',
    ),
    BuyV2Category(id: 'dairy-bakery', label: 'Dairy & bakery', glyph: '◒'),
    BuyV2Category(id: 'eggs-poultry', label: 'Eggs & poultry', glyph: '◉'),
    BuyV2Category(id: 'meat-seafood', label: 'Meat & seafood', glyph: '◍'),
    BuyV2Category(
      id: 'flour-rice-grains',
      label: 'Flour, rice & grains',
      glyph: '◇',
    ),
    BuyV2Category(id: 'dals-staples', label: 'Dals & staples', glyph: '◆'),
    BuyV2Category(id: 'oils-ghee', label: 'Oils & ghee', glyph: '◐'),
    BuyV2Category(id: 'ground-spices', label: 'Ground spices', glyph: '✧'),
    BuyV2Category(id: 'whole-spices', label: 'Whole spices', glyph: '✣'),
    BuyV2Category(
      id: 'breakfast-cereals',
      label: 'Breakfast & cereals',
      glyph: '☀',
    ),
    BuyV2Category(id: 'instant-foods', label: 'Instant foods', glyph: '▣'),
    BuyV2Category(id: 'sauces-spreads', label: 'Sauces & spreads', glyph: '◈'),
    BuyV2Category(
      id: 'biscuits-chocolate',
      label: 'Biscuits & chocolate',
      glyph: '○',
    ),
    BuyV2Category(id: 'namkeen-chips', label: 'Namkeen & chips', glyph: '◌'),
    BuyV2Category(id: 'tea-coffee', label: 'Tea & coffee', glyph: '◫'),
    BuyV2Category(id: 'juices-water', label: 'Juices & water', glyph: '◧'),
    BuyV2Category(id: 'frozen-foods', label: 'Frozen foods', glyph: '❄'),
    BuyV2Category(
      id: 'icecream-cheese',
      label: 'Ice cream & cheese',
      glyph: '◓',
    ),
    BuyV2Category(id: 'bath-hand-care', label: 'Bath & hand care', glyph: '✚'),
    BuyV2Category(id: 'oral-care', label: 'Oral care', glyph: '⌁'),
    BuyV2Category(id: 'hair-care', label: 'Hair care', glyph: '♢'),
    BuyV2Category(id: 'skin-care', label: 'Skin care', glyph: '◊'),
    BuyV2Category(
      id: 'surface-cleaners',
      label: 'Surface cleaners',
      glyph: '⌂',
    ),
    BuyV2Category(id: 'air-waste-care', label: 'Air & waste care', glyph: '◎'),
    BuyV2Category(
      id: 'laundry-dishwash',
      label: 'Laundry & dishwash',
      glyph: '≋',
    ),
    BuyV2Category(id: 'diapers-wipes', label: 'Diapers & wipes', glyph: '◉'),
    BuyV2Category(id: 'baby-care', label: 'Baby care', glyph: '◎'),
    BuyV2Category(
      id: 'health-wellness',
      label: 'Health & wellness',
      glyph: '＋',
    ),
    BuyV2Category(id: 'dog-care', label: 'Dog care', glyph: '♡'),
    BuyV2Category(id: 'cat-care', label: 'Cat care', glyph: '♧'),
  ];

  static const medicineCategories = <BuyV2Category>[
    BuyV2Category(id: 'all', label: 'All', glyph: '☷'),
    BuyV2Category(id: 'rx', label: 'Prescription', glyph: 'Rx'),
    BuyV2Category(id: 'pain-fever', label: 'Pain & fever', glyph: '＋'),
    BuyV2Category(id: 'diabetes', label: 'Diabetes', glyph: '◒'),
    BuyV2Category(id: 'heart-bp', label: 'Heart & BP', glyph: '♥'),
    BuyV2Category(id: 'digestive', label: 'Digestive', glyph: '◇'),
    BuyV2Category(id: 'respiratory', label: 'Respiratory', glyph: '≈'),
    BuyV2Category(id: 'allergy', label: 'Allergy', glyph: '✦'),
    BuyV2Category(id: 'vitamins', label: 'Vitamins', glyph: 'V'),
    BuyV2Category(id: 'first-aid', label: 'First aid', glyph: '✚'),
    BuyV2Category(id: 'devices', label: 'Devices', glyph: '▣'),
    BuyV2Category(id: 'women-care', label: 'Women care', glyph: '○'),
    BuyV2Category(id: 'baby-care', label: 'Baby care', glyph: '◎'),
    BuyV2Category(id: 'skin-care', label: 'Skin care', glyph: '◐'),
  ];

  static final _commerceSeeds = buyV2CommerceSeedRows
      .trim()
      .split('\n')
      .map((row) => _BuyV2CommerceSeed.fromRow(row.trim()))
      .toList(growable: false);

  static final _commerceVariantProducts = <BuyV2Product>[
    _commerceVariant(
      canonicalId: 'milk',
      destination: BuyV2Destination.shop,
      id: 's-milk-500ml',
      variant: 'Toned fresh milk · 500 ml',
      pack: '500 ml pouch',
      price: 35,
      unitPrice: '₹70/L',
      badge: '500 ml pack',
    ),
    _commerceVariant(
      canonicalId: 'milk',
      destination: BuyV2Destination.shop,
      id: 's-milk-2l',
      variant: 'Toned fresh milk · family pack',
      pack: '2 × 1 L pouches',
      price: 128,
      unitPrice: '₹64/L',
      badge: 'Family pack',
    ),
    _commerceVariant(
      canonicalId: 'rice',
      destination: BuyV2Destination.wholesale,
      id: 'w-rice-50kg',
      variant: 'Aged basmati · 50 kg trade sack',
      pack: '50 kg sack',
      price: 3200,
      unitPrice: '₹64/kg',
      badge: 'Volume price',
      minimumOrder: 1,
    ),
    _commerceVariant(
      canonicalId: 'oil',
      destination: BuyV2Destination.wholesale,
      id: 'w-oil-10l',
      variant: 'Refined sunflower · 10 L trade pack',
      pack: '2 × 5 L cans',
      price: 1580,
      unitPrice: '₹158/L',
      badge: 'Flexible bulk pack',
      minimumOrder: 1,
    ),
  ];

  static final products = <BuyV2Product>[
    for (final seed in _commerceSeeds)
      _commerceProduct(seed, BuyV2Destination.shop),
    for (final seed in _commerceSeeds)
      _commerceProduct(seed, BuyV2Destination.wholesale),
    ..._medicineProducts,
  ];

  static final allProducts = <BuyV2Product>[
    ...products,
    ..._commerceVariantProducts,
  ];

  static BuyV2Product _commerceVariant({
    required String canonicalId,
    required BuyV2Destination destination,
    required String id,
    required String variant,
    required String pack,
    required int price,
    required String unitPrice,
    required String badge,
    int? minimumOrder,
  }) {
    final seed = _commerceSeeds.firstWhere((item) => item.id == canonicalId);
    return _commerceProduct(seed, destination).copyWith(
      id: id,
      canonicalId: canonicalId,
      variant: variant,
      pack: pack,
      price: price,
      unitPrice: unitPrice,
      badge: badge,
      minimumOrder: minimumOrder,
      catalogueListing: false,
    );
  }

  static BuyV2Product _commerceProduct(
    _BuyV2CommerceSeed seed,
    BuyV2Destination destination,
  ) {
    final wholesale = destination == BuyV2Destination.wholesale;
    final seller = wholesale ? seed.wholesaleSeller : seed.shopSeller;
    final sellerType = wholesale
        ? seed.wholesaleSellerType
        : seed.shopSellerType;
    final originCity = _supplierOrigin(seller, sellerType);
    return BuyV2Product(
      id: '${wholesale ? 'w' : 's'}-${seed.id}',
      canonicalId: seed.id,
      destination: destination,
      categoryId: wholesale ? seed.wholesaleCategory : seed.shopCategory,
      // The review source's third column contains merchandising groups,
      // not substantiated brand identities. Do not invent a brand for it.
      brand: '',
      merchandisingLabel: seed.merchandisingLabel,
      title: seed.title,
      variant: _catalogueVariant(seed),
      pack: wholesale ? seed.wholesalePack : seed.shopPack,
      price: wholesale ? seed.wholesalePrice : seed.shopPrice,
      unitPrice: wholesale ? seed.wholesaleUnit : seed.shopUnit,
      badge: wholesale ? seed.wholesaleBadge : seed.shopBadge,
      seller: seller,
      sellerType: sellerType,
      deliveryPromise: wholesale
          ? _wholesalePromise(seed.wholesaleDelivery)
          : _shopPromise(seed.shopDelivery),
      origin: wholesale
          ? '$originCity → Jodhpur 342003'
          : 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Catalogue details verified',
      visualLabel: _visualLabel(seed.id.replaceAll('-', ' ')),
      visualKind: _visualKind(
        wholesale ? seed.wholesaleCategory : seed.shopCategory,
      ),
      reviewDeliveryOptions: wholesale
          ? const {BuyV2DeliveryOption.freight}
          : _reviewQuickProducts.contains(seed.id)
          ? const {BuyV2DeliveryOption.quick}
          : const {BuyV2DeliveryOption.scheduled, BuyV2DeliveryOption.courier},
      // Existing review fixtures only; Store/provider projections must supply
      // their own explicit classification. Quantity never grants a channel.
      offerClass: !wholesale
          ? BuyV2OfferClass.retail
          : seed.id == 'rice'
          ? BuyV2OfferClass.bulk
          : BuyV2OfferClass.wholesale,
      minimumOrder: wholesale ? _minimumOrder(seed.id) : 1,
      returnPolicy: _returnPolicy(seed, wholesale: wholesale),
      freightIncluded: wholesale,
      manufacturerVerified:
          wholesale && sellerType.toLowerCase().contains('manufacturer'),
    );
  }

  static String _shopPromise(String source) {
    final value = source.trim();
    final minutes = RegExp(
      r'(\d+)\s+minutes',
      caseSensitive: false,
    ).firstMatch(value);
    if (minutes != null) {
      return 'Delivery in ${minutes.group(1)} min';
    }
    if (RegExp(
      r'^(today|tomorrow)\s+by\s+',
      caseSensitive: false,
    ).hasMatch(value)) {
      // Seed rows have no observation date or order cutoff. A wall-clock label
      // cannot be reused as today's promise, including after midnight.
      return 'Delivery time confirmed at checkout';
    }
    return value;
  }

  static String _wholesalePromise(String source) {
    final value = source.trim();
    if (RegExp(
      r'^(today|tomorrow)\s+by\s+',
      caseSensitive: false,
    ).hasMatch(value)) {
      return 'Delivery time confirmed at checkout';
    }
    return value;
  }

  static String _returnPolicy(
    _BuyV2CommerceSeed seed, {
    required bool wholesale,
  }) {
    if (wholesale) return seed.wholesaleReturnPolicy.trim();
    final policy = seed.shopReturnPolicy.trim();
    if (policy != 'Eligibility and return window shown before payment') {
      return policy;
    }
    const perishableCategories = {
      'fruits-vegetables',
      'dairy-bakery',
      'eggs-poultry',
      'meat-seafood',
      'frozen-foods',
      'icecream-cheese',
    };
    return perishableCategories.contains(seed.shopCategory)
        ? 'Refund or replacement within 24 hours for spoiled, damaged or incorrect unopened packs'
        : 'Replacement within 7 days for damaged, defective or incorrect unopened packs';
  }

  static String _supplierOrigin(String seller, String sellerType) {
    final name = seller.toLowerCase();
    final type = sellerType.toLowerCase();
    if (const [
      'jodhpur',
      'sardarpura',
      'shree balaji',
      'ghar bazaar',
      'marwar',
      'thar',
      'family stationery',
      'school bazaar',
      'rajasthan mart',
    ].any(name.contains)) {
      return 'Jodhpur';
    }
    if (const [
          'surya oils',
          'care products',
          'herbal brands',
          'india',
          'national',
        ].any(name.contains) ||
        (type.contains('manufacturer') &&
            !name.contains('rajasthan') &&
            !name.contains('aravali'))) {
      return 'Delhi';
    }
    if (const ['rajasthan', 'aravali', 'kisan', 'jaipur'].any(name.contains)) {
      return 'Jaipur';
    }
    return 'Jodhpur';
  }

  // Explicit legacy screenbook scenarios. No runtime display-text inference.
  // These do not grant production eligibility or assert fleet/slot availability.
  static const _reviewQuickProducts = {
    'tomato',
    'rice',
    'soap',
    'onion',
    'bread',
    'chicken',
    'turmeric',
    'poha',
    'noodles',
    'biscuits',
    'tea',
    'peas',
    'toothpaste',
    'face-wash',
    'toilet-cleaner',
    'dishwash',
    'baby-wipes',
    'protein',
    'cat-food',
    'paper-cups',
    'price-labels',
    'banana',
    'curd',
    'fish-fillet',
    'toor-dal',
    'mustard-oil',
    'red-chilli',
    'corn-flakes',
    'ketchup',
    'potato-chips',
    'coffee',
    'frozen-fries',
    'toothbrush',
    'moisturizer',
    'garbage-bags',
    'fabric-conditioner',
    'baby-lotion',
    'glucose',
    'dog-treats',
    'tissues',
    'barcode-labels',
    'printer-paper',
  };

  static int _minimumOrder(String canonicalId) => switch (canonicalId) {
    'rice' => 4,
    'notebook' => 1,
    _ => 2,
  };

  static String _catalogueVariant(_BuyV2CommerceSeed seed) {
    const explicitVariants = {
      'tomato',
      'atta',
      'oil',
      'rice',
      'soap',
      'notebook',
      'banana',
      'potato',
      'curd',
      'paneer',
      'fish-fillet',
      'mutton',
      'toor-dal',
      'mustard-oil',
      'groundnut-oil',
      'red-chilli',
      'coriander-seeds',
      'thermal-rolls',
      'barcode-labels',
      'carry-bags',
      'printer-paper',
      'ball-pens',
    };
    if (explicitVariants.contains(seed.id)) return seed.variant;
    final separator = seed.variant.indexOf(' · ');
    if (separator < 0) return seed.variant;
    final descriptor = seed.variant.substring(0, separator);
    final titleCase = descriptor
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
    return '$titleCase${seed.variant.substring(separator)}';
  }

  static String _visualLabel(String value) {
    final words = value.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.length == 1) {
      final end = words.first.length < 6 ? words.first.length : 6;
      return words.first.substring(0, end).toUpperCase();
    }
    return words.take(2).map((word) => word[0]).join().toUpperCase();
  }

  static String _visualKind(String category) {
    if (category.contains('fruit') || category.contains('vegetable')) {
      return 'produce';
    }
    if (category.contains('dairy') || category.contains('icecream')) {
      return 'bottle';
    }
    if (category.contains('oil') || category.contains('ghee')) return 'bottle';
    if (category.contains('paper') ||
        category.contains('stationery') ||
        category.contains('school')) {
      return 'paper';
    }
    return 'pack';
  }

  static const _medicineProducts = <BuyV2Product>[
    BuyV2Product(
      id: 'm-paracetamol-500',
      destination: BuyV2Destination.medicine,
      categoryId: 'pain-fever',
      brand: 'PAIN & FEVER · RELIEF 500',
      title: 'Paracetamol 500 mg tablets',
      variant: 'Paracetamol 500 mg',
      pack: 'Strip of 15 tablets',
      price: 28,
      mrp: 34,
      unitPrice: '₹1.87/tablet',
      badge: '18% off',
      seller: 'Sardarpura Health Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Delivery time confirmed at checkout',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Expiry and batch shown before dispatch',
      visualLabel: '500',
      visualKind: 'medicine-box',
      composition: 'Paracetamol 500 mg',
      regulatoryNote: 'Use only as directed on the pack or by a clinician.',
      manufacturerVerified: true,
    ),
    BuyV2Product(
      id: 'm-pain-relief-gel',
      destination: BuyV2Destination.medicine,
      categoryId: 'pain-fever',
      brand: 'PAIN & FEVER · FLEXIRELIEF',
      title: 'Pain relief gel',
      variant: 'Diclofenac gel 1% w/w',
      pack: '30 g tube',
      price: 99,
      mrp: 118,
      unitPrice: '₹3.30/g',
      badge: '16% off',
      seller: 'Jodhpur Care Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Delivery time confirmed at checkout',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Sealed tube',
      visualLabel: 'GEL',
      visualKind: 'tube',
      composition: 'Diclofenac gel 1% w/w',
      regulatoryNote: 'For external use only.',
    ),
    BuyV2Product(
      id: 'm-metformin-500',
      destination: BuyV2Destination.medicine,
      categoryId: 'diabetes',
      brand: 'DIABETES · GLYCO SR',
      title: 'Metformin SR 500 mg',
      variant: 'Metformin 500 mg sustained release',
      pack: 'Strip of 10 tablets',
      price: 29,
      mrp: 36,
      unitPrice: '₹2.90/tablet',
      badge: 'Prescription required',
      seller: 'Sardarpura Health Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Delivery time confirmed after prescription review',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Pharmacist review required',
      visualLabel: 'SR 500',
      visualKind: 'medicine-box',
      requiresPrescription: true,
      composition: 'Metformin 500 mg sustained release',
      regulatoryNote: 'Dispensed only against a valid prescription.',
    ),
    BuyV2Product(
      id: 'm-glucose-strips',
      destination: BuyV2Destination.medicine,
      categoryId: 'devices',
      brand: 'DIABETES · GLUCOCHECK',
      title: 'Blood glucose test strips',
      variant: 'Compatible capillary glucose strips',
      pack: 'Vial of 50 strips',
      price: 599,
      mrp: 690,
      unitPrice: '₹11.98/strip',
      badge: '13% off',
      seller: 'Marwar Wellness Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Delivery time confirmed at checkout',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Check meter compatibility',
      visualLabel: '50',
      visualKind: 'bottle',
      composition: 'Capillary blood glucose test strips',
      regulatoryNote: 'Match the meter model before purchase.',
      manufacturerVerified: true,
    ),
    BuyV2Product(
      id: 'm-telmisartan-40',
      destination: BuyV2Destination.medicine,
      categoryId: 'heart-bp',
      brand: 'HEART & BP · TELMICARE 40',
      title: 'Telmisartan 40 mg tablets',
      variant: 'Telmisartan 40 mg',
      pack: 'Strip of 10 tablets',
      price: 86,
      mrp: 112,
      unitPrice: '₹8.60/tablet',
      badge: 'Prescription required',
      seller: 'Sardarpura Health Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Delivery time confirmed after prescription review',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Pharmacist review required',
      visualLabel: '40',
      visualKind: 'medicine-box',
      requiresPrescription: true,
      composition: 'Telmisartan 40 mg',
      regulatoryNote: 'Dispensed only against a valid prescription.',
    ),
    BuyV2Product(
      id: 'm-atorvastatin-10',
      destination: BuyV2Destination.medicine,
      categoryId: 'heart-bp',
      brand: 'HEART & BP · LIPICARE 10',
      title: 'Atorvastatin 10 mg tablets',
      variant: 'Atorvastatin 10 mg',
      pack: 'Strip of 10 tablets',
      price: 54,
      mrp: 74,
      unitPrice: '₹5.40/tablet',
      badge: 'Prescription required',
      seller: 'Marwar Wellness Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Delivery time confirmed after prescription review',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Pharmacist review required',
      visualLabel: '10',
      visualKind: 'medicine-box',
      requiresPrescription: true,
      composition: 'Atorvastatin 10 mg',
      regulatoryNote: 'Dispensed only against a valid prescription.',
    ),
    BuyV2Product(
      id: 'm-pantoprazole-40',
      destination: BuyV2Destination.medicine,
      categoryId: 'digestive',
      brand: 'DIGESTIVE · PANTOCARE 40',
      title: 'Pantoprazole 40 mg tablets',
      variant: 'Pantoprazole 40 mg',
      pack: 'Strip of 15 tablets',
      price: 69,
      mrp: 88,
      unitPrice: '₹4.60/tablet',
      badge: 'Prescription required',
      seller: 'Sardarpura Health Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Delivery time confirmed at checkout',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Pharmacist review required',
      visualLabel: '40',
      visualKind: 'medicine-box',
      requiresPrescription: true,
      composition: 'Pantoprazole 40 mg',
      regulatoryNote: 'Dispensed only against a valid prescription.',
    ),
    BuyV2Product(
      id: 'm-ors',
      destination: BuyV2Destination.medicine,
      categoryId: 'digestive',
      brand: 'DIGESTIVE · HYDRAORS',
      title: 'ORS hydration salts',
      variant: 'Oral rehydration salts',
      pack: 'Pack of 5 sachets',
      price: 24,
      mrp: 30,
      unitPrice: '₹4.80/sachet',
      badge: '20% off',
      seller: 'Sardarpura Health Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Delivery time confirmed after prescription review',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Sealed single-use sachets',
      visualLabel: 'ORS',
      visualKind: 'tube',
      composition: 'Oral rehydration salts',
      regulatoryNote: 'Prepare with the stated amount of clean water.',
      manufacturerVerified: true,
    ),
  ];
}

extension BuyV2DestinationCopy on BuyV2Destination {
  String get label => switch (this) {
    BuyV2Destination.shop => 'Shop',
    BuyV2Destination.wholesale => 'Wholesale',
    BuyV2Destination.medicine => 'Medicine',
    BuyV2Destination.orders => 'Orders',
  };
}

extension BuyV2CartScopeCopy on BuyV2CartScope {
  String get label => switch (this) {
    BuyV2CartScope.all => '₹ Total',
    BuyV2CartScope.shop => 'Shop',
    BuyV2CartScope.wholesale => 'Wholesale',
    BuyV2CartScope.medicine => 'Medicine',
  };
}
