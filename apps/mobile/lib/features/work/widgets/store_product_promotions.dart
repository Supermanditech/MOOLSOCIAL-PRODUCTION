import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../work_catalogue_gateway.dart';
import '../work_models.dart';
import '../work_product_promotions.dart';
import '../work_session.dart';
import '../../buy/buy_v2_content_contracts.dart' show BuyV2AdvertisedBenefitTerms;

/// Named, reusable Store-wide coupon drafts. Public activation is deliberately
/// not inferred from a device save or from an existing product advertisement.
class StoreCouponCampaignPanel extends StatefulWidget {
  const StoreCouponCampaignPanel({required this.session, super.key});
  final WorkSession session;
  @override State<StoreCouponCampaignPanel> createState() => _StoreCouponCampaignPanelState();
}

class _StoreCouponCampaignPanelState extends State<StoreCouponCampaignPanel> {
  late final String? _storeId;
  late final int? _epoch;
  late final Map<String, String> _original;
  bool _loading = true, _ready = false;
  bool get _current => mounted && _epoch != null && widget.session.activeWorkspace?.id == _storeId &&
      widget.session.navigationScopeRevision == _epoch &&
      identical(widget.session.workspaceOfferDraft, _original);
  @override void initState() {
    super.initState();
    _storeId = widget.session.activeWorkspace?.id;
    _epoch = widget.session.navigationScopeRevision;
    _original = widget.session.workspaceOfferDraft;
    _load();
  }
  Future<void> _load() async {
    if (_storeId == null) return;
    setState(() => _loading = true);
    final ready = await widget.session.loadWorkspaceOfferDraft(expectedStoreId: _storeId);
    if (_current) setState(() { _loading = false; _ready = ready; });
  }
  Future<void> _edit([StoreCouponCampaign? campaign]) async {
    if (!_current || !_ready || widget.session.workspaceOfferDraftSaving) return;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      isDismissible: false, enableDrag: false,
      useSafeArea: true, builder: (_) => FractionallySizedBox(heightFactor: .94,
        child: _StoreCouponEditor(session: widget.session, storeId: _storeId!,
          campaign: campaign, current: () => _current)));
    if (_current) setState(() {});
  }
  Future<void> _publication(StoreCouponCampaign campaign) async {
    final controller = widget.session.workspaceStoreCoupons;
    if (!_current || !_ready || controller == null) return;
    bool current() => _current && widget.session.workspaceStoreCouponCampaigns.any((saved) =>
      saved.id == campaign.id && saved.revision == campaign.revision &&
      StoreCouponInput.fromCampaign(saved, active: true).fingerprint == StoreCouponInput.fromCampaign(campaign, active: true).fingerprint);
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => _StoreCouponPublicationSheet(controller: controller, campaign: campaign, current: current));
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session, builder: (context, _) {
      if (!_current) return const Text('Reopen Store offers to continue.');
      if (_loading) { return const LinearProgressIndicator(); }
      if (!_ready) { return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Your saved coupons could not be opened. Nothing has been replaced.'),
        TextButton(onPressed: _load, child: const Text('Retry opening coupons')),
      ]); }
      if (widget.session.workspaceStoreCouponRecoveryRequired) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('The last coupon save is not confirmed. Check the saved version before making another change.'),
          TextButton(onPressed: _load, child: const Text('Check saved coupons')),
        ]);
      }
      final campaigns = widget.session.workspaceStoreCouponCampaigns;
      final publisher = widget.session.workspaceStoreCoupons;
      return Column(key: const Key('work-store-coupons'),
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [Color(0xff123d4a), Color(0xff256b78)])),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.local_offer_outlined, color: Colors.white),
                SizedBox(width: 9), Expanded(child: Text('Store coupons',
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)))]),
              const SizedBox(height: 8),
              const Text('One campaign. All eligible products in your Store.',
                style: TextStyle(color: Colors.white, height: 1.4)),
              const SizedBox(height: 12),
              FilledButton.icon(key: const Key('work-coupon-create'),
                onPressed: widget.session.workspaceOfferDraftSaving ? null : () => _edit(),
                icon: const Icon(Icons.add), label: const Text('Create Store coupon')),
            ])),
          const SizedBox(height: 10),
          Text(publisher == null
            ? 'Save once, reopen and edit anytime. Drafts stay private on this device; public publishing is not connected yet.'
            : 'Save drafts here. Check and publish each campaign separately; saving a draft does not update its public version.',
            style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xff566572))),
          for (final campaign in campaigns) ListTile(
            key: ValueKey('work-coupon-${campaign.id}'), contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.confirmation_number_outlined, color: Color(0xff256b78)),
            title: Text(campaign.name),
            subtitle: Text('${_couponSaving(campaign)} · Store-wide\n${publisher == null ? 'Saved draft · not published' : 'Saved draft · check public version separately'}'),
            isThreeLine: true,
            onTap: publisher == null ? null : () => _publication(campaign),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (publisher != null) IconButton(tooltip: 'Manage publishing for ${campaign.name}',
                onPressed: () => _publication(campaign), icon: const Icon(Icons.cloud_upload_outlined)),
              IconButton(tooltip: 'Edit ${campaign.name}',
              onPressed: widget.session.workspaceOfferDraftSaving ? null : () => _edit(campaign),
              icon: const Icon(Icons.edit_outlined))])),
          const SizedBox(height: 18),
        ]);
    });
}

