import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'youtube_embedded_player_bridge.dart';
import 'youtube_embedded_player_contract.dart';
import 'youtube_embedded_player_controller.dart';

const iosYouTubeEmbeddedPlayerViewType =
    'com.moolsocial.app/youtube_embedded_player';

typedef IosYouTubePlayerPortReady =
    void Function(IosYouTubeEmbeddedPlayerPort port);
typedef IosYouTubePlayerEventListener =
    FutureOr<void> Function(YouTubePlayerEvent event);
typedef IosYouTubePlatformFailureListener =
    FutureOr<void> Function(YouTubeEmbeddedPlayerPlatformFailure failure);
typedef IosYouTubePlatformFailure = YouTubeEmbeddedPlayerPlatformFailure;

/// Debug/private-Dev iOS boundary for the provider-only WKWebView.
///
/// The matching native factory is registered only in Debug builds, while the
/// shared feature flag remains disabled unless a private-Dev build explicitly
/// enables it.
class IosYouTubeEmbeddedPlayerSurface extends StatefulWidget {
  const IosYouTubeEmbeddedPlayerSurface({required this.onPortReady, super.key});

  final IosYouTubePlayerPortReady onPortReady;

  @override
  State<IosYouTubeEmbeddedPlayerSurface> createState() =>
      _IosYouTubeEmbeddedPlayerSurfaceState();
}

class _IosYouTubeEmbeddedPlayerSurfaceState
    extends State<IosYouTubeEmbeddedPlayerSurface> {
  IosYouTubeEmbeddedPlayerPort? _port;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw UnsupportedError(
        'The private-Dev YouTube player probe is iOS-only.',
      );
    }
    return UiKitView(
      viewType: iosYouTubeEmbeddedPlayerViewType,
      layoutDirection: TextDirection.ltr,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (viewId) {
        final port = IosYouTubeEmbeddedPlayerPort(viewId);
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

class IosYouTubeEmbeddedPlayerPort implements YouTubeEmbeddedPlayerPort {
  IosYouTubeEmbeddedPlayerPort(int viewId)
    : _channel = MethodChannel('$iosYouTubeEmbeddedPlayerViewType/$viewId') {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static const _maximumBridgeMessageBytes = 8192;

  final MethodChannel _channel;
  IosYouTubePlayerEventListener? _onEvent;
  IosYouTubePlatformFailureListener? _onPlatformFailure;
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
      throw StateError('The iOS player configuration is unavailable.');
    }
    if (baseUrl.toString() != youtubeEmbeddedPlayerBaseUrl) {
      throw StateError('The iOS player base URL is not approved.');
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
    if (utf8.encode(encoded).length > _maximumBridgeMessageBytes) {
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
        if (raw is! String ||
            utf8.encode(raw).length > _maximumBridgeMessageBytes) {
          throw const FormatException('Invalid iOS player event.');
        }
        final event = YouTubePlayerEvent.decode(raw);
        await _onEvent?.call(event);
      case 'platformFailure':
        final raw = call.arguments;
        if (raw is! Map ||
            raw.length != 2 ||
            raw['code'] is! String ||
            raw['message'] is! String) {
          throw const FormatException('Invalid iOS player failure.');
        }
        await _onPlatformFailure?.call(
          YouTubeEmbeddedPlayerPlatformFailure(
            code: raw['code'] as String,
            message: raw['message'] as String,
          ),
        );
      default:
        throw MissingPluginException(
          'Unsupported iOS player callback: ${call.method}',
        );
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('The iOS player port is closed.');
    }
  }
}
