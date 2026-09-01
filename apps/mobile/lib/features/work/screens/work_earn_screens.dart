import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_service_home.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/profile/global_profile_panel_v2.dart';
import '../widgets/work_opportunity_filter_sheet.dart';
import '../widgets/work_widgets.dart';
import '../work_models.dart';
import '../work_session.dart';

GlobalProfileContextAction _workProfileContext(
  WorkSession session,
  ValueChanged<String> onOpenRoute,
) {
  final workspace = session.activeWorkspace;
  if (session.reviewStage == WorkReviewStage.live && workspace != null) {
    return GlobalProfileContextAction(
      id: 'work-workspace-active',
      title: workspace.name,
      detail: '${workspace.profileLabel} · ${workspace.area}',
      actionLabel: 'Open Workspace',
      icon: Icons.dashboard_customize_outlined,
      onPressed: () => onOpenRoute('/app/work/my-work'),
    );
  }
  if (session.reviewCaseId != null) {
    return GlobalProfileContextAction(
      id: 'work-workspace-application',
      title: 'Workspace application',
      detail: 'Review status and provide requested information.',
      actionLabel: 'View application',
      icon: Icons.fact_check_outlined,
      onPressed: () => onOpenRoute('/app/work/my-work'),
    );
  }
  return GlobalProfileContextAction(
    id: 'work-workspace-create',
    title: 'Create a provider Workspace',
    detail: 'Choose how you work and submit the required information.',
    actionLabel: 'Start Workspace setup',
    icon: Icons.add_business_outlined,
    onPressed: () => onOpenRoute('/app/work/workspace/choose'),
  );
}

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
  final FocusNode _searchFocus = FocusNode(debugLabel: 'work-earn-search');
  bool _searchOpen = false;

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _setSearchOpen(bool value) {
    if (_searchOpen == value) return;
    setState(() => _searchOpen = value);
    if (value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    } else {
      _searchFocus.unfocus();
    }
  }

  void _openOpportunity(BuildContext context, WorkOpportunity opportunity) {
    widget.session.openOpportunity(opportunity.id);
    context.go('/app/work/opportunity/${opportunity.id}');
  }

  Future<void> _openFilters(BuildContext context) async {
    final cities =
        workOpportunities
            .map((opportunity) => opportunity.city.trim())
            .where((city) => city.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final selected = await showWorkOpportunityFilterSheet(
      context,
      initial: WorkOpportunityFilterSelection(
        type: widget.session.filter,
        city: widget.session.selectedCity,
        area: widget.session.selectedArea,
        pincode: widget.session.selectedPincode,
      ),
      cities: cities,
    );
    if (selected == null || !mounted) return;
    widget.session.setFilter(selected.type);
    widget.session.setOpportunityLocationFilters(
      city: selected.city,
      area: selected.area,
      pincode: selected.pincode,
    );
  }

  void _resetDiscovery() {
    _search.clear();
    widget.session.search('');
    widget.session.setFilter(WorkFeedFilter.forYou);
    widget.session.clearOpportunityFilters();
  }

  void _openProfile(BuildContext context) {
    void openRoute(String route) {
      if (route.startsWith('/app/work/workspace/choose')) {
        widget.session.startAnotherWork();
      }
      context.push(route);
    }

    showGlobalProfilePanelV2(
      context,
      contextAction: _workProfileContext(widget.session, openRoute),
      onOpenRoute: openRoute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_searchOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _searchOpen) _setSearchOpen(false);
      },
      child: AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) {
          final opportunities = widget.session.filteredOpportunities;
          final filterCount =
              widget.session.activeOpportunityFilterCount +
              (widget.session.filter == WorkFeedFilter.forYou ? 0 : 1);
          return WorkPageScaffold(
            session: widget.session,
            title: 'Earn Today',
            subtitle: 'Paid work',
            headerTitle: _WorkEarnSearchHeader(
              open: _searchOpen,
              controller: _search,
              focusNode: _searchFocus,
              query: widget.session.searchQuery,
              onOpen: () => _setSearchOpen(true),
              onClose: () => _setSearchOpen(false),
              onChanged: widget.session.search,
              onClear: () {
                _search.clear();
                widget.session.search('');
              },
              filterCount: filterCount,
              onFilter: () => _openFilters(context),
              onProfile: () => _openProfile(context),
            ),
            fallbackBackRoute: '/app/mool?from=work',
            showBack: false,
            showHeaderChat: false,
            showTrailingAction: false,
            activeLocalAction: 'earn',
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
                  if (widget.session.busy) ...[
                    const LinearProgressIndicator(
                      key: Key('work-feed-loading'),
                      minHeight: 3,
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                  ],
                  if (opportunities.isEmpty)
                    WorkEmptyState(
                      title: 'No paid work matches',
                      detail:
                          'Clear the search or location filters to see other funded requirements.',
                      actionLabel: 'Reset search and filters',
                      onAction: _resetDiscovery,
                    )
                  else
                    for (
                      var index = 0;
                      index < opportunities.length;
                      index += 1
                    ) ...[
                      _OpportunityCard(
                        opportunity: opportunities[index],
                        onOpen: () =>
                            _openOpportunity(context, opportunities[index]),
                      ),
                      if (index != opportunities.length - 1)
                        const SizedBox(height: MoolSpacing.sm),
                    ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorkEarnSearchHeader extends StatelessWidget {
  const _WorkEarnSearchHeader({
    required this.open,
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onOpen,
    required this.onClose,
    required this.onChanged,
    required this.onClear,
    required this.filterCount,
    required this.onFilter,
    required this.onProfile,
  });

  final bool open;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final int filterCount;
  final VoidCallback onFilter;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('work-earn-inline-header'),
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: Material(
              key: const Key('work-search-control'),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MoolRadii.control),
                side: const BorderSide(color: Color(0xFFD8DAE8)),
              ),
              clipBehavior: Clip.antiAlias,
              child: open
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('work-search'),
                            controller: controller,
                            focusNode: focusNode,
                            autofocus: true,
                            onChanged: onChanged,
                            textInputAction: TextInputAction.search,
                            maxLines: 1,
                            style: const TextStyle(
                              color: MoolColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search paid work',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: MoolColors.navy,
                              ),
                              prefixIconConstraints: BoxConstraints(
                                minWidth: 42,
                                minHeight: 44,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                            ),
                            onSubmitted: (_) {
                              FocusScope.of(context).unfocus();
                              onClose();
                            },
                          ),
                        ),
                        if (controller.text.isNotEmpty)
                          IconButton(
                            key: const Key('work-clear-search'),
                            tooltip: 'Clear search',
                            onPressed: onClear,
                            icon: const Icon(Icons.close_rounded),
                            constraints: const BoxConstraints.tightFor(
                              width: 44,
                              height: 44,
                            ),
                          ),
                        IconButton(
                          key: const Key('work-search-close'),
                          tooltip: 'Finish search',
                          onPressed: onClose,
                          icon: const Icon(Icons.check_rounded),
                          constraints: const BoxConstraints.tightFor(
                            width: 44,
                            height: 44,
                          ),
                        ),
                      ],
                    )
                  : Semantics(
                      label: 'Search paid work',
                      button: true,
                      child: InkWell(
                        key: const Key('work-search'),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onOpen();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: MoolColors.navy,
                                size: 21,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  query.isEmpty ? 'Search paid work' : query,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: query.isEmpty
                                        ? MoolColors.muted
                                        : MoolColors.ink,
                                    fontSize: 12,
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
          ),
        ),
        if (!open) ...[
          const SizedBox(width: 6),
          _WorkFilterButton(count: filterCount, onPressed: onFilter),
          const SizedBox(width: 4),
          MoolGlobalProfileShortcutV2(
            keyName: 'work-earn-global-profile',
            onPressed: onProfile,
          ),
        ],
      ],
    );
  }
}

