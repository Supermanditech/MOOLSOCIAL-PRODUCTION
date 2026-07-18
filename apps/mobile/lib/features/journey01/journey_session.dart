import 'package:flutter/foundation.dart';

import 'journey_services.dart';

enum JourneyStage { booting, bootFailure, setup, signIn, verify, ready }

enum AreaChoice { current, manual, skipped }

class JourneySession extends ChangeNotifier {
  JourneySession({
    JourneyStore? store,
    OtpGateway? otpGateway,
    AccountBootstrapGateway? accountBootstrapGateway,
    LocationPermissionGateway? locationGateway,
    DateTime Function()? now,
    this.otpValidity = const Duration(minutes: 2),
    this.resendCooldown = const Duration(seconds: 30),
  }) : _store = store ?? MemoryJourneyStore(),
       _otpGateway = otpGateway ?? ReviewOtpGateway(),
       _accountBootstrapGateway =
           accountBootstrapGateway ?? ReviewAccountBootstrapGateway(),
       _locationGateway = locationGateway ?? ReviewLocationPermissionGateway(),
       _now = now ?? DateTime.now;

  final JourneyStore _store;
  final OtpGateway _otpGateway;
  final AccountBootstrapGateway _accountBootstrapGateway;
  final LocationPermissionGateway _locationGateway;
  final DateTime Function() _now;
  final Duration otpValidity;
  final Duration resendCooldown;

  JourneyStage stage = JourneyStage.booting;
  String languageCode = 'en';
  AreaChoice? areaChoice;
  String? manualArea;
  String? phoneNumber;
  String? errorMessage;
  String? noticeMessage;
  String? reviewCode;
  String? returnTo;
  String previousPrimarySection = 'social';
  DateTime? otpExpiresAt;
  DateTime? resendAvailableAt;
  bool busy = false;

  bool _started = false;
  bool _authenticationCompletionInProgress = false;

  bool get isReady => stage == JourneyStage.ready;

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

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _setBusy(true);
    errorMessage = null;

    try {
      final capturedRoute = returnTo;
      final snapshot = await _store.read();
      if (snapshot != null) {
        languageCode = snapshot.languageCode;
        areaChoice = _areaChoiceFromStorage(snapshot.areaMode);
        manualArea = snapshot.areaLabel;
        returnTo = capturedRoute ?? snapshot.pendingRoute;
      }

      final signedIn = await _otpGateway.hasAuthenticatedUser();
      if (signedIn) {
        await _accountBootstrapGateway.prepareAuthenticatedAccount();
        stage = JourneyStage.ready;
      } else if (snapshot?.setupComplete ?? false) {
        stage = JourneyStage.signIn;
      } else {
        stage = JourneyStage.setup;
      }
      noticeMessage = null;
    } on Object {
      stage = JourneyStage.bootFailure;
      errorMessage =
          'MoolSocial could not restore your setup. Nothing was changed.';
    } finally {
      _setBusy(false);
    }
  }

  Future<void> retryBoot() async {
    _started = false;
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
    try {
      await _persist(setupComplete: true);
      stage = JourneyStage.signIn;
      errorMessage = null;
      noticeMessage = null;
      notifyListeners();
      return true;
    } on Object {
      errorMessage = 'Your setup could not be saved. Please retry.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
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
    return _sendOtp();
  }

  Future<bool> resendOtp() async {
    if (busy) return false;
    if (phoneNumber == null) {
      errorMessage = 'Enter your mobile number and request a code.';
      notifyListeners();
      return false;
    }
    if (!canResend) {
      errorMessage = 'You can request a new code in $resendSeconds seconds.';
      notifyListeners();
      return false;
    }
    return _sendOtp();
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
      await _otpGateway.verifyCode(code);
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
      await _accountBootstrapGateway.prepareAuthenticatedAccount();
      await _persist(setupComplete: true);
      stage = JourneyStage.ready;
      errorMessage = null;
      noticeMessage = null;
      reviewCode = null;
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
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (busy) return;
    _setBusy(true);
    try {
      await _otpGateway.signOut();
      stage = JourneyStage.signIn;
      phoneNumber = null;
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
      _persist(setupComplete: areaChoice != null);
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
        setupComplete: setupComplete,
        pendingRoute: returnTo,
      ),
    );
  }

  bool _isValidIndianMobile(String digits) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(digits);
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
}
