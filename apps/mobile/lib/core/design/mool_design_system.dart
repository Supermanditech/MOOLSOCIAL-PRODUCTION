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
    BoxShadow(color: Color(0x1F000036), blurRadius: 30, offset: Offset(0, 14)),
  ];

  static const card = [
    BoxShadow(color: Color(0x12000036), blurRadius: 20, offset: Offset(0, 8)),
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
