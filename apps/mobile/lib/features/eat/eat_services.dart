import 'eat_models.dart';

class EatServiceException implements Exception {
  const EatServiceException(this.userMessage);

  final String userMessage;
}

abstract interface class EatOrderGateway {
  Future<EatOrderReceipt> placeFoodOrder({
    required EatRestaurant restaurant,
    required List<EatCartLine> lines,
    required int total,
    required EatFulfilment fulfilment,
    required String deliveryAddress,
    required String promise,
    required EatPaymentMethod paymentMethod,
  });

  Future<TableBookingReceipt> bookTable({
    required EatRestaurant restaurant,
    required String people,
    required String time,
    required String tableChoice,
    required int price,
  });

  Future<TiffinSubscriptionReceipt> startTiffin({
    required TiffinKitchen kitchen,
    required String foodStyle,
    required TiffinMeal meal,
    required String slot,
    required TiffinPlan plan,
    required int price,
    required String address,
  });
}

class ReviewEatOrderGateway implements EatOrderGateway {
  ReviewEatOrderGateway({
    this.failNextFoodOrder = false,
    this.failNextTableBooking = false,
    this.failNextTiffinStart = false,
    this.latency = const Duration(milliseconds: 120),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  bool failNextFoodOrder;
  bool failNextTableBooking;
  bool failNextTiffinStart;
  final Duration latency;
  final DateTime Function() _now;
  int _sequence = 2100;

  Future<void> _wait() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
  }

  @override
  Future<EatOrderReceipt> placeFoodOrder({
    required EatRestaurant restaurant,
    required List<EatCartLine> lines,
    required int total,
    required EatFulfilment fulfilment,
    required String deliveryAddress,
    required String promise,
    required EatPaymentMethod paymentMethod,
  }) async {
    await _wait();
    if (failNextFoodOrder) {
      failNextFoodOrder = false;
      throw const EatServiceException(
        'Payment could not be completed. No money was deducted. Try again.',
      );
    }
    _sequence += 1;
    return EatOrderReceipt(
      id: 'MS-EAT-$_sequence',
      createdAt: _now(),
      restaurant: restaurant,
      lines: List.unmodifiable(lines),
      total: total,
      fulfilment: fulfilment,
      deliveryAddress: deliveryAddress,
      promise: promise,
      paymentMethod: paymentMethod,
    );
  }

  @override
  Future<TableBookingReceipt> bookTable({
    required EatRestaurant restaurant,
    required String people,
    required String time,
    required String tableChoice,
    required int price,
  }) async {
    await _wait();
    if (failNextTableBooking) {
      failNextTableBooking = false;
      throw const EatServiceException(
        'The table was just taken. Choose the next time or try again.',
      );
    }
    _sequence += 1;
    return TableBookingReceipt(
      id: 'MS-TABLE-$_sequence',
      restaurant: restaurant,
      people: people,
      time: time,
      tableChoice: tableChoice,
      price: price,
      createdAt: _now(),
    );
  }

  @override
  Future<TiffinSubscriptionReceipt> startTiffin({
    required TiffinKitchen kitchen,
    required String foodStyle,
    required TiffinMeal meal,
    required String slot,
    required TiffinPlan plan,
    required int price,
    required String address,
  }) async {
    await _wait();
    if (failNextTiffinStart) {
      failNextTiffinStart = false;
      throw const EatServiceException(
        'The meal plan could not start. No money was deducted. Try again.',
      );
    }
    _sequence += 1;
    return TiffinSubscriptionReceipt(
      id: 'MS-TIFFIN-$_sequence',
      kitchen: kitchen,
      foodStyle: foodStyle,
      meal: meal,
      slot: slot,
      plan: plan,
      price: price,
      address: address,
      createdAt: _now(),
    );
  }
}
