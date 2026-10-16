import 'package:flutter/material.dart';
import '../work_models.dart';
import '../work_session.dart';
import '../../buy/buy_v2_content_contracts.dart';
import '../../../core/design/mool_colors.dart';
import 'store_settings_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeDraft();
  }

  @override
  void didUpdateWidget(StoreCustomerPaymentTerms oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.storeId != widget.storeId ||
        oldWidget.customerId != widget.customerId) {
      _initializeDraft();
    }
  }

  void _initializeDraft() {
    _draftContext = widget.session.publicationPreferencesContext;
    _draftBinding = Object();
    final details = widget.session.workspacePublicationDetails;
    _inherit = !details.customerPaymentTerms.containsKey(widget.customerId);
    _terms = List.of(details.customerPaymentTerms[widget.customerId] ??
        details.wholesalePaymentTerms);
    _message = null;
  }

  bool _current(Object binding) => mounted &&
      identical(binding, _draftBinding) &&
      widget.session.navigationScopeRevision != null &&
      _draftContext == widget.session.publicationPreferencesContext;

  void _apply(Object binding) {
    if (!mounted || !identical(binding, _draftBinding)) return;
    final ok = widget.session.saveWorkspaceCustomerPaymentTerms(
      expectedContext: _draftContext,
      expectedStoreId: widget.storeId,
      customerId: widget.customerId,
      terms: _inherit ? null : _terms,
    );
    if (!mounted || !identical(binding, _draftBinding)) return;
    setState(() {
      _message = ok
          ? 'Customer preferences applied'
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
            else ...[
              SwitchListTile.adaptive(
                key: const Key('work-customer-terms-inherit'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Use Store defaults'),
                value: _inherit,
                onChanged: (value) {
                  if (!_current(binding)) return;
                  setState(() {
                    _inherit = value;
                    _message = null;
                  });
                },
              ),
              if (!_inherit)
                StorePaymentTermsEditor(
                  key: ObjectKey(binding),
                  initial: _terms,
                  onChanged: (value) {
                    if (_current(binding)) _terms = value;
                  },
                ),
              const Text(
                'Applies only to this customer’s wholesale orders. Retail stays full advance through MoolSocial.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('work-customer-terms-save'),
                onPressed: () => _apply(binding),
                child: const Text('Apply customer terms'),
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
