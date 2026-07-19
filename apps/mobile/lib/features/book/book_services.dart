import 'book_models.dart';

class BookServiceException implements Exception {
  const BookServiceException(this.userMessage);

  final String userMessage;
}

abstract interface class BookGateway {
  Future<DoctorAppointment> confirmDoctorAppointment({
    required String patient,
    required DoctorCare care,
    required String need,
  });

  Future<SalonBooking> confirmSalonBooking({
    required String service,
    required SalonMode mode,
    required int amount,
  });

  Future<void> paySalon({
    required String bookingId,
    required int amount,
    required SalonPayment method,
  });

  Future<LocalTask> createTask({
    required TaskType type,
    required String city,
    required String detail,
    required int heldAmount,
  });

  Future<void> releaseTaskPayment({
    required String taskId,
    required int amount,
  });

  Future<BookSupportCase> createSupportCase({
    required String subjectId,
    required String reason,
  });

  Future<void> acceptResolution({
    required String caseId,
    required TaskResolution resolution,
  });
}

class ReviewBookGateway implements BookGateway {
  ReviewBookGateway({
    this.failNextDoctor = false,
    this.failNextSalon = false,
    this.failNextSalonPayment = false,
    this.failNextTask = false,
    this.failNextTaskRelease = false,
    this.failNextSupport = false,
    this.failNextResolution = false,
    this.latency = const Duration(milliseconds: 120),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  bool failNextDoctor;
  bool failNextSalon;
  bool failNextSalonPayment;
  bool failNextTask;
  bool failNextTaskRelease;
  bool failNextSupport;
  bool failNextResolution;
  final Duration latency;
  final DateTime Function() _now;
  int _sequence = 2047;
  int doctorCalls = 0;
  int salonCalls = 0;
  int salonPaymentCalls = 0;
  int taskCalls = 0;
  int releaseCalls = 0;
  int supportCalls = 0;
  int resolutionCalls = 0;

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  @override
  Future<DoctorAppointment> confirmDoctorAppointment({
    required String patient,
    required DoctorCare care,
    required String need,
  }) async {
    doctorCalls += 1;
    await _wait();
    if (failNextDoctor) {
      failNextDoctor = false;
      throw const BookServiceException(
        'The appointment could not be confirmed. Your details are saved. Choose another slot or try again.',
      );
    }
    _sequence += 1;
    return DoctorAppointment(
      id: 'MS-CARE-$_sequence',
      patient: patient,
      care: care,
      need: need,
      createdAt: _now(),
    );
  }

  @override
  Future<SalonBooking> confirmSalonBooking({
    required String service,
    required SalonMode mode,
    required int amount,
  }) async {
    salonCalls += 1;
    await _wait();
    if (failNextSalon) {
      failNextSalon = false;
      throw const BookServiceException(
        'This slot is no longer available. No payment was taken. Choose another slot or try again.',
      );
    }
    _sequence += 1;
    return SalonBooking(
      id: 'SAL-$_sequence',
      service: service,
      mode: mode,
      amount: amount,
      createdAt: _now(),
    );
  }

  @override
  Future<void> paySalon({
    required String bookingId,
    required int amount,
    required SalonPayment method,
  }) async {
    salonPaymentCalls += 1;
    await _wait();
    if (failNextSalonPayment) {
      failNextSalonPayment = false;
      throw const BookServiceException(
        'Payment could not be completed. No money was deducted. Try again or choose another method.',
      );
    }
  }

  @override
  Future<LocalTask> createTask({
    required TaskType type,
    required String city,
    required String detail,
    required int heldAmount,
  }) async {
    taskCalls += 1;
    await _wait();
    if (failNextTask) {
      failNextTask = false;
      throw const BookServiceException(
        'A verified helper did not accept yet. No hold was created. Edit the task or try again.',
      );
    }
    _sequence += 1;
    return LocalTask(
      id: 'MS-TASK-$_sequence',
      type: type,
      city: city,
      detail: detail,
      heldAmount: heldAmount,
      createdAt: _now(),
    );
  }

  @override
  Future<void> releaseTaskPayment({
    required String taskId,
    required int amount,
  }) async {
    releaseCalls += 1;
    await _wait();
    if (failNextTaskRelease) {
      failNextTaskRelease = false;
      throw const BookServiceException(
        'Payment release is still protected. No money moved. Check the proof and try again.',
      );
    }
  }

  @override
  Future<BookSupportCase> createSupportCase({
    required String subjectId,
    required String reason,
  }) async {
    supportCalls += 1;
    await _wait();
    if (failNextSupport) {
      failNextSupport = false;
      throw const BookServiceException(
        'Support could not attach the saved evidence yet. The payment remains protected. Try again.',
      );
    }
    _sequence += 1;
    return BookSupportCase(
      id: 'MS-CASE-$_sequence',
      subjectId: subjectId,
      reason: reason,
      createdAt: _now(),
    );
  }

  @override
  Future<void> acceptResolution({
    required String caseId,
    required TaskResolution resolution,
  }) async {
    resolutionCalls += 1;
    await _wait();
    if (failNextResolution) {
      failNextResolution = false;
      throw const BookServiceException(
        'The resolution could not be confirmed. No money moved and the case remains open. Try again.',
      );
    }
  }
}
