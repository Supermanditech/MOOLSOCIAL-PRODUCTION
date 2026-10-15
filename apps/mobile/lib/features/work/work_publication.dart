import 'dart:convert';
import '../buy/buy_v2_models.dart';
import '../buy/buy_v2_content_contracts.dart';
import 'work_models.dart';

/// Exact Store/SKU content boundary reused by the already guarded public route.
/// No matching-by-name or generic catalogue copy fallback.
class WorkspacePublicContentAdapter implements BuyV2ProductContentAdapter {
  const WorkspacePublicContentAdapter({
    required this.storeId,
    required this.item,
    required this.sourceId,
    this.policyReadback,
    this.policyReadbackRequired = false,
    this.now,
  });
  final String storeId, sourceId;
  final WorkspaceCatalogueItem item;
  /// Optional authoritative policy readback, not a local policy publisher.
  /// Without it, policy/acceptance remain unknown as for legacy callers.
  final BuyV2ProductContentAdapter? policyReadback;
  /// Set by the publication consumer when policy resolution is required.
  /// This requests a source hold; it never asserts that a buyer has consented.
  final bool policyReadbackRequired;
  final DateTime Function()? now;
  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) {
    if (storeId.trim().isEmpty ||
        sourceId.trim().isEmpty ||
        product.storeId != storeId ||
        product.id != item.id ||
        product.canonicalId != item.canonicalId ||
        product.pack != item.pack ||
        product.variant != item.variant ||
        product.brand != item.brand ||
        product.title != item.title ||
        product.categoryId != item.categoryId) {
      return BuyV2ProductContentSnapshot(
        productId: product.id,
        state: BuyV2ProductContentState.unavailable,
        sourceId: sourceId,
      );
    }
    try {
      final local = item.toBuyPublicContent(storeId: storeId, sourceId: sourceId);
      final readback = policyReadback;
      BuyV2ProductContentSnapshot held() => BuyV2ProductContentSnapshot(
        productId: product.id,
        state: BuyV2ProductContentState.unavailable,
        sourceId: sourceId,
        supplierPolicyAcceptanceRequired: true,
        customerMessage: 'Store policy could not be confirmed. Refresh this product.',
      );
      if (readback == null) return policyReadbackRequired ? held() : local;
      try {
        final supplied = readback.snapshotFor(product);
        final current = (now ?? DateTime.now)();
        final policy = supplied.supplierPolicy;
        final decision = supplied.supplierPolicyAcceptanceRequired;
        if (supplied.productId != product.id ||
            supplied.sourceId.trim().isEmpty ||
            supplied.state != BuyV2ProductContentState.ready ||
            supplied.observedAt?.isAfter(current) == true ||
            (policy == null && decision != false) ||
            (policy != null && (!policy.appliesTo(product, current) ||
                decision != null && decision != policy.requiresAcceptance))) {
          return held();
        }
        return BuyV2ProductContentSnapshot(
          productId: local.productId,
          state: local.state,
          // Policy carries its own ID/revision/validity. Do not relabel local
          // product copy/media as provider-observed content.
          sourceId: local.sourceId,
          observedAt: local.observedAt,
          media: local.media,
          description: local.description,
          highlights: local.highlights,
          specifications: local.specifications,
          supplierPolicy: policy,
          supplierPolicyAcceptanceRequired: policy?.requiresAcceptance ?? decision,
        );
      } catch (_) {
        // A failed supplied source is a hold, never a permissive local fallback.
        return held();
      }
    } on FormatException {
      return BuyV2ProductContentSnapshot(
        productId: product.id,
        state: BuyV2ProductContentState.unavailable,
        sourceId: sourceId,
      );
    }
  }
}

/// A customer-field audit, not a publication acknowledgement. Internal costs,
/// bank details and buyer inputs are intentionally not product publication data.
class WorkspacePublicationIssue {
  const WorkspacePublicationIssue(this.field, this.location, this.message);
  final String field, location, message;
}

class WorkspacePublicationReport {
  WorkspacePublicationReport(Iterable<WorkspacePublicationIssue> issues)
    : issues = List.unmodifiable(issues);
  final List<WorkspacePublicationIssue> issues;
  bool get ready => issues.isEmpty;
}

