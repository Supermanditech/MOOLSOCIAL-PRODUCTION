import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../chat_entry_context.dart';
import '../chat_models.dart';
import '../chat_session.dart';
import '../widgets/chat_motion.dart';
import '../widgets/chat_widgets.dart';
import 'chat_privacy_screens.dart';
import 'chat_group_invites_screen.dart';
import 'chat_notification_settings_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.session.loadPrivacySettings());
      unawaited(widget.session.loadCallPreferences());
    });
  }

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

  Future<void> _savePrivacy(
    ChatPrivacySettings requested,
    String successMessage,
  ) async {
    final saved = await widget.session.updatePrivacySettings(requested);
    if (!mounted) return;
    if (saved) {
      _confirmSessionChange(successMessage);
      return;
    }
    await showChatUnavailableCapability(
      context,
      keyName: 'chat-privacy-update-recovery',
      title: 'Privacy setting unchanged',
      message:
          widget.session.privacyError ??
          'This setting could not update. Your current choice stays unchanged.',
    );
  }

  Future<void> _chooseMessagePermission() async {
    final selected = await showModalBottomSheet<ChatMessagePermission>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      sheetAnimationStyle: ChatMotion.sheetStyle(context),
      builder: (sheetContext) => SingleChildScrollView(
        child: Padding(
          key: const Key('chat-message-permission-picker'),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Who can message you',
                style: TextStyle(
                  color: MoolColors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              for (final permission in ChatMessagePermission.values)
                ListTile(
                  key: Key('chat-message-permission-${permission.name}'),
                  title: Text(_permissionLabel(permission)),
                  subtitle: Text(_permissionDescription(permission)),
                  trailing:
                      widget.session.privacySettings.whoCanMessage == permission
                      ? const Icon(
                          Icons.check_circle,
                          color: MoolColors.success,
                        )
                      : const Icon(Icons.circle_outlined),
                  onTap: () => Navigator.of(sheetContext).pop(permission),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _savePrivacy(
      widget.session.privacySettings.copyWith(whoCanMessage: selected),
      'Message permission saved.',
    );
  }

  Future<void> _saveCallPreferences(
    ChatCallPreferences requested,
    String successMessage,
  ) async {
    final saved = await widget.session.updateCallPreferences(requested);
    if (!mounted) return;
    if (saved) {
      _confirmSessionChange(successMessage);
      return;
    }
    await showChatUnavailableCapability(
      context,
      keyName: 'chat-call-settings-recovery',
      title: 'Call setting unchanged',
      message:
          widget.session.callError ??
          'This call setting could not update. Nothing changed.',
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
                              ? 'Chat is available until you close the app.'
                              : 'Chat is paused until you close the app.',
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
                        'Let people know whether they can voice call you.',
                      ),
                      value: session.globalVoiceCallsAvailableForSession,
                      onChanged: session.callLoading
                          ? null
                          : (available) => unawaited(
                              _saveCallPreferences(
                                session.callPreferences.copyWith(
                                  voiceCallsEnabled: available,
                                ),
                                available
                                    ? 'Voice calls turned on for your account.'
                                    : 'Voice calls turned off for your account.',
                              ),
                            ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('chat-settings-video-availability'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text('Video calls in this app'),
                      subtitle: const Text(
                        'Let people know whether they can video call you.',
                      ),
                      value: session.globalVideoCallsAvailableForSession,
                      onChanged: session.callLoading
                          ? null
                          : (available) => unawaited(
                              _saveCallPreferences(
                                session.callPreferences.copyWith(
                                  videoCallsEnabled: available,
                                ),
                                available
                                    ? 'Video calls turned on for your account.'
                                    : 'Video calls turned off for your account.',
                              ),
                            ),
                    ),
                    const _ChatSettingsScopeNote(
                      'Chat pause resets when you close the app. Voice and video call availability is saved to your account so callers receive the correct status.',
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
                              ? 'Send review is on across Chat until you close the app.'
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
                              ? 'Message previews are hidden until you close the app.'
                              : 'Message previews are shown.',
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
                              ? 'Suggested prompts are shown.'
                              : 'Suggested prompts are hidden until you close the app.',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _AccountSettingTile(
                      keyName: 'chat-settings-notifications',
                      icon: Icons.notifications_active_outlined,
                      title: 'Notifications and quiet hours',
                      subtitle: 'Choose alerts, previews and a quiet schedule.',
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatNotificationSettingsScreen(
                            session: session,
                            originReturnRoute: widget.originReturnRoute,
                          ),
                        ),
                      ),
                    ),
                    const _ChatSettingsScopeNote(
                      'Display and send choices reset when you close the app. Device or account notification choices change only after confirmation.',
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
                      subtitle: _permissionLabel(
                        session.privacySettings.whoCanMessage,
                      ),
                      onTap: () => unawaited(_chooseMessagePermission()),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('chat-settings-message-requests'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      secondary: const Icon(Icons.mark_email_unread_outlined),
                      title: const Text('Allow message requests'),
                      subtitle: const Text(
                        'People outside your allowed audience can request one conversation.',
                      ),
                      value: session.privacySettings.messageRequestsEnabled,
                      onChanged: session.privacyLoading
                          ? null
                          : (enabled) => unawaited(
                              _savePrivacy(
                                session.privacySettings.copyWith(
                                  messageRequestsEnabled: enabled,
                                ),
                                enabled
                                    ? 'Message requests turned on.'
                                    : 'Message requests turned off.',
                              ),
                            ),
                    ),
                    const Divider(height: 1),
                    _AccountSettingTile(
                      keyName: 'chat-settings-review-message-requests',
                      icon: Icons.inbox_outlined,
                      title: 'Review message requests',
                      subtitle: 'Accept or decline pending conversations.',
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatMessageRequestsScreen(
                            session: session,
                            originReturnRoute: widget.originReturnRoute,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _AccountSettingTile(
                      keyName: 'chat-settings-group-invites',
                      icon: Icons.group_add_outlined,
                      title: 'Group invitations',
                      subtitle: 'Review invitations before joining a group.',
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatGroupInvitesScreen(
                            session: session,
                            originReturnRoute: widget.originReturnRoute,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _AccountSettingTile(
                      keyName: 'chat-settings-blocked-accounts',
                      icon: Icons.block_outlined,
                      title: 'Blocked accounts',
                      subtitle: 'Review or unblock accounts safely.',
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatBlockedAccountsScreen(
                            session: session,
                            originReturnRoute: widget.originReturnRoute,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('chat-settings-last-seen'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      secondary: const Icon(Icons.schedule_outlined),
                      title: const Text('Share last seen'),
                      subtitle: const Text(
                        'Let eligible people see when you last used Chat.',
                      ),
                      value: session.privacySettings.shareLastSeen,
                      onChanged: session.privacyLoading
                          ? null
                          : (enabled) => unawaited(
                              _savePrivacy(
                                session.privacySettings.copyWith(
                                  shareLastSeen: enabled,
                                ),
                                enabled
                                    ? 'Last seen sharing turned on.'
                                    : 'Last seen sharing turned off.',
                              ),
                            ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('chat-settings-read-receipts'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      secondary: const Icon(Icons.done_all_rounded),
                      title: const Text('Read receipts'),
                      subtitle: const Text(
                        'Share and receive read status where permitted.',
                      ),
                      value: session.privacySettings.readReceipts,
                      onChanged: session.privacyLoading
                          ? null
                          : (enabled) => unawaited(
                              _savePrivacy(
                                session.privacySettings.copyWith(
                                  readReceipts: enabled,
                                ),
                                enabled
                                    ? 'Read receipts turned on.'
                                    : 'Read receipts turned off.',
                              ),
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

String _permissionLabel(ChatMessagePermission permission) =>
    switch (permission) {
      ChatMessagePermission.everyone => 'Everyone',
      ChatMessagePermission.connections => 'Connections only',
      ChatMessagePermission.nobody => 'No new conversations',
    };

String _permissionDescription(ChatMessagePermission permission) =>
    switch (permission) {
      ChatMessagePermission.everyone =>
        'Anyone eligible on MoolSocial can start a conversation.',
      ChatMessagePermission.connections =>
        'Only people you mutually follow can start directly.',
      ChatMessagePermission.nobody =>
        'Existing conversations stay available; no one new can start.',
    };

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
