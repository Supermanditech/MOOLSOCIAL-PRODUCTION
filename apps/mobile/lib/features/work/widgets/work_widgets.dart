import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_service_home.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/universal/mool_global_navigation_v2.dart';
import '../work_session.dart';

class WorkPageScaffold extends StatelessWidget {
  const WorkPageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.body,
    this.headerTitle,
    this.fallbackBackRoute = '/app/work/earn',
    this.showBack = true,
    this.activeLocalAction = 'earn',
    this.showHeaderChat = true,
    this.showTrailingAction = true,
    this.onBack,
    this.trailing,
    this.bottomAction,
    this.contextualLocalActions,
    this.contextualActiveId,
    this.contextualDestinationLabel,
    this.manageSystemBack = true,
    this.hideNavigationWhenKeyboardVisible = false,
    this.navigationOverBody = false,
    super.key,
  });

  final WorkSession session;
  final String title;
  final String subtitle;
  final Widget body;
  final Widget? headerTitle;
  final String fallbackBackRoute;
  final bool showBack;
  final String activeLocalAction;
  final bool showHeaderChat;
  final bool showTrailingAction;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? bottomAction;
  final List<MoolLocalNavigationAction>? contextualLocalActions;
  final String? contextualActiveId;
  final String? contextualDestinationLabel;
  final bool manageSystemBack;
  final bool hideNavigationWhenKeyboardVisible;
  final bool navigationOverBody;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    void leaveContentDepth() {
      session.clearMessages();
      if (onBack != null) {
        onBack!();
        return;
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallbackBackRoute);
      }
    }

    void openGlobal(String route) {
      session.clearMessages();
      context.push(route);
    }

    void openChat() {
      final current = GoRouterState.of(context).uri.toString();
      openGlobal(
        Uri(
          path: '/app/chat/inbox',
          queryParameters: {'return': current},
        ).toString(),
      );
    }

    void openLocal(String route) {
      session.clearMessages();
      context.push(route);
    }

    void switchGlobalDestination(String route) {
      session.clearMessages();
      openMoolConnectedRoute(context, activeFamilyId: 'work', route: route);
    }

    final localActions =
        contextualLocalActions ??
        [
          MoolLocalNavigationAction(
            keyName: 'work-local-earn',
            id: 'earn',
            label: 'Earn Today',
            icon: Icons.bolt_rounded,
            onPressed: activeLocalAction == 'earn'
                ? null
                : () => openLocal('/app/work/earn'),
          ),
          MoolLocalNavigationAction(
            keyName: 'work-local-workspace',
            id: 'workspace',
            label: 'Workspace',
            icon: Icons.dashboard_customize_outlined,
            onPressed: activeLocalAction == 'workspace'
                ? null
                : () => openLocal('/app/work/my-work'),
          ),
        ];
    final resolvedActiveId = contextualActiveId ?? activeLocalAction;
    var selectedLocalIndex = localActions.indexWhere(
      (action) => action.id == resolvedActiveId,
    );
    if (selectedLocalIndex < 0) selectedLocalIndex = 0;

    void moveLocal(int delta) {
      final target = (selectedLocalIndex + delta) % localActions.length;
      localActions[target].onPressed?.call();
    }

    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showNavigation =
        !hideNavigationWhenKeyboardVisible || !keyboardVisible;
    final navigation = MoolDestinationNavigationV2(
      activeId: 'work',
      destinationLabel: contextualDestinationLabel ?? 'Work',
      showFamilyRootAction: false,
      selectedLocalIndex: selectedLocalIndex,
      localActionCount: localActions.length,
      localNavigation: MoolLocalNavigationRail(
        key: const Key('work-local-navigation'),
        familyId: 'work',
        surfaceTone: MoolLocalNavigationSurfaceTone.light,
        semanticLabel: contextualLocalActions == null
            ? 'Work choices: Earn Today and Workspace.'
            : 'Store choices: Store, Orders, Sell and Stock.',
        activeId: resolvedActiveId,
        actions: localActions,
      ),
      onOpenMool: () => openGlobal('/app/mool?from=work'),
      onOpenAction: (action) => switchGlobalDestination(action.route),
      onPreviousLocalAction: () => moveLocal(-1),
      onNextLocalAction: () => moveLocal(1),
      onOpenChat: openChat,
    );
    final pageBody = SafeArea(
      top: false,
      bottom: true,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: MoolMetrics.maximumContentWidth,
          ),
          child: Column(
            children: [
              WorkMessageBanner(session: session),
              Expanded(child: _WorkPageReveal(child: body)),
              if (bottomAction != null)
                Material(
                  key: const Key('work-sticky-action-bar'),
                  color: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0x22000050),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      MoolSpacing.md,
                      MoolSpacing.sm,
                      MoolSpacing.md,
                      MoolSpacing.xs,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: _WorkActionReveal(child: bottomAction!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final composedBody = navigationOverBody && showNavigation
        ? Stack(
            children: [
              Positioned.fill(child: pageBody),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BlockSemantics(child: navigation),
              ),
            ],
          )
        : pageBody;

    return PopScope<Object?>(
      canPop: manageSystemBack ? onBack == null && canPop : true,
      onPopInvokedWithResult: (didPop, _) {
        if (!manageSystemBack) return;
        if (!didPop) {
          leaveContentDepth();
        }
      },
      child: Scaffold(
        extendBody: false,
        appBar: AppBar(
          backgroundColor: MoolColors.canvas,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 88,
          leadingWidth: showBack ? 64 : 16,
          leading: showBack
              ? Padding(
                  padding: const EdgeInsets.only(left: MoolSpacing.sm),
                  child: MoolNativeBackButton(
                    keyName: 'work-back',
                    onPressed: leaveContentDepth,
                  ),
                )
              : null,
          titleSpacing: showBack ? 4 : MoolSpacing.md,
          title:
              headerTitle ??
              MoolServiceHeaderTitle(
                title: title,
                subtitle: subtitle,
                titleKey: const Key('work-page-title'),
                subtitleKey: const Key('work-page-subtitle'),
              ),
          actions: [
            if (showHeaderChat) ...[
              MoolGlobalChatShortcut(
                keyName: 'work-global-chat',
                onPressed: openChat,
              ),
              const SizedBox(width: 4),
            ],
            if (showTrailingAction)
              Padding(
                padding: const EdgeInsets.only(right: MoolSpacing.sm),
                child:
                    trailing ??
                    IconButton.outlined(
                      key: const Key('work-help'),
                      tooltip: 'Work help',
                      onPressed: () => context.go(
                        Uri(
                          path: '/app/chat',
                          queryParameters: {
                            'type': 'support',
                            'return': GoRouterState.of(context).uri.toString(),
                          },
                        ).toString(),
                      ),
                      icon: const Icon(Icons.support_agent_outlined),
                    ),
              ),
          ],
        ),
        body: composedBody,
        bottomNavigationBar: navigationOverBody || !showNavigation
            ? null
            : navigation,
      ),
    );
  }
}

