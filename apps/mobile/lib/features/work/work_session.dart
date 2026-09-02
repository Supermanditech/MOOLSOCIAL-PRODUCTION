import 'package:flutter/foundation.dart';

import 'work_models.dart';
import 'work_services.dart';

class WorkSession extends ChangeNotifier {
  WorkSession({WorkGateway? gateway, WorkProofPicker? proofPicker})
    : gateway = gateway ?? ReviewWorkGateway(),
      proofPicker = proofPicker ?? ReviewWorkProofPicker();

  WorkSession.production({WorkGateway? gateway, WorkProofPicker? proofPicker})
    : gateway = gateway ?? buildWorkGateway(),
      proofPicker = proofPicker ?? NativeWorkProofPicker();

  final WorkGateway gateway;
  final WorkProofPicker proofPicker;

  bool busy = false;
  String? errorMessage;
  String? noticeMessage;
  WorkFeedFilter filter = WorkFeedFilter.forYou;
  String searchQuery = '';
  String selectedCity = '';
  String selectedArea = '';
  String selectedPincode = '';
  String? expandedOpportunityId;
  WorkOpportunity? selectedOpportunity;
  WorkOpportunity? savedOpportunity;
  String? applicationId;
  String? appliedOpportunityId;
  String? withdrawnApplicationId;
  final Map<String, String> applicationIdsByOpportunity = <String, String>{};
  final Set<String> expandedTerms = <String>{};

  String? selectedFamilyId;
  WorkProfileOption? selectedProfile;
  String accountDisplayName = '';
  String connectedProviderLabel = '';
  String connectedProviderAccount = '';
  String primaryMobile = '';
  bool primaryMobileOtpSent = false;
  bool primaryMobileVerified = false;
  String contactEmail = '';
  bool contactEmailOtpSent = false;
  bool contactEmailVerified = false;
  String alternateMobile = '';
  bool alternateOtpSent = false;
  bool alternateVerified = false;

  String workName = '';
  String workArea = '';
  String primaryActivity = '';
  final Map<String, String> addedProofs = <String, String>{
    'personal-kyc': 'ACCOUNT-KYC',
  };
  bool declarationAccepted = false;
  WorkReviewStage reviewStage = WorkReviewStage.none;
  String? reviewCaseId;
  String? workspaceId;
  String subscriptionPlan = 'free';
  String? reviewReason;
  WorkRemoteReviewStatus? remoteReviewStatus;
  bool reviewCorrectionDraft = false;
  String? _profileSubmissionKey;
  bool gstReminder = false;
  String gstin = '';
  bool gstAttachmentAdded = false;
  String? gstProofReference;
  bool unsupportedRequestSent = false;
  String unsupportedWorkspace = '';
  String unsupportedArea = '';
  String unsupportedFamily = '';
  String unsupportedOtherActivity = '';

  WorkWorkspace? activeWorkspace;
  final List<WorkWorkspace> otherWorkspaces = <WorkWorkspace>[];

  bool retailerProductAdded = false;
  int retailerQuantity = 0;
  int retailerBuyPrice = 0;
  int retailerSellPrice = 0;
  bool retailerHomeDelivery = false;
  bool retailerStoreCollection = false;
  bool retailerSetupSaved = false;
  bool initialWorkspaceStateLoaded = false;
  String workspaceSearchQuery = '';
  bool workspaceAcceptingOrders = true;
  String workspaceFulfilmentMode = 'Delivery and pickup';
  int workspaceBusyMinutes = 0;
  String workspaceReopensAt = '';
  bool workspaceVisibleToCustomers = false;
  String workspaceOrderCustomer = '';
  String workspaceOrderItems = '';
  String workspaceOrderAmount = '';
  bool workspaceOrderNeedsDelivery = false;
  String workspaceOrderSource = 'Counter';
  String workspaceOrderFulfilment = 'At the shop';
  String workspaceOrderPayment = 'Cash';
  String workspaceOrderAddress = '';
  String workspaceOrderStage = 'No order';
  int workspaceOrderExtraMinutes = 0;
  int workspaceSalesToday = 0;
  int workspaceSettlementBalance = 0;
  int workspaceSettlementRequested = 0;
  final List<WorkspaceCatalogueItem> workspaceCatalogueItems = [];
  final Map<String, int> workspaceOrderQuantities = {};
  final List<WorkspaceActivityEntry> workspaceActivity = [];
  final Set<String> dismissedWorkspaceAlerts = <String>{};

  int get workspaceOrderItemCount => workspaceOrderQuantities.values.fold(
    0,
    (total, quantity) => total + quantity,
  );

  int get workspaceOrderTotal =>
      workspaceCatalogueItems.fold(0, (total, product) {
        return total +
            product.sellingPrice * (workspaceOrderQuantities[product.id] ?? 0);
      });

  int get workspaceLowStockCount => workspaceCatalogueItems
      .where((product) => product.available && product.stock <= 5)
      .length;

  int get workspacePublishedProductCount =>
      workspaceCatalogueItems.where((product) => product.published).length;

  bool get hasActiveWorkspaceOrder =>
      workspaceOrderCustomer.isNotEmpty &&
      workspaceOrderStage != 'Completed' &&
      workspaceOrderStage != 'Cancelled';

  List<WorkOpportunity> get filteredOpportunities {
    final normalized = searchQuery.trim().toLowerCase();
    final city = selectedCity.trim().toLowerCase();
    final area = selectedArea.trim().toLowerCase();
    final pincode = selectedPincode.trim();
    final validPincode = RegExp(r'^\d{6}$').hasMatch(pincode);
    return workOpportunities.where((opportunity) {
      final filterMatch =
          filter == WorkFeedFilter.forYou ||
          opportunity.filters.contains(filter);
      final searchMatch =
          normalized.isEmpty ||
          [
            opportunity.title,
            opportunity.publisher,
            opportunity.kind,
            opportunity.location,
            opportunity.requiredWork,
            opportunity.qualificationHeadline,
            opportunity.city,
            opportunity.area,
            opportunity.pincode,
            opportunity.posterType.label,
          ].join(' ').toLowerCase().contains(normalized);
      final cityMatch = city.isEmpty || opportunity.city.toLowerCase() == city;
      final areaMatch = area.isEmpty || opportunity.area.toLowerCase() == area;
      final pincodeMatch =
          pincode.isEmpty ||
          (validPincode && opportunity.pincode == selectedPincode.trim());
      return filterMatch &&
          searchMatch &&
          cityMatch &&
          areaMatch &&
          pincodeMatch;
    }).toList();
  }

