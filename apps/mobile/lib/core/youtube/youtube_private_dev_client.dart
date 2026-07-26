import 'dart:convert';
import 'dart:math';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'youtube_private_dev_app_check.dart';
import 'youtube_private_dev_models.dart';
import 'youtube_private_dev_transport.dart';

part 'youtube_private_dev_live_client.dart';

const youtubePrivateDevProviderUrl = String.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PROVIDER_URL',
);
const youtubePrivateDevAnalyticsV2ClientEnabled = bool.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_ANALYTICS_V2_CLIENT_ENABLED',
  defaultValue: false,
);
const youtubePrivateDevReportingV1ClientEnabled = bool.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_REPORTING_V1_CLIENT_ENABLED',
  defaultValue: false,
);
const youtubePrivateDevLiveClientEnabled = bool.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_LIVE_CLIENT_ENABLED',
  defaultValue: false,
);

enum YouTubeAppCheckTokenMode { standard, limitedUse }

abstract interface class YouTubeCredentialSource {
  Future<String> appCheckToken(YouTubeAppCheckTokenMode mode);

  Future<String> firebaseIdToken();
}

class FirebaseYouTubeCredentialSource implements YouTubeCredentialSource {
  FirebaseYouTubeCredentialSource({
    FirebaseAuth? auth,
    FirebaseAppCheck? appCheck,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _appCheck = appCheck ?? FirebaseAppCheck.instance;

  final FirebaseAuth _auth;
  final FirebaseAppCheck _appCheck;

  @override
  Future<String> appCheckToken(YouTubeAppCheckTokenMode mode) async {
    final token = switch (mode) {
      YouTubeAppCheckTokenMode.standard => await _appCheck.getToken(),
      YouTubeAppCheckTokenMode.limitedUse =>
        await _appCheck.getLimitedUseToken(),
    };
    if (token == null || token.isEmpty) {
      throw const YouTubeProviderClientException(
        code: 'app_verification_required',
        message: 'App verification is unavailable.',
      );
    }
    return token;
  }

  @override
  Future<String> firebaseIdToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const YouTubeProviderClientException(
        code: 'authentication_required',
        message: 'Sign in to continue.',
        statusCode: 401,
      );
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const YouTubeProviderClientException(
        code: 'authentication_required',
        message: 'Sign in to continue.',
        statusCode: 401,
      );
    }
    return token;
  }
}

class YouTubeProviderClientException implements Exception {
  const YouTubeProviderClientException({
    required this.code,
    required this.message,
    this.retryable = false,
    this.statusCode,
  });

  final String code;
  final String message;
  final bool retryable;
  final int? statusCode;

  @override
  String toString() => 'YouTubeProviderClientException($code, $message)';
}

class YouTubeEligibilityRequiredException
    extends YouTubeProviderClientException {
  const YouTubeEligibilityRequiredException({
    required super.message,
    super.retryable,
    super.statusCode,
  }) : super(code: 'eligibility_required');
}

class YouTubeCapabilityUnavailableException
    extends YouTubeProviderClientException {
  const YouTubeCapabilityUnavailableException({
    required super.message,
    super.retryable,
    super.statusCode,
  }) : super(code: 'capability_disabled');
}

class YouTubeStatusConflictException extends YouTubeProviderClientException {
  const YouTubeStatusConflictException({
    required super.message,
    super.retryable,
    super.statusCode,
  }) : super(code: 'status_conflict');
}

class YouTubeResourceUnavailableException
    extends YouTubeProviderClientException {
  const YouTubeResourceUnavailableException({
    required super.message,
    super.retryable,
    super.statusCode,
  }) : super(code: 'not_found');
}

class YouTubePrivateDevClient {
  @visibleForTesting
  factory YouTubePrivateDevClient.forTesting({
    required Uri providerEndpoint,
    required YouTubeHttpTransport transport,
    required YouTubeCredentialSource credentials,
    required bool proofEnabled,
    required String firebaseProjectId,
    bool analyticsV2Enabled = false,
    bool reportingV1Enabled = false,
    bool liveEnabled = false,
    String Function()? requestId,
  }) {
    _validateRuntimeBoundary(
      proofEnabled: proofEnabled,
      firebaseProjectId: firebaseProjectId,
    );
    return YouTubePrivateDevClient._(
      _validateEndpoint(providerEndpoint),
      transport,
      credentials,
      requestId ?? _secureRequestId,
      analyticsV2Enabled,
      reportingV1Enabled,
      liveEnabled,
    );
  }

  YouTubePrivateDevClient._(
    this._providerEndpoint,
    this._transport,
    this._credentials,
    this._requestId,
    this._analyticsV2Enabled,
    this._reportingV1Enabled,
    this._liveEnabled,
  );

  factory YouTubePrivateDevClient.fromBuildConfiguration({
    required YouTubeHttpTransport transport,
    YouTubeCredentialSource? credentials,
  }) {
    if (!youtubePrivateDevProofEnabled) {
      throw StateError(
        'The YouTube provider client is available only in private Dev proof.',
      );
    }
    _validateRuntimeBoundary(
      proofEnabled: true,
      firebaseProjectId: Firebase.app().options.projectId,
    );
    final uri = Uri.tryParse(youtubePrivateDevProviderUrl);
    if (uri == null) {
      throw StateError('The YouTube private Dev provider URL is invalid.');
    }
    return YouTubePrivateDevClient._(
      _validateEndpoint(uri),
      transport,
      credentials ?? FirebaseYouTubeCredentialSource(),
      _secureRequestId,
      youtubePrivateDevAnalyticsV2ClientEnabled,
      youtubePrivateDevReportingV1ClientEnabled,
      youtubePrivateDevLiveClientEnabled,
    );
  }

  final Uri _providerEndpoint;
  final YouTubeHttpTransport _transport;
  final YouTubeCredentialSource _credentials;
  final String Function() _requestId;
  final bool _analyticsV2Enabled;
  final bool _reportingV1Enabled;
  final bool _liveEnabled;

  Future<YouTubePrivateDevCapabilities> capabilities() async {
    final data = await _invoke('capabilities');
    return YouTubePrivateDevCapabilities.fromJson(_asMap(data));
  }

  Future<YouTubeVideoPage> mostPopular({
    String? regionCode,
    String? pageToken,
  }) async {
    final data = await _invoke(
      'publicMostPopular',
      body: <String, Object?>{
        'regionCode': ?regionCode,
        'pageToken': ?pageToken,
      },
    );
    return YouTubeVideoPage.fromJson(_asMap(data));
  }

