import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../eat_models.dart';
import '../eat_session.dart';
import '../widgets/eat_widgets.dart';

class EatOrderScreen extends StatefulWidget {
  const EatOrderScreen({required this.session, super.key});

  final EatSession session;

  @override
  State<EatOrderScreen> createState() => _EatOrderScreenState();
}

class _EatOrderScreenState extends State<EatOrderScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final items = widget.session.visibleMenu(_searchController.text);
        return EatPageScaffold(
          key: const Key('eat-order-screen'),
          session: widget.session,
          title: widget.session.selectedRestaurant.name,
          subtitle:
              '${widget.session.selectedRestaurant.cuisine} · ${widget.session.fulfilmentPromise}',
          activeDock: 'order',
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  MoolSpacing.md,
                  MoolSpacing.xs,
                  MoolSpacing.md,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    _RestaurantSummary(session: widget.session),
                    const SizedBox(height: MoolSpacing.sm),
                    _FulfilmentChoices(session: widget.session),
                    const SizedBox(height: MoolSpacing.sm),
                    TextField(
                      key: const Key('eat-menu-search'),
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search dishes or ingredients',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                key: const Key('eat-menu-clear'),
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    SizedBox(
                      height: MoolMetrics.minimumTapTarget,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: EatMenuCategory.values.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: MoolSpacing.xs),
                        itemBuilder: (context, index) {
                          final category = EatMenuCategory.values[index];
                          return ChoiceChip(
                            key: Key('eat-menu-${category.name}'),
                            selected:
                                widget.session.selectedCategory == category,
                            label: Text(category.label),
                            onSelected: (_) =>
                                widget.session.selectMenuCategory(category),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    const EatTrustStrip(
                      items: [
                        ('Availability', 'reserved before payment'),
                        ('Cancel', 'before restaurant accepts'),
                        ('Proof', 'digital bill'),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                  ],
                ),
              ),
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyMenu(
                    onClear: () {
                      _searchController.clear();
                      widget.session.selectMenuCategory(
                        EatMenuCategory.bestValue,
                      );
                      setState(() {});
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    MoolSpacing.md,
                    0,
                    MoolSpacing.md,
                    MoolSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MoolSpacing.sm),
                    itemBuilder: (context, index) => _MenuItemCard(
                      item: items[index],
                      session: widget.session,
                    ),
                  ),
                ),
            ],
          ),
          bottomAction: widget.session.itemCount == 0
              ? null
              : FilledButton(
                  key: const Key('eat-view-basket'),
                  onPressed: () => context.go('/app/eat/basket'),
                  child: Text(
                    '${widget.session.itemCount} '
                    '${widget.session.itemCount == 1 ? 'item' : 'items'} · '
                    '${eatMoney(widget.session.subtotal)} · View basket',
                  ),
                ),
        );
      },
    );
  }
}

