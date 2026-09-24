import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/commerce/commerce_downloads.dart';
import '../work_document_preview.dart';
import '../work_invoice_pdf.dart';
import '../work_stock_export.dart';

enum WorkPdfActionResult { completed, cancelled, unavailable }

abstract interface class WorkInvoicePdfActions {
  Future<WorkPdfActionResult> save(WorkInvoicePdfDocument document);
  Future<WorkPdfActionResult> share(
    WorkInvoicePdfDocument document,
    Rect origin,
  );
}

class NativeWorkInvoicePdfActions implements WorkInvoicePdfActions {
  const NativeWorkInvoicePdfActions({required this.scope});
  final CommerceDownloadScope scope;
  @override
  Future<WorkPdfActionResult> save(WorkInvoicePdfDocument document) async {
    final saved = await saveCommerceDownloadFile(
      CommerceDownloadFile(
        scope: scope,
        id: document.identity,
        bytes: document.bytes,
        fileName: commerceDownloadName(
          document.fileName.replaceFirst(RegExp(r'\.pdf$'), ''),
        ),
      ),
    );
    return saved
        ? WorkPdfActionResult.completed
        : WorkPdfActionResult.cancelled;
  }

  @override
  Future<WorkPdfActionResult> share(
    WorkInvoicePdfDocument document,
    Rect origin,
  ) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(document.bytes, mimeType: 'application/pdf')],
        fileNameOverrides: [document.fileName],
        title: document.fileName,
        sharePositionOrigin: origin,
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => WorkPdfActionResult.completed,
      ShareResultStatus.dismissed => WorkPdfActionResult.cancelled,
      ShareResultStatus.unavailable => WorkPdfActionResult.unavailable,
    };
  }
}

class WorkInvoicePdfScreen extends StatefulWidget {
  const WorkInvoicePdfScreen({
    super.key,
    required this.request,
    required this.source,
    required this.isCurrent,
    required this.scopeChanges,
    this.actions,
    this.renderPage,
  });
  final WorkInvoicePdfRequest request;
  final WorkInvoicePdfSource source;
  final bool Function() isCurrent;
  final Listenable scopeChanges;
  final WorkInvoicePdfActions? actions;
  final Future<WorkPdfPage> Function(WorkInvoicePdfDocument, int)? renderPage;
  @override
  State<WorkInvoicePdfScreen> createState() => _WorkInvoicePdfScreenState();
}

class _WorkInvoicePdfScreenState extends State<WorkInvoicePdfScreen> {
  WorkInvoicePdfActions get _actions =>
      widget.actions ??
      NativeWorkInvoicePdfActions(
        scope: CommerceDownloadScope(
          widget.request.accountId,
          store: widget.request.storeId,
        ),
      );
  WorkPdfPreview _renderer = WorkPdfPreview();
  WorkInvoicePdfDocument? _document;
  WorkPdfPage? _page;
  String? _error, _notice;
  bool _loading = false, _rendering = false, _acting = false, _stale = false;
  int _epoch = 0;
  @override
  void initState() {
    super.initState();
    widget.scopeChanges.addListener(_checkScope);
    unawaited(_load());
  }

  @override
  void dispose() {
    _epoch++;
    widget.scopeChanges.removeListener(_checkScope);
    _renderer.dispose();
    super.dispose();
  }

  bool _valid(int epoch) =>
      mounted && epoch == _epoch && !_stale && widget.isCurrent();
  void _checkScope() {
    if (widget.isCurrent() || !mounted || _stale) return;
    _epoch++;
    _renderer.dispose();
    setState(() {
      _stale = true;
      _document = null;
      _page = null;
      _loading = false;
      _rendering = false;
      _acting = false;
      _error =
          'This invoice is no longer open in the current Store. Go back to reopen it.';
    });
  }

  void _cancel() {
    _epoch++;
    _renderer.dispose();
    _renderer = WorkPdfPreview();
    setState(() {
      _loading = false;
      _rendering = false;
      _error = 'Preview cancelled.';
    });
  }

  Future<void> _load() async {
    if (!widget.isCurrent()) {
      _checkScope();
      return;
    }
    final epoch = ++_epoch;
    setState(() {
      _loading = true;
      _document = null;
      _page = null;
      _error = null;
      _notice = null;
    });
    try {
      final document = await widget.source
          .load(widget.request)
          .timeout(const Duration(seconds: 30));
      if (!_valid(epoch)) return;
      if (document.identity != widget.request.identity ||
          document.fileName != widget.request.invoice.pdfFileName) {
        throw const WorkInvoicePdfException(
          'The returned file does not match this invoice.',
        );
      }
      setState(() {
        _document = document;
        _loading = false;
      });
      await _render(0);
    } catch (error) {
      if (!_valid(epoch)) return;
      setState(() {
        _loading = false;
        _error = error is WorkInvoicePdfException
            ? error.message
            : 'The PDF could not be prepared. Please try again.';
      });
    }
  }

