import 'package:flutter/material.dart';

import '../buy/buy_v2_content_contracts.dart';
import '../buy/buy_v2_models.dart';

enum WorkFeedFilter { forYou, jobs, freelance, campaigns, nearby }

extension WorkFeedFilterLabel on WorkFeedFilter {
  String get label => switch (this) {
    WorkFeedFilter.forYou => 'For You',
    WorkFeedFilter.jobs => 'Jobs',
    WorkFeedFilter.freelance => 'Freelance',
    WorkFeedFilter.campaigns => 'Campaigns',
    WorkFeedFilter.nearby => 'Nearby',
  };
}

enum WorkReviewStage { none, drafting, gstPending, approved, setup, live }

enum WorkspaceStoreState { open, paused, off }

enum WorkspaceDashboardState { ready, refreshing, offline, failed }

class WorkspaceProductCompliance {
  const WorkspaceProductCompliance({
    this.genericName,
    this.netQuantity,
    this.manufacturerName,
    this.packerName,
    this.importerName,
    this.countryOfOrigin,
    this.manufacturedOrPackedOn,
    this.bestBeforeOrUseBy,
    this.fssaiLicenseNumber,
    this.consumerCare,
  });

  final String? genericName;
  final String? netQuantity;
  final String? manufacturerName;
  final String? packerName;
  final String? importerName;
  final String? countryOfOrigin;
  final String? manufacturedOrPackedOn;
  final String? bestBeforeOrUseBy;
  final String? fssaiLicenseNumber;
  final String? consumerCare;
}

class WorkspaceOrderRecord {
  const WorkspaceOrderRecord({
    required this.id,
    required this.customer,
    required this.items,
    required this.quantities,
    required this.amount,
    required this.source,
    required this.fulfilment,
    required this.payment,
    required this.address,
    required this.stage,
    required this.needsDelivery,
    required this.createdAt,
    this.actionDeadline,
    this.extraMinutes = 0,
    this.stockReserved = false,
  });

  final String id;
  final String customer;
  final String items;
  final Map<String, int> quantities;
  final int amount;
  final String source;
  final String fulfilment;
  final String payment;
  final String address;
  final String stage;
  final bool needsDelivery;
  final DateTime createdAt;
  final DateTime? actionDeadline;
  final int extraMinutes;
  final bool stockReserved;

  WorkspaceOrderRecord copyWith({
    String? customer,
    String? items,
    Map<String, int>? quantities,
    int? amount,
    String? source,
    String? fulfilment,
    String? payment,
    String? address,
    String? stage,
    bool? needsDelivery,
    DateTime? actionDeadline,
    int? extraMinutes,
    bool? stockReserved,
  }) => WorkspaceOrderRecord(
    id: id,
    customer: customer ?? this.customer,
    items: items ?? this.items,
    quantities: Map<String, int>.unmodifiable(quantities ?? this.quantities),
    amount: amount ?? this.amount,
    source: source ?? this.source,
    fulfilment: fulfilment ?? this.fulfilment,
    payment: payment ?? this.payment,
    address: address ?? this.address,
    stage: stage ?? this.stage,
    needsDelivery: needsDelivery ?? this.needsDelivery,
    createdAt: createdAt,
    actionDeadline: actionDeadline ?? this.actionDeadline,
    extraMinutes: extraMinutes ?? this.extraMinutes,
    stockReserved: stockReserved ?? this.stockReserved,
  );
}

class WorkspaceDeliveryAssignment {
  const WorkspaceDeliveryAssignment({
    required this.orderId,
    required this.partnerName,
    required this.vehicleLabel,
    required this.eta,
    required this.stage,
  });

  final String orderId;
  final String partnerName;
  final String vehicleLabel;
  final DateTime eta;
  final String stage;
}

class WorkspacePackingLine {
  const WorkspacePackingLine({
    required this.id,
    required this.label,
    required this.quantity,
    required this.packed,
  });

  final String id;
  final String label;
  final int quantity;
  final bool packed;
}

class WorkspaceCustomerInvoice {
  const WorkspaceCustomerInvoice({
    required this.id,
    required this.orderId,
    required this.customer,
    required this.items,
    required this.amount,
    required this.payment,
    required this.issuedAt,
    this.sharedChannels = const <String>{},
  });

  final String id;
  final String orderId;
  final String customer;
  final String items;
  final int amount;
  final String payment;
  final DateTime issuedAt;
  final Set<String> sharedChannels;

  bool get needsCustomerHandoff => sharedChannels.isEmpty;

  WorkspaceCustomerInvoice copyWith({Set<String>? sharedChannels}) =>
      WorkspaceCustomerInvoice(
        id: id,
        orderId: orderId,
        customer: customer,
        items: items,
        amount: amount,
        payment: payment,
        issuedAt: issuedAt,
        sharedChannels: Set<String>.unmodifiable(
          sharedChannels ?? this.sharedChannels,
        ),
      );
}

class WorkspaceStoreOffer {
  const WorkspaceStoreOffer({
    required this.id,
    required this.title,
    required this.detail,
    required this.validUntil,
    required this.active,
  });

  final String id;
  final String title;
  final String detail;
  final DateTime validUntil;
  final bool active;
}

enum WorkspaceStockMode { availabilityOnly, exactQuantity }

enum WorkspaceStockMovementKind {
  sale,
  returned,
  goodsReceived,
  adjustment,
  damageOrExpiry,
  openingStock,
}

class WorkspaceStockMovement {
  const WorkspaceStockMovement({
    required this.id,
    required this.productId,
    required this.productLabel,
    required this.kind,
    required this.quantityDelta,
    required this.reason,
    required this.occurredAt,
  });

  final String id;
  final String productId;
  final String productLabel;
  final WorkspaceStockMovementKind kind;
  final int quantityDelta;
  final String reason;
  final DateTime occurredAt;
}

class WorkspaceCatalogueItem {
  const WorkspaceCatalogueItem({
    required this.id,
    required this.canonicalId,
    required this.categoryId,
    required this.brand,
    required this.title,
    required this.variant,
    required this.pack,
    required this.sku,
    required this.barcode,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.unitPrice,
    required this.stock,
    required this.deliveryPromise,
    required this.origin,
    required this.visualLabel,
    required this.visualKind,
    this.mrp,
    this.minimumOrder = 1,
    this.returnPolicy,
    this.requiresPrescription = false,
    this.composition,
    this.regulatoryNote,
    this.compliance,
    this.available = true,
    this.publicListing = true,
    this.stockMode = WorkspaceStockMode.exactQuantity,
    this.lowStockThreshold = 5,
  });

  final String id;
  final String canonicalId;
  final String categoryId;
  final String brand;
  final String title;
  final String variant;
  final String pack;
  final String sku;
  final String barcode;
  final int purchasePrice;
  final int sellingPrice;
  final String unitPrice;
  final int stock;
  final String deliveryPromise;
  final String origin;
  final String visualLabel;
  final String visualKind;
  final int? mrp;
  final int minimumOrder;
  final String? returnPolicy;
  final bool requiresPrescription;
  final String? composition;
  final String? regulatoryNote;
  final WorkspaceProductCompliance? compliance;
  final bool available;
  final bool publicListing;
  final WorkspaceStockMode stockMode;
  final int lowStockThreshold;

  bool get published =>
      publicListing &&
      available &&
      (stockMode == WorkspaceStockMode.availabilityOnly || stock > 0);

  BuyV2Product toBuyPublicProduct({
    required String storeName,
    String badge = 'Store price',
    String confirmedOn = 'Updated by store',
  }) => BuyV2Product(
    id: id,
    canonicalId: canonicalId,
    destination: BuyV2Destination.shop,
    categoryId: categoryId,
    brand: brand,
    title: title,
    variant: variant,
    pack: pack,
    price: sellingPrice,
    unitPrice: unitPrice,
    badge: badge,
    seller: storeName,
    sellerType: 'Verified retailer',
    deliveryPromise: deliveryPromise,
    origin: origin,
    confirmedOn: confirmedOn,
    visualLabel: visualLabel,
    visualKind: visualKind,
    mrp: mrp,
    requiresPrescription: requiresPrescription,
    composition: composition,
    regulatoryNote: regulatoryNote,
    minimumOrder: minimumOrder,
    returnPolicy: returnPolicy,
    catalogueListing: publicListing,
  );

  BuyV2ProductFactsSnapshot toBuyPublicFacts({
    required String storeName,
    required String sourceId,
    required bool storeVisible,
    required bool acceptingOrders,
    required DateTime observedAt,
    String? nextOpeningLabel,
    String? orderCutoffLabel,
    String? deliveryFeeLabel,
  }) {
    final product = toBuyPublicProduct(storeName: storeName);
    final orderable =
        storeVisible &&
        publicListing &&
        available &&
        (stockMode == WorkspaceStockMode.availabilityOnly || stock > 0) &&
        acceptingOrders;
    return BuyV2ProductFactsSnapshot(
      productId: id,
      price: sellingPrice,
      deliveryPromise: deliveryPromise,
      partner: storeName,
      orderabilityLabel: orderable
          ? 'Available to order'
          : !storeVisible || !publicListing
          ? 'Not listed for customers'
          : !available ||
                (stockMode == WorkspaceStockMode.exactQuantity && stock <= 0)
          ? 'Out of stock'
          : 'Store is not accepting orders',
      sourceId: sourceId,
      fulfilmentMode: buyV2CatalogueFulfilmentModeFor(product),
      storeOperatingState: acceptingOrders
          ? BuyV2StoreOperatingState.open
          : BuyV2StoreOperatingState.closed,
      nextOpeningLabel: nextOpeningLabel,
      orderCutoffLabel: orderCutoffLabel,
      deliveryFeeLabel: deliveryFeeLabel,
      observedAt: observedAt,
    );
  }

