import 'dart:convert';

part 'youtube_private_dev_owner_creator_models.dart';
part 'youtube_private_dev_analytics_reporting_models.dart';
part 'youtube_private_dev_live_models.dart';

enum YouTubeConnectPurpose {
  readonly,
  write,
  creatorAssets,
  upload,
  analytics,
  live,
  liveMemberships,
}

enum YouTubeOwnerAnalyticsPreset {
  overview,
  topVideos,
  countries,
  trafficSources,
  devicesOs,
  videoRetention,
}

enum YouTubeUploadProcessingOutcome {
  pending,
  succeeded,
  terminalFailure,
  invalid,
}

enum YouTubeProviderSource { youtube }

enum YouTubeBroadcastState { none, live, upcoming }

enum YouTubeVideoDefinition { hd, sd }

enum YouTubeVideoProjection { rectangular, spherical360 }

enum YouTubePublicVideoUnavailableReason {
  notPublic,
  notEmbeddable,
  processing,
  removedOrRejected,
  regionRestricted,
  ageRestricted,
  childrenDirected,
  metadataInvalid,
  unavailable,
}

enum YouTubeConnectionVerificationState { current, due, reconnectRequired }

enum YouTubeCommentOrder { time, relevance }

enum YouTubeOwnerSubscriptionOrder { alphabetical, relevance, unread }

enum YouTubePublicActivityType {
  upload,
  like,
  favorite,
  playlistItem,
  subscription,
}

enum YouTubePublicChannelSectionType {
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

extension YouTubeConnectPurposeWireValue on YouTubeConnectPurpose {
  String get wireValue => switch (this) {
    YouTubeConnectPurpose.readonly => 'readonly',
    YouTubeConnectPurpose.write => 'write',
    YouTubeConnectPurpose.creatorAssets => 'creatorAssets',
    YouTubeConnectPurpose.upload => 'upload',
    YouTubeConnectPurpose.analytics => 'analytics',
    YouTubeConnectPurpose.live => 'live',
    YouTubeConnectPurpose.liveMemberships => 'liveMemberships',
  };
}

extension YouTubeOwnerAnalyticsPresetWireValue on YouTubeOwnerAnalyticsPreset {
  String get wireValue => switch (this) {
    YouTubeOwnerAnalyticsPreset.overview => 'overview',
    YouTubeOwnerAnalyticsPreset.topVideos => 'topVideos',
    YouTubeOwnerAnalyticsPreset.countries => 'countries',
    YouTubeOwnerAnalyticsPreset.trafficSources => 'trafficSources',
    YouTubeOwnerAnalyticsPreset.devicesOs => 'devicesOs',
    YouTubeOwnerAnalyticsPreset.videoRetention => 'videoRetention',
  };
}

extension YouTubeCommentOrderWireValue on YouTubeCommentOrder {
  String get wireValue => switch (this) {
    YouTubeCommentOrder.time => 'time',
    YouTubeCommentOrder.relevance => 'relevance',
  };
}

extension YouTubeOwnerSubscriptionOrderWireValue
    on YouTubeOwnerSubscriptionOrder {
  String get wireValue => switch (this) {
    YouTubeOwnerSubscriptionOrder.alphabetical => 'alphabetical',
    YouTubeOwnerSubscriptionOrder.relevance => 'relevance',
    YouTubeOwnerSubscriptionOrder.unread => 'unread',
  };
}

class YouTubePrivateDevCapabilities {
  const YouTubePrivateDevCapabilities({
    required this.environment,
    required this.publicData,
    required this.ownerConnect,
    required this.privateUpload,
    required this.ownerAnalytics,
    required this.publicOrUnlistedUpload,
    this.ownerActions = false,
    this.creatorAssets = false,
    this.analyticsV2 = false,
    this.reportingV1 = false,
    this.live = false,
  });

  factory YouTubePrivateDevCapabilities.fromJson(Map<String, Object?> json) {
    return YouTubePrivateDevCapabilities(
      environment: _requiredString(json, 'environment'),
      publicData: _requiredBool(json, 'publicData'),
      ownerConnect: _requiredBool(json, 'ownerConnect'),
      privateUpload: _requiredBool(json, 'privateUpload'),
      ownerAnalytics: _requiredBool(json, 'ownerAnalytics'),
      publicOrUnlistedUpload: _requiredBool(json, 'publicOrUnlistedUpload'),
      ownerActions: _optionalBool(json, 'ownerActions') ?? false,
      creatorAssets: _optionalBool(json, 'creatorAssets') ?? false,
      analyticsV2: _optionalBool(json, 'analyticsV2') ?? false,
      reportingV1: _optionalBool(json, 'reportingV1') ?? false,
      live: _optionalBool(json, 'live') ?? false,
    );
  }

  final String environment;
  final bool publicData;
  final bool ownerConnect;
  final bool privateUpload;
  final bool ownerAnalytics;
  final bool publicOrUnlistedUpload;
  final bool ownerActions;
  final bool creatorAssets;
  final bool analyticsV2;
  final bool reportingV1;
  final bool live;
}

class YouTubeThumbnail {
  const YouTubeThumbnail({required this.url, this.width, this.height});

  factory YouTubeThumbnail.fromJson(Map<String, Object?> json) {
    final width = _optionalPositiveInt(json, 'width');
    final height = _optionalPositiveInt(json, 'height');
    return YouTubeThumbnail(
      url: _requiredUri(json, 'url'),
      width: width,
      height: height,
    );
  }

  final Uri url;
  final int? width;
  final int? height;
}

class YouTubeLocalizedMetadata {
  const YouTubeLocalizedMetadata({
    required this.title,
    required this.description,
  });

  factory YouTubeLocalizedMetadata.fromJson(Map<String, Object?> json) {
    return YouTubeLocalizedMetadata(
      title: _requiredString(json, 'title'),
      description: _requiredText(json, 'description'),
    );
  }

  final String title;
  final String description;
}

class YouTubeRegionRestriction {
  YouTubeRegionRestriction({this.allowed, this.blocked}) {
    if ((allowed == null) == (blocked == null)) {
      throw const FormatException(
        'A region restriction must provide either allowed or blocked regions.',
      );
    }
  }

  factory YouTubeRegionRestriction.fromJson(Map<String, Object?> json) {
    return YouTubeRegionRestriction(
      allowed: _optionalRegionList(json, 'allowed'),
      blocked: _optionalRegionList(json, 'blocked'),
    );
  }

  final List<String>? allowed;
  final List<String>? blocked;
}

class YouTubePublicVideoAvailability {
  const YouTubePublicVideoAvailability({
    required this.regionCode,
    required this.broadcastState,
    required this.syndication,
  });

  factory YouTubePublicVideoAvailability.fromJson(Map<String, Object?> json) {
    _requiredExactString(json, 'state', 'available');
    final syndication = _requiredString(json, 'syndication');
    if (syndication != 'search_filter_confirmed' &&
        syndication != 'embeddable_status_only') {
      throw const FormatException('syndication is invalid.');
    }
    return YouTubePublicVideoAvailability(
      regionCode: _requiredRegionCode(json, 'regionCode'),
      broadcastState: _broadcastState(_requiredString(json, 'broadcastState')),
      syndication: syndication,
    );
  }

  final String regionCode;
  final YouTubeBroadcastState broadcastState;
  final String syndication;
}

class YouTubeLiveStreamingDetails {
  YouTubeLiveStreamingDetails({
    this.actualStartTime,
    this.actualEndTime,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.concurrentViewers,
  }) {
    if (actualStartTime == null &&
        actualEndTime == null &&
        scheduledStartTime == null &&
        scheduledEndTime == null &&
        concurrentViewers == null) {
      throw const FormatException(
        'Live streaming details must contain provider metadata.',
      );
    }
  }

