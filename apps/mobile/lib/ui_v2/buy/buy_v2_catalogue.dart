import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/buy/buy_v2_content_contracts.dart';
import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
import 'buy_v2_category_sheet_policy.dart';
import 'buy_v2_design.dart';
import 'buy_v2_info_sheet_motion.dart';
import 'buy_v2_saved_clear_sheet_motion.dart';
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
          child: _CatalogueMotionOwner(
            key: ValueKey(
              'buy-catalogue-motion-${session.destination.name}-'
              '${session.selectedCategoryId}',
            ),
            destination: session.destination,
            child: _ProductGrid(
              session: session,
              savedOnly: _savedOnly,
              onShowAll: () => setState(() => _savedOnly = false),
            ),
          ),
        ),
      ],
    );
  }
}

class _CatalogueMotionOwner extends StatelessWidget {
  const _CatalogueMotionOwner({
    super.key,
    required this.destination,
    required this.child,
  });

  final BuyV2Destination destination;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = BuyV2Motion.resolved(context, BuyV2Motion.contentChange);
    final motion = switch (destination) {
      BuyV2Destination.shop => const (offset: Offset(14, 0), beginScale: 0.985),
      BuyV2Destination.wholesale => const (
        offset: Offset(0, 10),
        beginScale: 0.98,
      ),
      BuyV2Destination.medicine => const (
        offset: Offset(0, 6),
        beginScale: 0.995,
      ),
      BuyV2Destination.orders => const (offset: Offset.zero, beginScale: 1.0),
    };
    return TweenAnimationBuilder<double>(
      key: ValueKey('buy-catalogue-motion-tween-${destination.name}'),
      duration: duration,
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: duration == Duration.zero ? 1 : 0, end: 1),
      builder: (context, value, child) {
        final offset = Offset(
          motion.offset.dx * (1 - value),
          motion.offset.dy * (1 - value),
        );
        final scale = motion.beginScale + ((1 - motion.beginScale) * value);
        return Opacity(
          key: ValueKey('buy-catalogue-motion-opacity-${destination.name}'),
          opacity: value,
          child: Transform.translate(
            key: ValueKey('buy-catalogue-motion-translate-${destination.name}'),
            offset: offset,
            child: Transform.scale(
              key: ValueKey('buy-catalogue-motion-scale-${destination.name}'),
              alignment: Alignment.topCenter,
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: RepaintBoundary(
        key: ValueKey(
          'buy-catalogue-motion-raster-boundary-${destination.name}',
        ),
        child: child,
      ),
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
    return BuyV2FiniteIncomingTransition(
      key: const ValueKey('buy-search-results-surface'),
      stateKey:
          'buy-query-results-${session.destination.name}-'
          '${session.selectedCategoryId}-'
          '${session.selectedFilter ?? 'none'}-'
          '${query.toLowerCase()}',
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
              if (session.hasNarrowedProductSearchScope) ...[
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      key: ValueKey(
                        'buy-search-all-${session.destination.name}',
                      ),
                      onPressed: session.broadenProductSearchScope,
                      icon: const Icon(Icons.travel_explore_rounded, size: 20),
                      label: Text('Search all ${session.destination.label}'),
                    ),
                  ),
                ),
              ],
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
            constraints: const BoxConstraints(
              maxWidth: BuyV2CategorySheetPolicy.maxWidth,
            ),
            sheetAnimationStyle: BuyV2CategorySheetPolicy.resolve(context),
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
  final FocusNode _searchFocus = FocusNode(debugLabel: 'buy-category-search');
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_handleSearchFocusChanged);
  }

