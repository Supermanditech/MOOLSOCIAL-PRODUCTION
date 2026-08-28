import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../chat_session.dart';

void chatGoBack(BuildContext context, String returnRoute) {
  if (Navigator.of(context).canPop()) {
    context.pop();
    return;
  }
  context.go(returnRoute.startsWith('/app/') ? returnRoute : '/app/social');
}

String chatRoute(String path, {required String returnRoute, String? draft}) {
  return Uri(
    path: path,
    queryParameters: {
      'return': returnRoute,
      if (draft != null && draft.trim().isNotEmpty) 'draft': draft,
    },
  ).toString();
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
  final Widget? trailing;
  final Widget? bottom;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSystemInset = MediaQuery.viewPaddingOf(context).bottom;
    final bottomContentInset = keyboardInset > 0
        ? keyboardInset
        : bottomSystemInset;
    return PopScope<Object?>(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) chatGoBack(context, returnRoute);
      },
      child: RepaintBoundary(
        key: const Key('chat-page-surface'),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: backgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: prominentTitle ? 76 : 64,
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
              label: onTitleTap == null ? null : '$title. Conversation info',
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
                  child: Row(
                    children: [
                      if (titleIcon != null) ...[
                        Container(
                          key: const Key('chat-context-icon'),
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: (titleAccent ?? MoolColors.navy).withValues(
                              alpha: .10,
                            ),
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
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: MoolColors.ink,
                                fontSize: prominentTitle ? 25 : 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: prominentTitle ? -.55 : -.25,
                              ),
                            ),
                            if (subtitle.trim().isNotEmpty) ...[
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
                color: (titleAccent ?? MoolColors.navy).withValues(alpha: .12),
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
                  duration: MoolMotion.accessible(context, MoolMotion.quick),
                  curve: MoolMotion.enter,
                  padding: EdgeInsets.only(bottom: bottomContentInset),
                  child: bottom,
                ),
          floatingActionButton: floatingActionButton,
        ),
      ),
    );
  }
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
