import 'package:flutter/material.dart';

import 'buy_v2_design.dart';

/// R58.6.1 route policy for exact current-catalogue supplier continuation.
///
/// This policy owns only a finite native sheet transition and stable geometry.
/// Seller/product truth remains in `BuyV2Session` and no provider state is
/// inferred by motion.
abstract final class BuyV2SupplierSheetMotion {
  static const forwardDuration = BuyV2Motion.routeChange;
  static const reverseDuration = BuyV2Motion.recovery;
  static const maxWidth = BuyV2Metrics.maxWidth;
  static const heightFactor = .72;

  static AnimationStyle resolve(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return AnimationStyle(
      duration: reducedMotion ? Duration.zero : forwardDuration,
      reverseDuration: reducedMotion ? Duration.zero : reverseDuration,
      curve: reducedMotion ? Curves.linear : Curves.easeOutCubic,
      reverseCurve: reducedMotion ? Curves.linear : Curves.easeInCubic,
    );
  }
}
