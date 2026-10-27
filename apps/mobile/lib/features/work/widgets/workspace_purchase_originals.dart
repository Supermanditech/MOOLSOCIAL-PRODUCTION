import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../assistant/mool_assistant.dart';
import '../../../ui_v2/assistant/mool_assistant_v2.dart' show MoolAssistantRouteBoundNativeAdapter;
import '../work_document_preview.dart';
import '../work_stock_export.dart' show storeTradeDocumentLabel;
import '../work_order_identity_gateway.dart';
import '../work_catalogue_gateway.dart';
import '../work_models.dart' show WorkspacePurchasedUnitRow, WorkspacePurchasedUnitDraft, WorkspacePurchasedUnitDraftKey, WorkspacePurchasedUnitPublishCommand,
  WorkspacePurchasedUnitMismatchDraft, WorkspacePurchasedUnitMismatchCommand, WorkspaceIssueRecord;
import '../work_services.dart' show WorkPurchasedUnitDraftStore, SecureWorkPurchasedUnitDraftStore;

/// Shared quotation surface, deliberately separate from purchased orders.
class WorkspaceBulkQuotes extends StatefulWidget {
  const WorkspaceBulkQuotes({super.key, required this.access, this.storeId, this.onClose,
    this.request, this.requestLines = const [], this.inputCurrent, this.onUseForCart,this.readOnlyQuote});
  final WorkspaceBulkQuoteAccess access;
  final WorkspaceBulkQuote? readOnlyQuote;
  final String? storeId;
  final VoidCallback? onClose;
  final WorkspaceBulkQuoteIntent? request;
  final List<({String name, String pack, String? variant, int quantity})> requestLines;
  final bool Function()? inputCurrent;
  final Future<bool> Function(WorkspaceBulkQuote)? onUseForCart;
  @override State<WorkspaceBulkQuotes> createState() => _WorkspaceBulkQuotesState();
}

class _WorkspaceBulkQuotesState extends State<WorkspaceBulkQuotes> with WidgetsBindingObserver {
  final _rows = <Map<String, dynamic>>[];
  final _pending = <WorkspaceBulkQuoteIntent>[];
  String? _cursor, _store, _quoteId, _error;
  bool _loading = false, _acting = false, _sending = false, _termsAccepted = false;
  int _generation = 0;
  Object _detailVisit = Object();
  Timer? _expiry;
  WorkspaceBulkQuoteAccess get access => widget.access;
  bool _current(int generation) => mounted && generation == _generation && access.active && _readOnlyCurrent;
  WorkspaceBulkQuoteController? get controller => _store == null || !access.active ? null : access.forStore(_store!);
  bool get _readOnlyCurrent {
    final quote=widget.readOnlyQuote;if(quote==null)return true;
    if(!access.active || widget.inputCurrent?.call()==false)return false;
    final owner=controller;
    return owner!=null && owner.active && owner.initialized && !owner.busy && owner.pending.isEmpty && identical(owner.head(quote.quoteId),quote);
  }
  VoidCallback? get _closeReadOnly {
    if(_acting || !_readOnlyCurrent)return null;
    return (){if(!mounted || !_readOnlyCurrent)return;widget.onClose?.call();};
  }
  @override void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this); _selectRequest();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) unawaited(_load()); });
  }
  void _selectRequest() { _detailVisit = Object(); _store = widget.readOnlyQuote?.storeId ?? widget.request?.storeId; _quoteId = widget.readOnlyQuote?.quoteId ?? widget.request?.quoteId; }
  @override void didUpdateWidget(covariant WorkspaceBulkQuotes old) {
    super.didUpdateWidget(old);
    if (!identical(old.access, access) || old.storeId != widget.storeId || old.request?.fingerprint != widget.request?.fingerprint || !identical(old.readOnlyQuote,widget.readOnlyQuote)) {
      _generation++; _expiry?.cancel(); _rows.clear(); _pending.clear(); _cursor = null; _termsAccepted = false; _selectRequest();
      _loading = false; _acting = false; _sending = false; _error = null;
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) unawaited(_load()); });
    }
  }
  @override void dispose() { _generation++; _expiry?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && access.active && widget.readOnlyQuote==null) {
      setState(() {}); if (_quoteId != null) unawaited(_refresh());
    }
  }
  void _armExpiry() {
    _expiry?.cancel(); final quote = controller?.head(_quoteId ?? ''), generation = _generation;
    if (quote == null || !{'offered', 'accepted'}.contains(quote.state)) return;
    final delay = quote.validUntil!.difference(access.gateway.gateway.now().toUtc());
    if (delay.isNegative) return;
    _expiry = Timer(delay, () { if (_current(generation)) setState(() { _termsAccepted = false; }); });
  }
  Future<void> _load({bool more = false}) async {
    if (_loading || !access.active || widget.inputCurrent?.call()==false && widget.readOnlyQuote!=null) return;
    if(widget.readOnlyQuote!=null){_armExpiry();return;}
    final generation = _generation, originalAccess = access;
    setState(() { _loading = true; _error = null; });
    try {
      final stores = widget.storeId != null ? [widget.storeId!] : await originalAccess.pendingStores();
      final local = <WorkspaceBulkQuoteIntent>[];
      for (final store in stores) {
        if (!_current(generation) || !identical(originalAccess, access)) return;
        final owner = originalAccess.forStore(store);
        if (!await owner.restore()) throw const FormatException();
        local.addAll(owner.pending);
      }
      if (!_current(generation)) return;
      setState(() { _pending..clear()..addAll(local); });
      if (widget.request != null) {
        final owner = originalAccess.forStore(widget.request!.storeId);
        if (!await owner.restore()) throw const FormatException();
        if (owner.pending.any((p) => p.quoteId == widget.request!.quoteId)) await owner.recover();
        if (!_current(generation)) return;
        setState(() { _pending..clear()..addAll(owner.pending); }); _armExpiry(); return;
      }
      final page = await originalAccess.gateway.list(account: originalAccess.account,
        storeId: originalAccess.role == 'supplier' ? widget.storeId : null, cursor: more ? _cursor : null,
        current: () => _current(generation) && identical(access, originalAccess));
      if (!_current(generation)) return;
      setState(() {
        if (!more) _rows.clear();
        for (final row in page.summaries) { _rows.removeWhere((old) => old['quoteId'] == row['quoteId']); _rows.add(row); }
        _pending..clear()..addAll(local); _cursor = page.nextCursor;
      });
    } catch (_) { if (_current(generation)) setState(() { _error = 'Quotes could not be checked. Your saved requests are kept.'; }); }
    finally { if (_current(generation)) setState(() { _loading = false; }); }
  }
  Future<void> _refresh() async {
    if(widget.readOnlyQuote!=null)return;
    final owner = controller, id = _quoteId, generation = _generation;
    if (owner == null || id == null || owner.busy || _acting) return;
    final previous = owner.head(id)?.revision;
    await owner.recover();
    if (!_current(generation) || _quoteId != id) return;
    await owner.refresh(id);
    if (!_current(generation) || _quoteId != id) return;
    setState(() { if (previous != owner.head(id)?.revision) _termsAccepted = false; }); _armExpiry();
  }
  Future<void> _open(String store, String id) async {
    if(widget.readOnlyQuote!=null)return;
    setState(() { _detailVisit = Object(); _store = store; _quoteId = id; _termsAccepted = false; _error = null; }); await _refresh();
  }
  Future<bool> _confirm(String title, String body) async => await showDialog<bool>(context: context,
    builder: (dialog) => AlertDialog(title: Text(title), content: Text(body), scrollable: true,
      actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Not now')),
        FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Confirm'))])) == true;
  Future<void> _useForCart(WorkspaceBulkQuote quote, Object visit, Future<bool> Function(WorkspaceBulkQuote) callback) async {
    if(widget.readOnlyQuote!=null)return;
    final originalAccess = access, generation = _generation;
    bool current() => _current(generation) && identical(_detailVisit, visit) && identical(access, originalAccess) &&
      identical(widget.onUseForCart, callback) && _quoteId == quote.quoteId && _store == quote.storeId &&
      jsonEncode(controller?.head(quote.quoteId)?.toJson()) == jsonEncode(quote.toJson()) &&
      quote.accepted && quote.validUntil?.isAfter(access.gateway.gateway.now().toUtc()) == true;
    if (_acting || !current()) return;
    setState(() { _acting = true; _error = null; });
    try {
      if (!await _confirm('Use these prices for this Cart?',
        'The exact products and quantities must match. Final charges and payment terms are confirmed at Checkout. No order or payment is made now.') || !current()) { return; }
      setState(() { _sending = true; });
      final saved = await callback(quote);
      if (!current()) return;
      if (saved) { widget.onClose?.call(); }
      else { setState(() { _error = 'These prices could not be selected. Check the Cart quantities and refresh the quote.'; }); }
    } catch (_) {
      if (current()) setState(() { _error = 'These prices could not be saved for your Cart. Please try again.'; });
    } finally { if (_current(generation)) setState(() { _acting = false; _sending = false; }); }
  }
  WorkspaceBulkQuoteIntent _command(WorkspaceBulkQuote quote, String kind, {Map<String, dynamic> fields = const {}}) {
    final key = '$kind-${List.generate(16, (_) => math.Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    return WorkspaceBulkQuoteIntent.decode({'schemaVersion': 1, 'account': access.account, 'realm': access.realm, 'kind': kind,
      'body': {'schemaVersion': 1, 'quoteId': quote.quoteId, 'operationId': key, 'expectedRevision': quote.revision, ...fields},
      'base': quote.toJson(), 'expected': [for (final line in quote.lines) line.identity]},
      account: access.account, realm: access.realm, now: access.gateway.gateway.now());
  }
  Future<void> _act(String kind, {required Object visit, WorkspaceBulkQuoteIntent? original, WorkspaceBulkQuote? quote}) async {
    if(widget.readOnlyQuote!=null)return;
    final generation = _generation, owner = controller, originalAccess = access;
    if (_acting || owner == null || owner.busy || !_current(generation)) return;
    bool displayedCurrent() => _current(generation) && identical(access, originalAccess) && identical(_detailVisit, visit) &&
      identical(owner, controller) && (quote == null || _quoteId == quote.quoteId && _store == quote.storeId &&
        jsonEncode(owner.head(quote.quoteId)?.toJson()) == jsonEncode(quote.toJson())) &&
      (original == null || _quoteId == original.quoteId && _store == original.storeId && original.account == access.account && original.realm == access.realm) &&
      (kind != 'request' || widget.inputCurrent?.call() != false) &&
      (kind != 'accept' || quote?.offerCurrent(access.gateway.gateway.now()) == true &&
        (_termsAccepted || !quote!.lines.any((line) => line.supplierPolicy['requiresAcceptance'] == true)));
    if (!displayedCurrent()) return;
    setState(() { _acting = true; _error = null; });
    try {
      Map<String, dynamic>? fields;
      if (kind == 'offer') {
        fields = await showModalBottomSheet<Map<String, dynamic>>(context: context, isScrollControlled: true, useSafeArea: true,
          showDragHandle: true, builder: (_) => _BulkOfferEditor(quote: quote!, now: access.gateway.gateway.now));
        if (fields == null) return;
      } else if (!await _confirm(kind == 'accept' ? 'Agree to these prices?' : kind == 'withdraw' ? 'Close this request?' :
        kind == 'retry' ? 'Retry the same request?' : 'Request supplier prices?',
        kind == 'accept' ? 'This agrees to the supplier’s product prices and terms. It does not place an order or make a payment. Final charges must be confirmed before ordering.' :
        kind == 'withdraw' ? 'The current request will be closed if it has not already been accepted. No placed order is cancelled.' :
        kind == 'retry' ? 'The exact saved request will be checked again. No duplicate request will be created.' :
        'Send the selected Bulk products and quantities to this Store for a quotation. No payment is taken.')) {
        return;
      }
      if (!displayedCurrent()) return;
      bool inputCurrent() => displayedCurrent();
      final command = original ?? _command(quote!, kind, fields: fields ?? const {});
      setState(() { _sending = true; });
      final ok = kind == 'retry' ? await owner.retryOriginal(command, inputCurrent: inputCurrent) : await owner.submit(command, inputCurrent: inputCurrent);
      if (!_current(generation)) return;
      setState(() { _termsAccepted = false; if (!ok) _error = owner.message ?? 'This request has changed. Refresh before continuing.'; });
      _armExpiry();
    } catch (_) { if (_current(generation)) setState(() { _error = 'This request could not be confirmed. Check its status before trying again.'; }); }
    finally { if (_current(generation)) setState(() { _acting = false; _sending = false; }); }
  }
  String _date(DateTime value) {
    final l = MaterialLocalizations.of(context), local = value.toLocal();
    return '${l.formatShortDate(local)} · ${l.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }
  String _status(String state, {DateTime? until}) => switch (state) {
    'requested' => 'Awaiting supplier', 'offered' => until?.isAfter(access.gateway.gateway.now().toUtc()) == false ? 'Offer expired' : 'Ready to review',
    'accepted' => 'Prices agreed', 'withdrawn' => 'Closed', _ => 'Check status'};
  Widget _detail() {
    final owner = controller!, quote = widget.readOnlyQuote ?? owner.head(_quoteId!), request = widget.request;
    final visit = _detailVisit, useForCart = widget.onUseForCart;
    final pending = widget.readOnlyQuote==null?owner.pending.where((p) => p.quoteId == _quoteId).toList():<WorkspaceBulkQuoteIntent>[];
    final isNew = quote == null && pending.isEmpty && request?.quoteId == _quoteId;
    final original = pending.firstOrNull ?? (request?.quoteId == _quoteId ? request : null);
    final presentation = original?.presentation;
    final storeName = quote?.storeName ?? presentation?['storeName'] as String?;
    final policies = <String, Map<String, dynamic>>{};
    if (quote != null) { for (final line in quote.lines) { final p = line.supplierPolicy['policy']; if (p is Map<String, dynamic>) policies[jsonEncode([p['title'], p['body']])] = p; } }
    final mustReadTerms = quote?.lines.any((line) => line.supplierPolicy['requiresAcceptance'] == true) == true;
    final offer = quote?.toJson()['offer'];
    final totals = <String, int>{if (offer != null) for (final row in offer['prices'] as List) row['lineId'] as String: row['merchandiseMinor'] as int};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(storeName ?? 'Store name unavailable', style: Theme.of(context).textTheme.titleMedium),
      Text(quote == null ? isNew ? 'Review your Bulk request' : 'Confirmation pending' : _status(quote.state, until: quote.validUntil),
        style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (quote != null) ...[
        for (final line in quote.lines) Padding(padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(line.name),
            Text([if (line.variant != null) line.variant!, '${line.quantity} × ${line.packLabel}'].join(' · ')),
            if (totals.containsKey(line.lineId)) _BulkMoney(amount: totals[line.lineId]!),
          ])),
        if (quote.merchandiseMinor != null) _BulkMoney(key: const ValueKey('bulk-quote-product-prices'), label: 'Product prices', amount: quote.merchandiseMinor!),
        if (quote.validUntil != null) Text('Offer valid until ${_date(quote.validUntil!)}'),
        for (final policy in policies.values) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('${policy['title']}\n${policy['body']}')),
        if (quote.state == 'accepted') const Padding(padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Prices agreed. This is not a placed order. Final tax, delivery charges and permitted payment terms must be confirmed before ordering.')),
        if (quote.accepted && quote.validUntil?.isAfter(access.gateway.gateway.now().toUtc()) != true && (widget.onUseForCart != null || widget.readOnlyQuote!=null))
          const Text('This saved agreement has expired. Remove it from Cart if selected, then review the current listed prices.'),
      ] else if (presentation != null) ...[
        for (final row in presentation['lines'] as List) ListTile(contentPadding: EdgeInsets.zero,
          title: Text(row['name'] as String), subtitle: Text([if (row['variant'] != null) row['variant'] as String,
            '${(original!.toJson()['expected'] as List).firstWhere((e) => e['lineId'] == row['lineId'])['quantity']} × ${row['packLabel']}'].join(' · '))),
        Text(isNew ? 'The supplier will quote product prices. Taxes, delivery charges and payment terms are confirmed separately.' :
          'These are the products in your saved request. Confirmation is still pending.'),
      ] else if (isNew) ...[
        for (final line in widget.requestLines) ListTile(contentPadding: EdgeInsets.zero, title: Text(line.name),
          subtitle: Text([if (line.variant?.isNotEmpty == true) line.variant!, '${line.quantity} × ${line.pack}'].join(' · '))),
        const Text('The supplier will quote product prices. Taxes, delivery charges and payment terms are confirmed separately.'),
      ] else const Text('Your saved request is awaiting confirmation. Check its status before making changes.'),
      if (widget.readOnlyQuote==null && mustReadTerms && quote?.offerCurrent(access.gateway.gateway.now()) == true && access.role == 'buyer' && pending.isEmpty)
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: _termsAccepted, onChanged: _acting ? null : (v) => setState(() { _termsAccepted = v == true; }),
          title: const Text('I have read the supplier terms shown above.')),
      const SizedBox(height: 8),
      if(widget.readOnlyQuote==null)Wrap(spacing: 8, runSpacing: 8, children: [
        if (quote?.accepted == true && access.role == 'buyer' && useForCart != null)
          FilledButton(onPressed: _acting || quote!.validUntil?.isAfter(access.gateway.gateway.now().toUtc()) != true
            ? null : () => _useForCart(quote, visit, useForCart), child: const Text('Use for this Cart')),
        if (isNew) FilledButton(onPressed: _acting || owner.busy || owner.pending.isNotEmpty ? null : () => _act('request', visit: visit, original: request), child: const Text('Request prices')),
        if (isNew && owner.pending.isNotEmpty) TextButton(onPressed: _acting ? null : () => _open(owner.pending.first.storeId, owner.pending.first.quoteId), child: const Text('View earlier unconfirmed request')),
        if (quote != null && pending.isEmpty && {'requested', 'offered'}.contains(quote.state) && access.role == 'supplier')
          FilledButton(onPressed: _acting || owner.busy ? null : () => _act('offer', visit: visit, quote: quote), child: Text(quote.state == 'offered' ? 'Update quote' : 'Send quote')),
        if (quote != null && pending.isEmpty && quote.offerCurrent(access.gateway.gateway.now()) && access.role == 'buyer')
          FilledButton(onPressed: _acting || owner.busy || mustReadTerms && !_termsAccepted ? null : () => _act('accept', visit: visit, quote: quote), child: const Text('Accept quote')),
        if (quote != null && {'requested', 'offered'}.contains(quote.state))
          OutlinedButton(onPressed: _acting || owner.busy ? null : () => _act('withdraw', visit: visit, quote: quote), child: const Text('Close request')),
        if (!isNew) OutlinedButton(onPressed: _acting || owner.busy ? null : _refresh, child: const Text('Check status')),
        for (final original in pending) OutlinedButton(onPressed: _acting || owner.busy ? null : () => _act('retry', visit: visit, original: original),
          child: Text(original.kind == 'withdraw' ? 'Retry closing request' : 'Retry original request')),
      ]),
      if (owner.message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(owner.message!)),
    ]);
  }
  @override Widget build(BuildContext context) {
    if (!access.active) return const Center(child: Text('Sign in again to view your quotes.'));
    if(!_readOnlyCurrent)return const Center(child:Text('This saved quote is unavailable. Reopen the current selection.'));
    return Material(type: MaterialType.transparency, child: ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [if (_quoteId != null || widget.onClose != null) IconButton(tooltip: widget.readOnlyQuote!=null?'Back to purchase':widget.request != null ? 'Back to Cart' : _quoteId != null ? 'All Bulk quotes' : 'Back to orders',
        onPressed: widget.readOnlyQuote!=null?_closeReadOnly:_acting ? null : () { if (_quoteId != null && widget.request == null) { setState(() { _quoteId = null; _store = null; }); unawaited(_load()); }
          else { widget.onClose?.call(); } }, icon: const Icon(Icons.arrow_back_rounded)),
        const Expanded(child: Text('Bulk quotes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
        if(widget.readOnlyQuote==null)IconButton(tooltip: 'Refresh quotes', onPressed: _loading || _acting ? null : () => _quoteId == null ? _load() : _refresh(), icon: const Icon(Icons.refresh_rounded))]),
      const Text('Review product prices before placing a Bulk order.'), const SizedBox(height: 12),
      if (_loading || _sending) const LinearProgressIndicator(),
      if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_error!, key: const ValueKey('bulk-quote-error'))),
      if (_quoteId != null) AnimatedBuilder(animation: controller!, builder: (_, _) => _detail()) else ...[
        for (final original in _pending.where((p) => !_rows.any((row) => row['quoteId'] == p.quoteId))) ListTile(
          key: ValueKey('bulk-pending-${original.operationId}'), leading: const Icon(Icons.hourglass_top_rounded),
          title: Text(original.presentation?['storeName'] as String? ?? 'Store name unavailable'),
          subtitle: Text('Request awaiting confirmation · ${(original.toJson()['expected'] as List).length} products'),
          trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _open(original.storeId, original.quoteId)),
        for (final row in _rows) ListTile(key: ValueKey('bulk-quote-${row['quoteId']}'), leading: const Icon(Icons.request_quote_outlined),
          title: Text(row['storeName'] as String? ?? 'Store name unavailable'),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${row['productCount']} products · ${_status(row['state'] as String,
              until: row['offerValidUntil'] == null ? null : DateTime.parse(row['offerValidUntil'] as String))}\n${_date(DateTime.parse(row['updatedAt'] as String))}'),
            if (row['offerMerchandiseMinor'] != null) _BulkMoney(label: 'Product prices', amount: row['offerMerchandiseMinor'] as int),
          ]),
          trailing: const Icon(Icons.chevron_right_rounded), onTap: _loading ? null : () => _open(row['storeId'] as String, row['quoteId'] as String)),
        if (!_loading && _rows.isEmpty && _pending.isEmpty && _error == null) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No saved Bulk requests to show.')),
        if (_cursor != null) TextButton(onPressed: _loading ? null : () => _load(more: true), child: const Text('Show more')),
      ],
    ]));
  }
}