  factory YouTubeLiveStreamingDetails.fromJson(Map<String, Object?> json) {
    return YouTubeLiveStreamingDetails(
      actualStartTime: _optionalDateTime(json, 'actualStartTime'),
      actualEndTime: _optionalDateTime(json, 'actualEndTime'),
      scheduledStartTime: _optionalDateTime(json, 'scheduledStartTime'),
      scheduledEndTime: _optionalDateTime(json, 'scheduledEndTime'),
      concurrentViewers: _optionalCountString(json, 'concurrentViewers'),
    );
  }

  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final DateTime? scheduledStartTime;
  final DateTime? scheduledEndTime;
  final String? concurrentViewers;
}

class YouTubeVideoSummary {
  const YouTubeVideoSummary({
    required this.videoId,
    required this.title,
    required this.channelId,
    required this.channelTitle,
    required this.publishedAt,
    required this.description,
    required this.thumbnail,
    this.categoryId,
    this.tags,
    this.defaultLanguage,
    this.defaultAudioLanguage,
    this.localized,
    this.duration,
    this.captionAvailable,
    this.definition,
    this.licensedContent,
    this.projection,
    this.regionRestriction,
    this.viewCount,
    this.likeCount,
    this.commentCount,
    this.embeddable,
    this.privacyStatus,
    this.uploadStatus,
    this.availability,
    this.liveStreamingDetails,
  });

  factory YouTubeVideoSummary.fromJson(Map<String, Object?> json) {
    return YouTubeVideoSummary(
      videoId: _requiredString(json, 'videoId'),
      title: _requiredString(json, 'title'),
      channelId: _requiredString(json, 'channelId'),
      channelTitle: _requiredString(json, 'channelTitle'),
      publishedAt: _requiredDateTime(json, 'publishedAt'),
      description: _requiredText(json, 'description'),
      thumbnail: YouTubeThumbnail.fromJson(_requiredMap(json, 'thumbnail')),
      categoryId: _optionalCategoryId(json, 'categoryId'),
      tags: _optionalNonEmptyStringList(json, 'tags'),
      defaultLanguage: _optionalLanguageTag(json, 'defaultLanguage'),
      defaultAudioLanguage: _optionalLanguageTag(json, 'defaultAudioLanguage'),
      localized: _optionalMap(
        json,
        'localized',
      )?.let(YouTubeLocalizedMetadata.fromJson),
      duration: _optionalString(json, 'duration'),
      captionAvailable: _optionalBool(json, 'captionAvailable'),
      definition: _optionalVideoDefinition(json, 'definition'),
      licensedContent: _optionalBool(json, 'licensedContent'),
      projection: _optionalVideoProjection(json, 'projection'),
      regionRestriction: _optionalMap(
        json,
        'regionRestriction',
      )?.let(YouTubeRegionRestriction.fromJson),
      viewCount: _optionalCountString(json, 'viewCount'),
      likeCount: _optionalCountString(json, 'likeCount'),
      commentCount: _optionalCountString(json, 'commentCount'),
      embeddable: _optionalBool(json, 'embeddable'),
      privacyStatus: _optionalString(json, 'privacyStatus'),
      uploadStatus: _optionalString(json, 'uploadStatus'),
      availability: _optionalMap(
        json,
        'availability',
      )?.let(YouTubePublicVideoAvailability.fromJson),
      liveStreamingDetails: _optionalMap(
        json,
        'liveStreamingDetails',
      )?.let(YouTubeLiveStreamingDetails.fromJson),
    );
  }

  final String videoId;
  final String title;
  final String channelId;
  final String channelTitle;
  final DateTime publishedAt;
  final String description;
  final YouTubeThumbnail thumbnail;
  final String? categoryId;
  final List<String>? tags;
  final String? defaultLanguage;
  final String? defaultAudioLanguage;
  final YouTubeLocalizedMetadata? localized;
  final String? duration;
  final bool? captionAvailable;
  final YouTubeVideoDefinition? definition;
  final bool? licensedContent;
  final YouTubeVideoProjection? projection;
  final YouTubeRegionRestriction? regionRestriction;
  final String? viewCount;
  final String? likeCount;
  final String? commentCount;
  final bool? embeddable;
  final String? privacyStatus;
  final String? uploadStatus;
  final YouTubePublicVideoAvailability? availability;
  final YouTubeLiveStreamingDetails? liveStreamingDetails;

  YouTubeProviderSource get source => YouTubeProviderSource.youtube;

  YouTubeUploadProcessingOutcome get processingOutcome {
    return switch (uploadStatus?.trim().toLowerCase()) {
      null || 'uploaded' => YouTubeUploadProcessingOutcome.pending,
      'processed' => YouTubeUploadProcessingOutcome.succeeded,
      'failed' ||
      'rejected' ||
      'deleted' => YouTubeUploadProcessingOutcome.terminalFailure,
      _ => YouTubeUploadProcessingOutcome.invalid,
    };
  }

  /// True only when YouTube has successfully processed the upload.
  ///
  /// A terminal failed, rejected, or deleted upload must never satisfy a
  /// caller that is waiting for successful completion.
  bool get processingComplete =>
      processingOutcome == YouTubeUploadProcessingOutcome.succeeded;
}

class YouTubeFilteredVideoSummary {
  YouTubeFilteredVideoSummary({required this.total, required this.reasons}) {
    final summed = reasons.values.fold<int>(0, (total, count) => total + count);
    if (total < 1 || summed != total) {
      throw const FormatException('Filtered video totals are inconsistent.');
    }
  }

  factory YouTubeFilteredVideoSummary.fromJson(Map<String, Object?> json) {
    final rawReasons = _requiredMap(json, 'reasons');
    final reasons = <YouTubePublicVideoUnavailableReason, int>{};
    for (final entry in rawReasons.entries) {
      final reason = _unavailableReason(entry.key);
      final count = entry.value;
      if (count is! int || count < 1 || reasons.containsKey(reason)) {
        throw const FormatException('Filtered video reasons are invalid.');
      }
      reasons[reason] = count;
    }
    return YouTubeFilteredVideoSummary(
      total: _requiredNonNegativeInt(json, 'total'),
      reasons: Map.unmodifiable(reasons),
    );
  }

  final int total;
  final Map<YouTubePublicVideoUnavailableReason, int> reasons;
}

class YouTubeVideoPage {
  const YouTubeVideoPage({
    required this.items,
    this.nextPageToken,
    this.filtered,
  });

  factory YouTubeVideoPage.fromJson(Map<String, Object?> json) {
    return YouTubeVideoPage(
      items: _requiredList(
        json,
        'items',
      ).map(_asMap).map(YouTubeVideoSummary.fromJson).toList(growable: false),
      nextPageToken: _optionalString(json, 'nextPageToken'),
      filtered: _optionalMap(
        json,
        'filtered',
      )?.let(YouTubeFilteredVideoSummary.fromJson),
    );
  }

  final List<YouTubeVideoSummary> items;
  final String? nextPageToken;
  final YouTubeFilteredVideoSummary? filtered;

  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

class YouTubePublicChannelStatistics {
  const YouTubePublicChannelStatistics({
    required this.hiddenSubscriberCount,
    this.viewCount,
    this.subscriberCount,
    this.videoCount,
  });

  factory YouTubePublicChannelStatistics.fromJson(Map<String, Object?> json) {
    return YouTubePublicChannelStatistics(
      viewCount: _optionalCountString(json, 'viewCount'),
      subscriberCount: _optionalCountString(json, 'subscriberCount'),
      hiddenSubscriberCount: _requiredBool(json, 'hiddenSubscriberCount'),
      videoCount: _optionalCountString(json, 'videoCount'),
    );
  }