class _StoreCouponPublicationSheet extends StatefulWidget {
  const _StoreCouponPublicationSheet({required this.controller, required this.campaign, required this.current});
  final StoreCouponController controller;
  final StoreCouponCampaign campaign;
  final bool Function() current;
  @override State<_StoreCouponPublicationSheet> createState() => _StoreCouponPublicationSheetState();
}
class _StoreCouponPublicationSheetState extends State<_StoreCouponPublicationSheet> {
  bool _funding = false;
  StoreCouponController get _controller => widget.controller;
  bool get _current => mounted && widget.current() && _controller.active;
  @override void initState() {super.initState(); unawaited(_refresh());}
  Future<void> _refresh() async {
    if (!_current) return;
    setState(() => _funding = false);
    await _controller.refresh(widget.campaign.id);
  }
  Future<void> _reconcile() async {
    if (!_current) return;
    setState(() => _funding = false);
    await _controller.reconcile();
    if (_current) setState(() => _funding = false);
  }
  Future<void> _submit({required bool pause}) async {
    if (!_current || !_funding || _controller.busy) return;
    final input = pause ? _controller.currentRecord?.input.paused()
      : StoreCouponInput.fromCampaign(widget.campaign, active: true);
    if (input == null) return;
    await _controller.submit(widget.campaign.id, input, fundingAcknowledged: _funding, inputCurrent: () => _current);
    if (_current) setState(() => _funding = false);
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _controller, builder: (context, _) {
    final current = _current, record = _controller.currentRecord;
    final loaded = _controller.loadedCouponId == widget.campaign.id;
    final held = _controller.pending != null;
    return ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
      child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [const Icon(Icons.local_offer_outlined, color: Color(0xff256b78)), const SizedBox(width: 10),
            const Expanded(child: Text('Coupon publishing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
            IconButton(tooltip: 'Close coupon publishing', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
          const SizedBox(height: 12),
          Text(widget.campaign.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6), Text('${_couponSaving(widget.campaign)} · Store-wide'),
          Text('Minimum Store bill ₹${_couponAmount(widget.campaign.minimumSpendMinor)}'),
          _couponValidityAndLimits(context, StoreCouponInput.fromCampaign(widget.campaign, active: true)),
          const SizedBox(height: 8),
          const Text('One coupon saving applies to this Store’s eligible basket, not separately to every product. Other Stores are unaffected.'),
          const SizedBox(height: 12),
          if (!current) const Text('Store, account or draft changed. Close and reopen this campaign.')
          else if (_controller.busy) const LinearProgressIndicator()
          else if (held) ...[
            const Text('An earlier coupon update is not confirmed. Check that original update before publishing again.'),
            const SizedBox(height: 8),
            Text('Original coupon: ${_controller.pending!.input.name}'),
            Text('Original action: ${_controller.pending!.input.active ? 'Publish / update' : 'Pause'}'),
            Text('Exact original terms: ${_controller.pending!.input.toJson()['percentage'] == true
              ? '${_couponAmount(_controller.pending!.input.toJson()['discount'] as int)}% off'
              : '₹${_couponAmount(_controller.pending!.input.toJson()['discount'] as int)} off'} · '
              'minimum ₹${_couponAmount(_controller.pending!.input.toJson()['minimumSpendMinor'] as int)} · '
              'maximum saving ₹${_couponAmount(_controller.pending!.input.toJson()['maximumSavingMinor'] as int)}'),
            _couponValidityAndLimits(context, _controller.pending!.input),
            OutlinedButton.icon(onPressed: _reconcile, icon: const Icon(Icons.refresh),
              label: const Text('Check original coupon update')),
            CheckboxListTile(value: _funding, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) => setState(() => _funding = value == true),
              title: const Text('I confirm Store funding and retrying only that original coupon update.')),
            OutlinedButton(onPressed: _funding ? () async {
              await _controller.retryOriginal(fundingAcknowledged: true);
              if (_current) setState(() => _funding = false);
            } : null, child: const Text('Retry exact original update')),
          ] else ...[
            Text(!loaded ? 'Current server version has not been checked.' : record == null
              ? 'No saved server version. Your device draft is separate.'
              : '${record.input.active ? 'Active' : 'Paused'} settings on service · revision ${record.revision}\n${record.input.name}'),
            const SizedBox(height: 8),
            const Text('Published terms do not guarantee eligibility or savings. Checkout must confirm the actual discount; configured usage limits are not remaining uses.'),
            TextButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Check current coupon')),
            if (loaded) ...[
              CheckboxListTile(value: _funding, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) => setState(() => _funding = value == true),
                title: const Text('This Store funds the coupon savings. I confirm this update.')),
              FilledButton.icon(onPressed: _funding ? () => _submit(pause: false) : null,
                icon: const Icon(Icons.cloud_upload_outlined), label: Text(record == null ? 'Publish coupon terms' : 'Publish updated terms')),
              if (record?.input.active == true) OutlinedButton.icon(onPressed: _funding ? () => _submit(pause: true) : null,
                icon: const Icon(Icons.pause_circle_outline), label: const Text('Pause coupon')),
            ],
          ],
          if (_controller.message != null) Padding(padding: const EdgeInsets.only(top: 12),
            child: Text(_controller.message!, semanticsLabel: _controller.message)),
        ])));
  });
}

