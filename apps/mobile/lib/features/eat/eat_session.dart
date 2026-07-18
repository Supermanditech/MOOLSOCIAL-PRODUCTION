import 'package:flutter/foundation.dart';

import 'eat_models.dart';
import 'eat_services.dart';

class EatSession extends ChangeNotifier {
  EatSession({EatOrderGateway? gateway})
    : _gateway = gateway ?? ReviewEatOrderGateway();

  final EatOrderGateway _gateway;

  static const restaurants = <EatRestaurant>[
    EatRestaurant(
      id: 'spice-darbar',
      name: 'Spice Darbar',
      cuisine: 'North Indian',
      area: 'Ratanada',
      distance: '1.1 km',
      rating: 4.7,
      status: 'Kitchen open · instant confirmation',
      offer: '10% reward',
      bookingPrice: 0,
      bookingPriceLabel: 'booking',
      depositRule: 'No deposit',
      cancellationRule: 'Cancel free till 7:00 PM',
      confirmationRule: 'Instant confirmation',
    ),
    EatRestaurant(
      id: 'taj-jodhpur',
      name: 'Taj Jodhpur',
      cuisine: 'Premium dining',
      area: 'Circuit House Road',
      distance: '3.8 km',
      rating: 4.8,
      status: '7:30 PM available',
      offer: 'Dining points',
      bookingPrice: 1500,
      bookingPriceLabel: 'cover',
      depositRule: 'Cover adjusted in your bill',
      cancellationRule: 'Cancel free till 6:30 PM',
      confirmationRule: 'Instant confirmation',
    ),
    EatRestaurant(
      id: 'blue-lime',
      name: 'Blue Lime Cafe',
      cuisine: 'Cafe',
      area: 'Sardarpura',
      distance: '2.4 km',
      rating: 4.5,
      status: 'Window table open',
      offer: 'Free dessert',
      bookingPrice: 0,
      bookingPriceLabel: 'booking',
      depositRule: 'No deposit',
      cancellationRule: 'Cancel free till 7:30 PM',
      confirmationRule: 'Instant confirmation',
    ),
    EatRestaurant(
      id: 'raas-rooftop',
      name: 'Raas Rooftop',
      cuisine: 'Rooftop dining',
      area: 'Old City',
      distance: '4.2 km',
      rating: 4.6,
      status: 'Sunset slot open',
      offer: 'Sunset offer',
      bookingPrice: 500,
      bookingPriceLabel: 'hold',
      depositRule: 'Hold amount adjusted in your bill',
      cancellationRule: 'Cancel free till 6:45 PM',
      confirmationRule: 'Quick confirmation',
    ),
    EatRestaurant(
      id: 'closed-kitchen',
      name: 'Garden Kitchen',
      cuisine: 'Multi-cuisine',
      area: 'Paota',
      distance: '2.9 km',
      rating: 4.2,
      status: 'Closed today',
      offer: 'No active offer',
      bookingPrice: 0,
      bookingPriceLabel: 'booking',
      depositRule: 'No deposit',
      cancellationRule: 'No booking available',
      confirmationRule: 'Choose another restaurant',
      available: false,
    ),
  ];

  static const menuItems = <EatMenuItem>[
    EatMenuItem(
      id: 'veg-thali',
      name: 'Veg thali',
      description: '2 rotis · dal · sabzi · rice · salad',
      price: 149,
      category: EatMenuCategory.meals,
      readyIn: '22 min',
      offer: '10% reward',
      cancelRule: 'Cancel before restaurant accepts',
      serves: 1,
      customizable: true,
    ),
    EatMenuItem(
      id: 'paneer-combo',
      name: 'Paneer butter combo',
      description: 'Paneer · 3 rotis · jeera rice · no-onion option',
      price: 229,
      category: EatMenuCategory.bestValue,
      readyIn: '26 min',
      offer: 'Freshly prepared',
      cancelRule: 'Cancel before restaurant accepts',
      serves: 2,
      customizable: true,
    ),
    EatMenuItem(
      id: 'family-biryani',
      name: 'Family biryani pack',
      description: 'Biryani · raita · salad · shareable pack',
      price: 449,
      category: EatMenuCategory.biryani,
      readyIn: '31 min',
      offer: 'Save ₹40',
      cancelRule: 'Cancel before restaurant accepts',
      serves: 3,
      customizable: true,
    ),
    EatMenuItem(
      id: 'masala-chai',
      name: 'Masala chai',
      description: 'Fresh ginger tea',
      price: 49,
      category: EatMenuCategory.drinks,
      readyIn: '12 min',
      offer: 'Add-on price',
      cancelRule: 'Cancel before preparation',
      serves: 1,
    ),
    EatMenuItem(
      id: 'kesar-lassi',
      name: 'Kesar lassi',
      description: 'Chilled sweet lassi',
      price: 89,
      category: EatMenuCategory.drinks,
      readyIn: '10 min',
      offer: 'Today only',
      cancelRule: 'Cancel before preparation',
      serves: 1,
    ),
    EatMenuItem(
      id: 'samosa',
      name: 'Samosa pair',
      description: 'Next fresh batch at 5:30 PM',
      price: 70,
      category: EatMenuCategory.snacks,
      readyIn: 'Not available',
      offer: 'No charge',
      cancelRule: 'Choose an alternative',
      serves: 1,
      available: false,
    ),
  ];