class _BulkOfferEditor extends StatefulWidget {
  const _BulkOfferEditor({required this.quote, required this.now});
  final WorkspaceBulkQuote quote;
  final DateTime Function() now;
  @override State<_BulkOfferEditor> createState() => _BulkOfferEditorState();
}
class _BulkOfferEditorState extends State<_BulkOfferEditor> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _prices;
  DateTime? _until; String? _error;
  @override void initState() {
    super.initState();
    final prior = widget.quote.toJson()['offer'];
    _prices = {for (final line in widget.quote.lines) line.lineId: TextEditingController(text: () {
      if (prior == null) return '';
      final value = (prior['prices'] as List).firstWhere((p) => p['lineId'] == line.lineId)['unitPriceMinor'] as int;
      return '${value ~/ 100}.${(value % 100).toString().padLeft(2, '0')}';
    }())};
    if (widget.quote.validUntil?.isAfter(widget.now().toUtc()) == true) _until = widget.quote.validUntil;
  }
  int? _minor(String text) {
    if (!RegExp(r'^\d{1,11}(?:\.\d{1,2})?$').hasMatch(text.trim())) return null;
    final parts = text.trim().split('.'), value = int.parse(parts[0]) * 100 + (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
    return value > 0 && value <= 1000000000000 ? value : null;
  }
  int? get _subtotal {
    var value = 0;
    for (final line in widget.quote.lines) {
      final price = _minor(_prices[line.lineId]!.text); if (price == null) return null;
      value += price * line.quantity; if (value > 1000000000000) return null;
    }
    return value;
  }
  @override void dispose() { for (final value in _prices.values) { value.dispose(); } super.dispose(); }
  Future<void> _chooseExpiry() async {
    final now = widget.now().toLocal();
    final day = await showDatePicker(context: context, firstDate: DateUtils.dateOnly(now), lastDate: DateTime(now.year + 10), initialDate: now);
    if (!mounted || day == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (!mounted || time == null) return;
    setState(() { _until = DateTime(day.year, day.month, day.day, time.hour, time.minute).toUtc(); _error = null; });
  }
  @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85), child: Form(key: _form, child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
      const Text('Supplier quote', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      const Text('Quote only the requested product prices. Tax, delivery charges and payment terms are confirmed separately.'),
      for (final line in widget.quote.lines) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(line.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text([if (line.variant != null) line.variant!, '${line.quantity} × ${line.packLabel}'].join(' · ')),
        TextFormField(key: ValueKey('bulk-price-${line.lineId}'), controller: _prices[line.lineId], keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Price per pack', prefixText: '₹ '),
          onChanged: (_) => setState(() { _error = null; }),
          validator: (v) => _minor(v ?? '') == null ? 'Enter a positive price with up to 2 decimal places.' : null),
      ])),
      if (_subtotal != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8),
        child: _BulkMoney(label: 'Product subtotal', amount: _subtotal!)),
      OutlinedButton.icon(onPressed: _chooseExpiry, icon: const Icon(Icons.event_outlined), label: Text(_until == null ? 'Choose offer expiry date and time' :
        'Valid until ${MaterialLocalizations.of(context).formatShortDate(_until!.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_until!.toLocal()))}')),
      if (_error != null) Text(_error!),
      FilledButton(onPressed: () {
        if (!_form.currentState!.validate()) return;
        if (_until?.isAfter(widget.now().toUtc()) != true) { setState(() { _error = 'Choose a future expiry date and time.'; }); return; }
        final prices = [for (final line in widget.quote.lines) {'lineId': line.lineId, 'unitPriceMinor': _minor(_prices[line.lineId]!.text)!}];
        final total = widget.quote.lines.fold<int>(0, (sum, line) => sum + _minor(_prices[line.lineId]!.text)! * line.quantity);
        if (total > 1000000000000) { setState(() { _error = 'The total is too large. Check the quoted prices.'; }); return; }
        Navigator.pop(context, <String, dynamic>{'validUntil': _until!.toIso8601String(), 'prices': prices});
      }, child: const Text('Send quoted prices')),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not now')),
    ]))));
}

/// Fit the complete exact number as one unit; never split a paise digit or
/// ellipsize money. Only numeric text scales down when its natural width exceeds
/// the viewport; surrounding labels keep the user's text scale unchanged.
class _BulkMoney extends StatelessWidget {
  const _BulkMoney({super.key, required this.amount, this.label});
  final int amount;
  final String? label;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    if (label != null) Text(label!),
    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
      child: Text(_money(amount), softWrap: false, maxLines: 1,
        style: label == null ? null : Theme.of(context).textTheme.titleMedium)),
  ]);
}

/// Shared original facts plus separately requested authoritative order updates.
/// Never submits commerce commands or infers payment/delivery state from money.
class WorkspacePurchaseOriginals extends StatefulWidget {
  const WorkspacePurchaseOriginals({
    super.key,
    required this.gateway,
    required this.role,
    required this.realm,
    this.storeId,
    this.buyingStoreId,
    this.onRatePurchasedItem,
    this.onReceivePurchasedOrder,
    this.onOpenDeviceCase, this.capturedCurrent,this.initialRead,
  });
  final AuthenticatedWorkspaceOrderIdentityGateway gateway;
  final bool Function()? capturedCurrent;
  final ({WorkspacePurchaseReference reference,WorkspacePurchaseOrder original})? initialRead;
  final WorkspaceOrderIdentityRole role;
  final String realm;
  final String? storeId;
  /// Purchasing Store; [storeId] remains exclusively the supplier partition.
  final String? buyingStoreId;
  /// Buyer-only entry after authoritative completion, scoped to one frozen line.
  final void Function(WorkspacePurchaseReference, WorkspacePurchaseOrder, WorkspacePurchasedSkuLine)? onRatePurchasedItem;
  /// Store owner confirms physical arrival separately from delivery updates.
  final void Function(WorkspacePurchaseReference, WorkspacePurchaseOrder)? onReceivePurchasedOrder;
  final Future<bool> Function(WorkspaceDeviceCaseHandoff)? onOpenDeviceCase;
  @override
  State<WorkspacePurchaseOriginals> createState() =>
      _WorkspacePurchaseOriginalsState();
}

