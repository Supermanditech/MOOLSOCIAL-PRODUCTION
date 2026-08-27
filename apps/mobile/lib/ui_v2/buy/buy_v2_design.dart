import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/design/mool_motion_primitives.dart';
import '../../features/buy/buy_v2_content_contracts.dart';
import '../../features/buy/buy_v2_models.dart';

final NumberFormat _buyV2Currency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String buyV2Money(num value) => _buyV2Currency.format(value);

/// Converts the server-owned delivery fact into one compact buyer promise.
///
/// Google route duration is only one upstream input. This presentation helper
/// never calculates or guesses an ETA; it renders the complete promise already
/// supplied through [BuyV2ProductFactsSnapshot].
String buyV2BuyerDeliveryPromise(BuyV2ProductFactsSnapshot facts) {
  if (facts.stale) return 'Delivery time needs review';

  final orderability = facts.orderabilityLabel.trim().toLowerCase();
  if (orderability.contains('checking')) return 'Checking delivery time';
  if (orderability.contains('unavailable') ||
      orderability.contains('not available')) {
    return 'Currently unavailable';
  }

  return buyV2BuyerDeliveryPromiseSource(facts.deliveryPromise);
}

String buyV2BuyerDeliveryPromiseSource(String value) {
  final source = value.trim();
  if (source.toLowerCase().startsWith('delivered ')) return source;
  final minutes = RegExp(
    r'(\d+)\s*(?:min|minute)s?',
    caseSensitive: false,
  ).firstMatch(source);
  if (minutes != null) return 'Delivered in ${minutes.group(1)} min';
  final longerDuration = RegExp(
    r'(\d+)\s*(hour|day)s?',
    caseSensitive: false,
  ).firstMatch(source);
  if (longerDuration != null) {
    final amount = longerDuration.group(1)!;
    final unit = longerDuration.group(2)!.toLowerCase();
    return 'Delivered in $amount $unit${amount == '1' ? '' : 's'}';
  }
  return 'Delivery $source';
}

String buyV2DeliveryPromiseSummary({
  required String promise,
  String? promisedByLabel,
}) {
  final relative = buyV2BuyerDeliveryPromiseSource(promise);
  final deadline = promisedByLabel?.trim();
  return deadline == null || deadline.isEmpty
      ? relative
      : '$relative · $deadline';
}

String buyV2AutomaticFulfilmentLabel(BuyV2Destination destination) =>
    switch (destination) {
      BuyV2Destination.shop ||
      BuyV2Destination.wholesale => 'Automatically assigned Mool Partner',
      BuyV2Destination.medicine => 'Mool Pharmacy Partner',
      BuyV2Destination.orders => 'Mool Fulfilment Partner',
    };

const buyV2ProductOfferDecisionContractVersion =
    'buy-product-offer-decision-v1';

enum BuyV2ProductOfferDecisionState {
  ready,
  checking,
  stale,
  unavailable,
  changedPrice,
  missingFulfilment,
}

@immutable
class BuyV2ProductOfferDecision {
  const BuyV2ProductOfferDecision({
    required this.state,
    required this.statusLabel,
    required this.detail,
  });

  final BuyV2ProductOfferDecisionState state;
  final String statusLabel;
  final String detail;

  bool get canAdd => state == BuyV2ProductOfferDecisionState.ready;
}

BuyV2ProductOfferDecision buyV2ResolveProductOfferDecision({
  required BuyV2Product product,
  required BuyV2ProductFactsSnapshot facts,
}) {
  final orderability = facts.orderabilityLabel.trim().toLowerCase();
  final partner = facts.partner.trim().toLowerCase();
  final automaticFulfilment =
      product.destination == BuyV2Destination.shop ||
      product.destination == BuyV2Destination.wholesale;

  if (facts.stale) {
    return const BuyV2ProductOfferDecision(
      state: BuyV2ProductOfferDecisionState.stale,
      statusLabel: 'Offer needs review',
      detail:
          'Price, availability or delivery information may be out of date. Retry before adding to Cart.',
    );
  }
  if (orderability.contains('unavailable') ||
      orderability.contains('not available') ||
      orderability.contains('out of stock')) {
    return const BuyV2ProductOfferDecision(
      state: BuyV2ProductOfferDecisionState.unavailable,
      statusLabel: 'Currently unavailable',
      detail:
          'This product cannot be added to Cart right now. Retry or choose another product.',
    );
  }
  if (orderability.contains('checking') ||
      orderability.contains('loading') ||
      orderability.contains('pending review')) {
    return const BuyV2ProductOfferDecision(
      state: BuyV2ProductOfferDecisionState.checking,
      statusLabel: 'Checking availability',
      detail:
          'Current stock and delivery must be confirmed before adding to Cart.',
    );
  }
  if (facts.price != product.price) {
    return BuyV2ProductOfferDecision(
      state: BuyV2ProductOfferDecisionState.changedPrice,
      statusLabel: 'Price changed',
      detail:
          'The delivered price changed from ${buyV2Money(product.price)} to ${buyV2Money(facts.price)}. Retry or choose another product.',
    );
  }
  if (automaticFulfilment &&
      (facts.deliveryPromise.trim().isEmpty ||
          partner.isEmpty ||
          partner.contains('assignment pending') ||
          partner.contains('not assigned') ||
          partner.contains('missing'))) {
    return const BuyV2ProductOfferDecision(
      state: BuyV2ProductOfferDecisionState.missingFulfilment,
      statusLabel: 'Fulfilment unavailable',
      detail:
          'A delivery promise and automatic fulfilment path must be confirmed before adding to Cart.',
    );
  }
  return const BuyV2ProductOfferDecision(
    state: BuyV2ProductOfferDecisionState.ready,
    statusLabel: 'Ready to add',
    detail: 'Current price, stock and delivery are confirmed.',
  );
}

