part of 'youtube_private_dev_models.dart';

enum YouTubeOwnerRating { like, dislike, none }

enum YouTubeOwnerCommentModerationStatus { published, heldForReview, rejected }

enum YouTubePlaylistPrivacyStatus { private, unlisted, public }

enum YouTubeCreatorAssetKind {
  thumbnail,
  caption,
  channelBanner,
  watermark,
  playlistImage,
}

enum YouTubeCreatorResponseEncoding { json, empty }

enum YouTubeCaptionFormat { sbv, scc, srt, ttml, vtt }

enum YouTubeCaptionStatus { serving, syncing, failed }

enum YouTubeChannelBrandingField {
  country,
  description,
  defaultLanguage,
  keywords,
  trackingAnalyticsAccountId,
  unsubscribedTrailer,
}

enum YouTubeChannelSectionType {
  allPlaylists,
  completedEvents,
  liveEvents,
  multipleChannels,
  multiplePlaylists,
  popularUploads,
  recentUploads,
  singlePlaylist,
  subscriptions,
  upcomingEvents,
}

enum YouTubeWatermarkOffsetFrom { start, end }

enum YouTubeWatermarkCorner { topLeft, topRight, bottomLeft, bottomRight }

extension YouTubeOwnerRatingWireValue on YouTubeOwnerRating {
  String get wireValue => name;
}

extension YouTubeOwnerCommentModerationStatusWireValue
    on YouTubeOwnerCommentModerationStatus {
  String get wireValue => name;
}

extension YouTubePlaylistPrivacyStatusWireValue
    on YouTubePlaylistPrivacyStatus {
  String get wireValue => name;
}

extension YouTubeCaptionFormatWireValue on YouTubeCaptionFormat {
  String get wireValue => name;
}

extension YouTubeChannelSectionTypeWireValue on YouTubeChannelSectionType {
  String get wireValue => name;
}

extension YouTubeWatermarkOffsetFromWireValue on YouTubeWatermarkOffsetFrom {
  String get wireValue => name;
}

extension YouTubeWatermarkCornerWireValue on YouTubeWatermarkCorner {
  String get wireValue => name;
}

class YouTubeOwnerRatingResult {
  const YouTubeOwnerRatingResult({required this.videoId, required this.rating});

  factory YouTubeOwnerRatingResult.fromJson(Map<String, Object?> json) {
    return YouTubeOwnerRatingResult(
      videoId: _requiredString(json, 'videoId'),
      rating: _ownerRating(_requiredString(json, 'rating')),
    );
  }

  final String videoId;
  final YouTubeOwnerRating rating;
}

class YouTubeOwnerCommentMutation {
  const YouTubeOwnerCommentMutation({required this.comment, this.threadId});

  factory YouTubeOwnerCommentMutation.fromJson(Map<String, Object?> json) {
    return YouTubeOwnerCommentMutation(
      comment: YouTubePublicComment.fromJson(_requiredMap(json, 'comment')),
      threadId: _optionalString(json, 'threadId'),
    );
  }

  final YouTubePublicComment comment;
  final String? threadId;
}

class YouTubeDeleteResult {
  const YouTubeDeleteResult({
    required this.resourceId,
    required this.identifierKey,
    this.parentResourceId,
  });

  factory YouTubeDeleteResult.fromJson(
    Map<String, Object?> json, {
    required String identifierKey,
    String? parentIdentifierKey,
  }) {
    if (_requiredBool(json, 'deleted') != true) {
      throw const FormatException('deleted must be true.');
    }
    return YouTubeDeleteResult(
      resourceId: _requiredString(json, identifierKey),
      identifierKey: identifierKey,
      parentResourceId: parentIdentifierKey == null
          ? null
          : _requiredString(json, parentIdentifierKey),
    );
  }

  final String resourceId;
  final String identifierKey;
  final String? parentResourceId;
}

class YouTubeOwnerCommentModerationResult {
  const YouTubeOwnerCommentModerationResult({
    required this.commentId,
    required this.moderationStatus,
    required this.authorBanned,
  });

  factory YouTubeOwnerCommentModerationResult.fromJson(
    Map<String, Object?> json,
  ) {
    return YouTubeOwnerCommentModerationResult(
      commentId: _requiredString(json, 'commentId'),
      moderationStatus: _commentModerationStatus(
        _requiredString(json, 'moderationStatus'),
      ),
      authorBanned: _requiredBool(json, 'authorBanned'),
    );
  }