abstract final class WorkspacePublicationContract {
  static String? protectionValues(BuyV2PurchaseProtection? p) => p == null
      ? null
      : jsonEncode({
          'summary': p.summary,
          'remedies': p.remedies,
          'windowLabel': p.windowLabel,
          'conditionsLabel': p.conditionsLabel,
          'verificationLabel': p.verificationLabel,
          'initiationLabel': p.initiationLabel,
          'approvalLabel': p.approvalLabel,
          'pickupLabel': p.pickupLabel,
          'refundMethodLabel': p.refundMethodLabel,
          'refundTimelineLabel': p.refundTimelineLabel,
          'warrantyLabel': p.warrantyLabel,
          'nonReturnableReason': p.nonReturnableReason,
          'policyVersion': p.policyVersion,
          'effectiveFromLabel': p.effectiveFromLabel,
        });
  static const fieldLabels = <String, String>{
    'title': 'product name',
    'brand': 'brand',
    'pack': 'pack',
    'categoryId': 'category',
    'unitPrice': 'price per unit',
    'deliveryPromise': 'delivery information',
    'origin': 'product origin',
  };
  // Every stored public product property has an explicit source/disposition.
  // A source-coverage test fails when Buy adds a property without reconciling it.
  static const productBindings = <String, String>{
    'id': 'Store SKU identity',
    'canonicalId': 'Exact catalogue family identity',
    'storeId': 'Store branch identity',
    'destination':
        'Explicit Shop or Wholesale channel; never inferred from price',
    'categoryId': 'Product category',
    'brand': 'Product brand',
    'merchandisingLabel': 'Marketplace owned; not retailer input',
    'procurementSupplierGrant': 'Verified supplier grant; Wholesale pending',
    'mediaAssets': 'Approved exact pack photo binding',
    'title': 'Product title',
    'variant': 'Exact variant, empty only when not applicable',
    'variantAttributes':
        'Structured variant dimensions require a verified source; legacy variant text is not converted',
    'pack': 'Exact selling pack',
    'packTerms':
        'Supplied publication pack/pricing contract must match saved quantities/tiers; missing required terms block projection',
    'price':
        'Channel selling price in whole rupees; comparison uses minor units',
    'unitPrice':
        'Derived from structured pack quantity; legacy label is draft-only',
    'badge': 'Marketplace presentation, not retailer verification',
    'seller': 'Store display name',
    'sellerType': 'One-time Store business type; not manufacturer verification',
    'deliveryPromise': 'Product terms; authoritative fulfilment pending',
    'origin': 'Product origin; never the Store address',
    'confirmedOn': 'Source timestamp/acknowledgement pending',
    'visualLabel': 'Product image accessibility label',
    'visualKind': 'Catalogue media renderer type',
    'mrp': 'Applicable pack MRP',
    'requiresPrescription': 'Catalogue product classification',
    'composition': 'Applicable product composition',
    'regulatoryNote': 'Applicable product note; not an approval',
    'minimumOrder': 'Product/channel minimum packs',
    'offerClass':
        'Selected retail channel or explicit saved wholesale/bulk sale type; not eligibility or fleet permission',
    'reviewDeliveryOptions':
        'Device-review choices only; never public provider eligibility',
    'returnPolicy':
        'Per-product override or inherited one-time Store return summary',
    'purchaseProtection':
        'Inherited Store remedy/window/conditions; service confirmation and workflow fields stay absent',
    'compliance': 'Applicable catalogue/pack/batch facts',
    'freightIncluded': 'Wholesale quote source pending; never inferred',
    'manufacturerVerified': 'Authoritative verification, not retailer input',
    'catalogueListing': 'Requested listing; not publication acknowledgement',
  };

  static const storeBindings = <String, String>{
    'id': 'WorkWorkspace.id',
    'name': 'WorkWorkspace.name',
    'area': 'WorkWorkspace.area',
    'address': 'One-time Store publication details; inline Settings capture',
    'regionId':
        'Resolved shoppingArea.regionId; location-source wiring pending',
    'distanceMeters': 'Buyer location/service calculation, not Store input',
    'collection': 'Authoritative collection capability pending',
    'previewProduct': 'Same Store exact eligible SKU; no preview screen',
    'publicContactPhone':
        'Explicit customer-facing Store contact; never account/KYC contact',
    'openingHoursLabel':
        'Explicitly saved Store hours; not current open/orderability status',
  };

