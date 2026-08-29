enum ChatThreadType { people, business, order, support }

enum ChatSafetyTarget { person, business, conversation }

enum ChatDeliveryState { sending, delivered, read, failed }

enum ChatMessagePermission { everyone, connections, nobody }

enum ChatCallKind { voice, video }

enum ChatCallStatus { ringing, accepted, declined, ended }

enum ChatCallAvailabilityStatus { available, offline, callsOff, busy }

enum ChatPresenceState { active, background, offline }

enum ChatAttachmentKind { document, video, voice }

class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.kind,
    required this.name,
    required this.contentType,
    required this.sizeBytes,
    required this.readUrl,
    required this.readUrlExpiresAt,
    this.duration,
  });

  final String id;
  final ChatAttachmentKind kind;
  final String name;
  final String contentType;
  final int sizeBytes;
  final Uri readUrl;
  final DateTime readUrlExpiresAt;
  final Duration? duration;
}

class ChatCallPreferences {
  const ChatCallPreferences({
    required this.voiceCallsEnabled,
    required this.videoCallsEnabled,
    this.updatedAt,
  });

  static const defaults = ChatCallPreferences(
    voiceCallsEnabled: true,
    videoCallsEnabled: true,
  );

  final bool voiceCallsEnabled;
  final bool videoCallsEnabled;
  final DateTime? updatedAt;

  ChatCallPreferences copyWith({
    bool? voiceCallsEnabled,
    bool? videoCallsEnabled,
    DateTime? updatedAt,
  }) => ChatCallPreferences(
    voiceCallsEnabled: voiceCallsEnabled ?? this.voiceCallsEnabled,
    videoCallsEnabled: videoCallsEnabled ?? this.videoCallsEnabled,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class ChatCallAvailability {
  const ChatCallAvailability({
    required this.threadId,
    required this.kind,
    required this.recipientUserId,
    required this.recipientName,
    required this.canStart,
    required this.status,
    required this.message,
  });

  final String threadId;
  final ChatCallKind kind;
  final String recipientUserId;
  final String recipientName;
  final bool canStart;
  final ChatCallAvailabilityStatus status;
  final String message;
}

class ChatCall {
  const ChatCall({
    required this.id,
    required this.threadId,
    required this.kind,
    required this.callerUserId,
    required this.recipientUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String threadId;
  final ChatCallKind kind;
  final String callerUserId;
  final String recipientUserId;
  final ChatCallStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ChatPrivacySettings {
  const ChatPrivacySettings({
    required this.whoCanMessage,
    required this.messageRequestsEnabled,
    required this.shareLastSeen,
    required this.readReceipts,
    this.updatedAt,
  });

  static const defaults = ChatPrivacySettings(
    whoCanMessage: ChatMessagePermission.everyone,
    messageRequestsEnabled: true,
    shareLastSeen: true,
    readReceipts: true,
  );

  final ChatMessagePermission whoCanMessage;
  final bool messageRequestsEnabled;
  final bool shareLastSeen;
  final bool readReceipts;
  final DateTime? updatedAt;

  ChatPrivacySettings copyWith({
    ChatMessagePermission? whoCanMessage,
    bool? messageRequestsEnabled,
    bool? shareLastSeen,
    bool? readReceipts,
    DateTime? updatedAt,
  }) => ChatPrivacySettings(
    whoCanMessage: whoCanMessage ?? this.whoCanMessage,
    messageRequestsEnabled:
        messageRequestsEnabled ?? this.messageRequestsEnabled,
    shareLastSeen: shareLastSeen ?? this.shareLastSeen,
    readReceipts: readReceipts ?? this.readReceipts,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class ChatBlockedAccount {
  const ChatBlockedAccount({
    required this.userId,
    required this.name,
    required this.handle,
    required this.blockedAt,
  });

  final String userId;
  final String name;
  final String handle;
  final DateTime blockedAt;
}

class ChatMessageRequest {
  const ChatMessageRequest({
    required this.thread,
    required this.requestedByUserId,
    required this.requestedAt,
  });

  final ChatThread thread;
  final String requestedByUserId;
  final DateTime requestedAt;
}

class ChatPhotoAttachment {
  const ChatPhotoAttachment({
    required this.id,
    required this.name,
    required this.contentType,
    required this.sizeBytes,
    required this.readUrl,
    required this.readUrlExpiresAt,
  });

  final String id;
  final String name;
  final String contentType;
  final int sizeBytes;
  final Uri readUrl;
  final DateTime readUrlExpiresAt;
}

class ChatReplyReference {
  const ChatReplyReference({
    required this.messageId,
    required this.sender,
    required this.text,
  });

  final String messageId;
  final String sender;
  final String text;
}

class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.name,
    required this.subtitle,
    this.isMe = false,
    this.verified = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final bool isMe;
  final bool verified;
}

class ChatThread {
  const ChatThread({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.timeLabel,
    required this.type,
    this.unreadCount = 0,
    this.verified = false,
    this.safetyTarget,
    this.suggestedPrompts = const [],
    this.participants = const [],
    this.groupDescription,
    this.targetUserId,
    this.messageRequestPending = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String preview;
  final String timeLabel;
  final ChatThreadType type;
  final int unreadCount;
  final bool verified;
  final ChatSafetyTarget? safetyTarget;
  final List<String> suggestedPrompts;
  final List<ChatParticipant> participants;
  final String? groupDescription;
  final String? targetUserId;
  final bool messageRequestPending;

  bool get isGroup => participants.isNotEmpty;

  ChatSafetyTarget get effectiveSafetyTarget =>
      safetyTarget ??
      switch (type) {
        ChatThreadType.people => ChatSafetyTarget.person,
        ChatThreadType.business => ChatSafetyTarget.business,
        ChatThreadType.order ||
        ChatThreadType.support => ChatSafetyTarget.conversation,
      };
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timeLabel,
    required this.mine,
    this.deliveryState = ChatDeliveryState.delivered,
    this.attachmentLabel,
    this.reactionCount = 0,
    this.reactedByMe = false,
    this.replyTo,
    this.readCount = 0,
    this.forwarded = false,
    this.photo,
    this.attachment,
  });

  final String id;
  final String sender;
  final String text;
  final String timeLabel;
  final bool mine;
  final ChatDeliveryState deliveryState;
  final String? attachmentLabel;
  final int reactionCount;
  final bool reactedByMe;
  final ChatReplyReference? replyTo;
  final int readCount;
  final bool forwarded;
  final ChatPhotoAttachment? photo;
  final ChatAttachment? attachment;

  ChatMessage copyWith({
    ChatDeliveryState? deliveryState,
    int? reactionCount,
    bool? reactedByMe,
  }) {
    return ChatMessage(
      id: id,
      sender: sender,
      text: text,
      timeLabel: timeLabel,
      mine: mine,
      deliveryState: deliveryState ?? this.deliveryState,
      attachmentLabel: attachmentLabel,
      reactionCount: reactionCount ?? this.reactionCount,
      reactedByMe: reactedByMe ?? this.reactedByMe,
      replyTo: replyTo,
      readCount: readCount,
      forwarded: forwarded,
      photo: photo,
      attachment: attachment,
    );
  }

  bool get isSettled =>
      deliveryState == ChatDeliveryState.delivered ||
      deliveryState == ChatDeliveryState.read;
}

extension ChatThreadTypeCopy on ChatThreadType {
  String get label => switch (this) {
    ChatThreadType.people => 'People',
    ChatThreadType.business => 'Business',
    ChatThreadType.order => 'Orders',
    ChatThreadType.support => 'Support',
  };
}
