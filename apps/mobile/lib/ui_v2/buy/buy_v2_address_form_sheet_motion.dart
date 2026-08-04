import 'package:flutter/material.dart';

import 'buy_v2_address_sheet_motion.dart';
import 'buy_v2_design.dart';

/// R56.10 route and geometry policy for request/add-address forms.
///
/// The forms may validate only their local text and the existing Buy session.
/// This policy never supplies geocoding, current-location, map-provider,
/// serviceability or remote-persistence truth.
abstract final class BuyV2AddressFormSheetMotion {
  static const forwardDuration = BuyV2Motion.routeChange;
  static const reverseDuration = BuyV2Motion.recovery;
  static const maxWidth = BuyV2AddressSheetMotion.maxWidth;
  static const requestMaxHeightFactor = .78;
  static const addMaxHeightFactor = .94;

  static double resolveBottomSafeInset(BuildContext context) {
    return BuyV2AddressSheetMotion.resolveBottomSafeInset(context);
  }

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