abstract final class BuyV2Colors {
  static const navy = Color(0xFF000080);
  static const royal = Color(0xFF1515B8);
  static const orange = Color(0xFFFF9933);
  static const green = Color(0xFF138808);
  static const ink = Color(0xFF11132F);
  static const muted = Color(0xFF626780);
  static const line = Color(0xFFE0E2EE);
  static const canvas = Color(0xFFF4F5FB);
  static const softOrange = Color(0xFFFFF0DE);
  static const softGreen = Color(0xFFEAF7E8);
  static const softBlue = Color(0xFFEDECFF);
}

abstract final class BuyV2Metrics {
  static const maxWidth = 520.0;
  static const railWidth = 94.0;
  static const dockHeight = 54.0;
  static const radius = 16.0;
  static const compactRadius = 12.0;
  static const minimumTap = 44.0;
}

abstract final class BuyV2Motion {
  static const press = Duration(milliseconds: 110);
  static const selection = Duration(milliseconds: 150);
  static const stateChange = Duration(milliseconds: 180);
  static const contentChange = Duration(milliseconds: 240);
  static const expandCollapse = Duration(milliseconds: 260);
  static const routeChange = Duration(milliseconds: 280);
  static const success = Duration(milliseconds: 360);
  static const recovery = Duration(milliseconds: 220);
  static const brandReveal = Duration(milliseconds: 420);
  static const pressScale = .985;

  static Duration resolved(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}

/// A truthful, finite progress owner for state supplied by the Buy session.
///
/// The first frame is always the current value. A transition is allowed only
/// when the same owner later receives a different real value; changing owners,
/// remounting, restoring or enabling reduced motion resolves immediately.
class BuyV2HonestProgressIndicator extends StatefulWidget {
  const BuyV2HonestProgressIndicator({
    super.key,
    required this.ownerId,
    required this.progress,
    required this.statusLabel,
    required this.backgroundColor,
    required this.valueColor,
    required this.minHeight,
    this.isComplete = false,
    this.indicatorKey,
  });

  final String ownerId;
  final double progress;
  final String statusLabel;
  final Color backgroundColor;
  final Color valueColor;
  final double minHeight;
  final bool isComplete;
  final Key? indicatorKey;

  @override
  State<BuyV2HonestProgressIndicator> createState() =>
      _BuyV2HonestProgressIndicatorState();
}

class _BuyV2HonestProgressIndicatorState
    extends State<BuyV2HonestProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  late String _ownerId;
  late double _target;
  bool _hasObservedRealChange = false;

  double _resolvedTarget(BuyV2HonestProgressIndicator source) {
    if (source.isComplete) return 1;
    final bounded = source.progress.clamp(0.0, 1.0).toDouble();
    return bounded >= 1 ? .999 : bounded;
  }