  static const contentBindings = <String, String>{
    'productId':
        'Exact Store SKU identity; adapter checks Store, canonical ID, variant and pack',
    'state': 'Content projection state; not publication or orderability',
    'sourceId':
        'Caller source reference; authoritative revision from backend remains pending',
    'media': 'Same approved exact-pack media as public product projection',
    'highlights': 'Catalogue prefill or shared editor/CSV content.highlights',
    'highlightFields':
        'Typed highlight attributes pending; legacy highlights remain separate',
    'specifications':
        'Catalogue prefill or shared editor/CSV content.specifications',
    'categoryFacts': 'Verified typed category facts pending; no inferred IDs',
    'description': 'Catalogue prefill or shared editor/CSV content.description',
    'customerMessage': 'Unavailable/error state; no retailer entry',
    'observedAt': 'Authoritative source timestamp; not invented on local save',
    'sizeChart': 'Verified source-specific size chart pending',
    'priceHistory':
        'Authoritative price history pending; local edits are not history',
    'supplierPolicy': 'Optional exact-Store/product policy readback; live source pending',
    'supplierPolicyAcceptanceRequired':
        'Unknown until supplied by the authoritative policy owner; null is not consent',
    'retryable':
        'False for this local snapshot adapter; not a backend success state',
  };

  /// Fields supplied by the shared product record. Comparison is two-way:
  /// losing a field or introducing an unaccounted public property is a failure.
  static Map<String, Object?> sourceProductValues(
    WorkspaceCatalogueItem p, {
    required String storeId,
    required String storeName,
    BuyV2Destination channel = BuyV2Destination.shop,
    WorkspaceStorePublicationDetails? storeDetails,
  }) => {
    'id': p.id,
    'canonicalId': p.canonicalId,
    'storeId': storeId,
    'destination': channel,
    'categoryId': p.categoryId,
    'brand': p.brand,
    'title': p.title,
    'variant': p.variant,
    'pack': p.pack,
    'price': channel == BuyV2Destination.wholesale
        ? p.wholesaleOffer?.priceRupees
        : p.sellingPrice,
    'unitPrice':
        p.packMeasure?.valid == true &&
            (channel == BuyV2Destination.wholesale
                    ? p.wholesaleOffer?.priceRupees ?? -1
                    : p.sellingPrice) >=
                0 &&
            (channel == BuyV2Destination.wholesale
                    ? p.wholesaleOffer?.priceRupees ?? -1
                    : p.sellingPrice) <=
                999999999
        ? p.packMeasure!.pricePerUnit(
            channel == BuyV2Destination.wholesale
                ? p.wholesaleOffer?.priceRupees ?? 0
                : p.sellingPrice,
          )
        : p.unitPrice,
    'seller': storeName,
    'sellerType': storeDetails?.publicSellerType ?? 'Store',
    'deliveryPromise': p.deliveryPromise,
    'origin': p.origin,
    'visualLabel': p.visualLabel,
    'visualKind': p.visualKind,
    'mrp': p.mrp,
    'requiresPrescription': p.requiresPrescription,
    'composition': p.composition,
    'regulatoryNote': p.regulatoryNote,
    'minimumOrder': channel == BuyV2Destination.wholesale
        ? p.wholesaleOffer?.minimumPacks
        : p.minimumOrder,
    'returnPolicy': p.returnPolicy?.trim().isNotEmpty == true
        ? p.returnPolicy
        : storeDetails?.returnSummary.trim().isNotEmpty == true
        ? storeDetails!.returnSummary.trim()
        : p.returnPolicy,
    'purchaseProtection': protectionValues(
      storeDetails?.protectionFor(p.returnPolicy),
    ),
    // Retained v1 export omits newer fields; the current audit below includes
    // them. Actual typed public products carry all supported pack addresses.
    if (p.compliance case final c?)
      ...Map.fromEntries(c.toJson().entries.where((entry) => !const {
        'manufacturerAddress', 'packerAddress', 'importerAddress',
      }.contains(entry.key))).map(
        (key, value) => MapEntry('compliance.$key', value),
      ),
  };

