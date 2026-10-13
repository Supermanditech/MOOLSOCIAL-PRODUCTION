import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Compatibility boundary retained for existing app composition.
///
/// Tap feedback belongs to each bounded native control. This wrapper must not
/// paint a pointer-level ring, delay dispatch, intercept semantics or add a
/// second animation over the control that actually owns the action.
class MoolBuyTapAcknowledgement extends StatelessWidget {
  const MoolBuyTapAcknowledgement({
    super.key,
    this.routeInformation,
    this.isBuyActive,
    this.routeChanges,
    required this.child,
  }) : assert(routeInformation != null || isBuyActive != null);

  final ValueListenable<RouteInformation>? routeInformation;
  final bool Function()? isBuyActive;
  final Listenable? routeChanges;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