  Future<YouTubeVideoPage> playlist({
    required String playlistId,
    String? pageToken,
  }) async {
    final data = await _invoke(
      'publicPlaylist',
      body: <String, Object?>{
        'playlistId': playlistId,
        'pageToken': ?pageToken,
      },
    );
    return YouTubeVideoPage.fromJson(_asMap(data));
  }

  Future<YouTubeVideoPage> search({
    required String query,
    String? pageToken,
  }) async {
    final data = await _invoke(
      'publicSearch',
      body: <String, Object?>{'query': query, 'pageToken': ?pageToken},
    );
    return YouTubeVideoPage.fromJson(_asMap(data));
  }

  Future<List<YouTubeVideoSummary>> videoDetails(List<String> videoIds) async {
    final data = await _invoke(
      'publicVideoDetails',
      body: <String, Object?>{'videoIds': videoIds},
    );
    return _asList(
      data,
    ).map(_asMap).map(YouTubeVideoSummary.fromJson).toList(growable: false);
  }

  Future<YouTubeBatchStatisticsResult> batchVideoStatistics(
    List<String> videoIds,
  ) async {
    final data = await _invoke(
      'publicBatchVideoStatistics',
      body: <String, Object?>{'videoIds': videoIds},
    );
    return YouTubeBatchStatisticsResult.fromJson(_asMap(data));
  }

  Future<YouTubePublicChannelDetails> channelDetails({
    required String channelId,
  }) async {
    final data = await _invoke(
      'publicChannelDetails',
      body: <String, Object?>{'channelId': channelId},
    );
    return YouTubePublicChannelDetails.fromJson(_asMap(data));
  }

  Future<YouTubePublicChannelDetails> channelByHandle({
    required String handle,
  }) async {
    final data = await _invoke(
      'publicChannelByHandle',
      body: <String, Object?>{'handle': handle},
    );
    return YouTubePublicChannelDetails.fromJson(_asMap(data));
  }

  Future<YouTubePublicPlaylistDetails> playlistDetails({
    required String playlistId,
  }) async {
    final data = await _invoke(
      'publicPlaylistDetails',
      body: <String, Object?>{'playlistId': playlistId},
    );
    return YouTubePublicPlaylistDetails.fromJson(_asMap(data));
  }

  Future<YouTubePublicPlaylistPage> channelPlaylists({
    required String channelId,
    String? pageToken,
    int? maxResults,
  }) async {
    final data = await _invoke(
      'publicChannelPlaylists',
      body: <String, Object?>{
        'channelId': channelId,
        'pageToken': ?pageToken,
        'maxResults': ?maxResults,
      },
    );
    return YouTubePublicPlaylistPage.fromJson(_asMap(data));
  }

  Future<List<YouTubePublicRegion>> regions() async {
    final data = await _invoke('publicRegions');
    return _asList(
      data,
    ).map(_asMap).map(YouTubePublicRegion.fromJson).toList(growable: false);
  }

  Future<List<YouTubePublicLanguage>> languages() async {
    final data = await _invoke('publicLanguages');
    return _asList(
      data,
    ).map(_asMap).map(YouTubePublicLanguage.fromJson).toList(growable: false);
  }

  Future<List<YouTubePublicVideoCategory>> videoCategories({
    String? regionCode,
  }) async {
    final data = await _invoke(
      'publicVideoCategories',
      body: <String, Object?>{'regionCode': ?regionCode},
    );
    return _asList(data)
        .map(_asMap)
        .map(YouTubePublicVideoCategory.fromJson)
        .toList(growable: false);
  }

  Future<YouTubePublicCommentThreadsPage> commentThreads({
    required String videoId,
    String? regionCode,
    String? pageToken,
    int? maxResults,
    YouTubeCommentOrder? order,
  }) async {
    final data = await _invoke(
      'publicCommentThreads',
      body: <String, Object?>{
        'videoId': videoId,
        'regionCode': ?regionCode,
        'pageToken': ?pageToken,
        'maxResults': ?maxResults,
        'order': ?order?.wireValue,
      },
    );
    return YouTubePublicCommentThreadsPage.fromJson(_asMap(data));
  }

  Future<YouTubePublicCommentRepliesPage> commentReplies({
    required String videoId,
    required String threadId,
    required String parentCommentId,
    String? regionCode,
    String? pageToken,
    int? maxResults,
  }) async {
    final data = await _invoke(
      'publicCommentReplies',
      body: <String, Object?>{
        'videoId': videoId,
        'threadId': threadId,
        'parentCommentId': parentCommentId,
        'regionCode': ?regionCode,
        'pageToken': ?pageToken,
        'maxResults': ?maxResults,
      },
    );
    return YouTubePublicCommentRepliesPage.fromJson(_asMap(data));
  }

  Future<YouTubePublicChannelActivitiesPage> channelActivities({
    required String channelId,
    String? regionCode,
    String? pageToken,
    DateTime? publishedAfter,
    DateTime? publishedBefore,
    int? maxResults,
    List<YouTubePublicActivityType>? eventTypes,
  }) async {
    final data = await _invoke(
      'publicChannelActivities',
      body: <String, Object?>{
        'channelId': channelId,
        'regionCode': ?regionCode,
        'pageToken': ?pageToken,
        'publishedAfter': ?publishedAfter?.toUtc().toIso8601String(),
        'publishedBefore': ?publishedBefore?.toUtc().toIso8601String(),
        'maxResults': ?maxResults,
        'eventTypes': ?eventTypes
            ?.map((type) => type.name)
            .toList(growable: false),
      },
    );
    return YouTubePublicChannelActivitiesPage.fromJson(_asMap(data));
  }

  Future<YouTubePublicChannelSectionsResult> channelSections({
    required String channelId,
  }) async {
    final data = await _invoke(
      'publicChannelSections',
      body: <String, Object?>{'channelId': channelId},
    );
    return YouTubePublicChannelSectionsResult.fromJson(_asMap(data));
  }

  Future<YouTubeConnectionStatus> connectionStatus() async {
    final data = await _invoke('ownerConnectionStatus', authenticated: true);
    return YouTubeConnectionStatus.fromJson(_asMap(data));
  }

  Future<YouTubeConnectionStart> startConnection({
    required YouTubeConnectPurpose purpose,
    bool? promptForConsent,
  }) async {
    final data = await _invoke(
      'beginConnect',
      authenticated: true,
      limitedUseAppCheck: true,
      body: <String, Object?>{
        'purpose': purpose.wireValue,
        'promptForConsent': ?promptForConsent,
      },
    );
    return YouTubeConnectionStart.fromJson(_asMap(data));
  }

  Future<YouTubeOwnerVideosPage> ownerVideos({
    String? pageToken,
    int? maxResults,
  }) async {
    final data = await _invoke(
      'ownerVideos',
      authenticated: true,
      body: <String, Object?>{
        'pageToken': ?pageToken,
        'maxResults': ?maxResults,
      },
    );
    return YouTubeOwnerVideosPage.fromJson(_asMap(data));
  }

