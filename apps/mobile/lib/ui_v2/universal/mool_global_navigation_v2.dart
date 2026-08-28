import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_theme.dart';

@immutable
class PersonalMoolActionSpec {
  const PersonalMoolActionSpec({
    required this.id,
    required this.label,
    required this.route,
    required this.icon,
  });

  final String id;
  final String label;
  final String route;
  final IconData icon;
}

@immutable
class MoolDirectActionSpec {
  const MoolDirectActionSpec({
    required this.id,
    required this.label,
    required this.route,
    required this.icon,
  });

  final String id;
  final String label;
  final String route;
  final IconData icon;
}

void openMoolConnectedRoute(
  BuildContext context, {
  required String activeFamilyId,
  required String route,
}) {
  final sameFamily = moolActionFamilyIdForRoute(route) == activeFamilyId;
  if (sameFamily) {
    context.pushReplacement(route);
  } else {
    context.push(route);
  }
}

@immutable
class MoolActionFamilySpec {
  const MoolActionFamilySpec({
    required this.id,
    required this.label,
    required this.route,
    required this.icon,
    required this.actions,
  });

  final String id;
  final String label;
  final String route;
  final IconData icon;
  final List<MoolDirectActionSpec> actions;
}

MoolActionFamilySpec moolActionFamilyById(String familyId) =>
    moolActionFamilies.firstWhere((family) => family.id == familyId);

MoolDirectActionSpec moolDefaultActionForFamily(String familyId) {
  final family = moolActionFamilyById(familyId);
  return family.actions.firstWhere(
    (action) => action.route == family.route,
    orElse: () => family.actions.first,
  );
}

/// Resolves the customer-facing domain from the canonical catalogue instead
/// of assuming that a route's path prefix is its presentation owner.
///
/// Care/Medicine deliberately reuses Buy commerce, and Travel/Bus deliberately
/// reuses Book booking. Exact catalogue membership therefore wins over the
/// legacy route namespace.
String? moolActionFamilyIdForRoute(String route) {
  for (final family in moolActionFamilies) {
    if (family.route == route ||
        family.actions.any((action) => action.route == route)) {
      return family.id;
    }
  }
  final path = Uri.tryParse(route)?.path;
  if (path == null) return null;
  for (final familyId in const [
    'social',
    'buy',
    'eat',
    'ride',
    'book',
    'work',
  ]) {
    final familyRoot = '/app/$familyId';
    if (path == familyRoot || path.startsWith('$familyRoot/')) return familyId;
  }
  return null;
}

const moolActionFamilies = <MoolActionFamilySpec>[
  MoolActionFamilySpec(
    id: 'social',
    label: 'Social',
    icon: Icons.people_alt_outlined,
    route: '/app/social',
    actions: [
      MoolDirectActionSpec(
        id: 'videos',
        label: 'Home',
        icon: Icons.home_outlined,
        route: '/app/social?sub=videos',
      ),
      MoolDirectActionSpec(
        id: 'shorts',
        label: 'Shorts',
        icon: Icons.smart_display_outlined,
        route: '/app/social?sub=shorts',
      ),
      MoolDirectActionSpec(
        id: 'create',
        label: 'Create',
        icon: Icons.add_circle_outline_rounded,
        route: '/app/social?sub=create',
      ),
      MoolDirectActionSpec(
        id: 'feed',
        label: 'Feed',
        icon: Icons.dynamic_feed_outlined,
        route: '/app/social?sub=feed',
      ),
    ],
  ),
  MoolActionFamilySpec(
    id: 'buy',
    label: 'Shop',
    icon: Icons.storefront_outlined,
    route: '/app/buy?sub=shop',
    actions: [
      MoolDirectActionSpec(
        id: 'wholesale',
        label: 'Wholesale',
        icon: Icons.inventory_2_outlined,
        route: '/app/buy?sub=wholesale',
      ),
      MoolDirectActionSpec(
        id: 'orders',
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        route: '/app/buy?sub=orders',
      ),
    ],
  ),
  MoolActionFamilySpec(
    id: 'eat',
    label: 'Food',
    icon: Icons.restaurant_outlined,
    route: '/app/eat/home',
    actions: [
      MoolDirectActionSpec(
        id: 'order',
        label: 'Order Food',
        icon: Icons.restaurant_menu_rounded,
        route: '/app/eat/home',
      ),
      MoolDirectActionSpec(
        id: 'table',
        label: 'Book Table',
        icon: Icons.table_restaurant_outlined,
        route: '/app/eat/table',
      ),
    ],
  ),
  MoolActionFamilySpec(
    id: 'ride',
    label: 'Travel',
    icon: Icons.explore_outlined,
    route: '/app/ride/book?type=bike',
    actions: [
      MoolDirectActionSpec(
        id: 'bike',
        label: 'Bike',
        icon: Icons.two_wheeler_outlined,
        route: '/app/ride/book?type=bike',
      ),
      MoolDirectActionSpec(
        id: 'auto',
        label: 'Auto',
        icon: Icons.electric_rickshaw_outlined,
        route: '/app/ride/book?type=auto',
      ),
      MoolDirectActionSpec(
        id: 'cab',
        label: 'Cab',
        icon: Icons.local_taxi_outlined,
        route: '/app/ride/book?type=cab',
      ),
      MoolDirectActionSpec(
        id: 'bus',
        label: 'Bus',
        icon: Icons.directions_bus_filled_outlined,
        route: '/app/book/bus',
      ),
    ],
  ),
  MoolActionFamilySpec(
    id: 'book',
    label: 'Care',
    icon: Icons.health_and_safety_outlined,
    route: '/app/book/doctor',
    actions: [
      MoolDirectActionSpec(
        id: 'doctor',
        label: 'Doctor',
        icon: Icons.medical_services_outlined,
        route: '/app/book/doctor',
      ),
      MoolDirectActionSpec(
        id: 'medicine',
        label: 'Medicine',
        icon: Icons.medication_outlined,
        route: '/app/buy?sub=medicine',
      ),
      MoolDirectActionSpec(
        id: 'salon',
        label: 'Salon',
        icon: Icons.content_cut_rounded,
        route: '/app/book/salon',
      ),
    ],
  ),
  MoolActionFamilySpec(
    id: 'work',
    label: 'Work',
    icon: Icons.work_outline_rounded,
    route: '/app/work/home',
    actions: [
      MoolDirectActionSpec(
        id: 'earn',
        label: 'Earn Today',
        icon: Icons.bolt_rounded,
        route: '/app/work/earn',
      ),
      MoolDirectActionSpec(
        id: 'workspace',
        label: 'Workspace',
        icon: Icons.dashboard_customize_outlined,
        route: '/app/work/my-work',
      ),
    ],
  ),
];