class _RestaurantSummary extends StatelessWidget {
  const _RestaurantSummary({required this.session});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    final restaurant = session.selectedRestaurant;
    return EatSurfaceCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFFE6C7),
            foregroundColor: MoolColors.navy,
            child: Text(
              restaurant.name.split(' ').map((part) => part[0]).take(2).join(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${restaurant.area} · ${restaurant.distance} · ${restaurant.rating}',
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
                Text(
                  restaurant.status,
                  style: const TextStyle(
                    color: MoolColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('eat-change-restaurant'),
            onPressed: () => context.go('/app/eat/home'),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class _FulfilmentChoices extends StatelessWidget {
  const _FulfilmentChoices({required this.session});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    return EatSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How do you want it?',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            session.fulfilmentPromise,
            style: const TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Wrap(
            spacing: MoolSpacing.xs,
            runSpacing: MoolSpacing.xs,
            children: EatFulfilment.values.map((value) {
              return ChoiceChip(
                key: Key('eat-fulfilment-${value.name}'),
                selected: session.fulfilment == value,
                label: Text(value.label),
                onSelected: (_) async {
                  session.chooseFulfilment(value);
                  if (value == EatFulfilment.scheduled) {
                    await _showScheduleSheet(context, session);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item, required this.session});

  final EatMenuItem item;
  final EatSession session;

  @override
  Widget build(BuildContext context) {
    final quantity = session.quantityFor(item.id);
    return EatSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 84,
                decoration: BoxDecoration(
                  color: _menuColor(item.category),
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                ),
                child: Icon(
                  _menuIcon(item.category),
                  color: MoolColors.navy,
                  size: 34,
                ),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: MoolColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          eatMoney(item.price),
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.available
                          ? '${item.readyIn} · serves ${item.serves} · ${item.offer}'
                          : 'Not available · next batch later',
                      style: TextStyle(
                        color: item.available
                            ? MoolColors.success
                            : const Color(0xFFB42318),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: Key('eat-details-${item.id}'),
                    onPressed: () => _showItemDetails(context, item, session),
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: Text(item.customizable ? 'Customize' : 'Details'),
                  ),
                ),
              ),
              if (quantity == 0)
                FilledButton(
                  key: Key('eat-add-${item.id}'),
                  onPressed: item.available
                      ? () => session.addMenuItem(item.id)
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(84, MoolMetrics.minimumTapTarget),
                  ),
                  child: Text(item.available ? 'Add' : 'Unavailable'),
                )
              else
                EatQuantityControl(
                  itemId: item.id,
                  quantity: quantity,
                  onDecrease: () => session.decrease(item.id),
                  onIncrease: () => session.increase(item.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyMenu extends StatelessWidget {
  const _EmptyMenu({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_meals_outlined,
              size: 48,
              color: MoolColors.muted,
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'No matching dishes',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Clear the search or choose another menu.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MoolSpacing.md),
            OutlinedButton(
              key: const Key('eat-menu-show-all'),
              onPressed: onClear,
              child: const Text('Show full menu'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showScheduleSheet(
  BuildContext context,
  EatSession session,
) async {
  DateTime? date = session.scheduledDate;
  var time = session.scheduledTime ?? '8:30 PM';
  String? validationMessage;
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Schedule delivery',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              OutlinedButton.icon(
                key: const Key('eat-schedule-date'),
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 14)),
                    initialDate: date ?? DateTime.now(),
                  );
                  if (selected != null) {
                    setSheetState(() => date = selected);
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  date == null
                      ? 'Choose date'
                      : '${date!.day}/${date!.month}/${date!.year}',
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              Wrap(
                spacing: MoolSpacing.xs,
                children: ['7:30 PM', '8:30 PM', '9:30 PM']
                    .map(
                      (value) => ChoiceChip(
                        key: Key(
                          'eat-schedule-${value.replaceAll(RegExp(r'[^0-9]'), '')}',
                        ),
                        label: Text(value),
                        selected: time == value,
                        onSelected: (_) => setSheetState(() => time = value),
                      ),
                    )
                    .toList(),
              ),
              if (validationMessage != null) ...[
                const SizedBox(height: MoolSpacing.xs),
                Text(
                  validationMessage!,
                  key: const Key('eat-schedule-error'),
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: MoolSpacing.md),
              FilledButton(
                key: const Key('eat-schedule-confirm'),
                onPressed: () {
                  if (date == null) {
                    setSheetState(
                      () => validationMessage =
                          'Choose a delivery date before confirming.',
                    );
                    return;
                  }
                  if (session.confirmSchedule(date, time)) {
                    Navigator.pop(sheetContext);
                  } else {
                    setSheetState(
                      () => validationMessage =
                          session.errorMessage ?? 'Choose a valid time.',
                    );
                  }
                },
                child: const Text('Confirm schedule'),
              ),
              TextButton(
                key: const Key('eat-schedule-cancel'),
                onPressed: () {
                  session.chooseFulfilment(EatFulfilment.delivery);
                  Navigator.pop(sheetContext);
                },
                child: const Text('Keep delivery now'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 400));
}

Future<void> _showItemDetails(
  BuildContext context,
  EatMenuItem item,
  EatSession session,
) async {
  var selection = session.cartLines
      .where((line) => line.item.id == item.id)
      .map((line) => line.customization)
      .firstOrNull;
  selection ??= 'Standard preparation';
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(item.description),
              const SizedBox(height: MoolSpacing.sm),
              if (item.customizable)
                Wrap(
                  spacing: MoolSpacing.xs,
                  runSpacing: MoolSpacing.xs,
                  children:
                      const [
                            'Standard preparation',
                            'No onion or garlic',
                            'Less spicy',
                          ]
                          .map(
                            (option) => ChoiceChip(
                              key: Key(
                                'eat-custom-${option.replaceAll(' ', '-').toLowerCase()}',
                              ),
                              label: Text(option),
                              selected: selection == option,
                              onSelected: (_) =>
                                  setSheetState(() => selection = option),
                            ),
                          )
                          .toList(),
                ),
              EatTrustStrip(
                items: [
                  ('Ready', item.readyIn),
                  ('Cancel', item.cancelRule),
                  ('Proof', 'Digital bill'),
                ],
              ),
              const SizedBox(height: MoolSpacing.md),
              FilledButton(
                key: Key('eat-custom-save-${item.id}'),
                onPressed: item.available
                    ? () {
                        session.customizeMenuItem(item.id, selection!);
                        Navigator.pop(sheetContext);
                      }
                    : null,
                child: Text(
                  item.available
                      ? 'Save and add · ${eatMoney(item.price)}'
                      : 'Not available',
                ),
              ),
              TextButton(
                key: Key('eat-custom-cancel-${item.id}'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Color _menuColor(EatMenuCategory category) => switch (category) {
  EatMenuCategory.bestValue => const Color(0xFFFFE9D5),
  EatMenuCategory.meals => const Color(0xFFE1F3DE),
  EatMenuCategory.biryani => const Color(0xFFFFE6C7),
  EatMenuCategory.snacks => const Color(0xFFFFF1CC),
  EatMenuCategory.drinks => const Color(0xFFE3F1FF),
  EatMenuCategory.offers => const Color(0xFFEDE8FF),
};

IconData _menuIcon(EatMenuCategory category) => switch (category) {
  EatMenuCategory.bestValue => Icons.local_offer_outlined,
  EatMenuCategory.meals => Icons.rice_bowl_outlined,
  EatMenuCategory.biryani => Icons.dinner_dining_outlined,
  EatMenuCategory.snacks => Icons.bakery_dining_outlined,
  EatMenuCategory.drinks => Icons.local_drink_outlined,
  EatMenuCategory.offers => Icons.redeem_outlined,
};
