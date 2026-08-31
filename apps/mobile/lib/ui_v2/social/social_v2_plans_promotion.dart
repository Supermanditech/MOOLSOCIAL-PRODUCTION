import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/creator/creator_session.dart';
import '../../features/retailer/retailer_campaign_models.dart';
import '../../features/retailer/retailer_session.dart';
import '../../features/shared/shared_session.dart';
import 'social_v2_creator.dart';
import 'social_v2_design.dart';

class _PlanData {
  const _PlanData(
    this.id,
    this.name,
    this.workspace,
    this.summary,
    this.benefits,
  );
  final String id;
  final String name;
  final String workspace;
  final String summary;
  final List<String> benefits;
}

const _plans = <_PlanData>[
  _PlanData(
    'free',
    'Free',
    'Personal account',
    'Watch, connect, buy, book, pay and use essential MoolSocial services.',
    [
      'MoolSocial Shorts, Videos and Feed',
      'Create MoolSocial Reels, posts and carousels',
      'Save, chat and manage personal activity',
    ],
  ),
  _PlanData(
    'creator-pro',
    'Creator Pro',
    'Creator workspace',
    'Publish, distribute, measure and earn through one creator workspace.',
    [
      'Creator Studio and Content Library',
      'Connected-channel publishing',
      'Campaign discovery, performance and earnings',
    ],
  ),
  _PlanData(
    'business-pro',
    'Business Pro',
    'Business workspace',
    'Build reach, receive enquiries and manage business content and campaigns.',
    [
      'Business profile and catalogue',
      'Lead and campaign tools',
      'Team access with assigned roles',
    ],
  ),
  _PlanData(
    'commerce-pro',
    'Commerce Pro',
    'Commerce workspace',
    'Operate retail and wholesale selling with measurable Social promotion.',
    [
      'Retail and wholesale catalogue tools',
      'Order, fulfilment and settlement workspace',
      'Commerce attribution and promotion controls',
    ],
  ),
  _PlanData(
    'enterprise',
    'Enterprise',
    'Organisation workspace',
    'Coordinate brands, teams, governance and high-volume operations.',
    [
      'Multiple managed workspaces',
      'Organisation roles and approvals',
      'Governed data and integration support',
    ],
  ),
];

class SocialPlansV2Screen extends StatefulWidget {
  const SocialPlansV2Screen({
    required this.sharedSession,
    required this.retailerSession,
    required this.creatorSession,
    super.key,
  });

  final SharedSession sharedSession;
  final RetailerSession retailerSession;
  final CreatorSession creatorSession;

  @override
  State<SocialPlansV2Screen> createState() => _SocialPlansV2ScreenState();
}

class _SocialPlansV2ScreenState extends State<SocialPlansV2Screen> {
  String _filter = 'All plans';

