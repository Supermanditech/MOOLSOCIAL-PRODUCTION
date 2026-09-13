import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../work_models.dart';
import '../work_workspace_benefits.dart';
import 'work_widgets.dart';

class WorkWorkspaceBenefitCard extends StatelessWidget {
  const WorkWorkspaceBenefitCard({
    required this.option,
    required this.content,
    required this.expanded,
    required this.onToggle,
    required this.onChoose,
    this.showChooseAction = true,
    this.resumeApplication = false,
    super.key,
  });

  final WorkProfileOption option;
  final WorkWorkspaceBenefitContent content;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onChoose;
  final bool showChooseAction;
  final bool resumeApplication;

  @override
  Widget build(BuildContext context) {
    if (content.hasTopics) {
      return _WorkspaceGrowthCard(key: ValueKey(option.id), card: this);
    }
    final presentation = _workspacePresentation(option.familyId);
    return WorkCard(
      keyName: 'work-profile-${option.id}',
      onTap: expanded ? null : onToggle,
      color: expanded ? presentation.tint : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: expanded
                    ? presentation.accent
                    : presentation.tint,
                foregroundColor: expanded ? Colors.white : presentation.accent,
                child: Icon(option.icon),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (expanded)
                      Text(
                        'What MoolSocial can do for you',
                        style: TextStyle(
                          color: presentation.accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: MoolMotion.accessible(context, MoolMotion.deliberate),
            curve: MoolMotion.enter,
            alignment: Alignment.topCenter,
            child: expanded
                ? _ExpandedBenefits(
                    option: option,
                    content: content,
                    presentation: presentation,
                    onChoose: onChoose,
                    onClose: onToggle,
                    resumeApplication: resumeApplication,
                  )
                : _CompactBenefits(
                    option: option,
                    content: content,
                    accent: presentation.accent,
                  ),
          ),
        ],
      ),
    );
  }
}

class WorkWorkspaceChooseButton extends StatelessWidget {
  const WorkWorkspaceChooseButton({
    required this.profileId,
    required this.onChoose,
    this.showNextStep = true,
    this.resumeApplication = false,
    super.key,
  });
  final String profileId;
  final VoidCallback onChoose;
  final bool showNextStep;
  final bool resumeApplication;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      FilledButton(
        key: Key('work-profile-choose-$profileId'),
        onPressed: onChoose,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          backgroundColor: MoolColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          resumeApplication ? 'View application' : 'Choose this Workspace',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      if (showNextStep && !resumeApplication) ...[
        const SizedBox(height: 6),
        const _WorkspaceNextStep(),
      ],
    ],
  );
}

class _WorkspaceNextStep extends StatelessWidget {
  const _WorkspaceNextStep();
  @override
  Widget build(BuildContext context) => const Text(
    'Documents come next. No payment here.',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 11, color: MoolColors.muted),
  );
}

class _WorkspaceGrowthCard extends StatefulWidget {
  const _WorkspaceGrowthCard({required this.card, super.key});
  final WorkWorkspaceBenefitCard card;

  @override
  State<_WorkspaceGrowthCard> createState() => _WorkspaceGrowthCardState();
}

class _WorkspaceGrowthCardState extends State<_WorkspaceGrowthCard> {
  String _topic = workWorkspaceGrowthTopics.first;
  int _page = 0;
  int? _detail = 0;

