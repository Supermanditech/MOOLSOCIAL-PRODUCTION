part of 'youtube_private_dev_models.dart';

enum YouTubeLiveBroadcastFilter { all, active, upcoming, completed }

enum YouTubeLiveBroadcastLifecycle {
  created,
  ready,
  testing,
  live,
  complete,
  revoked,
  testStarting,
  liveStarting,
}

enum YouTubeLivePrivacy { private, public, unlisted }

enum YouTubeLiveRecordingStatus { notRecording, recording, recorded }

enum YouTubeLiveBroadcastTransition { testing, live, complete }

enum YouTubeLiveLatencyPreference { normal, low, ultraLow }

enum YouTubeLiveStreamStatus { created, ready, active, inactive, error }

enum YouTubeLiveStreamResolution {
  p240,
  p360,
  p480,
  p720,
  p1080,
  p1440,
  p2160,
  variable,
}

enum YouTubeLiveStreamFrameRate { fps30, fps60, variable }

enum YouTubeLiveStreamIngestionType { rtmp, dash, webrtc, hls }

enum YouTubeLiveChatMessageType {
  textMessageEvent,
  tombstone,
  fanFundingEvent,
  chatEndedEvent,
  sponsorOnlyModeStartedEvent,
  sponsorOnlyModeEndedEvent,
  newSponsorEvent,
  memberMilestoneChatEvent,
  membershipGiftingEvent,
  giftMembershipReceivedEvent,
  messageDeletedEvent,
  messageRetractedEvent,
  userBannedEvent,
  superChatEvent,
  superStickerEvent,
  pollEvent,
  giftEvent,
}

enum YouTubeLivePollStatus { active, closed, unknown }

enum YouTubeLiveBanType { permanent, temporary }

enum YouTubeLiveMembershipMode { allCurrent, updates }

enum YouTubeLiveEligibility {
  providerApprovedChannelOnly,
  youtubeRepresentativeAndMembershipsEnabledRequired,
}

extension YouTubeLiveBroadcastFilterWireValue on YouTubeLiveBroadcastFilter {
  String get wireValue => name;
}

extension YouTubeLiveBroadcastTransitionWireValue
    on YouTubeLiveBroadcastTransition {
  String get wireValue => name;
}

extension YouTubeLiveLatencyPreferenceWireValue
    on YouTubeLiveLatencyPreference {
  String get wireValue => name;
}

extension YouTubeLiveStreamResolutionWireValue on YouTubeLiveStreamResolution {
  String get wireValue => switch (this) {
    YouTubeLiveStreamResolution.p240 => '240p',
    YouTubeLiveStreamResolution.p360 => '360p',
    YouTubeLiveStreamResolution.p480 => '480p',
    YouTubeLiveStreamResolution.p720 => '720p',
    YouTubeLiveStreamResolution.p1080 => '1080p',
    YouTubeLiveStreamResolution.p1440 => '1440p',
    YouTubeLiveStreamResolution.p2160 => '2160p',
    YouTubeLiveStreamResolution.variable => 'variable',
  };
}

extension YouTubeLiveStreamFrameRateWireValue on YouTubeLiveStreamFrameRate {
  String get wireValue => switch (this) {
    YouTubeLiveStreamFrameRate.fps30 => '30fps',
    YouTubeLiveStreamFrameRate.fps60 => '60fps',
    YouTubeLiveStreamFrameRate.variable => 'variable',
  };
}

extension YouTubeLiveStreamIngestionTypeWireValue
    on YouTubeLiveStreamIngestionType {
  String get wireValue => name;
}

extension YouTubeLiveBanTypeWireValue on YouTubeLiveBanType {
  String get wireValue => name;
}

extension YouTubeLiveMembershipModeWireValue on YouTubeLiveMembershipMode {
  String get wireValue => switch (this) {
    YouTubeLiveMembershipMode.allCurrent => 'all_current',
    YouTubeLiveMembershipMode.updates => 'updates',
  };
}

class YouTubeLiveBroadcastWrite {
  const YouTubeLiveBroadcastWrite({
    required this.title,
    required this.description,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    required this.selfDeclaredMadeForKids,
    required this.enableEmbed,
    required this.enableDvr,
    required this.enableAutoStart,
    required this.enableAutoStop,
    required this.latencyPreference,
  });

