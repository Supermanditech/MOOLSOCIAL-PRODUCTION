import 'dart:async';
import 'dart:convert';

import 'package:excel_community/excel_community.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'work_models.dart';
import '../../shared/commerce/commerce_invoice_pdf.dart'
    show saveCommercePrintPages;

enum StorePrintState {
  completed,
  cancelled,
  unavailable,
  failed,
  submitted,
  blocked,
  unknown,
}

enum StorePrintPaper {
  printer('Printer settings'),
  a4('A4'),
  receipt58('58 mm receipt'),
  receipt80('80 mm receipt');

  const StorePrintPaper(this.label);
  final String label;
  // An initial suggestion only: native onLayout reports the printer's actual
  // selected paper. Never force a thermal layout onto reported A4 or vice versa.
  PdfPageFormat get initialFormat => switch (this) {
    printer || a4 => PdfPageFormat.a4,
    receipt58 => PdfPageFormat(58 * PdfPageFormat.mm, 200 * PdfPageFormat.mm),
    receipt80 => PdfPageFormat(80 * PdfPageFormat.mm, 200 * PdfPageFormat.mm),
  };
}

/// One contextual print action, with explicit paper suggestions when printer
/// configuration is ambiguous. No printer settings or device discovery clone.
class StorePrintButton extends StatelessWidget {
  const StorePrintButton({
    super.key,
    required this.onSelected,
    this.tooltip = 'Print document',
  });
  final ValueChanged<StorePrintPaper>? onSelected;
  final String tooltip;
  @override
  Widget build(BuildContext context) => PopupMenuButton<StorePrintPaper>(
    tooltip: tooltip,
    enabled: onSelected != null,
    onSelected: onSelected,
    icon: const Icon(Icons.print_outlined),
    itemBuilder: (_) => [
      for (final paper in StorePrintPaper.values)
        PopupMenuItem(
          value: paper,
          key: ValueKey('store-print-paper-${paper.name}'),
          child: Text(paper.label),
        ),
    ],
  );
}

/// One explicit, scoped OS print handoff. A queued job is not printed paper.
/// Native requests a new layout when the selected printer/media changes.
class StoreDocumentPrinter {
  static const channel = MethodChannel(
    'com.moolsocial.app/store_document_print',
  );
  static int _sequence = 0;
  static bool _busy = false;

