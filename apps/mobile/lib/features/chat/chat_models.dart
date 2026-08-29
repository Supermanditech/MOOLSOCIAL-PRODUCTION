enum ChatThreadType { people, business, order, support }

enum ChatSafetyTarget { person, business, conversation }

enum ChatDeliveryState { sending, delivered, read, failed }

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
