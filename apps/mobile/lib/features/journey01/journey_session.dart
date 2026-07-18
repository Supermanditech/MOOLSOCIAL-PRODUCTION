import 'package:flutter/foundation.dart';

enum JourneyStage { booting, setup, signIn, verify, ready }

enum AreaChoice { current, manual, skipped }

class JourneySession extends ChangeNotifier {
  JourneySession({
    this.stage = JourneyStage.booting,
    this.developmentOtp = '123456',
  });

  factory JourneySession.development() => JourneySession();

  JourneyStage stage;
  final String developmentOtp;

  String languageCode = 'en';
  AreaChoice? areaChoice;
  String? manualArea;
  String? phoneNumber;
  String? errorMessage;
  String? returnTo;

  bool get isReady => stage == JourneyStage.ready;

  void completeBoot() {
    if (stage != JourneyStage.booting) return;
    stage = JourneyStage.setup;
    notifyListeners();
  }

  void selectLanguage(String value) {
    languageCode = value;
    notifyListeners();
  }

  void selectArea(AreaChoice value, {String? label}) {
    areaChoice = value;
    manualArea = label;
    errorMessage = null;
    notifyListeners();
  }

  bool completeSetup() {
    if (areaChoice == null) {
      errorMessage = 'Choose an area option to continue.';
      notifyListeners();
      return false;
    }
    stage = JourneyStage.signIn;
    errorMessage = null;
    notifyListeners();
    return true;
  }

  bool requestOtp(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      errorMessage = 'Enter a valid 10-digit mobile number.';
      notifyListeners();
      return false;
    }
    phoneNumber = digits;
    stage = JourneyStage.verify;
    errorMessage = null;
    notifyListeners();
    return true;
  }

  bool verifyOtp(String value) {
    if (value != developmentOtp) {
      errorMessage = 'That code is not valid. Check it and try again.';
      notifyListeners();
      return false;
    }
    stage = JourneyStage.ready;
    errorMessage = null;
    notifyListeners();
    return true;
  }

  void changeSignInMethod() {
    stage = JourneyStage.signIn;
    errorMessage = null;
    notifyListeners();
  }

  void captureReturnTo(String location) {
    if (returnTo == null && location.startsWith('/app/')) {
      returnTo = location;
    }
  }

  String consumeReturnTo() {
    final route = returnTo ?? '/app/social';
    returnTo = null;
    return route;
  }
}
