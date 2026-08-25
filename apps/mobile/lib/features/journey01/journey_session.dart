import 'dart:async';

import 'package:flutter/foundation.dart';

import 'journey_services.dart';

const _deviceReviewMode = bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW');

enum JourneyStage { booting, bootFailure, setup, signIn, verify, ready }

enum AreaChoice { current, manual, skipped }

enum SocialAuthState { idle, pending, cancelled, failed }

enum EmailLinkState {
  idle,
  entering,
  sending,
  sent,
  awaitingEmail,
  completing,
  invalid,
  expired,
  used,
  failed,
}

enum JourneyAuthenticationPurpose { general, youtubeChannelConnection }

class JourneySession extends ChangeNotifier {
  JourneySession({
    JourneyStore? store,
    OtpGateway? otpGateway,
    EmailOtpGateway? emailOtpGateway,
    EmailLinkGateway? emailLinkGateway,
    PendingEmailLinkAddressStore? pendingEmailLinkAddressStore,
    SocialAuthGateway? socialAuthGateway,
    Set<SocialAuthProvider>? availableSocialAuthProviders,
    this.emailOtpAvailable = true,
    this.emailLinkAvailable = false,
    this.mobileOtpAvailable = true,
    AccountBootstrapGateway? accountBootstrapGateway,
    VerifiedPrincipalBindingStore? verifiedPrincipalBindingStore,
    AuthenticatedAccountIdentityGateway? accountIdentityGateway,
    LocationPermissionGateway? locationGateway,
    CurrentAreaGateway? currentAreaGateway,
    DateTime Function()? now,
    this.otpValidity = const Duration(minutes: 2),
    this.resendCooldown = const Duration(seconds: 30),
    this.accountBootstrapTimeout = const Duration(seconds: 8),
    this.socialAuthRollbackTimeout = const Duration(seconds: 8),
    this.allowGuestReady = false,
  }) : _store = store ?? MemoryJourneyStore(),
       _otpGateway = otpGateway ?? ReviewOtpGateway(),
       _emailOtpGateway = emailOtpGateway ?? ReviewEmailOtpGateway(),
       _emailLinkGateway =
           emailLinkGateway ?? const UnavailableEmailLinkGateway(),
       _pendingEmailLinkAddressStore =
           pendingEmailLinkAddressStore ?? MemoryPendingEmailLinkAddressStore(),
       _socialAuthGateway = socialAuthGateway ?? ReviewSocialAuthGateway(),
       availableSocialAuthProviders = Set.unmodifiable(
         availableSocialAuthProviders ?? SocialAuthProvider.values.toSet(),
       ),
       _accountBootstrapGateway =
           accountBootstrapGateway ?? ReviewAccountBootstrapGateway(),
       _verifiedPrincipalBindingStore =
           verifiedPrincipalBindingStore ??
           MemoryVerifiedPrincipalBindingStore(),
       _accountIdentityGateway =
           accountIdentityGateway ??
           ReviewAuthenticatedAccountIdentityGateway(),
       _locationGateway = locationGateway ?? ReviewLocationPermissionGateway(),
       _currentAreaGateway = currentAreaGateway ?? ReviewCurrentAreaGateway(),
       _now = now ?? DateTime.now;

  final JourneyStore _store;
  final OtpGateway _otpGateway;
  final EmailOtpGateway _emailOtpGateway;
  final EmailLinkGateway _emailLinkGateway;
  final PendingEmailLinkAddressStore _pendingEmailLinkAddressStore;
  final SocialAuthGateway _socialAuthGateway;
  final Set<SocialAuthProvider> availableSocialAuthProviders;
  final bool emailOtpAvailable;
  final bool emailLinkAvailable;
  final bool mobileOtpAvailable;
  final AccountBootstrapGateway _accountBootstrapGateway;
  final VerifiedPrincipalBindingStore _verifiedPrincipalBindingStore;
  final AuthenticatedAccountIdentityGateway _accountIdentityGateway;
  final LocationPermissionGateway _locationGateway;
  final CurrentAreaGateway _currentAreaGateway;
  final DateTime Function() _now;
  final Duration otpValidity;
  final Duration resendCooldown;
  final Duration accountBootstrapTimeout;
  final Duration socialAuthRollbackTimeout;
  final bool allowGuestReady;

  JourneyStage stage = JourneyStage.booting;
  String languageCode = 'en';
  AreaChoice? areaChoice;
  String? manualArea;
  String? currentAreaPrimary;
  String? currentAreaSecondary;
  String? currentAreaLabel;
  String? homeOrWorkArea;
  CurrentAreaFailureReason? currentAreaFailureReason;
  String? phoneNumber;
  String? emailAddress;
  OtpChannel? otpChannel;
  SocialAuthProvider? socialAuthProvider;
  SocialAuthState socialAuthState = SocialAuthState.idle;
  String? socialAuthReceiptCode;
  final List<String> socialAuthReceiptSequence = <String>[];
  int socialAuthAttempt = 0;
  EmailLinkState emailLinkState = EmailLinkState.idle;
  String? emailLinkReceiptCode;
  String? errorMessage;
  String? noticeMessage;
  AuthenticatedAccountIdentity? accountIdentity;
  AuthenticatedAccountBootstrapState? authenticatedBootstrapState;
  bool authenticatedRevalidationPending = false;
  String? reviewCode;
  String? returnTo;
  String? _authenticationCancelTo;
  JourneyAuthenticationPurpose authenticationPurpose =
      JourneyAuthenticationPurpose.general;
  String previousPrimarySection = 'social';
  String? _lastReadyRoute;
  DateTime? otpExpiresAt;
  DateTime? resendAvailableAt;
  bool busy = false;
  bool resolvingCurrentArea = false;

  bool _started = false;
  bool _storeRestored = false;
  bool _authenticatedAtBoot = false;
  bool _isAuthenticated = false;
  bool _authenticationCompletionInProgress = false;
  bool _socialAuthCleanupRequired = false;
  bool _principalBindingCleanupRequired = false;
  bool _unsafePrincipalResetRequired = false;
  Future<bool>? _authenticatedRevalidationFuture;
  String? _pendingEmailLink;
  String? _completedEmailLinkReturnRoute;
  String? _completedSocialAuthReturnRoute;
  int _completedSetupExperienceVersion = 0;
  Future<void> _persistenceTail = Future<void>.value();
  Future<void> _principalBindingMutationTail = Future<void>.value();
  int _authenticationGeneration = 0;
  bool _disposed = false;

  bool get isReady => stage == JourneyStage.ready;
  bool get isAuthenticated => _isAuthenticated;
  bool get socialAuthCleanupRequired => _socialAuthCleanupRequired;
  bool get principalBindingCleanupRequired => _principalBindingCleanupRequired;
  bool isSocialAuthProviderAvailable(SocialAuthProvider provider) =>
      availableSocialAuthProviders.contains(provider);
  bool get canCancelSignIn =>
      allowGuestReady &&
      !_isAuthenticated &&
      stage == JourneyStage.signIn &&
      _authenticationCancelTo?.startsWith('/app/') == true;
  String get authenticationCancelFallback => _lastReadyRoute ?? '/app/social';
  int get completedSetupExperienceVersion => _completedSetupExperienceVersion;

  bool get canResend => resendSeconds == 0 && !busy;

  int get resendSeconds {
    final available = resendAvailableAt;
    if (available == null) return 0;
    return _remainingSeconds(available);
  }

  int get expirySeconds {
    final expires = otpExpiresAt;
    if (expires == null) return 0;
    return _remainingSeconds(expires);
  }

  String get maskedOtpDestination {
    if (otpChannel == OtpChannel.email) {
      final value = emailAddress ?? '';
      final separator = value.indexOf('@');
      if (separator <= 1) return value;
      final local = value.substring(0, separator);
      final domain = value.substring(separator);
      return '${local.substring(0, 1)}${'*' * (local.length - 1)}$domain';
    }
    final value = phoneNumber ?? '';
    if (value.length < 4) return value;
    return '+91 ******${value.substring(value.length - 4)}';
  }

