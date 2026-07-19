import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../eat_models.dart';
import '../eat_session.dart';
import '../widgets/eat_widgets.dart';

class EatHomeScreen extends StatefulWidget {
  const EatHomeScreen({required this.session, super.key});

  final EatSession session;

  @override
  State<EatHomeScreen> createState() => _EatHomeScreenState();
}

class _EatHomeScreenState extends State<EatHomeScreen> {
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
        return EatPageScaffold(
          key: const Key('eat-home-screen'),
          session: widget.session,
          title: 'MoolSocial Eat',
          subtitle: 'Sardarpura · Jodhpur · open now',
          activeDock: 'eat',
          fallbackBackRoute: '/app/eat',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xxl,
            ),
            children: [
              TextField(
                key: const Key('eat-home-search'),
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search biryani, thali, cafe or tiffin',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? IconButton(
                          key: const Key('eat-home-voice'),
                          tooltip: 'Use voice search',
                          onPressed: () => _showVoiceSearch(context),
                          icon: const Icon(Icons.mic_none_rounded),
                        )
                      : IconButton(
                          key: const Key('eat-home-clear'),
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
              _ContextChoices(session: widget.session),
              const SizedBox(height: MoolSpacing.sm),
              if (restaurants.isEmpty)
                _EmptyRestaurants(
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
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
                  height: 128,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: restaurants.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: MoolSpacing.xs),
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return _RestaurantChoice(
                        restaurant: restaurant,
                        selected:
                            widget.session.selectedRestaurantId ==
                            restaurant.id,
                        onTap: () =>
                            widget.session.selectRestaurant(restaurant.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                _PrimaryRoutes(session: widget.session),
                const SizedBox(height: MoolSpacing.sm),
                const EatSurfaceCard(
                  color: Color(0xFFEAF7E8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Know before you confirm',
                        style: TextStyle(
                          color: Color(0xFF155B17),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: MoolSpacing.xs),
                      Text(
                        'Live availability, final price, fulfilment time, cancellation window and bill proof remain visible before payment.',
                        style: TextStyle(
                          color: Color(0xFF155B17),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showVoiceSearch(BuildContext context) async {
    final controller = TextEditingController();
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
                  'Find food by voice',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                TextField(
                  key: const Key('eat-voice-field'),
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Say or type what you want',
                    prefixIcon: const Icon(Icons.mic_rounded),
                    errorText: validationMessage,
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                FilledButton(
                  key: const Key('eat-voice-continue'),
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      setSheetState(
                        () => validationMessage =
                            'Type a dish, restaurant or cuisine to search.',
                      );
                      return;
                    }
                    _searchController.text = controller.text.trim();
                    Navigator.pop(sheetContext);
                    setState(() {});
                  },
                  child: const Text('Search food'),
                ),
                TextButton(
                  key: const Key('eat-voice-cancel'),
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
}

class _ContextChoices extends StatelessWidget {
  const _ContextChoices({required this.session});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    return EatSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you eating?',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: MoolSpacing.xs,
            crossAxisSpacing: MoolSpacing.xs,
            childAspectRatio: .88,
            children: [
              _ContextButton(
                key: const Key('eat-context-delivery'),
                icon: Icons.delivery_dining_outlined,
                title: 'Deliver',
                detail: 'home',
                onTap: () => context.go('/app/eat/order'),
              ),
              _ContextButton(
                key: const Key('eat-context-qr'),
                icon: Icons.qr_code_scanner_rounded,
                title: 'QR',
                detail: 'table',
                onTap: () => _showQr(context, session),
              ),
              _ContextButton(
                key: const Key('eat-context-find'),
                icon: Icons.storefront_outlined,
                title: 'Find',
                detail: 'place',
                onTap: () => session.showNotice(
                  'Search is ready. Enter a restaurant, cuisine or area.',
                ),
              ),
              _ContextButton(
                key: const Key('eat-context-offers'),
                icon: Icons.local_offer_outlined,
                title: 'Offers',
                detail: 'save',
                onTap: () => session.showNotice(
                  '${session.selectedRestaurant.offer} is ready before payment.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContextButton extends StatelessWidget {
  const _ContextButton({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F3FA),
      borderRadius: BorderRadius.circular(MoolRadii.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MoolRadii.control),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: MoolColors.navy, size: 22),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(color: MoolColors.muted, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantChoice extends StatelessWidget {
  const _RestaurantChoice({
    required this.restaurant,
    required this.selected,
    required this.onTap,
  });

  final EatRestaurant restaurant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      child: Material(
        color: selected ? const Color(0xFFEDEEFF) : Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? MoolColors.navy : const Color(0x22000080),
          ),
          borderRadius: BorderRadius.circular(MoolRadii.card),
        ),
        child: InkWell(
          key: Key('eat-restaurant-${restaurant.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(MoolRadii.card),
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: restaurant.available
                          ? const Color(0xFFFFE6C7)
                          : const Color(0xFFE6E7EE),
                      foregroundColor: MoolColors.navy,
                      child: Text(
                        restaurant.name
                            .split(' ')
                            .map((part) => part[0])
                            .take(2)
                            .join(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: selected ? MoolColors.success : MoolColors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.xs),
                Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${restaurant.cuisine} · ${restaurant.distance}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
                Text(
                  restaurant.available ? restaurant.offer : 'Closed today',
                  style: TextStyle(
                    color: restaurant.available
                        ? MoolColors.success
                        : const Color(0xFFB42318),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryRoutes extends StatelessWidget {
  const _PrimaryRoutes({required this.session});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RouteCard(
          key: const Key('eat-home-order'),
          icon: Icons.restaurant_menu_rounded,
          title: 'Order food',
          detail: 'Delivery, pickup, schedule or table QR',
          action: 'Choose food',
          onTap: () => context.go('/app/eat/order'),
        ),
        const SizedBox(height: MoolSpacing.xs),
        _RouteCard(
          key: const Key('eat-home-table'),
          icon: Icons.table_restaurant_outlined,
          title: 'Book a table',
          detail: 'Live slot, clear cost and cancellation rule',
          action: 'Find a table',
          onTap: () => context.go('/app/eat/table'),
        ),
        const SizedBox(height: MoolSpacing.xs),
        _RouteCard(
          key: const Key('eat-home-tiffin'),
          icon: Icons.lunch_dining_outlined,
          title: 'Start tiffin',
          detail: 'Trial, weekly or monthly meal plan',
          action: 'Choose a plan',
          onTap: () => context.go('/app/eat/tiffin'),
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EatSurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 84),
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEEFF),
                    borderRadius: BorderRadius.circular(MoolRadii.control),
                  ),
                  child: Icon(icon, color: MoolColors.navy),
                ),
                const SizedBox(width: MoolSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  action,
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: MoolColors.navy),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRestaurants extends StatelessWidget {
  const _EmptyRestaurants({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return EatSurfaceCard(
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: MoolColors.muted,
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Text(
            'No matching places',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Try another restaurant, cuisine or area.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MoolSpacing.md),
          OutlinedButton(
            key: const Key('eat-home-show-all'),
            onPressed: onClear,
            child: const Text('Show all places'),
          ),
        ],
      ),
    );
  }
}

Future<void> _showQr(BuildContext context, EatSession session) async {
  final controller = TextEditingController();
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
                'Scan a table QR',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              const Text(
                'Camera access is unavailable. Enter the printed code instead.',
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('eat-qr-code'),
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Restaurant table code',
                  prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                  errorText: validationMessage,
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              FilledButton(
                key: const Key('eat-qr-continue'),
                onPressed: () {
                  if (controller.text.trim().length < 4) {
                    setSheetState(
                      () => validationMessage =
                          'Enter or scan a valid table code.',
                    );
                    return;
                  }
                  session.chooseFulfilment(EatFulfilment.tableQr);
                  Navigator.pop(sheetContext);
                  context.go('/app/eat/order');
                },
                child: const Text('Open table menu'),
              ),
              TextButton(
                key: const Key('eat-qr-cancel'),
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
