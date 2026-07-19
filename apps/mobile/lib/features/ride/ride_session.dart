import 'package:flutter/foundation.dart';

import 'ride_models.dart';
import 'ride_services.dart';

class RideSession extends ChangeNotifier {
  RideSession({RideGateway? gateway})
    : _gateway = gateway ?? ReviewRideGateway();

  final RideGateway _gateway;

  static const packages = <RidePackage>[
    RidePackage(
      id: 'bike-saver',
      type: RideType.bike,
      name: 'Bike Saver',
      fare: 59,
      arrivalMinutes: 7,
      capacity: '1 seat',
      note: 'lowest fare',
      nearbyCaptains: 8,
    ),
    RidePackage(
      id: 'bike-now',
      type: RideType.bike,
      name: 'Bike Now',
      fare: 68,
      arrivalMinutes: 3,
      capacity: '1 seat',
      note: 'fastest pickup',
      nearbyCaptains: 11,
    ),
    RidePackage(
      id: 'bike-courier',
      type: RideType.bike,
      name: 'Bike Courier',
      fare: 49,
      arrivalMinutes: 4,
      capacity: 'small parcel',
      note: 'send an item',
      nearbyCaptains: 5,
    ),
    RidePackage(
      id: 'auto',
      type: RideType.auto,
      name: 'Auto',
      fare: 112,
      arrivalMinutes: 5,
      capacity: '3 seats',
      note: 'routine fare',
      nearbyCaptains: 12,
    ),
    RidePackage(
      id: 'auto-plus',
      type: RideType.auto,
      name: 'Auto Plus',
      fare: 138,
      arrivalMinutes: 5,
      capacity: 'luggage space',
      note: 'extra room',
      nearbyCaptains: 4,
    ),
    RidePackage(
      id: 'shared-auto',
      type: RideType.auto,
      name: 'Shared Auto',
      fare: 45,
      arrivalMinutes: 8,
      capacity: 'shared route',
      note: 'lower fare',
      nearbyCaptains: 6,
    ),
    RidePackage(
      id: 'cab-mini',
      type: RideType.cab,
      name: 'Mini',
      fare: 186,
      arrivalMinutes: 6,
      capacity: '4 seats',
      note: 'city cab',
      nearbyCaptains: 7,
    ),
    RidePackage(
      id: 'cab-sedan',
      type: RideType.cab,
      name: 'Sedan',
      fare: 238,
      arrivalMinutes: 7,
      capacity: '4 seats',
      note: 'comfort',
      nearbyCaptains: 5,
    ),
    RidePackage(
      id: 'cab-xl',
      type: RideType.cab,
      name: 'XL',
      fare: 312,
      arrivalMinutes: 9,
      capacity: '6 seats',
      note: 'family ride',
      nearbyCaptains: 3,
    ),
    RidePackage(
      id: 'cab-rental',
      type: RideType.cab,
      name: 'Rental 2 hr',
      fare: 599,
      arrivalMinutes: 10,
      capacity: '2-hour rental',
      note: 'wait included',
      nearbyCaptains: 2,
    ),
  ];

  String pickup = 'Sardarpura pickup gate, Jodhpur';
  String drop = 'Railway Station main gate';
  RideTime rideTime = RideTime.now;
  DateTime? scheduledDate;
  String? scheduledTime;
  RideType selectedType = RideType.auto;
  String selectedPackageId = 'auto';
  RidePaymentMethod paymentMethod = RidePaymentMethod.card;
  RideTrip? trip;
  RideTripStage stage = RideTripStage.captainArriving;
  String pickupNote = 'Stand near Mahadev Fresh Mart board';
  bool rideCancelled = false;
  String? addedStop;
  int fare = 112;
  bool busy = false;
  int rating = 0;
  final Set<String> compliments = {'Clean ride'};
  RideIssueType issueType = RideIssueType.missingItem;
  String missingItem = 'Phone';
  RideSupportTicket? supportTicket;
  String? noticeMessage;
  String? errorMessage;

  RidePackage get selectedPackage =>
      packages.firstWhere((item) => item.id == selectedPackageId);

  List<RidePackage> get visiblePackages =>
      packages.where((item) => item.type == selectedType).toList();

