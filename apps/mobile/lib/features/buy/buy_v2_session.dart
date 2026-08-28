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

class BuyV2Session extends ChangeNotifier {
  BuyV2Session({
    required this.core,
    this.productFactsAdapter = const BuyV2CatalogueProductFactsAdapter(),
    this.sponsoredContentAdapter = const BuyV2DisabledSponsoredContentAdapter(),
    BuyV2CartBenefitsAdapter? cartBenefitsAdapter,
    this.tipPolicy = const BuyV2DisabledTipPolicy(),
    this.savedProductsStore,
  }) : cartBenefitsAdapter =
           cartBenefitsAdapter ??
           (buyV2DeviceReviewBenefitSeedsEnabled
               ? const BuyV2SeededCartBenefitsAdapter()
               : const BuyV2DisabledCartBenefitsAdapter());

  final BuySession core;
  final BuyV2ProductFactsAdapter productFactsAdapter;
  final BuyV2SponsoredContentAdapter sponsoredContentAdapter;
  final BuyV2CartBenefitsAdapter cartBenefitsAdapter;
  final BuyV2TipPolicy tipPolicy;
  final BuyV2SavedProductsStore? savedProductsStore;

  static const bool sponsoredContentActivationApproved = false;
  static const BuyV2CatalogueProductFactsAdapter _catalogueFactsFallback =
      BuyV2CatalogueProductFactsAdapter();

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
  String? pendingPrescriptionProductId;
  BuyV2RecoveryKind? recoveryKind;
  _BuyV2RecoveryOrigin? _recoveryOrigin;
  String? notice;
  String? cartAcknowledgement;
  String? selectedFilter;
  bool businessVerified = true;
  bool prescriptionAttached = false;
  bool trackingAlertsEnabled = true;
  String selectedPayment = 'UPI';

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

  final Map<String, BuyV2CartLine> _cart = {};
  final Map<String, BuyV2ProductFactsSnapshot> _productFacts = {};
  final Map<String, int> _prescriptionApprovedQuantities = {};
  final Map<String, BuyV2CustomerReview> _customerReviews = {};
  final Map<String, String> _reportedProductReasons = {};
  final Map<BuyV2CartScope, double> _cartScrollOffsets = {};
  final Map<BuyV2Destination, String> _deliveryInstructionIds = {};
  final Map<String, _BuyV2CartBenefitSelectionRef> _selectedCartBenefitRefs =
      {};
  final Map<String, int> _tipsByFulfilmentKey = {};
  final Set<String> _savedKeys = {};
  String? _savedProductsOwnerScope;
  int _savedProductsMutationRevision = 0;
  Set<BuyV2Destination> _confirmedDestinations = {};
  List<BuyV2Order> _confirmedOrders = [];
  Map<String, _BuyV2DeliveryPromiseQuote> _checkoutPromiseSnapshot = {};
  Map<String, _BuyV2DeliveryPromiseQuote>? _pendingCheckoutPromiseSnapshot;
  List<BuyV2DeliveryPromiseChange> _checkoutDeliveryPromiseChanges = [];
  String? _confirmedPurchaseId;
  int _confirmedItemCount = 0;
  int _confirmedTotal = 0;
  int _orderSequence = 1;
  int _purchaseSequence = 1;

  final List<BuyV2Address> _addresses = [
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

  final List<BuyV2Order> _orders = [
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

  List<BuyV2Address> get addresses => List.unmodifiable(_addresses);

  List<BuyV2Order> get orders => List.unmodifiable(_orders);

  String? get selectedOrderId => _selectedOrderId;

  String? get selectedAddressId => _selectedAddressId;

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
    final candidates = BuyV2Catalogue.products.where((product) {
      if (product.destination != filterDestination) return false;
      final matchesCategory =
          category == 'all' ||
          (category == 'rx' && product.requiresPrescription) ||
          product.categoryId == category;
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
    return BuyV2Catalogue.products
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
      final validKeys = BuyV2Catalogue.products.map(_buyV2SavedKey).toSet();
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

  int get scopedPayableTotal => scopedCartTotal + scopedTipTotal;

  int get checkoutPayableTotal => checkoutTotal + checkoutTipTotal;

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
    notifyListeners();
    return true;
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
    final raw = cartBenefitsAdapter.benefitsFor(
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
          !ids.add(benefit.id)) {
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
    notice = '${current.title} selected for Checkout review.';
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

    final candidates = BuyV2Catalogue.products
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

    final candidates = BuyV2Catalogue.products
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

    final candidates = BuyV2Catalogue.products
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

    final candidates = BuyV2Catalogue.products
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

  List<BuyV2Order> get visibleOrders {
    final normalizedQuery = query.trim().toLowerCase();
    return _orders
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
      .where((order) => order.status != BuyV2OrderStatus.delivered)
      .length;

  int get deliveredOrderCount => _orders
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
        snapshot.sourceId.trim().isNotEmpty;
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
      notice = null;
      _captureCheckoutPromiseSnapshot();
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
    trackingAlertsEnabled = !trackingAlertsEnabled;
    notice = trackingAlertsEnabled
        ? 'Live order alerts are on.'
        : 'Live order alerts are paused.';
    notifyListeners();
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
    notice = null;
    notifyListeners();
    return true;
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

  List<BuyV2Product> get matchedPrescriptionProducts => List.unmodifiable(
    BuyV2Catalogue.products.where(
      (product) =>
          product.destination == BuyV2Destination.medicine &&
          _prescriptionApprovedQuantities.containsKey(product.id),
    ),
  );

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
    if (_cart.isEmpty) {
      _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    } else {
      notifyListeners();
    }
  }

  void remove(String id) {
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
    if (_cart.isEmpty) {
      _notifyNavigationIfChanged(previous, BuyV2NavigationMotionDirection.back);
    } else {
      notifyListeners();
    }
  }

  void clearCart() {
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
    notifyListeners();
    return true;
  }

  void addAddress(BuyV2Address address) {
    _addresses.add(address);
    _selectedAddressId = address.id;
    notice = 'Delivering to ${address.shortLine}';
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
    notice = '${address.label} address updated';
    notifyListeners();
    return true;
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

  bool confirmOrder() {
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
    _confirmedOrders = groups
        .map((group) => _createOrderForGroup(group, address, purchaseId))
        .toList(growable: false);
    _orders.insertAll(0, _confirmedOrders);
    _confirmedDestinations = _confirmedOrders
        .map((order) => order.destination)
        .toSet();
    _confirmedItemCount = checkoutItemCount;
    _confirmedTotal = checkoutPayableTotal;
    for (final line in lines) {
      _cart.remove(line.product.id);
    }
    _pruneCartSelections();
    cartScope = BuyV2CartScope.all;
    checkoutScope = BuyV2CartScope.all;
    destination = BuyV2Destination.orders;
    view = BuyV2View.confirmation;
    notice = null;
    _clearCheckoutPromiseSnapshot();
    _notifyNavigationIfChanged(
      previous,
      BuyV2NavigationMotionDirection.forward,
    );
    return true;
  }

  BuyV2Order _createOrderForGroup(
    BuyV2FulfilmentGroup group,
    BuyV2Address address,
    String purchaseId,
  ) {
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
          '${group.itemCount} $itemName · ${address.label} · ${address.area}',
      total: group.total + tipForGroup(group),
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

  bool openRecoveryOrderHelp() {
    if (!canOpenRecoveryOrderHelp) return false;
    if (!_restoreRecoveryOrigin(notify: false)) return false;
    openAssist();
    return true;
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