  static Future<StorePrintState> print({
    required String name,
    required bool Function() isCurrent,
    required Listenable scopeChanges,
    required Future<Uint8List> Function(PdfPageFormat, List<int>?) render,
    PdfPageFormat initialFormat = PdfPageFormat.a4,
  }) async {
    if (_busy || !isCurrent()) return StorePrintState.unavailable;
    if (name.isEmpty ||
        name.length > 160 ||
        name.contains(RegExp(r'[\x00-\x1f]'))) {
      return StorePrintState.unavailable;
    }
    _busy = true;
    final id =
        'store-print-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
    final requests = MethodChannel(
      'com.moolsocial.app/store_document_print/$id',
    );
    var invalidated = false;
    Future<void> cancel() async {
      try {
        await channel
            .invokeMethod<void>('cancel', {'id': id})
            .timeout(const Duration(seconds: 3));
      } on Object {
        // Never replace an unknown native outcome with a success claim.
      }
    }

    void changed() {
      if (!isCurrent() && !invalidated) {
        invalidated = true;
        unawaited(cancel());
      }
    }

    scopeChanges.addListener(changed);
    requests.setMethodCallHandler((call) async {
      if (call.method != 'render' || invalidated || !isCurrent()) {
        throw PlatformException(code: 'print_scope_changed');
      }
      final args = call.arguments;
      if (args is! Map || args['id'] != id) {
        throw PlatformException(code: 'invalid_print_request');
      }
      double number(String key) {
        final value = args[key];
        if (value is! num || !value.toDouble().isFinite || value < 0) {
          throw PlatformException(code: 'invalid_print_paper');
        }
        return value.toDouble();
      }

      final width = number('width'), height = number('height');
      final left = number('left'), top = number('top');
      final right = number('right'), bottom = number('bottom');
      if (width < 48 * PdfPageFormat.mm ||
          width > 330 * PdfPageFormat.mm ||
          height < 100 * PdfPageFormat.mm ||
          height > 1000 * PdfPageFormat.mm ||
          width - left - right < 40 * PdfPageFormat.mm ||
          height - top - bottom < 70 * PdfPageFormat.mm) {
        throw PlatformException(code: 'unsupported_print_paper');
      }
      final rawPages = args['pages'];
      List<int>? pages;
      if (rawPages != null) {
        if (rawPages is! List ||
            rawPages.isEmpty ||
            rawPages.length > 100 ||
            rawPages.any((p) => p is! int || p < 0 || p >= 100)) {
          throw PlatformException(code: 'invalid_print_pages');
        }
        pages = rawPages.cast<int>().toSet().toList()..sort();
      }
      final bytes = await render(
        PdfPageFormat(
          width,
          height,
          marginLeft: left,
          marginTop: top,
          marginRight: right,
          marginBottom: bottom,
        ),
        pages,
      ).timeout(const Duration(seconds: 30));
      if (invalidated || !isCurrent()) {
        throw PlatformException(code: 'print_scope_changed');
      }
      if (bytes.length < 8 ||
          bytes.length > 10 * 1024 * 1024 ||
          String.fromCharCodes(bytes.take(5)) != '%PDF-') {
        throw PlatformException(code: 'invalid_print_document');
      }
      return bytes;
    });
    try {
      final outcome = await channel
          .invokeMethod<String>('print', {
            'id': id,
            'name': name,
            'width': initialFormat.width,
            'height': initialFormat.height,
          })
          .timeout(const Duration(minutes: 3));
      if (invalidated || !isCurrent()) return StorePrintState.cancelled;
      return StorePrintState.values
              .where((s) => s.name == outcome)
              .firstOrNull ??
          StorePrintState.unknown;
    } on MissingPluginException {
      return StorePrintState.unavailable;
    } on TimeoutException {
      await cancel();
      return StorePrintState.unknown;
    } on PlatformException catch (error) {
      return error.code == 'print_unavailable'
          ? StorePrintState.unavailable
          : StorePrintState.failed;
    } on Object {
      // A malformed native reply cannot establish whether a job was queued.
      // Request cancellation and preserve uncertainty; do not retry silently.
      await cancel();
      return StorePrintState.unknown;
    } finally {
      scopeChanges.removeListener(changed);
      requests.setMethodCallHandler(null);
      _busy = false;
    }
  }
}

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
  // The installed direct-download bridge admits stock/customer filenames only.
  // Use the already-registered system picker for separate Sales/supplier documents;
  // never disguise it as a stock/customer report or weaken native validation.
  final supplierStatement = RegExp(r'^supplier-statement-[a-f0-9]{16}\.(pdf|csv)$').hasMatch(fileName) &&
      (format == StoreStockExportFormat.pdf || format == StoreStockExportFormat.csv) &&
      fileName.endsWith('.${format.extension}');
  final analyticsStatement = RegExp(r'^store-analytics-[A-F0-9]{16}\.pdf$').hasMatch(fileName) &&
      format == StoreStockExportFormat.pdf;
  if (analyticsStatement || supplierStatement || (RegExp(r'^sales-collections-[A-F0-9]{16}\.pdf$').hasMatch(fileName) &&
      format == StoreStockExportFormat.pdf)) {
    return await FilePicker.saveFile(
      dialogTitle: analyticsStatement ? 'Save Store analytics' : supplierStatement ? 'Save supplier statement' : 'Save Sales & Collections Statement',
      fileName: fileName,
      mimeType: format.mimeType,
      type: FileType.custom,
      allowedExtensions: [format.extension],
      bytes: bytes,
    ) != null;
  }
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
    this.accountId,
    this.ledger,
    this.scopeChanges,
    this.saveFile = saveStoreStockFile,
    this.generateFile = generateStoreStockFile,
  });
  final String storeId, storeName, filterDescription;
  final String? accountId;
  final StoreStockLedgerSnapshot? ledger;
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
  final _printChanges = ValueNotifier<int>(0);
  void _trackScope() {
    if (!widget.isCurrent()) _invalidated = true;
    _printChanges.value++;
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
    if (oldWidget.accountId != widget.accountId ||
        oldWidget.storeId != widget.storeId) {
      _invalidated = true;
    }
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
    _invalidated = true;
    _trackScope();
    _printChanges.dispose();
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
  (DateTime, DateTime)? get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = switch (_period) {
      StoreStockPeriod.current => null,
      StoreStockPeriod.today => today,
      StoreStockPeriod.week => DateTime(
        now.year,
        now.month,
        now.day - today.weekday + 1,
      ),
      StoreStockPeriod.month => DateTime(now.year, now.month),
      StoreStockPeriod.custom => _date(_from.text),
    };
    final to = _period == StoreStockPeriod.custom ? _date(_to.text) : today;
    if (from == null || to == null || from.isAfter(to) || to.isAfter(today)) {
      return null;
    }
    return (from.toUtc(), DateTime(to.year, to.month, to.day + 1).toUtc());
  }

  StoreStockLedgerSnapshot? get _ledger {
    final report = widget.ledger, range = _range;
    return _isCurrent &&
            report != null &&
            report.valid &&
            range != null &&
            report.accountId == widget.accountId &&
            report.storeId == widget.storeId &&
            report.from.toUtc() == range.$1 &&
            report.until.toUtc() == range.$2
        ? report
        : null;
  }

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

  Future<void> _print(StorePrintPaper paper) async {
    final current = _period == StoreStockPeriod.current;
    final ledger = current ? null : _ledger;
    if (_busy != null ||
        !_isCurrent ||
        (current ? widget.filteredProducts.isEmpty : ledger == null)) {
      return;
    }
    final revision = _printChanges.value;
    bool valid() => mounted && _isCurrent && revision == _printChanges.value;
    setState(() {
      _busy = StoreStockExportFormat.pdf;
      _status = null;
    });
    try {
      final snapshot = current
          ? StoreStockSnapshot(
              storeId: widget.storeId,
              storeName: widget.storeName,
              scope: widget.filterDescription.isEmpty
                  ? 'All Store stock'
                  : 'Current results: ${widget.filterDescription}',
              generatedAt: DateTime.now(),
              products: widget.filteredProducts,
            )
          : null;
      final state = await StoreDocumentPrinter.print(
        name: current ? 'Current stock snapshot' : 'Stock statement',
        initialFormat: paper.initialFormat,
        isCurrent: valid,
        scopeChanges: _printChanges,
        render: (media, pages) => current
            ? snapshot!.forPrint(media, pages)
            : ledger!.forPrint(media, pages),
      );
      if (mounted) {
        setState(
          () => _status = !valid()
              ? 'Stock changed. Reopen the statement before printing.'
              : switch (state) {
                  StorePrintState.completed =>
                    'The print service reports completion. Check your printer.',
                  StorePrintState.cancelled => 'Printing cancelled.',
                  StorePrintState.unavailable =>
                    'Printing is unavailable. Enable a compatible print service in phone settings.',
                  StorePrintState.failed =>
                    'Printing failed. Check the printer and retry.',
                  StorePrintState.submitted =>
                    'Sent to the print queue. Check the printer for completion.',
                  StorePrintState.blocked =>
                    'The print queue needs attention. Check the printer connection, paper and ink.',
                  StorePrintState.unknown =>
                    'Print status could not be confirmed. Check the print queue before retrying.',
                },
        );
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _status = error.message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _download(StoreStockExportFormat format) async {
    final ledger = _ledger;
    if (_busy != null ||
        (_period == StoreStockPeriod.current
            ? widget.filteredProducts.isEmpty
            : ledger == null)) {
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
      final snapshot = ledger == null
          ? StoreStockSnapshot(
              storeId: widget.storeId,
              storeName: widget.storeName,
              scope: widget.filterDescription.isEmpty
                  ? 'All Store stock'
                  : 'Current results: ${widget.filterDescription}',
              generatedAt: DateTime.now(),
              products: widget.filteredProducts,
            )
          : null;
      final bytes = ledger == null
          ? await widget.generateFile(snapshot!, format)
          : await ledger.generate(format);
      if (!mounted) return;
      if (!_isCurrent) {
        throw const FormatException(
          'Your store changed. Reopen Reports & Downloads.',
        );
      }
      if (ledger != null && !identical(ledger, _ledger)) {
        throw const FormatException(
          'The statement changed. Download it again.',
        );
      }
      final saved = await widget.saveFile(
        bytes,
        ledger?.fileName(format) ?? snapshot!.fileName(format),
        format,
      );
      if (!mounted) return;
      setState(
        () => _status = !_isCurrent
            ? 'Your store changed. Check the file saved for the previous store.'
            : saved
            ? '${format.label} saved · ${ledger?.lines.length ?? snapshot!.rows.length} products'
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
    final ledger = _ledger;
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
                    _busy != null ||
                        (current
                            ? widget.filteredProducts.isEmpty
                            : ledger == null)
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
            StorePrintButton(
              key: const Key('work-stock-print'),
              tooltip: 'Print stock statement',
              onSelected:
                  !_isCurrent ||
                      _busy != null ||
                      (current
                          ? widget.filteredProducts.isEmpty
                          : ledger == null)
                  ? null
                  : _print,
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
        if (!current && ledger == null)
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
        if (ledger != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              ledger.disclosure,
              key: const Key('work-stock-ledger-disclosure'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          StoreStockLedgerTable(ledger: ledger),
          StoreStockValueSummary(ledger: ledger),
        ],
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

/// Physical stock, not reservation events or today's available-stock snapshot.
/// The provider supplies period totals and valuation; the client only reconciles.
class StoreStockLedgerLine {
  const StoreStockLedgerLine({
    required this.productId,
    required this.name,
    required this.pack,
    required this.opening,
    required this.received,
    required this.issued,
    required this.closing,
    required this.reserved,
    this.openingValueMinor,
    this.receivedValueMinor,
    this.issuedValueMinor,
    this.closingValueMinor,
  });
  final String productId, name, pack;
  final int opening, received, issued, closing, reserved;
  final int? openingValueMinor,
      receivedValueMinor,
      issuedValueMinor,
      closingValueMinor;
  int get available => closing - reserved;
  bool get hasValuation => closingValueMinor != null;
  bool get valid {
    final quantities = [opening, received, issued, closing, reserved];
    final values = [
      openingValueMinor,
      receivedValueMinor,
      issuedValueMinor,
      closingValueMinor,
    ];
    return productId.trim().isNotEmpty &&
        name.trim().isNotEmpty &&
        pack.trim().isNotEmpty &&
        quantities.every((v) => v >= 0 && v <= 2147483647) &&
        opening + received - issued == closing &&
        reserved <= closing &&
        (values.every((v) => v == null) ||
            (values.every(
                  (v) => v != null && v >= 0 && v <= 9007199254740991,
                ) &&
                openingValueMinor! + receivedValueMinor! - issuedValueMinor! ==
                    closingValueMinor));
  }
}

/// Exact, complete period response for Reports & Downloads. No local movement
/// list is promoted to this contract and no missing balance is treated as zero.
class StoreStockLedgerSnapshot {
  StoreStockLedgerSnapshot({
    required this.accountId,
    required this.storeId,
    required this.storeName,
    required this.snapshotId,
    required this.from,
    required this.until,
    required this.observedAt,
    required this.complete,
    required this.reviewOnly,
    required List<StoreStockLedgerLine> lines,
    this.valuationMethod,
  }) : lines = List.unmodifiable(lines);
  final String accountId, storeId, storeName, snapshotId;
  final DateTime from, until, observedAt;
  final bool complete, reviewOnly;
  final String? valuationMethod;
  final List<StoreStockLedgerLine> lines;
  bool get valid =>
      accountId.trim().isNotEmpty &&
      storeId.trim().isNotEmpty &&
      storeName.trim().isNotEmpty &&
      snapshotId.trim().isNotEmpty &&
      complete &&
      from.isBefore(until) &&
      !observedAt.isBefore(from) &&
      lines.length <= 10000 &&
      lines.every((line) => line.valid) &&
      lines.map((line) => line.productId).toSet().length == lines.length &&
      (lines.any((line) => line.hasValuation)
          ? valuationMethod?.trim().isNotEmpty == true
          : valuationMethod == null);
  int? get closingValueMinor =>
      lines.every((line) => line.hasValuation) && lines.isNotEmpty
      ? lines.fold<int>(0, (sum, line) => sum + line.closingValueMinor!)
      : null;
  String get disclosure => reviewOnly
      ? 'Test statement · not issued'
      : 'Stock ledger · valuation ${valuationMethod ?? 'unavailable'}';
  static const headers = [
    'SKU',
    'Product',
    'Pack',
    'Opening Balance (Quantity)',
    'Inwards (Quantity)',
    'Outwards (Quantity)',
    'Closing Balance (Quantity)',
    'Reserved',
    'Available',
    'Closing Balance Value (₹)',
    'Opening Balance Value (₹)',
    'Inwards Value (₹)',
    'Outwards Value (₹)',
  ];
  List<List<Object?>> get rows => [
    for (final line in lines)
      [
        line.productId,
        line.name,
        line.pack,
        line.opening,
        line.received,
        line.issued,
        line.closing,
        line.reserved,
        line.available,
        line.closingValueMinor == null ? null : line.closingValueMinor! / 100,
        line.openingValueMinor == null ? null : line.openingValueMinor! / 100,
        line.receivedValueMinor == null ? null : line.receivedValueMinor! / 100,
        line.issuedValueMinor == null ? null : line.issuedValueMinor! / 100,
      ],
  ];
  String fileName(StoreStockExportFormat format) =>
      'stock-ledger-${storeId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}'
      '-${from.toIso8601String().substring(0, 10)}.${format.extension}';
  Future<Uint8List> generate(StoreStockExportFormat format) async {
    if (!valid) {
      throw const FormatException(
        'The stock statement is incomplete or inconsistent.',
      );
    }
    final font = format == StoreStockExportFormat.pdf
        ? await rootBundle.load('assets/fonts/Inter-Variable.ttf')
        : null;
    return compute(_generateStockLedgerFile, (this, format, font));
  }

  Future<Uint8List> forPrint(PdfPageFormat paper, List<int>? pages) async {
    if (!valid) {
      throw const FormatException(
        'The stock statement is incomplete or inconsistent.',
      );
    }
    final font = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    return compute(_generatePrintedStockLedger, (this, font, paper, pages));
  }
}

class StoreStockValueSummary extends StatelessWidget {
  const StoreStockValueSummary({super.key, required this.ledger});
  final StoreStockLedgerSnapshot ledger;

  @override
  Widget build(BuildContext context) {
    final complete =
        ledger.valid &&
        ledger.lines.isNotEmpty &&
        ledger.lines.every((line) => line.hasValuation);
    final selectors = <(String, int? Function(StoreStockLedgerLine))>[
      ('Opening Balance', (line) => line.openingValueMinor),
      ('Inwards', (line) => line.receivedValueMinor),
      ('Outwards', (line) => line.issuedValueMinor),
      ('Closing Balance', (line) => line.closingValueMinor),
    ];
    return Padding(
      key: const Key('stock-value-summary'),
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stock Summary · Value (₹)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          for (final entry in selectors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(entry.$1, style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      complete
                          ? (ledger.lines.fold<int>(
                                      0,
                                      (sum, line) => sum + entry.$2(line)!,
                                    ) /
                                    100)
                                .toStringAsFixed(2)
                          : 'Unavailable',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class StoreStockLedgerTable extends StatefulWidget {
  const StoreStockLedgerTable({super.key, required this.ledger});
  final StoreStockLedgerSnapshot ledger;
  @override
  State<StoreStockLedgerTable> createState() => _StoreStockLedgerTableState();
}

class _StoreStockLedgerTableState extends State<StoreStockLedgerTable> {
  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    final widths = [
      140.0,
      170.0,
      72.0,
      78.0,
      68.0,
      68.0,
      78.0,
      86.0,
      86.0,
      140.0,
      140.0,
      140.0,
      140.0,
    ];
    for (var i = 0; i < widths.length; i++) {
      if (i != 1) widths[i] *= scale.scale(1);
    }
    const labels = [
      'SKU',
      'Product',
      'Pack',
      'Opening Balance',
      'Inwards',
      'Outwards',
      'Closing Balance',
      'Reserved',
      'Available',
    ];
    const order = [1, 2, 3, 4, 5, 6, 7, 8, 0];
    String cellText(Object? value, int i) => value == null
        ? 'Unavailable'
        : i >= 9 && value is num
        ? value.toStringAsFixed(2)
        : '$value';
    double rowHeight(List<Object?> values) {
      var height = 0.0;
      for (final i in order) {
        final painter = TextPainter(
          text: TextSpan(
            text: cellText(values[i], i),
            style: TextStyle(
              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textScaler: scale,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: widths[i] - 16);
        if (painter.height > height) height = painter.height;
        painter.dispose();
      }
      return height + 21;
    }

    // Lead with the product, not a wide internal identifier. Export order is
    // unchanged; the identifier stays reachable at the end of the table.
    Widget row(List<Object?> values, {bool header = false}) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final i in order)
          SizedBox(
            width: widths[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Text(
                cellText(values[i], i),
                textAlign: i >= 3 ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontSize: 12,
                  color: header ? Colors.white : const Color(0xff14234b),
                  fontWeight: header ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
      ],
    );
    if (widget.ledger.lines.isEmpty) {
      return const Text('No stock recorded for this period.');
    }
    final rows = widget.ledger.rows;
    return SizedBox(
      key: const Key('work-stock-ledger-table'),
      height:
          (rowHeight(labels) +
                  rows
                      .take(5)
                      .fold<double>(
                        0,
                        (sum, values) => sum + rowHeight(values),
                      ) +
                  12)
              .clamp(80, 360)
              .toDouble(),
      child: Scrollbar(
        controller: _horizontal,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontal,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: order.fold<double>(0, (sum, i) => sum + widths[i]),
            child: Column(
              children: [
                ColoredBox(
                  color: const Color(0xff080078),
                  child: row(labels, header: true),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _vertical,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _vertical,
                      itemCount: rows.length,
                      itemBuilder: (_, i) => DecoratedBox(
                        key: ValueKey(
                          'stock-ledger-row-${widget.ledger.lines[i].productId}',
                        ),
                        decoration: BoxDecoration(
                          color: i.isOdd
                              ? const Color(0xfff5f6fb)
                              : Colors.white,
                          border: const Border(
                            bottom: BorderSide(color: Color(0xffe9edf5)),
                          ),
                        ),
                        child: row(rows[i]),
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

Future<Uint8List> _generatePrintedStockLedger(
  (StoreStockLedgerSnapshot, ByteData, PdfPageFormat, List<int>?) input,
) => _generateStockLedgerFile(
  (input.$1, StoreStockExportFormat.pdf, input.$2),
  paper: input.$3,
  pages: input.$4,
);

Future<Uint8List> _generateStockLedgerFile(
  (StoreStockLedgerSnapshot, StoreStockExportFormat, ByteData?) input, {
  PdfPageFormat? paper,
  List<int>? pages,
}) async {
  final (report, format, fontData) = input;
  final metadata = <List<Object?>>[
    ['Stock ledger', report.disclosure],
    ['Store', report.storeName, 'Store ID', report.storeId],
    [
      'From (inclusive UTC)',
      report.from.toUtc().toIso8601String(),
      'Until (exclusive UTC)',
      report.until.toUtc().toIso8601String(),
    ],
    [
      'Observed at (UTC)',
      report.observedAt.toUtc().toIso8601String(),
      'Snapshot',
      report.snapshotId,
    ],
    ['Valuation', report.valuationMethod ?? 'Unavailable'],
  ];
  final rows = report.rows;
  if (format == StoreStockExportFormat.csv) {
    String cell(Object? value) {
      var text = value?.toString() ?? '';
      if (value is String &&
          RegExp(r'^[\s\u0000-\u001f]*[=+@-]').hasMatch(text)) {
        text = "'$text";
      }
      return '"${text.replaceAll('"', '""')}"';
    }

    final records = [
      [
        'Report',
        'Store',
        'Store ID',
        'Snapshot',
        'From (UTC)',
        'Until (UTC)',
        'Observed (UTC)',
        'Valuation',
        ...StoreStockLedgerSnapshot.headers,
      ],
      // An empty complete report must retain its scope without inventing a SKU
      // or a zero balance. Empty product cells distinguish this metadata record.
      for (final row
          in rows.isEmpty
              ? [
                  List<Object?>.filled(
                    StoreStockLedgerSnapshot.headers.length,
                    null,
                  ),
                ]
              : rows)
        [
          report.disclosure,
          report.storeName,
          report.storeId,
          report.snapshotId,
          report.from.toUtc().toIso8601String(),
          report.until.toUtc().toIso8601String(),
          report.observedAt.toUtc().toIso8601String(),
          report.valuationMethod ?? 'Unavailable',
          ...row,
        ],
    ];
    return Uint8List.fromList(
      utf8.encode(
        '\ufeff${records.map((r) => r.map(cell).join(',')).join('\r\n')}\r\n',
      ),
    );
  }
  return _generateStoreTable(
    (
      StoreTabularReport(
        title: 'Stock ledger',
        disclosure: report.disclosure,
        metadata: metadata,
        headers: StoreStockLedgerSnapshot.headers,
        rows: rows,
        moneyColumns: const {9, 10, 11, 12},
        rightAlignedColumns: const {3, 4, 5, 6, 7, 8},
      ),
      format,
      fontData,
    ),
    paper: paper,
    pages: pages,
  );
}

/// Purpose guidance only; choosing a copy never authorizes its business effect.
const storeTradeDocumentGuidance = <String, ({String label, String guide})>{
  'purchaseOrder': (label: 'Purchase order / Sales order', guide: 'The buyer’s purchase order is the supplier’s sales order.'),
  'orderConfirmation': (label: 'Order confirmation', guide: 'Confirmed items, quantities, prices, payment terms and delivery commitment.'),
  'orderAmendment': (label: 'Order amendment', guide: 'A recorded change to an order; retain the earlier agreed details.'),
  'orderCancellation': (label: 'Order cancellation', guide: 'Cancelled items, the reason and who cancelled them.'),
  'pickList': (label: 'Pick list', guide: 'Internal items and batches to pick for an order.'),
  'packingList': (label: 'Packing list', guide: 'Items, batches and cartons actually packed.'),
  'shortSupply': (label: 'Short supply / substitution', guide: 'Unavailable goods or a proposed replacement; check buyer agreement.'),
  'supplierInvoice': (label: 'Supplier invoice / bill', guide: 'Supplier’s bill. Record its invoice type and amounts in Purchase entry.'),
  'deliveryChallan': (label: 'Delivery challan', guide: 'Goods-movement document for an applicable purpose; not proof of payment.'),
  'ewayBill': (label: 'E-way bill', guide: 'Copy the portal-issued number and transport details; attaching it does not verify validity.'),
  'transportReceipt': (label: 'LR / GR / Bilty', guide: 'Transporter’s consignment receipt, number, date and carrier details.'),
  'freightBill': (label: 'Freight invoice / transport bill', guide: 'Transport charges billed by the carrier; keep separate from the goods invoice.'),
  'proofOfDelivery': (label: 'Delivery acknowledgment / POD', guide: 'Recipient’s acknowledgment and delivery evidence; check quantities actually received.'),
  'goodsReceipt': (label: 'Goods receipt note / GRN', guide: 'The buying Store’s record of goods physically received; distinct from a transporter’s GR.'),
  'shortageDamage': (label: 'Shortage / damage report', guide: 'Differences between dispatched and received goods, with supporting evidence.'),
  'failedDelivery': (label: 'Failed delivery / return to origin', guide: 'Undelivered or refused goods and their return movement.'),
  'paymentReceipt': (label: 'Payment receipt / collection voucher', guide: 'Receipt for an actual payment; a payment screenshot alone does not confirm funds received.'),
  'paymentAdvice': (label: 'Payment advice / remittance advice', guide: 'Invoices the payer intends to settle; not confirmation that money was received.'),
  'supplierRefundVoucher': (label: 'Supplier GST refund voucher', guide: 'Supplier-issued against an advance receipt when no supply or tax invoice follows. Keep the original receipt reference and printed GST details; this copy does not adjust GST.'),
  'creditApproval': (label: 'Credit terms / credit approval', guide: 'Buyer-specific credit approved by the supplier, including days and limit.'),
  'accountStatement': (label: 'Supplier / customer account statement', guide: 'Bills, payments, credits and outstanding from the relevant account’s perspective.'),
  'returnNote': (label: 'Purchase return / sales return note', guide: 'Returned goods and inspection; buyer’s purchase return is supplier’s sales return.'),
  'supplierCreditNote': (label: 'Supplier credit note', guide: 'Supplier-issued credit linked to the original bill; check GST or commercial treatment separately.'),
  'supplierDebitNote': (label: 'Supplier GST debit note', guide: 'Supplier-issued upward value or tax adjustment; not a buyer’s shortage claim.'),
  'commercialAdjustment': (label: 'Commercial credit adjustment', guide: 'Agreed financial adjustment; do not assume it changes GST.'),
  'claim': (label: 'Claim note / invoice dispute', guide: 'Buyer’s shortage, damage or invoice claim; keep the resolution separately.'),
  'balanceConfirmation': (label: 'Balance confirmation', guide: 'Account balance as at a stated date, with agreed or disputed differences.'),
  'settlement': (label: 'Settlement record', guide: 'Agreed resolution linked to payments and adjustments; not a new payment receipt.'),
  'other': (label: 'Other supporting document', guide: 'Copy its actual printed title and details; its purpose remains to be checked.'),
};

String storeTradeDocumentLabel(String type) => storeTradeDocumentGuidance[type]?.label ?? 'Document type not selected';
String storeTradeDocumentGuide(String type) => storeTradeDocumentGuidance[type]?.guide ?? 'Choose the purpose of the copy you are attaching.';

/// Display aliases only: legacy saved document types are not rewritten.
String storePurchaseDocumentTypeLabel(String raw) => switch (raw.trim().toLowerCase()) {
  'gst invoice' || 'tax invoice' => 'GST tax invoice',
  'bill of supply' => 'Bill of supply',
  'invoice-cum-bill of supply' => 'Invoice-cum-bill of supply',
  'non-gst purchase bill' => 'Non-GST purchase bill',
  'other bill' => 'Other supplier invoice',
  _ => raw,
};

/// Recording guidance, not evidence of registration, tax eligibility or payment.
String storePurchaseDocumentTypeUseCase(String raw) => switch (raw.trim().toLowerCase()) {
  'gst invoice' || 'tax invoice' => 'Supplier’s GST tax invoice, including e-invoices.',
  'bill of supply' => 'Composition or exempt supply; no separate GST.',
  'invoice-cum-bill of supply' => 'Taxable and exempt supplies to an unregistered buyer.',
  'non-gst purchase bill' => 'Unregistered supplier’s bill or cash memo.',
  'other bill' => 'Type not confirmed; copy the original title.',
  _ => 'Choose the supplier’s printed bill type.',
};

String storePurchaseDocumentTypeGuidance(String raw) => switch (raw.trim().toLowerCase()) {
  'gst invoice' || 'tax invoice' => 'Use the supplier’s Tax Invoice / GST Invoice. For an e-invoice, enter the IRN / QR details below. Payment terms are recorded separately.',
  'bill of supply' => 'Use a Bill of Supply for composition or exempt supplies. GST should not be charged separately.',
  'invoice-cum-bill of supply' => 'Invoice-cum-bill of supply: taxable and exempt supplies together to an unregistered buyer. Keep the printed taxable and exempt values separately.',
  'non-gst purchase bill' => 'Use only for an unregistered supplier’s bill or cash memo. A cash-paid GST invoice is still a GST tax invoice. Buyer reverse-charge obligations need separate review.',
  'other bill' => 'Document type and tax treatment are not confirmed. Copy the printed title and check the original. Orders, challans, credit notes and payment receipts are not purchase invoices.',
  _ => 'Choose the supplier’s printed bill type. Cash / credit terms are recorded under Payment; an e-invoice uses GST tax invoice.',
};

/// Keep a printed title verbatim; never classify an unknown bill as a tax invoice.
String storePurchaseSupplierDocumentHeading({required String title, required String type}) {
  if (title.trim().isNotEmpty) return title;
  return switch (type.trim().toLowerCase()) {
    'gst invoice' || 'tax invoice' => 'TAX INVOICE',
    'bill of supply' => 'BILL OF SUPPLY',
    'invoice-cum-bill of supply' => 'INVOICE-CUM-BILL OF SUPPLY',
    'non-gst purchase bill' => 'SUPPLIER BILL',
    _ => 'SUPPLIER INVOICE',
  };
}

const storePurchaseUnpostedVoucherNumber = 'Not assigned (draft)';
const storePurchaseSavedCopyVoucherNumber = 'Not assigned (not posted)';

enum StorePurchaseAccountingState { draft, unconfirmed, confirmed, otherRevision, unavailable }

/// Presentation evidence only: this cannot post a bill or assign a voucher.
class StorePurchaseAccountingSnapshot {
  const StorePurchaseAccountingSnapshot._(this.state, this.copy, this.scope, this.ledgerProof,
    this.ledgerRevision, this.asOf);
  static const draft = StorePurchaseAccountingSnapshot._(
    StorePurchaseAccountingState.draft, null, null, null, null, null);
  static const unavailable = StorePurchaseAccountingSnapshot._(
    StorePurchaseAccountingState.unavailable, null, null, null, null, null);
  factory StorePurchaseAccountingSnapshot.capture({required WorkspacePurchaseSavedCopy copy,
    required (String, String, bool)? scope, required bool recovered, WorkspaceSupplierLedger? ledger}) {
    if (!copy.valid || scope == null || !recovered) return unavailable;
    // A recovered journal with no supplier ledger proves this bill unconfirmed;
    // failed recovery does not. Do not conflate empty and unavailable records.
    if (ledger == null) {
      return StorePurchaseAccountingSnapshot._(StorePurchaseAccountingState.unconfirmed,
        copy, scope, 'no-supplier-ledger', null, null);
    }
    if (!ledger.valid ||
        ledger.accountScope != scope.$1 || ledger.workspaceId != scope.$2 ||
        ledger.supplierId != copy.supplier.id || ledger.openingRecord?.qa != scope.$3) {
      return unavailable;
    }
    final accepted = ledger.purchaseBills[copy.draft.id];
    final state = accepted == null ? StorePurchaseAccountingState.unconfirmed
      : jsonEncode(accepted.copy.toJson()) == jsonEncode(copy.toJson())
        ? StorePurchaseAccountingState.confirmed : StorePurchaseAccountingState.otherRevision;
    return StorePurchaseAccountingSnapshot._(state, copy, scope,
      jsonEncode(ledger.toJson()), ledger.revision, ledger.asOf);
  }
  final StorePurchaseAccountingState state;
  final WorkspacePurchaseSavedCopy? copy;
  final (String, String, bool)? scope;
  final String? ledgerProof;
  final int? ledgerRevision;
  final DateTime? asOf;
  String get label => switch (state) {
    StorePurchaseAccountingState.draft => 'Draft · not recorded in supplier account',
    StorePurchaseAccountingState.unconfirmed => 'Not recorded in supplier account',
    StorePurchaseAccountingState.confirmed => 'Recorded in supplier account',
    StorePurchaseAccountingState.otherRevision => 'Another revision is recorded · this copy is not recorded',
    StorePurchaseAccountingState.unavailable => 'Supplier account status unavailable',
  };
  String get voucher => switch (state) {
    StorePurchaseAccountingState.draft => storePurchaseUnpostedVoucherNumber,
    StorePurchaseAccountingState.unconfirmed => storePurchaseSavedCopyVoucherNumber,
    _ => 'No system voucher assigned',
  };
  String get copyHeading => state == StorePurchaseAccountingState.draft
    ? 'Purchase entry - Recorded copy (Draft)' : 'Purchase entry - Saved copy';
  String get copyExplanation =>
    'Recorded purchase details, not the supplier original. Downloading does not change stock, dues or payments.';
  bool sameEvidence(StorePurchaseAccountingSnapshot other) => state == other.state &&
    scope == other.scope && ledgerProof == other.ledgerProof &&
    jsonEncode(copy?.toJson()) == jsonEncode(other.copy?.toJson());
  bool matches(WorkspacePurchaseEntryDraft draft, WorkspaceSupplierProfile supplier,
    int revision, String storeId) => copy == null || (scope?.$2 == storeId &&
      copy!.revision == revision && jsonEncode(copy!.draft.toJson()) == jsonEncode(draft.toJson()) &&
      jsonEncode(copy!.supplier.toJson()) == jsonEncode(supplier.toJson()));
}

/// Bounded PDF continuations; joining them preserves the exact source text.
List<String> storePurchasePdfTextParts(String value) {
  if (value.isEmpty) return [''];
  final runes = value.runes.toList();
  bool separator(int rune) => String.fromCharCode(rune).trim().isEmpty;
  final parts = <String>[];
  for (var start = 0; start < runes.length;) {
    final limit = (start + 300).clamp(0, runes.length);
    var end = limit;
    if (end < runes.length && !separator(runes[end])) {
      while (end > start && !separator(runes[end - 1])) { end--; }
      // A single overlong token still needs bounded, rune-safe rows.
      if (end == start) end = limit;
    }
    parts.add(String.fromCharCodes(runes.sublist(start, end)));
    start = end;
  }
  return parts;
}

/// A copy of retailer entries with captured account status, not a reissued supplier bill.
/// Original attachments and their visual evidence remain separate documents.
String storePurchaseCopyDetailLabel(String key, String label, {required bool isSavedCopy}) =>
    isSavedCopy && key == 'receiptStatus' ? 'Goods status when copy saved'
      : isSavedCopy && key == 'taxTreatment' ? 'GST treatment recorded' : label;

const storePurchaseRecordedCopyHeading = 'Recorded purchase copy · not the supplier original';
const storePurchaseMissingValueLegend = '— = not entered, not zero.';
String storePurchaseOriginalAvailability(WorkspacePurchaseEntryDraft draft) =>
  draft.attachments.any((copy) => copy.documentDetails.isEmpty || copy.documentDetails['type'] == 'supplierInvoice')
    ? 'Supplier invoice copy attached separately.' : 'No supplier invoice copy attached.';
String? storePurchaseUnconfirmedDocumentGuide(String type) =>
  const {'GST invoice', 'Tax invoice', 'Bill of supply', 'Invoice-cum-bill of supply', 'Non-GST purchase bill'}.contains(type.trim())
    ? null : 'Document type and GST treatment unconfirmed · check the supplier original.';

Future<Uint8List> generateStorePurchaseRecordedCopy({
  required WorkspacePurchaseEntryDraft draft,
  required WorkspaceSupplierProfile supplier,
  required String storeName,
  required String storeId,
  required int revision,
  required Map<String, String> labels,
  bool isSavedCopy = false,
  StorePurchaseAccountingSnapshot? accounting,
}) async {
  final status = accounting ?? (isSavedCopy
    ? StorePurchaseAccountingSnapshot.unavailable : StorePurchaseAccountingSnapshot.draft);
  if (!draft.valid || supplier.validationError != null ||
      draft.supplierId != supplier.id || storeId.isEmpty || revision < 0 ||
      !status.matches(draft, supplier, revision, storeId) ||
      (isSavedCopy == (status.state == StorePurchaseAccountingState.draft))) {
    throw FormatException(isSavedCopy
      ? 'Reopen the saved purchase copy before downloading.'
      : 'Reopen the saved purchase draft before downloading.');
  }
  final font = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Variable.ttf'));
  final document = pw.Document(title: 'Recorded purchase copy - ${draft.invoiceReference}',
    author: 'MoolSocial', subject: '${status.label}; ${storePurchaseOriginalAvailability(draft)}');
  final embedded = font.getFont(pw.Context(document: document.document));
  final allText = [storeName, storeId, draft.id, supplier.id, supplier.name,
    supplier.phone, supplier.address, supplier.gstin, draft.invoiceReference, draft.invoiceDate,
    ...labels.values, ...draft.details.values, ...draft.goods.expand((r) => r.values),
    ...draft.printedTaxRows.expand((r) => r.values),
    ...draft.additionalFields.expand((f) => [f.label, f.value]),
  ].join(' ');
  if (allText.runes.any((r) => r > 32 && !embedded.isRuneSupported(r))) {
    throw const FormatException('Some bill characters cannot be shown in this PDF. Download the supplier copy to keep them.');
  }
  const ink = PdfColor.fromInt(0xff171b20);
  const navy = PdfColor.fromInt(0xff17395c);
  const rule = PdfColor.fromInt(0xff89929c);
  final border = pw.Border.all(color: rule, width: .5);
  const moneyKeys = {'cost', 'taxableValue', 'taxAmount', 'lineTotal', 'supplyValue',
    'billDiscount', 'cgst', 'sgstAmount', 'sgst', 'utgst', 'igst', 'cess', 'freight',
    'otherCharges', 'roundOff', 'totalTax', 'invoiceTotal', 'amountPayable', 'paidAmount',
    'mrp', 'sellingPrice', 'discount'};
  String label(String key) => storePurchaseCopyDetailLabel(key,
    labels[key] ?? key.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m[0]}')
      .replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase()), isSavedCopy: isSavedCopy);
  String amount(String raw) {
    final minor = WorkspacePurchaseEntryDraft.printedPaise(raw);
    if (minor == null) return raw.isEmpty ? '—' : raw;
    final digits = (minor.abs() ~/ 100).toString();
    final head = digits.length > 3 ? digits.substring(0, digits.length - 3) : '';
    final groups = <String>[];
    for (var end = head.length; end > 0; end -= 2) {
      groups.insert(0, head.substring(end >= 2 ? end - 2 : 0, end));
    }
    return '${minor < 0 ? '-' : ''}${head.isEmpty ? digits : '${groups.join(',')},${digits.substring(digits.length - 3)}'}'
      '.${(minor.abs() % 100).toString().padLeft(2, '0')}';
  }
  String displayed(String key, String? raw) => moneyKeys.contains(key)
    ? amount(raw ?? '') : (raw == null || raw.isEmpty ? '—' : raw);
  pw.Widget text(String value, {double size = 9, bool bold = false}) => pw.Text(value,
    style: pw.TextStyle(fontSize: size, color: ink,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal));
  // Split long source text into bounded rows, not ellipses or truncated values.
  List<String> chunks(String value) {
    if (value.isEmpty) return ['—'];
    return storePurchasePdfTextParts(value);
  }
  pw.Widget table(List<String> headers, List<List<String>> rows,
      {Map<int, pw.TableColumnWidth>? widths, Set<int> amounts = const {}}) =>
    pw.TableHelper.fromTextArray(headers: headers, data: rows, columnWidths: widths,
      border: pw.TableBorder.all(color: rule, width: .5),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xfff0f3f5)),
      headerStyle: pw.TextStyle(fontSize: 8, color: ink, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8, color: ink),
      cellPadding: const pw.EdgeInsets.all(5),
      cellAlignments: {for (final i in amounts) i: pw.Alignment.topRight});
  pw.Widget fields(Iterable<String> keys) => table(const ['Detail', 'As entered'], [
    for (final key in keys) if (draft.details[key]?.isNotEmpty ?? false)
      for (final (index, part) in chunks(draft.details[key]!).indexed)
        [index == 0 ? label(key) : '${label(key)} (continued)', moneyKeys.contains(key) ? amount(part) : part],
  ], widths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(2)});
  pw.Widget block(String heading, List<(String, String)> facts) => pw.Container(
    padding: const pw.EdgeInsets.all(9),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      text(heading, bold: true),
      for (final (key, value) in facts) if (value.isNotEmpty)
        pw.Padding(padding: const pw.EdgeInsets.only(top: 3), child: text('$key: $value')),
    ]));
  pw.Widget pair(pw.Widget left, pw.Widget right) => pw.Table(
    border: pw.TableBorder.all(color: rule, width: .5),
    columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FlexColumnWidth()},
    children: [pw.TableRow(children: [left, right])]);
  final d = draft.details;
  final topDeclaration = d['documentType'] == 'Bill of supply' &&
    d['billOfSupplyReason'] == 'Composition scheme' && d['printedDeclaration']?.trim().isNotEmpty == true;
  const coreItemKeys = {'printedSerial', 'name', 'pack', 'unitCode', 'hsn', 'cost', 'quantity',
    'taxableValue', 'taxAmount', 'lineTotal'};
  const posItemKeys = {'productId', 'receivedQuantity', 'damagedQuantity', 'shortQuantity',
    'sellingPrice', 'mrp', 'barcode', 'alreadyInStock'};
  const posKeys = {'receiptStatus', 'receivedDate', 'expectedDeliveryDate', 'shippingTerms',
    'paymentStatus', 'paidAmount', 'paymentMethod', 'paymentReference', 'paymentDate', 'paymentTerms'};
  final used = <String>{'documentTitle', 'documentType', 'documentCopy', 'supplierEmail', 'originalInvoiceDate',
    'dueDate', 'poReference', 'placeOfSupply', 'placeOfSupplyCode', 'buyerName', 'buyerAddress',
    'buyerPhone', 'buyerEmail', 'buyerGstin', 'buyerUin', 'buyerState', 'buyerStateCode',
    'deliveryAddress', 'deliveryState', 'deliveryStateCode'};
  final totalKeys = ['printedTotalItems', 'printedTotalQuantity', 'supplyValue', 'billDiscount',
    'taxableValue', 'cgst', 'sgstAmount', 'sgst', 'utgst', 'igst', 'cess', 'freight',
    'otherCharges', 'roundOff', 'totalTax', 'invoiceTotal', 'amountPayable', 'amountInWords'];
  final bankKeys = ['bankName', 'bankAccount', 'bankIfsc', 'bankBranch', 'upiType', 'upiId', 'paymentQrStatus'];
  final signKeys = ['printedCompanyLabel', 'signatureStatus', 'signatory', 'printedSignatoryLabel', 'printedDeclaration'];
  used.addAll([...totalKeys, ...bankKeys, ...signKeys, 'notes', 'terms', 'printedFooter', ...posKeys]);
  final financialKeys = totalKeys.where((key) => moneyKeys.contains(key) &&
    (d[key]?.isNotEmpty ?? false)).toList();
  final financialTable = pw.Table(columnWidths: const {0: pw.FlexColumnWidth(1.6),
      1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(1.2)}, children: [
    for (final key in financialKeys) pw.TableRow(children: [pw.SizedBox(),
      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Align(alignment: pw.Alignment.topRight,
        child: text(label(key).replaceAll('₹', '').trim(), bold: key == 'invoiceTotal', size: key == 'invoiceTotal' ? 12 : 9))),
      pw.Container(padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: rule, width: .5))),
        alignment: pw.Alignment.topRight,
        child: text('${WorkspacePurchaseEntryDraft.printedPaise(d[key]!) == null ? '' : '₹'}${amount(d[key]!)}',
          bold: key == 'invoiceTotal', size: key == 'invoiceTotal' ? 12 : 9)),
    ]),
  ]);
  final widgets = <pw.Widget>[
    text(status.copyHeading, size: 11, bold: true),
    pw.SizedBox(height: 5),
    text(status.copyExplanation, size: 8),
    text(storePurchaseOriginalAvailability(draft), size: 8),
    if (storePurchaseUnconfirmedDocumentGuide(d['documentType'] ?? '') case final message?) text(message, size: 8),
    pw.SizedBox(height: 10),
    pw.Container(width: PdfPageFormat.a4.width - 48, padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(border: border),
      child: pw.Text(storePurchaseSupplierDocumentHeading(
        title: d['documentTitle'] ?? '', type: d['documentType'] ?? ''),
        style: pw.TextStyle(fontSize: 19, fontWeight: pw.FontWeight.bold, color: navy))),
    if (topDeclaration) text(d['printedDeclaration']!, bold: true),
    pair(block('Supplier', [('Name', supplier.name), ('GSTIN', supplier.gstin),
      ('Address', supplier.address), ('Phone', supplier.phone), ('Email', d['supplierEmail'] ?? '')]),
      block('Invoice details', [('Supplier invoice No.', draft.invoiceReference), ('Invoice date', draft.invoiceDate),
        ('Supplier document type', storePurchaseDocumentTypeLabel(d['documentType'] ?? '')),
        for (final key in ['originalInvoiceDate', 'dueDate', 'poReference', 'placeOfSupply', 'placeOfSupplyCode', 'documentCopy'])
          (key == 'documentCopy' ? 'Copy marking on supplier bill' : label(key), d[key] ?? '')])),
    if (d.entries.any((e) => e.key.startsWith('buyer') && e.value.isNotEmpty) ||
        d.entries.any((e) => e.key.startsWith('delivery') && e.value.isNotEmpty))
      if (d.entries.any((e) => e.key.startsWith('buyer') && e.value.isNotEmpty) &&
          d.entries.any((e) => e.key.startsWith('delivery') && e.value.isNotEmpty))
        pair(block('Billed to', [for (final key in ['buyerName', 'buyerAddress', 'buyerPhone', 'buyerEmail',
          'buyerGstin', 'buyerUin', 'buyerState', 'buyerStateCode']) (label(key), d[key] ?? '')]),
          block('Shipping address', [for (final key in ['deliveryAddress', 'deliveryState', 'deliveryStateCode'])
            (label(key), d[key] ?? '')]))
      else block(d.entries.any((e) => e.key.startsWith('buyer') && e.value.isNotEmpty) ? 'Billed to' : 'Shipping address',
        [for (final key in ['buyerName', 'buyerAddress', 'buyerPhone', 'buyerEmail', 'buyerGstin', 'buyerUin',
          'buyerState', 'buyerStateCode', 'deliveryAddress', 'deliveryState', 'deliveryStateCode']) (label(key), d[key] ?? '')]),
    table(const ['#', 'Item / description', 'HSN / SAC', 'Units', 'Rate ₹', 'Qty',
      'Taxable ₹', 'Tax ₹', 'Amount ₹'], [
        for (final (index, line) in draft.goods.indexed)
          for (final (partIndex, part) in chunks([line['name'] ?? '', line['pack'] ?? ''].where((s) => s.isNotEmpty).join('\n')).indexed)
            [partIndex == 0 ? line['printedSerial']?.isNotEmpty == true ? line['printedSerial']! : '${index + 1}' : '${index + 1} cont.',
              part, if (partIndex == 0) ...[displayed('hsn', line['hsn']), displayed('unitCode', line['unitCode']),
                displayed('cost', line['cost']), displayed('quantity', line['quantity']),
                displayed('taxableValue', line['taxableValue']), displayed('taxAmount', line['taxAmount']),
                displayed('lineTotal', line['lineTotal'])] else ...List.filled(7, '')],
      ], widths: const {0: pw.FlexColumnWidth(.45), 1: pw.FlexColumnWidth(2.8),
        2: pw.FlexColumnWidth(.8), 3: pw.FlexColumnWidth(.7), 4: pw.FlexColumnWidth(.9),
        5: pw.FlexColumnWidth(.6), 6: pw.FlexColumnWidth(1), 7: pw.FlexColumnWidth(.9), 8: pw.FlexColumnWidth(1)},
      amounts: const {4, 5, 6, 7, 8}),
    pw.SizedBox(height: 8),
    if (['printedTotalItems', 'printedTotalQuantity'].any((key) => d[key]?.isNotEmpty ?? false))
      text([for (final key in ['printedTotalItems', 'printedTotalQuantity'])
        if (d[key]?.isNotEmpty ?? false) '${label(key)}: ${d[key]}'].join(' / ')),
    if (financialKeys.isNotEmpty)
      if (financialKeys.every((key) => d[key]!.runes.length <= 40))
        pw.Inseparable(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [text('Invoice totals as entered', bold: true), financialTable]))
      else ...[pw.NewPage(freeSpace: 180), text('Invoice totals as entered', bold: true), financialTable],
    if (d['amountInWords']?.isNotEmpty ?? false)
      for (final part in chunks(d['amountInWords']!))
        pw.Container(width: PdfPageFormat.a4.width - 48, padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(border: border), child: text('Amount in words: $part')),
  ];
  widgets.add(text('— = not entered, not zero. Compare missing details with the supplier copy.', size: 8));
  if (!d.entries.any((e) => e.key.startsWith('buyer') && e.value.isNotEmpty)) {
    widgets.add(text('Billed-to details not entered.', size: 8));
  }
  if (financialKeys.any((key) => WorkspacePurchaseEntryDraft.printedPaise(d[key]!) == null)) {
    widgets.add(text('Some amount fields contain text. Review them against the supplier bill; they are not calculated totals.', size: 8));
  }
  if (draft.printedTaxRows.isNotEmpty) {
    widgets.addAll([pw.SizedBox(height: 8), text('HSN / tax summary as on invoice', bold: true)]);
    final columns = WorkspacePurchaseEntryDraft.printedTaxKeys.where((key) => key == 'label' ||
      key == 'hsn' || draft.printedTaxRows.any((row) => row[key]?.isNotEmpty ?? false)).toList();
    for (var offset = 2; offset < columns.length; offset += 5) {
      final group = [...columns.take(2), ...columns.skip(offset).take(5)];
      widgets.add(table([for (final key in group) key == 'label' ? 'Row' : key == 'hsn' ? 'HSN / SAC' : label(key)],
        [for (final row in draft.printedTaxRows) [for (final key in group) displayed(key, row[key])]],
        amounts: {for (var i = 2; i < group.length; i++) i}));
    }
    if (columns.length == 2) {
      widgets.add(table(const ['Row', 'HSN / SAC'], [
        for (final row in draft.printedTaxRows) [displayed('label', row['label']), displayed('hsn', row['hsn'])]]));
    }
  }
  widgets.addAll([
    if (bankKeys.any((key) => d[key]?.isNotEmpty ?? false)) ...[
      pw.SizedBox(height: 8), text('Supplier bank / UPI instructions', bold: true), fields(bankKeys)],
    if (signKeys.any((key) => (!topDeclaration || key != 'printedDeclaration') && (d[key]?.isNotEmpty ?? false))) ...[
      pw.SizedBox(height: 8), text('Signatory details as entered from bill - not verified', bold: true),
      fields(signKeys.where((key) => !topDeclaration || key != 'printedDeclaration'))],
    if (['notes', 'terms', 'printedFooter'].any((key) => d[key]?.isNotEmpty ?? false)) ...[
      pw.SizedBox(height: 8), text('Notes & terms', bold: true), fields(['notes', 'terms', 'printedFooter'])],
    if (d.keys.any((k) => !used.contains(k))) fields(d.keys.where((k) => !used.contains(k))),
  ]);
  final itemDetails = <List<String>>[
    for (final (index, line) in draft.goods.indexed)
      for (final e in line.entries) if (!coreItemKeys.contains(e.key) && !posItemKeys.contains(e.key) && e.value.isNotEmpty)
        for (final (partIndex, part) in chunks(e.value).indexed)
          ['Item ${index + 1}', '${label(e.key)}${partIndex == 0 ? '' : ' (continued)'}',
            moneyKeys.contains(e.key) ? amount(part) : part],
  ];
  if (itemDetails.isNotEmpty) {
    widgets.addAll([text('Further item details', bold: true),
      table(const ['Item', 'Detail', 'As entered'], itemDetails)]);
  }
  if (draft.additionalFields.isNotEmpty) {
    widgets.addAll([text('Additional invoice details', bold: true),
      table(const ['Belongs to', 'Heading on invoice', 'As entered'], [
        for (final f in draft.additionalFields)
          for (final (index, part) in chunks(f.value).indexed)
            ['${f.section}${f.itemIndex == null ? '' : ' - Item ${f.itemIndex! + 1}'}'
              '${f.summaryIndex == null ? '' : ' - Tax row ${f.summaryIndex! + 1}'}'
              '${f.reviewed ? '' : ' - needs review'}', '${f.label}${index == 0 ? '' : ' (continued)'}', part],
      ])]);
  }
  final retailerItemRows = <List<String>>[
      for (final (index, line) in draft.goods.indexed)
        for (final e in line.entries) if (posItemKeys.contains(e.key) && e.key != 'productId' && e.value.isNotEmpty)
          ['Item ${index + 1}', label(e.key), displayed(e.key, e.value)],
  ];
  widgets.addAll([
    // Retailer-owned observations share the separate record annexure. They
    // must not leave a lone payment row between supplier and reference pages.
    pw.NewPage(),
    if (posKeys.any((key) => d[key]?.isNotEmpty ?? false) || retailerItemRows.isNotEmpty)
      ...[text('Goods & payment details - retailer record', bold: true),
        if (posKeys.any((key) => d[key]?.isNotEmpty ?? false)) fields(posKeys),
        if (retailerItemRows.isNotEmpty) table(const ['Item', 'Retailer detail', 'As entered'], retailerItemRows)],
    // Keep the heading and first short row together, without making an
    // arbitrarily large product-reference table unbreakable.
    pw.NewPage(freeSpace: 180),
    pw.SizedBox(height: 10),
    text('Record details - saved references', size: 13, bold: true),
      text(isSavedCopy
        ? 'For tracing this saved purchase copy. These references are not supplier-invoice fields.'
        : 'For tracing this saved draft. These references are not supplier-invoice fields.', size: 8),
      pw.SizedBox(height: 8), table(const ['Detail', 'Saved value'], [
      ['Purchase voucher No.', status.voucher],
      ['Supplier account status', status.label],
      if (status.ledgerRevision != null) ['Account revision', '${status.ledgerRevision}'],
      if (status.asOf != null) ['Account status as of (UTC)', status.asOf!.toUtc().toIso8601String()],
      ['Store', storeName], ['Store ID', storeId], [isSavedCopy ? 'Source entry ID' : 'Draft ID', draft.id], ['Supplier ID', supplier.id],
      ['Saved revision', '$revision'], ['Saved on (UTC)', draft.updatedAt.toUtc().toIso8601String()],
      for (final (index, line) in draft.goods.indexed)
        if (line['productId']?.isNotEmpty ?? false) ['Item ${index + 1} product ID', line['productId']!],
      for (final a in draft.attachments) ...[
        if (a.documentDetails['type'] case final type?) ['Supporting copy type', storeTradeDocumentLabel(type)],
        for (final e in a.documentDetails.entries)
          if (e.key != 'type') [switch (e.key) {'title' => 'Title on copy', 'reference' => 'Document reference', _ => 'Date on copy'}, e.value],
        ['Supplier copy SHA-256', a.digest],
      ],
    ]),
  ]);
  document.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(24), maxPages: 1000,
    theme: pw.ThemeData.withFont(base: font, bold: font),
    footer: (context) => pw.Padding(padding: const pw.EdgeInsets.only(top: 8), child:
      text('Recorded purchase copy | ${draft.invoiceReference} | ${status.label} | Page ${context.pageNumber} of ${context.pagesCount}', size: 8)),
    build: (_) => widgets));
  return document.save();
}

/// Shared renderer only. Callers must validate account, coverage and balances
/// before constructing a report; this does not authorize or issue a document.
class StoreReportPdfGroup {
  StoreReportPdfGroup(this.title, List<int> columns, List<int> rowIndexes)
      : columns = List.unmodifiable(columns),
        rowIndexes = List.unmodifiable(rowIndexes);
  final String title;
  final List<int> columns, rowIndexes;
}

class StoreTabularReport {
  StoreTabularReport({
    required this.title,
    required this.disclosure,
    required List<List<Object?>> metadata,
    List<List<Object?>> machineMetadata = const [],
    required List<String> headers,
    required List<List<Object?>> rows,
    required Set<int> moneyColumns,
    this.rightAlignedColumns = const {},
    this.nullLabel = 'Unavailable',
    this.dateColumns = const {},
    List<List<String>> summary = const [],
    List<StoreReportPdfGroup> pdfGroups = const [],
  }) : metadata = List.unmodifiable(
         metadata.map((r) => List<Object?>.unmodifiable(r)),
       ),
       machineMetadata = List.unmodifiable(
         machineMetadata.map((r) => List<Object?>.unmodifiable(r)),
       ),
       headers = List.unmodifiable(headers),
       rows = List.unmodifiable(rows.map((r) => List<Object?>.unmodifiable(r))),
       moneyColumns = Set.unmodifiable(moneyColumns),
       pdfGroups = List.unmodifiable(pdfGroups),
       summary = List.unmodifiable(
         summary.map((r) => List<String>.unmodifiable(r)),
       );
  final List<List<String>> summary;
  final List<StoreReportPdfGroup> pdfGroups;

  void validatePdfGroups() {
    if (pdfGroups.isEmpty) return;
    final covered = <int>{};
    for (final group in pdfGroups) {
      if (group.title.trim().isEmpty || group.columns.length < 3 ||
          group.columns.toSet().length != group.columns.length ||
          group.columns.any((i) => i < 0 || i >= headers.length)) {
        throw const FormatException('Invalid statement section.');
      }
      for (final r in group.rowIndexes) {
        if (r < 0 || r >= rows.length || !covered.add(r) ||
            rows[r].length != headers.length) {
          throw const FormatException('Statement section records do not match.');
        }
        for (var c = 0; c < headers.length; c++) {
          if (!group.columns.contains(c) && rows[r][c] != '') {
            throw const FormatException('Statement section would omit a field.');
          }
        }
      }
    }
    if (covered.length != rows.length) {
      throw const FormatException('Statement section coverage is incomplete.');
    }
  }
  final String title, disclosure;
  final List<List<Object?>> metadata, machineMetadata, rows;
  final List<String> headers;
  final Set<int> moneyColumns;
  final Set<int> rightAlignedColumns;
  final String nullLabel;
  final Set<int> dateColumns;
  Future<Uint8List> generate(StoreStockExportFormat format) async {
    final font = format == StoreStockExportFormat.pdf
        ? await rootBundle.load('assets/fonts/Inter-Variable.ttf')
        : null;
    return compute(_generateStoreTable, (this, format, font));
  }

  Future<Uint8List> forPrint(PdfPageFormat paper, List<int>? pages) async {
    final font = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    return compute(_generatePrintedStoreTable, (this, font, paper, pages));
  }
}

Future<Uint8List> _generatePrintedStoreTable(
  (StoreTabularReport, ByteData, PdfPageFormat, List<int>?) input,
) => _generateStoreTable(
  (input.$1, StoreStockExportFormat.pdf, input.$2),
  paper: input.$3,
  pages: input.$4,
);

Future<Uint8List> _generateStoreTable(
  (StoreTabularReport, StoreStockExportFormat, ByteData?) input, {
  PdfPageFormat? paper,
  List<int>? pages,
}) async {
  final (report, format, fontData) = input;
  final metadata = [
        ...report.metadata,
        if (format != StoreStockExportFormat.pdf) ...report.machineMetadata,
        if (format != StoreStockExportFormat.pdf) ...report.summary,
      ],
      rows = report.rows;
  final headers = report.headers, moneyColumns = report.moneyColumns;
  final headerRow = metadata.length;
  if (format == StoreStockExportFormat.csv) {
    String cell(Object? value) {
      var text = value?.toString() ?? '';
      if (value is String &&
          RegExp(r'^[\s\u0000-\u001f]*[=+@-]').hasMatch(text)) {
        text = "'$text";
      }
      return '"${text.replaceAll('"', '""')}"';
    }

    final contextHeaders = [for (final r in metadata) '${r.first}'];
    final contextValues = [for (final r in metadata) r.skip(1).join(' · ')];
    final records = <List<Object?>>[
      [...contextHeaders, ...headers],
      for (final row
          in rows.isEmpty ? [List<Object?>.filled(headers.length, null)] : rows)
        [...contextValues, ...row],
    ];
    return Uint8List.fromList(
      utf8.encode(
        '\ufeff${records.map((r) => r.map(cell).join(',')).join('\r\n')}\r\n',
      ),
    );
  }
  if (format == StoreStockExportFormat.excel) {
    final book = xls.Excel.createExcel()..rename('Sheet1', report.title);
    final sheet = book[report.title];
    final all = [...metadata, headers, ...rows];
    for (var r = 0; r < all.length; r++) {
      for (var c = 0; c < all[r].length; c++) {
        final value = all[r][c];
        final cell = sheet.cell(
          xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        );
        cell.value = value == null || value == ''
            ? null
            : value is int
            ? xls.IntCellValue(value)
            : value is double
            ? xls.DoubleCellValue(value)
            : xls.TextCellValue('$value');
        cell.cellStyle = xls.CellStyle(
          fontFamily: 'Arial',
          fontSize: 10,
          bold: r == 0 || r == headerRow,
          fontColorHex: xls.ExcelColor.fromHexString(
            r == headerRow ? '#FFFFFF' : '#14234B',
          ),
          backgroundColorHex: xls.ExcelColor.fromHexString(
            r == headerRow ? '#080078' : '#FFFFFF',
          ),
          textWrapping: xls.TextWrapping.WrapText,
          horizontalAlign: value is num
              ? xls.HorizontalAlign.Right
              : xls.HorizontalAlign.Left,
          numberFormat: value is String
              ? xls.NumFormat.standard_49
              : xls.CustomNumericNumFormat(
                  formatCode: r > headerRow && moneyColumns.contains(c)
                      ? '#,##0.00'
                      : '#,##0',
                ),
        );
      }
      final lines = all[r].asMap().entries.fold<int>(1, (maxLines, entry) {
        final width = entry.key < 2
            ? 34
            : moneyColumns.contains(entry.key)
            ? 22
            : 17;
        final count = '${entry.value ?? ''}'
            .split('\n')
            .fold<int>(
              0,
              (sum, part) =>
                  sum + (part.length / (width - 3)).ceil().clamp(1, 1000),
            );
        return count > maxLines ? count : maxLines;
      });
      sheet.setRowHeight(
        r,
        (lines * 14 + 8).clamp(r <= headerRow ? 36 : 44, 409).toDouble(),
      );
    }
    for (var c = 0; c < headers.length; c++) {
      sheet.setColumnWidth(
        c,
        c < 2
            ? 34
            : moneyColumns.contains(c)
            ? 22
            : 17,
      );
    }
    return Uint8List.fromList(book.encode()!);
  }
  final document = pw.Document();
  report.validatePdfGroups();
  if (headers.isEmpty || rows.any((row) => row.length != headers.length)) {
    throw const FormatException('Statement columns and values do not match.');
  }
  final pageFormat = paper ?? PdfPageFormat.a4.landscape;
  final receipt = pageFormat.width <= 100 * PdfPageFormat.mm;
  final baseMargin = receipt ? 3 * PdfPageFormat.mm : 24.0;
  final rawMargins = [
    pageFormat.marginLeft,
    pageFormat.marginTop,
    pageFormat.marginRight,
    pageFormat.marginBottom,
  ];
  final margins = rawMargins
      .map((m) => (m > baseMargin ? m : baseMargin) + (paper == null ? 0 : 1))
      .toList();
  if (!pageFormat.width.isFinite ||
      !pageFormat.height.isFinite ||
      pageFormat.width < 48 * PdfPageFormat.mm ||
      pageFormat.width > 330 * PdfPageFormat.mm ||
      pageFormat.height < 100 * PdfPageFormat.mm ||
      pageFormat.height > 1000 * PdfPageFormat.mm ||
      rawMargins.any((m) => !m.isFinite || m < 0) ||
      pageFormat.width - margins[0] - margins[2] < 40 * PdfPageFormat.mm ||
      pageFormat.height - margins[1] - margins[3] < 70 * PdfPageFormat.mm) {
    throw const FormatException(
      'Unsupported statement paper or printable area.',
    );
  }
  String value(Object? cell, int column) => cell == null
      ? report.nullLabel
      : moneyColumns.contains(column) && cell is num
      ? cell.toStringAsFixed(2)
      : '$cell';
  final font = pw.Font.ttf(fontData!);
  final embedded = font.getFont(pw.Context(document: document.document));
  final text = [
    report.title,
    report.disclosure,
    ...headers,
    ...metadata.expand((r) => r),
    ...rows.expand((r) => r),
    ...report.summary.expand((r) => r),
    ...report.pdfGroups.map((group) => group.title),
  ].join(' ');
  if (text.runes.any((r) => r > 32 && !embedded.isRuneSupported(r))) {
    throw const FormatException(
      'Some characters cannot be shown in PDF. Choose Excel or CSV to keep all details.',
    );
  }
  if (report.summary.isNotEmpty) {
    document.addPage(
      pw.MultiPage(
        pageFormat: paper ?? PdfPageFormat.a4,
        maxPages: 100,
        margin: pw.EdgeInsets.fromLTRB(
          margins[0],
          margins[1],
          margins[2],
          margins[3],
        ),
        theme: pw.ThemeData.withFont(base: font, bold: font),
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            '${report.title} Statement — Summary',
            style: const pw.TextStyle(
              fontSize: 16,
              color: PdfColor.fromInt(0xff080078),
            ),
          ),
        ),
        footer: (c) => pw.Text(
          'Page ${c.pageNumber} · ${report.metadata.where((r) => r.first == 'Reference').map((r) => r.last).join()} · ${report.disclosure}',
          style: const pw.TextStyle(fontSize: 8),
        ),
        build: (_) => [
          pw.TableHelper.fromTextArray(
            data: report.summary,
            headerCount: 0,
            border: null,
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(3),
            },
            cellPadding: const pw.EdgeInsets.all(7),
            cellStyle: const pw.TextStyle(fontSize: 10),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xfff5f6fb),
            ),
          ),
        ],
      ),
    );
  }
  // Repeat identifying fields across column sections instead of shrinking an
  // entire ledger to illegibility when the printer selects portrait media.
  final capacity = ((pageFormat.width - margins[0] - margins[2]) / 80)
      .floor()
      .clamp(4, 30);
  final groups = report.pdfGroups.isEmpty || receipt
      ? [StoreReportPdfGroup('', List<int>.generate(headers.length, (i) => i),
          List<int>.generate(rows.length, (i) => i))]
      : report.pdfGroups.where((group) => group.rowIndexes.isNotEmpty).toList();
  if (groups.isEmpty) {
    groups.add(StoreReportPdfGroup('Invoices',
        List<int>.generate(headers.length, (i) => i), const []));
  }
  for (final group in groups) {
  final groupRows = [for (final i in group.rowIndexes) rows[i]];
  final allColumns = group.columns;
  final sections = <List<int>>[];
  if (receipt || allColumns.length <= capacity) {
    sections.add(allColumns);
  } else {
    for (var offset = 3; offset < allColumns.length; offset += capacity - 3) {
      sections.add([...allColumns.take(3), ...allColumns.skip(offset).take(capacity - 3)]);
    }
  }
  for (var start = 0; start < (groupRows.isEmpty ? 1 : groupRows.length); start += 50) {
    final batch = groupRows.skip(start).take(50);
    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        maxPages: 100,
        margin: pw.EdgeInsets.fromLTRB(
          margins[0],
          margins[1],
          margins[2],
          margins[3],
        ),
        theme: pw.ThemeData.withFont(base: font, bold: font),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (final row in metadata)
              pw.Text(row.join('  '), style: const pw.TextStyle(fontSize: 9)),
            if (group.title.isNotEmpty)
              pw.Text(group.title, style: pw.TextStyle(fontSize: 11,
                  fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (c) => pw.Text(
          'Page ${c.pageNumber} · ${report.disclosure}',
          style: const pw.TextStyle(fontSize: 8),
        ),
        build: (_) => [
          if (receipt)
            for (final row in batch)
              pw.Inseparable(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < headers.length; i++)
                        pw.Text(
                          '${headers[i]}: ${value(i < row.length ? row[i] : null, i)}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                    ],
                  ),
                ),
              )
          else
            for (final columns in sections) ...[
              pw.NewPage(freeSpace: 70),
              if (sections.length > 1)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(
                    'Fields ${sections.indexOf(columns) + 1} of ${sections.length}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              pw.TableHelper.fromTextArray(
                headers: [for (final i in columns) headers[i]],
                data: [
                  for (final row in batch)
                    [
                      for (final i in columns)
                        row[i] == null
                            ? report.nullLabel
                            : report.dateColumns.contains(i) &&
                                  row[i] is String &&
                                  DateTime.tryParse(row[i] as String) != null
                            ? (row[i] as String)
                                  .replaceFirst('T', '\n')
                                  .split('.')
                                  .first
                                  .replaceAll('Z', '')
                            : moneyColumns.contains(i) && row[i] is num
                            ? (row[i] as num).toStringAsFixed(2)
                            : '${row[i]}',
                    ],
                ],
                border: null,
                cellPadding: group.title.isEmpty
                    ? const pw.EdgeInsets.all(5)
                    : const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xff080078),
                ),
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                columnWidths: {
                  // Every column must participate in allocation. Intrinsic
                  // defaults can consume the page and collapse Date/Particulars.
                  for (var i = 0; i < columns.length; i++)
                    i: pw.FlexColumnWidth(
                      columns[i] == 1
                          ? 2.5
                          : columns[i] == 0
                          ? 1.6
                          : moneyColumns.contains(columns[i])
                          ? 1.5
                          : 1.4,
                    ),
                },
                cellAlignments: {
                  for (var i = 0; i < columns.length; i++)
                    if (moneyColumns.contains(columns[i]) ||
                        report.rightAlignedColumns.contains(columns[i]))
                      i: pw.Alignment.centerRight,
                },
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xfff5f6fb),
                ),
              ),
              // Space separates column sections, not terminal content: a final
              // spacer can spill onto a header/footer-only continuation page.
              if (columns != sections.last)
                pw.SizedBox(height: 12),
            ],
          if (groupRows.isEmpty) pw.Text('No records for this period.'),
        ],
      ),
    );
  }
  }
  return saveCommercePrintPages(document, pages);
}

