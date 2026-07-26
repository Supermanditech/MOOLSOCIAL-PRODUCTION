part of 'youtube_private_dev_client.dart';

extension YouTubePrivateDevLiveClient on YouTubePrivateDevClient {
  Future<YouTubeLiveBroadcastPage> liveListBroadcasts({
    required YouTubeLiveBroadcastFilter status,
    String? pageToken,
    int? maxResults,
  }) async {
    final data = await _liveOwnerOperation(
      'liveListBroadcasts',
      body: <String, Object?>{
        'status': status.wireValue,
        'pageToken': ?pageToken,
        'maxResults': ?maxResults,
      },
    );
    return YouTubeLiveBroadcastPage.fromJson(_asMap(data));
  }

  Future<YouTubeLiveBroadcast> liveInsertBroadcast({
    required YouTubeLiveBroadcastWrite broadcast,
  }) async {
    final data = await _liveOwnerOperation(
      'liveInsertBroadcast',
      body: broadcast.toJson(),
    );
    return YouTubeLiveBroadcast.fromJson(_asMap(data));
  }

  Future<YouTubeLiveBroadcast> liveUpdateBroadcast({
    required String broadcastId,
    required YouTubeLiveBroadcastWrite broadcast,
  }) async {
    final data = await _liveOwnerOperation(
      'liveUpdateBroadcast',
      body: <String, Object?>{
        'broadcastId': broadcastId,
        ...broadcast.toJson(),
      },
    );
    return YouTubeLiveBroadcast.fromJson(_asMap(data));
  }

  Future<YouTubeLiveBroadcast> liveBindBroadcast({
    required String broadcastId,
    required String streamId,
    required String confirmBroadcastId,
    required String confirmStreamId,
  }) async {
    _requireLiveConfirmation(
      broadcastId,
      confirmBroadcastId,
      'confirmBroadcastId',
    );
    _requireLiveConfirmation(streamId, confirmStreamId, 'confirmStreamId');
    final data = await _liveOwnerOperation(
      'liveBindBroadcast',
      body: <String, Object?>{
        'broadcastId': broadcastId,
        'streamId': streamId,
        'confirmBroadcastId': confirmBroadcastId,
        'confirmStreamId': confirmStreamId,
      },
    );
    return YouTubeLiveBroadcast.fromJson(_asMap(data));
  }

  Future<YouTubeLiveBroadcast> liveTransitionBroadcast({
    required String broadcastId,
    required YouTubeLiveBroadcastTransition targetStatus,
    required String confirmBroadcastId,
    required YouTubeLiveBroadcastTransition confirmTargetStatus,
  }) async {
    _requireLiveConfirmation(
      broadcastId,
      confirmBroadcastId,
      'confirmBroadcastId',
    );
    if (targetStatus != confirmTargetStatus) {
      throw ArgumentError.value(
        confirmTargetStatus,
        'confirmTargetStatus',
        'must match targetStatus',
      );
    }
    final data = await _liveOwnerOperation(
      'liveTransitionBroadcast',
      body: <String, Object?>{
        'broadcastId': broadcastId,
        'targetStatus': targetStatus.wireValue,
        'confirmBroadcastId': confirmBroadcastId,
        'confirmTargetStatus': confirmTargetStatus.wireValue,
      },
    );
    return YouTubeLiveBroadcast.fromJson(_asMap(data));
  }

  Future<YouTubeLiveBroadcastDeleteResult> liveDeleteBroadcast({
    required String broadcastId,
    required String confirmBroadcastId,
  }) async {
    _requireLiveConfirmation(
      broadcastId,
      confirmBroadcastId,
      'confirmBroadcastId',
    );
    final data = await _liveOwnerOperation(
      'liveDeleteBroadcast',
      body: <String, Object?>{
        'broadcastId': broadcastId,
        'confirmBroadcastId': confirmBroadcastId,
      },
    );
    return YouTubeLiveBroadcastDeleteResult.fromJson(_asMap(data));
  }

  Future<YouTubeLiveStreamPage> liveListStreams({
    String? pageToken,
    int? maxResults,
  }) async {
    final data = await _liveOwnerOperation(
      'liveListStreams',
      body: <String, Object?>{
        'pageToken': ?pageToken,
        'maxResults': ?maxResults,
      },
    );
    return YouTubeLiveStreamPage.fromJson(_asMap(data));
  }

  Future<YouTubeLiveStream> liveInsertStream({
    required YouTubeLiveStreamWrite stream,
    required YouTubeLiveStreamResolution resolution,
    required YouTubeLiveStreamFrameRate frameRate,
    required YouTubeLiveStreamIngestionType ingestionType,
  }) async {
    final data = await _liveOwnerOperation(
      'liveInsertStream',
      body: <String, Object?>{
        ...stream.toJson(),
        'resolution': resolution.wireValue,
        'frameRate': frameRate.wireValue,
        'ingestionType': ingestionType.wireValue,
      },
    );
    return YouTubeLiveStream.fromJson(_asMap(data));
  }

