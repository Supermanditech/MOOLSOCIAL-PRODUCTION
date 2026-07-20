import 'package:flutter/foundation.dart';

import 'chat_models.dart';
import 'chat_services.dart';

class ChatSession extends ChangeNotifier {
  ChatSession({ChatSendGateway? sendGateway})
    : _sendGateway = sendGateway ?? ReviewChatSendGateway() {
    _messages.addAll({
      'home-basket': [
        const ChatMessage(
          id: 'm1',
          sender: 'Amit',
          text: 'Please add atta, rice and oil for this month.',
          timeLabel: '10:42',
          mine: false,
          reactionCount: 2,
        ),
        const ChatMessage(
          id: 'm2',
          sender: 'Rakesh',
          text: 'I shared the kitchen list and monthly staples file.',
          timeLabel: '10:49',
          mine: false,
          attachmentLabel: 'Monthly Staples.pdf',
        ),
      ],
      'mahadev': [
        const ChatMessage(
          id: 'm3',
          sender: 'Mahadev Fresh Mart',
          text: 'Your basket quote is ready for home delivery.',
          timeLabel: '10:36',
          mine: false,
          attachmentLabel: 'Basket quote · ₹645',
        ),
        const ChatMessage(
          id: 'm4',
          sender: 'You',
          text: 'Please confirm fresh tomatoes and a GST bill.',
          timeLabel: '10:38',
          mine: true,
        ),
      ],
      'order-support': [
        const ChatMessage(
          id: 'm5',
          sender: 'Order Support',
          text: 'Case MS-CASE-204 is open. Which item needs help?',
          timeLabel: '10:55',
          mine: false,
        ),
      ],
      'rasoi': [
        const ChatMessage(
          id: 'm6',
          sender: 'Rasoi Kitchen',
          text: 'Your lunch order is being prepared.',
          timeLabel: '10:21',
          mine: false,
        ),
      ],
      'clinic-care': [
        const ChatMessage(
          id: 'm7',
          sender: 'Sardarpura Clinic',
          text: 'Your appointment details are linked. How can the clinic help?',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
      'task-helper': [
        const ChatMessage(
          id: 'm8',
          sender: 'Ramesh Kumar',
          text: 'I accepted the task and can see the approved instructions.',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
    });
  }

  final ChatSendGateway _sendGateway;
  final Map<String, List<ChatMessage>> _messages = {};
  final Set<String> _readThreads = {};
  int _messageSequence = 10;

  static const threads = <ChatThread>[
    ChatThread(
      id: 'order-support',
      title: 'Order Support',
      subtitle: 'Case MS-CASE-204',
      preview: 'Your missing-item case is open.',
      timeLabel: 'Now',
      type: ChatThreadType.support,
      unreadCount: 1,
      verified: true,
    ),
    ChatThread(
      id: 'mahadev',
      title: 'Mahadev Fresh Mart',
      subtitle: 'Verified local shop',
      preview: 'Your basket quote is ready.',
      timeLabel: '10:38',
      type: ChatThreadType.business,
      unreadCount: 1,
      verified: true,
    ),
    ChatThread(
      id: 'home-basket',
      title: 'Home Basket Group',
      subtitle: '5 members',
      preview: 'Amit: Add atta, rice and oil.',
      timeLabel: '10:49',
      type: ChatThreadType.people,
    ),
    ChatThread(
      id: 'rasoi',
      title: 'Rasoi Kitchen Order',
      subtitle: 'Order MS-EAT-217',
      preview: 'Your lunch order is being prepared.',
      timeLabel: '10:21',
      type: ChatThreadType.order,
      unreadCount: 1,
      verified: true,
    ),
    ChatThread(
      id: 'clinic-care',
      title: 'Sardarpura Clinic',
      subtitle: 'Verified clinic · Appointment support',
      preview: 'Your appointment details are linked.',
      timeLabel: 'Now',
      type: ChatThreadType.business,
      verified: true,
    ),
    ChatThread(
      id: 'task-helper',
      title: 'Ramesh Kumar',
      subtitle: 'Verified helper · Active task',
      preview: 'I can see the approved task instructions.',
      timeLabel: 'Now',
      type: ChatThreadType.business,
      verified: true,
    ),
  ];

  ChatThreadType? selectedFilter;
  bool unreadOnly = false;
  String? noticeMessage;
  String? errorMessage;
  String? pendingAttachment;
  String? replyingTo;
  bool busy = false;
  final List<String> pollOptions = [
    'Today evening',
    'Tomorrow morning',
    'Tomorrow evening',
  ];
  final List<String> invitedMembers = [];

  List<ChatThread> visibleThreads([String query = '']) {
    final normalized = query.trim().toLowerCase();
    return threads.where((thread) {
      final filterMatches =
          selectedFilter == null || thread.type == selectedFilter;
      final unreadMatches =
          !unreadOnly ||
          (thread.unreadCount > 0 && !_readThreads.contains(thread.id));
      final queryMatches =
          normalized.isEmpty ||
          thread.title.toLowerCase().contains(normalized) ||
          thread.subtitle.toLowerCase().contains(normalized) ||
          thread.preview.toLowerCase().contains(normalized);
      return filterMatches && unreadMatches && queryMatches;
    }).toList();
  }

  ChatThread thread(String id) {
    return threads.firstWhere(
      (thread) => thread.id == id,
      orElse: () => threads.first,
    );
  }

  List<ChatMessage> messages(String threadId) {
    return List.unmodifiable(_messages[threadId] ?? const []);
  }

  void chooseAll() {
    if (selectedFilter == null && !unreadOnly) return;
    selectedFilter = null;
    unreadOnly = false;
    notifyListeners();
  }

  void chooseUnread() {
    selectedFilter = null;
    unreadOnly = true;
    notifyListeners();
  }

  void chooseFilter(ChatThreadType value) {
    if (selectedFilter == value && !unreadOnly) return;
    selectedFilter = value;
    unreadOnly = false;
    notifyListeners();
  }

  void markRead(String threadId) {
    if (_readThreads.add(threadId)) notifyListeners();
  }

  int unreadFor(ChatThread thread) {
    return _readThreads.contains(thread.id) ? 0 : thread.unreadCount;
  }

  void attach(String label) {
    pendingAttachment = label;
    errorMessage = null;
    noticeMessage = '$label attached. Add a message or send it now.';
    notifyListeners();
  }

  void removeAttachment() {
    pendingAttachment = null;
    noticeMessage = 'Attachment removed.';
    errorMessage = null;
    notifyListeners();
  }

  void startReply(String messageId) {
    replyingTo = messageId;
    noticeMessage = null;
    errorMessage = null;
    notifyListeners();
  }

  void cancelReply() {
    replyingTo = null;
    notifyListeners();
  }

  Future<bool> send(String threadId, String value) async {
    if (busy) return false;
    final text = value.trim();
    if (text.isEmpty && pendingAttachment == null) {
      errorMessage = 'Write a message or add an attachment.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    noticeMessage = null;
    _messageSequence += 1;
    final message = ChatMessage(
      id: 'm$_messageSequence',
      sender: 'You',
      text: text.isEmpty ? pendingAttachment! : text,
      timeLabel: 'Now',
      mine: true,
      deliveryState: ChatDeliveryState.sending,
      attachmentLabel: pendingAttachment,
    );
    final values = _messages.putIfAbsent(threadId, () => []);
    values.add(message);
    pendingAttachment = null;
    replyingTo = null;
    notifyListeners();
    try {
      await _sendGateway.send(
        threadId: threadId,
        text: message.text,
        attachmentLabel: message.attachmentLabel,
      );
      _replaceMessage(
        threadId,
        message.id,
        message.copyWith(deliveryState: ChatDeliveryState.delivered),
      );
      noticeMessage = 'Message delivered.';
      return true;
    } on ChatServiceException catch (error) {
      _replaceMessage(
        threadId,
        message.id,
        message.copyWith(deliveryState: ChatDeliveryState.failed),
      );
      errorMessage = error.userMessage;
      return false;
    } on Object {
      _replaceMessage(
        threadId,
        message.id,
        message.copyWith(deliveryState: ChatDeliveryState.failed),
      );
      errorMessage = 'Message was not sent. Check your connection and retry.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> retry(String threadId, String messageId) async {
    final values = _messages[threadId] ?? [];
    final index = values.indexWhere((message) => message.id == messageId);
    if (index < 0) return false;
    final failed = values[index];
    values.removeAt(index);
    pendingAttachment = failed.attachmentLabel;
    return send(threadId, failed.text);
  }

  void toggleReaction(String threadId, String messageId) {
    final values = _messages[threadId] ?? [];
    final index = values.indexWhere((message) => message.id == messageId);
    if (index < 0) return;
    final current = values[index];
    values[index] = current.copyWith(
      reactionCount: current.reactionCount == 0 ? 1 : current.reactionCount - 1,
    );
    notifyListeners();
  }

  bool addPollOption(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      errorMessage = 'Enter a clear poll option.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (pollOptions.any(
      (option) => option.toLowerCase() == trimmed.toLowerCase(),
    )) {
      errorMessage = 'This poll option is already included.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    pollOptions.add(trimmed);
    errorMessage = null;
    noticeMessage = '$trimmed added to the poll.';
    notifyListeners();
    return true;
  }

  bool inviteMember(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      errorMessage = 'Enter a name or mobile number.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (invitedMembers.any(
      (member) => member.toLowerCase() == trimmed.toLowerCase(),
    )) {
      errorMessage = 'This person is already invited.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    invitedMembers.add(trimmed);
    errorMessage = null;
    noticeMessage = 'Invite prepared for $trimmed.';
    notifyListeners();
    return true;
  }

  void showNotice(String message) {
    errorMessage = null;
    noticeMessage = message;
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    noticeMessage = null;
    notifyListeners();
  }

  void _replaceMessage(
    String threadId,
    String messageId,
    ChatMessage replacement,
  ) {
    final values = _messages[threadId] ?? [];
    final index = values.indexWhere((message) => message.id == messageId);
    if (index >= 0) values[index] = replacement;
  }
}
