import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_motion_primitives.dart';
import '../../features/buy/buy_v2_content_contracts.dart';
import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
import '../../features/journey01/journey_services.dart';
import '../profile/global_profile_panel_v2.dart';
import '../universal/mool_global_navigation_v2.dart';
import 'buy_v2_chat_route_adapter.dart';
import 'buy_v2_catalogue.dart';
import 'buy_v2_design.dart';
import 'buy_v2_invoice.dart';
import 'buy_v2_invoice_downloader.dart';
import 'buy_v2_scanner.dart';
import 'buy_v2_views.dart';

String buyV2CustomerPaymentProviderLabel(
  String providerSlug, {
  required String fallback,
}) {
  final normalized = providerSlug.trim().toLowerCase();
  return switch (normalized) {
    'phonepe' => 'PhonePe',
    'paytm' => 'Paytm',
    'pine-labs' || 'pinelabs' => 'Pine Labs',
    _ when normalized.isNotEmpty =>
      normalized
          .split('-')
          .map(
            (part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}',
          )
          .join(' '),
    _ => fallback,
  };
}

class BuyV2Screen extends StatefulWidget {
  const BuyV2Screen({
    super.key,
    required this.session,
    this.accountIdentity,
    this.accountAuthenticated = false,
    this.initialDestination = BuyV2Destination.shop,
    this.initialOffersActive = false,
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
    this.invoiceDownloader = saveBuyV2InvoiceToDevice,
    this.paymentHandoff,
    this.liveDeliveryMapBuilder,
    this.offersSource = const BuyV2CataloguePublishedOffersSource(),
    this.wholesaleTradeDecisionAdapter =
        const BuyV2UnavailableWholesaleTradeDecisionAdapter(),
  });

  final BuyV2Session session;
  final AuthenticatedAccountIdentity? accountIdentity;
  final bool accountAuthenticated;
  final BuyV2Destination initialDestination;
  final bool initialOffersActive;
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
  final BuyV2InvoiceDownloader? invoiceDownloader;
  final BuyV2PaymentHandoff? paymentHandoff;
  final BuyV2LiveDeliveryMapBuilder? liveDeliveryMapBuilder;
  final BuyV2PublishedOffersSource offersSource;
  final BuyV2WholesaleTradeDecisionAdapter wholesaleTradeDecisionAdapter;

  @override
  State<BuyV2Screen> createState() => _BuyV2ScreenState();
}

class _BuyV2ScreenState extends State<BuyV2Screen> {
  final MoolGlobalNavigationController _moolNavigationController =
      MoolGlobalNavigationController();
  Timer? _noticeTimer;
  Timer? _cartAcknowledgementTimer;
  bool _scannerBusy = false;
  bool _searchOpen = false;
  bool _offersActive = false;
  bool _quickTrackerMinimized = true;
  bool _quickTrackerHidden = false;
  bool _quickTrackerSoundOnArrival = false;
  Offset? _miniCartPosition;
  String? _presentedQuickOrderId;
  BuyV2OrderStatus? _presentedQuickOrderStatus;
  final Map<BuyV2Destination, BuyV2Product> _storeBrowseAnchors = {};
  BuyV2Product? get _storeBrowseAnchor =>
      _storeBrowseAnchors.isEmpty ? null : _storeBrowseAnchors.values.last;
  BuyV2NavigationMotionDirection _surfaceMotionDirection =
      BuyV2NavigationMotionDirection.replace;
  late BuyV2GstInvoiceController _gstInvoiceController;
  late BuyV2Destination _lastSearchDestination;
  late final TextEditingController _searchController = TextEditingController(
    text: widget.session.query,
  );

  @override
  void initState() {
    super.initState();
    _gstInvoiceController = BuyV2GstInvoiceController(
      store: widget.session.gstInvoiceProfileStore,
    );
    _applyInitialState();
    unawaited(_restoreSessionState());
    _lastSearchDestination = widget.session.destination;
    widget.session.addListener(_sessionChanged);
  }

