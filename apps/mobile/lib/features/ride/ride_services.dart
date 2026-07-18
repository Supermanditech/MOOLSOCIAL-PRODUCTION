import 'ride_models.dart';

class RideServiceException implements Exception {
  const RideServiceException(this.userMessage);

  final String userMessage;
}

abstract interface class RideGateway {
  Future<RideTrip> bookRide({
    required RidePackage package,
    required String pickup,
    required String drop,
    required String rideTime,
  });

  Future<void> approvePayment({
    required String tripId,
    required int amount,
    required RidePaymentMethod method,
  });

  Future<RideSupportTicket> createSupportTicket({
    required String tripId,
    required RideIssueType issueType,
    required String detail,
  });
}

class ReviewRideGateway implements RideGateway {
  ReviewRideGateway({
    this.failNextBooking = false,
    this.failNextPayment = false,
    this.failNextSupport = false,
    this.latency = const Duration(milliseconds: 120),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  bool failNextBooking;
  bool failNextPayment;
  bool failNextSupport;
  final Duration latency;
  final DateTime Function() _now;
  int _sequence = 3183;
  int bookingCalls = 0;
  int paymentCalls = 0;
  int supportCalls = 0;

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  @override
  Future<RideTrip> bookRide({
    required RidePackage package,
    required String pickup,
    required String drop,
    required String rideTime,
  }) async {
    bookingCalls += 1;
    await _wait();
    if (failNextBooking) {
      failNextBooking = false;
      throw const RideServiceException(
        'No captain accepted yet. No payment was taken. Try matching again or choose another ride.',
      );
    }
    _sequence += 1;
    return RideTrip(
      id: 'MS-RIDE-$_sequence',
      package: package,
      pickup: pickup,
      drop: drop,
      rideTime: rideTime,
      createdAt: _now(),
    );
  }

  @override
  Future<void> approvePayment({
    required String tripId,
    required int amount,
    required RidePaymentMethod method,
  }) async {
    paymentCalls += 1;
    await _wait();
    if (failNextPayment) {
      failNextPayment = false;
      throw const RideServiceException(
        'Payment could not be completed. No money was deducted. Try again or choose another method.',
      );
    }
  }

  @override
  Future<RideSupportTicket> createSupportTicket({
    required String tripId,
    required RideIssueType issueType,
    required String detail,
  }) async {
    supportCalls += 1;
    await _wait();
    if (failNextSupport) {
      failNextSupport = false;
      throw const RideServiceException(
        'Support could not attach the evidence yet. Your trip remains saved. Try again.',
      );
    }
    _sequence += 1;
    return RideSupportTicket(
      id: 'MS-SUPPORT-$_sequence',
      tripId: tripId,
      issueType: issueType,
      detail: detail,
      createdAt: _now(),
    );
  }
}