  Future<YouTubeOwnerSubscriptionsPage> ownerSubscriptions({
    String? pageToken,
    int? maxResults,
    YouTubeOwnerSubscriptionOrder? order,
  }) async {
    final data = await _invoke(
      'ownerSubscriptions',
      authenticated: true,
      body: <String, Object?>{
        'pageToken': ?pageToken,
        'maxResults': ?maxResults,
        'order': ?order?.wireValue,
      },
    );
    return YouTubeOwnerSubscriptionsPage.fromJson(_asMap(data));
  }

  Future<YouTubeOwnerPlaylistsPage> ownerPlaylists({
    String? pageToken,
    int? maxResults,
  }) async {
    final data = await _invoke(
      'ownerPlaylists',
      authenticated: true,
      body: <String, Object?>{
        'pageToken': ?pageToken,
        'maxResults': ?maxResults,
      },
    );
    return YouTubeOwnerPlaylistsPage.fromJson(_asMap(data));
  }

  Future<YouTubeOwnerRatingResult> ownerGetRating({
    required String videoId,
  }) async {
    final data = await _ownerMutation(
      'ownerGetRating',
      body: <String, Object?>{'videoId': videoId},
    );
    return YouTubeOwnerRatingResult.fromJson(_asMap(data));
  }

  Future<YouTubeOwnerRatingResult> ownerSetRating({
    required String videoId,
    required YouTubeOwnerRating rating,
  }) async {
    if (rating == YouTubeOwnerRating.none) {
      throw ArgumentError.value(rating, 'rating', 'must be like or dislike');
    }
    final data = await _ownerMutation(
      'ownerSetRating',
      body: <String, Object?>{'videoId': videoId, 'rating': rating.wireValue},
    );
    return YouTubeOwnerRatingResult.fromJson(_asMap(data));
  }

  Future<YouTubeOwnerRatingResult> ownerRemoveRating({
    required String videoId,
  }) async {
    final data = await _ownerMutation(
      'ownerRemoveRating',
      body: <String, Object?>{'videoId': videoId},
    );
    return YouTubeOwnerRatingResult.fromJson(_asMap(data));
  }

  Future<YouTubeOwnerCommentMutation> ownerCreateComment({
    required String videoId,
    required String text,
  }) async {
    final data = await _ownerMutation(
      'ownerCreateComment',
      body: <String, Object?>{'videoId': videoId, 'text': text},
    );
    return YouTubeOwnerCommentMutation.fromJson(_asMap(data));
  }

  Future<YouTubeOwnerCommentMutation> ownerCreateReply({
    required String parentCommentId,
    required String text,
  }) async {
    final data = await _ownerMutation(
      'ownerCreateReply',
      body: <String, Object?>{'parentCommentId': parentCommentId, 'text': text},
    );
    return YouTubeOwnerCommentMutation.fromJson(_asMap(data));
  }

  Future<YouTubeOwnerCommentMutation> ownerUpdateComment({
    required String commentId,
    required String text,
  }) async {
    final data = await _ownerMutation(
      'ownerUpdateComment',
      body: <String, Object?>{'commentId': commentId, 'text': text},
    );
    return YouTubeOwnerCommentMutation.fromJson(_asMap(data));
  }

  Future<YouTubeDeleteResult> ownerDeleteComment({
    required String commentId,
  }) async {
    final data = await _ownerMutation(
      'ownerDeleteComment',
      body: <String, Object?>{'commentId': commentId},
    );
    return YouTubeDeleteResult.fromJson(
      _asMap(data),
      identifierKey: 'commentId',
    );
  }

  Future<YouTubeOwnerCommentModerationResult> ownerSetCommentModeration({
    required String commentId,
    required YouTubeOwnerCommentModerationStatus moderationStatus,
    bool? banAuthor,
  }) async {
    final data = await _ownerMutation(
      'ownerSetCommentModeration',
      body: <String, Object?>{
        'commentId': commentId,
        'moderationStatus': moderationStatus.wireValue,
        'banAuthor': ?banAuthor,
      },
    );
    return YouTubeOwnerCommentModerationResult.fromJson(_asMap(data));
  }

  Future<YouTubeOwnerSubscriptionMutation> ownerSubscribe({
    required String channelId,
  }) async {
    final data = await _ownerMutation(
      'ownerSubscribe',
      body: <String, Object?>{'channelId': channelId},
    );
    return YouTubeOwnerSubscriptionMutation.fromJson(_asMap(data));
  }

  Future<YouTubeDeleteResult> ownerUnsubscribe({
    required String subscriptionId,
  }) async {
    final data = await _ownerMutation(
      'ownerUnsubscribe',
      body: <String, Object?>{'subscriptionId': subscriptionId},
    );
    return YouTubeDeleteResult.fromJson(
      _asMap(data),
      identifierKey: 'subscriptionId',
    );
  }

  Future<YouTubeOwnerPlaylistMutation> ownerCreatePlaylist({
    required String title,
    required YouTubePlaylistPrivacyStatus privacyStatus,
    String description = '',
  }) async {
    final data = await _ownerMutation(
      'ownerCreatePlaylist',
      body: <String, Object?>{
        'title': title,
        'description': description,
        'privacyStatus': privacyStatus.wireValue,
      },
    );
    return YouTubeOwnerPlaylistMutation.fromJson(_asMap(data));
  }

  Future<YouTubeOwnerPlaylistMutation> ownerUpdatePlaylist({
    required String playlistId,
    required String title,
    required YouTubePlaylistPrivacyStatus privacyStatus,
    String description = '',
  }) async {
    final data = await _ownerMutation(
      'ownerUpdatePlaylist',
      body: <String, Object?>{
        'playlistId': playlistId,
        'title': title,
        'description': description,
        'privacyStatus': privacyStatus.wireValue,
      },
    );
    return YouTubeOwnerPlaylistMutation.fromJson(_asMap(data));
  }

  Future<YouTubeDeleteResult> ownerDeletePlaylist({
    required String playlistId,
  }) async {
    final data = await _ownerMutation(
      'ownerDeletePlaylist',
      body: <String, Object?>{'playlistId': playlistId},
    );
    return YouTubeDeleteResult.fromJson(
      _asMap(data),
      identifierKey: 'playlistId',
    );
  }

  Future<YouTubeOwnerPlaylistItemMutation> ownerCreatePlaylistItem({
    required String playlistId,
    required String videoId,
    int? position,
  }) async {
    final data = await _ownerMutation(
      'ownerCreatePlaylistItem',
      body: <String, Object?>{
        'playlistId': playlistId,
        'videoId': videoId,
        'position': ?position,
      },
    );
    return YouTubeOwnerPlaylistItemMutation.fromJson(_asMap(data));
  }

