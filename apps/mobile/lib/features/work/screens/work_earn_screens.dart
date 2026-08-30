import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_service_home.dart';
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
          title: 'Earn Today',
          subtitle: 'Pay, location and timing before you apply',
          fallbackBackRoute: '/app/work',
          showBack: false,
          activeLocalAction: 'earn',
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
                MoolServiceHomeTokens.pagePadding,
                MoolSpacing.xs,
                MoolServiceHomeTokens.pagePadding,
                MoolSpacing.xxl,
              ),
              children: [
                MoolServiceSearchField(
                  key: const Key('work-search-surface'),
                  fieldKey: const Key('work-search'),
                  controller: _search,
                  onChanged: widget.session.search,
                  hintText: 'Search work, publisher or location',
                  semanticLabel: 'Search work opportunities',
                  trailing: _search.text.isEmpty
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
                const SizedBox(height: MoolSpacing.sm),
                Wrap(
                  key: const Key('work-filter-list'),
                  spacing: MoolSpacing.xs,
                  runSpacing: MoolSpacing.xs,
                  children: [
                    for (final value in WorkFeedFilter.values)
                      MoolServiceChoice(
                        key: Key('work-filter-${value.name}'),
                        label: value.label,
                        selected: widget.session.filter == value,
                        onSelected: (_) => widget.session.setFilter(value),
                        accent: _workAccent,
                      ),
                  ],
                ),
                const SizedBox(height: MoolServiceHomeTokens.sectionGap),
                MoolServiceSectionHeader(
                  title: 'Work matching this view',
                  subtitle: opportunities.isEmpty
                      ? 'Try another filter or clear the search'
                      : '${opportunities.length} opportunities · eligibility and approval apply',
                ),
                const SizedBox(height: MoolSpacing.sm),
                if (opportunities.isEmpty)
                  WorkEmptyState(
                    title: 'No opportunities in this view',
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
                      onReview: () => _openOpportunity(context, opportunity),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                  ],
                MoolServiceCard(
                  key: const Key('work-start-my-work'),
                  title: 'Need a verified Workspace?',
                  subtitle:
                      'Set up one existing work or business profile, then return to an opportunity.',
                  icon: Icons.work_outline_rounded,
                  accent: _workAccent,
                  emphasized: true,
                  semanticLabel: 'Open Workspace setup',
                  onTap: () {
                    widget.session.startMyWork();
                    context.go('/app/work/my-work');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

const _workAccent = Color(0xFF4D46A8);

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opportunity, required this.onReview});

  final WorkOpportunity opportunity;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      keyName: 'work-opportunity-${opportunity.id}',
      onTap: onReview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _workAccent.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                ),
                child: Icon(opportunity.icon, color: _workAccent, size: 22),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${opportunity.kind} · ${opportunity.publisherType}',
                      style: const TextStyle(
                        color: MoolColors.success,
                        fontSize: MoolServiceHomeTokens.metadataSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      opportunity.title,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: MoolServiceHomeTokens.cardTitleSize,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      opportunity.publisher,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: MoolServiceHomeTokens.metadataSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          Text(
            opportunity.summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: MoolServiceHomeTokens.bodySize,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Wrap(
            spacing: MoolSpacing.sm,
            runSpacing: MoolSpacing.xs,
            children: [
              _WorkFact(
                icon: Icons.payments_outlined,
                label: opportunity.payment,
              ),
              _WorkFact(
                icon: Icons.place_outlined,
                label: opportunity.location,
              ),
              _WorkFact(
                icon: Icons.schedule_rounded,
                label: opportunity.deadline,
              ),
              _WorkFact(
                icon: Icons.verified_outlined,
                label: opportunity.fundingNote,
              ),
              _WorkFact(
                icon: Icons.account_balance_wallet_outlined,
                label: opportunity.payout,
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          SizedBox(
            key: Key('work-review-${opportunity.id}'),
            width: double.infinity,
            child: MoolServicePrimaryButton(
              label: 'Review opportunity',
              onPressed: onReview,
              accent: _workAccent,
              icon: Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkFact extends StatelessWidget {
  const _WorkFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: MoolColors.muted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: MoolColors.muted,
                fontSize: MoolServiceHomeTokens.metadataSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
          activeLocalAction: 'earn',
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
