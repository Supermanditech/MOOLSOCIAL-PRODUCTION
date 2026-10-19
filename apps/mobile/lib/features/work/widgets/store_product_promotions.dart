import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../work_catalogue_gateway.dart';
import '../work_models.dart';
import '../work_product_promotions.dart';
import '../work_session.dart';
import '../../buy/buy_v2_content_contracts.dart' show BuyV2AdvertisedBenefitTerms;

/// Explicit public promotion, never a conversion of the private targeted draft.
class StoreProductPromotionPanel extends StatelessWidget {
  const StoreProductPromotionPanel({
    required this.session,
    this.now,
    super.key,
  });
  final WorkSession session;
  final DateTime Function()? now;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) {
      final owner = session.workspaceProductPromotions;
      if (owner == null) return const SizedBox.shrink();
      return _PromotionEditor(
        key: ObjectKey(owner),
        session: session,
        owner: owner,
        now: now ?? DateTime.now,
      );
    },
  );
}

class _PromotionEditor extends StatefulWidget {
  const _PromotionEditor({
    required this.session,
    required this.owner,
    required this.now,
    super.key,
  });
  final WorkSession session;
  final StorePromotionController owner;
  final DateTime Function() now;
  @override
  State<_PromotionEditor> createState() => _PromotionEditorState();
}

class _PromotionEditorState extends State<_PromotionEditor> {
  final _headline = TextEditingController(), _detail = TextEditingController();
  final _benefitAmount = TextEditingController(), _benefitCap = TextEditingController(),
    _benefitSpend = TextEditingController(), _benefitQuantity = TextEditingController();
  String? _benefitKind, _flatBasis;
  final _headlineScroll = ScrollController(keepScrollOffset: false),
      _detailScroll = ScrollController(keepScrollOffset: false);
  final _records = <StorePromotionRecord>[];
  bool _listLoaded = false,
      _listing = false,
      _sourceLoading = false,
      _dirty = false;
  int _selectionEpoch = 0, _modalGeneration = 0;
  String? _cursor, _placementId, _skuId, _channel, _notice;
  DateTime? _from, _until;
  WorkspaceCatalogueOwnedSku? _source;
  BuildContext? _modalContext;
  WorkSession get _session => widget.session;
  StorePromotionController get _owner => widget.owner;
  bool get _live => mounted && _owner.active;
  bool get _locked =>
      !_live || !_owner.ready || _owner.busy || _owner.pending != null;
  WorkspaceCatalogueItem? get _product =>
      _session.workspaceCatalogueItems.where((p) => p.id == _skuId).firstOrNull;
  List<String> get _channels => [
    if (_product?.retailEnabled == true) 'retail',
    if (_product?.wholesaleOffer?.enabled == true)
      if (_product?.wholesaleOffer?.saleType case final type?) type.name,
  ];
  @override
  void initState() {
    super.initState();
    _owner.addListener(_changed);
    _session.addListener(_changed);
  }

  void _changed() {
    if (!_live) _closeModal();
    if (mounted) setState(() {});
  }

