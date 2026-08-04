import 'package:flutter/material.dart';

import 'buy_v2_design.dart';

/// The R56.1 route-motion contract for the existing Saved-clear decision.
///
/// This deliberately does not act as a general modal migration policy. The
/// other twelve native Buy V2 modal families keep their existing transitions
/// until separately registered and qualified.
abstract final class BuyV2SavedClearSheetMotion {
  static const forwardDuration = BuyV2Motion.routeChange;
  static const reverseDuration = BuyV2Motion.recovery;

  static AnimationStyle resolve(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return AnimationStyle(
      duration: reducedMotion ? Duration.zero : forwardDuration,
      reverseDuration: reducedMotion ? Duration.zero : reverseDuration,
      curve: reducedMotion ? Curves.linear : Curves.easeOutBack,
      reverseCurve: reducedMotion ? Curves.linear : Curves.easeInCubic,
    );
  }
}
