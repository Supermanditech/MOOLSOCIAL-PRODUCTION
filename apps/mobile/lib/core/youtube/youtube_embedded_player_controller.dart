import 'youtube_embedded_player_bridge.dart';
import 'youtube_embedded_player_contract.dart';

abstract interface class YouTubeEmbeddedPlayerPort {
  void bind({
    required Future<void> Function(YouTubePlayerEvent event) onEvent,
    required Future<void> Function(YouTubeEmbeddedPlayerPlatformFailure failure)
    onPlatformFailure,
  });

  void unbind();

  /// Mounts the provider-only bootstrap using an origin-preserving base URL.
  ///
  /// A platform adapter must use Android `loadDataWithBaseURL` or iOS
  /// `loadHTMLString(..., baseURL:)`, transfer one origin-allowlisted
  /// WebMessagePort-style channel, and expose no object-injection or arbitrary
  /// JavaScript execution path through this port.
  Future<void> mount({
    required String bootstrapHtml,
    required Uri baseUrl,
    required YouTubePlayerGeometry geometry,
  });

  Future<void> send(YouTubePlayerCommand command);

  /// Removes the provider WebView before native recovery UI is rendered.
  Future<void> detach();
}

class YouTubePlayerLease {
  YouTubePlayerLease._();

  static final YouTubePlayerLease _global = YouTubePlayerLease._();

  /// One process-wide lease. Constructing a lease never creates an isolated
  /// player pool, so independent callers cannot mount simultaneous players.
  factory YouTubePlayerLease() => _global;

  Object? _owner;

  bool acquire(Object owner) {
    if (_owner == null || identical(_owner, owner)) {
      _owner = owner;
      return true;
    }
    return false;
  }

  bool isOwner(Object owner) => identical(_owner, owner);

  void release(Object owner) {
    if (identical(_owner, owner)) _owner = null;
  }

  bool get hasOwner => _owner != null;
}

enum YouTubeEmbeddedPlayerStatus {
  disabled,
  idle,
  mounting,
  waitingForProvider,
  ready,
  cued,
  buffering,
  playing,
  paused,
  ended,
  autoplayBlocked,
  failed,
  disposed,
}

class YouTubeEmbeddedPlayerFailure {
  const YouTubeEmbeddedPlayerFailure({
    required this.code,
    required this.retryable,
    required this.action,
  });

  final int code;
  final bool retryable;
  final YouTubePlayerRecoveryAction action;
}

