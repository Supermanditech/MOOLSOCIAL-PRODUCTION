import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
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
  });

  final BuyV2Session session;
  final BuyV2Destination initialDestination;
  final BuyV2View initialView;
  final BuyV2CartScope initialCartScope;
  final String? productId;
  final String? orderId;
  final BuyV2RecoveryKind? recoveryKind;
  final BuyV2ScannerLauncher scannerLauncher;

  @override
  State<BuyV2Screen> createState() => _BuyV2ScreenState();
}

class _BuyV2ScreenState extends State<BuyV2Screen> {
  Timer? _noticeTimer;
  Timer? _cartAcknowledgementTimer;
  Timer? _brandRevealTimer;
  int _surfaceTransitionPhase = 0;
  int _surfaceTransitionToken = 0;
  bool _scannerBusy = false;
  bool _searchOpen = false;
  late BuyV2Destination _lastSearchDestination;
  late BuyV2Destination _lastHeaderDestination;
  late BuyV2View _lastHeaderView;
  int _headerPaintGeneration = 0;
  bool _brandRevealInitialized = false;
  bool _brandExpanded = false;
  late final TextEditingController _searchController = TextEditingController(
    text: widget.session.query,
  );

  @override
  void initState() {
    super.initState();
    _applyInitialState();
    _lastSearchDestination = widget.session.destination;
    _lastHeaderDestination = widget.session.destination;
    _lastHeaderView = widget.session.view;
    widget.session.addListener(_sessionChanged);
  }

