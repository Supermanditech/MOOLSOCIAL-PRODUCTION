import 'package:flutter/material.dart';

import 'buy_v2_design.dart';

/// The R56.6 route and geometry policy for the existing catalogue filters.
///
/// Filter truth remains in `BuyV2Session`. This policy owns only finite route
/// presentation and stable sheet geometry; it never derives a result count or
/// changes catalogue state.
abstract final class BuyV2FilterSheetMotion {
  static const forwardDuration = BuyV2Motion.routeChange;
  static const reverseDuration = BuyV2Motion.recovery;
  static const initialChildSize = .78;
  static const minChildSize = .45;
  static const maxChildSize = .92;
  static const maxWidth = BuyV2Metrics.maxWidth;

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
