import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_service_home.dart';
import '../../../core/design/mool_theme.dart';
import '../eat_models.dart';
import '../eat_session.dart';
import '../widgets/eat_widgets.dart';

class EatTableScreen extends StatefulWidget {
  const EatTableScreen({required this.session, super.key});

  final EatSession session;

  @override
  State<EatTableScreen> createState() => _EatTableScreenState();
}

class _EatTableScreenState extends State<EatTableScreen> {
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
        final restaurants = widget.session.visibleRestaurants(
          _searchController.text,
        );
        final restaurant = widget.session.tableRestaurant;
        final bookingTotal =
            restaurant.bookingPrice + widget.session.tableChoicePrice;
        return EatPageScaffold(
          key: const Key('eat-table-screen'),
          session: widget.session,
          title: 'Book Table',
          subtitle: 'Sardarpura · Jodhpur',
          activeLocalAction: 'table',
          fallbackBackRoute: '/app/eat',
          showBack: false,
          showTrailing: false,
          body: ListView(
            key: const Key('eat-table-discovery-list'),
            padding: const EdgeInsets.fromLTRB(
              MoolServiceHomeTokens.pagePadding,
              MoolSpacing.xs,
              MoolServiceHomeTokens.pagePadding,
              MoolSpacing.xxl,
            ),
            children: [
              const MoolServiceCard(
                key: Key('eat-table-location'),
                title: 'Sardarpura, Jodhpur',
                subtitle: 'Restaurants with table availability',
                icon: Icons.location_on_rounded,
                accent: _eatTableAccent,
              ),
              const SizedBox(height: MoolSpacing.sm),
              MoolServiceSearchField(
                key: const Key('eat-table-search-surface'),
                fieldKey: const Key('eat-table-search'),
                controller: _searchController,
                hintText: 'Search restaurant, cuisine or area',
                semanticLabel: 'Search restaurants for a table',
                onChanged: (_) => setState(() {}),
                trailing: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('eat-table-clear-search'),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              if (restaurants.isEmpty)
                EatSurfaceCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 46,
                        color: MoolColors.muted,
                      ),
                      const Text(
                        'No matching restaurants',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      OutlinedButton(
                        key: const Key('eat-table-show-all'),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Text('Show all restaurants'),
                      ),
                    ],
                  ),
                )
              else ...[
                MoolServiceSectionHeader(
                  title: 'Available restaurants',
                  subtitle:
                      '${restaurants.length} places · cost and cancellation shown before booking',
                ),
                const SizedBox(height: MoolSpacing.sm),
                for (final item in restaurants)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: MoolServiceHomeTokens.cardGap,
                    ),
                    child: _TableRestaurantChoice(
                      restaurant: item,
                      selected: widget.session.tableRestaurantId == item.id,
                      onTap: () =>
                          widget.session.selectTableRestaurant(item.id),
                    ),
                  ),
                const SizedBox(height: MoolSpacing.sm),
                _TableChoices(session: widget.session),
                const SizedBox(height: MoolSpacing.sm),
                EatSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${restaurant.name} · ${widget.session.tablePeople} at ${widget.session.tableTime}',
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${widget.session.tableChoice} · ${restaurant.confirmationRule}.',
                        style: const TextStyle(
                          color: MoolColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      EatTrustStrip(
                        items: [
                          ('Hold', '10 minutes'),
                          ('Cost', restaurant.depositRule),
                          ('Cancel', restaurant.cancellationRule),
                        ],
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      Text(
                        bookingTotal == 0
                            ? 'Free booking'
                            : '${eatMoney(bookingTotal)} ${restaurant.bookingPriceLabel}',
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          bottomAction: restaurants.isEmpty
              ? null
              : FilledButton(
                  key: const Key('eat-book-table'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _eatTableAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(
                      44,
                      MoolServiceHomeTokens.primaryActionHeight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MoolRadii.card),
                    ),
                  ),
                  onPressed: widget.session.busy
                      ? null
                      : () async {
                          final booked = await widget.session.bookTable();
                          if (booked && context.mounted) {
                            context.go(
                              '/app/eat/table/${widget.session.tableReceipt!.id}',
                            );
                          }
                        },
                  child: widget.session.busy
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          bookingTotal == 0
                              ? 'Book table'
                              : 'Book table · ${eatMoney(bookingTotal)}',
                        ),
                ),
        );
      },
    );
  }
}

