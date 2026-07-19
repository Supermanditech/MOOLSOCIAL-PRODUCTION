class CaptainGatewayException implements Exception {
  const CaptainGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReviewCaptainGateway {
  bool failAvailability = false;
  bool failAccept = false;
  bool failDecline = false;
  bool failStart = false;
  bool failArrival = false;
  bool failPayment = false;
  bool failVerification = false;
  bool failSupport = false;
  bool failApplication = false;

  int availabilityCalls = 0;
  int acceptCalls = 0;
  int declineCalls = 0;
  int startCalls = 0;
  int arrivalCalls = 0;
  int paymentCalls = 0;
  int verificationCalls = 0;
  int supportCalls = 0;
  int applicationCalls = 0;

  Future<void> setAvailability(bool value) => _run(
    'availability update',
    () => availabilityCalls += 1,
    () => failAvailability = false,
    failAvailability,
  );

  Future<void> acceptRide() => _run(
    'ride acceptance',
    () => acceptCalls += 1,
    () => failAccept = false,
    failAccept,
  );

  Future<void> declineRide() => _run(
    'ride decline',
    () => declineCalls += 1,
    () => failDecline = false,
    failDecline,
  );

  Future<void> startTrip() => _run(
    'trip start',
    () => startCalls += 1,
    () => failStart = false,
    failStart,
  );

  Future<void> confirmArrival() => _run(
    'destination arrival',
    () => arrivalCalls += 1,
    () => failArrival = false,
    failArrival,
  );

  Future<void> confirmPayment() => _run(
    'payment check',
    () => paymentCalls += 1,
    () => failPayment = false,
    failPayment,
  );

  Future<void> startVerification() => _run(
    'document verification',
    () => verificationCalls += 1,
    () => failVerification = false,
    failVerification,
  );

  Future<void> createSupportCase() => _run(
    'support case',
    () => supportCalls += 1,
    () => failSupport = false,
    failSupport,
  );

  Future<void> applyForWork() => _run(
    'paid work application',
    () => applicationCalls += 1,
    () => failApplication = false,
    failApplication,
  );

  Future<void> _run(
    String operation,
    void Function() count,
    void Function() clearFailure,
    bool shouldFail,
  ) async {
    count();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (shouldFail) {
      clearFailure();
      throw CaptainGatewayException(
        'We could not complete the $operation. Nothing was changed. Try again.',
      );
    }
  }
}
