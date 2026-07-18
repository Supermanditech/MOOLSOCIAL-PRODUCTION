enum RideType { bike, auto, cab }

enum RideTime { now, after15Minutes, scheduled }

enum RidePaymentMethod { cash, upi, card }

enum RideTripStage { captainArriving, liveTrip, paymentApproval, receipt }

enum RideIssueType { missingItem, fare, route, safety }

class RidePackage {
  const RidePackage({
    required this.id,
    required this.type,
    required this.name,
    required this.fare,
    required this.arrivalMinutes,
    required this.capacity,
    required this.note,
    required this.nearbyCaptains,
  });

  final String id;
  final RideType type;
  final String name;
  final int fare;
  final int arrivalMinutes;
  final String capacity;
  final String note;
  final int nearbyCaptains;
}

class RideTrip {
  const RideTrip({
    required this.id,
    required this.package,
    required this.pickup,
    required this.drop,
    required this.rideTime,
    required this.createdAt,
  });

  final String id;
  final RidePackage package;
  final String pickup;
  final String drop;
  final String rideTime;
  final DateTime createdAt;
}

class RideSupportTicket {
  const RideSupportTicket({
    required this.id,
    required this.tripId,
    required this.issueType,
    required this.detail,
    required this.createdAt,
  });

  final String id;
  final String tripId;
  final RideIssueType issueType;
  final String detail;
  final DateTime createdAt;
}

extension RideTypeCopy on RideType {
  String get label => switch (this) {
    RideType.bike => 'Bike',
    RideType.auto => 'Auto',
    RideType.cab => 'Cab',
  };
}

extension RideTimeCopy on RideTime {
  String get label => switch (this) {
    RideTime.now => 'Now',
    RideTime.after15Minutes => 'After 15 min',
    RideTime.scheduled => 'Schedule',
  };
}

extension RidePaymentCopy on RidePaymentMethod {
  String get label => switch (this) {
    RidePaymentMethod.cash => 'Cash',
    RidePaymentMethod.upi => 'UPI',
    RidePaymentMethod.card => 'Card',
  };
}

extension RideIssueCopy on RideIssueType {
  String get label => switch (this) {
    RideIssueType.missingItem => 'Item missing',
    RideIssueType.fare => 'Fare issue',
    RideIssueType.route => 'Route issue',
    RideIssueType.safety => 'Safety concern',
  };

  String get action => switch (this) {
    RideIssueType.missingItem => 'Report missing item',
    RideIssueType.fare => 'Raise fare review',
    RideIssueType.route => 'Raise route review',
    RideIssueType.safety => 'Report safety concern',
  };
}