  Future<YouTubeLiveStream> liveUpdateStream({
    required String streamId,
    required YouTubeLiveStreamWrite stream,
  }) async {
    final data = await _liveOwnerOperation(
      'liveUpdateStream',
      body: <String, Object?>{'streamId': streamId, ...stream.toJson()},
    );
    return YouTubeLiveStream.fromJson(_asMap(data));
  }

  Future<YouTubeLiveStreamDeleteResult> liveDeleteStream({
    required String streamId,
    required String confirmStreamId,
  }) async {
    _requireLiveConfirmation(streamId, confirmStreamId, 'confirmStreamId');
    final data = await _liveOwnerOperation(
      'liveDeleteStream',
      body: <String, Object?>{
        'streamId': streamId,
        'confirmStreamId': confirmStreamId,
      },
    );
    return YouTubeLiveStreamDeleteResult.fromJson(_asMap(data));
  }

  Future<YouTubeLiveChatMessagesPage> liveListChatMessages({
    required YouTubeLiveChatIdentity chat,
    String? pageToken,
  }) async {
    final data = await _liveOwnerOperation(
      'liveListChatMessages',
      body: <String, Object?>{
        ...chat.toJson(),
        'pageToken': ?pageToken,
        'maxResults': 200,
      },
    );
    return YouTubeLiveChatMessagesPage.fromJson(_asMap(data));
  }

  Future<YouTubeLiveChatMessage> liveInsertChatText({
    required YouTubeLiveChatIdentity chat,
    required String messageText,
  }) async {
    final data = await _liveOwnerOperation(
      'liveInsertChatText',
      body: <String, Object?>{...chat.toJson(), 'messageText': messageText},
    );
    return YouTubeLiveChatMessage.fromJson(_asMap(data));
  }

  Future<YouTubeLiveChatMessage> liveInsertChatPoll({
    required YouTubeLiveChatIdentity chat,
    required String questionText,
    required List<String> options,
  }) async {
    final data = await _liveOwnerOperation(
      'liveInsertChatPoll',
      body: <String, Object?>{
        ...chat.toJson(),
        'questionText': questionText,
        'options': List<String>.unmodifiable(options),
      },
    );
    return YouTubeLiveChatMessage.fromJson(_asMap(data));
  }

  Future<YouTubeLiveChatMessage> liveCloseChatPoll({
    required YouTubeLiveChatIdentity chat,
    required String pollMessageId,
    required String confirmPollMessageId,
    required YouTubeLivePollStatus confirmStatus,
  }) async {
    _requireLiveConfirmation(
      pollMessageId,
      confirmPollMessageId,
      'confirmPollMessageId',
    );
    if (confirmStatus != YouTubeLivePollStatus.closed) {
      throw ArgumentError.value(
        confirmStatus,
        'confirmStatus',
        'must explicitly confirm the closed state',
      );
    }
    final data = await _liveOwnerOperation(
      'liveCloseChatPoll',
      body: <String, Object?>{
        ...chat.toJson(),
        'pollMessageId': pollMessageId,
        'confirmPollMessageId': confirmPollMessageId,
        'confirmStatus': confirmStatus.name,
      },
    );
    return YouTubeLiveChatMessage.fromJson(_asMap(data));
  }

  Future<YouTubeLiveChatMessageDeleteResult> liveDeleteChatMessage({
    required YouTubeLiveChatIdentity chat,
    required String messageId,
    required String confirmMessageId,
  }) async {
    _requireLiveConfirmation(messageId, confirmMessageId, 'confirmMessageId');
    final data = await _liveOwnerOperation(
      'liveDeleteChatMessage',
      body: <String, Object?>{
        ...chat.toJson(),
        'messageId': messageId,
        'confirmMessageId': confirmMessageId,
      },
    );
    return YouTubeLiveChatMessageDeleteResult.fromJson(_asMap(data));
  }

  Future<YouTubeLiveModeratorsPage> liveListModerators({
    required YouTubeLiveChatIdentity chat,
    String? pageToken,
    int? maxResults,
  }) async {
    final data = await _liveOwnerOperation(
      'liveListModerators',
      body: <String, Object?>{
        ...chat.toJson(),
        'pageToken': ?pageToken,
        'maxResults': ?maxResults,
      },
    );
    return YouTubeLiveModeratorsPage.fromJson(_asMap(data));
  }

