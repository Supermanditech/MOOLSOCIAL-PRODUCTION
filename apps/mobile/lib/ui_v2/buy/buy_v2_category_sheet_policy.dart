import 'package:flutter/material.dart';

import 'buy_v2_design.dart';

/// The R56.3 route-shell contract for the existing category picker.
///
/// R40.3 already owns category route timing and the catalogue transition that
/// follows a real selection. R56.3 deliberately reuses that owner and adds no
/// nested fade, scale or slide inside the sheet.
abstract final class BuyV2CategorySheetPolicy {
  static const forwardDuration = BuyV2Motion.expandCollapse;
  static const reverseDuration = BuyV2Motion.expandCollapse;
  static const heightFactor = .64;
  static const maxWidth = BuyV2Metrics.maxWidth;

  static double heightFactorFor(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom > 0 ? 1 : heightFactor;
  }

  static AnimationStyle resolve(BuildContext context) {
    final forward = BuyV2Motion.resolved(context, forwardDuration);
    final reverse = BuyV2Motion.resolved(context, reverseDuration);
    final reducedMotion = forward == Duration.zero;
    return AnimationStyle(
      duration: forward,
      reverseDuration: reverse,
      curve: reducedMotion ? Curves.linear : Curves.easeOutCubic,
      reverseCurve: reducedMotion ? Curves.linear : Curves.easeInCubic,
    );
  }
}
