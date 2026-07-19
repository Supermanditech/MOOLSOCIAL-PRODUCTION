import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../creator_session.dart';

class CreatorPageScaffold extends StatelessWidget {
  const CreatorPageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.activeDock,
    required this.returnRoute,
    this.showBack = true,
    this.trailing,
    this.bottomAction,
    super.key,
  });

  final CreatorSession session;
  final String title;
  final String subtitle;
  final Widget body;
  final String activeDock;
  final String returnRoute;
  final bool showBack;
  final Widget? trailing;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 74,
        leadingWidth: showBack ? 64 : 18,
        leading: showBack
            ? Padding(
                padding: const EdgeInsets.only(left: MoolSpacing.sm),
                child: IconButton.outlined(
                  key: const Key('creator-back'),
                  tooltip: 'Go back',
                  onPressed: () {
                    session.clearMessages();
                    context.go(returnRoute);
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                ),
              )
            : null,
        titleSpacing: showBack ? 4 : MoolSpacing.md,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  key: const Key('creator-help'),
                  tooltip: 'Open creator controls',
                  onPressed: () => context.go('/app/creator/control'),
                  icon: const Icon(Icons.shield_outlined),
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
                CreatorMessageBanner(session: session),
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
      bottomNavigationBar: CreatorBottomDock(
        session: session,
        active: activeDock,
        returnRoute: returnRoute,
      ),
    );
  }
}

class CreatorMessageBanner extends StatelessWidget {
  const CreatorMessageBanner({required this.session, super.key});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) {
    final error = session.errorMessage;
    final notice = session.noticeMessage;
    if (error == null && notice == null && !session.busy) {
      return const SizedBox.shrink();
    }
    final isError = error != null;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key(isError ? 'creator-error' : 'creator-notice'),
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
          color: session.busy
              ? const Color(0xFFF3F2FF)
              : isError
              ? const Color(0xFFFFEDEC)
              : const Color(0xFFEAF7E8),
          borderRadius: BorderRadius.circular(MoolRadii.control),
        ),
        child: Row(
          children: [
            if (session.busy)
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
                color: isError ? const Color(0xFFC62828) : MoolColors.success,
              ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: Text(
                session.busy ? 'Finishing your request…' : error ?? notice!,
                style: TextStyle(
                  color: isError ? const Color(0xFFC62828) : MoolColors.ink,
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

class CreatorBottomDock extends StatelessWidget {
  const CreatorBottomDock({
    required this.session,
    required this.active,
    required this.returnRoute,
    super.key,
  });

  final CreatorSession session;
  final String active;
  final String returnRoute;

  @override
  Widget build(BuildContext context) {
    void open(String route) {
      session.clearMessages();
      context.go(route);
    }

    return MoolOutcomeDock(
      semanticLabel: 'Creator navigation',
      activeId: active,
      mool: MoolDockAction(
        keyName: 'creator-dock-mool',
        id: 'mool',
        label: 'Mool',
        icon: Icons.blur_circular_rounded,
        onPressed: () => open('/app/focus?return=$returnRoute'),
      ),
      actions: [
        MoolDockAction(
          keyName: 'creator-dock-create',
          id: 'create',
          label: 'Create',
          icon: Icons.add_circle_outline_rounded,
          onPressed: () => open('/app/creator/publish'),
        ),
        MoolDockAction(
          keyName: 'creator-dock-studio',
          id: 'studio',
          label: 'Studio',
          icon: Icons.space_dashboard_outlined,
          onPressed: () => open('/app/creator'),
        ),
        MoolDockAction(
          keyName: 'creator-dock-earnings',
          id: 'earnings',
          label: 'Earnings',
          icon: Icons.account_balance_wallet_outlined,
          onPressed: () => open('/app/creator/earnings'),
        ),
      ],
      chat: MoolDockAction(
        keyName: 'creator-dock-chat',
        id: 'chat',
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        badgeCount: 2,
        onPressed: () => open(
          Uri(
            path: '/app/chat/inbox',
            queryParameters: {'return': returnRoute},
          ).toString(),
        ),
      ),
    );
  }
}

class CreatorCard extends StatelessWidget {
  const CreatorCard({
    required this.child,
    this.keyName,
    this.onTap,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(MoolSpacing.md),
    super.key,
  });

  final Widget child;
  final String? keyName;
  final VoidCallback? onTap;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => MoolCardSurface(
    key: keyName == null ? null : Key(keyName!),
    color: color,
    padding: padding,
    onTap: onTap,
    child: child,
  );
}

class CreatorSectionTitle extends StatelessWidget {
  const CreatorSectionTitle({
    required this.title,
    required this.detail,
    super.key,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        flex: 2,
        child: Text(
          title,
          style: const TextStyle(
            color: MoolColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -.25,
          ),
        ),
      ),
      const SizedBox(width: MoolSpacing.xs),
      Expanded(
        child: Text(
          detail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: MoolColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class CreatorMetric extends StatelessWidget {
  const CreatorMetric({
    required this.label,
    required this.value,
    required this.detail,
    super.key,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) => CreatorCard(
    padding: const EdgeInsets.all(MoolSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: MoolColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: MoolSpacing.xxs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: MoolColors.navy,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: MoolColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class CreatorPill extends StatelessWidget {
  const CreatorPill({
    required this.label,
    this.color = MoolColors.success,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: MoolSpacing.xs,
      vertical: MoolSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(MoolRadii.capsule),
      border: Border.all(color: color.withValues(alpha: .22)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
    ),
  );
}

class CreatorActionRow extends StatelessWidget {
  const CreatorActionRow({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
    required this.onTap,
    this.meta,
    this.color = Colors.white,
    super.key,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String detail;
  final String? meta;
  final String action;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => CreatorCard(
    keyName: keyName,
    color: color,
    onTap: onTap,
    padding: const EdgeInsets.all(MoolSpacing.sm),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: MoolColors.navy.withValues(alpha: .08),
          foregroundColor: MoolColors.navy,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: MoolColors.muted, fontSize: 11),
              ),
              if (meta != null)
                Text(
                  meta!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: MoolSpacing.xs),
        Text(
          action,
          style: const TextStyle(
            color: MoolColors.navy,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Icon(Icons.chevron_right_rounded, size: 18),
      ],
    ),
  );
}

class CreatorFact extends StatelessWidget {
  const CreatorFact({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xxs),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: MoolColors.muted)),
        ),
        const SizedBox(width: MoolSpacing.sm),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}