  final String? viewCount;
  final String? subscriberCount;
  final bool hiddenSubscriberCount;
  final String? videoCount;
}

class YouTubePublicChannelDetails {
  const YouTubePublicChannelDetails({
    required this.channelId,
    required this.title,
    required this.description,
    required this.publishedAt,
    required this.statistics,
    required this.topicCategories,
    this.uploadsPlaylistId,
    this.thumbnail,
    this.customUrl,
    this.country,
  });

  factory YouTubePublicChannelDetails.fromJson(Map<String, Object?> json) {
    return YouTubePublicChannelDetails(
      channelId: _requiredString(json, 'channelId'),
      title: _requiredString(json, 'title'),
      description: _requiredText(json, 'description'),
      publishedAt: _requiredDateTime(json, 'publishedAt'),
      uploadsPlaylistId: _optionalString(json, 'uploadsPlaylistId'),
      thumbnail: _optionalMap(
        json,
        'thumbnail',
      )?.let(YouTubeThumbnail.fromJson),
      customUrl: _optionalString(json, 'customUrl'),
      country: _optionalString(json, 'country'),
      statistics: YouTubePublicChannelStatistics.fromJson(
        _requiredMap(json, 'statistics'),
      ),
      topicCategories: _requiredUriList(json, 'topicCategories'),
    );
  }

  final String channelId;
  final String title;
  final String description;
  final DateTime publishedAt;
  final String? uploadsPlaylistId;
  final YouTubeThumbnail? thumbnail;
  final String? customUrl;
  final String? country;
  final YouTubePublicChannelStatistics statistics;
  final List<Uri> topicCategories;

  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

class YouTubePublicPlaylistDetails {
  const YouTubePublicPlaylistDetails({
    required this.playlistId,
    required this.title,
    required this.description,
    required this.publishedAt,
    required this.channelId,
    required this.channelTitle,
    required this.itemCount,
    this.defaultLanguage,
    this.localized,
    this.thumbnail,
  });

  factory YouTubePublicPlaylistDetails.fromJson(Map<String, Object?> json) {
    _requiredExactString(json, 'privacyStatus', 'public');
    return YouTubePublicPlaylistDetails(
      playlistId: _requiredString(json, 'playlistId'),
      title: _requiredString(json, 'title'),
      description: _requiredText(json, 'description'),
      publishedAt: _requiredDateTime(json, 'publishedAt'),
      channelId: _requiredString(json, 'channelId'),
      channelTitle: _requiredString(json, 'channelTitle'),
      itemCount: _requiredNonNegativeInt(json, 'itemCount'),
      defaultLanguage: _optionalLanguageTag(json, 'defaultLanguage'),
      localized: _optionalMap(
        json,
        'localized',
      )?.let(YouTubeLocalizedMetadata.fromJson),
      thumbnail: _optionalMap(
        json,
        'thumbnail',
      )?.let(YouTubeThumbnail.fromJson),
    );
  }

  final String playlistId;
  final String title;
  final String description;
  final DateTime publishedAt;
  final String channelId;
  final String channelTitle;
  final int itemCount;
  final String? defaultLanguage;
  final YouTubeLocalizedMetadata? localized;
  final YouTubeThumbnail? thumbnail;

  String get privacyStatus => 'public';
  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

class YouTubePublicPlaylistPage {
  const YouTubePublicPlaylistPage({required this.items, this.nextPageToken});

