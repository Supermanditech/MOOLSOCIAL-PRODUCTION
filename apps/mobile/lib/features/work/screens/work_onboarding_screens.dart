import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../widgets/work_widgets.dart';
import '../work_models.dart';
import '../work_session.dart';

class MyWorkScreen extends StatelessWidget {
  const MyWorkScreen({required this.session, super.key});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final workspace = session.activeWorkspace;
        return WorkPageScaffold(
          session: session,
          title: 'My Work',
          subtitle: workspace == null
              ? 'Start and operate verified work'
              : workspace.name,
          fallbackBackRoute: '/app/work/earn',
          activeDock: 'my-work',
          body: ListView(
            key: const Key('my-work-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              if (session.savedOpportunity case final opportunity?) ...[
                WorkCard(
                  color: const Color(0xFFFFF4E5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const WorkPill(
                        label: 'Opportunity saved',
                        color: MoolColors.orange,
                        icon: Icons.bookmark_added_outlined,
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      Text(
                        opportunity.title,
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        workspace == null
                            ? 'Start My Work, then return to apply.'
                            : 'Your verified workspace can apply directly.',
                        style: const TextStyle(color: MoolColors.muted),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      if (workspace != null)
                        WorkPrimaryButton(
                          keyName: 'my-work-return-opportunity',
                          label: 'Return to opportunity',
                          onPressed: () {
                            session.openOpportunity(opportunity.id);
                            context.go(
                              '/app/work/opportunity/${opportunity.id}',
                            );
                          },
                          icon: Icons.arrow_back_rounded,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
              ],
              if (workspace == null)
                _NewWorkState(session: session)
              else ...[
                _ActiveWorkspaceCard(session: session, workspace: workspace),
                const SizedBox(height: MoolSpacing.md),
                const WorkSectionTitle(
                  title: 'Needs attention',
                  detail: 'Only actions that change an outcome appear here',
                ),
                const SizedBox(height: MoolSpacing.sm),
                _AttentionCard(
                  icon: Icons.inventory_2_outlined,
                  title: session.reviewStage == WorkReviewStage.live
                      ? 'Review available stock'
                      : 'Finish shop readiness',
                  detail: session.reviewStage == WorkReviewStage.live
                      ? 'Price, quantity and fulfilment must stay accurate.'
                      : 'Add stock, price and fulfilment before customers see products.',
                  actionLabel: session.reviewStage == WorkReviewStage.live
                      ? 'Open shop'
                      : 'Continue setup',
                  keyName: 'my-work-open-active',
                  onPressed: () => context.go(
                    session.reviewStage == WorkReviewStage.approved
                        ? '/app/work/ready'
                        : session.reviewStage == WorkReviewStage.live
                        ? '/app/retailer/home'
                        : '/app/work/retailer/setup',
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                const _AttentionCard(
                  icon: Icons.payments_outlined,
                  title: 'Settlement ready',
                  detail:
                      'The next payout can be reviewed inside the operating workspace.',
                  actionLabel: 'View summary',
                  keyName: 'my-work-settlement',
                ),
                if (session.otherWorkspaces.isNotEmpty) ...[
                  const SizedBox(height: MoolSpacing.md),
                  const WorkSectionTitle(
                    title: 'Other workspaces',
                    detail: 'Your current workspace stays selected',
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  SizedBox(
                    height: 132,
                    child: ListView.separated(
                      key: const Key('my-work-other-list'),
                      scrollDirection: Axis.horizontal,
                      itemCount: session.otherWorkspaces.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: MoolSpacing.xs),
                      itemBuilder: (context, index) {
                        final other = session.otherWorkspaces[index];
                        return SizedBox(
                          width: 220,
                          child: WorkCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const WorkPill(
                                  label: 'Verified',
                                  icon: Icons.verified_rounded,
                                ),
                                const SizedBox(height: MoolSpacing.xs),
                                Text(
                                  other.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: MoolColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  other.profileLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: MoolColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: MoolSpacing.md),
                OutlinedButton.icon(
                  key: const Key('my-work-add-another'),
                  onPressed: () {
                    session.startAnotherWork();
                    context.go('/app/work/choose');
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Another Work'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NewWorkState extends StatelessWidget {
  const _NewWorkState({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkCard(
          color: MoolColors.navy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start My Work',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              const Text(
                'Choose the exact work or business you operate. Your personal MoolSocial account stays active.',
                style: TextStyle(
                  color: Color(0xFFD9DAFF),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              WorkPrimaryButton(
                keyName: 'my-work-start',
                label: 'Start My Work',
                onPressed: () {
                  session.startMyWork();
                  context.go('/app/work/choose');
                },
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        const WorkCard(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFEAF7E8),
                foregroundColor: MoolColors.success,
                child: Icon(Icons.verified_user_outlined),
              ),
              SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified account contact',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '+91 98••• ••321 · Google account',
                      style: TextStyle(color: MoolColors.muted),
                    ),
                  ],
                ),
              ),
              WorkPill(label: 'Verified'),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        const WorkSectionTitle(
          title: 'How do you want to begin?',
          detail: 'Choose one. You can add another work later.',
        ),
        const SizedBox(height: MoolSpacing.sm),
        _StartChoice(
          keyName: 'my-work-choice-earn',
          icon: Icons.currency_rupee_rounded,
          title: 'Earn with MoolSocial',
          detail: 'Freelancer, delivery, captain or service work',
          onTap: () {
            session.selectFamily('create-work');
            context.go('/app/work/choose');
          },
        ),
        const SizedBox(height: MoolSpacing.xs),
        _StartChoice(
          keyName: 'my-work-choice-business',
          icon: Icons.storefront_outlined,
          title: 'Grow my business',
          detail: 'Shop, food, health, salon, transport or supply',
          onTap: () => context.go('/app/work/choose'),
        ),
        const SizedBox(height: MoolSpacing.xs),
        _StartChoice(
          keyName: 'my-work-choice-create',
          icon: Icons.video_camera_front_outlined,
          title: 'Create or promote',
          detail: 'Creator work and funded campaigns',
          onTap: () {
            session.selectFamily('create-work');
            context.go('/app/work/choose');
          },
        ),
      ],
    );
  }
}

class _StartChoice extends StatelessWidget {
  const _StartChoice({
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEDEEFF),
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
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
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

class _ActiveWorkspaceCard extends StatelessWidget {
  const _ActiveWorkspaceCard({required this.session, required this.workspace});

  final WorkSession session;
  final WorkWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      color: MoolColors.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: MoolColors.orange,
                foregroundColor: MoolColors.navy,
                child: Text(
                  'MF',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workspace.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${workspace.profileLabel} · ${workspace.area}',
                      style: const TextStyle(
                        color: Color(0xFFD9DAFF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const WorkPill(label: 'Verified', color: Color(0xFF9EE89B)),
            ],
          ),
          const SizedBox(height: MoolSpacing.md),
          Row(
            children: [
              _Metric(label: 'Today', value: '18 orders'),
              _Metric(label: 'Sales', value: '₹12,840'),
              _Metric(label: 'To procure', value: '7 items'),
            ],
          ),
          if (workspace.gstReminder) ...[
            const SizedBox(height: MoolSpacing.sm),
            const WorkPill(
              label: 'GST reminder active',
              color: MoolColors.orange,
              icon: Icons.schedule_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBFC2F7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
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

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.keyName,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String actionLabel;
  final String keyName;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEDEEFF),
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
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          TextButton(
            key: Key(keyName),
            onPressed:
                onPressed ??
                () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$actionLabel is ready.')),
                ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class WorkChooseActivityScreen extends StatefulWidget {
  const WorkChooseActivityScreen({required this.session, super.key});

  final WorkSession session;

  @override
  State<WorkChooseActivityScreen> createState() =>
      _WorkChooseActivityScreenState();
}

class _WorkChooseActivityScreenState extends State<WorkChooseActivityScreen> {
  late final TextEditingController _alternate = TextEditingController(
    text: widget.session.alternateMobile,
  );
  final TextEditingController _otp = TextEditingController();

  @override
  void dispose() {
    _alternate.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final family = widget.session.selectedFamilyId;
        final profile = widget.session.selectedProfile;
        return WorkPageScaffold(
          session: widget.session,
          title: 'Choose Your Work',
          subtitle: 'Select one exact profile at a time',
          fallbackBackRoute: '/app/work/my-work',
          activeDock: 'my-work',
          bottomAction: profile == null
              ? null
              : WorkPrimaryButton(
                  keyName: 'work-continue-proof',
                  label: 'Continue to proof',
                  busy: widget.session.busy,
                  onPressed: () {
                    if (widget.session.continueToProof()) {
                      context.go('/app/work/proof');
                    }
                  },
                ),
          body: ListView(
            key: const Key('work-choose-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              const WorkCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0xFFEAF7E8),
                      foregroundColor: MoolColors.success,
                      child: Icon(Icons.verified_user_outlined),
                    ),
                    SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Using your MoolSocial account',
                            style: TextStyle(
                              color: MoolColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '+91 98••• ••321 · identity verified',
                            style: TextStyle(
                              color: MoolColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    WorkPill(label: 'Verified'),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              if (family == null) ...[
                const WorkSectionTitle(
                  title: 'What kind of work do you operate?',
                  detail: 'Only profiles with a complete setup path are shown',
                ),
                const SizedBox(height: MoolSpacing.sm),
                for (final familyId in widget.session.familyIds) ...[
                  _FamilyCard(
                    familyId: familyId,
                    label: widget.session.familyLabel(familyId),
                    onTap: () => widget.session.selectFamily(familyId),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                ],
                OutlinedButton.icon(
                  key: const Key('work-profile-not-shown'),
                  onPressed: () => _showUnsupportedRequest(context),
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('My work is not shown'),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: WorkSectionTitle(
                        title: widget.session.familyLabel(family),
                        detail: profile == null
                            ? 'Choose the exact profile'
                            : 'Selected workspace',
                      ),
                    ),
                    TextButton(
                      key: const Key('work-change-family'),
                      onPressed: widget.session.changeFamily,
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.sm),
                if (profile == null)
                  for (final option in widget.session.profilesForFamily(
                    family,
                  )) ...[
                    _ProfileCard(
                      option: option,
                      selected: false,
                      onTap: () => widget.session.selectProfile(option.id),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                  ]
                else ...[
                  _ProfileCard(option: profile, selected: true),
                  const SizedBox(height: MoolSpacing.md),
                  const WorkSectionTitle(
                    title: 'Workspace contact',
                    detail: 'Your verified account contact is carried forward',
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  const WorkCard(
                    child: _ContactRow(
                      label: 'Primary contact',
                      value: '+91 98••• ••321',
                      state: 'Verified',
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  TextField(
                    key: const Key('work-alternate-mobile'),
                    controller: _alternate,
                    enabled: !widget.session.alternateVerified,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Alternate work number · optional',
                      prefixText: '+91 ',
                      suffixIcon: widget.session.alternateVerified
                          ? const Icon(
                              Icons.verified_rounded,
                              color: MoolColors.success,
                            )
                          : null,
                    ),
                  ),
                  if (!widget.session.alternateOtpSent)
                    TextButton(
                      key: const Key('work-send-alternate-otp'),
                      onPressed: widget.session.busy
                          ? null
                          : () => widget.session.sendAlternateOtp(
                              _alternate.text,
                            ),
                      child: const Text('Send OTP'),
                    )
                  else if (!widget.session.alternateVerified) ...[
                    const SizedBox(height: MoolSpacing.xs),
                    TextField(
                      key: const Key('work-alternate-otp'),
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: '6-digit OTP',
                        counterText: '',
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('work-change-alternate'),
                            onPressed: () {
                              widget.session.removeAlternateMobile();
                              _alternate.clear();
                              _otp.clear();
                            },
                            child: const Text('Change'),
                          ),
                        ),
                        const SizedBox(width: MoolSpacing.xs),
                        Expanded(
                          child: FilledButton(
                            key: const Key('work-verify-alternate'),
                            onPressed: () =>
                                widget.session.verifyAlternateOtp(_otp.text),
                            child: const Text('Verify'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUnsupportedRequest(BuildContext context) {
    final workspace = TextEditingController();
    final area = TextEditingController();
    var family = '';
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.lg,
            0,
            MoolSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Request a work profile',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Tell us what you operate. This request will not create a workspace.',
                  style: TextStyle(color: MoolColors.muted),
                ),
                const SizedBox(height: MoolSpacing.md),
                TextField(
                  key: const Key('work-request-profile-name'),
                  controller: workspace,
                  decoration: const InputDecoration(
                    labelText: 'Workspace you need',
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                DropdownButtonFormField<String>(
                  key: const Key('work-request-family'),
                  initialValue: family.isEmpty ? null : family,
                  decoration: const InputDecoration(
                    labelText: 'Closest work area',
                  ),
                  items:
                      const [
                            'Products & Trade',
                            'Food Business',
                            'Health & Medicine',
                            'Services & Salon',
                            'Ride & Transport',
                            'Create & Work',
                            'Other',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setSheetState(() => family = value ?? ''),
                ),
                const SizedBox(height: MoolSpacing.sm),
                TextField(
                  key: const Key('work-request-area'),
                  controller: area,
                  decoration: const InputDecoration(
                    labelText: 'Operating city or area',
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                FilledButton(
                  key: const Key('work-send-profile-request'),
                  onPressed: () async {
                    final sent = await widget.session.sendUnsupportedRequest(
                      workspace: workspace.text,
                      family: family,
                      area: area.text,
                    );
                    if (sent && sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                  child: const Text('Send request'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Back to cards'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.familyId,
    required this.label,
    required this.onTap,
  });

  final String familyId;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (familyId) {
      'products-trade' => Icons.inventory_2_outlined,
      'food-business' => Icons.restaurant_outlined,
      'health' => Icons.medical_services_outlined,
      'services' => Icons.handyman_outlined,
      'ride' => Icons.local_shipping_outlined,
      _ => Icons.work_outline_rounded,
    };
    return WorkCard(
      keyName: 'work-family-$familyId',
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEDEEFF),
            foregroundColor: MoolColors.navy,
            child: Icon(icon),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: MoolColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.option,
    required this.selected,
    this.onTap,
  });

  final WorkProfileOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      keyName: 'work-profile-${option.id}',
      onTap: onTap,
      color: selected ? const Color(0xFFEDEEFF) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: selected
                    ? MoolColors.navy
                    : const Color(0xFFEDEEFF),
                foregroundColor: selected ? Colors.white : MoolColors.navy,
                child: Icon(option.icon),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Text(
                  option.label,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: MoolColors.success,
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
          if (selected) ...[
            const Divider(height: MoolSpacing.lg),
            _PreviewRow(label: 'Sell / Serve', value: option.sellSide),
            _PreviewRow(label: 'Buy / Procure', value: option.buySide),
            _PreviewRow(label: 'Operate', value: option.tools),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Proof is requested only after this exact profile is confirmed.',
              style: TextStyle(
                color: MoolColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: MoolColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.label,
    required this.value,
    required this.state,
  });

  final String label;
  final String value;
  final String state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        WorkPill(label: state),
      ],
    );
  }
}

class WorkProfileProofScreen extends StatefulWidget {
  const WorkProfileProofScreen({required this.session, super.key});

  final WorkSession session;

  @override
  State<WorkProfileProofScreen> createState() => _WorkProfileProofScreenState();
}

class _WorkProfileProofScreenState extends State<WorkProfileProofScreen> {
  int _step = 0;
  late final TextEditingController _name = TextEditingController(
    text: widget.session.workName,
  );
  late final TextEditingController _area = TextEditingController(
    text: widget.session.workArea,
  );
  late final TextEditingController _activity = TextEditingController(
    text: widget.session.primaryActivity,
  );

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _activity.dispose();
    super.dispose();
  }

  void _saveFields() {
    widget.session.saveDetails(
      name: _name.text,
      area: _area.text,
      activity: _activity.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => WorkPageScaffold(
        session: widget.session,
        title: 'Verify Your Work',
        subtitle: widget.session.selectedProfile?.label ?? 'Work profile',
        fallbackBackRoute: '/app/work/choose',
        activeDock: 'my-work',
        bottomAction: switch (_step) {
          0 => WorkPrimaryButton(
            keyName: 'work-details-continue',
            label: 'Continue to proof',
            onPressed: () {
              _saveFields();
              if (widget.session.validateDetails()) {
                setState(() => _step = 1);
              }
            },
          ),
          1 => WorkPrimaryButton(
            keyName: 'work-proof-review',
            label: 'Review',
            onPressed: () {
              if (!widget.session.requiredProofsAdded) {
                widget.session.showError(
                  'Add every required proof before review.',
                );
                return;
              }
              setState(() => _step = 2);
            },
          ),
          _ => WorkPrimaryButton(
            keyName: 'work-submit-profile',
            label: 'Submit for review',
            busy: widget.session.busy,
            onPressed: () async {
              final submitted = await widget.session.submitProfile();
              if (submitted && context.mounted) {
                context.go('/app/work/status');
              }
            },
            icon: Icons.send_rounded,
          ),
        },
        body: ListView(
          key: const Key('work-proof-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.sm,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            _ProgressHeader(step: _step),
            const SizedBox(height: MoolSpacing.md),
            if (_step == 0) ...[
              const WorkSectionTitle(
                title: 'Work details',
                detail: 'Only information required for this workspace',
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('work-name'),
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Work or business name',
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('work-area'),
                controller: _area,
                decoration: const InputDecoration(
                  labelText: 'Operating city or PIN code',
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('work-activity'),
                controller: _activity,
                decoration: const InputDecoration(
                  labelText: 'Primary activity',
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkCard(
                color: Color(0xFFEAF7E8),
                child: _ContactRow(
                  label: 'Account owner',
                  value: '+91 98••• ••321',
                  state: 'Verified',
                ),
              ),
            ] else if (_step == 1) ...[
              Row(
                children: [
                  Expanded(
                    child: const WorkSectionTitle(
                      title: 'Proof',
                      detail: 'India / Rajasthan · profile-specific',
                    ),
                  ),
                  TextButton(
                    key: const Key('work-proof-back-details'),
                    onPressed: () => setState(() => _step = 0),
                    child: const Text('Back'),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final proof in workProofs) ...[
                _ProofCard(
                  proof: proof,
                  added: widget.session.addedProofs.containsKey(proof.id),
                  onAdd: () => _showProofSource(context, proof),
                  onRemove: proof.id == 'personal-kyc'
                      ? null
                      : () => widget.session.removeProof(proof.id),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
            ] else ...[
              Row(
                children: [
                  const Expanded(
                    child: WorkSectionTitle(
                      title: 'Review and submit',
                      detail: 'Check profile, contacts and proof',
                    ),
                  ),
                  TextButton(
                    key: const Key('work-review-back-proof'),
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('Back'),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              WorkCard(
                child: Column(
                  children: [
                    _ReviewRow(
                      label: 'Workspace',
                      value:
                          widget.session.selectedProfile?.label ??
                          'Not selected',
                    ),
                    _ReviewRow(label: 'Name', value: widget.session.workName),
                    _ReviewRow(label: 'Area', value: widget.session.workArea),
                    _ReviewRow(
                      label: 'Activity',
                      value: widget.session.primaryActivity,
                    ),
                    _ReviewRow(
                      label: 'Proof',
                      value: '${widget.session.addedProofs.length} items added',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              WorkCard(
                color: const Color(0xFFFFF4E5),
                child: CheckboxListTile(
                  key: const Key('work-declaration'),
                  value: widget.session.declarationAccepted,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I confirm these details and documents belong to me or I am authorized to operate this work profile.',
                    style: TextStyle(
                      color: MoolColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onChanged: (value) =>
                      widget.session.setDeclaration(value ?? false),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showProofSource(
    BuildContext context,
    WorkProofRequirement proof,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.lg,
          0,
          MoolSpacing.lg,
          MoolSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add ${proof.label}',
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Choose the easiest available source.',
              style: TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: MoolSpacing.md),
            for (final source in const [
              ('camera', 'Camera', Icons.camera_alt_outlined),
              ('upload', 'Upload', Icons.upload_file_outlined),
              ('number', 'Verify number', Icons.phone_android_outlined),
            ]) ...[
              OutlinedButton.icon(
                key: Key('work-proof-source-${source.$1}'),
                onPressed: () async {
                  final added = await widget.session.addProof(
                    proof.id,
                    source.$2,
                  );
                  if (added && sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
                icon: Icon(source.$3),
                label: Text(source.$2),
              ),
              const SizedBox(height: MoolSpacing.xs),
            ],
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Details', 'Proof', 'Review'];
    return Row(
      children: [
        for (var index = 0; index < labels.length; index += 1) ...[
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: MoolMotion.accessible(context, MoolMotion.quick),
                  height: 5,
                  decoration: BoxDecoration(
                    color: index <= step
                        ? MoolColors.navy
                        : const Color(0xFFD8DAE8),
                    borderRadius: BorderRadius.circular(MoolRadii.capsule),
                  ),
                ),
                const SizedBox(height: MoolSpacing.xxs),
                Text(
                  labels[index],
                  style: TextStyle(
                    color: index == step ? MoolColors.navy : MoolColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (index < labels.length - 1) const SizedBox(width: MoolSpacing.xs),
        ],
      ],
    );
  }
}

class _ProofCard extends StatelessWidget {
  const _ProofCard({
    required this.proof,
    required this.added,
    required this.onAdd,
    this.onRemove,
  });

  final WorkProofRequirement proof;
  final bool added;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      color: added ? const Color(0xFFEAF7E8) : Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: added
                ? MoolColors.success
                : const Color(0xFFEDEEFF),
            foregroundColor: added ? Colors.white : MoolColors.navy,
            child: Icon(
              added
                  ? Icons.check_rounded
                  : proof.required
                  ? Icons.priority_high_rounded
                  : Icons.add_rounded,
            ),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        proof.label,
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    WorkPill(
                      label: proof.required ? 'Required' : 'Add later',
                      color: proof.required
                          ? MoolColors.navy
                          : MoolColors.orange,
                    ),
                  ],
                ),
                Text(
                  proof.detail,
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          if (added && onRemove != null)
            IconButton(
              key: Key('work-remove-proof-${proof.id}'),
              tooltip: 'Remove ${proof.label}',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
            )
          else if (!added)
            TextButton(
              key: Key('work-add-proof-${proof.id}'),
              onPressed: onAdd,
              child: const Text('Add'),
            ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: MoolColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
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

class WorkVerificationStatusScreen extends StatelessWidget {
  const WorkVerificationStatusScreen({required this.session, super.key});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final approved = session.reviewStage == WorkReviewStage.approved;
        return WorkPageScaffold(
          session: session,
          title: approved ? 'Work approved' : 'Work profile review',
          subtitle: session.reviewCaseId ?? 'Review status',
          fallbackBackRoute: '/app/work/my-work',
          activeDock: 'my-work',
          bottomAction: approved
              ? WorkPrimaryButton(
                  keyName: 'work-open-ready',
                  label: 'Continue to workspace setup',
                  onPressed: () => context.go('/app/work/ready'),
                )
              : WorkPrimaryButton(
                  keyName: 'work-check-review',
                  label: 'Check review update',
                  busy: session.busy,
                  onPressed: () async {
                    final ready = await session.checkReview();
                    if (ready && context.mounted) {
                      context.go('/app/work/ready');
                    }
                  },
                  icon: Icons.refresh_rounded,
                ),
          body: ListView(
            key: const Key('work-status-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              const WorkCard(
                child: _ContactRow(
                  label: 'Account owner',
                  value: '+91 98••• ••321',
                  state: 'KYC received',
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              WorkCard(
                color: approved
                    ? const Color(0xFFEAF7E8)
                    : const Color(0xFFFFF4E5),
                child: Column(
                  children: [
                    Icon(
                      approved
                          ? Icons.verified_rounded
                          : Icons.hourglass_top_rounded,
                      size: 50,
                      color: approved ? MoolColors.success : MoolColors.orange,
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    Text(
                      approved ? 'Review approved' : 'Review in progress',
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      session.selectedProfile?.label ?? 'Work profile',
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      session.reviewCaseId ?? 'Case pending',
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const _StatusSteps(),
              const SizedBox(height: MoolSpacing.md),
              if (!approved)
                WorkCard(
                  color: const Color(0xFFFFF4E5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const WorkPill(
                        label: 'Action available',
                        color: MoolColors.orange,
                        icon: Icons.schedule_rounded,
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      const Text(
                        'Complete business verification',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'GST certificate is pending. Add it when available, or save a reminder while review continues.',
                        style: TextStyle(color: MoolColors.muted, height: 1.4),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('work-remind-gst'),
                              onPressed: session.remindGstLater,
                              child: const Text('Remind later'),
                            ),
                          ),
                          const SizedBox(width: MoolSpacing.xs),
                          Expanded(
                            child: FilledButton(
                              key: const Key('work-add-gst'),
                              onPressed: () => _showGstSheet(context),
                              child: const Text('Add GST'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: MoolSpacing.md),
              WorkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WorkSectionTitle(
                      title: 'Review team',
                      detail: 'Updates and exact corrections appear here',
                      trailing: WorkPill(
                        label: 'Chat enabled',
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    const Text(
                      'If a document is unclear or conditional approval applies, only that exact correction is requested. Your personal account stays active.',
                      style: TextStyle(color: MoolColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('work-status-open-chat'),
                            onPressed: () => context.go(
                              '/app/chat/inbox?return=/app/work/status',
                            ),
                            child: const Text('Open Chat'),
                          ),
                        ),
                        const SizedBox(width: MoolSpacing.xs),
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('work-status-open-my-work'),
                            onPressed: () => context.go('/app/work/my-work'),
                            child: const Text('Open My Work'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showGstSheet(BuildContext context) {
    final gst = TextEditingController(text: session.gstin);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => AnimatedBuilder(
        animation: session,
        builder: (context, _) => Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.lg,
            0,
            MoolSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add GST certificate',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Business review continues without this document, but the reminder remains until resolved.',
                  style: TextStyle(color: MoolColors.muted),
                ),
                const SizedBox(height: MoolSpacing.md),
                TextField(
                  key: const Key('work-gstin'),
                  controller: gst,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'GSTIN'),
                ),
                const SizedBox(height: MoolSpacing.sm),
                OutlinedButton.icon(
                  key: const Key('work-attach-gst'),
                  onPressed: session.attachGst,
                  icon: Icon(
                    session.gstAttachmentAdded
                        ? Icons.check_circle_rounded
                        : Icons.attach_file_rounded,
                  ),
                  label: Text(
                    session.gstAttachmentAdded
                        ? 'Certificate attached'
                        : 'Attach certificate',
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                FilledButton(
                  key: const Key('work-submit-gst'),
                  onPressed: session.busy
                      ? null
                      : () async {
                          final submitted = await session.submitGstProof(
                            gst.text,
                          );
                          if (submitted && sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                  child: const Text('Submit GST'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusSteps extends StatelessWidget {
  const _StatusSteps();

  @override
  Widget build(BuildContext context) {
    return const WorkCard(
      child: Row(
        children: [
          _StatusStep(
            icon: Icons.check_rounded,
            label: 'Submitted',
            done: true,
          ),
          _StatusStep(
            icon: Icons.fact_check_outlined,
            label: 'Checks',
            done: false,
          ),
          _StatusStep(
            icon: Icons.rocket_launch_outlined,
            label: 'Activation',
            done: false,
          ),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.icon,
    required this.label,
    required this.done,
  });

  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: done
                ? MoolColors.success
                : const Color(0xFFEDEEFF),
            foregroundColor: done ? Colors.white : MoolColors.navy,
            child: Icon(icon, size: 18),
          ),
          const SizedBox(height: MoolSpacing.xxs),
          Text(
            label,
            style: TextStyle(
              color: done ? MoolColors.success : MoolColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkspaceReadyScreen extends StatelessWidget {
  const WorkspaceReadyScreen({required this.session, super.key});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final workspace = session.activeWorkspace;
        return WorkPageScaffold(
          session: session,
          title: 'Workspace ready',
          subtitle: 'Approval creates no public listing',
          fallbackBackRoute: '/app/work/status',
          activeDock: 'my-work',
          bottomAction: WorkPrimaryButton(
            keyName: 'work-set-up-shop',
            label: 'Set up my shop',
            onPressed: () {
              session.beginRetailerSetup();
              context.go('/app/work/retailer/setup');
            },
            icon: Icons.storefront_rounded,
          ),
          body: ListView(
            key: const Key('workspace-ready-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              const WorkCard(
                child: _ContactRow(
                  label: 'Workspace owner',
                  value: '+91 98••• ••321',
                  state: 'Verified',
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              WorkCard(
                color: const Color(0xFFEAF7E8),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 58,
                      color: MoolColors.success,
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    const Text(
                      'Review approved',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      workspace?.profileLabel ?? 'Grocery / Kirana Shop',
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      workspace?.id ?? session.workspaceId ?? 'Workspace ready',
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    const WorkPill(
                      label: 'Not public yet',
                      color: MoolColors.orange,
                      icon: Icons.visibility_off_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkCard(
                child: Row(
                  children: [
                    _ReadyStep(
                      icon: Icons.check_rounded,
                      label: 'Approved',
                      done: true,
                    ),
                    _ReadyStep(
                      icon: Icons.tune_rounded,
                      label: 'Set up',
                      done: false,
                    ),
                    _ReadyStep(
                      icon: Icons.public_rounded,
                      label: 'Go live',
                      done: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              WorkCard(
                color: MoolColors.navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WorkPill(
                      label: 'Next action',
                      color: Color(0xFF9EE89B),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    const Text(
                      'Finish shop setup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      '3 steps · stock, price and fulfilment',
                      style: TextStyle(
                        color: Color(0xFFD9DAFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    const Text(
                      'Customers see products only after every readiness step is complete and you approve going live.',
                      style: TextStyle(color: Color(0xFFD9DAFF), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkSectionTitle(
                title: 'Already completed',
                detail: 'Common identity is not collected again',
              ),
              const SizedBox(height: MoolSpacing.sm),
              const WorkCard(
                child: Column(
                  children: [
                    _CompletedRow(label: 'Profile approved'),
                    _CompletedRow(label: 'Account linked'),
                    _CompletedRow(label: 'Exact shop profile selected'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReadyStep extends StatelessWidget {
  const _ReadyStep({
    required this.icon,
    required this.label,
    required this.done,
  });

  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: done
                ? MoolColors.success
                : const Color(0xFFEDEEFF),
            foregroundColor: done ? Colors.white : MoolColors.navy,
            child: Icon(icon),
          ),
          const SizedBox(height: MoolSpacing.xxs),
          Text(
            label,
            style: TextStyle(
              color: done ? MoolColors.success : MoolColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedRow extends StatelessWidget {
  const _CompletedRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: MoolColors.success),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: MoolColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RetailerSetupScreen extends StatefulWidget {
  const RetailerSetupScreen({required this.session, super.key});

  final WorkSession session;

  @override
  State<RetailerSetupScreen> createState() => _RetailerSetupScreenState();
}

class _RetailerSetupScreenState extends State<RetailerSetupScreen> {
  late final TextEditingController _quantity = TextEditingController(
    text: widget.session.retailerQuantity == 0
        ? ''
        : '${widget.session.retailerQuantity}',
  );
  late final TextEditingController _buy = TextEditingController(
    text: widget.session.retailerBuyPrice == 0
        ? ''
        : '${widget.session.retailerBuyPrice}',
  );
  late final TextEditingController _sell = TextEditingController(
    text: widget.session.retailerSellPrice == 0
        ? ''
        : '${widget.session.retailerSellPrice}',
  );

  @override
  void dispose() {
    _quantity.dispose();
    _buy.dispose();
    _sell.dispose();
    super.dispose();
  }

  void _saveFields() {
    widget.session.saveRetailerProduct(
      quantity: int.tryParse(_quantity.text) ?? 0,
      buyPrice: int.tryParse(_buy.text) ?? 0,
      sellPrice: int.tryParse(_sell.text) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final complete =
            widget.session.reviewStage == WorkReviewStage.live &&
            widget.session.retailerSetupSaved;
        return WorkPageScaffold(
          session: widget.session,
          title: complete ? 'Shop ready' : 'Set up your shop',
          subtitle: complete
              ? 'Available products are now visible'
              : 'Stock, price and fulfilment',
          fallbackBackRoute: complete ? '/app/work/my-work' : '/app/work/ready',
          activeDock: 'my-work',
          bottomAction: WorkPrimaryButton(
            keyName: complete
                ? 'retailer-setup-open-my-work'
                : 'retailer-finish-setup',
            label: complete
                ? 'Open shop operations'
                : 'Finish setup and go live',
            busy: widget.session.busy,
            onPressed: () async {
              if (complete) {
                context.go('/app/retailer/home');
                return;
              }
              _saveFields();
              await widget.session.finishRetailerSetup();
            },
            icon: complete
                ? Icons.work_outline_rounded
                : Icons.rocket_launch_rounded,
          ),
          body: ListView(
            key: const Key('retailer-setup-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              WorkCard(
                color: complete ? const Color(0xFFEAF7E8) : MoolColors.navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete ? 'Mahadev Fresh Mart is ready' : '3 steps',
                      style: TextStyle(
                        color: complete ? MoolColors.ink : Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      complete
                          ? 'Customers see only available stock with the fulfilment you approved.'
                          : 'Products remain private until all three checks pass and you approve going live.',
                      style: TextStyle(
                        color: complete
                            ? MoolColors.muted
                            : const Color(0xFFD9DAFF),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkSectionTitle(
                title: '1. Add a product',
                detail: 'Use the verified master catalogue',
              ),
              const SizedBox(height: MoolSpacing.sm),
              if (!widget.session.retailerProductAdded)
                WorkCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: MoolColors.navy,
                        size: 42,
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      const Text(
                        'Aashirvaad Whole Wheat Atta',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        '1 kg consumer pack · brand verified · barcode ready',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: MoolColors.muted),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      FilledButton.icon(
                        key: const Key('retailer-add-catalog-product'),
                        onPressed: widget.session.addRetailerProduct,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add to my shop'),
                      ),
                    ],
                  ),
                )
              else
                const WorkCard(
                  color: Color(0xFFEAF7E8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: MoolColors.success,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.check_rounded),
                      ),
                      SizedBox(width: MoolSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aashirvaad Whole Wheat Atta',
                              style: TextStyle(
                                color: MoolColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '1 kg consumer pack · catalogue matched',
                              style: TextStyle(color: MoolColors.muted),
                            ),
                          ],
                        ),
                      ),
                      WorkPill(label: 'Added'),
                    ],
                  ),
                ),
              const SizedBox(height: MoolSpacing.md),
              const WorkSectionTitle(
                title: '2. Set stock and price',
                detail: 'Consumer quantity only · wholesale stays separate',
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('retailer-product-quantity'),
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Available consumer quantity',
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('retailer-product-buy-price'),
                      controller: _buy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Purchase ₹',
                      ),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: TextField(
                      key: const Key('retailer-product-sell-price'),
                      controller: _sell,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Sell ₹'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkSectionTitle(
                title: '3. Choose fulfilment',
                detail: 'Home delivery and store collection are distinct',
              ),
              const SizedBox(height: MoolSpacing.sm),
              WorkCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      key: const Key('retailer-home-delivery'),
                      contentPadding: EdgeInsets.zero,
                      value: widget.session.retailerHomeDelivery,
                      title: const Text(
                        'Home delivery',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: const Text(
                        'Customer orders from home and receives delivery',
                      ),
                      onChanged: (value) =>
                          widget.session.setRetailerFulfilment(
                            homeDelivery: value,
                            storeCollection:
                                widget.session.retailerStoreCollection,
                          ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      key: const Key('retailer-store-collection'),
                      contentPadding: EdgeInsets.zero,
                      value: widget.session.retailerStoreCollection,
                      title: const Text(
                        'Store collection',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: const Text(
                        'Customer explicitly chooses this shop and collects',
                      ),
                      onChanged: (value) =>
                          widget.session.setRetailerFulfilment(
                            homeDelivery: widget.session.retailerHomeDelivery,
                            storeCollection: value,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              WorkCard(
                color: const Color(0xFFFFF4E5),
                child: Row(
                  children: [
                    Icon(
                      complete
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_outlined,
                      color: complete ? MoolColors.success : MoolColors.orange,
                    ),
                    const SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Text(
                        complete
                            ? 'This product is visible with current stock and fulfilment.'
                            : 'Nothing is public until setup passes and you choose Finish setup and go live.',
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
