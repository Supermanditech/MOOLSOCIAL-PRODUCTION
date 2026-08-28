import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/universal/mool_global_navigation_v2.dart';
import '../chat_entry_context.dart';
import '../chat_models.dart';
import '../chat_services.dart';
import '../chat_session.dart';
import '../widgets/chat_widgets.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    required this.session,
    required this.threadId,
    required this.returnRoute,
    this.initialMessageDraft,
    super.key,
  });

  final ChatSession session;
  final String threadId;
  final String returnRoute;
  final String? initialMessageDraft;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _messageController = TextEditingController();
  final Map<String, String> _draftTextByThread = {};
  int _threadLoadRequest = 0;

  @override
  void initState() {
    super.initState();
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
      if (identical(oldWidget.session, widget.session)) {
        _storeDraft(oldWidget.threadId);
      } else {
        _draftTextByThread.clear();
      }
      _restoreDraft(widget.threadId);
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

  void _storeDraft(String threadId) {
    final draft = _messageController.text;
    if (draft.isEmpty) {
      _draftTextByThread.remove(threadId);
    } else {
      _draftTextByThread[threadId] = draft;
    }
  }

  void _restoreDraft(String threadId) {
    final draft = _draftTextByThread[threadId] ?? '';
    _messageController.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
  }

  Future<void> _sendCurrentMessage() async {
    final session = widget.session;
    final threadId = widget.threadId;
    final draft = _messageController.text;
    final sent = await session.send(threadId, draft);
    if (!sent || !identical(session, widget.session)) return;
    if (_draftTextByThread[threadId] == draft) {
      _draftTextByThread.remove(threadId);
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
    final sent = await session.sendSelectedPhoto(threadId, draft);
    if (!sent || !identical(session, widget.session)) return;
    if (_draftTextByThread[threadId] == draft) {
      _draftTextByThread.remove(threadId);
    }
    if (mounted &&
        threadId == widget.threadId &&
        _messageController.text == draft) {
      _messageController.clear();
    }
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _threadLoadRequest += 1;
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
        final backRoute = returnsToChatThread
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('chat-thread-video'),
                tooltip: widget.session.videoCallsAvailableForSession(thread.id)
                    ? 'Video call'
                    : 'Video calls paused',
                onPressed: () => unawaited(
                  _showUnavailableCapability(
                    context,
                    keyName: 'chat-video-recovery',
                    title:
                        widget.session.videoCallsAvailableForSession(thread.id)
                        ? 'Video calling unavailable'
                        : 'Video calls paused',
                    message:
                        widget.session.videoCallsAvailableForSession(thread.id)
                        ? 'Video calling is not available right now. You can continue this conversation in Chat.'
                        : 'Video calls are paused for this conversation until you turn them on in Conversation info.',
                  ),
                ),
                icon: const Icon(Icons.videocam_outlined),
              ),
              IconButton(
                key: const Key('chat-thread-call'),
                tooltip: widget.session.voiceCallsAvailableForSession(thread.id)
                    ? 'Voice call'
                    : 'Voice calls paused',
                onPressed: () => unawaited(
                  _showUnavailableCapability(
                    context,
                    keyName: 'chat-call-recovery',
                    title:
                        widget.session.voiceCallsAvailableForSession(thread.id)
                        ? 'Voice calling unavailable'
                        : 'Voice calls paused',
                    message:
                        widget.session.voiceCallsAvailableForSession(thread.id)
                        ? 'Voice calling is not available right now. You can continue this conversation in Chat.'
                        : 'Voice calls are paused for this conversation until you turn them on in Conversation info.',
                  ),
                ),
                icon: const Icon(Icons.call_outlined),
              ),
            ],
          ),
          messageThreadId: thread.id,
          body:
              widget.session.loadingMessageThreads.contains(thread.id) &&
                  widget.session.messages(thread.id).isEmpty
              ? const _ThreadLoadingState()
              : widget.session.messageLoadError(thread.id) != null &&
                    widget.session.messages(thread.id).isEmpty
              ? _ThreadErrorState(
                  message: widget.session.messageLoadError(thread.id)!,
                  onRetry: () =>
                      widget.session.loadMessages(thread.id, refresh: true),
                )
              : _ThreadBody(session: widget.session, thread: thread),
          bottom: widget.session.chatAvailableForSession(thread.id)
              ? _Composer(
                  session: widget.session,
                  threadId: thread.id,
                  controller: _messageController,
                  onSend: _sendCurrentMessage,
                  onSendPhoto: _sendCurrentPhoto,
                )
              : _ChatPausedBar(
                  onResume: () => widget.session.setChatAvailableForSession(
                    thread.id,
                    available: true,
                  ),
                ),
        );
      },
    );
  }
}

