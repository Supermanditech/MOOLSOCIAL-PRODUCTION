import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../features/journey01/journey_session.dart';
import '../../launch/launch_presentation_gate.dart';

abstract final class _SplashV2Tokens {
  static const navy = Color(0xFF000080);
  static const saffron = Color(0xFFFF9933);
  static const green = Color(0xFF138808);
  static const white = Colors.white;

  static const horizontalPadding = 26.0;
  static const trackWidth = 154.0;
  static const trackHeight = 6.0;
  static const capsuleWidth = 60.0;
  static const capsuleTravel = trackWidth - capsuleWidth;
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
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _promiseEntrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _capsuleTravel = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween<double>(0), weight: 10),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0,
        end: _SplashV2Tokens.capsuleTravel,
      ).chain(CurveTween(curve: const Cubic(.45, 0, .2, 1))),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: ConstantTween<double>(_SplashV2Tokens.capsuleTravel),
      weight: 10,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: _SplashV2Tokens.capsuleTravel,
        end: 0,
      ).chain(CurveTween(curve: const Cubic(.45, 0, .2, 1))),
      weight: 35,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(0), weight: 10),
  ]).animate(_brandMotion);
  late final Animation<double> _taglineScale = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween<double>(1), weight: 10),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.025,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 35,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(1.025), weight: 10),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.025,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 35,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(1), weight: 10),
  ]).animate(_brandMotion);
  late final Animation<double> _promiseOpacity = CurvedAnimation(
    parent: _promiseEntrance,
    curve: Curves.easeOutCubic,
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
      _brandMotion.value = 0;
      _promiseEntrance.stop();
      _promiseEntrance.value = 1;
    } else {
      _syncMotionWithVisibleState();
      _promiseEntrance.forward(from: 0);
    }
  }

  void _syncMotionWithVisibleState() {
    final normalOpen =
        widget.session.stage != JourneyStage.bootFailure &&
        !(widget.presentationGate.minimumElapsed &&
            widget.session.stage == JourneyStage.booting);
    if ((_reduceMotion ?? false) || !normalOpen) {
      _brandMotion.stop();
    } else if (!_brandMotion.isAnimating) {
      _brandMotion.repeat();
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_syncMotionWithVisibleState);
    widget.presentationGate.removeListener(_syncMotionWithVisibleState);
    _brandMotion.dispose();
    _promiseEntrance.dispose();
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
                capsuleTravel: _capsuleTravel,
                taglineScale: _taglineScale,
                promiseOpacity: _promiseOpacity,
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
    required this.capsuleTravel,
    required this.taglineScale,
    required this.promiseOpacity,
    required this.reduceMotion,
  });

  final AnimationController brandMotion;
  final Animation<double> capsuleTravel;
  final Animation<double> taglineScale;
  final Animation<double> promiseOpacity;
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
                      const _Wordmark(),
                      const SizedBox(height: 10),
                      _MotionIdentityLine(
                        animation: brandMotion,
                        travel: capsuleTravel,
                        reduceMotion: reduceMotion,
                      ),
                      const SizedBox(height: 10),
                      _MotionTagline(
                        animation: brandMotion,
                        scale: taglineScale,
                        reduceMotion: reduceMotion,
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: promiseOpacity,
                        child: const _ApprovedPromise(),
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
                      const _Wordmark(),
                      const SizedBox(height: 10),
                      const _StaticIdentityLine(
                        width: _SplashV2Tokens.trackWidth,
                        height: _SplashV2Tokens.trackHeight,
                      ),
                      const SizedBox(height: 10),
                      const _StaticTagline(),
                      const SizedBox(height: 10),
                      const _ApprovedPromise(),
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
            const SizedBox(height: 10),
            const _StaticIdentityLine(width: 126, height: 4),
            const SizedBox(height: 14),
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
    return const Text(
      'MoolSocial',
      style: TextStyle(
        color: _SplashV2Tokens.white,
        fontSize: 25,
        height: .95,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ApprovedPromise extends StatelessWidget {
  const _ApprovedPromise();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Create. Connect. Work. Grow.',
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            color: _SplashV2Tokens.white,
            fontSize: 15,
            height: 1.2,
            fontWeight: FontWeight.w900,
            letterSpacing: .15,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'One app for life and business.',
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            color: Color(0xE0FFFFFF),
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MotionIdentityLine extends StatelessWidget {
  const _MotionIdentityLine({
    required this.animation,
    required this.travel,
    required this.reduceMotion,
  });

  final Animation<double> animation;
  final Animation<double> travel;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return const _StaticIdentityLine(
        width: _SplashV2Tokens.trackWidth,
        height: _SplashV2Tokens.trackHeight,
      );
    }

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: _SplashV2Tokens.trackWidth,
          height: _SplashV2Tokens.trackHeight,
          color: _SplashV2Tokens.white.withValues(alpha: .18),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) => Transform.translate(
              offset: Offset(travel.value, 0),
              child: child,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                key: const Key('splash-v2-moving-tricolour'),
                width: _SplashV2Tokens.capsuleWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                    stops: [0, .36, .36, .62, .62, 1],
                    colors: [
                      _SplashV2Tokens.saffron,
                      _SplashV2Tokens.saffron,
                      _SplashV2Tokens.white,
                      _SplashV2Tokens.white,
                      _SplashV2Tokens.green,
                      _SplashV2Tokens.green,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _SplashV2Tokens.saffron.withValues(alpha: .65),
                      blurRadius: 12,
                    ),
                    BoxShadow(
                      color: _SplashV2Tokens.white.withValues(alpha: .5),
                      blurRadius: 18,
                    ),
                    BoxShadow(
                      color: _SplashV2Tokens.green.withValues(alpha: .65),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MotionTagline extends StatelessWidget {
  const _MotionTagline({
    required this.animation,
    required this.scale,
    required this.reduceMotion,
  });

  final Animation<double> animation;
  final Animation<double> scale;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = reduceMotion ? 0.0 : animation.value;
        return Transform.scale(
          scale: reduceMotion ? 1 : scale.value,
          child: Container(
            height: 30,
            constraints: const BoxConstraints(minWidth: 214),
            decoration: BoxDecoration(
              color: _SplashV2Tokens.white,
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  offset: Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!reduceMotion)
                  Positioned(
                    top: -16,
                    bottom: -16,
                    left: -120 + (334 * value),
                    width: 112,
                    child: Transform.rotate(
                      angle: -.28,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _SplashV2Tokens.saffron.withValues(alpha: .62),
                              _SplashV2Tokens.white.withValues(alpha: .92),
                              _SplashV2Tokens.green.withValues(alpha: .62),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'India Ka Socio Commerce App',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      color: _SplashV2Tokens.navy,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StaticIdentityLine extends StatelessWidget {
  const _StaticIdentityLine({
    required this.width,
    required this.height,
    super.key,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          width: width,
          height: height,
          child: const Row(
            children: [
              Expanded(
                flex: 45,
                child: SizedBox.expand(
                  child: ColoredBox(color: _SplashV2Tokens.saffron),
                ),
              ),
              Expanded(
                flex: 14,
                child: SizedBox.expand(
                  child: ColoredBox(color: _SplashV2Tokens.white),
                ),
              ),
              Expanded(
                flex: 41,
                child: SizedBox.expand(
                  child: ColoredBox(color: _SplashV2Tokens.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticTagline extends StatelessWidget {
  const _StaticTagline();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      constraints: const BoxConstraints(minWidth: 214),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _SplashV2Tokens.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: const Text(
        'India Ka Socio Commerce App',
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          color: _SplashV2Tokens.navy,
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
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
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 9,
                height: 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _SplashV2Tokens.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(
                    color: _SplashV2Tokens.white,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StaticIdentityLine(
            key: const Key('splash-v2-footer-line'),
            width: availableWidth,
            height: 5,
          ),
        ],
      ),
    );
  }
}
