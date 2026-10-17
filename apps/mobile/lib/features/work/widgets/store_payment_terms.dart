import 'package:flutter/material.dart';
import '../work_models.dart';
import '../work_session.dart';
import '../work_supplier_policy.dart';
import '../../buy/buy_v2_content_contracts.dart';
import '../../../core/design/mool_colors.dart';
import 'store_settings_widgets.dart';

/// Explicit customer-facing policy; separate from private payment/return defaults.
class StoreSupplierPolicyPanel extends StatefulWidget {
  const StoreSupplierPolicyPanel({required this.session, super.key});
  final WorkSession session;
  @override
  State<StoreSupplierPolicyPanel> createState() => _StoreSupplierPolicyPanelState();
}
class _StoreSupplierPolicyPanelState extends State<StoreSupplierPolicyPanel> {
  late final _session = widget.session;
  late final _policy = _session.workspaceSupplierPolicy;
  final _title = TextEditingController(), _body = TextEditingController();
  final _titleScroll = ScrollController(keepScrollOffset: false), _bodyScroll = ScrollController(keepScrollOffset: false);
  final _selected = <String>{};
  bool _requiresAcceptance = false, _initialized = false;
  DateTime? _expiry;
  BuildContext? _modalContext;
  int _modalGeneration = 0;
  String? _error;
  bool get _current => mounted && identical(widget.session, _session) && _policy?.active == true;
  void _hydrateOnce() {
    if (_initialized || _policy?.ready != true) return;
    _fill(_policy?.draft ?? _policy?.published?.draft);
    _initialized = true;
  }
  void _closeRetiredModal() {
    final modal = _modalContext;
    _modalContext = null;
    _modalGeneration++;
    if (modal == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (modal.mounted && ModalRoute.of(modal)?.isCurrent == true) Navigator.of(modal).pop();
    });
  }
  @override
  void didUpdateWidget(covariant StoreSupplierPolicyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_current) _closeRetiredModal();
  }
  @override
  void initState() {
    super.initState();
    if (_policy != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || !_current) return;
        await _policy.refresh();
        if (!mounted || !_current) return;
        setState(_hydrateOnce);
      });
    }
  }
  void _fill(StorePolicyDraft? draft) {
    if (draft == null) return;
    _title.text = draft.title; _body.text = draft.body;
    _selected..clear()..addAll(draft.productIds);
    _requiresAcceptance = draft.requiresAcceptance; _expiry = draft.validUntil;
  }
  StorePolicyDraft _value() => StorePolicyDraft(title: _title.text, body: _body.text,
    productIds: _selected, requiresAcceptance: _requiresAcceptance, validUntil: _expiry);
  Future<void> _save({required bool publish}) async {
    if (!_current || _policy!.busy) return;
    try {
      final value = _value();
      setState(() => _error = null);
      if (publish) {
        await _session.publishWorkspaceSupplierPolicy(value);
      } else {
        await _policy.saveDraft(value);
      }
    } on FormatException catch (error) {
      if (mounted && _current) setState(() => _error = error.message);
    }
    if (mounted && _current) setState(() {});
  }
  Future<void> _pickExpiry() async {
    if (!_current || _policy!.busy) return;
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final existing = _expiry?.toLocal();
    final usualLast = DateTime(now.year + 5, now.month, now.day);
    final generation = ++_modalGeneration;
    final chosen = await showDatePicker(context: context,
      initialDate: existing != null && !existing.isBefore(first) ? existing : first,
      firstDate: first, lastDate: existing != null && existing.isAfter(usualLast) ? existing : usualLast,
      builder: (modal, child) {
        if (generation == _modalGeneration) _modalContext = modal;
        return AnimatedBuilder(animation: _session, builder: (context, _) {
          if (!_current) { _closeRetiredModal(); return const SizedBox.shrink(); }
          return child!;
        });
      });
    if (generation == _modalGeneration) _modalContext = null;
    if (chosen == null || !mounted || !_current) return;
    setState(() => _expiry = DateTime(chosen.year, chosen.month, chosen.day, 23, 59, 59).toUtc());
  }
  Future<void> _pickProducts() async {
    if (!_current || _policy!.busy) return;
    final chosen = Set<String>.of(_selected);
    final items = _session.workspaceCatalogueItems.toList(growable: false);
    final generation = ++_modalGeneration;
    final result = await showModalBottomSheet<Set<String>>(context: context, isScrollControlled: true,
      builder: (modal) {
        if (generation == _modalGeneration) _modalContext = modal;
        return AnimatedBuilder(animation: _session, builder: (context, _) {
          if (!_current) { _closeRetiredModal(); return const SizedBox.shrink(); }
          return FractionallySizedBox(heightFactor: .85, child: SafeArea(child: StatefulBuilder(
        builder: (context, change) => Column(children: [
          const Padding(padding: EdgeInsets.all(12), child: Text('Choose saved products', style: TextStyle(fontWeight: FontWeight.w700))),
          CheckboxListTile(title: const Text('All currently saved products'),
            subtitle: const Text('New products are not added automatically.'),
            value: items.isNotEmpty && items.every((p) => chosen.contains(p.id)),
            onChanged: (value) => change(() {if (value == true) {chosen.addAll(items.map((p) => p.id));}
              else {chosen.removeAll(items.map((p) => p.id));}})),
          Expanded(child: ListView(children: [for (final item in items) CheckboxListTile(
            title: Text(item.title), subtitle: Text('${item.brand} · ${item.variant} · ${item.pack}'),
            value: chosen.contains(item.id), onChanged: (value) => change(() {
              if (value == true) {chosen.add(item.id);} else {chosen.remove(item.id);}
            }))])),
          Wrap(spacing: 12, children: [TextButton(onPressed: () => change(chosen.clear), child: const Text('Clear selection')),
            FilledButton(onPressed: () => Navigator.of(context).pop(chosen), child: const Text('Use selection'))]),
          const SizedBox(height: 12),
        ]),
      )));
        });
      });
    if (generation == _modalGeneration) _modalContext = null;
    if (result == null || !mounted || !_current) return;
    setState(() {_selected..clear()..addAll(result);});
  }
  @override
  void dispose() {_closeRetiredModal(); _title.dispose(); _body.dispose(); _titleScroll.dispose(); _bodyScroll.dispose(); super.dispose();}
  @override
  Widget build(BuildContext context) {
    if (_policy == null) {
      return const ListTile(dense: true, contentPadding: EdgeInsets.zero,
        title: Text('Customer-facing policy'), subtitle: Text('Online policy publishing is unavailable. Private return preferences stay unchanged.'));
    }
    return AnimatedBuilder(animation: Listenable.merge([_policy, _session]), builder: (context, _) {
      if (!_current) { _closeRetiredModal(); return const Text('Your Store or account changed. Reopen settings to edit its policy.'); }
      final policy = _policy, locked = policy.busy || !_initialized || !policy.ready;
      final missing = _selected.where((id) => !_session.workspaceCatalogueItems.any((p) => p.id == id)).length;
      return ExpansionTile(key: const PageStorageKey('work-supplier-policy-section'), tilePadding: EdgeInsets.zero,
        title: const Text('Customer-facing policy'),
        subtitle: Text(policy.pending != null ? 'Original update needs checking' : policy.published == null
          ? 'Separate from private return preferences' : 'Saved policy · version ${policy.published!.revision}'),
        children: [
          if (!_initialized) Padding(padding: const EdgeInsets.all(12), child: Text(policy.busy
            ? 'Opening saved policy details…' : 'Open saved policy details before editing.')),
          if (policy.pending != null) ListTile(contentPadding: EdgeInsets.zero,
            title: const Text('Check original policy update'),
            subtitle: const Text('Checking does not send it again. New publishing stays on hold.'),
            trailing: IconButton(tooltip: 'Check original policy update', icon: const Icon(Icons.sync),
              onPressed: locked ? null : () async {await policy.reconcile(); if (mounted && _current) setState(() {});})),
          TextField(key: const Key('work-supplier-policy-title'), controller: _title, scrollController: _titleScroll, enabled: !locked,
            maxLength: 160, decoration: const InputDecoration(labelText: 'Policy title')),
          TextField(key: const Key('work-supplier-policy-body'), controller: _body, scrollController: _bodyScroll, enabled: !locked,
            minLines: 3, maxLines: 8, maxLength: 12000, decoration: const InputDecoration(labelText: 'Terms customers should review')),
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: locked ? null : _pickProducts,
            icon: const Icon(Icons.checklist), label: Text('Choose products · ${_selected.length} selected'))),
          if (missing > 0) Text('$missing unavailable selections are kept. Check saved products before publishing.'),
          SwitchListTile.adaptive(contentPadding: EdgeInsets.zero,
            title: const Text('Ask customers to accept before adding'), value: _requiresAcceptance,
            onChanged: locked ? null : (value) => setState(() => _requiresAcceptance = value)),
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            TextButton.icon(onPressed: locked ? null : _pickExpiry, icon: const Icon(Icons.event),
              label: Text(_expiry == null ? 'No expiry · choose date' : 'Expires ${MaterialLocalizations.of(context).formatMediumDate(_expiry!.toLocal())}')),
            if (_expiry != null) TextButton(onPressed: locked ? null : () => setState(() => _expiry = null), child: const Text('Clear expiry')),
          ]),
          const Text('Expiry is the end of the selected day in this device’s time zone. Save a private draft before leaving; publishing is separate.',
            style: TextStyle(fontSize: 12)),
          if (_error != null || policy.message != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8),
            child: Semantics(liveRegion: true, child: Text(_error ?? policy.message!, key: const Key('work-supplier-policy-message')))),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(onPressed: locked ? null : () => _save(publish: false), child: const Text('Save private draft')),
            FilledButton(onPressed: locked || !policy.ready || !policy.currentLoaded || policy.pending != null ? null : () => _save(publish: true),
              child: const Text('Publish policy')),
            TextButton(onPressed: policy.busy ? null : () async {
              await policy.refresh(); if (mounted && _current) setState(_hydrateOnce);
            }, child: const Text('Refresh current policy')),
            if (policy.published != null) TextButton(onPressed: locked ? null : () => setState(() => _fill(policy.published!.draft)), child: const Text('Use current policy')),
          ]),
          const SizedBox(height: 12),
        ]);
    });
  }
}