  Future<YouTubeLiveModerator> liveInsertModerator({
    required YouTubeLiveChatIdentity chat,
    required String moderatorChannelId,
  }) async {
    final data = await _liveOwnerOperation(
      'liveInsertModerator',
      body: <String, Object?>{
        ...chat.toJson(),
        'moderatorChannelId': moderatorChannelId,
      },
    );
    return YouTubeLiveModerator.fromJson(_asMap(data));
  }

  Future<YouTubeLiveModeratorDeleteResult> liveDeleteModerator({
    required YouTubeLiveChatIdentity chat,
    required String moderatorId,
    required String confirmModeratorId,
  }) async {
    _requireLiveConfirmation(
      moderatorId,
      confirmModeratorId,
      'confirmModeratorId',
    );
    final data = await _liveOwnerOperation(
      'liveDeleteModerator',
      body: <String, Object?>{
        ...chat.toJson(),
        'moderatorId': moderatorId,
        'confirmModeratorId': confirmModeratorId,
      },
    );
    return YouTubeLiveModeratorDeleteResult.fromJson(_asMap(data));
  }

  Future<YouTubeLiveBan> liveInsertBan({
    required YouTubeLiveChatIdentity chat,
    required String bannedChannelId,
    required YouTubeLiveBanType type,
    int? durationSeconds,
  }) async {
    if (type == YouTubeLiveBanType.temporary &&
        (durationSeconds == null ||
            durationSeconds < 60 ||
            durationSeconds > 86400)) {
      throw ArgumentError.value(
        durationSeconds,
        'durationSeconds',
        'must be between 60 and 86400 for a temporary ban',
      );
    }
    if (type == YouTubeLiveBanType.permanent && durationSeconds != null) {
      throw ArgumentError.value(
        durationSeconds,
        'durationSeconds',
        'must be omitted for a permanent ban',
      );
    }
    final data = await _liveOwnerOperation(
      'liveInsertBan',
      body: <String, Object?>{
        ...chat.toJson(),
        'bannedChannelId': bannedChannelId,
        'type': type.wireValue,
        'durationSeconds': ?durationSeconds,
      },
    );
    return YouTubeLiveBan.fromJson(_asMap(data));
  }

  Future<YouTubeLiveBanDeleteResult> liveDeleteBan({
    required YouTubeLiveChatIdentity chat,
    required String banId,
    required String confirmBanId,
  }) async {
    _requireLiveConfirmation(banId, confirmBanId, 'confirmBanId');
    final data = await _liveOwnerOperation(
      'liveDeleteBan',
      body: <String, Object?>{
        ...chat.toJson(),
        'banId': banId,
        'confirmBanId': confirmBanId,
      },
    );
    return YouTubeLiveBanDeleteResult.fromJson(_asMap(data));
  }

  Future<YouTubeLiveSuperChatEventsPage> liveListSuperChatEvents({
    String? pageToken,
    int? maxResults,
    String? language,
  }) async {
    final data = await _liveOwnerOperation(
      'liveListSuperChatEvents',
      body: <String, Object?>{
        'pageToken': ?pageToken,
        'maxResults': ?maxResults,
        'language': ?language,
      },
    );
    return YouTubeLiveSuperChatEventsPage.fromJson(_asMap(data));
  }

  Future<YouTubeLiveMembersPage> liveListMembers({
    required YouTubeLiveMembershipMode mode,
    String? pageToken,
    int? maxResults,
    String? memberChannelId,
    String? levelId,
  }) async {
    final data = await _liveOwnerOperation(
      'liveListMembers',
      body: <String, Object?>{
        'mode': mode.wireValue,
        'pageToken': ?pageToken,
        'maxResults': ?maxResults,
        'memberChannelId': ?memberChannelId,
        'levelId': ?levelId,
      },
    );
    return YouTubeLiveMembersPage.fromJson(_asMap(data));
  }

  Future<YouTubeLiveMembershipLevels> liveListMembershipLevels() async {
    final data = await _liveOwnerOperation('liveListMembershipLevels');
    return YouTubeLiveMembershipLevels.fromJson(_asMap(data));
  }

  Future<Object?> _liveOwnerOperation(
    String operation, {
    Map<String, Object?> body = const <String, Object?>{},
  }) {
    if (!_liveEnabled) {
      throw const YouTubeCapabilityUnavailableException(
        message: 'YouTube Live private Dev capability is unavailable.',
        statusCode: 503,
      );
    }
    return _ownerMutation(operation, body: body);
  }

  void _requireLiveConfirmation(
    String resourceId,
    String confirmation,
    String parameter,
  ) {
    if (resourceId != confirmation.trim()) {
      throw ArgumentError.value(
        confirmation,
        parameter,
        'must exactly match the selected resource',
      );
    }
  }
}
