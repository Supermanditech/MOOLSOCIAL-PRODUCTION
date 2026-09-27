import 'package:flutter/material.dart';

import '../../../core/design/mool_colors.dart';
import '../../buy/buy_v2_models.dart';

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
    this.editorSelection = false,
  });
  final String selected;
  final Map<String, int> counts;
  final String Function(String) label;
  final bool stockOnly;
  final String stockFilter;
  final Map<String, String> stockFilters;
  final bool editorSelection;
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
    final categories = [if (!widget.editorSelection) '', ...ids];
    final publicLabels = {
      for (final item in [
        ...BuyV2Catalogue.shopCategories,
        ...BuyV2Catalogue.wholesaleCategories,
      ])
        item.id: item.label,
    };
    String label(String key) =>
        key.isEmpty ? 'All categories' : widget.editorSelection
            ? widget.label(key) : publicLabels[key] ?? widget.label(key);
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
      heightFactor: widget.stockOnly || widget.editorSelection
          ? (MediaQuery.orientationOf(context) == Orientation.landscape ||
              MediaQuery.viewInsetsOf(context).bottom > 0 ? 1 : .72) : 1,
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
                        widget.editorSelection ? 'Choose category' : widget.stockOnly
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
                          if (widget.stockOnly || widget.editorSelection) {
                            return ListView.separated(
                              key: const Key('work-catalogue-category-list'),
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const Divider(height: 1, color: MoolColors.line),
                              itemBuilder: (context, index) {
                                final id = filtered[index];
                                final count = id.isEmpty
                                    ? widget.counts.values.fold<int>(0, (a, b) => a + b)
                                    : widget.counts[id]!;
                                return ListTile(
                                  key: Key('work-catalogue-category-$id'),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  minVerticalPadding: 10,
                                  selected: id == widget.selected,
                                  selectedTileColor: const Color(0xFFF0F2F8),
                                  leading: Icon(icon(id), size: 22, color: MoolColors.navy),
                                  title: Text(label(id), style: const TextStyle(fontSize: 14,
                                      color: MoolColors.navy, fontWeight: FontWeight.w600)),
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                    if (!widget.editorSelection) Text('$count',
                                        style: const TextStyle(fontSize: 12, color: MoolColors.muted)),
                                    if (id == widget.selected) const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(Icons.check, size: 18, color: MoolColors.navy)),
                                  ]),
                                  onTap: () => Navigator.pop(context, id),
                                );
                              },
                            );
                          }
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
                                  mainAxisExtent: 68 + 36 * scale,
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
                                      ? const Color(0xffedf0ff)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      14,
                                    ),
                                    side: BorderSide(
                                      color: selected
                                          ? MoolColors.navy
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
                                          Icon(
                                              icon(id),
                                              size: 22,
                                              color: MoolColors.navy,
                                            ),
                                          Text(
                                            label(id),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
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
