import 'package:flutter/foundation.dart';

import 'work_models.dart';
import 'work_services.dart';

class WorkSession extends ChangeNotifier {
  WorkSession({ReviewWorkGateway? gateway})
    : gateway = gateway ?? ReviewWorkGateway();

  final ReviewWorkGateway gateway;

  bool busy = false;
  String? errorMessage;
  String? noticeMessage;
  WorkFeedFilter filter = WorkFeedFilter.forYou;
  String searchQuery = '';
  String? expandedOpportunityId;
  WorkOpportunity? selectedOpportunity;
  WorkOpportunity? savedOpportunity;
  String? applicationId;
  final Set<String> expandedTerms = <String>{};

  String? selectedFamilyId;
  WorkProfileOption? selectedProfile;
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
  bool gstReminder = false;
  String gstin = '';
  bool gstAttachmentAdded = false;
  bool unsupportedRequestSent = false;
  String unsupportedWorkspace = '';
  String unsupportedArea = '';
  String unsupportedFamily = '';

  WorkWorkspace? activeWorkspace;
  final List<WorkWorkspace> otherWorkspaces = <WorkWorkspace>[];

  bool retailerProductAdded = false;
  int retailerQuantity = 0;
  int retailerBuyPrice = 0;
  int retailerSellPrice = 0;
  bool retailerHomeDelivery = false;
  bool retailerStoreCollection = false;
  bool retailerSetupSaved = false;