  void _closeModal() {
    final modal = _modalContext;
    _modalContext = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (modal?.mounted == true && ModalRoute.of(modal!)?.isCurrent == true) {
        Navigator.of(modal).pop();
      }
    });
  }

  Widget _guardModal(BuildContext context, Widget child) {
    _modalContext = context;
    return AnimatedBuilder(
      animation: _session,
      builder: (_, _) => _live ? child : const SizedBox.shrink(),
    );
  }

  void _endModal(int generation) {
    if (_modalGeneration == generation) _modalContext = null;
  }

  Future<bool> _mayReplace() async {
    if (!_dirty) return _live;
    final generation = ++_modalGeneration;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialog) => _guardModal(
        dialog,
        AlertDialog(
          title: const Text('Discard unsaved promotion changes?'),
          content: const Text(
            'Your saved promotion and customer-message draft will not change.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Discard changes'),
            ),
          ],
        ),
      ),
    );
    _endModal(generation);
    return _live && discard == true;
  }

  Future<void> _loadList({bool more = false}) async {
    if (!_live || _listing || more && _cursor == null) return;
    setState(() {
      _listing = true;
      _notice = null;
    });
    try {
      if (!await _owner.restore() || !_live || _owner.pending != null) return;
      final page = await _owner.gateway.list(
        _owner.scope,
        () => _live,
        after: more ? _cursor : null,
      );
      if (!_live) return;
      final combined = more ? [..._records] : <StorePromotionRecord>[];
      for (final record in page.records) {
        if (record.scope != _owner.scope ||
            combined.any((r) => r.placementId == record.placementId)) {
          throw const FormatException();
        }
        combined.add(record);
      }
      setState(() {
        _records
          ..clear()
          ..addAll(combined);
        _cursor = page.nextCursor;
        _listLoaded = true;
      });
    } on Object {
      if (_live) {
        setState(() {
          _listLoaded = false;
          _notice = 'Saved promotions could not be opened. Try again.';
        });
      }
    } finally {
      if (_live) setState(() => _listing = false);
    }
  }

  Future<void> _open(String? id) async {
    if (_locked || _listing || !await _mayReplace() || !_live) return;
    final placement =
        id ??
        'promotion-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    if (!await _owner.refresh(placement) || !_live) return;
    final existing = _owner.currentRecord?.input;
    setState(() {
      _placementId = placement;
      _skuId = existing?.skuId;
      _channel = existing?.channel;
      _headline.text = existing?.headline ?? '';
      _detail.text = existing?.detail ?? '';
      final terms = existing?.benefitTerms;
      _benefitKind = terms?.kind; _flatBasis = terms?.flatBasis;
      _benefitAmount.text = terms == null ? '' : workspacePriceInputFromMinor(terms.flatAmountMinor ?? terms.percentageBasisPoints!);
      _benefitCap.text = terms?.maximumSavingMinor == null ? '' : workspacePriceInputFromMinor(terms!.maximumSavingMinor!);
      _benefitSpend.text = terms?.minimumSpendMinor == null ? '' : workspacePriceInputFromMinor(terms!.minimumSpendMinor!);
      _benefitQuantity.text = terms?.minimumQuantity?.toString() ?? '';
      _from = existing?.validFrom ?? widget.now().toUtc();
      _until = existing?.validUntil;
      _source = null;
      _dirty = false;
      _notice = null;
    });
    if (_skuId != null) await _loadSource();
  }

  Future<void> _loadSource() async {
    final sku = _skuId, channel = _channel, epoch = ++_selectionEpoch;
    if (!_live || sku == null || channel == null) return;
    setState(() {
      _sourceLoading = true;
      _source = null;
    });
    final source = await _session.readWorkspacePromotionSource(
      sku,
      channel: channel,
    );
    if (!_live || epoch != _selectionEpoch) return;
    setState(() {
      _sourceLoading = false;
      _source = source;
      if (source == null) {
        _notice =
            'Current product details could not be confirmed. Refresh the product before promoting it.';
      }
    });
  }

  Future<void> _chooseProduct() async {
    if (_locked || _sourceLoading) return;
    final generation = ++_modalGeneration;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => _guardModal(
        sheet,
        SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheet).height * .65,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  'Choose a saved product',
                  style: Theme.of(sheet).textTheme.titleMedium,
                ),
                for (final item in _session.workspaceCatalogueItems)
                  ListTile(
                    key: Key('work-promotion-product-${item.id}'),
                    title: Text(item.title),
                    subtitle: Text(item.pack),
                    onTap: () {
                      if (_live) Navigator.pop(sheet, item.id);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    _endModal(generation);
    if (!_live ||
        selected == null ||
        !_session.workspaceCatalogueItems.any((p) => p.id == selected)) {
      return;
    }
    setState(() {
      _skuId = selected;
      _source = null;
      _channel = _channels.contains(_channel)
          ? _channel
          : _channels.firstOrNull;
      _dirty = true;
    });
    await _loadSource();
  }

  Future<void> _pickDate({required bool start}) async {
    if (_locked) return;
    final generation = ++_modalGeneration,
        today = DateUtils.dateOnly(widget.now().toLocal());
    final retained = (start ? _from : _until)?.toLocal();
    var first = today.subtract(const Duration(days: 366)),
        last = today.add(const Duration(days: 730));
    if (retained != null && retained.isBefore(first)) {
      first = DateUtils.dateOnly(retained);
    }
    if (retained != null && retained.isAfter(last)) {
      last = DateUtils.dateOnly(retained);
    }
    final selected = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDate: retained ?? today.add(Duration(days: start ? 0 : 7)),
      builder: (dialog, child) =>
          _guardModal(dialog, child ?? const SizedBox.shrink()),
    );
    _endModal(generation);
    if (!_live || selected == null) return;
    setState(() {
      if (start) {
        _from = selected.toUtc();
      } else {
        _until = selected
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1))
            .toUtc();
      }
      _dirty = true;
    });
  }

  BuyV2AdvertisedBenefitTerms? get _advertisedTerms {
    final kind = _benefitKind;
    if (kind == null) return null;
    const maxMoney = 4503599627370495;
    int? optionalMoney(TextEditingController controller) {
      if (controller.text.trim().isEmpty) return null;
      return workspacePriceMinorFromInput(controller.text, maximumMinor: maxMoney) ?? (throw const FormatException());
    }
    final amount = workspacePriceMinorFromInput(_benefitAmount.text, maximumMinor: kind == 'flat' ? maxMoney : 10000);
    if (amount == null) throw const FormatException();
    final quantityText = _benefitQuantity.text.trim();
    if (quantityText.isNotEmpty && !RegExp(r'^\d+$').hasMatch(quantityText)) throw const FormatException();
    final quantity = quantityText.isEmpty ? null : int.tryParse(quantityText);
    if (quantityText.isNotEmpty && quantity == null) throw const FormatException();
    return BuyV2AdvertisedBenefitTerms(kind: kind, flatAmountMinor: kind == 'flat' ? amount : null,
      flatBasis: kind == 'flat' ? _flatBasis : null, percentageBasisPoints: kind == 'percentage' ? amount : null,
      maximumSavingMinor: optionalMoney(_benefitCap), minimumSpendMinor: optionalMoney(_benefitSpend), minimumQuantity: quantity);
  }

  Widget _benefitInput(String key, String label, TextEditingController controller, {bool whole = false}) => TextField(
    key: Key(key), controller: controller, enabled: !_locked,
    keyboardType: TextInputType.numberWithOptions(decimal: !whole),
    decoration: InputDecoration(labelText: label, helperText: whole ? 'Whole selling packs' : 'Up to two decimal places'),
    onChanged: (_) => setState(() => _dirty = true));

  Widget _benefitEditor() {
    String? error;
    try { _advertisedTerms; } on FormatException { error = 'Check the amount, basis and optional limits. Use positive values; minimum spend can be zero.'; }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DropdownButtonFormField<String>(key: const Key('work-promotion-benefit-kind'), initialValue: _benefitKind ?? 'none', isExpanded: true,
        decoration: const InputDecoration(labelText: 'Offer amount · optional'),
        items: const [DropdownMenuItem(value: 'none', child: Text('No structured offer amount')),
          DropdownMenuItem(value: 'flat', child: Text('Flat amount (₹)')),
          DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)'))],
        onChanged: _locked ? null : (value) => setState(() {
          _benefitKind = value == 'none' ? null : value; _flatBasis = null; _benefitAmount.clear(); _dirty = true;
        })),
      if (_benefitKind != null) ...[
        _benefitInput('work-promotion-benefit-amount', _benefitKind == 'flat' ? 'Advertised amount (₹)' : 'Advertised percentage (%)', _benefitAmount),
        if (_benefitKind == 'flat') DropdownButtonFormField<String>(key: const Key('work-promotion-flat-basis'), initialValue: _flatBasis, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Flat amount applies'),
          items: const [DropdownMenuItem(value: 'per_pack', child: Text('Per selling pack')),
            DropdownMenuItem(value: 'per_order', child: Text('Once per order for this product'))],
          onChanged: _locked ? null : (value) => setState(() { _flatBasis = value; _dirty = true; })),
        _benefitInput('work-promotion-benefit-cap', 'Maximum saving per order (₹) · optional', _benefitCap),
        _benefitInput('work-promotion-benefit-spend', 'Minimum spend on this product (₹) · optional', _benefitSpend),
        _benefitInput('work-promotion-benefit-quantity', 'Minimum selling packs · optional', _benefitQuantity, whole: true),
        const Padding(padding: EdgeInsets.only(top: 6), child: Text('These are your advertised terms, not an applied discount. Checkout confirmation is separate.')),
        if (error != null) Text(error, key: const Key('work-promotion-benefit-error'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    ]);
  }

  StorePromotionInput? get _input {
    final source = _source, from = _from, until = _until, channel = _channel;
    if (source == null ||
        channel == null ||
        from == null ||
        until == null ||
        source.skuId != _skuId ||
        !until.isAfter(widget.now().toUtc())) {
      return null;
    }
    try {
      return StorePromotionInput(
        skuId: source.skuId,
        skuRevision: source.revision,
        channel: channel,
        headline: _headline.text,
        detail: _detail.text,
        validFrom: from,
        validUntil: until,
        active: true,
        benefitTerms: _advertisedTerms,
      );
    } on Object {
      return null;
    }
  }

  Future<void> _save({bool pause = false}) async {
    final id = _placementId,
        input = pause ? _owner.currentRecord?.input.paused() : _input;
    if (_locked ||
        id == null ||
        input == null ||
        _owner.loadedPlacementId != id) {
      return;
    }
    final result = await _session.submitWorkspaceProductPromotion(id, input);
    if (!_live) return;
    setState(() {
      if (!pause && result.state == StorePromotionResultState.saved) {
        _dirty = false;
      }
      _notice = null;
    });
  }

  Future<void> _refreshCurrent() async {
    final id = _placementId;
    if (_locked || id == null) return;
    if (await _owner.refresh(id) && _live) {
      setState(
        () =>
            _notice = 'Saved promotion checked. Your unsaved entries are kept.',
      );
      await _loadSource();
    }
  }

  String _date(DateTime? value) => value == null
      ? 'Choose date'
      : '${value.toLocal().day}/${value.toLocal().month}/${value.toLocal().year}';
  @override
  Widget build(BuildContext context) {
    if (!_live) return const SizedBox.shrink();
    final original = _owner.pending;
    final current = _owner.currentRecord;
    final savedLoaded =
        _placementId != null && _owner.loadedPlacementId == _placementId;
    return ExpansionTile(
      key: const Key('work-public-promotions-panel'),
      tilePadding: EdgeInsets.zero,
      maintainState: true,
      title: const Text('Public product promotions'),
      subtitle: Text(
        original == null
            ? 'Separate from customer messages'
            : 'Earlier update needs checking',
      ),
      onExpansionChanged: (open) {
        if (open && !_listLoaded) unawaited(_loadList());
      },
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Public listing only. No checkout discount or customer message.',
            ),
            if (_listing || _owner.busy || _sourceLoading)
              const LinearProgressIndicator(),
            if (_notice != null)
              Text(_notice!, key: const Key('work-promotion-notice')),
            if (_owner.message != null)
              Text(_owner.message!, key: const Key('work-promotion-status')),
            if (original != null) ...[
              const Text(
                'An earlier update is unconfirmed. Check its result before saving again.',
              ),
              TextButton.icon(
                key: const Key('work-promotion-original'),
                onPressed: _owner.busy
                    ? null
                    : () async {
                        await _owner.reconcile();
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('Check original update'),
              ),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  key: const Key('work-promotion-new'),
                  onPressed: _locked || !_listLoaded || _listing
                      ? null
                      : () => _open(null),
                  icon: const Icon(Icons.add),
                  label: const Text('New product promotion'),
                ),
                TextButton(
                  onPressed: _owner.busy || _listing || original != null
                      ? null
                      : _loadList,
                  child: const Text('Refresh promotions'),
                ),
              ],
            ),
            for (final record in _records)
              ListTile(
                contentPadding: EdgeInsets.zero,
                key: Key('work-promotion-record-${record.placementId}'),
                title: Text(record.input.headline),
                subtitle: Text(
                  'Saved ${record.input.active ? 'active' : 'paused'} · until ${_date(record.input.validUntil)}',
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _locked || _listing
                    ? null
                    : () => _open(record.placementId),
              ),
            if (_cursor != null)
              TextButton(
                onPressed: _locked || _listing
                    ? null
                    : () => _loadList(more: true),
                child: const Text('More promotions'),
              ),
            if (_placementId != null) ...[
              const Divider(),
              OutlinedButton.icon(
                key: const Key('work-promotion-product'),
                onPressed: _locked || _sourceLoading ? null : _chooseProduct,
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(
                  _product == null
                      ? 'Choose saved product'
                      : '${_product!.title} · ${_product!.pack}',
                ),
              ),
              if (_skuId != null && _product == null)
                const Text(
                  'The original product is no longer in this Store. You can still pause its saved promotion.',
                ),
              if (_channels.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final channel in _channels)
                      ChoiceChip(
                        label: Text(switch (channel) {
                          'retail' => 'Retail',
                          'wholesale' => 'Wholesale',
                          _ => 'Bulk',
                        }),
                        selected: _channel == channel,
                        onSelected: _locked || _sourceLoading
                            ? null
                            : (_) {
                                setState(() {
                                  _channel = channel;
                                  _dirty = true;
                                });
                                unawaited(_loadSource());
                              },
                      ),
                  ],
                ),
              TextField(
                key: const Key('work-promotion-headline'),
                controller: _headline,
                scrollController: _headlineScroll,
                enabled: !_locked,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'Promotion headline',
                  counterText: '',
                ),
                onChanged: (_) => setState(() => _dirty = true),
              ),
              TextField(
                key: const Key('work-promotion-detail'),
                controller: _detail,
                scrollController: _detailScroll,
                enabled: !_locked,
                maxLength: 2000,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Product promotion details',
                  counterText: '',
                ),
                onChanged: (_) => setState(() => _dirty = true),
              ),
              if (_owner.benefitTermsSupported) _benefitEditor(),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _locked ? null : () => _pickDate(start: true),
                    icon: const Icon(Icons.event_outlined),
                    label: Text('Starts ${_date(_from)}'),
                  ),
                  TextButton.icon(
                    key: const Key('work-promotion-expiry'),
                    onPressed: _locked ? null : () => _pickDate(start: false),
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text(
                      _until == null
                          ? 'Choose end date'
                          : 'Ends ${_date(_until)}',
                    ),
                  ),
                ],
              ),
              if (_dirty)
                const Text(
                  'Unsaved entries are kept while this editor stays open.',
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    key: const Key('work-promotion-save'),
                    onPressed:
                        _locked ||
                            _sourceLoading ||
                            !savedLoaded ||
                            _input == null
                        ? null
                        : () => _save(),
                    child: Text(
                      current?.input.active == false
                          ? 'Save and resume promotion'
                          : 'Save product promotion',
                    ),
                  ),
                  if (current?.input.active == true)
                    OutlinedButton(
                      key: const Key('work-promotion-pause'),
                      onPressed: _locked || !savedLoaded
                          ? null
                          : () => _save(pause: true),
                      child: const Text('Pause saved promotion'),
                    ),
                  TextButton(
                    key: const Key('work-promotion-refresh'),
                    onPressed: _locked ? null : _refreshCurrent,
                    child: const Text('Refresh saved promotion'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _closeModal();
    _owner.removeListener(_changed);
    _session.removeListener(_changed);
    _headline.dispose();
    _detail.dispose();
    _benefitAmount.dispose(); _benefitCap.dispose(); _benefitSpend.dispose(); _benefitQuantity.dispose();
    _headlineScroll.dispose();
    _detailScroll.dispose();
    super.dispose();
  }
}
