enum LocationPermissionResult { granted, denied, permanentlyDenied }

class JourneySnapshot {
  const JourneySnapshot({
    required this.languageCode,
    required this.areaMode,
    required this.setupComplete,
    this.areaLabel,
    this.pendingRoute,
  });

  final String languageCode;
  final String? areaMode;
  final String? areaLabel;
  final bool setupComplete;
  final String? pendingRoute;
}

abstract interface class JourneyStore {
  Future<JourneySnapshot?> read();

  Future<void> write(JourneySnapshot snapshot);
}

class MemoryJourneyStore implements JourneyStore {
  MemoryJourneyStore({this.snapshot, this.readFailure, this.writeFailure});

  JourneySnapshot? snapshot;
  Object? readFailure;
  Object? writeFailure;
  int writeCount = 0;

  @override
  Future<JourneySnapshot?> read() async {
    if (readFailure case final failure?) throw failure;
    return snapshot;
  }

  @override
  Future<void> write(JourneySnapshot value) async {
    if (writeFailure case final failure?) throw failure;
    snapshot = value;
    writeCount += 1;
  }
}

class OtpRequestResult {
  const OtpRequestResult({this.automaticallyVerified = false, this.userId});

  final bool automaticallyVerified;
  final String? userId;
}

class JourneyServiceException implements Exception {
  const JourneyServiceException(this.userMessage);

  final String userMessage;

  @override
  String toString() => userMessage;
}

abstract interface class OtpGateway {
  Future<bool> hasAuthenticatedUser();

  Future<OtpRequestResult> requestCode(String phoneNumber);

  Future<String> verifyCode(String code);

  Future<String?> reviewCodeFor(String phoneNumber);

  Future<void> signOut();
}

class ReviewOtpGateway implements OtpGateway {
  ReviewOtpGateway({
    this.acceptedCode = '123456',
    this.signedIn = false,
    this.requestFailure,
    this.verifyFailure,
  });

  final String acceptedCode;
  bool signedIn;
  Object? requestFailure;
  Object? verifyFailure;
  int requestCount = 0;
  int verificationCount = 0;
  String? lastPhoneNumber;

  @override
  Future<bool> hasAuthenticatedUser() async => signedIn;

  @override
  Future<OtpRequestResult> requestCode(String phoneNumber) async {
    requestCount += 1;
    lastPhoneNumber = phoneNumber;
    if (requestFailure case final failure?) throw failure;
    return const OtpRequestResult();
  }

  @override
  Future<String?> reviewCodeFor(String phoneNumber) async => acceptedCode;

  @override
  Future<void> signOut() async {
    signedIn = false;
  }

  @override
  Future<String> verifyCode(String code) async {
    verificationCount += 1;
    if (verifyFailure case final failure?) throw failure;
    if (code != acceptedCode) {
      throw const JourneyServiceException(
        'That code is not valid. Check it and try again.',
      );
    }
    signedIn = true;
    return 'review-user';
  }
}

abstract interface class LocationPermissionGateway {
  Future<LocationPermissionResult> requestWhenInUse();
}

abstract interface class AccountBootstrapGateway {
  Future<void> prepareAuthenticatedAccount();
}

class ReviewAccountBootstrapGateway implements AccountBootstrapGateway {
  ReviewAccountBootstrapGateway({this.failure});

  Object? failure;
  int prepareCount = 0;

  @override
  Future<void> prepareAuthenticatedAccount() async {
    prepareCount += 1;
    if (failure case final value?) throw value;
  }
}

class ReviewLocationPermissionGateway implements LocationPermissionGateway {
  ReviewLocationPermissionGateway({
    this.result = LocationPermissionResult.granted,
    this.failure,
  });

  LocationPermissionResult result;
  Object? failure;
  int requestCount = 0;

  @override
  Future<LocationPermissionResult> requestWhenInUse() async {
    requestCount += 1;
    if (failure case final value?) throw value;
    return result;
  }
}
