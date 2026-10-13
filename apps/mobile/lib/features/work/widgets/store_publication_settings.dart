import 'package:flutter/material.dart';
import '../../../core/design/mool_colors.dart';
import '../work_models.dart';
import '../work_session.dart';
import 'store_settings_widgets.dart';
import 'store_payment_terms.dart';

/// One-time provider inputs inside existing Business details, not a new route.
class StorePublicationSettings extends StatefulWidget {
  const StorePublicationSettings({required this.session, super.key});
  final WorkSession session;
  @override
  State<StorePublicationSettings> createState() =>
      _StorePublicationSettingsState();
}

class _StorePublicationSettingsState extends State<StorePublicationSettings> {
  late final _storeId =
      widget.session.activeWorkspace?.id ?? widget.session.workspaceId;
  late final _initial = widget.session.workspacePublicationDetails;
  late String _businessType = _initial.businessType;
  late bool _retail = _initial.retailChannelEnabled ?? true;
  late bool _wholesale =
      _initial.wholesaleChannelEnabled ??
      widget.session.workspaceCatalogueItems.any(
        (item) => item.wholesaleOffer?.enabled == true,
      );
  static const _labels = {
    'legalName': 'Legal business name',
    'street': 'Shop / building / street',
    'city': 'City',
    'state': 'State',
    'pinCode': 'PIN code',
    'billingAddress': 'Registered address, if different',
    'pan': 'Business PAN, if applicable',
    'cin': 'CIN, if applicable',
    'fssai': 'Store FSSAI, if applicable',
    'signatory': 'Invoice signatory',
    'returnSummary': 'Return terms for customers',
    'returnConditions': 'Return conditions',
    'returnWindowDays': 'Return window',
    'dispatchDays': 'Dispatch within',
  };
  late final _fields = {
    for (final key in _labels.keys)
      key: TextEditingController(text: '${_initial.toJson()[key] ?? ''}'),
  };
  late List<WorkspacePaymentTerm> _wholesaleTerms = List.of(
    _initial.wholesalePaymentTerms,
  );
  late final _remedies = Set<String>.of(_initial.returnRemedies);
  String? _message;
  bool _failed = false;

