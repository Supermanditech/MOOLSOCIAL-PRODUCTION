import 'package:flutter/foundation.dart';

import 'buy_session.dart';
import 'buy_v2_models.dart';

class BuyV2Session extends ChangeNotifier {
  BuyV2Session({required this.core});

  final BuySession core;

  BuyV2Destination destination = BuyV2Destination.shop;
  BuyV2View view = BuyV2View.catalogue;
  BuyV2CartScope cartScope = BuyV2CartScope.all;
  String shopCategoryId = 'all';
  String wholesaleCategoryId = 'all';
  String medicineCategoryId = 'all';
  String query = '';
  String? selectedProductId;
  String? selectedOrderId;
  String? pendingPrescriptionProductId;
  String? notice;
  String? selectedFilter;
  bool businessVerified = true;
  bool prescriptionAttached = false;
  String selectedAddressId = 'home';

  final Map<String, BuyV2CartLine> _cart = {};
  final Set<String> _prescriptionApprovedProductIds = {};

  final List<BuyV2Address> addresses = const [
    BuyV2Address(
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
    BuyV2Address(
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

  final List<BuyV2Order> orders = const [
    BuyV2Order(
      id: 'MS-240782',
      destination: BuyV2Destination.shop,
      title: 'Shop order',
      itemSummary: '13 products · Home · Sardarpura',
      total: 4839,
      partner: 'Sardarpura Supermart',
      partnerType: 'Verified retailer',
      promise: 'Wed, 29 Jul · by 7:30 pm',
      destinationLabel: 'Sardarpura · 342003',
      progress: .54,
      status: BuyV2OrderStatus.preparing,
    ),
    BuyV2Order(
      id: 'PO-240783',
      destination: BuyV2Destination.wholesale,
      title: 'Wholesale order',
      itemSummary: '1 trade product · Shree Balaji Retail',
      total: 4200,
      partner: 'Marwar Foods Distribution',
      partnerType: 'Verified distributor',
      promise: 'Thu, 30 Jul · 10:00 am–2:00 pm',
      destinationLabel: 'Basni · 342005',
      progress: .34,
      status: BuyV2OrderStatus.confirmed,
    ),
    BuyV2Order(
      id: 'RX-240784',
      destination: BuyV2Destination.medicine,
      title: 'Medicine order',
      itemSummary: '2 medicines · Home · Sardarpura',
      total: 134,
      partner: 'Sardarpura Health Pharmacy',
      partnerType: 'Licensed pharmacy',
      promise: 'Wed, 29 Jul · by 11:00 am',
      destinationLabel: 'Sardarpura · 342003',
      progress: .67,
      status: BuyV2OrderStatus.preparing,
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
          product.variant.toLowerCase().contains(normalized);
      final matchesFilter = switch (selectedFilter) {
        'fast' =>
          product.deliveryPromise.contains('within') ||
              product.deliveryPromise.contains('11:00'),
        'lowest' =>
          product.badge.toLowerCase().contains('lowest') ||
              product.badge.contains('off'),
        'manufacturer' => product.sellerType.contains('manufacturer'),
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

  List<BuyV2CartLine> get cartLines {
    final lines = _cart.values.where((line) {
      return switch (cartScope) {
        BuyV2CartScope.all => true,
        BuyV2CartScope.shop =>
          line.product.destination == BuyV2Destination.shop,
        BuyV2CartScope.wholesale =>
          line.product.destination == BuyV2Destination.wholesale,
        BuyV2CartScope.medicine =>
          line.product.destination == BuyV2Destination.medicine,
      };
    }).toList();
    return List.unmodifiable(lines);
  }

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

  BuyV2Product product(String id) => BuyV2Catalogue.products.firstWhere(
    (product) => product.id == id,
    orElse: () => BuyV2Catalogue.products.first,
  );

  BuyV2Product? get selectedProduct {
    final id = selectedProductId;
    return id == null ? null : product(id);
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
    destination = value;
    view = value == BuyV2Destination.orders
        ? BuyV2View.catalogue
        : BuyV2View.catalogue;
    query = '';
    selectedFilter = null;
    notice = null;
    notifyListeners();
  }

  void openProduct(String id) {
    final item = product(id);
    destination = item.destination;
    selectedProductId = item.id;
    view = BuyV2View.product;
    notice = null;
    notifyListeners();
  }

  void openCart({BuyV2CartScope scope = BuyV2CartScope.all}) {
    cartScope = scope;
    view = BuyV2View.cart;
    notifyListeners();
  }

  void openCheckout() {
    if (_cart.isEmpty) {
      view = BuyV2View.catalogue;
      notice = 'Choose a product to continue.';
    } else {
      view = BuyV2View.checkout;
      notice = null;
    }
    notifyListeners();
  }

  void openOrders() {
    destination = BuyV2Destination.orders;
    view = BuyV2View.catalogue;
    notifyListeners();
  }

  void openTracking(String orderId) {
    destination = BuyV2Destination.orders;
    selectedOrderId = orderId;
    view = BuyV2View.tracking;
    notifyListeners();
  }

  void openAssist() {
    view = BuyV2View.assist;
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
    final item = product(id);
    if (item.destination == BuyV2Destination.wholesale && !businessVerified) {
      notice = 'Verify your Workspace to place a wholesale order.';
      notifyListeners();
      return false;
    }
    if (item.requiresPrescription &&
        !_prescriptionApprovedProductIds.contains(item.id)) {
      pendingPrescriptionProductId = item.id;
      notice = null;
      notifyListeners();
      return false;
    }
    final current = _cart[id];
    _cart[id] = BuyV2CartLine(
      product: item,
      quantity: (current?.quantity ?? 0) + item.minimumOrder,
    );
    final unitLabel = itemCount == 1 ? 'item' : 'items';
    notice = '${item.title} added · $itemCount $unitLabel';
    notifyListeners();
    return true;
  }

  void approveSavedPrescription(String prescriptionId) {
    prescriptionAttached = true;
    final matched = prescriptionId == 'meera'
        ? const ['m-telmisartan-40', 'm-atorvastatin-10']
        : const ['m-metformin-500', 'm-pantoprazole-40'];
    _prescriptionApprovedProductIds.addAll(matched);
    final pending = pendingPrescriptionProductId;
    pendingPrescriptionProductId = null;
    if (pending != null && _prescriptionApprovedProductIds.contains(pending)) {
      addProduct(pending);
      return;
    }
    notice = '${matched.length} prescribed medicines are ready to add.';
    notifyListeners();
  }

  void attachNewPrescription() {
    prescriptionAttached = true;
    _prescriptionApprovedProductIds.addAll(
      BuyV2Catalogue.products
          .where(
            (product) =>
                product.destination == BuyV2Destination.medicine &&
                product.requiresPrescription,
          )
          .map((product) => product.id),
    );
    final pending = pendingPrescriptionProductId;
    pendingPrescriptionProductId = null;
    if (pending != null) {
      addProduct(pending);
      return;
    }
    notice = 'Prescription added. Matched medicines are ready to add.';
    notifyListeners();
  }

  bool isPrescriptionApproved(String id) =>
      _prescriptionApprovedProductIds.contains(id);

  int quantityFor(String id) => _cart[id]?.quantity ?? 0;

  void increase(String id) {
    final current = _cart[id];
    if (current == null) {
      addProduct(id);
      return;
    }
    _cart[id] = current.copyWith(quantity: current.quantity + 1);
    notice = '${current.product.title} · ${current.quantity + 1} in cart';
    notifyListeners();
  }

  void decrease(String id) {
    final current = _cart[id];
    if (current == null) return;
    final minimum = current.product.minimumOrder;
    if (current.quantity <= minimum) {
      _cart.remove(id);
      notice = '${current.product.title} removed.';
    } else {
      _cart[id] = current.copyWith(quantity: current.quantity - 1);
      notice = '${current.product.title} · ${current.quantity - 1} in cart';
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
    notice = '${removed.product.title} removed.';
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
    notifyListeners();
  }

  void chooseCartScope(BuyV2CartScope value) {
    cartScope = value;
    notifyListeners();
  }

  void chooseAddress(String id) {
    selectedAddressId = id;
    notice = 'Delivering to ${selectedAddress.shortLine}';
    notifyListeners();
  }

  void confirmOrder() {
    notice =
        'Order confirmed for ${selectedAddress.recipient} · ${selectedAddress.shortLine}';
    _cart.clear();
    destination = BuyV2Destination.orders;
    view = BuyV2View.catalogue;
    notifyListeners();
  }

  void reorder(BuyV2Order order) {
    destination = order.destination;
    view = BuyV2View.catalogue;
    notice =
        'Previous items are ready. Add or remove products before checkout.';
    notifyListeners();
  }

  void clearNotice() {
    if (notice == null) return;
    notice = null;
    notifyListeners();
  }

  void showNotice(String message) {
    notice = message;
    notifyListeners();
  }
}
