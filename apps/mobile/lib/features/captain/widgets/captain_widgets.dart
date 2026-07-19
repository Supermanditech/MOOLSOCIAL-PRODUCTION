import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../captain_session.dart';

class CaptainPageScaffold extends StatelessWidget {
  const CaptainPageScaffold({
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

  final CaptainSession session;
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
                  key: const Key('captain-back'),
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
                  key: const Key('captain-help'),
                  tooltip: 'Open captain support',
                  onPressed: () =>
                      context.go('/app/captain/support-work?tab=support'),
                  icon: const Icon(Icons.help_outline_rounded),
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
                CaptainMessageBanner(session: session),
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
      bottomNavigationBar: CaptainBottomDock(
        session: session,
        active: activeDock,
        returnRoute: returnRoute,
      ),
    );
  }
}

class CaptainMessageBanner extends StatelessWidget {
  const CaptainMessageBanner({required this.session, super.key});

  final CaptainSession session;

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
        key: Key(isError ? 'captain-error' : 'captain-notice'),
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

class CaptainBottomDock extends StatelessWidget {
  const CaptainBottomDock({
    required this.session,
    required this.active,
    required this.returnRoute,
    super.key,
  });

  final CaptainSession session;
  final String active;
  final String returnRoute;

  @override
  Widget build(BuildContext context) {
    void open(String route) {
      session.clearMessages();
      context.go(route);
    }

    return MoolOutcomeDock(
      semanticLabel: 'Captain navigation',
      activeId: active,
      mool: MoolDockAction(
        keyName: 'captain-dock-mool',
        id: 'mool',
        label: 'Mool',
        icon: Icons.blur_circular_rounded,
        onPressed: () => open('/app/focus?return=$returnRoute'),
      ),
      actions: [
        MoolDockAction(
          keyName: 'captain-dock-requests',
          id: 'requests',
          label: 'Requests',
          icon: Icons.notifications_active_outlined,
          onPressed: () => open('/app/captain/requests'),
        ),
        MoolDockAction(
          keyName: 'captain-dock-trips',
          id: 'trips',
          label: 'Trip',
          icon: Icons.navigation_outlined,
          onPressed: () => open(session.currentTripRoute),
        ),
        MoolDockAction(
          keyName: 'captain-dock-earnings',
          id: 'earnings',
          label: 'Earnings',
          icon: Icons.account_balance_wallet_outlined,
          onPressed: () => open('/app/captain/earnings'),
        ),
      ],
      chat: MoolDockAction(
        keyName: 'captain-dock-chat',
        id: 'chat',
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        badgeCount: 1,
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

class CaptainCard extends StatelessWidget {
  const CaptainCard({
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

class CaptainSectionTitle extends StatelessWidget {
  const CaptainSectionTitle({
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

class CaptainMetric extends StatelessWidget {
  const CaptainMetric({
    required this.label,
    required this.value,
    required this.detail,
    super.key,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) => CaptainCard(
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

class CaptainPill extends StatelessWidget {
  const CaptainPill({
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

class CaptainActionRow extends StatelessWidget {
  const CaptainActionRow({
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
  Widget build(BuildContext context) => CaptainCard(
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

class CaptainRouteMap extends StatelessWidget {
  const CaptainRouteMap({
    required this.label,
    required this.start,
    required this.end,
    this.height = 220,
    super.key,
  });

  final String label;
  final String start;
  final String end;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFECEEF5),
      borderRadius: BorderRadius.circular(MoolRadii.card),
      border: Border.all(color: const Color(0x16000080)),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: const _CaptainMapPainter()),
        ),
        Positioned(
          left: MoolSpacing.sm,
          top: MoolSpacing.sm,
          child: CaptainPill(label: label, color: MoolColors.navy),
        ),
        Positioned(
          left: 34,
          bottom: 44,
          child: _MapPin(label: start, color: MoolColors.navy),
        ),
        Positioned(
          right: 34,
          top: 58,
          child: _MapPin(label: end, color: MoolColors.success),
        ),
      ],
    ),
  );
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: MoolSpacing.xs,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(MoolRadii.capsule),
      boxShadow: MoolShadows.card,
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _CaptainMapPainter extends CustomPainter {
  const _CaptainMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final route = Paint()
      ..color = MoolColors.royal
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = const Color(0xFFD9DCE8)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(18, size.height * .25),
      Offset(size.width - 16, size.height * .70),
      road,
    );
    canvas.drawLine(
      Offset(20, size.height * .78),
      Offset(size.width * .74, 18),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .1, size.height * .54),
      Offset(size.width * .92, size.height * .36),
      minor,
    );
    final path = Path()
      ..moveTo(66, size.height - 54)
      ..cubicTo(
        size.width * .34,
        size.height * .65,
        size.width * .57,
        size.height * .60,
        size.width - 72,
        82,
      );
    canvas.drawPath(path, route);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