  void _applyBusiness({String? type, bool? retail, bool? wholesale}) {
    final details = WorkspaceStorePublicationDetails.fromJson({
      ...widget.session.workspacePublicationDetails.toJson(),
      'businessType': type ?? _businessType,
      'retailChannelEnabled': retail ?? _retail,
      'wholesaleChannelEnabled': wholesale ?? _wholesale,
    });
    final saved = widget.session.saveWorkspacePublicationDetails(
      details,
      expectedStoreId: _storeId,
    );
    setState(() {
      if (saved) {
        _businessType = details.businessType;
        _retail = details.retailChannelEnabled!;
        _wholesale = details.wholesaleChannelEnabled!;
      }
      _failed = !saved;
      _message = saved
          ? 'Selling preferences applied'
          : 'Your Store changed. Reopen these details in the correct Store.';
    });
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  void _apply({required bool address}) {
    final current = widget.session.workspacePublicationDetails;
    final patch = <String, Object?>{...current.toJson()};
    if (address) {
      for (final key in _labels.keys.take(10)) {
        patch[key] = _fields[key]!.text.trim();
      }
      if ([
        'street',
        'city',
        'state',
        'pinCode',
      ].any((key) => patch[key] != current.toJson()[key])) {
        // Even a move within one PIN invalidates the previously resolved place.
        patch.remove('shoppingArea');
      }
    } else {
      for (final key in ['returnSummary', 'returnConditions']) {
        patch[key] = _fields[key]!.text.trim();
      }
      patch['dispatchDays'] = int.tryParse(
        _fields['dispatchDays']!.text.trim(),
      );
      patch['returnWindowDays'] = int.tryParse(
        _fields['returnWindowDays']!.text.trim(),
      );
      patch['wholesalePaymentTerms'] = _wholesaleTerms
          .map((t) => t.toJson())
          .toList();
      patch['returnRemedies'] = _remedies.toList();
    }
    try {
      final details = WorkspaceStorePublicationDetails.fromJson(patch);
      final saved = widget.session.saveWorkspacePublicationDetails(
        details,
        expectedStoreId: _storeId,
      );
      setState(() {
        _failed = !saved;
        _message = saved
            ? (address
                  ? 'Store details applied'
                  : 'Payment and return preferences applied')
            : 'Your Store changed. Reopen these details in the correct Store.';
      });
    } on FormatException catch (error) {
      setState(() {
        _failed = true;
        _message = error.message;
      });
    }
  }

  StoreSettingsInput _input(
    String key, {
    bool required = false,
    bool full = false,
  }) => StoreSettingsInput(
    id: 'work-publication-$key',
    label: _labels[key]!,
    controller: _fields[key]!,
    fullWidth: full,
    maxLines:
        [
          'returnSummary',
          'returnConditions',
          'street',
          'billingAddress',
        ].contains(key)
        ? 3
        : 1,
    numeric: ['pinCode', 'returnWindowDays', 'dispatchDays'].contains(key),
    suffix: ['returnWindowDays', 'dispatchDays'].contains(key) ? 'days' : null,
    validate: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) return 'Enter this detail.';
      if (text.length > 2000) return 'Use at most 2,000 characters.';
      if (text.isEmpty) return null;
      if (key == 'pinCode') return StoreSettingsInput.pin(text);
      if (key == 'dispatchDays' || key == 'returnWindowDays') {
        return StoreSettingsInput.whole(text, 0, 365);
      }
      return null;
    },
  );

  Widget _choices(
    String title,
    String id,
    Set<String> values,
    Set<String> selected,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: MoolColors.navy,
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 0,
          children: [
            for (final value in values)
              FilterChip(
                key: Key('work-publication-$id-$value'),
                label: Text(value),
                selected: selected.contains(value),
                onSelected: (on) => setState(() {
                  on ? selected.add(value) : selected.remove(value);
                  _message = null;
                }),
                selectedColor: MoolColors.navy,
                labelStyle: TextStyle(
                  color: selected.contains(value)
                      ? Colors.white
                      : MoolColors.navy,
                ),
              ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => StoreSettingsStyle(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StoreSettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('work-publication-business-type'),
                  initialValue: _businessType,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Business type'),
                  items: [
                    for (final entry
                        in WorkspaceStorePublicationDetails
                            .businessTypes
                            .entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) _applyBusiness(type: value);
                  },
                ),
                const SizedBox(height: 6),
                const Text('Sell through'),
                Wrap(
                  spacing: 16,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Retail'),
                        Switch(
                          key: const Key('work-publication-channel-retail'),
                          value: _retail,
                          onChanged: (value) => _applyBusiness(retail: value),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Wholesale'),
                        Switch(
                          key: const Key('work-publication-channel-wholesale'),
                          value: _wholesale,
                          onChanged: (value) =>
                              _applyBusiness(wholesale: value),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  !_retail && !_wholesale
                      ? 'Online selling is off. Your Store stock stays available for Counter Sale.'
                      : 'Use either or both. Product prices and packs stay in the product editor; publication checks still apply.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        StoreSettingsCard(
          tonal: true,
          child: ExpansionTile(
            key: const PageStorageKey('work-publication-address-section'),
            title: const Text('Address & invoicing'),
            children: [
              StoreSettingsForm(
                title: '',
                detail: '',
                embedded: true,
                pairAtWidth: 260,
                fields: [
                  _input('legalName', required: true, full: true),
                  _input('street', required: true, full: true),
                  _input('city', required: true),
                  _input('state', required: true),
                  _input('pinCode', required: true),
                  _input('signatory'),
                  _input('billingAddress', full: true),
                ],
                saveKey: 'work-publication-save-address',
                saveLabel: 'Apply Store details',
                onSave: () => _apply(address: true),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExpansionTile(
                      key: const PageStorageKey(
                        'work-publication-business-references',
                      ),
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Business references'),
                      children: [
                        for (final key in ['pan', 'cin', 'fssai'])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextField(
                              key: Key('work-publication-$key'),
                              controller: _fields[key],
                              decoration: InputDecoration(
                                labelText: _labels[key],
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      widget.session.workspacePublicationDetails.shoppingArea ==
                              null
                          ? 'Location confirmation is still required before publication.'
                          : 'Location linked · ${widget.session.workspacePublicationDetails.shoppingArea!.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Text(
                      'Leave the registered address blank to use the Store address.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        StoreSettingsCard(
          child: ExpansionTile(
            key: const PageStorageKey('work-publication-terms-section'),
            title: const Text('Payments & returns'),
            children: [
              StoreSettingsForm(
                title: '',
                detail: '',
                embedded: true,
                pairAtWidth: 260,
                leading: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Buy / Retail',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Full advance through MoolSocial',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    ExpansionTile(
                      key: const PageStorageKey(
                        'work-publication-wholesale-terms',
                      ),
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Wholesale payment terms'),
                      children: [
                        StorePaymentTermsEditor(
                          initial: _wholesaleTerms,
                          onChanged: (value) {
                            _wholesaleTerms = value;
                          },
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Choose one or more defaults. Set individual arrangements in Customers → customer details.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                fields: [
                  _input('returnSummary', required: true, full: true),
                  _input('returnWindowDays'),
                  _input('dispatchDays', required: true),
                  _input('returnConditions', full: true),
                ],
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _choices(
                      'Return options',
                      'remedy',
                      WorkspaceStorePublicationDetails.remedies,
                      _remedies,
                    ),
                    const Text(
                      'Applies to products without their own return terms. Delivery coverage and charges are managed by MoolSocial.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                saveKey: 'work-publication-save-terms',
                saveLabel: 'Apply terms',
                onSave: () => _apply(address: false),
              ),
            ],
          ),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _message!,
                key: const Key('work-publication-result'),
                style: TextStyle(
                  fontSize: 12,
                  color: _failed ? const Color(0xffb42318) : MoolColors.navy,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
