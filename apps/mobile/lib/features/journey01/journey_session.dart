import 'package:flutter/foundation.dart';

import 'journey_services.dart';

enum JourneyStage { booting, bootFailure, setup, signIn, verify, ready }

enum AreaChoice { current, manual, skipped }

enum SocialAuthState { idle, pending, cancelled, failed }

class JourneySession extends ChangeNotifier {
  JourneySession({
    JourneyStore? store,
    OtpGateway? otpGateway,
    EmailOtpGateway? emailOtpGateway,
    SocialAuthGateway? socialAuthGateway,
    AccountBootstrapGateway? accountBootstrapGateway,
    LocationPermissionGateway? locationGateway,
    CurrentAreaGateway? currentAreaGateway,
    DateTime Function()? now,
    this.otpValidity = const Duration(minutes: 2),
    this.resendCooldown = const Duration(seconds: 30),
    this.accountBootstrapTimeout = const Duration(seconds: 8),
  }) : _store = store ?? MemoryJourneyStore(),
       _otpGateway = otpGateway ?? ReviewOtpGateway(),
       _emailOtpGateway = emailOtpGateway ?? ReviewEmailOtpGateway(),
       _socialAuthGateway = socialAuthGateway ?? ReviewSocialAuthGateway(),
       _accountBootstrapGateway =
           accountBootstrapGateway ?? ReviewAccountBootstrapGateway(),
       _locationGateway = locationGateway ?? ReviewLocationPermissionGateway(),
       _currentAreaGateway = currentAreaGateway ?? ReviewCurrentAreaGateway(),
       _now = now ?? DateTime.now;

  final JourneyStore _store;
  final OtpGateway _otpGateway;
  final EmailOtpGateway _emailOtpGateway;
  final SocialAuthGateway _socialAuthGateway;
  final AccountBootstrapGateway _accountBootstrapGateway;
  final LocationPermissionGateway _locationGateway;
  final CurrentAreaGateway _currentAreaGateway;
  final DateTime Function() _now;
  final Duration otpValidity;
  final Duration resendCooldown;
  final Duration accountBootstrapTimeout;

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
  String? errorMessage;
  String? noticeMessage;
  String? reviewCode;
  String? returnTo;
  String previousPrimarySection = 'social';
  DateTime? otpExpiresAt;
  DateTime? resendAvailableAt;
  bool busy = false;
  bool resolvingCurrentArea = false;

  bool _started = false;
  bool _storeRestored = false;
  bool _authenticatedAtBoot = false;
  bool _authenticationCompletionInProgress = false;
  int _completedSetupExperienceVersion = 0;

