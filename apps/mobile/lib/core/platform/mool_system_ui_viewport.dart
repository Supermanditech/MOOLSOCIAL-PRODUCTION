import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps Android on its mandatory edge-to-edge window contract. Shared
/// navigation accounts for exported accessibility insets in Flutter instead
/// of requesting a non-edge mode that target SDK 36 cannot apply.
Future<void> configureMoolSystemUiViewport() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
