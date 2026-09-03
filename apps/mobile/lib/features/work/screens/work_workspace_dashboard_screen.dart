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
  _WorkspaceControlView _view = _WorkspaceControlView.dashboard;
  bool _draftAcceptingOrders = true;
  bool _draftVisibleToCustomers = false;
  String _draftFulfilmentMode = 'Delivery and pickup';
  int _draftBusyMinutes = 0;
  String _draftReopensAt = '';
  _WorkspaceOperation _operation = _WorkspaceOperation.orders;
  _WorkspaceControlView _operationReturnView = _WorkspaceControlView.dashboard;
  _WorkspaceOperation? _operationReturnOperation;
  Timer? _procurementRevealTimer;
  bool _procurementReady = false;

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
        _showProcurement();
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
      _WorkspaceControlView.status => 'Daily controls and store configuration',
      _WorkspaceControlView.alerts =>
        'Resolve the most important store actions first',
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
            _WorkspaceOperation.paidWork,
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
        _view == _WorkspaceControlView.operation;

    return WorkPageScaffold(
      session: session,
      title: title,
      subtitle: subtitle,
      headerTitle: storeRootSurface
          ? _WorkspaceDashboardHeader(
              session: session,
              workspace: workspace,
              profile: profile,
              searchOpen: _view == _WorkspaceControlView.search,
              searchController: _searchController,
              searchFocusNode: _searchFocus,
              onSwitchWorkspace: () => _showWorkspaceSwitcher(context),
              onBack: _view == _WorkspaceControlView.operation
                  ? () => unawaited(_leaveOperation())
                  : null,
              onSearch: _showSearch,
              onSearchChanged: session.updateWorkspaceSearch,
              onCloseSearch: _finishSearch,
              onScan: () => _showOperation(_WorkspaceOperation.catalogue),
              onSettings: _showStatus,
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
        _WorkspaceControlView.dashboard => null,
        _WorkspaceControlView.procurement => _showDashboard,
        _WorkspaceControlView.status => () => unawaited(_leaveSettings()),
        _WorkspaceControlView.operation => () => unawaited(_leaveOperation()),
        _WorkspaceControlView.search => _finishSearch,
        _ => _showDashboard,
      },
      manageSystemBack: _view != _WorkspaceControlView.procurement,
      hideNavigationWhenKeyboardVisible:
          _view == _WorkspaceControlView.procurement,
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
          onCustomers: () => _showOperation(_WorkspaceOperation.customers),
          onMoney: () => _showOperation(_WorkspaceOperation.payments),
          onGrow: () => _showOperation(_WorkspaceOperation.growth),
          onOrders: () => _showOperation(_WorkspaceOperation.orders),
          onNewSale: () {
            session.prepareWorkspaceOrder(
              source: 'Counter',
              fulfilment: 'At the shop',
            );
            _showOperation(_WorkspaceOperation.counterOrder);
          },
          onDeliverOrder: () {
            session.prepareWorkspaceOrder(
              source: 'Phone',
              fulfilment: 'Mool delivery',
            );
            _showOperation(_WorkspaceOperation.counterOrder);
          },
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
          onExit: _showDashboard,
          onDestinationChanged: _handleProcurementDestinationChanged,
        ),
        _WorkspaceControlView.operation => _WorkspaceOperationSurface(
          operation: _operation,
          session: session,
          onOpenStore: _showDashboard,
          onOpenOperation: _showOperation,
          onOpenRoute: openScopedRoute,
        ),
      },
    );
  }

  void _showDashboard() {
    _searchFocus.unfocus();
    setState(() => _view = _WorkspaceControlView.dashboard);
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
      _view = _WorkspaceControlView.status;
    });
  }

  void _showAlerts() {
    _searchFocus.unfocus();
    setState(() => _view = _WorkspaceControlView.alerts);
  }

  void _showOperation(_WorkspaceOperation operation) {
    _searchFocus.unfocus();
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

  void _showProcurement() {
    _searchFocus.unfocus();
    session.clearMessages();
    setState(() => _view = _WorkspaceControlView.procurement);
    if (_procurementReady || _procurementRevealTimer != null) return;
    _procurementRevealTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _procurementReady = true);
      _procurementRevealTimer = null;
    });
  }

  bool _isNestedWorkspaceOperation(_WorkspaceOperation operation) => const {
    _WorkspaceOperation.deliverySettings,
    _WorkspaceOperation.staff,
    _WorkspaceOperation.businessRecord,
    _WorkspaceOperation.offers,
    _WorkspaceOperation.paidWork,
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
        _showDashboard();
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
      onOpenRoute: (route) => context.push(route),
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
    setState(() => _view = _WorkspaceControlView.dashboard);
  }

  bool get _settingsDirty =>
      _draftAcceptingOrders != session.workspaceAcceptingOrders ||
      _draftVisibleToCustomers != session.workspaceVisibleToCustomers ||
      _draftFulfilmentMode != session.workspaceFulfilmentMode ||
      _draftBusyMinutes != session.workspaceBusyMinutes ||
      _draftReopensAt != session.workspaceReopensAt;

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
    required this.onExit,
    required this.onDestinationChanged,
  });

  final BuyV2Session session;
  final AuthenticatedAccountIdentity? accountIdentity;
  final bool accountAuthenticated;
  final bool ready;
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
}

extension on _WorkspaceOperation {
  String get title => switch (this) {
    _WorkspaceOperation.orders => 'Customer orders',
    _WorkspaceOperation.counterOrder => 'Create customer order',
    _WorkspaceOperation.catalogue => 'Catalogue and stock',
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
    _WorkspaceOperation.paidWork => 'Publish paid work',
  };

  String get subtitle => switch (this) {
    _WorkspaceOperation.orders => 'Accept, prepare and complete every order',
    _WorkspaceOperation.counterOrder =>
      'Record counter or phone orders and arrange delivery',
    _WorkspaceOperation.catalogue =>
      'Products, selling prices and available stock',
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
  };
}

enum _QuickStoreState { open, paused, off }

