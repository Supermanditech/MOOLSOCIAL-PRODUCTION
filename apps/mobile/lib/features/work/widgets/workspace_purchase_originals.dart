import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../work_order_identity_gateway.dart';
import '../work_catalogue_gateway.dart';

/// Shared quotation surface, deliberately separate from purchased orders.
class WorkspaceBulkQuotes extends StatefulWidget {
  const WorkspaceBulkQuotes({super.key, required this.access, this.storeId, this.onClose,
    this.request, this.requestLines = const [], this.inputCurrent});
  final WorkspaceBulkQuoteAccess access;
  final String? storeId;
  final VoidCallback? onClose;
  final WorkspaceBulkQuoteIntent? request;
  final List<({String name, String pack, String? variant, int quantity})> requestLines;
  final bool Function()? inputCurrent;
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
  bool _current(int generation) => mounted && generation == _generation && access.active;
  WorkspaceBulkQuoteController? get controller => _store == null || !access.active ? null : access.forStore(_store!);
  @override void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this); _selectRequest();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) unawaited(_load()); });
  }
  void _selectRequest() { _detailVisit = Object(); _store = widget.request?.storeId; _quoteId = widget.request?.quoteId; }
  @override void didUpdateWidget(covariant WorkspaceBulkQuotes old) {
    super.didUpdateWidget(old);
    if (!identical(old.access, access) || old.storeId != widget.storeId || old.request?.fingerprint != widget.request?.fingerprint) {
      _generation++; _expiry?.cancel(); _rows.clear(); _pending.clear(); _cursor = null; _termsAccepted = false; _selectRequest();
      _loading = false; _acting = false; _sending = false; _error = null;
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) unawaited(_load()); });
    }
  }
  @override void dispose() { _generation++; _expiry?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && access.active) {
      setState(() {}); if (_quoteId != null) unawaited(_refresh());
    }
  }
  void _armExpiry() {
    _expiry?.cancel(); final quote = controller?.head(_quoteId ?? ''), generation = _generation;
    if (quote?.state != 'offered') return;
    final delay = quote!.validUntil!.difference(access.gateway.gateway.now().toUtc());
    if (delay.isNegative) return;
    _expiry = Timer(delay, () { if (_current(generation)) setState(() { _termsAccepted = false; }); });
  }
  Future<void> _load({bool more = false}) async {
    if (_loading || !access.active) return;
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
    setState(() { _detailVisit = Object(); _store = store; _quoteId = id; _termsAccepted = false; _error = null; }); await _refresh();
  }
  Future<bool> _confirm(String title, String body) async => await showDialog<bool>(context: context,
    builder: (dialog) => AlertDialog(title: Text(title), content: Text(body), scrollable: true,
      actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Not now')),
        FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Confirm'))])) == true;
  WorkspaceBulkQuoteIntent _command(WorkspaceBulkQuote quote, String kind, {Map<String, dynamic> fields = const {}}) {
    final key = '$kind-${List.generate(16, (_) => math.Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    return WorkspaceBulkQuoteIntent.decode({'schemaVersion': 1, 'account': access.account, 'realm': access.realm, 'kind': kind,
      'body': {'schemaVersion': 1, 'quoteId': quote.quoteId, 'operationId': key, 'expectedRevision': quote.revision, ...fields},
      'base': quote.toJson(), 'expected': [for (final line in quote.lines) line.identity]},
      account: access.account, realm: access.realm, now: access.gateway.gateway.now());
  }
  Future<void> _act(String kind, {required Object visit, WorkspaceBulkQuoteIntent? original, WorkspaceBulkQuote? quote}) async {
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
    final owner = controller!, quote = owner.head(_quoteId!), request = widget.request;
    final visit = _detailVisit;
    final pending = owner.pending.where((p) => p.quoteId == _quoteId).toList();
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
      if (mustReadTerms && quote?.offerCurrent(access.gateway.gateway.now()) == true && access.role == 'buyer' && pending.isEmpty)
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: _termsAccepted, onChanged: _acting ? null : (v) => setState(() { _termsAccepted = v == true; }),
          title: const Text('I have read the supplier terms shown above.')),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
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
    return Material(type: MaterialType.transparency, child: ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [if (_quoteId != null || widget.onClose != null) IconButton(tooltip: widget.request != null ? 'Back to Cart' : _quoteId != null ? 'All Bulk quotes' : 'Back to orders',
        onPressed: _acting ? null : () { if (_quoteId != null && widget.request == null) { setState(() { _quoteId = null; _store = null; }); unawaited(_load()); }
          else { widget.onClose?.call(); } }, icon: const Icon(Icons.arrow_back_rounded)),
        const Expanded(child: Text('Bulk quotes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
        IconButton(tooltip: 'Refresh quotes', onPressed: _loading || _acting ? null : () => _quoteId == null ? _load() : _refresh(), icon: const Icon(Icons.refresh_rounded))]),
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
    this.onRatePurchasedItem,
  });
  final AuthenticatedWorkspaceOrderIdentityGateway gateway;
  final WorkspaceOrderIdentityRole role;
  final String realm;
  final String? storeId;
  /// Buyer-only entry after authoritative completion, scoped to one frozen line.
  final void Function(WorkspacePurchaseReference, WorkspacePurchaseOrder, WorkspacePurchasedSkuLine)? onRatePurchasedItem;
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
      mounted && generation == _generation && widget.gateway.isCurrent;
  @override
  void didUpdateWidget(covariant WorkspacePurchaseOriginals oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.gateway, widget.gateway) ||
        oldWidget.role != widget.role ||
        oldWidget.realm != widget.realm ||
        oldWidget.storeId != widget.storeId) {
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
    if (!widget.gateway.isCurrent) return;
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
    if (_pending.contains(reference.orderId) ||
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
    _generation++;
    super.dispose();
  }

  Future<void> _checkUpdate(WorkspacePurchaseReference reference) async {
    if (!widget.gateway.isCurrent ||
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
            onPressed: loading ? null : () => _checkUpdate(reference),
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
    if (!widget.gateway.isCurrent) return const SizedBox.shrink();
    return Material(
      type: MaterialType.transparency,
      child: ExpansionTile(
        key: PageStorageKey((
          widget.gateway,
          widget.role,
          widget.realm,
          widget.storeId,
        )),
        tilePadding: EdgeInsets.zero,
        title: const Text(
          'Saved purchase details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        onExpansionChanged: (expanded) {
          final generation = _generation;
          if (expanded && !_loaded) {
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
                          : () => _load(more: _retryMore),
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
                    key: PageStorageKey((
                      widget.gateway,
                      widget.role,
                      widget.realm,
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
                      final generation = _generation;
                      if (expanded) {
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
                          onPressed: () => _open(reference),
                          child: const Text('Details unavailable · retry'),
                        ),
                      if (_details[reference.orderId] case final details?) ...[
                        _orderUpdate(reference),
                        WorkspaceOriginalFulfilmentForOrder(original: details),
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
                                WorkspaceOriginalScheduledForLine(line: line),
                                WorkspaceOriginalInstructionsForLine(original: details, lineId: line.lineId),
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
                  onPressed: () => _load(more: true),
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