  @override
  Widget build(BuildContext context) {
    final visible = switch (_filter) {
      'Personal' => _plans.where((plan) => plan.id == 'free').toList(),
      'Professional' =>
        _plans
            .where(
              (plan) => [
                'creator-pro',
                'business-pro',
                'commerce-pro',
              ].contains(plan.id),
            )
            .toList(),
      'Organisation' =>
        _plans.where((plan) => plan.id == 'enterprise').toList(),
      _ => _plans,
    };
    return AnimatedBuilder(
      animation: widget.sharedSession,
      builder: (context, _) => SocialV2Scaffold(
        title: 'Plans & Access',
        subtitle: 'Choose capabilities for your active workspace',
        selectedTab: SocialV2Tab.mool,
        onBack: () => Navigator.of(context).pop(),
        onTab: (_) {},
        onCreatorWorkspace: _openCreator,
        bottomRail: _PlanBottomRail(
          selected: 'plans',
          onPlans: () {},
          onPromote: _openPromotion,
          onStudio: _openCreator,
        ),
        body: SocialV2PageList(
          children: [
            const SocialV2Notice(
              title: 'Launch access is active until 30 September 2026',
              detail:
                  'No automatic charge. Any paid price and renewal terms will be shown for your approval before activation.',
            ),
            const SocialV2Hero(
              eyebrow: 'One account · capabilities by workspace',
              title:
                  'Start free. Add professional tools only when you need them.',
              detail:
                  'Your identity, purchases, followers and personal activity remain together.',
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'All plans', label: Text('All plans')),
                  ButtonSegment(value: 'Personal', label: Text('Personal')),
                  ButtonSegment(
                    value: 'Professional',
                    label: Text('Professional'),
                  ),
                  ButtonSegment(
                    value: 'Organisation',
                    label: Text('Organisation'),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (values) =>
                    setState(() => _filter = values.first),
              ),
            ),
            for (final plan in visible)
              _PlanCard(
                plan: plan,
                active:
                    plan.id == 'free' ||
                    (plan.id == 'creator-pro' &&
                        widget.sharedSession.subscriptionActive),
                onTap: () => _openPlan(plan),
              ),
            const SocialV2Notice(
              title: 'Work opportunities remain open',
              detail:
                  'A paid plan is not required to find work, apply, complete verification or receive eligible earnings.',
              warning: true,
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      _ManagePlanV2Screen(session: widget.sharedSession),
                ),
              ),
              child: const Text('Manage current access'),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlan(_PlanData plan) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _PlanDetailsV2Screen(plan: plan, session: widget.sharedSession),
      ),
    );
  }

  void _openCreator() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreatorSocialV2Screen(
          session: widget.creatorSession,
          owner: CreatorSocialV2Owner.home,
        ),
      ),
    );
  }

  void _openPromotion() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SocialPromotionV2Screen(session: widget.retailerSession),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.active,
    required this.onTap,
  });
  final _PlanData plan;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SocialV2Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    color: SocialV2Colors.navy,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Chip(label: Text(active ? 'Active' : 'Launch access')),
            ],
          ),
          Text(
            plan.workspace,
            style: const TextStyle(
              color: SocialV2Colors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.summary,
            style: const TextStyle(
              color: SocialV2Colors.muted,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final benefit in plan.benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: SocialV2Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 7),
          active
              ? OutlinedButton(
                  onPressed: onTap,
                  child: const Text('View current access'),
                )
              : FilledButton(
                  onPressed: onTap,
                  child: Text('Check ${plan.name}'),
                ),
        ],
      ),
    );
  }
}

class _PlanDetailsV2Screen extends StatefulWidget {
  const _PlanDetailsV2Screen({required this.plan, required this.session});
  final _PlanData plan;
  final SharedSession session;

  @override
  State<_PlanDetailsV2Screen> createState() => _PlanDetailsV2ScreenState();
}

class _PlanDetailsV2ScreenState extends State<_PlanDetailsV2Screen> {
  bool _consent = false;
  bool _showActivation = false;

  @override
  Widget build(BuildContext context) {
    return SocialV2Scaffold(
      title: 'Plan Details',
      subtitle: 'Check access and limits before activation',
      selectedTab: SocialV2Tab.mool,
      onBack: () => Navigator.of(context).pop(),
      onTab: (tab) => _leaveForSocialDestination(context, tab),
      body: _showActivation ? _activation() : _details(),
    );
  }

