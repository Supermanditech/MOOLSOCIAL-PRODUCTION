import 'dart:async';

import 'package:flutter/foundation.dart';

import 'buy_session.dart';
import 'buy_v2_cart_contracts.dart';
import 'buy_v2_content_contracts.dart';
import 'buy_v2_models.dart';
import 'buy_v2_search_relevance.dart';
import 'buy_v2_saved_products_store.dart';

String _buyV2SavedKey(BuyV2Product product) =>
    '${product.destination.name}|${product.canonicalId}';

@immutable
class _BuyV2CartBenefitSelectionRef {
  const _BuyV2CartBenefitSelectionRef({
    required this.benefitId,
    required this.sourceId,
  });

  final String benefitId;
  final String sourceId;
}

@immutable
class _BuyV2DeliveryPromiseQuote {
  const _BuyV2DeliveryPromiseQuote({
    required this.promise,
    this.promisedByLabel,
  });

  final String promise;
  final String? promisedByLabel;

  @override
  bool operator ==(Object other) =>
      other is _BuyV2DeliveryPromiseQuote &&
      other.promise == promise &&
      other.promisedByLabel == promisedByLabel;

  @override
  int get hashCode => Object.hash(promise, promisedByLabel);
}

typedef BuyV2DeliveryPromiseChange = ({
  String groupKey,
  String previousPromise,
  String? previousPromisedByLabel,
  String currentPromise,
  String? currentPromisedByLabel,
});

typedef BuyV2PriceChange = ({
  String productId,
  String title,
  int previousPrice,
  int currentPrice,
});

typedef BuyV2CheckoutAvailabilityIssue = ({
  String productId,
  String title,
  String orderabilityLabel,
});

typedef _BuyV2NavigationSurfaceIdentity = ({
  BuyV2Destination destination,
  BuyV2View view,
  String? detail,
});

typedef _BuyV2RecoveryOrigin = ({
  BuyV2Destination destination,
  BuyV2View view,
  BuyV2CartScope cartScope,
  BuyV2CartScope checkoutScope,
  BuyV2OrdersTab ordersTab,
  String shopCategoryId,
  String wholesaleCategoryId,
  String medicineCategoryId,
  String query,
  String? filter,
  String? productId,
  String? orderId,
});

enum BuyV2CheckoutSubmissionState {
  idle,
  submitting,
  paymentActionRequired,
  paymentPending,
  paymentUnknown,
  cancelled,
  confirmed,
  failed,
  unavailable,
}

final class _BuyV2UnavailableCommerceAdapter implements BuyV2CommerceAdapter {
  const _BuyV2UnavailableCommerceAdapter();

  static const _unavailable =
      'Shop is unavailable right now. Try again shortly.';

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => const BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.unavailable,
    customerMessage: _unavailable,
  );

  @override
  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  ) async => const BuyV2OrderPlacementResult(
    outcome: BuyV2OrderPlacementOutcome.unavailable,
    customerMessage:
        'Ordering is unavailable right now. Your Cart has not changed.',
  );

  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  }) async => const BuyV2OrderPlacementResult(
    outcome: BuyV2OrderPlacementOutcome.unavailable,
    customerMessage:
        'Payment status is unavailable right now. Do not pay again.',
  );

  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({
    required String orderId,
  }) async => const BuyV2OrderRefreshResult(
    state: BuyV2CommerceLoadState.unavailable,
    customerMessage: 'Order updates are unavailable right now.',
  );

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: false,
        enabled: false,
        customerMessage: 'Order alerts are unavailable right now.',
      );

  @override
  Future<BuyV2OrderAlertsResult> setOrderAlerts({
    required bool enabled,
  }) async => const BuyV2OrderAlertsResult(
    available: false,
    enabled: false,
    customerMessage: 'Order alerts are unavailable right now.',
  );

  @override
  Future<BuyV2MutationResult> submitProductReview({
    required BuyV2Product product,
    required int rating,
    required String comment,
  }) async => const BuyV2MutationResult(
    accepted: false,
    customerMessage: 'Reviews are unavailable right now. Try again later.',
  );

  @override
  Future<BuyV2MutationResult> reportProduct({
    required BuyV2Product product,
    required String reason,
  }) async => const BuyV2MutationResult(
    accepted: false,
    customerMessage:
        'Product reporting is unavailable right now. Try again later.',
  );

  @override
  Future<BuyV2AddressRequestResult> createAddressRequest({
    String recipient = '',
  }) async => const BuyV2AddressRequestResult(
    customerMessage:
        'Address requests are unavailable right now. Enter the address yourself.',
  );
}

final class _BuyV2DeviceReviewCommerceAdapter implements BuyV2CommerceAdapter {
  const _BuyV2DeviceReviewCommerceAdapter();

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: BuyV2Catalogue.products,
    paymentMethods: BuyV2Session.paymentMethods,
    businessVerified: true,
    businessVerificationState: BuyV2BusinessVerificationState.verified,
    productReportsAvailable: true,
    reviewableProductIds: BuyV2Catalogue.products
        .map((product) => product.id)
        .toSet(),
  );

  @override
  Future<BuyV2OrderPlacementResult> placeOrder(
    BuyV2OrderPlacementRequest request,
  ) async {
    final reference =
        'BT-${DateTime.now().microsecondsSinceEpoch.toString().substring(8)}';
    if (request.paymentMethod == 'Bank transfer') {
      return BuyV2OrderPlacementResult(
        outcome: BuyV2OrderPlacementOutcome.paymentActionRequired,
        customerMessage:
            'Transfer the exact amount once, then return here to check it.',
        paymentReference: reference,
        bankTransferInstructions: BuyV2BankTransferInstructions(
          beneficiaryName: 'MoolSocial Shop Payments',
          bankName: 'MoolSocial Payments Bank',
          accountNumber: '000000004821',
          ifsc: 'MOOL0000482',
          transferReference: reference,
        ),
      );
    }
    return BuyV2OrderPlacementResult(
      outcome: BuyV2OrderPlacementOutcome.confirmed,
      customerMessage: 'Your order is confirmed.',
      purchaseReference:
          'MS-${DateTime.now().microsecondsSinceEpoch.toString().substring(8)}',
    );
  }

  @override
  Future<BuyV2OrderPlacementResult> reconcileOrder({
    required String idempotencyKey,
    required String paymentReference,
  }) async => BuyV2OrderPlacementResult(
    outcome: BuyV2OrderPlacementOutcome.paymentPending,
    customerMessage:
        'Your transfer is still being checked. Do not transfer again.',
    paymentReference: paymentReference,
  );

  @override
  Future<BuyV2OrderRefreshResult> refreshOrder({
    required String orderId,
  }) async => const BuyV2OrderRefreshResult(
    state: BuyV2CommerceLoadState.unavailable,
    customerMessage: 'Order updates are unavailable right now.',
  );

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: true,
        enabled: true,
        customerMessage: 'Order alerts are on.',
      );

  @override
  Future<BuyV2OrderAlertsResult> setOrderAlerts({
    required bool enabled,
  }) async => BuyV2OrderAlertsResult(
    available: true,
    enabled: enabled,
    customerMessage: enabled
        ? 'Order alerts are on.'
        : 'Order alerts are paused.',
  );

  @override
  Future<BuyV2MutationResult> submitProductReview({
    required BuyV2Product product,
    required int rating,
    required String comment,
  }) async => const BuyV2MutationResult(
    accepted: true,
    customerMessage: 'Your review was added.',
  );

  @override
  Future<BuyV2MutationResult> reportProduct({
    required BuyV2Product product,
    required String reason,
  }) async => const BuyV2MutationResult(
    accepted: true,
    customerMessage: 'Report received. We will review the product details.',
  );

  @override
  Future<BuyV2AddressRequestResult> createAddressRequest({
    String recipient = '',
  }) async => BuyV2AddressRequestResult(
    shareUri: Uri.parse('https://moolsocial.com/address/request'),
    customerMessage: 'Choose an app to send the address request.',
  );
}

final class _BuyV2DeviceReviewGstInvoiceProfileStore
    implements BuyV2GstInvoiceProfileStore {
  BuyV2GstInvoiceProfileSnapshot? _snapshot;

  @override
  String? get ownerScope => 'device-review-session:buy-gst';

  @override
  Future<BuyV2GstInvoiceProfileSnapshot?> read() async => _snapshot;

  @override
  Future<bool> write(BuyV2GstInvoiceProfileSnapshot snapshot) async {
    _snapshot = snapshot;
    return true;
  }
}

class BuyV2Session extends ChangeNotifier {
  BuyV2Session({
    required this.core,
    this.productFactsAdapter = const BuyV2CatalogueProductFactsAdapter(),
    this.sponsoredContentAdapter = const BuyV2DisabledSponsoredContentAdapter(),
    BuyV2CartBenefitsAdapter? cartBenefitsAdapter,
    this.tipPolicy = const BuyV2DisabledTipPolicy(),
    this.savedProductsStore,
    this.customerStateStore,
    BuyV2GstInvoiceProfileStore? gstInvoiceProfileStore,
    this.commercialPaymentTermsAdapter,
    this.checkoutQuoteAdapter,
    this.balancePaymentAdapter,
    this.deliveryExceptionAdapter,
    BuyV2CommerceAdapter? commerceAdapter,
    bool? reviewDataEnabled,
  }) : cartBenefitsAdapter =
           cartBenefitsAdapter ??
           (buyV2DeviceReviewBenefitSeedsEnabled
               ? const BuyV2SeededCartBenefitsAdapter()
               : const BuyV2DisabledCartBenefitsAdapter()),
       reviewDataEnabled =
           reviewDataEnabled ??
           (kDebugMode || buyV2DeviceReviewBenefitSeedsEnabled),
       gstInvoiceProfileStore =
           gstInvoiceProfileStore ??
           ((reviewDataEnabled ??
                   (kDebugMode || buyV2DeviceReviewBenefitSeedsEnabled))
               ? _BuyV2DeviceReviewGstInvoiceProfileStore()
               : null),
       commerceAdapter =
           commerceAdapter ??
           ((reviewDataEnabled ??
                   (kDebugMode || buyV2DeviceReviewBenefitSeedsEnabled))
               ? const _BuyV2DeviceReviewCommerceAdapter()
               : const _BuyV2UnavailableCommerceAdapter()) {
    if (cartBenefitsAdapter is BuyV2LiveCartBenefitsAdapter) {
      cartBenefitsLoadState = BuyV2CartBenefitsLoadState.idle;
    }
    _catalogueProducts.addAll(BuyV2Catalogue.products);
    if (this.reviewDataEnabled) {
      _businessVerificationState = BuyV2BusinessVerificationState.verified;
      _productReportsAvailable = true;
      _reviewableProductIds.addAll(
        BuyV2Catalogue.products.map((product) => product.id),
      );
    }
    if (!this.reviewDataEnabled) {
      _catalogueProducts.clear();
      _addresses.clear();
      _orders.clear();
      _selectedAddressId = null;
      businessVerified = false;
      trackingAlertsEnabled = false;
      trackingAlertsAvailable = false;
      availablePaymentMethods = const {};
      commerceLoadState = BuyV2CommerceLoadState.loading;
    }
  }

  final BuySession core;
  final BuyV2ProductFactsAdapter productFactsAdapter;
  final BuyV2SponsoredContentAdapter sponsoredContentAdapter;
  final BuyV2CartBenefitsAdapter cartBenefitsAdapter;
  final BuyV2TipPolicy tipPolicy;
  final BuyV2SavedProductsStore? savedProductsStore;
  final BuyV2CustomerStateStore? customerStateStore;
  final BuyV2GstInvoiceProfileStore? gstInvoiceProfileStore;
  final BuyV2CommercialPaymentTermsAdapter? commercialPaymentTermsAdapter;
  final BuyV2CheckoutQuoteAdapter? checkoutQuoteAdapter;
  final BuyV2BalancePaymentAdapter? balancePaymentAdapter;
  final BuyV2DeliveryExceptionAdapter? deliveryExceptionAdapter;
  final BuyV2CommerceAdapter commerceAdapter;
  final bool reviewDataEnabled;

  static const bool sponsoredContentActivationApproved = false;
  static const BuyV2CatalogueProductFactsAdapter _catalogueFactsFallback =
      BuyV2CatalogueProductFactsAdapter();

  static const Set<String> paymentMethods = {
    'UPI',
    'Bank transfer',
    'Purchase order',
  };

  BuyV2CommerceLoadState commerceLoadState = BuyV2CommerceLoadState.ready;
  BuyV2CheckoutSubmissionState checkoutSubmissionState =
      BuyV2CheckoutSubmissionState.idle;
  Set<String> availablePaymentMethods = paymentMethods;
  String? commerceMessage;
  String? _checkoutIdempotencyKey;
  String? _paymentReference;
  Uri? _paymentActionUri;
  BuyV2BankTransferInstructions? _bankTransferInstructions;
  int _checkoutAttemptSequence = 0;

  String? get checkoutIdempotencyKey => _checkoutIdempotencyKey;
  String? get paymentReference => _paymentReference;
  Uri? get paymentActionUri => _paymentActionUri;
  BuyV2BankTransferInstructions? get bankTransferInstructions =>
      _bankTransferInstructions;

  bool get catalogueAvailable =>
      commerceLoadState == BuyV2CommerceLoadState.ready;

  bool canReviewProduct(String productId) =>
      _reviewableProductIds.contains(productId);

  bool canReportProduct(String productId) =>
      findProduct(productId) != null && _productReportsAvailable;

  bool productFeedbackBusy(String productId) =>
      _productFeedbackBusyIds.contains(productId);

  bool get addressRequestsAvailable => reviewDataEnabled;

  bool get checkoutBusy =>
      checkoutSubmissionState == BuyV2CheckoutSubmissionState.submitting;

  bool get checkoutRequiresResolution =>
      checkoutSubmissionState ==
          BuyV2CheckoutSubmissionState.paymentActionRequired ||
      checkoutSubmissionState == BuyV2CheckoutSubmissionState.paymentPending ||
      checkoutSubmissionState == BuyV2CheckoutSubmissionState.paymentUnknown;

  bool get checkoutBenefitReviewRequired =>
      liveCartBenefitsEnabled &&
      _hasSelectedCartBenefitReference &&
      cartBenefitsLoadState != BuyV2CartBenefitsLoadState.ready;

  BuyV2Destination destination = BuyV2Destination.shop;
  BuyV2View view = BuyV2View.catalogue;
  BuyV2CartScope cartScope = BuyV2CartScope.all;
  BuyV2CartScope checkoutScope = BuyV2CartScope.all;
  BuyV2OrdersTab ordersTab = BuyV2OrdersTab.active;
  String shopCategoryId = 'all';
  String wholesaleCategoryId = 'all';
  String medicineCategoryId = 'all';
  String query = '';
  String? selectedProductId;
  String? pendingPrescriptionProductId;
  BuyV2RecoveryKind? recoveryKind;
  _BuyV2RecoveryOrigin? _recoveryOrigin;
  String? notice;
  String? cartAcknowledgement;
  String? selectedFilter;
  BuyV2ShoppingIntent? activeShoppingIntent;
  bool businessVerified = true;
  BuyV2BusinessVerificationState _businessVerificationState =
      BuyV2BusinessVerificationState.unavailable;
  BuyV2BusinessVerificationState get businessVerificationState {
    if (businessVerified) return BuyV2BusinessVerificationState.verified;
    return _businessVerificationState == BuyV2BusinessVerificationState.verified
        ? BuyV2BusinessVerificationState.unavailable
        : _businessVerificationState;
  }

  bool prescriptionAttached = false;
  bool trackingAlertsEnabled = true;
  bool trackingAlertsAvailable = true;
  bool trackingAlertsBusy = false;
  String selectedPayment = 'UPI';

  bool get purchaseOrderEligibleForCheckout {
    final lines = checkoutLines;
    return businessVerified &&
        lines.isNotEmpty &&
        lines.every(
          (line) => line.product.destination == BuyV2Destination.wholesale,
        );
  }

  static const purchaseOrderEligibilityMessage =
      'Purchase order requires a verified business Workspace and a wholesale-only basket.';

  int _navigationMotionSequence = 0;
  BuyV2NavigationMotionDirection _navigationMotionDirection =
      BuyV2NavigationMotionDirection.replace;
  bool _handlingBackNavigation = false;

  int get navigationMotionSequence => _navigationMotionSequence;
  BuyV2NavigationMotionDirection get navigationMotionDirection =>
      _navigationMotionDirection;

  BuyV2Destination get activeDockDestination => switch (view) {
    BuyV2View.cart => _dockDestinationForScope(cartScope),
    BuyV2View.checkout => _dockDestinationForScope(checkoutScope),
    _ => destination,
  };

  BuyV2Destination _dockDestinationForScope(BuyV2CartScope scope) =>
      switch (scope) {
        BuyV2CartScope.shop => BuyV2Destination.shop,
        BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
        BuyV2CartScope.medicine => BuyV2Destination.medicine,
        BuyV2CartScope.all => destination,
      };

  String get recoveryReturnLabel {
    final origin = _recoveryOrigin;
    if (origin == null) return 'Return to Shop';
    return switch (origin.view) {
      BuyV2View.catalogue => 'Return to ${origin.destination.label}',
      BuyV2View.product => 'Return to product',
      BuyV2View.cart => 'Return to Cart',
      BuyV2View.checkout => 'Return to Checkout',
      BuyV2View.confirmation => 'Return to confirmation',
      BuyV2View.tracking || BuyV2View.orderItems => 'Return to order',
      BuyV2View.assist => 'Return to Help',
      BuyV2View.account => 'Return to Account',
      BuyV2View.recovery => 'Return to Shop',
    };
  }

  bool get canOpenRecoveryOrderHelp {
    final origin = _recoveryOrigin;
    if (recoveryKind != BuyV2RecoveryKind.deliveryDelay || origin == null) {
      return false;
    }
    if (origin.view != BuyV2View.tracking &&
        origin.view != BuyV2View.orderItems) {
      return false;
    }
    final orderId = origin.orderId;
    return orderId != null && _orders.any((order) => order.id == orderId);
  }

  bool get canResolveCheckoutAddress =>
      recoveryKind == BuyV2RecoveryKind.serviceAreaUnavailable &&
      _recoveryOrigin?.view == BuyV2View.checkout &&
      selectedAddressOrNull != null;

  _BuyV2NavigationSurfaceIdentity get _navigationSurfaceIdentity => (
    destination: destination,
    view: view,
    detail: switch (view) {
      BuyV2View.product => selectedProductId,
      BuyV2View.tracking || BuyV2View.orderItems => _selectedOrderId,
      BuyV2View.recovery => recoveryKind?.name,
      BuyV2View.catalogue ||
      BuyV2View.cart ||
      BuyV2View.checkout ||
      BuyV2View.confirmation ||
      BuyV2View.assist ||
      BuyV2View.account => null,
    },
  );

  void _notifyNavigation(BuyV2NavigationMotionDirection direction) {
    _navigationMotionDirection = _handlingBackNavigation
        ? BuyV2NavigationMotionDirection.back
        : direction;
    _navigationMotionSequence += 1;
    notifyListeners();
  }

  void _notifyNavigationIfChanged(
    _BuyV2NavigationSurfaceIdentity previous,
    BuyV2NavigationMotionDirection direction,
  ) {
    if (previous == _navigationSurfaceIdentity) {
      notifyListeners();
    } else {
      _notifyNavigation(direction);
    }
  }

  String? _selectedOrderId;
  String? _selectedAddressId = 'home';

  BuyV2Destination _accountReturnDestination = BuyV2Destination.shop;
  BuyV2View _accountReturnView = BuyV2View.catalogue;
  String? _accountReturnProductId;
  String? _accountReturnOrderId;
  String _accountReturnQuery = '';
  String? _accountReturnFilter;
  bool _accountChildReturnActive = false;
  BuyV2Destination _assistReturnDestination = BuyV2Destination.shop;
  BuyV2View _assistReturnView = BuyV2View.catalogue;
  BuyV2Destination _productReturnDestination = BuyV2Destination.shop;
  BuyV2View _productReturnView = BuyV2View.catalogue;

