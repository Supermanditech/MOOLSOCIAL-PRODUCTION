import 'package:flutter/foundation.dart';

import 'captain_models.dart';
import 'captain_services.dart';

class CaptainSession extends ChangeNotifier {
  CaptainSession({ReviewCaptainGateway? gateway})
    : gateway = gateway ?? ReviewCaptainGateway();

  final ReviewCaptainGateway gateway;

  bool online = true;
  bool authorized = true;
  bool busy = false;
  String? errorMessage;
  String? noticeMessage;

  bool availableForRides = false;
  bool requestsPaused = false;
  CaptainRequestDecision requestDecision = CaptainRequestDecision.none;
  String? assignmentId;
  String? declineId;

  CaptainTripState tripState = CaptainTripState.available;
  bool pickupGeofenceFresh = true;
  bool destinationGeofenceFresh = true;
  bool captainArrivedAtPickup = false;
  String pickupOtp = '';
  String? tripStartId;
  String? arrivalId;
  String? paymentReceiptId;
  String selectedTripOption = 'options';

  CaptainEarningsTab earningsTab = CaptainEarningsTab.today;
  String? selectedEarningId;

  String selectedDocumentId = 'insurance';
  bool verificationConsent = false;
  String? verificationId;

  CaptainSupportTab supportTab = CaptainSupportTab.support;
  String selectedSupportId = 'trip';
  String supportMessage =
      'Please review the trip record and help resolve this issue.';
  String? supportCaseId;
  String selectedWorkId = 'captain-onboarding';
  bool workTermsAccepted = false;
  String? workApplicationId;

  CaptainDocument get selectedDocument => reviewCaptainDocuments.firstWhere(
    (item) => item.id == selectedDocumentId,
  );

  CaptainSupportOption get selectedSupport =>
      reviewCaptainSupport.firstWhere((item) => item.id == selectedSupportId);

  CaptainPaidWork get selectedWork =>
      reviewCaptainPaidWork.firstWhere((item) => item.id == selectedWorkId);

  String get currentTripRoute => switch (tripState) {
    CaptainTripState.live => '/app/captain/trips/${reviewCaptainRide.id}',
    CaptainTripState.paymentPending || CaptainTripState.completed =>
      '/app/captain/trips/${reviewCaptainRide.id}/complete',
    _ => '/app/captain/trips/${reviewCaptainRide.id}/pickup',
  };

  void clearMessages() {
    errorMessage = null;
    noticeMessage = null;
  }

  void showNotice(String message) {
    errorMessage = null;
    noticeMessage = message;
    notifyListeners();
  }

