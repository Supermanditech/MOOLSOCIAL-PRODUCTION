import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_theme.dart';
import '../../features/journey01/widgets/journey_frame.dart';
import 'mool_global_navigation_v2.dart';

@immutable
class MvpActionChoiceSpec {
  const MvpActionChoiceSpec({
    required this.id,
    required this.label,
    required this.supportingLabel,
    required this.route,
    required this.icon,
  });

  final String id;
  final String label;
  final String supportingLabel;
  final String route;
  final IconData icon;
}

@immutable
class MvpActionChoiceRootSpec {
  const MvpActionChoiceRootSpec({
    required this.sectionLabel,
    required this.headline,
    required this.supportingText,
    required this.actions,
  });

  final String sectionLabel;
  final String headline;
  final String supportingText;
  final List<MvpActionChoiceSpec> actions;
}

const personalEatActionChoices = <MvpActionChoiceSpec>[
  MvpActionChoiceSpec(
    id: 'order-food',
    label: 'Order Food',
    supportingLabel: 'Choose food and get it delivered',
    route: '/app/eat/home',
    icon: Icons.delivery_dining_outlined,
  ),
  MvpActionChoiceSpec(
    id: 'book-table',
    label: 'Book Table',
    supportingLabel: 'Choose a restaurant and dining time',
    route: '/app/eat/table',
    icon: Icons.table_restaurant_outlined,
  ),
];

const personalRideActionChoices = <MvpActionChoiceSpec>[
  MvpActionChoiceSpec(
    id: 'bike',
    label: 'Bike',
    supportingLabel: 'Quick solo ride for nearby trips',
    route: '/app/ride/book?type=bike',
    icon: Icons.two_wheeler_outlined,
  ),
  MvpActionChoiceSpec(
    id: 'auto',
    label: 'Auto',
    supportingLabel: 'Everyday three-wheeler ride',
    route: '/app/ride/book?type=auto',
    icon: Icons.electric_rickshaw_outlined,
  ),
  MvpActionChoiceSpec(
    id: 'cab',
    label: 'Cab',
    supportingLabel: 'Comfortable car for your trip',
    route: '/app/ride/book?type=cab',
    icon: Icons.local_taxi_outlined,
  ),
];

const personalBookActionChoices = <MvpActionChoiceSpec>[
  MvpActionChoiceSpec(
    id: 'doctor',
    label: 'Doctor',
    supportingLabel: 'Choose a doctor and available time',
    route: '/app/book/doctor',
    icon: Icons.medical_services_outlined,
  ),
  MvpActionChoiceSpec(
    id: 'salon',
    label: 'Salon',
    supportingLabel: 'Choose a salon service and time',
    route: '/app/book/salon',
    icon: Icons.content_cut_rounded,
  ),
];

const personalWorkActionChoices = <MvpActionChoiceSpec>[
  MvpActionChoiceSpec(
    id: 'earn-today',
    label: 'Earn Today',
    supportingLabel: 'Find verified, funded work near you',
    route: '/app/work/earn',
    icon: Icons.payments_outlined,
  ),
  MvpActionChoiceSpec(
    id: 'workspace',
    label: 'Workspace',
    supportingLabel: 'Choose and build the Workspace for your role',
    route: '/app/work/my-work',
    icon: Icons.work_outline_rounded,
  ),
];

const personalMvpActionChoiceRoots = <String, MvpActionChoiceRootSpec>{
  'eat': MvpActionChoiceRootSpec(
    sectionLabel: 'Eat',
    headline: 'What would you like?',
    supportingText: 'Order now or plan a table in one tap.',
    actions: personalEatActionChoices,
  ),
  'ride': MvpActionChoiceRootSpec(
    sectionLabel: 'Ride',
    headline: 'How do you want to ride?',
    supportingText: 'Choose a vehicle and move forward in one tap.',
    actions: personalRideActionChoices,
  ),
  'book': MvpActionChoiceRootSpec(
    sectionLabel: 'Book',
    headline: 'What would you like to book?',
    supportingText: 'Choose your next appointment in one tap.',
    actions: personalBookActionChoices,
  ),
  'work': MvpActionChoiceRootSpec(
    sectionLabel: 'Work',
    headline: 'What would you like to do?',
    supportingText: 'Find work or open your workspace in one tap.',
    actions: personalWorkActionChoices,
  ),
};

class MvpActionChoiceRootV2 extends StatefulWidget {
  const MvpActionChoiceRootV2({
    required this.sectionLabel,
    required this.headline,
    required this.supportingText,
    required this.actions,
    required this.onBack,
    required this.onOpenAction,
    required this.onOpenMainAction,
    required this.onOpenMool,
    required this.onOpenChat,
    super.key,
  });

