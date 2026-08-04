import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/moolsocial_brand_motion.dart';
import '../../../features/journey01/journey_session.dart';
import '../../launch/launch_presentation_gate.dart';

abstract final class _SplashV2Tokens {
  static const navy = Color(0xFF000080);
  static const green = Color(0xFF138808);
  static const white = Colors.white;

  static const horizontalPadding = 26.0;
  static const revealDuration = Duration(milliseconds: 2400);
}

class AppSplashScreenV2 extends StatefulWidget {
  const AppSplashScreenV2({
    required this.session,
    required this.presentationGate,
    super.key,
  });

  final JourneySession session;
  final LaunchPresentationGate presentationGate;

  @override
  State<AppSplashScreenV2> createState() => _AppSplashScreenV2State();
}

class _AppSplashScreenV2State extends State<AppSplashScreenV2>
    with TickerProviderStateMixin {
  late final AnimationController _brandMotion = AnimationController(
    vsync: this,
    duration: _SplashV2Tokens.revealDuration,
  );
  late final Listenable _screenState = Listenable.merge([
    widget.session,
    widget.presentationGate,
  ]);

  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_syncMotionWithVisibleState);
    widget.presentationGate.addListener(_syncMotionWithVisibleState);
    widget.presentationGate.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.session.start());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;

    if (reduceMotion) {
      _brandMotion.stop();
      _brandMotion.value = 1;
    } else {
      _syncMotionWithVisibleState();
    }
  }

  void _syncMotionWithVisibleState() {
    final normalOpen =
        widget.session.stage != JourneyStage.bootFailure &&
        !(widget.presentationGate.minimumElapsed &&
            widget.session.stage == JourneyStage.booting);
    if ((_reduceMotion ?? false) || !normalOpen) {
      _brandMotion.stop();
    } else if (!_brandMotion.isAnimating && !_brandMotion.isCompleted) {
      _brandMotion.forward();
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_syncMotionWithVisibleState);
    widget.presentationGate.removeListener(_syncMotionWithVisibleState);
    _brandMotion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _SplashV2Tokens.navy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _SplashV2Tokens.navy,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: _SplashV2Tokens.navy,
      ),
      child: Scaffold(
        key: const Key('screen01-v2'),
        backgroundColor: _SplashV2Tokens.navy,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _screenState,
            builder: (context, _) {
              if (widget.session.stage == JourneyStage.bootFailure) {
                return _RecoveryState(
                  onRetry: widget.session.retryBoot,
                  onHelp: _openHelp,
                );
              }

              if (widget.presentationGate.minimumElapsed &&
                  widget.session.stage == JourneyStage.booting) {
                return const _SilentHandoffState();
              }

              return _NormalOpenState(
                brandMotion: _brandMotion,
                reduceMotion: _reduceMotion ?? false,
              );
            },
          ),
        ),
      ),
    );
  }

  void _openHelp() {
    widget.session.captureReturnTo('/app/chat');
    unawaited(widget.session.retryBoot());
  }
}

class _NormalOpenState extends StatelessWidget {
  const _NormalOpenState({
    required this.brandMotion,
    required this.reduceMotion,
  });

