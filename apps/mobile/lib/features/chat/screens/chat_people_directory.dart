import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../../shared/shared_models.dart';
import '../widgets/chat_motion.dart';
import '../widgets/chat_widgets.dart';

enum ChatHomeSection { chats, people, discover }

extension ChatHomeSectionCopy on ChatHomeSection {
  String get label => switch (this) {
    ChatHomeSection.chats => 'Chats',
    ChatHomeSection.people => 'People',
    ChatHomeSection.discover => 'Discover',
  };

  IconData get icon => switch (this) {
    ChatHomeSection.chats => Icons.chat_bubble_outline_rounded,
    ChatHomeSection.people => Icons.people_outline_rounded,
    ChatHomeSection.discover => Icons.person_search_outlined,
  };

  IconData get selectedIcon => switch (this) {
    ChatHomeSection.chats => Icons.chat_bubble_rounded,
    ChatHomeSection.people => Icons.people_rounded,
    ChatHomeSection.discover => Icons.person_search_rounded,
  };
}

class ChatPersonEntry {
  const ChatPersonEntry({
    required this.authorId,
    required this.name,
    required this.handle,
    this.profile,
    this.loading = false,
    this.connecting = false,
    this.error,
  });

  final String authorId;
  final String name;
  final String handle;
  final SocialAuthorProfile? profile;
  final bool loading;
  final bool connecting;
  final String? error;

  bool get connected => profile?.followed == true;
  bool get isSelf => profile?.isSelf == true;
}

class ChatPeopleDirectory extends StatelessWidget {
  const ChatPeopleDirectory({
    required this.section,
    required this.searchController,
    required this.people,
    required this.loading,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onConnect,
    required this.onChat,
    required this.onDiscover,
    required this.onOpenFeed,
    required this.publicFeedOpened,
    required this.onBackToChats,
    this.error,
    super.key,
  });

  final ChatHomeSection section;
  final TextEditingController searchController;
  final List<ChatPersonEntry> people;
  final bool loading;
  final String? error;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final ValueChanged<ChatPersonEntry> onConnect;
  final ValueChanged<ChatPersonEntry> onChat;
  final VoidCallback onDiscover;
  final VoidCallback onOpenFeed;
  final bool publicFeedOpened;
  final VoidCallback onBackToChats;