class _WorkspacePurchaseOriginalsState
    extends State<WorkspacePurchaseOriginals> {
  final _references = <WorkspacePurchaseReference>[];
  final _details = <String, WorkspacePurchaseOrder>{};
  final _updates = <String, WorkspaceOperationalOrderSnapshot>{};
  final _completions = <String, WorkspaceOrderCompletion>{};
  final _completionFailed = <String>{};
  final _updatePending = <String>{}, _updateFailed = <String>{};
  final _pending = <String>{}, _failed = <String>{};
  int _generation = 0;
  String? _cursor;
  bool _loading = false,
      _unavailable = false,
      _loaded = false,
      _retryMore = false;
  bool _current(int generation) =>
      mounted && generation == _generation && widget.gateway.isCurrent &&
      widget.capturedCurrent?.call() != false;
  @override void initState(){
    super.initState();_assistantOriginalIndices.add(this);
    final read=widget.initialRead;
    if(read!=null&&read.reference.valid&&read.original.orderId==read.reference.orderId&&
       read.original.storeId==read.reference.storeId&&read.original.originalFingerprint==read.reference.originalFingerprint){
      _references.add(read.reference);_details[read.reference.orderId]=read.original;_loaded=true;
    }
  }
  @override
  void didUpdateWidget(covariant WorkspacePurchaseOriginals oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.gateway, widget.gateway) ||
        oldWidget.role != widget.role ||
        oldWidget.realm != widget.realm ||
        oldWidget.storeId != widget.storeId ||
        oldWidget.buyingStoreId != widget.buyingStoreId) {
      _generation++;
      _references.clear();
      _details.clear();
      _updates.clear();
      _completions.clear(); _completionFailed.clear();
      _updatePending.clear();
      _updateFailed.clear();
      _pending.clear();
      _failed.clear();
      _cursor = null;
      _loading = false;
      _unavailable = false;
      _loaded = false;
      _retryMore = false;
    }
  }

  Future<void> _load({bool more = false}) async {
    final generation = _generation;
    if (!_current(generation) || _loading || more && _cursor == null) return;
    _loaded = true;
    _retryMore = more;
    if (mounted) {
      setState(() {
        _loading = true;
        _unavailable = false;
        if (!more) {
          _references.clear();
          _details.clear();
          _updates.clear();
          _completions.clear(); _completionFailed.clear();
          _updatePending.clear();
          _updateFailed.clear();
          _failed.clear();
          _cursor = null;
        }
      });
    }
    final page = await widget.gateway.listPurchaseReferences(
      role: widget.role,
      realm: widget.realm,
      storeId: widget.storeId,
      buyingStoreId: widget.buyingStoreId,
      cursor: more ? _cursor : null,
    );
    if (!_current(generation)) return;
    setState(() {
      _loading = false;
      _unavailable = page == null;
      if (page != null) {
        for (final ref in page.references) {
          if (!_references.any(
            (r) =>
                r.purchaseId == ref.purchaseId &&
                r.storeId == ref.storeId &&
                r.orderId == ref.orderId,
          )) {
            _references.add(ref);
          }
        }
        _cursor = page.nextCursor;
      }
    });
  }

  Future<void> _open(WorkspacePurchaseReference reference) async {
    if (!_current(_generation) || _pending.contains(reference.orderId) ||
        _details.containsKey(reference.orderId)) {
      return;
    }
    final generation = _generation;
    setState(() {
      _pending.add(reference.orderId);
      _failed.remove(reference.orderId);
    });
    final details = await widget.gateway.readReferencedOrder(
      role: widget.role,
      realm: widget.realm,
      reference: reference,
      buyingStoreId: widget.buyingStoreId,
    );
    if (!_current(generation)) return;
    setState(() {
      _pending.remove(reference.orderId);
      if (details == null) {
        _failed.add(reference.orderId);
      } else {
        _details[reference.orderId] = details;
      }
    });
  }

  @override
  void dispose() {
    _assistantOriginalIndices.remove(this);
    _generation++;
    super.dispose();
  }

  Future<void> _checkUpdate(WorkspacePurchaseReference reference) async {
    if (!_current(_generation) ||
        _updatePending.contains(reference.orderId)) {
      return;
    }
    final generation = _generation;
    setState(() {
      _updatePending.add(reference.orderId);
      _updateFailed.remove(reference.orderId);
    });
    final gateway = AuthenticatedWorkspaceOrderOperationsGateway(widget.gateway);
    final preparing = gateway.read(role: widget.role, realm: widget.realm, reference: reference);
    final completing = gateway.readCompletion(role: widget.role, realm: widget.realm, reference: reference);
    final update = await preparing, completion = await completing;
    if (!_current(generation)) return;
    setState(() {
      _updatePending.remove(reference.orderId);
      final previous = _updates[reference.orderId];
      if (update == null ||
          previous != null &&
              (update.fulfilment != previous.fulfilment || update.revision < previous.revision ||
                  update.revision == previous.revision &&
                      update.stage != previous.stage)) {
        _updateFailed.add(reference.orderId);
      } else {
        _updates[reference.orderId] = update;
      }
      final previousCompletion = _completions[reference.orderId], next = completion?.completion;
      final admitted = _updates[reference.orderId];
      final contradictoryMode = next != null && admitted != null &&
        next.outcome != (admitted.fulfilment == 'collection' ? 'collected' : 'delivered');
      if (completion == null || contradictoryMode || previousCompletion != null && previousCompletion != next) {
        _completionFailed.add(reference.orderId);
      } else {
        _completionFailed.remove(reference.orderId);
        if (next != null) _completions[reference.orderId] = next;
      }
    });
  }

  Widget _orderUpdate(WorkspacePurchaseReference reference) {
    final generation = _generation;
    final update = _updates[reference.orderId];
    final completion = _completions[reference.orderId];
    final loading = _updatePending.contains(reference.orderId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (update != null || completion != null)
          Text(
            completion != null ? (completion.outcome == 'collected' ? 'Collected' : 'Delivered') : switch (update!.stage) {
              'Confirmed' => 'Awaiting Store acceptance',
              'Rejected' => 'Not accepted by Store',
              _ => update.stage,
            },
            key: ValueKey('purchase-order-status-${reference.orderId}'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        if (completion != null)
          Text('Completed ${MaterialLocalizations.of(context).formatShortDate(completion.occurredAt.toLocal())} · '
            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(completion.occurredAt.toLocal()))}',
            key: ValueKey('purchase-order-completion-${reference.orderId}')),
        if (_completionFailed.contains(reference.orderId))
          Text(completion == null ? 'Delivery/collection update unavailable.'
            : 'Latest completion update unavailable; showing the recorded result.'),
        if (update?.rejectionReason case final reason?) Text(reason),
        if (_updateFailed.contains(reference.orderId))
          Text(
            update == null
                ? 'Order update unavailable. Original purchase details are kept.'
                : 'Update unavailable; showing earlier status.',
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: loading ? null : () {
              if (_current(generation)) unawaited(_checkUpdate(reference));
            },
            child: Text(
              loading
                  ? 'Checking order update…'
                  : update == null
                  ? 'Check order update'
                  : 'Refresh order update',
            ),
          ),
        ),
      ],
    );
  }

  Widget _receivingAction(WorkspacePurchaseReference reference, WorkspacePurchaseOrder original) {
    final generation = _generation, gateway = widget.gateway, callback = widget.onReceivePurchasedOrder;
    final store = widget.buyingStoreId;
    return Align(alignment: AlignmentDirectional.centerStart, child: TextButton.icon(
      key: ValueKey('purchase-receive-order-${reference.orderId}'),
      onPressed: () {
        if (!_current(generation) || !identical(widget.gateway, gateway) ||
            widget.role != WorkspaceOrderIdentityRole.buyer || callback == null ||
            !identical(widget.onReceivePurchasedOrder, callback) || store == null || widget.buyingStoreId != store ||
            original.purchaser?.kind != 'store' || original.purchaser?.storeId != store ||
            !identical(_details[reference.orderId], original)) {
          return;
        }
        callback(reference, original);
      }, icon: const Icon(Icons.inventory_2_outlined, size: 18), label: const Text('Receive goods')));
  }

  Widget _ratingAction(WorkspacePurchaseReference reference, WorkspacePurchaseOrder original, WorkspacePurchasedSkuLine line) {
    final generation = _generation, gateway = widget.gateway, callback = widget.onRatePurchasedItem;
    final completion = _completions[reference.orderId];
    return Align(alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(key: ValueKey('purchase-rate-item-${reference.orderId}-${line.lineId}'),
        onPressed: () {
          if (!_current(generation) || !identical(widget.gateway, gateway) ||
              widget.role != WorkspaceOrderIdentityRole.buyer || callback == null ||
              !identical(widget.onRatePurchasedItem, callback) || completion == null ||
              _completions[reference.orderId] != completion || _completionFailed.contains(reference.orderId) ||
              !identical(_details[reference.orderId], original)) {
            return;
          }
          callback(reference, original, line);
        },
        icon: const Icon(Icons.star_outline_rounded, size: 18), label: const Text('Rate purchase')));
  }

  @override
  Widget build(BuildContext context) {
    final generation = _generation;
    if (!widget.gateway.isCurrent) return const SizedBox.shrink();
    return Material(
      type: MaterialType.transparency,
      child: ExpansionTile(
        initiallyExpanded:widget.initialRead!=null,
        key: PageStorageKey((
          widget.gateway,
          widget.role,
          widget.realm,
          widget.storeId,
          widget.buyingStoreId,
        )),
        tilePadding: EdgeInsets.zero,
        title: const Text(
          'Saved purchase details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        onExpansionChanged: (expanded) {
          if (_current(generation) && expanded && !_loaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_current(generation) && !_loaded) unawaited(_load());
            });
          }
        },
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Details only. Payment and delivery updates are separate.',
                style: TextStyle(fontSize: 12),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (_unavailable)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Purchase details unavailable'),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              if (_current(generation) && _unavailable) unawaited(_load(more: _retryMore));
                            },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              if (!_loading && !_unavailable && _references.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No saved purchase details returned. This is not the complete online order list.',
                  ),
                ),
              for (final reference in _references)
                KeyedSubtree(
                  key: ValueKey('original-order-${reference.orderId}'),
                  child: ExpansionTile(
                    initiallyExpanded:widget.initialRead?.reference.orderId==reference.orderId,
                    key: PageStorageKey((
                      widget.gateway,
                      widget.role,
                      widget.realm,
                      widget.buyingStoreId,
                      reference.purchaseId,
                      reference.storeId,
                      reference.orderId,
                    )),
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Order ${reference.orderId}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text('View original items and total'),
                    onExpansionChanged: (expanded) {
                      if (_current(generation) && expanded) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_current(generation)) unawaited(_open(reference));
                        });
                      }
                    },
                    children: [
                      if (_pending.contains(reference.orderId))
                        const LinearProgressIndicator(minHeight: 2),
                      if (_failed.contains(reference.orderId))
                        TextButton(
                          onPressed: () {
                            if (_current(generation)) unawaited(_open(reference));
                          },
                          child: const Text('Details unavailable · retry'),
                        ),
                      if (_details[reference.orderId] case final details?) ...[
                        if (details.purchaser?.kind == 'store')
                          Text('Buying for: ${details.purchaser!.name}'),
                        if (widget.role == WorkspaceOrderIdentityRole.buyer && widget.onReceivePurchasedOrder != null &&
                            widget.buyingStoreId != null && details.purchaser?.kind == 'store' &&
                            details.purchaser?.storeId == widget.buyingStoreId)
                          _receivingAction(reference, details),
                        _orderUpdate(reference),
                        WorkspaceOriginalFulfilmentForOrder(original: details),
                        WorkspaceOrderDocumentsForOrder(gateway: widget.gateway,
                          target: WorkspaceOrderDocumentTarget(accountUserId: widget.gateway.accountUserId,
                            role: widget.role, realm: widget.realm, buyingStoreId: widget.buyingStoreId, reference: reference),
                          inputCurrent: () => _current(generation) && identical(_details[reference.orderId], details)),
                        if (details.supplierQuote case final agreed?) ...[
                          _BulkMoney(key: ValueKey('original-supplier-quote-${reference.orderId}'),
                            label: 'Agreed Bulk product prices', amount: agreed.merchandiseMinor),
                          const Text('From the supplier quote accepted for this order.', style: TextStyle(fontSize: 12)),
                        ],
                        for (final line in details.lines)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  line.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${_quantity(line.quantityMilli)} ${line.quantityUnit} · ${line.packLabel}',
                                ),
                                WorkspaceOriginalVariantForLine(line: line),
                                WorkspaceOriginalSupplierTaxForLine(line: line),
                                WorkspaceOriginalCommodityPriceForLine(line: line),
                                WorkspaceOriginalScheduledForLine(line: line),
                                WorkspaceOriginalInstructionsForLine(original: details, lineId: line.lineId),
                                WorkspaceOriginalWarrantyForLine(
                                  key: ValueKey((widget.gateway, _generation, reference.originalFingerprint, line.lineId)),
                                  gateway: widget.gateway, role: widget.role, realm: widget.realm,
                                  buyingStoreId: widget.buyingStoreId, reference: reference, line: line,
                                  inputCurrent: () => _current(generation) && identical(_details[reference.orderId], details)),
                                WorkspacePurchasedUnitsForLine(
                                  key: ValueKey(('units', widget.gateway, _generation, reference.originalFingerprint, line.lineId)),
                                  gateway: widget.gateway, role: widget.role, realm: widget.realm,
                                  buyingStoreId: widget.buyingStoreId, reference: reference, line: line,
                                  onOpenDeviceCase: widget.onOpenDeviceCase,
                                  inputCurrent: () => _current(generation) && identical(_details[reference.orderId], details)),
                                _amount(line.lineTotalMinor),
                                WorkspaceOriginalBenefitsForLine(original: details, lineId: line.lineId),
                                if (widget.role == WorkspaceOrderIdentityRole.buyer &&
                                    _completions.containsKey(reference.orderId) &&
                                    !_completionFailed.contains(reference.orderId) &&
                                    line.publicListing != null && widget.onRatePurchasedItem != null)
                                  _ratingAction(reference, details, line),
                              ],
                            ),
                          ),
                        const Divider(height: 16),
                        for (final (field, label) in const [
                          ('itemsMinor', 'Items'),
                          ('discountMinor', 'Discount'),
                          ('taxMinor', 'Tax'),
                          ('deliveryMinor', 'Delivery'),
                          ('freightMinor', 'Freight'),
                          ('paymentFeeMinor', 'Payment fee'),
                          ('tipMinor', 'Tip'),
                          ('totalMinor', 'Order total'),
                        ])
                          if (field == 'itemsMinor' ||
                              field == 'totalMinor' ||
                              details.totals[field] != 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: field == 'totalMinor'
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  _amount(
                                    details.totals[field]!,
                                    total: field == 'totalMinor',
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              if (_cursor != null && !_loading)
                TextButton(
                  onPressed: () {
                    if (_current(generation)) unawaited(_load(more: true));
                  },
                  child: const Text('Load more purchase details'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amount(int minor, {bool total = false}) => LayoutBuilder(
    builder: (context, constraints) {
      final value = _money(minor);
      final style = TextStyle(
        fontSize: total ? 16 : 13,
        fontWeight: total ? FontWeight.w700 : FontWeight.w400,
      );
      final scaler = MediaQuery.textScalerOf(context);
      final painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout();
      final ratio = painter.width == 0
          ? 1.0
          : (constraints.maxWidth / painter.width).clamp(0.0, 1.0);
      painter.dispose();
      return Text(
        value,
        softWrap: false,
        maxLines: 1,
        style: style.copyWith(fontSize: style.fontSize! * ratio * .99),
      );
    },
  );
}

/// Read-only accepted buyer statements, available only to the supplier owner.
class WorkspaceReceivedDeviceReportPanel extends StatefulWidget {
  const WorkspaceReceivedDeviceReportPanel({super.key, required this.gateway, required this.realm,
    required this.reference, required this.line, this.inputCurrent, this.onOpenCase,this.initialRead,this.initialReportId});
  final AuthenticatedWorkspaceOrderIdentityGateway gateway;
  final String realm;
  final WorkspacePurchaseReference reference;
  final WorkspacePurchasedSkuLine line;
  final bool Function()? inputCurrent;
  final WorkspaceReceivedDeviceReports? initialRead;
  final String? initialReportId;
  final Future<bool> Function(WorkspaceDeviceCaseHandoff)? onOpenCase;
  @override State<WorkspaceReceivedDeviceReportPanel> createState() => _WorkspaceReceivedDeviceReportPanelState();
}

class _WorkspaceReceivedDeviceReportPanelState extends State<WorkspaceReceivedDeviceReportPanel> with WidgetsBindingObserver {
  WorkspaceReceivedDeviceReportSource? _source;
  Object? _lifetime;
  WorkspaceReceivedDeviceReports? _record;
  final _reports = <String, WorkspaceReceivedDeviceReport>{};
  final _history = <String, String>{};
  final _cases = <String, WorkspaceIssueRecord>{};
  final _pages = <String?, String>{};
  int _generation = 0, _revision = -1;
  bool _open = false, _loading = false, _acting = false;
  String? _error;
  Timer? _expiry;
  WorkspacePurchasedLineTarget get _target => WorkspacePurchasedLineTarget(accountUserId: widget.gateway.accountUserId,
    role: WorkspaceOrderIdentityRole.seller, realm: widget.realm, reference: widget.reference, line: widget.line);
  bool _current(int visit) {
    try { return mounted && visit == _generation && widget.inputCurrent?.call() != false && widget.gateway.isCurrent &&
      _source != null && identical(widget.gateway.purchasedUnitSource, _source) && _source!.isCurrent &&
      _source!.accountUserId == widget.gateway.accountUserId && _lifetime != null && _source!.lifetime == _lifetime; }
    on Object { return false; }
  }
  bool get _authorised {
    try { final grant = _record?.ownerAccess;
      return _current(_generation) && grant != null && _source!.ownerAccessCurrent(grant) && grant.allows(_target, DateTime.now().toUtc()); }
    on Object { return false; }
  }
  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _bind();
    final read=widget.initialRead;
    if(read!=null&&read.original!=null&&read.validFor(_target,read.original!)){
      _open=true;_record=read;_revision=read.revision;_reports.addEntries(read.reports.map((r)=>MapEntry(r.id,r)));
      _pages[null]=jsonEncode([read.reports.map((r)=>[r.id,r.fingerprint,r.supportCase?.revision,
        r.supportCase?.updatedAt.toUtc().toIso8601String(),r.supportCase?.purchaseContext?.fingerprint]).toList(),read.complete,read.nextCursor]);
      for(final report in read.reports){_history[report.id]=report.fingerprint;if(report.supportCase case final issue?)_cases[issue.cacheId]=issue;}
      final id=widget.initialReportId;
      if(id!=null)WidgetsBinding.instance.addPostFrameCallback((_){
        if(!_current(_generation)||!_authorised)return;
        final reports=_reports.values.where((r)=>r.id==id&&r.supportCase!=null);
        if(reports.length==1)unawaited(_openCase(reports.single));
      });
    }
  }
  void _bind() {
    final source = widget.gateway.purchasedUnitSource;
    _source = source is WorkspaceReceivedDeviceReportSource ? source : null;
    _lifetime = _source?.lifetime; _source?.addListener(_changed);
  }
  void _retire({bool identity = false}) {
    _generation++; _expiry?.cancel(); _record = null; _reports.clear(); _loading = false; _acting = false;
    if (identity) { _history.clear(); _cases.clear(); _pages.clear(); _revision = -1; }
  }
  void _changed() {
    if (!mounted) return;
    final identity = _source?.lifetime != _lifetime;
    setState(() { _retire(identity: identity); _lifetime = _source?.lifetime; _error = 'Reports need a current owner check.'; });
    if (_open) unawaited(_load());
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed && _open) _changed(); }
  @override void didUpdateWidget(covariant WorkspaceReceivedDeviceReportPanel old) {
    super.didUpdateWidget(old);
    if (!identical(old.gateway, widget.gateway) || old.realm != widget.realm ||
      jsonEncode(old.reference.toJson()) != jsonEncode(widget.reference.toJson()) || jsonEncode(old.line.toJson()) != jsonEncode(widget.line.toJson()) ||
      !identical(widget.gateway.purchasedUnitSource, _source) || _source?.lifetime != _lifetime) {
      _source?.removeListener(_changed); _retire(identity: true); _bind(); _error = null;
      if (_open) unawaited(_load());
    }
  }
  @override void dispose() { _source?.removeListener(_changed); _retire(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  Future<void> _load({bool more = false}) async {
    if (_loading || !_open) return;
    if (!_current(_generation)) { setState(() { _retire(); _error = 'Buyer device reports are unavailable. Store owner access is required.'; }); return; }
    final cursor = more ? _record?.nextCursor : null;
    if (more && (cursor == null || !_authorised || _error != null)) return;
    final visit = ++_generation;
    setState(() { _loading = true; _error = null; });
    final result = await widget.gateway.readReceivedDeviceReports(realm: widget.realm, reference: widget.reference,
      line: widget.line, cursor: cursor, inputCurrent: () => _open && _current(visit));
    if (!_current(visit) || !_open) return;
    String? error;
    if (result == null || result.original == null) { error = 'Current buyer device reports could not be verified. Try again.'; }
    else {
      final signature = jsonEncode([result.reports.map((r) => [r.id, r.fingerprint, r.supportCase?.revision,
        r.supportCase?.updatedAt.toUtc().toIso8601String(), r.supportCase?.purchaseContext?.fingerprint]).toList(), result.complete, result.nextCursor]);
      if (result.revision < _revision || more && result.revision != _revision || result.revision == _revision && _pages[cursor] != null && _pages[cursor] != signature ||
        result.nextCursor != null && (result.nextCursor == cursor || more && _pages.containsKey(result.nextCursor))) {
        error = 'Reports changed. Refresh before continuing.';
      }
      for (final report in result.reports) {
        final previous = report.supportCase == null ? null : _cases[report.supportCase!.cacheId];
        if (_history[report.id] != null && _history[report.id] != report.fingerprint || more && _reports.containsKey(report.id) ||
          previous != null && (report.supportCase!.revision < previous.revision || report.supportCase!.updatedAt.isBefore(previous.updatedAt) ||
            report.supportCase!.revision == previous.revision && !report.supportCase!.sameRevisionContent(previous))) {
          error = 'Reports changed. Refresh before continuing.';
        }
      }
      if (error == null) {
        if (!more) _reports.clear();
        if (result.revision != _revision) _pages.clear();
        _pages[cursor] = signature; _revision = result.revision; _record = result;
        for (final report in result.reports) {
          _reports[report.id] = report; _history[report.id] = report.fingerprint;
          if (report.supportCase case final issue?) { _cases[issue.cacheId] = issue; }
        }
        _expiry?.cancel();
        final remaining = result.ownerAccess.expiresAt.difference(DateTime.now().toUtc());
        _expiry = Timer(remaining.isNegative ? Duration.zero : remaining, () {
          if (mounted && identical(_record, result)) setState(() { _retire(); _error = 'Store owner access expired. Refresh reports.'; });
        });
      }
    }
    setState(() { _loading = false; _error = error; if (!_authorised) { _record = null; _reports.clear(); } });
  }
  Future<void> _openCase(WorkspaceReceivedDeviceReport report) async {
    if (_acting || _loading || _error != null || !_authorised || widget.onOpenCase == null || report.supportCase == null) return;
    final visit = _generation, record = _record!;
    final handoff = WorkspaceDeviceCaseHandoff(gateway: widget.gateway, source: _source!, target: record.target,
      original: record.original!, issue: report.supportCase!, ownerAccess: record.ownerAccess);
    if (!handoff.current) return;
    setState(() => _acting = true);
    try { await widget.onOpenCase!(handoff); }
    on Object { if (_current(visit)) setState(() => _error = 'The linked case could not be opened. Refresh reports.'); }
    finally { if (_current(visit)) setState(() => _acting = false); }
  }
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () {
      setState(() { _open = !_open; if (!_open) _retire(); }); if (_open) unawaited(_load());
    }, child: Text(_open ? 'Close buyer device reports' : 'Buyer device reports'))),
    if (_open) ...[
      if (_loading) const Text('Checking buyer device reports…'),
      if (_error != null) Text(_error!),
      if (_authorised) ...[
        if (_reports.isEmpty && !_loading) Text(_record!.complete ? 'No buyer device reports recorded.' : 'No reports returned. Coverage is incomplete.'),
        if (!_record!.complete && _reports.isNotEmpty) const Text('Partial report history.'),
        for (final report in _reports.values) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Report ${report.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Recorded ${report.recordedAt.toLocal()}'), Text(report.note),
            for (final row in report.rows) Text(row.labels.join(' · ')),
            if (report.supportCase == null) const Text('Support case not connected.')
            else if (widget.onOpenCase == null) const Text('Case review is unavailable here.')
            else Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _acting || _loading || _error != null ? null : () => _openCase(report), child: const Text('Review linked case'))),
          ])),
        if (_record!.nextCursor != null && _error == null) TextButton(onPressed: _loading || _acting ? null : () => _load(more: true), child: const Text('More reports')),
      ],
      TextButton(onPressed: _loading || _acting ? null : () => _load(), child: const Text('Refresh reports')),
    ],
  ]);
}

/// Private supplier draft and separately supplied device readback. Local saves
/// never publish supplier records or submit buyer mismatch reports.
class WorkspacePurchasedUnitsForLine extends StatefulWidget {
  const WorkspacePurchasedUnitsForLine({super.key, required this.gateway, required this.role, required this.realm,
    required this.reference, required this.line, this.buyingStoreId, this.inputCurrent, this.draftStore, this.onOpenDeviceCase,this.initialRead});
  final AuthenticatedWorkspaceOrderIdentityGateway gateway;
  final WorkspaceOrderIdentityRole role;
  final String realm;
  final String? buyingStoreId;
  final WorkspacePurchaseReference reference;
  final WorkspacePurchasedSkuLine line;
  final bool Function()? inputCurrent;
  final WorkspaceUnitAssistantRead? initialRead;
  final WorkPurchasedUnitDraftStore? draftStore;
  final Future<bool> Function(WorkspaceDeviceCaseHandoff)? onOpenDeviceCase;
  @override State<WorkspacePurchasedUnitsForLine> createState() => _WorkspacePurchasedUnitsForLineState();
}