  Future<YouTubeOwnerPlaylistItemMutation> ownerReorderPlaylistItem({
    required String playlistItemId,
    required int position,
  }) async {
    final data = await _ownerMutation(
      'ownerReorderPlaylistItem',
      body: <String, Object?>{
        'playlistItemId': playlistItemId,
        'position': position,
      },
    );
    return YouTubeOwnerPlaylistItemMutation.fromJson(_asMap(data));
  }

  Future<YouTubeDeleteResult> ownerDeletePlaylistItem({
    required String playlistItemId,
  }) async {
    final data = await _ownerMutation(
      'ownerDeletePlaylistItem',
      body: <String, Object?>{'playlistItemId': playlistItemId},
    );
    return YouTubeDeleteResult.fromJson(
      _asMap(data),
      identifierKey: 'playlistItemId',
    );
  }

  Future<YouTubeOwnerVideoMetadataMutation> ownerUpdateVideoMetadata({
    required String videoId,
    required String title,
    required String categoryId,
    String description = '',
    List<String>? tags,
  }) async {
    final data = await _ownerMutation(
      'ownerUpdateVideoMetadata',
      body: <String, Object?>{
        'videoId': videoId,
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'tags': ?tags,
      },
    );
    return YouTubeOwnerVideoMetadataMutation.fromJson(_asMap(data));
  }

  Future<YouTubeDeleteResult> ownerDeleteVideo({
    required String videoId,
    required String confirmVideoId,
  }) async {
    final data = await _ownerMutation(
      'ownerDeleteVideo',
      body: <String, Object?>{
        'videoId': videoId,
        'confirmVideoId': confirmVideoId,
      },
    );
    return YouTubeDeleteResult.fromJson(_asMap(data), identifierKey: 'videoId');
  }

  Future<YouTubeDirectAssetUploadSession> creatorBeginThumbnailSet({
    required String videoId,
    required String contentType,
    required int contentLength,
  }) async {
    final data = await _ownerMutation(
      'creatorBeginThumbnailSet',
      body: <String, Object?>{
        'videoId': videoId,
        'contentType': contentType,
        'contentLength': contentLength,
      },
    );
    return YouTubeDirectAssetUploadSession.fromJson(_asMap(data));
  }

  Future<YouTubeCreatorCaptionsResult> creatorListCaptions({
    required String videoId,
  }) async {
    final data = await _ownerMutation(
      'creatorListCaptions',
      body: <String, Object?>{'videoId': videoId},
    );
    return YouTubeCreatorCaptionsResult.fromJson(_asMap(data));
  }

  Future<YouTubeCreatorCaptionDownload> creatorDownloadCaption({
    required String videoId,
    required String captionId,
    required YouTubeCaptionFormat format,
    String? translatedLanguage,
  }) async {
    final data = await _ownerMutation(
      'creatorDownloadCaption',
      body: <String, Object?>{
        'videoId': videoId,
        'captionId': captionId,
        'format': format.wireValue,
        'translatedLanguage': ?translatedLanguage,
      },
    );
    return YouTubeCreatorCaptionDownload.fromJson(_asMap(data));
  }

  Future<YouTubeDirectAssetUploadSession> creatorBeginCaptionInsert({
    required String videoId,
    required String language,
    required bool isDraft,
    required String contentType,
    required int contentLength,
    String name = '',
  }) async {
    final data = await _ownerMutation(
      'creatorBeginCaptionInsert',
      body: <String, Object?>{
        'videoId': videoId,
        'language': language,
        'name': name,
        'isDraft': isDraft,
        'contentType': contentType,
        'contentLength': contentLength,
      },
    );
    return YouTubeDirectAssetUploadSession.fromJson(_asMap(data));
  }

  Future<YouTubeCreatorCaption> creatorUpdateCaptionDraft({
    required String videoId,
    required String captionId,
    required bool isDraft,
  }) async {
    final data = await _ownerMutation(
      'creatorUpdateCaptionDraft',
      body: <String, Object?>{
        'videoId': videoId,
        'captionId': captionId,
        'isDraft': isDraft,
      },
    );
    return YouTubeCreatorCaption.fromJson(_asMap(data));
  }

  Future<YouTubeDirectAssetUploadSession> creatorBeginCaptionReplacement({
    required String videoId,
    required String captionId,
    required bool isDraft,
    required String contentType,
    required int contentLength,
  }) async {
    final data = await _ownerMutation(
      'creatorBeginCaptionReplacement',
      body: <String, Object?>{
        'videoId': videoId,
        'captionId': captionId,
        'isDraft': isDraft,
        'contentType': contentType,
        'contentLength': contentLength,
      },
    );
    return YouTubeDirectAssetUploadSession.fromJson(_asMap(data));
  }

  Future<YouTubeDeleteResult> creatorDeleteCaption({
    required String videoId,
    required String captionId,
  }) async {
    final data = await _ownerMutation(
      'creatorDeleteCaption',
      body: <String, Object?>{'videoId': videoId, 'captionId': captionId},
    );
    return YouTubeDeleteResult.fromJson(
      _asMap(data),
      identifierKey: 'captionId',
    );
  }

  Future<YouTubeChannelBrandingUpdate> creatorUpdateChannelBranding({
    required YouTubeChannelBrandingPatch patch,
  }) async {
    final data = await _ownerMutation(
      'creatorUpdateChannelBranding',
      body: <String, Object?>{'patch': patch.toJson()},
    );
    return YouTubeChannelBrandingUpdate.fromJson(_asMap(data));
  }

  Future<YouTubeChannelSectionsResult> creatorListChannelSections() async {
    final data = await _ownerMutation('creatorListChannelSections');
    return YouTubeChannelSectionsResult.fromJson(_asMap(data));
  }

  Future<YouTubeChannelSection> creatorInsertChannelSection({
    required YouTubeChannelSectionInput section,
  }) async {
    final data = await _ownerMutation(
      'creatorInsertChannelSection',
      body: <String, Object?>{'section': section.toJson()},
    );
    return YouTubeChannelSection.fromJson(_asMap(data));
  }

  Future<YouTubeChannelSection> creatorUpdateChannelSection({
    required String sectionId,
    required YouTubeChannelSectionInput section,
  }) async {
    final data = await _ownerMutation(
      'creatorUpdateChannelSection',
      body: <String, Object?>{
        'sectionId': sectionId,
        'section': section.toJson(),
      },
    );
    return YouTubeChannelSection.fromJson(_asMap(data));
  }