  WorkspaceCatalogueItem copyWith({
    String? canonicalId,
    String? categoryId,
    String? brand,
    String? title,
    String? variant,
    String? pack,
    String? sku,
    String? barcode,
    int? purchasePrice,
    int? sellingPrice,
    String? unitPrice,
    int? stock,
    String? deliveryPromise,
    String? origin,
    String? visualLabel,
    String? visualKind,
    int? mrp,
    int? minimumOrder,
    String? returnPolicy,
    bool? requiresPrescription,
    String? composition,
    String? regulatoryNote,
    WorkspaceProductCompliance? compliance,
    bool? available,
    bool? publicListing,
    WorkspaceStockMode? stockMode,
    int? lowStockThreshold,
  }) => WorkspaceCatalogueItem(
    id: id,
    canonicalId: canonicalId ?? this.canonicalId,
    categoryId: categoryId ?? this.categoryId,
    brand: brand ?? this.brand,
    title: title ?? this.title,
    variant: variant ?? this.variant,
    pack: pack ?? this.pack,
    sku: sku ?? this.sku,
    barcode: barcode ?? this.barcode,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    unitPrice: unitPrice ?? this.unitPrice,
    stock: stock ?? this.stock,
    deliveryPromise: deliveryPromise ?? this.deliveryPromise,
    origin: origin ?? this.origin,
    visualLabel: visualLabel ?? this.visualLabel,
    visualKind: visualKind ?? this.visualKind,
    mrp: mrp ?? this.mrp,
    minimumOrder: minimumOrder ?? this.minimumOrder,
    returnPolicy: returnPolicy ?? this.returnPolicy,
    requiresPrescription: requiresPrescription ?? this.requiresPrescription,
    composition: composition ?? this.composition,
    regulatoryNote: regulatoryNote ?? this.regulatoryNote,
    compliance: compliance ?? this.compliance,
    available: available ?? this.available,
    publicListing: publicListing ?? this.publicListing,
    stockMode: stockMode ?? this.stockMode,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
  );
}

const workspaceMasterCatalogue = <WorkspaceCatalogueItem>[
  WorkspaceCatalogueItem(
    id: 'oil-fortune-1l',
    canonicalId: 'oil-fortune-sunflower',
    categoryId: 'cooking-oil',
    brand: 'Fortune',
    title: 'Fortune Sunflower Oil',
    variant: 'Refined sunflower oil',
    pack: '1 L pouch',
    sku: 'FRT-1L',
    barcode: '8906007281015',
    purchasePrice: 248,
    sellingPrice: 264,
    unitPrice: '₹264/L',
    stock: 0,
    deliveryPromise: 'Store pickup or local delivery',
    origin: 'India',
    visualLabel: 'Fortune Sunflower Oil 1 L pouch',
    visualKind: 'catalogue-packshot',
    mrp: 270,
    returnPolicy: 'Return accepted for a sealed damaged pack at delivery.',
    compliance: WorkspaceProductCompliance(
      genericName: 'Refined sunflower oil',
      netQuantity: '1 L',
      countryOfOrigin: 'India',
    ),
  ),
  WorkspaceCatalogueItem(
    id: 'atta-aashirvaad-1kg',
    canonicalId: 'atta-aashirvaad-whole-wheat',
    categoryId: 'flour-grains',
    brand: 'Aashirvaad',
    title: 'Aashirvaad Whole Wheat Atta',
    variant: 'Whole wheat flour',
    pack: '1 kg pack',
    sku: 'AAT-1K',
    barcode: '8901725001228',
    purchasePrice: 98,
    sellingPrice: 108,
    unitPrice: '₹108/kg',
    stock: 0,
    deliveryPromise: 'Store pickup or local delivery',
    origin: 'India',
    visualLabel: 'Aashirvaad Whole Wheat Atta 1 kg',
    visualKind: 'catalogue-packshot',
    mrp: 112,
    compliance: WorkspaceProductCompliance(
      genericName: 'Whole wheat flour',
      netQuantity: '1 kg',
      countryOfOrigin: 'India',
    ),
  ),
  WorkspaceCatalogueItem(
    id: 'salt-tata-1kg',
    canonicalId: 'salt-tata-iodised',
    categoryId: 'salt-spices',
    brand: 'Tata',
    title: 'Tata Salt',
    variant: 'Iodised salt',
    pack: '1 kg pack',
    sku: 'TSL-1K',
    barcode: '8904043901017',
    purchasePrice: 50,
    sellingPrice: 56,
    unitPrice: '₹56/kg',
    stock: 0,
    deliveryPromise: 'Store pickup or local delivery',
    origin: 'India',
    visualLabel: 'Tata Salt 1 kg pack',
    visualKind: 'catalogue-packshot',
    mrp: 58,
    compliance: WorkspaceProductCompliance(
      genericName: 'Iodised salt',
      netQuantity: '1 kg',
      countryOfOrigin: 'India',
    ),
  ),
];

class WorkspaceActivityEntry {
  const WorkspaceActivityEntry({required this.message, required this.time});

  final String message;
  final DateTime time;
}

class WorkspaceGroupBuy {
  const WorkspaceGroupBuy({
    required this.id,
    required this.productName,
    required this.specification,
    required this.leadRetailer,
    required this.confirmedRetailers,
    required this.targetQuantity,
    required this.securedQuantity,
    required this.unitLabel,
    required this.regularUnitPrice,
    required this.groupUnitPrice,
    required this.facilitationFee,
    required this.deliveryFee,
    required this.confirmationAmount,
    required this.closingLabel,
    required this.storeDeliveryLabel,
    required this.paymentConfirmed,
    this.deliveryPartnerName,
    this.participants = const [],
  });

  final String id;
  final String productName;
  final String specification;
  final String leadRetailer;
  final List<String> confirmedRetailers;
  final int targetQuantity;
  final int securedQuantity;
  final String unitLabel;
  final int regularUnitPrice;
  final int groupUnitPrice;
  final int facilitationFee;
  final int deliveryFee;
  final int confirmationAmount;
  final String closingLabel;
  final String storeDeliveryLabel;
  final bool paymentConfirmed;
  final String? deliveryPartnerName;
  final List<WorkspaceGroupBuyParticipant> participants;

  int get remainingQuantity =>
      (targetQuantity - securedQuantity).clamp(0, targetQuantity);
  int get savingPerUnit => regularUnitPrice - groupUnitPrice;
  int get totalSaving => savingPerUnit * securedQuantity;
  int get goodsValue => groupUnitPrice * securedQuantity;
  int get deliveredTotal => goodsValue + facilitationFee + deliveryFee;
  int get referenceTotal => regularUnitPrice * securedQuantity;
  int get netSaving => (referenceTotal - deliveredTotal).clamp(0, 1 << 31);
  int get balanceDue => (deliveredTotal - confirmationAmount).clamp(0, 1 << 31);
}

class WorkspaceGroupBuyParticipant {
  const WorkspaceGroupBuyParticipant({
    required this.businessName,
    required this.locality,
    required this.quantity,
    required this.unitLabel,
    required this.milestone,
  });

  final String businessName;
  final String locality;
  final int quantity;
  final String unitLabel;
  final String milestone;
}

enum WorkOpportunityPosterType {
  moolSocial,
  retailer,
  wholesaler,
  socialUser,
  manufacturer,
  rider,
  doctor,
  other,
}

extension WorkOpportunityPosterTypeLabel on WorkOpportunityPosterType {
  String get label => switch (this) {
    WorkOpportunityPosterType.moolSocial => 'MoolSocial',
    WorkOpportunityPosterType.retailer => 'Retailer',
    WorkOpportunityPosterType.wholesaler => 'Wholesaler',
    WorkOpportunityPosterType.socialUser => 'Social user',
    WorkOpportunityPosterType.manufacturer => 'Manufacturer',
    WorkOpportunityPosterType.rider => 'Rider',
    WorkOpportunityPosterType.doctor => 'Doctor',
    WorkOpportunityPosterType.other => 'Other verified user',
  };
}

enum WorkOpportunityCardColorToken {
  cobalt,
  emerald,
  crimson,
  violet,
  amber,
  teal,
  magenta,
  indigo,
}

class WorkOpportunity {
  const WorkOpportunity({
    required this.id,
    required this.publisher,
    required this.publisherType,
    required this.posterType,
    required this.title,
    required this.summary,
    required this.qualificationHeadline,
    required this.kind,
    required this.location,
    required this.city,
    required this.area,
    required this.pincode,
    required this.capacity,
    required this.peopleNeeded,
    required this.peopleJoined,
    required this.applicationsInProgress,
    required this.finalDeadline,
    required this.paymentAmount,
    required this.monthlyPayment,
    required this.payout,
    required this.requiredWork,
    required this.deadline,
    required this.fundingNote,
    required this.aboutRole,
    required this.whatYoullDo,
    required this.whoYouAre,
    required this.niceToHave,
    required this.whyJoin,
    required this.cardColorToken,
    required this.requiresWorkspace,
    required this.icon,
    required this.filters,
    this.hourlyPayment,
    this.assignmentPayment,
    this.funded = true,
    this.available = true,
  });