// Accepted private edits outlive their screen while a native write is pending.
// This contains no supplier-published facts and cannot grant access to a Store.
class _UnitDraftPendingEdits {
  _UnitDraftPendingEdits(this.version, List<WorkspacePurchasedUnitRow> rows, this.report) : rows = List.unmodifiable(rows);
  int version;
  List<WorkspacePurchasedUnitRow> rows;
  WorkspacePurchasedUnitMismatchDraft? report;
  void offer(int nextVersion, List<WorkspacePurchasedUnitRow> nextRows, WorkspacePurchasedUnitMismatchDraft? nextReport) {
    version = nextVersion; rows = List.unmodifiable(nextRows); report = nextReport;
  }
}

bool _deviceDraftAccess(WorkspacePurchasedUnitSource source, WorkspacePurchasedLineTarget target,
  WorkspacePurchasedUnitOwnerAccess? owner, WorkspacePurchasedUnitReportAccess? buyer) =>
  target.role == WorkspaceOrderIdentityRole.seller ? owner != null && source.ownerAccessCurrent(owner) && owner.allows(target, DateTime.now().toUtc()) :
    source is WorkspacePurchasedUnitReporter && buyer != null && source.reportAccessCurrent(buyer) && buyer.allows(target, DateTime.now().toUtc());