  static Map<String, Object?> publicProductValues(BuyV2Product p) => {
    'id': p.id,
    'canonicalId': p.canonicalId,
    'storeId': p.storeId,
    'destination': p.destination,
    'categoryId': p.categoryId,
    'brand': p.brand,
    'title': p.title,
    'variant': p.variant,
    'pack': p.pack,
    'price': p.price,
    'unitPrice': p.unitPrice,
    'seller': p.seller,
    'sellerType': p.sellerType,
    'deliveryPromise': p.deliveryPromise,
    'origin': p.origin,
    'visualLabel': p.visualLabel,
    'visualKind': p.visualKind,
    'mrp': p.mrp,
    'requiresPrescription': p.requiresPrescription,
    'composition': p.composition,
    'regulatoryNote': p.regulatoryNote,
    'minimumOrder': p.minimumOrder,
    'returnPolicy': p.returnPolicy,
    'purchaseProtection': protectionValues(p.purchaseProtection),
    if (p.compliance case final c?) ...{
      'compliance.genericName': c.genericName,
      'compliance.netQuantity': c.netQuantity,
      'compliance.manufacturerName': c.manufacturerName,
      'compliance.packerName': c.packerName,
      'compliance.importerName': c.importerName,
      'compliance.countryOfOrigin': c.countryOfOrigin,
      'compliance.manufacturedOrPackedOn': c.manufacturedOrPackedOnLabel,
      'compliance.bestBeforeOrUseBy': c.bestBeforeOrUseByLabel,
      'compliance.fssaiLicenseNumber': c.fssaiLicenseNumber,
      'compliance.consumerCare': c.consumerCare,
    },
  };

  /// Extend the audit without silently changing the retained v1 export schema.
  /// Unsupported provider values cannot be inferred from legacy text/quantity.
  static Map<String, Object?> sourceProductAuditValues(
    WorkspaceCatalogueItem p, {
    required String storeId,
    required String storeName,
    BuyV2Destination channel = BuyV2Destination.shop,
    WorkspaceStorePublicationDetails? storeDetails,
    BuyV2PackTerms? publicPackTerms,
  }) => {
    ...sourceProductValues(
      p,
      storeId: storeId,
      storeName: storeName,
      channel: channel,
      storeDetails: storeDetails,
    ),
    'variantAttributes': const <BuyV2VariantAttribute>[],
    'packTerms': publicPackTerms,
    if (publicPackTerms != null) 'unitPrice': publicPackTerms.unitPriceLabel ?? '',
    if (channel == BuyV2Destination.wholesale && p.wholesaleOffer?.valid == true)
      'price': p.wholesaleOffer!.priceAt(p.wholesaleOffer!.minimumPacks),
    'offerClass': channel == BuyV2Destination.shop
        ? BuyV2OfferClass.retail
        : switch (p.wholesaleOffer?.saleType) {
            BuyV2WholesaleSaleType.wholesale => BuyV2OfferClass.wholesale,
            BuyV2WholesaleSaleType.bulk => BuyV2OfferClass.bulk,
            null => null,
          },
    'reviewDeliveryOptions': const <BuyV2DeliveryOption>{},
    'compliance.manufacturerAddress': p.compliance?.manufacturerAddress,
    'compliance.packerAddress': p.compliance?.packerAddress,
    'compliance.importerAddress': p.compliance?.importerAddress,
  };

  static Map<String, Object?> publicProductAuditValues(BuyV2Product p) => {
    ...publicProductValues(p),
    // Empty allocations are equivalent; nonempty unowned values must reject.
    'variantAttributes': p.variantAttributes.isEmpty
        ? const <BuyV2VariantAttribute>[]
        : p.variantAttributes,
    'packTerms': p.packTerms,
    'offerClass': p.offerClass,
    'reviewDeliveryOptions': p.reviewDeliveryOptions.isEmpty
        ? const <BuyV2DeliveryOption>{}
        : p.reviewDeliveryOptions,
    'compliance.manufacturerAddress': p.compliance?.manufacturerAddress,
    'compliance.packerAddress': p.compliance?.packerAddress,
    'compliance.importerAddress': p.compliance?.importerAddress,
  };

