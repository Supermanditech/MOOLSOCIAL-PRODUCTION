import 'package:flutter/foundation.dart';

import 'chat_models.dart';
import 'chat_services.dart';

class ChatSession extends ChangeNotifier {
  ChatSession({
    ChatSendGateway? sendGateway,
    this._photoPicker,
    this._attachmentPicker,
    this._voiceRecorder,
    this._attachmentPlayback,
  }) : _gateway = null,
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
      'shop-assist': [
        const ChatMessage(
          id: 'shop-assist-1',
          sender: 'MoolSocial Assist',
          text:
              'Choose an order question below or write what you need help with.',
          timeLabel: 'Now',
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
      'work-opportunity': [
        const ChatMessage(
          id: 'work-opportunity-1',
          sender: 'MoolSocial Work',
          text:
              'Ask about eligibility, timing or the next step for an opportunity.',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
      'work-support': [
        const ChatMessage(
          id: 'work-support-1',
          sender: 'MoolSocial Work Support',
          text:
              'Tell us which opportunity or workspace step you need help with.',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
      'pay-support': [
        const ChatMessage(
          id: 'pay-support-1',
          sender: 'MoolSocial Pay Support',
          text: 'Tell us which payment, request or receipt you need help with.',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
      'retailer-order-ms-2841': [
        const ChatMessage(
          id: 'retailer-order-ms-2841-1',
          sender: 'Amit Sharma',
          text: 'Please message me here if the delivery time changes.',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
      'retailer-order-ms-2840': [
        const ChatMessage(
          id: 'retailer-order-ms-2840-1',
          sender: 'Neha Jain',
          text: 'Thank you. The delivered order is complete.',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
      'food-restaurant-spice-darbar': [
        const ChatMessage(
          id: 'food-restaurant-spice-darbar-1',
          sender: 'Spice Darbar',
          text: 'Your table and food questions can continue here.',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
      'food-restaurant-taj-jodhpur': [
        const ChatMessage(
          id: 'food-restaurant-taj-jodhpur-1',
          sender: 'Taj Jodhpur',
          text: 'Ask about your table booking or dining visit here.',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
      'food-restaurant-blue-lime': [
        const ChatMessage(
          id: 'food-restaurant-blue-lime-1',
          sender: 'Blue Lime Cafe',
          text: 'Ask about your table or cafe order here.',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
      'food-restaurant-raas-rooftop': [
        const ChatMessage(
          id: 'food-restaurant-raas-rooftop-1',
          sender: 'Raas Rooftop',
          text: 'Ask about your booking or arrival details here.',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
      'ride-captain': [
        const ChatMessage(
          id: 'ride-captain-1',
          sender: 'Arjun Singh',
          text: 'I’m on the way. Message me here about the pickup point.',
          timeLabel: 'Now',
          mine: false,
        ),
      ],
    });
  }

  ChatSession.production({
    ChatGateway? gateway,
    ChatPhotoPicker? photoPicker,
    ChatAttachmentPicker? attachmentPicker,
    ChatVoiceRecorder? voiceRecorder,
    ChatAttachmentPlayback? attachmentPlayback,
  }) : _gateway = gateway ?? buildChatGateway(),
       _reviewSendGateway = null,
       _photoPicker = photoPicker ?? NativeChatPhotoPicker(),
       _attachmentPicker = attachmentPicker ?? NativeChatAttachmentPicker(),
       _voiceRecorder = voiceRecorder ?? NativeChatVoiceRecorder(),
       _attachmentPlayback =
           attachmentPlayback ?? NativeChatAttachmentPlayback();

  final ChatGateway? _gateway;
  final ChatSendGateway? _reviewSendGateway;
  final ChatPhotoPicker? _photoPicker;
  final ChatAttachmentPicker? _attachmentPicker;
  final ChatVoiceRecorder? _voiceRecorder;
  final ChatAttachmentPlayback? _attachmentPlayback;
  final List<ChatThread> _threads = [];
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, String> _messageLoadErrors = {};
  final Map<String, String> _threadActionErrors = {};
  final Map<String, String> _threadActionNotices = {};
  final Map<String, Set<String>> _hiddenMessageIdsByThread = {};
  final Map<String, String> _draftTextByThread = {};
  final Set<String> _readThreads = {};
  final Set<String> _markedUnreadThreads = {};
  final Set<String> _pinnedThreadIds = {};
  final Set<String> _reducedAttentionThreadIds = {};
  final Set<String> _archivedThreadIds = {};
  final Map<String, String> _retryKeys = {};
  final Map<String, String> _forwardRetryKeys = {};
  final Map<String, ChatMessage> _replyTargets = {};
  final Map<String, _PendingChatPhoto> _pendingPhotos = {};
  final Map<String, _PendingChatAttachment> _pendingAttachments = {};
  final Set<String> _recordingThreads = {};
  final Map<String, bool> _chatAvailableForSession = {};
  final Map<String, bool> _voiceCallsAvailableForSession = {};
  final Map<String, bool> _videoCallsAvailableForSession = {};
  final Map<String, bool> _reviewBeforeSendingForSession = {};
  bool _globalChatAvailableForSession = true;
  bool _globalVoiceCallsAvailableForSession = true;
  bool _globalVideoCallsAvailableForSession = true;
  bool _globalReviewBeforeSendingForSession = false;
  bool _hideMessagePreviewsForSession = false;
  bool _showSuggestedPromptsForSession = true;
  ChatPrivacySettings _privacySettings = ChatPrivacySettings.defaults;
  final List<ChatBlockedAccount> _blockedAccounts = [];
  final List<ChatMessageRequest> _messageRequests = [];
  bool privacyLoading = false;
  bool privacyLoaded = false;
  String? privacyError;
  ChatCallPreferences _callPreferences = ChatCallPreferences.defaults;
  final List<ChatCall> _incomingCalls = [];
  ChatCall? _activeCall;
  bool callLoading = false;
  bool callPreferencesLoaded = false;
  String? callError;
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
      id: 'shop-assist',
      title: 'MoolSocial Assist',
      subtitle: 'Shop order help',
      preview: 'Choose an order question to continue.',
      timeLabel: 'Now',
      type: ChatThreadType.support,
      verified: true,
      suggestedPrompts: [
        'Where is my order?',
        'Cancel or change order',
        'Change delivery',
        'Problem with an item',
      ],
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
      groupDescription: 'Plan household shopping together.',
      participants: [
        ChatParticipant(
          id: 'current-user',
          name: 'You',
          subtitle: 'Group member',
          isMe: true,
        ),
        ChatParticipant(id: 'amit', name: 'Amit', subtitle: 'Group member'),
        ChatParticipant(id: 'rakesh', name: 'Rakesh', subtitle: 'Group member'),
        ChatParticipant(id: 'neha', name: 'Neha', subtitle: 'Group member'),
        ChatParticipant(id: 'priya', name: 'Priya', subtitle: 'Group member'),
      ],
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
    ChatThread(
      id: 'work-opportunity',
      title: 'MoolSocial Work',
      subtitle: 'Opportunity support',
      preview: 'Ask about eligibility, timing or next steps.',
      timeLabel: 'Now',
      type: ChatThreadType.business,
      verified: true,
    ),
    ChatThread(
      id: 'work-support',
      title: 'MoolSocial Work Support',
      subtitle: 'Opportunities and workspace help',
      preview: 'Get help with an opportunity or workspace step.',
      timeLabel: 'Now',
      type: ChatThreadType.support,
      verified: true,
    ),
    ChatThread(
      id: 'pay-support',
      title: 'MoolSocial Pay Support',
      subtitle: 'Payments and receipts',
      preview: 'Get help with a payment, request or receipt.',
      timeLabel: 'Now',
      type: ChatThreadType.support,
      verified: true,
    ),
    ChatThread(
      id: 'retailer-order-ms-2841',
      title: 'Amit Sharma',
      subtitle: 'Order MS-2841',
      preview: 'Message here if the delivery time changes.',
      timeLabel: 'Now',
      type: ChatThreadType.people,
    ),
    ChatThread(
      id: 'retailer-order-ms-2840',
      title: 'Neha Jain',
      subtitle: 'Order MS-2840',
      preview: 'The delivered order is complete.',
      timeLabel: 'Now',
      type: ChatThreadType.people,
    ),
    ChatThread(
      id: 'food-restaurant-spice-darbar',
      title: 'Spice Darbar',
      subtitle: 'Table bookings and food orders',
      preview: 'Continue your table or food questions here.',
      timeLabel: 'Now',
      type: ChatThreadType.business,
      verified: true,
    ),
    ChatThread(
      id: 'food-restaurant-taj-jodhpur',
      title: 'Taj Jodhpur',
      subtitle: 'Table bookings and dining',
      preview: 'Ask about your table booking or visit.',
      timeLabel: 'Now',
      type: ChatThreadType.business,
      verified: true,
    ),
    ChatThread(
      id: 'food-restaurant-blue-lime',
      title: 'Blue Lime Cafe',
      subtitle: 'Table bookings and cafe orders',
      preview: 'Ask about your table or cafe order.',
      timeLabel: 'Now',
      type: ChatThreadType.business,
      verified: true,
    ),
    ChatThread(
      id: 'food-restaurant-raas-rooftop',
      title: 'Raas Rooftop',
      subtitle: 'Table bookings and arrival',
      preview: 'Ask about your booking or arrival details.',
      timeLabel: 'Now',
      type: ChatThreadType.business,
      verified: true,
    ),
    ChatThread(
      id: 'ride-captain',
      title: 'Arjun Singh',
      subtitle: 'Your verified captain',
      preview: 'Message about the pickup point.',
      timeLabel: 'Now',
      type: ChatThreadType.people,
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
    final matches = _threads
        .where((thread) {
          final filterMatches =
              selectedFilter == null || thread.type == selectedFilter;
          final unreadMatches = !unreadOnly || unreadFor(thread) > 0;
          final queryMatches =
              normalized.isEmpty ||
              thread.title.toLowerCase().contains(normalized) ||
              thread.subtitle.toLowerCase().contains(normalized) ||
              thread.preview.toLowerCase().contains(normalized);
          return !_archivedThreadIds.contains(thread.id) &&
              filterMatches &&
              unreadMatches &&
              queryMatches;
        })
        .toList(growable: false);
    return [
      ...matches.where((thread) => _pinnedThreadIds.contains(thread.id)),
      ...matches.where((thread) => !_pinnedThreadIds.contains(thread.id)),
    ];
  }

  List<ChatThread> archivedThreads([String query = '']) {
    final normalized = query.trim().toLowerCase();
    return _threads
        .where((thread) {
          final queryMatches =
              normalized.isEmpty ||
              thread.title.toLowerCase().contains(normalized) ||
              thread.subtitle.toLowerCase().contains(normalized) ||
              thread.preview.toLowerCase().contains(normalized);
          return _archivedThreadIds.contains(thread.id) && queryMatches;
        })
        .toList(growable: false);
  }

  bool isPinnedForSession(String threadId) =>
      _pinnedThreadIds.contains(threadId);

  bool hasReducedAttentionForSession(String threadId) =>
      _reducedAttentionThreadIds.contains(threadId);

  bool isArchivedForSession(String threadId) =>
      _archivedThreadIds.contains(threadId);

  int get archivedConversationCount => _archivedThreadIds.length;

  void setPinnedForSession(String threadId, {required bool pinned}) {
    final changed = pinned
        ? _pinnedThreadIds.add(threadId)
        : _pinnedThreadIds.remove(threadId);
    if (changed) notifyListeners();
  }

  void setReducedAttentionForSession(String threadId, {required bool reduced}) {
    final changed = reduced
        ? _reducedAttentionThreadIds.add(threadId)
        : _reducedAttentionThreadIds.remove(threadId);
    if (changed) notifyListeners();
  }

  void setArchivedForSession(String threadId, {required bool archived}) {
    final changed = archived
        ? _archivedThreadIds.add(threadId)
        : _archivedThreadIds.remove(threadId);
    if (!changed) return;
    notifyListeners();
  }

  void setReadForSession(String threadId, {required bool read}) {
    final changed = read
        ? _readThreads.add(threadId) | _markedUnreadThreads.remove(threadId)
        : _markedUnreadThreads.add(threadId) | _readThreads.remove(threadId);
    if (changed) notifyListeners();
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
    final hiddenIds = _hiddenMessageIdsByThread[threadId];
    final values = _messages[threadId] ?? const [];
    if (hiddenIds == null || hiddenIds.isEmpty) {
      return List.unmodifiable(values);
    }
    return List.unmodifiable(
      values.where((message) => !hiddenIds.contains(message.id)),
    );
  }

  bool isMessageHiddenForSession(String threadId, String messageId) =>
      _hiddenMessageIdsByThread[threadId]?.contains(messageId) ?? false;

  void setMessageHiddenForSession(
    String threadId,
    String messageId, {
    required bool hidden,
  }) {
    final hiddenIds = _hiddenMessageIdsByThread.putIfAbsent(
      threadId,
      () => <String>{},
    );
    final changed = hidden
        ? hiddenIds.add(messageId)
        : hiddenIds.remove(messageId);
    if (hiddenIds.isEmpty) _hiddenMessageIdsByThread.remove(threadId);
    if (changed) notifyListeners();
  }

  String? messageLoadError(String threadId) => _messageLoadErrors[threadId];

  String? threadActionError(String threadId) => _threadActionErrors[threadId];

  String? threadActionNotice(String threadId) => _threadActionNotices[threadId];

  ChatMessage? replyTarget(String threadId) => _replyTargets[threadId];

  String draftTextForSession(String threadId) =>
      _draftTextByThread[threadId] ?? '';

  bool hasDraftForSession(String threadId) =>
      draftTextForSession(threadId).trim().isNotEmpty ||
      replyTarget(threadId) != null ||
      selectedPhoto(threadId) != null;

  String? draftSummaryForSession(String threadId) {
    final text = draftTextForSession(threadId).trim();
    if (text.isNotEmpty) {
      return text.replaceAll(RegExp(r'\s+'), ' ');
    }
    if (selectedPhoto(threadId) != null) return 'Photo ready to send';
    if (selectedAttachment(threadId) case final attachment?) {
      return attachment.kind == ChatAttachmentKind.voice
          ? 'Voice message ready to send'
          : '${attachment.kind == ChatAttachmentKind.video ? 'Video' : 'Document'} ready to send';
    }
    if (replyTarget(threadId) != null) return 'Reply ready to send';
    return null;
  }

  void setDraftTextForSession(String threadId, String value) {
    final changed = value.isEmpty
        ? _draftTextByThread.remove(threadId) != null
        : _draftTextByThread[threadId] != value;
    if (value.isNotEmpty) {
      _draftTextByThread[threadId] = value;
    }
    if (changed) notifyListeners();
  }

  void discardDraftForSession(String threadId) {
    final hadText = _draftTextByThread.remove(threadId) != null;
    final hadReply = _replyTargets.remove(threadId) != null;
    final hadPhoto = _pendingPhotos.remove(threadId) != null;
    final hadAttachment = _pendingAttachments.remove(threadId) != null;
    final changed = hadText || hadReply || hadPhoto || hadAttachment;
    if (changed) notifyListeners();
  }

  bool get globalChatAvailableForSession => _globalChatAvailableForSession;

  bool get globalVoiceCallsAvailableForSession =>
      _globalVoiceCallsAvailableForSession;

  bool get globalVideoCallsAvailableForSession =>
      _globalVideoCallsAvailableForSession;

  bool get globalReviewBeforeSendingForSession =>
      _globalReviewBeforeSendingForSession;

  bool get hideMessagePreviewsForSession => _hideMessagePreviewsForSession;

  bool get showSuggestedPromptsForSession => _showSuggestedPromptsForSession;

  ChatPickedAttachment? selectedAttachment(String threadId) =>
      _pendingAttachments[threadId]?.attachment;

  bool get attachmentSelectionAvailable => _attachmentPicker != null;
  bool get voiceRecordingAvailable => _voiceRecorder != null;

  bool isRecordingVoice(String threadId) =>
      _recordingThreads.contains(threadId);

  Future<bool> selectAttachment(
    String threadId,
    ChatAttachmentKind kind,
  ) async {
    final picker = _attachmentPicker;
    if (busy || picker == null || kind == ChatAttachmentKind.voice) {
      _threadActionErrors[threadId] =
          'Attachment selection is unavailable right now.';
      notifyListeners();
      return false;
    }
    busy = true;
    _threadActionErrors.remove(threadId);
    notifyListeners();
    try {
      final picked = await picker.pick(kind);
      if (picked == null) return false;
      _pendingAttachments[threadId] = _PendingChatAttachment(
        attachment: picked,
        idempotencyKey:
            'chat-attachment-${DateTime.now().microsecondsSinceEpoch}-${++_messageSequence}',
      );
      _pendingPhotos.remove(threadId);
      _threadActionNotices[threadId] =
          '${kind == ChatAttachmentKind.video ? 'Video' : 'Document'} ready to send.';
      return true;
    } on ChatServiceException catch (error) {
      _threadActionErrors[threadId] = error.userMessage;
      return false;
    } on Object {
      _threadActionErrors[threadId] = 'That attachment could not be opened.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> startVoiceRecording(String threadId) async {
    final recorder = _voiceRecorder;
    if (busy || recorder == null || _recordingThreads.isNotEmpty) {
      _threadActionErrors[threadId] =
          'Voice recording is unavailable right now.';
      notifyListeners();
      return false;
    }
    try {
      await recorder.start();
      _recordingThreads.add(threadId);
      _threadActionErrors.remove(threadId);
      _threadActionNotices[threadId] = 'Recording voice message…';
      notifyListeners();
      return true;
    } on ChatServiceException catch (error) {
      _threadActionErrors[threadId] = error.userMessage;
      notifyListeners();
      return false;
    } on Object {
      _threadActionErrors[threadId] = 'Voice recording could not start.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> stopVoiceRecording(String threadId) async {
    final recorder = _voiceRecorder;
    if (recorder == null || !_recordingThreads.contains(threadId)) return false;
    busy = true;
    notifyListeners();
    try {
      final picked = await recorder.stop();
      _pendingAttachments[threadId] = _PendingChatAttachment(
        attachment: picked,
        idempotencyKey:
            'chat-voice-${DateTime.now().microsecondsSinceEpoch}-${++_messageSequence}',
      );
      _pendingPhotos.remove(threadId);
      _threadActionNotices[threadId] = 'Voice message ready to send.';
      return true;
    } on ChatServiceException catch (error) {
      _threadActionErrors[threadId] = error.userMessage;
      return false;
    } on Object {
      _threadActionErrors[threadId] = 'Voice recording could not be completed.';
      return false;
    } finally {
      _recordingThreads.remove(threadId);
      busy = false;
      notifyListeners();
    }
  }

  Future<void> cancelVoiceRecording(String threadId) async {
    if (!_recordingThreads.remove(threadId)) return;
    await _voiceRecorder?.cancel();
    _threadActionNotices.remove(threadId);
    notifyListeners();
  }

  void cancelSelectedAttachment(String threadId) {
    if (_pendingAttachments.remove(threadId) != null) notifyListeners();
  }

  Future<bool> sendSelectedAttachment(String threadId, String caption) async {
    if (busy) return false;
    final pending = _pendingAttachments[threadId];
    final gateway = _gateway is ChatAttachmentGateway
        ? _gateway as ChatAttachmentGateway
        : null;
    if (pending == null || gateway == null) {
      _threadActionErrors[threadId] = 'Choose an attachment first.';
      notifyListeners();
      return false;
    }
    if (!pending.sendLocked) {
      pending
        ..caption = caption.trim()
        ..replyTo = _replyReference(_replyTargets[threadId])
        ..sendLocked = true;
    }
    busy = true;
    _threadActionErrors.remove(threadId);
    notifyListeners();
    try {
      final delivered = await gateway.sendAttachment(
        threadId: threadId,
        attachment: pending.attachment,
        caption: pending.caption,
        idempotencyKey: pending.idempotencyKey,
        replyToMessageId: pending.replyTo?.messageId,
      );
      if (delivered.attachment == null) {
        throw const ChatServiceException(
          'Chat returned an invalid attachment. Try again.',
        );
      }
      _messages.putIfAbsent(threadId, () => []).add(delivered);
      _pendingAttachments.remove(threadId);
      if (_replyTargets[threadId]?.id == pending.replyTo?.messageId) {
        _replyTargets.remove(threadId);
      }
      _threadActionNotices[threadId] =
          '${pending.attachment.kind == ChatAttachmentKind.voice ? 'Voice message' : 'Attachment'} delivered.';
      return true;
    } on ChatServiceException catch (error) {
      _threadActionErrors[threadId] = error.userMessage;
      return false;
    } on Object {
      _threadActionErrors[threadId] =
          'Attachment was not sent. Check your connection and retry.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> openAttachment(
    String threadId,
    ChatAttachment attachment,
  ) async {
    final playback = _attachmentPlayback;
    if (playback == null) return false;
    try {
      await playback.open(attachment);
      return true;
    } on ChatServiceException catch (error) {
      _threadActionErrors[threadId] = error.userMessage;
      notifyListeners();
      return false;
    } on Object {
      _threadActionErrors[threadId] = 'That attachment could not be opened.';
      notifyListeners();
      return false;
    }
  }

  ChatPrivacySettings get privacySettings => _privacySettings;

  List<ChatBlockedAccount> get blockedAccounts =>
      List.unmodifiable(_blockedAccounts);

  List<ChatMessageRequest> get messageRequests =>
      List.unmodifiable(_messageRequests);

  ChatPrivacyGateway? get _privacyGateway =>
      _gateway is ChatPrivacyGateway ? _gateway as ChatPrivacyGateway : null;

  Future<bool> loadPrivacySettings({bool refresh = false}) async {
    if (privacyLoading || (privacyLoaded && !refresh)) return privacyLoaded;
    final gateway = _privacyGateway;
    if (gateway == null) {
      privacyLoaded = _gateway == null;
      if (!privacyLoaded) {
        privacyError = 'Privacy settings are unavailable right now.';
        notifyListeners();
      }
      return privacyLoaded;
    }
    privacyLoading = true;
    privacyError = null;
    notifyListeners();
    try {
      _privacySettings = await gateway.getPrivacySettings();
      privacyLoaded = true;
      return true;
    } on ChatServiceException catch (error) {
      privacyError = error.userMessage;
      return false;
    } on Object {
      privacyError = 'Privacy settings could not load. Try again.';
      return false;
    } finally {
      privacyLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePrivacySettings(ChatPrivacySettings requested) async {
    if (privacyLoading) return false;
    final previous = _privacySettings;
    final gateway = _privacyGateway;
    if (gateway == null && _gateway == null) {
      _privacySettings = requested;
      privacyLoaded = true;
      notifyListeners();
      return true;
    }
    if (gateway == null) {
      privacyError = 'Privacy settings are unavailable right now.';
      notifyListeners();
      return false;
    }
    privacyLoading = true;
    privacyError = null;
    notifyListeners();
    try {
      _privacySettings = await gateway.updatePrivacySettings(requested);
      privacyLoaded = true;
      return true;
    } on ChatServiceException catch (error) {
      _privacySettings = previous;
      privacyError = error.userMessage;
      return false;
    } on Object {
      _privacySettings = previous;
      privacyError = 'Privacy settings could not update. Nothing changed.';
      return false;
    } finally {
      privacyLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadBlockedAccounts() async {
    final gateway = _privacyGateway;
    if (gateway == null || privacyLoading) return false;
    privacyLoading = true;
    privacyError = null;
    notifyListeners();
    try {
      _blockedAccounts
        ..clear()
        ..addAll(await gateway.listBlockedAccounts());
      return true;
    } on ChatServiceException catch (error) {
      privacyError = error.userMessage;
      return false;
    } on Object {
      privacyError = 'Blocked accounts could not load. Try again.';
      return false;
    } finally {
      privacyLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setBlockedAccount(
    String targetUserId, {
    required bool blocked,
  }) async {
    final gateway = _privacyGateway;
    if (gateway == null || privacyLoading) {
      privacyError = 'Blocking is unavailable right now. Nothing changed.';
      notifyListeners();
      return false;
    }
    privacyLoading = true;
    privacyError = null;
    notifyListeners();
    try {
      final saved = await gateway.setBlockedAccount(
        targetUserId: targetUserId,
        blocked: blocked,
      );
      if (saved != blocked) {
        throw const ChatServiceException(
          'Blocking returned an invalid result. Nothing changed.',
        );
      }
      if (!blocked) {
        _blockedAccounts.removeWhere((item) => item.userId == targetUserId);
      }
      return true;
    } on ChatServiceException catch (error) {
      privacyError = error.userMessage;
      return false;
    } on Object {
      privacyError = 'Blocking could not update. Nothing changed.';
      return false;
    } finally {
      privacyLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadMessageRequests() async {
    final gateway = _privacyGateway;
    if (gateway == null || privacyLoading) return false;
    privacyLoading = true;
    privacyError = null;
    notifyListeners();
    try {
      _messageRequests
        ..clear()
        ..addAll(await gateway.listMessageRequests());
      return true;
    } on ChatServiceException catch (error) {
      privacyError = error.userMessage;
      return false;
    } on Object {
      privacyError = 'Message requests could not load. Try again.';
      return false;
    } finally {
      privacyLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resolveMessageRequest(
    String threadId, {
    required bool accepted,
  }) async {
    final gateway = _privacyGateway;
    if (gateway == null || privacyLoading) return false;
    privacyLoading = true;
    privacyError = null;
    notifyListeners();
    try {
      final saved = await gateway.resolveMessageRequest(
        threadId: threadId,
        accepted: accepted,
      );
      if (saved != accepted) {
        throw const ChatServiceException(
          'Message request returned an invalid result. Nothing changed.',
        );
      }
      final index = _messageRequests.indexWhere(
        (request) => request.thread.id == threadId,
      );
      if (index >= 0) {
        final request = _messageRequests.removeAt(index);
        if (accepted && !_threads.any((thread) => thread.id == threadId)) {
          _threads.insert(0, request.thread);
        }
      }
      return true;
    } on ChatServiceException catch (error) {
      privacyError = error.userMessage;
      return false;
    } on Object {
      privacyError = 'Message request could not update. Nothing changed.';
      return false;
    } finally {
      privacyLoading = false;
      notifyListeners();
    }
  }

  ChatCallPreferences get callPreferences => _callPreferences;

  ChatCall? get activeCall => _activeCall;

  List<ChatCall> get incomingCalls => List.unmodifiable(_incomingCalls);

  ChatCallGateway? get _callGateway =>
      _gateway is ChatCallGateway ? _gateway as ChatCallGateway : null;

  Future<bool> loadCallPreferences({bool refresh = false}) async {
    if (callLoading || (callPreferencesLoaded && !refresh)) {
      return callPreferencesLoaded;
    }
    final gateway = _callGateway;
    if (gateway == null) {
      callPreferencesLoaded = _gateway == null;
      return callPreferencesLoaded;
    }
    callLoading = true;
    callError = null;
    notifyListeners();
    try {
      _callPreferences = await gateway.getCallPreferences();
      _globalVoiceCallsAvailableForSession = _callPreferences.voiceCallsEnabled;
      _globalVideoCallsAvailableForSession = _callPreferences.videoCallsEnabled;
      callPreferencesLoaded = true;
      return true;
    } on ChatServiceException catch (error) {
      callError = error.userMessage;
      return false;
    } on Object {
      callError = 'Call settings could not load. Try again.';
      return false;
    } finally {
      callLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCallPreferences(ChatCallPreferences requested) async {
    if (callLoading) return false;
    final gateway = _callGateway;
    if (gateway == null && _gateway == null) {
      _callPreferences = requested;
      _globalVoiceCallsAvailableForSession = requested.voiceCallsEnabled;
      _globalVideoCallsAvailableForSession = requested.videoCallsEnabled;
      callPreferencesLoaded = true;
      notifyListeners();
      return true;
    }
    if (gateway == null) {
      callError = 'Call settings are unavailable right now.';
      notifyListeners();
      return false;
    }
    final previous = _callPreferences;
    callLoading = true;
    callError = null;
    notifyListeners();
    try {
      _callPreferences = await gateway.updateCallPreferences(requested);
      _globalVoiceCallsAvailableForSession = _callPreferences.voiceCallsEnabled;
      _globalVideoCallsAvailableForSession = _callPreferences.videoCallsEnabled;
      callPreferencesLoaded = true;
      return true;
    } on ChatServiceException catch (error) {
      _callPreferences = previous;
      callError = error.userMessage;
      return false;
    } on Object {
      _callPreferences = previous;
      callError = 'Call settings could not update. Nothing changed.';
      return false;
    } finally {
      callLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePresence(ChatPresenceState state) async {
    final gateway = _callGateway;
    if (gateway == null) return;
    try {
      await gateway.setPresence(state);
    } on Object {
      // Presence is best-effort. Call actions recheck authoritative state.
    }
  }

  Future<ChatCallAvailability?> callAvailability(
    String threadId,
    ChatCallKind kind,
  ) async {
    final gateway = _callGateway;
    if (gateway == null) return null;
    try {
      return await gateway.getCallAvailability(threadId: threadId, kind: kind);
    } on ChatServiceException catch (error) {
      callError = error.userMessage;
      notifyListeners();
      return null;
    } on Object {
      callError = 'Call availability could not be checked. Try again.';
      notifyListeners();
      return null;
    }
  }

  Future<ChatCall?> startCall(String threadId, ChatCallKind kind) async {
    if (callLoading) return null;
    final gateway = _callGateway;
    if (gateway == null) {
      callError =
          '${kind == ChatCallKind.voice ? 'Voice' : 'Video'} calling is unavailable right now.';
      notifyListeners();
      return null;
    }
    callLoading = true;
    callError = null;
    notifyListeners();
    try {
      final availability = await gateway.getCallAvailability(
        threadId: threadId,
        kind: kind,
      );
      if (!availability.canStart) {
        callError = availability.message;
        return null;
      }
      final call = await gateway.startCall(
        threadId: threadId,
        kind: kind,
        idempotencyKey:
            'chat-call-${DateTime.now().microsecondsSinceEpoch}-${++_messageSequence}',
      );
      _activeCall = call;
      return call;
    } on ChatServiceException catch (error) {
      callError = error.userMessage;
      return null;
    } on Object {
      callError = 'The call request could not start. Try again.';
      return null;
    } finally {
      callLoading = false;
      notifyListeners();
    }
  }

  Future<bool> endCall() async {
    final call = _activeCall;
    final gateway = _callGateway;
    if (call == null || gateway == null || callLoading) return false;
    callLoading = true;
    callError = null;
    notifyListeners();
    try {
      _activeCall = await gateway.endCall(callId: call.id);
      return true;
    } on ChatServiceException catch (error) {
      callError = error.userMessage;
      return false;
    } on Object {
      callError = 'The call could not end. Try again.';
      return false;
    } finally {
      callLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadIncomingCalls() async {
    final gateway = _callGateway;
    if (gateway == null || callLoading) return false;
    try {
      _incomingCalls
        ..clear()
        ..addAll(await gateway.listIncomingCalls());
      notifyListeners();
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> respondToCall(String callId, {required bool accepted}) async {
    final gateway = _callGateway;
    if (gateway == null || callLoading) return false;
    callLoading = true;
    callError = null;
    notifyListeners();
    try {
      final call = await gateway.respondToCall(
        callId: callId,
        accepted: accepted,
      );
      _incomingCalls.removeWhere((item) => item.id == callId);
      if (accepted) _activeCall = call;
      return true;
    } on ChatServiceException catch (error) {
      callError = error.userMessage;
      return false;
    } on Object {
      callError = 'The incoming call could not update. Nothing changed.';
      return false;
    } finally {
      callLoading = false;
      notifyListeners();
    }
  }

  bool chatAvailableForConversationInSession(String threadId) =>
      _chatAvailableForSession[threadId] ?? true;

  bool voiceCallsAvailableForConversationInSession(String threadId) =>
      _voiceCallsAvailableForSession[threadId] ?? true;

  bool videoCallsAvailableForConversationInSession(String threadId) =>
      _videoCallsAvailableForSession[threadId] ?? true;

  bool reviewBeforeSendingForConversationInSession(String threadId) =>
      _reviewBeforeSendingForSession[threadId] ?? false;

  bool chatAvailableForSession(String threadId) =>
      globalChatAvailableForSession &&
      chatAvailableForConversationInSession(threadId);

  bool voiceCallsAvailableForSession(String threadId) =>
      globalVoiceCallsAvailableForSession &&
      voiceCallsAvailableForConversationInSession(threadId);

  bool videoCallsAvailableForSession(String threadId) =>
      globalVideoCallsAvailableForSession &&
      videoCallsAvailableForConversationInSession(threadId);

  bool reviewBeforeSendingForSession(String threadId) =>
      globalReviewBeforeSendingForSession ||
      reviewBeforeSendingForConversationInSession(threadId);

  void setGlobalChatAvailableForSession({required bool available}) {
    if (globalChatAvailableForSession == available) return;
    _globalChatAvailableForSession = available;
    notifyListeners();
  }

  void setGlobalVoiceCallsAvailableForSession({required bool available}) {
    if (globalVoiceCallsAvailableForSession == available) return;
    _globalVoiceCallsAvailableForSession = available;
    notifyListeners();
  }

  void setGlobalVideoCallsAvailableForSession({required bool available}) {
    if (globalVideoCallsAvailableForSession == available) return;
    _globalVideoCallsAvailableForSession = available;
    notifyListeners();
  }

  void setGlobalReviewBeforeSendingForSession({required bool enabled}) {
    if (globalReviewBeforeSendingForSession == enabled) return;
    _globalReviewBeforeSendingForSession = enabled;
    notifyListeners();
  }

  void setHideMessagePreviewsForSession({required bool hidden}) {
    if (hideMessagePreviewsForSession == hidden) return;
    _hideMessagePreviewsForSession = hidden;
    notifyListeners();
  }

  void setShowSuggestedPromptsForSession({required bool visible}) {
    if (showSuggestedPromptsForSession == visible) return;
    _showSuggestedPromptsForSession = visible;
    notifyListeners();
  }

  void setChatAvailableForSession(String threadId, {required bool available}) {
    if (chatAvailableForConversationInSession(threadId) == available) return;
    _chatAvailableForSession[threadId] = available;
    notifyListeners();
  }

  void setVoiceCallsAvailableForSession(
    String threadId, {
    required bool available,
  }) {
    if (voiceCallsAvailableForConversationInSession(threadId) == available) {
      return;
    }
    _voiceCallsAvailableForSession[threadId] = available;
    notifyListeners();
  }

  void setVideoCallsAvailableForSession(
    String threadId, {
    required bool available,
  }) {
    if (videoCallsAvailableForConversationInSession(threadId) == available) {
      return;
    }
    _videoCallsAvailableForSession[threadId] = available;
    notifyListeners();
  }

  void setReviewBeforeSendingForSession(
    String threadId, {
    required bool enabled,
  }) {
    if (reviewBeforeSendingForConversationInSession(threadId) == enabled) {
      return;
    }
    _reviewBeforeSendingForSession[threadId] = enabled;
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
      _pendingAttachments.remove(threadId);
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
      _markedUnreadThreads.remove(threadId);
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
    if (_markedUnreadThreads.contains(thread.id)) {
      return thread.unreadCount > 0 ? thread.unreadCount : 1;
    }
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
    _hiddenMessageIdsByThread.clear();
    _draftTextByThread.clear();
    _readThreads.clear();
    _markedUnreadThreads.clear();
    _pinnedThreadIds.clear();
    _reducedAttentionThreadIds.clear();
    _archivedThreadIds.clear();
    _retryKeys.clear();
    _forwardRetryKeys.clear();
    _replyTargets.clear();
    _pendingPhotos.clear();
    _pendingAttachments.clear();
    _recordingThreads.clear();
    _chatAvailableForSession.clear();
    _voiceCallsAvailableForSession.clear();
    _videoCallsAvailableForSession.clear();
    _reviewBeforeSendingForSession.clear();
    _globalChatAvailableForSession = true;
    _globalVoiceCallsAvailableForSession = true;
    _globalVideoCallsAvailableForSession = true;
    _globalReviewBeforeSendingForSession = false;
    _hideMessagePreviewsForSession = false;
    _showSuggestedPromptsForSession = true;
    _privacySettings = ChatPrivacySettings.defaults;
    _blockedAccounts.clear();
    _messageRequests.clear();
    privacyLoading = false;
    privacyLoaded = false;
    privacyError = null;
    _callPreferences = ChatCallPreferences.defaults;
    _incomingCalls.clear();
    _activeCall = null;
    callLoading = false;
    callPreferencesLoaded = false;
    callError = null;
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
        : message.attachment != null
        ? message.attachment!.kind == ChatAttachmentKind.voice
              ? 'Voice message'
              : message.attachment!.name
        : message.attachmentLabel?.trim().isNotEmpty == true
        ? message.attachmentLabel!.trim()
        : 'Message';
    return ChatReplyReference(
      messageId: message.id,
      sender: message.sender,
      text: text,
    );
  }

  @override
  void dispose() {
    _voiceRecorder?.dispose();
    _attachmentPlayback?.dispose();
    super.dispose();
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

class _PendingChatAttachment {
  _PendingChatAttachment({
    required this.attachment,
    required this.idempotencyKey,
  });

  final ChatPickedAttachment attachment;
  final String idempotencyKey;
  String caption = '';
  ChatReplyReference? replyTo;
  bool sendLocked = false;
}
