import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/buy/buy_v2_screen.dart';
import '../../../ui_v2/buy/buy_v2_scanner.dart';
import '../../../ui_v2/profile/global_profile_panel_v2.dart';
import '../../buy/buy_v2_models.dart';
import '../../buy/buy_v2_session.dart';
import '../../journey01/journey_services.dart';
import '../widgets/work_widgets.dart';
import '../work_models.dart';
import '../work_session.dart';

String _formatStoreAmount(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  if (digits.length <= 3) return '${negative ? '-' : ''}$digits';
  final tail = digits.substring(digits.length - 3);
  var lead = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (lead.length > 2) {
    groups.insert(0, lead.substring(lead.length - 2));
    lead = lead.substring(0, lead.length - 2);
  }
  if (lead.isNotEmpty) groups.insert(0, lead);
  return '${negative ? '-' : ''}${groups.join(',')},$tail';
}

class WorkWorkspaceDashboardScreen extends StatefulWidget {
  const WorkWorkspaceDashboardScreen({
    required this.session,
    required this.procurementSession,
    this.accountIdentity,
    this.accountAuthenticated = false,
    super.key,
  });

  final WorkSession session;
  final BuyV2Session procurementSession;
  final AuthenticatedAccountIdentity? accountIdentity;
  final bool accountAuthenticated;

  @override
  State<WorkWorkspaceDashboardScreen> createState() =>
      _WorkWorkspaceDashboardScreenState();
}