  final String commentId;
  final YouTubeOwnerCommentModerationStatus moderationStatus;
  final bool authorBanned;
}

class YouTubeOwnerSubscriptionMutation {
  const YouTubeOwnerSubscriptionMutation({
    required this.subscriptionId,
    required this.actorChannelId,
    required this.targetChannelId,
  });

  factory YouTubeOwnerSubscriptionMutation.fromJson(Map<String, Object?> json) {
    return YouTubeOwnerSubscriptionMutation(
      subscriptionId: _requiredString(json, 'subscriptionId'),
      actorChannelId: _requiredString(json, 'actorChannelId'),
      targetChannelId: _requiredString(json, 'targetChannelId'),
    );
  }

  final String subscriptionId;
  final String actorChannelId;
  final String targetChannelId;
}

class YouTubeOwnerPlaylistMutation {
  const YouTubeOwnerPlaylistMutation({
    required this.playlistId,
    required this.actorChannelId,
    required this.title,
    required this.description,
    required this.privacyStatus,
  });

  factory YouTubeOwnerPlaylistMutation.fromJson(Map<String, Object?> json) {
    return YouTubeOwnerPlaylistMutation(
      playlistId: _requiredString(json, 'playlistId'),
      actorChannelId: _requiredString(json, 'actorChannelId'),
      title: _requiredString(json, 'title'),
      description: _requiredText(json, 'description'),
      privacyStatus: _playlistPrivacyStatus(
        _requiredString(json, 'privacyStatus'),
      ),
    );
  }

  final String playlistId;
  final String actorChannelId;
  final String title;
  final String description;
  final YouTubePlaylistPrivacyStatus privacyStatus;
}

class YouTubeOwnerPlaylistItemMutation {
  const YouTubeOwnerPlaylistItemMutation({
    required this.playlistItemId,
    required this.playlistId,
    required this.videoId,
    required this.position,
  });

  factory YouTubeOwnerPlaylistItemMutation.fromJson(Map<String, Object?> json) {
    return YouTubeOwnerPlaylistItemMutation(
      playlistItemId: _requiredString(json, 'playlistItemId'),
      playlistId: _requiredString(json, 'playlistId'),
      videoId: _requiredString(json, 'videoId'),
      position: _requiredNonNegativeInt(json, 'position'),
    );
  }

  final String playlistItemId;
  final String playlistId;
  final String videoId;
  final int position;
}

class YouTubeOwnerVideoMetadataMutation {
  const YouTubeOwnerVideoMetadataMutation({
    required this.videoId,
    required this.actorChannelId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.tags,
    required this.privacyStatus,
  });

  factory YouTubeOwnerVideoMetadataMutation.fromJson(
    Map<String, Object?> json,
  ) {
    final privacyStatus = _requiredString(json, 'privacyStatus');
    if (privacyStatus != 'private') {
      throw const FormatException('privacyStatus must be private.');
    }
    return YouTubeOwnerVideoMetadataMutation(
      videoId: _requiredString(json, 'videoId'),
      actorChannelId: _requiredString(json, 'actorChannelId'),
      title: _requiredString(json, 'title'),
      description: _requiredText(json, 'description'),
      categoryId: _requiredCategoryId(json, 'categoryId'),
      tags: _requiredNonEmptyStringList(json, 'tags', allowEmpty: true),
      privacyStatus: YouTubePlaylistPrivacyStatus.private,
    );
  }

  final String videoId;
  final String actorChannelId;
  final String title;
  final String description;
  final String categoryId;
  final List<String> tags;
  final YouTubePlaylistPrivacyStatus privacyStatus;
}

class YouTubeDirectAssetUploadSession {
  const YouTubeDirectAssetUploadSession({
    required this.sessionUrl,
    required this.expiresAt,
    required this.contentType,
    required this.contentLength,
    required this.resourceKind,
    required this.providerResponseEncoding,
  });