  String get maskedEmailLinkDestination {
    final value = emailAddress ?? '';
    final separator = value.indexOf('@');
    if (separator <= 0 || separator == value.length - 1) return '';
    final local = value.substring(0, separator);
    final domain = value.substring(separator);
    final visible = local.substring(0, 1);
    final hiddenCount = local.length <= 4 ? 3 : local.length - 1;
    return '$visible${'•' * hiddenCount}$domain';
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _authenticationGeneration += 1;
    _completedSetupExperienceVersion = 0;
    _setBusy(true);
    errorMessage = null;
    authenticatedRevalidationPending = false;

    try {
      final capturedRoute = returnTo;
      final snapshot = await _store.read();
      if (snapshot != null) {
        _completedSetupExperienceVersion = snapshot.setupExperienceVersion;
        languageCode = snapshot.languageCode;
        areaChoice = _areaChoiceFromStorage(snapshot.areaMode);
        manualArea = snapshot.areaLabel;
        currentAreaLabel = snapshot.currentAreaLabel;
        homeOrWorkArea = snapshot.homeOrWorkAreaLabel;
        if (currentAreaLabel case final label?) {
          final parts = label
              .split(',')
              .map((part) => part.trim())
              .where((part) => part.isNotEmpty)
              .toList(growable: false);
          currentAreaPrimary = parts.isEmpty ? label : parts.first;
          currentAreaSecondary = parts.length > 1
              ? parts.skip(1).join(', ')
              : 'Nearby results are ready';
        }
        returnTo = returnTo ?? capturedRoute ?? snapshot.pendingRoute;
        _lastReadyRoute = _canonicalPersistedReadyRoute(
          snapshot.lastReadyRoute,
        );
      }
      _storeRestored = true;

      var signedIn =
          await _otpGateway.hasAuthenticatedUser() ||
          await _socialAuthGateway.hasAuthenticatedUser();
      if (signedIn && _principalBindingCleanupRequired) {
        await _resetUnsafePrincipalBinding();
        signedIn = false;
      }
      if (!signedIn) await _clearReceiptForSignedOutEntry();
      _isAuthenticated = signedIn;
      final pendingAuthenticationUri = _localAppUri(returnTo);
      final resumesPersistedAuthentication =
          !signedIn && _requiresAuthentication(pendingAuthenticationUri);
      if (resumesPersistedAuthentication) {
        authenticationPurpose = _restoredAuthenticationPurpose(
          snapshot?.pendingAuthenticationPurpose,
          pendingAuthenticationUri!,
        );
        _authenticationCancelTo = _restoredAuthenticationCancelRoute(
          snapshot?.pendingAuthenticationCancelRoute,
          pendingAuthenticationUri,
          _lastReadyRoute,
        );
      }
      final requiresApprovedSetup =
          snapshot == null ||
          _completedSetupExperienceVersion < approvedSetupExperienceVersion;
      if (requiresApprovedSetup) {
        _authenticatedAtBoot = signedIn;
        stage = JourneyStage.setup;
      } else if (signedIn) {
        final bootstrap = await _prepareAuthenticatedAccount();
        if (await _acceptAuthenticatedRelaunch(bootstrap)) {
          if (!authenticatedRevalidationPending) {
            await _refreshAuthenticatedAccountIdentity();
          }
          stage = JourneyStage.ready;
        }
      } else if (snapshot.setupComplete) {
        stage = resumesPersistedAuthentication
            ? JourneyStage.signIn
            : allowGuestReady
            ? JourneyStage.ready
            : JourneyStage.signIn;
      } else {
        stage = JourneyStage.setup;
      }
      if (returnTo != null && returnTo != snapshot?.pendingRoute) {
        await _persist(
          setupComplete: snapshot?.setupComplete ?? areaChoice != null,
        );
      }
      if (kDebugMode || _deviceReviewMode) {
        debugPrint(
          'MOOLSOCIAL_STARTUP '
          'stage=${stage.name} '
          'snapshot=${snapshot != null} '
          'setupComplete=${snapshot?.setupComplete ?? false} '
          'completedSetupVersion=$_completedSetupExperienceVersion '
          'requiredSetupVersion=$approvedSetupExperienceVersion '
          'authenticated=$_isAuthenticated',
        );
      }
      if (!authenticatedRevalidationPending) noticeMessage = null;
    } on Object {
      stage = JourneyStage.bootFailure;
      if (kDebugMode || _deviceReviewMode) {
        debugPrint('MOOLSOCIAL_STARTUP stage=${stage.name}');
      }
      errorMessage =
          'MoolSocial could not restore your setup. Nothing was changed.';
    } finally {
      _setBusy(false);
    }
  }

  Future<void> retryBoot() async {
    _started = false;
    _storeRestored = false;
    _authenticatedAtBoot = false;
    stage = JourneyStage.booting;
    notifyListeners();
    await start();
  }

  void selectLanguage(String value) {
    languageCode = value;
    errorMessage = null;
    notifyListeners();
  }

