import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/universal/mool_global_navigation_v2.dart';
import '../chat_models.dart';
import '../chat_session.dart';
import 'chat_motion.dart';

void chatGoBack(BuildContext context, String returnRoute) {
  if (Navigator.of(context).canPop()) {
    context.pop();
    return;
  }
  context.go(returnRoute.startsWith('/app/') ? returnRoute : '/app/social');
}

String chatRoute(
  String path, {
  required String returnRoute,
  String? draft,
  String? filter,
}) {
  return Uri(
    path: path,
    queryParameters: {
      'return': returnRoute,
      if (draft != null && draft.trim().isNotEmpty) 'draft': draft,
      if (filter != null && filter.trim().isNotEmpty) 'type': filter,
    },
  ).toString();
}

Future<void> showChatUnavailableCapability(
  BuildContext context, {
  required String keyName,
  required String title,
  required String message,
}) {
  final viewPadding = MediaQuery.viewPaddingOf(context);
  final bottomInset = viewPadding.bottom;
  final exportedSemanticsClearance = moolAndroidExportedSemanticsClearance(
    viewPadding: viewPadding,
    platform: Theme.of(context).platform,
  );
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    sheetAnimationStyle: ChatMotion.sheetStyle(context),
    builder: (sheetContext) => ChatBottomSheetSafeArea(
      bottomInset: bottomInset,
      exportedSemanticsClearance: exportedSemanticsClearance,
      child: Padding(
        key: Key(keyName),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.lg,
          MoolSpacing.xs,
          MoolSpacing.lg,
          MoolSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            Text(message, style: const TextStyle(color: MoolColors.muted)),
            const SizedBox(height: MoolSpacing.md),
            FilledButton(
              key: const Key('chat-capability-continue'),
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Continue in Chat'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ChatBottomSheetSafeArea extends StatelessWidget {
  const ChatBottomSheetSafeArea({
    required this.bottomInset,
    required this.exportedSemanticsClearance,
    required this.child,
    super.key,
  });

  final double bottomInset;
  final double exportedSemanticsClearance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final baseBottomPadding = bottomInset > MoolSpacing.md
        ? bottomInset
        : MoolSpacing.md;
    final bottomPadding = baseBottomPadding + exportedSemanticsClearance;
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: child,
      ),
    );
  }
}