  factory YouTubePublicPlaylistPage.fromJson(Map<String, Object?> json) {
    return YouTubePublicPlaylistPage(
      items: _requiredList(json, 'items')
          .map(_asMap)
          .map(YouTubePublicPlaylistDetails.fromJson)
          .toList(growable: false),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final List<YouTubePublicPlaylistDetails> items;
  final String? nextPageToken;

  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

class YouTubePublicRegion {
  const YouTubePublicRegion({required this.regionCode, required this.name});

  factory YouTubePublicRegion.fromJson(Map<String, Object?> json) {
    return YouTubePublicRegion(
      regionCode: _requiredRegionCode(json, 'regionCode'),
      name: _requiredString(json, 'name'),
    );
  }

  final String regionCode;
  final String name;
  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

class YouTubePublicLanguage {
  const YouTubePublicLanguage({required this.languageCode, required this.name});

  factory YouTubePublicLanguage.fromJson(Map<String, Object?> json) {
    return YouTubePublicLanguage(
      languageCode: _requiredLanguageTag(json, 'languageCode'),
      name: _requiredString(json, 'name'),
    );
  }

  final String languageCode;
  final String name;
  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

class YouTubePublicVideoCategory {
  const YouTubePublicVideoCategory({
    required this.categoryId,
    required this.title,
    required this.assignable,
    this.channelId,
  });

  factory YouTubePublicVideoCategory.fromJson(Map<String, Object?> json) {
    return YouTubePublicVideoCategory(
      categoryId: _requiredCategoryId(json, 'categoryId'),
      title: _requiredString(json, 'title'),
      assignable: _requiredBool(json, 'assignable'),
      channelId: _optionalString(json, 'channelId'),
    );
  }

  final String categoryId;
  final String title;
  final bool assignable;
  final String? channelId;
  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

class YouTubeVideoStatisticsSnapshot {
  const YouTubeVideoStatisticsSnapshot({
    required this.videoId,
    this.publishTime,
    this.viewCount,
    this.likeCount,
    this.commentCount,
    this.duration,
    this.durationMillis,
  });

  factory YouTubeVideoStatisticsSnapshot.fromJson(Map<String, Object?> json) {
    return YouTubeVideoStatisticsSnapshot(
      videoId: _requiredString(json, 'videoId'),
      publishTime: _optionalDateTime(json, 'publishTime'),
      viewCount: _optionalCountString(json, 'viewCount'),
      likeCount: _optionalCountString(json, 'likeCount'),
      commentCount: _optionalCountString(json, 'commentCount'),
      duration: _optionalString(json, 'duration'),
      durationMillis: _optionalCountString(json, 'durationMillis'),
    );
  }

  final String videoId;
  final DateTime? publishTime;
  final String? viewCount;
  final String? likeCount;
  final String? commentCount;
  final String? duration;
  final String? durationMillis;
}

class YouTubeBatchStatisticsSummary {
  YouTubeBatchStatisticsSummary({
    required this.requestedVideoCount,
    required this.succeededVideoCount,
    required this.failedVideoCount,
    required this.failedVideoIds,
  }) {
    if (succeededVideoCount + failedVideoCount != requestedVideoCount ||
        failedVideoIds.length != failedVideoCount) {
      throw const FormatException('Batch statistics summary is inconsistent.');
    }
  }

  factory YouTubeBatchStatisticsSummary.fromJson(Map<String, Object?> json) {
    return YouTubeBatchStatisticsSummary(
      requestedVideoCount: _requiredCount(json, 'requestedVideoCount'),
      succeededVideoCount: _requiredCount(json, 'succeededVideoCount'),
      failedVideoCount: _requiredCount(json, 'failedVideoCount'),
      failedVideoIds: _requiredNonEmptyStringList(
        json,
        'failedVideoIds',
        allowEmpty: true,
      ),
    );
  }

  final int requestedVideoCount;
  final int succeededVideoCount;
  final int failedVideoCount;
  final List<String> failedVideoIds;
}

class YouTubeBatchStatisticsResult {
  YouTubeBatchStatisticsResult({required this.items, required this.summary}) {
    if (items.length != summary.succeededVideoCount) {
      throw const FormatException(
        'Batch statistics items are inconsistent with the summary.',
      );
    }
  }

  factory YouTubeBatchStatisticsResult.fromJson(Map<String, Object?> json) {
    return YouTubeBatchStatisticsResult(
      items: _requiredList(json, 'items')
          .map(_asMap)
          .map(YouTubeVideoStatisticsSnapshot.fromJson)
          .toList(growable: false),
      summary: YouTubeBatchStatisticsSummary.fromJson(
        _requiredMap(json, 'summary'),
      ),
    );
  }

  final List<YouTubeVideoStatisticsSnapshot> items;
  final YouTubeBatchStatisticsSummary summary;
  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

class YouTubePublicCommentAuthor {
  const YouTubePublicCommentAuthor({
    required this.displayName,
    this.profileImageUrl,
    this.channelId,
    this.channelUrl,
  });

  factory YouTubePublicCommentAuthor.fromJson(Map<String, Object?> json) {
    return YouTubePublicCommentAuthor(
      displayName: _requiredString(json, 'displayName'),
      profileImageUrl: _optionalUri(json, 'profileImageUrl'),
      channelId: _optionalString(json, 'channelId'),
      channelUrl: _optionalUri(json, 'channelUrl'),
    );
  }

  final String displayName;
  final Uri? profileImageUrl;
  final String? channelId;
  final Uri? channelUrl;
}

class YouTubePublicComment {
  const YouTubePublicComment({
    required this.commentId,
    required this.textDisplay,
    required this.author,
    required this.associatedChannelId,
    required this.likeCount,
    required this.publishedAt,
    required this.updatedAt,
    this.parentId,
  });

  factory YouTubePublicComment.fromJson(Map<String, Object?> json) {
    _requiredExactString(json, 'textFormat', 'plainText');
    return YouTubePublicComment(
      commentId: _requiredString(json, 'commentId'),
      textDisplay: _requiredString(json, 'textDisplay'),
      author: YouTubePublicCommentAuthor.fromJson(_requiredMap(json, 'author')),
      associatedChannelId: _requiredString(json, 'associatedChannelId'),
      likeCount: _requiredNonNegativeInt(json, 'likeCount'),
      publishedAt: _requiredDateTime(json, 'publishedAt'),
      updatedAt: _requiredDateTime(json, 'updatedAt'),
      parentId: _optionalString(json, 'parentId'),
    );
  }

  final String commentId;

  /// Complete provider-returned plain text. It is never provider HTML.
  final String textDisplay;
  final YouTubePublicCommentAuthor author;
  final String associatedChannelId;
  final int likeCount;
  final DateTime publishedAt;
  final DateTime updatedAt;
  final String? parentId;

  String get textFormat => 'plainText';
  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

class YouTubePublicCommentThread {
  YouTubePublicCommentThread({
    required this.threadId,
    required this.videoId,
    required this.channelId,
    required this.topLevelComment,
    required this.replies,
    required this.totalReplyCount,
    required this.includedReplyCount,
    required this.repliesComplete,
    required this.isPublic,
  }) {
    if (includedReplyCount != replies.length ||
        includedReplyCount > totalReplyCount ||
        repliesComplete != (includedReplyCount == totalReplyCount)) {
      throw const FormatException('Comment reply counts are inconsistent.');
    }
  }

  factory YouTubePublicCommentThread.fromJson(Map<String, Object?> json) {
    return YouTubePublicCommentThread(
      threadId: _requiredString(json, 'threadId'),
      videoId: _requiredString(json, 'videoId'),
      channelId: _requiredString(json, 'channelId'),
      topLevelComment: YouTubePublicComment.fromJson(
        _requiredMap(json, 'topLevelComment'),
      ),
      replies: _requiredList(
        json,
        'replies',
      ).map(_asMap).map(YouTubePublicComment.fromJson).toList(growable: false),
      totalReplyCount: _requiredNonNegativeInt(json, 'totalReplyCount'),
      includedReplyCount: _requiredNonNegativeInt(json, 'includedReplyCount'),
      repliesComplete: _requiredBool(json, 'repliesComplete'),
      isPublic: _requiredBool(json, 'isPublic'),
    );
  }

  final String threadId;
  final String videoId;
  final String channelId;
  final YouTubePublicComment topLevelComment;
  final List<YouTubePublicComment> replies;
  final int totalReplyCount;
  final int includedReplyCount;
  final bool repliesComplete;
  final bool isPublic;
}

class YouTubePublicCommentAttribution {
  const YouTubePublicCommentAttribution({
    required this.videoId,
    required this.videoTitle,
    required this.channelId,
    required this.channelTitle,
  });

  factory YouTubePublicCommentAttribution.fromJson(Map<String, Object?> json) {
    _requiredExactString(json, 'source', 'youtube');
    return YouTubePublicCommentAttribution(
      videoId: _requiredString(json, 'videoId'),
      videoTitle: _requiredString(json, 'videoTitle'),
      channelId: _requiredString(json, 'channelId'),
      channelTitle: _requiredString(json, 'channelTitle'),
    );
  }

  final String videoId;
  final String videoTitle;
  final String channelId;
  final String channelTitle;
  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

class YouTubePublicCommentReplyAttribution
    extends YouTubePublicCommentAttribution {
  const YouTubePublicCommentReplyAttribution({
    required super.videoId,
    required super.videoTitle,
    required super.channelId,
    required super.channelTitle,
    required this.threadId,
    required this.parentCommentId,
  });

  factory YouTubePublicCommentReplyAttribution.fromJson(
    Map<String, Object?> json,
  ) {
    _requiredExactString(json, 'source', 'youtube');
    return YouTubePublicCommentReplyAttribution(
      videoId: _requiredString(json, 'videoId'),
      videoTitle: _requiredString(json, 'videoTitle'),
      channelId: _requiredString(json, 'channelId'),
      channelTitle: _requiredString(json, 'channelTitle'),
      threadId: _requiredString(json, 'threadId'),
      parentCommentId: _requiredString(json, 'parentCommentId'),
    );
  }

  final String threadId;
  final String parentCommentId;
}

class YouTubePublicCommentThreadsPage {
  const YouTubePublicCommentThreadsPage({
    required this.attribution,
    required this.items,
    this.nextPageToken,
  });

  factory YouTubePublicCommentThreadsPage.fromJson(Map<String, Object?> json) {
    return YouTubePublicCommentThreadsPage(
      attribution: YouTubePublicCommentAttribution.fromJson(
        _requiredMap(json, 'attribution'),
      ),
      items: _requiredList(json, 'items')
          .map(_asMap)
          .map(YouTubePublicCommentThread.fromJson)
          .toList(growable: false),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final YouTubePublicCommentAttribution attribution;
  final List<YouTubePublicCommentThread> items;
  final String? nextPageToken;
}

class YouTubePublicCommentRepliesPage {
  const YouTubePublicCommentRepliesPage({
    required this.attribution,
    required this.items,
    this.nextPageToken,
  });

  factory YouTubePublicCommentRepliesPage.fromJson(Map<String, Object?> json) {
    return YouTubePublicCommentRepliesPage(
      attribution: YouTubePublicCommentReplyAttribution.fromJson(
        _requiredMap(json, 'attribution'),
      ),
      items: _requiredList(
        json,
        'items',
      ).map(_asMap).map(YouTubePublicComment.fromJson).toList(growable: false),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final YouTubePublicCommentReplyAttribution attribution;
  final List<YouTubePublicComment> items;
  final String? nextPageToken;
}

sealed class YouTubePublicActivityTarget {
  const YouTubePublicActivityTarget();

  factory YouTubePublicActivityTarget.fromJson(Map<String, Object?> json) {
    return switch (_requiredString(json, 'kind')) {
      'video' => YouTubePublicActivityVideoTarget.fromJson(json),
      'channel' => YouTubePublicActivityChannelTarget.fromJson(json),
      _ => throw const FormatException('Activity target kind is invalid.'),
    };
  }
}

final class YouTubePublicActivityVideoTarget
    extends YouTubePublicActivityTarget {
  const YouTubePublicActivityVideoTarget({
    required this.videoId,
    this.playlistId,
    this.playlistItemId,
  });

  factory YouTubePublicActivityVideoTarget.fromJson(Map<String, Object?> json) {
    _requiredExactString(json, 'kind', 'video');
    return YouTubePublicActivityVideoTarget(
      videoId: _requiredString(json, 'videoId'),
      playlistId: _optionalString(json, 'playlistId'),
      playlistItemId: _optionalString(json, 'playlistItemId'),
    );
  }

  final String videoId;
  final String? playlistId;
  final String? playlistItemId;
}

final class YouTubePublicActivityChannelTarget
    extends YouTubePublicActivityTarget {
  const YouTubePublicActivityChannelTarget({required this.channelId});

  factory YouTubePublicActivityChannelTarget.fromJson(
    Map<String, Object?> json,
  ) {
    _requiredExactString(json, 'kind', 'channel');
    return YouTubePublicActivityChannelTarget(
      channelId: _requiredString(json, 'channelId'),
    );
  }

  final String channelId;
}

class YouTubePublicChannelActivity {
  const YouTubePublicChannelActivity({
    required this.activityId,
    required this.channelId,
    required this.channelTitle,
    required this.publishedAt,
    required this.type,
    required this.title,
    required this.description,
    required this.target,
    this.thumbnail,
    this.groupId,
  });

  factory YouTubePublicChannelActivity.fromJson(Map<String, Object?> json) {
    return YouTubePublicChannelActivity(
      activityId: _requiredString(json, 'activityId'),
      channelId: _requiredString(json, 'channelId'),
      channelTitle: _requiredString(json, 'channelTitle'),
      publishedAt: _requiredDateTime(json, 'publishedAt'),
      type: _publicActivityType(_requiredString(json, 'type')),
      title: _requiredString(json, 'title'),
      description: _requiredText(json, 'description'),
      target: YouTubePublicActivityTarget.fromJson(
        _requiredMap(json, 'target'),
      ),
      thumbnail: _optionalMap(
        json,
        'thumbnail',
      )?.let(YouTubeThumbnail.fromJson),
      groupId: _optionalString(json, 'groupId'),
    );
  }

  final String activityId;
  final String channelId;
  final String channelTitle;
  final DateTime publishedAt;
  final YouTubePublicActivityType type;
  final String title;
  final String description;
  final YouTubePublicActivityTarget target;
  final YouTubeThumbnail? thumbnail;
  final String? groupId;
  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

class YouTubePublicChannelActivitiesPage {
  const YouTubePublicChannelActivitiesPage({
    required this.channelId,
    required this.regionCode,
    required this.items,
    required this.omittedByFilterOrUnsupportedCount,
    this.nextPageToken,
  });

  factory YouTubePublicChannelActivitiesPage.fromJson(
    Map<String, Object?> json,
  ) {
    _requiredExactString(json, 'source', 'youtube');
    _requiredExactString(json, 'feedScope', 'publicChannel');
    return YouTubePublicChannelActivitiesPage(
      channelId: _requiredString(json, 'channelId'),
      regionCode: _requiredRegionCode(json, 'regionCode'),
      items: _requiredList(json, 'items')
          .map(_asMap)
          .map(YouTubePublicChannelActivity.fromJson)
          .toList(growable: false),
      omittedByFilterOrUnsupportedCount: _requiredNonNegativeInt(
        json,
        'omittedByFilterOrUnsupportedCount',
      ),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final String channelId;
  final String regionCode;
  final List<YouTubePublicChannelActivity> items;
  final int omittedByFilterOrUnsupportedCount;
  final String? nextPageToken;
  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

class YouTubePublicChannelSection {
  const YouTubePublicChannelSection({
    required this.sectionId,
    required this.channelId,
    required this.type,
    required this.position,
    this.title,
    this.playlistIds,
    this.channelIds,
  });

  factory YouTubePublicChannelSection.fromJson(Map<String, Object?> json) {
    return YouTubePublicChannelSection(
      sectionId: _requiredString(json, 'sectionId'),
      channelId: _requiredString(json, 'channelId'),
      type: _publicChannelSectionType(_requiredString(json, 'type')),
      position: _requiredNonNegativeInt(json, 'position'),
      title: _optionalString(json, 'title'),
      playlistIds: _optionalNonEmptyStringList(json, 'playlistIds'),
      channelIds: _optionalNonEmptyStringList(json, 'channelIds'),
    );
  }

  final String sectionId;
  final String channelId;
  final YouTubePublicChannelSectionType type;
  final int position;
  final String? title;
  final List<String>? playlistIds;
  final List<String>? channelIds;
}

class YouTubePublicChannelSectionsResult {
  const YouTubePublicChannelSectionsResult({
    required this.channelId,
    required this.items,
  });

  factory YouTubePublicChannelSectionsResult.fromJson(
    Map<String, Object?> json,
  ) {
    _requiredExactString(json, 'source', 'youtube');
    return YouTubePublicChannelSectionsResult(
      channelId: _requiredString(json, 'channelId'),
      items: _requiredList(json, 'items')
          .map(_asMap)
          .map(YouTubePublicChannelSection.fromJson)
          .toList(growable: false),
    );
  }

  final String channelId;
  final List<YouTubePublicChannelSection> items;
  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

sealed class YouTubeConnectionStatus {
  const YouTubeConnectionStatus();

  factory YouTubeConnectionStatus.fromJson(Map<String, Object?> json) {
    final connected = _requiredBool(json, 'connected');
    final verificationState = _connectionVerificationState(
      _requiredString(json, 'verificationState'),
    );
    if (!connected) {
      if (verificationState !=
          YouTubeConnectionVerificationState.reconnectRequired) {
        throw const FormatException(
          'A disconnected channel must require reconnection.',
        );
      }
      return YouTubeDisconnected(
        lastVerifiedAt: _nullableDateTime(json, 'lastVerifiedAt'),
        nextVerificationDueAt: _nullableDateTime(json, 'nextVerificationDueAt'),
      );
    }
    if (verificationState ==
        YouTubeConnectionVerificationState.reconnectRequired) {
      throw const FormatException(
        'A connected channel cannot require reconnection.',
      );
    }
    return YouTubeConnected(
      channelId: _requiredString(json, 'channelId'),
      channelTitle: _requiredString(json, 'channelTitle'),
      grantedScopes: _requiredNonEmptyStringList(json, 'grantedScopes'),
      lastVerifiedAt: _requiredDateTime(json, 'lastVerifiedAt'),
      nextVerificationDueAt: _requiredDateTime(json, 'nextVerificationDueAt'),
      verificationState: verificationState,
    );
  }
}

final class YouTubeDisconnected extends YouTubeConnectionStatus {
  const YouTubeDisconnected({this.lastVerifiedAt, this.nextVerificationDueAt});

  final DateTime? lastVerifiedAt;
  final DateTime? nextVerificationDueAt;
  YouTubeConnectionVerificationState get verificationState =>
      YouTubeConnectionVerificationState.reconnectRequired;
}

final class YouTubeConnected extends YouTubeConnectionStatus {
  const YouTubeConnected({
    required this.channelId,
    required this.channelTitle,
    required this.grantedScopes,
    this.lastVerifiedAt,
    this.nextVerificationDueAt,
    this.verificationState = YouTubeConnectionVerificationState.current,
  });

  final String channelId;
  final String channelTitle;
  final List<String> grantedScopes;
  final DateTime? lastVerifiedAt;
  final DateTime? nextVerificationDueAt;
  final YouTubeConnectionVerificationState verificationState;
}

class YouTubeConnectionStart {
  const YouTubeConnectionStart({
    required this.authorizationUrl,
    required this.expiresAt,
  });

  factory YouTubeConnectionStart.fromJson(Map<String, Object?> json) {
    return YouTubeConnectionStart(
      authorizationUrl: _requiredUri(json, 'authorizationUrl'),
      expiresAt: _requiredDateTime(json, 'expiresAt'),
    );
  }

  final Uri authorizationUrl;
  final DateTime expiresAt;
}

class YouTubeOwnerAttribution {
  const YouTubeOwnerAttribution({
    required this.channelId,
    required this.channelTitle,
  });

  factory YouTubeOwnerAttribution.fromJson(Map<String, Object?> json) {
    _requiredExactString(json, 'source', 'youtube');
    return YouTubeOwnerAttribution(
      channelId: _requiredString(json, 'channelId'),
      channelTitle: _requiredString(json, 'channelTitle'),
    );
  }

  final String channelId;
  final String channelTitle;
  YouTubeProviderSource get source => YouTubeProviderSource.youtube;
}

sealed class YouTubeOwnerVideo {
  const YouTubeOwnerVideo({
    required this.playlistItemId,
    required this.playlistPublishedAt,
    required this.position,
  });

  factory YouTubeOwnerVideo.fromJson(Map<String, Object?> json) {
    final state = _requiredString(json, 'state');
    return switch (state) {
      'available' => YouTubeOwnerAvailableVideo.fromJson(json),
      'unavailable' => YouTubeOwnerUnavailableVideo.fromJson(json),
      _ => throw const FormatException('Owner video state is invalid.'),
    };
  }

  final String playlistItemId;
  final DateTime? playlistPublishedAt;
  final int? position;
}

final class YouTubeOwnerUnavailableVideo extends YouTubeOwnerVideo {
  const YouTubeOwnerUnavailableVideo({
    required super.playlistItemId,
    required super.playlistPublishedAt,
    required super.position,
    this.videoId,
  });

  factory YouTubeOwnerUnavailableVideo.fromJson(Map<String, Object?> json) {
    _requiredExactString(json, 'state', 'unavailable');
    return YouTubeOwnerUnavailableVideo(
      playlistItemId: _requiredString(json, 'playlistItemId'),
      videoId: _optionalString(json, 'videoId'),
      playlistPublishedAt: _optionalDateTime(json, 'playlistPublishedAt'),
      position: _optionalNonNegativeInt(json, 'position'),
    );
  }

  final String? videoId;
}

final class YouTubeOwnerAvailableVideo extends YouTubeOwnerVideo {
  const YouTubeOwnerAvailableVideo({
    required super.playlistItemId,
    required super.playlistPublishedAt,
    required super.position,
    required this.video,
  });

  factory YouTubeOwnerAvailableVideo.fromJson(Map<String, Object?> json) {
    _requiredExactString(json, 'state', 'available');
    return YouTubeOwnerAvailableVideo(
      playlistItemId: _requiredString(json, 'playlistItemId'),
      playlistPublishedAt: _optionalDateTime(json, 'playlistPublishedAt'),
      position: _optionalNonNegativeInt(json, 'position'),
      video: YouTubeVideoSummary.fromJson(_requiredMap(json, 'video')),
    );
  }

  final YouTubeVideoSummary video;
}

class YouTubeOwnerVideosPage {
  const YouTubeOwnerVideosPage({
    required this.attribution,
    required this.items,
    this.nextPageToken,
  });

  factory YouTubeOwnerVideosPage.fromJson(Map<String, Object?> json) {
    return YouTubeOwnerVideosPage(
      attribution: YouTubeOwnerAttribution.fromJson(
        _requiredMap(json, 'attribution'),
      ),
      items: _requiredList(
        json,
        'items',
      ).map(_asMap).map(YouTubeOwnerVideo.fromJson).toList(growable: false),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final YouTubeOwnerAttribution attribution;
  final List<YouTubeOwnerVideo> items;
  final String? nextPageToken;
}

class YouTubeOwnerSubscription {
  const YouTubeOwnerSubscription({
    required this.subscriptionId,
    required this.channelId,
    required this.channelTitle,
    required this.description,
    required this.publishedAt,
    this.thumbnail,
  });

  factory YouTubeOwnerSubscription.fromJson(Map<String, Object?> json) {
    return YouTubeOwnerSubscription(
      subscriptionId: _requiredString(json, 'subscriptionId'),
      channelId: _requiredString(json, 'channelId'),
      channelTitle: _requiredString(json, 'channelTitle'),
      description: _requiredText(json, 'description'),
      publishedAt: _requiredDateTime(json, 'publishedAt'),
      thumbnail: _optionalMap(
        json,
        'thumbnail',
      )?.let(YouTubeThumbnail.fromJson),
    );
  }

  final String subscriptionId;
  final String channelId;
  final String channelTitle;
  final String description;
  final DateTime publishedAt;
  final YouTubeThumbnail? thumbnail;
}

class YouTubeOwnerSubscriptionsPage {
  const YouTubeOwnerSubscriptionsPage({
    required this.attribution,
    required this.items,
    this.nextPageToken,
  });

  factory YouTubeOwnerSubscriptionsPage.fromJson(Map<String, Object?> json) {
    return YouTubeOwnerSubscriptionsPage(
      attribution: YouTubeOwnerAttribution.fromJson(
        _requiredMap(json, 'attribution'),
      ),
      items: _requiredList(json, 'items')
          .map(_asMap)
          .map(YouTubeOwnerSubscription.fromJson)
          .toList(growable: false),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final YouTubeOwnerAttribution attribution;
  final List<YouTubeOwnerSubscription> items;
  final String? nextPageToken;
}

class YouTubeOwnerPlaylist {
  const YouTubeOwnerPlaylist({
    required this.playlistId,
    required this.title,
    required this.description,
    required this.publishedAt,
    required this.channelId,
    required this.channelTitle,
    required this.itemCount,
    required this.privacyStatus,
    this.thumbnail,
  });

  factory YouTubeOwnerPlaylist.fromJson(Map<String, Object?> json) {
    final privacyStatus = _requiredString(json, 'privacyStatus');
    if (privacyStatus != 'private' &&
        privacyStatus != 'public' &&
        privacyStatus != 'unlisted') {
      throw const FormatException('Playlist privacy status is invalid.');
    }
    return YouTubeOwnerPlaylist(
      playlistId: _requiredString(json, 'playlistId'),
      title: _requiredString(json, 'title'),
      description: _requiredText(json, 'description'),
      publishedAt: _requiredDateTime(json, 'publishedAt'),
      channelId: _requiredString(json, 'channelId'),
      channelTitle: _requiredString(json, 'channelTitle'),
      itemCount: _requiredNonNegativeInt(json, 'itemCount'),
      privacyStatus: privacyStatus,
      thumbnail: _optionalMap(
        json,
        'thumbnail',
      )?.let(YouTubeThumbnail.fromJson),
    );
  }

  final String playlistId;
  final String title;
  final String description;
  final DateTime publishedAt;
  final String channelId;
  final String channelTitle;
  final int itemCount;
  final String privacyStatus;
  final YouTubeThumbnail? thumbnail;
}

class YouTubeOwnerPlaylistsPage {
  const YouTubeOwnerPlaylistsPage({
    required this.attribution,
    required this.items,
    this.nextPageToken,
  });

  factory YouTubeOwnerPlaylistsPage.fromJson(Map<String, Object?> json) {
    return YouTubeOwnerPlaylistsPage(
      attribution: YouTubeOwnerAttribution.fromJson(
        _requiredMap(json, 'attribution'),
      ),
      items: _requiredList(
        json,
        'items',
      ).map(_asMap).map(YouTubeOwnerPlaylist.fromJson).toList(growable: false),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final YouTubeOwnerAttribution attribution;
  final List<YouTubeOwnerPlaylist> items;
  final String? nextPageToken;
}

class YouTubePrivateUploadMetadata {
  const YouTubePrivateUploadMetadata({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.madeForKids,
    required this.containsSyntheticMedia,
    required this.containsPaidPromotion,
    required this.notifySubscribers,
  });

  final String title;
  final String description;
  final String categoryId;
  final bool madeForKids;
  final bool containsSyntheticMedia;
  final bool containsPaidPromotion;
  final bool notifySubscribers;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'madeForKids': madeForKids,
      'containsSyntheticMedia': containsSyntheticMedia,
      'containsPaidPromotion': containsPaidPromotion,
      'notifySubscribers': notifySubscribers,
    };
  }
}

class YouTubeUploadFileIdentity {
  YouTubeUploadFileIdentity({
    required this.digest,
    required this.byteLength,
    required String contentType,
  }) : contentType = contentType.trim().toLowerCase() {
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(digest) ||
        byteLength < 1 ||
        this.contentType.isEmpty) {
      throw const FormatException('A valid video file identity is required.');
    }
  }

  final String digest;
  final int byteLength;
  final String contentType;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'algorithm': 'sha256',
      'digest': digest,
      'byteLength': byteLength,
      'contentType': contentType,
    };
  }

  bool matches(YouTubeUploadFileIdentity other) {
    return digest == other.digest &&
        byteLength == other.byteLength &&
        contentType == other.contentType;
  }
}

class YouTubePrivateUploadSession {
  const YouTubePrivateUploadSession({
    required this.jobKey,
    required this.sessionUrl,
    required this.expiresAt,
    required this.privacyStatus,
    required this.contentType,
    required this.contentLength,
    required this.fileIdentity,
  });

  factory YouTubePrivateUploadSession.fromJson(
    Map<String, Object?> json, {
    required String contentType,
    required int contentLength,
    required YouTubeUploadFileIdentity fileIdentity,
  }) {
    final privacyStatus = _requiredString(json, 'privacyStatus');
    if (privacyStatus != 'private') {
      throw const FormatException(
        'Private Dev returned a non-private upload session.',
      );
    }
    return YouTubePrivateUploadSession(
      jobKey: _requiredString(json, 'jobKey'),
      sessionUrl: _requiredUri(json, 'sessionUrl'),
      expiresAt: _requiredDateTime(json, 'expiresAt'),
      privacyStatus: privacyStatus,
      contentType: contentType,
      contentLength: contentLength,
      fileIdentity: fileIdentity,
    );
  }

  final String jobKey;
  final Uri sessionUrl;
  final DateTime expiresAt;
  final String privacyStatus;
  final String contentType;
  final int contentLength;
  final YouTubeUploadFileIdentity fileIdentity;
}

class YouTubeAnalyticsRow {
  const YouTubeAnalyticsRow({required this.dimensions, required this.metrics});

  factory YouTubeAnalyticsRow.fromJson(Map<String, Object?> json) {
    final dimensions = _requiredMap(
      json,
      'dimensions',
    ).map((key, value) => MapEntry(key, value as String));
    final metrics = _requiredMap(
      json,
      'metrics',
    ).map((key, value) => MapEntry(key, value as num));
    return YouTubeAnalyticsRow(
      dimensions: Map.unmodifiable(dimensions),
      metrics: Map.unmodifiable(metrics),
    );
  }

  final Map<String, String> dimensions;
  final Map<String, num> metrics;
}

class YouTubeOwnerAnalyticsResult {
  const YouTubeOwnerAnalyticsResult({
    required this.preset,
    required this.startDate,
    required this.endDate,
    required this.requestedStartDate,
    required this.requestedEndDate,
    required this.rows,
    required this.empty,
    required this.providerMayExcludeRecentIncompleteDays,
    this.videoId,
    this.continuationStartIndex,
  });

  factory YouTubeOwnerAnalyticsResult.fromJson(Map<String, Object?> json) {
    final requestedRange = _requiredMap(json, 'requestedRange');
    final preset = _analyticsPreset(_requiredString(json, 'preset'));
    return YouTubeOwnerAnalyticsResult(
      preset: preset,
      startDate: _requiredString(json, 'startDate'),
      endDate: _requiredString(json, 'endDate'),
      requestedStartDate: _requiredString(requestedRange, 'startDate'),
      requestedEndDate: _requiredString(requestedRange, 'endDate'),
      videoId: _optionalString(json, 'videoId'),
      rows: _requiredList(
        json,
        'rows',
      ).map(_asMap).map(YouTubeAnalyticsRow.fromJson).toList(growable: false),
      continuationStartIndex: _optionalInt(json, 'continuationStartIndex'),
      empty: _requiredBool(json, 'empty'),
      providerMayExcludeRecentIncompleteDays: _requiredBool(
        json,
        'providerMayExcludeRecentIncompleteDays',
      ),
    );
  }

  final YouTubeOwnerAnalyticsPreset preset;
  final String startDate;
  final String endDate;
  final String requestedStartDate;
  final String requestedEndDate;
  final String? videoId;
  final List<YouTubeAnalyticsRow> rows;
  final int? continuationStartIndex;
  final bool empty;
  final bool providerMayExcludeRecentIncompleteDays;
}

class YouTubeDisconnectResult {
  const YouTubeDisconnectResult({
    required this.disconnected,
    required this.providerRevocationConfirmed,
  });

  factory YouTubeDisconnectResult.fromJson(Map<String, Object?> json) {
    return YouTubeDisconnectResult(
      disconnected: _requiredBool(json, 'disconnected'),
      providerRevocationConfirmed: _requiredBool(
        json,
        'providerRevocationConfirmed',
      ),
    );
  }

  final bool disconnected;
  final bool providerRevocationConfirmed;
}

YouTubeOwnerAnalyticsPreset _analyticsPreset(String value) {
  return switch (value) {
    'overview' => YouTubeOwnerAnalyticsPreset.overview,
    'topVideos' => YouTubeOwnerAnalyticsPreset.topVideos,
    'countries' => YouTubeOwnerAnalyticsPreset.countries,
    'trafficSources' => YouTubeOwnerAnalyticsPreset.trafficSources,
    'devicesOs' => YouTubeOwnerAnalyticsPreset.devicesOs,
    'videoRetention' => YouTubeOwnerAnalyticsPreset.videoRetention,
    _ => throw const FormatException(
      'preset must be a supported analytics preset.',
    ),
  };
}

YouTubePublicActivityType _publicActivityType(String value) {
  return switch (value) {
    'upload' => YouTubePublicActivityType.upload,
    'like' => YouTubePublicActivityType.like,
    'favorite' => YouTubePublicActivityType.favorite,
    'playlistItem' => YouTubePublicActivityType.playlistItem,
    'subscription' => YouTubePublicActivityType.subscription,
    _ => throw const FormatException('Public activity type is invalid.'),
  };
}

YouTubePublicChannelSectionType _publicChannelSectionType(String value) {
  return switch (value) {
    'allPlaylists' => YouTubePublicChannelSectionType.allPlaylists,
    'completedEvents' => YouTubePublicChannelSectionType.completedEvents,
    'liveEvents' => YouTubePublicChannelSectionType.liveEvents,
    'multipleChannels' => YouTubePublicChannelSectionType.multipleChannels,
    'multiplePlaylists' => YouTubePublicChannelSectionType.multiplePlaylists,
    'popularUploads' => YouTubePublicChannelSectionType.popularUploads,
    'recentUploads' => YouTubePublicChannelSectionType.recentUploads,
    'singlePlaylist' => YouTubePublicChannelSectionType.singlePlaylist,
    'subscriptions' => YouTubePublicChannelSectionType.subscriptions,
    'upcomingEvents' => YouTubePublicChannelSectionType.upcomingEvents,
    _ => throw const FormatException('Public channel section type is invalid.'),
  };
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw FormatException('$key must be an object.');
}

Map<String, Object?>? _optionalMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  return _asMap(value);
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const FormatException('Expected an object.');
}

List<Object?> _requiredList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is List<Object?>) return value;
  if (value is List) return value.cast<Object?>();
  throw FormatException('$key must be a list.');
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('$key must be text.');
}

String _requiredText(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('$key must be text.');
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('$key must be text.');
}

void _requiredExactString(
  Map<String, Object?> json,
  String key,
  String expected,
) {
  if (_requiredString(json, key) != expected) {
    throw FormatException('$key must be $expected.');
  }
}

bool _requiredBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('$key must be true or false.');
}

bool? _optionalBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is bool) return value;
  throw FormatException('$key must be true or false.');
}

int? _optionalInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  throw FormatException('$key must be a whole number.');
}

int _requiredNonNegativeInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int && value >= 0) return value;
  throw FormatException('$key must be a non-negative whole number.');
}

int? _optionalNonNegativeInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int && value >= 0) return value;
  throw FormatException('$key must be a non-negative whole number.');
}

int? _optionalPositiveInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int && value > 0) return value;
  throw FormatException('$key must be a positive whole number.');
}

DateTime _requiredDateTime(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('$key must be a timestamp.');
  return parsed;
}

DateTime? _optionalDateTime(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a timestamp.');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('$key must be a timestamp.');
  return parsed;
}

DateTime? _nullableDateTime(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) {
    throw FormatException('$key must be present.');
  }
  return _optionalDateTime(json, key);
}

Uri _requiredUri(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final parsed = Uri.tryParse(value);
  if (parsed == null ||
      !parsed.hasAuthority ||
      (parsed.scheme != 'https' && parsed.scheme != 'http')) {
    throw FormatException('$key must be a provider URL.');
  }
  return parsed;
}

Uri? _optionalUri(Map<String, Object?> json, String key) {
  if (json[key] == null) return null;
  return _requiredUri(json, key);
}

List<Uri> _requiredUriList(Map<String, Object?> json, String key) {
  return _requiredList(json, key)
      .map((value) {
        if (value is! String) throw FormatException('$key must contain URLs.');
        return _requiredUri(<String, Object?>{key: value}, key);
      })
      .toList(growable: false);
}

List<String> _requiredNonEmptyStringList(
  Map<String, Object?> json,
  String key, {
  bool allowEmpty = false,
}) {
  final values = _requiredList(json, key);
  if (!allowEmpty && values.isEmpty) {
    throw FormatException('$key must not be empty.');
  }
  final result = <String>[];
  for (final value in values) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key must contain text.');
    }
    result.add(value);
  }
  return List.unmodifiable(result);
}

List<String>? _optionalNonEmptyStringList(
  Map<String, Object?> json,
  String key,
) {
  if (json[key] == null) return null;
  return _requiredNonEmptyStringList(json, key);
}

List<String>? _optionalRegionList(Map<String, Object?> json, String key) {
  if (json[key] == null) return null;
  final values = _requiredNonEmptyStringList(json, key);
  final seen = <String>{};
  for (final value in values) {
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(value) || !seen.add(value)) {
      throw FormatException('$key must contain unique region codes.');
    }
  }
  return values;
}

String _requiredRegionCode(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(value)) {
    throw FormatException('$key must be a region code.');
  }
  return value;
}

String _requiredLanguageTag(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  if (!RegExp(r'^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$').hasMatch(value)) {
    throw FormatException('$key must be a language tag.');
  }
  return value;
}

String? _optionalLanguageTag(Map<String, Object?> json, String key) {
  if (json[key] == null) return null;
  return _requiredLanguageTag(json, key);
}

String _requiredCategoryId(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  if (!RegExp(r'^\d{1,3}$').hasMatch(value)) {
    throw FormatException('$key must be a video category.');
  }
  return value;
}

String? _optionalCategoryId(Map<String, Object?> json, String key) {
  if (json[key] == null) return null;
  return _requiredCategoryId(json, key);
}

String? _optionalCountString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String && RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(value)) {
    return value;
  }
  throw FormatException('$key must be a non-negative count.');
}

int _requiredCount(Map<String, Object?> json, String key) {
  final value = _optionalCountString(json, key);
  if (value == null) throw FormatException('$key must be a count.');
  final parsed = int.tryParse(value);
  if (parsed == null) throw FormatException('$key is too large.');
  return parsed;
}

YouTubeBroadcastState _broadcastState(String value) {
  return switch (value) {
    'none' => YouTubeBroadcastState.none,
    'live' => YouTubeBroadcastState.live,
    'upcoming' => YouTubeBroadcastState.upcoming,
    _ => throw const FormatException('broadcastState is invalid.'),
  };
}

YouTubeVideoDefinition? _optionalVideoDefinition(
  Map<String, Object?> json,
  String key,
) {
  final value = _optionalString(json, key);
  return switch (value) {
    null => null,
    'hd' => YouTubeVideoDefinition.hd,
    'sd' => YouTubeVideoDefinition.sd,
    _ => throw FormatException('$key is invalid.'),
  };
}

YouTubeVideoProjection? _optionalVideoProjection(
  Map<String, Object?> json,
  String key,
) {
  final value = _optionalString(json, key);
  return switch (value) {
    null => null,
    'rectangular' => YouTubeVideoProjection.rectangular,
    '360' => YouTubeVideoProjection.spherical360,
    _ => throw FormatException('$key is invalid.'),
  };
}

YouTubePublicVideoUnavailableReason _unavailableReason(String value) {
  return switch (value) {
    'not_public' => YouTubePublicVideoUnavailableReason.notPublic,
    'not_embeddable' => YouTubePublicVideoUnavailableReason.notEmbeddable,
    'processing' => YouTubePublicVideoUnavailableReason.processing,
    'removed_or_rejected' =>
      YouTubePublicVideoUnavailableReason.removedOrRejected,
    'region_restricted' => YouTubePublicVideoUnavailableReason.regionRestricted,
    'age_restricted' => YouTubePublicVideoUnavailableReason.ageRestricted,
    'children_directed' => YouTubePublicVideoUnavailableReason.childrenDirected,
    'metadata_invalid' => YouTubePublicVideoUnavailableReason.metadataInvalid,
    'unavailable' => YouTubePublicVideoUnavailableReason.unavailable,
    _ => throw const FormatException('Filtered video reason is invalid.'),
  };
}

YouTubeConnectionVerificationState _connectionVerificationState(String value) {
  return switch (value) {
    'current' => YouTubeConnectionVerificationState.current,
    'due' => YouTubeConnectionVerificationState.due,
    'reconnect_required' =>
      YouTubeConnectionVerificationState.reconnectRequired,
    _ => throw const FormatException('verificationState is invalid.'),
  };
}

extension _TransformValue<T> on T {
  R let<R>(R Function(T value) transform) => transform(this);
}
