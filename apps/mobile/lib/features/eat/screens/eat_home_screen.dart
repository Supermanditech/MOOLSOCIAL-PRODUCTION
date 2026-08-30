import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_service_home.dart';
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
  final _searchFocusNode = FocusNode();
  String _selectedCuisine = 'All';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
  }

  void _handleSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) {
          final restaurants = widget.session
              .visibleRestaurants(_searchController.text)
              .where(
                (restaurant) => switch (_selectedCuisine) {
                  'North Indian' => restaurant.cuisine == 'North Indian',
                  'Cafe' => restaurant.cuisine == 'Cafe',
                  'Dining' =>
                    restaurant.cuisine.toLowerCase().contains('dining') ||
                        restaurant.cuisine.toLowerCase().contains('rooftop') ||
                        restaurant.cuisine.toLowerCase().contains('multi'),
                  _ => true,
                },
              )
              .toList();
          return EatPageScaffold(
            key: const Key('eat-home-screen'),
            session: widget.session,
            title: 'Order Food',
            subtitle: 'Sardarpura · Jodhpur · open now',
            activeLocalAction: 'order',
            fallbackBackRoute: '/app/eat',
            showBack: false,
            body: ListView(
              key: const Key('eat-home-discovery-list'),
              padding: const EdgeInsets.fromLTRB(
                MoolServiceHomeTokens.pagePadding,
                MoolSpacing.xs,
                MoolServiceHomeTokens.pagePadding,
                MoolSpacing.xxl,
              ),
              children: [
                const MoolServiceCard(
                  key: Key('eat-home-location'),
                  title: 'Sardarpura, Jodhpur',
                  subtitle: 'Delivering to Home',
                  icon: Icons.location_on_rounded,
                  accent: _eatAccent,
                ),
                const SizedBox(height: MoolSpacing.sm),
                MoolServiceSearchField(
                  key: const Key('eat-home-search-surface'),
                  fieldKey: const Key('eat-home-search'),
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: 'Search food, cuisine or restaurant',
                  semanticLabel: 'Search food and restaurants',
                  onChanged: (_) => setState(() {}),
                  trailing: _searchController.text.isEmpty
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
                const SizedBox(height: MoolSpacing.sm),
                const _PrimaryRoutes(),
                const SizedBox(height: MoolServiceHomeTokens.sectionGap),
                MoolServiceSectionHeader(
                  title: 'Food near you',
                  subtitle: restaurants.isEmpty
                      ? 'Try another cuisine or search'
                      : '${restaurants.length} places · price and time shown before you choose',
                ),
                const SizedBox(height: MoolSpacing.sm),
                _ContextChoices(
                  selectedCuisine: _selectedCuisine,
                  onSelected: (value) =>
                      setState(() => _selectedCuisine = value),
                ),
                const SizedBox(height: MoolSpacing.sm),
                if (restaurants.isEmpty)
                  _EmptyRestaurants(
                    onClear: () {
                      _searchController.clear();
                      setState(() => _selectedCuisine = 'All');
                    },
                  )
                else
                  for (final restaurant in restaurants)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: MoolServiceHomeTokens.cardGap,
                      ),
                      child: _RestaurantChoice(
                        restaurant: restaurant,
                        onTap: () {
                          widget.session.selectRestaurant(restaurant.id);
                          if (widget.session.selectedRestaurantId ==
                              restaurant.id) {
                            context.go('/app/eat/order');
                          }
                        },
                      ),
                    ),
              ],
            ),
          );
        },
      ),
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

const _eatAccent = Color(0xFFB42318);

class _ContextChoices extends StatelessWidget {
  const _ContextChoices({
    required this.selectedCuisine,
    required this.onSelected,
  });

  final String selectedCuisine;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('eat-home-cuisine-filters'),
      spacing: MoolSpacing.xs,
      runSpacing: MoolSpacing.xs,
      children: [
        for (final cuisine in const ['All', 'North Indian', 'Cafe', 'Dining'])
          MoolServiceChoice(
            key: Key(
              'eat-cuisine-${cuisine.toLowerCase().replaceAll(' ', '-')}',
            ),
            label: cuisine,
            selected: selectedCuisine == cuisine,
            onSelected: (_) => onSelected(cuisine),
            accent: _eatAccent,
          ),
      ],
    );
  }
}

class _RestaurantChoice extends StatelessWidget {
  const _RestaurantChoice({required this.restaurant, required this.onTap});

  final EatRestaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MoolServiceCard(
      key: Key('eat-restaurant-${restaurant.id}'),
      title: restaurant.name,
      subtitle: restaurant.available
          ? '${restaurant.cuisine} · ${restaurant.area}'
          : '${restaurant.cuisine} · Closed today',
      icon: restaurant.available
          ? Icons.restaurant_rounded
          : Icons.event_busy_rounded,
      accent: restaurant.available ? _eatAccent : MoolColors.muted,
      emphasized: false,
      semanticLabel: restaurant.available
          ? 'Open ${restaurant.name} menu. ${restaurant.rating} rating. ${restaurant.deliveryTime}. From ${eatMoney(restaurant.orderStartingPrice)}.'
          : '${restaurant.name} is closed today',
      metadata: [
        MoolServiceMeta(
          icon: Icons.star_rounded,
          label: restaurant.rating.toStringAsFixed(1),
        ),
        MoolServiceMeta(
          icon: Icons.schedule_rounded,
          label: restaurant.deliveryTime,
        ),
        MoolServiceMeta(
          icon: Icons.near_me_outlined,
          label: restaurant.distance,
        ),
        MoolServiceMeta(
          icon: Icons.payments_outlined,
          label: 'From ${eatMoney(restaurant.orderStartingPrice)}',
        ),
      ],
      onTap: onTap,
    );
  }
}

class _PrimaryRoutes extends StatelessWidget {
  const _PrimaryRoutes();

  @override
  Widget build(BuildContext context) {
    return _RouteCard(
      key: const Key('eat-home-table'),
      icon: Icons.table_restaurant_outlined,
      title: 'Book Table',
      detail: 'See available times, cost and cancellation before booking',
      action: 'Find a table',
      onTap: () => context.go('/app/eat/table'),
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
    return MoolServiceCard(
      title: title,
      subtitle: detail,
      icon: icon,
      accent: _eatAccent,
      emphasized: false,
      semanticLabel: '$action. $title. $detail',
      onTap: onTap,
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