  void _handleSearchFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setQueryFromSemantics(String value) {
    _searchFocus.requestFocus();
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() => _query = value);
  }

  void _clearQuery() {
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_handleSearchFocusChanged);
    _searchFocus.dispose();
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
    return Semantics(
      key: const ValueKey('buy-category-sheet-route'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: '${session.destination.label} categories',
      child: KeyedSubtree(
        key: const ValueKey('buy-category-sheet-layout-owner'),
        child: FractionallySizedBox(
          heightFactor: BuyV2CategorySheetPolicy.heightFactorFor(context),
          child: Padding(
            padding: const EdgeInsets.only(bottom: BuyV2Metrics.dockHeight),
            child: ClipRRect(
              key: const ValueKey('buy-category-sheet-surface'),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: RepaintBoundary(
                key: const ValueKey('buy-category-sheet-repaint-boundary'),
                child: _CatalogueCategoryBackdrop(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color(0xFAFFFFFF),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(color: BuyV2Colors.line, width: 1.5),
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
                          padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: BuyV2Colors.softOrange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.category_outlined,
                                  color: BuyV2Colors.navy,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${session.destination.label} categories',
                                      key: const ValueKey(
                                        'buy-category-sheet-title',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: BuyV2Colors.navy,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const Text(
                                      'Choose one to update products',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: BuyV2Colors.muted,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                key: const ValueKey('buy-category-close'),
                                tooltip: 'Close categories',
                                onPressed: () => Navigator.of(context).pop(),
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  minimumSize: const Size(44, 44),
                                  maximumSize: const Size(44, 44),
                                  backgroundColor: Colors.white,
                                  foregroundColor: BuyV2Colors.navy,
                                  side: const BorderSide(
                                    color: BuyV2Colors.line,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 20),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          child: SizedBox(
                            height: 44,
                            child: Semantics(
                              key: const ValueKey(
                                'buy-category-search-semantics',
                              ),
                              container: true,
                              excludeSemantics: true,
                              textField: true,
                              focusable: true,
                              focused: _searchFocus.hasFocus,
                              label: 'Category search',
                              value: _query,
                              hint: 'Find a category',
                              onTap: _searchFocus.requestFocus,
                              onFocus: _searchFocus.requestFocus,
                              onSetText: _setQueryFromSemantics,
                              child: TextField(
                                key: const ValueKey('buy-category-search'),
                                controller: _controller,
                                focusNode: _searchFocus,
                                onChanged: (value) =>
                                    setState(() => _query = value),
                                textInputAction: TextInputAction.search,
                                style: const TextStyle(
                                  color: BuyV2Colors.ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  label: const ExcludeSemantics(
                                    child: Text('Category search'),
                                  ),
                                  hint: const ExcludeSemantics(
                                    child: Text('Find a category'),
                                  ),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  labelStyle: const TextStyle(
                                    color: BuyV2Colors.navy,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
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
                                          key: const ValueKey(
                                            'buy-category-search-clear',
                                          ),
                                          tooltip: 'Clear category search',
                                          onPressed: _clearQuery,
                                          icon: const Icon(
                                            Icons.clear_rounded,
                                            size: 18,
                                          ),
                                        ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
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
                                      color: BuyV2Colors.orange,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: categories.isEmpty
                              ? _CatalogueCategoryEmptyState(
                                  onClear: _clearQuery,
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
                                            category.id ==
                                            session.selectedCategoryId;
                                        return Semantics(
                                          key: ValueKey(
                                            'buy-category-semantics-${category.id}',
                                          ),
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
                                              borderRadius:
                                                  BorderRadius.circular(16),
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
                                              onTap: () async {
                                                HapticFeedback.selectionClick();
                                                final routeCompleted =
                                                    ModalRoute.of(
                                                      context,
                                                    )?.completed;
                                                Navigator.of(context).pop();
                                                if (routeCompleted != null) {
                                                  await routeCompleted;
                                                }
                                                if (session
                                                        .selectedCategoryId !=
                                                    category.id) {
                                                  session.chooseCategory(
                                                    category.id,
                                                  );
                                                }
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 7,
                                                    ),
                                                child: Stack(
                                                  children: [
                                                    Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 28,
                                                            height: 28,
                                                            alignment: Alignment
                                                                .center,
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
                                                                  ? BuyV2Colors
                                                                        .green
                                                                  : BuyV2Colors
                                                                        .navy,
                                                              size: 16,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                double.infinity,
                                                            child: Text(
                                                              category.label,
                                                              key: ValueKey(
                                                                'buy-category-label-'
                                                                '${category.id}',
                                                              ),
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color:
                                                                    BuyV2Colors
                                                                        .ink,
                                                                fontSize: 10,
                                                                height: 1.05,
                                                                fontWeight:
                                                                    selected
                                                                    ? FontWeight
                                                                          .w900
                                                                    : FontWeight
                                                                          .w700,
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
                                                          Icons
                                                              .check_circle_rounded,
                                                          color:
                                                              BuyV2Colors.green,
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
          ),
        ),
      ),
    );
  }
}

class _CatalogueCategoryBackdrop extends StatelessWidget {
  const _CatalogueCategoryBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('buy-category-sheet-backdrop-owner'),
      child: KeyedSubtree(
        key: const ValueKey('buy-category-sheet-opaque-content'),
        child: child,
      ),
    );
  }
}

class _CatalogueCategoryEmptyState extends StatelessWidget {
  const _CatalogueCategoryEmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Semantics(
      key: const ValueKey('buy-category-empty'),
      container: true,
      explicitChildNodes: true,
      label: 'No categories match. Clear category search.',
      child: keyboardVisible
          ? _CatalogueCategoryKeyboardEmptyState(onClear: onClear)
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: BuyV2Colors.softOrange,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        color: BuyV2Colors.navy,
                        size: 23,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No categories match',
                      style: TextStyle(
                        color: BuyV2Colors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Try a different category name.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: BuyV2Colors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _CatalogueCategoryClearButton(onClear: onClear),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CatalogueCategoryKeyboardEmptyState extends StatelessWidget {
  const _CatalogueCategoryKeyboardEmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No categories match',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: BuyV2Colors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Try a different category name.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: BuyV2Colors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _CatalogueCategoryClearButton(onClear: onClear, compact: true),
          ],
        ),
      ),
    );
  }
}

class _CatalogueCategoryClearButton extends StatelessWidget {
  const _CatalogueCategoryClearButton({
    required this.onClear,
    this.compact = false,
  });

  final VoidCallback onClear;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const ValueKey('buy-category-empty-clear'),
      onPressed: onClear,
      style: compact
          ? OutlinedButton.styleFrom(
              minimumSize: const Size(116, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            )
          : null,
      icon: const Icon(Icons.refresh_rounded, size: 17),
      label: const Text('Clear search'),
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
    void activate() {
      HapticFeedback.selectionClick();
      onTap();
    }

    return Semantics(
      label: badge == null ? label : '$label, $badge saved',
      button: true,
      excludeSemantics: true,
      onTap: activate,
      child: IconButton(
        onPressed: activate,
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
          child: BuyV2FiniteVisualTransition(
            key: const ValueKey('buy-saved-filter-icon-motion'),
            stateKey: icon,
            ownerSize: const Size.square(19),
            child: Icon(icon, size: 19),
          ),
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
    void openSheet() {
      HapticFeedback.selectionClick();
      showBuyV2FilterSheet(
        context,
        session,
        actions: [
          BuyV2FilterSheetAction(
            keyName: 'buy-active-orders-button',
            icon: Icons.local_shipping_outlined,
            title: 'Track active order',
            detail: 'Order ${order.id}',
            onTap: () => session.openTracking(order.id),
          ),
          if (session.destination == BuyV2Destination.shop)
            BuyV2FilterSheetAction(
              keyName: 'buy-household-basket-button',
              icon: Icons.shopping_basket_outlined,
              title: 'Monthly home basket',
              detail: 'Review a ready household list',
              onTap: () {
                showBuyV2HouseholdBasket(context, session);
              },
            ),
          if (session.destination == BuyV2Destination.medicine)
            BuyV2FilterSheetAction(
              keyName: 'buy-prescription-button',
              icon: Icons.description_outlined,
              title: 'Prescriptions',
              detail: 'Review saved prescription access',
              onTap: () {
                showBuyV2PrescriptionSheet(context, session);
              },
            ),
        ],
      );
    }

    return Semantics(
      label:
          'Open ${session.destination.label} tools and filters. '
          'Current ${_filterLabel(filterOptions, session.selectedFilter)}',
      button: true,
      excludeSemantics: true,
      onTap: openSheet,
      child: IconButton(
        key: const ValueKey('buy-filter-button'),
        onPressed: openSheet,
        tooltip: 'Orders, tools and filters',
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          maximumSize: const Size(44, 44),
          backgroundColor: session.selectedFilter == null
              ? Colors.white
              : BuyV2Colors.softOrange,
          foregroundColor: BuyV2Colors.navy,
          side: const BorderSide(color: BuyV2Colors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: Badge(
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

String _filterLabel(List<(String, String)> options, String? selectedFilter) =>
    options
        .firstWhere(
          (option) =>
              (option.$1 == 'any' && selectedFilter == null) ||
              option.$1 == selectedFilter,
          orElse: () => options.first,
        )
        .$2;

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
) async {
  final action = await showModalBottomSheet<_HouseholdBasketAction>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: BuyV2InfoSheetMotion.resolve(context),
    builder: (sheetContext) => _HouseholdBasket(
      onClose: () => Navigator.of(sheetContext).pop(),
      onSeeProducts: () =>
          Navigator.of(sheetContext).pop(_HouseholdBasketAction.seeProducts),
      onAddToCart: () =>
          Navigator.of(sheetContext).pop(_HouseholdBasketAction.addToCart),
    ),
  );
  switch (action) {
    case _HouseholdBasketAction.seeProducts:
      session.chooseCategory('all');
      session.showNotice('Basket products are shown below');
      break;
    case _HouseholdBasketAction.addToCart:
      final featured = BuyV2Catalogue.products
          .where((product) => product.destination == BuyV2Destination.shop)
          .take(4);
      for (final product in featured) {
        session.addProduct(product.id);
      }
      break;
    case null:
      break;
  }
}

Future<void> showBuyV2SavedProducts(
  BuildContext context,
  BuyV2Session session,
) async {
  final destination = session.destination;
  final selectedProductId = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: BuyV2InfoSheetMotion.resolve(context),
    builder: (sheetContext) => _SavedProductsSheet(
      session: session,
      destination: destination,
      onClose: () => Navigator.of(sheetContext).pop(),
      onOpenProduct: (productId) => Navigator.of(sheetContext).pop(productId),
    ),
  );
  if (selectedProductId != null) {
    session.openProduct(selectedProductId);
  }
}

enum _HouseholdBasketAction { seeProducts, addToCart }

class _BuyV2InfoSheetHeader extends StatelessWidget {
  const _BuyV2InfoSheetHeader({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onClose,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: BuyV2Colors.softOrange,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: BuyV2Colors.navy, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.buyTitle.copyWith(fontSize: 19)),
                const SizedBox(height: 2),
                Text(detail, style: context.buyMeta),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          key: ValueKey('buy-info-sheet-close-$title'),
          onPressed: onClose,
          tooltip: 'Close $title',
          style: IconButton.styleFrom(
            minimumSize: const Size.square(BuyV2Metrics.minimumTap),
            side: const BorderSide(color: BuyV2Colors.line),
          ),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _SavedProductsSheet extends StatelessWidget {
  const _SavedProductsSheet({
    required this.session,
    required this.destination,
    required this.onClose,
    required this.onOpenProduct,
  });

  final BuyV2Session session;
  final BuyV2Destination destination;
  final VoidCallback onClose;
  final ValueChanged<String> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final sheetHeight = (MediaQuery.sizeOf(context).height * .58)
        .clamp(300.0, 420.0)
        .toDouble();
    return Semantics(
      key: const ValueKey('buy-saved-products-info-sheet'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Saved products in ${destination.label}',
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AnimatedBuilder(
            animation: session,
            builder: (context, _) {
              final saved = session.savedProductsFor(destination);
              final ownerKey = saved.map((product) => product.id).join('|');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BuyV2InfoSheetHeader(
                    icon: Icons.bookmarks_rounded,
                    title: 'Saved products',
                    detail: '${destination.label} · ${saved.length} saved',
                    onClose: onClose,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: AnimatedSwitcher(
                      key: const ValueKey('buy-saved-products-owner-motion'),
                      duration: BuyV2InfoSheetMotion.resolveContentDuration(
                        context,
                      ),
                      reverseDuration:
                          BuyV2InfoSheetMotion.resolveContentDuration(context),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, .025),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: saved.isEmpty
                          ? _SavedProductsEmptyState(
                              key: const ValueKey(
                                'buy-saved-products-empty-state',
                              ),
                              destination: destination,
                            )
                          : ListView.separated(
                              key: ValueKey(
                                'buy-saved-products-list-$ownerKey',
                              ),
                              padding: EdgeInsets.zero,
                              itemCount: saved.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final product = saved[index];
                                return _SavedProductInfoRow(
                                  product: product,
                                  onOpen: () => onOpenProduct(product.id),
                                  onRemove: () =>
                                      session.toggleSaved(product.id),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SavedProductsEmptyState extends StatelessWidget {
  const _SavedProductsEmptyState({super.key, required this.destination});

  final BuyV2Destination destination;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: BuyV2Colors.softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_add_outlined,
                color: BuyV2Colors.navy,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No Saved products yet',
              textAlign: TextAlign.center,
              style: context.buyTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Save products from the ${destination.label} grid for instant access.',
              textAlign: TextAlign.center,
              style: context.buyMeta,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedProductInfoRow extends StatelessWidget {
  const _SavedProductInfoRow({
    required this.product,
    required this.onOpen,
    required this.onRemove,
  });

  final BuyV2Product product;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: BuyV2Colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Open ${product.title}',
              onTap: onOpen,
              excludeSemantics: true,
              child: InkWell(
                key: ValueKey('buy-saved-${product.id}'),
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: BuyV2Colors.softBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          color: BuyV2Colors.navy,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BuyV2Colors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.pack} · ${buyV2Money(product.price)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyMeta,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: ValueKey('buy-unsave-${product.id}'),
            tooltip: 'Remove ${product.title} from Saved',
            onPressed: onRemove,
            icon: const Icon(Icons.bookmark_remove_rounded),
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

class _HouseholdBasket extends StatelessWidget {
  const _HouseholdBasket({
    required this.onClose,
    required this.onSeeProducts,
    required this.onAddToCart,
  });

  final VoidCallback onClose;
  final VoidCallback onSeeProducts;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final compactActions =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final seeProducts = OutlinedButton.icon(
      key: const ValueKey('buy-household-see-products'),
      onPressed: onSeeProducts,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(BuyV2Metrics.minimumTap),
        side: const BorderSide(color: BuyV2Colors.line),
      ),
      icon: const Icon(Icons.grid_view_rounded, size: 18),
      label: const Text('See 12 products'),
    );
    final addToCart = FilledButton.icon(
      key: const ValueKey('buy-household-add-to-cart'),
      onPressed: onAddToCart,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(BuyV2Metrics.minimumTap),
      ),
      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
      label: const Text('Add basket to cart'),
    );
    return Semantics(
      key: const ValueKey('buy-household-basket-info-sheet'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Monthly home basket',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BuyV2InfoSheetHeader(
              icon: Icons.shopping_basket_outlined,
              title: 'Monthly home basket',
              detail: 'A ready 30-day household plan',
              onClose: onClose,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: BuyV2Colors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'HOUSEHOLD BASKET',
                          style: context.buyMeta.copyWith(
                            color: BuyV2Colors.navy,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: BuyV2Colors.softGreen,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Save ₹415',
                          style: TextStyle(
                            color: BuyV2Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HouseholdBasketFact(
                        icon: Icons.inventory_2_outlined,
                        label: '12 products',
                      ),
                      _HouseholdBasketFact(
                        icon: Icons.layers_outlined,
                        label: '21 packs',
                      ),
                      _HouseholdBasketFact(
                        icon: Icons.calendar_month_outlined,
                        label: '30 days',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Review the products first, or add the existing basket to your cart.',
                    style: context.buyMeta,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (compactActions) ...[
              SizedBox(width: double.infinity, child: seeProducts),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: addToCart),
            ] else
              Row(
                children: [
                  Expanded(child: seeProducts),
                  const SizedBox(width: 8),
                  Expanded(child: addToCart),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HouseholdBasketFact extends StatelessWidget {
  const _HouseholdBasketFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: BuyV2Colors.softOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: BuyV2Colors.navy, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: BuyV2Colors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
        const compactCards = true;
        final columns = savedOnly
            ? constraints.maxWidth >= 320
                  ? 2
                  : 1
            : accessibleText && constraints.maxWidth < 460
            ? 2
            : constraints.maxWidth >= 320
            ? 3
            : 2;
        final featuredProducts = showPromotions
            ? products.take(6).toList(growable: false)
            : const <BuyV2Product>[];
        final prescriptionMatches =
            showPromotions && session.destination == BuyV2Destination.medicine
            ? session.matchedPrescriptionProducts
            : const <BuyV2Product>[];
        final gridProducts = showPromotions
            ? products.skip(featuredProducts.length).toList(growable: false)
            : products;
        final tileHeight = savedOnly
            ? accessibleText
                  ? 270.0
                  : 260.0
            : accessibleText
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
            if (prescriptionMatches.isNotEmpty)
              SliverToBoxAdapter(
                child: _PrescriptionMatchLane(
                  session: session,
                  products: prescriptionMatches,
                ),
              ),
            if (showPromotions)
              SliverToBoxAdapter(
                child: _FeaturedProductRail(
                  session: session,
                  products: featuredProducts,
                  accessibleText: accessibleText,
                ),
              ),
            if (showPromotions)
              SliverToBoxAdapter(
                child: BuyV2SponsoredSlot(
                  content: session.sponsoredContentFor(
                    BuyV2SponsoredPlacement.catalogueAfterDiscovery,
                  ),
                ),
              ),
            if (showPromotions && gridProducts.isNotEmpty)
              const SliverToBoxAdapter(child: _CatalogueSectionHeader()),
            if (savedOnly)
              SliverToBoxAdapter(
                child: _SavedDecisionShelf(
                  session: session,
                  products: products,
                ),
              ),
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
                  laneCount: savedOnly ? 1 : null,
                  savedContext: savedOnly,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SavedDecisionShelf extends StatelessWidget {
  const _SavedDecisionShelf({required this.session, required this.products});

  final BuyV2Session session;
  final List<BuyV2Product> products;

  @override
  Widget build(BuildContext context) {
    final destination = session.destination;
    final savedTitle = switch (destination) {
      BuyV2Destination.shop => 'Saved in Shop',
      BuyV2Destination.wholesale => 'Saved for Wholesale',
      BuyV2Destination.medicine => 'Saved in Medicine',
      BuyV2Destination.orders => 'Saved in Shop',
    };
    final productLabel = switch (destination) {
      BuyV2Destination.shop => products.length == 1 ? 'product' : 'products',
      BuyV2Destination.wholesale =>
        products.length == 1 ? 'trade product' : 'trade products',
      BuyV2Destination.medicine =>
        products.length == 1 ? 'medicine' : 'medicines',
      BuyV2Destination.orders => products.length == 1 ? 'product' : 'products',
    };
    final hasPrescriptionGate =
        destination == BuyV2Destination.medicine &&
        products.any(
          (product) =>
              product.requiresPrescription &&
              !session.isPrescriptionApproved(product.id),
        );

    return Semantics(
      key: const ValueKey('buy-saved-decision-shelf'),
      container: true,
      label: '$savedTitle. ${products.length} $productLabel.',
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 2),
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BuyV2Colors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BuyV2ThemeScope.of(context).softAccent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.bookmarks_rounded,
                    color: BuyV2Colors.navy,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        savedTitle,
                        style: const TextStyle(
                          color: BuyV2Colors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${products.length} $productLabel · ready for Cart',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyMeta.copyWith(fontSize: 8),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const ValueKey('buy-saved-clear'),
                  onPressed: () => _confirmClearSaved(
                    context,
                    session,
                    destination,
                    savedTitle,
                    productLabel,
                    products.length,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: BuyV2Colors.muted,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Changed your mind?'),
                      Text(
                        'Clear list',
                        style: TextStyle(
                          color: BuyV2Colors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasPrescriptionGate) ...[
              const SizedBox(height: 4),
              Text(
                'A prescription medicine stays Saved until its prescription '
                'is linked.',
                style: context.buyMeta.copyWith(
                  color: BuyV2Colors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            if (hasPrescriptionGate) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('buy-saved-review-prescription'),
                  onPressed: () => showBuyV2PrescriptionSheet(context, session),
                  icon: const Icon(
                    Icons.medical_information_outlined,
                    size: 17,
                  ),
                  label: const Text('Review prescription'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmClearSaved(
  BuildContext context,
  BuyV2Session session,
  BuyV2Destination destination,
  String savedTitle,
  String productLabel,
  int productCount,
) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: BuyV2SavedClearSheetMotion.resolve(context),
    builder: (sheetContext) => _SavedClearDecisionSheet(
      savedTitle: savedTitle,
      productLabel: productLabel,
      productCount: productCount,
      destination: destination,
      onKeep: () => Navigator.of(sheetContext).pop(false),
      onClear: () => Navigator.of(sheetContext).pop(true),
    ),
  );
  if (confirmed == true) {
    session.clearSavedProducts(destination);
  }
}

class _SavedClearDecisionSheet extends StatelessWidget {
  const _SavedClearDecisionSheet({
    required this.savedTitle,
    required this.productLabel,
    required this.productCount,
    required this.destination,
    required this.onKeep,
    required this.onClear,
  });

  final String savedTitle;
  final String productLabel;
  final int productCount;
  final BuyV2Destination destination;
  final VoidCallback onKeep;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final destinationNoun = switch (destination) {
      BuyV2Destination.shop => 'Shop',
      BuyV2Destination.wholesale => 'Wholesale',
      BuyV2Destination.medicine => 'Medicine',
      BuyV2Destination.orders => 'Shop',
    };
    return Semantics(
      key: const ValueKey('buy-saved-clear-sheet'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Clear $savedTitle',
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BuyV2ThemeScope.of(context).softAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bookmark_remove_outlined,
                    color: BuyV2Colors.navy,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clear $savedTitle?',
                        style: context.buyTitle.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Remove $productCount saved $productLabel from '
                        '$destinationNoun. Items already in Cart stay there.',
                        style: context.buyMeta.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('buy-saved-clear-close'),
                  tooltip: 'Keep saved',
                  onPressed: onKeep,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('buy-saved-keep'),
                    onPressed: onKeep,
                    child: const Text('Keep saved'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('buy-saved-confirm-clear'),
                    onPressed: onClear,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB3261E),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear list'),
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

class _HorizontalProductGrid extends StatelessWidget {
  const _HorizontalProductGrid({
    required this.session,
    required this.products,
    required this.cardWidth,
    required this.tileHeight,
    required this.storageKey,
    this.compact = true,
    this.laneCount,
    this.savedContext = false,
  });

  final BuyV2Session session;
  final List<BuyV2Product> products;
  final double cardWidth;
  final double tileHeight;
  final String storageKey;
  final bool compact;
  final int? laneCount;
  final bool savedContext;

  @override
  Widget build(BuildContext context) {
    final resolvedLaneCount = laneCount ?? (products.length > 1 ? 2 : 1);
    return Semantics(
      key: const ValueKey('buy-horizontal-product-grid'),
      container: true,
      label:
          'Products in $resolvedLaneCount independently scrollable '
          '${resolvedLaneCount == 1 ? 'lane' : 'lanes'}.',
      child: SizedBox(
        height: (tileHeight * resolvedLaneCount) + 14,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 10),
          child: Column(
            children: [
              for (
                var laneIndex = 0;
                laneIndex < resolvedLaneCount;
                laneIndex++
              ) ...[
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
                      itemCount:
                          (products.length -
                              laneIndex +
                              resolvedLaneCount -
                              1) ~/
                          resolvedLaneCount,
                      separatorBuilder: (_, _) => const SizedBox(width: 7),
                      itemBuilder: (context, index) {
                        final productIndex =
                            (index * resolvedLaneCount) + laneIndex;
                        return SizedBox(
                          width: cardWidth,
                          child: BuyV2ProductCard(
                            session: session,
                            product: products[productIndex],
                            compact: compact,
                            savedContext: savedContext,
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
          sequenceIndex: 0,
          onTap: () => showBuyV2HouseholdBasket(context, session),
        ),
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-shop-wholesale'),
          title: 'Buying for a business?',
          detail: 'Compare established wholesale packs',
          icon: Icons.storefront_outlined,
          accent: BuyV2Colors.green,
          sequenceIndex: 1,
          onTap: () => session.openDestination(BuyV2Destination.wholesale),
        ),
      ],
      BuyV2Destination.wholesale => [
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-wholesale-restock'),
          title: 'Flexible restocking',
          detail: 'See products with flexible minimum packs',
          icon: Icons.inventory_2_outlined,
          sequenceIndex: 0,
          onTap: () => session.chooseFilter('moq'),
        ),
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-wholesale-shop'),
          title: 'Shopping for home?',
          detail: 'Return to retail packs in Shop',
          icon: Icons.shopping_bag_outlined,
          accent: BuyV2Colors.green,
          sequenceIndex: 1,
          onTap: () => session.openDestination(BuyV2Destination.shop),
        ),
      ],
      BuyV2Destination.medicine => [
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-medicine-prescription'),
          title: 'Prescription centre',
          detail: 'Add or use a saved prescription',
          icon: Icons.description_outlined,
          sequenceIndex: 0,
          onTap: () => showBuyV2PrescriptionSheet(context, session),
        ),
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-medicine-wellness'),
          title: 'Everyday wellness',
          detail: 'Browse no-prescription care',
          icon: Icons.health_and_safety_outlined,
          accent: BuyV2Colors.green,
          sequenceIndex: 1,
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

class _PrescriptionMatchLane extends StatelessWidget {
  const _PrescriptionMatchLane({required this.session, required this.products});

  final BuyV2Session session;
  final List<BuyV2Product> products;

  @override
  Widget build(BuildContext context) {
    final stateKey = products.map((product) => product.id).join('|');
    final medicineLabel = products.length == 1 ? 'medicine' : 'medicines';
    return BuyV2FiniteIncomingTransition(
      key: const ValueKey('buy-prescription-match-lane-motion'),
      stateKey: 'prescription-matches-$stateKey',
      child: Container(
        key: const ValueKey('buy-prescription-match-lane'),
        margin: const EdgeInsets.fromLTRB(6, 4, 6, 6),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: BuyV2Colors.softGreen,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: BuyV2Colors.green.withValues(alpha: .26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.medical_information_outlined,
                  size: 19,
                  color: BuyV2Colors.green,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Prescription matches',
                    style: context.buyTitle.copyWith(fontSize: 15),
                  ),
                ),
                Text(
                  '${products.length} $medicineLabel',
                  style: context.buyMeta.copyWith(
                    color: BuyV2Colors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Matched in this session. Pharmacist review is still required '
              'before payment. Not medical advice.',
              style: context.buyMeta,
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 58,
              child: ListView.separated(
                key: const ValueKey('buy-prescription-match-list'),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final product = products[index];
                  void openProduct() {
                    HapticFeedback.selectionClick();
                    session.openProduct(product.id);
                  }

                  return Semantics(
                    key: ValueKey(
                      'buy-prescription-match-product-${product.id}',
                    ),
                    button: true,
                    label:
                        'View prescription-matched ${product.title} product '
                        'details. ${product.pack}. '
                        'Pharmacist review required. Not medical advice.',
                    excludeSemantics: true,
                    onTap: openProduct,
                    child: BuyV2IntentDepth(
                      key: ValueKey(
                        'buy-prescription-match-depth-${product.id}',
                      ),
                      spatial: true,
                      child: OutlinedButton(
                        key: ValueKey(
                          'buy-prescription-match-action-${product.id}',
                        ),
                        onPressed: openProduct,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(238, 54),
                          maximumSize: const Size(286, 58),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          foregroundColor: BuyV2Colors.navy,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: BuyV2Colors.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: Text(
                          '${product.title}\n${product.pack} · '
                          '${buyV2Money(product.price)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1.22,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
    final facts = session.productFactsFor(product);
    final quantity = session.quantityFor(product.id);
    final rxBlocked =
        product.requiresPrescription &&
        !session.isPrescriptionApproved(product.id);
    return BuyV2IntentDepth(
      key: ValueKey('buy-featured-depth-${product.id}'),
      spatial: true,
      child: AnimatedScale(
        key: ValueKey('buy-featured-product-${product.id}'),
        scale: _pressed ? BuyV2Motion.pressScale : 1,
        duration: BuyV2Motion.resolved(context, BuyV2Motion.press),
        curve: Curves.easeOutCubic,
        child: Semantics(
          label:
              '${product.title}, ${product.pack}, ${buyV2Money(facts.price)}, '
              '${facts.deliveryPromise}, fulfilled by ${facts.partner}',
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
                                  buyV2Money(facts.price),
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
                                    '${facts.partner} · '
                                    '${_compactDeliveryPromise(facts.deliveryPromise)}',
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
                productTitle: product.title,
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
    this.savedContext = false,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final bool compact;
  final bool savedContext;

  @override
  Widget build(BuildContext context) {
    final facts = session.productFactsFor(product);
    final quantity = session.quantityFor(product.id);
    final rxBlocked =
        product.requiresPrescription &&
        !session.isPrescriptionApproved(product.id);
    return BuyV2IntentDepth(
      key: ValueKey('buy-product-depth-${product.id}'),
      spatial: true,
      child: Semantics(
        label:
            '${product.title}, ${product.pack}, ${buyV2Money(facts.price)}, '
            '${facts.deliveryPromise}, fulfilled by ${facts.partner}',
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
                    _ProductVisual(
                      product: product,
                      compact: compact,
                      reservedActionWidth: savedContext ? 84 : 42,
                    ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        buyV2Money(facts.price),
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
                                color: facts.stale
                                    ? BuyV2Colors.softOrange
                                    : BuyV2Colors.softGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        facts.stale
                                            ? Icons.sync_problem_rounded
                                            : facts.isLive
                                            ? Icons.bolt_rounded
                                            : Icons.schedule_rounded,
                                        size: 11,
                                        color: facts.stale
                                            ? BuyV2Colors.orange
                                            : BuyV2Colors.green,
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          compact
                                              ? '${facts.partner} · '
                                                    '${_compactDeliveryPromise(facts.deliveryPromise)}'
                                              : facts.deliveryPromise,
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
                                      facts.partner,
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
                                      key: ValueKey(
                                        'buy-quantity-${product.id}',
                                      ),
                                      productTitle: product.title,
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
                                          key: ValueKey(
                                            'buy-add-${product.id}',
                                          ),
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
                                                        : const Color(
                                                            0x66000080,
                                                          ),
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
                  child: _ProductSaveButton(
                    session: session,
                    product: product,
                    showRemoveLabel: savedContext,
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

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    super.key,
    required this.productTitle,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String productTitle;
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
            child: Semantics(
              label: 'Decrease $productTitle quantity from $quantity',
              button: true,
              excludeSemantics: true,
              onTap: onDecrease,
              child: IconButton(
                tooltip: 'Remove one',
                onPressed: onDecrease,
                icon: const Icon(Icons.remove, size: 17),
                color: BuyV2Colors.navy,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          BuyV2FiniteValueTransition(
            key: const ValueKey('buy-grid-quantity-value-motion'),
            stateKey: quantity,
            text: '$quantity',
            ownerSize: const Size(24, 24),
            style: const TextStyle(
              color: BuyV2Colors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: Semantics(
              label: 'Increase $productTitle quantity from $quantity',
              button: true,
              excludeSemantics: true,
              onTap: onIncrease,
              child: IconButton(
                tooltip: 'Add one',
                onPressed: onIncrease,
                icon: const Icon(Icons.add, size: 17),
                color: BuyV2Colors.navy,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSaveButton extends StatelessWidget {
  const _ProductSaveButton({
    required this.session,
    required this.product,
    this.showRemoveLabel = false,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final bool showRemoveLabel;

  @override
  Widget build(BuildContext context) {
    final saved = session.isSaved(product.id);
    void toggleSaved() {
      HapticFeedback.selectionClick();
      session.toggleSaved(product.id);
    }

    if (showRemoveLabel && saved) {
      return Semantics(
        key: ValueKey('buy-save-${product.id}'),
        button: true,
        label: 'Remove ${product.title} from Saved',
        child: Tooltip(
          message: 'Remove ${product.title} from Saved',
          child: InkWell(
            onTap: toggleSaved,
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 62,
              height: 44,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: BuyV2Colors.orange.withValues(alpha: .22),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark_remove_outlined,
                          size: 12,
                          color: BuyV2Colors.orange,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Remove',
                          style: TextStyle(
                            color: BuyV2Colors.muted,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return IconButton(
      key: ValueKey('buy-save-${product.id}'),
      tooltip: saved
          ? 'Remove ${product.title} from Saved'
          : 'Save ${product.title}',
      onPressed: toggleSaved,
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        maximumSize: const Size(44, 44),
        foregroundColor: saved ? BuyV2Colors.orange : BuyV2Colors.navy,
        shape: const CircleBorder(),
      ),
      icon: BuyV2FiniteVisualTransition(
        key: ValueKey('buy-save-visual-${product.id}'),
        stateKey: saved,
        ownerSize: const Size.square(27),
        child: Container(
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
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({
    required this.product,
    required this.compact,
    this.reservedActionWidth = 42,
  });

  final BuyV2Product product;
  final bool compact;
  final double reservedActionWidth;

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
            right: compact ? reservedActionWidth : 6,
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
