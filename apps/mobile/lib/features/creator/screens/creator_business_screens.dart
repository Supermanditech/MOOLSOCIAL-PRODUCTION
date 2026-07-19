import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../creator_models.dart';
import '../creator_session.dart';
import '../widgets/creator_widgets.dart';

class CreatorCampaignsScreen extends StatelessWidget {
  const CreatorCampaignsScreen({required this.session, super.key});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CreatorPageScaffold(
        session: session,
        title: 'Funded Campaigns',
        subtitle: 'Business-funded work matched to your audience',
        activeDock: 'studio',
        returnRoute: '/app/creator',
        trailing: IconButton.outlined(
          key: const Key('creator-campaign-filter'),
          tooltip: 'Campaign filters',
          onPressed: () => _filterSheet(context),
          icon: const Icon(Icons.tune_rounded),
        ),
        body: ListView(
          key: const Key('creator-campaigns-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const CreatorCard(
              color: MoolColors.navy,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AVAILABLE FUNDED WORK',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '18 campaigns',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '3 active · potential depends on approved outcomes',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  CreatorPill(
                    label: '₹42K POTENTIAL',
                    color: MoolColors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CreatorCampaignTab.values
                    .map(
                      (tab) => Padding(
                        padding: const EdgeInsets.only(right: MoolSpacing.xs),
                        child: MoolSegment(
                          key: Key('creator-campaign-tab-${tab.name}'),
                          label: switch (tab) {
                            CreatorCampaignTab.bestFit => 'Best Fit',
                            CreatorCampaignTab.awareness => 'Awareness',
                            CreatorCampaignTab.conversion => 'Conversion',
                            CreatorCampaignTab.saved => 'Saved',
                            CreatorCampaignTab.active => 'Active',
                          },
                          selected: session.campaignTab == tab,
                          onPressed: () => session.setCampaignTab(tab),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            ..._visibleCampaigns(session.campaignTab).map(
              (campaign) => Padding(
                padding: const EdgeInsets.only(bottom: MoolSpacing.sm),
                child: _CampaignCard(
                  campaign: campaign,
                  onOpen: () {
                    session.selectCampaign(campaign.id);
                    _campaignSheet(context);
                  },
                ),
              ),
            ),
            const CreatorCard(
              color: Color(0xFFFFF6E8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFB05C00)),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Text(
                      'Campaigns are funded work, not brand listings. Fit, geography, deliverable, payout, outcome rule, rights and disclosure appear before acceptance.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CreatorCampaign> _visibleCampaigns(CreatorCampaignTab tab) {
    if (tab == CreatorCampaignTab.active) {
      return reviewCreatorCampaigns.where((item) => item.active).toList();
    }
    if (tab == CreatorCampaignTab.saved) {
      return [reviewCreatorCampaigns[1]];
    }
    if (tab == CreatorCampaignTab.awareness) {
      return reviewCreatorCampaigns
          .where((item) => item.outcomePay.contains('Education'))
          .toList();
    }
    if (tab == CreatorCampaignTab.conversion) {
      return reviewCreatorCampaigns
          .where((item) => item.outcomePay.contains('order'))
          .toList();
    }
    return reviewCreatorCampaigns;
  }

  Future<void> _filterSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('creator-campaign-filter-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Campaign filters',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const CreatorCard(
              color: Color(0xFFF4F3FF),
              child: Column(
                children: [
                  CreatorFact(label: 'Geography', value: 'Jodhpur'),
                  CreatorFact(label: 'Formats', value: 'Funded Reel + YouTube'),
                  CreatorFact(label: 'Funding', value: 'Reserved only'),
                  CreatorFact(label: 'Minimum fit', value: '80%'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('creator-campaign-filter-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Show Matches'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _campaignSheet(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final campaign = session.selectedCampaign;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: SingleChildScrollView(
              child: Column(
                key: const Key('creator-campaign-sheet'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.active ? 'Campaign deliverable' : 'Campaign terms',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(campaign.title),
                  const SizedBox(height: MoolSpacing.md),
                  CreatorCard(
                    color: const Color(0xFFF4F3FF),
                    child: Column(
                      children: [
                        CreatorFact(label: 'Business', value: campaign.sponsor),
                        CreatorFact(
                          label: 'Creator pay',
                          value: '₹${campaign.fixedPay} fixed',
                        ),
                        CreatorFact(
                          label: 'Outcome pay',
                          value: campaign.outcomePay,
                        ),
                        CreatorFact(label: 'Format', value: campaign.format),
                        CreatorFact(
                          label: 'Geography',
                          value: campaign.geography,
                        ),
                        CreatorFact(
                          label: 'Disclosure',
                          value: campaign.disclosure,
                        ),
                        CreatorFact(
                          label: 'Attribution',
                          value: campaign.attribution,
                        ),
                        CreatorFact(
                          label: 'Deadline',
                          value: campaign.deadline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  const Text(
                    'Acceptance does not approve medical, financial, regulated or misleading claims. Content must remain truthful and carry the required disclosure.',
                    style: TextStyle(color: MoolColors.muted, fontSize: 11),
                  ),
                  if (!campaign.active)
                    CheckboxListTile(
                      key: const Key('creator-campaign-terms'),
                      contentPadding: EdgeInsets.zero,
                      value: session.campaignTermsAccepted,
                      onChanged: (value) =>
                          session.acceptCampaignTerms(value ?? false),
                      title: const Text(
                        'I reviewed the funded brief, rights, disclosure, attribution and cancellation',
                      ),
                    ),
                  if (session.errorMessage != null)
                    Text(
                      session.errorMessage!,
                      key: const Key('creator-campaign-error'),
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: MoolSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('creator-campaign-primary'),
                      onPressed: session.busy
                          ? null
                          : () async {
                              if (campaign.active) {
                                Navigator.pop(sheetContext);
                                context.go(
                                  '/app/creator/publish?campaign=${campaign.id}',
                                );
                                return;
                              }
                              final accepted = await session.acceptCampaign();
                              if (accepted &&
                                  context.mounted &&
                                  session.campaignAcceptanceId != null) {
                                // Keep the reviewed terms visible so the
                                // creator decides when to open production.
                              }
                            },
                      child: Text(
                        campaign.active
                            ? 'Open Deliverable'
                            : session.campaignAcceptanceId == null
                            ? 'Accept Funded Campaign'
                            : 'Campaign Accepted',
                      ),
                    ),
                  ),
                  if (session.campaignAcceptanceId != null && !campaign.active)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const Key('creator-campaign-create'),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          context.go(
                            '/app/creator/publish?campaign=${campaign.id}',
                          );
                        },
                        child: const Text('Create Deliverable'),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      key: const Key('creator-campaign-close'),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Close'),
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

class CreatorEarningsScreen extends StatelessWidget {
  const CreatorEarningsScreen({required this.session, super.key});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CreatorPageScaffold(
        session: session,
        title: 'Creator Earnings',
        subtitle: 'Campaign, attribution and payout records',
        activeDock: 'earnings',
        returnRoute: '/app/creator',
        trailing: IconButton.outlined(
          key: const Key('creator-earnings-download'),
          tooltip: 'Prepare statement',
          onPressed: () => _statementSheet(context),
          icon: const Icon(Icons.download_rounded),
        ),
        body: ListView(
          key: const Key('creator-earnings-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const CreatorCard(
              color: MoolColors.navy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVAILABLE FOR PAYOUT',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '₹6,240',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Verified bank ••4421 · automatic payout tomorrow',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CreatorEarningsTab.values
                    .map(
                      (tab) => Padding(
                        padding: const EdgeInsets.only(right: MoolSpacing.xs),
                        child: MoolSegment(
                          key: Key('creator-earnings-tab-${tab.name}'),
                          label: switch (tab) {
                            CreatorEarningsTab.overview => 'This Month',
                            CreatorEarningsTab.ledger => 'Ledger',
                            CreatorEarningsTab.payouts => 'Payouts',
                          },
                          selected: session.earningsTab == tab,
                          onPressed: () => session.setEarningsTab(tab),
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
                  child: CreatorMetric(
                    label: 'FIXED',
                    value: '₹7,500',
                    detail: 'campaigns',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CreatorMetric(
                    label: 'OUTCOMES',
                    value: '₹3,840',
                    detail: 'verified',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CreatorMetric(
                    label: 'AWARENESS',
                    value: '₹1,500',
                    detail: 'funded',
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Row(
              children: [
                Expanded(
                  child: CreatorMetric(
                    label: 'EARNED',
                    value: '₹12,620',
                    detail: 'this month',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CreatorMetric(
                    label: 'PAID',
                    value: '₹6,380',
                    detail: 'to bank',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CreatorMetric(
                    label: 'AVAILABLE',
                    value: '₹6,240',
                    detail: 'ready',
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.md),
            const CreatorSectionTitle(
              title: 'Recent money activity',
              detail: 'Source and rule visible',
            ),
            const SizedBox(height: MoolSpacing.sm),
            ...reviewCreatorLedger.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
                child: CreatorActionRow(
                  keyName: 'creator-ledger-${item.id}',
                  icon: item.amount.startsWith('+')
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  title: item.title,
                  detail: item.detail,
                  meta: '${item.amount} · ${item.status}',
                  action: 'Inspect',
                  onTap: () {
                    session.selectLedger(item.id);
                    _ledgerSheet(context, item);
                  },
                ),
              ),
            ),
            const CreatorCard(
              color: Color(0xFFFFF6E8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFB05C00)),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Text(
                      'Views alone do not create payout. Every payable amount shows its business funding or verified attribution rule.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _statementSheet(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('creator-statement-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Creator statement',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text('Campaign, outcome, deduction and payout records.'),
                const SizedBox(height: MoolSpacing.md),
                const CreatorCard(
                  color: Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      CreatorFact(label: 'Period', value: 'July 2026'),
                      CreatorFact(label: 'Earned', value: '₹12,620'),
                      CreatorFact(label: 'Paid', value: '₹6,380'),
                      CreatorFact(label: 'Available', value: '₹6,240'),
                      CreatorFact(label: 'Bank', value: '••4421'),
                      CreatorFact(label: 'Formats', value: 'PDF and CSV'),
                    ],
                  ),
                ),
                if (session.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: MoolSpacing.sm),
                    child: Text(
                      session.errorMessage!,
                      key: const Key('creator-statement-error'),
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('creator-statement-prepare'),
                    onPressed: session.busy ? null : session.prepareStatement,
                    child: Text(
                      session.statementId == null
                          ? 'Prepare Statement'
                          : 'Statement Ready',
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('creator-statement-close'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _ledgerSheet(BuildContext context, CreatorLedgerItem item) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: Column(
              key: const Key('creator-ledger-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(item.detail),
                const SizedBox(height: MoolSpacing.md),
                CreatorCard(
                  color: const Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      CreatorFact(label: 'Amount', value: item.amount),
                      CreatorFact(label: 'Status', value: item.status),
                      const CreatorFact(
                        label: 'Why this amount',
                        value: 'Campaign or verified sale',
                      ),
                      const CreatorFact(
                        label: 'Returns',
                        value: 'Accounted before payout',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('creator-ledger-close'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class CreatorControlScreen extends StatelessWidget {
  const CreatorControlScreen({required this.session, super.key});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CreatorPageScaffold(
        session: session,
        title: 'Channel & Safety',
        subtitle: 'Verification, rights, team and appeals',
        activeDock: 'studio',
        returnRoute: '/app/creator',
        trailing: IconButton.outlined(
          key: const Key('creator-control-help'),
          tooltip: 'Creator control help',
          onPressed: () => _controlSheet(context, CreatorControlArea.safety),
          icon: const Icon(Icons.help_outline_rounded),
        ),
        body: ListView(
          key: const Key('creator-control-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const CreatorCard(
              color: Color(0xFFF4F3FF),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: MoolColors.navy,
                    foregroundColor: Colors.white,
                    child: Text(
                      'JD',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@JodhpurDaily',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text('Multi-format creator · India'),
                        Text(
                          'Earning readiness 92%',
                          style: TextStyle(
                            color: MoolColors.success,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CreatorPill(label: 'VERIFIED'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            CreatorCard(
              keyName: 'creator-rights-alert',
              color: const Color(0xFFFFF6E8),
              onTap: () => _controlSheet(context, CreatorControlArea.rights),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFB05C00)),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'One audio-rights review',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Content remains published. Earnings are held only for that item.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Review',
                    style: TextStyle(
                      color: MoolColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            ...CreatorControlArea.values.map(
              (area) => Padding(
                padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
                child: CreatorActionRow(
                  keyName: 'creator-control-${area.name}',
                  icon: _controlIcon(area),
                  title: _controlTitle(area),
                  detail: _controlDetail(area),
                  meta: _controlStatus(area),
                  action: area == CreatorControlArea.rights
                      ? 'Review'
                      : 'Manage',
                  onTap: () => _controlSheet(context, area),
                ),
              ),
            ),
            const CreatorCard(
              color: Color(0xFFEAF7E8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: MoolColors.success),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Text(
                      'Important earning, moderation and campaign decisions show a reason, evidence, applicable rule and review path.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _controlSheet(BuildContext context, CreatorControlArea area) {
    session.selectControl(area);
    if (area == CreatorControlArea.rights) return _appealSheet(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: Column(
            key: const Key('creator-control-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _controlTitle(area),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(_controlDetail(area)),
              const SizedBox(height: MoolSpacing.md),
              CreatorCard(
                color: const Color(0xFFF4F3FF),
                child: Column(
                  children: [
                    CreatorFact(label: 'Status', value: _controlStatus(area)),
                    const CreatorFact(
                      label: 'Last change',
                      value: 'Visible in activity history',
                    ),
                    const CreatorFact(
                      label: 'Important changes',
                      value: 'Require confirmation',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('creator-control-sheet-close'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _appealSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
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
              key: const Key('creator-rights-appeal-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Audio rights review',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text(
                  'CR-2041 · earnings held for one Short · evidence due in 6 days',
                ),
                const SizedBox(height: MoolSpacing.md),
                const CreatorCard(
                  color: Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      CreatorFact(label: 'Content', value: 'Remains published'),
                      CreatorFact(
                        label: 'Affected earning',
                        value: 'Held for this item only',
                      ),
                      CreatorFact(
                        label: 'Review reason',
                        value: 'Audio ownership evidence',
                      ),
                      CreatorFact(label: 'Review time', value: 'Within 7 days'),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                TextFormField(
                  key: const Key('creator-appeal-note'),
                  initialValue: session.appealNote,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Explain your rights evidence',
                  ),
                  onChanged: session.setAppealNote,
                ),
                CheckboxListTile(
                  key: const Key('creator-appeal-evidence'),
                  contentPadding: EdgeInsets.zero,
                  value: session.appealEvidenceConfirmed,
                  onChanged: (value) =>
                      session.confirmAppealEvidence(value ?? false),
                  title: const Text(
                    'I can provide the original or licensed audio evidence',
                  ),
                ),
                if (session.errorMessage != null)
                  Text(
                    session.errorMessage!,
                    key: const Key('creator-appeal-error'),
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: MoolSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('creator-appeal-submit'),
                    onPressed: session.busy ? null : session.submitAppeal,
                    child: Text(
                      session.appealId == null
                          ? 'Submit Appeal'
                          : 'Appeal Submitted',
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('creator-appeal-close'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  static IconData _controlIcon(CreatorControlArea area) => switch (area) {
    CreatorControlArea.identity => Icons.verified_user_outlined,
    CreatorControlArea.profile => Icons.person_outline_rounded,
    CreatorControlArea.rights => Icons.copyright_rounded,
    CreatorControlArea.disclosure => Icons.campaign_outlined,
    CreatorControlArea.team => Icons.group_outlined,
    CreatorControlArea.safety => Icons.policy_outlined,
    CreatorControlArea.security => Icons.security_outlined,
  };

  static String _controlTitle(CreatorControlArea area) => switch (area) {
    CreatorControlArea.identity => 'Identity & Payout',
    CreatorControlArea.profile => 'Channel Settings',
    CreatorControlArea.rights => 'Content Rights',
    CreatorControlArea.disclosure => 'Paid Disclosure',
    CreatorControlArea.team => 'Team & Access',
    CreatorControlArea.safety => 'Safety & Moderation',
    CreatorControlArea.security => 'Account Security',
  };

  static String _controlDetail(CreatorControlArea area) => switch (area) {
    CreatorControlArea.identity => 'KYC, bank, tax and account holder',
    CreatorControlArea.profile =>
      'Name, category, language, links and visibility',
    CreatorControlArea.rights =>
      'Audio, video, image, people and brand permissions',
    CreatorControlArea.disclosure =>
      'Partnership labels and regulated-category rules',
    CreatorControlArea.team => 'Editor, analyst and campaign roles',
    CreatorControlArea.safety => 'Limits, removals and appeal history',
    CreatorControlArea.security => 'MFA, devices and recent access',
  };

  static String _controlStatus(CreatorControlArea area) => switch (area) {
    CreatorControlArea.identity => 'Verified',
    CreatorControlArea.profile => 'Public',
    CreatorControlArea.rights => '1 review',
    CreatorControlArea.disclosure => 'Ready',
    CreatorControlArea.team => '2 members',
    CreatorControlArea.safety => 'No severe restriction',
    CreatorControlArea.security => 'MFA on',
  };
}

class CreatorMembershipsScreen extends StatelessWidget {
  const CreatorMembershipsScreen({required this.session, super.key});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CreatorPageScaffold(
        session: session,
        title: 'Memberships',
        subtitle: 'Member promise, price and take-home',
        activeDock: 'studio',
        returnRoute: '/app/creator/audience',
        trailing: IconButton.outlined(
          key: const Key('creator-membership-settings'),
          tooltip: 'Membership eligibility',
          onPressed: () => _eligibilitySheet(context),
          icon: const Icon(Icons.settings_outlined),
        ),
        body: ListView(
          key: const Key('creator-memberships-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const CreatorCard(
              color: MoolColors.navy,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE MEMBERS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '286 members',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Monthly and yearly plans · member controlled',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  CreatorPill(label: 'ELIGIBLE', color: MoolColors.orange),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            ...reviewCreatorMembershipPlans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: MoolSpacing.sm),
                child: CreatorCard(
                  keyName: 'creator-membership-${plan.id}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${plan.members} members',
                                  style: const TextStyle(
                                    color: MoolColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${plan.monthlyPrice}/mo',
                            style: const TextStyle(
                              color: MoolColors.success,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      Text(plan.promise),
                      const SizedBox(height: MoolSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _PlanFact(
                              label: 'YEARLY',
                              value: '₹${plan.yearlyPrice}',
                            ),
                          ),
                          Expanded(
                            child: _PlanFact(
                              label: 'CREATOR NET*',
                              value: '₹${plan.monthlyNet}/mo',
                            ),
                          ),
                          const Expanded(
                            child: _PlanFact(label: 'PAYOUT', value: 'Monthly'),
                          ),
                        ],
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: Key('creator-membership-manage-${plan.id}'),
                          onPressed: () {
                            session.selectMembership(plan.id);
                            _planSheet(context);
                          },
                          child: const Text('Review Plan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const CreatorSectionTitle(
              title: 'Eligibility',
              detail: 'Current launch rules',
            ),
            const SizedBox(height: MoolSpacing.sm),
            const CreatorCard(
              child: Column(
                children: [
                  _EligibilityRow(
                    title: 'Identity and payout',
                    detail: 'Age, KYC and bank verified',
                  ),
                  _EligibilityRow(
                    title: 'Original content',
                    detail: '24 eligible public items',
                  ),
                  _EligibilityRow(
                    title: 'Audience trust',
                    detail: 'Returning audience verified',
                  ),
                  _EligibilityRow(
                    title: 'Safety and rights',
                    detail: 'No severe active restriction',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const CreatorCard(
              color: Color(0xFFFFF6E8),
              child: Text(
                '* Final take-home appears before activation. Applicable tax, refunds and payment-method costs can change the estimated amount. Members control renewal and cancellation.',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eligibilitySheet(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('creator-membership-eligibility-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Membership eligibility',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const Text(
              'Identity, content, audience trust and safety must remain eligible.',
            ),
            const SizedBox(height: MoolSpacing.md),
            const CreatorCard(
              color: Color(0xFFEAF7E8),
              child: Column(
                children: [
                  CreatorFact(label: 'Identity', value: 'Ready'),
                  CreatorFact(label: 'Original content', value: 'Ready'),
                  CreatorFact(label: 'Audience trust', value: 'Ready'),
                  CreatorFact(label: 'Safety and rights', value: 'Ready'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('creator-membership-eligibility-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _planSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final plan = session.selectedMembership;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: SingleChildScrollView(
              child: Column(
                key: const Key('creator-membership-plan-sheet'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review ${plan.name}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text('Member promise and take-home before activation.'),
                  const SizedBox(height: MoolSpacing.md),
                  CreatorCard(
                    color: const Color(0xFFF4F3FF),
                    child: Column(
                      children: [
                        CreatorFact(
                          label: 'Monthly',
                          value: '₹${plan.monthlyPrice}',
                        ),
                        CreatorFact(
                          label: 'Yearly',
                          value: '₹${plan.yearlyPrice}',
                        ),
                        CreatorFact(
                          label: 'Estimated take-home',
                          value: '₹${plan.monthlyNet}/month',
                        ),
                        const CreatorFact(label: 'Payout', value: 'Monthly'),
                        const CreatorFact(
                          label: 'Renewal',
                          value: 'Visible to member',
                        ),
                        const CreatorFact(
                          label: 'Cancellation',
                          value: 'Member controlled',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  Text(
                    plan.promise,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  CheckboxListTile(
                    key: const Key('creator-membership-benefits'),
                    contentPadding: EdgeInsets.zero,
                    value: session.membershipBenefitsConfirmed,
                    onChanged: (value) =>
                        session.confirmMembershipBenefits(value ?? false),
                    title: const Text(
                      'I can deliver the member promise and benefits',
                    ),
                  ),
                  CheckboxListTile(
                    key: const Key('creator-membership-billing'),
                    contentPadding: EdgeInsets.zero,
                    value: session.membershipBillingConfirmed,
                    onChanged: (value) =>
                        session.confirmMembershipBilling(value ?? false),
                    title: const Text(
                      'I reviewed price, take-home, renewal, refund and cancellation',
                    ),
                  ),
                  if (session.errorMessage != null)
                    Text(
                      session.errorMessage!,
                      key: const Key('creator-membership-error'),
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: MoolSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('creator-membership-save'),
                      onPressed: session.busy
                          ? null
                          : session.saveMembershipPlan,
                      child: Text(
                        session.membershipPlanId == null
                            ? 'Save Plan for Activation'
                            : 'Plan Saved',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      key: const Key('creator-membership-close'),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Close'),
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

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign, required this.onOpen});

  final CreatorCampaign campaign;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => CreatorCard(
    keyName: 'creator-campaign-${campaign.id}',
    onTap: onOpen,
    color: campaign.active ? const Color(0xFFEAF7E8) : Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.active
                        ? 'ACTIVE · FUNDED'
                        : '${campaign.fit}% AUDIENCE FIT · FUNDED',
                    style: const TextStyle(
                      color: MoolColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    campaign.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    campaign.sponsor,
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            CreatorPill(
              label: campaign.active
                  ? 'ACTIVE'
                  : campaign.deadline.toUpperCase(),
              color: campaign.active
                  ? MoolColors.success
                  : const Color(0xFFB05C00),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _CampaignFact(label: 'FORMAT', value: campaign.format),
            ),
            Expanded(
              child: _CampaignFact(
                label: 'FIXED PAY',
                value: '₹${campaign.fixedPay}',
              ),
            ),
            Expanded(
              child: _CampaignFact(
                label: 'OUTCOME',
                value: campaign.outcomePay,
              ),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: Key('creator-campaign-review-${campaign.id}'),
            onPressed: onOpen,
            child: Text(campaign.active ? 'Open Deliverable' : 'Review Terms'),
          ),
        ),
      ],
    ),
  );
}

class _CampaignFact extends StatelessWidget {
  const _CampaignFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: MoolSpacing.xs),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: MoolColors.orange, width: 2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: MoolColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _PlanFact extends StatelessWidget {
  const _PlanFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: MoolSpacing.xs),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: MoolColors.orange, width: 2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: MoolColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _EligibilityRow extends StatelessWidget {
  const _EligibilityRow({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 14,
          backgroundColor: MoolColors.success,
          foregroundColor: Colors.white,
          child: Icon(Icons.check_rounded, size: 16),
        ),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(
                detail,
                style: const TextStyle(color: MoolColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        const CreatorPill(label: 'READY'),
      ],
    ),
  );
}