class _WorkWorkspaceDashboardScreenState
    extends State<WorkWorkspaceDashboardScreen> {
  WorkSession get session => widget.session;
  late final TextEditingController _searchController;
  final FocusNode _searchFocus = FocusNode(debugLabel: 'workspace-search');
  final _catalogueKey = GlobalKey<_WorkspaceCatalogueSurfaceState>();
  final _counterKey = GlobalKey<_CounterOrderSurfaceState>();
  final _saleSearchController = TextEditingController();
  final Map<String, Map<String, String>> _requirementDrafts = {};
  bool _requirementPickerOpen = false;
  _WorkspaceControlView _view = _WorkspaceControlView.dashboard;
  bool _draftAcceptingOrders = true;
  bool _draftVisibleToCustomers = false;
  String _draftFulfilmentMode = 'Delivery and pickup';
  int _draftBusyMinutes = 0;
  String _draftReopensAt = '';
  String _draftOpeningTime = '8:00 AM';
  String _draftClosingTime = '10:00 PM';
  int _draftMaximumActiveOrders = 8;
  bool _draftOrderAlertSound = true;
  bool _draftOrderAlertVibration = true;
  _WorkspaceOperation _operation = _WorkspaceOperation.orders;
  _WorkspaceControlView _operationReturnView = _WorkspaceControlView.dashboard;
  _WorkspaceOperation? _operationReturnOperation;
  Timer? _procurementRevealTimer;
  bool _procurementReady = false;
  _WorkspaceOperation? _procurementReturnOperation;
  String? _procurementProductId;
  WorkspaceOrderRecord? _reviewedOrder;

  @override
  void initState() {
    super.initState();
    session.clearMessages();
    _searchController = TextEditingController(
      text: session.workspaceSearchQuery,
    );
  }

  @override
  void dispose() {
    _saleSearchController.dispose();
    _procurementRevealTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final workspace = session.activeWorkspace;
        final profile = workspace == null
            ? null
            : _profileForWorkspace(session, workspace);
        if (workspace == null || profile == null || !workspace.verified) {
          return WorkPageScaffold(
            session: session,
            title: 'Your Workspace',
            subtitle: 'Business and professional tools',
            fallbackBackRoute: '/app/work/earn',
            activeLocalAction: 'workspace',
            showHeaderChat: false,
            showTrailingAction: false,
            body: WorkEmptyState(
              title: 'No approved Workspace yet',
              detail:
                  'Choose how you work and complete the review before opening your dashboard.',
              actionLabel: 'Choose a Workspace',
              onAction: () => context.go('/app/work/workspace/choose'),
            ),
          );
        }

        final presentation = _presentationFor(profile);
        final retailer = const {
          'retailer-grocery',
          'retailer-speciality',
        }.contains(profile.id);
        if (retailer) {
          return _buildRetailerControls(
            context,
            workspace: workspace,
            profile: profile,
          );
        }
        return WorkPageScaffold(
          session: session,
          title: workspace.name,
          subtitle: '${profile.label} · ${workspace.area}',
          fallbackBackRoute: '/app/work/earn',
          activeLocalAction: 'workspace',
          showHeaderChat: false,
          showTrailingAction: false,
          bottomAction: WorkPrimaryButton(
            keyName: 'work-dashboard-earn',
            label: presentation.earnAction,
            icon: Icons.bolt_rounded,
            onPressed: () => context.go('/app/work/earn'),
          ),
          body: ListView(
            key: const Key('work-workspace-dashboard'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              _DashboardReveal(
                child: _WorkspaceDashboardHero(
                  workspace: workspace,
                  profile: profile,
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              _DashboardReveal(
                delay: const Duration(milliseconds: 70),
                child: WorkSectionTitle(
                  title: presentation.title,
                  detail: presentation.detail,
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              _DashboardReveal(
                delay: const Duration(milliseconds: 110),
                child: Row(
                  children: [
                    for (
                      var index = 0;
                      index < presentation.signals.length;
                      index++
                    ) ...[
                      Expanded(
                        child: _DashboardSignal(
                          icon: presentation.signals[index].icon,
                          label: presentation.signals[index].label,
                        ),
                      ),
                      if (index < presentation.signals.length - 1)
                        const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              _DashboardReveal(
                delay: const Duration(milliseconds: 150),
                child: _DashboardPriorityCard(
                  session: session,
                  profile: profile,
                  presentation: presentation,
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkSectionTitle(
                title: 'Grow with one connected Workspace',
                detail:
                    'Your approved identity stays connected while each tool follows how you work.',
              ),
              const SizedBox(height: MoolSpacing.sm),
              _DashboardCapability(
                keyName: 'work-dashboard-customers',
                icon: Icons.campaign_outlined,
                title: presentation.customerTitle,
                detail: profile.sellSide,
              ),
              const SizedBox(height: MoolSpacing.xs),
              _DashboardCapability(
                keyName: 'work-dashboard-sourcing',
                icon: Icons.handshake_outlined,
                title: presentation.networkTitle,
                detail: profile.buySide,
              ),
              const SizedBox(height: MoolSpacing.xs),
              _DashboardCapability(
                keyName: 'work-dashboard-tools',
                icon: Icons.dashboard_customize_outlined,
                title: presentation.toolsTitle,
                detail: profile.tools,
              ),
              const SizedBox(height: MoolSpacing.md),
              _WorkspaceAccountState(session: session, workspace: workspace),
              const SizedBox(height: MoolSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('work-dashboard-manage-record'),
                      onPressed: () =>
                          context.push('/app/work/workspace/proof'),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Workspace record'),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('work-dashboard-add-workspace'),
                      onPressed: () {
                        session.startAnotherWork();
                        context.push('/app/work/workspace/choose');
                      },
                      icon: const Icon(Icons.add_business_outlined),
                      label: const Text('Add Workspace'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRetailerControls(
    BuildContext context, {
    required WorkWorkspace workspace,
    required WorkProfileOption profile,
  }) {
    const dashboardReturn = '/app/work/workspace/dashboard';
    void openRetailer(
      String path, {
      Map<String, String> queryParameters = const {},
    }) {
      context.push(
        Uri(
          path: path,
          queryParameters: {
            ...queryParameters,
            'workspaceId': workspace.id,
            'return': dashboardReturn,
          },
        ).toString(),
      );
    }

    void openScopedRoute(String route) {
      final target = Uri.parse(route);
      if (target.path == '/app/buy' &&
          const {
            'wholesale',
            'business',
          }.contains(target.queryParameters['sub'])) {
        _showProcurement(
          productId: target.queryParameters['product'],
          returnOperation: _view == _WorkspaceControlView.operation
              ? _operation
              : null,
        );
        return;
      }
      if (target.path == '/app/work/workspace/dashboard') {
        _showStatus();
        return;
      }
      if (target.path.startsWith('/app/retailer')) {
        final operation = switch (target.path) {
          '/app/retailer/orders' => _WorkspaceOperation.orders,
          '/app/retailer/customers' => _WorkspaceOperation.customers,
          '/app/retailer/books/money' => _WorkspaceOperation.payments,
          '/app/retailer/books' => _WorkspaceOperation.books,
          '/app/retailer/wholesale' => _WorkspaceOperation.sourcing,
          '/app/retailer/home' when target.queryParameters['view'] == 'stock' =>
            _WorkspaceOperation.catalogue,
          _ => null,
        };
        if (operation != null) {
          _showOperation(operation);
          return;
        }
        openRetailer(target.path, queryParameters: target.queryParameters);
        return;
      }
      context.push(
        target
            .replace(
              queryParameters: {
                ...target.queryParameters,
                'workspaceId': workspace.id,
                'return': dashboardReturn,
              },
            )
            .toString(),
      );
    }

    final title = switch (_view) {
      _WorkspaceControlView.dashboard => workspace.name,
      _WorkspaceControlView.search => 'Search your store',
      _WorkspaceControlView.status => 'Store settings',
      _WorkspaceControlView.alerts => 'Needs your attention',
      _WorkspaceControlView.procurement => 'Wholesale and Bulk',
      _WorkspaceControlView.operation =>
        _operation == _WorkspaceOperation.counterOrder &&
                session.workspaceOrderNeedsDelivery
            ? 'Deliver order'
            : _operation == _WorkspaceOperation.counterOrder
            ? 'New sale'
            : _operation.title,
    };
    final subtitle = switch (_view) {
      _WorkspaceControlView.dashboard => '${profile.label} · ${workspace.area}',
      _WorkspaceControlView.search =>
        'Find orders, products, customers or business records',
      _WorkspaceControlView.status => 'Open, pause and run your store',
      _WorkspaceControlView.alerts => 'Orders and tasks needing action',
      _WorkspaceControlView.procurement => 'Store purchase · ${workspace.name}',
      _WorkspaceControlView.operation =>
        _operation == _WorkspaceOperation.counterOrder &&
                session.workspaceOrderNeedsDelivery
            ? 'Phone, Counter or Chat order with customer delivery'
            : _operation.subtitle,
    };
    final bottomAction = switch (_view) {
      _WorkspaceControlView.status => WorkPrimaryButton(
        keyName: 'work-status-save',
        label: 'Save settings',
        icon: Icons.check_circle_outline_rounded,
        onPressed: _saveAvailability,
      ),
      _ => null,
    };
    final storeActiveId = switch ((_view, _operation)) {
      (_WorkspaceControlView.operation, _WorkspaceOperation.orders) => 'orders',
      (_WorkspaceControlView.operation, _WorkspaceOperation.delivery) =>
        'orders',
      (_WorkspaceControlView.operation, _WorkspaceOperation.counterOrder) =>
        'sell',
      (_WorkspaceControlView.operation, _WorkspaceOperation.catalogue) =>
        'stock',
      (_WorkspaceControlView.operation, _WorkspaceOperation.stockStatement) =>
        'stock',
      (_WorkspaceControlView.operation, _WorkspaceOperation.sourcing) =>
        'stock',
      (_WorkspaceControlView.operation, _WorkspaceOperation.groupBuying) =>
        'stock',
      (
        _WorkspaceControlView.operation,
        _WorkspaceOperation.customers ||
            _WorkspaceOperation.payments ||
            _WorkspaceOperation.growth ||
            _WorkspaceOperation.preview ||
            _WorkspaceOperation.books ||
            _WorkspaceOperation.services ||
            _WorkspaceOperation.settings ||
            _WorkspaceOperation.deliverySettings ||
            _WorkspaceOperation.staff ||
            _WorkspaceOperation.businessRecord ||
            _WorkspaceOperation.offers ||
            _WorkspaceOperation.paidWork ||
            _WorkspaceOperation.statement ||
            _WorkspaceOperation.dues ||
            _WorkspaceOperation.storeLink ||
            _WorkspaceOperation.direct,
      ) =>
        'business',
      (_WorkspaceControlView.status || _WorkspaceControlView.alerts, _) =>
        'business',
      (_WorkspaceControlView.procurement, _) => 'stock',
      _ => 'store',
    };
    final storeActions = [
      MoolLocalNavigationAction(
        keyName: 'work-store-home',
        id: 'store',
        label: 'Store',
        icon: Icons.storefront_outlined,
        onPressed: storeActiveId == 'store'
            ? null
            : _view == _WorkspaceControlView.status
            ? () => unawaited(_leaveSettings())
            : () => unawaited(_navigateFromCounterDraft(_showDashboard)),
      ),
      MoolLocalNavigationAction(
        keyName: 'work-store-orders',
        id: 'orders',
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        onPressed: storeActiveId == 'orders'
            ? null
            : () => unawaited(
                _navigateFromCounterDraft(
                  () => _showOperation(_WorkspaceOperation.orders),
                ),
              ),
      ),
      MoolLocalNavigationAction(
        keyName: 'work-store-sell',
        id: 'sell',
        label: 'Sell',
        icon: Icons.point_of_sale_outlined,
        onPressed: storeActiveId == 'sell'
            ? null
            : () {
                session.prepareWorkspaceOrder(
                  source: 'Counter',
                  fulfilment: 'At the shop',
                );
                _saleSearchController.clear();
                _showOperation(_WorkspaceOperation.counterOrder);
              },
      ),
      MoolLocalNavigationAction(
        keyName: 'work-store-stock',
        id: 'stock',
        label: 'Stock',
        icon: Icons.inventory_2_outlined,
        onPressed: storeActiveId == 'stock'
            ? null
            : () => unawaited(
                _navigateFromCounterDraft(
                  () => _showOperation(_WorkspaceOperation.catalogue),
                ),
              ),
      ),
    ];
    final storeRootSurface =
        _view == _WorkspaceControlView.dashboard ||
        _view == _WorkspaceControlView.search ||
        _view == _WorkspaceControlView.alerts ||
        _view == _WorkspaceControlView.operation;

    final saleOpen =
        _view == _WorkspaceControlView.operation &&
        _operation == _WorkspaceOperation.counterOrder;
    return WorkPageScaffold(
      session: session,
      title: title,
      subtitle: subtitle,
      headerTitle: storeRootSurface
          ? _WorkspaceDashboardHeader(
              session: session,
              workspace: workspace,
              profile: profile,
              searchOpen: _view == _WorkspaceControlView.search || saleOpen,
              keepSearchUtilities: saleOpen,
              searchHint: saleOpen ? 'Search products' : 'Search your store',
              searchController: saleOpen
                  ? _saleSearchController
                  : _searchController,
              searchFocusNode: _searchFocus,
              onSwitchWorkspace: () => _showWorkspaceSwitcher(context),
              onBack: _view == _WorkspaceControlView.operation
                  ? () => unawaited(_leaveOperation())
                  : _view == _WorkspaceControlView.alerts
                  ? _showDashboard
                  : _reviewedOrder != null
                  ? _closeOrderDetails
                  : null,
              onSearch: saleOpen ? _searchFocus.requestFocus : _showSearch,
              onSearchChanged: saleOpen
                  ? (_) => setState(() {})
                  : session.updateWorkspaceSearch,
              onCloseSearch: saleOpen ? _searchFocus.unfocus : _finishSearch,
              onScan: () {
                if (saleOpen) {
                  unawaited(_counterKey.currentState?._scanProduct());
                  return;
                }
                _showOperation(_WorkspaceOperation.catalogue);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) unawaited(_catalogueKey.currentState?._scan());
                });
              },
              onSettings: () => _showStoreSignals(context),
              onAlerts: _showAlerts,
              onProfile: () => _openProfile(context, workspace),
            )
          : null,
      fallbackBackRoute: '/app/work/earn',
      activeLocalAction: 'workspace',
      showBack: !storeRootSurface,
      showHeaderChat: false,
      showTrailingAction: false,
      contextualDestinationLabel: 'Store',
      contextualActiveId: storeActiveId,
      contextualLocalActions: storeActions,
      onBack: switch (_view) {
        _WorkspaceControlView.dashboard =>
          _reviewedOrder == null ? null : _closeOrderDetails,
        _WorkspaceControlView.procurement => _leaveProcurement,
        _WorkspaceControlView.status => () => unawaited(_leaveSettings()),
        _WorkspaceControlView.operation => () => unawaited(_leaveOperation()),
        _WorkspaceControlView.search => _finishSearch,
        _ => _showDashboard,
      },
      manageSystemBack: _view != _WorkspaceControlView.procurement,
      hideNavigationWhenKeyboardVisible: true,
      navigationOverBody: _view == _WorkspaceControlView.procurement,
      resizeToAvoidBottomInset: _view != _WorkspaceControlView.procurement,
      bottomAction: bottomAction,
      body: switch (_view) {
        _WorkspaceControlView.dashboard => _StoreControlDashboard(
          session: session,
          workspace: workspace,
          onSetup: () {
            session.beginRetailerSetup();
            context.push('/app/work/retailer/setup');
          },
          onCustomers: () => _showOperation(_WorkspaceOperation.dues),
          onMoney: () => _showOperation(_WorkspaceOperation.statement),
          onGrow: () => _showOperation(_WorkspaceOperation.offers),
          onOrders: () => _showOperation(_WorkspaceOperation.orders),
          reviewedOrder: _reviewedOrder,
          onReviewOrder: () {
            final order =
                session.currentWorkspaceOrder ??
                session.visibleWorkspaceOrders
                    .where(
                      (order) =>
                          order.id ==
                          (session.currentWorkspaceOrderId ??
                              'current-store-order'),
                    )
                    .firstOrNull;
            if (order != null) setState(() => _reviewedOrder = order);
          },
          onCloseOrder: _closeOrderDetails,
          onNewSale: () {
            session.prepareWorkspaceOrder(
              source: 'Counter',
              fulfilment: 'At the shop',
            );
            _showOperation(_WorkspaceOperation.counterOrder);
          },
          onDeliverOrder: () => _showOperation(_WorkspaceOperation.storeLink),
          onStock: () => _showOperation(_WorkspaceOperation.catalogue),
          onOpenOperation: _showOperation,
          onBuyStock: _showProcurement,
        ),
        _WorkspaceControlView.search => _WorkspaceSearchSurface(
          session: session,
          query: session.workspaceSearchQuery,
          onClear: _clearSearch,
          onOpenRoute: openScopedRoute,
        ),
        _WorkspaceControlView.status => _WorkspaceStatusSurface(
          acceptingOrders: _draftAcceptingOrders,
          visibleToCustomers: _draftVisibleToCustomers,
          fulfilmentMode: _draftFulfilmentMode,
          busyMinutes: _draftBusyMinutes,
          reopensAt: _draftReopensAt,
          openingTime: _draftOpeningTime,
          closingTime: _draftClosingTime,
          maximumActiveOrders: _draftMaximumActiveOrders,
          alertSound: _draftOrderAlertSound,
          alertVibration: _draftOrderAlertVibration,
          onAcceptingChanged: (value) => setState(() {
            _draftAcceptingOrders = value;
            if (!value && _draftReopensAt.isEmpty) {
              _draftReopensAt = 'Tomorrow at 8:00 AM';
            }
          }),
          onVisibilityChanged: (value) => setState(() {
            _draftVisibleToCustomers = value;
          }),
          onFulfilmentChanged: (value) => setState(() {
            _draftFulfilmentMode = value;
          }),
          onBusyMinutesChanged: (value) => setState(() {
            _draftBusyMinutes = value;
          }),
          onReopensChanged: (value) => setState(() {
            _draftReopensAt = value;
          }),
          onOpeningTimeChanged: (value) => setState(() {
            _draftOpeningTime = value;
          }),
          onClosingTimeChanged: (value) => setState(() {
            _draftClosingTime = value;
          }),
          onMaximumActiveOrdersChanged: (value) => setState(() {
            _draftMaximumActiveOrders = value;
          }),
          onAlertSoundChanged: (value) => setState(() {
            _draftOrderAlertSound = value;
          }),
          onAlertVibrationChanged: (value) => setState(() {
            _draftOrderAlertVibration = value;
          }),
          onProductControls: () =>
              _showOperation(_WorkspaceOperation.catalogue),
          onDeliveryControls: () =>
              _showOperation(_WorkspaceOperation.deliverySettings),
          onStaffControls: () => _showOperation(_WorkspaceOperation.staff),
          onPaymentControls: () => _showOperation(_WorkspaceOperation.payments),
          onBusinessDetails: () =>
              _showOperation(_WorkspaceOperation.businessRecord),
        ),
        _WorkspaceControlView.alerts => _WorkspaceAlertsSurface(
          session: session,
          onOpen: openScopedRoute,
          onOpenOperation: _showOperation,
          onOpenOrders: () => openRetailer('/app/retailer/orders'),
          onOpenStatus: _showStatus,
          onDismiss: session.dismissWorkspaceAlert,
        ),
        _WorkspaceControlView.procurement => _StoreProcurementSurface(
          session: widget.procurementSession,
          accountIdentity: widget.accountIdentity,
          accountAuthenticated: widget.accountAuthenticated,
          ready: _procurementReady,
          productId: _procurementProductId,
          onExit: _leaveProcurement,
          onDestinationChanged: _handleProcurementDestinationChanged,
        ),
        _WorkspaceControlView.operation => _WorkspaceOperationSurface(
          operation: _operation,
          session: session,
          procurementSession: widget.procurementSession,
          catalogueKey: _catalogueKey,
          counterKey: _counterKey,
          saleQuery: _saleSearchController.text,
          requirementDraft: _requirementDrafts.putIfAbsent(
            workspace.id,
            () => {},
          ),
          onOpenStore: _showDashboard,
          onOpenOperation: _showOperation,
          onOpenRoute: openScopedRoute,
        ),
      },
    );
  }

  void _showDashboard() {
    _searchFocus.unfocus();
    setState(() {
      _reviewedOrder = null;
      _view = _WorkspaceControlView.dashboard;
    });
  }

  void _closeOrderDetails() => setState(() => _reviewedOrder = null);

  void _showStoreSignals(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Store status',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _ProductPreviewLine(
                label: 'Taking orders',
                value: switch (session.workspaceStoreState) {
                  WorkspaceStoreState.open => 'Open',
                  WorkspaceStoreState.paused => 'Paused',
                  _ => 'Off',
                },
              ),
              _ProductPreviewLine(
                label: 'Storefront',
                value: session.workspaceVisibleToCustomers
                    ? 'Public'
                    : 'Private',
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage opening hours and visibility in your business profile.',
                style: TextStyle(color: MoolColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearch() {
    setState(() => _view = _WorkspaceControlView.search);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _showStatus() {
    _searchFocus.unfocus();
    setState(() {
      _draftAcceptingOrders = session.workspaceAcceptingOrders;
      _draftVisibleToCustomers = session.workspaceVisibleToCustomers;
      _draftFulfilmentMode = session.workspaceFulfilmentMode;
      _draftBusyMinutes = session.workspaceBusyMinutes;
      _draftReopensAt = session.workspaceReopensAt;
      _draftOpeningTime = session.workspaceOpeningTime;
      _draftClosingTime = session.workspaceClosingTime;
      _draftMaximumActiveOrders = session.workspaceMaximumActiveOrders;
      _draftOrderAlertSound = session.workspaceOrderAlertSound;
      _draftOrderAlertVibration = session.workspaceOrderAlertVibration;
      _view = _WorkspaceControlView.status;
    });
  }

  void _showAlerts() {
    _searchFocus.unfocus();
    setState(() => _view = _WorkspaceControlView.alerts);
  }

  void _showOperation(_WorkspaceOperation operation) {
    _searchFocus.unfocus();
    if (operation == _WorkspaceOperation.paidWork) {
      final workspaceId = session.activeWorkspace?.id;
      if (workspaceId == null) return;
      if (_requirementDrafts[workspaceId]?['service'] == null) {
        unawaited(_openRequirementPicker(workspaceId));
        return;
      }
    }
    session.clearMessages();
    if (operation == _WorkspaceOperation.direct) {
      widget.procurementSession.openDestination(BuyV2Destination.wholesale);
      widget.procurementSession.chooseFilter('manufacturer');
    }
    setState(() {
      if (_view == _WorkspaceControlView.status) {
        _operationReturnView = _WorkspaceControlView.status;
        _operationReturnOperation = null;
      } else if (_view == _WorkspaceControlView.operation &&
          _isNestedWorkspaceOperation(operation)) {
        _operationReturnView = _WorkspaceControlView.operation;
        _operationReturnOperation = _operation;
      } else {
        _operationReturnView = _WorkspaceControlView.dashboard;
        _operationReturnOperation = null;
      }
      _operation = operation;
      _view = _WorkspaceControlView.operation;
    });
  }

  Future<void> _openRequirementPicker(String workspaceId) async {
    if (_requirementPickerOpen) return;
    _requirementPickerOpen = true;
    final service = await _chooseStoreRequirement(context);
    _requirementPickerOpen = false;
    if (!mounted ||
        service == null ||
        session.activeWorkspace?.id != workspaceId) {
      return;
    }
    _requirementDrafts.putIfAbsent(workspaceId, () => {})['service'] = service;
    _showOperation(_WorkspaceOperation.paidWork);
  }

  void _showProcurement({
    _WorkspaceOperation? returnOperation,
    String? productId,
  }) {
    _searchFocus.unfocus();
    session.clearMessages();
    setState(() {
      _procurementReturnOperation = returnOperation;
      _procurementProductId = productId;
      _view = _WorkspaceControlView.procurement;
    });
    if (_procurementReady || _procurementRevealTimer != null) return;
    _procurementRevealTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _procurementReady = true);
      _procurementRevealTimer = null;
    });
  }

  void _leaveProcurement() {
    final parent = _procurementReturnOperation;
    setState(() {
      _procurementReturnOperation = null;
      if (parent == null) {
        _view = _WorkspaceControlView.dashboard;
      } else {
        _operation = parent;
        _operationReturnView = _WorkspaceControlView.dashboard;
        _operationReturnOperation = null;
        _view = _WorkspaceControlView.operation;
      }
    });
  }

  bool _isNestedWorkspaceOperation(_WorkspaceOperation operation) => const {
    _WorkspaceOperation.deliverySettings,
    _WorkspaceOperation.staff,
    _WorkspaceOperation.businessRecord,
    _WorkspaceOperation.offers,
    _WorkspaceOperation.paidWork,
    _WorkspaceOperation.stockStatement,
  }.contains(operation);

  bool get _hasCounterOrderDraft =>
      _view == _WorkspaceControlView.operation &&
      _operation == _WorkspaceOperation.counterOrder &&
      (session.workspaceOrderCustomer.trim().isNotEmpty ||
          session.workspaceOrderQuantities.isNotEmpty);

  Future<bool> _confirmDiscardCounterOrder() async {
    if (!_hasCounterOrderDraft) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('work-order-discard-dialog'),
        title: const Text('Leave this sale?'),
        content: const Text(
          'The customer and selected products have not been completed.',
        ),
        actions: [
          TextButton(
            key: const Key('work-order-keep-editing'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            key: const Key('work-order-discard'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard sale'),
          ),
        ],
      ),
    );
    if (discard == true) session.startNewWorkspaceOrder();
    return discard == true;
  }

  Future<void> _leaveOperation() async {
    if (!await _confirmDiscardCounterOrder() || !mounted) return;
    if (_operationReturnView == _WorkspaceControlView.status) {
      _showStatus();
      return;
    }
    final parent = _operationReturnOperation;
    if (_operationReturnView == _WorkspaceControlView.operation &&
        parent != null) {
      setState(() {
        _operation = parent;
        _operationReturnView = _WorkspaceControlView.dashboard;
        _operationReturnOperation = null;
      });
      return;
    }
    _showDashboard();
  }

  Future<void> _navigateFromCounterDraft(VoidCallback destination) async {
    if (!await _confirmDiscardCounterOrder() || !mounted) return;
    destination();
  }

  void _handleProcurementDestinationChanged(BuyV2Destination destination) {
    if (destination != BuyV2Destination.shop ||
        _view != _WorkspaceControlView.procurement) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _view == _WorkspaceControlView.procurement) {
        _leaveProcurement();
      }
    });
  }

  void _openProfile(BuildContext context, WorkWorkspace workspace) {
    showGlobalProfilePanelV2(
      context,
      accountAuthenticated: true,
      activeWorkspace: GlobalProfileWorkspaceContext(
        name: workspace.name,
        roleLabel: workspace.profileLabel,
        area: workspace.area,
      ),
      contextAction: GlobalProfileContextAction(
        id: 'store-settings',
        title: 'Store tools',
        detail: 'Business settings, customers and records',
        actionLabel: 'Manage store',
        icon: Icons.tune_rounded,
        accentColor: MoolColors.navy,
        gradientColors: const [MoolColors.navy, MoolColors.navy],
        onPressed: () => _showOperation(_WorkspaceOperation.settings),
      ),
      onOpenRoute: (route) {
        if (route == '/app/work/my-work') {
          _showOperation(_WorkspaceOperation.settings);
        } else {
          context.push(route);
        }
      },
    );
  }

  Future<void> _showWorkspaceSwitcher(BuildContext context) async {
    final current = session.activeWorkspace;
    if (current == null) return;
    final choices = [current, ...session.otherWorkspaces];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: .72,
          child: Column(
            key: const Key('work-workspace-switcher-sheet'),
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MoolSpacing.md,
                  ),
                  children: [
                    const Text(
                      'Choose your Workspace',
                      style: TextStyle(
                        color: MoolColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: MoolColors.navy,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Create content anytime from Social. Request another Workspace only for a separate business or professional identity.',
                              style: TextStyle(
                                color: MoolColors.ink,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    for (final workspace in choices)
                      ListTile(
                        key: ValueKey('work-switch-${workspace.id}'),
                        leading: Icon(
                          workspace.id == current.id
                              ? Icons.check_circle_rounded
                              : Icons.storefront_outlined,
                          color: MoolColors.navy,
                        ),
                        title: Text(workspace.name),
                        subtitle: Text(
                          '${workspace.profileLabel} · ${workspace.area}',
                        ),
                        selected: workspace.id == current.id,
                        onTap: workspace.id == current.id
                            ? null
                            : () {
                                session.activateWorkspace(workspace);
                                Navigator.of(sheetContext).pop();
                                _showDashboard();
                              },
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  MoolSpacing.md,
                  8,
                  MoolSpacing.md,
                  MediaQuery.viewPaddingOf(sheetContext).bottom + 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('work-switch-add-workspace'),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      session.startAnotherWork();
                      context.push('/app/work/workspace/choose');
                    },
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('Request another Workspace'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    session.updateWorkspaceSearch('');
    _searchFocus.requestFocus();
  }

  void _finishSearch() {
    _searchController.clear();
    session.updateWorkspaceSearch('');
    _showDashboard();
  }

  void _saveAvailability() {
    session.setWorkspaceVisibility(_draftVisibleToCustomers);
    session.saveWorkspaceAvailability(
      acceptingOrders: _draftAcceptingOrders,
      fulfilmentMode: _draftFulfilmentMode,
      busyMinutes: _draftBusyMinutes,
      reopensAt: _draftReopensAt,
    );
    session.saveWorkspaceTradingControls(
      openingTime: _draftOpeningTime,
      closingTime: _draftClosingTime,
      maximumActiveOrders: _draftMaximumActiveOrders,
      alertSound: _draftOrderAlertSound,
      alertVibration: _draftOrderAlertVibration,
    );
    setState(() => _view = _WorkspaceControlView.dashboard);
  }

  bool get _settingsDirty =>
      _draftAcceptingOrders != session.workspaceAcceptingOrders ||
      _draftVisibleToCustomers != session.workspaceVisibleToCustomers ||
      _draftFulfilmentMode != session.workspaceFulfilmentMode ||
      _draftBusyMinutes != session.workspaceBusyMinutes ||
      _draftReopensAt != session.workspaceReopensAt ||
      _draftOpeningTime != session.workspaceOpeningTime ||
      _draftClosingTime != session.workspaceClosingTime ||
      _draftMaximumActiveOrders != session.workspaceMaximumActiveOrders ||
      _draftOrderAlertSound != session.workspaceOrderAlertSound ||
      _draftOrderAlertVibration != session.workspaceOrderAlertVibration;

  Future<void> _leaveSettings() async {
    if (!_settingsDirty) {
      _showDashboard();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('work-settings-discard-dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        title: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0DB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFF9A4A00)),
              SizedBox(width: 8),
              Expanded(child: Text('Unsaved Store settings')),
            ],
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Save these changes or continue editing before leaving.',
              style: TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const FittedBox(child: Text('Keep editing')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB42318),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const FittedBox(child: Text('Discard')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (discard == true && mounted) _showDashboard();
  }
}

enum _WorkspaceControlView {
  dashboard,
  search,
  status,
  alerts,
  procurement,
  operation,
}

class _StoreProcurementSurface extends StatelessWidget {
  const _StoreProcurementSurface({
    required this.session,
    required this.accountIdentity,
    required this.accountAuthenticated,
    required this.ready,
    this.productId,
    required this.onExit,
    required this.onDestinationChanged,
  });

  final BuyV2Session session;
  final AuthenticatedAccountIdentity? accountIdentity;
  final bool accountAuthenticated;
  final bool ready;
  final String? productId;
  final VoidCallback onExit;
  final ValueChanged<BuyV2Destination> onDestinationChanged;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardVisible = media.viewInsets.bottom > 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crop = keyboardVisible ? 116.0 : 0.0;
        final buy = MediaQuery(
          data: media.copyWith(
            size: Size(media.size.width, media.size.height + crop),
            viewInsets: keyboardVisible ? EdgeInsets.zero : media.viewInsets,
            viewPadding: keyboardVisible
                ? media.viewPadding.copyWith(bottom: 0)
                : media.viewPadding,
            padding: keyboardVisible
                ? media.padding.copyWith(bottom: 0)
                : media.padding,
            textScaler: media.textScaler.clamp(
              minScaleFactor: 1,
              maxScaleFactor: 1,
            ),
          ),
          child: BuyV2Screen(
            key: const ValueKey('work-store-procurement-buy-host'),
            session: session,
            accountIdentity: accountIdentity,
            accountAuthenticated: accountAuthenticated,
            initialDestination: BuyV2Destination.wholesale,
            initialView: productId == null
                ? BuyV2View.catalogue
                : BuyV2View.product,
            productId: productId,
            initialCartScope: BuyV2CartScope.wholesale,
            onExit: onExit,
            onDestinationChanged: onDestinationChanged,
          ),
        );
        return Stack(
          key: const Key('work-store-procurement-screen'),
          children: [
            Positioned.fill(
              child: crop == 0
                  ? buy
                  : ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: constraints.maxHeight + crop,
                        maxHeight: constraints.maxHeight + crop,
                        child: SizedBox(
                          height: constraints.maxHeight + crop,
                          child: buy,
                        ),
                      ),
                    ),
            ),
            if (!ready)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0xFFF8FAFF),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          'Preparing Wholesale and Bulk',
                          style: TextStyle(
                            color: MoolColors.navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Your Store remains available while products load.',
                          style: TextStyle(color: MoolColors.muted),
                        ),
                      ],
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

enum _WorkspaceOperation {
  orders,
  counterOrder,
  catalogue,
  stockStatement,
  delivery,
  customers,
  payments,
  books,
  sourcing,
  growth,
  services,
  settings,
  preview,
  groupBuying,
  deliverySettings,
  staff,
  businessRecord,
  offers,
  paidWork,
  statement,
  dues,
  storeLink,
  direct,
}

extension on _WorkspaceOperation {
  String get title => switch (this) {
    _WorkspaceOperation.orders => 'Customer orders',
    _WorkspaceOperation.counterOrder => 'Create customer order',
    _WorkspaceOperation.catalogue => 'Catalogue and stock',
    _WorkspaceOperation.stockStatement => 'Stock statement',
    _WorkspaceOperation.delivery => 'Delivery desk',
    _WorkspaceOperation.customers => 'Customer records',
    _WorkspaceOperation.payments => 'Sales and settlements',
    _WorkspaceOperation.books => 'Business books',
    _WorkspaceOperation.sourcing => 'Wholesale sourcing',
    _WorkspaceOperation.growth => 'Grow your store',
    _WorkspaceOperation.services => 'Business services',
    _WorkspaceOperation.settings => 'Workspace settings',
    _WorkspaceOperation.preview => 'Customer store preview',
    _WorkspaceOperation.groupBuying => 'Group Bulk Buying',
    _WorkspaceOperation.deliverySettings => 'Delivery area and charges',
    _WorkspaceOperation.staff => 'Staff and counters',
    _WorkspaceOperation.businessRecord => 'Business details and documents',
    _WorkspaceOperation.offers => 'Store offers',
    _WorkspaceOperation.paidWork => 'Post requirement',
    _WorkspaceOperation.statement => 'View statement',
    _WorkspaceOperation.dues => 'Collect dues',
    _WorkspaceOperation.storeLink => 'Send store link',
    _WorkspaceOperation.direct => 'Buy Direct',
  };

  String get subtitle => switch (this) {
    _WorkspaceOperation.orders => 'Accept, prepare and complete every order',
    _WorkspaceOperation.counterOrder =>
      'Record counter or phone orders and arrange delivery',
    _WorkspaceOperation.catalogue =>
      'Products, selling prices and available stock',
    _WorkspaceOperation.stockStatement =>
      'Available, reserved and low-stock changes',
    _WorkspaceOperation.delivery =>
      'Assign delivery and follow every customer handoff',
    _WorkspaceOperation.customers =>
      'Purchases, dues and repeat-business history',
    _WorkspaceOperation.payments =>
      'Completed sales, available balance and settlement',
    _WorkspaceOperation.books => 'Sales, purchases, stock and money records',
    _WorkspaceOperation.sourcing =>
      'Compare wholesale supply and replenish stock',
    _WorkspaceOperation.growth =>
      'Bring customers back, publish offers and promote your store',
    _WorkspaceOperation.services =>
      'GST, tax, bookkeeping and audit assistance',
    _WorkspaceOperation.settings =>
      'Store details, documents and additional Workspaces',
    _WorkspaceOperation.preview =>
      'See exactly what customers can discover and order',
    _WorkspaceOperation.groupBuying =>
      'Buy together with verified retailers at a confirmed group price',
    _WorkspaceOperation.deliverySettings =>
      'Customer service area, delivery fee and free-delivery threshold',
    _WorkspaceOperation.staff => 'Counter capacity and controlled staff access',
    _WorkspaceOperation.businessRecord =>
      'Approved business identity and submitted documents',
    _WorkspaceOperation.offers =>
      'Create offers that bring customers back to your Store',
    _WorkspaceOperation.paidWork =>
      'Publish a funded Store requirement for eligible candidates',
    _WorkspaceOperation.statement => 'Sales, purchases and expenses',
    _WorkspaceOperation.dues => 'Customer balances and unpaid invoices',
    _WorkspaceOperation.storeLink => 'Let customers order from your store',
    _WorkspaceOperation.direct =>
      'Manufacturer prices. Delivered to your store.',
  };
}

enum _QuickStoreState { open, paused, off }

class _WorkspaceDashboardHeader extends StatelessWidget {
  const _WorkspaceDashboardHeader({
    required this.session,
    required this.workspace,
    required this.profile,
    required this.searchOpen,
    this.searchHint = 'Search your store',
    this.keepSearchUtilities = false,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSwitchWorkspace,
    this.onBack,
    required this.onSearch,
    required this.onSearchChanged,
    required this.onCloseSearch,
    required this.onScan,
    required this.onSettings,
    required this.onAlerts,
    required this.onProfile,
  });

  final WorkSession session;
  final WorkWorkspace workspace;
  final WorkProfileOption profile;
  final bool searchOpen;
  final String searchHint;
  final bool keepSearchUtilities;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSwitchWorkspace;
  final VoidCallback? onBack;
  final VoidCallback onSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCloseSearch;
  final VoidCallback onScan;
  final VoidCallback onSettings;
  final VoidCallback onAlerts;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        key: const Key('work-dashboard-inline-header'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (onBack != null) ...[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    key: const Key('work-operation-back'),
                    tooltip: 'Back',
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: MoolColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
              ],
              Expanded(
                child: Semantics(
                  container: true,
                  button: true,
                  label:
                      '${workspace.name}, ${profile.label}, ${workspace.area}. Change Workspace',
                  child: InkWell(
                    key: const Key('work-dashboard-workspace-switcher'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: onSwitchWorkspace,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 15,
                            color: MoolColors.navy,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              workspace.name,
                              style: const TextStyle(
                                color: MoolColors.navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: MoolColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label:
                    '${session.workspaceStoreState == WorkspaceStoreState.open
                        ? 'Open'
                        : session.workspaceStoreState == WorkspaceStoreState.paused
                        ? 'Paused'
                        : 'Off'}, ${session.workspaceVisibleToCustomers ? 'public storefront' : 'private storefront'}. Store status',
                child: Material(
                  key: const Key('work-dashboard-settings'),
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onSettings,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        minWidth: 48,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              session.workspaceStoreState ==
                                      WorkspaceStoreState.open
                                  ? Icons.radio_button_checked_rounded
                                  : session.workspaceStoreState ==
                                        WorkspaceStoreState.paused
                                  ? Icons.pause_circle_outline_rounded
                                  : Icons.power_settings_new_rounded,
                              size: 16,
                              color: MoolColors.navy,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              session.workspaceVisibleToCustomers
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 16,
                              color: MoolColors.navy,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Container(
                  key: const Key('work-dashboard-inline-search-band'),
                  height: 44,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFDCE2F2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: searchOpen
                            ? TextField(
                                key: const Key('work-dashboard-search-field'),
                                controller: searchController,
                                focusNode: searchFocusNode,
                                autofocus: false,
                                onChanged: onSearchChanged,
                                textInputAction: TextInputAction.search,
                                style: const TextStyle(
                                  color: MoolColors.navy,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                                decoration: InputDecoration(
                                  hintText: searchHint,
                                  hintStyle: const TextStyle(
                                    color: MoolColors.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: MoolColors.navy,
                                    size: 21,
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 42,
                                    minHeight: 44,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              )
                            : Semantics(
                                key: const Key('work-dashboard-search'),
                                button: true,
                                label:
                                    'Search orders, products, customers or invoices',
                                child: InkWell(
                                  onTap: onSearch,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.search_rounded,
                                          color: MoolColors.navy,
                                          size: 21,
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              searchController.text
                                                      .trim()
                                                      .isEmpty
                                                  ? 'Search your store'
                                                  : searchController.text
                                                        .trim(),
                                              maxLines: 1,
                                              style: TextStyle(
                                                color:
                                                    searchController.text
                                                        .trim()
                                                        .isEmpty
                                                    ? MoolColors.muted
                                                    : MoolColors.navy,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
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
                      if (searchOpen && searchController.text.isNotEmpty)
                        IconButton(
                          key: const Key('work-dashboard-search-clear'),
                          tooltip: 'Clear search',
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 20),
                          constraints: const BoxConstraints.tightFor(
                            width: 40,
                            height: 44,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      if (!searchOpen || keepSearchUtilities)
                        _HeaderSearchUtility(
                          key: const Key('work-dashboard-scan'),
                          tooltip: 'Scan product barcode',
                          onTap: onScan,
                          icon: Icons.qr_code_scanner_rounded,
                        ),
                      if (searchOpen && !keepSearchUtilities)
                        IconButton(
                          key: const Key('work-dashboard-search-close'),
                          tooltip: 'Finish search',
                          onPressed: onCloseSearch,
                          icon: const Icon(Icons.check_rounded, size: 21),
                          color: MoolColors.navy,
                          constraints: const BoxConstraints.tightFor(
                            width: 44,
                            height: 44,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
              ),
              if (!searchOpen || keepSearchUtilities) ...[
                const SizedBox(width: 6),
                _DashboardAlertButton(
                  count: _workspaceAlerts(session).length,
                  onPressed: onAlerts,
                ),
                const SizedBox(width: 4),
                MoolGlobalProfileShortcutV2(
                  keyName: 'work-dashboard-profile',
                  onPressed: onProfile,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderSearchUtility extends StatelessWidget {
  const _HeaderSearchUtility({
    required this.tooltip,
    required this.onTap,
    required this.icon,
    super.key,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox(width: 44, height: 48, child: Icon(icon, size: 18)),
      ),
    );
  }
}

class _StoreControlDashboard extends StatelessWidget {
  const _StoreControlDashboard({
    required this.session,
    required this.workspace,
    required this.onSetup,
    required this.onCustomers,
    required this.onMoney,
    required this.onGrow,
    required this.onOrders,
    required this.onNewSale,
    required this.onDeliverOrder,
    required this.onStock,
    required this.onOpenOperation,
    required this.onBuyStock,
    required this.reviewedOrder,
    required this.onReviewOrder,
    required this.onCloseOrder,
  });

  final WorkSession session;
  final WorkWorkspace workspace;
  final VoidCallback onSetup, onCustomers, onMoney, onGrow, onOrders;
  final VoidCallback onNewSale, onDeliverOrder, onStock, onBuyStock;
  final ValueChanged<_WorkspaceOperation> onOpenOperation;
  final WorkspaceOrderRecord? reviewedOrder;
  final VoidCallback onReviewOrder, onCloseOrder;

  @override
  Widget build(BuildContext context) {
    final ready =
        session.retailerSetupSaved ||
        session.reviewStage == WorkReviewStage.live;
    return Material(
      key: const Key('work-workspace-dashboard'),
      color: const Color(0xFFF7F8FC),
      child: Column(
        children: [
          if (ready)
            _StoreLiveBusinessPulse(
              session: session,
              onOrders: onCustomers,
              onSales: onMoney,
              onStock: onStock,
              onSettlement: () => onOpenOperation(_WorkspaceOperation.payments),
            ),
          if (session.workspaceDashboardState != WorkspaceDashboardState.ready)
            _DashboardSyncBanner(session: session),
          Expanded(
            child: ready
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _StoreActivityDeck(
                          key: const Key('store-stable-working-centre'),
                          session: session,
                          reviewedOrder: reviewedOrder,
                          onReviewOrder: onReviewOrder,
                          onCloseOrder: onCloseOrder,
                          onStock: onStock,
                          onMoney: onMoney,
                          onGroupBulk: () =>
                              onOpenOperation(_WorkspaceOperation.groupBuying),
                        ),
                      ),
                      _StoreActionEdge(
                        session: session,
                        onRestock: onBuyStock,
                        onDirect: () =>
                            onOpenOperation(_WorkspaceOperation.direct),
                        onGroup: () =>
                            onOpenOperation(_WorkspaceOperation.groupBuying),
                      ),
                    ],
                  )
                : _StoreSetupDeck(
                    session: session,
                    workspace: workspace,
                    onSetup: onSetup,
                  ),
          ),
          if (ready)
            _StoreReachStrip(
              onLink: onDeliverOrder,
              onPromote: onGrow,
              onRequirement: () =>
                  onOpenOperation(_WorkspaceOperation.paidWork),
            ),
        ],
      ),
    );
  }
}

class _StoreActionEdge extends StatelessWidget {
  const _StoreActionEdge({
    required this.session,
    required this.onRestock,
    required this.onDirect,
    required this.onGroup,
  });
  final WorkSession session;
  final VoidCallback onRestock, onDirect, onGroup;

  @override
  Widget build(BuildContext context) {
    final deal = session.activeGroupBuy;
    return Container(
      key: const Key('work-store-action-edge'),
      width: MediaQuery.sizeOf(context).width < 360 ? 80 : 92,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE5E8F1))),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            _StoreEdgeAction(
              keyName: 'work-quick-buy',
              icon: Icons.inventory_2_outlined,
              label: 'Restock',
              onTap: onRestock,
              detail: session.workspaceLowStockCount > 0
                  ? '${session.workspaceLowStockCount} low stock'
                  : null,
            ),
            const Divider(height: 24, indent: 16, endIndent: 16),
            _StoreEdgeAction(
              keyName: 'work-quick-direct',
              icon: Icons.factory_outlined,
              label: 'Buy Direct',
              onTap: onDirect,
            ),
            const Divider(height: 24, indent: 16, endIndent: 16),
            _StoreEdgeAction(
              keyName: 'work-quick-group-buy',
              icon: Icons.groups_2_outlined,
              label: 'Group Bulk Buying',
              onTap: onGroup,
              detail: deal == null
                  ? null
                  : '${deal.productName}\n₹${deal.groupUnitPrice}/${deal.unitLabel}',
              progress: deal == null || deal.targetQuantity <= 0
                  ? null
                  : (deal.securedQuantity / deal.targetQuantity).clamp(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreEdgeAction extends StatelessWidget {
  const _StoreEdgeAction({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.progress,
  });
  final String keyName, label;
  final String? detail;
  final IconData icon;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: detail == null ? label : '$label, $detail',
    excludeSemantics: true,
    child: InkWell(
      key: Key(keyName),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64, minWidth: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            children: [
              Icon(icon, size: 25, color: MoolColors.navy),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: MoolColors.navy,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 8),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: MoolColors.muted,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: 8),
                Semantics(
                  label: 'Group quantity confirmed',
                  value: '${(progress! * 100).round()} percent',
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    color: MoolColors.navy,
                    backgroundColor: const Color(0xFFE8EBF6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _StoreReachStrip extends StatelessWidget {
  const _StoreReachStrip({
    required this.onLink,
    required this.onPromote,
    required this.onRequirement,
  });
  final VoidCallback onLink, onPromote, onRequirement;

  @override
  Widget build(BuildContext context) => Material(
    key: const Key('work-store-reach-strip'),
    color: Colors.white,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E8F1))),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _action(
              'work-quick-store-link',
              Icons.link_rounded,
              'Send store link',
              onLink,
            ),
            const VerticalDivider(width: 1, indent: 12, endIndent: 12),
            _action(
              'work-quick-promote',
              Icons.campaign_outlined,
              'Promote store',
              onPromote,
            ),
            const VerticalDivider(width: 1, indent: 12, endIndent: 12),
            _action(
              'work-quick-requirement',
              Icons.post_add_rounded,
              'Post requirement',
              onRequirement,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _action(String key, IconData icon, String label, VoidCallback onTap) =>
      Expanded(
        flex: key == 'work-quick-requirement' ? 13 : 10,
        child: InkWell(
          key: Key(key),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 19, color: MoolColors.navy),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: MoolColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _StoreLiveBusinessPulse extends StatelessWidget {
  const _StoreLiveBusinessPulse({
    required this.session,
    required this.onOrders,
    required this.onSales,
    required this.onStock,
    required this.onSettlement,
  });

  final WorkSession session;
  final VoidCallback onOrders;
  final VoidCallback onSales;
  final VoidCallback onStock;
  final VoidCallback onSettlement;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Store finances',
      child: Container(
        key: const Key('work-live-status-bubbles'),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE5E8F1))),
        ),
        child: IntrinsicHeight(
          key: const Key('work-store-live-business-pulse'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StorePulseMetric(
                keyName: 'work-pulse-sales',
                label: 'View statement',
                value: '₹${_formatStoreAmount(session.workspaceSalesToday)}',
                icon: Icons.point_of_sale_outlined,
                onTap: onSales,
              ),
              _StorePulseDivider(),
              _StorePulseMetric(
                keyName: 'work-pulse-dues',
                label: 'Collect dues',
                value:
                    '₹${_formatStoreAmount(session.workspaceCustomerBook.fold<int>(0, (total, customer) => total + customer.amountDue))}',
                icon: Icons.payments_outlined,
                onTap: onOrders,
              ),
              _StorePulseDivider(),
              _StorePulseMetric(
                keyName: 'work-pulse-settlement',
                label: 'Settle',
                value:
                    '₹${_formatStoreAmount(session.workspaceSettlementEligible)}',
                icon: Icons.account_balance_wallet_outlined,
                onTap: onSettlement,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorePulseDivider extends StatelessWidget {
  const _StorePulseDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 28,
      child: VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E7F4)),
    );
  }
}

class _StorePulseMetric extends StatelessWidget {
  const _StorePulseMetric({
    required this.keyName,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String keyName;
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = MoolColors.navy;
    return Expanded(
      child: Semantics(
        button: true,
        label: '$label, $value',
        excludeSemantics: true,
        child: InkWell(
          key: Key(keyName),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          child: FittedBox(
                            key: ValueKey(value),
                            fit: BoxFit.scaleDown,
                            child: Text(
                              value,
                              maxLines: 1,
                              style: TextStyle(
                                color: accent,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

class _StoreActivityDeck extends StatelessWidget {
  const _StoreActivityDeck({
    required this.session,
    required this.onReviewOrder,
    required this.onCloseOrder,
    required this.reviewedOrder,
    required this.onStock,
    required this.onMoney,
    required this.onGroupBulk,
    super.key,
  });
  final WorkSession session;
  final WorkspaceOrderRecord? reviewedOrder;
  final VoidCallback onReviewOrder, onCloseOrder, onStock, onMoney, onGroupBulk;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (reviewedOrder case final selected?) {
      final record =
          session.visibleWorkspaceOrders
              .where((order) => order.id == selected.id)
              .firstOrNull ??
          selected;
      content = _StoreOrderDetails(
        session: session,
        order: record,
        onClose: onCloseOrder,
      );
    } else if (session.hasActiveWorkspaceOrder) {
      content = switch (session.workspaceOrderStage) {
        'Preparing' => _PackingActivityCard(session: session),
        'Ready for pickup' => _PickupReadyActivityCard(session: session),
        'Ready' ||
        'Delivery requested' => _DeliveryActivityCard(session: session),
        _ => _IncomingOrderActivityCard(
          session: session,
          onReview: onReviewOrder,
          onReject: () => _showRejectOrderSheet(context, session),
        ),
      };
    } else if (session.latestWorkspaceInvoice?.needsCustomerHandoff == true) {
      content = _InvoiceReadyActivityCard(
        session: session,
        invoice: session.latestWorkspaceInvoice!,
      );
    } else if (session.activeGroupBuy != null) {
      content = _GroupBulkActivityCard(
        groupBuy: session.activeGroupBuy!,
        onOpen: onGroupBulk,
      );
    } else if (session.workspaceLowStockCount > 0) {
      content = _StockActivityCard(session: session, onOpen: onStock);
    } else if (session.workspaceSettlementBalance > 0) {
      content = _MoneyActivityCard(session: session, onOpen: onMoney);
    } else {
      content = const _StoreReadyActivity();
    }
    return Padding(
      key: const Key('work-store-activity-deck'),
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.sizeOf(context).height < 650 ? 6 : 14,
        12,
        MediaQuery.sizeOf(context).height < 650 ? 6 : 14,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
          final desiredHeight = switch (content) {
            _StoreOrderDetails() => largeText ? 580.0 : 520.0,
            _StoreReadyActivity() => 230.0,
            _IncomingOrderActivityCard() =>
              largeText
                  ? 350.0 + session.workspacePackingLines.length * 48
                  : 272.0 + session.workspacePackingLines.length * 36,
            _PackingActivityCard() => largeText ? 480.0 : 410.0,
            _PickupReadyActivityCard() => 300.0,
            _InvoiceReadyActivityCard() => 350.0,
            _ => 420.0,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SizedBox(
                  height: desiredHeight.clamp(0, constraints.maxHeight),
                  child: _ActivityDeckShell(child: content),
                ),
              ),
              if (reviewedOrder == null &&
                  constraints.maxHeight > desiredHeight + 100 &&
                  session.visibleWorkspaceOrders.any(
                    (order) => order.stage == 'Completed',
                  ))
                _StoreRecentSale(session: session, onOpen: onMoney),
            ],
          );
        },
      ),
    );
  }
}

class _StoreRecentSale extends StatelessWidget {
  const _StoreRecentSale({required this.session, required this.onOpen});
  final WorkSession session;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final completed =
        session.visibleWorkspaceOrders
            .where((order) => order.stage == 'Completed')
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Padding(
      key: const Key('work-store-recent-sales'),
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Recent sales',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MoolColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          for (final order in completed.take(2))
            InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: MoolColors.navy,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customer.split('·').first.trim(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.payment,
                            style: const TextStyle(
                              fontSize: 11,
                              color: MoolColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '₹${_formatStoreAmount(order.amount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MoolColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityDeckShell extends StatelessWidget {
  const _ActivityDeckShell({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 1,
    shadowColor: const Color(0x12000080),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE1E5EF)),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

void _advanceDeskOrder(WorkSession session, {String? expectedOrderId}) {
  if (expectedOrderId != null &&
      (session.currentWorkspaceOrderId ?? 'current-store-order') !=
          expectedOrderId) {
    session.showError('This order has changed. Review it before continuing.');
    return;
  }
  final previous = session.workspaceOrderStage;
  final deadline =
      session.currentWorkspaceOrder?.actionDeadline ??
      session.workspaceOrderActionDeadline;
  if (previous == 'Confirmed' &&
      deadline != null &&
      !deadline.isAfter(DateTime.now())) {
    session.showError('Acceptance time ended. Waiting for an order update.');
    return;
  }
  session.advanceWorkspaceOrder();
  // The changed working surface is the acknowledgement; do not shift its
  // controls with a second success banner. Retain every error and other notice.
  if (session.errorMessage == null &&
      previous != session.workspaceOrderStage &&
      session.noticeMessage ==
          'Order is now ${session.workspaceOrderStage.toLowerCase()}.') {
    session.dismissMessages();
  }
}

class _IncomingOrderActivityCard extends StatelessWidget {
  const _IncomingOrderActivityCard({
    required this.session,
    required this.onReview,
    required this.onReject,
  });
  final WorkSession session;
  final VoidCallback onReview, onReject;

  @override
  Widget build(BuildContext context) {
    final lines = session.workspacePackingLines;
    final units = lines.fold<int>(0, (sum, line) => sum + line.quantity);
    final origin = session.workspaceOrderSource == 'App'
        ? 'MoolSocial order'
        : '${session.workspaceOrderSource} order';
    final collection = session.workspaceOrderFulfilment == 'Pickup'
        ? 'Customer pickup'
        : session.workspaceOrderFulfilment;
    final amount =
        '₹${_formatStoreAmount(int.tryParse(session.workspaceOrderAmount) ?? 0)}';
    final compact = MediaQuery.sizeOf(context).height < 650;
    return GestureDetector(
      key: const Key('work-activity-incoming-order'),
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 380 && !session.busy) {
          _advanceDeskOrder(session);
        } else if (velocity < -380 && !session.busy) {
          onReject();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(14, compact ? 8 : 14, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!compact)
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 15,
                          color: MoolColors.navy,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            origin,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: MoolColors.navy,
                              letterSpacing: .1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: compact ? 0 : 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          session.workspaceOrderCustomer
                              .split('·')
                              .first
                              .trim(),
                          style: TextStyle(
                            fontSize: compact ? 14 : 18,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141633),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            amount,
                            style: TextStyle(
                              fontSize: compact ? 18 : 24,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: MoolColors.navy,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          collection,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            color: MoolColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          session.workspaceOrderPayment,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: MoolColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 25, color: Color(0xFFE6E9F2)),
                  Text(
                    lines.isEmpty
                        ? 'Items not supplied'
                        : '${lines.length} ${lines.length == 1 ? 'product' : 'products'} · $units ${units == 1 ? 'unit' : 'units'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MoolColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final line in lines)
                    _DeskItemLine(label: line.label, quantity: line.quantity),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFFF3F5FD),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 5, color: MoolColors.navy),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Awaiting acceptance',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: MoolColors.navy,
                    ),
                  ),
                ),
                if (session.workspaceOrderActionDeadline != null) ...[
                  const SizedBox(width: 5),
                  Flexible(
                    child: _LiveCountdownText(
                      deadline: session.workspaceOrderActionDeadline,
                      fallback: 'Review now',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: MoolColors.navy,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const Key('work-activity-order-review'),
                    onPressed: onReview,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                    ),
                    child: const Text(
                      'View details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _DeskCustomerActions(
                  customer: session.workspaceOrderCustomer,
                  orderId:
                      session.currentWorkspaceOrderId ?? 'current-store-order',
                ),
              ],
            ),
          ),
          _OrderDecisionButtons(
            busy: session.busy,
            onAccept: () => _advanceDeskOrder(session),
            onReject: onReject,
          ),
        ],
      ),
    );
  }
}

class _DeskItemLine extends StatelessWidget {
  const _DeskItemLine({required this.label, required this.quantity});
  final String label;
  final int quantity;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: MoolColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '× $quantity',
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: MoolColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DeskCustomerActions extends StatelessWidget {
  const _DeskCustomerActions({required this.customer, required this.orderId});
  final String customer, orderId;
  @override
  Widget build(BuildContext context) {
    final phone = customer.replaceAll(RegExp(r'[^0-9]'), '');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('work-activity-order-call'),
          tooltip: phone.length >= 10
              ? 'Call customer'
              : 'Phone number unavailable',
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.call_outlined,
            size: 19,
            color: MoolColors.navy,
          ),
          onPressed: phone.length < 10
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    if (await launchUrl(Uri(scheme: 'tel', path: phone))) {
                      return;
                    }
                  } catch (_) {
                    // The installed phone handler owns the call.
                  }
                  if (context.mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not open your phone app. Please try again.',
                        ),
                      ),
                    );
                  }
                },
        ),
        IconButton(
          key: const Key('work-activity-order-chat'),
          tooltip: 'Chat about this order',
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 19,
            color: MoolColors.navy,
          ),
          onPressed: () => context.push(
            Uri(
              path: '/app/chat/inbox',
              queryParameters: {
                'return': GoRouterState.of(context).uri.toString(),
                'type': 'business',
                'recipient': customer,
                'draft': 'Question about your order $orderId',
              },
            ).toString(),
          ),
        ),
      ],
    );
  }
}

class _OrderDecisionButtons extends StatelessWidget {
  const _OrderDecisionButtons({
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });
  final bool busy;
  final VoidCallback onAccept, onReject;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('work-activity-order-reject'),
            onPressed: busy ? null : onReject,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 48),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              side: const BorderSide(color: Color(0xFFD7DCED)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reject', style: TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            key: const Key('work-activity-order-accept'),
            onPressed: busy ? null : onAccept,
            style: FilledButton.styleFrom(
              minimumSize: const Size(44, 48),
              backgroundColor: MoolColors.navy,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Accept', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    ),
  );
}

class _StoreOrderDetails extends StatelessWidget {
  const _StoreOrderDetails({
    required this.session,
    required this.order,
    required this.onClose,
  });
  final WorkSession session;
  final WorkspaceOrderRecord order;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final active =
        (session.currentWorkspaceOrderId ?? 'current-store-order') ==
            order.id &&
        session.hasActiveWorkspaceOrder;
    final awaiting = active && session.workspaceOrderStage == 'Confirmed';
    return Column(
      key: const Key('work-store-exact-order'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: MoolColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_formatStoreAmount(order.amount)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: MoolColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: const Key('work-order-details-close'),
                tooltip: 'Close details',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 19),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            key: ValueKey('store-detail-${order.id}'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              Text(
                order.customer,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  color: MoolColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              _detail('Status', awaiting ? 'Awaiting acceptance' : order.stage),
              _detail(
                'Placed through',
                order.source == 'App' ? 'MoolSocial' : order.source,
              ),
              _detail('Payment', order.payment),
              _detail('Fulfilment', order.fulfilment),
              if (order.address.isNotEmpty)
                _detail('Deliver to', order.address),
              const Divider(height: 24),
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: MoolColors.navy,
                ),
              ),
              const SizedBox(height: 5),
              if (active)
                for (final line in session.workspacePackingLines)
                  _DeskItemLine(label: line.label, quantity: line.quantity)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    order.items,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              if (order.actionDeadline != null) ...[
                const SizedBox(height: 8),
                _LiveCountdownText(
                  deadline: order.actionDeadline,
                  fallback: 'Review now',
                  style: const TextStyle(fontSize: 12, color: MoolColors.muted),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: _DeskCustomerActions(
                  customer: order.customer,
                  orderId: order.id,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (awaiting)
          _OrderDecisionButtons(
            busy: session.busy,
            onAccept: () {
              final previous = session.workspaceOrderStage;
              _advanceDeskOrder(session, expectedOrderId: order.id);
              if (session.errorMessage == null &&
                  session.workspaceOrderStage != previous) {
                onClose();
              }
            },
            onReject: () => _showRejectOrderSheet(context, session),
          ),
      ],
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: MoolColors.muted),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: MoolColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PackingActivityCard extends StatelessWidget {
  const _PackingActivityCard({required this.session});
  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final lines = session.workspacePackingLines;
    final total = lines.fold<int>(0, (sum, line) => sum + line.quantity);
    final packed = lines
        .where((line) => line.packed)
        .fold<int>(0, (sum, line) => sum + line.quantity);
    return Column(
      key: const Key('work-activity-packing'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: MoolColors.navy,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'PACKING NOW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: MoolColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                session.workspaceOrderCustomer.split('·').first.trim(),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Order ₹${_formatStoreAmount(int.tryParse(session.workspaceOrderAmount) ?? 0)}',
                style: const TextStyle(fontSize: 13, color: MoolColors.muted),
              ),
              const SizedBox(height: 16),
              TweenAnimationBuilder<double>(
                tween: Tween(end: total == 0 ? 0 : packed / total),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                builder: (context, progress, _) => LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  color: MoolColors.navy,
                  backgroundColor: const Color(0xFFE9ECF6),
                  borderRadius: BorderRadius.circular(5),
                  semanticsLabel:
                      'Packing progress, $packed of $total units packed',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$packed of $total units packed',
                style: const TextStyle(
                  fontSize: 12,
                  color: MoolColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(height: 24),
              for (final line in lines)
                CheckboxListTile(
                  key: Key('work-pack-${line.id}'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.trailing,
                  activeColor: MoolColors.navy,
                  value: line.packed,
                  onChanged: session.busy
                      ? null
                      : (value) => session.setWorkspacePackingLine(
                          line.id,
                          value == true,
                        ),
                  title: Text(
                    '${line.label} × ${line.quantity}',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (session.workspaceOrderActionDeadline != null) ...[
                const SizedBox(height: 8),
                _LiveCountdownText(
                  deadline: session.workspaceOrderActionDeadline,
                  fallback: 'In progress',
                  style: const TextStyle(fontSize: 11, color: MoolColors.muted),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              IconButton(
                key: const Key('work-packing-contact-customer'),
                tooltip: 'Packing problem? Message customer',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
                onPressed: () => context.push(
                  Uri(
                    path: '/app/chat/inbox',
                    queryParameters: {
                      'return': GoRouterState.of(context).uri.toString(),
                      'type': 'business',
                      'recipient': session.workspaceOrderCustomer,
                      'draft':
                          'I need to confirm a product or quantity in your ₹${session.workspaceOrderAmount} order.',
                    },
                  ).toString(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: const Key('work-activity-mark-ready'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 48),
                    backgroundColor: MoolColors.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: !session.busy && session.workspacePackingComplete
                      ? () => _advanceDeskOrder(session)
                      : null,
                  child: const Text(
                    'Mark ready',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickupReadyActivityCard extends StatelessWidget {
  const _PickupReadyActivityCard({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('work-activity-pickup-ready'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LiveDot(color: Color(0xFF08765D)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'READY FOR PICKUP',
                  maxLines: 1,
                  style: TextStyle(
                    color: Color(0xFF08765D),
                    fontSize: 11,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _LiveCountdownText(
                deadline: session.workspaceOrderActionDeadline,
                fallback: 'Ready at counter',
                style: const TextStyle(
                  color: Color(0xFF08765D),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFE8F7F1),
                child: Icon(
                  Icons.store_mall_directory_rounded,
                  color: Color(0xFF08765D),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.workspaceOrderCustomer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${session.workspaceOrderPayment} · ₹${session.workspaceOrderAmount}',
                      style: const TextStyle(color: MoolColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            session.workspaceOrderItems,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('work-confirm-customer-pickup'),
              onPressed: session.workspaceHandoverBusy
                  ? null
                  : () => _showWorkspacePickupSheet(context, session),
              icon: const Icon(Icons.password_rounded),
              label: const FittedBox(
                child: Text('Confirm pickup code & create invoice'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showWorkspacePickupSheet(
  BuildContext context,
  WorkSession session,
) async {
  final pageContext = context;
  var pickupCode = '';
  String? error;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          MediaQuery.viewInsetsOf(context).bottom +
              MediaQuery.viewPaddingOf(context).bottom +
              18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirm customer pickup',
                style: TextStyle(
                  color: MoolColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${session.workspaceOrderCustomer} · ₹${session.workspaceOrderAmount}',
                style: const TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter the 6-digit pickup code shown to the customer. The invoice is created after confirmation.',
                style: TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('work-pickup-code'),
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                onChanged: (value) => pickupCode = value,
                decoration: InputDecoration(
                  labelText: 'Customer pickup code',
                  errorText: error,
                  prefixIcon: const Icon(Icons.password_rounded),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('work-pickup-confirm'),
                onPressed: session.workspaceHandoverBusy
                    ? null
                    : () async {
                        final success = await session.verifyWorkspacePickup(
                          pickupCode,
                        );
                        if (!sheetContext.mounted) return;
                        if (!success) {
                          setSheetState(() => error = session.errorMessage);
                          return;
                        }
                        final invoice = session.latestWorkspaceInvoice;
                        Navigator.of(sheetContext).pop();
                        await Future<void>.delayed(
                          const Duration(milliseconds: 260),
                        );
                        if (invoice != null && pageContext.mounted) {
                          await _showWorkspaceInvoiceSheet(
                            pageContext,
                            session,
                            invoice,
                          );
                        }
                      },
                icon: const Icon(Icons.verified_rounded),
                label: const Text('Confirm pickup'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _InvoiceReadyActivityCard extends StatelessWidget {
  const _InvoiceReadyActivityCard({
    required this.session,
    required this.invoice,
  });
  final WorkSession session;
  final WorkspaceCustomerInvoice invoice;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('work-activity-invoice'),
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: MoolColors.navy,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Invoice ready',
                      style: TextStyle(
                        color: MoolColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                invoice.customer,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                invoice.id,
                style: const TextStyle(color: MoolColors.muted, fontSize: 12),
              ),
              const Divider(height: 20),
              Text(
                '₹${_formatStoreAmount(invoice.amount)}',
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                invoice.payment,
                style: const TextStyle(color: MoolColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('work-invoice-open'),
            onPressed: () =>
                _showWorkspaceInvoiceSheet(context, session, invoice),
            icon: const Icon(Icons.send_outlined, size: 18),
            label: const Text('Send invoice'),
          ),
        ),
      ),
    ],
  );
}

Future<void> _showWorkspaceInvoiceSheet(
  BuildContext context,
  WorkSession session,
  WorkspaceCustomerInvoice invoice,
) async {
  final returnRoute = GoRouterState.of(context).uri.toString();
  final router = GoRouter.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Send customer invoice',
                      style: TextStyle(
                        color: MoolColors.navy,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close invoice',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                '${invoice.id} · ${invoice.customer}',
                style: const TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${invoice.amount}',
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(invoice.items),
                    Text(
                      invoice.payment,
                      style: const TextStyle(color: MoolColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose the channel approved by the customer. Their purchase stays connected to your Store for repeat orders.',
                style: TextStyle(color: MoolColors.muted, height: 1.35),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('work-invoice-share-chat'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  session.markWorkspaceInvoiceShared(
                    invoice.id,
                    'MoolSocial Chat',
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    router.push(
                      Uri(
                        path: '/app/chat/inbox',
                        queryParameters: {
                          'type': 'business',
                          'return': returnRoute,
                          'recipient': invoice.customer,
                          'draft':
                              '${invoice.id} · ₹${invoice.amount} · ${invoice.items}',
                        },
                      ).toString(),
                    );
                  });
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Send in MoolSocial Chat'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('work-invoice-share-whatsapp'),
                onPressed: () async {
                  final digits = invoice.customer.replaceAll(RegExp(r'\D'), '');
                  final mobile = digits.length == 10 ? '91$digits' : digits;
                  final message = Uri.encodeComponent(
                    '${invoice.id} from ${session.activeWorkspace?.name ?? session.workName}\n'
                    '${invoice.items}\nTotal ₹${invoice.amount} · ${invoice.payment}\n'
                    'Keep this invoice and join MoolSocial for repeat orders, savings and delivery updates.',
                  );
                  final opened =
                      mobile.isNotEmpty &&
                      await launchUrl(
                        Uri.parse('https://wa.me/$mobile?text=$message'),
                        mode: LaunchMode.externalApplication,
                      );
                  if (opened) {
                    session.markWorkspaceInvoiceShared(invoice.id, 'WhatsApp');
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  } else {
                    session.showError(
                      'WhatsApp could not open. Send this invoice through MoolSocial Chat.',
                    );
                  }
                },
                icon: const Icon(Icons.send_outlined),
                label: const Text('Send on WhatsApp'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DeliveryActivityCard extends StatelessWidget {
  const _DeliveryActivityCard({required this.session});
  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final assignment = session.workspaceDeliveryAssignment;
    final canConfirmOwnDelivery =
        session.workspaceOrderFulfilment == 'Own delivery' &&
        const [
          'Picked up',
          'Collected',
          'Out for delivery',
        ].contains(assignment?.stage);
    return Column(
      key: const Key('work-activity-delivery'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Customer delivery',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  assignment?.partnerName ?? 'Awaiting a delivery partner',
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (assignment != null) ...[
                  Text(
                    '${assignment.vehicleLabel} · ${assignment.stage}',
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DeliveryProgressTrack(stage: assignment.stage),
                  const SizedBox(height: 8),
                  _LiveCountdownText(
                    deadline: assignment.eta,
                    fallback: 'Arrival estimate unavailable',
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontSize: 12,
                    ),
                  ),
                ],
                const Divider(height: 22),
                Text(
                  session.workspaceOrderCustomer,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  session.workspaceOrderAddress.isEmpty
                      ? 'Customer address unavailable'
                      : session.workspaceOrderAddress,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (session.workspaceOperationsSyncError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    session.workspaceOperationsSyncError!,
                    style: const TextStyle(color: MoolColors.ink, fontSize: 12),
                  ),
                  TextButton(
                    key: const Key('work-delivery-retry'),
                    onPressed: session.workspaceOperationsSyncing
                        ? null
                        : session.retryWorkspaceDeliveryAssignment,
                    child: const Text('Try again'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      key: const Key('work-delivery-call-customer'),
                      onPressed: () {
                        final digits = session.workspaceOrderCustomer
                            .replaceAll(RegExp(r'[^0-9]'), '');
                        if (digits.length >= 10) {
                          unawaited(
                            launchUrl(Uri(scheme: 'tel', path: digits)),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: const Text('Call'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      key: const Key('work-delivery-chat-customer'),
                      onPressed: () => context.push(
                        Uri(
                          path: '/app/chat/inbox',
                          queryParameters: {
                            'return': GoRouterState.of(context).uri.toString(),
                            'recipient': session.workspaceOrderCustomer,
                            'draft':
                                'Delivery support for ${session.workspaceOrderCustomer}',
                          },
                        ).toString(),
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('Chat'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      key: const Key('work-delivery-open-map'),
                      onPressed: session.workspaceOrderAddress.isEmpty
                          ? null
                          : () => unawaited(
                              launchUrl(
                                Uri.https('www.google.com', '/maps/search/', {
                                  'api': '1',
                                  'query': session.workspaceOrderAddress,
                                }),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Map'),
                    ),
                  ),
                ],
              ),
              if (canConfirmOwnDelivery)
                FilledButton.icon(
                  key: const Key('work-activity-confirm-handover'),
                  onPressed: session.workspaceHandoverBusy
                      ? null
                      : () => _showWorkspaceHandoverSheet(context, session),
                  icon: const Icon(Icons.password_rounded, size: 18),
                  label: const Text('Confirm customer delivery'),
                )
              else
                const Text(
                  'Waiting for the delivery partner’s pickup or delivery confirmation.',
                  key: Key('work-delivery-proof-pending'),
                  style: TextStyle(
                    color: MoolColors.muted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveryProgressTrack extends StatelessWidget {
  const _DeliveryProgressTrack({required this.stage});

  final String? stage;

  @override
  Widget build(BuildContext context) {
    const steps = ['Assigned', 'At store', 'Picked up', 'Delivered'];
    final currentIndex = stage == null
        ? -1
        : steps.indexWhere(
            (step) =>
                step.toLowerCase() == stage!.trim().toLowerCase() ||
                (step == 'Picked up' &&
                    stage!.trim().toLowerCase() == 'collected'),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++)
            Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: index <= currentIndex
                          ? const Color(0xFF08765D)
                          : const Color(0xFFDCE2F2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      index < currentIndex
                          ? Icons.check_rounded
                          : index == currentIndex
                          ? Icons.circle
                          : Icons.circle_outlined,
                      color: index <= currentIndex
                          ? Colors.white
                          : MoolColors.muted,
                      size: index == currentIndex ? 10 : 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      steps[index],
                      maxLines: 1,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _showWorkspaceHandoverSheet(
  BuildContext context,
  WorkSession session,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _WorkspaceHandoverSheet(session: session),
  );
}

class _WorkspaceHandoverSheet extends StatefulWidget {
  const _WorkspaceHandoverSheet({required this.session});

  final WorkSession session;

  @override
  State<_WorkspaceHandoverSheet> createState() =>
      _WorkspaceHandoverSheetState();
}

class _WorkspaceHandoverSheetState extends State<_WorkspaceHandoverSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Confirm customer handover',
            style: TextStyle(
              color: MoolColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Enter the 6-digit OTP shared by the customer after receiving the order.',
            style: TextStyle(color: MoolColors.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('work-handover-otp'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Customer delivery OTP',
              errorText: _error,
              prefixIcon: const Icon(Icons.password_rounded),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const Key('work-handover-confirm'),
            onPressed: widget.session.workspaceHandoverBusy
                ? null
                : () async {
                    final success = await widget.session
                        .verifyWorkspaceHandover(_controller.text);
                    if (success && mounted) {
                      Navigator.of(this.context).pop();
                    } else if (mounted) {
                      setState(() => _error = widget.session.errorMessage);
                    }
                  },
            icon: const Icon(Icons.verified_rounded),
            label: const Text('Verify and complete order'),
          ),
        ],
      ),
    );
  }
}

class _StockActivityCard extends StatelessWidget {
  const _StockActivityCard({required this.session, required this.onOpen});
  final WorkSession session;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final product = session.workspaceCatalogueItems
        .where((item) => item.stock <= 5)
        .firstOrNull;
    return Column(
      key: const Key('work-activity-stock'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Check stock',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  product?.title ?? 'Your product catalogue',
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (product != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${product.stock} available · ${product.pack}',
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontSize: 13,
                    ),
                  ),
                ],
                const Divider(height: 22),
                const Text(
                  'Check quantities and replenish what your customers need.',
                  style: TextStyle(
                    color: MoolColors.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(10),
          child: FilledButton(
            onPressed: onOpen,
            child: const Text('Open catalogue'),
          ),
        ),
      ],
    );
  }
}

class _MoneyActivityCard extends StatelessWidget {
  const _MoneyActivityCard({required this.session, required this.onOpen});
  final WorkSession session;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('work-activity-money'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales balance',
                style: TextStyle(
                  color: MoolColors.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '₹${_formatStoreAmount(session.workspaceSettlementBalance)}',
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Today’s sales · ₹${_formatStoreAmount(session.workspaceSalesToday)}',
                style: const TextStyle(color: MoolColors.muted, fontSize: 12),
              ),
              const Divider(height: 22),
              const Text(
                'Review payments and deductions before requesting settlement.',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.all(10),
        child: FilledButton(
          onPressed: onOpen,
          child: const Text('Review settlement'),
        ),
      ),
    ],
  );
}

class _GroupBulkActivityCard extends StatelessWidget {
  const _GroupBulkActivityCard({required this.groupBuy, required this.onOpen});

  final WorkspaceGroupBuy groupBuy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final progress = groupBuy.targetQuantity == 0
        ? 0.0
        : groupBuy.securedQuantity / groupBuy.targetQuantity;
    return InkWell(
      key: const Key('work-activity-group-bulk'),
      onTap: onOpen,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GROUP BULK · ${groupBuy.closingLabel.toUpperCase()}',
              style: const TextStyle(
                color: Color(0xFF9A4A00),
                fontSize: 10.5,
                letterSpacing: .6,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              groupBuy.productName,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              groupBuy.specification,
              style: const TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 118,
                height: 118,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 12,
                      backgroundColor: const Color(0xFFE7EBF8),
                      color: MoolColors.orange,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${groupBuy.securedQuantity}',
                          style: const TextStyle(
                            color: MoolColors.navy,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'of ${groupBuy.targetQuantity} ${groupBuy.unitLabel}',
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DeckPrice(
                    label: 'Group price',
                    value: '₹${groupBuy.groupUnitPrice}/${groupBuy.unitLabel}',
                  ),
                ),
                Expanded(
                  child: _DeckPrice(
                    label: 'You save',
                    value: '₹${groupBuy.savingPerUnit}/${groupBuy.unitLabel}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpen,
                child: const Text('Review Group Bulk Buying'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckPrice extends StatelessWidget {
  const _DeckPrice({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: MoolColors.muted, fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: MoolColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StoreReadyActivity extends StatelessWidget {
  const _StoreReadyActivity();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('work-activity-ready'),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            children: [
              _LiveDot(color: MoolColors.navy),
              SizedBox(width: 8),
              Text(
                'STORE READY',
                style: TextStyle(
                  color: MoolColors.navy,
                  fontSize: 11,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFF0F3FF),
                child: Icon(Icons.storefront_rounded, color: MoolColors.navy),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your store is ready',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'New orders and urgent tasks will appear here.',
                      style: TextStyle(
                        color: MoolColors.muted,
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreSetupDeck extends StatelessWidget {
  const _StoreSetupDeck({
    required this.session,
    required this.workspace,
    required this.onSetup,
  });

  final WorkSession session;
  final WorkWorkspace workspace;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final productsReady = session.workspaceCatalogueItems.isNotEmpty;
    final fulfilmentReady =
        session.retailerHomeDelivery || session.retailerStoreCollection;
    final progress =
        ([productsReady, fulfilmentReady].where((value) => value).length) / 2;
    return Padding(
      key: const Key('work-activity-setup'),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            width: 108,
            height: 108,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  color: MoolColors.orange,
                  backgroundColor: const Color(0xFFDCE2F2),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'ready',
                      style: TextStyle(color: MoolColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Prepare ${workspace.name} for its first order',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 19,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Confirm products, Selling Price, MRP and fulfilment. Your store remains private until you publish it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: MoolColors.muted, height: 1.35),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('work-dashboard-priority-action'),
              onPressed: onSetup,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue store setup'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .35), blurRadius: 8),
        ],
      ),
    );
  }
}

class _LiveCountdownText extends StatefulWidget {
  const _LiveCountdownText({
    required this.deadline,
    required this.fallback,
    required this.style,
  });

  final DateTime? deadline;
  final String fallback;
  final TextStyle style;

  @override
  State<_LiveCountdownText> createState() => _LiveCountdownTextState();
}

class _LiveCountdownTextState extends State<_LiveCountdownText>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restartTicker();
  }

  @override
  void didUpdateWidget(covariant _LiveCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) _restartTicker();
  }

  void _restartTicker() {
    _timer?.cancel();
    final deadline = widget.deadline;
    if (deadline == null || !deadline.isAfter(DateTime.now())) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {});
      if (!deadline.isAfter(DateTime.now())) timer.cancel();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restartTicker();
      setState(() {});
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.deadline;
    var label = widget.fallback;
    if (deadline != null) {
      final remaining = deadline.difference(DateTime.now());
      final seconds = (remaining.inMilliseconds / 1000).ceil().clamp(
        0,
        1 << 31,
      );
      label = seconds == 0
          ? 'Time ended'
          : '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    }
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
  }
}

Future<void> _showRejectOrderSheet(
  BuildContext context,
  WorkSession session,
) async {
  String? selectedReason;
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        key: const Key('work-reject-order-dialog'),
        backgroundColor: const Color(0xFFFFFDFD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE9E7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Color(0xFFB42318), size: 24),
              SizedBox(width: 10),
              Text('Reject order'),
            ],
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose the reason shared with the customer.',
                style: TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: 6),
              for (final option in const [
                'Product unavailable',
                'Cannot meet requested time',
                'Delivery unavailable',
                'Customer requested cancellation',
              ])
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Material(
                    color: selectedReason == option
                        ? const Color(0xFFFFE9E7)
                        : const Color(0xFFF7F7FA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: selectedReason == option
                            ? const Color(0xFFE4574F)
                            : const Color(0xFFE7E7EE),
                      ),
                    ),
                    child: RadioListTile<String>(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      activeColor: const Color(0xFFB42318),
                      value: option,
                      // ignore: deprecated_member_use
                      groupValue: selectedReason,
                      title: Text(option),
                      // ignore: deprecated_member_use
                      onChanged: (value) =>
                          setDialogState(() => selectedReason = value),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const FittedBox(child: Text('Keep order')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB42318),
                        disabledBackgroundColor: const Color(0xFFE7E7EE),
                      ),
                      onPressed: selectedReason == null
                          ? null
                          : () =>
                                Navigator.of(dialogContext).pop(selectedReason),
                      child: const FittedBox(child: Text('Reject order')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  session.cancelWorkspaceOrder();
}

class _DashboardSyncBanner extends StatelessWidget {
  const _DashboardSyncBanner({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final lastUpdated = session.workspaceLastUpdatedAt;
    final time = lastUpdated == null
        ? null
        : '${lastUpdated.hour.toString().padLeft(2, '0')}:${lastUpdated.minute.toString().padLeft(2, '0')}';
    final (
      icon,
      color,
      title,
      detail,
    ) = switch (session.workspaceDashboardState) {
      WorkspaceDashboardState.refreshing => (
        Icons.sync_rounded,
        MoolColors.navy,
        'Refreshing store activity',
        'Saved records remain available while the latest activity arrives.',
      ),
      WorkspaceDashboardState.offline => (
        Icons.cloud_off_outlined,
        const Color(0xFF9A4A00),
        'Showing saved store activity',
        time == null
            ? 'Reconnect to receive new orders and payment updates.'
            : 'Last updated $time. Reconnect to receive new activity.',
      ),
      WorkspaceDashboardState.failed => (
        Icons.error_outline_rounded,
        const Color(0xFFB42318),
        'Store activity could not be refreshed',
        session.workspaceDashboardError.isEmpty
            ? 'Your saved records are unchanged. Try again shortly.'
            : session.workspaceDashboardError,
      ),
      WorkspaceDashboardState.ready => (
        Icons.check_circle_outline_rounded,
        const Color(0xFF08765D),
        'Store activity is up to date',
        time == null ? 'Ready for today.' : 'Updated $time.',
      ),
    };
    return Container(
      key: const Key('work-dashboard-sync-state'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (session.workspaceDashboardState ==
              WorkspaceDashboardState.refreshing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else if (session.workspaceDashboardState ==
                  WorkspaceDashboardState.offline ||
              session.workspaceDashboardState == WorkspaceDashboardState.failed)
            IconButton(
              key: const Key('work-dashboard-retry'),
              tooltip: 'Refresh store activity',
              onPressed: session.retryWorkspaceDashboard,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _StoreSetupPanel extends StatelessWidget {
  const _StoreSetupPanel({
    required this.session,
    required this.workspace,
    required this.onPressed,
  });

  final WorkSession session;
  final WorkWorkspace workspace;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final productsReady =
        session.retailerProductAdded ||
        session.workspaceCatalogueItems.isNotEmpty;
    final fulfilmentReady =
        session.retailerHomeDelivery || session.retailerStoreCollection;
    final completed = [
      productsReady,
      fulfilmentReady,
    ].where((value) => value).length;
    return Container(
      key: const Key('work-dashboard-setup-panel'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE2F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F001B4D),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: MoolColors.navy,
                size: 24,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prepare your store for its first order',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontSize: 16,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${workspace.name} stays private until you choose to publish it.',
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$completed/2',
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SetupMilestone(
            complete: productsReady,
            label: 'Products and selling prices',
          ),
          const SizedBox(height: 6),
          _SetupMilestone(
            complete: fulfilmentReady,
            label: 'Pickup and delivery choices',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('work-dashboard-priority-action'),
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue store setup'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupMilestone extends StatelessWidget {
  const _SetupMilestone({required this.complete, required this.label});

  final bool complete;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          complete ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: complete ? const Color(0xFF08765D) : MoolColors.muted,
          size: 18,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: complete ? MoolColors.ink : MoolColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _StoreSetupBenefits extends StatelessWidget {
  const _StoreSetupBenefits();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-dashboard-setup-benefits'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready after setup',
            style: TextStyle(
              color: MoolColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          _SetupBenefitRow(
            icon: Icons.receipt_long_outlined,
            text: 'Accept app, phone and counter orders in one place',
          ),
          _SetupBenefitRow(
            icon: Icons.delivery_dining_outlined,
            text: 'Offer pickup or delivery without permanent delivery staff',
          ),
          _SetupBenefitRow(
            icon: Icons.store_mall_directory_outlined,
            text: 'Show available products and prices to nearby customers',
          ),
          _SetupBenefitRow(
            icon: Icons.inventory_2_outlined,
            text: 'Restock through Wholesale and Group Bulk Buying',
          ),
        ],
      ),
    );
  }
}

class _SetupBenefitRow extends StatelessWidget {
  const _SetupBenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: MoolColors.navy, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _StoreMetricBand extends StatelessWidget {
  const _StoreMetricBand({
    required this.session,
    required this.onOrders,
    required this.onMoney,
    required this.onStock,
  });

  final WorkSession session;
  final VoidCallback onOrders;
  final VoidCallback onMoney;
  final VoidCallback onStock;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('work-dashboard-live-metrics'),
      children: [
        _StoreMetricTile(
          label: 'Orders',
          value: session.hasActiveWorkspaceOrder ? '1' : '0',
          onTap: onOrders,
        ),
        _StoreMetricTile(
          label: 'Sales today',
          value: '₹${session.workspaceSalesToday}',
          onTap: onMoney,
        ),
        _StoreMetricTile(
          label: 'Available',
          value: '₹${session.workspaceSettlementBalance}',
          onTap: onMoney,
        ),
        _StoreMetricTile(
          label: 'Low stock',
          value: '${session.workspaceLowStockCount}',
          onTap: onStock,
        ),
      ],
    );
  }
}

class _StoreMetricTile extends StatelessWidget {
  const _StoreMetricTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  value,
                  key: ValueKey(value),
                  maxLines: 1,
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StoreDayReadyState extends StatelessWidget {
  const _StoreDayReadyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-dashboard-ready-state'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE8F7F1),
            foregroundColor: Color(0xFF08765D),
            child: Icon(Icons.check_rounded),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your store is ready for today',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'New paid orders and stock alerts will appear here.',
                  style: TextStyle(
                    color: MoolColors.muted,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAlertButton extends StatelessWidget {
  const _DashboardAlertButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: count == 0 ? 'Store alerts' : 'Store alerts, $count need review',
      onTap: onPressed,
      excludeSemantics: true,
      child: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: IconButton.outlined(
          key: const Key('work-dashboard-alerts'),
          tooltip: 'Store alerts',
          onPressed: onPressed,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ),
    );
  }
}

class _StoreContextRail extends StatelessWidget {
  const _StoreContextRail({
    this.selected = 'today',
    required this.onToday,
    required this.onCustomers,
    required this.onMoney,
    required this.onGrow,
    this.onStorefront,
  });

  final String selected;
  final VoidCallback? onToday;
  final VoidCallback? onCustomers;
  final VoidCallback? onMoney;
  final VoidCallback? onGrow;
  final VoidCallback? onStorefront;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-store-context-rail'),
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE2F2))),
      ),
      child: Row(
        children: [
          _StoreContextButton(
            label: 'Today',
            selected: selected == 'today',
            onPressed: selected == 'today' ? null : onToday,
          ),
          _StoreContextButton(
            label: 'Customers',
            selected: selected == 'customers',
            onPressed: selected == 'customers' ? null : onCustomers,
          ),
          _StoreContextButton(
            label: 'Money',
            selected: selected == 'money',
            onPressed: selected == 'money' ? null : onMoney,
          ),
          _StoreContextButton(
            label: 'Grow',
            selected: selected == 'grow',
            onPressed: selected == 'grow' ? null : onGrow,
          ),
          if (selected == 'storefront' || onStorefront != null)
            _StoreContextButton(
              label: 'Storefront',
              selected: selected == 'storefront',
              onPressed: selected == 'storefront' ? null : onStorefront,
            ),
        ],
      ),
    );
  }
}

class _StoreContextButton extends StatelessWidget {
  const _StoreContextButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: selected ? MoolColors.navy : MoolColors.muted,
          shape: const RoundedRectangleBorder(),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomCenter,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: selected ? 28 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: MoolColors.orange,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StoreSignalStrip extends StatelessWidget {
  const _StoreSignalStrip({
    required this.session,
    required this.ready,
    required this.onStateSelected,
    required this.onVisibilityChanged,
    required this.onStatus,
    required this.onPreview,
  });

  final WorkSession session;
  final bool ready;
  final ValueChanged<_QuickStoreState> onStateSelected;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onStatus;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final state = !ready
        ? 'Setup needed'
        : switch (session.workspaceStoreState) {
            WorkspaceStoreState.open => 'Open',
            WorkspaceStoreState.paused => 'Paused',
            WorkspaceStoreState.off => 'Off',
          };
    final stateColor = switch (state) {
      'Open' => const Color(0xFF08765D),
      'Paused' => const Color(0xFF9A4A00),
      'Off' => const Color(0xFFB42318),
      _ => MoolColors.orange,
    };
    return Container(
      key: const Key('work-dashboard-command-centre'),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FD),
        border: Border(bottom: BorderSide(color: Color(0xFFDCE2F2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ready
                ? PopupMenuButton<_QuickStoreState>(
                    key: const Key('work-dashboard-store-state'),
                    tooltip: 'Change store availability',
                    onSelected: onStateSelected,
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _QuickStoreState.open,
                        child: Text('Open for orders'),
                      ),
                      PopupMenuItem(
                        value: _QuickStoreState.paused,
                        child: Text('Pause for 1 hour'),
                      ),
                      PopupMenuItem(
                        value: _QuickStoreState.off,
                        child: Text('Turn ordering off'),
                      ),
                    ],
                    child: _StoreStatusPill(
                      icon: Icons.circle,
                      iconColor: stateColor,
                      label: state,
                    ),
                  )
                : const _StoreStatusPill(
                    key: Key('work-dashboard-store-state'),
                    icon: Icons.build_circle_outlined,
                    iconColor: MoolColors.orange,
                    label: 'Setup needed',
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              key: const Key('work-dashboard-visibility'),
              borderRadius: BorderRadius.circular(999),
              onTap: ready
                  ? () => onVisibilityChanged(
                      !session.workspaceVisibleToCustomers,
                    )
                  : null,
              child: _StoreStatusPill(
                icon: session.workspaceVisibleToCustomers
                    ? Icons.public_rounded
                    : Icons.visibility_off_outlined,
                iconColor: session.workspaceVisibleToCustomers
                    ? const Color(0xFF08765D)
                    : MoolColors.muted,
                label: session.workspaceVisibleToCustomers
                    ? 'Public'
                    : 'Private',
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            key: const Key('work-dashboard-public-preview'),
            tooltip: 'Preview customer storefront',
            onPressed: onPreview,
            icon: const Icon(Icons.visibility_outlined, size: 18),
          ),
          IconButton(
            key: const Key('work-dashboard-status'),
            tooltip: 'Opening and fulfilment settings',
            onPressed: onStatus,
            icon: const Icon(Icons.tune_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}

class _StoreStatusPill extends StatelessWidget {
  const _StoreStatusPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE2F2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 13),
          const SizedBox(width: 5),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _StoreQuickActionBar extends StatelessWidget {
  const _StoreQuickActionBar({
    required this.onNewSale,
    required this.onDelivery,
    required this.onBuy,
    required this.onGroupBuy,
  });

  final VoidCallback onNewSale;
  final VoidCallback onDelivery;
  final VoidCallback onBuy;
  final VoidCallback onGroupBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-store-quick-actions'),
      height: 58,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _StoreQuickAction(
            keyName: 'work-quick-new-sale',
            icon: Icons.point_of_sale_outlined,
            label: 'New Sale',
            onPressed: onNewSale,
          ),
          _StoreQuickAction(
            keyName: 'work-quick-delivery',
            icon: Icons.delivery_dining_outlined,
            label: 'Deliver Order',
            onPressed: onDelivery,
          ),
          _StoreQuickAction(
            keyName: 'work-quick-buy',
            icon: Icons.shopping_bag_outlined,
            label: 'Buy Stock',
            onPressed: onBuy,
          ),
          _StoreQuickAction(
            keyName: 'work-quick-group-buy',
            icon: Icons.groups_2_outlined,
            label: 'Group Bulk',
            onPressed: onGroupBuy,
          ),
        ],
      ),
    );
  }
}

class _StoreQuickAction extends StatelessWidget {
  const _StoreQuickAction({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        key: Key(keyName),
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: MoolColors.navy, size: 19),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _GroupBuyTodayRow extends StatelessWidget {
  const _GroupBuyTodayRow({required this.groupBuy, required this.onPressed});

  final WorkspaceGroupBuy groupBuy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _StoreActionRow(
      keyName: 'work-dashboard-active-group-buy',
      urgency: _StoreActionUrgency.attention,
      icon: Icons.groups_2_outlined,
      eyebrow: 'GROUP BULK · ${groupBuy.closingLabel.toUpperCase()}',
      title:
          '${groupBuy.productName} · ₹${groupBuy.groupUnitPrice}/${groupBuy.unitLabel}',
      detail:
          '${groupBuy.confirmedRetailers.length} retailer confirmed · Save ₹${groupBuy.savingPerUnit}/${groupBuy.unitLabel}',
      actionLabel: 'Review',
      onPressed: onPressed,
    );
  }
}

enum _StoreActionUrgency { normal, attention, positive }

class _StoreActionRow extends StatelessWidget {
  const _StoreActionRow({
    required this.keyName,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onPressed,
    this.actionKey,
    this.urgency = _StoreActionUrgency.normal,
  });

  final String keyName;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onPressed;
  final String? actionKey;
  final _StoreActionUrgency urgency;

  @override
  Widget build(BuildContext context) {
    final accent = switch (urgency) {
      _StoreActionUrgency.attention => const Color(0xFF9A4A00),
      _StoreActionUrgency.positive => const Color(0xFF08765D),
      _StoreActionUrgency.normal => MoolColors.navy,
    };
    return Container(
      key: Key('$keyName-row'),
      constraints: const BoxConstraints(minHeight: 78),
      color: urgency == _StoreActionUrgency.attention
          ? const Color(0xFFFFFAF2)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 23),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    letterSpacing: .45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 11,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 82,
            child: KeyedSubtree(
              key: Key(keyName),
              child: TextButton(
                key: actionKey == null ? null : Key(actionKey!),
                onPressed: onPressed,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(actionLabel, maxLines: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _TodayOrderAction extends StatelessWidget {
  const _TodayOrderAction({required this.session, required this.onOrders});

  final WorkSession session;
  final VoidCallback onOrders;

  @override
  Widget build(BuildContext context) {
    if (session.workspaceOrderCustomer.isEmpty) {
      return _StoreActionRow(
        keyName: 'work-dashboard-orders',
        actionKey: 'work-dashboard-create-order',
        icon: Icons.receipt_long_outlined,
        eyebrow: 'ORDERS',
        title: 'No order waiting',
        detail: 'App orders appear here as they arrive.',
        actionLabel: 'New sale',
        onPressed: onOrders,
      );
    }
    final stage = session.workspaceOrderStage;
    final actionLabel = switch (stage) {
      'Confirmed' => 'Prepare',
      'Preparing' => 'Mark ready',
      'Ready' when session.workspaceOrderNeedsDelivery => 'Deliver',
      'Ready' => 'Complete',
      'Delivery requested' => 'Track',
      _ => 'View',
    };
    return _StoreActionRow(
      keyName: 'work-dashboard-orders',
      urgency: _StoreActionUrgency.attention,
      icon: Icons.receipt_long_outlined,
      eyebrow: stage.toUpperCase(),
      title:
          '${session.workspaceOrderSource} order · ₹${session.workspaceOrderAmount}',
      detail: session.workspaceOrderItems,
      actionLabel: actionLabel,
      onPressed: onOrders,
    );
  }
}

// ignore: unused_element
class _StoreRecentActivity extends StatelessWidget {
  const _StoreRecentActivity({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('work-dashboard-live-activity'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT ACTIVITY',
          style: TextStyle(
            color: MoolColors.navy,
            fontSize: 9,
            letterSpacing: .55,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        for (final entry in session.workspaceActivity.take(3))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Color(0xFF08765D), size: 7),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    entry.message,
                    style: const TextStyle(
                      color: MoolColors.ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: MoolColors.muted, fontSize: 8),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WorkspaceSectionLabel extends StatelessWidget {
  const _WorkspaceSectionLabel({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = largeText || constraints.maxWidth < 420;
        final heading = Text(
          title,
          style: const TextStyle(
            color: MoolColors.navy,
            fontSize: 18,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        );
        final supporting = Text(
          detail,
          textAlign: stacked ? TextAlign.start : TextAlign.end,
          maxLines: 2,
          style: const TextStyle(
            color: MoolColors.muted,
            fontSize: 9.5,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 3), supporting],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: heading),
            Flexible(child: supporting),
          ],
        );
      },
    );
  }
}

class _WorkspaceNavigationRow extends StatelessWidget {
  const _WorkspaceNavigationRow({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      keyName: keyName,
      onTap: onTap,
      padding: const EdgeInsets.all(MoolSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEAF2FF),
            foregroundColor: MoolColors.navy,
            child: Icon(icon, size: 21),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: MoolColors.muted),
        ],
      ),
    );
  }
}

class _WorkspaceSearchSurface extends StatelessWidget {
  const _WorkspaceSearchSurface({
    required this.session,
    required this.query,
    required this.onClear,
    required this.onOpenRoute,
  });

  final WorkSession session;
  final String query;
  final VoidCallback onClear;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final results = _workspaceSearchRecords(session, normalized);
    return AnimatedSwitcher(
      key: const Key('work-dashboard-search-screen'),
      duration: const Duration(milliseconds: 220),
      child: results.isEmpty
          ? Center(
              key: const Key('work-dashboard-search-empty'),
              child: Padding(
                padding: const EdgeInsets.all(MoolSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.manage_search_rounded,
                      size: 46,
                      color: MoolColors.muted,
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Text(
                      normalized.isEmpty
                          ? 'Search products, orders, customers or records'
                          : 'No matching store record',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (normalized.isNotEmpty) ...[
                      const SizedBox(height: MoolSpacing.sm),
                      TextButton.icon(
                        key: const Key('work-dashboard-search-clear'),
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Clear search'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : ListView.separated(
              key: const Key('work-dashboard-search-results'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                MoolSpacing.md,
                MoolSpacing.sm,
                MoolSpacing.md,
                MoolSpacing.xl,
              ),
              itemCount: results.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: MoolSpacing.xs),
              itemBuilder: (context, index) {
                final destination = results[index];
                return _WorkspaceNavigationRow(
                  keyName: 'work-search-${destination.id}',
                  icon: destination.icon,
                  title: destination.title,
                  detail: destination.detail,
                  onTap: () => onOpenRoute(destination.route),
                );
              },
            ),
    );
  }
}

class _StoreStatementSurface extends StatefulWidget {
  const _StoreStatementSurface({required this.session});
  final WorkSession session;
  @override
  State<_StoreStatementSurface> createState() => _StoreStatementSurfaceState();
}

class _StoreStatementSurfaceState extends State<_StoreStatementSurface> {
  String _book = 'Sales';

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final orders = session.filteredWorkspaceMoneyOrders;
    return Column(
      key: const Key('work-store-statement'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Store statement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: MoolColors.navy,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                key: const Key('work-statement-period'),
                tooltip: 'Statement period',
                onSelected: session.setWorkspaceMoneyPeriod,
                itemBuilder: (_) => [
                  for (final period in [
                    'Today',
                    'Week',
                    'Month',
                    'Financial year',
                  ])
                    PopupMenuItem(value: period, child: Text(period)),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    session.workspaceMoneyPeriod,
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_book == 'Sales') ...[
                const Text(
                  'Customer purchases',
                  style: TextStyle(fontSize: 12, color: MoolColors.muted),
                ),
                const SizedBox(height: 16),
                if (orders.isEmpty)
                  const _DeskEmpty(
                    icon: Icons.receipt_long_outlined,
                    title: 'No sales in this period',
                    detail: 'Recorded customer purchases will appear here.',
                  ),
                for (final order in orders) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F3FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${order.createdAt.day}\n${order.createdAt.month}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: MoolColors.navy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customer,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.id} · ${order.payment}\n${order.stage}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: MoolColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${_formatStoreAmount(order.amount)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: MoolColors.navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ] else
                _DeskEmpty(
                  icon: _book == 'Purchases'
                      ? Icons.local_shipping_outlined
                      : Icons.receipt_outlined,
                  title: _book == 'Purchases'
                      ? 'No purchases linked to this store'
                      : 'No recorded expenses',
                  detail: _book == 'Purchases'
                      ? 'Supplier invoices and incoming deliveries will appear when linked to this business. Personal purchases stay separate.'
                      : 'Business expenses will appear here when recorded.',
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final book in ['Sales', 'Purchases', 'Expenses'])
                  Expanded(
                    child: TextButton(
                      key: Key('work-statement-${book.toLowerCase()}'),
                      onPressed: _book == book
                          ? null
                          : () => setState(() => _book = book),
                      style: TextButton.styleFrom(
                        backgroundColor: _book == book
                            ? const Color(0xFFECEFFF)
                            : null,
                        disabledForegroundColor: MoolColors.navy,
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(book, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeskEmpty extends StatelessWidget {
  const _DeskEmpty({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title, detail;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 32, color: MoolColors.navy),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            color: MoolColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: MoolColors.muted,
          ),
        ),
      ],
    ),
  );
}

class _StoreDuesSurface extends StatelessWidget {
  const _StoreDuesSurface({required this.session, required this.onOpenRoute});
  final WorkSession session;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final customers = session.workspaceCustomerBook
        .where((customer) => customer.amountDue > 0)
        .toList();
    return ListView(
      key: const Key('work-store-dues'),
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Collect dues',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Unpaid customer balances',
          style: TextStyle(fontSize: 12, color: MoolColors.muted),
        ),
        const SizedBox(height: 16),
        if (customers.isEmpty)
          const _DeskEmpty(
            icon: Icons.task_alt_rounded,
            title: 'No customer dues recorded',
            detail:
                'Unpaid invoices will appear here. Paid purchases remain in your statement.',
          ),
        for (final customer in customers) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      customer.mobile,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MoolColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${_formatStoreAmount(customer.amountDue)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MoolColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final order in customer.orders.where(
            (order) => order.payment.toLowerCase().contains('due'),
          ))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _ProductPreviewLine(
                label: order.id,
                value: '₹${order.amount} · ${order.payment}',
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onOpenRoute(
                Uri(
                  path: '/app/chat/inbox',
                  queryParameters: {
                    'type': 'business',
                    'recipient': customer.mobile,
                    'draft':
                        'Hello ${customer.name}, your recorded balance with ${session.activeWorkspace?.name ?? session.workName} is ₹${customer.amountDue}. Please contact us if anything needs correcting.',
                  },
                ).toString(),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Discuss balance'),
            ),
          ),
          const Divider(height: 24),
        ],
      ],
    );
  }
}

class _StoreLinkSurface extends StatelessWidget {
  const _StoreLinkSurface({required this.session});
  final WorkSession session;
  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('work-store-link'),
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Send store link',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 24),
      const Icon(Icons.storefront_outlined, size: 44, color: MoolColors.navy),
      const SizedBox(height: 14),
      Text(
        session.activeWorkspace?.name ?? session.workName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: MoolColors.navy,
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'A call becomes an online order.',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text(
        'Send your store to a customer. They choose their items, add an address and pay in MoolSocial. You receive the order here.',
        style: TextStyle(fontSize: 13, height: 1.5, color: MoolColors.muted),
      ),
      const SizedBox(height: 24),
      const _DeskEmpty(
        icon: Icons.link_off_rounded,
        title: 'Your store link is not available yet',
        detail:
            'Sharing becomes available when your published storefront has its own customer link.',
      ),
    ],
  );
}

class _StoreDirectSurface extends StatelessWidget {
  const _StoreDirectSurface({required this.session, required this.onOpenRoute});
  final BuyV2Session session;
  final ValueChanged<String> onOpenRoute;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) {
      final products = session.visibleProducts
          .where(
            (product) =>
                product.destination == BuyV2Destination.wholesale &&
                product.manufacturerVerified &&
                product.sellerType.toLowerCase().contains('manufacturer'),
          )
          .toList();
      return ListView(
        key: const Key('work-store-buy-direct'),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Buy Direct',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manufacturer prices. Delivered to your store.',
            style: TextStyle(fontSize: 14, height: 1.4, color: MoolColors.navy),
          ),
          const SizedBox(height: 18),
          if (products.isEmpty)
            const _DeskEmpty(
              icon: Icons.factory_outlined,
              title: 'No manufacturer offers to show',
              detail:
                  'Direct offers will appear here when available for your store. Wholesale suppliers remain available under Restock.',
            ),
          for (final product in products) ...[
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                key: Key('work-direct-${product.id}'),
                borderRadius: BorderRadius.circular(16),
                onTap: () => onOpenRoute(
                  Uri(
                    path: '/app/buy',
                    queryParameters: {
                      'sub': 'wholesale',
                      'view': 'product',
                      'product': product.id,
                    },
                  ).toString(),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.seller,
                        style: const TextStyle(
                          fontSize: 11,
                          color: MoolColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${product.pack} · Minimum ${product.minimumOrder}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '₹${_formatStoreAmount(product.price)}',
                        style: const TextStyle(
                          fontSize: 22,
                          color: MoolColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        product.deliveryPromise,
                        style: const TextStyle(
                          fontSize: 12,
                          color: MoolColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'View offer',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: MoolColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    },
  );
}

class _WorkspaceOperationSurface extends StatelessWidget {
  const _WorkspaceOperationSurface({
    required this.operation,
    required this.session,
    required this.procurementSession,
    required this.catalogueKey,
    required this.counterKey,
    required this.saleQuery,
    required this.requirementDraft,
    required this.onOpenStore,
    required this.onOpenOperation,
    required this.onOpenRoute,
  });

  final _WorkspaceOperation operation;
  final WorkSession session;
  final BuyV2Session procurementSession;
  final GlobalKey<_WorkspaceCatalogueSurfaceState> catalogueKey;
  final GlobalKey<_CounterOrderSurfaceState> counterKey;
  final String saleQuery;
  final Map<String, String> requirementDraft;
  final VoidCallback onOpenStore;
  final ValueChanged<_WorkspaceOperation> onOpenOperation;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    if (operation == _WorkspaceOperation.statement) {
      return _StoreStatementSurface(session: session);
    }
    if (operation == _WorkspaceOperation.settings) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Store tools',
            style: TextStyle(
              fontSize: 20,
              color: MoolColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final action in <(String, String, IconData, VoidCallback)>[
            (
              'settings',
              'Store settings',
              Icons.tune_rounded,
              () => onOpenRoute('/app/work/workspace/dashboard'),
            ),
            (
              'customers',
              'Customer records',
              Icons.people_outline_rounded,
              () => onOpenOperation(_WorkspaceOperation.customers),
            ),
            (
              'money',
              'Settlement records',
              Icons.account_balance_outlined,
              () => onOpenOperation(_WorkspaceOperation.payments),
            ),
            (
              'grow',
              'Promote store and post requirements',
              Icons.campaign_outlined,
              () => onOpenOperation(_WorkspaceOperation.growth),
            ),
            (
              'preview',
              'View public store',
              Icons.storefront_outlined,
              () => onOpenOperation(_WorkspaceOperation.preview),
            ),
          ])
            ListTile(
              key: Key('work-business-${action.$1}'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(action.$3, color: MoolColors.navy),
              title: Text(action.$2),
              onTap: action.$4,
            ),
          ..._operationContent(),
        ],
      );
    }
    if (operation == _WorkspaceOperation.dues) {
      return _StoreDuesSurface(session: session, onOpenRoute: onOpenRoute);
    }
    if (operation == _WorkspaceOperation.storeLink) {
      return _StoreLinkSurface(session: session);
    }
    if (operation == _WorkspaceOperation.direct) {
      return _StoreDirectSurface(
        session: procurementSession,
        onOpenRoute: onOpenRoute,
      );
    }
    if (operation == _WorkspaceOperation.orders) {
      return _OrdersDestinationSurface(
        session: session,
        onCreateOrder: () => onOpenOperation(_WorkspaceOperation.counterOrder),
        onOpenDelivery: () => onOpenOperation(_WorkspaceOperation.delivery),
      );
    }
    if (operation == _WorkspaceOperation.counterOrder) {
      return _CounterOrderSurface(
        key: counterKey,
        query: saleQuery,
        session: session,
        onArrangeDelivery: () => onOpenOperation(_WorkspaceOperation.orders),
        onOpenCatalogue: () => onOpenOperation(_WorkspaceOperation.catalogue),
      );
    }
    if (operation == _WorkspaceOperation.catalogue) {
      return _WorkspaceCatalogueSurface(
        key: catalogueKey,
        session: session,
        onOpenStockStatement: () =>
            onOpenOperation(_WorkspaceOperation.stockStatement),
      );
    }
    if (operation == _WorkspaceOperation.stockStatement) {
      return _WorkspaceStockStatementSurface(
        session: session,
        onRestock: (product) => onOpenRoute(
          Uri(
            path: '/app/buy',
            queryParameters: {
              'sub': 'wholesale',
              'context': 'wholesale',
              'search': '${product.brand} ${product.title} ${product.pack}',
            },
          ).toString(),
        ),
      );
    }
    if (operation == _WorkspaceOperation.groupBuying) {
      return session.activeGroupBuy == null
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                Text(
                  'Group Bulk Buying',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                _DeskEmpty(
                  icon: Icons.groups_2_outlined,
                  title: 'The next bulk opportunity will appear here',
                  detail:
                      'See the product, participating stores, quantity, complete price and closing date before you commit. No open group purchase is available for this store yet.',
                ),
              ],
            )
          : _WorkspaceGroupBuyingSurface(session: session);
    }
    if (operation == _WorkspaceOperation.preview) {
      return Column(
        children: [
          _StoreContextRail(
            selected: 'storefront',
            onToday: onOpenStore,
            onCustomers: () => onOpenOperation(_WorkspaceOperation.customers),
            onMoney: () => onOpenOperation(_WorkspaceOperation.payments),
            onGrow: () => onOpenOperation(_WorkspaceOperation.growth),
            onStorefront: null,
          ),
          Expanded(child: _CustomerStorePreviewSurface(session: session)),
        ],
      );
    }
    if (operation == _WorkspaceOperation.delivery) {
      return _DeliveryDestinationSurface(
        session: session,
        onCreateOrder: () => onOpenOperation(_WorkspaceOperation.counterOrder),
      );
    }
    if (operation == _WorkspaceOperation.customers) {
      return _CustomersDestinationSurface(
        session: session,
        onRepeatBasket: (customerId) {
          if (session.prepareRepeatWorkspaceOrderFor(customerId: customerId)) {
            onOpenOperation(_WorkspaceOperation.counterOrder);
          }
        },
        onOffer: () => onOpenOperation(_WorkspaceOperation.offers),
      );
    }
    if (operation == _WorkspaceOperation.payments) {
      return _MoneyDestinationSurface(session: session);
    }
    if (operation == _WorkspaceOperation.deliverySettings) {
      return _WorkspaceDeliverySettingsSurface(session: session);
    }
    if (operation == _WorkspaceOperation.staff) {
      return _WorkspaceStaffSettingsSurface(session: session);
    }
    if (operation == _WorkspaceOperation.businessRecord) {
      return _WorkspaceBusinessRecordSurface(
        session: session,
        onPreview: () => onOpenOperation(_WorkspaceOperation.preview),
      );
    }
    if (operation == _WorkspaceOperation.offers) {
      return _WorkspaceOffersSurface(
        session: session,
        onPromote: () => onOpenRoute(
          Uri(
            path: '/app/social/promote',
            queryParameters: {
              'workspaceId': session.activeWorkspace?.id ?? '',
              'workspaceName':
                  session.activeWorkspace?.name ?? session.workName,
            },
          ).toString(),
        ),
      );
    }
    if (operation == _WorkspaceOperation.paidWork) {
      return _WorkspacePaidWorkSurface(
        session: session,
        draft: requirementDraft,
      );
    }
    if (operation == _WorkspaceOperation.growth) {
      return _GrowDestinationSurfaceV2(
        session: session,
        onCustomers: () => onOpenOperation(_WorkspaceOperation.customers),
        onOffers: () => onOpenOperation(_WorkspaceOperation.offers),
        onPromote: () => onOpenRoute(
          Uri(
            path: '/app/social/promote',
            queryParameters: {
              'workspaceId': session.activeWorkspace?.id ?? '',
              'workspaceName':
                  session.activeWorkspace?.name ?? session.workName,
            },
          ).toString(),
        ),
        onPaidWork: () => onOpenOperation(_WorkspaceOperation.paidWork),
        onServices: () => onOpenOperation(_WorkspaceOperation.services),
      );
    }
    final selectedStoreContext = switch (operation) {
      _WorkspaceOperation.customers => 'customers',
      _WorkspaceOperation.payments || _WorkspaceOperation.books => 'money',
      _WorkspaceOperation.growth || _WorkspaceOperation.services => 'grow',
      _WorkspaceOperation.offers || _WorkspaceOperation.paidWork => 'grow',
      _WorkspaceOperation.sourcing || _WorkspaceOperation.preview => 'none',
      _ => 'today',
    };
    final content = ListView(
      key: Key('work-dashboard-${operation.name}-screen'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, MoolSpacing.xl),
      children: [..._operationContent()],
    );
    return Column(
      children: [
        _StoreContextRail(
          selected: selectedStoreContext,
          onToday: onOpenStore,
          onCustomers: () => onOpenRoute('/app/retailer/customers'),
          onMoney: () => onOpenRoute('/app/retailer/books/money'),
          onGrow: () => onOpenOperation(_WorkspaceOperation.growth),
        ),
        Expanded(child: content),
      ],
    );
  }

  List<Widget> _operationContent() => switch (operation) {
    _WorkspaceOperation.statement ||
    _WorkspaceOperation.dues ||
    _WorkspaceOperation.storeLink ||
    _WorkspaceOperation.direct => const [],
    _WorkspaceOperation.orders => const [],
    _WorkspaceOperation.catalogue => const [],
    _WorkspaceOperation.stockStatement => const [],
    _WorkspaceOperation.delivery => const [],
    _WorkspaceOperation.customers => const [
      _OperationActionCard(
        icon: Icons.people_alt_outlined,
        title: 'Customer purchase records',
        detail:
            'Customer name, purchase date, order value and payment state will appear after a recorded sale.',
      ),
      SizedBox(height: MoolSpacing.xs),
      _OperationActionCard(
        icon: Icons.repeat_rounded,
        title: 'Bring customers back',
        detail:
            'Repeat-order and permitted offer actions will use real customer purchase history.',
      ),
    ],
    _WorkspaceOperation.payments => [
      _OperationMetricBoard(session: session),
      const SizedBox(height: MoolSpacing.xs),
      _OperationActionCard(
        icon: Icons.account_balance_outlined,
        title: 'Request settlement',
        detail: session.workspaceSettlementBalance > 0
            ? '₹${session.workspaceSettlementBalance} from completed sales is available.'
            : 'Settlement becomes available when completed sales create a payable balance.',
        actionLabel: session.workspaceSettlementBalance > 0
            ? 'Request ₹${session.workspaceSettlementBalance}'
            : null,
        onPressed: session.workspaceSettlementBalance > 0
            ? session.requestWorkspaceSettlement
            : null,
      ),
    ],
    _WorkspaceOperation.books => const [
      _OperationActionCard(
        icon: Icons.point_of_sale_outlined,
        title: 'Sales record',
        detail: 'App, counter and phone-order sales stay together by date.',
      ),
      SizedBox(height: MoolSpacing.xs),
      _OperationActionCard(
        icon: Icons.shopping_bag_outlined,
        title: 'Purchase and stock record',
        detail:
            'Wholesale purchases, received stock and supplier payments stay connected.',
      ),
      SizedBox(height: MoolSpacing.xs),
      _OperationActionCard(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Customer dues',
        detail:
            'Recorded customer balances remain visible without mixing them with paid sales.',
      ),
    ],
    _WorkspaceOperation.sourcing => [
      _OperationActionCard(
        icon: Icons.inventory_2_outlined,
        title: 'Buy stock at wholesale',
        detail:
            'Compare pack size, minimum order, delivery date and payment terms before buying.',
        actionLabel: 'Open Wholesale',
        onPressed: () => onOpenRoute('/app/buy?sub=wholesale'),
      ),
      const SizedBox(height: MoolSpacing.xs),
      const _OperationActionCard(
        icon: Icons.groups_2_outlined,
        title: 'Group Bulk Buying',
        detail:
            'Review exact specifications, closing time, confirmed stores, savings, fees and door delivery.',
      ),
    ],
    _WorkspaceOperation.growth => [
      _StoreActionRow(
        keyName: 'work-growth-customers',
        icon: Icons.repeat_rounded,
        eyebrow: 'CUSTOMERS',
        title: 'Bring customers back',
        detail:
            'Open customer purchase records, repeat baskets and permitted follow-up actions.',
        actionLabel: 'Open',
        onPressed: () => onOpenRoute('/app/retailer/customers'),
      ),
      const Divider(height: 1),
      _StoreActionRow(
        keyName: 'work-growth-offers',
        icon: Icons.local_offer_outlined,
        eyebrow: 'OFFERS',
        title: 'Offers and repeat baskets',
        detail:
            'Create a focused offer for customers who can receive store updates.',
        actionLabel: 'Create',
        onPressed: () => onOpenRoute('/app/retailer/campaigns'),
      ),
      const Divider(height: 1),
      _StoreActionRow(
        keyName: 'work-growth-social',
        icon: Icons.campaign_outlined,
        eyebrow: 'STORE REACH',
        title: 'Promote your store',
        detail:
            'Start a MoolSocial post with your store identity and product context already connected.',
        actionLabel: 'Create',
        onPressed: () => onOpenRoute('/app/social/promote'),
      ),
      const Divider(height: 1),
      _StoreActionRow(
        keyName: 'work-growth-paid-work',
        icon: Icons.work_outline_rounded,
        eyebrow: 'PAID WORK',
        title: 'Post requirement',
        detail:
            'Prepare a funded local requirement for delivery, onboarding, sales or store support.',
        actionLabel: 'Prepare',
        onPressed: () =>
            onOpenRoute('/app/work/earn?intent=publish&publisher=workspace'),
      ),
      const Divider(height: 1),
      _StoreActionRow(
        keyName: 'work-growth-services',
        icon: Icons.business_center_outlined,
        eyebrow: 'BUSINESS SUPPORT',
        title: 'Business support',
        detail:
            'Request GST, tax, bookkeeping or audit assistance without leaving store operations.',
        actionLabel: 'View',
        onPressed: () => onOpenOperation(_WorkspaceOperation.services),
      ),
    ],
    _WorkspaceOperation.services => [
      _OperationActionCard(
        icon: Icons.receipt_long_outlined,
        title: 'GST and tax assistance',
        detail:
            'Keep business records ready and request professional filing assistance when needed.',
        actionLabel: 'Ask for help',
        onPressed: () => onOpenRoute(
          '/app/chat/inbox?type=support&draft=GST%20and%20tax%20assistance',
        ),
      ),
      const SizedBox(height: MoolSpacing.xs),
      _OperationActionCard(
        icon: Icons.menu_book_outlined,
        title: 'Bookkeeping and accounts',
        detail:
            'Organise sales, purchases, stock and settlement records for your accountant.',
        actionLabel: 'Ask for help',
        onPressed: () => onOpenRoute(
          '/app/chat/inbox?type=support&draft=Bookkeeping%20and%20accounts%20assistance',
        ),
      ),
      const SizedBox(height: MoolSpacing.xs),
      _OperationActionCard(
        icon: Icons.verified_user_outlined,
        title: 'Audit support',
        detail:
            'Request document and record assistance without changing your store operations.',
        actionLabel: 'Ask for help',
        onPressed: () => onOpenRoute(
          '/app/chat/inbox?type=support&draft=Business%20audit%20assistance',
        ),
      ),
    ],
    _WorkspaceOperation.settings => [
      _OperationActionCard(
        keyName: 'work-dashboard-manage-record',
        icon: Icons.fact_check_outlined,
        title: 'Store details and documents',
        detail:
            'Review submitted business details, documents and any clarification request.',
        actionLabel: 'Open Workspace record',
        onPressed: () => onOpenRoute('/app/work/workspace/proof'),
      ),
      const SizedBox(height: MoolSpacing.xs),
      _OperationActionCard(
        keyName: 'work-dashboard-add-workspace',
        icon: Icons.add_business_outlined,
        title: 'Add another Workspace',
        detail:
            'Create a separate Workspace for another business, profession or service.',
        actionLabel: 'Choose another Workspace',
        onPressed: () {
          session.startAnotherWork();
          onOpenRoute('/app/work/workspace/choose');
        },
      ),
    ],
    _WorkspaceOperation.counterOrder => const [],
    _WorkspaceOperation.preview => const [],
    _WorkspaceOperation.groupBuying => const [],
    _WorkspaceOperation.deliverySettings => const [],
    _WorkspaceOperation.staff => const [],
    _WorkspaceOperation.businessRecord => const [],
    _WorkspaceOperation.offers => const [],
    _WorkspaceOperation.paidWork => const [],
  };
}

class _OperationActionCard extends StatelessWidget {
  const _OperationActionCard({
    required this.icon,
    required this.title,
    required this.detail,
    this.keyName,
    this.actionLabel,
    this.onPressed,
  });

  final String? keyName;
  final IconData icon;
  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      keyName: keyName,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEAF2FF),
            foregroundColor: MoolColors.navy,
            child: Icon(icon),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
                if (actionLabel != null && onPressed != null) ...[
                  const SizedBox(height: MoolSpacing.xs),
                  FilledButton.tonalIcon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCatalogueSurface extends StatefulWidget {
  const _WorkspaceCatalogueSurface({
    required this.session,
    required this.onOpenStockStatement,
    super.key,
  });

  final WorkSession session;
  final VoidCallback onOpenStockStatement;

  @override
  State<_WorkspaceCatalogueSurface> createState() =>
      _WorkspaceCatalogueSurfaceState();
}

class _WorkspaceCatalogueSurfaceState
    extends State<_WorkspaceCatalogueSurface> {
  bool _lowStockOnly = false;

  WorkspaceCatalogueItem _blankProduct({String barcode = ''}) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return WorkspaceCatalogueItem(
      id: 'custom-$stamp',
      canonicalId: 'custom-$stamp',
      categoryId: 'other',
      brand: '',
      title: '',
      variant: '',
      pack: '',
      sku: 'SKU-$stamp',
      barcode: barcode,
      purchasePrice: 0,
      sellingPrice: 0,
      unitPrice: '',
      stock: 0,
      deliveryPromise: 'Store pickup or local delivery',
      origin: 'India',
      visualLabel: 'Product image pending',
      visualKind: 'catalogue-packshot',
      available: false,
      publicListing: false,
    );
  }

  Future<void> _edit(WorkspaceCatalogueItem product) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _CatalogueProductEditor(session: widget.session, product: product),
    );
    if (mounted) setState(() {});
  }

  Future<void> _scan() async {
    final code = await showBuyV2ProductScanner(context);
    if (!mounted || code == null || code.trim().isEmpty) return;
    final normalized = code.trim().toLowerCase();
    final products = [
      ...widget.session.workspaceCatalogueItems,
      ...workspaceMasterCatalogue,
    ];
    final product = products
        .where(
          (item) =>
              item.barcode.toLowerCase() == normalized ||
              item.sku.toLowerCase() == normalized ||
              item.canonicalId.toLowerCase() == normalized,
        )
        .firstOrNull;
    await _edit(product ?? _blankProduct(barcode: code.trim()));
  }

  Future<void> _changePrice(WorkspaceCatalogueItem product) async {
    final price = TextEditingController(text: '${product.sellingPrice}');
    final mrp = TextEditingController(text: product.mrp?.toString() ?? '');
    String? error;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottom = MediaQuery.viewInsetsOf(context).bottom;
          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.fromLTRB(18, 0, 18, bottom + 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change customer price',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: MoolColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${product.title} · ${product.pack}',
                  style: const TextStyle(color: MoolColors.muted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('work-quick-price'),
                        controller: price,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Selling price',
                          prefixText: '₹ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const Key('work-quick-mrp'),
                        controller: mrp,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'MRP',
                          prefixText: '₹ ',
                        ),
                      ),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('work-quick-price-save'),
                    onPressed: () {
                      final sellingPrice = int.tryParse(price.text.trim());
                      final maximumPrice = int.tryParse(mrp.text.trim());
                      if (sellingPrice == null || sellingPrice <= 0) {
                        setSheetState(
                          () => error = 'Enter the price customers will pay.',
                        );
                        return;
                      }
                      if (maximumPrice != null && maximumPrice < sellingPrice) {
                        setSheetState(
                          () => error = 'MRP cannot be below selling price.',
                        );
                        return;
                      }
                      widget.session.addOrUpdateWorkspaceProduct(
                        product.copyWith(
                          sellingPrice: sellingPrice,
                          mrp: maximumPrice,
                          unitPrice: '₹$sellingPrice/${product.pack}',
                        ),
                      );
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Update customer price'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        price.dispose();
        mrp.dispose();
      }),
    );
    if (mounted) setState(() {});
  }

  Future<void> _updateStock(WorkspaceCatalogueItem product) async {
    final quantity = TextEditingController(text: '${product.stock}');
    var reason = 'Counted in store';
    String? error;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottom = MediaQuery.viewInsetsOf(context).bottom;
          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.fromLTRB(18, 0, 18, bottom + 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update available quantity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: MoolColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${product.title} · ${product.pack}',
                  style: const TextStyle(color: MoolColors.muted),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('work-quick-stock'),
                  controller: quantity,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Quantity available now',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: const Key('work-quick-stock-reason'),
                  initialValue: reason,
                  decoration: const InputDecoration(
                    labelText: 'Why did the quantity change?',
                  ),
                  items:
                      const [
                            'Counted in store',
                            'Goods received',
                            'Customer return',
                            'Damage or expiry',
                            'Correction',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) setSheetState(() => reason = value);
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('work-quick-stock-save'),
                    onPressed: () {
                      final parsed = int.tryParse(quantity.text.trim());
                      if (parsed == null || parsed < 0) {
                        setSheetState(
                          () => error = 'Enter a valid available quantity.',
                        );
                        return;
                      }
                      final kind = switch (reason) {
                        'Goods received' =>
                          WorkspaceStockMovementKind.goodsReceived,
                        'Customer return' =>
                          WorkspaceStockMovementKind.returned,
                        'Damage or expiry' =>
                          WorkspaceStockMovementKind.damageOrExpiry,
                        _ => WorkspaceStockMovementKind.adjustment,
                      };
                      if (widget.session.updateWorkspaceStock(
                        productId: product.id,
                        quantity: parsed,
                        reason: reason,
                        kind: kind,
                      )) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    child: const Text('Save quantity'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 320), quantity.dispose),
    );
    if (mounted) setState(() {});
  }

  void _togglePublic(WorkspaceCatalogueItem product) {
    final makePublic = !product.publicListing;
    if (makePublic && (product.sellingPrice <= 0 || !product.available)) {
      widget.session.showError(
        'Add a customer price and make this product available before publishing.',
      );
      return;
    }
    widget.session.addOrUpdateWorkspaceProduct(
      product.copyWith(publicListing: makePublic),
    );
    setState(() {});
  }

  Future<void> _showCatalogueTools() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'More product tools',
                style: TextStyle(
                  color: MoolColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.library_add_outlined),
              title: const Text('Add from MoolSocial catalogue'),
              subtitle: const Text('Use product details already available'),
              onTap: () => Navigator.pop(context, 'catalogue'),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_rounded),
              title: const Text('Import product file'),
              subtitle: const Text('CSV, JSON or a POS export'),
              onTap: () => Navigator.pop(context, 'import'),
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded),
              title: Text(
                _lowStockOnly ? 'Show all products' : 'Show low stock',
              ),
              onTap: () => Navigator.pop(context, 'low'),
            ),
            ListTile(
              key: const Key('work-catalogue-open-stock-statement'),
              leading: const Icon(Icons.list_alt_rounded),
              title: const Text('Open stock statement'),
              subtitle: const Text('Available, reserved and quantity changes'),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenStockStatement();
              },
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'import':
        await _importCatalogue();
      case 'low':
        setState(() => _lowStockOnly = !_lowStockOnly);
      case 'catalogue':
        await _showMasterCatalogue();
      case null:
        break;
    }
  }

  Future<void> _showMasterCatalogue() async {
    final ownedIds = widget.session.workspaceCatalogueItems
        .map((product) => product.id)
        .toSet();
    final products = workspaceMasterCatalogue
        .where((product) => !ownedIds.contains(product.id))
        .toList(growable: false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Add from MoolSocial catalogue',
                style: TextStyle(
                  color: MoolColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 2, 18, 10),
              child: Text(
                'Choose a product, then confirm your price and availability.',
                style: TextStyle(color: MoolColors.muted),
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? const Center(
                      child: Text('All available products are already added.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _WorkspaceProductRow(
                          product: product,
                          owned: false,
                          onEdit: () {
                            Navigator.pop(sheetContext);
                            _edit(product);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importCatalogue() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'json'],
    );
    if (!mounted || picked == null) return;
    try {
      final content = utf8.decode(await picked.readAsBytes());
      final rows = <Map<String, String>>[];
      if (picked.name.toLowerCase().endsWith('.json')) {
        final decoded = jsonDecode(content);
        if (decoded is! List) throw const FormatException();
        for (final entry in decoded) {
          if (entry is! Map) continue;
          rows.add(
            entry.map(
              (key, value) => MapEntry('$key', value == null ? '' : '$value'),
            ),
          );
        }
      } else {
        final lines = const LineSplitter()
            .convert(content)
            .where((line) => line.trim().isNotEmpty)
            .toList();
        if (lines.length < 2) throw const FormatException();
        final headers = lines.first
            .split(',')
            .map((value) => value.trim())
            .toList();
        for (final line in lines.skip(1)) {
          final values = line.split(',').map((value) => value.trim()).toList();
          rows.add({
            for (var index = 0; index < headers.length; index++)
              headers[index]: index < values.length ? values[index] : '',
          });
        }
      }
      final imported = <WorkspaceCatalogueItem>[];
      var catalogueMatches = 0;
      var privateDrafts = 0;
      var skippedRows = 0;
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        final title = row['title']?.trim() ?? '';
        final brand = row['brand']?.trim() ?? '';
        final pack = row['pack']?.trim() ?? '';
        final selling = int.tryParse(row['sellingPrice'] ?? '');
        final purchase = int.tryParse(row['purchasePrice'] ?? '');
        final stock = int.tryParse(row['stock'] ?? '');
        if (title.isEmpty ||
            brand.isEmpty ||
            pack.isEmpty ||
            selling == null ||
            purchase == null ||
            stock == null) {
          skippedRows++;
          continue;
        }
        final stamp = DateTime.now().microsecondsSinceEpoch + index;
        final barcode = row['barcode']?.trim() ?? '';
        final canonicalId = row['canonicalId']?.trim() ?? '';
        final matched = workspaceMasterCatalogue
            .where(
              (product) =>
                  (barcode.isNotEmpty && product.barcode == barcode) ||
                  (canonicalId.isNotEmpty &&
                      product.canonicalId == canonicalId) ||
                  (product.brand.toLowerCase() == brand.toLowerCase() &&
                      product.title.toLowerCase() == title.toLowerCase() &&
                      product.pack.toLowerCase() == pack.toLowerCase()),
            )
            .firstOrNull;
        final stockMode =
            row['stockMode']?.toLowerCase().contains('availability') == true
            ? WorkspaceStockMode.availabilityOnly
            : WorkspaceStockMode.exactQuantity;
        final publicRequested = row['publicListing']?.toLowerCase() != 'false';
        final available = stockMode == WorkspaceStockMode.availabilityOnly
            ? row['available']?.toLowerCase() != 'false'
            : stock > 0;
        final lowStockThreshold =
            int.tryParse(row['lowStockThreshold'] ?? '') ?? 5;
        if (matched != null) {
          catalogueMatches++;
          imported.add(
            matched.copyWith(
              sku: row['sku']?.trim().isNotEmpty == true
                  ? row['sku']!.trim()
                  : matched.sku,
              purchasePrice: purchase,
              sellingPrice: selling,
              unitPrice: row['unitPrice']?.trim().isNotEmpty == true
                  ? row['unitPrice']!.trim()
                  : '₹$selling/${matched.pack}',
              stock: stock,
              deliveryPromise: row['deliveryPromise']?.trim().isNotEmpty == true
                  ? row['deliveryPromise']!.trim()
                  : matched.deliveryPromise,
              mrp: int.tryParse(row['mrp'] ?? '') ?? matched.mrp,
              minimumOrder: int.tryParse(row['minimumOrder'] ?? '') ?? 1,
              available: available,
              publicListing: publicRequested && selling > 0 && available,
              stockMode: stockMode,
              lowStockThreshold: lowStockThreshold,
            ),
          );
        } else {
          privateDrafts++;
          imported.add(
            WorkspaceCatalogueItem(
              id: row['id']?.trim().isNotEmpty == true
                  ? row['id']!.trim()
                  : 'import-$stamp',
              canonicalId: canonicalId.isNotEmpty
                  ? canonicalId
                  : 'import-$stamp',
              categoryId: row['categoryId']?.trim().isNotEmpty == true
                  ? row['categoryId']!.trim()
                  : 'other',
              brand: brand,
              title: title,
              variant: row['variant']?.trim() ?? '',
              pack: pack,
              sku: row['sku']?.trim().isNotEmpty == true
                  ? row['sku']!.trim()
                  : 'SKU-$stamp',
              barcode: barcode,
              purchasePrice: purchase,
              sellingPrice: selling,
              unitPrice: row['unitPrice']?.trim().isNotEmpty == true
                  ? row['unitPrice']!.trim()
                  : '₹$selling/$pack',
              stock: stock,
              deliveryPromise: row['deliveryPromise']?.trim().isNotEmpty == true
                  ? row['deliveryPromise']!.trim()
                  : 'Store pickup or local delivery',
              origin: row['origin']?.trim().isNotEmpty == true
                  ? row['origin']!.trim()
                  : 'India',
              visualLabel: row['visualLabel']?.trim().isNotEmpty == true
                  ? row['visualLabel']!.trim()
                  : '$brand $title $pack',
              visualKind: 'catalogue-packshot',
              mrp: int.tryParse(row['mrp'] ?? ''),
              minimumOrder: int.tryParse(row['minimumOrder'] ?? '') ?? 1,
              returnPolicy: row['returnPolicy']?.trim(),
              available: available,
              publicListing: false,
              stockMode: stockMode,
              lowStockThreshold: lowStockThreshold,
            ),
          );
        }
      }
      if (imported.isEmpty) throw const FormatException();
      widget.session.importWorkspaceProducts(imported);
      widget.session.showNotice(
        '${imported.length} products added · $catalogueMatches matched · $privateDrafts private for review${skippedRows > 0 ? ' · $skippedRows rows need correction' : ''}.',
      );
      if (mounted) setState(() {});
    } on Object {
      widget.session.showError(
        'Import a CSV or JSON file containing title, brand, pack, purchasePrice, sellingPrice and stock.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final own = widget.session.workspaceCatalogueItems
        .where(
          (product) =>
              !_lowStockOnly ||
              (product.stockMode == WorkspaceStockMode.exactQuantity &&
                  product.stock <= product.lowStockThreshold),
        )
        .toList();
    final available = workspaceMasterCatalogue
        .where((product) => !_lowStockOnly)
        .where(
          (product) => widget.session.workspaceCatalogueItems.every(
            (owned) => owned.id != product.id,
          ),
        )
        .toList();
    return Container(
      key: const Key('work-dashboard-catalogue-screen'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9FAFF), Color(0xFFEEF2FF)],
        ),
      ),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Products',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('work-catalogue-add'),
                  onPressed: () => _edit(_blankProduct()),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                key: const Key('work-catalogue-stock-statement'),
                tooltip: 'Stock statement',
                onPressed: widget.onOpenStockStatement,
                icon: const Icon(Icons.list_alt_rounded),
              ),
              IconButton.filledTonal(
                key: const Key('work-catalogue-more'),
                tooltip: 'More product tools',
                onPressed: _showCatalogueTools,
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Prices, stock and public listings',
            style: TextStyle(color: MoolColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 9),
          _CatalogueSummary(session: widget.session),
          if (_lowStockOnly) ...[
            const SizedBox(height: 8),
            Material(
              color: const Color(0xFFFFF3E4),
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                dense: true,
                leading: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFF9A4A00),
                ),
                title: const Text(
                  'Showing products that need stock',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                trailing: TextButton(
                  onPressed: () => setState(() => _lowStockOnly = false),
                  child: const Text('Show all'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (own.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                _lowStockOnly
                    ? 'No products currently need restocking.'
                    : 'No products are active yet. Scan, import or add your first product.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: MoolColors.muted),
              ),
            )
          else
            for (final product in own) ...[
              _WorkspaceProductRow(
                product: product,
                owned: true,
                onEdit: () => _edit(product),
                onChangePrice: () => _changePrice(product),
                onUpdateStock: () => _updateStock(product),
                onTogglePublic: () => _togglePublic(product),
              ),
              const SizedBox(height: 8),
            ],
          if (!_lowStockOnly && available.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Add from MoolSocial catalogue',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Product details are ready. Confirm only your price and availability.',
              style: TextStyle(color: MoolColors.muted, fontSize: 10),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 126,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: available.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final product = available[index];
                  return _VerifiedProductMatch(
                    product: product,
                    onTap: () => _edit(product),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ignore: unused_element
class _WorkspacePublicSkuCard extends StatelessWidget {
  const _WorkspacePublicSkuCard({
    required this.product,
    required this.storeName,
    required this.onTap,
  });

  final WorkspaceCatalogueItem product;
  final String storeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final publicSku = product.toBuyPublicProduct(storeName: storeName);
    return Material(
      key: Key('work-public-sku-${product.id}'),
      elevation: 12,
      shadowColor: const Color(0x22001B4D),
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAF2FF), Color(0xFFDCE5FF)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      publicSku.brand.substring(0, 1),
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          publicSku.title,
                          maxLines: 2,
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 17,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${publicSku.brand} · ${publicSku.pack}',
                          style: const TextStyle(color: MoolColors.muted),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 8,
                          runSpacing: 3,
                          children: [
                            Text(
                              '₹${publicSku.price}',
                              style: const TextStyle(
                                color: MoolColors.navy,
                                fontSize: 24,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (publicSku.mrp case final mrp?) ...[
                              Text(
                                'MRP ₹$mrp',
                                style: const TextStyle(
                                  color: MoolColors.muted,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          publicSku.unitPrice,
                          style: const TextStyle(
                            color: Color(0xFF08765D),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _SkuFactChip(
                    icon: Icons.inventory_2_outlined,
                    label: '${product.stock} available',
                  ),
                  _SkuFactChip(
                    icon: product.publicListing
                        ? Icons.public_rounded
                        : Icons.visibility_off_outlined,
                    label: product.publicListing ? 'Public' : 'Store only',
                  ),
                  _SkuFactChip(
                    icon: Icons.local_shipping_outlined,
                    label: publicSku.deliveryPromise,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Buy SKU ${publicSku.canonicalId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.tune_rounded,
                    color: MoolColors.navy,
                    size: 19,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkuFactChip extends StatelessWidget {
  const _SkuFactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MoolColors.navy, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedProductMatch extends StatelessWidget {
  const _VerifiedProductMatch({required this.product, required this.onTap});

  final WorkspaceCatalogueItem product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('work-catalogue-master-${product.id}'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: 180,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${product.brand} · ${product.pack}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 5),
                const Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: Color(0xFF08765D),
                      size: 15,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Add this product',
                      style: TextStyle(
                        color: Color(0xFF08765D),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StockContextRail extends StatelessWidget {
  const _StockContextRail({
    required this.lowStockOnly,
    // ignore: unused_element_parameter
    this.groupBuySelected = false,
    required this.onProducts,
    required this.onLowStock,
    required this.onPurchases,
    required this.onGroupBuy,
  });

  final bool lowStockOnly;
  final bool groupBuySelected;
  final VoidCallback onProducts;
  final VoidCallback onLowStock;
  final VoidCallback onPurchases;
  final VoidCallback onGroupBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-stock-context-rail'),
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE2F2))),
      ),
      child: Row(
        children: [
          _StoreContextButton(
            label: 'Products',
            selected: !lowStockOnly && !groupBuySelected,
            onPressed: !lowStockOnly && !groupBuySelected ? null : onProducts,
          ),
          _StoreContextButton(
            label: 'Low stock',
            selected: lowStockOnly && !groupBuySelected,
            onPressed: lowStockOnly && !groupBuySelected ? null : onLowStock,
          ),
          _StoreContextButton(
            label: 'Purchases',
            selected: false,
            onPressed: onPurchases,
          ),
          _StoreContextButton(
            label: 'Group Bulk',
            selected: groupBuySelected,
            onPressed: groupBuySelected ? null : onGroupBuy,
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _CatalogueSummary extends StatelessWidget {
  const _CatalogueSummary({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CatalogueMetric(
            value: '${session.workspaceCatalogueItems.length}',
            label: 'Products',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _CatalogueMetric(
            value: '${session.workspacePublishedProductCount}',
            label: 'Public',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _CatalogueMetric(
            value: '${session.workspaceLowStockCount}',
            label: 'Low stock',
          ),
        ),
      ],
    );
  }
}

class _CatalogueMetric extends StatelessWidget {
  const _CatalogueMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(MoolRadii.control),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceProductRow extends StatelessWidget {
  const _WorkspaceProductRow({
    required this.product,
    required this.owned,
    required this.onEdit,
    this.onChangePrice,
    this.onUpdateStock,
    this.onTogglePublic,
  });

  final WorkspaceCatalogueItem product;
  final bool owned;
  final VoidCallback onEdit;
  final VoidCallback? onChangePrice;
  final VoidCallback? onUpdateStock;
  final VoidCallback? onTogglePublic;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: owned ? Key('work-public-sku-${product.id}') : null,
      child: WorkCard(
        keyName: 'work-catalogue-${owned ? 'owned' : 'master'}-${product.id}',
        padding: const EdgeInsets.fromLTRB(8, 7, 6, 7),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFEAF2FF),
              foregroundColor: MoolColors.navy,
              child: Text(
                product.brand.isEmpty ? '?' : product.brand.substring(0, 1),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MoolColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    owned
                        ? '${product.pack} · MRP ₹${product.mrp ?? product.sellingPrice} · ${product.sku}'
                        : '${product.pack} · ${product.sku}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 9.5,
                    ),
                  ),
                  if (owned)
                    Row(
                      children: [
                        _ProductQuickValue(
                          keyName: 'work-catalogue-price-${product.id}',
                          icon: Icons.sell_outlined,
                          label: '₹${product.sellingPrice}',
                          onTap: onChangePrice,
                        ),
                        const SizedBox(width: 5),
                        _ProductQuickValue(
                          keyName: 'work-catalogue-stock-${product.id}',
                          icon: Icons.inventory_2_outlined,
                          label:
                              product.stockMode ==
                                  WorkspaceStockMode.availabilityOnly
                              ? (product.available
                                    ? 'Available'
                                    : 'Unavailable')
                              : '${product.stock} in stock',
                          attention:
                              product.stockMode ==
                                  WorkspaceStockMode.exactQuantity &&
                              product.stock <= product.lowStockThreshold,
                          onTap: onUpdateStock,
                        ),
                      ],
                    )
                  else
                    Text(
                      'MRP ₹${product.mrp ?? product.sellingPrice} · Product details ready',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            if (owned) ...[
              _ProductVisibilityButton(
                keyName: 'work-catalogue-visibility-${product.id}',
                isPublic: product.publicListing,
                onTap: onTogglePublic,
              ),
              IconButton(
                key: Key('work-catalogue-edit-${product.id}'),
                tooltip: 'Edit complete product details',
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ] else
              SizedBox(
                width: 68,
                child: FilledButton.tonal(
                  key: Key('work-catalogue-add-${product.id}'),
                  onPressed: onEdit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                  ),
                  child: const FittedBox(child: Text('Add')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductVisibilityButton extends StatelessWidget {
  const _ProductVisibilityButton({
    required this.keyName,
    required this.isPublic,
    required this.onTap,
  });

  final String keyName;
  final bool isPublic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isPublic ? const Color(0xFF08765D) : MoolColors.muted;
    return Tooltip(
      message: isPublic ? 'Hide from customers' : 'Show to customers',
      child: InkWell(
        key: Key(keyName),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 42,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPublic ? Icons.public_rounded : Icons.visibility_off_outlined,
                color: color,
                size: 18,
              ),
              Text(
                isPublic ? 'Public' : 'Private',
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductQuickValue extends StatelessWidget {
  const _ProductQuickValue({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
    this.attention = false,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final color = attention ? const Color(0xFF9A4A00) : MoolColors.navy;
    return Tooltip(
      message: keyName.contains('stock')
          ? 'Update available quantity'
          : 'Change selling price',
      child: Material(
        color: attention ? const Color(0xFFFFF3E4) : const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          key: Key(keyName),
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
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

class _WorkspaceStockStatementSurface extends StatelessWidget {
  const _WorkspaceStockStatementSurface({
    required this.session,
    required this.onRestock,
  });

  final WorkSession session;
  final ValueChanged<WorkspaceCatalogueItem> onRestock;

  @override
  Widget build(BuildContext context) {
    final products = [...session.workspaceCatalogueItems]
      ..sort((a, b) {
        final aRisk =
            !a.available ||
                (a.stockMode == WorkspaceStockMode.exactQuantity &&
                    a.stock <= a.lowStockThreshold)
            ? 0
            : 1;
        final bRisk =
            !b.available ||
                (b.stockMode == WorkspaceStockMode.exactQuantity &&
                    b.stock <= b.lowStockThreshold)
            ? 0
            : 1;
        return aRisk != bRisk
            ? aRisk.compareTo(bRisk)
            : a.stock.compareTo(b.stock);
      });
    return Container(
      key: const Key('work-stock-statement-screen'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9FAFF), Color(0xFFEEF2FF)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
        children: [
          const Text(
            'Know what you can sell today',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Available quantity, customer-order reservations and every recorded change stay together.',
            style: TextStyle(color: MoolColors.muted, fontSize: 10.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StockSummaryMetric(
                value: '${session.workspaceAvailableUnitCount}',
                label: 'Available',
              ),
              _StockSummaryMetric(
                value: '${session.workspaceReservedUnitCount}',
                label: 'Reserved',
              ),
              _StockSummaryMetric(
                value: '${session.workspaceLowStockCount}',
                label: 'Low stock',
                attention: session.workspaceLowStockCount > 0,
              ),
              _StockSummaryMetric(
                value: '${session.workspaceOutOfStockCount}',
                label: 'Out',
                attention: session.workspaceOutOfStockCount > 0,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Stock position',
            style: TextStyle(
              color: MoolColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          if (products.isEmpty)
            const _StoreEmptyPanel(
              icon: Icons.inventory_2_outlined,
              title: 'No products added yet',
              detail: 'Add a product to begin your stock statement.',
            )
          else
            for (final product in products) ...[
              _StockPositionRow(
                product: product,
                reserved: session.reservedWorkspaceUnitsFor(product.id),
                daysOfStock: session.workspaceDaysOfStockFor(product),
                suggestedQuantity: session.suggestedWorkspaceRestockFor(
                  product,
                ),
                onRestock: () => onRestock(product),
              ),
              const SizedBox(height: 7),
            ],
          const SizedBox(height: 8),
          const Text(
            'Recent quantity changes',
            style: TextStyle(
              color: MoolColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          if (session.workspaceStockMovements.isEmpty)
            const _StoreEmptyPanel(
              icon: Icons.history_rounded,
              title: 'No quantity changes recorded',
              detail:
                  'Sales, goods received, returns and counted adjustments will appear here.',
            )
          else
            for (final movement in session.workspaceStockMovements.take(12))
              _StockMovementRow(movement: movement),
        ],
      ),
    );
  }
}

class _StockSummaryMetric extends StatelessWidget {
  const _StockSummaryMetric({
    required this.value,
    required this.label,
    this.attention = false,
  });

  final String value;
  final String label;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final color = attention ? const Color(0xFF9A4A00) : MoolColors.navy;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
        decoration: BoxDecoration(
          color: attention ? const Color(0xFFFFF3E4) : Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockPositionRow extends StatelessWidget {
  const _StockPositionRow({
    required this.product,
    required this.reserved,
    required this.daysOfStock,
    required this.suggestedQuantity,
    required this.onRestock,
  });

  final WorkspaceCatalogueItem product;
  final int reserved;
  final int? daysOfStock;
  final int suggestedQuantity;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    final low =
        product.stockMode == WorkspaceStockMode.exactQuantity &&
        product.stock <= product.lowStockThreshold;
    final stockLabel = product.stockMode == WorkspaceStockMode.availabilityOnly
        ? (product.available ? 'Available' : 'Unavailable')
        : '${product.stock} available';
    return Material(
      key: Key('work-stock-position-${product.id}'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: low
                  ? const Color(0xFFFFF0DB)
                  : const Color(0xFFEAF2FF),
              foregroundColor: low ? const Color(0xFF9A4A00) : MoolColors.navy,
              child: Text(
                product.brand.isEmpty ? '?' : product.brand.substring(0, 1),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MoolColors.ink,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '$stockLabel · $reserved reserved',
                    style: TextStyle(
                      color: low ? const Color(0xFF9A4A00) : MoolColors.muted,
                      fontSize: 9.5,
                      fontWeight: low ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                  Text(
                    daysOfStock == null
                        ? 'Sales history will estimate days remaining'
                        : '$daysOfStock days at recent sales pace',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            if (low)
              TextButton(
                key: Key('work-stock-restock-${product.id}'),
                onPressed: onRestock,
                child: Text(
                  suggestedQuantity > 0
                      ? 'Restock $suggestedQuantity'
                      : 'Restock',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StockMovementRow extends StatelessWidget {
  const _StockMovementRow({required this.movement});

  final WorkspaceStockMovement movement;

  @override
  Widget build(BuildContext context) {
    final positive = movement.quantityDelta > 0;
    final label = switch (movement.kind) {
      WorkspaceStockMovementKind.sale => 'Sale',
      WorkspaceStockMovementKind.returned => 'Returned to stock',
      WorkspaceStockMovementKind.goodsReceived => 'Goods received',
      WorkspaceStockMovementKind.adjustment => 'Counted adjustment',
      WorkspaceStockMovementKind.damageOrExpiry => 'Damage or expiry',
      WorkspaceStockMovementKind.openingStock => 'Opening quantity',
    };
    return ListTile(
      key: Key('work-stock-movement-${movement.id}'),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: positive
            ? const Color(0xFFEAF7F3)
            : const Color(0xFFFFEFEA),
        child: Icon(
          positive ? Icons.add_rounded : Icons.remove_rounded,
          color: positive ? const Color(0xFF08765D) : const Color(0xFFB42318),
          size: 18,
        ),
      ),
      title: Text(
        movement.productLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        '$label · ${movement.reason}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${positive ? '+' : ''}${movement.quantityDelta}',
        style: TextStyle(
          color: positive ? const Color(0xFF08765D) : const Color(0xFFB42318),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StoreEmptyPanel extends StatelessWidget {
  const _StoreEmptyPanel({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: MoolColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(color: MoolColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogueProductEditor extends StatefulWidget {
  const _CatalogueProductEditor({required this.session, required this.product});

  final WorkSession session;
  final WorkspaceCatalogueItem product;

  @override
  State<_CatalogueProductEditor> createState() =>
      _CatalogueProductEditorState();
}

class _CatalogueProductEditorState extends State<_CatalogueProductEditor> {
  late final TextEditingController _title = TextEditingController(
    text: widget.product.title,
  );
  late final TextEditingController _brand = TextEditingController(
    text: widget.product.brand,
  );
  late final TextEditingController _variant = TextEditingController(
    text: widget.product.variant,
  );
  late final TextEditingController _pack = TextEditingController(
    text: widget.product.pack,
  );
  late final TextEditingController _category = TextEditingController(
    text: widget.product.categoryId,
  );
  late final TextEditingController _sku = TextEditingController(
    text: widget.product.sku,
  );
  late final TextEditingController _barcode = TextEditingController(
    text: widget.product.barcode,
  );
  late final TextEditingController _purchase = TextEditingController(
    text: widget.product.purchasePrice == 0
        ? ''
        : '${widget.product.purchasePrice}',
  );
  late final TextEditingController _selling = TextEditingController(
    text: '${widget.product.sellingPrice}',
  );
  late final TextEditingController _mrp = TextEditingController(
    text: widget.product.mrp == null ? '' : '${widget.product.mrp}',
  );
  late final TextEditingController _stock = TextEditingController(
    text: '${widget.product.stock}',
  );
  late final TextEditingController _lowStockThreshold = TextEditingController(
    text: '${widget.product.lowStockThreshold}',
  );
  late final TextEditingController _delivery = TextEditingController(
    text: widget.product.deliveryPromise,
  );
  late final TextEditingController _unitPrice = TextEditingController(
    text: widget.product.unitPrice,
  );
  late final TextEditingController _origin = TextEditingController(
    text: widget.product.origin,
  );
  late final TextEditingController _minimumOrder = TextEditingController(
    text: '${widget.product.minimumOrder}',
  );
  late final TextEditingController _returnPolicy = TextEditingController(
    text: widget.product.returnPolicy ?? '',
  );
  late final TextEditingController _composition = TextEditingController(
    text: widget.product.composition ?? '',
  );
  late final TextEditingController _regulatory = TextEditingController(
    text: widget.product.regulatoryNote ?? '',
  );
  late final TextEditingController _visualLabel = TextEditingController(
    text: widget.product.visualLabel,
  );
  late bool _public = widget.product.publicListing;
  late bool _available = widget.product.available;
  late WorkspaceStockMode _stockMode = widget.product.stockMode;
  String? _error;

  bool get _catalogueMatched => workspaceMasterCatalogue.any(
    (product) => product.canonicalId == widget.product.canonicalId,
  );

  @override
  void dispose() {
    _title.dispose();
    _brand.dispose();
    _variant.dispose();
    _pack.dispose();
    _category.dispose();
    _sku.dispose();
    _barcode.dispose();
    _purchase.dispose();
    _selling.dispose();
    _mrp.dispose();
    _stock.dispose();
    _lowStockThreshold.dispose();
    _delivery.dispose();
    _unitPrice.dispose();
    _origin.dispose();
    _minimumOrder.dispose();
    _returnPolicy.dispose();
    _composition.dispose();
    _regulatory.dispose();
    _visualLabel.dispose();
    super.dispose();
  }

  void _save() {
    final purchase = int.tryParse(_purchase.text.trim());
    final selling = int.tryParse(_selling.text.trim());
    final mrp = int.tryParse(_mrp.text.trim());
    final stock = _stockMode == WorkspaceStockMode.availabilityOnly
        ? widget.product.stock.clamp(0, 1 << 31).toInt()
        : int.tryParse(_stock.text.trim());
    final lowStockThreshold = int.tryParse(_lowStockThreshold.text.trim());
    final minimumOrder = int.tryParse(_minimumOrder.text.trim());
    final error = _title.text.trim().isEmpty
        ? 'Enter the product name shown to customers.'
        : _brand.text.trim().isEmpty
        ? 'Enter the product brand or maker.'
        : _pack.text.trim().isEmpty
        ? 'Enter the customer pack size.'
        : _category.text.trim().isEmpty
        ? 'Choose or enter the product category.'
        : _sku.text.trim().isEmpty
        ? 'Enter a unique store SKU.'
        : purchase == null || purchase <= 0
        ? 'Enter the current purchase cost for your internal margin view.'
        : selling == null || selling <= purchase
        ? 'Enter a customer price above the purchase cost.'
        : stock == null || stock < 0
        ? 'Enter the available stock.'
        : lowStockThreshold == null || lowStockThreshold < 0
        ? 'Enter when you want a low-stock reminder.'
        : mrp != null && mrp < selling
        ? 'MRP cannot be lower than the customer price.'
        : _delivery.text.trim().isEmpty
        ? 'Add the customer delivery promise.'
        : minimumOrder == null || minimumOrder <= 0
        ? 'Enter the minimum customer order quantity.'
        : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    widget.session.addOrUpdateWorkspaceProduct(
      widget.product.copyWith(
        categoryId: _category.text.trim(),
        brand: _brand.text.trim(),
        title: _title.text.trim(),
        variant: _variant.text.trim(),
        pack: _pack.text.trim(),
        sku: _sku.text.trim(),
        barcode: _barcode.text.trim(),
        purchasePrice: purchase,
        sellingPrice: selling,
        mrp: mrp,
        stock: stock,
        unitPrice: _unitPrice.text.trim().isEmpty
            ? '₹$selling/${_pack.text.trim()}'
            : _unitPrice.text.trim(),
        deliveryPromise: _delivery.text.trim(),
        origin: _origin.text.trim().isEmpty ? 'India' : _origin.text.trim(),
        visualLabel: _visualLabel.text.trim().isEmpty
            ? '${_brand.text.trim()} ${_title.text.trim()} ${_pack.text.trim()}'
            : _visualLabel.text.trim(),
        minimumOrder: minimumOrder,
        returnPolicy: _returnPolicy.text.trim(),
        composition: _composition.text.trim(),
        regulatoryNote: _regulatory.text.trim(),
        available: _stockMode == WorkspaceStockMode.availabilityOnly
            ? _available
            : stock! > 0,
        publicListing:
            _public &&
            _catalogueMatched &&
            (_stockMode == WorkspaceStockMode.availabilityOnly
                ? _available
                : stock! > 0),
        stockMode: _stockMode,
        lowStockThreshold: lowStockThreshold,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.md,
              MoolSpacing.md,
              MediaQuery.viewInsetsOf(context).bottom + 96,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.title.isEmpty
                              ? 'Add product'
                              : 'Edit ${widget.product.title}',
                          style: const TextStyle(
                            color: MoolColors.navy,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('work-product-close'),
                        tooltip: 'Close product editor',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text(
                    widget.product.title.isEmpty
                        ? 'Create the complete customer-facing catalogue record.'
                        : '${widget.product.brand} · ${widget.product.pack} · ${widget.product.sku}',
                    style: const TextStyle(color: MoolColors.muted),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  Container(
                    key: const Key('work-product-fast-editor'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F6FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color(0xFFDDE6FF),
                              foregroundColor: MoolColors.navy,
                              child: Text(
                                _brand.text.trim().isEmpty
                                    ? '?'
                                    : _brand.text.trim().substring(0, 1),
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _title.text.trim().isEmpty
                                        ? 'New product'
                                        : _title.text.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: MoolColors.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    _pack.text.trim().isEmpty
                                        ? 'Add the customer pack or size'
                                        : '${_pack.text.trim()} · ${_sku.text.trim()}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: MoolColors.muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _catalogueMatched
                                  ? Icons.verified_rounded
                                  : Icons.lock_outline_rounded,
                              color: _catalogueMatched
                                  ? const Color(0xFF08765D)
                                  : MoolColors.muted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MoneyField(
                                keyName: 'work-product-selling-price',
                                controller: _selling,
                                label: 'Selling price',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MoneyField(
                                keyName: 'work-product-mrp',
                                controller: _mrp,
                                label: 'MRP',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'How do you track this product?',
                          style: TextStyle(
                            color: MoolColors.ink,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                key: const Key('work-product-stock-exact'),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Exact quantity'),
                                ),
                                selected:
                                    _stockMode ==
                                    WorkspaceStockMode.exactQuantity,
                                onSelected: (_) => setState(
                                  () => _stockMode =
                                      WorkspaceStockMode.exactQuantity,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: ChoiceChip(
                                key: const Key('work-product-stock-available'),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Availability only'),
                                ),
                                selected:
                                    _stockMode ==
                                    WorkspaceStockMode.availabilityOnly,
                                onSelected: (_) => setState(
                                  () => _stockMode =
                                      WorkspaceStockMode.availabilityOnly,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_stockMode == WorkspaceStockMode.exactQuantity)
                          Row(
                            children: [
                              Expanded(
                                child: _AccessibleWorkTextField(
                                  keyName: 'work-product-stock',
                                  controller: _stock,
                                  keyboardType: TextInputType.number,
                                  label: 'Quantity available',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _AccessibleWorkTextField(
                                  keyName: 'work-product-low-stock-threshold',
                                  controller: _lowStockThreshold,
                                  keyboardType: TextInputType.number,
                                  label: 'Remind me at',
                                ),
                              ),
                            ],
                          )
                        else
                          Material(
                            color: Colors.transparent,
                            child: SwitchListTile.adaptive(
                              key: const Key('work-product-available'),
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Available for customers'),
                              subtitle: const Text(
                                'Turn this off when you cannot fulfil orders.',
                              ),
                              value: _available,
                              onChanged: (value) =>
                                  setState(() => _available = value),
                            ),
                          ),
                        Row(
                          key: const Key('work-product-public'),
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Show to customers',
                                    style: TextStyle(
                                      color: MoolColors.ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    _catalogueMatched
                                        ? 'Buy shows your price and availability. Purchase cost stays private.'
                                        : 'This product stays private until its details are reviewed.',
                                    style: const TextStyle(
                                      color: MoolColors.muted,
                                      fontSize: 9.5,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _catalogueMatched && _public,
                              onChanged: _catalogueMatched
                                  ? (value) => setState(() => _public = value)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    key: const Key('work-product-details-section'),
                    initiallyExpanded: widget.product.title.isEmpty,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text(
                      'Product and store details',
                      style: TextStyle(
                        color: MoolColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: const Text(
                      'Name, pack, barcode, purchase cost and delivery',
                    ),
                    children: [
                      _AccessibleWorkTextField(
                        keyName: 'work-product-title',
                        controller: _title,
                        label: 'Product name',
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      _ResponsiveFieldPair(
                        first: _AccessibleWorkTextField(
                          keyName: 'work-product-brand',
                          controller: _brand,
                          label: 'Brand or maker',
                        ),
                        second: _AccessibleWorkTextField(
                          keyName: 'work-product-category',
                          controller: _category,
                          label: 'Category',
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      _ResponsiveFieldPair(
                        first: _AccessibleWorkTextField(
                          keyName: 'work-product-variant',
                          controller: _variant,
                          label: 'Variant',
                        ),
                        second: _AccessibleWorkTextField(
                          keyName: 'work-product-pack',
                          controller: _pack,
                          label: 'Pack or size',
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      _ResponsiveFieldPair(
                        first: _AccessibleWorkTextField(
                          keyName: 'work-product-sku',
                          controller: _sku,
                          label: 'Store SKU',
                        ),
                        second: _AccessibleWorkTextField(
                          keyName: 'work-product-barcode',
                          controller: _barcode,
                          keyboardType: TextInputType.number,
                          label: 'Barcode',
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      _MoneyField(
                        keyName: 'work-product-purchase-price',
                        controller: _purchase,
                        label: 'Purchase cost — only you can see this',
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      _AccessibleWorkTextField(
                        keyName: 'work-product-delivery',
                        controller: _delivery,
                        label: 'Customer delivery promise',
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      _ResponsiveFieldPair(
                        first: _AccessibleWorkTextField(
                          keyName: 'work-product-unit-price',
                          controller: _unitPrice,
                          label: 'Unit price shown to customers',
                          hint: 'For example ₹264/L',
                        ),
                        second: _AccessibleWorkTextField(
                          keyName: 'work-product-minimum-order',
                          controller: _minimumOrder,
                          keyboardType: TextInputType.number,
                          label: 'Minimum customer order',
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      _AccessibleWorkTextField(
                        keyName: 'work-product-origin',
                        controller: _origin,
                        label: 'Country of origin',
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                    ],
                  ),
                  ExpansionTile(
                    key: const Key('work-product-customer-facts-section'),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text(
                      'Details customers may need',
                      style: TextStyle(
                        color: MoolColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: const Text(
                      'Return, ingredients, safety and product photo description',
                    ),
                    children: [
                      _AccessibleWorkTextField(
                        keyName: 'work-product-return-policy',
                        controller: _returnPolicy,
                        maxLines: 2,
                        label: 'Return policy',
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      _AccessibleWorkTextField(
                        keyName: 'work-product-composition',
                        controller: _composition,
                        maxLines: 2,
                        label: 'Composition or ingredients',
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      _AccessibleWorkTextField(
                        keyName: 'work-product-regulatory',
                        controller: _regulatory,
                        maxLines: 2,
                        label: 'Regulatory or safety information',
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      _AccessibleWorkTextField(
                        keyName: 'work-product-visual-label',
                        controller: _visualLabel,
                        label: 'Product photo description',
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                    ],
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      key: const Key('work-product-error'),
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (widget.session.workspaceCatalogueItems.any(
                    (product) => product.id == widget.product.id,
                  )) ...[
                    const SizedBox(height: MoolSpacing.xs),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('work-product-retire'),
                        onPressed: () {
                          widget.session.retireWorkspaceProduct(
                            widget.product.id,
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        label: const Text('Remove from active catalogue'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 76),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom:
                MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.viewPaddingOf(context).bottom +
                8,
            child: Material(
              color: Colors.white,
              elevation: 3,
              shadowColor: const Color(0x22001B4D),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('work-product-cancel'),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('work-product-save'),
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Save product'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessibleWorkTextField extends StatefulWidget {
  const _AccessibleWorkTextField({
    required this.keyName,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.prefixText,
  });

  final String keyName;
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final String? prefixText;

  @override
  State<_AccessibleWorkTextField> createState() =>
      _AccessibleWorkTextFieldState();
}

class _AccessibleWorkTextFieldState extends State<_AccessibleWorkTextField> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'work-${widget.keyName}',
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleValueChanged);
  }

  @override
  void didUpdateWidget(covariant _AccessibleWorkTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleValueChanged);
      widget.controller.addListener(_handleValueChanged);
    }
  }

  void _handleValueChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleValueChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      identifier: widget.keyName,
      label: widget.label,
      hint: 'Enter ${widget.label.toLowerCase()}',
      value: widget.controller.text.trim().isEmpty
          ? 'Not entered'
          : widget.controller.text,
      textField: true,
      onTap: _focusNode.requestFocus,
      onSetText: (value) {
        widget.controller
          ..text = value
          ..selection = TextSelection.collapsed(offset: value.length);
        widget.onChanged?.call(value);
      },
      child: ExcludeSemantics(
        child: TextField(
          key: Key(widget.keyName),
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          decoration: InputDecoration(
            label: Text(widget.label),
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,
            prefixText: widget.prefixText,
          ),
        ),
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.keyName,
    required this.controller,
    required this.label,
  });

  final String keyName;
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _AccessibleWorkTextField(
      keyName: keyName,
      controller: controller,
      label: label,
      keyboardType: TextInputType.number,
      prefixText: '₹ ',
    );
  }
}

class _CustomerStorePreviewSurface extends StatelessWidget {
  const _CustomerStorePreviewSurface({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final products = session.workspaceCatalogueItems
        .where((product) => product.published)
        .toList();
    final ready =
        session.retailerSetupSaved ||
        session.reviewStage == WorkReviewStage.live;
    return ListView(
      key: const Key('work-dashboard-preview-screen'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      children: [
        const _WorkspaceSectionLabel(
          title: 'Customer storefront preview',
          detail: 'Customer-facing availability, fulfilment and product facts',
        ),
        const SizedBox(height: MoolSpacing.xs),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MoolColors.navy,
            borderRadius: BorderRadius.circular(MoolRadii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.workspaceVisibleToCustomers
                    ? 'CUSTOMER VIEW · VISIBLE'
                    : 'CUSTOMER VIEW · PRIVATE PREVIEW',
                style: const TextStyle(
                  color: Color(0xFFFFC073),
                  fontSize: 9,
                  letterSpacing: .6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                session.activeWorkspace?.name ?? 'Your store',
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${session.activeWorkspace?.area ?? ''} · Mool Retail Partner',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFD9DAFF), fontSize: 11),
              ),
              const SizedBox(height: MoolSpacing.xs),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _PreviewFactChip(
                    icon:
                        session.workspaceStoreState == WorkspaceStoreState.open
                        ? Icons.circle
                        : Icons.schedule_rounded,
                    label: switch (session.workspaceStoreState) {
                      WorkspaceStoreState.open => 'Open for orders',
                      WorkspaceStoreState.paused =>
                        'Paused ${session.workspaceReopensAt}',
                      WorkspaceStoreState.off => 'Ordering is off',
                    },
                  ),
                  _PreviewFactChip(
                    icon: Icons.local_shipping_outlined,
                    label: session.workspaceFulfilmentMode,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        const _WorkspaceSectionLabel(
          title: 'Available products',
          detail: 'Customer price and delivery',
        ),
        const SizedBox(height: MoolSpacing.xs),
        if (products.isEmpty)
          const WorkCard(
            keyName: 'work-preview-empty',
            child: Text(
              'No public product is available yet. Add stock and enable customer visibility from Catalogue.',
              style: TextStyle(color: MoolColors.muted, height: 1.3),
            ),
          )
        else
          for (final product in products) ...[
            WorkCard(
              keyName: 'work-preview-product-${product.id}',
              padding: const EdgeInsets.all(10),
              onTap: () =>
                  _showCustomerProductPreview(context, session, product),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFEAF2FF),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: MoolColors.navy,
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${product.pack} · ${product.deliveryPromise}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${product.sellingPrice}',
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
          ],
        WorkCard(
          keyName: 'work-preview-retailer-controls',
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store visibility',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Retailer control · not shown to customers',
                      style: TextStyle(color: MoolColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 132,
                child: FilledButton.tonalIcon(
                  key: const Key('work-preview-visibility'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: ready
                      ? () => session.setWorkspaceVisibility(
                          !session.workspaceVisibleToCustomers,
                        )
                      : null,
                  icon: Icon(
                    session.workspaceVisibleToCustomers
                        ? Icons.visibility_off_outlined
                        : Icons.public_rounded,
                  ),
                  label: FittedBox(
                    child: Text(
                      session.workspaceVisibleToCustomers
                          ? 'Make private'
                          : 'Publish Store',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        WorkCard(
          keyName: 'work-preview-trust',
          color: const Color(0xFFF4F6FF),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE8F7F1),
                child: Icon(Icons.verified_outlined, color: Color(0xFF08765D)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MoolSocial partner',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Reliability grows with completed customer orders.',
                      style: TextStyle(color: MoolColors.muted, fontSize: 10),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 104,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: null,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                  label: const FittedBox(child: Text('Follow')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _showCustomerProductPreview(
  BuildContext context,
  WorkSession session,
  WorkspaceCatalogueItem product,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (sheetContext) => SafeArea(
    top: false,
    child: FractionallySizedBox(
      heightFactor: .78,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close product details',
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Text(
            '${product.brand} · ${product.variant} · ${product.pack}',
            style: const TextStyle(color: MoolColors.muted),
          ),
          const SizedBox(height: 12),
          WorkCard(
            color: const Color(0xFFF4F6FF),
            child: Column(
              children: [
                _ProductPreviewLine(
                  label: 'Customer price',
                  value: '₹${product.sellingPrice}',
                ),
                _ProductPreviewLine(
                  label: 'MRP',
                  value: '₹${product.mrp ?? product.sellingPrice}',
                ),
                _ProductPreviewLine(
                  label: 'Unit price',
                  value: product.unitPrice,
                ),
                _ProductPreviewLine(
                  label: 'Available stock',
                  value: '${product.stock}',
                ),
                _ProductPreviewLine(
                  label: 'Delivery',
                  value: product.deliveryPromise,
                ),
                _ProductPreviewLine(
                  label: 'Minimum order',
                  value: '${product.minimumOrder}',
                ),
                _ProductPreviewLine(
                  label: 'Country of origin',
                  value: product.origin,
                ),
              ],
            ),
          ),
          if ((product.returnPolicy ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.assignment_return_outlined),
              title: const Text('Return policy'),
              subtitle: Text(product.returnPolicy!),
            ),
          ],
          if ((product.composition ?? '').isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Composition or ingredients'),
              subtitle: Text(product.composition!),
            ),
          if ((product.regulatoryNote ?? '').isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text('Safety information'),
              subtitle: Text(product.regulatoryNote!),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('work-preview-open-buy-product'),
            onPressed: session.workspaceVisibleToCustomers && product.published
                ? () {
                    Navigator.of(sheetContext).pop();
                    context.push(
                      Uri(
                        path: '/app/buy',
                        queryParameters: {
                          'view': 'product',
                          'product': product.id,
                          'workspaceProduct': product.id,
                          'return': GoRouterState.of(context).uri.toString(),
                        },
                      ).toString(),
                    );
                  }
                : null,
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Open customer Buy view'),
          ),
        ],
      ),
    ),
  ),
);

class _ProductPreviewLine extends StatelessWidget {
  const _ProductPreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: MoolColors.muted)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PreviewFactChip extends StatelessWidget {
  const _PreviewFactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceGroupBuyingSurface extends StatefulWidget {
  const _WorkspaceGroupBuyingSurface({required this.session});

  final WorkSession session;

  @override
  State<_WorkspaceGroupBuyingSurface> createState() =>
      _WorkspaceGroupBuyingSurfaceState();
}

class _WorkspaceGroupBuyingSurfaceState
    extends State<_WorkspaceGroupBuyingSurface> {
  String? _productId;
  final TextEditingController _specification = TextEditingController();
  final TextEditingController _target = TextEditingController();
  final TextEditingController _secured = TextEditingController();
  final TextEditingController _unit = TextEditingController(text: 'kg');
  final TextEditingController _regularPrice = TextEditingController();
  final TextEditingController _groupPrice = TextEditingController();
  final TextEditingController _facilitationFee = TextEditingController(
    text: '0',
  );
  final TextEditingController _deliveryFee = TextEditingController(text: '0');
  final TextEditingController _confirmationAmount = TextEditingController();
  final TextEditingController _closing = TextEditingController();
  final TextEditingController _deliveryDate = TextEditingController();
  String? _error;
  DateTime? _closingAt;
  DateTime? _deliveryOn;

  List<WorkspaceCatalogueItem> get _availableProducts {
    final byId = <String, WorkspaceCatalogueItem>{
      for (final product in workspaceMasterCatalogue) product.id: product,
      for (final product in widget.session.workspaceCatalogueItems)
        product.id: product,
    };
    return byId.values.toList(growable: false);
  }

  Future<void> _chooseProduct() async {
    final selected = await showModalBottomSheet<WorkspaceCatalogueItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _GroupBuyProductPicker(products: _availableProducts),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _productId = selected.id;
      if (_specification.text.isEmpty) {
        _specification.text = '${selected.variant} · ${selected.pack}';
      }
    });
  }

  Future<void> _pickClosing() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      initialDate: _closingAt ?? now.add(const Duration(days: 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _closingAt ?? now.add(const Duration(days: 3)),
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _closingAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _closing.text =
          '${date.day}/${date.month}/${date.year} · ${time.format(context)}';
    });
  }

  Future<void> _pickDeliveryDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: _closingAt ?? now,
      lastDate: now.add(const Duration(days: 120)),
      initialDate:
          _deliveryOn ?? (_closingAt ?? now).add(const Duration(days: 2)),
    );
    if (date == null) return;
    setState(() {
      _deliveryOn = date;
      _deliveryDate.text =
          '${date.day}/${date.month}/${date.year} · Door delivery';
    });
  }

  @override
  void dispose() {
    _specification.dispose();
    _target.dispose();
    _secured.dispose();
    _unit.dispose();
    _regularPrice.dispose();
    _groupPrice.dispose();
    _facilitationFee.dispose();
    _deliveryFee.dispose();
    _confirmationAmount.dispose();
    _closing.dispose();
    _deliveryDate.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final selected = _availableProducts
        .where((product) => product.id == _productId)
        .firstOrNull;
    final target = int.tryParse(_target.text.trim());
    final secured = int.tryParse(_secured.text.trim());
    final regular = int.tryParse(_regularPrice.text.trim());
    final group = int.tryParse(_groupPrice.text.trim());
    final facilitation = int.tryParse(_facilitationFee.text.trim());
    final delivery = int.tryParse(_deliveryFee.text.trim());
    final confirmation = int.tryParse(_confirmationAmount.text.trim());
    final error = selected == null
        ? 'Choose the exact product or commodity.'
        : _specification.text.trim().isEmpty
        ? 'Add the complete product specification.'
        : target == null || target <= 0
        ? 'Enter the total Group Bulk Buying quantity.'
        : secured == null || secured <= 0 || secured > target
        ? 'Enter the quantity already confirmed by your store.'
        : _unit.text.trim().isEmpty
        ? 'Enter the trading unit.'
        : regular == null || regular <= 0
        ? 'Enter the regular market price.'
        : group == null || group <= 0 || group >= regular
        ? 'Enter an offer price below the regular price.'
        : facilitation == null || facilitation < 0
        ? 'Enter the MoolSocial facilitation fee.'
        : delivery == null || delivery < 0
        ? 'Enter the store delivery fee or zero for free delivery.'
        : confirmation == null || confirmation <= 0
        ? 'Enter the confirmation amount.'
        : _closingAt == null
        ? 'Add the closing date and time.'
        : _deliveryOn == null || _deliveryOn!.isBefore(_closingAt!)
        ? 'Add the expected door-delivery date.'
        : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _error = null);
    FocusManager.instance.primaryFocus?.unfocus();
    await widget.session.createWorkspaceGroupBuy(
      productName: selected!.title,
      specification: _specification.text.trim(),
      targetQuantity: target!,
      securedQuantity: secured!,
      unitLabel: _unit.text.trim(),
      regularUnitPrice: regular!,
      groupUnitPrice: group!,
      facilitationFee: facilitation!,
      deliveryFee: delivery!,
      confirmationAmount: confirmation!,
      closingLabel: _closing.text.trim(),
      storeDeliveryLabel: _deliveryDate.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupBuy = widget.session.activeGroupBuy;
    if (groupBuy != null) {
      return _ActiveGroupBuyView(groupBuy: groupBuy);
    }
    final products = _availableProducts;
    return ListView(
      key: const Key('work-group-buy-create-screen'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      children: [
        const Text(
          'Start Group Bulk Buying',
          style: TextStyle(
            color: MoolColors.navy,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text(
          'Review the exact product, delivered price, fees and closing time before securing your quantity.',
          style: TextStyle(color: MoolColors.muted),
        ),
        const SizedBox(height: MoolSpacing.sm),
        OutlinedButton.icon(
          key: const Key('work-group-buy-product'),
          onPressed: _chooseProduct,
          icon: const Icon(Icons.search_rounded),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              products
                      .where((product) => product.id == _productId)
                      .firstOrNull
                      ?.title ??
                  'Search product or commodity',
            ),
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        TextField(
          key: const Key('work-group-buy-specification'),
          controller: _specification,
          decoration: const InputDecoration(
            labelText: 'Exact specification and grade',
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        _ResponsiveFieldPair(
          first: _NumberField(
            keyName: 'work-group-buy-target',
            controller: _target,
            label: 'Target quantity',
          ),
          second: _NumberField(
            keyName: 'work-group-buy-secured',
            controller: _secured,
            label: 'Your confirmed quantity',
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        Semantics(
          label: 'Trading unit',
          textField: true,
          child: TextField(
            key: const Key('work-group-buy-unit'),
            controller: _unit,
            decoration: const InputDecoration(labelText: 'Trading unit'),
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        _ResponsiveFieldPair(
          first: _MoneyField(
            keyName: 'work-group-buy-regular-price',
            controller: _regularPrice,
            label: 'Regular / unit',
          ),
          second: _MoneyField(
            keyName: 'work-group-buy-price',
            controller: _groupPrice,
            label: 'Offer / unit',
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        _MoneyField(
          keyName: 'work-group-buy-facilitation-fee',
          controller: _facilitationFee,
          label: 'MoolSocial trade facilitation fee',
        ),
        const SizedBox(height: MoolSpacing.xs),
        _MoneyField(
          keyName: 'work-group-buy-delivery-fee',
          controller: _deliveryFee,
          label: 'Delivery fee (enter zero for free delivery)',
        ),
        const SizedBox(height: MoolSpacing.xs),
        _MoneyField(
          keyName: 'work-group-buy-confirmation-amount',
          controller: _confirmationAmount,
          label: 'Confirmation amount',
        ),
        const SizedBox(height: MoolSpacing.xs),
        TextField(
          key: const Key('work-group-buy-closing'),
          controller: _closing,
          readOnly: true,
          onTap: _pickClosing,
          decoration: const InputDecoration(
            labelText: 'Closing date and time',
            hintText: 'Choose the final date and time',
            suffixIcon: Icon(Icons.event_outlined),
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        TextField(
          key: const Key('work-group-buy-delivery-date'),
          controller: _deliveryDate,
          readOnly: true,
          onTap: _pickDeliveryDate,
          decoration: const InputDecoration(
            labelText: 'Door-delivery date',
            hintText: 'Choose the confirmed expected date',
            suffixIcon: Icon(Icons.local_shipping_outlined),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: MoolColors.navy,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The offer becomes visible to other eligible retailers after your payment is confirmed.',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null)
          Text(
            _error!,
            key: const Key('work-group-buy-error'),
            style: const TextStyle(
              color: Color(0xFFB42318),
              fontWeight: FontWeight.w800,
            ),
          ),
        const SizedBox(height: MoolSpacing.sm),
        FilledButton.icon(
          key: const Key('work-group-buy-confirm'),
          onPressed: widget.session.busy ? null : _start,
          icon: const Icon(Icons.lock_outline_rounded),
          label: const Text('Continue to secure your quantity'),
        ),
      ],
    );
  }
}

class _GroupBuyProductPicker extends StatefulWidget {
  const _GroupBuyProductPicker({required this.products});

  final List<WorkspaceCatalogueItem> products;

  @override
  State<_GroupBuyProductPicker> createState() => _GroupBuyProductPickerState();
}

class _GroupBuyProductPickerState extends State<_GroupBuyProductPicker> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _query.text.trim().toLowerCase();
    final matches = widget.products
        .where((product) {
          return normalized.isEmpty ||
              '${product.title} ${product.brand} ${product.variant} ${product.pack} ${product.sku}'
                  .toLowerCase()
                  .contains(normalized);
        })
        .toList(growable: false);
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: .72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('work-group-buy-product-search'),
                controller: _query,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Search wholesale product or commodity',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final product = matches[index];
                  return ListTile(
                    title: Text(product.title),
                    subtitle: Text(
                      '${product.brand} · ${product.variant} · ${product.pack}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => Navigator.of(context).pop(product),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.keyName,
    required this.controller,
    required this.label,
  });

  final String keyName;
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _AccessibleWorkTextField(
      keyName: keyName,
      controller: controller,
      label: label,
      keyboardType: TextInputType.number,
    );
  }
}

class _ActiveGroupBuyView extends StatelessWidget {
  const _ActiveGroupBuyView({required this.groupBuy});
  final WorkspaceGroupBuy groupBuy;

  @override
  Widget build(BuildContext context) {
    final progress = groupBuy.targetQuantity == 0
        ? 0.0
        : (groupBuy.securedQuantity / groupBuy.targetQuantity).clamp(0.0, 1.0);
    return ListView(
      key: const Key('work-group-buy-active-screen'),
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Group Bulk Buying',
          style: TextStyle(
            fontSize: 12,
            color: MoolColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          groupBuy.productName,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: MoolColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          groupBuy.specification,
          style: const TextStyle(
            fontSize: 13,
            color: MoolColors.ink,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: MoolColors.navy,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GROUP PRICE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: .8,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${groupBuy.groupUnitPrice}/${groupBuy.unitLabel}',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reference ₹${groupBuy.regularUnitPrice}/${groupBuy.unitLabel} · ₹${groupBuy.savingPerUnit} less before fees',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ProductPreviewLine(
          label: 'Confirmed',
          value:
              '${groupBuy.securedQuantity} / ${groupBuy.targetQuantity} ${groupBuy.unitLabel}',
        ),
        const SizedBox(height: 6),
        Semantics(
          label: 'Confirmed quantity',
          value: '${(progress * 100).round()} percent',
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            color: MoolColors.navy,
            backgroundColor: const Color(0xFFE4E8F5),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 10),
        _ProductPreviewLine(
          label: 'Still available',
          value:
              '${(groupBuy.targetQuantity - groupBuy.securedQuantity).clamp(0, groupBuy.targetQuantity)} ${groupBuy.unitLabel}',
        ),
        _ProductPreviewLine(label: 'Closes', value: groupBuy.closingLabel),
        _ProductPreviewLine(
          label: 'Delivery',
          value: groupBuy.storeDeliveryLabel,
        ),
        if (groupBuy.deliveryPartnerName != null)
          _ProductPreviewLine(
            label: 'Delivery partner',
            value: groupBuy.deliveryPartnerName!,
          ),
        const Divider(height: 28),
        const Text(
          'Complete cost',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: MoolColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        _GroupBuyReviewLine(
          label: 'Goods · ${groupBuy.securedQuantity} ${groupBuy.unitLabel}',
          value: '₹${_formatStoreAmount(groupBuy.goodsValue)}',
        ),
        _GroupBuyReviewLine(
          label: 'MoolSocial trade fee',
          value: '₹${groupBuy.facilitationFee}',
        ),
        _GroupBuyReviewLine(
          label: 'Delivery fee',
          value: groupBuy.deliveryFee == 0
              ? 'Free'
              : '₹${groupBuy.deliveryFee}',
        ),
        _GroupBuyReviewLine(
          label: 'Total with listed fees',
          value: '₹${_formatStoreAmount(groupBuy.deliveredTotal)}',
          strong: true,
        ),
        _GroupBuyReviewLine(
          label: 'Saving after listed fees',
          value: '₹${groupBuy.netSaving}',
          strong: true,
        ),
        const SizedBox(height: 6),
        const Text(
          'Check the supplier invoice for applicable taxes before payment.',
          style: TextStyle(fontSize: 11, color: MoolColors.muted, height: 1.4),
        ),
        const Divider(height: 28),
        Text(
          '${groupBuy.confirmedRetailers.length} participating stores',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: MoolColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        for (final participant in groupBuy.participants)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.storefront_outlined,
              color: MoolColors.navy,
            ),
            title: Text(
              participant.businessName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${participant.locality} · ${participant.milestone}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Text(
              '${participant.quantity} ${participant.unitLabel}',
              style: const TextStyle(fontSize: 12, color: MoolColors.navy),
            ),
          ),
        if (groupBuy.participants.isEmpty)
          for (final name in groupBuy.confirmedRetailers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront_outlined),
              title: Text(name),
            ),
        const Divider(height: 28),
        Text(
          groupBuy.paymentConfirmed
              ? 'Confirmation payment recorded'
              : 'Payment not confirmed',
          key: const Key('work-group-buy-payment-confirmed'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: MoolColors.navy,
          ),
        ),
        _GroupBuyReviewLine(
          label: 'Confirmation amount',
          value: '₹${groupBuy.confirmationAmount}',
        ),
        Text(
          groupBuy.paymentConfirmed
              ? 'Awaiting stock confirmation. Any further payment request will appear with its amount and deadline.'
              : 'Wait for payment confirmation before making another payment.',
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: MoolColors.muted,
          ),
        ),
      ],
    );
  }
}

class _GroupBuyReviewLine extends StatelessWidget {
  const _GroupBuyReviewLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: MoolColors.muted)),
          ),
          Text(
            value,
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: strong ? 17 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _LegacyActiveGroupBuyView extends StatelessWidget {
  const _LegacyActiveGroupBuyView({required this.groupBuy});

  final WorkspaceGroupBuy groupBuy;

  @override
  Widget build(BuildContext context) {
    final progress = groupBuy.targetQuantity == 0
        ? 0.0
        : groupBuy.securedQuantity / groupBuy.targetQuantity;
    return Container(
      key: const Key('work-group-buy-active-screen'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF070A2D), Color(0xFF11176A)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            'GROUP BULK BUYING',
            style: TextStyle(
              color: Color(0xFFFFB34E),
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            groupBuy.productName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            groupBuy.specification,
            style: const TextStyle(color: Color(0xFFBFC6FF)),
          ),
          const SizedBox(height: 22),
          Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 15,
                      backgroundColor: Colors.white12,
                      color: const Color(0xFFFFA31A),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${groupBuy.securedQuantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'of ${groupBuy.targetQuantity} ${groupBuy.unitLabel} secured',
                        style: const TextStyle(color: Color(0xFFBFC6FF)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _GroupBulkPrice(
                  label: 'Group price',
                  value: '₹${groupBuy.groupUnitPrice}/${groupBuy.unitLabel}',
                  accent: const Color(0xFF52E5A3),
                ),
              ),
              Expanded(
                child: _GroupBulkPrice(
                  label: 'Regular price',
                  value: '₹${groupBuy.regularUnitPrice}/${groupBuy.unitLabel}',
                ),
              ),
              Expanded(
                child: _GroupBulkPrice(
                  label: 'You save',
                  value: '₹${groupBuy.totalSaving}',
                  accent: const Color(0xFFFFB34E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _GroupBulkLine(label: 'Closes', value: groupBuy.closingLabel),
                _GroupBulkLine(
                  label: 'Trade facilitation fee',
                  value: '₹${groupBuy.facilitationFee}',
                ),
                _GroupBulkLine(
                  label: 'Delivery',
                  value: groupBuy.deliveryFee == 0
                      ? 'Free · ${groupBuy.storeDeliveryLabel}'
                      : '₹${groupBuy.deliveryFee} · ${groupBuy.storeDeliveryLabel}',
                ),
                _GroupBulkLine(
                  label: 'Confirmation paid',
                  value: '₹${groupBuy.confirmationAmount}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'CONFIRMED STORES',
            style: TextStyle(
              color: Color(0xFFBFC6FF),
              fontSize: 10,
              letterSpacing: .7,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: groupBuy.confirmedRetailers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final retailer = groupBuy.confirmedRetailers[index];
                return Container(
                  width: 172,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF52E5A3),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          retailer,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupBulkPrice extends StatelessWidget {
  const _GroupBulkPrice({
    required this.label,
    required this.value,
    this.accent = Colors.white,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFBFC6FF), fontSize: 9.5),
        ),
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _GroupBulkLine extends StatelessWidget {
  const _GroupBulkLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFBFC6FF)),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _GroupBuyFact extends StatelessWidget {
  const _GroupBuyFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: MoolColors.muted)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: MoolColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationMetricBoard extends StatelessWidget {
  const _OperationMetricBoard({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      keyName: 'work-payments-summary',
      color: const Color(0xFFEAF7F3),
      child: Column(
        children: [
          _PaymentMetric(
            label: 'Completed sales today',
            value: '₹${session.workspaceSalesToday}',
          ),
          const Divider(height: MoolSpacing.md),
          _PaymentMetric(
            label: 'Available for settlement',
            value: '₹${session.workspaceSettlementBalance}',
          ),
          const Divider(height: MoolSpacing.md),
          _PaymentMetric(
            label: 'Settlement requested',
            value: '₹${session.workspaceSettlementRequested}',
          ),
        ],
      ),
    );
  }
}

class _PaymentMetric extends StatelessWidget {
  const _PaymentMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _OrdersDestinationSurface extends StatefulWidget {
  const _OrdersDestinationSurface({
    required this.session,
    required this.onCreateOrder,
    required this.onOpenDelivery,
  });

  final WorkSession session;
  final VoidCallback onCreateOrder;
  final VoidCallback onOpenDelivery;

  @override
  State<_OrdersDestinationSurface> createState() =>
      _OrdersDestinationSurfaceState();
}

class _OrdersDestinationSurfaceState extends State<_OrdersDestinationSurface> {
  late String _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.session.workspaceOrderFilter;
  }

  @override
  void didUpdateWidget(covariant _OrdersDestinationSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_filter != widget.session.workspaceOrderFilter) {
      _filter = widget.session.workspaceOrderFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final allOrders = session.visibleWorkspaceOrders;
    bool matches(WorkspaceOrderRecord order, String filter) => switch (filter) {
      'Live' => !const {'Completed', 'Cancelled'}.contains(order.stage),
      'New' => order.stage == 'Confirmed',
      'Packing' => order.stage == 'Preparing',
      'Ready' => const {
        'Ready',
        'Ready for pickup',
        'Delivery requested',
      }.contains(order.stage),
      'Done' => const {'Completed', 'Cancelled'}.contains(order.stage),
      _ => false,
    };

    int countFor(String filter) =>
        allOrders.where((order) => matches(order, filter)).length;
    final visibleOrders = allOrders
        .where((order) => matches(order, _filter))
        .toList(growable: false);
    const filterLabels = {
      'Live': 'All',
      'New': 'New',
      'Packing': 'Packing',
      'Ready': 'Ready',
      'Done': 'History',
    };
    return Container(
      key: const Key('work-orders-destination'),
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Customer orders',
                    style: TextStyle(
                      color: MoolColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${countFor('Live')} active',
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            key: const Key('work-orders-filter-strip'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                for (final filter in filterLabels.keys) ...[
                  ChoiceChip(
                    key: Key('work-orders-filter-${filter.toLowerCase()}'),
                    label: Text('${filterLabels[filter]} ${countFor(filter)}'),
                    selected: _filter == filter,
                    onSelected: (_) {
                      widget.session.setWorkspaceOrderFilter(filter);
                      setState(() => _filter = filter);
                    },
                  ),
                  const SizedBox(width: 7),
                ],
              ],
            ),
          ),
          Expanded(
            child: visibleOrders.isNotEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
                    children: [
                      for (final order in visibleOrders) ...[
                        _LiveOrderTicket(
                          session: session,
                          order: order,
                          active:
                              session.hasActiveWorkspaceOrder &&
                              (session.currentWorkspaceOrderId == null ||
                                  order.id == session.currentWorkspaceOrderId),
                          onOpenDelivery: widget.onOpenDelivery,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0xFFE5EAFF),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              color: MoolColors.navy,
                              size: 25,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'Done'
                                ? 'No completed order yet'
                                : 'No ${filterLabels[_filter]!.toLowerCase()} order needs action',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: MoolColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _filter == 'Done'
                                ? 'Completed and cancelled orders are saved here.'
                                : 'A new order will appear here when it needs this action.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: MoolColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('work-orders-create'),
                onPressed: widget.onCreateOrder,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create bill'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveOrderTicket extends StatelessWidget {
  const _LiveOrderTicket({
    required this.session,
    required this.order,
    required this.active,
    required this.onOpenDelivery,
  });

  final WorkSession session;
  final WorkspaceOrderRecord order;
  final bool active;
  final VoidCallback onOpenDelivery;

  @override
  Widget build(BuildContext context) {
    final stage = order.stage;
    final packingLines = active && stage == 'Preparing'
        ? session.workspacePackingLines
        : const <WorkspacePackingLine>[];
    final packedUnits = packingLines
        .where((line) => line.packed)
        .fold<int>(0, (total, line) => total + line.quantity);
    final totalUnits = packingLines.fold<int>(
      0,
      (total, line) => total + line.quantity,
    );
    final nextAction = switch (stage) {
      'Confirmed' => 'Accept',
      'Preparing' => 'Mark ready',
      'Ready' when order.needsDelivery => 'Arrange delivery',
      'Ready' => 'Complete pickup',
      'Delivery requested' => 'Track delivery',
      _ => 'Review',
    };
    return Material(
      key: const Key('work-live-order-ticket'),
      color: Colors.white,
      elevation: 0,
      shadowColor: const Color(0x16001B4D),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: MoolColors.navy,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          stage == 'Confirmed' ? 'Awaiting acceptance' : stage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: MoolColors.navy,
                            fontSize: 10,
                            letterSpacing: .6,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (order.actionDeadline case final deadline?) ...[
                        const SizedBox(width: 8),
                        _LiveCountdownText(
                          deadline: deadline,
                          fallback: 'Review',
                          style: const TextStyle(
                            color: MoolColors.navy,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '₹${_formatStoreAmount(order.amount)}',
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.customer,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${order.source} · ${order.payment} · ${order.fulfilment}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: MoolColors.muted, fontSize: 10.5),
            ),
            const SizedBox(height: 7),
            Text(
              order.items,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (packingLines.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: totalUnits == 0 ? 0 : packedUnits / totalUnits,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$packedUnits/$totalUnits packed',
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              for (final line in packingLines)
                Material(
                  color: const Color(0xFFF4F6FF),
                  borderRadius: BorderRadius.circular(12),
                  child: CheckboxListTile(
                    key: Key('work-order-pack-${line.id}'),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    controlAffinity: ListTileControlAffinity.trailing,
                    value: line.packed,
                    onChanged: (value) =>
                        session.setWorkspacePackingLine(line.id, value == true),
                    title: Text(
                      '${line.label} × ${line.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
            if (active) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed:
                      stage == 'Preparing' && !session.workspacePackingComplete
                      ? null
                      : stage == 'Ready' && order.needsDelivery
                      ? () {
                          session.advanceWorkspaceOrder();
                          onOpenDelivery();
                        }
                      : () => _advanceDeskOrder(
                          session,
                          expectedOrderId: order.id,
                        ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                  label: Text(nextAction),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeliveryDestinationSurface extends StatelessWidget {
  const _DeliveryDestinationSurface({
    required this.session,
    required this.onCreateOrder,
  });

  final WorkSession session;
  final VoidCallback onCreateOrder;

  @override
  Widget build(BuildContext context) {
    final hasConfirmedDelivery =
        session.workspaceOrderCustomer.isNotEmpty &&
        session.workspaceOrderNeedsDelivery;
    if (hasConfirmedDelivery) {
      return Container(
        key: const Key('work-delivery-destination'),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9FAFF), Color(0xFFEFF3FF)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        child: _ActivityDeckShell(
          child: _DeliveryActivityCard(session: session),
        ),
      );
    }
    return Container(
      key: const Key('work-delivery-destination'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9FAFF), Color(0xFFEEF2FF)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MoolColors.navy,
                boxShadow: [
                  BoxShadow(
                    color: MoolColors.navy.withValues(alpha: .22),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Deliver an offline order',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Record a Phone, Counter or Chat order, confirm the customer address and request delivery.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MoolColors.muted, height: 1.35),
            ),
            const SizedBox(height: 22),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DeliverySourceIcon(
                  icon: Icons.phone_in_talk_outlined,
                  label: 'Phone',
                ),
                _DeliverySourceIcon(
                  icon: Icons.storefront_outlined,
                  label: 'Counter',
                ),
                _DeliverySourceIcon(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                ),
                _DeliverySourceIcon(
                  icon: Icons.receipt_long_outlined,
                  label: 'Existing',
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('work-delivery-start-order'),
                onPressed: onCreateOrder,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Record delivery order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliverySourceIcon extends StatelessWidget {
  const _DeliverySourceIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white,
          foregroundColor: MoolColors.navy,
          child: Icon(icon),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: MoolColors.navy,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CustomersDestinationSurface extends StatefulWidget {
  const _CustomersDestinationSurface({
    required this.session,
    required this.onRepeatBasket,
    required this.onOffer,
  });

  final WorkSession session;
  final ValueChanged<String> onRepeatBasket;
  final VoidCallback onOffer;

  @override
  State<_CustomersDestinationSurface> createState() =>
      _CustomersDestinationSurfaceState();
}

class _CustomersDestinationSurfaceState
    extends State<_CustomersDestinationSurface> {
  late final TextEditingController _search = TextEditingController(
    text: widget.session.workspaceCustomerSearch,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _call(WorkspaceCustomerRecord customer) async {
    final digits = customer.mobile.replaceAll(RegExp(r'\D'), '');
    final opened =
        digits.length >= 10 &&
        await launchUrl(Uri(scheme: 'tel', path: digits));
    if (opened) {
      widget.session.markWorkspaceCustomerContacted(customer.id);
    } else {
      widget.session.showError('Calling could not open on this device.');
    }
  }

  Future<void> _whatsApp(WorkspaceCustomerRecord customer) async {
    final digits = customer.mobile.replaceAll(RegExp(r'\D'), '');
    final number = digits.length > 10 ? digits : '91$digits';
    final uri = Uri.https('wa.me', '/$number', {
      'text':
          'Hello ${customer.name}, this is ${widget.session.activeWorkspace?.name ?? widget.session.workName}.',
    });
    final opened =
        digits.length >= 10 &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) {
      widget.session.markWorkspaceCustomerContacted(customer.id);
    } else {
      widget.session.showError(
        'WhatsApp could not open. You can contact this customer through MoolSocial Chat.',
      );
    }
  }

  void _chat(BuildContext context, WorkspaceCustomerRecord customer) {
    widget.session.markWorkspaceCustomerContacted(customer.id);
    context.push(
      Uri(
        path: '/app/chat/inbox',
        queryParameters: {
          'return': GoRouterState.of(context).uri.toString(),
          'type': 'business',
          'recipient': customer.mobile,
          'name': customer.name,
          'draft': 'Customer support for ${customer.name}',
        },
      ).toString(),
    );
  }

  void _invoice(BuildContext context, WorkspaceCustomerRecord customer) {
    final invoice = widget.session.workspaceInvoices
        .where(
          (invoice) =>
              widget.session.workspaceCustomerId(invoice.customer) ==
              customer.id,
        )
        .firstOrNull;
    if (invoice == null) {
      widget.session.showError(
        'No invoice is available for this customer yet.',
      );
      return;
    }
    _showWorkspaceInvoiceSheet(context, widget.session, invoice);
  }

  Future<void> _showCustomer(
    BuildContext context,
    WorkspaceCustomerRecord customer,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE5EAFF),
                    foregroundColor: MoolColors.navy,
                    child: Text(
                      customer.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: MoolColors.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          customer.mobile,
                          style: const TextStyle(color: MoolColors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (customer.amountDue > 0)
                    Text(
                      '₹${customer.amountDue} due',
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _CustomerAction(
                      icon: Icons.call_outlined,
                      label: 'Call',
                      onTap: () => _call(customer),
                    ),
                  ),
                  Expanded(
                    child: _CustomerAction(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chat',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _chat(context, customer);
                      },
                    ),
                  ),
                  Expanded(
                    child: _CustomerAction(
                      icon: Icons.message_outlined,
                      label: 'WhatsApp',
                      onTap: () => _whatsApp(customer),
                    ),
                  ),
                  Expanded(
                    child: _CustomerAction(
                      keyName: 'work-customer-repeat',
                      icon: Icons.repeat_rounded,
                      label: 'Repeat',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onRepeatBasket(customer.id);
                      },
                    ),
                  ),
                  Expanded(
                    child: _CustomerAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'Invoice',
                      onTap: () => _invoice(sheetContext, customer),
                    ),
                  ),
                  Expanded(
                    child: _CustomerAction(
                      icon: Icons.local_offer_outlined,
                      label: customer.messagesAllowed
                          ? 'Send offer'
                          : 'Offer locked',
                      onTap: customer.messagesAllowed
                          ? () {
                              Navigator.pop(sheetContext);
                              widget.onOffer();
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _CustomerMiniFact(
                    label: 'Orders',
                    value: '${customer.orderCount}',
                  ),
                  _CustomerMiniFact(
                    label: 'Spent',
                    value: '₹${_formatStoreAmount(customer.totalSpend)}',
                  ),
                  _CustomerMiniFact(
                    label: 'Average',
                    value: '₹${_formatStoreAmount(customer.averageBasket)}',
                  ),
                ],
              ),
            ),
            if (!customer.messagesAllowed)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 2),
                child: Text(
                  'Order help remains available. Send promotional offers only after the customer allows store messages.',
                  style: TextStyle(color: MoolColors.muted, fontSize: 10),
                ),
              ),
            const Divider(height: 18),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: customer.orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final order = customer.orders[index];
                  return WorkCard(
                    keyName: 'work-customer-order-${order.id}',
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.items,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: MoolColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${order.payment} · ${order.stage} · ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: MoolColors.muted,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${order.amount}',
                          style: const TextStyle(
                            color: MoolColors.navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseCustomPeriod(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange:
          widget.session.workspaceCustomerCustomStart != null &&
              widget.session.workspaceCustomerCustomEnd != null
          ? DateTimeRange(
              start: widget.session.workspaceCustomerCustomStart!,
              end: widget.session.workspaceCustomerCustomEnd!,
            )
          : null,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: 1, maxScaleFactor: 1.2),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      widget.session.setWorkspaceCustomerCustomPeriod(range.start, range.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = widget.session.visibleWorkspaceCustomers;
    final allCustomers = widget.session.workspaceCustomerBook;
    final repeat = allCustomers
        .where((customer) => customer.repeatCustomer)
        .length;
    final due = allCustomers.fold<int>(
      0,
      (total, customer) => total + customer.amountDue,
    );
    return Container(
      key: const Key('work-customers-destination'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF9FAFF), Color(0xFFEEF2FF)],
        ),
      ),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Customers',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _CustomerHeaderFact(
                label: 'Total',
                value: '${allCustomers.length}',
              ),
              _CustomerHeaderFact(label: 'Repeat', value: '$repeat'),
              _CustomerHeaderFact(
                label: 'Due',
                value: '₹${_formatStoreAmount(due)}',
                attention: due > 0,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('work-customer-search'),
            controller: _search,
            onChanged: widget.session.updateWorkspaceCustomerSearch,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search name or mobile',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final filter = const [
                  'Recent',
                  'Repeat',
                  'Payment due',
                  'Following Store',
                  'Messages allowed',
                ][index];
                return ChoiceChip(
                  key: Key(
                    'work-customer-filter-${filter.toLowerCase().replaceAll(' ', '-')}',
                  ),
                  label: Text(filter),
                  selected: widget.session.workspaceCustomerFilter == filter,
                  onSelected: (_) =>
                      widget.session.setWorkspaceCustomerFilter(filter),
                );
              },
            ),
          ),
          const SizedBox(height: 7),
          if (customers.isEmpty)
            const _StoreEmptyPanel(
              icon: Icons.people_outline_rounded,
              title: 'No customers found',
              detail:
                  'Completed counter, phone, Chat and app orders will build your customer book.',
            )
          else
            for (final customer in customers) ...[
              _CustomerBookRow(
                customer: customer,
                onOpen: () => _showCustomer(context, customer),
                onCall: () => _call(customer),
                onChat: () => _chat(context, customer),
              ),
              const SizedBox(height: 6),
            ],
          const SizedBox(height: 6),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(Icons.date_range_outlined, size: 18),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Customer statement',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    key: const Key('work-customer-period'),
                    value: widget.session.workspaceCustomerPeriod,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'Week', child: Text('Week')),
                      DropdownMenuItem(value: 'Month', child: Text('Month')),
                      DropdownMenuItem(
                        value: 'Quarter',
                        child: Text('Quarter'),
                      ),
                      DropdownMenuItem(
                        value: 'Financial year',
                        child: Text('Financial year'),
                      ),
                      DropdownMenuItem(
                        value: 'Custom',
                        child: Text('Custom dates'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == 'Custom') {
                        _chooseCustomPeriod(context);
                      } else if (value != null) {
                        widget.session.setWorkspaceCustomerPeriod(value);
                      }
                    },
                  ),
                  IconButton(
                    key: const Key('work-customer-custom-period'),
                    tooltip: 'Choose custom dates',
                    onPressed: () => _chooseCustomPeriod(context),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerBookRow extends StatelessWidget {
  const _CustomerBookRow({
    required this.customer,
    required this.onOpen,
    required this.onCall,
    required this.onChat,
  });

  final WorkspaceCustomerRecord customer;
  final VoidCallback onOpen;
  final VoidCallback onCall;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final lastContact = customer.lastContactAt;
    return Material(
      key: Key('work-customer-${customer.id}'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 7, 4, 7),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFE5EAFF),
                foregroundColor: MoolColors.navy,
                child: Text(
                  customer.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${customer.mobile} · ${customer.orderCount} orders · ₹${_formatStoreAmount(customer.totalSpend)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      customer.amountDue > 0
                          ? '₹${customer.amountDue} payment due'
                          : lastContact == null
                          ? 'Last purchase ${customer.lastPurchaseAt.day}/${customer.lastPurchaseAt.month}'
                          : 'Contacted ${lastContact.day}/${lastContact.month}',
                      style: TextStyle(
                        color: customer.amountDue > 0
                            ? const Color(0xFFB42318)
                            : const Color(0xFF08765D),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('work-customer-call-${customer.id}'),
                tooltip: 'Call ${customer.name}',
                visualDensity: VisualDensity.compact,
                onPressed: onCall,
                icon: const Icon(Icons.call_outlined, size: 19),
              ),
              IconButton(
                key: Key('work-customer-chat-${customer.id}'),
                tooltip: 'Chat with ${customer.name}',
                visualDensity: VisualDensity.compact,
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerHeaderFact extends StatelessWidget {
  const _CustomerHeaderFact({
    required this.label,
    required this.value,
    this.attention = false,
  });

  final String label;
  final String value;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: TextStyle(
              color: attention ? const Color(0xFFB42318) : MoolColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: MoolColors.muted, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _CustomerMiniFact extends StatelessWidget {
  const _CustomerMiniFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6FF),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: MoolColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: MoolColors.muted, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerAction extends StatelessWidget {
  const _CustomerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.keyName,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: keyName == null ? null : Key(keyName!),
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: onTap == null
                  ? const Color(0xFFF0F1F5)
                  : const Color(0xFFE5EAFF),
              foregroundColor: onTap == null
                  ? MoolColors.muted
                  : MoolColors.navy,
              child: Icon(icon, size: 19),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onTap == null ? MoolColors.muted : MoolColors.navy,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _LegacyCustomersDestinationSurface extends StatelessWidget {
  const _LegacyCustomersDestinationSurface({
    required this.session,
    required this.onRepeatBasket,
  });

  final WorkSession session;
  final VoidCallback onRepeatBasket;

  @override
  Widget build(BuildContext context) {
    final orders = session.filteredWorkspaceCustomerOrders;
    final latestOrder = orders.firstOrNull;
    final customer = latestOrder == null
        ? 'No customer sale yet'
        : latestOrder.customer;
    return Container(
      key: const Key('work-customers-destination'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF9FAFF), Color(0xFFEEF2FF)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          const Text(
            'Customer relationships',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Purchase history, repeat baskets, balances and customer follow-up',
            style: TextStyle(color: MoolColors.muted),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            elevation: 10,
            shadowColor: const Color(0x18001B4D),
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 29,
                        backgroundColor: Color(0xFFE5EAFF),
                        child: Icon(
                          Icons.person_rounded,
                          color: MoolColors.navy,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          customer,
                          maxLines: 2,
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _CustomerFact(
                        label: 'Last purchase',
                        value: latestOrder == null
                            ? '—'
                            : '₹${latestOrder.amount}',
                      ),
                      _CustomerFact(label: 'Orders', value: '${orders.length}'),
                      const _CustomerFact(label: 'Due', value: '₹0'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: latestOrder == null
                              ? null
                              : () => context.push(
                                  Uri(
                                    path: '/app/chat/inbox',
                                    queryParameters: {
                                      'return': GoRouterState.of(
                                        context,
                                      ).uri.toString(),
                                      'type': 'business',
                                      'recipient': latestOrder.customer,
                                      'draft':
                                          'Customer support for ${latestOrder.customer}',
                                    },
                                  ).toString(),
                                ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Chat'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: latestOrder == null
                              ? null
                              : onRepeatBasket,
                          icon: const Icon(Icons.repeat_rounded),
                          label: const Text('Repeat basket'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PeriodStrip(
            selected: session.workspaceCustomerPeriod,
            onSelected: session.setWorkspaceCustomerPeriod,
            onCustom: () async {
              final now = DateTime.now();
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 3),
                lastDate: now,
                initialDateRange:
                    session.workspaceCustomerCustomStart != null &&
                        session.workspaceCustomerCustomEnd != null
                    ? DateTimeRange(
                        start: session.workspaceCustomerCustomStart!,
                        end: session.workspaceCustomerCustomEnd!,
                      )
                    : null,
              );
              if (range != null) {
                session.setWorkspaceCustomerCustomPeriod(
                  range.start,
                  range.end,
                );
              }
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Customer purchase statement',
            style: TextStyle(
              color: MoolColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (orders.isEmpty)
            const WorkCard(
              child: Text(
                'No customer purchase falls within this period.',
                style: TextStyle(color: MoolColors.muted),
              ),
            )
          else
            for (final order in orders) ...[
              WorkCard(
                keyName: 'work-customer-order-${order.id}',
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customer,
                            style: const TextStyle(
                              color: MoolColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${order.items} · ${order.payment} · ${order.stage}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${order.amount}',
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _CustomerFact extends StatelessWidget {
  const _CustomerFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: MoolColors.muted, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

class _PeriodStrip extends StatelessWidget {
  const _PeriodStrip({
    required this.selected,
    required this.onSelected,
    required this.onCustom,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final period in const [
          'Week',
          'Month',
          'Quarter',
          'Financial year',
          'Custom',
        ])
          ChoiceChip(
            label: Text(period),
            selected: selected == period,
            onSelected: (_) =>
                period == 'Custom' ? onCustom() : onSelected(period),
          ),
      ],
    );
  }
}

class _MoneyDestinationSurface extends StatelessWidget {
  const _MoneyDestinationSurface({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final orders = session.filteredWorkspaceMoneyOrders;
    final pendingFulfilment = orders
        .where(
          (order) => order.stage != 'Completed' && order.stage != 'Cancelled',
        )
        .fold<int>(0, (total, order) => total + order.amount);
    final settlementActivity = session.workspaceActivity
        .where(
          (entry) =>
              entry.message.toLowerCase().contains('settlement') ||
              entry.message.toLowerCase().contains('order'),
        )
        .take(5)
        .toList();
    return Container(
      key: const Key('work-money-destination'),
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            'RECORDED SALES BALANCE',
            style: TextStyle(
              color: MoolColors.muted,
              fontSize: 10,
              letterSpacing: .8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '₹${_formatStoreAmount(session.workspaceSettlementEligible)}',
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Flexible(
                child: FilledButton.icon(
                  key: const Key('work-money-request-settlement'),
                  onPressed:
                      session.workspaceSettlementEligible > 0 && !session.busy
                      ? () => _showWorkspaceSettlementReview(context, session)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: MoolColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.account_balance_outlined, size: 18),
                  label: const Text(
                    'Review payout',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MoneyDestinationFact(
                label: 'Sales today',
                value: '₹${_formatStoreAmount(session.workspaceSalesToday)}',
              ),
              _MoneyDestinationFact(
                label: 'Sales awaiting completion',
                value: '₹$pendingFulfilment',
              ),
              _MoneyDestinationFact(
                label: 'Settlement requested',
                value: '₹${session.workspaceSettlementRequested}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Settlement details',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                key: const Key('work-money-period'),
                tooltip: 'Choose statement period',
                onSelected: session.setWorkspaceMoneyPeriod,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'Today', child: Text('Today')),
                  PopupMenuItem(value: 'Week', child: Text('Week')),
                  PopupMenuItem(value: 'Month', child: Text('Month')),
                  PopupMenuItem(
                    value: 'Financial year',
                    child: Text('Financial year'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFDDE3F4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        session.workspaceMoneyPeriod,
                        style: const TextStyle(
                          color: MoolColors.navy,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_more_rounded,
                        color: MoolColors.navy,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FC),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                _MoneyDestinationLine(
                  label: 'Completed-sale balance',
                  value:
                      '₹${_formatStoreAmount(session.workspaceSettlementBalance + session.workspaceSettlementRequested)}',
                ),
                _MoneyDestinationLine(
                  label: 'MoolSocial fees',
                  value:
                      '− ₹${_formatStoreAmount(session.workspacePlatformAdjustments)}',
                ),
                _MoneyDestinationLine(
                  label: 'Delivery adjustments',
                  value:
                      '− ₹${_formatStoreAmount(session.workspaceDeliveryAdjustments)}',
                ),
                _MoneyDestinationLine(
                  label: 'Refunds and holds',
                  value: '− ₹${_formatStoreAmount(session.workspaceRefunds)}',
                ),
                _MoneyDestinationLine(
                  label: 'Tax withheld',
                  value:
                      '− ₹${_formatStoreAmount(session.workspaceTaxWithheld)}',
                ),
                _MoneyDestinationLine(
                  label: 'Balance after adjustments',
                  value:
                      '₹${_formatStoreAmount(session.workspaceSettlementEligible)}',
                ),
              ],
            ),
          ),
          if (session.workspaceSettlementReference case final reference?) ...[
            const SizedBox(height: 14),
            Text(
              'Latest settlement request · $reference',
              style: const TextStyle(color: MoolColors.muted),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Recorded sales',
            style: TextStyle(
              color: MoolColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (orders.isEmpty)
            const Text(
              'No sale falls within this period.',
              style: TextStyle(color: MoolColors.muted),
            )
          else
            for (final order in orders)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Icons.point_of_sale_outlined,
                  color: MoolColors.muted,
                ),
                title: Text(
                  '${order.id} · ₹${order.amount}',
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  '${order.customer} · ${order.payment} · ${order.stage} · ${order.createdAt.day}/${order.createdAt.month}',
                  style: const TextStyle(color: MoolColors.muted),
                ),
              ),
          const SizedBox(height: 18),
          const Text(
            'Settlement activity',
            style: TextStyle(
              color: MoolColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (settlementActivity.isEmpty)
            const Text(
              'Completed sales and settlement requests will appear here.',
              style: TextStyle(color: MoolColors.muted),
            )
          else
            for (final entry in settlementActivity)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Icons.receipt_long_outlined,
                  color: MoolColors.muted,
                ),
                title: Text(
                  entry.message,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${entry.time.day}/${entry.time.month} · ${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: MoolColors.muted),
                ),
              ),
        ],
      ),
    );
  }
}

String _settlementExpectedDateLabel() {
  var date = DateTime.now();
  var workingDays = 0;
  while (workingDays < 2) {
    date = date.add(const Duration(days: 1));
    if (date.weekday != DateTime.saturday && date.weekday != DateTime.sunday) {
      workingDays++;
    }
  }
  return '${date.day}/${date.month}/${date.year}';
}

Future<void> _showWorkspaceSettlementReview(
  BuildContext context,
  WorkSession session,
) async {
  final controller = TextEditingController(
    text: '${session.workspaceSettlementEligible}',
  );
  String? error;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            18,
            0,
            18,
            MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.viewPaddingOf(context).bottom +
                18,
          ),
          child: Column(
            key: const Key('work-settlement-review'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Review settlement request',
                style: TextStyle(
                  color: MoolColors.navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Confirm the amount and payout details before sending.',
                style: TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: 12),
              _MoneyField(
                keyName: 'work-settlement-request-amount',
                controller: controller,
                label: 'Settlement amount',
              ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Color(0xFFB42318))),
              const SizedBox(height: 12),
              WorkCard(
                color: const Color(0xFFF4F6FF),
                child: Column(
                  children: [
                    _ProductPreviewLine(
                      label: 'Receiving account',
                      value: session.workspacePayoutBankName.isEmpty
                          ? 'Bank details required'
                          : '${session.workspacePayoutBankName} · •••• ${session.workspacePayoutAccountEnding}',
                    ),
                    _ProductPreviewLine(
                      label: 'MoolSocial fees',
                      value:
                          '₹${_formatStoreAmount(session.workspacePlatformAdjustments)}',
                    ),
                    _ProductPreviewLine(
                      label: 'Delivery adjustments',
                      value:
                          '₹${_formatStoreAmount(session.workspaceDeliveryAdjustments)}',
                    ),
                    _ProductPreviewLine(
                      label: 'Refunds and holds',
                      value: '₹${_formatStoreAmount(session.workspaceRefunds)}',
                    ),
                    _ProductPreviewLine(
                      label: 'Tax withheld',
                      value:
                          '₹${_formatStoreAmount(session.workspaceTaxWithheld)}',
                    ),
                    _ProductPreviewLine(
                      label: 'Net payout requested',
                      value: '₹${controller.text.trim()}',
                    ),
                    _ProductPreviewLine(
                      label: 'Expected by',
                      value: _settlementExpectedDateLabel(),
                    ),
                  ],
                ),
              ),
              if (session.workspacePayoutBankName.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Add your receiving bank account in Business details before requesting payment.',
                    style: TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('work-settlement-confirm'),
                onPressed:
                    session.busy || session.workspacePayoutBankName.isEmpty
                    ? null
                    : () async {
                        final amount = int.tryParse(controller.text.trim());
                        if (amount == null ||
                            amount <= 0 ||
                            amount > session.workspaceSettlementEligible) {
                          setSheetState(
                            () => error =
                                'Enter an amount up to ₹${session.workspaceSettlementEligible}.',
                          );
                          return;
                        }
                        await session.requestWorkspaceSettlement(
                          amount: amount,
                        );
                        if (sheetContext.mounted &&
                            session.errorMessage == null) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                icon: const Icon(Icons.account_balance_outlined),
                label: const Text('Confirm settlement request'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  unawaited(
    Future<void>.delayed(const Duration(milliseconds: 320), controller.dispose),
  );
}

class _MoneyDestinationFact extends StatelessWidget {
  const _MoneyDestinationFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: MoolColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _MoneyDestinationLine extends StatelessWidget {
  const _MoneyDestinationLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: MoolColors.muted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: MoolColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceDeliverySettingsSurface extends StatefulWidget {
  const _WorkspaceDeliverySettingsSurface({required this.session});

  final WorkSession session;

  @override
  State<_WorkspaceDeliverySettingsSurface> createState() =>
      _WorkspaceDeliverySettingsSurfaceState();
}

class _WorkspaceDeliverySettingsSurfaceState
    extends State<_WorkspaceDeliverySettingsSurface> {
  late final TextEditingController _city = TextEditingController(
    text: widget.session.workspaceDeliveryCity,
  );
  late final TextEditingController _area = TextEditingController(
    text: widget.session.workspaceDeliveryArea,
  );
  late final TextEditingController _pincode = TextEditingController(
    text: widget.session.workspaceDeliveryPincode,
  );
  late bool _pickupEnabled = widget.session.workspacePickupEnabled;
  late final TextEditingController _radius = TextEditingController(
    text: '${widget.session.workspaceDeliveryRadiusKm}',
  );
  late final TextEditingController _fee = TextEditingController(
    text: '${widget.session.workspaceDeliveryFee}',
  );
  late final TextEditingController _freeAbove = TextEditingController(
    text: '${widget.session.workspaceFreeDeliveryAbove}',
  );

  @override
  void dispose() {
    _city.dispose();
    _area.dispose();
    _pincode.dispose();
    _radius.dispose();
    _fee.dispose();
    _freeAbove.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('work-delivery-settings-screen'),
      padding: const EdgeInsets.all(18),
      children: [
        const _WorkspaceSectionLabel(
          title: 'Customer delivery coverage',
          detail: 'Shown before the customer confirms an order',
        ),
        const SizedBox(height: 12),
        _AccessibleWorkTextField(
          keyName: 'work-delivery-city',
          controller: _city,
          label: 'City',
        ),
        const SizedBox(height: 8),
        _ResponsiveFieldPair(
          first: _AccessibleWorkTextField(
            keyName: 'work-delivery-area',
            controller: _area,
            label: 'Area',
          ),
          second: _AccessibleWorkTextField(
            keyName: 'work-delivery-pincode',
            controller: _pincode,
            keyboardType: TextInputType.number,
            label: 'Pincode',
          ),
        ),
        SwitchListTile.adaptive(
          key: const Key('work-delivery-pickup'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Customer pickup available'),
          subtitle: const Text(
            'Customers can collect a packed order in store.',
          ),
          value: _pickupEnabled,
          onChanged: (value) => setState(() => _pickupEnabled = value),
        ),
        _NumberField(
          keyName: 'work-delivery-radius',
          controller: _radius,
          label: 'Delivery radius in kilometres',
        ),
        const SizedBox(height: 10),
        _MoneyField(
          keyName: 'work-delivery-fee',
          controller: _fee,
          label: 'Customer delivery fee',
        ),
        const SizedBox(height: 10),
        _MoneyField(
          keyName: 'work-delivery-free-above',
          controller: _freeAbove,
          label: 'Free delivery above',
        ),
        const SizedBox(height: 10),
        const WorkCard(
          color: Color(0xFFF4F6FF),
          child: Text(
            'Customers see where you deliver, the delivery charge and whether pickup is available before checkout.',
            style: TextStyle(color: MoolColors.ink, height: 1.35),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const Key('work-delivery-settings-save'),
          onPressed: () {
            widget.session.saveWorkspaceDeliverySettings(
              radiusKm: int.tryParse(_radius.text) ?? 0,
              fee: int.tryParse(_fee.text) ?? 0,
              freeAbove: int.tryParse(_freeAbove.text) ?? 0,
              city: _city.text,
              area: _area.text,
              pincode: _pincode.text,
              pickupEnabled: _pickupEnabled,
            );
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Save delivery settings'),
        ),
      ],
    );
  }
}

class _WorkspaceStaffSettingsSurface extends StatefulWidget {
  const _WorkspaceStaffSettingsSurface({required this.session});

  final WorkSession session;

  @override
  State<_WorkspaceStaffSettingsSurface> createState() =>
      _WorkspaceStaffSettingsSurfaceState();
}

class _WorkspaceStaffSettingsSurfaceState
    extends State<_WorkspaceStaffSettingsSurface> {
  late bool _enabled = widget.session.workspaceStaffAccessEnabled;
  late final TextEditingController _counters = TextEditingController(
    text: '${widget.session.workspaceCounterCount}',
  );

  @override
  void dispose() {
    _counters.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('work-staff-settings-screen'),
      padding: const EdgeInsets.all(18),
      children: [
        const _WorkspaceSectionLabel(
          title: 'Staff and counters',
          detail:
              'Give staff access without sharing payments or business documents',
        ),
        const SizedBox(height: 12),
        WorkCard(
          child: SwitchListTile.adaptive(
            key: const Key('work-staff-access-toggle'),
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
            title: const Text('Allow counter staff access'),
            subtitle: const Text(
              'Use this only on Store-managed devices. Payments and business documents remain owner-only.',
            ),
          ),
        ),
        const SizedBox(height: 10),
        _NumberField(
          keyName: 'work-counter-count',
          controller: _counters,
          label: 'Active billing counters',
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const Key('work-staff-settings-save'),
          onPressed: () {
            widget.session.saveWorkspaceStaffSettings(
              staffAccessEnabled: _enabled,
              counterCount: int.tryParse(_counters.text) ?? 1,
            );
          },
          icon: const Icon(Icons.admin_panel_settings_outlined),
          label: const Text('Save staff controls'),
        ),
      ],
    );
  }
}

class _WorkspaceBusinessRecordSurface extends StatelessWidget {
  const _WorkspaceBusinessRecordSurface({
    required this.session,
    required this.onPreview,
  });

  final WorkSession session;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final workspace = session.activeWorkspace;
    return ListView(
      key: const Key('work-business-record-screen'),
      padding: const EdgeInsets.all(18),
      children: [
        WorkCard(
          color: const Color(0xFFEAF7E8),
          child: Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF08765D),
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registered MoolSocial Business Partner',
                      style: TextStyle(
                        color: Color(0xFF08765D),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      workspace?.name ?? session.workName,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(workspace?.profileLabel ?? 'Store'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          key: const Key('work-business-public-preview'),
          onPressed: onPreview,
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('View your customer Store'),
        ),
        const SizedBox(height: 14),
        const _WorkspaceSectionLabel(
          title: 'Business record',
          detail: 'Business details approved for this store',
        ),
        const SizedBox(height: 10),
        WorkCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Operating area'),
                subtitle: Text(workspace?.area ?? session.workArea),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_copy_outlined),
                title: const Text('Documents on record'),
                subtitle: Text(
                  '${session.addedProofs.length} ${session.addedProofs.length == 1 ? 'document' : 'documents'} on file',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('MoolSocial Store plan'),
                subtitle: Text(
                  session.subscriptionPlan == 'free'
                      ? 'Free plan'
                      : session.subscriptionPlan,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Store team'),
                subtitle: Text(
                  session.workspaceStaffAccessEnabled
                      ? '${session.workspaceCounterCount} active counters'
                      : 'Only you have Store access',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('GST compliance'),
                subtitle: Text(
                  session.gstProofReference == null
                      ? 'Add when registration applies under applicable law'
                      : 'GST document on record',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push(
            Uri(
              path: '/app/chat/inbox',
              queryParameters: {
                'return': GoRouterState.of(context).uri.toString(),
                'draft': 'Update business details or documents',
              },
            ).toString(),
          ),
          icon: const Icon(Icons.support_agent_outlined),
          label: const Text('Request a business record update'),
        ),
      ],
    );
  }
}

class _WorkspaceOffersSurface extends StatefulWidget {
  const _WorkspaceOffersSurface({
    required this.session,
    required this.onPromote,
  });

  final WorkSession session;
  final VoidCallback onPromote;

  @override
  State<_WorkspaceOffersSurface> createState() =>
      _WorkspaceOffersSurfaceState();
}

class _WorkspaceOffersSurfaceState extends State<_WorkspaceOffersSurface> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _detail = TextEditingController();
  final TextEditingController _orderCap = TextEditingController(text: '50');
  String? _productId;
  DateTime? _validUntil;

  void _useTemplate(String template) {
    final copy = switch (template) {
      'Monthly essentials' => (
        'Save on your monthly essentials',
        'Buy selected monthly essentials before the offer ends.',
      ),
      'Back in stock' => (
        'Your requested product is back',
        'Order while fresh stock is available at the Store.',
      ),
      'Festival saving' => (
        'Festival savings at your Store',
        'Save on selected products during the festival offer period.',
      ),
      _ => (
        'Repeat your recent basket',
        'Reorder your recent basket while the selected products are available.',
      ),
    };
    setState(() {
      _title.text = copy.$1;
      _detail.text = copy.$2;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    _orderCap.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _validUntil ?? now.add(const Duration(days: 7)),
    );
    if (selected != null) setState(() => _validUntil = selected);
  }

  @override
  Widget build(BuildContext context) {
    final eligibleCustomers = widget.session.workspaceCustomerBook
        .where((customer) => customer.messagesAllowed)
        .length;
    final products = widget.session.workspaceCatalogueItems
        .where((product) => product.published)
        .toList(growable: false);
    final selectedProduct = products
        .where((product) => product.id == _productId)
        .firstOrNull;
    final cap = int.tryParse(_orderCap.text.trim()) ?? 0;
    return ListView(
      key: const Key('work-store-offers-screen'),
      padding: const EdgeInsets.all(18),
      children: [
        const _WorkspaceSectionLabel(
          title: 'Bring customers back',
          detail:
              'Choose a useful offer for customers who allow Store messages',
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final template = const [
                'Monthly essentials',
                'Back in stock',
                'Festival saving',
                'Repeat your basket',
              ][index];
              return ActionChip(
                label: Text(template),
                onPressed: () => _useTemplate(template),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const Key('work-offer-product'),
          isExpanded: true,
          initialValue: _productId,
          decoration: const InputDecoration(
            labelText: 'Product customers can buy',
          ),
          items: products
              .map(
                (product) => DropdownMenuItem(
                  value: product.id,
                  child: Text(
                    '${product.title} · ${product.pack}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => _productId = value),
        ),
        const SizedBox(height: 8),
        _AccessibleWorkTextField(
          keyName: 'work-offer-title',
          controller: _title,
          onChanged: (_) => setState(() {}),
          label: 'Offer headline',
        ),
        const SizedBox(height: 8),
        _AccessibleWorkTextField(
          keyName: 'work-offer-detail',
          controller: _detail,
          onChanged: (_) => setState(() {}),
          maxLines: 2,
          label: 'Customer saving and terms',
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('work-offer-valid-until'),
          onPressed: _pickDate,
          icon: const Icon(Icons.event_outlined),
          label: Text(
            _validUntil == null
                ? 'Choose offer end date'
                : 'Valid until ${_validUntil!.day}/${_validUntil!.month}/${_validUntil!.year}',
          ),
        ),
        const SizedBox(height: 8),
        _NumberField(
          keyName: 'work-offer-order-cap',
          controller: _orderCap,
          label: 'Maximum customer orders for this offer',
        ),
        const SizedBox(height: 8),
        Container(
          key: const Key('work-offer-preview'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title.text.trim().isEmpty
                    ? 'Your offer preview'
                    : _title.text.trim(),
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                selectedProduct == null
                    ? 'Choose an available product.'
                    : '${selectedProduct.title} · ${selectedProduct.pack} · ₹${selectedProduct.sellingPrice}',
                style: const TextStyle(color: MoolColors.muted, fontSize: 10),
              ),
              Text(
                eligibleCustomers == 0
                    ? 'No customer has allowed Store offers yet.'
                    : '$eligibleCustomers customers can receive this offer · first $cap orders',
                style: TextStyle(
                  color: eligibleCustomers == 0
                      ? const Color(0xFFB42318)
                      : const Color(0xFF08765D),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const Key('work-offer-publish'),
          onPressed:
              _title.text.trim().isEmpty ||
                  _detail.text.trim().isEmpty ||
                  _validUntil == null ||
                  selectedProduct == null ||
                  eligibleCustomers == 0 ||
                  cap <= 0
              ? null
              : () {
                  widget.session.addWorkspaceOffer(
                    title: _title.text,
                    detail: _detail.text,
                    validUntil: _validUntil!,
                    productId: selectedProduct.id,
                    orderCap: cap,
                  );
                  setState(() {});
                },
          icon: const Icon(Icons.local_offer_outlined),
          label: const Text('Publish Store offer'),
        ),
        if (widget.session.workspaceOffers.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'Active offers',
            style: TextStyle(
              color: MoolColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          for (final offer in widget.session.workspaceOffers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sell_outlined),
              title: Text(offer.title),
              subtitle: Text(offer.detail),
              trailing: Text(
                '${offer.validUntil.day}/${offer.validUntil.month}',
              ),
            ),
          OutlinedButton.icon(
            onPressed: widget.onPromote,
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('Promote this Store offer'),
          ),
        ],
      ],
    );
  }
}

const _storeRequirementServices = <(String, IconData)>[
  ('Product sourcing', Icons.manage_search_rounded),
  ('Stock supply', Icons.inventory_2_outlined),
  ('Business partner', Icons.handshake_outlined),
  ('Investment partner', Icons.account_balance_outlined),
  ('Content management', Icons.edit_note_rounded),
  ('Social media', Icons.forum_outlined),
  ('Store promotion', Icons.campaign_outlined),
  ('Offer management', Icons.local_offer_outlined),
  ('Basket marketing', Icons.shopping_basket_outlined),
  ('Sales growth', Icons.trending_up_rounded),
];

Future<String?> _chooseStoreRequirement(
  BuildContext context, {
  String? selected,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.white,
  barrierColor: Colors.black.withValues(alpha: .16),
  showDragHandle: false,
  constraints: const BoxConstraints(maxWidth: 560),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  clipBehavior: Clip.antiAlias,
  sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: Duration(milliseconds: 220),
          reverseDuration: Duration(milliseconds: 160),
        ),
  builder: (sheetContext) {
    final columns =
        MediaQuery.sizeOf(sheetContext).width < 390 &&
            MediaQuery.textScalerOf(sheetContext).scale(13) > 16
        ? 1
        : 2;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * .7,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          key: const Key('work-requirement-selector'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Post requirement',
                      style: TextStyle(
                        color: MoolColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('work-requirement-selector-close'),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (
                      var row = 0;
                      row < _storeRequirementServices.length ~/ columns;
                      row++
                    ) ...[
                      if (row != 0)
                        const Divider(height: 1, color: Color(0xFFE9EDF5)),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (
                              var column = 0;
                              column < columns;
                              column++
                            ) ...[
                              if (column != 0)
                                const VerticalDivider(
                                  width: 1,
                                  color: Color(0xFFE9EDF5),
                                ),
                              Expanded(
                                child: _StoreRequirementChoice(
                                  index: row * columns + column,
                                  selected: selected,
                                  onSelected: (value) =>
                                      Navigator.pop(sheetContext, value),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
);

class _StoreRequirementChoice extends StatelessWidget {
  const _StoreRequirementChoice({
    required this.index,
    required this.selected,
    required this.onSelected,
  });
  final int index;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = _storeRequirementServices[index];
    final isSelected = selected == label;
    return Semantics(
      selected: isSelected,
      child: Material(
        color: isSelected ? const Color(0xFFF0F3FF) : Colors.white,
        child: InkWell(
          key: Key('work-requirement-category-$index'),
          onTap: () => onSelected(label),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: MoolColors.navy),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
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

class _WorkspacePaidWorkSurface extends StatefulWidget {
  const _WorkspacePaidWorkSurface({required this.session, required this.draft});
  final WorkSession session;
  final Map<String, String> draft;

  @override
  State<_WorkspacePaidWorkSurface> createState() =>
      _WorkspacePaidWorkSurfaceState();
}

class _WorkspacePaidWorkSurfaceState extends State<_WorkspacePaidWorkSurface> {
  final _title = TextEditingController();
  final _outcome = TextEditingController();
  final _terms = TextEditingController();
  final _budget = TextEditingController();
  late final _location = TextEditingController(
    text: widget.session.activeWorkspace?.area ?? widget.session.workArea,
  );
  String? _service;
  DateTime? _deadline;
  bool _reviewing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _service = draft['service'];
    _title.text = draft['title'] ?? '';
    _outcome.text = draft['outcome'] ?? '';
    _terms.text = draft['terms'] ?? '';
    _budget.text = draft['budget'] ?? '';
    _location.text = draft['location'] ?? _location.text;
    _deadline = DateTime.tryParse(draft['deadline'] ?? '');
    for (final controller in [_title, _outcome, _terms, _budget, _location]) {
      controller.addListener(_retainDraft);
    }
  }

  void _retainDraft() {
    widget.draft
      ..['title'] = _title.text
      ..['outcome'] = _outcome.text
      ..['terms'] = _terms.text
      ..['budget'] = _budget.text
      ..['location'] = _location.text;
    if (_service == null) {
      widget.draft.remove('service');
    } else {
      widget.draft['service'] = _service!;
    }
    if (_deadline != null) {
      widget.draft['deadline'] = _deadline!.toIso8601String();
    }
  }

  bool get _partnership =>
      _service == 'Business partner' || _service == 'Investment partner';
  bool get _supply =>
      _service == 'Product sourcing' || _service == 'Stock supply';
  String get _deadlineLabel => _deadline == null
      ? 'Choose deadline'
      : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}';

  @override
  void dispose() {
    for (final controller in [_title, _outcome, _terms, _budget, _location]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
    );
    if (mounted && selected != null) {
      setState(() => _deadline = selected);
      _retainDraft();
    }
  }

  void _review() {
    final budget = num.tryParse(_budget.text.trim());
    final error = _title.text.trim().isEmpty
        ? 'Describe what your store needs.'
        : _outcome.text.trim().isEmpty
        ? 'Describe the result you expect.'
        : _location.text.trim().isEmpty
        ? 'Enter the required location.'
        : _budget.text.trim().isNotEmpty && (budget == null || budget <= 0)
        ? 'Enter a valid budget or leave it blank to discuss.'
        : null;
    setState(() {
      _error = error;
      _reviewing = error == null;
    });
    if (error == null) FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) => Material(
    key: const Key('work-paid-requirement-screen'),
    color: Colors.white,
    child: AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      child: _service == null
          ? _selector()
          : _reviewing
          ? _reviewSurface()
          : _details(),
    ),
  );

  Future<void> _changeService() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await _chooseStoreRequirement(context, selected: _service);
    if (!mounted || selected == null) return;
    setState(() {
      _service = selected;
      _error = null;
    });
    _retainDraft();
  }

  Widget _selector() => Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: _changeService,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Choose service'),
      ),
    ),
  );

  Widget _details() => LayoutBuilder(
    builder: (context, constraints) {
      final compactHeight = constraints.maxHeight < 320;
      final theme = Theme.of(context);
      Widget reviewAction() => FilledButton(
        key: const Key('work-requirement-review'),
        onPressed: _review,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
        child: const Text('Review requirement', textAlign: TextAlign.center),
      );
      return Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.copyWith(
            titleMedium: const TextStyle(
              fontSize: 15,
              height: 1.3,
              color: MoolColors.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: false,
            isDense: true,
            labelStyle: TextStyle(color: MoolColors.muted, fontSize: 13),
            floatingLabelStyle: TextStyle(color: MoolColors.navy, fontSize: 13),
            contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 0),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFDCE2F1)),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFDCE2F1)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: MoolColors.navy, width: 1.5),
            ),
          ),
        ),
        child: Column(
          key: const Key('work-requirement-details'),
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Post requirement',
                            style: TextStyle(
                              color: MoolColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Not posted',
                          style: TextStyle(
                            color: MoolColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const Key('work-requirement-change'),
                        onPressed: _changeService,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _service!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: MoolColors.navy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.expand_more_rounded, size: 22),
                          ],
                        ),
                      ),
                    ),
                    _AccessibleWorkTextField(
                      keyName: 'work-requirement-title',
                      controller: _title,
                      label: _supply
                          ? 'Products, packs and quantity'
                          : 'What do you need?',
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 8),
                    _AccessibleWorkTextField(
                      keyName: 'work-requirement-outcome',
                      controller: _outcome,
                      label: 'Expected result',
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 8),
                    _AccessibleWorkTextField(
                      keyName: 'work-requirement-location',
                      controller: _location,
                      label: 'Location',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 8),
                    _AccessibleWorkTextField(
                      keyName: 'work-requirement-terms',
                      controller: _terms,
                      label: _partnership
                          ? 'Proposed partnership terms'
                          : 'Completion and payment terms',
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 8),
                    _MoneyField(
                      keyName: 'work-requirement-budget',
                      controller: _budget,
                      label: _partnership
                          ? 'Proposed amount (optional)'
                          : 'Budget (optional)',
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const Key('work-requirement-deadline'),
                        onPressed: _pickDeadline,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.event_outlined, size: 20),
                        label: Text(_deadlineLabel),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _pricing(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFB42318)),
                        ),
                      ),
                    if (compactHeight) ...[
                      const SizedBox(height: 12),
                      reviewAction(),
                    ],
                  ],
                ),
              ),
            ),
            if (!compactHeight)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE9EDF5))),
                ),
                child: reviewAction(),
              ),
          ],
        ),
      );
    },
  );

  Widget _pricing() => Container(
    key: const Key('work-requirement-pricing'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E8F1)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MoolSocial fee',
          style: TextStyle(
            color: MoolColors.navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Service pricing is not available yet. Your plan benefits and any amount due must be confirmed before posting.',
          style: TextStyle(color: MoolColors.muted, fontSize: 12, height: 1.4),
        ),
      ],
    ),
  );

  Widget _reviewSurface() => ListView(
    key: const Key('work-requirement-review-surface'),
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'Your requirement',
        style: TextStyle(
          color: MoolColors.navy,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 16),
      for (final fact in [
        ('Service', _service!),
        ('Requirement', _title.text.trim()),
        ('Expected result', _outcome.text.trim()),
        ('Location', _location.text.trim()),
        (
          'Terms',
          _terms.text.trim().isEmpty ? 'To be discussed' : _terms.text.trim(),
        ),
        (
          'Budget',
          _budget.text.trim().isEmpty
              ? 'To be discussed'
              : '₹${_budget.text.trim()}',
        ),
        if (_deadline != null) ('Deadline', _deadlineLabel),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ProductPreviewLine(label: fact.$1, value: fact.$2),
        ),
      const Divider(height: 24),
      _pricing(),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const Key('work-requirement-edit'),
        onPressed: () => setState(() => _reviewing = false),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Edit requirement'),
      ),
      const SizedBox(height: 8),
      const Text(
        'Not posted. No payment has been taken.',
        style: TextStyle(color: MoolColors.muted, fontSize: 12),
      ),
    ],
  );
}

class _ResponsiveFieldPair extends StatelessWidget {
  const _ResponsiveFieldPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.2;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (largeText || constraints.maxWidth < 390) {
          return Column(children: [first, const SizedBox(height: 8), second]);
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 8),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _GrowDestinationSurfaceV2 extends StatelessWidget {
  const _GrowDestinationSurfaceV2({
    required this.session,
    required this.onCustomers,
    required this.onOffers,
    required this.onPromote,
    required this.onPaidWork,
    required this.onServices,
  });

  final WorkSession session;
  final VoidCallback onCustomers;
  final VoidCallback onOffers;
  final VoidCallback onPromote;
  final VoidCallback onPaidWork;
  final VoidCallback onServices;

  @override
  Widget build(BuildContext context) {
    final repeatCustomers = session.workspaceCustomerBook
        .where((customer) => customer.repeatCustomer)
        .length;
    final activeOffers = session.workspaceOffers
        .where(
          (offer) => offer.active && offer.validUntil.isAfter(DateTime.now()),
        )
        .length;
    final paidWorkOpen = session.workspacePaidRequirementReference == null
        ? 0
        : 1;
    return Container(
      key: const Key('work-grow-destination'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF9FAFF), Color(0xFFE9EEFF)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
        children: [
          const Text(
            'Grow repeat business',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Bring customers back with offers, useful reminders and your Store presence.',
            style: TextStyle(color: MoolColors.muted, fontSize: 10.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _GrowthMetric(value: '$repeatCustomers', label: 'Repeat'),
              _GrowthMetric(value: '$activeOffers', label: 'Offers live'),
              _GrowthMetric(value: '$paidWorkOpen', label: 'Requirements'),
              _GrowthMetric(
                value: session.workspaceVisibleToCustomers
                    ? 'Public'
                    : 'Private',
                label: 'Store reach',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _StoreActionRow(
                  keyName: 'work-growth-customers',
                  icon: Icons.repeat_rounded,
                  eyebrow: 'REPEAT BUSINESS',
                  title: 'Bring customers back',
                  detail:
                      '$repeatCustomers repeat customers · purchase history and repeat baskets',
                  actionLabel: 'Customers',
                  onPressed: onCustomers,
                ),
                const Divider(height: 1),
                _StoreActionRow(
                  keyName: 'work-growth-offers',
                  icon: Icons.local_offer_outlined,
                  eyebrow: 'CUSTOMER OFFERS',
                  title: 'Create a Store offer',
                  detail:
                      '$activeOffers active · choose products and customers who allow offers',
                  actionLabel: 'Create',
                  onPressed: onOffers,
                ),
                const Divider(height: 1),
                _StoreActionRow(
                  keyName: 'work-growth-social',
                  icon: Icons.campaign_outlined,
                  eyebrow: 'STORE REACH',
                  title: 'Promote your Store',
                  detail:
                      'Create a Social post with your Store identity and return here.',
                  actionLabel: 'Promote',
                  onPressed: onPromote,
                ),
                const Divider(height: 1),
                _StoreActionRow(
                  keyName: 'work-growth-paid-work',
                  icon: Icons.work_outline_rounded,
                  eyebrow: 'FUNDED LOCAL WORK',
                  title: 'Post requirement',
                  detail: paidWorkOpen == 0
                      ? 'Create a funded requirement for delivery, sales or Store support.'
                      : '1 funded Store requirement is published.',
                  actionLabel: paidWorkOpen == 0 ? 'Prepare' : 'View',
                  onPressed: onPaidWork,
                ),
                const Divider(height: 1),
                _StoreActionRow(
                  keyName: 'work-growth-services',
                  icon: Icons.business_center_outlined,
                  eyebrow: 'BUSINESS SUPPORT',
                  title: 'GST, books and audit support',
                  detail:
                      'Request scoped professional help without leaving Store operations.',
                  actionLabel: 'View',
                  onPressed: onServices,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthMetric extends StatelessWidget {
  const _GrowthMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(color: MoolColors.muted, fontSize: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _GrowDestinationSurface extends StatelessWidget {
  const _GrowDestinationSurface({
    required this.onCustomers,
    required this.onOffers,
    required this.onPromote,
    required this.onPaidWork,
    required this.onServices,
  });

  final VoidCallback onCustomers;
  final VoidCallback onOffers;
  final VoidCallback onPromote;
  final VoidCallback onPaidWork;
  final VoidCallback onServices;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-grow-destination'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9FAFF), Color(0xFFE9EEFF)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF000080), Color(0xFF4856D9)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: MoolColors.navy.withValues(alpha: .2),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Grow your store',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Choose the business outcome you want to improve.',
            textAlign: TextAlign.center,
            style: TextStyle(color: MoolColors.muted),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 22,
            children: [
              _GrowActionOrb(
                icon: Icons.repeat_rounded,
                label: 'Repeat customers',
                onTap: onCustomers,
              ),
              _GrowActionOrb(
                icon: Icons.local_offer_outlined,
                label: 'Offers',
                onTap: onOffers,
              ),
              _GrowActionOrb(
                icon: Icons.campaign_outlined,
                label: 'Promote store',
                onTap: onPromote,
              ),
              _GrowActionOrb(
                icon: Icons.work_outline_rounded,
                label: 'Post requirement',
                onTap: onPaidWork,
              ),
              _GrowActionOrb(
                icon: Icons.business_center_outlined,
                label: 'Business support',
                onTap: onServices,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrowActionOrb extends StatelessWidget {
  const _GrowActionOrb({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: SizedBox(
        width: 105,
        child: Column(
          children: [
            Material(
              color: Colors.white,
              elevation: 8,
              shadowColor: const Color(0x1A001B4D),
              shape: const CircleBorder(),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Icon(icon, color: MoolColors.navy, size: 31),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceOrdersSurface extends StatefulWidget {
  const _WorkspaceOrdersSurface({
    required this.session,
    required this.onCreateOrder,
    required this.onOpenDelivery,
  });

  final WorkSession session;
  final VoidCallback onCreateOrder;
  final VoidCallback onOpenDelivery;

  @override
  State<_WorkspaceOrdersSurface> createState() =>
      _WorkspaceOrdersSurfaceState();
}

class _WorkspaceOrdersSurfaceState extends State<_WorkspaceOrdersSurface> {
  String _selected = 'New';

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final stageGroup = switch (session.workspaceOrderStage) {
      'Confirmed' => 'New',
      'Preparing' => 'Preparing',
      'Ready' || 'Delivery requested' => 'Ready',
      'Completed' || 'Cancelled' => 'Completed',
      _ => 'New',
    };
    final showOrder =
        session.workspaceOrderCustomer.isNotEmpty && stageGroup == _selected;
    return Column(
      key: const Key('work-dashboard-orders-screen'),
      children: [
        _OrderStatusRail(
          selected: _selected,
          onSelected: (value) => setState(() => _selected = value),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              if (!showOrder)
                _OperationActionCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'No $_selected order',
                  detail: _selected == 'New'
                      ? 'New app orders will appear here. You can also record a counter, phone or Chat order now.'
                      : 'Orders move here automatically after the previous action is completed.',
                  actionLabel: _selected == 'New'
                      ? 'Create customer order'
                      : null,
                  onPressed: _selected == 'New' ? widget.onCreateOrder : null,
                )
              else
                _LiveWorkspaceOrderCard(
                  session: session,
                  onCreateOrder: () {
                    session.startNewWorkspaceOrder();
                    widget.onCreateOrder();
                  },
                  onOpenDelivery: widget.onOpenDelivery,
                ),
              const SizedBox(height: MoolSpacing.sm),
              const _WorkspaceSectionLabel(
                title: 'Order flow',
                detail: 'Every action remains attached to the order',
              ),
              const SizedBox(height: MoolSpacing.xs),
              const _OperationActionCard(
                icon: Icons.verified_user_outlined,
                title: 'Customer, payment, stock and delivery stay together',
                detail:
                    'The next required action appears on the order without an intermediate menu.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderStatusRail extends StatelessWidget {
  const _OrderStatusRail({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-orders-context-rail'),
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE2F2))),
      ),
      child: Row(
        children: [
          for (final label in const ['New', 'Preparing', 'Ready', 'Completed'])
            _StoreContextButton(
              label: label,
              selected: selected == label,
              onPressed: selected == label ? null : () => onSelected(label),
            ),
        ],
      ),
    );
  }
}

class _LiveWorkspaceOrderCard extends StatelessWidget {
  const _LiveWorkspaceOrderCard({
    required this.session,
    required this.onCreateOrder,
    required this.onOpenDelivery,
  });

  final WorkSession session;
  final VoidCallback onCreateOrder;
  final VoidCallback onOpenDelivery;

  @override
  Widget build(BuildContext context) {
    final stage = session.workspaceOrderStage;
    final primaryLabel = switch (stage) {
      'Confirmed' => 'Start preparing',
      'Preparing' => 'Mark order ready',
      'Ready' when session.workspaceOrderNeedsDelivery => 'Arrange delivery',
      'Ready for pickup' => 'Complete pickup and create invoice',
      'Delivery requested' => 'Mark delivered',
      _ => null,
    };
    return WorkCard(
      keyName: 'work-live-order',
      color: const Color(0xFFF7F8FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E8FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  stage.toUpperCase(),
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '₹${session.workspaceOrderAmount}',
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            '${session.workspaceOrderSource} · ${session.workspaceOrderCustomer}',
            style: const TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            session.workspaceOrderItems,
            style: const TextStyle(color: MoolColors.muted, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            '${session.workspaceOrderPayment} · ${session.workspaceOrderFulfilment}${session.workspaceOrderExtraMinutes == 0 ? '' : ' · +${session.workspaceOrderExtraMinutes} min'}',
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (session.workspaceOrderAddress.isNotEmpty)
            Text(
              session.workspaceOrderAddress,
              style: const TextStyle(color: MoolColors.muted, fontSize: 10),
            ),
          const SizedBox(height: MoolSpacing.sm),
          if (primaryLabel != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('work-order-primary-action'),
                onPressed:
                    stage == 'Ready' && session.workspaceOrderNeedsDelivery
                    ? onOpenDelivery
                    : session.advanceWorkspaceOrder,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(primaryLabel),
              ),
            ),
          Row(
            children: [
              TextButton(
                key: const Key('work-order-new'),
                onPressed: onCreateOrder,
                child: const Text('New order'),
              ),
              const Spacer(),
              if (session.hasActiveWorkspaceOrder)
                PopupMenuButton<String>(
                  key: const Key('work-order-more'),
                  tooltip: 'More order actions',
                  onSelected: (value) {
                    if (value == 'cancel') {
                      session.cancelWorkspaceOrder();
                    } else {
                      session.extendWorkspaceOrder(int.parse(value));
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: '10', child: Text('Add 10 minutes')),
                    PopupMenuItem(value: '20', child: Text('Add 20 minutes')),
                    PopupMenuItem(value: 'cancel', child: Text('Cancel order')),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _WorkspaceDeliverySurface extends StatelessWidget {
  const _WorkspaceDeliverySurface({
    required this.session,
    required this.onCreateOrder,
  });

  final WorkSession session;
  final VoidCallback onCreateOrder;

  @override
  Widget build(BuildContext context) {
    final hasDelivery =
        session.workspaceOrderCustomer.isNotEmpty &&
        session.workspaceOrderNeedsDelivery;
    return ListView(
      key: const Key('work-dashboard-delivery-screen'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      children: [
        if (!hasDelivery)
          _OperationActionCard(
            icon: Icons.delivery_dining_outlined,
            title: 'No order is waiting for delivery',
            detail:
                'Record a phone, counter or Chat order and choose a delivery option.',
            actionLabel: 'Create delivery order',
            onPressed: onCreateOrder,
          )
        else
          WorkCard(
            keyName: 'work-live-delivery',
            color: const Color(0xFFEAF7F3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.workspaceOrderStage.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF08765D),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${session.workspaceOrderCustomer} · ₹${session.workspaceOrderAmount}',
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  session.workspaceOrderAddress,
                  style: const TextStyle(color: MoolColors.muted),
                ),
                const SizedBox(height: MoolSpacing.xs),
                if (session.workspaceOrderStage != 'Delivery requested' &&
                    session.workspaceOrderStage != 'Completed')
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('work-delivery-request'),
                      onPressed: session.advanceWorkspaceOrder,
                      icon: const Icon(Icons.delivery_dining_rounded),
                      label: Text(
                        session.workspaceOrderStage == 'Ready'
                            ? 'Request delivery partner'
                            : 'Mark order ready',
                      ),
                    ),
                  )
                else if (session.workspaceOrderStage == 'Delivery requested')
                  const Text(
                    'Finding an available delivery partner. Rider identity and route will appear only after confirmation.',
                    style: TextStyle(
                      color: MoolColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: MoolSpacing.xs),
        const _OperationActionCard(
          icon: Icons.route_outlined,
          title: 'Live delivery journey',
          detail:
              'Confirmed rider, pickup, route and customer handoff updates appear here without invented status.',
        ),
      ],
    );
  }
}

class _CounterOrderSurface extends StatefulWidget {
  const _CounterOrderSurface({
    required this.session,
    required this.query,
    required this.onArrangeDelivery,
    required this.onOpenCatalogue,
    super.key,
  });

  final WorkSession session;
  final String query;
  final VoidCallback onArrangeDelivery;
  final VoidCallback onOpenCatalogue;

  @override
  State<_CounterOrderSurface> createState() => _CounterOrderSurfaceState();
}

class _CounterOrderSurfaceState extends State<_CounterOrderSurface> {
  late final TextEditingController _customer = TextEditingController(
    text: widget.session.workspaceOrderCustomer,
  );
  late final TextEditingController _address = TextEditingController(
    text: widget.session.workspaceOrderAddress,
  );
  late String _source = widget.session.workspaceOrderSource;
  late String _fulfilment = widget.session.workspaceOrderFulfilment;
  late String _payment = widget.session.workspaceOrderPayment;
  String? _error;

  @override
  void dispose() {
    _customer.dispose();
    _address.dispose();
    super.dispose();
  }

  List<String> get _recentCustomers {
    final seen = <String>{};
    return widget.session.visibleWorkspaceOrders
        .map((order) => order.customer.trim())
        .where((customer) => customer.isNotEmpty && seen.add(customer))
        .take(4)
        .toList(growable: false);
  }

  int get _selectedUnits => widget.session.workspaceOrderQuantities.values
      .fold<int>(0, (total, quantity) => total + quantity);

  String get _draftItems => widget.session.workspaceCatalogueItems
      .where(
        (product) =>
            (widget.session.workspaceOrderQuantities[product.id] ?? 0) > 0,
      )
      .map(
        (product) =>
            '${product.title} × ${widget.session.workspaceOrderQuantities[product.id]}',
      )
      .join(' · ');

  String _fulfilmentLabel(String value) => switch (value) {
    'At the shop' => 'Take now',
    'Own delivery' => 'My delivery',
    'Mool delivery' => 'Mool delivery',
    _ => value,
  };

  void _save() {
    final phone = _customer.text.replaceAll(RegExp(r'\D'), '');
    final error = phone.length < 10
        ? 'Enter the customer’s 10-digit mobile number.'
        : widget.session.workspaceOrderItemCount == 0
        ? 'Add at least one product from your store catalogue.'
        : _fulfilment != 'At the shop' && _address.text.trim().isEmpty
        ? 'Add the confirmed customer delivery address.'
        : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    widget.session.saveWorkspaceOrderDraft(
      customer: _customer.text,
      source: _source,
      fulfilment: _fulfilment,
      payment: _payment,
      address: _address.text,
    );
    setState(() => _error = null);
    FocusManager.instance.primaryFocus?.unfocus();
    if (_fulfilment == 'At the shop') {
      final invoice = widget.session.completeWorkspaceCounterSale();
      if (invoice != null) {
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 240), () {
            if (mounted) {
              _showWorkspaceInvoiceSheet(context, widget.session, invoice);
            }
          }),
        );
      }
    } else {
      widget.session.showNotice(
        _source == 'Phone'
            ? 'Delivery order saved. Confirm the order with the customer before dispatch.'
            : 'Delivery order saved. Pack the items before requesting a rider.',
      );
      widget.onArrangeDelivery();
    }
  }

  Future<void> _review() async {
    final systemBottom = MediaQuery.viewPaddingOf(context).bottom;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final media = MediaQuery.of(context);
          return SafeArea(
            top: false,
            minimum: EdgeInsets.only(bottom: systemBottom),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
              child: SizedBox(
                height: media.size.height * .72,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Review customer order',
                              style: TextStyle(
                                color: MoolColors.ink,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _OrderReviewSummary(
                              customer: _customer.text.trim(),
                              source: _source,
                              items: _draftItems,
                              units: _selectedUnits,
                              amount: widget.session.workspaceOrderTotal,
                            ),
                            const SizedBox(height: 14),
                            _OrderCompletionChoices(
                              fulfilment: _fulfilment,
                              payment: _payment,
                              addressController: _address,
                              onFulfilmentChanged: (value) {
                                setState(() => _fulfilment = value);
                                setSheetState(() {});
                              },
                              onPaymentChanged: (value) {
                                setState(() => _payment = value);
                                setSheetState(() {});
                              },
                            ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Color(0xFFB42318),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E7F4)),
                        ),
                      ),
                      child: FilledButton.icon(
                        key: const Key('work-order-save'),
                        onPressed: () {
                          if (_fulfilment != 'At the shop' &&
                              _address.text.trim().isEmpty) {
                            setSheetState(
                              () => _error = 'Add the delivery address.',
                            );
                            return;
                          }
                          Navigator.of(context).pop();
                          _save();
                        },
                        icon: Icon(
                          _fulfilment == 'At the shop'
                              ? Icons.check_circle_outline_rounded
                              : Icons.delivery_dining_rounded,
                        ),
                        label: Text(
                          _fulfilment == 'At the shop'
                              ? 'Complete sale & create invoice'
                              : _fulfilment == 'Mool delivery'
                              ? 'Create order for Mool delivery'
                              : 'Create order for my delivery',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _scanProduct() async {
    final code = await showBuyV2ProductScanner(context);
    if (!mounted || code == null || code.trim().isEmpty) return;
    final normalized = code.trim().toLowerCase();
    final product = widget.session.workspaceCatalogueItems
        .where(
          (item) =>
              item.barcode.toLowerCase() == normalized ||
              item.sku.toLowerCase() == normalized ||
              item.canonicalId.toLowerCase() == normalized,
        )
        .firstOrNull;
    if (product == null) {
      widget.session.showError(
        'This product is not in your Store catalogue. Add it from Stock first.',
      );
      return;
    }
    widget.session.adjustWorkspaceOrderQuantity(product.id, 1);
  }

  Future<void> _editCustomer() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.white,
      builder: (_) => _StoreSaleCustomerSheet(
        initialValue: _customer.text,
        recentCustomers: _recentCustomers,
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _customer.text = selected;
      _error = null;
    });
    // Draft identity only; no order, invoice or payment is created here.
    widget.session.workspaceOrderCustomer = selected;
  }

  Future<void> _chooseSaleOption({required bool delivery}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final values = delivery
        ? const ['At the shop', 'Own delivery', 'Mool delivery']
        : const ['Counter', 'Phone', 'Chat'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .65,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          delivery ? 'Delivery options' : 'Order received',
                          style: const TextStyle(
                            color: MoolColors.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                for (final value in values)
                  ListTile(
                    key: Key(
                      delivery
                          ? 'work-order-receive-${value.toLowerCase().replaceAll(' ', '-')}'
                          : 'work-sell-source-${value.toLowerCase()}',
                    ),
                    selected: (delivery ? _fulfilment : _source) == value,
                    selectedColor: MoolColors.navy,
                    title: Text(delivery ? _fulfilmentLabel(value) : value),
                    trailing: (delivery ? _fulfilment : _source) == value
                        ? const Icon(Icons.check_rounded, size: 20)
                        : null,
                    onTap: () => Navigator.pop(sheetContext, value),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      if (delivery) {
        _fulfilment = selected;
        widget.session.workspaceOrderFulfilment = selected;
      } else {
        _source = selected;
        widget.session.workspaceOrderSource = selected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final validPhone =
        _customer.text.replaceAll(RegExp(r'\D'), '').length >= 10;
    final query = widget.query.trim().toLowerCase();
    final products = widget.session.workspaceCatalogueItems
        .where(
          (product) =>
              query.isEmpty ||
              '${product.title} ${product.brand} ${product.pack} ${product.sku} ${product.barcode}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList(growable: false);
    final selectedCustomer = _customer.text.trim();
    return Material(
      key: const Key('work-dashboard-counter-order-screen'),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            key: const Key('work-sale-compact-controls'),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE9EDF5))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    key: const Key('work-sale-customer'),
                    onPressed: _editCustomer,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    icon: const Icon(Icons.person_outline_rounded, size: 20),
                    label: Text(
                      selectedCustomer.isEmpty
                          ? 'Add customer'
                          : selectedCustomer.split('·').first.trim(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: TextButton(
                    key: const Key('work-sale-delivery'),
                    onPressed: () => _chooseSaleOption(delivery: true),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _fulfilmentLabel(_fulfilment),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.expand_more_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('work-sale-source'),
                  tooltip: 'Order received: $_source',
                  onPressed: () => _chooseSaleOption(delivery: false),
                  icon: const Icon(Icons.more_horiz_rounded, size: 22),
                ),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            query.isNotEmpty
                                ? 'No products match your search'
                                : 'Your catalogue is ready for products',
                            style: const TextStyle(
                              color: MoolColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (query.isEmpty) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: widget.onOpenCatalogue,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add products'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    key: const Key('work-sale-products'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: products.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: Color(0xFFE9EDF5)),
                    itemBuilder: (context, index) => _SaleProductTile(
                      product: products[index],
                      session: widget.session,
                    ),
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                _error!,
                key: const Key('work-order-error'),
                style: const TextStyle(color: Color(0xFFB42318)),
              ),
            ),
          Container(
            key: const Key('work-sale-total-bar'),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE9EDF5))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_selectedUnits units',
                        style: const TextStyle(
                          color: MoolColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '₹${_formatStoreAmount(widget.session.workspaceOrderTotal)}',
                        style: const TextStyle(
                          color: MoolColors.navy,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FilledButton(
                    key: const Key('work-order-review'),
                    onPressed: _selectedUnits == 0
                        ? null
                        : validPhone
                        ? _review
                        : _editCustomer,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _selectedUnits == 0
                          ? 'Add products'
                          : validPhone
                          ? 'Review bill'
                          : 'Add customer',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreSaleCustomerSheet extends StatefulWidget {
  const _StoreSaleCustomerSheet({
    required this.initialValue,
    required this.recentCustomers,
  });
  final String initialValue;
  final List<String> recentCustomers;

  @override
  State<_StoreSaleCustomerSheet> createState() =>
      _StoreSaleCustomerSheetState();
}

class _StoreSaleCustomerSheetState extends State<_StoreSaleCustomerSheet> {
  late final _controller = TextEditingController(text: widget.initialValue);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = _controller.text.trim();
    if (value.replaceAll(RegExp(r'\D'), '').length < 10) {
      setState(() => _error = 'Enter the customer’s 10-digit mobile number.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (media.size.height - media.viewInsets.bottom) * .8,
          ),
          child: SingleChildScrollView(
            key: const Key('work-sale-customer-sheet'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Customer',
                        style: TextStyle(
                          color: MoolColors.navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('work-sale-customer-close'),
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                _AccessibleWorkTextField(
                  keyName: 'work-order-customer',
                  controller: _controller,
                  label: 'Customer mobile number',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB42318)),
                    ),
                  ),
                if (widget.recentCustomers.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Recent customers',
                    style: TextStyle(color: MoolColors.muted, fontSize: 12),
                  ),
                  for (final customer in widget.recentCustomers)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history_rounded, size: 20),
                      title: Text(
                        customer,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        _controller.text = customer;
                        _confirm();
                      },
                    ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('work-sale-customer-confirm'),
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Use customer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaleProductTile extends StatelessWidget {
  const _SaleProductTile({required this.product, required this.session});
  final WorkspaceCatalogueItem product;
  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final quantity = session.workspaceOrderQuantities[product.id] ?? 0;
    return Padding(
      key: Key('work-sale-product-${product.id}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₹${_formatStoreAmount(product.sellingPrice)}',
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${product.pack} · ${product.stock} in stock',
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: Key('work-order-reduce-${product.id}'),
                tooltip: 'Reduce ${product.title}',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: quantity == 0
                    ? null
                    : () =>
                          session.adjustWorkspaceOrderQuantity(product.id, -1),
                icon: const Icon(Icons.remove_rounded, size: 20),
              ),
              SizedBox(
                width: 26,
                child: Semantics(
                  liveRegion: false,
                  label: '${product.title}, $quantity selected',
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              IconButton(
                key: Key('work-order-add-${product.id}'),
                tooltip: 'Add ${product.title}',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: product.stock > quantity
                    ? () => session.adjustWorkspaceOrderQuantity(product.id, 1)
                    : null,
                style: IconButton.styleFrom(
                  foregroundColor: MoolColors.navy,
                  backgroundColor: const Color(0xFFF1F4FF),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _OrderTotalBar extends StatelessWidget {
  const _OrderTotalBar({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-order-total'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFFEAF7F3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${session.workspaceOrderItemCount} products',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '₹${session.workspaceOrderTotal}',
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderReviewSummary extends StatelessWidget {
  const _OrderReviewSummary({
    required this.customer,
    required this.source,
    required this.items,
    required this.units,
    required this.amount,
  });

  final String customer;
  final String source;
  final String items;
  final int units;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-order-review-summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  customer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '₹${_formatStoreAmount(amount)}',
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(
            '$source order · $units units',
            style: const TextStyle(color: MoolColors.muted, fontSize: 10.5),
          ),
          const SizedBox(height: 7),
          Text(
            items,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCompletionChoices extends StatelessWidget {
  const _OrderCompletionChoices({
    required this.fulfilment,
    required this.payment,
    required this.addressController,
    required this.onFulfilmentChanged,
    required this.onPaymentChanged,
  });

  final String fulfilment;
  final String payment;
  final TextEditingController addressController;
  final ValueChanged<String> onFulfilmentChanged;
  final ValueChanged<String> onPaymentChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<String>(
        key: ValueKey('work-review-fulfilment-$fulfilment'),
        initialValue: fulfilment,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Receive order'),
        items: [
          for (final mode in const [
            'At the shop',
            'Own delivery',
            'Mool delivery',
          ])
            DropdownMenuItem(
              value: mode,
              child: Text(switch (mode) {
                'At the shop' => 'Take now',
                'Own delivery' => 'My delivery',
                _ => 'Mool delivery',
              }),
            ),
        ],
        onChanged: (value) {
          if (value != null) onFulfilmentChanged(value);
        },
      ),
      if (fulfilment != 'At the shop') ...[
        const SizedBox(height: 12),
        _AccessibleWorkTextField(
          keyName: 'work-order-address',
          controller: addressController,
          label: 'Delivery address',
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.done,
        ),
      ],
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: ValueKey('work-review-payment-$payment'),
        initialValue: payment,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Payment arrangement'),
        items: [
          for (final option in const [
            'Cash',
            'UPI',
            'Pay request',
            'On delivery',
            'Customer due',
          ])
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: (value) {
          if (value != null) onPaymentChanged(value);
        },
      ),
      const SizedBox(height: 10),
      const Text(
        'Confirm payment separately. Recording this bill does not collect payment.',
        style: TextStyle(color: MoolColors.muted, fontSize: 12, height: 1.4),
      ),
      if (fulfilment == 'Mool delivery')
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Confirm the address with your customer. Rider availability is confirmed after the delivery request.',
            style: TextStyle(
              color: MoolColors.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
    ],
  );
}

// ignore: unused_element
class _SellSourceRail extends StatelessWidget {
  const _SellSourceRail({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-sell-context-rail'),
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE2F2))),
      ),
      child: Row(
        children: [
          for (final label in const ['Counter', 'Phone', 'Chat'])
            _StoreContextButton(
              label: label,
              selected: selected == label,
              onPressed: selected == label ? null : () => onSelected(label),
            ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _OrderCatalogueRow extends StatelessWidget {
  const _OrderCatalogueRow({required this.product, required this.session});

  final WorkspaceCatalogueItem product;
  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final quantity = session.workspaceOrderQuantities[product.id] ?? 0;
    return WorkCard(
      keyName: 'work-order-product-${product.id}',
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${product.pack} · ₹${product.sellingPrice} · ${product.stock} available',
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          if (quantity == 0)
            SizedBox(
              width: 76,
              child: FilledButton.tonal(
                key: Key('work-order-add-${product.id}'),
                onPressed: product.stock == 0
                    ? null
                    : () => session.adjustWorkspaceOrderQuantity(product.id, 1),
                child: const Text('Add'),
              ),
            )
          else
            Row(
              children: [
                IconButton(
                  key: Key('work-order-reduce-${product.id}'),
                  tooltip: 'Reduce ${product.title}',
                  onPressed: () =>
                      session.adjustWorkspaceOrderQuantity(product.id, -1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$quantity',
                  key: Key('work-order-quantity-${product.id}'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                IconButton(
                  key: Key('work-order-increase-${product.id}'),
                  tooltip: 'Add ${product.title}',
                  onPressed: quantity >= product.stock
                      ? null
                      : () =>
                            session.adjustWorkspaceOrderQuantity(product.id, 1),
                  icon: const Icon(Icons.add_circle_rounded),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WorkspaceStatusSurface extends StatelessWidget {
  const _WorkspaceStatusSurface({
    required this.acceptingOrders,
    required this.visibleToCustomers,
    required this.fulfilmentMode,
    required this.busyMinutes,
    required this.reopensAt,
    required this.openingTime,
    required this.closingTime,
    required this.maximumActiveOrders,
    required this.alertSound,
    required this.alertVibration,
    required this.onAcceptingChanged,
    required this.onVisibilityChanged,
    required this.onFulfilmentChanged,
    required this.onBusyMinutesChanged,
    required this.onReopensChanged,
    required this.onOpeningTimeChanged,
    required this.onClosingTimeChanged,
    required this.onMaximumActiveOrdersChanged,
    required this.onAlertSoundChanged,
    required this.onAlertVibrationChanged,
    required this.onProductControls,
    required this.onDeliveryControls,
    required this.onStaffControls,
    required this.onPaymentControls,
    required this.onBusinessDetails,
  });

  final bool acceptingOrders;
  final bool visibleToCustomers;
  final String fulfilmentMode;
  final int busyMinutes;
  final String reopensAt;
  final String openingTime;
  final String closingTime;
  final int maximumActiveOrders;
  final bool alertSound;
  final bool alertVibration;
  final ValueChanged<bool> onAcceptingChanged;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<String> onFulfilmentChanged;
  final ValueChanged<int> onBusyMinutesChanged;
  final ValueChanged<String> onReopensChanged;
  final ValueChanged<String> onOpeningTimeChanged;
  final ValueChanged<String> onClosingTimeChanged;
  final ValueChanged<int> onMaximumActiveOrdersChanged;
  final ValueChanged<bool> onAlertSoundChanged;
  final ValueChanged<bool> onAlertVibrationChanged;
  final VoidCallback onProductControls;
  final VoidCallback onDeliveryControls;
  final VoidCallback onStaffControls;
  final VoidCallback onPaymentControls;
  final VoidCallback onBusinessDetails;

  @override
  Widget build(BuildContext context) {
    final currentState = acceptingOrders
        ? WorkspaceStoreState.open
        : reopensAt.isEmpty
        ? WorkspaceStoreState.off
        : WorkspaceStoreState.paused;
    return ListView(
      key: const Key('work-dashboard-status-screen'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      children: [
        const _SettingsSectionLabel(
          title: 'Today',
          detail: 'Today’s store controls',
        ),
        const SizedBox(height: 10),
        SegmentedButton<WorkspaceStoreState>(
          key: const Key('work-status-store-state'),
          segments: const [
            ButtonSegment(
              value: WorkspaceStoreState.open,
              icon: Icon(Icons.play_circle_outline_rounded),
              label: Text('Open'),
            ),
            ButtonSegment(
              value: WorkspaceStoreState.paused,
              icon: Icon(Icons.pause_circle_outline_rounded),
              label: Text('Paused'),
            ),
            ButtonSegment(
              value: WorkspaceStoreState.off,
              icon: Icon(Icons.power_settings_new_rounded),
              label: Text('Off'),
            ),
          ],
          selected: {currentState},
          onSelectionChanged: (selection) {
            switch (selection.first) {
              case WorkspaceStoreState.open:
                onAcceptingChanged(true);
                onReopensChanged('');
              case WorkspaceStoreState.paused:
                onAcceptingChanged(false);
                onReopensChanged('In 1 hour');
              case WorkspaceStoreState.off:
                onAcceptingChanged(false);
                onReopensChanged('');
            }
          },
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SwitchListTile.adaptive(
                key: const Key('work-status-visibility'),
                title: const Text('Public storefront'),
                subtitle: const Text(
                  'Allow customers to discover your store and public products.',
                ),
                value: visibleToCustomers,
                onChanged: onVisibilityChanged,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                key: const Key('work-status-opening-time'),
                leading: Icon(Icons.schedule_rounded),
                title: const Text('Opens'),
                subtitle: Text(openingTime),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () async {
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                  );
                  if (selected != null && context.mounted) {
                    onOpeningTimeChanged(selected.format(context));
                  }
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                key: const Key('work-status-closing-time'),
                leading: const Icon(Icons.nightlight_outlined),
                title: const Text('Closes'),
                subtitle: Text(closingTime),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () async {
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 22, minute: 0),
                  );
                  if (selected != null && context.mounted) {
                    onClosingTimeChanged(selected.format(context));
                  }
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              const ListTile(
                leading: Icon(Icons.layers_outlined),
                title: Text('Maximum active orders'),
                subtitle: Text('Pause new orders when this limit is reached'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final count in const [4, 8, 12, 20])
                      ChoiceChip(
                        key: Key('work-status-max-orders-$count'),
                        label: Text('$count orders'),
                        selected: maximumActiveOrders == count,
                        onSelected: (selected) {
                          if (selected) onMaximumActiveOrdersChanged(count);
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile.adaptive(
                key: const Key('work-status-alert-sound'),
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Order alert sound'),
                value: alertSound,
                onChanged: onAlertSoundChanged,
              ),
              SwitchListTile.adaptive(
                key: const Key('work-status-alert-vibration'),
                secondary: const Icon(Icons.vibration_rounded),
                title: const Text('Order alert vibration'),
                value: alertVibration,
                onChanged: onAlertVibrationChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SettingsSectionLabel(
          title: 'Default preparation time',
          detail: 'A specific accepted order can be adjusted separately',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: MoolSpacing.xs,
          runSpacing: MoolSpacing.xs,
          children: [
            for (final minutes in const [0, 5, 10, 15, 20, 30])
              ChoiceChip(
                key: Key('work-status-busy-$minutes'),
                label: Text(minutes == 0 ? 'Standard' : '$minutes min'),
                selected: busyMinutes == minutes,
                onSelected: acceptingOrders
                    ? (selected) {
                        if (selected) onBusyMinutesChanged(minutes);
                      }
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 18),
        const _SettingsSectionLabel(
          title: 'Pickup and delivery',
          detail: 'Only enabled choices appear to customers',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: MoolSpacing.xs,
          runSpacing: MoolSpacing.xs,
          children: [
            for (final mode in const [
              'Delivery and pickup',
              'Pickup only',
              'Delivery only',
            ])
              ChoiceChip(
                key: Key(
                  'work-status-mode-${mode.toLowerCase().replaceAll(' ', '-')}',
                ),
                label: Text(mode),
                selected: fulfilmentMode == mode,
                onSelected: acceptingOrders
                    ? (selected) {
                        if (selected) onFulfilmentChanged(mode);
                      }
                    : null,
              ),
          ],
        ),
        if (!acceptingOrders) ...[
          const SizedBox(height: 18),
          const _SettingsSectionLabel(
            title: 'Ordering resumes',
            detail: 'Shown to customers while the store is paused',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: MoolSpacing.xs,
            runSpacing: MoolSpacing.xs,
            children: [
              for (final option in const [
                'In 30 minutes',
                'In 1 hour',
                'Tomorrow at 8:00 AM',
              ])
                ChoiceChip(
                  key: Key(
                    'work-status-reopens-${option.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
                  ),
                  label: Text(option),
                  selected: reopensAt == option,
                  onSelected: (selected) {
                    if (selected) onReopensChanged(option);
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 22),
        const _SettingsSectionLabel(
          title: 'Store',
          detail: 'Longer-term configuration',
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Product controls'),
                subtitle: const Text(
                  'Visibility, stock mode and low-stock defaults',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onProductControls,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: const Text('Delivery area and charges'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onDeliveryControls,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Staff and counters'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onStaffControls,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: const Text('Payment and settlement'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onPaymentControls,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: const Text('Business details and documents'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onBusinessDetails,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: MoolColors.navy,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          detail,
          style: const TextStyle(color: MoolColors.muted, fontSize: 10.5),
        ),
      ],
    );
  }
}

class _WorkspaceAlertsSurface extends StatelessWidget {
  const _WorkspaceAlertsSurface({
    required this.session,
    required this.onOpen,
    required this.onOpenOperation,
    required this.onOpenOrders,
    required this.onOpenStatus,
    required this.onDismiss,
  });
  final WorkSession session;
  final ValueChanged<String> onOpen;
  final ValueChanged<_WorkspaceOperation> onOpenOperation;
  final VoidCallback onOpenOrders, onOpenStatus;
  final ValueChanged<String> onDismiss;

  @override
  Widget build(BuildContext context) {
    final alerts = _workspaceAlerts(session);
    if (alerts.isEmpty) {
      return WorkEmptyState(
        keyName: 'work-dashboard-alerts-empty',
        title: 'Nothing needs attention',
        detail: 'Updates about your orders, stock and payments appear here.',
        actionLabel: 'Review customer orders',
        onAction: onOpenOrders,
      );
    }
    return Material(
      color: Colors.white,
      child: ListView.separated(
        key: const Key('work-dashboard-alerts-screen'),
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: Color(0xFFE5E8F1)),
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return Material(
            key: Key('work-alert-${alert.id}'),
            color: Colors.white,
            child: InkWell(
              key: Key('work-alert-action-${alert.id}'),
              onTap: () {
                if (alert.id == 'store-paused') {
                  onOpenStatus();
                } else if (alert.operation != null) {
                  onOpenOperation(alert.operation!);
                } else {
                  onOpen(alert.route!);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(alert.icon, color: MoolColors.navy, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: const TextStyle(
                              color: MoolColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            alert.detail,
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            alert.actionLabel,
                            style: const TextStyle(
                              color: MoolColors.navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!alert.requiredAction)
                      IconButton(
                        key: Key('work-alert-dismiss-${alert.id}'),
                        tooltip: 'Dismiss ${alert.title}',
                        onPressed: () => onDismiss(alert.id),
                        icon: const Icon(Icons.close_rounded, size: 19),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

typedef _WorkspaceSearchRecord = ({
  String id,
  String title,
  String detail,
  String route,
  IconData icon,
});

List<_WorkspaceSearchRecord> _workspaceSearchRecords(
  WorkSession session,
  String normalized,
) {
  if (normalized.isEmpty) return const [];
  bool matches(String value) => value.toLowerCase().contains(normalized);
  final records = <_WorkspaceSearchRecord>[];
  for (final product in session.workspaceCatalogueItems) {
    if (!matches(
      '${product.title} ${product.brand} ${product.variant} ${product.pack} ${product.sku} ${product.barcode}',
    )) {
      continue;
    }
    records.add((
      id: 'product-${product.id}',
      title: product.title,
      detail:
          '${product.brand} · ${product.pack} · ₹${product.sellingPrice} · ${product.stock} available',
      route: '/app/retailer/home?view=stock&product=${product.id}',
      icon: Icons.inventory_2_outlined,
    ));
  }
  if (session.workspaceOrderCustomer.isNotEmpty &&
      matches(
        '${session.workspaceOrderCustomer} ${session.workspaceOrderSource} ${session.workspaceOrderItems} ${session.workspaceOrderAmount} ${session.workspaceOrderStage}',
      )) {
    records.add((
      id: 'order-current',
      title:
          '${session.workspaceOrderSource} order · ${session.workspaceOrderCustomer}',
      detail:
          '${session.workspaceOrderStage} · ₹${session.workspaceOrderAmount} · ${session.workspaceOrderItems}',
      route: '/app/retailer/orders',
      icon: Icons.receipt_long_outlined,
    ));
    records.add((
      id: 'customer-current',
      title: session.workspaceOrderCustomer,
      detail: 'Customer purchase and payment record',
      route: '/app/retailer/customers',
      icon: Icons.person_outline_rounded,
    ));
  }
  for (var index = 0; index < session.workspaceActivity.length; index++) {
    final activity = session.workspaceActivity[index];
    if (!matches(activity.message)) continue;
    records.add((
      id: 'activity-$index',
      title: activity.message,
      detail:
          'Store activity · ${activity.time.hour.toString().padLeft(2, '0')}:${activity.time.minute.toString().padLeft(2, '0')}',
      route: '/app/retailer/books',
      icon: Icons.history_rounded,
    ));
  }
  return records;
}

typedef _WorkspaceAlertItem = ({
  String id,
  String title,
  String detail,
  String actionLabel,
  String? route,
  _WorkspaceOperation? operation,
  IconData icon,
  bool requiredAction,
});

List<_WorkspaceAlertItem> _workspaceAlerts(WorkSession session) {
  final alerts = <_WorkspaceAlertItem>[];
  if (!session.retailerSetupSaved) {
    alerts.add((
      id: 'store-setup',
      title: 'Finish store operations setup',
      detail:
          'Add the products and fulfilment choices needed before customers can order.',
      actionLabel: 'Continue store setup',
      route: '/app/work/retailer/setup',
      operation: null,
      icon: Icons.storefront_outlined,
      requiredAction: true,
    ));
  }
  if (!session.workspaceContactsReady) {
    alerts.add((
      id: 'contact-details',
      title: 'Confirm contact details',
      detail:
          'Keep a confirmed contact number and email available for store support.',
      actionLabel: 'Review contact details',
      route: '/app/work/workspace/contact',
      operation: null,
      icon: Icons.contact_phone_outlined,
      requiredAction: true,
    ));
  }
  if (session.retailerSetupSaved &&
      !session.workspaceAcceptingOrders &&
      !session.dismissedWorkspaceAlerts.contains('store-paused')) {
    alerts.add((
      id: 'store-paused',
      title: 'Your store is paused',
      detail: session.workspaceReopensAt.isEmpty
          ? 'Customers cannot place new app orders until you reopen the store.'
          : 'Customers can see that ordering resumes ${session.workspaceReopensAt}.',
      actionLabel: 'Review availability',
      route: '/app/work/workspace/dashboard',
      operation: null,
      icon: Icons.pause_circle_outline_rounded,
      requiredAction: false,
    ));
  }
  if (session.workspaceLowStockCount > 0) {
    alerts.add((
      id: 'low-stock',
      title: '${session.workspaceLowStockCount} products need stock attention',
      detail:
          'Review available quantities before accepting the next customer order.',
      actionLabel: 'Review catalogue',
      route: '/app/retailer/home?view=stock',
      operation: null,
      icon: Icons.inventory_2_outlined,
      requiredAction: true,
    ));
  }
  if (session.workspaceOrderCustomer.isNotEmpty) {
    alerts.add((
      id: 'customer-order',
      title: session.workspaceOrderNeedsDelivery
          ? 'Customer order needs delivery details'
          : 'Customer order is ready to review',
      detail:
          '${session.workspaceOrderItems} · ₹${session.workspaceOrderAmount}',
      actionLabel: session.workspaceOrderNeedsDelivery
          ? 'Continue delivery'
          : 'Review order',
      route: '/app/retailer/orders',
      operation: null,
      icon: session.workspaceOrderNeedsDelivery
          ? Icons.delivery_dining_outlined
          : Icons.receipt_long_outlined,
      requiredAction: true,
    ));
  }
  return alerts;
}

class _WorkspaceDashboardHero extends StatelessWidget {
  const _WorkspaceDashboardHero({
    required this.workspace,
    required this.profile,
  });

  final WorkWorkspace workspace;
  final WorkProfileOption profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-dashboard-hero'),
      padding: const EdgeInsets.symmetric(
        horizontal: MoolSpacing.sm,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF080887), Color(0xFF1616AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MoolRadii.card),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22080887),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: MoolColors.orange,
            foregroundColor: MoolColors.navy,
            child: Icon(profile.icon, size: 24),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  workspace.name,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${profile.label} · ${workspace.area}',
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    color: Color(0xFFD8D9FF),
                    fontSize: 10.5,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSignal extends StatelessWidget {
  const _DashboardSignal({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      child: Column(
        children: [
          Icon(icon, color: MoolColors.navy),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 9.5,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPriorityCard extends StatelessWidget {
  const _DashboardPriorityCard({
    required this.session,
    required this.profile,
    required this.presentation,
  });

  final WorkSession session;
  final WorkProfileOption profile;
  final _DashboardPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final retailer = const {
      'retailer-grocery',
      'retailer-speciality',
    }.contains(profile.id);
    final shopReady =
        retailer &&
        (session.retailerSetupSaved ||
            session.reviewStage == WorkReviewStage.live);
    return WorkCard(
      keyName: 'work-dashboard-priority',
      color: const Color(0xFFFFF4E5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: MoolColors.orange,
            foregroundColor: MoolColors.navy,
            child: Icon(Icons.rocket_launch_outlined),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'START HERE',
                  style: TextStyle(
                    color: MoolColors.orange,
                    fontSize: 9,
                    letterSpacing: .45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  shopReady ? 'Open your shop operations' : presentation.focus,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  shopReady
                      ? 'Your catalogue and fulfilment choices are ready for daily work.'
                      : presentation.focusDetail,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
                FilledButton.icon(
                  key: const Key('work-dashboard-priority-action'),
                  onPressed: retailer
                      ? () {
                          if (shopReady) {
                            context.push('/app/retailer/home');
                            return;
                          }
                          session.beginRetailerSetup();
                          context.push('/app/work/retailer/setup');
                        }
                      : () => context.push('/app/work/workspace/proof'),
                  icon: Icon(
                    retailer
                        ? Icons.storefront_outlined
                        : Icons.fact_check_outlined,
                  ),
                  label: Text(
                    retailer
                        ? shopReady
                              ? 'Open operations'
                              : 'Prepare my catalogue'
                        : 'View approved record',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCapability extends StatelessWidget {
  const _DashboardCapability({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      keyName: keyName,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEAF2FF),
            foregroundColor: MoolColors.navy,
            child: Icon(icon),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceAccountState extends StatelessWidget {
  const _WorkspaceAccountState({
    required this.session,
    required this.workspace,
  });

  final WorkSession session;
  final WorkWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      keyName: 'work-dashboard-account-state',
      color: const Color(0xFFEAF7E8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkSectionTitle(
            title: 'Workspace and account',
            detail: 'One sign-in keeps your approved Workspace connected.',
          ),
          const SizedBox(height: MoolSpacing.sm),
          _AccountStateRow(
            label: 'MoolSocial account',
            value: session.connectedProviderLabel.isEmpty
                ? 'Connected'
                : '${session.connectedProviderLabel} connected',
          ),
          _AccountStateRow(
            label: 'Contact details',
            value: session.workspaceContactsReady ? 'Confirmed' : 'Attention',
          ),
          _AccountStateRow(
            label: 'Workspace review',
            value: workspace.verified ? 'Approved' : 'In review',
          ),
          _AccountStateRow(label: 'Workspace ID', value: workspace.id),
        ],
      ),
    );
  }
}

class _AccountStateRow extends StatelessWidget {
  const _AccountStateRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: MoolColors.success,
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: MoolColors.muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardReveal extends StatelessWidget {
  const _DashboardReveal({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final duration = MoolMotion.accessible(
      context,
      MoolMotion.standard + delay,
    );
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: MoolMotion.enter,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _DashboardPresentation {
  const _DashboardPresentation({
    required this.title,
    required this.detail,
    required this.focus,
    required this.focusDetail,
    required this.customerTitle,
    required this.networkTitle,
    required this.toolsTitle,
    required this.earnAction,
    required this.signals,
  });

  final String title;
  final String detail;
  final String focus;
  final String focusDetail;
  final String customerTitle;
  final String networkTitle;
  final String toolsTitle;
  final String earnAction;
  final List<({IconData icon, String label})> signals;
}

_DashboardPresentation _presentationFor(
  WorkProfileOption profile,
) => switch (profile.familyId) {
  'products-trade' => _DashboardPresentation(
    title: profile.id == 'manufacturer'
        ? 'Your manufacturing growth desk'
        : profile.id == 'wholesaler'
        ? 'Your trade growth desk'
        : 'Your store growth desk',
    detail:
        'Keep products, buyers, fulfilment and business opportunities in one clear place.',
    focus: profile.id == 'manufacturer'
        ? 'Prepare your supply and distribution presence'
        : profile.id == 'wholesaler'
        ? 'Prepare your trade catalogue and buyer terms'
        : 'Prepare your catalogue for local customers',
    focusDetail:
        'Your Workspace is approved. Review its readiness before publishing any offer or product.',
    customerTitle: 'Reach the right buyers',
    networkTitle: 'Strengthen sourcing and supply',
    toolsTitle: 'Run daily trade clearly',
    earnAction: 'Find business opportunities',
    signals: const [
      (icon: Icons.inventory_2_outlined, label: 'Catalogue'),
      (icon: Icons.receipt_long_outlined, label: 'Orders'),
      (icon: Icons.groups_outlined, label: 'Customers'),
    ],
  ),
  'food-business' => const _DashboardPresentation(
    title: 'Your food business desk',
    detail:
        'Bring menus, meal demand, fulfilment and repeat customers together.',
    focus: 'Prepare your menu and service area',
    focusDetail:
        'Review your approved details before accepting meal, pickup or delivery demand.',
    customerTitle: 'Bring diners and meal customers back',
    networkTitle: 'Source ingredients and packaging',
    toolsTitle: 'Manage kitchen and fulfilment',
    earnAction: 'Find food business opportunities',
    signals: [
      (icon: Icons.restaurant_menu_outlined, label: 'Menu'),
      (icon: Icons.takeout_dining_outlined, label: 'Orders'),
      (icon: Icons.event_repeat_outlined, label: 'Meal plans'),
    ],
  ),
  'health' => const _DashboardPresentation(
    title: 'Your trusted care desk',
    detail:
        'Keep availability, appointments and compliant follow-up clearly separated.',
    focus: 'Prepare availability and verified services',
    focusDetail:
        'Review your approved professional details before receiving appointment or medicine requests.',
    customerTitle: 'Help patients find verified care',
    networkTitle: 'Organise eligible professional supplies',
    toolsTitle: 'Manage appointments and follow-up',
    earnAction: 'Find healthcare opportunities',
    signals: [
      (icon: Icons.calendar_month_outlined, label: 'Availability'),
      (icon: Icons.event_available_outlined, label: 'Appointments'),
      (icon: Icons.health_and_safety_outlined, label: 'Compliance'),
    ],
  ),
  'services' => const _DashboardPresentation(
    title: 'Your service growth desk',
    detail:
        'Turn appointments, service quality and repeat visits into steady local business.',
    focus: 'Prepare your services and availability',
    focusDetail:
        'Review your approved Workspace before accepting appointments or packages.',
    customerTitle: 'Turn first visits into repeat visits',
    networkTitle: 'Source professional products confidently',
    toolsTitle: 'Manage services, staff and billing',
    earnAction: 'Find service opportunities',
    signals: [
      (icon: Icons.content_cut_outlined, label: 'Services'),
      (icon: Icons.calendar_month_outlined, label: 'Appointments'),
      (icon: Icons.loyalty_outlined, label: 'Repeat visits'),
    ],
  ),
  'travel' => _DashboardPresentation(
    title: 'Your ${profile.label.toLowerCase()} desk',
    detail:
        'Keep availability, trip readiness, safety documents and earnings together.',
    focus: 'Prepare your travel availability',
    focusDetail:
        'Review the approved vehicle or operator details before accepting passenger requests.',
    customerTitle: 'Be available for the right trip demand',
    networkTitle: 'Find operating and vehicle support',
    toolsTitle: 'Manage trips, safety and earnings',
    earnAction: 'Find travel opportunities',
    signals: const [
      (icon: Icons.toggle_on_outlined, label: 'Availability'),
      (icon: Icons.route_outlined, label: 'Trips and routes'),
      (icon: Icons.payments_outlined, label: 'Earnings'),
    ],
  ),
  'delivery' => _DashboardPresentation(
    title: 'Your ${profile.label.toLowerCase()} desk',
    detail:
        'Keep delivery availability, route proof and completed-work earnings visible.',
    focus: 'Prepare your delivery availability',
    focusDetail:
        'Review the approved rider, vehicle or fleet details before accepting assignments.',
    customerTitle: 'Match with suitable delivery demand',
    networkTitle: 'Find routes and operating support',
    toolsTitle: 'Manage delivery proof and settlements',
    earnAction: 'Find delivery assignments',
    signals: const [
      (icon: Icons.delivery_dining_outlined, label: 'Availability'),
      (icon: Icons.route_outlined, label: 'Assignments'),
      (icon: Icons.payments_outlined, label: 'Earnings'),
    ],
  ),
  'create-work' => _DashboardPresentation(
    title: profile.id == 'creator'
        ? 'Your creator work desk'
        : 'Your professional work desk',
    detail:
        'Keep opportunities, deliverables, proof and earnings connected to your approved identity.',
    focus: profile.id == 'creator'
        ? 'Prepare your portfolio and channels'
        : 'Prepare your skills and work profile',
    focusDetail:
        'Review your approved Workspace, then choose paid opportunities that fit your experience.',
    customerTitle: profile.id == 'creator'
        ? 'Turn content into paid outcomes'
        : 'Show your skills with clear proof',
    networkTitle: 'Find professional tools and support',
    toolsTitle: 'Manage work, deliverables and payouts',
    earnAction: 'Find paid opportunities',
    signals: const [
      (icon: Icons.work_outline_rounded, label: 'Opportunities'),
      (icon: Icons.task_alt_outlined, label: 'Deliverables'),
      (icon: Icons.payments_outlined, label: 'Earnings'),
    ],
  ),
  _ => const _DashboardPresentation(
    title: 'Your Workspace dashboard',
    detail: 'Keep your approved work identity and next actions together.',
    focus: 'Review your Workspace readiness',
    focusDetail:
        'Confirm that your details remain correct before starting work.',
    customerTitle: 'Reach suitable customers',
    networkTitle: 'Build trusted connections',
    toolsTitle: 'Manage your work clearly',
    earnAction: 'Find paid opportunities',
    signals: [
      (icon: Icons.person_search_outlined, label: 'Demand'),
      (icon: Icons.task_alt_outlined, label: 'Work'),
      (icon: Icons.payments_outlined, label: 'Earnings'),
    ],
  ),
};

WorkProfileOption? _profileForWorkspace(
  WorkSession session,
  WorkWorkspace workspace,
) {
  final profileId = workspace.profileId;
  if (profileId != null) {
    for (final profile in workProfiles) {
      if (profile.id == profileId) return profile;
    }
  }
  final selected = session.selectedProfile;
  if (selected != null && selected.label == workspace.profileLabel) {
    return selected;
  }
  for (final profile in workProfiles) {
    if (profile.label == workspace.profileLabel) return profile;
  }
  return null;
}