  final String sectionLabel;
  final String headline;
  final String supportingText;
  final List<MvpActionChoiceSpec> actions;
  final VoidCallback onBack;
  final ValueChanged<MvpActionChoiceSpec> onOpenAction;
  final ValueChanged<PersonalMoolActionSpec> onOpenMainAction;
  final VoidCallback onOpenMool;
  final VoidCallback onOpenChat;

  @override
  State<MvpActionChoiceRootV2> createState() => _MvpActionChoiceRootV2State();
}

class _MvpActionChoiceRootV2State extends State<MvpActionChoiceRootV2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: MoolMotion.standard,
  );

  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations || media.accessibleNavigation;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _arrival.value = 1;
    } else {
      _arrival.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _arrival.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return PopScope<Object?>(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: MoolColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: MoolColors.canvas,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          key: Key('mvp-action-root-${widget.sectionLabel.toLowerCase()}'),
          backgroundColor: MoolColors.canvas,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: MoolMetrics.maximumContentWidth,
                ),
                child: Column(
                  children: [
                    _ActionChoiceHeader(
                      sectionLabel: widget.sectionLabel,
                      headline: widget.headline,
                      supportingText: widget.supportingText,
                    ),
                    Expanded(
                      child: _ActionChoiceList(
                        sectionLabel: widget.sectionLabel,
                        actions: widget.actions,
                        arrival: _arrival,
                        onOpenAction: widget.onOpenAction,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: MoolGlobalNavigationV2(
            activeId: widget.sectionLabel.toLowerCase(),
            onOpenMool: widget.onOpenMool,
            onOpenAction: widget.onOpenMainAction,
            onOpenChat: widget.onOpenChat,
          ),
        ),
      ),
    );
  }
}

class _ActionChoiceHeader extends StatelessWidget {
  const _ActionChoiceHeader({
    required this.sectionLabel,
    required this.headline,
    required this.supportingText,
  });

  final String sectionLabel;
  final String headline;
  final String supportingText;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MoolColors.navy, Color(0xFF24207A)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -42,
            top: -54,
            child: _OrbitRing(size: 142, opacity: .10),
          ),
          const Positioned(
            right: 18,
            bottom: -40,
            child: _OrbitRing(size: 92, opacity: .08),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.xs,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sectionLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.xs),
                Semantics(
                  header: true,
                  child: Text(
                    headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  supportingText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                const PrototypeIdentityLine(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitRing extends StatelessWidget {
  const _OrbitRing({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: opacity),
            width: 18,
          ),
        ),
      ),
    );
  }
}

class _ActionChoiceList extends StatelessWidget {
  const _ActionChoiceList({
    required this.sectionLabel,
    required this.actions,
    required this.arrival,
    required this.onOpenAction,
  });

  final String sectionLabel;
  final List<MvpActionChoiceSpec> actions;
  final Animation<double> arrival;
  final ValueChanged<MvpActionChoiceSpec> onOpenAction;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: Key('mvp-action-${sectionLabel.toLowerCase()}-list'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.lg,
        MoolSpacing.md,
        MoolSpacing.lg,
      ),
      itemCount: actions.length,
      separatorBuilder: (_, _) => const SizedBox(height: MoolSpacing.sm),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _ActionChoiceArrival(
          action: action,
          index: index,
          animation: arrival,
          onTap: () => onOpenAction(action),
        );
      },
    );
  }
}

class _ActionChoiceArrival extends StatelessWidget {
  const _ActionChoiceArrival({
    required this.action,
    required this.index,
    required this.animation,
    required this.onTap,
  });

  final MvpActionChoiceSpec action;
  final int index;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = index * .12;
    final end = (start + .78).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = Interval(
          start,
          end,
          curve: MoolMotion.enter,
        ).transform(animation.value);
        final direction = index.isEven ? -1.0 : 1.0;
        return Opacity(
          key: Key('mvp-action-arrival-${action.id}'),
          opacity: progress,
          child: Transform.translate(
            offset: Offset(direction * 18 * (1 - progress), 6 * (1 - progress)),
            child: Transform.scale(
              scale: .985 + (.015 * progress),
              child: child,
            ),
          ),
        );
      },
      child: MoolCardSurface(
        key: Key('mvp-action-choice-${action.id}'),
        onTap: onTap,
        semanticLabel: 'Open ${action.label}',
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0x0F000080),
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                ),
                child: Icon(action.icon, color: MoolColors.navy, size: 25),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 17,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.supportingLabel,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 11.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              const Icon(
                Icons.arrow_forward_rounded,
                color: MoolColors.success,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