  @override
  void initState() {
    super.initState();
    _ownerId = widget.ownerId;
    _target = _resolvedTarget(widget);
    _controller = AnimationController(
      vsync: this,
      duration: BuyV2Motion.stateChange,
    );
    _animation = AlwaysStoppedAnimation<double>(_target);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _animation = AlwaysStoppedAnimation<double>(_target);
    }
  }

  @override
  void didUpdateWidget(covariant BuyV2HonestProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextTarget = _resolvedTarget(widget);
    if (_ownerId != widget.ownerId) {
      _controller.stop();
      _ownerId = widget.ownerId;
      _target = nextTarget;
      _animation = AlwaysStoppedAnimation<double>(_target);
      _hasObservedRealChange = false;
      return;
    }

    final statusChanged = oldWidget.statusLabel != widget.statusLabel;
    if (nextTarget == _target) {
      _hasObservedRealChange = _hasObservedRealChange || statusChanged;
      return;
    }

    _hasObservedRealChange = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _target = nextTarget;
      _animation = AlwaysStoppedAnimation<double>(_target);
      return;
    }

    final currentValue = _animation.value;
    _target = nextTarget;
    _animation = Tween<double>(begin: currentValue, end: _target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_target * 100).round();
    return Semantics(
      label: widget.statusLabel,
      value: '$percent% complete',
      liveRegion: _hasObservedRealChange,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => ExcludeSemantics(
          child: LinearProgressIndicator(
            key: widget.indicatorKey,
            value: _animation.value,
            minHeight: widget.minHeight,
            backgroundColor: widget.backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(widget.valueColor),
          ),
        ),
      ),
    );
  }
}

/// A fixed-owner finite transition for a real Buy value change.
///
/// The outgoing visual is excluded from semantics by the shared primitive, so
/// quantity and money updates expose only the current value while settling.
class BuyV2FiniteValueTransition extends StatelessWidget {
  const BuyV2FiniteValueTransition({
    super.key,
    required this.stateKey,
    required this.text,
    required this.ownerSize,
    required this.style,
    this.textAlign = TextAlign.center,
    this.maxLines = 1,
    this.duration = BuyV2Motion.stateChange,
  });

  final Object stateKey;
  final String text;
  final Size ownerSize;
  final TextStyle style;
  final TextAlign textAlign;
  final int maxLines;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final alignment = switch (textAlign) {
      TextAlign.left => Alignment.centerLeft,
      TextAlign.right => Alignment.centerRight,
      TextAlign.start => AlignmentDirectional.centerStart,
      TextAlign.end => AlignmentDirectional.centerEnd,
      TextAlign.center || TextAlign.justify => Alignment.center,
    };
    return MoolFiniteStateTransition(
      stateKey: stateKey,
      ownerSize: ownerSize,
      semanticLabel: text,
      alignment: alignment,
      duration: duration,
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

/// Finite visual replacement inside an existing semantic/hit owner.
class BuyV2FiniteVisualTransition extends StatelessWidget {
  const BuyV2FiniteVisualTransition({
    super.key,
    required this.stateKey,
    required this.ownerSize,
    required this.child,
    this.duration = BuyV2Motion.stateChange,
    this.alignment = Alignment.center,
  });

  final Object stateKey;
  final Size ownerSize;
  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return MoolFiniteStateTransition(
      stateKey: stateKey,
      ownerSize: ownerSize,
      duration: duration,
      alignment: alignment,
      child: child,
    );
  }
}

/// One finite incoming visual for content whose geometry remains owned by its
/// current child. Unlike a switcher, this never retains an outgoing semantic
/// copy while a coupon/offer context is replaced.
class BuyV2FiniteIncomingTransition extends StatelessWidget {
  const BuyV2FiniteIncomingTransition({
    super.key,
    required this.stateKey,
    required this.child,
    this.duration = BuyV2Motion.contentChange,
  });

  final Object stateKey;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey<Object>(stateKey),
      tween: Tween<double>(begin: reduced ? 1 : .72, end: 1),
      duration: BuyV2Motion.resolved(context, duration),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 4),
          child: child,
        ),
      ),
    );
  }
}

/// One finite spatial reveal for truthful product media entering its existing
/// layout owner. This does not retain an outgoing image or alter hit testing.
class BuyV2FiniteDepthReveal extends StatelessWidget {
  const BuyV2FiniteDepthReveal({
    super.key,
    required this.stateKey,
    required this.child,
    this.duration = BuyV2Motion.contentChange,
  });

  final Object stateKey;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey<Object>(stateKey),
      tween: Tween<double>(begin: reduced ? 1 : .76, end: 1),
      duration: BuyV2Motion.resolved(context, duration),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        final remaining = 1 - value;
        final transform = Matrix4.translationValues(0, remaining * 5, 0)
          ..setEntry(3, 2, .001)
          ..rotateY(remaining * .035);
        return Opacity(
          opacity: value,
          child: Transform(
            alignment: Alignment.center,
            transform: transform,
            transformHitTests: false,
            child: child,
          ),
        );
      },
    );
  }
}

@immutable
class BuyV2ThemeSpec {
  const BuyV2ThemeSpec({
    required this.accent,
    required this.softAccent,
    required this.canvas,
    required this.headerStart,
    required this.headerEnd,
    required this.headerForeground,
    required this.headerAccent,
    required this.headerGradient,
    required this.canvasGradient,
  });