  final String id;
  final String publisher;
  final String publisherType;
  final WorkOpportunityPosterType posterType;
  final String title;
  final String summary;
  final String qualificationHeadline;
  final String kind;
  final String location;
  final String city;
  final String area;
  final String pincode;
  final String capacity;
  final int peopleNeeded;
  final int peopleJoined;
  final int applicationsInProgress;
  final String finalDeadline;
  int get positionsRemaining {
    final remaining = peopleNeeded - peopleJoined - applicationsInProgress;
    return remaining < 0 ? 0 : remaining;
  }

  final String paymentAmount;
  String get payment => monthlyPayment;
  final String monthlyPayment;
  final String? hourlyPayment;
  final String? assignmentPayment;
  final String payout;
  final String requiredWork;
  final String deadline;
  final String fundingNote;
  final String aboutRole;
  final List<String> whatYoullDo;
  final List<String> whoYouAre;
  final List<String> niceToHave;
  final String whyJoin;
  final WorkOpportunityCardColorToken cardColorToken;
  final bool requiresWorkspace;
  final IconData icon;
  final Set<WorkFeedFilter> filters;
  final bool funded;
  final bool available;
}

class WorkTerm {
  const WorkTerm({required this.id, required this.title, required this.detail});

  final String id;
  final String title;
  final String detail;
}

enum WorkGstMatchCategory {
  retailGoodsSupplier,
  wholesaleDistributor,
  manufacturerSupplier,
  foodServiceProvider,
  healthcareProvider,
  pharmacySupplier,
  personalCareProvider,
  bikeTravelProvider,
  autoTravelProvider,
  cabTravelProvider,
  busTravelProvider,
  quickDeliveryBiker,
  wholesaleFleetDelivery,
  bulkDeliveryFleet,
  digitalContentProvider,
  independentProfessional,
}

extension WorkGstMatchCategoryLabel on WorkGstMatchCategory {
  String get label => switch (this) {
    WorkGstMatchCategory.retailGoodsSupplier => 'Retail goods supplier',
    WorkGstMatchCategory.wholesaleDistributor => 'Wholesale distributor',
    WorkGstMatchCategory.manufacturerSupplier => 'Manufacturer or supplier',
    WorkGstMatchCategory.foodServiceProvider => 'Food service provider',
    WorkGstMatchCategory.healthcareProvider => 'Healthcare provider',
    WorkGstMatchCategory.pharmacySupplier => 'Pharmacy or medicine supplier',
    WorkGstMatchCategory.personalCareProvider =>
      'Personal care service provider',
    WorkGstMatchCategory.bikeTravelProvider => 'Bike travel provider',
    WorkGstMatchCategory.autoTravelProvider => 'Auto travel provider',
    WorkGstMatchCategory.cabTravelProvider => 'Cab travel provider',
    WorkGstMatchCategory.busTravelProvider => 'Bus travel provider',
    WorkGstMatchCategory.quickDeliveryBiker => 'Quick delivery biker',
    WorkGstMatchCategory.wholesaleFleetDelivery => 'Wholesale fleet delivery',
    WorkGstMatchCategory.bulkDeliveryFleet => 'Bulk delivery fleet',
    WorkGstMatchCategory.digitalContentProvider =>
      'Digital content service provider',
    WorkGstMatchCategory.independentProfessional => 'Independent professional',
  };
}

class WorkProfileOption {
  const WorkProfileOption({
    required this.id,
    required this.familyId,
    required this.familyLabel,
    required this.label,
    required this.gstMatchCategory,
    required this.sellSide,
    required this.buySide,
    required this.tools,
    required this.icon,
  });

  final String id;
  final String familyId;
  final String familyLabel;
  final String label;
  final WorkGstMatchCategory gstMatchCategory;
  final String sellSide;
  final String buySide;
  final String tools;
  final IconData icon;
}

enum WorkContactChannel { primaryMobile, email, alternateMobile }

extension WorkContactChannelValue on WorkContactChannel {
  String get apiValue => switch (this) {
    WorkContactChannel.primaryMobile => 'primary_mobile',
    WorkContactChannel.email => 'email',
    WorkContactChannel.alternateMobile => 'alternate_mobile',
  };
}

class WorkAccountSnapshot {
  const WorkAccountSnapshot({
    this.displayName = '',
    this.email = '',
    this.mobile = '',
    this.providerLabel = '',
    this.providerAccount = '',
    this.emailConfirmed = false,
    this.mobileConfirmed = false,
  });

  final String displayName;
  final String email;
  final String mobile;
  final String providerLabel;
  final String providerAccount;
  final bool emailConfirmed;
  final bool mobileConfirmed;
}

enum WorkDocumentImportance { required, ifApplicable, optional }

extension WorkDocumentImportanceLabel on WorkDocumentImportance {
  String get label => switch (this) {
    WorkDocumentImportance.required => 'Required',
    WorkDocumentImportance.ifApplicable => 'Required when applicable',
    WorkDocumentImportance.optional => 'Optional',
  };
}

class WorkDocumentChecklistItem {
  const WorkDocumentChecklistItem({
    required this.title,
    required this.detail,
    required this.importance,
    required this.icon,
  });

  final String title;
  final String detail;
  final WorkDocumentImportance importance;
  final IconData icon;
}

const _identityDocument = WorkDocumentChecklistItem(
  title: 'Account owner identity',
  detail: 'PAN, Aadhaar or another accepted government identity document.',
  importance: WorkDocumentImportance.required,
  icon: Icons.badge_outlined,
);

const _gstDocument = WorkDocumentChecklistItem(
  title: 'GST registration certificate',
  detail:
      'Required when GST registration applies to this Workspace. Applicability is confirmed during verification.',
  importance: WorkDocumentImportance.ifApplicable,
  icon: Icons.receipt_long_outlined,
);

const _payoutBankDocument = WorkDocumentChecklistItem(
  title: 'Payout bank account proof',
  detail:
      'A cancelled cheque or recent bank statement PDF showing the account holder name, account number and IFSC for approved sales, service or work payments.',
  importance: WorkDocumentImportance.required,
  icon: Icons.account_balance_outlined,
);

List<WorkDocumentChecklistItem> _withRequiredPayoutBank(
  List<WorkDocumentChecklistItem> profileDocuments,
) => List<WorkDocumentChecklistItem>.unmodifiable([
  ...profileDocuments.where(
    (document) =>
        document.title != _gstDocument.title &&
        document.title != 'Payout account document',
  ),
  _payoutBankDocument,
  _gstDocument,
]);

