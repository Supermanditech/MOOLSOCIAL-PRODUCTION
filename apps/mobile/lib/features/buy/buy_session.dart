import 'package:flutter/foundation.dart';

import 'buy_models.dart';
import 'buy_services.dart';

class BuySession extends ChangeNotifier {
  BuySession({BuyOrderGateway? orderGateway})
    : _orderGateway = orderGateway ?? ReviewBuyOrderGateway();

  final BuyOrderGateway _orderGateway;

  static const products = <BuyProduct>[
    BuyProduct(
      id: 'tomato',
      name: 'Hybrid tomatoes',
      detail: 'Freshly sorted today',
      unitLabel: '500 g',
      price: 37,
      category: BuyCategory.fresh,
      seller: 'Mahadev Fresh Mart',
      deliveryPromise: 'Home delivery in 22–35 min',
      refundRule: 'Refund for missing or damaged items',
    ),
    BuyProduct(
      id: 'atta',
      name: 'Whole wheat atta',
      detail: 'Stone-ground family staple',
      unitLabel: '10 kg bag',
      price: 495,
      category: BuyCategory.staples,
      seller: 'Mahadev Fresh Mart',
      deliveryPromise: 'Home delivery in 22–35 min',
      refundRule: 'Return unopened pack within 24 hours',
    ),
    BuyProduct(
      id: 'milk',
      name: 'Fresh toned milk',
      detail: 'Chilled and packed today',
      unitLabel: '1 litre',
      price: 64,
      category: BuyCategory.dairy,
      seller: 'Sardarpura Dairy',
      deliveryPromise: 'Home delivery in 18–28 min',
      refundRule: 'Instant refund if seal is damaged',
    ),
    BuyProduct(
      id: 'home-combo',
      name: 'Home cleaning combo',
      detail: 'Floor cleaner and dish wash',
      unitLabel: '1 combo',
      price: 155,
      category: BuyCategory.homeCare,
      seller: 'Mahadev Fresh Mart',
      deliveryPromise: 'Home delivery in 22–35 min',
      refundRule: 'Return unopened item within 24 hours',
    ),
    BuyProduct(
      id: 'shampoo',
      name: 'Daily care shampoo',
      detail: 'Gentle everyday care',
      unitLabel: '340 ml',
      price: 229,
      category: BuyCategory.personalCare,
      seller: 'Care & More',
      deliveryPromise: 'Home delivery in 30–45 min',
      refundRule: 'Return unopened item within 24 hours',
    ),
    BuyProduct(
      id: 'mango',
      name: 'Kesar mangoes',
      detail: 'Next harvest arriving tomorrow',
      unitLabel: '1 kg',
      price: 180,
      category: BuyCategory.fresh,
      seller: 'Mahadev Fresh Mart',
      deliveryPromise: 'Not available today',
      refundRule: 'No charge until available',
      available: false,
    ),
  ];

  final Map<String, BuyCartLine> _cart = {};
  BuyCategory selectedCategory = BuyCategory.all;
  BuyFulfilment fulfilment = BuyFulfilment.homeDelivery;
  UnavailableItemRule unavailableItemRule =
      UnavailableItemRule.askBeforeReplacing;
  BuyPaymentMethod paymentMethod = BuyPaymentMethod.upi;
  String address = 'Home · Sardarpura, Jodhpur';
  String deliveryPromise = 'Deliver in 22–35 min';
  String? pickupStore;
  String? couponCode;
  String? noticeMessage;
  String? errorMessage;
  BuyOrderReceipt? receipt;
  BuyOrderStage orderStage = BuyOrderStage.confirmed;
  BuyCollectionStage collectionStage = BuyCollectionStage.confirmed;
  bool busy = false;
  int shopRating = 0;
  int riderRating = 0;
  bool ratingSubmitted = false;

  List<BuyCartLine> get cartLines => List.unmodifiable(_cart.values);