  final Color accent;
  final Color softAccent;
  final Color canvas;
  final Color headerStart;
  final Color headerEnd;
  final Color headerForeground;
  final Color headerAccent;
  final MoolBrandGradient headerGradient;
  final MoolBrandGradient canvasGradient;

  static BuyV2ThemeSpec resolve(BuyV2Destination destination, BuyV2View view) {
    final vertical = switch (destination) {
      BuyV2Destination.shop => const BuyV2ThemeSpec(
        accent: BuyV2Colors.orange,
        softAccent: Color(0x1AFF9933),
        canvas: Colors.white,
        headerStart: BuyV2Colors.navy,
        headerEnd: BuyV2Colors.orange,
        headerForeground: Colors.white,
        headerAccent: BuyV2Colors.navy,
        headerGradient: MoolBrandGradient.saffron,
        canvasGradient: MoolBrandGradient.saffron,
      ),
      BuyV2Destination.wholesale => const BuyV2ThemeSpec(
        accent: BuyV2Colors.green,
        softAccent: Color(0x1A138808),
        canvas: Colors.white,
        headerStart: BuyV2Colors.navy,
        headerEnd: BuyV2Colors.green,
        headerForeground: Colors.white,
        headerAccent: BuyV2Colors.orange,
        headerGradient: MoolBrandGradient.green,
        canvasGradient: MoolBrandGradient.green,
      ),
      BuyV2Destination.medicine => const BuyV2ThemeSpec(
        accent: BuyV2Colors.navy,
        softAccent: Color(0x14000080),
        canvas: Colors.white,
        headerStart: BuyV2Colors.green,
        headerEnd: BuyV2Colors.navy,
        headerForeground: BuyV2Colors.navy,
        headerAccent: BuyV2Colors.navy,
        headerGradient: MoolBrandGradient.tricolour,
        canvasGradient: MoolBrandGradient.navy,
      ),
      BuyV2Destination.orders => const BuyV2ThemeSpec(
        accent: BuyV2Colors.navy,
        softAccent: Color(0x14000080),
        canvas: Colors.white,
        headerStart: BuyV2Colors.navy,
        headerEnd: BuyV2Colors.navy,
        headerForeground: Colors.white,
        headerAccent: BuyV2Colors.orange,
        headerGradient: MoolBrandGradient.navy,
        canvasGradient: MoolBrandGradient.tricolour,
      ),
    };
    return switch (view) {
      BuyV2View.cart ||
      BuyV2View.checkout ||
      BuyV2View.confirmation => BuyV2ThemeSpec(
        accent: BuyV2Colors.orange,
        softAccent: const Color(0x1AFF9933),
        canvas: Colors.white,
        headerStart: vertical.headerStart,
        headerEnd: BuyV2Colors.orange,
        headerForeground: Colors.white,
        headerAccent: BuyV2Colors.navy,
        headerGradient: MoolBrandGradient.saffron,
        canvasGradient: MoolBrandGradient.saffron,
      ),
      BuyV2View.tracking || BuyV2View.orderItems => BuyV2ThemeSpec(
        accent: BuyV2Colors.green,
        softAccent: const Color(0x1A138808),
        canvas: Colors.white,
        headerStart: vertical.headerStart,
        headerEnd: BuyV2Colors.green,
        headerForeground: Colors.white,
        headerAccent: BuyV2Colors.orange,
        headerGradient: MoolBrandGradient.green,
        canvasGradient: MoolBrandGradient.green,
      ),
      BuyV2View.account || BuyV2View.assist => BuyV2ThemeSpec(
        accent: BuyV2Colors.navy,
        softAccent: const Color(0x14000080),
        canvas: Colors.white,
        headerStart: BuyV2Colors.navy,
        headerEnd: BuyV2Colors.navy,
        headerForeground: Colors.white,
        headerAccent: BuyV2Colors.orange,
        headerGradient: MoolBrandGradient.navy,
        canvasGradient: MoolBrandGradient.navy,
      ),
      BuyV2View.catalogue ||
      BuyV2View.product ||
      BuyV2View.recovery => vertical,
    };
  }
}

class BuyV2ThemeScope extends InheritedWidget {
  const BuyV2ThemeScope({super.key, required this.spec, required super.child});

  final BuyV2ThemeSpec spec;

  static BuyV2ThemeSpec of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<BuyV2ThemeScope>()
            ?.spec ??
        BuyV2ThemeSpec.resolve(BuyV2Destination.shop, BuyV2View.catalogue);
  }

  @override
  bool updateShouldNotify(BuyV2ThemeScope oldWidget) => spec != oldWidget.spec;
}

