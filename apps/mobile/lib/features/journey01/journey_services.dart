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
    this.pendingAuthenticationCancelRoute,
    this.pendingAuthenticationPurpose,
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
  final String? pendingAuthenticationCancelRoute;
  final String? pendingAuthenticationPurpose;
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

class SeededJourneyStore implements JourneyStore {
  SeededJourneyStore({required this.delegate, required this.seed});

  final JourneyStore delegate;
  final JourneySnapshot seed;

  @override
  Future<JourneySnapshot?> read() async => await delegate.read() ?? seed;

  @override
  Future<void> write(JourneySnapshot snapshot) => delegate.write(snapshot);
}

class OtpRequestResult {
  const OtpRequestResult({this.automaticallyVerified = false, this.userId});

  final bool automaticallyVerified;
  final String? userId;
}

class JourneyServiceException implements Exception {
  const JourneyServiceException(this.userMessage, {this.code});

  final String userMessage;
  final String? code;

  @override
  String toString() => userMessage;
}

enum SocialAuthProvider { google, youtube, apple, x, instagram, facebook }

enum SocialAuthOutcome { authenticated, authorizationPending, cancelled }

class SocialAuthResult {
  const SocialAuthResult._(this.outcome, {this.userId, this.code});

  const SocialAuthResult.authenticated(String userId, {String? code})
    : this._(SocialAuthOutcome.authenticated, userId: userId, code: code);

  const SocialAuthResult.authorizationPending({String? code})
    : this._(SocialAuthOutcome.authorizationPending, code: code);

  const SocialAuthResult.cancelled({String? code})
    : this._(SocialAuthOutcome.cancelled, code: code);

  final SocialAuthOutcome outcome;
  final String? userId;
  final String? code;
}

abstract interface class SocialAuthGateway {
  Future<bool> hasAuthenticatedUser();

  Future<SocialAuthResult> signIn(SocialAuthProvider provider);

  Future<void> signOut();
}

abstract interface class SocialAuthCallbackGateway {
  SocialAuthProvider? providerForCallback(Uri callbackUri);

  Future<SocialAuthResult> completeForegroundCallback(Uri callbackUri);

  Future<SocialAuthResult> completeColdStartCallback(Uri callbackUri);
}

class ReviewSocialAuthGateway implements SocialAuthGateway {
  ReviewSocialAuthGateway({
    this.defaultResult = const SocialAuthResult.cancelled(),
    Map<SocialAuthProvider, SocialAuthResult>? results,
    Map<SocialAuthProvider, Object>? failures,
    this.signedIn = false,
    this.responseDelay = Duration.zero,
    this.signOutFailure,
  }) : results = results ?? <SocialAuthProvider, SocialAuthResult>{},
       failures = failures ?? <SocialAuthProvider, Object>{};

  final SocialAuthResult defaultResult;
  final Map<SocialAuthProvider, SocialAuthResult> results;
  final Map<SocialAuthProvider, Object> failures;
  final Duration responseDelay;
  final Object? signOutFailure;
  bool signedIn;
  int signInCount = 0;
  int signOutCount = 0;
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
    signOutCount += 1;
    if (signOutFailure case final failure?) throw failure;
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

abstract interface class EmailLinkGateway {
  Future<void> sendSignInLink(String emailAddress);

  bool isSignInLink(String emailLink);

  Future<String> signInWithEmailLink({
    required String emailAddress,
    required String emailLink,
  });

  Future<void> signOut();
}

abstract interface class PendingEmailLinkAddressStore {
  Future<String?> read();

  Future<void> write(String emailAddress);

