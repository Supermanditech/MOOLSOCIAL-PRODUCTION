import 'package:flutter/material.dart';

import '../../../core/design/mool_colors.dart';
import '../../../ui_v2/buy/buy_v2_design.dart';
import '../work_models.dart';
import '../work_stock_export.dart';

// Share the entry's mode callback without introducing another route or draft.
class _StoreAddModeScope extends InheritedWidget {
  const _StoreAddModeScope({
    required this.onSelected,
    required this.enabled,
    required super.child,
  });
  final ValueChanged<int> onSelected;
  final bool enabled;
  @override
  bool updateShouldNotify(_StoreAddModeScope oldWidget) =>
      enabled != oldWidget.enabled || onSelected != oldWidget.onSelected;
}

class _StoreAddModeSelector extends StatelessWidget {
  const _StoreAddModeSelector({
    required this.index,
    required this.onSelected,
    this.enabled = true,
    this.subtitle,
    this.compact = false,
  });
  final int index;
  final ValueChanged<int> onSelected;
  final bool enabled;
  final String? subtitle;
  final bool compact;

  static const labels = ['MoolSocial catalogue', 'Add manually', 'Import CSV'];
  static const modeKeys = ['find', 'enter', 'import'];

  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    key: const Key('work-add-product-options'),
    tooltip: 'Switch product entry method',
    enabled: enabled,
    initialValue: index,
    onSelected: (value) {
      FocusManager.instance.primaryFocus?.unfocus();
      onSelected(value);
    },
    itemBuilder: (_) => [
      for (var i = 0; i < labels.length; i++)
        PopupMenuItem(
          value: i,
          key: Key('work-add-product-${modeKeys[i]}'),
          child: Text(labels[i]),
        ),
    ],
    child: Semantics(
      button: true,
      label: '${labels[index]}. Switch product entry method',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: compact
                          ? MediaQuery.textScalerOf(context).scale(1) > 1.3
                                ? 10
                                : 12
                          : 18,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: MoolColors.navy,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: MoolColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: MoolColors.navy,
            ),
          ],
        ),
      ),
    ),
  );
}

