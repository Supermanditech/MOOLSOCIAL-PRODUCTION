import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_motion_primitives.dart';
import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
import '../universal/mool_global_navigation_v2.dart';
import 'buy_v2_catalogue.dart';
import 'buy_v2_design.dart';
import 'buy_v2_scanner.dart';
import 'buy_v2_views.dart';

class BuyV2Screen extends StatefulWidget {
  const BuyV2Screen({
    super.key,
    required this.session,
    this.initialDestination = BuyV2Destination.shop,
    this.initialView = BuyV2View.catalogue,
    this.initialCartScope = BuyV2CartScope.all,
    this.productId,
    this.orderId,
    this.recoveryKind,
    this.scannerLauncher = showBuyV2ProductScanner,
    this.onExit,
    this.onOpenMool,
    this.onOpenMainAction,
    this.onOpenChat,
    this.onDestinationChanged,
  });

  final BuyV2Session session;
  final BuyV2Destination initialDestination;
  final BuyV2View initialView;
  final BuyV2CartScope initialCartScope;
  final String? productId;
  final String? orderId;
  final BuyV2RecoveryKind? recoveryKind;
  final BuyV2ScannerLauncher scannerLauncher;
  final VoidCallback? onExit;
  final VoidCallback? onOpenMool;
  final ValueChanged<PersonalMoolActionSpec>? onOpenMainAction;
  final VoidCallback? onOpenChat;
  final ValueChanged<BuyV2Destination>? onDestinationChanged;

  @override
  State<BuyV2Screen> createState() => _BuyV2ScreenState();
}

class _BuyV2ScreenState extends State<BuyV2Screen> {
  Timer? _noticeTimer;
  Timer? _cartAcknowledgementTimer;
  bool _scannerBusy = false;
  bool _searchOpen = false;
  final BuyV2CheckoutBillingController _checkoutBilling =
      BuyV2CheckoutBillingController();
  late BuyV2Destination _lastSearchDestination;
  late final TextEditingController _searchController = TextEditingController(
    text: widget.session.query,
  );

  @override
  void initState() {
    super.initState();
    _applyInitialState();
    unawaited(widget.session.restoreSavedProducts());
    _lastSearchDestination = widget.session.destination;
    widget.session.addListener(_sessionChanged);
  }

  @override
  void didUpdateWidget(covariant BuyV2Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_sessionChanged);
      widget.session.addListener(_sessionChanged);
      unawaited(widget.session.restoreSavedProducts());
    }
    if (oldWidget.initialDestination != widget.initialDestination ||
        oldWidget.initialView != widget.initialView ||
        oldWidget.initialCartScope != widget.initialCartScope ||
        oldWidget.productId != widget.productId ||
        oldWidget.orderId != widget.orderId ||
        oldWidget.recoveryKind != widget.recoveryKind) {
      _applyInitialState();
    }
  }

  void _applyInitialState() {
    final productId = widget.productId;
    final orderId = widget.orderId;
    final recoveryKind = widget.recoveryKind;
    if (recoveryKind != null) {
      widget.session.openRecovery(recoveryKind);
    } else if (productId != null) {
      widget.session.openProduct(productId);
    } else if (orderId != null && widget.initialView == BuyV2View.tracking) {
      widget.session.openTracking(orderId);
    } else if (widget.initialView == BuyV2View.cart) {
      widget.session.destination = widget.initialDestination;
      final cartScope = widget.initialCartScope == BuyV2CartScope.all
          ? switch (widget.initialDestination) {
              BuyV2Destination.shop => BuyV2CartScope.shop,
              BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
              BuyV2Destination.medicine => BuyV2CartScope.medicine,
              BuyV2Destination.orders => BuyV2CartScope.shop,
            }
          : widget.initialCartScope;
      widget.session.openCart(scope: cartScope);
    } else if (widget.initialView == BuyV2View.checkout) {
      widget.session.destination = widget.initialDestination;
      widget.session.openCheckout();
    } else {
      widget.session.destination = widget.initialDestination;
      widget.session.view = widget.initialView;
    }
  }

  void _sessionChanged() {
    if (!mounted) return;
    final destinationChanged =
        _lastSearchDestination != widget.session.destination;
    if (destinationChanged) {
      _lastSearchDestination = widget.session.destination;
      widget.onDestinationChanged?.call(widget.session.destination);
    }
    if (destinationChanged || widget.session.view != BuyV2View.catalogue) {
      _searchOpen = false;
    }
    if (_searchController.text != widget.session.query) {
      _searchController.value = TextEditingValue(
        text: widget.session.query,
        selection: TextSelection.collapsed(offset: widget.session.query.length),
      );
    }
    _noticeTimer?.cancel();
    if (widget.session.notice != null) {
      _noticeTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) widget.session.clearNotice();
      });
    }
    _cartAcknowledgementTimer?.cancel();
    if (widget.session.cartAcknowledgement != null) {
      _cartAcknowledgementTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) widget.session.clearCartAcknowledgement();
      });
    }
    setState(() {});
  }

  Future<void> _scanProduct() async {
    if (_scannerBusy) return;
    setState(() => _scannerBusy = true);
    try {
      final scanned = await widget.scannerLauncher(context);
      if (!mounted || scanned == null || scanned.trim().isEmpty) return;

      final code = scanned.trim();
      widget.session.updateQuery(code);
      final matches = widget.session.visibleProducts;
      if (matches.length == 1) {
        widget.session.openProduct(matches.single.id);
      } else if (matches.isEmpty) {
        widget.session.showNotice(
          'No product matched that code. Check the code or search by name.',
        );
      } else {
        widget.session.showNotice('${matches.length} matching products found.');
      }
    } finally {
      if (mounted) setState(() => _scannerBusy = false);
    }
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _cartAcknowledgementTimer?.cancel();
    widget.session.removeListener(_sessionChanged);
    _searchController.dispose();
    _checkoutBilling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final careNavigation =
        session.activeDockDestination == BuyV2Destination.medicine;
    final surfaceTheme = BuyV2ThemeSpec.resolve(
      session.destination,
      session.view,
    );
    return BuyV2ThemeScope(
      spec: surfaceTheme,
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            HapticFeedback.selectionClick();
            if (_searchOpen) {
              FocusScope.of(context).unfocus();
              setState(() => _searchOpen = false);
            } else if (session.canHandleBack) {
              session.goBack();
            } else if (widget.onExit case final onExit?) {
              onExit();
            } else {
              context.go('/app/mool?from=buy');
            }
          }
        },
        child: Scaffold(
          key: const ValueKey('buy-v2-screen'),
          extendBody: true,
          backgroundColor: Colors.white,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: surfaceTheme.canvasGradient.colors,
              ),
            ),
            child: SafeArea(
              bottom: true,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: BuyV2Metrics.maxWidth,
                  ),
                  child: MoolFiniteGradientTransition(
                    key: const ValueKey('buy-theme-canvas'),
                    gradient: surfaceTheme.canvasGradient,
                    duration: BuyV2Motion.contentChange,
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: .94),
                      child: Column(
                        children: [
                          RepaintBoundary(
                            key: ValueKey(
                              'buy-header-boundary-${session.destination.name}-'
                              '${session.view.name}',
                            ),
                            child: _BuyHeader(
                              session: session,
                              onOpenChat: _openGlobalChat,
                            ),
                          ),
                          if (session.view == BuyV2View.catalogue)
                            _BuySearchBand(
                              session: session,
                              controller: _searchController,
                              open: _searchOpen,
                              onOpenChanged: (value) =>
                                  setState(() => _searchOpen = value),
                              onScan: _scanProduct,
                              onLocation: () =>
                                  showBuyV2AddressSheet(context, session),
                              scannerBusy: _scannerBusy,
                            ),
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _BuyNavigationSurfaceOwner(
                                    key: ObjectKey(session),
                                    stateKey: session.navigationMotionSequence,
                                    direction:
                                        session.navigationMotionDirection,
                                    child: _BuyExpandCollapseOwner(
                                      key: ValueKey(
                                        _searchOpen &&
                                                session.destination !=
                                                    BuyV2Destination.orders
                                            ? 'buy-search-owner-motion-search'
                                            : 'buy-search-owner-motion-primary',
                                      ),
                                      child:
                                          _searchOpen &&
                                              session.destination !=
                                                  BuyV2Destination.orders
                                          ? BuyV2SearchResultsView(
                                              session: session,
                                            )
                                          : _currentView(session),
                                    ),
                                  ),
                                ),
                                if (session.notice case final message?)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: _BuyNotice(message: message),
                                  ),
                              ],
                            ),
                          ),
                          if (_showsMiniCart(session))
                            _BuyMiniCartBar(session: session),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: MoolDestinationNavigationV2(
            activeId: careNavigation ? 'book' : 'buy',
            destinationLabel: careNavigation ? 'Care' : 'Shop',
            selectedLocalIndex: careNavigation
                ? 1
                : switch (session.activeDockDestination) {
                    BuyV2Destination.orders => 1,
                    _ => 0,
                  },
            localActionCount: careNavigation ? 3 : 2,
            localNavigation: careNavigation
                ? _buildCareLocalNavigation()
                : _buildBuyLocalNavigation(session),
            onOpenMool: _openGlobalMool,
            onOpenAction: _openGlobalAction,
            onOpenChat: _openGlobalChat,
            onPreviousLocalAction: () => _moveBuyLocal(session, -1),
            onNextLocalAction: () => _moveBuyLocal(session, 1),
          ),
        ),
      ),
    );
  }

  Widget _buildBuyLocalNavigation(BuyV2Session session) {
    final active = session.activeDockDestination;
    return MoolLocalNavigationRail(
      key: const ValueKey('buy-local-destination-tabs'),
      familyId: 'buy',
      surfaceTone: MoolLocalNavigationSurfaceTone.light,
      semanticLabel: 'Shop choices: Wholesale and Orders.',
      activeId: active.name,
      actions: [
        MoolLocalNavigationAction(
          keyName: 'buy-local-tab-wholesale',
          id: BuyV2Destination.wholesale.name,
          label: 'Wholesale',
          icon: Icons.inventory_2_outlined,
          onPressed: active == BuyV2Destination.wholesale
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  session.openDestination(BuyV2Destination.wholesale);
                },
        ),
        MoolLocalNavigationAction(
          keyName: 'buy-local-tab-orders',
          id: BuyV2Destination.orders.name,
          label: 'Orders',
          icon: Icons.receipt_long_outlined,
          onPressed: active == BuyV2Destination.orders
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  session.openOrders();
                },
        ),
      ],
    );
  }

  Widget _buildCareLocalNavigation() {
    return MoolLocalNavigationRail(
      key: const ValueKey('care-local-destination-tabs'),
      familyId: 'book',
      surfaceTone: MoolLocalNavigationSurfaceTone.light,
      semanticLabel: 'Care choices: Doctor, Medicine and Salon.',
      activeId: 'medicine',
      actions: [
        MoolLocalNavigationAction(
          keyName: 'care-local-tab-doctor',
          id: 'doctor',
          label: 'Doctor',
          icon: Icons.medical_services_outlined,
          onPressed: () => openMoolConnectedRoute(
            context,
            activeFamilyId: 'book',
            route: '/app/book/doctor',
          ),
        ),
        const MoolLocalNavigationAction(
          keyName: 'care-local-tab-medicine',
          id: 'medicine',
          label: 'Medicine',
          icon: Icons.medication_outlined,
        ),
        MoolLocalNavigationAction(
          keyName: 'care-local-tab-salon',
          id: 'salon',
          label: 'Salon',
          icon: Icons.content_cut_rounded,
          onPressed: () => openMoolConnectedRoute(
            context,
            activeFamilyId: 'book',
            route: '/app/book/salon',
          ),
        ),
      ],
    );
  }

  void _moveBuyLocal(BuyV2Session session, int delta) {
    if (session.activeDockDestination == BuyV2Destination.medicine) {
      const careRoutes = [
        '/app/book/doctor',
        '/app/buy?sub=medicine',
        '/app/book/salon',
      ];
      final next = (1 + delta + careRoutes.length) % careRoutes.length;
      openMoolConnectedRoute(
        context,
        activeFamilyId: 'book',
        route: careRoutes[next],
      );
      return;
    }
    const destinations = [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.orders,
    ];
    final current = destinations.indexOf(session.activeDockDestination);
    final next =
        destinations[(current + delta + destinations.length) %
            destinations.length];
    HapticFeedback.selectionClick();
    if (next == BuyV2Destination.orders) {
      session.openOrders();
    } else {
      session.openDestination(next);
    }
  }

  bool _showsMiniCart(BuyV2Session session) =>
      session.itemCount > 0 &&
      (session.view == BuyV2View.product ||
          session.view == BuyV2View.catalogue);

  void _openGlobalMool() {
    final onOpenMool = widget.onOpenMool;
    if (onOpenMool != null) {
      onOpenMool();
      return;
    }
    context.push('/app/mool?from=buy');
  }

  void _openGlobalAction(PersonalMoolActionSpec action) {
    final onOpenMainAction = widget.onOpenMainAction;
    if (onOpenMainAction != null) {
      onOpenMainAction(action);
      return;
    }
    openMoolConnectedRoute(
      context,
      activeFamilyId:
          widget.session.activeDockDestination == BuyV2Destination.medicine
          ? 'book'
          : 'buy',
      route: action.route,
    );
  }

  void _openGlobalChat() {
    final onOpenChat = widget.onOpenChat;
    if (onOpenChat != null) {
      onOpenChat();
      return;
    }
    final router = GoRouter.maybeOf(context);
    final returnRoute = router?.routeInformationProvider.value.uri.toString();
    context.push(
      Uri(
        path: '/app/chat/inbox',
        queryParameters: {'return': returnRoute ?? '/app/buy'},
      ).toString(),
    );
  }

  Widget _currentView(BuyV2Session session) {
    if (session.destination == BuyV2Destination.orders &&
        session.view == BuyV2View.catalogue) {
      return BuyV2OrdersView(session: session);
    }
    return switch (session.view) {
      BuyV2View.catalogue => BuyV2CatalogueView(session: session),
      BuyV2View.product => BuyV2ProductView(session: session),
      BuyV2View.cart => BuyV2CartView(session: session),
      BuyV2View.checkout => BuyV2CheckoutView(
        session: session,
        billingController: _checkoutBilling,
      ),
      BuyV2View.confirmation => BuyV2ConfirmationView(session: session),
      BuyV2View.tracking => BuyV2TrackingView(session: session),
      BuyV2View.orderItems => BuyV2OrderItemsView(session: session),
      BuyV2View.assist => BuyV2AssistView(session: session),
      BuyV2View.account => BuyV2AccountView(session: session),
      BuyV2View.recovery => BuyV2RecoveryView(session: session),
    };
  }
}