  @override
  void didUpdateWidget(covariant BuyV2Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    var restoreState = false;
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_sessionChanged);
      widget.session.addListener(_sessionChanged);
      restoreState = true;
    }
    if (oldWidget.session.gstInvoiceProfileStore !=
        widget.session.gstInvoiceProfileStore) {
      _gstInvoiceController.dispose();
      _gstInvoiceController = BuyV2GstInvoiceController(
        store: widget.session.gstInvoiceProfileStore,
      );
      restoreState = true;
    }
    if (restoreState) unawaited(_restoreSessionState());
    if (oldWidget.initialDestination != widget.initialDestination ||
        oldWidget.initialOffersActive != widget.initialOffersActive ||
        oldWidget.initialView != widget.initialView ||
        oldWidget.initialCartScope != widget.initialCartScope ||
        oldWidget.productId != widget.productId ||
        oldWidget.orderId != widget.orderId ||
        oldWidget.recoveryKind != widget.recoveryKind) {
      _applyInitialState();
    }
  }

  Future<void> _restoreSessionState() async {
    await widget.session.restoreCommerce();
    await widget.session.restoreCustomerState();
    await widget.session.restoreSavedProducts();
    await widget.session.restoreOrderAlerts();
    await widget.session.restoreShoppingAlerts();
    await widget.session.refreshCartBenefits();
    await widget.session.refreshCheckoutQuote();
    await widget.session.refreshCommercialPaymentTerms();
    await _gstInvoiceController.restore();
    if (widget.session.businessVerified) {
      _gstInvoiceController.applySavedBusinessProfile();
    }
  }

  void _applyInitialState() {
    _offersActive = widget.initialOffersActive;
    final productId = widget.productId;
    final orderId = widget.orderId;
    final recoveryKind = widget.recoveryKind;
    final storeReturnId = widget.session.takeStoreReturnAnchor(
      routeProductId: productId,
    );
    if (storeReturnId != null) {
      widget.session.destination = widget.initialDestination;
      widget.session.view = BuyV2View.catalogue;
      widget.session.selectedProductId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final anchor = widget.session.findProduct(storeReturnId);
        if (anchor != null) _openPartnerCatalogue(anchor);
      });
    } else if (recoveryKind != null) {
      widget.session.destination = widget.initialDestination;
      widget.session.openRecovery(recoveryKind);
    } else if (productId != null) {
      widget.session.openProduct(productId);
    } else if (orderId != null && widget.initialView == BuyV2View.orderItems) {
      widget.session.openOrderItems(orderId);
    } else if (orderId != null &&
        (widget.initialView == BuyV2View.tracking ||
            widget.initialView == BuyV2View.assist)) {
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
    _surfaceMotionDirection = widget.session.navigationMotionDirection;
    final quickOrder = widget.session.activeQuickDeliveryOrder;
    final quickOrderId = quickOrder?.id;
    if (quickOrderId != _presentedQuickOrderId) {
      _presentedQuickOrderId = quickOrderId;
      _presentedQuickOrderStatus = quickOrder?.status;
      _quickTrackerMinimized = true;
      _quickTrackerHidden = false;
    } else if (_quickTrackerSoundOnArrival &&
        quickOrder != null &&
        quickOrder.status != _presentedQuickOrderStatus &&
        (quickOrder.status == BuyV2OrderStatus.arriving ||
            quickOrder.status == BuyV2OrderStatus.delivered)) {
      unawaited(SystemSound.play(SystemSoundType.alert));
    }
    _presentedQuickOrderStatus = quickOrder?.status;
    if (_offersActive &&
        widget.session.view == BuyV2View.catalogue &&
        widget.session.destination != BuyV2Destination.shop) {
      _offersActive = false;
    }
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

  GlobalProfileContextAction _buyProfileContext(BuyV2Session session) {
    void prepareDestinationChange() {
      setState(() {
        _offersActive = false;
        _searchOpen = false;
      });
    }

    void openOrders() {
      prepareDestinationChange();
      session.openOrders();
    }

    void openCart(BuyV2Destination destination) {
      prepareDestinationChange();
      session.openDestination(destination);
      session.openCart(
        scope: switch (destination) {
          BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
          BuyV2Destination.medicine => BuyV2CartScope.medicine,
          BuyV2Destination.shop ||
          BuyV2Destination.orders => BuyV2CartScope.shop,
        },
      );
    }

    void openCatalogue(BuyV2Destination destination) {
      prepareDestinationChange();
      session.openDestination(destination);
    }

    if (_offersActive) {
      return GlobalProfileContextAction(
        id: 'shop-offers',
        title: 'Shop offers',
        detail: 'Review current offers and continue with eligible products.',
        actionLabel: 'Open offers',
        icon: Icons.local_offer_outlined,
        accentColor: BuyV2Colors.orange,
        gradientColors: const [BuyV2Colors.navy, BuyV2Colors.orange],
        onPressed: _openOffers,
      );
    }

    final destination = session.activeDockDestination;
    if (destination == BuyV2Destination.orders) {
      final activeOrders = session.activeOrderCount;
      final deliveredOrders = session.deliveredOrderCount;
      return GlobalProfileContextAction(
        id: 'shop-orders',
        title: 'Your Shop orders',
        detail:
            '$activeOrders active · $deliveredOrders delivered orders are ready to review.',
        actionLabel: 'Open orders',
        icon: Icons.receipt_long_outlined,
        accentColor: BuyV2Colors.orange,
        gradientColors: const [BuyV2Colors.navy, BuyV2Colors.orange],
        onPressed: openOrders,
      );
    }

    final activeOrders = session.activeOrderCount;
    if (destination == BuyV2Destination.shop && activeOrders > 0) {
      return GlobalProfileContextAction(
        id: 'shop-active-orders',
        title: activeOrders == 1
            ? 'Your active Shop order'
            : 'Your Shop orders',
        detail: activeOrders == 1
            ? 'One order is ready to track from purchase to delivery.'
            : '$activeOrders active orders are ready to track.',
        actionLabel: 'Open orders',
        icon: Icons.local_shipping_outlined,
        accentColor: BuyV2Colors.orange,
        gradientColors: const [BuyV2Colors.navy, BuyV2Colors.orange],
        onPressed: openOrders,
      );
    }

    final itemCount = session.countForDestination(destination);
    final accent = switch (destination) {
      BuyV2Destination.wholesale => BuyV2Colors.royal,
      BuyV2Destination.medicine => BuyV2Colors.green,
      BuyV2Destination.shop || BuyV2Destination.orders => BuyV2Colors.orange,
    };
    final icon = switch (destination) {
      BuyV2Destination.wholesale => Icons.inventory_2_outlined,
      BuyV2Destination.medicine => Icons.medication_outlined,
      BuyV2Destination.shop ||
      BuyV2Destination.orders => Icons.shopping_bag_outlined,
    };
    if (itemCount > 0) {
      return GlobalProfileContextAction(
        id: '${destination.name}-cart',
        title: 'Your ${destination.label} cart',
        detail:
            '$itemCount ${itemCount == 1 ? 'item' : 'items'} · '
            '${buyV2Money(session.totalForDestination(destination))}',
        actionLabel: 'Open cart',
        icon: icon,
        accentColor: accent,
        gradientColors: [BuyV2Colors.navy, accent],
        onPressed: () => openCart(destination),
      );
    }

    final savedCount = session.savedCountFor(destination);
    return GlobalProfileContextAction(
      id: '${destination.name}-discovery',
      title: savedCount > 0
          ? 'Continue ${destination.label}'
          : switch (destination) {
              BuyV2Destination.wholesale => 'Source wholesale products',
              BuyV2Destination.medicine => 'Browse medicine and care',
              BuyV2Destination.shop ||
              BuyV2Destination.orders => 'Shop everyday needs',
            },
      detail: savedCount > 0
          ? '$savedCount saved ${savedCount == 1 ? 'product is' : 'products are'} ready when you return.'
          : switch (destination) {
              BuyV2Destination.wholesale =>
                'Compare bulk packs, minimum orders and delivery promises.',
              BuyV2Destination.medicine =>
                'Review medicine information and prescription requirements.',
              BuyV2Destination.shop || BuyV2Destination.orders =>
                'Browse retail packs, trusted sellers and delivery promises.',
            },
      actionLabel: 'Browse ${destination.label}',
      icon: destination == BuyV2Destination.shop
          ? Icons.storefront_outlined
          : icon,
      accentColor: accent,
      gradientColors: [BuyV2Colors.navy, accent],
      onPressed: () => openCatalogue(destination),
    );
  }

  void _openBuyProfile() {
    HapticFeedback.selectionClick();
    setState(() => _searchOpen = false);
    unawaited(
      showGlobalProfilePanelV2(
        context,
        accountAuthenticated: widget.accountAuthenticated,
        contextAction: _buyProfileContext(widget.session),
        onOpenRoute: (route) {
          context.push(route);
        },
      ),
    );
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _cartAcknowledgementTimer?.cancel();
    widget.session.removeListener(_sessionChanged);
    _searchController.dispose();
    _gstInvoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final careNavigation =
        session.activeDockDestination == BuyV2Destination.medicine;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final surfaceTheme = BuyV2ThemeSpec.resolve(
      session.destination,
      session.view,
    );
    final quickOrder = session.view == BuyV2View.tracking
        ? null
        : session.activeQuickDeliveryOrder;
    final quietOrder = quickOrder == null && session.view != BuyV2View.tracking
        ? session.activeQuietDeliveryOrder
        : null;
    return BuyV2ThemeScope(
      spec: surfaceTheme,
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            HapticFeedback.selectionClick();
            if (_moolNavigationController.isOpen) {
              unawaited(_moolNavigationController.close());
            } else if (_searchOpen) {
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
                          if (session.view == BuyV2View.catalogue)
                            _BuySearchBand(
                              session: session,
                              offersActive: _offersActive,
                              controller: _searchController,
                              open: _searchOpen,
                              onOpenChanged: (value) =>
                                  setState(() => _searchOpen = value),
                              onScan: _scanProduct,
                              onLocation: () =>
                                  showBuyV2AddressSheet(context, session),
                              onAccount: _openBuyProfile,
                              scannerBusy: _scannerBusy,
                            ),
                          if (session.activeShoppingIntent != null &&
                              session.destination != BuyV2Destination.orders &&
                              session.destination != BuyV2Destination.medicine)
                            BuyV2ShoppingIntentBar(session: session),
                          if (quickOrder != null && !_quickTrackerHidden)
                            _BuyQuickDeliveryStatusBar(
                              order: quickOrder,
                              minimized: _quickTrackerMinimized,
                              soundOnArrival: _quickTrackerSoundOnArrival,
                              onMinimizedChanged: (value) => setState(
                                () => _quickTrackerMinimized = value,
                              ),
                              onHiddenChanged: (value) =>
                                  setState(() => _quickTrackerHidden = value),
                              onSoundChanged: (value) => setState(
                                () => _quickTrackerSoundOnArrival = value,
                              ),
                              onKeepOnScreen: () => setState(() {
                                _quickTrackerHidden = false;
                                _quickTrackerMinimized = true;
                              }),
                              onOpen: () => session.openTracking(quickOrder.id),
                            )
                          else if (quietOrder != null)
                            _BuyQuietDeliveryStatusBar(
                              order: quietOrder,
                              onOpen: () => session.openTracking(quietOrder.id),
                            ),
                          Expanded(
                            child: Stack(
                              key: const ValueKey(
                                'buy-navigation-overlay-stack',
                              ),
                              children: [
                                Positioned.fill(
                                  child: _BuyNavigationSurfaceOwner(
                                    key: ObjectKey(session),
                                    stateKey: session.navigationMotionSequence,
                                    direction: _surfaceMotionDirection,
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
                                              !_offersActive &&
                                              session.destination !=
                                                  BuyV2Destination.orders
                                          ? BuyV2SearchResultsView(
                                              session: session,
                                            )
                                          : _currentView(session),
                                    ),
                                  ),
                                ),
                                if (quickOrder != null && _quickTrackerHidden)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Semantics(
                                        key: const ValueKey(
                                          'buy-quick-delivery-status-hidden',
                                        ),
                                        label: 'Live delivery hidden',
                                        button: true,
                                        child: Material(
                                          color: Colors.white,
                                          shape: const CircleBorder(
                                            side: BorderSide(
                                              color: BuyV2Colors.royal,
                                            ),
                                          ),
                                          child: IconButton(
                                            key: const ValueKey(
                                              'buy-quick-delivery-restore',
                                            ),
                                            tooltip: 'Restore live delivery',
                                            onPressed: () => setState(
                                              () => _quickTrackerHidden = false,
                                            ),
                                            color: BuyV2Colors.royal,
                                            icon: const Icon(
                                              Icons.bolt_rounded,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!keyboardVisible && _showsMiniCart(session))
                                  Positioned.fill(
                                    child: _BuyMiniCartBar(
                                      session: session,
                                      aggregate: _offersActive,
                                      initialPosition: _miniCartPosition,
                                      onPositionChanged: (position) {
                                        _miniCartPosition = position;
                                      },
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: keyboardVisible
              ? null
              : MoolDestinationNavigationV2(
                  activeId: careNavigation ? 'book' : 'buy',
                  destinationLabel: careNavigation ? 'Care' : 'Shop',
                  familyRootSelected:
                      !careNavigation &&
                      !_offersActive &&
                      session.activeDockDestination == BuyV2Destination.shop,
                  selectedLocalIndex: careNavigation
                      ? 1
                      : _offersActive
                      ? 2
                      : switch (session.activeDockDestination) {
                          BuyV2Destination.orders => 1,
                          _ => 0,
                        },
                  localActionCount: 3,
                  localNavigation: careNavigation
                      ? _buildCareLocalNavigation()
                      : _buildBuyLocalNavigation(session),
                  onOpenMool: _openGlobalMool,
                  onOpenAction: _openGlobalAction,
                  onOpenChat: _openShopChat,
                  moolNavigationController: _moolNavigationController,
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
      semanticLabel: 'Shop choices: Wholesale, Orders and Offers.',
      activeId: _offersActive ? 'offers' : active.name,
      actions: [
        MoolLocalNavigationAction(
          keyName: 'buy-local-tab-wholesale',
          id: BuyV2Destination.wholesale.name,
          label: 'Wholesale',
          icon: Icons.inventory_2_outlined,
          onPressed: () => _openBuyDestination(BuyV2Destination.wholesale),
        ),
        MoolLocalNavigationAction(
          keyName: 'buy-local-tab-orders',
          id: BuyV2Destination.orders.name,
          label: 'Orders',
          icon: Icons.receipt_long_outlined,
          onPressed: () => _openBuyDestination(BuyV2Destination.orders),
        ),
        MoolLocalNavigationAction(
          keyName: 'buy-local-tab-offers',
          id: 'offers',
          label: 'Offers',
          icon: Icons.local_offer_outlined,
          onPressed: _openOffers,
        ),
      ],
    );
  }

  void _openBuyDestination(BuyV2Destination destination) {
    HapticFeedback.selectionClick();
    setState(() {
      _offersActive = false;
      _searchOpen = false;
    });
    if (destination == BuyV2Destination.orders) {
      widget.session.openOrders();
    } else {
      widget.session.openDestination(destination);
    }
  }

  void _openOffers() {
    HapticFeedback.selectionClick();
    setState(() {
      _offersActive = true;
      _searchOpen = false;
    });
    widget.session.openDestination(BuyV2Destination.shop);
    final router = GoRouter.maybeOf(context);
    if (router != null &&
        router.routeInformationProvider.value.uri.toString() !=
            '/app/buy?sub=offers') {
      router.replace('/app/buy?sub=offers');
    }
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
    final current = _offersActive
        ? destinations.length
        : destinations.indexOf(session.activeDockDestination);
    final nextIndex =
        (current + delta + destinations.length + 1) % (destinations.length + 1);
    if (nextIndex == destinations.length) {
      _openOffers();
    } else {
      _openBuyDestination(destinations[nextIndex]);
    }
  }

  bool _showsMiniCart(BuyV2Session session) =>
      (_offersActive || session.activeDockDestination == BuyV2Destination.orders
              ? session.itemCount
              : session.countForDestination(session.activeDockDestination)) >
          0 &&
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
    if (action.id == 'buy') {
      _openBuyDestination(BuyV2Destination.shop);
      return;
    }
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

  void _openOrderHelpChat(BuyV2Order order) {
    final onOpenChat = widget.onOpenChat;
    final chatLabel = order.destination == BuyV2Destination.medicine
        ? 'Care Chat'
        : 'Shop Chat';
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      if (onOpenChat != null) {
        onOpenChat();
      } else {
        widget.session.showNotice(
          '$chatLabel is unavailable right now. Your order is unchanged.',
        );
      }
      return;
    }
    try {
      context.push(
        const BuyV2ChatRouteAdapter().orderHelpLocationFor(order: order),
      );
    } on ArgumentError {
      widget.session.showNotice(
        '$chatLabel is unavailable right now. Your order is unchanged.',
      );
    }
  }

  void _openProductQuestion(BuyV2Product product) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      final onOpenChat = widget.onOpenChat;
      if (onOpenChat != null) {
        onOpenChat();
      } else {
        widget.session.showNotice(
          'Supplier Chat is unavailable right now. Your product is unchanged.',
        );
      }
      return;
    }
    try {
      context.push(
        const BuyV2ChatRouteAdapter().productQuestionLocationFor(
          product: product,
          quantity: widget.session.quantityFor(product.id),
        ),
      );
    } on ArgumentError {
      widget.session.showNotice(
        'Supplier Chat is unavailable right now. Your product is unchanged.',
      );
    }
  }

  void _openStoreQuestion(BuyV2Product product) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      final onOpenChat = widget.onOpenChat;
      if (onOpenChat != null) {
        onOpenChat();
      } else {
        widget.session.showNotice(
          'Store Chat is unavailable right now. Your products are unchanged.',
        );
      }
      return;
    }
    if (!widget.session.rememberStoreReturnAnchor(product.id)) {
      widget.session.showNotice(
        'This store is unavailable right now. Your products are unchanged.',
      );
      return;
    }
    unawaited(_openStoreQuestionRoute(product));
  }

  Future<void> _openStoreQuestionRoute(BuyV2Product product) async {
    try {
      await context.push(
        const BuyV2ChatRouteAdapter().storeQuestionLocationFor(anchor: product),
      );
    } on ArgumentError {
      widget.session.clearStoreReturnAnchor();
      widget.session.showNotice(
        'Store Chat is unavailable right now. Your products are unchanged.',
      );
      return;
    }
    if (!mounted) return;
    final anchorId = widget.session.takeStoreReturnAnchor(
      routeProductId: product.id,
    );
    if (anchorId == null) return;
    final anchor = widget.session.findProduct(anchorId);
    if (anchor != null) _openPartnerCatalogue(anchor);
  }

  void _rememberStoreBrowse(BuyV2Product product) {
    setState(() {
      _storeBrowseAnchors.remove(product.destination);
      _storeBrowseAnchors[product.destination] = product;
    });
  }

  void _openPartnerCatalogue(BuyV2Product product, {bool brandOnly = false}) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    if (!brandOnly) {
      _rememberStoreBrowse(product);
    }
    unawaited(
      showBuyV2PartnerCatalogue(
        context,
        widget.session,
        product,
        brandOnly: brandOnly,
        onAskStore: _openStoreQuestion,
        onStoreChanged: _rememberStoreBrowse,
        onOpenProduct: _openStoreProduct,
        onOpenCart: () => widget.session.openCart(
          scope: switch (product.destination) {
            BuyV2Destination.shop ||
            BuyV2Destination.orders => BuyV2CartScope.shop,
            BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
            BuyV2Destination.medicine => BuyV2CartScope.medicine,
          },
        ),
      ),
    );
  }

  Future<bool> _openStoreProduct(BuyV2Product product) async {
    final session = widget.session;
    if (_storeBrowseAnchor?.seller != product.seller ||
        _storeBrowseAnchor?.destination != product.destination) {
      _rememberStoreBrowse(product);
    }
    final previousView = session.view;
    final previousDestination = session.destination;
    final previousProductId = session.selectedProductId;
    final previousCartScope = session.cartScope;
    if (!session.openProduct(product.id) || !mounted) return false;

    final openCart = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        settings: const RouteSettings(name: 'buy-store-product'),
        transitionDuration: BuyV2Motion.contentChange,
        reverseTransitionDuration: BuyV2Motion.contentChange,
        pageBuilder: (routeContext, _, _) => Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: AnimatedBuilder(
              animation: session,
              builder: (context, _) => Column(
                children: [
                  Expanded(
                    child: BuyV2ProductView(
                      session: session,
                      returnLabel:
                          'Back to ${_storeBrowseAnchor?.seller ?? product.seller}',
                      onReturn: () => Navigator.of(routeContext).pop(false),
                      onAskSeller: _openProductQuestion,
                      onOpenPartnerCatalogue: _openPartnerCatalogue,
                      wholesaleTradeDecisionAdapter:
                          widget.wholesaleTradeDecisionAdapter,
                    ),
                  ),
                  if (session.countForDestination(product.destination) > 0)
                    BuyV2StoreCartBar(
                      session: session,
                      destination: product.destination,
                      onOpenCart: () => Navigator.of(routeContext).pop(true),
                    ),
                ],
              ),
            ),
          ),
        ),
        transitionsBuilder: (context, animation, _, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            key: const ValueKey('buy-store-product-route-motion'),
            opacity: Tween<double>(begin: .86, end: 1).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.035, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    if (!mounted) return openCart ?? false;

    if (previousView == BuyV2View.cart) {
      session.destination = previousDestination;
      session.openCart(scope: previousCartScope);
    } else if (previousView == BuyV2View.product && previousProductId != null) {
      session.openProduct(previousProductId);
    }
    return openCart ?? false;
  }

  void _openShopChat() {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      widget.onOpenChat?.call();
      return;
    }
    final session = widget.session;
    context.push(
      const BuyV2ChatRouteAdapter().locationFor(
        destination: session.activeDockDestination,
        view: session.view,
        offersActive: _offersActive,
        cartScope: session.cartScope,
        checkoutScope: session.checkoutScope,
        productId: session.selectedProductId,
        orderId: session.selectedOrderId,
        recoveryKind: session.recoveryKind,
      ),
    );
  }

  Widget _currentView(BuyV2Session session) {
    final cartStoreAnchor = switch (session.cartScope) {
      BuyV2CartScope.all => _storeBrowseAnchor,
      BuyV2CartScope.shop => _storeBrowseAnchors[BuyV2Destination.shop],
      BuyV2CartScope.wholesale =>
        _storeBrowseAnchors[BuyV2Destination.wholesale],
      BuyV2CartScope.medicine => _storeBrowseAnchors[BuyV2Destination.medicine],
    };
    if (_offersActive && session.view == BuyV2View.catalogue) {
      return BuyV2OffersView(session: session, source: widget.offersSource);
    }
    if (session.destination == BuyV2Destination.orders &&
        session.view == BuyV2View.catalogue) {
      return BuyV2OrdersView(
        session: session,
        onOpenOrderHelp: _openOrderHelpChat,
        invoiceDownloader: widget.invoiceDownloader,
        browseProducts: session.visibleProducts.isEmpty
            ? null
            : BuyV2ProgressiveProductGrid(
                session: session,
                products: session.visibleProducts,
                storageKey: 'buy-orders-products',
                semanticLabel: 'Products to buy from Orders',
              ),
      );
    }
    return switch (session.view) {
      BuyV2View.catalogue => BuyV2CatalogueView(session: session),
      BuyV2View.product => BuyV2ProductView(
        session: session,
        returnLabel: _offersActive ? 'Offers' : null,
        onAskSeller: _openProductQuestion,
        onOpenPartnerCatalogue: _openPartnerCatalogue,
        wholesaleTradeDecisionAdapter: widget.wholesaleTradeDecisionAdapter,
      ),
      BuyV2View.cart => BuyV2CartView(
        session: session,
        storeLabel: cartStoreAnchor?.seller,
        onBrowseStore: cartStoreAnchor == null
            ? null
            : () => _openPartnerCatalogue(cartStoreAnchor),
        onBrowseMore: () {
          if (_offersActive) {
            _openOffers();
            return;
          }
          final destination = switch (session.cartScope) {
            BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
            BuyV2CartScope.medicine => BuyV2Destination.medicine,
            BuyV2CartScope.all || BuyV2CartScope.shop => BuyV2Destination.shop,
          };
          _openBuyDestination(destination);
        },
      ),
      BuyV2View.checkout => BuyV2CheckoutView(
        session: session,
        gstInvoiceController: _gstInvoiceController,
        keyboardVisible: MediaQuery.viewInsetsOf(context).bottom > 0,
        paymentHandoff: widget.paymentHandoff,
      ),
      BuyV2View.confirmation => BuyV2ConfirmationView(
        session: session,
        invoiceDownloader: widget.invoiceDownloader,
      ),
      BuyV2View.tracking => BuyV2TrackingView(
        session: session,
        onOpenOrderHelp: _openOrderHelpChat,
        invoiceDownloader: widget.invoiceDownloader,
        paymentHandoff: widget.paymentHandoff,
        liveDeliveryMapBuilder: widget.liveDeliveryMapBuilder,
      ),
      BuyV2View.orderItems => BuyV2OrderItemsView(session: session),
      BuyV2View.assist => BuyV2TrackingView(
        session: session,
        onOpenOrderHelp: _openOrderHelpChat,
        invoiceDownloader: widget.invoiceDownloader,
        paymentHandoff: widget.paymentHandoff,
        liveDeliveryMapBuilder: widget.liveDeliveryMapBuilder,
      ),
      BuyV2View.account => BuyV2AccountView(
        session: session,
        accountIdentity: widget.accountIdentity,
        accountAuthenticated: widget.accountAuthenticated,
      ),
      BuyV2View.recovery => BuyV2RecoveryView(
        session: session,
        onOpenOrderHelp: _openOrderHelpChat,
      ),
    };
  }
}

String _buyOrderStatusLabel(BuyV2OrderStatus status) => switch (status) {
  BuyV2OrderStatus.preparing => 'Preparing your order',
  BuyV2OrderStatus.confirmed => 'Order confirmed',
  BuyV2OrderStatus.dispatched => 'On the way',
  BuyV2OrderStatus.arriving => 'Arriving soon',
  BuyV2OrderStatus.delivered => 'Delivered',
};

class _BuyQuickDeliveryStatusBar extends StatelessWidget {
  const _BuyQuickDeliveryStatusBar({
    required this.order,
    required this.minimized,
    required this.soundOnArrival,
    required this.onMinimizedChanged,
    required this.onHiddenChanged,
    required this.onSoundChanged,
    required this.onKeepOnScreen,
    required this.onOpen,
  });

  final BuyV2Order order;
  final bool minimized;
  final bool soundOnArrival;
  final ValueChanged<bool> onMinimizedChanged;
  final ValueChanged<bool> onHiddenChanged;
  final ValueChanged<bool> onSoundChanged;
  final VoidCallback onKeepOnScreen;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final status = _buyOrderStatusLabel(order.status);
    final promise = buyV2OrderPromiseSummary(order);
    const statusStyle = TextStyle(
      color: BuyV2Colors.navy,
      fontSize: 9,
      fontWeight: FontWeight.w800,
    );
    final measuredWidth =
        buyV2ValueTextSize(context, status, statusStyle).width + 74;
    final collapsedWidth = (measuredWidth < 236 ? 236.0 : measuredWidth)
        .clamp(0.0, MediaQuery.sizeOf(context).width - 16)
        .toDouble();
    final statusBar = minimized
        ? Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              key: const ValueKey('buy-quick-delivery-status-minimized'),
              width: collapsedWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: InkWell(
                            key: const ValueKey(
                              'buy-quick-delivery-open-minimized',
                            ),
                            onTap: onOpen,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.bolt_rounded,
                                    color: BuyV2Colors.royal,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Semantics(
                                      label: '$status · $promise',
                                      excludeSemantics: true,
                                      child: Text(
                                        status,
                                        maxLines: 1,
                                        style: statusStyle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('buy-quick-delivery-expand'),
                          tooltip: 'Show delivery choices',
                          onPressed: () => onMinimizedChanged(false),
                          icon: const Icon(Icons.expand_more_rounded, size: 18),
                          color: BuyV2Colors.royal,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 44),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BuyV2HonestProgressIndicator(
                    ownerId: order.id,
                    progress: order.progress,
                    statusLabel: _buyOrderStatusLabel(order.status),
                    backgroundColor: BuyV2Colors.softBlue,
                    valueColor: BuyV2Colors.royal,
                    minHeight: 2,
                  ),
                ],
              ),
            ),
          )
        : Padding(
            key: const ValueKey('buy-quick-delivery-status-expanded'),
            padding: const EdgeInsets.fromLTRB(10, 5, 6, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: BuyV2Colors.navy,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: InkWell(
                        key: const ValueKey('buy-quick-delivery-open'),
                        onTap: onOpen,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick delivery',
                              style: context.buyBody.copyWith(fontSize: 10.5),
                            ),
                            Text('$status · $promise', style: context.buyMeta),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('buy-quick-delivery-minimize'),
                      tooltip: 'Minimize delivery status',
                      onPressed: () => onMinimizedChanged(true),
                      icon: const Icon(Icons.expand_less_rounded, size: 18),
                      color: BuyV2Colors.navy,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  ],
                ),
                BuyV2HonestProgressIndicator(
                  ownerId: order.id,
                  progress: order.progress,
                  statusLabel: _buyOrderStatusLabel(order.status),
                  backgroundColor: BuyV2Colors.softBlue,
                  valueColor: BuyV2Colors.navy,
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton.icon(
                      key: const ValueKey('buy-quick-delivery-keep'),
                      onPressed: onKeepOnScreen,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      icon: const Icon(Icons.push_pin_outlined, size: 15),
                      label: const Text('Keep'),
                    ),
                    FilterChip(
                      key: const ValueKey('buy-quick-delivery-sound'),
                      selected: soundOnArrival,
                      onSelected: onSoundChanged,
                      selectedColor: BuyV2Colors.navy,
                      backgroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      side: const BorderSide(color: BuyV2Colors.navy),
                      labelStyle: TextStyle(
                        color: soundOnArrival ? Colors.white : BuyV2Colors.navy,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                      label: const Text('Arrival sound'),
                    ),
                    TextButton.icon(
                      key: const ValueKey('buy-quick-delivery-hide'),
                      onPressed: () => onHiddenChanged(true),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      icon: const Icon(Icons.visibility_off_outlined, size: 15),
                      label: const Text('Hide'),
                    ),
                  ],
                ),
              ],
            ),
          );
    if (MediaQuery.disableAnimationsOf(context)) return statusBar;
    return AnimatedSize(
      duration: BuyV2Motion.expandCollapse,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: statusBar,
    );
  }
}

