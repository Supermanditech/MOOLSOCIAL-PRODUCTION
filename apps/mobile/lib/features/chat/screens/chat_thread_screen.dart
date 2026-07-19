import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../chat_models.dart';
import '../chat_session.dart';
import '../widgets/chat_widgets.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    required this.session,
    required this.threadId,
    required this.returnRoute,
    super.key,
  });

  final ChatSession session;
  final String threadId;
  final String returnRoute;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _messageController = TextEditingController();
  String _mode = 'Chat';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.session.markRead(widget.threadId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final thread = widget.session.thread(widget.threadId);
        final inboxRoute = chatRoute(
          '/app/chat/inbox',
          returnRoute: widget.returnRoute,
        );
        return ChatPageScaffold(
          key: const Key('chat-thread-screen'),
          session: widget.session,
          title: thread.title,
          subtitle: thread.subtitle,
          returnRoute: inboxRoute,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('chat-thread-call'),
                tooltip: 'Start audio call',
                onPressed: () => _showCallChoice(
                  context,
                  widget.session,
                  thread,
                  video: false,
                ),
                icon: const Icon(Icons.call_outlined),
              ),
              IconButton(
                key: const Key('chat-thread-video'),
                tooltip: 'Start video call',
                onPressed: () => _showCallChoice(
                  context,
                  widget.session,
                  thread,
                  video: true,
                ),
                icon: const Icon(Icons.videocam_outlined),
              ),
              IconButton(
                key: const Key('chat-thread-more'),
                tooltip: 'More conversation options',
                onPressed: () =>
                    _showMoreOptions(context, widget.session, thread),
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              _ModeStrip(
                type: thread.type,
                selected: _mode,
                onChanged: (value) => setState(() => _mode = value),
              ),
              Expanded(
                child: _ThreadBody(
                  session: widget.session,
                  thread: thread,
                  mode: _mode,
                ),
              ),
            ],
          ),
          bottom: _Composer(
            session: widget.session,
            threadId: thread.id,
            controller: _messageController,
          ),
        );
      },
    );
  }
}

class _ModeStrip extends StatelessWidget {
  const _ModeStrip({
    required this.type,
    required this.selected,
    required this.onChanged,
  });

  final ChatThreadType type;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final modes = type == ChatThreadType.business
        ? const ['Chat', 'Catalog', 'Quote', 'Orders', 'Pay']
        : type == ChatThreadType.people
        ? const ['Chat', 'Media', 'Basket', 'Poll', 'Invite']
        : const ['Chat', 'Details', 'Updates'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        0,
        MoolSpacing.md,
        MoolSpacing.xs,
      ),
      child: SizedBox(
        height: MoolMetrics.minimumTapTarget,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: modes.length,
          separatorBuilder: (_, _) => const SizedBox(width: MoolSpacing.xs),
          itemBuilder: (context, index) {
            final mode = modes[index];
            return ChoiceChip(
              key: Key('chat-mode-${mode.toLowerCase()}'),
              label: Text(mode),
              selected: selected == mode,
              onSelected: (_) => onChanged(mode),
            );
          },
        ),
      ),
    );
  }
}

class _ThreadBody extends StatelessWidget {
  const _ThreadBody({
    required this.session,
    required this.thread,
    required this.mode,
  });

  final ChatSession session;
  final ChatThread thread;
  final String mode;

