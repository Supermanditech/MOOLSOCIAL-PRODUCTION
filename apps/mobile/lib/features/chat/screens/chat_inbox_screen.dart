import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../../shared/shared_session.dart';
import '../chat_entry_context.dart';
import '../chat_models.dart';
import '../chat_session.dart';
import '../widgets/chat_widgets.dart';
import 'chat_people_directory.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({
    required this.session,
    required this.returnRoute,
    this.socialSession,
    this.initialFilter,
    this.initialTargetUserId,
    this.initialMessageDraft,
    super.key,
  });

  final ChatSession session;
  final String returnRoute;
  final SharedSession? socialSession;
  final ChatThreadType? initialFilter;
  final String? initialTargetUserId;
  final String? initialMessageDraft;

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final _searchController = TextEditingController();
  final _peopleSearchController = TextEditingController();
  int _routeRequest = 0;
  int _peopleRequest = 0;
  bool _applyingRoute = false;
  bool _loadingPeopleDirectory = false;
  String? _peopleDirectoryError;
  ChatHomeSection _section = ChatHomeSection.chats;

  ChatEntryContext get _entryContext =>
      ChatEntryContext.resolve(widget.returnRoute);

  ChatThreadType? get _effectiveInitialFilter =>
      widget.initialFilter ?? _entryContext.defaultFilter;

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
        !identical(oldWidget.socialSession, widget.socialSession) ||
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
        final filter = _effectiveInitialFilter;
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
        filter == _effectiveInitialFilter &&
        targetUserId == widget.initialTargetUserId?.trim() &&
        messageDraft == widget.initialMessageDraft &&
        returnRoute == widget.returnRoute;
  }

  @override
  void dispose() {
    _routeRequest += 1;
    _peopleRequest += 1;
    _searchController.dispose();
    _peopleSearchController.dispose();
    super.dispose();
  }

  void _selectSection(ChatHomeSection section) {
    if (_section == section) return;
    setState(() => _section = section);
    if (section != ChatHomeSection.chats) {
      unawaited(_ensurePeopleDirectory());
    }
  }

  Future<void> _ensurePeopleDirectory({bool refresh = false}) async {
    final social = widget.socialSession;
    if (social == null || !social.socialContentAvailable) {
      if (mounted) {
        setState(() {
          _loadingPeopleDirectory = false;
          _peopleDirectoryError =
              'People discovery is unavailable right now. Try again later.';
        });
      }
      return;
    }
    final request = ++_peopleRequest;
    setState(() {
      _loadingPeopleDirectory = true;
      _peopleDirectoryError = null;
    });
    try {
      if (refresh || !social.socialFeedLoaded) {
        final loaded = await social.loadSocialFeed(refresh: refresh);
        if (!loaded && social.socialPublishedItems.isEmpty) {
          throw StateError(
            social.socialFeedError ?? 'Public people could not load.',
          );
        }
      }
      if (!mounted || request != _peopleRequest) return;
      final authorIds = social.socialPublishedItems
          .map((item) => item.authorId?.trim())
          .whereType<String>()
          .where((authorId) => authorId.isNotEmpty)
          .toSet()
          .take(12)
          .toList(growable: false);
      await Future.wait(
        authorIds.map(
          (authorId) => social.loadSocialAuthor(authorId, authenticated: true),
        ),
      );
      if (!mounted || request != _peopleRequest) return;
      setState(() => _loadingPeopleDirectory = false);
    } on Object catch (error) {
      if (!mounted || request != _peopleRequest) return;
      setState(() {
        _loadingPeopleDirectory = false;
        _peopleDirectoryError = error is StateError
            ? error.message.toString()
            : 'People could not load. Check your connection and try again.';
      });
    }
  }

  List<ChatPersonEntry> _visiblePeople() {
    final social = widget.socialSession;
    if (social == null) return const [];
    final peopleById = <String, ChatPersonEntry>{};
    for (final item in social.socialPublishedItems) {
      final authorId = item.authorId?.trim();
      if (authorId == null || authorId.isEmpty) continue;
      final profile = social.socialAuthorProfile(authorId);
      if (profile?.isSelf == true) continue;
      peopleById.putIfAbsent(
        authorId,
        () => ChatPersonEntry(
          authorId: authorId,
          name: profile?.authorName ?? item.authorName,
          handle: profile?.authorHandle ?? item.authorHandle,
          profile: profile,
          loading: social.socialAuthorLoading(authorId),
          connecting: social.socialFollowBusy(authorId),
          error: social.socialAuthorError(authorId),
        ),
      );
    }
    var people = peopleById.values
        .where((person) {
          if (_section == ChatHomeSection.people && !person.connected) {
            return false;
          }
          final query = _peopleSearchController.text.trim().toLowerCase();
          if (query.isEmpty) return true;
          return person.name.toLowerCase().contains(query) ||
              person.handle.toLowerCase().contains(query);
        })
        .toList(growable: false);
    people.sort((left, right) {
      if (left.connected != right.connected) return left.connected ? -1 : 1;
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return people;
  }

  Future<void> _toggleConnection(ChatPersonEntry person) async {
    final social = widget.socialSession;
    if (social == null) return;
    var profile = social.socialAuthorProfile(person.authorId);
    if (profile == null) {
      await social.loadSocialAuthor(person.authorId, authenticated: true);
      profile = social.socialAuthorProfile(person.authorId);
    }
    if (profile == null || profile.isSelf) return;
    await social.setSocialFollow(person.authorId, !profile.followed);
  }

  Future<void> _startPersonChat(ChatPersonEntry person) async {
    final thread = await widget.session.createDirectThread(person.authorId);
    if (!mounted || thread == null) return;
    _openThread(context, thread.id, widget.returnRoute);
  }

  int get _sectionIndex => ChatHomeSection.values.indexOf(_section);

  Future<void> _handleMoreAction(String action) async {
    switch (action) {
      case 'refresh':
        if (_section == ChatHomeSection.chats) {
          await widget.session.loadThreads(refresh: true);
        } else {
          await _ensurePeopleDirectory(refresh: true);
        }
        return;
      case 'feed':
        if (mounted) context.go('/app/social?sub=feed');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listeners = <Listenable>[
      widget.session,
      if (widget.socialSession != null) widget.socialSession!,
    ];
    return AnimatedBuilder(
      animation: Listenable.merge(listeners),
      builder: (context, _) {
        final entryContext = _entryContext;
        final visibleThreads = widget.session.visibleThreads(
          _searchController.text,
        );
        final allowedThreadIds = entryContext.allowedThreadIds;
        final threads = allowedThreadIds == null
            ? visibleThreads
            : visibleThreads
                  .where((thread) => allowedThreadIds.contains(thread.id))
                  .toList(growable: false);
        final people = _visiblePeople();
        final sectionMotion = MoolMotion.accessible(
          context,
          MoolMotion.standard,
        );
        final reverseSectionMotion = MoolMotion.accessible(
          context,
          MoolMotion.quick,
        );
        return ChatPageScaffold(
          key: const Key('chat-inbox-screen'),
          session: widget.session,
          title: entryContext.title,
          subtitle: 'MoolSocial messaging',
          returnRoute: widget.returnRoute,
          titleAccent: entryContext.accent,
          prominentTitle: entryContext.id != ChatEntryContextId.workspace,
          showContentBack: true,
          backKeyName: 'chat-inbox-back',
          showMessageBanner: false,
          trailing: PopupMenuButton<String>(
            key: const Key('chat-more'),
            tooltip: 'More Chat options',
            onSelected: (value) => unawaited(_handleMoreAction(value)),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh_rounded),
                  title: Text('Refresh'),
                ),
              ),
              if (entryContext.id == ChatEntryContextId.social)
                const PopupMenuItem(
                  value: 'feed',
                  child: ListTile(
                    leading: Icon(Icons.dynamic_feed_outlined),
                    title: Text('Open public Feed'),
                  ),
                ),
            ],
            icon: const Icon(Icons.more_vert_rounded),
          ),
          floatingActionButton: FloatingActionButton(
            key: const Key('chat-new'),
            tooltip: 'Start a conversation',
            onPressed: () => _showNewChat(
              context,
              onDiscover: () => _selectSection(ChatHomeSection.discover),
            ),
            backgroundColor: MoolColors.navy,
            foregroundColor: Colors.white,
            child: const Icon(Icons.person_add_alt_1_rounded),
          ),
          bottom: NavigationBar(
            key: const Key('chat-native-navigation'),
            height: 72,
            elevation: 0,
            backgroundColor: const Color(0xFFF6F6FA),
            indicatorColor: MoolColors.navy.withValues(alpha: .10),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: _sectionIndex,
            onDestinationSelected: (index) =>
                _selectSection(ChatHomeSection.values[index]),
            destinations: [
              for (final section in ChatHomeSection.values)
                NavigationDestination(
                  key: Key('chat-section-${section.name}'),
                  icon: Icon(section.icon),
                  selectedIcon: Icon(section.selectedIcon),
                  label: section.label,
                ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: sectionMotion,
            reverseDuration: reverseSectionMotion,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(.045, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            ),
            child: switch (_section) {
              ChatHomeSection.chats => KeyedSubtree(
                key: const ValueKey('chat-section-body-chats'),
                child: _buildChats(threads),
              ),
              ChatHomeSection.people ||
              ChatHomeSection.discover => ChatPeopleDirectory(
                key: ValueKey('chat-section-body-${_section.name}'),
                section: _section,
                searchController: _peopleSearchController,
                people: people,
                loading: _loadingPeopleDirectory,
                error:
                    _peopleDirectoryError ??
                    widget.socialSession?.socialFeedError,
                onSearchChanged: (_) => setState(() {}),
                onRefresh: () => _ensurePeopleDirectory(refresh: true),
                onConnect: (person) => unawaited(_toggleConnection(person)),
                onChat: (person) => unawaited(_startPersonChat(person)),
                onDiscover: () => _selectSection(ChatHomeSection.discover),
                onOpenFeed: () => context.go('/app/social?sub=feed'),
              ),
            },
          ),
        );
      },
    );
  }

  Widget _buildChats(List<ChatThread> threads) {
    if (widget.session.loadingThreads && !widget.session.threadsLoaded) {
      return const _ChatLoadingState();
    }
    if (widget.session.errorMessage != null && threads.isEmpty) {
      return _ChatErrorState(
        message: widget.session.errorMessage!,
        onRetry: () => widget.session.loadThreads(refresh: true),
      );
    }
    return CustomScrollView(
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
                  filled: true,
                  fillColor: const Color(0xFFF0F1F5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MoolRadii.capsule),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MoolRadii.capsule),
                    borderSide: const BorderSide(
                      color: MoolColors.navy,
                      width: 1.5,
                    ),
                  ),
                  suffixIcon: IconButton(
                    key: const Key('chat-voice-search'),
                    tooltip: 'Voice search',
                    onPressed: () async {
                      final query = await _showVoiceSearch(context);
                      if (query == null || !mounted) return;
                      _searchController.text = query;
                      setState(() {});
                    },
                    icon: const Icon(Icons.mic_none_rounded),
                  ),
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              if (_entryContext.showThreadFilters) ...[
                _FilterStrip(session: widget.session),
                const SizedBox(height: MoolSpacing.sm),
              ],
            ],
          ),
        ),
        if (threads.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyInbox(
              hasQuery:
                  _searchController.text.trim().isNotEmpty ||
                  (_entryContext.showThreadFilters &&
                      widget.session.selectedFilter != null) ||
                  widget.session.unreadOnly,
              socialOnly: _entryContext.id == ChatEntryContextId.social,
              onReset: () {
                _searchController.clear();
                if (_entryContext.defaultFilter case final filter?) {
                  widget.session.chooseFilter(filter);
                } else {
                  widget.session.chooseAll();
                }
                setState(() {});
              },
              onDiscover: () => _selectSection(ChatHomeSection.discover),
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
                  const Divider(height: 1, indent: 61, color: MoolColors.line),
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
    );
  }
}