  Widget _details() {
    return SocialV2PageList(
      children: [
        SocialV2Hero(
          eyebrow: widget.plan.workspace,
          title: widget.plan.name,
          detail: widget.plan.summary,
        ),
        const SocialV2Notice(
          title: 'Launch access is active until 30 September 2026',
          detail:
              'No automatic charge. Paid terms will require your explicit approval.',
        ),
        SocialV2Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SocialV2SectionTitle('Included capabilities'),
              const SizedBox(height: 8),
              for (final benefit in widget.plan.benefits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '✓  $benefit',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SocialV2Notice(
          title: 'Before paid activation',
          detail:
              'Price, billing period, taxes, usage limits, renewal date and cancellation terms will appear first.',
          warning: true,
        ),
        FilledButton(
          key: const Key('social-v2-open-plan-activation'),
          onPressed: () => setState(() => _showActivation = true),
          child: Text('Use ${widget.plan.name} during launch access'),
        ),
      ],
    );
  }

  Widget _activation() {
    return SocialV2PageList(
      key: const ValueKey('social-v2-plan-activation'),
      children: [
        SocialV2Hero(
          eyebrow: 'Confirm access',
          title:
              'Add ${widget.plan.name} to your ${widget.plan.workspace.toLowerCase()}',
          detail: 'Your personal account remains the owner of this workspace.',
        ),
        SocialV2Notice(
          title: '${widget.plan.name} · ₹0 during launch',
          detail: 'Access ends 30 September 2026 · no automatic charge',
        ),
        CheckboxListTile(
          value: _consent,
          onChanged: (value) => setState(() => _consent = value ?? false),
          title: const Text('I understand the launch access period'),
          subtitle: const Text(
            'MoolSocial will ask before any paid activation.',
          ),
        ),
        FilledButton(
          key: const Key('social-v2-activate-plan'),
          onPressed: () {
            if (!_consent) {
              showSocialV2Message(
                context,
                'Confirm the launch access period to continue',
              );
              return;
            }
            widget.session.setSubscriptionActive(true);
            showSocialV2Message(
              context,
              '${widget.plan.name} launch access is active',
            );
          },
          child: const Text('Activate launch access'),
        ),
        OutlinedButton(
          onPressed: () => setState(() => _showActivation = false),
          child: const Text('Back to plan details'),
        ),
      ],
    );
  }
}

enum _ManagePlanView { home, cancel, invoice }

class _ManagePlanV2Screen extends StatefulWidget {
  const _ManagePlanV2Screen({required this.session});
  final SharedSession session;
  @override
  State<_ManagePlanV2Screen> createState() => _ManagePlanV2ScreenState();
}

class _ManagePlanV2ScreenState extends State<_ManagePlanV2Screen> {
  bool _confirmEnd = false;
  _ManagePlanView _view = _ManagePlanView.home;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => SocialV2Scaffold(
        title: 'Manage Subscription',
        subtitle: 'Your plan, access period, usage and billing',
        selectedTab: SocialV2Tab.mool,
        onBack: () => Navigator.of(context).pop(),
        onTab: (tab) => _leaveForSocialDestination(context, tab),
        body: switch (_view) {
          _ManagePlanView.home => _home(),
          _ManagePlanView.cancel => _cancel(),
          _ManagePlanView.invoice => _invoice(),
        },
      ),
    );
  }

  Widget _home() {
    return SocialV2PageList(
      key: const ValueKey('social-v2-manage-plan-home'),
      children: [
        const SocialV2Hero(
          eyebrow: 'Current personal access',
          title: 'Free',
          detail: 'Active · no payment method required',
        ),
        if (widget.session.subscriptionActive)
          const SocialV2Notice(
            title: 'Creator Pro launch access',
            detail: 'Ends 30 September 2026 · no automatic renewal',
          )
        else
          const SocialV2Notice(
            title: 'No professional plan is active',
            detail: 'Your personal account and work access remain available.',
            warning: true,
          ),
        SocialV2ListTile(
          icon: Icons.receipt_long_outlined,
          title: 'Access and billing history',
          detail: 'Launch access confirmation and future invoices',
          onTap: () => setState(() => _view = _ManagePlanView.invoice),
        ),
        SocialV2ListTile(
          icon: Icons.compare_arrows_rounded,
          title: 'Change plan',
          detail: 'Compare capabilities before changing access',
          onTap: () => Navigator.of(context).pop(),
        ),
        if (widget.session.subscriptionActive)
          SocialV2ListTile(
            icon: Icons.close_rounded,
            title: 'End launch access',
            detail: 'Creator workspace content remains in your account',
            onTap: () => setState(() => _view = _ManagePlanView.cancel),
          ),
      ],
    );
  }

  Widget _cancel() {
    return SocialV2PageList(
      key: const ValueKey('social-v2-manage-plan-cancel'),
      children: [
        const SocialV2Hero(
          eyebrow: 'Creator Pro',
          title: 'Keep your content and end professional access',
          detail:
              'Your personal account, followers, posts and payable earnings remain available.',
        ),
        const SocialV2Notice(
          title: 'What changes after the access end date',
          detail:
              'Connected publishing and new campaign acceptance stop. Published MoolSocial content remains on your profile.',
          warning: true,
        ),
        CheckboxListTile(
          value: _confirmEnd,
          onChanged: (value) => setState(() => _confirmEnd = value ?? false),
          title: const Text('End access on 30 September 2026'),
          subtitle: const Text(
            'This does not delete your Creator workspace or content.',
          ),
        ),
        FilledButton(
          key: const Key('social-v2-confirm-end-plan'),
          onPressed: () {
            if (!_confirmEnd) {
              showSocialV2Message(
                context,
                'Confirm the access end date to continue',
              );
              return;
            }
            widget.session.setSubscriptionActive(false);
            setState(() => _view = _ManagePlanView.home);
            showSocialV2Message(
              context,
              'Access will end on 30 September 2026',
            );
          },
          child: const Text('Confirm end date'),
        ),
        OutlinedButton(
          onPressed: () => setState(() => _view = _ManagePlanView.home),
          child: const Text('Keep access'),
        ),
      ],
    );
  }

  Widget _invoice() {
    return SocialV2PageList(
      key: const ValueKey('social-v2-manage-plan-invoice'),
      children: [
        const SocialV2SectionTitle(
          'Access and billing history',
          detail: 'Records appear when a charge or credit exists',
        ),
        const SocialV2ListTile(
          icon: Icons.receipt_long_outlined,
          title: 'Creator Pro launch access',
          detail: '20 July–30 September 2026 · confirmed 20 July 2026',
          badge: '₹0',
        ),
        const SocialV2Notice(
          title: 'No paid invoice yet',
          detail:
              'A tax invoice will appear only after an explicitly approved payment.',
        ),
        OutlinedButton(
          onPressed: () => setState(() => _view = _ManagePlanView.home),
          child: const Text('Return to current access'),
        ),
      ],
    );
  }
}

