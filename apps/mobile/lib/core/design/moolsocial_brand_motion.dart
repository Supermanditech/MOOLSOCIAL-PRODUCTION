import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mool_colors.dart';

typedef MoolSocialBrandClock = DateTime Function();

/// Session-scoped cadence for the finite MoolSocial identity choreography.
///
/// Ordinary activity can arm a later brand replay after meaningful inactivity,
/// but only a deliberate brand interaction consumes that replay. A long app
/// pause may request one automatic resume replay under the same cooldown.
class MoolSocialBrandCadence extends ChangeNotifier {
  MoolSocialBrandCadence({
    MoolSocialBrandClock? now,
    this.inactivityThreshold = const Duration(minutes: 10),
    this.playbackCooldown = const Duration(minutes: 20),
  }) : _now = now ?? DateTime.now;

  final MoolSocialBrandClock _now;
  final Duration inactivityThreshold;
  final Duration playbackCooldown;

  DateTime? _lastActivity;
  DateTime? _lastPlayback;
  DateTime? _pausedAt;
  bool _interactionReplayArmed = false;
  int _autoReplayGeneration = 1;
  int _consumedAutoReplayGeneration = 0;

  int get autoReplayGeneration => _autoReplayGeneration;
  bool get interactionReplayArmed => _interactionReplayArmed;

  void noteActivity() {
    final current = _now();
    final previous = _lastActivity;
    if (previous != null &&
        current.difference(previous) >= inactivityThreshold) {
      _interactionReplayArmed = true;
    }
    _lastActivity = current;
  }

  bool consumeAutomaticReplay(int generation) {
    if (generation <= _consumedAutoReplayGeneration) return false;
    _consumedAutoReplayGeneration = generation;
    final current = _now();
    if (!_cooldownAllows(current)) return false;
    _recordPlayback(current);
    return true;
  }

  bool requestInteractionReplay() {
    final current = _now();
    final previous = _lastActivity;
    if (previous != null &&
        current.difference(previous) >= inactivityThreshold) {
      _interactionReplayArmed = true;
    }
    _lastActivity = current;
    if (!_interactionReplayArmed || !_cooldownAllows(current)) return false;
    _interactionReplayArmed = false;
    _recordPlayback(current);
    return true;
  }

  void appPaused() {
    _pausedAt ??= _now();
  }

  void appResumed() {
    final current = _now();
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null ||
        current.difference(pausedAt) < inactivityThreshold ||
        !_cooldownAllows(current)) {
      return;
    }
    _autoReplayGeneration += 1;
    notifyListeners();
  }

  bool _cooldownAllows(DateTime current) {
    final lastPlayback = _lastPlayback;
    return lastPlayback == null ||
        current.difference(lastPlayback) >= playbackCooldown;
  }

  void _recordPlayback(DateTime current) {
    _lastPlayback = current;
    _lastActivity = current;
  }
}

class MoolSocialBrandMotionScope
    extends InheritedNotifier<MoolSocialBrandCadence> {
  const MoolSocialBrandMotionScope({
    super.key,
    required MoolSocialBrandCadence cadence,
    required super.child,
  }) : super(notifier: cadence);

  static MoolSocialBrandCadence? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MoolSocialBrandMotionScope>()
        ?.notifier;
  }
}

enum MoolSocialBrandLayout { fullWordmark, stackedWords, singleSlotWords }

/// One semantic and hit owner for the MoolSocial identity choreography.
///
/// The complete MoolSocial identity is readable at the first painted frame and
/// remains the permanent outcome. The widget never loops, never animates its
/// layout width, and never gates route readiness.
class MoolSocialBrandMotion extends StatefulWidget {
  const MoolSocialBrandMotion({
    super.key,
    this.onDarkBackground = false,
    this.width = 118,
    this.height = 44,
    this.fontSize = 10,
    this.surfaceColor,
    this.borderRadius = 13,
    this.autoPlay = true,
    this.progressOverride,
    this.onPressed,
    this.cadence,
    this.layout = MoolSocialBrandLayout.fullWordmark,
    this.motionDuration = duration,
    this.useSharedCadence = true,
    this.repeatSingleSlotWords = false,
  }) : assert(
         progressOverride == null ||
             (progressOverride >= 0 && progressOverride <= 1),
       );

