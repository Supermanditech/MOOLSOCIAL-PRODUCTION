import 'dart:async';

import 'package:flutter/widgets.dart';

/// Prevents launch handoff unless Screen 01 has remained continuously visible
/// in the foreground for the required presentation interval.
///
/// The accepted Screen 01 presentation stays immutable. This adjacent guard
/// owns only interruption behavior: calls, app switching, screen locking and
/// other non-resumed lifecycle states cancel the pending handoff. A full
/// foreground interval starts again when the app resumes.
class LaunchInterruptionGuard extends ChangeNotifier
    with WidgetsBindingObserver {
  LaunchInterruptionGuard({
    this.minimumForegroundDuration = const Duration(milliseconds: 3000),
  });

  final Duration minimumForegroundDuration;

  Timer? _timer;
  bool _started = false;
  bool _foreground = false;
  bool _minimumForegroundElapsed = false;

  bool get canHandoff => _started && _foreground && _minimumForegroundElapsed;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    final lifecycle =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _applyLifecycle(lifecycle);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _applyLifecycle(state);
  }

  void _applyLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _restartForegroundInterval();
      return;
    }

    final changed = _foreground || _minimumForegroundElapsed;
    _foreground = false;
    _minimumForegroundElapsed = false;
    _timer?.cancel();
    _timer = null;
    if (changed) notifyListeners();
  }

  void _restartForegroundInterval() {
    _timer?.cancel();
    _minimumForegroundElapsed = false;

    if (minimumForegroundDuration == Duration.zero) {
      _markForegroundElapsed();
      return;
    }

    notifyListeners();
    _timer = Timer(minimumForegroundDuration, _markForegroundElapsed);
  }

  void _markForegroundElapsed() {
    if (!_foreground || _minimumForegroundElapsed) return;
    _minimumForegroundElapsed = true;
    _timer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