class _WorkFilterButton extends StatelessWidget {
  const _WorkFilterButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.outlined(
          key: const Key('work-filter-button'),
          tooltip: count == 0
              ? 'Filter paid work'
              : 'Filter paid work, $count active',
          onPressed: onPressed,
          icon: const Icon(Icons.tune_rounded),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: MoolColors.orange,
              foregroundColor: Colors.white,
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opportunity, required this.onOpen});

  final WorkOpportunity opportunity;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = _cardColor(opportunity.cardColorToken);
    final owner = opportunity.posterType == WorkOpportunityPosterType.moolSocial
        ? 'MoolSocial-owned'
        : 'MoolSocial user-owned';
    return Semantics(
      button: true,
      label:
          '$owner. ${opportunity.posterType.label}. ${opportunity.title}. ${opportunity.qualificationHeadline}. Monthly payment ${opportunity.monthlyPayment}.',
      onTap: onOpen,
      excludeSemantics: true,
      child: Material(
        key: Key('work-opportunity-${opportunity.id}'),
        color: color,
        borderRadius: BorderRadius.circular(MoolRadii.floating),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: MoolSpacing.xs,
                  runSpacing: MoolSpacing.xs,
                  children: [
                    _WhiteTag(
                      key: Key('work-opportunity-owner-${opportunity.id}'),
                      label: owner,
                    ),
                    if (opportunity.funded)
                      _WhiteTag(
                        key: Key('work-opportunity-funding-${opportunity.id}'),
                        label: 'Funded',
                      ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.sm),
                Text(
                  'Posted by ${opportunity.posterType.label} · ${opportunity.publisher}',
                  key: Key('work-opportunity-poster-type-${opportunity.id}'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  opportunity.title,
                  key: Key('work-opportunity-position-${opportunity.id}'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
                Text(
                  opportunity.summary,
                  key: Key('work-opportunity-description-${opportunity.id}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF4F4FF),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                _CardFact(
                  key: Key(
                    'work-opportunity-candidate-requirements-${opportunity.id}',
                  ),
                  icon: Icons.verified_user_outlined,
                  text: opportunity.qualificationHeadline,
                ),
                _CardFact(
                  key: Key('work-opportunity-requirement-${opportunity.id}'),
                  icon: Icons.assignment_outlined,
                  text: opportunity.requiredWork,
                ),
                _CardFact(
                  key: Key('work-opportunity-location-${opportunity.id}'),
                  icon: Icons.place_outlined,
                  text:
                      '${opportunity.area}, ${opportunity.city} · ${opportunity.pincode}',
                ),
                const SizedBox(height: MoolSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(MoolSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(MoolRadii.control),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunity.paymentAmount,
                        key: Key(
                          'work-opportunity-pay-amount-${opportunity.id}',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Monthly payment',
                        style: TextStyle(
                          color: Color(0xFFEFEFFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        opportunity.monthlyPayment,
                        key: Key(
                          'work-opportunity-pay-monthly-${opportunity.id}',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Primary format · monthly',
                        key: Key(
                          'work-opportunity-pay-format-${opportunity.id}',
                        ),
                        style: const TextStyle(
                          color: Color(0xFFEFEFFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (opportunity.hourlyPayment case final hourly?)
                        Text(
                          'Hourly: $hourly',
                          key: Key(
                            'work-opportunity-pay-hourly-${opportunity.id}',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (opportunity.assignmentPayment case final assignment?)
                        Text(
                          'Per assignment: $assignment',
                          key: Key(
                            'work-opportunity-pay-assignment-${opportunity.id}',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: Key('work-opportunity-apply-${opportunity.id}'),
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: color,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhiteTag extends StatelessWidget {
  const _WhiteTag({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .17),
        borderRadius: BorderRadius.circular(MoolRadii.capsule),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CardFact extends StatelessWidget {
  const _CardFact({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                height: 1.3,
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
    final matches = workOpportunities.where(
      (opportunity) => opportunity.id == opportunityId,
    );
    if (matches.isEmpty) {
      return WorkPageScaffold(
        session: session,
        title: 'Paid work unavailable',
        subtitle: 'This requirement is no longer available',
        fallbackBackRoute: '/app/work/earn',
        activeLocalAction: 'earn',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            WorkEmptyState(
              title: 'This paid-work link is unavailable',
              detail: 'Return to Earn Today to review current funded work.',
              actionLabel: 'Open Earn Today',
              onAction: () => context.go('/app/work/earn'),
            ),
          ],
        ),
      );
    }
    final opportunity = matches.single;
    if (session.selectedOpportunity?.id != opportunity.id) {
      session.openOpportunity(opportunity.id);
    }
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final applied = session.applicationIdsByOpportunity.containsKey(
          opportunity.id,
        );
        return WorkPageScaffold(
          session: session,
          title: opportunity.title,
          subtitle: '${opportunity.posterType.label} paid requirement',
          fallbackBackRoute: '/app/work/earn',
          activeLocalAction: 'earn',
          bottomAction: applied
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: null,
                        child: Text('Application submitted'),
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('work-withdraw-application'),
                      onPressed: session.busy
                          ? null
                          : () => _confirmWithdrawal(context, session),
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Withdraw'),
                    ),
                  ],
                )
              : WorkPrimaryButton(
                  keyName: 'work-apply-opportunity',
                  label: 'Apply · ${opportunity.monthlyPayment}',
                  busy: session.busy,
                  onPressed: opportunity.available
                      ? () async {
                          final success = await session
                              .applySelectedOpportunity();
                          if (!context.mounted) return;
                          if (!success &&
                              opportunity.requiresWorkspace &&
                              !session.hasVerifiedWorkspace) {
                            context.go('/app/work/my-work');
                          }
                        }
                      : null,
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
              _OpportunityDetailHero(opportunity: opportunity),
              const SizedBox(height: MoolSpacing.md),
              _DetailSection(
                keyName: 'work-detail-about-role',
                title: 'About the Role',
                child: Text(opportunity.aboutRole),
              ),
              _DetailSection(
                keyName: 'work-detail-what-youll-do',
                title: 'What You’ll Do',
                child: _BulletList(items: opportunity.whatYoullDo),
              ),
              _DetailSection(
                keyName: 'work-detail-who-you-are',
                title: 'Who You Are',
                child: _BulletList(items: opportunity.whoYouAre),
              ),
              _DetailSection(
                keyName: 'work-detail-nice-to-have',
                title: 'Nice to Have',
                child: _BulletList(items: opportunity.niceToHave),
              ),
              _DetailSection(
                keyName: 'work-detail-why-join',
                title: 'Why Join MoolSocial',
                child: Text(opportunity.whyJoin),
              ),
              _PaymentDetails(opportunity: opportunity),
              if (applied) ...[
                const SizedBox(height: MoolSpacing.md),
                WorkCard(
                  color: const Color(0xFFEAF7E8),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: MoolColors.success,
                        size: 40,
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      Text(
                        'Application ${session.applicationIdsByOpportunity[opportunity.id]}',
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Updates and exact next steps will appear in Work Chat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: MoolColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
              if (session.withdrawnApplicationId != null && !applied) ...[
                const SizedBox(height: MoolSpacing.md),
                const WorkCard(
                  color: Color(0xFFFFF4E5),
                  child: Text(
                    'Application withdrawn. You may apply again while this paid requirement remains open.',
                    style: TextStyle(
                      color: MoolColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OpportunityDetailHero extends StatelessWidget {
  const _OpportunityDetailHero({required this.opportunity});

  final WorkOpportunity opportunity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MoolSpacing.md),
      decoration: BoxDecoration(
        color: _cardColor(opportunity.cardColorToken),
        borderRadius: BorderRadius.circular(MoolRadii.floating),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            opportunity.posterType == WorkOpportunityPosterType.moolSocial
                ? 'MoolSocial-owned · ${opportunity.publisher}'
                : 'User-owned · ${opportunity.posterType.label} · ${opportunity.publisher}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            opportunity.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          _CardFact(
            icon: Icons.verified_user_outlined,
            text: opportunity.qualificationHeadline,
          ),
          _CardFact(
            icon: Icons.place_outlined,
            text:
                '${opportunity.area}, ${opportunity.city} · ${opportunity.pincode}',
          ),
          _CardFact(
            icon: Icons.payments_outlined,
            text: 'Monthly payment: ${opportunity.monthlyPayment}',
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.keyName,
    required this.title,
    required this.child,
  });

  final String keyName;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MoolSpacing.md),
      child: WorkCard(
        keyName: keyName,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            DefaultTextStyle(
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: CircleAvatar(
                    radius: 3,
                    backgroundColor: MoolColors.navy,
                  ),
                ),
                const SizedBox(width: MoolSpacing.sm),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}

class _PaymentDetails extends StatelessWidget {
  const _PaymentDetails({required this.opportunity});

  final WorkOpportunity opportunity;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      keyName: 'work-detail-payment',
      title: 'Payment details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PaymentRow(
            label: 'Payment amount',
            value: opportunity.paymentAmount,
          ),
          _PaymentRow(
            label: 'Monthly payment',
            value: opportunity.monthlyPayment,
            emphasized: true,
          ),
          if (opportunity.hourlyPayment case final hourly?)
            _PaymentRow(label: 'Hourly payment', value: hourly),
          if (opportunity.assignmentPayment case final assignment?)
            _PaymentRow(label: 'Assignment payment', value: assignment),
          _PaymentRow(label: 'Payout timing', value: opportunity.payout),
          _PaymentRow(label: 'Funding', value: opportunity.fundingNote),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: MoolColors.muted)),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: MoolColors.ink,
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmWithdrawal(
  BuildContext context,
  WorkSession session,
) async {
  final confirmed = await showModalBottomSheet<bool>(
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
        key: const Key('work-withdraw-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Withdraw application?',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text(
            'This removes only this application. You can apply again while the requirement remains open.',
            style: TextStyle(color: MoolColors.muted, height: 1.4),
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton(
            key: const Key('work-withdraw-confirm'),
            onPressed: () => Navigator.of(sheetContext).pop(true),
            child: const Text('Withdraw'),
          ),
          TextButton(
            key: const Key('work-withdraw-cancel'),
            onPressed: () => Navigator.of(sheetContext).pop(false),
            child: const Text('Keep application'),
          ),
        ],
      ),
    ),
  );
  if (confirmed == true && context.mounted) {
    await session.withdrawSelectedOpportunity();
  }
}

Color _cardColor(WorkOpportunityCardColorToken token) => switch (token) {
  WorkOpportunityCardColorToken.cobalt => const Color(0xFF0047AB),
  WorkOpportunityCardColorToken.emerald => const Color(0xFF007A4D),
  WorkOpportunityCardColorToken.crimson => const Color(0xFFB00020),
  WorkOpportunityCardColorToken.violet => const Color(0xFF5B21B6),
  WorkOpportunityCardColorToken.amber => const Color(0xFFA65A00),
  WorkOpportunityCardColorToken.teal => const Color(0xFF006D77),
  WorkOpportunityCardColorToken.magenta => const Color(0xFF9C1C6B),
  WorkOpportunityCardColorToken.indigo => const Color(0xFF283593),
};
