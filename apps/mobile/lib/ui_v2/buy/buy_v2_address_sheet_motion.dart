import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'buy_v2_design.dart';

/// R56.9 route and geometry policy for the saved-address choice surface.
///
/// Address truth remains in `BuyV2Session`. This policy owns only a finite
/// native route and bounded geometry; it never validates, geocodes or confirms
/// serviceability for an address.
abstract final class BuyV2AddressSheetMotion {
  static const forwardDuration = BuyV2Motion.routeChange;
  static const reverseDuration = BuyV2Motion.recovery;
  static const maxWidth = BuyV2Metrics.maxWidth;
  static const maxHeightFactor = .86;
  static const fallbackBottomSafeInset = 24.0;

  static double resolveBottomSafeInset(BuildContext context) {
    final media = MediaQuery.of(context);
    final view = View.of(context);
    final devicePixelRatio = view.devicePixelRatio;
    final rawViewPadding = devicePixelRatio > 0
        ? view.viewPadding.bottom / devicePixelRatio
        : 0.0;
    final physicalLogicalHeight = devicePixelRatio > 0
        ? view.physicalSize.height / devicePixelRatio
        : media.size.height;
    final viewportExclusion = math.max(
      0.0,
      physicalLogicalHeight - media.size.height,
    );
    return math.max(
      fallbackBottomSafeInset,
      math.max(
        media.viewPadding.bottom,
        math.max(rawViewPadding, viewportExclusion),
      ),
    );
  }

  static double resolveModalActionBottomInset(BuildContext context) {
    final view = View.of(context);
    final devicePixelRatio = view.devicePixelRatio;
    final rawTopPadding = devicePixelRatio > 0
        ? view.viewPadding.top / devicePixelRatio
        : 0.0;
    final rawBottomPadding = devicePixelRatio > 0
        ? view.viewPadding.bottom / devicePixelRatio
        : 0.0;
    const exportedSemanticsOverflow = 58.0 - 44.0;
    final exportedSemanticsClearance = math.max(
      0.0,
      rawTopPadding - exportedSemanticsOverflow,
    );
    return math.max(fallbackBottomSafeInset, rawBottomPadding) +
        exportedSemanticsClearance;
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