  factory YouTubeDirectAssetUploadSession.fromJson(Map<String, Object?> json) {
    if (_requiredString(json, 'uploadMethod') != 'PUT') {
      throw const FormatException('uploadMethod must be PUT.');
    }
    return YouTubeDirectAssetUploadSession(
      sessionUrl: _requiredUri(json, 'sessionUrl'),
      expiresAt: _requiredDateTime(json, 'expiresAt'),
      contentType: _requiredString(json, 'contentType'),
      contentLength: _ownerCreatorRequiredPositiveInt(json, 'contentLength'),
      resourceKind: _creatorAssetKind(_requiredString(json, 'resourceKind')),
      providerResponseEncoding: _creatorResponseEncoding(
        _requiredString(json, 'providerResponseEncoding'),
      ),
    );
  }

  final Uri sessionUrl;
  final DateTime expiresAt;
  final String contentType;
  final int contentLength;
  final YouTubeCreatorAssetKind resourceKind;
  final YouTubeCreatorResponseEncoding providerResponseEncoding;

  String get uploadMethod => 'PUT';
}

class YouTubeCreatorCaption {
  const YouTubeCreatorCaption({
    required this.captionId,
    required this.videoId,
    required this.language,
    required this.name,
    required this.isDraft,
    required this.status,
    this.lastUpdated,
    this.trackKind,
    this.audioTrackType,
    this.isCC,
    this.isLarge,
    this.isEasyReader,
    this.isAutoSynced,
    this.failureReason,
  });

  factory YouTubeCreatorCaption.fromJson(Map<String, Object?> json) {
    return YouTubeCreatorCaption(
      captionId: _requiredString(json, 'captionId'),
      videoId: _requiredString(json, 'videoId'),
      language: _requiredLanguageTag(json, 'language'),
      name: _requiredText(json, 'name'),
      isDraft: _requiredBool(json, 'isDraft'),
      status: _captionStatus(_requiredString(json, 'status')),
      lastUpdated: _optionalDateTime(json, 'lastUpdated'),
      trackKind: _optionalString(json, 'trackKind'),
      audioTrackType: _optionalString(json, 'audioTrackType'),
      isCC: _optionalBool(json, 'isCC'),
      isLarge: _optionalBool(json, 'isLarge'),
      isEasyReader: _optionalBool(json, 'isEasyReader'),
      isAutoSynced: _optionalBool(json, 'isAutoSynced'),
      failureReason: _optionalString(json, 'failureReason'),
    );
  }

  final String captionId;
  final String videoId;
  final String language;
  final String name;
  final bool isDraft;
  final YouTubeCaptionStatus status;
  final DateTime? lastUpdated;
  final String? trackKind;
  final String? audioTrackType;
  final bool? isCC;
  final bool? isLarge;
  final bool? isEasyReader;
  final bool? isAutoSynced;
  final String? failureReason;
}

class YouTubeCreatorCaptionsResult {
  const YouTubeCreatorCaptionsResult({
    required this.videoId,
    required this.items,
  });

  factory YouTubeCreatorCaptionsResult.fromJson(Map<String, Object?> json) {
    return YouTubeCreatorCaptionsResult(
      videoId: _requiredString(json, 'videoId'),
      items: _requiredList(
        json,
        'items',
      ).map(_asMap).map(YouTubeCreatorCaption.fromJson).toList(growable: false),
    );
  }

  final String videoId;
  final List<YouTubeCreatorCaption> items;
}

class YouTubeCreatorCaptionDownload {
  const YouTubeCreatorCaptionDownload({
    required this.captionId,
    required this.videoId,
    required this.format,
    required this.data,
    required this.byteLimit,
    required this.contentType,
    this.translatedLanguage,
  });

  factory YouTubeCreatorCaptionDownload.fromJson(Map<String, Object?> json) {
    if (_requiredString(json, 'encoding') != 'base64') {
      throw const FormatException('encoding must be base64.');
    }
    return YouTubeCreatorCaptionDownload(
      captionId: _requiredString(json, 'captionId'),
      videoId: _requiredString(json, 'videoId'),
      format: _captionFormat(_requiredString(json, 'format')),
      data: _requiredString(json, 'data'),
      byteLimit: _ownerCreatorRequiredPositiveInt(json, 'byteLimit'),
      contentType: _requiredString(json, 'contentType'),
      translatedLanguage: _optionalLanguageTag(json, 'translatedLanguage'),
    );
  }

  final String captionId;
  final String videoId;
  final YouTubeCaptionFormat format;
  final String data;
  final int byteLimit;
  final String contentType;
  final String? translatedLanguage;

  String get encoding => 'base64';
}

