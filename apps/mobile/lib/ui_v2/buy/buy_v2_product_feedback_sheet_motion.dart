import 'package:flutter/material.dart';

import 'buy_v2_design.dart';

/// The R56.5 route, keyboard-inset and local-form-state motion contract for
/// the existing product review and issue-report sheets.
///
/// This policy deliberately does not migrate filters or any later modal
/// family. Form-state motion is eligible only when rating, comment or reason
/// state changes locally; submission truth remains owned by [BuyV2Session].
abstract final class BuyV2ProductFeedbackSheetMotion {
  static const forwardDuration = BuyV2Motion.routeChange;
  static const reverseDuration = BuyV2Motion.recovery;
  static const keyboardInsetDuration = BuyV2Motion.stateChange;
  static const formStateDuration = BuyV2Motion.stateChange;

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

  static Duration resolveFormStateDuration(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : formStateDuration;
  }
}