class YouTubeEmbeddedPlayerPlatformFailure {
  const YouTubeEmbeddedPlayerPlatformFailure({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

class YouTubeEmbeddedPlayerSnapshot {
  const YouTubeEmbeddedPlayerSnapshot({
    required this.status,
    required this.selectedVideoId,
    required this.mounted,
    required this.visibleFraction,
    required this.failure,
    required this.platformFailure,
    required this.playerState,
    required this.playbackQuality,
    required this.playbackRate,
    required this.captionOptions,
    required this.sphericalProperties,
    required this.apiRevision,
  });

  final YouTubeEmbeddedPlayerStatus status;
  final String? selectedVideoId;
  final bool mounted;
  final double visibleFraction;
  final YouTubeEmbeddedPlayerFailure? failure;
  final YouTubeEmbeddedPlayerPlatformFailure? platformFailure;
  final YouTubePlayerStateSnapshot? playerState;
  final String? playbackQuality;
  final double? playbackRate;
  final YouTubeCaptionOptionsSnapshot? captionOptions;
  final YouTubeSphericalProperties? sphericalProperties;
  final int apiRevision;
}

typedef YouTubePlayerSnapshotListener =
    void Function(YouTubeEmbeddedPlayerSnapshot snapshot);

/// Coordinates one official player without importing or mounting any Flutter
/// presentation. The caller owns native layout and user-facing recovery.
class YouTubeEmbeddedPlayerController {
  YouTubeEmbeddedPlayerController(
    this._port,
    this._lease, {
    this.config = const YouTubeEmbeddedPlayerFeatureConfig.disabled(),
    this.onSnapshot,
  }) {
    _status = config.enabled
        ? YouTubeEmbeddedPlayerStatus.idle
        : YouTubeEmbeddedPlayerStatus.disabled;
    _port.bind(onEvent: onBridgeEvent, onPlatformFailure: onPlatformFailure);
  }

  final YouTubeEmbeddedPlayerPort _port;
  final YouTubePlayerLease _lease;
  final Object _leaseOwner = Object();
  final YouTubeEmbeddedPlayerFeatureConfig config;
  final YouTubePlayerSnapshotListener? onSnapshot;

  late YouTubeEmbeddedPlayerStatus _status;
  YouTubeEmbeddedVideoRecord? _selection;
  YouTubePlayerGeometry? _geometry;
  YouTubeEmbeddedPlayerFailure? _failure;
  YouTubeEmbeddedPlayerPlatformFailure? _platformFailure;
  String? _failureVideoId;
  bool _mounted = false;
  bool _ready = false;
  bool _disposed = false;
  bool _recreationUsed = false;
  bool _appActive = true;
  bool _routeVisible = true;
  bool _screenUnlocked = true;
  bool _hasAudioFocus = true;
  bool _callInterrupted = false;
  bool _reducedMotion = false;
  double _visibleFraction = 1;
  int _selectionGeneration = 0;
  int _nativeSessionGeneration = 0;
  int _apiRevision = 0;
  YouTubePlayerStateSnapshot? _playerState;
  String? _playbackQuality;
  double? _playbackRate;
  YouTubeCaptionOptionsSnapshot? _captionOptions;
  YouTubeSphericalProperties? _sphericalProperties;
  Future<void>? _detachInFlight;

  YouTubeEmbeddedPlayerSnapshot get snapshot => YouTubeEmbeddedPlayerSnapshot(
    status: _status,
    selectedVideoId: _selection?.videoId,
    mounted: _mounted,
    visibleFraction: _visibleFraction,
    failure: _failure,
    platformFailure: _platformFailure,
    playerState: _playerState,
    playbackQuality: _playbackQuality,
    playbackRate: _playbackRate,
    captionOptions: _captionOptions,
    sphericalProperties: _sphericalProperties,
    apiRevision: _apiRevision,
  );

  Future<YouTubePlayerEligibility> select({
    required YouTubeEmbeddedVideoRecord record,
    required double availableWidth,
  }) async {
    _ensureUsable();
    if (!config.enabled) {
      throw StateError('The embedded player feature is disabled.');
    }
    final selectionGeneration = ++_selectionGeneration;
    final previousVideoId = _selection?.videoId;
    final sameVideo = previousVideoId == record.videoId;
    final eligibility = YouTubePlayerEligibilityPolicy.evaluate(record);
    if (!eligibility.eligible) {
      _selection = record;
      _failure = null;
      _platformFailure = null;
      _failureVideoId = null;
      _geometry = null;
      _recreationUsed = false;
      await _detachForNativeState();
      if (!_isCurrentSelection(selectionGeneration, record.videoId)) {
        return eligibility;
      }
      _status = YouTubeEmbeddedPlayerStatus.failed;
      _emit();
      return eligibility;
    }

    final aspect = record.isVerifiedVerticalShort
        ? YouTubePlayerAspect.verifiedVerticalShort
        : YouTubePlayerAspect.standardVideo;
    final geometry = YouTubePlayerGeometry.forAvailableWidth(
      availableWidth: availableWidth,
      aspect: aspect,
    );
    final geometryChanged = _mounted && !_hasSameGeometry(_geometry, geometry);
    _selection = record;
    if (!sameVideo) {
      _failure = null;
      _platformFailure = null;
      _failureVideoId = null;
      _recreationUsed = false;
      _playerState = null;
      _playbackQuality = null;
      _playbackRate = null;
      _captionOptions = null;
      _sphericalProperties = null;
      _apiRevision = 0;
    } else if (!_mounted && (_failure != null || _platformFailure != null)) {
      // A repeated selection is not a recovery gesture. Provider code 5 may
      // recreate this exact item only through retryPlayerFailureFromUser,
      // while native terminal failures remain terminal for this selection.
      return eligibility;
    }

    if (!_mounted) {
      await _mount(
        geometry,
        selectionGeneration: selectionGeneration,
        expectedVideoId: record.videoId,
      );
    } else if (geometryChanged) {
      await _detachForNativeState();
      if (!_isCurrentSelection(selectionGeneration, record.videoId)) {
        return eligibility;
      }
      await _mount(
        geometry,
        selectionGeneration: selectionGeneration,
        expectedVideoId: record.videoId,
      );
    } else if (_ready) {
      final nativeSessionGeneration = _nativeSessionGeneration;
      await _port.send(YouTubePlayerCommand.cue(record.videoId));
      if (!_isCurrentNativeSession(nativeSessionGeneration) ||
          !_isCurrentSelection(selectionGeneration, record.videoId)) {
        return eligibility;
      }
      _status = YouTubeEmbeddedPlayerStatus.cued;
      _emit();
    }
    return eligibility;
  }

  Future<void> onBridgeEvent(YouTubePlayerEvent event) async {
    if (_disposed || !_mounted) return;
    final nativeSessionGeneration = _nativeSessionGeneration;
    switch (event.type) {
      case YouTubePlayerEventType.ready:
        _ready = true;
        _status = YouTubeEmbeddedPlayerStatus.ready;
        final selection = _selection;
        if (selection != null) {
          await _port.send(YouTubePlayerCommand.cue(selection.videoId));
          if (!_isCurrentNativeSession(nativeSessionGeneration) ||
              _selection?.videoId != selection.videoId) {
            return;
          }
          _status = YouTubeEmbeddedPlayerStatus.cued;
        }
      case YouTubePlayerEventType.state:
        _status = switch (event.state!) {
          YouTubeProviderPlayerState.initializing =>
            YouTubeEmbeddedPlayerStatus.waitingForProvider,
          YouTubeProviderPlayerState.cued => YouTubeEmbeddedPlayerStatus.cued,
          YouTubeProviderPlayerState.buffering =>
            YouTubeEmbeddedPlayerStatus.buffering,
          YouTubeProviderPlayerState.playing =>
            YouTubeEmbeddedPlayerStatus.playing,
          YouTubeProviderPlayerState.paused =>
            YouTubeEmbeddedPlayerStatus.paused,
          YouTubeProviderPlayerState.ended => YouTubeEmbeddedPlayerStatus.ended,
        };
      case YouTubePlayerEventType.error:
        final failedVideoId = _selection?.videoId;
        final disposition = YouTubePlayerErrorPolicy.evaluate(
          event.errorCode!,
          recreationAlreadyUsed: _recreationUsed,
        );
        _failure = YouTubeEmbeddedPlayerFailure(
          code: disposition.providerCode,
          retryable: disposition.retryableInPlayer,
          action: disposition.action,
        );
        _platformFailure = null;
        _failureVideoId = failedVideoId;
        await _detachForNativeState();
        if (_disposed ||
            failedVideoId == null ||
            _selection?.videoId != failedVideoId ||
            _failureVideoId != failedVideoId) {
          return;
        }
        _status = YouTubeEmbeddedPlayerStatus.failed;
      case YouTubePlayerEventType.autoplayBlocked:
        _status = YouTubeEmbeddedPlayerStatus.autoplayBlocked;
      case YouTubePlayerEventType.playbackQualityChanged:
        _playbackQuality = event.playbackQuality;
      case YouTubePlayerEventType.playbackRateChanged:
        _playbackRate = event.playbackRate;
      case YouTubePlayerEventType.apiChanged:
        _apiRevision += 1;
      case YouTubePlayerEventType.stateSnapshot:
        _playerState = event.stateSnapshot;
        _playbackRate = event.stateSnapshot?.playbackRate;
      case YouTubePlayerEventType.captionOptionsSnapshot:
        _captionOptions = event.captionOptionsSnapshot;
      case YouTubePlayerEventType.sphericalSnapshot:
        _sphericalProperties = event.sphericalProperties;
    }
    _emit();
  }

  Future<void> onPlatformFailure(
    YouTubeEmbeddedPlayerPlatformFailure failure,
  ) async {
    if (_disposed || !_mounted) return;
    ++_selectionGeneration;
    _failure = null;
    _failureVideoId = null;
    _platformFailure = failure;
    _geometry = null;
    await _detachForNativeState(nativeAlreadyDetached: true);
    if (_disposed || _platformFailure != failure) return;
    _status = YouTubeEmbeddedPlayerStatus.failed;
    _emit();
  }

  Future<void> playFromUserGesture() async {
    _ensureReady();
    if (!_safeToPlay) {
      throw StateError('Playback is unavailable while the player is inactive.');
    }
    await _port.send(const YouTubePlayerCommand.play());
  }

  Future<bool> attemptVerifiedShortAutoplay() async {
    _ensureMounted();
    final selection = _selection;
    if (!_ready ||
        !config.shortsAutoplayEnabled ||
        selection == null ||
        !selection.isVerifiedVerticalShort ||
        _reducedMotion ||
        !_safeToPlay) {
      return false;
    }
    await _port.send(YouTubePlayerCommand.load(selection.videoId));
    return true;
  }

  Future<void> pauseFromUserGesture() async {
    _ensureReady();
    await _port.send(const YouTubePlayerCommand.pause());
  }

  Future<void> stopFromUserGesture() async {
    _ensureReady();
    await _port.send(const YouTubePlayerCommand.stop());
  }

  Future<void> seekFromUserGesture(double seconds) async {
    _ensureReady();
    final command = YouTubePlayerCommand.seek(seconds);
    command.toJson();
    await _port.send(command);
  }

  Future<void> playNextFromUserGesture() async {
    _ensureReady();
    await _port.send(const YouTubePlayerCommand.next());
  }

  Future<void> playPreviousFromUserGesture() async {
    _ensureReady();
    await _port.send(const YouTubePlayerCommand.previous());
  }

  Future<void> playPlaylistIndexFromUserGesture(int index) async {
    _ensureReady();
    final command = YouTubePlayerCommand.playAt(index);
    command.toJson();
    await _port.send(command);
  }

  Future<void> setMuted(bool muted) async {
    _ensureReady();
    await _port.send(
      muted
          ? const YouTubePlayerCommand.mute()
          : const YouTubePlayerCommand.unmute(),
    );
  }

  Future<void> setVolumeFromUserGesture(int volume) async {
    _ensureReady();
    final command = YouTubePlayerCommand.setVolume(volume);
    command.toJson();
    await _port.send(command);
  }

  Future<void> setPlaybackRateFromUserGesture(double playbackRate) async {
    _ensureReady();
    final command = YouTubePlayerCommand.setPlaybackRate(playbackRate);
    command.toJson();
    await _port.send(command);
  }

  Future<void> setPlaylistLoop(bool enabled) async {
    _ensureReady();
    await _port.send(YouTubePlayerCommand.setLoop(enabled));
  }

  Future<void> setPlaylistShuffle(bool enabled) async {
    _ensureReady();
    await _port.send(YouTubePlayerCommand.setShuffle(enabled));
  }

  Future<void> setCaptionFontSize(int fontSize) async {
    _ensureReady();
    final command = YouTubePlayerCommand.setCaptionFontSize(fontSize);
    command.toJson();
    await _port.send(command);
  }

  Future<void> reloadCaptions() async {
    _ensureReady();
    await _port.send(const YouTubePlayerCommand.reloadCaptions());
  }

  Future<void> requestCaptionOptions() async {
    _ensureReady();
    await _port.send(const YouTubePlayerCommand.requestCaptionOptions());
  }

  Future<void> requestPlayerState() async {
    _ensureReady();
    await _port.send(const YouTubePlayerCommand.requestState());
  }

  Future<void> requestSphericalProperties() async {
    _ensureReady();
    await _port.send(const YouTubePlayerCommand.requestSpherical());
  }

  Future<void> setSphericalProperties(
    YouTubeSphericalProperties properties,
  ) async {
    _ensureReady();
    final command = YouTubePlayerCommand.setSpherical(properties);
    command.toJson();
    await _port.send(command);
  }

  Future<bool> retryPlayerFailureFromUser() async {
    _ensureUsable();
    final failure = _failure;
    final geometry = _geometry;
    final selection = _selection;
    if (failure == null ||
        failure.code != 5 ||
        !failure.retryable ||
        _recreationUsed ||
        geometry == null ||
        selection == null ||
        _failureVideoId != selection.videoId ||
        !YouTubePlayerEligibilityPolicy.evaluate(selection).eligible) {
      return false;
    }
    final selectionGeneration = ++_selectionGeneration;
    _recreationUsed = true;
    _failure = null;
    _failureVideoId = null;
    await _mount(
      geometry,
      selectionGeneration: selectionGeneration,
      expectedVideoId: selection.videoId,
    );
    return true;
  }

  Future<void> onVisibleFractionChanged(double fraction) async {
    if (!fraction.isFinite || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(
        fraction,
        'fraction',
        'Visibility must be between 0 and 1.',
      );
    }
    _visibleFraction = fraction;
    await _pauseIfLifecycleRequires();
    _emit();
  }

  Future<void> onAppActiveChanged(bool active) async {
    _appActive = active;
    await _pauseIfLifecycleRequires();
  }

  Future<void> onRouteVisibleChanged(bool visible) async {
    _routeVisible = visible;
    await _pauseIfLifecycleRequires();
  }

  Future<void> onScreenUnlockedChanged(bool unlocked) async {
    _screenUnlocked = unlocked;
    await _pauseIfLifecycleRequires();
  }

  Future<void> onAudioFocusChanged(bool hasFocus) async {
    _hasAudioFocus = hasFocus;
    await _pauseIfLifecycleRequires();
  }

  Future<void> onCallInterruptedChanged(bool interrupted) async {
    _callInterrupted = interrupted;
    await _pauseIfLifecycleRequires();
  }

  void onReducedMotionChanged(bool reducedMotion) {
    _reducedMotion = reducedMotion;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    ++_selectionGeneration;
    _port.unbind();
    try {
      try {
        if (_mounted && _ready) {
          await _port.send(const YouTubePlayerCommand.dispose());
        }
      } finally {
        await _detachForNativeState();
      }
    } finally {
      _mounted = false;
      _ready = false;
      ++_nativeSessionGeneration;
      _lease.release(_leaseOwner);
      _status = YouTubeEmbeddedPlayerStatus.disposed;
      _emit();
    }
  }

  bool get _safeToPlay =>
      _appActive &&
      _routeVisible &&
      _screenUnlocked &&
      _hasAudioFocus &&
      !_callInterrupted &&
      _visibleFraction > 0.5;

  Future<void> _mount(
    YouTubePlayerGeometry geometry, {
    required int selectionGeneration,
    required String expectedVideoId,
  }) async {
    final detachInFlight = _detachInFlight;
    if (detachInFlight != null) await detachInFlight;
    if (!_isCurrentSelection(selectionGeneration, expectedVideoId)) return;
    if (!_lease.acquire(_leaseOwner)) {
      throw StateError('Another official YouTube player is already active.');
    }
    final nativeSessionGeneration = ++_nativeSessionGeneration;
    _geometry = geometry;
    _mounted = true;
    _ready = false;
    _status = YouTubeEmbeddedPlayerStatus.mounting;
    _emit();
    try {
      _status = YouTubeEmbeddedPlayerStatus.waitingForProvider;
      _emit();
      await _port.mount(
        bootstrapHtml: YouTubeEmbeddedPlayerBootstrap.html,
        baseUrl: Uri.parse(youtubeEmbeddedPlayerBaseUrl),
        geometry: geometry,
      );
    } catch (_) {
      if (_isCurrentNativeSession(nativeSessionGeneration)) {
        _lease.release(_leaseOwner);
        _mounted = false;
        _ready = false;
        _status = YouTubeEmbeddedPlayerStatus.failed;
        _emit();
      }
      rethrow;
    }
  }

  Future<void> _pauseIfLifecycleRequires() async {
    if (!_mounted || !_ready || _safeToPlay) return;
    final nativeSessionGeneration = _nativeSessionGeneration;
    try {
      await _port.send(const YouTubePlayerCommand.pause());
    } on Object {
      if (!_isCurrentNativeSession(nativeSessionGeneration)) return;
      final failedVideoId = _selection?.videoId;
      final failure = const YouTubeEmbeddedPlayerPlatformFailure(
        code: 'lifecycle_pause_failed',
        message: 'The player could not pause safely.',
      );
      ++_selectionGeneration;
      _failure = null;
      _failureVideoId = null;
      _platformFailure = failure;
      try {
        await _detachForNativeState();
      } on Object {
        // Detach still releases the shared lease in its own finally block.
      }
      if (_disposed ||
          _selection?.videoId != failedVideoId ||
          !identical(_platformFailure, failure)) {
        return;
      }
      _status = YouTubeEmbeddedPlayerStatus.failed;
      _emit();
      return;
    }
    if (!_isCurrentNativeSession(nativeSessionGeneration)) return;
    if (_status == YouTubeEmbeddedPlayerStatus.playing ||
        _status == YouTubeEmbeddedPlayerStatus.buffering) {
      _status = YouTubeEmbeddedPlayerStatus.paused;
    }
    _emit();
  }

  Future<void> _detachForNativeState({
    bool nativeAlreadyDetached = false,
  }) async {
    final wasMounted = _mounted;
    _mounted = false;
    _ready = false;
    ++_nativeSessionGeneration;

    final existingDetach = _detachInFlight;
    if (existingDetach != null) {
      await existingDetach;
      return;
    }
    if (!wasMounted || nativeAlreadyDetached) {
      _lease.release(_leaseOwner);
      return;
    }

    final detach = () async {
      try {
        await _port.detach();
      } finally {
        _lease.release(_leaseOwner);
      }
    }();
    _detachInFlight = detach;
    try {
      await detach;
    } finally {
      if (identical(_detachInFlight, detach)) {
        _detachInFlight = null;
      }
    }
  }

  bool _isCurrentSelection(int generation, String videoId) {
    return !_disposed &&
        generation == _selectionGeneration &&
        _selection?.videoId == videoId;
  }

  bool _isCurrentNativeSession(int generation) {
    return !_disposed &&
        _mounted &&
        _lease.isOwner(_leaseOwner) &&
        generation == _nativeSessionGeneration;
  }

  void _ensureMounted() {
    _ensureUsable();
    if (!_mounted || !_lease.isOwner(_leaseOwner)) {
      throw StateError('The official YouTube player is not mounted.');
    }
  }

  void _ensureReady() {
    _ensureMounted();
    if (!_ready) {
      throw StateError('The official YouTube player is not ready.');
    }
  }

  void _ensureUsable() {
    if (_disposed) {
      throw StateError('The official YouTube player has been disposed.');
    }
  }

  void _emit() => onSnapshot?.call(snapshot);

  static bool _hasSameGeometry(
    YouTubePlayerGeometry? current,
    YouTubePlayerGeometry next,
  ) {
    return current != null &&
        current.width == next.width &&
        current.height == next.height &&
        current.aspect == next.aspect;
  }
}