extension WorkProfileDocumentChecklist on WorkProfileOption {
  List<WorkDocumentChecklistItem>
  get verificationDocuments => _withRequiredPayoutBank(switch (id) {
    'retailer-grocery' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Shop address document',
        detail:
            'Ownership, rent, lease, consent or a recent utility document for the shop.',
        importance: WorkDocumentImportance.required,
        icon: Icons.storefront_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Food business registration or licence',
        detail: 'FSSAI registration or licence when food products require it.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.restaurant_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Owner or operator authority',
        detail: 'Authorisation when the account owner is not the shop owner.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'retailer-speciality' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Store address document',
        detail:
            'Ownership, rent, lease, consent or a recent utility document for the store.',
        importance: WorkDocumentImportance.required,
        icon: Icons.shopping_bag_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Category licence or registration',
        detail: 'Any licence required for the products you sell.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.verified_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Owner or operator authority',
        detail: 'Authorisation when the account owner is not the store owner.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'wholesaler' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Business registration document',
        detail:
            'Registration or constitution document for the wholesale business.',
        importance: WorkDocumentImportance.required,
        icon: Icons.business_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Warehouse or business address document',
        detail: 'Ownership, rent, lease, consent or utility document.',
        importance: WorkDocumentImportance.required,
        icon: Icons.warehouse_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Authorised representative document',
        detail: 'Authorisation if another person manages this Workspace.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'manufacturer' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Business registration document',
        detail: 'Company, partnership, LLP, proprietorship or Udyam document.',
        importance: WorkDocumentImportance.required,
        icon: Icons.business_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Manufacturing unit address document',
        detail:
            'Ownership, rent, lease, consent or utility document for the unit.',
        importance: WorkDocumentImportance.required,
        icon: Icons.factory_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Manufacturing licence',
        detail: 'Licence or approval required for your product category.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.approval_outlined,
      ),
      _gstDocument,
    ],
    'restaurant' || 'cloud-kitchen' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'FSSAI registration or licence',
        detail: 'The food registration or licence applicable to your business.',
        importance: WorkDocumentImportance.required,
        icon: Icons.restaurant_menu_rounded,
      ),
      WorkDocumentChecklistItem(
        title: 'Kitchen or restaurant address document',
        detail: 'Ownership, rent, lease, consent or utility document.',
        importance: WorkDocumentImportance.required,
        icon: Icons.location_city_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Owner or operator authority',
        detail: 'Authorisation when the account owner is not the operator.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'clinic' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Professional registration certificate',
        detail:
            'Current medical council or applicable professional registration.',
        importance: WorkDocumentImportance.required,
        icon: Icons.medical_services_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Clinic address document',
        detail: 'Address document when appointments are offered from a clinic.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.local_hospital_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Clinic operator authority',
        detail: 'Authorisation when the doctor does not own the clinic.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'pharmacy' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Drug licence',
        detail: 'Current retail or wholesale drug licence for the pharmacy.',
        importance: WorkDocumentImportance.required,
        icon: Icons.local_pharmacy_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Pharmacist or authorised-person document',
        detail:
            'Registration or authorisation for the responsible professional.',
        importance: WorkDocumentImportance.required,
        icon: Icons.badge_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Pharmacy address document',
        detail: 'Ownership, rent, lease, consent or utility document.',
        importance: WorkDocumentImportance.required,
        icon: Icons.store_outlined,
      ),
      _gstDocument,
    ],
    'salon' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Salon address document',
        detail: 'Ownership, rent, lease, consent or utility document.',
        importance: WorkDocumentImportance.required,
        icon: Icons.content_cut_rounded,
      ),
      WorkDocumentChecklistItem(
        title: 'Shop or local registration',
        detail: 'Local registration or licence required for your salon.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.approval_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Owner or operator authority',
        detail: 'Authorisation when the account owner is not the salon owner.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'travel-bike-provider' ||
    'travel-auto-provider' ||
    'travel-cab-provider' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Driving licence',
        detail: 'Current licence for the vehicle category you operate.',
        importance: WorkDocumentImportance.required,
        icon: Icons.badge_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Vehicle registration certificate',
        detail: 'Current RC for the vehicle used for passenger travel.',
        importance: WorkDocumentImportance.required,
        icon: Icons.directions_car_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Vehicle insurance and permit',
        detail:
            'Current insurance and the permit applicable to the travel service.',
        importance: WorkDocumentImportance.required,
        icon: Icons.health_and_safety_outlined,
      ),
      _gstDocument,
    ],
    'travel-bus-provider' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Bus driving licence or operator authority',
        detail:
            'Current vehicle-category licence or authority from the bus operator.',
        importance: WorkDocumentImportance.required,
        icon: Icons.badge_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Bus registration certificate',
        detail: 'Current RC for each bus added to the Workspace.',
        importance: WorkDocumentImportance.required,
        icon: Icons.directions_bus_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Passenger-service permit and insurance',
        detail:
            'Current insurance and the permit applicable to the passenger service.',
        importance: WorkDocumentImportance.required,
        icon: Icons.health_and_safety_outlined,
      ),
      _gstDocument,
    ],
    'quick-delivery-biker' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Driving licence',
        detail: 'Current licence for the delivery bike category.',
        importance: WorkDocumentImportance.required,
        icon: Icons.badge_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Bike registration certificate',
        detail: 'Current RC for the bike used for delivery work.',
        importance: WorkDocumentImportance.required,
        icon: Icons.two_wheeler_rounded,
      ),
      WorkDocumentChecklistItem(
        title: 'Bike insurance and permit',
        detail: 'Current insurance and any permit applicable to delivery work.',
        importance: WorkDocumentImportance.required,
        icon: Icons.health_and_safety_outlined,
      ),
      _gstDocument,
    ],
    'wholesale-fleet-delivery' || 'bulk-delivery-fleet' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Transport business registration',
        detail: 'Registration or constitution document for the fleet business.',
        importance: WorkDocumentImportance.required,
        icon: Icons.business_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Vehicle RC, permit and insurance',
        detail:
            'Current documents for delivery vehicles added to the Workspace.',
        importance: WorkDocumentImportance.required,
        icon: Icons.local_shipping_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Fleet operator authority',
        detail: 'Authorisation for the person managing the fleet.',
        importance: WorkDocumentImportance.required,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    'creator' => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Portfolio or channel ownership',
        detail:
            'A public portfolio, channel or account showing your original work.',
        importance: WorkDocumentImportance.required,
        icon: Icons.video_camera_front_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Payout account document',
        detail:
            'A bank document that confirms where approved earnings are paid.',
        importance: WorkDocumentImportance.required,
        icon: Icons.account_balance_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Agency or brand authorisation',
        detail: 'Authorisation when you represent a creator agency or brand.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.assignment_ind_outlined,
      ),
      _gstDocument,
    ],
    _ => const [
      _identityDocument,
      WorkDocumentChecklistItem(
        title: 'Portfolio, qualification or experience document',
        detail: 'A document or link that demonstrates the work you offer.',
        importance: WorkDocumentImportance.required,
        icon: Icons.work_outline_rounded,
      ),
      WorkDocumentChecklistItem(
        title: 'Payout account document',
        detail:
            'A bank document that confirms where approved earnings are paid.',
        importance: WorkDocumentImportance.required,
        icon: Icons.account_balance_outlined,
      ),
      WorkDocumentChecklistItem(
        title: 'Professional licence',
        detail: 'A current licence when your profession requires one.',
        importance: WorkDocumentImportance.ifApplicable,
        icon: Icons.workspace_premium_outlined,
      ),
      _gstDocument,
    ],
  });
}

class WorkProofRequirement {
  const WorkProofRequirement({
    required this.id,
    required this.label,
    required this.detail,
    required this.importance,
  });

  final String id;
  final String label;
  final String detail;
  final WorkDocumentImportance importance;
  bool get required => importance == WorkDocumentImportance.required;
}

class WorkWorkspace {
  const WorkWorkspace({
    required this.id,
    required this.name,
    required this.profileLabel,
    required this.area,
    required this.verified,
    this.profileId,
    this.gstReminder = false,
  });

  final String id;
  final String name;
  final String profileLabel;
  final String? profileId;
  final String area;
  final bool verified;
  final bool gstReminder;
}

