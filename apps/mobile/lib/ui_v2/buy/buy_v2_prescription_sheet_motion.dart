import 'package:flutter/material.dart';

import 'buy_v2_design.dart';

/// R56.8 route/geometry policy for the established prescription sheet.
///
/// Prescription matching and quantity truth remain in `BuyV2Session`; this
/// policy never represents upload, pharmacist or provider progress.
abstract final class BuyV2PrescriptionSheetMotion {
  static const forwardDuration = BuyV2Motion.routeChange;
  static const reverseDuration = BuyV2Motion.recovery;
  static const maxWidth = BuyV2Metrics.maxWidth;
  static const maxHeightFactor = .82;

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
