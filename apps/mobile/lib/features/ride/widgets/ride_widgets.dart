import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../ride_session.dart';

String rideMoney(int value) => '₹$value';

class RidePageScaffold extends StatelessWidget {
  const RidePageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.body,
    this.activeDock = 'ride',
    this.fallbackBackRoute = '/app/ride',
    this.showBack = true,
    this.trailing,
    this.bottomAction,
    super.key,
  });

  final RideSession session;
  final String title;
  final String subtitle;
  final Widget body;
  final String activeDock;
  final String fallbackBackRoute;
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
        toolbarHeight: 72,
        leadingWidth: showBack ? 64 : 16,
        leading: showBack
            ? Padding(
                padding: const EdgeInsets.only(left: MoolSpacing.sm),
                child: IconButton.outlined(
                  key: const Key('ride-back'),
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
                  key: const Key('ride-safety-shortcut'),
                  tooltip: 'Open safety centre',
                  onPressed: () => session.showNotice(
                    'Safety centre is ready. Share your trip or call emergency help.',
                  ),
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
                RideMessageBanner(session: session),
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
      bottomNavigationBar: RideBottomDock(session: session, active: activeDock),
    );
  }
}

class RideMessageBanner extends StatelessWidget {
  const RideMessageBanner({required this.session, super.key});

  final RideSession session;

  @override
  Widget build(BuildContext context) {
    final error = session.errorMessage;
    final notice = session.noticeMessage;
    if (error == null && notice == null) return const SizedBox.shrink();
    final isError = error != null;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key(isError ? 'ride-error' : 'ride-notice'),
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
              key: const Key('dismiss-ride-message'),
              tooltip: 'Dismiss message',
              onPressed: session.clearMessages,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class RideCard extends StatelessWidget {
  const RideCard({
    required this.child,
    this.padding = const EdgeInsets.all(MoolSpacing.md),
    this.color = Colors.white,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return MoolCardSurface(
      color: color,
      padding: padding,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}

class RideSectionTitle extends StatelessWidget {
  const RideSectionTitle(this.title, {this.detail, super.key});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: MoolSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (detail != null) ...[
            const SizedBox(width: MoolSpacing.xs),
            Flexible(
              child: Text(
                detail!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RideQuickAction extends StatelessWidget {
  const RideQuickAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          side: const BorderSide(color: MoolColors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class RideBottomDock extends StatelessWidget {
  const RideBottomDock({
    required this.session,
    required this.active,
    super.key,
  });

  final RideSession session;
  final String active;

  @override
  Widget build(BuildContext context) {
    final tripId = session.trip?.id;
    void clear() => session.clearMessages();
    return MoolOutcomeDock(
      semanticLabel: 'Ride navigation',
      activeId: active,
      mool: MoolDockAction(
        keyName: 'ride-dock-mool',
        id: 'mool',
        label: 'Mool',
        icon: Icons.blur_circular_rounded,
        onPressed: () {
          clear();
          context.go('/app/mool');
        },
      ),
      actions: [
        MoolDockAction(
          keyName: 'ride-dock-book',
          id: 'ride',
          label: 'Book',
          icon: Icons.local_taxi_outlined,
          onPressed: () {
            clear();
            context.go('/app/ride/book');
          },
        ),
        MoolDockAction(
          keyName: 'ride-dock-trip',
          id: 'trip',
          label: 'Trip',
          icon: Icons.route_outlined,
          onPressed: () {
            clear();
            context.go(
              tripId == null ? '/app/ride/book' : '/app/ride/trip/$tripId',
            );
          },
        ),
        MoolDockAction(
          keyName: 'ride-dock-help',
          id: 'help',
          label: 'Help',
          icon: Icons.support_agent_rounded,
          onPressed: () {
            clear();
            if (tripId == null) {
              session.showNotice(
                'Book a ride first so help can attach its route and receipt.',
              );
            } else {
              context.go('/app/ride/trip/$tripId/support');
            }
          },
        ),
      ],
      chat: MoolDockAction(
        keyName: 'ride-dock-chat',
        id: 'chat',
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        onPressed: () {
          final current = GoRouterState.of(context).uri.toString();
          clear();
          context.go(
            Uri(
              path: '/app/chat/inbox',
              queryParameters: {'return': current},
            ).toString(),
          );
        },
      ),
    );
  }
}