class _BuyExpandCollapseOwner extends StatelessWidget {
  const _BuyExpandCollapseOwner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = BuyV2Motion.resolved(context, BuyV2Motion.expandCollapse);
    return TweenAnimationBuilder<double>(
      key: const ValueKey('buy-expand-collapse-owner-tween'),
      duration: duration,
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: duration == Duration.zero ? 1 : 0, end: 1),
      builder: (context, value, child) => Opacity(
        key: const ValueKey('buy-expand-collapse-owner-opacity'),
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _BuyNavigationSurfaceOwner extends StatefulWidget {
  const _BuyNavigationSurfaceOwner({
    super.key,
    required this.stateKey,
    required this.direction,
    required this.child,
  });

  final int stateKey;
  final BuyV2NavigationMotionDirection direction;
  final Widget child;

  @override
  State<_BuyNavigationSurfaceOwner> createState() =>
      _BuyNavigationSurfaceOwnerState();
}

class _BuyNavigationSurfaceOwnerState
    extends State<_BuyNavigationSurfaceOwner> {
  bool _hasBuilt = false;

  @override
  Widget build(BuildContext context) {
    final firstBuild = !_hasBuilt;
    _hasBuilt = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      return KeyedSubtree(
        key: const ValueKey('buy-navigation-surface-current'),
        child: KeyedSubtree(
          key: ValueKey<int>(widget.stateKey),
          child: widget.child,
        ),
      );
    }

    return ClipRect(
      key: const ValueKey('buy-navigation-surface-owner'),
      child: TweenAnimationBuilder<double>(
        key: ValueKey<int>(widget.stateKey),
        tween: Tween<double>(begin: firstBuild ? 1 : 0, end: 1),
        duration: BuyV2Motion.routeChange,
        child: KeyedSubtree(
          key: const ValueKey('buy-navigation-surface-current'),
          child: widget.child,
        ),
        builder: (context, value, child) {
          final progress = Curves.easeOutCubic.transform(value);
          final remaining = 1 - progress;
          final horizontal = switch (widget.direction) {
            BuyV2NavigationMotionDirection.forward => 18.0,
            BuyV2NavigationMotionDirection.back => -18.0,
            BuyV2NavigationMotionDirection.replace => 0.0,
          };
          final vertical =
              widget.direction == BuyV2NavigationMotionDirection.replace
              ? 5.0
              : 0.0;
          final scaleStart =
              widget.direction == BuyV2NavigationMotionDirection.replace
              ? .992
              : .996;

          return Opacity(
            opacity: .82 + (.18 * progress),
            child: Transform.translate(
              key: const ValueKey('buy-navigation-surface-translation'),
              offset: Offset(horizontal * remaining, vertical * remaining),
              transformHitTests: false,
              child: Transform.scale(
                scale: scaleStart + (1 - scaleStart) * progress,
                transformHitTests: false,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BuyHeader extends StatelessWidget {
  const _BuyHeader({required this.session, required this.onOpenChat});

  final BuyV2Session session;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final theme = BuyV2ThemeScope.of(context);
    return MoolFiniteGradientTransition(
      key: const ValueKey('buy-shared-header'),
      gradient: theme.headerGradient,
      duration: BuyV2Motion.routeChange,
      child: _ContextualGlassHeader(
        session: session,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
          child: Row(
            children: [
              SizedBox(
                key: const ValueKey('buy-header-context-slot'),
                width: 44,
                height: 56,
                child: Center(
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: _HeaderContextButton(session: session),
                  ),
                ),
              ),
              const Spacer(),
              MoolGlobalChatShortcut(
                keyName: 'buy-global-chat',
                onPressed: onOpenChat,
                onDarkSurface: true,
              ),
              const SizedBox(width: 4),
              Semantics(
                label: session.view == BuyV2View.account
                    ? 'Close profile and return to purchases'
                    : 'Open profile and account',
                button: true,
                child: InkWell(
                  key: const ValueKey('buy-open-account'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (session.view == BuyV2View.account) {
                      session.closeAccount();
                    } else {
                      session.openAccount();
                    }
                  },
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 44,
                    height: 56,
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            key: const ValueKey('buy-profile-glass-core'),
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: BuyV2Colors.navy.withValues(alpha: .76),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .90),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: BuyV2Colors.navy.withValues(
                                    alpha: .24,
                                  ),
                                  blurRadius: 7,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'DC',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -1,
                            bottom: 1,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: BuyV2Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextualGlassHeader extends StatelessWidget {
  const _ContextualGlassHeader({required this.session, required this.child});

  final BuyV2Session session;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final destination = session.destination;
    final view = session.view;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final promoAction = _resolveHeaderPromoAction(context, session);
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(
        'buy-contextual-glass-motion-${destination.name}-${view.name}',
      ),
      tween: Tween<double>(begin: reduced ? 1 : 0, end: 1),
      duration: BuyV2Motion.resolved(
        context,
        const Duration(milliseconds: 3600),
      ),
      curve: Curves.linear,
      builder: (context, progress, _) => ClipRect(
        key: const ValueKey('buy-contextual-glass-header'),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  key: const ValueKey('buy-header-navy-depth-stage'),
                  color: BuyV2Colors.navy,
                  child: _HeaderSignatureMotion(
                    destination: destination,
                    view: view,
                    progress: progress,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  key: const ValueKey('buy-header-contrast-veil'),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0, .38, .76, 1],
                      colors: [
                        BuyV2Colors.navy.withValues(alpha: .18),
                        BuyV2Colors.navy.withValues(alpha: .03),
                        BuyV2Colors.navy.withValues(alpha: .22),
                        BuyV2Colors.navy.withValues(alpha: .10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (promoAction != null)
              Positioned(
                left: 8,
                width: 96,
                top: 0,
                bottom: 0,
                child: _HeaderPromoTapTarget(
                  destination: destination,
                  slot: _HeaderScenePainter.creativeSlotForProgress(progress),
                  action: promoAction,
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

class _HeaderPromoTapTarget extends StatelessWidget {
  const _HeaderPromoTapTarget({
    required this.destination,
    required this.slot,
    required this.action,
  });

  final BuyV2Destination destination;
  final int slot;
  final _HeaderPromoAction action;

  @override
  Widget build(BuildContext context) {
    void dispatchAction() {
      HapticFeedback.selectionClick();
      action.onTap();
    }

    return Semantics(
      key: ValueKey<String>(
        'buy-header-promo-stage-action-${destination.name}-$slot',
      ),
      label:
          '${destination.label} visual promotion ${slot + 1} of 5. '
          '${action.semantics}',
      button: true,
      onTap: dispatchAction,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>(
            'buy-header-promo-stage-tap-${destination.name}-$slot',
          ),
          onTap: dispatchAction,
          splashColor: Colors.white.withValues(alpha: .10),
          highlightColor: Colors.white.withValues(alpha: .055),
        ),
      ),
    );
  }
}

class _HeaderSignatureMotion extends StatelessWidget {
  const _HeaderSignatureMotion({
    required this.destination,
    required this.view,
    required this.progress,
  });

  final BuyV2Destination destination;
  final BuyV2View view;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final signatureKey = switch (destination) {
      BuyV2Destination.shop => 'buy-header-signature-shop',
      BuyV2Destination.wholesale => 'buy-header-signature-wholesale',
      BuyV2Destination.medicine => 'buy-header-signature-medicine',
      BuyV2Destination.orders => 'buy-header-signature-orders',
    };
    return RepaintBoundary(
      key: const ValueKey('buy-header-visual-creative-reel'),
      child: CustomPaint(
        key: ValueKey<String>(signatureKey),
        painter: _HeaderScenePainter(
          destination: destination,
          view: view,
          progress: progress,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _HeaderScenePainter extends CustomPainter {
  const _HeaderScenePainter({
    required this.destination,
    required this.view,
    required this.progress,
  });

  final BuyV2Destination destination;
  final BuyV2View view;
  final double progress;

  static const int _creativeSlotsPerContext = 5;
  static const int _totalVisualCreativeSlots = 20;
  static const Color _shopLight = Color(0xFF00D4FF);
  static const Color _shopRim = Color(0xFF7C4DFF);
  static const Color _wholesaleLight = Color(0xFF00BFA5);
  static const Color _wholesaleRim = Color(0xFFFFCA28);
  static const Color _medicineLight = Color(0xFF47D7FF);
  static const Color _medicineRim = Color(0xFF9D7CFF);
  static const Color _ordersLight = Color(0xFF42A5F5);
  static const Color _ordersRim = Color(0xFFE040FB);

  ({Color primary, Color secondary, Color tertiary}) get _promoPalette =>
      switch (destination) {
        BuyV2Destination.shop => (
          primary: _shopLight,
          secondary: _shopRim,
          tertiary: _ordersRim,
        ),
        BuyV2Destination.wholesale => (
          primary: _wholesaleLight,
          secondary: _wholesaleRim,
          tertiary: _shopLight,
        ),
        BuyV2Destination.medicine => (
          primary: _medicineLight,
          secondary: _medicineRim,
          tertiary: _wholesaleLight,
        ),
        BuyV2Destination.orders => (
          primary: _ordersLight,
          secondary: _ordersRim,
          tertiary: _medicineLight,
        ),
      };

  Offset _cameraVanishingPoint(Size size) {
    final horizontalDolly = math.sin(progress * math.pi) * .026;
    final verticalDolly = math.cos(progress * math.pi * .82) * .026;
    return Offset(
      size.width * (.70 + horizontalDolly),
      size.height * (.47 + verticalDolly),
    );
  }

  static int creativeSlotForProgress(double progress) {
    final reelArrival = progress <= .08
        ? 0.0
        : progress >= .88
        ? 1.0
        : Curves.easeOutCubic.transform((progress - .08) / .80);
    final reelPosition =
        Curves.easeInOutCubic.transform(reelArrival) *
        (_creativeSlotsPerContext - 1);
    return reelPosition.round().clamp(0, _creativeSlotsPerContext - 1);
  }

  double _phase(double begin, double end) {
    if (progress <= begin) return 0;
    if (progress >= end) return 1;
    return Curves.easeOutCubic.transform((progress - begin) / (end - begin));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final far = .58 + (.42 * _phase(0, .42));
    final middle = .34 + (.66 * _phase(.16, .70));
    final near = .16 + (.84 * _phase(.34, .96));
    canvas.drawRect(bounds, Paint()..color = BuyV2Colors.navy);
    _paintCinematicVolume(canvas, size, far, middle);
    _paintContextCreativeReel(canvas, size, far, middle, near);
    _paintForegroundOcclusion(canvas, size, near);
  }

  void _paintCinematicVolume(
    Canvas canvas,
    Size size,
    double far,
    double middle,
  ) {
    final bounds = Offset.zero & size;
    final vanishing = _cameraVanishingPoint(size);
    final palette = _promoPalette;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.46, -.08),
          radius: 1.32,
          stops: const [0, .18, .50, .78, 1],
          colors: [
            Color.lerp(
              Colors.white,
              palette.primary,
              .44,
            )!.withValues(alpha: .27 * far),
            palette.tertiary.withValues(alpha: .15 * middle),
            palette.secondary.withValues(alpha: .18 * far),
            BuyV2Colors.navy.withValues(alpha: .12),
            BuyV2Colors.navy,
          ],
        ).createShader(bounds),
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, .25, .52, .76, 1],
          colors: [
            palette.primary.withValues(alpha: .40 * far),
            Colors.white.withValues(alpha: .085 * far),
            BuyV2Colors.navy.withValues(alpha: 0),
            palette.secondary.withValues(alpha: .34 * middle),
            palette.tertiary.withValues(alpha: .28 * middle),
          ],
        ).createShader(bounds),
    );
    for (final glow in <({Offset centre, Color colour, double radius})>[
      (
        centre: Offset(size.width * .08, size.height * .08),
        colour: palette.primary,
        radius: size.width * .28,
      ),
      (
        centre: Offset(size.width * .92, size.height * .14),
        colour: palette.secondary,
        radius: size.width * .24,
      ),
      (
        centre: Offset(size.width * .66, size.height * .98),
        colour: palette.tertiary,
        radius: size.width * .32,
      ),
    ]) {
      canvas.drawCircle(
        glow.centre,
        glow.radius,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  glow.colour.withValues(alpha: .12 * middle),
                  glow.colour.withValues(alpha: .035 * far),
                  glow.colour.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: glow.centre, radius: glow.radius),
              ),
      );
    }

    final portal = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: vanishing,
        width: 22 + (12 * far),
        height: 13 + (8 * far),
      ),
      const Radius.circular(4),
    );
    final ceiling = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(portal.right, portal.top)
      ..lineTo(portal.left, portal.top)
      ..close();
    final floor = Path()
      ..moveTo(0, size.height)
      ..lineTo(portal.left, portal.bottom)
      ..lineTo(portal.right, portal.bottom)
      ..lineTo(size.width, size.height)
      ..close();
    final leftWall = Path()
      ..moveTo(0, 0)
      ..lineTo(portal.left, portal.top)
      ..lineTo(portal.left, portal.bottom)
      ..lineTo(0, size.height)
      ..close();
    final rightWall = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(portal.right, portal.bottom)
      ..lineTo(portal.right, portal.top)
      ..close();
    canvas.drawPath(
      ceiling,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.tertiary.withValues(alpha: .24 * far),
            Color.lerp(
              BuyV2Colors.navy,
              palette.primary,
              .18,
            )!.withValues(alpha: .82),
            Colors.white.withValues(alpha: .045 * middle),
          ],
        ).createShader(bounds),
    );
    canvas.drawPath(
      leftWall,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.lerp(
              BuyV2Colors.navy,
              palette.primary,
              .42,
            )!.withValues(alpha: .94),
            palette.primary.withValues(alpha: .19 * far),
            palette.tertiary.withValues(alpha: .10 * middle),
          ],
        ).createShader(bounds),
    );
    canvas.drawPath(
      rightWall,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Color.lerp(
              BuyV2Colors.navy,
              palette.secondary,
              .38,
            )!.withValues(alpha: .92),
            palette.secondary.withValues(alpha: .21 * middle),
            palette.tertiary.withValues(alpha: .095 * far),
          ],
        ).createShader(bounds),
    );
    canvas.drawPath(
      floor,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, .34, .72, 1],
          colors: [
            palette.primary.withValues(alpha: .20 * middle),
            Color.lerp(
              BuyV2Colors.navy,
              palette.tertiary,
              .26,
            )!.withValues(alpha: .56),
            palette.secondary.withValues(alpha: .22 * middle),
            BuyV2Colors.navy.withValues(alpha: .48),
          ],
        ).createShader(bounds),
    );
    _paintPoolRoomSurfaces(canvas, size, portal, far, middle);
    _paintBroadcastLighting(canvas, size, portal, far, middle);

    for (var frame = 0; frame < 9; frame += 1) {
      final frameArrival = (far - (frame * .025)).clamp(0.0, 1.0);
      if (frameArrival <= 0) continue;
      final depth = frame / 8;
      final expansion = Curves.easeInCubic.transform(depth);
      final rect = Rect.fromCenter(
        center: Offset(
          vanishing.dx - (size.width * .07 * expansion),
          vanishing.dy + (size.height * .018 * expansion),
        ),
        width: 24 + (size.width * 1.16 * expansion),
        height: 14 + (size.height * 1.52 * expansion),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(4 + (8 * expansion))),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = frame < 2 ? .95 : .55
          ..color = Colors.white.withValues(
            alpha: (.18 - (frame * .014)) * frameArrival,
          ),
      );
    }

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75
      ..color = Colors.white.withValues(alpha: .17 * far);
    for (final corner in <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      canvas.drawLine(corner, vanishing, edge);
    }

    for (var panel = 0; panel < 5; panel += 1) {
      final t = (panel + 1) / 6;
      final centre = Offset.lerp(
        Offset(size.width * (.12 + (panel * .18)), -4),
        vanishing,
        .28 + (.08 * panel),
      )!;
      final panelRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: centre,
          width: 18 - (7 * t),
          height: 7 - (2.5 * t),
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(
        panelRect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: .28 * far),
              Colors.white.withValues(alpha: .065 * far),
              BuyV2Colors.navy.withValues(alpha: .18),
            ],
          ).createShader(panelRect.outerRect),
      );
    }

    for (var reflection = 0; reflection < 5; reflection += 1) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            size.width * (.66 + (.025 * reflection)),
            size.height * (.64 + (.075 * reflection)),
          ),
          width: size.width * (.13 + (.15 * reflection)),
          height: 2.2 + (reflection * 1.3),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65
          ..color = Colors.white.withValues(
            alpha: (.13 - (reflection * .019)) * middle,
          ),
      );
    }

    canvas.drawRRect(
      portal,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .26 * far),
            Colors.white.withValues(alpha: .055 * far),
            BuyV2Colors.navy.withValues(alpha: .64),
          ],
        ).createShader(portal.outerRect),
    );
    canvas.drawRRect(
      portal,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .42 * far),
    );
    canvas.drawCircle(portal.center, 2.1, Paint()..color = BuyV2Colors.green);
    _paintVolumetricGlints(
      canvas,
      size,
      far,
      middle,
      palette.primary,
      palette.secondary,
    );
  }

  void _paintPoolRoomSurfaces(
    Canvas canvas,
    Size size,
    RRect portal,
    double far,
    double middle,
  ) {
    final bounds = Offset.zero & size;
    final vanishing = portal.center;
    final palette = _promoPalette;
    for (var bay = 0; bay < 4; bay += 1) {
      final depth = bay / 4;
      final leftNearX = size.width * (.02 + (bay * .105));
      final leftFarX = portal.left - (7 + (bay * 9));
      final leftBay = Path()
        ..moveTo(leftNearX, 5 + (bay * 2.2))
        ..quadraticBezierTo(
          size.width * (.38 + (.035 * bay)),
          9 + (bay * 2),
          leftFarX,
          portal.top + (2 * depth),
        )
        ..lineTo(leftFarX, portal.bottom - (2 * depth))
        ..quadraticBezierTo(
          size.width * (.36 + (.04 * bay)),
          size.height - (8 + (bay * 1.5)),
          leftNearX,
          size.height - (5 + (bay * 2)),
        )
        ..close();
      canvas.drawPath(
        leftBay,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: (.085 - (.012 * bay)) * far),
              BuyV2Colors.navy.withValues(alpha: .20 + (.08 * bay)),
              Colors.white.withValues(alpha: .018 * middle),
            ],
          ).createShader(bounds),
      );
      canvas.drawPath(
        leftBay,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bay == 0 ? 1.15 : .65
          ..color = Colors.white.withValues(alpha: (.24 - (.035 * bay)) * far),
      );

      final rightNearX = size.width * (.98 - (bay * .075));
      final rightFarX = portal.right + (7 + (bay * 8));
      final rightBay = Path()
        ..moveTo(rightNearX, 5 + (bay * 2.4))
        ..quadraticBezierTo(
          size.width * (.88 - (.02 * bay)),
          9 + (bay * 2),
          rightFarX,
          portal.top + (2 * depth),
        )
        ..lineTo(rightFarX, portal.bottom - (2 * depth))
        ..quadraticBezierTo(
          size.width * (.88 - (.02 * bay)),
          size.height - (8 + (bay * 1.5)),
          rightNearX,
          size.height - (5 + (bay * 2)),
        )
        ..close();
      canvas.drawPath(
        rightBay,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              Colors.white.withValues(alpha: (.10 - (.014 * bay)) * far),
              BuyV2Colors.navy.withValues(alpha: .22 + (.07 * bay)),
              Colors.white.withValues(alpha: .022 * middle),
            ],
          ).createShader(bounds),
      );
      canvas.drawPath(
        rightBay,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bay == 0 ? 1.15 : .65
          ..color = Colors.white.withValues(alpha: (.26 - (.038 * bay)) * far),
      );
    }

    for (var rim = 0; rim < 6; rim += 1) {
      final expansion = rim * 15.0;
      final pool = Rect.fromCenter(
        center: Offset(
          vanishing.dx - (expansion * .20),
          size.height * (.67 + (.035 * rim)),
        ),
        width: 42 + (expansion * 2.1),
        height: 5 + (rim * 2.4),
      );
      canvas.drawOval(
        pool,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim == 0 ? 1.1 : .65
          ..color = Colors.white.withValues(
            alpha: (.28 - (.038 * rim)) * middle,
          ),
      );
    }

    final mirror = Path()
      ..moveTo(portal.left + 3, portal.bottom)
      ..lineTo(portal.right - 3, portal.bottom)
      ..lineTo(size.width * .83, size.height)
      ..lineTo(size.width * .42, size.height)
      ..close();
    canvas.drawPath(
      mirror,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .15 * middle),
            Colors.white.withValues(alpha: .025 * middle),
            BuyV2Colors.navy.withValues(alpha: 0),
          ],
        ).createShader(bounds),
    );

    final cornerCore = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(
        Colors.white,
        palette.primary,
        .42,
      )!.withValues(alpha: .56 * far);
    final cornerGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..color = palette.secondary.withValues(alpha: .16 * far);
    final corners = <Path>[
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(size.width * .38, 3, portal.left, portal.top),
      Path()
        ..moveTo(size.width, 0)
        ..quadraticBezierTo(size.width * .88, 4, portal.right, portal.top),
      Path()
        ..moveTo(0, size.height)
        ..quadraticBezierTo(
          size.width * .36,
          size.height - 4,
          portal.left,
          portal.bottom,
        ),
      Path()
        ..moveTo(size.width, size.height)
        ..quadraticBezierTo(
          size.width * .89,
          size.height - 4,
          portal.right,
          portal.bottom,
        ),
    ];
    for (final corner in corners) {
      canvas.drawPath(corner, cornerGlow);
      canvas.drawPath(corner, cornerCore);
    }

    final deepLight = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: .28 * far),
          palette.primary.withValues(alpha: .24 * far),
          palette.secondary.withValues(alpha: .13 * middle),
          palette.tertiary.withValues(alpha: .07 * middle),
          BuyV2Colors.navy.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: vanishing, radius: 35));
    canvas.drawCircle(vanishing, 35, deepLight);
  }

  void _paintBroadcastLighting(
    Canvas canvas,
    Size size,
    RRect portal,
    double far,
    double middle,
  ) {
    final palette = _promoPalette;
    final vanishing = portal.center;
    final bounds = Offset.zero & size;
    final beamOrigins = <Offset>[
      Offset(size.width * .06, 0),
      Offset(size.width * .34, 0),
      Offset(size.width * .78, 0),
      Offset(size.width * .97, size.height),
    ];
    for (var beam = 0; beam < beamOrigins.length; beam += 1) {
      final origin = beamOrigins[beam];
      final colour = switch (beam % 3) {
        0 => palette.primary,
        1 => palette.secondary,
        _ => palette.tertiary,
      };
      final width = 18.0 + (beam * 7);
      final beamPath = Path()
        ..moveTo(origin.dx - width, origin.dy)
        ..lineTo(origin.dx + width, origin.dy)
        ..lineTo(vanishing.dx + (beam.isEven ? 5 : -5), vanishing.dy + 2)
        ..lineTo(vanishing.dx - (beam.isEven ? 5 : -5), vanishing.dy - 2)
        ..close();
      canvas.drawPath(
        beamPath,
        Paint()
          ..shader = LinearGradient(
            begin: beam < 3 ? Alignment.topCenter : Alignment.bottomRight,
            end: Alignment.center,
            colors: [
              colour.withValues(alpha: .27 * far),
              colour.withValues(alpha: .11 * middle),
              colour.withValues(alpha: 0),
            ],
          ).createShader(bounds),
      );
    }

    for (var curtain = 0; curtain < 6; curtain += 1) {
      final t = curtain / 5;
      final origin = Offset(size.width * (.08 + (.17 * curtain)), -2);
      final colour = switch (curtain % 3) {
        0 => palette.primary,
        1 => palette.secondary,
        _ => palette.tertiary,
      };
      final lightPath = Path()
        ..moveTo(origin.dx, origin.dy)
        ..quadraticBezierTo(
          size.width * (.42 + (.09 * t)),
          size.height * (.18 + (.12 * math.sin(t * math.pi))),
          vanishing.dx,
          vanishing.dy,
        )
        ..quadraticBezierTo(
          size.width * (.54 + (.13 * t)),
          size.height * .80,
          size.width * (.22 + (.14 * curtain)),
          size.height + 2,
        );
      canvas.drawPath(
        lightPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5 - (2.2 * t)
          ..strokeCap = StrokeCap.round
          ..color = colour.withValues(alpha: (.075 - (.025 * t)) * far)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawPath(
        lightPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .55
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(
            Colors.white,
            colour,
            .62,
          )!.withValues(alpha: (.52 - (.15 * t)) * far),
      );
    }

    for (var flare = 0; flare < 5; flare += 1) {
      final t = flare / 4;
      final centre = Offset.lerp(
        vanishing,
        Offset(size.width * .18, size.height * .70),
        t,
      )!;
      final radius = 1.4 + (t * 5.5);
      final colour = switch (flare % 3) {
        0 => palette.primary,
        1 => palette.secondary,
        _ => palette.tertiary,
      };
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .55
          ..color = colour.withValues(alpha: (.46 - (.07 * flare)) * middle),
      );
    }

    final lensBloom = Rect.fromCircle(
      center: vanishing,
      radius: 28 + (18 * middle),
    );
    canvas.drawCircle(
      vanishing,
      lensBloom.width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .18 * far),
            palette.primary.withValues(alpha: .21 * middle),
            palette.secondary.withValues(alpha: .11 * middle),
            palette.tertiary.withValues(alpha: .055 * middle),
            BuyV2Colors.navy.withValues(alpha: 0),
          ],
        ).createShader(lensBloom),
    );
  }

  void _paintContextCreativeReel(
    Canvas canvas,
    Size size,
    double far,
    double middle,
    double near,
  ) {
    assert(_creativeSlotsPerContext * 4 == _totalVisualCreativeSlots);
    final reelArrival = _phase(.08, .88);
    final reelPosition =
        Curves.easeInOutCubic.transform(reelArrival) *
        (_creativeSlotsPerContext - 1);
    final vanishing = _cameraVanishingPoint(size);
    final palette = _promoPalette;
    final handoffFraction = reelPosition - reelPosition.floorToDouble();
    final handoffFlash = math.sin(math.pi * handoffFraction).abs();
    if (handoffFlash > .01) {
      final flashRadius = 8 + (34 * handoffFlash);
      canvas.drawCircle(
        vanishing,
        flashRadius,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: .34 * handoffFlash),
                  palette.primary.withValues(alpha: .15 * handoffFlash),
                  palette.secondary.withValues(alpha: .06 * handoffFlash),
                  BuyV2Colors.navy.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: vanishing, radius: flashRadius),
              ),
      );
    }
    for (var slot = 0; slot < _creativeSlotsPerContext; slot += 1) {
      final delta = slot - reelPosition;
      final distance = delta.abs();
      var visibility = distance <= 1
          ? (1 - (distance * .76)).clamp(0.0, 1.0)
          : delta > 0
          ? (.18 / distance).clamp(0.0, .18)
          : (.09 / distance).clamp(0.0, .09);
      final settledBackground =
          reelArrival >= .999 && slot != _creativeSlotsPerContext - 1;
      if (reelArrival >= .999 && slot != _creativeSlotsPerContext - 1) {
        visibility = .10 + (slot * .025);
      }
      if (visibility <= .01) continue;
      final isActive = !settledBackground && distance < .74;
      final settledTargets = <Offset>[
        Offset(size.width * .38, size.height * .24),
        Offset(size.width * .47, size.height * .68),
        Offset(size.width * .76, size.height * .22),
        Offset(size.width * .84, size.height * .66),
      ];
      final target = settledBackground
          ? settledTargets[slot]
          : isActive
          ? Offset(
              size.width * (.62 - (.13 * delta)),
              size.height * (.39 + ((slot.isOdd ? 1 : -1) * .045)),
            )
          : delta > 0
          ? Offset(
              size.width * (.78 + (.045 * (slot % 3))),
              size.height * (slot.isOdd ? .24 : .63),
            )
          : Offset(
              size.width * (.39 - (.05 * (slot % 2))),
              size.height * (slot.isOdd ? .67 : .22),
            );
      final forwardTravel = settledBackground
          ? .24 + (.045 * slot)
          : isActive
          ? .40 + (.60 * visibility)
          : delta > 0
          ? (.34 - (.035 * distance)).clamp(.22, .34)
          : .88;
      final centre = Offset.lerp(vanishing, target, forwardTravel)!;
      final scale = settledBackground
          ? .25 + (.035 * slot)
          : isActive
          ? .42 + (.78 * visibility)
          : delta > 0
          ? .31 + (.16 * visibility)
          : 1.12 + (.10 * (1 - visibility));
      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.scale(scale);
      _paintPromoLightField(
        canvas,
        slot,
        visibility,
        isActive: isActive,
        flash: handoffFlash,
      );
      _paintVisualCreative(canvas, slot, visibility);
      canvas.restore();
      if (isActive) {
        canvas.save();
        canvas.translate(centre.dx, size.height * .74);
        canvas.scale(scale, -.22 * scale);
        _paintVisualCreative(canvas, slot, visibility * .18 * middle);
        canvas.restore();
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centre.dx, size.height * .78),
          width: (30 + (slot * 5)) * visibility,
          height: 3.8 * visibility,
        ),
        Paint()
          ..shader =
              LinearGradient(
                colors: [
                  palette.primary.withValues(alpha: 0),
                  palette.primary.withValues(alpha: .25 * visibility),
                  Colors.white.withValues(alpha: .18 * visibility),
                  palette.secondary.withValues(alpha: .18 * visibility),
                  palette.secondary.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCenter(
                  center: Offset(centre.dx, size.height * .78),
                  width: (30 + (slot * 5)) * visibility,
                  height: 3.8 * visibility,
                ),
              ),
      );
    }
  }

  void _paintPromoLightField(
    Canvas canvas,
    int slot,
    double opacity, {
    required bool isActive,
    required double flash,
  }) {
    final palette = _promoPalette;
    final primary = slot.isEven ? palette.primary : palette.secondary;
    final secondary = slot.isEven ? palette.secondary : palette.primary;
    final tertiary = palette.tertiary;
    const field = Rect.fromLTWH(-43, -30, 86, 60);
    canvas.drawOval(
      field,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.20, -.24),
          radius: 1,
          stops: const [0, .24, .52, .78, 1],
          colors: [
            Colors.white.withValues(alpha: .24 * opacity),
            primary.withValues(alpha: .25 * opacity),
            secondary.withValues(alpha: .16 * opacity),
            tertiary.withValues(alpha: .09 * opacity),
            BuyV2Colors.navy.withValues(alpha: 0),
          ],
        ).createShader(field)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final arcRect = field.deflate(3);
    for (var arc = 0; arc < 3; arc += 1) {
      final colour = switch (arc) {
        0 => primary,
        1 => secondary,
        _ => tertiary,
      };
      canvas.drawArc(
        arcRect.deflate(arc * 4),
        (-.85 + (arc * 1.95)) + (flash * .22),
        .70 + (arc * .11),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 1.45 : .75
          ..strokeCap = StrokeCap.round
          ..color = colour.withValues(alpha: (isActive ? .82 : .48) * opacity),
      );
    }
    for (var particle = 0; particle < 4; particle += 1) {
      final colour = particle.isEven ? primary : tertiary;
      canvas.drawCircle(
        Offset(-27 + (particle * 18), particle.isEven ? -18 : 19),
        1.2 + ((particle % 3) * .45),
        Paint()..color = colour.withValues(alpha: .74 * opacity),
      );
    }
  }

  void _paintVisualCreative(Canvas canvas, int slot, double opacity) {
    final objectBounds = const Rect.fromLTWH(-34, -26, 68, 52);
    final palette = _promoPalette;
    final primary = slot.isEven ? palette.primary : palette.secondary;
    final secondary = slot.isEven ? palette.secondary : palette.primary;
    final tertiary = palette.tertiary;
    final glass = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.38, -.46),
        radius: 1.18,
        colors: [
          Color.lerp(
            Colors.white,
            primary,
            .24,
          )!.withValues(alpha: .30 * opacity),
          primary.withValues(alpha: .13 * opacity),
          secondary.withValues(alpha: .15 * opacity),
          tertiary.withValues(alpha: .08 * opacity),
          BuyV2Colors.navy.withValues(alpha: .62 * opacity),
        ],
      ).createShader(objectBounds);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Color.lerp(
        Colors.white,
        primary,
        .35,
      )!.withValues(alpha: .62 * opacity);
    final soft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(
        secondary,
        tertiary,
        .34,
      )!.withValues(alpha: .48 * opacity);
    final green = Paint()
      ..color = opacity >= .52
          ? BuyV2Colors.green
          : Colors.white.withValues(alpha: .18 * opacity);

    switch ((destination, slot)) {
      case (BuyV2Destination.shop, 0):
        final basket = Path()
          ..moveTo(-22, -7)
          ..lineTo(-16, 13)
          ..lineTo(16, 13)
          ..lineTo(22, -7)
          ..close();
        canvas.drawPath(basket, glass);
        canvas.drawPath(basket, edge);
        canvas.drawArc(
          const Rect.fromLTWH(-13, -18, 26, 24),
          math.pi,
          math.pi,
          false,
          edge,
        );
        canvas.drawCircle(const Offset(0, 2), 3.2, green);
      case (BuyV2Destination.shop, 1):
        final store = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-24, -18, 48, 36),
          const Radius.circular(5),
        );
        canvas.drawRRect(store, glass);
        canvas.drawRRect(store, edge);
        canvas.drawLine(const Offset(-15, -7), const Offset(15, -7), soft);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-7, -4, 14, 22),
            const Radius.circular(3),
          ),
          edge,
        );
        canvas.drawCircle(const Offset(13, 4), 3, green);
      case (BuyV2Destination.shop, 2):
        for (var item = 0; item < 3; item += 1) {
          final card = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(-20 + (item * 20), -2 + (item.isOdd ? -5 : 4)),
              width: 16,
              height: 24,
            ),
            const Radius.circular(4),
          );
          canvas.drawRRect(card, glass);
          canvas.drawRRect(card, edge);
        }
        canvas.drawOval(const Rect.fromLTWH(-30, 15, 60, 7), soft);
        canvas.drawCircle(const Offset(0, -7), 2.8, green);
      case (BuyV2Destination.shop, 3):
        final cart = Path()
          ..moveTo(-23, -15)
          ..lineTo(-17, -15)
          ..lineTo(-10, 7)
          ..lineTo(17, 7)
          ..lineTo(22, -8)
          ..lineTo(-14, -8);
        canvas.drawPath(cart, edge);
        canvas.drawCircle(const Offset(-5, 15), 4, soft);
        canvas.drawCircle(const Offset(14, 15), 4, soft);
        canvas.drawCircle(const Offset(7, -1), 3, green);
        canvas.drawOval(const Rect.fromLTWH(-28, -22, 56, 44), soft);
      case (BuyV2Destination.shop, 4):
        for (var aisle = 0; aisle < 5; aisle += 1) {
          final x = -30 + (aisle * 15.0);
          final aislePath = Path()
            ..moveTo(x, 22)
            ..quadraticBezierTo(x * .48, -5, x * .18, -23);
          canvas.drawPath(aislePath, aisle.isEven ? edge : soft);
          canvas.drawCircle(
            Offset(x * .58, -2 + ((aisle % 2) * 8)),
            2.6 + ((aisle % 3) * .45),
            aisle.isEven ? glass : soft,
          );
        }
        canvas.drawArc(
          const Rect.fromLTWH(-32, -24, 64, 48),
          math.pi * .10,
          math.pi * .80,
          false,
          edge,
        );
        canvas.drawCircle(Offset.zero, 3.4, green);
      case (BuyV2Destination.wholesale, 0):
        for (var box = 0; box < 4; box += 1) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              -27 + ((box % 2) * 28),
              -18 + ((box ~/ 2) * 20),
              24,
              17,
            ),
            const Radius.circular(3),
          );
          canvas.drawRRect(rect, glass);
          canvas.drawRRect(rect, edge);
        }
        canvas.drawCircle(Offset.zero, 3, green);
      case (BuyV2Destination.wholesale, 1):
        final pallet = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-25, -18, 50, 32),
          const Radius.circular(4),
        );
        canvas.drawRRect(pallet, glass);
        canvas.drawRRect(pallet, edge);
        canvas.drawLine(const Offset(-29, 18), const Offset(29, 18), edge);
        canvas.drawLine(const Offset(-29, 22), const Offset(29, 22), edge);
        canvas.drawCircle(const Offset(17, -7), 3, green);
      case (BuyV2Destination.wholesale, 2):
        for (var frame = 0; frame < 4; frame += 1) {
          final inset = frame * 5.0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                -30 + inset,
                -22 + (inset * .4),
                60 - (inset * 2),
                44 - (inset * .8),
              ),
              const Radius.circular(4),
            ),
            frame == 3 ? edge : soft,
          );
        }
        canvas.drawCircle(Offset.zero, 3.2, green);
      case (BuyV2Destination.wholesale, 3):
        for (var orbit = 0; orbit < 3; orbit += 1) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: 24 + (orbit * 18),
              height: 14 + (orbit * 12),
            ),
            soft,
          );
        }
        for (final x in const [-17.0, 0.0, 17.0]) {
          final centre = Offset(x, x == 0 ? -4 : 5);
          canvas.drawCircle(centre, 6, glass);
          canvas.drawCircle(centre, 6, edge);
        }
        canvas.drawCircle(Offset.zero, 3, green);
      case (BuyV2Destination.wholesale, 4):
        final dock = Path()
          ..moveTo(-31, 20)
          ..lineTo(-22, -19)
          ..lineTo(22, -19)
          ..lineTo(31, 20)
          ..close();
        canvas.drawPath(dock, glass);
        canvas.drawPath(dock, edge);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-10, -8, 20, 28),
            const Radius.circular(3),
          ),
          edge,
        );
        canvas.drawCircle(const Offset(17, 7), 3.2, green);
      case (BuyV2Destination.medicine, 0):
        for (var halo = 0; halo < 4; halo += 1) {
          canvas.drawCircle(Offset.zero, 7 + (halo * 6), soft);
        }
        canvas.drawCircle(Offset.zero, 9, glass);
        canvas.drawCircle(Offset.zero, 3.4, green);
      case (BuyV2Destination.medicine, 1):
        canvas.save();
        canvas.rotate(-.35);
        final capsule = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-28, -8, 56, 16),
          const Radius.circular(9),
        );
        canvas.drawRRect(capsule, glass);
        canvas.drawRRect(capsule, edge);
        canvas.drawLine(const Offset(0, -8), const Offset(0, 8), edge);
        canvas.drawCircle(const Offset(-12, 0), 3.2, green);
        canvas.restore();
      case (BuyV2Destination.medicine, 2):
        final shield = Path()
          ..moveTo(0, -24)
          ..quadraticBezierTo(18, -18, 24, -10)
          ..quadraticBezierTo(21, 14, 0, 24)
          ..quadraticBezierTo(-21, 14, -24, -10)
          ..quadraticBezierTo(-18, -18, 0, -24)
          ..close();
        canvas.drawPath(shield, glass);
        canvas.drawPath(shield, edge);
        canvas.drawLine(const Offset(-8, 0), const Offset(8, 0), edge);
        canvas.drawLine(const Offset(0, -8), const Offset(0, 8), edge);
        canvas.drawCircle(const Offset(12, 11), 3, green);
      case (BuyV2Destination.medicine, 3):
        for (var orbit = 0; orbit < 3; orbit += 1) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: 30 + (orbit * 17),
              height: 18 + (orbit * 11),
            ),
            soft,
          );
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-12, -12, 24, 24),
            const Radius.circular(6),
          ),
          glass,
        );
        canvas.drawLine(const Offset(-7, 0), const Offset(7, 0), edge);
        canvas.drawLine(const Offset(0, -7), const Offset(0, 7), edge);
        canvas.drawCircle(const Offset(18, -8), 3, green);
      case (BuyV2Destination.medicine, 4):
        for (var frame = 0; frame < 4; frame += 1) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: 28 + (frame * 13),
              height: 18 + (frame * 9),
            ),
            frame == 3 ? edge : soft,
          );
        }
        canvas.drawCircle(Offset.zero, 10, glass);
        canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), edge);
        canvas.drawLine(const Offset(0, -6), const Offset(0, 6), edge);
        canvas.drawCircle(const Offset(16, 10), 3.2, green);
      case (BuyV2Destination.orders, 0):
        final parcel = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-23, -18, 46, 36),
          const Radius.circular(5),
        );
        canvas.drawRRect(parcel, glass);
        canvas.drawRRect(parcel, edge);
        canvas.drawLine(const Offset(0, -18), const Offset(0, 18), edge);
        canvas.drawCircle(const Offset(13, 8), 3.2, green);
      case (BuyV2Destination.orders, 1):
        final route = Path()
          ..moveTo(-30, 15)
          ..cubicTo(-15, -24, 8, 24, 30, -16);
        canvas.drawPath(route, edge);
        for (final point in const [
          Offset(-24, 3),
          Offset(-2, 0),
          Offset(23, -7),
        ]) {
          canvas.drawCircle(point, 4, glass);
          canvas.drawCircle(point, 4, edge);
        }
        canvas.drawCircle(const Offset(23, -7), 2.4, green);
      case (BuyV2Destination.orders, 2):
        for (var orbit = 0; orbit < 4; orbit += 1) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: 22 + (orbit * 14),
              height: 13 + (orbit * 9),
            ),
            soft,
          );
        }
        for (final point in const [
          Offset(-18, 4),
          Offset(0, -6),
          Offset(18, 4),
        ]) {
          canvas.drawCircle(point, 4.5, glass);
          canvas.drawCircle(point, 4.5, edge);
        }
        canvas.drawCircle(const Offset(18, 4), 2.5, green);
      case (BuyV2Destination.orders, 3):
        final arc = Path()
          ..moveTo(-30, 15)
          ..quadraticBezierTo(0, -28, 30, 15);
        canvas.drawPath(arc, edge);
        final vehicle = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-18, -5, 36, 20),
          const Radius.circular(5),
        );
        canvas.drawRRect(vehicle, glass);
        canvas.drawRRect(vehicle, edge);
        canvas.drawCircle(const Offset(-10, 16), 3.2, edge);
        canvas.drawCircle(const Offset(11, 16), 3.2, edge);
        canvas.drawCircle(const Offset(10, 2), 2.6, green);
      case (BuyV2Destination.orders, 4):
        final vault = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-24, -22, 48, 44),
          const Radius.circular(6),
        );
        canvas.drawRRect(vault, glass);
        canvas.drawRRect(vault, edge);
        for (final x in const [-11.0, 0.0, 11.0]) {
          canvas.drawLine(Offset(x, -13), Offset(x, 13), soft);
        }
        canvas.drawOval(const Rect.fromLTWH(-31, -27, 62, 54), soft);
        canvas.drawCircle(const Offset(15, 10), 3.2, green);
      default:
        assert(false, 'Unsupported header visual creative slot');
    }
  }

  // Kept only while prior qualified candidates remain source-reconstructable.
  // ignore: unused_element
  void _paintAllCornerDepth(
    Canvas canvas,
    Size size,
    double far,
    double middle,
  ) {
    final bounds = Offset.zero & size;
    final portalCentre = Offset(
      size.width * (.73 + (.035 * (1 - far))),
      size.height * (.44 - (.025 * (1 - far))),
    );
    final portal = Rect.fromCenter(
      center: portalCentre,
      width: size.width * (.10 + (.055 * far)),
      height: size.height * (.13 + (.10 * far)),
    );

    final topVault = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(portal.right, portal.top)
      ..lineTo(portal.left, portal.top)
      ..close();
    canvas.drawPath(
      topVault,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BuyV2Colors.navy.withValues(alpha: .42),
            Colors.white.withValues(alpha: .035 * far),
            BuyV2Colors.navy.withValues(alpha: .10 * middle),
          ],
        ).createShader(bounds),
    );

    final bottomVault = Path()
      ..moveTo(0, size.height)
      ..lineTo(portal.left, portal.bottom)
      ..lineTo(portal.right, portal.bottom)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      bottomVault,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            BuyV2Colors.navy.withValues(alpha: .58),
            Colors.white.withValues(alpha: .045 * middle),
            BuyV2Colors.navy.withValues(alpha: .08 * far),
          ],
        ).createShader(bounds),
    );

    final leftVault = Path()
      ..moveTo(0, 0)
      ..lineTo(portal.left, portal.top)
      ..lineTo(portal.left, portal.bottom)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      leftVault,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            BuyV2Colors.navy.withValues(alpha: .34),
            Colors.white.withValues(alpha: .022 * far),
            BuyV2Colors.navy.withValues(alpha: .055 * middle),
          ],
        ).createShader(bounds),
    );

    final rightVault = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(portal.right, portal.bottom)
      ..lineTo(portal.right, portal.top)
      ..close();
    canvas.drawPath(
      rightVault,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            BuyV2Colors.navy.withValues(alpha: .46),
            Colors.white.withValues(alpha: .04 * middle),
            BuyV2Colors.navy.withValues(alpha: .07 * far),
          ],
        ).createShader(bounds),
    );

    final cornerEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .85
      ..color = Colors.white.withValues(alpha: .12 * far);
    final upperLeft = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        size.width * .28,
        size.height * .02,
        portal.left - 24,
        portal.top - 7,
        portal.left,
        portal.top,
      );
    final upperRight = Path()
      ..moveTo(size.width, 0)
      ..cubicTo(
        size.width * .92,
        size.height * .06,
        portal.right + 20,
        portal.top - 6,
        portal.right,
        portal.top,
      );
    final lowerLeft = Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * .34,
        size.height * .93,
        portal.left - 20,
        portal.bottom + 8,
        portal.left,
        portal.bottom,
      );
    final lowerRight = Path()
      ..moveTo(size.width, size.height)
      ..cubicTo(
        size.width * .91,
        size.height * .91,
        portal.right + 18,
        portal.bottom + 7,
        portal.right,
        portal.bottom,
      );
    canvas.drawPath(upperLeft, cornerEdge);
    canvas.drawPath(upperRight, cornerEdge);
    canvas.drawPath(lowerLeft, cornerEdge);
    canvas.drawPath(lowerRight, cornerEdge);

    for (var plane = 0; plane < 7; plane += 1) {
      final planeArrival = (far - (plane * .035)).clamp(0.0, 1.0);
      if (planeArrival <= 0) continue;
      final expansion = 3.0 + (plane * 27.0);
      final planeRect = RRect.fromRectAndRadius(
        portal.inflate(expansion),
        Radius.circular(4 + (plane * 2.0)),
      );
      canvas.drawRRect(
        planeRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = plane == 0 ? 1.05 : .55
          ..color = Colors.white.withValues(
            alpha: (.14 - (plane * .014)) * planeArrival,
          ),
      );
    }

    for (var halo = 0; halo < 4; halo += 1) {
      final expansion = 8.0 + (halo * 22.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: portalCentre,
          width: portal.width + (expansion * 2.4),
          height: portal.height + expansion,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65
          ..color = Colors.white.withValues(
            alpha: (.105 - (halo * .018)) * middle,
          ),
      );
    }
  }

  // Kept only while prior qualified candidates remain source-reconstructable.
  // ignore: unused_element
  void _paintPerspectiveChamber(
    Canvas canvas,
    Size size,
    double far,
    double middle,
  ) {
    final vanishing = Offset(size.width * .73, size.height * .44);
    for (var depth = 0; depth < 6; depth += 1) {
      final arrival = (far - (depth * .038)).clamp(0.0, 1.0);
      if (arrival <= 0) continue;
      final depthFactor = depth / 5;
      final frameWidth = size.width * (.17 + (.84 * depthFactor));
      final frameHeight = size.height * (.21 + (1.34 * depthFactor));
      final chamber = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
            vanishing.dx - (14 * depthFactor) + (24 * (1 - arrival)),
            vanishing.dy + (2 * depthFactor),
          ),
          width: frameWidth,
          height: frameHeight,
        ),
        Radius.circular(5 + (depth * 2.0)),
      );
      canvas.drawRRect(
        chamber,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = depth == 0 ? 1.05 : .65
          ..color = Colors.white.withValues(
            alpha: (.13 - (depth * .012)) * arrival,
          ),
      );
    }

    for (var pane = 0; pane < 4; pane += 1) {
      final arrival = (middle - (pane * .055)).clamp(0.0, 1.0);
      if (arrival <= 0) continue;
      final target = Offset(
        size.width * (.52 + (pane * .14)),
        size.height * (.16 + ((pane % 2) * .40)),
      );
      final centre = Offset.lerp(vanishing, target, arrival)!;
      final paneRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: centre,
          width: 12 + (pane * 3.0),
          height: 9 + (pane * 2.0),
        ),
        const Radius.circular(7),
      );
      canvas.drawRRect(
        paneRect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.35, -.35),
            radius: 1.15,
            colors: [
              Colors.white.withValues(alpha: .20 * arrival),
              Colors.white.withValues(alpha: .035 * arrival),
              BuyV2Colors.navy.withValues(alpha: .28 * arrival),
            ],
          ).createShader(paneRect.outerRect),
      );
      canvas.drawRRect(
        paneRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6
          ..color = Colors.white.withValues(alpha: .16 * arrival),
      );
    }

    for (var reflection = 0; reflection < 4; reflection += 1) {
      final centre = Offset(
        size.width * (.68 + (reflection * .06)),
        size.height * (.70 + (reflection * .08)),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: centre,
          width: size.width * (.38 - (reflection * .045)),
          height: 5 + (reflection * 1.4),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = Colors.white.withValues(
            alpha: (.08 - (reflection * .012)) * middle,
          ),
      );
    }
  }

  void _paintVolumetricGlints(
    Canvas canvas,
    Size size,
    double far,
    double middle,
    Color primary,
    Color secondary,
  ) {
    final points = <(Offset, double)>[
      (Offset(size.width * .58, size.height * .24), 5.5),
      (Offset(size.width * .81, size.height * .18), 4.0),
      (Offset(size.width * .90, size.height * .61), 5.0),
      (Offset(size.width * .65, size.height * .76), 3.5),
    ];
    for (var index = 0; index < points.length; index += 1) {
      final arrival = (middle - (index * .035)).clamp(0.0, 1.0);
      if (arrival <= 0) continue;
      final point = points[index];
      canvas.drawCircle(
        point.$1,
        point.$2 + (4 * far),
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: .24 * arrival),
                  Colors.white.withValues(alpha: .055 * arrival),
                  BuyV2Colors.navy.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: point.$1, radius: point.$2 + (4 * far)),
              ),
      );
    }

    if (middle > 0) {
      canvas.drawCircle(
        Offset(size.width * .76, size.height * .39),
        2.2,
        Paint()..color = primary,
      );
      canvas.drawCircle(
        Offset(size.width * .84, size.height * .55),
        1.8,
        Paint()..color = secondary,
      );
    }
  }

  // Kept only while prior qualified candidates remain source-reconstructable.
  // ignore: unused_element
  void _paintCinematicWorld(
    Canvas canvas,
    Size size,
    double far,
    double middle,
    double near,
  ) {
    switch (destination) {
      case BuyV2Destination.shop:
        _paintCinematicShop(canvas, size, far, middle, near);
      case BuyV2Destination.wholesale:
        _paintCinematicWholesale(canvas, size, far, middle, near);
      case BuyV2Destination.medicine:
        _paintCinematicMedicine(canvas, size, far, middle, near);
      case BuyV2Destination.orders:
        _paintCinematicOrders(canvas, size, far, middle, near);
    }
  }

  void _paintCinematicShop(
    Canvas canvas,
    Size size,
    double far,
    double middle,
    double near,
  ) {
    final vanishing = Offset(size.width * .74, size.height * .43);
    for (var index = 0; index < 5; index += 1) {
      final arrival = index.isEven ? middle : near;
      if (arrival <= 0) continue;
      final target = Offset(
        size.width * (.54 + (index * .095)),
        size.height * (.16 + ((index % 2) * .35)),
      );
      final centre = Offset.lerp(vanishing, target, arrival)!;
      final scale = .55 + (.09 * index) + (.35 * arrival);
      final card = RRect.fromRectAndRadius(
        Rect.fromCenter(center: centre, width: 21 * scale, height: 28 * scale),
        Radius.circular(5 * scale),
      );
      canvas.drawRRect(
        card,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.45, -.50),
            radius: 1.28,
            colors: [
              Colors.white.withValues(alpha: .22 * arrival),
              Colors.white.withValues(alpha: .05 * arrival),
              BuyV2Colors.navy.withValues(alpha: .58 * arrival),
            ],
          ).createShader(card.outerRect),
      );
      canvas.drawRRect(
        card,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = Colors.white.withValues(alpha: .25 * arrival),
      );
      canvas.drawCircle(
        centre + Offset(0, -4 * scale),
        3.2 * scale,
        Paint()..color = index.isEven ? BuyV2Colors.orange : BuyV2Colors.green,
      );
    }

    for (var contour = 0; contour < 3; contour += 1) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * .79, size.height * .47),
          width: size.width * (.18 + (contour * .18)),
          height: size.height * (.22 + (contour * .20)),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = Colors.white.withValues(
            alpha: (.09 - (contour * .02)) * far,
          ),
      );
    }
  }

  void _paintCinematicWholesale(
    Canvas canvas,
    Size size,
    double far,
    double middle,
    double near,
  ) {
    final vanishing = Offset(size.width * .74, size.height * .43);
    for (var parcel = 0; parcel < 5; parcel += 1) {
      final arrival = parcel > 1 ? near : middle;
      if (arrival <= 0) continue;
      final target = Offset(
        size.width * (.53 + (parcel * .105)),
        size.height * (.58 - ((parcel % 2) * .30)),
      );
      final centre = Offset.lerp(vanishing, target, arrival)!;
      final boxScale = .50 + (.10 * parcel) + (.28 * arrival);
      final box = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: centre,
          width: (25.0 + parcel) * boxScale,
          height: (21.0 + parcel) * boxScale,
        ),
        Radius.circular(4 * boxScale),
      );
      canvas.drawRRect(
        box,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.42, -.48),
            radius: 1.25,
            colors: [
              Colors.white.withValues(alpha: .21 * arrival),
              BuyV2Colors.navy.withValues(alpha: .34 * arrival),
              BuyV2Colors.navy.withValues(alpha: .72 * arrival),
            ],
          ).createShader(box.outerRect),
      );
      canvas.drawRRect(
        box,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = Colors.white.withValues(alpha: .22 * arrival),
      );
      canvas.drawCircle(
        centre,
        3.2 * boxScale,
        Paint()..color = parcel.isOdd ? BuyV2Colors.orange : BuyV2Colors.green,
      );
    }

    for (var orbit = 0; orbit < 3; orbit += 1) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * .78, size.height * .45),
          width: size.width * (.20 + (orbit * .17)),
          height: size.height * (.28 + (orbit * .18)),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .75
          ..color = Colors.white.withValues(
            alpha: (.095 - (orbit * .021)) * far,
          ),
      );
    }
  }

  void _paintCinematicMedicine(
    Canvas canvas,
    Size size,
    double far,
    double middle,
    double near,
  ) {
    final centre = Offset(
      size.width * (.76 + (.08 * (1 - far))),
      size.height * .43,
    );
    for (final radius in [
      size.height * .67,
      size.height * .46,
      size.height * .27,
    ]) {
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = Colors.white.withValues(alpha: .19 * far),
      );
    }
    final careTarget = Offset(size.width * .67, size.height * .39);
    final careCentre = Offset.lerp(centre, careTarget, middle)!;
    canvas.drawCircle(
      careCentre,
      12 + (7 * middle),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.40),
          radius: 1.12,
          colors: [
            Colors.white.withValues(alpha: .24 * middle),
            Colors.white.withValues(alpha: .055 * middle),
            BuyV2Colors.navy.withValues(alpha: .42 * middle),
          ],
        ).createShader(Rect.fromCircle(center: careCentre, radius: 19)),
    );
    canvas.drawCircle(careCentre, 5.2, Paint()..color = BuyV2Colors.green);
    canvas.drawCircle(
      careCentre + const Offset(-2, -2),
      1.7,
      Paint()..color = Colors.white.withValues(alpha: .88 * middle),
    );
    for (var orbit = 0; orbit < 3; orbit += 1) {
      canvas.drawOval(
        Rect.fromCenter(
          center: centre,
          width: size.width * (.18 + (orbit * .17)),
          height: size.height * (.24 + (orbit * .18)),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = Colors.white.withValues(
            alpha: (.10 - (orbit * .023)) * middle,
          ),
      );
    }
    canvas.save();
    final capsuleCentre = Offset.lerp(
      centre,
      Offset(size.width * .84, size.height * .68),
      near,
    )!;
    canvas.translate(capsuleCentre.dx, capsuleCentre.dy);
    canvas.rotate(-.34);
    final capsule = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 42, height: 15),
      const Radius.circular(9),
    );
    if (near > 0) {
      canvas.drawRRect(
        capsule,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: .92 * near),
              Colors.white.withValues(alpha: .11 * near),
              BuyV2Colors.navy.withValues(alpha: .78 * near),
            ],
          ).createShader(capsule.outerRect),
      );
      canvas.drawCircle(
        const Offset(-9, 0),
        4.1,
        Paint()..color = BuyV2Colors.orange,
      );
    }
    canvas.restore();
  }

  void _paintCinematicOrders(
    Canvas canvas,
    Size size,
    double far,
    double middle,
    double near,
  ) {
    final route = Path()
      ..moveTo(size.width * .48, size.height * .81)
      ..cubicTo(
        size.width * (.61 + (.10 * (1 - far))),
        size.height * .08,
        size.width * .82,
        size.height * .88,
        size.width,
        size.height * .18,
      );
    canvas.drawPath(
      route,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .11 * far),
    );
    canvas.drawPath(
      route,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .42 * far),
    );
    final parcelLeft = size.width * (.67 + (.16 * (1 - middle)));
    final parcel = RRect.fromRectAndRadius(
      Rect.fromLTWH(parcelLeft, size.height * .18, 29, 27),
      const Radius.circular(4),
    );
    if (middle > 0) {
      canvas.drawRRect(
        parcel,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.42, -.46),
            radius: 1.24,
            colors: [
              Colors.white.withValues(alpha: .22 * middle),
              BuyV2Colors.navy.withValues(alpha: .36 * middle),
              BuyV2Colors.navy.withValues(alpha: .78 * middle),
            ],
          ).createShader(parcel.outerRect),
      );
      canvas.drawRRect(
        parcel,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = Colors.white.withValues(alpha: .24 * middle),
      );
      canvas.drawCircle(
        parcel.center,
        3.3,
        Paint()..color = BuyV2Colors.orange,
      );
    }
    final node = Offset(
      size.width * (.88 + (.07 * (1 - near))),
      size.height * .67,
    );
    if (near > 0) {
      canvas.drawCircle(node, 7, Paint()..color = BuyV2Colors.green);
    }
    canvas.drawCircle(
      node,
      2.5,
      Paint()..color = Colors.white.withValues(alpha: near),
    );
    for (final stop in [.58, .77, .94]) {
      canvas.drawCircle(
        Offset(size.width * stop, size.height * (.59 - (.13 * stop))),
        2.5 + (3 * near),
        Paint()..color = Colors.white.withValues(alpha: .17 * near),
      );
    }
  }

  // Kept only while FIX13 remains source-reconstructable. FIX14 never calls it.
  // ignore: unused_element
  void _paintSceneNarrative(Canvas canvas, Size size) {
    final feature = view == BuyV2View.account
        ? ('Your account', 'Purchases & profile')
        : switch (destination) {
            BuyV2Destination.shop => (
              'Everyday shop',
              'Plan the monthly basket',
            ),
            BuyV2Destination.wholesale => (
              'Wholesale supply',
              'Flexible restocking',
            ),
            BuyV2Destination.medicine => (
              'Everyday care',
              'Prescription centre',
            ),
            BuyV2Destination.orders => ('Orders & delivery', 'Purchases'),
          };
    final accent = switch (destination) {
      BuyV2Destination.shop => BuyV2Colors.orange,
      BuyV2Destination.wholesale => BuyV2Colors.green,
      BuyV2Destination.medicine => BuyV2Colors.green,
      BuyV2Destination.orders => BuyV2Colors.orange,
    };
    final eyebrowArrival = _phase(.60, .76);
    final titleArrival = _phase(.70, .92);
    final x = math.max(114.0, size.width * .30);
    final maxWidth = math.max(106.0, size.width * .48);
    final vanishing = Offset(size.width * .72, size.height * .43);
    final clip = Path()
      ..moveTo(x - 8, 5)
      ..lineTo(x + maxWidth + 12, 1)
      ..lineTo(x + maxWidth - 2, size.height - 4)
      ..lineTo(x - 15, size.height)
      ..close();
    canvas.save();
    canvas.clipPath(clip);

    final contextWord = switch (destination) {
      BuyV2Destination.shop => 'SHOP',
      BuyV2Destination.wholesale => 'SUPPLY',
      BuyV2Destination.medicine => 'CARE',
      BuyV2Destination.orders => 'ORDERS',
    };
    final contextPainter = TextPainter(
      text: TextSpan(
        text: contextWord,
        style: TextStyle(
          color: Colors.white.withValues(alpha: .055 * titleArrival),
          fontSize: math.min(32.0, size.height * .40),
          fontFamily: 'Inter',
          height: 1,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth + 20);
    final contextPosition = Offset.lerp(
      vanishing,
      Offset(x, size.height * .48),
      titleArrival,
    )!;
    canvas.save();
    canvas.translate(contextPosition.dx, contextPosition.dy);
    final contextScale = .20 + (.80 * titleArrival);
    canvas.scale(contextScale, contextScale);
    contextPainter.paint(canvas, Offset.zero);
    canvas.restore();

    final eyebrowPosition = Offset.lerp(
      vanishing,
      Offset(x, 7),
      eyebrowArrival,
    )!;
    canvas.save();
    canvas.translate(eyebrowPosition.dx, eyebrowPosition.dy);
    canvas.skew(-.045 - (.08 * (1 - eyebrowArrival)), 0);
    final eyebrowScale = .30 + (.70 * eyebrowArrival);
    canvas.scale(eyebrowScale, eyebrowScale);
    _paintNarrativeText(
      canvas,
      feature.$1,
      Offset.zero,
      fontSize: 9,
      opacity: eyebrowArrival,
      color: accent,
      maxWidth: maxWidth,
      fontWeight: FontWeight.w800,
    );
    canvas.restore();

    final titlePosition = Offset.lerp(vanishing, Offset(x, 20), titleArrival)!;
    canvas.save();
    canvas.translate(titlePosition.dx, titlePosition.dy);
    canvas.skew(-.06 - (.09 * (1 - titleArrival)), 0);
    final titleScale = .26 + (.74 * titleArrival);
    canvas.scale(titleScale, titleScale);
    _paintNarrativeText(
      canvas,
      feature.$2,
      Offset.zero,
      fontSize: 10.8,
      opacity: titleArrival,
      color: Colors.white,
      maxWidth: maxWidth,
      fontWeight: FontWeight.w900,
    );
    canvas.restore();
    canvas.restore();
  }

  void _paintNarrativeText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required double opacity,
    required Color color,
    required double maxWidth,
    required FontWeight fontWeight,
  }) {
    if (opacity <= 0) return;
    final shadow = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: BuyV2Colors.navy.withValues(alpha: .86 * opacity),
          fontSize: fontSize,
          fontFamily: 'Inter',
          height: 1,
          fontWeight: fontWeight,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    shadow.paint(canvas, offset + const Offset(1.5, 2.5));
    final face = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: opacity),
          fontSize: fontSize,
          fontFamily: 'Inter',
          height: 1,
          fontWeight: fontWeight,
          letterSpacing: .05,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    face.paint(canvas, offset);
  }

  void _paintForegroundOcclusion(Canvas canvas, Size size, double near) {
    final bounds = Offset.zero & size;
    final topLens = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * .91, size.height * .16)
      ..lineTo(size.width * .10, size.height * .19)
      ..close();
    canvas.drawPath(
      topLens,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BuyV2Colors.navy.withValues(alpha: .46 * near),
            Colors.white.withValues(alpha: .055 * near),
            BuyV2Colors.navy.withValues(alpha: 0),
          ],
        ).createShader(bounds),
    );

    final leftLens = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .060, size.height * .16)
      ..lineTo(size.width * .045, size.height * .84)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      leftLens,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            BuyV2Colors.navy.withValues(alpha: .54 * near),
            Colors.white.withValues(alpha: .075 * near),
            BuyV2Colors.navy.withValues(alpha: 0),
          ],
        ).createShader(bounds),
    );

    final rightLens = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * .948, size.height * .84)
      ..lineTo(size.width * .958, size.height * .16)
      ..close();
    canvas.drawPath(
      rightLens,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            BuyV2Colors.navy.withValues(alpha: .56 * near),
            Colors.white.withValues(alpha: .070 * near),
            BuyV2Colors.navy.withValues(alpha: 0),
          ],
        ).createShader(bounds),
    );

    for (var lens = 0; lens < 3; lens += 1) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            size.width * (.78 + (.025 * lens)),
            size.height * (.44 + (.03 * lens)),
          ),
          width: size.width * (.42 + (lens * .24)),
          height: size.height * (.64 + (lens * .34)),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lens == 0 ? 1.15 : .75
          ..color = Colors.white.withValues(
            alpha: (.16 - (lens * .031)) * near,
          ),
      );
    }

    final cameraLip = Path()
      ..moveTo(size.width * .18, size.height)
      ..lineTo(size.width * .66, size.height * (.72 + (.08 * (1 - near))))
      ..lineTo(size.width, size.height * .76)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      cameraLip,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .055 * near),
            BuyV2Colors.navy.withValues(alpha: .20 * near),
            BuyV2Colors.navy.withValues(alpha: .52 * near),
          ],
        ).createShader(bounds),
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.18, -.12),
          radius: 1.22,
          stops: const [.42, .78, 1],
          colors: [
            BuyV2Colors.navy.withValues(alpha: 0),
            BuyV2Colors.navy.withValues(alpha: .10 * near),
            BuyV2Colors.navy.withValues(alpha: .38 * near),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  // Kept only while prior rejected evidence remains source-reconstructable.
  // ignore: unused_element
  void _paintPerspectiveStage(Canvas canvas, Size size, double settled) {
    final horizon = Offset(
      size.width * (.82 - (.05 * (1 - settled))),
      size.height * .42,
    );
    final floor = Path()
      ..moveTo(size.width * .28, size.height)
      ..lineTo(horizon.dx - 22, horizon.dy)
      ..lineTo(horizon.dx + 22, horizon.dy)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      floor,
      Paint()..color = Colors.white.withValues(alpha: .075),
    );
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .15);
    for (final foot in const [.34, .50, .66, .82, .98]) {
      canvas.drawLine(
        horizon,
        Offset(size.width * foot, size.height),
        rayPaint,
      );
    }
    canvas.drawCircle(
      horizon,
      3.5 + (3.5 * settled),
      Paint()..color = Colors.white.withValues(alpha: .24),
    );
    canvas.drawLine(
      Offset(size.width * .18, horizon.dy),
      Offset(size.width, horizon.dy),
      Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .18),
    );
  }

  // ignore: unused_element
  void _paintFarAtmosphere(Canvas canvas, Size size, double settled) {
    canvas.save();
    canvas.translate(size.width * .075 * (1 - settled), 0);
    canvas.scale(.92 + (.08 * settled), .92 + (.08 * settled));
    final farPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .13);
    for (final centre in const [.18, .46, .78, 1.04]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * centre, size.height * .52),
          width: size.height * 1.82,
          height: size.height * 1.04,
        ),
        farPaint,
      );
    }
    final horizonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = Colors.white.withValues(alpha: .11);
    for (var line = 0; line < 3; line += 1) {
      final y = size.height * (.16 + (line * .18));
      canvas.drawLine(
        Offset(size.width * .46, y),
        Offset(size.width, y - (line * 2)),
        horizonPaint,
      );
    }
    canvas.restore();
  }

  // ignore: unused_element
  void _paintContextWorld(
    Canvas canvas,
    Size size,
    double far,
    double middle,
    double near,
  ) {
    switch (destination) {
      case BuyV2Destination.shop:
        _paintRetailWorld(canvas, size, far, middle, near);
      case BuyV2Destination.wholesale:
        _paintWarehouseWorld(canvas, size, far, middle, near);
      case BuyV2Destination.medicine:
        _paintPharmacyWorld(canvas, size, far, middle, near);
      case BuyV2Destination.orders:
        _paintDeliveryWorld(canvas, size, far, middle, near);
    }
  }

  void _paintRetailWorld(
    Canvas canvas,
    Size size,
    double far,
    double middle,
    double near,
  ) {
    final shelfPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .16 * far);
    final shelfLeft = size.width * (.18 - (.04 * (1 - far)));
    final shelfRight = size.width * .96;
    for (final yFactor in const [.18, .43, .68]) {
      final y = size.height * yFactor;
      canvas.drawLine(Offset(shelfLeft, y), Offset(shelfRight, y), shelfPaint);
    }
    for (final xFactor in const [.28, .43, .58, .73, .88]) {
      final x = size.width * xFactor;
      canvas.drawLine(
        Offset(x, size.height * .12),
        Offset(x, size.height * .76),
        shelfPaint,
      );
    }
    final beltY = size.height * (.72 + (.08 * (1 - middle)));
    canvas.drawLine(
      Offset(size.width * .34, beltY),
      Offset(size.width, beltY),
      Paint()
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: .10 * middle),
    );
    _paintContextParcel(
      canvas,
      Offset(size.width * (.58 - (.13 * (1 - middle))), beltY - 13),
      18,
      BuyV2Colors.orange,
      middle,
    );
    _paintContextParcel(
      canvas,
      Offset(size.width * (.68 - (.20 * (1 - near))), beltY - 10),
      14,
      BuyV2Colors.green,
      near,
    );
  }

  void _paintWarehouseWorld(
    Canvas canvas,
    Size size,
    double far,
    double middle,
    double near,
  ) {
    final rackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: .20 * far);
    final aisleTop = size.height * .10;
    final aisleBottom = size.height * .82;
    for (final xFactor in const [.24, .40, .56, .72, .88]) {
      final x = size.width * (xFactor + (.04 * (1 - far)));
      canvas.drawLine(Offset(x, aisleTop), Offset(x, aisleBottom), rackPaint);
    }
    for (final yFactor in const [.24, .48, .72]) {
      final y = size.height * yFactor;
      canvas.drawLine(
        Offset(size.width * .20, y),
        Offset(size.width * .94, y),
        rackPaint,
      );
    }
    final palletY = size.height * .59;
    for (var index = 0; index < 3; index += 1) {
      _paintContextParcel(
        canvas,
        Offset(
          size.width * (.58 + (index * .07) + (.16 * (1 - middle))),
          palletY - (index.isOdd ? 8 : 0),
        ),
        18 + (index * 2),
        index == 1 ? BuyV2Colors.orange : BuyV2Colors.green,
        middle,
      );
    }
    canvas.drawLine(
      Offset(size.width * (.50 + (.22 * (1 - near))), size.height * .82),
      Offset(size.width * .92, size.height * .82),
      Paint()
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: .24 * near),
    );
  }

  void _paintPharmacyWorld(
    Canvas canvas,
    Size size,
    double far,
    double middle,
    double near,
  ) {
    final aperturePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: .20 * far);
    final centre = Offset(size.width * .62, size.height * .47);
    for (final scale in const [1.0, .72, .46]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centre.dx + (20 * (1 - far)), centre.dy),
          width: size.height * 2.2 * scale,
          height: size.height * 1.05 * scale,
        ),
        aperturePaint,
      );
    }
    final shelfPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .16 * middle);
    for (final yFactor in const [.22, .48, .74]) {
      canvas.drawLine(
        Offset(size.width * .36, size.height * yFactor),
        Offset(size.width * .94, size.height * yFactor),
        shelfPaint,
      );
    }
    for (var index = 0; index < 4; index += 1) {
      canvas.drawCircle(
        Offset(
          size.width * (.54 + (index * .07) - (.12 * (1 - near))),
          size.height * .68,
        ),
        4 + (index * .5),
        Paint()..color = index.isEven ? BuyV2Colors.green : BuyV2Colors.orange,
      );
    }
  }

  void _paintDeliveryWorld(
    Canvas canvas,
    Size size,
    double far,
    double middle,
    double near,
  ) {
    final routePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .22 * far);
    final route = Path()
      ..moveTo(size.width * .18, size.height * .72)
      ..cubicTo(
        size.width * .40,
        size.height * .08,
        size.width * .62,
        size.height * .90,
        size.width * .90,
        size.height * .24,
      );
    canvas.drawPath(route, routePaint);
    for (final point in const [.30, .50, .70, .88]) {
      canvas.drawCircle(
        Offset(size.width * point, size.height * (.62 - (.18 * point))),
        3 + (2 * middle),
        Paint()
          ..color = point == .70
              ? BuyV2Colors.orange
              : Colors.white.withValues(alpha: .62 * middle),
      );
    }
    _paintContextParcel(
      canvas,
      Offset(size.width * (.63 - (.18 * (1 - near))), size.height * .50),
      23,
      BuyV2Colors.orange,
      near,
    );
  }

  void _paintContextParcel(
    Canvas canvas,
    Offset origin,
    double extent,
    Color colour,
    double arrival,
  ) {
    if (arrival <= 0) return;
    final scale = .58 + (.42 * arrival);
    final rect = Rect.fromCenter(
      center: origin,
      width: extent * scale,
      height: extent * .74 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = colour,
    );
    canvas.drawLine(
      Offset(rect.left + (rect.width * .50), rect.top),
      Offset(rect.left + (rect.width * .50), rect.bottom),
      Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .52),
    );
  }

  // ignore: unused_element
  void _paintNearLens(Canvas canvas, Size size, double arrival) {
    final nearX = size.width * (.86 + (.20 * (1 - arrival)));
    final occlusion = Path()
      ..moveTo(nearX, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(nearX - 38, size.height)
      ..close();
    canvas.drawPath(
      occlusion,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .02 * arrival),
            Colors.white.withValues(alpha: .16 * arrival),
            Colors.white.withValues(alpha: .04 * arrival),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawLine(
      Offset(nearX - 38, size.height),
      Offset(nearX, 0),
      Paint()
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: .28 * arrival),
    );
  }

  // ignore: unused_element
  void _paintShop(Canvas canvas, Size size, double settled) {
    final compact = size.width < 360;
    final farTravel = size.width * .12 * (1 - settled);
    canvas.save();
    canvas.translate(-farTravel, 0);
    for (final x in const [.22, .38, .54]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * x, 8, 22, 29),
          const Radius.circular(5),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: .22),
      );
    }
    canvas.restore();

    final middleTravel = size.width * .20 * (1 - settled);
    final orangeSize = compact ? 12.0 : 18.0;
    final greenSize = compact ? 9.0 : 14.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * (compact ? .71 : .62) - middleTravel,
          9,
          orangeSize,
          orangeSize,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = BuyV2Colors.orange,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * (compact ? .76 : .69) - middleTravel,
          25,
          greenSize,
          greenSize,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = BuyV2Colors.green,
    );

    final nearTravel = size.width * .31 * (1 - settled);
    final basketWidth = compact ? 17.0 : 36.0;
    final basketLeft = size.width * (compact ? .80 : .78) - nearTravel;
    final basketPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .92);
    final basketGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .11);
    final basket = Path()
      ..moveTo(basketLeft, 18)
      ..lineTo(basketLeft + basketWidth * .17, 35)
      ..lineTo(basketLeft + basketWidth * .83, 35)
      ..lineTo(basketLeft + basketWidth, 18)
      ..close();
    canvas.drawPath(basket, basketGlow);
    canvas.drawPath(basket, basketPaint);
    if (compact) {
      canvas.drawArc(
        Rect.fromLTWH(basketLeft + 5, 10, 8, 11),
        math.pi,
        math.pi,
        false,
        basketPaint,
      );
    } else {
      canvas.drawArc(
        Rect.fromLTWH(basketLeft + 10, 8, 18, 18),
        math.pi,
        math.pi,
        false,
        basketPaint,
      );
    }
  }

  // ignore: unused_element
  void _paintWholesale(Canvas canvas, Size size, double settled) {
    final compact = size.width < 360;
    final farRise = 13 * (1 - settled);
    for (var index = 0; index < 3; index += 1) {
      final top = 7 + (index * 11) + farRise;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * (.24 + index * .05), top, 44, 8),
          const Radius.circular(4),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = Colors.white.withValues(alpha: .20),
      );
    }

    final middleRise = 20 * (1 - settled);
    final greenWidth = compact ? 18.0 : 30.0;
    final saffronWidth = compact ? 12.0 : 24.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * (compact ? .71 : .63),
          20 + middleRise,
          greenWidth,
          compact ? 14 : 20,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = BuyV2Colors.green,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * (compact ? .78 : .73),
          8 + middleRise,
          saffronWidth,
          compact ? 11 : 16,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = BuyV2Colors.orange,
    );

    final nearShift = size.width * .27 * (1 - settled);
    final palletLeft = size.width * (compact ? .82 : .78) + nearShift;
    final palletWidth = compact ? 12.0 : 34.0;
    final palletHeight = compact ? 22.0 : 28.0;
    final nearPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..color = Colors.white.withValues(alpha: .90);
    final palletGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..color = Colors.white.withValues(alpha: .11);
    canvas.drawRect(
      Rect.fromLTWH(palletLeft, 8, palletWidth, palletHeight),
      Paint()..color = Colors.white.withValues(alpha: .055),
    );
    canvas.drawRect(
      Rect.fromLTWH(palletLeft, 8, palletWidth, palletHeight),
      palletGlow,
    );
    canvas.drawRect(
      Rect.fromLTWH(palletLeft, 8, palletWidth, palletHeight),
      nearPaint,
    );
    canvas.drawLine(
      Offset(palletLeft, 8 + palletHeight * .48),
      Offset(palletLeft + palletWidth, 8 + palletHeight * .48),
      nearPaint,
    );
    canvas.drawLine(
      Offset(palletLeft + palletWidth * .5, 8),
      Offset(palletLeft + palletWidth * .5, 8 + palletHeight),
      nearPaint,
    );
  }

  // ignore: unused_element
  void _paintMedicine(Canvas canvas, Size size, double settled) {
    final compact = size.width < 360;
    final farScale = .72 + (.28 * settled);
    final farCentre = Offset(size.width * .35, size.height * .5);
    canvas.drawCircle(
      farCentre,
      27 * farScale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: .22),
    );

    final middleShift = 28 * (1 - settled);
    final crossCentre = Offset(
      size.width * (compact ? .72 : .67) + middleShift,
      23,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: crossCentre,
          width: compact ? 18 : 28,
          height: compact ? 7 : 10,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = BuyV2Colors.green,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: crossCentre,
          width: compact ? 7 : 10,
          height: compact ? 18 : 28,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = BuyV2Colors.green,
    );

    final capsuleLeft = size.width * (compact ? .78 : .76) - 34 * (1 - settled);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(capsuleLeft, 8, compact ? 14 : 30, compact ? 8 : 12),
        const Radius.circular(8),
      ),
      Paint()..color = BuyV2Colors.orange,
    );

    final nearShift = size.width * .25 * (1 - settled);
    final sheetLeft = size.width * (compact ? .82 : .78) + nearShift;
    final sheetWidth = compact ? 12.0 : 31.0;
    final sheetHeight = compact ? 24.0 : 31.0;
    final nearPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .92);
    final sheetBounds = RRect.fromRectAndRadius(
      Rect.fromLTWH(sheetLeft, 6, sheetWidth, sheetHeight),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      sheetBounds,
      Paint()..color = Colors.white.withValues(alpha: .06),
    );
    canvas.drawRRect(
      sheetBounds,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.8
        ..color = Colors.white.withValues(alpha: .11),
    );
    canvas.drawRRect(sheetBounds, nearPaint);
    for (final fraction in const [.32, .54, .76]) {
      canvas.drawLine(
        Offset(sheetLeft + sheetWidth * .22, 6 + sheetHeight * fraction),
        Offset(sheetLeft + sheetWidth * .78, 6 + sheetHeight * fraction),
        nearPaint,
      );
    }
  }

  // ignore: unused_element
  void _paintOrders(Canvas canvas, Size size, double settled) {
    final compact = size.width < 360;
    final farShift = -size.width * .10 * (1 - settled);
    final routePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .24);
    final route = Path()
      ..moveTo(size.width * .20 + farShift, 35)
      ..cubicTo(
        size.width * .38 + farShift,
        4,
        size.width * .58 + farShift,
        45,
        size.width * .76 + farShift,
        15,
      );
    canvas.drawPath(route, routePaint);

    final middleShift = size.width * .20 * (1 - settled);
    final parcelWidth = compact ? 16.0 : 26.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * (compact ? .71 : .62) - middleShift,
          12,
          parcelWidth,
          compact ? 18 : 25,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = BuyV2Colors.orange,
    );
    canvas.drawCircle(
      Offset(size.width * (compact ? .78 : .75) - middleShift, 34),
      compact ? 4 : 6,
      Paint()..color = BuyV2Colors.green,
    );

    final nearShift = size.width * .30 * (1 - settled);
    final vehicleLeft = size.width * (compact ? .82 : .78) + nearShift;
    final vehicleWidth = compact ? 13.0 : 34.0;
    final nearPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: .92);
    final vehicle = Path()
      ..moveTo(vehicleLeft, 13)
      ..lineTo(vehicleLeft + vehicleWidth * .70, 13)
      ..lineTo(vehicleLeft + vehicleWidth, compact ? 19 : 23)
      ..lineTo(vehicleLeft + vehicleWidth, compact ? 29 : 34)
      ..lineTo(vehicleLeft, compact ? 29 : 34)
      ..close();
    canvas.drawPath(
      vehicle,
      Paint()..color = Colors.white.withValues(alpha: .055),
    );
    canvas.drawPath(
      vehicle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: .11),
    );
    canvas.drawPath(vehicle, nearPaint);
    canvas.drawCircle(
      Offset(vehicleLeft + vehicleWidth * .24, compact ? 31 : 36),
      compact ? 2.2 : 3.5,
      nearPaint,
    );
    canvas.drawCircle(
      Offset(vehicleLeft + vehicleWidth * .82, compact ? 31 : 36),
      compact ? 2.2 : 3.5,
      nearPaint,
    );

    final sheenShift = size.width * (-.18 + (1.20 * settled));
    final sheen = Path()
      ..moveTo(sheenShift - 22, size.height)
      ..lineTo(sheenShift - 5, 0)
      ..lineTo(sheenShift + 9, 0)
      ..lineTo(sheenShift - 8, size.height)
      ..close();
    canvas.drawPath(
      sheen,
      Paint()..color = Colors.white.withValues(alpha: .10),
    );
  }

  @override
  bool shouldRepaint(_HeaderScenePainter oldDelegate) =>
      oldDelegate.destination != destination ||
      oldDelegate.view != view ||
      oldDelegate.progress != progress;
}

