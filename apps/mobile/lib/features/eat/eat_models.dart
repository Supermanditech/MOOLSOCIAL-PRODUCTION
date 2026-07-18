enum EatFulfilment { delivery, pickup, tableQr, scheduled }

enum EatMenuCategory { bestValue, meals, biryani, snacks, drinks, offers }

enum EatPaymentMethod { upi, wallet, card, payAtHandoff }

enum EatOrderStage { confirmed, preparing, riderAssigned, nearby, delivered }

enum TiffinMeal { lunch, dinner, lunchAndDinner, trialToday }

enum TiffinPlan { trial, weekly, monthly }

class EatRestaurant {
  const EatRestaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.area,
    required this.distance,
    required this.rating,
    required this.status,
    required this.offer,
    required this.bookingPrice,
    required this.bookingPriceLabel,
    required this.depositRule,
    required this.cancellationRule,
    required this.confirmationRule,
    this.available = true,
  });

  final String id;
  final String name;
  final String cuisine;
  final String area;
  final String distance;
  final double rating;
  final String status;
  final String offer;
  final int bookingPrice;
  final String bookingPriceLabel;
  final String depositRule;
  final String cancellationRule;
  final String confirmationRule;
  final bool available;
}

class EatMenuItem {
  const EatMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.readyIn,
    required this.offer,
    required this.cancelRule,
    required this.serves,
    this.available = true,
    this.customizable = false,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final EatMenuCategory category;
  final String readyIn;
  final String offer;
  final String cancelRule;
  final int serves;
  final bool available;
  final bool customizable;
}

class EatCartLine {
  const EatCartLine({
    required this.item,
    required this.quantity,
    this.customization,
  });

  final EatMenuItem item;
  final int quantity;
  final String? customization;

  int get total => item.price * quantity;

  EatCartLine copyWith({int? quantity, String? customization}) {
    return EatCartLine(
      item: item,
      quantity: quantity ?? this.quantity,
      customization: customization ?? this.customization,
    );
  }
}

class EatOrderReceipt {
  const EatOrderReceipt({
    required this.id,
    required this.createdAt,
    required this.restaurant,
    required this.lines,
    required this.total,
    required this.fulfilment,
    required this.deliveryAddress,
    required this.promise,
    required this.paymentMethod,
  });

  final String id;
  final DateTime createdAt;
  final EatRestaurant restaurant;
  final List<EatCartLine> lines;
  final int total;
  final EatFulfilment fulfilment;
  final String deliveryAddress;
  final String promise;
  final EatPaymentMethod paymentMethod;
}

class TableBookingReceipt {
  const TableBookingReceipt({
    required this.id,
    required this.restaurant,
    required this.people,
    required this.time,
    required this.tableChoice,
    required this.price,
    required this.createdAt,
  });

  final String id;
  final EatRestaurant restaurant;
  final String people;
  final String time;
  final String tableChoice;
  final int price;
  final DateTime createdAt;
}

class TiffinKitchen {
  const TiffinKitchen({
    required this.id,
    required this.name,
    required this.detail,
    required this.distance,
    required this.trust,
    required this.trialPrice,
    required this.weeklyPrice,
    required this.monthlyPrice,
    required this.pauseRule,
    required this.defaultSlot,
    this.available = true,
  });

  final String id;
  final String name;
  final String detail;
  final String distance;
  final String trust;
  final int trialPrice;
  final int weeklyPrice;
  final int monthlyPrice;
  final String pauseRule;
  final String defaultSlot;
  final bool available;
}

class TiffinSubscriptionReceipt {
  const TiffinSubscriptionReceipt({
    required this.id,
    required this.kitchen,
    required this.foodStyle,
    required this.meal,
    required this.slot,
    required this.plan,
    required this.price,
    required this.address,
    required this.createdAt,
  });

  final String id;
  final TiffinKitchen kitchen;
  final String foodStyle;
  final TiffinMeal meal;
  final String slot;
  final TiffinPlan plan;
  final int price;
  final String address;
  final DateTime createdAt;
}

extension EatFulfilmentCopy on EatFulfilment {
  String get label => switch (this) {
    EatFulfilment.delivery => 'Deliver',
    EatFulfilment.pickup => 'Pickup',
    EatFulfilment.tableQr => 'QR table',
    EatFulfilment.scheduled => 'Schedule',
  };
}

extension EatMenuCategoryCopy on EatMenuCategory {
  String get label => switch (this) {
    EatMenuCategory.bestValue => 'Best value',
    EatMenuCategory.meals => 'Meals',
    EatMenuCategory.biryani => 'Biryani',
    EatMenuCategory.snacks => 'Snacks',
    EatMenuCategory.drinks => 'Drinks',
    EatMenuCategory.offers => 'Offers',
  };
}

extension EatPaymentMethodCopy on EatPaymentMethod {
  String get label => switch (this) {
    EatPaymentMethod.upi => 'UPI',
    EatPaymentMethod.wallet => 'Mool wallet',
    EatPaymentMethod.card => 'Debit or credit card',
    EatPaymentMethod.payAtHandoff => 'Pay at handoff',
  };
}

extension EatOrderStageCopy on EatOrderStage {
  String get title => switch (this) {
    EatOrderStage.confirmed => 'Order confirmed',
    EatOrderStage.preparing => 'Your meal is being prepared',
    EatOrderStage.riderAssigned => 'Rider is collecting your meal',
    EatOrderStage.nearby => 'Your rider is nearby',
    EatOrderStage.delivered => 'Meal delivered',
  };

  String get detail => switch (this) {
    EatOrderStage.confirmed => 'The restaurant accepted your paid order.',
    EatOrderStage.preparing => 'Fresh preparation is in progress.',
    EatOrderStage.riderAssigned => 'The packed meal will be checked at pickup.',
    EatOrderStage.nearby => 'Keep your phone nearby for a smooth handoff.',
    EatOrderStage.delivered => 'Check the meal and confirm the handoff.',
  };
}

extension TiffinMealCopy on TiffinMeal {
  String get label => switch (this) {
    TiffinMeal.lunch => 'Lunch',
    TiffinMeal.dinner => 'Dinner',
    TiffinMeal.lunchAndDinner => 'Lunch + Dinner',
    TiffinMeal.trialToday => 'Trial today',
  };

  String get count => switch (this) {
    TiffinMeal.lunch || TiffinMeal.dinner => '26 meals',
    TiffinMeal.lunchAndDinner => '52 meals',
    TiffinMeal.trialToday => '1 meal',
  };
}

extension TiffinPlanCopy on TiffinPlan {
  String get label => switch (this) {
    TiffinPlan.trial => 'Trial meal',
    TiffinPlan.weekly => 'Weekly plan',
    TiffinPlan.monthly => 'Monthly plan',
  };

  String get period => switch (this) {
    TiffinPlan.trial => 'today',
    TiffinPlan.weekly => 'week',
    TiffinPlan.monthly => 'month',
  };
}