Widget _couponValidityAndLimits(BuildContext context, StoreCouponInput input) {
  final terms = input.toJson(), dates = MaterialLocalizations.of(context);
  final start = DateTime.parse(terms['startsAt'] as String).toLocal();
  final end = DateTime.parse(terms['endsAt'] as String).toLocal();
  String at(DateTime value) => '${dates.formatMediumDate(value)} ${dates.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
  return Text('Valid ${at(start)} – ${at(end)}\nConfigured limits: ${terms['totalUses']} total uses · ${terms['usesPerCustomer']} per customer');
}

String _couponAmount(int minor) => (minor / 100).toStringAsFixed(minor % 100 == 0 ? 0 : 2);
String _couponSaving(StoreCouponCampaign campaign) => campaign.percentage
    ? '${_couponAmount(campaign.discount)}% off · up to ₹${_couponAmount(campaign.maximumSavingMinor)}'
    : '₹${_couponAmount(campaign.discount)} off';

class _StoreCouponEditor extends StatefulWidget {
  const _StoreCouponEditor({required this.session, required this.storeId,
    required this.current, this.campaign});
  final WorkSession session;
  final String storeId;
  final bool Function() current;
  final StoreCouponCampaign? campaign;
  @override State<_StoreCouponEditor> createState() => _StoreCouponEditorState();
}

