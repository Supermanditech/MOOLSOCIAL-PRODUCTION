import 'package:flutter/foundation.dart';

import 'creator_models.dart';
import 'creator_services.dart';

class CreatorSession extends ChangeNotifier {
  CreatorSession({ReviewCreatorGateway? gateway})
    : gateway = gateway ?? ReviewCreatorGateway();

  final ReviewCreatorGateway gateway;

  bool online = true;
  bool authorized = true;
  bool busy = false;
  String? errorMessage;
  String? noticeMessage;

  CreatorPublishFormat publishFormat = CreatorPublishFormat.reel;
  String postTitle = '';
  String postCaption = '';
  bool mediaSelected = false;
  bool mediaWithinLimit = true;
  int reelDurationDays = 1;
  String reelFundingCampaignId = 'CR-2048';
  bool reelFundingReserved = true;
  bool reelFundingReviewed = false;
  String visibility = 'public';
  bool sponsored = false;
  bool rightsConfirmed = false;
  String? draftId;
  String? publishedPostId;

  CreatorContentTab contentTab = CreatorContentTab.published;
  String contentQuery = '';
  String? selectedContentId;

  CreatorPerformanceWindow performanceWindow =
      CreatorPerformanceWindow.sevenDays;
  CreatorPerformanceView performanceView = CreatorPerformanceView.content;
  String? exportId;

  CreatorCampaignTab campaignTab = CreatorCampaignTab.bestFit;
  String selectedCampaignId = 'CR-2048';
  bool campaignTermsAccepted = false;
  String? campaignAcceptanceId;

  CreatorEarningsTab earningsTab = CreatorEarningsTab.overview;
  String? selectedLedgerId;
  String? statementId;

  CreatorControlArea selectedControlArea = CreatorControlArea.rights;
  bool appealEvidenceConfirmed = false;
  String appealNote =
      'I own the original audio and can provide the source recording.';
  String? appealId;

  String selectedMembershipId = 'local-insider';
  bool membershipBenefitsConfirmed = false;
  bool membershipBillingConfirmed = false;
  String? membershipPlanId;

  YouTubeConnectStep youtubeStep = YouTubeConnectStep.source;
  String youtubeUrl = '';
  bool youtubeChannelConnected = false;
  bool youtubeValidated = false;
  String? youtubeValidationId;
  String youtubeAction = '';
  String youtubeCategory = 'grocery';
  String youtubeLocation = 'jodhpur';
  String youtubeReference = 'Monthly Fresh Basket · ₹399';
  String youtubeContext =
      'See the basket price, delivery time and refund rule before ordering.';
  bool youtubeSponsored = false;
  String youtubeCampaign = 'none';
  int youtubePlacementDays = 1;
  bool youtubeRightsConfirmed = false;
  bool youtubeActionTruthConfirmed = false;
  String? youtubeConnectedPostId;

  CreatorCampaign get selectedCampaign => reviewCreatorCampaigns.firstWhere(
    (item) => item.id == selectedCampaignId,
  );

  CreatorCampaign get reelFundingCampaign => reviewCreatorCampaigns.firstWhere(
    (item) => item.id == reelFundingCampaignId,
  );

  CreatorMembershipPlan get selectedMembership => reviewCreatorMembershipPlans
      .firstWhere((item) => item.id == selectedMembershipId);

  List<CreatorContentItem> get visibleContent {
    final expectedStatus = switch (contentTab) {
      CreatorContentTab.published => 'Published',
      CreatorContentTab.drafts => 'Draft',
      CreatorContentTab.scheduled => 'Scheduled',
      CreatorContentTab.unavailable => 'Unavailable',
    };
    final query = contentQuery.trim().toLowerCase();
    return reviewCreatorContent
        .where((item) => item.status == expectedStatus)
        .where(
          (item) =>
              query.isEmpty ||
              item.title.toLowerCase().contains(query) ||
              item.format.toLowerCase().contains(query),
        )
        .toList();
  }

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

  void selectPublishFormat(CreatorPublishFormat value) {
    publishFormat = value;
    publishedPostId = null;
    clearMessages();
    notifyListeners();
  }

  void setPostTitle(String value) {
    postTitle = value;
    publishedPostId = null;
    clearMessages();
    notifyListeners();
  }