class _WorkspacePurchasedUnitsForLineState extends State<WorkspacePurchasedUnitsForLine> with WidgetsBindingObserver {
  final _storage = PageStorageBucket();
  int _generation = 0, _draftVisit = 0, _editVersion = 0, _savedVersion = 0, _publishedRevision = 0;
  bool _expanded = false, _loading = false, _unavailable = false, _editing = false, _draftLoading = false,
    _draftReady = false, _saving = false, _recovery = false, _reviewCopy = false;
  int? _localRevision;
  WorkspacePurchasedUnitsRead? _record, _latest;
  WorkspacePurchasedUnitDraft? _checkedCopy;
  List<WorkspacePurchasedUnitRow> _rows = [];
  WorkPurchasedUnitDraftStore? _privateStore;
  Object _saveToken = Object();
  _UnitDraftPendingEdits? _pendingEdits;
  WorkspacePurchasedUnitPublishCommand? _command, _reviewCommand;
  (List<WorkspacePurchasedUnitRow>, int, WorkspacePurchasedUnitMismatchDraft?)? _keptSharingEdits;
  WorkspacePurchasedUnitMismatchDraft? _report;
  WorkspacePurchasedUnitMismatchCommand? _reportReview;
  bool _sharing = false;
  Object _shareToken = Object();
  Timer? _expiry;
  String _draftStatus = '';
  bool _sourceEventQueued = false;
  WorkspacePurchasedLineTarget get _target => WorkspacePurchasedLineTarget(accountUserId: widget.gateway.accountUserId,
    role: widget.role, realm: widget.realm, reference: widget.reference, line: widget.line, buyingStoreId: widget.buyingStoreId);
  Object get _identity => (widget.gateway, widget.gateway.purchasedUnitSource, widget.gateway.purchasedUnitSource?.lifetime, _target.binding, widget.draftStore);
  late Object _owner = _identity;
  bool _current(int visit) {
    final source = widget.gateway.purchasedUnitSource;
    return mounted && visit == _generation && _owner == _identity && widget.gateway.isCurrent && widget.inputCurrent?.call() != false &&
      (source == null || source.isCurrent && source.lifetime != null && source.accountUserId == widget.gateway.accountUserId);
  }
  bool get _canEdit {
    final access = _record?.ownerAccess, source = widget.gateway.purchasedUnitSource;
    return _current(_generation) && !_loading && widget.role == WorkspaceOrderIdentityRole.seller &&
      _record?.complete == true && access != null && source != null && source.ownerAccessCurrent(access) && access.allows(_target, DateTime.now().toUtc());
  }
  bool get _canReport {
    final source = widget.gateway.purchasedUnitSource;
    return _current(_generation) && !_loading && widget.role == WorkspaceOrderIdentityRole.buyer && _record?.complete == true &&
      source != null && _deviceDraftAccess(source, _target, null, _record?.reportAccess);
  }
  bool get _canDraft => _canEdit || _canReport;
  WorkspacePurchasedUnitDraftKey get _draftKey => WorkspacePurchasedUnitDraftKey(account: _target.accountUserId,
    realm: _target.realm, store: _target.reference.storeId, binding: _target.binding);
  WorkPurchasedUnitDraftStore get _store {
    if (widget.draftStore case final supplied?) return supplied;
    return _privateStore ??= (() {
      final gateway = widget.gateway, source = gateway.purchasedUnitSource!, lifetime = source.lifetime,
        access = _record!.ownerAccess, reportAccess = _record!.reportAccess, target = _target, key = _draftKey;
      bool authorised() => gateway.isCurrent && source.isCurrent && source.lifetime == lifetime &&
        source.accountUserId == gateway.accountUserId && _deviceDraftAccess(source, target, access, reportAccess);
      // A frozen, already requested private write may finish after its UI closes,
      // only for this still-authorised principal and original namespace.
      return SecureWorkPurchasedUnitDraftStore(accountScope: () => authorised() ? gateway.accountUserId : null,
        targetScope: () => authorised() ? key.identity : null);
    })();
  }
  void _sourceChanged() {
    if (!mounted || _sourceEventQueued) return;
    _sourceEventQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sourceEventQueued = false;
      if (!mounted) return;
      if (_owner != _identity) {
        setState(_retireIdentity);
        return;
      }
      setState(() {});
      if (_current(_generation) && _expanded && !_loading) unawaited(_read());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
  @override void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this); widget.gateway.purchasedUnitSource?.addListener(_sourceChanged);
    final initial=widget.initialRead;
    if(initial!=null&&initial.record.validFor(_target)){
      _expanded=true;_record=initial.record;_latest=initial.record;
      if(initial.actionId!='AI-ACT-393'){
        final saved=initial.draft;
        _editing=true;_draftReady=true;_localRevision=saved?.revision;_publishedRevision=saved?.publishedRevision??initial.record.revision;
        _rows=List.of(saved?.rows??initial.record.rows);_report=saved?.report??(widget.role==WorkspaceOrderIdentityRole.buyer?
          WorkspacePurchasedUnitMismatchDraft(sourceFingerprint:initial.record.fingerprint):null);
        _command=saved?.pending;_draftStatus=saved==null?'Private draft · not shared':'Saved on this device · not shared';
        if(initial.actionId=='AI-ACT-394'){
          _checkedCopy=saved;
          final prepared=List<WorkspacePurchasedUnitRow>.of(_rows);
          for(final value in initial.fields['rows'] as List){
            final fields=value as Map,id=fields['id'] as String?;
            final index=id==null?-1:prepared.indexWhere((row)=>row.id==id);
            final original=index<0?null:prepared[index];
            final row=WorkspacePurchasedUnitRow(id:original?.id??'device-${_operationId()}',
              serial:fields.containsKey('serial')?fields['serial'] as String:original?.serial??'',
              imei1:fields.containsKey('imei1')?fields['imei1'] as String:original?.imei1??'',
              imei2:fields.containsKey('imei2')?fields['imei2'] as String:original?.imei2??'');
            if(index<0){prepared.add(row);}else{prepared[index]=row;}
          }
          _rows=prepared;
          _reviewCopy=true;_editVersion++;_draftStatus='Review the supplied device details before saving.';
        }else if(initial.actionId=='AI-ACT-396'){
          _checkedCopy=saved;_rows=List.of(initial.record.rows);_report=WorkspacePurchasedUnitMismatchDraft(sourceFingerprint:initial.record.fingerprint,
            selected:(initial.fields['selectedIds'] as List).cast<String>(),note:initial.fields['note'] as String);
          _reviewCopy=true;_editVersion++;_draftStatus='Review the supplied mismatch details before saving.';
        }
      }
    }
  }
  @override void didUpdateWidget(covariant WorkspacePurchasedUnitsForLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.gateway.purchasedUnitSource, widget.gateway.purchasedUnitSource)) {
      oldWidget.gateway.purchasedUnitSource?.removeListener(_sourceChanged);
      widget.gateway.purchasedUnitSource?.addListener(_sourceChanged);
    }
    if (_owner != _identity) _retireIdentity();
  }
  void _retireIdentity() {
    _generation++; _draftVisit++; _owner = _identity; _expiry?.cancel(); _expanded = false; _loading = false; _unavailable = false;
    _record = null; _latest = null; _rows = []; _checkedCopy = null; _privateStore = null; _draftReady = false; _editing = false;
    _draftLoading = false; _saving = false; _saveToken = Object(); _pendingEdits = null; _recovery = false; _reviewCopy = false; _localRevision = null;
    _editVersion = 0; _savedVersion = 0; _publishedRevision = 0; _draftStatus = '';
    _command = null; _reviewCommand = null; _sharing = false; _shareToken = Object(); _keptSharingEdits = null; _report = null; _reportReview = null;
  }
  @override void dispose() {
    _generation++; _draftVisit++; _expiry?.cancel(); widget.gateway.purchasedUnitSource?.removeListener(_sourceChanged);
    WidgetsBinding.instance.removeObserver(this); super.dispose();
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _current(_generation) && _expanded) unawaited(_read());
  }
  Future<void> _read() async {
    final visit = _generation;
    if (!_current(visit) || !_expanded || _loading) return;
    setState(() { _loading = true; _unavailable = false; _record = null; });
    final result = await widget.gateway.readPurchasedUnits(role: widget.role, realm: widget.realm, reference: widget.reference,
      line: widget.line, buyingStoreId: widget.buyingStoreId, inputCurrent: () => _current(visit) && _expanded);
    if (!_current(visit) || !_expanded) return;
    final previous = _latest, accepted = result != null && (previous == null || result.revision > previous.revision ||
      result.revision == previous.revision && result.fingerprint == previous.fingerprint);
    setState(() {
      _loading = false; _unavailable = !accepted; _record = accepted ? result : null; _privateStore = null;
      if (accepted) {
        _latest = result;
        if (_reviewCommand != null && _reviewCommand!.expectedRevision != result.revision ||
          _reportReview != null && _reportReview!.sourceFingerprint != result.fingerprint) {
          _reviewCommand = null; _reportReview = null; _draftStatus = 'Supplier device records changed. Review the latest records before continuing.';
        }
      }
    });
    _expiry?.cancel();
    final deadline = _record?.ownerAccess?.expiresAt ?? _record?.reportAccess?.expiresAt;
    if (deadline != null && deadline.isAfter(DateTime.now().toUtc())) {
      _expiry = Timer(deadline.difference(DateTime.now().toUtc()), () { if (_current(visit)) setState(() {}); });
    }
  }
  String _rowBytes(List<WorkspacePurchasedUnitRow> rows) => jsonEncode(rows.map((r) => r.toJson()).toList());
  String _draftBytes(List<WorkspacePurchasedUnitRow> rows, WorkspacePurchasedUnitMismatchDraft? report) => jsonEncode([_rowBytes(rows), report?.toJson()]);
  Future<void> _loadDraft({bool recover = false}) async {
    if (!_expanded || !_canDraft || _draftLoading || _saving || _sharing) return;
    final visit = _generation, draftVisit = ++_draftVisit, store = _store, key = _draftKey;
    setState(() { _editing = true; _draftLoading = true; _draftStatus = 'Opening private draft…'; });
    try {
      final saved = await store.read(key);
      if (!_current(visit) || !_expanded || draftVisit != _draftVisit) return;
      if (saved != null && (!saved.valid || saved.key.identity != key.identity)) throw const FormatException();
      if (saved != null && (widget.role == WorkspaceOrderIdentityRole.buyer) != (saved.report != null)) throw const FormatException();
      if (!_canDraft) { setState(() { _recovery = true; _draftStatus = 'Draft access changed. Check the saved copy when access is restored.'; }); return; }
      setState(() {
        _localRevision = saved?.revision; _draftReady = true; _recovery = false; _command = saved?.pending; _reviewCommand = null; _reportReview = null;
        if (_command != null || saved?.report?.pending != null) {
          if (_editVersion != _savedVersion && _draftBytes(_rows, _report) != _draftBytes(saved!.rows, saved.report)) {
            _keptSharingEdits ??= (List.unmodifiable(_rows), _publishedRevision, _report);
          }
          _rows = List.of(saved!.rows); _report = saved.report; _publishedRevision = saved.publishedRevision; _savedVersion = _editVersion;
          _reviewCopy = false; _draftStatus = _report?.recorded == true ? 'Report recorded. Reference: ${_report!.reportId}' : 'Result needs checking. Your saved request is kept.';
        } else if (_keptSharingEdits case final kept?) {
          _rows = List.of(kept.$1); _publishedRevision = kept.$2; _report = kept.$3; _checkedCopy = saved;
          _reviewCopy = true; _editVersion++; _keptSharingEdits = null; _draftStatus = 'Sharing checked. Choose between your kept edits and the saved draft.';
        } else if (recover && _editVersion != _savedVersion && _draftBytes(_rows, _report) != _draftBytes(saved?.rows ?? const [], saved?.report)) {
          _checkedCopy = saved; _reviewCopy = true; _draftStatus = 'Saved draft checked. Choose which copy to keep.';
        } else {
          _rows = List.of(saved?.rows ?? _record!.rows); _publishedRevision = saved?.publishedRevision ?? _record!.revision;
          _report = saved?.report ?? (widget.role == WorkspaceOrderIdentityRole.buyer ? WorkspacePurchasedUnitMismatchDraft(sourceFingerprint: _record!.fingerprint) : null);
          _savedVersion = _editVersion; _reviewCopy = false; _draftStatus = saved == null ? 'Private draft · not shared' : 'Saved on this device · not shared';
        }
      });
      if (saved != null && saved.publishedRevision > (_record?.revision ?? -1)) unawaited(_read());
    } on Object {
      if (_current(visit) && _expanded && draftVisit == _draftVisit) setState(() { _recovery = true; _draftStatus = 'Private draft could not be checked. Saved data and your edits are kept.'; });
    } finally { if (_current(visit) && draftVisit == _draftVisit) setState(() { _draftLoading = false; }); }
  }
  bool get _editable => _expanded && _canDraft && _editing && _draftReady && !_draftLoading && !_recovery && !_reviewCopy &&
    !_sharing && _command == null && _reviewCommand == null && _report?.pending == null && _reportReview == null;
  bool get _shareReady => widget.role == WorkspaceOrderIdentityRole.seller && _editable && !_saving && _editVersion == _savedVersion && _localRevision != null &&
    _publishedRevision == _record?.revision && _rows.every((r) => r.ready) && widget.gateway.purchasedUnitSource is WorkspacePurchasedUnitPublisher;
  bool _draftActionCurrent(int visit, int draftVisit) => _current(visit) && _expanded && draftVisit == _draftVisit;
  void _change(List<WorkspacePurchasedUnitRow> rows, {WorkspacePurchasedUnitMismatchDraft? report}) {
    if (!_editable || rows.length > 1000 || rows.any((r) => !r.validDraft)) return;
    setState(() { _rows = List.of(rows); _report = report ?? _report; _editVersion++; _draftStatus = 'Saving private draft…'; });
    if (_saving) _pendingEdits?.offer(_editVersion, _rows, _report);
    unawaited(_save());
  }
  Future<void> _save() async {
    if (!_editable || _saving || _savedVersion == _editVersion) return;
    final visit = _generation, owner = _owner, saveToken = _saveToken, store = _store, key = _draftKey;
    final gateway = widget.gateway, source = gateway.purchasedUnitSource!, lifetime = source.lifetime,
      access = _record!.ownerAccess, reportAccess = _record!.reportAccess, target = _target, publishedRevision = _publishedRevision;
    bool authorised() => gateway.isCurrent && source.isCurrent && source.lifetime == lifetime &&
      source.accountUserId == gateway.accountUserId && _deviceDraftAccess(source, target, access, reportAccess);
    final pending = _UnitDraftPendingEdits(_editVersion, _rows, _report);
    _pendingEdits = pending;
    var localRevision = _localRevision, savedVersion = _savedVersion;
    setState(() { _saving = true; });
    final waiting = Timer(const Duration(seconds: 10), () {
      if (_current(visit) && identical(pending, _pendingEdits) && _saving) {
        setState(() {
          _recovery = true;
          _draftStatus = 'Private draft save is still pending. Your edits are kept while the saved result is checked.';
        });
      }
    });
    try {
      while (authorised() && savedVersion != pending.version) {
        final version = pending.version, expected = localRevision;
        final next = WorkspacePurchasedUnitDraft(key: key, revision: (expected ?? 0) + 1,
          publishedRevision: publishedRevision, rows: pending.rows, report: pending.report);
        await store.save(next, expectedRevision: expected);
        localRevision = next.revision; savedVersion = version;
        if (_current(visit) && owner == _owner) { _localRevision = localRevision; _savedVersion = savedVersion; }
      }
      if (_current(visit) && owner == _owner) {
        setState(() {
          _recovery = savedVersion != pending.version;
          _draftStatus = !_recovery ? 'Saved on this device · not shared' : 'Your unsaved edits are kept here. Check the saved copy before continuing.';
        });
      }
    } on Object {
      if (_current(visit)) setState(() { _recovery = true; _draftStatus = 'Draft save needs recovery. Your edits are kept; check the saved copy before editing.'; });
    } finally {
      waiting.cancel();
      if (mounted && identical(saveToken, _saveToken) && identical(pending, _pendingEdits)) {
        setState(() { _saving = false; _pendingEdits = null; });
      }
    }
  }
  void _chooseCopy(bool kept, int visit, int draftVisit, WorkspacePurchasedUnitDraft? checkedCopy) {
    if (!_draftActionCurrent(visit, draftVisit) || !identical(checkedCopy, _checkedCopy) || !_canDraft || !_reviewCopy || _saving) return;
    setState(() {
      _reviewCopy = false; _recovery = false;
      if (!kept) {
        _rows = List.of(_checkedCopy?.rows ?? (widget.role == WorkspaceOrderIdentityRole.buyer ? _record!.rows : const []));
        _report = _checkedCopy?.report ?? (widget.role == WorkspaceOrderIdentityRole.buyer ? WorkspacePurchasedUnitMismatchDraft(sourceFingerprint: _record!.fingerprint) : null);
        _publishedRevision = _checkedCopy?.publishedRevision ?? _record!.revision; _savedVersion = _editVersion;
      }
      else { _editVersion++; }
      _draftVisit++; _draftStatus = kept ? 'Saving private draft…' : 'Saved on this device · not shared';
    });
    if (kept) unawaited(_save());
  }
  void _field(String id, String field, String value) {
    if (!_canEdit) return;
    final rows = [for (final row in _rows) row.id != id ? row : WorkspacePurchasedUnitRow(id: row.id,
      serial: field == 'serial' ? value : row.serial, imei1: field == 'imei1' ? value : row.imei1, imei2: field == 'imei2' ? value : row.imei2)];
    _change(rows);
  }
  String _operationId() => List.generate(16, (_) => math.Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  void _reviewSharing(int visit, int draftVisit) {
    if (!_draftActionCurrent(visit, draftVisit) || !_shareReady) return;
    setState(() { _reviewCommand = WorkspacePurchasedUnitPublishCommand(key: _draftKey, operationId: _operationId(),
      expectedRevision: _publishedRevision, rows: _rows); });
  }
  void _rebaseDraft(int visit, int draftVisit, WorkspacePurchasedUnitsRead record, bool useSupplier) {
    if (!_draftActionCurrent(visit, draftVisit) || !_canEdit || !_editable || _saving || !identical(record, _record)) return;
    _publishedRevision = record.revision;
    _draftVisit++;
    _change(useSupplier ? record.rows : _rows);
  }
  bool get _reportReady => _canReport && _editable && !_saving && _editVersion == _savedVersion && _localRevision != null &&
    _report != null && _report!.selected.isNotEmpty && _report!.note.trim().isNotEmpty &&
    _publishedRevision == _record?.revision && _report!.sourceFingerprint == _record?.fingerprint;
  void _changeReport({String? note, List<String>? selected}) {
    if (!_canReport || !_editable || _report == null) return;
    final report = WorkspacePurchasedUnitMismatchDraft(sourceFingerprint: _report!.sourceFingerprint,
      note: note ?? _report!.note, selected: selected ?? _report!.selected);
    if (!report.validFor(_draftKey, _publishedRevision, _rows)) return;
    _change(_rows, report: report);
  }
  void _latestReportSource(int visit, int draftVisit, WorkspacePurchasedUnitsRead record) {
    if (!_draftActionCurrent(visit, draftVisit) || !_canReport || !_editable || _saving || !identical(record, _record)) return;
    _publishedRevision = record.revision; _draftVisit++;
    _change(record.rows, report: WorkspacePurchasedUnitMismatchDraft(sourceFingerprint: record.fingerprint, note: _report?.note ?? ''));
  }
  void _reviewMismatch(int visit, int draftVisit) {
    if (!_draftActionCurrent(visit, draftVisit) || !_reportReady) return;
    final command = WorkspacePurchasedUnitMismatchCommand(key: _draftKey, operationId: _operationId(), sourceRevision: _publishedRevision,
      sourceFingerprint: _report!.sourceFingerprint, note: _report!.note.trim(), rows: _rows.where((r) => _report!.selected.contains(r.id)).toList());
    if (command.valid) setState(() { _reportReview = command; });
  }
  Future<void> _sendMismatch(WorkspacePurchasedUnitMismatchCommand command, {required bool reconcile}) async {
    if (!_expanded || !_canReport || _sharing || _saving || _draftLoading || _report == null || _report!.recorded) return;
    if (reconcile ? _report!.pending?.fingerprint != command.fingerprint : _reportReview?.fingerprint != command.fingerprint ||
      _report!.pending != null || _editVersion != _savedVersion || _publishedRevision != _record?.revision || _report!.sourceFingerprint != _record?.fingerprint) {
      return;
    }
    final visit = _generation, draftVisit = _draftVisit, store = _store, key = _draftKey, token = _shareToken,
      source = widget.gateway.purchasedUnitSource!, lease = _record!.reportAccess!, target = _target;
    bool current() => _draftActionCurrent(visit, draftVisit) && _deviceDraftAccess(source, target, null, lease);
    setState(() {
      _sharing = true; _reportReview = null;
      _report = WorkspacePurchasedUnitMismatchDraft(sourceFingerprint: _report!.sourceFingerprint, note: _report!.note, selected: _report!.selected, pending: command);
      _draftStatus = 'Checking device report…';
    });
    try {
      if (!reconcile) {
        final pending = WorkspacePurchasedUnitDraft(key: key, revision: (_localRevision ?? 0) + 1,
          publishedRevision: _publishedRevision, rows: _rows, report: _report);
        await store.save(pending, expectedRevision: _localRevision).timeout(const Duration(seconds: 10));
        if (!current()) return;
        _localRevision = pending.revision;
      } else {
        final saved = await store.read(key).timeout(const Duration(seconds: 10));
        if (!current()) return;
        if (saved == null || !saved.valid || saved.key.identity != key.identity || saved.report?.pending?.fingerprint != command.fingerprint || saved.report!.recorded) {
          setState(() { _recovery = true; _draftStatus = 'Check the saved private report before continuing.'; }); return;
        }
        _localRevision = saved.revision;
      }
      if (!current() || !_canReport) return;
      final reply = await widget.gateway.reportPurchasedUnitMismatch(command: command, realm: widget.realm, reference: widget.reference,
        line: widget.line, buyingStoreId: widget.buyingStoreId, reconcile: reconcile, inputCurrent: current);
      if (!current()) return;
      if (reply == null || reply.state == WorkspacePurchasedUnitPublishState.pending) {
        setState(() { _draftStatus = 'Report result needs checking. Your saved request is kept.'; }); return;
      }
      final recorded = reply.state == WorkspacePurchasedUnitPublishState.applied;
      final report = WorkspacePurchasedUnitMismatchDraft(sourceFingerprint: _report!.sourceFingerprint, note: _report!.note, selected: _report!.selected,
        pending: recorded ? command : null, reportId: reply.reportId, recordedAt: reply.recordedAt?.toUtc());
      final resolved = WorkspacePurchasedUnitDraft(key: key, revision: _localRevision! + 1, publishedRevision: _publishedRevision, rows: _rows, report: report);
      await store.save(resolved, expectedRevision: _localRevision).timeout(const Duration(seconds: 10));
      if (!current()) return;
      setState(() {
        _localRevision = resolved.revision; _report = report; _recovery = false; _draftVisit++; _savedVersion = _editVersion;
        _draftStatus = recorded ? 'Report recorded. Reference: ${reply.reportId}' : 'Report not sent. Your private draft is kept.';
        if (!recorded) {
          if (_keptSharingEdits case final kept?) {
            _rows = List.of(kept.$1); _publishedRevision = kept.$2; _report = kept.$3; _checkedCopy = resolved;
            _reviewCopy = true; _editVersion++; _keptSharingEdits = null; _draftStatus = 'Choose between your kept edits and the saved report draft.';
          }
        }
      });
    } on Object {
      if (current()) setState(() { _recovery = true; _draftStatus = 'Report result needs checking. Recover the saved draft before continuing.'; });
    } finally {
      if (mounted && identical(token, _shareToken)) setState(() { _sharing = false; });
    }
  }
  Future<void> _share(WorkspacePurchasedUnitPublishCommand command, {required bool reconcile}) async {
    if (!_expanded || !_canEdit || _sharing || _saving || _draftLoading || widget.gateway.purchasedUnitSource is! WorkspacePurchasedUnitPublisher) return;
    if (reconcile ? _command?.fingerprint != command.fingerprint : _reviewCommand?.fingerprint != command.fingerprint ||
      _command != null || _editVersion != _savedVersion || _publishedRevision != _record?.revision || _rowBytes(_rows) != _rowBytes(command.rows)) {
      return;
    }
    final visit = _generation, draftVisit = _draftVisit, store = _store, key = _draftKey, shareToken = _shareToken,
      source = widget.gateway.purchasedUnitSource!, lease = _record!.ownerAccess!, target = _target;
    bool current() => _draftActionCurrent(visit, draftVisit) && _deviceDraftAccess(source, target, lease, null);
    setState(() { _sharing = true; _command = command; _reviewCommand = null; _draftStatus = 'Checking device sharing…'; });
    try {
      if (!reconcile) {
        final pending = WorkspacePurchasedUnitDraft(key: key, revision: (_localRevision ?? 0) + 1,
          publishedRevision: command.expectedRevision, rows: command.rows, pending: command);
        await store.save(pending, expectedRevision: _localRevision).timeout(const Duration(seconds: 10));
        if (!current()) return;
        _localRevision = pending.revision;
      } else {
        final saved = await store.read(key).timeout(const Duration(seconds: 10));
        if (!current()) return;
        if (saved == null || !saved.valid || saved.key.identity != key.identity || saved.pending?.fingerprint != command.fingerprint) {
          setState(() { _recovery = true; _draftStatus = 'Check the saved private draft before continuing. Your request is kept.'; });
          return;
        }
        _localRevision = saved.revision;
      }
      if (!current() || !_canEdit) return;
      final reply = await widget.gateway.publishPurchasedUnits(command: command, realm: widget.realm,
        reference: widget.reference, line: widget.line, reconcile: reconcile, inputCurrent: current);
      if (!current()) return;
      if (reply == null || reply.state == WorkspacePurchasedUnitPublishState.pending) {
        setState(() { _draftStatus = 'Sharing result needs checking. Your saved request is kept.'; }); return;
      }
      final record = reply.record;
      if (record != null && _latest?.revision == record.revision && _latest!.fingerprint != record.fingerprint) {
        setState(() { _draftStatus = 'Sharing result needs checking. Your saved request is kept.'; }); return;
      }
      final resolved = WorkspacePurchasedUnitDraft(key: key, revision: _localRevision! + 1,
        publishedRevision: record?.revision ?? command.expectedRevision, rows: record?.rows ?? command.rows);
      await store.save(resolved, expectedRevision: _localRevision).timeout(const Duration(seconds: 10));
      if (!current()) return;
      setState(() {
        _localRevision = resolved.revision; _rows = List.of(resolved.rows); _publishedRevision = resolved.publishedRevision;
        _command = null; _recovery = false; _draftVisit++; _savedVersion = _editVersion;
        if (record != null && (_latest == null || record.revision > _latest!.revision)) { _record = record; _latest = record; }
        _draftStatus = record == null ? 'Not shared. Your private draft is kept.' : 'Device details shared with the buyer.';
        if (_keptSharingEdits case final kept?) {
          _rows = List.of(kept.$1); _publishedRevision = kept.$2; _report = kept.$3; _checkedCopy = resolved;
          _reviewCopy = true; _editVersion++; _keptSharingEdits = null; _draftStatus = 'Sharing checked. Choose between your kept edits and the saved draft.';
        }
      });
    } on Object {
      if (current()) setState(() { _recovery = true; _draftStatus = 'Sharing result needs checking. Recover the saved draft before continuing.'; });
    } finally {
      if (mounted && identical(shareToken, _shareToken)) setState(() { _sharing = false; });
    }
  }
  @override Widget build(BuildContext context) {
    final visit = _generation, draftVisit = _draftVisit, checkedCopy = _checkedCopy, record = _current(_generation) ? _record : null,
      pending = _command, review = _reviewCommand;
    final canEdit = _canEdit, unavailable = !_current(_generation) || _unavailable;
    return PageStorage(bucket: _storage, child: ExpansionTile(key: ValueKey(_owner), initiallyExpanded:widget.initialRead!=null, tilePadding: EdgeInsets.zero,
      title: const Text('Device details', style: TextStyle(fontSize: 13)), onExpansionChanged: (open) {
        if (!_current(visit)) return;
        _expanded = open;
        if (!open) {
          if (_editing && (_saving || _editVersion != _savedVersion)) {
            _recovery = true; _draftStatus = 'Check the saved private draft before continuing. Your edits are kept.';
          }
          _generation++; _loading = false; _unavailable = false;
        }
        final opening = _generation;
        WidgetsBinding.instance.addPostFrameCallback((_) { if (_current(opening)) { setState(() {}); if (_expanded) unawaited(_read()); } });
      }, children: [Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_loading && !unavailable) const LinearProgressIndicator(minHeight: 2),
        if (unavailable) ...[const Text('Device details for this purchase are unavailable.'),
          Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () {
            if (_current(visit) && _expanded && !_loading && _unavailable) unawaited(_read());
          }, child: const Text('Retry device details')))],
        if (record != null) ...[
          const Text('Supplier device records · private'),
          if (!record.complete) const Text('Only some device records are shown.'),
          if (record.rows.isEmpty) Text(record.complete ? 'No device identifiers were supplied for this purchase.' : 'No device identifiers were returned in this partial view.'),
          for (final row in record.rows) Padding(padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final label in row.labels) Text(label)])),
          if (widget.role == WorkspaceOrderIdentityRole.buyer) ...[
            if (!_canReport) const Text('Mismatch reporting is unavailable.'),
            if (_canReport && !_editing) TextButton(onPressed: () {
              if (_draftActionCurrent(visit, draftVisit) && _canReport && !_editing) unawaited(_loadDraft());
            }, child: const Text('Report a device mismatch')),
          ],
          if (widget.role == WorkspaceOrderIdentityRole.seller) ...[
            if (!canEdit) const Text('Device draft editing is unavailable. Saved private drafts are kept.'),
            if (canEdit && !_editing) TextButton(onPressed: () { if (_draftActionCurrent(visit, draftVisit) && _canEdit && !_editing) unawaited(_loadDraft()); }, child: const Text('Prepare device details')),
          ],
        ],
        if (widget.role == WorkspaceOrderIdentityRole.seller) WorkspaceReceivedDeviceReportPanel(
          key: ValueKey(('received-device-reports', _owner)), gateway: widget.gateway, realm: widget.realm,
          reference: widget.reference, line: widget.line, inputCurrent: () => _current(visit) && _expanded, onOpenCase: widget.onOpenDeviceCase),
        if (_canDraft && _editing) ...[
          const Divider(height: 16), Text(widget.role == WorkspaceOrderIdentityRole.buyer ? 'Private mismatch report' : 'Private device draft'),
          if (widget.role == WorkspaceOrderIdentityRole.seller) const Text('Add one row for each actual device. Serial and both IMEIs belong on the same row.'),
          if (_draftStatus.isNotEmpty) Text(_draftStatus, key: const ValueKey('unit-draft-status')),
          if (_draftLoading || _sharing) const LinearProgressIndicator(minHeight: 2),
          if (_recovery) TextButton(onPressed: _draftLoading || _saving || _sharing ? null : () {
            if (_draftActionCurrent(visit, draftVisit)) unawaited(_loadDraft(recover: true));
          }, child: const Text('Recover private draft')),
          if (_reviewCopy) ...[
            const Text('Your kept edits'),
            ..._copyReview(_rows, report: _report),
            const Text('Saved on this device'),
            ..._copyReview(checkedCopy?.rows ?? const [], report: checkedCopy?.report),
            Wrap(children: [TextButton(onPressed: () => _chooseCopy(false, visit, draftVisit, checkedCopy), child: const Text('Use saved draft')),
              TextButton(onPressed: () => _chooseCopy(true, visit, draftVisit, checkedCopy), child: const Text('Save kept edits'))]),
          ],
          if (_draftReady && !_reviewCopy) ...[
            if (widget.role == WorkspaceOrderIdentityRole.buyer) _reportBody(context, visit, draftVisit, record)
            else ...[
            if (_publishedRevision != record?.revision) ...[
              const Text('Supplier records changed. Compare the supplier records above with your draft before sharing.'),
              if (record != null && _editable && !_saving) Wrap(children: [
                TextButton(onPressed: () => _rebaseDraft(visit, draftVisit, record, true), child: const Text('Use supplier records')),
                TextButton(onPressed: () => _rebaseDraft(visit, draftVisit, record, false), child: const Text('Keep this draft against updated records')),
              ]),
            ],
            if (review == null) ...[
            for (final (index, row) in _rows.indexed) Padding(padding: const EdgeInsets.only(top: 8), child: Column(
              key: ValueKey(('unit-draft-row', _owner, _draftVisit, row.id)), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [Expanded(child: Text('Device ${index + 1}')), IconButton(tooltip: 'Remove device ${index + 1}',
                  onPressed: !_editable ? null : () { if (_draftActionCurrent(visit, draftVisit)) _change(_rows.where((r) => r.id != row.id).toList()); }, icon: const Icon(Icons.remove_circle_outline))]),
                for (final (field, label, value) in [('serial', 'Serial', row.serial), ('imei1', 'IMEI 1', row.imei1), ('imei2', 'IMEI 2', row.imei2)])
                  TextFormField(key: ValueKey(('unit-input', row.id, field)), initialValue: value, enabled: _editable,
                    maxLength: 240, decoration: InputDecoration(labelText: label, counterText: ''),
                    onChanged: (value) { if (_draftActionCurrent(visit, draftVisit)) _field(row.id, field, value); }),
                if (!row.ready) const Text('Enter at least one complete printed identifier before sharing.'),
              ])),
            Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: !_editable || _rows.length >= 1000 ? null : () {
              if (!_draftActionCurrent(visit, draftVisit)) return;
              final id = 'device-${List.generate(16, (_) => math.Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
              _change([..._rows, WorkspacePurchasedUnitRow(id: id)]);
            }, child: const Text('Add device'))),
            ],
            if (widget.gateway.purchasedUnitSource is! WorkspacePurchasedUnitPublisher)
              const Text('Sharing device details is unavailable. This draft is not shared with the buyer.')
            else if (pending != null) ...[
              const Text('Editing is locked until this sharing request is checked.'),
              TextButton(onPressed: _sharing || _recovery ? null : () {
                if (_draftActionCurrent(visit, draftVisit) && identical(pending, _command)) unawaited(_share(pending, reconcile: true));
              }, child: const Text('Check sharing status')),
            ] else if (review != null) ...[
              const Text('Review device details to share'),
              const Text('These identifiers will be shared privately with the buyer for this purchase.'),
              ..._copyReview(review.rows),
              Wrap(children: [TextButton(onPressed: () {
                if (_draftActionCurrent(visit, draftVisit) && identical(review, _reviewCommand)) setState(() { _reviewCommand = null; });
              }, child: const Text('Back to editing')),
                FilledButton(onPressed: () {
                  if (_draftActionCurrent(visit, draftVisit) && identical(review, _reviewCommand)) unawaited(_share(review, reconcile: false));
                }, child: const Text('Share device details'))]),
            ] else TextButton(onPressed: !_shareReady ? null : () => _reviewSharing(visit, draftVisit), child: const Text('Review and share device details')),
            ],
          ],
        ],
      ])]));
  }
  Widget _reportBody(BuildContext context, int visit, int draftVisit, WorkspacePurchasedUnitsRead? record) {
    final report = _report, review = _reportReview;
    if (report == null) return const Text('Private report is unavailable. Recover the saved draft before continuing.');
    if (report.recorded) {
      final at = report.recordedAt!.toLocal(), local = MaterialLocalizations.of(context);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Report reference: ${report.reportId}'), Text('Recorded ${local.formatMediumDate(at)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(at))}'),
        ..._copyReview(_rows.where((r) => report.selected.contains(r.id)).toList()), SelectableText(report.note.trim()),
        if (_keptSharingEdits?.$3 case final kept?) ...[const Text('Unsaved report note kept on this screen'), SelectableText(kept.note)],
      ]);
    }
    if (report.pending case final pending?) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Editing is locked until this report is checked.'), ..._copyReview(pending.rows), Text(pending.note),
        TextButton(onPressed: _sharing || _recovery ? null : () {
          if (_draftActionCurrent(visit, draftVisit) && identical(pending, _report?.pending)) unawaited(_sendMismatch(pending, reconcile: true));
        }, child: const Text('Check report status')),
      ]);
    }
    if (review != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Review your device mismatch report'), const Text('This report will be shared privately with the supplier for this purchase.'),
        ..._copyReview(review.rows), Text(review.note),
        Wrap(children: [TextButton(onPressed: () {
          if (_draftActionCurrent(visit, draftVisit) && identical(review, _reportReview)) setState(() { _reportReview = null; });
        }, child: const Text('Back to report')),
          FilledButton(onPressed: () {
            if (_draftActionCurrent(visit, draftVisit) && identical(review, _reportReview)) unawaited(_sendMismatch(review, reconcile: false));
          }, child: const Text('Send device report'))]),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Select the supplier-recorded devices that differ from what you received.'),
      if (record != null && (_publishedRevision != record.revision || report.sourceFingerprint != record.fingerprint)) ...[
        const Text('Supplier device records changed. Review the latest records and select the affected devices again.'),
        TextButton(onPressed: !_editable || _saving ? null : () => _latestReportSource(visit, draftVisit, record), child: const Text('Review latest supplier records')),
      ],
      for (final (index, row) in _rows.indexed) CheckboxListTile(key: ValueKey(('mismatch-device', row.id)), contentPadding: EdgeInsets.zero,
        dense: true, controlAffinity: ListTileControlAffinity.leading, title: Text('Device ${index + 1}'), subtitle: Text(row.labels.join('\n')),
        value: report.selected.contains(row.id), onChanged: !_editable ? null : (selected) {
          if (!_draftActionCurrent(visit, draftVisit)) return;
          final ids = {...report.selected}; if (selected == true) { ids.add(row.id); } else { ids.remove(row.id); }
          _changeReport(selected: _rows.where((r) => ids.contains(r.id)).map((r) => r.id).toList());
        }),
      TextFormField(key: ValueKey(('mismatch-note', _owner, _draftVisit)), initialValue: report.note, enabled: _editable,
        minLines: 2, maxLines: 4, maxLength: 2000, decoration: const InputDecoration(labelText: 'Describe the mismatch'),
        onChanged: (note) { if (_draftActionCurrent(visit, draftVisit)) _changeReport(note: note); }),
      const Text('Select a device and describe what differs before sending.'),
      TextButton(onPressed: !_reportReady ? null : () => _reviewMismatch(visit, draftVisit), child: const Text('Review device report')),
    ]);
  }
  Iterable<Widget> _copyReview(List<WorkspacePurchasedUnitRow> rows, {WorkspacePurchasedUnitMismatchDraft? report}) sync* {
    if (report != null) {
      yield Text(report.note.isEmpty ? 'No report description saved.' : report.note);
      yield Text('${report.selected.length} selected devices');
    }
    if (rows.isEmpty) yield const Text('No saved device rows.');
    for (final (index, row) in rows.indexed) {
      yield Text('Device ${index + 1}');
      for (final (label, value) in [('Serial', row.serial), ('IMEI 1', row.imei1), ('IMEI 2', row.imei2)]) {
        yield Text('$label: ${value.isEmpty ? 'Not entered' : value}');
      }
    }
  }
}

