import 'package:flutter/material.dart';

import 'buy_v2_design.dart';

/// A small, finite entrance used by Shop Chat rows.
///
/// The child remains the sole semantic and hit-test owner throughout motion.
class BuyV2ShopChatEntryMotion extends StatelessWidget {
  const BuyV2ShopChatEntryMotion({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = Duration(milliseconds: 190 + index.clamp(0, 5) * 24);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduced ? 1 : .74, end: 1),
      duration: BuyV2Motion.resolved(context, duration),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          transformHitTests: false,
          child: child,
        ),
      ),
    );
  }
}

/// Replaces one filtered Shop Chat result set without retaining duplicate
/// outgoing semantics.
class BuyV2ShopChatFilterMotion extends StatelessWidget {
  const BuyV2ShopChatFilterMotion({
    super.key,
    required this.stateKey,
    required this.child,
  });

  final Object stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BuyV2FiniteIncomingTransition(
      stateKey: stateKey,
      duration: BuyV2Motion.stateChange,
      child: child,
    );
  }
}

/// Finite directional motion for inbox, conversation and business-info
/// surfaces. Only the incoming surface owns semantics and hit testing.
class BuyV2ShopChatSurfaceMotion extends StatelessWidget {
  const BuyV2ShopChatSurfaceMotion({
    super.key,
    required this.stateKey,
    required this.forward,
    required this.child,
  });

  final Object stateKey;
  final bool forward;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey<Object>(stateKey),
      tween: Tween<double>(begin: reduced ? 1 : .68, end: 1),
      duration: BuyV2Motion.resolved(context, BuyV2Motion.routeChange),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          key: const ValueKey('buy-shop-chat-surface-translation'),
          offset: Offset((1 - value) * (forward ? 26 : -18), 0),
          transformHitTests: false,
          child: child,
        ),
      ),
    );
  }
}