class _FilterStrip extends StatefulWidget {
  const _FilterStrip({required this.session});

  final ChatSession session;

  @override
  State<_FilterStrip> createState() => _FilterStripState();
}

class _FilterStripState extends State<_FilterStrip> {
  final _anchors = List<GlobalKey>.generate(6, (_) => GlobalKey());
  String? _revealedSelection;

  String get _selection => widget.session.unreadOnly
      ? 'Unread'
      : widget.session.selectedFilter?.label ?? 'All';

  void _scheduleSelectedReveal() {
    final selection = _selection;
    if (_revealedSelection == selection) return;
    _revealedSelection = selection;
    final index = switch (selection) {
      'All' => 0,
      'Unread' => 1,
      _ =>
        2 + ChatThreadType.values.indexWhere((type) => type.label == selection),
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index < 0 || index >= _anchors.length) return;
      final anchorContext = _anchors[index].currentContext;
      if (anchorContext == null) return;
      unawaited(
        Scrollable.ensureVisible(
          anchorContext,
          alignment: .88,
          duration: MoolMotion.accessible(context, MoolMotion.quick),
          curve: MoolMotion.enter,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final values = <(String, bool, VoidCallback)>[
      (
        'All',
        widget.session.selectedFilter == null && !widget.session.unreadOnly,
        widget.session.chooseAll,
      ),
      ('Unread', widget.session.unreadOnly, widget.session.chooseUnread),
      for (final type in ChatThreadType.values)
        (
          type.label,
          widget.session.selectedFilter == type,
          () => widget.session.chooseFilter(type),
        ),
    ];
    _scheduleSelectedReveal();
    return SizedBox(
      height: MoolMetrics.minimumTapTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: MoolSpacing.sm),
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: MoolSpacing.xs),
        itemBuilder: (context, index) => KeyedSubtree(
          key: _anchors[index],
          child: ChoiceChip(
            key: Key('chat-filter-${values[index].$1.toLowerCase()}'),
            label: Text(values[index].$1),
            selected: values[index].$2,
            showCheckmark: true,
            checkmarkColor: values[index].$2 ? Colors.white : MoolColors.navy,
            selectedColor: MoolColors.navy,
            backgroundColor: const Color(0xFFF0F1F5),
            side: BorderSide.none,
            shape: const StadiumBorder(),
            labelStyle: TextStyle(
              color: values[index].$2 ? Colors.white : MoolColors.ink,
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) => values[index].$3(),
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('chat-open-thread-${thread.id}'),
        onTap: onTap,
        overlayColor: WidgetStatePropertyAll(
          MoolColors.navy.withValues(alpha: .06),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: _threadColor(thread.type),
                child: Icon(
                  _threadIcon(thread.type),
                  size: 22,
                  color: MoolColors.navy,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MoolColors.ink,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
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
                        const SizedBox(width: 8),
                        Text(
                          thread.timeLabel,
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Badge(
                            label: Text('$unread'),
                            backgroundColor: MoolColors.success,
                            textColor: Colors.white,
                          ),
                        ],
                      ],
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

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({
    required this.hasQuery,
    required this.socialOnly,
    required this.onReset,
    required this.onDiscover,
    required this.onOpenFeed,
  });

  final bool hasQuery;
  final bool socialOnly;
  final VoidCallback onReset;
  final VoidCallback onDiscover;
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
              hasQuery
                  ? 'No matching conversations'
                  : socialOnly
                  ? 'No people conversations yet'
                  : 'No conversations yet',
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
                  : socialOnly
                  ? 'Discover a public MoolSocial profile, connect, then start a private Chat.'
                  : 'Open a public Feed profile to start a private conversation.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MoolSpacing.md),
            OutlinedButton(
              key: Key(
                hasQuery
                    ? 'chat-reset-search'
                    : socialOnly
                    ? 'chat-open-discover'
                    : 'chat-open-feed',
              ),
              onPressed: hasQuery
                  ? onReset
                  : socialOnly
                  ? onDiscover
                  : onOpenFeed,
              child: Text(
                hasQuery
                    ? 'Clear search'
                    : socialOnly
                    ? 'Discover people'
                    : 'Open Feed',
              ),
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

Future<void> _showNewChat(
  BuildContext context, {
  required VoidCallback onDiscover,
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
              'Discover a public MoolSocial profile, connect, then continue '
              'privately in Chat. Phone contacts are never uploaded.',
            ),
            const SizedBox(height: MoolSpacing.md),
            FilledButton.icon(
              key: const Key('chat-new-discover-people'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                onDiscover();
              },
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('Discover MoolSocial people'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            OutlinedButton.icon(
              key: const Key('chat-new-open-feed'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.go('/app/social?sub=feed');
              },
              icon: const Icon(Icons.dynamic_feed_outlined),
              label: const Text('Open public Feed'),
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