  bool get isReady => stage == JourneyStage.ready;
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

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _completedSetupExperienceVersion = 0;
    _setBusy(true);
    errorMessage = null;

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
      }
      _storeRestored = true;

      final signedIn =
          await _otpGateway.hasAuthenticatedUser() ||
          await _socialAuthGateway.hasAuthenticatedUser();
      final requiresApprovedSetup =
          snapshot == null ||
          _completedSetupExperienceVersion < approvedSetupExperienceVersion;
      if (requiresApprovedSetup) {
        _authenticatedAtBoot = signedIn;
        stage = JourneyStage.setup;
      } else if (signedIn) {
        await _prepareAuthenticatedAccount();
        stage = JourneyStage.ready;
      } else if (snapshot.setupComplete) {
        stage = JourneyStage.signIn;
      } else {
        stage = JourneyStage.setup;
      }
      if (returnTo != null && returnTo != snapshot?.pendingRoute) {
        await _persist(
          setupComplete: snapshot?.setupComplete ?? areaChoice != null,
        );
      }
      if (kDebugMode) {
        debugPrint(
          'MOOLSOCIAL_STARTUP '
          'stage=${stage.name} '
          'snapshot=${snapshot != null} '
          'setupComplete=${snapshot?.setupComplete ?? false} '
          'completedSetupVersion=$_completedSetupExperienceVersion '
          'requiredSetupVersion=$approvedSetupExperienceVersion '
          'authenticated=$signedIn',
        );
      }
      noticeMessage = null;
    } on Object {
      stage = JourneyStage.bootFailure;
      if (kDebugMode) {
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
        await _prepareAuthenticatedAccount();
        stage = JourneyStage.ready;
      } else {
        stage = JourneyStage.signIn;
      }
      errorMessage = null;
      noticeMessage = null;
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
    socialAuthProvider = provider;
    socialAuthState = SocialAuthState.pending;
    errorMessage = null;
    noticeMessage = null;
    _setBusy(true);
    try {
      final result = await _socialAuthGateway.signIn(provider);
      if (result.outcome == SocialAuthOutcome.cancelled) {
        socialAuthState = SocialAuthState.cancelled;
        errorMessage =
            '${_socialProviderLabel(provider)} sign-in was cancelled. '
            'Try again or choose another method.';
        notifyListeners();
        return false;
      }
      await _completeAuthentication();
      return true;
    } on JourneyServiceException catch (error) {
      socialAuthState = SocialAuthState.failed;
      errorMessage = error.userMessage;
      notifyListeners();
      return false;
    } on Object {
      socialAuthState = SocialAuthState.failed;
      errorMessage =
          '${_socialProviderLabel(provider)} sign-in could not be completed. '
          'Check the connection and try again.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void clearSocialAuthResult() {
    socialAuthProvider = null;
    socialAuthState = SocialAuthState.idle;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  Future<bool> requestOtp(String value) async {
    if (busy) return false;
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
        await _completeAuthentication();
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
      await _completeAuthentication();
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

  Future<void> _completeAuthentication() async {
    if (stage == JourneyStage.ready || _authenticationCompletionInProgress) {
      return;
    }
    _authenticationCompletionInProgress = true;
    try {
      await _prepareAuthenticatedAccount();
      await _persist(setupComplete: true);
      stage = JourneyStage.ready;
      errorMessage = null;
      noticeMessage = null;
      reviewCode = null;
      socialAuthProvider = null;
      socialAuthState = SocialAuthState.idle;
      notifyListeners();
    } finally {
      _authenticationCompletionInProgress = false;
    }
  }

  void changeSignInMethod() {
    stage = JourneyStage.signIn;
    otpExpiresAt = null;
    resendAvailableAt = null;
    reviewCode = null;
    otpChannel = null;
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (busy) return;
    _setBusy(true);
    try {
      await _otpGateway.signOut();
      await _socialAuthGateway.signOut();
      stage = JourneyStage.signIn;
      phoneNumber = null;
      emailAddress = null;
      otpChannel = null;
      socialAuthProvider = null;
      socialAuthState = SocialAuthState.idle;
      errorMessage = null;
      noticeMessage =
          'You are signed out. Your language and area are retained.';
      await _persist(setupComplete: true);
      notifyListeners();
    } finally {
      _setBusy(false);
    }
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
      await _store.write(
        JourneySnapshot(
          languageCode: snapshot.languageCode,
          areaMode: snapshot.areaMode,
          areaLabel: snapshot.areaLabel,
          currentAreaLabel: snapshot.currentAreaLabel,
          homeOrWorkAreaLabel: snapshot.homeOrWorkAreaLabel,
          setupComplete: snapshot.setupComplete,
          pendingRoute: location,
          setupExperienceVersion: snapshot.setupExperienceVersion,
        ),
      );
    } on Object {
      // Startup still retains the route in memory and owns visible recovery.
    }
  }

  String readyRoute() => returnTo ?? '/app/social';

  void confirmReadyRoute(String location) {
    if (returnTo == location) {
      returnTo = null;
      _persist(setupComplete: true);
    }
  }

  void openMoolFrom(String section) {
    if (section != 'mool') previousPrimarySection = section;
  }

  String closeMoolRoute() => '/app/$previousPrimarySection';

  Future<void> _persist({required bool setupComplete}) {
    return _store.write(
      JourneySnapshot(
        languageCode: languageCode,
        areaMode: areaChoice?.name,
        areaLabel: manualArea,
        currentAreaLabel: currentAreaLabel,
        homeOrWorkAreaLabel: homeOrWorkArea,
        setupComplete: setupComplete,
        pendingRoute: returnTo,
        setupExperienceVersion: _completedSetupExperienceVersion,
      ),
    );
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

  Future<void> _prepareAuthenticatedAccount() {
    return _accountBootstrapGateway.prepareAuthenticatedAccount().timeout(
      accountBootstrapTimeout,
      onTimeout: () => throw const JourneyServiceException(
        'Your account service did not respond. Check the connection and try again.',
      ),
    );
  }
}
