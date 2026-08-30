import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/universal/mool_global_navigation_v2.dart';
import '../chat_entry_context.dart';
import '../chat_models.dart';
import '../chat_services.dart';
import '../chat_session.dart';
import '../widgets/chat_motion.dart';
import '../widgets/chat_widgets.dart';
import 'chat_conversation_search_screen.dart';
import 'chat_group_info_screen.dart';
import 'chat_settings_screen.dart';
import 'chat_shared_content_screen.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    required this.session,
    required this.threadId,
    required this.returnRoute,
    this.initialMessageDraft,
    this.returnDirectToOrigin = false,
    super.key,
  });

  final ChatSession session;
  final String threadId;
  final String returnRoute;
  final String? initialMessageDraft;
  final bool returnDirectToOrigin;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _messageController = TextEditingController();
  final _composerKey = GlobalKey<_ComposerState>();
  final _messageScrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  int _threadLoadRequest = 0;
  String? _highlightedMessageId;
  bool _applyingDraftText = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleDraftTextChanged);
    _restoreDraft(widget.threadId);
    _applyInitialDraftIfEmpty(widget.initialMessageDraft);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_recoverInterruptedPhoto(widget.threadId));
        unawaited(_loadThread(widget.threadId));
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatThreadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.session, widget.session) ||
        oldWidget.threadId != widget.threadId) {
      _restoreDraft(widget.threadId);
      if (_messageScrollController.hasClients) {
        _messageScrollController.jumpTo(0);
      }
      _messageKeys.clear();
      _highlightedMessageId = null;
      _applyInitialDraftIfEmpty(widget.initialMessageDraft);
      unawaited(_recoverInterruptedPhoto(widget.threadId));
      unawaited(_loadThread(widget.threadId));
    } else if (oldWidget.initialMessageDraft != widget.initialMessageDraft) {
      _applyInitialDraftIfEmpty(widget.initialMessageDraft);
    }
  }

  void _applyInitialDraftIfEmpty(String? initialDraft) {
    final draft = initialDraft?.trim();
    if (draft == null || draft.isEmpty || _messageController.text.isNotEmpty) {
      return;
    }
    _messageController.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
  }

  void _handleDraftTextChanged() {
    if (_applyingDraftText) return;
    widget.session.setDraftTextForSession(
      widget.threadId,
      _messageController.text,
    );
  }

  void _restoreDraft(String threadId) {
    final draft = widget.session.draftTextForSession(threadId);
    _applyingDraftText = true;
    try {
      _messageController.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
    } finally {
      _applyingDraftText = false;
    }
  }

  Future<void> _sendCurrentMessage() async {
    final session = widget.session;
    final threadId = widget.threadId;
    final draft = _messageController.text;
    if (!await _confirmSendReview(draft: draft, includesPhoto: false)) {
      return;
    }
    final sent = await session.send(threadId, draft);
    if (!sent || !identical(session, widget.session)) return;
    if (session.draftTextForSession(threadId) == draft) {
      session.setDraftTextForSession(threadId, '');
    }
    if (mounted &&
        threadId == widget.threadId &&
        _messageController.text == draft) {
      _messageController.clear();
    }
  }

  Future<void> _sendCurrentPhoto() async {
    final session = widget.session;
    final threadId = widget.threadId;
    final draft = _messageController.text;
    final selected = session.selectedPhoto(threadId);
    if (selected == null) return;
    if (!await _confirmSendReview(draft: draft, includesPhoto: true)) {
      return;
    }
    final sent = await session.sendSelectedPhoto(threadId, draft);
    if (!sent || !identical(session, widget.session)) return;
    if (session.draftTextForSession(threadId) == draft) {
      session.setDraftTextForSession(threadId, '');
    }
    if (mounted &&
        threadId == widget.threadId &&
        _messageController.text == draft) {
      _messageController.clear();
    }
  }

  Future<void> _sendCurrentAttachment() async {
    final session = widget.session;
    final threadId = widget.threadId;
    final draft = _messageController.text;
    final selected = session.selectedAttachment(threadId);
    if (selected == null) return;
    final label = switch (selected.kind) {
      ChatAttachmentKind.document => 'Document',
      ChatAttachmentKind.video => 'Video',
      ChatAttachmentKind.voice => 'Voice message',
    };
    if (!await _confirmSendReview(
      draft: draft,
      includesPhoto: false,
      attachmentLabel: label,
    )) {
      return;
    }
    final sent = await session.sendSelectedAttachment(threadId, draft);
    if (!sent || !identical(session, widget.session)) return;
    if (session.draftTextForSession(threadId) == draft) {
      session.setDraftTextForSession(threadId, '');
    }
    if (mounted &&
        threadId == widget.threadId &&
        _messageController.text == draft) {
      _messageController.clear();
    }
  }

  Future<void> _retryMessage(String messageId) async {
    final session = widget.session;
    final threadId = widget.threadId;
    final failed = session
        .messages(threadId)
        .where((message) => message.id == messageId);
    if (failed.isEmpty) return;
    final failedText = failed.single.text;
    final sent = await session.retry(threadId, messageId);
    if (!sent || !identical(session, widget.session)) return;
    if (mounted &&
        threadId == widget.threadId &&
        _messageController.text == failedText &&
        session.draftTextForSession(threadId) == failedText) {
      _messageController.clear();
      session.discardDraftForSession(threadId);
    }
  }

  Future<bool> _confirmSendReview({
    required String draft,
    required bool includesPhoto,
    String? attachmentLabel,
  }) async {
    final session = widget.session;
    final threadId = widget.threadId;
    if (!session.reviewBeforeSendingForSession(threadId)) return true;

    FocusManager.instance.primaryFocus?.unfocus();
    final thread = session.thread(threadId);
    final reply = session.replyTarget(threadId);
    final trimmedDraft = draft.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('chat-send-review-dialog'),
        title: const Text('Review before sending'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To ${thread.title}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (reply != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Replying to ${reply.sender}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: MoolColors.muted),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                key: const Key('chat-send-review-content'),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                ),
                child: Text(
                  switch ((
                    includesPhoto,
                    attachmentLabel,
                    trimmedDraft.isEmpty,
                  )) {
                    (_, String label, true) => label,
                    (_, String label, false) => '$label\n$trimmedDraft',
                    (true, _, true) => 'Photo',
                    (true, _, false) => 'Photo\n$trimmedDraft',
                    (false, _, _) => trimmedDraft,
                  },
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Nothing is sent until you choose Send now.',
                style: TextStyle(color: MoolColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('chat-send-review-edit'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            key: const Key('chat-send-review-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Send now'),
          ),
        ],
      ),
    );
    return confirmed == true &&
        mounted &&
        identical(session, widget.session) &&
        threadId == widget.threadId;
  }

  void _applySuggestedPrompt(String prompt) {
    final existing = _messageController.text.trim();
    final next = existing.isEmpty
        ? prompt
        : existing.contains(prompt)
        ? existing
        : '$existing\n$prompt';
    _messageController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _recoverInterruptedPhoto(String threadId) async {
    final session = widget.session;
    if (!session.photoSharingAvailable ||
        session.selectedPhoto(threadId) != null) {
      return;
    }
    await session.recoverInterruptedPhotoSelection(threadId);
  }

  Future<void> _loadThread(String threadId) async {
    final request = ++_threadLoadRequest;
    final session = widget.session;
    await session.loadThreads();
    if (!mounted ||
        request != _threadLoadRequest ||
        !identical(session, widget.session) ||
        threadId != widget.threadId) {
      return;
    }
    final loaded = await session.loadMessages(threadId, refresh: true);
    if (!mounted ||
        request != _threadLoadRequest ||
        !identical(session, widget.session) ||
        threadId != widget.threadId) {
      return;
    }
    if (loaded) await session.markRead(threadId);
  }

  Future<void> _openConversationInfo(
    ChatThread thread,
    ChatEntryContext entryContext,
  ) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => _ConversationInfoScreen(
          session: widget.session,
          thread: thread,
          entryContext: entryContext,
          originReturnRoute: widget.returnRoute,
        ),
      ),
    );
  }

  Future<void> _startCall(ChatThread thread, ChatCallKind kind) async {
    final available = kind == ChatCallKind.voice
        ? widget.session.voiceCallsAvailableForSession(thread.id)
        : widget.session.videoCallsAvailableForSession(thread.id);
    final recoveryKey = kind == ChatCallKind.voice
        ? 'chat-call-recovery'
        : 'chat-video-recovery';
    final label = kind == ChatCallKind.voice ? 'Voice' : 'Video';
    if (!available) {
      await showChatUnavailableCapability(
        context,
        keyName: recoveryKey,
        title: '$label calls paused',
        message:
            '$label calls are paused for this conversation until you turn them on in Conversation info.',
      );
      return;
    }
    final call = await widget.session.startCall(thread.id, kind);
    if (!mounted) return;
    if (call == null) {
      await showChatUnavailableCapability(
        context,
        keyName: recoveryKey,
        title: '$label calling unavailable',
        message:
            widget.session.callError ??
            '$label calling is not available right now. You can continue this conversation in Chat.',
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      sheetAnimationStyle: ChatMotion.sheetStyle(context),
      builder: (sheetContext) => Padding(
        key: const Key('chat-call-status'),
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              kind == ChatCallKind.voice
                  ? Icons.call_outlined
                  : Icons.videocam_outlined,
              size: 42,
              color: MoolColors.navy,
            ),
            const SizedBox(height: 10),
            Text(
              'Calling ${thread.title}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$label call request sent. Waiting for ${thread.title} to answer.',
              key: const Key('chat-call-status-message'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('chat-call-end'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
              ),
              onPressed: () async {
                final ended = await widget.session.endCall();
                if (ended && sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
              },
              icon: const Icon(Icons.call_end_rounded),
              label: const Text('End call'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChatSettings() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatSettingsScreen(
          session: widget.session,
          originReturnRoute: widget.returnRoute,
        ),
      ),
    );
  }

  Future<void> _openMessageSearch() async {
    final messageId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ChatConversationSearchScreen(
          session: widget.session,
          threadId: widget.threadId,
          originReturnRoute: widget.returnRoute,
        ),
      ),
    );
    if (messageId == null || !mounted) return;
    await _revealMessage(messageId);
  }

  Future<void> _revealMessage(String messageId) async {
    setState(() => _highlightedMessageId = messageId);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final directContext = _messageKeys[messageId]?.currentContext;
    final duration = ChatMotion.resolve(context, ChatMotion.routeChange);
    if (directContext != null && directContext.mounted) {
      await Scrollable.ensureVisible(
        directContext,
        alignment: .5,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final messages = widget.session.messages(widget.threadId);
    final index = messages.indexWhere((message) => message.id == messageId);
    if (index < 0 || !_messageScrollController.hasClients) return;
    final ratio = messages.length <= 1 ? 0.0 : index / (messages.length - 1);
    await _messageScrollController.animateTo(
      _messageScrollController.position.maxScrollExtent * ratio,
      duration: duration,
      curve: Curves.easeOutCubic,
    );
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final resultContext = _messageKeys[messageId]?.currentContext;
    if (resultContext != null && resultContext.mounted) {
      await Scrollable.ensureVisible(
        resultContext,
        alignment: .5,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _threadLoadRequest += 1;
    _messageScrollController.dispose();
    _messageController.removeListener(_handleDraftTextChanged);
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final thread = widget.session.thread(widget.threadId);
        final returnUri = Uri.tryParse(widget.returnRoute);
        final returnsToChatThread =
            returnUri?.pathSegments.length == 4 &&
            returnUri?.pathSegments[0] == 'app' &&
            returnUri?.pathSegments[1] == 'chat' &&
            returnUri?.pathSegments[2] == 'thread';
        final backRoute = widget.returnDirectToOrigin
            ? widget.returnRoute
            : returnsToChatThread
            ? widget.returnRoute
            : chatRoute('/app/chat/inbox', returnRoute: widget.returnRoute);
        final entryContext = ChatEntryContext.resolve(widget.returnRoute);
        return ChatPageScaffold(
          key: const Key('chat-thread-screen'),
          session: widget.session,
          title: thread.title,
          subtitle: thread.subtitle,
          returnRoute: backRoute,
          showContentBack: true,
          titleIcon: _threadIconFor(thread.type),
          titleAccent: entryContext.accent,
          onTitleTap: () =>
              unawaited(_openConversationInfo(thread, entryContext)),
          backgroundColor: const Color(0xFFF1F2F6),
          onBlockedPop: () =>
              _composerKey.currentState?.closeAttachmentsForBack() ?? false,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('chat-thread-search'),
                tooltip: 'Search messages',
                onPressed: () => unawaited(_openMessageSearch()),
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                key: const Key('chat-thread-video'),
                tooltip: widget.session.videoCallsAvailableForSession(thread.id)
                    ? 'Video call'
                    : 'Video calls paused',
                onPressed: () =>
                    unawaited(_startCall(thread, ChatCallKind.video)),
                icon: const Icon(Icons.videocam_outlined),
              ),
              IconButton(
                key: const Key('chat-thread-call'),
                tooltip: widget.session.voiceCallsAvailableForSession(thread.id)
                    ? 'Voice call'
                    : 'Voice calls paused',
                onPressed: () =>
                    unawaited(_startCall(thread, ChatCallKind.voice)),
                icon: const Icon(Icons.call_outlined),
              ),
            ],
          ),
          messageThreadId: thread.id,
          body:
              widget.session.loadingMessageThreads.contains(thread.id) &&
                  widget.session.messages(thread.id).isEmpty
              ? const ChatFiniteIncomingMotion(
                  stateKey: 'chat-thread-loading-state',
                  child: _ThreadLoadingState(),
                )
              : widget.session.messageLoadError(thread.id) != null &&
                    widget.session.messages(thread.id).isEmpty
              ? ChatFiniteIncomingMotion(
                  stateKey: 'chat-thread-error-state',
                  child: _ThreadErrorState(
                    message: widget.session.messageLoadError(thread.id)!,
                    onRetry: () =>
                        widget.session.loadMessages(thread.id, refresh: true),
                  ),
                )
              : _ThreadBody(
                  session: widget.session,
                  thread: thread,
                  scrollController: _messageScrollController,
                  messageKeys: _messageKeys,
                  highlightedMessageId: _highlightedMessageId,
                  onRetryMessage: _retryMessage,
                ),
          bottom: ChatFiniteIncomingMotion(
            stateKey: widget.session.chatAvailableForSession(thread.id)
                ? 'chat-composer-active'
                : 'chat-composer-paused',
            child: widget.session.chatAvailableForSession(thread.id)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (thread.suggestedPrompts.isNotEmpty &&
                          widget.session.showSuggestedPromptsForSession &&
                          MediaQuery.viewInsetsOf(context).bottom == 0)
                        _SuggestedPromptStrip(
                          values: thread.suggestedPrompts,
                          onSelected: _applySuggestedPrompt,
                        ),
                      _Composer(
                        key: _composerKey,
                        session: widget.session,
                        threadId: thread.id,
                        controller: _messageController,
                        onSend: _sendCurrentMessage,
                        onSendPhoto: _sendCurrentPhoto,
                        onSendAttachment: _sendCurrentAttachment,
                      ),
                    ],
                  )
                : _ChatPausedBar(
                    globallyPaused:
                        !widget.session.globalChatAvailableForSession,
                    onResume: () => widget.session.setChatAvailableForSession(
                      thread.id,
                      available: true,
                    ),
                    onOpenSettings: () => unawaited(_openChatSettings()),
                  ),
          ),
        );
      },
    );
  }
}

