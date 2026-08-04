import 'package:flutter/material.dart';

import 'mool_design_system.dart';

/// Brand-safe gradients available to shared motion owners.
///
/// Every stop is one of the four identity colours. Vertical/business mapping
/// belongs to the integrating ticket rather than this primitive layer.
enum MoolBrandGradient {
  navy,
  saffron,
  green,
  tricolour;

  List<Color> get colors => switch (this) {
    MoolBrandGradient.navy => const <Color>[
      MoolBrand.identityNavy,
      MoolBrand.identityGreen,
      MoolBrand.identityNavy,
    ],
    MoolBrandGradient.saffron => const <Color>[
      MoolBrand.identityNavy,
      MoolBrand.identitySaffron,
      MoolBrand.identityWhite,
    ],
    MoolBrandGradient.green => const <Color>[
      MoolBrand.identityNavy,
      MoolBrand.identityGreen,
      MoolBrand.identityWhite,
    ],
    MoolBrandGradient.tricolour => const <Color>[
      MoolBrand.identitySaffron,
      MoolBrand.identityWhite,
      MoolBrand.identityGreen,
    ],
  };
}

/// A fixed-geometry, finite gradient transition.
class MoolFiniteGradientTransition extends StatelessWidget {
  const MoolFiniteGradientTransition({
    required this.gradient,
    required this.child,
    this.duration = MoolMotion.deliberate,
    this.curve = MoolMotion.change,
    this.padding = EdgeInsets.zero,
    this.borderRadius = BorderRadius.zero,
    this.alignment,
    super.key,
  });

  final MoolBrandGradient gradient;
  final Widget child;
  final Duration duration;
  final Curve curve;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MoolMotion.accessible(context, duration),
      curve: curve,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient.colors,
        ),
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

/// A finite text swap inside an explicit owner size.
///
/// The visual copies are excluded from semantics so an outgoing transition
/// can never announce alongside the final text.
class MoolFiniteTextTransition extends StatelessWidget {
  const MoolFiniteTextTransition({
    required this.stateKey,
    required this.text,
    required this.ownerSize,
    required this.style,
    this.textAlign = TextAlign.center,
    this.maxLines = 2,
    this.duration = MoolMotion.standard,
    super.key,
  });

  final Object stateKey;
  final String text;
  final Size ownerSize;
  final TextStyle style;
  final TextAlign textAlign;
  final int maxLines;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final resolvedDuration = MoolMotion.accessible(context, duration);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: SizedBox.fromSize(
        size: ownerSize,
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: resolvedDuration,
            reverseDuration: resolvedDuration,
            switchInCurve: MoolMotion.enter,
            switchOutCurve: MoolMotion.change,
            layoutBuilder: _fixedStackLayout,
            transitionBuilder: (child, animation) {
              final fade = CurvedAnimation(
                parent: animation,
                curve: const Interval(.5, 1, curve: MoolMotion.enter),
                reverseCurve: const Interval(.5, 1, curve: MoolMotion.change),
              );
              final offset =
                  Tween<Offset>(begin: const Offset(.08, 0), end: Offset.zero)
                      .chain(CurveTween(curve: const Interval(.5, 1)))
                      .animate(animation);
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: ExcludeSemantics(
              key: ValueKey<Object>(stateKey),
              child: Center(
                child: Text(
                  text,
                  textAlign: textAlign,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A finite icon swap inside one stable semantic and hit owner.
class MoolFiniteIconTransition extends StatelessWidget {
  const MoolFiniteIconTransition({
    required this.stateKey,
    required this.icon,
    required this.semanticLabel,
    this.ownerSize = const Size.square(MoolMetrics.minimumTapTarget),
    this.iconSize = 24,
    this.color = MoolBrand.identityNavy,
    this.duration = MoolMotion.standard,
    super.key,
  });

  final Object stateKey;
  final IconData icon;
  final String semanticLabel;
  final Size ownerSize;
  final double iconSize;
  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final resolvedDuration = MoolMotion.accessible(context, duration);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox.fromSize(
        size: ownerSize,
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: resolvedDuration,
            reverseDuration: resolvedDuration,
            switchInCurve: MoolMotion.enter,
            switchOutCurve: MoolMotion.change,
            layoutBuilder: _fixedStackLayout,
            transitionBuilder: (child, animation) {
              final fade = CurvedAnimation(
                parent: animation,
                curve: const Interval(.5, 1, curve: MoolMotion.enter),
                reverseCurve: const Interval(.5, 1, curve: MoolMotion.change),
              );
              final phased = CurvedAnimation(
                parent: animation,
                curve: const Interval(.5, 1),
                reverseCurve: const Interval(.5, 1),
              );
              final turn = Tween<double>(begin: -.08, end: 0).animate(phased);
              final scale = Tween<double>(begin: .86, end: 1).animate(phased);
              return FadeTransition(
                opacity: fade,
                child: RotationTransition(
                  turns: turn,
                  child: ScaleTransition(scale: scale, child: child),
                ),
              );
            },
            child: ExcludeSemantics(
              key: ValueKey<Object>(stateKey),
              child: Icon(icon, size: iconSize, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// A generic finite state swap for already-owned, fixed-size content.
class MoolFiniteStateTransition extends StatelessWidget {
  const MoolFiniteStateTransition({
    required this.stateKey,
    required this.ownerSize,
    required this.child,
    this.semanticLabel,
    this.duration = MoolMotion.standard,
    this.alignment = Alignment.center,
    super.key,
  });

  final Object stateKey;
  final Size ownerSize;
  final Widget child;
  final String? semanticLabel;
  final Duration duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final resolvedDuration = MoolMotion.accessible(context, duration);
    final visual = SizedBox.fromSize(
      size: ownerSize,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: resolvedDuration,
          reverseDuration: resolvedDuration,
          switchInCurve: MoolMotion.enter,
          switchOutCurve: MoolMotion.change,
          layoutBuilder: _fixedStackLayout,
          transitionBuilder: (child, animation) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: const Interval(.5, 1, curve: MoolMotion.enter),
              reverseCurve: const Interval(.5, 1, curve: MoolMotion.change),
            );
            final offset =
                Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
                    .chain(CurveTween(curve: const Interval(.5, 1)))
                    .animate(animation);
            final scale = Tween<double>(begin: .98, end: 1)
                .chain(CurveTween(curve: const Interval(.5, 1)))
                .animate(animation);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: offset,
                child: ScaleTransition(scale: scale, child: child),
              ),
            );
          },
          child: Align(
            key: ValueKey<Object>(stateKey),
            alignment: alignment,
            child: semanticLabel == null
                ? child
                : ExcludeSemantics(child: child),
          ),
        ),
      ),
    );

    if (semanticLabel == null) return visual;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: visual,
    );
  }
}

Widget _fixedStackLayout(Widget? currentChild, List<Widget> previousChildren) {
  return Stack(
    alignment: Alignment.center,
    fit: StackFit.expand,
    children: <Widget>[...previousChildren, ?currentChild],
  );
}
