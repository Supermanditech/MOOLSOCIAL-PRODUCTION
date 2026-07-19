import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../chat_models.dart';
import '../chat_session.dart';
import '../widgets/chat_widgets.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({
    required this.session,
    required this.returnRoute,
    this.initialFilter,
    super.key,
  });

  final ChatSession session;
  final String returnRoute;
  final ChatThreadType? initialFilter;

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final filter = widget.initialFilter;
      if (filter == null) {
        widget.session.chooseAll();
      } else {
        widget.session.chooseFilter(filter);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final threads = widget.session.visibleThreads(_searchController.text);
        return ChatPageScaffold(
          key: const Key('chat-inbox-screen'),
          session: widget.session,
          title: 'Chat',
          subtitle: 'People, businesses, orders and support',
          returnRoute: widget.returnRoute,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                key: const Key('chat-open-mool'),
                tooltip: 'Open Mool',
                onPressed: () => context.go('/app/mool'),
                icon: const Icon(Icons.blur_circular_rounded),
              ),
              const SizedBox(width: MoolSpacing.xs),
              IconButton.filled(
                key: const Key('chat-new'),
                tooltip: 'Start a new chat',
                onPressed: () => _showNewChat(context, widget.session),
                icon: const Icon(Icons.edit_square),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  MoolSpacing.md,
                  MoolSpacing.xs,
                  MoolSpacing.md,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    TextField(
                      key: const Key('chat-search-field'),
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search conversations',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          key: const Key('chat-voice-search'),
                          tooltip: 'Voice search',
                          onPressed: () async {
                            final query = await _showVoiceSearch(context);
                            if (query == null || !context.mounted) return;
                            _searchController.text = query;
                            setState(() {});
                          },
                          icon: const Icon(Icons.mic_none_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    _FilterStrip(session: widget.session),
                    const SizedBox(height: MoolSpacing.sm),
                    if (widget.session.selectedFilter == null &&
                        !widget.session.unreadOnly) ...[
                      _PriorityCard(
                        onOpen: () => _openThread(
                          context,
                          'order-support',
                          widget.returnRoute,
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                    ],
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Conversations',
                            style: TextStyle(
                              color: MoolColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${threads.length}',
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                  ],
                ),
              ),
              if (threads.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyInbox(
                    onReset: () {
                      _searchController.clear();
                      widget.session.chooseAll();
                      setState(() {});
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    MoolSpacing.md,
                    0,
                    MoolSpacing.md,
                    MoolSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: threads.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MoolSpacing.xs),
                    itemBuilder: (context, index) => _ThreadCard(
                      thread: threads[index],
                      unread: widget.session.unreadFor(threads[index]),
                      onTap: () => _openThread(
                        context,
                        threads[index].id,
                        widget.returnRoute,
                      ),
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

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({required this.session});

  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    final values = <(String, bool, VoidCallback)>[
      (
        'All',
        session.selectedFilter == null && !session.unreadOnly,
        session.chooseAll,
      ),
      ('Unread', session.unreadOnly, session.chooseUnread),
      for (final type in ChatThreadType.values)
        (
          type.label,
          session.selectedFilter == type,
          () => session.chooseFilter(type),
        ),
    ];
    return SizedBox(
      height: MoolMetrics.minimumTapTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: MoolSpacing.xs),
        itemBuilder: (context, index) => ChoiceChip(
          key: Key('chat-filter-${values[index].$1.toLowerCase()}'),
          label: Text(values[index].$1),
          selected: values[index].$2,
          onSelected: (_) => values[index].$3(),
        ),
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ChatSurfaceCard(
      color: const Color(0xFFFFF1DF),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: MoolColors.orange,
            child: Icon(Icons.priority_high_rounded, color: MoolColors.ink),
          ),
          const SizedBox(width: MoolSpacing.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order problem needs your reply',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Case MS-CASE-204 · support is waiting',
                  style: TextStyle(color: MoolColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          FilledButton(
            key: const Key('chat-open-priority'),
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              minimumSize: const Size(72, MoolMetrics.minimumTapTarget),
            ),
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({
    required this.thread,
    required this.unread,
    required this.onTap,
  });

  final ChatThread thread;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChatSurfaceCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        key: Key('chat-open-thread-${thread.id}'),
        onTap: onTap,
        minTileHeight: 78,
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: _threadColor(thread.type),
          child: Icon(_threadIcon(thread.type), color: MoolColors.navy),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                thread.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (thread.verified) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: MoolColors.success,
              ),
            ],
          ],
        ),
        subtitle: Text(
          thread.preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              thread.timeLabel,
              style: const TextStyle(
                color: MoolColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            if (unread > 0)
              Badge(
                label: Text('$unread'),
                backgroundColor: MoolColors.orange,
                textColor: MoolColors.ink,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mark_chat_unread_outlined,
              size: 48,
              color: MoolColors.muted,
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'No matching conversations',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Clear the search or show every conversation.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MoolSpacing.md),
            OutlinedButton(
              key: const Key('chat-reset-search'),
              onPressed: onReset,
              child: const Text('Show all conversations'),
            ),
          ],
        ),
      ),
    );
  }
}

void _openThread(BuildContext context, String threadId, String returnRoute) {
  context.go(chatRoute('/app/chat/thread/$threadId', returnRoute: returnRoute));
}

Future<void> _showNewChat(BuildContext context, ChatSession session) {
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
              'Start a conversation',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            for (final type in ChatThreadType.values)
              ListTile(
                key: Key('chat-new-${type.name}'),
                leading: Icon(_threadIcon(type), color: MoolColors.navy),
                title: Text(type.label),
                subtitle: Text(_newChatDetail(type)),
                onTap: () {
                  session.chooseFilter(type);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

Future<String?> _showVoiceSearch(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  var query = '';
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MediaQuery.viewInsetsOf(sheetContext).bottom + MoolSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Find a conversation',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text('Speak or type a person, business, order or case.'),
          const SizedBox(height: MoolSpacing.md),
          Form(
            key: formKey,
            child: TextFormField(
              key: const Key('chat-voice-search-field'),
              onChanged: (value) => query = value,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a conversation name.'
                  : null,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mic_none_rounded),
                labelText: 'Conversation name',
              ),
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton(
            key: const Key('chat-use-voice-search'),
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.of(sheetContext).pop(query.trim());
            },
            child: const Text('Search conversations'),
          ),
        ],
      ),
    ),
  );
}

Color _threadColor(ChatThreadType type) => switch (type) {
  ChatThreadType.people => const Color(0xFFEDE8FF),
  ChatThreadType.business => const Color(0xFFE5F3E4),
  ChatThreadType.order => const Color(0xFFFFEDDA),
  ChatThreadType.support => const Color(0xFFE3F1FF),
};

IconData _threadIcon(ChatThreadType type) => switch (type) {
  ChatThreadType.people => Icons.people_outline_rounded,
  ChatThreadType.business => Icons.storefront_outlined,
  ChatThreadType.order => Icons.shopping_bag_outlined,
  ChatThreadType.support => Icons.support_agent_rounded,
};

String _newChatDetail(ChatThreadType type) => switch (type) {
  ChatThreadType.people => 'Find a person or create a group',
  ChatThreadType.business => 'Message a shop or service',
  ChatThreadType.order => 'Open a conversation linked to an order',
  ChatThreadType.support => 'Continue a case or ask for help',
};
