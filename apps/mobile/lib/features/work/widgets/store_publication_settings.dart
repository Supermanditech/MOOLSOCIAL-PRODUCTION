import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/design/mool_colors.dart';
import '../work_catalogue_gateway.dart';
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
  late final String? _storeId;
  late final int? _scopeRevision;
  late final WorkSession _ownerSession;
  late final Object _ownerContext;
  late Future<bool> _load;
  bool _initialized = false;
  WorkspacePublicDetailsController? _publisher;
  static const _publicKeys = ['street', 'city', 'state', 'pinCode', 'publicContactPhone'];
  @override
  void initState() {
    super.initState();
    _storeId = widget.session.activeWorkspace?.id ?? widget.session.workspaceId;
    _scopeRevision = widget.session.navigationScopeRevision;
    _ownerSession = widget.session;
    _ownerContext = widget.session.publicationPreferencesContext;
    if (_storeId != null && !widget.session.publicationPreferencesPersistenceAvailable) {
      _initializeInputs();
      _load = Future.value(true);
    } else {
      _load = _loadInputs();
    }
  }
  bool get _contextCurrent => identical(widget.session, _ownerSession) &&
      _ownerContext == widget.session.publicationPreferencesContext;
  Future<bool> _loadInputs() async {
    final loaded = _storeId != null && await widget.session
        .loadWorkspacePublicationPreferences(expectedStoreId: _storeId);
    if (loaded && mounted && _contextCurrent && !_initialized) {
      _initializeInputs();
    }
    return loaded;
  }
  void _initializeInputs() {
    _initial = widget.session.workspacePublicationDetails;
    for (final key in _labels.keys) {
      _fields[key] = TextEditingController(text: '${_initial.toJson()[key] ?? ''}');
      if (_publicKeys.contains(key)) {
        _fields[key]!.addListener(() { if (mounted) setState(() {}); });
      }
    }
    _initialized = true;
  }
  late final WorkspaceStorePublicationDetails _initial;
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
    'publicContactPhone': 'Customer contact number (public)',
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
  final _fields = <String, TextEditingController>{};
  late List<WorkspacePaymentTerm> _wholesaleTerms = List.of(
    _initial.wholesalePaymentTerms,
  );
  late final _remedies = Set<String>.of(_initial.returnRemedies);
  String? _message;
  bool _failed = false;
  static const _changedContextMessage =
      'Your Store changed. Reopen these details in the correct Store or account. Your entries are kept.';
  bool _canApply() {
    if (!_contextCurrent) {
      setState(() { _failed = true; _message = _changedContextMessage; });
      return false;
    }
    return !widget.session.workspacePublicationPreferencesSaving;
  }

  bool get _publicEditsUnsaved {
    final saved = widget.session.workspacePublicationDetails.toJson();
    return _publicKeys.any((key) => _fields[key]!.text.trim() != '${saved[key] ?? ''}');
  }
  Future<void> _preparePublisher(WorkspacePublicDetailsController publisher) async {
    if (!mounted || !_contextCurrent || !identical(publisher, _publisher)) return;
    await widget.session.loadWorkspacePublicDetailsInputs();
    if (!mounted || !_contextCurrent || !identical(publisher, _publisher)) return;
    if (await publisher.restore() && publisher.pending == null) await publisher.refresh();
  }
  Future<void> _retryPublicOriginal(WorkspacePublicDetailsController publisher) async {
    final original = publisher.pending?.fingerprint;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Retry the original update?'),
      content: Text('${publisher.pending?.details.businessType == null ? 'This sends the address, contact and hours' : 'This sends the public Store details'} saved in the earlier request—not your current edits. '
        'Its result is still unconfirmed. It will not start a different update.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Retry original'))]));
    if (confirmed == true && mounted && _contextCurrent && publisher.canRetryOriginal &&
        publisher.pending?.fingerprint == original && identical(publisher, _publisher)) {
      await publisher.retryOriginal();
    }
  }
  Widget _publicUpdateActions() {
    final publisher = widget.session.workspacePublicDetailsPublisher;
    if (publisher == null) return const SizedBox.shrink();
    if (!identical(publisher, _publisher)) {
      _publisher = publisher;
      // Read-only preparation after the current build; never dispatch a save.
      unawaited(Future<void>.microtask(() => _preparePublisher(publisher)));
    }
    return AnimatedBuilder(animation: publisher, builder: (context, _) {
      final savedInputs = widget.session.workspacePublicDetailsFieldsForPublishing;
      final pending = publisher.pending != null;
      final classification = savedInputs?.businessType != null || publisher.pending?.details.businessType != null ||
        publisher.published?.details.businessType != null;
      final classificationMissing = publisher.published?.details.businessType != null && savedInputs?.businessType == null;
      return Padding(padding: const EdgeInsets.only(top: 8), child: Column(
        key: const Key('work-publication-public-update'), crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(classification ? 'Public Store details' : 'Public address, contact & hours', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(publisher.message ?? 'Check current public details before updating.', style: const TextStyle(fontSize: 12)),
          if (_publicEditsUnsaved) const Text('Apply Store details first. Unsaved entries are not sent publicly.',
            style: TextStyle(fontSize: 12)),
          if (!pending && !_publicEditsUnsaved && savedInputs == null)
            const Text('Save valid Store details and any changed hours on this device first.', style: TextStyle(fontSize: 12)),
          if (!pending && classificationMissing)
            const Text('Choose a business type or Not shown publicly before updating.', style: TextStyle(fontSize: 12)),
          Wrap(spacing: 8, runSpacing: 4, children: [
            TextButton(key: const Key('work-publication-check-public'),
              onPressed: publisher.busy || !_contextCurrent ? null : () async {
                if (publisher.pending != null) { await publisher.reconcile(); }
                else {
                  await widget.session.loadWorkspacePublicDetailsInputs();
                  if (mounted && _contextCurrent) await publisher.refresh();
                }
              }, child: Text(publisher.busy ? 'Checking…' : pending ? 'Check original update' : 'Check public details')),
            if (!pending) FilledButton(key: const Key('work-publication-update-public'),
              onPressed: !publisher.canPublish || savedInputs == null || classificationMissing || _publicEditsUnsaved || !_contextCurrent
                ? null : () async {
                  await widget.session.publishWorkspacePublicDetails(inputCurrent: () => mounted &&
                    _contextCurrent && !_publicEditsUnsaved && identical(publisher, _publisher));
                }, child: const Text('Update public details')),
            if (publisher.canRetryOriginal) OutlinedButton(key: const Key('work-publication-retry-public-original'),
              onPressed: _contextCurrent ? () => _retryPublicOriginal(publisher) : null,
              child: const Text('Retry original update')),
          ]),
          const Text('Only these public details are updated. Online availability and location-based services need separate confirmation.',
            style: TextStyle(fontSize: 12)),
        ]));
    });
  }

  void _applyBusiness({String? type, bool? retail, bool? wholesale}) {
    if (!_canApply()) return;
    final details = WorkspaceStorePublicationDetails.fromJson({
      ...widget.session.workspacePublicationDetails.toJson(),
      'businessType': ?type,
      'retailChannelEnabled': retail ?? _retail,
      'wholesaleChannelEnabled': wholesale ?? _wholesale,
    });
    final saved = widget.session.saveWorkspacePublicationDetails(
      details,
      expectedStoreId: _storeId,
      expectedNavigationRevision: _scopeRevision,
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
    if (!_canApply()) return;
    final current = widget.session.workspacePublicationDetails;
    final patch = <String, Object?>{...current.toJson()};
    if (address) {
      for (final key in const [
        'legalName',
        'street',
        'city',
        'state',
        'pinCode',
        'publicContactPhone',
        'billingAddress',
        'pan',
        'cin',
        'fssai',
        'signatory',
      ]) {
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
        expectedNavigationRevision: _scopeRevision,
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
      if (key == 'publicContactPhone' &&
          !WorkspaceStorePublicationDetails.validPublicPhone(text)) {
        return 'Enter a valid customer contact number.';
      }
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
  Widget build(BuildContext context) => FutureBuilder<bool>(future: _load,
    initialData: _initialized ? true : null,
    builder: (context, snapshot) {
      if (!_contextCurrent) return const Text(_changedContextMessage);
      if (!_initialized && snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator(semanticsLabel: 'Opening saved Store defaults'));
      }
      if (snapshot.data != true || !_initialized) {
        return Column(children: [
        Text(widget.session.workspacePublicationPreferencesError ?? 'Saved Store defaults could not be opened.'),
        OutlinedButton(onPressed: () => setState(() { _load = _loadInputs(); }), child: const Text('Try again')),
        ]);
      }
      return AnimatedBuilder(animation: widget.session, builder: (context, _) {
        if (!_contextCurrent) return const Text(_changedContextMessage);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (widget.session.publicationPreferencesPersistenceAvailable) Padding(
            padding: const EdgeInsets.only(bottom: 8), child: Text(
              widget.session.workspacePublicationPreferencesError ??
                (widget.session.workspacePublicationPreferencesSaving ? 'Saving Store defaults on this device…' :
                 widget.session.workspacePublicationPreferencesSaved ?
                   widget.session.workspacePublicDetailsPublisher == null ? 'Saved on this device. Public synchronization is pending.' :
                   'Saved on this device. Public details are updated separately below.' :
                 'Save these inputs on this device. Public synchronization is pending.'),
              key: const Key('work-publication-device-status'), style: const TextStyle(fontSize: 12))),
          AbsorbPointer(absorbing: widget.session.workspacePublicationPreferencesSaving, child: _editor(context)),
        ]);
      });
    });

  Widget _editor(BuildContext context) => StoreSettingsStyle(
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
                  _input('publicContactPhone', full: true),
                  _input('signatory'),
                  _input('billingAddress', full: true),
                ],
                saveKey: 'work-publication-save-address',
                saveLabel: 'Apply Store details',
                saveEnabled: !widget.session.workspacePublicationPreferencesSaving,
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
                          ? 'Location-based services need a confirmed Store location.'
                          : 'Location linked · ${widget.session.workspacePublicationDetails.shoppingArea!.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Text(
                      'Leave the registered address blank to use the Store address.',
                      style: TextStyle(fontSize: 12),
                    ),
                    _publicUpdateActions(),
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
                        'Choose defaults once. Individual arrangements stay in Customers → customer details. These are preferences; customer eligibility and payable amounts need confirmation at checkout.',
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
                saveEnabled: !widget.session.workspacePublicationPreferencesSaving,
                onSave: () => _apply(address: false),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: StoreSupplierPolicyPanel(session: widget.session,
                  key: ValueKey(('supplier-policy', _storeId, _scopeRevision)))),
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
