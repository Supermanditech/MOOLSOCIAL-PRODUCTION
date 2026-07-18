enum ChatThreadType { people, business, order, support }

enum ChatDeliveryState { sending, delivered, failed }

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
  });

  final String id;
  final String title;
  final String subtitle;
  final String preview;
  final String timeLabel;
  final ChatThreadType type;
  final int unreadCount;
  final bool verified;
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
  });

  final String id;
  final String sender;
  final String text;
  final String timeLabel;
  final bool mine;
  final ChatDeliveryState deliveryState;
  final String? attachmentLabel;
  final int reactionCount;

  ChatMessage copyWith({ChatDeliveryState? deliveryState, int? reactionCount}) {
    return ChatMessage(
      id: id,
      sender: sender,
      text: text,
      timeLabel: timeLabel,
      mine: mine,
      deliveryState: deliveryState ?? this.deliveryState,
      attachmentLabel: attachmentLabel,
      reactionCount: reactionCount ?? this.reactionCount,
    );
  }
}

extension ChatThreadTypeCopy on ChatThreadType {
  String get label => switch (this) {
    ChatThreadType.people => 'People',
    ChatThreadType.business => 'Business',
    ChatThreadType.order => 'Orders',
    ChatThreadType.support => 'Support',
  };
}