  static const duration = Duration(milliseconds: 1200);

  final bool onDarkBackground;
  final double width;
  final double height;
  final double fontSize;
  final Color? surfaceColor;
  final double borderRadius;
  final bool autoPlay;
  final double? progressOverride;
  final VoidCallback? onPressed;
  final MoolSocialBrandCadence? cadence;
  final MoolSocialBrandLayout layout;
  final Duration motionDuration;
  final bool useSharedCadence;

  /// Alternates Mool and Social in one stable slot using idle-timer initiated
  /// finite turns. This never keeps a Flutter ticker alive between turns.
  final bool repeatSingleSlotWords;

  @override
  State<MoolSocialBrandMotion> createState() => _MoolSocialBrandMotionState();
}

class _MoolSocialBrandMotionState extends State<MoolSocialBrandMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.motionDuration,
    value: 1,
  );
  late final MoolSocialBrandCadence _localCadence = MoolSocialBrandCadence();

  MoolSocialBrandCadence? _cadence;
  bool _reduceMotion = false;
  int _handledAutoReplayGeneration = 0;
  Timer? _singleSlotTimer;
  bool _singleSlotCycleConfigured = false;
  bool _singleSlotForward = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cadence =
        widget.cadence ??
        (widget.useSharedCadence
            ? MoolSocialBrandMotionScope.maybeOf(context)
            : null) ??
        _localCadence;
    if (_cadence != cadence) {
      _cadence?.removeListener(_handleCadenceSignal);
      _cadence = cadence..addListener(_handleCadenceSignal);
      _handledAutoReplayGeneration = 0;
    }

    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _stopSingleSlotCycle(reset: true);
      _controller
        ..stop()
        ..value = widget.repeatSingleSlotWords ? 0 : 1;
    } else if (widget.repeatSingleSlotWords) {
      _configureSingleSlotCycle();
    }
    _scheduleAutomaticReplayAfterPaint();
  }

  @override
  void didUpdateWidget(covariant MoolSocialBrandMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionDuration != widget.motionDuration) {
      _controller.duration = widget.motionDuration;
    }
    if (oldWidget.repeatSingleSlotWords != widget.repeatSingleSlotWords ||
        oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.progressOverride != widget.progressOverride) {
      _stopSingleSlotCycle(reset: widget.repeatSingleSlotWords);
      if (!_reduceMotion && widget.repeatSingleSlotWords) {
        _configureSingleSlotCycle();
      }
    }
    if (oldWidget.cadence != widget.cadence ||
        oldWidget.useSharedCadence != widget.useSharedCadence) {
      _cadence?.removeListener(_handleCadenceSignal);
      final cadence =
          widget.cadence ??
          (widget.useSharedCadence
              ? MoolSocialBrandMotionScope.maybeOf(context)
              : null) ??
          _localCadence;
      _cadence = cadence..addListener(_handleCadenceSignal);
      _handledAutoReplayGeneration = 0;
    }
    if (!widget.autoPlay) {
      _controller
        ..stop()
        ..value = 1;
    }
    _scheduleAutomaticReplayAfterPaint();
  }

  void _handleCadenceSignal() {
    if (!mounted) return;
    _scheduleAutomaticReplayAfterPaint();
  }

  /// Paint progress zero once before consuming the shared generation. This
  /// makes cold-start motion observable and prevents route construction from
  /// advancing the controller before its start frame can reach the display.
  void _scheduleAutomaticReplayAfterPaint() {
    if (widget.repeatSingleSlotWords) return;
    final cadence = _cadence;
    if (cadence == null || !widget.autoPlay) return;
    final generation = cadence.autoReplayGeneration;
    if (generation <= _handledAutoReplayGeneration) return;
    _handledAutoReplayGeneration = generation;

    if (_reduceMotion || widget.progressOverride != null) {
      cadence.consumeAutomaticReplay(generation);
      _controller
        ..stop()
        ..value = 1;
      return;
    }

    _controller
      ..stop()
      ..value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _cadence != cadence || !widget.autoPlay) return;
      final shouldPlay = cadence.consumeAutomaticReplay(generation);
      if (shouldPlay) {
        _controller.forward(from: 0);
      } else {
        _controller.value = 1;
      }
    });
  }

  void _handleBrandInteraction() {
    if (widget.repeatSingleSlotWords) {
      widget.onPressed?.call();
      return;
    }
    final shouldReplay = _cadence?.requestInteractionReplay() ?? false;
    if (shouldReplay && !_reduceMotion && widget.progressOverride == null) {
      HapticFeedback.selectionClick();
      _controller.forward(from: 0);
    }
    widget.onPressed?.call();
  }

  @override
  void dispose() {
    _singleSlotTimer?.cancel();
    _cadence?.removeListener(_handleCadenceSignal);
    _controller.dispose();
    _localCadence.dispose();
    super.dispose();
  }

  void _configureSingleSlotCycle() {
    if (_singleSlotCycleConfigured ||
        !widget.autoPlay ||
        widget.progressOverride != null ||
        _reduceMotion) {
      return;
    }
    _singleSlotCycleConfigured = true;
    _singleSlotForward = true;
    _controller
      ..stop()
      ..value = 0;
    _scheduleSingleSlotTurn(const Duration(milliseconds: 1200));
  }

  void _scheduleSingleSlotTurn(Duration dwell) {
    _singleSlotTimer?.cancel();
    _singleSlotTimer = Timer(dwell, () {
      _singleSlotTimer = null;
      if (!mounted ||
          !_singleSlotCycleConfigured ||
          _reduceMotion ||
          !widget.autoPlay ||
          widget.progressOverride != null) {
        return;
      }
      final turn = _singleSlotForward
          ? _controller.forward(from: 0)
          : _controller.reverse(from: 1);
      turn.then((_) {
        if (!mounted || !_singleSlotCycleConfigured) return;
        _singleSlotForward = !_singleSlotForward;
        _scheduleSingleSlotTurn(const Duration(milliseconds: 2100));
      });
    });
  }

  void _stopSingleSlotCycle({required bool reset}) {
    _singleSlotTimer?.cancel();
    _singleSlotTimer = null;
    _singleSlotCycleConfigured = false;
    _controller.stop();
    if (reset) {
      _singleSlotForward = true;
      _controller.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('moolsocial-brand-semantics'),
      label: 'MoolSocial',
      header: true,
      button: widget.onPressed != null,
      child: ExcludeSemantics(
        child: GestureDetector(
          key: const ValueKey('moolsocial-brand-hit-owner'),
          behavior: HitTestBehavior.opaque,
          onTap: _handleBrandInteraction,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _BrandFrame(
              progress: widget.progressOverride ?? _controller.value,
              onDarkBackground: widget.onDarkBackground,
              width: widget.width,
              height: widget.height,
              fontSize: widget.fontSize,
              surfaceColor: widget.surfaceColor,
              borderRadius: widget.borderRadius,
              layout: widget.layout,
              showStaticSingleSlotFullName:
                  _reduceMotion && widget.repeatSingleSlotWords,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandFrame extends StatelessWidget {
  const _BrandFrame({
    required this.progress,
    required this.onDarkBackground,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.surfaceColor,
    required this.borderRadius,
    required this.layout,
    required this.showStaticSingleSlotFullName,
  });

  final double progress;
  final bool onDarkBackground;
  final double width;
  final double height;
  final double fontSize;
  final Color? surfaceColor;
  final double borderRadius;
  final MoolSocialBrandLayout layout;
  final bool showStaticSingleSlotFullName;

  @override
  Widget build(BuildContext context) {
    final singleSlot = layout == MoolSocialBrandLayout.singleSlotWords;
    final wordmarkArrival = _interval(progress, 0, .42, Curves.easeOutCubic);
    final identityLine = _interval(progress, .24, .68, Curves.easeOutCubic);
    final settle = _interval(progress, .62, 1, Curves.easeOutCubic);
    final letterColour = onDarkBackground ? Colors.white : MoolColors.navy;
    final remainingDepth = (1 - wordmarkArrival) * (1 - (.35 * settle));
    final accentStrength = wordmarkArrival * (1 - settle);
    final wordmarkPerspective = singleSlot
        ? Matrix4.identity()
        : (Matrix4.identity()
            ..setEntry(3, 2, .0016)
            ..rotateX(.055 * remainingDepth)
            ..rotateY(-.11 * remainingDepth));

    final stackedBaseShadow = onDarkBackground
        ? MoolColors.navy.withValues(alpha: .62)
        : Colors.white.withValues(alpha: .72);
    final wordStyle = TextStyle(
      color: letterColour,
      fontSize: fontSize,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: -.45,
      shadows: layout == MoolSocialBrandLayout.singleSlotWords
          ? [
              Shadow(
                color: MoolColors.navy.withValues(alpha: .78),
                offset: const Offset(0, 1.5),
                blurRadius: 3.6,
              ),
            ]
          : layout == MoolSocialBrandLayout.stackedWords
          ? [
              Shadow(
                color: stackedBaseShadow,
                offset: const Offset(0, 1.4),
                blurRadius: 3.2,
              ),
              Shadow(
                color: MoolColors.orange.withValues(
                  alpha: .24 * accentStrength,
                ),
                offset: Offset(-1.8 * accentStrength, 0),
                blurRadius: 3.2 * accentStrength,
              ),
              Shadow(
                color: MoolColors.success.withValues(
                  alpha: .22 * accentStrength,
                ),
                offset: Offset(1.8 * accentStrength, 0),
                blurRadius: 3.2 * accentStrength,
              ),
            ]
          : accentStrength <= 0
          ? null
          : [
              Shadow(
                color: MoolColors.orange.withValues(
                  alpha: .16 * accentStrength,
                ),
                offset: Offset(-1.4 * accentStrength, 0),
                blurRadius: 2.6 * accentStrength,
              ),
              Shadow(
                color: MoolColors.success.withValues(
                  alpha: .14 * accentStrength,
                ),
                offset: Offset(1.4 * accentStrength, 0),
                blurRadius: 2.6 * accentStrength,
              ),
            ],
    );

    Widget frame = SizedBox(
      key: const ValueKey('moolsocial-brand-motion-frame'),
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: switch (layout) {
              MoolSocialBrandLayout.stackedWords => math.max(3, fontSize * .22),
              MoolSocialBrandLayout.singleSlotWords => math.max(
                1.5,
                fontSize * .08,
              ),
              MoolSocialBrandLayout.fullWordmark => math.max(5, fontSize * .42),
            },
            vertical: switch (layout) {
              MoolSocialBrandLayout.stackedWords => math.max(2, fontSize * .12),
              MoolSocialBrandLayout.singleSlotWords => math.max(
                2.5,
                fontSize * .12,
              ),
              MoolSocialBrandLayout.fullWordmark => math.max(3, fontSize * .20),
            },
          ),
          child: Center(
            child: Opacity(
              key: const ValueKey('moolsocial-brand-wordmark-opacity'),
              opacity: singleSlot
                  ? 1
                  : (.54 + (.46 * wordmarkArrival)).clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, singleSlot ? 0 : (1 - wordmarkArrival) * 3),
                child: Transform.scale(
                  scale: singleSlot ? 1 : .965 + (.035 * wordmarkArrival),
                  child: Transform(
                    key: const ValueKey('moolsocial-brand-wordmark-transform'),
                    alignment: Alignment.center,
                    transform: wordmarkPerspective,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: switch (layout) {
                        MoolSocialBrandLayout.stackedWords => _StackedWordmark(
                          progress: progress,
                          fontSize: fontSize,
                          style: wordStyle,
                        ),
                        MoolSocialBrandLayout.singleSlotWords =>
                          _SingleSlotWordmark(
                            progress: progress,
                            fontSize: fontSize,
                            style: wordStyle,
                            showStaticFullName: showStaticSingleSlotFullName,
                          ),
                        MoolSocialBrandLayout.fullWordmark => _FullWordmark(
                          fontSize: fontSize,
                          style: wordStyle,
                          identityLine: identityLine,
                        ),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (surfaceColor != null) {
      frame = DecoratedBox(
        key: const ValueKey('moolsocial-brand-surface'),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: onDarkBackground
                ? Colors.white.withValues(alpha: .24)
                : MoolColors.navy.withValues(alpha: .10),
          ),
        ),
        child: frame,
      );
    }
    return RepaintBoundary(child: frame);
  }

  static double _interval(double value, double begin, double end, Curve curve) {
    if (value <= begin) return 0;
    if (value >= end) return 1;
    return curve.transform((value - begin) / (end - begin));
  }
}

class _FullWordmark extends StatelessWidget {
  const _FullWordmark({
    required this.fontSize,
    required this.style,
    required this.identityLine,
  });

  final double fontSize;
  final TextStyle style;
  final double identityLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('moolsocial-brand-wordmark'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MoolSocial',
          key: const ValueKey('moolsocial-brand-wordmark-text'),
          maxLines: 1,
          softWrap: false,
          style: style,
        ),
        SizedBox(height: math.max(3, fontSize * .20)),
        _BrandIdentityLine(
          fontSize: fontSize,
          progress: identityLine,
          widthFactor: 5.7,
        ),
      ],
    );
  }
}

class _StackedWordmark extends StatelessWidget {
  const _StackedWordmark({
    required this.progress,
    required this.fontSize,
    required this.style,
  });

  final double progress;
  final double fontSize;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final moolArrival = _BrandFrame._interval(
      progress,
      0,
      .34,
      Curves.easeOutCubic,
    );
    final moolDepthArrival = _BrandFrame._interval(
      progress,
      0,
      .38,
      Curves.easeOutBack,
    );
    final socialArrival = _BrandFrame._interval(
      progress,
      .28,
      .68,
      Curves.easeOutCubic,
    );
    final socialDepthArrival = _BrandFrame._interval(
      progress,
      .28,
      .72,
      Curves.easeOutBack,
    );
    final lineArrival = _BrandFrame._interval(
      progress,
      .68,
      .92,
      Curves.easeOutCubic,
    );
    final moolDepth = Matrix4.identity()
      ..setEntry(3, 2, .0032)
      ..rotateX(-.42 * (1 - moolDepthArrival))
      ..rotateY(1.28 * (1 - moolDepthArrival));
    final socialDepth = Matrix4.identity()
      ..setEntry(3, 2, .0034)
      ..rotateX(1.52 * (1 - socialDepthArrival))
      ..rotateY(-.48 * (1 - socialDepthArrival));

    return Column(
      key: const ValueKey('moolsocial-brand-stacked-wordmark'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          key: const ValueKey('moolsocial-brand-stacked-mool-opacity'),
          opacity: moolArrival,
          child: Transform.translate(
            offset: Offset(-17 * (1 - moolArrival), 9 * (1 - moolArrival)),
            child: Transform.scale(
              scale: .56 + (.44 * moolDepthArrival),
              child: Transform(
                key: const ValueKey('moolsocial-brand-stacked-mool-depth'),
                alignment: Alignment.center,
                transform: moolDepth,
                child: Text(
                  'Mool',
                  key: const ValueKey('moolsocial-brand-stacked-mool'),
                  maxLines: 1,
                  softWrap: false,
                  style: style.copyWith(height: .88),
                ),
              ),
            ),
          ),
        ),
        ClipRect(
          child: SizedBox(
            height: fontSize * .92,
            child: Opacity(
              key: const ValueKey('moolsocial-brand-stacked-social-opacity'),
              opacity: socialArrival,
              child: Transform.translate(
                offset: Offset(
                  5 * (1 - socialArrival),
                  -fontSize * 1.22 * (1 - socialArrival),
                ),
                child: Transform.scale(
                  scale: .52 + (.48 * socialDepthArrival),
                  child: Transform(
                    key: const ValueKey(
                      'moolsocial-brand-stacked-social-depth',
                    ),
                    alignment: Alignment.topCenter,
                    transform: socialDepth,
                    child: Text(
                      'Social',
                      key: const ValueKey('moolsocial-brand-stacked-social'),
                      maxLines: 1,
                      softWrap: false,
                      style: style.copyWith(height: .88),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: math.max(1.5, fontSize * .08)),
        _BrandIdentityLine(
          fontSize: fontSize,
          progress: lineArrival,
          widthFactor: 3.15,
        ),
      ],
    );
  }
}

/// A compact header-only identity stage where each word owns the same slot.
///
/// Mool and Social occupy the exact same analogue date-wheel footprint. The
/// controller may run one finite turn in either direction, then dwells without
/// retaining a ticker.
class _SingleSlotWordmark extends StatelessWidget {
  const _SingleSlotWordmark({
    required this.progress,
    required this.fontSize,
    required this.style,
    required this.showStaticFullName,
  });

  final double progress;
  final double fontSize;
  final TextStyle style;
  final bool showStaticFullName;

  @override
  Widget build(BuildContext context) {
    final turn = _BrandFrame._interval(
      progress,
      .06,
      .94,
      Curves.easeInOutCubic,
    );
    final outgoingFade = _BrandFrame._interval(
      turn,
      .34,
      .58,
      Curves.easeInCubic,
    );
    final incomingFade = _BrandFrame._interval(
      turn,
      .42,
      .66,
      Curves.easeOutCubic,
    );
    final moolOpacity = showStaticFullName ? 0.0 : 1 - outgoingFade;
    final socialOpacity = showStaticFullName ? 0.0 : incomingFade;
    final edgeLight = showStaticFullName
        ? 0.0
        : math.sin(math.pi * turn).clamp(0.0, 1.0);

    return SizedBox(
      key: const ValueKey('moolsocial-brand-single-slot-wordmark'),
      width: fontSize * 3.18,
      height: fontSize * 1.74,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.centerLeft,
          children: [
            _SingleSlotWord(
              key: const ValueKey('moolsocial-brand-single-slot-mool'),
              text: 'Mool',
              opacityKey: const ValueKey(
                'moolsocial-brand-single-slot-mool-opacity',
              ),
              opacity: moolOpacity,
              turn: turn,
              incoming: false,
              style: style,
            ),
            IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: Opacity(
                  key: const ValueKey(
                    'moolsocial-brand-single-slot-edge-light-opacity',
                  ),
                  opacity: edgeLight * .72,
                  child: Container(
                    key: const ValueKey(
                      'moolsocial-brand-single-slot-edge-light',
                    ),
                    width: fontSize * 2.75,
                    height: 1.4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: .64),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _SingleSlotWord(
              key: const ValueKey('moolsocial-brand-single-slot-social'),
              text: 'Social',
              opacityKey: const ValueKey(
                'moolsocial-brand-single-slot-social-opacity',
              ),
              opacity: socialOpacity,
              turn: turn,
              incoming: true,
              style: style,
            ),
            _SingleSlotWord(
              key: const ValueKey('moolsocial-brand-single-slot-full'),
              text: 'MoolSocial',
              opacityKey: const ValueKey(
                'moolsocial-brand-single-slot-full-opacity',
              ),
              opacity: showStaticFullName ? 1 : 0,
              turn: turn,
              incoming: true,
              style: style.copyWith(fontSize: fontSize * .72),
            ),
          ],
        ),
      ),
    );
  }
}

class _SingleSlotWord extends StatelessWidget {
  const _SingleSlotWord({
    super.key,
    required this.text,
    required this.opacityKey,
    required this.opacity,
    required this.turn,
    required this.incoming,
    required this.style,
  });

  final String text;
  final Key opacityKey;
  final double opacity;
  final double turn;
  final bool incoming;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final phase = incoming ? 1 - turn : turn;
    final direction = incoming ? 1.0 : -1.0;
    final edgeProximity = math.sin(math.pi * phase).clamp(0.0, 1.0);
    final depth = Matrix4.identity()
      ..setEntry(3, 2, .0054)
      ..rotateX(phase * math.pi * .58 * direction)
      ..rotateY(phase * .18 * direction);
    return Opacity(
      key: opacityKey,
      opacity: opacity.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, phase * (style.fontSize ?? 16) * .46 * direction),
        child: Transform.scale(
          scale: .70 + (.30 * (1 - phase)) + (.055 * edgeProximity),
          child: Transform(
            alignment: incoming ? Alignment.topCenter : Alignment.bottomCenter,
            transform: depth,
            child: Align(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(text, maxLines: 1, softWrap: false, style: style),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandIdentityLine extends StatelessWidget {
  const _BrandIdentityLine({
    required this.fontSize,
    required this.progress,
    required this.widthFactor,
  });

  final double fontSize;
  final double progress;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      key: const ValueKey('moolsocial-brand-identity-line'),
      alignment: Alignment.centerLeft,
      scaleX: .08 + (.92 * progress),
      child: Opacity(
        opacity: .32 + (.68 * progress),
        child: SizedBox(
          width: fontSize * widthFactor,
          height: math.max(2, fontSize * .12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(child: ColoredBox(color: MoolColors.orange)),
              Expanded(child: ColoredBox(color: Colors.white)),
              Expanded(child: ColoredBox(color: MoolColors.success)),
            ],
          ),
        ),
      ),
    );
  }
}
