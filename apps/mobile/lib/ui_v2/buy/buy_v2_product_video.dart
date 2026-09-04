import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../features/buy/buy_v2_content_contracts.dart';
import '../../features/buy/buy_v2_models.dart';
import 'buy_v2_design.dart';

typedef BuyV2ProductVideoControllerFactory =
    VideoPlayerController Function(Uri source);
typedef BuyV2ProductVideoBuilder =
    Widget Function(VideoPlayerController controller);

VideoPlayerController _buyV2NetworkVideoController(Uri source) =>
    VideoPlayerController.networkUrl(source);

Widget _buyV2VideoSurface(VideoPlayerController controller) =>
    VideoPlayer(controller);

class BuyV2ProductVideo extends StatefulWidget {
  const BuyV2ProductVideo({
    super.key,
    required this.product,
    required this.media,
    required this.active,
    this.controllerFactory = _buyV2NetworkVideoController,
    this.videoBuilder = _buyV2VideoSurface,
  });

  final BuyV2Product product;
  final BuyV2ProductMediaAsset media;
  final bool active;
  final BuyV2ProductVideoControllerFactory controllerFactory;
  final BuyV2ProductVideoBuilder videoBuilder;

  @override
  State<BuyV2ProductVideo> createState() => _BuyV2ProductVideoState();
}

class _BuyV2ProductVideoState extends State<BuyV2ProductVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initializing = true;
  bool _muted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  @override
  void didUpdateWidget(covariant BuyV2ProductVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.source != widget.media.source) {
      unawaited(_initialize());
      return;
    }
    if (oldWidget.active && !widget.active) {
      unawaited(_controller?.pause());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_controller?.pause());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_refresh);
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    final previous = _controller;
    _controller = null;
    if (previous != null) {
      previous.removeListener(_refresh);
      await previous.dispose();
    }
    final uri = Uri.tryParse(widget.media.source ?? '');
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      _setFailure('This product video is unavailable right now.');
      return;
    }
    if (mounted) {
      setState(() {
        _initializing = true;
        _error = null;
      });
    } else {
      _initializing = true;
      _error = null;
    }
    final controller = widget.controllerFactory(uri);
    _controller = controller;
    controller.addListener(_refresh);
    try {
      await controller.initialize();
      if (!mounted || !identical(_controller, controller)) {
        controller.removeListener(_refresh);
        await controller.dispose();
        return;
      }
      await controller.setLooping(false);
      await controller.setVolume(_muted ? 0 : 1);
      setState(() => _initializing = false);
    } on Object {
      if (identical(_controller, controller)) {
        controller.removeListener(_refresh);
        _controller = null;
        await controller.dispose();
      }
      _setFailure('This product video could not load. Try again.');
    }
  }

  void _setFailure(String message) {
    if (!mounted) {
      _initializing = false;
      _error = message;
      return;
    }
    setState(() {
      _initializing = false;
      _error = message;
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }
    if (controller.value.position >= controller.value.duration) {
      await controller.seekTo(Duration.zero);
    }
    await controller.play();
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    _muted = !_muted;
    await controller.setVolume(_muted ? 0 : 1);
    if (mounted) setState(() {});
  }

  void _showTranscript() {
    final transcript = widget.media.transcript;
    if (transcript == null || transcript.trim().isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          key: ValueKey('buy-product-video-transcript-${widget.media.id}'),
          padding: EdgeInsets.fromLTRB(
            18,
            0,
            18,
            18 + MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Video transcript',
                      style: sheetContext.buyTitle.copyWith(fontSize: 19),
                    ),
                  ),
                  IconButton.outlined(
                    key: const ValueKey('buy-product-video-transcript-close'),
                    tooltip: 'Close transcript',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(widget.media.label, style: sheetContext.buyBody),
              const SizedBox(height: 10),
              Text(
                transcript,
                style: sheetContext.buyMeta.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _poster() {
    final poster = Uri.tryParse(widget.media.posterSource ?? '');
    final fallback = BuyV2ProductPackshot(
      product: widget.product,
      borderRadius: 17,
      animateFirstFrame: false,
    );
    if (poster == null ||
        (poster.scheme != 'https' && poster.scheme != 'http') ||
        poster.host.isEmpty) {
      return fallback;
    }
    return Image.network(
      poster.toString(),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final value = controller?.value;
    final error = _error;
    final initialized = value?.isInitialized ?? false;
    return Semantics(
      key: ValueKey('buy-product-video-${widget.media.id}'),
      container: true,
      label: '${widget.media.semanticLabel}. Product video.',
      liveRegion: error != null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!initialized) _poster(),
              if (initialized && controller != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: value!.aspectRatio == 0
                        ? 16 / 9
                        : value.aspectRatio,
                    child: widget.videoBuilder(controller),
                  ),
                ),
              if (_initializing)
                const ColoredBox(
                  color: Color(0x66000000),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              if (error != null)
                ColoredBox(
                  color: const Color(0xB3000000),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam_off_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            key: ValueKey(
                              'buy-product-video-retry-${widget.media.id}',
                            ),
                            onPressed: _initialize,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              minimumSize: const Size(120, 44),
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                          const SizedBox(height: 4),
                          TextButton.icon(
                            key: ValueKey(
                              'buy-product-video-error-transcript-'
                              '${widget.media.id}',
                            ),
                            onPressed: _showTranscript,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size(120, 44),
                            ),
                            icon: const Icon(Icons.subtitles_outlined),
                            label: const Text('Read transcript'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (initialized && !_initializing && error == null) ...[
                Center(
                  child: IconButton.filled(
                    key: ValueKey('buy-product-video-play-${widget.media.id}'),
                    tooltip: value!.isPlaying ? 'Pause video' : 'Play video',
                    onPressed: _togglePlayback,
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(52),
                      backgroundColor: const Color(0xCC000040),
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(
                      value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 30,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ColoredBox(
                    color: const Color(0xB3000000),
                    child: SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          IconButton(
                            key: ValueKey(
                              'buy-product-video-transcript-button-'
                              '${widget.media.id}',
                            ),
                            tooltip: 'Read transcript',
                            onPressed: _showTranscript,
                            color: Colors.white,
                            icon: const Icon(Icons.subtitles_outlined),
                          ),
                          Expanded(
                            child: Slider(
                              key: ValueKey(
                                'buy-product-video-progress-${widget.media.id}',
                              ),
                              value: value.duration.inMilliseconds == 0
                                  ? 0
                                  : (value.position.inMilliseconds /
                                            value.duration.inMilliseconds)
                                        .clamp(0.0, 1.0),
                              onChanged: (progress) => _controller?.seekTo(
                                Duration(
                                  milliseconds:
                                      (value.duration.inMilliseconds * progress)
                                          .round(),
                                ),
                              ),
                              activeColor: Colors.white,
                              inactiveColor: Colors.white38,
                            ),
                          ),
                          Text(
                            _durationLabel(value.position, value.duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            key: ValueKey(
                              'buy-product-video-mute-${widget.media.id}',
                            ),
                            tooltip: _muted ? 'Unmute video' : 'Mute video',
                            onPressed: _toggleMute,
                            color: Colors.white,
                            icon: Icon(
                              _muted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _durationLabel(Duration position, Duration duration) {
  String part(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  return '${part(position)} / ${part(duration)}';
}