/// Shared preference editor for Store defaults and a single customer override.
/// Does not generate credit eligibility, amounts due or a checkout term source ID.
class StorePaymentTermsEditor extends StatefulWidget {
  const StorePaymentTermsEditor({
    required this.initial,
    required this.onChanged,
    super.key,
  });
  final List<WorkspacePaymentTerm> initial;
  final ValueChanged<List<WorkspacePaymentTerm>> onChanged;
  @override
  State<StorePaymentTermsEditor> createState() =>
      _StorePaymentTermsEditorState();
}

class _StorePaymentTermsEditorState extends State<StorePaymentTermsEditor> {
  late final _selected = widget.initial.map((t) => t.kind).toSet();
  late final _advance = {
    for (final kind in WorkspacePaymentTerm.wholesaleKinds)
      kind: TextEditingController(
        text:
            '${widget.initial.where((t) => t.kind == kind).firstOrNull?.advancePercent ?? ''}',
      ),
  };
  late final _days = {
    for (final kind in WorkspacePaymentTerm.wholesaleKinds)
      kind: TextEditingController(
        text:
            '${widget.initial.where((t) => t.kind == kind).firstOrNull?.netDays ?? ''}',
      ),
  };
  final _storage = PageStorageBucket();
  int? _numberValue(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    return RegExp(r'^\d+$').hasMatch(text) ? int.tryParse(text) ?? -1 : -1;
  }

