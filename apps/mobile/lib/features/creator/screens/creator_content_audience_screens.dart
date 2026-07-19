import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../creator_models.dart';
import '../creator_session.dart';
import '../widgets/creator_widgets.dart';

class CreatorContentLibraryScreen extends StatelessWidget {
  const CreatorContentLibraryScreen({required this.session, super.key});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CreatorPageScaffold(
        session: session,
        title: 'Content Library',
        subtitle: 'Posts, Reels and YouTube connections',
        activeDock: 'studio',
        returnRoute: '/app/creator',
        trailing: IconButton.outlined(
          key: const Key('creator-library-add'),
          tooltip: 'Create content',
          onPressed: () => context.go('/app/creator/publish'),
          icon: const Icon(Icons.add_rounded),
        ),
        body: ListView(
          key: const Key('creator-content-library-screen'),
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
                  child: TextFormField(
                    key: const Key('creator-content-search'),
                    initialValue: session.contentQuery,
                    decoration: const InputDecoration(
                      labelText: 'Search content',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: session.setContentQuery,
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                IconButton.outlined(
                  key: const Key('creator-content-filter'),
                  tooltip: 'Content filters',
                  onPressed: () => _filterSheet(context),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CreatorContentTab.values
                    .map(
                      (tab) => Padding(
                        padding: const EdgeInsets.only(right: MoolSpacing.xs),
                        child: MoolSegment(
                          key: Key('creator-content-tab-${tab.name}'),
                          label: switch (tab) {
                            CreatorContentTab.published => 'Published',
                            CreatorContentTab.drafts => 'Drafts',
                            CreatorContentTab.scheduled => 'Scheduled',
                            CreatorContentTab.unavailable => 'Unavailable',
                          },
                          selected: session.contentTab == tab,
                          onPressed: () => session.setContentTab(tab),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            if (session.visibleContent.isEmpty)
              CreatorCard(
                keyName: 'creator-content-empty',
                color: const Color(0xFFF4F3FF),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 38,
                      color: MoolColors.navy,
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    const Text(
                      'No matching content',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const Text(
                      'Clear the search or choose another content state.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      key: const Key('creator-content-clear'),
                      onPressed: () => session.setContentQuery(''),
                      child: const Text('Clear Search'),
                    ),
                  ],
                ),
              )
            else
              ...session.visibleContent.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
                  child: CreatorActionRow(
                    keyName: 'creator-content-${item.id}',
                    icon: item.youtube
                        ? Icons.play_circle_outline_rounded
                        : item.format.contains('Reel')
                        ? Icons.movie_filter_outlined
                        : item.format.contains('Image')
                        ? Icons.image_outlined
                        : Icons.article_outlined,
                    title: item.title,
                    detail: '${item.format} · ${item.detail}',
                    meta: item.outcome,
                    action: item.status == 'Unavailable' ? 'Fix' : 'Open',
                    color: item.status == 'Unavailable'
                        ? const Color(0xFFFFEDEC)
                        : Colors.white,
                    onTap: () {
                      session.selectContent(item.id);
                      _contentSheet(context, item);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _filterSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('creator-content-filter-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter content',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const Text(
              'Every state stays attached to the same content record.',
            ),
            const SizedBox(height: MoolSpacing.md),
            for (final tab in CreatorContentTab.values)
              ListTile(
                key: Key('creator-content-filter-${tab.name}'),
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  session.contentTab == tab
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: MoolColors.navy,
                ),
                onTap: () {
                  session.setContentTab(tab);
                  Navigator.pop(sheetContext);
                },
                title: Text(switch (tab) {
                  CreatorContentTab.published => 'Published',
                  CreatorContentTab.drafts => 'Drafts',
                  CreatorContentTab.scheduled => 'Scheduled',
                  CreatorContentTab.unavailable => 'Unavailable or removed',
                }),
              ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('creator-content-filter-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _contentSheet(BuildContext context, CreatorContentItem item) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: SingleChildScrollView(
              child: Column(
                key: const Key('creator-content-detail-sheet'),
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
                  Text(item.format),
                  const SizedBox(height: MoolSpacing.md),
                  CreatorCard(
                    color: const Color(0xFFF4F3FF),
                    child: Column(
                      children: [
                        CreatorFact(label: 'Status', value: item.status),
                        CreatorFact(label: 'Availability', value: item.detail),
                        CreatorFact(label: 'Outcome', value: item.outcome),
                        CreatorFact(
                          label: 'Video host',
                          value: item.youtube ? 'YouTube' : 'MoolSocial',
                        ),
                        const CreatorFact(
                          label: 'Rights',
                          value: 'Confirmed for this content',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('creator-content-primary-action'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        if (item.status == 'Unavailable') {
                          context.go('/app/creator/youtube-connect');
                        } else if (item.status == 'Draft') {
                          context.go('/app/creator/publish');
                        } else {
                          context.go('/app/creator/performance');
                        }
                      },
                      child: Text(
                        item.status == 'Unavailable'
                            ? 'Replace YouTube Connection'
                            : item.status == 'Draft'
                            ? 'Continue Editing'
                            : 'Open Performance',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      key: const Key('creator-content-detail-close'),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class CreatorPerformanceScreen extends StatelessWidget {
  const CreatorPerformanceScreen({required this.session, super.key});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CreatorPageScaffold(
        session: session,
        title: 'Performance',
        subtitle: 'Attention, demand and verified outcomes',
        activeDock: 'studio',
        returnRoute: '/app/creator/content',
        trailing: IconButton.outlined(
          key: const Key('creator-performance-export'),
          tooltip: 'Export performance',
          onPressed: () => _exportSheet(context),
          icon: const Icon(Icons.download_rounded),
        ),
        body: ListView(
          key: const Key('creator-performance-screen'),
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: CreatorPerformanceWindow.values
                          .map(
                            (window) => Padding(
                              padding: const EdgeInsets.only(
                                right: MoolSpacing.xs,
                              ),
                              child: MoolSegment(
                                key: Key(
                                  'creator-performance-window-${window.name}',
                                ),
                                label: switch (window) {
                                  CreatorPerformanceWindow.sevenDays =>
                                    '7 days',
                                  CreatorPerformanceWindow.twentyEightDays =>
                                    '28 days',
                                  CreatorPerformanceWindow.ninetyDays =>
                                    '90 days',
                                },
                                selected: session.performanceWindow == window,
                                onPressed: () =>
                                    session.setPerformanceWindow(window),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: MoolSpacing.sm),
                SegmentedButton<CreatorPerformanceView>(
                  segments: const [
                    ButtonSegment(
                      value: CreatorPerformanceView.content,
                      label: Text('Content'),
                    ),
                    ButtonSegment(
                      value: CreatorPerformanceView.campaigns,
                      label: Text('Campaign'),
                    ),
                  ],
                  selected: {session.performanceView},
                  onSelectionChanged: (value) =>
                      session.setPerformanceView(value.first),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Row(
              children: [
                Expanded(
                  child: CreatorMetric(
                    label: 'REACH',
                    value: '1.28L',
                    detail: 'people',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CreatorMetric(
                    label: 'WATCH TIME',
                    value: '4.2K h',
                    detail: 'YouTube',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CreatorMetric(
                    label: 'ENGAGED',
                    value: '18.4K',
                    detail: 'actions',
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            const CreatorCard(child: _PerformanceChart()),
            const SizedBox(height: MoolSpacing.md),
            const CreatorSectionTitle(
              title: 'Verified value',
              detail: 'Attribution applied',
            ),
            const SizedBox(height: MoolSpacing.sm),
            const _ImpactGrid(),
            const SizedBox(height: MoolSpacing.md),
            CreatorActionRow(
              keyName: 'creator-performance-top-content',
              icon: Icons.insights_rounded,
              title: 'How local baskets save time',
              detail: '48.2K views · 126 paid orders',
              meta: '₹2,840 payable',
              action: 'Inspect',
              onTap: () => _topContentSheet(context),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const CreatorCard(
              color: Color(0xFFFFF6E8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.privacy_tip_outlined, color: Color(0xFFB05C00)),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Text(
                      'Reports use aggregated groups and minimum privacy thresholds. Private viewer identities and purchase histories are not shown.',
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

  Future<void> _exportSheet(BuildContext context) => showModalBottomSheet<void>(
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
              key: const Key('creator-export-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Export performance',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text('Download an aggregated creator report.'),
                const SizedBox(height: MoolSpacing.md),
                const CreatorCard(
                  color: Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      CreatorFact(label: 'Range', value: 'Selected period'),
                      CreatorFact(label: 'Privacy', value: 'Aggregated'),
                      CreatorFact(
                        label: 'Attribution',
                        value: 'Earning conditions included',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('creator-export-csv'),
                        onPressed: () => session.prepareExport('CSV'),
                        child: const Text('Prepare CSV'),
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    Expanded(
                      child: FilledButton(
                        key: const Key('creator-export-pdf'),
                        onPressed: () => session.prepareExport('PDF'),
                        child: const Text('Prepare PDF'),
                      ),
                    ),
                  ],
                ),
                if (session.exportId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: MoolSpacing.sm),
                    child: Text(
                      '${session.exportId} is ready.',
                      key: const Key('creator-export-ready'),
                      style: const TextStyle(
                        color: MoolColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('creator-export-close'),
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

  Future<void> _topContentSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: SingleChildScrollView(
              child: Column(
                key: const Key('creator-performance-detail-sheet'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How local baskets save time',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                  const Text('Connected YouTube Short · CR-2048'),
                  const SizedBox(height: MoolSpacing.md),
                  const CreatorFact(label: 'Reached', value: '48,200'),
                  const CreatorFact(label: 'Demand actions', value: '1,206'),
                  const CreatorFact(label: 'Paid orders', value: '126'),
                  const CreatorFact(
                    label: 'Attributed value',
                    value: '₹48,620',
                  ),
                  const CreatorFact(label: 'Creator payable', value: '₹2,840'),
                  const SizedBox(height: MoolSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('creator-performance-detail-close'),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class CreatorAudienceScreen extends StatelessWidget {
  const CreatorAudienceScreen({required this.session, super.key});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) {
    return CreatorPageScaffold(
      session: session,
      title: 'Audience & Community',
      subtitle: 'Aggregated people, interests and demand',
      activeDock: 'studio',
      returnRoute: '/app/creator',
      trailing: IconButton.outlined(
        key: const Key('creator-audience-invite'),
        tooltip: 'Invite followers',
        onPressed: () => _inviteSheet(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: ListView(
        key: const Key('creator-audience-screen'),
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
                  'FOLLOWERS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '84,260',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '+8.4% this month · 62% returning viewers',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Row(
            children: [
              Expanded(
                child: CreatorMetric(
                  label: 'RETURNING',
                  value: '52.4K',
                  detail: 'viewers',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: CreatorMetric(
                  label: 'ENGAGED',
                  value: '18.4K',
                  detail: 'people',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: CreatorMetric(
                  label: 'PURCHASE INTEREST',
                  value: '6.2K',
                  detail: 'verified',
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.md),
          const CreatorSectionTitle(
            title: 'Audience geography',
            detail: 'Minimum group sizes applied',
          ),
          const SizedBox(height: MoolSpacing.sm),
          const CreatorCard(
            child: Column(
              children: [
                _AudienceBar(label: 'Jodhpur', value: .38, detail: '38%'),
                _AudienceBar(label: 'Jaipur', value: .21, detail: '21%'),
                _AudienceBar(label: 'Rajasthan', value: .29, detail: '29%'),
                _AudienceBar(label: 'Other India', value: .12, detail: '12%'),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          const CreatorSectionTitle(
            title: 'Top interests',
            detail: 'Aggregated',
          ),
          const SizedBox(height: MoolSpacing.sm),
          const CreatorCard(
            child: Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: [
                CreatorPill(label: 'Daily needs · 42%'),
                CreatorPill(label: 'Local food · 31%'),
                CreatorPill(label: 'Small business · 18%'),
                CreatorPill(label: 'Mobility · 9%'),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          const CreatorSectionTitle(
            title: 'Community',
            detail: 'Actions you can complete',
          ),
          const SizedBox(height: MoolSpacing.sm),
          CreatorActionRow(
            keyName: 'creator-audience-ask',
            icon: Icons.poll_outlined,
            title: 'Ask your audience',
            detail: 'Create a post, poll or demand question',
            meta: 'Build a verified demand signal',
            action: 'Create',
            onTap: () => context.go('/app/social?sub=create'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          CreatorActionRow(
            keyName: 'creator-audience-comments',
            icon: Icons.forum_outlined,
            title: '326 comments need attention',
            detail: 'Helpful, questions and held-for-review',
            meta: 'Open community replies',
            action: 'Reply',
            onTap: () =>
                context.go('/app/chat/inbox?return=/app/creator/audience'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          CreatorActionRow(
            keyName: 'creator-audience-share',
            icon: Icons.link_rounded,
            title: 'Invite existing followers',
            detail: 'Share your public MoolSocial channel link',
            meta: 'No password or contact import',
            action: 'Share',
            onTap: () => _inviteSheet(context),
          ),
          const SizedBox(height: MoolSpacing.xs),
          CreatorActionRow(
            keyName: 'creator-audience-memberships',
            icon: Icons.workspace_premium_outlined,
            title: 'Memberships',
            detail: 'Monthly and yearly member plans',
            meta: 'Take-home shown before activation',
            action: 'Manage',
            onTap: () => context.go('/app/creator/audience?tab=memberships'),
          ),
          const SizedBox(height: MoolSpacing.md),
          const CreatorCard(
            color: Color(0xFFFFF6E8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip_outlined, color: Color(0xFFB05C00)),
                SizedBox(width: MoolSpacing.sm),
                Expanded(
                  child: Text(
                    'Small groups, sensitive attributes, private viewer identities and individual purchase histories stay hidden.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            key: const Key('creator-audience-invite-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invite to your channel',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const Text(
                'Share a public link without importing private contacts.',
              ),
              const SizedBox(height: MoolSpacing.md),
              const CreatorCard(
                color: Color(0xFFF4F3FF),
                child: Column(
                  children: [
                    CreatorFact(label: 'Channel', value: '@JodhpurDaily'),
                    CreatorFact(label: 'Link', value: 'mool.social/jd'),
                    CreatorFact(label: 'QR', value: 'Available'),
                    CreatorFact(label: 'Attribution', value: 'Invite source'),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('creator-audience-share-confirm'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    session.showNotice(
                      'Channel share options are ready. No contacts were imported.',
                    );
                  },
                  child: const Text('Share Channel'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('creator-audience-share-close'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PerformanceChart extends StatelessWidget {
  const _PerformanceChart();

  @override
  Widget build(BuildContext context) {
    const values = [.42, .67, .53, .79, .72, .91, 1.0];
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SizedBox(
      height: 165,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verified value trend',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const Text(
            'Outcomes, not views alone',
            style: TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < values.length; index += 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: values[index],
                              child: Container(
                                decoration: BoxDecoration(
                                  color: index == values.length - 1
                                      ? MoolColors.navy
                                      : MoolColors.royal.withValues(alpha: .45),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[index],
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

class _ImpactGrid extends StatelessWidget {
  const _ImpactGrid();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Row(
        children: [
          Expanded(
            child: CreatorMetric(
              label: 'DEMAND STARTED',
              value: '1,206',
              detail: 'people',
            ),
          ),
          SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: CreatorMetric(
              label: 'INFORMED',
              value: '684',
              detail: 'actions',
            ),
          ),
          SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: CreatorMetric(label: 'ORDERS', value: '126', detail: 'paid'),
          ),
        ],
      ),
      SizedBox(height: MoolSpacing.xs),
      Row(
        children: [
          Expanded(
            child: CreatorMetric(
              label: 'BOOKINGS',
              value: '38',
              detail: 'completed',
            ),
          ),
          SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: CreatorMetric(
              label: 'VALUE',
              value: '₹48.6K',
              detail: 'attributed',
            ),
          ),
          SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: CreatorMetric(
              label: 'PAYABLE',
              value: '₹8,940',
              detail: 'verified',
            ),
          ),
        ],
      ),
    ],
  );
}

class _AudienceBar extends StatelessWidget {
  const _AudienceBar({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final double value;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
    child: Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MoolRadii.capsule),
            child: LinearProgressIndicator(value: value, minHeight: 8),
          ),
        ),
        const SizedBox(width: MoolSpacing.xs),
        SizedBox(
          width: 34,
          child: Text(
            detail,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}