  int get activeOpportunityFilterCount => [
    selectedCity,
    selectedArea,
    selectedPincode,
  ].where((value) => value.trim().isNotEmpty).length;

  bool get hasOpportunityLocationFilter =>
      selectedCity.trim().isNotEmpty ||
      selectedArea.trim().isNotEmpty ||
      selectedPincode.trim().isNotEmpty;

  List<WorkOpportunity> get relatedOpportunities {
    if (!hasOpportunityLocationFilter) return const <WorkOpportunity>[];
    final exactIds = filteredOpportunities
        .map((opportunity) => opportunity.id)
        .toSet();
    final normalized = searchQuery.trim().toLowerCase();
    return workOpportunities
        .where((opportunity) {
          if (exactIds.contains(opportunity.id)) return false;
          final filterMatch =
              filter == WorkFeedFilter.forYou ||
              opportunity.filters.contains(filter);
          final searchMatch =
              normalized.isEmpty ||
              [
                opportunity.title,
                opportunity.publisher,
                opportunity.kind,
                opportunity.requiredWork,
                opportunity.qualificationHeadline,
                opportunity.posterType.label,
              ].join(' ').toLowerCase().contains(normalized);
          return filterMatch && searchMatch;
        })
        .take(4)
        .toList(growable: false);
  }

  List<String> get familyIds => workProfiles
      .map((profile) => profile.familyId)
      .toSet()
      .toList(growable: false);

  List<WorkProfileOption> profilesForFamily(String familyId) => workProfiles
      .where((profile) => profile.familyId == familyId)
      .toList(growable: false);

  String familyLabel(String familyId) => workProfiles
      .firstWhere((profile) => profile.familyId == familyId)
      .familyLabel;

  WorkGstMatchCategory? get selectedGstMatchCategory =>
      selectedProfile?.gstMatchCategory;

  WorkDocumentChecklistItem? get selectedGstChecklistItem => selectedProfile
      ?.verificationDocuments
      .where((document) => document.title == 'GST registration certificate')
      .firstOrNull;

  List<WorkProofRequirement> get selectedWorkspaceDocuments {
    final profile = selectedProfile;
    if (profile == null) return workProofs;
    final documents = <WorkProofRequirement>[];
    for (var index = 0; index < profile.verificationDocuments.length; index++) {
      final document = profile.verificationDocuments[index];
      if (document.title == 'GST registration certificate') continue;
      final id = index == 0
          ? 'personal-kyc'
          : document.title == 'Payout bank account proof'
          ? 'payout-bank-account'
          : document.title.toLowerCase().contains('address')
          ? 'shop-front'
          : document.title.toLowerCase().contains('authority') ||
                document.title.toLowerCase().contains('authorised')
          ? 'owner-authority'
          : '${profile.id}-document-$index';
      documents.add(
        WorkProofRequirement(
          id: id,
          label: document.title,
          detail: document.detail,
          importance: document.importance,
        ),
      );
    }
    return List<WorkProofRequirement>.unmodifiable(documents);
  }

  bool get requiredProofsAdded => selectedWorkspaceDocuments
      .where((proof) => proof.required)
      .every((proof) => addedProofs.containsKey(proof.id));

  bool get hasVerifiedWorkspace => activeWorkspace?.verified == true;

  bool get retailerReady =>
      retailerProductAdded &&
      retailerQuantity > 0 &&
      retailerBuyPrice > 0 &&
      retailerSellPrice > retailerBuyPrice &&
      (retailerHomeDelivery || retailerStoreCollection);

  void clearMessages() {
    errorMessage = null;
    noticeMessage = null;
  }

  void dismissMessages() {
    clearMessages();
    notifyListeners();
  }

  void showNotice(String message) {
    errorMessage = null;
    noticeMessage = message;
    notifyListeners();
  }

  void showError(String message) {
    errorMessage = message;
    noticeMessage = null;
    notifyListeners();
  }

  void setFilter(WorkFeedFilter value) {
    filter = value;
    clearMessages();
    notifyListeners();
  }

  void search(String value) {
    searchQuery = value;
    clearMessages();
    notifyListeners();
  }

  void updateWorkspaceSearch(String value) {
    workspaceSearchQuery = value;
    notifyListeners();
  }

  void saveWorkspaceAvailability({
    required bool acceptingOrders,
    required String fulfilmentMode,
    required int busyMinutes,
    required String reopensAt,
  }) {
    workspaceAcceptingOrders = acceptingOrders;
    workspaceFulfilmentMode = fulfilmentMode;
    workspaceBusyMinutes = busyMinutes;
    workspaceReopensAt = acceptingOrders ? '' : reopensAt;
    _recordWorkspaceActivity(
      acceptingOrders
          ? busyMinutes > 0
                ? 'Store marked busy with $busyMinutes minutes extra preparation.'
                : 'Store opened for customer orders.'
          : 'New customer orders paused${reopensAt.isEmpty ? '.' : ' until $reopensAt.'}',
    );
    showNotice(
      acceptingOrders
          ? 'Store availability updated for customers.'
          : 'Store paused. Customers can see when ordering resumes.',
    );
  }

  void dismissWorkspaceAlert(String alertId) {
    dismissedWorkspaceAlerts.add(alertId);
    notifyListeners();
  }