final personalMoolRootActions = List<PersonalMoolActionSpec>.unmodifiable(
  moolActionFamilies.map(
    (family) => PersonalMoolActionSpec(
      id: family.id,
      label: family.label,
      route: family.route,
      icon: family.icon,
    ),
  ),
);

const moolGlobalNavigationHeroTag = 'moolsocial-global-navigation-hero';

CustomTransitionPage<void> moolMainDestinationPage({
  required GoRouterState state,
  required Widget child,
}) {
  final accessibility =
      WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
  final reduceRouteMotion =
      accessibility.disableAnimations || accessibility.accessibleNavigation;
  final routeDuration = reduceRouteMotion ? Duration.zero : MoolMotion.standard;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: routeDuration,
    reverseTransitionDuration: routeDuration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final media = MediaQuery.maybeOf(context);
      final reduceMotion =
          (media?.disableAnimations ?? false) ||
          (media?.accessibleNavigation ?? false);
      if (reduceMotion) return child;
      final progress = CurvedAnimation(
        parent: animation,
        curve: MoolMotion.enter,
        reverseCurve: MoolMotion.change,
      );
      return FadeTransition(
        key: const Key('moolsocial-main-destination-motion'),
        opacity: Tween<double>(begin: .92, end: 1).animate(progress),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.035, 0),
            end: Offset.zero,
          ).animate(progress),
          child: child,
        ),
      );
    },
  );
}

const double moolDestinationFamilyRailHeight =
    MoolLocalNavigationTokens.railHeight;
const double moolDestinationFamilyRailSurfaceOpacity = 0;
const Duration moolDestinationFamilyWaveDuration = Duration(milliseconds: 200);
const double moolDestinationFamilyBridgeOverlap = 8;
const double moolDestinationFamilyBridgeHeight =
    moolDestinationFamilyRailHeight + moolDestinationFamilyBridgeOverlap;

double moolAndroidExportedSemanticsClearance({
  required EdgeInsets viewPadding,
  required TargetPlatform platform,
}) {
  if (platform != TargetPlatform.android) return 0;
  const minimumExportedTarget = MoolMetrics.minimumTapTarget;
  final availableOverflow =
      MoolLocalNavigationTokens.destinationRailHeight - minimumExportedTarget;
  return (viewPadding.top - availableOverflow)
      .clamp(0, double.infinity)
      .toDouble();
}

/// Keeps destination-local choices visibly connected to the selected global
/// action without placing a panel between the customer and destination content.
class MoolGlobalChatShortcut extends StatelessWidget {
  const MoolGlobalChatShortcut({
    required this.keyName,
    required this.onPressed,
    this.onDarkSurface = false,
    super.key,
  });

  final String keyName;
  final VoidCallback onPressed;
  final bool onDarkSurface;

  @override
  Widget build(BuildContext context) {
    final foreground = onDarkSurface ? Colors.white : MoolColors.ink;
    final background = onDarkSurface
        ? Colors.white.withValues(alpha: .10)
        : Colors.white.withValues(alpha: .72);
    final border = onDarkSurface
        ? Colors.white.withValues(alpha: .24)
        : MoolColors.ink.withValues(alpha: .14);
    return Semantics(
      container: true,
      button: true,
      label: 'Open Chat',
      child: IconButton(
        key: ValueKey(keyName),
        tooltip: 'Open Chat',
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        style: IconButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: background,
          side: BorderSide(color: border),
          shape: const CircleBorder(),
        ),
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
      ),
    );
  }
}

class MoolGlobalNavigationController {
  bool get isOpen => _isOpen;

  bool _isOpen = false;
  Future<void> Function()? _close;

  Future<void> close() async {
    await _close?.call();
  }

  void _attach(Future<void> Function() close) {
    _close = close;
  }

  void _detach() {
    _close = null;
    _isOpen = false;
  }

  void _setOpen(bool value) {
    _isOpen = value;
  }
}

class MoolDestinationNavigationV2 extends StatefulWidget {
  const MoolDestinationNavigationV2({
    required this.activeId,
    required this.destinationLabel,
    required this.localNavigation,
    required this.selectedLocalIndex,
    required this.localActionCount,
    required this.onOpenMool,
    required this.onOpenAction,
    required this.onOpenChat,
    this.moolNavigationController,
    this.onPreviousLocalAction,
    this.onNextLocalAction,
    super.key,
  }) : assert(localActionCount > 0),
       assert(selectedLocalIndex >= 0),
       assert(selectedLocalIndex < localActionCount);

  final String activeId;
  final String destinationLabel;
  final Widget localNavigation;
  final int selectedLocalIndex;
  final int localActionCount;
  final VoidCallback? onOpenMool;
  final ValueChanged<PersonalMoolActionSpec> onOpenAction;
  final VoidCallback? onOpenChat;
  final MoolGlobalNavigationController? moolNavigationController;
  final VoidCallback? onPreviousLocalAction;
  final VoidCallback? onNextLocalAction;

  @visibleForTesting
  static void debugResetDisclosureSession() {}

  @override
  State<MoolDestinationNavigationV2> createState() =>
      _MoolDestinationNavigationV2State();
}

