import 'package:flutter/material.dart';

import '../../../core/design/mool_colors.dart';
import '../../buy/buy_v2_models.dart';
import '../../../ui_v2/buy/buy_v2_design.dart';

/// Buy-style category window with Store catalogue inputs, never a customer cart.
class StoreCatalogueCategories extends StatefulWidget {
  const StoreCatalogueCategories({
    super.key,
    required this.selected,
    required this.counts,
    required this.label,
    required this.stockOnly,
    this.stockFilter = '',
    this.stockFilters = const {},
  });
  final String selected;
  final Map<String, int> counts;
  final String Function(String) label;
  final bool stockOnly;
  final String stockFilter;
  final Map<String, String> stockFilters;
  @override
  State<StoreCatalogueCategories> createState() =>
      _StoreCatalogueCategoriesState();
}

class _StoreCatalogueCategoriesState extends State<StoreCatalogueCategories> {
  String _query = '';
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.counts.keys.toList()..sort();
    final categories = ['', ...ids];
    final publicLabels = {
      for (final item in [
        ...BuyV2Catalogue.shopCategories,
        ...BuyV2Catalogue.wholesaleCategories,
      ])
        item.id: item.label,
    };
    String label(String key) =>
        key.isEmpty ? 'All categories' : publicLabels[key] ?? widget.label(key);
    final filtered = categories
        .where((key) => label(key).toLowerCase().contains(_query.toLowerCase()))
        .toList();
    IconData icon(String id) => switch (id) {
      '' => Icons.grid_view_rounded,
      'cooking-oil' || 'oils-ghee' => Icons.water_drop_outlined,
      'flour-grains' ||
      'flour-rice-grains' ||
      'dals-staples' => Icons.grass_outlined,
      'salt-spices' || 'ground-spices' || 'whole-spices' => Icons.eco_outlined,
      'fruits-vegetables' => Icons.local_florist_outlined,
      'dairy-bakery' => Icons.bakery_dining_outlined,
      _ => Icons.category_outlined,
    };
    return FractionallySizedBox(
      heightFactor: 1,
      child: Material(
        key: const Key('work-catalogue-category-window'),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 4, 4),
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined, color: MoolColors.navy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.stockOnly
                            ? 'Store stock categories'
                            : 'Catalogue categories',
                        style: const TextStyle(
                          fontSize: 16,
                          color: MoolColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.stockFilters.isNotEmpty)
                      PopupMenuButton<String>(
                        key: const Key('work-catalogue-filter'),
                        tooltip: 'Filter stock',
                        initialValue: widget.stockFilter,
                        icon: Icon(
                          Icons.tune_rounded,
                          color: widget.stockFilter.isEmpty
                              ? MoolColors.navy
                              : MoolColors.orange,
                        ),
                        onSelected: (value) =>
                            Navigator.pop(context, '#filter:$value'),
                        itemBuilder: (_) => [
                          for (final entry in widget.stockFilters.entries)
                            PopupMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                        ],
                      ),
                    IconButton(
                      tooltip: 'Close categories',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  key: const Key('work-catalogue-category-search'),
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Find a category',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: const Key(
                              'work-catalogue-category-search-clear',
                            ),
                            tooltip: 'Clear category search',
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.clear_rounded, size: 18),
                          ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 48,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching categories'))
                    : LayoutBuilder(
                        builder: (context, size) {
                          final scale = MediaQuery.textScalerOf(
                            context,
                          ).scale(1);
                          final columns = scale > 1.5
                              ? 1
                              : size.maxWidth < 350
                              ? 2
                              : 3;
                          return GridView.builder(
                            key: const Key('work-catalogue-category-grid'),
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisExtent: widget.stockOnly
                                      ? 104 + 36 * (scale - 1)
                                      : 68 + 36 * scale,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemBuilder: (context, index) {
                              final id = filtered[index];
                              final selected = id == widget.selected;
                              final count = id.isEmpty
                                  ? widget.counts.values.fold<int>(
                                      0,
                                      (a, b) => a + b,
                                    )
                                  : widget.counts[id]!;
                              return Semantics(
                                selected: selected,
                                button: true,
                                child: Material(
                                  color: selected
                                      ? (widget.stockOnly
                                            ? const Color(0xFFFDF0E1)
                                            : const Color(0xffedf0ff))
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      widget.stockOnly ? 16 : 14,
                                    ),
                                    side: BorderSide(
                                      color: selected
                                          ? (widget.stockOnly
                                                ? MoolColors.orange
                                                : MoolColors.navy)
                                          : MoolColors.line,
                                    ),
                                  ),
                                  child: InkWell(
                                    key: Key('work-catalogue-category-$id'),
                                    onTap: () => Navigator.pop(context, id),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (widget.stockOnly)
                                            _StockCategoryThumbnail(
                                              id: id,
                                              label: label(id),
                                            )
                                          else
                                            Icon(
                                              icon(id),
                                              size: 22,
                                              color: MoolColors.navy,
                                            ),
                                          if (widget.stockOnly)
                                            const SizedBox(height: 5),
                                          Text(
                                            label(id),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: widget.stockOnly
                                                  ? 10
                                                  : 12,
                                              fontWeight: selected
                                                  ? FontWeight.w900
                                                  : FontWeight.w700,
                                              color: MoolColors.navy,
                                            ),
                                          ),
                                          Text(
                                            '$count ${count == 1 ? 'product' : 'products'}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: MoolColors.muted,
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
    );
  }
}

// Cursor Buy picker presentation, adapted to saved Store category IDs. Reuses
// the existing bundled category atlas and crop model; no product-photo claim.
class _StockCategoryThumbnail extends StatelessWidget {
  const _StockCategoryThumbnail({required this.id, required this.label});
  final String id, label;
  @override
  Widget build(BuildContext context) {
    final entry = switch (id) {
      'fruits-vegetables' => (BuyV2ProductPackshot.categoryAtlasAPath, 0),
      'dairy-bakery' => (BuyV2ProductPackshot.categoryAtlasAPath, 1),
      'eggs-poultry' => (BuyV2ProductPackshot.categoryAtlasAPath, 2),
      'meat-seafood' => (BuyV2ProductPackshot.categoryAtlasAPath, 3),
      'flour-grains' ||
      'flour-rice-grains' ||
      'dals-staples' => (BuyV2ProductPackshot.categoryAtlasAPath, 4),
      'cooking-oil' ||
      'oils-ghee' => (BuyV2ProductPackshot.categoryAtlasAPath, 5),
      'salt-spices' ||
      'ground-spices' => (BuyV2ProductPackshot.categoryAtlasAPath, 6),
      'whole-spices' => (BuyV2ProductPackshot.categoryAtlasAPath, 7),
      'breakfast-cereals' => (BuyV2ProductPackshot.categoryAtlasAPath, 8),
      'instant-foods' => (BuyV2ProductPackshot.categoryAtlasAPath, 9),
      'biscuits-chocolate' => (BuyV2ProductPackshot.categoryAtlasAPath, 10),
      'namkeen-chips' => (BuyV2ProductPackshot.categoryAtlasAPath, 11),
      'tea-coffee' => (BuyV2ProductPackshot.categoryAtlasBPath, 0),
      'juices-water' => (BuyV2ProductPackshot.categoryAtlasBPath, 1),
      'frozen-foods' => (BuyV2ProductPackshot.categoryAtlasBPath, 2),
      'icecream-cheese' => (BuyV2ProductPackshot.categoryAtlasBPath, 3),
      'oral-care' => (BuyV2ProductPackshot.categoryAtlasBPath, 4),
      'bath-hand-care' => (BuyV2ProductPackshot.categoryAtlasBPath, 5),
      'hair-care' => (BuyV2ProductPackshot.categoryAtlasBPath, 6),
      'skin-care' => (BuyV2ProductPackshot.categoryAtlasBPath, 7),
      'surface-cleaners' => (BuyV2ProductPackshot.categoryAtlasBPath, 8),
      'laundry-dishwash' => (BuyV2ProductPackshot.categoryAtlasBPath, 9),
      'air-waste-care' => (BuyV2ProductPackshot.categoryAtlasBPath, 10),
      'diapers-wipes' => (BuyV2ProductPackshot.categoryAtlasBPath, 11),
      'baby-care' => (BuyV2ProductPackshot.categoryAtlasCPath, 0),
      'health-wellness' => (BuyV2ProductPackshot.categoryAtlasCPath, 1),
      'dog-care' => (BuyV2ProductPackshot.categoryAtlasCPath, 2),
      'cat-care' => (BuyV2ProductPackshot.categoryAtlasCPath, 3),
      'food-storage-packs' ||
      'horeca-food-packs' => (BuyV2ProductPackshot.categoryAtlasCPath, 4),
      'cups-tissues' ||
      'horeca-tableware' => (BuyV2ProductPackshot.categoryAtlasCPath, 5),
      'shop-supplies' ||
      'retail-supplies' => (BuyV2ProductPackshot.categoryAtlasCPath, 6),
      'school-office' ||
      'stationery-office' => (BuyV2ProductPackshot.categoryAtlasCPath, 7),
      'sauces-spreads' => (BuyV2ProductPackshot.categoryAtlasCPath, 8),
      _ => null,
    };
    final source = entry == null
        ? null
        : BuyV2ProductMediaSource(
            assetPath: entry.$1,
            cell: entry.$2,
            kind: BuyV2ProductMediaKind.category,
          );
    final fallback = Icon(
      id.isEmpty ? Icons.apps_rounded : Icons.category_outlined,
      color: MoolColors.navy,
      size: 20,
    );
    const size = 36.0;
    return Semantics(
      image: true,
      label: '$label category illustration',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: ColoredBox(
            color: BuyV2Colors.softBlue,
            child: source == null
                ? fallback
                : Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        left:
                            -source.sourceRect.left *
                            size /
                            source.sourceRect.width,
                        top:
                            -source.sourceRect.top *
                            size /
                            source.sourceRect.height,
                        width:
                            source.atlasSize.width *
                            size /
                            source.sourceRect.width,
                        height:
                            source.atlasSize.height *
                            size /
                            source.sourceRect.height,
                        child: Image.asset(
                          source.assetPath,
                          fit: BoxFit.fill,
                          errorBuilder: (_, _, _) =>
                              SizedBox.square(dimension: size, child: fallback),
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