  void setWorkspaceVisibility(bool visible) {
    workspaceVisibleToCustomers = visible;
    _recordWorkspaceActivity(
      visible
          ? 'Store published for customer discovery.'
          : 'Store removed from customer discovery.',
    );
    showNotice(
      visible
          ? 'Your store is now visible to customers.'
          : 'Your store is hidden from customer discovery.',
    );
  }

  void saveWorkspaceOrderDraft({
    required String customer,
    required String source,
    required String fulfilment,
    required String payment,
    required String address,
  }) {
    workspaceOrderCustomer = customer.trim();
    workspaceOrderSource = source;
    workspaceOrderFulfilment = fulfilment;
    workspaceOrderPayment = payment;
    workspaceOrderAddress = address.trim();
    workspaceOrderNeedsDelivery = fulfilment != 'At the shop';
    workspaceOrderItems = workspaceCatalogueItems
        .where((product) => (workspaceOrderQuantities[product.id] ?? 0) > 0)
        .map(
          (product) =>
              '${product.title} × ${workspaceOrderQuantities[product.id]}',
        )
        .join(', ');
    workspaceOrderAmount = '$workspaceOrderTotal';
    workspaceOrderStage = 'Confirmed';
    workspaceOrderExtraMinutes = 0;
    _recordWorkspaceActivity(
      '$source order saved · $workspaceOrderItemCount products · ₹$workspaceOrderTotal.',
    );
    showNotice(
      workspaceOrderNeedsDelivery
          ? 'Order saved. Add the delivery address when the customer confirms.'
          : 'Counter order saved for customer confirmation.',
    );
  }

  void advanceWorkspaceOrder() {
    final previous = workspaceOrderStage;
    workspaceOrderStage = switch (previous) {
      'Confirmed' => 'Preparing',
      'Preparing' => 'Ready',
      'Ready' when workspaceOrderNeedsDelivery => 'Delivery requested',
      'Ready' => 'Completed',
      'Delivery requested' => 'Completed',
      _ => workspaceOrderStage,
    };
    if (workspaceOrderStage == 'Completed' && previous != 'Completed') {
      final amount = int.tryParse(workspaceOrderAmount) ?? 0;
      workspaceSalesToday += amount;
      workspaceSettlementBalance += amount;
    }
    _recordWorkspaceActivity('Order moved to $workspaceOrderStage.');
    showNotice('Order is now ${workspaceOrderStage.toLowerCase()}.');
  }

  void requestWorkspaceSettlement() {
    if (workspaceSettlementBalance <= 0) {
      showError('No completed-sale balance is available for settlement yet.');
      return;
    }
    workspaceSettlementRequested += workspaceSettlementBalance;
    _recordWorkspaceActivity(
      'Settlement requested for ₹$workspaceSettlementBalance.',
    );
    workspaceSettlementBalance = 0;
    showNotice('Settlement request received for processing.');
  }

  void extendWorkspaceOrder(int minutes) {
    workspaceOrderExtraMinutes += minutes;
    _recordWorkspaceActivity(
      'Customer preparation estimate extended by $minutes minutes.',
    );
    showNotice('Customer preparation estimate updated.');
  }

  void cancelWorkspaceOrder() {
    workspaceOrderStage = 'Cancelled';
    _recordWorkspaceActivity('Customer order cancelled.');
    showNotice('Order cancelled. Stock remains available.');
  }

  void startNewWorkspaceOrder() {
    workspaceOrderCustomer = '';
    workspaceOrderItems = '';
    workspaceOrderAmount = '';
    workspaceOrderNeedsDelivery = false;
    workspaceOrderSource = 'Counter';
    workspaceOrderFulfilment = 'At the shop';
    workspaceOrderPayment = 'Cash';
    workspaceOrderAddress = '';
    workspaceOrderStage = 'No order';
    workspaceOrderExtraMinutes = 0;
    workspaceOrderQuantities.clear();
    clearMessages();
    notifyListeners();
  }

  void addOrUpdateWorkspaceProduct(WorkspaceCatalogueItem product) {
    final index = workspaceCatalogueItems.indexWhere(
      (item) => item.id == product.id,
    );
    if (index == -1) {
      workspaceCatalogueItems.add(product);
      _recordWorkspaceActivity('${product.title} added to your catalogue.');
    } else {
      workspaceCatalogueItems[index] = product;
      _recordWorkspaceActivity('${product.title} price and stock updated.');
    }
    retailerProductAdded = workspaceCatalogueItems.isNotEmpty;
    if (workspaceCatalogueItems.isNotEmpty) {
      final first = workspaceCatalogueItems.first;
      retailerQuantity = first.stock;
      retailerBuyPrice = first.purchasePrice;
      retailerSellPrice = first.sellingPrice;
    }
    showNotice(
      product.publicListing
          ? '${product.title} is ready for store publishing.'
          : '${product.title} saved for store use only.',
    );
  }

  void adjustWorkspaceOrderQuantity(String productId, int change) {
    final product = workspaceCatalogueItems
        .where((item) => item.id == productId)
        .firstOrNull;
    if (product == null) return;
    final current = workspaceOrderQuantities[productId] ?? 0;
    final next = (current + change).clamp(0, product.stock);
    if (next == 0) {
      workspaceOrderQuantities.remove(productId);
    } else {
      workspaceOrderQuantities[productId] = next;
    }
    clearMessages();
    notifyListeners();
  }

  void _recordWorkspaceActivity(String message) {
    workspaceActivity.insert(
      0,
      WorkspaceActivityEntry(message: message, time: DateTime.now()),
    );
    if (workspaceActivity.length > 8) workspaceActivity.removeLast();
  }

  void setOpportunityLocationFilters({
    String? city,
    String? area,
    String? pincode,
  }) {
    selectedCity = city?.trim() ?? '';
    selectedArea = area?.trim() ?? '';
    selectedPincode = pincode?.trim() ?? '';
    clearMessages();
    notifyListeners();
  }

