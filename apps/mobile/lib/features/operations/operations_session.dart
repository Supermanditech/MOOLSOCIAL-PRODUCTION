import 'package:flutter/foundation.dart';

import 'operations_services.dart';

enum EarnOpportunityFilter {
  bestMatch,
  onboarding,
  campaign,
  verification,
  delivery,
}

enum EarnApplicationTab { applied, saved, eligibility }

enum EarnHistoryTab { history, issues, growth }

enum ProviderCatalogueTab { live, draft, paused, needsUpdate }

enum ProviderRequestTab { newRequests, accepted, completed }

enum ProviderBusinessTab { payments, customers, receipts, refunds }

enum ProviderGrowthTab { bestMatch, earn, promote, nearby }

class EarnOpportunity {
  const EarnOpportunity({
    required this.id,
    required this.title,
    required this.source,
    required this.capacity,
    required this.payout,
    required this.place,
    required this.proof,
  });

  final String id;
  final String title;
  final String source;
  final String capacity;
  final String payout;
  final String place;
  final String proof;
}

const reviewEarnOpportunities = <EarnOpportunity>[
  EarnOpportunity(
    id: 'retailer',
    title: 'Onboard verified grocery retailers',
    source: 'MOOLSOCIAL FUNDED · 96% MATCH',
    capacity: '118 seats',
    payout: '₹450 / approved',
    place: 'Jodhpur',
    proof: 'KYC + activation',
  ),
  EarnOpportunity(
    id: 'qr',
    title: 'Verify shop display and QR placement',
    source: 'MANUFACTURER CAMPAIGN · FUNDED',
    capacity: '64 seats',
    payout: '₹220 / shop',
    place: '25 minutes',
    proof: 'GPS + photo',
  ),
  EarnOpportunity(
    id: 'catalog',
    title: 'Validate FMCG catalogue data',
    source: 'REMOTE · 91% MATCH',
    capacity: '240 units',
    payout: '₹18 / approved SKU',
    place: 'Remote',
    proof: 'Source match',
  ),
];

class OperationsSession extends ChangeNotifier {
  OperationsSession({ReviewOperationsGateway? gateway})
    : gateway = gateway ?? ReviewOperationsGateway();

  final ReviewOperationsGateway gateway;

  bool busy = false;
  bool online = true;
  bool authorized = true;
  String? errorMessage;
  String? noticeMessage;

  EarnOpportunityFilter opportunityFilter = EarnOpportunityFilter.bestMatch;
  String? selectedOpportunityId;
  bool opportunityTermsAccepted = false;
  String? applicationId;
  EarnApplicationTab applicationTab = EarnApplicationTab.applied;
  String? selectedApplication;
  String? workStartId;
  String supportCategory = 'Business unavailable';
  String supportDetails = '';
  String? earnSupportId;
  final Set<String> capturedProof = <String>{
    'owner-otp',
    'shop-photo',
    'qr-test',
    'owner-confirmed',
  };
  bool outcomeTruthConfirmed = false;
  String? outcomeId;
  String? statementId;
  EarnHistoryTab historyTab = EarnHistoryTab.history;
  String? selectedWorkRecord;

  ProviderCatalogueTab catalogueTab = ProviderCatalogueTab.live;
  String serviceName = '';
  String servicePrice = '';
  String serviceTime = '';
  String serviceScope = '';
  bool serviceConsumerVisible = true;
  String? serviceId;

  bool acceptNewDemand = true;
  String selectedDay = 'Monday';
  String serviceMode = 'Within 8 km';
  String pauseDuration = '30 minutes';
  bool pauseConfirmed = false;
  String? availabilityId;

  ProviderRequestTab requestTab = ProviderRequestTab.newRequests;
  String? selectedRequestId;
  bool requestTermsConfirmed = false;
  String declineReason = '';
  String? requestAcceptanceId;
  String? requestDeclineId;

  int fulfilmentStep = 3;
  bool arrivalConfirmed = false;
  bool outcomeCompleted = false;
  String? fulfilmentId;

  ProviderBusinessTab businessTab = ProviderBusinessTab.payments;
  String exportType = 'Statement';
  String? exportId;
  String? selectedBusinessRecord;