class _MoolDestinationNavigationV2State
    extends State<MoolDestinationNavigationV2> {
  @override
  Widget build(BuildContext context) {
    final family = moolActionFamilies.firstWhere(
      (candidate) => candidate.id == widget.activeId,
      orElse: () => moolActionFamilies.first,
    );
    final view = View.of(context);
    final exportedSemanticsClearance = moolAndroidExportedSemanticsClearance(
      viewPadding: EdgeInsets.fromViewPadding(
        view.viewPadding,
        view.devicePixelRatio,
      ),
      platform: defaultTargetPlatform,
    );
    return RepaintBoundary(
      key: const Key('moolsocial-single-home-launcher-shell'),
      child: DecoratedBox(
        key: const Key('moolsocial-uniform-destination-canvas'),
        decoration: const BoxDecoration(
          color: MoolLocalNavigationTokens.destinationCanvas,
          border: Border(
            top: BorderSide(
              color: MoolLocalNavigationTokens.destinationDivider,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            key: const Key('moolsocial-android-exported-semantics-clearance'),
            padding: EdgeInsets.only(bottom: exportedSemanticsClearance),
            child: SafeArea(
              top: false,
              maintainBottomViewPadding: true,
              minimum: const EdgeInsets.only(bottom: 2),
              child: SizedBox(
                key: const Key('moolsocial-compact-destination-rail'),
                height: MoolLocalNavigationTokens.destinationRailHeight,
                child: Row(
                  children: [
                    MoolGlobalNavigationV2(
                      activeId: widget.activeId,
                      onOpenMool: widget.onOpenMool,
                      onOpenAction: widget.onOpenAction,
                      onOpenChat: widget.onOpenChat,
                      controller: widget.moolNavigationController,
                      compact: true,
                    ),
                    const SizedBox(width: 2),
                    if (family.id != 'social') ...[
                      _MoolFamilyRootButton(
                        family: family,
                        onPressed: () => widget.onOpenAction(
                          PersonalMoolActionSpec(
                            id: family.id,
                            label: family.label,
                            route: family.route,
                            icon: family.icon,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                    ],
                    Expanded(child: widget.localNavigation),
                    const SizedBox(width: 2),
                    MoolGlobalChatNavigationV2(
                      controlKey: const Key('mool-global-chat'),
                      onOpenChat: widget.onOpenChat,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoolFamilyRootButton extends StatelessWidget {
  const _MoolFamilyRootButton({required this.family, required this.onPressed});

  final MoolActionFamilySpec family;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = MoolLocalNavigationTokens.navigationAccentForFamily(
      family.id,
    );
    final fixedCellWidth =
        MoolLocalNavigationTokens.destinationFixedCellWidthFor(
          MediaQuery.sizeOf(context).width,
        );
    return Semantics(
      container: true,
      button: true,
      label: 'Open ${family.label} home',
      onTap: onPressed,
      excludeSemantics: true,
      child: SizedBox(
        key: ValueKey('moolsocial-family-root-${family.id}'),
        width: fixedCellWidth,
        height: MoolLocalNavigationTokens.destinationRailHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('moolsocial-family-root-${family.id}-tap'),
            onTap: onPressed,
            splashColor: accent.withValues(alpha: .08),
            highlightColor: accent.withValues(alpha: .045),
            child: MoolDestinationIconLabel(
              key: ValueKey('moolsocial-family-root-${family.id}-icon-label'),
              label: family.label,
              icon: family.icon,
              color: accent.withValues(alpha: .84),
              emphasized: true,
            ),
          ),
        ),
      ),
    );
  }
}

class MoolDestinationFamilyWavePainter extends CustomPainter {
  MoolDestinationFamilyWavePainter({
    required this.accent,
    required this.fromLocalPosition,
    required this.toLocalPosition,
    required this.localActionCount,
    required this.progress,
    required this.selectedMainActionAnchor,
    required this.reducedMotion,
  }) : super(repaint: progress);

  final Color accent;
  final double fromLocalPosition;
  final double toLocalPosition;
  final int localActionCount;
  final Animation<double> progress;
  final Offset selectedMainActionAnchor;
  final bool reducedMotion;

  double get paintedLocalPosition =>
      fromLocalPosition +
      (toLocalPosition - fromLocalPosition) * progress.value;

  Offset familyFirstAnchor(Size size) => Offset(
    MoolLocalNavigationTokens.selectedCenterX(
      maxWidth: size.width,
      actionCount: localActionCount,
      selectedIndex: 0,
    ),
    moolDestinationFamilyRailHeight + moolDestinationFamilyBridgeOverlap / 2,
  );

  Offset familyLastAnchor(Size size) => Offset(
    MoolLocalNavigationTokens.selectedCenterX(
      maxWidth: size.width,
      actionCount: localActionCount,
      selectedIndex: localActionCount - 1,
    ),
    moolDestinationFamilyRailHeight + moolDestinationFamilyBridgeOverlap / 2,
  );

  Offset familyCrest(Size size) {
    final first = familyFirstAnchor(size);
    final last = familyLastAnchor(size);
    return Offset(
      (first.dx + last.dx) / 2,
      moolDestinationFamilyRailHeight - 2,
    );
  }

  Offset resolvedMainAnchor(Size size) => Offset(
    selectedMainActionAnchor.dx.clamp(0.0, size.width),
    size.height - 1,
  );

  Path reverseUPath(Size size) {
    final first = familyFirstAnchor(size);
    final last = familyLastAnchor(size);
    final crest = familyCrest(size);
    final halfSpan = (last.dx - first.dx) / 2;
    return Path()
      ..moveTo(first.dx, first.dy)
      ..cubicTo(
        first.dx + halfSpan * .44,
        crest.dy,
        crest.dx - halfSpan * .36,
        crest.dy,
        crest.dx,
        crest.dy,
      )
      ..cubicTo(
        crest.dx + halfSpan * .36,
        crest.dy,
        last.dx - halfSpan * .44,
        crest.dy,
        last.dx,
        last.dy,
      );
  }

  Path mainStemPath(Size size) {
    final main = resolvedMainAnchor(size);
    final crest = familyCrest(size);
    return Path()
      ..moveTo(main.dx, main.dy)
      ..cubicTo(
        main.dx,
        main.dy - 3,
        crest.dx,
        crest.dy + 5,
        crest.dx,
        crest.dy,
      );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final reverseU = reverseUPath(size);
    final stem = mainStemPath(size);
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3
      ..color = accent.withValues(alpha: .08);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = MoolLocalNavigationTokens.connectionLineStrokeWidth
      ..color = accent.withValues(
        alpha: MoolLocalNavigationTokens.connectionLineMaximumOpacity,
      );
    canvas
      ..drawPath(stem, glowPaint)
      ..drawPath(reverseU, glowPaint)
      ..drawPath(stem, linePaint)
      ..drawPath(reverseU, linePaint)
      ..drawCircle(
        resolvedMainAnchor(size),
        MoolLocalNavigationTokens.connectionDotRadius,
        linePaint..style = PaintingStyle.fill,
      );
  }

  @override
  bool shouldRepaint(covariant MoolDestinationFamilyWavePainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.fromLocalPosition != fromLocalPosition ||
        oldDelegate.toLocalPosition != toLocalPosition ||
        oldDelegate.localActionCount != localActionCount ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedMainActionAnchor != selectedMainActionAnchor ||
        oldDelegate.reducedMotion != reducedMotion;
  }
}

class MoolMainDomainMenu extends StatelessWidget {
  const MoolMainDomainMenu({
    required this.keyPrefix,
    required this.onOpenFamily,
    this.selectedFamilyId,
    super.key,
  });

  final String keyPrefix;
  final String? selectedFamilyId;
  final ValueChanged<MoolActionFamilySpec> onOpenFamily;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'MoolSocial main actions',
      child: Column(
        key: ValueKey('$keyPrefix-main-actions-only'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final family in moolActionFamilies)
            SizedBox(
              height: MoolLocalNavigationTokens.switcherRowHeight,
              child: _MoolMainDomainButton(
                keyPrefix: keyPrefix,
                family: family,
                selected: family.id == selectedFamilyId,
                onPressed: () => onOpenFamily(family),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoolMainDomainButton extends StatefulWidget {
  const _MoolMainDomainButton({
    required this.keyPrefix,
    required this.family,
    required this.selected,
    required this.onPressed,
  });

  final String keyPrefix;
  final MoolActionFamilySpec family;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_MoolMainDomainButton> createState() => _MoolMainDomainButtonState();
}

class _MoolMainDomainButtonState extends State<_MoolMainDomainButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final family = widget.family;
    final accent = MoolLocalNavigationTokens.navigationAccentForFamily(
      family.id,
    );
    final radius = BorderRadius.circular(
      MoolLocalNavigationTokens.switcherRowRadius,
    );
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.selected
          ? '${family.label}, current domain'
          : 'Open ${family.label}',
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: AnimatedScale(
        key: ValueKey('${widget.keyPrefix}-family-${family.id}-press-motion'),
        scale: _pressed ? .98 : 1,
        duration: MoolHomeHubTokens.accessibleDuration(
          context,
          MoolHomeHubTokens.pressDuration,
        ),
        curve: MoolMotion.change,
        child: AnimatedContainer(
          key: ValueKey('${widget.keyPrefix}-family-${family.id}'),
          duration: MoolHomeHubTokens.accessibleDuration(
            context,
            MoolLocalNavigationTokens.selectionDuration,
          ),
          curve: MoolMotion.change,
          decoration: BoxDecoration(
            color: widget.selected
                ? accent.withValues(
                    alpha:
                        MoolLocalNavigationTokens.switcherSelectedFillOpacity,
                  )
                : null,
            borderRadius: radius,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onHighlightChanged: (pressed) {
                if (_pressed != pressed) setState(() => _pressed = pressed);
              },
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onPressed();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal:
                      MoolLocalNavigationTokens.switcherRowHorizontalPadding,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: MoolHomeHubTokens.accessibleDuration(
                        context,
                        MoolLocalNavigationTokens.selectionDuration,
                      ),
                      width:
                          MoolLocalNavigationTokens.switcherIconContainerSize,
                      height:
                          MoolLocalNavigationTokens.switcherIconContainerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(
                          alpha: widget.selected
                              ? MoolLocalNavigationTokens
                                    .switcherSelectedIconFillOpacity
                              : MoolLocalNavigationTokens
                                    .switcherIconFillOpacity,
                        ),
                        border: Border.all(
                          color: MoolLocalNavigationTokens.switcherIconBorder,
                        ),
                      ),
                      child: Icon(
                        family.icon,
                        color: accent,
                        size: MoolLocalNavigationTokens.switcherIconSize,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        family.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontFamily:
                              MoolLocalNavigationTokens.destinationFontFamily,
                          fontSize:
                              MoolLocalNavigationTokens.destinationLabelSize,
                          height: MoolLocalNavigationTokens
                              .destinationLabelLineHeight,
                          fontWeight: widget.selected
                              ? MoolLocalNavigationTokens
                                    .destinationSelectedLabelWeight
                              : MoolLocalNavigationTokens
                                    .destinationLabelWeight,
                        ),
                      ),
                    ),
                    if (widget.selected)
                      Container(
                        key: ValueKey(
                          '${widget.keyPrefix}-family-${family.id}-indicator',
                        ),
                        width: MoolLocalNavigationTokens
                            .switcherSelectedIndicatorWidth,
                        height: MoolLocalNavigationTokens
                            .switcherSelectedIndicatorHeight,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MoolActionChooser extends StatefulWidget {
  const MoolActionChooser({
    required this.initialFamilyId,
    required this.keyPrefix,
    required this.onOpenAction,
    super.key,
  });

  final String initialFamilyId;
  final String keyPrefix;
  final ValueChanged<MoolDirectActionSpec> onOpenAction;

  @override
  State<MoolActionChooser> createState() => _MoolActionChooserState();
}

class _MoolActionChooserState extends State<MoolActionChooser> {
  late String _selectedFamilyId = _resolvedFamilyId(widget.initialFamilyId);

  static String _resolvedFamilyId(String candidate) =>
      moolActionFamilies.any((family) => family.id == candidate)
      ? candidate
      : moolActionFamilies.first.id;

  @override
  void didUpdateWidget(covariant MoolActionChooser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFamilyId != widget.initialFamilyId) {
      _selectedFamilyId = _resolvedFamilyId(widget.initialFamilyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFamily = moolActionFamilies.firstWhere(
      (family) => family.id == _selectedFamilyId,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 390;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              key: ValueKey('${widget.keyPrefix}-family-grid'),
              height: compact ? 132 : 164,
              child: _MoolActionFamilyGrid(
                keyPrefix: widget.keyPrefix,
                selectedFamilyId: _selectedFamilyId,
                onSelected: (family) {
                  if (_selectedFamilyId == family.id) return;
                  setState(() => _selectedFamilyId = family.id);
                  HapticFeedback.selectionClick();
                },
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            AnimatedSwitcher(
              duration: MoolHomeHubTokens.accessibleDuration(
                context,
                MoolLocalNavigationTokens.selectionDuration,
              ),
              switchInCurve: MoolMotion.enter,
              switchOutCurve: MoolMotion.change,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: .99, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: _MoolSelectedFamilyActions(
                key: ValueKey(
                  '${widget.keyPrefix}-selected-family-${selectedFamily.id}',
                ),
                keyPrefix: widget.keyPrefix,
                family: selectedFamily,
                onOpenAction: widget.onOpenAction,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MoolActionFamilyGrid extends StatelessWidget {
  const _MoolActionFamilyGrid({
    required this.keyPrefix,
    required this.selectedFamilyId,
    required this.onSelected,
  });

  final String keyPrefix;
  final String selectedFamilyId;
  final ValueChanged<MoolActionFamilySpec> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          Expanded(
            child: Row(
              children: [
                for (var column = 0; column < 3; column++) ...[
                  Expanded(
                    child: _MoolActionFamilyButton(
                      keyPrefix: keyPrefix,
                      family: moolActionFamilies[row * 3 + column],
                      selected:
                          moolActionFamilies[row * 3 + column].id ==
                          selectedFamilyId,
                      onPressed: () =>
                          onSelected(moolActionFamilies[row * 3 + column]),
                    ),
                  ),
                  if (column != 2) const SizedBox(width: MoolSpacing.xs),
                ],
              ],
            ),
          ),
          if (row == 0) const SizedBox(height: MoolSpacing.xs),
        ],
      ],
    );
  }
}

class _MoolActionFamilyButton extends StatelessWidget {
  const _MoolActionFamilyButton({
    required this.keyPrefix,
    required this.family,
    required this.selected,
    required this.onPressed,
  });

  final String keyPrefix;
  final MoolActionFamilySpec family;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = MoolHomeHubTokens.accentForFamily(family.id);
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      selected: selected,
      label: family.label,
      onTap: onPressed,
      excludeSemantics: true,
      child: AnimatedContainer(
        key: ValueKey('$keyPrefix-family-${family.id}'),
        duration: MoolHomeHubTokens.accessibleDuration(
          context,
          MoolHomeHubTokens.pressDuration,
        ),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: .14)
              : Colors.white.withValues(alpha: .88),
          borderRadius: radius,
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: .55)
                : const Color(0xFFE2E5EB),
          ),
          boxShadow: selected ? MoolShadows.card : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(MoolSpacing.xs),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    family.icon,
                    color: selected ? accent : MoolColors.navy,
                    size: 23,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    family.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: MoolColors.ink,
                      fontSize: 12.5,
                      height: 1.1,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
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

class _MoolSelectedFamilyActions extends StatelessWidget {
  const _MoolSelectedFamilyActions({
    required this.keyPrefix,
    required this.family,
    required this.onOpenAction,
    super.key,
  });

  final String keyPrefix;
  final MoolActionFamilySpec family;
  final ValueChanged<MoolDirectActionSpec> onOpenAction;

  @override
  Widget build(BuildContext context) {
    final accent = MoolHomeHubTokens.accentForFamily(family.id);
    final rows = <List<MoolDirectActionSpec>>[];
    for (var index = 0; index < family.actions.length; index += 2) {
      rows.add(
        family.actions.sublist(
          index,
          index + 2 > family.actions.length ? family.actions.length : index + 2,
        ),
      );
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '${family.label} actions',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E5EB)),
          boxShadow: MoolShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MoolSpacing.xs,
                  0,
                  MoolSpacing.xs,
                  MoolSpacing.xs,
                ),
                child: Text(
                  family.label,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 17,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.15,
                  ),
                ),
              ),
              for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
                SizedBox(
                  height: 60,
                  child: rows[rowIndex].length == 1
                      ? FractionallySizedBox(
                          widthFactor: .5,
                          child: _MoolDirectActionButton(
                            keyPrefix: keyPrefix,
                            familyId: family.id,
                            action: rows[rowIndex].single,
                            accent: accent,
                            onPressed: () =>
                                onOpenAction(rows[rowIndex].single),
                          ),
                        )
                      : Row(
                          children: [
                            for (
                              var column = 0;
                              column < rows[rowIndex].length;
                              column++
                            ) ...[
                              Expanded(
                                child: _MoolDirectActionButton(
                                  keyPrefix: keyPrefix,
                                  familyId: family.id,
                                  action: rows[rowIndex][column],
                                  accent: accent,
                                  onPressed: () =>
                                      onOpenAction(rows[rowIndex][column]),
                                ),
                              ),
                              if (column == 0)
                                const SizedBox(width: MoolSpacing.xs),
                            ],
                          ],
                        ),
                ),
                if (rowIndex != rows.length - 1)
                  const SizedBox(height: MoolSpacing.xs),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MoolDirectActionButton extends StatelessWidget {
  const _MoolDirectActionButton({
    required this.keyPrefix,
    required this.familyId,
    required this.action,
    required this.accent,
    required this.onPressed,
  });

  final String keyPrefix;
  final String familyId;
  final MoolDirectActionSpec action;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      label: action.label,
      onTap: onPressed,
      excludeSemantics: true,
      child: SizedBox.expand(
        child: DecoratedBox(
          key: ValueKey('$keyPrefix-$familyId-${action.id}'),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .08),
            borderRadius: radius,
            border: Border.all(color: accent.withValues(alpha: .20)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(MoolSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon, color: accent, size: 19),
                    const SizedBox(width: MoolSpacing.xs),
                    Flexible(
                      child: Text(
                        action.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontSize: 12.5,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MoolConnectedActionNavigator extends StatefulWidget {
  const MoolConnectedActionNavigator({
    required this.initialFamilyId,
    required this.onOpenFamily,
    required this.onDismiss,
    super.key,
  });

  final String initialFamilyId;
  final ValueChanged<MoolActionFamilySpec> onOpenFamily;
  final VoidCallback onDismiss;

  @override
  State<MoolConnectedActionNavigator> createState() =>
      _MoolConnectedActionNavigatorState();
}

class _MoolConnectedActionNavigatorState
    extends State<MoolConnectedActionNavigator> {
  double _dragDy = 0;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      MoolLocalNavigationTokens.switcherRadius,
    );
    return GestureDetector(
      key: const Key('mool-connected-action-navigator-drag-surface'),
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _dragDy = 0,
      onVerticalDragUpdate: (details) => _dragDy += details.primaryDelta ?? 0,
      onVerticalDragEnd: (details) {
        if (_dragDy > 24 ||
            (details.primaryVelocity != null &&
                details.primaryVelocity! > 80)) {
          widget.onDismiss();
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: MoolLocalNavigationTokens.switcherShadow,
              blurRadius: MoolLocalNavigationTokens.switcherShadowBlurRadius,
              offset: MoolLocalNavigationTokens.switcherShadowOffset,
            ),
          ],
        ),
        child: ClipRRect(
          key: const Key('mool-connected-action-navigator'),
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: MoolLocalNavigationTokens.switcherBlurSigma,
              sigmaY: MoolLocalNavigationTokens.switcherBlurSigma,
            ),
            child: DecoratedBox(
              key: const Key('moolsocial-uniform-switcher-glass'),
              decoration: BoxDecoration(
                color: MoolLocalNavigationTokens.switcherCanvas,
                border: Border.all(
                  color: MoolLocalNavigationTokens.switcherBorder,
                ),
                borderRadius: radius,
              ),
              child: Padding(
                padding: const EdgeInsets.all(
                  MoolLocalNavigationTokens.switcherPadding,
                ),
                child: MoolMainDomainMenu(
                  selectedFamilyId: widget.initialFamilyId,
                  keyPrefix: 'mool-navigator',
                  onOpenFamily: widget.onOpenFamily,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MoolGlobalNavigationV2 extends StatefulWidget {
  const MoolGlobalNavigationV2({
    required this.activeId,
    required this.onOpenMool,
    required this.onOpenAction,
    required this.onOpenChat,
    this.controller,
    this.selectedMainActionAnchorKey,
    this.localNavigationExpanded,
    this.onToggleLocalNavigation,
    this.compact = false,
    this.compactOverlayAlignEnd = false,
    super.key,
  }) : assert(
         (localNavigationExpanded == null) == (onToggleLocalNavigation == null),
       );

  final String activeId;
  final VoidCallback? onOpenMool;
  final ValueChanged<PersonalMoolActionSpec> onOpenAction;
  final VoidCallback? onOpenChat;
  final MoolGlobalNavigationController? controller;
  final GlobalKey? selectedMainActionAnchorKey;
  final bool? localNavigationExpanded;
  final VoidCallback? onToggleLocalNavigation;
  final bool compact;
  final bool compactOverlayAlignEnd;

  @override
  State<MoolGlobalNavigationV2> createState() => _MoolGlobalNavigationV2State();
}

class _MoolGlobalNavigationV2State extends State<MoolGlobalNavigationV2>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _launcherLink = LayerLink();
  late final AnimationController _switcherController;
  LocalHistoryEntry? _historyEntry;
  bool _isOpen = false;
  bool _reduceMotion = false;
  bool _removingHistoryEntry = false;
  double _launcherDragDy = 0;

  @override
  void initState() {
    super.initState();
    _switcherController = AnimationController(
      vsync: this,
      duration: MoolLocalNavigationTokens.selectionDuration,
    );
    widget.controller?._attach(_closeConnectedNavigator);
  }

  @override
  void didUpdateWidget(covariant MoolGlobalNavigationV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(_closeConnectedNavigator);
      widget.controller?._setOpen(_isOpen);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final nextReduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    if (nextReduceMotion && !_reduceMotion && _isOpen) {
      _switcherController.value = 1;
    }
    _reduceMotion = nextReduceMotion;
  }

  @override
  void dispose() {
    _removeLocalHistoryEntry();
    widget.controller?._detach();
    _switcherController.dispose();
    super.dispose();
  }

  void _registerLocalHistoryEntry() {
    if (_historyEntry != null) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    final entry = LocalHistoryEntry(onRemove: _handleLocalHistoryRemoved);
    _historyEntry = entry;
    route.addLocalHistoryEntry(entry);
  }

  void _removeLocalHistoryEntry() {
    final entry = _historyEntry;
    if (entry == null) return;
    _historyEntry = null;
    _removingHistoryEntry = true;
    entry.remove();
    _removingHistoryEntry = false;
  }

  void _handleLocalHistoryRemoved() {
    _historyEntry = null;
    if (_removingHistoryEntry || !_isOpen) return;
    _closeConnectedNavigator(removeHistoryEntry: false);
  }

  Future<bool> _handleBackButton() {
    if (!_isOpen) return Future<bool>.value(false);
    _closeConnectedNavigator();
    return Future<bool>.value(true);
  }

  void _openConnectedNavigator() {
    if (_isOpen) return;
    setState(() => _isOpen = true);
    widget.controller?._setOpen(true);
    _overlayController.show();
    _registerLocalHistoryEntry();
    if (_reduceMotion) {
      _switcherController.value = 1;
    } else {
      _switcherController.forward(from: 0);
    }
  }

  Future<void> _closeConnectedNavigator({
    bool removeHistoryEntry = true,
  }) async {
    if (!_isOpen) return;
    if (removeHistoryEntry) _removeLocalHistoryEntry();
    if (_reduceMotion) {
      _switcherController.value = 0;
    } else {
      await _switcherController.reverse();
    }
    if (!mounted || !_isOpen) return;
    _overlayController.hide();
    widget.controller?._setOpen(false);
    setState(() => _isOpen = false);
  }

  void _toggleConnectedNavigator() {
    if (_isOpen) {
      _closeConnectedNavigator();
    } else {
      _openConnectedNavigator();
    }
  }

  void _openFamily(MoolActionFamilySpec family) {
    _removeLocalHistoryEntry();
    _switcherController.value = 0;
    _overlayController.hide();
    widget.controller?._setOpen(false);
    setState(() => _isOpen = false);
    widget.onOpenAction(
      PersonalMoolActionSpec(
        id: family.id,
        label: family.label,
        route: family.route,
        icon: family.icon,
      ),
    );
  }

  Widget _buildEmbeddedSwitcher(BuildContext context) {
    final initialFamilyId =
        moolActionFamilies.any((family) => family.id == widget.activeId)
        ? widget.activeId
        : moolActionFamilies.first.id;
    final progress = CurvedAnimation(
      parent: _switcherController,
      curve: MoolMotion.enter,
      reverseCurve: MoolMotion.change,
    );
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('mool-switcher-outside-dismiss'),
              behavior: HitTestBehavior.opaque,
              onTap: _closeConnectedNavigator,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _launcherLink,
            showWhenUnlinked: false,
            targetAnchor: widget.compact && widget.compactOverlayAlignEnd
                ? Alignment.topRight
                : Alignment.topLeft,
            followerAnchor: widget.compact && widget.compactOverlayAlignEnd
                ? Alignment.bottomRight
                : Alignment.bottomLeft,
            offset: const Offset(0, -2),
            child: FadeTransition(
              opacity: progress,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, .035),
                  end: Offset.zero,
                ).animate(progress),
                child: ScaleTransition(
                  key: const Key('moolsocial-main-menu-arrival-motion'),
                  alignment: Alignment.bottomLeft,
                  scale: Tween<double>(begin: .96, end: 1).animate(progress),
                  child: SizedBox(
                    width: MoolLocalNavigationTokens.switcherWidth,
                    child: MoolConnectedActionNavigator(
                      initialFamilyId: initialFamilyId,
                      onOpenFamily: _openFamily,
                      onDismiss: _closeConnectedNavigator,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeId == 'mool' && !widget.compact) {
      return const SizedBox.shrink(
        key: Key('moolsocial-home-has-no-bottom-navigation'),
      );
    }
    final launcher = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (_) => _launcherDragDy = 0,
      onVerticalDragUpdate: (details) {
        _launcherDragDy += details.primaryDelta ?? 0;
      },
      onVerticalDragEnd: (details) {
        if (_launcherDragDy < -24 ||
            (details.primaryVelocity != null &&
                details.primaryVelocity! < -80)) {
          _openConnectedNavigator();
        }
      },
      child: CompositedTransformTarget(
        link: _launcherLink,
        child: _MoolHomeLauncher(
          compact: widget.compact,
          expanded: _isOpen,
          onPressed: _toggleConnectedNavigator,
        ),
      ),
    );
    final view = View.of(context);
    final standaloneExportedSemanticsClearance = widget.compact
        ? 0.0
        : moolAndroidExportedSemanticsClearance(
            viewPadding: EdgeInsets.fromViewPadding(
              view.viewPadding,
              view.devicePixelRatio,
            ),
            platform: defaultTargetPlatform,
          );
    final anchoredLauncher = widget.compact
        ? launcher
        : Padding(
            key: const Key(
              'moolsocial-global-android-exported-semantics-clearance',
            ),
            padding: EdgeInsets.only(
              bottom: standaloneExportedSemanticsClearance,
            ),
            child: Hero(
              tag: moolGlobalNavigationHeroTag,
              transitionOnUserGestures: true,
              child: Material(
                color: Colors.transparent,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: MoolSpacing.xs),
                  child: SizedBox(
                    key: const Key('moolsocial-single-home-launcher-area'),
                    height: 64,
                    child: Center(child: launcher),
                  ),
                ),
              ),
            ),
          );
    final portal = OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: _buildEmbeddedSwitcher,
      child: anchoredLauncher,
    );
    if (Router.maybeOf<Object?>(context)?.backButtonDispatcher == null) {
      return portal;
    }
    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: portal,
    );
  }
}

/// The globally stable right-edge companion to the left-edge Mool launcher.
/// Both edge controls use the same high-contrast white surface and fixed
/// geometry so destination content never changes their learned positions.
class MoolGlobalChatNavigationV2 extends StatefulWidget {
  const MoolGlobalChatNavigationV2({
    required this.onOpenChat,
    this.controlKey = const Key('mool-global-chat'),
    super.key,
  });

  final VoidCallback? onOpenChat;
  final Key controlKey;

  @override
  State<MoolGlobalChatNavigationV2> createState() =>
      _MoolGlobalChatNavigationV2State();
}

class _MoolGlobalChatNavigationV2State
    extends State<MoolGlobalChatNavigationV2> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fixedCellWidth =
        MoolLocalNavigationTokens.destinationFixedCellWidthFor(
          MediaQuery.sizeOf(context).width,
        );
    return Semantics(
      key: widget.controlKey,
      container: true,
      button: true,
      enabled: widget.onOpenChat != null,
      label: 'Open MoolSocial Chat',
      onTap: widget.onOpenChat,
      excludeSemantics: true,
      child: AnimatedScale(
        key: const Key('mool-global-chat-press-motion'),
        scale: _pressed ? .94 : 1,
        duration: MoolHomeHubTokens.accessibleDuration(
          context,
          MoolHomeHubTokens.pressDuration,
        ),
        curve: MoolMotion.change,
        child: SizedBox(
          width: fixedCellWidth,
          height: MoolLocalNavigationTokens.destinationRailHeight,
          child: Material(
            key: const Key('mool-global-chat-white-surface'),
            color: Colors.white,
            elevation: 1,
            shadowColor: const Color(0x26000050),
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('mool-global-chat-tap'),
              onHighlightChanged: widget.onOpenChat == null
                  ? null
                  : (pressed) {
                      if (_pressed != pressed) {
                        setState(() => _pressed = pressed);
                      }
                    },
              onTap: widget.onOpenChat == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      widget.onOpenChat!();
                    },
              splashColor: MoolColors.navy.withValues(alpha: .08),
              highlightColor: MoolColors.navy.withValues(alpha: .045),
              child: const MoolDestinationIconLabel(
                key: Key('mool-global-chat-icon-label'),
                label: 'Chat',
                icon: Icons.chat_bubble_outline_rounded,
                color: MoolColors.navy,
                emphasized: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoolHomeLauncher extends StatefulWidget {
  const _MoolHomeLauncher({
    required this.onPressed,
    required this.expanded,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final bool expanded;
  final bool compact;

  @override
  State<_MoolHomeLauncher> createState() => _MoolHomeLauncherState();
}

class _MoolHomeLauncherState extends State<_MoolHomeLauncher> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      final fixedCellWidth =
          MoolLocalNavigationTokens.destinationFixedCellWidthFor(
            MediaQuery.sizeOf(context).width,
          );
      return Semantics(
        key: const Key('mool-home-launcher'),
        container: true,
        button: true,
        expanded: widget.expanded,
        label: widget.expanded
            ? 'Close MoolSocial main menu'
            : 'Open MoolSocial main menu',
        onTap: widget.onPressed,
        excludeSemantics: true,
        child: AnimatedScale(
          key: const Key('mool-compact-launcher-press-motion'),
          scale: _pressed ? .94 : 1,
          duration: MoolHomeHubTokens.accessibleDuration(
            context,
            MoolHomeHubTokens.pressDuration,
          ),
          curve: MoolMotion.change,
          child: SizedBox(
            width: fixedCellWidth,
            height: MoolLocalNavigationTokens.destinationRailHeight,
            child: Material(
              key: const Key('mool-compact-launcher-white-surface'),
              color: Colors.white,
              elevation: 1,
              shadowColor: const Color(0x26000050),
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('mool-compact-launcher'),
                onHighlightChanged: (pressed) {
                  if (_pressed != pressed) setState(() => _pressed = pressed);
                },
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onPressed();
                },
                splashColor: MoolColors.navy.withValues(alpha: .08),
                highlightColor: MoolColors.navy.withValues(alpha: .045),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const MoolDestinationIconLabel(
                      key: Key('mool-compact-launcher-icon-label'),
                      label: 'Mool',
                      icon: Icons.grid_view_rounded,
                      color: MoolColors.navy,
                      emphasized: true,
                    ),
                    Positioned(
                      bottom: 0,
                      child: AnimatedOpacity(
                        key: const Key('mool-launcher-expanded-indicator'),
                        opacity: widget.expanded ? 1 : 0,
                        duration: MoolHomeHubTokens.accessibleDuration(
                          context,
                          MoolLocalNavigationTokens.selectionDuration,
                        ),
                        child: Container(
                          width: MoolLocalNavigationTokens
                              .destinationSelectedIndicatorWidth,
                          height: MoolLocalNavigationTokens
                              .destinationSelectedIndicatorHeight,
                          decoration: BoxDecoration(
                            color: MoolColors.navy,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
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
    return Semantics(
      button: true,
      expanded: widget.expanded,
      label: widget.expanded
          ? 'Close MoolSocial main menu'
          : 'Open MoolSocial main menu',
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: AnimatedScale(
        key: const Key('mool-home-launcher-press-motion'),
        scale: _pressed ? .975 : 1,
        duration: MoolHomeHubTokens.accessibleDuration(
          context,
          MoolHomeHubTokens.pressDuration,
        ),
        curve: MoolMotion.change,
        child: SizedBox(
          width: 64,
          height: 56,
          child: Material(
            key: const Key('mool-home-launcher'),
            color: Colors.transparent,
            child: InkWell(
              onHighlightChanged: (pressed) {
                if (_pressed != pressed) setState(() => _pressed = pressed);
              },
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onPressed();
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        color: MoolColors.navy,
                        size: MoolLocalNavigationTokens.destinationIconSize,
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Mool',
                        style: TextStyle(
                          color: MoolColors.navy,
                          fontSize:
                              MoolLocalNavigationTokens.destinationLabelSize,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    child: AnimatedOpacity(
                      opacity: widget.expanded ? 1 : 0,
                      duration: MoolHomeHubTokens.accessibleDuration(
                        context,
                        MoolLocalNavigationTokens.selectionDuration,
                      ),
                      child: Container(
                        width: 16,
                        height: 2,
                        decoration: BoxDecoration(
                          color: MoolColors.navy,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
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