const workOpportunities = <WorkOpportunity>[
  WorkOpportunity(
    id: 'quick-delivery-biker',
    publisher: 'MoolSocial',
    publisherType: 'MoolSocial-owned funded task',
    posterType: WorkOpportunityPosterType.moolSocial,
    title: 'Quick Delivery Biker',
    summary:
        'Pick up prepaid local orders and complete OTP-confirmed deliveries during an agreed shift.',
    qualificationHeadline: 'Bike, valid licence and Android phone required',
    kind: 'Freelance delivery',
    location: 'Sardarpura, Jodhpur · 342003',
    city: 'Jodhpur',
    area: 'Sardarpura',
    pincode: '342003',
    capacity: '18 funded shifts',
    peopleNeeded: 18,
    peopleJoined: 6,
    applicationsInProgress: 4,
    finalDeadline: '05 Sep 2026',
    paymentAmount: '₹650 per completed shift',
    monthlyPayment: 'Up to ₹19,500 monthly for 30 completed shifts',
    hourlyPayment: '₹100 per active hour',
    assignmentPayment: '₹650 for 8 verified drops',
    payout: 'Within 1 working day',
    requiredWork: 'Rider / delivery freelancer',
    deadline: 'Apply while 18 funded shifts remain',
    fundingNote: 'Funded · ₹11,700 total task budget',
    aboutRole:
        'A flexible local delivery assignment for riders who can complete a fixed, prepaid route safely and on time.',
    whatYoullDo: [
      'Collect the assigned prepaid orders from the pickup point.',
      'Complete eight OTP-confirmed drops in the assigned area.',
      'Report delivery exceptions through the route support flow.',
    ],
    whoYouAre: [
      'You have a roadworthy bike, valid driving licence and smartphone.',
      'You can navigate Sardarpura and communicate clearly with customers.',
    ],
    niceToHave: [
      'Previous food, grocery or parcel delivery experience.',
      'Your own insulated delivery bag.',
    ],
    whyJoin:
        'Choose a funded shift with its route, work requirement and payout stated before you apply.',
    cardColorToken: WorkOpportunityCardColorToken.cobalt,
    requiresWorkspace: true,
    icon: Icons.delivery_dining_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.jobs,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'user-acquisition-onboarding',
    publisher: 'MoolSocial Growth',
    publisherType: 'MoolSocial-owned funded task',
    posterType: WorkOpportunityPosterType.moolSocial,
    title: 'MoolSocial User Acquisition & Business Onboarding Specialist',
    summary:
        'Meet local retailers, explain MoolSocial and complete owner-approved onboarding.',
    qualificationHeadline: 'Local retail network and field-sales confidence',
    kind: 'Freelance onboarding',
    location: 'Sardarpura, Jodhpur · 342003',
    city: 'Jodhpur',
    area: 'Sardarpura',
    pincode: '342003',
    capacity: '40 funded onboardings',
    peopleNeeded: 40,
    peopleJoined: 14,
    applicationsInProgress: 9,
    finalDeadline: '07 Sep 2026',
    paymentAmount: '₹350 per verified retailer',
    monthlyPayment: 'Up to ₹14,000 monthly for 40 verified onboardings',
    assignmentPayment: '₹350 per approved onboarding',
    payout: 'T+1 after verification',
    requiredWork: 'Retailer acquisition freelancer',
    deadline: 'Open while 40 funded onboardings remain',
    fundingNote: 'Funded · maximum task budget ₹14,000',
    aboutRole:
        'Acquire eligible local retailers and help each owner complete an informed, consent-based MoolSocial onboarding.',
    whatYoullDo: [
      'Identify eligible retailers in the assigned area.',
      'Explain the relevant app benefits without making false promises.',
      'Submit owner consent and the required verified onboarding record.',
    ],
    whoYouAre: [
      'You know local shop owners and are comfortable with field visits.',
      'You can demonstrate a mobile app in Hindi or a local language.',
    ],
    niceToHave: [
      'Retail distribution, merchant acquisition or FMCG experience.',
    ],
    whyJoin:
        'Earn against each verified outcome with the acceptance rule and funded capacity visible upfront.',
    cardColorToken: WorkOpportunityCardColorToken.emerald,
    requiresWorkspace: false,
    icon: Icons.storefront_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'retailer-onboarding-specialist',
    publisher: 'Mahadev Fresh Mart',
    publisherType: 'Verified retailer-owned posting',
    posterType: WorkOpportunityPosterType.retailer,
    title: 'Retailer Onboarding Specialist',
    summary:
        'Onboard verified kirana and speciality retailers in one assigned market.',
    qualificationHeadline:
        'Retailer relationships and field-app demonstration skills',
    kind: 'Freelance onboarding',
    location: 'Ratanada, Jodhpur · 342011',
    city: 'Jodhpur',
    area: 'Ratanada',
    pincode: '342011',
    capacity: '20 funded onboardings',
    peopleNeeded: 20,
    peopleJoined: 8,
    applicationsInProgress: 5,
    finalDeadline: '06 Sep 2026',
    paymentAmount: '₹350 per verified retailer',
    monthlyPayment: 'Up to ₹7,000 monthly for 20 verified onboardings',
    assignmentPayment: '₹350 per approved onboarding',
    payout: 'T+1 after verification',
    requiredWork: 'Retailer onboarding freelancer',
    deadline: 'Open while 20 funded onboardings remain',
    fundingNote: 'Retailer funded · maximum task budget ₹7,000',
    aboutRole:
        'Help a verified retailer association bring eligible peers onto MoolSocial through an informed, owner-approved onboarding flow.',
    whatYoullDo: [
      'Meet the owner and explain the relevant retailer workflow.',
      'Confirm business category and operating area.',
      'Submit consent-backed onboarding evidence.',
    ],
    whoYouAre: [
      'You know local retailers and can conduct field visits.',
      'You can demonstrate an app accurately in a local language.',
    ],
    niceToHave: [
      'FMCG, merchant acquisition or retail distribution experience.',
    ],
    whyJoin: 'Earn a stated amount for each independently verified retailer.',
    cardColorToken: WorkOpportunityCardColorToken.amber,
    requiresWorkspace: false,
    icon: Icons.add_business_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'manufacturer-onboarding-specialist',
    publisher: 'MoolSocial Trade',
    publisherType: 'MoolSocial-owned funded task',
    posterType: WorkOpportunityPosterType.moolSocial,
    title: 'Manufacturer Onboarding Specialist',
    summary:
        'Use local industrial contacts to onboard verified manufacturers and their catalogue owners.',
    qualificationHeadline: 'B2B field network and manufacturer contacts',
    kind: 'Freelance onboarding',
    location: 'Boranada, Jodhpur · 342012',
    city: 'Jodhpur',
    area: 'Boranada',
    pincode: '342012',
    capacity: '12 funded onboardings',
    peopleNeeded: 12,
    peopleJoined: 3,
    applicationsInProgress: 4,
    finalDeadline: '10 Sep 2026',
    paymentAmount: '₹900 per verified manufacturer',
    monthlyPayment: 'Up to ₹10,800 monthly for 12 verified onboardings',
    assignmentPayment: '₹900 per approved onboarding',
    payout: 'Within 2 working days',
    requiredWork: 'Manufacturer acquisition freelancer',
    deadline: 'Open while 12 funded onboardings remain',
    fundingNote: 'Funded · maximum task budget ₹10,800',
    aboutRole:
        'Bring suitable manufacturers onto MoolSocial with verified business ownership and a clear trade profile.',
    whatYoullDo: [
      'Approach suitable manufacturers through existing or new contacts.',
      'Explain trade discovery and catalogue requirements.',
      'Complete a verified, owner-approved onboarding record.',
    ],
    whoYouAre: [
      'You understand local manufacturing or distribution businesses.',
      'You can verify the decision-maker before starting onboarding.',
    ],
    niceToHave: [
      'Industrial sales, sourcing or channel-development experience.',
    ],
    whyJoin:
        'Turn your B2B network into clearly priced, independently verifiable assignments.',
    cardColorToken: WorkOpportunityCardColorToken.crimson,
    requiresWorkspace: false,
    icon: Icons.factory_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'rider-onboarding-specialist',
    publisher: 'Arjun Fleet Services',
    publisherType: 'Verified rider-owned posting',
    posterType: WorkOpportunityPosterType.rider,
    title: 'Rider Onboarding Specialist',
    summary:
        'Onboard eligible taxi, bike and bus operators and verify their operating category.',
    qualificationHeadline:
        'Transport-operator contacts across taxi, bike or bus',
    kind: 'Freelance onboarding',
    location: 'Mansarovar, Jaipur · 302020',
    city: 'Jaipur',
    area: 'Mansarovar',
    pincode: '302020',
    capacity: '25 funded onboardings',
    peopleNeeded: 25,
    peopleJoined: 10,
    applicationsInProgress: 6,
    finalDeadline: '08 Sep 2026',
    paymentAmount: '₹500 per verified operator',
    monthlyPayment: 'Up to ₹12,500 monthly for 25 verified onboardings',
    assignmentPayment: '₹500 per approved operator',
    payout: 'Within 2 working days',
    requiredWork: 'Transport onboarding freelancer',
    deadline: 'Open while 25 funded onboardings remain',
    fundingNote: 'User funded · maximum task budget ₹12,500',
    aboutRole:
        'Help a verified fleet operator build a network of eligible taxi, bike and bus operators in Jaipur.',
    whatYoullDo: [
      'Contact operators and explain the exact participation terms.',
      'Confirm their vehicle or fleet category and operating area.',
      'Submit consent-backed onboarding evidence for review.',
    ],
    whoYouAre: [
      'You already know local drivers, owners or transport unions.',
      'You can distinguish taxi, bike and bus onboarding requirements.',
    ],
    niceToHave: [
      'Fleet coordination or mobility-platform acquisition experience.',
    ],
    whyJoin:
        'Use your transport network for a bounded, funded outcome rather than an undefined sales target.',
    cardColorToken: WorkOpportunityCardColorToken.violet,
    requiresWorkspace: false,
    icon: Icons.connect_without_contact_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'doctor-onboarding-specialist',
    publisher: 'Dr Meera Health Network',
    publisherType: 'Verified doctor-owned posting',
    posterType: WorkOpportunityPosterType.doctor,
    title: 'Doctor Onboarding Specialist',
    summary:
        'Use existing professional connections to onboard verified doctors with consent.',
    qualificationHeadline:
        'Existing doctor relationships or medical-representative experience',
    kind: 'Freelance onboarding',
    location: 'Vijay Nagar, Indore · 452010',
    city: 'Indore',
    area: 'Vijay Nagar',
    pincode: '452010',
    capacity: '15 funded onboardings',
    peopleNeeded: 15,
    peopleJoined: 5,
    applicationsInProgress: 3,
    finalDeadline: '12 Sep 2026',
    paymentAmount: '₹750 per verified doctor',
    monthlyPayment: 'Up to ₹11,250 monthly for 15 verified onboardings',
    assignmentPayment: '₹750 per approved onboarding',
    payout: 'Within 3 working days',
    requiredWork: 'Healthcare onboarding freelancer',
    deadline: 'Open while 15 funded onboardings remain',
    fundingNote: 'Doctor funded · maximum task budget ₹11,250',
    aboutRole:
        'Support a verified doctor network by introducing eligible clinicians and completing consent-based profile onboarding.',
    whatYoullDo: [
      'Contact doctors through legitimate professional relationships.',
      'Explain profile visibility and verification requirements.',
      'Submit only consented and verifiable onboarding records.',
    ],
    whoYouAre: [
      'You have active connections with doctors or clinics.',
      'You understand professional boundaries and consent.',
    ],
    niceToHave: [
      'Medical representative or healthcare partnership experience.',
    ],
    whyJoin:
        'Apply your trusted healthcare network to a transparent, per-outcome assignment.',
    cardColorToken: WorkOpportunityCardColorToken.teal,
    requiresWorkspace: false,
    icon: Icons.medical_services_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'sales-specialist',
    publisher: 'MoolSocial Commerce',
    publisherType: 'MoolSocial-owned funded task',
    posterType: WorkOpportunityPosterType.moolSocial,
    title: 'MoolSocial Area Sales Specialist',
    summary:
        'Promote selected MoolSocial products and close in-app orders in an assigned area.',
    qualificationHeadline: 'Field sales record and local buyer relationships',
    kind: 'Freelance sales',
    location: 'Kothrud, Pune · 411038',
    city: 'Pune',
    area: 'Kothrud',
    pincode: '411038',
    capacity: '4 monthly assignments',
    peopleNeeded: 4,
    peopleJoined: 1,
    applicationsInProgress: 1,
    finalDeadline: '15 Sep 2026',
    paymentAmount: '₹24,000 monthly assignment',
    monthlyPayment: '₹24,000 per month',
    hourlyPayment: '₹150 equivalent per active hour',
    payout: 'Monthly after verified activity',
    requiredWork: 'Area sales freelancer',
    deadline: 'Applications close 15 September',
    fundingNote: 'Funded · 4 one-month assignments',
    aboutRole:
        'Own area-wise product promotion and verified in-app sales for a one-month freelance assignment.',
    whatYoullDo: [
      'Visit eligible buyers and demonstrate selected products.',
      'Create an area plan and record qualified follow-ups.',
      'Close attributable orders through MoolSocial.',
    ],
    whoYouAre: [
      'You have field sales experience and can work independently.',
      'You understand the Kothrud trade area and can travel locally.',
    ],
    niceToHave: ['FMCG, retail-tech or marketplace sales experience.'],
    whyJoin:
        'Own a defined territory with monthly compensation and measurable work expectations.',
    cardColorToken: WorkOpportunityCardColorToken.magenta,
    requiresWorkspace: true,
    icon: Icons.campaign_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.jobs,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'content-creator',
    publisher: 'Saanvi Home Foods',
    publisherType: 'Verified manufacturer-owned posting',
    posterType: WorkOpportunityPosterType.manufacturer,
    title: 'Content Creator',
    summary:
        'Produce two original vertical product videos from the supplied brief and product pack.',
    qualificationHeadline:
        'Strong vertical-video portfolio and editing ability',
    kind: 'Freelance content',
    location: 'Remote, India',
    city: 'India',
    area: 'Remote',
    pincode: '',
    capacity: '10 funded assignments',
    peopleNeeded: 10,
    peopleJoined: 4,
    applicationsInProgress: 2,
    finalDeadline: '11 Sep 2026',
    paymentAmount: '₹2,400 per approved assignment',
    monthlyPayment: 'Up to ₹24,000 monthly for 10 assignments',
    assignmentPayment: '₹2,400 for two approved videos',
    payout: 'Within 3 working days',
    requiredWork: 'Content creator',
    deadline: 'Open while 10 funded assignments remain',
    fundingNote: 'Manufacturer funded · product supplied',
    aboutRole:
        'Create concise product-led videos for a verified manufacturer using a supplied factual brief.',
    whatYoullDo: [
      'Plan and record two original vertical videos.',
      'Edit captions, pacing and product demonstrations to the brief.',
      'Complete one correction round when requested.',
    ],
    whoYouAre: [
      'You can show a relevant original-content portfolio.',
      'You can shoot and edit clear vertical video independently.',
    ],
    niceToHave: ['Hindi or regional-language presentation skills.'],
    whyJoin:
        'Receive the product and acceptance criteria before producing a funded assignment.',
    cardColorToken: WorkOpportunityCardColorToken.indigo,
    requiresWorkspace: false,
    icon: Icons.video_camera_front_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.campaigns,
    },
  ),
  WorkOpportunity(
    id: 'social-content-creator',
    publisher: 'Kavya Sharma',
    publisherType: 'Verified social-user-owned posting',
    posterType: WorkOpportunityPosterType.socialUser,
    title: 'Social Content Creator',
    summary:
        'Create a local-language social story and three short edits for a funded community campaign.',
    qualificationHeadline:
        'Original storytelling and public social-content portfolio',
    kind: 'Freelance social content',
    location: 'Vaishali Nagar, Jaipur · 302021',
    city: 'Jaipur',
    area: 'Vaishali Nagar',
    pincode: '302021',
    capacity: '8 funded assignments',
    peopleNeeded: 8,
    peopleJoined: 3,
    applicationsInProgress: 2,
    finalDeadline: '09 Sep 2026',
    paymentAmount: '₹1,800 per approved assignment',
    monthlyPayment: 'Up to ₹14,400 monthly for 8 assignments',
    assignmentPayment: '₹1,800 for one story and three edits',
    payout: 'Within 3 working days',
    requiredWork: 'Social content creator',
    deadline: 'Open while 8 funded assignments remain',
    fundingNote: 'User funded · disclosure required',
    aboutRole:
        'Create original social content for a verified user campaign with the deliverables and usage window stated upfront.',
    whatYoullDo: [
      'Develop one local-language story from the approved brief.',
      'Deliver three vertical edits sized for social publishing.',
      'Label sponsored content and use only cleared material.',
    ],
    whoYouAre: [
      'You publish original social content and can share a portfolio.',
      'You understand disclosure, consent and music-rights requirements.',
    ],
    niceToHave: ['A Jaipur audience or local community-reporting experience.'],
    whyJoin:
        'Take a bounded creative assignment with explicit deliverables, funding and rights expectations.',
    cardColorToken: WorkOpportunityCardColorToken.crimson,
    requiresWorkspace: false,
    icon: Icons.auto_awesome_motion_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.campaigns,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'wholesaler-onboarding-specialist',
    publisher: 'MoolSocial Trade',
    publisherType: 'MoolSocial-owned funded task',
    posterType: WorkOpportunityPosterType.moolSocial,
    title: 'Wholesaler Onboarding Specialist',
    summary:
        'Identify eligible wholesalers and complete verified, owner-approved business onboarding.',
    qualificationHeadline:
        'Wholesale-market network and B2B onboarding ability',
    kind: 'Freelance onboarding',
    location: 'Madhupura, Ahmedabad · 380004',
    city: 'Ahmedabad',
    area: 'Madhupura',
    pincode: '380004',
    capacity: '16 funded onboardings',
    peopleNeeded: 16,
    peopleJoined: 6,
    applicationsInProgress: 4,
    finalDeadline: '13 Sep 2026',
    paymentAmount: '₹700 per verified wholesaler',
    monthlyPayment: 'Up to ₹11,200 monthly for 16 verified onboardings',
    assignmentPayment: '₹700 per approved onboarding',
    payout: 'Within 2 working days',
    requiredWork: 'Wholesaler acquisition freelancer',
    deadline: 'Open while 16 funded onboardings remain',
    fundingNote: 'Funded · maximum task budget ₹11,200',
    aboutRole:
        'Grow verified wholesale supply in Ahmedabad through informed, consent-based business onboarding.',
    whatYoullDo: [
      'Identify eligible wholesalers and confirm the business owner.',
      'Explain catalogue and trade-order requirements.',
      'Submit a verified onboarding record with consent.',
    ],
    whoYouAre: [
      'You know wholesale markets and can speak with business owners.',
      'You can explain a mobile trade workflow clearly.',
    ],
    niceToHave: ['Distribution, sourcing or B2B marketplace experience.'],
    whyJoin:
        'Use your wholesale network for transparent, funded onboarding outcomes.',
    cardColorToken: WorkOpportunityCardColorToken.indigo,
    requiresWorkspace: false,
    icon: Icons.warehouse_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'taxi-operator-onboarding-specialist',
    publisher: 'Arjun Fleet Services',
    publisherType: 'Verified rider-owned posting',
    posterType: WorkOpportunityPosterType.rider,
    title: 'Taxi Operator Onboarding Specialist',
    summary:
        'Onboard owner-drivers and taxi operators with verified vehicle and operating-area details.',
    qualificationHeadline: 'Existing taxi-owner or driver network',
    kind: 'Freelance onboarding',
    location: 'Sanganer, Jaipur · 302029',
    city: 'Jaipur',
    area: 'Sanganer',
    pincode: '302029',
    capacity: '12 funded onboardings',
    peopleNeeded: 12,
    peopleJoined: 4,
    applicationsInProgress: 3,
    finalDeadline: '10 Sep 2026',
    paymentAmount: '₹550 per verified taxi operator',
    monthlyPayment: 'Up to ₹6,600 monthly for 12 verified operators',
    assignmentPayment: '₹550 per approved taxi operator',
    payout: 'Within 2 working days',
    requiredWork: 'Taxi onboarding freelancer',
    deadline: 'Open while 12 funded onboardings remain',
    fundingNote: 'Rider funded · maximum task budget ₹6,600',
    aboutRole:
        'Recruit eligible taxi operators for a verified fleet owner in one defined Jaipur service area.',
    whatYoullDo: [
      'Contact owner-drivers and explain the exact participation terms.',
      'Verify taxi category, documents and operating area.',
      'Submit consent-backed onboarding evidence.',
    ],
    whoYouAre: [
      'You have active connections with taxi owners or drivers.',
      'You can verify documents without retaining private copies.',
    ],
    niceToHave: ['Taxi union, fleet desk or mobility-platform experience.'],
    whyJoin: 'Earn per verified taxi operator through a funded local task.',
    cardColorToken: WorkOpportunityCardColorToken.amber,
    requiresWorkspace: false,
    icon: Icons.local_taxi_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'bike-rider-onboarding-specialist',
    publisher: 'Imran Khan',
    publisherType: 'Verified rider-owned posting',
    posterType: WorkOpportunityPosterType.rider,
    title: 'Bike Rider Onboarding Specialist',
    summary:
        'Find eligible bike riders and complete licence, vehicle and service-area verification.',
    qualificationHeadline: 'Bike-rider network and local route knowledge',
    kind: 'Freelance onboarding',
    location: 'Talwandi, Kota · 324005',
    city: 'Kota',
    area: 'Talwandi',
    pincode: '324005',
    capacity: '20 funded onboardings',
    peopleNeeded: 20,
    peopleJoined: 7,
    applicationsInProgress: 5,
    finalDeadline: '14 Sep 2026',
    paymentAmount: '₹300 per verified bike rider',
    monthlyPayment: 'Up to ₹6,000 monthly for 20 verified riders',
    assignmentPayment: '₹300 per approved bike rider',
    payout: 'T+1 after verification',
    requiredWork: 'Bike-rider onboarding freelancer',
    deadline: 'Open while 20 funded onboardings remain',
    fundingNote: 'Rider funded · maximum task budget ₹6,000',
    aboutRole:
        'Help a verified rider create a local pool of eligible bike riders for defined route work.',
    whatYoullDo: [
      'Introduce the opportunity and its terms accurately.',
      'Confirm licence, bike and preferred operating area.',
      'Submit each rider only after consent.',
    ],
    whoYouAre: [
      'You know active bike riders in Kota.',
      'You can use the onboarding and verification flow reliably.',
    ],
    niceToHave: ['Delivery or two-wheeler community coordination experience.'],
    whyJoin: 'Turn local rider connections into verified, funded outcomes.',
    cardColorToken: WorkOpportunityCardColorToken.cobalt,
    requiresWorkspace: false,
    icon: Icons.two_wheeler_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'bus-operator-onboarding-specialist',
    publisher: 'Rajasthan Route Partners',
    publisherType: 'Verified other-user-owned posting',
    posterType: WorkOpportunityPosterType.other,
    title: 'Bus Operator Onboarding Specialist',
    summary:
        'Onboard verified private bus operators with route, fleet and authorized-contact details.',
    qualificationHeadline:
        'Bus-operator network and transport-business knowledge',
    kind: 'Freelance onboarding',
    location: 'Surajpole, Udaipur · 313001',
    city: 'Udaipur',
    area: 'Surajpole',
    pincode: '313001',
    capacity: '8 funded onboardings',
    peopleNeeded: 8,
    peopleJoined: 2,
    applicationsInProgress: 2,
    finalDeadline: '16 Sep 2026',
    paymentAmount: '₹1,200 per verified bus operator',
    monthlyPayment: 'Up to ₹9,600 monthly for 8 verified operators',
    assignmentPayment: '₹1,200 per approved bus operator',
    payout: 'Within 3 working days',
    requiredWork: 'Bus-operator onboarding freelancer',
    deadline: 'Open while 8 funded onboardings remain',
    fundingNote: 'User funded · maximum task budget ₹9,600',
    aboutRole:
        'Build a verified private-bus operator directory for a local route-services user.',
    whatYoullDo: [
      'Contact an authorized operator representative.',
      'Confirm routes, fleet category and business authority.',
      'Complete consent-based onboarding for review.',
    ],
    whoYouAre: [
      'You know private bus owners, agents or operator offices.',
      'You can check business authority and route information.',
    ],
    niceToHave: ['Bus booking, tourism or transport-agency experience.'],
    whyJoin: 'Earn against a small, defined set of high-value onboardings.',
    cardColorToken: WorkOpportunityCardColorToken.crimson,
    requiresWorkspace: false,
    icon: Icons.directions_bus_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'wholesale-sales-specialist',
    publisher: 'Surat Textile Distribution',
    publisherType: 'Verified wholesaler-owned posting',
    posterType: WorkOpportunityPosterType.wholesaler,
    title: 'Wholesale Sales Specialist',
    summary:
        'Promote a defined textile catalogue and close attributable retailer orders in-app.',
    qualificationHeadline: 'Wholesale textile sales and retailer relationships',
    kind: 'Freelance sales',
    location: 'Ring Road, Surat · 395002',
    city: 'Surat',
    area: 'Ring Road',
    pincode: '395002',
    capacity: '15 funded orders',
    peopleNeeded: 15,
    peopleJoined: 5,
    applicationsInProgress: 4,
    finalDeadline: '12 Sep 2026',
    paymentAmount: '₹500 per verified wholesale order',
    monthlyPayment: 'Up to ₹7,500 monthly for 15 verified orders',
    assignmentPayment: '₹500 per paid, non-refunded order',
    payout: 'T+2 after the refund window',
    requiredWork: 'Wholesale sales freelancer',
    deadline: 'Open while 15 funded orders remain',
    fundingNote: 'Wholesaler funded · maximum task budget ₹7,500',
    aboutRole:
        'Sell a verified wholesaler catalogue to eligible retailers using attributable in-app orders.',
    whatYoullDo: [
      'Present the exact catalogue, pack and price terms.',
      'Qualify retailer demand and answer product questions.',
      'Close trackable orders without off-platform payment.',
    ],
    whoYouAre: [
      'You have wholesale textile selling experience.',
      'You maintain trusted retailer relationships.',
    ],
    niceToHave: ['Existing Surat textile-market accounts.'],
    whyJoin: 'Sell a funded catalogue with transparent per-order earnings.',
    cardColorToken: WorkOpportunityCardColorToken.magenta,
    requiresWorkspace: true,
    icon: Icons.sell_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
  WorkOpportunity(
    id: 'bulk-sales-specialist',
    publisher: 'RajTex Manufacturing',
    publisherType: 'Verified manufacturer-owned posting',
    posterType: WorkOpportunityPosterType.manufacturer,
    title: 'Bulk Sales Specialist',
    summary:
        'Find institutional buyers and close funded bulk orders for a defined manufacturer range.',
    qualificationHeadline: 'Institutional or bulk-selling track record',
    kind: 'Freelance sales',
    location: 'Boranada, Jodhpur · 342012',
    city: 'Jodhpur',
    area: 'Boranada',
    pincode: '342012',
    capacity: '10 funded bulk orders',
    peopleNeeded: 10,
    peopleJoined: 4,
    applicationsInProgress: 2,
    finalDeadline: '11 Sep 2026',
    paymentAmount: '₹1,000 per verified bulk order',
    monthlyPayment: 'Up to ₹10,000 monthly for 10 verified orders',
    assignmentPayment: '₹1,000 per paid, non-refunded order',
    payout: 'T+3 after the refund window',
    requiredWork: 'Bulk sales freelancer',
    deadline: 'Open while 10 funded orders remain',
    fundingNote: 'Manufacturer funded · maximum task budget ₹10,000',
    aboutRole:
        'Develop institutional demand and close eligible high-volume orders for a verified manufacturer.',
    whatYoullDo: [
      'Identify buyers whose requirements match the defined range.',
      'Explain quantity, lead-time and payment terms accurately.',
      'Close attributable bulk orders through MoolSocial.',
    ],
    whoYouAre: [
      'You have proven wholesale, institutional or bulk-selling experience.',
      'You can manage longer B2B buying conversations.',
    ],
    niceToHave: [
      'Hospitality, institutional procurement or distributor contacts.',
    ],
    whyJoin: 'Earn a clear amount for each accepted and settled bulk order.',
    cardColorToken: WorkOpportunityCardColorToken.emerald,
    requiresWorkspace: true,
    icon: Icons.inventory_outlined,
    filters: {
      WorkFeedFilter.forYou,
      WorkFeedFilter.freelance,
      WorkFeedFilter.nearby,
    },
  ),
];