  Future<void> clear();
}

class MemoryPendingEmailLinkAddressStore
    implements PendingEmailLinkAddressStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String emailAddress) async {
    value = emailAddress;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class UnavailableEmailLinkGateway implements EmailLinkGateway {
  const UnavailableEmailLinkGateway();

  static const _unavailable = JourneyServiceException(
    'Email link sign-in is not available right now. Choose another method.',
    code: 'email-link-unavailable',
  );

  @override
  Future<void> sendSignInLink(String emailAddress) async => throw _unavailable;

  @override
  bool isSignInLink(String emailLink) => false;

  @override
  Future<String> signInWithEmailLink({
    required String emailAddress,
    required String emailLink,
  }) async => throw _unavailable;

  @override
  Future<void> signOut() async {}
}

class ReviewEmailLinkGateway implements EmailLinkGateway {
  ReviewEmailLinkGateway({
    this.acceptedLink = 'moolsocial-review-email-link',
    this.userId = 'review-email-link-user',
    this.sendFailure,
    this.completionFailure,
  });

  final String acceptedLink;
  final String userId;
  Object? sendFailure;
  Object? completionFailure;
  int sendCount = 0;
  int completionCount = 0;
  int signOutCount = 0;
  String? lastEmailAddress;
  bool signedIn = false;

  @override
  Future<void> sendSignInLink(String emailAddress) async {
    sendCount += 1;
    lastEmailAddress = emailAddress;
    if (sendFailure case final failure?) throw failure;
  }

  @override
  bool isSignInLink(String emailLink) => emailLink == acceptedLink;

  @override
  Future<String> signInWithEmailLink({
    required String emailAddress,
    required String emailLink,
  }) async {
    completionCount += 1;
    if (completionFailure case final failure?) throw failure;
    if (!isSignInLink(emailLink)) {
      throw const JourneyServiceException(
        'This sign-in link is invalid. Request a new link.',
        code: 'invalid-action-code',
      );
    }
    if (lastEmailAddress != null && lastEmailAddress != emailAddress) {
      throw const JourneyServiceException(
        'Enter the email address that received this link.',
        code: 'invalid-email',
      );
    }
    signedIn = true;
    return userId;
  }

  @override
  Future<void> signOut() async {
    signOutCount += 1;
    signedIn = false;
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
  int signOutCount = 0;
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
    signOutCount += 1;
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
  Future<void> prepareAuthenticatedAccount({String? expectedUserId});
}

class AuthenticatedAccountIdentity {
  const AuthenticatedAccountIdentity({
    this.displayName,
    this.emailAddress,
    this.phoneNumber,
    this.providerAccountLabel,
    this.signInMethods = const <String>[],
  });

  final String? displayName;
  final String? emailAddress;
  final String? phoneNumber;
  final String? providerAccountLabel;
  final List<String> signInMethods;

  String get primaryLabel {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = emailAddress?.trim();
    if (email != null && email.isNotEmpty) return email;
    final phone = phoneNumber?.trim();
    if (phone != null && phone.isNotEmpty) return phone;
    final providerAccount = providerAccountLabel?.trim();
    if (providerAccount != null && providerAccount.isNotEmpty) {
      return providerAccount;
    }
    return 'MoolSocial member';
  }

  String get detailLabel {
    final details = <String>[
      if (emailAddress?.trim() case final email? when email.isNotEmpty) email,
      if (phoneNumber?.trim() case final phone? when phone.isNotEmpty) phone,
      if (providerAccountLabel?.trim() case final account?
          when account.isNotEmpty)
        account,
      if (signInMethods.isNotEmpty) signInMethods.join(' · '),
    ];
    return details.isEmpty ? 'Signed in to MoolSocial' : details.join(' · ');
  }
}

abstract interface class AuthenticatedAccountIdentityGateway {
  Future<AuthenticatedAccountIdentity?> currentIdentity();
}

class ReviewAuthenticatedAccountIdentityGateway
    implements AuthenticatedAccountIdentityGateway {
  ReviewAuthenticatedAccountIdentityGateway({this.identity, this.failure});

  AuthenticatedAccountIdentity? identity;
  Object? failure;
  int readCount = 0;

  @override
  Future<AuthenticatedAccountIdentity?> currentIdentity() async {
    readCount += 1;
    if (failure case final value?) throw value;
    return identity;
  }
}

class ReviewAccountBootstrapGateway implements AccountBootstrapGateway {
  ReviewAccountBootstrapGateway({this.failure});

  Object? failure;
  int prepareCount = 0;
  String? lastExpectedUserId;

  @override
  Future<void> prepareAuthenticatedAccount({String? expectedUserId}) async {
    prepareCount += 1;
    lastExpectedUserId = expectedUserId;
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
