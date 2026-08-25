import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
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
        return ChatPageScaffold(
          key: const Key('chat-thread-screen'),
          session: widget.session,
          title: thread.title,
          subtitle: thread.subtitle,
          returnRoute: backRoute,
          showContentBack: true,
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
          bottom: _Composer(
            session: widget.session,
            threadId: thread.id,
            controller: _messageController,
            onSend: _sendCurrentMessage,
            onSendPhoto: _sendCurrentPhoto,
          ),
        );
      },
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
      child: Container(
        key: Key('chat-message-${message.id}'),
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: message.mine ? MoolColors.navy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(MoolRadii.card),
            topRight: const Radius.circular(MoolRadii.card),
            bottomLeft: Radius.circular(
              message.mine ? MoolRadii.card : MoolSpacing.xs,
            ),
            bottomRight: Radius.circular(
              message.mine ? MoolSpacing.xs : MoolRadii.card,
            ),
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
                          color: message.mine ? Colors.white : MoolColors.navy,
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
                  fontWeight: FontWeight.w600,
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
            if (message.isSettled)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: Key('chat-reply-${message.id}'),
                    tooltip: 'Reply',
                    onPressed: session.busy
                        ? null
                        : () => session.startReply(threadId, message.id),
                    visualDensity: VisualDensity.compact,
                    color: message.mine ? Colors.white : MoolColors.navy,
                    icon: const Icon(Icons.reply_rounded, size: 19),
                  ),
                  IconButton(
                    key: Key('chat-react-${message.id}'),
                    tooltip: message.reactedByMe ? 'Remove reaction' : 'React',
                    onPressed: session.busy
                        ? null
                        : () => unawaited(
                            session.toggleReaction(threadId, message.id),
                          ),
                    visualDensity: VisualDensity.compact,
                    color: message.mine ? Colors.white : MoolColors.navy,
                    icon: Badge(
                      isLabelVisible: message.reactionCount > 0,
                      label: Text('${message.reactionCount}'),
                      backgroundColor: MoolColors.orange,
                      textColor: MoolColors.ink,
                      child: Icon(
                        message.reactedByMe
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        size: 19,
                      ),
                    ),
                  ),
                  if (message.photo == null &&
                      message.attachmentLabel == null &&
                      message.text.trim().isNotEmpty)
                    IconButton(
                      key: Key('chat-forward-${message.id}'),
                      tooltip: 'Forward',
                      onPressed:
                          session.busy ||
                              session.availableForwardTargets(threadId).isEmpty
                          ? null
                          : () => unawaited(
                              _chooseForwardTarget(
                                context,
                                session,
                                threadId,
                                message,
                              ),
                            ),
                      visualDensity: VisualDensity.compact,
                      color: message.mine ? Colors.white : MoolColors.navy,
                      icon: const Icon(Icons.forward_rounded, size: 19),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _chooseForwardTarget(
  BuildContext context,
  ChatSession session,
  String sourceThreadId,
  ChatMessage message,
) async {
  final targets = session.availableForwardTargets(sourceThreadId);
  if (targets.isEmpty) return;
  final target = await showModalBottomSheet<ChatThread>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
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

class _Composer extends StatelessWidget {
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

  Future<void> _choosePhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ChatPhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          key: const Key('chat-attach-sheet'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Share a photo',
                style: TextStyle(
                  color: MoolColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text('JPEG, PNG or WebP up to 4 MB.'),
            ),
            ListTile(
              key: const Key('chat-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ChatPhotoSource.gallery),
            ),
            ListTile(
              key: const Key('chat-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ChatPhotoSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    await session.selectPhoto(threadId, source);
  }

  @override
  Widget build(BuildContext context) {
    final reply = session.replyTarget(threadId);
    final photo = session.selectedPhoto(threadId);
    return SafeArea(
      top: false,
      bottom: false,
      child: Material(
        color: Colors.white,
        elevation: 10,
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
                  if (session.photoSharingAvailable) ...[
                    IconButton(
                      key: const Key('chat-attach'),
                      tooltip: 'Share a photo',
                      onPressed: session.busy
                          ? null
                          : () => unawaited(_choosePhoto(context)),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                  ],
                  Expanded(
                    child: TextField(
                      key: const Key('chat-message-field'),
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: photo == null
                            ? 'Message'
                            : 'Add a caption (optional)',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: MoolSpacing.sm,
                          vertical: MoolSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  IconButton.filled(
                    key: Key(photo == null ? 'chat-send' : 'chat-send-photo'),
                    tooltip: photo == null ? 'Send message' : 'Send photo',
                    onPressed: session.busy
                        ? null
                        : () => unawaited(
                            photo == null ? onSend() : onSendPhoto(),
                          ),
                    icon: session.busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
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