/// Shared private document reader for buyer and supplier order originals.
class WorkspaceOrderDocumentsForOrder extends StatefulWidget {
  const WorkspaceOrderDocumentsForOrder({super.key, required this.gateway, required this.target, this.inputCurrent,this.initialRead,this.initialDocumentId});
  final AuthenticatedWorkspaceOrderIdentityGateway gateway;
  final WorkspaceOrderDocumentTarget target;
  final bool Function()? inputCurrent;
  final WorkspaceOrderDocumentsRead? initialRead;
  final String? initialDocumentId;
  @override State<WorkspaceOrderDocumentsForOrder> createState() => _WorkspaceOrderDocumentsForOrderState();
}

class _WorkspaceOrderDocumentsForOrderState extends State<WorkspaceOrderDocumentsForOrder> with WidgetsBindingObserver {
  final _storage = PageStorageBucket();
  final _access = ValueNotifier<int>(0);
  int _generation = 0;
  bool _expanded = false, _loading = false, _unavailable = false;
  WorkspaceOrderDocumentsRead? _record, _latest;
  Object get _identity => (widget.gateway, widget.gateway.orderDocumentSource,
    widget.gateway.orderDocumentSource?.lifetime, widget.target.binding);
  late Object _owner = _identity;
  bool _current(int generation) {
    final source = widget.gateway.orderDocumentSource;
    return mounted && generation == _generation && _owner == _identity && widget.gateway.isCurrent &&
      widget.target.valid && widget.inputCurrent?.call() != false && (source == null ||
        source.isCurrent && source.lifetime != null && source.accountUserId == widget.gateway.accountUserId);
  }
  @override void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this);
    final read=widget.initialRead;
    if(read!=null&&read.validFor(widget.target)){_expanded=true;_record=read;_latest=read;}
    widget.gateway.orderDocumentSource?.addListener(_sourceChanged);
  }
  void _retire() {
    _generation++; _loading = false; _record = null; _unavailable = _expanded;
    _access.value++;
  }
  void _sourceChanged() {
    if (!mounted) return;
    setState(() { _retire(); if (_owner != _identity) { _owner = _identity; _latest = null; } });
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) setState(_retire);
  }
  @override void didUpdateWidget(covariant WorkspaceOrderDocumentsForOrder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.gateway.orderDocumentSource, widget.gateway.orderDocumentSource)) {
      oldWidget.gateway.orderDocumentSource?.removeListener(_sourceChanged);
      widget.gateway.orderDocumentSource?.addListener(_sourceChanged);
    }
    if (_owner != _identity || widget.inputCurrent?.call() == false) {
      _retire();
      if (_owner != _identity) { _owner = _identity; _latest = null; _expanded = false; }
    }
  }
  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.gateway.orderDocumentSource?.removeListener(_sourceChanged);
    _generation++; _access.dispose(); super.dispose();
  }
  Future<void> _read() async {
    final generation = _generation;
    if (!_current(generation) || !_expanded || _loading) return;
    setState(() { _loading = true; _unavailable = false; _record = null; });
    final result = await widget.gateway.readOrderDocuments(target: widget.target,
      inputCurrent: () => _current(generation) && _expanded);
    if (!_current(generation) || !_expanded) return;
    final previous = _latest;
    final accepted = result != null && (previous == null || result.revision > previous.revision ||
      result.revision == previous.revision && result.fingerprint == previous.fingerprint);
    setState(() { _loading = false; _unavailable = !accepted; _record = accepted ? result : null; if (accepted) _latest = result; });
  }
  void _open(WorkspaceOrderDocumentsRead record, WorkspaceOrderDocument document) {
    final generation = _generation;
    bool current() => _current(generation) && _expanded && identical(_record, record);
    if (!current() || document.copy == null) return;
    final gateway = widget.gateway, target = widget.target, copy = document.copy!;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WorkspaceOriginalCopyViewer(
      title: 'Order document', fileName: copy.fileName, contentType: copy.contentType,
      owner: _access, isCurrent: current,
      read: () async {
        if (!current()) throw StateError('Retired document');
        final bytes = await gateway.readOrderDocumentCopy(target: target, recorded: record,
          documentId: document.id, inputCurrent: current);
        if (bytes == null || !current()) throw StateError('Unavailable document');
        return bytes;
      })));
  }
  @override Widget build(BuildContext context) {
    final generation = _generation, record = _current(_generation) ? _record : null;
    final unavailable = !_current(_generation) || _unavailable;
    return PageStorage(bucket: _storage, child: ExpansionTile(key: ValueKey(_owner), initiallyExpanded:widget.initialRead!=null, tilePadding: EdgeInsets.zero,
      title: const Text('Order documents', style: TextStyle(fontSize: 13)),
      subtitle: const Text('View order details and linked copies.', style: TextStyle(fontSize: 12)),
      onExpansionChanged: (expanded) {
        if (!_current(generation)) return;
        _expanded = expanded;
        if (!expanded) _retire();
        final visit = _generation;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_current(visit)) return;
          setState(() {}); if (_expanded) unawaited(_read());
        });
      },
      children: [Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_loading && !unavailable) const LinearProgressIndicator(minHeight: 2),
        if (unavailable) ...[
          const Text('Documents for this order are unavailable.'),
          Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: _loading || !_current(generation) ? null : () {
            if (_current(generation) && _expanded) unawaited(_read());
          }, child: const Text('Retry documents'))),
        ],
        if (record != null && record.documents.isEmpty) const Text('No documents are linked to this order.'),
        if (record != null) for (final document in record.documents)
          ExpansionTile(key: ValueKey((record.fingerprint, document.id)), initiallyExpanded:widget.initialDocumentId==document.id, tilePadding: EdgeInsets.zero,
            title: Text(document.number, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text('${document.printedTitle ?? storeTradeDocumentLabel(document.kind)} · ${MaterialLocalizations.of(context).formatShortDate(document.date)}',
              style: const TextStyle(fontSize: 12)),
            children: [Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final field in WorkspaceOrderDocument.labels.entries)
                if (document.particulars[field.key] case final value?) Padding(padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${field.value}: $value')),
              if (const ['orderAmendment', 'orderCancellation'].contains(document.kind))
                _WorkspaceOrderChangeParticulars(document: document, record: record, onOpen: (previous) => _open(record, previous)),
              if (document.linkedDocumentIds.any((id) => id != document.changes?.previousDocumentId))
                Text('Linked documents: ${document.linkedDocumentIds.where((id) => id != document.changes?.previousDocumentId).map((id) => record.documents.singleWhere((doc) => doc.id == id).number).join(', ')}'),
              if (document.copy != null) Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                onPressed: () => _open(record, document), icon: const Icon(Icons.description_outlined, size: 18), label: const Text('View original')))
              else const Text('Original copy has not been supplied.'),
            ])]),
      ])]));
  }
}

class _WorkspaceOrderChangeParticulars extends StatelessWidget {
  const _WorkspaceOrderChangeParticulars({required this.document, required this.record, required this.onOpen});
  final WorkspaceOrderDocument document;
  final WorkspaceOrderDocumentsRead record;
  final ValueChanged<WorkspaceOrderDocument> onOpen;
  @override Widget build(BuildContext context) {
    final changes = document.changes;
    final previous = changes?.previousDocumentId == null ? null : record.documents.singleWhere((d) => d.id == changes!.previousDocumentId);
    final style = Theme.of(context).textTheme.bodySmall;
    String date(DateTime at) => MaterialLocalizations.of(context).formatShortDate(at.toLocal());
    String timestamp(DateTime at) => '${date(at)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(at.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
    Widget fact(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('$label: $value', style: style));
    Iterable<Widget> comparison(String? before, String? after) sync* {
      yield fact('Before', before ?? 'Not supplied');
      yield fact('In this document', after ?? 'Not supplied');
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(document.kind == 'orderCancellation' ? 'Cancellation particulars' : 'Amendment particulars',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('Current order status is shown separately.', style: TextStyle(fontSize: 12))),
      if (changes == null) Text('Change details have not been supplied.', style: style)
      else ...[
        if (previous != null) fact('Previous document', '${previous.number} · Revision ${previous.revision}')
        else Text('Previous document has not been linked.', style: style),
        if (changes.reason case final reason?) fact('Reason', reason),
        if (changes.effectiveAt case final at?) fact('Effective from', timestamp(at)),
        if (changes.recordedAt case final at?) fact('Recorded on', timestamp(at)),
        if (changes.recordedBy case final actor?) fact('Recorded by', actor),
        if (changes.outcome case final outcome?) fact('Document outcome', outcome),
        for (final term in changes.terms) ...[
          Text(term.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ...comparison(term.before, term.after),
        ],
        for (final line in changes.lines) ...[
          Text(line.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(WorkspaceOrderLineChange.actionLabels[line.action]!, style: style),
          ...comparison(line.before, line.after),
        ],
        if (changes.terms.isEmpty && changes.lines.isEmpty) Text('Affected items or terms have not been supplied.', style: style),
        if (previous != null && previous.copy != null) Align(alignment: Alignment.centerLeft, child: TextButton.icon(
          onPressed: () => onOpen(previous), icon: const Icon(Icons.history, size: 18), label: const Text('View previous original'))),
      ],
    ]);
  }
}

/// Local-byte viewer shared with receiving and purchase/payment copies. Its
/// caller supplies the original access check; no path/URL or upload is accepted.
class WorkspaceOriginalCopyViewer extends StatefulWidget {
  const WorkspaceOriginalCopyViewer({super.key, required this.title, required this.fileName,
    required this.contentType, required this.read, required this.isCurrent, required this.owner,
    this.unavailableText = 'Return to the order and refresh its documents.',
    this.errorText = 'This original could not be opened. Return to the order to refresh, or retry.',this.embedded=false});
  final String title, fileName, contentType, unavailableText, errorText;
  final Future<Uint8List> Function() read;
  final bool Function() isCurrent;
  final Listenable owner;
  final bool embedded;
  @override State<WorkspaceOriginalCopyViewer> createState() => _WorkspaceOriginalCopyViewerState();
}

class _WorkspaceOriginalCopyViewerState extends State<WorkspaceOriginalCopyViewer> {
  final _pdf = WorkPdfPreview();
  Uint8List? _bytes, _pageBytes;
  int _page = 0, _pages = 1, _generation = 0;
  bool _loading = true;
  String? _error;
  bool get _current => mounted && widget.isCurrent();
  void _changed() {
    if (!_current && mounted) { _generation++; setState(() { _bytes = null; _pageBytes = null; _loading = false; }); }
  }
  @override void initState() { super.initState(); widget.owner.addListener(_changed); unawaited(_load(0)); }
  @override void dispose() { widget.owner.removeListener(_changed); _generation++; _pdf.dispose(); super.dispose(); }
  Future<void> _load(int page) async {
    if (!_current) return;
    final visit = ++_generation;
    bool current() => _current && visit == _generation;
    setState(() { _loading = true; _error = null; _bytes = null; _pageBytes = null; });
    try {
      final bytes = await widget.read();
      if (!current()) return;
      if (widget.contentType == 'application/pdf') {
        final rendered = await _pdf.render(bytes, page: page);
        if (!current()) return;
        _pageBytes = rendered.bytes; _pages = rendered.pageCount; _page = page;
      }
      _bytes = bytes;
    } on Object { if (current()) _error = widget.errorText; }
    finally { if (current()) setState(() => _loading = false); }
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: widget.owner, builder: (context, _) => Scaffold(
    appBar: widget.embedded?null:AppBar(title: Text(widget.title)),
    body: !_current ? Center(child: Text(widget.unavailableText)) : Column(children: [
      Padding(padding: const EdgeInsets.all(8), child: Text(widget.fileName, maxLines: 2, overflow: TextOverflow.ellipsis)),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        Text(_error!), TextButton(onPressed: _loading ? null : () => _load(_page), child: const Text('Retry copy'))])),
      if (_bytes != null && _error == null) Expanded(child: InteractiveViewer(minScale: .5, maxScale: 8,
        child: Center(child: Image(image: ResizeImage(MemoryImage(_pageBytes ?? _bytes!), width: 1280, height: 2048, policy: ResizeImagePolicy.fit),
          fit: BoxFit.contain, errorBuilder: (_, _, _) => const Text('This copy could not be displayed.'))))),
      if (_bytes != null && _pages > 1) Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
        TextButton(onPressed: _loading || _page == 0 ? null : () => _load(_page - 1), child: const Text('Previous page')),
        Text('${_page + 1} / $_pages'),
        TextButton(onPressed: _loading || _page + 1 >= _pages ? null : () => _load(_page + 1), child: const Text('Next page')),
      ]),
    ])));
}