  Future<YouTubeDeleteResult> creatorDeleteChannelSection({
    required String sectionId,
  }) async {
    final data = await _ownerMutation(
      'creatorDeleteChannelSection',
      body: <String, Object?>{'sectionId': sectionId},
    );
    return YouTubeDeleteResult.fromJson(
      _asMap(data),
      identifierKey: 'sectionId',
    );
  }

  Future<YouTubeDirectAssetUploadSession> creatorBeginChannelBannerInsert({
    required String contentType,
    required int contentLength,
    required int width,
    required int height,
  }) async {
    final data = await _ownerMutation(
      'creatorBeginChannelBannerInsert',
      body: <String, Object?>{
        'contentType': contentType,
        'contentLength': contentLength,
        'width': width,
        'height': height,
      },
    );
    return YouTubeDirectAssetUploadSession.fromJson(_asMap(data));
  }

  Future<YouTubeChannelAssetAction> creatorApplyChannelBanner({
    required String bannerExternalUrl,
  }) async {
    final data = await _ownerMutation(
      'creatorApplyChannelBanner',
      body: <String, Object?>{'bannerExternalUrl': bannerExternalUrl},
    );
    return YouTubeChannelAssetAction.bannerApplied(_asMap(data));
  }

  Future<YouTubeDirectAssetUploadSession> creatorBeginWatermarkSet({
    required String contentType,
    required int contentLength,
    required int width,
    required int height,
    required int offsetMs,
    required int durationMs,
    required YouTubeWatermarkOffsetFrom offsetFrom,
    required YouTubeWatermarkCorner corner,
  }) async {
    final data = await _ownerMutation(
      'creatorBeginWatermarkSet',
      body: <String, Object?>{
        'contentType': contentType,
        'contentLength': contentLength,
        'width': width,
        'height': height,
        'offsetMs': offsetMs,
        'durationMs': durationMs,
        'offsetFrom': offsetFrom.wireValue,
        'corner': corner.wireValue,
      },
    );
    return YouTubeDirectAssetUploadSession.fromJson(_asMap(data));
  }

  Future<YouTubeChannelAssetAction> creatorUnsetWatermark() async {
    final data = await _ownerMutation('creatorUnsetWatermark');
    return YouTubeChannelAssetAction.watermarkUnset(_asMap(data));
  }

  Future<YouTubePlaylistImagesResult> creatorListPlaylistImages({
    required String playlistId,
    String? pageToken,
    int? maxResults,
  }) async {
    final data = await _ownerMutation(
      'creatorListPlaylistImages',
      body: <String, Object?>{
        'playlistId': playlistId,
        'pageToken': ?pageToken,
        'maxResults': ?maxResults,
      },
    );
    return YouTubePlaylistImagesResult.fromJson(_asMap(data));
  }

  Future<YouTubeDirectAssetUploadSession> creatorBeginPlaylistImageInsert({
    required String playlistId,
    required String contentType,
    required int contentLength,
    required int width,
    required int height,
  }) async {
    final data = await _ownerMutation(
      'creatorBeginPlaylistImageInsert',
      body: <String, Object?>{
        'playlistId': playlistId,
        'contentType': contentType,
        'contentLength': contentLength,
        'width': width,
        'height': height,
      },
    );
    return YouTubeDirectAssetUploadSession.fromJson(_asMap(data));
  }

  Future<YouTubeDirectAssetUploadSession> creatorBeginPlaylistImageUpdate({
    required String playlistId,
    required String playlistImageId,
    required String contentType,
    required int contentLength,
    required int width,
    required int height,
  }) async {
    final data = await _ownerMutation(
      'creatorBeginPlaylistImageUpdate',
      body: <String, Object?>{
        'playlistId': playlistId,
        'playlistImageId': playlistImageId,
        'contentType': contentType,
        'contentLength': contentLength,
        'width': width,
        'height': height,
      },
    );
    return YouTubeDirectAssetUploadSession.fromJson(_asMap(data));
  }

  Future<YouTubeDeleteResult> creatorDeletePlaylistImage({
    required String playlistId,
    required String playlistImageId,
  }) async {
    final data = await _ownerMutation(
      'creatorDeletePlaylistImage',
      body: <String, Object?>{
        'playlistId': playlistId,
        'playlistImageId': playlistImageId,
      },
    );
    return YouTubeDeleteResult.fromJson(
      _asMap(data),
      identifierKey: 'playlistImageId',
      parentIdentifierKey: 'playlistId',
    );
  }

  Future<YouTubeAbuseReasonsResult> creatorListVideoAbuseReasons({
    String? language,
  }) async {
    final data = await _ownerMutation(
      'creatorListVideoAbuseReasons',
      body: <String, Object?>{'language': ?language},
    );
    return YouTubeAbuseReasonsResult.fromJson(_asMap(data));
  }

  Future<YouTubeAbuseReportResult> creatorReportVideoAbuse({
    required String videoId,
    required String reasonId,
    required String confirmVideoId,
    required String confirmReasonId,
    String? secondaryReasonId,
    String? comments,
    String? language,
  }) async {
    final data = await _ownerMutation(
      'creatorReportVideoAbuse',
      body: <String, Object?>{
        'videoId': videoId,
        'reasonId': reasonId,
        'confirmVideoId': confirmVideoId,
        'confirmReasonId': confirmReasonId,
        'secondaryReasonId': ?secondaryReasonId,
        'comments': ?comments,
        'language': ?language,
      },
    );
    return YouTubeAbuseReportResult.fromJson(_asMap(data));
  }

  Future<YouTubeGeneralAbuseReportResult> creatorInsertAbuseReport({
    required String subjectTypeId,
    required String subjectId,
    required List<String> abuseTypeIds,
    required String confirmSubjectTypeId,
    required String confirmSubjectId,
    required List<String> confirmAbuseTypeIds,
    String? description,
    List<Map<String, String>>? relatedEntities,
  }) async {
    final data = await _ownerMutation(
      'creatorInsertAbuseReport',
      body: <String, Object?>{
        'subjectTypeId': subjectTypeId,
        'subjectId': subjectId,
        'abuseTypeIds': abuseTypeIds,
        'confirmSubjectTypeId': confirmSubjectTypeId,
        'confirmSubjectId': confirmSubjectId,
        'confirmAbuseTypeIds': confirmAbuseTypeIds,
        'description': ?description,
        'relatedEntities': ?relatedEntities,
      },
    );
    return YouTubeGeneralAbuseReportResult.fromJson(_asMap(data));
  }