/// Immutable current balances, not an accounting ledger or physical stock count.
/// The caller supplies the whole selected dataset, never only visible rows.
String storeStockSalePrices(WorkspaceCatalogueItem item, {String Function(int)? formatMoney}) {
  final trade = item.wholesaleOffer;
  final money = formatMoney ?? workspacePriceInputFromMinor;
  return [
    if (item.retailEnabled) 'Retail ₹${money(item.sellingPriceMinor)}',
    if (trade?.enabled == true)
      trade!.valid && trade.saleType != null
        ? '${trade.saleType!.name == 'bulk' ? 'Bulk' : 'Wholesale'} ₹${money(trade.priceAtMinor(trade.minimumPacks))}'
        : 'Trade price unconfirmed',
    if (!item.retailEnabled && trade?.enabled != true) 'Not offered',
  ].join('\n');
}

String? storeStockTradeQuantity(WorkspaceCatalogueItem item) {
  final trade = item.wholesaleOffer;
  return trade?.enabled == true && trade!.valid && trade.saleType != null
    ? 'at min ${trade.minimumPacks} packs' : null;
}

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
             p.retailEnabled ? _priceCell(p.sellingPriceMinor) : null,
             _priceCell(p.purchasePriceMinor),
             _priceCell(p.mrpMinor),
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
             p.retailEnabled ? 'Enabled' : 'Not offered',
             p.wholesaleOffer?.enabled != true ? 'Not offered' : p.wholesaleOffer!.saleType?.name ?? 'Unconfirmed',
             p.wholesaleOffer?.enabled == true && p.wholesaleOffer!.valid
                 ? _priceCell(p.wholesaleOffer!.priceAtMinor(p.wholesaleOffer!.minimumPacks)) : null,
             p.wholesaleOffer?.enabled == true && p.wholesaleOffer!.valid ? p.wholesaleOffer!.minimumPacks : null,
             p.wholesaleOffer?.enabled == true && p.wholesaleOffer!.valid ? p.wholesaleOffer!.incrementPacks : null,
             p.wholesaleOffer?.enabled == true && p.wholesaleOffer!.valid
                 ? p.wholesaleOffer!.tiers.map((tier) => '${tier.minimumPacks}:${workspacePriceInputFromMinor(tier.packPriceMinor)}').join('; ') : '',
             [storeStockSalePrices(p), ?storeStockTradeQuantity(p)].join('\n'),
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
  // Keep legacy spreadsheet numeric cells literal. Fractional money is exact
  // decimal text in both files and print, never a double or unlabelled paise.
  static Object? _priceCell(int? minor) => minor == null ? null
      : minor % 100 == 0 ? minor ~/ 100 : workspacePriceInputFromMinor(minor);
  static const headers = [
    'Item',
    'SKU',
    'Barcode',
    'Brand',
    'Variant',
    'Pack',
    'Category',
    'Qty on hand',
    'Stock tracking',
    'Availability',
    'Retail price (INR)',
    'Purchase price (INR)',
    'Pack MRP (INR)',
    'Low-stock alert',
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
    'Retail selling',
    'Trade type',
    'Trade price at minimum quantity (INR)',
    'Trade minimum packs',
    'Trade quantity step',
    'Trade quantity prices (packs:INR)',
    'Sale prices',
  ];
  String get timestamp => generatedAt.toUtc().toIso8601String();
  String get displayTimestamp {
    final value = generatedAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final offset = value.timeZoneOffset.inMinutes;
    final zone = 'UTC${offset < 0 ? '-' : '+'}'
        '${two(offset.abs() ~/ 60)}:${two(offset.abs() % 60)}';
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)} $zone (phone time)';
  }

  // Presentation only. Machine exports retain the original category identity.
  static String displayCategory(Object? value) {
    final id = value?.toString().trim() ?? '';
    if (id.isEmpty || id == 'uncategorised') return 'Uncategorised';
    if (id == 'other') return 'Other products';
    return id.split(RegExp('[-_]')).where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  List<List<Object?>> get presentationRows => [
    for (final row in rows)
      [for (var c = 0; c < row.length; c++) c == 6 ? displayCategory(row[c]) : row[c]],
  ];
  Future<Uint8List> forPrint(
    PdfPageFormat paper,
    List<int>? pages,
  ) => StoreTabularReport(
    title: 'Current stock snapshot',
    disclosure:
        'Current recorded balances; not a historical or audited statement. Full product metadata: Excel or CSV.',
    metadata: [
      ...exportRows.take(2),
      ['Generated at', displayTimestamp],
      ...exportRows.skip(3).take(2),
    ],
    // The existing stock PDF includes position and reference fields, not
    // the full compliance export. Keep that same scope for print media.
    headers: headers.take(15).toList(),
    rows: [for (final row in presentationRows) row.take(15).toList()],
    moneyColumns: const {10, 11, 12},
    rightAlignedColumns: const {7, 13},
  ).forPrint(paper, pages);
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
  final showMrp = snapshot.rows.any((row) => row[12] != null);
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
                '${snapshot.displayTimestamp} | ${snapshot.scope} | ${snapshot.rows.length} products',
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
              'Item / SKU / pack',
              'Qty on hand',
              'Sale prices INR',
              'Purchase INR',
              if (showMrp) 'Pack MRP INR',
              'Low-stock alert',
              'Availability',
            ],
            batch
                .map(
                  (r) => [
                    '${r[0]}\n${r[1]} | ${r[5]}',
                    r[7]?.toString() ?? 'Not tracked',
                    r[38].toString().replaceAll('₹', ''),
                    '${r[11]}',
                    if (showMrp) r[12]?.toString() ?? '—',
                    r[13]?.toString() ?? 'N/A',
                    '${r[9]}',
                  ],
                )
                .toList(),
            {
              0: const pw.FlexColumnWidth(3),
              for (var c = 1; c < (showMrp ? 7 : 6); c++) c: pw.FlexColumnWidth(c == 2 ? 2 : 1),
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
                  StoreStockSnapshot.displayCategory(r[6]),
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