class _BuyQuietDeliveryStatusBar extends StatelessWidget {
  const _BuyQuietDeliveryStatusBar({required this.order, required this.onOpen});

  final BuyV2Order order;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 3),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: const BorderSide(color: BuyV2Colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('buy-quiet-delivery-status'),
          onTap: onOpen,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: BuyV2Colors.navy,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_buyOrderStatusLabel(order.status)} · ${buyV2OrderPromiseSummary(order)}',
                      style: context.buyMeta.copyWith(
                        color: BuyV2Colors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: BuyV2Colors.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

class _BuySearchBand extends StatelessWidget {
  const _BuySearchBand({
    required this.session,
    required this.offersActive,
    required this.controller,
    required this.open,
    required this.onOpenChanged,
    required this.onScan,
    required this.onLocation,
    required this.onAccount,
    required this.scannerBusy,
  });

  final BuyV2Session session;
  final bool offersActive;
  final TextEditingController controller;
  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final VoidCallback onScan;
  final VoidCallback onLocation;
  final VoidCallback onAccount;
  final bool scannerBusy;

  @override
  Widget build(BuildContext context) {
    final hint = offersActive
        ? 'Search offers, products and sellers'
        : switch (session.destination) {
            BuyV2Destination.wholesale => 'Search bulk products and suppliers',
            BuyV2Destination.medicine => 'Search medicines and wellness',
            BuyV2Destination.orders => 'Search orders, sellers or ID',
            _ => 'Search products, brands and codes',
          };
    final compactHint = offersActive
        ? 'Search current offers'
        : switch (session.destination) {
            BuyV2Destination.wholesale => 'Search bulk products',
            BuyV2Destination.medicine => 'Search medicines',
            BuyV2Destination.orders => 'Search orders or ID',
            _ => 'Search products',
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
                            onSubmitted: (value) {
                              session.submitSearch(value);
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
                                            ? compactHint
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
                          if (controller.text.trim().isNotEmpty) {
                            session.submitSearch(controller.text);
                          }
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
            const SizedBox(width: 4),
            MoolGlobalProfileShortcutV2(
              keyName: 'buy-open-account',
              onPressed: onAccount,
            ),
          ],
        ],
      ),
    );
  }
}

