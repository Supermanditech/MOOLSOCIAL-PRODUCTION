import 'package:flutter/material.dart';

import '../../../../core/design/mool_design_system.dart';
import '../../../../core/design/mool_theme.dart';
import '../universal_intent_catalog.dart';

Future<void> showIntentCompletionSheet(
  BuildContext context,
  UniversalIntentSpec spec,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _IntentCompletionSheet(spec: spec),
  );
}

class _IntentCompletionSheet extends StatefulWidget {
  const _IntentCompletionSheet({required this.spec});

  final UniversalIntentSpec spec;

  @override
  State<_IntentCompletionSheet> createState() => _IntentCompletionSheetState();
}

class _IntentCompletionSheetState extends State<_IntentCompletionSheet> {
  IntentOption? _selected;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    return AnimatedPadding(
      duration: MoolMotion.accessible(context, MoolMotion.standard),
      padding: EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.xs,
        MoolSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
      ),
      child: AnimatedSwitcher(
        duration: MoolMotion.accessible(context, MoolMotion.standard),
        child: _completed
            ? _CompletionResult(
                key: const ValueKey('completed'),
                spec: spec,
                onDone: () => Navigator.pop(context),
              )
            : _selected == null
            ? _ChoiceStep(
                key: const ValueKey('choose'),
                spec: spec,
                onSelected: (value) => setState(() => _selected = value),
              )
            : _ReviewStep(
                key: const ValueKey('review'),
                spec: spec,
                selected: _selected!,
                onBack: () => setState(() => _selected = null),
                onConfirm: () => setState(() => _completed = true),
              ),
      ),
    );
  }
}

class _SheetHeading extends StatelessWidget {
  const _SheetHeading({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0x16138808),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: MoolColors.success),
        ),
        const SizedBox(height: MoolSpacing.md),
        Text(
          title,
          style: const TextStyle(
            color: MoolColors.navy,
            fontSize: 24,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        Text(
          description,
          style: const TextStyle(
            color: MoolColors.muted,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  const _ChoiceStep({required this.spec, required this.onSelected, super.key});

  final UniversalIntentSpec spec;
  final ValueChanged<IntentOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeading(
          icon: spec.icon,
          title: spec.choicePrompt,
          description: spec.description,
        ),
        const SizedBox(height: MoolSpacing.lg),
        ...List.generate(spec.options.length, (index) {
          final option = spec.options[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
            child: Semantics(
              button: true,
              label: '${option.label}. ${option.detail}',
              child: Material(
                color: const Color(0xFFF5F6FC),
                borderRadius: BorderRadius.circular(MoolRadii.card),
                child: InkWell(
                  key: Key('intent-option-${spec.id}-$index'),
                  onTap: () => onSelected(option),
                  borderRadius: BorderRadius.circular(MoolRadii.card),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 68),
                    child: Padding(
                      padding: const EdgeInsets.all(MoolSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  option.label,
                                  style: const TextStyle(
                                    color: MoolColors.navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: MoolSpacing.xxs),
                                Text(
                                  option.detail,
                                  style: const TextStyle(
                                    color: MoolColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: MoolColors.navy,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        TextButton(
          key: Key('intent-cancel-${spec.id}'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.spec,
    required this.selected,
    required this.onBack,
    required this.onConfirm,
    super.key,
  });

  final UniversalIntentSpec spec;
  final IntentOption selected;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeading(
          icon: spec.icon,
          title: selected.label,
          description: selected.detail,
        ),
        const SizedBox(height: MoolSpacing.lg),
        Wrap(
          spacing: MoolSpacing.xs,
          runSpacing: MoolSpacing.xs,
          children: spec.facts
              .map(
                (fact) => Chip(
                  avatar: const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: MoolColors.success,
                  ),
                  label: Text(fact),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: MoolSpacing.lg),
        FilledButton(
          key: Key('intent-confirm-${spec.id}'),
          onPressed: onConfirm,
          style: FilledButton.styleFrom(backgroundColor: MoolColors.navy),
          child: Text(spec.confirmAction),
        ),
        TextButton(
          key: Key('intent-back-${spec.id}'),
          onPressed: onBack,
          child: const Text('Choose another option'),
        ),
      ],
    );
  }
}

class _CompletionResult extends StatelessWidget {
  const _CompletionResult({
    required this.spec,
    required this.onDone,
    super.key,
  });

  final UniversalIntentSpec spec;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '${spec.resultTitle}. ${spec.resultDescription}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: MoolColors.success,
            size: 64,
          ),
          const SizedBox(height: MoolSpacing.md),
          Text(
            spec.resultTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            spec.resultDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: MoolSpacing.lg),
          FilledButton(
            key: Key('intent-done-${spec.id}'),
            onPressed: onDone,
            style: FilledButton.styleFrom(backgroundColor: MoolColors.navy),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