  void clearOpportunityFilters() {
    selectedCity = '';
    selectedArea = '';
    selectedPincode = '';
    clearMessages();
    notifyListeners();
  }

  Future<void> refreshFeed() async {
    await _run(() async {
      final records = await gateway.loadFeed();
      _restoreWorkspaceState(records);
      initialWorkspaceStateLoaded = true;
    }, success: 'Work opportunities refreshed.');
  }

  Future<void> loadInitialWorkspaceState() async {
    if (initialWorkspaceStateLoaded || busy) return;
    await refreshFeed();
    if (noticeMessage == 'Work opportunities refreshed.') {
      clearMessages();
      notifyListeners();
    }
  }

  void toggleOpportunity(String id) {
    expandedOpportunityId = expandedOpportunityId == id ? null : id;
    notifyListeners();
  }

  void openOpportunity(String id) {
    final opportunity = workOpportunities.firstWhere(
      (opportunity) => opportunity.id == id,
      orElse: () => workOpportunities.first,
    );
    selectedOpportunity = opportunity;
    applicationId = applicationIdsByOpportunity[opportunity.id];
    appliedOpportunityId = applicationId == null ? null : opportunity.id;
    withdrawnApplicationId = null;
    expandedTerms.clear();
    clearMessages();
  }

  void toggleTerm(String id) {
    if (!expandedTerms.add(id)) expandedTerms.remove(id);
    notifyListeners();
  }

  Future<bool> applySelectedOpportunity() async {
    final opportunity = selectedOpportunity;
    if (opportunity == null) {
      errorMessage = 'Open an opportunity before applying.';
      notifyListeners();
      return false;
    }
    if (!opportunity.available) {
      savedOpportunity = opportunity;
      errorMessage =
          'This opportunity is no longer accepting applications. It remains saved.';
      notifyListeners();
      return false;
    }
    final existingApplicationId = applicationIdsByOpportunity[opportunity.id];
    if (existingApplicationId != null) {
      applicationId = existingApplicationId;
      appliedOpportunityId = opportunity.id;
      errorMessage = null;
      noticeMessage =
          'Your application for this opportunity is already submitted.';
      notifyListeners();
      return true;
    }
    savedOpportunity = opportunity;
    if (opportunity.requiresWorkspace && !hasVerifiedWorkspace) {
      noticeMessage = 'Opportunity saved. Start My Work, then return to apply.';
      errorMessage = null;
      notifyListeners();
      return false;
    }
    return _runBool(
      () async {
        final createdApplicationId = await gateway.apply(opportunity.id);
        applicationIdsByOpportunity[opportunity.id] = createdApplicationId;
        applicationId = createdApplicationId;
        appliedOpportunityId = opportunity.id;
        withdrawnApplicationId = null;
      },
      success:
          'Application sent. The opportunity, terms and payout remain saved.',
    );
  }

  Future<bool> withdrawSelectedOpportunity() async {
    final opportunity = selectedOpportunity;
    final currentApplicationId = opportunity == null
        ? null
        : applicationIdsByOpportunity[opportunity.id];
    if (opportunity == null || currentApplicationId == null) {
      errorMessage =
          'There is no application to withdraw for this opportunity.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    return _runBool(
      () async {
        await gateway.withdraw(currentApplicationId, opportunity.id);
        applicationIdsByOpportunity.remove(opportunity.id);
        applicationId = null;
        appliedOpportunityId = null;
        withdrawnApplicationId = currentApplicationId;
      },
      success:
          'Application withdrawn. You can apply again while this opportunity remains available.',
    );
  }

  void startMyWork() {
    clearMessages();
    if (activeWorkspace == null) reviewStage = WorkReviewStage.drafting;
    notifyListeners();
  }

  void startAnotherWork() {
    selectedFamilyId = null;
    selectedProfile = null;
    alternateMobile = '';
    alternateOtpSent = false;
    alternateVerified = false;
    workName = '';
    workArea = '';
    primaryActivity = '';
    addedProofs
      ..clear()
      ..['personal-kyc'] = 'ACCOUNT-KYC';
    declarationAccepted = false;
    reviewCaseId = null;
    workspaceId = activeWorkspace?.id;
    subscriptionPlan = 'free';
    reviewReason = null;
    remoteReviewStatus = null;
    reviewCorrectionDraft = false;
    _profileSubmissionKey = null;
    if (activeWorkspace == null) reviewStage = WorkReviewStage.drafting;
    gstReminder = false;
    gstin = '';
    gstAttachmentAdded = false;
    gstProofReference = null;
    clearMessages();
    notifyListeners();
  }

  void selectFamily(String familyId) {
    selectedFamilyId = familyId;
    selectedProfile = null;
    clearMessages();
    notifyListeners();
  }

  void selectProfile(String profileId) {
    final nextProfile = workProfiles.firstWhere(
      (profile) => profile.id == profileId,
    );
    if (selectedProfile?.id != nextProfile.id) {
      addedProofs.removeWhere((id, _) => id != 'personal-kyc');
      declarationAccepted = false;
    }
    selectedProfile = nextProfile;
    clearMessages();
    notifyListeners();
  }

  void changeFamily() {
    selectedFamilyId = null;
    selectedProfile = null;
    clearMessages();
    notifyListeners();
  }

  void hydrateAccountSnapshot(WorkAccountSnapshot snapshot) {
    accountDisplayName = snapshot.displayName.trim();
    connectedProviderLabel = snapshot.providerLabel.trim();
    connectedProviderAccount = snapshot.providerAccount.trim();
    if (primaryMobile.isEmpty) {
      final digits = snapshot.mobile.replaceAll(RegExp(r'\D'), '');
      final normalized = digits.length > 10
          ? digits.substring(digits.length - 10)
          : digits;
      if (normalized.length == 10) {
        primaryMobile = normalized;
        primaryMobileVerified = snapshot.mobileConfirmed;
      }
    }
    if (contactEmail.isEmpty) {
      final normalized = snapshot.email.trim().toLowerCase();
      if (_validEmail(normalized)) {
        contactEmail = normalized;
        contactEmailVerified = snapshot.emailConfirmed;
      }
    }
  }

