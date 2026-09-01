import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../work_models.dart';
import 'work_filter_sheet_motion.dart';

@immutable
class WorkOpportunityFilterSelection {
  const WorkOpportunityFilterSelection({
    required this.type,
    required this.city,
    required this.area,
    required this.pincode,
  });

  final WorkFeedFilter type;
  final String city;
  final String area;
  final String pincode;

  int get activeCount =>
      (type == WorkFeedFilter.forYou ? 0 : 1) +
      (city.isEmpty ? 0 : 1) +
      (area.isEmpty ? 0 : 1) +
      (pincode.isEmpty ? 0 : 1);
}

Future<WorkOpportunityFilterSelection?> showWorkOpportunityFilterSheet(
  BuildContext context, {
  required WorkOpportunityFilterSelection initial,
  required List<String> cities,
}) {
  final area = TextEditingController(text: initial.area);
  final pincode = TextEditingController(text: initial.pincode);
  var type = initial.type;
  var city = initial.city;

  return showModalBottomSheet<WorkOpportunityFilterSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: WorkFilterSheetMotion.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: WorkFilterSheetMotion.resolve(context),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => AnimatedPadding(
        duration:
            WorkFilterSheetMotion.resolve(sheetContext).duration ??
            Duration.zero,
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: WorkFilterSheetMotion.initialChildSize,
          minChildSize: WorkFilterSheetMotion.minChildSize,
          maxChildSize: WorkFilterSheetMotion.maxChildSize,
          builder: (sheetContext, controller) => SafeArea(
            top: false,
            child: Semantics(
              key: const Key('work-filter-sheet-route'),
              container: true,
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: 'Work filters',
              child: ListView(
                key: const Key('work-filter-scroll'),
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filter paid work',
                              style: TextStyle(
                                color: MoolColors.ink,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Choose work type and an exact location.',
                              style: TextStyle(
                                color: MoolColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        key: const Key('work-filter-close'),
                        tooltip: 'Close filters',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          maximumSize: const Size(44, 44),
                          foregroundColor: MoolColors.navy,
                          backgroundColor: const Color(0xFFEDEEFF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MoolSpacing.md),
                  const Text(
                    'Location',
                    style: TextStyle(
                      color: MoolColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  DropdownButtonFormField<String>(
                    key: const Key('work-filter-city'),
                    initialValue: city.isEmpty ? '' : city,
                    decoration: const InputDecoration(labelText: 'City'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Any city'),
                      ),
                      for (final value in cities)
                        DropdownMenuItem(value: value, child: Text(value)),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => city = value ?? ''),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  TextField(
                    key: const Key('work-filter-area'),
                    controller: area,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Area or locality',
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  TextField(
                    key: const Key('work-filter-pincode'),
                    controller: pincode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: '6-digit pincode',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.md),
                  const Text(
                    'Work type',
                    style: TextStyle(
                      color: MoolColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  for (final value in WorkFeedFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
                      child: _WorkFilterOption(
                        value: value,
                        selected: type == value,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => type = value);
                        },
                      ),
                    ),
                  const SizedBox(height: MoolSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('work-filter-clear'),
                          onPressed: () {
                            area.clear();
                            pincode.clear();
                            setSheetState(() {
                              type = WorkFeedFilter.forYou;
                              city = '';
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: MoolSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          key: const Key('work-filter-apply'),
                          onPressed: () => Navigator.of(sheetContext).pop(
                            WorkOpportunityFilterSelection(
                              type: type,
                              city: city.trim(),
                              area: area.text.trim(),
                              pincode: pincode.text.trim(),
                            ),
                          ),
                          child: const Text('Show paid work'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _WorkFilterOption extends StatelessWidget {
  const _WorkFilterOption({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final WorkFeedFilter value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = value == WorkFeedFilter.forYou
        ? 'All paid work'
        : value.label;
    final detail = switch (value) {
      WorkFeedFilter.forYou => 'Jobs, freelance assignments and funded tasks',
      WorkFeedFilter.jobs => 'Monthly paid positions and ongoing roles',
      WorkFeedFilter.freelance => 'Hourly and assignment-based work',
      WorkFeedFilter.campaigns => 'Funded content and growth requirements',
      WorkFeedFilter.nearby => 'Work tied to a city, area or pincode',
    };
    return Semantics(
      key: ValueKey('work-filter-semantics-${value.name}'),
      button: true,
      selected: selected,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? const Color(0xFFEDEEFF) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoolRadii.control),
          side: BorderSide(
            color: selected ? MoolColors.navy : const Color(0xFFE1E3EC),
          ),
        ),
        child: InkWell(
          key: ValueKey('work-filter-${value.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(MoolRadii.control),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MoolSpacing.sm,
                vertical: MoolSpacing.xs,
              ),
              child: Row(
                children: [
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
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? MoolColors.navy : MoolColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