typedef _HeaderPromoAction = ({
  IconData icon,
  String label,
  String semantics,
  Color accent,
  VoidCallback onTap,
});

_HeaderPromoAction? _resolveHeaderPromoAction(
  BuildContext context,
  BuyV2Session session,
) {
  final activeOrders = session.orders
      .where((order) => order.status != BuyV2OrderStatus.delivered)
      .toList(growable: false);
  final activeOrder = activeOrders.isEmpty ? null : activeOrders.first;
  late final _HeaderPromoAction? action;
  if (session.view == BuyV2View.account) {
    action = (
      icon: Icons.receipt_long_outlined,
      label: 'View purchases',
      semantics: 'View purchases from your account',
      accent: BuyV2Colors.green,
      onTap: session.openOrdersFromAccount,
    );
  } else if (session.view != BuyV2View.catalogue) {
    action = null;
  } else {
    action = switch (session.destination) {
      BuyV2Destination.shop => (
        icon: Icons.shopping_basket_outlined,
        label: 'Plan basket',
        semantics: 'Plan a household basket',
        accent: BuyV2Colors.green,
        onTap: () => unawaited(showBuyV2HouseholdBasket(context, session)),
      ),
      BuyV2Destination.wholesale => (
        icon: Icons.inventory_2_outlined,
        label: 'Flexible packs',
        semantics: 'Show flexible minimum-order packs',
        accent: BuyV2Colors.green,
        onTap: () => session.chooseFilter('moq'),
      ),
      BuyV2Destination.medicine => (
        icon: Icons.medical_services_outlined,
        label: 'Prescription centre',
        semantics: 'Open the prescription centre',
        accent: BuyV2Colors.green,
        onTap: () => unawaited(showBuyV2PrescriptionSheet(context, session)),
      ),
      BuyV2Destination.orders when activeOrder != null => (
        icon: Icons.route_outlined,
        label: 'Track active order',
        semantics: 'Track active order ${activeOrder.id}',
        accent: BuyV2Colors.green,
        onTap: () => session.openTracking(activeOrder.id),
      ),
      BuyV2Destination.orders => (
        icon: Icons.receipt_long_outlined,
        label: 'View purchases',
        semantics: 'View your purchases',
        accent: BuyV2Colors.green,
        onTap: session.openOrders,
      ),
    };
  }
  return action;
}