  static const tiffinKitchens = <TiffinKitchen>[
    TiffinKitchen(
      id: 'maa-tiffin',
      name: 'Maa Tiffin',
      detail: 'Home kitchen',
      distance: '2.0 km',
      trust: 'Home kitchen verified',
      trialPrice: 79,
      weeklyPrice: 720,
      monthlyPrice: 2850,
      pauseRule: 'Skip up to 4 meals',
      defaultSlot: '12:30 PM',
    ),
    TiffinKitchen(
      id: 'jain-satvik',
      name: 'Jain Satvik',
      detail: 'No onion or garlic',
      distance: '3.1 km',
      trust: 'Jain kitchen verified',
      trialPrice: 99,
      weeklyPrice: 840,
      monthlyPrice: 3200,
      pauseRule: 'Skip up to 3 meals',
      defaultSlot: '12:45 PM',
    ),
    TiffinKitchen(
      id: 'office-meal',
      name: 'Office Meal Co',
      detail: 'Office lunch route',
      distance: '4.4 km',
      trust: 'Office delivery route verified',
      trialPrice: 89,
      weeklyPrice: 690,
      monthlyPrice: 2650,
      pauseRule: 'Skip up to 5 meals',
      defaultSlot: '1:15 PM',
    ),
    TiffinKitchen(
      id: 'paused-kitchen',
      name: 'Daily Bowl',
      detail: 'Home-style meals',
      distance: '3.6 km',
      trust: 'Kitchen paused',
      trialPrice: 85,
      weeklyPrice: 700,
      monthlyPrice: 2700,
      pauseRule: 'New plans unavailable',
      defaultSlot: '12:30 PM',
      available: false,
    ),
  ];

  final Map<String, EatCartLine> _cart = {};
  String selectedRestaurantId = restaurants.first.id;
  EatMenuCategory selectedCategory = EatMenuCategory.bestValue;
  EatFulfilment fulfilment = EatFulfilment.delivery;
  EatPaymentMethod paymentMethod = EatPaymentMethod.upi;
  DateTime? scheduledDate;
  String? scheduledTime;
  String deliveryAddress = 'Home · Sardarpura, Jodhpur';
  String? noticeMessage;
  String? errorMessage;
  bool busy = false;
  EatOrderReceipt? orderReceipt;
  EatOrderStage orderStage = EatOrderStage.confirmed;
  bool foodOrderCancelled = false;
  int foodRating = 0;

  String tableRestaurantId = restaurants.first.id;
  String tablePeople = '4';
  String tableTime = '7:30 PM';
  String tableChoice = 'Standard table';
  int tableChoicePrice = 0;
  TableBookingReceipt? tableReceipt;
  bool tableBookingCancelled = false;

  String selectedKitchenId = tiffinKitchens.first.id;
  String foodStyle = 'Regular veg';
  TiffinMeal tiffinMeal = TiffinMeal.lunch;
  String tiffinSlot = '12:30 PM';
  TiffinPlan tiffinPlan = TiffinPlan.monthly;
  String tiffinAddress = 'Home · Sardarpura, Jodhpur';
  TiffinSubscriptionReceipt? tiffinReceipt;
  bool tiffinPaused = false;
  bool nextMealSkipped = false;
  bool tiffinCancelled = false;

  EatRestaurant get selectedRestaurant =>
      restaurants.firstWhere((item) => item.id == selectedRestaurantId);

  EatRestaurant get tableRestaurant =>
      restaurants.firstWhere((item) => item.id == tableRestaurantId);

  TiffinKitchen get selectedKitchen =>
      tiffinKitchens.firstWhere((item) => item.id == selectedKitchenId);

  List<EatCartLine> get cartLines => List.unmodifiable(_cart.values);

  int get itemCount =>
      _cart.values.fold(0, (total, line) => total + line.quantity);