class YouTubeChannelBrandingPatch {
  YouTubeChannelBrandingPatch(Map<YouTubeChannelBrandingField, String?> changes)
    : changes = Map.unmodifiable(changes) {
    if (changes.isEmpty) {
      throw const FormatException('At least one branding change is required.');
    }
  }

  final Map<YouTubeChannelBrandingField, String?> changes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      for (final entry in changes.entries) entry.key.name: entry.value,
    };
  }
}

class YouTubeChannelBranding {
  const YouTubeChannelBranding({
    this.country,
    this.description,
    this.defaultLanguage,
    this.keywords,
    this.trackingAnalyticsAccountId,
    this.unsubscribedTrailer,
  });

  factory YouTubeChannelBranding.fromJson(Map<String, Object?> json) {
    return YouTubeChannelBranding(
      country: _ownerCreatorOptionalAllowEmptyText(json, 'country'),
      description: _ownerCreatorOptionalAllowEmptyText(json, 'description'),
      defaultLanguage: _ownerCreatorOptionalAllowEmptyText(
        json,
        'defaultLanguage',
      ),
      keywords: _ownerCreatorOptionalAllowEmptyText(json, 'keywords'),
      trackingAnalyticsAccountId: _ownerCreatorOptionalAllowEmptyText(
        json,
        'trackingAnalyticsAccountId',
      ),
      unsubscribedTrailer: _ownerCreatorOptionalAllowEmptyText(
        json,
        'unsubscribedTrailer',
      ),
    );
  }

  final String? country;
  final String? description;
  final String? defaultLanguage;
  final String? keywords;
  final String? trackingAnalyticsAccountId;
  final String? unsubscribedTrailer;
}

class YouTubeChannelBrandingUpdate {
  const YouTubeChannelBrandingUpdate({
    required this.channelId,
    required this.branding,
  });

  factory YouTubeChannelBrandingUpdate.fromJson(Map<String, Object?> json) {
    return YouTubeChannelBrandingUpdate(
      channelId: _requiredString(json, 'channelId'),
      branding: YouTubeChannelBranding.fromJson(_requiredMap(json, 'branding')),
    );
  }

  final String channelId;
  final YouTubeChannelBranding branding;
}

class YouTubeChannelSectionInput {
  const YouTubeChannelSectionInput({
    required this.type,
    required this.position,
    this.title,
    this.playlistIds = const <String>[],
    this.channelIds = const <String>[],
  });

  final YouTubeChannelSectionType type;
  final int position;
  final String? title;
  final List<String> playlistIds;
  final List<String> channelIds;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type.wireValue,
      'position': position,
      'title': ?title,
      if (playlistIds.isNotEmpty) 'playlistIds': playlistIds,
      if (channelIds.isNotEmpty) 'channelIds': channelIds,
    };
  }
}

class YouTubeChannelSection {
  const YouTubeChannelSection({
    required this.sectionId,
    required this.channelId,
    required this.type,
    required this.position,
    this.title,
    this.playlistIds = const <String>[],
    this.channelIds = const <String>[],
  });

  factory YouTubeChannelSection.fromJson(Map<String, Object?> json) {
    if (_requiredString(json, 'style') != 'horizontalRow') {
      throw const FormatException('style must be horizontalRow.');
    }
    return YouTubeChannelSection(
      sectionId: _requiredString(json, 'sectionId'),
      channelId: _requiredString(json, 'channelId'),
      type: _channelSectionType(_requiredString(json, 'type')),
      position: _requiredNonNegativeInt(json, 'position'),
      title: _optionalString(json, 'title'),
      playlistIds:
          _optionalNonEmptyStringList(json, 'playlistIds') ?? const <String>[],
      channelIds:
          _optionalNonEmptyStringList(json, 'channelIds') ?? const <String>[],
    );
  }

  final String sectionId;
  final String channelId;
  final YouTubeChannelSectionType type;
  final int position;
  final String? title;
  final List<String> playlistIds;
  final List<String> channelIds;

  String get style => 'horizontalRow';
}

class YouTubeChannelSectionsResult {
  const YouTubeChannelSectionsResult({
    required this.channelId,
    required this.items,
  });

  factory YouTubeChannelSectionsResult.fromJson(Map<String, Object?> json) {
    return YouTubeChannelSectionsResult(
      channelId: _requiredString(json, 'channelId'),
      items: _requiredList(
        json,
        'items',
      ).map(_asMap).map(YouTubeChannelSection.fromJson).toList(growable: false),
    );
  }