  Future<YouTubePrivateUploadSession> beginPrivateUpload({
    required String idempotencyKey,
    required YouTubeUploadFileIdentity fileIdentity,
    required YouTubePrivateUploadMetadata metadata,
  }) async {
    final data = await _invoke(
      'beginPrivateUpload',
      authenticated: true,
      limitedUseAppCheck: true,
      body: <String, Object?>{
        'idempotencyKey': idempotencyKey,
        'contentType': fileIdentity.contentType,
        'contentLength': fileIdentity.byteLength,
        'fileIdentity': fileIdentity.toJson(),
        'metadata': metadata.toJson(),
      },
    );
    return YouTubePrivateUploadSession.fromJson(
      _asMap(data),
      contentType: fileIdentity.contentType,
      contentLength: fileIdentity.byteLength,
      fileIdentity: fileIdentity,
    );
  }

  Future<YouTubeVideoSummary> reconcileUpload(String jobKey) async {
    final data = await _invoke(
      'reconcileUpload',
      authenticated: true,
      limitedUseAppCheck: true,
      body: <String, Object?>{'jobKey': jobKey},
    );
    return YouTubeVideoSummary.fromJson(_asMap(data));
  }

  Future<YouTubeVideoSummary> pollUpload({
    required String jobKey,
    int maximumAttempts = 12,
    Duration interval = const Duration(seconds: 5),
    Future<void> Function(Duration duration)? delay,
  }) async {
    if (maximumAttempts < 1) {
      throw ArgumentError.value(
        maximumAttempts,
        'maximumAttempts',
        'must be at least one',
      );
    }
    final wait = delay ?? Future<void>.delayed;
    for (var attempt = 0; attempt < maximumAttempts; attempt += 1) {
      try {
        final latest = await reconcileUpload(jobKey);
        switch (latest.processingOutcome) {
          case YouTubeUploadProcessingOutcome.succeeded:
            return latest;
          case YouTubeUploadProcessingOutcome.terminalFailure:
            throw const YouTubeProviderClientException(
              code: 'upload_processing_failed',
              message:
                  'YouTube could not finish processing the uploaded video.',
            );
          case YouTubeUploadProcessingOutcome.invalid:
            throw const YouTubeProviderClientException(
              code: 'invalid_provider_response',
              message: 'YouTube returned an unknown upload status.',
            );
          case YouTubeUploadProcessingOutcome.pending:
            break;
        }
      } on YouTubeProviderClientException catch (error) {
        if (!error.retryable || attempt == maximumAttempts - 1) rethrow;
      }
      if (attempt < maximumAttempts - 1) await wait(interval);
    }
    throw const YouTubeProviderClientException(
      code: 'upload_processing_timeout',
      message: 'The uploaded video is still processing.',
      retryable: true,
    );
  }

  Future<YouTubeAnalyticsV2GroupsPage> analyticsV2ListGroups({
    String? groupId,
    String? pageToken,
  }) async {
    _requireAnalyticsV2Enabled();
    final request = YouTubeAnalyticsV2GroupsRequest(
      groupId: groupId,
      pageToken: pageToken,
    );
    final data = await _ownerMutation(
      'analyticsV2ListGroups',
      body: request.toJson(),
    );
    final page = YouTubeAnalyticsV2GroupsPage.fromJson(_asMap(data));
    if (request.groupId case final groupId?) {
      if (page.items.length > 1 ||
          (page.items.isNotEmpty && page.items.single.groupId != groupId)) {
        throw const FormatException(
          'The provider returned a different analytics group.',
        );
      }
    }
    return page;
  }

  Future<YouTubeAnalyticsV2Group> analyticsV2CreateGroup({
    required String idempotencyKey,
    required String title,
    required YouTubeAnalyticsV2GroupItemType itemType,
  }) async {
    _requireAnalyticsV2Enabled();
    final request = YouTubeAnalyticsV2CreateGroupRequest(
      idempotencyKey: idempotencyKey,
      title: title,
      itemType: itemType,
    );
    final data = await _ownerMutation(
      'analyticsV2CreateGroup',
      body: request.toJson(),
    );
    final group = YouTubeAnalyticsV2Group.fromJson(_asMap(data));
    if (group.itemType != request.itemType) {
      throw const FormatException(
        'The provider returned a different analytics group type.',
      );
    }
    return group;
  }

  Future<YouTubeAnalyticsV2Group> analyticsV2UpdateGroup({
    required String idempotencyKey,
    required String groupId,
    required String title,
  }) async {
    _requireAnalyticsV2Enabled();
    final request = YouTubeAnalyticsV2UpdateGroupRequest(
      idempotencyKey: idempotencyKey,
      groupId: groupId,
      title: title,
    );
    final data = await _ownerMutation(
      'analyticsV2UpdateGroup',
      body: request.toJson(),
    );
    final group = YouTubeAnalyticsV2Group.fromJson(_asMap(data));
    if (group.groupId != request.groupId || group.title != request.title) {
      throw const FormatException(
        'The provider returned a different analytics group.',
      );
    }
    return group;
  }

  Future<YouTubeAnalyticsV2DeleteResult> analyticsV2DeleteGroup({
    required String idempotencyKey,
    required String groupId,
    required String confirmGroupId,
  }) async {
    _requireAnalyticsV2Enabled();
    final request = YouTubeAnalyticsV2DeleteGroupRequest(
      idempotencyKey: idempotencyKey,
      groupId: groupId,
      confirmGroupId: confirmGroupId,
    );
    final data = await _ownerMutation(
      'analyticsV2DeleteGroup',
      body: request.toJson(),
    );
    final result = YouTubeAnalyticsV2DeleteResult.group(_asMap(data));
    if (result.resourceId != request.groupId) {
      throw const FormatException(
        'The provider deleted a different analytics group.',
      );
    }
    return result;
  }

  Future<YouTubeAnalyticsV2GroupItemsResult> analyticsV2ListGroupItems({
    required String groupId,
  }) async {
    _requireAnalyticsV2Enabled();
    final request = YouTubeAnalyticsV2GroupItemsRequest(groupId: groupId);
    final data = await _ownerMutation(
      'analyticsV2ListGroupItems',
      body: request.toJson(),
    );
    final result = YouTubeAnalyticsV2GroupItemsResult.fromJson(_asMap(data));
    if (result.groupId != request.groupId) {
      throw const FormatException(
        'The provider returned a different analytics group.',
      );
    }
    return result;
  }