class SocialPromotionV2Screen extends StatefulWidget {
  const SocialPromotionV2Screen({
    required this.session,
    this.initialState,
    this.initialStep,
    super.key,
  });
  final RetailerSession session;
  final String? initialState;
  final int? initialStep;

  @override
  State<SocialPromotionV2Screen> createState() =>
      _SocialPromotionV2ScreenState();
}

class _SocialPromotionV2ScreenState extends State<SocialPromotionV2Screen> {
  late int _step = (widget.initialStep ?? 1).clamp(1, 5) - 1;
  late String _outcomeState = widget.initialState ?? '';
  String _content = 'Morning market Reel';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => SocialV2Scaffold(
        title: 'Promote on MoolSocial',
        subtitle: 'Create a measurable campaign for a real outcome',
        selectedTab: SocialV2Tab.mool,
        onBack: () => Navigator.of(context).pop(),
        onTab: (_) {},
        bottomRail: _PlanBottomRail(
          selected: 'promote',
          onPlans: () => Navigator.of(context).pop(),
          onPromote: () {},
          onStudio: () {},
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_outcomeState == 'failure') return _failure();
    if (_outcomeState == 'live') return _live();
    return switch (_step) {
      0 => _goal(),
      1 => _contentStep(),
      2 => _audience(),
      3 => _budget(),
      _ => _confirmation(),
    };
  }