  final AnimationController brandMotion;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('splash-v2-normal'),
      label:
          'MoolSocial. India Ka Socio Commerce App. '
          'Create. Connect. Work. Grow. One app for life and business. '
          'Opening your MoolSocial space.',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _SplashV2Tokens.horizontalPadding,
            34,
            _SplashV2Tokens.horizontalPadding,
            26,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProgressiveBrandLockup(
                        animation: brandMotion,
                        reduceMotion: reduceMotion,
                      ),
                    ],
                  ),
                ),
              ),
              const _OpeningFooter(status: 'Opening your MoolSocial space'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SilentHandoffState extends StatelessWidget {
  const _SilentHandoffState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('splash-v2-handoff'),
      label:
          'MoolSocial. India Ka Socio Commerce App. '
          'Create. Connect. Work. Grow. One app for life and business. '
          'Still opening your MoolSocial space.',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _SplashV2Tokens.horizontalPadding,
            34,
            _SplashV2Tokens.horizontalPadding,
            26,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _ProgressiveBrandLockup(reduceMotion: true),
                    ],
                  ),
                ),
              ),
              const _OpeningFooter(
                status: 'Still opening your MoolSocial space',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoveryState extends StatelessWidget {
  const _RecoveryState({required this.onRetry, required this.onHelp});

  final VoidCallback onRetry;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('splash-v2-recovery'),
      label: 'MoolSocial launch recovery',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _SplashV2Tokens.horizontalPadding,
          vertical: 34,
        ),
        child: Column(
          children: [
            const Spacer(),
            const _Wordmark(),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: _SplashV2Tokens.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Connection paused',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _SplashV2Tokens.navy,
                      fontSize: 21,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check your internet connection, then try again.',
                    key: Key('boot-error'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _SplashV2Tokens.navy,
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: Semantics(
                      button: true,
                      child: Material(
                        color: _SplashV2Tokens.navy,
                        shape: const StadiumBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const Key('retry-boot'),
                          onTap: onRetry,
                          customBorder: const StadiumBorder(),
                          child: const Center(
                            child: Text(
                              'Retry',
                              style: TextStyle(
                                color: _SplashV2Tokens.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: Semantics(
                      button: true,
                      child: Material(
                        color: _SplashV2Tokens.white,
                        shape: const StadiumBorder(
                          side: BorderSide(color: _SplashV2Tokens.navy),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const Key('boot-help'),
                          onTap: onHelp,
                          customBorder: const StadiumBorder(),
                          child: const Center(
                            child: Text(
                              'Help',
                              style: TextStyle(
                                color: _SplashV2Tokens.navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const MoolSocialBrandMotion(
      width: 190,
      height: 52,
      fontSize: 25,
      onDarkBackground: true,
      autoPlay: false,
      progressOverride: 1,
    );
  }
}

class _ProgressiveBrandLockup extends StatelessWidget {
  const _ProgressiveBrandLockup({this.animation, required this.reduceMotion});

  final Animation<double>? animation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final listenable = animation ?? const AlwaysStoppedAnimation<double>(1);
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final progress = reduceMotion ? 1.0 : listenable.value;
        final wordmarkProgress = _interval(
          progress,
          0,
          .26,
          Curves.easeOutCubic,
        );
        final taglineProgress = _interval(
          progress,
          .20,
          .50,
          Curves.easeOutCubic,
        );
        final businessProgress = _interval(
          progress,
          .44,
          .76,
          Curves.easeOutCubic,
        );
        final settleProgress = _interval(progress, .72, 1, Curves.easeOutCubic);
        final lockupTransform = Matrix4.identity()
          ..setEntry(3, 2, .0012)
          ..rotateX(.018 * (1 - settleProgress));

        return RepaintBoundary(
          key: const Key('splash-v2-progressive-lockup'),
          child: Transform.translate(
            offset: Offset(0, 2 * (1 - settleProgress)),
            child: Transform.scale(
              scale: 1.012 - (.012 * settleProgress),
              child: Transform(
                key: const Key('splash-v2-unified-settle'),
                alignment: Alignment.center,
                transform: lockupTransform,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      key: const Key('splash-v2-wordmark-stage'),
                      width: 190,
                      height: 52,
                      child: Center(
                        child: MoolSocialBrandMotion(
                          width: 190,
                          height: 52,
                          fontSize: 29,
                          onDarkBackground: true,
                          progressOverride: wordmarkProgress,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      key: const Key('splash-v2-tagline-stage'),
                      opacity: taglineProgress,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - taglineProgress)),
                        child: Text(
                          'India Ka Socio Commerce App',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            color: _SplashV2Tokens.white.withValues(alpha: .92),
                            fontSize: 13,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Opacity(
                      key: const Key('splash-v2-business-stage'),
                      opacity: businessProgress,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - businessProgress)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Create. Connect. Work. Grow.',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                color: _SplashV2Tokens.white,
                                fontSize: 15.5,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'One app for life and business.',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                color: _SplashV2Tokens.white.withValues(
                                  alpha: .78,
                                ),
                                fontSize: 11.5,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static double _interval(double value, double begin, double end, Curve curve) {
    if (value <= begin) return 0;
    if (value >= end) return 1;
    return curve.transform((value - begin) / (end - begin));
  }
}

class _OpeningFooter extends StatelessWidget {
  const _OpeningFooter({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final availableWidth =
        MediaQuery.sizeOf(context).width -
        (_SplashV2Tokens.horizontalPadding * 2);
    return SizedBox(
      width: availableWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _SplashV2Tokens.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _SplashV2Tokens.white.withValues(alpha: .82),
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                letterSpacing: .12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