  final List<BuyV2Product> _catalogueProducts = [];
  final Map<String, BuyV2CartLine> _cart = {};
  final Map<String, BuyV2ProductFactsSnapshot> _productFacts = {};
  final Map<String, int> _prescriptionApprovedQuantities = {};
  final Map<String, BuyV2CustomerReview> _customerReviews = {};
  final Map<String, String> _reportedProductReasons = {};
  final Set<String> _reviewableProductIds = {};
  final Set<String> _productFeedbackBusyIds = {};
  bool _productReportsAvailable = false;
  final Set<String> _orderRefreshBusyIds = {};
  final Map<String, BuyV2CommerceLoadState> _orderRefreshStates = {};
  final Map<String, String> _orderRefreshMessages = {};
  final Map<String, BuyV2BalancePaymentResult> _balancePaymentResults = {};
  final Set<String> _balancePaymentBusyOrderIds = {};
  int _balancePaymentAttemptSequence = 0;
  final Map<String, BuyV2DeliveryExceptionSnapshot>
  _deliveryExceptionSnapshots = {};
  final Set<String> _deliveryExceptionBusyOrderIds = {};
  final Map<String, String> _selectedDeliveryRescheduleSlots = {};
  final Map<BuyV2CartScope, double> _cartScrollOffsets = {};
  final Map<BuyV2Destination, String> _deliveryInstructionIds = {};
  final Map<String, _BuyV2CartBenefitSelectionRef> _selectedCartBenefitRefs =
      {};
  List<BuyV2CartBenefit> _liveCartBenefits = [];
  int _cartBenefitsRequestSequence = 0;
  BuyV2CartBenefitsLoadState cartBenefitsLoadState =
      BuyV2CartBenefitsLoadState.ready;
  String? cartBenefitsMessage;
  List<BuyV2CommercialPaymentTerm> _commercialPaymentTerms = [];
  final Map<String, String> _selectedCommercialPaymentTermIds = {};
  int _commercialPaymentTermsRequestSequence = 0;
  BuyV2CommerceLoadState commercialPaymentTermsLoadState =
      BuyV2CommerceLoadState.ready;
  String? commercialPaymentTermsMessage;
  BuyV2CheckoutQuote? _checkoutQuote;
  String? _checkoutQuoteFingerprint;
  int _checkoutQuoteRequestSequence = 0;
  BuyV2CommerceLoadState checkoutQuoteLoadState = BuyV2CommerceLoadState.ready;
  String? checkoutQuoteMessage;
  final Map<String, int> _tipsByFulfilmentKey = {};
  final Set<String> _savedKeys = {};
  String? _savedProductsOwnerScope;
  int _savedProductsMutationRevision = 0;
  String? _customerStateOwnerScope;
  int _customerStateMutationRevision = 0;
  Set<BuyV2Destination> _confirmedDestinations = {};
  List<BuyV2Order> _confirmedOrders = [];
  Map<String, _BuyV2DeliveryPromiseQuote> _checkoutPromiseSnapshot = {};
  Map<String, _BuyV2DeliveryPromiseQuote>? _pendingCheckoutPromiseSnapshot;
  List<BuyV2DeliveryPromiseChange> _checkoutDeliveryPromiseChanges = [];
  List<BuyV2PriceChange> _checkoutPriceChanges = [];
  BuyV2CheckoutAvailabilityIssue? _checkoutAvailabilityIssue;
  String? _confirmedPurchaseId;
  int _confirmedItemCount = 0;
  int _confirmedTotal = 0;
  int _confirmedAmountPaidNow = 0;
  int _confirmedBalanceDue = 0;
  int _orderSequence = 1;
  int _purchaseSequence = 1;

  List<BuyV2PriceChange> get checkoutPriceChanges =>
      List.unmodifiable(_checkoutPriceChanges);

  bool get checkoutPriceReviewRequired => _checkoutPriceChanges.isNotEmpty;

  BuyV2CheckoutAvailabilityIssue? get checkoutAvailabilityIssue =>
      _checkoutAvailabilityIssue;

  void acceptCheckoutPriceChanges() {
    if (_checkoutPriceChanges.isEmpty) return;
    _checkoutPriceChanges = [];
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = 'Updated prices accepted';
    _persistCustomerState();
    notifyListeners();
  }

  final List<BuyV2Address> _addresses = [
    const BuyV2Address(
      id: 'home',
      kind: BuyV2AddressKind.home,
      label: 'Home',
      recipient: 'Aarav Sharma',
      phone: '9000000000',
      line: '12, Central Avenue',
      area: 'Sardarpura, Jodhpur',
      pinCode: '342003',
      landmark: 'Near Sardarpura circle',
    ),
    const BuyV2Address(
      id: 'work',
      kind: BuyV2AddressKind.work,
      label: 'Work',
      recipient: 'Aarav Sharma',
      phone: '9000000000',
      line: 'Business receiving desk',
      area: 'Basni, Jodhpur',
      pinCode: '342005',
      landmark: 'Near industrial area gate',
    ),
  ];

  final List<BuyV2Order> _orders = [
    const BuyV2Order(
      id: 'MS-240782',
      destination: BuyV2Destination.shop,
      title: 'Shop order',
      itemSummary: '13 products · Home · Sardarpura',
      total: 4839,
      partner: 'Sardarpura Supermart',
      partnerType: 'Mool Retail Partner',
      promise: 'Delivery schedule awaiting live confirmation',
      destinationLabel: 'Sardarpura · 342003',
      progress: .54,
      status: BuyV2OrderStatus.preparing,
    ),
    const BuyV2Order(
      id: 'PO-240783',
      destination: BuyV2Destination.wholesale,
      title: 'Wholesale order',
      itemSummary: '1 trade product · Work receiving · Basni',
      total: 4200,
      partner: 'Marwar Foods Distribution',
      partnerType: 'Mool Trade Partner',
      buyerName: 'Shree Balaji Retail',
      buyerType: 'Verified retailer Workspace',
      paymentMethod: 'Bank transfer',
      paymentTermLabel: 'Booking amount with balance at delivery',
      amountPaidNow: 1260,
      balanceDue: 2940,
      balanceDueLabel: 'Due at confirmed delivery',
      paymentStatusLabel: 'Booking amount paid · balance due at delivery',
      promise: 'Supplier delivery schedule awaiting confirmation',
      destinationLabel: 'Basni · 342005',
      progress: .34,
      status: BuyV2OrderStatus.confirmed,
    ),
    const BuyV2Order(
      id: 'RX-240784',
      destination: BuyV2Destination.medicine,
      title: 'Medicine order',
      itemSummary: '2 medicines · Home · Sardarpura',
      total: 134,
      partner: 'Sardarpura Health Pharmacy',
      partnerType: 'Mool Pharmacy Partner',
      promise: 'Pharmacy delivery schedule awaiting confirmation',
      destinationLabel: 'Sardarpura · 342003',
      progress: .67,
      status: BuyV2OrderStatus.preparing,
    ),
    const BuyV2Order(
      id: 'MS-240741',
      destination: BuyV2Destination.shop,
      title: 'Shop order',
      itemSummary: '8 products · Home · Sardarpura',
      total: 2186,
      partner: 'Sardarpura Supermart',
      partnerType: 'Mool Retail Partner',
      promise: 'Delivered · 25 Jul · 6:42 pm',
      destinationLabel: 'Sardarpura · 342003',
      progress: 1,
      status: BuyV2OrderStatus.delivered,
    ),
    const BuyV2Order(
      id: 'PO-240728',
      destination: BuyV2Destination.wholesale,
      title: 'Wholesale order',
      itemSummary: '3 trade products · Work receiving · Basni',
      total: 8460,
      partner: 'Marwar Foods Distribution',
      partnerType: 'Mool Trade Partner',
      buyerName: 'Shree Balaji Retail',
      buyerType: 'Verified retailer Workspace',
      paymentMethod: 'Bank transfer',
      paymentTermLabel: 'Full advance',
      amountPaidNow: 8460,
      paymentStatusLabel: 'Paid in full',
      promise: 'Delivered · 23 Jul · 1:18 pm',
      destinationLabel: 'Basni · 342005',
      progress: 1,
      status: BuyV2OrderStatus.delivered,
    ),
    const BuyV2Order(
      id: 'RX-240719',
      destination: BuyV2Destination.medicine,
      title: 'Medicine order',
      itemSummary: '2 medicines · Home · Sardarpura',
      total: 698,
      partner: 'Sardarpura Health Pharmacy',
      partnerType: 'Mool Pharmacy Partner',
      promise: 'Delivered · 20 Jul · 10:36 am',
      destinationLabel: 'Sardarpura · 342003',
      progress: 1,
      status: BuyV2OrderStatus.delivered,
    ),
  ];

  List<BuyV2Address> get addresses => List.unmodifiable(_addresses);

  List<BuyV2Order> get orders => List.unmodifiable(_orders);

  bool orderRefreshBusy(String orderId) =>
      _orderRefreshBusyIds.contains(orderId);

  BuyV2CommerceLoadState? orderRefreshState(String orderId) =>
      _orderRefreshStates[orderId];

  String? orderRefreshMessage(String orderId) => _orderRefreshMessages[orderId];