  Future<void> _render(int index) async {
    final document = _document;
    if (document == null || !widget.isCurrent()) return;
    final epoch = _epoch;
    setState(() {
      _rendering = true;
      _error = null;
    });
    try {
      final page =
          await (widget.renderPage?.call(document, index) ??
                  _renderer.render(document.bytes, page: index))
              .timeout(const Duration(seconds: 25));
      if (!_valid(epoch)) return;
      setState(() {
        _page = page;
        _rendering = false;
      });
    } catch (_) {
      if (!_valid(epoch)) return;
      setState(() {
        _rendering = false;
        _error = 'Preview could not open. Retry, or save the PDF to view it.';
      });
    }
  }

  Future<void> _fileAction(bool share) async {
    final document = _document;
    if (document == null || _acting || !widget.isCurrent()) return;
    final epoch = _epoch;
    setState(() {
      _acting = true;
      _notice = null;
    });
    try {
      final box = context.findRenderObject() as RenderBox;
      final result = share
          ? await _actions.share(
              document,
              box.localToGlobal(Offset.zero) & box.size,
            )
          : await _actions.save(document);
      if (!_valid(epoch)) return;
      setState(() {
        _notice = switch (result) {
          WorkPdfActionResult.completed =>
            share ? 'File handed to the selected app.' : 'Invoice saved.',
          WorkPdfActionResult.cancelled =>
            share ? 'Sharing cancelled.' : 'Save cancelled.',
          WorkPdfActionResult.unavailable =>
            'The action could not be confirmed. You can try again.',
        };
      });
    } catch (error) {
      if (!_valid(epoch)) return;
      setState(() {
        _notice = !share && error is FormatException
            ? error.message
            : share
            ? 'Could not share the PDF. Please try again.'
            : 'Could not save the PDF. Please try again.';
      });
    } finally {
      if (_valid(epoch)) setState(() => _acting = false);
    }
  }

  Future<void> _print(StorePrintPaper paper) async {
    final document = _document;
    if (document == null || _acting || _stale || !widget.isCurrent()) return;
    final source = widget.source;
    if (source is! WorkInvoicePrintSource) {
      setState(
        () => _notice =
            'Printing is unavailable for this document source. You can save the PDF.',
      );
      return;
    }
    final epoch = _epoch;
    setState(() {
      _acting = true;
      _notice = null;
    });
    try {
      final state = await StoreDocumentPrinter.print(
        name: document.fileName,
        initialFormat: paper.initialFormat,
        isCurrent: () => _valid(epoch),
        scopeChanges: widget.scopeChanges,
        render: (paper, pages) async {
          final output = await (source as WorkInvoicePrintSource).forPrint(
            widget.request,
            paper,
            pages,
          );
          if (!_valid(epoch) ||
              output.identity != document.identity ||
              output.reviewOnly != document.reviewOnly) {
            throw const WorkInvoicePdfException(
              'The document changed. Reopen it to print.',
            );
          }
          return output.bytes;
        },
      );
      if (!_valid(epoch)) return;
      setState(
        () => _notice = switch (state) {
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
    } finally {
      if (_valid(epoch)) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Invoice PDF'),
      actions: [
        StorePrintButton(
          key: const Key('invoice-pdf-print'),
          tooltip: 'Print invoice',
          onSelected: _document == null || _acting || _rendering || _stale
              ? null
              : _print,
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.request.invoice.pdfFileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (_document?.reviewOnly == true)
                const Text(
                  'Preview copy - not issued',
                  key: Key('invoice-pdf-review-label'),
                ),
              if (_loading || _rendering) ...[
                const LinearProgressIndicator(key: Key('invoice-pdf-loading')),
                TextButton(onPressed: _cancel, child: const Text('Cancel')),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(_error!, key: const Key('invoice-pdf-error')),
                      if (!_stale)
                        TextButton(
                          key: const Key('invoice-pdf-retry'),
                          onPressed: _loading || _rendering
                              ? null
                              : () => _document == null
                                    ? _load()
                                    : _render(_page?.index ?? 0),
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
              SizedBox(
                height: (constraints.maxHeight - 300).clamp(220.0, 900.0),
                child: _page == null
                    ? const SizedBox.shrink()
                    : InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Center(
                          child: Image.memory(
                            _page!.bytes,
                            key: const Key('invoice-pdf-page'),
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                const Text('This page could not be displayed.'),
                          ),
                        ),
                      ),
              ),
              if (_page != null && _page!.pageCount > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Previous page',
                      onPressed: _acting || _rendering || _page!.index == 0
                          ? null
                          : () => _render(_page!.index - 1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('${_page!.index + 1} / ${_page!.pageCount}'),
                    IconButton(
                      tooltip: 'Next page',
                      onPressed:
                          _acting ||
                              _rendering ||
                              _page!.index + 1 == _page!.pageCount
                          ? null
                          : () => _render(_page!.index + 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _notice!,
                    key: const Key('invoice-pdf-action-status'),
                  ),
                ),
              if (_document != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('invoice-pdf-save'),
                        onPressed: _acting || _rendering
                            ? null
                            : () => _fileAction(false),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Save PDF'),
                      ),
                      FilledButton.icon(
                        key: const Key('invoice-pdf-share'),
                        onPressed: _acting || _rendering
                            ? null
                            : () => _fileAction(true),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share PDF'),
                      ),
                      if (_acting)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