class ChatPageScaffold extends StatelessWidget {
  const ChatPageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.returnRoute,
    required this.body,
    this.showContentBack = false,
    this.backKeyName = 'chat-back',
    this.showMessageBanner = true,
    this.prominentTitle = false,
    this.titleIcon,
    this.titleAccent,
    this.onTitleTap,
    this.backgroundColor = MoolColors.canvas,
    this.messageThreadId,
    this.onBlockedPop,
    this.trailing,
    this.bottom,
    this.floatingActionButton,
    super.key,
  });

  final ChatSession session;
  final String title;
  final String subtitle;
  final String returnRoute;
  final Widget body;
  final bool showContentBack;
  final String backKeyName;
  final bool showMessageBanner;
  final bool prominentTitle;
  final IconData? titleIcon;
  final Color? titleAccent;
  final VoidCallback? onTitleTap;
  final Color backgroundColor;
  final String? messageThreadId;
  final bool Function()? onBlockedPop;
  final Widget? trailing;
  final Widget? bottom;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final bottomSystemInset = viewPadding.bottom;
    final exportedSemanticsClearance = moolAndroidExportedSemanticsClearance(
      viewPadding: viewPadding,
      platform: Theme.of(context).platform,
    );
    final bottomContentInset = keyboardInset > 0
        ? keyboardInset
        : bottomSystemInset + exportedSemanticsClearance;
    return _ChatPresenceLifecycle(
      session: session,
      child: PopScope<Object?>(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (onBlockedPop?.call() ?? false) return;
          chatGoBack(context, returnRoute);
        },
        child: ChatRouteEntryMotion(
          key: const Key('chat-route-entry-motion'),
          stateKey: '$title|$returnRoute',
          child: RepaintBoundary(
            key: const Key('chat-page-surface'),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: backgroundColor,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                toolbarHeight: prominentTitle
                    ? 76
                    : trailing != null
                    ? 82
                    : 64,
                backgroundColor: MoolColors.canvas,
                surfaceTintColor: Colors.transparent,
                leadingWidth: showContentBack ? 52 : 0,
                leading: showContentBack
                    ? MoolNativeBackButton(
                        keyName: backKeyName,
                        onPressed: () => chatGoBack(context, returnRoute),
                      )
                    : null,
                titleSpacing: showContentBack ? 0 : MoolSpacing.md,
                title: Semantics(
                  header: true,
                  button: onTitleTap != null,
                  label: onTitleTap == null
                      ? null
                      : '$title. Conversation info',
                  child: InkWell(
                    key: onTitleTap == null
                        ? null
                        : const Key('chat-conversation-info'),
                    onTap: onTitleTap,
                    borderRadius: BorderRadius.circular(MoolRadii.control),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: MoolMetrics.minimumTapTarget,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 180;
                          final showIcon = titleIcon != null && !compact;
                          final showSubtitle = subtitle.trim().isNotEmpty;
                          return Row(
                            children: [
                              if (showIcon) ...[
                                Container(
                                  key: const Key('chat-context-icon'),
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: (titleAccent ?? MoolColors.navy)
                                        .withValues(alpha: .10),
                                    borderRadius: BorderRadius.circular(
                                      MoolRadii.control,
                                    ),
                                  ),
                                  child: Icon(
                                    titleIcon,
                                    size: 20,
                                    color: titleAccent ?? MoolColors.navy,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      key: const Key('chat-page-title'),
                                      title,
                                      maxLines: compact ? 2 : 1,
                                      overflow: compact
                                          ? TextOverflow.clip
                                          : TextOverflow.ellipsis,
                                      softWrap: compact,
                                      style: TextStyle(
                                        color: MoolColors.ink,
                                        fontSize: compact
                                            ? 15
                                            : prominentTitle
                                            ? 25
                                            : trailing != null &&
                                                  title.length > 14
                                            ? 17
                                            : 19,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: prominentTitle
                                            ? -.55
                                            : -.25,
                                      ),
                                    ),
                                    if (showSubtitle) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: MoolColors.muted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (trailing != null)
                    Padding(
                      padding: const EdgeInsets.only(right: MoolSpacing.sm),
                      child: trailing!,
                    ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(
                    key: const Key('chat-moolsocial-divider'),
                    height: 1,
                    thickness: 1,
                    color: (titleAccent ?? MoolColors.navy).withValues(
                      alpha: .12,
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: MoolMetrics.maximumContentWidth,
                    ),
                    child: Column(
                      children: [
                        if (showMessageBanner)
                          ChatMessageBanner(
                            session: session,
                            threadId: messageThreadId,
                          ),
                        if (session.incomingCalls.isNotEmpty)
                          _ChatIncomingCallBanner(
                            session: session,
                            call: session.incomingCalls.first,
                          ),
                        if (session.activeCall case final call?
                            when call.status == ChatCallStatus.accepted)
                          _ChatActiveCallBanner(session: session, call: call),
                        Expanded(child: body),
                      ],
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: bottom == null
                  ? null
                  : AnimatedPadding(
                      key: const Key('chat-keyboard-safe-bottom'),
                      duration: MoolMotion.accessible(
                        context,
                        MoolMotion.quick,
                      ),
                      curve: MoolMotion.enter,
                      padding: EdgeInsets.only(bottom: bottomContentInset),
                      child: bottom,
                    ),
              floatingActionButton: floatingActionButton,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatPresenceLifecycle extends StatefulWidget {
  const _ChatPresenceLifecycle({required this.session, required this.child});

  final ChatSession session;
  final Widget child;

  @override
  State<_ChatPresenceLifecycle> createState() => _ChatPresenceLifecycleState();
}

class _ChatIncomingCallBanner extends StatelessWidget {
  const _ChatIncomingCallBanner({required this.session, required this.call});

  final ChatSession session;
  final ChatCall call;

  @override
  Widget build(BuildContext context) {
    final thread = session.thread(call.threadId);
    final label = call.kind == ChatCallKind.voice ? 'Voice' : 'Video';
    return Material(
      key: const Key('chat-incoming-call'),
      color: const Color(0xFFEAF7E8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.call_received_rounded,
                  color: MoolColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$label call from ${thread.title}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('chat-incoming-decline'),
                  onPressed: session.callLoading
                      ? null
                      : () => unawaited(
                          session.respondToCall(call.id, accepted: false),
                        ),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('chat-incoming-accept'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(88, 44),
                  ),
                  onPressed: session.callLoading
                      ? null
                      : () => unawaited(
                          session.respondToCall(call.id, accepted: true),
                        ),
                  child: const Text('Answer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatActiveCallBanner extends StatelessWidget {
  const _ChatActiveCallBanner({required this.session, required this.call});

  final ChatSession session;
  final ChatCall call;

  @override
  Widget build(BuildContext context) => Material(
    key: const Key('chat-active-call'),
    color: const Color(0xFFEAF7E8),
    child: ListTile(
      dense: true,
      leading: const Icon(Icons.graphic_eq_rounded, color: MoolColors.success),
      title: Text(
        '${call.kind == ChatCallKind.voice ? 'Voice' : 'Video'} call connected',
      ),
      trailing: TextButton.icon(
        key: const Key('chat-active-call-end'),
        onPressed: session.callLoading
            ? null
            : () => unawaited(session.endCall()),
        icon: const Icon(Icons.call_end_rounded),
        label: const Text('End'),
      ),
    ),
  );
}

class _ChatPresenceLifecycleState extends State<_ChatPresenceLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.session.updatePresence(ChatPresenceState.active));
        unawaited(widget.session.loadIncomingCalls());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final presence = switch (state) {
      AppLifecycleState.resumed => ChatPresenceState.active,
      AppLifecycleState.detached => ChatPresenceState.offline,
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused => ChatPresenceState.background,
    };
    unawaited(widget.session.updatePresence(presence));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class ChatMessageBanner extends StatelessWidget {
  const ChatMessageBanner({required this.session, this.threadId, super.key});

  final ChatSession session;
  final String? threadId;

  @override
  Widget build(BuildContext context) {
    final error = threadId == null
        ? session.errorMessage
        : session.threadActionError(threadId!);
    final notice = threadId == null
        ? session.noticeMessage
        : session.threadActionNotice(threadId!);
    if (error == null && notice == null) return const SizedBox.shrink();
    final isError = error != null;
    return Semantics(
      liveRegion: true,
      child: ChatFiniteIncomingMotion(
        stateKey: '${isError ? 'error' : 'notice'}-${error ?? notice}',
        child: Container(
          key: Key(isError ? 'chat-error' : 'chat-notice'),
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            0,
            MoolSpacing.md,
            MoolSpacing.xs,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MoolSpacing.sm,
            vertical: MoolSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFFFEBEA) : const Color(0xFFEAF7E8),
            borderRadius: BorderRadius.circular(MoolRadii.control),
            border: Border.all(
              color: isError ? const Color(0xFFD3322F) : MoolColors.success,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: isError ? const Color(0xFFB42318) : MoolColors.success,
                size: 19,
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Text(
                  error ?? notice!,
                  style: TextStyle(
                    color: isError
                        ? const Color(0xFF7A271A)
                        : const Color(0xFF155B17),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: const Key('dismiss-chat-message'),
                tooltip: 'Dismiss message',
                onPressed: threadId == null
                    ? session.clearMessages
                    : () => session.clearThreadMessages(threadId!),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatSurfaceCard extends StatelessWidget {
  const ChatSurfaceCard({
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(MoolSpacing.md),
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return MoolCardSurface(color: color, padding: padding, child: child);
  }
}