  Future<bool> refreshOrder(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) {
      notice = 'This order could not be found.';
      notifyListeners();
      return false;
    }
    if (reviewDataEnabled) {
      _orderRefreshStates[orderId] = BuyV2CommerceLoadState.ready;
      _orderRefreshMessages[orderId] = 'Order is up to date.';
      notice = 'Order is up to date.';
      notifyListeners();
      return true;
    }
    if (!_orderRefreshBusyIds.add(orderId)) return false;
    _orderRefreshStates[orderId] = BuyV2CommerceLoadState.loading;
    _orderRefreshMessages.remove(orderId);
    notifyListeners();
    try {
      final result = await commerceAdapter.refreshOrder(orderId: orderId);
      final refreshed = result.order;
      final valid =
          result.state == BuyV2CommerceLoadState.ready &&
          refreshed != null &&
          refreshed.id == orderId &&
          refreshed.total >= 0 &&
          refreshed.progress >= 0 &&
          refreshed.progress <= 1 &&
          refreshed.partner.trim().isNotEmpty &&
          refreshed.promise.trim().isNotEmpty &&
          _validTaxInvoiceForOrder(refreshed);
      if (!valid) {
        _orderRefreshStates[orderId] = result.state;
        _orderRefreshMessages[orderId] = result.customerMessage;
        notice = result.customerMessage;
        return false;
      }
      _orders[index] = refreshed;
      _orderRefreshStates[orderId] = BuyV2CommerceLoadState.ready;
      _orderRefreshMessages[orderId] = result.customerMessage;
      notice = result.customerMessage;
      return true;
    } on Object {
      _orderRefreshStates[orderId] = BuyV2CommerceLoadState.offline;
      _orderRefreshMessages[orderId] =
          'Order could not refresh. Check your connection and try again.';
      notice = _orderRefreshMessages[orderId];
      return false;
    } finally {
      _orderRefreshBusyIds.remove(orderId);
      notifyListeners();
    }
  }

  bool _validTaxInvoiceForOrder(BuyV2Order order) {
    final state = order.taxInvoiceState;
    final details = order.taxInvoiceDetails;
    if (state == null) return true;
    if (state == BuyV2TaxInvoiceState.pending ||
        state == BuyV2TaxInvoiceState.unavailable) {
      return details == null;
    }
    if (!order.invoiceAvailable ||
        details == null ||
        details.invoiceNumber.trim().isEmpty ||
        details.sellerLegalName.trim().isEmpty ||
        details.sellerAddress.trim().isEmpty ||
        details.sellerGstin.trim().length != 15 ||
        details.placeOfSupply.trim().isEmpty ||
        details.sourceId.trim().isEmpty ||
        details.lines.isEmpty ||
        (state == BuyV2TaxInvoiceState.corrected &&
            details.revisionLabel?.trim().isNotEmpty != true)) {
      return false;
    }
    for (final line in details.lines) {
      final intraStateTax = line.cgst > 0 || line.sgst > 0;
      if (line.description.trim().isEmpty ||
          line.hsnSac.trim().isEmpty ||
          line.taxableValue < 0 ||
          line.gstRate < 0 ||
          line.gstRate > 100 ||
          line.cgst < 0 ||
          line.sgst < 0 ||
          line.igst < 0 ||
          line.cess < 0 ||
          (intraStateTax && line.igst > 0)) {
        return false;
      }
    }
    return details.totalTax == order.tax;
  }

  bool balancePaymentBusy(String orderId) =>
      _balancePaymentBusyOrderIds.contains(orderId);

  BuyV2BalancePaymentResult? balancePaymentFor(String orderId) =>
      _balancePaymentResults[orderId];

  Future<bool> restoreBalancePayment(String orderId) async {
    final adapter = balancePaymentAdapter;
    final order = _orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    if (adapter == null || order == null || order.balanceDue <= 0) return false;
    if (!_balancePaymentBusyOrderIds.add(orderId)) return false;
    notifyListeners();
    try {
      final result = await adapter.loadBalance(orderId: orderId);
      if (!_validBalancePaymentResult(order, result)) return false;
      _balancePaymentResults[orderId] = result;
      return true;
    } on Object {
      _balancePaymentResults[orderId] = BuyV2BalancePaymentResult(
        state: BuyV2BalancePaymentState.offline,
        amountDue: order.balanceDue,
        dueLabel: order.balanceDueLabel ?? 'Due later',
        customerMessage: 'Balance status could not be checked. Try again.',
      );
      return false;
    } finally {
      _balancePaymentBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> startBalancePayment(String orderId) async {
    final adapter = balancePaymentAdapter;
    final order = _orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    final current = _balancePaymentResults[orderId];
    if (adapter == null ||
        order == null ||
        current == null ||
        (current.state != BuyV2BalancePaymentState.due &&
            current.state != BuyV2BalancePaymentState.overdue) ||
        !_balancePaymentBusyOrderIds.add(orderId)) {
      return false;
    }
    notifyListeners();
    try {
      final result = await adapter.startPayment(
        orderId: orderId,
        amountDue: current.amountDue,
        idempotencyKey:
            'balance-${orderId.toLowerCase()}-'
            '${_balancePaymentAttemptSequence++}',
      );
      if (!_validBalancePaymentResult(order, result)) return false;
      _balancePaymentResults[orderId] = result;
      return result.state == BuyV2BalancePaymentState.paymentActionRequired;
    } on Object {
      _balancePaymentResults[orderId] = BuyV2BalancePaymentResult(
        state: BuyV2BalancePaymentState.offline,
        amountDue: current.amountDue,
        dueLabel: current.dueLabel,
        customerMessage: 'Balance payment could not start. Try again.',
      );
      return false;
    } finally {
      _balancePaymentBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> continueBalancePayment(
    String orderId,
    BuyV2PaymentHandoff handoff,
  ) async {
    final order = _orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    final current = _balancePaymentResults[orderId];
    final uri = current?.paymentActionUri;
    if (order == null ||
        current == null ||
        current.state != BuyV2BalancePaymentState.paymentActionRequired ||
        uri == null ||
        !_balancePaymentBusyOrderIds.add(orderId)) {
      return false;
    }
    notifyListeners();
    var opened = false;
    try {
      opened = await handoff(uri);
    } on Object {
      opened = false;
    }
    _balancePaymentResults[orderId] = BuyV2BalancePaymentResult(
      state: opened
          ? BuyV2BalancePaymentState.paymentPending
          : BuyV2BalancePaymentState.unknown,
      amountDue: current.amountDue,
      dueLabel: current.dueLabel,
      customerMessage: opened
          ? 'Return here after payment to check the balance.'
          : 'The payment app did not open. No payment is confirmed.',
      paymentReference: current.paymentReference,
      paymentActionUri: current.paymentActionUri,
    );
    _balancePaymentBusyOrderIds.remove(orderId);
    notifyListeners();
    return opened;
  }

  Future<bool> reconcileBalancePayment(String orderId) async {
    final adapter = balancePaymentAdapter;
    final order = _orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    final current = _balancePaymentResults[orderId];
    final reference = current?.paymentReference;
    if (adapter == null ||
        order == null ||
        current == null ||
        reference == null ||
        (current.state != BuyV2BalancePaymentState.paymentPending &&
            current.state != BuyV2BalancePaymentState.unknown) ||
        !_balancePaymentBusyOrderIds.add(orderId)) {
      return false;
    }
    notifyListeners();
    try {
      final result = await adapter.reconcilePayment(
        orderId: orderId,
        paymentReference: reference,
      );
      if (!_validBalancePaymentResult(order, result)) return false;
      _balancePaymentResults[orderId] = result;
      return result.state == BuyV2BalancePaymentState.paid;
    } on Object {
      _balancePaymentResults[orderId] = BuyV2BalancePaymentResult(
        state: BuyV2BalancePaymentState.unknown,
        amountDue: current.amountDue,
        dueLabel: current.dueLabel,
        customerMessage:
            'Balance payment is still being checked. Do not pay again.',
        paymentReference: reference,
      );
      return false;
    } finally {
      _balancePaymentBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  bool _validBalancePaymentResult(
    BuyV2Order order,
    BuyV2BalancePaymentResult result,
  ) {
    if (result.amountDue < 0 ||
        result.amountDue > order.balanceDue ||
        result.dueLabel.trim().isEmpty ||
        result.customerMessage.trim().isEmpty) {
      return false;
    }
    return switch (result.state) {
      BuyV2BalancePaymentState.paymentActionRequired =>
        result.amountDue > 0 &&
            result.paymentReference?.trim().isNotEmpty == true &&
            result.paymentActionUri != null &&
            (result.paymentActionUri!.scheme == 'upi' ||
                result.paymentActionUri!.scheme == 'https') &&
            result.paymentActionUri!.host.isNotEmpty,
      BuyV2BalancePaymentState.paymentPending ||
      BuyV2BalancePaymentState.unknown =>
        result.paymentReference?.trim().isNotEmpty == true,
      BuyV2BalancePaymentState.paid => result.amountDue == 0,
      BuyV2BalancePaymentState.upcoming ||
      BuyV2BalancePaymentState.due ||
      BuyV2BalancePaymentState.overdue ||
      BuyV2BalancePaymentState.offline ||
      BuyV2BalancePaymentState.unavailable => result.amountDue > 0,
    };
  }

  bool deliveryExceptionBusy(String orderId) =>
      _deliveryExceptionBusyOrderIds.contains(orderId);

  BuyV2DeliveryExceptionSnapshot? deliveryExceptionFor(String orderId) =>
      _deliveryExceptionSnapshots[orderId];

  String? selectedDeliveryRescheduleSlot(String orderId) =>
      _selectedDeliveryRescheduleSlots[orderId];

  Future<bool> restoreDeliveryException(String orderId) async {
    final adapter = deliveryExceptionAdapter;
    final orderExists = _orders.any((order) => order.id == orderId);
    if (adapter == null ||
        !orderExists ||
        !_deliveryExceptionBusyOrderIds.add(orderId)) {
      return false;
    }
    notifyListeners();
    try {
      final snapshot = await adapter.loadException(orderId: orderId);
      if (!_validDeliveryExceptionSnapshot(snapshot)) return false;
      _deliveryExceptionSnapshots[orderId] = snapshot;
      final selected = _selectedDeliveryRescheduleSlots[orderId];
      if (selected != null && !snapshot.rescheduleSlots.contains(selected)) {
        _selectedDeliveryRescheduleSlots.remove(orderId);
      }
      return true;
    } on Object {
      _deliveryExceptionSnapshots[orderId] =
          const BuyV2DeliveryExceptionSnapshot(
            state: BuyV2CommerceLoadState.offline,
            customerMessage:
                'Delivery updates could not be checked. Try again.',
          );
      return false;
    } finally {
      _deliveryExceptionBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  bool chooseDeliveryRescheduleSlot(String orderId, String slot) {
    final snapshot = _deliveryExceptionSnapshots[orderId];
    if (snapshot == null || !snapshot.rescheduleSlots.contains(slot)) {
      notice = 'This delivery time is no longer available.';
      notifyListeners();
      return false;
    }
    _selectedDeliveryRescheduleSlots[orderId] = slot;
    notice = '$slot selected.';
    notifyListeners();
    return true;
  }

  Future<bool> confirmDeliveryReschedule(String orderId) async {
    final adapter = deliveryExceptionAdapter;
    final snapshot = _deliveryExceptionSnapshots[orderId];
    final exceptionId = snapshot?.exceptionId;
    final slot = _selectedDeliveryRescheduleSlots[orderId];
    if (adapter == null ||
        snapshot == null ||
        exceptionId == null ||
        slot == null ||
        !snapshot.rescheduleSlots.contains(slot) ||
        !_deliveryExceptionBusyOrderIds.add(orderId)) {
      return false;
    }
    notifyListeners();
    try {
      final updated = await adapter.rescheduleDelivery(
        orderId: orderId,
        exceptionId: exceptionId,
        slot: slot,
      );
      if (!_validDeliveryExceptionSnapshot(updated)) return false;
      _deliveryExceptionSnapshots[orderId] = updated;
      _selectedDeliveryRescheduleSlots.remove(orderId);
      notice = updated.customerMessage;
      return true;
    } on Object {
      notice = 'Delivery could not be rescheduled. Try again.';
      return false;
    } finally {
      _deliveryExceptionBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> disputeProofOfDelivery(String orderId) async {
    final adapter = deliveryExceptionAdapter;
    final snapshot = _deliveryExceptionSnapshots[orderId];
    final exceptionId = snapshot?.exceptionId;
    final proofReference = snapshot?.proofReference;
    if (adapter == null ||
        snapshot?.kind != BuyV2DeliveryExceptionKind.proofOfDeliveryAvailable ||
        exceptionId == null ||
        proofReference == null ||
        !_deliveryExceptionBusyOrderIds.add(orderId)) {
      return false;
    }
    notifyListeners();
    try {
      final updated = await adapter.disputeProofOfDelivery(
        orderId: orderId,
        exceptionId: exceptionId,
        proofReference: proofReference,
      );
      if (!_validDeliveryExceptionSnapshot(updated)) return false;
      _deliveryExceptionSnapshots[orderId] = updated;
      notice = updated.customerMessage;
      return updated.kind == BuyV2DeliveryExceptionKind.proofOfDeliveryDisputed;
    } on Object {
      notice = 'Proof of delivery could not be reported. Try again.';
      return false;
    } finally {
      _deliveryExceptionBusyOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  bool _validDeliveryExceptionSnapshot(
    BuyV2DeliveryExceptionSnapshot snapshot,
  ) {
    if (snapshot.customerMessage.trim().isEmpty) return false;
    if (snapshot.state != BuyV2CommerceLoadState.ready) return true;
    final kind = snapshot.kind;
    if (kind == null) return true;
    if (snapshot.exceptionId?.trim().isNotEmpty != true ||
        snapshot.headline?.trim().isNotEmpty != true ||
        snapshot.detail?.trim().isNotEmpty != true ||
        snapshot.rescheduleSlots.any((slot) => slot.trim().isEmpty) ||
        snapshot.rescheduleSlots.toSet().length !=
            snapshot.rescheduleSlots.length) {
      return false;
    }
    if (kind == BuyV2DeliveryExceptionKind.rescheduleAvailable &&
        snapshot.rescheduleSlots.isEmpty) {
      return false;
    }
    if (kind == BuyV2DeliveryExceptionKind.proofOfDeliveryAvailable &&
        snapshot.proofReference?.trim().isNotEmpty != true) {
      return false;
    }
    return true;
  }

  String? get selectedOrderId => _selectedOrderId;

  String? get selectedAddressId => _selectedAddressId;

  Future<void> restoreCommerce() async {
    if (reviewDataEnabled) {
      commerceLoadState = BuyV2CommerceLoadState.ready;
      commerceMessage = null;
      return;
    }
    commerceLoadState = BuyV2CommerceLoadState.loading;
    commerceMessage = null;
    notifyListeners();
    try {
      final snapshot = await commerceAdapter.refresh();
      _catalogueProducts
        ..clear()
        ..addAll(snapshot.products);
      _addresses
        ..clear()
        ..addAll(snapshot.addresses);
      _orders
        ..clear()
        ..addAll(snapshot.orders);
      _businessVerificationState = snapshot.businessVerificationState;
      businessVerified =
          snapshot.businessVerificationState ==
              BuyV2BusinessVerificationState.verified ||
          snapshot.businessVerified;
      _productReportsAvailable = snapshot.productReportsAvailable;
      _reviewableProductIds
        ..clear()
        ..addAll(snapshot.reviewableProductIds);
      availablePaymentMethods = Set.unmodifiable(snapshot.paymentMethods);
      _selectedAddressId = snapshot.selectedAddressId;
      if (_selectedAddressId != null &&
          !_addresses.any((address) => address.id == _selectedAddressId)) {
        _selectedAddressId = null;
      }
      if (!availablePaymentMethods.contains(selectedPayment)) {
        selectedPayment = availablePaymentMethods.firstOrNull ?? '';
      }
      commerceLoadState = snapshot.state;
      commerceMessage = snapshot.customerMessage;
    } on Object {
      commerceLoadState = BuyV2CommerceLoadState.offline;
      commerceMessage =
          'Shop could not refresh. Check your connection and try again.';
    }
    notifyListeners();
  }

  Future<void> retryCommerce() => restoreCommerce();

  Future<BuyV2AddressRequestResult> createAddressRequest({
    String recipient = '',
  }) async {
    final result = await commerceAdapter.createAddressRequest(
      recipient: recipient.trim(),
    );
    notice = result.customerMessage;
    notifyListeners();
    return result;
  }

  List<BuyV2Category> get categories => switch (destination) {
    BuyV2Destination.shop => BuyV2Catalogue.shopCategories,
    BuyV2Destination.wholesale => BuyV2Catalogue.wholesaleCategories,
    BuyV2Destination.medicine => BuyV2Catalogue.medicineCategories,
    BuyV2Destination.orders => const [],
  };

  String get selectedCategoryId => switch (destination) {
    BuyV2Destination.shop => shopCategoryId,
    BuyV2Destination.wholesale => wholesaleCategoryId,
    BuyV2Destination.medicine => medicineCategoryId,
    BuyV2Destination.orders => 'all',
  };

  BuyV2FulfilmentMode fulfilmentModeFor(BuyV2Product product) =>
      productFactsFor(product).fulfilmentMode ??
      buyV2CatalogueFulfilmentModeFor(product);

  List<BuyV2Product> get visibleProducts {
    final normalized = query.trim().toLowerCase();
    final filterDestination = destination == BuyV2Destination.orders
        ? BuyV2Destination.shop
        : destination;
    final category = selectedCategoryId;
    final intentProductIds =
        activeShoppingIntent == BuyV2ShoppingIntent.monthlyBasket
        ? _catalogueProducts
              .where((product) => product.destination == BuyV2Destination.shop)
              .take(12)
              .map((product) => product.id)
              .toSet()
        : null;
    final candidates = _catalogueProducts.where((product) {
      if (product.destination != filterDestination) return false;
      if (intentProductIds != null && !intentProductIds.contains(product.id)) {
        return false;
      }
      final matchesCategory =
          category == 'all' ||
          (category == 'rx' && product.requiresPrescription) ||
          product.categoryId == category;
      final matchesFilter = switch (selectedFilter) {
        'fast' => switch (filterDestination) {
          BuyV2Destination.shop => product.deliveryPromise.contains(
            'Delivered in',
          ),
          BuyV2Destination.wholesale => product.origin.toLowerCase().contains(
            'jodhpur',
          ),
          BuyV2Destination.medicine => !product.requiresPrescription,
          BuyV2Destination.orders => false,
        },
        'today' => product.deliveryPromise.contains('Delivered in'),
        'lowest' =>
          product.badge.toLowerCase().contains('lowest') ||
              product.badge.contains('off'),
        'manufacturer' =>
          product.sellerType.toLowerCase().contains('manufacturer') ||
              product.manufacturerVerified,
        'nearby' =>
          product.origin.toLowerCase().contains('jodhpur') ||
              product.seller.toLowerCase().contains('sardarpura') ||
              product.seller.toLowerCase().contains('jodhpur'),
        'two-days' =>
          product.origin.toLowerCase().contains('jodhpur') ||
              product.origin.toLowerCase().contains('jaipur'),
        'freight' => product.freightIncluded,
        'moq' =>
          product.destination == BuyV2Destination.wholesale &&
              product.minimumOrder <= 2,
        'returns' => product.returnPolicy != null,
        'quick-local' =>
          fulfilmentModeFor(product) == BuyV2FulfilmentMode.quickLocal,
        'standard-courier' =>
          fulfilmentModeFor(product) == BuyV2FulfilmentMode.standardCourier,
        'bulk-freight' =>
          fulfilmentModeFor(product) == BuyV2FulfilmentMode.bulkFreight,
        'rx' => product.requiresPrescription,
        'otc' => !product.requiresPrescription,
        _ => true,
      };
      return matchesCategory && matchesFilter;
    }).toList();
    final products = normalized.isEmpty
        ? candidates
        : BuyV2SearchRelevance.rankProducts(candidates, query);
    if (category == 'all' && normalized.isEmpty && products.length > 18) {
      return products.take(18).toList();
    }
    return products;
  }

  bool get hasNarrowedProductSearchScope =>
      destination != BuyV2Destination.orders &&
      query.trim().isNotEmpty &&
      (selectedCategoryId != 'all' || selectedFilter != null);

  /// Truthful, replaceable search-discovery boundary for the active vertical.
  ///
  /// Until an approved suggestion API exists, suggestions come only from the
  /// products already allowed by the current destination/category/filter
  /// selection. The presentation does not infer popularity, history or
  /// personalization from this list.
  List<String> get searchSuggestions {
    if (destination == BuyV2Destination.orders || query.trim().isNotEmpty) {
      return const [];
    }
    final suggestions = <String>[];
    final seen = <String>{};
    for (final product in visibleProducts) {
      final label = product.title.trim();
      if (label.isEmpty || !seen.add(label.toLowerCase())) continue;
      suggestions.add(label);
      if (suggestions.length == 4) break;
    }
    return List.unmodifiable(suggestions);
  }

  List<BuyV2Product> savedProductsFor(BuyV2Destination value) {
    final destination = value == BuyV2Destination.orders
        ? BuyV2Destination.shop
        : value;
    return _catalogueProducts
        .where(
          (product) =>
              product.destination == destination &&
              _savedKeys.contains(_buyV2SavedKey(product)),
        )
        .toList(growable: false);
  }

  int savedCountFor(BuyV2Destination value) => savedProductsFor(value).length;

  bool isSaved(String productId) {
    final item = findProduct(productId);
    return item != null && _savedKeys.contains(_buyV2SavedKey(item));
  }

  void toggleSaved(String productId) {
    final item = findProduct(productId);
    if (item == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return;
    }
    final key = _buyV2SavedKey(item);
    if (_savedKeys.remove(key)) {
      notice = '${item.title} removed from Saved.';
    } else {
      _savedKeys.add(key);
      notice = '${item.title} saved.';
    }
    _savedProductsMutationRevision += 1;
    _persistSavedProducts();
    _persistCustomerState();
    notifyListeners();
  }

  void clearSavedProducts(BuyV2Destination value) {
    final destination = value == BuyV2Destination.orders
        ? BuyV2Destination.shop
        : value;
    final removed = _savedKeys.where(
      (key) => key.startsWith('${destination.name}|'),
    );
    if (removed.isEmpty) return;
    _savedKeys.removeAll(removed.toList(growable: false));
    _savedProductsMutationRevision += 1;
    notice = '${destination.label} Saved products cleared.';
    _persistSavedProducts();
    _persistCustomerState();
    notifyListeners();
  }

  Future<void> restoreSavedProducts() async {
    final store = savedProductsStore;
    final ownerScope = store?.ownerScope;
    if (store == null ||
        ownerScope == null ||
        ownerScope == _savedProductsOwnerScope) {
      return;
    }
    _savedProductsOwnerScope = ownerScope;
    _savedKeys.clear();
    final mutationRevision = _savedProductsMutationRevision;
    notifyListeners();
    try {
      final stored = await store.read() ?? const <String>{};
      if (store.ownerScope != ownerScope ||
          mutationRevision != _savedProductsMutationRevision) {
        return;
      }
      final validKeys = _catalogueProducts.map(_buyV2SavedKey).toSet();
      _savedKeys
        ..clear()
        ..addAll(stored.where(validKeys.contains));
      notifyListeners();
    } on Object {
      if (store.ownerScope == ownerScope) {
        _savedProductsOwnerScope = null;
      }
      notice = 'Saved products could not be restored.';
      notifyListeners();
    }
  }

  void _persistSavedProducts() {
    final store = savedProductsStore;
    if (store == null) return;
    final snapshot = Set<String>.unmodifiable(_savedKeys);
    unawaited(
      store
          .write(snapshot)
          .then((saved) {
            if (!saved) {
              notice = 'Saved products could not be retained. Try again.';
              notifyListeners();
            }
          })
          .catchError((Object _) {
            notice = 'Saved products could not be retained. Try again.';
            notifyListeners();
          }),
    );
  }

  Future<void> restoreCustomerState() async {
    final store = customerStateStore;
    final ownerScope = store?.ownerScope;
    if (store == null ||
        ownerScope == null ||
        ownerScope == _customerStateOwnerScope) {
      return;
    }
    _customerStateOwnerScope = ownerScope;
    final mutationRevision = _customerStateMutationRevision;
    try {
      final snapshot = await store.read();
      if (snapshot == null ||
          store.ownerScope != ownerScope ||
          mutationRevision != _customerStateMutationRevision) {
        return;
      }
      _cart.clear();
      for (final entry in snapshot.cartQuantities.entries) {
        final product = findProduct(entry.key);
        if (product == null || entry.value < product.minimumOrder) continue;
        _cart[product.id] = BuyV2CartLine(
          product: product,
          quantity: entry.value,
        );
      }
      _addresses
        ..clear()
        ..addAll(snapshot.addresses);
      _selectedAddressId = snapshot.selectedAddressId;
      if (_selectedAddressId != null &&
          !_addresses.any((address) => address.id == _selectedAddressId)) {
        _selectedAddressId = null;
      }
      final validSavedKeys = _catalogueProducts.map(_buyV2SavedKey).toSet();
      _savedKeys
        ..clear()
        ..addAll(snapshot.savedProductKeys.where(validSavedKeys.contains));
      _deliveryInstructionIds
        ..clear()
        ..addAll(snapshot.deliveryInstructionIds);
      final storedPayment = snapshot.selectedPayment;
      if (storedPayment != null &&
          availablePaymentMethods.contains(storedPayment)) {
        selectedPayment = storedPayment;
      }
      _checkoutIdempotencyKey = snapshot.checkoutIdempotencyKey;
      _paymentReference = snapshot.paymentReference;
      _paymentActionUri = snapshot.paymentActionUri;
      _bankTransferInstructions = snapshot.bankTransferInstructions;
      activeShoppingIntent = BuyV2ShoppingIntent.values
          .where((intent) => intent.name == snapshot.shoppingIntent)
          .firstOrNull;
      final storedSubmissionState = BuyV2CheckoutSubmissionState.values
          .where((state) => state.name == snapshot.checkoutSubmissionState)
          .firstOrNull;
      checkoutSubmissionState = switch (storedSubmissionState) {
        BuyV2CheckoutSubmissionState.submitting
            when _paymentReference != null =>
          BuyV2CheckoutSubmissionState.paymentUnknown,
        BuyV2CheckoutSubmissionState.submitting =>
          BuyV2CheckoutSubmissionState.failed,
        final state? => state,
        null => BuyV2CheckoutSubmissionState.idle,
      };
      _pruneCartSelections();
      notifyListeners();
    } on Object {
      if (store.ownerScope == ownerScope) _customerStateOwnerScope = null;
      notice = 'Your Shop choices could not be restored. Try again.';
      notifyListeners();
    }
  }

  void _persistCustomerState() {
    final store = customerStateStore;
    if (store == null || store.ownerScope == null) return;
    _customerStateMutationRevision += 1;
    final snapshot = BuyV2CustomerStateSnapshot(
      cartQuantities: Map.unmodifiable({
        for (final line in _cart.values) line.product.id: line.quantity,
      }),
      addresses: List.unmodifiable(_addresses),
      selectedAddressId: _selectedAddressId,
      savedProductKeys: Set.unmodifiable(_savedKeys),
      deliveryInstructionIds: Map.unmodifiable(_deliveryInstructionIds),
      selectedPayment: selectedPayment.isEmpty ? null : selectedPayment,
      checkoutIdempotencyKey: _checkoutIdempotencyKey,
      paymentReference: _paymentReference,
      paymentActionUri: _paymentActionUri,
      bankTransferInstructions: _bankTransferInstructions,
      shoppingIntent: activeShoppingIntent?.name,
      checkoutSubmissionState: checkoutSubmissionState.name,
    );
    unawaited(
      store
          .write(snapshot)
          .then((saved) {
            if (!saved) {
              notice = 'Your Shop choices could not be retained. Try again.';
              notifyListeners();
            }
          })
          .catchError((Object _) {
            notice = 'Your Shop choices could not be retained. Try again.';
            notifyListeners();
          }),
    );
  }

  List<BuyV2CartLine> get cartLines {
    final lines = _linesForScope(cartScope);
    return List.unmodifiable(lines);
  }

  double cartScrollOffsetFor(BuyV2CartScope scope) =>
      _cartScrollOffsets[scope] ?? 0;

  void rememberCartScrollOffset(BuyV2CartScope scope, double offset) {
    if (!offset.isFinite) return;
    _cartScrollOffsets[scope] = offset < 0 ? 0 : offset;
  }

  List<BuyV2CartLine> get checkoutLines =>
      List.unmodifiable(_linesForScope(checkoutScope));

  List<BuyV2CartLine> _linesForScope(BuyV2CartScope scope) =>
      _cart.values.where((line) {
        return switch (scope) {
          BuyV2CartScope.all => true,
          BuyV2CartScope.shop =>
            line.product.destination == BuyV2Destination.shop,
          BuyV2CartScope.wholesale =>
            line.product.destination == BuyV2Destination.wholesale,
          BuyV2CartScope.medicine =>
            line.product.destination == BuyV2Destination.medicine,
        };
      }).toList();

  int countForDestination(BuyV2Destination value) => _cart.values
      .where((line) => line.product.destination == value)
      .fold(0, (total, line) => total + line.quantity);

  int totalForDestination(BuyV2Destination value) => _cart.values
      .where((line) => line.product.destination == value)
      .fold(0, (total, line) => total + line.total);

  int get itemCount =>
      _cart.values.fold(0, (total, line) => total + line.quantity);

  int get cartTotal =>
      _cart.values.fold(0, (total, line) => total + line.total);

  int get scopedItemCount =>
      cartLines.fold(0, (total, line) => total + line.quantity);

  int get scopedCartTotal =>
      cartLines.fold(0, (total, line) => total + line.total);

  int get scopedCartListPriceTotal => cartLines.fold(0, (total, line) {
    final product = line.product;
    final listPrice = product.mrp != null && product.mrp! > product.price
        ? product.mrp!
        : product.price;
    return total + (listPrice * line.quantity);
  });

  int get scopedCartSavings => scopedCartListPriceTotal - scopedCartTotal;

  Map<BuyV2Destination, int> get scopedCartFamilyTotals => Map.unmodifiable({
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ])
      if (cartLines.any((line) => line.product.destination == destination))
        destination: cartLines
            .where((line) => line.product.destination == destination)
            .fold(0, (total, line) => total + line.total),
  });

  Set<BuyV2Destination> get cartDestinations => Set.unmodifiable(
    _cart.values.map((line) => line.product.destination).toSet(),
  );

  Set<BuyV2Destination> get checkoutDestinations => Set.unmodifiable(
    checkoutLines.map((line) => line.product.destination).toSet(),
  );

  int get checkoutItemCount =>
      checkoutLines.fold(0, (total, line) => total + line.quantity);

  int get checkoutTotal =>
      checkoutLines.fold(0, (total, line) => total + line.total);

  List<BuyV2FulfilmentGroup> get scopedCartFulfilmentGroups =>
      _fulfilmentGroupsFor(cartLines);

  List<BuyV2FulfilmentGroup> get checkoutFulfilmentGroups =>
      _fulfilmentGroupsFor(checkoutLines);

  List<BuyV2FulfilmentGroup> _fulfilmentGroupsFor(List<BuyV2CartLine> lines) {
    final grouped = <String, List<BuyV2CartLine>>{};
    for (final line in lines) {
      final product = line.product;
      final key = '${product.destination.name}|${product.seller}';
      grouped.putIfAbsent(key, () => []).add(line);
    }
    return grouped.values
        .map((lines) {
          final facts = lines
              .map((line) => productFactsFor(line.product))
              .toList(growable: false);
          final promisedByLabels = facts
              .map((fact) => fact.promisedByLabel?.trim())
              .whereType<String>()
              .where((label) => label.isNotEmpty)
              .toSet();
          final dispatchPromises = facts
              .map((fact) => fact.dispatchPromise?.trim())
              .whereType<String>()
              .where((value) => value.isNotEmpty)
              .toSet();
          final deliveryProviders = facts
              .map((fact) => fact.deliveryProviderName?.trim())
              .whereType<String>()
              .where((value) => value.isNotEmpty)
              .toSet();
          final serviceLevels = facts
              .map((fact) => fact.deliveryServiceLevel?.trim())
              .whereType<String>()
              .where((value) => value.isNotEmpty)
              .toSet();
          return BuyV2FulfilmentGroup(
            destination: lines.first.product.destination,
            partner: lines.first.product.seller,
            partnerType: lines.first.product.partnerRole,
            promise: facts
                .map((fact) => fact.deliveryPromise)
                .toSet()
                .join(' · '),
            promisedByLabel: promisedByLabels.isEmpty
                ? null
                : promisedByLabels.join(' · '),
            dispatchPromise: dispatchPromises.isEmpty
                ? null
                : dispatchPromises.join(' · '),
            deliveryProviderName: deliveryProviders.isEmpty
                ? null
                : deliveryProviders.join(' · '),
            deliveryServiceLevel: serviceLevels.isEmpty
                ? null
                : serviceLevels.join(' · '),
            lines: List.unmodifiable(lines),
          );
        })
        .toList(growable: false);
  }

  Map<String, _BuyV2DeliveryPromiseQuote> _deliveryPromiseSnapshotFor(
    List<BuyV2FulfilmentGroup> groups,
  ) => {
    for (final group in groups)
      group.key: _BuyV2DeliveryPromiseQuote(
        promise: group.promise,
        promisedByLabel: group.promisedByLabel,
      ),
  };

  void _captureCheckoutPromiseSnapshot() {
    _checkoutPromiseSnapshot = _deliveryPromiseSnapshotFor(
      checkoutFulfilmentGroups,
    );
    _pendingCheckoutPromiseSnapshot = null;
    _checkoutDeliveryPromiseChanges = [];
  }

  void _clearCheckoutPromiseSnapshot() {
    _checkoutPromiseSnapshot = {};
    _pendingCheckoutPromiseSnapshot = null;
    _checkoutDeliveryPromiseChanges = [];
    _checkoutPriceChanges = [];
    _checkoutAvailabilityIssue = null;
    _invalidateCheckoutQuote();
    _invalidateCommercialPaymentTerms();
  }

  int tipForGroup(BuyV2FulfilmentGroup group) =>
      _tipsByFulfilmentKey[group.key] ?? 0;

  int get scopedTipTotal => scopedCartFulfilmentGroups.fold(
    0,
    (total, group) => total + tipForGroup(group),
  );

  int get checkoutTipTotal => checkoutFulfilmentGroups.fold(
    0,
    (total, group) => total + tipForGroup(group),
  );

  int couponSavingForDestination(BuyV2Destination destination) {
    final coupon = selectedCartBenefit(
      kind: BuyV2CartBenefitKind.coupon,
      destination: destination,
    );
    if (coupon == null) return 0;
    return coupon.savingAmount.clamp(0, totalForDestination(destination));
  }

  int get scopedCouponSaving => cartLines
      .map((line) => line.product.destination)
      .toSet()
      .fold(
        0,
        (total, destination) => total + couponSavingForDestination(destination),
      );

  int get checkoutCouponSaving => checkoutDestinations.fold(
    0,
    (total, destination) => total + couponSavingForDestination(destination),
  );

  Map<String, int> _checkoutGroupCouponSavings() {
    final remainingDiscount = {
      for (final destination in checkoutDestinations)
        destination: couponSavingForDestination(destination),
    };
    return Map.unmodifiable({
      for (final group in checkoutFulfilmentGroups)
        group.key: () {
          final available = remainingDiscount[group.destination] ?? 0;
          final discount = available > group.total ? group.total : available;
          remainingDiscount[group.destination] = available - discount;
          return discount;
        }(),
    });
  }

  Map<String, int> _checkoutGroupPayables() {
    if (checkoutQuoteLoadState == BuyV2CommerceLoadState.ready &&
        _checkoutQuote != null) {
      return Map.unmodifiable({
        for (final line in _checkoutQuote!.lines)
          line.fulfilmentKey: line.total,
      });
    }
    final discountByKey = _checkoutGroupCouponSavings();
    return Map.unmodifiable({
      for (final group in checkoutFulfilmentGroups)
        group.key:
            group.total + tipForGroup(group) - (discountByKey[group.key] ?? 0),
    });
  }

  int get scopedPayableTotal =>
      (scopedCartTotal + scopedTipTotal - scopedCouponSaving).clamp(
        0,
        scopedCartTotal + scopedTipTotal,
      );

  int get calculatedCheckoutPayableTotal =>
      (checkoutTotal + checkoutTipTotal - checkoutCouponSaving).clamp(
        0,
        checkoutTotal + checkoutTipTotal,
      );

  BuyV2CheckoutQuote? get checkoutQuote => _checkoutQuote;

  int get checkoutPayableTotal =>
      checkoutQuoteLoadState == BuyV2CommerceLoadState.ready &&
          _checkoutQuote != null
      ? _checkoutQuote!.total
      : calculatedCheckoutPayableTotal;

  List<BuyV2TipOption> tipOptionsFor(BuyV2Destination destination) =>
      List.unmodifiable(tipPolicy.optionsFor(destination));

  bool chooseTip({
    required String fulfilmentKey,
    required BuyV2Destination destination,
    required int amount,
  }) {
    final group = _fulfilmentGroupsFor(
      _cart.values.toList(),
    ).where((candidate) => candidate.key == fulfilmentKey).firstOrNull;
    if (group == null ||
        group.destination != destination ||
        !tipPolicy.accepts(destination, amount)) {
      notice = 'This tip option is not available.';
      notifyListeners();
      return false;
    }
    if (amount == 0) {
      _tipsByFulfilmentKey.remove(fulfilmentKey);
    } else {
      _tipsByFulfilmentKey[fulfilmentKey] = amount;
    }
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = null;
    notifyListeners();
    return true;
  }

  List<BuyV2DeliveryInstructionOption> deliveryInstructionsFor(
    BuyV2Destination destination,
  ) => buyV2DeliveryInstructionsFor(destination);

  BuyV2DeliveryInstructionOption? selectedDeliveryInstructionFor(
    BuyV2Destination destination,
  ) {
    final id = _deliveryInstructionIds[destination];
    if (id == null) return null;
    return buyV2DeliveryInstructionOptions
        .where((option) => option.id == id && option.destination == destination)
        .firstOrNull;
  }

  bool chooseDeliveryInstruction({
    required BuyV2Destination destination,
    required String? instructionId,
  }) {
    if (instructionId == null) {
      _deliveryInstructionIds.remove(destination);
      notice = null;
      _persistCustomerState();
      notifyListeners();
      return true;
    }
    final valid = buyV2DeliveryInstructionOptions.any(
      (option) =>
          option.id == instructionId && option.destination == destination,
    );
    if (!valid ||
        !_cart.values.any((line) => line.product.destination == destination)) {
      notice = 'This delivery instruction is not available.';
      notifyListeners();
      return false;
    }
    _deliveryInstructionIds[destination] = instructionId;
    notice = null;
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  bool get liveCartBenefitsEnabled =>
      cartBenefitsAdapter is BuyV2LiveCartBenefitsAdapter;

  bool get cartBenefitsBusy =>
      cartBenefitsLoadState == BuyV2CartBenefitsLoadState.loading;

  String _cartBenefitsFingerprint() => _cart.values
      .map(
        (line) => '${line.product.id}:${line.quantity}:${line.product.price}',
      )
      .followedBy([selectedPayment])
      .join('|');

  Future<bool> refreshCartBenefits() async {
    final adapter = cartBenefitsAdapter;
    if (adapter is! BuyV2LiveCartBenefitsAdapter) return true;
    if (_cart.isEmpty) {
      _liveCartBenefits = [];
      cartBenefitsLoadState = BuyV2CartBenefitsLoadState.ready;
      cartBenefitsMessage = null;
      _invalidateAndRefreshCheckoutPricingContracts();
      notifyListeners();
      return true;
    }
    final requestSequence = ++_cartBenefitsRequestSequence;
    final fingerprint = _cartBenefitsFingerprint();
    cartBenefitsLoadState = BuyV2CartBenefitsLoadState.loading;
    cartBenefitsMessage = null;
    notifyListeners();
    try {
      final snapshot = await adapter.loadEligibility(
        BuyV2CartBenefitsRequest(
          lines: List.unmodifiable(_cart.values),
          selectedPaymentMethod: selectedPayment,
        ),
      );
      if (requestSequence != _cartBenefitsRequestSequence ||
          fingerprint != _cartBenefitsFingerprint()) {
        return false;
      }
      cartBenefitsLoadState = snapshot.state;
      cartBenefitsMessage = snapshot.customerMessage;
      if (snapshot.state != BuyV2CartBenefitsLoadState.ready) {
        _liveCartBenefits = [];
        _invalidateAndRefreshCheckoutPricingContracts();
        notifyListeners();
        return !_hasSelectedCartBenefitReference;
      }
      _liveCartBenefits = _validatedLiveCartBenefits(snapshot);
      final removedSelection = _removeIneligibleCartBenefitSelections();
      if (removedSelection) {
        cartBenefitsMessage =
            'A selected coupon or offer is no longer eligible. Review the current options.';
      }
      _invalidateAndRefreshCheckoutPricingContracts();
      notifyListeners();
      return !removedSelection;
    } on Object {
      if (requestSequence != _cartBenefitsRequestSequence) return false;
      _liveCartBenefits = [];
      cartBenefitsLoadState = BuyV2CartBenefitsLoadState.unavailable;
      cartBenefitsMessage =
          'Coupons and offers could not be checked. Try again.';
      _invalidateAndRefreshCheckoutPricingContracts();
      notifyListeners();
      return !_hasSelectedCartBenefitReference;
    }
  }

  List<BuyV2CartBenefit> _validatedLiveCartBenefits(
    BuyV2CartBenefitsSnapshot snapshot,
  ) {
    final destinations = cartDestinations;
    final totals = {
      for (final destination in destinations)
        destination: totalForDestination(destination),
    };
    final quantities = {
      for (final destination in destinations)
        destination: countForDestination(destination),
    };
    final ids = <String>{};
    return List.unmodifiable([
      for (final benefit in snapshot.benefits)
        if (destinations.contains(benefit.destination) &&
            benefit.id.trim().isNotEmpty &&
            benefit.title.trim().isNotEmpty &&
            benefit.detail.trim().isNotEmpty &&
            benefit.sourceId.trim().isNotEmpty &&
            benefit.sponsorName.trim().isNotEmpty &&
            benefit.savingAmount >= 0 &&
            benefit.savingAmount <= (totals[benefit.destination] ?? 0) &&
            (benefit.kind == BuyV2CartBenefitKind.coupon ||
                benefit.savingAmount == 0) &&
            _liveBenefitMatchesStrategy(
              benefit,
              evaluatedAt: snapshot.evaluatedAt,
              destinationTotal: totals[benefit.destination] ?? 0,
              destinationQuantity: quantities[benefit.destination] ?? 0,
            ) &&
            ids.add(
              '${benefit.destination.name}|${benefit.kind.name}|${benefit.id}',
            ))
          benefit,
    ]);
  }

  bool _liveBenefitMatchesStrategy(
    BuyV2CartBenefit benefit, {
    required DateTime evaluatedAt,
    required int destinationTotal,
    required int destinationQuantity,
  }) {
    if (benefit.validFrom case final validFrom?
        when evaluatedAt.isBefore(validFrom)) {
      return false;
    }
    if (benefit.validUntil case final validUntil?
        when !evaluatedAt.isBefore(validUntil)) {
      return false;
    }
    if (benefit.minimumSpend case final minimumSpend?
        when minimumSpend <= 0 || destinationTotal < minimumSpend) {
      return false;
    }
    if (benefit.minimumQuantity case final minimumQuantity?
        when minimumQuantity <= 0 || destinationQuantity < minimumQuantity) {
      return false;
    }
    return switch (benefit.strategy) {
      BuyV2CartBenefitStrategy.timedSale => benefit.validUntil != null,
      BuyV2CartBenefitStrategy.publishedOffer =>
        benefit.offerId?.trim().isNotEmpty ?? false,
      BuyV2CartBenefitStrategy.minimumOrder =>
        benefit.minimumSpend != null || benefit.minimumQuantity != null,
      BuyV2CartBenefitStrategy.loadBased => benefit.minimumQuantity != null,
      BuyV2CartBenefitStrategy.financialProduct =>
        (benefit.sponsor == BuyV2CartBenefitSponsor.bank ||
                benefit.sponsor == BuyV2CartBenefitSponsor.financialPartner) &&
            (benefit.eligiblePaymentMethods.isEmpty ||
                benefit.eligiblePaymentMethods.contains(selectedPayment)),
      BuyV2CartBenefitStrategy.partnerCampaign => true,
      BuyV2CartBenefitStrategy.freeDelivery => benefit.freeDelivery,
    };
  }

  bool get _hasSelectedCartBenefitReference =>
      _selectedCartBenefitRefs.isNotEmpty;

  bool _removeIneligibleCartBenefitSelections() {
    var removed = false;
    _selectedCartBenefitRefs.removeWhere((key, selection) {
      final available = _liveCartBenefits.any(
        (benefit) =>
            key ==
                _cartBenefitSelectionKey(benefit.destination, benefit.kind) &&
            selection.benefitId == benefit.id &&
            selection.sourceId == benefit.sourceId,
      );
      if (!available) removed = true;
      return !available;
    });
    return removed;
  }

  void _invalidateLiveCartBenefits() {
    if (!liveCartBenefitsEnabled) return;
    _cartBenefitsRequestSequence += 1;
    _liveCartBenefits = [];
    cartBenefitsLoadState = _cart.isEmpty
        ? BuyV2CartBenefitsLoadState.ready
        : BuyV2CartBenefitsLoadState.idle;
    cartBenefitsMessage = null;
  }

  bool get checkoutQuoteEnabled => checkoutQuoteAdapter != null;

  bool get checkoutQuoteBusy =>
      checkoutQuoteLoadState == BuyV2CommerceLoadState.loading;

  bool get checkoutQuoteReviewRequired {
    if (!checkoutQuoteEnabled) return false;
    final quote = _checkoutQuote;
    return checkoutQuoteLoadState != BuyV2CommerceLoadState.ready ||
        quote == null ||
        !DateTime.now().isBefore(quote.validUntil) ||
        _checkoutQuoteFingerprint != _currentCheckoutQuoteFingerprint();
  }

  int get checkoutQuotedTax =>
      _checkoutQuote?.lines.fold<int>(0, (total, line) => total + line.tax) ??
      0;

  int get checkoutQuotedFreight =>
      _checkoutQuote?.lines.fold<int>(
        0,
        (total, line) => total + line.freight,
      ) ??
      0;

  int get checkoutQuotedDeliveryFee =>
      _checkoutQuote?.lines.fold<int>(
        0,
        (total, line) => total + line.deliveryFee,
      ) ??
      0;

  int get checkoutQuotedPaymentCharge =>
      _checkoutQuote?.lines.fold<int>(
        0,
        (total, line) => total + line.paymentCharge,
      ) ??
      0;

  Future<bool> refreshCheckoutQuote() async {
    final adapter = checkoutQuoteAdapter;
    final address = selectedAddressOrNull;
    final groups = checkoutFulfilmentGroups;
    if (adapter == null) return true;
    if (address == null || groups.isEmpty) {
      _checkoutQuote = null;
      _checkoutQuoteFingerprint = null;
      checkoutQuoteLoadState = BuyV2CommerceLoadState.unavailable;
      checkoutQuoteMessage = 'Choose a delivery address to check the total.';
      notifyListeners();
      return false;
    }
    final requestSequence = ++_checkoutQuoteRequestSequence;
    final fingerprint = _currentCheckoutQuoteFingerprint();
    _checkoutQuote = null;
    _checkoutQuoteFingerprint = null;
    checkoutQuoteLoadState = BuyV2CommerceLoadState.loading;
    checkoutQuoteMessage = null;
    notifyListeners();
    try {
      final snapshot = await adapter.loadQuote(
        groups: List.unmodifiable(groups),
        address: address,
        selectedPaymentMethod: selectedPayment,
        selectedBenefits: selectedCartBenefitsFor(cartDestinations),
        tipAmountsByFulfilmentKey: {
          for (final group in groups) group.key: tipForGroup(group),
        },
      );
      if (requestSequence != _checkoutQuoteRequestSequence ||
          fingerprint != _currentCheckoutQuoteFingerprint()) {
        return false;
      }
      checkoutQuoteLoadState = snapshot.state;
      checkoutQuoteMessage = snapshot.customerMessage;
      final quote = snapshot.quote;
      if (snapshot.state != BuyV2CommerceLoadState.ready ||
          quote == null ||
          !_validCheckoutQuote(quote, groups)) {
        _checkoutQuote = null;
        _checkoutQuoteFingerprint = null;
        if (snapshot.state == BuyV2CommerceLoadState.ready) {
          checkoutQuoteLoadState = BuyV2CommerceLoadState.unavailable;
          checkoutQuoteMessage = 'The current total could not be verified.';
        }
        _invalidateCommercialPaymentTerms();
        notifyListeners();
        return false;
      }
      _checkoutQuote = quote;
      _checkoutQuoteFingerprint = fingerprint;
      _invalidateCommercialPaymentTerms();
      if (commercialPaymentTermsEnabled) {
        unawaited(refreshCommercialPaymentTerms());
      }
      notifyListeners();
      return true;
    } on Object {
      if (requestSequence != _checkoutQuoteRequestSequence) return false;
      _checkoutQuote = null;
      _checkoutQuoteFingerprint = null;
      checkoutQuoteLoadState = BuyV2CommerceLoadState.unavailable;
      checkoutQuoteMessage = 'Checkout total could not be checked. Try again.';
      _invalidateCommercialPaymentTerms();
      notifyListeners();
      return false;
    }
  }

  bool _validCheckoutQuote(
    BuyV2CheckoutQuote quote,
    List<BuyV2FulfilmentGroup> groups,
  ) {
    if (quote.id.trim().isEmpty ||
        quote.sourceId.trim().isEmpty ||
        !quote.evaluatedAt.isBefore(quote.validUntil) ||
        !DateTime.now().isBefore(quote.validUntil) ||
        quote.lines.length != groups.length) {
      return false;
    }
    final groupByKey = {for (final group in groups) group.key: group};
    final expectedCouponSaving = _checkoutGroupCouponSavings();
    final seen = <String>{};
    var total = 0;
    for (final line in quote.lines) {
      final group = groupByKey[line.fulfilmentKey];
      if (group == null ||
          !seen.add(line.fulfilmentKey) ||
          line.itemSubtotal != group.total ||
          line.couponSaving !=
              (expectedCouponSaving[line.fulfilmentKey] ?? 0) ||
          line.tip != tipForGroup(group) ||
          line.tax < 0 ||
          line.freight < 0 ||
          line.deliveryFee < 0 ||
          line.paymentCharge < 0 ||
          line.total !=
              line.itemSubtotal -
                  line.couponSaving +
                  line.tax +
                  line.freight +
                  line.deliveryFee +
                  line.tip +
                  line.paymentCharge) {
        return false;
      }
      total += line.total;
    }
    return total == quote.total;
  }

  String _currentCheckoutQuoteFingerprint() {
    final addressId = selectedAddressOrNull?.id ?? 'no-address';
    final benefits = selectedCartBenefitsFor(
      cartDestinations,
    ).map((benefit) => '${benefit.id}:${benefit.sourceId}').join(',');
    return checkoutFulfilmentGroups
        .map(
          (group) =>
              '${group.key}:${group.total}:${tipForGroup(group)}:'
              '${_checkoutGroupCouponSavings()[group.key] ?? 0}',
        )
        .followedBy([addressId, selectedPayment, benefits])
        .join('|');
  }

  void _invalidateCheckoutQuote() {
    if (!checkoutQuoteEnabled) return;
    _checkoutQuoteRequestSequence += 1;
    _checkoutQuote = null;
    _checkoutQuoteFingerprint = null;
    checkoutQuoteLoadState = BuyV2CommerceLoadState.loading;
    checkoutQuoteMessage = null;
  }

  bool get commercialPaymentTermsEnabled =>
      commercialPaymentTermsAdapter != null;

  bool get commercialPaymentTermsBusy =>
      commercialPaymentTermsLoadState == BuyV2CommerceLoadState.loading;

  List<BuyV2CommercialPaymentTerm> commercialPaymentTermsFor(
    String fulfilmentKey,
  ) => List.unmodifiable(
    _commercialPaymentTerms.where(
      (term) => term.fulfilmentKey == fulfilmentKey,
    ),
  );

  BuyV2CommercialPaymentTerm? selectedCommercialPaymentTermFor(
    String fulfilmentKey,
  ) {
    final selectedId = _selectedCommercialPaymentTermIds[fulfilmentKey];
    if (selectedId == null) return null;
    return _commercialPaymentTerms
        .where(
          (term) =>
              term.fulfilmentKey == fulfilmentKey && term.id == selectedId,
        )
        .firstOrNull;
  }

  bool get checkoutPaymentTermsReviewRequired {
    if (!commercialPaymentTermsEnabled) return false;
    if (commercialPaymentTermsLoadState != BuyV2CommerceLoadState.ready) {
      return true;
    }
    return checkoutFulfilmentGroups.any(
      (group) => selectedCommercialPaymentTermFor(group.key) == null,
    );
  }

  int get checkoutAmountDueNow {
    if (!commercialPaymentTermsEnabled) return checkoutPayableTotal;
    final selected = [
      for (final group in checkoutFulfilmentGroups)
        selectedCommercialPaymentTermFor(group.key),
    ];
    if (selected.any((term) => term == null)) return checkoutPayableTotal;
    return selected.whereType<BuyV2CommercialPaymentTerm>().fold(
      0,
      (total, term) => total + term.amountDueNow,
    );
  }

  int get checkoutBalanceDue {
    if (!commercialPaymentTermsEnabled) return 0;
    return checkoutFulfilmentGroups
        .map((group) => selectedCommercialPaymentTermFor(group.key))
        .whereType<BuyV2CommercialPaymentTerm>()
        .fold(0, (total, term) => total + term.balanceDue);
  }

  Future<bool> refreshCommercialPaymentTerms() async {
    final adapter = commercialPaymentTermsAdapter;
    if (adapter == null) return true;
    final groups = checkoutFulfilmentGroups;
    if (groups.isEmpty) {
      _commercialPaymentTerms = [];
      _selectedCommercialPaymentTermIds.clear();
      commercialPaymentTermsLoadState = BuyV2CommerceLoadState.ready;
      commercialPaymentTermsMessage = null;
      notifyListeners();
      return true;
    }
    final requestSequence = ++_commercialPaymentTermsRequestSequence;
    final fingerprint = _commercialPaymentTermsFingerprint(groups);
    commercialPaymentTermsLoadState = BuyV2CommerceLoadState.loading;
    commercialPaymentTermsMessage = null;
    notifyListeners();
    try {
      final snapshot = await adapter.loadTerms(
        groups: List.unmodifiable(groups),
        selectedPaymentMethod: selectedPayment,
        quotedTotalsByFulfilmentKey: _checkoutGroupPayables(),
      );
      if (requestSequence != _commercialPaymentTermsRequestSequence ||
          fingerprint != _commercialPaymentTermsFingerprint(groups)) {
        return false;
      }
      commercialPaymentTermsLoadState = snapshot.state;
      commercialPaymentTermsMessage = snapshot.customerMessage;
      if (snapshot.state != BuyV2CommerceLoadState.ready) {
        _commercialPaymentTerms = [];
        notifyListeners();
        return false;
      }
      _commercialPaymentTerms = _validatedCommercialPaymentTerms(
        snapshot.terms,
        groups,
      );
      _selectedCommercialPaymentTermIds.removeWhere(
        (groupKey, selectedId) => !_commercialPaymentTerms.any(
          (term) => term.fulfilmentKey == groupKey && term.id == selectedId,
        ),
      );
      for (final group in groups) {
        if (group.destination == BuyV2Destination.wholesale) continue;
        final retailAdvance = commercialPaymentTermsFor(group.key)
            .where(
              (term) =>
                  term.kind == BuyV2CommercialPaymentTermKind.retailAdvance,
            )
            .firstOrNull;
        if (retailAdvance != null) {
          _selectedCommercialPaymentTermIds[group.key] = retailAdvance.id;
        }
      }
      if (checkoutPaymentTermsReviewRequired &&
          commercialPaymentTermsMessage == null) {
        commercialPaymentTermsMessage =
            'Choose an available payment term for each Wholesale delivery.';
      }
      notifyListeners();
      return !checkoutPaymentTermsReviewRequired;
    } on Object {
      if (requestSequence != _commercialPaymentTermsRequestSequence) {
        return false;
      }
      _commercialPaymentTerms = [];
      commercialPaymentTermsLoadState = BuyV2CommerceLoadState.unavailable;
      commercialPaymentTermsMessage =
          'Payment terms could not be checked. Try again.';
      notifyListeners();
      return false;
    }
  }

  String _commercialPaymentTermsFingerprint(
    List<BuyV2FulfilmentGroup> groups,
  ) => groups
      .map(
        (group) =>
            '${group.key}:${group.total}:${tipForGroup(group)}:'
            '${couponSavingForDestination(group.destination)}',
      )
      .followedBy([selectedPayment])
      .join('|');

  List<BuyV2CommercialPaymentTerm> _validatedCommercialPaymentTerms(
    List<BuyV2CommercialPaymentTerm> terms,
    List<BuyV2FulfilmentGroup> groups,
  ) {
    final groupByKey = {for (final group in groups) group.key: group};
    final payableByKey = _checkoutGroupPayables();
    final identities = <String>{};
    return List.unmodifiable([
      for (final term in terms)
        if (_validCommercialPaymentTerm(
              term,
              group: groupByKey[term.fulfilmentKey],
              expectedTotal: payableByKey[term.fulfilmentKey],
            ) &&
            identities.add('${term.fulfilmentKey}|${term.id}'))
          term,
    ]);
  }

  bool _validCommercialPaymentTerm(
    BuyV2CommercialPaymentTerm term, {
    required BuyV2FulfilmentGroup? group,
    required int? expectedTotal,
  }) {
    if (group == null ||
        expectedTotal == null ||
        term.id.trim().isEmpty ||
        term.sourceId.trim().isEmpty ||
        term.supplierName.trim().isEmpty ||
        term.fulfilmentKey != group.key ||
        term.destination != group.destination ||
        term.supplierName != group.partner ||
        term.orderTotal != expectedTotal ||
        term.amountDueNow < 0 ||
        term.balanceDue < 0 ||
        term.amountDueNow + term.balanceDue != expectedTotal ||
        term.balanceDueLabel.trim().isEmpty) {
      return false;
    }
    if (group.destination != BuyV2Destination.wholesale) {
      return term.kind == BuyV2CommercialPaymentTermKind.retailAdvance &&
          term.amountDueNow == expectedTotal &&
          term.balanceDue == 0;
    }
    return switch (term.kind) {
      BuyV2CommercialPaymentTermKind.retailAdvance => false,
      BuyV2CommercialPaymentTermKind.wholesaleAdvance =>
        term.amountDueNow == expectedTotal && term.balanceDue == 0,
      BuyV2CommercialPaymentTermKind.bookingBalanceBeforeDispatch ||
      BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery =>
        term.amountDueNow > 0 && term.balanceDue > 0,
      BuyV2CommercialPaymentTermKind.supplierCredit =>
        term.netDays != null &&
            term.netDays! >= 1 &&
            term.netDays! <= (term.supplierIsMicroOrSmall ? 45 : 90) &&
            term.financierName == null &&
            term.keyFactsUri == null,
      BuyV2CommercialPaymentTermKind.regulatedCredit =>
        term.netDays != null &&
            term.netDays! >= 1 &&
            term.netDays! <= 90 &&
            term.financierName?.trim().isNotEmpty == true &&
            term.annualPercentageRate != null &&
            term.annualPercentageRate! >= 0 &&
            term.keyFactsUri?.scheme == 'https' &&
            term.keyFactsUri?.host.isNotEmpty == true,
    };
  }

  bool chooseCommercialPaymentTerm(BuyV2CommercialPaymentTerm term) {
    if (commercialPaymentTermsLoadState != BuyV2CommerceLoadState.ready ||
        !commercialPaymentTermsFor(
          term.fulfilmentKey,
        ).any((candidate) => candidate.id == term.id)) {
      notice = 'This payment term is no longer available.';
      notifyListeners();
      return false;
    }
    _selectedCommercialPaymentTermIds[term.fulfilmentKey] = term.id;
    notice = '${_commercialPaymentTermLabel(term.kind)} selected.';
    notifyListeners();
    return true;
  }

  String _commercialPaymentTermLabel(BuyV2CommercialPaymentTermKind kind) =>
      switch (kind) {
        BuyV2CommercialPaymentTermKind.retailAdvance ||
        BuyV2CommercialPaymentTermKind.wholesaleAdvance => 'Full advance',
        BuyV2CommercialPaymentTermKind.bookingBalanceBeforeDispatch =>
          'Booking amount with balance before dispatch',
        BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery =>
          'Booking amount with balance at delivery',
        BuyV2CommercialPaymentTermKind.supplierCredit => 'Supplier credit',
        BuyV2CommercialPaymentTermKind.regulatedCredit =>
          'Financial partner credit',
      };

  void _invalidateCommercialPaymentTerms() {
    if (!commercialPaymentTermsEnabled) return;
    _commercialPaymentTermsRequestSequence += 1;
    _commercialPaymentTerms = [];
    commercialPaymentTermsLoadState = BuyV2CommerceLoadState.loading;
    commercialPaymentTermsMessage = null;
  }

  void _invalidateAndRefreshCheckoutPricingContracts() {
    _invalidateCheckoutQuote();
    if (_cart.isNotEmpty && checkoutQuoteEnabled) {
      unawaited(refreshCheckoutQuote());
    }
    _invalidateCommercialPaymentTerms();
    if (_cart.isNotEmpty &&
        commercialPaymentTermsEnabled &&
        !checkoutQuoteEnabled) {
      unawaited(refreshCommercialPaymentTerms());
    }
  }

  List<BuyV2CartBenefit> cartBenefits({
    required BuyV2CartBenefitKind kind,
    BuyV2Destination? destination,
  }) {
    final destinations = destination == null
        ? cartLines.map((line) => line.product.destination).toSet()
        : {destination};
    if (destinations.isEmpty ||
        destinations.contains(BuyV2Destination.orders)) {
      return const [];
    }
    final raw = liveCartBenefitsEnabled
        ? _liveCartBenefits
        : cartBenefitsAdapter.benefitsFor(
            kind: kind,
            destinations: destinations,
            itemTotal: destination == null
                ? scopedCartTotal
                : totalForDestination(destination),
          );
    final valid = <BuyV2CartBenefit>[];
    final ids = <String>{};
    for (final benefit in raw) {
      if (benefit.kind != kind ||
          !destinations.contains(benefit.destination) ||
          benefit.id.trim().isEmpty ||
          benefit.title.trim().isEmpty ||
          benefit.detail.trim().isEmpty ||
          benefit.sourceId.trim().isEmpty ||
          benefit.sponsorName.trim().isEmpty ||
          benefit.savingAmount < 0 ||
          !ids.add('${benefit.destination.name}|${benefit.id}')) {
        continue;
      }
      valid.add(benefit);
    }
    return List.unmodifiable(valid);
  }

  String _cartBenefitSelectionKey(
    BuyV2Destination destination,
    BuyV2CartBenefitKind kind,
  ) => '${destination.name}|${kind.name}';

  BuyV2CartBenefit? selectedCartBenefit({
    required BuyV2CartBenefitKind kind,
    required BuyV2Destination destination,
  }) {
    final selected =
        _selectedCartBenefitRefs[_cartBenefitSelectionKey(destination, kind)];
    if (selected == null) return null;
    return cartBenefits(kind: kind, destination: destination)
        .where(
          (benefit) =>
              benefit.id == selected.benefitId &&
              benefit.sourceId == selected.sourceId,
        )
        .firstOrNull;
  }

  List<BuyV2CartBenefit> selectedCartBenefitsFor(
    Set<BuyV2Destination> destinations,
  ) {
    final selected = <BuyV2CartBenefit>[];
    for (final destination in destinations) {
      if (destination == BuyV2Destination.orders) continue;
      for (final kind in BuyV2CartBenefitKind.values) {
        final benefit = selectedCartBenefit(
          kind: kind,
          destination: destination,
        );
        if (benefit != null) selected.add(benefit);
      }
    }
    return List.unmodifiable(selected);
  }

  bool chooseCartBenefit(BuyV2CartBenefit benefit) {
    if (liveCartBenefitsEnabled &&
        cartBenefitsLoadState != BuyV2CartBenefitsLoadState.ready) {
      notice = 'Coupon eligibility is still being checked.';
      notifyListeners();
      return false;
    }
    final available = cartBenefits(
      kind: benefit.kind,
      destination: benefit.destination,
    );
    final current = available
        .where(
          (candidate) =>
              candidate.id == benefit.id &&
              candidate.sourceId == benefit.sourceId,
        )
        .firstOrNull;
    if (current == null) {
      notice = 'This offer is no longer available.';
      notifyListeners();
      return false;
    }
    _selectedCartBenefitRefs[_cartBenefitSelectionKey(
      current.destination,
      current.kind,
    )] = _BuyV2CartBenefitSelectionRef(
      benefitId: current.id,
      sourceId: current.sourceId,
    );
    _invalidateAndRefreshCheckoutPricingContracts();
    notice =
        current.kind == BuyV2CartBenefitKind.coupon && current.savingAmount > 0
        ? '${current.title} applied. Your total now includes the saving.'
        : '${current.title} selected for Checkout review.';
    notifyListeners();
    return true;
  }

  void removeCartBenefit({
    required BuyV2CartBenefitKind kind,
    required BuyV2Destination destination,
  }) {
    final removed = _selectedCartBenefitRefs.remove(
      _cartBenefitSelectionKey(destination, kind),
    );
    if (removed == null) return;
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = kind == BuyV2CartBenefitKind.coupon
        ? 'Coupon removed from Checkout review.'
        : 'Payment offer removed from Checkout review.';
    notifyListeners();
  }

  List<BuyV2Product> cartRecommendationsFor(
    BuyV2Destination destination, {
    Set<String> excludedProductIds = const {},
    bool specialOffersOnly = false,
    int limit = 6,
  }) {
    if (destination == BuyV2Destination.orders || limit <= 0) {
      return const [];
    }
    final cartProductIds = _cart.keys.toSet();
    final categoryIds = _cart.values
        .where((line) => line.product.destination == destination)
        .map((line) => line.product.categoryId)
        .toSet();
    bool hasOffer(BuyV2Product product) {
      final badge = product.badge.toLowerCase();
      return (product.mrp != null && product.mrp! > product.price) ||
          badge.contains('off') ||
          badge.contains('lowest') ||
          badge.contains('best');
    }

    int score(BuyV2Product product) {
      var value = categoryIds.contains(product.categoryId) ? 8 : 0;
      if (hasOffer(product)) value += 4;
      if (destination == BuyV2Destination.medicine &&
          !product.requiresPrescription) {
        value += 2;
      }
      return value;
    }

    final candidates = _catalogueProducts
        .where(
          (product) =>
              product.destination == destination &&
              !cartProductIds.contains(product.id) &&
              !excludedProductIds.contains(product.id) &&
              (!specialOffersOnly || hasOffer(product)),
        )
        .toList(growable: false);
    candidates.sort((left, right) {
      final scoreOrder = score(right).compareTo(score(left));
      if (scoreOrder != 0) return scoreOrder;
      final priceOrder = left.price.compareTo(right.price);
      if (priceOrder != 0) return priceOrder;
      return left.id.compareTo(right.id);
    });
    return List.unmodifiable(candidates.take(limit));
  }

  /// Returns deterministic continuation products from the current catalogue.
  ///
  /// This is deliberately independent of Cart contents, customer history,
  /// popularity, serviceability and provider state. It is a local catalogue
  /// ordering helper, not a personalized or clinical recommendation owner.
  List<BuyV2Product> productContinuationsFor(
    BuyV2Product current, {
    int limit = 6,
  }) {
    if (current.destination == BuyV2Destination.orders || limit <= 0) {
      return const [];
    }

    int score(BuyV2Product product) {
      var value = product.categoryId == current.categoryId ? 8 : 0;
      if (product.brand == current.brand) value += 4;
      return value;
    }

    final candidates = _catalogueProducts
        .where(
          (product) =>
              product.destination == current.destination &&
              product.id != current.id,
        )
        .toList(growable: false);
    candidates.sort((left, right) {
      final scoreOrder = score(right).compareTo(score(left));
      if (scoreOrder != 0) return scoreOrder;
      final priceOrder = left.price.compareTo(right.price);
      if (priceOrder != 0) return priceOrder;
      return left.id.compareTo(right.id);
    });
    return List.unmodifiable(candidates.take(limit));
  }

  /// Returns exact current-catalogue Wholesale products from the same seller.
  ///
  /// Seller equality is deliberately literal and local. This selector does
  /// not establish supplier identity, verification, availability, ranking,
  /// serviceability or a commercial recommendation.
  List<BuyV2Product> supplierContinuationsFor(
    BuyV2Product current, {
    int limit = 12,
  }) {
    if (current.destination != BuyV2Destination.wholesale || limit <= 0) {
      return const [];
    }

    final candidates = _catalogueProducts
        .where(
          (product) =>
              product.destination == BuyV2Destination.wholesale &&
              product.id != current.id &&
              product.seller == current.seller,
        )
        .toList(growable: false);
    candidates.sort((left, right) {
      final priceOrder = left.price.compareTo(right.price);
      if (priceOrder != 0) return priceOrder;
      return left.id.compareTo(right.id);
    });
    return List.unmodifiable(candidates.take(limit));
  }

  /// Returns exact current-catalogue Shop or Medicine products from the same
  /// literal seller.
  ///
  /// This local selector does not establish seller or pharmacy identity,
  /// verification, availability, serviceability, ranking, recommendation or
  /// a medical relationship. Wholesale remains owned by
  /// [supplierContinuationsFor].
  List<BuyV2Product> sellerContinuationsFor(
    BuyV2Product current, {
    int limit = 12,
  }) {
    final supportedDestination =
        current.destination == BuyV2Destination.shop ||
        current.destination == BuyV2Destination.medicine;
    if (!supportedDestination || limit <= 0) return const [];

    final candidates = _catalogueProducts
        .where(
          (product) =>
              product.destination == current.destination &&
              product.id != current.id &&
              product.seller == current.seller,
        )
        .toList(growable: false);
    candidates.sort((left, right) {
      final priceOrder = left.price.compareTo(right.price);
      if (priceOrder != 0) return priceOrder;
      return left.id.compareTo(right.id);
    });
    return List.unmodifiable(candidates.take(limit));
  }

  Set<BuyV2Destination> get confirmedDestinations =>
      Set.unmodifiable(_confirmedDestinations);

  List<BuyV2Order> get confirmedOrders => List.unmodifiable(_confirmedOrders);

  String? get confirmedPurchaseId => _confirmedPurchaseId;

  bool get checkoutPromiseReviewRequired =>
      _pendingCheckoutPromiseSnapshot != null;

  List<BuyV2DeliveryPromiseChange> get checkoutDeliveryPromiseChanges =>
      List.unmodifiable(_checkoutDeliveryPromiseChanges);

  int get confirmedItemCount => _confirmedItemCount;

  int get confirmedTotal => _confirmedTotal;

  int get confirmedAmountPaidNow => _confirmedAmountPaidNow;

  int get confirmedBalanceDue => _confirmedBalanceDue;

  List<BuyV2Order> get visibleOrders {
    final normalizedQuery = query.trim().toLowerCase();
    return _orders
        .where((order) => order.destination != BuyV2Destination.medicine)
        .where(
          (order) => ordersTab == BuyV2OrdersTab.delivered
              ? order.status == BuyV2OrderStatus.delivered
              : order.status != BuyV2OrderStatus.delivered,
        )
        .where(
          (order) =>
              destination != BuyV2Destination.orders ||
              normalizedQuery.isEmpty ||
              [
                order.id,
                order.title,
                order.partner,
                order.partnerType,
                order.itemSummary,
              ].any((value) => value.toLowerCase().contains(normalizedQuery)),
        )
        .toList(growable: false);
  }

  int get activeOrderCount => _orders
      .where((order) => order.destination != BuyV2Destination.medicine)
      .where((order) => order.status != BuyV2OrderStatus.delivered)
      .length;

  int get deliveredOrderCount => _orders
      .where((order) => order.destination != BuyV2Destination.medicine)
      .where((order) => order.status == BuyV2OrderStatus.delivered)
      .length;

  BuyV2Product? findProduct(String id) {
    for (final product in _catalogueProducts) {
      if (product.id == id) return product;
    }
    return null;
  }

  BuyV2Product product(String id) {
    final match = findProduct(id);
    if (match != null) return match;
    throw ArgumentError.value(id, 'id', 'Unknown Buy product');
  }

  BuyV2ProductFactsSnapshot productFactsFor(BuyV2Product product) {
    return _productFacts.putIfAbsent(product.id, () {
      final next = productFactsAdapter.snapshotFor(product);
      return _validProductFacts(product, next)
          ? next
          : _catalogueFactsFallback.snapshotFor(product);
    });
  }

  bool refreshProductFacts(String productId) {
    final product = findProduct(productId);
    if (product == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    final next = productFactsAdapter.snapshotFor(product);
    if (!_validProductFacts(product, next)) {
      notice = 'Product information could not be refreshed.';
      notifyListeners();
      return false;
    }
    final previous = _productFacts[product.id];
    _productFacts[product.id] = next;
    if (previous != next) {
      notifyListeners();
    }
    return true;
  }

  bool _validProductFacts(
    BuyV2Product product,
    BuyV2ProductFactsSnapshot snapshot,
  ) {
    return snapshot.productId == product.id &&
        snapshot.price > 0 &&
        snapshot.deliveryPromise.trim().isNotEmpty &&
        snapshot.partner.trim().isNotEmpty &&
        snapshot.orderabilityLabel.trim().isNotEmpty &&
        snapshot.sourceId.trim().isNotEmpty &&
        (snapshot.dispatchPromise == null ||
            snapshot.dispatchPromise!.trim().isNotEmpty) &&
        (snapshot.deliveryProviderName == null ||
            snapshot.deliveryProviderName!.trim().isNotEmpty) &&
        (snapshot.deliveryServiceLevel == null ||
            snapshot.deliveryServiceLevel!.trim().isNotEmpty) &&
        (snapshot.nextOpeningLabel == null ||
            snapshot.nextOpeningLabel!.trim().isNotEmpty) &&
        (snapshot.orderCutoffLabel == null ||
            snapshot.orderCutoffLabel!.trim().isNotEmpty) &&
        (snapshot.deliveryFeeLabel == null ||
            snapshot.deliveryFeeLabel!.trim().isNotEmpty) &&
        (snapshot.storeOperatingState != BuyV2StoreOperatingState.closed ||
            snapshot.nextOpeningLabel?.trim().isNotEmpty == true);
  }

  BuyV2SponsoredContent? sponsoredContentFor(
    BuyV2SponsoredPlacement placement,
  ) {
    if (!sponsoredContentActivationApproved) return null;
    final content = sponsoredContentAdapter.contentFor(placement);
    return content?.placement == placement ? content : null;
  }

  BuyV2Product? get selectedProduct {
    final id = selectedProductId;
    return id == null ? null : findProduct(id);
  }

  BuyV2Order? get selectedOrderOrNull {
    final id = _selectedOrderId;
    if (id == null) return null;
    return _orders.where((order) => order.id == id).firstOrNull;
  }

  BuyV2Order get selectedOrder =>
      selectedOrderOrNull ??
      (throw StateError('No valid Buy order is selected.'));

  /// The truthful order owner for the existing Assist current-order card.
  ///
  /// A selected order is contextual only when Assist was opened from that
  /// order's Tracking or Items depth. General Assist entry deliberately keeps
  /// the established first-active-order fallback and cannot consume a stale
  /// selection left by an earlier Orders journey.
  BuyV2Order get assistOrder {
    final selected = selectedOrderOrNull;
    if ((_assistReturnView == BuyV2View.tracking ||
            _assistReturnView == BuyV2View.orderItems) &&
        selected != null) {
      return selected;
    }
    return _orders.firstWhere(
      (order) => order.status != BuyV2OrderStatus.delivered,
      orElse: () => _orders.first,
    );
  }

  BuyV2Address? get selectedAddressOrNull {
    final id = _selectedAddressId;
    if (id == null) return null;
    return _addresses.where((address) => address.id == id).firstOrNull;
  }

  BuyV2Address get selectedAddress =>
      selectedAddressOrNull ??
      (throw StateError('No valid Buy address is selected.'));

  bool restoreSelectedOrderId(String? id) {
    if (id == null || !_orders.any((order) => order.id == id)) {
      _selectedOrderId = null;
      destination = BuyV2Destination.orders;
      view = BuyV2View.catalogue;
      query = '';
      selectedFilter = null;
      notice = 'This order could not be found.';
      notifyListeners();
      return false;
    }
    _selectedOrderId = id;
    notice = null;
    notifyListeners();
    return true;
  }

  bool restoreSelectedAddressId(String? id) {
    if (id == null || !_addresses.any((address) => address.id == id)) {
      _selectedAddressId = null;
      if (view == BuyV2View.checkout || view == BuyV2View.confirmation) {
        view = BuyV2View.cart;
      }
      notice = 'Choose a delivery address to continue.';
      notifyListeners();
      return false;
    }
    _selectedAddressId = id;
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = null;
    notifyListeners();
    return true;
  }

  void openDestination(BuyV2Destination value) {
    final previous = _navigationSurfaceIdentity;
    _clearRecoveryOriginIfActive();
    _accountChildReturnActive = false;
    destination = value;
    view = value == BuyV2Destination.orders
        ? BuyV2View.catalogue
        : BuyV2View.catalogue;
    query = '';
    selectedFilter = null;
    activeShoppingIntent = null;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.replace,
    );
  }

  bool openProduct(String id) {
    final item = findProduct(id);
    if (item == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    final previous = _navigationSurfaceIdentity;
    if (view != BuyV2View.product) {
      _productReturnDestination = destination;
      _productReturnView = view;
    }
    destination = item.destination;
    selectedProductId = item.id;
    view = BuyV2View.product;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
    return true;
  }

  void closeProduct() {
    final previous = _navigationSurfaceIdentity;
    destination = _productReturnDestination;
    view = _productReturnView;
    selectedProductId = null;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  void openCart({BuyV2CartScope scope = BuyV2CartScope.all}) {
    final previous = _navigationSurfaceIdentity;
    if (_cart.isEmpty) {
      destination = switch (scope) {
        BuyV2CartScope.shop => BuyV2Destination.shop,
        BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
        BuyV2CartScope.medicine => BuyV2Destination.medicine,
        BuyV2CartScope.all =>
          destination == BuyV2Destination.orders
              ? BuyV2Destination.shop
              : destination,
      };
      cartScope = BuyV2CartScope.all;
      view = BuyV2View.catalogue;
      notice = null;
      _notifyNavigationIfChanged(
        previous,
        BuyV2NavigationMotionDirection.replace,
      );
      return;
    }
    cartScope = scope;
    view = BuyV2View.cart;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
  }

  bool openCheckout() {
    final previous = _navigationSurfaceIdentity;
    if (cartLines.isEmpty) {
      _clearCheckoutPromiseSnapshot();
      view = BuyV2View.catalogue;
      notice = 'Choose a product to continue.';
      _notifyNavigationIfChanged(
        previous,
        BuyV2NavigationMotionDirection.replace,
      );
      return false;
    }
    if (selectedAddressOrNull == null) {
      _clearCheckoutPromiseSnapshot();
      view = BuyV2View.cart;
      notice = 'Choose a delivery address to continue.';
      _notifyNavigationIfChanged(
        previous,
        BuyV2NavigationMotionDirection.replace,
      );
      return false;
    } else {
      checkoutScope = cartScope;
      view = BuyV2View.checkout;
      if (!checkoutRequiresResolution) {
        checkoutSubmissionState = BuyV2CheckoutSubmissionState.idle;
      }
      notice = null;
      _captureCheckoutPromiseSnapshot();
      _invalidateAndRefreshCheckoutPricingContracts();
    }
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
    return true;
  }

  void openOrders() {
    _clearRecoveryOriginIfActive();
    _accountChildReturnActive = false;
    query = '';
    selectedFilter = null;
    _openOrdersRoot();
  }

  void _openOrdersRoot({
    BuyV2NavigationMotionDirection direction =
        BuyV2NavigationMotionDirection.replace,
  }) {
    final previous = _navigationSurfaceIdentity;
    destination = BuyV2Destination.orders;
    view = BuyV2View.catalogue;
    ordersTab = BuyV2OrdersTab.active;
    notice = null;
    _notifyNavigationIfChanged(previous, direction);
  }

  void openOrdersFromAccount() {
    if (view != BuyV2View.account) {
      openOrders();
      return;
    }
    _accountChildReturnActive = true;
    query = '';
    selectedFilter = null;
    _openOrdersRoot(direction: BuyV2NavigationMotionDirection.forward);
  }

  void openWholesaleFromAccount() {
    if (view != BuyV2View.account) {
      openDestination(BuyV2Destination.wholesale);
      return;
    }
    final previous = _navigationSurfaceIdentity;
    _accountChildReturnActive = true;
    destination = BuyV2Destination.wholesale;
    view = BuyV2View.catalogue;
    query = '';
    selectedFilter = null;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
  }

  bool openTracking(String orderId) {
    final previous = _navigationSurfaceIdentity;
    destination = BuyV2Destination.orders;
    final orderExists = _orders.any((order) => order.id == orderId);
    if (!orderExists) {
      _selectedOrderId = null;
      view = BuyV2View.catalogue;
      notice = 'This order could not be found.';
      _notifyNavigationIfChanged(
        previous,
        BuyV2NavigationMotionDirection.replace,
      );
      return false;
    }
    _selectedOrderId = orderId;
    view = BuyV2View.tracking;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
    if (balancePaymentAdapter != null) {
      unawaited(restoreBalancePayment(orderId));
    }
    if (deliveryExceptionAdapter != null) {
      unawaited(restoreDeliveryException(orderId));
    }
    return true;
  }

  void returnToOrders() {
    final previous = _navigationSurfaceIdentity;
    destination = BuyV2Destination.orders;
    view = BuyV2View.catalogue;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  bool openOrderItems(String orderId) {
    final order = _orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    if (order == null) {
      notice = 'This order could not be found.';
      notifyListeners();
      return false;
    }
    final previous = _navigationSurfaceIdentity;
    _selectedOrderId = order.id;
    destination = BuyV2Destination.orders;
    view = BuyV2View.orderItems;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
    return true;
  }

  List<BuyV2Product> productsForOrder(BuyV2Order order) {
    return order.productIds
        .map(findProduct)
        .whereType<BuyV2Product>()
        .where((product) => product.destination == order.destination)
        .toList(growable: false);
  }

  void toggleTrackingAlerts() {
    if (!reviewDataEnabled) {
      notice = 'Order alerts are unavailable right now.';
      notifyListeners();
      return;
    }
    trackingAlertsEnabled = !trackingAlertsEnabled;
    notice = trackingAlertsEnabled
        ? 'Live order alerts are on.'
        : 'Live order alerts are paused.';
    notifyListeners();
  }

  Future<void> restoreOrderAlerts() async {
    if (reviewDataEnabled || trackingAlertsBusy) return;
    trackingAlertsBusy = true;
    notifyListeners();
    try {
      final result = await commerceAdapter.loadOrderAlerts();
      trackingAlertsAvailable = result.available;
      trackingAlertsEnabled = result.available && result.enabled;
      notice = result.available ? null : result.customerMessage;
    } on Object {
      trackingAlertsAvailable = false;
      trackingAlertsEnabled = false;
      notice = 'Order alerts could not load. Try again.';
    } finally {
      trackingAlertsBusy = false;
      notifyListeners();
    }
  }

  Future<bool> setTrackingAlerts(bool enabled) async {
    if (trackingAlertsBusy || !trackingAlertsAvailable) return false;
    if (reviewDataEnabled) {
      trackingAlertsEnabled = enabled;
      notice = enabled ? 'Order alerts are on.' : 'Order alerts are paused.';
      notifyListeners();
      return true;
    }
    trackingAlertsBusy = true;
    notifyListeners();
    try {
      final result = await commerceAdapter.setOrderAlerts(enabled: enabled);
      trackingAlertsAvailable = result.available;
      trackingAlertsEnabled = result.available && result.enabled;
      notice = result.customerMessage;
      return result.available && result.enabled == enabled;
    } on Object {
      notice = 'Order alert preference could not be saved. Try again.';
      return false;
    } finally {
      trackingAlertsBusy = false;
      notifyListeners();
    }
  }

  void openAssist() {
    final previous = _navigationSurfaceIdentity;
    if (view != BuyV2View.assist) {
      _assistReturnDestination = destination;
      _assistReturnView = view;
    }
    view = BuyV2View.assist;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
  }

  void closeAssist() {
    final previous = _navigationSurfaceIdentity;
    destination = _assistReturnDestination;
    view = _assistReturnView;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  void openAccount() {
    if (_accountChildReturnActive) {
      returnToAccount();
      return;
    }
    final previous = _navigationSurfaceIdentity;
    if (view != BuyV2View.account) {
      _accountReturnDestination = destination;
      _accountReturnView = view;
      _accountReturnProductId = selectedProductId;
      _accountReturnOrderId = _selectedOrderId;
      _accountReturnQuery = query;
      _accountReturnFilter = selectedFilter;
    }
    view = BuyV2View.account;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
  }

  void closeAccount() {
    final previous = _navigationSurfaceIdentity;
    _accountChildReturnActive = false;
    destination = _accountReturnDestination;
    view = _accountReturnView;
    selectedProductId = _accountReturnProductId;
    _selectedOrderId = _accountReturnOrderId;
    if ((_accountReturnView == BuyV2View.tracking ||
            _accountReturnView == BuyV2View.orderItems) &&
        selectedOrderOrNull == null) {
      _accountChildReturnActive = false;
      _openOrdersRoot(direction: BuyV2NavigationMotionDirection.back);
      notice = 'This order could not be found.';
      notifyListeners();
      return;
    }
    query = _accountReturnQuery;
    selectedFilter = _accountReturnFilter;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  bool get canReturnToAccount =>
      _accountChildReturnActive && view != BuyV2View.account;

  void returnToAccount() {
    if (!_accountChildReturnActive) return;
    final previous = _navigationSurfaceIdentity;
    _accountChildReturnActive = false;
    destination = _accountReturnDestination;
    view = BuyV2View.account;
    query = _accountReturnQuery;
    selectedFilter = _accountReturnFilter;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  bool get canHandleBack =>
      canReturnToAccount ||
      view != BuyV2View.catalogue ||
      destination != BuyV2Destination.shop;

  void goBack() {
    if (view == BuyV2View.checkout && checkoutBusy) {
      notice = 'Keep Checkout open while your payment status is checked.';
      notifyListeners();
      return;
    }
    _handlingBackNavigation = true;
    try {
      switch (view) {
        case BuyV2View.account:
          closeAccount();
        case BuyV2View.product:
          closeProduct();
        case BuyV2View.cart:
          returnToCatalogue();
        case BuyV2View.checkout:
          openCart(scope: checkoutScope);
        case BuyV2View.confirmation:
          _openOrdersRoot();
        case BuyV2View.tracking:
          returnToOrders();
        case BuyV2View.orderItems:
          final order = selectedOrderOrNull;
          if (order == null) {
            _openOrdersRoot();
            notice = 'This order could not be found.';
            notifyListeners();
          } else {
            openTracking(order.id);
          }
        case BuyV2View.assist:
          closeAssist();
        case BuyV2View.recovery:
          _restoreRecoveryOrigin();
        case BuyV2View.catalogue:
          if (canReturnToAccount) {
            returnToAccount();
          } else if (destination != BuyV2Destination.shop) {
            openDestination(BuyV2Destination.shop);
          }
      }
    } finally {
      _handlingBackNavigation = false;
    }
  }

  void showOrdersTab(BuyV2OrdersTab value) {
    destination = BuyV2Destination.orders;
    view = BuyV2View.catalogue;
    ordersTab = value;
    notifyListeners();
  }

  void returnToCatalogue() {
    final previous = _navigationSurfaceIdentity;
    if (destination == BuyV2Destination.orders) {
      view = BuyV2View.catalogue;
    } else {
      view = BuyV2View.catalogue;
    }
    selectedProductId = null;
    notice = null;
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  BuyV2CustomerReview? customerReviewFor(String productId) {
    final product = findProduct(productId);
    return product == null ? null : _customerReviews[product.canonicalId];
  }

  bool submitProductReview({
    required String productId,
    required int rating,
    required String comment,
  }) {
    final product = findProduct(productId);
    final cleanComment = comment.trim();
    if (product == null || rating < 1 || rating > 5 || cleanComment.isEmpty) {
      notice = 'Add a rating and a short review to continue.';
      notifyListeners();
      return false;
    }
    _customerReviews[product.canonicalId] = BuyV2CustomerReview(
      productCanonicalId: product.canonicalId,
      rating: rating,
      comment: cleanComment,
      updatedLabel: 'Added just now',
    );
    notice = 'Your review was added.';
    notifyListeners();
    return true;
  }

  bool hasReportedProduct(String productId) {
    final product = findProduct(productId);
    return product != null &&
        _reportedProductReasons.containsKey(product.canonicalId);
  }

  bool reportProduct({required String productId, required String reason}) {
    final product = findProduct(productId);
    final cleanReason = reason.trim();
    if (product == null || cleanReason.isEmpty) {
      notice = 'Choose what needs attention.';
      notifyListeners();
      return false;
    }
    _reportedProductReasons[product.canonicalId] = cleanReason;
    notice = 'Report received. We will review these product details.';
    notifyListeners();
    return true;
  }

  Future<bool> submitProductReviewOnline({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    if (reviewDataEnabled) {
      return submitProductReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );
    }
    final product = findProduct(productId);
    final cleanComment = comment.trim();
    if (product == null || rating < 1 || rating > 5 || cleanComment.isEmpty) {
      notice = 'Add a rating and a short review to continue.';
      notifyListeners();
      return false;
    }
    if (!canReviewProduct(productId)) {
      notice = 'You can review this product after a delivered purchase.';
      notifyListeners();
      return false;
    }
    if (!_productFeedbackBusyIds.add(productId)) return false;
    notice = null;
    notifyListeners();
    try {
      final result = await commerceAdapter.submitProductReview(
        product: product,
        rating: rating,
        comment: cleanComment,
      );
      if (result.accepted) {
        _customerReviews[product.canonicalId] = BuyV2CustomerReview(
          productCanonicalId: product.canonicalId,
          rating: rating,
          comment: cleanComment,
          updatedLabel: 'Added just now',
        );
      }
      notice = result.customerMessage;
      return result.accepted;
    } on Object {
      notice =
          'Your review could not be sent. Check your connection and retry.';
      return false;
    } finally {
      _productFeedbackBusyIds.remove(productId);
      notifyListeners();
    }
  }

  Future<bool> reportProductOnline({
    required String productId,
    required String reason,
  }) async {
    if (reviewDataEnabled) {
      return reportProduct(productId: productId, reason: reason);
    }
    final product = findProduct(productId);
    final cleanReason = reason.trim();
    if (product == null || cleanReason.isEmpty) {
      notice = 'Choose what needs attention.';
      notifyListeners();
      return false;
    }
    if (!canReportProduct(productId)) {
      notice = 'Product reporting is unavailable right now. Try again later.';
      notifyListeners();
      return false;
    }
    if (!_productFeedbackBusyIds.add(productId)) return false;
    notice = null;
    notifyListeners();
    try {
      final result = await commerceAdapter.reportProduct(
        product: product,
        reason: cleanReason,
      );
      if (result.accepted) {
        _reportedProductReasons[product.canonicalId] = cleanReason;
      }
      notice = result.customerMessage;
      return result.accepted;
    } on Object {
      notice =
          'This report could not be sent. Check your connection and retry.';
      return false;
    } finally {
      _productFeedbackBusyIds.remove(productId);
      notifyListeners();
    }
  }

  void chooseCategory(String id) {
    switch (destination) {
      case BuyV2Destination.shop:
        shopCategoryId = id;
      case BuyV2Destination.wholesale:
        wholesaleCategoryId = id;
      case BuyV2Destination.medicine:
        medicineCategoryId = id;
      case BuyV2Destination.orders:
        break;
    }
    query = '';
    notice = null;
    notifyListeners();
  }

  void updateQuery(String value) {
    query = value;
    notifyListeners();
  }

  bool broadenProductSearchScope() {
    if (!hasNarrowedProductSearchScope) return false;
    switch (destination) {
      case BuyV2Destination.shop:
        shopCategoryId = 'all';
      case BuyV2Destination.wholesale:
        wholesaleCategoryId = 'all';
      case BuyV2Destination.medicine:
        medicineCategoryId = 'all';
      case BuyV2Destination.orders:
        return false;
    }
    selectedFilter = null;
    activeShoppingIntent = null;
    notice = null;
    notifyListeners();
    return true;
  }

  void chooseFilter(String? value) {
    selectedFilter = value;
    notifyListeners();
  }

  void chooseShoppingIntent(BuyV2ShoppingIntent intent) {
    final target = switch (intent) {
      BuyV2ShoppingIntent.monthlyBasket ||
      BuyV2ShoppingIntent.homeShopping => BuyV2Destination.shop,
      BuyV2ShoppingIntent.businessBuying ||
      BuyV2ShoppingIntent.flexibleRestocking => BuyV2Destination.wholesale,
    };
    openDestination(target);
    activeShoppingIntent = intent;
    switch (target) {
      case BuyV2Destination.shop:
        shopCategoryId = 'all';
      case BuyV2Destination.wholesale:
        wholesaleCategoryId = 'all';
      case BuyV2Destination.medicine || BuyV2Destination.orders:
        break;
    }
    selectedFilter = intent == BuyV2ShoppingIntent.flexibleRestocking
        ? 'moq'
        : null;
    notice = null;
    _persistCustomerState();
    notifyListeners();
  }

  void clearShoppingIntent() {
    if (activeShoppingIntent == null) return;
    activeShoppingIntent = null;
    selectedFilter = null;
    notice = 'Showing all ${destination.label} products.';
    _persistCustomerState();
    notifyListeners();
  }

  bool _holdCartForPaymentResolution() {
    if (!checkoutRequiresResolution) return false;
    notice =
        'Check the current payment before changing your Cart or payment method.';
    notifyListeners();
    return true;
  }

  bool addProduct(String id) {
    if (_holdCartForPaymentResolution()) return false;
    final item = findProduct(id);
    if (item == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    if (item.destination == BuyV2Destination.wholesale && !businessVerified) {
      notice =
          'Complete your Workspace business profile to place a wholesale order.';
      notifyListeners();
      return false;
    }
    if (item.requiresPrescription &&
        !_prescriptionApprovedQuantities.containsKey(item.id)) {
      pendingPrescriptionProductId = item.id;
      notice = null;
      notifyListeners();
      return false;
    }
    final current = _cart[id];
    final approvedMaximum = _prescriptionApprovedQuantities[item.id];
    if (approvedMaximum != null &&
        (current?.quantity ?? 0) + item.minimumOrder > approvedMaximum) {
      notice = 'Prescription quantity reached for ${item.title}.';
      notifyListeners();
      return false;
    }
    _cart[id] = BuyV2CartLine(
      product: item,
      quantity: (current?.quantity ?? 0) + item.minimumOrder,
    );
    _pruneCartSelections();
    final unitLabel = itemCount == 1 ? 'item' : 'items';
    _acknowledgeCart('${item.title} added · $itemCount $unitLabel');
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  bool approveSavedPrescription(String prescriptionId) {
    final matched = switch (prescriptionId) {
      'meera' => const {'m-telmisartan-40': 1, 'm-atorvastatin-10': 1},
      'arvind' => const {'m-metformin-500': 1, 'm-pantoprazole-40': 1},
      _ => null,
    };
    if (matched == null) {
      notice = 'This saved prescription could not be found.';
      notifyListeners();
      return false;
    }
    prescriptionAttached = true;
    _prescriptionApprovedQuantities.addAll(matched);
    final pending = pendingPrescriptionProductId;
    pendingPrescriptionProductId = null;
    if (pending != null &&
        _prescriptionApprovedQuantities.containsKey(pending)) {
      addProduct(pending);
      return true;
    }
    notice = '${matched.length} prescribed medicines are ready to add.';
    notifyListeners();
    return true;
  }

  bool attachNewPrescription() {
    prescriptionAttached = true;
    const matched = {
      'm-telmisartan-40': 1,
      'm-atorvastatin-10': 1,
      'm-metformin-500': 1,
    };
    _prescriptionApprovedQuantities.addAll(matched);
    final pending = pendingPrescriptionProductId;
    pendingPrescriptionProductId = null;
    if (pending != null &&
        _prescriptionApprovedQuantities.containsKey(pending)) {
      addProduct(pending);
      return true;
    }
    notice = '${matched.length} matched medicines are ready to add.';
    notifyListeners();
    return true;
  }

  bool isPrescriptionApproved(String id) =>
      _prescriptionApprovedQuantities.containsKey(id);

  int get approvedPrescriptionProductCount =>
      _prescriptionApprovedQuantities.length;

  List<BuyV2Product> get matchedPrescriptionProducts => List.unmodifiable(
    _catalogueProducts.where(
      (product) =>
          product.destination == BuyV2Destination.medicine &&
          _prescriptionApprovedQuantities.containsKey(product.id),
    ),
  );

  int? prescriptionMaximumFor(String id) => _prescriptionApprovedQuantities[id];

  int quantityFor(String id) => _cart[id]?.quantity ?? 0;

  void increase(String id) {
    if (_holdCartForPaymentResolution()) return;
    final current = _cart[id];
    if (current == null) {
      addProduct(id);
      return;
    }
    final approvedMaximum = _prescriptionApprovedQuantities[id];
    if (approvedMaximum != null && current.quantity >= approvedMaximum) {
      notice = 'Prescription quantity reached for ${current.product.title}.';
      notifyListeners();
      return;
    }
    _cart[id] = current.copyWith(quantity: current.quantity + 1);
    _pruneCartSelections();
    _acknowledgeCart(
      '${current.product.title} · ${current.quantity + 1} in cart',
    );
    _persistCustomerState();
    notifyListeners();
  }

  void decrease(String id) {
    if (_holdCartForPaymentResolution()) return;
    final previous = _navigationSurfaceIdentity;
    final current = _cart[id];
    if (current == null) return;
    final minimum = current.product.minimumOrder;
    if (current.quantity <= minimum) {
      _cart.remove(id);
      _acknowledgeCart('${current.product.title} removed');
    } else {
      _cart[id] = current.copyWith(quantity: current.quantity - 1);
      _acknowledgeCart(
        '${current.product.title} · ${current.quantity - 1} in cart',
      );
    }
    if (_cart.isEmpty) {
      destination = current.product.destination;
      view = BuyV2View.catalogue;
      cartScope = BuyV2CartScope.all;
    }
    _pruneCartSelections();
    _persistCustomerState();
    if (_cart.isEmpty) {
      _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    } else {
      notifyListeners();
    }
  }

  void remove(String id) {
    if (_holdCartForPaymentResolution()) return;
    final previous = _navigationSurfaceIdentity;
    final removed = _cart.remove(id);
    if (removed == null) return;
    _acknowledgeCart('${removed.product.title} removed');
    if (_cart.isEmpty) {
      destination = removed.product.destination;
      view = BuyV2View.catalogue;
      cartScope = BuyV2CartScope.all;
    }
    _pruneCartSelections();
    _persistCustomerState();
    if (_cart.isEmpty) {
      _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    } else {
      notifyListeners();
    }
  }

  void clearCart() {
    if (_holdCartForPaymentResolution()) return;
    final previous = _navigationSurfaceIdentity;
    final fallback = switch (cartScope) {
      BuyV2CartScope.shop => BuyV2Destination.shop,
      BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
      BuyV2CartScope.medicine => BuyV2Destination.medicine,
      BuyV2CartScope.all =>
        destination == BuyV2Destination.orders
            ? BuyV2Destination.shop
            : destination,
    };
    _cart.clear();
    _deliveryInstructionIds.clear();
    _selectedCartBenefitRefs.clear();
    _tipsByFulfilmentKey.clear();
    destination = fallback;
    view = BuyV2View.catalogue;
    cartScope = BuyV2CartScope.all;
    notice = null;
    cartAcknowledgement = null;
    _persistCustomerState();
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
  }

  void chooseCartScope(BuyV2CartScope value) {
    cartScope = value;
    notifyListeners();
  }

  bool chooseAddress(String id) {
    if (!_addresses.any((address) => address.id == id)) {
      notice = 'This saved address could not be found.';
      notifyListeners();
      return false;
    }
    _selectedAddressId = id;
    notice = 'Delivering to ${selectedAddress.shortLine}';
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  void addAddress(BuyV2Address address) {
    _addresses.add(address);
    _selectedAddressId = address.id;
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = 'Delivering to ${address.shortLine}';
    _persistCustomerState();
    notifyListeners();
  }

  bool updateAddress(BuyV2Address address) {
    final index = _addresses.indexWhere(
      (candidate) => candidate.id == address.id,
    );
    if (index < 0) {
      notice = 'This saved address is no longer available.';
      notifyListeners();
      return false;
    }
    _addresses[index] = address;
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = '${address.label} address updated';
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  bool removeAddress(String id) {
    final index = _addresses.indexWhere((address) => address.id == id);
    if (index < 0) {
      notice = 'This saved address is no longer available.';
      notifyListeners();
      return false;
    }
    final removed = _addresses.removeAt(index);
    if (_selectedAddressId == id) {
      _selectedAddressId = _addresses.firstOrNull?.id;
    }
    _invalidateAndRefreshCheckoutPricingContracts();
    notice = '${removed.label} address removed';
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  bool choosePayment(String value) {
    if (_holdCartForPaymentResolution()) return false;
    if (!availablePaymentMethods.contains(value)) {
      notice = 'This payment method is not available.';
      notifyListeners();
      return false;
    }
    if (value == 'Purchase order' &&
        view == BuyV2View.checkout &&
        !purchaseOrderEligibleForCheckout) {
      notice = purchaseOrderEligibilityMessage;
      notifyListeners();
      return false;
    }
    selectedPayment = value;
    _invalidateLiveCartBenefits();
    if (_cart.isNotEmpty && liveCartBenefitsEnabled) {
      unawaited(refreshCartBenefits());
    }
    _invalidateCheckoutQuote();
    if (_cart.isNotEmpty && checkoutQuoteEnabled) {
      unawaited(refreshCheckoutQuote());
    }
    _invalidateCommercialPaymentTerms();
    if (_cart.isNotEmpty &&
        commercialPaymentTermsEnabled &&
        !checkoutQuoteEnabled) {
      unawaited(refreshCommercialPaymentTerms());
    }
    notice = '$value selected';
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  bool confirmOrder() {
    if (!reviewDataEnabled) {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.unavailable;
      notice = 'Ordering is unavailable right now. Your Cart has not changed.';
      notifyListeners();
      return false;
    }
    final previous = _navigationSurfaceIdentity;
    final lines = checkoutLines;
    if (lines.isEmpty) {
      returnToCatalogue();
      return false;
    }
    final address = selectedAddressOrNull;
    if (address == null) {
      view = BuyV2View.cart;
      notice = 'Choose a delivery address to continue.';
      _notifyNavigationIfChanged(
        previous,
        BuyV2NavigationMotionDirection.replace,
      );
      return false;
    }
    if (checkoutPromiseReviewRequired) {
      notice = 'Review and accept the updated delivery times to continue.';
      notifyListeners();
      return false;
    }
    for (final product in lines.map((line) => line.product).toSet()) {
      final next = productFactsAdapter.snapshotFor(product);
      if (!_validProductFacts(product, next)) {
        notice = 'Delivery times could not be confirmed. Try again.';
        notifyListeners();
        return false;
      }
      final availability = next.orderabilityLabel.toLowerCase();
      if (availability.contains('unavailable') ||
          availability.contains('out of stock') ||
          availability.contains('not available')) {
        _checkoutAvailabilityIssue = (
          productId: product.id,
          title: product.title,
          orderabilityLabel: next.orderabilityLabel,
        );
        openRecovery(BuyV2RecoveryKind.stockUnavailable);
        return false;
      }
      _productFacts[product.id] = next;
    }
    final groups = checkoutFulfilmentGroups;
    final refreshedSnapshot = _deliveryPromiseSnapshotFor(groups);
    if (_checkoutPromiseSnapshot.isEmpty) {
      _checkoutPromiseSnapshot = refreshedSnapshot;
    }
    if (!mapEquals(_checkoutPromiseSnapshot, refreshedSnapshot)) {
      final changedKeys = {
        ..._checkoutPromiseSnapshot.keys,
        ...refreshedSnapshot.keys,
      }.where((key) => _checkoutPromiseSnapshot[key] != refreshedSnapshot[key]);
      _checkoutDeliveryPromiseChanges = [
        for (final key in changedKeys)
          (
            groupKey: key,
            previousPromise:
                _checkoutPromiseSnapshot[key]?.promise ?? 'Not quoted',
            previousPromisedByLabel:
                _checkoutPromiseSnapshot[key]?.promisedByLabel,
            currentPromise: refreshedSnapshot[key]?.promise ?? 'Unavailable',
            currentPromisedByLabel: refreshedSnapshot[key]?.promisedByLabel,
          ),
      ];
      _pendingCheckoutPromiseSnapshot = refreshedSnapshot;
      notice = 'Delivery times changed. Review the updated plan.';
      notifyListeners();
      return false;
    }
    final purchaseId =
        'BUY-NEW-${(_purchaseSequence++).toString().padLeft(2, '0')}';
    _confirmedPurchaseId = purchaseId;
    _confirmedOrders = _createOrdersForGroups(groups, address, purchaseId);
    _completeConfirmedOrder(previous: previous, lines: lines);
    return true;
  }

  Future<bool> submitOrder() {
    if (selectedPayment == 'Purchase order' &&
        !purchaseOrderEligibleForCheckout) {
      notice = purchaseOrderEligibilityMessage;
      notifyListeners();
      return Future<bool>.value(false);
    }
    if (reviewDataEnabled && selectedPayment == 'Bank transfer') {
      return _submitOrderAsync();
    }
    if (reviewDataEnabled) {
      if ((liveCartBenefitsEnabled && _hasSelectedCartBenefitReference) ||
          checkoutQuoteEnabled ||
          commercialPaymentTermsEnabled) {
        return _submitReviewOrderWithContracts();
      }
      return Future<bool>.value(confirmOrder());
    }
    return _submitOrderAsync();
  }

  Future<bool> _submitReviewOrderWithContracts() async {
    if (liveCartBenefitsEnabled && _hasSelectedCartBenefitReference) {
      final eligible = await refreshCartBenefits();
      if (!eligible ||
          cartBenefitsLoadState != BuyV2CartBenefitsLoadState.ready) {
        notice =
            cartBenefitsMessage ??
            'Coupon eligibility could not be confirmed. Review the current options.';
        notifyListeners();
        return false;
      }
    }
    if (checkoutQuoteEnabled) {
      await refreshCheckoutQuote();
      if (checkoutQuoteReviewRequired) {
        notice =
            checkoutQuoteMessage ??
            'The current Checkout total could not be confirmed.';
        notifyListeners();
        return false;
      }
    }
    if (commercialPaymentTermsEnabled) {
      await refreshCommercialPaymentTerms();
      if (checkoutPaymentTermsReviewRequired) {
        notice =
            commercialPaymentTermsMessage ??
            'Choose an available payment term to continue.';
        notifyListeners();
        return false;
      }
    }
    return confirmOrder();
  }

  bool _refreshCheckoutFactsForProduction(List<BuyV2CartLine> lines) {
    final priceChanges = <BuyV2PriceChange>[];
    for (final product in lines.map((line) => line.product).toSet()) {
      final next = productFactsAdapter.snapshotFor(product);
      if (!_validProductFacts(product, next) || next.stale) {
        checkoutSubmissionState = BuyV2CheckoutSubmissionState.failed;
        notice =
            'Current price and availability could not be confirmed. Try again.';
        notifyListeners();
        return false;
      }
      final availability = next.orderabilityLabel.toLowerCase();
      if (availability.contains('unavailable') ||
          availability.contains('out of stock') ||
          availability.contains('not available')) {
        _checkoutAvailabilityIssue = (
          productId: product.id,
          title: product.title,
          orderabilityLabel: next.orderabilityLabel,
        );
        openRecovery(BuyV2RecoveryKind.stockUnavailable);
        return false;
      }
      if (next.price != product.price) {
        priceChanges.add((
          productId: product.id,
          title: product.title,
          previousPrice: product.price,
          currentPrice: next.price,
        ));
      }
      final updatedProduct = product.copyWith(
        price: next.price,
        deliveryPromise: next.deliveryPromise,
        seller: next.partner,
        confirmedOn: 'Checked now',
      );
      final catalogueIndex = _catalogueProducts.indexWhere(
        (candidate) => candidate.id == product.id,
      );
      if (catalogueIndex >= 0) {
        _catalogueProducts[catalogueIndex] = updatedProduct;
      }
      final cartLine = _cart[product.id];
      if (cartLine != null) {
        _cart[product.id] = cartLine.copyWith(product: updatedProduct);
      }
      _productFacts[product.id] = next;
    }
    if (priceChanges.isNotEmpty) {
      _checkoutPriceChanges = List.unmodifiable(priceChanges);
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.idle;
      _invalidateCheckoutQuote();
      _invalidateCommercialPaymentTerms();
      notice = 'Prices changed. Review the updated total to continue.';
      _persistCustomerState();
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> _submitOrderAsync() async {
    if (checkoutBusy) return false;
    final previous = _navigationSurfaceIdentity;
    final lines = checkoutLines;
    if (lines.isEmpty) {
      returnToCatalogue();
      return false;
    }
    final address = selectedAddressOrNull;
    if (address == null) {
      view = BuyV2View.cart;
      notice = 'Choose a delivery address to continue.';
      _notifyNavigationIfChanged(
        previous,
        BuyV2NavigationMotionDirection.replace,
      );
      return false;
    }
    if (checkoutPromiseReviewRequired) {
      notice = 'Review and accept the updated delivery times to continue.';
      notifyListeners();
      return false;
    }
    if (liveCartBenefitsEnabled && _hasSelectedCartBenefitReference) {
      final eligible = await refreshCartBenefits();
      if (!eligible ||
          cartBenefitsLoadState != BuyV2CartBenefitsLoadState.ready) {
        notice =
            cartBenefitsMessage ??
            'Coupon eligibility could not be confirmed. Review the current options.';
        notifyListeners();
        return false;
      }
    }
    if (!_refreshCheckoutFactsForProduction(lines)) return false;
    if (checkoutQuoteEnabled) {
      await refreshCheckoutQuote();
      if (checkoutQuoteReviewRequired) {
        notice =
            checkoutQuoteMessage ??
            'The current Checkout total could not be confirmed.';
        notifyListeners();
        return false;
      }
    }
    if (commercialPaymentTermsEnabled) {
      await refreshCommercialPaymentTerms();
      if (checkoutPaymentTermsReviewRequired) {
        notice =
            commercialPaymentTermsMessage ??
            'Choose an available payment term to continue.';
        notifyListeners();
        return false;
      }
    }
    final groups = checkoutFulfilmentGroups;
    final refreshedSnapshot = _deliveryPromiseSnapshotFor(groups);
    if (_checkoutPromiseSnapshot.isEmpty) {
      _checkoutPromiseSnapshot = refreshedSnapshot;
    }
    if (!mapEquals(_checkoutPromiseSnapshot, refreshedSnapshot)) {
      final changedKeys = {
        ..._checkoutPromiseSnapshot.keys,
        ...refreshedSnapshot.keys,
      }.where((key) => _checkoutPromiseSnapshot[key] != refreshedSnapshot[key]);
      _checkoutDeliveryPromiseChanges = [
        for (final key in changedKeys)
          (
            groupKey: key,
            previousPromise:
                _checkoutPromiseSnapshot[key]?.promise ?? 'Not quoted',
            previousPromisedByLabel:
                _checkoutPromiseSnapshot[key]?.promisedByLabel,
            currentPromise: refreshedSnapshot[key]?.promise ?? 'Unavailable',
            currentPromisedByLabel: refreshedSnapshot[key]?.promisedByLabel,
          ),
      ];
      _pendingCheckoutPromiseSnapshot = refreshedSnapshot;
      notice = 'Delivery times changed. Review the updated plan.';
      notifyListeners();
      return false;
    }
    if (checkoutPriceReviewRequired) {
      notice = 'Review and accept the updated prices to continue.';
      notifyListeners();
      return false;
    }
    if (checkoutRequiresResolution) {
      notice = 'Check the current payment before trying again.';
      notifyListeners();
      return false;
    }
    _checkoutIdempotencyKey ??=
        'shop-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
        '${_checkoutAttemptSequence++}';
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.submitting;
    notice = null;
    _persistCustomerState();
    notifyListeners();
    final placement = await commerceAdapter.placeOrder(
      BuyV2OrderPlacementRequest(
        lines: List.unmodifiable(lines),
        address: address,
        paymentMethod: selectedPayment,
        total: checkoutPayableTotal,
        amountDueNow: checkoutAmountDueNow,
        idempotencyKey: _checkoutIdempotencyKey!,
        commercialPaymentTermIds: Map.unmodifiable(
          _selectedCommercialPaymentTermIds,
        ),
        checkoutQuoteId: _checkoutQuote?.id,
      ),
    );
    return _handleOrderPlacement(
      placement: placement,
      previous: previous,
      lines: lines,
      groups: groups,
      address: address,
    );
  }

  bool _handleOrderPlacement({
    required BuyV2OrderPlacementResult placement,
    required _BuyV2NavigationSurfaceIdentity previous,
    required List<BuyV2CartLine> lines,
    required List<BuyV2FulfilmentGroup> groups,
    required BuyV2Address address,
  }) {
    _paymentReference = placement.paymentReference ?? _paymentReference;
    _paymentActionUri = placement.paymentActionUri;
    _bankTransferInstructions =
        placement.bankTransferInstructions ?? _bankTransferInstructions;
    if (placement.outcome != BuyV2OrderPlacementOutcome.confirmed &&
        _openPlacementRecovery(placement, lines)) {
      return false;
    }
    if (placement.outcome != BuyV2OrderPlacementOutcome.confirmed) {
      checkoutSubmissionState = switch (placement.outcome) {
        BuyV2OrderPlacementOutcome.paymentActionRequired
            when _validPaymentAction(placement) ||
                _validBankTransferAction(placement) =>
          BuyV2CheckoutSubmissionState.paymentActionRequired,
        BuyV2OrderPlacementOutcome.paymentActionRequired =>
          BuyV2CheckoutSubmissionState.failed,
        BuyV2OrderPlacementOutcome.paymentPending
            when _paymentReference != null =>
          BuyV2CheckoutSubmissionState.paymentPending,
        BuyV2OrderPlacementOutcome.paymentPending ||
        BuyV2OrderPlacementOutcome.paymentUnknown =>
          BuyV2CheckoutSubmissionState.paymentUnknown,
        BuyV2OrderPlacementOutcome.cancelled =>
          BuyV2CheckoutSubmissionState.cancelled,
        BuyV2OrderPlacementOutcome.unavailable =>
          BuyV2CheckoutSubmissionState.unavailable,
        BuyV2OrderPlacementOutcome.failed =>
          BuyV2CheckoutSubmissionState.failed,
        BuyV2OrderPlacementOutcome.confirmed =>
          BuyV2CheckoutSubmissionState.confirmed,
      };
      if (checkoutSubmissionState == BuyV2CheckoutSubmissionState.cancelled) {
        _checkoutIdempotencyKey = null;
        _paymentReference = null;
        _paymentActionUri = null;
        _bankTransferInstructions = null;
      }
      notice = placement.customerMessage;
      _persistCustomerState();
      notifyListeners();
      return false;
    }
    if (!reviewDataEnabled && placement.orders.isEmpty) {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.failed;
      notice =
          'Order confirmation could not be verified. Your Cart has not changed.';
      notifyListeners();
      return false;
    }
    if (!reviewDataEnabled &&
        placement.orders.fold<int>(0, (total, order) => total + order.total) !=
            checkoutPayableTotal) {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.failed;
      notice = 'Order total could not be verified. Your Cart has not changed.';
      notifyListeners();
      return false;
    }
    final purchaseId =
        placement.purchaseReference ??
        'BUY-NEW-${(_purchaseSequence++).toString().padLeft(2, '0')}';
    _confirmedPurchaseId = purchaseId;
    _confirmedOrders = placement.orders.isNotEmpty
        ? List.unmodifiable(placement.orders)
        : _createOrdersForGroups(groups, address, purchaseId);
    _completeConfirmedOrder(previous: previous, lines: lines);
    return true;
  }

  bool _openPlacementRecovery(
    BuyV2OrderPlacementResult placement,
    List<BuyV2CartLine> lines,
  ) {
    final failureKind = placement.failureKind;
    if (failureKind == null) return false;
    if (failureKind == BuyV2OrderPlacementFailureKind.stockUnavailable) {
      final productId = placement.affectedProductId?.trim();
      final line = productId == null
          ? null
          : lines
                .where((candidate) => candidate.product.id == productId)
                .firstOrNull;
      if (line == null) return false;
      _checkoutAvailabilityIssue = (
        productId: line.product.id,
        title: line.product.title,
        orderabilityLabel: placement.customerMessage,
      );
      _clearCheckoutPaymentAttempt();
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.idle;
      openRecovery(BuyV2RecoveryKind.stockUnavailable);
      return true;
    }
    _checkoutAvailabilityIssue = null;
    _clearCheckoutPaymentAttempt();
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.idle;
    openRecovery(BuyV2RecoveryKind.serviceAreaUnavailable);
    return true;
  }

  void _clearCheckoutPaymentAttempt() {
    _checkoutIdempotencyKey = null;
    _paymentReference = null;
    _paymentActionUri = null;
    _bankTransferInstructions = null;
    _persistCustomerState();
  }

  bool _validPaymentAction(BuyV2OrderPlacementResult placement) {
    final uri = placement.paymentActionUri;
    final reference = placement.paymentReference?.trim();
    return uri != null &&
        (uri.scheme == 'upi' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        reference != null &&
        reference.isNotEmpty;
  }

  bool _validBankTransferAction(BuyV2OrderPlacementResult placement) {
    final instructions = placement.bankTransferInstructions;
    final reference = placement.paymentReference?.trim();
    return selectedPayment == 'Bank transfer' &&
        instructions != null &&
        instructions.beneficiaryName.trim().isNotEmpty &&
        instructions.bankName.trim().isNotEmpty &&
        instructions.accountNumber.trim().isNotEmpty &&
        instructions.ifsc.trim().isNotEmpty &&
        instructions.transferReference.trim().isNotEmpty &&
        reference != null &&
        reference.isNotEmpty &&
        instructions.transferReference == reference;
  }

  bool markBankTransferSent() {
    if (checkoutBusy ||
        selectedPayment != 'Bank transfer' ||
        checkoutSubmissionState !=
            BuyV2CheckoutSubmissionState.paymentActionRequired ||
        _bankTransferInstructions == null ||
        _paymentReference == null) {
      return false;
    }
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.paymentPending;
    notice = 'Transfer submitted for checking. Do not transfer again.';
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  Future<bool> continuePayment(BuyV2PaymentHandoff handoff) async {
    final uri = _paymentActionUri;
    if (checkoutBusy ||
        checkoutSubmissionState !=
            BuyV2CheckoutSubmissionState.paymentActionRequired ||
        uri == null) {
      return false;
    }
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.submitting;
    notice = null;
    _persistCustomerState();
    notifyListeners();
    var opened = false;
    try {
      opened = await handoff(uri);
    } on Object {
      opened = false;
    }
    if (!opened) {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.failed;
      notice =
          'The payment app did not open. Your Cart has not changed. Try again.';
      _persistCustomerState();
      notifyListeners();
      return false;
    }
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.paymentPending;
    notice = 'Return here after payment to check your order.';
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  Future<bool> reconcilePayment() async {
    if (checkoutBusy) return false;
    final idempotencyKey = _checkoutIdempotencyKey;
    final paymentReference = _paymentReference;
    final address = selectedAddressOrNull;
    final lines = checkoutLines;
    if (idempotencyKey == null ||
        paymentReference == null ||
        address == null ||
        lines.isEmpty) {
      checkoutSubmissionState = BuyV2CheckoutSubmissionState.paymentUnknown;
      notice =
          'Payment status could not be matched. Do not pay again. Get order help.';
      _persistCustomerState();
      notifyListeners();
      return false;
    }
    final previous = _navigationSurfaceIdentity;
    final groups = checkoutFulfilmentGroups;
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.submitting;
    notice = null;
    _persistCustomerState();
    notifyListeners();
    final placement = await commerceAdapter.reconcileOrder(
      idempotencyKey: idempotencyKey,
      paymentReference: paymentReference,
    );
    return _handleOrderPlacement(
      placement: placement,
      previous: previous,
      lines: lines,
      groups: groups,
      address: address,
    );
  }

  bool cancelPaymentAttempt() {
    if (checkoutBusy ||
        checkoutSubmissionState !=
            BuyV2CheckoutSubmissionState.paymentActionRequired) {
      return false;
    }
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.cancelled;
    _checkoutIdempotencyKey = null;
    _paymentReference = null;
    _paymentActionUri = null;
    _bankTransferInstructions = null;
    notice = 'Payment cancelled. Your Cart has not changed.';
    _persistCustomerState();
    notifyListeners();
    return true;
  }

  void _completeConfirmedOrder({
    required _BuyV2NavigationSurfaceIdentity previous,
    required List<BuyV2CartLine> lines,
  }) {
    _orders.insertAll(0, _confirmedOrders);
    _confirmedDestinations = _confirmedOrders
        .map((order) => order.destination)
        .toSet();
    _confirmedItemCount = checkoutItemCount;
    _confirmedTotal = checkoutPayableTotal;
    _confirmedAmountPaidNow = checkoutAmountDueNow;
    _confirmedBalanceDue = checkoutBalanceDue;
    for (final line in lines) {
      _cart.remove(line.product.id);
    }
    _pruneCartSelections();
    cartScope = BuyV2CartScope.all;
    checkoutScope = BuyV2CartScope.all;
    destination = BuyV2Destination.orders;
    view = BuyV2View.confirmation;
    checkoutSubmissionState = BuyV2CheckoutSubmissionState.confirmed;
    _checkoutIdempotencyKey = null;
    _paymentReference = null;
    _paymentActionUri = null;
    _bankTransferInstructions = null;
    notice = null;
    _clearCheckoutPromiseSnapshot();
    _persistCustomerState();
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
  }

  List<BuyV2Order> _createOrdersForGroups(
    List<BuyV2FulfilmentGroup> groups,
    BuyV2Address address,
    String purchaseId,
  ) {
    final discountByKey = _checkoutGroupCouponSavings();
    final quoteLineByKey = {
      for (final line
          in _checkoutQuote?.lines ?? const <BuyV2CheckoutQuoteLine>[])
        line.fulfilmentKey: line,
    };
    return List.unmodifiable([
      for (final group in groups)
        () {
          final quoteLine = quoteLineByKey[group.key];
          return _createOrderForGroup(
            group,
            address,
            purchaseId,
            discount:
                quoteLine?.couponSaving ?? (discountByKey[group.key] ?? 0),
            tax: quoteLine?.tax ?? 0,
            freight: quoteLine?.freight ?? 0,
            deliveryFee: quoteLine?.deliveryFee ?? 0,
            paymentCharge: quoteLine?.paymentCharge ?? 0,
            totalOverride: quoteLine?.total,
          );
        }(),
    ]);
  }

  BuyV2Order _createOrderForGroup(
    BuyV2FulfilmentGroup group,
    BuyV2Address address,
    String purchaseId, {
    int discount = 0,
    int tax = 0,
    int freight = 0,
    int deliveryFee = 0,
    int paymentCharge = 0,
    int? totalOverride,
  }) {
    final sequence = _orderSequence++;
    final prefix = switch (group.destination) {
      BuyV2Destination.shop => 'MS',
      BuyV2Destination.wholesale => 'PO',
      BuyV2Destination.medicine => 'RX',
      BuyV2Destination.orders => 'MS',
    };
    final itemName = switch (group.destination) {
      BuyV2Destination.shop => group.itemCount == 1 ? 'product' : 'products',
      BuyV2Destination.wholesale =>
        group.itemCount == 1 ? 'trade pack' : 'trade packs',
      BuyV2Destination.medicine =>
        group.itemCount == 1 ? 'medicine' : 'medicines',
      BuyV2Destination.orders => 'products',
    };
    final status = group.destination == BuyV2Destination.wholesale
        ? BuyV2OrderStatus.confirmed
        : BuyV2OrderStatus.preparing;
    final paymentTerm = selectedCommercialPaymentTermFor(group.key);
    return BuyV2Order(
      id: '$prefix-NEW-${sequence.toString().padLeft(2, '0')}',
      destination: group.destination,
      title: '${group.destination.label} order',
      itemSummary:
          '${group.itemCount} $itemName · ${address.label} · ${address.area}',
      total:
          totalOverride ??
          group.total +
              tipForGroup(group) -
              discount +
              tax +
              freight +
              deliveryFee +
              paymentCharge,
      partner: group.partner,
      partnerType: group.partnerType,
      promise: group.promise,
      destinationLabel: address.shortLine,
      progress: status == BuyV2OrderStatus.confirmed ? .34 : .2,
      status: status,
      purchaseId: purchaseId,
      promisedByLabel: group.promisedByLabel,
      productIds: group.productIds,
      lines: List.unmodifiable(group.lines),
      paymentMethod: selectedPayment,
      recipient: address.recipient,
      addressLine: '${address.line}, ${address.area} ${address.pinCode}',
      deliveryInstruction: selectedDeliveryInstructionFor(
        group.destination,
      )?.label,
      tip: tipForGroup(group),
      discount: discount,
      paymentTermLabel: paymentTerm == null
          ? null
          : _commercialPaymentTermLabel(paymentTerm.kind),
      amountPaidNow: paymentTerm?.amountDueNow,
      balanceDue: paymentTerm?.balanceDue ?? 0,
      balanceDueLabel: paymentTerm?.balanceDueLabel,
      paymentStatusLabel: paymentTerm == null
          ? null
          : paymentTerm.balanceDue == 0
          ? 'Paid in full'
          : 'Booking amount paid · balance ${paymentTerm.balanceDueLabel}',
      buyerName: group.destination == BuyV2Destination.wholesale
          ? 'Shree Balaji Retail'
          : null,
      buyerType: group.destination == BuyV2Destination.wholesale
          ? 'Verified retailer Workspace'
          : null,
      tax: tax,
      freight: freight,
      deliveryFee: deliveryFee,
      paymentCharge: paymentCharge,
      dispatchPromise: group.dispatchPromise,
      deliveryPartnerName: group.deliveryProviderName,
      deliveryPartnerType: group.deliveryProviderName == null
          ? null
          : 'Delivery partner',
      deliveryServiceLevel: group.deliveryServiceLevel,
    );
  }

  bool acceptCheckoutPromiseChanges() {
    final pending = _pendingCheckoutPromiseSnapshot;
    if (pending == null) return false;
    _checkoutPromiseSnapshot = Map.unmodifiable(pending);
    _pendingCheckoutPromiseSnapshot = null;
    _checkoutDeliveryPromiseChanges = [];
    notice = null;
    notifyListeners();
    return true;
  }

  void _pruneCartSelections() {
    final destinations = _cart.values
        .map((line) => line.product.destination)
        .toSet();
    _deliveryInstructionIds.removeWhere(
      (destination, _) => !destinations.contains(destination),
    );
    _selectedCartBenefitRefs.removeWhere((key, _) {
      final destinationName = key.split('|').firstOrNull;
      return !destinations.any(
        (destination) => destination.name == destinationName,
      );
    });
    final groupKeys = _fulfilmentGroupsFor(
      _cart.values.toList(growable: false),
    ).map((group) => group.key).toSet();
    _tipsByFulfilmentKey.removeWhere((key, _) => !groupKeys.contains(key));
    _invalidateLiveCartBenefits();
    if (_cart.isNotEmpty && liveCartBenefitsEnabled) {
      unawaited(refreshCartBenefits());
    }
    _invalidateCheckoutQuote();
    if (_cart.isNotEmpty && checkoutQuoteEnabled) {
      unawaited(refreshCheckoutQuote());
    }
    _invalidateCommercialPaymentTerms();
    if (_cart.isNotEmpty &&
        commercialPaymentTermsEnabled &&
        !checkoutQuoteEnabled) {
      unawaited(refreshCommercialPaymentTerms());
    }
  }

  bool reorder(BuyV2Order order) {
    final ids = order.productIds.toList(growable: false);
    final products = ids.map(findProduct).toList(growable: false);
    if (ids.isEmpty ||
        ids.toSet().length != ids.length ||
        products.any(
          (product) =>
              product == null || product.destination != order.destination,
        )) {
      notice = 'Products from this order could not be found.';
      notifyListeners();
      return false;
    }

    final exactProducts = products.whereType<BuyV2Product>().toList(
      growable: false,
    );
    if (order.destination == BuyV2Destination.wholesale && !businessVerified) {
      notice =
          'Complete your Workspace business profile to place a wholesale order.';
      notifyListeners();
      return false;
    }
    if (exactProducts.any(
      (product) =>
          product.requiresPrescription &&
          !_prescriptionApprovedQuantities.containsKey(product.id),
    )) {
      notice = 'Prescription review is required before reordering medicines.';
      notifyListeners();
      return false;
    }
    for (final product in exactProducts) {
      final approvedMaximum = _prescriptionApprovedQuantities[product.id];
      final nextQuantity =
          (_cart[product.id]?.quantity ?? 0) + product.minimumOrder;
      if (approvedMaximum != null && nextQuantity > approvedMaximum) {
        notice = 'Prescription quantity reached for ${product.title}.';
        notifyListeners();
        return false;
      }
    }

    final previous = _navigationSurfaceIdentity;
    destination = order.destination;
    for (final product in exactProducts) {
      final current = _cart[product.id];
      _cart[product.id] = BuyV2CartLine(
        product: product,
        quantity: (current?.quantity ?? 0) + product.minimumOrder,
      );
    }
    cartScope = switch (order.destination) {
      BuyV2Destination.shop => BuyV2CartScope.shop,
      BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
      BuyV2Destination.medicine => BuyV2CartScope.medicine,
      BuyV2Destination.orders => BuyV2CartScope.all,
    };
    view = BuyV2View.cart;
    notice = 'Previous products are ready to edit.';
    cartAcknowledgement = 'Previous products are ready to edit.';
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
    return true;
  }

  void openRecovery(BuyV2RecoveryKind kind) {
    final previous = _navigationSurfaceIdentity;
    if (kind != BuyV2RecoveryKind.stockUnavailable) {
      _checkoutAvailabilityIssue = null;
    }
    if (view != BuyV2View.recovery) {
      _recoveryOrigin = (
        destination: destination,
        view: view,
        cartScope: cartScope,
        checkoutScope: checkoutScope,
        ordersTab: ordersTab,
        shopCategoryId: shopCategoryId,
        wholesaleCategoryId: wholesaleCategoryId,
        medicineCategoryId: medicineCategoryId,
        query: query,
        filter: selectedFilter,
        productId: selectedProductId,
        orderId: _selectedOrderId,
      );
    }
    recoveryKind = kind;
    view = BuyV2View.recovery;
    notice = null;
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
  }

  void retryRecovery() {
    _restoreRecoveryOrigin();
  }

  bool retryCheckoutAvailability() {
    final issue = _checkoutAvailabilityIssue;
    if (recoveryKind != BuyV2RecoveryKind.stockUnavailable || issue == null) {
      return false;
    }
    final product = findProduct(issue.productId);
    if (product == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    final next = productFactsAdapter.snapshotFor(product);
    if (!_validProductFacts(product, next) || next.stale) {
      notice = 'Availability could not be confirmed. Try again.';
      notifyListeners();
      return false;
    }
    final availability = next.orderabilityLabel.toLowerCase();
    if (availability.contains('unavailable') ||
        availability.contains('out of stock') ||
        availability.contains('not available')) {
      _checkoutAvailabilityIssue = (
        productId: product.id,
        title: product.title,
        orderabilityLabel: next.orderabilityLabel,
      );
      notice = '${product.title} is still unavailable.';
      notifyListeners();
      return false;
    }
    final previous = _navigationSurfaceIdentity;
    final updatedProduct = product.copyWith(
      price: next.price,
      deliveryPromise: next.deliveryPromise,
      seller: next.partner,
      confirmedOn: 'Checked now',
    );
    final catalogueIndex = _catalogueProducts.indexWhere(
      (candidate) => candidate.id == product.id,
    );
    if (catalogueIndex >= 0) {
      _catalogueProducts[catalogueIndex] = updatedProduct;
    }
    final cartLine = _cart[product.id];
    if (cartLine != null) {
      _cart[product.id] = cartLine.copyWith(product: updatedProduct);
    }
    _productFacts[product.id] = next;
    if (next.price != product.price) {
      _checkoutPriceChanges = [
        (
          productId: product.id,
          title: product.title,
          previousPrice: product.price,
          currentPrice: next.price,
        ),
      ];
    }
    _checkoutAvailabilityIssue = null;
    _restoreRecoveryOrigin(notify: false);
    notice = next.price == product.price
        ? '${product.title} is available. Review Checkout to continue.'
        : 'The current price changed. Review the updated total to continue.';
    _persistCustomerState();
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    return true;
  }

  bool removeCheckoutIssueProduct() {
    final issue = _checkoutAvailabilityIssue;
    if (recoveryKind != BuyV2RecoveryKind.stockUnavailable || issue == null) {
      return false;
    }
    final previous = _navigationSurfaceIdentity;
    final removed = _cart.remove(issue.productId);
    if (removed == null) return false;
    _checkoutAvailabilityIssue = null;
    _restoreRecoveryOrigin(notify: false);
    _acknowledgeCart('${removed.product.title} removed');
    _pruneCartSelections();
    if (_cart.isEmpty) {
      destination = removed.product.destination;
      view = BuyV2View.catalogue;
      cartScope = BuyV2CartScope.all;
    } else if (checkoutLines.isEmpty) {
      view = BuyV2View.cart;
      cartScope = BuyV2CartScope.all;
    }
    _persistCustomerState();
    _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    return true;
  }

  bool openCheckoutIssueProduct() {
    final issue = _checkoutAvailabilityIssue;
    if (recoveryKind != BuyV2RecoveryKind.stockUnavailable || issue == null) {
      return false;
    }
    _restoreRecoveryOrigin(notify: false);
    _checkoutAvailabilityIssue = null;
    return openProduct(issue.productId);
  }

  bool openRecoveryOrderHelp() {
    if (!canOpenRecoveryOrderHelp) return false;
    return _restoreRecoveryOrigin();
  }

  void _clearRecoveryOriginIfActive() {
    if (view != BuyV2View.recovery) return;
    recoveryKind = null;
    _recoveryOrigin = null;
  }

  bool _restoreRecoveryOrigin({bool notify = true}) {
    final previous = _navigationSurfaceIdentity;
    final origin = _recoveryOrigin;
    recoveryKind = null;
    _recoveryOrigin = null;
    _checkoutAvailabilityIssue = null;

    if (origin == null || origin.view == BuyV2View.recovery) {
      destination = BuyV2Destination.shop;
      view = BuyV2View.catalogue;
      query = '';
      selectedFilter = null;
      selectedProductId = null;
      _selectedOrderId = null;
      notice = null;
      if (notify) {
        _notifyNavigationIfChanged(
          previous,
          BuyV2NavigationMotionDirection.back,
        );
      }
      return false;
    }

    destination = origin.destination;
    view = origin.view;
    cartScope = origin.cartScope;
    checkoutScope = origin.checkoutScope;
    ordersTab = origin.ordersTab;
    shopCategoryId = origin.shopCategoryId;
    wholesaleCategoryId = origin.wholesaleCategoryId;
    medicineCategoryId = origin.medicineCategoryId;
    query = origin.query;
    selectedFilter = origin.filter;
    selectedProductId = origin.productId;
    _selectedOrderId = origin.orderId;
    notice = null;
    var exact = true;

    switch (origin.view) {
      case BuyV2View.product:
        final product = selectedProduct;
        if (product == null || product.destination != origin.destination) {
          selectedProductId = null;
          view = BuyV2View.catalogue;
          notice = 'This product could not be found.';
          exact = false;
        }
      case BuyV2View.cart:
        if (_linesForScope(origin.cartScope).isEmpty) {
          view = BuyV2View.catalogue;
          notice = 'This Cart section is empty.';
          exact = false;
        }
      case BuyV2View.checkout:
        if (_linesForScope(origin.checkoutScope).isEmpty) {
          if (_linesForScope(origin.cartScope).isEmpty) {
            view = BuyV2View.catalogue;
            notice = 'Choose a product to continue.';
          } else {
            view = BuyV2View.cart;
            notice = 'Review your Cart before continuing.';
          }
          exact = false;
        } else if (selectedAddressOrNull == null) {
          cartScope = origin.checkoutScope;
          view = BuyV2View.cart;
          notice = 'Choose a delivery address to continue.';
          exact = false;
        }
      case BuyV2View.confirmation:
        if (_confirmedOrders.isEmpty || _confirmedItemCount <= 0) {
          destination = BuyV2Destination.orders;
          view = BuyV2View.catalogue;
          notice = 'This confirmation is no longer available. View Orders.';
          exact = false;
        }
      case BuyV2View.tracking || BuyV2View.orderItems:
        if (selectedOrderOrNull == null) {
          destination = BuyV2Destination.orders;
          view = BuyV2View.catalogue;
          notice = 'This order could not be found.';
          exact = false;
        }
      case BuyV2View.assist:
        final requiresExactOrder =
            _assistReturnView == BuyV2View.tracking ||
            _assistReturnView == BuyV2View.orderItems;
        if (requiresExactOrder && selectedOrderOrNull == null) {
          destination = BuyV2Destination.orders;
          view = BuyV2View.catalogue;
          notice = 'This order could not be found.';
          exact = false;
        }
      case BuyV2View.catalogue || BuyV2View.account:
        break;
      case BuyV2View.recovery:
        throw StateError('Recovery cannot be its own retained origin.');
    }

    if (notify) {
      _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    }
    return exact;
  }

  void clearNotice() {
    if (notice == null) return;
    notice = null;
    notifyListeners();
  }

  void clearCartAcknowledgement() {
    if (cartAcknowledgement == null) return;
    cartAcknowledgement = null;
    notifyListeners();
  }

  void _acknowledgeCart(String message) {
    notice = null;
    cartAcknowledgement = message;
  }

  void showNotice(String message) {
    notice = message;
    notifyListeners();
  }
}