  int get subtotal => _cart.values.fold(0, (total, line) => total + line.total);

  int get deliveryFee => switch (fulfilment) {
    EatFulfilment.delivery ||
    EatFulfilment.scheduled => subtotal >= 499 ? 0 : 19,
    EatFulfilment.pickup || EatFulfilment.tableQr => 0,
  };

  int get taxes => (subtotal * .05).round();

  int get orderTotal => subtotal + deliveryFee + taxes;

  String get fulfilmentPromise => switch (fulfilment) {
    EatFulfilment.delivery => 'Deliver in 22–35 min',
    EatFulfilment.pickup => 'Ready for pickup in 15–20 min',
    EatFulfilment.tableQr => 'Serve at your table in 12–20 min',
    EatFulfilment.scheduled =>
      scheduledDate == null || scheduledTime == null
          ? 'Choose and confirm a delivery time'
          : 'Scheduled for ${scheduledDate!.day}/${scheduledDate!.month} at $scheduledTime',
  };

  int get tiffinPrice => switch (tiffinPlan) {
    TiffinPlan.trial => selectedKitchen.trialPrice,
    TiffinPlan.weekly => selectedKitchen.weeklyPrice,
    TiffinPlan.monthly => selectedKitchen.monthlyPrice,
  };

  List<EatRestaurant> visibleRestaurants(String query) {
    final normalized = query.trim().toLowerCase();
    return restaurants.where((restaurant) {
      return normalized.isEmpty ||
          restaurant.name.toLowerCase().contains(normalized) ||
          restaurant.cuisine.toLowerCase().contains(normalized) ||
          restaurant.area.toLowerCase().contains(normalized);
    }).toList();
  }

  List<EatMenuItem> visibleMenu(String query) {
    final normalized = query.trim().toLowerCase();
    return menuItems.where((item) {
      final categoryMatches =
          selectedCategory == EatMenuCategory.bestValue ||
          selectedCategory == EatMenuCategory.offers ||
          item.category == selectedCategory;
      final queryMatches =
          normalized.isEmpty ||
          item.name.toLowerCase().contains(normalized) ||
          item.description.toLowerCase().contains(normalized);
      return categoryMatches && queryMatches;
    }).toList();
  }

  EatMenuItem menuItem(String id) =>
      menuItems.firstWhere((item) => item.id == id);

  int quantityFor(String itemId) => _cart[itemId]?.quantity ?? 0;

  void selectRestaurant(String id) {
    final restaurant = restaurants.firstWhere((item) => item.id == id);
    if (!restaurant.available) {
      errorMessage =
          '${restaurant.name} is closed today. Choose another restaurant.';
      noticeMessage = null;
      notifyListeners();
      return;
    }
    selectedRestaurantId = id;
    errorMessage = null;
    noticeMessage = '${restaurant.name} selected.';
    notifyListeners();
  }

