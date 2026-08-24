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