const _eatTableAccent = Color(0xFFB42318);

class _TableRestaurantChoice extends StatelessWidget {
  const _TableRestaurantChoice({
    required this.restaurant,
    required this.selected,
    required this.onTap,
  });

  final EatRestaurant restaurant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = restaurant.bookingPrice == 0
        ? 'Free booking'
        : '${eatMoney(restaurant.bookingPrice)} ${restaurant.bookingPriceLabel}';
    return MoolServiceCard(
      key: Key('eat-table-restaurant-${restaurant.id}'),
      title: restaurant.name,
      subtitle: restaurant.available
          ? '${restaurant.cuisine} · ${restaurant.area}\n${restaurant.status}'
          : '${restaurant.cuisine} · No tables today',
      icon: restaurant.available
          ? Icons.table_restaurant_rounded
          : Icons.event_busy_rounded,
      accent: restaurant.available ? _eatTableAccent : MoolColors.muted,
      emphasized: false,
      semanticLabel: restaurant.available
          ? 'Select ${restaurant.name}. ${restaurant.rating} rating. ${restaurant.distance}. ${restaurant.status}. $price.'
          : '${restaurant.name} has no tables today',
      metadata: [
        MoolServiceMeta(
          icon: Icons.star_rounded,
          label: restaurant.rating.toStringAsFixed(1),
        ),
        MoolServiceMeta(
          icon: Icons.near_me_outlined,
          label: restaurant.distance,
        ),
        MoolServiceMeta(icon: Icons.payments_outlined, label: price),
      ],
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? MoolColors.success : MoolColors.muted,
      ),
      onTap: onTap,
    );
  }
}

class _TableChoices extends StatelessWidget {
  const _TableChoices({required this.session});

  final EatSession session;

  static const tableOptions = <(String, int)>[
    ('Standard table', 0),
    ('Family dining', 0),
    ('Dining pack', 1200),
    ('Buffet seat', 899),
    ('Celebration setup', 2000),
  ];

  @override
  Widget build(BuildContext context) {
    return EatSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Book your table',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Text(
            'People',
            style: TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
          Wrap(
            spacing: MoolSpacing.xs,
            children: ['2', '4', '6', '8+']
                .map(
                  (value) => MoolServiceChoice(
                    key: Key('eat-table-people-$value'),
                    selected: session.tablePeople == value,
                    label: '$value people',
                    onSelected: (_) => session.chooseTablePeople(value),
                    accent: _eatTableAccent,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Text(
            'Time',
            style: TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
          Wrap(
            spacing: MoolSpacing.xs,
            children: ['Now', '7:30 PM', '8:00 PM', '8:30 PM']
                .map(
                  (value) => MoolServiceChoice(
                    key: Key(
                      'eat-table-time-${value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}',
                    ),
                    selected: session.tableTime == value,
                    label: value,
                    onSelected: (_) => session.chooseTableTime(value),
                    accent: _eatTableAccent,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Text(
            'Table choice',
            style: TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Wrap(
            spacing: MoolSpacing.xs,
            runSpacing: MoolSpacing.xs,
            children: [
              for (final option in tableOptions)
                MoolServiceChoice(
                  key: Key(
                    'eat-table-choice-${option.$1.replaceAll(' ', '-').toLowerCase()}',
                  ),
                  label: option.$2 == 0
                      ? option.$1
                      : '${option.$1} · ${eatMoney(option.$2)}',
                  selected: session.tableChoice == option.$1,
                  onSelected: (_) =>
                      session.chooseTableType(option.$1, option.$2),
                  accent: _eatTableAccent,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
