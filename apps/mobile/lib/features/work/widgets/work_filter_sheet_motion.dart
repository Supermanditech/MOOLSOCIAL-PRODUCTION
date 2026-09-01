import 'package:flutter/material.dart';

/// Matches the accepted Buy filter-sheet route geometry while keeping Work
/// filter state and presentation independently owned.
abstract final class WorkFilterSheetMotion {
  static const forwardDuration = Duration(milliseconds: 280);
  static const reverseDuration = Duration(milliseconds: 220);
  static const initialChildSize = .78;
  static const minChildSize = .45;
  static const maxChildSize = .92;
  static const maxWidth = 520.0;

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