  bool get workspaceContactsReady =>
      primaryMobileVerified &&
      contactEmailVerified &&
      (alternateMobile.isEmpty || alternateVerified);

  Future<bool> sendPrimaryMobileOtp(String mobile) async {
    final normalized = mobile.replaceAll(RegExp(r'\D'), '');
    if (normalized.length != 10) {
      errorMessage = 'Enter a valid 10-digit phone number.';
      notifyListeners();
      return false;
    }
    primaryMobile = normalized;
    return _sendWorkspaceContactOtp(
      WorkContactChannel.primaryMobile,
      normalized,
      onSent: () {
        primaryMobileOtpSent = true;
        primaryMobileVerified = false;
      },
    );
  }

  Future<bool> verifyPrimaryMobileOtp(String code) =>
      _verifyWorkspaceContactOtp(
        WorkContactChannel.primaryMobile,
        primaryMobile,
        code,
        onVerified: () => primaryMobileVerified = true,
      );

  Future<bool> sendContactEmailOtp(String email) async {
    final normalized = email.trim().toLowerCase();
    if (!_validEmail(normalized)) {
      errorMessage = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }
    contactEmail = normalized;
    return _sendWorkspaceContactOtp(
      WorkContactChannel.email,
      normalized,
      onSent: () {
        contactEmailOtpSent = true;
        contactEmailVerified = false;
      },
    );
  }

  Future<bool> verifyContactEmailOtp(String code) => _verifyWorkspaceContactOtp(
    WorkContactChannel.email,
    contactEmail,
    code,
    onVerified: () => contactEmailVerified = true,
  );

  void changePrimaryMobile() {
    primaryMobile = '';
    primaryMobileOtpSent = false;
    primaryMobileVerified = false;
    clearMessages();
    notifyListeners();
  }

  void changeContactEmail() {
    contactEmail = '';
    contactEmailOtpSent = false;
    contactEmailVerified = false;
    clearMessages();
    notifyListeners();
  }

  Future<bool> sendAlternateOtp(String mobile) async {
    final normalized = mobile.replaceAll(RegExp(r'\D'), '');
    if (normalized.length != 10) {
      errorMessage = 'Enter a valid 10-digit alternate mobile number.';
      notifyListeners();
      return false;
    }
    if (normalized == primaryMobile) {
      errorMessage = 'This is already the number customers can reach you on.';
      notifyListeners();
      return false;
    }
    alternateMobile = normalized;
    return _sendWorkspaceContactOtp(
      WorkContactChannel.alternateMobile,
      normalized,
      onSent: () {
        alternateOtpSent = true;
        alternateVerified = false;
      },
    );
  }

  Future<bool> verifyAlternateOtp(String code) => _verifyWorkspaceContactOtp(
    WorkContactChannel.alternateMobile,
    alternateMobile,
    code,
    onVerified: () => alternateVerified = true,
  );

  Future<bool> _sendWorkspaceContactOtp(
    WorkContactChannel channel,
    String value, {
    required VoidCallback onSent,
  }) => _runBool(() async {
    await gateway.sendContactOtp(channel: channel, value: value);
    onSent();
  }, success: 'OTP sent. Enter the 6-digit code to confirm this contact.');

  Future<bool> _verifyWorkspaceContactOtp(
    WorkContactChannel channel,
    String value,
    String code, {
    required VoidCallback onVerified,
  }) async {
    final sent = switch (channel) {
      WorkContactChannel.primaryMobile => primaryMobileOtpSent,
      WorkContactChannel.email => contactEmailOtpSent,
      WorkContactChannel.alternateMobile => alternateOtpSent,
    };
    if (!sent) {
      errorMessage = 'Send the OTP before verification.';
      notifyListeners();
      return false;
    }
    final normalizedCode = code.replaceAll(RegExp(r'\D'), '');
    if (normalizedCode.length != 6) {
      errorMessage = 'Enter the complete 6-digit OTP.';
      notifyListeners();
      return false;
    }
    return _runBool(() async {
      await gateway.verifyContactOtp(
        channel: channel,
        value: value,
        code: normalizedCode,
      );
      onVerified();
    }, success: 'Contact confirmed for this Workspace.');
  }

  void removeAlternateMobile() {
    alternateMobile = '';
    alternateOtpSent = false;
    alternateVerified = false;
    clearMessages();
    notifyListeners();
  }

  bool continueToProof() {
    if (selectedProfile == null) {
      errorMessage = 'Choose the work profile that best matches what you do.';
      notifyListeners();
      return false;
    }
    if (!primaryMobileVerified) {
      errorMessage =
          'Confirm the phone number customers can reach you on before continuing.';
      notifyListeners();
      return false;
    }
    if (!contactEmailVerified) {
      errorMessage = 'Confirm your email address before continuing.';
      notifyListeners();
      return false;
    }
    if (alternateMobile.isNotEmpty && !alternateVerified) {
      errorMessage = 'Confirm or remove the alternate contact number.';
      notifyListeners();
      return false;
    }
    reviewStage = WorkReviewStage.drafting;
    clearMessages();
    notifyListeners();
    return true;
  }

  Future<bool> sendUnsupportedRequest({
    required String workspace,
    required String family,
    required String area,
    String otherActivity = '',
  }) async {
    if (workspace.trim().length < 3) {
      errorMessage = 'Enter your business, profession or service.';
      notifyListeners();
      return false;
    }
    if (family.trim().isEmpty) {
      errorMessage = 'Choose the closest category.';
      notifyListeners();
      return false;
    }
    if (area.trim().length < 3) {
      errorMessage = 'Enter your operating city or area.';
      notifyListeners();
      return false;
    }
    if (family.trim() == 'Other' && otherActivity.trim().length < 3) {
      errorMessage = 'Enter the activity you want to offer.';
      notifyListeners();
      return false;
    }
    unsupportedWorkspace = workspace.trim();
    unsupportedFamily = family.trim();
    unsupportedArea = area.trim();
    unsupportedOtherActivity = family.trim() == 'Other'
        ? otherActivity.trim()
        : '';
    unsupportedRequestSent = true;
    errorMessage = null;
    noticeMessage =
        'Thank you—MoolSocial will review your request and update you in Workspace and Chat.';
    notifyListeners();
    return true;
  }