class _ConversationInfoScreen extends StatefulWidget {
  const _ConversationInfoScreen({
    required this.session,
    required this.thread,
    required this.entryContext,
  });

  final ChatSession session;
  final ChatThread thread;
  final ChatEntryContext entryContext;

  @override
  State<_ConversationInfoScreen> createState() =>
      _ConversationInfoScreenState();
}

class _ConversationInfoScreenState extends State<_ConversationInfoScreen> {
  String? _statusMessage;

  void _confirmLocalChange(String message) {
    setState(() => _statusMessage = message);
  }

  void _showAccountSettingRecovery({
    required String keyName,
    required String title,
  }) {
    unawaited(
      _showUnavailableCapability(
        context,
        keyName: keyName,
        title: title,
        message:
            'This account setting cannot be updated right now. Your current choice stays unchanged. Try again later.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final thread = widget.thread;
        final session = widget.session;
        final chatAvailable = session.chatAvailableForSession(thread.id);
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
                accent: widget.entryContext.accent,
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                _ConversationStatusNotice(message: _statusMessage!),
              ],
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
                      subtitle: const Text(
                        'Pause or resume the composer for this conversation.',
                      ),
                      value: chatAvailable,
                      onChanged: (available) {
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
                      subtitle: const Text(
                        'Control the voice-call action in this conversation.',
                      ),
                      value: session.voiceCallsAvailableForSession(thread.id),
                      onChanged: (available) {
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
                      subtitle: const Text(
                        'Control the video-call action in this conversation.',
                      ),
                      value: session.videoCallsAvailableForSession(thread.id),
                      onChanged: (available) {
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
                        'Account setting · current choice stays unchanged.',
                      ),
                      value: true,
                      onChanged: (_) => _showAccountSettingRecovery(
                        keyName: 'chat-last-seen-recovery',
                        title: 'Last seen setting unchanged',
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
                        'Account setting · current choice stays unchanged.',
                      ),
                      value: true,
                      onChanged: (_) => _showAccountSettingRecovery(
                        keyName: 'chat-read-receipts-recovery',
                        title: 'Read receipt setting unchanged',
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
                  title: const Text('Block this person'),
                  subtitle: const Text('Nothing changes without confirmation.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showAccountSettingRecovery(
                    keyName: 'chat-block-user-recovery',
                    title: 'Blocking unavailable',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConversationIdentityCard extends StatelessWidget {
  const _ConversationIdentityCard({
    required this.thread,
    required this.chatAvailable,
    required this.accent,
  });

  final ChatThread thread;
  final bool chatAvailable;
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
                            : 'Chat paused for this session',
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
  const _ChatPausedBar({required this.onResume});

  final VoidCallback onResume;

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
              const Expanded(
                child: Text(
                  'Chat is paused for this app session.',
                  style: TextStyle(
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
                  key: const Key('chat-resume'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(96, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: onResume,
                  child: const Text('Resume'),
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
  const _ThreadBody({required this.session, required this.thread});

  final ChatSession session;
  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final messages = session.messages(thread.id);
    return ListView.builder(
      key: const Key('chat-message-list'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.lg,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) => _MessageBubble(
        message: messages[index],
        threadId: thread.id,
        session: session,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.threadId,
    required this.session,
  });

  final ChatMessage message;
  final String threadId;
  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    final failed = message.deliveryState == ChatDeliveryState.failed;
    final reply = message.replyTo;
    final photo = message.photo;
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
        child: Container(
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
            border: failed ? Border.all(color: const Color(0xFFD3322F)) : null,
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
                      child: Icon(
                        _deliveryIcon(message.deliveryState),
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
                      : () => session.retry(threadId, message.id),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFB4AB),
                  ),
                  child: const Text('Retry'),
                ),
              if (message.reactionCount > 0)
                Container(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBottomSheetSafeArea extends StatelessWidget {
  const _ChatBottomSheetSafeArea({
    required this.bottomInset,
    required this.child,
  });

  final double bottomInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final baseBottomPadding = bottomInset > MoolSpacing.md
        ? bottomInset
        : MoolSpacing.md;
    final exportedSemanticsClearance = moolAndroidExportedSemanticsClearance(
      viewPadding: MediaQuery.viewPaddingOf(context),
      platform: Theme.of(context).platform,
    );
    final bottomPadding = baseBottomPadding + exportedSemanticsClearance;
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: child,
      ),
    );
  }
}

Future<void> _showUnavailableCapability(
  BuildContext context, {
  required String keyName,
  required String title,
  required String message,
}) {
  final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ChatBottomSheetSafeArea(
      bottomInset: bottomInset,
      child: Padding(
        key: Key(keyName),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.lg,
          MoolSpacing.xs,
          MoolSpacing.lg,
          MoolSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            Text(message, style: const TextStyle(color: MoolColors.muted)),
            const SizedBox(height: MoolSpacing.md),
            FilledButton(
              key: const Key('chat-capability-continue'),
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Continue in Chat'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showMessageActions(
  BuildContext context, {
  required ChatSession session,
  required String threadId,
  required ChatMessage message,
}) {
  final forwardableContent =
      message.photo == null &&
      message.attachmentLabel == null &&
      message.text.trim().isNotEmpty;
  final canForward =
      forwardableContent &&
      session.availableForwardTargets(threadId).isNotEmpty;
  final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ChatBottomSheetSafeArea(
      bottomInset: bottomInset,
      child: Column(
        key: const Key('chat-message-actions'),
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: MoolSpacing.xs),
        ],
      ),
    ),
  );
}

Future<void> _chooseForwardTarget(
  BuildContext context,
  ChatSession session,
  String sourceThreadId,
  ChatMessage message,
) async {
  final targets = session.availableForwardTargets(sourceThreadId);
  if (targets.isEmpty) return;
  final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
  final target = await showModalBottomSheet<ChatThread>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ChatBottomSheetSafeArea(
      bottomInset: bottomInset,
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

enum _ChatAttachmentChoice { document, gallery, camera }

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
  });

  final ChatSession session;
  final String threadId;
  final TextEditingController controller;
  final Future<void> Function() onSend;
  final Future<void> Function() onSendPhoto;

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

  void _toggleAttachments() {
    setState(() {
      _attachmentsOpen = !_attachmentsOpen;
      _attachmentNotice = null;
    });
  }

  Future<void> _chooseAttachment(
    BuildContext context,
    _ChatAttachmentChoice choice,
  ) async {
    switch (choice) {
      case _ChatAttachmentChoice.document:
        setState(() {
          _attachmentNotice =
              'Document sharing is not available right now. You can share a photo or continue with a message.';
        });
        return;
      case _ChatAttachmentChoice.gallery:
        await _selectPhoto(context, ChatPhotoSource.gallery);
        return;
      case _ChatAttachmentChoice.camera:
        await _selectPhoto(context, ChatPhotoSource.camera);
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
              if (_attachmentsOpen) ...[
                Container(
                  key: const Key('chat-attachment-tray'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(MoolSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(MoolRadii.card),
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
              if (photo != null) ...[
                Container(
                  key: const Key('chat-selected-photo'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(MoolSpacing.xs),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F8),
                    borderRadius: BorderRadius.circular(MoolRadii.control),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(MoolRadii.control),
                        child: Image.memory(
                          photo.bytes,
                          key: const Key('chat-selected-photo-image'),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(
                                width: 72,
                                height: 72,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                        ),
                      ),
                      const SizedBox(width: MoolSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: const TextStyle(color: MoolColors.muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('chat-remove-photo'),
                        tooltip: 'Remove photo',
                        onPressed: session.busy
                            ? null
                            : () => session.cancelSelectedPhoto(threadId),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
              if (reply != null) ...[
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
                    borderRadius: BorderRadius.circular(MoolRadii.control),
                    border: const Border(
                      left: BorderSide(color: MoolColors.orange, width: 3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                        onPressed: () => session.cancelReply(threadId),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('chat-message-field'),
                              controller: controller,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: photo == null
                                    ? 'Message'
                                    : 'Add a caption',
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: MoolSpacing.xs,
                                  vertical: MoolSpacing.sm,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('chat-attach'),
                            tooltip: _attachmentsOpen
                                ? 'Close attachments'
                                : 'Attach a file',
                            onPressed: session.busy ? null : _toggleAttachments,
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
                            icon: const Icon(Icons.photo_camera_outlined),
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
                      final sendsContent = photo != null || hasMessage;
                      return SizedBox.square(
                        dimension: 48,
                        child: IconButton.filled(
                          key: Key(
                            photo != null
                                ? 'chat-send-photo'
                                : hasMessage
                                ? 'chat-send'
                                : 'chat-voice-message',
                          ),
                          tooltip: photo != null
                              ? 'Send photo'
                              : hasMessage
                              ? 'Send message'
                              : 'Voice message',
                          style: IconButton.styleFrom(
                            backgroundColor: MoolColors.navy,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: session.busy
                              ? null
                              : () => unawaited(
                                  sendsContent
                                      ? photo == null
                                            ? onSend()
                                            : onSendPhoto()
                                      : _showUnavailableCapability(
                                          context,
                                          keyName:
                                              'chat-voice-message-recovery',
                                          title: 'Voice messages unavailable',
                                          message:
                                              'Voice messages are not available right now. You can type a message instead.',
                                        ),
                                ),
                          icon: session.busy
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  sendsContent
                                      ? Icons.send_rounded
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