  final String title;
  final String description;
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final bool selfDeclaredMadeForKids;
  final bool enableEmbed;
  final bool enableDvr;
  final bool enableAutoStart;
  final bool enableAutoStop;
  final YouTubeLiveLatencyPreference latencyPreference;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'title': title,
      'description': description,
      'scheduledStartTime': _youtubeLiveUtcTimestamp(scheduledStartTime),
      'scheduledEndTime': _youtubeLiveUtcTimestamp(scheduledEndTime),
      'selfDeclaredMadeForKids': selfDeclaredMadeForKids,
      'enableEmbed': enableEmbed,
      'enableDvr': enableDvr,
      'enableAutoStart': enableAutoStart,
      'enableAutoStop': enableAutoStop,
      'latencyPreference': latencyPreference.wireValue,
    };
  }
}

class YouTubeLiveStreamWrite {
  const YouTubeLiveStreamWrite({
    required this.title,
    required this.description,
    required this.isReusable,
  });

  final String title;
  final String description;
  final bool isReusable;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'title': title,
      'description': description,
      'isReusable': isReusable,
    };
  }
}

class YouTubeLiveChatIdentity {
  const YouTubeLiveChatIdentity({
    required this.broadcastId,
    required this.liveChatId,
  });

  final String broadcastId;
  final String liveChatId;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'broadcastId': broadcastId,
      'liveChatId': liveChatId,
    };
  }
}

class YouTubeLiveBroadcast {
  const YouTubeLiveBroadcast({
    required this.broadcastId,
    required this.channelId,
    required this.title,
    required this.description,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    required this.lifeCycleStatus,
    required this.privacyStatus,
    required this.recordingStatus,
    this.actualStartTime,
    this.actualEndTime,
    this.liveChatId,
    this.madeForKids,
    this.selfDeclaredMadeForKids,
    this.boundStreamId,
    this.enableEmbed,
    this.enableDvr,
    this.recordFromStart,
    this.enableAutoStart,
    this.enableAutoStop,
    this.latencyPreference,
  });

  factory YouTubeLiveBroadcast.fromJson(Map<String, Object?> json) {
    return YouTubeLiveBroadcast(
      broadcastId: _requiredString(json, 'broadcastId'),
      channelId: _requiredString(json, 'channelId'),
      title: _requiredString(json, 'title'),
      description: _requiredText(json, 'description'),
      scheduledStartTime: _requiredDateTime(json, 'scheduledStartTime'),
      scheduledEndTime: _requiredDateTime(json, 'scheduledEndTime'),
      actualStartTime: _optionalDateTime(json, 'actualStartTime'),
      actualEndTime: _optionalDateTime(json, 'actualEndTime'),
      liveChatId: _optionalString(json, 'liveChatId'),
      lifeCycleStatus: _youtubeLiveBroadcastLifecycle(
        _requiredString(json, 'lifeCycleStatus'),
      ),
      privacyStatus: _youtubeLivePrivacy(
        _requiredString(json, 'privacyStatus'),
      ),
      recordingStatus: _youtubeLiveRecordingStatus(
        _requiredString(json, 'recordingStatus'),
      ),
      madeForKids: _optionalBool(json, 'madeForKids'),
      selfDeclaredMadeForKids: _optionalBool(json, 'selfDeclaredMadeForKids'),
      boundStreamId: _optionalString(json, 'boundStreamId'),
      enableEmbed: _optionalBool(json, 'enableEmbed'),
      enableDvr: _optionalBool(json, 'enableDvr'),
      recordFromStart: _optionalBool(json, 'recordFromStart'),
      enableAutoStart: _optionalBool(json, 'enableAutoStart'),
      enableAutoStop: _optionalBool(json, 'enableAutoStop'),
      latencyPreference: _youtubeLiveOptionalLatency(json, 'latencyPreference'),
    );
  }

  final String broadcastId;
  final String channelId;
  final String title;
  final String description;
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final String? liveChatId;
  final YouTubeLiveBroadcastLifecycle lifeCycleStatus;
  final YouTubeLivePrivacy privacyStatus;
  final YouTubeLiveRecordingStatus recordingStatus;
  final bool? madeForKids;
  final bool? selfDeclaredMadeForKids;
  final String? boundStreamId;
  final bool? enableEmbed;
  final bool? enableDvr;
  final bool? recordFromStart;
  final bool? enableAutoStart;
  final bool? enableAutoStop;
  final YouTubeLiveLatencyPreference? latencyPreference;
}

class YouTubeLiveBroadcastPage {
  const YouTubeLiveBroadcastPage({required this.items, this.nextPageToken});