  void saveDetails({
    required String name,
    required String area,
    required String activity,
  }) {
    workName = name.trim();
    workArea = area.trim();
    primaryActivity = activity.trim();
    clearMessages();
    notifyListeners();
  }

  bool validateDetails() {
    if (workName.length < 3) {
      errorMessage = 'Enter the work or business name.';
      notifyListeners();
      return false;
    }
    if (workArea.length < 3) {
      errorMessage = 'Enter an operating city or PIN code.';
      notifyListeners();
      return false;
    }
    if (primaryActivity.length < 3) {
      errorMessage = 'Describe the primary activity.';
      notifyListeners();
      return false;
    }
    clearMessages();
    notifyListeners();
    return true;
  }

  Future<bool> addProof(String proofId, WorkProofSource source) async {
    if (busy) return false;
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      final proof = await proofPicker.pick(source);
      if (proof == null) return false;
      addedProofs[proofId] = await gateway.saveProof(proofId, proof);
      noticeMessage = 'Document received. You can review it before submission.';
      return true;
    } on WorkGatewayException catch (error) {
      if (!error.cancelled) errorMessage = error.message;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void removeProof(String proofId) {
    if (proofId == 'personal-kyc') return;
    addedProofs.remove(proofId);
    showNotice('Document removed. You can add a replacement during review.');
  }

  void setDeclaration(bool value) {
    declarationAccepted = value;
    clearMessages();
    notifyListeners();
  }

  bool beginReviewCorrection() {
    if (remoteReviewStatus == WorkRemoteReviewStatus.suspended) {
      errorMessage =
          'This Workspace is unavailable. Contact MoolSocial Support for the next step.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (remoteReviewStatus == WorkRemoteReviewStatus.approved ||
        remoteReviewStatus == WorkRemoteReviewStatus.live) {
      errorMessage =
          'This Workspace is already approved. Open its dashboard to manage it.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (remoteReviewStatus == WorkRemoteReviewStatus.rejected) {
      reviseRejectedProfile();
      return true;
    }
    if (reviewCaseId == null) {
      errorMessage = 'Submit the Workspace before sending a correction.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    reviewCorrectionDraft = true;
    declarationAccepted = false;
    clearMessages();
    notifyListeners();
    return true;
  }

  WorkProfileSubmission _currentProfileSubmission() {
    final profile = selectedProfile!;
    _profileSubmissionKey ??=
        'work-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    return WorkProfileSubmission(
      familyId: profile.familyId,
      profileId: profile.id,
      name: workName,
      area: workArea,
      primaryActivity: primaryActivity,
      proofReferences: Map<String, String>.unmodifiable(addedProofs),
      primaryMobile: primaryMobile,
      email: contactEmail,
      alternateMobile: alternateMobile,
      connectedProvider: connectedProviderLabel,
      connectedProviderAccount: connectedProviderAccount,
      alternateMobileVerified: alternateVerified,
      idempotencyKey: _profileSubmissionKey!,
    );
  }

  Future<bool> submitProfile() async {
    if (!validateDetails()) return false;
    if (!workspaceContactsReady) {
      errorMessage =
          'Confirm your phone number and email before submitting this Workspace.';
      notifyListeners();
      return false;
    }
    if (!declarationAccepted) {
      errorMessage = 'Confirm the declaration before submission.';
      notifyListeners();
      return false;
    }
    final existingCaseId = reviewCaseId;
    if (existingCaseId != null && reviewCorrectionDraft) {
      return _runBool(
        () async {
          final result = await gateway.submitCorrection(
            existingCaseId,
            _currentProfileSubmission(),
          );
          reviewCaseId = result.caseId;
          subscriptionPlan = result.plan;
          reviewReason = result.reason;
          remoteReviewStatus = result.status;
          reviewStage = WorkReviewStage.gstPending;
          reviewCorrectionDraft = false;
        },
        success:
            'Your Workspace correction was sent with the existing review reference.',
      );
    }
    if (existingCaseId != null) {
      noticeMessage =
          'This Workspace is already under review as $existingCaseId.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    return _runBool(
      () async {
        final result = await gateway.submitProfile(_currentProfileSubmission());
        reviewCaseId = result.caseId;
        subscriptionPlan = result.plan;
        reviewReason = result.reason;
        remoteReviewStatus = result.status;
        reviewStage = WorkReviewStage.gstPending;
      },
      success:
          'Work profile sent for review. Your personal account remains active.',
    );
  }

  void remindGstLater() {
    gstReminder = true;
    errorMessage = null;
    noticeMessage =
        'GST reminder saved. Review continues without losing progress.';
    notifyListeners();
  }

  Future<bool> addGstProof(WorkProofSource source) async {
    if (busy) return false;
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      final proof = await proofPicker.pick(source);
      if (proof == null) return false;
      gstProofReference = await gateway.saveProof('gst', proof);
      gstAttachmentAdded = true;
      noticeMessage = 'GST certificate received for this review.';
      return true;
    } on WorkGatewayException catch (error) {
      if (!error.cancelled) errorMessage = error.message;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> submitGstProof(String value) async {
    final normalized = value.trim().toUpperCase();
    if (!RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][A-Z0-9]Z[A-Z0-9]$',
    ).hasMatch(normalized)) {
      errorMessage = 'Enter a valid 15-character GSTIN.';
      notifyListeners();
      return false;
    }
    if (!gstAttachmentAdded) {
      errorMessage = 'Attach the GST certificate before submission.';
      notifyListeners();
      return false;
    }
    return _runBool(() async {
      final caseId = reviewCaseId;
      if (caseId == null) {
        throw const WorkGatewayException(
          'Submit the Workspace profile before adding a GST certificate.',
        );
      }
      final proofReference = gstProofReference;
      if (proofReference == null) {
        throw const WorkGatewayException(
          'Attach the GST certificate before submission.',
        );
      }
      await gateway.submitGst(caseId, normalized, proofReference);
      gstin = normalized;
      gstReminder = false;
    }, success: 'GST certificate added to your Workspace review.');
  }