  @override
  Widget build(BuildContext context) {
    if (mode != 'Chat') {
      return _ContextPanel(session: session, thread: thread, mode: mode);
    }
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
    return Align(
      alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: Key('chat-message-${message.id}'),
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: MoolSpacing.sm),
        padding: const EdgeInsets.all(MoolSpacing.sm),
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
          border: Border.all(
            color: failed ? const Color(0xFFD3322F) : const Color(0x18000080),
          ),
          boxShadow: MoolShadows.card,
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
            if (message.attachmentLabel != null) ...[
              const SizedBox(height: 3),
              Material(
                color: message.mine
                    ? Colors.white.withValues(alpha: .14)
                    : const Color(0xFFF0F1F8),
                borderRadius: BorderRadius.circular(MoolRadii.control),
                child: ListTile(
                  key: Key('chat-open-attachment-${message.id}'),
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
                  onTap: () =>
                      session.showNotice('${message.attachmentLabel} opened.'),
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
            ],
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
                  Icon(
                    _deliveryIcon(message.deliveryState),
                    color: failed
                        ? const Color(0xFFFFB4AB)
                        : Colors.white.withValues(alpha: .82),
                    size: 14,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Wrap(
              spacing: MoolSpacing.xs,
              children: [
                TextButton(
                  key: Key('chat-like-${message.id}'),
                  onPressed: () => session.toggleReaction(threadId, message.id),
                  style: TextButton.styleFrom(
                    foregroundColor: message.mine
                        ? Colors.white
                        : MoolColors.navy,
                    minimumSize: const Size(
                      MoolMetrics.minimumTapTarget,
                      MoolMetrics.minimumTapTarget,
                    ),
                  ),
                  child: Text(
                    message.reactionCount == 0
                        ? 'Like'
                        : 'Like ${message.reactionCount}',
                  ),
                ),
                TextButton(
                  key: Key('chat-reply-${message.id}'),
                  onPressed: () => session.startReply(message.id),
                  style: TextButton.styleFrom(
                    foregroundColor: message.mine
                        ? Colors.white
                        : MoolColors.navy,
                  ),
                  child: const Text('Reply'),
                ),
                if (failed)
                  TextButton(
                    key: Key('chat-retry-${message.id}'),
                    onPressed: () => session.retry(threadId, message.id),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFB4AB),
                    ),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({
    required this.session,
    required this.thread,
    required this.mode,
  });

  final ChatSession session;
  final ChatThread thread;
  final String mode;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: Key('chat-context-${mode.toLowerCase()}'),
      padding: const EdgeInsets.all(MoolSpacing.md),
      children: [
        ChatSurfaceCard(
          color: const Color(0xFFEDEEFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _contextTitle(mode),
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              Text(_contextDetail(mode, thread.type)),
              const SizedBox(height: MoolSpacing.md),
              FilledButton.icon(
                key: Key('chat-context-primary-${mode.toLowerCase()}'),
                onPressed: () =>
                    _completeContextAction(context, session, thread, mode),
                icon: Icon(_contextIcon(mode)),
                label: Text(_contextAction(mode)),
              ),
            ],
          ),
        ),
        if (mode == 'Poll') ...[
          const SizedBox(height: MoolSpacing.sm),
          _PollCard(session: session),
        ],
        if (mode == 'Basket' || mode == 'Quote') ...[
          const SizedBox(height: MoolSpacing.sm),
          ChatSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == 'Basket'
                      ? 'Shared household list'
                      : 'Mahadev Fresh Mart quote',
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
                const Text('Tomatoes · atta · rice · cooking oil'),
                const SizedBox(height: MoolSpacing.sm),
                OutlinedButton(
                  key: Key('chat-${mode.toLowerCase()}-buy'),
                  onPressed: () => context.go('/app/buy/grocery'),
                  child: Text(
                    mode == 'Basket'
                        ? 'Find current prices'
                        : 'Review products',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PollCard extends StatelessWidget {
  const _PollCard({required this.session});

  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    return ChatSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Which delivery time works?',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          for (final option in const [
            'Today evening',
            'Tomorrow morning',
            'Tomorrow evening',
          ])
            ListTile(
              key: Key(
                'chat-poll-${option.toLowerCase().replaceAll(' ', '-')}',
              ),
              title: Text(option),
              trailing: const Icon(Icons.radio_button_unchecked_rounded),
              onTap: () => session.showNotice('Vote recorded for $option.'),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.session,
    required this.threadId,
    required this.controller,
  });

  final ChatSession session;
  final String threadId;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
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
              if (session.replyingTo != null)
                _ComposerChip(
                  key: const Key('chat-reply-preview'),
                  icon: Icons.reply_rounded,
                  label: 'Replying to a message',
                  onRemove: session.cancelReply,
                ),
              if (session.pendingAttachment != null)
                _ComposerChip(
                  key: const Key('chat-attachment-preview'),
                  icon: Icons.attach_file_rounded,
                  label: session.pendingAttachment!,
                  onRemove: session.removeAttachment,
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filledTonal(
                    key: const Key('chat-thread-mool'),
                    tooltip: 'Open Mool',
                    onPressed: () => context.go('/app/mool'),
                    icon: const Text(
                      'Mool',
                      style: TextStyle(
                        color: MoolColors.navy,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('chat-attach'),
                    tooltip: 'Attach',
                    onPressed: () => _showAttachments(context, session),
                    icon: const Icon(Icons.attach_file_rounded),
                  ),
                  IconButton(
                    key: const Key('chat-camera'),
                    tooltip: 'Open camera',
                    onPressed: () => session.attach('Camera photo'),
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      key: const Key('chat-message-field'),
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: MoolSpacing.sm,
                          vertical: MoolSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  IconButton.filled(
                    key: const Key('chat-send'),
                    tooltip: 'Send message',
                    onPressed: session.busy
                        ? null
                        : () async {
                            final sent = await session.send(
                              threadId,
                              controller.text,
                            );
                            if (sent) controller.clear();
                          },
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

class _ComposerChip extends StatelessWidget {
  const _ComposerChip({
    required this.icon,
    required this.label,
    required this.onRemove,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: MoolSpacing.xs),
      padding: const EdgeInsets.only(left: MoolSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEEFF),
        borderRadius: BorderRadius.circular(MoolRadii.control),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: MoolColors.navy),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAttachments(BuildContext context, ChatSession session) {
  const options = [
    ('Camera', Icons.camera_alt_outlined),
    ('Gallery', Icons.photo_library_outlined),
    ('Video', Icons.videocam_outlined),
    ('File', Icons.description_outlined),
    ('Location', Icons.location_on_outlined),
    ('Contact', Icons.person_outline_rounded),
    ('Poll', Icons.poll_outlined),
    ('Household basket', Icons.shopping_basket_outlined),
  ];
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add to this message',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: [
                for (final option in options)
                  ActionChip(
                    key: Key(
                      'chat-attachment-${option.$1.toLowerCase().replaceAll(' ', '-')}',
                    ),
                    avatar: Icon(option.$2, color: MoolColors.navy, size: 19),
                    label: Text(option.$1),
                    onPressed: () {
                      session.attach(option.$1);
                      Navigator.of(sheetContext).pop();
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

Future<void> _showCallChoice(
  BuildContext context,
  ChatSession session,
  ChatThread thread, {
  required bool video,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${video ? 'Video call' : 'Call'} ${thread.title}?',
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            video
                ? 'Camera and microphone permission will be requested when needed.'
                : 'The call uses a protected number for business and support chats.',
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton.icon(
            key: Key(video ? 'chat-confirm-video' : 'chat-confirm-call'),
            onPressed: () {
              Navigator.of(sheetContext).pop();
              session.showNotice(
                '${video ? 'Video call' : 'Call'} started with ${thread.title}.',
              );
            },
            icon: Icon(video ? Icons.videocam_outlined : Icons.call_outlined),
            label: Text(video ? 'Start video call' : 'Call now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showMoreOptions(
  BuildContext context,
  ChatSession session,
  ChatThread thread,
) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in const [
            ('search', Icons.search_rounded, 'Search this conversation'),
            ('mute', Icons.notifications_off_outlined, 'Mute notifications'),
            ('media', Icons.photo_library_outlined, 'Shared media and files'),
            ('block', Icons.block_outlined, 'Block and report'),
          ])
            ListTile(
              key: Key('chat-more-${option.$1}'),
              leading: Icon(option.$2, color: MoolColors.navy),
              title: Text(option.$3),
              onTap: () {
                Navigator.of(sheetContext).pop();
                session.showNotice(
                  '${option.$3} selected for ${thread.title}.',
                );
              },
            ),
        ],
      ),
    ),
  );
}

IconData _deliveryIcon(ChatDeliveryState state) => switch (state) {
  ChatDeliveryState.sending => Icons.schedule_rounded,
  ChatDeliveryState.delivered => Icons.done_all_rounded,
  ChatDeliveryState.failed => Icons.error_outline_rounded,
};

String _contextTitle(String mode) => switch (mode) {
  'Catalog' => 'Shop catalog',
  'Quote' => 'Basket quote',
  'Orders' => 'Linked orders',
  'Pay' => 'Pay after confirmation',
  'Media' => 'Shared media',
  'Basket' => 'Shared household basket',
  'Poll' => 'Group poll',
  'Invite' => 'Invite members',
  'Details' => 'Conversation details',
  'Updates' => 'Status updates',
  _ => mode,
};

String _contextDetail(String mode, ChatThreadType type) => switch (mode) {
  'Catalog' => 'Browse verified products without leaving the business chat.',
  'Quote' => 'Confirm items, price and home delivery before checkout.',
  'Orders' => 'Open orders already linked to this conversation.',
  'Pay' => 'Payment opens only after the final amount is confirmed.',
  'Media' => 'Review photos, voice notes and documents shared here.',
  'Basket' => 'Edit a list together, then find current product prices.',
  'Poll' => 'Vote once and use the result for the group action.',
  'Invite' => 'Invite a person after confirming who can see this chat.',
  'Details' => 'Review the linked ${type.label.toLowerCase()} context.',
  'Updates' => 'See status changes in one chronological list.',
  _ => 'Complete this conversation action.',
};

String _contextAction(String mode) => switch (mode) {
  'Catalog' => 'Open products',
  'Quote' => 'Review quote',
  'Orders' => 'Open linked order',
  'Pay' => 'Review payment',
  'Media' => 'Open shared files',
  'Basket' => 'Edit shared list',
  'Poll' => 'Add poll option',
  'Invite' => 'Invite a member',
  'Details' => 'View details',
  'Updates' => 'Refresh updates',
  _ => 'Continue',
};

IconData _contextIcon(String mode) => switch (mode) {
  'Catalog' => Icons.storefront_outlined,
  'Quote' => Icons.request_quote_outlined,
  'Orders' => Icons.shopping_bag_outlined,
  'Pay' => Icons.account_balance_wallet_outlined,
  'Media' => Icons.photo_library_outlined,
  'Basket' => Icons.shopping_basket_outlined,
  'Poll' => Icons.poll_outlined,
  'Invite' => Icons.person_add_alt_outlined,
  'Details' => Icons.info_outline_rounded,
  'Updates' => Icons.refresh_rounded,
  _ => Icons.arrow_forward_rounded,
};

void _completeContextAction(
  BuildContext context,
  ChatSession session,
  ChatThread thread,
  String mode,
) {
  if (const {'Catalog', 'Quote'}.contains(mode)) {
    context.go('/app/buy/grocery');
    return;
  }
  if (mode == 'Pay') {
    context.go('/app/pay');
    return;
  }
  session.showNotice('${_contextAction(mode)} is ready in ${thread.title}.');
}
