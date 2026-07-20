import 'dart:async';

import 'package:flutter/foundation.dart';

/// Presentation-only timing for the approved Screen 01 launch moment.
///
/// The existing [JourneySession] remains the authority for boot work and route
/// selection. This gate only prevents the router from leaving `/boot` before
/// the approved motion has had time to complete.
class LaunchPresentationGate extends ChangeNotifier {
  LaunchPresentationGate({
    this.minimumDuration = const Duration(milliseconds: 3000),
  });

  final Duration minimumDuration;

  Timer? _timer;
  bool _started = false;
  bool _minimumElapsed = false;

  bool get minimumElapsed => _minimumElapsed;

  void start() {
    if (_started) return;
    _started = true;

    if (minimumDuration == Duration.zero) {
      _markElapsed();
      return;
    }

    _timer = Timer(minimumDuration, _markElapsed);
  }

  void _markElapsed() {
    if (_minimumElapsed) return;
    _minimumElapsed = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