  final String channelId;
  final List<YouTubeChannelSection> items;
}

class YouTubeChannelAssetAction {
  const YouTubeChannelAssetAction({
    required this.channelId,
    required this.action,
  });

  factory YouTubeChannelAssetAction.bannerApplied(Map<String, Object?> json) {
    if (_requiredBool(json, 'bannerApplied') != true) {
      throw const FormatException('bannerApplied must be true.');
    }
    return YouTubeChannelAssetAction(
      channelId: _requiredString(json, 'channelId'),
      action: 'bannerApplied',
    );
  }

  factory YouTubeChannelAssetAction.watermarkUnset(Map<String, Object?> json) {
    if (_requiredBool(json, 'watermarkUnset') != true) {
      throw const FormatException('watermarkUnset must be true.');
    }
    return YouTubeChannelAssetAction(
      channelId: _requiredString(json, 'channelId'),
      action: 'watermarkUnset',
    );
  }

  final String channelId;
  final String action;
}

class YouTubePlaylistImage {
  const YouTubePlaylistImage({
    required this.playlistImageId,
    required this.playlistId,
    required this.type,
    this.width,
    this.height,
    this.imageUrl,
  });

  factory YouTubePlaylistImage.fromJson(Map<String, Object?> json) {
    return YouTubePlaylistImage(
      playlistImageId: _requiredString(json, 'playlistImageId'),
      playlistId: _requiredString(json, 'playlistId'),
      type: _requiredString(json, 'type'),
      width: _optionalNonNegativeInt(json, 'width'),
      height: _optionalNonNegativeInt(json, 'height'),
      imageUrl: _optionalUri(json, 'imageUrl'),
    );
  }

  final String playlistImageId;
  final String playlistId;
  final String type;
  final int? width;
  final int? height;
  final Uri? imageUrl;
}

class YouTubePlaylistImagesResult {
  const YouTubePlaylistImagesResult({
    required this.playlistId,
    required this.items,
    this.nextPageToken,
  });

