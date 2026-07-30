import 'package:flutter/foundation.dart';

import 'buy_session.dart';
import 'buy_v2_models.dart';

class BuyV2Session extends ChangeNotifier {
  BuyV2Session({required this.core})
    : _savedCanonicalIds = {
        ...BuyV2Catalogue.products
            .where((product) => product.destination == BuyV2Destination.shop)
            .take(3)
            .map((product) => product.canonicalId),
        ...BuyV2Catalogue.products
            .where(
              (product) => product.destination == BuyV2Destination.medicine,
            )
            .take(3)
            .map((product) => product.canonicalId),
      };

  final BuySession core;

  static const Set<String> paymentMethods = {
    'UPI',
    'Bank transfer',
    'Purchase order',
  };

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
  String? selectedOrderId;
  String? pendingPrescriptionProductId;
  BuyV2RecoveryKind? recoveryKind;
  String? notice;
  String? cartAcknowledgement;
  String? selectedFilter;
  bool businessVerified = true;
  bool prescriptionAttached = false;
  bool trackingAlertsEnabled = true;
  String selectedAddressId = 'home';
  String selectedPayment = 'UPI';

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

  final Map<String, BuyV2CartLine> _cart = {};
  final Map<String, int> _prescriptionApprovedQuantities = {};
  final Map<String, BuyV2CustomerReview> _customerReviews = {};
  final Map<String, String> _reportedProductReasons = {};
  final Set<String> _savedCanonicalIds;
  Set<BuyV2Destination> _confirmedDestinations = {};
  List<BuyV2Order> _confirmedOrders = [];
  int _confirmedItemCount = 0;
  int _confirmedTotal = 0;
  int _orderSequence = 1;

  final List<BuyV2Address> addresses = [
    const BuyV2Address(
      id: 'home',
      kind: BuyV2AddressKind.home,
      label: 'Home',
      recipient: 'Dharmendra Choudhary',
      phone: '9251893684',
      line: '12, Central Residency',
      area: 'Sardarpura, Jodhpur',
      pinCode: '342003',
      landmark: 'Near Sardarpura circle',
    ),
    const BuyV2Address(
      id: 'work',
      kind: BuyV2AddressKind.work,
      label: 'Work',
      recipient: 'Dharmendra Choudhary',
      phone: '9251893684',
      line: 'Supermandi Tech Private Limited',
      area: 'Basni, Jodhpur',
      pinCode: '342005',
      landmark: 'Near industrial area gate',
    ),
  ];

