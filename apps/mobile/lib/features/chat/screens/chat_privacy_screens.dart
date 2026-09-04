import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../chat_entry_context.dart';
import '../chat_session.dart';
import '../widgets/chat_widgets.dart';

class ChatMessageRequestsScreen extends StatefulWidget {
  const ChatMessageRequestsScreen({
    required this.session,
    required this.originReturnRoute,
    super.key,
  });

  final ChatSession session;
  final String originReturnRoute;

  @override
  State<ChatMessageRequestsScreen> createState() =>
      _ChatMessageRequestsScreenState();
}

class _ChatMessageRequestsScreenState extends State<ChatMessageRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.session.loadMessageRequests());
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = ChatEntryContext.resolve(widget.originReturnRoute);
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => ChatPageScaffold(
        key: const Key('chat-message-requests-screen'),
        session: widget.session,
        title: 'Message requests',
        subtitle: 'Choose who can reach you',
        returnRoute: chatRoute(
          '/app/chat/inbox',
          returnRoute: widget.originReturnRoute,
        ),
        showContentBack: true,
        backKeyName: 'chat-message-requests-back',
        titleIcon: Icons.mark_email_unread_outlined,
        titleAccent: entry.accent,
        showMessageBanner: false,
        backgroundColor: const Color(0xFFF4F5F8),
        body: _RequestBody(session: widget.session),
      ),
    );
  }
}

class _RequestBody extends StatelessWidget {
  const _RequestBody({required this.session});

  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    if (session.privacyLoading && session.messageRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (session.privacyError case final error?
        when session.messageRequests.isEmpty) {
      return _PrivacyRecovery(
        message: error,
        retryKey: 'chat-message-requests-retry',
        onRetry: session.loadMessageRequests,
      );
    }
    if (session.messageRequests.isEmpty) {
      return const _PrivacyEmpty(
        keyName: 'chat-message-requests-empty',
        icon: Icons.mark_email_read_outlined,
        title: 'No message requests',
        message: 'New requests from eligible people will appear here.',
      );
    }
    return ListView.separated(
      key: const Key('chat-message-requests-list'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      itemCount: session.messageRequests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final request = session.messageRequests[index];
        return Material(
          key: Key('chat-message-request-${request.thread.id}'),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: MoolColors.line.withValues(alpha: .75)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  request.thread.title,
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  request.thread.preview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: MoolColors.muted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: Key(
                          'chat-message-request-decline-${request.thread.id}',
                        ),
                        onPressed: session.privacyLoading
                            ? null
                            : () => unawaited(
                                _resolve(
                                  context,
                                  request.thread.id,
                                  accepted: false,
                                ),
                              ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        key: Key(
                          'chat-message-request-accept-${request.thread.id}',
                        ),
                        onPressed: session.privacyLoading
                            ? null
                            : () => unawaited(
                                _resolve(
                                  context,
                                  request.thread.id,
                                  accepted: true,
                                ),
                              ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _resolve(
    BuildContext context,
    String threadId, {
    required bool accepted,
  }) async {
    final saved = await session.resolveMessageRequest(
      threadId,
      accepted: accepted,
    );
    if (!context.mounted) return;
    if (!saved) {
      await showChatUnavailableCapability(
        context,
        keyName: 'chat-message-request-update-recovery',
        title: 'Request unchanged',
        message:
            session.privacyError ??
            'This request could not update. Nothing changed.',
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('chat-message-request-feedback'),
        content: Text(
          accepted ? 'Message request accepted.' : 'Message request declined.',
        ),
      ),
    );
  }
}

class ChatBlockedAccountsScreen extends StatefulWidget {
  const ChatBlockedAccountsScreen({
    required this.session,
    required this.originReturnRoute,
    super.key,
  });

  final ChatSession session;
  final String originReturnRoute;

  @override
  State<ChatBlockedAccountsScreen> createState() =>
      _ChatBlockedAccountsScreenState();
}

class _ChatBlockedAccountsScreenState extends State<ChatBlockedAccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.session.loadBlockedAccounts());
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = ChatEntryContext.resolve(widget.originReturnRoute);
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => ChatPageScaffold(
        key: const Key('chat-blocked-accounts-screen'),
        session: widget.session,
        title: 'Blocked accounts',
        subtitle: 'Your safety choices',
        returnRoute: chatRoute(
          '/app/chat/inbox',
          returnRoute: widget.originReturnRoute,
        ),
        showContentBack: true,
        backKeyName: 'chat-blocked-accounts-back',
        titleIcon: Icons.block_outlined,
        titleAccent: entry.accent,
        showMessageBanner: false,
        backgroundColor: const Color(0xFFF4F5F8),
        body: _BlockedBody(session: widget.session),
      ),
    );
  }
}

class _BlockedBody extends StatelessWidget {
  const _BlockedBody({required this.session});

  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    if (session.privacyLoading && session.blockedAccounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (session.privacyError case final error?
        when session.blockedAccounts.isEmpty) {
      return _PrivacyRecovery(
        message: error,
        retryKey: 'chat-blocked-accounts-retry',
        onRetry: session.loadBlockedAccounts,
      );
    }
    if (session.blockedAccounts.isEmpty) {
      return const _PrivacyEmpty(
        keyName: 'chat-blocked-accounts-empty',
        icon: Icons.shield_outlined,
        title: 'No blocked accounts',
        message: 'Accounts you block will appear here until you unblock them.',
      );
    }
    return ListView.separated(
      key: const Key('chat-blocked-accounts-list'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      itemCount: session.blockedAccounts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final account = session.blockedAccounts[index];
        return Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: MoolColors.line.withValues(alpha: .75)),
          ),
          child: ListTile(
            key: Key('chat-blocked-account-${account.userId}'),
            title: Text(account.name),
            subtitle: Text(account.handle),
            trailing: TextButton(
              key: Key('chat-unblock-${account.userId}'),
              onPressed: session.privacyLoading
                  ? null
                  : () => unawaited(_unblock(context, account.userId)),
              child: const Text('Unblock'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _unblock(BuildContext context, String userId) async {
    final saved = await session.setBlockedAccount(userId, blocked: false);
    if (!context.mounted || saved) return;
    await showChatUnavailableCapability(
      context,
      keyName: 'chat-unblock-recovery',
      title: 'Account remains blocked',
      message: session.privacyError ?? 'Unblocking failed. Nothing changed.',
    );
  }
}

class _PrivacyRecovery extends StatelessWidget {
  const _PrivacyRecovery({
    required this.message,
    required this.retryKey,
    required this.onRetry,
  });

  final String message;
  final String retryKey;
  final Future<bool> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(MoolSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: Key(retryKey),
            onPressed: () => unawaited(onRetry()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class _PrivacyEmpty extends StatelessWidget {
  const _PrivacyEmpty({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.message,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      key: Key(keyName),
      padding: const EdgeInsets.all(MoolSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: MoolColors.muted),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
