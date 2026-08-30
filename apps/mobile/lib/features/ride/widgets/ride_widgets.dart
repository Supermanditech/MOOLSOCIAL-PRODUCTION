import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/profile/global_profile_panel_v2.dart';
import '../../../ui_v2/universal/mool_global_navigation_v2.dart';
import '../ride_models.dart';
import '../ride_session.dart';

String rideMoney(int value) => '₹$value';

GlobalProfileContextAction _travelProfileContext(
  RideSession session,
  ValueChanged<String> onOpenRoute,
) {
  final trip = session.trip;
  if (trip != null && !session.rideCancelled) {
    final stageLabel = switch (session.stage) {
      RideTripStage.captainArriving => 'Captain is arriving',
      RideTripStage.liveTrip => 'Ride in progress',
      RideTripStage.paymentApproval => 'Fare ready for approval',
      RideTripStage.receipt => 'Ride completed',
    };
    return GlobalProfileContextAction(
      id: 'travel-active-ride',
      title: 'Your ${trip.package.name} ride',
      detail: '$stageLabel · ${trip.drop}',
      actionLabel: session.stage == RideTripStage.receipt
          ? 'View receipt'
          : 'Open ride',
      icon: Icons.local_taxi_outlined,
      accentColor: const Color(0xFF0284C7),
      gradientColors: const [Color(0xFF075985), Color(0xFF0EA5E9)],
      onPressed: () => onOpenRoute('/app/ride/trip/${trip.id}'),
    );
  }

  return GlobalProfileContextAction(
    id: 'travel-bus-discovery',
    title: 'Plan a bus journey',
    detail: 'Compare routes, timings, seats and fares before checkout.',
    actionLabel: 'Search buses',
    icon: Icons.directions_bus_filled_outlined,
    accentColor: const Color(0xFF0284C7),
    gradientColors: const [Color(0xFF075985), Color(0xFF0EA5E9)],
    onPressed: () => onOpenRoute('/app/book/bus'),
  );
}

class RidePageScaffold extends StatelessWidget {
  const RidePageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.body,
    this.activeLocalAction = '',
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
  final String activeLocalAction;
  final String fallbackBackRoute;
  final bool showBack;
  final Widget? trailing;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final tripId = session.trip?.id;
    final activeSubAction =
        const {'bike', 'auto', 'cab'}.contains(activeLocalAction)
        ? activeLocalAction
        : session.selectedType.name;

