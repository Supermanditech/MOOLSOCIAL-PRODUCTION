import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../buy/buy_v2_design.dart';

class MoolBuyTapAcknowledgement extends StatefulWidget {
  const MoolBuyTapAcknowledgement({
    super.key,
    this.routeInformation,
    this.isBuyActive,
    this.routeChanges,
    required this.child,
  }) : assert(routeInformation != null || isBuyActive != null);

  final ValueListenable<RouteInformation>? routeInformation;
  final bool Function()? isBuyActive;
  final Listenable? routeChanges;
  final Widget child;

  @override
  State<MoolBuyTapAcknowledgement> createState() =>
      _MoolBuyTapAcknowledgementState();
}

class _MoolBuyTapAcknowledgementState extends State<MoolBuyTapAcknowledgement> {
  static const _diameter = 28.0;

  int? _activePointer;
  Offset _contact = const Offset(-_diameter, -_diameter);
  Offset? _origin;
  bool _pressed = false;

  Listenable get _routeListenable =>
      widget.routeChanges ?? widget.routeInformation!;

  bool get _isBuyRoute =>
      widget.isBuyActive?.call() ??
      widget.routeInformation!.value.uri.path.startsWith('/app/buy');

  @override
  void initState() {
    super.initState();
    _routeListenable.addListener(_handleRouteChange);
  }

  @override
  void didUpdateWidget(MoolBuyTapAcknowledgement oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldListenable = oldWidget.routeChanges ?? oldWidget.routeInformation!;
    if (oldListenable == _routeListenable) return;
    oldListenable.removeListener(_handleRouteChange);
    _routeListenable.addListener(_handleRouteChange);
    _handleRouteChange();
  }

  @override
  void dispose() {
    _routeListenable.removeListener(_handleRouteChange);
    super.dispose();
  }

  void _handleRouteChange() {
    if (_isBuyRoute || _activePointer == null) return;
    setState(_clearContact);
  }

  void _clearContact() {
    _activePointer = null;
    _origin = null;
    _pressed = false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_isBuyRoute || _activePointer != null) return;
    setState(() {
      _activePointer = event.pointer;
      _origin = event.localPosition;
      _contact = event.localPosition;
      _pressed = true;
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _origin == null) return;
    if ((event.localPosition - _origin!).distance <= kTouchSlop) return;
    setState(_clearContact);
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    setState(_clearContact);
  }

  @override
  Widget build(BuildContext context) {
    final duration = BuyV2Motion.resolved(context, BuyV2Motion.press);
    return Listener(
      key: const ValueKey('mool-buy-tap-acknowledgement'),
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned(
            left: _contact.dx - (_diameter / 2),
            top: _contact.dy - (_diameter / 2),
            width: _diameter,
            height: _diameter,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedOpacity(
                  key: const ValueKey('mool-buy-tap-visual'),
                  opacity: _isBuyRoute && _pressed ? .92 : 0,
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    key: const ValueKey('mool-buy-tap-scale'),
                    scale: _pressed ? 1 : 1.22,
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    child: const RepaintBoundary(
                      child: CustomPaint(
                        key: ValueKey('mool-buy-tap-ring'),
                        painter: _MoolTapRingPainter(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoolTapRingPainter extends CustomPainter {
  const _MoolTapRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - 3;
    final bounds = Rect.fromCircle(center: centre, radius: radius);
    final underlay = Paint()
      ..color = BuyV2Colors.navy.withValues(alpha: .34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centre, radius, underlay);

    const gap = .11;
    final sweep = ((math.pi * 2) / 3) - gap;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final (index, color) in <Color>[
      BuyV2Colors.orange,
      Colors.white,
      BuyV2Colors.green,
    ].indexed) {
      arc.color = color;
      canvas.drawArc(
        bounds,
        (-math.pi / 2) + (index * ((math.pi * 2) / 3)) + (gap / 2),
        sweep,
        false,
        arc,
      );
    }

    canvas.drawCircle(
      centre,
      1.5,
      Paint()..color = BuyV2Colors.navy.withValues(alpha: .8),
    );
  }

  @override
  bool shouldRepaint(_MoolTapRingPainter oldDelegate) => false;
}