  @override
  Widget build(BuildContext context) {
    final connectedOnly = section == ChatHomeSection.people;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        key: PageStorageKey('chat-${section.name}-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
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
                ChatFocusMotion(
                  motionKeyName: 'chat-people-search-focus-motion',
                  child: TextField(
                    key: const Key('chat-people-search'),
                    controller: searchController,
                    onChanged: onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: connectedOnly
                          ? 'Search connected people'
                          : 'Search MoolSocial people',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      suffixIcon: searchController.text.isEmpty
                          ? null
                          : IconButton(
                              key: const Key('chat-people-search-clear'),
                              tooltip: 'Clear people search',
                              onPressed: () {
                                searchController.clear();
                                onSearchChanged('');
                              },
                              icon: const ChatActionIconMotion(
                                stateKey: 'clear-people-search',
                                icon: Icons.close_rounded,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                ChatSurfaceCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: connectedOnly
                            ? const Color(0xFFE5F3E4)
                            : const Color(0xFFEDE8FF),
                        foregroundColor: MoolColors.navy,
                        child: Icon(
                          connectedOnly
                              ? Icons.people_alt_outlined
                              : Icons.travel_explore_rounded,
                        ),
                      ),
                      const SizedBox(width: MoolSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connectedOnly
                                  ? 'Your MoolSocial people'
                                  : publicFeedOpened
                                  ? 'Public Feed'
                                  : 'Discover from the public Feed',
                              style: const TextStyle(
                                color: MoolColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              connectedOnly
                                  ? 'People you connected with stay separate from shops, orders and support.'
                                  : publicFeedOpened
                                  ? 'Public profiles and conversations appear here when Feed is available.'
                                  : 'Connect with a public profile before continuing privately in Chat.',
                              style: const TextStyle(
                                color: MoolColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (error case final message?) ...[
                  const SizedBox(height: MoolSpacing.sm),
                  ChatFiniteIncomingMotion(
                    stateKey: 'chat-people-error-$message',
                    child: _PeopleNotice(message: message, onRetry: onRefresh),
                  ),
                ],
                const SizedBox(height: MoolSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        connectedOnly
                            ? 'Connected people'
                            : 'People to discover',
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${people.length}',
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
          if (loading && people.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: ChatFiniteIncomingMotion(
                stateKey: 'chat-people-loading-state',
                child: Center(
                  child: CircularProgressIndicator(
                    key: Key('chat-people-loading'),
                  ),
                ),
              ),
            )
          else if (people.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ChatFiniteIncomingMotion(
                stateKey:
                    'chat-people-empty-${section.name}-${searchController.text.trim().isNotEmpty}-$publicFeedOpened',
                child: _PeopleEmpty(
                  connectedOnly: connectedOnly,
                  hasQuery: searchController.text.trim().isNotEmpty,
                  onDiscover: onDiscover,
                  onOpenFeed: onOpenFeed,
                  publicFeedOpened: publicFeedOpened,
                  onBackToChats: onBackToChats,
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
                itemCount: people.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: MoolSpacing.xs),
                itemBuilder: (context, index) => ChatListEntryMotion(
                  key: ValueKey(
                    'chat-person-entry-motion-${people[index].authorId}',
                  ),
                  stateKey: people[index].authorId,
                  index: index,
                  child: _PersonCard(
                    person: people[index],
                    onConnect: () => onConnect(people[index]),
                    onChat: () => onChat(people[index]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.person,
    required this.onConnect,
    required this.onChat,
  });

  final ChatPersonEntry person;
  final VoidCallback onConnect;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final motionDuration = ChatMotion.resolve(context, ChatMotion.focus);
    final initials = person.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return AnimatedContainer(
      key: Key('chat-person-${person.authorId}'),
      duration: motionDuration,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: person.connected ? MoolColors.success : MoolColors.line,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFEDE8FF),
                  foregroundColor: MoolColors.navy,
                  child: Text(
                    initials.isEmpty ? 'MS' : initials,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: MoolSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              person.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: MoolColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (person.profile != null) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: MoolColors.success,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        person.handle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MoolColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (person.profile case final profile?)
                        Text(
                          '${profile.followerCount} followers',
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (person.error case final message?) ...[
              const SizedBox(height: MoolSpacing.xs),
              Text(
                message,
                style: const TextStyle(color: Color(0xFFB3261E), fontSize: 11),
              ),
            ],
            const SizedBox(height: MoolSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: Key('chat-person-connect-${person.authorId}'),
                    onPressed:
                        person.loading || person.connecting || person.isSelf
                        ? null
                        : onConnect,
                    icon: person.connecting
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            person.connected
                                ? Icons.person_remove_outlined
                                : Icons.person_add_alt_1_rounded,
                          ),
                    label: Text(person.connected ? 'Disconnect' : 'Connect'),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: FilledButton.icon(
                    key: Key('chat-person-message-${person.authorId}'),
                    onPressed: person.isSelf || !person.connected
                        ? null
                        : onChat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(person.connected ? 'Chat' : 'Connect first'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeopleNotice extends StatelessWidget {
  const _PeopleNotice({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(MoolSpacing.sm),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3F3),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFC9C9)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFFB3261E)),
        const SizedBox(width: MoolSpacing.xs),
        Expanded(child: Text(message)),
        IconButton(
          key: const Key('chat-people-retry'),
          tooltip: 'Retry people discovery',
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
  );
}

class _PeopleEmpty extends StatelessWidget {
  const _PeopleEmpty({
    required this.connectedOnly,
    required this.hasQuery,
    required this.onDiscover,
    required this.onOpenFeed,
    required this.publicFeedOpened,
    required this.onBackToChats,
  });

  final bool connectedOnly;
  final bool hasQuery;
  final VoidCallback onDiscover;
  final VoidCallback onOpenFeed;
  final bool publicFeedOpened;
  final VoidCallback onBackToChats;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(MoolSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connectedOnly
                ? Icons.people_outline_rounded
                : Icons.person_search_outlined,
            size: 48,
            color: MoolColors.muted,
          ),
          const SizedBox(height: MoolSpacing.sm),
          Text(
            hasQuery
                ? 'No matching people'
                : connectedOnly
                ? 'No connected people yet'
                : publicFeedOpened
                ? 'Public Feed unavailable'
                : 'No public people to show yet',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            connectedOnly
                ? 'Discover a public MoolSocial profile, connect, then continue privately in Chat.'
                : publicFeedOpened
                ? 'Public profiles could not load. Try again or return to conversations.'
                : 'Open Feed to discover public profiles and conversations.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MoolSpacing.md),
          if (publicFeedOpened) ...[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: [
                OutlinedButton(
                  key: const Key('chat-feed-back-to-chats'),
                  onPressed: onBackToChats,
                  child: const Text('Back to Chats'),
                ),
                FilledButton.icon(
                  key: const Key('chat-feed-retry'),
                  onPressed: onOpenFeed,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ] else
            FilledButton.icon(
              key: Key(
                connectedOnly
                    ? 'chat-people-open-discover'
                    : 'chat-discover-open-feed',
              ),
              onPressed: connectedOnly ? onDiscover : onOpenFeed,
              icon: Icon(
                connectedOnly
                    ? Icons.person_search_outlined
                    : Icons.dynamic_feed_outlined,
              ),
              label: Text(connectedOnly ? 'Discover people' : 'Open Feed'),
            ),
        ],
      ),
    ),
  );
}