  final List<BuyV2Order> orders = [
    const BuyV2Order(
      id: 'MS-240782',
      destination: BuyV2Destination.shop,
      title: 'Shop order',
      itemSummary: '13 products · Home · Sardarpura',
      total: 4839,
      partner: 'Sardarpura Supermart',
      partnerType: 'Mool Retail Partner',
      promise: 'Wed, 29 Jul · by 7:30 pm',
      destinationLabel: 'Sardarpura · 342003',
      progress: .54,
      status: BuyV2OrderStatus.preparing,
    ),
    const BuyV2Order(
      id: 'PO-240783',
      destination: BuyV2Destination.wholesale,
      title: 'Wholesale order',
      itemSummary: '1 trade product · Shree Balaji Retail',
      total: 4200,
      partner: 'Marwar Foods Distribution',
      partnerType: 'Mool Trade Partner',
      promise: 'Thu, 30 Jul · 10:00 am–2:00 pm',
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
      promise: 'Wed, 29 Jul · by 11:00 am',
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
      itemSummary: '3 trade products · Shree Balaji Retail',
      total: 8460,
      partner: 'Marwar Foods Distribution',
      partnerType: 'Mool Trade Partner',
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

  List<BuyV2Product> get visibleProducts {
    final normalized = query.trim().toLowerCase();
    final filterDestination = destination == BuyV2Destination.orders
        ? BuyV2Destination.shop
        : destination;
    final category = selectedCategoryId;
    final products = BuyV2Catalogue.products.where((product) {
      if (product.destination != filterDestination) return false;
      final matchesCategory =
          category == 'all' ||
          (category == 'rx' && product.requiresPrescription) ||
          product.categoryId == category;
      final matchesQuery =
          normalized.isEmpty ||
          product.title.toLowerCase().contains(normalized) ||
          product.brand.toLowerCase().contains(normalized) ||
          product.seller.toLowerCase().contains(normalized) ||
          product.variant.toLowerCase().contains(normalized) ||
          product.id.toLowerCase().contains(normalized);
      final matchesFilter = switch (selectedFilter) {
        'fast' => switch (filterDestination) {
          BuyV2Destination.shop => product.deliveryPromise.contains('within'),
          BuyV2Destination.wholesale => product.deliveryPromise.contains(
            'Thu, 30 Jul',
          ),
          BuyV2Destination.medicine => product.deliveryPromise.contains(
            '11:00',
          ),
          BuyV2Destination.orders => false,
        },
        'today' =>
          product.deliveryPromise.contains('Wed, 29 Jul') ||
              product.deliveryPromise.contains('within'),
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
          !product.deliveryPromise.toLowerCase().contains('aug') &&
              !product.deliveryPromise.toLowerCase().contains('week'),
        'freight' => product.freightIncluded,
        'moq' =>
          product.destination == BuyV2Destination.wholesale &&
              product.minimumOrder <= 2,
        'returns' => product.returnPolicy != null,
        'rx' => product.requiresPrescription,
        'otc' => !product.requiresPrescription,
        _ => true,
      };
      return matchesCategory && matchesQuery && matchesFilter;
    }).toList();
    if (category == 'all' && normalized.isEmpty && products.length > 18) {
      return products.take(18).toList();
    }
    return products;
  }

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
    return BuyV2Catalogue.products
        .where(
          (product) =>
              product.destination == destination &&
              _savedCanonicalIds.contains(product.canonicalId),
        )
        .toList(growable: false);
  }

  int savedCountFor(BuyV2Destination value) => savedProductsFor(value).length;

  bool isSaved(String productId) {
    final item = findProduct(productId);
    return item != null && _savedCanonicalIds.contains(item.canonicalId);
  }

  void toggleSaved(String productId) {
    final item = findProduct(productId);
    if (item == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return;
    }
    if (_savedCanonicalIds.remove(item.canonicalId)) {
      notice = '${item.title} removed from Saved.';
    } else {
      _savedCanonicalIds.add(item.canonicalId);
      notice = '${item.title} saved.';
    }
    notifyListeners();
  }

  List<BuyV2CartLine> get cartLines {
    final lines = _linesForScope(cartScope);
    return List.unmodifiable(lines);
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

  List<BuyV2FulfilmentGroup> get checkoutFulfilmentGroups {
    final grouped = <String, List<BuyV2CartLine>>{};
    for (final line in checkoutLines) {
      final product = line.product;
      final key = '${product.destination.name}|${product.seller}';
      grouped.putIfAbsent(key, () => []).add(line);
    }
    return grouped.values
        .map(
          (lines) => BuyV2FulfilmentGroup(
            destination: lines.first.product.destination,
            partner: lines.first.product.seller,
            partnerType: lines.first.product.partnerRole,
            promise: lines
                .map((line) => line.product.deliveryPromise)
                .toSet()
                .join(' · '),
            lines: List.unmodifiable(lines),
          ),
        )
        .toList(growable: false);
  }

  Set<BuyV2Destination> get confirmedDestinations =>
      Set.unmodifiable(_confirmedDestinations);

  List<BuyV2Order> get confirmedOrders => List.unmodifiable(_confirmedOrders);

  int get confirmedItemCount => _confirmedItemCount;

  int get confirmedTotal => _confirmedTotal;

  List<BuyV2Order> get visibleOrders {
    final normalizedQuery = query.trim().toLowerCase();
    return orders
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

  int get activeOrderCount => orders
      .where((order) => order.status != BuyV2OrderStatus.delivered)
      .length;

  int get deliveredOrderCount => orders
      .where((order) => order.status == BuyV2OrderStatus.delivered)
      .length;

  BuyV2Product? findProduct(String id) {
    for (final product in BuyV2Catalogue.products) {
      if (product.id == id) return product;
    }
    return null;
  }

  BuyV2Product product(String id) {
    final match = findProduct(id);
    if (match != null) return match;
    throw ArgumentError.value(id, 'id', 'Unknown Buy product');
  }

  BuyV2Product? get selectedProduct {
    final id = selectedProductId;
    return id == null ? null : findProduct(id);
  }

  BuyV2Order get selectedOrder {
    final id = selectedOrderId;
    return orders.firstWhere(
      (order) => order.id == id,
      orElse: () => orders.first,
    );
  }

  BuyV2Address get selectedAddress => addresses.firstWhere(
    (address) => address.id == selectedAddressId,
    orElse: () => addresses.first,
  );

  void openDestination(BuyV2Destination value) {
    _accountChildReturnActive = false;
    destination = value;
    view = value == BuyV2Destination.orders
        ? BuyV2View.catalogue
        : BuyV2View.catalogue;
    query = '';
    selectedFilter = null;
    notice = null;
    notifyListeners();
  }

  bool openProduct(String id) {
    final item = findProduct(id);
    if (item == null) {
      notice = 'This product could not be found.';
      notifyListeners();
      return false;
    }
    if (view != BuyV2View.product) {
      _productReturnDestination = destination;
      _productReturnView = view;
    }
    destination = item.destination;
    selectedProductId = item.id;
    view = BuyV2View.product;
    notice = null;
    notifyListeners();
    return true;
  }

  void closeProduct() {
    destination = _productReturnDestination;
    view = _productReturnView;
    selectedProductId = null;
    notice = null;
    notifyListeners();
  }

  void openCart({BuyV2CartScope scope = BuyV2CartScope.all}) {
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
      notifyListeners();
      return;
    }
    cartScope = scope;
    view = BuyV2View.cart;
    notifyListeners();
  }

  void openCheckout() {
    if (cartLines.isEmpty) {
      view = BuyV2View.catalogue;
      notice = 'Choose a product to continue.';
    } else {
      checkoutScope = cartScope;
      view = BuyV2View.checkout;
      notice = null;
    }
    notifyListeners();
  }

  void openOrders() {
    _accountChildReturnActive = false;
    query = '';
    selectedFilter = null;
    _openOrdersRoot();
  }

  void _openOrdersRoot() {
    destination = BuyV2Destination.orders;
    view = BuyV2View.catalogue;
    ordersTab = BuyV2OrdersTab.active;
    notice = null;
    notifyListeners();
  }

  void openOrdersFromAccount() {
    if (view != BuyV2View.account) {
      openOrders();
      return;
    }
    _accountChildReturnActive = true;
    query = '';
    selectedFilter = null;
    _openOrdersRoot();
  }

  void openWholesaleFromAccount() {
    if (view != BuyV2View.account) {
      openDestination(BuyV2Destination.wholesale);
      return;
    }
    _accountChildReturnActive = true;
    destination = BuyV2Destination.wholesale;
    view = BuyV2View.catalogue;
    query = '';
    selectedFilter = null;
    notice = null;
    notifyListeners();
  }

  bool openTracking(String orderId) {
    destination = BuyV2Destination.orders;
    final orderExists = orders.any((order) => order.id == orderId);
    if (!orderExists) {
      selectedOrderId = null;
      view = BuyV2View.catalogue;
      notice = 'This order could not be found.';
      notifyListeners();
      return false;
    }
    selectedOrderId = orderId;
    view = BuyV2View.tracking;
    notice = null;
    notifyListeners();
    return true;
  }

  bool openOrderItems(String orderId) {
    final order = orders
        .where((candidate) => candidate.id == orderId)
        .firstOrNull;
    if (order == null) {
      notice = 'This order could not be found.';
      notifyListeners();
      return false;
    }
    selectedOrderId = order.id;
    destination = BuyV2Destination.orders;
    view = BuyV2View.orderItems;
    notice = null;
    notifyListeners();
    return true;
  }

  List<BuyV2Product> productsForOrder(BuyV2Order order) {
    final ids =
        (order.productIds.isNotEmpty
                ? order.productIds
                : BuyV2Catalogue.products
                      .where(
                        (product) => product.destination == order.destination,
                      )
                      .take(2)
                      .map((product) => product.id))
            .toList(growable: false);
    return ids
        .map(findProduct)
        .whereType<BuyV2Product>()
        .where((product) => product.destination == order.destination)
        .toList(growable: false);
  }

  void toggleTrackingAlerts() {
    trackingAlertsEnabled = !trackingAlertsEnabled;
    notice = trackingAlertsEnabled
        ? 'Live order alerts are on.'
        : 'Live order alerts are paused.';
    notifyListeners();
  }

  void openAssist() {
    if (view != BuyV2View.assist) {
      _assistReturnDestination = destination;
      _assistReturnView = view;
    }
    view = BuyV2View.assist;
    notice = null;
    notifyListeners();
  }

  void closeAssist() {
    destination = _assistReturnDestination;
    view = _assistReturnView;
    notice = null;
    notifyListeners();
  }

  void openAccount() {
    if (_accountChildReturnActive) {
      returnToAccount();
      return;
    }
    if (view != BuyV2View.account) {
      _accountReturnDestination = destination;
      _accountReturnView = view;
      _accountReturnProductId = selectedProductId;
      _accountReturnOrderId = selectedOrderId;
      _accountReturnQuery = query;
      _accountReturnFilter = selectedFilter;
    }
    view = BuyV2View.account;
    notice = null;
    notifyListeners();
  }

  void closeAccount() {
    _accountChildReturnActive = false;
    destination = _accountReturnDestination;
    view = _accountReturnView;
    selectedProductId = _accountReturnProductId;
    selectedOrderId = _accountReturnOrderId;
    query = _accountReturnQuery;
    selectedFilter = _accountReturnFilter;
    notice = null;
    notifyListeners();
  }

  bool get canReturnToAccount =>
      _accountChildReturnActive && view != BuyV2View.account;

  void returnToAccount() {
    if (!_accountChildReturnActive) return;
    _accountChildReturnActive = false;
    destination = _accountReturnDestination;
    view = BuyV2View.account;
    query = _accountReturnQuery;
    selectedFilter = _accountReturnFilter;
    notice = null;
    notifyListeners();
  }

  bool get canHandleBack =>
      canReturnToAccount ||
      view != BuyV2View.catalogue ||
      destination != BuyV2Destination.shop;

  void goBack() {
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
        _openOrdersRoot();
      case BuyV2View.orderItems:
        openTracking(selectedOrder.id);
      case BuyV2View.assist:
        closeAssist();
      case BuyV2View.recovery:
        if (cartLines.isEmpty) {
          returnToCatalogue();
        } else {
          view = BuyV2View.checkout;
          notice = null;
          notifyListeners();
        }
      case BuyV2View.catalogue:
        if (canReturnToAccount) {
          returnToAccount();
        } else if (destination != BuyV2Destination.shop) {
          openDestination(BuyV2Destination.shop);
        }
    }
  }

  void showOrdersTab(BuyV2OrdersTab value) {
    destination = BuyV2Destination.orders;
    view = BuyV2View.catalogue;
    ordersTab = value;
    notifyListeners();
  }

  void returnToCatalogue() {
    if (destination == BuyV2Destination.orders) {
      view = BuyV2View.catalogue;
    } else {
      view = BuyV2View.catalogue;
    }
    selectedProductId = null;
    notice = null;
    notifyListeners();
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

  void chooseFilter(String? value) {
    selectedFilter = value;
    notifyListeners();
  }

  bool addProduct(String id) {
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
    final unitLabel = itemCount == 1 ? 'item' : 'items';
    _acknowledgeCart('${item.title} added · $itemCount $unitLabel');
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

  int? prescriptionMaximumFor(String id) => _prescriptionApprovedQuantities[id];

  int quantityFor(String id) => _cart[id]?.quantity ?? 0;

  void increase(String id) {
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
    _acknowledgeCart(
      '${current.product.title} · ${current.quantity + 1} in cart',
    );
    notifyListeners();
  }

  void decrease(String id) {
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
    notifyListeners();
  }

  void remove(String id) {
    final removed = _cart.remove(id);
    if (removed == null) return;
    _acknowledgeCart('${removed.product.title} removed');
    if (_cart.isEmpty) {
      destination = removed.product.destination;
      view = BuyV2View.catalogue;
      cartScope = BuyV2CartScope.all;
    }
    notifyListeners();
  }

  void clearCart() {
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
    destination = fallback;
    view = BuyV2View.catalogue;
    cartScope = BuyV2CartScope.all;
    notice = null;
    cartAcknowledgement = null;
    notifyListeners();
  }

  void chooseCartScope(BuyV2CartScope value) {
    cartScope = value;
    notifyListeners();
  }

  bool chooseAddress(String id) {
    if (!addresses.any((address) => address.id == id)) {
      notice = 'This saved address could not be found.';
      notifyListeners();
      return false;
    }
    selectedAddressId = id;
    notice = 'Delivering to ${selectedAddress.shortLine}';
    notifyListeners();
    return true;
  }

  void addAddress(BuyV2Address address) {
    addresses.add(address);
    selectedAddressId = address.id;
    notice = 'Delivering to ${address.shortLine}';
    notifyListeners();
  }

  bool choosePayment(String value) {
    if (!paymentMethods.contains(value)) {
      notice = 'This payment method is not available.';
      notifyListeners();
      return false;
    }
    selectedPayment = value;
    notice = '$value selected';
    notifyListeners();
    return true;
  }

  void confirmOrder() {
    final lines = checkoutLines;
    if (lines.isEmpty) {
      returnToCatalogue();
      return;
    }
    final groups = checkoutFulfilmentGroups;
    _confirmedOrders = groups.map(_createOrderForGroup).toList(growable: false);
    orders.insertAll(0, _confirmedOrders);
    _confirmedDestinations = _confirmedOrders
        .map((order) => order.destination)
        .toSet();
    _confirmedItemCount = checkoutItemCount;
    _confirmedTotal = checkoutTotal;
    for (final line in lines) {
      _cart.remove(line.product.id);
    }
    cartScope = BuyV2CartScope.all;
    checkoutScope = BuyV2CartScope.all;
    destination = BuyV2Destination.orders;
    view = BuyV2View.confirmation;
    notice = null;
    notifyListeners();
  }

  BuyV2Order _createOrderForGroup(BuyV2FulfilmentGroup group) {
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
    return BuyV2Order(
      id: '$prefix-NEW-${sequence.toString().padLeft(2, '0')}',
      destination: group.destination,
      title: '${group.destination.label} order',
      itemSummary:
          '${group.itemCount} $itemName · ${selectedAddress.label} · ${selectedAddress.area}',
      total: group.total,
      partner: group.partner,
      partnerType: group.partnerType,
      promise: group.promise,
      destinationLabel: selectedAddress.shortLine,
      progress: status == BuyV2OrderStatus.confirmed ? .34 : .2,
      status: status,
      productIds: group.productIds,
    );
  }

  bool reorder(BuyV2Order order) {
    destination = order.destination;
    final ids =
        (order.productIds.isNotEmpty
                ? order.productIds
                : BuyV2Catalogue.products
                      .where(
                        (product) => product.destination == order.destination,
                      )
                      .take(2)
                      .map((product) => product.id))
            .toList(growable: false);
    final products = ids.map(findProduct).toList(growable: false);
    if (products.isEmpty ||
        products.any(
          (product) =>
              product == null || product.destination != order.destination,
        )) {
      view = BuyV2View.catalogue;
      notice = 'Products from this order could not be found.';
      notifyListeners();
      return false;
    }
    for (final product in products.whereType<BuyV2Product>()) {
      addProduct(product.id);
    }
    cartScope = switch (order.destination) {
      BuyV2Destination.shop => BuyV2CartScope.shop,
      BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
      BuyV2Destination.medicine => BuyV2CartScope.medicine,
      BuyV2Destination.orders => BuyV2CartScope.all,
    };
    view = BuyV2View.cart;
    notice = 'Previous products are ready to edit.';
    notifyListeners();
    return true;
  }

  void openRecovery(BuyV2RecoveryKind kind) {
    recoveryKind = kind;
    view = BuyV2View.recovery;
    notifyListeners();
  }

  void retryRecovery() {
    final kind = recoveryKind;
    recoveryKind = null;
    if (kind == BuyV2RecoveryKind.paymentFailed && _cart.isNotEmpty) {
      view = BuyV2View.checkout;
    } else {
      destination = BuyV2Destination.shop;
      view = BuyV2View.catalogue;
    }
    notice = 'Updated. You can continue.';
    notifyListeners();
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
