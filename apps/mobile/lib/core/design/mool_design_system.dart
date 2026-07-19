import 'dart:ui';

import 'package:flutter/material.dart';

import 'mool_colors.dart';

/// Shared full-app design tokens.
///
/// Product screens must use these values instead of introducing local spacing,
/// radius, motion or tap-target constants. See
/// docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md.
abstract final class MoolSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class MoolRadii {
  static const double control = 12;
  static const double card = 18;
  static const double sheet = 28;
  static const double floating = 24;
  static const double capsule = 999;
}

abstract final class MoolMetrics {
  /// Apple Human Interface Guidance minimum interactive size.
  static const double minimumTapTarget = 44;
  static const double compactTapTarget = 48;
  static const double maximumContentWidth = 440;
  static const double bottomNavigationHeight = 64;
}

abstract final class MoolMotion {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration deliberate = Duration(milliseconds: 360);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve change = Curves.easeInOutCubic;

  static Duration accessible(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}

abstract final class MoolShadows {
  static const floating = [
    BoxShadow(color: Color(0x18000036), blurRadius: 32, offset: Offset(0, 16)),
    BoxShadow(color: Color(0x0A000036), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const card = [
    BoxShadow(color: Color(0x0F000036), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x08000036), blurRadius: 4, offset: Offset(0, 1)),
  ];
}

/// A restrained translucent surface for persistent navigation and temporary
/// command palettes. The content remains the visual focus.
class MoolGlassSurface extends StatelessWidget {
  const MoolGlassSurface({
    required this.child,
    this.dark = false,
    this.padding = const EdgeInsets.all(MoolSpacing.xs),
    this.borderRadius = MoolRadii.floating,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final bool dark;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final surface = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: AnimatedContainer(
          duration: MoolMotion.accessible(context, MoolMotion.standard),
          curve: MoolMotion.change,
          padding: padding,
          decoration: BoxDecoration(
            color: dark
                ? const Color(0xE812124F)
                : Colors.white.withValues(alpha: .88),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: .16)
                  : const Color(0x1F000080),
            ),
            borderRadius: radius,
            boxShadow: MoolShadows.floating,
          ),
          child: child,
        ),
      ),
    );

    if (semanticLabel == null) return surface;
    return Semantics(container: true, label: semanticLabel, child: surface);
  }
}

/// The standard content surface for every MoolSocial vertical.
///
/// It keeps hierarchy calm, provides a restrained pressed response and avoids
/// the heavy outlined-card treatment that made earlier prototype screens feel
/// like internal forms.
class MoolCardSurface extends StatefulWidget {
  const MoolCardSurface({
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(MoolSpacing.md),
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<MoolCardSurface> createState() => _MoolCardSurfaceState();
}

class _MoolCardSurfaceState extends State<MoolCardSurface> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(MoolRadii.card);
    return Semantics(
      label: widget.semanticLabel,
      button: widget.onTap != null,
      child: AnimatedScale(
        scale: pressed ? .985 : 1,
        duration: MoolMotion.accessible(context, MoolMotion.quick),
        curve: MoolMotion.change,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: radius,
            border: Border.all(color: const Color(0x14000080)),
            boxShadow: MoolShadows.card,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: widget.onTap == null
                    ? null
                    : (value) => setState(() => pressed = value),
                splashColor: MoolColors.royal.withValues(alpha: .08),
                highlightColor: MoolColors.royal.withValues(alpha: .04),
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A reusable selected/unselected capsule for focused sub-actions.
class MoolSegment extends StatelessWidget {
  const MoolSegment({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? MoolColors.navy : Colors.transparent,
        borderRadius: BorderRadius.circular(MoolRadii.capsule),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(MoolRadii.capsule),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: MoolMetrics.minimumTapTarget,
              minHeight: MoolMetrics.minimumTapTarget,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: icon == null ? MoolSpacing.sm : MoolSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 17,
                      color: selected ? Colors.white : MoolColors.navy,
                    ),
                    const SizedBox(width: MoolSpacing.xxs),
                  ],
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: selected ? Colors.white : MoolColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

class MoolDockAction {
  const MoolDockAction({
    required this.keyName,
    required this.id,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.badgeCount = 0,
  });

  final String keyName;
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final int badgeCount;
}

/// One persistent navigation language for every product vertical: Mool and
/// Chat remain stable while the current vertical owns a readable middle rail.
class MoolOutcomeDock extends StatelessWidget {
  const MoolOutcomeDock({
    required this.semanticLabel,
    required this.activeId,
    required this.mool,
    required this.actions,
    required this.chat,
    super.key,
  });

  final String semanticLabel;
  final String activeId;
  final MoolDockAction mool;
  final List<MoolDockAction> actions;
  final MoolDockAction chat;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.sm,
          MoolSpacing.xs,
          MoolSpacing.sm,
          MoolSpacing.sm,
        ),
        child: SizedBox(
          height: 68,
          child: MoolGlassSurface(
            semanticLabel: semanticLabel,
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                _MoolEdgeDockAction(
                  action: mool,
                  selected: activeId == mool.id,
                  isMool: true,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1F8).withValues(alpha: .86),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x10000080)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          for (final action in actions)
                            Expanded(
                              child: _MoolMiddleDockAction(
                                action: action,
                                selected: activeId == action.id,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _MoolEdgeDockAction(
                  action: chat,
                  selected: activeId == chat.id,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoolEdgeDockAction extends StatelessWidget {
  const _MoolEdgeDockAction({
    required this.action,
    required this.selected,
    this.isMool = false,
  });

  final MoolDockAction action;
  final bool selected;
  final bool isMool;

  @override
  Widget build(BuildContext context) {
    final foreground = selected || isMool ? Colors.white : MoolColors.navy;
    return Semantics(
      selected: selected,
      button: true,
      label: action.label,
      child: InkWell(
        key: Key(action.keyName),
        onTap: action.onPressed,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: MoolMotion.accessible(context, MoolMotion.quick),
          curve: MoolMotion.change,
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: isMool
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2929D4), Color(0xFF07076E)],
                  )
                : null,
            color: isMool
                ? null
                : selected
                ? MoolColors.navy
                : Colors.white.withValues(alpha: .74),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected || isMool
                  ? Colors.white.withValues(alpha: .22)
                  : const Color(0x16000080),
            ),
            boxShadow: isMool || selected
                ? const [
                    BoxShadow(
                      color: Color(0x33070768),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: isMool
                    ? const Text(
                        'Mool',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(action.icon, color: foreground, size: 19),
                          const SizedBox(height: 2),
                          Text(
                            action.label,
                            maxLines: 1,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ),
              if (action.badgeCount > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: MoolColors.orange,
                      borderRadius: BorderRadius.circular(MoolRadii.capsule),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '${action.badgeCount}',
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoolMiddleDockAction extends StatelessWidget {
  const _MoolMiddleDockAction({required this.action, required this.selected});

  final MoolDockAction action;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: action.label,
      child: InkWell(
        key: Key(action.keyName),
        onTap: action.onPressed,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: MoolMotion.accessible(context, MoolMotion.quick),
          curve: MoolMotion.change,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? MoolColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x28070768),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action.icon,
                size: 18,
                color: selected ? Colors.white : MoolColors.navy,
              ),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  action.label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected ? Colors.white : MoolColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
