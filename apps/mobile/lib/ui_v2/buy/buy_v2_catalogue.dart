import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
import 'buy_v2_design.dart';
import 'buy_v2_views.dart';

class BuyV2CatalogueView extends StatefulWidget {
  const BuyV2CatalogueView({super.key, required this.session});

  final BuyV2Session session;

  @override
  State<BuyV2CatalogueView> createState() => _BuyV2CatalogueViewState();
}

class _BuyV2CatalogueViewState extends State<BuyV2CatalogueView> {
  bool _savedOnly = false;
  late BuyV2Destination _lastDestination = widget.session.destination;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    if (_lastDestination != session.destination) {
      _lastDestination = session.destination;
      _savedOnly = false;
    }
    return Column(
      children: [
        if (session.canReturnToAccount)
          _CatalogueAccountReturn(session: session),
        _CatalogueToolbar(
          session: session,
          savedOnly: _savedOnly,
          onSaved: () {
            if (!_savedOnly) {
              session.chooseCategory('all');
            }
            setState(() => _savedOnly = !_savedOnly);
          },
        ),
        Expanded(
          child: _ProductGrid(
            session: session,
            savedOnly: _savedOnly,
            onShowAll: () => setState(() => _savedOnly = false),
          ),
        ),
      ],
    );
  }
}

