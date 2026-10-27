import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../core/design/mool_design_system.dart';

/// Shared existing Android exported-viewport allowance, extracted unchanged
/// from global navigation so bottom composers can use it without a UI cycle.
double moolAndroidExportedSemanticsClearance({
  required EdgeInsets viewPadding,
  required TargetPlatform platform,
}) {
  if (platform != TargetPlatform.android) return 0;
  const minimumExportedTarget = MoolMetrics.minimumTapTarget;
  final availableOverflow =
      MoolLocalNavigationTokens.destinationRailHeight - minimumExportedTarget;
  return (viewPadding.top - availableOverflow)
      .clamp(0, double.infinity)
      .toDouble();
}
