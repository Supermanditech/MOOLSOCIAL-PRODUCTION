import 'dart:convert';

import 'package:excel_community/excel_community.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'work_models.dart';

typedef StoreStockFileSaver =
    Future<bool> Function(
      Uint8List bytes,
      String fileName,
      StoreStockExportFormat format,
    );

Future<Uint8List> generateStoreStockFile(
  StoreStockSnapshot snapshot,
  StoreStockExportFormat format,
) => snapshot.generate(format);

Future<bool> saveStoreStockFile(
  Uint8List bytes,
  String fileName,
  StoreStockExportFormat format,
) async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      return await const MethodChannel(
            'com.moolsocial.app/store_stock_download',
          ).invokeMethod<bool>('save', {
            'bytes': bytes,
            'fileName': fileName,
            'mimeType': format.mimeType,
          }) ==
          true;
    } on PlatformException catch (error) {
      if (error.code == 'stock_download_unsupported') {
        throw const FormatException(
          'Direct downloads require Android 10 or later.',
        );
      }
      throw const FormatException(
        'Could not save to Downloads. Please try again.',
      );
    } on MissingPluginException {
      throw const FormatException(
        'Downloads are unavailable in this app version.',
      );
    }
  }
  return await FilePicker.saveFile(
        dialogTitle: fileName == 'store-products-template.csv'
            ? 'Save CSV template'
            : 'Save stock statement',
        fileName: fileName,
        mimeType: format.mimeType,
        type: FileType.custom,
        allowedExtensions: [format.extension],
        bytes: bytes,
      ) !=
      null;
}

enum StoreStockPeriod { current, today, week, month, custom }

Future<String?> downloadStoreProductCsvTemplate() async {
  final saved = await saveStoreStockFile(
    Uint8List.fromList(utf8.encode(WorkspaceProductImport.csvTemplate)),
    'store-products-template.csv',
    StoreStockExportFormat.csv,
  );
  if (!saved) return 'Template download cancelled. Try again.';
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'Template saved in Downloads / MoolSocial.'
      : 'CSV template saved.';
}

class StoreStockDownloadControls extends StatefulWidget {
  const StoreStockDownloadControls({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.filteredProducts,
    required this.filterDescription,
    required this.isCurrent,
    this.onCurrentPeriodChanged,
    this.scopeChanges,
    this.saveFile = saveStoreStockFile,
    this.generateFile = generateStoreStockFile,
  });
  final String storeId, storeName, filterDescription;
  final List<WorkspaceCatalogueItem> filteredProducts;
  final bool Function() isCurrent;
  final Listenable? scopeChanges;
  final ValueChanged<bool>? onCurrentPeriodChanged;
  final StoreStockFileSaver saveFile;
  final Future<Uint8List> Function(StoreStockSnapshot, StoreStockExportFormat)
  generateFile;
  @override
  State<StoreStockDownloadControls> createState() =>
      _StoreStockDownloadControlsState();
}