const workTerms = <WorkTerm>[
  WorkTerm(
    id: 'payment',
    title: 'Payment and payout',
    detail:
        'Use the selected opportunity’s funded amount, monthly earning basis, optional hourly or assignment rate, and payout timing.',
  ),
  WorkTerm(
    id: 'publisher',
    title: 'What the publisher provides',
    detail:
        'The selected opportunity states whether MoolSocial or a verified user posted and funded the requirement.',
  ),
  WorkTerm(
    id: 'review',
    title: 'Review, correction and rejection',
    detail:
        'Acceptance follows the selected opportunity’s stated work and qualification requirements. A failed action remains retryable without changing application identity.',
  ),
  WorkTerm(
    id: 'rights',
    title: 'Content use and rights',
    detail:
        'Any content-specific usage, disclosure and rights requirements must be stated in the selected opportunity before application.',
  ),
];

const workProfiles = <WorkProfileOption>[
  WorkProfileOption(
    id: 'retailer-grocery',
    familyId: 'products-trade',
    familyLabel: 'Products & Trade',
    label: 'Grocery / Kirana Shop',
    gstMatchCategory: WorkGstMatchCategory.retailGoodsSupplier,
    sellSide:
        'Grow a trusted neighbourhood store and serve more local customers.',
    buySide: 'Source verified wholesale packs from eligible suppliers.',
    tools: 'Run catalogue, stock, orders, delivery and business records.',
    icon: Icons.storefront_rounded,
  ),
  WorkProfileOption(
    id: 'retailer-speciality',
    familyId: 'products-trade',
    familyLabel: 'Products & Trade',
    label: 'Speciality Retail Shop',
    gstMatchCategory: WorkGstMatchCategory.retailGoodsSupplier,
    sellSide:
        'Showcase specialist products to customers searching by category.',
    buySide:
        'Build reliable supplier relationships and source with confidence.',
    tools: 'Manage catalogue, inventory, orders, invoices and fulfilment.',
    icon: Icons.shopping_bag_outlined,
  ),
  WorkProfileOption(
    id: 'wholesaler',
    familyId: 'products-trade',
    familyLabel: 'Products & Trade',
    label: 'Wholesaler / Distributor',
    gstMatchCategory: WorkGstMatchCategory.wholesaleDistributor,
    sellSide:
        'Reach verified retailers with clear case packs, pricing and trade terms.',
    buySide: 'Connect with manufacturers and strengthen your sourcing network.',
    tools: 'Manage business orders, buyer terms, credit and dispatch.',
    icon: Icons.warehouse_outlined,
  ),
  WorkProfileOption(
    id: 'manufacturer',
    familyId: 'products-trade',
    familyLabel: 'Products & Trade',
    label: 'Manufacturer / Supplier',
    gstMatchCategory: WorkGstMatchCategory.manufacturerSupplier,
    sellSide:
        'Expand distribution by reaching eligible retailers and wholesalers.',
    buySide: 'Source business materials and specialist services.',
    tools: 'Track sales opportunities, distribution partners and fulfilment.',
    icon: Icons.factory_outlined,
  ),
  WorkProfileOption(
    id: 'restaurant',
    familyId: 'food-business',
    familyLabel: 'Food Business',
    label: 'Restaurant / Café',
    gstMatchCategory: WorkGstMatchCategory.foodServiceProvider,
    sellSide:
        'Welcome more diners through delivery, pickup and table bookings.',
    buySide: 'Source ingredients, packaging and operating supplies.',
    tools: 'Run menus, kitchen flow, orders, tables and customer service.',
    icon: Icons.restaurant_rounded,
  ),
  WorkProfileOption(
    id: 'cloud-kitchen',
    familyId: 'food-business',
    familyLabel: 'Food Business',
    label: 'Cloud Kitchen / Tiffin',
    gstMatchCategory: WorkGstMatchCategory.foodServiceProvider,
    sellSide: 'Grow meal orders, tiffin plans and recurring subscriptions.',
    buySide: 'Source ingredients and packaging from suitable suppliers.',
    tools: 'Manage menus, meal plans, kitchen flow and delivery.',
    icon: Icons.soup_kitchen_outlined,
  ),
  WorkProfileOption(
    id: 'clinic',
    familyId: 'health',
    familyLabel: 'Health & Medicine',
    label: 'Clinic / Doctor',
    gstMatchCategory: WorkGstMatchCategory.healthcareProvider,
    sellSide:
        'Build a trusted patient presence and offer verified appointments.',
    buySide: 'Organise eligible clinic and professional supplies.',
    tools: 'Manage availability, consent, appointments and follow-up.',
    icon: Icons.medical_services_outlined,
  ),
  WorkProfileOption(
    id: 'pharmacy',
    familyId: 'health',
    familyLabel: 'Health & Medicine',
    label: 'Pharmacy',
    gstMatchCategory: WorkGstMatchCategory.pharmacySupplier,
    sellSide: 'Serve eligible medicine orders with licensed fulfilment.',
    buySide: 'Source medicines and products from licensed suppliers.',
    tools: 'Manage prescription review, compliant stock and orders.',
    icon: Icons.local_pharmacy_outlined,
  ),
  WorkProfileOption(
    id: 'salon',
    familyId: 'services',
    familyLabel: 'Services & Salon',
    label: 'Salon / Wellness',
    gstMatchCategory: WorkGstMatchCategory.personalCareProvider,
    sellSide:
        'Attract repeat customers with appointments, services and packages.',
    buySide: 'Source professional products for your team and customers.',
    tools: 'Manage schedules, staff, billing and repeat visits.',
    icon: Icons.content_cut_rounded,
  ),
  WorkProfileOption(
    id: 'travel-bike-provider',
    familyId: 'travel',
    familyLabel: 'Travel Partners',
    label: 'Bike Travel Provider',
    gstMatchCategory: WorkGstMatchCategory.bikeTravelProvider,
    sellSide: 'Offer eligible passenger bike trips in your operating area.',
    buySide: 'Find bike care and operating services.',
    tools: 'Manage trip availability, safety, documents and earnings.',
    icon: Icons.two_wheeler_rounded,
  ),
  WorkProfileOption(
    id: 'travel-auto-provider',
    familyId: 'travel',
    familyLabel: 'Travel Partners',
    label: 'Auto Travel Provider',
    gstMatchCategory: WorkGstMatchCategory.autoTravelProvider,
    sellSide: 'Offer eligible auto trips in your operating area.',
    buySide: 'Find auto care and operating services.',
    tools: 'Manage trip availability, safety, documents and earnings.',
    icon: Icons.electric_rickshaw_outlined,
  ),
  WorkProfileOption(
    id: 'travel-cab-provider',
    familyId: 'travel',
    familyLabel: 'Travel Partners',
    label: 'Cab Travel Provider',
    gstMatchCategory: WorkGstMatchCategory.cabTravelProvider,
    sellSide: 'Offer eligible cab trips in your operating area.',
    buySide: 'Find cab care and operating services.',
    tools: 'Manage trip availability, safety, documents and earnings.',
    icon: Icons.local_taxi_outlined,
  ),
  WorkProfileOption(
    id: 'travel-bus-provider',
    familyId: 'travel',
    familyLabel: 'Travel Partners',
    label: 'Bus Travel Provider',
    gstMatchCategory: WorkGstMatchCategory.busTravelProvider,
    sellSide: 'Offer eligible passenger bus routes and service capacity.',
    buySide: 'Find route and fleet operating services.',
    tools: 'Manage buses, drivers, routes, safety and settlements.',
    icon: Icons.directions_bus_outlined,
  ),
  WorkProfileOption(
    id: 'quick-delivery-biker',
    familyId: 'delivery',
    familyLabel: 'Delivery & Logistics',
    label: 'Quick Delivery Biker',
    gstMatchCategory: WorkGstMatchCategory.quickDeliveryBiker,
    sellSide: 'Accept eligible local quick-delivery assignments.',
    buySide: 'Find bike care and delivery operating services.',
    tools: 'Manage delivery availability, routes, proof and earnings.',
    icon: Icons.delivery_dining_outlined,
  ),
  WorkProfileOption(
    id: 'wholesale-fleet-delivery',
    familyId: 'delivery',
    familyLabel: 'Delivery & Logistics',
    label: 'Wholesale Fleet Delivery',
    gstMatchCategory: WorkGstMatchCategory.wholesaleFleetDelivery,
    sellSide: 'Offer verified fleet capacity for wholesale deliveries.',
    buySide: 'Find suitable wholesale routes and operating services.',
    tools: 'Manage vehicles, drivers, wholesale routes and settlements.',
    icon: Icons.local_shipping_outlined,
  ),
  WorkProfileOption(
    id: 'bulk-delivery-fleet',
    familyId: 'delivery',
    familyLabel: 'Delivery & Logistics',
    label: 'Bulk Delivery Fleet',
    gstMatchCategory: WorkGstMatchCategory.bulkDeliveryFleet,
    sellSide: 'Offer verified vehicle capacity for bulk deliveries.',
    buySide: 'Find suitable bulk routes and operating services.',
    tools: 'Manage vehicles, drivers, bulk routes and settlements.',
    icon: Icons.local_shipping_outlined,
  ),
  WorkProfileOption(
    id: 'creator',
    familyId: 'create-work',
    familyLabel: 'Create & Work',
    label: 'Creator',
    gstMatchCategory: WorkGstMatchCategory.digitalContentProvider,
    sellSide: 'Turn your audience and skills into paid brand opportunities.',
    buySide: 'Find professional tools and creator support.',
    tools: 'Manage channels, campaigns, deliverables and earnings.',
    icon: Icons.video_camera_front_outlined,
  ),
  WorkProfileOption(
    id: 'freelancer',
    familyId: 'create-work',
    familyLabel: 'Create & Work',
    label: 'Freelancer / Job Seeker',
    gstMatchCategory: WorkGstMatchCategory.independentProfessional,
    sellSide: 'Showcase your skills and pursue paid assignments and roles.',
    buySide: 'Access professional services that support your work.',
    tools: 'Manage applications, portfolio documents, payouts and profile.',
    icon: Icons.work_outline_rounded,
  ),
];

const workProofs = <WorkProofRequirement>[
  WorkProofRequirement(
    id: 'personal-kyc',
    label: 'Personal identity',
    detail: 'Signed-in account identity · included with this application',
    importance: WorkDocumentImportance.required,
  ),
  WorkProofRequirement(
    id: 'shop-front',
    label: 'Shop or workplace document',
    detail: 'A clear current document showing the work name or location',
    importance: WorkDocumentImportance.required,
  ),
  WorkProofRequirement(
    id: 'owner-authority',
    label: 'Owner or operator authority',
    detail: 'Registration, licence, bill or authorization showing your link',
    importance: WorkDocumentImportance.required,
  ),
  WorkProofRequirement(
    id: 'gst',
    label: 'GST certificate',
    detail: 'Required when GST registration applies to this Workspace',
    importance: WorkDocumentImportance.ifApplicable,
  ),
];