class _BuySearchBand extends StatelessWidget {
  const _BuySearchBand({
    required this.session,
    required this.controller,
    required this.open,
    required this.onOpenChanged,
    required this.onScan,
    required this.onLocation,
    required this.scannerBusy,
  });

  final BuyV2Session session;
  final TextEditingController controller;
  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final VoidCallback onScan;
  final VoidCallback onLocation;
  final bool scannerBusy;

  @override
  Widget build(BuildContext context) {
    final hint = switch (session.destination) {
      BuyV2Destination.wholesale => 'Search bulk products and suppliers',
      BuyV2Destination.medicine => 'Search medicines and wellness',
      BuyV2Destination.orders => 'Search orders, sellers or ID',
      _ => 'Search products, brands and codes',
    };
    final showScanner = session.destination != BuyV2Destination.orders;
    final longQuery = open && controller.text.trim().length > 38;
    final accessibilityText = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    final longQueryBandHeight = accessibilityText ? 174.0 : 132.0;
    final longQueryControlHeight = accessibilityText ? 162.0 : 120.0;
    final expandCollapseDuration = BuyV2Motion.resolved(
      context,
      BuyV2Motion.expandCollapse,
    );
    final theme = BuyV2ThemeScope.of(context);
    return AnimatedContainer(
      key: const ValueKey('buy-search-band'),
      duration: expandCollapseDuration,
      curve: Curves.easeOutCubic,
      height: open ? (longQuery ? longQueryBandHeight : 82) : 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: theme.canvas,
        border: const Border(bottom: BorderSide(color: BuyV2Colors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              key: const ValueKey('buy-search-control'),
              duration: expandCollapseDuration,
              curve: Curves.easeOutCubic,
              height: open ? (longQuery ? longQueryControlHeight : 70) : 44,
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Row(
                children: [
                  Expanded(
                    child: open
                        ? TextField(
                            key: const ValueKey('buy-search-field'),
                            controller: controller,
                            autofocus: true,
                            onChanged: session.updateQuery,
                            textInputAction: TextInputAction.search,
                            minLines: 1,
                            maxLines: 6,
                            textAlignVertical: longQuery
                                ? TextAlignVertical.top
                                : TextAlignVertical.center,
                            style: const TextStyle(
                              color: BuyV2Colors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              hintText: hint,
                              hintStyle: const TextStyle(
                                color: BuyV2Colors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: BuyV2Colors.navy,
                                size: 21,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 42,
                                minHeight: 46,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) {
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : Semantics(
                            label: hint,
                            button: true,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onOpenChanged(true);
                              },
                              borderRadius: BorderRadius.circular(13),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.search_rounded,
                                      color: BuyV2Colors.navy,
                                      size: 21,
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        session.query.isEmpty
                                            ? hint
                                            : session.query,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: session.query.isEmpty
                                              ? BuyV2Colors.muted
                                              : BuyV2Colors.ink,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (open && controller.text.isNotEmpty)
                    IconButton(
                      key: const ValueKey('buy-search-clear'),
                      tooltip: 'Clear search',
                      onPressed: () {
                        controller.clear();
                        session.updateQuery('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: BuyV2Colors.muted,
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  if (showScanner && !open && controller.text.isEmpty)
                    IconButton(
                      key: const ValueKey('buy-open-scanner'),
                      tooltip: scannerBusy
                          ? 'Opening camera scanner'
                          : 'Open camera barcode scanner',
                      onPressed: scannerBusy ? null : onScan,
                      icon: scannerBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code_scanner_rounded, size: 20),
                      color: BuyV2Colors.navy,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 44,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  if (open)
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: IconButton(
                        key: const ValueKey('buy-search-close'),
                        tooltip: 'Finish search',
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          onOpenChanged(false);
                        },
                        icon: const Icon(Icons.check_rounded, size: 21),
                        color: BuyV2Colors.navy,
                        constraints: const BoxConstraints.tightFor(
                          width: 44,
                          height: 44,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!open) ...[
            const SizedBox(width: 6),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: BuyV2Colors.line),
              ),
              child: IconButton(
                key: const ValueKey('buy-change-location'),
                tooltip: 'Change delivery location',
                onPressed: onLocation,
                icon: const Icon(Icons.location_on_outlined, size: 22),
                color: BuyV2Colors.navy,
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BuyMiniCartBar extends StatelessWidget {
  const _BuyMiniCartBar({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final cartScope = switch (session.destination) {
      BuyV2Destination.shop => BuyV2CartScope.shop,
      BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
      BuyV2Destination.medicine => BuyV2CartScope.medicine,
      BuyV2Destination.orders => BuyV2CartScope.all,
    };
    final itemCount = session.destination == BuyV2Destination.orders
        ? session.itemCount
        : session.countForDestination(session.destination);
    final total = session.destination == BuyV2Destination.orders
        ? session.cartTotal
        : session.totalForDestination(session.destination);
    final itemLabel = itemCount == 1 ? 'item' : 'items';
    final cartMessage =
        session.cartAcknowledgement ?? '$itemCount $itemLabel ready';
    const title = 'Cart';
    void activate() {
      HapticFeedback.selectionClick();
      session.openCart(scope: cartScope);
    }

    return Semantics(
      key: const ValueKey('buy-compact-cart-indicator'),
      label: '$title, $cartMessage, ${buyV2Money(total)}. View cart',
      button: true,
      liveRegion: true,
      excludeSemantics: true,
      onTap: activate,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: activate,
          child: Container(
            height: 64,
            margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF111A36), BuyV2Colors.navy],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: Colors.white24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2B000050),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: BuyV2Colors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return BuyV2FiniteValueTransition(
                            key: ValueKey(
                              session.cartAcknowledgement == null
                                  ? 'buy-cart-summary'
                                  : 'buy-cart-acknowledgement',
                            ),
                            stateKey: '$cartMessage|$itemCount|$total',
                            text: cartMessage,
                            ownerSize: Size(constraints.maxWidth, 14),
                            textAlign: TextAlign.start,
                            duration: BuyV2Motion.contentChange,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                BuyV2FiniteValueTransition(
                  key: const ValueKey('buy-mini-cart-total-motion'),
                  stateKey: total,
                  text: buyV2Money(total),
                  ownerSize: const Size(74, 24),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 9),
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BuyV2Colors.orange,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View cart',
                        style: TextStyle(
                          color: BuyV2Colors.navy,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 1),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: BuyV2Colors.navy,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderContextButton extends StatelessWidget {
  const _HeaderContextButton({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final resolvedAction = _resolveHeaderPromoAction(context, session);
    if (resolvedAction == null) return const SizedBox(height: 56);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final motionKey =
        '${session.destination.name}-${session.view.name}-${resolvedAction.label}';
    return Semantics(
      label: resolvedAction.semantics,
      button: true,
      excludeSemantics: true,
      child: SizedBox(
        height: 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Opacity(
              key: ValueKey('buy-header-surface-copy-suppressed'),
              opacity: 0,
              child: SizedBox.shrink(),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: TweenAnimationBuilder<double>(
                key: ValueKey<String>('buy-header-action-motion-$motionKey'),
                tween: Tween<double>(begin: reduced ? 1 : 0, end: 1),
                duration: BuyV2Motion.resolved(
                  context,
                  const Duration(milliseconds: 3600),
                ),
                curve: const Interval(.62, .88, curve: Curves.easeOutCubic),
                builder: (context, progress, child) => Opacity(
                  opacity: progress,
                  child: Transform.translate(
                    offset: Offset(10 * (1 - progress), 5 * (1 - progress)),
                    child: child,
                  ),
                ),
                child: Tooltip(
                  message: resolvedAction.semantics,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey<String>(
                        'buy-header-context-cta-${session.destination.name}',
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        resolvedAction.onTap();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BuyV2Colors.navy.withValues(alpha: .86),
                              Colors.white.withValues(alpha: .18),
                              BuyV2Colors.navy.withValues(alpha: .66),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .58),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: .10),
                              blurRadius: 9,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              resolvedAction.icon,
                              color: Colors.white,
                              size: 17,
                            ),
                            Positioned(
                              right: 3,
                              bottom: 3,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: resolvedAction.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: .7,
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}

class _BuyNotice extends StatelessWidget {
  const _BuyNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('buy-live-notice'),
      liveRegion: true,
      label: message,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 160),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36, maxWidth: 248),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: BuyV2Colors.navy,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x29000050),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: BuyV2Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