class _StoreStockDownloadControlsState
    extends State<StoreStockDownloadControls> {
  StoreStockPeriod _period = StoreStockPeriod.current;
  StoreStockExportFormat? _busy;
  String? _status;
  bool _invalidated = false;
  void _trackScope() {
    if (!widget.isCurrent()) _invalidated = true;
  }

  bool get _isCurrent => !_invalidated && widget.isCurrent();
  @override
  void initState() {
    super.initState();
    widget.scopeChanges?.addListener(_trackScope);
  }

  @override
  void didUpdateWidget(StoreStockDownloadControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scopeChanges != widget.scopeChanges) {
      oldWidget.scopeChanges?.removeListener(_trackScope);
      widget.scopeChanges?.addListener(_trackScope);
    }
    _trackScope();
  }

  final _from = TextEditingController();
  final _to = TextEditingController();
  static const _labels = [
    'Current stock',
    'Today',
    'This week',
    'This month',
    'Custom dates',
  ];
  @override
  void dispose() {
    widget.scopeChanges?.removeListener(_trackScope);
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  DateTime? _date(String value) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value.trim());
    if (match == null) return null;
    final d = int.parse(match[1]!);
    final m = int.parse(match[2]!);
    final y = int.parse(match[3]!);
    final date = DateTime(y, m, d);
    return date.year == y && date.month == m && date.day == d ? date : null;
  }

  String _label(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String get _periodDescription {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_period == StoreStockPeriod.custom) {
      if (_from.text.isEmpty || _to.text.isEmpty) {
        return 'Enter both dates as DD/MM/YYYY.';
      }
      final from = _date(_from.text), to = _date(_to.text);
      if (from == null || to == null) return 'Enter valid dates as DD/MM/YYYY.';
      if (from.isAfter(to)) return 'From date must be on or before To date.';
      if (to.isAfter(today)) return 'Choose dates up to today.';
      return '${_label(from)} – ${_label(to)}';
    }
    final from = switch (_period) {
      StoreStockPeriod.week => today.subtract(
        Duration(days: today.weekday - 1),
      ),
      StoreStockPeriod.month => DateTime(today.year, today.month),
      _ => today,
    };
    return from == today ? _label(today) : '${_label(from)} – ${_label(today)}';
  }

  Future<void> _download(StoreStockExportFormat format) async {
    if (_busy != null ||
        _period != StoreStockPeriod.current ||
        widget.filteredProducts.isEmpty) {
      return;
    }
    setState(() {
      _busy = format;
      _status = null;
    });
    try {
      if (!_isCurrent) {
        throw const FormatException(
          'Your store changed. Reopen Reports & Downloads.',
        );
      }
      final snapshot = StoreStockSnapshot(
        storeId: widget.storeId,
        storeName: widget.storeName,
        scope: widget.filterDescription.isEmpty
            ? 'All Store stock'
            : 'Current results: ${widget.filterDescription}',
        generatedAt: DateTime.now(),
        products: widget.filteredProducts,
      );
      final bytes = await widget.generateFile(snapshot, format);
      if (!mounted) return;
      if (!_isCurrent) {
        throw const FormatException(
          'Your store changed. Reopen Reports & Downloads.',
        );
      }
      final saved = await widget.saveFile(
        bytes,
        snapshot.fileName(format),
        format,
      );
      if (!mounted) return;
      setState(
        () => _status = !_isCurrent
            ? 'Your store changed. Check the file saved for the previous store.'
            : saved
            ? '${format.label} saved · ${snapshot.rows.length} products'
            : 'Download cancelled. Tap a format to try again.',
      );
    } on FormatException catch (e) {
      if (mounted) setState(() => _status = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Could not save. Tap a format to try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _period == StoreStockPeriod.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PopupMenuButton<StoreStockPeriod>(
              key: const Key('work-stock-period-selector'),
              tooltip: 'Statement period',
              enabled: _busy == null,
              initialValue: _period,
              onSelected: (period) {
                setState(() {
                  _period = period;
                  _status = null;
                });
                widget.onCurrentPeriodChanged?.call(
                  period == StoreStockPeriod.current,
                );
              },
              itemBuilder: (_) => [
                for (final period in StoreStockPeriod.values)
                  PopupMenuItem(
                    key: Key('work-stock-period-${period.name}'),
                    value: period,
                    child: Text(_labels[period.index]),
                  ),
              ],
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      current ? 'Current' : _labels[_period.index],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded, size: 18),
                  ],
                ),
              ),
            ),
            for (final format in StoreStockExportFormat.values)
              TextButton(
                key: Key('work-stock-download-${format.extension}'),
                onPressed:
                    !current || _busy != null || widget.filteredProducts.isEmpty
                    ? null
                    : () => _download(format),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: Text(
                  _busy == format ? 'Preparing…' : format.label,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        if (_period == StoreStockPeriod.custom)
          LayoutBuilder(
            builder: (context, box) {
              Widget field(
                String label,
                TextEditingController controller,
                String key,
              ) => TextField(
                key: Key(key),
                controller: controller,
                keyboardType: TextInputType.datetime,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: label,
                  hintText: 'DD/MM/YYYY',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              );
              final from = field('From', _from, 'work-stock-from');
              final to = field('To', _to, 'work-stock-to');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MediaQuery.textScalerOf(context).scale(1) > 1.5
                    ? Column(children: [from, const SizedBox(height: 8), to])
                    : Row(
                        children: [
                          Expanded(child: from),
                          const SizedBox(width: 8),
                          Expanded(child: to),
                        ],
                      ),
              );
            },
          ),
        if (!current)
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 6),
            child: Text(
              'Historical stock statements are unavailable. Current stock is not used for past dates.',
              key: Key('work-stock-history-unavailable'),
              style: TextStyle(fontSize: 12),
            ),
          ),
        if (!current)
          Text(
            _periodDescription,
            key: const Key('work-stock-period-range'),
            style: const TextStyle(fontSize: 12),
          ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _status!,
                key: const Key('work-stock-export-status'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (_status?.contains(' saved · ') == true &&
            widget.saveFile == saveStoreStockFile &&
            !kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android)
          const Text(
            'Saved in Downloads / MoolSocial.',
            style: TextStyle(fontSize: 12),
          ),
      ],
    );
  }
}

