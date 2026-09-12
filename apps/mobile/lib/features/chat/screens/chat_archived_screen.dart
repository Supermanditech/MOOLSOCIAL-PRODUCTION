import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../chat_entry_context.dart';
import '../chat_models.dart';
import '../chat_session.dart';
import '../widgets/chat_motion.dart';
import '../widgets/chat_widgets.dart';
import 'chat_thread_screen.dart';

class ChatArchivedScreen extends StatelessWidget {
  const ChatArchivedScreen({
    required this.session,
    required this.originReturnRoute,
    super.key,
  });

  final ChatSession session;
  final String originReturnRoute;

  @override
  Widget build(BuildContext context) {
    final entryContext = ChatEntryContext.resolve(originReturnRoute);
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final threads = session
            .archivedThreads()
            .where((thread) => entryContext.allowsThread(thread.id))
            .toList(growable: false);
        return ChatPageScaffold(
          key: const Key('chat-archived-screen'),
          session: session,
          title: 'Archived conversations',
          subtitle: 'Hidden until you close the app',
          returnRoute: chatRoute(
            '/app/chat/inbox',
            returnRoute: originReturnRoute,
          ),
          showContentBack: true,
          backKeyName: 'chat-archived-back',
          titleIcon: Icons.archive_outlined,
          titleAccent: entryContext.accent,
          showMessageBanner: false,
          backgroundColor: const Color(0xFFF4F5F8),
          body: threads.isEmpty
              ? _ArchivedEmptyState(
                  onBack: () => chatGoBack(
                    context,
                    chatRoute(
                      '/app/chat/inbox',
                      returnRoute: originReturnRoute,
                    ),
                  ),
                )
              : ListView.separated(
                  key: const Key('chat-archived-list'),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  itemCount: threads.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => ChatListEntryMotion(
                    stateKey: 'archived-${threads[index].id}',
                    index: index,
                    child: _ArchivedConversationCard(
                      thread: threads[index],
                      unread: session.unreadFor(threads[index]),
                      onOpen: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatThreadScreen(
                            session: session,
                            threadId: threads[index].id,
                            returnRoute: originReturnRoute,
                          ),
                        ),
                      ),
                      onRestore: () => session.setArchivedForSession(
                        threads[index].id,
                        archived: false,
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _ArchivedConversationCard extends StatelessWidget {
  const _ArchivedConversationCard({
    required this.thread,
    required this.unread,
    required this.onOpen,
    required this.onRestore,
  });

  final ChatThread thread;
  final int unread;
  final VoidCallback onOpen;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: MoolColors.line.withValues(alpha: .7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('chat-archived-open-${thread.id}'),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _archivedThreadIcon(thread.type),
                  color: MoolColors.navy,
                  size: 22,
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
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (unread > 0)
                          Badge(
                            label: Text('$unread'),
                            backgroundColor: MoolColors.muted,
                            textColor: Colors.white,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      thread.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: Key('chat-archived-restore-${thread.id}'),
                onPressed: onRestore,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(76, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Restore'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchivedEmptyState extends StatelessWidget {
  const _ArchivedEmptyState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MoolSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 46,
              color: MoolColors.muted,
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'No archived conversations',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MoolColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Conversations archived until you close the app will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: MoolSpacing.md),
            FilledButton(
              key: const Key('chat-archived-empty-back'),
              onPressed: onBack,
              child: const Text('Back to Chat'),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _archivedThreadIcon(ChatThreadType type) => switch (type) {
  ChatThreadType.people => Icons.person_outline_rounded,
  ChatThreadType.business => Icons.storefront_outlined,
  ChatThreadType.order => Icons.local_shipping_outlined,
  ChatThreadType.support => Icons.support_agent_rounded,
};
