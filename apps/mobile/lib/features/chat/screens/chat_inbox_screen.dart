import 'dart:async';

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
    this.initialTargetUserId,
    this.initialMessageDraft,
    super.key,
  });

  final ChatSession session;
  final String returnRoute;
  final ChatThreadType? initialFilter;
  final String? initialTargetUserId;
  final String? initialMessageDraft;

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final _searchController = TextEditingController();
  int _routeRequest = 0;
  bool _applyingRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _queueRouteApplication();
    });
  }

  @override
  void didUpdateWidget(covariant ChatInboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.session, widget.session) ||
        oldWidget.initialFilter != widget.initialFilter ||
        oldWidget.initialTargetUserId != widget.initialTargetUserId ||
        oldWidget.initialMessageDraft != widget.initialMessageDraft ||
        oldWidget.returnRoute != widget.returnRoute) {
      _queueRouteApplication();
    }
  }

  void _queueRouteApplication() {
    _routeRequest += 1;
    if (!_applyingRoute) unawaited(_applyLatestRoute());
  }

  Future<void> _applyLatestRoute() async {
    if (_applyingRoute) return;
    _applyingRoute = true;
    try {
      while (mounted) {
        final request = _routeRequest;
        final session = widget.session;
        final filter = widget.initialFilter;
        final targetUserId = widget.initialTargetUserId?.trim();
        final messageDraft = widget.initialMessageDraft;
        final returnRoute = widget.returnRoute;
        if (filter == null) {
          session.chooseAll();
        } else {
          session.chooseFilter(filter);
        }
        await session.loadThreads(refresh: true);
        if (!_routeIsCurrent(
          request: request,
          session: session,
          filter: filter,
          targetUserId: targetUserId,
          messageDraft: messageDraft,
          returnRoute: returnRoute,
        )) {
          continue;
        }
        if (targetUserId == null || targetUserId.isEmpty) return;
        final thread = await session.createDirectThread(targetUserId);
        if (!_routeIsCurrent(
          request: request,
          session: session,
          filter: filter,
          targetUserId: targetUserId,
          messageDraft: messageDraft,
          returnRoute: returnRoute,
        )) {
          continue;
        }
        if (!mounted) return;
        if (thread != null) {
          _openThread(context, thread.id, returnRoute, draft: messageDraft);
        }
        return;
      }
    } finally {
      _applyingRoute = false;
    }
  }

  bool _routeIsCurrent({
    required int request,
    required ChatSession session,
    required ChatThreadType? filter,
    required String? targetUserId,
    required String? messageDraft,
    required String returnRoute,
  }) {
    return mounted &&
        request == _routeRequest &&
        identical(session, widget.session) &&
        filter == widget.initialFilter &&
        targetUserId == widget.initialTargetUserId?.trim() &&
        messageDraft == widget.initialMessageDraft &&
        returnRoute == widget.returnRoute;
  }

  @override
  void dispose() {
    _routeRequest += 1;
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
          showContentBack: true,
          backKey: const Key('chat-inbox-back'),
          backTooltip: 'Back to previous screen',
          trailing: IconButton.filled(
            key: const Key('chat-new'),
            tooltip: 'Start a new chat',
            style: IconButton.styleFrom(
              backgroundColor: MoolColors.navy,
              foregroundColor: Colors.white,
              minimumSize: const Size.square(MoolMetrics.compactTapTarget),
              disabledBackgroundColor: MoolColors.navy.withValues(alpha: .38),
              disabledForegroundColor: Colors.white.withValues(alpha: .72),
            ),
            onPressed: () => _showNewChat(context, widget.session),
            icon: const Icon(Icons.edit_square),
          ),
          body: widget.session.loadingThreads && !widget.session.threadsLoaded
              ? const _ChatLoadingState()
              : widget.session.errorMessage != null && threads.isEmpty
              ? _ChatErrorState(
                  message: widget.session.errorMessage!,
                  onRetry: () => widget.session.loadThreads(refresh: true),
                )
              : CustomScrollView(
                  key: const PageStorageKey('chat-inbox-scroll'),
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
                          hasQuery:
                              _searchController.text.trim().isNotEmpty ||
                              widget.session.selectedFilter != null ||
                              widget.session.unreadOnly,
                          onReset: () {
                            _searchController.clear();
                            widget.session.chooseAll();
                            setState(() {});
                          },
                          onOpenFeed: () => context.go('/app/social?sub=feed'),
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
                              draft: widget.initialMessageDraft,
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
  const _EmptyInbox({
    required this.hasQuery,
    required this.onReset,
    required this.onOpenFeed,
  });

  final bool hasQuery;
  final VoidCallback onReset;
  final VoidCallback onOpenFeed;

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
            Text(
              hasQuery ? 'No matching conversations' : 'No conversations yet',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            Text(
              hasQuery
                  ? 'Clear the search or show every conversation.'
                  : 'Open a public Feed profile to start a private conversation.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MoolSpacing.md),
            OutlinedButton(
              key: Key(hasQuery ? 'chat-reset-search' : 'chat-open-feed'),
              onPressed: hasQuery ? onReset : onOpenFeed,
              child: Text(hasQuery ? 'Show all conversations' : 'Open Feed'),
            ),
          ],
        ),
      ),
    );
  }
}

void _openThread(
  BuildContext context,
  String threadId,
  String returnRoute, {
  String? draft,
}) {
  context.push(
    chatRoute(
      '/app/chat/thread/$threadId',
      returnRoute: returnRoute,
      draft: draft,
    ),
  );
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
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Open a public MoolSocial post, choose its author, then start Chat. '
              'This prevents unsolicited contact and keeps the recipient clear.',
            ),
            const SizedBox(height: MoolSpacing.md),
            FilledButton.icon(
              key: const Key('chat-new-open-feed'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.go('/app/social?sub=feed');
              },
              icon: const Icon(Icons.dynamic_feed_outlined),
              label: const Text('Open Feed'),
            ),
            TextButton(
              key: const Key('chat-new-cancel'),
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Cancel'),
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

class _ChatLoadingState extends StatelessWidget {
  const _ChatLoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: MoolSpacing.sm),
        Text('Loading conversations'),
      ],
    ),
  );
}

class _ChatErrorState extends StatelessWidget {
  const _ChatErrorState({required this.message, required this.onRetry});

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
            'Chat could not load',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: MoolSpacing.md),
          FilledButton.icon(
            key: const Key('chat-retry-load'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