enum StoreStockExportFormat {
  pdf('PDF', 'pdf', 'application/pdf'),
  excel(
    'Excel',
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ),
  csv('CSV', 'csv', 'text/csv');

  const StoreStockExportFormat(this.label, this.extension, this.mimeType);
  final String label, extension, mimeType;
}

/// Immutable current balances, not an accounting ledger or physical stock count.
/// The caller supplies the whole selected dataset, never only visible rows.
class StoreStockSnapshot {
  StoreStockSnapshot({
    required this.storeId,
    required this.storeName,
    required this.scope,
    required this.generatedAt,
    required List<WorkspaceCatalogueItem> products,
  }) : rows = List.unmodifiable(
         products.map(
           (p) => List<Object?>.unmodifiable([
             p.title,
             p.sku,
             p.barcode,
             p.brand,
             p.variant,
             p.pack,
             p.categoryId,
             p.stockMode == WorkspaceStockMode.exactQuantity ? p.stock : null,
             p.stockMode == WorkspaceStockMode.exactQuantity
                 ? 'Exact quantity'
                 : 'Availability only',
             p.available ? 'Available' : 'Unavailable',
             p.sellingPrice,
             p.purchasePrice,
             p.mrp,
             p.stockMode == WorkspaceStockMode.exactQuantity
                 ? p.lowStockThreshold
                 : null,
             p.publicListing ? 'Public selected' : 'Store only',
             p.minimumOrder,
             p.unitPrice,
             p.origin,
             p.compliance?.genericName,
             p.compliance?.netQuantity,
             p.compliance?.manufacturerName,
             p.compliance?.packerName,
             p.compliance?.importerName,
             p.compliance?.countryOfOrigin,
             p.compliance?.manufacturedOrPackedOn,
             p.compliance?.bestBeforeOrUseBy,
             p.compliance?.fssaiLicenseNumber,
             p.compliance?.consumerCare,
             p.deliveryPromise,
             p.returnPolicy,
             p.composition,
             p.regulatoryNote,
           ]),
         ),
       ) {
    if (storeId.trim().isEmpty ||
        storeName.trim().isEmpty ||
        rows.isEmpty ||
        rows.length > 10000) {
      throw const FormatException(
        'Choose between 1 and 10,000 saved products.',
      );
    }
  }

  final String storeId, storeName, scope;
  final DateTime generatedAt;
  final List<List<Object?>> rows;
  static const headers = [
    'Product',
    'SKU',
    'Barcode',
    'Brand',
    'Variant',
    'Pack',
    'Category',
    'Recorded stock',
    'Stock tracking',
    'Availability',
    'Selling price (INR)',
    'Purchase price (INR)',
    'MRP (INR)',
    'Reorder level',
    'Visibility selection',
    'Minimum order',
    'Unit price',
    'Origin',
    'Generic name',
    'Net quantity',
    'Manufacturer',
    'Packer',
    'Importer',
    'Country of origin',
    'Packed on',
    'Best before / use by',
    'FSSAI',
    'Consumer care',
    'Delivery terms',
    'Return terms',
    'Composition',
    'Regulatory note',
  ];
  String get timestamp => generatedAt.toUtc().toIso8601String();
  String fileName(StoreStockExportFormat format) =>
      'stock-snapshot-${timestamp.replaceAll(RegExp(r'[^0-9]'), '')}.${format.extension}';