/// Read-only recorded warranty supplement. Collapse/replacement retires pending
/// reads; nothing is persisted into the immutable order or payment originals.
class WorkspaceOriginalWarrantyForLine extends StatefulWidget {
  const WorkspaceOriginalWarrantyForLine({super.key, required this.gateway, required this.role, required this.realm,
    required this.reference, required this.line, this.buyingStoreId, this.inputCurrent,this.initialRead});
  final AuthenticatedWorkspaceOrderIdentityGateway gateway;
  final WorkspaceOrderIdentityRole role;
  final String realm;
  final String? buyingStoreId;
  final WorkspacePurchaseReference reference;
  final WorkspacePurchasedSkuLine line;
  final bool Function()? inputCurrent;
  final WorkspacePurchasedWarrantyRead? initialRead;
  @override State<WorkspaceOriginalWarrantyForLine> createState() => _WorkspaceOriginalWarrantyForLineState();
}

class _WorkspaceOriginalWarrantyForLineState extends State<WorkspaceOriginalWarrantyForLine> {
  final _storage = PageStorageBucket();
  int _generation = 0;
  bool _expanded = false, _loading = false, _unavailable = false;
  WorkspacePurchasedWarrantyRead? _record, _latest;
  Object get _identity => (widget.gateway, widget.gateway.purchasedWarrantyReader, widget.gateway.purchasedWarrantyReader?.lifetime,
    WorkspacePurchasedWarrantyTarget(accountUserId: widget.gateway.accountUserId, role: widget.role, realm: widget.realm,
      buyingStoreId: widget.buyingStoreId, reference: widget.reference, line: widget.line).binding);
  late Object _owner = _identity;
  bool _current(int generation) {
    final reader = widget.gateway.purchasedWarrantyReader;
    return mounted && generation == _generation && _owner == _identity && widget.gateway.isCurrent &&
      (reader == null || reader.isCurrent && reader.lifetime != null && reader.accountUserId == widget.gateway.accountUserId) &&
      widget.inputCurrent?.call() != false;
  }
  @override void initState(){super.initState();final read=widget.initialRead;
    final target=WorkspacePurchasedWarrantyTarget(accountUserId:widget.gateway.accountUserId,role:widget.role,realm:widget.realm,
      reference:widget.reference,line:widget.line,buyingStoreId:widget.buyingStoreId);
    if(read!=null&&read.validFor(target)){_expanded=true;_record=read;_latest=read;}}
  @override void didUpdateWidget(covariant WorkspaceOriginalWarrantyForLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_owner != _identity) {
      _generation++; _owner = _identity; _expanded = false; _loading = false; _unavailable = false; _record = null; _latest = null;
    }
  }
  @override void dispose() { _generation++; super.dispose(); }
  Future<void> _read() async {
    final generation = _generation;
    if (!_current(generation) || !_expanded || _loading) return;
    setState(() { _loading = true; _unavailable = false; _record = null; });
    final result = await widget.gateway.readPurchasedWarranty(role: widget.role, realm: widget.realm,
      buyingStoreId: widget.buyingStoreId, reference: widget.reference, line: widget.line,
      inputCurrent: () => _current(generation) && _expanded);
    if (!_current(generation) || !_expanded) return;
    final previous = _latest;
    final accepted = result != null && (previous == null || result.revision > previous.revision ||
      result.revision == previous.revision && result.fingerprint == previous.fingerprint);
    setState(() {
      _loading = false; _unavailable = !accepted; _record = accepted ? result : null;
      if (accepted) _latest = result;
    });
  }
  @override Widget build(BuildContext context) {
    final generation = _generation, record = _current(_generation) ? _record : null;
    final unavailable = !_current(_generation) || _unavailable;
    final style = Theme.of(context).textTheme.bodySmall;
    String date(DateTime at) => MaterialLocalizations.of(context).formatFullDate(at.toLocal());
    return PageStorage(bucket: _storage, child: ExpansionTile(key: ValueKey(_owner), initiallyExpanded:widget.initialRead!=null, tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: const Text('Warranty details', style: TextStyle(fontSize: 13)),
      onExpansionChanged: (expanded) {
        if (!_current(generation)) return;
        _expanded = expanded;
        if (!expanded) { _generation++; _loading = false; _unavailable = false; _record = null; }
        final visit = _generation;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_current(visit)) return;
          setState(() {});
          if (_expanded) unawaited(_read());
        });
      },
      children: [Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_loading && !unavailable) const LinearProgressIndicator(minHeight: 2),
        if (unavailable) ...[
          const Text('Warranty details for this purchase are unavailable.'),
          Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () {
            if (_current(generation) && _expanded && !_loading && _unavailable) unawaited(_read());
          }, child: const Text('Retry warranty details'))),
        ],
        if (record != null) ...[
          Text('Recorded on ${date(record.recordedAt)}', style: style),
          if (record.terms == null) const Text('No detailed warranty terms were supplied for this purchase.')
          else ...[
            for (final entry in WorkspacePurchasedWarrantyTerms.labels.entries)
              if (record.terms!.fields[entry.key] case final value?) Text('${entry.value}: $value', style: style),
            if (record.terms!.startedAt case final started?) Text('Recorded warranty start: ${date(started)}', style: style),
            if (record.terms!.fields.containsKey('issuer') || record.terms!.fields.containsKey('contact') || record.terms!.fields.containsKey('service'))
              const Text('For warranty support, use the issuer or service contact in these terms.')
            else const Text('Warranty support contact was not supplied.'),
          ],
        ],
      ])]));
  }
}

/// Compact private order details, never an address/eligibility verification.
class WorkspaceOriginalFulfilmentForOrder extends StatelessWidget {
  const WorkspaceOriginalFulfilmentForOrder({super.key, required this.original});
  final WorkspacePurchaseOrder original;
  @override
  Widget build(BuildContext context) {
    final supplied = original.fulfilmentContext;
    if (supplied == null || supplied.recipient == null && supplied.address == null) return const SizedBox.shrink();
    final recipient = supplied.recipient, address = supplied.address;
    final addressLines = address == null ? <String>[] : [address.line, address.area, address.pinCode,
      if (address.landmark.isNotEmpty) 'Landmark: ${address.landmark}'].where((v) => v.isNotEmpty).toList();
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4);
    return Padding(key: ValueKey('original-fulfilment-${original.orderId}'), padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(supplied.method == 'collection' ? 'Order collection details' : 'Order delivery details',
          style: style?.copyWith(fontWeight: FontWeight.w600)),
        if (recipient != null && recipient.name.isNotEmpty) Text(recipient.name, style: style),
        if (recipient != null && recipient.phone.isNotEmpty) Text(recipient.phone, style: style),
        if (addressLines.isNotEmpty) Text(addressLines.join('\n'), style: style),
      ]));
  }
}

class WorkspaceOriginalInstructionsForLine extends StatelessWidget {
  const WorkspaceOriginalInstructionsForLine({super.key, required this.original, required this.lineId});
  final WorkspacePurchaseOrder original;
  final String lineId;
  @override
  Widget build(BuildContext context) {
    final note = original.fulfilmentContext?.instructions[lineId];
    return note == null ? const SizedBox.shrink() : Text('Instructions · $note',
      key: ValueKey('original-instructions-$lineId'), style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4));
  }
}

/// Only supplied original text; never supplement it from today's catalogue.
class WorkspaceOriginalVariantForLine extends StatelessWidget {
  const WorkspaceOriginalVariantForLine({super.key, required this.line});
  final WorkspacePurchasedSkuLine line;
  @override
  Widget build(BuildContext context) => line.variant == null || line.variant!.isEmpty
    ? const SizedBox.shrink()
    : Text(line.variant!, key: ValueKey('original-variant-${line.lineId}'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4));
}

/// Historical supplier statement only. Original charged totals stay separate.
class WorkspaceOriginalSupplierTaxForLine extends StatelessWidget {
  const WorkspaceOriginalSupplierTaxForLine({super.key, required this.line});
  final WorkspacePurchasedSkuLine line;
  @override
  Widget build(BuildContext context) {
    if (!line.hasSupplierTaxSnapshot) return const SizedBox.shrink();
    final snapshot = line.supplierTaxSnapshot;
    final gst = snapshot?.gst, amount = snapshot?.legacyAmount;
    final included = (gst?.basis ?? amount?.basis)?.name == 'included';
    final label = snapshot == null ? 'Supplier GST not recorded for this purchase'
      : '${gst != null ? 'Supplier-declared GST ${gst.percentageText}%' : 'Supplier-declared tax ${_money(amount!.amountMinor)} per selling pack'}'
        ' · ${included ? 'Included in' : 'Additional to'} the ordered price';
    return Text(label, key: ValueKey('original-supplier-gst-${line.lineId}'),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4));
  }
}

/// Frozen agreed price; current catalogue expiry cannot rewrite this purchase.
class WorkspaceOriginalCommodityPriceForLine extends StatelessWidget {
  const WorkspaceOriginalCommodityPriceForLine({super.key, required this.line});
  final WorkspacePurchasedSkuLine line;
  @override
  Widget build(BuildContext context) {
    final snapshot = line.commodityPriceSnapshot;
    if (snapshot == null) return const SizedBox.shrink();
    final local = MaterialLocalizations.of(context);
    String instant(DateTime value) {
      final date = value.toLocal();
      return '${local.formatMediumDate(date)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(date),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
    }
    return Text('Agreed supplier price ${_money(line.unitPriceMinor)} per selling pack · ${instant(snapshot.agreedAt)}\n'
      'Supplier confirmed ${instant(snapshot.confirmedAt)}', key: ValueKey('original-commodity-price-${line.lineId}'),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4));
  }
}

/// Historical desired selection only. No current availability or booking claim.
class WorkspaceOriginalScheduledForLine extends StatelessWidget {
  const WorkspaceOriginalScheduledForLine({super.key, required this.line});
  final WorkspacePurchasedSkuLine line;
  @override
  Widget build(BuildContext context) {
    final selected = line.scheduledFulfilment;
    if (!line.hasScheduledFulfilmentSnapshot || selected == null) return const SizedBox.shrink();
    final local = MaterialLocalizations.of(context);
    final start = selected.startsAt.toLocal(), end = selected.endsAt.toLocal();
    String time(DateTime value) => local.formatTimeOfDay(TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
    final window = '${local.formatFullDate(start)} · ${time(start)} – '
      '${DateUtils.isSameDay(start, end) ? '' : '${local.formatFullDate(end)} · '}${time(end)}';
    return Text('Requested Scheduled window · $window', key: ValueKey('original-scheduled-${line.lineId}'),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4));
  }
}

/// Same immutable breakdown on buyer originals and Store operational details.
/// No raw funding references, inferred savings, cashback success or new actions.
class WorkspaceOriginalBenefitsForLine extends StatelessWidget {
  const WorkspaceOriginalBenefitsForLine({super.key, required this.original, required this.lineId});
  final WorkspacePurchaseOrder original;
  final String lineId;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    for (final component in original.benefitAttribution?.components ?? const <WorkspaceOriginalBenefitComponent>[])
      if (component.allocations[lineId] case final amount?)
        Padding(key: ValueKey('original-benefit-$lineId-${component.componentId}'),
          padding: const EdgeInsets.only(top: 4), child: Text(component.isCashbackOffer
            ? '${component.label} · ${component.amountBasis == 'maximum' ? 'Up to' : 'Quoted'} ${_money(amount)} cashback · confirmation pending'
            : '${component.label} · Discount ${_money(amount)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4))),
  ]);
}

