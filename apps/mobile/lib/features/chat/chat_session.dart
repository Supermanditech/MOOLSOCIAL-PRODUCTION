import 'package:flutter/foundation.dart';

import 'chat_models.dart';
import 'chat_services.dart';

class ChatSession extends ChangeNotifier {
  ChatSession({ChatSendGateway? sendGateway, this._photoPicker})
    : _gateway = null,
      _reviewSendGateway = sendGateway ?? ReviewChatSendGateway() {
    _threads.addAll(reviewThreads);
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
      'ride-support': [
        const ChatMessage(
          id: 'm9',
          sender: 'Trip Support',
          text:
              'Your Bike Saver trip from Sardarpura pickup gate to Railway Station is ready for coordination.',
          timeLabel: 'Now',
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
      'workspace-support': [
        const ChatMessage(
          id: 'workspace-review-1',
          sender: 'Workspace Review',
          text:
              'Choose one provider profile and complete only the requested details. Your personal account remains active during review.',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
    });
  }

  ChatSession.production({ChatGateway? gateway, ChatPhotoPicker? photoPicker})
    : _gateway = gateway ?? buildChatGateway(),
      _reviewSendGateway = null,
      _photoPicker = photoPicker ?? NativeChatPhotoPicker();

  final ChatGateway? _gateway;
  final ChatSendGateway? _reviewSendGateway;
  final ChatPhotoPicker? _photoPicker;
  final List<ChatThread> _threads = [];
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, String> _messageLoadErrors = {};
  final Map<String, String> _threadActionErrors = {};
  final Map<String, String> _threadActionNotices = {};
  final Set<String> _readThreads = {};
  final Map<String, String> _retryKeys = {};
  final Map<String, String> _forwardRetryKeys = {};
  final Map<String, ChatMessage> _replyTargets = {};
  final Map<String, _PendingChatPhoto> _pendingPhotos = {};
  final Map<String, bool> _chatAvailableForSession = {};
  final Map<String, bool> _voiceCallsAvailableForSession = {};
  final Map<String, bool> _videoCallsAvailableForSession = {};
  int _messageSequence = 10;

  static const reviewThreads = <ChatThread>[
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
      id: 'shop-order',
      title: 'Fresh Basket Order',
      subtitle: 'Order MS-240782',
      preview: 'Your grocery order is being packed.',
      timeLabel: 'Now',
      type: ChatThreadType.order,
      unreadCount: 1,
      verified: true,
    ),
    ChatThread(
      id: 'shop-partner',
      title: 'Metro Wholesale Partner',
      subtitle: 'Verified wholesale partner',
      preview: 'Your bulk quote is ready.',
      timeLabel: 'Now',
      type: ChatThreadType.business,
      verified: true,
    ),
    ChatThread(
      id: 'shop-offers',
      title: 'Shop Offers Support',
      subtitle: 'Offer help',
      preview: 'We can help with this Shop offer.',
      timeLabel: 'Now',
      type: ChatThreadType.support,
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
      id: 'ride-support',
      title: 'Trip Support',
      subtitle: 'Bike Saver · Sardarpura to Railway Station',
      preview: 'Your trip is ready for coordination.',
      timeLabel: 'Now',
      type: ChatThreadType.support,
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
      safetyTarget: ChatSafetyTarget.person,
    ),
    ChatThread(
      id: 'workspace-support',
      title: 'Workspace Review',
      subtitle: 'Setup and application support',
      preview: 'Complete only the details requested for review.',
      timeLabel: 'Now',
      type: ChatThreadType.support,
      verified: true,
    ),
  ];

  ChatThreadType? selectedFilter;
  bool unreadOnly = false;
  String? noticeMessage;
  String? errorMessage;
  bool busy = false;
  bool loadingThreads = false;
  bool threadsLoaded = false;
  final Set<String> loadingMessageThreads = {};
  final Set<String> readingThreads = {};
  final List<String> pollOptions = [
    'Today evening',
    'Tomorrow morning',
    'Tomorrow evening',
  ];
  final List<String> invitedMembers = [];

  List<ChatThread> visibleThreads([String query = '']) {
    final normalized = query.trim().toLowerCase();
    return _threads.where((thread) {
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

  List<ChatThread> availableForwardTargets(String sourceThreadId) {
    return List.unmodifiable(
      _threads.where((thread) => thread.id != sourceThreadId),
    );
  }

  ChatThread thread(String id) {
    return _threads.firstWhere(
      (thread) => thread.id == id,
      orElse: () => ChatThread(
        id: id,
        title: 'Conversation',
        subtitle: 'Loading messages',
        preview: '',
        timeLabel: '',
        type: ChatThreadType.people,
      ),
    );
  }

  List<ChatMessage> messages(String threadId) {
    return List.unmodifiable(_messages[threadId] ?? const []);
  }

  String? messageLoadError(String threadId) => _messageLoadErrors[threadId];

  String? threadActionError(String threadId) => _threadActionErrors[threadId];

  String? threadActionNotice(String threadId) => _threadActionNotices[threadId];

  ChatMessage? replyTarget(String threadId) => _replyTargets[threadId];

  bool chatAvailableForSession(String threadId) =>
      _chatAvailableForSession[threadId] ?? true;

  bool voiceCallsAvailableForSession(String threadId) =>
      _voiceCallsAvailableForSession[threadId] ?? true;

  bool videoCallsAvailableForSession(String threadId) =>
      _videoCallsAvailableForSession[threadId] ?? true;

  void setChatAvailableForSession(String threadId, {required bool available}) {
    if (chatAvailableForSession(threadId) == available) return;
    _chatAvailableForSession[threadId] = available;
    notifyListeners();
  }

  void setVoiceCallsAvailableForSession(
    String threadId, {
    required bool available,
  }) {
    if (voiceCallsAvailableForSession(threadId) == available) return;
    _voiceCallsAvailableForSession[threadId] = available;
    notifyListeners();
  }

  void setVideoCallsAvailableForSession(
    String threadId, {
    required bool available,
  }) {
    if (videoCallsAvailableForSession(threadId) == available) return;
    _videoCallsAvailableForSession[threadId] = available;
    notifyListeners();
  }

  bool get photoSharingAvailable =>
      _gateway is ChatPhotoGateway && _photoPicker != null;

  ChatPickedPhoto? selectedPhoto(String threadId) =>
      _pendingPhotos[threadId]?.photo;

  Future<bool> selectPhoto(String threadId, ChatPhotoSource source) {
    return _stagePhoto(
      threadId,
      () => _photoPicker!.pick(source),
      unavailableMessage: 'That photo could not be opened. Choose it again.',
    );
  }

  Future<bool> recoverInterruptedPhotoSelection(String threadId) {
    if (_pendingPhotos.containsKey(threadId)) return Future.value(true);
    return _stagePhoto(
      threadId,
      () => _photoPicker!.recoverInterruptedSelection(),
      unavailableMessage: 'The interrupted photo could not be recovered.',
    );
  }

  void cancelSelectedPhoto(String threadId) {
    if (busy) return;
    if (_pendingPhotos.remove(threadId) != null) {
      _threadActionErrors.remove(threadId);
      _threadActionNotices.remove(threadId);
      notifyListeners();
    }
  }

  Future<bool> _stagePhoto(
    String threadId,
    Future<ChatPickedPhoto?> Function() choose, {
    required String unavailableMessage,
  }) async {
    if (busy || !photoSharingAvailable) return false;
    busy = true;
    _threadActionErrors.remove(threadId);
    _threadActionNotices.remove(threadId);
    notifyListeners();
    try {
      final photo = await choose();
      if (photo == null) return false;
      _pendingPhotos[threadId] = _PendingChatPhoto(
        photo: photo,
        idempotencyKey:
            'chat-photo-${DateTime.now().microsecondsSinceEpoch}-${++_messageSequence}',
      );
      _threadActionNotices[threadId] = 'Photo ready to send.';
      return true;
    } on ChatServiceException catch (error) {
      _threadActionErrors[threadId] = error.userMessage;
      return false;
    } on Object {
      _threadActionErrors[threadId] = unavailableMessage;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> sendSelectedPhoto(String threadId, String caption) async {
    if (busy) return false;
    final pending = _pendingPhotos[threadId];
    final photoGateway = _gateway is ChatPhotoGateway
        ? _gateway as ChatPhotoGateway
        : null;
    if (pending == null || photoGateway == null) {
      _threadActionErrors[threadId] = 'Choose a photo first.';
      _threadActionNotices.remove(threadId);
      notifyListeners();
      return false;
    }
    final requestedCaption = caption.trim();
    if (pending.sendLocked && requestedCaption != pending.caption) {
      _threadActionErrors[threadId] =
          'This retry keeps the original caption. Remove the photo to change it.';
      _threadActionNotices.remove(threadId);
      notifyListeners();
      return false;
    }
    if (!pending.sendLocked) {
      pending
        ..caption = requestedCaption
        ..replyTo = _replyReference(_replyTargets[threadId])
        ..sendLocked = true;
    }
    busy = true;
    _threadActionErrors.remove(threadId);
    _threadActionNotices.remove(threadId);
    notifyListeners();
    try {
      final delivered = await photoGateway.sendPhoto(
        threadId: threadId,
        photo: pending.photo,
        caption: pending.caption,
        idempotencyKey: pending.idempotencyKey,
        replyToMessageId: pending.replyTo?.messageId,
      );
      if (delivered.photo == null) {
        throw const ChatServiceException(
          'Chat returned an invalid photo. Try again.',
          code: 'invalid_response',
          retryable: true,
        );
      }
      final values = _messages.putIfAbsent(threadId, () => []);
      if (!values.any((message) => message.id == delivered.id)) {
        values.add(delivered);
      }
      if (identical(_pendingPhotos[threadId], pending)) {
        _pendingPhotos.remove(threadId);
      }
      if (_replyTargets[threadId]?.id == pending.replyTo?.messageId) {
        _replyTargets.remove(threadId);
      }
      _threadActionNotices[threadId] = 'Photo delivered.';
      return true;
    } on ChatServiceException catch (error) {
      _threadActionErrors[threadId] = error.userMessage;
      return false;
    } on Object {
      _threadActionErrors[threadId] =
          'Photo was not sent. Check your connection and try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> loadThreads({bool refresh = false}) async {
    final gateway = _gateway;
    if (gateway == null || loadingThreads || (threadsLoaded && !refresh)) {
      return gateway == null || threadsLoaded;
    }
    loadingThreads = true;
    errorMessage = null;
    notifyListeners();
    try {
      final values = await gateway.listThreads();
      _threads
        ..clear()
        ..addAll(values);
      threadsLoaded = true;
      return true;
    } on ChatServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage = 'Chat could not load. Check your connection and retry.';
      return false;
    } finally {
      loadingThreads = false;
      notifyListeners();
    }
  }

  Future<bool> loadMessages(String threadId, {bool refresh = false}) async {
    final gateway = _gateway;
    if (gateway == null || loadingMessageThreads.contains(threadId)) {
      return gateway == null;
    }
    if (!refresh && _messages.containsKey(threadId)) return true;
    loadingMessageThreads.add(threadId);
    _messageLoadErrors.remove(threadId);
    errorMessage = null;
    notifyListeners();
    try {
      final loaded = await gateway.listMessages(threadId: threadId);
      _messages[threadId] = List<ChatMessage>.of(loaded);
      _messageLoadErrors.remove(threadId);
      return true;
    } on ChatServiceException catch (error) {
      _messageLoadErrors[threadId] = error.userMessage;
      return false;
    } on Object {
      _messageLoadErrors[threadId] =
          'Messages could not load. Check your connection and retry.';
      return false;
    } finally {
      loadingMessageThreads.remove(threadId);
      notifyListeners();
    }
  }

  Future<ChatThread?> createDirectThread(String targetUserId) async {
    final gateway = _gateway;
    if (gateway == null || busy) return null;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final created = await gateway.createDirectThread(
        targetUserId: targetUserId,
      );
      final index = _threads.indexWhere((thread) => thread.id == created.id);
      if (index < 0) {
        _threads.insert(0, created);
      } else {
        _threads[index] = created;
      }
      threadsLoaded = true;
      return created;
    } on ChatServiceException catch (error) {
      errorMessage = error.userMessage;
      return null;
    } on Object {
      errorMessage = 'That conversation could not start. Try again.';
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
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

  Future<bool> markRead(String threadId) async {
    if (readingThreads.contains(threadId)) return false;
    readingThreads.add(threadId);
    _threadActionErrors.remove(threadId);
    notifyListeners();
    try {
      final gateway = _gateway;
      if (gateway != null) await gateway.markThreadRead(threadId: threadId);
      _readThreads.add(threadId);
      return true;
    } on ChatServiceException catch (error) {
      _threadActionErrors[threadId] = error.userMessage;
      return false;
    } on Object {
      _threadActionErrors[threadId] =
          'Read status could not update. Check your connection and retry.';
      return false;
    } finally {
      readingThreads.remove(threadId);
      notifyListeners();
    }
  }

  int unreadFor(ChatThread thread) {
    return _readThreads.contains(thread.id) ? 0 : thread.unreadCount;
  }

  Future<bool> send(
    String threadId,
    String value, {
    String? retryKey,
    ChatReplyReference? replyOverride,
  }) async {
    if (busy) return false;
    final text = value.trim();
    if (text.isEmpty) {
      _threadActionErrors[threadId] = 'Write a message.';
      _threadActionNotices.remove(threadId);
      notifyListeners();
      return false;
    }
    busy = true;
    _threadActionErrors.remove(threadId);
    _threadActionNotices.remove(threadId);
    _messageSequence += 1;
    final idempotencyKey =
        retryKey ??
        'chat-${DateTime.now().microsecondsSinceEpoch}-$_messageSequence';
    final selectedReply =
        replyOverride ?? _replyReference(_replyTargets[threadId]);
    final message = ChatMessage(
      id: 'm$_messageSequence',
      sender: 'You',
      text: text,
      timeLabel: 'Now',
      mine: true,
      deliveryState: ChatDeliveryState.sending,
      replyTo: selectedReply,
    );
    final values = _messages.putIfAbsent(threadId, () => []);
    values.add(message);
    notifyListeners();
    try {
      final gateway = _gateway;
      final delivered = gateway == null
          ? null
          : await gateway.sendMessage(
              threadId: threadId,
              text: message.text,
              idempotencyKey: idempotencyKey,
              replyToMessageId: selectedReply?.messageId,
            );
      if (gateway == null) {
        final reviewSendGateway = _reviewSendGateway;
        if (reviewSendGateway == null) {
          throw StateError('Chat has no configured send gateway.');
        }
        await reviewSendGateway.send(threadId: threadId, text: message.text);
      }
      _replaceMessage(
        threadId,
        message.id,
        delivered ??
            message.copyWith(deliveryState: ChatDeliveryState.delivered),
      );
      _retryKeys.remove(message.id);
      if (_replyTargets[threadId]?.id == selectedReply?.messageId) {
        _replyTargets.remove(threadId);
      }
      _threadActionNotices[threadId] = 'Message delivered.';
      return true;
    } on ChatServiceException catch (error) {
      _replaceMessage(
        threadId,
        message.id,
        message.copyWith(deliveryState: ChatDeliveryState.failed),
      );
      _retryKeys[message.id] = idempotencyKey;
      _threadActionErrors[threadId] = error.userMessage;
      return false;
    } on Object {
      _replaceMessage(
        threadId,
        message.id,
        message.copyWith(deliveryState: ChatDeliveryState.failed),
      );
      _retryKeys[message.id] = idempotencyKey;
      _threadActionErrors[threadId] =
          'Message was not sent. Check your connection and retry.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> retry(String threadId, String messageId) async {
    if (busy) return false;
    final values = _messages[threadId] ?? [];
    final index = values.indexWhere((message) => message.id == messageId);
    if (index < 0) return false;
    final failed = values[index];
    final retryKey = _retryKeys.remove(messageId);
    values.removeAt(index);
    return send(
      threadId,
      failed.text,
      retryKey: retryKey,
      replyOverride: failed.replyTo,
    );
  }

  bool startReply(String threadId, String messageId) {
    if (busy) return false;
    final values = _messages[threadId] ?? [];
    final index = values.indexWhere((message) => message.id == messageId);
    if (index < 0 || !values[index].isSettled) {
      return false;
    }
    _replyTargets[threadId] = values[index];
    _threadActionErrors.remove(threadId);
    _threadActionNotices.remove(threadId);
    notifyListeners();
    return true;
  }

  void cancelReply(String threadId) {
    if (_replyTargets.remove(threadId) != null) notifyListeners();
  }

  Future<bool> toggleReaction(String threadId, String messageId) async {
    if (busy) return false;
    final values = _messages[threadId] ?? [];
    final index = values.indexWhere((message) => message.id == messageId);
    if (index < 0 || !values[index].isSettled) {
      return false;
    }
    final current = values[index];
    final reacted = !current.reactedByMe;
    busy = true;
    _threadActionErrors.remove(threadId);
    _threadActionNotices.remove(threadId);
    notifyListeners();
    try {
      final gateway = _gateway;
      final saved = gateway == null
          ? current.copyWith(
              reactionCount: reacted
                  ? current.reactionCount + 1
                  : current.reactionCount > 0
                  ? current.reactionCount - 1
                  : 0,
              reactedByMe: reacted,
            )
          : await gateway.setReaction(
              threadId: threadId,
              messageId: messageId,
              reacted: reacted,
            );
      _replaceMessage(threadId, messageId, saved);
      _threadActionNotices[threadId] = reacted
          ? 'Reaction added.'
          : 'Reaction removed.';
      return true;
    } on ChatServiceException catch (error) {
      _threadActionErrors[threadId] = error.userMessage;
      return false;
    } on Object {
      _threadActionErrors[threadId] =
          'Reaction could not update. Check your connection and retry.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> forwardMessage(
    String sourceThreadId,
    String sourceMessageId,
    String targetThreadId,
  ) async {
    if (busy || sourceThreadId == targetThreadId) return false;
    final sourceMessages = _messages[sourceThreadId] ?? const <ChatMessage>[];
    final sourceIndex = sourceMessages.indexWhere(
      (message) => message.id == sourceMessageId,
    );
    final targetExists = _threads.any((thread) => thread.id == targetThreadId);
    if (sourceIndex < 0 || !targetExists) return false;
    final source = sourceMessages[sourceIndex];
    if (!source.isSettled ||
        source.text.trim().isEmpty ||
        source.attachmentLabel != null ||
        source.photo != null) {
      _threadActionErrors[sourceThreadId] =
          'Only delivered text messages can be forwarded right now.';
      _threadActionNotices.remove(sourceThreadId);
      notifyListeners();
      return false;
    }
    final retryOwner = '$sourceThreadId|$sourceMessageId|$targetThreadId';
    final idempotencyKey = _forwardRetryKeys.putIfAbsent(
      retryOwner,
      () =>
          'chat-forward-${DateTime.now().microsecondsSinceEpoch}-${++_messageSequence}',
    );
    busy = true;
    _threadActionErrors.remove(sourceThreadId);
    _threadActionNotices.remove(sourceThreadId);
    notifyListeners();
    try {
      final gateway = _gateway;
      final forwarded = gateway == null
          ? ChatMessage(
              id: 'forward-m${++_messageSequence}',
              sender: 'You',
              text: source.text,
              timeLabel: 'Now',
              mine: true,
              forwarded: true,
            )
          : await gateway.forwardMessage(
              sourceThreadId: sourceThreadId,
              sourceMessageId: sourceMessageId,
              targetThreadId: targetThreadId,
              idempotencyKey: idempotencyKey,
            );
      final targetMessages = _messages[targetThreadId];
      if (targetMessages != null &&
          !targetMessages.any((message) => message.id == forwarded.id)) {
        targetMessages.add(forwarded);
      }
      _forwardRetryKeys.remove(retryOwner);
      _threadActionNotices[sourceThreadId] =
          'Message forwarded to ${thread(targetThreadId).title}.';
      return true;
    } on ChatServiceException catch (error) {
      _threadActionErrors[sourceThreadId] = error.userMessage;
      return false;
    } on Object {
      _threadActionErrors[sourceThreadId] =
          'Message could not be forwarded. Check your connection and retry.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
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

  void resetForAuthenticationBoundary() {
    _threads.clear();
    _messages.clear();
    _messageLoadErrors.clear();
    _threadActionErrors.clear();
    _threadActionNotices.clear();
    _readThreads.clear();
    _retryKeys.clear();
    _forwardRetryKeys.clear();
    _replyTargets.clear();
    _pendingPhotos.clear();
    selectedFilter = null;
    unreadOnly = false;
    noticeMessage = null;
    errorMessage = null;
    busy = false;
    loadingThreads = false;
    threadsLoaded = false;
    loadingMessageThreads.clear();
    readingThreads.clear();
    invitedMembers.clear();
    pollOptions
      ..clear()
      ..addAll(const ['Today evening', 'Tomorrow morning', 'Tomorrow evening']);
    notifyListeners();
  }

  void clearThreadMessages(String threadId) {
    final hadError = _threadActionErrors.remove(threadId) != null;
    final hadNotice = _threadActionNotices.remove(threadId) != null;
    if (hadError || hadNotice) notifyListeners();
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

  ChatReplyReference? _replyReference(ChatMessage? message) {
    if (message == null) return null;
    final text = message.text.trim().isNotEmpty
        ? message.text.trim()
        : message.photo != null
        ? 'Photo'
        : message.attachmentLabel?.trim().isNotEmpty == true
        ? message.attachmentLabel!.trim()
        : 'Message';
    return ChatReplyReference(
      messageId: message.id,
      sender: message.sender,
      text: text,
    );
  }
}

class _PendingChatPhoto {
  _PendingChatPhoto({required this.photo, required this.idempotencyKey});

  final ChatPickedPhoto photo;
  final String idempotencyKey;
  String caption = '';
  ChatReplyReference? replyTo;
  bool sendLocked = false;
}
