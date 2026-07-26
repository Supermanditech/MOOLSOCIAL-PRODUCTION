import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'youtube_embedded_player_bridge.dart';
import 'youtube_embedded_player_contract.dart';
import 'youtube_embedded_player_controller.dart';

const androidYouTubeEmbeddedPlayerViewType =
    'com.moolsocial.app/youtube_embedded_player';

typedef AndroidYouTubePlayerPortReady =
    void Function(AndroidYouTubeEmbeddedPlayerPort port);
typedef AndroidYouTubePlayerEventListener =
    FutureOr<void> Function(YouTubePlayerEvent event);
typedef AndroidYouTubePlatformFailureListener =
    FutureOr<void> Function(YouTubeEmbeddedPlayerPlatformFailure failure);
typedef AndroidYouTubePlatformFailure = YouTubeEmbeddedPlayerPlatformFailure;

/// Debug/private-Dev Android boundary for the provider-only WebView.
///
/// The matching native factory is not registered in release builds, while the
/// shared feature flag remains disabled unless a private-Dev build explicitly
/// enables it.
class AndroidYouTubeEmbeddedPlayerSurface extends StatefulWidget {
  const AndroidYouTubeEmbeddedPlayerSurface({
    required this.onPortReady,
    super.key,
  });

  final AndroidYouTubePlayerPortReady onPortReady;

  @override
  State<AndroidYouTubeEmbeddedPlayerSurface> createState() =>
      _AndroidYouTubeEmbeddedPlayerSurfaceState();
}

class _AndroidYouTubeEmbeddedPlayerSurfaceState
    extends State<AndroidYouTubeEmbeddedPlayerSurface> {
  AndroidYouTubeEmbeddedPlayerPort? _port;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'The private-Dev YouTube player probe is Android-only.',
      );
    }
    return AndroidView(
      viewType: androidYouTubeEmbeddedPlayerViewType,
      layoutDirection: TextDirection.ltr,
      onPlatformViewCreated: (viewId) {
        final port = AndroidYouTubeEmbeddedPlayerPort(viewId);
        _port = port;
        widget.onPortReady(port);
      },
    );
  }

  @override
  void dispose() {
    _port?.close();
    super.dispose();
  }
}

class AndroidYouTubeEmbeddedPlayerPort implements YouTubeEmbeddedPlayerPort {
  AndroidYouTubeEmbeddedPlayerPort(int viewId)
    : _channel = MethodChannel(
        '$androidYouTubeEmbeddedPlayerViewType/$viewId',
      ) {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static const _maximumBridgeMessageBytes = 8192;

  final MethodChannel _channel;
  AndroidYouTubePlayerEventListener? _onEvent;
  AndroidYouTubePlatformFailureListener? _onPlatformFailure;
  bool _closed = false;

  @override
  void bind({
    required Future<void> Function(YouTubePlayerEvent event) onEvent,
    required Future<void> Function(YouTubeEmbeddedPlayerPlatformFailure failure)
    onPlatformFailure,
  }) {
    _ensureOpen();
    _onEvent = onEvent;
    _onPlatformFailure = onPlatformFailure;
  }

  @override
  void unbind() {
    _onEvent = null;
    _onPlatformFailure = null;
  }

  @override
  Future<void> mount({
    required String bootstrapHtml,
    required Uri baseUrl,
    required YouTubePlayerGeometry geometry,
  }) async {
    _ensureOpen();
    if (bootstrapHtml != YouTubeEmbeddedPlayerBootstrap.html) {
      throw StateError('The Android player configuration is unavailable.');
    }
    if (baseUrl.toString() != youtubeEmbeddedPlayerBaseUrl) {
      throw StateError('The Android player base URL is not approved.');
    }
    await _channel.invokeMethod<void>('mount', <String, Object?>{
      'bootstrapHtml': bootstrapHtml,
      'baseUrl': baseUrl.toString(),
      'width': geometry.width,
      'height': geometry.height,
      'aspect': geometry.aspect.name,
    });
  }

  @override
  Future<void> send(YouTubePlayerCommand command) async {
    _ensureOpen();
    final encoded = command.encode();
    if (encoded.length > _maximumBridgeMessageBytes) {
      throw const FormatException('Player command exceeds the safe limit.');
    }
    await _channel.invokeMethod<void>('send', <String, Object?>{
      'message': encoded,
    });
  }

  @override
  Future<void> detach() async {
    _ensureOpen();
    await _channel.invokeMethod<void>('detach');
  }

  void close() {
    if (_closed) return;
    _closed = true;
    unbind();
    _channel.setMethodCallHandler(null);
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (_closed) return;
    switch (call.method) {
      case 'playerEvent':
        final raw = call.arguments;
        if (raw is! String || raw.length > _maximumBridgeMessageBytes) {
          throw const FormatException('Invalid Android player event.');
        }
        final event = YouTubePlayerEvent.decode(raw);
        await _onEvent?.call(event);
      case 'platformFailure':
        final raw = call.arguments;
        if (raw is! Map ||
            raw.length != 2 ||
            raw['code'] is! String ||
            raw['message'] is! String) {
          throw const FormatException('Invalid Android player failure.');
        }
        await _onPlatformFailure?.call(
          YouTubeEmbeddedPlayerPlatformFailure(
            code: raw['code'] as String,
            message: raw['message'] as String,
          ),
        );
      default:
        throw MissingPluginException(
          'Unsupported Android player callback: ${call.method}',
        );
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('The Android player port is closed.');
    }
  }
}