    void leaveContentDepth() {
      session.clearMessages();
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallbackBackRoute);
      }
    }

    void openRideType(RideType type) {
      session.clearMessages();
      if (tripId != null) {
        session.showNotice(
          'Your ${session.selectedType.label} ride is still active. '
          'Finish or cancel it before starting ${type.label}.',
        );
        return;
      }
      session.chooseType(type);
      if (const {'bike', 'auto', 'cab'}.contains(activeLocalAction)) return;
      context.push('/app/ride/book?type=${type.name}');
    }

    void openGlobal(String route) {
      session.clearMessages();
      context.push(route);
    }

    void openChat() {
      final routeState = GoRouterState.of(context);
      final current = routeState.uri.path == '/app/ride/book'
          ? Uri(
              path: routeState.uri.path,
              queryParameters: {
                ...routeState.uri.queryParameters,
                'type': session.selectedType.name,
              },
            ).toString()
          : routeState.uri.toString();
      openGlobal(
        Uri(
          path: '/app/chat/inbox',
          queryParameters: {'return': current},
        ).toString(),
      );
    }

    void switchGlobalDestination(String route) {
      session.clearMessages();
      openMoolConnectedRoute(context, activeFamilyId: 'ride', route: route);
    }

    void openConnectedAction(String route) {
      final uri = Uri.tryParse(route);
      final rideType = uri?.path == '/app/ride/book'
          ? switch (uri?.queryParameters['type']) {
              'bike' => RideType.bike,
              'auto' => RideType.auto,
              'cab' => RideType.cab,
              _ => null,
            }
          : null;
      if (rideType != null) {
        openRideType(rideType);
        return;
      }
      switchGlobalDestination(route);
    }

    void openTravelAction(String actionId) {
      if (actionId == 'bus') {
        switchGlobalDestination('/app/book/bus');
        return;
      }
      openRideType(RideType.values.firstWhere((type) => type.name == actionId));
    }

    return PopScope<Object?>(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          leaveContentDepth();
        }
      },
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          backgroundColor: MoolColors.canvas,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 72,
          leadingWidth: showBack ? 64 : 16,
          leading: showBack
              ? Padding(
                  padding: const EdgeInsets.only(left: MoolSpacing.sm),
                  child: MoolNativeBackButton(
                    keyName: 'ride-back',
                    onPressed: leaveContentDepth,
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
            MoolGlobalChatShortcut(
              keyName: 'ride-global-chat',
              onPressed: openChat,
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: MoolSpacing.sm),
              child:
                  trailing ??
                  IconButton.outlined(
                    key: const Key('ride-safety-shortcut'),
                    tooltip: 'Open safety centre',
                    onPressed: () => showRideSafetyCentre(
                      context,
                      session,
                      tripId: session.trip?.id,
                    ),
                    icon: const Icon(Icons.shield_outlined),
                  ),
            ),
            if (!showBack)
              Padding(
                padding: const EdgeInsets.only(right: MoolSpacing.sm),
                child: MoolGlobalProfileShortcutV2(
                  keyName: 'ride-global-profile',
                  onPressed: () => showGlobalProfilePanelV2(
                    context,
                    contextAction: _travelProfileContext(session, openGlobal),
                    onOpenRoute: openGlobal,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
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
        bottomNavigationBar: MoolDestinationNavigationV2(
          activeId: 'ride',
          destinationLabel: 'Travel',
          familyRootSelected: activeSubAction == 'bike',
          selectedLocalIndex: switch (activeSubAction) {
            'auto' => 1,
            'cab' => 2,
            _ => 0,
          },
          localActionCount: 4,
          localNavigation: MoolLocalNavigationRail(
            key: const Key('ride-local-navigation'),
            familyId: 'ride',
            surfaceTone: MoolLocalNavigationSurfaceTone.light,
            semanticLabel: 'Travel choices: Bike, Auto, Cab and Bus.',
            activeId: activeSubAction,
            actions: [
              for (final type in RideType.values)
                MoolLocalNavigationAction(
                  keyName: 'ride-local-${type.name}',
                  id: type.name,
                  label: type.label,
                  icon: switch (type) {
                    RideType.bike => Icons.two_wheeler_outlined,
                    RideType.auto => Icons.electric_rickshaw_outlined,
                    RideType.cab => Icons.local_taxi_outlined,
                  },
                  onPressed: activeSubAction == type.name
                      ? null
                      : () => openRideType(type),
                ),
              MoolLocalNavigationAction(
                keyName: 'ride-local-bus',
                id: 'bus',
                label: 'Bus',
                icon: Icons.directions_bus_filled_outlined,
                onPressed: () => openTravelAction('bus'),
              ),
            ],
          ),
          onOpenMool: () => openGlobal('/app/mool?from=ride'),
          onOpenAction: (action) => openConnectedAction(action.route),
          onPreviousLocalAction: () {
            const actions = ['bike', 'auto', 'cab', 'bus'];
            final current = actions.indexOf(activeSubAction);
            openTravelAction(
              actions[(current - 1 + actions.length) % actions.length],
            );
          },
          onNextLocalAction: () {
            const actions = ['bike', 'auto', 'cab', 'bus'];
            final current = actions.indexOf(activeSubAction);
            openTravelAction(actions[(current + 1) % actions.length]);
          },
          onOpenChat: openChat,
        ),
      ),
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

Future<void> showRideSafetyCentre(
  BuildContext context,
  RideSession session, {
  required String? tripId,
}) {
  final hasActiveTrip = tripId != null;
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        0,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        key: const Key('ride-safety-centre-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Safety centre',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            hasActiveTrip
                ? 'Trip details, live route and captain identity are saved.'
                : 'There is no active trip. Emergency help and MoolSocial '
                      'support remain available.',
            key: const Key('ride-safety-context'),
            style: const TextStyle(color: MoolColors.muted),
          ),
          const SizedBox(height: MoolSpacing.md),
          if (hasActiveTrip)
            ListTile(
              key: const Key('ride-safety-share'),
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Copy live trip link'),
              subtitle: const Text('Includes route and captain details'),
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: 'https://moolsocial.com/trip/$tripId'),
                );
                session.showNotice('Live trip safety link copied.');
                Navigator.pop(sheetContext);
              },
            )
          else
            ListTile(
              key: const Key('ride-safety-book'),
              leading: const Icon(Icons.local_taxi_outlined),
              title: const Text('Book a ride'),
              subtitle: const Text('Choose a verified bike, auto or cab'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.go('/app/ride/book');
              },
            ),
          ListTile(
            key: const Key('ride-safety-emergency'),
            leading: const Icon(
              Icons.emergency_outlined,
              color: Color(0xFFB42318),
            ),
            title: const Text('Call emergency help'),
            subtitle: const Text('Connect to emergency assistance now'),
            onTap: () {
              session.showNotice('Connecting to emergency assistance…');
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            key: const Key('ride-safety-report'),
            leading: const Icon(Icons.report_outlined),
            title: Text(
              hasActiveTrip
                  ? 'Report a safety concern'
                  : 'Contact safety support',
            ),
            subtitle: Text(
              hasActiveTrip
                  ? 'Route evidence will be attached'
                  : 'Open a private support conversation',
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              if (hasActiveTrip) {
                session.chooseIssue(RideIssueType.safety);
                context.go('/app/ride/trip/$tripId/support');
                return;
              }
              context.go(
                Uri(
                  path: '/app/chat',
                  queryParameters: {
                    'type': 'support',
                    'return': GoRouterState.of(context).uri.toString(),
                  },
                ).toString(),
              );
            },
          ),
        ],
      ),
    ),
  );
}