class _WorkspaceDashboardHeader extends StatelessWidget {
  const _WorkspaceDashboardHeader({
    required this.session,
    required this.workspace,
    required this.profile,
    required this.searchOpen,
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
                  width: 34,
                  height: 28,
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
                    child: SizedBox(
                      height: 22,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 15,
                            color: MoolColors.navy,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${workspace.name} · ${workspace.area}',
                                maxLines: 1,
                                style: const TextStyle(
                                  color: MoolColors.navy,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${session.workspaceStoreState == WorkspaceStoreState.open
                                ? 'Open'
                                : session.workspaceStoreState == WorkspaceStoreState.paused
                                ? 'Paused'
                                : 'Off'} · ${session.workspaceVisibleToCustomers ? 'Public' : 'Private'}',
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 2),
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
                                autofocus: true,
                                onChanged: onSearchChanged,
                                textInputAction: TextInputAction.search,
                                style: const TextStyle(
                                  color: MoolColors.navy,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Search your store',
                                  hintStyle: TextStyle(
                                    color: MoolColors.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: MoolColors.navy,
                                    size: 21,
                                  ),
                                  prefixIconConstraints: BoxConstraints(
                                    minWidth: 42,
                                    minHeight: 44,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
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
                      if (!searchOpen)
                        _HeaderSearchUtility(
                          key: const Key('work-dashboard-scan'),
                          tooltip: 'Scan product barcode',
                          onTap: onScan,
                          icon: Icons.qr_code_scanner_rounded,
                        ),
                      if (searchOpen)
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
              if (!searchOpen) ...[
                const SizedBox(width: 4),
                IconButton.outlined(
                  key: const Key('work-dashboard-settings'),
                  tooltip: 'Store settings',
                  onPressed: onSettings,
                  icon: const Icon(Icons.tune_rounded),
                ),
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
        child: SizedBox(width: 36, height: 48, child: Icon(icon, size: 18)),
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
  });

  final WorkSession session;
  final WorkWorkspace workspace;
  final VoidCallback onSetup;
  final VoidCallback onCustomers;
  final VoidCallback onMoney;
  final VoidCallback onGrow;
  final VoidCallback onOrders;
  final VoidCallback onNewSale;
  final VoidCallback onDeliverOrder;
  final VoidCallback onStock;
  final ValueChanged<_WorkspaceOperation> onOpenOperation;
  final VoidCallback onBuyStock;

  @override
  Widget build(BuildContext context) {
    final storeReady =
        session.retailerSetupSaved ||
        session.reviewStage == WorkReviewStage.live;
    return Container(
      key: const Key('work-workspace-dashboard'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFF), Color(0xFFEFF3FF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: storeReady
                  ? _StoreActivityDeck(
                      key: ValueKey(session.workspaceOrderStage),
                      session: session,
                      onReviewOrder: onOrders,
                      onStock: onStock,
                      onMoney: onMoney,
                      onGroupBulk: () =>
                          onOpenOperation(_WorkspaceOperation.groupBuying),
                    )
                  : _StoreSetupDeck(
                      session: session,
                      workspace: workspace,
                      onSetup: onSetup,
                    ),
            ),
          ),
          if (storeReady)
            Positioned(
              right: 10,
              top: 14,
              child: _LiveStatusBubbleRail(
                session: session,
                onOrders: () {
                  session.setWorkspaceOrderFilter('Live');
                  onOrders();
                },
                onPacking: () {
                  session.setWorkspaceOrderFilter('Packing');
                  onOrders();
                },
                onDelivery: () {
                  session.setWorkspaceOrderFilter('Ready');
                  onOrders();
                },
                onStock: onStock,
                onMoney: onMoney,
              ),
            ),
          if (storeReady)
            Positioned(
              left: 12,
              right: 70,
              bottom: 14,
              child: _FloatingStoreCommandDock(
                onNewSale: onNewSale,
                onDeliver: onDeliverOrder,
                onBuyStock: onBuyStock,
                onGroupBulk: () =>
                    onOpenOperation(_WorkspaceOperation.groupBuying),
              ),
            ),
          if (storeReady)
            Positioned(
              right: 12,
              bottom: 18,
              child: _BusinessDrawerButton(
                onCustomers: onCustomers,
                onMoney: onMoney,
                onGrow: onGrow,
                onPreview: () => onOpenOperation(_WorkspaceOperation.preview),
              ),
            ),
          if (session.workspaceDashboardState != WorkspaceDashboardState.ready)
            Positioned(
              left: 12,
              right: 68,
              top: 10,
              child: _DashboardSyncBanner(session: session),
            ),
        ],
      ),
    );
  }
}

class _StoreActivityDeck extends StatelessWidget {
  const _StoreActivityDeck({
    required this.session,
    required this.onReviewOrder,
    required this.onStock,
    required this.onMoney,
    required this.onGroupBulk,
    super.key,
  });

  final WorkSession session;
  final VoidCallback onReviewOrder;
  final VoidCallback onStock;
  final VoidCallback onMoney;
  final VoidCallback onGroupBulk;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (session.hasActiveWorkspaceOrder) {
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
      padding: const EdgeInsets.fromLTRB(14, 18, 70, 104),
      child: Center(child: _ActivityDeckShell(child: content)),
    );
  }
}

class _ActivityDeckShell extends StatelessWidget {
  const _ActivityDeckShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430, maxHeight: 510),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 18),
            child: Transform.scale(
              scale: .92,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE5FF),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, 9),
            child: Transform.scale(
              scale: .96,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEFF),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Material(
            elevation: 14,
            shadowColor: const Color(0x22001B4D),
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: SizedBox.expand(child: child),
          ),
        ],
      ),
    );
  }
}

class _IncomingOrderActivityCard extends StatelessWidget {
  const _IncomingOrderActivityCard({
    required this.session,
    required this.onReview,
    required this.onReject,
  });

