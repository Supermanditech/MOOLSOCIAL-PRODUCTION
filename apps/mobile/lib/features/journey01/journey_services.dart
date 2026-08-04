const approvedSetupExperienceVersion = 5;

enum LocationPermissionResult { granted, denied, permanentlyDenied }

class JourneySnapshot {
  const JourneySnapshot({
    required this.languageCode,
    required this.areaMode,
    required this.setupComplete,
    this.areaLabel,
    this.currentAreaLabel,
    this.homeOrWorkAreaLabel,
    this.pendingRoute,
    this.lastReadyRoute,
    this.setupExperienceVersion = approvedSetupExperienceVersion,
  });

  final String languageCode;
  final String? areaMode;
  final String? areaLabel;
  final String? currentAreaLabel;
  final String? homeOrWorkAreaLabel;
  final bool setupComplete;
  final String? pendingRoute;
  final String? lastReadyRoute;
  final int setupExperienceVersion;
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

enum SocialAuthProvider { google, youtube, apple, x, instagram, facebook }

enum SocialAuthOutcome { authenticated, cancelled }

class SocialAuthResult {
  const SocialAuthResult._(this.outcome, {this.userId});

  const SocialAuthResult.authenticated(String userId)
    : this._(SocialAuthOutcome.authenticated, userId: userId);

  const SocialAuthResult.cancelled() : this._(SocialAuthOutcome.cancelled);

  final SocialAuthOutcome outcome;
  final String? userId;
}

abstract interface class SocialAuthGateway {
  Future<bool> hasAuthenticatedUser();

  Future<SocialAuthResult> signIn(SocialAuthProvider provider);

  Future<void> signOut();
}

class ReviewSocialAuthGateway implements SocialAuthGateway {
  ReviewSocialAuthGateway({
    this.defaultResult = const SocialAuthResult.cancelled(),
    Map<SocialAuthProvider, SocialAuthResult>? results,
    Map<SocialAuthProvider, Object>? failures,
    this.signedIn = false,
    this.responseDelay = Duration.zero,
  }) : results = results ?? <SocialAuthProvider, SocialAuthResult>{},
       failures = failures ?? <SocialAuthProvider, Object>{};

  final SocialAuthResult defaultResult;
  final Map<SocialAuthProvider, SocialAuthResult> results;
  final Map<SocialAuthProvider, Object> failures;
  final Duration responseDelay;
  bool signedIn;
  int signInCount = 0;
  SocialAuthProvider? lastProvider;

  @override
  Future<bool> hasAuthenticatedUser() async => signedIn;

  @override
  Future<SocialAuthResult> signIn(SocialAuthProvider provider) async {
    signInCount += 1;
    lastProvider = provider;
    if (responseDelay > Duration.zero) {
      await Future<void>.delayed(responseDelay);
    }
    if (failures[provider] case final failure?) throw failure;
    final result = results[provider] ?? defaultResult;
    if (result.outcome == SocialAuthOutcome.authenticated) signedIn = true;
    return result;
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
  }
}

abstract interface class OtpGateway {
  Future<bool> hasAuthenticatedUser();

  Future<OtpRequestResult> requestCode(String phoneNumber);

  Future<String> verifyCode(String code);

  Future<String?> reviewCodeFor(String phoneNumber);

  Future<void> signOut();
}

enum OtpChannel { mobile, email }

abstract interface class EmailOtpGateway {
  Future<void> requestCode(String emailAddress);

  Future<String> verifyCode(String code);

  Future<String?> reviewCodeFor(String emailAddress);
}

class ReviewEmailOtpGateway implements EmailOtpGateway {
  ReviewEmailOtpGateway({
    this.acceptedCode = '123456',
    this.requestFailure,
    this.verifyFailure,
  });

  final String acceptedCode;
  Object? requestFailure;
  Object? verifyFailure;
  int requestCount = 0;
  int verificationCount = 0;
  String? lastEmailAddress;

  @override
  Future<void> requestCode(String emailAddress) async {
    requestCount += 1;
    lastEmailAddress = emailAddress;
    if (requestFailure case final failure?) throw failure;
  }

  @override
  Future<String?> reviewCodeFor(String emailAddress) async => acceptedCode;

  @override
  Future<String> verifyCode(String code) async {
    verificationCount += 1;
    if (verifyFailure case final failure?) throw failure;
    if (code != acceptedCode) {
      throw const JourneyServiceException(
        'That code is not valid. Check it and try again.',
      );
    }
    return 'review-email-user';
  }
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

  Future<LocationPermissionResult> checkWhenInUse();
}

class ResolvedCurrentArea {
  const ResolvedCurrentArea({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.fullLabel,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final String fullLabel;
}

enum CurrentAreaFailureReason {
  permissionNotAllowed,
  permissionPermanentlyNotAllowed,
  locationServicesOff,
  unavailable,
}

class CurrentAreaException implements Exception {
  const CurrentAreaException(this.reason);

  final CurrentAreaFailureReason reason;
}

abstract interface class CurrentAreaGateway {
  Future<ResolvedCurrentArea> resolve({bool requestPermission = true});

  Future<void> openLocationServicesSettings();

  Future<void> openAppSettings();
}

class ReviewCurrentAreaGateway implements CurrentAreaGateway {
  ReviewCurrentAreaGateway({
    this.area = const ResolvedCurrentArea(
      primaryLabel: 'Sardarpura',
      secondaryLabel: 'Jodhpur, Rajasthan',
      fullLabel: 'Sardarpura, Jodhpur, Rajasthan',
    ),
    this.failureReason,
  });

  ResolvedCurrentArea area;
  CurrentAreaFailureReason? failureReason;
  int resolveCount = 0;
  int openLocationServicesSettingsCount = 0;
  int openAppSettingsCount = 0;
  final List<bool> requestPermissionHistory = <bool>[];

  @override
  Future<ResolvedCurrentArea> resolve({bool requestPermission = true}) async {
    resolveCount += 1;
    requestPermissionHistory.add(requestPermission);
    if (failureReason case final reason?) throw CurrentAreaException(reason);
    return area;
  }

  @override
  Future<void> openLocationServicesSettings() async {
    openLocationServicesSettingsCount += 1;
  }

  @override
  Future<void> openAppSettings() async {
    openAppSettingsCount += 1;
  }
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
  int checkCount = 0;

  @override
  Future<LocationPermissionResult> checkWhenInUse() async {
    checkCount += 1;
    if (failure case final value?) throw value;
    return result;
  }

  @override
  Future<LocationPermissionResult> requestWhenInUse() async {
    requestCount += 1;
    if (failure case final value?) throw value;
    return result;
  }
}