/// One page, three input modes, existing Store product owners.
class StoreAddProductEntryScreen extends StatefulWidget {
  const StoreAddProductEntryScreen({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.catalogue,
    required this.manual,
    required this.importCsv,
    this.downloadCsvTemplate = downloadStoreProductCsvTemplate,
    this.catalogueEditing = false,
    this.onCloseCatalogueEditor,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget catalogue;
  final Widget manual;
  final Future<String?> Function() importCsv;
  final Future<String?> Function() downloadCsvTemplate;
  final bool catalogueEditing;
  final VoidCallback? onCloseCatalogueEditor;

  @override
  State<StoreAddProductEntryScreen> createState() =>
      _StoreAddProductEntryScreenState();
}

class _StoreAddProductEntryScreenState
    extends State<StoreAddProductEntryScreen> {
  bool _importing = false;
  bool _templateBusy = false;
  String? _importStatus;
  Future<void> _downloadTemplate() async {
    if (_templateBusy || _importing) return;
    setState(() {
      _templateBusy = true;
      _importStatus = null;
    });
    try {
      final message = await widget.downloadCsvTemplate();
      if (mounted) setState(() => _importStatus = message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _importStatus = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _importStatus =
              'Could not download the template. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _templateBusy = false);
    }
  }

  Future<void> _import() async {
    if (_importing || _templateBusy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _importing = true;
      _importStatus = null;
    });
    try {
      final status = await widget.importCsv();
      if (mounted) setState(() => _importStatus = status);
    } catch (_) {
      if (mounted) {
        setState(
          () => _importStatus = 'Could not open the file. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = widget.selectedIndex == 0 && !widget.catalogueEditing;
    return Scaffold(
      key: const Key('work-add-product-entry'),
      backgroundColor: Colors.white,
      appBar: catalogue
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              leading: BackButton(
                onPressed: widget.catalogueEditing && widget.selectedIndex == 0
                    ? widget.onCloseCatalogueEditor
                    : () => widget.onSelected(0),
              ),
              title: widget.selectedIndex == 0
                  ? const Text('Review product')
                  : _StoreAddModeSelector(
                      index: widget.selectedIndex,
                      onSelected: widget.onSelected,
                      enabled: !_importing && !_templateBusy,
                    ),
            ),
      body: SafeArea(
        child: _StoreAddModeScope(
          onSelected: widget.onSelected,
          enabled: !_importing && !_templateBusy,
          child: IndexedStack(
            index: widget.selectedIndex,
            children: [widget.catalogue, widget.manual, _csvPanel()],
          ),
        ),
      ),
    );
  }

  Widget _columnGuide(bool required, {bool packFacts = false}) => Column(
    children: [
      for (final entry in WorkspaceProductImport.templateLabels.entries)
        if (WorkspaceProductImport.requiredColumns.contains(entry.key) ==
                required &&
            WorkspaceProductImport.packFieldLabels.containsKey(entry.key) ==
                packFacts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: LayoutBuilder(
              builder: (context, size) {
                final label = Text(
                  entry.value,
                  style: const TextStyle(fontSize: 12, color: MoolColors.navy),
                );
                final name = Text(
                  entry.key,
                  style: const TextStyle(fontSize: 11, color: MoolColors.muted),
                );
                return MediaQuery.textScalerOf(context).scale(1) > 1.5
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [label, name],
                      )
                    : Row(
                        children: [
                          Expanded(child: label),
                          Expanded(child: name),
                        ],
                      );
              },
            ),
          ),
    ],
  );

  Widget _csvPanel() => SingleChildScrollView(
    key: const Key('work-add-product-csv-panel'),
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Add your product list',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: MoolColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'One row per SKU, variant and pack. Up to 10,000 products · 10 MB.',
          style: TextStyle(fontSize: 12, height: 1.4, color: MoolColors.muted),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const Key('work-add-product-choose-csv'),
          onPressed: _importing || _templateBusy ? null : _import,
          icon: const Icon(Icons.upload_file_outlined, size: 20),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(_importing ? 'Opening…' : 'Choose CSV file'),
          ),
        ),
        TextButton.icon(
          key: const Key('work-add-product-download-template'),
          onPressed: _templateBusy || _importing ? null : _downloadTemplate,
          icon: const Icon(Icons.download_outlined, size: 18),
          label: Text(_templateBusy ? 'Downloading…' : 'Download CSV template'),
        ),
        const Text(
          'Review before saving. Importing does not publish products.',
          style: TextStyle(fontSize: 12, height: 1.4, color: MoolColors.muted),
        ),
        if (_importStatus != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _importStatus!,
                key: const Key('work-add-product-import-status'),
                style: const TextStyle(fontSize: 12, color: MoolColors.navy),
              ),
            ),
          ),
        const SizedBox(height: 18),
        const Text(
          'Fill for each SKU',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: MoolColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        _columnGuide(true),
        const SizedBox(height: 6),
        const Text(
          'Purchase cost stays private. Prices use whole rupees, without ₹ or commas. Stock uses whole quantities.',
          style: TextStyle(fontSize: 11, height: 1.5, color: MoolColors.muted),
        ),
        const Divider(height: 24),
        ExpansionTile(
          key: const Key('work-csv-optional-columns'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: const Text(
            'Variant, pricing and stock options',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Include the exact variant when applicable',
            style: TextStyle(fontSize: 11),
          ),
          children: [
            _columnGuide(false),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Use a separate row for each variant and pack. Keep SKU and barcode columns as text to preserve leading zeros. Stock tracking: exactQuantity or availabilityOnly. Available for sale: true or false. Low-stock levels stay private.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: MoolColors.muted,
                ),
              ),
            ),
          ],
        ),
        ExpansionTile(
          key: const Key('work-csv-pack-facts'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: const Text(
            'Product and pack details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Fill missing facts or correct catalogue details',
            style: TextStyle(fontSize: 11),
          ),
          children: [
            const Text(
              'An exact catalogue match keeps its photo and pack facts. Leave these cells blank to keep those facts. Add only applicable details; changes need review before publication.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: MoolColors.muted,
              ),
            ),
            _columnGuide(false, packFacts: true),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Manufacturing and expiry dates belong to each stock batch, not every unit of this SKU.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: MoolColors.muted,
                ),
              ),
            ),
          ],
        ),
        ExpansionTile(
          key: const Key('work-csv-catalogue-settings'),
          tilePadding: EdgeInsets.zero,
          title: const Text(
            'Set once in Store Settings',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'Keep your Store profile, business details, accepted payment methods, UPI and bank setup, delivery coverage and default terms out of this CSV. These belong in Store Settings, not in every product row.\n\nUse product-specific delivery or return details only where that product differs. Never include bank details, payment status or invoice totals in this file.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: MoolColors.muted,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// File review reuses product records and the same editor via [editProduct].
class StoreProductImportReviewScreen extends StatefulWidget {
  const StoreProductImportReviewScreen({
    super.key,
    required this.fileName,
    required this.review,
    required this.editProduct,
    required this.saveProducts,
  });
  final String fileName;
  final WorkspaceProductImport review;
  final Future<WorkspaceCatalogueItem?> Function(WorkspaceCatalogueItem)
  editProduct;
  final Future<String?> Function(List<WorkspaceCatalogueItem>) saveProducts;
  @override
  State<StoreProductImportReviewScreen> createState() =>
      _StoreProductImportReviewScreenState();
}

class _StoreProductImportReviewScreenState
    extends State<StoreProductImportReviewScreen> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _showError(String error) {
    setState(() => _error = error);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  late final List<WorkspaceProductImportRow> _rows = List.of(
    widget.review.rows,
  );
  late final Set<int> _selected = {
    for (final r in _rows)
      if (r.product != null) r.number,
  };
  bool _issuesOnly = false, _busy = false;
  String? _error;
  Future<void> _edit(int index) async {
    final row = _rows[index];
    final edited = await widget.editProduct(row.product!);
    if (!mounted || edited == null) return;
    final duplicate = _rows.any(
      (r) =>
          r.number != row.number &&
          r.product != null &&
          (r.product!.sku.toLowerCase() == edited.sku.toLowerCase() ||
              (edited.barcode.isNotEmpty &&
                  r.product!.barcode == edited.barcode) ||
              WorkspaceProductImport.identity(r.product!) ==
                  WorkspaceProductImport.identity(edited)),
    );
    setState(() {
      if (duplicate) {
        _error =
            'This SKU, barcode or product is already in this file. Your previous details are unchanged.';
      } else {
        _error = null;
        _rows[index] = WorkspaceProductImportRow(
          row.number,
          edited.title,
          edited.copyWith(publicListing: false),
          null,
          row.matched,
        );
      }
    });
  }

  Future<void> _save() async {
    if (_busy || _selected.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final error = await widget.saveProducts([
        for (final r in _rows)
          if (_selected.contains(r.number) && r.product != null) r.product!,
      ]);
      if (!mounted) return;
      if (error != null) {
        _showError(error);
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        _showError('Could not save products. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _rows.where((r) => r.product != null).length;
    final attention = _rows.length - ready;
    final visible = _rows
        .asMap()
        .entries
        .where(
          (e) =>
              _issuesOnly ? e.value.product == null : e.value.product != null,
        )
        .toList();
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Review import'),
          backgroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  key: const Key('work-import-rows'),
                  controller: _scroll,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: MoolColors.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  key: const Key('work-import-ready'),
                                  label: Text('Ready · $ready'),
                                  selected: !_issuesOnly,
                                  onSelected: _busy
                                      ? null
                                      : (_) =>
                                            setState(() => _issuesOnly = false),
                                ),
                                ChoiceChip(
                                  key: const Key('work-import-issues'),
                                  label: Text(
                                    MediaQuery.textScalerOf(context).scale(1) >
                                            1.5
                                        ? 'Check · $attention'
                                        : 'Needs attention · $attention',
                                  ),
                                  selected: _issuesOnly,
                                  onSelected: _busy
                                      ? null
                                      : (_) =>
                                            setState(() => _issuesOnly = true),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _issuesOnly
                                  ? 'First issue shown for each row. Correct your CSV, then import again.'
                                  : 'Save selected products to Store stock. Nothing is published.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: MoolColors.muted,
                              ),
                            ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Divider(height: 1)),
                    visible.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _issuesOnly
                                      ? 'No rows need attention.'
                                      : 'No products are ready. Check Needs attention.',
                                ),
                              ),
                            ),
                          )
                        : SliverList.builder(
                            itemCount: visible.length,
                            itemBuilder: (context, i) {
                              final entry = visible[i],
                                  row = entry.value,
                                  product = row.product;
                              return Container(
                                key: Key('work-import-row-${row.number}'),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: MoolColors.line),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (product != null)
                                      Checkbox(
                                        value: _selected.contains(row.number),
                                        onChanged: _busy
                                            ? null
                                            : (value) => setState(() {
                                                if (value == true) {
                                                  _selected.add(row.number);
                                                } else {
                                                  _selected.remove(row.number);
                                                }
                                              }),
                                      )
                                    else
                                      const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.error_outline,
                                          size: 20,
                                          color: Color(0xFF9A4A00),
                                        ),
                                      ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              row.title,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: MoolColors.navy,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (product == null &&
                                                [
                                                  row.sku,
                                                  row.variant,
                                                  row.pack,
                                                ].any((v) => v.isNotEmpty))
                                              Text(
                                                [
                                                  if (row.sku.isNotEmpty)
                                                    'SKU ${row.sku}',
                                                  if (row.variant.isNotEmpty)
                                                    row.variant,
                                                  if (row.pack.isNotEmpty)
                                                    row.pack,
                                                ].join(' · '),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: MoolColors.muted,
                                                ),
                                              ),
                                            Text(
                                              product == null
                                                  ? 'Row ${row.number}'
                                                  : '${product.variant.isEmpty ? '' : '${product.variant} · '}${product.pack} · ₹${product.sellingPrice} · ${product.stockMode == WorkspaceStockMode.availabilityOnly ? (product.available ? 'Available' : 'Unavailable') : '${product.stock} in stock'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: MoolColors.muted,
                                              ),
                                            ),
                                            if (product == null) ...[
                                              for (final entry
                                                  in row.issueValues.entries)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${WorkspaceProductImport.templateLabels[entry.key] ?? entry.key} · ${entry.key}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              MoolColors.navy,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Entered: ${entry.value.isEmpty ? '(empty)' : entry.value}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              MoolColors.muted,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  'Correction: ${row.issue}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: MoolColors.navy,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (product != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  product.catalogueFactsRequireReview
                                                      ? 'Product facts need review · Store only'
                                                      : row.matched
                                                      ? 'Catalogue match · Store only'
                                                      : 'New product · Photo review needed',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: MoolColors.muted,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (product != null)
                                      IconButton(
                                        key: Key(
                                          'work-import-edit-${row.number}',
                                        ),
                                        tooltip: 'Edit product',
                                        onPressed: _busy
                                            ? null
                                            : () => _edit(entry.key),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                          color: MoolColors.navy,
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
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (attention > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '$attention rows need correction and will not be added.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: MoolColors.muted,
                          ),
                        ),
                      ),
                    FilledButton(
                      key: const Key('work-import-save'),
                      onPressed: _busy || _selected.isEmpty ? null : _save,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _busy
                              ? 'Saving…'
                              : 'Save ${_selected.length} to Store',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selects identity only. Store prices, stock and visibility are edited next.
class StoreAddProductSheet extends StatefulWidget {
  const StoreAddProductSheet({
    super.key,
    required this.catalogue,
    required this.ownedProducts,
    required this.createProduct,
    required this.scanBarcode,
    this.embedded = false,
    this.onSelected,
    this.onAdd,
    this.stockOnly = false,
    this.onlyLowStock = false,
    this.onAddProduct,
    this.onStockTools,
    this.stockExportBuilder,
    this.stockListItemBuilder,
    this.stockListHeader,
    this.stockStatementBuilder,
  });

  final List<WorkspaceCatalogueItem> catalogue;
  final List<WorkspaceCatalogueItem> ownedProducts;
  final WorkspaceCatalogueItem Function(String barcode) createProduct;
  final Future<String?> Function() scanBarcode;
  final bool embedded;
  final ValueChanged<WorkspaceCatalogueItem>? onSelected;
  final ValueChanged<WorkspaceCatalogueItem>? onAdd;
  final bool stockOnly;
  final bool onlyLowStock;
  final VoidCallback? onAddProduct;
  final VoidCallback? onStockTools;
  final Widget Function(
    List<WorkspaceCatalogueItem>,
    String,
    ValueChanged<bool>,
  )?
  stockExportBuilder;
  final Widget Function(WorkspaceCatalogueItem)? stockListItemBuilder;
  final Widget? stockListHeader;
  final Widget Function(
    List<WorkspaceCatalogueItem>,
    int,
    ScrollController,
    VoidCallback,
  )?
  stockStatementBuilder;

  @override
  State<StoreAddProductSheet> createState() => _StoreAddProductSheetState();
}

class _StoreAddProductSheetState extends State<StoreAddProductSheet> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  static const _pageSize = 50;
  static const _uncategorised = '#uncategorised';
  int _pageLimit = _pageSize;
  bool _listView = false;
  late Map<String, WorkspaceCatalogueItem> _ownedById;
  late Map<(String, String, String, String), WorkspaceCatalogueItem>
  _ownedByIdentity;
  late List<({WorkspaceCatalogueItem product, String search})> _indexed;
  late Map<String, int> _categoryCounts;
  late List<String> _brands;
  bool _scanning = false;
  String _barcode = '';
  String? _scanError;
  String _category = '';
  String _filter = '';
  bool _savedOnly = false;
  bool _currentStockPeriod = true;

  @override
  void initState() {
    super.initState();
    _listView = widget.stockOnly;
    _indexProducts();
  }

  @override
  void didUpdateWidget(StoreAddProductSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _indexProducts();
  }

  (String, String, String, String) _identity(WorkspaceCatalogueItem product) =>
      (product.canonicalId, product.variant, product.pack, product.barcode);

  String _categoryKey(WorkspaceCatalogueItem product) =>
      product.categoryId.trim().isEmpty ? _uncategorised : product.categoryId;

  // Index once per parent data update, not once per tile or typed character.
  // Matching 10,000 catalogue and owned SKUs must not perform N x M scans.
  void _indexProducts() {
    _ownedById = {for (final item in widget.ownedProducts) item.id: item};
    _ownedByIdentity = {
      for (final item in widget.ownedProducts) _identity(item): item,
    };
    final products = Map<String, WorkspaceCatalogueItem>.of(_ownedById);
    for (final product
        in widget.stockOnly ? <WorkspaceCatalogueItem>[] : widget.catalogue) {
      if (_owned(product) == null) {
        products.putIfAbsent(product.id, () => product);
      }
    }
    _indexed = [
      for (final product in products.values)
        (
          product: product,
          search:
              '${product.title} ${product.brand} ${product.variant} ${product.pack} ${product.sku} ${product.barcode}'
                  .toLowerCase(),
        ),
    ];
    _categoryCounts = {};
    final brands = <String>{};
    for (final product in products.values) {
      _categoryCounts.update(
        _categoryKey(product),
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (product.brand.isNotEmpty) brands.add(product.brand);
    }
    _brands = brands.toList()..sort();
  }

  void _resetBrowse(VoidCallback change) {
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() {
      change();
      _pageLimit = _pageSize;
    });
  }

  void _loadMore(int count) {
    if (_pageLimit >= count) return;
    setState(() => _pageLimit = (_pageLimit + _pageSize).clamp(0, count));
  }

  void _select(WorkspaceCatalogueItem product) {
    if (widget.onSelected != null) {
      widget.onSelected!(product);
    } else {
      Navigator.pop(context, product);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _scanning = true;
      _scanError = null;
    });
    try {
      final code = await widget.scanBarcode();
      if (!mounted || code == null || code.trim().isEmpty) return;
      _resetBrowse(() {
        _barcode = code.trim();
        _search.text = _barcode;
        _category = '';
        _filter = '';
        _savedOnly = false;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _scanError =
              'Could not scan. Search or enter the product instead.',
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  WorkspaceCatalogueItem? _owned(WorkspaceCatalogueItem product) {
    return _ownedById[product.id] ?? _ownedByIdentity[_identity(product)];
  }

  bool _matchesFilter(WorkspaceCatalogueItem product) {
    if (widget.onlyLowStock && !_lowStock(product)) return false;
    if (!widget.stockOnly) {
      return _filter.isEmpty ||
          (_filter == 'new'
              ? _owned(product) == null
              : product.brand == _filter);
    }
    return switch (_filter) {
      '#low' => _lowStock(product),
      '#out' =>
        product.stockMode == WorkspaceStockMode.exactQuantity
            ? product.stock == 0
            : !product.available,
      '#private' => !product.publicListing,
      '#public' => product.publicListing,
      '' => true,
      _ => product.brand == _filter,
    };
  }

  bool _lowStock(WorkspaceCatalogueItem product) =>
      product.stockMode == WorkspaceStockMode.exactQuantity &&
      product.stock <= product.lowStockThreshold;

  String _stockLabel(WorkspaceCatalogueItem product) =>
      product.stockMode == WorkspaceStockMode.availabilityOnly
      ? (product.available ? 'Available' : 'Unavailable')
      : '${product.stock} in stock';

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final modes = context
        .dependOnInheritedWidgetOfExactType<_StoreAddModeScope>();
    final categories = _categoryCounts.keys.toList()..sort();
    final entries = _indexed
        .where(
          (entry) =>
              (_category.isEmpty || _categoryKey(entry.product) == _category) &&
              (!_savedOnly || _owned(entry.product) != null) &&
              _matchesFilter(entry.product) &&
              (query.isEmpty || entry.search.contains(query)),
        )
        .map((entry) => entry.product)
        .toList(growable: false);
    final visibleCount = _pageLimit.clamp(0, entries.length);
    final subtitle =
        '${_category.isEmpty ? '' : '${_categoryLabel(_category)} · '}'
        '${entries.length} ${entries.length == 1 ? 'product' : 'products'}'
        '${_savedOnly ? ' · In your store' : ''}'
        '${widget.onlyLowStock ? ' · Low stock' : ''}';
    return Scaffold(
      key: const Key('work-add-products-picker'),
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: !widget.embedded,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Add products')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = Column(
              children: [
                Container(
                  key: const Key('work-catalogue-search-band'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: MoolColors.canvas,
                    border: Border(bottom: BorderSide(color: MoolColors.line)),
                  ),
                  child: Row(
                    children: [
                      if (widget.embedded && !widget.stockOnly)
                        const BackButton(),
                      Expanded(
                        child: TextField(
                          key: const Key('work-add-products-search'),
                          controller: _search,
                          onChanged: (_) => _resetBrowse(() => _barcode = ''),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: MoolColors.navy,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                MediaQuery.textScalerOf(context).scale(1) > 1.3
                                ? 'Search'
                                : 'Search products',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 42,
                              minHeight: 48,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 21,
                              color: MoolColors.navy,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_category.isNotEmpty ||
                                    _filter.isNotEmpty ||
                                    _savedOnly ||
                                    query.isNotEmpty)
                                  IconButton(
                                    key: const Key('work-catalogue-clear'),
                                    tooltip: 'Clear search and filters',
                                    onPressed: () => _resetBrowse(() {
                                      _search.clear();
                                      _category = '';
                                      _filter = '';
                                      _savedOnly = false;
                                    }),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                    ),
                                  ),
                                IconButton(
                                  key: const Key('work-add-products-scan'),
                                  tooltip: 'Scan barcode',
                                  onPressed: _scanning ? null : _scan,
                                  icon: const Icon(
                                    Icons.qr_code_scanner,
                                    size: 22,
                                  ),
                                ),
                                if (!widget.stockOnly)
                                  IconButton(
                                    key: const Key(
                                      'work-catalogue-view-toggle',
                                    ),
                                    tooltip: _listView
                                        ? 'Grid view'
                                        : 'List view',
                                    onPressed: () => _resetBrowse(
                                      () => _listView = !_listView,
                                    ),
                                    icon: Icon(
                                      _listView
                                          ? Icons.grid_view_rounded
                                          : Icons.view_list_rounded,
                                      size: 22,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  key: const Key('work-catalogue-toolbar'),
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF8F8FF), Color(0xFFF5F8FF)],
                    ),
                    border: Border(bottom: BorderSide(color: MoolColors.line)),
                  ),
                  child: Row(
                    children: [
                      PopupMenuButton<String>(
                        key: const Key('work-catalogue-category'),
                        tooltip: 'Choose category',
                        initialValue: _category,
                        onSelected: (value) =>
                            _resetBrowse(() => _category = value),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: '',
                            child: Text('All categories'),
                          ),
                          for (final category in categories)
                            PopupMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(_categoryLabel(category)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_categoryCounts[category]}',
                                    style: const TextStyle(
                                      color: MoolColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        child: _control(
                          Icons.menu_rounded,
                          _category.isEmpty
                              ? 'Category'
                              : _categoryLabel(_category),
                          active: _category.isNotEmpty,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: modes != null
                              ? _StoreAddModeSelector(
                                  index: 0,
                                  onSelected: modes.onSelected,
                                  enabled: modes.enabled,
                                  compact: true,
                                  subtitle: subtitle,
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.stockOnly
                                          ? 'Store stock'
                                          : 'MoolSocial catalogue',
                                      key: widget.stockOnly
                                          ? const Key('work-catalogue-heading')
                                          : null,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.2,
                                        fontWeight: FontWeight.w700,
                                        color: MoolColors.navy,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.stockOnly && !_currentStockPeriod
                                          ? 'Historical statement'
                                          : subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        height: 1.2,
                                        color: MoolColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      if (widget.stockOnly)
                        IconButton(
                          key: const Key('work-catalogue-add'),
                          tooltip: 'Add product',
                          onPressed: widget.onAddProduct,
                          icon: _control(
                            Icons.add_rounded,
                            'Add product',
                            active: false,
                          ),
                          padding: EdgeInsets.zero,
                        )
                      else
                        IconButton(
                          key: const Key('work-catalogue-saved'),
                          tooltip: _savedOnly
                              ? 'Show all products'
                              : 'Saved in your store',
                          onPressed: () => _resetBrowse(() {
                            _savedOnly = !_savedOnly;
                            if (_savedOnly && _filter == 'new') _filter = '';
                          }),
                          padding: EdgeInsets.zero,
                          icon: _control(
                            _savedOnly
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            'Saved in your store',
                            active: _savedOnly,
                            badge: '${widget.ownedProducts.length}',
                          ),
                        ),
                      const SizedBox(width: 6),
                      PopupMenuButton<String>(
                        key: const Key('work-catalogue-filter'),
                        tooltip: 'Filter products',
                        initialValue: _filter,
                        onSelected: (value) => _resetBrowse(() {
                          _filter = value;
                          if (value == 'new') _savedOnly = false;
                        }),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: '',
                            child: Text('All products'),
                          ),
                          if (!widget.stockOnly)
                            const PopupMenuItem(
                              value: 'new',
                              child: Text('Not added yet'),
                            ),
                          if (widget.stockOnly) ...[
                            const PopupMenuItem(
                              value: '#low',
                              child: Text('Low stock'),
                            ),
                            const PopupMenuItem(
                              value: '#out',
                              child: Text('Out of stock'),
                            ),
                            const PopupMenuItem(
                              value: '#private',
                              child: Text('Store only'),
                            ),
                            const PopupMenuItem(
                              value: '#public',
                              child: Text('Public selected'),
                            ),
                          ],
                          for (final brand in _brands)
                            PopupMenuItem(value: brand, child: Text(brand)),
                        ],
                        child: _control(
                          Icons.tune_rounded,
                          'Filter${_filter.isEmpty ? '' : ' •'}',
                          active: _filter.isNotEmpty,
                        ),
                      ),
                      if (widget.stockOnly)
                        IconButton(
                          key: const Key('work-catalogue-more'),
                          tooltip: 'More product tools',
                          onPressed: widget.onStockTools,
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: MoolColors.navy,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.stockOnly && widget.stockExportBuilder != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentStockPeriod)
                          Text(
                            '${entries.length} products · ${entries.where((p) => p.stockMode == WorkspaceStockMode.exactQuantity && p.stock > 0 && p.stock <= p.lowStockThreshold).length} low · ${entries.where((p) => p.stockMode == WorkspaceStockMode.exactQuantity ? p.stock <= 0 : !p.available).length} out',
                            key: const Key('work-stock-summary'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: MoolColors.muted,
                            ),
                          ),
                        widget.stockExportBuilder!(
                          List.of(entries),
                          [
                            if (_search.text.trim().isNotEmpty)
                              'Search: ${_search.text.trim()}',
                            if (_barcode.isNotEmpty) 'Barcode: $_barcode',
                            if (_category.isNotEmpty)
                              'Category: ${_categoryLabel(_category)}',
                            if (_filter.isNotEmpty)
                              'Filter: ${switch (_filter) {
                                '#low' => 'Low stock',
                                '#out' => 'Out of stock',
                                '#private' => 'Store only',
                                '#public' => 'Public selected',
                                _ => _filter,
                              }}',
                          ].join('; '),
                          (current) =>
                              setState(() => _currentStockPeriod = current),
                        ),
                      ],
                    ),
                  ),
                if (_scanError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _scanError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (widget.stockOnly &&
                    entries.isNotEmpty &&
                    widget.stockStatementBuilder == null &&
                    widget.stockListHeader != null)
                  widget.stockListHeader!,
                Expanded(
                  child: widget.stockOnly && !_currentStockPeriod
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No historical statement is available for this period yet. Choose Current stock to view and download saved stock.',
                              key: Key('work-stock-history-unavailable'),
                            ),
                          ),
                        )
                      : entries.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              widget.stockOnly
                                  ? (widget.ownedProducts.isEmpty
                                        ? 'No products saved yet. Tap + to add a product to your store.'
                                        : 'No matching stock. Try another search or filter.')
                                  : widget.embedded
                                  ? 'No matching product. Use Add manually to enter its details.'
                                  : 'No matching product. You can add its details below.',
                            ),
                          ),
                        )
                      : widget.stockOnly && widget.stockStatementBuilder != null
                      ? widget.stockStatementBuilder!(
                          entries,
                          visibleCount,
                          _scroll,
                          () => _loadMore(entries.length),
                        )
                      : LayoutBuilder(
                          builder: (context, grid) {
                            final scale = MediaQuery.textScalerOf(
                              context,
                            ).scale(1);
                            final columns = scale > 1.6
                                ? 1
                                : ((grid.maxWidth - 16) /
                                          (scale > 1.15 ? 140 : 96))
                                      .floor()
                                      .clamp(1, 5);
                            return NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification.depth == 0 &&
                                    notification is ScrollUpdateNotification &&
                                    notification.metrics.extentAfter < 160) {
                                  _loadMore(entries.length);
                                }
                                return false;
                              },
                              child: KeyedSubtree(
                                key: PageStorageKey(
                                  'catalogue-scroll-${widget.key}',
                                ),
                                child: CustomScrollView(
                                  key: Key(
                                    _listView
                                        ? 'work-catalogue-list'
                                        : 'work-catalogue-grid',
                                  ),
                                  controller: _scroll,
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  slivers: [
                                    SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        0,
                                        8,
                                        12,
                                      ),
                                      sliver: _listView
                                          ? SliverList.builder(
                                              itemCount: visibleCount,
                                              itemBuilder: (_, index) => Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: widget.stockOnly
                                                      ? 0
                                                      : 8,
                                                ),
                                                child:
                                                    widget.stockOnly &&
                                                        widget.stockListItemBuilder !=
                                                            null
                                                    ? widget
                                                          .stockListItemBuilder!(
                                                        entries[index],
                                                      )
                                                    : _listTile(entries[index]),
                                              ),
                                            )
                                          : SliverGrid.builder(
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: columns,
                                                    crossAxisSpacing: 8,
                                                    mainAxisSpacing: 8,
                                                    mainAxisExtent:
                                                        92 +
                                                        (widget.stockOnly
                                                                ? 114
                                                                : 84) *
                                                            scale,
                                                  ),
                                              itemCount: visibleCount,
                                              itemBuilder: (_, index) =>
                                                  _tile(entries[index]),
                                            ),
                                    ),
                                    if (visibleCount < entries.length)
                                      SliverToBoxAdapter(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: TextButton(
                                            key: const Key(
                                              'work-catalogue-load-more',
                                            ),
                                            onPressed: () =>
                                                _loadMore(entries.length),
                                            child: Text(
                                              'Load more · $visibleCount of ${entries.length}',
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (!widget.embedded)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('work-add-product-manual'),
                        onPressed: () =>
                            _select(widget.createProduct(_barcode)),
                        icon: const Icon(Icons.add),
                        label: const Text('Enter a new product'),
                      ),
                    ),
                  ),
              ],
            );
            // Stock stays in the same scroll subtree when a quantity/price
            // sheet opens the keyboard; reparenting it loses the return offset.
            if (widget.stockOnly || constraints.maxHeight < 280) {
              final minimumHeight = widget.stockStatementBuilder == null
                  ? 360.0
                  : 360.0 *
                        MediaQuery.textScalerOf(
                          context,
                        ).scale(1).clamp(1.0, 2.5);
              return SingleChildScrollView(
                child: SizedBox(
                  height:
                      widget.stockOnly && constraints.maxHeight > minimumHeight
                      ? constraints.maxHeight
                      : minimumHeight,
                  child: content,
                ),
              );
            }
            return content;
          },
        ),
      ),
    );
  }

  String _categoryLabel(String id) => id.isEmpty || id == _uncategorised
      ? 'Uncategorised'
      : id
            .split('-')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');

  // Buy's 48px catalogue chrome, with Store callbacks instead of cart state.
  Widget _control(
    IconData icon,
    String label, {
    required bool active,
    String? badge,
  }) => Semantics(
    label: label,
    selected: active,
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: active
              ? const [Color(0xFFFFE8CE), Colors.white]
              : const [Colors.white, Color(0xFFF4F3FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? BuyV2Colors.orange : BuyV2Colors.line,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000080),
            blurRadius: 9,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Badge(
          isLabelVisible: badge != null,
          label: badge == null
              ? null
              : Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
          backgroundColor: BuyV2Colors.orange,
          textColor: BuyV2Colors.navy,
          child: Icon(
            icon,
            size: 22,
            color: active ? BuyV2Colors.royal : BuyV2Colors.navy,
          ),
        ),
      ),
    ),
  );

  void _activate(WorkspaceCatalogueItem product) {
    final owned = _owned(product);
    if (owned == null && widget.onAdd != null) {
      widget.onAdd!(product);
    } else {
      _select(
        owned ??
            product.copyWith(
              purchasePrice: 0,
              sellingPrice: 0,
              stock: 0,
              unitPrice: '',
              available: false,
              publicListing: false,
            ),
      );
    }
  }

  Widget _listTile(WorkspaceCatalogueItem product) {
    final owned = _owned(product);
    final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final action = SizedBox(
      width: enlarged ? double.infinity : 108,
      height: 48,
      child: FilledButton.tonal(
        key: Key('work-catalogue-add-${product.id}'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () => _activate(product),
        child: Text(
          owned == null ? 'Add to Store' : 'Edit',
          textAlign: TextAlign.center,
        ),
      ),
    );
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: owned == null ? MoolColors.line : MoolColors.navy,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _activate(product),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 48,
                    child: BuyV2ProductPackshot(
                      product: product.toCataloguePreviewProduct(),
                      borderRadius: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tooltip(
                          message:
                              '${product.title} · ${product.variant} · ${product.pack}',
                          child: Text(
                            product.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: MoolColors.navy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (product.variant.trim().isNotEmpty)
                          Text(
                            product.variant,
                            key: Key('work-catalogue-variant-${product.id}'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: MoolColors.navy,
                            ),
                          ),
                        Text(
                          product.pack,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: MoolColors.muted,
                          ),
                        ),
                        Text(
                          widget.stockOnly
                              ? '₹${product.sellingPrice} · ${_stockLabel(product)}'
                              : owned != null
                              ? 'In your store'
                              : product.mrp == null
                              ? product.brand
                              : 'MRP ₹${product.mrp}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: MoolColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!enlarged) ...[const SizedBox(width: 8), action],
                ],
              ),
              if (enlarged) ...[const SizedBox(height: 8), action],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(WorkspaceCatalogueItem product) {
    final owned = _owned(product);
    void act() => _activate(product);

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: owned == null ? MoolColors.line : MoolColors.navy,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('work-add-product-${product.id}'),
        onTap: act,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
                child: BuyV2ProductPackshot(
                  product: product.toCataloguePreviewProduct(),
                  borderRadius: 0,
                ),
              ),
              const SizedBox(height: 2),
              Tooltip(
                message:
                    '${product.title} · ${product.variant} · ${product.pack}',
                child: Text(
                  product.title,
                  maxLines: product.variant.trim().isEmpty ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: MoolColors.navy,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              if (product.variant.trim().isNotEmpty)
                Tooltip(
                  message: product.variant,
                  child: Text(
                    product.variant,
                    key: Key('work-catalogue-variant-${product.id}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      color: MoolColors.navy,
                    ),
                  ),
                ),
              Text(
                product.pack,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: MoolColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                widget.stockOnly
                    ? '₹${product.sellingPrice}'
                    : owned != null
                    ? 'In your store'
                    : product.mrp == null
                    ? product.brand
                    : 'MRP ₹${product.mrp}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: MoolColors.muted),
              ),
              if (widget.stockOnly) ...[
                Text(
                  _stockLabel(product),
                  key: Key('work-stock-quantity-${product.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: _lowStock(product)
                        ? const Color(0xFF9A4A00)
                        : MoolColors.navy,
                  ),
                ),
                Text(
                  product.publicListing ? 'Public selected' : 'Store only',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: MoolColors.muted),
                ),
              ],
              const Spacer(),
              SizedBox(
                height: 48,
                child: FilledButton.tonal(
                  key: Key('work-catalogue-add-${product.id}'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: act,
                  child: Text(
                    owned == null ? 'Add to Store' : 'Edit',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
