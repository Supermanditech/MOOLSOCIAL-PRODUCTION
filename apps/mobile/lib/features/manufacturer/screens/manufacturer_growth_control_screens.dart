import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../manufacturer_models.dart';
import '../manufacturer_session.dart';
import '../widgets/manufacturer_widgets.dart';

class ManufacturerGrowthScreen extends StatelessWidget {
  const ManufacturerGrowthScreen({
    required this.session,
    required this.initialTab,
    super.key,
  });

  final ManufacturerSession session;
  final ManufacturerGrowthTab initialTab;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => ManufacturerPageScaffold(
        session: session,
        title: 'Business Growth',
        subtitle: 'Buyers, demand and funded outcomes',
        activeDock: 'none',
        returnRoute: '/app/manufacturer',
        trailing: IconButton.outlined(
          key: const Key('manufacturer-growth-create'),
          tooltip: 'Create outcome campaign',
          onPressed: () => _campaignSheet(context),
          icon: const Icon(Icons.add_rounded),
        ),
        body: ListView(
          key: const Key('manufacturer-growth-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const Row(
              children: [
                Expanded(
                  child: ManufacturerMetric(
                    label: 'ACTIVE BUYERS',
                    value: '286',
                    detail: 'verified',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: ManufacturerMetric(
                    label: 'REPEAT RATE',
                    value: '64%',
                    detail: 'paid buyers',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: ManufacturerMetric(
                    label: 'DEMAND',
                    value: '₹18.4L',
                    detail: 'pipeline',
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ManufacturerGrowthTab.values
                    .map(
                      (tab) => Padding(
                        padding: const EdgeInsets.only(right: MoolSpacing.xs),
                        child: MoolSegment(
                          key: Key('manufacturer-growth-tab-${tab.name}'),
                          label:
                              tab.name[0].toUpperCase() + tab.name.substring(1),
                          selected: session.growthTab == tab,
                          onPressed: () => session.setGrowthTab(tab),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            ...switch (session.growthTab) {
              ManufacturerGrowthTab.buyers => _buyers(context),
              ManufacturerGrowthTab.demand => _demand(context),
              ManufacturerGrowthTab.campaigns => _campaigns(context),
              ManufacturerGrowthTab.analytics => _analytics(context),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _buyers(BuildContext context) => [
    const ManufacturerSectionTitle(
      title: 'Verified buyer relationships',
      detail: 'repeat · risk · retention',
    ),
    const SizedBox(height: MoolSpacing.sm),
    ...[
      (
        'raj',
        'Rajasthan Retailer Pool',
        '168 active retailers · 72% repeat',
        '₹9.8L paid sales · low risk',
      ),
      (
        'hotel',
        'Jodhpur Hotel Group',
        '28 properties · monthly staples',
        '₹3.2L forecast · 15 day terms',
      ),
      (
        'dist',
        'Marwar Restaurant Distributor',
        '64 restaurants · mixed loads',
        'Next order forecast in 6 days',
      ),
    ].map(
      (buyer) => Padding(
        padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
        child: ManufacturerActionRow(
          keyName: 'manufacturer-buyer-${buyer.$1}',
          icon: Icons.storefront_outlined,
          title: buyer.$2,
          detail: buyer.$3,
          meta: buyer.$4,
          action: 'Open',
          onTap: () => _detailSheet(
            context,
            buyer.$2,
            '${buyer.$3}. ${buyer.$4}. Only paid, non-refunded orders count.',
          ),
        ),
      ),
    ),
  ];

  List<Widget> _demand(BuildContext context) => [
    const ManufacturerSectionTitle(
      title: 'Aggregated demand',
      detail: 'quantity · geography · close',
    ),
    const SizedBox(height: MoolSpacing.sm),
    ManufacturerActionRow(
      keyName: 'manufacturer-demand-oil',
      icon: Icons.groups_2_outlined,
      title: '860 cases · Sunflower Oil 1 L',
      detail: 'Jodhpur + Jaipur · verified retailer demand',
      meta: '78% committed · target ₹3.80L · closes 22 Jul',
      action: 'Review',
      onTap: () => _detailSheet(
        context,
        'Retailer demand pool',
        '860 cases at confirmed buyer terms. Uncommitted interest is not a sale.',
      ),
    ),
    const SizedBox(height: MoolSpacing.xs),
    ManufacturerActionRow(
      keyName: 'manufacturer-demand-flour',
      icon: Icons.groups_outlined,
      title: '410 bags · Whole Wheat Flour',
      detail: 'Jodhpur district · hotels and retailers',
      meta: '62% committed · closes 25 Jul',
      action: 'Review',
      onTap: () => _detailSheet(
        context,
        'Flour demand',
        'Verified requirements, price range and close time remain visible before commitment.',
      ),
    ),
  ];

  List<Widget> _campaigns(BuildContext context) => [
    ManufacturerCard(
      keyName: 'manufacturer-campaign-active',
      color: const Color(0xFFF4F3FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Retailer activation · Jaipur',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              ManufacturerPill(label: 'LIVE'),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          const LinearProgressIndicator(value: .68),
          const SizedBox(height: MoolSpacing.sm),
          const Row(
            children: [
              Expanded(
                child: _GrowthFact(label: 'Objective', value: '100'),
              ),
              Expanded(
                child: _GrowthFact(label: 'Activated', value: '68'),
              ),
              Expanded(
                child: _GrowthFact(label: 'Funded', value: '₹42K'),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Row(
            children: [
              Expanded(
                child: _GrowthFact(label: 'Fee', value: '₹280/active'),
              ),
              Expanded(
                child: _GrowthFact(label: 'Sales target', value: '₹4.5L'),
              ),
              Expanded(
                child: _GrowthFact(label: 'Ends', value: '20 Jul'),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              key: const Key('manufacturer-campaign-manage'),
              onPressed: () => _campaignSheet(context),
              child: const Text('Manage campaign'),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: MoolSpacing.xs),
    ManufacturerActionRow(
      keyName: 'manufacturer-campaign-create',
      icon: Icons.campaign_outlined,
      title: 'Launch Jodhpur hotel campaign',
      detail: 'Fund verified field sales through Earn',
      meta: 'Pay only for approved outcomes',
      action: 'Create',
      onTap: () => _campaignSheet(context),
    ),
  ];

  List<Widget> _analytics(BuildContext context) => [
    const ManufacturerSectionTitle(
      title: 'Sales intelligence',
      detail: 'paid outcomes only',
    ),
    const SizedBox(height: MoolSpacing.sm),
    const ManufacturerCard(
      color: Color(0xFFEAF7E8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rajasthan demand forecast',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: MoolSpacing.sm),
          LinearProgressIndicator(value: .74),
          SizedBox(height: MoolSpacing.sm),
          Text(
            'Sunflower Oil 1 L demand is forecast 18% higher over 30 days, based on paid repeat orders and verified open requirements.',
            style: TextStyle(color: MoolColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
    const SizedBox(height: MoolSpacing.xs),
    ManufacturerActionRow(
      keyName: 'manufacturer-analytics-geography',
      icon: Icons.map_outlined,
      title: 'Geography conversion',
      detail: 'Jodhpur 71% · Jaipur 58% · Pali 43%',
      action: 'View',
      onTap: () => _detailSheet(
        context,
        'Geography conversion',
        'Conversion uses paid, non-refunded attributed orders, not views or unverified leads.',
      ),
    ),
  ];

  Future<void> _campaignSheet(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('manufacturer-campaign-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create verified outcome campaign',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: MoolSpacing.xs),
                const Text(
                  'Funding is a maximum. Only approved activations or paid sales count.',
                ),
                const SizedBox(height: MoolSpacing.md),
                TextFormField(
                  key: const Key('manufacturer-campaign-target'),
                  initialValue: '${session.campaignTarget}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Verified buyer target',
                  ),
                  onChanged: (value) =>
                      session.setCampaignTarget(int.tryParse(value) ?? 0),
                ),
                const SizedBox(height: MoolSpacing.xs),
                TextFormField(
                  key: const Key('manufacturer-campaign-budget'),
                  initialValue: '${session.campaignBudget}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maximum approved funding',
                  ),
                  onChanged: (value) =>
                      session.setCampaignBudget(int.tryParse(value) ?? 0),
                ),
                const SizedBox(height: MoolSpacing.sm),
                const ManufacturerCard(
                  color: Color(0xFFFFF6E8),
                  child: Text(
                    'Verified Earn workers may execute approved onboarding and sales work. Worker identity is never exposed as a public directory.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('manufacturer-campaign-publish'),
                    onPressed: session.busy
                        ? null
                        : () async {
                            final ok = await session.reviewOrPublishCampaign();
                            if (ok &&
                                session.campaignId != null &&
                                sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                    child: Text(
                      session.campaignId != null
                          ? 'Campaign active'
                          : session.campaignReviewed
                          ? 'Publish funded campaign'
                          : 'Review campaign',
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

class ManufacturerControlScreen extends StatelessWidget {
  const ManufacturerControlScreen({
    required this.session,
    required this.initialTab,
    super.key,
  });

  final ManufacturerSession session;
  final ManufacturerControlTab initialTab;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => ManufacturerPageScaffold(
        session: session,
        title: 'Workspace Control',
        subtitle: 'Claims, people, settings and support',
        activeDock: 'none',
        returnRoute: '/app/manufacturer',
        trailing: IconButton.outlined(
          key: const Key('manufacturer-control-add'),
          tooltip: 'Add team member',
          onPressed: () {
            session.setControlTab(ManufacturerControlTab.team);
            session.openTeamInvite();
          },
          icon: const Icon(Icons.person_add_alt_1_outlined),
        ),
        body: ListView(
          key: const Key('manufacturer-control-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const ManufacturerCard(
              color: Color(0xFFF4F3FF),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: MoolColors.navy,
                    foregroundColor: Colors.white,
                    child: Text(
                      'MFR',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operating model: Manufacturer',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Verified factory · input mapping enabled',
                          style: TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ManufacturerPill(label: 'VERIFIED'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ManufacturerControlTab.values
                    .map(
                      (tab) => Padding(
                        padding: const EdgeInsets.only(right: MoolSpacing.xs),
                        child: MoolSegment(
                          key: Key('manufacturer-control-tab-${tab.name}'),
                          label:
                              tab.name[0].toUpperCase() + tab.name.substring(1),
                          selected: session.controlTab == tab,
                          onPressed: () => session.setControlTab(tab),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Row(
              children: [
                Expanded(
                  child: ManufacturerMetric(
                    label: 'OPEN CASES',
                    value: '3',
                    detail: 'evidence held',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: ManufacturerMetric(
                    label: 'TEAM',
                    value: '8',
                    detail: 'least privilege',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: ManufacturerMetric(
                    label: 'READY',
                    value: '96%',
                    detail: '2 alerts',
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.md),
            ...switch (session.controlTab) {
              ManufacturerControlTab.claims => _claims(context),
              ManufacturerControlTab.team => _team(context),
              ManufacturerControlTab.settings => _settings(context),
              ManufacturerControlTab.support => _support(context),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _claims(BuildContext context) => [
    const ManufacturerSectionTitle(
      title: 'Open cases',
      detail: 'evidence · money · resolution',
    ),
    const SizedBox(height: MoolSpacing.sm),
    ...reviewManufacturerClaims.map(
      (claim) => Padding(
        padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
        child: ManufacturerActionRow(
          keyName: 'manufacturer-claim-${claim.id}',
          icon: Icons.gavel_outlined,
          title: claim.title,
          detail: claim.detail,
          meta: claim.hold,
          action: 'Review',
          onTap: () {
            session.selectClaim(claim.id);
            _claimSheet(context);
          },
        ),
      ),
    ),
  ];

  List<Widget> _team(BuildContext context) => [
    Row(
      children: [
        const Expanded(
          child: ManufacturerSectionTitle(
            title: 'Team access',
            detail: 'least privilege',
          ),
        ),
        TextButton.icon(
          key: const Key('manufacturer-team-invite'),
          onPressed: session.openTeamInvite,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Invite'),
        ),
      ],
    ),
    const SizedBox(height: MoolSpacing.sm),
    if (session.teamInviteOpen) ...[
      ManufacturerCard(
        keyName: 'manufacturer-team-invite-panel',
        color: const Color(0xFFF4F3FF),
        child: Column(
          children: [
            TextFormField(
              key: const Key('manufacturer-team-name'),
              initialValue: session.teamInviteName,
              onChanged: session.setTeamInviteName,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            TextFormField(
              key: const Key('manufacturer-team-mobile'),
              initialValue: session.teamInviteMobile,
              onChanged: session.setTeamInviteMobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            DropdownButtonFormField<String>(
              key: const Key('manufacturer-team-role'),
              isExpanded: true,
              initialValue: session.teamInviteRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: ['Sales', 'Production', 'Dispatch', 'Accounts']
                  .map(
                    (role) => DropdownMenuItem(value: role, child: Text(role)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) session.setTeamInviteRole(value);
              },
            ),
            const SizedBox(height: MoolSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('manufacturer-team-cancel'),
                    onPressed: session.closeTeamInvite,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: FilledButton(
                    key: const Key('manufacturer-team-send'),
                    onPressed: session.busy ? null : session.sendTeamInvite,
                    child: Text(
                      session.teamInviteId == null ? 'Send invite' : 'Sent',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: MoolSpacing.sm),
    ],
    ...reviewManufacturerTeam.map(
      (member) => Padding(
        padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
        child: ManufacturerActionRow(
          keyName: 'manufacturer-team-${member.id}',
          icon: Icons.person_outline_rounded,
          title: '${member.name} · ${member.role}',
          detail: member.access,
          action: 'Manage',
          onTap: () => _detailSheet(
            context,
            '${member.name} · ${member.role}',
            '${member.access}. Devices, sessions and changes are audited.',
          ),
        ),
      ),
    ),
  ];

  List<Widget> _settings(BuildContext context) => [
    const ManufacturerSectionTitle(
      title: 'Operating settings',
      detail: 'Verified business type',
    ),
    const SizedBox(height: MoolSpacing.sm),
    ...[
      (
        'business',
        Icons.verified_outlined,
        'Business & GST',
        'GSTIN, bank, address and authorised person',
      ),
      (
        'model',
        Icons.factory_outlined,
        'Manufacturer model',
        'Trader activity requires separate verification',
      ),
      (
        'capacity',
        Icons.precision_manufacturing_outlined,
        'Factory & Capacity',
        'Location, lines, hours and dispatch cut-off',
      ),
      (
        'fleet',
        Icons.local_shipping_outlined,
        'Fleet & Delivery',
        'Own fleet and MoolSocial Transport defaults',
      ),
      (
        'security',
        Icons.security_outlined,
        'Devices & Approvals',
        'MFA, sessions and money approvals',
      ),
      (
        'alerts',
        Icons.notifications_none_rounded,
        'Orders & Alerts',
        'Push, SMS, email and permitted WhatsApp',
      ),
    ].map(
      (setting) => Padding(
        padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
        child: ManufacturerActionRow(
          keyName: 'manufacturer-setting-${setting.$1}',
          icon: setting.$2,
          title: setting.$3,
          detail: setting.$4,
          action: 'Review',
          onTap: () => _detailSheet(
            context,
            setting.$3,
            '${setting.$4}. Only permitted team members can save this change.',
          ),
        ),
      ),
    ),
    const SizedBox(height: MoolSpacing.sm),
    FilledButton(
      key: const Key('manufacturer-settings-save'),
      onPressed: session.busy ? null : session.saveWorkspaceSettings,
      child: Text(
        session.settingsVersion == null
            ? 'Save workspace settings'
            : 'Settings saved',
      ),
    ),
  ];

  List<Widget> _support(BuildContext context) => [
    const ManufacturerCard(
      color: Color(0xFFF4F3FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MoolSocial Business Support',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: MoolSpacing.xs),
          Text(
            'Order, transport, payment, GST and workspace help remains linked to the affected record.',
            style: TextStyle(color: MoolColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
    const SizedBox(height: MoolSpacing.sm),
    ...[
      (
        'order',
        Icons.receipt_long_outlined,
        'Order support',
        'Average response 8 min',
      ),
      (
        'money',
        Icons.account_balance_outlined,
        'Money support',
        'Payment-ledger case',
      ),
      (
        'gst',
        Icons.description_outlined,
        'GST & documents',
        'Qualified professionals',
      ),
      ('security', Icons.security_outlined, 'Security', '24×7 priority'),
    ].map(
      (item) => Padding(
        padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
        child: ManufacturerActionRow(
          keyName: 'manufacturer-support-${item.$1}',
          icon: item.$2,
          title: item.$3,
          detail: item.$4,
          action: 'Start',
          onTap: () => context.go(
            '/app/chat/thread/order-support?return=/app/manufacturer/control?tab=support',
          ),
        ),
      ),
    ),
  ];

  Future<void> _claimSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('manufacturer-claim-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.selectedClaim.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(session.selectedClaim.detail),
                const SizedBox(height: MoolSpacing.sm),
                Wrap(
                  spacing: MoolSpacing.xs,
                  children:
                      [
                            'Approve matched quantity',
                            'Request evidence',
                            'Reject with evidence',
                          ]
                          .map(
                            (outcome) => ChoiceChip(
                              key: Key(
                                'manufacturer-claim-outcome-${outcome.toLowerCase().replaceAll(' ', '-')}',
                              ),
                              label: Text(outcome),
                              selected: session.claimOutcome == outcome,
                              onSelected: (_) =>
                                  session.setClaimOutcome(outcome),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: MoolSpacing.xs),
                TextFormField(
                  key: const Key('manufacturer-claim-message'),
                  initialValue: session.claimMessage,
                  minLines: 2,
                  maxLines: 4,
                  onChanged: session.setClaimMessage,
                  decoration: const InputDecoration(
                    labelText: 'Evidence-based response',
                  ),
                ),
                CheckboxListTile(
                  key: const Key('manufacturer-claim-evidence'),
                  contentPadding: EdgeInsets.zero,
                  value: session.claimEvidenceAttached,
                  onChanged: (value) =>
                      session.setClaimEvidence(value ?? false),
                  title: const Text('Evidence attached and reviewed'),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('manufacturer-claim-resolve'),
                    onPressed: session.busy
                        ? null
                        : () async {
                            final ok = await session.resolveClaim();
                            if (ok && sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                    child: Text(
                      session.claimResolutionId == null
                          ? 'Confirm auditable outcome'
                          : 'Resolved',
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

class ManufacturerServicesScreen extends StatelessWidget {
  const ManufacturerServicesScreen({
    required this.session,
    required this.initialTab,
    super.key,
  });

  final ManufacturerSession session;
  final ManufacturerServiceTab initialTab;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => ManufacturerPageScaffold(
        session: session,
        title: 'Business Services',
        subtitle: 'Professional products for manufacturers',
        activeDock: 'none',
        returnRoute: '/app/manufacturer',
        trailing: IconButton.outlined(
          key: const Key('manufacturer-services-help'),
          tooltip: 'Business services help',
          onPressed: () => _detailSheet(
            context,
            'Business Services help',
            'See coverage, charges, expected result, proof and cancellation terms before you request a service.',
          ),
          icon: const Icon(Icons.help_outline_rounded),
        ),
        body: ListView(
          key: const Key('manufacturer-services-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const ManufacturerCard(
              color: Color(0xFFF4F3FF),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: MoolColors.navy,
                    foregroundColor: Colors.white,
                    child: Text(
                      'MS',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Separate plans · measurable outcomes',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Every charge and cancellation rule appears before activation.',
                          style: TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ManufacturerPill(label: '2 ACTIVE'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            MoolGlassSurface(
              padding: const EdgeInsets.all(MoolSpacing.xxs),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ManufacturerServiceTab.values
                      .map(
                        (tab) => Padding(
                          padding: const EdgeInsets.only(right: MoolSpacing.xs),
                          child: MoolSegment(
                            key: Key('manufacturer-services-tab-${tab.name}'),
                            label: switch (tab) {
                              ManufacturerServiceTab.services => 'All services',
                              ManufacturerServiceTab.active => 'Active',
                              ManufacturerServiceTab.requests => 'Requests',
                            },
                            selected: session.serviceTab == tab,
                            onPressed: () => session.setServiceTab(tab),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            ...switch (session.serviceTab) {
              ManufacturerServiceTab.services => _services(context),
              ManufacturerServiceTab.active => _active(context),
              ManufacturerServiceTab.requests => _requests(context),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _services(BuildContext context) => [
    const ManufacturerSectionTitle(
      title: 'Manufacturer services',
      detail: 'Plan and price first',
    ),
    const SizedBox(height: MoolSpacing.sm),
    ...reviewManufacturerServices.map(
      (service) => Padding(
        padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
        child: ManufacturerCard(
          keyName: 'manufacturer-service-${service.id}',
          onTap: () {
            session.selectService(service.id);
            _serviceSheet(context);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: MoolColors.navy.withValues(alpha: .08),
                    foregroundColor: MoolColors.navy,
                    child: Text(
                      service.mark,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          service.detail,
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ManufacturerPill(
                    label: service.scope.toUpperCase(),
                    color: MoolColors.navy,
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _GrowthFact(label: 'Base', value: service.base),
                  ),
                  Expanded(
                    child: _GrowthFact(
                      label: 'Outcome charge',
                      value: service.outcomeCharge,
                    ),
                  ),
                  const Expanded(
                    child: _GrowthFact(
                      label: 'Activation',
                      value: 'After approval',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'See plan and price  ›',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ];

  List<Widget> _active(BuildContext context) => [
    const ManufacturerSectionTitle(
      title: 'Active services',
      detail: 'Usage and evidence',
    ),
    const SizedBox(height: MoolSpacing.sm),
    const _ServiceProgress(
      keyName: 'manufacturer-service-active-logistics',
      title: 'Product Pickup & Delivery · Starter',
      detail: 'Jodhpur factory · 12 routes completed',
      progress: .61,
      status: '₹1,820 used of ₹3,000 monthly limit',
    ),
    const SizedBox(height: MoolSpacing.xs),
    const _ServiceProgress(
      keyName: 'manufacturer-service-active-tax',
      title: 'GST, Accounts & Books · Monthly',
      detail: 'Books updated · 2 supplier documents required',
      progress: .86,
      status: 'July readiness 86% · professional review pending',
    ),
  ];

  List<Widget> _requests(BuildContext context) => [
    const ManufacturerSectionTitle(
      title: 'Service requests',
      detail: 'No charge before approval',
    ),
    const SizedBox(height: MoolSpacing.sm),
    _ServiceProgress(
      keyName: 'manufacturer-service-request-current',
      title: session.serviceRequestId == null
          ? 'Exclusive Rajasthan Sales Contract'
          : '${session.selectedService.name} · ${session.serviceRequestId}',
      detail: 'Coverage and availability check',
      progress: session.serviceRequestId == null ? .35 : .20,
      status: 'Commercial proposal due within 1 business day',
    ),
    const SizedBox(height: MoolSpacing.xs),
    const _ServiceProgress(
      keyName: 'manufacturer-service-request-source',
      title: 'Exclusive Oilseed Sourcing',
      detail: 'Input category and quality specification under review',
      progress: .58,
      status: '3 verified sources shortlisted',
    ),
  ];

  Future<void> _serviceSheet(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final service = session.selectedService;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: SingleChildScrollView(
              child: Column(
                key: const Key('manufacturer-service-sheet'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  Text(service.detail),
                  const SizedBox(height: MoolSpacing.md),
                  ManufacturerCard(
                    color: const Color(0xFFF4F3FF),
                    child: Column(
                      children: [
                        _ServiceLine(label: 'Territory', value: service.scope),
                        _ServiceLine(label: 'Base', value: service.base),
                        _ServiceLine(
                          label: 'Success charge',
                          value: service.outcomeCharge,
                        ),
                        const _ServiceLine(
                          label: 'Minimum term',
                          value: 'Monthly',
                        ),
                        const _ServiceLine(
                          label: 'Evidence',
                          value: 'Approved outcome proof',
                        ),
                        const _ServiceLine(
                          label: 'Cancellation',
                          value: 'Plan-specific · before approval',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  Text(
                    service.id == 'tax'
                        ? 'Filing, advice and statutory audit are performed only by appropriately qualified professionals.'
                        : 'Exclusive coverage starts only after location, service level, duration and availability are confirmed.',
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  CheckboxListTile(
                    key: const Key('manufacturer-service-terms'),
                    contentPadding: EdgeInsets.zero,
                    value: session.serviceTermsAccepted,
                    onChanged: (value) =>
                        session.acceptServiceTerms(value ?? false),
                    title: const Text(
                      'I reviewed coverage, charges, proof and cancellation',
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('manufacturer-service-request'),
                      onPressed: session.busy
                          ? null
                          : () async {
                              final ok = await session.requestService();
                              if (ok && sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      child: Text(
                        session.serviceRequestId == null
                            ? 'Request approval'
                            : 'Request submitted',
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

class _GrowthFact extends StatelessWidget {
  const _GrowthFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: MoolColors.muted, fontSize: 9)),
      Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: MoolColors.navy,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _ServiceProgress extends StatelessWidget {
  const _ServiceProgress({
    required this.keyName,
    required this.title,
    required this.detail,
    required this.progress,
    required this.status,
  });

  final String keyName;
  final String title;
  final String detail;
  final double progress;
  final String status;

  @override
  Widget build(BuildContext context) => ManufacturerCard(
    keyName: keyName,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(
          detail,
          style: const TextStyle(color: MoolColors.muted, fontSize: 11),
        ),
        const SizedBox(height: MoolSpacing.sm),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: MoolSpacing.xs),
        Text(
          status,
          style: const TextStyle(
            color: MoolColors.success,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _ServiceLine extends StatelessWidget {
  const _ServiceLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xxs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

Future<void> _detailSheet(BuildContext context, String title, String detail) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: Column(
            key: const Key('manufacturer-growth-detail-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              Text(detail),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('manufacturer-growth-detail-done'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
