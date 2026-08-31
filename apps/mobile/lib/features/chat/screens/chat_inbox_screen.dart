import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/universal/mool_global_navigation_v2.dart';
import '../../shared/shared_session.dart';
import '../chat_entry_context.dart';
import '../chat_models.dart';
import '../chat_session.dart';
import '../widgets/chat_motion.dart';
import '../widgets/chat_widgets.dart';
import 'chat_archived_screen.dart';
import 'chat_people_directory.dart';
import 'chat_settings_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({
    required this.session,
    required this.returnRoute,
    this.authenticated = true,
    this.onAuthenticationRequired,
    this.socialSession,
    this.initialFilter,
    this.initialTargetUserId,
    this.initialMessageDraft,
    this.initialSection = ChatHomeSection.chats,
    super.key,
  });

  final ChatSession session;
  final String returnRoute;
  final bool authenticated;
  final VoidCallback? onAuthenticationRequired;
  final SharedSession? socialSession;
  final ChatThreadType? initialFilter;
  final String? initialTargetUserId;
  final String? initialMessageDraft;
  final ChatHomeSection initialSection;

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _peopleSearchController = TextEditingController();
  int _routeRequest = 0;
  int _peopleRequest = 0;
  bool _applyingRoute = false;
  bool _loadingPeopleDirectory = false;
  String? _peopleDirectoryError;
  final Set<String> _pendingMessageRequests = <String>{};
  late ChatHomeSection _section;
  bool _publicFeedOpened = false;

  ChatEntryContext get _entryContext =>
      ChatEntryContext.resolve(widget.returnRoute);

  ChatThreadType? get _effectiveInitialFilter => widget.initialFilter;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    _searchFocusNode.addListener(_handleSearchFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _queueRouteApplication();
      if (_section != ChatHomeSection.chats) {
        unawaited(_ensurePeopleDirectory());
      }
    });
  }

  void _handleSearchFocusChange() {
    if (mounted) setState(() {});
  }

  void _clearConversationSearch() {
    if (_searchController.text.isEmpty) return;
    _searchController.clear();
    setState(() {});
  }

  void _openInlineConversationSearch() {
    _searchFocusNode.requestFocus();
  }

  void _closeInlineConversationSearch() {
    _searchFocusNode.unfocus();
  }

  @override
  void didUpdateWidget(covariant ChatInboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.session, widget.session) ||
        !identical(oldWidget.socialSession, widget.socialSession) ||
        oldWidget.initialFilter != widget.initialFilter ||
        oldWidget.initialTargetUserId != widget.initialTargetUserId ||
        oldWidget.initialMessageDraft != widget.initialMessageDraft ||
        oldWidget.initialSection != widget.initialSection ||
        oldWidget.returnRoute != widget.returnRoute) {
      if (oldWidget.initialSection != widget.initialSection) {
        _section = widget.initialSection;
        if (_section != ChatHomeSection.chats) {
          unawaited(_ensurePeopleDirectory());
        }
      }
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
    _searchFocusNode
      ..removeListener(_handleSearchFocusChange)
      ..dispose();
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
          (authorId) => social.loadSocialAuthor(
            authorId,
            authenticated: widget.authenticated,
          ),
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

  Future<void> _openPublicFeedDiscovery() async {
    if (mounted) setState(() => _publicFeedOpened = true);
    _selectSection(ChatHomeSection.discover);
    await _ensurePeopleDirectory(refresh: true);
    if (!mounted || _peopleDirectoryError != null) return;
    final social = widget.socialSession;
    if (social == null || social.socialPublishedItems.isEmpty) return;
    final chatReturn = GoRouterState.of(context).uri.toString();
    context.push(
      Uri(
        path: '/app/social',
        queryParameters: {'sub': 'feed', 'return': chatReturn},
      ).toString(),
    );
  }

  List<ChatPersonEntry> _visiblePeople() {
    final social = widget.socialSession;
    if (social == null) return const [];
    final peopleById = <String, ChatPersonEntry>{};
    for (final item in social.socialPublishedItems) {
      final authorId = item.authorId?.trim();
      if (authorId == null || authorId.isEmpty) continue;
      if (social.socialAuthorBlocked(authorId)) continue;
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
          messageRequestPending: _pendingMessageRequests.contains(authorId),
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
    if (!_requirePeopleAuthentication()) return;
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
    if (!_requirePeopleAuthentication()) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: Key('chat-message-request-dialog-${person.authorId}'),
        title: Text('Request to message ${person.name}?'),
        content: const Text(
          'They must approve before a private conversation opens. Following someone does not bypass message approval.',
        ),
        actions: [
          TextButton(
            key: const Key('chat-message-request-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            key: const Key('chat-message-request-send'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send request'),
          ),
        ],
      ),
    );
    if (!mounted || approved != true) return;
    setState(() => _pendingMessageRequests.add(person.authorId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Message request is awaiting approval. No private chat was opened.',
        ),
      ),
    );
  }

  bool _requirePeopleAuthentication() {
    if (widget.authenticated) return true;
    final callback = widget.onAuthenticationRequired;
    if (callback != null) {
      callback();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to follow people or request a conversation.'),
        ),
      );
    }
    return false;
  }

  int get _sectionIndex => ChatHomeSection.values.indexOf(_section);

  Future<void> _handleMoreAction(String action) async {
    switch (action) {
      case 'archived':
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ChatArchivedScreen(
              session: widget.session,
              originReturnRoute: widget.returnRoute,
            ),
          ),
        );
        return;
      case 'settings':
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ChatSettingsScreen(
              session: widget.session,
              originReturnRoute: widget.returnRoute,
            ),
          ),
        );
        return;
      case 'refresh':
        if (_section == ChatHomeSection.chats) {
          await widget.session.loadThreads(refresh: true);
        } else {
          await _ensurePeopleDirectory(refresh: true);
        }
        return;
      case 'feed':
        if (mounted) await _openPublicFeedDiscovery();
        return;
    }
  }

  Future<void> _showConversationActions(ChatThread thread) async {
    final action = await _chooseConversationAction(
      context,
      session: widget.session,
      thread: thread,
    );
    if (action == null || !mounted) return;
    String message;
    switch (action) {
      case _ConversationAction.pin:
        final pinned = !widget.session.isPinnedForSession(thread.id);
        widget.session.setPinnedForSession(thread.id, pinned: pinned);
        message = pinned
            ? 'Conversation pinned until you close the app.'
            : 'Conversation unpinned.';
      case _ConversationAction.attention:
        final reduced = !widget.session.hasReducedAttentionForSession(
          thread.id,
        );
        widget.session.setReducedAttentionForSession(
          thread.id,
          reduced: reduced,
        );
        message = reduced
            ? 'Attention cues reduced until you close the app.'
            : 'Standard attention cues restored.';
      case _ConversationAction.read:
        final markRead = widget.session.unreadFor(thread) > 0;
        widget.session.setReadForSession(thread.id, read: markRead);
        message = markRead
            ? 'Conversation marked read.'
            : 'Conversation marked unread.';
      case _ConversationAction.archive:
        widget.session.setArchivedForSession(thread.id, archived: true);
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar(reason: SnackBarClosedReason.remove)
          ..showSnackBar(
            SnackBar(
              key: const Key('chat-archive-feedback'),
              behavior: SnackBarBehavior.floating,
              content: const Text(
                'Conversation archived until you close the app.',
              ),
              action: SnackBarAction(
                key: const Key('chat-archive-undo'),
                label: 'Undo',
                onPressed: () => widget.session.setArchivedForSession(
                  thread.id,
                  archived: false,
                ),
              ),
            ),
          );
        return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar(reason: SnackBarClosedReason.remove)
      ..showSnackBar(
        SnackBar(
          key: const Key('chat-conversation-action-feedback'),
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
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
        final threads = visibleThreads
            .where((thread) => entryContext.allowsThread(thread.id))
            .toList(growable: false);
        final people = _visiblePeople();
        final sectionMotion = ChatMotion.resolve(
          context,
          ChatMotion.stateChange,
        );
        final reverseSectionMotion = ChatMotion.resolve(
          context,
          ChatMotion.recovery,
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
                key: Key('chat-more-settings'),
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.tune_rounded),
                  title: Text('Chat settings'),
                ),
              ),
              const PopupMenuItem(
                key: Key('chat-more-archived'),
                value: 'archived',
                child: ListTile(
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Archived conversations'),
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh_rounded),
                  title: Text('Refresh'),
                ),
              ),
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
          floatingActionButton: null,
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
            key: const Key('chat-section-motion'),
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
                authenticated: widget.authenticated,
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
                onOpenFeed: () => unawaited(_openPublicFeedDiscovery()),
                publicFeedOpened:
                    _section == ChatHomeSection.discover && _publicFeedOpened,
                onBackToChats: () => _selectSection(ChatHomeSection.chats),
              ),
            },
          ),
        );
      },
    );
  }

  Widget _buildChats(List<ChatThread> threads) {
    if (widget.session.loadingThreads && !widget.session.threadsLoaded) {
      return const ChatFiniteIncomingMotion(
        stateKey: 'chat-inbox-loading',
        child: _ChatLoadingState(),
      );
    }
    if (widget.session.errorMessage != null && threads.isEmpty) {
      return ChatFiniteIncomingMotion(
        stateKey: 'chat-inbox-error',
        child: _ChatErrorState(
          message: widget.session.errorMessage!,
          onRetry: () => widget.session.loadThreads(refresh: true),
        ),
      );
    }
    final hasSearchQuery = _searchController.text.trim().isNotEmpty;
    final searchFocused = _searchFocusNode.hasFocus;
    final searchActive = hasSearchQuery || searchFocused;
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
              ChatSearchFocusMotion(
                focused: _searchFocusNode.hasFocus,
                child: TextField(
                  key: const Key('chat-search-field'),
                  focusNode: _searchFocusNode,
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchFocusNode.unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Search conversations',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    suffixIcon: IconButton(
                      key: Key(
                        hasSearchQuery
                            ? 'chat-clear-search'
                            : searchFocused
                            ? 'chat-close-inline-search'
                            : 'chat-open-inline-search',
                      ),
                      tooltip: hasSearchQuery
                          ? 'Clear conversation search'
                          : searchFocused
                          ? 'Close conversation search'
                          : 'Search conversations',
                      onPressed: hasSearchQuery
                          ? _clearConversationSearch
                          : searchFocused
                          ? _closeInlineConversationSearch
                          : _openInlineConversationSearch,
                      icon: ChatActionIconMotion(
                        key: const Key('chat-search-action-icon-motion'),
                        stateKey: hasSearchQuery
                            ? 'clear'
                            : searchFocused
                            ? 'close'
                            : 'search',
                        icon: hasSearchQuery
                            ? Icons.close_rounded
                            : searchFocused
                            ? Icons.keyboard_hide_rounded
                            : Icons.search_rounded,
                      ),
                    ),
                  ),
                ),
              ),
              if (threads.isNotEmpty && !searchActive) ...[
                const SizedBox(height: MoolSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: const Key('chat-new'),
                    onPressed: () => _selectSection(ChatHomeSection.discover),
                    style: FilledButton.styleFrom(
                      backgroundColor: MoolColors.navy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(44, 44),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('New conversation'),
                  ),
                ),
              ],
              const SizedBox(height: MoolSpacing.sm),
              if (_entryContext.showThreadFilters && !searchActive) ...[
                _FilterStrip(session: widget.session),
                const SizedBox(height: MoolSpacing.sm),
              ],
            ],
          ),
        ),
        if (threads.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: ChatFiniteIncomingMotion(
              stateKey: hasSearchQuery
                  ? 'chat-inbox-no-search-results'
                  : 'chat-inbox-empty-${widget.session.selectedFilter?.name ?? 'all'}-${widget.session.unreadOnly}',
              child: _EmptyInbox(
                hasQuery:
                    hasSearchQuery ||
                    (_entryContext.showThreadFilters &&
                        widget.session.selectedFilter != null) ||
                    widget.session.unreadOnly,
                socialOnly: _entryContext.id == ChatEntryContextId.social,
                onReset: () {
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                  widget.session.chooseAll();
                  setState(() {});
                },
                onDiscover: () => _selectSection(ChatHomeSection.discover),
                onOpenFeed: () => unawaited(_openPublicFeedDiscovery()),
                onStartConversation: () =>
                    _selectSection(ChatHomeSection.discover),
              ),
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
              itemBuilder: (context, index) => ChatListEntryMotion(
                key: ValueKey('chat-thread-entry-motion-${threads[index].id}'),
                stateKey: threads[index].id,
                index: index,
                child: _ThreadCard(
                  thread: threads[index],
                  unread: widget.session.unreadFor(threads[index]),
                  hidePreview: widget.session.hideMessagePreviewsForSession,
                  draftSummary: widget.session.draftSummaryForSession(
                    threads[index].id,
                  ),
                  pinned: widget.session.isPinnedForSession(threads[index].id),
                  reducedAttention: widget.session
                      .hasReducedAttentionForSession(threads[index].id),
                  onMore: () =>
                      unawaited(_showConversationActions(threads[index])),
                  onTap: () => _openThread(
                    context,
                    threads[index].id,
                    widget.returnRoute,
                    draft: widget.initialMessageDraft,
                  ),
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
          child: ChatSelectionMotion(
            selected: values[index].$2,
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
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({
    required this.thread,
    required this.unread,
    required this.hidePreview,
    required this.draftSummary,
    required this.pinned,
    required this.reducedAttention,
    required this.onMore,
    required this.onTap,
  });

  final ChatThread thread;
  final int unread;
  final bool hidePreview;
  final String? draftSummary;
  final bool pinned;
  final bool reducedAttention;
  final VoidCallback onMore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('chat-open-thread-${thread.id}'),
        onTap: onTap,
        onLongPress: onMore,
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
                        if (pinned) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.push_pin_rounded,
                            size: 15,
                            color: MoolColors.navy,
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
                            draftSummary != null
                                ? hidePreview
                                      ? 'Draft saved'
                                      : 'Draft: $draftSummary'
                                : hidePreview
                                ? 'Message preview hidden'
                                : thread.preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: draftSummary != null
                                  ? MoolColors.orange
                                  : MoolColors.muted,
                              fontSize: 13,
                              fontWeight: draftSummary != null
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Semantics(
                            label: reducedAttention
                                ? '$unread unread messages, attention reduced'
                                : '$unread unread messages',
                            child: Badge(
                              label: Text('$unread'),
                              backgroundColor: reducedAttention
                                  ? MoolColors.muted
                                  : MoolColors.success,
                              textColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('chat-thread-more-${thread.id}'),
                tooltip: 'Conversation options',
                onPressed: onMore,
                icon: Icon(
                  reducedAttention
                      ? Icons.notifications_paused_outlined
                      : Icons.more_vert_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ConversationAction { pin, attention, read, archive }

Future<_ConversationAction?> _chooseConversationAction(
  BuildContext context, {
  required ChatSession session,
  required ChatThread thread,
}) {
  final pinned = session.isPinnedForSession(thread.id);
  final reducedAttention = session.hasReducedAttentionForSession(thread.id);
  final hasUnread = session.unreadFor(thread) > 0;
  final viewPadding = MediaQuery.viewPaddingOf(context);
  final bottomInset = viewPadding.bottom;
  final exportedSemanticsClearance = moolAndroidExportedSemanticsClearance(
    viewPadding: viewPadding,
    platform: Theme.of(context).platform,
  );
  return showModalBottomSheet<_ConversationAction>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    sheetAnimationStyle: ChatMotion.sheetStyle(context),
    builder: (sheetContext) => ChatBottomSheetSafeArea(
      bottomInset: bottomInset,
      exportedSemanticsClearance: exportedSemanticsClearance,
      child: Column(
        key: const Key('chat-conversation-actions'),
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text(
              'Conversation options',
              style: TextStyle(
                color: MoolColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              thread.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            key: Key('chat-action-pin-${thread.id}'),
            leading: Icon(
              pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
            ),
            title: Text(pinned ? 'Unpin conversation' : 'Pin conversation'),
            onTap: () =>
                Navigator.of(sheetContext).pop(_ConversationAction.pin),
          ),
          ListTile(
            key: Key('chat-action-attention-${thread.id}'),
            leading: Icon(
              reducedAttention
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_paused_outlined,
            ),
            title: Text(
              reducedAttention
                  ? 'Restore attention cues'
                  : 'Reduce attention cues',
            ),
            subtitle: const Text(
              'Keep unread state with a quieter visual cue.',
            ),
            onTap: () =>
                Navigator.of(sheetContext).pop(_ConversationAction.attention),
          ),
          ListTile(
            key: Key('chat-action-read-${thread.id}'),
            leading: Icon(
              hasUnread
                  ? Icons.drafts_outlined
                  : Icons.mark_email_unread_outlined,
            ),
            title: Text(hasUnread ? 'Mark as read' : 'Mark as unread'),
            onTap: () =>
                Navigator.of(sheetContext).pop(_ConversationAction.read),
          ),
          ListTile(
            key: Key('chat-action-archive-${thread.id}'),
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Archive conversation'),
            subtitle: const Text(
              'Hide it until you restore it or close MoolSocial.',
            ),
            onTap: () =>
                Navigator.of(sheetContext).pop(_ConversationAction.archive),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Text(
              'Pin, attention and archive choices reset when you close the app.',
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
  );
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({
    required this.hasQuery,
    required this.socialOnly,
    required this.onReset,
    required this.onDiscover,
    required this.onOpenFeed,
    required this.onStartConversation,
  });

  final bool hasQuery;
  final bool socialOnly;
  final VoidCallback onReset;
  final VoidCallback onDiscover;
  final VoidCallback onOpenFeed;
  final VoidCallback onStartConversation;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Align(
      alignment: keyboardVisible ? Alignment.topCenter : Alignment.center,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MoolSpacing.xl,
          keyboardVisible ? MoolSpacing.sm : MoolSpacing.xl,
          MoolSpacing.xl,
          MoolSpacing.xl,
        ),
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
            if (hasQuery || socialOnly)
              OutlinedButton(
                key: Key(hasQuery ? 'chat-reset-search' : 'chat-open-discover'),
                onPressed: hasQuery ? onReset : onDiscover,
                child: Text(hasQuery ? 'Clear search' : 'Discover people'),
              )
            else
              Transform.translate(
                offset: const Offset(0, -MoolSpacing.sm),
                child: Wrap(
                  key: const Key('chat-empty-actions'),
                  alignment: WrapAlignment.center,
                  spacing: MoolSpacing.xs,
                  runSpacing: MoolSpacing.xs,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('chat-open-feed'),
                      onPressed: onOpenFeed,
                      icon: const Icon(Icons.dynamic_feed_outlined),
                      label: const Text('Open Feed'),
                    ),
                    FilledButton.icon(
                      key: const Key('chat-empty-start'),
                      onPressed: onStartConversation,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Start conversation'),
                    ),
                  ],
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