class _CatalogueAccountReturn extends StatelessWidget {
  const _CatalogueAccountReturn({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('buy-catalogue-return-account'),
      color: BuyV2Colors.softBlue,
      child: InkWell(
        onTap: session.returnToAccount,
        child: const SizedBox(
          height: 44,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 19,
                  color: BuyV2Colors.navy,
                ),
                SizedBox(width: 6),
                Text(
                  'Back to Account',
                  style: TextStyle(
                    color: BuyV2Colors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
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

class BuyV2SearchResultsView extends StatelessWidget {
  const BuyV2SearchResultsView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final query = session.query.trim();
    final products = session.visibleProducts;
    return AnimatedSwitcher(
      key: const ValueKey('buy-search-results-surface'),
      duration: BuyV2Motion.resolved(context, BuyV2Motion.contentChange),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: query.isEmpty
          ? _SearchReadyState(
              key: ValueKey('buy-search-ready-${session.destination.name}'),
              session: session,
            )
          : _SearchProductResults(
              key: ValueKey(
                'buy-search-matches-${session.destination.name}-$query',
              ),
              session: session,
              products: products,
              query: query,
            ),
    );
  }
}

class _SearchReadyState extends StatelessWidget {
  const _SearchReadyState({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final suggestions = session.searchSuggestions;
    return ColoredBox(
      color: Colors.white,
      child: ListView.separated(
        key: const ValueKey('buy-search-suggestion-list'),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        itemCount: suggestions.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 42, color: BuyV2Colors.line),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return Semantics(
            button: true,
            label: 'Search ${session.destination.label} for $suggestion',
            child: InkWell(
              key: ValueKey(
                'buy-search-suggestion-${session.destination.name}-$index',
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                session.updateQuery(suggestion);
              },
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 30,
                        child: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: BuyV2Colors.muted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          suggestion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BuyV2Colors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }
}

class _SearchProductResults extends StatelessWidget {
  const _SearchProductResults({
    super.key,
    required this.session,
    required this.products,
    required this.query,
  });

  final BuyV2Session session;
  final List<BuyV2Product> products;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: BuyV2Colors.muted,
              ),
              const SizedBox(height: 9),
              Text(
                'No matches for “$query”',
                textAlign: TextAlign.center,
                style: context.buyTitle.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                'Check the spelling or try a product, brand, seller or code.',
                textAlign: TextAlign.center,
                style: context.buyMeta,
              ),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final accessibleText = textScale > 1.25;
        final columns = accessibleText && constraints.maxWidth < 460
            ? 2
            : constraints.maxWidth >= 320
            ? 3
            : 2;
        final tileHeight = accessibleText
            ? 254.0
            : columns == 3
            ? 188.0
            : 260.0;
        final width =
            (constraints.maxWidth - 16 - ((columns - 1) * 7)) / columns;
        return CustomScrollView(
          key: PageStorageKey('buy-search-${session.destination.name}-$query'),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${products.length} '
                        '${products.length == 1 ? 'match' : 'matches'}',
                        style: context.buyTitle.copyWith(fontSize: 15),
                      ),
                    ),
                    Text(
                      session.destination.label,
                      style: context.buyEyebrow.copyWith(
                        color: BuyV2Colors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _HorizontalProductGrid(
                session: session,
                products: products,
                cardWidth: width,
                tileHeight: tileHeight,
                storageKey:
                    'buy-search-horizontal-${session.destination.name}-$query',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CatalogueToolbar extends StatelessWidget {
  const _CatalogueToolbar({
    required this.session,
    required this.savedOnly,
    required this.onSaved,
  });

  final BuyV2Session session;
  final bool savedOnly;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final order = session.orders.firstWhere(
      (order) =>
          order.destination == session.destination ||
          session.destination == BuyV2Destination.shop,
      orElse: () => session.orders.first,
    );
    return Container(
      key: const ValueKey('buy-catalogue-toolbar'),
      height: 60,
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
      decoration: const BoxDecoration(
        color: BuyV2Colors.canvas,
        border: Border(bottom: BorderSide(color: BuyV2Colors.line)),
      ),
      child: Row(
        children: [
          _CatalogueCategoryPickerButton(session: session),
          const SizedBox(width: 4),
          Expanded(child: _CatalogueOwnedFeature(session: session)),
          const SizedBox(width: 4),
          _CompactCatalogueAction(
            key: const ValueKey('buy-saved-products-button'),
            icon: savedOnly
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: savedOnly ? 'Show all products' : 'Show Saved products',
            badge: '${session.savedCountFor(session.destination)}',
            active: savedOnly,
            onTap: onSaved,
          ),
          const SizedBox(width: 4),
          _CatalogueToolsMenu(session: session, order: order),
        ],
      ),
    );
  }
}

class _CatalogueCategoryPickerButton extends StatelessWidget {
  const _CatalogueCategoryPickerButton({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final selected = session.categories.firstWhere(
      (category) => category.id == session.selectedCategoryId,
      orElse: () => session.categories.first,
    );
    return Semantics(
      label:
          'Choose ${session.destination.label} category. '
          'Current category ${selected.label}',
      button: true,
      child: IconButton(
        key: const ValueKey('buy-category-picker'),
        tooltip: '${session.destination.label} categories · ${selected.label}',
        onPressed: () {
          HapticFeedback.selectionClick();
          showModalBottomSheet<void>(
            context: context,
            useSafeArea: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: const Color(0x240A064D),
            builder: (_) => _CatalogueCategorySheet(session: session),
          );
        },
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(44, 44),
          maximumSize: const Size(44, 44),
          backgroundColor: BuyV2Colors.softOrange,
          foregroundColor: BuyV2Colors.navy,
          side: const BorderSide(color: BuyV2Colors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: const Icon(Icons.menu_rounded, size: 21),
      ),
    );
  }
}

class _CatalogueOwnedFeature extends StatelessWidget {
  const _CatalogueOwnedFeature({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final feature = switch (session.destination) {
      BuyV2Destination.shop => (
        'MoolSocial value',
        'lowest',
        Icons.auto_awesome_rounded,
      ),
      BuyV2Destination.wholesale => (
        'Flexible packs',
        'moq',
        Icons.inventory_2_outlined,
      ),
      BuyV2Destination.medicine => (
        'Everyday care',
        'otc',
        Icons.health_and_safety_outlined,
      ),
      BuyV2Destination.orders => (
        'MoolSocial',
        'any',
        Icons.auto_awesome_rounded,
      ),
    };
    final active = session.selectedFilter == feature.$2;
    return Semantics(
      label: '${feature.$1}, MoolSocial feature',
      selected: active,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('buy-owned-feature'),
          onTap: () {
            HapticFeedback.selectionClick();
            session.chooseFilter(active ? null : feature.$2);
          },
          borderRadius: BorderRadius.circular(13),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: active
                    ? const [BuyV2Colors.softGreen, Color(0xFFE8F7EC)]
                    : const [Color(0xFFFFF2E4), Color(0xFFF2F4FF)],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: active ? BuyV2Colors.green : BuyV2Colors.line,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  feature.$3,
                  size: 18,
                  color: active ? BuyV2Colors.green : BuyV2Colors.navy,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        feature.$1,
                        maxLines: 1,
                        style: const TextStyle(
                          color: BuyV2Colors.ink,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
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

class _CatalogueCategorySheet extends StatefulWidget {
  const _CatalogueCategorySheet({required this.session});

  final BuyV2Session session;

  @override
  State<_CatalogueCategorySheet> createState() =>
      _CatalogueCategorySheetState();
}

class _CatalogueCategorySheetState extends State<_CatalogueCategorySheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final query = _query.trim().toLowerCase();
    final categories = session.categories
        .where(
          (category) =>
              query.isEmpty || category.label.toLowerCase().contains(query),
        )
        .toList(growable: false);
    return FractionallySizedBox(
      heightFactor: .64,
      child: Padding(
        padding: const EdgeInsets.only(bottom: BuyV2Metrics.dockHeight),
        child: ClipRRect(
          key: const ValueKey('buy-category-sheet-surface'),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xF2F8F8FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: Colors.white, width: 1.5),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: BuyV2Colors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: TextField(
                              key: const ValueKey('buy-category-search'),
                              controller: _controller,
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(
                                color: BuyV2Colors.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Find a category',
                                hintStyle: const TextStyle(
                                  color: BuyV2Colors.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 44,
                                ),
                                suffixIcon: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear category search',
                                        onPressed: () {
                                          _controller.clear();
                                          setState(() => _query = '');
                                        },
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 18,
                                        ),
                                      ),
                                filled: true,
                                fillColor: const Color(0xF7FFFFFF),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: BuyV2Colors.line,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: BuyV2Colors.line,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: BuyV2Colors.royal,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          key: const ValueKey('buy-category-close'),
                          tooltip: 'Close categories',
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(44, 44),
                            maximumSize: const Size(44, 44),
                            backgroundColor: const Color(0xF7FFFFFF),
                            foregroundColor: BuyV2Colors.navy,
                            side: const BorderSide(color: BuyV2Colors.line),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: categories.isEmpty
                        ? const Center(
                            child: Text(
                              'No category found',
                              style: TextStyle(
                                color: BuyV2Colors.muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth < 350
                                  ? 2
                                  : 3;
                              return GridView.builder(
                                key: const ValueKey('buy-category-grid'),
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  10,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      mainAxisExtent: 84,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                    ),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  final selected =
                                      category.id == session.selectedCategoryId;
                                  return Semantics(
                                    label:
                                        '${session.destination.label} category, '
                                        '${category.label}'
                                        '${selected ? ', selected' : ''}',
                                    selected: selected,
                                    button: true,
                                    child: Material(
                                      color: selected
                                          ? const Color(0xFFFDF0E1)
                                          : const Color(0xEFFFFFFF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: selected
                                              ? BuyV2Colors.orange
                                              : BuyV2Colors.line,
                                        ),
                                      ),
                                      child: InkWell(
                                        key: ValueKey(
                                          'buy-category-${category.id}',
                                        ),
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          session.chooseCategory(category.id);
                                          Navigator.of(context).pop();
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 7,
                                          ),
                                          child: Stack(
                                            children: [
                                              Align(
                                                alignment: Alignment.center,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 28,
                                                      height: 28,
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: BoxDecoration(
                                                        color: selected
                                                            ? Colors.white
                                                            : BuyV2Colors
                                                                  .softBlue,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        buyV2CategoryIconFor(
                                                          category.id,
                                                        ),
                                                        key: ValueKey(
                                                          'buy-category-icon-'
                                                          '${category.id}',
                                                        ),
                                                        color: selected
                                                            ? BuyV2Colors.green
                                                            : BuyV2Colors.navy,
                                                        size: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: Text(
                                                        category.label,
                                                        key: ValueKey(
                                                          'buy-category-label-'
                                                          '${category.id}',
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color:
                                                              BuyV2Colors.ink,
                                                          fontSize: 10,
                                                          height: 1.05,
                                                          fontWeight: selected
                                                              ? FontWeight.w900
                                                              : FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (selected)
                                                const Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Icon(
                                                    Icons.check_circle_rounded,
                                                    color: BuyV2Colors.green,
                                                    size: 15,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
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

@visibleForTesting
IconData buyV2CategoryIconFor(String id) => switch (id) {
  'all' => Icons.auto_awesome_rounded,
  'fruits-vegetables' => Icons.eco_outlined,
  'dairy-bakery' => Icons.bakery_dining_outlined,
  'eggs-poultry' => Icons.egg_alt_outlined,
  'meat-seafood' => Icons.set_meal_outlined,
  'flour-rice-grains' => Icons.grain_rounded,
  'dals-staples' => Icons.rice_bowl_outlined,
  'oils-ghee' => Icons.opacity_rounded,
  'ground-spices' => Icons.blender_outlined,
  'whole-spices' => Icons.filter_vintage_outlined,
  'breakfast-cereals' => Icons.breakfast_dining_outlined,
  'instant-foods' => Icons.ramen_dining_outlined,
  'sauces-spreads' => Icons.local_dining_outlined,
  'biscuits-chocolate' => Icons.cookie_outlined,
  'namkeen-chips' => Icons.fastfood_outlined,
  'tea-coffee' => Icons.coffee_outlined,
  'juices-water' => Icons.local_drink_outlined,
  'frozen-foods' => Icons.ac_unit_rounded,
  'icecream-cheese' => Icons.icecream_outlined,
  'bath-hand-care' => Icons.soap_outlined,
  'oral-care' => Icons.health_and_safety_outlined,
  'hair-care' => Icons.content_cut_rounded,
  'skin-care' => Icons.face_retouching_natural_outlined,
  'surface-cleaners' => Icons.cleaning_services_outlined,
  'air-waste-care' => Icons.delete_sweep_outlined,
  'laundry-dishwash' => Icons.local_laundry_service_outlined,
  'diapers-wipes' => Icons.baby_changing_station_outlined,
  'baby-care' => Icons.child_friendly_outlined,
  'health-wellness' => Icons.health_and_safety_outlined,
  'dog-care' || 'cat-care' => Icons.pets_outlined,
  'food-storage-packs' => Icons.inventory_2_outlined,
  'cups-tissues' => Icons.takeout_dining_outlined,
  'school-office' || 'stationery-office' => Icons.edit_note_outlined,
  'shop-supplies' || 'retail-supplies' => Icons.storefront_outlined,
  'horeca-food-packs' => Icons.restaurant_menu_outlined,
  'horeca-tableware' => Icons.room_service_outlined,
  'rx' => Icons.description_outlined,
  'pain-fever' => Icons.thermostat_outlined,
  'diabetes' => Icons.bloodtype_outlined,
  'heart-bp' => Icons.favorite_border_rounded,
  'digestive' => Icons.restaurant_outlined,
  'respiratory' => Icons.air_rounded,
  'allergy' => Icons.masks_outlined,
  'vitamins' => Icons.medication_outlined,
  'first-aid' => Icons.medical_services_outlined,
  'devices' => Icons.monitor_heart_outlined,
  'women-care' => Icons.female_rounded,
  _ => Icons.category_outlined,
};

class _CompactCatalogueAction extends StatelessWidget {
  const _CompactCatalogueAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: IconButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        tooltip: label,
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          maximumSize: const Size(44, 44),
          backgroundColor: active ? BuyV2Colors.softOrange : Colors.white,
          foregroundColor: BuyV2Colors.navy,
          side: const BorderSide(color: BuyV2Colors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: Badge(
          isLabelVisible: badge != null,
          label: badge == null
              ? null
              : Text(badge!, style: const TextStyle(fontSize: 8)),
          backgroundColor: BuyV2Colors.orange,
          textColor: BuyV2Colors.navy,
          child: Icon(icon, size: 19),
        ),
      ),
    );
  }
}

class _CatalogueToolsMenu extends StatelessWidget {
  const _CatalogueToolsMenu({required this.session, required this.order});

  final BuyV2Session session;
  final BuyV2Order order;

  @override
  Widget build(BuildContext context) {
    final filterOptions = _filterOptionsFor(session.destination);
    return PopupMenuButton<String>(
      key: const ValueKey('buy-filter-button'),
      tooltip: 'Orders, tools and filters',
      position: PopupMenuPosition.under,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 12,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: BuyV2Colors.line),
      ),
      constraints: const BoxConstraints(
        minWidth: 210,
        maxWidth: 260,
        maxHeight: 360,
      ),
      onSelected: (value) {
        HapticFeedback.selectionClick();
        if (value == 'active-order') {
          session.openTracking(order.id);
        } else if (value == 'basket') {
          showBuyV2HouseholdBasket(context, session);
        } else if (value == 'prescription') {
          showBuyV2PrescriptionSheet(context, session);
        } else if (value.startsWith('filter:')) {
          final filter = value.substring(7);
          session.chooseFilter(filter == 'any' ? null : filter);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          key: const ValueKey('buy-active-orders-button'),
          value: 'active-order',
          height: 44,
          child: const _ToolsMenuRow(
            icon: Icons.local_shipping_outlined,
            label: 'Track active order',
            detail: '3 active',
          ),
        ),
        if (session.destination == BuyV2Destination.shop)
          const PopupMenuItem<String>(
            key: ValueKey('buy-household-basket-button'),
            value: 'basket',
            height: 44,
            child: _ToolsMenuRow(
              icon: Icons.shopping_basket_outlined,
              label: 'Monthly home basket',
            ),
          ),
        if (session.destination == BuyV2Destination.medicine)
          const PopupMenuItem<String>(
            key: ValueKey('buy-prescription-button'),
            value: 'prescription',
            height: 44,
            child: _ToolsMenuRow(
              icon: Icons.description_outlined,
              label: 'Prescriptions',
            ),
          ),
        const PopupMenuDivider(),
        for (final option in filterOptions)
          PopupMenuItem<String>(
            key: ValueKey('buy-filter-${option.$1}'),
            value: 'filter:${option.$1}',
            height: 44,
            child: _ToolsMenuRow(
              icon:
                  (option.$1 == 'any' && session.selectedFilter == null) ||
                      session.selectedFilter == option.$1
                  ? Icons.check_circle_rounded
                  : Icons.tune_rounded,
              label: option.$2,
              active:
                  (option.$1 == 'any' && session.selectedFilter == null) ||
                  session.selectedFilter == option.$1,
            ),
          ),
      ],
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: session.selectedFilter == null
              ? Colors.white
              : BuyV2Colors.softOrange,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: BuyV2Colors.line),
        ),
        child: Badge(
          isLabelVisible: session.selectedFilter != null,
          backgroundColor: BuyV2Colors.orange,
          child: const Icon(
            Icons.more_horiz_rounded,
            color: BuyV2Colors.navy,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ToolsMenuRow extends StatelessWidget {
  const _ToolsMenuRow({
    required this.icon,
    required this.label,
    this.detail,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: active ? BuyV2Colors.green : BuyV2Colors.navy,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: BuyV2Colors.ink,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (detail != null)
          Text(
            detail!,
            style: const TextStyle(
              color: BuyV2Colors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

List<(String, String)> _filterOptionsFor(BuyV2Destination destination) =>
    switch (destination) {
      BuyV2Destination.shop => const [
        ('any', 'Any delivery time'),
        ('fast', 'Fast delivery'),
        ('today', 'Delivered today'),
        ('lowest', 'Lowest delivered price'),
        ('nearby', 'Nearby sellers'),
        ('returns', 'Easy returns'),
      ],
      BuyV2Destination.wholesale => const [
        ('any', 'Any delivery schedule'),
        ('fast', 'Fastest delivery'),
        ('two-days', 'Within two days'),
        ('lowest', 'Lowest landed price'),
        ('freight', 'Freight included'),
        ('moq', 'Flexible MOQ'),
        ('manufacturer', 'Manufacturer direct'),
      ],
      BuyV2Destination.medicine => const [
        ('any', 'Any delivery time'),
        ('fast', 'Fastest pharmacy delivery'),
        ('today', 'Delivered today'),
        ('lowest', 'Lowest delivered price'),
        ('otc', 'No prescription required'),
        ('nearby', 'Nearby pharmacy'),
        ('manufacturer', 'Manufacturer sealed packs'),
      ],
      BuyV2Destination.orders => const [],
    };

Future<void> showBuyV2HouseholdBasket(
  BuildContext context,
  BuyV2Session session,
) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
      child: _HouseholdBasket(session: session),
    ),
  );
}

Future<void> showBuyV2SavedProducts(
  BuildContext context,
  BuyV2Session session,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 520, maxHeight: 360),
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final saved = session.savedProductsFor(session.destination);
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bookmark_rounded, color: BuyV2Colors.navy),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Saved products',
                      style: TextStyle(
                        color: BuyV2Colors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${session.destination.label} · ${saved.length}',
                    style: context.buyMeta,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (saved.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.bookmark_add_outlined,
                          color: BuyV2Colors.muted,
                          size: 30,
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Save products from the grid for instant access.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: BuyV2Colors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final product in saved)
                        ListTile(
                          key: ValueKey('buy-saved-${product.id}'),
                          dense: true,
                          minTileHeight: 56,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.bookmark_rounded,
                            color: BuyV2Colors.navy,
                          ),
                          title: Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${product.pack} · ${buyV2Money(product.price)}',
                          ),
                          trailing: IconButton(
                            key: ValueKey('buy-unsave-${product.id}'),
                            tooltip: 'Remove ${product.title} from Saved',
                            onPressed: () => session.toggleSaved(product.id),
                            icon: const Icon(Icons.bookmark_remove_rounded),
                          ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            session.openProduct(product.id);
                          },
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _HouseholdBasket extends StatelessWidget {
  const _HouseholdBasket({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              BuyV2Colors.softOrange,
              Colors.white,
              BuyV2Colors.softGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: BuyV2Colors.line),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🧺', style: TextStyle(fontSize: 21)),
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOUSEHOLD BASKETS',
                        style: TextStyle(
                          color: BuyV2Colors.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Monthly home basket',
                        style: TextStyle(
                          color: BuyV2Colors.navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '12 products · 21 packs · 30 days',
                        style: TextStyle(
                          color: BuyV2Colors.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Save ₹415',
                  style: TextStyle(
                    color: BuyV2Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      session.chooseCategory('all');
                      session.showNotice('Basket products are shown below');
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      side: const BorderSide(color: BuyV2Colors.line),
                    ),
                    child: const Text(
                      'See 12 products',
                      style: TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final featured = BuyV2Catalogue.products
                          .where(
                            (product) =>
                                product.destination == BuyV2Destination.shop,
                          )
                          .take(4);
                      for (final product in featured) {
                        session.addProduct(product.id);
                      }
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    child: const Text(
                      'Add basket to cart',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _compactProductBadge(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('lowest')) return 'Lowest price';
  if (normalized.contains('popular')) return 'Popular';
  if (normalized.contains('prescription')) return 'Rx required';
  return value;
}

String _compactDeliveryPromise(String value) {
  final parts = value.split(' · ');
  if (parts.length < 2) return value;
  final date = parts.first.replaceFirst(RegExp(r'^[A-Za-z]{3},\s*'), '');
  final timing = parts
      .sublist(1)
      .join(' · ')
      .replaceFirst(RegExp(r'^(?:by|within)\s+'), '');
  return '$date · $timing';
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.session,
    required this.savedOnly,
    required this.onShowAll,
  });

  final BuyV2Session session;
  final bool savedOnly;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final products = savedOnly
        ? session.visibleProducts
              .where((product) => session.isSaved(product.id))
              .toList(growable: false)
        : session.visibleProducts;
    final showPromotions =
        !savedOnly &&
        session.query.isEmpty &&
        session.selectedCategoryId == 'all';
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                color: BuyV2Colors.muted,
                size: 34,
              ),
              const SizedBox(height: 8),
              Text(
                savedOnly ? 'No Saved products here' : 'No matching products',
                style: context.buyTitle.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                savedOnly
                    ? 'Save products from this grid for instant access.'
                    : 'Try another category or clear the filter.',
                textAlign: TextAlign.center,
                style: context.buyMeta,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  if (savedOnly) {
                    onShowAll();
                  } else {
                    session.chooseFilter(null);
                    session.chooseCategory('all');
                  }
                },
                child: const Text('Show all products'),
              ),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final accessibleText = textScale > 1.25;
        final columns = accessibleText && constraints.maxWidth < 460
            ? 2
            : constraints.maxWidth >= 320
            ? 3
            : 2;
        const compactCards = true;
        final featuredProducts = showPromotions
            ? products.take(6).toList(growable: false)
            : const <BuyV2Product>[];
        final gridProducts = showPromotions
            ? products.skip(featuredProducts.length).toList(growable: false)
            : products;
        final tileHeight = accessibleText
            ? 254.0
            : columns == 3
            ? 188.0
            : 260.0;
        final width =
            (constraints.maxWidth - 12 - ((columns - 1) * 5)) / columns;
        return CustomScrollView(
          key: PageStorageKey(
            'buy-${session.destination.name}-${session.selectedCategoryId}'
            '-${savedOnly ? 'saved' : 'all'}',
          ),
          slivers: [
            if (showPromotions)
              SliverToBoxAdapter(
                child: _CataloguePromotionRail(session: session),
              ),
            if (showPromotions)
              SliverToBoxAdapter(
                child: _FeaturedProductRail(
                  session: session,
                  products: featuredProducts,
                  accessibleText: accessibleText,
                ),
              ),
            if (showPromotions && gridProducts.isNotEmpty)
              const SliverToBoxAdapter(child: _CatalogueSectionHeader()),
            if (gridProducts.isNotEmpty)
              SliverToBoxAdapter(
                child: _HorizontalProductGrid(
                  session: session,
                  products: gridProducts,
                  cardWidth: width,
                  tileHeight: tileHeight,
                  storageKey:
                      'buy-products-horizontal-${session.destination.name}-'
                      '${session.selectedCategoryId}-${savedOnly ? 'saved' : 'all'}',
                  compact: compactCards,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HorizontalProductGrid extends StatelessWidget {
  const _HorizontalProductGrid({
    required this.session,
    required this.products,
    required this.cardWidth,
    required this.tileHeight,
    required this.storageKey,
    this.compact = true,
  });

  final BuyV2Session session;
  final List<BuyV2Product> products;
  final double cardWidth;
  final double tileHeight;
  final String storageKey;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final laneCount = products.length > 1 ? 2 : 1;
    return Semantics(
      key: const ValueKey('buy-horizontal-product-grid'),
      container: true,
      label:
          'Products in $laneCount independently scrollable '
          '${laneCount == 1 ? 'lane' : 'lanes'}.',
      child: SizedBox(
        height: (tileHeight * laneCount) + 14,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 10),
          child: Column(
            children: [
              for (var laneIndex = 0; laneIndex < laneCount; laneIndex++) ...[
                if (laneIndex > 0) const SizedBox(height: 6),
                Expanded(
                  child: Semantics(
                    key: ValueKey('buy-horizontal-product-lane-$laneIndex'),
                    container: true,
                    label:
                        'Product lane ${laneIndex + 1}. '
                        'Swipe left or right for more.',
                    child: ListView.separated(
                      key: PageStorageKey('$storageKey-lane-$laneIndex'),
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: (products.length - laneIndex + 1) ~/ 2,
                      separatorBuilder: (_, _) => const SizedBox(width: 7),
                      itemBuilder: (context, index) {
                        final productIndex = (index * 2) + laneIndex;
                        return SizedBox(
                          width: cardWidth,
                          child: BuyV2ProductCard(
                            session: session,
                            product: products[productIndex],
                            compact: compact,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CataloguePromotionRail extends StatelessWidget {
  const _CataloguePromotionRail({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final cards = switch (session.destination) {
      BuyV2Destination.shop => [
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-shop-basket'),
          title: 'Plan the monthly basket',
          detail: 'Review a ready household product list',
          icon: Icons.shopping_basket_outlined,
          onTap: () => showBuyV2HouseholdBasket(context, session),
        ),
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-shop-wholesale'),
          title: 'Buying for a business?',
          detail: 'Compare established wholesale packs',
          icon: Icons.storefront_outlined,
          accent: BuyV2Colors.green,
          onTap: () => session.openDestination(BuyV2Destination.wholesale),
        ),
      ],
      BuyV2Destination.wholesale => [
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-wholesale-restock'),
          title: 'Flexible restocking',
          detail: 'See products with flexible minimum packs',
          icon: Icons.inventory_2_outlined,
          onTap: () => session.chooseFilter('moq'),
        ),
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-wholesale-shop'),
          title: 'Shopping for home?',
          detail: 'Return to retail packs in Shop',
          icon: Icons.shopping_bag_outlined,
          accent: BuyV2Colors.green,
          onTap: () => session.openDestination(BuyV2Destination.shop),
        ),
      ],
      BuyV2Destination.medicine => [
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-medicine-prescription'),
          title: 'Prescription centre',
          detail: 'Upload or use a saved prescription',
          icon: Icons.description_outlined,
          onTap: () => showBuyV2PrescriptionSheet(context, session),
        ),
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-medicine-wellness'),
          title: 'Everyday wellness',
          detail: 'Browse no-prescription care',
          icon: Icons.health_and_safety_outlined,
          accent: BuyV2Colors.green,
          onTap: () => session.chooseFilter('otc'),
        ),
      ],
      BuyV2Destination.orders => const <BuyV2PromotionCard>[],
    };
    return SizedBox(
      key: const ValueKey('buy-catalogue-promotions'),
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}

class _FeaturedProductRail extends StatelessWidget {
  const _FeaturedProductRail({
    required this.session,
    required this.products,
    required this.accessibleText,
  });

  final BuyV2Session session;
  final List<BuyV2Product> products;
  final bool accessibleText;

  @override
  Widget build(BuildContext context) {
    final title = switch (session.destination) {
      BuyV2Destination.shop => 'Fresh picks',
      BuyV2Destination.wholesale => 'Trade picks',
      BuyV2Destination.medicine => 'Pharmacy picks',
      BuyV2Destination.orders => 'Product picks',
    };
    return SizedBox(
      key: const ValueKey('buy-featured-products'),
      height: accessibleText ? 286 : 266,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 7, 9, 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.buyTitle.copyWith(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Swipe to explore',
                      style: context.buyMeta.copyWith(
                        color: BuyV2Colors.navy,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: BuyV2Colors.navy,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('buy-featured-product-list'),
              padding: const EdgeInsets.fromLTRB(7, 0, 12, 8),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => SizedBox(
                width: accessibleText ? 178 : 168,
                child: _FeaturedProductCard(
                  session: session,
                  product: products[index],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogueSectionHeader extends StatelessWidget {
  const _CatalogueSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('buy-more-products-heading'),
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'More products',
              style: context.buyTitle.copyWith(fontSize: 15),
            ),
          ),
          Text(
            'Swipe for more',
            style: context.buyMeta.copyWith(
              color: BuyV2Colors.navy,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: BuyV2Colors.navy,
          ),
        ],
      ),
    );
  }
}

class _FeaturedProductCard extends StatefulWidget {
  const _FeaturedProductCard({required this.session, required this.product});

  final BuyV2Session session;
  final BuyV2Product product;

  @override
  State<_FeaturedProductCard> createState() => _FeaturedProductCardState();
}

class _FeaturedProductCardState extends State<_FeaturedProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final product = widget.product;
    final quantity = session.quantityFor(product.id);
    final rxBlocked =
        product.requiresPrescription &&
        !session.isPrescriptionApproved(product.id);
    return AnimatedScale(
      key: ValueKey('buy-featured-product-${product.id}'),
      scale: _pressed ? BuyV2Motion.pressScale : 1,
      duration: BuyV2Motion.resolved(context, BuyV2Motion.press),
      curve: Curves.easeOutCubic,
      child: Semantics(
        label:
            '${product.title}, ${product.pack}, ${buyV2Money(product.price)}, '
            '${product.deliveryPromise}, fulfilled by ${product.seller}',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('buy-product-${product.id}'),
            onHighlightChanged: (pressed) {
              if (_pressed != pressed) {
                setState(() => _pressed = pressed);
              }
            },
            onTap: () {
              HapticFeedback.selectionClick();
              session.openProduct(product.id);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: buyV2CardDecoration(radius: 16, shadow: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _FeaturedProductVisual(product: product),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: _ProductSaveButton(
                            session: session,
                            product: product,
                          ),
                        ),
                        Positioned(
                          right: 7,
                          bottom: 7,
                          child: _FeaturedProductAction(
                            session: session,
                            product: product,
                            quantity: quantity,
                            rxBlocked: rxBlocked,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: BuyV2Colors.ink,
                              fontSize: 11,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.pack,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.buyMeta.copyWith(fontSize: 8),
                          ),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                buyV2Money(product.price),
                                style: const TextStyle(
                                  color: BuyV2Colors.navy,
                                  fontSize: 15,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${product.seller} · '
                                  '${_compactDeliveryPromise(product.deliveryPromise)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: BuyV2Colors.green,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

class _FeaturedProductVisual extends StatelessWidget {
  const _FeaturedProductVisual({required this.product});

  final BuyV2Product product;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _productVisualColors(product)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 8,
            right: 8,
            bottom: 8,
            child: BuyV2ProductPackshot(
              key: ValueKey('buy-featured-packshot-${product.id}'),
              product: product,
              borderRadius: 13,
            ),
          ),
          Positioned(
            left: 7,
            top: 7,
            right: 50,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 92),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: product.requiresPrescription
                      ? BuyV2Colors.navy
                      : BuyV2Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _compactProductBadge(product.badge),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
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

class _FeaturedProductAction extends StatelessWidget {
  const _FeaturedProductAction({
    required this.session,
    required this.product,
    required this.quantity,
    required this.rxBlocked,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final int quantity;
  final bool rxBlocked;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: BuyV2Motion.resolved(context, BuyV2Motion.stateChange),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .92, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: quantity > 0
          ? SizedBox(
              key: ValueKey('buy-featured-quantity-shell-${product.id}'),
              width: 108,
              child: _QuantityStepper(
                key: ValueKey('buy-quantity-${product.id}'),
                quantity: quantity,
                onDecrease: () => session.decrease(product.id),
                onIncrease: () => session.increase(product.id),
              ),
            )
          : Semantics(
              label: rxBlocked
                  ? 'Use prescription for ${product.title}'
                  : 'Add ${product.title} to cart',
              button: true,
              child: Material(
                key: ValueKey('buy-add-${product.id}'),
                color: rxBlocked ? BuyV2Colors.navy : Colors.white,
                elevation: 3,
                shadowColor: const Color(0x33000040),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final added = session.addProduct(product.id);
                    if (!added &&
                        session.pendingPrescriptionProductId == product.id) {
                      showBuyV2PrescriptionSheet(context, session);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: BuyV2Metrics.minimumTap,
                    height: BuyV2Metrics.minimumTap,
                    child: Center(
                      child: rxBlocked
                          ? const Text(
                              'Rx',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : const Icon(
                              Icons.add_rounded,
                              color: BuyV2Colors.navy,
                              size: 23,
                            ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class BuyV2ProductCard extends StatelessWidget {
  const BuyV2ProductCard({
    super.key,
    required this.session,
    required this.product,
    this.compact = false,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final quantity = session.quantityFor(product.id);
    final rxBlocked =
        product.requiresPrescription &&
        !session.isPrescriptionApproved(product.id);
    return Semantics(
      label:
          '${product.title}, ${product.pack}, ${buyV2Money(product.price)}, ${product.deliveryPromise}, fulfilled by ${product.seller}',
      button: true,
      child: InkWell(
        key: ValueKey('buy-product-${product.id}'),
        onTap: () => session.openProduct(product.id),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: buyV2CardDecoration(radius: 14),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductVisual(product: product, compact: compact),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 6 : 9,
                        compact ? 4 : 7,
                        compact ? 6 : 9,
                        compact ? 2 : 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!compact) ...[
                            Text(
                              product.brand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyEyebrow.copyWith(fontSize: 7),
                            ),
                            const SizedBox(height: 3),
                          ],
                          Text(
                            product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: BuyV2Colors.ink,
                              fontSize: compact ? 9 : 12,
                              height: compact ? 1 : 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: compact ? 1 : 5),
                          if (!compact) ...[
                            Text(
                              product.variant,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BuyV2Colors.ink,
                                fontSize: 8,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],
                          Text(
                            product.pack,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.buyMeta.copyWith(
                              fontSize: compact ? 8 : 8,
                            ),
                          ),
                          if (compact)
                            const SizedBox(height: 1)
                          else
                            const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      buyV2Money(product.price),
                                      style: TextStyle(
                                        color: BuyV2Colors.navy,
                                        fontSize: compact ? 13 : 18,
                                        height: 1,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    if (!compact)
                                      Text(
                                        product.unitPrice,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.buyMeta.copyWith(
                                          fontSize: 7,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (compact)
                            const Spacer()
                          else
                            const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 4 : 6,
                              vertical: compact ? 2 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: BuyV2Colors.softGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 11,
                                      color: BuyV2Colors.green,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        compact
                                            ? '${product.seller} · '
                                                  '${_compactDeliveryPromise(product.deliveryPromise)}'
                                            : product.deliveryPromise,
                                        maxLines: compact ? 1 : 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: BuyV2Colors.green,
                                          fontSize: compact ? 7.5 : 8,
                                          height: 1.05,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!compact) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    product.seller,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: BuyV2Colors.ink,
                                      fontSize: 8,
                                      height: 1.05,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${product.origin} · ${product.confirmedOn}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: BuyV2Colors.muted,
                                      fontSize: 7,
                                      height: 1.05,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: compact ? 2 : 6),
                          AnimatedSwitcher(
                            duration: BuyV2Motion.resolved(
                              context,
                              BuyV2Motion.stateChange,
                            ),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: quantity > 0
                                ? _QuantityStepper(
                                    key: ValueKey('buy-quantity-${product.id}'),
                                    quantity: quantity,
                                    onDecrease: () =>
                                        session.decrease(product.id),
                                    onIncrease: () =>
                                        session.increase(product.id),
                                  )
                                : SizedBox(
                                    key: ValueKey(
                                      'buy-add-shell-${product.id}',
                                    ),
                                    width: double.infinity,
                                    height: BuyV2Metrics.minimumTap,
                                    child: Semantics(
                                      label: rxBlocked
                                          ? 'Use prescription for '
                                                '${product.title}'
                                          : 'Add ${product.title} to cart',
                                      button: true,
                                      child: Material(
                                        key: ValueKey('buy-add-${product.id}'),
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            final added = session.addProduct(
                                              product.id,
                                            );
                                            if (!added &&
                                                session.pendingPrescriptionProductId ==
                                                    product.id) {
                                              showBuyV2PrescriptionSheet(
                                                context,
                                                session,
                                              );
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                          child: Center(
                                            child: Container(
                                              height: 32,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: rxBlocked
                                                    ? BuyV2Colors.navy
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: rxBlocked
                                                      ? BuyV2Colors.navy
                                                      : const Color(0x66000080),
                                                ),
                                              ),
                                              child: rxBlocked
                                                  ? const Text(
                                                      'Use Rx',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.add_rounded,
                                                      color: BuyV2Colors.navy,
                                                      size: 20,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 2,
                right: 2,
                child: _ProductSaveButton(session: session, product: product),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: BuyV2Metrics.minimumTap,
      decoration: BoxDecoration(
        color: BuyV2Colors.softBlue,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x23000080)),
      ),
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              tooltip: 'Remove one',
              onPressed: onDecrease,
              icon: const Icon(Icons.remove, size: 17),
              color: BuyV2Colors.navy,
              padding: EdgeInsets.zero,
            ),
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              color: BuyV2Colors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: IconButton(
              tooltip: 'Add one',
              onPressed: onIncrease,
              icon: const Icon(Icons.add, size: 17),
              color: BuyV2Colors.navy,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSaveButton extends StatelessWidget {
  const _ProductSaveButton({required this.session, required this.product});

  final BuyV2Session session;
  final BuyV2Product product;

  @override
  Widget build(BuildContext context) {
    final saved = session.isSaved(product.id);
    return IconButton(
      key: ValueKey('buy-save-${product.id}'),
      tooltip: saved
          ? 'Remove ${product.title} from Saved'
          : 'Save ${product.title}',
      onPressed: () {
        HapticFeedback.selectionClick();
        session.toggleSaved(product.id);
      },
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        maximumSize: const Size(44, 44),
        foregroundColor: saved ? BuyV2Colors.orange : BuyV2Colors.navy,
        shape: const CircleBorder(),
      ),
      icon: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .92),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white),
        ),
        child: Icon(
          saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          size: 16,
        ),
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.product, required this.compact});

  final BuyV2Product product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _productVisualColors(product);
    return SizedBox(
      height: compact ? 72 : 110,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                  bottom: Radius.circular(10),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, .35),
            child: SizedBox(
              key: ValueKey('buy-grid-packshot-${product.id}'),
              width: compact ? 86 : 96,
              height: compact ? 64 : 86,
              child: BuyV2ProductPackshot(
                product: product,
                borderRadius: compact ? 8 : 12,
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 6,
            right: compact ? 42 : 6,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                constraints: BoxConstraints(maxWidth: compact ? 58 : 120),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 4 : 6,
                  vertical: compact ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: product.requiresPrescription
                      ? BuyV2Colors.navy
                      : BuyV2Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  compact ? _compactProductBadge(product.badge) : product.badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 7 : 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            right: 8,
            bottom: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BuyV2Colors.green,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 2)],
              ),
              child: SizedBox(width: 9, height: 9),
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> _productVisualColors(BuyV2Product product) {
  return switch (product.visualKind) {
    'produce' => const [Color(0xFFFFE9E2), Color(0xFFEAF7E8)],
    'bottle' => const [Color(0xFFFFF5CF), Color(0xFFE8F6F8)],
    'paper' => const [Color(0xFFE8ECFA), Color(0xFFF8EBF4)],
    'medicine-box' => const [Color(0xFFE5F5F1), Color(0xFFFFE9E9)],
    'tube' => const [Color(0xFFFFE6D6), Color(0xFFF4EAF8)],
    _ => const [Color(0xFFFFF1DE), Color(0xFFEDF3F8)],
  };
}
