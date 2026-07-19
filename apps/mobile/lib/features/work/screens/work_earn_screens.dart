import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../widgets/work_widgets.dart';
import '../work_models.dart';
import '../work_session.dart';

class WorkEarnScreen extends StatefulWidget {
  const WorkEarnScreen({required this.session, super.key});

  final WorkSession session;

  @override
  State<WorkEarnScreen> createState() => _WorkEarnScreenState();
}

class _WorkEarnScreenState extends State<WorkEarnScreen> {
  late final TextEditingController _search = TextEditingController(
    text: widget.session.searchQuery,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openOpportunity(BuildContext context, WorkOpportunity opportunity) {
    widget.session.openOpportunity(opportunity.id);
    context.go('/app/work/opportunity/${opportunity.id}');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final opportunities = widget.session.filteredOpportunities;
        return WorkPageScaffold(
          session: widget.session,
          title: 'Work',
          subtitle: 'Earn from verified, funded outcomes',
          showBack: false,
          activeDock: 'earn',
          trailing: IconButton.outlined(
            key: const Key('work-refresh-feed'),
            tooltip: 'Refresh work',
            onPressed: widget.session.busy ? null : widget.session.refreshFeed,
            icon: const Icon(Icons.refresh_rounded),
          ),
          body: RefreshIndicator(
            onRefresh: widget.session.refreshFeed,
            child: ListView(
              key: const Key('work-earn-screen'),
              padding: const EdgeInsets.fromLTRB(
                MoolSpacing.md,
                MoolSpacing.sm,
                MoolSpacing.md,
                MoolSpacing.xl,
              ),
              children: [
                WorkCard(
                  color: MoolColors.navy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Earn from verified work',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          WorkPill(
                            label: 'Updated live',
                            color: Color(0xFF9EE89B),
                            icon: Icons.verified_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      const Text(
                        'Payment, requirement, location and deadline are shown before Apply.',
                        style: TextStyle(
                          color: Color(0xFFD9DAFF),
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly earning potential',
                                  style: TextStyle(
                                    color: Color(0xFFD9DAFF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '₹35,000–₹80,000',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: const Key('work-earning-info'),
                            tooltip: 'How this range is calculated',
                            onPressed: () => _showEarningInfo(context),
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0x55FFFFFF)),
                            ),
                            icon: const Icon(Icons.info_outline_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      const Text(
                        '10,248 funded actions matched',
                        style: TextStyle(
                          color: Color(0xFF9EE89B),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                TextField(
                  key: const Key('work-search'),
                  controller: _search,
                  onChanged: widget.session.search,
                  decoration: InputDecoration(
                    hintText: 'Search jobs, freelance work or campaigns',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('work-clear-search'),
                            tooltip: 'Clear search',
                            onPressed: () {
                              _search.clear();
                              widget.session.search('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    key: const Key('work-filter-list'),
                    scrollDirection: Axis.horizontal,
                    itemCount: WorkFeedFilter.values.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: MoolSpacing.xs),
                    itemBuilder: (context, index) {
                      final value = WorkFeedFilter.values[index];
                      return MoolSegment(
                        key: Key('work-filter-${value.name}'),
                        label: value.label,
                        selected: widget.session.filter == value,
                        onPressed: () => widget.session.setFilter(value),
                      );
                    },
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                WorkSectionTitle(
                  title: 'Paid work for you',
                  detail: opportunities.isEmpty
                      ? 'No live opportunity matches this view'
                      : '${opportunities.length} live · approval and eligibility apply',
                ),
                const SizedBox(height: MoolSpacing.sm),
                if (opportunities.isEmpty)
                  WorkEmptyState(
                    title: 'No live opportunities in this view',
                    detail:
                        'Choose For You or clear the search. You can also start a verified work profile.',
                    actionLabel: 'Show all work',
                    onAction: () {
                      _search.clear();
                      widget.session.search('');
                      widget.session.setFilter(WorkFeedFilter.forYou);
                    },
                  )
                else
                  for (final opportunity in opportunities) ...[
                    _OpportunityCard(
                      opportunity: opportunity,
                      expanded:
                          widget.session.expandedOpportunityId ==
                          opportunity.id,
                      onToggle: () =>
                          widget.session.toggleOpportunity(opportunity.id),
                      onReview: () => _openOpportunity(context, opportunity),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                  ],
                WorkCard(
                  color: const Color(0xFFEDEEFF),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const WorkSectionTitle(
                        title: 'Start My Work',
                        detail:
                            'Add one verified activity without changing your personal account.',
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      WorkPrimaryButton(
                        keyName: 'work-start-my-work',
                        label: 'Start My Work',
                        onPressed: () {
                          widget.session.startMyWork();
                          context.go('/app/work/my-work');
                        },
                        icon: Icons.add_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEarningInfo(BuildContext context) {
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
            const Text(
              'How this range is calculated',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'Current funded opportunities × realistic monthly capacity. Approval, availability and eligibility apply. This is not guaranteed income.',
              style: TextStyle(color: MoolColors.muted, height: 1.45),
            ),
            const SizedBox(height: MoolSpacing.md),
            const _InfoRow(label: 'Eligible funded work', value: '₹2,40,000'),
            const _InfoRow(label: 'Reserved payout', value: '₹0'),
            const SizedBox(height: MoolSpacing.md),
            FilledButton(
              key: const Key('work-close-earning-info'),
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.opportunity,
    required this.expanded,
    required this.onToggle,
    required this.onReview,
  });

  final WorkOpportunity opportunity;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: Key('work-opportunity-${opportunity.id}'),
            onTap: onToggle,
            borderRadius: BorderRadius.circular(MoolRadii.control),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: MoolColors.navy,
                      borderRadius: BorderRadius.circular(MoolRadii.control),
                    ),
                    child: Icon(opportunity.icon, color: Colors.white),
                  ),
                  const SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${opportunity.kind.toUpperCase()} · VERIFIED',
                          style: const TextStyle(
                            color: MoolColors.success,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          opportunity.title,
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${opportunity.publisher} · ${opportunity.location} · ${opportunity.capacity}',
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        opportunity.payment.split(' per ').first,
                        style: const TextStyle(
                          color: MoolColors.success,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: MoolColors.navy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: MoolSpacing.lg),
            Text(
              opportunity.summary,
              style: const TextStyle(color: MoolColors.muted, height: 1.4),
            ),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: [
                WorkPill(label: opportunity.requiredWork),
                WorkPill(label: opportunity.payout, color: MoolColors.orange),
                WorkPill(label: opportunity.deadline, color: MoolColors.royal),
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            Text(
              opportunity.fundingNote,
              style: const TextStyle(
                color: MoolColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: Key('work-review-${opportunity.id}'),
                onPressed: onReview,
                child: const Text('Review & Apply'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WorkOpportunityScreen extends StatelessWidget {
  const WorkOpportunityScreen({
    required this.session,
    required this.opportunityId,
    super.key,
  });

  final WorkSession session;
  final String opportunityId;

  @override
  Widget build(BuildContext context) {
    if (session.selectedOpportunity?.id != opportunityId) {
      session.openOpportunity(opportunityId);
    }
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final opportunity = session.selectedOpportunity!;
        final applied = session.applicationId != null;
        return WorkPageScaffold(
          session: session,
          title: applied ? 'Application sent' : 'Opportunity',
          subtitle: applied
              ? 'Terms and payout remain saved'
              : 'Review outcome and terms',
          fallbackBackRoute: '/app/work/earn',
          activeDock: 'earn',
          bottomAction: applied
              ? WorkPrimaryButton(
                  keyName: 'work-open-my-work-after-apply',
                  label: 'Open My Work',
                  onPressed: () => context.go('/app/work/my-work'),
                  icon: Icons.work_outline_rounded,
                )
              : WorkPrimaryButton(
                  keyName: 'work-apply-opportunity',
                  label: 'Apply now · ${opportunity.payment}',
                  busy: session.busy,
                  onPressed: () async {
                    final applied = await session.applySelectedOpportunity();
                    if (!context.mounted) return;
                    if (!applied && !session.hasVerifiedWorkspace) {
                      context.go('/app/work/my-work');
                    }
                  },
                  icon: Icons.send_rounded,
                ),
          body: ListView(
            key: const Key('work-opportunity-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              WorkCard(
                color: MoolColors.navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            opportunity.publisher,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const WorkPill(
                          label: 'Verified',
                          color: Color(0xFF9EE89B),
                          icon: Icons.verified_rounded,
                        ),
                      ],
                    ),
                    Text(
                      opportunity.publisherType,
                      style: const TextStyle(
                        color: Color(0xFFD9DAFF),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    Text(
                      opportunity.payment,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    Text(
                      opportunity.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      opportunity.summary,
                      style: const TextStyle(
                        color: Color(0xFFD9DAFF),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Wrap(
                      spacing: MoolSpacing.xs,
                      runSpacing: MoolSpacing.xs,
                      children: [
                        WorkPill(
                          label: 'Funded',
                          color: const Color(0xFF9EE89B),
                        ),
                        WorkPill(
                          label: opportunity.capacity,
                          color: Colors.white,
                        ),
                        WorkPill(
                          label: opportunity.location,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkSectionTitle(
                title: 'What you must complete',
                detail: 'The exact paid outcome',
              ),
              const SizedBox(height: MoolSpacing.sm),
              const _OutcomeStep(
                number: '1',
                text: 'Record one original 45–60 second vertical video.',
              ),
              const _OutcomeStep(
                number: '2',
                text:
                    'Explain MoolSocial accurately in Hindi or an approved regional language.',
              ),
              const _OutcomeStep(
                number: '3',
                text:
                    'Add the sponsored disclosure and submit before the deadline.',
              ),
              const SizedBox(height: MoolSpacing.md),
              WorkCard(
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Best fit',
                      value: opportunity.requiredWork,
                    ),
                    _InfoRow(label: 'Payout', value: opportunity.payout),
                    _InfoRow(
                      label: 'Availability',
                      value: opportunity.capacity,
                    ),
                    _InfoRow(label: 'Deadline', value: opportunity.deadline),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              const WorkSectionTitle(
                title: 'Terms before Apply',
                detail:
                    'Version 3 · each section is saved with the application',
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final term in workTerms) ...[
                WorkCard(
                  padding: EdgeInsets.zero,
                  child: ExpansionTile(
                    key: Key('work-term-${term.id}'),
                    initiallyExpanded: session.expandedTerms.contains(term.id),
                    onExpansionChanged: (_) => session.toggleTerm(term.id),
                    title: Text(
                      term.title,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      MoolSpacing.md,
                      0,
                      MoolSpacing.md,
                      MoolSpacing.md,
                    ),
                    children: [
                      Text(
                        term.detail,
                        style: const TextStyle(
                          color: MoolColors.muted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
              ],
              if (applied)
                WorkCard(
                  color: const Color(0xFFEAF7E8),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: MoolColors.success,
                        size: 42,
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      Text(
                        'Application ${session.applicationId}',
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Publisher review, corrections and payout timing will update in My Work and Chat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: MoolColors.muted),
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

class _OutcomeStep extends StatelessWidget {
  const _OutcomeStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
      child: WorkCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: MoolColors.navy,
              foregroundColor: Colors.white,
              child: Text(
                number,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: MoolSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: MoolColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: MoolSpacing.sm),
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