  int get itemCount =>
      _cart.values.fold(0, (total, line) => total + line.quantity);

  int get subtotal => _cart.values.fold(0, (total, line) => total + line.total);

  int get deliveryFee =>
      subtotal >= 499 || fulfilment == BuyFulfilment.storePickup ? 0 : 25;

  int get discount => couponCode == 'MOOL50' && subtotal >= 299 ? 50 : 0;

  int get total => subtotal + deliveryFee - discount;

  List<BuyProduct> visibleProducts([String query = '']) {
    final normalized = query.trim().toLowerCase();
    return products.where((product) {
      final categoryMatches =
          selectedCategory == BuyCategory.all ||
          product.category == selectedCategory;
      final queryMatches =
          normalized.isEmpty ||
          product.name.toLowerCase().contains(normalized) ||
          product.detail.toLowerCase().contains(normalized) ||
          product.seller.toLowerCase().contains(normalized);
      return categoryMatches && queryMatches;
    }).toList();
  }

  BuyProduct product(String id) {
    return products.firstWhere(
      (product) => product.id == id,
      orElse: () => products.first,
    );
  }

  int quantityFor(String productId) => _cart[productId]?.quantity ?? 0;

  void selectCategory(BuyCategory value) {
    selectedCategory = value;
    noticeMessage = null;
    errorMessage = null;
    notifyListeners();
  }