class _StoreCouponEditorState extends State<_StoreCouponEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _discount = TextEditingController(),
    _minimum = TextEditingController(), _maximum = TextEditingController(),
    _total = TextEditingController(), _perCustomer = TextEditingController();
  late final String _id = widget.campaign?.id ??
      'coupon-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
  bool _percentage = false, _saving = false, _dirty = false;
  DateTime? _from, _until;
  String? _error;
  StoreCouponCampaign? _unconfirmedAttempt;
  bool get _editingLocked => _saving || _unconfirmedAttempt != null;
  @override void initState() {
    super.initState();
    final c = widget.campaign;
    if (c != null) {
      _name.text = c.name; _percentage = c.percentage;
      _discount.text = _couponAmount(c.discount);
      _minimum.text = _couponAmount(c.minimumSpendMinor);
      _maximum.text = _couponAmount(c.maximumSavingMinor);
      _total.text = '${c.totalUses}'; _perCustomer.text = '${c.usesPerCustomer}';
      _from = c.startsAt.toLocal(); _until = c.endsAt.toLocal();
    }
  }
  @override void dispose() {
    for (final c in [_name, _discount, _minimum, _maximum, _total, _perCustomer]) { c.dispose(); }
    super.dispose();
  }
  int? _exact(String raw) {
    if (!RegExp(r'^\d{1,11}(\.\d{1,2})?$').hasMatch(raw.trim())) return null;
    final parts = raw.trim().split('.');
    return int.parse(parts[0]) * 100 + (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  }
  Future<void> _date(bool start) async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    final now = DateUtils.dateOnly(DateTime.now());
    final value = start ? _from : _until;
    final selected = await showDatePicker(context: context,
      firstDate: DateTime(now.year - 5), lastDate: DateTime(now.year + 5),
      initialDate: value ?? now);
    if (!mounted || !widget.current() || selected == null) return;
    setState(() {
      // End date is inclusive in the owner's local time, including after reopen.
      if (start) { _from = selected; }
      else { _until = DateTime(selected.year, selected.month, selected.day + 1)
        .subtract(const Duration(milliseconds: 1)); }
      _dirty = true;
    });
  }
  Future<void> _save() async {
    if (_saving || !widget.current()) return;
    if (_unconfirmedAttempt case final original?) {
      setState(() => _saving = true);
      final checked = await widget.session.loadWorkspaceOfferDraft(expectedStoreId: widget.storeId);
      if (!mounted) return;
      if (checked && widget.current()) {
        final saved = widget.session.workspaceStoreCouponCampaigns.where((c) => c.id == original.id).firstOrNull;
        if (saved != null && encodeStoreCouponCampaigns([saved]) == encodeStoreCouponCampaigns([original])) {
          setState(() { _dirty = false; _saving = false; }); Navigator.of(context).pop(); return;
        }
        setState(() { _saving = false; _unconfirmedAttempt = null;
          _error = 'Saved version checked. Your entries are kept; review them before saving again.'; });
      } else { setState(() { _saving = false;
        _error = 'The saved version could not be checked. Your entries are kept; no new save was sent.'; }); }
      return;
    }
    if (!_form.currentState!.validate()) return;
    if (_from == null || _until == null || !_until!.isAfter(_from!)) {
      setState(() => _error = 'Choose a start and end date in order.'); return;
    }
    final discount = _exact(_discount.text)!;
    StoreCouponCampaign campaign;
    try {
      campaign = StoreCouponCampaign(id: _id, storeId: widget.storeId,
        revision: (widget.campaign?.revision ?? 0) + 1, name: _name.text.trim(),
        percentage: _percentage, discount: discount,
        minimumSpendMinor: _exact(_minimum.text)!,
        maximumSavingMinor: _percentage ? _exact(_maximum.text)! : discount,
        startsAt: _from!, endsAt: _until!, totalUses: int.parse(_total.text.trim()),
        usesPerCustomer: int.parse(_perCustomer.text.trim()));
    } on FormatException catch (e) { setState(() => _error = e.message); return; }
    setState(() { _saving = true; _error = null; _unconfirmedAttempt = campaign; });
    final saved = await widget.session.saveWorkspaceStoreCouponCampaign(campaign,
      expectedStoreId: widget.storeId);
    if (!mounted) return;
    if (saved && widget.current()) { setState(() => _dirty = false); Navigator.of(context).pop(); }
    else { setState(() { _saving = false; _error = 'Save not confirmed. Your entries are kept. Check the saved version before trying again.'; }); }
  }
  Future<void> _close() async {
    if (_saving) return;
    if (_dirty) {
      final leave = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Leave unsaved changes?'),
        content: Text(_unconfirmedAttempt == null ? 'Your previously saved coupon will stay unchanged.' :
          'The last save is not confirmed. Reopen Store offers to check the saved version. Closing will leave this editor.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave'))]));
      if (leave != true || !mounted) return;
    }
    if (mounted) Navigator.of(context).pop();
  }
  Widget _field(String label, String key, TextEditingController controller,
      {bool integer = false, bool name = false, bool allowZero = false}) => Semantics(
    label: label, textField: true, child: TextFormField(
    key: Key(key), controller: controller,
    enabled: !_editingLocked && widget.current(),
    maxLength: name ? 80 : null,
    keyboardType: name ? TextInputType.text : TextInputType.numberWithOptions(decimal: !integer),
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(),
      helperText: allowZero ? 'Enter 0 for no minimum purchase.' : null),
    onChanged: (_) => setState(() => _dirty = true),
    validator: (raw) {
      final text = raw?.trim() ?? '';
      if (name) return text.isEmpty ? 'Enter a coupon name.' : null;
      final number = integer ? (RegExp(r'^\d{1,10}$').hasMatch(text) ? int.tryParse(text) : null) : _exact(text);
      if (number == null || number < (allowZero ? 0 : 1) || number > (integer ? 1000000000 : 9000000000000)) {
        return integer ? 'Enter a whole-number limit above 0.' : 'Enter a valid amount with up to 2 decimal places.';
      }
      if (key == 'work-coupon-discount' && _percentage && number > 10000) return 'Percentage cannot exceed 100.';
      return null;
    }));
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: widget.session,
    builder: (context, _) => PopScope(canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) unawaited(_close()); },
      child: Scaffold(backgroundColor: const Color(0xfff7f9fa),
        appBar: AppBar(automaticallyImplyLeading: false,
          title: Text(widget.campaign == null ? 'Create Store coupon' : 'Edit Store coupon'),
          actions: [IconButton(tooltip: 'Close coupon editor', onPressed: _saving ? null : _close,
            icon: const Icon(Icons.close))]),
        bottomNavigationBar: !widget.current() ? null : Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(key: const Key('work-coupon-save'), onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Please wait…' :
                _unconfirmedAttempt != null ? 'Check saved coupon' : 'Save coupon draft'))))),
        body: !widget.current() ? const Center(child: Text('Your Store session changed. Close and reopen this coupon.'))
          : Form(key: _form, child: ListView(key: const Key('work-coupon-editor'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const Text('ALL PRODUCTS IN THIS STORE', style: TextStyle(color: Color(0xff256b78), fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('One saving per eligible Store basket—not per product. Other Stores are unaffected.'),
              const SizedBox(height: 16),
              _field('Coupon name', 'work-coupon-name', _name, name: true),
              Wrap(spacing: 6, children: [for (final name in ['Diwali savings', 'Festive savings', 'New Year offer'])
                ActionChip(label: Text(name), onPressed: _editingLocked ? null : () => setState(() { _name.text = name; _dirty = true; }))]),
              const SizedBox(height: 12),
              SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('₹ off')),
                ButtonSegment(value: true, label: Text('% off'))], selected: {_percentage},
                onSelectionChanged: _editingLocked ? null : (value) => setState(() { _percentage = value.single; _discount.clear(); _dirty = true; })),
              const SizedBox(height: 12),
              _field(_percentage ? 'Discount (%)' : 'Discount (₹)', 'work-coupon-discount', _discount),
              const SizedBox(height: 12),
              _field('Minimum Store bill (₹)', 'work-coupon-minimum', _minimum, allowZero: true),
              if (_percentage) ...[const SizedBox(height: 12), _field('Maximum saving per bill (₹)', 'work-coupon-maximum', _maximum)],
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(key: const Key('work-coupon-start'), onPressed: _editingLocked ? null : () => _date(true),
                  icon: const Icon(Icons.event), label: Text(_from == null ? 'Start date' : 'From ${MaterialLocalizations.of(context).formatShortDate(_from!)}')),
                OutlinedButton.icon(key: const Key('work-coupon-end'), onPressed: _editingLocked ? null : () => _date(false),
                  icon: const Icon(Icons.event_available), label: Text(_until == null ? 'End date' : 'Until ${MaterialLocalizations.of(context).formatShortDate(_until!)}'))]),
              const SizedBox(height: 12),
              _field('Total permitted uses', 'work-coupon-total-uses', _total, integer: true),
              const SizedBox(height: 12),
              _field('Uses per customer', 'work-coupon-customer-uses', _perCustomer, integer: true),
              const SizedBox(height: 14),
              Text(widget.session.workspaceStoreCoupons == null
                ? 'These are your configured limits, not actual usage. Your Store funds the coupon. Public activation and Checkout confirmation are not connected yet.'
                : 'These are your configured limits, not actual usage. Your Store funds the coupon. Saving keeps a private draft; manage publishing separately. Checkout must confirm savings.',
                style: const TextStyle(fontSize: 12, color: Color(0xff566572), height: 1.4)),
              if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                child: Semantics(liveRegion: true, child: Text(_error!, style: const TextStyle(color: Color(0xff9c2737))))),
              const SizedBox(height: 12),
            ])))));
}

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
