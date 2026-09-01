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
    super.key,
  });

  final WorkProfileOption option;
  final WorkWorkspaceBenefitContent content;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
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
  });

  final WorkProfileOption option;
  final WorkWorkspaceBenefitContent content;
  final _WorkspacePresentation presentation;
  final VoidCallback onChoose;
  final VoidCallback onClose;

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
          label: const Text(
            'Choose this Workspace',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
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
