import 'dart:convert';

import 'package:crypto/crypto.dart';

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
    this.profileDisplayName,
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
  final String? profileDisplayName;
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
  Object? signOutFailure;
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

enum AuthenticatedAccountBootstrapState {
  verified,
  retryableUnavailable,
  invalidSession,
  fatal,
}

final class VerifiedPrincipalBinding {
  VerifiedPrincipalBinding._(this._storageValue);

  static final RegExp _storagePattern = RegExp(r'^v1:[0-9a-f]{64}$');

  final String _storageValue;

  static VerifiedPrincipalBinding fromStorage(String value) {
    if (!_storagePattern.hasMatch(value)) {
      throw const FormatException('Invalid verified-principal binding.');
    }
    return VerifiedPrincipalBinding._(value);
  }

  String get storageValue => _storageValue;

  bool matches(VerifiedPrincipalBinding other) {
    final left = _storageValue.codeUnits;
    final right = other._storageValue.codeUnits;
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index += 1) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }

  @override
  bool operator ==(Object other) =>
      other is VerifiedPrincipalBinding && matches(other);

  @override
  int get hashCode => Object.hash(runtimeType, _storageValue);

  @override
  String toString() => 'VerifiedPrincipalBinding(redacted)';
}

final class AuthenticatedAccountBootstrapResult {
  const AuthenticatedAccountBootstrapResult._({
    required this.state,
    required this.code,
    this.currentBinding,
  });

  factory AuthenticatedAccountBootstrapResult.verified(
    VerifiedPrincipalBinding binding,
  ) => AuthenticatedAccountBootstrapResult._(
    state: AuthenticatedAccountBootstrapState.verified,
    code: 'auth-session-verified',
    currentBinding: binding,
  );

  factory AuthenticatedAccountBootstrapResult.retryableUnavailable(
    VerifiedPrincipalBinding binding, {
    String code = 'auth-session-network-unavailable',
  }) => AuthenticatedAccountBootstrapResult._(
    state: AuthenticatedAccountBootstrapState.retryableUnavailable,
    code: code,
    currentBinding: binding,
  );

  const AuthenticatedAccountBootstrapResult.invalidSession({
    String code = 'auth-session-invalid',
  }) : this._(
         state: AuthenticatedAccountBootstrapState.invalidSession,
         code: code,
       );

  const AuthenticatedAccountBootstrapResult.fatal({
    String code = 'auth-session-verification-fatal',
  }) : this._(state: AuthenticatedAccountBootstrapState.fatal, code: code);

  final AuthenticatedAccountBootstrapState state;
  final VerifiedPrincipalBinding? currentBinding;
  final String code;

  @override
  String toString() =>
      'AuthenticatedAccountBootstrapResult(state: ${state.name}, code: redacted, binding: redacted)';
}

abstract interface class PrincipalBindingProtector {
  Future<VerifiedPrincipalBinding> protect(String principalId);
}

class ReviewPrincipalBindingProtector implements PrincipalBindingProtector {
  const ReviewPrincipalBindingProtector();

  static final Hmac _reviewHmac = Hmac(
    sha256,
    utf8.encode('moolsocial-review-principal-binding-v1'),
  );

  @override
  Future<VerifiedPrincipalBinding> protect(String principalId) async {
    if (principalId.isEmpty) {
      throw const JourneyServiceException(
        'Your signed-in account could not be verified. Please sign in again.',
        code: 'auth-session-missing',
      );
    }
    final digest = _reviewHmac.convert(
      utf8.encode('moolsocial.verified-principal.v1\u0000$principalId'),
    );
    return VerifiedPrincipalBinding.fromStorage('v1:$digest');
  }
}

abstract interface class VerifiedPrincipalBindingStore {
  Future<VerifiedPrincipalBinding?> read();

  Future<void> write(VerifiedPrincipalBinding binding);

  Future<void> clear();

  Future<void> resetUnsafeState();
}

class MemoryVerifiedPrincipalBindingStore
    implements VerifiedPrincipalBindingStore {
  MemoryVerifiedPrincipalBindingStore({
    this.binding,
    this.readFailure,
    this.writeFailure,
    this.clearFailure,
    this.resetFailure,
  });

  VerifiedPrincipalBinding? binding;
  Object? readFailure;
  Object? writeFailure;
  Object? clearFailure;
  Object? resetFailure;
  int readCount = 0;
  int writeCount = 0;
  int clearCount = 0;
  int resetCount = 0;

  @override
  Future<VerifiedPrincipalBinding?> read() async {
    readCount += 1;
    if (readFailure case final value?) throw value;
    return binding;
  }

  @override
  Future<void> write(VerifiedPrincipalBinding value) async {
    writeCount += 1;
    if (writeFailure case final failure?) throw failure;
    binding = value;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    if (clearFailure case final failure?) throw failure;
    binding = null;
  }

  @override
  Future<void> resetUnsafeState() async {
    resetCount += 1;
    if (resetFailure case final failure?) throw failure;
    binding = null;
  }
}

abstract interface class AccountBootstrapGateway {
  Future<AuthenticatedAccountBootstrapResult> prepareAuthenticatedAccount({
    String? expectedUserId,
  });

  Future<VerifiedPrincipalBinding?> currentPrincipalBinding();

  Future<void> invalidateLocalSession();
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
    ];
    return details.isEmpty ? 'Signed in to MoolSocial' : details.join(' · ');
  }

  String get signInMethodsLabel => signInMethods.isEmpty
      ? 'Manage sign-in methods in Account & security'
      : 'Sign-in methods: ${signInMethods.join(' · ')}';
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
  ReviewAccountBootstrapGateway({
    this.failure,
    this.invalidationFailure,
    AuthenticatedAccountBootstrapResult? result,
    VerifiedPrincipalBinding? currentBinding,
  }) : result =
           result ??
           AuthenticatedAccountBootstrapResult.verified(_defaultBinding),
       currentBinding = currentBinding ?? _defaultBinding;

  static final VerifiedPrincipalBinding _defaultBinding =
      VerifiedPrincipalBinding.fromStorage(
        'v1:0000000000000000000000000000000000000000000000000000000000000000',
      );

  Object? failure;
  Object? invalidationFailure;
  AuthenticatedAccountBootstrapResult result;
  VerifiedPrincipalBinding? currentBinding;
  int prepareCount = 0;
  int currentBindingCount = 0;
  int invalidationCount = 0;
  String? lastExpectedUserId;

  @override
  Future<AuthenticatedAccountBootstrapResult> prepareAuthenticatedAccount({
    String? expectedUserId,
  }) async {
    prepareCount += 1;
    lastExpectedUserId = expectedUserId;
    if (failure case final value?) throw value;
    return result;
  }

  @override
  Future<VerifiedPrincipalBinding?> currentPrincipalBinding() async {
    currentBindingCount += 1;
    return currentBinding;
  }

  @override
  Future<void> invalidateLocalSession() async {
    invalidationCount += 1;
    if (invalidationFailure case final failure?) throw failure;
    currentBinding = null;
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
