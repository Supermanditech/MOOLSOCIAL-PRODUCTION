import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/design/mool_colors.dart';
import '../../../ui_v2/buy/buy_v2_design.dart';
import '../../../ui_v2/buy/buy_v2_category_sheet_policy.dart';
import '../widgets/store_catalogue_categories.dart';
import '../widgets/store_product_thumbnail.dart';
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
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: MoolColors.line),
    ),
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
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: index == i
                  ? const LinearGradient(
                      colors: [Color(0xffedf0ff), Colors.white],
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  [
                    Icons.inventory_2_outlined,
                    Icons.edit_outlined,
                    Icons.upload_file_outlined,
                  ][i],
                  size: 20,
                  color: MoolColors.navy,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    labels[i],
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (index == i)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: MoolColors.navy,
                  ),
              ],
            ),
          ),
        ),
    ],
    child: Semantics(
      button: true,
      label: '${labels[index]}. Switch product entry method',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    index == 0 ? 'Catalogue' : labels[index],
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
            const SizedBox(width: 4),
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
    return PopScope(
      canPop: catalogue,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.catalogueEditing && widget.selectedIndex == 0) {
          widget.onCloseCatalogueEditor?.call();
        } else {
          widget.onSelected(0);
        }
      },
      child: Scaffold(
        key: const Key('work-add-product-entry'),
        backgroundColor: Colors.white,
        appBar: catalogue
            ? null
            : AppBar(
                toolbarHeight: 48,
                titleSpacing: 0,
                titleTextStyle: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MoolColors.navy,
                    ),
                backgroundColor: Colors.white,
                leading: BackButton(
                  onPressed:
                      widget.catalogueEditing && widget.selectedIndex == 0
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
          'One row per SKU, variant and pack. Up to 10,000 products · 10 MB.',
          style: TextStyle(fontSize: 12, height: 1.4, color: MoolColors.muted),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const Key('work-add-product-choose-csv'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF0F1F7),
            foregroundColor: const Color(0xFF252B38),
          ),
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
        const SizedBox(height: 8),
        ExpansionTile(
          key: const Key('work-csv-required-columns'),
          tilePadding: EdgeInsets.zero,
          title: const Text(
            'Required product fields',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          children: [
            _columnGuide(true),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Purchase price stays private. Use whole rupees without ₹ or commas, and whole stock quantities.',
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
                'Store identity, address and default payment/return terms are set once in Store Settings. MoolSocial manages delivery coverage and charges.\n\nInclude product-specific terms only where they differ. Keep bank details, payment status and invoice totals out of this CSV.',
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
    this.correctRow,
  });
  final String fileName;
  final WorkspaceProductImport review;
  final Future<WorkspaceCatalogueItem?> Function(WorkspaceCatalogueItem)
  editProduct;
  final Future<String?> Function(List<WorkspaceCatalogueItem>) saveProducts;
  final Future<WorkspaceProductImportRow?> Function(
    WorkspaceProductImportRow,
    List<WorkspaceProductImportRow>,
  )?
  correctRow;
  @override
  State<StoreProductImportReviewScreen> createState() =>
      _StoreProductImportReviewScreenState();
}

class _StoreProductImportReviewScreenState
    extends State<StoreProductImportReviewScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _expandedIssues = <int>{};
  String _query = '';
  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
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
  late bool _issuesOnly =
      _rows.isNotEmpty && _rows.every((r) => r.product == null);
  bool _busy = false;
  late final Map<int, String> _searchIndex = {
    for (final row in _rows) row.number: _searchable(row),
  };
  String _searchable(WorkspaceProductImportRow row) => [
    row.title,
    row.sku,
    row.variant,
    row.pack,
    row.issue ?? '',
    row.product?.sku ?? '',
    row.product?.barcode ?? '',
    row.product?.brand ?? '',
    row.product?.variant ?? '',
    row.product?.pack ?? '',
    ...row.issueValues.keys,
    ...row.issueValues.values,
  ].join(' ').toLowerCase();

  String _issueType(WorkspaceProductImportRow row) {
    if (row.issueKind == WorkspaceProductImportIssueKind.duplicateInStore) {
      return 'Already in Store stock';
    }
    if (row.issueKind == WorkspaceProductImportIssueKind.duplicateInFile) {
      return 'Repeated in this file';
    }
    final issue = (row.issue ?? '').toLowerCase();
    if (issue.contains('already in store') || issue.contains('repeated')) {
      return 'Duplicate product';
    }
    if (issue.contains('column count')) return 'CSV columns do not match';
    if (issue.contains('catalogue')) return 'Check catalogue match';
    if (row.issueValues.length == 1) {
      final entry = row.issueValues.entries.single;
      final label =
          WorkspaceProductImport.templateLabels[entry.key] ?? entry.key;
      return '${entry.value.isEmpty ? 'Missing' : 'Check'} ${label.toLowerCase()}';
    }
    return 'Check product details';
  }

  String? _error;
  Future<void> _correct(int index) async {
    if (_busy || widget.correctRow == null) return;
    final original = _rows[index];
    final corrected = await widget.correctRow!(original, [
      for (final row in _rows)
        if (row.number != original.number && row.product != null) row,
    ]);
    if (!mounted || corrected == null) return;
    final product = corrected.product;
    if (corrected.number != original.number || product == null) return;
    final duplicate = _rows.any(
      (row) =>
          row.number != original.number &&
          row.product != null &&
          (row.product!.id == product.id ||
              row.product!.sku.trim().toLowerCase() ==
                  product.sku.trim().toLowerCase() ||
              (product.barcode.isNotEmpty &&
                  row.product!.barcode == product.barcode) ||
              WorkspaceProductImport.identity(row.product!) ==
                  WorkspaceProductImport.identity(product)),
    );
    if (duplicate) {
      _showError(
        'This product is already in the import. Your original row is unchanged.',
      );
      return;
    }
    setState(() {
      _rows[index] = corrected;
      _searchIndex[original.number] = _searchable(corrected);
      _selected.add(original.number);
      _expandedIssues.remove(original.number);
      _issuesOnly = false;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

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
          sourceValues: row.sourceValues,
        );
        _searchIndex[row.number] = _searchable(_rows[index]);
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
    final rowQuery = RegExp(
      r'^(?:row\s*)?(\d+)$',
      caseSensitive: false,
    ).firstMatch(_query.trim());
    final searchedRow = rowQuery == null
        ? null
        : int.tryParse(rowQuery.group(1)!);
    final terms = _query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final visible = _rows
        .asMap()
        .entries
        .where(
          (e) =>
              (_issuesOnly
                  ? e.value.product == null
                  : e.value.product != null) &&
              (searchedRow == e.value.number ||
                  terms.every(
                    (term) => _searchIndex[e.value.number]!.contains(term),
                  )),
        )
        .toList();
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 48,
          titleSpacing: 0,
          title: const Text('Review import'),
          titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: MoolColors.navy,
            fontWeight: FontWeight.w700,
          ),
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
                            TextField(
                              key: const Key('work-import-search'),
                              controller: _search,
                              enabled: !_busy,
                              style: const TextStyle(fontSize: 14),
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              decoration: InputDecoration(
                                hintText:
                                    MediaQuery.textScalerOf(context).scale(1) >
                                        1.5
                                    ? 'Search CSV'
                                    : 'Search product, SKU or row',
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: MoolColors.muted,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                ),
                                suffixIcon: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        key: const Key(
                                          'work-import-clear-search',
                                        ),
                                        tooltip: 'Clear search',
                                        onPressed: () {
                                          _search.clear();
                                          setState(() => _query = '');
                                        },
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                        ),
                                      ),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  key: const Key('work-import-ready'),
                                  showCheckmark: true,
                                  checkmarkColor: const Color(0xFF252B38),
                                  selectedColor: const Color(0xFFF0F1F7),
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide.none,
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF252B38),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  padding: EdgeInsets.zero,
                                  label: Text('Ready · $ready'),
                                  selected: !_issuesOnly,
                                  onSelected: _busy
                                      ? null
                                      : (_) =>
                                            setState(() => _issuesOnly = false),
                                ),
                                ChoiceChip(
                                  key: const Key('work-import-issues'),
                                  showCheckmark: true,
                                  checkmarkColor: const Color(0xFF252B38),
                                  selectedColor: const Color(0xFFF0F1F7),
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide.none,
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF252B38),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  padding: EdgeInsets.zero,
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
                            if (!_issuesOnly && visible.isNotEmpty)
                              Row(
                                children: [
                                  Checkbox(
                                    key: const Key(
                                      'work-import-select-results',
                                    ),
                                    tristate: true,
                                    value:
                                        visible.every(
                                          (e) => _selected.contains(
                                            e.value.number,
                                          ),
                                        )
                                        ? true
                                        : visible.any(
                                            (e) => _selected.contains(
                                              e.value.number,
                                            ),
                                          )
                                        ? null
                                        : false,
                                    onChanged: _busy
                                        ? null
                                        : (_) => setState(() {
                                            final numbers = visible
                                                .map((e) => e.value.number)
                                                .toSet();
                                            if (numbers.every(
                                              _selected.contains,
                                            )) {
                                              _selected.removeAll(numbers);
                                            } else {
                                              _selected.addAll(numbers);
                                            }
                                          }),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${visible.every((e) => _selected.contains(e.value.number)) ? 'Clear' : 'Select'} ${_query.trim().isEmpty ? 'all' : 'results'} (${visible.length})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: MoolColors.navy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (!_issuesOnly)
                              const Text(
                                'Saves as private stock',
                                style: TextStyle(
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
                                      ? (terms.isEmpty
                                            ? 'No rows need attention.'
                                            : 'No issues match your search.')
                                      : (terms.isEmpty
                                            ? 'No products are ready. Check Needs attention.'
                                            : 'No products match your search.'),
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
                                  vertical: 2,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (product != null)
                                      Checkbox(
                                        key: Key(
                                          'work-import-select-${row.number}',
                                        ),
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
                                                color: Color(0xFF252B38),
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
                                                  if (row.sku.isNotEmpty &&
                                                      _expandedIssues.contains(
                                                        row.number,
                                                      ))
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
                                                  ? 'Row ${row.number} · ${_issueType(row)}'
                                                  : '${product.variant.isEmpty ? '' : '${product.variant} · '}${product.pack} · ₹${product.sellingPrice} · ${product.stockMode == WorkspaceStockMode.availabilityOnly ? (product.available ? 'Available' : 'Unavailable') : '${product.stock} in stock'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: MoolColors.muted,
                                              ),
                                            ),
                                            if (product == null) ...[
                                              if (_expandedIssues.contains(
                                                    row.number,
                                                  ) &&
                                                  row.issueKind ==
                                                      WorkspaceProductImportIssueKind
                                                          .malformedColumns)
                                                for (
                                                  var cell = 0;
                                                  cell < row.sourceCells.length;
                                                  cell++
                                                )
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 6,
                                                        ),
                                                    child: Text(
                                                      '${cell < row.sourceHeaders.length ? 'Column ${cell + 1} (${row.sourceHeaders[cell]})' : 'Extra column ${cell + 1}'}: ${row.sourceCells[cell].isEmpty ? '(empty)' : row.sourceCells[cell]}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: MoolColors.muted,
                                                      ),
                                                    ),
                                                  ),
                                              if (_expandedIssues.contains(
                                                    row.number,
                                                  ) &&
                                                  row.issueKind !=
                                                      WorkspaceProductImportIssueKind
                                                          .malformedColumns)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 4,
                                                  ),
                                                  child: Text(
                                                    row.canCorrect &&
                                                            widget.correctRow !=
                                                                null
                                                        ? 'Tap Edit to correct this product.'
                                                        : 'Correct the CSV and import again.',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: MoolColors.muted,
                                                    ),
                                                  ),
                                                ),
                                              if (_expandedIssues.contains(
                                                row.number,
                                              ))
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
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    MoolColors
                                                                        .navy,
                                                              ),
                                                        ),
                                                        Text(
                                                          'Entered: ${entry.value.isEmpty ? '(empty)' : entry.value}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    MoolColors
                                                                        .muted,
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
                                                  row.issue ??
                                                      'Review this row.',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: MoolColors.muted,
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
                                    if (product == null)
                                      Column(
                                        children: [
                                          if (row.canCorrect &&
                                              widget.correctRow != null)
                                            TextButton(
                                              key: Key(
                                                'work-import-correct-${row.number}',
                                              ),
                                              onPressed: _busy
                                                  ? null
                                                  : () => _correct(entry.key),
                                              style: TextButton.styleFrom(
                                                minimumSize: const Size(48, 48),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: const Text('Edit'),
                                            ),
                                          if (row.issueValues.isNotEmpty ||
                                              row.issueKind ==
                                                  WorkspaceProductImportIssueKind
                                                      .malformedColumns)
                                            IconButton(
                                              key: Key(
                                                'work-import-details-${row.number}',
                                              ),
                                              tooltip:
                                                  _expandedIssues.contains(
                                                    row.number,
                                                  )
                                                  ? 'Hide CSV values'
                                                  : 'Show CSV values',
                                              onPressed: () => setState(() {
                                                if (!_expandedIssues.add(
                                                  row.number,
                                                )) {
                                                  _expandedIssues.remove(
                                                    row.number,
                                                  );
                                                }
                                              }),
                                              icon: Icon(
                                                _expandedIssues.contains(
                                                      row.number,
                                                    )
                                                    ? Icons.expand_less
                                                    : Icons.expand_more,
                                                size: 20,
                                              ),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
              if (ready > 0 && MediaQuery.viewInsetsOf(context).bottom == 0)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        key: const Key('work-import-save'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF0F1F7),
                          foregroundColor: const Color(0xFF252B38),
                        ),
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
    this.stockExportBuilder,
    this.stockListItemBuilder,
    this.stockListHeader,
    this.stockStatementBuilder,
    this.savedCatalogueKeys,
    this.recentSearches,
    this.onBrowseChanged,
    this.isStoreCurrent,
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
  // Store-scoped state is supplied by the existing session, not inventory.
  final Set<String>? savedCatalogueKeys;
  final List<String>? recentSearches;
  final VoidCallback? onBrowseChanged;
  final bool Function()? isStoreCurrent;
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
  final _searchFocus = FocusNode();
  final _localSaved = <String>{};
  final _localHistory = <String>[];
  Set<String> get _saved => widget.savedCatalogueKeys ?? _localSaved;
  List<String> get _history => widget.recentSearches ?? _localHistory;
  String _saveKey(WorkspaceCatalogueItem item) =>
      jsonEncode([item.canonicalId, item.variant, item.pack, item.barcode]);
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
    _searchFocus.addListener(_focusChanged);
    _indexProducts();
  }

  void _focusChanged() {
    if (mounted) setState(() {});
  }

  void _rememberQuery() {
    final query = _search.text.trim();
    if (query.isEmpty || widget.stockOnly) return;
    if (widget.isStoreCurrent?.call() == false) return;
    _history.removeWhere((old) => old.toLowerCase() == query.toLowerCase());
    _history.insert(0, query);
    if (_history.length > 6) _history.removeRange(6, _history.length);
    widget.onBrowseChanged?.call();
  }

  void _bookmark(WorkspaceCatalogueItem item) {
    if (widget.isStoreCurrent?.call() == false) return;
    setState(() {
      final key = _saveKey(item);
      if (!_saved.add(key)) _saved.remove(key);
    });
    widget.onBrowseChanged?.call();
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
    final products = <String, WorkspaceCatalogueItem>{
      for (final product
          in widget.stockOnly ? widget.ownedProducts : widget.catalogue)
        product.id: product,
    };
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
    _searchFocus.dispose();
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
      if (!widget.stockOnly) _reviewBarcode(_barcode);
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
    if (widget.stockOnly) return _ownedById[product.id];
    return _ownedByIdentity[_identity(product)];
  }

  void _reviewBarcode(String code) {
    _resetBrowse(() {
      _barcode = code;
      _search.text = code;
      _category = '';
      _filter = '';
      _savedOnly = false;
      _scanError = null;
    });
    final matches = _indexed
        .where((entry) => entry.product.barcode == code)
        .toList();
    if (matches.length == 1) {
      _activate(matches.single.product);
    } else {
      setState(
        () => _scanError = matches.isEmpty
            ? 'No exact pack found. Search by name or add manually.'
            : 'More than one pack matches. Choose the exact pack below.',
      );
    }
  }

  Future<void> _chooseCategory() async {
    _searchFocus.unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(),
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(
        maxWidth: BuyV2CategorySheetPolicy.maxWidth,
      ),
      sheetAnimationStyle: BuyV2CategorySheetPolicy.resolve(context),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: StoreCatalogueCategories(
          selected: _category,
          counts: _categoryCounts,
          label: _categoryLabel,
          stockOnly: widget.stockOnly,
          stockFilter: _filter,
          stockFilters: widget.stockOnly
              ? {
                  '': 'All products',
                  '#low': 'Low stock',
                  '#out': 'Out of stock',
                  '#private': 'Store only',
                  '#public': 'Public selected',
                  for (final brand in _brands) brand: brand,
                }
              : const {},
        ),
      ),
    );
    if (mounted && selected != null) {
      _resetBrowse(() {
        if (widget.stockOnly && selected.startsWith('#filter:')) {
          _filter = selected.substring(8);
        } else {
          _category = selected;
        }
      });
    }
  }

  Widget _saveControl(WorkspaceCatalogueItem product) => IconButton(
    key: Key('work-catalogue-bookmark-${product.id}'),
    tooltip: _saved.contains(_saveKey(product))
        ? 'Remove from shortlist'
        : 'Save for later',
    isSelected: _saved.contains(_saveKey(product)),
    onPressed: () => _bookmark(product),
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    padding: EdgeInsets.zero,
    iconSize: 20,
    color: MoolColors.navy,
    icon: const Icon(Icons.bookmark_border_rounded),
    selectedIcon: const Icon(Icons.bookmark_rounded),
  );

  Widget _viewControl() => IconButton(
    key: const Key('work-catalogue-view-toggle'),
    tooltip: _listView ? 'Grid view' : 'List view',
    color: MoolColors.navy,
    onPressed: () => _resetBrowse(() => _listView = !_listView),
    icon: Icon(
      _listView ? Icons.grid_view_rounded : Icons.view_list_rounded,
      size: 22,
    ),
  );

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
    final entries = _indexed
        .where(
          (entry) =>
              (_category.isEmpty || _categoryKey(entry.product) == _category) &&
              (!_savedOnly || _saved.contains(_saveKey(entry.product))) &&
              _matchesFilter(entry.product) &&
              (query.isEmpty || entry.search.contains(query)),
        )
        .map((entry) => entry.product)
        .toList(growable: false);
    final visibleCount = _pageLimit.clamp(0, entries.length);
    final lowCount = entries
        .where(
          (p) =>
              p.stockMode == WorkspaceStockMode.exactQuantity &&
              p.stock > 0 &&
              p.stock <= p.lowStockThreshold,
        )
        .length;
    final outCount = entries
        .where(
          (p) => p.stockMode == WorkspaceStockMode.exactQuantity
              ? p.stock <= 0
              : !p.available,
        )
        .length;
    final subtitle =
        '${_category.isEmpty ? '' : '${_categoryLabel(_category)} · '}'
        '${entries.length} ${entries.length == 1 ? 'product' : 'products'}'
        '${_savedOnly ? ' · Shortlisted' : ''}'
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
                  color: Colors.white,
                  child: Row(
                    children: [
                      if (widget.embedded && !widget.stockOnly)
                        const BackButton(),
                      Expanded(
                        child: TextField(
                          key: const Key('work-add-products-search'),
                          controller: _search,
                          focusNode: _searchFocus,
                          minLines: 1,
                          maxLines: widget.stockOnly ? 6 : 1,
                          onChanged: (_) => _resetBrowse(() {
                            _barcode = '';
                            _scanError = null;
                          }),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) {
                            _rememberQuery();
                            _searchFocus.unfocus();
                            final code = _search.text.trim();
                            if (!widget.stockOnly &&
                                (RegExp(r'^\d{6,}$').hasMatch(code) ||
                                    _indexed.any(
                                      (entry) => entry.product.barcode == code,
                                    ))) {
                              _reviewBarcode(code);
                            }
                          },
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: MoolColors.navy,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                MediaQuery.textScalerOf(context).scale(1) > 1.3
                                ? 'Search'
                                : widget.stockOnly
                                ? 'Search products'
                                : 'Type a product name',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            hintMaxLines: 1,
                            filled: false,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 48,
                            ),
                            prefixIcon: widget.stockOnly
                                ? IconButton(
                                    key: const Key('work-catalogue-category'),
                                    tooltip: 'Categories and stock filters',
                                    onPressed: _chooseCategory,
                                    icon: Icon(
                                      Icons.menu_rounded,
                                      size: 21,
                                      color:
                                          _category.isNotEmpty ||
                                              _filter.isNotEmpty
                                          ? MoolColors.orange
                                          : MoolColors.navy,
                                    ),
                                  )
                                : const Icon(
                                    Icons.search_rounded,
                                    size: 21,
                                    color: MoolColors.navy,
                                  ),
                            suffixIcon:
                                widget.stockOnly &&
                                    _searchFocus.hasFocus &&
                                    query.isEmpty &&
                                    _category.isEmpty &&
                                    _filter.isEmpty &&
                                    !_savedOnly
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_category.isNotEmpty ||
                                          _filter.isNotEmpty ||
                                          _savedOnly ||
                                          query.isNotEmpty)
                                        IconButton(
                                          key: const Key(
                                            'work-catalogue-clear',
                                          ),
                                          tooltip: 'Clear search and filters',
                                          onPressed: () => _resetBrowse(() {
                                            _search.clear();
                                            _barcode = '';
                                            _scanError = null;
                                            _category = '';
                                            _filter = '';
                                            _savedOnly = false;
                                          }),
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 20,
                                          ),
                                        ),
                                      if (!widget.stockOnly &&
                                          MediaQuery.textScalerOf(
                                                context,
                                              ).scale(1) >
                                              1.3)
                                        _viewControl(),
                                      if (!widget.stockOnly ||
                                          !_searchFocus.hasFocus)
                                        IconButton(
                                          key: const Key(
                                            'work-add-products-scan',
                                          ),
                                          tooltip: 'Scan barcode',
                                          onPressed: _scanning ? null : _scan,
                                          icon: const Icon(
                                            Icons.qr_code_scanner,
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
                if (!widget.stockOnly)
                  Container(
                    key: const Key('work-catalogue-toolbar'),
                    padding: EdgeInsets.fromLTRB(
                      6,
                      widget.stockOnly ? 0 : 6,
                      6,
                      widget.stockOnly ? 0 : 5,
                    ),
                    color: Colors.white,
                    child: Row(
                      children: [
                        IconButton(
                          key: const Key('work-catalogue-category'),
                          tooltip: 'Choose category',
                          onPressed: _chooseCategory,
                          padding: EdgeInsets.zero,
                          icon: _control(
                            Icons.menu_rounded,
                            'Category',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.stockOnly
                                            ? 'Store stock'
                                            : 'Catalogue',
                                        key: widget.stockOnly
                                            ? const Key(
                                                'work-catalogue-heading',
                                              )
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
                                            : widget.stockOnly
                                            ? '$subtitle${lowCount > 0 ? ' · $lowCount low' : ''}${outCount > 0 ? ' · $outCount out' : ''}'
                                            : subtitle,
                                        key: widget.stockOnly
                                            ? const Key('work-stock-summary')
                                            : null,
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
                        if (!widget.stockOnly)
                          IconButton(
                            key: const Key('work-catalogue-saved'),
                            tooltip: _savedOnly
                                ? 'Show all products'
                                : 'Saved shortlist (${_saved.length})',
                            onPressed: () => _resetBrowse(() {
                              _savedOnly = !_savedOnly;
                            }),
                            padding: EdgeInsets.zero,
                            icon: SizedBox.square(
                              dimension: 48,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _savedOnly
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    size: 18,
                                  ),
                                  const Text(
                                    'Saved',
                                    style: TextStyle(fontSize: 9),
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        PopupMenuButton<String>(
                          key: const Key('work-catalogue-filter'),
                          tooltip: 'Filter products',
                          color: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xffe8ebf0)),
                          ),
                          style: const ButtonStyle(
                            foregroundColor: WidgetStatePropertyAll(
                              Color(0xff30343b),
                            ),
                          ),
                          initialValue: _filter,
                          onSelected: (value) => _resetBrowse(() {
                            _filter = value;
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
                        if (!widget.stockOnly &&
                            MediaQuery.textScalerOf(context).scale(1) <= 1.3)
                          _viewControl(),
                      ],
                    ),
                  ),
                if (!widget.stockOnly) const SizedBox(height: 8),
                if (widget.stockOnly && widget.stockExportBuilder != null)
                  Visibility(
                    maintainState: true,
                    visible:
                        !((MediaQuery.viewInsetsOf(context).bottom > 0 ||
                                View.of(context).viewInsets.bottom > 0) &&
                            _searchFocus.hasFocus),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                  ),
                if (!widget.stockOnly &&
                    (_category.isNotEmpty || _filter.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (_category.isNotEmpty)
                          InputChip(
                            label: Text(_categoryLabel(_category)),
                            onDeleted: () => _resetBrowse(() => _category = ''),
                          ),
                        if (_filter.isNotEmpty)
                          InputChip(
                            label: Text(
                              _filter == 'new' ? 'Not added yet' : _filter,
                            ),
                            onDeleted: () => _resetBrowse(() => _filter = ''),
                          ),
                      ],
                    ),
                  ),
                if (!widget.stockOnly && _searchFocus.hasFocus) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Find products for your Store. Can't scan? Enter the barcode number.",
                        style: TextStyle(fontSize: 12, color: MoolColors.muted),
                      ),
                    ),
                  ),
                  if (_history.isNotEmpty && query.isEmpty)
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          for (final term in _history)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                avatar: const Icon(Icons.history, size: 16),
                                label: Text(term),
                                onPressed: () {
                                  _resetBrowse(() => _search.text = term);
                                  _searchFocus.unfocus();
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.stockOnly
                                      ? (widget.ownedProducts.isEmpty
                                            ? 'No products saved yet. Open Store → Add products to add your stock.'
                                            : 'No matching stock. Try another search or filter.')
                                      : _savedOnly && _saved.isEmpty
                                      ? 'Your shortlist is empty. Tap the bookmark on a product, then review it before adding to Store.'
                                      : _savedOnly
                                      ? 'No shortlisted products match. Clear search and filters to see your shortlist.'
                                      : 'No matching products. Try clearing search and filters.',
                                ),
                                if (_search.text.isNotEmpty ||
                                    _barcode.isNotEmpty ||
                                    _category.isNotEmpty ||
                                    _filter.isNotEmpty)
                                  TextButton(
                                    key: const Key(
                                      'work-catalogue-clear-filters',
                                    ),
                                    onPressed: () => _resetBrowse(() {
                                      _search.clear();
                                      _barcode = '';
                                      _category = '';
                                      _filter = '';
                                    }),
                                    child: const Text(
                                      'Clear search and filters',
                                    ),
                                  ),
                              ],
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
                            // Buy's proportional fit, in a smaller Store square.
                            final cardWidth =
                                (grid.maxWidth - 16 - (columns - 1) * 8) /
                                columns;
                            // Buy's card also reserves a 1px inset per side.
                            final photoExtent =
                                StoreProductThumbnail.gridExtent(cardWidth);
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
                                      sliver: _listView || columns == 1
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
                                                    : _listView
                                                    ? _listTile(entries[index])
                                                    : _tile(
                                                        entries[index],
                                                        photoExtent:
                                                            photoExtent,
                                                        intrinsicHeight: true,
                                                      ),
                                              ),
                                            )
                                          : SliverGrid.builder(
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: columns,
                                                    crossAxisSpacing: 8,
                                                    mainAxisSpacing: 8,
                                                    mainAxisExtent:
                                                        (widget.stockOnly
                                                            ? 92
                                                            : 44 +
                                                                  photoExtent) +
                                                        (widget.stockOnly
                                                                ? 114
                                                                : 84) *
                                                            scale,
                                                  ),
                                              itemCount: visibleCount,
                                              itemBuilder: (_, index) => _tile(
                                                entries[index],
                                                photoExtent: photoExtent,
                                              ),
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
    child: SizedBox(
      width: 48,
      height: 48,
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
          backgroundColor: BuyV2Colors.navy,
          textColor: Colors.white,
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
    _rememberQuery();
    _searchFocus.unfocus();
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

  Widget _catalogueAction(WorkspaceCatalogueItem product, bool added) =>
      DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: added
                ? const [Color(0xfff1f6f2), Colors.white]
                : const [Color(0xffeef0f8), Colors.white],
          ),
        ),
        child: TextButton(
          key: Key('work-catalogue-add-${product.id}'),
          style: TextButton.styleFrom(
            foregroundColor: MoolColors.navy,
            backgroundColor: Colors.transparent,
            minimumSize: const Size(44, 48),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () => _activate(product),
          child: Tooltip(
            message: added
                ? 'Added to Store · edit product'
                : 'Review product to add',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(added ? Icons.check_rounded : Icons.add_rounded, size: 12),
                const SizedBox(width: 2),
                Flexible(child: Text(added ? 'Edit' : 'Add')),
              ],
            ),
          ),
        ),
      );

  Widget _listTile(WorkspaceCatalogueItem product) {
    final owned = _owned(product);
    final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final action = SizedBox(
      width: enlarged ? double.infinity : 84,
      height: 48,
      child: _catalogueAction(product, owned != null),
    );
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide.none,
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
                  StoreProductThumbnail(product: product, extent: 36),
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
                              color: Color(0xff30343b),
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
                              color: Color(0xff555b65),
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
                              : product.brand,
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
                  if (!widget.stockOnly) _saveControl(product),
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

  Widget _tile(
    WorkspaceCatalogueItem product, {
    required double photoExtent,
    bool intrinsicHeight = false,
  }) {
    final owned = _owned(product);
    void act() => _activate(product);

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('work-add-product-${product.id}'),
        onTap: act,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: photoExtent,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StoreProductThumbnail(
                          key: Key('work-catalogue-thumbnail-${product.id}'),
                          product: product,
                          extent: photoExtent,
                        ),
                      ),
                    ),
                  ),
                  if (!widget.stockOnly) _saveControl(product),
                ],
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
                    color: Color(0xff30343b),
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
                      color: Color(0xff555b65),
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
                    : product.brand,
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
              if (intrinsicHeight)
                const SizedBox(height: 6)
              else
                const Spacer(),
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: _catalogueAction(product, owned != null),
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