class BuyV2IntentDepth extends StatefulWidget {
  const BuyV2IntentDepth({
    super.key,
    required this.child,
    this.enabled = true,
    this.spatial = false,
  });

  final Widget child;
  final bool enabled;
  final bool spatial;

  @override
  State<BuyV2IntentDepth> createState() => _BuyV2IntentDepthState();
}

class _BuyV2IntentDepthState extends State<BuyV2IntentDepth> {
  bool _pressed = false;
  double _tiltX = .008;
  double _tiltY = 0;

  void _setPressed(bool value, [Offset? localPosition]) {
    if (!mounted || _pressed == value) return;
    setState(() {
      _pressed = value;
      if (value && widget.spatial && localPosition != null) {
        final size = context.size;
        if (size != null && size.width > 0 && size.height > 0) {
          final horizontal = (localPosition.dx / size.width).clamp(0.0, 1.0);
          final vertical = (localPosition.dy / size.height).clamp(0.0, 1.0);
          _tiltX = (.5 - vertical) * .022;
          _tiltY = (horizontal - .5) * .032;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final enabled = widget.enabled && !reduceMotion;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: enabled
          ? (event) => _setPressed(true, event.localPosition)
          : null,
      onPointerUp: enabled ? (_) => _setPressed(false) : null,
      onPointerCancel: enabled ? (_) => _setPressed(false) : null,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: enabled && _pressed ? 1 : 0),
        duration: BuyV2Motion.resolved(context, BuyV2Motion.press),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          if (!widget.spatial) {
            final transform = Matrix4.translationValues(0, value * .8, 0)
              ..setEntry(3, 2, value * .0007)
              ..rotateX(value * .008);
            return Transform(
              key: const ValueKey('buy-intent-depth-transform'),
              alignment: Alignment.center,
              transform: transform,
              transformHitTests: false,
              child: child,
            );
          }
          final contentTransform = Matrix4.translationValues(0, value * .8, 0);
          final planeTransform = Matrix4.identity()
            ..setEntry(3, 2, value * .0011)
            ..rotateX(value * _tiltX)
            ..rotateY(value * _tiltY);
          final sheenDirection = Alignment(
            (_tiltY * 28).clamp(-1.0, 1.0),
            (_tiltX * 36).clamp(-1.0, 1.0),
          );
          return Transform.scale(
            key: const ValueKey('buy-intent-depth-scale'),
            scale: 1 - value * .007,
            transformHitTests: false,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Transform(
                  key: const ValueKey('buy-intent-depth-transform'),
                  alignment: Alignment.center,
                  transform: contentTransform,
                  transformHitTests: false,
                  child: child,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: Transform(
                        key: const ValueKey('buy-intent-depth-plane'),
                        alignment: Alignment.center,
                        transform: planeTransform,
                        transformHitTests: false,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: BuyV2Colors.navy.withValues(alpha: .14),
                            ),
                            gradient: LinearGradient(
                              begin: sheenDirection,
                              end: Alignment(
                                -sheenDirection.x,
                                -sheenDirection.y,
                              ),
                              colors: [
                                BuyV2Colors.navy.withValues(alpha: 0),
                                Colors.white.withValues(alpha: .12),
                                BuyV2Colors.orange.withValues(alpha: .08),
                                BuyV2Colors.green.withValues(alpha: .06),
                              ],
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
        },
        child: widget.child,
      ),
    );
  }
}

class BuyV2TricolourLine extends StatelessWidget {
  const BuyV2TricolourLine({super.key, this.height = 3});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Row(
        children: [
          Expanded(child: ColoredBox(color: BuyV2Colors.orange)),
          Expanded(child: ColoredBox(color: Colors.white)),
          Expanded(child: ColoredBox(color: BuyV2Colors.green)),
        ],
      ),
    );
  }
}

enum BuyV2ProductMediaKind { exactProduct, category }

@immutable
class BuyV2ProductMediaSource {
  const BuyV2ProductMediaSource({
    required this.assetPath,
    required this.cell,
    required this.kind,
  });

  final String assetPath;
  final int cell;
  final BuyV2ProductMediaKind kind;
}

class BuyV2ProductPackshot extends StatelessWidget {
  const BuyV2ProductPackshot({
    super.key,
    required this.product,
    this.borderRadius = 14,
    this.animateFirstFrame = false,
  });

  static const productAtlasPath =
      'assets/prototype/moolsocial-product-packshot-atlas-v2-2026.png';
  static const categoryAtlasAPath =
      'assets/prototype/moolsocial-category-media-atlas-v3a-2026.png';
  static const categoryAtlasBPath =
      'assets/prototype/moolsocial-category-media-atlas-v3b-2026.png';
  static const categoryAtlasCPath =
      'assets/prototype/moolsocial-category-media-atlas-v3c-2026.png';
  static const medicineAtlasPath =
      'assets/prototype/moolsocial-medicine-media-atlas-v3d-2026.png';

