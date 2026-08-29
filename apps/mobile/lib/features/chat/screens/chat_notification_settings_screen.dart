import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/mool_theme.dart';
import '../chat_entry_context.dart';
import '../chat_models.dart';
import '../chat_session.dart';
import '../widgets/chat_widgets.dart';

class ChatNotificationSettingsScreen extends StatefulWidget {
  const ChatNotificationSettingsScreen({
    required this.session,
    required this.originReturnRoute,
    super.key,
  });

  final ChatSession session;
  final String originReturnRoute;

  @override
  State<ChatNotificationSettingsScreen> createState() =>
      _ChatNotificationSettingsScreenState();
}

class _ChatNotificationSettingsScreenState
    extends State<ChatNotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.session.loadNotificationPreferences());
    });
  }

  Future<void> _save(ChatNotificationPreferences requested) async {
    final saved = await widget.session.updateNotificationPreferences(requested);
    if (!mounted || saved) return;
    await showChatUnavailableCapability(
      context,
      keyName: 'chat-notification-update-recovery',
      title: 'Notification setting unchanged',
      message:
          widget.session.notificationError ?? 'Nothing changed. Try again.',
    );
  }

  Future<void> _enableDevice() async {
    final saved = await widget.session.enableDeviceNotifications();
    if (!mounted || saved) return;
    await showChatUnavailableCapability(
      context,
      keyName: 'chat-notification-device-recovery',
      title: 'Device notifications remain off',
      message:
          widget.session.notificationError ??
          'Allow notifications in device settings, then try again.',
    );
  }

  Future<void> _pickQuietTime({required bool start}) async {
    final current = start
        ? widget.session.notificationPreferences.quietStartMinutes
        : widget.session.notificationPreferences.quietEndMinutes;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: start ? 'Quiet hours start' : 'Quiet hours end',
    );
    if (selected == null || !mounted) return;
    final minutes = selected.hour * 60 + selected.minute;
    await _save(
      start
          ? widget.session.notificationPreferences.copyWith(
              quietStartMinutes: minutes,
            )
          : widget.session.notificationPreferences.copyWith(
              quietEndMinutes: minutes,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = ChatEntryContext.resolve(widget.originReturnRoute);
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final session = widget.session;
        final settings = session.notificationPreferences;
        return ChatPageScaffold(
          key: const Key('chat-notification-settings-screen'),
          session: session,
          title: 'Notifications',
          subtitle: 'Quiet when you need it',
          returnRoute: chatRoute(
            '/app/chat/inbox',
            returnRoute: widget.originReturnRoute,
          ),
          showContentBack: true,
          backKeyName: 'chat-notification-settings-back',
          titleIcon: Icons.notifications_active_outlined,
          titleAccent: entry.accent,
          showMessageBanner: false,
          backgroundColor: const Color(0xFFF4F5F8),
          body: ListView(
            key: const Key('chat-notification-settings-list'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _NotificationCard(
                child: ListTile(
                  key: const Key('chat-notification-device'),
                  leading: Icon(
                    session.deviceNotificationsRegistered
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_outlined,
                    color: session.deviceNotificationsRegistered
                        ? MoolColors.success
                        : MoolColors.navy,
                  ),
                  title: Text(
                    session.deviceNotificationsRegistered
                        ? 'Enabled on this device'
                        : 'Enable on this device',
                  ),
                  subtitle: Text(
                    _permissionLabel(session.notificationPermission),
                  ),
                  trailing: session.deviceNotificationsRegistered
                      ? TextButton(
                          key: const Key('chat-notification-device-pause'),
                          onPressed: session.notificationLoading
                              ? null
                              : () => unawaited(
                                  session.disableDeviceNotifications(),
                                ),
                          child: const Text('Pause'),
                        )
                      : FilledButton(
                          key: const Key('chat-notification-device-enable'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(84, 44),
                          ),
                          onPressed: session.notificationLoading
                              ? null
                              : () => unawaited(_enableDevice()),
                          child: const Text('Enable'),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _NotificationCard(
                child: Column(
                  children: [
                    _notificationSwitch(
                      keyName: 'chat-notification-messages',
                      title: 'Message notifications',
                      value: settings.messagesEnabled,
                      onChanged: (value) =>
                          _save(settings.copyWith(messagesEnabled: value)),
                    ),
                    const Divider(height: 1),
                    _notificationSwitch(
                      keyName: 'chat-notification-calls',
                      title: 'Call notifications',
                      value: settings.callsEnabled,
                      onChanged: (value) =>
                          _save(settings.copyWith(callsEnabled: value)),
                    ),
                    const Divider(height: 1),
                    _notificationSwitch(
                      keyName: 'chat-notification-group-invites',
                      title: 'Group invitation notifications',
                      value: settings.groupInvitesEnabled,
                      onChanged: (value) =>
                          _save(settings.copyWith(groupInvitesEnabled: value)),
                    ),
                    const Divider(height: 1),
                    _notificationSwitch(
                      keyName: 'chat-notification-preview',
                      title: 'Show notification previews',
                      value: settings.showPreview,
                      onChanged: (value) =>
                          _save(settings.copyWith(showPreview: value)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _NotificationCard(
                child: Column(
                  children: [
                    _notificationSwitch(
                      keyName: 'chat-notification-quiet-hours',
                      title: 'Quiet hours',
                      subtitle:
                          'Mute routine Chat alerts during your schedule.',
                      value: settings.quietHoursEnabled,
                      onChanged: (value) =>
                          _save(settings.copyWith(quietHoursEnabled: value)),
                    ),
                    if (settings.quietHoursEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        key: const Key('chat-notification-quiet-start'),
                        title: const Text('Starts'),
                        trailing: Text(_timeLabel(settings.quietStartMinutes)),
                        onTap: () => unawaited(_pickQuietTime(start: true)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        key: const Key('chat-notification-quiet-end'),
                        title: const Text('Ends'),
                        trailing: Text(_timeLabel(settings.quietEndMinutes)),
                        onTap: () => unawaited(_pickQuietTime(start: false)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Quiet hours mute routine message and invitation alerts. Incoming call alerts follow your saved call-notification choice and device controls.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MoolColors.muted, fontSize: 11.5),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _notificationSwitch({
    required String keyName,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) => SwitchListTile.adaptive(
    key: Key(keyName),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    value: value,
    onChanged: widget.session.notificationLoading ? null : onChanged,
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: MoolColors.line.withValues(alpha: .75)),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

String _timeLabel(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _permissionLabel(ChatNotificationPermission permission) =>
    switch (permission) {
      ChatNotificationPermission.authorized => 'Device permission allowed',
      ChatNotificationPermission.provisional => 'Quiet delivery allowed',
      ChatNotificationPermission.denied => 'Off in device settings',
      ChatNotificationPermission.unknown => 'Device permission not requested',
    };
