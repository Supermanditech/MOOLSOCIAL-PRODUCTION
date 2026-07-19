enum BuyCategory { all, fresh, staples, dairy, homeCare, personalCare }

enum BuyFulfilment { homeDelivery, storePickup }

enum UnavailableItemRule { remove, askBeforeReplacing, allowSimilarItem }

enum BuyPaymentMethod { upi, wallet, card, cashOnDelivery }

enum BuyOrderStage { confirmed, packing, riderAssigned, nearby, delivered }

enum BuyCollectionStage { confirmed, packing, ready, collected }

class BuyProduct {
  const BuyProduct({
    required this.id,
    required this.name,
    required this.detail,
    required this.unitLabel,
    required this.price,
    required this.category,
    required this.seller,
    required this.deliveryPromise,
    required this.refundRule,
    this.available = true,
  });

  final String id;
  final String name;
  final String detail;
  final String unitLabel;
  final int price;
  final BuyCategory category;
  final String seller;
  final String deliveryPromise;
  final String refundRule;
  final bool available;
}

class BuyCartLine {
  const BuyCartLine({required this.product, required this.quantity});

  final BuyProduct product;
  final int quantity;

  int get total => product.price * quantity;

  BuyCartLine copyWith({int? quantity}) {
    return BuyCartLine(product: product, quantity: quantity ?? this.quantity);
  }
}

class BuyOrderReceipt {
  const BuyOrderReceipt({
    required this.id,
    required this.createdAt,
    required this.lines,
    required this.total,
    required this.fulfilment,
    required this.address,
    required this.deliveryPromise,
    required this.paymentMethod,
  });

  final String id;
  final DateTime createdAt;
  final List<BuyCartLine> lines;
  final int total;
  final BuyFulfilment fulfilment;
  final String address;
  final String deliveryPromise;
  final BuyPaymentMethod paymentMethod;
}

extension BuyCategoryCopy on BuyCategory {
  String get label => switch (this) {
    BuyCategory.all => 'All',
    BuyCategory.fresh => 'Fresh',
    BuyCategory.staples => 'Staples',
    BuyCategory.dairy => 'Dairy',
    BuyCategory.homeCare => 'Home care',
    BuyCategory.personalCare => 'Personal care',
  };
}

extension BuyFulfilmentCopy on BuyFulfilment {
  String get label => switch (this) {
    BuyFulfilment.homeDelivery => 'Deliver to home',
    BuyFulfilment.storePickup => 'Collect from store',
  };
}

extension BuyPaymentMethodCopy on BuyPaymentMethod {
  String get label => switch (this) {
    BuyPaymentMethod.upi => 'UPI',
    BuyPaymentMethod.wallet => 'Mool wallet',
    BuyPaymentMethod.card => 'Debit or credit card',
    BuyPaymentMethod.cashOnDelivery => 'Pay on delivery',
  };
}

extension BuyOrderStageCopy on BuyOrderStage {
  String get title => switch (this) {
    BuyOrderStage.confirmed => 'Order confirmed',
    BuyOrderStage.packing => 'Shop is packing your basket',
    BuyOrderStage.riderAssigned => 'Rider is collecting your order',
    BuyOrderStage.nearby => 'Your rider is nearby',
    BuyOrderStage.delivered => 'Delivered at your doorstep',
  };

  String get detail => switch (this) {
    BuyOrderStage.confirmed => 'The shop received your paid order.',
    BuyOrderStage.packing => 'Items are being checked and packed.',
    BuyOrderStage.riderAssigned => 'Rakesh is on the way to the shop.',
    BuyOrderStage.nearby =>
      'Keep your phone nearby so the rider can complete delivery.',
    BuyOrderStage.delivered =>
      'Check the basket and confirm everything arrived.',
  };
}

extension BuyCollectionStageCopy on BuyCollectionStage {
  String get title => switch (this) {
    BuyCollectionStage.confirmed => 'Collection order confirmed',
    BuyCollectionStage.packing => 'Shop is packing your basket',
    BuyCollectionStage.ready => 'Ready to collect',
    BuyCollectionStage.collected => 'Collected from the store',
  };

  String get detail => switch (this) {
    BuyCollectionStage.confirmed =>
      'The shop received your order and collection choice.',
    BuyCollectionStage.packing =>
      'Items are being checked before you travel to the store.',
    BuyCollectionStage.ready =>
      'Show your collection code at the selected store.',
    BuyCollectionStage.collected =>
      'Your collection was confirmed at the counter.',
  };
}
