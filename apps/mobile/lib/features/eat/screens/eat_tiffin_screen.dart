import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../eat_models.dart';
import '../eat_session.dart';
import '../widgets/eat_widgets.dart';

class EatTiffinScreen extends StatelessWidget {
  const EatTiffinScreen({required this.session, super.key});

  final EatSession session;

  static const foodStyles = <String, List<String>>{
    'Regular veg': [
      'Dal · roti · rice',
      'Paneer · salad',
      'Rajma · jeera rice',
      'Veg pulao · curd',
    ],
    'Jain': [
      'Dal · phulka · rice',
      'Paneer · roti',
      'Kadhi · rice',
      'Sabzi · khichdi',
    ],
    'High protein': [
      'Paneer bowl',
      'Dal protein thali',
      'Chana rice',
      'Sprout salad meal',
    ],
    'Rajasthani': ['Dal bati', 'Gatte · roti', 'Ker sangri', 'Kadhi · rice'],
    'Diet': ['Less-oil thali', 'Millet roti', 'Salad · dal', 'Khichdi · curd'],
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final kitchen = session.selectedKitchen;
        final menu = foodStyles[session.foodStyle]!;
        return EatPageScaffold(
          key: const Key('eat-tiffin-screen'),
          session: session,
          title: 'Tiffin plans',
          subtitle: 'Trial, weekly or monthly daily meals',
          activeDock: 'tiffin',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xxl,
            ),
            children: [
              const Text(
                'Choose a kitchen',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              SizedBox(
                height: 142,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: EatSession.tiffinKitchens.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: MoolSpacing.xs),
                  itemBuilder: (context, index) {
                    final item = EatSession.tiffinKitchens[index];
                    final selected = session.selectedKitchenId == item.id;
                    return SizedBox(
                      width: 186,
                      child: Material(
                        color: selected
                            ? const Color(0xFFEDEEFF)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: selected
                                ? MoolColors.navy
                                : const Color(0x22000080),
                          ),
                          borderRadius: BorderRadius.circular(MoolRadii.card),
                        ),
                        child: InkWell(
                          key: Key('eat-tiffin-kitchen-${item.id}'),
                          onTap: () => session.selectTiffinKitchen(item.id),
                          borderRadius: BorderRadius.circular(MoolRadii.card),
                          child: Padding(
                            padding: const EdgeInsets.all(MoolSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFE1F3DE),
                                      foregroundColor: MoolColors.navy,
                                      child: Text(
                                        item.name
                                            .split(' ')
                                            .map((part) => part[0])
                                            .take(2)
                                            .join(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      selected
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      color: selected
                                          ? MoolColors.success
                                          : MoolColors.muted,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: MoolColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  item.available
                                      ? '${item.detail} · ${item.distance}'
                                      : 'New plans paused',
                                  style: TextStyle(
                                    color: item.available
                                        ? MoolColors.muted
                                        : const Color(0xFFB42318),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  item.available
                                      ? 'Trial ${eatMoney(item.trialPrice)}'
                                      : 'Choose another kitchen',
                                  style: TextStyle(
                                    color: item.available
                                        ? MoolColors.success
                                        : const Color(0xFFB42318),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              _MealChoices(session: session, foodStyles: foodStyles),
              const SizedBox(height: MoolSpacing.sm),
              _PlanChoices(session: session),
              const SizedBox(height: MoolSpacing.sm),
              EatSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Menu calendar',
                            style: TextStyle(
                              color: MoolColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          session.foodStyle,
                          style: const TextStyle(
                            color: MoolColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: MoolSpacing.xs,
                            crossAxisSpacing: MoolSpacing.xs,
                            childAspectRatio: 2.25,
                          ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final day = const ['Mon', 'Tue', 'Wed', 'Thu'][index];
                        return Container(
                          padding: const EdgeInsets.all(MoolSpacing.sm),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FC),
                            borderRadius: BorderRadius.circular(
                              MoolRadii.control,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day,
                                style: const TextStyle(
                                  color: MoolColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                menu[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: MoolColors.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              EatSurfaceCard(
                color: const Color(0xFFEDEEFF),
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
                                '${kitchen.name} · ${session.foodStyle} ${session.tiffinMeal.label}',
                                style: const TextStyle(
                                  color: MoolColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${session.tiffinMeal.count} · ${session.tiffinSlot} · ${kitchen.trust}',
                                style: const TextStyle(
                                  color: MoolColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          eatMoney(session.tiffinPrice),
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    EatTrustStrip(
                      items: [
                        ('Pause', kitchen.pauseRule),
                        ('Trial', eatMoney(kitchen.trialPrice)),
                        ('Cancel', 'before next cycle'),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.tiffinAddress,
                            style: const TextStyle(
                              color: MoolColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        TextButton(
                          key: const Key('eat-tiffin-change-address'),
                          onPressed: () => _editTiffinAddress(context, session),
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              const EatSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily meal control',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: MoolSpacing.xs),
                    EatTrustStrip(
                      items: [
                        ('Address', 'home, office or hostel'),
                        ('Skip', 'before kitchen cutoff'),
                        ('Diet', 'saved with every meal'),
                        ('Bill', 'weekly or monthly receipt'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomAction: FilledButton(
            key: const Key('eat-start-tiffin'),
            onPressed: session.busy
                ? null
                : () async {
                    final started = await session.startTiffin();
                    if (started && context.mounted) {
                      context.go(
                        '/app/eat/tiffin/${session.tiffinReceipt!.id}',
                      );
                    }
                  },
            child: session.busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    '${_startLabel(session.tiffinPlan)} · ${eatMoney(session.tiffinPrice)}',
                  ),
          ),
        );
      },
    );
  }
}

class _MealChoices extends StatelessWidget {
  const _MealChoices({required this.session, required this.foodStyles});

  final EatSession session;
  final Map<String, List<String>> foodStyles;

  @override
  Widget build(BuildContext context) {
    return EatSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose food',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Text(
            'Food style',
            style: TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
          Wrap(
            spacing: MoolSpacing.xs,
            runSpacing: MoolSpacing.xs,
            children: foodStyles.keys
                .map(
                  (value) => ChoiceChip(
                    key: Key(
                      'eat-tiffin-style-${value.replaceAll(' ', '-').toLowerCase()}',
                    ),
                    label: Text(value),
                    selected: session.foodStyle == value,
                    onSelected: (_) => session.chooseFoodStyle(value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Text(
            'Meal',
            style: TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
          Wrap(
            spacing: MoolSpacing.xs,
            runSpacing: MoolSpacing.xs,
            children: TiffinMeal.values
                .map(
                  (value) => ChoiceChip(
                    key: Key('eat-tiffin-meal-${value.name}'),
                    label: Text(value.label),
                    selected: session.tiffinMeal == value,
                    onSelected: (_) => session.chooseTiffinMeal(value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Text(
            'Delivery slot',
            style: TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
          Wrap(
            spacing: MoolSpacing.xs,
            runSpacing: MoolSpacing.xs,
            children: ['12:30 PM', '1:15 PM', '8:00 PM', 'Office route']
                .map(
                  (value) => ChoiceChip(
                    key: Key(
                      'eat-tiffin-slot-${value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}',
                    ),
                    label: Text(value),
                    selected: session.tiffinSlot == value,
                    onSelected: (_) => session.chooseTiffinSlot(value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PlanChoices extends StatelessWidget {
  const _PlanChoices({required this.session});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    return EatSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a plan',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          for (final plan in TiffinPlan.values)
            Padding(
              padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
              child: Material(
                color: session.tiffinPlan == plan
                    ? const Color(0xFFEDEEFF)
                    : const Color(0xFFF5F6FC),
                borderRadius: BorderRadius.circular(MoolRadii.control),
                child: InkWell(
                  key: Key('eat-tiffin-plan-${plan.name}'),
                  onTap: () => session.chooseTiffinPlan(plan),
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: MoolMetrics.minimumTapTarget,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(MoolSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.label,
                                  style: const TextStyle(
                                    color: MoolColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  switch (plan) {
                                    TiffinPlan.trial =>
                                      'One meal today · no lock-in',
                                    TiffinPlan.weekly =>
                                      '6 meals · pause next week',
                                    TiffinPlan.monthly =>
                                      '26 meals · skip allowed',
                                  },
                                  style: const TextStyle(
                                    color: MoolColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            eatMoney(switch (plan) {
                              TiffinPlan.trial =>
                                session.selectedKitchen.trialPrice,
                              TiffinPlan.weekly =>
                                session.selectedKitchen.weeklyPrice,
                              TiffinPlan.monthly =>
                                session.selectedKitchen.monthlyPrice,
                            }),
                            style: const TextStyle(
                              color: MoolColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            session.tiffinPlan == plan
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: session.tiffinPlan == plan
                                ? MoolColors.success
                                : MoolColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _startLabel(TiffinPlan plan) => switch (plan) {
  TiffinPlan.trial => 'Try meal today',
  TiffinPlan.weekly => 'Start weekly tiffin',
  TiffinPlan.monthly => 'Start monthly tiffin',
};

Future<void> _editTiffinAddress(
  BuildContext context,
  EatSession session,
) async {
  final controller = TextEditingController(text: session.tiffinAddress);
  String? validationMessage;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.lg,
            MoolSpacing.lg,
            MoolSpacing.lg,
            MediaQuery.viewInsetsOf(sheetContext).bottom + MoolSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tiffin delivery address',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('eat-tiffin-address-field'),
                controller: controller,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Home, office or hostel address',
                  errorText: validationMessage,
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              FilledButton(
                key: const Key('eat-tiffin-save-address'),
                onPressed: () {
                  if (controller.text.trim().length < 8) {
                    setSheetState(
                      () => validationMessage =
                          'Enter a complete delivery address.',
                    );
                    return;
                  }
                  session.updateTiffinAddress(controller.text);
                  Navigator.pop(sheetContext);
                },
                child: const Text('Save address'),
              ),
              TextButton(
                key: const Key('eat-tiffin-cancel-address'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 400));
  controller.dispose();
}
