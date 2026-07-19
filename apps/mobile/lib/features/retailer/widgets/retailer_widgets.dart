import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_session.dart';

class RetailerPageScaffold extends StatelessWidget {
  const RetailerPageScaffold({
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

  final RetailerSession session;
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
        backgroundColor: MoolColors.canvas,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 74,
        leadingWidth: showBack ? 64 : 18,
        leading: showBack
            ? Padding(
                padding: const EdgeInsets.only(left: MoolSpacing.sm),
                child: IconButton.outlined(
                  key: const Key('retailer-back'),
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
                  key: const Key('retailer-alerts'),
                  tooltip: 'Open alerts',
                  onPressed: () => session.showNotice(
                    '${session.openOrderCount} order needs attention. Delivery promises remain visible on each order.',
                  ),
                  icon: Badge(
                    isLabelVisible: session.openOrderCount > 0,
                    label: Text('${session.openOrderCount}'),
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
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
                RetailerMessageBanner(session: session),
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
      bottomNavigationBar: RetailerBottomDock(
        session: session,
        active: activeDock,
        returnRoute: returnRoute,
      ),
    );
  }
}

class RetailerMessageBanner extends StatelessWidget {
  const RetailerMessageBanner({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    final error = session.errorMessage;
    final notice = session.noticeMessage;
    if (error == null && notice == null) return const SizedBox.shrink();
    final isError = error != null;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key(isError ? 'retailer-error' : 'retailer-notice'),
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
              key: const Key('dismiss-retailer-message'),
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

class RetailerCard extends StatelessWidget {
  const RetailerCard({
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
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MoolRadii.card),
      side: const BorderSide(color: Color(0x1F000080)),
    );
    return Material(
      key: keyName == null ? null : Key(keyName!),
      color: color,
      elevation: 1,
      shadowColor: const Color(0x22000036),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(MoolRadii.card),
              child: Padding(padding: padding, child: child),
            ),
    );
  }
}

class RetailerPill extends StatelessWidget {
  const RetailerPill({
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
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class RetailerPrimaryButton extends StatelessWidget {
  const RetailerPrimaryButton({
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
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
    );
  }
}

class RetailerSectionTitle extends StatelessWidget {
  const RetailerSectionTitle({
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
        ...?(trailing == null ? null : <Widget>[trailing!]),
      ],
    );
  }
}

class RetailerBottomDock extends StatelessWidget {
  const RetailerBottomDock({
    required this.session,
    required this.active,
    required this.returnRoute,
    super.key,
  });

  final RetailerSession session;
  final String active;
  final String returnRoute;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData, String)>[
      ('mool', 'Mool', Icons.circle_rounded, '/app/retailer/mool'),
      ('orders', 'Orders', Icons.receipt_long_outlined, '/app/retailer/orders'),
      (
        'stock',
        'Stock',
        Icons.inventory_2_outlined,
        '/app/retailer/home?view=stock',
      ),
      (
        'wholesale',
        'Wholesale',
        Icons.local_shipping_outlined,
        '/app/retailer/wholesale',
      ),
      (
        'chat',
        'Chat',
        Icons.chat_bubble_outline_rounded,
        Uri(
          path: '/app/chat/inbox',
          queryParameters: {'return': returnRoute},
        ).toString(),
      ),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          0,
          MoolSpacing.md,
          MoolSpacing.xs,
        ),
        child: SizedBox(
          height: 64,
          child: MoolGlassSurface(
            semanticLabel: 'Retailer navigation',
            padding: const EdgeInsets.all(MoolSpacing.xxs),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: Semantics(
                      selected: active == item.$1,
                      button: true,
                      label: 'Open ${item.$2}',
                      child: InkWell(
                        key: Key('retailer-dock-${item.$1}'),
                        onTap: () {
                          session.clearMessages();
                          context.go(item.$4);
                        },
                        borderRadius: BorderRadius.circular(MoolRadii.capsule),
                        child: AnimatedContainer(
                          duration: MoolMotion.accessible(
                            context,
                            MoolMotion.quick,
                          ),
                          constraints: const BoxConstraints(minHeight: 52),
                          decoration: BoxDecoration(
                            color: active == item.$1
                                ? MoolColors.navy
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              MoolRadii.capsule,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.$3,
                                size: 19,
                                color: active == item.$1
                                    ? Colors.white
                                    : MoolColors.navy,
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  item.$2,
                                  style: TextStyle(
                                    color: active == item.$1
                                        ? Colors.white
                                        : MoolColors.navy,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RetailerEmptyState extends StatelessWidget {
  const RetailerEmptyState({
    required this.keyName,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String keyName;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return RetailerCard(
      keyName: keyName,
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 38,
            color: MoolColors.muted,
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