  Widget _goal() {
    final choices = <(RetailerCampaignObjective, String, String)>[
      (
        RetailerCampaignObjective.increaseSales,
        'Sales',
        'Drive attributable MoolSocial orders',
      ),
      (
        RetailerCampaignObjective.bringCustomersBack,
        'Leads',
        'Receive eligible customer enquiries',
      ),
      (
        RetailerCampaignObjective.clearSlowStock,
        'Reach',
        'Show content to a relevant MoolSocial audience',
      ),
      (
        RetailerCampaignObjective.reachNewArea,
        'Visits',
        'Bring people to a MoolSocial shop or profile',
      ),
    ];
    return SocialV2PageList(
      key: const ValueKey('social-promotion-goal'),
      children: [
        const SocialV2Hero(
          eyebrow: 'MoolSocial promotion',
          title: 'What outcome matters most?',
          detail: 'Campaign reporting follows the goal you choose.',
        ),
        for (final choice in choices)
          SocialV2ListTile(
            icon: Icons.campaign_outlined,
            title: choice.$2,
            detail: choice.$3,
            onTap: () {
              widget.session.setCampaignObjective(choice.$1);
              setState(() => _step = 1);
            },
          ),
        const SocialV2Notice(
          title: 'Campaign spend is separate from your MoolSocial plan',
          detail:
              'You choose the total budget and approve payment before the campaign starts.',
        ),
      ],
    );
  }