  bool updateRoute({required String pickupValue, required String dropValue}) {
    final newPickup = pickupValue.trim();
    final newDrop = dropValue.trim();
    if (newPickup.length < 5 || newDrop.length < 5) {
      errorMessage = 'Enter a complete pickup and destination.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (newPickup.toLowerCase() == newDrop.toLowerCase()) {
      errorMessage = 'Pickup and destination must be different.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    pickup = newPickup;
    drop = newDrop;
    errorMessage = null;
    noticeMessage = 'Route updated.';
    notifyListeners();
    return true;
  }

  void chooseType(RideType value) {
    selectedType = value;
    selectedPackageId = packages.firstWhere((item) => item.type == value).id;
    fare = selectedPackage.fare;
    errorMessage = null;
    noticeMessage = '${value.label} selected.';
    notifyListeners();
  }

  void prepareBooking(RideType value) {
    reset();
    selectedType = value;
    selectedPackageId = packages.firstWhere((item) => item.type == value).id;
    fare = selectedPackage.fare;
    noticeMessage = null;
    notifyListeners();
  }

  void choosePackage(String id) {
    selectedPackageId = id;
    fare = selectedPackage.fare;
    errorMessage = null;
    noticeMessage = '${selectedPackage.name} selected.';
    notifyListeners();
  }

  void chooseRideTime(RideTime value) {
    rideTime = value;
    errorMessage = null;
    noticeMessage = value == RideTime.scheduled
        ? 'Choose and confirm your pickup time.'
        : '${value.label} selected.';
    notifyListeners();
  }

  bool confirmSchedule(DateTime? date, String time) {
    if (date == null || time.trim().isEmpty) {
      errorMessage = 'Choose both a pickup date and time.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    scheduledDate = date;
    scheduledTime = time.trim();
    rideTime = RideTime.scheduled;
    errorMessage = null;
    noticeMessage = 'Ride scheduled for $scheduledTime.';
    notifyListeners();
    return true;
  }

  String get rideTimeLabel => switch (rideTime) {
    RideTime.now => 'Now',
    RideTime.after15Minutes => 'After 15 min',
    RideTime.scheduled =>
      scheduledDate == null || scheduledTime == null
          ? 'Schedule not confirmed'
          : '${scheduledDate!.day}/${scheduledDate!.month} at $scheduledTime',
  };

  Future<bool> bookRide() async {
    if (busy) return false;
    if (rideTime == RideTime.scheduled &&
        (scheduledDate == null || scheduledTime == null)) {
      errorMessage = 'Confirm the scheduled pickup before booking.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
    try {
      trip = await _gateway.bookRide(
        package: selectedPackage,
        pickup: pickup,
        drop: drop,
        rideTime: rideTimeLabel,
      );
      fare = selectedPackage.fare;
      stage = RideTripStage.captainArriving;
      rideCancelled = false;
      addedStop = null;
      noticeMessage = 'Captain Arjun accepted your ride.';
      return true;
    } on RideServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage =
          'The ride could not be booked. Check your connection and try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  bool updatePickupNote(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 5) {
      errorMessage = 'Enter a visible landmark or pickup instruction.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    pickupNote = trimmed;
    errorMessage = null;
    noticeMessage = 'Pickup instruction saved.';
    notifyListeners();
    return true;
  }

  void cancelRide() {
    if (stage != RideTripStage.captainArriving || rideCancelled) {
      errorMessage = 'This ride can no longer be cancelled here.';
      noticeMessage = null;
    } else {
      rideCancelled = true;
      errorMessage = null;
      noticeMessage = 'Ride cancelled with ₹0 fee. No payment was taken.';
    }
    notifyListeners();
  }

  void startTrip() {
    if (rideCancelled) return;
    stage = RideTripStage.liveTrip;
    errorMessage = null;
    noticeMessage = 'Trip started. Route and safety controls are live.';
    notifyListeners();
  }

  bool reviewAddedStop(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 5) {
      errorMessage = 'Enter a landmark or address for the added stop.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    addedStop = trimmed;
    fare = selectedPackage.fare + 26;
    errorMessage = null;
    noticeMessage = '$trimmed added. New estimated fare is ₹$fare.';
    notifyListeners();
    return true;
  }

  void choosePayment(RidePaymentMethod value) {
    paymentMethod = value;
    errorMessage = null;
    noticeMessage = value == RidePaymentMethod.card
        ? 'Card remains on hold until you approve the final fare.'
        : '${value.label} selected for trip end.';
    notifyListeners();
  }

  void reachDestination() {
    stage = RideTripStage.paymentApproval;
    errorMessage = null;
    noticeMessage = 'Destination reached. Review the final fare before paying.';
    notifyListeners();
  }

  Future<bool> approvePayment() async {
    if (busy || trip == null || stage != RideTripStage.paymentApproval) {
      return false;
    }
    busy = true;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
    try {
      await _gateway.approvePayment(
        tripId: trip!.id,
        amount: fare,
        method: paymentMethod,
      );
      stage = RideTripStage.receipt;
      noticeMessage = 'Payment confirmed. Your receipt is ready.';
      return true;
    } on RideServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage = 'Payment status could not be confirmed. Try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void setRating(int value) {
    rating = value;
    notifyListeners();
  }

  void toggleCompliment(String value) {
    if (!compliments.add(value)) compliments.remove(value);
    notifyListeners();
  }

  bool submitRating() {
    if (rating == 0) {
      errorMessage = 'Choose a captain rating before submitting.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    errorMessage = null;
    noticeMessage = 'Rating submitted. Thank you for the feedback.';
    notifyListeners();
    return true;
  }

  void chooseIssue(RideIssueType value) {
    issueType = value;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  void chooseMissingItem(String value) {
    missingItem = value;
    notifyListeners();
  }

  Future<bool> submitSupport(String detail) async {
    if (busy || trip == null) return false;
    if (supportTicket != null) {
      errorMessage = null;
      noticeMessage = 'Support request ${supportTicket!.id} is already open.';
      notifyListeners();
      return true;
    }
    final resolvedDetail = detail.trim().isEmpty
        ? issueType == RideIssueType.missingItem
              ? missingItem
              : ''
        : detail.trim();
    if (resolvedDetail.length < 3) {
      errorMessage = 'Add a short detail so support can act on this issue.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
    try {
      supportTicket = await _gateway.createSupportTicket(
        tripId: trip!.id,
        issueType: issueType,
        detail: resolvedDetail,
      );
      noticeMessage = 'Support request ${supportTicket!.id} created.';
      return true;
    } on RideServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage = 'Support request could not be created. Try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
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

  void reset() {
    trip = null;
    stage = RideTripStage.captainArriving;
    rideCancelled = false;
    addedStop = null;
    fare = selectedPackage.fare;
    rating = 0;
    supportTicket = null;
    pickupNote = 'Stand near Mahadev Fresh Mart board';
    paymentMethod = RidePaymentMethod.card;
    issueType = RideIssueType.missingItem;
    missingItem = 'Phone';
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }
}
