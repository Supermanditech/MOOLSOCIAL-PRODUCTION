import 'package:flutter/material.dart';

import 'buy_v2_design.dart';

/// R56.7 route and geometry policy for the existing payment-method choice.
///
/// Payment truth remains in `BuyV2Session`. This policy owns only a finite
/// native route and stable compact geometry; it never starts or verifies a
/// payment.
abstract final class BuyV2PaymentSheetMotion {
  static const forwardDuration = BuyV2Motion.routeChange;
  static const reverseDuration = BuyV2Motion.recovery;
  static const maxWidth = BuyV2Metrics.maxWidth;
  static const maxHeightFactor = .78;

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