  Widget _contentStep() {
    return SocialV2PageList(
      key: const ValueKey('social-promotion-content'),
      children: [
        const _CampaignProgress(step: 1),
        const SocialV2SectionTitle(
          'Choose what people will see',
          detail: 'Requirements and destination appear before payment',
        ),
        SocialV2ListTile(
          icon: Icons.play_circle_outline,
          title: 'Morning market Reel',
          detail: 'MoolSocial Reel · product destination ready',
          badge: 'Recommended',
          onTap: () {
            setState(() {
              _content = 'Morning market Reel';
              _step = 2;
            });
          },
        ),
        SocialV2ListTile(
          icon: Icons.view_carousel_outlined,
          title: 'Blue City morning Carousel',
          detail: 'MoolSocial Feed · profile destination ready',
          onTap: () {
            setState(() {
              _content = 'Blue City morning Carousel';
              _step = 2;
            });
          },
        ),
        OutlinedButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('Back to goal'),
        ),
      ],
    );
  }

  Widget _audience() {
    return SocialV2PageList(
      key: const ValueKey('social-promotion-audience'),
      children: [
        const _CampaignProgress(step: 2),
        const SocialV2SectionTitle(
          'Choose the audience',
          detail: 'Reach people through eligible MoolSocial surfaces',
        ),
        DropdownButtonFormField<RetailerCampaignAudience>(
          initialValue: widget.session.campaignAudience,
          decoration: const InputDecoration(labelText: 'Audience'),
          items: RetailerCampaignAudience.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) widget.session.setCampaignAudience(value);
          },
        ),
        DropdownButtonFormField<int>(
          initialValue: widget.session.campaignRadiusKm,
          decoration: const InputDecoration(
            labelText: 'Distance from serviceable area',
          ),
          items: const [5, 10, 25, 50]
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text('$value km')),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) widget.session.setCampaignRadius(value);
          },
        ),
        const SocialV2Notice(
          title: 'Selected placements',
          detail: 'MoolSocial Shorts · Feed · Video discovery · Search',
        ),
        const SocialV2Notice(
          title: 'YouTube videos continue playing on YouTube',
          detail:
              'MoolSocial promotion never appears inside or over the YouTube player.',
          warning: true,
        ),
        FilledButton(
          onPressed: () => setState(() => _step = 3),
          child: const Text('Continue to budget'),
        ),
        OutlinedButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Back to content'),
        ),
      ],
    );
  }

  Widget _budget() {
    return SocialV2PageList(
      key: const ValueKey('social-promotion-budget'),
      children: [
        const _CampaignProgress(step: 3),
        const SocialV2SectionTitle(
          'Set your total spend',
          detail: 'Estimated delivery updates as choices change',
        ),
        TextFormField(
          key: const Key('social-promotion-budget-input'),
          initialValue: widget.session.campaignSpendCap.toString(),
          keyboardType: TextInputType.number,
          scrollPadding: socialV2InputScrollPadding,
          textInputAction: TextInputAction.done,
          onEditingComplete: () => FocusScope.of(context).unfocus(),
          decoration: const InputDecoration(
            labelText: 'Total campaign budget',
            prefixText: '₹',
          ),
          onChanged: (value) =>
              widget.session.setCampaignSpendCap(int.tryParse(value) ?? 0),
        ),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [500, 1500, 3000, 5000]
              .map(
                (value) => ChoiceChip(
                  label: Text('₹$value'),
                  selected: widget.session.campaignSpendCap == value,
                  onSelected: (_) => widget.session.setCampaignSpendCap(value),
                ),
              )
              .toList(),
        ),
        DropdownButtonFormField<int>(
          initialValue: widget.session.campaignDurationDays,
          decoration: const InputDecoration(labelText: 'Duration'),
          items: const [7, 14, 30]
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text('$value days')),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) widget.session.setCampaignDuration(value);
          },
        ),
        const SocialV2Notice(
          title: 'Estimated reach: 8K–14K',
          detail: 'This is an estimate, not a guaranteed result.',
        ),
        FilledButton(
          onPressed: () => setState(() => _step = 4),
          child: const Text('Check campaign'),
        ),
        OutlinedButton(
          onPressed: () => setState(() => _step = 2),
          child: const Text('Back to audience'),
        ),
      ],
    );
  }

  Widget _confirmation() {
    final session = widget.session;
    return SocialV2PageList(
      key: const ValueKey('social-promotion-check'),
      children: [
        const _CampaignProgress(step: 4),
        const SocialV2SectionTitle(
          'Check before payment',
          detail: 'Nothing starts until payment is approved',
        ),
        SocialV2Card(
          child: Column(
            children: [
              _ReviewRow('Goal', session.campaignObjective.label),
              _ReviewRow('Content', _content),
              _ReviewRow(
                'Audience',
                '${session.campaignAudience.label} · ${session.campaignRadiusKm} km',
              ),
              const _ReviewRow(
                'Placements',
                'Shorts, Feed, discovery and Search',
              ),
              _ReviewRow('Duration', '${session.campaignDurationDays} days'),
              _ReviewRow('Total budget', '₹${session.campaignSpendCap}'),
            ],
          ),
        ),
        const SocialV2Notice(
          title: 'Estimates are not guaranteed results',
          detail:
              'Actual delivery depends on eligible audience, content quality and marketplace activity.',
          warning: true,
        ),
        FilledButton(
          key: const Key('social-v2-campaign-pay'),
          onPressed: _continueToPay,
          child: const Text('Continue to Pay'),
        ),
        OutlinedButton(
          onPressed: () => setState(() => _step = 3),
          child: const Text('Back to budget'),
        ),
      ],
    );
  }

  Future<void> _continueToPay() async {
    widget.session
      ..setCampaignName(_content.isEmpty ? 'Social promotion' : _content)
      ..setCampaignChannel(RetailerCampaignChannel.moolSocial);
    final saved = await widget.session.saveCampaignDraft();
    if (!mounted) return;
    if (!saved) {
      setState(() => _outcomeState = 'failure');
      return;
    }
    context.go(
      '/app/pay/home?source=social-campaign&amount=${widget.session.campaignSpendCap}',
    );
  }

  Widget _failure() {
    return SocialV2PageList(
      key: const ValueKey('social-v2-campaign-payment-recovery'),
      children: [
        const SocialV2Hero(
          eyebrow: 'Saved',
          title: 'Your campaign is saved',
          detail:
              'Payment did not finish. No campaign spend started and no duplicate charge will be created.',
        ),
        FilledButton(
          onPressed: () => setState(() {
            _outcomeState = '';
            _step = 4;
          }),
          child: const Text('Try payment again'),
        ),
        OutlinedButton(
          onPressed: () => setState(() {
            _outcomeState = '';
            _step = 4;
          }),
          child: const Text('Review campaign'),
        ),
      ],
    );
  }

  Widget _live() {
    return SocialV2PageList(
      key: const ValueKey('social-v2-campaign-live'),
      children: [
        const SocialV2Hero(
          eyebrow: 'Campaign ready',
          title: 'Your campaign is ready',
          detail:
              'Delivery begins after the content and payment checks complete.',
        ),
        const SocialV2Notice(
          title: 'In review · ₹0 spent',
          detail: '₹1,500 campaign limit · no delivery begins before approval',
        ),
        SocialV2Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Morning market Reel',
                style: TextStyle(
                  color: SocialV2Colors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: .04,
                color: SocialV2Colors.green,
                backgroundColor: SocialV2Colors.canvas,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 8),
              const Text('Sales goal · Shorts and Feed · 7 days'),
            ],
          ),
        ),
        FilledButton(
          onPressed: () => showSocialV2Message(
            context,
            'Campaign results will appear as eligible delivery begins',
          ),
          child: const Text('View campaign results'),
        ),
        OutlinedButton(
          onPressed: () => setState(() {
            _outcomeState = '';
            _step = 0;
          }),
          child: const Text('Create another campaign'),
        ),
      ],
    );
  }
}

