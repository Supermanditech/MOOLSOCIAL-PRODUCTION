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
                  session: session,
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
    };
    final subtitle = switch (_view) {
      _WorkspaceControlView.dashboard => '${profile.label} · ${workspace.area}',
      _WorkspaceControlView.search =>
        'Find orders, products, customers or business records',
      _WorkspaceControlView.status =>
        'Choose when customers can order and how you fulfil',
      _WorkspaceControlView.alerts =>
        'Resolve the most important store actions first',
    };
    final bottomAction = switch (_view) {
      _WorkspaceControlView.dashboard => WorkPrimaryButton(
        keyName: 'work-dashboard-earn',
        label: 'Find business opportunities',
        icon: Icons.bolt_rounded,
        onPressed: () => context.push('/app/work/earn'),
      ),
      _WorkspaceControlView.status => WorkPrimaryButton(
        keyName: 'work-status-save',
        label: 'Save store availability',
        icon: Icons.check_circle_outline_rounded,
        onPressed: _saveAvailability,
      ),
      _ => null,
    };

    return WorkPageScaffold(
      session: session,
      title: title,
      subtitle: subtitle,
      fallbackBackRoute: '/app/work/earn',
      activeLocalAction: 'workspace',
      showHeaderChat: false,
      showTrailingAction: false,
      onBack: _view == _WorkspaceControlView.dashboard ? null : _showDashboard,
      bottomAction: bottomAction,
      body: switch (_view) {
        _WorkspaceControlView.dashboard => _StoreControlDashboard(
          session: session,
          workspace: workspace,
          profile: profile,
          onSearch: _showSearch,
          onStatus: _showStatus,
          onAlerts: _showAlerts,
          onProfile: () => _openProfile(context, workspace),
        ),
        _WorkspaceControlView.search => _WorkspaceSearchSurface(
          controller: _searchController,
          focusNode: _searchFocus,
          query: session.workspaceSearchQuery,
          onChanged: session.updateWorkspaceSearch,
          onClear: _clearSearch,
          onOpen: (route) => context.push(route),
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
          onOpenStatus: _showStatus,
          onDismiss: session.dismissWorkspaceAlert,
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

enum _WorkspaceControlView { dashboard, search, status, alerts }

class _StoreControlDashboard extends StatelessWidget {
  const _StoreControlDashboard({
    required this.session,
    required this.workspace,
    required this.profile,
    required this.onSearch,
    required this.onStatus,
    required this.onAlerts,
    required this.onProfile,
  });

  final WorkSession session;
  final WorkWorkspace workspace;
  final WorkProfileOption profile;
  final VoidCallback onSearch;
  final VoidCallback onStatus;
  final VoidCallback onAlerts;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(profile);
    final alertCount = _workspaceAlerts(session).length;
    return ListView(
      key: const Key('work-workspace-dashboard'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: MoolServiceSearchField(
                fieldKey: const Key('work-dashboard-search'),
                hintText: 'Search orders, products, customers or invoices',
                semanticLabel: 'Search your store',
                readOnly: true,
                onTap: onSearch,
              ),
            ),
            const SizedBox(width: MoolSpacing.xs),
            _DashboardAlertButton(count: alertCount, onPressed: onAlerts),
            const SizedBox(width: 4),
            MoolGlobalProfileShortcutV2(
              keyName: 'work-dashboard-profile',
              onPressed: onProfile,
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        _DashboardReveal(
          child: _WorkspaceDashboardHero(
            session: session,
            workspace: workspace,
            profile: profile,
            onStatus: onStatus,
          ),
        ),
        const SizedBox(height: MoolSpacing.sm),
        _StoreAvailabilityStrip(session: session, onPressed: onStatus),
        const SizedBox(height: MoolSpacing.md),
        const WorkSectionTitle(
          title: 'Today in your store',
          detail: 'Open the exact task you want to complete.',
        ),
        const SizedBox(height: MoolSpacing.sm),
        LayoutBuilder(
          key: const Key('work-dashboard-daily-actions'),
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - MoolSpacing.xs) / 2;
            return Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: [
                SizedBox(
                  width: tileWidth,
                  height: 104,
                  child: _WorkspaceActionTile(
                    keyName: 'work-dashboard-orders',
                    icon: Icons.receipt_long_outlined,
                    title: 'Customer orders',
                    detail: 'Review and fulfil',
                    onTap: () => context.push('/app/retailer/orders'),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  height: 104,
                  child: _WorkspaceActionTile(
                    keyName: 'work-dashboard-create-order',
                    icon: Icons.add_shopping_cart_rounded,
                    title: 'Create counter order',
                    detail: 'Record a store sale',
                    onTap: () => context.push('/app/retailer/orders/new'),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  height: 104,
                  child: _WorkspaceActionTile(
                    keyName: 'work-dashboard-products',
                    icon: Icons.inventory_2_outlined,
                    title: 'Catalogue',
                    detail: 'Products, prices and stock',
                    onTap: () => context.push('/app/retailer/home?view=stock'),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  height: 104,
                  child: _WorkspaceActionTile(
                    keyName: 'work-dashboard-delivery',
                    icon: Icons.delivery_dining_outlined,
                    title: 'Deliver a phone order',
                    detail: 'Create and arrange delivery',
                    onTap: () =>
                        context.push('/app/retailer/orders/new?source=phone'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: MoolSpacing.md),
        _DashboardReveal(
          delay: const Duration(milliseconds: 90),
          child: _DashboardPriorityCard(
            session: session,
            profile: profile,
            presentation: presentation,
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        WorkSectionTitle(
          title: 'Needs your attention',
          detail: alertCount == 0
              ? 'Your store has no urgent action right now.'
              : '$alertCount store ${alertCount == 1 ? 'action' : 'actions'} to review.',
        ),
        const SizedBox(height: MoolSpacing.sm),
        _AttentionPreview(session: session, onOpenAlerts: onAlerts),
        const SizedBox(height: MoolSpacing.md),
        const WorkSectionTitle(
          title: 'Run your business',
          detail: 'Your existing store tools stay connected to this Workspace.',
        ),
        const SizedBox(height: MoolSpacing.sm),
        _WorkspaceNavigationRow(
          keyName: 'work-dashboard-customers',
          icon: Icons.groups_outlined,
          title: 'Customers',
          detail: 'Purchase history, dues and repeat business',
          onTap: () => context.push('/app/retailer/customers'),
        ),
        const SizedBox(height: MoolSpacing.xs),
        _WorkspaceNavigationRow(
          keyName: 'work-dashboard-books',
          icon: Icons.menu_book_outlined,
          title: 'Business books',
          detail: 'Sales, purchases, stock and money',
          onTap: () => context.push('/app/retailer/books'),
        ),
        const SizedBox(height: MoolSpacing.xs),
        _WorkspaceNavigationRow(
          keyName: 'work-dashboard-sourcing',
          icon: Icons.handshake_outlined,
          title: 'Wholesale sourcing',
          detail: 'Restock through the existing Wholesale flow',
          onTap: () => context.push('/app/retailer/wholesale'),
        ),
        const SizedBox(height: MoolSpacing.xs),
        _WorkspaceNavigationRow(
          keyName: 'work-dashboard-tools',
          icon: Icons.business_center_outlined,
          title: 'Business services',
          detail: 'GST, tax, bookkeeping and audit support',
          onTap: () => context.push('/app/retailer/services'),
        ),
        const SizedBox(height: MoolSpacing.md),
        _WorkspaceAccountState(session: session, workspace: workspace),
        const SizedBox(height: MoolSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('work-dashboard-manage-record'),
                onPressed: () => context.push('/app/work/workspace/proof'),
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

class _StoreAvailabilityStrip extends StatelessWidget {
  const _StoreAvailabilityStrip({
    required this.session,
    required this.onPressed,
  });

  final WorkSession session;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accepting = session.workspaceAcceptingOrders;
    return Material(
      key: const Key('work-dashboard-availability'),
      color: accepting ? const Color(0xFFEAF7F3) : const Color(0xFFFFF3E8),
      borderRadius: BorderRadius.circular(MoolRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(MoolRadii.card),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MoolSpacing.sm,
            vertical: MoolSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                accepting
                    ? Icons.storefront_rounded
                    : Icons.pause_circle_outline,
                color: accepting
                    ? const Color(0xFF08765D)
                    : const Color(0xFF9A4A00),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accepting ? 'Accepting app orders' : 'Store paused',
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      accepting
                          ? session.workspaceBusyMinutes == 0
                                ? session.workspaceFulfilmentMode
                                : '${session.workspaceFulfilmentMode} · ${session.workspaceBusyMinutes} min extra preparation'
                          : session.workspaceReopensAt.isEmpty
                          ? 'Choose when customers can order again'
                          : 'Ordering resumes ${session.workspaceReopensAt}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Change',
                style: TextStyle(
                  color: MoolColors.navy,
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

class _WorkspaceActionTile extends StatelessWidget {
  const _WorkspaceActionTile({
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
    return Material(
      key: Key(keyName),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MoolRadii.card),
        side: const BorderSide(color: Color(0xFFDCE2F2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(MoolRadii.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: MoolColors.navy, size: 23),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 12,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 9.5,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

class _AttentionPreview extends StatelessWidget {
  const _AttentionPreview({required this.session, required this.onOpenAlerts});

  final WorkSession session;
  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final alerts = _workspaceAlerts(session);
    if (alerts.isEmpty) {
      return WorkCard(
        keyName: 'work-dashboard-no-alerts',
        padding: const EdgeInsets.all(MoolSpacing.sm),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: MoolColors.success),
            SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: Text(
                'No urgent store action right now.',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final first = alerts.first;
    return WorkCard(
      keyName: 'work-dashboard-attention-preview',
      onTap: onOpenAlerts,
      color: const Color(0xFFFFF7EA),
      padding: const EdgeInsets.all(MoolSpacing.sm),
      child: Row(
        children: [
          Icon(first.icon, color: const Color(0xFF9A4A00)),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  first.title,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  first.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
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
  final ValueChanged<String> onOpen;

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
              if (results.isNotEmpty) onOpen(results.first.route);
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
                      onTap: () => onOpen(destination.route),
                    );
                  },
                ),
        ),
      ],
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
    required this.onOpenStatus,
    required this.onDismiss,
  });

  final WorkSession session;
  final ValueChanged<String> onOpen;
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
        onAction: () => onOpen('/app/retailer/orders'),
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
                        } else {
                          onOpen(alert.route);
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
  String route,
  IconData icon,
});

const List<_WorkspaceSearchDestination> _workspaceSearchDestinations = [
  (
    id: 'orders',
    title: 'Customer orders',
    detail: 'Need action, preparing, ready and completed orders',
    keywords: 'order invoice fulfilment packing pickup delivery',
    route: '/app/retailer/orders',
    icon: Icons.receipt_long_outlined,
  ),
  (
    id: 'products',
    title: 'Products and stock',
    detail: 'Catalogue, price, availability and stock',
    keywords: 'product sku barcode inventory catalogue price',
    route: '/app/retailer/home?view=stock',
    icon: Icons.inventory_2_outlined,
  ),
  (
    id: 'customers',
    title: 'Customers',
    detail: 'Purchase history, repeat orders and payment records',
    keywords: 'customer mobile due statement repeat',
    route: '/app/retailer/customers',
    icon: Icons.groups_outlined,
  ),
  (
    id: 'books',
    title: 'Business books',
    detail: 'Sales, purchases, stock and money',
    keywords: 'invoice ledger sales purchase stock money expense settlement',
    route: '/app/retailer/books',
    icon: Icons.menu_book_outlined,
  ),
  (
    id: 'wholesale',
    title: 'Wholesale sourcing',
    detail: 'Restock products and track purchase orders',
    keywords: 'wholesale supplier restock sourcing purchase order',
    route: '/app/retailer/wholesale',
    icon: Icons.handshake_outlined,
  ),
  (
    id: 'services',
    title: 'Business services',
    detail: 'GST, tax, bookkeeping and audit support',
    keywords: 'gst itr income tax books audit compliance',
    route: '/app/retailer/services',
    icon: Icons.business_center_outlined,
  ),
  (
    id: 'workspace-record',
    title: 'Workspace record',
    detail: 'Business details, documents and review status',
    keywords: 'workspace kyc document review profile approval',
    route: '/app/work/workspace/proof',
    icon: Icons.fact_check_outlined,
  ),
];

typedef _WorkspaceAlertItem = ({
  String id,
  String title,
  String detail,
  String actionLabel,
  String route,
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
      icon: Icons.pause_circle_outline_rounded,
      requiredAction: false,
    ));
  }
  return alerts;
}

class _WorkspaceDashboardHero extends StatelessWidget {
  const _WorkspaceDashboardHero({
    required this.session,
    required this.workspace,
    required this.profile,
    this.onStatus,
  });

  final WorkSession session;
  final WorkWorkspace workspace;
  final WorkProfileOption profile;
  final VoidCallback? onStatus;

  @override
  Widget build(BuildContext context) {
    final live = session.reviewStage == WorkReviewStage.live;
    return Container(
      key: const Key('work-dashboard-hero'),
      padding: const EdgeInsets.all(MoolSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF080887), Color(0xFF006B62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MoolRadii.sheet),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22080887),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: MoolColors.orange,
                foregroundColor: MoolColors.navy,
                child: Icon(profile.icon, size: 27),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      live ? 'WORKSPACE ACTIVE' : 'WORKSPACE APPROVED',
                      style: const TextStyle(
                        color: Color(0xFFFFD39A),
                        fontSize: 10,
                        letterSpacing: .55,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      workspace.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (onStatus != null)
                IconButton(
                  key: const Key('work-dashboard-status'),
                  tooltip: 'Change store availability',
                  onPressed: onStatus,
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: .12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: .24),
                    ),
                  ),
                  icon: const Icon(Icons.tune_rounded),
                ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          Text(
            '${profile.label} · ${workspace.area}',
            style: const TextStyle(
              color: Color(0xFFE7E7FF),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _HeroState(
                  label: 'ACCOUNT',
                  value: session.connectedProviderLabel.isEmpty
                      ? 'Linked'
                      : session.connectedProviderLabel,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: _HeroState(label: 'REVIEW', value: 'Approved'),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _HeroState(
                  label: 'VISIBILITY',
                  value: live ? 'Live' : 'Private',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroState extends StatelessWidget {
  const _HeroState({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(MoolRadii.control),
        border: Border.all(color: Colors.white.withValues(alpha: .25)),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD9DAFF),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
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