  Future<bool> checkReview() async {
    if (reviewCaseId == null) {
      errorMessage = 'Submit the work profile before checking review.';
      notifyListeners();
      return false;
    }
    if (busy) return false;
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      final result = await gateway.checkReview(reviewCaseId!);
      subscriptionPlan = result.plan;
      reviewReason = result.reason;
      remoteReviewStatus = result.status;
      switch (result.status) {
        case WorkRemoteReviewStatus.pending:
          reviewStage = WorkReviewStage.gstPending;
          noticeMessage =
              'Review is still in progress. Your personal account remains active.';
          return false;
        case WorkRemoteReviewStatus.rejected:
          errorMessage = result.reason?.trim().isNotEmpty == true
              ? result.reason
              : 'This work profile needs changes before it can be approved.';
          return false;
        case WorkRemoteReviewStatus.suspended:
          errorMessage = result.reason?.trim().isNotEmpty == true
              ? result.reason
              : 'This Workspace is temporarily unavailable. Contact MoolSocial Support.';
          return false;
        case WorkRemoteReviewStatus.approved:
        case WorkRemoteReviewStatus.live:
          final approvedWorkspaceId = result.workspaceId;
          if (approvedWorkspaceId == null || approvedWorkspaceId.isEmpty) {
            throw const WorkGatewayException(
              'Approval was received without a Workspace. Try checking again.',
              retryable: true,
            );
          }
          workspaceId = approvedWorkspaceId;
          reviewCorrectionDraft = false;
          reviewStage = result.status == WorkRemoteReviewStatus.live
              ? WorkReviewStage.live
              : WorkReviewStage.approved;
          final previousWorkspace = activeWorkspace;
          if (previousWorkspace != null &&
              previousWorkspace.id != approvedWorkspaceId &&
              otherWorkspaces.every(
                (workspace) => workspace.id != previousWorkspace.id,
              )) {
            otherWorkspaces.add(previousWorkspace);
          }
          activeWorkspace = WorkWorkspace(
            id: approvedWorkspaceId,
            name: workName,
            profileLabel: selectedProfile?.label ?? 'Work profile',
            profileId: selectedProfile?.id,
            area: workArea,
            verified: true,
            gstReminder: gstReminder && gstin.isEmpty,
          );
          noticeMessage = result.status == WorkRemoteReviewStatus.live
              ? 'Your Workspace is live.'
              : 'Work profile approved. Finish setup before customers can view your Workspace.';
          return true;
      }
    } on WorkGatewayException catch (error) {
      errorMessage = error.message;
      noticeMessage = null;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void beginRetailerSetup() {
    reviewStage = WorkReviewStage.setup;
    clearMessages();
    notifyListeners();
  }

  void reviseRejectedProfile() {
    if (remoteReviewStatus != WorkRemoteReviewStatus.rejected) return;
    reviewCaseId = null;
    workspaceId = null;
    reviewReason = null;
    remoteReviewStatus = null;
    reviewCorrectionDraft = false;
    _profileSubmissionKey = null;
    declarationAccepted = false;
    reviewStage = WorkReviewStage.drafting;
    clearMessages();
    notifyListeners();
  }

  void addRetailerProduct() {
    retailerProductAdded = true;
    if (workspaceCatalogueItems.isEmpty) {
      workspaceCatalogueItems.add(workspaceMasterCatalogue.first);
    }
    clearMessages();
    notifyListeners();
  }

  void saveRetailerProduct({
    required int quantity,
    required int buyPrice,
    required int sellPrice,
  }) {
    retailerQuantity = quantity;
    retailerBuyPrice = buyPrice;
    retailerSellPrice = sellPrice;
    if (workspaceCatalogueItems.isEmpty) {
      workspaceCatalogueItems.add(workspaceMasterCatalogue.first);
    }
    workspaceCatalogueItems[0] = workspaceCatalogueItems.first.copyWith(
      stock: quantity,
      purchasePrice: buyPrice,
      sellingPrice: sellPrice,
      unitPrice: '₹$sellPrice/${workspaceCatalogueItems.first.pack}',
      available: quantity > 0,
      publicListing: true,
    );
    clearMessages();
    notifyListeners();
  }

  void setRetailerFulfilment({
    required bool homeDelivery,
    required bool storeCollection,
  }) {
    retailerHomeDelivery = homeDelivery;
    retailerStoreCollection = storeCollection;
    clearMessages();
    notifyListeners();
  }

  Future<bool> finishRetailerSetup() async {
    if (!retailerProductAdded) {
      errorMessage = 'Add at least one product from the verified catalogue.';
      notifyListeners();
      return false;
    }
    if (retailerQuantity <= 0) {
      errorMessage = 'Enter the available consumer quantity.';
      notifyListeners();
      return false;
    }
    if (retailerBuyPrice <= 0) {
      errorMessage = 'Enter the purchase price for margin checking.';
      notifyListeners();
      return false;
    }
    if (retailerSellPrice <= retailerBuyPrice) {
      errorMessage =
          'Enter a selling price above the purchase price, or correct the purchase cost.';
      notifyListeners();
      return false;
    }
    if (!retailerHomeDelivery && !retailerStoreCollection) {
      errorMessage =
          'Choose home delivery or store collection before going live.';
      notifyListeners();
      return false;
    }
    if (retailerSetupSaved) {
      noticeMessage = 'Shop setup is already complete.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    return _runBool(
      () async {
        final approvedWorkspaceId = workspaceId;
        if (approvedWorkspaceId == null) {
          throw const WorkGatewayException(
            'Wait for Workspace approval before finishing setup.',
          );
        }
        await gateway.finishSetup(
          workspaceId: approvedWorkspaceId,
          quantity: retailerQuantity,
          buyPrice: retailerBuyPrice,
          sellPrice: retailerSellPrice,
          homeDelivery: retailerHomeDelivery,
          storeCollection: retailerStoreCollection,
        );
        retailerSetupSaved = true;
        reviewStage = WorkReviewStage.live;
        workspaceVisibleToCustomers = true;
        _recordWorkspaceActivity('Store setup completed and published.');
      },
      success:
          'Shop setup complete. Your available product and fulfilment choices are live.',
    );
  }

  void seedVerifiedWorkspace() {
    selectedProfile = workProfiles.first;
    workName = 'Mahadev Fresh Mart';
    workArea = 'Sardarpura, Jodhpur';
    primaryActivity = 'Grocery and household products';
    reviewCaseId = 'WP-240701';
    workspaceId = 'WK-510001';
    reviewStage = WorkReviewStage.approved;
    activeWorkspace = const WorkWorkspace(
      id: 'WK-510001',
      name: 'Mahadev Fresh Mart',
      profileLabel: 'Grocery / Kirana Shop',
      profileId: 'retailer-grocery',
      area: 'Sardarpura, Jodhpur',
      verified: true,
    );
    workspaceCatalogueItems
      ..clear()
      ..add(
        workspaceMasterCatalogue.first.copyWith(
          stock: 8,
          available: true,
          publicListing: true,
        ),
      );
    notifyListeners();
  }

  void seedMultipleWorkspaces() {
    seedVerifiedWorkspace();
    otherWorkspaces
      ..clear()
      ..addAll(const [
        WorkWorkspace(
          id: 'WK-510002',
          name: 'Creator Work',
          profileLabel: 'Creator',
          profileId: 'creator',
          area: 'Remote India',
          verified: true,
        ),
        WorkWorkspace(
          id: 'WK-510003',
          name: 'Quick Delivery Work',
          profileLabel: 'Quick Delivery Biker',
          profileId: 'quick-delivery-biker',
          area: 'Jodhpur',
          verified: true,
        ),
      ]);
    notifyListeners();
  }

  void _restoreWorkspaceState(List<WorkReviewResult> records) {
    if (records.isEmpty) return;
    WorkWorkspace? restoredActive;
    final restoredOthers = <WorkWorkspace>[];
    WorkReviewResult? pending;
    WorkReviewResult? stopped;
    for (final record in records) {
      if (record.status == WorkRemoteReviewStatus.pending) {
        pending ??= record;
        continue;
      }
      if (record.status == WorkRemoteReviewStatus.rejected ||
          record.status == WorkRemoteReviewStatus.suspended) {
        stopped ??= record;
        continue;
      }
      if (record.status != WorkRemoteReviewStatus.approved &&
          record.status != WorkRemoteReviewStatus.live) {
        continue;
      }
      final id = record.workspaceId;
      final name = record.name;
      final area = record.area;
      final profileId = record.profileId;
      if (id == null || name == null || area == null || profileId == null) {
        continue;
      }
      final option = workProfiles
          .where((item) => item.id == profileId)
          .firstOrNull;
      if (option == null) continue;
      final workspace = WorkWorkspace(
        id: id,
        name: name,
        profileLabel: option.label,
        profileId: option.id,
        area: area,
        verified: true,
      );
      if (restoredActive == null ||
          record.status == WorkRemoteReviewStatus.live) {
        if (restoredActive != null) restoredOthers.add(restoredActive);
        restoredActive = workspace;
        selectedProfile = option;
        workName = name;
        workArea = area;
        primaryActivity = record.primaryActivity ?? '';
        reviewCaseId = record.caseId;
        workspaceId = id;
        subscriptionPlan = record.plan;
        remoteReviewStatus = record.status;
        reviewStage = record.status == WorkRemoteReviewStatus.live
            ? WorkReviewStage.live
            : WorkReviewStage.approved;
      } else {
        restoredOthers.add(workspace);
      }
    }
    if (restoredActive != null) {
      activeWorkspace = restoredActive;
      otherWorkspaces
        ..clear()
        ..addAll(restoredOthers);
      return;
    }
    if (pending != null) {
      final option = workProfiles
          .where((item) => item.id == pending!.profileId)
          .firstOrNull;
      selectedProfile = option;
      selectedFamilyId = option?.familyId;
      workName = pending.name ?? workName;
      workArea = pending.area ?? workArea;
      primaryActivity = pending.primaryActivity ?? primaryActivity;
      reviewCaseId = pending.caseId;
      subscriptionPlan = pending.plan;
      remoteReviewStatus = pending.status;
      reviewStage = WorkReviewStage.gstPending;
      return;
    }
    if (stopped != null) {
      final option = workProfiles
          .where((item) => item.id == stopped!.profileId)
          .firstOrNull;
      selectedProfile = option;
      selectedFamilyId = option?.familyId;
      workName = stopped.name ?? workName;
      workArea = stopped.area ?? workArea;
      primaryActivity = stopped.primaryActivity ?? primaryActivity;
      reviewCaseId = stopped.caseId;
      subscriptionPlan = stopped.plan;
      reviewReason = stopped.reason;
      remoteReviewStatus = stopped.status;
      reviewStage = WorkReviewStage.gstPending;
    }
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    await _runBool(action, success: success);
  }

  Future<bool> _runBool(
    Future<void> Function() action, {
    required String success,
  }) async {
    if (busy) return false;
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      await action();
      errorMessage = null;
      noticeMessage = success;
      return true;
    } on WorkGatewayException catch (error) {
      errorMessage = error.message;
      noticeMessage = null;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

bool _validEmail(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