class _SuggestedPromptStrip extends StatelessWidget {
  const _SuggestedPromptStrip({required this.values, required this.onSelected});

  final List<String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('chat-suggested-prompts'),
      width: double.infinity,
      color: MoolColors.canvas,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (index, value) in values.indexed) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: ActionChip(
                  key: Key('chat-suggested-prompt-$index'),
                  label: Text(value),
                  onPressed: () => onSelected(value),
                ),
              ),
              if (index != values.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConversationInfoScreen extends StatefulWidget {
  const _ConversationInfoScreen({
    required this.session,
    required this.thread,
    required this.entryContext,
    required this.originReturnRoute,
  });

  final ChatSession session;
  final ChatThread thread;
  final ChatEntryContext entryContext;
  final String originReturnRoute;

  @override
  State<_ConversationInfoScreen> createState() =>
      _ConversationInfoScreenState();
}

class _ConversationInfoScreenState extends State<_ConversationInfoScreen> {
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.session.loadPrivacySettings());
    });
  }

  void _confirmLocalChange(String message) {
    setState(() => _statusMessage = message);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar(reason: SnackBarClosedReason.remove)
      ..showSnackBar(
        SnackBar(
          key: const Key('chat-info-local-feedback'),
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  void _showSafetyRecovery(ChatThread thread) {
    final copy = _conversationSafetyCopy(thread);
    unawaited(
      showChatUnavailableCapability(
        context,
        keyName: copy.recoveryKey,
        title: copy.recoveryTitle,
        message: copy.recoveryMessage,
      ),
    );
  }

  Future<void> _savePrivacyChoice(
    ChatPrivacySettings requested,
    String success,
  ) async {
    final saved = await widget.session.updatePrivacySettings(requested);
    if (!mounted) return;
    if (saved) {
      _confirmLocalChange(success);
      return;
    }
    await showChatUnavailableCapability(
      context,
      keyName: 'chat-info-privacy-recovery',
      title: 'Privacy setting unchanged',
      message:
          widget.session.privacyError ??
          'This account setting could not update. Nothing changed.',
    );
  }

  Future<void> _blockConversation(ChatThread thread) async {
    final targetUserId = thread.targetUserId;
    if (targetUserId == null) {
      _showSafetyRecovery(thread);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('chat-block-confirmation'),
        title: Text('Block ${thread.title}?'),
        content: const Text(
          'They will not be able to start or continue a direct conversation with you. You can unblock them later in Chat settings.',
        ),
        actions: [
          TextButton(
            key: const Key('chat-block-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('chat-block-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final blocked = await widget.session.setBlockedAccount(
      targetUserId,
      blocked: true,
    );
    if (!mounted) return;
    if (!blocked) {
      _showSafetyRecovery(thread);
      return;
    }
    widget.session.setChatAvailableForSession(thread.id, available: false);
    _confirmLocalChange('${thread.title} is blocked.');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final thread = widget.thread;
        final session = widget.session;
        final chatAvailable = session.chatAvailableForSession(thread.id);
        final globalChatAvailable = session.globalChatAvailableForSession;
        final globalVoiceAvailable =
            session.globalVoiceCallsAvailableForSession;
        final globalVideoAvailable =
            session.globalVideoCallsAvailableForSession;
        final globalSendReview = session.globalReviewBeforeSendingForSession;
        final safety = _conversationSafetyCopy(thread);
        return ChatPageScaffold(
          key: const Key('chat-conversation-info-screen'),
          session: session,
          title: 'Conversation info',
          subtitle: thread.title,
          returnRoute: '/app/chat/thread/${thread.id}',
          showContentBack: true,
          backKeyName: 'chat-conversation-info-back',
          titleIcon: Icons.manage_accounts_outlined,
          titleAccent: widget.entryContext.accent,
          showMessageBanner: false,
          backgroundColor: const Color(0xFFF4F5F8),
          body: ListView(
            key: const Key('chat-conversation-info-list'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _ConversationIdentityCard(
                thread: thread,
                chatAvailable: chatAvailable,
                globalChatAvailable: globalChatAvailable,
                accent: widget.entryContext.accent,
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                ChatFiniteIncomingMotion(
                  stateKey: _statusMessage!,
                  child: _ConversationStatusNotice(message: _statusMessage!),
                ),
              ],
              const SizedBox(height: 16),
              _ConversationSettingsSection(
                title: 'Across Chat',
                child: Column(
                  children: [
                    ListTile(
                      key: const Key('chat-info-open-global-settings'),
                      minLeadingWidth: 28,
                      leading: const Icon(Icons.tune_rounded),
                      title: const Text('Chat settings'),
                      subtitle: const Text(
                        'Manage messages, calls, peace of mind, privacy and spam controls.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatSettingsScreen(
                            session: session,
                            originReturnRoute: widget.originReturnRoute,
                          ),
                        ),
                      ),
                    ),
                    if (thread.isGroup) ...[
                      const Divider(height: 1),
                      ListTile(
                        key: const Key('chat-info-group-info'),
                        minLeadingWidth: 28,
                        leading: const Icon(Icons.groups_2_outlined),
                        title: const Text('Group info'),
                        subtitle: Text(
                          '${thread.participants.length} members and group controls.',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => ChatGroupInfoScreen(
                              session: session,
                              threadId: thread.id,
                              originReturnRoute: widget.originReturnRoute,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    ListTile(
                      key: const Key('chat-info-shared-content'),
                      minLeadingWidth: 28,
                      leading: const Icon(Icons.perm_media_outlined),
                      title: const Text('Media, files and links'),
                      subtitle: const Text(
                        'Browse content currently loaded in this conversation.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatSharedContentScreen(
                            session: session,
                            threadId: thread.id,
                            originReturnRoute: widget.originReturnRoute,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ConversationSettingsSection(
                title: 'Availability',
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      key: const Key('chat-info-chat-availability'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Chat in this app'),
                      subtitle: Text(
                        globalChatAvailable
                            ? 'Pause or resume the composer for this conversation.'
                            : 'Paused across Chat. Turn it on in Chat settings first.',
                      ),
                      value:
                          globalChatAvailable &&
                          session.chatAvailableForConversationInSession(
                            thread.id,
                          ),
                      onChanged: !globalChatAvailable
                          ? null
                          : (available) {
                              session.setChatAvailableForSession(
                                thread.id,
                                available: available,
                              );
                              _confirmLocalChange(
                                available
                                    ? 'Chat resumed for this app session.'
                                    : 'Chat paused for this app session.',
                              );
                            },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('chat-info-voice-availability'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Voice calls in this app'),
                      subtitle: Text(
                        globalVoiceAvailable
                            ? 'Control the voice-call action in this conversation.'
                            : 'Paused across Chat. Turn it on in Chat settings first.',
                      ),
                      value:
                          globalVoiceAvailable &&
                          session.voiceCallsAvailableForConversationInSession(
                            thread.id,
                          ),
                      onChanged: !globalVoiceAvailable
                          ? null
                          : (available) {
                              session.setVoiceCallsAvailableForSession(
                                thread.id,
                                available: available,
                              );
                              _confirmLocalChange(
                                available
                                    ? 'Voice calls turned on for this app session.'
                                    : 'Voice calls paused for this app session.',
                              );
                            },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('chat-info-video-availability'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Video calls in this app'),
                      subtitle: Text(
                        globalVideoAvailable
                            ? 'Control the video-call action in this conversation.'
                            : 'Paused across Chat. Turn it on in Chat settings first.',
                      ),
                      value:
                          globalVideoAvailable &&
                          session.videoCallsAvailableForConversationInSession(
                            thread.id,
                          ),
                      onChanged: !globalVideoAvailable
                          ? null
                          : (available) {
                              session.setVideoCallsAvailableForSession(
                                thread.id,
                                available: available,
                              );
                              _confirmLocalChange(
                                available
                                    ? 'Video calls turned on for this app session.'
                                    : 'Video calls paused for this app session.',
                              );
                            },
                    ),
                    const _ConversationScopeNote(
                      'These choices apply until you close MoolSocial. They do not change account permissions or another person’s settings.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ConversationSettingsSection(
                title: 'Conversation',
                child: ListTile(
                  key: const Key('chat-info-voice-chat'),
                  minLeadingWidth: 28,
                  leading: const Icon(Icons.graphic_eq_rounded),
                  title: const Text('Start a voice chat'),
                  subtitle: const Text(
                    'Talk live with this conversation when voice chat is available.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => unawaited(
                    showChatUnavailableCapability(
                      context,
                      keyName: 'chat-voice-chat-recovery',
                      title: 'Voice chat unavailable',
                      message:
                          'Voice chat is not available right now. You can continue with messages or try a voice call.',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ConversationSettingsSection(
                title: 'Wellbeing',
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      key: const Key('chat-info-review-before-send'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Review before sending'),
                      subtitle: Text(
                        globalSendReview
                            ? 'On across Chat. Change it in Chat settings.'
                            : 'Confirm messages and photos before they are sent.',
                      ),
                      value:
                          globalSendReview ||
                          session.reviewBeforeSendingForConversationInSession(
                            thread.id,
                          ),
                      onChanged: globalSendReview
                          ? null
                          : (enabled) {
                              session.setReviewBeforeSendingForSession(
                                thread.id,
                                enabled: enabled,
                              );
                              _confirmLocalChange(
                                enabled
                                    ? 'Send review turned on for this app session.'
                                    : 'Send review turned off for this app session.',
                              );
                            },
                    ),
                    const _ConversationScopeNote(
                      'This preference applies to this conversation until you close MoolSocial. It does not change another person’s settings.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ConversationSettingsSection(
                title: 'Privacy',
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      key: const Key('chat-info-last-seen'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Share last seen'),
                      subtitle: const Text(
                        'Let eligible people see when you last used Chat.',
                      ),
                      value: session.privacySettings.shareLastSeen,
                      onChanged: session.privacyLoading
                          ? null
                          : (enabled) => unawaited(
                              _savePrivacyChoice(
                                session.privacySettings.copyWith(
                                  shareLastSeen: enabled,
                                ),
                                enabled
                                    ? 'Last seen sharing turned on.'
                                    : 'Last seen sharing turned off.',
                              ),
                            ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('chat-info-read-receipts'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Read receipts'),
                      subtitle: const Text(
                        'Share and receive read status where permitted.',
                      ),
                      value: session.privacySettings.readReceipts,
                      onChanged: session.privacyLoading
                          ? null
                          : (enabled) => unawaited(
                              _savePrivacyChoice(
                                session.privacySettings.copyWith(
                                  readReceipts: enabled,
                                ),
                                enabled
                                    ? 'Read receipts turned on.'
                                    : 'Read receipts turned off.',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ConversationSettingsSection(
                title: 'Safety',
                child: ListTile(
                  key: const Key('chat-info-block-user'),
                  minLeadingWidth: 28,
                  leading: const Icon(Icons.block_outlined),
                  title: Text(safety.label),
                  subtitle: Text(safety.description),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => unawaited(_blockConversation(thread)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

({
  String label,
  String description,
  String recoveryKey,
  String recoveryTitle,
  String recoveryMessage,
})
_conversationSafetyCopy(
  ChatThread thread,
) => switch (thread.effectiveSafetyTarget) {
  ChatSafetyTarget.person => (
    label: 'Block this person',
    description: 'Nothing changes without confirmation.',
    recoveryKey: 'chat-block-user-recovery',
    recoveryTitle: 'Blocking unavailable',
    recoveryMessage:
        'Blocking cannot be completed right now. Nothing changed. You can continue in Chat or try again later.',
  ),
  ChatSafetyTarget.business => (
    label: 'Block this business',
    description: 'Nothing changes without confirmation.',
    recoveryKey: 'chat-block-business-recovery',
    recoveryTitle: 'Business blocking unavailable',
    recoveryMessage:
        'Business blocking cannot be completed right now. Nothing changed. You can continue in Chat or try again later.',
  ),
  ChatSafetyTarget.conversation => (
    label: 'Conversation safety',
    description: 'Report this conversation or ask MoolSocial for help.',
    recoveryKey: 'chat-conversation-safety-recovery',
    recoveryTitle: 'Conversation safety unavailable',
    recoveryMessage:
        'Safety and reporting controls are not available right now. Nothing changed. You can continue in Chat or try again later.',
  ),
};

class _ConversationIdentityCard extends StatelessWidget {
  const _ConversationIdentityCard({
    required this.thread,
    required this.chatAvailable,
    required this.globalChatAvailable,
    required this.accent,
  });

  final ChatThread thread;
  final bool chatAvailable;
  final bool globalChatAvailable;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('chat-conversation-status'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MoolColors.line.withValues(alpha: .7)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_threadIconFor(thread.type), color: accent, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  thread.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: chatAvailable
                            ? const Color(0xFF1C9B62)
                            : MoolColors.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        chatAvailable
                            ? 'Available in Chat'
                            : globalChatAvailable
                            ? 'Chat paused for this conversation'
                            : 'Chat paused in Chat settings',
                        style: const TextStyle(
                          color: MoolColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (thread.verified)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.verified_rounded, color: Color(0xFF1C73E8)),
            ),
        ],
      ),
    );
  }
}

class _ConversationSettingsSection extends StatelessWidget {
  const _ConversationSettingsSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
            ),
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }
}

class _ConversationScopeNote extends StatelessWidget {
  const _ConversationScopeNote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Text(
        message,
        style: const TextStyle(
          color: MoolColors.muted,
          fontSize: 11.5,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ConversationStatusNotice extends StatelessWidget {
  const _ConversationStatusNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('chat-info-local-status'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatPausedBar extends StatelessWidget {
  const _ChatPausedBar({
    required this.globallyPaused,
    required this.onResume,
    required this.onOpenSettings,
  });

  final bool globallyPaused;
  final VoidCallback onResume;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('chat-paused-bar'),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  globallyPaused
                      ? 'Chat is paused in Chat settings.'
                      : 'Chat is paused for this conversation.',
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: OutlinedButton(
                  key: Key(
                    globallyPaused
                        ? 'chat-open-settings-from-paused'
                        : 'chat-resume',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(96, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: globallyPaused ? onOpenSettings : onResume,
                  child: Text(globallyPaused ? 'Settings' : 'Resume'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadLoadingState extends StatelessWidget {
  const _ThreadLoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: MoolSpacing.sm),
        Text('Loading messages'),
      ],
    ),
  );
}

class _ThreadErrorState extends StatelessWidget {
  const _ThreadErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(MoolSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 44, color: MoolColors.muted),
          const SizedBox(height: MoolSpacing.sm),
          const Text(
            'Messages could not load',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: MoolSpacing.md),
          FilledButton.icon(
            key: const Key('chat-retry-messages'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class _ThreadBody extends StatelessWidget {
  const _ThreadBody({
    required this.session,
    required this.thread,
    required this.scrollController,
    required this.messageKeys,
    required this.highlightedMessageId,
    required this.onRetryMessage,
  });

  final ChatSession session;
  final ChatThread thread;
  final ScrollController scrollController;
  final Map<String, GlobalKey> messageKeys;
  final String? highlightedMessageId;
  final Future<void> Function(String messageId) onRetryMessage;

  @override
  Widget build(BuildContext context) {
    final messages = session.messages(thread.id);
    return ListView.builder(
      key: const Key('chat-message-list'),
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        112,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) => KeyedSubtree(
        key: messageKeys.putIfAbsent(messages[index].id, () => GlobalKey()),
        child: ChatListEntryMotion(
          key: ValueKey('chat-message-entry-motion-${messages[index].id}'),
          stateKey: messages[index].id,
          index: index,
          child: _MessageBubble(
            message: messages[index],
            threadId: thread.id,
            session: session,
            highlighted: messages[index].id == highlightedMessageId,
            onRetry: onRetryMessage,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.threadId,
    required this.session,
    required this.highlighted,
    required this.onRetry,
  });

  final ChatMessage message;
  final String threadId;
  final ChatSession session;
  final bool highlighted;
  final Future<void> Function(String messageId) onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = message.deliveryState == ChatDeliveryState.failed;
    final reply = message.replyTo;
    final photo = message.photo;
    final attachment = message.attachment;
    return Align(
      alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        key: Key('chat-message-${message.id}'),
        onLongPress: message.isSettled && !session.busy
            ? () => _showMessageActions(
                context,
                session: session,
                threadId: threadId,
                message: message,
              )
            : null,
        child: AnimatedContainer(
          key: Key('chat-message-highlight-${message.id}'),
          duration: ChatMotion.resolve(context, ChatMotion.focus),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(maxWidth: 330),
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: message.mine ? MoolColors.navy : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15),
              topRight: const Radius.circular(15),
              bottomLeft: Radius.circular(message.mine ? 15 : MoolSpacing.xs),
              bottomRight: Radius.circular(message.mine ? MoolSpacing.xs : 15),
            ),
            border: failed
                ? Border.all(color: const Color(0xFFD3322F))
                : highlighted
                ? Border.all(color: MoolColors.orange, width: 2)
                : null,
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: MoolColors.orange.withValues(alpha: .18),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.mine)
                Text(
                  message.sender,
                  style: const TextStyle(
                    color: MoolColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              if (message.forwarded) ...[
                const SizedBox(height: 3),
                Semantics(
                  label: 'Forwarded message',
                  child: Row(
                    key: Key('chat-forwarded-${message.id}'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.forward_rounded,
                        size: 14,
                        color: message.mine
                            ? Colors.white.withValues(alpha: .78)
                            : MoolColors.muted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Forwarded',
                        style: TextStyle(
                          color: message.mine
                              ? Colors.white.withValues(alpha: .78)
                              : MoolColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (reply != null) ...[
                const SizedBox(height: 3),
                Semantics(
                  label: 'Reply to ${reply.sender}: ${reply.text}',
                  child: Container(
                    key: Key('chat-reply-context-${message.id}'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(MoolSpacing.xs),
                    decoration: BoxDecoration(
                      color: message.mine
                          ? Colors.white.withValues(alpha: .12)
                          : const Color(0xFFF0F1F8),
                      borderRadius: BorderRadius.circular(MoolRadii.control),
                      border: const Border(
                        left: BorderSide(color: MoolColors.orange, width: 3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reply.sender,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: message.mine
                                ? Colors.white
                                : MoolColors.navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          reply.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: message.mine
                                ? Colors.white.withValues(alpha: .78)
                                : MoolColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
              if (photo != null) ...[
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                  child: Semantics(
                    label: 'Photo ${photo.name}',
                    image: true,
                    child: Image.network(
                      photo.readUrl.toString(),
                      key: Key('chat-photo-${message.id}'),
                      width: 280,
                      height: 210,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          width: 280,
                          height: 210,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => SizedBox(
                        width: 280,
                        height: 210,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                color: message.mine
                                    ? Colors.white
                                    : MoolColors.navy,
                              ),
                              const SizedBox(height: MoolSpacing.xs),
                              Text(
                                'Photo could not load.',
                                style: TextStyle(
                                  color: message.mine
                                      ? Colors.white
                                      : MoolColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextButton(
                                key: Key('chat-photo-refresh-${message.id}'),
                                onPressed: session.busy
                                    ? null
                                    : () => unawaited(
                                        session.loadMessages(
                                          threadId,
                                          refresh: true,
                                        ),
                                      ),
                                style: TextButton.styleFrom(
                                  foregroundColor: message.mine
                                      ? Colors.white
                                      : MoolColors.navy,
                                ),
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
              if (attachment != null) ...[
                const SizedBox(height: 3),
                Material(
                  color: message.mine
                      ? Colors.white.withValues(alpha: .14)
                      : const Color(0xFFF0F1F8),
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                  child: ListTile(
                    key: Key('chat-attachment-${message.id}'),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    leading: Icon(switch (attachment.kind) {
                      ChatAttachmentKind.document => Icons.description_outlined,
                      ChatAttachmentKind.video => Icons.play_circle_outline,
                      ChatAttachmentKind.voice => Icons.graphic_eq_rounded,
                    }, color: message.mine ? Colors.white : MoolColors.navy),
                    title: Text(
                      attachment.kind == ChatAttachmentKind.voice
                          ? 'Voice message'
                          : attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: message.mine ? Colors.white : MoolColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      attachment.duration == null
                          ? _fileSizeLabel(attachment.sizeBytes)
                          : _durationLabel(attachment.duration!),
                      style: TextStyle(
                        color: message.mine
                            ? Colors.white.withValues(alpha: .75)
                            : MoolColors.muted,
                      ),
                    ),
                    trailing: Icon(
                      attachment.kind == ChatAttachmentKind.voice
                          ? Icons.play_arrow_rounded
                          : Icons.open_in_new_rounded,
                      color: message.mine ? Colors.white : MoolColors.navy,
                    ),
                    onTap: () =>
                        unawaited(session.openAttachment(threadId, attachment)),
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
              if (message.attachmentLabel != null) ...[
                const SizedBox(height: 3),
                Material(
                  color: message.mine
                      ? Colors.white.withValues(alpha: .14)
                      : const Color(0xFFF0F1F8),
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                  child: ListTile(
                    key: Key('chat-attachment-reference-${message.id}'),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: MoolSpacing.xs,
                    ),
                    leading: Icon(
                      Icons.description_outlined,
                      color: message.mine ? Colors.white : MoolColors.navy,
                    ),
                    title: Text(
                      message.attachmentLabel!,
                      style: TextStyle(
                        color: message.mine ? Colors.white : MoolColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text('Attachment reference'),
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
              if (message.text.trim().isNotEmpty)
                Text(
                  message.text,
                  style: TextStyle(
                    color: message.mine ? Colors.white : MoolColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: MoolSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.timeLabel,
                    style: TextStyle(
                      color: message.mine
                          ? Colors.white.withValues(alpha: .72)
                          : MoolColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  if (message.mine) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: _deliveryLabel(message.deliveryState),
                      child: ChatActionIconMotion(
                        key: Key('chat-delivery-icon-motion-${message.id}'),
                        stateKey: message.deliveryState,
                        icon: _deliveryIcon(message.deliveryState),
                        color: failed
                            ? const Color(0xFFFFB4AB)
                            : message.deliveryState == ChatDeliveryState.read
                            ? MoolColors.orange
                            : Colors.white.withValues(alpha: .82),
                        size: 14,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              if (failed)
                TextButton(
                  key: Key('chat-retry-${message.id}'),
                  onPressed: session.busy
                      ? null
                      : () => unawaited(onRetry(message.id)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFB4AB),
                  ),
                  child: const Text('Retry'),
                ),
              if (message.reactionCount > 0)
                ChatFiniteIncomingMotion(
                  stateKey:
                      'reaction-${message.id}-${message.reactionCount}-${message.reactedByMe}',
                  duration: ChatMotion.focus,
                  child: Container(
                    key: Key('chat-reaction-count-${message.id}'),
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: message.mine
                          ? Colors.white.withValues(alpha: .14)
                          : const Color(0xFFF0F1F5),
                      borderRadius: BorderRadius.circular(MoolRadii.capsule),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          message.reactedByMe
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_up_outlined,
                          size: 13,
                          color: message.mine ? Colors.white : MoolColors.navy,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${message.reactionCount}',
                          style: TextStyle(
                            color: message.mine ? Colors.white : MoolColors.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showMessageActions(
  BuildContext context, {
  required ChatSession session,
  required String threadId,
  required ChatMessage message,
}) {
  final copyValue = _copyableMessageValue(message);
  final forwardableContent =
      message.photo == null &&
      message.attachmentLabel == null &&
      message.text.trim().isNotEmpty;
  final canForward =
      forwardableContent &&
      session.availableForwardTargets(threadId).isNotEmpty;
  final viewPadding = MediaQuery.viewPaddingOf(context);
  final bottomInset = viewPadding.bottom;
  final exportedSemanticsClearance = moolAndroidExportedSemanticsClearance(
    viewPadding: viewPadding,
    platform: Theme.of(context).platform,
  );
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    sheetAnimationStyle: ChatMotion.sheetStyle(context),
    builder: (sheetContext) => ChatBottomSheetSafeArea(
      bottomInset: bottomInset,
      exportedSemanticsClearance: exportedSemanticsClearance,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .78,
        ),
        child: ListView(
          key: const Key('chat-message-actions'),
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Message actions',
                style: TextStyle(
                  color: MoolColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (copyValue != null)
              ListTile(
                key: Key('chat-copy-${message.id}'),
                leading: const Icon(Icons.content_copy_rounded),
                title: const Text('Copy'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await Future<void>.delayed(Duration.zero);
                  if (!context.mounted) return;
                  await _copyMessage(context, copyValue);
                },
              ),
            ListTile(
              key: Key('chat-reply-${message.id}'),
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                session.startReply(threadId, message.id);
              },
            ),
            ListTile(
              key: Key('chat-react-${message.id}'),
              leading: Icon(
                message.reactedByMe
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_up_outlined,
              ),
              title: Text(message.reactedByMe ? 'Remove reaction' : 'React'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(session.toggleReaction(threadId, message.id));
              },
            ),
            if (forwardableContent)
              ListTile(
                key: Key('chat-forward-${message.id}'),
                leading: const Icon(Icons.forward_rounded),
                title: const Text('Forward'),
                enabled: canForward,
                onTap: !canForward
                    ? null
                    : () async {
                        Navigator.of(sheetContext).pop();
                        await Future<void>.delayed(Duration.zero);
                        if (!context.mounted) return;
                        await _chooseForwardTarget(
                          context,
                          session,
                          threadId,
                          message,
                        );
                      },
              ),
            ListTile(
              key: Key('chat-message-info-action-${message.id}'),
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Message details'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await Future<void>.delayed(Duration.zero);
                if (!context.mounted) return;
                await _showMessageInfo(context, message);
              },
            ),
            ListTile(
              key: Key('chat-remove-message-${message.id}'),
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Remove for me'),
              subtitle: const Text('Hide this message for this app session.'),
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(sheetContext).pop();
                session.setMessageHiddenForSession(
                  threadId,
                  message.id,
                  hidden: true,
                );
                messenger
                  ..hideCurrentSnackBar(reason: SnackBarClosedReason.remove)
                  ..showSnackBar(
                    SnackBar(
                      key: const Key('chat-message-remove-feedback'),
                      behavior: SnackBarBehavior.floating,
                      content: const Text(
                        'Message removed for this app session.',
                      ),
                      action: SnackBarAction(
                        key: const Key('chat-message-remove-undo'),
                        label: 'Undo',
                        onPressed: () => session.setMessageHiddenForSession(
                          threadId,
                          message.id,
                          hidden: false,
                        ),
                      ),
                    ),
                  );
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Text(
                'Remove for me affects this app session only. It does not delete the message for anyone else.',
                style: TextStyle(
                  color: MoolColors.muted,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _copyMessage(BuildContext context, String value) async {
  try {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar(reason: SnackBarClosedReason.remove)
      ..showSnackBar(
        const SnackBar(
          key: Key('chat-message-copy-feedback'),
          behavior: SnackBarBehavior.floating,
          content: Text('Message copied.'),
        ),
      );
  } on Object {
    if (!context.mounted) return;
    await showChatUnavailableCapability(
      context,
      keyName: 'chat-message-copy-recovery',
      title: 'Copy unavailable',
      message:
          'This message could not be copied right now. Nothing changed. You can continue in Chat and try again later.',
    );
  }
}

Future<void> _showMessageInfo(BuildContext context, ChatMessage message) {
  final viewPadding = MediaQuery.viewPaddingOf(context);
  final bottomInset = viewPadding.bottom;
  final exportedSemanticsClearance = moolAndroidExportedSemanticsClearance(
    viewPadding: viewPadding,
    platform: Theme.of(context).platform,
  );
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    sheetAnimationStyle: ChatMotion.sheetStyle(context),
    builder: (sheetContext) => ChatBottomSheetSafeArea(
      bottomInset: bottomInset,
      exportedSemanticsClearance: exportedSemanticsClearance,
      child: SingleChildScrollView(
        key: const Key('chat-message-info'),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Message details',
              style: TextStyle(
                color: MoolColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            _MessageInfoRow(
              keyName: 'chat-message-info-sender',
              label: message.mine ? 'Sent by' : 'Received from',
              value: message.sender,
            ),
            _MessageInfoRow(
              keyName: 'chat-message-info-time',
              label: 'Time',
              value: message.timeLabel,
            ),
            _MessageInfoRow(
              keyName: 'chat-message-info-type',
              label: 'Type',
              value: _messageTypeLabel(message),
            ),
            _MessageInfoRow(
              keyName: 'chat-message-info-status',
              label: 'Status',
              value: message.mine
                  ? _deliveryLabel(message.deliveryState)
                  : 'Received',
            ),
            if (message.forwarded)
              const _MessageInfoRow(
                keyName: 'chat-message-info-forwarded',
                label: 'Forwarded',
                value: 'Yes',
              ),
            if (message.replyTo case final reply?)
              _MessageInfoRow(
                keyName: 'chat-message-info-reply',
                label: 'Replying to',
                value: reply.sender,
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Details reflect the message currently loaded in Chat. Private reader identities are not shown.',
                style: TextStyle(color: MoolColors.muted, fontSize: 11.5),
              ),
            ),
            FilledButton(
              key: const Key('chat-message-info-continue'),
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Continue in Chat'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MessageInfoRow extends StatelessWidget {
  const _MessageInfoRow({
    required this.keyName,
    required this.label,
    required this.value,
  });

  final String keyName;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key(keyName),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: MoolColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: MoolColors.muted)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: MoolColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _copyableMessageValue(ChatMessage message) {
  final text = message.text.trim();
  if (text.isNotEmpty) return text;
  final attachment = message.attachmentLabel?.trim();
  return attachment == null || attachment.isEmpty ? null : attachment;
}

String _messageTypeLabel(ChatMessage message) {
  if (message.photo != null) return 'Photo';
  if (message.attachmentLabel != null) return 'Attachment';
  return 'Text message';
}

Future<void> _chooseForwardTarget(
  BuildContext context,
  ChatSession session,
  String sourceThreadId,
  ChatMessage message,
) async {
  final targets = session.availableForwardTargets(sourceThreadId);
  if (targets.isEmpty) return;
  final viewPadding = MediaQuery.viewPaddingOf(context);
  final bottomInset = viewPadding.bottom;
  final exportedSemanticsClearance = moolAndroidExportedSemanticsClearance(
    viewPadding: viewPadding,
    platform: Theme.of(context).platform,
  );
  final target = await showModalBottomSheet<ChatThread>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    sheetAnimationStyle: ChatMotion.sheetStyle(context),
    builder: (sheetContext) => ChatBottomSheetSafeArea(
      bottomInset: bottomInset,
      exportedSemanticsClearance: exportedSemanticsClearance,
      child: Column(
        key: const Key('chat-forward-picker'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: MoolSpacing.md),
            child: Text(
              'Forward message',
              style: TextStyle(
                color: MoolColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.sm,
            ),
            child: Text(
              'Choose one existing conversation.',
              style: TextStyle(color: MoolColors.muted),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: targets.length,
              itemBuilder: (context, index) {
                final target = targets[index];
                return ListTile(
                  key: Key('chat-forward-target-${target.id}'),
                  leading: const Icon(Icons.chat_bubble_outline_rounded),
                  title: Text(target.title),
                  subtitle: Text(target.subtitle),
                  onTap: () => Navigator.of(sheetContext).pop(target),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
  if (target == null || !context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('chat-forward-confirmation'),
      title: const Text('Forward message?'),
      content: Text('Send this message to ${target.title}?'),
      actions: [
        TextButton(
          key: const Key('chat-forward-cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('chat-forward-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Forward'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await session.forwardMessage(sourceThreadId, message.id, target.id);
  }
}

enum _ChatAttachmentChoice { document, gallery, camera, video }

String _durationLabel(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _fileSizeLabel(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).ceil()} KB';
}

class _ChatAttachmentAction extends StatelessWidget {
  const _ChatAttachmentAction({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
    key: Key(keyName),
    onTap: onPressed,
    borderRadius: BorderRadius.circular(MoolRadii.control),
    overlayColor: WidgetStatePropertyAll(
      MoolColors.navy.withValues(alpha: .06),
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: MoolColors.navy, size: 23),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.session,
    required this.threadId,
    required this.controller,
    required this.onSend,
    required this.onSendPhoto,
    required this.onSendAttachment,
    super.key,
  });

  final ChatSession session;
  final String threadId;
  final TextEditingController controller;
  final Future<void> Function() onSend;
  final Future<void> Function() onSendPhoto;
  final Future<void> Function() onSendAttachment;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _attachmentsOpen = false;
  String? _attachmentNotice;

  ChatSession get session => widget.session;
  String get threadId => widget.threadId;
  TextEditingController get controller => widget.controller;
  Future<void> Function() get onSend => widget.onSend;
  Future<void> Function() get onSendPhoto => widget.onSendPhoto;
  Future<void> Function() get onSendAttachment => widget.onSendAttachment;

  void _toggleAttachments() {
    setState(() {
      _attachmentsOpen = !_attachmentsOpen;
      _attachmentNotice = null;
    });
  }

  bool closeAttachmentsForBack() {
    if (!_attachmentsOpen) return false;
    setState(() {
      _attachmentsOpen = false;
      _attachmentNotice = null;
    });
    return true;
  }

  void _discardDraft() {
    if (session.busy) return;
    controller.clear();
    session.discardDraftForSession(threadId);
    setState(() {
      _attachmentsOpen = false;
      _attachmentNotice = null;
    });
  }

  Future<void> _chooseAttachment(
    BuildContext context,
    _ChatAttachmentChoice choice,
  ) async {
    switch (choice) {
      case _ChatAttachmentChoice.document:
        if (!session.attachmentSelectionAvailable) {
          setState(() {
            _attachmentNotice =
                'Document sharing is not available right now. You can share a photo or continue with a message.';
          });
          return;
        }
        await session.selectAttachment(threadId, ChatAttachmentKind.document);
        if (mounted) setState(() => _attachmentsOpen = false);
        return;
      case _ChatAttachmentChoice.gallery:
        await _selectPhoto(context, ChatPhotoSource.gallery);
        return;
      case _ChatAttachmentChoice.camera:
        await _selectPhoto(context, ChatPhotoSource.camera);
        return;
      case _ChatAttachmentChoice.video:
        if (!session.attachmentSelectionAvailable) {
          setState(() {
            _attachmentNotice =
                'Video sharing is not available right now. You can share a photo or continue with a message.';
          });
          return;
        }
        await session.selectAttachment(threadId, ChatAttachmentKind.video);
        if (mounted) setState(() => _attachmentsOpen = false);
        return;
    }
  }

  Future<void> _selectPhoto(
    BuildContext context,
    ChatPhotoSource source,
  ) async {
    if (!session.photoSharingAvailable) {
      if (!mounted) return;
      setState(() {
        _attachmentsOpen = true;
        _attachmentNotice =
            'Photo sharing is not available right now. You can continue with a message.';
      });
      return;
    }
    await session.selectPhoto(threadId, source);
    if (!mounted) return;
    setState(() {
      _attachmentsOpen = false;
      _attachmentNotice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reply = session.replyTarget(threadId);
    final photo = session.selectedPhoto(threadId);
    final attachment = session.selectedAttachment(threadId);
    return SafeArea(
      top: false,
      bottom: false,
      child: Material(
        color: const Color(0xFFF1F2F6),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.sm,
            MoolSpacing.xs,
            MoolSpacing.sm,
            MoolSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopScope<void>(
                canPop: !_attachmentsOpen,
                child: const SizedBox.shrink(),
              ),
              ChatExpandableMotion(
                key: const Key('chat-attachment-expand-motion'),
                child: _attachmentsOpen
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            key: const Key('chat-attachment-tray'),
                            width: double.infinity,
                            padding: const EdgeInsets.all(MoolSpacing.xs),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                MoolRadii.card,
                              ),
                              border: Border.all(
                                color: MoolColors.navy.withValues(alpha: .10),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ChatAttachmentAction(
                                        keyName: 'chat-document',
                                        icon: Icons.insert_drive_file_outlined,
                                        label: 'Document',
                                        onPressed: () => unawaited(
                                          _chooseAttachment(
                                            context,
                                            _ChatAttachmentChoice.document,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _ChatAttachmentAction(
                                        keyName: 'chat-gallery',
                                        icon: Icons.photo_library_outlined,
                                        label: 'Photos',
                                        onPressed: () => unawaited(
                                          _chooseAttachment(
                                            context,
                                            _ChatAttachmentChoice.gallery,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _ChatAttachmentAction(
                                        keyName: 'chat-camera',
                                        icon: Icons.photo_camera_outlined,
                                        label: 'Camera',
                                        onPressed: () => unawaited(
                                          _chooseAttachment(
                                            context,
                                            _ChatAttachmentChoice.camera,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _ChatAttachmentAction(
                                        keyName: 'chat-video',
                                        icon: Icons.video_library_outlined,
                                        label: 'Video',
                                        onPressed: () => unawaited(
                                          _chooseAttachment(
                                            context,
                                            _ChatAttachmentChoice.video,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_attachmentNotice != null) ...[
                                  const SizedBox(height: MoolSpacing.xs),
                                  Container(
                                    key: const Key('chat-attachment-notice'),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: MoolSpacing.sm,
                                      vertical: MoolSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F1F5),
                                      borderRadius: BorderRadius.circular(
                                        MoolRadii.control,
                                      ),
                                    ),
                                    child: Text(
                                      _attachmentNotice!,
                                      style: const TextStyle(
                                        color: MoolColors.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: MoolSpacing.xs),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              ChatExpandableMotion(
                key: const Key('chat-selected-photo-expand-motion'),
                child: photo != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            key: const Key('chat-selected-photo'),
                            width: double.infinity,
                            padding: const EdgeInsets.all(MoolSpacing.xs),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F1F8),
                              borderRadius: BorderRadius.circular(
                                MoolRadii.control,
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    MoolRadii.control,
                                  ),
                                  child: Image.memory(
                                    photo.bytes,
                                    key: const Key('chat-selected-photo-image'),
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const SizedBox(
                                              width: 72,
                                              height: 72,
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                              ),
                                            ),
                                  ),
                                ),
                                const SizedBox(width: MoolSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Photo ready to send',
                                        style: TextStyle(
                                          color: MoolColors.navy,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        photo.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: MoolColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  key: const Key('chat-remove-photo'),
                                  tooltip: 'Remove photo',
                                  onPressed: session.busy
                                      ? null
                                      : () => session.cancelSelectedPhoto(
                                          threadId,
                                        ),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: MoolSpacing.xs),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              ChatExpandableMotion(
                key: const Key('chat-reply-expand-motion'),
                child: reply != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            key: const Key('chat-composer-reply-context'),
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(
                              MoolSpacing.sm,
                              MoolSpacing.xs,
                              MoolSpacing.xs,
                              MoolSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F1F8),
                              borderRadius: BorderRadius.circular(
                                MoolRadii.control,
                              ),
                              border: const Border(
                                left: BorderSide(
                                  color: MoolColors.orange,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Replying to ${reply.sender}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: MoolColors.navy,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        reply.text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: MoolColors.muted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  key: const Key('chat-cancel-reply'),
                                  tooltip: 'Cancel reply',
                                  onPressed: () =>
                                      session.cancelReply(threadId),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: MoolSpacing.xs),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              ChatExpandableMotion(
                key: const Key('chat-selected-attachment-expand-motion'),
                child: attachment != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            key: const Key('chat-selected-attachment'),
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F1F8),
                              borderRadius: BorderRadius.circular(
                                MoolRadii.control,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(switch (attachment.kind) {
                                  ChatAttachmentKind.document =>
                                    Icons.description_outlined,
                                  ChatAttachmentKind.video =>
                                    Icons.video_file_outlined,
                                  ChatAttachmentKind.voice =>
                                    Icons.graphic_eq_rounded,
                                }, color: MoolColors.navy),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        switch (attachment.kind) {
                                          ChatAttachmentKind.document =>
                                            'Document ready to send',
                                          ChatAttachmentKind.video =>
                                            'Video ready to send',
                                          ChatAttachmentKind.voice =>
                                            'Voice message ready to send',
                                        },
                                        style: const TextStyle(
                                          color: MoolColors.navy,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        attachment.duration == null
                                            ? attachment.name
                                            : _durationLabel(
                                                attachment.duration!,
                                              ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: MoolColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  key: const Key('chat-remove-attachment'),
                                  tooltip: 'Remove attachment',
                                  onPressed: session.busy
                                      ? null
                                      : () => session.cancelSelectedAttachment(
                                          threadId,
                                        ),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: MoolSpacing.xs),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      key: const Key('chat-composer-surface'),
                      constraints: const BoxConstraints(minHeight: 48),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(MoolRadii.capsule),
                        border: Border.all(
                          color: MoolColors.navy.withValues(alpha: .10),
                        ),
                      ),
                      child: Stack(
                        children: [
                          TextField(
                            key: const Key('chat-message-field'),
                            controller: controller,
                            minLines: 1,
                            maxLines: 2,
                            scrollPadding: const EdgeInsets.only(bottom: 112),
                            decoration: InputDecoration(
                              hintText: photo == null && attachment == null
                                  ? 'Message'
                                  : 'Add a caption',
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.fromLTRB(
                                MoolSpacing.sm,
                                8,
                                MoolSpacing.sm,
                                48,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: SizedBox(
                              height: MoolMetrics.minimumTapTarget,
                              child: Row(
                                key: const Key('chat-composer-control-row'),
                                children: [
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: controller,
                                    builder: (context, value, _) {
                                      final hasDraft =
                                          value.text.isNotEmpty ||
                                          photo != null ||
                                          attachment != null ||
                                          reply != null;
                                      if (!hasDraft) {
                                        return const SizedBox(
                                          width: MoolMetrics.minimumTapTarget,
                                        );
                                      }
                                      return IconButton(
                                        key: const Key('chat-discard-draft'),
                                        tooltip: 'Discard draft',
                                        onPressed: session.busy
                                            ? null
                                            : _discardDraft,
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                      );
                                    },
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    key: const Key('chat-attach'),
                                    tooltip: _attachmentsOpen
                                        ? 'Close attachments'
                                        : 'Attach a file',
                                    onPressed: session.busy
                                        ? null
                                        : _toggleAttachments,
                                    icon: const Icon(Icons.attach_file_rounded),
                                  ),
                                  IconButton(
                                    key: const Key('chat-composer-camera'),
                                    tooltip: 'Camera',
                                    onPressed: session.busy
                                        ? null
                                        : () => unawaited(
                                            _selectPhoto(
                                              context,
                                              ChatPhotoSource.camera,
                                            ),
                                          ),
                                    icon: const Icon(
                                      Icons.photo_camera_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final hasMessage = value.text.trim().isNotEmpty;
                      final recording = session.isRecordingVoice(threadId);
                      final sendsContent =
                          photo != null || attachment != null || hasMessage;
                      return SizedBox.square(
                        dimension: 48,
                        child: IconButton.filled(
                          key: Key(
                            photo != null
                                ? 'chat-send-photo'
                                : attachment != null
                                ? 'chat-send-attachment'
                                : hasMessage
                                ? 'chat-send'
                                : recording
                                ? 'chat-voice-stop'
                                : 'chat-voice-message',
                          ),
                          tooltip: photo != null
                              ? 'Send photo'
                              : attachment != null
                              ? 'Send attachment'
                              : hasMessage
                              ? 'Send message'
                              : recording
                              ? 'Stop recording'
                              : 'Voice message',
                          style: IconButton.styleFrom(
                            backgroundColor: MoolColors.navy,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: session.busy
                              ? null
                              : () => unawaited(
                                  sendsContent
                                      ? photo != null
                                            ? onSendPhoto()
                                            : attachment != null
                                            ? onSendAttachment()
                                            : onSend()
                                      : !session.voiceRecordingAvailable
                                      ? showChatUnavailableCapability(
                                          context,
                                          keyName:
                                              'chat-voice-message-recovery',
                                          title: 'Voice messages unavailable',
                                          message:
                                              'Voice messages are not available right now. You can type a message instead.',
                                        )
                                      : recording
                                      ? session.stopVoiceRecording(threadId)
                                      : session.startVoiceRecording(threadId),
                                ),
                          icon: session.busy
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : ChatActionIconMotion(
                                  key: const Key(
                                    'chat-composer-action-icon-motion',
                                  ),
                                  stateKey: photo != null
                                      ? 'photo'
                                      : attachment != null
                                      ? 'attachment'
                                      : hasMessage
                                      ? 'send'
                                      : recording
                                      ? 'recording'
                                      : 'voice',
                                  icon: sendsContent
                                      ? Icons.send_rounded
                                      : recording
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _threadIconFor(ChatThreadType type) => switch (type) {
  ChatThreadType.people => Icons.person_outline_rounded,
  ChatThreadType.business => Icons.storefront_outlined,
  ChatThreadType.order => Icons.local_shipping_outlined,
  ChatThreadType.support => Icons.support_agent_rounded,
};

IconData _deliveryIcon(ChatDeliveryState state) => switch (state) {
  ChatDeliveryState.sending => Icons.schedule_rounded,
  ChatDeliveryState.delivered => Icons.done_rounded,
  ChatDeliveryState.read => Icons.done_all_rounded,
  ChatDeliveryState.failed => Icons.error_outline_rounded,
};

String _deliveryLabel(ChatDeliveryState state) => switch (state) {
  ChatDeliveryState.sending => 'Sending',
  ChatDeliveryState.delivered => 'Delivered',
  ChatDeliveryState.read => 'Read',
  ChatDeliveryState.failed => 'Not sent',
};