  @override
  void didUpdateWidget(covariant BuyV2Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_sessionChanged);
      widget.session.addListener(_sessionChanged);
      _lastHeaderDestination = widget.session.destination;
      _lastHeaderView = widget.session.view;
      _headerPaintGeneration += 1;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_brandRevealInitialized) return;
    _brandRevealInitialized = true;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _brandExpanded = true;
    _brandRevealTimer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _brandExpanded = false);
    });
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
      widget.session.openCart(scope: widget.initialCartScope);
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
    final headerChanged =
        _lastHeaderDestination != widget.session.destination ||
        _lastHeaderView != widget.session.view;
    final destinationChanged =
        _lastSearchDestination != widget.session.destination;
    int? transitionToken;
    if (headerChanged) {
      _lastHeaderDestination = widget.session.destination;
      _lastHeaderView = widget.session.view;
      _headerPaintGeneration += 1;
      _surfaceTransitionPhase = 1;
      _surfaceTransitionToken += 1;
      transitionToken = _surfaceTransitionToken;
    }
    if (destinationChanged) {
      _lastSearchDestination = widget.session.destination;
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
    if (headerChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || transitionToken != _surfaceTransitionToken) return;
        setState(() => _surfaceTransitionPhase = 2);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || transitionToken != _surfaceTransitionToken) return;
          setState(() {
            _surfaceTransitionPhase = 0;
            _headerPaintGeneration += 1;
          });
        });
      });
    }
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
    _brandRevealTimer?.cancel();
    widget.session.removeListener(_sessionChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final surfaceTheme = BuyV2ThemeSpec.resolve(
      session.destination,
      session.view,
    );
    return BuyV2ThemeScope(
      spec: surfaceTheme,
      child: PopScope<Object?>(
        canPop: !_searchOpen && !session.canHandleBack,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            HapticFeedback.selectionClick();
            if (_searchOpen) {
              FocusScope.of(context).unfocus();
              setState(() => _searchOpen = false);
            } else {
              session.goBack();
            }
          }
        },
        child: Scaffold(
          key: const ValueKey('buy-v2-screen'),
          backgroundColor: surfaceTheme.canvas,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: BuyV2Metrics.maxWidth,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: surfaceTheme.canvas),
                  child: Column(
                    children: [
                      RepaintBoundary(
                        key: ValueKey(
                          'buy-header-boundary-${session.destination.name}-'
                          '${session.view.name}-$_headerPaintGeneration',
                        ),
                        child: _BuyHeader(
                          session: session,
                          revealBrand: _brandExpanded,
                          onAddress: () =>
                              showBuyV2AddressSheet(context, session),
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
                          scannerBusy: _scannerBusy,
                        ),
                      Expanded(
                        child: _surfaceTransitionPhase == 1
                            ? _BuySurfaceProgress(
                                label: _transitionLabel(session),
                              )
                            : Stack(
                                children: [
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      ignoring: _surfaceTransitionPhase != 0,
                                      child: Opacity(
                                        opacity: _surfaceTransitionPhase == 2
                                            ? 0
                                            : 1,
                                        child: TickerMode(
                                          enabled: _surfaceTransitionPhase == 0,
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
                                  ),
                                  if (_surfaceTransitionPhase == 2)
                                    Positioned.fill(
                                      child: _BuySurfaceProgress(
                                        label: _transitionLabel(session),
                                      ),
                                    ),
                                  if (_surfaceTransitionPhase == 0)
                                    if (session.notice case final message?)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: _BuyNotice(message: message),
                                      ),
                                ],
                              ),
                      ),
                      if (_surfaceTransitionPhase == 0 &&
                          _showsMiniCart(session))
                        _BuyMiniCartBar(session: session),
                      _BuyDock(session: session),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _showsMiniCart(BuyV2Session session) =>
      session.itemCount > 0 &&
      (session.view == BuyV2View.product ||
          session.view == BuyV2View.catalogue);

  String _transitionLabel(BuyV2Session session) => switch (session.view) {
    BuyV2View.catalogue => session.destination.label,
    BuyV2View.product => 'Product',
    BuyV2View.cart => 'Cart',
    BuyV2View.checkout => 'Checkout',
    BuyV2View.confirmation => 'Order confirmation',
    BuyV2View.tracking => 'Order tracking',
    BuyV2View.orderItems => 'Order items',
    BuyV2View.assist => 'MoolSocial Assist',
    BuyV2View.account => 'Account',
    BuyV2View.recovery => 'Support',
  };

  Widget _currentView(BuyV2Session session) {
    if (session.destination == BuyV2Destination.orders &&
        session.view == BuyV2View.catalogue) {
      return BuyV2OrdersView(session: session);
    }
    return switch (session.view) {
      BuyV2View.catalogue => BuyV2CatalogueView(session: session),
      BuyV2View.product => BuyV2ProductView(session: session),
      BuyV2View.cart => BuyV2CartView(session: session),
      BuyV2View.checkout => BuyV2CheckoutView(session: session),
      BuyV2View.confirmation => BuyV2ConfirmationView(session: session),
      BuyV2View.tracking => BuyV2TrackingView(session: session),
      BuyV2View.orderItems => BuyV2OrderItemsView(session: session),
      BuyV2View.assist => BuyV2AssistView(session: session),
      BuyV2View.account => BuyV2AccountView(session: session),
      BuyV2View.recovery => BuyV2RecoveryView(session: session),
    };
  }
}

class _BuySurfaceProgress extends StatelessWidget {
  const _BuySurfaceProgress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final theme = BuyV2ThemeScope.of(context);
    return Semantics(
      key: const ValueKey('buy-destination-progress'),
      label: '$label selected',
      liveRegion: true,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BuyV2Colors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                reduceMotion
                    ? Icons.check_circle_outline_rounded
                    : Icons.auto_awesome_rounded,
                color: theme.accent,
                size: 20,
              ),
              if (!reduceMotion) ...[
                const SizedBox(width: 7),
                SizedBox(width: 28, child: BuyV2TricolourLine(height: 3)),
              ],
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: BuyV2Colors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyHeader extends StatelessWidget {
  const _BuyHeader({
    required this.session,
    required this.onAddress,
    required this.revealBrand,
  });

  final BuyV2Session session;
  final VoidCallback onAddress;
  final bool revealBrand;

  @override
  Widget build(BuildContext context) {
    final theme = BuyV2ThemeScope.of(context);
    return DecoratedBox(
      key: const ValueKey('buy-shared-header'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.headerStart, theme.headerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
            child: Row(
              children: [
                AnimatedContainer(
                  key: const ValueKey('buy-brand-tile'),
                  width: revealBrand ? 118 : 50,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  duration: BuyV2Motion.resolved(
                    context,
                    BuyV2Motion.brandReveal,
                  ),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.white70),
                  ),
                  child: _MoolSocialWordmark(expanded: revealBrand),
                ),
                Container(
                  width: 1,
                  height: 30,
                  margin: const EdgeInsets.only(left: 6, right: 7),
                  color: Colors.white24,
                ),
                Expanded(
                  child: _HeaderContextButton(
                    session: session,
                    onTap:
                        session.destination == BuyV2Destination.orders ||
                            session.view == BuyV2View.account
                        ? null
                        : onAddress,
                  ),
                ),
                const SizedBox(width: 2),
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
                      height: 44,
                      child: Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: BuyV2Colors.orange,
                                  width: 1.5,
                                ),
                              ),
                              child: const Text(
                                'DC',
                                style: TextStyle(
                                  color: BuyV2Colors.navy,
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
          const BuyV2TricolourLine(height: 2),
        ],
      ),
    );
  }
}

class _BuySearchBand extends StatelessWidget {
  const _BuySearchBand({
    required this.session,
    required this.controller,
    required this.open,
    required this.onOpenChanged,
    required this.onScan,
    required this.scannerBusy,
  });

  final BuyV2Session session;
  final TextEditingController controller;
  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final VoidCallback onScan;
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final theme = BuyV2ThemeScope.of(context);
    return AnimatedContainer(
      key: const ValueKey('buy-search-band'),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: open ? 60 : 56,
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
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: open ? 48 : 44,
              decoration: BoxDecoration(
                color: open ? const Color(0xFFF7F8FF) : Colors.white,
                borderRadius: BorderRadius.circular(open ? 24 : 14),
                border: Border.all(
                  color: open ? theme.accent : BuyV2Colors.line,
                ),
                boxShadow: [
                  BoxShadow(
                    color: open
                        ? const Color(0x10081745)
                        : const Color(0x0D000040),
                    blurRadius: open ? 12 : 8,
                    offset: Offset(0, open ? 4 : 3),
                  ),
                ],
              ),
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
                                vertical: 13,
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
                        style: IconButton.styleFrom(
                          foregroundColor: BuyV2Colors.navy,
                          backgroundColor: const Color(0xFFE9EDFC),
                          minimumSize: const Size.square(44),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 21),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showScanner && !open) ...[
            const SizedBox(width: 6),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: BuyV2Colors.line),
              ),
              child: IconButton(
                key: const ValueKey('buy-open-scanner'),
                tooltip: scannerBusy
                    ? 'Opening camera scanner'
                    : 'Open camera barcode scanner',
                onPressed: scannerBusy ? null : onScan,
                icon: scannerBusy
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_scanner_rounded, size: 22),
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
    final itemCount = session.itemCount;
    final total = session.cartTotal;
    final itemLabel = itemCount == 1 ? 'item' : 'items';
    final cartMessage =
        session.cartAcknowledgement ?? '$itemCount $itemLabel ready';
    const title = 'Cart';
    return Semantics(
      key: const ValueKey('buy-compact-cart-indicator'),
      label: '$title, $cartMessage, ${buyV2Money(total)}. View cart',
      button: true,
      liveRegion: true,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            session.openCart();
          },
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
                      AnimatedSwitcher(
                        duration: BuyV2Motion.resolved(
                          context,
                          BuyV2Motion.contentChange,
                        ),
                        child: Text(
                          cartMessage,
                          key: ValueKey(
                            session.cartAcknowledgement == null
                                ? 'buy-cart-summary'
                                : 'buy-cart-acknowledgement',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  buyV2Money(total),
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
  const _HeaderContextButton({required this.session, required this.onTap});

  final BuyV2Session session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = session.view == BuyV2View.account
        ? (
            Icons.person_outline_rounded,
            'MoolSocial · Your account',
            'Purchases & profile',
          )
        : switch (session.destination) {
            BuyV2Destination.shop => (
              Icons.location_on_outlined,
              'MoolSocial · Deliver to',
              session.selectedAddressOrNull?.compactLine ??
                  'Choose delivery address',
            ),
            BuyV2Destination.wholesale => (
              Icons.storefront_outlined,
              'MoolSocial · Buying for',
              'Shree Balaji Retail',
            ),
            BuyV2Destination.medicine => (
              Icons.local_pharmacy_outlined,
              'MoolSocial · Licensed pharmacy',
              session.selectedAddressOrNull?.compactLine ??
                  'Choose delivery address',
            ),
            BuyV2Destination.orders => (
              Icons.local_shipping_outlined,
              'MoolSocial · Purchases',
              'Orders & delivery',
            ),
          };
    return Semantics(
      label: '${content.$2}, ${content.$3}',
      button: onTap != null,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Icon(content.$1, color: BuyV2Colors.orange, size: 16),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 8,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      content.$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.expand_more_rounded,
                  color: Colors.white54,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoolSocialWordmark extends StatelessWidget {
  const _MoolSocialWordmark({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MoolSocial',
      header: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              key: ValueKey('buy-brand-mark'),
              width: 32,
              height: 24,
              child: CustomPaint(painter: _MoolSocialMarkPainter()),
            ),
            if (expanded) ...[
              const SizedBox(width: 5),
              const Flexible(
                child: Text(
                  'MoolSocial',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    color: BuyV2Colors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoolSocialMarkPainter extends CustomPainter {
  const _MoolSocialMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final leftPeak = Offset(size.width * .28, size.height * .29);
    final centre = Offset(size.width * .5, size.height * .76);
    final rightPeak = Offset(size.width * .72, size.height * .29);
    final left = Paint()
      ..color = BuyV2Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final right = Paint()
      ..color = BuyV2Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final leftPath = Path()
      ..moveTo(size.width * .09, size.height * .86)
      ..lineTo(leftPeak.dx, leftPeak.dy)
      ..lineTo(centre.dx, centre.dy);
    final rightPath = Path()
      ..moveTo(centre.dx, centre.dy)
      ..lineTo(rightPeak.dx, rightPeak.dy)
      ..lineTo(size.width * .91, size.height * .86);
    canvas
      ..drawPath(leftPath, left)
      ..drawPath(rightPath, right)
      ..drawCircle(
        Offset(leftPeak.dx, size.height * .14),
        2.3,
        Paint()..color = BuyV2Colors.navy,
      )
      ..drawCircle(
        Offset(rightPeak.dx, size.height * .14),
        2.3,
        Paint()..color = BuyV2Colors.navy,
      );
  }

  @override
  bool shouldRepaint(covariant _MoolSocialMarkPainter oldDelegate) => false;
}

class _BuyDock extends StatefulWidget {
  const _BuyDock({required this.session});

  final BuyV2Session session;

  @override
  State<_BuyDock> createState() => _BuyDockState();
}

class _BuyDockState extends State<_BuyDock> {
  bool _showPrimaryActions = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final theme = BuyV2ThemeScope.of(context);
    final items = _showPrimaryActions
        ? <({String label, IconData icon, VoidCallback onTap, bool active})>[
            (
              label: 'Social',
              icon: Icons.people_alt_outlined,
              onTap: () => context.go('/app/social'),
              active: false,
            ),
            (
              label: 'Buy',
              icon: Icons.shopping_bag_outlined,
              onTap: () => setState(() => _showPrimaryActions = false),
              active: true,
            ),
            (
              label: 'Eat',
              icon: Icons.restaurant_outlined,
              onTap: () => context.go('/app/eat'),
              active: false,
            ),
            (
              label: 'Ride',
              icon: Icons.directions_bike_outlined,
              onTap: () => context.go('/app/ride'),
              active: false,
            ),
            (
              label: 'Book',
              icon: Icons.calendar_month_outlined,
              onTap: () => context.go('/app/book'),
              active: false,
            ),
            (
              label: 'Pay',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => context.go('/app/pay'),
              active: false,
            ),
            (
              label: 'Work',
              icon: Icons.work_outline_rounded,
              onTap: () => context.go('/app/work'),
              active: false,
            ),
          ]
        : <({String label, IconData icon, VoidCallback onTap, bool active})>[
            (
              label: 'Mool',
              icon: Icons.grid_view_rounded,
              onTap: () => setState(() => _showPrimaryActions = true),
              active: false,
            ),
            (
              label: 'Shop',
              icon: Icons.shopping_bag_outlined,
              onTap: () => session.openDestination(BuyV2Destination.shop),
              active: session.destination == BuyV2Destination.shop,
            ),
            (
              label: 'Wholesale',
              icon: Icons.inventory_2_outlined,
              onTap: () => session.openDestination(BuyV2Destination.wholesale),
              active: session.destination == BuyV2Destination.wholesale,
            ),
            (
              label: 'Medicine',
              icon: Icons.medication_outlined,
              onTap: () => session.openDestination(BuyV2Destination.medicine),
              active: session.destination == BuyV2Destination.medicine,
            ),
            (
              label: 'Orders',
              icon: Icons.receipt_long_outlined,
              onTap: session.openOrders,
              active:
                  session.destination == BuyV2Destination.orders &&
                  session.view != BuyV2View.assist,
            ),
            (
              label: 'Chat',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: session.view == BuyV2View.assist
                  ? session.closeAssist
                  : session.openAssist,
              active: session.view == BuyV2View.assist,
            ),
          ];

    return SizedBox(
      key: const ValueKey('buy-persistent-dock'),
      height: BuyV2Metrics.dockHeight,
      child: Material(
        color: Colors.white,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: BuyV2Colors.line)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: Semantics(
                      label: item.label,
                      selected: item.active,
                      button: true,
                      child: InkWell(
                        key: ValueKey(
                          _showPrimaryActions
                              ? 'buy-mool-${item.label.toLowerCase()}'
                              : 'buy-dock-${item.label.toLowerCase()}',
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          item.onTap();
                        },
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                          decoration: BoxDecoration(
                            color: item.active
                                ? theme.softAccent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: item.active
                                ? Border.all(color: const Color(0x2FFF9933))
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 140),
                                width: item.active ? 16 : 0,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: item.active
                                      ? theme.accent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Icon(
                                item.icon,
                                size: _showPrimaryActions ? 17 : 18,
                                color: item.active
                                    ? BuyV2Colors.navy
                                    : !_showPrimaryActions &&
                                          item.label == 'Mool'
                                    ? BuyV2Colors.navy
                                    : BuyV2Colors.muted,
                              ),
                              const SizedBox(height: 1),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      softWrap: false,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: item.active
                                            ? BuyV2Colors.navy
                                            : !_showPrimaryActions &&
                                                  item.label == 'Mool'
                                            ? BuyV2Colors.navy
                                            : BuyV2Colors.muted,
                                        fontSize: _showPrimaryActions ? 7.5 : 8,
                                        height: .9,
                                        fontWeight: FontWeight.w800,
                                      ),
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
