import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../chat_entry_context.dart';
import '../chat_models.dart';
import '../chat_session.dart';
import '../widgets/chat_motion.dart';
import '../widgets/chat_widgets.dart';
import 'chat_shared_content_screen.dart';

class ChatGroupInfoScreen extends StatelessWidget {
  const ChatGroupInfoScreen({
    required this.session,
    required this.threadId,
    required this.originReturnRoute,
    super.key,
  });

  final ChatSession session;
  final String threadId;
  final String originReturnRoute;

  @override
  Widget build(BuildContext context) {
    final entryContext = ChatEntryContext.resolve(originReturnRoute);
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final thread = session.thread(threadId);
        return ChatPageScaffold(
          key: const Key('chat-group-info-screen'),
          session: session,
          title: 'Group info',
          subtitle: thread.title,
          returnRoute: chatRoute(
            '/app/chat/thread/${thread.id}',
            returnRoute: originReturnRoute,
          ),
          showContentBack: true,
          backKeyName: 'chat-group-info-back',
          titleIcon: Icons.groups_2_outlined,
          titleAccent: entryContext.accent,
          showMessageBanner: false,
          backgroundColor: const Color(0xFFF4F5F8),
          body: ListView(
            key: const Key('chat-group-info-list'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              ChatFiniteIncomingMotion(
                stateKey: 'group-identity-${thread.id}',
                child: _GroupIdentityCard(thread: thread),
              ),
              const SizedBox(height: 16),
              _GroupSection(
                title: 'Group members',
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < thread.participants.length;
                      index++
                    ) ...[
                      _ParticipantTile(
                        participant: thread.participants[index],
                        onTap: () => unawaited(
                          _showParticipant(context, thread.participants[index]),
                        ),
                      ),
                      if (index < thread.participants.length - 1)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _GroupSection(
                title: 'Group actions',
                child: Column(
                  children: [
                    _GroupActionTile(
                      keyName: 'chat-group-shared-content',
                      icon: Icons.perm_media_outlined,
                      title: 'Media, files and links',
                      subtitle:
                          'Browse content currently loaded in this group.',
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatSharedContentScreen(
                            session: session,
                            threadId: thread.id,
                            originReturnRoute: originReturnRoute,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _GroupActionTile(
                      keyName: 'chat-group-invite',
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'Invite people',
                      subtitle: 'Add someone with their permission.',
                      onTap: () => _showUnchanged(
                        context,
                        keyName: 'chat-group-invite-recovery',
                        title: 'Invites unavailable',
                        message:
                            'People cannot be invited right now. The group and its members stay unchanged.',
                      ),
                    ),
                    const Divider(height: 1),
                    _GroupActionTile(
                      keyName: 'chat-group-permissions',
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Group permissions',
                      subtitle: 'Review who can manage this group.',
                      onTap: () => _showUnchanged(
                        context,
                        keyName: 'chat-group-permissions-recovery',
                        title: 'Permissions unavailable',
                        message:
                            'Group permissions cannot be loaded right now. No permission changed.',
                      ),
                    ),
                    const Divider(height: 1),
                    _GroupActionTile(
                      keyName: 'chat-group-leave',
                      icon: Icons.logout_rounded,
                      title: 'Leave group',
                      subtitle:
                          'Your membership stays active until leaving succeeds.',
                      destructive: true,
                      onTap: () => _showUnchanged(
                        context,
                        keyName: 'chat-group-leave-recovery',
                        title: 'Could not leave group',
                        message:
                            'Leaving is unavailable right now. You are still a member and can continue in Chat.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Membership and permissions are shown from the currently loaded conversation. Account-backed changes are never assumed to succeed.',
                key: Key('chat-group-scope-note'),
                textAlign: TextAlign.center,
                style: TextStyle(color: MoolColors.muted, fontSize: 11.5),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupIdentityCard extends StatelessWidget {
  const _GroupIdentityCard({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('chat-group-identity'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MoolColors.line.withValues(alpha: .75)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFFE9EDF5),
            child: Icon(Icons.groups_2_rounded, color: MoolColors.navy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${thread.participants.length} members',
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (thread.groupDescription case final description?) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: MoolColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            title,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
        ),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: MoolColors.line.withValues(alpha: .75)),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant, required this.onTap});

  final ChatParticipant participant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('chat-group-member-${participant.id}'),
      minTileHeight: MoolMetrics.minimumTapTarget,
      leading: CircleAvatar(
        backgroundColor: MoolColors.navy.withValues(alpha: .08),
        child: Text(
          participant.name.characters.first.toUpperCase(),
          style: const TextStyle(
            color: MoolColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              participant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (participant.verified) ...[
            const SizedBox(width: 5),
            const Icon(
              Icons.verified_rounded,
              size: 16,
              color: MoolColors.royal,
            ),
          ],
        ],
      ),
      subtitle: Text(
        participant.isMe
            ? 'You · ${participant.subtitle}'
            : participant.subtitle,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _GroupActionTile extends StatelessWidget {
  const _GroupActionTile({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFB3261E) : MoolColors.navy;
    return ListTile(
      key: Key(keyName),
      minTileHeight: MoolMetrics.minimumTapTarget,
      minLeadingWidth: 28,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right_rounded, color: color),
      onTap: onTap,
    );
  }
}

Future<void> _showParticipant(
  BuildContext context,
  ChatParticipant participant,
) {
  return showChatUnavailableCapability(
    context,
    keyName: 'chat-group-member-recovery-${participant.id}',
    title: participant.isMe
        ? 'This is you'
        : '${participant.name} profile unavailable',
    message: participant.isMe
        ? 'Your group membership is active. Continue in Chat to coordinate with everyone.'
        : 'This member profile cannot be opened right now. You remain in Group info and nothing changed.',
  );
}

void _showUnchanged(
  BuildContext context, {
  required String keyName,
  required String title,
  required String message,
}) {
  unawaited(
    showChatUnavailableCapability(
      context,
      keyName: keyName,
      title: title,
      message: message,
    ),
  );
}
