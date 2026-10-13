import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../chat_entry_context.dart';
import '../chat_models.dart';
import '../chat_session.dart';
import '../widgets/chat_motion.dart';
import '../widgets/chat_widgets.dart';

class ChatConversationSearchScreen extends StatefulWidget {
  const ChatConversationSearchScreen({
    required this.session,
    required this.threadId,
    required this.originReturnRoute,
    super.key,
  });

  final ChatSession session;
  final String threadId;
  final String originReturnRoute;

  @override
  State<ChatConversationSearchScreen> createState() =>
      _ChatConversationSearchScreenState();
}

class _ChatConversationSearchScreenState
    extends State<ChatConversationSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  List<ChatMessage> _results() {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return widget.session
        .messages(widget.threadId)
        .where((message) {
          final values = <String>[
            message.sender,
            message.text,
            ?message.attachmentLabel,
            ?message.photo?.name,
            ?message.replyTo?.sender,
            ?message.replyTo?.text,
          ];
          return values.any((value) => value.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {});
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.session.thread(widget.threadId);
    final entryContext = ChatEntryContext.resolve(widget.originReturnRoute);
    final query = _controller.text.trim();
    final results = _results();
    return ChatPageScaffold(
      key: const Key('chat-conversation-search-screen'),
      session: widget.session,
      title: 'Search messages',
      subtitle: thread.title,
      returnRoute: chatRoute(
        '/app/chat/thread/${thread.id}',
        returnRoute: widget.originReturnRoute,
      ),
      showContentBack: true,
      backKeyName: 'chat-conversation-search-back',
      titleIcon: Icons.search_rounded,
      titleAccent: entryContext.accent,
      showMessageBanner: false,
      backgroundColor: const Color(0xFFF4F5F8),
      body: AnimatedPadding(
        key: const Key('chat-conversation-search-keyboard-safe'),
        duration: ChatMotion.resolve(context, ChatMotion.focus),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Material(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: ChatSearchFocusMotion(
                  focused: _focusNode.hasFocus,
                  motionKeyName: 'chat-conversation-search-focus-motion',
                  child: TextField(
                    key: const Key('chat-conversation-search-field'),
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search this conversation',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              key: const Key('chat-conversation-search-clear'),
                              tooltip: 'Clear message search',
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: query.isEmpty
                  ? const ChatFiniteIncomingMotion(
                      stateKey: 'conversation-search-intro',
                      child: _ConversationSearchIntro(),
                    )
                  : results.isEmpty
                  ? ChatFiniteIncomingMotion(
                      stateKey: 'conversation-search-empty-$query',
                      child: _ConversationSearchEmpty(onClear: _clearSearch),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                          child: Text(
                            '${results.length} ${results.length == 1 ? 'result' : 'results'}',
                            key: const Key('chat-conversation-search-count'),
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            key: const Key('chat-conversation-search-results'),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            itemCount: results.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) =>
                                ChatListEntryMotion(
                                  stateKey: 'search-${results[index].id}',
                                  index: index,
                                  child: _ConversationSearchResult(
                                    message: results[index],
                                    onOpen: () => Navigator.of(
                                      context,
                                    ).pop(results[index].id),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SafeArea(
              top: false,
              child: Padding(
                key: Key('chat-conversation-search-scope'),
                padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Text(
                  'Search covers messages currently loaded on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: MoolColors.muted, fontSize: 11.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationSearchResult extends StatelessWidget {
  const _ConversationSearchResult({
    required this.message,
    required this.onOpen,
  });

  final ChatMessage message;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final summary = _messageSearchSummary(message);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: MoolColors.line.withValues(alpha: .7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: Key('chat-conversation-search-result-${message.id}'),
        minTileHeight: 68,
        leading: CircleAvatar(
          backgroundColor: message.mine
              ? MoolColors.navy.withValues(alpha: .10)
              : MoolColors.success.withValues(alpha: .12),
          child: Icon(
            message.photo != null
                ? Icons.photo_outlined
                : message.attachmentLabel != null
                ? Icons.description_outlined
                : Icons.chat_bubble_outline_rounded,
            color: MoolColors.navy,
          ),
        ),
        title: Text(
          message.sender,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message.timeLabel,
              style: const TextStyle(color: MoolColors.muted, fontSize: 11),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _ConversationSearchIntro extends StatelessWidget {
  const _ConversationSearchIntro();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(MoolSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.manage_search_rounded,
              size: 48,
              color: MoolColors.muted,
            ),
            SizedBox(height: MoolSpacing.sm),
            Text(
              'Find a message',
              style: TextStyle(
                color: MoolColors.navy,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: MoolSpacing.xs),
            Text(
              'Search message text, senders, replies and attachment names.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MoolColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationSearchEmpty extends StatelessWidget {
  const _ConversationSearchEmpty({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MoolSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: MoolColors.muted,
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'No messages found',
              key: Key('chat-conversation-search-empty'),
              style: TextStyle(
                color: MoolColors.navy,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Try another word, sender or attachment name.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: MoolSpacing.md),
            OutlinedButton(
              key: const Key('chat-conversation-search-empty-clear'),
              onPressed: onClear,
              child: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}

String _messageSearchSummary(ChatMessage message) {
  final text = message.text.trim();
  if (text.isNotEmpty) return text;
  if (message.photo case final photo?) return 'Photo · ${photo.name}';
  if (message.attachmentLabel case final attachment?) {
    return 'Attachment · $attachment';
  }
  return 'Message';
}
