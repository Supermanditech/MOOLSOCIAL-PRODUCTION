import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_adjacent_promotion_policy.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_public_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('C29Q production delivery stays disabled for a complete campaign', () {
    const policy = YouTubeAdjacentPromotionPolicy.production();
    expect(
      policy.evaluate(_eligible()).code,
      YouTubePromotionDecisionCode.productionDisabled,
    );
  });

  test(
    'C29Q denies every YouTube-owned surface even when delivery is enabled',
    () {
      const policy = YouTubeAdjacentPromotionPolicy.forPolicyTest(
        deliveryEnabled: true,
      );
      for (final surface in YouTubePromotionSurface.values.where(
        (value) =>
            value != YouTubePromotionSurface.moolSocialIndependentAdjacent,
      )) {
        final decision = policy.evaluate(_eligible(surface: surface));
        expect(
          decision.code,
          YouTubePromotionDecisionCode.youtubeOwnedSurface,
          reason: surface.name,
        );
      }
    },
  );

  test('C29Q requires every independent-value activation dependency', () {
    const policy = YouTubeAdjacentPromotionPolicy.forPolicyTest(
      deliveryEnabled: true,
    );
    final cases =
        <YouTubeAdjacentPromotionCandidate, YouTubePromotionDecisionCode>{
          _eligible(hasRealCampaignOwner: false):
              YouTubePromotionDecisionCode.campaignOwnerMissing,
          _eligible(hasCreatorVideoProductRelationship: false):
              YouTubePromotionDecisionCode.relationshipMissing,
          _eligible(hasIndependentMoolSocialValue: false):
              YouTubePromotionDecisionCode.independentValueMissing,
          _eligible(disclosure: 'Sponsored'):
              YouTubePromotionDecisionCode.disclosureMissing,
          _eligible(outsidePlayerAndControls: false):
              YouTubePromotionDecisionCode.playerBoundaryInvalid,
          _eligible(incentivizesYouTubeEngagement: true):
              YouTubePromotionDecisionCode.engagementIncentiveForbidden,
          _eligible(legalApproved: false):
              YouTubePromotionDecisionCode.legalReviewMissing,
          _eligible(youtubeApiComplianceApproved: false):
              YouTubePromotionDecisionCode.youtubeApiReviewMissing,
          _eligible(remoteKillSwitchConfigured: false):
              YouTubePromotionDecisionCode.remoteKillSwitchMissing,
          _eligible(remoteDeliveryAllowed: false):
              YouTubePromotionDecisionCode.remoteDeliveryDisabled,
        };
    for (final entry in cases.entries) {
      expect(policy.evaluate(entry.key).code, entry.value);
    }
    expect(policy.evaluate(_eligible()).allowed, isTrue);
  });

  testWidgets('C29Q renders no promotion on YouTube Home Shorts or Watch', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    addTearDown(owners.dispose);

    for (final state in const [
      (subAction: 'videos', watch: false),
      (subAction: 'shorts', watch: false),
      (subAction: 'videos', watch: true),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: owners.consumer(state.subAction, watch: state.watch),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Promoted on MoolSocial'), findsNothing);
      expect(find.textContaining('Sponsored'), findsNothing);
      expect(find.textContaining('Advertisement'), findsNothing);
      expect(tester.takeException(), isNull, reason: '$state');
    }
  });

  test('C29Q YouTube surface owners contain no visible promotion copy', () {
    for (final owner in const [
      'lib/ui_v2/social/social_v2_consumer.dart',
      'lib/core/youtube/youtube_embedded_player_android.dart',
      'lib/core/youtube/youtube_embedded_player_contract.dart',
      'lib/core/youtube/youtube_embedded_player_controller.dart',
    ]) {
      final source = File(owner).readAsStringSync();
      expect(source, isNot(contains('Promoted on MoolSocial')), reason: owner);
      expect(source, isNot(contains('Advertisement')), reason: owner);
    }
  });
}

YouTubeAdjacentPromotionCandidate _eligible({
  YouTubePromotionSurface surface =
      YouTubePromotionSurface.moolSocialIndependentAdjacent,
  bool hasRealCampaignOwner = true,
  bool hasCreatorVideoProductRelationship = true,
  bool hasIndependentMoolSocialValue = true,
  String disclosure = 'Promoted on MoolSocial',
  bool outsidePlayerAndControls = true,
  bool incentivizesYouTubeEngagement = false,
  bool legalApproved = true,
  bool youtubeApiComplianceApproved = true,
  bool remoteKillSwitchConfigured = true,
  bool remoteDeliveryAllowed = true,
}) => YouTubeAdjacentPromotionCandidate(
  surface: surface,
  hasRealCampaignOwner: hasRealCampaignOwner,
  hasCreatorVideoProductRelationship: hasCreatorVideoProductRelationship,
  hasIndependentMoolSocialValue: hasIndependentMoolSocialValue,
  disclosure: disclosure,
  outsidePlayerAndControls: outsidePlayerAndControls,
  incentivizesYouTubeEngagement: incentivizesYouTubeEngagement,
  legalApproved: legalApproved,
  youtubeApiComplianceApproved: youtubeApiComplianceApproved,
  remoteKillSwitchConfigured: remoteKillSwitchConfigured,
  remoteDeliveryAllowed: remoteDeliveryAllowed,
);

class _Owners {
  final journey = JourneySession();
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession();

  SocialUniversalV2 consumer(String subAction, {required bool watch}) =>
      SocialUniversalV2(
        session: journey,
        creatorSession: creator,
        retailerSession: retailer,
        sharedSession: shared,
        initialSubAction: subAction,
        initialState: watch ? 'video-watch' : null,
        initialItem: watch ? 'video-1' : null,
        youtubePublicAccessOverride: true,
        youtubeCreatorAccessOverride: false,
        youtubeVideosLoader: () async => [_video('video-1', 'PT4M')],
        youtubeShortsLoader: () async => [_video('short-1', 'PT30S')],
        youtubeCatalogueSnapshotStore: Screen04YouTubeCatalogueSnapshotStore(),
      );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}

Screen04YouTubePublicVideo _video(String id, String duration) =>
    Screen04YouTubePublicVideo(
      videoId: id,
      title: 'Provider title',
      channelId: 'channel-1',
      channelTitle: 'Provider channel',
      description: 'Provider description',
      thumbnailUrl: Uri.parse('https://i.ytimg.com/vi/$id/hqdefault.jpg'),
      publishedAt: DateTime.utc(2026, 8, 11),
      duration: duration,
      captionAvailable: true,
      viewCount: '100',
      likeCount: '10',
      commentCount: '1',
      embeddable: true,
      hasKnownDeviceRegionExclusion: false,
      hashtags: const ['#Shorts'],
    );