  factory YouTubePlaylistImagesResult.fromJson(Map<String, Object?> json) {
    return YouTubePlaylistImagesResult(
      playlistId: _requiredString(json, 'playlistId'),
      items: _requiredList(
        json,
        'items',
      ).map(_asMap).map(YouTubePlaylistImage.fromJson).toList(growable: false),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final String playlistId;
  final List<YouTubePlaylistImage> items;
  final String? nextPageToken;
}

class YouTubeAbuseReason {
  const YouTubeAbuseReason({
    required this.reasonId,
    required this.label,
    required this.secondaryReasons,
  });

  factory YouTubeAbuseReason.fromJson(Map<String, Object?> json) {
    return YouTubeAbuseReason(
      reasonId: _requiredString(json, 'reasonId'),
      label: _requiredString(json, 'label'),
      secondaryReasons: _requiredList(json, 'secondaryReasons')
          .map(_asMap)
          .map(YouTubeAbuseReasonChoice.fromJson)
          .toList(growable: false),
    );
  }

  final String reasonId;
  final String label;
  final List<YouTubeAbuseReasonChoice> secondaryReasons;
}

class YouTubeAbuseReasonChoice {
  const YouTubeAbuseReasonChoice({required this.reasonId, required this.label});

  factory YouTubeAbuseReasonChoice.fromJson(Map<String, Object?> json) {
    return YouTubeAbuseReasonChoice(
      reasonId: _requiredString(json, 'reasonId'),
      label: _requiredString(json, 'label'),
    );
  }

  final String reasonId;
  final String label;
}

class YouTubeAbuseReasonsResult {
  const YouTubeAbuseReasonsResult({required this.items, this.language});

  factory YouTubeAbuseReasonsResult.fromJson(Map<String, Object?> json) {
    return YouTubeAbuseReasonsResult(
      language: _optionalLanguageTag(json, 'language'),
      items: _requiredList(
        json,
        'items',
      ).map(_asMap).map(YouTubeAbuseReason.fromJson).toList(growable: false),
    );
  }

  final String? language;
  final List<YouTubeAbuseReason> items;
}

class YouTubeAbuseReportResult {
  const YouTubeAbuseReportResult({
    required this.videoId,
    required this.reasonId,
  });

  factory YouTubeAbuseReportResult.fromJson(Map<String, Object?> json) {
    if (_requiredBool(json, 'reported') != true) {
      throw const FormatException('reported must be true.');
    }
    return YouTubeAbuseReportResult(
      videoId: _requiredString(json, 'videoId'),
      reasonId: _requiredString(json, 'reasonId'),
    );
  }

  final String videoId;
  final String reasonId;
}

class YouTubeGeneralAbuseReportResult {
  const YouTubeGeneralAbuseReportResult({
    required this.subjectTypeId,
    required this.subjectId,
    required this.abuseTypeIds,
  });

  factory YouTubeGeneralAbuseReportResult.fromJson(Map<String, Object?> json) {
    if (_requiredBool(json, 'submitted') != true) {
      throw const FormatException('submitted must be true.');
    }
    return YouTubeGeneralAbuseReportResult(
      subjectTypeId: _requiredString(json, 'subjectTypeId'),
      subjectId: _requiredString(json, 'subjectId'),
      abuseTypeIds: _requiredNonEmptyStringList(json, 'abuseTypeIds'),
    );
  }

  final String subjectTypeId;
  final String subjectId;
  final List<String> abuseTypeIds;
}

YouTubeOwnerRating _ownerRating(String value) {
  return switch (value) {
    'like' => YouTubeOwnerRating.like,
    'dislike' => YouTubeOwnerRating.dislike,
    'none' => YouTubeOwnerRating.none,
    _ => throw const FormatException('rating is invalid.'),
  };
}

YouTubeOwnerCommentModerationStatus _commentModerationStatus(String value) {
  return switch (value) {
    'published' => YouTubeOwnerCommentModerationStatus.published,
    'heldForReview' => YouTubeOwnerCommentModerationStatus.heldForReview,
    'rejected' => YouTubeOwnerCommentModerationStatus.rejected,
    _ => throw const FormatException('moderationStatus is invalid.'),
  };
}

YouTubePlaylistPrivacyStatus _playlistPrivacyStatus(String value) {
  return switch (value) {
    'private' => YouTubePlaylistPrivacyStatus.private,
    'unlisted' => YouTubePlaylistPrivacyStatus.unlisted,
    'public' => YouTubePlaylistPrivacyStatus.public,
    _ => throw const FormatException('privacyStatus is invalid.'),
  };
}

YouTubeCreatorAssetKind _creatorAssetKind(String value) {
  return switch (value) {
    'thumbnail' => YouTubeCreatorAssetKind.thumbnail,
    'caption' => YouTubeCreatorAssetKind.caption,
    'channelBanner' => YouTubeCreatorAssetKind.channelBanner,
    'watermark' => YouTubeCreatorAssetKind.watermark,
    'playlistImage' => YouTubeCreatorAssetKind.playlistImage,
    _ => throw const FormatException('resourceKind is invalid.'),
  };
}

YouTubeCreatorResponseEncoding _creatorResponseEncoding(String value) {
  return switch (value) {
    'json' => YouTubeCreatorResponseEncoding.json,
    'empty' => YouTubeCreatorResponseEncoding.empty,
    _ => throw const FormatException('providerResponseEncoding is invalid.'),
  };
}

YouTubeCaptionFormat _captionFormat(String value) {
  return switch (value) {
    'sbv' => YouTubeCaptionFormat.sbv,
    'scc' => YouTubeCaptionFormat.scc,
    'srt' => YouTubeCaptionFormat.srt,
    'ttml' => YouTubeCaptionFormat.ttml,
    'vtt' => YouTubeCaptionFormat.vtt,
    _ => throw const FormatException('format is invalid.'),
  };
}

YouTubeCaptionStatus _captionStatus(String value) {
  return switch (value) {
    'serving' => YouTubeCaptionStatus.serving,
    'syncing' => YouTubeCaptionStatus.syncing,
    'failed' => YouTubeCaptionStatus.failed,
    _ => throw const FormatException('status is invalid.'),
  };
}

YouTubeChannelSectionType _channelSectionType(String value) {
  for (final type in YouTubeChannelSectionType.values) {
    if (type.name == value) return type;
  }
  throw const FormatException('type is invalid.');
}

int _ownerCreatorRequiredPositiveInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int && value > 0) return value;
  throw FormatException('$key must be a positive whole number.');
}

String? _ownerCreatorOptionalAllowEmptyText(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('$key must be text.');
}