class _WorkPageReveal extends StatelessWidget {
  const _WorkPageReveal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MoolMotion.accessible(context, MoolMotion.standard),
      curve: MoolMotion.enter,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _WorkActionReveal extends StatelessWidget {
  const _WorkActionReveal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MoolMotion.accessible(context, MoolMotion.deliberate),
      curve: MoolMotion.enter,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(
          scale: .97 + (.03 * value),
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class WorkMessageBanner extends StatefulWidget {
  const WorkMessageBanner({required this.session, super.key});

  final WorkSession session;

  @override
  State<WorkMessageBanner> createState() => _WorkMessageBannerState();
}

class _WorkMessageBannerState extends State<WorkMessageBanner> {
  Timer? _dismissTimer;
  String? _scheduledNotice;

  void _scheduleNoticeDismissal(String? notice) {
    if (notice == null || notice == _scheduledNotice) return;
    _dismissTimer?.cancel();
    _scheduledNotice = notice;
    _dismissTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted || widget.session.noticeMessage != notice) return;
      widget.session.dismissMessages();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.session.errorMessage;
    final notice = widget.session.noticeMessage;
    _scheduleNoticeDismissal(notice);
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
              onPressed: widget.session.dismissMessages,
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
    return MoolServicePrimaryButton(
      key: Key(keyName),
      label: label,
      onPressed: busy ? null : onPressed,
      icon: busy ? Icons.hourglass_top_rounded : icon,
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