  factory YouTubeLiveBroadcastPage.fromJson(Map<String, Object?> json) {
    return YouTubeLiveBroadcastPage(
      items: List<YouTubeLiveBroadcast>.unmodifiable(
        _requiredList(
          json,
          'items',
        ).map((value) => YouTubeLiveBroadcast.fromJson(_asMap(value))),
      ),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final List<YouTubeLiveBroadcast> items;
  final String? nextPageToken;
}

class YouTubeLiveStream {
  const YouTubeLiveStream({
    required this.streamId,
    required this.channelId,
    required this.title,
    required this.description,
    required this.streamStatus,
    required this.resolution,
    required this.frameRate,
    required this.ingestionType,
    required this.isReusable,
    this.ingestionAddress,
    this.backupIngestionAddress,
    this.rtmpsIngestionAddress,
    this.rtmpsBackupIngestionAddress,
    this.streamName,
  });

  factory YouTubeLiveStream.fromJson(Map<String, Object?> json) {
    return YouTubeLiveStream(
      streamId: _requiredString(json, 'streamId'),
      channelId: _requiredString(json, 'channelId'),
      title: _requiredString(json, 'title'),
      description: _requiredText(json, 'description'),
      streamStatus: _youtubeLiveStreamStatus(
        _requiredString(json, 'streamStatus'),
      ),
      resolution: _youtubeLiveStreamResolution(
        _requiredString(json, 'resolution'),
      ),
      frameRate: _youtubeLiveStreamFrameRate(
        _requiredString(json, 'frameRate'),
      ),
      ingestionType: _youtubeLiveStreamIngestionType(
        _requiredString(json, 'ingestionType'),
      ),
      isReusable: _requiredBool(json, 'isReusable'),
      ingestionAddress: _youtubeLiveOptionalIngestionUri(
        json,
        'ingestionAddress',
      ),
      backupIngestionAddress: _youtubeLiveOptionalIngestionUri(
        json,
        'backupIngestionAddress',
      ),
      rtmpsIngestionAddress: _youtubeLiveOptionalIngestionUri(
        json,
        'rtmpsIngestionAddress',
      ),
      rtmpsBackupIngestionAddress: _youtubeLiveOptionalIngestionUri(
        json,
        'rtmpsBackupIngestionAddress',
      ),
      streamName: _optionalString(json, 'streamName'),
    );
  }

  final String streamId;
  final String channelId;
  final String title;
  final String description;
  final YouTubeLiveStreamStatus streamStatus;
  final YouTubeLiveStreamResolution resolution;
  final YouTubeLiveStreamFrameRate frameRate;
  final YouTubeLiveStreamIngestionType ingestionType;
  final bool isReusable;
  final Uri? ingestionAddress;
  final Uri? backupIngestionAddress;
  final Uri? rtmpsIngestionAddress;
  final Uri? rtmpsBackupIngestionAddress;

  /// Provider stream key. It must never be logged or included in evidence.
  final String? streamName;
}

class YouTubeLiveStreamPage {
  const YouTubeLiveStreamPage({required this.items, this.nextPageToken});

  factory YouTubeLiveStreamPage.fromJson(Map<String, Object?> json) {
    return YouTubeLiveStreamPage(
      items: List<YouTubeLiveStream>.unmodifiable(
        _requiredList(
          json,
          'items',
        ).map((value) => YouTubeLiveStream.fromJson(_asMap(value))),
      ),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final List<YouTubeLiveStream> items;
  final String? nextPageToken;
}

class YouTubeLiveChatAuthor {
  const YouTubeLiveChatAuthor({
    required this.channelId,
    required this.displayName,
    required this.isVerified,
    required this.isChatOwner,
    required this.isChatSponsor,
    required this.isChatModerator,
    this.profileImageUrl,
  });

  factory YouTubeLiveChatAuthor.fromJson(Map<String, Object?> json) {
    return YouTubeLiveChatAuthor(
      channelId: _requiredString(json, 'channelId'),
      displayName: _requiredString(json, 'displayName'),
      profileImageUrl: _optionalUri(json, 'profileImageUrl'),
      isVerified: _requiredBool(json, 'isVerified'),
      isChatOwner: _requiredBool(json, 'isChatOwner'),
      isChatSponsor: _requiredBool(json, 'isChatSponsor'),
      isChatModerator: _requiredBool(json, 'isChatModerator'),
    );
  }

  final String channelId;
  final String displayName;
  final Uri? profileImageUrl;
  final bool isVerified;
  final bool isChatOwner;
  final bool isChatSponsor;
  final bool isChatModerator;
}

class YouTubeLivePollOption {
  const YouTubeLivePollOption({required this.optionText, this.tally});

  factory YouTubeLivePollOption.fromJson(Map<String, Object?> json) {
    return YouTubeLivePollOption(
      optionText: _requiredString(json, 'optionText'),
      tally: _optionalCountString(json, 'tally'),
    );
  }

  final String optionText;
  final String? tally;
}

class YouTubeLivePoll {
  const YouTubeLivePoll({
    required this.questionText,
    required this.status,
    required this.options,
  });

  factory YouTubeLivePoll.fromJson(Map<String, Object?> json) {
    final options = _requiredList(json, 'options')
        .map((value) => YouTubeLivePollOption.fromJson(_asMap(value)))
        .toList(growable: false);
    if (options.length < 2 || options.length > 4) {
      throw const FormatException(
        'A live poll must contain between two and four options.',
      );
    }
    return YouTubeLivePoll(
      questionText: _requiredString(json, 'questionText'),
      status: _youtubeLivePollStatus(_requiredString(json, 'status')),
      options: List.unmodifiable(options),
    );
  }

  final String questionText;
  final YouTubeLivePollStatus status;
  final List<YouTubeLivePollOption> options;
}

class YouTubeLiveChatMessage {
  const YouTubeLiveChatMessage({
    required this.messageId,
    required this.liveChatId,
    required this.type,
    required this.publishedAt,
    this.displayMessage,
    this.textMessage,
    this.author,
    this.poll,
  });

  factory YouTubeLiveChatMessage.fromJson(Map<String, Object?> json) {
    final author = _optionalMap(json, 'author');
    final poll = _optionalMap(json, 'poll');
    return YouTubeLiveChatMessage(
      messageId: _requiredString(json, 'messageId'),
      liveChatId: _requiredString(json, 'liveChatId'),
      type: _youtubeLiveChatMessageType(_requiredString(json, 'type')),
      publishedAt: _requiredDateTime(json, 'publishedAt'),
      displayMessage: _optionalString(json, 'displayMessage'),
      textMessage: _optionalString(json, 'textMessage'),
      author: author == null ? null : YouTubeLiveChatAuthor.fromJson(author),
      poll: poll == null ? null : YouTubeLivePoll.fromJson(poll),
    );
  }

  final String messageId;
  final String liveChatId;
  final YouTubeLiveChatMessageType type;
  final DateTime publishedAt;
  final String? displayMessage;
  final String? textMessage;
  final YouTubeLiveChatAuthor? author;
  final YouTubeLivePoll? poll;
}

class YouTubeLiveChatMessagesPage {
  const YouTubeLiveChatMessagesPage({
    required this.items,
    required this.pollingInterval,
    this.nextPageToken,
    this.offlineAt,
    this.activePoll,
  });

  factory YouTubeLiveChatMessagesPage.fromJson(Map<String, Object?> json) {
    final milliseconds = _requiredNonNegativeInt(json, 'pollingIntervalMillis');
    if (milliseconds < 250 || milliseconds > 120000) {
      throw const FormatException(
        'pollingIntervalMillis is outside the supported range.',
      );
    }
    final activePoll = _optionalMap(json, 'activePoll');
    return YouTubeLiveChatMessagesPage(
      items: List<YouTubeLiveChatMessage>.unmodifiable(
        _requiredList(
          json,
          'items',
        ).map((value) => YouTubeLiveChatMessage.fromJson(_asMap(value))),
      ),
      pollingInterval: Duration(milliseconds: milliseconds),
      nextPageToken: _optionalString(json, 'nextPageToken'),
      offlineAt: _optionalDateTime(json, 'offlineAt'),
      activePoll: activePoll == null
          ? null
          : YouTubeLiveChatMessage.fromJson(activePoll),
    );
  }

  final List<YouTubeLiveChatMessage> items;
  final Duration pollingInterval;
  final String? nextPageToken;
  final DateTime? offlineAt;
  final YouTubeLiveChatMessage? activePoll;
}

class YouTubeLiveModerator {
  const YouTubeLiveModerator({
    required this.moderatorId,
    required this.liveChatId,
    required this.channelId,
    required this.displayName,
    this.profileImageUrl,
  });

  factory YouTubeLiveModerator.fromJson(Map<String, Object?> json) {
    return YouTubeLiveModerator(
      moderatorId: _requiredString(json, 'moderatorId'),
      liveChatId: _requiredString(json, 'liveChatId'),
      channelId: _requiredString(json, 'channelId'),
      displayName: _requiredString(json, 'displayName'),
      profileImageUrl: _optionalUri(json, 'profileImageUrl'),
    );
  }

  final String moderatorId;
  final String liveChatId;
  final String channelId;
  final String displayName;
  final Uri? profileImageUrl;
}

class YouTubeLiveModeratorsPage {
  const YouTubeLiveModeratorsPage({required this.items, this.nextPageToken});

  factory YouTubeLiveModeratorsPage.fromJson(Map<String, Object?> json) {
    return YouTubeLiveModeratorsPage(
      items: List<YouTubeLiveModerator>.unmodifiable(
        _requiredList(
          json,
          'items',
        ).map((value) => YouTubeLiveModerator.fromJson(_asMap(value))),
      ),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final List<YouTubeLiveModerator> items;
  final String? nextPageToken;
}

class YouTubeLiveBan {
  const YouTubeLiveBan({
    required this.banId,
    required this.liveChatId,
    required this.bannedChannelId,
    required this.type,
    this.durationSeconds,
  });

  factory YouTubeLiveBan.fromJson(Map<String, Object?> json) {
    final type = _youtubeLiveBanType(_requiredString(json, 'type'));
    final durationSeconds = _optionalPositiveInt(json, 'durationSeconds');
    if ((type == YouTubeLiveBanType.temporary && durationSeconds == null) ||
        (type == YouTubeLiveBanType.permanent && durationSeconds != null)) {
      throw const FormatException('The live ban duration is inconsistent.');
    }
    return YouTubeLiveBan(
      banId: _requiredString(json, 'banId'),
      liveChatId: _requiredString(json, 'liveChatId'),
      bannedChannelId: _requiredString(json, 'bannedChannelId'),
      type: type,
      durationSeconds: durationSeconds,
    );
  }

  final String banId;
  final String liveChatId;
  final String bannedChannelId;
  final YouTubeLiveBanType type;
  final int? durationSeconds;
}

class YouTubeLiveSuperChatEvent {
  const YouTubeLiveSuperChatEvent({
    required this.eventId,
    required this.supporterChannelId,
    required this.supporterDisplayName,
    required this.createdAt,
    required this.amountMicros,
    required this.currency,
    required this.displayString,
    required this.commentText,
    required this.isSuperStickerEvent,
    this.supporterProfileImageUrl,
  });

  factory YouTubeLiveSuperChatEvent.fromJson(Map<String, Object?> json) {
    return YouTubeLiveSuperChatEvent(
      eventId: _requiredString(json, 'eventId'),
      supporterChannelId: _requiredString(json, 'supporterChannelId'),
      supporterDisplayName: _requiredString(json, 'supporterDisplayName'),
      supporterProfileImageUrl: _optionalUri(json, 'supporterProfileImageUrl'),
      createdAt: _requiredDateTime(json, 'createdAt'),
      amountMicros: _youtubeLiveRequiredCountString(json, 'amountMicros'),
      currency: _youtubeLiveCurrency(json, 'currency'),
      displayString: _requiredString(json, 'displayString'),
      commentText: _requiredText(json, 'commentText'),
      isSuperStickerEvent: _requiredBool(json, 'isSuperStickerEvent'),
    );
  }

  final String eventId;
  final String supporterChannelId;
  final String supporterDisplayName;
  final Uri? supporterProfileImageUrl;
  final DateTime createdAt;
  final String amountMicros;
  final String currency;
  final String displayString;
  final String commentText;
  final bool isSuperStickerEvent;
}

class YouTubeLiveSuperChatEventsPage {
  const YouTubeLiveSuperChatEventsPage({
    required this.eligibility,
    required this.items,
    this.nextPageToken,
  });

  factory YouTubeLiveSuperChatEventsPage.fromJson(Map<String, Object?> json) {
    return YouTubeLiveSuperChatEventsPage(
      eligibility: _youtubeLiveExpectedEligibility(
        _requiredString(json, 'eligibility'),
        YouTubeLiveEligibility.providerApprovedChannelOnly,
      ),
      items: List<YouTubeLiveSuperChatEvent>.unmodifiable(
        _requiredList(
          json,
          'items',
        ).map((value) => YouTubeLiveSuperChatEvent.fromJson(_asMap(value))),
      ),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final YouTubeLiveEligibility eligibility;
  final List<YouTubeLiveSuperChatEvent> items;
  final String? nextPageToken;
}

class YouTubeLiveMember {
  const YouTubeLiveMember({
    required this.creatorChannelId,
    required this.highestAccessibleLevelId,
    required this.highestAccessibleLevelDisplayName,
    required this.accessibleLevelIds,
    this.memberChannelId,
    this.memberDisplayName,
    this.memberProfileImageUrl,
  });

  factory YouTubeLiveMember.fromJson(Map<String, Object?> json) {
    return YouTubeLiveMember(
      creatorChannelId: _requiredString(json, 'creatorChannelId'),
      memberChannelId: _optionalString(json, 'memberChannelId'),
      memberDisplayName: _optionalString(json, 'memberDisplayName'),
      memberProfileImageUrl: _optionalUri(json, 'memberProfileImageUrl'),
      highestAccessibleLevelId: _requiredString(
        json,
        'highestAccessibleLevelId',
      ),
      highestAccessibleLevelDisplayName: _requiredString(
        json,
        'highestAccessibleLevelDisplayName',
      ),
      accessibleLevelIds: List<String>.unmodifiable(
        _requiredNonEmptyStringList(
          json,
          'accessibleLevelIds',
          allowEmpty: true,
        ),
      ),
    );
  }

  final String creatorChannelId;
  final String? memberChannelId;
  final String? memberDisplayName;
  final Uri? memberProfileImageUrl;
  final String highestAccessibleLevelId;
  final String highestAccessibleLevelDisplayName;
  final List<String> accessibleLevelIds;
}

class YouTubeLiveMembersPage {
  const YouTubeLiveMembersPage({
    required this.eligibility,
    required this.items,
    this.nextPageToken,
  });

  factory YouTubeLiveMembersPage.fromJson(Map<String, Object?> json) {
    return YouTubeLiveMembersPage(
      eligibility: _youtubeLiveExpectedEligibility(
        _requiredString(json, 'eligibility'),
        YouTubeLiveEligibility
            .youtubeRepresentativeAndMembershipsEnabledRequired,
      ),
      items: List<YouTubeLiveMember>.unmodifiable(
        _requiredList(
          json,
          'items',
        ).map((value) => YouTubeLiveMember.fromJson(_asMap(value))),
      ),
      nextPageToken: _optionalString(json, 'nextPageToken'),
    );
  }

  final YouTubeLiveEligibility eligibility;
  final List<YouTubeLiveMember> items;
  final String? nextPageToken;
}

class YouTubeLiveMembershipLevel {
  const YouTubeLiveMembershipLevel({
    required this.levelId,
    required this.creatorChannelId,
    required this.displayName,
  });

  factory YouTubeLiveMembershipLevel.fromJson(Map<String, Object?> json) {
    return YouTubeLiveMembershipLevel(
      levelId: _requiredString(json, 'levelId'),
      creatorChannelId: _requiredString(json, 'creatorChannelId'),
      displayName: _requiredString(json, 'displayName'),
    );
  }

  final String levelId;
  final String creatorChannelId;
  final String displayName;
}

class YouTubeLiveMembershipLevels {
  const YouTubeLiveMembershipLevels({
    required this.eligibility,
    required this.items,
  });

  factory YouTubeLiveMembershipLevels.fromJson(Map<String, Object?> json) {
    return YouTubeLiveMembershipLevels(
      eligibility: _youtubeLiveExpectedEligibility(
        _requiredString(json, 'eligibility'),
        YouTubeLiveEligibility
            .youtubeRepresentativeAndMembershipsEnabledRequired,
      ),
      items: List<YouTubeLiveMembershipLevel>.unmodifiable(
        _requiredList(
          json,
          'items',
        ).map((value) => YouTubeLiveMembershipLevel.fromJson(_asMap(value))),
      ),
    );
  }

  final YouTubeLiveEligibility eligibility;
  final List<YouTubeLiveMembershipLevel> items;
}

class YouTubeLiveBroadcastDeleteResult {
  const YouTubeLiveBroadcastDeleteResult({required this.broadcastId});

  factory YouTubeLiveBroadcastDeleteResult.fromJson(Map<String, Object?> json) {
    return YouTubeLiveBroadcastDeleteResult(
      broadcastId: _requiredString(json, 'deletedBroadcastId'),
    );
  }

  final String broadcastId;
}

class YouTubeLiveStreamDeleteResult {
  const YouTubeLiveStreamDeleteResult({required this.streamId});

  factory YouTubeLiveStreamDeleteResult.fromJson(Map<String, Object?> json) {
    return YouTubeLiveStreamDeleteResult(
      streamId: _requiredString(json, 'deletedStreamId'),
    );
  }

  final String streamId;
}

class YouTubeLiveChatMessageDeleteResult {
  const YouTubeLiveChatMessageDeleteResult({required this.messageId});

  factory YouTubeLiveChatMessageDeleteResult.fromJson(
    Map<String, Object?> json,
  ) {
    return YouTubeLiveChatMessageDeleteResult(
      messageId: _requiredString(json, 'deletedMessageId'),
    );
  }

  final String messageId;
}

class YouTubeLiveModeratorDeleteResult {
  const YouTubeLiveModeratorDeleteResult({required this.moderatorId});

  factory YouTubeLiveModeratorDeleteResult.fromJson(Map<String, Object?> json) {
    return YouTubeLiveModeratorDeleteResult(
      moderatorId: _requiredString(json, 'deletedModeratorId'),
    );
  }

  final String moderatorId;
}

class YouTubeLiveBanDeleteResult {
  const YouTubeLiveBanDeleteResult({required this.banId});

  factory YouTubeLiveBanDeleteResult.fromJson(Map<String, Object?> json) {
    return YouTubeLiveBanDeleteResult(
      banId: _requiredString(json, 'deletedBanId'),
    );
  }

  final String banId;
}

YouTubeLiveBroadcastLifecycle _youtubeLiveBroadcastLifecycle(String value) {
  return switch (value) {
    'created' => YouTubeLiveBroadcastLifecycle.created,
    'ready' => YouTubeLiveBroadcastLifecycle.ready,
    'testing' => YouTubeLiveBroadcastLifecycle.testing,
    'live' => YouTubeLiveBroadcastLifecycle.live,
    'complete' => YouTubeLiveBroadcastLifecycle.complete,
    'revoked' => YouTubeLiveBroadcastLifecycle.revoked,
    'testStarting' => YouTubeLiveBroadcastLifecycle.testStarting,
    'liveStarting' => YouTubeLiveBroadcastLifecycle.liveStarting,
    _ => throw const FormatException('lifeCycleStatus is invalid.'),
  };
}

YouTubeLivePrivacy _youtubeLivePrivacy(String value) {
  return switch (value) {
    'private' => YouTubeLivePrivacy.private,
    'public' => YouTubeLivePrivacy.public,
    'unlisted' => YouTubeLivePrivacy.unlisted,
    _ => throw const FormatException('privacyStatus is invalid.'),
  };
}

YouTubeLiveRecordingStatus _youtubeLiveRecordingStatus(String value) {
  return switch (value) {
    'notRecording' => YouTubeLiveRecordingStatus.notRecording,
    'recording' => YouTubeLiveRecordingStatus.recording,
    'recorded' => YouTubeLiveRecordingStatus.recorded,
    _ => throw const FormatException('recordingStatus is invalid.'),
  };
}

YouTubeLiveLatencyPreference? _youtubeLiveOptionalLatency(
  Map<String, Object?> json,
  String key,
) {
  final value = _optionalString(json, key);
  return switch (value) {
    null => null,
    'normal' => YouTubeLiveLatencyPreference.normal,
    'low' => YouTubeLiveLatencyPreference.low,
    'ultraLow' => YouTubeLiveLatencyPreference.ultraLow,
    _ => throw FormatException('$key is invalid.'),
  };
}

YouTubeLiveStreamStatus _youtubeLiveStreamStatus(String value) {
  return switch (value) {
    'created' => YouTubeLiveStreamStatus.created,
    'ready' => YouTubeLiveStreamStatus.ready,
    'active' => YouTubeLiveStreamStatus.active,
    'inactive' => YouTubeLiveStreamStatus.inactive,
    'error' => YouTubeLiveStreamStatus.error,
    _ => throw const FormatException('streamStatus is invalid.'),
  };
}

YouTubeLiveStreamResolution _youtubeLiveStreamResolution(String value) {
  return switch (value) {
    '240p' => YouTubeLiveStreamResolution.p240,
    '360p' => YouTubeLiveStreamResolution.p360,
    '480p' => YouTubeLiveStreamResolution.p480,
    '720p' => YouTubeLiveStreamResolution.p720,
    '1080p' => YouTubeLiveStreamResolution.p1080,
    '1440p' => YouTubeLiveStreamResolution.p1440,
    '2160p' => YouTubeLiveStreamResolution.p2160,
    'variable' => YouTubeLiveStreamResolution.variable,
    _ => throw const FormatException('resolution is invalid.'),
  };
}

YouTubeLiveStreamFrameRate _youtubeLiveStreamFrameRate(String value) {
  return switch (value) {
    '30fps' => YouTubeLiveStreamFrameRate.fps30,
    '60fps' => YouTubeLiveStreamFrameRate.fps60,
    'variable' => YouTubeLiveStreamFrameRate.variable,
    _ => throw const FormatException('frameRate is invalid.'),
  };
}

YouTubeLiveStreamIngestionType _youtubeLiveStreamIngestionType(String value) {
  return switch (value) {
    'rtmp' => YouTubeLiveStreamIngestionType.rtmp,
    'dash' => YouTubeLiveStreamIngestionType.dash,
    'webrtc' => YouTubeLiveStreamIngestionType.webrtc,
    'hls' => YouTubeLiveStreamIngestionType.hls,
    _ => throw const FormatException('ingestionType is invalid.'),
  };
}

YouTubeLiveChatMessageType _youtubeLiveChatMessageType(String value) {
  for (final type in YouTubeLiveChatMessageType.values) {
    if (type.name == value) return type;
  }
  throw const FormatException('type is not a supported live chat event.');
}

YouTubeLivePollStatus _youtubeLivePollStatus(String value) {
  return switch (value) {
    'active' => YouTubeLivePollStatus.active,
    'closed' => YouTubeLivePollStatus.closed,
    'unknown' => YouTubeLivePollStatus.unknown,
    _ => throw const FormatException('status is invalid.'),
  };
}

YouTubeLiveBanType _youtubeLiveBanType(String value) {
  return switch (value) {
    'permanent' => YouTubeLiveBanType.permanent,
    'temporary' => YouTubeLiveBanType.temporary,
    _ => throw const FormatException('type is invalid.'),
  };
}

YouTubeLiveEligibility _youtubeLiveEligibility(String value) {
  return switch (value) {
    'provider_approved_channel_only' =>
      YouTubeLiveEligibility.providerApprovedChannelOnly,
    'youtube_representative_and_memberships_enabled_required' =>
      YouTubeLiveEligibility.youtubeRepresentativeAndMembershipsEnabledRequired,
    _ => throw const FormatException('eligibility is invalid.'),
  };
}

YouTubeLiveEligibility _youtubeLiveExpectedEligibility(
  String value,
  YouTubeLiveEligibility expected,
) {
  final eligibility = _youtubeLiveEligibility(value);
  if (eligibility != expected) {
    throw const FormatException(
      'The provider eligibility classification is inconsistent.',
    );
  }
  return eligibility;
}

Uri? _youtubeLiveOptionalIngestionUri(Map<String, Object?> json, String key) {
  final value = _optionalString(json, key);
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  final host = uri?.host.toLowerCase() ?? '';
  final trustedHost =
      host == 'youtube.com' ||
      host.endsWith('.youtube.com') ||
      host == 'google.com' ||
      host.endsWith('.google.com') ||
      host == 'googleapis.com' ||
      host.endsWith('.googleapis.com');
  if (uri == null ||
      !const <String>{'rtmp', 'rtmps', 'https'}.contains(uri.scheme) ||
      host.isEmpty ||
      !trustedHost ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    throw FormatException('$key must be a trusted provider ingestion URL.');
  }
  return uri;
}

String _youtubeLiveCurrency(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  if (!RegExp(r'^[A-Z]{3}$').hasMatch(value)) {
    throw FormatException('$key must be an ISO currency code.');
  }
  return value;
}

String _youtubeLiveRequiredCountString(Map<String, Object?> json, String key) {
  final value = _optionalCountString(json, key);
  if (value == null) throw FormatException('$key must be a count.');
  return value;
}

String _youtubeLiveUtcTimestamp(DateTime value) {
  final utc = value.toUtc();
  String two(int part) => part.toString().padLeft(2, '0');
  String three(int part) => part.toString().padLeft(3, '0');
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${two(utc.month)}-${two(utc.day)}T'
      '${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}.'
      '${three(utc.millisecond)}Z';
}
