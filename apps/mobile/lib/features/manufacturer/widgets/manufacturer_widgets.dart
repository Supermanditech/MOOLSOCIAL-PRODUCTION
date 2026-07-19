import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../manufacturer_session.dart';

class ManufacturerPageScaffold extends StatelessWidget {
  const ManufacturerPageScaffold({
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

  final ManufacturerSession session;
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
                  key: const Key('manufacturer-back'),
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
                  key: const Key('manufacturer-alerts'),
                  tooltip: 'Open priority actions',
                  onPressed: () => session.showNotice(
                    '6 orders, 2 dispatches and 4 input requirements need action.',
                  ),
                  icon: const Badge(
                    label: Text('4'),
                    child: Icon(Icons.notifications_none_rounded),
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
                ManufacturerMessageBanner(session: session),
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
      bottomNavigationBar: ManufacturerBottomDock(
        session: session,
        active: activeDock,
        returnRoute: returnRoute,
      ),
    );
  }
}

class ManufacturerMessageBanner extends StatelessWidget {
  const ManufacturerMessageBanner({required this.session, super.key});

  final ManufacturerSession session;

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
        key: Key(isError ? 'manufacturer-error' : 'manufacturer-notice'),
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

class ManufacturerBottomDock extends StatelessWidget {
  const ManufacturerBottomDock({
    required this.session,
    required this.active,
    required this.returnRoute,
    super.key,
  });

  final ManufacturerSession session;
  final String active;
  final String returnRoute;

  @override
  Widget build(BuildContext context) {
    void open(String route) {
      session.clearMessages();
      context.go(route);
    }

    return MoolOutcomeDock(
      semanticLabel: 'Manufacturer navigation',
      activeId: active,
      mool: MoolDockAction(
        keyName: 'manufacturer-dock-mool',
        id: 'mool',
        label: 'Mool',
        icon: Icons.blur_circular_rounded,
        onPressed: () => open('/app/focus?return=$returnRoute'),
      ),
      actions: [
        MoolDockAction(
          keyName: 'manufacturer-dock-orders',
          id: 'orders',
          label: 'Orders',
          icon: Icons.receipt_long_outlined,
          onPressed: () => open('/app/manufacturer?view=orders'),
        ),
        MoolDockAction(
          keyName: 'manufacturer-dock-stock',
          id: 'stock',
          label: 'Stock',
          icon: Icons.inventory_2_outlined,
          onPressed: () => open('/app/manufacturer/catalogue'),
        ),
        MoolDockAction(
          keyName: 'manufacturer-dock-inputs',
          id: 'inputs',
          label: 'Inputs',
          icon: Icons.local_shipping_outlined,
          onPressed: () => open('/app/manufacturer/purchases'),
        ),
      ],
      chat: MoolDockAction(
        keyName: 'manufacturer-dock-chat',
        id: 'chat',
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        badgeCount: 3,
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

class ManufacturerSupplyControl extends StatelessWidget {
  const ManufacturerSupplyControl({
    required this.live,
    required this.onPressed,
    super.key,
  });

  final bool live;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = live ? const Color(0xFF166B2E) : MoolColors.muted;
    final background = live ? const Color(0xFFEAF7E8) : const Color(0xFFF0F1F7);
    return Semantics(
      button: true,
      toggled: live,
      label: live ? 'Supply is live' : 'Supply is paused',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(MoolRadii.capsule),
        child: InkWell(
          key: const Key('manufacturer-supply-toggle'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(MoolRadii.capsule),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: MoolMetrics.minimumTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MoolSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: MoolMotion.accessible(context, MoolMotion.quick),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: live ? MoolColors.success : MoolColors.muted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xxs),
                  Text(
                    live ? 'Live' : 'Paused',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ManufacturerCard extends StatelessWidget {
  const ManufacturerCard({
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

class ManufacturerSectionTitle extends StatelessWidget {
  const ManufacturerSectionTitle({
    required this.title,
    required this.detail,
    super.key,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
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
}

class ManufacturerMetric extends StatelessWidget {
  const ManufacturerMetric({
    required this.label,
    required this.value,
    required this.detail,
    super.key,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) => ManufacturerCard(
    padding: const EdgeInsets.all(MoolSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: MoolColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: MoolSpacing.xxs),
        Text(
          value,
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

class ManufacturerPill extends StatelessWidget {
  const ManufacturerPill({
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

class ManufacturerActionRow extends StatelessWidget {
  const ManufacturerActionRow({
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
  Widget build(BuildContext context) => ManufacturerCard(
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

class ManufacturerSearch extends StatelessWidget {
  const ManufacturerSearch({
    required this.session,
    required this.hint,
    this.scan,
    this.voice,
    super.key,
  });

  final ManufacturerSession session;
  final String hint;
  final VoidCallback? scan;
  final VoidCallback? voice;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('manufacturer-search'),
      initialValue: session.searchQuery,
      onChanged: session.setSearch,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session.searchQuery.isNotEmpty)
              IconButton(
                key: const Key('manufacturer-clear-search'),
                tooltip: 'Clear search',
                onPressed: session.clearSearch,
                icon: const Icon(Icons.close_rounded),
              ),
            if (scan != null)
              IconButton(
                key: const Key('manufacturer-scan'),
                tooltip: 'Scan product or document',
                onPressed: scan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
              ),
            if (voice != null)
              IconButton(
                key: const Key('manufacturer-voice'),
                tooltip: 'Search by voice',
                onPressed: voice,
                icon: const Icon(Icons.mic_none_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
