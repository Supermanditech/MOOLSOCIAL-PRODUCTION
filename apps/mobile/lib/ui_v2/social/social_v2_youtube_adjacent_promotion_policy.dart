enum YouTubePromotionSurface {
  youtubeHome,
  youtubeWatch,
  youtubeShorts,
  youtubePlayer,
  youtubeThumbnail,
  moolSocialIndependentAdjacent,
}

enum YouTubePromotionDecisionCode {
  productionDisabled,
  youtubeOwnedSurface,
  campaignOwnerMissing,
  relationshipMissing,
  independentValueMissing,
  disclosureMissing,
  playerBoundaryInvalid,
  engagementIncentiveForbidden,
  legalReviewMissing,
  youtubeApiReviewMissing,
  remoteKillSwitchMissing,
  remoteDeliveryDisabled,
  eligible,
}

class YouTubeAdjacentPromotionCandidate {
  const YouTubeAdjacentPromotionCandidate({
    required this.surface,
    required this.hasRealCampaignOwner,
    required this.hasCreatorVideoProductRelationship,
    required this.hasIndependentMoolSocialValue,
    required this.disclosure,
    required this.outsidePlayerAndControls,
    required this.incentivizesYouTubeEngagement,
    required this.legalApproved,
    required this.youtubeApiComplianceApproved,
    required this.remoteKillSwitchConfigured,
    required this.remoteDeliveryAllowed,
  });

  final YouTubePromotionSurface surface;
  final bool hasRealCampaignOwner;
  final bool hasCreatorVideoProductRelationship;
  final bool hasIndependentMoolSocialValue;
  final String disclosure;
  final bool outsidePlayerAndControls;
  final bool incentivizesYouTubeEngagement;
  final bool legalApproved;
  final bool youtubeApiComplianceApproved;
  final bool remoteKillSwitchConfigured;
  final bool remoteDeliveryAllowed;
}

class YouTubePromotionDecision {
  const YouTubePromotionDecision(this.code);

  final YouTubePromotionDecisionCode code;

  bool get allowed => code == YouTubePromotionDecisionCode.eligible;
}

class YouTubeAdjacentPromotionPolicy {
  const YouTubeAdjacentPromotionPolicy._({required this.deliveryEnabled});

  const YouTubeAdjacentPromotionPolicy.production()
    : this._(deliveryEnabled: false);

  const YouTubeAdjacentPromotionPolicy.forPolicyTest({
    required bool deliveryEnabled,
  }) : this._(deliveryEnabled: deliveryEnabled);

  final bool deliveryEnabled;

  YouTubePromotionDecision evaluate(
    YouTubeAdjacentPromotionCandidate candidate,
  ) {
    if (!deliveryEnabled) {
      return const YouTubePromotionDecision(
        YouTubePromotionDecisionCode.productionDisabled,
      );
    }
    if (candidate.surface !=
        YouTubePromotionSurface.moolSocialIndependentAdjacent) {
      return const YouTubePromotionDecision(
        YouTubePromotionDecisionCode.youtubeOwnedSurface,
      );
    }
    if (!candidate.hasRealCampaignOwner) {
      return const YouTubePromotionDecision(
        YouTubePromotionDecisionCode.campaignOwnerMissing,
      );
    }
    if (!candidate.hasCreatorVideoProductRelationship) {
      return const YouTubePromotionDecision(
        YouTubePromotionDecisionCode.relationshipMissing,
      );
    }
    if (!candidate.hasIndependentMoolSocialValue) {
      return const YouTubePromotionDecision(
        YouTubePromotionDecisionCode.independentValueMissing,
      );
    }
    if (candidate.disclosure.trim() != 'Promoted on MoolSocial') {
      return const YouTubePromotionDecision(
        YouTubePromotionDecisionCode.disclosureMissing,
      );
    }
    if (!candidate.outsidePlayerAndControls) {
      return const YouTubePromotionDecision(
        YouTubePromotionDecisionCode.playerBoundaryInvalid,
      );
    }
    if (candidate.incentivizesYouTubeEngagement) {
      return const YouTubePromotionDecision(
        YouTubePromotionDecisionCode.engagementIncentiveForbidden,
      );
    }
    if (!candidate.legalApproved) {
      return const YouTubePromotionDecision(
        YouTubePromotionDecisionCode.legalReviewMissing,
      );
    }
    if (!candidate.youtubeApiComplianceApproved) {
      return const YouTubePromotionDecision(
        YouTubePromotionDecisionCode.youtubeApiReviewMissing,
      );
    }
    if (!candidate.remoteKillSwitchConfigured) {
      return const YouTubePromotionDecision(
        YouTubePromotionDecisionCode.remoteKillSwitchMissing,
      );
    }
    if (!candidate.remoteDeliveryAllowed) {
      return const YouTubePromotionDecision(
        YouTubePromotionDecisionCode.remoteDeliveryDisabled,
      );
    }
    return const YouTubePromotionDecision(
      YouTubePromotionDecisionCode.eligible,
    );
  }
}