  @override
  void didUpdateWidget(_WorkspaceGrowthCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.card.expanded && oldWidget.card.expanded) {
      _topic = workWorkspaceGrowthTopics.first;
      _page = 0;
      _detail = 0;
    }
  }

  void _showTopic(String topic) => setState(() {
    _topic = topic;
    _page = 0;
    _detail = 0;
  });

  void _showPage(int page) => setState(() {
    _page = page;
    _detail = 0;
  });

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final compactHeading = MediaQuery.textScalerOf(context).scale(14) > 18;
    final items = card.content.benefits
        .where((point) => point.group == _topic)
        .toList();
    final start = _page * 3;
    final visible = items.skip(start).take(3).toList();
    final radius = BorderRadius.circular(16);
    if (!card.expanded) {
      return Material(
        key: Key('work-profile-${card.option.id}'),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: Color(0xFFE2E5F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: card.onToggle,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(card.option.icon, color: MoolColors.navy, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        card.option.label,
                        style: const TextStyle(
                          color: MoolColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  card.content.preview,
                  key: Key('workspace-benefit-preview-${card.option.id}'),
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'See how MoolSocial helps',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      key: Key('work-profile-${card.option.id}'),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: Color(0xFFD9DEEE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        key: Key('workspace-benefits-${card.option.id}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: MoolColors.navy,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
              child: Row(
                children: [
                  if (!compactHeading) ...[
                    Icon(card.option.icon, size: 25, color: Colors.white),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.option.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!compactHeading) ...[
                          const SizedBox(height: 4),
                          Text(
                            card.content.subtitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key('work-profile-close-${card.option.id}'),
                    tooltip: 'Close details',
                    onPressed: card.onToggle,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final large = MediaQuery.textScalerOf(context).scale(13) > 17;
                final columns = large || constraints.maxWidth < 290 ? 2 : 4;
                return Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    for (final topic in workWorkspaceGrowthTopics)
                      SizedBox(
                        width: large ? null : constraints.maxWidth / columns,
                        child: Semantics(
                          selected: _topic == topic,
                          child: TextButton(
                            key: Key('work-growth-group-$topic'),
                            onPressed: _topic == topic
                                ? null
                                : () => _showTopic(topic),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(44, 44),
                              padding: EdgeInsets.symmetric(
                                horizontal: large ? 8 : 2,
                                vertical: 10,
                              ),
                              foregroundColor: MoolColors.muted,
                              disabledForegroundColor: MoolColors.navy,
                              backgroundColor: _topic == topic
                                  ? const Color(0xFFF0F2FD)
                                  : Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              topic,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E5F0)),
          for (var index = 0; index < visible.length; index++) ...[
            Semantics(
              button: true,
              expanded: _detail == index,
              child: InkWell(
                key: Key('work-growth-concern-${visible[index].action}'),
                onTap: () =>
                    setState(() => _detail = _detail == index ? null : index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visible[index].title,
                              style: const TextStyle(
                                color: MoolColors.ink,
                                fontSize: 14,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              visible[index].action,
                              key: Key(
                                'work-growth-action-${visible[index].action}',
                              ),
                              style: const TextStyle(
                                color: MoolColors.navy,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _detail == index ? Icons.remove : Icons.add,
                        size: 18,
                        color: MoolColors.navy,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              key: Key('work-growth-disclosure-${visible[index].action}'),
              alignment: Alignment.topCenter,
              duration: MoolMotion.accessible(context, MoolMotion.standard),
              curve: MoolMotion.enter,
              child: _detail != index
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 36, 12),
                      child: Text(
                        visible[index].detail,
                        style: const TextStyle(
                          color: MoolColors.muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E5F0)),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  key: const Key('work-growth-previous'),
                  tooltip: 'Previous points',
                  onPressed: _page == 0 ? null : () => _showPage(_page - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${start + 1}–${start + visible.length} of ${items.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MoolColors.muted,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('work-growth-next'),
                  tooltip: 'More points',
                  onPressed: start + visible.length >= items.length
                      ? null
                      : () => _showPage(_page + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          if (card.showChooseAction)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: WorkWorkspaceChooseButton(
                profileId: card.option.id,
                onChoose: card.onChoose,
                resumeApplication: card.resumeApplication,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _WorkspaceNextStep(),
            ),
        ],
      ),
    );
  }
}

class _CompactBenefits extends StatelessWidget {
  const _CompactBenefits({
    required this.option,
    required this.content,
    required this.accent,
  });

  final WorkProfileOption option;
  final WorkWorkspaceBenefitContent content;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: MoolSpacing.xs),
        Text(
          content.preview,
          key: Key('workspace-benefit-preview-${option.id}'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: MoolColors.ink,
            fontSize: 10.5,
            height: 1.28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: _AttentionCue(accent: accent),
        ),
      ],
    );
  }
}

class _ExpandedBenefits extends StatelessWidget {
  const _ExpandedBenefits({
    required this.option,
    required this.content,
    required this.presentation,
    required this.onChoose,
    required this.onClose,
    required this.resumeApplication,
  });

  final WorkProfileOption option;
  final WorkWorkspaceBenefitContent content;
  final _WorkspacePresentation presentation;
  final VoidCallback onChoose;
  final VoidCallback onClose;
  final bool resumeApplication;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('workspace-benefits-${option.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: MoolSpacing.lg),
        Container(
          padding: const EdgeInsets.all(MoolSpacing.sm),
          decoration: BoxDecoration(
            color: presentation.accent,
            borderRadius: BorderRadius.circular(MoolRadii.control),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.white, size: 21),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Text(
                  content.problem,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.sm),
        const Text(
          'What changes with MoolSocial',
          style: TextStyle(
            color: MoolColors.navy,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        for (var index = 0; index < content.benefits.length; index += 1) ...[
          _BenefitTile(
            index: index,
            benefit: content.benefits[index],
            accent: presentation.accent,
          ),
          if (index < content.benefits.length - 1)
            const SizedBox(height: MoolSpacing.xs),
        ],
        const SizedBox(height: MoolSpacing.sm),
        Container(
          padding: const EdgeInsets.all(MoolSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(MoolRadii.control),
            border: Border.all(
              color: presentation.accent.withValues(alpha: .24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why this is different',
                style: TextStyle(
                  color: presentation.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                content.difference,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 11,
                  height: 1.32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.sm),
        FilledButton.icon(
          key: Key('work-profile-choose-${option.id}'),
          onPressed: onChoose,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: MoolColors.navy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MoolRadii.control),
              side: BorderSide(color: presentation.accent, width: 2),
            ),
          ),
          icon: const Icon(Icons.workspace_premium_outlined),
          label: Text(
            resumeApplication ? 'View application' : 'Choose this Workspace',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        if (!resumeApplication) ...[
          const SizedBox(height: 4),
          const Text(
            'Next: review the documents needed to verify this Workspace.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MoolColors.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 2),
        TextButton(
          key: Key('work-profile-close-${option.id}'),
          onPressed: onClose,
          child: const Text('Show fewer details'),
        ),
      ],
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.index,
    required this.benefit,
    required this.accent,
  });

  final int index;
  final WorkWorkspaceBenefit benefit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const icons = <IconData>[
      Icons.people_alt_outlined,
      Icons.local_shipping_outlined,
      Icons.fact_check_outlined,
      Icons.payments_outlined,
    ];
    return Container(
      padding: const EdgeInsets.all(MoolSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MoolRadii.control),
        border: Border.all(color: accent.withValues(alpha: .16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: accent.withValues(alpha: .1),
            foregroundColor: accent,
            child: Icon(icons[index % icons.length], size: 18),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  benefit.detail,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10,
                    height: 1.3,
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

class _AttentionCue extends StatefulWidget {
  const _AttentionCue({required this.accent});

  final Color accent;

  @override
  State<_AttentionCue> createState() => _AttentionCueState();
}

class _AttentionCueState extends State<_AttentionCue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
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
    final motion = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: .72, end: 1).animate(motion),
      child: ScaleTransition(
        scale: Tween<double>(begin: .98, end: 1).animate(motion),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(MoolRadii.capsule),
            border: Border.all(color: widget.accent.withValues(alpha: .25)),
          ),
          child: Text(
            'See how MoolSocial helps',
            style: TextStyle(
              color: widget.accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspacePresentation {
  const _WorkspacePresentation({required this.accent, required this.tint});

  final Color accent;
  final Color tint;
}

_WorkspacePresentation _workspacePresentation(String familyId) =>
    switch (familyId) {
      'products-trade' => const _WorkspacePresentation(
        accent: Color(0xFF0047AB),
        tint: Color(0xFFEAF2FF),
      ),
      'food-business' => const _WorkspacePresentation(
        accent: Color(0xFFA65A00),
        tint: Color(0xFFFFF4E5),
      ),
      'health' => const _WorkspacePresentation(
        accent: Color(0xFF007A4D),
        tint: Color(0xFFE8F7F0),
      ),
      'services' => const _WorkspacePresentation(
        accent: Color(0xFF9C1C6B),
        tint: Color(0xFFFFEDF7),
      ),
      'travel' => const _WorkspacePresentation(
        accent: Color(0xFF006D77),
        tint: Color(0xFFE8F7F8),
      ),
      'delivery' => const _WorkspacePresentation(
        accent: Color(0xFFB54708),
        tint: Color(0xFFFFF1E7),
      ),
      _ => const _WorkspacePresentation(
        accent: Color(0xFF5B21B6),
        tint: Color(0xFFF2EDFF),
      ),
    };
