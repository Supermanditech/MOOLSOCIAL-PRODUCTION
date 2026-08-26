import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_motion_primitives.dart';
import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
import '../../features/journey01/journey_services.dart';
import '../universal/mool_contextual_chat_v2.dart';
import '../universal/mool_global_navigation_v2.dart';
import 'buy_v2_catalogue.dart';
import 'buy_v2_design.dart';
import 'buy_v2_invoice.dart';
import 'buy_v2_invoice_downloader.dart';
import 'buy_v2_scanner.dart';
import 'buy_v2_shop_chat.dart';
import 'buy_v2_views.dart';

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
    this.onShopChatAction,
    this.onShopChatHandoff,
    this.onDestinationChanged,
    this.invoiceDownloader = saveBuyV2InvoiceToDevice,
    this.offersSource = const BuyV2CataloguePublishedOffersSource(),
    this.shopChatSource = const BuyV2SessionShopChatProvisioningSource(),
    this.contextualChatSource =
        const MoolDefaultContextualChatProvisioningSource(),
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
  final BuyV2ShopChatActionHandler? onShopChatAction;
  final BuyV2ShopChatHandoffHandler? onShopChatHandoff;
  final ValueChanged<BuyV2Destination>? onDestinationChanged;
  final BuyV2InvoiceDownloader? invoiceDownloader;
  final BuyV2PublishedOffersSource offersSource;
  final BuyV2ShopChatProvisioningSource shopChatSource;
  final MoolContextualChatProvisioningSource contextualChatSource;

  @override
  State<BuyV2Screen> createState() => _BuyV2ScreenState();
}