  static List<WorkspacePublicationIssue> productIssues(
    WorkspaceCatalogueItem item, {
    required String storeId,
    required String storeName,
    BuyV2Destination channel = BuyV2Destination.shop,
    BuyV2Product? projected,
    WorkspaceStorePublicationDetails? storeDetails,
    BuyV2PackTerms? publicPackTerms,
    DateTime? now,
  }) {
    final issues = <WorkspacePublicationIssue>[];
    void missing(String field, String message) => issues.add(
      WorkspacePublicationIssue(
        '${item.id}:$field',
        'Store stock',
        '${item.title}: $message',
      ),
    );
    for (final field in {
      'title': item.title,
      'brand': item.brand,
      'pack': item.pack,
      'categoryId': item.categoryId,
      'unitPrice': item.packMeasure?.valid == true
          ? 'Derived from pack quantity'
          : item.unitPrice,
      'deliveryPromise': item.deliveryPromise,
      'origin': item.origin,
    }.entries) {
      if (field.value.trim().isEmpty) {
        missing(field.key, 'complete ${fieldLabels[field.key]}.');
      }
    }
    if (item.id.trim().isEmpty || item.canonicalId.trim().isEmpty) {
      missing('identity', 'product identity is missing.');
    }
    if (storeDetails?.channelEnabled(channel) == false) {
      missing('channel', 'This selling channel is off in Store settings.');
    }
    if (channel == BuyV2Destination.wholesale &&
        item.wholesaleOffer?.saleType == null) {
      missing(
        'wholesaleSaleType',
        'Choose Standard wholesale or Bulk supply in the product editor.',
      );
    }
    final price = channel == BuyV2Destination.wholesale
        ? item.wholesaleOffer?.priceRupees ?? 0
        : item.sellingPrice;
    final minimum = channel == BuyV2Destination.wholesale
        ? item.wholesaleOffer?.minimumPacks ?? 0
        : item.minimumOrder;
    if (price <= 0 || price > 999999999) {
      missing('sellingPrice', 'enter a selling price.');
    }
    if (item.mrp != null && item.mrp! < price) {
      missing('mrp', 'MRP is below the selling price.');
    }
    if (minimum <= 0) {
      missing('minimumOrder', 'enter a valid minimum order.');
    }
    if (item.catalogueFactsRequireReview) {
      missing('catalogueReview', 'product information needs review.');
    }
    try {
      WorkspaceProductContent.parse(item.content.inputValues);
    } on FormatException catch (error) {
      missing('content.${error.message.split(':').first}', error.message);
    }
    if (channel == BuyV2Destination.wholesale &&
        (item.wholesaleOffer?.valid != true ||
            item.wholesaleOffer?.enabled != true)) {
      missing('channel', 'Complete and enable wholesale selling terms.');
      return issues;
    }
    final termsIssue = item.publicSellingTermsIssue(
      channel: channel, storeId: storeId, terms: publicPackTerms, now: now,
    );
    if (termsIssue != null) {
      missing('packTerms', termsIssue);
      return issues;
    }
    final target =
        projected ??
        item.toBuyPublicProduct(
          storeId: storeId,
          storeName: storeName,
          channel: channel,
          storeDetails: storeDetails,
          publicPackTerms: publicPackTerms,
          now: now,
        );
    if (item.cataloguePhoto?.status != WorkspaceCataloguePhotoStatus.approved ||
        target.mediaAssets.isEmpty ||
        item.cataloguePhoto?.matches(item) != true) {
      missing(
        'photo',
        'an approved photo of this exact variant and pack is needed.',
      );
    }
    final photo = item.cataloguePhoto;
    if (photo != null && target.mediaAssets.isNotEmpty) {
      final asset = target.mediaAssets.singleOrNull;
      final binding = asset?.binding;
      if (asset?.id != photo.assetId ||
          asset?.source != photo.source ||
          binding?.assetRevision != photo.revision ||
          binding?.supplierWorkspaceId != photo.publisherWorkspaceId ||
          binding?.storeId != storeId ||
          binding?.skuId != item.id ||
          binding?.productId != item.canonicalId ||
          asset == null ||
          BuyV2SupplierMediaPolicy.publicationMessage(target, asset) != null) {
        missing(
          'photo.mapping',
          'the customer photo does not match this Store product.',
        );
      }
    }
    final from = sourceProductAuditValues(
      item,
      storeId: storeId,
      storeName: storeName,
      channel: channel,
      storeDetails: storeDetails,
      publicPackTerms: publicPackTerms,
    );
    final to = publicProductAuditValues(target);
    for (final key in {...from.keys, ...to.keys}) {
      if (!from.containsKey(key) ||
          !to.containsKey(key) ||
          from[key] != to[key]) {
        missing(
          key,
          'customer information does not match the saved product. Review its details.',
        );
      }
    }
    return issues;
  }