  void setOnline(bool value) {
    online = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> toggleAvailability() async {
    final target = !availableForRides;
    return _protected(
      operation: () => gateway.setAvailability(target),
      success: () {
        availableForRides = target;
        if (!target) requestsPaused = false;
        noticeMessage = target
            ? 'You are online. Eligible ride requests can now reach you.'
            : 'You are offline. Location sharing for new ride requests is stopped.';
      },
    );
  }

  void setRequestsPaused(bool value) {
    requestsPaused = value;
    noticeMessage = value
        ? 'New ride requests are paused.'
        : 'New ride requests are active.';
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> acceptRide() async {
    if (assignmentId != null) {
      noticeMessage =
          '$assignmentId is already assigned. The ride was not accepted twice.';
      notifyListeners();
      return true;
    }
    if (!availableForRides || requestsPaused) {
      return _validation('Go online and resume requests before accepting.');
    }
    return _protected(
      operation: gateway.acceptRide,
      success: () {
        requestDecision = CaptainRequestDecision.accepted;
        assignmentId = 'CAP-ASG-117-4821';
        tripState = CaptainTripState.pickup;
        noticeMessage =
            'Ride ${reviewCaptainRide.id} accepted once. Navigate to the pickup now.';
      },
    );
  }

  Future<bool> declineRide() async {
    if (declineId != null) {
      noticeMessage =
          '$declineId is already recorded. The request was not declined twice.';
      notifyListeners();
      return true;
    }
    return _protected(
      operation: gateway.declineRide,
      success: () {
        requestDecision = CaptainRequestDecision.declined;
        declineId = 'CAP-DEC-117-4821';
        noticeMessage = 'Ride declined. No trip assignment was created.';
      },
    );
  }

  void markPickupArrival() {
    if (!pickupGeofenceFresh) {
      _validation(
        'Refresh location at the pickup before asking the rider for OTP.',
      );
      return;
    }
    captainArrivedAtPickup = true;
    noticeMessage = 'Pickup reached. Ask the rider for the 4-digit trip OTP.';
    errorMessage = null;
    notifyListeners();
  }

  void setPickupOtp(String value) {
    pickupOtp = value.replaceAll(RegExp(r'[^0-9]'), '');
    clearMessages();
    notifyListeners();
  }

  void setPickupGeofenceFresh(bool value) {
    pickupGeofenceFresh = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> startTrip() async {
    if (tripStartId != null) {
      noticeMessage =
          '$tripStartId is already active. The trip was not started twice.';
      notifyListeners();
      return true;
    }
    if (!captainArrivedAtPickup || !pickupGeofenceFresh) {
      return _validation(
        'Confirm your live pickup location before trip start.',
      );
    }
    if (pickupOtp.length != 4) {
      return _validation('Enter all 4 digits from the rider.');
    }
    if (pickupOtp != '4821') {
      return _validation(
        'That OTP does not match this trip. Ask the rider to check it.',
      );
    }
    return _protected(
      operation: gateway.startTrip,
      success: () {
        tripStartId = 'CAP-START-118-4821';
        tripState = CaptainTripState.live;
        noticeMessage =
            'Trip ${reviewCaptainRide.id} started with pickup location and rider OTP.';
      },
    );
  }

  void setDestinationGeofenceFresh(bool value) {
    destinationGeofenceFresh = value;
    clearMessages();
    notifyListeners();
  }

  void selectTripOption(String value) {
    selectedTripOption = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> confirmDestinationArrival() async {
    if (arrivalId != null) {
      noticeMessage =
          '$arrivalId already confirms destination arrival. Fare was not finalized twice.';
      notifyListeners();
      return true;
    }
    if (tripStartId == null || tripState != CaptainTripState.live) {
      return _validation('Start the trip before confirming destination.');
    }
    if (!destinationGeofenceFresh) {
      return _validation(
        'Refresh live location at the destination before completing the trip.',
      );
    }
    return _protected(
      operation: gateway.confirmArrival,
      success: () {
        arrivalId = 'CAP-ARR-119-4821';
        tripState = CaptainTripState.paymentPending;
        noticeMessage =
            'Destination arrival confirmed. Final fare and payment are ready.';
      },
    );
  }

  Future<bool> checkPayment() async {
    if (paymentReceiptId != null) {
      noticeMessage =
          '$paymentReceiptId already confirms payment. Earnings were not credited twice.';
      notifyListeners();
      return true;
    }
    if (arrivalId == null || tripState != CaptainTripState.paymentPending) {
      return _validation(
        'Confirm destination arrival before checking payment.',
      );
    }
    return _protected(
      operation: gateway.confirmPayment,
      success: () {
        paymentReceiptId = 'CAP-PAY-120-4821';
        tripState = CaptainTripState.completed;
        noticeMessage =
            '₹278 received through UPI. ₹250 is available in Earnings.';
      },
    );
  }

  void setEarningsTab(CaptainEarningsTab value) {
    earningsTab = value;
    clearMessages();
    notifyListeners();
  }

  void selectEarning(String id) {
    selectedEarningId = id;
    final item = reviewCaptainEarnings.firstWhere((entry) => entry.id == id);
    noticeMessage =
        '${item.id}: gross ₹${item.gross}, platform ₹${item.platformCharge}, net ₹${item.net}.';
    errorMessage = null;
    notifyListeners();
  }

  void selectDocument(String id) {
    selectedDocumentId = id;
    verificationConsent = false;
    clearMessages();
    notifyListeners();
  }

  void acceptVerificationConsent(bool value) {
    verificationConsent = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> startDocumentVerification() async {
    if (verificationId != null) {
      noticeMessage =
          '$verificationId is already in progress. No second verification was created.';
      notifyListeners();
      return true;
    }
    if (!verificationConsent) {
      return _validation(
        'Confirm that you will provide the selected document or DigiLocker record.',
      );
    }
    return _protected(
      operation: gateway.startVerification,
      success: () {
        verificationId = 'CAP-VER-122-0719';
        noticeMessage =
            '${selectedDocument.name} submitted for verification. We will notify you before ride eligibility changes.';
      },
    );
  }

  void setSupportTab(CaptainSupportTab value) {
    supportTab = value;
    clearMessages();
    notifyListeners();
  }

  void selectSupport(String id) {
    selectedSupportId = id;
    supportCaseId = null;
    clearMessages();
    notifyListeners();
  }

  void setSupportMessage(String value) {
    supportMessage = value;
    supportCaseId = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> createSupportCase() async {
    if (supportCaseId != null) {
      noticeMessage =
          '$supportCaseId is already open. No duplicate case was created.';
      notifyListeners();
      return true;
    }
    if (supportMessage.trim().length < 12) {
      return _validation('Describe the issue in at least 12 characters.');
    }
    return _protected(
      operation: gateway.createSupportCase,
      success: () {
        supportCaseId = 'CAP-CASE-123-0719';
        noticeMessage =
            '$supportCaseId opened with captain, vehicle and trip records attached.';
      },
    );
  }

  void selectWork(String id) {
    selectedWorkId = id;
    workTermsAccepted = false;
    workApplicationId = null;
    clearMessages();
    notifyListeners();
  }

  void acceptWorkTerms(bool value) {
    workTermsAccepted = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> applyForWork() async {
    if (workApplicationId != null) {
      noticeMessage =
          '$workApplicationId is already submitted. No duplicate application was created.';
      notifyListeners();
      return true;
    }
    if (!workTermsAccepted) {
      return _validation(
        'Review and accept the task, geography, payment and proof terms.',
      );
    }
    return _protected(
      operation: gateway.applyForWork,
      success: () {
        workApplicationId = 'CAP-WORK-123-0719';
        noticeMessage =
            '$workApplicationId submitted. Payment is earned only after approved proof.';
      },
    );
  }

  bool _validation(String message) {
    errorMessage = message;
    noticeMessage = null;
    notifyListeners();
    return false;
  }

  Future<bool> _protected({
    required Future<void> Function() operation,
    required void Function() success,
  }) async {
    if (busy) return false;
    if (!online) {
      return _validation(
        'You are offline. Reconnect and retry the same action.',
      );
    }
    if (!authorized) {
      return _validation(
        'This profile cannot complete that action. Ask the account owner to update your access.',
      );
    }
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      await operation();
      success();
      errorMessage = null;
      return true;
    } on CaptainGatewayException catch (error) {
      errorMessage = error.message;
      noticeMessage = null;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
