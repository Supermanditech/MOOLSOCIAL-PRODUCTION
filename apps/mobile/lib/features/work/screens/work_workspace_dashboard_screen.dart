import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
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

  @override
  void initState() {
    super.initState();
    session.clearMessages();
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
}

class _WorkspaceDashboardHero extends StatelessWidget {
  const _WorkspaceDashboardHero({
    required this.session,
    required this.workspace,
    required this.profile,
  });

  final WorkSession session;
  final WorkWorkspace workspace;
  final WorkProfileOption profile;

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