  bool addProduct(String productId, {int quantity = 1}) {
    final selected = product(productId);
    if (!selected.available) {
      errorMessage = '${selected.name} is not available today.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    final current = _cart[productId];
    _cart[productId] = BuyCartLine(
      product: selected,
      quantity: (current?.quantity ?? 0) + quantity,
    );
    errorMessage = null;
    noticeMessage = '${selected.name} added to your basket.';
    notifyListeners();
    return true;
  }

  void increase(String productId) {
    addProduct(productId);
  }

  void decrease(String productId) {
    final current = _cart[productId];
    if (current == null) return;
    if (current.quantity == 1) {
      _cart.remove(productId);
      noticeMessage = '${current.product.name} removed from your basket.';
    } else {
      _cart[productId] = current.copyWith(quantity: current.quantity - 1);
      noticeMessage = 'Quantity updated.';
    }
    errorMessage = null;
    notifyListeners();
  }

  void remove(String productId) {
    final removed = _cart.remove(productId);
    if (removed != null) {
      noticeMessage = '${removed.product.name} removed from your basket.';
      errorMessage = null;
      notifyListeners();
    }
  }

  void chooseHomeDelivery() {
    fulfilment = BuyFulfilment.homeDelivery;
    pickupStore = null;
    deliveryPromise = 'Deliver in 22–35 min';
    noticeMessage = 'Home delivery selected.';
    errorMessage = null;
    notifyListeners();
  }

  void chooseStorePickup(String store) {
    fulfilment = BuyFulfilment.storePickup;
    pickupStore = store;
    address = store;
    deliveryPromise = 'Ready to collect in 15–20 min';
    noticeMessage = 'Collection selected at $store.';
    errorMessage = null;
    notifyListeners();
  }

  bool updateAddress(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 8) {
      errorMessage = 'Enter a complete delivery address.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    address = trimmed;
    fulfilment = BuyFulfilment.homeDelivery;
    pickupStore = null;
    errorMessage = null;
    noticeMessage = 'Delivery address updated.';
    notifyListeners();
    return true;
  }

  void chooseDeliveryPromise(String value) {
    deliveryPromise = value;
    errorMessage = null;
    noticeMessage = 'Delivery time updated.';
    notifyListeners();
  }

  void chooseUnavailableRule(UnavailableItemRule value) {
    unavailableItemRule = value;
    errorMessage = null;
    noticeMessage = 'Unavailable-item preference saved.';
    notifyListeners();
  }

  bool applyCoupon(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) {
      errorMessage = 'Enter a coupon code.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (normalized != 'MOOL50') {
      errorMessage = 'This coupon is not valid.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (subtotal < 299) {
      errorMessage = 'Add ₹${299 - subtotal} more to use MOOL50.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    couponCode = normalized;
    errorMessage = null;
    noticeMessage = 'MOOL50 applied. You saved ₹50.';
    notifyListeners();
    return true;
  }

  void removeCoupon() {
    couponCode = null;
    errorMessage = null;
    noticeMessage = 'Coupon removed.';
    notifyListeners();
  }

  void choosePaymentMethod(BuyPaymentMethod value) {
    paymentMethod = value;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  Future<bool> placeOrder() async {
    if (busy) return false;
    if (_cart.isEmpty) {
      errorMessage = 'Your basket is empty. Add a product before checkout.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
    try {
      receipt = await _orderGateway.placeOrder(
        lines: cartLines,
        total: total,
        fulfilment: fulfilment,
        address: address,
        deliveryPromise: deliveryPromise,
        paymentMethod: paymentMethod,
      );
      orderStage = BuyOrderStage.confirmed;
      collectionStage = BuyCollectionStage.confirmed;
      noticeMessage = 'Order ${receipt!.id} is confirmed.';
      return true;
    } on BuyServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage =
          'The order could not be placed. Check your connection and try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void refreshOrderStatus() {
    if (orderStage == BuyOrderStage.delivered) {
      noticeMessage = 'Delivery status is up to date.';
      notifyListeners();
      return;
    }
    orderStage = BuyOrderStage.values[orderStage.index + 1];
    errorMessage = null;
    noticeMessage = orderStage.title;
    notifyListeners();
  }

  void refreshCollectionStatus() {
    if (collectionStage == BuyCollectionStage.collected) {
      noticeMessage = 'Collection status is up to date.';
      notifyListeners();
      return;
    }
    collectionStage = BuyCollectionStage.values[collectionStage.index + 1];
    errorMessage = null;
    noticeMessage = collectionStage.title;
    notifyListeners();
  }

  bool confirmCollection() {
    if (collectionStage.index < BuyCollectionStage.ready.index) {
      errorMessage = 'Wait until the shop marks your basket ready.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    collectionStage = BuyCollectionStage.collected;
    errorMessage = null;
    noticeMessage = 'Collection confirmed.';
    notifyListeners();
    return true;
  }

  void setShopRating(int value) {
    shopRating = value;
    ratingSubmitted = false;
    notifyListeners();
  }

  void setRiderRating(int value) {
    riderRating = value;
    ratingSubmitted = false;
    notifyListeners();
  }

  bool submitRating() {
    if (shopRating == 0 || riderRating == 0) {
      errorMessage = 'Rate both the shop and rider before submitting.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    ratingSubmitted = true;
    errorMessage = null;
    noticeMessage = 'Thank you. Your ratings were submitted.';
    notifyListeners();
    return true;
  }

  bool submitCollectionRating() {
    if (shopRating == 0) {
      errorMessage = 'Rate the shop before submitting.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    ratingSubmitted = true;
    errorMessage = null;
    noticeMessage = 'Thank you. Your shop rating was submitted.';
    notifyListeners();
    return true;
  }

  void clearMessages() {
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  void showNotice(String message) {
    errorMessage = null;
    noticeMessage = message;
    notifyListeners();
  }

  void startNewBasket() {
    _cart.clear();
    receipt = null;
    orderStage = BuyOrderStage.confirmed;
    collectionStage = BuyCollectionStage.confirmed;
    couponCode = null;
    ratingSubmitted = false;
    shopRating = 0;
    riderRating = 0;
    noticeMessage = null;
    errorMessage = null;
    fulfilment = BuyFulfilment.homeDelivery;
    address = 'Home · Sardarpura, Jodhpur';
    deliveryPromise = 'Deliver in 22–35 min';
    notifyListeners();
  }
}