  final BuyV2Product product;
  final double borderRadius;
  final bool animateFirstFrame;

  @override
  Widget build(BuildContext context) {
    final source = resolveMedia(product);
    if (source == null) {
      return Semantics(
        image: true,
        label: 'Category visual for ${product.title}',
        child: _BuyV2ProductMediaFallback(
          key: ValueKey('buy-product-media-fallback-${product.id}'),
          product: product,
          borderRadius: borderRadius,
        ),
      );
    }
    final cell = source.cell;
    final column = cell % 4;
    final row = cell ~/ 4;
    return Semantics(
      image: true,
      label: source.kind == BuyV2ProductMediaKind.exactProduct
          ? 'Product photo of ${product.title}'
          : 'Category photo for ${product.title}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ColoredBox(
          color: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth;
              final cellHeight = constraints.maxHeight;
              return Transform.scale(
                scale: 1.04,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: _BuyV2ProductMediaFallback(
                          product: product,
                          borderRadius: borderRadius,
                        ),
                      ),
                    ),
                    Positioned(
                      key: ValueKey(
                        'buy-packshot-sprite-${product.id}-'
                        '${source.assetPath}-$cell',
                      ),
                      left: -column * cellWidth,
                      top: -row * cellHeight,
                      width: cellWidth * 4,
                      height: cellHeight * 3,
                      child: Image.asset(
                        source.assetPath,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                        frameBuilder: animateFirstFrame
                            ? (context, child, frame, synchronouslyLoaded) {
                                if (synchronouslyLoaded) {
                                  return child;
                                }
                                return AnimatedOpacity(
                                  key: ValueKey(
                                    'buy-packshot-decoded-frame-${product.id}',
                                  ),
                                  opacity: frame == null ? 0 : 1,
                                  duration: BuyV2Motion.resolved(
                                    context,
                                    const Duration(milliseconds: 180),
                                  ),
                                  curve: Curves.easeOutCubic,
                                  child: child,
                                );
                              }
                            : null,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: BuyV2Colors.navy,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static BuyV2ProductMediaSource? resolveMedia(BuyV2Product product) {
    final medicineCell = switch (product.id) {
      'm-paracetamol-500' => 0,
      'm-pain-relief-gel' => 1,
      'm-metformin-500' => 2,
      'm-glucose-strips' => 3,
      'm-telmisartan-40' => 4,
      'm-atorvastatin-10' => 5,
      'm-pantoprazole-40' => 6,
      'm-ors' => 7,
      _ => null,
    };
    if (medicineCell != null) {
      return BuyV2ProductMediaSource(
        assetPath: medicineAtlasPath,
        cell: medicineCell,
        kind: BuyV2ProductMediaKind.exactProduct,
      );
    }

    final canonicalId = product.canonicalId.toLowerCase();
    final exactProductCell = switch (canonicalId) {
      'tomato' => 0,
      'rice' => 1,
      'atta' => 2,
      'oil' => 3,
      'soap' => 4,
      'notebook' => 5,
      'milk' => 6,
      'bread' => 7,
      'water' => 11,
      _ => null,
    };
    if (exactProductCell != null) {
      return BuyV2ProductMediaSource(
        assetPath: productAtlasPath,
        cell: exactProductCell,
        kind: BuyV2ProductMediaKind.exactProduct,
      );
    }

    final categoryId = product.categoryId.toLowerCase();
    final categorySource = switch (categoryId) {
      'fruits-vegetables' => (categoryAtlasAPath, 0),
      'dairy-bakery' => (categoryAtlasAPath, 1),
      'eggs-poultry' => (categoryAtlasAPath, 2),
      'meat-seafood' => (categoryAtlasAPath, 3),
      'flour-rice-grains' || 'dals-staples' => (categoryAtlasAPath, 4),
      'oils-ghee' => (categoryAtlasAPath, 5),
      'ground-spices' => (categoryAtlasAPath, 6),
      'whole-spices' => (categoryAtlasAPath, 7),
      'breakfast-cereals' => (categoryAtlasAPath, 8),
      'instant-foods' => (categoryAtlasAPath, 9),
      'biscuits-chocolate' => (categoryAtlasAPath, 10),
      'namkeen-chips' => (categoryAtlasAPath, 11),
      'tea-coffee' => (categoryAtlasBPath, 0),
      'juices-water' => (categoryAtlasBPath, 1),
      'frozen-foods' => (categoryAtlasBPath, 2),
      'icecream-cheese' => (categoryAtlasBPath, 3),
      'oral-care' => (categoryAtlasBPath, 4),
      'bath-hand-care' => (categoryAtlasBPath, 5),
      'hair-care' => (categoryAtlasBPath, 6),
      'skin-care' => (categoryAtlasBPath, 7),
      'surface-cleaners' => (categoryAtlasBPath, 8),
      'laundry-dishwash' => (categoryAtlasBPath, 9),
      'air-waste-care' => (categoryAtlasBPath, 10),
      'diapers-wipes' => (categoryAtlasBPath, 11),
      'baby-care' => (categoryAtlasCPath, 0),
      'health-wellness' => (categoryAtlasCPath, 1),
      'dog-care' => (categoryAtlasCPath, 2),
      'cat-care' => (categoryAtlasCPath, 3),
      'food-storage-packs' || 'horeca-food-packs' => (categoryAtlasCPath, 4),
      'cups-tissues' || 'horeca-tableware' => (categoryAtlasCPath, 5),
      'shop-supplies' || 'retail-supplies' => (categoryAtlasCPath, 6),
      'school-office' || 'stationery-office' => (categoryAtlasCPath, 7),
      'sauces-spreads' => (categoryAtlasCPath, 8),
      _ => null,
    };
    if (categorySource != null) {
      return BuyV2ProductMediaSource(
        assetPath: categorySource.$1,
        cell: categorySource.$2,
        kind: BuyV2ProductMediaKind.category,
      );
    }
    return null;
  }
}

class _BuyV2ProductMediaFallback extends StatelessWidget {
  const _BuyV2ProductMediaFallback({
    super.key,
    required this.product,
    required this.borderRadius,
  });

  final BuyV2Product product;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortest = constraints.biggest.shortestSide;
            final iconSize = (shortest * .38).clamp(20.0, 46.0);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _fallbackIcon(product.categoryId),
                    size: iconSize,
                    color: BuyV2Colors.navy,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.visualLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BuyV2Colors.muted,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _fallbackIcon(String categoryId) {
    final category = categoryId.toLowerCase();
    if (category.contains('egg') || category.contains('poultry')) {
      return Icons.egg_alt_outlined;
    }
    if (category.contains('meat') || category.contains('seafood')) {
      return Icons.restaurant_outlined;
    }
    if (category.contains('spice') ||
        category.contains('grain') ||
        category.contains('staple')) {
      return Icons.grain_rounded;
    }
    if (category.contains('breakfast') || category.contains('instant')) {
      return Icons.breakfast_dining_outlined;
    }
    if (category.contains('biscuit') ||
        category.contains('chocolate') ||
        category.contains('namkeen') ||
        category.contains('chip')) {
      return Icons.cookie_outlined;
    }
    if (category.contains('tea') ||
        category.contains('coffee') ||
        category.contains('juice')) {
      return Icons.local_cafe_outlined;
    }
    if (category.contains('frozen') ||
        category.contains('icecream') ||
        category.contains('cheese')) {
      return Icons.ac_unit_rounded;
    }
    if (category.contains('care') ||
        category.contains('wash') ||
        category.contains('clean') ||
        category.contains('laundry')) {
      return Icons.spa_outlined;
    }
    if (category.contains('baby') ||
        category.contains('diaper') ||
        category.contains('wipe')) {
      return Icons.child_care_outlined;
    }
    if (category.contains('dog') || category.contains('cat')) {
      return Icons.pets_outlined;
    }
    if (category.contains('paper') ||
        category.contains('school') ||
        category.contains('stationery') ||
        category.contains('suppl')) {
      return Icons.inventory_2_outlined;
    }
    if (category.contains('health') ||
        category.contains('wellness') ||
        product.destination == BuyV2Destination.medicine) {
      return Icons.health_and_safety_outlined;
    }
    return Icons.inventory_2_outlined;
  }
}

BoxDecoration buyV2CardDecoration({
  Color color = Colors.white,
  Color border = BuyV2Colors.line,
  double radius = BuyV2Metrics.radius,
  bool shadow = false,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border),
    boxShadow: shadow
        ? const [
            BoxShadow(
              color: Color(0x13000040),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ]
        : null,
  );
}

class BuyV2PromotionCard extends StatefulWidget {
  const BuyV2PromotionCard({
    super.key,
    required this.title,
    required this.detail,
    required this.icon,
    required this.onTap,
    this.accent = BuyV2Colors.orange,
    this.width = 220,
    this.sequenceIndex = 0,
  });

  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  final double width;
  final int sequenceIndex;

  @override
  State<BuyV2PromotionCard> createState() => _BuyV2PromotionCardState();
}

class _BuyV2PromotionCardState extends State<BuyV2PromotionCard>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _acknowledgementController;
  bool _entryStarted = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _acknowledgementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _entryController.value = 1;
      _acknowledgementController.value = 0;
    } else if (!_entryStarted) {
      _entryStarted = true;
      _entryController.forward();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _acknowledgementController.dispose();
    super.dispose();
  }

  void _dispatchAction() {
    if (!MediaQuery.disableAnimationsOf(context)) {
      _acknowledgementController.forward(from: 0);
    }
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = BuyV2ThemeScope.of(context);
    final entryBegin = (widget.sequenceIndex.clamp(0, 3) * .12).toDouble();
    final entry = CurvedAnimation(
      parent: _entryController,
      curve: Interval(entryBegin, 1, curve: Curves.easeOutCubic),
    );
    final acknowledgement = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 58,
      ),
    ]).animate(_acknowledgementController);
    return Semantics(
      label: '${widget.title}. ${widget.detail}',
      button: true,
      onTap: _dispatchAction,
      child: AnimatedBuilder(
        animation: Listenable.merge([entry, acknowledgement]),
        builder: (context, child) {
          final entryValue = entry.value;
          final acknowledgementValue = acknowledgement.value;
          return Opacity(
            opacity: entryValue.clamp(.001, 1),
            child: Transform.translate(
              key: const ValueKey('buy-promotion-entry-transform'),
              offset: Offset(0, 7 * (1 - entryValue)),
              transformHitTests: false,
              child: Transform.scale(
                scale: .985 + (.015 * entryValue),
                transformHitTests: false,
                child: BuyV2IntentDepth(
                  child: SizedBox(
                    width: widget.width,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _dispatchAction,
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.accent.withValues(alpha: .15),
                                Colors.white,
                                BuyV2Colors.softGreen.withValues(alpha: .72),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: BuyV2Colors.line),
                          ),
                          child: Row(
                            children: [
                              Transform.rotate(
                                angle: acknowledgementValue * -.07,
                                child: Transform.scale(
                                  key: const ValueKey(
                                    'buy-promotion-action-icon',
                                  ),
                                  scale: 1 + acknowledgementValue * .08,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: widget.accent.withValues(
                                          alpha: .4,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      widget.icon,
                                      color: theme.headerEnd,
                                      size: 21,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: BuyV2Colors.ink,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.detail,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: BuyV2Colors.muted,
                                        fontSize: 8,
                                        height: 1.15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Transform.translate(
                                key: const ValueKey(
                                  'buy-promotion-action-arrow',
                                ),
                                offset: Offset(acknowledgementValue * 3.5, 0),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: widget.accent,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BuyV2SponsoredSlot extends StatelessWidget {
  const BuyV2SponsoredSlot({super.key, required this.content});

  final BuyV2SponsoredContent? content;

  @override
  Widget build(BuildContext context) {
    final content = this.content;
    if (content == null) {
      return const SizedBox.shrink();
    }
    final video = content.format == BuyV2SponsoredFormat.inlineVideo;
    return Semantics(
      key: ValueKey('buy-sponsored-${content.id}'),
      container: true,
      label:
          '${content.disclosure}. ${content.title}. ${content.detail}'
          '${video ? '. Video is paused.' : ''}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        margin: const EdgeInsets.fromLTRB(8, 5, 8, 5),
        padding: const EdgeInsets.all(9),
        decoration: buyV2CardDecoration(
          color: const Color(0xFFF8F8FB),
          border: const Color(0x33000080),
          radius: 15,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BuyV2Colors.softBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                video ? Icons.play_circle_outline_rounded : Icons.campaign,
                color: BuyV2Colors.navy,
                size: 24,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.disclosure,
                    style: context.buyEyebrow.copyWith(fontSize: 8),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    content.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.buyBody.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    content.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.buyMeta.copyWith(fontSize: 8),
                  ),
                ],
              ),
            ),
            if (video)
              const Tooltip(
                message: 'Video playback unavailable',
                child: Icon(
                  Icons.pause_circle_outline_rounded,
                  color: BuyV2Colors.muted,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension BuyV2TextStyles on BuildContext {
  TextStyle get buyEyebrow => const TextStyle(
    color: BuyV2Colors.muted,
    fontSize: 10,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: .55,
  );

  TextStyle get buyTitle => const TextStyle(
    color: BuyV2Colors.ink,
    fontSize: 22,
    height: 1.08,
    fontWeight: FontWeight.w900,
    letterSpacing: -.5,
  );

  TextStyle get buyBody => const TextStyle(
    color: BuyV2Colors.ink,
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  TextStyle get buyMeta => const TextStyle(
    color: BuyV2Colors.muted,
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
}