  Future<YouTubeAnalyticsV2GroupItem> analyticsV2InsertGroupItem({
    required String idempotencyKey,
    required String groupId,
    required YouTubeAnalyticsV2GroupItemType resourceType,
    required String resourceId,
  }) async {
    _requireAnalyticsV2Enabled();
    final request = YouTubeAnalyticsV2InsertGroupItemRequest(
      idempotencyKey: idempotencyKey,
      groupId: groupId,
      resourceType: resourceType,
      resourceId: resourceId,
    );
    final data = await _ownerMutation(
      'analyticsV2InsertGroupItem',
      body: request.toJson(),
    );
    final item = YouTubeAnalyticsV2GroupItem.fromJson(_asMap(data));
    if (item.groupId != request.groupId ||
        item.resourceType != request.resourceType ||
        item.resourceId != request.resourceId) {
      throw const FormatException(
        'The provider returned a different analytics group item.',
      );
    }
    return item;
  }

  Future<YouTubeAnalyticsV2DeleteResult> analyticsV2DeleteGroupItem({
    required String idempotencyKey,
    required String groupItemId,
    required String confirmGroupItemId,
  }) async {
    _requireAnalyticsV2Enabled();
    final request = YouTubeAnalyticsV2DeleteGroupItemRequest(
      idempotencyKey: idempotencyKey,
      groupItemId: groupItemId,
      confirmGroupItemId: confirmGroupItemId,
    );
    final data = await _ownerMutation(
      'analyticsV2DeleteGroupItem',
      body: request.toJson(),
    );
    final result = YouTubeAnalyticsV2DeleteResult.groupItem(_asMap(data));
    if (result.resourceId != request.groupItemId) {
      throw const FormatException(
        'The provider deleted a different analytics group item.',
      );
    }
    return result;
  }

  Future<YouTubeAnalyticsV2ReportResult> analyticsV2QueryReport({
    required YouTubeAnalyticsV2ReportQuery query,
  }) async {
    _requireAnalyticsV2Enabled();
    final data = await _ownerMutation(
      'analyticsV2QueryReport',
      body: query.toJson(),
    );
    return YouTubeAnalyticsV2ReportResult.fromJson(_asMap(data));
  }

  Future<YouTubeReportingV1ReportTypesPage> reportingV1ListReportTypes({
    String? pageToken,
    int pageSize = 50,
    bool includeSystemManaged = false,
  }) async {
    _requireReportingV1Enabled();
    final request = YouTubeReportingV1PageRequest(
      pageToken: pageToken,
      pageSize: pageSize,
      includeSystemManaged: includeSystemManaged,
    );
    final data = await _ownerMutation(
      'reportingV1ListReportTypes',
      body: request.toJson(),
    );
    return YouTubeReportingV1ReportTypesPage.fromJson(_asMap(data));
  }

  Future<YouTubeReportingV1Job> reportingV1CreateJob({
    required String idempotencyKey,
    required String reportTypeId,
    required String name,
  }) async {
    _requireReportingV1Enabled();
    final request = YouTubeReportingV1CreateJobRequest(
      idempotencyKey: idempotencyKey,
      reportTypeId: reportTypeId,
      name: name,
    );
    final data = await _ownerMutation(
      'reportingV1CreateJob',
      body: request.toJson(),
    );
    final job = YouTubeReportingV1Job.fromJson(_asMap(data));
    if (job.reportTypeId != request.reportTypeId ||
        job.name != request.name ||
        job.status != YouTubeReportingV1JobStatus.active) {
      throw const FormatException(
        'The provider returned a different reporting job.',
      );
    }
    return job;
  }

  Future<YouTubeReportingV1JobsPage> reportingV1ListJobs({
    String? pageToken,
    int pageSize = 50,
    bool includeSystemManaged = false,
  }) async {
    _requireReportingV1Enabled();
    final request = YouTubeReportingV1PageRequest(
      pageToken: pageToken,
      pageSize: pageSize,
      includeSystemManaged: includeSystemManaged,
    );
    final data = await _ownerMutation(
      'reportingV1ListJobs',
      body: request.toJson(),
    );
    return YouTubeReportingV1JobsPage.fromJson(_asMap(data));
  }

  Future<YouTubeReportingV1Job> reportingV1GetJob({
    required String jobId,
  }) async {
    _requireReportingV1Enabled();
    final request = YouTubeReportingV1JobRequest(jobId: jobId);
    final data = await _ownerMutation(
      'reportingV1GetJob',
      body: request.toJson(),
    );
    final job = YouTubeReportingV1Job.fromJson(_asMap(data));
    if (job.jobId != request.jobId) {
      throw const FormatException(
        'The provider returned a different reporting job.',
      );
    }
    return job;
  }

  Future<YouTubeReportingV1DeleteJobResult> reportingV1DeleteJob({
    required String idempotencyKey,
    required String jobId,
    required String confirmJobId,
  }) async {
    _requireReportingV1Enabled();
    final request = YouTubeReportingV1DeleteJobRequest(
      idempotencyKey: idempotencyKey,
      jobId: jobId,
      confirmJobId: confirmJobId,
    );
    final data = await _ownerMutation(
      'reportingV1DeleteJob',
      body: request.toJson(),
    );
    final result = YouTubeReportingV1DeleteJobResult.fromJson(_asMap(data));
    if (result.jobId != request.jobId) {
      throw const FormatException(
        'The provider deleted a different reporting job.',
      );
    }
    return result;
  }

  Future<YouTubeReportingV1ReportsPage> reportingV1ListReports({
    required String jobId,
    String? pageToken,
    int pageSize = 50,
    YouTubeReportingV1ReportWindow? window,
  }) async {
    _requireReportingV1Enabled();
    final request = YouTubeReportingV1ReportsRequest(
      jobId: jobId,
      pageToken: pageToken,
      pageSize: pageSize,
      window: window,
    );
    final data = await _ownerMutation(
      'reportingV1ListReports',
      body: request.toJson(),
    );
    final page = YouTubeReportingV1ReportsPage.fromJson(_asMap(data));
    if (page.items.any((report) => report.jobId != request.jobId)) {
      throw const FormatException(
        'The provider returned a report from a different job.',
      );
    }
    return page;
  }

  Future<YouTubeReportingV1Report> reportingV1GetReport({
    required String jobId,
    required String reportId,
  }) async {
    _requireReportingV1Enabled();
    final request = YouTubeReportingV1ReportRequest(
      jobId: jobId,
      reportId: reportId,
    );
    final data = await _ownerMutation(
      'reportingV1GetReport',
      body: request.toJson(),
    );
    final report = YouTubeReportingV1Report.fromJson(_asMap(data));
    if (report.jobId != request.jobId || report.reportId != request.reportId) {
      throw const FormatException('The provider returned a different report.');
    }
    return report;
  }