class _CampaignProgress extends StatelessWidget {
  const _CampaignProgress({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) {
    const labels = ['Goal', 'Content', 'Audience', 'Budget', 'Check'];
    return Row(
      children: List.generate(
        labels.length,
        (index) => Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: index <= step
                    ? SocialV2Colors.navy
                    : const Color(0xFFE6E7F0),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: index <= step ? Colors.white : SocialV2Colors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                child: Text(
                  labels[index],
                  style: const TextStyle(
                    color: SocialV2Colors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
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

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: SocialV2Colors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: SocialV2Colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBottomRail extends StatelessWidget {
  const _PlanBottomRail({
    required this.selected,
    required this.onPlans,
    required this.onPromote,
    required this.onStudio,
  });
  final String selected;
  final VoidCallback onPlans;
  final VoidCallback onPromote;
  final VoidCallback onStudio;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData, VoidCallback)>[
      (
        'mool',
        'Mool',
        Icons.grid_view_rounded,
        () => _leaveForSocialDestination(context, SocialV2Tab.mool),
      ),
      ('plans', 'Plans', Icons.wallet_outlined, onPlans),
      ('promote', 'Promote', Icons.campaign_outlined, onPromote),
      ('studio', 'Studio', Icons.home_outlined, onStudio),
      (
        'chat',
        'Chat',
        Icons.chat_bubble_outline_rounded,
        () => _leaveForSocialDestination(context, SocialV2Tab.chat),
      ),
    ];
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: SocialV2Colors.line)),
      ),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: InkWell(
                  onTap: item.$4,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 58,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected == item.$1
                            ? SocialV2Colors.navy
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.$3,
                            size: 21,
                            color: selected == item.$1
                                ? Colors.white
                                : SocialV2Colors.muted,
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            child: Text(
                              item.$2,
                              style: TextStyle(
                                color: selected == item.$1
                                    ? Colors.white
                                    : SocialV2Colors.muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

void _leaveForSocialDestination(BuildContext context, SocialV2Tab tab) {
  final router = GoRouter.of(context);
  Navigator.of(context).popUntil((route) => route.isFirst);
  final location = switch (tab) {
    SocialV2Tab.mool => '/app/mool',
    SocialV2Tab.shorts => '/app/social?sub=shorts',
    SocialV2Tab.videos => '/app/social?sub=videos',
    SocialV2Tab.feed => '/app/social?sub=feed',
    SocialV2Tab.create => '/app/social?sub=create',
    SocialV2Tab.chat => '/app/chat',
  };
  router.go(location);
}
