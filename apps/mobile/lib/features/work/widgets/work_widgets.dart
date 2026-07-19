import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../work_session.dart';

class WorkPageScaffold extends StatelessWidget {
  const WorkPageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.body,
    this.fallbackBackRoute = '/app/work/earn',
    this.showBack = true,
    this.activeDock = 'earn',
    this.trailing,
    this.bottomAction,
    super.key,
  });

  final WorkSession session;
  final String title;
  final String subtitle;
  final Widget body;
  final String fallbackBackRoute;
  final bool showBack;
  final String activeDock;
  final Widget? trailing;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MoolColors.canvas,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        leadingWidth: showBack ? 64 : 16,
        leading: showBack
            ? Padding(
                padding: const EdgeInsets.only(left: MoolSpacing.sm),
                child: IconButton.outlined(
                  key: const Key('work-back'),
                  tooltip: 'Go back',
                  onPressed: () {
                    session.clearMessages();
                    context.go(fallbackBackRoute);
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                ),
              )
            : null,
        titleSpacing: showBack ? 4 : MoolSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -.35,
              ),
            ),
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
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: MoolSpacing.sm),
            child:
                trailing ??
                IconButton.outlined(
                  key: const Key('work-help'),
                  tooltip: 'Work help',
                  onPressed: () => session.showNotice(
                    'Work help is ready. Your opportunity and setup progress remain saved.',
                  ),
                  icon: const Icon(Icons.support_agent_outlined),
                ),
          ),
        ],
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
                WorkMessageBanner(session: session),
                Expanded(child: body),
                if (bottomAction != null)
                  Material(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        MoolSpacing.md,
                        MoolSpacing.sm,
                        MoolSpacing.md,
                        MoolSpacing.xs,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: bottomAction,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: WorkBottomDock(session: session, active: activeDock),
    );
  }
}

class WorkMessageBanner extends StatelessWidget {
  const WorkMessageBanner({required this.session, super.key});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final error = session.errorMessage;
    final notice = session.noticeMessage;
    if (error == null && notice == null) return const SizedBox.shrink();
    final isError = error != null;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key(isError ? 'work-error' : 'work-notice'),
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
              key: const Key('dismiss-work-message'),
              tooltip: 'Dismiss message',
              visualDensity: VisualDensity.compact,
              onPressed: session.dismissMessages,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkCard extends StatelessWidget {
  const WorkCard({
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(MoolSpacing.md),
    this.onTap,
    this.keyName,
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    return MoolCardSurface(
      key: keyName == null ? null : Key(keyName!),
      color: color,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

class WorkSectionTitle extends StatelessWidget {
  const WorkSectionTitle({
    required this.title,
    required this.detail,
    this.trailing,
    super.key,
  });

  final String title;
  final String detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: MoolSpacing.xs),
          trailing!,
        ],
      ],
    );
  }
}

class WorkPrimaryButton extends StatelessWidget {
  const WorkPrimaryButton({
    required this.keyName,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.busy = false,
    super.key,
  });

  final String keyName;
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: Key(keyName),
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}

class WorkPill extends StatelessWidget {
  const WorkPill({
    required this.label,
    this.color = MoolColors.success,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MoolSpacing.xs,
        vertical: MoolSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(MoolRadii.capsule),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkBottomDock extends StatelessWidget {
  const WorkBottomDock({
    required this.session,
    required this.active,
    super.key,
  });

  final WorkSession session;
  final String active;

  @override
  Widget build(BuildContext context) {
    void open(String route) {
      session.clearMessages();
      context.go(route);
    }

    return MoolOutcomeDock(
      semanticLabel: 'Work navigation',
      activeId: active,
      mool: MoolDockAction(
        keyName: 'work-dock-mool',
        id: 'mool',
        label: 'Mool',
        icon: Icons.blur_circular_rounded,
        onPressed: () => open('/app/work/mool'),
      ),
      actions: [
        MoolDockAction(
          keyName: 'work-dock-earn',
          id: 'earn',
          label: 'Earn',
          icon: Icons.currency_rupee_rounded,
          onPressed: () => open('/app/work/earn'),
        ),
        MoolDockAction(
          keyName: 'work-dock-my-work',
          id: 'my-work',
          label: 'My Work',
          icon: Icons.work_outline_rounded,
          onPressed: () => open('/app/work/my-work'),
        ),
      ],
      chat: MoolDockAction(
        keyName: 'work-dock-chat',
        id: 'chat',
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        onPressed: () => open('/app/chat/inbox?return=/app/work/earn'),
      ),
    );
  }
}

class WorkEmptyState extends StatelessWidget {
  const WorkEmptyState({
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
    this.keyName = 'work-empty',
    super.key,
  });

  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      keyName: keyName,
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: MoolColors.muted,
            size: 36,
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xxs),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: MoolColors.muted),
          ),
          const SizedBox(height: MoolSpacing.sm),
          OutlinedButton(
            key: Key('$keyName-action'),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
