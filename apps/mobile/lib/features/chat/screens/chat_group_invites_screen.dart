import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../chat_entry_context.dart';
import '../chat_session.dart';
import '../widgets/chat_widgets.dart';

class ChatGroupInvitesScreen extends StatefulWidget {
  const ChatGroupInvitesScreen({
    required this.session,
    required this.originReturnRoute,
    super.key,
  });

  final ChatSession session;
  final String originReturnRoute;

  @override
  State<ChatGroupInvitesScreen> createState() => _ChatGroupInvitesScreenState();
}

class _ChatGroupInvitesScreenState extends State<ChatGroupInvitesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.session.loadGroupInvites());
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = ChatEntryContext.resolve(widget.originReturnRoute);
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => ChatPageScaffold(
        key: const Key('chat-group-invites-screen'),
        session: widget.session,
        title: 'Group invitations',
        subtitle: 'Choose before joining',
        returnRoute: chatRoute(
          '/app/chat/inbox',
          returnRoute: widget.originReturnRoute,
        ),
        showContentBack: true,
        backKeyName: 'chat-group-invites-back',
        titleIcon: Icons.group_add_outlined,
        titleAccent: entry.accent,
        showMessageBanner: false,
        backgroundColor: const Color(0xFFF4F5F8),
        body: widget.session.groupInvites.isEmpty
            ? const _GroupInvitesEmpty()
            : ListView.separated(
                key: const Key('chat-group-invites-list'),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                itemCount: widget.session.groupInvites.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final invite = widget.session.groupInvites[index];
                  return Material(
                    key: Key('chat-group-invite-${invite.id}'),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: MoolColors.line.withValues(alpha: .75),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            invite.groupTitle,
                            style: const TextStyle(
                              color: MoolColors.navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${invite.invitedByName} invited you.'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: Key(
                                    'chat-group-invite-decline-${invite.id}',
                                  ),
                                  onPressed: widget.session.groupLoading
                                      ? null
                                      : () => unawaited(
                                          _respond(invite.id, false),
                                        ),
                                  child: const Text('Decline'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  key: Key(
                                    'chat-group-invite-accept-${invite.id}',
                                  ),
                                  onPressed: widget.session.groupLoading
                                      ? null
                                      : () => unawaited(
                                          _respond(invite.id, true),
                                        ),
                                  child: const Text('Join group'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _respond(String inviteId, bool accepted) async {
    final saved = await widget.session.respondToGroupInvite(
      inviteId,
      accepted: accepted,
    );
    if (!mounted || saved) return;
    await showChatUnavailableCapability(
      context,
      keyName: 'chat-group-invite-response-recovery',
      title: 'Invitation unchanged',
      message: widget.session.groupError ?? 'Nothing changed. Try again.',
    );
  }
}

class _GroupInvitesEmpty extends StatelessWidget {
  const _GroupInvitesEmpty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      key: Key('chat-group-invites-empty'),
      padding: EdgeInsets.all(MoolSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups_outlined, size: 46, color: MoolColors.muted),
          SizedBox(height: 10),
          Text(
            'No group invitations',
            style: TextStyle(
              color: MoolColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Invitations appear here before you join a new group.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
