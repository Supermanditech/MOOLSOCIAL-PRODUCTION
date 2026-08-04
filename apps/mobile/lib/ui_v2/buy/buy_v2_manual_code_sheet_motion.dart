import 'package:flutter/material.dart';

import 'buy_v2_design.dart';

/// The R56.2 route and inset-motion contract for manual scanner recovery.
///
/// This deliberately does not migrate any other Buy modal family. R56.1
/// Saved-clear keeps its separately qualified policy and the remaining eleven
/// modal families keep their existing transitions until separately registered.
abstract final class BuyV2ManualCodeSheetMotion {
  static const forwardDuration = BuyV2Motion.routeChange;
  static const reverseDuration = BuyV2Motion.recovery;
  static const keyboardInsetDuration = Duration(milliseconds: 180);

  static AnimationStyle resolve(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return AnimationStyle(
      duration: reducedMotion ? Duration.zero : forwardDuration,
      reverseDuration: reducedMotion ? Duration.zero : reverseDuration,
      curve: reducedMotion ? Curves.linear : Curves.easeOutBack,
      reverseCurve: reducedMotion ? Curves.linear : Curves.easeInCubic,
    );
  }

  static Duration resolveKeyboardInsetDuration(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : keyboardInsetDuration;
  }
}