String _quantity(int milli) {
  final fraction = (milli % 1000)
      .toString()
      .padLeft(3, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return '${milli ~/ 1000}${fraction.isEmpty ? '' : '.$fraction'}';
}

String _money(int minor) {
  final digits = (minor ~/ 100).toString();
  final tail = digits.length > 3 ? digits.substring(digits.length - 3) : digits;
  var head = digits.length > 3 ? digits.substring(0, digits.length - 3) : '';
  final groups = <String>[tail];
  while (head.isNotEmpty) {
    final length = head.length > 2 ? 2 : head.length;
    groups.insert(0, head.substring(head.length - length));
    head = head.substring(0, head.length - length);
  }
  return '₹${groups.join(',')}.${(minor % 100).toString().padLeft(2, '0')}';
}

/// Frozen original read selected from an authenticated native purchase index.
/// It is not a model-supplied reference, recipient or access grant.
class WorkspaceOriginalAssistantTarget {
  const WorkspaceOriginalAssistantTarget({required this.gateway,required this.role,required this.realm,
    required this.reference,this.lineId,this.buyingStoreId,this.onOpenCase,this.draftStore});
  final AuthenticatedWorkspaceOrderIdentityGateway gateway;
  final WorkspaceOrderIdentityRole role;
  final String realm;
  final WorkspacePurchaseReference reference;
  final String? lineId,buyingStoreId;
  final Future<bool> Function(WorkspaceDeviceCaseHandoff)? onOpenCase;
  final WorkPurchasedUnitDraftStore? draftStore;
  String get entityId=>lineId==null?reference.orderId:jsonEncode([reference.orderId,lineId]);
  String get binding=>WorkspaceOrderDocumentTarget(accountUserId:gateway.accountUserId,role:role,
    realm:realm,reference:reference,buyingStoreId:buyingStoreId).binding;
}

/// Exact current original references retained by mounted native index owners.
/// This is a read projection, never a substitute provider or mutable cache.
final _assistantOriginalIndices=<_WorkspacePurchaseOriginalsState>{};
WorkspacePurchaseReference? workspaceAssistantOriginalReference({required AuthenticatedWorkspaceOrderIdentityGateway gateway,
    required WorkspaceOrderIdentityRole role,required String realm,required String storeId,required String orderId}){
  final refs=<WorkspacePurchaseReference>[];
  for(final owner in _assistantOriginalIndices){
    final w=owner.widget;
    if(!owner._current(owner._generation)||!identical(w.gateway,gateway)||w.role!=role||w.realm!=realm||
       (role==WorkspaceOrderIdentityRole.seller?w.storeId!=storeId:w.buyingStoreId!=storeId))continue;
    refs.addAll(owner._references.where((r)=>r.orderId==orderId));
  }
  if(refs.isEmpty)return null;
  final first=refs.first;
  return refs.every((r)=>jsonEncode(r.toJson())==jsonEncode(first.toJson()))?first:null;
}

class WorkspaceOrderOriginalNativeAdapter implements MoolAssistantOwnerAwareNativeAdapter,
    MoolAssistantRouteBoundNativeAdapter {
  WorkspaceOrderOriginalNativeAdapter({required this.actionId,required this.navigator,required this.currentContext,
    required this.currentOwner,required this.ownerChanges,required this.resolve});
  @override final String actionId;
  final NavigatorState navigator;
  final MoolAssistantContext? Function() currentContext;
  final bool Function() currentOwner;
  final Listenable ownerChanges;
  final WorkspaceOriginalAssistantTarget? Function(String) resolve;
  Route<void>? _assistantRoute;NavigatorState? _assistantNavigator;
  WorkspaceOriginalAssistantTarget? _target;
  WorkspacePurchaseOrder? _original;
  WorkspacePurchasedSkuLine? _line;
  WorkspaceOrderDocumentsRead? _documents;
  WorkspacePurchasedWarrantyRead? _warranty;
  WorkspacePurchasedUnitsRead? _units;
  WorkspaceReceivedDeviceReports? _reports;
  WorkspacePurchasedUnitDraft? _draft;
  WorkPurchasedUnitDraftStore? _draftStore;
  Object? _binding,_witness;int _revision=0;bool _opened=false;
  @override void bindAssistantRoute(Route<void> route,NavigatorState owner){
    if(_assistantRoute!=null||!identical(owner,navigator))throw StateError('Original owner route changed');
    _assistantRoute=route;_assistantNavigator=owner;
  }
  bool get _assistantCurrent=>_assistantRoute?.isCurrent==true&&_assistantRoute?.isActive==true&&
      identical(_assistantRoute?.navigator,_assistantNavigator);
  bool _scope(Object binding)=>navigator.mounted&&currentOwner()&&currentContext()?.binding==binding&&
      currentContext()?.inWorkspace==true&&currentContext()?.storeWorkspace==true&&currentContext()?.workspaceApproved==true;
  bool _targetCurrent(WorkspaceOriginalAssistantTarget t,Object binding){
    final ctx=currentContext(),again=resolve(t.entityId);
    return _scope(binding)&&ctx?.workspaceId!=null&&t.gateway.isCurrent&&again!=null&&
      identical(again.gateway,t.gateway)&&again.binding==t.binding&&again.lineId==t.lineId&&
      (t.role==WorkspaceOrderIdentityRole.seller?t.reference.storeId==ctx!.workspaceId:
        t.buyingStoreId==ctx!.workspaceId)&&t.reference.valid;
  }
  static const supported=['AI-ACT-274','AI-ACT-389','AI-ACT-390','AI-ACT-391','AI-ACT-392','AI-ACT-393',
    'AI-ACT-394','AI-ACT-395','AI-ACT-396','AI-ACT-397','AI-ACT-398','AI-ACT-399','AI-ACT-400'];
  @override Set<String> get allowedFields=>switch(actionId){
    'AI-ACT-390'||'AI-ACT-391'=>const {'documentId','documentRevision'},
    'AI-ACT-394'=>const {'rows'},'AI-ACT-396'=>const {'selectedIds','note'},
    'AI-ACT-400'=>const {'reportId'},_=>const {},};
  @override String? validateFields(Map<String,Object?> fields){
    if(fields.keys.any((key)=>!allowedFields.contains(key)))return 'Some original details are not supported.';
    if(actionId=='AI-ACT-390'||actionId=='AI-ACT-391'){
      if(fields['documentId'] is! String||(fields['documentId'] as String).trim().isEmpty||
         fields['documentRevision'] is! int||(fields['documentRevision'] as int)<=0)return 'Choose the exact original document and revision.';
    }
    if(actionId=='AI-ACT-400'&&(fields['reportId'] is! String||(fields['reportId'] as String).trim().isEmpty))return 'Choose the linked device report.';
    if(actionId=='AI-ACT-394'){
      final rows=fields['rows'];if(rows is! List||rows.isEmpty||rows.length>1000)return 'Add the printed device identifiers.';
      for(final row in rows){if(row is! Map||row.isEmpty||row.keys.any((k)=>!const {'id','serial','imei1','imei2'}.contains(k))||
        row.values.any((v)=>v is! String)||!WorkspacePurchasedUnitRow(id:row['id'] as String? ?? 'device-review',
          serial:row['serial'] as String? ?? '',imei1:row['imei1'] as String? ?? '',imei2:row['imei2'] as String? ?? '').validDraft)
        return 'Check the original serial and IMEI text.';}
    }
    if(actionId=='AI-ACT-396'){
      final ids=fields['selectedIds'];if(ids is! List||ids.isEmpty||ids.any((id)=>id is! String)||ids.toSet().length!=ids.length||fields['note'] is! String)
        return 'Select the affected devices and describe the mismatch.';
    }
    return null;
  }
  List<Object?> _sourceWitness(WorkspaceOriginalAssistantTarget t)=>[
    t.gateway,t.gateway.lifetime(),t.gateway.orderDocumentSource,t.gateway.orderDocumentSource?.lifetime,t.gateway.orderDocumentSource?.isCurrent,
    t.gateway.purchasedWarrantyReader,t.gateway.purchasedWarrantyReader?.lifetime,t.gateway.purchasedWarrantyReader?.isCurrent,
    t.gateway.purchasedUnitSource,t.gateway.purchasedUnitSource?.lifetime,t.gateway.purchasedUnitSource?.isCurrent,t.binding,t.lineId,
    _original?.originalFingerprint,_documents?.fingerprint,_warranty?.fingerprint,_units?.fingerprint,
    _units?.ownerAccess?.expiresAt,_units?.reportAccess?.expiresAt,
    _reports==null?null:_reportsWitness(_reports!),
    _draft==null?null:jsonEncode(_draft!.toJson()),
  ];
  String _reportsWitness(WorkspaceReceivedDeviceReports reports,{bool includeAccess=true})=>jsonEncode([reports.revision,includeAccess?reports.ownerAccess.expiresAt.toUtc().toIso8601String():null,
    reports.reports.map((r)=>[r.id,r.fingerprint,if(r.supportCase case final issue?)[issue.id,issue.revision,
      issue.updatedAt.toUtc().toIso8601String(),issue.state.name,issue.reason,issue.nextStep,issue.resolution,
      issue.permittedResponses.map((r)=>r.name).toList(),issue.purchaseContext?.fingerprint]]).toList(),reports.complete,reports.nextCursor]);
  @override Future<MoolAssistantNativeSnapshot?> snapshot(MoolAssistantContext context,String? entityId)async{
    if(!supported.contains(actionId)||_opened||entityId==null||!_scope(context.binding)||!_assistantCurrent)return null;
    final t=resolve(entityId);if(t==null||!_targetCurrent(t,context.binding))return null;
    final buyer=const {'AI-ACT-396','AI-ACT-399'}.contains(actionId);
    if((t.role==WorkspaceOrderIdentityRole.buyer)!=buyer||
       (const {'AI-ACT-274','AI-ACT-389','AI-ACT-390','AI-ACT-391'}.contains(actionId)?t.lineId!=null:t.lineId==null))return null;
    bool current()=>_assistantCurrent&&_targetCurrent(t,context.binding)&&!_opened;
    final original=await t.gateway.readReferencedOrder(role:t.role,realm:t.realm,reference:t.reference,buyingStoreId:t.buyingStoreId,inputCurrent:current);
    if(!current()||original==null)return null;
    WorkspacePurchasedSkuLine? line;
    if(t.lineId!=null){final matches=original.lines.where((v)=>v.lineId==t.lineId);if(matches.length!=1)return null;line=matches.single;}
    WorkspaceOrderDocumentsRead? documents;WorkspacePurchasedWarrantyRead? warranty;WorkspacePurchasedUnitsRead? units;
    WorkspaceReceivedDeviceReports? reports;WorkspacePurchasedUnitDraft? draft;WorkPurchasedUnitDraftStore? draftStore;
    if(const {'AI-ACT-389','AI-ACT-390','AI-ACT-391'}.contains(actionId)){
      documents=await t.gateway.readOrderDocuments(target:WorkspaceOrderDocumentTarget(accountUserId:t.gateway.accountUserId,
        role:t.role,realm:t.realm,reference:t.reference,buyingStoreId:t.buyingStoreId),inputCurrent:current);
      if(!current()||documents==null)return null;
    }
    if(actionId=='AI-ACT-392'){
      warranty=await t.gateway.readPurchasedWarranty(role:t.role,realm:t.realm,reference:t.reference,line:line!,buyingStoreId:t.buyingStoreId,inputCurrent:current);
      if(!current()||warranty==null)return null;
    }
    if(const {'AI-ACT-393','AI-ACT-394','AI-ACT-395','AI-ACT-396','AI-ACT-397','AI-ACT-398','AI-ACT-399','AI-ACT-400'}.contains(actionId)){
      units=await t.gateway.readPurchasedUnits(role:t.role,realm:t.realm,reference:t.reference,line:line!,buyingStoreId:t.buyingStoreId,inputCurrent:current);
      if(!current()||units==null)return null;
    }
    if(actionId=='AI-ACT-397'||actionId=='AI-ACT-400'){
      reports=await t.gateway.readReceivedDeviceReports(realm:t.realm,reference:t.reference,line:line!,inputCurrent:current);
      if(!current()||reports==null)return null;
    }
    if(const {'AI-ACT-394','AI-ACT-395','AI-ACT-396','AI-ACT-398','AI-ACT-399'}.contains(actionId)){
      final source=t.gateway.purchasedUnitSource!,key=WorkspacePurchasedUnitDraftKey(account:t.gateway.accountUserId,realm:t.realm,
        store:t.reference.storeId,binding:units!.target.binding),read=units;
      bool authorised()=>t.gateway.isCurrent&&source.isCurrent&&source.lifetime!=null&&source.accountUserId==t.gateway.accountUserId&&
        _deviceDraftAccess(source,read.target,read.ownerAccess,read.reportAccess);
      if(!units.complete||!authorised())return null;
      if(const {'AI-ACT-395','AI-ACT-398'}.contains(actionId)&&source is! WorkspacePurchasedUnitPublisher)return null;
      draftStore=t.draftStore??SecureWorkPurchasedUnitDraftStore(accountScope:()=>authorised()?t.gateway.accountUserId:null,
        targetScope:()=>authorised()?key.identity:null);
      draft=await draftStore.read(key);
      if(!current()||!authorised()||draft!=null&&(!draft.valid||draft.key.identity!=key.identity||
        (t.role==WorkspaceOrderIdentityRole.buyer)!=(draft.report!=null)))return null;
      if((actionId=='AI-ACT-395'&&(draft==null||draft.pending!=null||draft.publishedRevision!=units.revision||!draft.rows.every((r)=>r.ready)))||
        (actionId=='AI-ACT-398'&&draft?.pending==null)||(actionId=='AI-ACT-399'&&draft?.report?.pending==null)||
        (const {'AI-ACT-394','AI-ACT-396'}.contains(actionId)&&(draft?.pending!=null||draft?.report?.pending!=null||draft?.report?.recorded==true)))return null;
    }
    if(_target?.binding==t.binding&&_target?.lineId==t.lineId&&identical(_target?.gateway,t.gateway)){
      if(documents!=null&&_documents!=null&&(documents.revision<_documents!.revision||documents.revision==_documents!.revision&&documents.fingerprint!=_documents!.fingerprint)||
         warranty!=null&&_warranty!=null&&(warranty.revision<_warranty!.revision||warranty.revision==_warranty!.revision&&warranty.fingerprint!=_warranty!.fingerprint)||
         units!=null&&_units!=null&&(units.revision<_units!.revision||units.revision==_units!.revision&&units.fingerprint!=_units!.fingerprint)||
         reports!=null&&_reports!=null&&(reports.revision<_reports!.revision||reports.revision==_reports!.revision&&_reportsWitness(reports,includeAccess:false)!=_reportsWitness(_reports!,includeAccess:false))||
         _draft!=null&&(draft==null||draft.revision<_draft!.revision||draft.revision==_draft!.revision&&jsonEncode(draft.toJson())!=jsonEncode(_draft!.toJson())))return null;
    }
    _original=original;_line=line;_documents=documents;_warranty=warranty;_units=units;_reports=reports;_draft=draft;_draftStore=draftStore;
    final witness=_sourceWitness(t);if(_binding!=context.binding||_target?.entityId!=t.entityId||!listEquals(_witness as List<Object?>?,witness)){
      _binding=context.binding;_target=t;_witness=List<Object?>.unmodifiable(witness);_revision++;
    }
    return MoolAssistantNativeSnapshot(binding:context.binding,sourceRevision:'original-native:$actionId:$_revision',permitted:true,entityId:entityId);
  }
  @override Future<MoolAssistantReviewResult> openReview(MoolAssistantProposal p,bool Function() current)=>
    openOwnedReview(p,isCurrent:current,ownerChanges:ownerChanges);
  @override Future<MoolAssistantReviewResult> openOwnedReview(MoolAssistantProposal p,
      {required bool Function() isCurrent,required Listenable ownerChanges})async{
    final t=_target,original=_original;
    if(t==null||original==null||_opened||!_assistantCurrent||!isCurrent()||validateFields(p.fields)!=null||p.actionId!=actionId||
      p.sourceRevision!='original-native:$actionId:$_revision'||p.entityId!=t.entityId||!_targetCurrent(t,p.binding)||
      !p.validUntil.isAfter(DateTime.now()))return MoolAssistantReviewResult.stale;
    WorkspaceOrderDocument? document;
    if(actionId=='AI-ACT-390'||actionId=='AI-ACT-391'){
      final matches=_documents!.documents.where((d)=>d.id==p.fields['documentId']&&d.revision==p.fields['documentRevision']);
      if(matches.length!=1)return MoolAssistantReviewResult.unavailable;document=matches.single;
      if(actionId=='AI-ACT-390'&&document.copy==null||actionId=='AI-ACT-391'&&!const {'orderAmendment','orderCancellation'}.contains(document.kind))return MoolAssistantReviewResult.unavailable;
    }
    if(actionId=='AI-ACT-400'&&!_reports!.reports.any((r)=>r.id==p.fields['reportId']&&r.supportCase!=null))return MoolAssistantReviewResult.unavailable;
    if(actionId=='AI-ACT-400'&&t.onOpenCase==null)return MoolAssistantReviewResult.unavailable;
    if(actionId=='AI-ACT-394'){
      final baseline=_draft?.rows??_units!.rows;
      final rows=p.fields['rows'] as List;
      if(baseline.length+rows.where((value)=>(value as Map)['id']==null).length>1000)return MoolAssistantReviewResult.unavailable;
      final allowed=baseline.map((row)=>row.id).toSet(),ids=<String>{};
      for(final row in p.fields['rows'] as List){final id=(row as Map)['id'];
        if(id!=null&&(!allowed.contains(id)||!ids.add(id as String)))return MoolAssistantReviewResult.unavailable;}
    }
    if(actionId=='AI-ACT-396'){
      final report=WorkspacePurchasedUnitMismatchDraft(sourceFingerprint:_units!.fingerprint,
        note:p.fields['note'] as String,selected:(p.fields['selectedIds'] as List).cast<String>());
      final key=WorkspacePurchasedUnitDraftKey(account:t.gateway.accountUserId,realm:t.realm,store:t.reference.storeId,binding:_units!.target.binding);
      if(!report.validFor(key,_units!.revision,_units!.rows))return MoolAssistantReviewResult.unavailable;
    }
    final changes=ValueNotifier<int>(0);bool sourceRetired=false;
    void sourceChanged(){sourceRetired=true;changes.value++;}
    t.gateway.orderDocumentSource?.addListener(sourceChanged);t.gateway.purchasedUnitSource?.addListener(sourceChanged);
    final deadlines=[p.validUntil,if(_units?.ownerAccess case final grant?)grant.expiresAt,
      if(_units?.reportAccess case final grant?)grant.expiresAt,if(_reports case final reports?)reports.ownerAccess.expiresAt]..sort();
    final deadline=deadlines.first;
    bool current()=>!sourceRetired&&isCurrent()&&deadline.isAfter(DateTime.now())&&_targetCurrent(t,p.binding)&&
      listEquals(_witness as List<Object?>?,_sourceWitness(t));
    _opened=true;
    try{
      if(!current())return MoolAssistantReviewResult.stale;
      await navigator.push<void>(MaterialPageRoute(builder:(_)=>_WorkspaceOriginalNativeReview(
        title:p.title,current:current,changes:Listenable.merge([ownerChanges,this.ownerChanges,changes]),validUntil:deadline,scrollBody:actionId!='AI-ACT-390',
        body:(capturedCurrent)=>_originalBody(t,original,document,p,capturedCurrent,changes))));
      return current()?MoolAssistantReviewResult.opened:MoolAssistantReviewResult.stale;
    }finally{
      _opened=false;t.gateway.orderDocumentSource?.removeListener(sourceChanged);t.gateway.purchasedUnitSource?.removeListener(sourceChanged);changes.dispose();
    }
  }
  Widget _originalBody(WorkspaceOriginalAssistantTarget t,WorkspacePurchaseOrder original,WorkspaceOrderDocument? document,
      MoolAssistantProposal p,bool Function() current,Listenable changes){
    final target=WorkspaceOrderDocumentTarget(accountUserId:t.gateway.accountUserId,role:t.role,realm:t.realm,reference:t.reference,buyingStoreId:t.buyingStoreId);
    if(actionId=='AI-ACT-274')return WorkspacePurchaseOriginals(gateway:t.gateway,role:t.role,realm:t.realm,
      storeId:t.role==WorkspaceOrderIdentityRole.seller?t.reference.storeId:null,buyingStoreId:t.buyingStoreId,
      capturedCurrent:current,initialRead:(reference:t.reference,original:original));
    if(actionId=='AI-ACT-389'||actionId=='AI-ACT-391')return WorkspaceOrderDocumentsForOrder(gateway:t.gateway,target:target,
      inputCurrent:current,initialRead:_documents,initialDocumentId:document?.id);
    if(actionId=='AI-ACT-390')return WorkspaceOriginalCopyViewer(title:'Order document',fileName:document!.copy!.fileName,
      contentType:document.copy!.contentType,owner:changes,isCurrent:current,embedded:true,read:()async{
        if(!current())throw StateError('Original document retired');
        final bytes=await t.gateway.readOrderDocumentCopy(target:target,recorded:_documents!,documentId:document.id,inputCurrent:current);
        if(!current()||bytes==null)throw StateError('Original document unavailable');return bytes;
      });
    if(actionId=='AI-ACT-392')return WorkspaceOriginalWarrantyForLine(gateway:t.gateway,role:t.role,realm:t.realm,
      reference:t.reference,line:_line!,buyingStoreId:t.buyingStoreId,inputCurrent:current,initialRead:_warranty);
    if(actionId=='AI-ACT-397'||actionId=='AI-ACT-400')return WorkspaceReceivedDeviceReportPanel(gateway:t.gateway,
      realm:t.realm,reference:t.reference,line:_line!,inputCurrent:current,onOpenCase:t.onOpenCase,
      initialRead:_reports,initialReportId:p.fields['reportId'] as String?);
    return WorkspacePurchasedUnitsForLine(gateway:t.gateway,role:t.role,realm:t.realm,reference:t.reference,line:_line!,
      buyingStoreId:t.buyingStoreId,inputCurrent:current,draftStore:_draftStore,
      initialRead:WorkspaceUnitAssistantRead(record:_units!,draft:_draft,actionId:actionId,fields:p.fields));
  }
}

class _WorkspaceOriginalNativeReview extends StatefulWidget{
  const _WorkspaceOriginalNativeReview({required this.title,required this.current,required this.changes,required this.validUntil,required this.body,this.scrollBody=true});
  final String title;final bool Function() current;final Listenable changes;final DateTime validUntil;
  final Widget Function(bool Function()) body;
  final bool scrollBody;
  @override State<_WorkspaceOriginalNativeReview> createState()=>_WorkspaceOriginalNativeReviewState();
}
class _WorkspaceOriginalNativeReviewState extends State<_WorkspaceOriginalNativeReview>{
  Route<dynamic>? _route;Timer? _expiry;bool _retired=false,_closing=false;
  bool get _current=>mounted&&!_retired&&!_closing&&widget.current()&&_route?.isCurrent==true;
  @override void initState(){super.initState();widget.changes.addListener(_changed);
    final duration=widget.validUntil.difference(DateTime.now());_expiry=Timer(duration.isNegative?Duration.zero:duration,_retire);}
  @override void didChangeDependencies(){super.didChangeDependencies();_route??=ModalRoute.of(context);}
  void _changed(){if(!mounted||_closing)return;if(!widget.current())_retire();else setState((){});}
  void _retire(){if(!mounted||_retired||_closing)return;_retired=true;WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)_close();});WidgetsBinding.instance.ensureVisualUpdate();}
  void _close(){if(!mounted||_closing)return;_closing=true;final route=_route;if(route?.isActive!=true)return;
    if(route!.isCurrent)Navigator.of(context).pop();else Navigator.of(context).removeRoute(route);}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.title,maxLines:1,overflow:TextOverflow.ellipsis),leading:BackButton(onPressed:_close)),
    body:!widget.current()||_retired?const SizedBox.shrink():Navigator(onGenerateRoute:(_)=>MaterialPageRoute<void>(builder:(_)=>
      widget.scrollBody?SingleChildScrollView(padding:const EdgeInsets.all(12),child:widget.body(()=>_current)):widget.body(()=>_current))));
  @override void dispose(){_expiry?.cancel();widget.changes.removeListener(_changed);super.dispose();}
}

@immutable
class WorkspaceUnitAssistantRead{
  WorkspaceUnitAssistantRead({required this.record,required this.draft,required this.actionId,required Map<String,Object?> fields}):fields=Map.unmodifiable(fields);
  final WorkspacePurchasedUnitsRead record;final WorkspacePurchasedUnitDraft? draft;
  final String actionId;final Map<String,Object?> fields;
}