  static WorkspacePublicationReport inspect({
    required WorkWorkspace? store,
    required Iterable<WorkspaceCatalogueItem> products,
    WorkspaceStorePublicationDetails details =
        const WorkspaceStorePublicationDetails(),
  }) {
    final issues = <WorkspacePublicationIssue>[];
    if (store == null ||
        !store.verified ||
        store.id.trim().isEmpty ||
        store.name.trim().isEmpty ||
        store.area.trim().isEmpty) {
      issues.add(
        const WorkspacePublicationIssue(
          'store.identity',
          'Business details',
          'Complete verified Store identity and locality.',
        ),
      );
    }
    final selected = products.where((item) => item.publicListing).toList();
    if (selected.isEmpty) {
      issues.add(
        const WorkspacePublicationIssue(
          'products',
          'Store stock',
          'Choose products for customers after completing their details.',
        ),
      );
    }
    for (final item in selected) {
      if (item.retailEnabled) {
        issues.addAll(
          productIssues(
            item,
            storeId: store?.id ?? '',
            storeName: store?.name ?? '',
            storeDetails: details,
          ),
        );
      }
      if (item.wholesaleOffer?.enabled == true) {
        issues.addAll(
          productIssues(
            item,
            storeId: store?.id ?? '',
            storeName: store?.name ?? '',
            channel: BuyV2Destination.wholesale,
            storeDetails: details,
          ),
        );
      }
    }
    // These are verified gaps, NOT fabricated inputs/defaults or booleans that a
    // retailer can check off. Remove each only when its actual adapter is mapped
    // and tested. Backend work remains deferred; this frontend fails closed.
    issues.addAll([
      for (final error in details.inputErrors.entries)
        WorkspacePublicationIssue(
          'store.${error.key}',
          'Store settings',
          error.value,
        ),
      if (selected.any((p) => p.wholesaleOffer?.enabled == true) &&
          details.wholesalePaymentTerms.isEmpty)
        const WorkspacePublicationIssue(
          'store.wholesalePayments',
          'Payments & returns',
          'Choose the default wholesale payment terms.',
        ),
      if (selected.any(
        (item) => !item.retailEnabled && item.wholesaleOffer?.enabled != true,
      ))
        const WorkspacePublicationIssue(
          'product.channel',
          'Store stock',
          'Choose at least one selling channel for customer products.',
        ),
      if (details.street.trim().isEmpty ||
          details.city.trim().isEmpty ||
          details.state.trim().isEmpty ||
          details.shoppingArea?.valid != true ||
          details.shoppingArea?.postalCode != details.pinCode)
        const WorkspacePublicationIssue(
          'store.address',
          'Business details',
          'Your full Store address needs confirmation before publication.',
        ),
      if (details.legalName.trim().isEmpty ||
          details.returnSummary.trim().isEmpty)
        const WorkspacePublicationIssue(
          'store.terms',
          'Store settings',
          'Payment, delivery, return and invoice information need confirmation.',
        ),
      if (selected.any((item) => item.packMeasure?.valid != true))
        const WorkspacePublicationIssue(
          'product.quantity',
          'Store stock',
          'Pack quantities and price per unit need confirmation.',
        ),
      const WorkspacePublicationIssue(
        'publication.confirmation',
        'Publication',
        'Publication is not available yet. You can continue saving and using Store stock.',
      ),
    ]);
    // Keep Store-wide requirements visible even when thousands of selected SKUs
    // have individual issues. Retain every issue in the report for remediation.
    return WorkspacePublicationReport([
      ...issues.where((issue) => !issue.field.contains(':')),
      ...issues.where((issue) => issue.field.contains(':')),
    ]);
  }
}