class _BuyV2ScreenState extends State<BuyV2Screen> {
  final GlobalKey<BuyV2ShopChatViewState> _shopChatViewKey = GlobalKey();
  Timer? _noticeTimer;
  Timer? _cartAcknowledgementTimer;
  bool _scannerBusy = false;
  bool _searchOpen = false;
  bool _offersActive = false;
  bool _shopChatActive = false;
  final Map<String, BuyV2ShopChatRetainedState> _shopChatRetainedStates = {};
  BuyV2ShopChatFilter _shopChatInitialFilter = BuyV2ShopChatFilter.all;
  String? _shopChatInitialFilterId;
  BuyV2ShopChatPresentation _shopChatPresentation =
      BuyV2ShopChatPresentation.shop;
  String _shopChatOriginLabel = 'Shop';
  int _shopChatMotionSequence = 0;
  BuyV2NavigationMotionDirection _surfaceMotionDirection =
      BuyV2NavigationMotionDirection.replace;
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
        oldWidget.initialOffersActive != widget.initialOffersActive ||
        oldWidget.initialView != widget.initialView ||
        oldWidget.initialCartScope != widget.initialCartScope ||
        oldWidget.productId != widget.productId ||
        oldWidget.orderId != widget.orderId ||
        oldWidget.recoveryKind != widget.recoveryKind) {
      _applyInitialState();
    }
  }

  void _applyInitialState() {
    _offersActive = widget.initialOffersActive;
    _shopChatActive = false;
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
    _surfaceMotionDirection = widget.session.navigationMotionDirection;
    if (_offersActive &&
        widget.session.view == BuyV2View.catalogue &&
        widget.session.destination != BuyV2Destination.shop) {
      _offersActive = false;
    }
    final careDestination =
        widget.session.activeDockDestination == BuyV2Destination.medicine;
    if (_shopChatActive &&
        ((_shopChatPresentation.familyId == 'book') != careDestination)) {
      _shopChatActive = false;
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

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _cartAcknowledgementTimer?.cancel();
    widget.session.removeListener(_sessionChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final careNavigation =
        session.activeDockDestination == BuyV2Destination.medicine;
    final surfaceTheme = _shopChatActive
        ? BuyV2ThemeSpec.resolve(BuyV2Destination.shop, BuyV2View.catalogue)
        : BuyV2ThemeSpec.resolve(session.destination, session.view);
    return BuyV2ThemeScope(
      spec: surfaceTheme,
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            HapticFeedback.selectionClick();
            if (_shopChatActive) {
              _handleShopChatBack();
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
                          if (session.view == BuyV2View.catalogue &&
                              !_shopChatActive)
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
                              onAccount: () {
                                HapticFeedback.selectionClick();
                                setState(() => _searchOpen = false);
                                session.openAccount();
                              },
                              accountLabel:
                                  widget.accountIdentity?.primaryLabel ??
                                  (widget.accountAuthenticated
                                      ? 'MoolSocial member'
                                      : 'MoolSocial guest'),
                              scannerBusy: _scannerBusy,
                            ),
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _BuyNavigationSurfaceOwner(
                                    key: ObjectKey(session),
                                    stateKey: Object.hash(
                                      session.navigationMotionSequence,
                                      _shopChatMotionSequence,
                                    ),
                                    direction: _surfaceMotionDirection,
                                    child: _BuyExpandCollapseOwner(
                                      key: ValueKey(
                                        _shopChatActive
                                            ? 'buy-shop-chat-owner-motion'
                                            : _searchOpen &&
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
                                if (session.notice case final message?)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: _BuyNotice(message: message),
                                  ),
                              ],
                            ),
                          ),
                          if (!_shopChatActive && _showsMiniCart(session))
                            _BuyMiniCartBar(session: session),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: _shopChatActive
              ? null
              : MoolDestinationNavigationV2(
                  activeId: careNavigation ? 'book' : 'buy',
                  destinationLabel: careNavigation ? 'Care' : 'Shop',
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
          onPressed: !_offersActive && active == BuyV2Destination.wholesale
              ? null
              : () => _openBuyDestination(BuyV2Destination.wholesale),
        ),
        MoolLocalNavigationAction(
          keyName: 'buy-local-tab-orders',
          id: BuyV2Destination.orders.name,
          label: 'Orders',
          icon: Icons.receipt_long_outlined,
          onPressed: !_offersActive && active == BuyV2Destination.orders
              ? null
              : () => _openBuyDestination(BuyV2Destination.orders),
        ),
        MoolLocalNavigationAction(
          keyName: 'buy-local-tab-offers',
          id: 'offers',
          label: 'Offers',
          icon: Icons.local_offer_outlined,
          onPressed: _offersActive ? null : _openOffers,
        ),
      ],
    );
  }

  void _openBuyDestination(BuyV2Destination destination) {
    HapticFeedback.selectionClick();
    setState(() {
      _offersActive = false;
      _shopChatActive = false;
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
      _shopChatActive = false;
      _searchOpen = false;
    });
    widget.session.openDestination(BuyV2Destination.shop);
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
    if (action.id == 'buy' && (_offersActive || _shopChatActive)) {
      setState(() {
        _offersActive = false;
        _shopChatActive = false;
      });
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

  void _handoffShopChatAction(
    BuyV2ShopChatThread thread,
    BuyV2ShopChatAction action,
  ) {
    final externalHandoff = widget.onShopChatHandoff;
    if (externalHandoff != null) {
      externalHandoff(thread, action);
      return;
    }
    final onOpenChat = widget.onOpenChat;
    if (onOpenChat != null) {
      onOpenChat();
      return;
    }
    final router = GoRouter.maybeOf(context);
    final currentRoute =
        router?.routeInformationProvider.value.uri.toString() ?? '/app/buy';
    final returnRoute = _shopChatReturnRouteFor(thread, currentRoute);
    final draft = action.kind == BuyV2ShopChatActionKind.sendText
        ? action.text?.trim()
        : null;
    context.push(
      Uri(
        path: '/app/chat/inbox',
        queryParameters: {
          'type': thread.productionChatType,
          if (draft != null && draft.isNotEmpty) 'draft': draft,
          'return': returnRoute,
        },
      ).toString(),
    );
  }

  String _shopChatReturnRouteFor(
    BuyV2ShopChatThread thread,
    String currentRoute,
  ) {
    if (_shopChatPresentation.familyId == 'book') {
      final subAction = thread.resolvedFilterId;
      if (subAction == 'medicine' && _shopChatInitialFilterId == 'medicine') {
        return currentRoute;
      }
      return Uri(
        path: '/app/book',
        queryParameters: {'sub': subAction},
      ).toString();
    }
    final target = thread.commerceTarget;
    final matchesOrigin = switch (target) {
      BuyV2ShopChatCommerceTarget.shop =>
        _shopChatInitialFilter == BuyV2ShopChatFilter.all,
      BuyV2ShopChatCommerceTarget.wholesale =>
        _shopChatInitialFilter == BuyV2ShopChatFilter.sellers,
      BuyV2ShopChatCommerceTarget.orders =>
        _shopChatInitialFilter == BuyV2ShopChatFilter.orders,
      BuyV2ShopChatCommerceTarget.offers =>
        _shopChatInitialFilter == BuyV2ShopChatFilter.offers,
      null => true,
    };
    if (matchesOrigin) return currentRoute;
    return switch (target) {
      BuyV2ShopChatCommerceTarget.shop => '/app/buy',
      BuyV2ShopChatCommerceTarget.wholesale => '/app/buy?sub=wholesale',
      BuyV2ShopChatCommerceTarget.orders => '/app/buy?sub=orders',
      BuyV2ShopChatCommerceTarget.offers => '/app/buy?sub=offers',
      null => currentRoute,
    };
  }

  void _openShopChat() {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    final careChat =
        widget.session.activeDockDestination == BuyV2Destination.medicine;
    setState(() {
      _shopChatPresentation = careChat
          ? MoolContextualChatCatalog.care
          : BuyV2ShopChatPresentation.shop;
      _shopChatInitialFilterId = careChat ? 'medicine' : null;
      _shopChatOriginLabel = careChat
          ? 'Medicine'
          : _offersActive
          ? 'Offers'
          : switch (widget.session.activeDockDestination) {
              BuyV2Destination.orders => 'Orders',
              BuyV2Destination.wholesale => 'Wholesale',
              _ => 'Shop',
            };
      _shopChatInitialFilter = careChat
          ? BuyV2ShopChatFilter.sellers
          : _offersActive
          ? BuyV2ShopChatFilter.offers
          : switch (widget.session.activeDockDestination) {
              BuyV2Destination.orders => BuyV2ShopChatFilter.orders,
              BuyV2Destination.wholesale => BuyV2ShopChatFilter.sellers,
              _ => BuyV2ShopChatFilter.all,
            };
      _shopChatActive = true;
      _searchOpen = false;
      _shopChatMotionSequence += 1;
      _surfaceMotionDirection = BuyV2NavigationMotionDirection.forward;
    });
  }

  void _closeShopChat() {
    HapticFeedback.selectionClick();
    setState(() {
      _shopChatActive = false;
      _shopChatMotionSequence += 1;
      _surfaceMotionDirection = BuyV2NavigationMotionDirection.back;
    });
  }

  void _handleShopChatBack() {
    if (_shopChatViewKey.currentState?.handleBack() ?? false) return;
    _closeShopChat();
  }

  void _openShopChatCommerce(BuyV2ShopChatCommerceTarget target) {
    switch (target) {
      case BuyV2ShopChatCommerceTarget.shop:
        _openBuyDestination(BuyV2Destination.shop);
      case BuyV2ShopChatCommerceTarget.wholesale:
        _openBuyDestination(BuyV2Destination.wholesale);
      case BuyV2ShopChatCommerceTarget.orders:
        _openBuyDestination(BuyV2Destination.orders);
      case BuyV2ShopChatCommerceTarget.offers:
        _openOffers();
    }
  }

  void _openCareChatContext(BuyV2ShopChatThread thread) {
    final subAction = thread.resolvedFilterId;
    _closeShopChat();
    if (subAction == 'medicine') {
      return;
    }
    openMoolConnectedRoute(
      context,
      activeFamilyId: 'book',
      route: Uri(
        path: '/app/book',
        queryParameters: {'sub': subAction},
      ).toString(),
    );
  }

  Widget _currentView(BuyV2Session session) {
    if (_shopChatActive) {
      final careChat = _shopChatPresentation.familyId == 'book';
      final retainedStateKey =
          '${_shopChatPresentation.familyId}|$_shopChatOriginLabel|${_shopChatInitialFilterId ?? _shopChatInitialFilter.name}';
      return BuyV2ShopChatView(
        key: _shopChatViewKey,
        session: session,
        originLabel: _shopChatOriginLabel,
        initialFilter: _shopChatInitialFilter,
        initialFilterId: _shopChatInitialFilterId,
        presentation: _shopChatPresentation,
        onBack: _closeShopChat,
        onOpenProductionChat: _openGlobalChat,
        provisioningSource: careChat
            ? MoolContextualChatSourceAdapter(
                familyId: 'book',
                source: widget.contextualChatSource,
              )
            : widget.shopChatSource,
        retainedState: _shopChatRetainedStates.putIfAbsent(
          retainedStateKey,
          BuyV2ShopChatRetainedState.new,
        ),
        onAction: widget.onShopChatAction,
        onHandoff: _handoffShopChatAction,
        onOpenCommerce: careChat ? null : _openShopChatCommerce,
        onOpenThreadContext: careChat ? _openCareChatContext : null,
      );
    }
    if (_offersActive && session.view == BuyV2View.catalogue) {
      return BuyV2OffersView(session: session, source: widget.offersSource);
    }
    if (session.destination == BuyV2Destination.orders &&
        session.view == BuyV2View.catalogue) {
      return BuyV2OrdersView(
        session: session,
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
      ),
      BuyV2View.cart => BuyV2CartView(
        session: session,
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
      BuyV2View.checkout => BuyV2CheckoutView(session: session),
      BuyV2View.confirmation => BuyV2ConfirmationView(
        session: session,
        invoiceDownloader: widget.invoiceDownloader,
      ),
      BuyV2View.tracking => BuyV2TrackingView(
        session: session,
        invoiceDownloader: widget.invoiceDownloader,
      ),
      BuyV2View.orderItems => BuyV2OrderItemsView(session: session),
      BuyV2View.assist => BuyV2AssistView(session: session),
      BuyV2View.account => BuyV2AccountView(
        session: session,
        accountIdentity: widget.accountIdentity,
        accountAuthenticated: widget.accountAuthenticated,
      ),
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
    required this.accountLabel,
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
  final String accountLabel;
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
            const SizedBox(width: 4),
            _BuyAccountButton(onPressed: onAccount, accountLabel: accountLabel),
          ],
        ],
      ),
    );
  }
}

class _BuyAccountButton extends StatelessWidget {
  const _BuyAccountButton({
    required this.onPressed,
    required this.accountLabel,
  });

  final VoidCallback onPressed;
  final String accountLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open profile and account',
      button: true,
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: BuyV2Colors.line),
        ),
        child: InkWell(
          key: const ValueKey('buy-open-account'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    key: const ValueKey('buy-profile-avatar'),
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: BuyV2Colors.navy,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _buyAccountInitials(accountLabel),
                      style: const TextStyle(
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
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
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

String _buyAccountInitials(String label) {
  final words = label
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return 'MS';
  if (words.length > 1) {
    return words
        .take(2)
        .map((word) => String.fromCharCode(word.runes.first))
        .join()
        .toUpperCase();
  }
  return String.fromCharCodes(words.single.runes.take(2)).toUpperCase();
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
    void activate() {
      HapticFeedback.selectionClick();
      session.openCart();
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