  void _emit() {
    widget.onChanged([
      for (final kind in WorkspacePaymentTerm.wholesaleKinds)
        if (_selected.contains(kind))
          WorkspacePaymentTerm(
            kind,
            advancePercent: _numberValue(_advance[kind]!.text),
            netDays: _numberValue(_days[kind]!.text),
          ),
    ]);
  }

  @override
  void dispose() {
    for (final c in [..._advance.values, ..._days.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _number(BuyV2CommercialPaymentTermKind kind, {required bool days}) {
    final controller = (days ? _days : _advance)[kind]!;
    return TextField(
      key: Key('work-payment-${kind.name}-${days ? 'days' : 'advance'}'),
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: days ? 'Credit days' : 'Advance %',
        errorMaxLines: 3,
        errorText: !days &&
                kind == BuyV2CommercialPaymentTermKind.supplierCredit &&
                controller.text.trim().isEmpty
            ? null
            : StoreSettingsInput.whole(controller.text,
                days || kind != BuyV2CommercialPaymentTermKind.supplierCredit ? 1 : 0,
                days ? 365 : 99),
        hintText: days
            ? '1–365'
            : kind == BuyV2CommercialPaymentTermKind.supplierCredit
            ? '0–99'
            : '1–99',
      ),
      onChanged: (_) => setState(_emit),
    );
  }

  @override
  Widget build(BuildContext context) => PageStorage(
    bucket: _storage,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final kind in WorkspacePaymentTerm.wholesaleKinds) ...[
          CheckboxListTile(
            key: Key('work-payment-term-${kind.name}'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            activeColor: MoolColors.navy,
            title: Text(
              WorkspacePaymentTerm(kind).label,
              style: const TextStyle(fontSize: 13),
            ),
            value: _selected.contains(kind),
            onChanged: (on) {
              setState(() {
                on == true ? _selected.add(kind) : _selected.remove(kind);
              });
              _emit();
            },
          ),
          if (_selected.contains(kind) &&
              (WorkspacePaymentTerm(kind).needsAdvance ||
                  kind == BuyV2CommercialPaymentTermKind.supplierCredit))
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 6),
              child: LayoutBuilder(
                builder: (context, box) {
                  final credit =
                      kind == BuyV2CommercialPaymentTermKind.supplierCredit;
                  final pair =
                      credit &&
                      box.maxWidth >= 260 &&
                      MediaQuery.textScalerOf(context).scale(14) <= 19;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: pair
                            ? (box.maxWidth - 8) / 2
                            : !credit &&
                                  MediaQuery.textScalerOf(context).scale(14) <=
                                      19 &&
                                  box.maxWidth > 132
                            ? 132
                            : box.maxWidth,
                        child: _number(kind, days: false),
                      ),
                      if (credit)
                        SizedBox(
                          width: pair ? (box.maxWidth - 8) / 2 : box.maxWidth,
                          child: _number(kind, days: true),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ],
    ),
  );
}

/// Embedded in the existing customer details, never a new customer route.
class StoreCustomerPaymentTerms extends StatefulWidget {
  const StoreCustomerPaymentTerms({
    required this.session,
    required this.storeId,
    required this.customerId,
    super.key,
  });
  final WorkSession session;
  final String storeId, customerId;
  @override
  State<StoreCustomerPaymentTerms> createState() =>
      _StoreCustomerPaymentTermsState();
}

class _StoreCustomerPaymentTermsState extends State<StoreCustomerPaymentTerms> {
  late bool _inherit;
  late List<WorkspacePaymentTerm> _terms;
  late Object _draftContext;
  Object _draftBinding = Object();
  String? _message;
  bool _opening = true;
  bool _dirty = false;
  int _editVersion = 0;

  @override
  void initState() {
    super.initState();
    _initializeDraft();
    _load();
  }

  @override
  void didUpdateWidget(StoreCustomerPaymentTerms oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.storeId != widget.storeId ||
        oldWidget.customerId != widget.customerId) {
      _initializeDraft();
      _load();
    }
  }

  void _initializeDraft({bool preserveInput = false}) {
    _draftContext = widget.session.publicationPreferencesContext;
    _draftBinding = Object();
    final details = widget.session.workspacePublicationDetails;
    if (!preserveInput) {
      _inherit = !details.customerPaymentTerms.containsKey(widget.customerId);
      _terms = List.of(details.customerPaymentTerms[widget.customerId] ?? details.wholesalePaymentTerms);
      _dirty = false;
    }
    _message = null;
  }

  Future<void> _load() async {
    final binding = _draftBinding, session = widget.session;
    _opening = true;
    await session.recoverCustomerLedger();
    if (!_current(binding)) return;
    await session.loadWorkspacePublicationPreferences(expectedStoreId: widget.storeId);
    if (!_current(binding)) return;
    await session.loadWorkspaceCustomerPaymentTerms(expectedStoreId: widget.storeId, customerId: widget.customerId);
    if (!_current(binding)) return;
    setState(() { _initializeDraft(preserveInput: _dirty); _opening = false; });
  }

  bool _current(Object binding) => mounted &&
      identical(binding, _draftBinding) &&
      widget.session.navigationScopeRevision != null &&
      _draftContext == widget.session.publicationPreferencesContext;

  Future<void> _apply(Object binding) async {
    if (!mounted || !identical(binding, _draftBinding)) return;
    final submittedVersion = _editVersion;
    final ok = widget.session.saveWorkspaceCustomerPaymentTerms(
      expectedContext: _draftContext,
      expectedStoreId: widget.storeId,
      customerId: widget.customerId,
      terms: _inherit ? null : _terms,
    );
    if (ok) await widget.session.workspaceCustomerTermsWrite(widget.customerId);
    if (!mounted || !identical(binding, _draftBinding)) return;
    setState(() {
      _message = _editVersion != submittedVersion
          ? 'Your latest edits have not been applied.'
          : ok
          ? widget.session.workspaceCustomerTermsSaved(widget.customerId)
              ? 'Private preferences saved on this device. Not synced to customer checkout.'
              : widget.session.workspaceCustomerTermsError(widget.customerId) ??
                  'Customer preferences applied for this session only.'
          : 'Check the terms and reopen this customer in the correct Store.';
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, child) {
      final binding = _draftBinding;
      return StoreSettingsStyle(
        child: ExpansionTile(
          key: PageStorageKey(
            'customer-payment-terms-${widget.storeId}-${widget.customerId}',
          ),
          title: const Text('Wholesale payment terms'),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (!_current(binding))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Semantics(
                  liveRegion: true,
                  child: const Text('Your Store or account changed. Reopen this customer to edit payment terms.'),
                ),
              )
            else if (_opening) const Padding(
              padding: EdgeInsets.symmetric(vertical: 8), child: Text('Opening private customer preferences…'))
            else ...[
              if (widget.session.workspaceCustomerTermsError(widget.customerId) case final error?) ...[
                Semantics(liveRegion: true, child: Text(error)),
                TextButton(onPressed: () { setState(() { _opening = true; }); _load(); },
                  child: const Text('Retry saved preferences')),
              ],
              SwitchListTile.adaptive(
                key: const Key('work-customer-terms-inherit'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Use Store defaults'),
                value: _inherit,
                onChanged: widget.session.workspaceCustomerTermsSaving(widget.customerId) ? null : (value) {
                  if (!_current(binding)) return;
                  setState(() {
                    _inherit = value;
                    _dirty = true;
                    _editVersion++;
                    _message = null;
                  });
                },
              ),
              if (!_inherit)
                StorePaymentTermsEditor(
                  key: ObjectKey(binding),
                  initial: _terms,
                  onChanged: (value) {
                    if (_current(binding)) {
                      setState(() {
                        _terms = value;
                        _dirty = true;
                        _editVersion++;
                        _message = null;
                      });
                    }
                  },
                ),
              Text(
                widget.session.workspaceCustomerTermsRecoveryAvailable(widget.customerId)
                    ? 'Private wholesale preference for this saved ledger customer. Checkout terms and credit still need confirmation.'
                    : 'Session-only wholesale preference. Saved customer identity is not available; checkout terms and credit still need confirmation.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('work-customer-terms-save'),
                onPressed: widget.session.workspaceCustomerTermsSaving(widget.customerId) ||
                    !widget.session.workspaceCustomerTermsReady(widget.customerId) ? null : () => _apply(binding),
                child: Text(widget.session.workspaceCustomerTermsSaving(widget.customerId)
                    ? 'Saving…' : 'Apply customer terms'),
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Semantics(liveRegion: true, child: Text(_message!)),
                ),
            ],
          ],
        ),
      );
    },
  );
}
