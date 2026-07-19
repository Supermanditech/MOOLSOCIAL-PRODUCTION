enum DoctorCare { clinic, opd, video, followUp }

enum SalonMode { salon, home, makeup, package }

enum SalonPayment { atSalon, upi, cardHold }

enum SalonIssue { bill, service, safety }

enum TaskType { pickup, document, market, custom }

enum TaskPayment { upi, card, wallet }

enum TaskIssue { wrongProof, incomplete, overcharged, safety }

enum TaskResolution { refund, rework, adjustBill, closeCase }

class DoctorAppointment {
  const DoctorAppointment({
    required this.id,
    required this.patient,
    required this.care,
    required this.need,
    required this.createdAt,
  });

  final String id;
  final String patient;
  final DoctorCare care;
  final String need;
  final DateTime createdAt;
}

class SalonBooking {
  const SalonBooking({
    required this.id,
    required this.service,
    required this.mode,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String service;
  final SalonMode mode;
  final int amount;
  final DateTime createdAt;
}

class LocalTask {
  const LocalTask({
    required this.id,
    required this.type,
    required this.city,
    required this.detail,
    required this.heldAmount,
    required this.createdAt,
  });

  final String id;
  final TaskType type;
  final String city;
  final String detail;
  final int heldAmount;
  final DateTime createdAt;
}

class BookSupportCase {
  const BookSupportCase({
    required this.id,
    required this.subjectId,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String subjectId;
  final String reason;
  final DateTime createdAt;
}

extension DoctorCareCopy on DoctorCare {
  String get label => switch (this) {
    DoctorCare.clinic => 'Clinic',
    DoctorCare.opd => 'Hospital OPD',
    DoctorCare.video => 'Video',
    DoctorCare.followUp => 'Follow-up',
  };
}

extension SalonModeCopy on SalonMode {
  String get label => switch (this) {
    SalonMode.salon => 'Salon',
    SalonMode.home => 'Home visit',
    SalonMode.makeup => 'Makeup',
    SalonMode.package => 'Package',
  };
}

extension SalonPaymentCopy on SalonPayment {
  String get label => switch (this) {
    SalonPayment.atSalon => 'Pay at salon',
    SalonPayment.upi => 'UPI now',
    SalonPayment.cardHold => 'Card hold',
  };
}

extension SalonIssueCopy on SalonIssue {
  String get label => switch (this) {
    SalonIssue.bill => 'Bill correction',
    SalonIssue.service => 'Service quality',
    SalonIssue.safety => 'Safety concern',
  };
}

extension TaskTypeCopy on TaskType {
  String get label => switch (this) {
    TaskType.pickup => 'Pickup work',
    TaskType.document => 'Document work',
    TaskType.market => 'Buy locally',
    TaskType.custom => 'Custom task',
  };
}

extension TaskPaymentCopy on TaskPayment {
  String get label => switch (this) {
    TaskPayment.upi => 'UPI hold',
    TaskPayment.card => 'Card hold',
    TaskPayment.wallet => 'Wallet',
  };
}

extension TaskIssueCopy on TaskIssue {
  String get label => switch (this) {
    TaskIssue.wrongProof => 'Wrong proof',
    TaskIssue.incomplete => 'Task incomplete',
    TaskIssue.overcharged => 'Overcharged',
    TaskIssue.safety => 'Safety concern',
  };
}

extension TaskResolutionCopy on TaskResolution {
  String get label => switch (this) {
    TaskResolution.refund => 'Refund',
    TaskResolution.rework => 'Rework',
    TaskResolution.adjustBill => 'Adjust bill',
    TaskResolution.closeCase => 'Close case',
  };
}
