import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/profile/global_profile_panel_v2.dart';
import '../../../ui_v2/universal/mool_global_navigation_v2.dart';
import '../book_models.dart';
import '../book_session.dart';

String bookMoney(int value) => '₹$value';

GlobalProfileContextAction _busTravelProfileContext(
  BookSession session,
  ValueChanged<String> onOpenRoute,
) {
  final selected = session.selectedBus;
  return GlobalProfileContextAction(
    id: selected == null
        ? 'travel-cab-discovery'
        : 'travel-selected-bus-alternative',
    title: selected == null ? 'Travel by cab' : 'Compare another option',
    detail: selected == null
        ? 'Review pickup time, vehicle and fare before you book.'
        : '${selected.from} → ${selected.to} remains selected while you compare.',
    actionLabel: 'Compare a cab',
    icon: Icons.local_taxi_outlined,
    accentColor: const Color(0xFF0284C7),
    gradientColors: const [Color(0xFF075985), Color(0xFF0EA5E9)],
    onPressed: () => onOpenRoute('/app/ride/book?type=cab'),
  );
}

GlobalProfileContextAction _careProfileContext(
  BookSession session,
  String activeSubAction,
  ValueChanged<String> onOpenRoute,
) {
  final appointment = session.appointment;
  if (appointment != null) {
    return GlobalProfileContextAction(
      id: 'care-doctor-appointment',
      title: 'Your doctor appointment',
      detail:
          '${appointment.care.label} · ${appointment.patient} · ${appointment.need}',
      actionLabel: 'View appointment',
      icon: Icons.medical_services_outlined,
      accentColor: const Color(0xFF0F766E),
      gradientColors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
      onPressed: () => onOpenRoute('/app/book/doctor/details'),
    );
  }

  final salon = session.salonBooking;
  if (salon != null) {
    final route = session.salonServiceDone
        ? '/app/book/salon/complete'
        : session.salonCheckedIn
        ? '/app/book/salon/visit'
        : '/app/book/salon/confirmed';
    return GlobalProfileContextAction(
      id: 'care-salon-booking',
      title: 'Your salon booking',
      detail: '${salon.service} · ${salon.mode.label}',
      actionLabel: session.salonServiceDone
          ? 'View completion'
          : 'Open booking',
      icon: Icons.content_cut_rounded,
      accentColor: const Color(0xFF7C3AED),
      gradientColors: const [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
      onPressed: () => onOpenRoute(route),
    );
  }

  final task = session.task;
  if (task != null) {
    final route = session.taskReleased
        ? '/app/book/task/completed'
        : session.taskProofReceived
        ? '/app/book/task/proof'
        : '/app/book/task/live';
    return GlobalProfileContextAction(
      id: 'care-active-task',
      title: 'Your active task',
      detail: '${task.type.label} · ${task.city}',
      actionLabel: session.taskReleased ? 'View receipt' : 'Open task',
      icon: Icons.task_alt_outlined,
      accentColor: const Color(0xFF2563EB),
      gradientColors: const [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
      onPressed: () => onOpenRoute(route),
    );
  }

  final salonOrigin = activeSubAction == 'salon';
  return GlobalProfileContextAction(
    id: salonOrigin ? 'care-doctor-discovery' : 'care-salon-discovery',
    title: salonOrigin ? 'Book a doctor' : 'Book a salon',
    detail: salonOrigin
        ? 'Choose clinic, hospital OPD, video or follow-up care.'
        : 'Choose a salon visit, home visit, makeup or package.',
    actionLabel: salonOrigin ? 'Find a doctor' : 'Find a salon',
    icon: salonOrigin
        ? Icons.medical_services_outlined
        : Icons.content_cut_rounded,
    accentColor: const Color(0xFF0F766E),
    gradientColors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
    onPressed: () =>
        onOpenRoute(salonOrigin ? '/app/book/doctor' : '/app/book/salon'),
  );
}

class BookPageScaffold extends StatelessWidget {
  const BookPageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.body,
    this.activeLocalAction = '',
    this.fallbackBackRoute = '/app/book',
    this.showBack = true,
    this.trailing,
    this.bottomAction,
    super.key,
  });

  final BookSession session;
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
    final currentPath = GoRouterState.of(context).uri.path;
    final routeSubAction = currentPath.startsWith('/app/book/doctor')
        ? 'doctor'
        : currentPath.startsWith('/app/book/salon')
        ? 'salon'
        : currentPath.startsWith('/app/book/bus')
        ? 'bus'
        : '';
    final activeSubAction = routeSubAction.isNotEmpty
        ? routeSubAction
        : const {'doctor', 'salon', 'bus'}.contains(activeLocalAction)
        ? activeLocalAction
        : '';
    final travelNavigation = activeSubAction == 'bus';
    final navigationFamilyId = travelNavigation ? 'ride' : 'book';

    void leaveContentDepth() {
      session.clearMessages();
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallbackBackRoute);
      }
    }

    void openLocal(String route) {
      session.clearMessages();
      context.push(route);
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

    void switchGlobalDestination(String route) {
      session.clearMessages();
      openMoolConnectedRoute(
        context,
        activeFamilyId: navigationFamilyId,
        route: route,
      );
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
                    keyName: 'book-back',
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
              keyName: travelNavigation
                  ? 'ride-global-chat'
                  : 'care-global-chat',
              onPressed: openChat,
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: MoolSpacing.sm),
              child:
                  trailing ??
                  IconButton.outlined(
                    key: const Key('book-help'),
                    tooltip: 'Booking support',
                    onPressed: () => context.go(
                      Uri(
                        path: '/app/chat',
                        queryParameters: {
                          'type': 'support',
                          'return': GoRouterState.of(context).uri.toString(),
                        },
                      ).toString(),
                    ),
                    icon: const Icon(Icons.support_agent_rounded),
                  ),
            ),
            if (!showBack)
              Padding(
                padding: const EdgeInsets.only(right: MoolSpacing.sm),
                child: MoolGlobalProfileShortcutV2(
                  keyName: travelNavigation
                      ? 'travel-global-profile'
                      : 'care-global-profile',
                  onPressed: () => showGlobalProfilePanelV2(
                    context,
                    contextAction: travelNavigation
                        ? _busTravelProfileContext(session, openGlobal)
                        : _careProfileContext(
                            session,
                            activeSubAction,
                            openGlobal,
                          ),
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
                  BookMessageBanner(session: session),
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
          activeId: navigationFamilyId,
          destinationLabel: travelNavigation ? 'Travel' : 'Care',
          selectedLocalIndex: travelNavigation
              ? 3
              : activeSubAction == 'salon'
              ? 2
              : 0,
          localActionCount: travelNavigation ? 4 : 3,
          localNavigation: travelNavigation
              ? MoolLocalNavigationRail(
                  key: const Key('travel-bus-local-navigation'),
                  familyId: 'ride',
                  surfaceTone: MoolLocalNavigationSurfaceTone.light,
                  semanticLabel: 'Travel choices: Bike, Auto, Cab and Bus.',
                  activeId: 'bus',
                  actions: [
                    for (final entry in const [
                      ('bike', 'Bike', Icons.two_wheeler_outlined),
                      ('auto', 'Auto', Icons.electric_rickshaw_outlined),
                      ('cab', 'Cab', Icons.local_taxi_outlined),
                    ])
                      MoolLocalNavigationAction(
                        keyName: 'travel-local-${entry.$1}',
                        id: entry.$1,
                        label: entry.$2,
                        icon: entry.$3,
                        onPressed: () => switchGlobalDestination(
                          '/app/ride/book?type=${entry.$1}',
                        ),
                      ),
                    const MoolLocalNavigationAction(
                      keyName: 'travel-local-bus',
                      id: 'bus',
                      label: 'Bus',
                      icon: Icons.directions_bus_filled_outlined,
                    ),
                  ],
                )
              : MoolLocalNavigationRail(
                  key: const Key('care-book-local-navigation'),
                  familyId: 'book',
                  surfaceTone: MoolLocalNavigationSurfaceTone.light,
                  semanticLabel: 'Care choices: Doctor, Medicine and Salon.',
                  activeId: activeSubAction,
                  actions: [
                    MoolLocalNavigationAction(
                      keyName: 'care-local-doctor',
                      id: 'doctor',
                      label: 'Doctor',
                      icon: Icons.medical_services_outlined,
                      onPressed: activeSubAction == 'doctor'
                          ? null
                          : () => openLocal('/app/book/doctor'),
                    ),
                    MoolLocalNavigationAction(
                      keyName: 'care-local-medicine',
                      id: 'medicine',
                      label: 'Medicine',
                      icon: Icons.medication_outlined,
                      onPressed: () =>
                          switchGlobalDestination('/app/buy?sub=medicine'),
                    ),
                    MoolLocalNavigationAction(
                      keyName: 'care-local-salon',
                      id: 'salon',
                      label: 'Salon',
                      icon: Icons.content_cut_rounded,
                      onPressed: activeSubAction == 'salon'
                          ? null
                          : () => openLocal('/app/book/salon'),
                    ),
                  ],
                ),
          onOpenMool: () => openGlobal('/app/mool?from=$navigationFamilyId'),
          onOpenAction: (action) => switchGlobalDestination(action.route),
          onPreviousLocalAction: () {
            final routes = travelNavigation
                ? const [
                    '/app/ride/book?type=bike',
                    '/app/ride/book?type=auto',
                    '/app/ride/book?type=cab',
                    '/app/book/bus',
                  ]
                : const [
                    '/app/book/doctor',
                    '/app/buy?sub=medicine',
                    '/app/book/salon',
                  ];
            final current = travelNavigation
                ? 3
                : activeSubAction == 'salon'
                ? 2
                : 0;
            switchGlobalDestination(
              routes[(current - 1 + routes.length) % routes.length],
            );
          },
          onNextLocalAction: () {
            final routes = travelNavigation
                ? const [
                    '/app/ride/book?type=bike',
                    '/app/ride/book?type=auto',
                    '/app/ride/book?type=cab',
                    '/app/book/bus',
                  ]
                : const [
                    '/app/book/doctor',
                    '/app/buy?sub=medicine',
                    '/app/book/salon',
                  ];
            final current = travelNavigation
                ? 3
                : activeSubAction == 'salon'
                ? 2
                : 0;
            switchGlobalDestination(routes[(current + 1) % routes.length]);
          },
          onOpenChat: openChat,
        ),
      ),
    );
  }
}

class BookMessageBanner extends StatelessWidget {
  const BookMessageBanner({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    final error = session.errorMessage;
    final notice = session.noticeMessage;
    if (error == null && notice == null) return const SizedBox.shrink();
    final isError = error != null;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key(isError ? 'book-error' : 'book-notice'),
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
              key: const Key('dismiss-book-message'),
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

class BookCard extends StatelessWidget {
  const BookCard({
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

class BookSectionTitle extends StatelessWidget {
  const BookSectionTitle(this.title, {this.detail, super.key});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: MoolColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 2),
          Text(
            detail!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class BookFact extends StatelessWidget {
  const BookFact({
    required this.icon,
    required this.title,
    required this.detail,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFECECFB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: MoolColors.navy, size: 21),
        ),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: MoolColors.ink,
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