  List<List<Object?>> get exportRows => [
    ['Current stock snapshot'],
    ['Store', storeName, 'Store ID', storeId],
    ['Generated at (UTC)', timestamp],
    ['Scope', scope, 'Products', rows.length],
    ['Current recorded balances; not a historical or audited statement.'],
    headers,
    ...rows,
  ];

  Future<Uint8List> generate(StoreStockExportFormat format) async {
    final font = format == StoreStockExportFormat.pdf
        ? await rootBundle.load('assets/fonts/Inter-Variable.ttf')
        : null;
    return compute(_generateStockFile, (this, format, font));
  }
}

Future<Uint8List> _generateStockFile(
  (StoreStockSnapshot, StoreStockExportFormat, ByteData?) input,
) async {
  final (snapshot, format, fontData) = input;
  if (format == StoreStockExportFormat.csv) {
    String cell(Object? value) {
      var text = value?.toString() ?? '';
      // Strings cannot become formulae when opened by spreadsheet software.
      if (value is String &&
          RegExp(r'^[\s\u0000-\u001f]*[=+@-]').hasMatch(text)) {
        text = "'$text";
      }
      return '"${text.replaceAll('"', '""')}"';
    }

    final records = <List<Object?>>[
      [
        'Report',
        'Store',
        'Store ID',
        'Generated at (UTC)',
        'Scope',
        ...StoreStockSnapshot.headers,
      ],
      for (final row in snapshot.rows)
        [
          'Current stock snapshot',
          snapshot.storeName,
          snapshot.storeId,
          snapshot.timestamp,
          snapshot.scope,
          ...row,
        ],
    ];
    return Uint8List.fromList(
      utf8.encode(
        '\ufeff${records.map((r) => r.map(cell).join(',')).join('\r\n')}\r\n',
      ),
    );
  }
  if (format == StoreStockExportFormat.excel) {
    final book = xls.Excel.createExcel();
    book.rename('Sheet1', 'Current stock');
    final sheet = book['Current stock'];
    final all = snapshot.exportRows;
    for (var r = 0; r < all.length; r++) {
      for (var c = 0; c < all[r].length; c++) {
        final value = all[r][c];
        final cell = sheet.cell(
          xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        );
        cell.value = value is int
            ? xls.IntCellValue(value)
            : value == null
            ? null
            : xls.TextCellValue(value.toString());
        cell.cellStyle = xls.CellStyle(
          fontFamily: 'Arial',
          fontSize: r == 0 ? 14 : 10,
          bold: r == 0 || r == 5,
          fontColorHex: xls.ExcelColor.fromHexString(
            r == 5 ? '#FFFFFF' : '#14234B',
          ),
          backgroundColorHex: xls.ExcelColor.fromHexString(
            r == 5 ? '#080078' : '#FFFFFF',
          ),
          verticalAlign: xls.VerticalAlign.Center,
          horizontalAlign: value is num
              ? xls.HorizontalAlign.Right
              : xls.HorizontalAlign.Left,
          textWrapping: xls.TextWrapping.WrapText,
          numberFormat: value is String
              ? xls.NumFormat.standard_49
              : xls.CustomNumericNumFormat(formatCode: '#,##0'),
        );
      }
      var lines = 1;
      for (var c = 0; c < all[r].length; c++) {
        final width = c == 0
            ? 40
            : c >= 18
            ? 32
            : 24;
        final textLines = (all[r][c]?.toString() ?? '')
            .split('\n')
            .fold<int>(
              0,
              (sum, line) =>
                  sum + (line.length / (width * .8)).ceil().clamp(1, 1000),
            );
        if (textLines > lines) lines = textLines;
      }
      sheet.setRowHeight(r, (lines * 13.0 + 8).clamp(r == 5 ? 32 : 22, 409));
    }
    for (var c = 0; c < StoreStockSnapshot.headers.length; c++) {
      sheet.setColumnWidth(
        c,
        c == 0
            ? 40
            : c >= 18
            ? 32
            : 24,
      );
    }
    return Uint8List.fromList(book.encode()!);
  }
  final document = pw.Document();
  final font = pw.Font.ttf(fontData!);
  final embedded = font.getFont(pw.Context(document: document.document));
  final text = [
    snapshot.storeName,
    snapshot.storeId,
    snapshot.scope,
    ...snapshot.rows.expand((r) => [for (var c = 0; c <= 14; c++) r[c]]),
  ].join(' ');
  if (text.runes.any((r) => r > 32 && !embedded.isRuneSupported(r))) {
    throw const FormatException(
      'Some characters cannot be shown in PDF. Choose Excel or CSV to keep all details.',
    );
  }
  pw.Widget table(
    List<String> headers,
    List<List<String>> rows,
    Map<int, pw.TableColumnWidth> widths,
  ) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    columnWidths: widths,
    border: null,
    cellPadding: const pw.EdgeInsets.all(5),
    headerDecoration: const pw.BoxDecoration(
      color: PdfColor.fromInt(0xff080078),
    ),
    headerStyle: pw.TextStyle(
      fontSize: 9,
      color: PdfColors.white,
      fontWeight: pw.FontWeight.bold,
    ),
    cellStyle: const pw.TextStyle(fontSize: 9),
    oddRowDecoration: const pw.BoxDecoration(
      color: PdfColor.fromInt(0xfff5f6fb),
    ),
    cellAlignment: pw.Alignment.centerLeft,
    cellAlignments: headers.length == 7
        ? {for (var c = 1; c <= 5; c++) c: pw.Alignment.centerRight}
        : {},
  );
  // Bound each table's layout work. One giant spanning table repeatedly lays
  // out the remaining rows on every page and becomes quadratic for 10k SKUs.
  for (var start = 0; start < snapshot.rows.length; start += 50) {
    final batch = snapshot.rows.sublist(
      start,
      (start + 50).clamp(0, snapshot.rows.length),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        maxPages: 20000,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Current stock snapshot',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                '${snapshot.storeName} | ${snapshot.storeId}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                '${snapshot.timestamp} (UTC) | ${snapshot.scope} | ${snapshot.rows.length} products',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        footer: (c) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Current recorded balances. Not a historical or audited statement.',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              '${c.pageNumber} / ${c.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (_) => [
          table(
            [
              'Product / SKU / pack',
              'Stock',
              'Selling INR',
              'Purchase INR',
              'MRP INR',
              'Reorder',
              'Availability',
            ],
            batch
                .map(
                  (r) => [
                    '${r[0]}\n${r[1]} | ${r[5]}',
                    r[7]?.toString() ?? 'Not tracked',
                    '${r[10]}',
                    '${r[11]}',
                    r[12]?.toString() ?? 'Not set',
                    r[13]?.toString() ?? 'N/A',
                    '${r[9]}',
                  ],
                )
                .toList(),
            {
              0: const pw.FlexColumnWidth(3),
              for (var c = 1; c < 7; c++) c: const pw.FlexColumnWidth(1),
            },
          ),
          pw.NewPage(),
          pw.Text('Stock references', style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 10),
          // Keep a stock PDF readable; full product/pack metadata is in Excel/CSV.
          table(
            [
              'Product / SKU',
              'Barcode',
              'Brand / variant',
              'Category',
              'Visibility selection',
            ],
            [
              for (final r in batch)
                [
                  '${r[0]}\n${r[1]}',
                  '${r[2]}',
                  '${r[3]}\n${r[4]}',
                  '${r[6]}',
                  '${r[14]}',
                ],
            ],
            {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
          ),
        ],
      ),
    );
  }
  return document.save();
}