  void selectArea(AreaChoice value, {String? label}) {
    areaChoice = value;
    manualArea = value == AreaChoice.manual ? label : null;
    if (value == AreaChoice.skipped) {
      currentAreaPrimary = null;
      currentAreaSecondary = null;
      currentAreaLabel = null;
      homeOrWorkArea = null;
    }
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  Future<bool> resolveCurrentArea({bool requestPermission = true}) async {
    if (resolvingCurrentArea) return false;
    resolvingCurrentArea = true;
    errorMessage = null;
    notifyListeners();

    try {
      final area = await _currentAreaGateway.resolve(
        requestPermission: requestPermission,
      );
      currentAreaPrimary = area.primaryLabel;
      currentAreaSecondary = area.secondaryLabel;
      currentAreaLabel = area.fullLabel;
      areaChoice = AreaChoice.current;
      manualArea = area.fullLabel;
      currentAreaFailureReason = null;
      errorMessage = null;
      return true;
    } on CurrentAreaException catch (error) {
      currentAreaPrimary = null;
      currentAreaSecondary = null;
      currentAreaLabel = null;
      areaChoice = null;
      manualArea = null;
      currentAreaFailureReason = error.reason;
      errorMessage = switch (error.reason) {
        CurrentAreaFailureReason.locationServicesOff =>
          'Turn on Location Services to see what’s near you.',
        CurrentAreaFailureReason.permissionNotAllowed ||
        CurrentAreaFailureReason.permissionPermanentlyNotAllowed =>
          'Allow location to see what’s near you.',
        CurrentAreaFailureReason.unavailable =>
          'We couldn’t get your location. Try again or continue for now.',
      };
      return false;
    } on Object {
      currentAreaPrimary = null;
      currentAreaSecondary = null;
      currentAreaLabel = null;
      areaChoice = null;
      manualArea = null;
      currentAreaFailureReason = CurrentAreaFailureReason.unavailable;
      errorMessage =
          'We couldn’t get your location. Try again or continue for now.';
      return false;
    } finally {
      resolvingCurrentArea = false;
      notifyListeners();
    }
  }

  Future<void> openLocationServicesSettings() =>
      _currentAreaGateway.openLocationServicesSettings();

  Future<void> openCurrentAreaAppSettings() =>
      _currentAreaGateway.openAppSettings();

  bool setHomeOrWorkArea(String value) {
    final area = value.trim();
    if (area.length < 3) {
      errorMessage = 'Enter at least 3 characters for your home or work area.';
      notifyListeners();
      return false;
    }
    homeOrWorkArea = area;
    if (currentAreaLabel == null) {
      currentAreaPrimary = area;
      currentAreaSecondary = 'Your chosen area';
      currentAreaLabel = area;
      areaChoice = AreaChoice.current;
      manualArea = area;
    }
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
    return true;
  }

  void changeAreaLater() {
    areaChoice = AreaChoice.skipped;
    manualArea = null;
    currentAreaPrimary = null;
    currentAreaSecondary = null;
    currentAreaLabel = null;
    homeOrWorkArea = null;
    currentAreaFailureReason = null;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  Future<bool> updateLanguage(String value) async {
    final previous = languageCode;
    languageCode = value;
    errorMessage = null;
    notifyListeners();
    try {
      await _persist(setupComplete: true);
      noticeMessage = value == 'hi'
          ? 'भाषा हिन्दी में बदल दी गई है।'
          : 'Language changed to English.';
      notifyListeners();
      return true;
    } on Object {
      languageCode = previous;
      errorMessage = 'Language could not be saved. Try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateArea(AreaChoice value, {String? label}) async {
    final previousChoice = areaChoice;
    final previousLabel = manualArea;
    if (value == AreaChoice.manual &&
        (label == null || label.trim().length < 3)) {
      errorMessage = 'Enter at least 3 characters for your area.';
      notifyListeners();
      return false;
    }

    areaChoice = value;
    manualArea = switch (value) {
      AreaChoice.current => 'Current location',
      AreaChoice.manual => label!.trim(),
      AreaChoice.skipped => null,
    };
    errorMessage = null;
    notifyListeners();
    try {
      await _persist(setupComplete: true);
      noticeMessage = value == AreaChoice.skipped
          ? 'Service area removed. You can add it whenever you need it.'
          : 'Service area updated.';
      notifyListeners();
      return true;
    } on Object {
      areaChoice = previousChoice;
      manualArea = previousLabel;
      errorMessage = 'Service area could not be saved. Try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> useCurrentLocation() async {
    if (busy) return;
    _setBusy(true);
    errorMessage = null;
    noticeMessage = null;

    try {
      final result = await _locationGateway.requestWhenInUse();
      switch (result) {
        case LocationPermissionResult.granted:
          areaChoice = AreaChoice.current;
          manualArea = 'Current location';
          noticeMessage = 'Location access is ready for nearby services.';
        case LocationPermissionResult.denied:
          areaChoice = null;
          errorMessage =
              'Location access was not allowed. Choose manual area or skip.';
        case LocationPermissionResult.permanentlyDenied:
          areaChoice = null;
          errorMessage =
              'Location access is blocked in device settings. Choose manual '
              'area or skip.';
      }
    } on Object {
      areaChoice = null;
      errorMessage =
          'Your location could not be detected. Enter your area or skip for '
          'now.';
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> completeSetup() async {
    if (busy) return false;
    if (areaChoice == null) {
      errorMessage = 'Choose an area option to continue.';
      notifyListeners();
      return false;
    }
    if (areaChoice == AreaChoice.manual &&
        (manualArea == null || manualArea!.trim().length < 3)) {
      errorMessage = 'Enter at least 3 characters for your area.';
      notifyListeners();
      return false;
    }

    _setBusy(true);
    final previousCompletedVersion = _completedSetupExperienceVersion;
    _completedSetupExperienceVersion = approvedSetupExperienceVersion;
    try {
      await _persist(setupComplete: true);
      if (_authenticatedAtBoot) {
        final bootstrap = await _prepareAuthenticatedAccount();
        if (await _acceptAuthenticatedRelaunch(bootstrap)) {
          if (!authenticatedRevalidationPending) {
            await _refreshAuthenticatedAccountIdentity();
          }
          stage = JourneyStage.ready;
        } else {
          stage = JourneyStage.signIn;
        }
      } else if (allowGuestReady) {
        stage = JourneyStage.ready;
      } else {
        stage = JourneyStage.signIn;
      }
      errorMessage = null;
      if (!authenticatedRevalidationPending) noticeMessage = null;
      notifyListeners();
      return true;
    } on Object {
      _completedSetupExperienceVersion = previousCompletedVersion;
      errorMessage = 'Your setup could not be saved. Please retry.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> signInWithSocial(SocialAuthProvider provider) async {
    if (busy) return false;
    if ((_socialAuthCleanupRequired || _principalBindingCleanupRequired) &&
        !await _retrySocialAuthCleanup(provider)) {
      return false;
    }
    _beginSocialAuthAttempt();
    if (!isSocialAuthProviderAvailable(provider)) {
      socialAuthProvider = provider;
      socialAuthState = SocialAuthState.failed;
      _recordSocialAuthReceipt(provider, 'auth-provider-configuration');
      errorMessage =
          '${_socialProviderLabel(provider)} sign-in is not available right now. '
          'Choose another method.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    socialAuthProvider = provider;
    socialAuthState = SocialAuthState.pending;
    _recordSocialAuthReceipt(provider, 'auth-started');
    errorMessage = null;
    noticeMessage = null;
    _setBusy(true);
    try {
      final result = await _socialAuthGateway.signIn(provider);
      if (result.outcome == SocialAuthOutcome.cancelled) {
        socialAuthState = SocialAuthState.cancelled;
        _recordSocialAuthReceipt(provider, result.code ?? 'auth-cancelled');
        errorMessage = _socialAuthCancellationMessage(provider, result.code);
        notifyListeners();
        return false;
      }
      if (result.outcome == SocialAuthOutcome.authorizationPending) {
        _recordSocialAuthReceipt(
          provider,
          result.code ?? 'auth-browser-opened',
        );
        noticeMessage =
            'Complete ${_socialProviderLabel(provider)} sign-in in the secure browser.';
        notifyListeners();
        return false;
      }
      _recordSocialAuthReceipt(
        provider,
        result.code ?? 'auth-provider-credential-complete',
      );
      final expectedUserId = result.userId;
      if (expectedUserId == null || expectedUserId.isEmpty) {
        throw const JourneyServiceException(
          'Your signed-in account could not be verified. Please sign in again.',
          code: 'auth-session-missing',
        );
      }
      try {
        await _completeAuthentication(expectedUserId: expectedUserId);
      } on Object catch (error) {
        if (!await _rollbackIncompleteSocialAuthentication()) {
          throw _socialAuthRollbackFailure(error);
        }
        rethrow;
      }
      _recordSocialAuthReceipt(provider, 'auth-session-ready');
      return true;
    } on JourneyServiceException catch (error) {
      socialAuthState = SocialAuthState.failed;
      _recordSocialAuthReceipt(provider, error.code ?? 'auth-unknown');
      errorMessage = error.userMessage;
      notifyListeners();
      return false;
    } on Object {
      socialAuthState = SocialAuthState.failed;
      _recordSocialAuthReceipt(provider, 'auth-unexpected');
      errorMessage =
          '${_socialProviderLabel(provider)} sign-in could not be completed. '
          'Check the connection and try again.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> prepareSocialAuthReturn(String callbackLocation) async {
    if (_socialAuthGateway is! SocialAuthCallbackGateway) return false;
    final callbackGateway = _socialAuthGateway as SocialAuthCallbackGateway;
    final callbackUri = Uri.tryParse(callbackLocation);
    if (callbackUri == null) return false;
    final provider = callbackGateway.providerForCallback(callbackUri);
    if (provider == null) return false;

    final coldStart = !_started;
    await start();
    if (stage == JourneyStage.bootFailure || _principalBindingCleanupRequired) {
      errorMessage =
          'The previous account verification must be cleared before sign-in can continue. Retry startup.';
      notifyListeners();
      return true;
    }
    final completionRoute = _canonicalPersistedReadyRoute(returnTo);
    if (_isAuthenticated) {
      _beginSocialAuthAttempt();
      stage = JourneyStage.ready;
      socialAuthProvider = provider;
      socialAuthState = SocialAuthState.failed;
      _recordSocialAuthReceipt(provider, 'auth-callback-already-authenticated');
      errorMessage =
          'This sign-in return is no longer active. Sign out before connecting a different account.';
      noticeMessage = null;
      notifyListeners();
      return true;
    }

    if (socialAuthReceiptSequence.isEmpty || socialAuthProvider != provider) {
      _beginSocialAuthAttempt();
    }
    stage = JourneyStage.signIn;
    socialAuthProvider = provider;
    socialAuthState = SocialAuthState.pending;
    _recordSocialAuthReceipt(provider, 'auth-callback-received');
    errorMessage = null;
    noticeMessage = null;
    _setBusy(true);
    try {
      final result = coldStart
          ? await callbackGateway.completeColdStartCallback(callbackUri)
          : await callbackGateway.completeForegroundCallback(callbackUri);
      if (result.outcome == SocialAuthOutcome.cancelled) {
        socialAuthState = SocialAuthState.cancelled;
        _recordSocialAuthReceipt(provider, result.code ?? 'auth-cancelled');
        errorMessage = _socialAuthCancellationMessage(provider, result.code);
        notifyListeners();
        return true;
      }
      if (result.outcome == SocialAuthOutcome.authorizationPending) {
        _recordSocialAuthReceipt(
          provider,
          result.code ?? 'auth-callback-incomplete',
        );
        throw const JourneyServiceException(
          'The account provider returned an incomplete sign-in. Please try again.',
          code: 'auth-provider-configuration',
        );
      }
      _recordSocialAuthReceipt(
        provider,
        result.code ?? 'auth-provider-credential-complete',
      );
      final expectedUserId = result.userId;
      if (expectedUserId == null || expectedUserId.isEmpty) {
        throw const JourneyServiceException(
          'Your signed-in account could not be verified. Please sign in again.',
          code: 'auth-session-missing',
        );
      }
      try {
        await _completeAuthentication(expectedUserId: expectedUserId);
      } on Object catch (error) {
        if (!await _rollbackIncompleteSocialAuthentication()) {
          throw _socialAuthRollbackFailure(error);
        }
        rethrow;
      }
      _recordSocialAuthReceipt(provider, 'auth-session-ready');
      _completedSocialAuthReturnRoute = completionRoute;
      return true;
    } on JourneyServiceException catch (error) {
      socialAuthState = SocialAuthState.failed;
      _recordSocialAuthReceipt(provider, error.code ?? 'auth-unknown');
      errorMessage = error.userMessage;
      notifyListeners();
      return true;
    } on Object {
      socialAuthState = SocialAuthState.failed;
      _recordSocialAuthReceipt(provider, 'auth-unexpected');
      errorMessage =
          '${_socialProviderLabel(provider)} sign-in could not be completed. '
          'Check the connection and try again.';
      notifyListeners();
      return true;
    } finally {
      _setBusy(false);
    }
  }

  String? takeCompletedSocialAuthReturnRoute() {
    final route = _completedSocialAuthReturnRoute;
    _completedSocialAuthReturnRoute = null;
    return route;
  }

  void clearSocialAuthResult() {
    socialAuthProvider = null;
    socialAuthState = SocialAuthState.idle;
    socialAuthReceiptCode = null;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  void _recordSocialAuthReceipt(SocialAuthProvider provider, String code) {
    socialAuthReceiptCode = code;
    if (socialAuthReceiptSequence.length == 16) {
      socialAuthReceiptSequence.removeAt(0);
    }
    socialAuthReceiptSequence.add(code);
    if (kDebugMode || _deviceReviewMode) {
      debugPrint(
        'MOOLSOCIAL_SOCIAL_AUTH attempt=$socialAuthAttempt '
        'provider=${provider.name} code=$code',
      );
    }
  }

  void _beginSocialAuthAttempt() {
    socialAuthAttempt += 1;
    socialAuthReceiptSequence.clear();
  }

  void openEmailLinkEntry() {
    if (busy) return;
    emailLinkState = EmailLinkState.entering;
    emailLinkReceiptCode = null;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  void useDifferentEmailForLink() {
    if (busy) return;
    emailAddress = null;
    _pendingEmailLink = null;
    unawaited(_clearPendingEmailLinkAddress());
    emailLinkState = EmailLinkState.entering;
    emailLinkReceiptCode = null;
    resendAvailableAt = null;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  void cancelEmailLink() {
    if (busy) return;
    emailAddress = null;
    _pendingEmailLink = null;
    unawaited(_clearPendingEmailLinkAddress());
    emailLinkState = EmailLinkState.idle;
    emailLinkReceiptCode = null;
    resendAvailableAt = null;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  Future<bool> prepareEmailLinkReturn(String emailLink) async {
    if (!emailLinkAvailable ||
        emailLink.isEmpty ||
        !_emailLinkGateway.isSignInLink(emailLink)) {
      return false;
    }

    _pendingEmailLink = emailLink;
    _recordEmailLinkReceipt('email-link-callback-received');
    await start();
    if (stage == JourneyStage.bootFailure || _principalBindingCleanupRequired) {
      emailLinkState = EmailLinkState.failed;
      errorMessage =
          'The previous account verification must be cleared before sign-in can continue. Retry startup.';
      notifyListeners();
      return true;
    }
    if (_isAuthenticated) {
      _pendingEmailLink = null;
      await _clearPendingEmailLinkAddress();
      return false;
    }

    stage = JourneyStage.signIn;
    errorMessage = null;
    noticeMessage = null;
    try {
      final retainedAddress = (await _pendingEmailLinkAddressStore.read())
          ?.trim()
          .toLowerCase();
      if (retainedAddress != null && _isValidEmail(retainedAddress)) {
        emailAddress = retainedAddress;
      } else if (retainedAddress != null) {
        await _clearPendingEmailLinkAddress();
      }
    } on Object {
      // Cross-device and unavailable local recovery use matching-address entry.
    }
    if (emailAddress == null) {
      emailLinkState = EmailLinkState.awaitingEmail;
      _recordEmailLinkReceipt('email-link-awaiting-address');
      notifyListeners();
      return true;
    }

    final completionRoute = _canonicalPersistedReadyRoute(returnTo);
    final completed = await completeEmailLink(emailAddress!);
    if (completed && isReady) {
      _completedEmailLinkReturnRoute = completionRoute;
    }
    return true;
  }

  String? takeCompletedEmailLinkReturnRoute() {
    final route = _completedEmailLinkReturnRoute;
    _completedEmailLinkReturnRoute = null;
    return route;
  }

  Future<bool> requestEmailLink(String value) async {
    if (busy) return false;
    if (!_bindingCleanupAllowsAuthentication()) return false;
    if (!emailLinkAvailable) {
      emailLinkState = EmailLinkState.failed;
      _recordEmailLinkReceipt('email-link-unavailable');
      errorMessage =
          'Email link sign-in is not available right now. Choose another method.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }

    final email = value.trim().toLowerCase();
    if (!_isValidEmail(email)) {
      emailLinkState = EmailLinkState.entering;
      _recordEmailLinkReceipt('email-link-invalid-email');
      errorMessage = 'Enter a valid email address.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }

    emailAddress = email;
    _pendingEmailLink = null;
    emailLinkState = EmailLinkState.sending;
    _recordEmailLinkReceipt('email-link-send-started');
    _setBusy(true);
    errorMessage = null;
    noticeMessage = null;
    var recoveryAddressPersisted = false;
    try {
      await _pendingEmailLinkAddressStore.write(email);
      recoveryAddressPersisted = true;
      await _emailLinkGateway.sendSignInLink(email);
      resendAvailableAt = _now().add(resendCooldown);
      emailLinkState = EmailLinkState.sent;
      _recordEmailLinkReceipt('email-link-sent');
      noticeMessage = 'A secure sign-in link was sent.';
      notifyListeners();
      return true;
    } on JourneyServiceException catch (error) {
      await _clearPendingEmailLinkAddress();
      _applyEmailLinkFailure(error);
      return false;
    } on Object {
      await _clearPendingEmailLinkAddress();
      _applyEmailLinkFailure(
        recoveryAddressPersisted
            ? const JourneyServiceException(
                'The email service is unavailable. Check the connection and retry.',
                code: 'email-link-bridge-failure',
              )
            : const JourneyServiceException(
                'This device could not save the secure sign-in request. Please try again.',
                code: 'email-link-local-recovery-unavailable',
              ),
      );
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> resendEmailLink() async {
    if (busy) return false;
    final email = emailAddress;
    if (email == null) {
      openEmailLinkEntry();
      return false;
    }
    if (!canResend) {
      errorMessage = 'You can request a new link in $resendSeconds seconds.';
      notifyListeners();
      return false;
    }
    return requestEmailLink(email);
  }

  Future<bool> completeEmailLink(String value) async {
    if (isReady || _authenticationCompletionInProgress) return true;
    if (busy) return false;
    if (!_bindingCleanupAllowsAuthentication()) return false;
    final emailLink = _pendingEmailLink;
    if (emailLink == null) {
      _applyEmailLinkFailure(
        const JourneyServiceException(
          'This sign-in link is invalid. Request a new link.',
          code: 'invalid-action-code',
        ),
      );
      return false;
    }
    final email = value.trim().toLowerCase();
    if (!_isValidEmail(email)) {
      emailLinkState = EmailLinkState.awaitingEmail;
      _recordEmailLinkReceipt('email-link-invalid-email');
      errorMessage = 'Enter the email address that received this link.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }

    emailAddress = email;
    emailLinkState = EmailLinkState.completing;
    _recordEmailLinkReceipt('email-link-completing');
    _setBusy(true);
    errorMessage = null;
    noticeMessage = null;
    try {
      await _emailLinkGateway.signInWithEmailLink(
        emailAddress: email,
        emailLink: emailLink,
      );
      _recordEmailLinkReceipt('email-link-firebase-credential-complete');
      try {
        await _completeAuthentication();
      } on Object {
        await _rollbackIncompleteEmailLinkAuthentication();
        rethrow;
      }
      _pendingEmailLink = null;
      await _clearPendingEmailLinkAddress();
      emailLinkState = EmailLinkState.idle;
      _recordEmailLinkReceipt('email-link-session-ready');
      return true;
    } on JourneyServiceException catch (error) {
      _applyEmailLinkFailure(error);
      return false;
    } on Object {
      _applyEmailLinkFailure(
        const JourneyServiceException(
          'Sign-in could not be completed. Check the connection and retry.',
          code: 'email-link-bridge-failure',
        ),
      );
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void _applyEmailLinkFailure(JourneyServiceException error) {
    _recordEmailLinkReceipt(error.code ?? 'email-link-unclassified');
    emailLinkState = switch (error.code) {
      'expired-action-code' => EmailLinkState.expired,
      'email-link-already-used' => EmailLinkState.used,
      'invalid-action-code' => EmailLinkState.invalid,
      'invalid-email' ||
      'invalid-recipient-email' ||
      'missing-email' => EmailLinkState.awaitingEmail,
      _ => EmailLinkState.failed,
    };
    errorMessage = error.userMessage;
    noticeMessage = null;
    notifyListeners();
  }

  Future<void> _clearPendingEmailLinkAddress() async {
    try {
      await _pendingEmailLinkAddressStore.clear();
    } on Object {
      // The provider failure remains the customer-visible recovery path.
    }
  }

  void _recordEmailLinkReceipt(String code) {
    emailLinkReceiptCode = code;
    if (kDebugMode || _deviceReviewMode) {
      debugPrint('MOOLSOCIAL_EMAIL_LINK code=$code');
    }
  }

  Future<bool> requestOtp(String value) async {
    if (busy) return false;
    if (!_bindingCleanupAllowsAuthentication()) return false;
    if (!mobileOtpAvailable) {
      errorMessage =
          'Mobile OTP is not available right now. Choose another method.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (!_isValidIndianMobile(digits)) {
      errorMessage = 'Enter a valid 10-digit Indian mobile number.';
      notifyListeners();
      return false;
    }

    phoneNumber = digits;
    otpChannel = OtpChannel.mobile;
    return _sendOtp();
  }

  Future<bool> requestEmailOtp(String value) async {
    if (busy) return false;
    if (!_bindingCleanupAllowsAuthentication()) return false;
    if (!emailOtpAvailable) {
      errorMessage =
          'Email OTP is not available right now. Choose another method.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    final email = value.trim().toLowerCase();
    if (!_isValidEmail(email)) {
      errorMessage = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }

    emailAddress = email;
    otpChannel = OtpChannel.email;
    return _sendEmailOtp();
  }

  Future<bool> resendOtp() async {
    if (busy) return false;
    if (otpChannel == OtpChannel.email) {
      if (emailAddress == null) {
        errorMessage = 'Enter your email address and request a code.';
        notifyListeners();
        return false;
      }
    } else if (phoneNumber == null) {
      errorMessage = 'Enter your mobile number and request a code.';
      notifyListeners();
      return false;
    }
    if (!canResend) {
      errorMessage = 'You can request a new code in $resendSeconds seconds.';
      notifyListeners();
      return false;
    }
    return otpChannel == OtpChannel.email ? _sendEmailOtp() : _sendOtp();
  }

  Future<bool> _sendOtp() async {
    final digits = phoneNumber;
    if (digits == null) return false;

    _setBusy(true);
    errorMessage = null;
    noticeMessage = null;
    reviewCode = null;

    final e164 = '+91$digits';
    try {
      final result = await _otpGateway.requestCode(e164);
      if (result.automaticallyVerified) {
        try {
          await _completeAuthentication();
        } on Object {
          await _rollbackIncompleteOtpAuthentication();
          rethrow;
        }
        return true;
      }

      otpExpiresAt = _now().add(otpValidity);
      resendAvailableAt = _now().add(resendCooldown);
      stage = JourneyStage.verify;
      reviewCode = await _otpGateway.reviewCodeFor(e164);
      noticeMessage = 'A verification code is ready.';
      notifyListeners();
      return true;
    } on JourneyServiceException catch (error) {
      errorMessage = error.userMessage;
      notifyListeners();
      return false;
    } on Object {
      errorMessage =
          'The verification service is unavailable. Check the connection and retry.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> _sendEmailOtp() async {
    final email = emailAddress;
    if (email == null) return false;

    _setBusy(true);
    errorMessage = null;
    noticeMessage = null;
    reviewCode = null;

    try {
      await _emailOtpGateway.requestCode(email);
      otpExpiresAt = _now().add(otpValidity);
      resendAvailableAt = _now().add(resendCooldown);
      stage = JourneyStage.verify;
      reviewCode = await _emailOtpGateway.reviewCodeFor(email);
      noticeMessage = 'A verification code is ready.';
      notifyListeners();
      return true;
    } on JourneyServiceException catch (error) {
      errorMessage = error.userMessage;
      notifyListeners();
      return false;
    } on Object {
      errorMessage =
          'The verification service is unavailable. Check the connection and retry.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> verifyOtp(String value) async {
    if (isReady || _authenticationCompletionInProgress) return true;
    if (busy) return false;
    if (!_bindingCleanupAllowsAuthentication()) return false;
    final code = value.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) {
      errorMessage = 'Enter the complete 6-digit code.';
      notifyListeners();
      return false;
    }
    final expires = otpExpiresAt;
    if (expires == null || !_now().isBefore(expires)) {
      errorMessage = 'That code has expired. Request a new code.';
      notifyListeners();
      return false;
    }

    _setBusy(true);
    errorMessage = null;
    try {
      if (otpChannel == OtpChannel.email) {
        await _emailOtpGateway.verifyCode(code);
      } else {
        await _otpGateway.verifyCode(code);
      }
      try {
        await _completeAuthentication();
      } on Object {
        if (otpChannel == OtpChannel.mobile) {
          await _rollbackIncompleteOtpAuthentication();
        }
        rethrow;
      }
      return true;
    } on JourneyServiceException catch (error) {
      errorMessage = error.userMessage;
      notifyListeners();
      return false;
    } on Object {
      errorMessage =
          'Verification could not be completed. Check the connection and retry.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _completeAuthentication({String? expectedUserId}) async {
    if (stage == JourneyStage.ready || _authenticationCompletionInProgress) {
      return;
    }
    _authenticationGeneration += 1;
    _authenticationCompletionInProgress = true;
    try {
      final bootstrap = await _prepareAuthenticatedAccount(
        expectedUserId: expectedUserId,
      );
      _requireVerifiedInteractiveBootstrap(bootstrap);
      await _refreshAuthenticatedAccountIdentity();
      await _persist(setupComplete: true);
      await _retainVerifiedPrincipalForOnlineSession(bootstrap.currentBinding!);
      _isAuthenticated = true;
      authenticatedRevalidationPending = false;
      stage = JourneyStage.ready;
      errorMessage = null;
      noticeMessage = null;
      reviewCode = null;
      socialAuthProvider = null;
      socialAuthState = SocialAuthState.idle;
      _authenticationCancelTo = null;
      authenticationPurpose = JourneyAuthenticationPurpose.general;
      notifyListeners();
    } finally {
      _authenticationCompletionInProgress = false;
    }
  }

  Future<bool> _rollbackIncompleteSocialAuthentication() async {
    _isAuthenticated = false;
    accountIdentity = null;
    _socialAuthCleanupRequired = true;
    try {
      await _socialAuthGateway.signOut().timeout(socialAuthRollbackTimeout);
      if (!await _clearVerifiedPrincipalAfterAuthFailure()) return false;
      _socialAuthCleanupRequired = false;
      return true;
    } on Object {
      return false;
    }
  }

  JourneyServiceException _socialAuthRollbackFailure(Object originalError) {
    final originalMessage = originalError is JourneyServiceException
        ? '${originalError.userMessage} '
        : '';
    return JourneyServiceException(
      '${originalMessage}The incomplete sign-in could not be cleared safely. '
      'Please close and reopen the app before trying again.',
      code: 'auth-rollback-failed',
    );
  }

  Future<bool> _retrySocialAuthCleanup(SocialAuthProvider provider) async {
    socialAuthProvider = provider;
    socialAuthState = SocialAuthState.pending;
    errorMessage = null;
    noticeMessage = null;
    _setBusy(true);
    try {
      await _socialAuthGateway.signOut().timeout(socialAuthRollbackTimeout);
      if (!await _clearVerifiedPrincipalAfterAuthFailure()) {
        throw const JourneyServiceException(
          'Saved account verification could not be cleared safely.',
          code: 'auth-binding-clear-failed',
        );
      }
      _socialAuthCleanupRequired = false;
      return true;
    } on Object {
      socialAuthState = SocialAuthState.failed;
      _recordSocialAuthReceipt(provider, 'auth-rollback-failed');
      errorMessage =
          'The previous sign-in could not be cleared safely. Please close and reopen the app before trying again.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _rollbackIncompleteOtpAuthentication() async {
    _isAuthenticated = false;
    accountIdentity = null;
    try {
      await _otpGateway.signOut();
    } on Object {
      // The original account-bootstrap failure remains the visible recovery.
    }
    await _clearVerifiedPrincipalAfterAuthFailure();
  }

  Future<void> _rollbackIncompleteEmailLinkAuthentication() async {
    _isAuthenticated = false;
    accountIdentity = null;
    try {
      await _emailLinkGateway.signOut();
    } on Object {
      // The original account-bootstrap failure remains the visible recovery.
    }
    await _clearVerifiedPrincipalAfterAuthFailure();
  }

  void changeSignInMethod() {
    stage = JourneyStage.signIn;
    otpExpiresAt = null;
    resendAvailableAt = null;
    reviewCode = null;
    otpChannel = null;
    emailLinkState = EmailLinkState.idle;
    emailLinkReceiptCode = null;
    _pendingEmailLink = null;
    unawaited(_clearPendingEmailLinkAddress());
    _completedEmailLinkReturnRoute = null;
    _completedSocialAuthReturnRoute = null;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  void beginSignIn({
    required String returnLocation,
    String? cancelLocation,
    JourneyAuthenticationPurpose purpose = JourneyAuthenticationPurpose.general,
  }) {
    if (_isAuthenticated) return;
    returnTo = returnLocation;
    _authenticationCancelTo = cancelLocation ?? returnLocation;
    authenticationPurpose = purpose;
    stage = JourneyStage.signIn;
    errorMessage = null;
    noticeMessage = null;
    otpExpiresAt = null;
    resendAvailableAt = null;
    reviewCode = null;
    otpChannel = null;
    emailLinkState = EmailLinkState.idle;
    emailLinkReceiptCode = null;
    _pendingEmailLink = null;
    unawaited(_clearPendingEmailLinkAddress());
    _completedEmailLinkReturnRoute = null;
    _completedSocialAuthReturnRoute = null;
    socialAuthProvider = null;
    socialAuthState = SocialAuthState.idle;
    if (_storeRestored) {
      _persist(setupComplete: true);
    }
    notifyListeners();
  }

  void cancelSignIn() {
    if (!canCancelSignIn) return;
    final cancelLocation = _authenticationCancelTo;
    stage = JourneyStage.ready;
    returnTo = null;
    _lastReadyRoute =
        _canonicalPersistedReadyRoute(cancelLocation) ?? _lastReadyRoute;
    errorMessage = null;
    noticeMessage = null;
    otpExpiresAt = null;
    resendAvailableAt = null;
    reviewCode = null;
    otpChannel = null;
    emailLinkState = EmailLinkState.idle;
    emailLinkReceiptCode = null;
    _pendingEmailLink = null;
    unawaited(_clearPendingEmailLinkAddress());
    _completedEmailLinkReturnRoute = null;
    _completedSocialAuthReturnRoute = null;
    socialAuthProvider = null;
    socialAuthState = SocialAuthState.idle;
    authenticationPurpose = JourneyAuthenticationPurpose.general;
    _persist(setupComplete: true);
    notifyListeners();
  }

  Future<bool> signOut() async {
    if (busy) return false;
    _authenticationGeneration += 1;
    _setBusy(true);
    try {
      Object? cleanupFailure;
      var localSessionInvalidated = false;
      try {
        await _clearVerifiedPrincipalBinding().timeout(
          socialAuthRollbackTimeout,
        );
        _principalBindingCleanupRequired = false;
      } on Object catch (error) {
        _principalBindingCleanupRequired = true;
        cleanupFailure = error;
      }
      for (final cleanup in <Future<void> Function()>[
        _otpGateway.signOut,
        _socialAuthGateway.signOut,
        _emailLinkGateway.signOut,
      ]) {
        try {
          await cleanup().timeout(socialAuthRollbackTimeout);
        } on Object catch (error) {
          cleanupFailure ??= error;
        }
      }
      try {
        await _accountBootstrapGateway.invalidateLocalSession().timeout(
          socialAuthRollbackTimeout,
        );
        localSessionInvalidated = true;
      } on Object catch (error) {
        cleanupFailure ??= error;
      }
      await _clearPendingEmailLinkAddress();
      if (localSessionInvalidated) _applyLocallySignedOutState();
      if (cleanupFailure != null) {
        errorMessage = localSessionInvalidated
            ? 'You are signed out on this device, but saved verification cleanup must finish before another sign-in. Retry startup.'
            : 'Sign-out could not be completed safely. Check the connection and try again.';
        noticeMessage = null;
        notifyListeners();
        return false;
      }
      errorMessage = null;
      noticeMessage =
          'You are signed out. Your language and area are retained.';
      await _persist(setupComplete: true);
      notifyListeners();
      return true;
    } finally {
      _setBusy(false);
    }
  }

  void _applyLocallySignedOutState() {
    _isAuthenticated = false;
    authenticatedRevalidationPending = false;
    accountIdentity = null;
    stage = JourneyStage.signIn;
    phoneNumber = null;
    emailAddress = null;
    otpChannel = null;
    emailLinkState = EmailLinkState.idle;
    emailLinkReceiptCode = null;
    _pendingEmailLink = null;
    _completedEmailLinkReturnRoute = null;
    _completedSocialAuthReturnRoute = null;
    socialAuthProvider = null;
    socialAuthState = SocialAuthState.idle;
    authenticationPurpose = JourneyAuthenticationPurpose.general;
  }

  Future<bool> retryAuthenticatedAccountRevalidation() {
    final existing = _authenticatedRevalidationFuture;
    if (existing != null) return existing;
    if (!_isAuthenticated || !authenticatedRevalidationPending) {
      return Future<bool>.value(false);
    }
    final generation = _authenticationGeneration;
    final attempt = _runAuthenticatedAccountRevalidation(generation);
    _authenticatedRevalidationFuture = attempt;
    return attempt;
  }

  Future<bool> _runAuthenticatedAccountRevalidation(int generation) async {
    try {
      final bootstrap = await _prepareAuthenticatedAccount();
      if (!_isActiveRevalidationGeneration(generation)) return false;
      if (bootstrap.state == AuthenticatedAccountBootstrapState.fatal) {
        await _invalidateMismatchedPrincipal();
        errorMessage =
            'Your account session could not be verified safely. Please sign in again.';
        _notifyRevalidationListeners();
        return false;
      }
      final accepted = await _acceptAuthenticatedRelaunch(
        bootstrap,
        revalidationGeneration: generation,
      );
      if (!_isCurrentAuthenticationGeneration(generation)) return false;
      if (!accepted) {
        _notifyRevalidationListeners();
        return false;
      }
      if (authenticatedRevalidationPending) {
        _notifyRevalidationListeners();
        return false;
      }
      await _refreshAuthenticatedAccountIdentity(generation: generation);
      if (!_isCurrentAuthenticationGeneration(generation)) return false;
      errorMessage = null;
      noticeMessage = null;
      _notifyRevalidationListeners();
      return true;
    } on Object {
      _notifyRevalidationListeners();
      return false;
    } finally {
      _authenticatedRevalidationFuture = null;
    }
  }

  bool _isActiveRevalidationGeneration(int generation) =>
      _isCurrentAuthenticationGeneration(generation) &&
      authenticatedRevalidationPending;

  bool _isCurrentAuthenticationGeneration(int generation) =>
      !_disposed && generation == _authenticationGeneration && _isAuthenticated;

  void _notifyRevalidationListeners() {
    if (!_disposed) notifyListeners();
  }

  void captureReturnTo(String location) {
    if (returnTo == null && location.startsWith('/app/')) {
      returnTo = location;
      if (_storeRestored) {
        _persist(setupComplete: areaChoice != null);
      } else {
        _persistCapturedRouteBeforeRestore(location);
      }
    }
  }

  Future<void> _persistCapturedRouteBeforeRestore(String location) async {
    try {
      final snapshot = await _store.read();
      if (_storeRestored || returnTo != location) {
        return;
      }
      if (snapshot == null) {
        await _persist(setupComplete: false);
        return;
      }
      await _writeSnapshotInOrder(
        JourneySnapshot(
          languageCode: snapshot.languageCode,
          areaMode: snapshot.areaMode,
          areaLabel: snapshot.areaLabel,
          currentAreaLabel: snapshot.currentAreaLabel,
          homeOrWorkAreaLabel: snapshot.homeOrWorkAreaLabel,
          setupComplete: snapshot.setupComplete,
          pendingRoute: location,
          pendingAuthenticationCancelRoute:
              snapshot.pendingAuthenticationCancelRoute,
          pendingAuthenticationPurpose: snapshot.pendingAuthenticationPurpose,
          lastReadyRoute: snapshot.lastReadyRoute,
          setupExperienceVersion: snapshot.setupExperienceVersion,
        ),
      );
    } on Object {
      // Startup still retains the route in memory and owns visible recovery.
    }
  }

  String readyRoute() => _authenticationCancelTo ?? returnTo ?? '/app/social';

  void confirmReadyRoute(String location) {
    final nextReadyRoute = _canonicalPersistedReadyRoute(location);
    final readyRouteChanged = nextReadyRoute != _lastReadyRoute;
    _lastReadyRoute = nextReadyRoute;
    var returnRouteCleared = false;
    if (_authenticationCancelTo == location) {
      _authenticationCancelTo = null;
    }
    if (returnTo == location) {
      returnTo = null;
      returnRouteCleared = true;
    }
    if (readyRouteChanged || returnRouteCleared) {
      _persist(setupComplete: true);
    }
  }

  String buyExitRoute({String? requestedRoute}) =>
      requestedRoute == '/app/mool' ? '/app/mool' : '/app/mool?from=buy';

  void openMoolFrom(String section) {
    if (section != 'mool') previousPrimarySection = section;
  }

  String closeMoolRoute() => '/app/$previousPrimarySection';

  Future<void> _persist({required bool setupComplete}) {
    return _writeSnapshotInOrder(
      JourneySnapshot(
        languageCode: languageCode,
        areaMode: areaChoice?.name,
        areaLabel: manualArea,
        currentAreaLabel: currentAreaLabel,
        homeOrWorkAreaLabel: homeOrWorkArea,
        setupComplete: setupComplete,
        pendingRoute: returnTo,
        pendingAuthenticationCancelRoute: stage == JourneyStage.signIn
            ? _authenticationCancelTo
            : null,
        pendingAuthenticationPurpose: stage == JourneyStage.signIn
            ? authenticationPurpose.name
            : null,
        lastReadyRoute: _lastReadyRoute,
        setupExperienceVersion: _completedSetupExperienceVersion,
      ),
    );
  }

  Future<void> _writeSnapshotInOrder(JourneySnapshot snapshot) {
    final previous = _persistenceTail;
    final current = () async {
      try {
        await previous;
      } on Object {
        // A failed caller retains its own error, but cannot poison later state.
      }
      await _store.write(snapshot);
    }();
    _persistenceTail = current;
    return current;
  }

  bool _isValidIndianMobile(String digits) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(digits);
  }

  bool _isValidEmail(String value) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
      caseSensitive: false,
    ).hasMatch(value);
  }

  String _socialProviderLabel(SocialAuthProvider provider) {
    return switch (provider) {
      SocialAuthProvider.google => 'Google',
      SocialAuthProvider.youtube => 'YouTube',
      SocialAuthProvider.apple => 'Apple',
      SocialAuthProvider.x => 'X',
      SocialAuthProvider.instagram => 'Instagram',
      SocialAuthProvider.facebook => 'Facebook',
    };
  }

  String _socialAuthCancellationMessage(
    SocialAuthProvider provider,
    String? code,
  ) {
    if (provider == SocialAuthProvider.google &&
        code == 'auth-google-native-no-identity') {
      return 'Google did not return an identity (GSI-N01). '
          'If you did not close the account chooser, try once more.';
    }
    return '${_socialProviderLabel(provider)} sign-in wasn’t completed. '
        'Try again or choose another method.';
  }

  AreaChoice? _areaChoiceFromStorage(String? value) {
    if (value == null) return null;
    for (final choice in AreaChoice.values) {
      if (choice.name == value) return choice;
    }
    return null;
  }

  int _remainingSeconds(DateTime deadline) {
    final milliseconds = deadline.difference(_now()).inMilliseconds;
    if (milliseconds <= 0) return 0;
    return (milliseconds + 999) ~/ 1000;
  }

  void _setBusy(bool value) {
    busy = value;
    notifyListeners();
  }

  Future<AuthenticatedAccountBootstrapResult> _prepareAuthenticatedAccount({
    String? expectedUserId,
  }) async {
    VerifiedPrincipalBinding? localBinding;
    try {
      localBinding = await _accountBootstrapGateway
          .currentPrincipalBinding()
          .timeout(accountBootstrapTimeout);
    } on TimeoutException {
      localBinding = null;
    } on Object {
      await _resetUnsafePrincipalBinding();
      return const AuthenticatedAccountBootstrapResult.invalidSession(
        code: 'auth-binding-reset-required',
      );
    }
    return _accountBootstrapGateway
        .prepareAuthenticatedAccount(expectedUserId: expectedUserId)
        .timeout(
          accountBootstrapTimeout,
          onTimeout: () => expectedUserId?.isNotEmpty ?? false
              ? const AuthenticatedAccountBootstrapResult.fatal(
                  code: 'auth-session-timeout',
                )
              : _classifyBootstrapTimeout(localBinding),
        );
  }

  Future<AuthenticatedAccountBootstrapResult> _classifyBootstrapTimeout(
    VerifiedPrincipalBinding? before,
  ) async {
    if (before == null) {
      return const AuthenticatedAccountBootstrapResult.fatal(
        code: 'auth-session-timeout-unbound',
      );
    }

    final VerifiedPrincipalBinding? after;
    try {
      after = await _accountBootstrapGateway.currentPrincipalBinding().timeout(
        accountBootstrapTimeout,
      );
    } on Object {
      return const AuthenticatedAccountBootstrapResult.fatal(
        code: 'auth-session-timeout-recheck-failed',
      );
    }
    if (after == null) {
      return const AuthenticatedAccountBootstrapResult.invalidSession(
        code: 'auth-session-missing',
      );
    }
    if (!before.matches(after)) {
      return const AuthenticatedAccountBootstrapResult.invalidSession(
        code: 'auth-session-user-mismatch',
      );
    }

    final VerifiedPrincipalBinding? stored;
    try {
      stored = await _verifiedPrincipalBindingStore.read();
    } on Object {
      await _resetUnsafePrincipalBinding();
      return const AuthenticatedAccountBootstrapResult.invalidSession(
        code: 'auth-binding-reset-required',
      );
    }
    if (stored == null) {
      return const AuthenticatedAccountBootstrapResult.fatal(
        code: 'auth-session-timeout-unbound',
      );
    }
    if (!stored.matches(after)) {
      return const AuthenticatedAccountBootstrapResult.invalidSession(
        code: 'auth-session-binding-mismatch',
      );
    }
    return AuthenticatedAccountBootstrapResult.retryableUnavailable(
      after,
      code: 'auth-session-timeout',
    );
  }

  Future<bool> _acceptAuthenticatedRelaunch(
    AuthenticatedAccountBootstrapResult bootstrap, {
    int? revalidationGeneration,
  }) async {
    authenticatedBootstrapState = bootstrap.state;
    if (revalidationGeneration != null &&
        !_isActiveRevalidationGeneration(revalidationGeneration)) {
      return false;
    }
    switch (bootstrap.state) {
      case AuthenticatedAccountBootstrapState.verified:
        final current = bootstrap.currentBinding!;
        final VerifiedPrincipalBinding? stored;
        try {
          stored = await _verifiedPrincipalBindingStore.read();
        } on Object {
          await _resetUnsafePrincipalBinding();
          return false;
        }
        if (revalidationGeneration != null &&
            !_isActiveRevalidationGeneration(revalidationGeneration)) {
          return false;
        }
        if (stored != null && !stored.matches(current)) {
          await _invalidateMismatchedPrincipal();
          return false;
        }
        if (!await _retainVerifiedPrincipalForOnlineSession(
          current,
          existing: stored,
          revalidationGeneration: revalidationGeneration,
        )) {
          return false;
        }
        if (revalidationGeneration != null &&
            !_isActiveRevalidationGeneration(revalidationGeneration)) {
          return false;
        }
        authenticatedRevalidationPending = false;
        return true;
      case AuthenticatedAccountBootstrapState.retryableUnavailable:
        final current = bootstrap.currentBinding!;
        final VerifiedPrincipalBinding? stored;
        try {
          stored = await _verifiedPrincipalBindingStore.read();
        } on Object {
          await _resetUnsafePrincipalBinding();
          return false;
        }
        if (revalidationGeneration != null &&
            !_isActiveRevalidationGeneration(revalidationGeneration)) {
          return false;
        }
        if (stored == null) {
          throw const JourneyServiceException(
            'Your account must complete one online verification before offline access is available.',
            code: 'auth-session-offline-unbound',
          );
        }
        if (!stored.matches(current)) {
          await _invalidateMismatchedPrincipal();
          return false;
        }
        authenticatedRevalidationPending = true;
        accountIdentity = null;
        noticeMessage =
            'You are offline. Eligible saved content remains available while account verification waits.';
        return true;
      case AuthenticatedAccountBootstrapState.invalidSession:
        if (bootstrap.code == 'auth-binding-reset-required') return false;
        await _invalidateMismatchedPrincipal();
        return false;
      case AuthenticatedAccountBootstrapState.fatal:
        throw JourneyServiceException(
          'Your account session could not be verified safely. Please retry online.',
          code: bootstrap.code,
        );
    }
  }

  void _requireVerifiedInteractiveBootstrap(
    AuthenticatedAccountBootstrapResult bootstrap,
  ) {
    authenticatedBootstrapState = bootstrap.state;
    if (bootstrap.state == AuthenticatedAccountBootstrapState.verified &&
        bootstrap.currentBinding != null) {
      return;
    }
    if (bootstrap.code == 'auth-session-timeout') {
      throw const JourneyServiceException(
        'Your account service did not respond. Check the connection and try again.',
        code: 'auth-session-timeout',
      );
    }
    final message = switch (bootstrap.state) {
      AuthenticatedAccountBootstrapState.retryableUnavailable =>
        'Your account service did not respond. Check the connection and try again.',
      AuthenticatedAccountBootstrapState.invalidSession =>
        'Your signed-in account could not be verified. Please sign in again.',
      AuthenticatedAccountBootstrapState.fatal =>
        'Your account session could not be verified safely. Please try again.',
      AuthenticatedAccountBootstrapState.verified =>
        'Your signed-in account could not be verified. Please sign in again.',
    };
    throw JourneyServiceException(message, code: bootstrap.code);
  }

  Future<bool> _retainVerifiedPrincipalForOnlineSession(
    VerifiedPrincipalBinding binding, {
    VerifiedPrincipalBinding? existing,
    int? revalidationGeneration,
  }) async {
    final VerifiedPrincipalBinding? prior;
    try {
      prior = existing ?? await _verifiedPrincipalBindingStore.read();
    } on Object {
      await _resetUnsafePrincipalBinding();
      throw const JourneyServiceException(
        'Saved account verification was unsafe and has been reset. Please sign in again.',
        code: 'auth-binding-reset-required',
      );
    }
    if (revalidationGeneration != null &&
        !_isActiveRevalidationGeneration(revalidationGeneration)) {
      return false;
    }
    if (prior != null && prior.matches(binding)) return true;
    try {
      await _writeVerifiedPrincipalBinding(binding);
      if (revalidationGeneration != null &&
          !_isActiveRevalidationGeneration(revalidationGeneration)) {
        return false;
      }
    } on Object {
      try {
        await _clearVerifiedPrincipalBinding();
      } on Object {
        throw const JourneyServiceException(
          'Your account verification could not be stored or cleared safely.',
          code: 'auth-binding-unsafe-state',
        );
      }
      // The online session remains valid, but no offline receipt is retained.
    }
    return true;
  }

  Future<T> _runPrincipalBindingMutation<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _principalBindingMutationTail = _principalBindingMutationTail.then((
      _,
    ) async {
      try {
        completer.complete(await operation());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _writeVerifiedPrincipalBinding(
    VerifiedPrincipalBinding binding,
  ) => _runPrincipalBindingMutation(
    () => _verifiedPrincipalBindingStore.write(binding),
  );

  Future<void> _clearVerifiedPrincipalBinding() =>
      _runPrincipalBindingMutation(_verifiedPrincipalBindingStore.clear);

  Future<void> _resetUnsafeVerifiedPrincipalBinding() =>
      _runPrincipalBindingMutation(
        _verifiedPrincipalBindingStore.resetUnsafeState,
      );

  Future<void> _invalidateMismatchedPrincipal() async {
    _authenticationGeneration += 1;
    Object? cleanupFailure;
    for (final cleanup in <Future<void> Function()>[
      _clearVerifiedPrincipalBinding,
      _accountBootstrapGateway.invalidateLocalSession,
      _otpGateway.signOut,
      _socialAuthGateway.signOut,
      _emailLinkGateway.signOut,
    ]) {
      try {
        await cleanup().timeout(socialAuthRollbackTimeout);
      } on Object catch (error) {
        cleanupFailure ??= error;
      }
    }
    _isAuthenticated = false;
    authenticatedRevalidationPending = false;
    accountIdentity = null;
    if (cleanupFailure != null) {
      throw const JourneyServiceException(
        'The invalid account session could not be cleared safely.',
        code: 'auth-session-invalidation-failed',
      );
    }
    stage = JourneyStage.signIn;
  }

  Future<void> _resetUnsafePrincipalBinding() async {
    _authenticationGeneration += 1;
    Object? cleanupFailure;
    for (final cleanup in <Future<void> Function()>[
      _resetUnsafeVerifiedPrincipalBinding,
      _accountBootstrapGateway.invalidateLocalSession,
      _otpGateway.signOut,
      _socialAuthGateway.signOut,
      _emailLinkGateway.signOut,
    ]) {
      try {
        await cleanup().timeout(socialAuthRollbackTimeout);
      } on Object catch (error) {
        cleanupFailure ??= error;
      }
    }
    _isAuthenticated = false;
    authenticatedRevalidationPending = false;
    accountIdentity = null;
    _principalBindingCleanupRequired = cleanupFailure != null;
    _unsafePrincipalResetRequired = cleanupFailure != null;
    if (cleanupFailure != null) {
      throw const JourneyServiceException(
        'Unsafe account verification could not be reset safely.',
        code: 'auth-binding-reset-failed',
      );
    }
    _unsafePrincipalResetRequired = false;
    stage = JourneyStage.signIn;
  }

  Future<void> _clearReceiptForSignedOutEntry() async {
    if (_unsafePrincipalResetRequired) {
      await _resetUnsafePrincipalBinding();
      return;
    }
    try {
      await _clearVerifiedPrincipalBinding();
      _principalBindingCleanupRequired = false;
    } on Object {
      _principalBindingCleanupRequired = true;
      throw const JourneyServiceException(
        'The previous account verification could not be cleared safely.',
        code: 'auth-binding-cleanup-required',
      );
    }
  }

  Future<bool> _clearVerifiedPrincipalAfterAuthFailure() async {
    try {
      await _clearVerifiedPrincipalBinding();
      _principalBindingCleanupRequired = false;
      return true;
    } on Object {
      _principalBindingCleanupRequired = true;
      return false;
    }
  }

  bool _bindingCleanupAllowsAuthentication() {
    if (!_principalBindingCleanupRequired) return true;
    errorMessage =
        'The previous account verification must be cleared before sign-in can continue. Retry startup.';
    noticeMessage = null;
    notifyListeners();
    return false;
  }

  Future<void> _refreshAuthenticatedAccountIdentity({int? generation}) async {
    AuthenticatedAccountIdentity? refreshed;
    try {
      refreshed = await _accountIdentityGateway.currentIdentity();
    } on Object {
      refreshed = null;
    }
    if (generation != null && !_isCurrentAuthenticationGeneration(generation)) {
      return;
    }
    accountIdentity = refreshed;
    accountIdentity ??= switch ((emailAddress, phoneNumber)) {
      (final email?, _) when email.trim().isNotEmpty =>
        AuthenticatedAccountIdentity(
          emailAddress: email.trim(),
          signInMethods: const ['Email'],
        ),
      (_, final phone?) when phone.trim().isNotEmpty =>
        AuthenticatedAccountIdentity(
          phoneNumber: phone.trim(),
          signInMethods: const ['Phone'],
        ),
      _ => null,
    };
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _authenticationGeneration += 1;
    }
    super.dispose();
  }
}

bool _requiresAuthentication(Uri? uri) {
  if (uri == null) return false;
  if (_isChatPath(uri.path)) return true;
  if (uri.path == '/app/creator/youtube-connect') return true;
  if (uri.path != '/app/social') return false;
  final subAction = uri.queryParameters['sub'];
  if (subAction == 'create') return true;
  return subAction == 'feed' && uri.queryParameters.containsKey('action');
}

JourneyAuthenticationPurpose _restoredAuthenticationPurpose(
  String? storedPurpose,
  Uri uri,
) {
  if (uri.path == '/app/creator/youtube-connect' &&
      storedPurpose ==
          JourneyAuthenticationPurpose.youtubeChannelConnection.name) {
    return JourneyAuthenticationPurpose.youtubeChannelConnection;
  }
  if (uri.path == '/app/creator/youtube-connect') {
    return JourneyAuthenticationPurpose.youtubeChannelConnection;
  }
  return JourneyAuthenticationPurpose.general;
}

String _restoredAuthenticationCancelRoute(
  String? storedCancelRoute,
  Uri pendingUri,
  String? lastReadyRoute,
) {
  final storedUri = _localAppUri(storedCancelRoute);
  if (storedUri != null && !_requiresAuthentication(storedUri)) {
    return storedCancelRoute!;
  }
  if (lastReadyRoute != null) return lastReadyRoute;
  if (pendingUri.path == '/app/creator/youtube-connect') {
    return '/app/social?sub=videos';
  }
  if (pendingUri.path == '/app/social' &&
      pendingUri.queryParameters['sub'] == 'feed') {
    final item = pendingUri.queryParameters['item'];
    return item == null
        ? '/app/social?sub=feed'
        : Uri(
            path: '/app/social',
            queryParameters: {'sub': 'feed', 'item': item},
          ).toString();
  }
  return '/app/social';
}

String? _canonicalPersistedReadyRoute(String? location) {
  final uri = _localAppUri(location);
  if (uri == null) return null;
  final path = uri.path;

  if (_isChatPath(path)) {
    final returnLocation = uri.queryParameters['return'];
    final returnUri = _localAppUri(returnLocation);
    if (returnUri == null || _isChatPath(returnUri.path)) {
      return '/app/social';
    }
    return _canonicalPersistedReadyRoute(returnLocation) ?? '/app/social';
  }
  if (path.startsWith('/app/buy')) {
    return _canonicalBuyResumeRoute(uri);
  }
  if (path == '/app/social') {
    final subAction = uri.queryParameters['sub'];
    if (const {'shorts', 'videos', 'feed', 'create'}.contains(subAction)) {
      return '/app/social?sub=$subAction';
    }
    return '/app/social';
  }
  if (path == '/app/mool') {
    final origin = uri.queryParameters['from'];
    if (const {
      'social',
      'buy',
      'eat',
      'ride',
      'book',
      'work',
    }.contains(origin)) {
      return '/app/mool?from=$origin';
    }
    return '/app/mool';
  }
  if (path == '/app/eat') return '/app/eat';
  if (const {
        '/app/eat/home',
        '/app/eat/order',
        '/app/eat/basket',
        '/app/eat/review',
      }.contains(path) ||
      path.startsWith('/app/eat/order/')) {
    return '/app/eat/home';
  }
  if (path == '/app/eat/table' || path.startsWith('/app/eat/table/')) {
    return '/app/eat/table';
  }
  if (path == '/app/ride') return '/app/ride';
  if (path == '/app/ride/book') {
    final type = uri.queryParameters['type'];
    if (const {'bike', 'auto', 'cab'}.contains(type)) {
      return '/app/ride/book?type=$type';
    }
    return type == null ? '/app/ride' : '/app/social';
  }
  if (path.startsWith('/app/ride/trip/')) return '/app/ride';
  if (path == '/app/book') return '/app/book';
  if (path == '/app/book/doctor' || path.startsWith('/app/book/doctor/')) {
    return '/app/book/doctor';
  }
  if (path == '/app/book/salon' || path.startsWith('/app/book/salon/')) {
    return '/app/book/salon';
  }
  if (path == '/app/work') return '/app/work';
  if (path == '/app/work/earn' ||
      (path.startsWith('/app/work/opportunity/') &&
          path != '/app/work/opportunity/delivery')) {
    return '/app/work/earn';
  }
  if (path == '/app/work/my-work' ||
      path.startsWith('/app/work/workspace/') ||
      const {
        '/app/work/status',
        '/app/work/ready',
        '/app/work/retailer/setup',
      }.contains(path)) {
    return '/app/work/my-work';
  }
  if (path == '/app/action-unavailable') {
    return switch (uri.queryParameters['reason']) {
      'tiffin' => '/app/eat',
      'get-it-done' => '/app/book',
      'standalone-pay' => '/app/mool',
      'delivery' || 'onboard' || 'verify' => '/app/work',
      _ => '/app/social',
    };
  }
  return '/app/social';
}

bool _isChatPath(String path) =>
    path == '/app/chat' ||
    path == '/app/chat/inbox' ||
    path.startsWith('/app/chat/thread/');

Uri? _localAppUri(String? location) {
  if (location == null || location.isEmpty || location.length > 512) {
    return null;
  }
  final uri = Uri.tryParse(location);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (!uri.path.startsWith('/app/') || uri.pathSegments.contains('..')) {
    return null;
  }
  return uri;
}

String? _canonicalBuyResumeRoute(Uri uri) {
  final path = uri.path;
  final segments = uri.pathSegments;
  final isBuyProduct =
      segments.length == 4 &&
      segments[0] == 'app' &&
      segments[1] == 'buy' &&
      segments[2] == 'product' &&
      segments[3].isNotEmpty;
  final isBuyOrder =
      segments.length >= 4 &&
      segments[0] == 'app' &&
      segments[1] == 'buy' &&
      segments[2] == 'order' &&
      segments[3].isNotEmpty;
  if (path == '/app/buy') {
    final destination = switch (uri.queryParameters['sub'] ??
        uri.queryParameters['scope'] ??
        uri.queryParameters['context']) {
      'wholesale' || 'business' => 'wholesale',
      'medicine' || 'rx' => 'medicine',
      'orders' || 'tracking' => 'orders',
      _ => 'shop',
    };
    return '/app/buy?sub=$destination';
  }
  if (path == '/app/buy/grocery' || isBuyProduct) {
    return '/app/buy?sub=shop';
  }
  if (path == '/app/buy/medicine') {
    return '/app/buy?sub=medicine';
  }
  if (path == '/app/buy/basket' || path == '/app/buy/review') {
    return '/app/buy?view=cart';
  }
  if (isBuyOrder) {
    return '/app/buy?sub=orders';
  }
  return null;
}
