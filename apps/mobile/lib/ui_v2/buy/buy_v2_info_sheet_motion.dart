import 'package:flutter/material.dart';

import 'buy_v2_design.dart';

/// The R56.4 route/content-motion contract for the existing household-basket
/// and Saved-products informational sheets.
///
/// This deliberately does not migrate R56.1-R56.3 or any later form/action
/// family. Content motion is eligible only when the real Saved owner changes.
abstract final class BuyV2InfoSheetMotion {
  static const forwardDuration = BuyV2Motion.routeChange;
  static const reverseDuration = BuyV2Motion.recovery;
  static const contentDuration = BuyV2Motion.stateChange;

  static AnimationStyle resolve(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return AnimationStyle(
      duration: reducedMotion ? Duration.zero : forwardDuration,
      reverseDuration: reducedMotion ? Duration.zero : reverseDuration,
      curve: reducedMotion ? Curves.linear : Curves.easeOutBack,
      reverseCurve: reducedMotion ? Curves.linear : Curves.easeInCubic,
    );
  }

  static Duration resolveContentDuration(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : contentDuration;
  }
}