  void setPostCaption(String value) {
    postCaption = value;
    publishedPostId = null;
    clearMessages();
    notifyListeners();
  }

  void selectMedia({bool withinLimit = true}) {
    mediaSelected = true;
    mediaWithinLimit = withinLimit;
    publishedPostId = null;
    clearMessages();
    notifyListeners();
  }

  void clearMedia() {
    mediaSelected = false;
    publishedPostId = null;
    clearMessages();
    notifyListeners();
  }

  void setReelDuration(int value) {
    reelDurationDays = value.clamp(1, 7);
    clearMessages();
    notifyListeners();
  }

  void acceptReelFunding(bool value) {
    reelFundingReviewed = value;
    clearMessages();
    notifyListeners();
  }

  void setVisibility(String value) {
    visibility = value;
    clearMessages();
    notifyListeners();
  }

  void setSponsored(bool value) {
    sponsored = value;
    clearMessages();
    notifyListeners();
  }

  void confirmRights(bool value) {
    rightsConfirmed = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> saveDraft() async {
    if (draftId != null) {
      noticeMessage = '$draftId is already saved. No second draft was created.';
      notifyListeners();
      return true;
    }
    if (postTitle.trim().length < 3 && postCaption.trim().length < 8) {
      return _validation('Add a title or useful caption before saving.');
    }
    return _protected(
      operation: gateway.saveDraft,
      success: () {
        draftId = 'CR-DRAFT-125-0719';
        noticeMessage = 'Draft saved. Continue from Content Library anytime.';
      },
    );
  }

  Future<bool> publishNativePost() async {
    if (publishedPostId != null) {
      noticeMessage =
          '$publishedPostId is already published. It was not posted twice.';
      notifyListeners();
      return true;
    }
    if (publishFormat == CreatorPublishFormat.youtube) {
      return _validation('Continue with YouTube Connect for video content.');
    }
    if (postTitle.trim().length < 3) {
      return _validation('Add a clear title.');
    }
    if (postCaption.trim().length < 8) {
      return _validation('Add a useful caption of at least 8 characters.');
    }
    if (publishFormat != CreatorPublishFormat.text && !mediaSelected) {
      return _validation('Choose media before review.');
    }
    if (!mediaWithinLimit) {
      return _validation(
        'This Reel is longer than 60 seconds. Trim it before publishing.',
      );
    }
    if (publishFormat == CreatorPublishFormat.reel &&
        (!reelFundingReserved || !reelFundingReviewed)) {
      return _validation(
        'A verified business must reserve funding. Review the sponsor, 1–7 day run and automatic expiry.',
      );
    }
    if (!rightsConfirmed) {
      return _validation('Confirm media rights before publishing.');
    }
    return _protected(
      operation: gateway.publishPost,
      success: () {
        publishedPostId = switch (publishFormat) {
          CreatorPublishFormat.reel => 'REEL-125-0719',
          CreatorPublishFormat.text => 'POST-125-0719',
          CreatorPublishFormat.image => 'IMAGE-125-0719',
          CreatorPublishFormat.youtube => throw StateError('unreachable'),
        };
        noticeMessage = publishFormat == CreatorPublishFormat.reel
            ? 'Business-funded Reel published for $reelDurationDays day${reelDurationDays == 1 ? '' : 's'}. It will unpublish automatically.'
            : 'Post published. It is now visible to the selected audience.';
      },
    );
  }

  void setContentTab(CreatorContentTab value) {
    contentTab = value;
    selectedContentId = null;
    clearMessages();
    notifyListeners();
  }

  void setContentQuery(String value) {
    contentQuery = value;
    selectedContentId = null;
    clearMessages();
    notifyListeners();
  }

  void selectContent(String id) {
    selectedContentId = id;
    clearMessages();
    notifyListeners();
  }

  void setPerformanceWindow(CreatorPerformanceWindow value) {
    performanceWindow = value;
    clearMessages();
    notifyListeners();
  }

  void setPerformanceView(CreatorPerformanceView value) {
    performanceView = value;
    clearMessages();
    notifyListeners();
  }

  void prepareExport(String format) {
    exportId = 'CR-EXPORT-127-${format.toUpperCase()}';
    noticeMessage = '$format report prepared with aggregated results.';
    errorMessage = null;
    notifyListeners();
  }

  void setCampaignTab(CreatorCampaignTab value) {
    campaignTab = value;
    clearMessages();
    notifyListeners();
  }

  void selectCampaign(String id) {
    selectedCampaignId = id;
    campaignTermsAccepted = false;
    campaignAcceptanceId = null;
    clearMessages();
    notifyListeners();
  }

  void acceptCampaignTerms(bool value) {
    campaignTermsAccepted = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> acceptCampaign() async {
    if (campaignAcceptanceId != null) {
      noticeMessage =
          '$campaignAcceptanceId already reserves this campaign. No second acceptance was created.';
      notifyListeners();
      return true;
    }
    if (!campaignTermsAccepted) {
      return _validation(
        'Review and accept the brief, rights, disclosure, attribution and cancellation terms.',
      );
    }
    return _protected(
      operation: gateway.acceptCampaign,
      success: () {
        campaignAcceptanceId = 'CR-ACCEPT-129-2048';
        noticeMessage =
            'Campaign accepted. The funded deliverable is ready to create.';
      },
    );
  }

  void setEarningsTab(CreatorEarningsTab value) {
    earningsTab = value;
    clearMessages();
    notifyListeners();
  }

  void selectLedger(String id) {
    selectedLedgerId = id;
    clearMessages();
    notifyListeners();
  }

  Future<bool> prepareStatement() async {
    if (statementId != null) {
      noticeMessage =
          '$statementId is already ready. No duplicate statement was created.';
      notifyListeners();
      return true;
    }
    return _protected(
      operation: gateway.prepareStatement,
      success: () {
        statementId = 'CR-STATEMENT-130-0726';
        noticeMessage = 'July statement is ready in PDF and CSV.';
      },
    );
  }

  void selectControl(CreatorControlArea value) {
    selectedControlArea = value;
    clearMessages();
    notifyListeners();
  }

  void confirmAppealEvidence(bool value) {
    appealEvidenceConfirmed = value;
    clearMessages();
    notifyListeners();
  }

  void setAppealNote(String value) {
    appealNote = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> submitAppeal() async {
    if (appealId != null) {
      noticeMessage = '$appealId is already open. No duplicate appeal exists.';
      notifyListeners();
      return true;
    }
    if (!appealEvidenceConfirmed || appealNote.trim().length < 12) {
      return _validation(
        'Confirm the evidence and explain your appeal in at least 12 characters.',
      );
    }
    return _protected(
      operation: gateway.submitAppeal,
      success: () {
        appealId = 'CR-APPEAL-131-2041';
        noticeMessage =
            'Appeal submitted. The affected item remains published while earnings are held.';
      },
    );
  }

  void selectMembership(String id) {
    selectedMembershipId = id;
    membershipBenefitsConfirmed = false;
    membershipBillingConfirmed = false;
    membershipPlanId = null;
    clearMessages();
    notifyListeners();
  }

  void confirmMembershipBenefits(bool value) {
    membershipBenefitsConfirmed = value;
    clearMessages();
    notifyListeners();
  }

  void confirmMembershipBilling(bool value) {
    membershipBillingConfirmed = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> saveMembershipPlan() async {
    if (membershipPlanId != null) {
      noticeMessage =
          '$membershipPlanId is already saved. No duplicate plan was created.';
      notifyListeners();
      return true;
    }
    if (!membershipBenefitsConfirmed || !membershipBillingConfirmed) {
      return _validation(
        'Confirm the member promise and the price, take-home, renewal, refund and cancellation terms.',
      );
    }
    return _protected(
      operation: gateway.saveMembership,
      success: () {
        membershipPlanId = 'CR-MEMBER-132-${selectedMembership.id}';
        noticeMessage =
            '${selectedMembership.name} plan saved for final activation review.';
      },
    );
  }

  void setYouTubeUrl(String value) {
    youtubeUrl = value.trim();
    youtubeValidated = false;
    youtubeValidationId = null;
    clearMessages();
    notifyListeners();
  }

  void setYouTubeChannelConnected(bool value) {
    youtubeChannelConnected = value;
    youtubeValidated = false;
    youtubeValidationId = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> validateYouTubeSource() async {
    if (youtubeValidationId != null) {
      noticeMessage =
          '$youtubeValidationId already confirms this public video. It was not validated twice.';
      notifyListeners();
      return true;
    }
    final validUrl =
        youtubeUrl.contains('youtube.com/') || youtubeUrl.contains('youtu.be/');
    if (!validUrl && !youtubeChannelConnected) {
      return _validation(
        'Paste a public YouTube link or connect your channel first.',
      );
    }
    return _protected(
      operation: gateway.validateYouTube,
      success: () {
        youtubeValidated = true;
        youtubeValidationId = 'YT-VALID-166-0719';
        noticeMessage =
            'Public YouTube content validated. Choose its MoolSocial action.';
      },
    );
  }

  bool continueToYouTubeAction() {
    if (!youtubeValidated) {
      return _validation('Validate one public YouTube video or Short first.');
    }
    youtubeStep = YouTubeConnectStep.action;
    clearMessages();
    notifyListeners();
    return true;
  }

  void selectYouTubeAction(String value) {
    youtubeAction = value;
    clearMessages();
    notifyListeners();
  }

  void setYouTubeCategory(String value) {
    youtubeCategory = value;
    clearMessages();
    notifyListeners();
  }

  void setYouTubeLocation(String value) {
    youtubeLocation = value;
    clearMessages();
    notifyListeners();
  }

  void setYouTubeReference(String value) {
    youtubeReference = value;
    clearMessages();
    notifyListeners();
  }

  void setYouTubeContext(String value) {
    youtubeContext = value;
    clearMessages();
    notifyListeners();
  }

  void setYouTubeSponsored(bool value) {
    youtubeSponsored = value;
    clearMessages();
    notifyListeners();
  }

  void setYouTubeCampaign(String value) {
    youtubeCampaign = value;
    clearMessages();
    notifyListeners();
  }

  void setYouTubePlacementDays(int value) {
    youtubePlacementDays = value.clamp(1, 7);
    clearMessages();
    notifyListeners();
  }

  void confirmYouTubeRights(bool value) {
    youtubeRightsConfirmed = value;
    clearMessages();
    notifyListeners();
  }

  void confirmYouTubeActionTruth(bool value) {
    youtubeActionTruthConfirmed = value;
    clearMessages();
    notifyListeners();
  }

  bool continueToYouTubeReview() {
    if (youtubeAction.isEmpty) {
      return _validation('Choose what the viewer should accomplish.');
    }
    if (youtubeContext.trim().length < 12) {
      return _validation('Explain the exact user outcome.');
    }
    if (!youtubeRightsConfirmed || !youtubeActionTruthConfirmed) {
      return _validation(
        'Confirm video rights and that the attached action is accurate.',
      );
    }
    youtubeStep = YouTubeConnectStep.review;
    clearMessages();
    notifyListeners();
    return true;
  }

  void backYouTubeStep() {
    youtubeStep = switch (youtubeStep) {
      YouTubeConnectStep.action => YouTubeConnectStep.source,
      YouTubeConnectStep.review => YouTubeConnectStep.action,
      YouTubeConnectStep.complete => YouTubeConnectStep.review,
      YouTubeConnectStep.source => YouTubeConnectStep.source,
    };
    clearMessages();
    notifyListeners();
  }

  Future<bool> publishYouTubeConnection() async {
    if (youtubeConnectedPostId != null) {
      noticeMessage =
          '$youtubeConnectedPostId is already published. No duplicate connection was created.';
      notifyListeners();
      return true;
    }
    if (youtubeStep != YouTubeConnectStep.review) {
      return _validation('Review the YouTube content and Mool action first.');
    }
    return _protected(
      operation: gateway.publishYouTubeConnection,
      success: () {
        youtubeConnectedPostId = 'YT-POST-166-0719';
        youtubeStep = YouTubeConnectStep.complete;
        noticeMessage =
            'Connected post published. The video stays on YouTube and the Mool action stays separate.';
      },
    );
  }

  void restartYouTubeConnect() {
    youtubeStep = YouTubeConnectStep.source;
    youtubeUrl = '';
    youtubeValidated = false;
    youtubeValidationId = null;
    youtubeAction = '';
    youtubeRightsConfirmed = false;
    youtubeActionTruthConfirmed = false;
    youtubeConnectedPostId = null;
    clearMessages();
    notifyListeners();
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
      return _validation('You are offline. Reconnect and retry this action.');
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
    } on CreatorGatewayException catch (error) {
      errorMessage = error.message;
      noticeMessage = null;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