  final WorkSession session;
  final VoidCallback onReview;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('work-activity-incoming-order'),
      behavior: HitTestBehavior.opaque,
      onTap: onReview,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 380) {
          session.advanceWorkspaceOrder();
        } else if (velocity < -380) {
          onReject();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _LiveDot(color: Color(0xFFFF8A00)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'NEW ORDER',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF9A4A00),
                      fontSize: 11,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: _LiveCountdownText(
                    deadline: session.workspaceOrderActionDeadline,
                    fallback: 'Review now',
                    style: const TextStyle(
                      color: Color(0xFF9A4A00),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '₹${session.workspaceOrderAmount}',
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 36,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              session.workspaceOrderCustomer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${session.workspaceOrderSource} · ${session.workspaceOrderPayment} · ${session.workspaceOrderFulfilment}',
              style: const TextStyle(
                color: MoolColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  session.workspaceOrderItems,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('work-activity-order-reject'),
                    onPressed: onReject,
                    icon: const Icon(Icons.swipe_left_rounded),
                    label: const FittedBox(child: Text('Reject')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('work-activity-order-accept'),
                    onPressed: session.advanceWorkspaceOrder,
                    icon: const Icon(Icons.swipe_right_rounded),
                    label: const FittedBox(child: Text('Accept')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Swipe left to reject · Tap to review · Swipe right to accept',
                textAlign: TextAlign.center,
                style: TextStyle(color: MoolColors.muted, fontSize: 9.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackingActivityCard extends StatelessWidget {
  const _PackingActivityCard({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('work-activity-packing'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LiveDot(color: MoolColors.navy),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PACKING NOW',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 11,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _LiveCountdownText(
                    deadline: session.workspaceOrderActionDeadline,
                    fallback: 'In progress',
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            session.workspaceOrderCustomer,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Order ₹${session.workspaceOrderAmount}',
            style: const TextStyle(color: MoolColors.muted),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: session.workspacePackingProgress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 5),
              Text(
                '${session.workspaceOrderDisplayItemCount} products reserved for packing',
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Material(
              color: const Color(0xFFF6F8FF),
              borderRadius: BorderRadius.circular(18),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                children: [
                  for (final line in session.workspacePackingLines)
                    SizedBox(
                      height: 42,
                      child: CheckboxListTile(
                        key: Key('work-pack-${line.id}'),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.trailing,
                        value: line.packed,
                        onChanged: (value) => session.setWorkspacePackingLine(
                          line.id,
                          value == true,
                        ),
                        title: Text(
                          '${line.label} · ${line.quantity}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('work-activity-mark-ready'),
              onPressed: session.workspacePackingComplete
                  ? session.advanceWorkspaceOrder
                  : null,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Mark ready'),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'READY FOR CUSTOMER PICKUP',
            style: TextStyle(
              color: Color(0xFF08765D),
              fontSize: 11,
              letterSpacing: .7,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xFFE8F7F1),
              child: Icon(
                Icons.store_mall_directory_rounded,
                color: Color(0xFF08765D),
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            session.workspaceOrderCustomer,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${session.workspaceOrderItems} · ₹${session.workspaceOrderAmount}',
            style: const TextStyle(color: MoolColors.muted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('work-confirm-customer-pickup'),
              onPressed: () {
                session.advanceWorkspaceOrder();
                final invoice = session.latestWorkspaceInvoice;
                if (invoice != null) {
                  _showWorkspaceInvoiceSheet(context, session, invoice);
                }
              },
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Confirm pickup and send invoice'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceReadyActivityCard extends StatelessWidget {
  const _InvoiceReadyActivityCard({
    required this.session,
    required this.invoice,
  });

  final WorkSession session;
  final WorkspaceCustomerInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('work-activity-invoice-ready'),
      onTap: () => _showWorkspaceInvoiceSheet(context, session, invoice),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CUSTOMER INVOICE READY',
              style: TextStyle(
                color: Color(0xFF08765D),
                fontSize: 11,
                letterSpacing: .7,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 28),
            const Icon(
              Icons.receipt_long_rounded,
              color: MoolColors.navy,
              size: 70,
            ),
            const SizedBox(height: 14),
            Text(
              invoice.id,
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${invoice.customer} · ₹${invoice.amount}',
              style: const TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    _showWorkspaceInvoiceSheet(context, session, invoice),
                icon: const Icon(Icons.send_outlined),
                label: const Text('Send invoice and retain customer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    return Padding(
      key: const Key('work-activity-delivery'),
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
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
                    'DELIVERY LIVE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF08765D),
                      fontSize: 11,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _LiveCountdownText(
                      deadline: assignment?.eta,
                      fallback: assignment == null ? 'Assigning' : 'Live',
                      style: const TextStyle(
                        color: Color(0xFF08765D),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE8F7F1),
                  child: Icon(
                    Icons.delivery_dining_rounded,
                    color: Color(0xFF08765D),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment?.partnerName ??
                            'Delivery partner assignment pending',
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        assignment == null
                            ? 'You can continue after a partner accepts.'
                            : '${assignment.vehicleLabel} · ${assignment.stage}',
                        style: const TextStyle(color: MoolColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _DeliveryProgressTrack(stage: assignment?.stage),
            const SizedBox(height: 24),
            Text(
              session.workspaceOrderCustomer,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              session.workspaceOrderAddress.isEmpty
                  ? 'Add the customer delivery address before handover.'
                  : session.workspaceOrderAddress,
              style: TextStyle(
                color: session.workspaceOrderAddress.isEmpty
                    ? const Color(0xFFB42318)
                    : MoolColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      Uri(
                        path: '/app/chat/inbox',
                        queryParameters: {
                          'return': GoRouterState.of(context).uri.toString(),
                          'draft':
                              'Delivery support for ${session.workspaceOrderCustomer}',
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
                    key: const Key('work-activity-confirm-handover'),
                    onPressed:
                        assignment == null ||
                            session.workspaceOrderAddress.isEmpty ||
                            session.workspaceHandoverBusy
                        ? null
                        : () => _showWorkspaceHandoverSheet(context, session),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Confirm handover'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryProgressTrack extends StatelessWidget {
  const _DeliveryProgressTrack({required this.stage});

  final String? stage;

  @override
  Widget build(BuildContext context) {
    const steps = ['Assigned', 'At store', 'Collected', 'Delivered'];
    final currentIndex = stage == null
        ? -1
        : steps.indexWhere(
            (step) => step.toLowerCase() == stage!.trim().toLowerCase(),
          );
    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  width: index == currentIndex ? 18 : 12,
                  height: index == currentIndex ? 18 : 12,
                  decoration: BoxDecoration(
                    color: index <= currentIndex
                        ? const Color(0xFF08765D)
                        : const Color(0xFFDCE2F2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[index] == 'Collected' ? 'Pickup' : steps[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (index < steps.length - 1)
            const Expanded(child: Divider(height: 1)),
        ],
      ],
    );
  }
}

Future<void> _showWorkspaceHandoverSheet(
  BuildContext context,
  WorkSession session,
) async {
  final controller = TextEditingController();
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
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Customer delivery OTP',
                errorText: error,
                prefixIcon: const Icon(Icons.password_rounded),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('work-handover-confirm'),
              onPressed: session.workspaceHandoverBusy
                  ? null
                  : () async {
                      final success = await session.verifyWorkspaceHandover(
                        controller.text,
                      );
                      if (success && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      } else if (sheetContext.mounted) {
                        setSheetState(() => error = session.errorMessage);
                      }
                    },
              icon: const Icon(Icons.verified_rounded),
              label: const Text('Verify and complete order'),
            ),
          ],
        ),
      ),
    ),
  );
  controller.dispose();
}

class _StockActivityCard extends StatelessWidget {
  const _StockActivityCard({required this.session, required this.onOpen});

  final WorkSession session;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final product = session.workspaceCatalogueItems.firstWhere(
      (item) => item.stock <= 5,
      orElse: () => session.workspaceCatalogueItems.first,
    );
    return InkWell(
      key: const Key('work-activity-stock'),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'STOCK NEEDS ATTENTION',
              style: TextStyle(
                color: Color(0xFF9A4A00),
                fontSize: 11,
                letterSpacing: .7,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Center(
              child: CircleAvatar(
                radius: 52,
                backgroundColor: const Color(0xFFFFF0DB),
                child: Text(
                  product.brand.substring(0, 1),
                  style: const TextStyle(
                    color: Color(0xFF9A4A00),
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              product.title,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${product.pack} · ${product.stock} left',
              style: const TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              'Selling ₹${product.sellingPrice} · MRP ₹${product.mrp ?? product.sellingPrice}',
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Open catalogue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyActivityCard extends StatelessWidget {
  const _MoneyActivityCard({required this.session, required this.onOpen});

  final WorkSession session;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('work-activity-money'),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MONEY READY',
              style: TextStyle(
                color: Color(0xFF08765D),
                fontSize: 11,
                letterSpacing: .7,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFF08765D),
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              '₹${session.workspaceSettlementBalance}',
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 36,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Available settlement',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '₹${session.workspaceSalesToday} completed sales today',
              style: const TextStyle(color: MoolColors.muted),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpen,
                child: const Text('Review settlement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    return Padding(
      key: const Key('work-activity-ready'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Row(
            children: [
              _LiveDot(color: Color(0xFF08765D)),
              SizedBox(width: 8),
              Text(
                'STORE LIVE',
                style: TextStyle(
                  color: Color(0xFF08765D),
                  fontSize: 11,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF000080), Color(0xFF3949C6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: MoolColors.navy.withValues(alpha: .22),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready for customer activity',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'New orders and time-sensitive store work will rise here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MoolColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const Spacer(),
          const Text(
            'Swipe through live work · Completed activity moves to history',
            textAlign: TextAlign.center,
            style: TextStyle(color: MoolColors.muted, fontSize: 9.5),
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

class _LiveStatusBubbleRail extends StatelessWidget {
  const _LiveStatusBubbleRail({
    required this.session,
    required this.onOrders,
    required this.onPacking,
    required this.onDelivery,
    required this.onStock,
    required this.onMoney,
  });

  final WorkSession session;
  final VoidCallback onOrders;
  final VoidCallback onPacking;
  final VoidCallback onDelivery;
  final VoidCallback onStock;
  final VoidCallback onMoney;

  @override
  Widget build(BuildContext context) {
    final packing = session.workspaceOrderStage == 'Preparing';
    final delivery =
        const {
          'Ready',
          'Delivery requested',
        }.contains(session.workspaceOrderStage) &&
        session.workspaceOrderNeedsDelivery;
    return Column(
      key: const Key('work-live-status-bubbles'),
      children: [
        _ActivityBubble(
          icon: Icons.receipt_long_outlined,
          label: 'Orders',
          count: session.hasActiveWorkspaceOrder ? 1 : 0,
          active: session.hasActiveWorkspaceOrder && !packing && !delivery,
          onTap: onOrders,
        ),
        const SizedBox(height: 10),
        _ActivityBubble(
          icon: Icons.inventory_rounded,
          label: 'Packing',
          count: packing ? 1 : 0,
          active: packing,
          onTap: onPacking,
        ),
        const SizedBox(height: 10),
        _ActivityBubble(
          icon: Icons.delivery_dining_outlined,
          label: 'Delivery',
          count: delivery ? 1 : 0,
          active: delivery,
          onTap: onDelivery,
        ),
        const SizedBox(height: 10),
        _ActivityBubble(
          icon: Icons.inventory_2_outlined,
          label: 'Stock',
          count: session.workspaceLowStockCount,
          active: session.workspaceLowStockCount > 0,
          onTap: onStock,
        ),
        const SizedBox(height: 10),
        _ActivityBubble(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Money',
          count: session.workspaceSettlementBalance > 0 ? 1 : 0,
          active: session.workspaceSettlementBalance > 0,
          onTap: onMoney,
        ),
      ],
    );
  }
}

class _ActivityBubble extends StatelessWidget {
  const _ActivityBubble({
    required this.icon,
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label${count > 0 ? ': $count' : ''}',
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          width: active ? 50 : 44,
          height: active ? 50 : 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? MoolColors.navy : Colors.white,
            border: Border.all(
              color: active ? MoolColors.navy : const Color(0xFFDCE2F2),
            ),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x22000080),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: active ? Colors.white : MoolColors.muted,
                      size: 16,
                    ),
                    const SizedBox(height: 1),
                    SizedBox(
                      width: 36,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            color: active ? Colors.white : MoolColors.muted,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 17,
                    height: 17,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: MoolColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
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

class _FloatingStoreCommandDock extends StatelessWidget {
  const _FloatingStoreCommandDock({
    required this.onNewSale,
    required this.onDeliver,
    required this.onBuyStock,
    required this.onGroupBulk,
  });

  final VoidCallback onNewSale;
  final VoidCallback onDeliver;
  final VoidCallback onBuyStock;
  final VoidCallback onGroupBulk;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('work-floating-command-dock'),
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _FloatingCommand(
          keyName: 'work-quick-new-sale',
          icon: Icons.point_of_sale_rounded,
          label: 'New sale',
          onTap: onNewSale,
        ),
        _FloatingCommand(
          keyName: 'work-quick-delivery',
          icon: Icons.delivery_dining_rounded,
          label: 'Deliver',
          onTap: onDeliver,
        ),
        _FloatingCommand(
          keyName: 'work-quick-buy',
          icon: Icons.shopping_bag_rounded,
          label: 'Buy stock',
          onTap: onBuyStock,
        ),
        _FloatingCommand(
          keyName: 'work-quick-group-buy',
          icon: Icons.groups_2_rounded,
          label: 'Group bulk',
          onTap: onGroupBulk,
        ),
      ],
    );
  }
}

class _FloatingCommand extends StatelessWidget {
  const _FloatingCommand({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              key: Key(keyName),
              elevation: 9,
              shadowColor: const Color(0x22000080),
              color: MoolColors.navy,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(icon, color: Colors.white, size: 21),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessDrawerButton extends StatelessWidget {
  const _BusinessDrawerButton({
    required this.onCustomers,
    required this.onMoney,
    required this.onGrow,
    required this.onPreview,
  });

  final VoidCallback onCustomers;
  final VoidCallback onMoney;
  final VoidCallback onGrow;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('work-business-drawer'),
      color: MoolColors.navy,
      elevation: 9,
      shadowColor: const Color(0x22000080),
      shape: const CircleBorder(),
      child: Tooltip(
        message: 'Customers, Money and Grow',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (context) => _BusinessDrawerSheet(
              onCustomers: onCustomers,
              onMoney: onMoney,
              onGrow: onGrow,
              onPreview: onPreview,
            ),
          ),
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.apps_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _BusinessDrawerSheet extends StatelessWidget {
  const _BusinessDrawerSheet({
    required this.onCustomers,
    required this.onMoney,
    required this.onGrow,
    required this.onPreview,
  });

  final VoidCallback onCustomers;
  final VoidCallback onMoney;
  final VoidCallback onGrow;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    void open(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    return SafeArea(
      child: Padding(
        key: const Key('work-business-drawer-sheet'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 6,
              runSpacing: 8,
              children: [
                _BusinessDrawerAction(
                  icon: Icons.people_alt_outlined,
                  label: 'Customers',
                  onTap: () => open(onCustomers),
                ),
                _BusinessDrawerAction(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Money',
                  onTap: () => open(onMoney),
                ),
                _BusinessDrawerAction(
                  icon: Icons.trending_up_rounded,
                  label: 'Grow',
                  onTap: () => open(onGrow),
                ),
                _BusinessDrawerAction(
                  icon: Icons.visibility_outlined,
                  label: 'Storefront',
                  onTap: () => open(onPreview),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessDrawerAction extends StatelessWidget {
  const _BusinessDrawerAction({
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
      key: Key('work-business-${label.toLowerCase()}'),
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEAF2FF),
              foregroundColor: MoolColors.navy,
              child: Icon(icon),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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

class _LiveCountdownText extends StatelessWidget {
  const _LiveCountdownText({
    required this.deadline,
    required this.fallback,
    required this.style,
  });

  final DateTime? deadline;
  final String fallback;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final deadline = this.deadline;
    var label = fallback;
    if (deadline != null) {
      final remaining = deadline.difference(DateTime.now());
      label = remaining.isNegative
          ? 'Action due'
          : '${remaining.inMinutes.toString().padLeft(2, '0')}:${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
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
                child: Text(actionLabel),
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

class _WorkspaceOperationSurface extends StatelessWidget {
  const _WorkspaceOperationSurface({
    required this.operation,
    required this.session,
    required this.onOpenStore,
    required this.onOpenOperation,
    required this.onOpenRoute,
  });

  final _WorkspaceOperation operation;
  final WorkSession session;
  final VoidCallback onOpenStore;
  final ValueChanged<_WorkspaceOperation> onOpenOperation;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    if (operation == _WorkspaceOperation.orders) {
      return _OrdersDestinationSurface(
        session: session,
        onCreateOrder: () => onOpenOperation(_WorkspaceOperation.counterOrder),
        onOpenDelivery: () => onOpenOperation(_WorkspaceOperation.delivery),
      );
    }
    if (operation == _WorkspaceOperation.counterOrder) {
      return _CounterOrderSurface(
        session: session,
        onArrangeDelivery: () => onOpenOperation(_WorkspaceOperation.delivery),
        onOpenCatalogue: () => onOpenOperation(_WorkspaceOperation.catalogue),
      );
    }
    if (operation == _WorkspaceOperation.catalogue) {
      return _WorkspaceCatalogueSurface(
        session: session,
        onOpenPurchases: () => onOpenOperation(_WorkspaceOperation.sourcing),
        onOpenGroupBuy: () => onOpenOperation(_WorkspaceOperation.groupBuying),
      );
    }
    if (operation == _WorkspaceOperation.groupBuying) {
      return _WorkspaceGroupBuyingSurface(session: session);
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
        onRepeatBasket: () {
          if (session.prepareRepeatWorkspaceOrder()) {
            onOpenOperation(_WorkspaceOperation.counterOrder);
          }
        },
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
      return _WorkspaceBusinessRecordSurface(session: session);
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
      return _WorkspacePaidWorkSurface(session: session);
    }
    if (operation == _WorkspaceOperation.growth) {
      return _GrowDestinationSurface(
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
    _WorkspaceOperation.orders => const [],
    _WorkspaceOperation.catalogue => const [],
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
        title: 'Publish paid work',
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
        actionLabel: 'Review assistance',
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
        actionLabel: 'Review assistance',
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
        actionLabel: 'Review assistance',
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
    required this.onOpenPurchases,
    required this.onOpenGroupBuy,
  });

  final WorkSession session;
  final VoidCallback onOpenPurchases;
  final VoidCallback onOpenGroupBuy;

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
          continue;
        }
        final stamp = DateTime.now().microsecondsSinceEpoch + index;
        imported.add(
          WorkspaceCatalogueItem(
            id: row['id']?.trim().isNotEmpty == true
                ? row['id']!.trim()
                : 'import-$stamp',
            canonicalId: row['canonicalId']?.trim().isNotEmpty == true
                ? row['canonicalId']!.trim()
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
            barcode: row['barcode']?.trim() ?? '',
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
            available: stock > 0,
            publicListing: row['publicListing']?.toLowerCase() != 'false',
          ),
        );
      }
      if (imported.isEmpty) throw const FormatException();
      widget.session.importWorkspaceProducts(imported);
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
        .where((product) => !_lowStockOnly || product.stock <= 5)
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CatalogueCircleAction(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan',
                onTap: _scan,
              ),
              _CatalogueCircleAction(
                icon: Icons.upload_file_rounded,
                label: 'Import',
                onTap: _importCatalogue,
              ),
              _CatalogueCircleAction(
                icon: Icons.add_box_outlined,
                label: 'Add',
                onTap: () => _edit(_blankProduct()),
              ),
              _CatalogueCircleAction(
                icon: Icons.warning_amber_rounded,
                label: 'Low stock',
                active: _lowStockOnly,
                onTap: () => setState(() => _lowStockOnly = !_lowStockOnly),
              ),
              _CatalogueCircleAction(
                icon: Icons.groups_2_outlined,
                label: 'Group bulk',
                onTap: widget.onOpenGroupBuy,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Store catalogue',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: widget.onOpenPurchases,
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Purchases'),
              ),
            ],
          ),
          const Text(
            'Keep customer prices, available stock and delivery details current.',
            style: TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
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
                onPressed: () => _edit(product),
              ),
              const SizedBox(height: 8),
            ],
          if (!_lowStockOnly && available.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Verified catalogue matches',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
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

class _CatalogueCircleAction extends StatelessWidget {
  const _CatalogueCircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: active ? MoolColors.navy : Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x15001B4D),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: active ? Colors.white : MoolColors.navy,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: const TextStyle(
                color: MoolColors.navy,
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
      key: const Key('work-product-editor'),
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
                      'Use verified match',
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

// ignore: unused_element
class _WorkspaceProductRow extends StatelessWidget {
  const _WorkspaceProductRow({
    required this.product,
    required this.owned,
    required this.onPressed,
  });

  final WorkspaceCatalogueItem product;
  final bool owned;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: owned ? Key('work-public-sku-${product.id}') : null,
      child: WorkCard(
        keyName: 'work-catalogue-${owned ? 'owned' : 'master'}-${product.id}',
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEAF2FF),
              foregroundColor: MoolColors.navy,
              child: Text(
                product.brand.substring(0, 1),
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
                    maxLines: 2,
                    style: const TextStyle(
                      color: MoolColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${product.pack} · ${product.sku}',
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 9.5,
                    ),
                  ),
                  Text(
                    owned
                        ? '₹${product.sellingPrice} · ${product.stock} available · ${product.publicListing ? 'Public' : 'Store only'}'
                        : 'MRP ₹${product.mrp ?? product.sellingPrice} · verified match',
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 76,
              child: FilledButton.tonal(
                key: Key(
                  'work-catalogue-${owned ? 'edit' : 'add'}-${product.id}',
                ),
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: FittedBox(child: Text(owned ? 'Edit' : 'Add')),
              ),
            ),
          ],
        ),
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
  String? _error;

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
    final stock = int.tryParse(_stock.text.trim());
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
        available: stock! > 0,
        publicListing: _public,
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
                  const _WorkspaceSectionLabel(
                    title: 'Product identity',
                    detail: 'Shown in customer search and product details',
                  ),
                  const SizedBox(height: MoolSpacing.xs),
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
                  const SizedBox(height: MoolSpacing.sm),
                  const _WorkspaceSectionLabel(
                    title: 'Price and availability',
                    detail: 'Purchase cost stays private',
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  _ResponsiveFieldPair(
                    first: _MoneyField(
                      keyName: 'work-product-purchase-price',
                      controller: _purchase,
                      label: 'Purchase cost',
                    ),
                    second: _MoneyField(
                      keyName: 'work-product-selling-price',
                      controller: _selling,
                      label: 'Customer price',
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  _ResponsiveFieldPair(
                    first: _MoneyField(
                      keyName: 'work-product-mrp',
                      controller: _mrp,
                      label: 'MRP',
                    ),
                    second: _AccessibleWorkTextField(
                      keyName: 'work-product-stock',
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      label: 'Available stock',
                    ),
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
                      label: 'Unit price label',
                      hint: 'For example ₹264/L',
                    ),
                    second: _AccessibleWorkTextField(
                      keyName: 'work-product-minimum-order',
                      controller: _minimumOrder,
                      keyboardType: TextInputType.number,
                      label: 'Minimum order',
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  _AccessibleWorkTextField(
                    keyName: 'work-product-origin',
                    controller: _origin,
                    label: 'Country of origin',
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  const _WorkspaceSectionLabel(
                    title: 'Customer information',
                    detail: 'Used on the public Buy product page',
                  ),
                  const SizedBox(height: MoolSpacing.xs),
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
                    label: 'Product image description',
                  ),
                  SwitchListTile.adaptive(
                    key: const Key('work-product-public'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show this product to customers'),
                    subtitle: const Text(
                      'Purchase cost remains private. Customer price, stock and product information are published.',
                    ),
                    value: _public,
                    onChanged: (value) => setState(() => _public = value),
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
      value: widget.controller.text,
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
    final query = TextEditingController();
    WorkspaceCatalogueItem? selected;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final normalized = query.text.trim().toLowerCase();
          final matches = _availableProducts
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
                      controller: query,
                      autofocus: true,
                      onChanged: (_) => setSheetState(() {}),
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
                          onTap: () {
                            selected = product;
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    query.dispose();
    if (selected == null || !mounted) return;
    setState(() {
      _productId = selected!.id;
      if (_specification.text.isEmpty) {
        _specification.text = '${selected!.variant} · ${selected!.pack}';
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
    final stageMatches = switch (_filter) {
      'Live' => session.hasActiveWorkspaceOrder,
      'New' => session.workspaceOrderStage == 'Confirmed',
      'Packing' => session.workspaceOrderStage == 'Preparing',
      'Ready' => const {
        'Ready',
        'Ready for pickup',
        'Delivery requested',
      }.contains(session.workspaceOrderStage),
      'Done' => const {
        'Completed',
        'Cancelled',
      }.contains(session.workspaceOrderStage),
      _ => false,
    };
    return Container(
      key: const Key('work-orders-destination'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9FAFF), Color(0xFFEEF2FF)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Orders',
                    style: TextStyle(
                      color: MoolColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  session.hasActiveWorkspaceOrder ? '1 live' : 'No live order',
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final filter in const [
                  'Live',
                  'New',
                  'Packing',
                  'Ready',
                  'Done',
                ])
                  ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) {
                      widget.session.setWorkspaceOrderFilter(filter);
                      setState(() => _filter = filter);
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: stageMatches
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                    children: [
                      _LiveOrderTicket(
                        session: session,
                        onOpenDelivery: widget.onOpenDelivery,
                      ),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 38,
                            backgroundColor: Color(0xFFE5EAFF),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              color: MoolColors.navy,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No $_filter order needs action',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: MoolColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _filter == 'Done'
                                ? 'Completed and cancelled orders will appear here.'
                                : 'Orders move here automatically as their status changes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: MoolColors.muted),
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
                label: const Text('Record store order'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveOrderTicket extends StatelessWidget {
  const _LiveOrderTicket({required this.session, required this.onOpenDelivery});

  final WorkSession session;
  final VoidCallback onOpenDelivery;

  @override
  Widget build(BuildContext context) {
    final stage = session.workspaceOrderStage;
    final nextAction = switch (stage) {
      'Confirmed' => 'Start packing',
      'Preparing' => 'Mark ready',
      'Ready' when session.workspaceOrderNeedsDelivery => 'Arrange delivery',
      'Ready' => 'Complete pickup',
      'Delivery requested' => 'Track delivery',
      _ => 'Review',
    };
    return Material(
      key: const Key('work-live-order-ticket'),
      color: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x1F001B4D),
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LiveDot(
                  color: stage == 'Confirmed'
                      ? MoolColors.orange
                      : MoolColors.navy,
                ),
                const SizedBox(width: 7),
                Text(
                  stage.toUpperCase(),
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 10,
                    letterSpacing: .6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${session.workspaceOrderAmount}',
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              session.workspaceOrderCustomer,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${session.workspaceOrderSource} · ${session.workspaceOrderPayment} · ${session.workspaceOrderFulfilment}',
              style: const TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                session.workspaceOrderItems,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    stage == 'Ready' && session.workspaceOrderNeedsDelivery
                    ? onOpenDelivery
                    : session.advanceWorkspaceOrder,
                child: Text(nextAction),
              ),
            ),
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

class _CustomersDestinationSurface extends StatelessWidget {
  const _CustomersDestinationSurface({
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF080C34), Color(0xFF141B73)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            'AVAILABLE SETTLEMENT',
            style: TextStyle(
              color: Color(0xFFBFC6FF),
              fontSize: 10,
              letterSpacing: .8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${session.workspaceSettlementEligible}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _MoneyDestinationFact(
                label: 'Sales today',
                value: '₹${session.workspaceSalesToday}',
              ),
              _MoneyDestinationFact(
                label: 'Pending fulfilment',
                value: '₹$pendingFulfilment',
              ),
              _MoneyDestinationFact(
                label: 'Requested',
                value: '₹${session.workspaceSettlementRequested}',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final period in const [
                'Today',
                'Week',
                'Month',
                'Financial year',
              ])
                ChoiceChip(
                  label: Text(period),
                  selected: session.workspaceMoneyPeriod == period,
                  onSelected: (_) => session.setWorkspaceMoneyPeriod(period),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                _MoneyDestinationLine(
                  label: 'Completed sales',
                  value: '${session.workspaceCompletedSalesCount}',
                ),
                _MoneyDestinationLine(
                  label: 'Platform and fulfilment adjustments',
                  value: '₹${session.workspacePlatformAdjustments}',
                ),
                _MoneyDestinationLine(
                  label: 'Refunds and holds',
                  value: '₹${session.workspaceRefunds}',
                ),
                _MoneyDestinationLine(
                  label: 'Tax withheld',
                  value: '₹${session.workspaceTaxWithheld}',
                ),
              ],
            ),
          ),
          if (session.workspaceSettlementReference case final reference?) ...[
            const SizedBox(height: 14),
            Text(
              'Latest settlement request · $reference',
              style: const TextStyle(color: Color(0xFFBFC6FF)),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Sales and payment ledger',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (orders.isEmpty)
            const Text(
              'No sale falls within this period.',
              style: TextStyle(color: Color(0xFFBFC6FF)),
            )
          else
            for (final order in orders)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Icons.point_of_sale_outlined,
                  color: Color(0xFFBFC6FF),
                ),
                title: Text(
                  '${order.id} · ₹${order.amount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  '${order.customer} · ${order.payment} · ${order.stage} · ${order.createdAt.day}/${order.createdAt.month}',
                  style: const TextStyle(color: Color(0xFFBFC6FF)),
                ),
              ),
          const SizedBox(height: 18),
          const Text(
            'Settlement activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (settlementActivity.isEmpty)
            const Text(
              'Completed sales and settlement requests will appear here.',
              style: TextStyle(color: Color(0xFFBFC6FF)),
            )
          else
            for (final entry in settlementActivity)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFFBFC6FF),
                ),
                title: Text(
                  entry.message,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${entry.time.day}/${entry.time.month} · ${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Color(0xFFBFC6FF)),
                ),
              ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: session.workspaceSettlementEligible > 0 && !session.busy
                ? () => _showWorkspaceSettlementReview(context, session)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF52E5A3),
              foregroundColor: const Color(0xFF071B19),
            ),
            child: const Text('Review and request settlement'),
          ),
        ],
      ),
    );
  }
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
                    const _ProductPreviewLine(
                      label: 'Payout destination',
                      value: 'Workspace bank account',
                    ),
                    _ProductPreviewLine(
                      label: 'Platform adjustments',
                      value: '₹${session.workspacePlatformAdjustments}',
                    ),
                    _ProductPreviewLine(
                      label: 'Refunds and holds',
                      value: '₹${session.workspaceRefunds}',
                    ),
                    _ProductPreviewLine(
                      label: 'Tax withheld',
                      value: '₹${session.workspaceTaxWithheld}',
                    ),
                    const _ProductPreviewLine(
                      label: 'Expected processing',
                      value: 'Up to 2 working days',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('work-settlement-confirm'),
                onPressed: session.busy
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
  controller.dispose();
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
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFBFC6FF), fontSize: 9),
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
              style: const TextStyle(color: Color(0xFFBFC6FF)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
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
        const SizedBox(height: 14),
        const WorkCard(
          color: Color(0xFFF4F6FF),
          child: Text(
            'Customer serviceability, delivery fee and free-delivery threshold must be confirmed before checkout.',
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
          detail: 'Owner-controlled access to daily Store operations',
        ),
        const SizedBox(height: 12),
        WorkCard(
          child: SwitchListTile.adaptive(
            key: const Key('work-staff-access-toggle'),
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
            title: const Text('Allow staff access'),
            subtitle: const Text(
              'Staff permissions are granted individually; owner settlement and business records remain private.',
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
  const _WorkspaceBusinessRecordSurface({required this.session});

  final WorkSession session;

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
                      'Active MoolSocial business partner',
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
                    Text(workspace?.profileLabel ?? 'Store Workspace'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _WorkspaceSectionLabel(
          title: 'Business record',
          detail: 'Approved details currently used for Store operations',
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
                  '${session.addedProofs.length} document references available',
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
  DateTime? _validUntil;

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
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
    return ListView(
      key: const Key('work-store-offers-screen'),
      padding: const EdgeInsets.all(18),
      children: [
        const _WorkspaceSectionLabel(
          title: 'Bring customers back',
          detail: 'Publish a clear Store offer, then promote it if needed',
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const Key('work-offer-publish'),
          onPressed:
              _title.text.trim().isEmpty ||
                  _detail.text.trim().isEmpty ||
                  _validUntil == null
              ? null
              : () {
                  widget.session.addWorkspaceOffer(
                    title: _title.text,
                    detail: _detail.text,
                    validUntil: _validUntil!,
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

class _WorkspacePaidWorkSurface extends StatefulWidget {
  const _WorkspacePaidWorkSurface({required this.session});

  final WorkSession session;

  @override
  State<_WorkspacePaidWorkSurface> createState() =>
      _WorkspacePaidWorkSurfaceState();
}

class _WorkspacePaidWorkSurfaceState extends State<_WorkspacePaidWorkSurface> {
  final TextEditingController _position = TextEditingController();
  final TextEditingController _work = TextEditingController();
  final TextEditingController _candidate = TextEditingController();
  late final TextEditingController _location = TextEditingController(
    text: widget.session.activeWorkspace?.area ?? widget.session.workArea,
  );
  final TextEditingController _people = TextEditingController(text: '1');
  final TextEditingController _amount = TextEditingController();
  String _format = 'Assignment';
  DateTime? _deadline;
  String? _error;

  @override
  void dispose() {
    _position.dispose();
    _work.dispose();
    _candidate.dispose();
    _location.dispose();
    _people.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
    );
    if (selected != null) setState(() => _deadline = selected);
  }

  Future<void> _publish() async {
    final people = int.tryParse(_people.text.trim());
    final amount = int.tryParse(_amount.text.trim());
    final error = _position.text.trim().isEmpty
        ? 'Enter the paid position or assignment.'
        : _work.text.trim().isEmpty
        ? 'Explain the work to be completed.'
        : _candidate.text.trim().isEmpty
        ? 'Explain the required experience or qualification.'
        : _location.text.trim().isEmpty
        ? 'Enter the work location.'
        : people == null || people <= 0
        ? 'Enter the number of people required.'
        : amount == null || amount <= 0
        ? 'Enter the funded payment amount.'
        : _deadline == null
        ? 'Choose the final application deadline.'
        : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final created = await widget.session.createWorkspacePaidRequirement(
      position: _position.text,
      work: _work.text,
      candidateRequirement: _candidate.text,
      location: _location.text,
      peopleNeeded: people!,
      paymentAmount: amount!,
      paymentFormat: _format,
      deadline: _deadline!,
    );
    if (mounted) {
      setState(() => _error = created ? null : widget.session.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reference = widget.session.workspacePaidRequirementReference;
    return ListView(
      key: const Key('work-paid-requirement-screen'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        const _WorkspaceSectionLabel(
          title: 'Publish funded Store work',
          detail: 'Candidates see the requirement, eligibility and payment',
        ),
        const SizedBox(height: 10),
        _AccessibleWorkTextField(
          keyName: 'work-paid-position',
          controller: _position,
          label: 'Position or assignment',
        ),
        const SizedBox(height: 8),
        _AccessibleWorkTextField(
          keyName: 'work-paid-work',
          controller: _work,
          maxLines: 2,
          label: 'Work to be completed',
        ),
        const SizedBox(height: 8),
        _AccessibleWorkTextField(
          keyName: 'work-paid-candidate',
          controller: _candidate,
          maxLines: 2,
          label: 'Experience or qualification',
        ),
        const SizedBox(height: 8),
        _AccessibleWorkTextField(
          keyName: 'work-paid-location',
          controller: _location,
          label: 'City, area or pincode',
        ),
        const SizedBox(height: 8),
        _ResponsiveFieldPair(
          first: _NumberField(
            keyName: 'work-paid-people',
            controller: _people,
            label: 'People needed',
          ),
          second: _MoneyField(
            keyName: 'work-paid-amount',
            controller: _amount,
            label: 'Payment amount',
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Assignment', label: Text('Per task')),
            ButtonSegment(value: 'Hourly', label: Text('Hourly')),
            ButtonSegment(value: 'Monthly', label: Text('Monthly')),
          ],
          selected: {_format},
          onSelectionChanged: (value) => setState(() => _format = value.first),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('work-paid-deadline'),
          onPressed: _pickDeadline,
          icon: const Icon(Icons.event_outlined),
          label: Text(
            _deadline == null
                ? 'Choose final deadline'
                : 'Deadline ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFB42318),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('work-paid-publish'),
          onPressed: widget.session.busy ? null : _publish,
          icon: const Icon(Icons.publish_outlined),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              reference == null
                  ? 'Fund and publish to Earn Today'
                  : 'Published · $reference',
            ),
          ),
        ),
      ],
    );
  }
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
                label: 'Publish paid work',
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
    required this.onArrangeDelivery,
    required this.onOpenCatalogue,
  });

  final WorkSession session;
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
      widget.onArrangeDelivery();
    }
  }

  Future<void> _review() async {
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
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
              child: SizedBox(
                height: media.size.height * .56,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    18,
                    0,
                    18,
                    media.viewPadding.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete this order',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('work-order-save'),
                          onPressed: () {
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
                                ? 'Confirm customer order'
                                : 'Confirm and arrange delivery',
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

  @override
  Widget build(BuildContext context) {
    final validPhone =
        _customer.text.replaceAll(RegExp(r'\D'), '').length >= 10;
    final canReview = validPhone && widget.session.workspaceOrderItemCount > 0;
    return Container(
      key: const Key('work-dashboard-counter-order-screen'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9FAFF), Color(0xFFEEF2FF)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _fulfilment == 'At the shop' ? 'New sale' : 'Deliver order',
                    style: const TextStyle(
                      color: MoolColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _fulfilment == 'At the shop'
                        ? 'Counter, Phone or Chat sale from your live catalogue'
                        : 'Record the customer order before requesting delivery',
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 10.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final source in const ['Counter', 'Phone', 'Chat'])
                      ChoiceChip(
                        key: Key('work-sell-source-${source.toLowerCase()}'),
                        label: Text(source),
                        selected: _source == source,
                        onSelected: (_) => setState(() => _source = source),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _AccessibleWorkTextField(
                  keyName: 'work-order-customer',
                  controller: _customer,
                  label: 'Customer mobile number',
                  hint: 'Number used for order updates',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Add products',
                    style: TextStyle(
                      color: MoolColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Scan barcode',
                  onPressed: _scanProduct,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                ),
                IconButton(
                  tooltip: 'Search catalogue',
                  onPressed: widget.onOpenCatalogue,
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.session.workspaceCatalogueItems.isEmpty
                ? Center(
                    child: FilledButton.tonalIcon(
                      onPressed: widget.onOpenCatalogue,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add products to your catalogue'),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 160,
                        ),
                    itemCount: widget.session.workspaceCatalogueItems.length,
                    itemBuilder: (context, index) {
                      final product =
                          widget.session.workspaceCatalogueItems[index];
                      return _SaleProductTile(
                        product: product,
                        session: widget.session,
                      );
                    },
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                key: const Key('work-order-error'),
                style: const TextStyle(
                  color: Color(0xFFB42318),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          Material(
            color: Colors.white,
            elevation: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.session.workspaceOrderItemCount} products',
                            style: const TextStyle(color: MoolColors.muted),
                          ),
                          Text(
                            '₹${widget.session.workspaceOrderTotal}',
                            style: const TextStyle(
                              color: MoolColors.navy,
                              fontSize: 24,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: FilledButton.icon(
                        key: const Key('work-order-review'),
                        onPressed: canReview ? _review : null,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          _fulfilment == 'At the shop'
                              ? 'Review sale'
                              : 'Review delivery',
                        ),
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

class _SaleProductTile extends StatelessWidget {
  const _SaleProductTile({required this.product, required this.session});

  final WorkspaceCatalogueItem product;
  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final quantity = session.workspaceOrderQuantities[product.id] ?? 0;
    return Material(
      color: Colors.white,
      elevation: quantity > 0 ? 8 : 2,
      shadowColor: const Color(0x1A001B4D),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: Key('work-order-add-${product.id}'),
        borderRadius: BorderRadius.circular(22),
        onTap: () => session.adjustWorkspaceOrderQuantity(product.id, 1),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5EAFF),
                child: Text(
                  product.brand.substring(0, 1),
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),
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
                product.pack,
                style: const TextStyle(color: MoolColors.muted, fontSize: 9.5),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '₹${product.sellingPrice}',
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (quantity > 0)
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: MoolColors.navy,
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.add_circle_rounded,
                      color: MoolColors.navy,
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer receives the order',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final mode in const [
              'At the shop',
              'Own delivery',
              'Mool delivery',
            ])
              ChoiceChip(
                key: Key(
                  'work-order-fulfilment-${mode.toLowerCase().replaceAll(' ', '-')}',
                ),
                label: Text(mode),
                selected: fulfilment == mode,
                onSelected: (selected) {
                  if (selected) onFulfilmentChanged(mode);
                },
              ),
          ],
        ),
        if (fulfilment != 'At the shop') ...[
          const SizedBox(height: MoolSpacing.xs),
          TextField(
            key: const Key('work-order-address'),
            controller: addressController,
            minLines: 2,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Customer delivery address',
              hintText: 'House, street, area and landmark',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
        ],
        const SizedBox(height: MoolSpacing.xs),
        const Text('Payment', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final option in const [
              'Cash',
              'UPI',
              'Pay request',
              'On delivery',
              'Customer due',
            ])
              ChoiceChip(
                key: Key(
                  'work-order-payment-${option.toLowerCase().replaceAll(' ', '-')}',
                ),
                label: Text(option),
                selected: payment == option,
                onSelected: (selected) {
                  if (selected) onPaymentChanged(option);
                },
              ),
          ],
        ),
      ],
    );
  }
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
    required this.onAcceptingChanged,
    required this.onVisibilityChanged,
    required this.onFulfilmentChanged,
    required this.onBusyMinutesChanged,
    required this.onReopensChanged,
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
  final ValueChanged<bool> onAcceptingChanged;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<String> onFulfilmentChanged;
  final ValueChanged<int> onBusyMinutesChanged;
  final ValueChanged<String> onReopensChanged;
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
          detail: 'Controls you may change during the trading day',
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
              const ListTile(
                leading: Icon(Icons.schedule_rounded),
                title: Text('Today’s hours'),
                subtitle: Text('8:00 AM–10:00 PM'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              const ListTile(
                leading: Icon(Icons.layers_outlined),
                title: Text('Maximum active orders'),
                subtitle: Text('8 orders'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              const ListTile(
                leading: Icon(Icons.notifications_active_outlined),
                title: Text('Order alerts'),
                subtitle: Text('Sound and vibration on'),
                trailing: Icon(Icons.chevron_right_rounded),
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
          title: 'Fulfilment',
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
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenStatus;
  final ValueChanged<String> onDismiss;

  @override
  Widget build(BuildContext context) {
    final alerts = _workspaceAlerts(session);
    if (alerts.isEmpty) {
      return WorkEmptyState(
        keyName: 'work-dashboard-alerts-empty',
        title: 'No urgent store action',
        detail:
            'Order, delivery, money and stock alerts will appear here when they need your attention.',
        actionLabel: 'Review customer orders',
        onAction: onOpenOrders,
      );
    }
    return ListView.separated(
      key: const Key('work-dashboard-alerts-screen'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      itemCount: alerts.length,
      separatorBuilder: (_, _) => const SizedBox(height: MoolSpacing.xs),
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return WorkCard(
          keyName: 'work-alert-${alert.id}',
          color: alert.requiredAction ? const Color(0xFFFFF7EA) : Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: alert.requiredAction
                    ? const Color(0xFFFFE6C2)
                    : const Color(0xFFEAF2FF),
                foregroundColor: alert.requiredAction
                    ? const Color(0xFF9A4A00)
                    : MoolColors.navy,
                child: Icon(alert.icon),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alert.detail,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    TextButton.icon(
                      key: Key('work-alert-action-${alert.id}'),
                      onPressed: () {
                        if (alert.id == 'store-paused') {
                          onOpenStatus();
                        } else if (alert.operation != null) {
                          onOpenOperation(alert.operation!);
                        } else {
                          onOpen(alert.route!);
                        }
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                      label: Text(alert.actionLabel),
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
        );
      },
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
