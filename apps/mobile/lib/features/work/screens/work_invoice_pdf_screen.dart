import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../work_document_preview.dart';
import '../work_invoice_pdf.dart';

enum WorkPdfActionResult { completed, cancelled, unavailable }

abstract interface class WorkInvoicePdfActions {
  Future<WorkPdfActionResult> save(WorkInvoicePdfDocument document);
  Future<WorkPdfActionResult> share(
    WorkInvoicePdfDocument document,
    Rect origin,
  );
}

class NativeWorkInvoicePdfActions implements WorkInvoicePdfActions {
  const NativeWorkInvoicePdfActions();
  @override
  Future<WorkPdfActionResult> save(WorkInvoicePdfDocument document) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Save invoice',
      fileName: document.fileName,
      mimeType: 'application/pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: document.bytes,
    );
    return path == null
        ? WorkPdfActionResult.cancelled
        : WorkPdfActionResult.completed;
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
    this.actions = const NativeWorkInvoicePdfActions(),
    this.renderPage,
  });
  final WorkInvoicePdfRequest request;
  final WorkInvoicePdfSource source;
  final bool Function() isCurrent;
  final Listenable scopeChanges;
  final WorkInvoicePdfActions actions;
  final Future<WorkPdfPage> Function(WorkInvoicePdfDocument, int)? renderPage;
  @override
  State<WorkInvoicePdfScreen> createState() => _WorkInvoicePdfScreenState();
}

class _WorkInvoicePdfScreenState extends State<WorkInvoicePdfScreen> {
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
          ? await widget.actions.share(
              document,
              box.localToGlobal(Offset.zero) & box.size,
            )
          : await widget.actions.save(document);
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
    } catch (_) {
      if (!_valid(epoch)) return;
      setState(() {
        _notice = share
            ? 'Could not share the PDF. Please try again.'
            : 'Could not save the PDF. Please try again.';
      });
    } finally {
      if (_valid(epoch)) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Invoice PDF')),
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
