import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_service_home.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/profile/global_profile_panel_v2.dart';
import '../widgets/work_widgets.dart';
import '../work_models.dart';
import '../work_session.dart';

GlobalProfileContextAction _workProfileContext(
  WorkSession session,
  ValueChanged<String> onOpenRoute,
) {
  final workspace = session.activeWorkspace;
  if (session.hasVerifiedWorkspace && workspace != null) {
    return GlobalProfileContextAction(
      id: 'work-workspace-active',
      title: workspace.name,
      detail: '${workspace.profileLabel} · ${workspace.area}',
      actionLabel: 'Open Workspace',
      icon: Icons.dashboard_customize_outlined,
      onPressed: () => onOpenRoute('/app/work/workspace/dashboard'),
    );
  }
  if (session.reviewCaseId != null) {
    return GlobalProfileContextAction(
      id: 'work-workspace-application',
      title: 'Workspace application',
      detail: 'Review status and provide requested information.',
      actionLabel: 'View application',
      icon: Icons.fact_check_outlined,
      onPressed: () => onOpenRoute('/app/work/workspace/proof'),
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
  Timer? _refreshNoticeTimer;

  @override
  void dispose() {
    _refreshNoticeTimer?.cancel();
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

  void _openWorkspaceSetup(BuildContext context) {
    widget.session.startAnotherWork();
    context.push('/app/work/workspace/choose');
  }

  void _startApplication(BuildContext context, WorkOpportunity opportunity) {
    widget.session.openOpportunity(opportunity.id);
    widget.session.startAnotherWork();
    context.push('/app/work/workspace/choose');
  }

  void _resetDiscovery() {
    _search.clear();
    widget.session.search('');
    widget.session.setFilter(WorkFeedFilter.forYou);
    widget.session.clearOpportunityFilters();
  }

  Future<void> _refreshFeed() async {
    _refreshNoticeTimer?.cancel();
    await widget.session.refreshFeed();
    if (!mounted ||
        widget.session.noticeMessage != 'Work opportunities refreshed.') {
      return;
    }
    _refreshNoticeTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted &&
          widget.session.noticeMessage == 'Work opportunities refreshed.') {
        widget.session.dismissMessages();
      }
    });
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
          final related = widget.session.relatedOpportunities;
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
              onFilter: () => context.push('/app/work/filters'),
              onProfile: () => _openProfile(context),
            ),
            fallbackBackRoute: '/app/mool?from=work',
            showBack: false,
            showHeaderChat: false,
            showTrailingAction: false,
            activeLocalAction: 'earn',
            body: Column(
              children: [
                _PersistentWorkspaceAssistance(
                  onPressed: () => _openWorkspaceSetup(context),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshFeed,
                    child: CustomScrollView(
                      key: const Key('work-earn-screen'),
                      slivers: [
                        if (widget.session.busy) ...[
                          const SliverToBoxAdapter(
                            child: LinearProgressIndicator(
                              key: Key('work-feed-loading'),
                              minHeight: 3,
                            ),
                          ),
                        ],
                        if (opportunities.isEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              MoolServiceHomeTokens.pagePadding,
                              MoolSpacing.sm,
                              MoolServiceHomeTokens.pagePadding,
                              MoolSpacing.sm,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: WorkEmptyState(
                                title: widget.session.selectedCity.isEmpty
                                    ? 'No paid work matches'
                                    : 'No openings found in ${widget.session.selectedCity}',
                                detail: related.isEmpty
                                    ? 'Try another search or location to discover available opportunities.'
                                    : 'Explore similar opportunities currently open in other locations.',
                                actionLabel: 'Reset search and filters',
                                onAction: _resetDiscovery,
                              ),
                            ),
                          ),
                        if (opportunities.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              MoolServiceHomeTokens.pagePadding,
                              MoolSpacing.sm,
                              MoolServiceHomeTokens.pagePadding,
                              0,
                            ),
                            sliver: SliverList.builder(
                              itemCount: opportunities.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: MoolSpacing.sm,
                                ),
                                child: _WorkReveal(
                                  order: index,
                                  child: _OpportunityCard(
                                    opportunity: opportunities[index],
                                    onOpen: () => _openOpportunity(
                                      context,
                                      opportunities[index],
                                    ),
                                    onApply: () => _startApplication(
                                      context,
                                      opportunities[index],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (related.isNotEmpty) ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              MoolServiceHomeTokens.pagePadding,
                              MoolSpacing.md,
                              MoolServiceHomeTokens.pagePadding,
                              MoolSpacing.sm,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: _RelatedWorkHeading(
                                city: widget.session.selectedCity,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: MoolServiceHomeTokens.pagePadding,
                            ),
                            sliver: SliverList.builder(
                              itemCount: related.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: MoolSpacing.sm,
                                ),
                                child: _WorkReveal(
                                  order: index,
                                  child: _OpportunityCard(
                                    opportunity: related[index],
                                    recommended: true,
                                    onOpen: () => _openOpportunity(
                                      context,
                                      related[index],
                                    ),
                                    onApply: () => _startApplication(
                                      context,
                                      related[index],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SliverToBoxAdapter(
                          child: SizedBox(height: MoolSpacing.xxl),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

class WorkOpportunityFilterScreen extends StatelessWidget {
  const WorkOpportunityFilterScreen({required this.session, super.key});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => WorkPageScaffold(
        session: session,
        title: 'Find paid work',
        subtitle: 'Choose the work and location that suit you',
        fallbackBackRoute: '/app/work/earn',
        activeLocalAction: 'earn',
        showHeaderChat: false,
        showTrailingAction: false,
        bottomAction: WorkPrimaryButton(
          keyName: 'work-filter-show-results',
          label: 'Show ${session.filteredOpportunities.length} opportunities',
          onPressed: () => context.pop(),
          icon: Icons.search_rounded,
        ),
        body: _OpportunityFilterContent(session: session),
      ),
    );
  }
}

class _OpportunityFilterContent extends StatelessWidget {
  const _OpportunityFilterContent({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final cities = <String>{
      'Delhi',
      ...workOpportunities
          .map((opportunity) => opportunity.city.trim())
          .where((city) => city.isNotEmpty && city != 'India'),
    }.toList()..sort();
    final areas =
        workOpportunities
            .where((opportunity) => opportunity.city == session.selectedCity)
            .map((opportunity) => opportunity.area)
            .where((area) => area.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final pincodes =
        workOpportunities
            .where(
              (opportunity) =>
                  opportunity.city == session.selectedCity &&
                  (session.selectedArea.isEmpty ||
                      opportunity.area == session.selectedArea),
            )
            .map((opportunity) => opportunity.pincode)
            .where((pincode) => pincode.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ListView(
      key: const Key('work-filter-screen'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.sm,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      children: [
        WorkCard(
          keyName: 'work-filter-type-section',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FilterSectionTitle(
                icon: Icons.work_outline_rounded,
                title: 'Work type',
                detail: 'Select the opportunities you want to see.',
              ),
              const SizedBox(height: MoolSpacing.sm),
              _FilterChoiceRow(
                semanticLabel: 'Work type',
                children: [
                  for (final value in WorkFeedFilter.values)
                    ChoiceChip(
                      key: ValueKey('work-filter-${value.name}'),
                      label: Text(value.label),
                      selected: session.filter == value,
                      onSelected: (_) => session.setFilter(value),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        WorkCard(
          keyName: 'work-filter-location-section',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FilterSectionTitle(
                icon: Icons.location_on_outlined,
                title: 'Preferred location',
                detail: 'Search by city, then narrow by area or PIN code.',
              ),
              const SizedBox(height: MoolSpacing.sm),
              Autocomplete<String>(
                key: const Key('work-filter-city-search'),
                initialValue: TextEditingValue(text: session.selectedCity),
                displayStringForOption: (city) => city,
                optionsBuilder: (value) {
                  final query = value.text.trim().toLowerCase();
                  return cities.where(
                    (city) => query.isEmpty
                        ? true
                        : city.toLowerCase().contains(query),
                  );
                },
                onSelected: (city) =>
                    session.setOpportunityLocationFilters(city: city),
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) => TextField(
                      key: const Key('work-filter-city-field'),
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: 'City',
                        hintText: 'Start typing a city name',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: session.selectedCity.isEmpty
                            ? null
                            : IconButton(
                                key: const Key('work-filter-city-clear'),
                                tooltip: 'Clear city',
                                onPressed: () {
                                  controller.clear();
                                  session.clearOpportunityFilters();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                      onSubmitted: (_) => onSubmitted(),
                    ),
                optionsViewBuilder: (context, onSelected, options) {
                  final visible = options.take(8).toList(growable: false);
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(MoolRadii.control),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 360,
                          maxHeight: 300,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: visible.length,
                          itemBuilder: (context, index) => ListTile(
                            key: ValueKey('work-filter-city-${visible[index]}'),
                            dense: true,
                            title: Text(visible[index]),
                            onTap: () => onSelected(visible[index]),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (session.selectedCity.isNotEmpty) ...[
                const SizedBox(height: MoolSpacing.md),
                if (areas.isNotEmpty) ...[
                  const Text(
                    'Area',
                    style: TextStyle(
                      color: MoolColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  _FilterChoiceRow(
                    semanticLabel: 'Area',
                    children: [
                      ChoiceChip(
                        key: const Key('work-filter-area-all'),
                        label: const Text('All areas'),
                        selected: session.selectedArea.isEmpty,
                        onSelected: (_) =>
                            session.setOpportunityLocationFilters(
                              city: session.selectedCity,
                            ),
                      ),
                      for (final area in areas)
                        ChoiceChip(
                          key: ValueKey('work-filter-area-$area'),
                          label: Text(area),
                          selected: session.selectedArea == area,
                          onSelected: (_) =>
                              session.setOpportunityLocationFilters(
                                city: session.selectedCity,
                                area: session.selectedArea == area ? '' : area,
                              ),
                        ),
                    ],
                  ),
                ],
                if (pincodes.isNotEmpty) ...[
                  const SizedBox(height: MoolSpacing.md),
                  const Text(
                    'PIN code',
                    style: TextStyle(
                      color: MoolColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  _FilterChoiceRow(
                    semanticLabel: 'PIN code',
                    children: [
                      for (final pincode in pincodes)
                        ChoiceChip(
                          key: ValueKey('work-filter-pincode-$pincode'),
                          label: Text(pincode),
                          selected: session.selectedPincode == pincode,
                          onSelected: (_) =>
                              session.setOpportunityLocationFilters(
                                city: session.selectedCity,
                                area: session.selectedArea,
                                pincode: session.selectedPincode == pincode
                                    ? ''
                                    : pincode,
                              ),
                        ),
                    ],
                  ),
                ],
                if (areas.isEmpty && pincodes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(MoolSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(MoolRadii.control),
                    ),
                    child: Text(
                      'No openings are currently listed in ${session.selectedCity}. Similar opportunities will remain available after you view results.',
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (session.filter != WorkFeedFilter.forYou ||
            session.hasOpportunityLocationFilter) ...[
          const SizedBox(height: MoolSpacing.sm),
          TextButton.icon(
            key: const Key('work-filter-clear'),
            onPressed: () {
              session.setFilter(WorkFeedFilter.forYou);
              session.clearOpportunityFilters();
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Clear all filters'),
          ),
        ],
      ],
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: MoolColors.navy),
        const SizedBox(width: MoolSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersistentWorkspaceAssistance extends StatelessWidget {
  const _PersistentWorkspaceAssistance({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('work-persistent-workspace-assistance'),
      color: const Color(0xFFFFF4E5),
      child: InkWell(
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MoolSpacing.md,
            vertical: 8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_business_outlined,
                color: MoolColors.navy,
                size: 21,
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Text(
                  'Create your Workspace, upload your documents and get setup support from a MoolSocial representative.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 10.5,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: MoolColors.orange),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChoiceRow extends StatelessWidget {
  const _FilterChoiceRow({required this.semanticLabel, required this.children});

  final String semanticLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Wrap(
        spacing: MoolSpacing.xs,
        runSpacing: MoolSpacing.xs,
        children: [...children],
      ),
    );
  }
}

class _RelatedWorkHeading extends StatelessWidget {
  const _RelatedWorkHeading({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-related-opportunities'),
      padding: const EdgeInsets.all(MoolSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(MoolRadii.control),
        border: Border.all(color: const Color(0xFFFFC37A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.explore_outlined, color: MoolColors.navy),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city.isEmpty
                      ? 'Similar opportunities'
                      : 'Open opportunities in other locations',
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Explore roles that match your skills while new openings are added in your selected location.',
                  style: TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.opportunity,
    required this.onOpen,
    required this.onApply,
    this.recommended = false,
  });

  final WorkOpportunity opportunity;
  final VoidCallback onOpen;
  final VoidCallback onApply;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final color = _cardColor(opportunity.cardColorToken);
    final owner = opportunity.posterType == WorkOpportunityPosterType.moolSocial
        ? 'Posted by MoolSocial'
        : 'Posted by a verified ${opportunity.posterType.label.toLowerCase()}';
    final posterLine = opportunity.publisher == opportunity.posterType.label
        ? opportunity.posterType.label
        : '${opportunity.posterType.label} · ${opportunity.publisher}';
    return Semantics(
      label:
          '$owner. ${opportunity.posterType.label}. ${opportunity.title}. ${opportunity.qualificationHeadline}. ${opportunity.requiredWork}. Monthly payment ${opportunity.monthlyPayment}. ${opportunity.positionsRemaining} positions remaining. Deadline ${opportunity.finalDeadline}.',
      container: true,
      button: true,
      onTap: onOpen,
      child: Material(
        key: Key('work-opportunity-${opportunity.id}'),
        color: Colors.white,
        borderRadius: BorderRadius.circular(MoolRadii.floating),
        elevation: 1.5,
        shadowColor: const Color(0x22000050),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(color: color, child: const SizedBox(width: 6)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(MoolSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: onOpen,
                        borderRadius: BorderRadius.circular(MoolRadii.control),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(
                                      MoolRadii.capsule,
                                    ),
                                  ),
                                  child: Text(
                                    recommended ? 'RECOMMENDED' : 'HIRING NOW',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      letterSpacing: .35,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  key: Key(
                                    'work-opportunity-owner-${opportunity.id}',
                                  ),
                                  child: Text(
                                    posterLine,
                                    key: Key(
                                      'work-opportunity-poster-type-${opportunity.id}',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: MoolColors.muted,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              opportunity.title,
                              key: Key(
                                'work-opportunity-position-${opportunity.id}',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: MoolColors.navy,
                                fontSize: 15.5,
                                height: 1.12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              opportunity.summary,
                              key: Key(
                                'work-opportunity-description-${opportunity.id}',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: MoolColors.muted,
                                fontSize: 10.5,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _CardFact(
                              key: Key(
                                'work-opportunity-candidate-requirements-${opportunity.id}',
                              ),
                              icon: Icons.verified_outlined,
                              text: opportunity.qualificationHeadline,
                              color: MoolColors.ink,
                              maxLines: 1,
                            ),
                            _CardFact(
                              key: Key(
                                'work-opportunity-requirement-${opportunity.id}',
                              ),
                              icon: Icons.work_outline_rounded,
                              text: opportunity.requiredWork,
                              color: MoolColors.ink,
                              maxLines: 1,
                            ),
                            _CardFact(
                              key: Key(
                                'work-opportunity-location-${opportunity.id}',
                              ),
                              icon: Icons.place_outlined,
                              text: opportunity.pincode.isEmpty
                                  ? '${opportunity.area}, ${opportunity.city}'
                                  : '${opportunity.area}, ${opportunity.city} · ${opportunity.pincode}',
                              color: MoolColors.muted,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: MoolSpacing.xs,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: .07),
                                borderRadius: BorderRadius.circular(
                                  MoolRadii.control,
                                ),
                                border: Border.all(
                                  color: color.withValues(alpha: .22),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'MONTHLY PAYMENT',
                                          style: TextStyle(
                                            color: MoolColors.muted,
                                            fontSize: 8,
                                            letterSpacing: .3,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        Text(
                                          opportunity.monthlyPayment,
                                          key: Key(
                                            'work-opportunity-pay-monthly-${opportunity.id}',
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 12,
                                            height: 1.15,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: MoolSpacing.xs),
                                  Text(
                                    opportunity.paymentAmount,
                                    key: Key(
                                      'work-opportunity-pay-amount-${opportunity.id}',
                                    ),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: MoolColors.ink,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (opportunity.hourlyPayment != null ||
                                opportunity.assignmentPayment != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: MoolSpacing.sm,
                                  runSpacing: 2,
                                  children: [
                                    if (opportunity.hourlyPayment
                                        case final hourly?)
                                      Text(
                                        'Hourly $hourly',
                                        key: Key(
                                          'work-opportunity-pay-hourly-${opportunity.id}',
                                        ),
                                        style: const TextStyle(
                                          color: MoolColors.muted,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    if (opportunity.assignmentPayment
                                        case final assignment?)
                                      Text(
                                        'Assignment $assignment',
                                        key: Key(
                                          'work-opportunity-pay-assignment-${opportunity.id}',
                                        ),
                                        style: const TextStyle(
                                          color: MoolColors.muted,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 6),
                            _LiveHiringStatus(
                              opportunity: opportunity,
                              accent: color,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton.icon(
                                key: Key(
                                  'work-opportunity-details-${opportunity.id}',
                                ),
                                onPressed: onOpen,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: MoolColors.navy,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  side: const BorderSide(
                                    color: MoolColors.navy,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.description_outlined,
                                  size: 17,
                                ),
                                label: const Text(
                                  'View details',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _AttentionApplyButton(
                              keyName:
                                  'work-opportunity-apply-${opportunity.id}',
                              onPressed: onApply,
                              accent: color,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _LiveHiringStatus extends StatefulWidget {
  const _LiveHiringStatus({required this.opportunity, required this.accent});

  final WorkOpportunity opportunity;
  final Color accent;

  @override
  State<_LiveHiringStatus> createState() => _LiveHiringStatusState();
}

class _LiveHiringStatusState extends State<_LiveHiringStatus>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: 1,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || MediaQuery.disableAnimationsOf(context)) return;
    _started = true;
    _controller.repeat(reverse: true, count: 4).whenComplete(() {
      if (mounted) _controller.value = 1;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opportunity = widget.opportunity;
    final pulse = Tween<double>(
      begin: .48,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    return Container(
      key: Key('work-opportunity-live-status-${opportunity.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(MoolRadii.control),
        border: Border.all(color: const Color(0xFFD8DAE8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    FadeTransition(
                      opacity: pulse,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD92D20),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'LIVE AVAILABILITY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: MoolColors.navy,
                          fontSize: 8,
                          letterSpacing: .25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Deadline ',
                        style: TextStyle(
                          color: MoolColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: opportunity.finalDeadline,
                        style: TextStyle(
                          color: widget.accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  key: Key('work-opportunity-deadline-${opportunity.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 8.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FadeTransition(
            opacity: pulse,
            child: Row(
              children: [
                _LiveMetric(
                  keyName: 'work-opportunity-needed-${opportunity.id}',
                  value: opportunity.peopleNeeded,
                  label: 'Needed',
                  color: MoolColors.navy,
                ),
                _LiveMetric(
                  keyName: 'work-opportunity-joined-${opportunity.id}',
                  value: opportunity.peopleJoined,
                  label: 'Joined',
                  color: MoolColors.success,
                ),
                _LiveMetric(
                  keyName: 'work-opportunity-progress-${opportunity.id}',
                  value: opportunity.applicationsInProgress,
                  label: 'In progress',
                  color: MoolColors.orange,
                ),
                _LiveMetric(
                  keyName: 'work-opportunity-left-${opportunity.id}',
                  value: opportunity.positionsRemaining,
                  label: 'Left',
                  color: widget.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(MoolRadii.capsule),
            child: SizedBox(
              height: 4,
              child: Row(
                children: [
                  Expanded(
                    flex: opportunity.peopleJoined,
                    child: const ColoredBox(color: MoolColors.success),
                  ),
                  Expanded(
                    flex: opportunity.applicationsInProgress,
                    child: const ColoredBox(color: MoolColors.orange),
                  ),
                  Expanded(
                    flex: opportunity.positionsRemaining,
                    child: ColoredBox(
                      color: widget.accent.withValues(alpha: .18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveMetric extends StatelessWidget {
  const _LiveMetric({
    required this.keyName,
    required this.value,
    required this.label,
    required this.color,
  });

  final String keyName;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            key: Key(keyName),
            style: TextStyle(
              color: color,
              fontSize: 16,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceSetupCta extends StatelessWidget {
  const _WorkspaceSetupCta({required this.keyName, required this.onPressed});

  final String keyName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(MoolRadii.control),
      child: InkWell(
        key: Key(keyName),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(MoolRadii.control),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MoolSpacing.xs,
            vertical: MoolSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.add_business_outlined,
                color: MoolColors.navy,
                size: 19,
              ),
              const SizedBox(width: MoolSpacing.xs),
              const Expanded(
                child: Text(
                  'Create your workspace and upload documents for account setup and help from a MoolSocial representative.',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: MoolColors.orange,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionApplyButton extends StatefulWidget {
  const _AttentionApplyButton({
    required this.keyName,
    required this.onPressed,
    required this.accent,
    this.compact = false,
  });

  final String keyName;
  final VoidCallback? onPressed;
  final Color accent;
  final bool compact;

  @override
  State<_AttentionApplyButton> createState() => _AttentionApplyButtonState();
}

class _AttentionApplyButtonState extends State<_AttentionApplyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  bool _motionStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionStarted || MediaQuery.disableAnimationsOf(context)) return;
    _motionStarted = true;
    _controller.repeat(reverse: true, count: 4).whenComplete(() {
      if (mounted) _controller.value = 1;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: .72,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: SizedBox(
        width: double.infinity,
        height: widget.compact ? 44 : 48,
        child: FilledButton(
          key: Key(widget.keyName),
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: MoolColors.navy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            disabledBackgroundColor: MoolColors.muted.withValues(alpha: .28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MoolRadii.control),
              side: BorderSide(color: widget.accent, width: 2),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: MoolColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                const Text(
                  'Apply Now',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkReveal extends StatelessWidget {
  const _WorkReveal({required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MoolMotion.accessible(
        context,
        Duration(milliseconds: 220 + (order.clamp(0, 4) * 45)),
      ),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _CardFact extends StatelessWidget {
  const _CardFact({
    required this.icon,
    required this.text,
    this.color = Colors.white,
    this.maxLines,
    super.key,
  });

  final IconData icon;
  final String text;
  final Color color;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: maxLines == null ? null : TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                height: 1.25,
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
        subtitle: 'This opportunity is no longer available',
        fallbackBackRoute: '/app/work/earn',
        activeLocalAction: 'earn',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            WorkEmptyState(
              title: 'This paid-work link is unavailable',
              detail: 'Return to Earn Today to view current opportunities.',
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
          title: 'Opportunity details',
          subtitle: 'Posted by ${opportunity.posterType.label}',
          fallbackBackRoute: '/app/work/earn',
          activeLocalAction: 'earn',
          showHeaderChat: false,
          showTrailingAction: false,
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
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WorkspaceSetupCta(
                      keyName: 'work-detail-workspace-setup',
                      onPressed: () {
                        session.startAnotherWork();
                        context.push('/app/work/workspace/choose');
                      },
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    _AttentionApplyButton(
                      keyName: 'work-apply-opportunity',
                      accent: _cardColor(opportunity.cardColorToken),
                      onPressed: opportunity.available && !session.busy
                          ? () {
                              session.startAnotherWork();
                              context.push('/app/work/workspace/choose');
                            }
                          : null,
                    ),
                  ],
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
              _WorkReveal(
                order: 0,
                child: _OpportunityDetailHero(opportunity: opportunity),
              ),
              const SizedBox(height: MoolSpacing.md),
              _WorkReveal(
                order: 1,
                child: _DetailSection(
                  keyName: 'work-detail-about-role',
                  title: 'About the Role',
                  icon: Icons.badge_outlined,
                  accent: const Color(0xFF0047AB),
                  tint: const Color(0xFFEAF2FF),
                  child: Text(opportunity.aboutRole),
                ),
              ),
              _WorkReveal(
                order: 2,
                child: _DetailSection(
                  keyName: 'work-detail-what-youll-do',
                  title: 'What You’ll Do',
                  icon: Icons.task_alt_rounded,
                  accent: const Color(0xFF007A4D),
                  tint: const Color(0xFFE8F7F0),
                  child: _BulletList(
                    items: opportunity.whatYoullDo,
                    bulletColor: const Color(0xFF007A4D),
                  ),
                ),
              ),
              _WorkReveal(
                order: 3,
                child: _DetailSection(
                  keyName: 'work-detail-who-you-are',
                  title: 'Who You Are',
                  icon: Icons.verified_user_outlined,
                  accent: const Color(0xFF5B21B6),
                  tint: const Color(0xFFF2EDFF),
                  child: _BulletList(
                    items: opportunity.whoYouAre,
                    bulletColor: const Color(0xFF5B21B6),
                  ),
                ),
              ),
              _WorkReveal(
                order: 4,
                child: _DetailSection(
                  keyName: 'work-detail-nice-to-have',
                  title: 'Nice to Have',
                  icon: Icons.auto_awesome_outlined,
                  accent: const Color(0xFFA65A00),
                  tint: const Color(0xFFFFF4E5),
                  child: _BulletList(
                    items: opportunity.niceToHave,
                    bulletColor: const Color(0xFFA65A00),
                  ),
                ),
              ),
              _WorkReveal(
                order: 4,
                child: _DetailSection(
                  keyName: 'work-detail-why-join',
                  title: 'Why Join MoolSocial',
                  icon: Icons.bolt_rounded,
                  accent: MoolColors.orange,
                  tint: const Color(0xFFFFF7ED),
                  child: Text(opportunity.whyJoin),
                ),
              ),
              _WorkReveal(
                order: 4,
                child: _PaymentDetails(opportunity: opportunity),
              ),
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
                        'Application updates and next steps will appear in Work Chat.',
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
                    'Application withdrawn. You may apply again while this opportunity remains open.',
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
    final accent = _cardColor(opportunity.cardColorToken);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MoolRadii.floating),
        border: Border.all(color: accent.withValues(alpha: .42)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000050),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: accent,
            padding: const EdgeInsets.symmetric(
              horizontal: MoolSpacing.md,
              vertical: MoolSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    opportunity.deadline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opportunity.posterType == WorkOpportunityPosterType.moolSocial
                      ? 'POSTED BY MOOLSOCIAL · ${opportunity.publisher}'
                      : 'POSTED BY VERIFIED ${opportunity.posterType.label.toUpperCase()} · ${opportunity.publisher}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    letterSpacing: .35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  opportunity.title,
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 22,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
                Text(
                  opportunity.summary,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                _DecisionSnapshot(opportunity: opportunity, accent: accent),
                const SizedBox(height: MoolSpacing.sm),
                _LiveHiringStatus(opportunity: opportunity, accent: accent),
              ],
            ),
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
    required this.icon,
    required this.accent,
    required this.tint,
  });

  final String keyName;
  final String title;
  final Widget child;
  final IconData icon;
  final Color accent;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key(keyName),
      margin: const EdgeInsets.only(bottom: MoolSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MoolRadii.floating),
        border: Border.all(color: accent.withValues(alpha: .28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(color: accent, child: const SizedBox(width: 5)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(MoolSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MoolSpacing.xs,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tint,
                        borderRadius: BorderRadius.circular(MoolRadii.control),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: accent, size: 19),
                          const SizedBox(width: MoolSpacing.xs),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: accent,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    DefaultTextStyle(
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 12.5,
                        height: 1.38,
                        fontWeight: FontWeight.w600,
                      ),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionSnapshot extends StatelessWidget {
  const _DecisionSnapshot({required this.opportunity, required this.accent});

  final WorkOpportunity opportunity;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MoolSpacing.sm),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(MoolRadii.control),
        border: Border.all(color: accent.withValues(alpha: .22)),
      ),
      child: Column(
        children: [
          _DecisionRow(
            icon: Icons.verified_user_outlined,
            label: 'You need',
            value: opportunity.qualificationHeadline,
            accent: accent,
          ),
          const Divider(height: MoolSpacing.md),
          _DecisionRow(
            icon: Icons.place_outlined,
            label: 'Where',
            value: opportunity.pincode.isEmpty
                ? '${opportunity.area}, ${opportunity.city}'
                : '${opportunity.area}, ${opportunity.city} · ${opportunity.pincode}',
            accent: accent,
          ),
          const Divider(height: MoolSpacing.md),
          _DecisionRow(
            icon: Icons.payments_outlined,
            label: 'You can earn',
            value: opportunity.monthlyPayment,
            accent: accent,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _DecisionRow extends StatelessWidget {
  const _DecisionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 19),
        const SizedBox(width: MoolSpacing.xs),
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: emphasized ? accent : MoolColors.ink,
              fontSize: 11.5,
              height: 1.28,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, this.bulletColor = MoolColors.navy});

  final List<String> items;
  final Color bulletColor;

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
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: bulletColor,
                      shape: BoxShape.circle,
                    ),
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
    final rows = <(String, String)>[
      ('Payment for this work', opportunity.paymentAmount),
      if (opportunity.hourlyPayment case final hourly?)
        ('Hourly payment', hourly),
      if (opportunity.assignmentPayment case final assignment?)
        ('Payment per assignment', assignment),
      ('Payment schedule', opportunity.payout),
      ('Available budget', opportunity.fundingNote),
    ];
    return _DetailSection(
      keyName: 'work-detail-payment',
      title: 'Payment details',
      icon: Icons.account_balance_wallet_outlined,
      accent: const Color(0xFF007A4D),
      tint: const Color(0xFFE8F7F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MoolSpacing.sm),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007A4D), Color(0xFF005F3C)],
              ),
              borderRadius: BorderRadius.circular(MoolRadii.control),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MONTHLY EARNING POTENTIAL',
                  style: TextStyle(
                    color: Color(0xFFD8FFEA),
                    fontSize: 9,
                    letterSpacing: .45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  opportunity.monthlyPayment,
                  key: const Key('work-payment-monthly-highlight'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Container(
            key: const Key('work-payment-table'),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB8DCC9)),
              borderRadius: BorderRadius.circular(MoolRadii.control),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(.9),
                1: FlexColumnWidth(1.35),
              },
              border: const TableBorder(
                horizontalInside: BorderSide(color: Color(0xFFD7E9DF)),
                verticalInside: BorderSide(color: Color(0xFFD7E9DF)),
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFE8F7F0)),
                  children: [
                    _PaymentCell(text: 'Payment type', header: true),
                    _PaymentCell(text: 'Amount and schedule', header: true),
                  ],
                ),
                for (var index = 0; index < rows.length; index += 1)
                  TableRow(
                    decoration: BoxDecoration(
                      color: index.isEven
                          ? Colors.white
                          : const Color(0xFFF7FBF9),
                    ),
                    children: [
                      _PaymentCell(text: rows[index].$1),
                      _PaymentCell(text: rows[index].$2, value: true),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCell extends StatelessWidget {
  const _PaymentCell({
    required this.text,
    this.header = false,
    this.value = false,
  });

  final String text;
  final bool header;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MoolSpacing.xs,
        vertical: 9,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: header
              ? const Color(0xFF005F3C)
              : value
              ? MoolColors.ink
              : MoolColors.muted,
          fontSize: header ? 10.5 : 11,
          height: 1.3,
          fontWeight: header || value ? FontWeight.w900 : FontWeight.w700,
        ),
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
            'This removes only this application. You can apply again while the opportunity remains open.',
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
