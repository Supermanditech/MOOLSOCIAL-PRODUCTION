import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../chat_entry_context.dart';
import '../chat_session.dart';
import '../widgets/chat_motion.dart';
import '../widgets/chat_widgets.dart';

class ChatSettingsScreen extends StatefulWidget {
  const ChatSettingsScreen({
    required this.session,
    required this.originReturnRoute,
    super.key,
  });

  final ChatSession session;
  final String originReturnRoute;

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  String? _statusMessage;

  void _confirmSessionChange(String message) {
    setState(() => _statusMessage = message);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar(reason: SnackBarClosedReason.remove)
      ..showSnackBar(
        SnackBar(
          key: const Key('chat-settings-feedback'),
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  void _showAccountRecovery({
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

  @override
  Widget build(BuildContext context) {
    final entryContext = ChatEntryContext.resolve(widget.originReturnRoute);
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final session = widget.session;
        return ChatPageScaffold(
          key: const Key('chat-settings-screen'),
          session: session,
          title: 'Chat settings',
          subtitle: 'Control your Chat experience',
          returnRoute: chatRoute(
            '/app/chat/inbox',
            returnRoute: widget.originReturnRoute,
          ),
          showContentBack: true,
          backKeyName: 'chat-settings-back',
          titleIcon: Icons.tune_rounded,
          titleAccent: entryContext.accent,
          showMessageBanner: false,
          backgroundColor: const Color(0xFFF4F5F8),
          body: ListView(
            key: const Key('chat-settings-list'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _ChatSettingsSummary(session: session),
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                ChatFiniteIncomingMotion(
                  stateKey: _statusMessage!,
                  child: _ChatSettingsStatusNotice(message: _statusMessage!),
                ),
              ],
              const SizedBox(height: 16),
              _ChatSettingsSection(
                title: 'Messages and calls',
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      key: const Key('chat-settings-chat-availability'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Chat in this app'),
                      subtitle: const Text(
                        'Pause every composer while keeping conversations readable.',
                      ),
                      value: session.globalChatAvailableForSession,
                      onChanged: (available) {
                        session.setGlobalChatAvailableForSession(
                          available: available,
                        );
                        _confirmSessionChange(
                          available
                              ? 'Chat resumed for this app session.'
                              : 'Chat paused for this app session.',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('chat-settings-voice-availability'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Voice calls in this app'),
                      subtitle: const Text(
                        'Pause the voice-call action in every conversation.',
                      ),
                      value: session.globalVoiceCallsAvailableForSession,
                      onChanged: (available) {
                        session.setGlobalVoiceCallsAvailableForSession(
                          available: available,
                        );
                        _confirmSessionChange(
                          available
                              ? 'Voice calls turned on for this app session.'
                              : 'Voice calls paused for this app session.',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('chat-settings-video-availability'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Video calls in this app'),
                      subtitle: const Text(
                        'Pause the video-call action in every conversation.',
                      ),
                      value: session.globalVideoCallsAvailableForSession,
                      onChanged: (available) {
                        session.setGlobalVideoCallsAvailableForSession(
                          available: available,
                        );
                        _confirmSessionChange(
                          available
                              ? 'Video calls turned on for this app session.'
                              : 'Video calls paused for this app session.',
                        );
                      },
                    ),
                    const _ChatSettingsScopeNote(
                      'These controls change this app session only. They do not update another person’s availability or account settings.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ChatSettingsSection(
                title: 'Peace of mind',
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      key: const Key('chat-settings-review-before-send'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Review before every send'),
                      subtitle: const Text(
                        'Confirm messages and photos before they are sent.',
                      ),
                      value: session.globalReviewBeforeSendingForSession,
                      onChanged: (enabled) {
                        session.setGlobalReviewBeforeSendingForSession(
                          enabled: enabled,
                        );
                        _confirmSessionChange(
                          enabled
                              ? 'Send review turned on across Chat for this app session.'
                              : 'Global send review turned off. Conversation choices remain.',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('chat-settings-hide-previews'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Hide message previews'),
                      subtitle: const Text(
                        'Replace message text in the Chat list until you close MoolSocial.',
                      ),
                      value: session.hideMessagePreviewsForSession,
                      onChanged: (hidden) {
                        session.setHideMessagePreviewsForSession(
                          hidden: hidden,
                        );
                        _confirmSessionChange(
                          hidden
                              ? 'Message previews hidden for this app session.'
                              : 'Message previews shown for this app session.',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('chat-settings-suggested-prompts'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Show suggested prompts'),
                      subtitle: const Text(
                        'Show quick questions in conversations that provide them.',
                      ),
                      value: session.showSuggestedPromptsForSession,
                      onChanged: (visible) {
                        session.setShowSuggestedPromptsForSession(
                          visible: visible,
                        );
                        _confirmSessionChange(
                          visible
                              ? 'Suggested prompts shown for this app session.'
                              : 'Suggested prompts hidden for this app session.',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _AccountSettingTile(
                      keyName: 'chat-settings-notifications',
                      icon: Icons.notifications_active_outlined,
                      title: 'Notifications and quiet hours',
                      subtitle:
                          'Device and account settings · current choices stay unchanged.',
                      onTap: () => _showAccountRecovery(
                        keyName: 'chat-notifications-recovery',
                        title: 'Notification settings unavailable',
                        message:
                            'Notifications and quiet hours cannot be opened right now. Your device and account choices stay unchanged. You can still quiet one conversation from the Chat list.',
                      ),
                    ),
                    const _ChatSettingsScopeNote(
                      'Local display and send controls apply only in this app session. Device or account notification choices never change without a confirmed result.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ChatSettingsSection(
                title: 'Privacy and spam',
                child: Column(
                  children: [
                    _AccountSettingTile(
                      keyName: 'chat-settings-who-can-message',
                      icon: Icons.person_search_outlined,
                      title: 'Who can message you',
                      subtitle:
                          'Account setting · current choice stays unchanged.',
                      onTap: () => _showAccountRecovery(
                        keyName: 'chat-message-permission-recovery',
                        title: 'Message permission unchanged',
                        message:
                            'Who can message you cannot be updated right now. Nothing changed. You can pause Chat in this app session or try again later.',
                      ),
                    ),
                    const Divider(height: 1),
                    _AccountSettingTile(
                      keyName: 'chat-settings-message-requests',
                      icon: Icons.mark_email_unread_outlined,
                      title: 'Message requests',
                      subtitle:
                          'Account setting · request filters are unavailable.',
                      onTap: () => _showAccountRecovery(
                        keyName: 'chat-message-requests-recovery',
                        title: 'Message requests unavailable',
                        message:
                            'Message request filters cannot be opened right now. Nothing was accepted or rejected. Try again later.',
                      ),
                    ),
                    const Divider(height: 1),
                    _AccountSettingTile(
                      keyName: 'chat-settings-blocked-accounts',
                      icon: Icons.block_outlined,
                      title: 'Blocked accounts',
                      subtitle:
                          'Account setting · blocked accounts stay unchanged.',
                      onTap: () => _showAccountRecovery(
                        keyName: 'chat-blocked-accounts-recovery',
                        title: 'Blocked accounts unavailable',
                        message:
                            'Blocked accounts cannot be loaded or changed right now. Nothing changed. Try again later.',
                      ),
                    ),
                    const Divider(height: 1),
                    _AccountSettingTile(
                      keyName: 'chat-settings-last-seen',
                      icon: Icons.schedule_outlined,
                      title: 'Share last seen',
                      subtitle:
                          'Account setting · current choice stays unchanged.',
                      onTap: () => _showAccountRecovery(
                        keyName: 'chat-settings-last-seen-recovery',
                        title: 'Last seen setting unchanged',
                        message:
                            'Last seen cannot be updated right now. Your current account choice stays unchanged. Try again later.',
                      ),
                    ),
                    const Divider(height: 1),
                    _AccountSettingTile(
                      keyName: 'chat-settings-read-receipts',
                      icon: Icons.done_all_rounded,
                      title: 'Read receipts',
                      subtitle:
                          'Account setting · current choice stays unchanged.',
                      onTap: () => _showAccountRecovery(
                        keyName: 'chat-settings-read-receipts-recovery',
                        title: 'Read receipt setting unchanged',
                        message:
                            'Read receipts cannot be updated right now. Your current account choice stays unchanged. Try again later.',
                      ),
                    ),
                    const _ChatSettingsScopeNote(
                      'Account-backed privacy and spam controls never change without a confirmed service response.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatSettingsSummary extends StatelessWidget {
  const _ChatSettingsSummary({required this.session});

  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    final messages = session.globalChatAvailableForSession
        ? 'Messages ready'
        : 'Messages paused';
    final calls = switch ((
      session.globalVoiceCallsAvailableForSession,
      session.globalVideoCallsAvailableForSession,
    )) {
      (true, true) => 'Calls ready',
      (false, false) => 'Calls paused',
      (false, true) => 'Voice paused',
      (true, false) => 'Video paused',
    };
    return Container(
      key: const Key('chat-settings-summary'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MoolColors.line.withValues(alpha: .7)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MoolColors.navy.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: MoolColors.navy,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Chat controls',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$messages · $calls',
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Session controls are private to this device.',
                  style: TextStyle(color: MoolColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatSettingsSection extends StatelessWidget {
  const _ChatSettingsSection({required this.title, required this.child});

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
              color: MoolColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
        ),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: MoolColors.line.withValues(alpha: .7)),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }
}

class _ChatSettingsScopeNote extends StatelessWidget {
  const _ChatSettingsScopeNote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F8FB),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Text(
        message,
        style: const TextStyle(
          color: MoolColors.muted,
          fontSize: 11.5,
          height: 1.35,
        ),
      ),
    );
  }
}

class _AccountSettingTile extends StatelessWidget {
  const _AccountSettingTile({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key(keyName),
      minLeadingWidth: 28,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _ChatSettingsStatusNotice extends StatelessWidget {
  const _ChatSettingsStatusNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('chat-settings-status'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7E8),
          borderRadius: BorderRadius.circular(MoolRadii.control),
          border: Border.all(color: MoolColors.success),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: MoolColors.success,
              size: 19,
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF155B17),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