  ProviderGrowthTab growthTab = ProviderGrowthTab.bestMatch;
  String? selectedGrowthId;
  bool growthTermsAccepted = false;
  String? growthAcceptanceId;

  bool priorityAlerts = true;
  bool autoPauseAtCapacity = true;
  bool customerReminders = false;
  String? selectedControlId;
  String? controlsVersionId;
  String providerSupportCategory = 'Access and staff';
  String providerSupportDetails = '';
  String? providerSupportId;

  EarnOpportunity get selectedOpportunity => reviewEarnOpportunities.firstWhere(
    (item) => item.id == (selectedOpportunityId ?? 'retailer'),
  );

  void clearMessages() {
    errorMessage = null;
    noticeMessage = null;
  }

  void dismissMessages() {
    clearMessages();
    notifyListeners();
  }

  void setOnline(bool value) {
    online = value;
    clearMessages();
    notifyListeners();
  }

  void setOpportunityFilter(EarnOpportunityFilter value) {
    opportunityFilter = value;
    clearMessages();
    notifyListeners();
  }

  void selectOpportunity(String id) {
    selectedOpportunityId = id;
    opportunityTermsAccepted = false;
    clearMessages();
    notifyListeners();
  }

  void confirmOpportunityTerms(bool value) {
    opportunityTermsAccepted = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> applyOpportunity() async {
    if (applicationId != null) {
      noticeMessage = 'Application already sent. Open My Work to continue.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (!opportunityTermsAccepted) {
      errorMessage = 'Review and accept the work, proof and payout terms.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _protected(
      operation: gateway.apply,
      onSuccess: () {
        applicationId = 'EARN-APP-133-${selectedOpportunity.id}';
        noticeMessage =
            'Application sent. Eligibility and funded capacity are being checked.';
      },
    );
  }

  void setApplicationTab(EarnApplicationTab value) {
    applicationTab = value;
    clearMessages();
    notifyListeners();
  }

  void selectApplication(String id) {
    selectedApplication = id;
    clearMessages();
    notifyListeners();
  }

  Future<bool> startApprovedWork() async {
    if (workStartId != null) {
      noticeMessage = 'Work is already active.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (selectedApplication != 'approved') {
      errorMessage = 'Only an approved, reserved assignment can start.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _protected(
      operation: gateway.startWork,
      onSuccess: () {
        workStartId = 'WRK-4821';
        noticeMessage =
            'Work started. Your reserved output and proof are ready.';
      },
    );
  }

  void selectSupportCategory(String value) {
    supportCategory = value;
    clearMessages();
    notifyListeners();
  }

  void updateSupportDetails(String value) {
    supportDetails = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> openEarnSupport() async {
    if (earnSupportId != null) {
      noticeMessage = 'Support case $earnSupportId is already open.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (supportDetails.trim().length < 12) {
      errorMessage = 'Describe what happened in at least 12 characters.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _protected(
      operation: gateway.openEarnSupport,
      onSuccess: () {
        earnSupportId = 'EARN-CASE-135-4821';
        noticeMessage = 'Support case opened. Updates will arrive in Chat.';
      },
    );
  }

  void toggleProof(String id) {
    if (!capturedProof.add(id)) capturedProof.remove(id);
    outcomeTruthConfirmed = false;
    clearMessages();
    notifyListeners();
  }

  void confirmOutcomeTruth(bool value) {
    outcomeTruthConfirmed = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> submitOutcome() async {
    if (outcomeId != null) {
      noticeMessage = 'Outcome is already under verification.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (capturedProof.length < 4 || !outcomeTruthConfirmed) {
      errorMessage = 'Complete all four proof items and confirm the outcome.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _protected(
      operation: gateway.submitOutcome,
      onSuccess: () {
        outcomeId = 'EARN-OUTCOME-136-4821';
        noticeMessage = 'Outcome submitted. Verification target is 24 hours.';
      },
    );
  }

  Future<bool> prepareStatement() async {
    if (statementId != null) {
      noticeMessage = 'Statement is already ready.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    return _protected(
      operation: gateway.prepareStatement,
      onSuccess: () {
        statementId = 'EARN-STMT-137-0719';
        noticeMessage = 'Statement ready in PDF and CSV.';
      },
    );
  }

  void setHistoryTab(EarnHistoryTab value) {
    historyTab = value;
    clearMessages();
    notifyListeners();
  }

  void selectWorkRecord(String id) {
    selectedWorkRecord = id;
    clearMessages();
    notifyListeners();
  }

  void setCatalogueTab(ProviderCatalogueTab value) {
    catalogueTab = value;
    clearMessages();
    notifyListeners();
  }

  void beginService({String? name}) {
    serviceName = name ?? '';
    servicePrice = name == null ? '' : '499';
    serviceTime = name == null ? '' : '45';
    serviceScope = name == null
        ? ''
        : 'Defined visit, completion confirmation and receipt.';
    serviceId = null;
    clearMessages();
    notifyListeners();
  }

  void setServiceConsumerVisible(bool value) {
    serviceConsumerVisible = value;
    serviceId = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> saveService() async {
    if (serviceId != null) {
      noticeMessage = 'Service is already saved.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    final price = int.tryParse(servicePrice);
    final time = int.tryParse(serviceTime);
    if (serviceName.trim().length < 3 ||
        price == null ||
        price <= 0 ||
        time == null ||
        time <= 0 ||
        serviceScope.trim().length < 12) {
      errorMessage = 'Add a name, valid price, time and clear customer scope.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _protected(
      operation: gateway.saveService,
      onSuccess: () {
        serviceId = 'PROV-SVC-140-0719';
        noticeMessage = serviceConsumerVisible
            ? 'Service saved and ready for customer review.'
            : 'Service saved as a draft.';
      },
    );
  }

  void toggleNewDemand(bool value) {
    acceptNewDemand = value;
    pauseConfirmed = false;
    clearMessages();
    notifyListeners();
  }

  void setPauseDuration(String value) {
    pauseDuration = value;
    clearMessages();
    notifyListeners();
  }

  void confirmPause(bool value) {
    pauseConfirmed = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> saveAvailability() async {
    if (availabilityId != null) {
      noticeMessage = 'Availability is already up to date.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (!acceptNewDemand && !pauseConfirmed) {
      errorMessage = 'Confirm how long new demand should pause.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _protected(
      operation: gateway.saveAvailability,
      onSuccess: () {
        availabilityId = 'PROV-CAP-141-0719';
        noticeMessage = acceptNewDemand
            ? 'Availability saved. Customers can request open capacity.'
            : 'New demand paused for $pauseDuration. Accepted work stays active.';
      },
    );
  }

  void setRequestTab(ProviderRequestTab value) {
    requestTab = value;
    clearMessages();
    notifyListeners();
  }

  void selectRequest(String id) {
    selectedRequestId = id;
    requestTermsConfirmed = false;
    requestAcceptanceId = null;
    requestDeclineId = null;
    clearMessages();
    notifyListeners();
  }

  void confirmRequestTerms(bool value) {
    requestTermsConfirmed = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> acceptRequest() async {
    if (requestAcceptanceId != null) {
      noticeMessage = 'Request is already accepted.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (selectedRequestId == null || !requestTermsConfirmed) {
      errorMessage = 'Review the price, time, scope and cancellation first.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _protected(
      operation: gateway.acceptRequest,
      onSuccess: () {
        requestAcceptanceId = 'PROV-ACCEPT-142-$selectedRequestId';
        noticeMessage = 'Request accepted. Capacity is reserved.';
      },
    );
  }

  Future<bool> declineRequest() async {
    if (requestDeclineId != null) {
      noticeMessage = 'Response is already sent.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (selectedRequestId == null || declineReason.trim().length < 5) {
      errorMessage = 'Choose the request and give the customer a clear reason.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _protected(
      operation: gateway.declineRequest,
      onSuccess: () {
        requestDeclineId = 'PROV-DECLINE-142-$selectedRequestId';
        noticeMessage = 'Customer notified. No capacity was reserved.';
      },
    );
  }

  void confirmArrival(bool value) {
    arrivalConfirmed = value;
    clearMessages();
    notifyListeners();
  }

  void confirmFulfilmentOutcome(bool value) {
    outcomeCompleted = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> completeFulfilment() async {
    if (fulfilmentId != null) {
      noticeMessage = 'Outcome is already complete.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (!arrivalConfirmed || !outcomeCompleted) {
      errorMessage = 'Confirm arrival and the completed customer outcome.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _protected(
      operation: gateway.completeFulfilment,
      onSuccess: () {
        fulfilmentStep = 5;
        fulfilmentId = 'PROV-DONE-143-2401';
        noticeMessage = 'Outcome completed. ₹850 moved to settlement review.';
      },
    );
  }

  void setBusinessTab(ProviderBusinessTab value) {
    businessTab = value;
    clearMessages();
    notifyListeners();
  }

  void setExportType(String value) {
    exportType = value;
    exportId = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> exportRecords() async {
    if (exportId != null) {
      noticeMessage = '$exportType file is already ready.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    return _protected(
      operation: gateway.exportRecords,
      onSuccess: () {
        exportId = 'PROV-EXPORT-144-${exportType.toUpperCase()}';
        noticeMessage = '$exportType file is ready.';
      },
    );
  }

  void setGrowthTab(ProviderGrowthTab value) {
    growthTab = value;
    clearMessages();
    notifyListeners();
  }

  void selectGrowth(String id) {
    selectedGrowthId = id;
    growthTermsAccepted = false;
    growthAcceptanceId = null;
    clearMessages();
    notifyListeners();
  }

  void confirmGrowthTerms(bool value) {
    growthTermsAccepted = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> acceptGrowth() async {
    if (growthAcceptanceId != null) {
      noticeMessage = selectedGrowthId == 'campaign'
          ? 'Your growth campaign request is already submitted.'
          : 'This funded work is already accepted.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (selectedGrowthId == null || !growthTermsAccepted) {
      errorMessage = selectedGrowthId == 'campaign'
          ? 'Review the outcome, budget and charging terms.'
          : 'Review the funded outcome and payout terms.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _protected(
      operation: gateway.acceptGrowth,
      onSuccess: () {
        growthAcceptanceId = 'PROV-GROW-145-$selectedGrowthId';
        noticeMessage = selectedGrowthId == 'campaign'
            ? 'Growth campaign submitted. No charge is made until final confirmation.'
            : 'Funded work accepted. Capacity and payout terms are reserved.';
      },
    );
  }

  void toggleControl(String id) {
    switch (id) {
      case 'alerts':
        priorityAlerts = !priorityAlerts;
        break;
      case 'capacity':
        autoPauseAtCapacity = !autoPauseAtCapacity;
        break;
      case 'reminders':
        customerReminders = !customerReminders;
        break;
    }
    controlsVersionId = null;
    clearMessages();
    notifyListeners();
  }

  void selectControl(String id) {
    selectedControlId = id;
    clearMessages();
    notifyListeners();
  }

  Future<bool> saveControls() async {
    if (controlsVersionId != null) {
      noticeMessage = 'Workspace controls are already up to date.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    return _protected(
      operation: gateway.saveControls,
      onSuccess: () {
        controlsVersionId = 'PROV-CONTROL-146-0719';
        noticeMessage = 'Workspace controls saved together.';
      },
    );
  }

  void updateProviderSupportDetails(String value) {
    providerSupportDetails = value;
    clearMessages();
    notifyListeners();
  }

  void setProviderSupportCategory(String value) {
    providerSupportCategory = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> openProviderSupport() async {
    if (providerSupportId != null) {
      noticeMessage = 'Support case $providerSupportId is already open.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    if (providerSupportDetails.trim().length < 12) {
      errorMessage =
          'Describe what needs to be checked in at least 12 characters.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _protected(
      operation: gateway.openProviderSupport,
      onSuccess: () {
        providerSupportId = 'SUP-146-2048';
        noticeMessage =
            'Support case opened. Workspace Support will reply in Chat.';
      },
    );
  }

  Future<bool> _protected({
    required Future<void> Function() operation,
    required VoidCallback onSuccess,
  }) async {
    if (busy) return false;
    if (!online) {
      errorMessage = 'You are offline. Reconnect and try the same action.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (!authorized) {
      errorMessage = 'This account does not have permission for that action.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      await operation();
      onSuccess();
      return true;
    } on OperationsGatewayException catch (error) {
      errorMessage = error.message;
      noticeMessage = null;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
