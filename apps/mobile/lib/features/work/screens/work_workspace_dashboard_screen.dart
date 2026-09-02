import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_service_home.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/profile/global_profile_panel_v2.dart';
import '../widgets/work_widgets.dart';
import '../work_models.dart';
import '../work_session.dart';

class WorkWorkspaceDashboardScreen extends StatefulWidget {
  const WorkWorkspaceDashboardScreen({required this.session, super.key});

  final WorkSession session;

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
  String _draftFulfilmentMode = 'Delivery and pickup';
  int _draftBusyMinutes = 0;
  String _draftReopensAt = '';
  _WorkspaceOperation _operation = _WorkspaceOperation.orders;

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
    final title = switch (_view) {
      _WorkspaceControlView.dashboard => workspace.name,
      _WorkspaceControlView.search => 'Search your store',
      _WorkspaceControlView.status => 'Store availability',
      _WorkspaceControlView.alerts => 'Needs your attention',
      _WorkspaceControlView.operation => _operation.title,
    };
    final subtitle = switch (_view) {
      _WorkspaceControlView.dashboard => '${profile.label} · ${workspace.area}',
      _WorkspaceControlView.search =>
        'Find orders, products, customers or business records',
      _WorkspaceControlView.status =>
        'Choose when customers can order and how you fulfil',
      _WorkspaceControlView.alerts =>
        'Resolve the most important store actions first',
      _WorkspaceControlView.operation => _operation.subtitle,
    };
    final bottomAction = switch (_view) {
      _WorkspaceControlView.status => WorkPrimaryButton(
        keyName: 'work-status-save',
        label: 'Save store availability',
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
      _ => 'store',
    };
    final storeActions = [
      MoolLocalNavigationAction(
        keyName: 'work-store-home',
        id: 'store',
        label: 'Store',
        icon: Icons.storefront_outlined,
        onPressed: storeActiveId == 'store' ? null : _showDashboard,
      ),
      MoolLocalNavigationAction(
        keyName: 'work-store-orders',
        id: 'orders',
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        onPressed: storeActiveId == 'orders'
            ? null
            : () => _showOperation(_WorkspaceOperation.orders),
      ),
      MoolLocalNavigationAction(
        keyName: 'work-store-sell',
        id: 'sell',
        label: 'Sell',
        icon: Icons.point_of_sale_outlined,
        onPressed: storeActiveId == 'sell'
            ? null
            : () => _showOperation(_WorkspaceOperation.counterOrder),
      ),
      MoolLocalNavigationAction(
        keyName: 'work-store-stock',
        id: 'stock',
        label: 'Stock',
        icon: Icons.inventory_2_outlined,
        onPressed: storeActiveId == 'stock'
            ? null
            : () => _showOperation(_WorkspaceOperation.catalogue),
      ),
    ];
    final storeRootSurface =
        _view == _WorkspaceControlView.dashboard ||
        _view == _WorkspaceControlView.operation;

    return WorkPageScaffold(
      session: session,
      title: title,
      subtitle: subtitle,
      headerTitle: storeRootSurface
          ? _WorkspaceDashboardHeader(
              session: session,
              onSearch: _showSearch,
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
      onBack: _view == _WorkspaceControlView.dashboard ? null : _showDashboard,
      bottomAction: bottomAction,
      body: switch (_view) {
        _WorkspaceControlView.dashboard => _StoreControlDashboard(
          session: session,
          onStatus: _showStatus,
          onQuickState: (state) => _applyQuickStoreState(context, state),
          onOpenOperation: _showOperation,
        ),
        _WorkspaceControlView.search => _WorkspaceSearchSurface(
          controller: _searchController,
          focusNode: _searchFocus,
          query: session.workspaceSearchQuery,
          onChanged: session.updateWorkspaceSearch,
          onClear: _clearSearch,
          onOpen: _showOperation,
        ),
        _WorkspaceControlView.status => _WorkspaceStatusSurface(
          acceptingOrders: _draftAcceptingOrders,
          fulfilmentMode: _draftFulfilmentMode,
          busyMinutes: _draftBusyMinutes,
          reopensAt: _draftReopensAt,
          onAcceptingChanged: (value) => setState(() {
            _draftAcceptingOrders = value;
            if (!value && _draftReopensAt.isEmpty) {
              _draftReopensAt = 'Tomorrow at 8:00 AM';
            }
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
        ),
        _WorkspaceControlView.alerts => _WorkspaceAlertsSurface(
          session: session,
          onOpen: (route) => context.push(route),
          onOpenOperation: _showOperation,
          onOpenOrders: () => _showOperation(_WorkspaceOperation.orders),
          onOpenStatus: _showStatus,
          onDismiss: session.dismissWorkspaceAlert,
        ),
        _WorkspaceControlView.operation => _WorkspaceOperationSurface(
          operation: _operation,
          session: session,
          onOpenStore: _showDashboard,
          onOpenOperation: _showOperation,
          onOpenRoute: (route) => context.push(route),
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
      _operation = operation;
      _view = _WorkspaceControlView.operation;
    });
  }

  void _applyQuickStoreState(BuildContext context, _QuickStoreState state) {
    final ready =
        session.retailerSetupSaved ||
        session.reviewStage == WorkReviewStage.live;
    if (!ready && state != _QuickStoreState.closed) {
      session.beginRetailerSetup();
      context.push('/app/work/retailer/setup');
      return;
    }
    switch (state) {
      case _QuickStoreState.open:
        session.setWorkspaceVisibility(true);
        session.saveWorkspaceAvailability(
          acceptingOrders: true,
          fulfilmentMode: session.workspaceFulfilmentMode,
          busyMinutes: 0,
          reopensAt: '',
        );
      case _QuickStoreState.busy:
        session.setWorkspaceVisibility(true);
        session.saveWorkspaceAvailability(
          acceptingOrders: true,
          fulfilmentMode: session.workspaceFulfilmentMode,
          busyMinutes: 20,
          reopensAt: '',
        );
      case _QuickStoreState.paused:
        session.setWorkspaceVisibility(true);
        session.saveWorkspaceAvailability(
          acceptingOrders: false,
          fulfilmentMode: session.workspaceFulfilmentMode,
          busyMinutes: 0,
          reopensAt: 'In 1 hour',
        );
      case _QuickStoreState.closed:
        session.setWorkspaceVisibility(false);
        session.saveWorkspaceAvailability(
          acceptingOrders: false,
          fulfilmentMode: session.workspaceFulfilmentMode,
          busyMinutes: 0,
          reopensAt: '',
        );
    }
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

  void _clearSearch() {
    _searchController.clear();
    session.updateWorkspaceSearch('');
    _searchFocus.requestFocus();
  }

  void _saveAvailability() {
    session.saveWorkspaceAvailability(
      acceptingOrders: _draftAcceptingOrders,
      fulfilmentMode: _draftFulfilmentMode,
      busyMinutes: _draftBusyMinutes,
      reopensAt: _draftReopensAt,
    );
    setState(() => _view = _WorkspaceControlView.dashboard);
  }
}

enum _WorkspaceControlView { dashboard, search, status, alerts, operation }

enum _WorkspaceOperation {
  orders,
  counterOrder,
  catalogue,
  delivery,
  customers,
  payments,
  books,
  sourcing,
  services,
  settings,
  preview,
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
    _WorkspaceOperation.services => 'Business services',
    _WorkspaceOperation.settings => 'Workspace settings',
    _WorkspaceOperation.preview => 'Customer store preview',
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
    _WorkspaceOperation.services =>
      'GST, tax, bookkeeping and audit assistance',
    _WorkspaceOperation.settings =>
      'Store details, documents and additional Workspaces',
    _WorkspaceOperation.preview =>
      'See exactly what customers can discover and order',
  };
}

enum _QuickStoreState { open, busy, paused, closed }

class _WorkspaceDashboardHeader extends StatelessWidget {
  const _WorkspaceDashboardHeader({
    required this.session,
    required this.onSearch,
    required this.onAlerts,
    required this.onProfile,
  });

  final WorkSession session;
  final VoidCallback onSearch;
  final VoidCallback onAlerts;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('work-dashboard-inline-header'),
      children: [
        Expanded(
          child: Semantics(
            key: const Key('work-dashboard-search'),
            button: true,
            label: 'Search orders, products and customers',
            onTap: onSearch,
            excludeSemantics: true,
            child: MoolServiceSearchField(
              hintText: 'Search orders, products or customers',
              readOnly: true,
              onTap: onSearch,
            ),
          ),
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
    );
  }
}

class _StoreControlDashboard extends StatelessWidget {
  const _StoreControlDashboard({
    required this.session,
    required this.onStatus,
    required this.onQuickState,
    required this.onOpenOperation,
  });

  final WorkSession session;
  final VoidCallback onStatus;
  final ValueChanged<_QuickStoreState> onQuickState;
  final ValueChanged<_WorkspaceOperation> onOpenOperation;

  @override
  Widget build(BuildContext context) {
    final alertCount = _workspaceAlerts(session).length;
    final storeReady =
        session.retailerSetupSaved ||
        session.reviewStage == WorkReviewStage.live;
    return Column(
      key: const Key('work-workspace-dashboard'),
      children: [
        _StoreContextRail(
          onToday: null,
          onCustomers: () => onOpenOperation(_WorkspaceOperation.customers),
          onMoney: () => onOpenOperation(_WorkspaceOperation.payments),
          onGrow: () => onOpenOperation(_WorkspaceOperation.sourcing),
        ),
        _StoreSignalStrip(
          session: session,
          ready: storeReady,
          onStateSelected: onQuickState,
          onStatus: onStatus,
          onPreview: () => onOpenOperation(_WorkspaceOperation.preview),
        ),
        Expanded(
          child: ListView(
            key: const Key('work-store-today-canvas'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              if (!storeReady) ...[
                _StoreActionRow(
                  keyName: 'work-dashboard-priority-action',
                  urgency: _StoreActionUrgency.attention,
                  icon: Icons.rocket_launch_outlined,
                  eyebrow: 'ACTION REQUIRED',
                  title: 'Finish store setup',
                  detail: 'Add products and customer fulfilment choices.',
                  actionLabel: 'Continue',
                  onPressed: () {
                    session.beginRetailerSetup();
                    context.push('/app/work/retailer/setup');
                  },
                ),
                const Divider(height: 1),
              ],
              _TodayOrderAction(
                session: session,
                onOrders: () => onOpenOperation(_WorkspaceOperation.orders),
                onSell: () => onOpenOperation(_WorkspaceOperation.counterOrder),
                onDelivery: () => onOpenOperation(_WorkspaceOperation.delivery),
              ),
              const Divider(height: 1),
              _StoreActionRow(
                keyName: 'work-dashboard-products',
                urgency: session.workspaceLowStockCount > 0
                    ? _StoreActionUrgency.attention
                    : _StoreActionUrgency.normal,
                icon: Icons.inventory_2_outlined,
                eyebrow: session.workspaceLowStockCount > 0
                    ? 'STOCK ATTENTION'
                    : 'STOCK',
                title: session.workspaceLowStockCount > 0
                    ? '${session.workspaceLowStockCount} products running low'
                    : '${session.workspaceCatalogueItems.length} products',
                detail: session.workspaceCatalogueItems.isEmpty
                    ? 'Add products to begin selling.'
                    : session.workspaceLowStockCount > 0
                    ? 'Review quantity before accepting the next order.'
                    : 'No low-stock action right now.',
                actionLabel: session.workspaceLowStockCount > 0
                    ? 'Update'
                    : 'Open',
                onPressed: () => onOpenOperation(_WorkspaceOperation.catalogue),
              ),
              if (session.workspaceSettlementBalance > 0) ...[
                const Divider(height: 1),
                _StoreActionRow(
                  keyName: 'work-dashboard-payments',
                  urgency: _StoreActionUrgency.positive,
                  icon: Icons.account_balance_wallet_outlined,
                  eyebrow: 'MONEY',
                  title: '₹${session.workspaceSettlementBalance} available',
                  detail: 'Completed sales ready for settlement request.',
                  actionLabel: 'Request',
                  onPressed: () =>
                      onOpenOperation(_WorkspaceOperation.payments),
                ),
              ],
              const Divider(height: 1),
              _StoreActionRow(
                keyName: 'work-dashboard-delivery',
                icon: Icons.delivery_dining_outlined,
                eyebrow: 'DELIVERY',
                title: session.workspaceOrderNeedsDelivery
                    ? 'One order needs delivery attention'
                    : 'No delivery waiting',
                detail: session.workspaceOrderNeedsDelivery
                    ? 'Continue the confirmed customer handoff.'
                    : 'Phone and counter orders can request delivery here.',
                actionLabel: session.workspaceOrderNeedsDelivery
                    ? 'Continue'
                    : 'Open',
                onPressed: () => onOpenOperation(_WorkspaceOperation.delivery),
              ),
              if (session.workspaceActivity.isNotEmpty) ...[
                const SizedBox(height: MoolSpacing.md),
                _StoreRecentActivity(session: session),
              ],
              if (alertCount > 0) ...[
                const SizedBox(height: MoolSpacing.sm),
                TextButton.icon(
                  onPressed: () =>
                      onOpenOperation(_WorkspaceOperation.settings),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    '$alertCount ${alertCount == 1 ? 'store action' : 'store actions'} need attention',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardAlertButton extends StatelessWidget {
  const _DashboardAlertButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: IconButton.outlined(
        key: const Key('work-dashboard-alerts'),
        tooltip: 'Store alerts',
        onPressed: onPressed,
        icon: const Icon(Icons.notifications_none_rounded),
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
  });

  final String selected;
  final VoidCallback? onToday;
  final VoidCallback? onCustomers;
  final VoidCallback? onMoney;
  final VoidCallback? onGrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-store-context-rail'),
      height: 44,
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
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
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

class _StoreSignalStrip extends StatelessWidget {
  const _StoreSignalStrip({
    required this.session,
    required this.ready,
    required this.onStateSelected,
    required this.onStatus,
    required this.onPreview,
  });

  final WorkSession session;
  final bool ready;
  final ValueChanged<_QuickStoreState> onStateSelected;
  final VoidCallback onStatus;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final state = !ready
        ? 'SETUP'
        : !session.workspaceVisibleToCustomers
        ? 'CLOSED'
        : !session.workspaceAcceptingOrders
        ? 'PAUSED'
        : session.workspaceBusyMinutes > 0
        ? 'BUSY'
        : 'OPEN';
    final stateColor = switch (state) {
      'OPEN' => const Color(0xFF08765D),
      'BUSY' || 'PAUSED' => const Color(0xFF9A4A00),
      'CLOSED' => const Color(0xFFB42318),
      _ => MoolColors.orange,
    };
    return Container(
      key: const Key('work-dashboard-command-centre'),
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FD),
        border: Border(bottom: BorderSide(color: Color(0xFFDCE2F2))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 66,
            child: PopupMenuButton<_QuickStoreState>(
              key: const Key('work-dashboard-store-state'),
              tooltip: 'Change store state',
              onSelected: onStateSelected,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _QuickStoreState.open,
                  child: Text('Open for orders'),
                ),
                PopupMenuItem(
                  value: _QuickStoreState.busy,
                  child: Text('Busy · add 20 minutes'),
                ),
                PopupMenuItem(
                  value: _QuickStoreState.paused,
                  child: Text('Pause for 1 hour'),
                ),
                PopupMenuItem(
                  value: _QuickStoreState.closed,
                  child: Text('Close store'),
                ),
              ],
              child: _StoreSignal(
                label: 'Store',
                value: state,
                valueColor: stateColor,
              ),
            ),
          ),
          Expanded(
            child: _StoreSignal(
              label: 'Orders',
              value: session.hasActiveWorkspaceOrder ? '1' : '0',
            ),
          ),
          Expanded(
            child: _StoreSignal(
              label: 'Sales',
              value: '₹${session.workspaceSalesToday}',
            ),
          ),
          Expanded(
            child: _StoreSignal(
              label: 'Low stock',
              value: '${session.workspaceLowStockCount}',
            ),
          ),
          IconButton(
            key: const Key('work-dashboard-public-preview'),
            tooltip: 'Customer store preview',
            onPressed: onPreview,
            icon: const Icon(Icons.visibility_outlined, size: 19),
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

class _StoreSignal extends StatelessWidget {
  const _StoreSignal({
    required this.label,
    required this.value,
    this.valueColor = MoolColors.navy,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: const TextStyle(
            color: MoolColors.muted,
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
                    fontSize: 8,
                    letterSpacing: .45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 13,
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
                    fontSize: 9.5,
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

class _TodayOrderAction extends StatelessWidget {
  const _TodayOrderAction({
    required this.session,
    required this.onOrders,
    required this.onSell,
    required this.onDelivery,
  });

  final WorkSession session;
  final VoidCallback onOrders;
  final VoidCallback onSell;
  final VoidCallback onDelivery;

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
        onPressed: onSell,
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
    final action = switch (stage) {
      'Confirmed' || 'Preparing' => session.advanceWorkspaceOrder,
      'Ready' when session.workspaceOrderNeedsDelivery => onDelivery,
      'Ready' => session.advanceWorkspaceOrder,
      'Delivery requested' => onDelivery,
      _ => onOrders,
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
      onPressed: action,
    );
  }
}

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Flexible(
          child: Text(
            detail,
            textAlign: TextAlign.end,
            maxLines: 2,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 9.5,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onOpen,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<_WorkspaceOperation> onOpen;

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final results = _workspaceSearchDestinations.where((destination) {
      if (normalized.isEmpty) return true;
      return '${destination.title} ${destination.detail} ${destination.keywords}'
          .toLowerCase()
          .contains(normalized);
    }).toList();
    return Column(
      key: const Key('work-dashboard-search-screen'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.sm,
          ),
          child: MoolServiceSearchField(
            fieldKey: const Key('work-dashboard-search-field'),
            controller: controller,
            focusNode: focusNode,
            hintText: 'Search orders, products, customers or invoices',
            semanticLabel: 'Search your store records',
            onChanged: onChanged,
            onSubmitted: (_) {
              if (results.isNotEmpty) onOpen(results.first.operation);
            },
            trailing: query.isEmpty
                ? null
                : IconButton(
                    key: const Key('work-dashboard-search-clear'),
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? WorkEmptyState(
                  keyName: 'work-dashboard-search-empty',
                  title: 'No matching store record',
                  detail:
                      'Try an order number, product, customer, invoice or business book.',
                  actionLabel: 'Clear search',
                  onAction: onClear,
                )
              : ListView.separated(
                  key: const Key('work-dashboard-search-results'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    MoolSpacing.md,
                    0,
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
                      onTap: () => onOpen(destination.operation),
                    );
                  },
                ),
        ),
      ],
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
      return _WorkspaceOrdersSurface(
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
      );
    }
    if (operation == _WorkspaceOperation.preview) {
      return Column(
        children: [
          _StoreContextRail(
            onToday: onOpenStore,
            onCustomers: () => onOpenOperation(_WorkspaceOperation.customers),
            onMoney: () => onOpenOperation(_WorkspaceOperation.payments),
            onGrow: () => onOpenOperation(_WorkspaceOperation.sourcing),
          ),
          Expanded(child: _CustomerStorePreviewSurface(session: session)),
        ],
      );
    }
    if (operation == _WorkspaceOperation.delivery) {
      return _WorkspaceDeliverySurface(
        session: session,
        onCreateOrder: () => onOpenOperation(_WorkspaceOperation.counterOrder),
      );
    }
    final selectedStoreContext = switch (operation) {
      _WorkspaceOperation.customers => 'customers',
      _WorkspaceOperation.payments || _WorkspaceOperation.books => 'money',
      _WorkspaceOperation.sourcing || _WorkspaceOperation.services => 'grow',
      _ => 'today',
    };
    final content = ListView(
      key: Key('work-dashboard-${operation.name}-screen'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      children: [..._operationContent()],
    );
    return Column(
      children: [
        _StoreContextRail(
          selected: selectedStoreContext,
          onToday: onOpenStore,
          onCustomers: () => onOpenOperation(_WorkspaceOperation.customers),
          onMoney: () => onOpenOperation(_WorkspaceOperation.payments),
          onGrow: () => onOpenOperation(_WorkspaceOperation.sourcing),
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
        title: 'Retailer group buying',
        detail:
            'Confirmed retailer-led group buys will show specifications, closing time, savings, fees and store delivery.',
      ),
    ],
    _WorkspaceOperation.services => const [
      _OperationActionCard(
        icon: Icons.receipt_long_outlined,
        title: 'GST and tax assistance',
        detail:
            'Keep business records ready and request professional filing assistance when needed.',
      ),
      SizedBox(height: MoolSpacing.xs),
      _OperationActionCard(
        icon: Icons.menu_book_outlined,
        title: 'Bookkeeping and accounts',
        detail:
            'Organise sales, purchases, stock and settlement records for your accountant.',
      ),
      SizedBox(height: MoolSpacing.xs),
      _OperationActionCard(
        icon: Icons.verified_user_outlined,
        title: 'Audit support',
        detail:
            'Request document and record assistance without changing your store operations.',
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
  });

  final WorkSession session;
  final VoidCallback onOpenPurchases;

  @override
  State<_WorkspaceCatalogueSurface> createState() =>
      _WorkspaceCatalogueSurfaceState();
}

class _WorkspaceCatalogueSurfaceState
    extends State<_WorkspaceCatalogueSurface> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _lowStockOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    bool matches(WorkspaceCatalogueItem product) =>
        normalized.isEmpty ||
        '${product.title} ${product.brand} ${product.pack} ${product.sku} ${product.barcode} ${product.categoryId}'
            .toLowerCase()
            .contains(normalized);
    final own = widget.session.workspaceCatalogueItems
        .where(matches)
        .where((product) => !_lowStockOnly || product.stock <= 5)
        .toList();
    final available = workspaceMasterCatalogue
        .where(matches)
        .where((product) => !_lowStockOnly)
        .where(
          (product) => widget.session.workspaceCatalogueItems.every(
            (owned) => owned.id != product.id,
          ),
        )
        .toList();
    return Column(
      key: const Key('work-dashboard-catalogue-screen'),
      children: [
        _StockContextRail(
          lowStockOnly: _lowStockOnly,
          onProducts: () => setState(() => _lowStockOnly = false),
          onLowStock: () => setState(() => _lowStockOnly = true),
          onPurchases: widget.onOpenPurchases,
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              MoolServiceSearchField(
                fieldKey: const Key('work-catalogue-search'),
                controller: _search,
                hintText: 'Search product, pack, SKU or barcode',
                semanticLabel: 'Search your catalogue and verified products',
                onChanged: (value) => setState(() => _query = value),
                trailing: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear product search',
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              _CatalogueSummary(session: widget.session),
              const SizedBox(height: MoolSpacing.md),
              const _WorkspaceSectionLabel(
                title: 'Your catalogue',
                detail: 'Price · stock · public status',
              ),
              const SizedBox(height: MoolSpacing.xs),
              if (own.isEmpty)
                const WorkCard(
                  keyName: 'work-catalogue-empty',
                  child: Text(
                    'No matching product in your store. Add one from the verified catalogue below.',
                    style: TextStyle(color: MoolColors.muted, height: 1.3),
                  ),
                )
              else
                for (final product in own) ...[
                  _WorkspaceProductRow(
                    product: product,
                    owned: true,
                    onPressed: () => _edit(product),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                ],
              const SizedBox(height: MoolSpacing.md),
              const _WorkspaceSectionLabel(
                title: 'Add products',
                detail: 'Match once; enter only store values',
              ),
              const SizedBox(height: MoolSpacing.xs),
              if (available.isEmpty)
                const WorkCard(
                  child: Text(
                    'All matching verified products are already in your catalogue.',
                    style: TextStyle(color: MoolColors.muted),
                  ),
                )
              else
                for (final product in available) ...[
                  _WorkspaceProductRow(
                    product: product,
                    owned: false,
                    onPressed: () => _edit(product),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StockContextRail extends StatelessWidget {
  const _StockContextRail({
    required this.lowStockOnly,
    required this.onProducts,
    required this.onLowStock,
    required this.onPurchases,
  });

  final bool lowStockOnly;
  final VoidCallback onProducts;
  final VoidCallback onLowStock;
  final VoidCallback onPurchases;

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
            selected: !lowStockOnly,
            onPressed: lowStockOnly ? onProducts : null,
          ),
          _StoreContextButton(
            label: 'Low stock',
            selected: lowStockOnly,
            onPressed: lowStockOnly ? null : onLowStock,
          ),
          _StoreContextButton(
            label: 'Purchases',
            selected: false,
            onPressed: onPurchases,
          ),
        ],
      ),
    );
  }
}

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
    required this.onPressed,
  });

  final WorkspaceCatalogueItem product;
  final bool owned;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
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
              child: Text(owned ? 'Edit' : 'Add'),
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
  late bool _public = widget.product.publicListing;
  String? _error;

  @override
  void dispose() {
    _purchase.dispose();
    _selling.dispose();
    _mrp.dispose();
    _stock.dispose();
    _delivery.dispose();
    super.dispose();
  }

  void _save() {
    final purchase = int.tryParse(_purchase.text.trim());
    final selling = int.tryParse(_selling.text.trim());
    final mrp = int.tryParse(_mrp.text.trim());
    final stock = int.tryParse(_stock.text.trim());
    final error = purchase == null || purchase <= 0
        ? 'Enter the current purchase cost for your internal margin view.'
        : selling == null || selling <= purchase
        ? 'Enter a customer price above the purchase cost.'
        : stock == null || stock < 0
        ? 'Enter the available stock.'
        : mrp != null && mrp < selling
        ? 'MRP cannot be lower than the customer price.'
        : _delivery.text.trim().isEmpty
        ? 'Add the customer delivery promise.'
        : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    widget.session.addOrUpdateWorkspaceProduct(
      widget.product.copyWith(
        purchasePrice: purchase,
        sellingPrice: selling,
        mrp: mrp,
        stock: stock,
        unitPrice: '₹$selling/${widget.product.pack}',
        deliveryPromise: _delivery.text.trim(),
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.md,
          MoolSpacing.md,
          MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.title,
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${widget.product.brand} · ${widget.product.pack} · ${widget.product.sku}',
                style: const TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _MoneyField(
                      keyName: 'work-product-purchase-price',
                      controller: _purchase,
                      label: 'Purchase cost',
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: _MoneyField(
                      keyName: 'work-product-selling-price',
                      controller: _selling,
                      label: 'Customer price',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _MoneyField(
                      keyName: 'work-product-mrp',
                      controller: _mrp,
                      label: 'MRP',
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: TextField(
                      key: const Key('work-product-stock'),
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Available stock',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.xs),
              TextField(
                key: const Key('work-product-delivery'),
                controller: _delivery,
                decoration: const InputDecoration(
                  labelText: 'Customer delivery promise',
                ),
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
              const SizedBox(height: MoolSpacing.sm),
              SizedBox(
                width: double.infinity,
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
    return TextField(
      key: Key(keyName),
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, prefixText: '₹ '),
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
        Container(
          padding: const EdgeInsets.all(MoolSpacing.sm),
          decoration: BoxDecoration(
            color: MoolColors.navy,
            borderRadius: BorderRadius.circular(MoolRadii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.workspaceVisibleToCustomers
                    ? 'VISIBLE TO CUSTOMERS'
                    : 'PRIVATE PREVIEW',
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
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${session.activeWorkspace?.area ?? ''} · Mool Retail Partner',
                style: const TextStyle(color: Color(0xFFD9DAFF)),
              ),
              const SizedBox(height: MoolSpacing.xs),
              FilledButton.tonalIcon(
                key: const Key('work-preview-visibility'),
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
                label: Text(
                  session.workspaceVisibleToCustomers
                      ? 'Make store private'
                      : 'Publish store',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
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
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${product.pack} · ${product.deliveryPromise}',
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${product.sellingPrice}',
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
          ],
      ],
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
      'Ready' => 'Complete order',
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
    if (_fulfilment != 'At the shop') widget.onArrangeDelivery();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('work-dashboard-counter-order-screen'),
      children: [
        _SellSourceRail(
          selected: _source,
          onSelected: (value) => setState(() => _source = value),
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              TextField(
                key: const Key('work-order-customer'),
                controller: _customer,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Customer mobile number',
                  hintText: 'Number used for order updates',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              const _WorkspaceSectionLabel(
                title: 'Products',
                detail: 'From your catalogue',
              ),
              const SizedBox(height: MoolSpacing.xs),
              if (widget.session.workspaceCatalogueItems.isEmpty)
                WorkCard(
                  keyName: 'work-order-catalogue-empty',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your catalogue has no product yet.',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const Text(
                        'Add products once, then use them for counter, phone and Chat orders.',
                        style: TextStyle(color: MoolColors.muted),
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      FilledButton.tonalIcon(
                        onPressed: widget.onOpenCatalogue,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add products'),
                      ),
                    ],
                  ),
                )
              else
                for (final product
                    in widget.session.workspaceCatalogueItems) ...[
                  _OrderCatalogueRow(product: product, session: widget.session),
                  const SizedBox(height: MoolSpacing.xs),
                ],
              _OrderTotalBar(session: widget.session),
              const SizedBox(height: MoolSpacing.xs),
              _OrderCompletionChoices(
                fulfilment: _fulfilment,
                payment: _payment,
                addressController: _address,
                onFulfilmentChanged: (value) =>
                    setState(() => _fulfilment = value),
                onPaymentChanged: (value) => setState(() => _payment = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: MoolSpacing.xs),
                Text(
                  _error!,
                  key: const Key('work-order-error'),
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: MoolSpacing.sm),
              FilledButton.icon(
                key: const Key('work-order-save'),
                onPressed: _save,
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
            ],
          ),
        ),
      ],
    );
  }
}

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
    required this.fulfilmentMode,
    required this.busyMinutes,
    required this.reopensAt,
    required this.onAcceptingChanged,
    required this.onFulfilmentChanged,
    required this.onBusyMinutesChanged,
    required this.onReopensChanged,
  });

  final bool acceptingOrders;
  final String fulfilmentMode;
  final int busyMinutes;
  final String reopensAt;
  final ValueChanged<bool> onAcceptingChanged;
  final ValueChanged<String> onFulfilmentChanged;
  final ValueChanged<int> onBusyMinutesChanged;
  final ValueChanged<String> onReopensChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('work-dashboard-status-screen'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      children: [
        WorkCard(
          keyName: 'work-status-current',
          color: acceptingOrders
              ? const Color(0xFFEAF7F3)
              : const Color(0xFFFFF3E8),
          child: SwitchListTile.adaptive(
            key: const Key('work-status-accepting-orders'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              acceptingOrders ? 'Accepting app orders' : 'Store paused',
              style: const TextStyle(
                color: MoolColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              acceptingOrders
                  ? 'Customers can place orders using your selected fulfilment options.'
                  : 'New app orders stop. Accepted orders remain active.',
              style: const TextStyle(color: MoolColors.muted, fontSize: 11),
            ),
            value: acceptingOrders,
            onChanged: onAcceptingChanged,
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        const WorkSectionTitle(
          title: 'How customers receive orders',
          detail: 'Only available options will appear before checkout.',
        ),
        const SizedBox(height: MoolSpacing.sm),
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
        const SizedBox(height: MoolSpacing.md),
        const WorkSectionTitle(
          title: 'Preparation time',
          detail: 'Add time temporarily when the store is busy.',
        ),
        const SizedBox(height: MoolSpacing.sm),
        Wrap(
          spacing: MoolSpacing.xs,
          runSpacing: MoolSpacing.xs,
          children: [
            for (final minutes in const [0, 10, 20, 30])
              ChoiceChip(
                key: Key('work-status-busy-$minutes'),
                label: Text(minutes == 0 ? 'Normal time' : '+$minutes min'),
                selected: busyMinutes == minutes,
                onSelected: acceptingOrders
                    ? (selected) {
                        if (selected) onBusyMinutesChanged(minutes);
                      }
                    : null,
              ),
          ],
        ),
        if (!acceptingOrders) ...[
          const SizedBox(height: MoolSpacing.md),
          const WorkSectionTitle(
            title: 'When ordering resumes',
            detail: 'Customers will see this before trying to order.',
          ),
          const SizedBox(height: MoolSpacing.sm),
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
        const SizedBox(height: MoolSpacing.md),
        const WorkCard(
          keyName: 'work-status-order-protection',
          color: Color(0xFFF2F4FA),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, color: MoolColors.navy),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Text(
                  'Pausing the store never cancels an accepted order. Existing packing, pickup and delivery work stays available.',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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

typedef _WorkspaceSearchDestination = ({
  String id,
  String title,
  String detail,
  String keywords,
  _WorkspaceOperation operation,
  IconData icon,
});

const List<_WorkspaceSearchDestination> _workspaceSearchDestinations = [
  (
    id: 'orders',
    title: 'Customer orders',
    detail: 'Need action, preparing, ready and completed orders',
    keywords: 'order invoice fulfilment packing pickup delivery',
    operation: _WorkspaceOperation.orders,
    icon: Icons.receipt_long_outlined,
  ),
  (
    id: 'products',
    title: 'Products and stock',
    detail: 'Catalogue, price, availability and stock',
    keywords: 'product sku barcode inventory catalogue price',
    operation: _WorkspaceOperation.catalogue,
    icon: Icons.inventory_2_outlined,
  ),
  (
    id: 'customers',
    title: 'Customers',
    detail: 'Purchase history, repeat orders and payment records',
    keywords: 'customer mobile due statement repeat',
    operation: _WorkspaceOperation.customers,
    icon: Icons.groups_outlined,
  ),
  (
    id: 'books',
    title: 'Business books',
    detail: 'Sales, purchases, stock and money',
    keywords: 'invoice ledger sales purchase stock money expense settlement',
    operation: _WorkspaceOperation.books,
    icon: Icons.menu_book_outlined,
  ),
  (
    id: 'wholesale',
    title: 'Wholesale sourcing',
    detail: 'Restock products and track purchase orders',
    keywords: 'wholesale supplier restock sourcing purchase order',
    operation: _WorkspaceOperation.sourcing,
    icon: Icons.handshake_outlined,
  ),
  (
    id: 'services',
    title: 'Business services',
    detail: 'GST, tax, bookkeeping and audit support',
    keywords: 'gst itr income tax books audit compliance',
    operation: _WorkspaceOperation.services,
    icon: Icons.business_center_outlined,
  ),
  (
    id: 'workspace-record',
    title: 'Workspace record',
    detail: 'Business details, documents and review status',
    keywords: 'workspace kyc document review profile approval',
    operation: _WorkspaceOperation.settings,
    icon: Icons.fact_check_outlined,
  ),
];

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
  if (!session.workspaceAcceptingOrders &&
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
      route: null,
      operation: _WorkspaceOperation.catalogue,
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
      route: null,
      operation: session.workspaceOrderNeedsDelivery
          ? _WorkspaceOperation.delivery
          : _WorkspaceOperation.orders,
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