  Future<YouTubeReportingV1DownloadedMedia> reportingV1DownloadReportMedia({
    required String jobId,
    required String reportId,
    int maximumBytes = youtubeReportingV1MaximumMediaBytes,
  }) async {
    _requireReportingV1Enabled();
    final request = YouTubeReportingV1DownloadRequest(
      jobId: jobId,
      reportId: reportId,
      maximumBytes: maximumBytes,
    );
    final data = await _ownerMutation(
      'reportingV1DownloadReportMedia',
      body: request.toJson(),
    );
    final media = YouTubeReportingV1DownloadedMedia.fromJson(_asMap(data));
    if (media.jobId != request.jobId ||
        media.reportId != request.reportId ||
        media.byteLength > request.maximumBytes) {
      throw const FormatException(
        'The provider returned report media outside the requested boundary.',
      );
    }
    return media;
  }

  Future<YouTubeOwnerAnalyticsResult> analyticsPreset({
    required YouTubeOwnerAnalyticsPreset preset,
    required DateTime startDate,
    required DateTime endDate,
    String? videoId,
    int? startIndex,
  }) async {
    final data = await _invoke(
      'ownerAnalyticsPreset',
      authenticated: true,
      limitedUseAppCheck: true,
      body: <String, Object?>{
        'preset': preset.wireValue,
        'startDate': _date(startDate),
        'endDate': _date(endDate),
        'videoId': ?videoId,
        'startIndex': ?startIndex,
      },
    );
    return YouTubeOwnerAnalyticsResult.fromJson(_asMap(data));
  }

  Future<YouTubeDisconnectResult> disconnect() async {
    final data = await _invoke(
      'disconnect',
      authenticated: true,
      limitedUseAppCheck: true,
    );
    return YouTubeDisconnectResult.fromJson(_asMap(data));
  }

  void _requireAnalyticsV2Enabled() {
    if (!_analyticsV2Enabled) {
      throw const YouTubeCapabilityUnavailableException(
        message: 'YouTube Analytics v2 is unavailable.',
        statusCode: 503,
      );
    }
  }

  void _requireReportingV1Enabled() {
    if (!_reportingV1Enabled) {
      throw const YouTubeCapabilityUnavailableException(
        message: 'YouTube Reporting v1 is unavailable.',
        statusCode: 503,
      );
    }
  }

  Future<Object?> _invoke(
    String operation, {
    Map<String, Object?> body = const <String, Object?>{},
    bool authenticated = false,
    bool limitedUseAppCheck = false,
  }) async {
    final idToken = authenticated ? await _credentials.firebaseIdToken() : null;
    final appCheck = await _credentials.appCheckToken(
      limitedUseAppCheck
          ? YouTubeAppCheckTokenMode.limitedUse
          : YouTubeAppCheckTokenMode.standard,
    );
    final headers = <String, String>{
      'accept': 'application/json',
      'x-firebase-appcheck': appCheck,
      'x-request-id': _requestId(),
    };
    if (idToken != null) {
      headers['authorization'] = 'Bearer $idToken';
    }
    final response = await _transport.postJson(
      _providerEndpoint,
      headers: headers,
      body: <String, Object?>{'operation': operation, ...body},
    );
    final envelope = _decodeEnvelope(response);
    if (envelope['ok'] == true) return envelope['data'];
    final error = _asMap(envelope['error']);
    final code = _requiredString(error, 'code');
    final message = _requiredString(error, 'message');
    final retryable = error['retryable'] == true;
    throw switch (code) {
      'eligibility_required' => YouTubeEligibilityRequiredException(
        message: message,
        retryable: retryable,
        statusCode: response.statusCode,
      ),
      'capability_disabled' => YouTubeCapabilityUnavailableException(
        message: message,
        retryable: retryable,
        statusCode: response.statusCode,
      ),
      'status_conflict' => YouTubeStatusConflictException(
        message: message,
        retryable: retryable,
        statusCode: response.statusCode,
      ),
      'not_found' => YouTubeResourceUnavailableException(
        message: message,
        retryable: retryable,
        statusCode: response.statusCode,
      ),
      _ => YouTubeProviderClientException(
        code: code,
        message: message,
        retryable: retryable,
        statusCode: response.statusCode,
      ),
    };
  }

  Future<Object?> _ownerMutation(
    String operation, {
    Map<String, Object?> body = const <String, Object?>{},
  }) {
    return _invoke(
      operation,
      body: body,
      authenticated: true,
      limitedUseAppCheck: true,
    );
  }

  Map<String, Object?> _decodeEnvelope(YouTubeHttpResponse response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw YouTubeProviderClientException(
        code: 'invalid_provider_response',
        message: 'The provider returned an unreadable response.',
        statusCode: response.statusCode,
      );
    }
    final envelope = _asMap(decoded);
    if (envelope['ok'] is! bool) {
      throw YouTubeProviderClientException(
        code: 'invalid_provider_response',
        message: 'The provider returned an invalid response.',
        statusCode: response.statusCode,
      );
    }
    if ((response.statusCode < 200 || response.statusCode >= 300) &&
        envelope['ok'] == true) {
      throw YouTubeProviderClientException(
        code: 'invalid_provider_response',
        message: 'The provider returned an inconsistent response.',
        statusCode: response.statusCode,
      );
    }
    if (envelope['ok'] == true && !envelope.containsKey('data')) {
      throw YouTubeProviderClientException(
        code: 'invalid_provider_response',
        message: 'The provider response is incomplete.',
        statusCode: response.statusCode,
      );
    }
    return envelope;
  }

  static Uri _validateEndpoint(Uri endpoint) {
    const requiredHost = 'asia-south1-moolsocial-dev-503018.cloudfunctions.net';
    if (endpoint.scheme != 'https' ||
        endpoint.host != requiredHost ||
        endpoint.path != '/youtubeProvider' ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        endpoint.hasPort ||
        endpoint.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        endpoint,
        'providerEndpoint',
        'must use the secure private-Dev service address',
      );
    }
    return endpoint;
  }

  static void _validateRuntimeBoundary({
    required bool proofEnabled,
    required String firebaseProjectId,
  }) {
    if (!proofEnabled) {
      throw StateError(
        'The YouTube provider client is available only in private Dev proof.',
      );
    }
    if (firebaseProjectId != youtubePrivateDevProjectId) {
      throw StateError(
        'The YouTube provider client requires the dedicated Dev project.',
      );
    }
  }

  static String _secureRequestId() {
    final random = Random.secure();
    final entropy = List<int>.generate(16, (_) => random.nextInt(256));
    final suffix = entropy
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'mobile-${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }

  static String _date(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
  }
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const FormatException('Expected an object.');
}

List<Object?> _asList(Object? value) {
  if (value is List<Object?>) return value;
  if (value is List) return value.cast<Object?>();
  throw const FormatException('Expected a list.');
}

String _requiredString(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is String && field.isNotEmpty) return field;
  throw FormatException('$key must be text.');
}