class _BuyMiniCartBar extends StatefulWidget {
  const _BuyMiniCartBar({
    required this.session,
    required this.initialPosition,
    required this.onPositionChanged,
    this.aggregate = false,
  });

  final BuyV2Session session;
  final bool aggregate;
  final Offset? initialPosition;
  final ValueChanged<Offset> onPositionChanged;

  @override
  State<_BuyMiniCartBar> createState() => _BuyMiniCartBarState();
}

class _BuyMiniCartBarState extends State<_BuyMiniCartBar> {
  static const _edgeInset = 8.0;
  Offset? _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  Offset _defaultPosition(Size available, Size cart) => Offset(
    (available.width - cart.width - _edgeInset).clamp(
      _edgeInset,
      available.width,
    ),
    (available.height - cart.height - _edgeInset).clamp(
      _edgeInset,
      available.height,
    ),
  );

  Offset _clampPosition(Offset position, Size available, Size cart) => Offset(
    position.dx.clamp(
      _edgeInset,
      (available.width - cart.width - _edgeInset).clamp(
        _edgeInset,
        available.width,
      ),
    ),
    position.dy.clamp(
      _edgeInset,
      (available.height - cart.height - _edgeInset).clamp(
        _edgeInset,
        available.height,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final destination = session.activeDockDestination;
    final scope = widget.aggregate
        ? BuyV2CartScope.all
        : switch (destination) {
            BuyV2Destination.shop => BuyV2CartScope.shop,
            BuyV2Destination.wholesale => BuyV2CartScope.wholesale,
            BuyV2Destination.medicine => BuyV2CartScope.medicine,
            BuyV2Destination.orders => BuyV2CartScope.all,
          };
    final itemCount = widget.aggregate || destination == BuyV2Destination.orders
        ? session.itemCount
        : session.countForDestination(destination);
    final total = widget.aggregate || destination == BuyV2Destination.orders
        ? session.cartTotal
        : session.totalForDestination(destination);
    final itemLabel = itemCount == 1 ? 'item' : 'items';
    final itemText = '$itemCount $itemLabel';
    final totalText = buyV2Money(total);
    final cartMessage = session.cartAcknowledgement ?? '$itemText ready';
    const itemStyle = TextStyle(
      color: Colors.white70,
      fontSize: 8.5,
      height: 1,
      fontWeight: FontWeight.w800,
    );
    const totalStyle = TextStyle(
      color: Colors.white,
      fontSize: 12.5,
      height: 1,
      fontWeight: FontWeight.w900,
    );
    final itemSize = buyV2ValueTextSize(context, itemText, itemStyle);
    final totalSize = buyV2ValueTextSize(context, totalText, totalStyle);

    void activate() {
      HapticFeedback.selectionClick();
      session.openCart(scope: scope);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.biggest;
        final maximumWidth = (available.width - (_edgeInset * 2)).clamp(
          88.0,
          double.infinity,
        );
        final textWidth = itemSize.width > totalSize.width
            ? itemSize.width
            : totalSize.width;
        final cartWidth = (textWidth + 40).clamp(88.0, maximumWidth).toDouble();
        final cartHeight = (itemSize.height + totalSize.height + 18)
            .clamp(48.0, double.infinity)
            .toDouble();
        final cartSize = Size(cartWidth, cartHeight);
        final currentPosition = _clampPosition(
          _position ?? _defaultPosition(available, cartSize),
          available,
          cartSize,
        );
        final valueWidth = cartWidth - 40;

        void move(DragUpdateDetails details) {
          setState(() {
            _position = _clampPosition(
              (_position ?? currentPosition) + details.delta,
              available,
              cartSize,
            );
          });
        }

        void finishMove() {
          final position = _position ?? currentPosition;
          widget.onPositionChanged(position);
          HapticFeedback.selectionClick();
        }

        return Stack(
          key: const ValueKey('buy-mini-cart-transparent-overlay'),
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: currentPosition.dx,
              top: currentPosition.dy,
              child: Semantics(
                key: const ValueKey('buy-compact-cart-indicator'),
                container: true,
                label: 'Cart, $cartMessage, $totalText. View cart',
                hint: 'Drag to move. Double tap to view cart.',
                button: true,
                liveRegion: true,
                onTap: activate,
                child: GestureDetector(
                  key: const ValueKey('buy-mini-cart-drag-handle'),
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: move,
                  onPanEnd: (_) => finishMove(),
                  onPanCancel: finishMove,
                  child: SizedBox(
                    width: cartWidth,
                    height: cartHeight,
                    child: Material(
                      color: BuyV2Colors.navy,
                      elevation: 3,
                      shadowColor: BuyV2Colors.navy.withValues(alpha: .2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: BuyV2Colors.royal),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: activate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              AnimatedSwitcher(
                                duration: BuyV2Motion.resolved(
                                  context,
                                  BuyV2Motion.stateChange,
                                ),
                                child: Icon(
                                  session.cartAcknowledgement == null
                                      ? Icons.shopping_cart_outlined
                                      : Icons.check_circle_rounded,
                                  key: ValueKey(
                                    session.cartAcknowledgement == null
                                        ? 'buy-mini-cart-icon'
                                        : 'buy-mini-cart-added-icon',
                                  ),
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  BuyV2FiniteValueTransition(
                                    key: ValueKey(
                                      session.cartAcknowledgement == null
                                          ? 'buy-cart-summary'
                                          : 'buy-cart-acknowledgement',
                                    ),
                                    stateKey: '$cartMessage|$itemCount|$total',
                                    text: itemText,
                                    ownerSize: Size(
                                      valueWidth,
                                      itemSize.height,
                                    ),
                                    textAlign: TextAlign.start,
                                    style: itemStyle,
                                  ),
                                  const SizedBox(height: 2),
                                  BuyV2FiniteValueTransition(
                                    key: const ValueKey('buy-cart-total'),
                                    stateKey: '$total|$totalText',
                                    text: totalText,
                                    ownerSize: Size(
                                      valueWidth,
                                      totalSize.height,
                                    ),
                                    textAlign: TextAlign.start,
                                    style: totalStyle,
                                  ),
                                ],
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
          ],
        );
      },
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