  List<WorkOpportunity> get filteredOpportunities {
    final normalized = searchQuery.trim().toLowerCase();
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
          ].join(' ').toLowerCase().contains(normalized);
      return filterMatch && searchMatch;
    }).toList();
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

  bool get requiredProofsAdded => workProofs
      .where((proof) => proof.required)
      .every((proof) => addedProofs.containsKey(proof.id));

  bool get hasVerifiedWorkspace =>
      activeWorkspace?.verified == true &&
      {
        WorkReviewStage.approved,
        WorkReviewStage.setup,
        WorkReviewStage.live,
      }.contains(reviewStage);

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

  Future<void> refreshFeed() async {
    await _run(gateway.loadFeed, success: 'Verified work is up to date.');
  }

  void toggleOpportunity(String id) {
    expandedOpportunityId = expandedOpportunityId == id ? null : id;
    notifyListeners();
  }

  void openOpportunity(String id) {
    selectedOpportunity = workOpportunities.firstWhere(
      (opportunity) => opportunity.id == id,
      orElse: () => workOpportunities.first,
    );
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
    savedOpportunity = opportunity;
    if (!hasVerifiedWorkspace) {
      noticeMessage = 'Opportunity saved. Start My Work, then return to apply.';
      errorMessage = null;
      notifyListeners();
      return false;
    }
    return _runBool(
      () async {
        applicationId = await gateway.apply(opportunity.id);
      },
      success:
          'Application sent. The opportunity, terms and payout remain saved.',
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
    workspaceId = null;
    reviewStage = WorkReviewStage.drafting;
    gstReminder = false;
    gstin = '';
    gstAttachmentAdded = false;
    clearMessages();
    notifyListeners();
  }

  void selectFamily(String familyId) {
    selectedFamilyId = familyId;
    selectedProfile = null;
    alternateOtpSent = false;
    alternateVerified = false;
    clearMessages();
    notifyListeners();
  }

  void selectProfile(String profileId) {
    selectedProfile = workProfiles.firstWhere(
      (profile) => profile.id == profileId,
    );
    clearMessages();
    notifyListeners();
  }

  void changeFamily() {
    selectedFamilyId = null;
    selectedProfile = null;
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
    if (normalized == '9829012321') {
      errorMessage = 'This is already your verified account number.';
      notifyListeners();
      return false;
    }
    alternateMobile = normalized;
    return _runBool(() async {
      await gateway.sendOtp(normalized);
      alternateOtpSent = true;
      alternateVerified = false;
    }, success: 'OTP sent to +91 $normalized.');
  }

  bool verifyAlternateOtp(String code) {
    if (!alternateOtpSent) {
      errorMessage = 'Send the OTP before verification.';
      notifyListeners();
      return false;
    }
    if (code.trim() != '123456') {
      errorMessage = 'Enter the 6-digit OTP sent to the alternate number.';
      notifyListeners();
      return false;
    }
    alternateVerified = true;
    errorMessage = null;
    noticeMessage = 'Alternate work number verified.';
    notifyListeners();
    return true;
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
      errorMessage = 'Choose the exact work profile you operate.';
      notifyListeners();
      return false;
    }
    if (alternateMobile.isNotEmpty && !alternateVerified) {
      errorMessage = 'Verify or remove the alternate work number.';
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
  }) async {
    if (workspace.trim().length < 3) {
      errorMessage = 'Describe the work profile you need.';
      notifyListeners();
      return false;
    }
    if (family.trim().isEmpty) {
      errorMessage = 'Choose the closest work area.';
      notifyListeners();
      return false;
    }
    if (area.trim().length < 3) {
      errorMessage = 'Enter your operating city or area.';
      notifyListeners();
      return false;
    }
    unsupportedWorkspace = workspace.trim();
    unsupportedFamily = family.trim();
    unsupportedArea = area.trim();
    unsupportedRequestSent = true;
    errorMessage = null;
    noticeMessage =
        'Request sent. No workspace was created. We will update My Work and Chat.';
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

  Future<bool> addProof(String proofId, String source) async {
    return _runBool(() async {
      addedProofs[proofId] = await gateway.saveProof(proofId, source);
    }, success: 'Proof added. You can review it before submission.');
  }

  void removeProof(String proofId) {
    if (proofId == 'personal-kyc') return;
    addedProofs.remove(proofId);
    showNotice('Proof removed. Add a replacement before review if required.');
  }

  void setDeclaration(bool value) {
    declarationAccepted = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> submitProfile() async {
    if (!validateDetails()) return false;
    if (!requiredProofsAdded) {
      errorMessage = 'Add every required proof before submission.';
      notifyListeners();
      return false;
    }
    if (!declarationAccepted) {
      errorMessage = 'Confirm the declaration before submission.';
      notifyListeners();
      return false;
    }
    if (reviewCaseId != null) {
      noticeMessage =
          'This work profile is already under review as $reviewCaseId.';
      errorMessage = null;
      notifyListeners();
      return true;
    }
    return _runBool(
      () async {
        reviewCaseId = await gateway.submitProfile();
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

  void attachGst() {
    gstAttachmentAdded = true;
    clearMessages();
    notifyListeners();
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
      await gateway.submitGst();
      gstin = normalized;
      gstReminder = false;
    }, success: 'GST proof added to the active review.');
  }

  Future<bool> checkReview() async {
    if (reviewCaseId == null) {
      errorMessage = 'Submit the work profile before checking review.';
      notifyListeners();
      return false;
    }
    return _runBool(
      () async {
        workspaceId = await gateway.checkReview();
        reviewStage = WorkReviewStage.approved;
        activeWorkspace = WorkWorkspace(
          id: workspaceId!,
          name: workName,
          profileLabel: selectedProfile?.label ?? 'Work profile',
          area: workArea,
          verified: true,
          gstReminder: gstReminder && gstin.isEmpty,
        );
      },
      success:
          'Work profile approved. Finish the exact setup before customers can see it.',
    );
  }

  void beginRetailerSetup() {
    reviewStage = WorkReviewStage.setup;
    clearMessages();
    notifyListeners();
  }

  void addRetailerProduct() {
    retailerProductAdded = true;
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
        await gateway.finishSetup();
        retailerSetupSaved = true;
        reviewStage = WorkReviewStage.live;
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
      area: 'Sardarpura, Jodhpur',
      verified: true,
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
          area: 'Remote India',
          verified: true,
        ),
        WorkWorkspace(
          id: 'WK-510003',
          name: 'Delivery Work',
          profileLabel: 'Ride / Delivery Captain',
          area: 'Jodhpur',
          verified: true,
        ),
      ]);
    notifyListeners();
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