  void selectMenuCategory(EatMenuCategory value) {
    selectedCategory = value;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  void chooseFulfilment(EatFulfilment value) {
    fulfilment = value;
    errorMessage = null;
    noticeMessage = value == EatFulfilment.scheduled
        ? 'Choose a date and time, then confirm the slot.'
        : '${value.label} selected.';
    notifyListeners();
  }

  bool confirmSchedule(DateTime? date, String time) {
    if (date == null || time.trim().isEmpty) {
      errorMessage = 'Choose both a delivery date and time.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (date.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    )) {
      errorMessage = 'Choose today or a future date.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    scheduledDate = date;
    scheduledTime = time.trim();
    fulfilment = EatFulfilment.scheduled;
    errorMessage = null;
    noticeMessage = 'Delivery slot confirmed for $scheduledTime.';
    notifyListeners();
    return true;
  }

  bool updateDeliveryAddress(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 8) {
      errorMessage = 'Enter a complete delivery address.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    deliveryAddress = trimmed;
    errorMessage = null;
    noticeMessage = 'Delivery address updated.';
    notifyListeners();
    return true;
  }

  bool addMenuItem(String id, {String? customization}) {
    final item = menuItem(id);
    if (!item.available) {
      errorMessage = '${item.name} is not available. Choose another item.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    final current = _cart[id];
    _cart[id] = EatCartLine(
      item: item,
      quantity: (current?.quantity ?? 0) + 1,
      customization: customization ?? current?.customization,
    );
    errorMessage = null;
    noticeMessage = current == null
        ? '${item.name} added to your food basket.'
        : '${item.name} quantity increased.';
    notifyListeners();
    return true;
  }

  void customizeMenuItem(String id, String value) {
    final current = _cart[id];
    if (current == null) {
      addMenuItem(id, customization: value);
      return;
    }
    _cart[id] = current.copyWith(customization: value);
    errorMessage = null;
    noticeMessage = 'Customization saved for ${current.item.name}.';
    notifyListeners();
  }

  void increase(String id) => addMenuItem(id);

  void decrease(String id) {
    final current = _cart[id];
    if (current == null) return;
    if (current.quantity <= 1) {
      _cart.remove(id);
      noticeMessage = '${current.item.name} removed from your food basket.';
    } else {
      _cart[id] = current.copyWith(quantity: current.quantity - 1);
      noticeMessage = 'Quantity updated.';
    }
    errorMessage = null;
    notifyListeners();
  }

  void remove(String id) {
    final removed = _cart.remove(id);
    if (removed != null) {
      errorMessage = null;
      noticeMessage = '${removed.item.name} removed from your food basket.';
      notifyListeners();
    }
  }

  void choosePaymentMethod(EatPaymentMethod value) {
    paymentMethod = value;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  Future<bool> placeFoodOrder() async {
    if (busy) return false;
    if (_cart.isEmpty) {
      errorMessage = 'Your food basket is empty. Add an item before payment.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (fulfilment == EatFulfilment.scheduled &&
        (scheduledDate == null || scheduledTime == null)) {
      errorMessage = 'Confirm your scheduled delivery time before payment.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
    try {
      orderReceipt = await _gateway.placeFoodOrder(
        restaurant: selectedRestaurant,
        lines: cartLines,
        total: orderTotal,
        fulfilment: fulfilment,
        deliveryAddress: deliveryAddress,
        promise: fulfilmentPromise,
        paymentMethod: paymentMethod,
      );
      orderStage = EatOrderStage.confirmed;
      foodOrderCancelled = false;
      noticeMessage = 'Order ${orderReceipt!.id} is confirmed.';
      return true;
    } on EatServiceException catch (error) {
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

  void refreshFoodOrder() {
    if (foodOrderCancelled) {
      noticeMessage = 'This order is cancelled.';
    } else if (orderStage == EatOrderStage.delivered) {
      noticeMessage = 'Delivery status is up to date.';
    } else {
      orderStage = EatOrderStage.values[orderStage.index + 1];
      noticeMessage = orderStage.title;
    }
    errorMessage = null;
    notifyListeners();
  }

  bool cancelFoodOrder() {
    if (orderStage.index > EatOrderStage.confirmed.index) {
      errorMessage =
          'Preparation has started. Open support to check cancellation options.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    foodOrderCancelled = true;
    errorMessage = null;
    noticeMessage = 'Order cancelled. Your refund is being processed.';
    notifyListeners();
    return true;
  }

  void setFoodRating(int value) {
    foodRating = value;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  bool submitFoodRating() {
    if (foodRating == 0) {
      errorMessage = 'Choose a rating before submitting.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    errorMessage = null;
    noticeMessage = 'Thank you. Your meal rating was submitted.';
    notifyListeners();
    return true;
  }

  void selectTableRestaurant(String id) {
    final restaurant = restaurants.firstWhere((item) => item.id == id);
    if (!restaurant.available) {
      errorMessage =
          '${restaurant.name} has no tables today. Choose another restaurant.';
      noticeMessage = null;
      notifyListeners();
      return;
    }
    tableRestaurantId = id;
    errorMessage = null;
    noticeMessage = '${restaurant.name} selected for your table.';
    notifyListeners();
  }

  void chooseTablePeople(String value) {
    tablePeople = value;
    errorMessage = null;
    noticeMessage = '$value people selected.';
    notifyListeners();
  }

  void chooseTableTime(String value) {
    tableTime = value;
    errorMessage = null;
    noticeMessage = '$value selected.';
    notifyListeners();
  }

  void chooseTableType(String value, int price) {
    tableChoice = value;
    tableChoicePrice = price;
    errorMessage = null;
    noticeMessage = '$value selected.';
    notifyListeners();
  }

  Future<bool> bookTable() async {
    if (busy) return false;
    if (tablePeople.isEmpty || tableTime.isEmpty || tableChoice.isEmpty) {
      errorMessage = 'Choose people, time and table before booking.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
    try {
      tableReceipt = await _gateway.bookTable(
        restaurant: tableRestaurant,
        people: tablePeople,
        time: tableTime,
        tableChoice: tableChoice,
        price: tableRestaurant.bookingPrice + tableChoicePrice,
      );
      tableBookingCancelled = false;
      noticeMessage = 'Table ${tableReceipt!.id} is confirmed.';
      return true;
    } on EatServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage =
          'The table could not be booked. Check your connection and try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void cancelTableBooking() {
    if (tableReceipt == null || tableBookingCancelled) {
      errorMessage = 'There is no active table booking to cancel.';
      noticeMessage = null;
    } else {
      tableBookingCancelled = true;
      errorMessage = null;
      noticeMessage = 'Table booking cancelled with no cancellation fee.';
    }
    notifyListeners();
  }

  void selectTiffinKitchen(String id) {
    final kitchen = tiffinKitchens.firstWhere((item) => item.id == id);
    if (!kitchen.available) {
      errorMessage = '${kitchen.name} is paused. Choose another kitchen.';
      noticeMessage = null;
      notifyListeners();
      return;
    }
    selectedKitchenId = id;
    tiffinSlot = kitchen.defaultSlot;
    errorMessage = null;
    noticeMessage = '${kitchen.name} selected.';
    notifyListeners();
  }

  void chooseFoodStyle(String value) {
    foodStyle = value;
    errorMessage = null;
    noticeMessage = '$value menu selected.';
    notifyListeners();
  }

  void chooseTiffinMeal(TiffinMeal value) {
    tiffinMeal = value;
    if (value == TiffinMeal.trialToday) tiffinPlan = TiffinPlan.trial;
    errorMessage = null;
    noticeMessage = '${value.label} selected.';
    notifyListeners();
  }

  void chooseTiffinSlot(String value) {
    tiffinSlot = value;
    errorMessage = null;
    noticeMessage = '$value delivery selected.';
    notifyListeners();
  }

  void chooseTiffinPlan(TiffinPlan value) {
    tiffinPlan = value;
    if (value == TiffinPlan.trial) tiffinMeal = TiffinMeal.trialToday;
    errorMessage = null;
    noticeMessage = '${value.label} selected.';
    notifyListeners();
  }

  bool updateTiffinAddress(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 8) {
      errorMessage = 'Enter a complete home, office or hostel address.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    tiffinAddress = trimmed;
    errorMessage = null;
    noticeMessage = 'Tiffin address updated.';
    notifyListeners();
    return true;
  }

  Future<bool> startTiffin() async {
    if (busy) return false;
    if (!selectedKitchen.available) {
      errorMessage = 'Choose an available kitchen before continuing.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (tiffinAddress.trim().length < 8) {
      errorMessage = 'Enter a complete delivery address.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
    try {
      tiffinReceipt = await _gateway.startTiffin(
        kitchen: selectedKitchen,
        foodStyle: foodStyle,
        meal: tiffinMeal,
        slot: tiffinSlot,
        plan: tiffinPlan,
        price: tiffinPrice,
        address: tiffinAddress,
      );
      tiffinPaused = false;
      nextMealSkipped = false;
      tiffinCancelled = false;
      noticeMessage = '${tiffinPlan.label} started.';
      return true;
    } on EatServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage =
          'The meal plan could not start. Check your connection and try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void toggleTiffinPause() {
    if (tiffinReceipt == null || tiffinCancelled) {
      errorMessage = 'There is no active meal plan to pause.';
      noticeMessage = null;
    } else {
      tiffinPaused = !tiffinPaused;
      errorMessage = null;
      noticeMessage = tiffinPaused
          ? 'Meal plan paused before the next cycle.'
          : 'Meal plan resumed.';
    }
    notifyListeners();
  }

  void toggleNextMealSkip() {
    if (tiffinReceipt == null || tiffinCancelled) {
      errorMessage = 'There is no active meal to skip.';
      noticeMessage = null;
    } else {
      nextMealSkipped = !nextMealSkipped;
      errorMessage = null;
      noticeMessage = nextMealSkipped
          ? 'Next meal skipped before the kitchen cutoff.'
          : 'Next meal restored.';
    }
    notifyListeners();
  }

  void cancelTiffin() {
    if (tiffinReceipt == null || tiffinCancelled) {
      errorMessage = 'There is no active meal plan to cancel.';
      noticeMessage = null;
    } else {
      tiffinCancelled = true;
      errorMessage = null;
      noticeMessage = 'Meal plan will stop before the next billing cycle.';
    }
    notifyListeners();
  }

  void showNotice(String value) {
    errorMessage = null;
    noticeMessage = value;
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  void startNewFoodOrder() {
    _cart.clear();
    orderReceipt = null;
    orderStage = EatOrderStage.confirmed;
    foodOrderCancelled = false;
    foodRating = 0;
    fulfilment = EatFulfilment.delivery;
    scheduledDate = null;
    scheduledTime = null;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }
}
