import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
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
          title: 'Book a table',
          subtitle: 'Live availability · clear cancellation',
          activeDock: 'table',
          trailing: IconButton.outlined(
            key: const Key('eat-table-saved'),
            tooltip: 'Saved restaurants',
            onPressed: () => widget.session.showNotice(
              'Spice Darbar and Blue Lime Cafe are in your saved places.',
            ),
            icon: const Icon(Icons.bookmark_outline_rounded),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xxl,
            ),
            children: [
              TextField(
                key: const Key('eat-table-search'),
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search restaurant, cuisine or area',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('eat-table-clear-search'),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
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
                const Text(
                  'Choose a place',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
                SizedBox(
                  height: 124,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: restaurants.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: MoolSpacing.xs),
                    itemBuilder: (context, index) {
                      final item = restaurants[index];
                      final selected =
                          widget.session.tableRestaurantId == item.id;
                      return SizedBox(
                        width: 184,
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
                            key: Key('eat-table-restaurant-${item.id}'),
                            onTap: () =>
                                widget.session.selectTableRestaurant(item.id),
                            borderRadius: BorderRadius.circular(MoolRadii.card),
                            child: Padding(
                              padding: const EdgeInsets.all(MoolSpacing.sm),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFFFFE6C7,
                                        ),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: MoolColors.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    item.available
                                        ? '${item.area} · ${item.status}'
                                        : 'No tables today',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: item.available
                                          ? MoolColors.muted
                                          : const Color(0xFFB42318),
                                      fontSize: 10,
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
                _TableChoices(session: widget.session),
                const SizedBox(height: MoolSpacing.sm),
                EatSurfaceCard(
                  color: const Color(0xFFEDEEFF),
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
                        '${widget.session.tableChoice} · ${restaurant.offer} · ${restaurant.confirmationRule}.',
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bookingTotal == 0
                                  ? 'Free booking'
                                  : '${eatMoney(bookingTotal)} ${restaurant.bookingPriceLabel}',
                              style: const TextStyle(
                                color: MoolColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          TextButton(
                            key: const Key('eat-table-chat'),
                            onPressed: () => context.go(
                              '/app/chat/thread/mahadev-business?return=/app/eat/table',
                            ),
                            child: const Text('Chat'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                _BeforeYouGo(session: widget.session),
              ],
            ],
          ),
          bottomAction: restaurants.isEmpty
              ? null
              : FilledButton(
                  key: const Key('eat-book-table'),
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

class _TableChoices extends StatelessWidget {
  const _TableChoices({required this.session});

  final EatSession session;

  static const tableOptions = <(String, String, int)>[
    ('Standard table', 'Normal table · fastest confirmation', 0),
    ('Family dining', 'Bigger table · child friendly', 0),
    ('Dining pack', 'Starter included · adjusted in bill', 1200),
    ('Buffet seat', 'Per-person buffet · limited slot', 899),
    ('Celebration setup', 'Decor setup · cake note supported', 2000),
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
                  (value) => ChoiceChip(
                    key: Key('eat-table-people-$value'),
                    selected: session.tablePeople == value,
                    label: Text('$value people'),
                    onSelected: (_) => session.chooseTablePeople(value),
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
                  (value) => ChoiceChip(
                    key: Key(
                      'eat-table-time-${value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}',
                    ),
                    selected: session.tableTime == value,
                    label: Text(value),
                    onSelected: (_) => session.chooseTableTime(value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Text(
            'Table choice',
            style: TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          for (final option in tableOptions)
            Padding(
              padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
              child: Material(
                color: session.tableChoice == option.$1
                    ? const Color(0xFFEDEEFF)
                    : const Color(0xFFF5F6FC),
                borderRadius: BorderRadius.circular(MoolRadii.control),
                child: InkWell(
                  key: Key(
                    'eat-table-choice-${option.$1.replaceAll(' ', '-').toLowerCase()}',
                  ),
                  onTap: () => session.chooseTableType(option.$1, option.$3),
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
                                  option.$1,
                                  style: const TextStyle(
                                    color: MoolColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  option.$2,
                                  style: const TextStyle(
                                    color: MoolColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (option.$3 > 0)
                            Text(
                              eatMoney(option.$3),
                              style: const TextStyle(
                                color: MoolColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(
                            session.tableChoice == option.$1
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: session.tableChoice == option.$1
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

class _BeforeYouGo extends StatelessWidget {
  const _BeforeYouGo({required this.session});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    return EatSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Before you go',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('eat-table-parking'),
                  onPressed: () => session.showNotice(
                    'Front-lane parking is busy after 8 PM. Nearby paid parking is available.',
                  ),
                  child: const Text('Parking'),
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OutlinedButton(
                  key: const Key('eat-table-call'),
                  onPressed: () => session.showNotice(
                    'Calling the restaurant through a masked number.',
                  ),
                  child: const Text('Call'),
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OutlinedButton(
                  key: const Key('eat-table-menu'),
                  onPressed: () => context.go('/app/eat/order'),
                  child: const Text('Menu'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
