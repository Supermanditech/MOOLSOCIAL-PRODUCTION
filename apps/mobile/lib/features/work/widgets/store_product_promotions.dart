import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../ui_v2/universal/mool_global_navigation_v2.dart' show moolAndroidExportedSemanticsClearance;
import '../work_catalogue_gateway.dart';
import '../work_models.dart';
import '../work_product_promotions.dart';
import '../work_session.dart';
import '../../buy/buy_v2_content_contracts.dart' show BuyV2AdvertisedBenefitTerms;
import '../../buy/buy_v2_models.dart' show BuyV2StoreOfferTerms, BuyV2StoreOfferSku, BuyV2StoreOfferTier, BuyV2StoreOfferKind;

InputDecoration _couponDecoration(BuildContext context, String label, {String? hint}) {
  final colors = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color) => OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color));
  return InputDecoration(labelText: label, hintText: hint, isDense: true,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(fontSize: 12), floatingLabelStyle: const TextStyle(fontSize: 12),
    errorStyle: const TextStyle(fontSize: 11), constraints: const BoxConstraints(minHeight: 48),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: border(colors.outlineVariant), enabledBorder: border(colors.outlineVariant), focusedBorder: border(colors.primary));
}
ButtonStyle _couponActionStyle(BuildContext context) => OutlinedButton.styleFrom(minimumSize: const Size(0, 48),
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600));
Widget _couponPair(BuildContext context, Widget first, Widget second, {double minimumWidth = 300}) =>
  LayoutBuilder(builder: (context, constraints) => constraints.maxWidth >= minimumWidth && MediaQuery.textScalerOf(context).scale(14) <= 18
    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: first), const SizedBox(width: 8), Expanded(child: second)])
    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [first, const SizedBox(height: 8), second]));

/// Raw values for the original coupon editor. No identity, funding or effect.
@immutable
class StoreCouponReviewInitial {
  StoreCouponReviewInitial._(this.values);
  final Map<String, Object?> values;
  static const allowedFields = {'name', 'kind', 'percentage', 'discount', 'minimumSpend',
    'maximumSaving', 'startsAt', 'endsAt', 'totalUses', 'usesPerCustomer', 'allProducts',
    'skuIds', 'channels', 'tiers', 'buyQuantity', 'rewardSkuId', 'rewardQuantity',
    'nextPurchaseDays', 'buyerIds'};
  factory StoreCouponReviewInitial.fromFields(Map<String, Object?> fields) {
    if (fields.isEmpty || fields.keys.any((key) => !allowedFields.contains(key))) {
      throw const FormatException('Supply the original coupon fields to review.');
    }
    final values = <String, Object?>{};
    for (final entry in fields.entries) {
      final key = entry.key, value = entry.value;
      if (const {'percentage', 'allProducts'}.contains(key)) {
        if (value is! bool) throw FormatException('Check $key.');
      } else if (const {'skuIds', 'buyerIds', 'channels'}.contains(key)) {
        if (value is! List || value.any((id) => id is! String || id.trim().isEmpty) ||
            value.toSet().length != value.length || (key != 'channels' && value.length > 1000) ||
            key == 'buyerIds' && value.any((id) => !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$').hasMatch(id as String)) ||
            key == 'channels' && (value.isEmpty || value.any((id) => !const {'retail','wholesale','bulk'}.contains(id)))) {
          throw FormatException('Use exact current $key selections.');
        }
        values[key] = List<String>.unmodifiable(value.cast<String>()); continue;
      } else if (key == 'tiers') {
        if (value is! List || value.isEmpty || value.length > 100) throw const FormatException('Check the native price slabs.');
        final tiers = value.map(BuyV2StoreOfferTier.fromJson).toList();
        var previous = 0;
        for (final tier in tiers) {
          if (tier.minimumQuantity <= previous || tier.minimumQuantity > 1000000000 ||
              tier.priceMinor <= 0 || tier.priceMinor > 9000000000000) throw const FormatException('Check increasing native slab quantities and prices.');
          previous = tier.minimumQuantity;
        }
        values[key] = List<BuyV2StoreOfferTier>.unmodifiable(tiers); continue;
      } else {
        if (value is! String || value.trim().isEmpty) throw FormatException('Supply $key from the original source.');
        if (key == 'name' && (value.trim().length > 80 || RegExp(r'[\x00-\x1f]').hasMatch(value))) throw const FormatException('Check the coupon name.');
        if (key == 'kind' && !BuyV2StoreOfferKind.values.any((kind) => kind.name == value)) throw const FormatException('Choose an existing native offer type.');
        if (const {'discount','minimumSpend','maximumSaving'}.contains(key)) {
          final amount = _couponInitialAmount(value);
          if (amount == null || amount < (key == 'minimumSpend' ? 0 : 1) || amount > 9000000000000) throw FormatException('Check $key with up to two decimal places.');
        }
        if (const {'totalUses','usesPerCustomer','buyQuantity','rewardQuantity','nextPurchaseDays'}.contains(key)) {
          final amount = RegExp(r'^\d{1,10}$').hasMatch(value.trim()) ? int.tryParse(value.trim()) : null;
          if (amount == null || amount < 1 || amount > (key == 'nextPurchaseDays' ? 365 : 1000000000)) throw FormatException('Check the native whole number for $key.');
        }
        if (key == 'startsAt' || key == 'endsAt') _couponInitialDate(value);
      }
      values[key] = value;
    }
    return StoreCouponReviewInitial._(Map.unmodifiable(values));
  }
  bool referencesCurrent(WorkSession session) {
    final store = session.activeWorkspace?.id;
    if (store == null) return false;
    final ids = [...?(values['skuIds'] as List<String>?), if (values['rewardSkuId'] case final String id) id];
    if (ids.isNotEmpty && session.localInventoryEnabled && !session.workspaceInventoryLoaded) return false;
    for (final id in ids) {
      final rows = session.workspaceCatalogueItems.where((item) => item.id == id).toList();
      if (rows.length != 1) return false;
      final item = rows.single;
      try {
        BuyV2StoreOfferSku(storeId: store, skuId: id,
          title: item.variant.isEmpty ? item.title : '${item.title} · ${item.variant}', sellUnit: item.pack);
      } on FormatException { return false; }
    }
    final buyers = values['buyerIds'] as List<String>? ?? const [];
    return buyers.every((id) => session.workspaceCustomerBook.where((buyer) => buyer.id == id).length == 1);
  }
  String? problemFor(StoreCouponCampaign? campaign) {
    final kindName = values['kind'] as String? ?? campaign?.structuredTerms?.kind.name ?? BuyV2StoreOfferKind.billDiscount.name;
    final kind = BuyV2StoreOfferKind.values.singleWhere((kind) => kind.name == kindName);
    final money = kind != BuyV2StoreOfferKind.quantityPrice && kind != BuyV2StoreOfferKind.extraQuantity;
    if (!money && const {'percentage','discount','maximumSaving'}.any(values.containsKey) ||
        values.containsKey('tiers') && kind != BuyV2StoreOfferKind.quantityPrice ||
        const {'buyQuantity','rewardSkuId','rewardQuantity'}.any(values.containsKey) && kind != BuyV2StoreOfferKind.extraQuantity ||
        values.containsKey('nextPurchaseDays') && kind != BuyV2StoreOfferKind.nextPurchase ||
        values.containsKey('buyerIds') && kind != BuyV2StoreOfferKind.buyerDiscount) {
      return 'Keep supplied fields with their original native offer type.';
    }
    if (values['allProducts'] == true && (values.containsKey('skuIds') || kind == BuyV2StoreOfferKind.productDiscount || !money)) {
      return 'Choose the exact native product scope.';
    }
    final percentage = values['percentage'] as bool? ?? campaign?.percentage ?? false;
    if (values.containsKey('maximumSaving') && !percentage) return 'Maximum saving belongs to the native percentage offer.';
    final discount = values['discount'] as String?;
    if (percentage && discount != null && _couponInitialAmount(discount)! > 10000) return 'Discount cannot exceed 100%.';
    final total = int.tryParse(values['totalUses'] as String? ?? '') ?? campaign?.totalUses ?? 100;
    final perCustomer = int.tryParse(values['usesPerCustomer'] as String? ?? '') ?? campaign?.usesPerCustomer ?? 1;
    if (perCustomer > total) return 'Check total uses and uses per buyer.';
    final startRaw = values['startsAt'] as String?, endRaw = values['endsAt'] as String?;
    final start = startRaw == null ? campaign?.startsAt : _couponInitialDate(startRaw);
    final end = endRaw == null ? campaign?.endsAt : _couponInitialDate(endRaw);
    if (start != null && end != null && !end.isAfter(start)) return 'Choose a start and end date in order.';
    return null;
  }
}

int? _couponInitialAmount(String raw) {
  if (!RegExp(r'^\d{1,11}(\.\d{1,2})?$').hasMatch(raw.trim())) return null;
  final parts = raw.trim().split('.');
  return int.parse(parts[0]) * 100 + (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
}

DateTime _couponInitialDate(String raw) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.\d{1,6})?)?(?:(Z)|([+-])(\d{2}):(\d{2}))?$').firstMatch(raw);
  final parsed = DateTime.tryParse(raw);
  if (match == null || parsed == null) throw const FormatException('Supply the exact source date and time.');
  final year = int.parse(match[1]!), month = int.parse(match[2]!), day = int.parse(match[3]!);
  final calendar = DateTime(year, month, day);
  if (calendar.year != year || calendar.month != month || calendar.day != day ||
      int.parse(match[4]!) > 23 || int.parse(match[5]!) > 59 || int.parse(match[6] ?? '0') > 59 ||
      int.parse(match[9] ?? '0') > 23 || int.parse(match[10] ?? '0') > 59) {
    throw const FormatException('Check the actual source date and time.');
  }
  return parsed.toLocal();
}

final _couponEditorOwners = <WorkSession, Set<Object>>{};
bool storeCouponNativeEditorOpen(WorkSession session) => _couponEditorOwners[session]?.isNotEmpty == true;

Future<bool> showStoreCouponEditorReview(BuildContext context, {required WorkSession session,
  required StoreCouponReviewInitial initial, StoreCouponCampaign? campaign,
  required Listenable owner, required bool Function() current, required bool Function() sourceCurrent}) async {
  final storeId = session.activeWorkspace?.id;
  if (storeId == null || !current() || !sourceCurrent() || !initial.referencesCurrent(session) || storeCouponNativeEditorOpen(session)) return false;
  var applied = false;
  await showModalBottomSheet<void>(context: context, isScrollControlled: true, isDismissible: false, enableDrag: false,
    useSafeArea: true, showDragHandle: false, builder: (_) => AnimatedBuilder(animation: owner, builder: (_, _) =>
      FractionallySizedBox(heightFactor: 1, child: _couponCapturedSurface(owner, current,
        _StoreCouponEditor(session: session, storeId: storeId,
          campaign: campaign, initial: initial, owner: owner, current: current, reviewSourceCurrent: sourceCurrent,
          onInitialApplied: () => applied = true)))));
  return applied;
}

Future<void> showStoreCouponPublicationReview(BuildContext context, {required WorkSession session,
  required StoreCouponCampaign campaign, required String operation, required Listenable owner,
  required bool Function() current}) async {
  final controller = session.workspaceStoreCoupons;
  if (!current()) return;
  final supported = controller != null && controller.active && controller.supports(StoreCouponInput.fromCampaign(campaign, active: true));
  await showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true,
    builder: (_) => _couponCapturedSurface(owner, current, supported
      ? _StoreCouponPublicationSheet(controller: controller, campaign: campaign, current: current, session: session, reviewOperation: operation, readOnlyOpen: true)
      : _couponReviewUnavailable(campaign, current, owner, operation: operation)));
}

Widget _couponCapturedSurface(Listenable changes, bool Function() current, Widget child) =>
  AnimatedBuilder(animation: changes, child: child, builder: (context, child) {
    final active = current();
    if (!active) WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && !current()) FocusScope.of(context).unfocus();
    });
    return Stack(children: [Offstage(offstage: !active, child: ExcludeFocus(excluding: !active, child: child!)),
      if (!active) SizedBox(height: MediaQuery.sizeOf(context).height * .6,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Your Store or request changed. Coupon input is kept.'),
          TextButton(key: const Key('work-coupon-owner-close'), onPressed: () {
            if (ModalRoute.of(context)?.isCurrent == true) Navigator.of(context).maybePop();
          }, child: const Text('Close')),
        ])),
    ]);
  });


Future<void> showStoreCouponsManager(BuildContext context, {required WorkSession session,
    required Listenable scopeOwner, required bool Function() isCurrent, String? initialQuery}) =>
  showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true,
    showDragHandle: false, builder: (context) => AnimatedBuilder(animation: scopeOwner,
      builder: (context, _) => SizedBox(height: MediaQuery.sizeOf(context).height * .94,
        child: Scaffold(appBar: AppBar(automaticallyImplyLeading: false, toolbarHeight: 48,
          title: const Text('Coupons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          actions: [IconButton(tooltip: 'Close coupons', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
          body: !isCurrent() ? const Center(child: Text('Your Store session changed. Close and reopen Coupons.'))
            : ListView(padding: const EdgeInsets.all(12), children: [StoreCouponCampaignPanel(
                session: session, scopeOwner: scopeOwner, isCurrent: isCurrent, initialQuery: initialQuery, showHeading: false)])))));

Widget _couponReviewUnavailable(StoreCouponCampaign campaign, bool Function() current, Listenable owner, {String? operation}) =>
  AnimatedBuilder(animation: owner, builder: (context, _) => ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
    child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [const Expanded(child: Text('Review coupon', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18))),
          IconButton(tooltip: 'Close coupon review', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
        if (!current()) const Text('Your Store or saved offer changed. Close and reopen this review.')
        else ...[
          Text(campaign.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(_couponSaving(campaign)),
          if (campaign.structuredTerms case final terms?)
            for (final line in terms.conditions) Padding(padding: const EdgeInsets.only(top: 6), child: Text(line))
          else Text('Minimum Store bill ₹${_couponAmount(campaign.minimumSpendMinor)}'),
          _couponValidityAndLimits(context, StoreCouponInput.fromCampaign(campaign, active: true)),
          const SizedBox(height: 12),
          const Text('Private draft · Public status unavailable. Publishing is not connected for these terms.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: null, child: Text(operation == 'pause' ? 'Pause' : 'Publish')),
        ],
      ]))));

/// Named, reusable Store-wide coupon drafts. Public activation is deliberately
/// not inferred from a device save or from an existing product advertisement.
class StoreCouponCampaignPanel extends StatefulWidget {
  const StoreCouponCampaignPanel({required this.session, this.scopeOwner, this.isCurrent, this.initialQuery, this.showHeading = true, super.key});
  final WorkSession session;
  final Listenable? scopeOwner;
  final bool Function()? isCurrent;
  final bool showHeading;
  final String? initialQuery;
  @override State<StoreCouponCampaignPanel> createState() => _StoreCouponCampaignPanelState();
}

class _StoreCouponCampaignPanelState extends State<StoreCouponCampaignPanel> {
  final _search = TextEditingController();
  late final String? _storeId;
  late final int? _epoch;
  late final Map<String, String> _original;
  bool _loading = true, _ready = false, _retryingDraft = false;
  StoreCouponDraftSyncController? _draftSync;
  @override void dispose() { _search.dispose(); super.dispose(); }
  late final Listenable _owner = Listenable.merge([widget.session, if (widget.scopeOwner != null) widget.scopeOwner!]);
  bool get _current => mounted && _epoch != null && widget.session.activeWorkspace?.id == _storeId &&
      widget.session.navigationScopeRevision == _epoch &&
      (widget.isCurrent?.call() ?? true) &&
      identical(widget.session.workspaceOfferDraft, _original);
  @override void initState() {
    super.initState();
    _search.text = widget.initialQuery ?? '';
    _storeId = widget.session.activeWorkspace?.id;
    _epoch = widget.session.navigationScopeRevision;
    _original = widget.session.workspaceOfferDraft;
    _load();
  }
  Future<void> _load() async {
    if (_storeId == null) return;
    setState(() => _loading = true);
    final ready = await widget.session.loadWorkspaceOfferDraft(expectedStoreId: _storeId);
    if (_current && ready) {
      _draftSync = widget.session.workspaceCouponDraftSync;
      // Native manager entry may inspect the retained journal. It never sends
      // a save, reconciles status or adopts an online campaign on opening.
      await _draftSync?.restore();
    }
    if (_current) setState(() { _loading = false; _ready = ready; });
  }
  Future<void> _checkDraftSave() async {
    final sync = _draftSync;
    if (!_current || sync == null || !sync.active || sync.busy || _retryingDraft) return;
    if (!await sync.restore() || !_current || !sync.active) return;
    if (sync.pending != null) await sync.reconcile();
    if (_current) setState(() {});
  }
  Future<void> _retryDraftSave() async {
    final sync = _draftSync, original = _draftSync?.pending;
    if (!_current || sync == null || !sync.active || !sync.ready || sync.busy || original == null || _retryingDraft) return;
    setState(() => _retryingDraft = true);
    bool sameOriginal() => _current && sync.active && sync.ready && !sync.busy &&
      sync.pending?.fingerprint == original.fingerprint;
    try {
      final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AnimatedBuilder(
        animation: _owner, builder: (_, _) => AlertDialog(scrollable: true, title: const Text('Retry saved draft?'),
          content: Text(sameOriginal()
            ? 'Retry the earlier saved copy of “${original.campaign.name}”? Later edits stay on this device. This does not publish it.'
            : 'The saved draft or Store access changed. Reopen Coupons to continue.'),
          actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')),
            FilledButton(onPressed: sameOriginal() ? () => Navigator.pop(dialog, true) : null,
              child: const Text('Retry original save'))])));
      if (confirmed == true && sameOriginal()) await sync.retryOriginal(confirmedOriginal: true);
    } finally {if (mounted) setState(() => _retryingDraft = false);}
  }
  Future<void> _edit([StoreCouponCampaign? campaign]) async {
    if (!_current || !_ready || widget.session.workspaceOfferDraftSaving) return;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      isDismissible: false, enableDrag: false,
      useSafeArea: true, showDragHandle: false, builder: (_) => AnimatedBuilder(animation: _owner, builder: (context, _) => FractionallySizedBox(heightFactor: 1,
        child: _StoreCouponEditor(session: widget.session, storeId: _storeId!,
          campaign: campaign, owner: _owner, current: () => _current))));
    if (_current) setState(() {});
  }
  Future<void> _publication(StoreCouponCampaign campaign) async {
    final controller = widget.session.workspaceStoreCoupons;
    if (!_current || !_ready) return;
    bool current() => _current && widget.session.workspaceStoreCouponCampaigns.any((saved) =>
      saved.id == campaign.id && saved.revision == campaign.revision &&
      StoreCouponInput.fromCampaign(saved, active: true).fingerprint == StoreCouponInput.fromCampaign(campaign, active: true).fingerprint);
    final supported = controller != null && controller.supports(StoreCouponInput.fromCampaign(campaign, active: true));
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => AnimatedBuilder(animation: _owner, builder: (context, _) => supported
        ? _StoreCouponPublicationSheet(controller: controller, campaign: campaign, current: current, session: widget.session)
        : _couponReviewUnavailable(campaign, current, _owner)));
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _owner, builder: (context, _) {
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
      final query = _search.text.trim().toLowerCase();
      final visible = campaigns.where((campaign) => query.isEmpty ||
        '${campaign.name} ${campaign.structuredTerms?.kind.label ?? ''} ${campaign.structuredTerms?.scopeLabel ?? ''} '
        '${campaign.structuredTerms?.skus.map((sku) => '${sku.title} ${sku.skuId}').join(' ') ?? ''}'
          .toLowerCase().contains(query)).toList();
      final publisher = widget.session.workspaceStoreCoupons;
      final draftSync = _draftSync;
      return Column(key: const Key('work-store-coupons'),
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _couponPair(context, Text(widget.showHeading ? 'Store coupons' : '${campaigns.length} saved',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          FilledButton.icon(key: const Key('work-coupon-create'), style: _couponActionStyle(context),
            onPressed: widget.session.workspaceOfferDraftSaving ? null : () => _edit(),
            icon: const Icon(Icons.add, size: 18), label: const Text('New coupon'))),
          const SizedBox(height: 6),
          Text(publisher == null ? 'Private drafts · Publishing unavailable.' : 'Save your draft, then review publishing.',
            style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xff566572))),
          if (draftSync?.active == true && (!draftSync!.ready || draftSync.pending != null)) ...[
            const SizedBox(height: 6),
            const Text('The earlier online draft save is unconfirmed. Your device draft is kept.',
              key: Key('work-coupon-draft-save-status'), style: TextStyle(fontSize: 12, height: 1.4)),
            Wrap(spacing: 8, children: [
              TextButton.icon(onPressed: draftSync.busy || _retryingDraft ? null : _checkDraftSave,
                icon: const Icon(Icons.refresh, size: 18), label: const Text('Check draft save')),
              if (draftSync.pending != null) TextButton.icon(
                onPressed: !draftSync.ready || draftSync.busy || _retryingDraft ? null : _retryDraftSave,
                icon: const Icon(Icons.sync, size: 18), label: const Text('Retry original save')),
            ]),
          ],
          if (campaigns.length > 4 || _search.text.isNotEmpty) TextField(key: const Key('work-coupon-search'), controller: _search, onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14), decoration: _couponDecoration(context, 'Search coupons', hint: 'Name or selected product')
              .copyWith(prefixIcon: const Icon(Icons.search, size: 20))),
          if (campaigns.isNotEmpty && visible.isEmpty) const Text('No matching coupons.'),
          for (final campaign in visible) ListTile(
            key: ValueKey('work-coupon-${campaign.id}'), contentPadding: EdgeInsets.zero, dense: true,
            leading: const Icon(Icons.confirmation_number_outlined, color: Color(0xff256b78)),
            title: Text(campaign.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('${campaign.structuredTerms?.kind.label ?? 'Bill discount'} · ${_couponSaving(campaign)}\n${campaign.structuredTerms?.scopeLabel ?? 'Store-wide'} · Draft',
              style: const TextStyle(fontSize: 11)),
            isThreeLine: true,
            onTap: () => _publication(campaign),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(tooltip: 'Manage publishing for ${campaign.name}',
                onPressed: () => _publication(campaign), icon: const Icon(Icons.cloud_upload_outlined)),
              IconButton(tooltip: 'Edit ${campaign.name}',
              onPressed: widget.session.workspaceOfferDraftSaving ? null : () => _edit(campaign),
              icon: const Icon(Icons.edit_outlined))])),
          const SizedBox(height: 18),
        ]);
    });
}

class _StoreCouponPublicationSheet extends StatefulWidget {
  const _StoreCouponPublicationSheet({required this.controller, required this.campaign, required this.current, this.session, this.reviewOperation, this.readOnlyOpen = false});
  final WorkSession? session;
  final String? reviewOperation;
  final bool readOnlyOpen;
  final StoreCouponController controller;
  final StoreCouponCampaign campaign;
  final bool Function() current;
  @override State<_StoreCouponPublicationSheet> createState() => _StoreCouponPublicationSheetState();
}
class _StoreCouponPublicationSheetState extends State<_StoreCouponPublicationSheet> {
  bool _funding = false;
  StoreCouponController get _controller => widget.controller;
  bool get _current => mounted && widget.current() && _controller.active;
  final _ownerToken = Object();
  @override void initState() {
    super.initState();
    if (widget.session case final source?) _couponEditorOwners.putIfAbsent(source, () => {}).add(_ownerToken);
    if (!widget.readOnlyOpen || _controller.loadedCouponId != widget.campaign.id) unawaited(_refresh());
  }
  @override void dispose() {
    if (widget.session case final source?) {
      _couponEditorOwners[source]?.remove(_ownerToken);
      if (_couponEditorOwners[source]?.isEmpty == true) _couponEditorOwners.remove(source);
    }
    super.dispose();
  }
  Future<void> _refresh() async {
    if (!_current) return;
    setState(() => _funding = false);
    await _controller.refresh(widget.campaign.id, inputCurrent: () => _current);
  }
  Future<void> _reconcile() async {
    if (!_current) return;
    setState(() => _funding = false);
    await _controller.reconcile(inputCurrent: () => _current);
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
          const SizedBox(height: 6), Text(_couponSaving(widget.campaign)),
          if (widget.campaign.structuredTerms case final terms?)
            for (final line in terms.conditions) Text(line)
          else Text('Minimum Store bill ₹${_couponAmount(widget.campaign.minimumSpendMinor)}'),
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
            if (_controller.pending!.input.structured) ...[
              Text('Original offer: ${BuyV2StoreOfferTerms.fromJson(_controller.pending!.input.toJson()['structuredTerms']).savingLabel}'),
              for (final line in BuyV2StoreOfferTerms.fromJson(_controller.pending!.input.toJson()['structuredTerms']).conditions) Text(line),
            ] else Text('Exact original terms: ${_controller.pending!.input.toJson()['percentage'] == true
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
              if (!_current || !_funding || _controller.busy) return;
              await _controller.retryOriginal(fundingAcknowledged: true, inputCurrent: () => _current);
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
              if (widget.reviewOperation != 'pause') FilledButton.icon(onPressed: _funding ? () => _submit(pause: false) : null,
                icon: const Icon(Icons.cloud_upload_outlined), label: Text(record == null ? 'Publish coupon terms' : 'Publish updated terms')),
              if (widget.reviewOperation != 'publish' && record?.input.active == true) OutlinedButton.icon(onPressed: _funding ? () => _submit(pause: true) : null,
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
String _couponSaving(StoreCouponCampaign campaign) => campaign.structuredTerms?.savingLabel ?? (campaign.percentage
    ? '${_couponAmount(campaign.discount)}% off · up to ₹${_couponAmount(campaign.maximumSavingMinor)}'
    : '₹${_couponAmount(campaign.discount)} off');

class _StoreCouponEditor extends StatefulWidget {
  const _StoreCouponEditor({required this.session, required this.storeId,
    required this.current, required this.owner, this.campaign, this.initial, this.reviewSourceCurrent, this.onInitialApplied});
  final StoreCouponReviewInitial? initial;
  final bool Function()? reviewSourceCurrent;
  final VoidCallback? onInitialApplied;
  final WorkSession session;
  final String storeId;
  final bool Function() current;
  final Listenable owner;
  final StoreCouponCampaign? campaign;
  @override State<_StoreCouponEditor> createState() => _StoreCouponEditorState();
}

class _StoreCouponEditorState extends State<_StoreCouponEditor> {
  final _form = GlobalKey<FormState>();
  final _ownerToken = Object();
  bool get _current => mounted && widget.current() &&
    (_unconfirmedAttempt != null || widget.reviewSourceCurrent?.call() != false);
  final _nameFocus = FocusNode();
  List<String> get _nameExamples => ['Diwali offer', 'Holi offer', switch (_kind) {
    BuyV2StoreOfferKind.quantityPrice => 'Bulk savings',
    BuyV2StoreOfferKind.nextPurchase => 'Shop again offer',
    BuyV2StoreOfferKind.buyerDiscount => 'Preferred buyer offer',
    BuyV2StoreOfferKind.dealerIntro => 'Dealer welcome',
    BuyV2StoreOfferKind.extraQuantity => 'Extra quantity offer',
    BuyV2StoreOfferKind.productDiscount => 'Product savings',
    BuyV2StoreOfferKind.billDiscount => 'Store savings',
  }];
  final _name = TextEditingController(), _discount = TextEditingController(),
    _minimum = TextEditingController(), _maximum = TextEditingController(),
    _total = TextEditingController(), _perCustomer = TextEditingController();
  final _buyQuantity = TextEditingController(), _rewardQuantity = TextEditingController(),
    _nextDays = TextEditingController(text: '30');
  BuyV2StoreOfferKind _kind = BuyV2StoreOfferKind.billDiscount;
  bool _structuredEditing = false, _allProducts = true;
  final _skuIds = <String>{}, _buyerIds = <String>{};
  final _retainedSkus = <String, BuyV2StoreOfferSku>{};
  final _channels = <String>{'retail', 'wholesale', 'bulk'};
  List<BuyV2StoreOfferTier> _tiers = const [];
  BuyV2StoreOfferSku? _retainedReward;
  String? _rewardId;
  bool get _money => _kind != BuyV2StoreOfferKind.quantityPrice && _kind != BuyV2StoreOfferKind.extraQuantity;
  late final String _id = widget.campaign?.id ??
      'coupon-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
  bool _percentage = false, _saving = false, _dirty = false;
  DateTime? _from, _until;
  String? _error;
  StoreCouponCampaign? _unconfirmedAttempt;
  bool get _editingLocked => _saving || _unconfirmedAttempt != null;
  @override void initState() {
    super.initState();
    _couponEditorOwners.putIfAbsent(widget.session, () => {}).add(_ownerToken);
    final c = widget.campaign;
    if (c != null) {
      _name.text = c.name; _percentage = c.percentage;
      _discount.text = _couponAmount(c.discount);
      _minimum.text = _couponAmount(c.minimumSpendMinor);
      _maximum.text = _couponAmount(c.maximumSavingMinor);
      _total.text = '${c.totalUses}'; _perCustomer.text = '${c.usesPerCustomer}';
      _from = c.startsAt.toLocal(); _until = c.endsAt.toLocal();
      if (c.structuredTerms case final terms?) {
        _structuredEditing = true; _kind = terms.kind; _allProducts = terms.skus.isEmpty;
        _skuIds.addAll(terms.skus.map((sku) => sku.skuId));
        _retainedSkus.addEntries(terms.skus.map((sku) => MapEntry(sku.skuId, sku)));
        _channels..clear()..addAll(terms.channels); _buyerIds.addAll(c.buyerReferences);
        _tiers = terms.tiers; _retainedReward = terms.rewardSku; _rewardId = terms.rewardSku?.skuId;
        _buyQuantity.text = terms.buyQuantity?.toString() ?? '';
        _rewardQuantity.text = terms.rewardQuantity?.toString() ?? '';
        _nextDays.text = '${terms.nextPurchaseDays ?? 30}';
        if (!terms.hasMonetaryDiscount) { _discount.clear(); _maximum.clear(); }
      }
    } else {
      _minimum.text = '0'; _total.text = '100'; _perCustomer.text = '1';
    }
    if (widget.initial case final initial?) {
      // Source/actor may retire between route push and its first native build.
      if (!_current || !initial.referencesCurrent(widget.session)) return;
      final values = initial.values;
      final fields = {'name': _name, 'discount': _discount, 'minimumSpend': _minimum,
        'maximumSaving': _maximum, 'totalUses': _total, 'usesPerCustomer': _perCustomer,
        'buyQuantity': _buyQuantity, 'rewardQuantity': _rewardQuantity, 'nextPurchaseDays': _nextDays};
      for (final entry in fields.entries) {
        if (values[entry.key] case final String raw) entry.value.text = raw;
      }
      if (values['kind'] case final String kind) {
        _kind = BuyV2StoreOfferKind.values.singleWhere((value) => value.name == kind);
        if (_kind == BuyV2StoreOfferKind.productDiscount || !_money) _allProducts = false;
      }
      if (values['percentage'] case final bool value) _percentage = value;
      if (values['startsAt'] case final String raw) _from = _couponInitialDate(raw);
      if (values['endsAt'] case final String raw) _until = _couponInitialDate(raw);
      if (values['allProducts'] case final bool value) _allProducts = value;
      if (values['skuIds'] case final List<String> ids) { _skuIds..clear()..addAll(ids); _allProducts = false; }
      if (values['buyerIds'] case final List<String> ids) _buyerIds..clear()..addAll(ids);
      if (values['channels'] case final List<String> channels) _channels..clear()..addAll(channels);
      if (values['tiers'] case final List<BuyV2StoreOfferTier> tiers) _tiers = tiers;
      if (values['rewardSkuId'] case final String id) _rewardId = id;
      for (final id in {...?(values['skuIds'] as List<String>?), if (values['rewardSkuId'] case final String id) id}) {
        final item = widget.session.workspaceCatalogueItems.singleWhere((item) => item.id == id);
        final old = _retainedSkus[id] ?? (_retainedReward?.skuId == id ? _retainedReward : null);
        final ref = BuyV2StoreOfferSku(storeId: widget.storeId, skuId: id,
          title: item.variant.isEmpty ? item.title : '${item.title} · ${item.variant}', sellUnit: item.pack,
          listings: old?.sellUnit == item.pack ? old!.listings : const []);
        _retainedSkus[id] = ref;
        if (_rewardId == id) _retainedReward = ref;
      }
      if (values.keys.any((key) => const {'kind','allProducts','skuIds','buyerIds','channels','tiers',
          'buyQuantity','rewardSkuId','rewardQuantity','nextPurchaseDays'}.contains(key))) _structuredEditing = true;
      // Supplied values are unsaved native input, protected by original Leave.
      _dirty = true;
      widget.onInitialApplied?.call();
    }
  }
  @override void dispose() {
    _couponEditorOwners[widget.session]?.remove(_ownerToken);
    if (_couponEditorOwners[widget.session]?.isEmpty == true) _couponEditorOwners.remove(widget.session);
    _nameFocus.dispose();
    for (final c in [_name, _discount, _minimum, _maximum, _total, _perCustomer,
      _buyQuantity, _rewardQuantity, _nextDays]) { c.dispose(); }
    super.dispose();
  }
  int? _exact(String raw) => _couponInitialAmount(raw);
  BuyV2StoreOfferSku _sku(String id) {
    final rows = widget.session.workspaceCatalogueItems.where((item) => item.id == id);
    if (rows.length != 1) throw const FormatException('A selected product is unavailable. Review the product selection.');
    final item = rows.single, retained = _retainedSkus[id] ?? (_retainedReward?.skuId == id ? _retainedReward : null);
    if (retained != null && retained.sellUnit != item.pack) {
      throw const FormatException('Selling unit changed. Re-select the product and review quantities and prices.');
    }
    return BuyV2StoreOfferSku(storeId: widget.storeId, skuId: item.id,
      title: item.variant.isEmpty ? item.title : '${item.title} · ${item.variant}', sellUnit: item.pack,
      listings: retained?.sellUnit == item.pack ? retained!.listings : const []);
  }
  Future<Set<String>?> _chooseReferences({required String title,
      required List<({String id, String name, String detail, bool available})> rows,
      required Set<String> initial, bool single = false}) async {
    var query = ''; final selected = Set<String>.of(initial);
    return showModalBottomSheet<Set<String>>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: false,
      builder: (context) => StatefulBuilder(builder: (context, update) => AnimatedBuilder(animation: widget.owner,
        builder: (context, _) => SizedBox(height: MediaQuery.sizeOf(context).height * .9,
          child: Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom +
            (defaultTargetPlatform == TargetPlatform.android && View.of(context).viewInsets.bottom == 0
              ? max(36.0, moolAndroidExportedSemanticsClearance(
                  viewPadding: EdgeInsets.fromViewPadding(View.of(context).viewPadding, View.of(context).devicePixelRatio),
                  platform: defaultTargetPlatform)) : 0)),
            child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
                IconButton(tooltip: 'Close selection', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
              if (!_current) const Expanded(child: Center(child: Text('Your Store session changed. Reopen this selection.')))
              else ...[
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: TextField(
                  key: const Key('work-coupon-reference-search'), style: const TextStyle(fontSize: 14),
                  decoration: _couponDecoration(context, 'Search', hint: title == 'Eligible buyers' ? 'Buyer name or phone' : 'Product name or SKU')
                    .copyWith(prefixIcon: const Icon(Icons.search, size: 20)),
                  onChanged: (value) => update(() => query = value.trim().toLowerCase()))),
                Expanded(child: Builder(builder: (context) {
                  final visible = rows.where((row) => '${row.name} ${row.detail} ${row.id}'.toLowerCase().contains(query)).toList();
                  if (visible.isEmpty) return const Center(child: Text('No matching records.'));
                  return ListView.builder(itemCount: visible.length, itemBuilder: (context, index) {
                    final row = visible[index];
                    return CheckboxListTile(value: selected.contains(row.id), controlAffinity: ListTileControlAffinity.leading,
                      dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      title: Text(row.name, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(row.available ? row.detail : 'Saved selection unavailable · tap to remove', style: const TextStyle(fontSize: 12)),
                      onChanged: !_current || !row.available && !selected.contains(row.id) ? null : (checked) => update(() {
                        if (checked == true) { if (single) selected.clear(); selected.add(row.id); }
                        else { selected.remove(row.id); }
                      }));
                  });
                })),
                Padding(padding: const EdgeInsets.all(12), child: FilledButton(style: _couponActionStyle(context),
                  onPressed: () { if (_current) Navigator.pop(context, selected); }, child: const Text('Use selection'))),
              ],
            ])))))));
  }
  Future<void> _pickProducts({bool reward = false}) async {
    final items = widget.session.workspaceCatalogueItems;
    final currentIds = items.map((item) => item.id).toSet();
    final retained = {..._retainedSkus, if (_retainedReward != null) _retainedReward!.skuId: _retainedReward!};
    final rows = <({String id, String name, String detail, bool available})>[
      for (final item in items) (id: item.id, name: item.title, detail: '${item.pack} · ${item.sku}', available: true),
      for (final entry in retained.entries) if (!currentIds.contains(entry.key))
        (id: entry.key, name: entry.value.title, detail: entry.value.sellUnit, available: false),
    ];
    final result = await _chooseReferences(title: reward ? 'Additional product' : 'Eligible products', rows: rows,
      initial: reward ? {if (_rewardId != null) _rewardId!} : _skuIds,
      single: reward || !_money);
    if (!mounted || !_current || result == null) return;
    setState(() { _dirty = true; _structuredEditing = true;
      BuyV2StoreOfferSku? selectedRef(String id) {
        final item = items.where((item) => item.id == id).firstOrNull;
        if (item == null) return null;
        final old = retained[id];
        return BuyV2StoreOfferSku(storeId: widget.storeId, skuId: id,
          title: item.variant.isEmpty ? item.title : '${item.title} · ${item.variant}', sellUnit: item.pack,
          listings: old?.sellUnit == item.pack ? old!.listings : const []);
      }
      if (reward) {
        final next = result.firstOrNull, nextRef = next == null ? null : selectedRef(next);
        if (next != _rewardId || nextRef?.sellUnit != _retainedReward?.sellUnit) _rewardQuantity.clear();
        _rewardId = next; _retainedReward = nextRef;
      } else {
        final changed = !setEquals(result, _skuIds) || result.any((id) =>
          retained[id] != null && selectedRef(id)?.sellUnit != retained[id]!.sellUnit);
        if (!_money && changed) { _tiers = const []; _buyQuantity.clear(); _rewardQuantity.clear(); }
        for (final id in result) { final value = selectedRef(id); if (value != null) _retainedSkus[id] = value; }
        _skuIds..clear()..addAll(result); _allProducts = false;
      }
    });
  }
  Future<void> _pickBuyers() async {
    final buyers = widget.session.workspaceCustomerBook;
    final ids = buyers.map((buyer) => buyer.id).toSet();
    final rows = <({String id, String name, String detail, bool available})>[
      for (final buyer in buyers) (id: buyer.id, name: buyer.name, detail: buyer.mobile, available: true),
      for (final id in _buyerIds) if (!ids.contains(id)) (id: id, name: 'Unavailable saved buyer', detail: id, available: false),
    ];
    final result = await _chooseReferences(title: 'Eligible buyers', rows: rows, initial: _buyerIds);
    if (!mounted || !_current || result == null) return;
    setState(() { _buyerIds..clear()..addAll(result); _dirty = true; _structuredEditing = true; });
  }
  Future<void> _editTiers() async {
    final unit = _skuIds.length == 1 ? widget.session.workspaceCatalogueItems
      .where((item) => item.id == _skuIds.single).firstOrNull?.pack : null;
    if (unit == null) { setState(() => _error = 'Select one selling SKU before adding price slabs.'); return; }
    final result = await showModalBottomSheet<List<BuyV2StoreOfferTier>>(context: context,
      isScrollControlled: true, useSafeArea: true, isDismissible: false, enableDrag: false, showDragHandle: false,
      builder: (_) => _StoreOfferTierEditor(initial: _tiers, sellUnit: unit, owner: widget.owner, current: () => _current));
    if (!mounted || !_current || result == null) return;
    setState(() { _tiers = result; _dirty = true; _structuredEditing = true; });
  }
  BuyV2StoreOfferTerms _terms() {
    if (_channels.isEmpty) throw const FormatException('Choose at least one selling mode.');
    if (!_allProducts && _skuIds.isEmpty) throw const FormatException('Select the eligible products.');
    if (_kind == BuyV2StoreOfferKind.buyerDiscount) {
      final ids = widget.session.workspaceCustomerBook.map((buyer) => buyer.id).toSet();
      if (_buyerIds.isEmpty || !_buyerIds.every(ids.contains)) throw const FormatException('Review the selected buyers.');
    }
    return BuyV2StoreOfferTerms(storeId: widget.storeId, kind: _kind,
      skus: _allProducts ? const [] : _skuIds.map(_sku), channels: _channels,
      discountKind: _money ? _percentage ? 'percentage' : 'flat' : null,
      discountValue: _money ? _exact(_discount.text) : null,
      minimumSpendMinor: _exact(_minimum.text) ?? 0,
      maximumSavingMinor: _money ? _percentage ? _exact(_maximum.text) : _exact(_discount.text) : null,
      tiers: _kind == BuyV2StoreOfferKind.quantityPrice ? _tiers : const [],
      buyQuantity: _kind == BuyV2StoreOfferKind.extraQuantity ? int.tryParse(_buyQuantity.text) : null,
      rewardSku: _kind == BuyV2StoreOfferKind.extraQuantity && _rewardId != null ? _sku(_rewardId!) : null,
      rewardQuantity: _kind == BuyV2StoreOfferKind.extraQuantity ? int.tryParse(_rewardQuantity.text) : null,
      nextPurchaseDays: _kind == BuyV2StoreOfferKind.nextPurchase ? int.tryParse(_nextDays.text) : null);
  }
  Future<void> _date(bool start) async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    final now = DateUtils.dateOnly(DateTime.now());
    final value = start ? _from : _until;
    final selected = await showDatePicker(context: context,
      builder: widget.initial == null ? null : (_, child) => _couponCapturedSurface(widget.owner, () => _current, child!),
      firstDate: DateTime(now.year - 5), lastDate: DateTime(now.year + 5),
      initialDate: value ?? now);
    if (!mounted || !_current || selected == null) return;
    DateTime? exact;
    if (_kind == BuyV2StoreOfferKind.quantityPrice) {
      final time = await showTimePicker(context: context,
        builder: widget.initial == null ? null : (_, child) => _couponCapturedSurface(widget.owner, () => _current, child!),
        initialTime: value == null ? TimeOfDay(hour: start ? 0 : 23, minute: start ? 0 : 59)
          : TimeOfDay.fromDateTime(value));
      if (!mounted || !_current || time == null) return;
      exact = DateTime(selected.year, selected.month, selected.day, time.hour, time.minute);
    }
    setState(() {
      // End date is inclusive in the owner's local time, including after reopen.
      if (exact != null) { if (start) { _from = exact; } else { _until = exact; } }
      else if (start) { _from = selected; }
      else { _until = DateTime(selected.year, selected.month, selected.day + 1)
        .subtract(const Duration(milliseconds: 1)); }
      _dirty = true;
    });
  }
  Future<void> _save() async {
    if (_saving || !_current) return;
    if (_unconfirmedAttempt case final original?) {
      setState(() => _saving = true);
      final checked = await widget.session.loadWorkspaceOfferDraft(expectedStoreId: widget.storeId);
      if (!mounted) return;
      if (checked && _current) {
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
    final problem = _inputProblem;
    if (problem != null) {
      _form.currentState!.validate();
      setState(() => _error = problem); return;
    }
    if (!_form.currentState!.validate()) return;
    if (_from == null || _until == null || !_until!.isAfter(_from!)) {
      setState(() => _error = 'Choose a start and end date in order.'); return;
    }
    StoreCouponCampaign campaign;
    try {
      campaign = _structuredEditing ? StoreCouponCampaign.offer(id: _id, storeId: widget.storeId,
        revision: (widget.campaign?.revision ?? 0) + 1, name: _name.text.trim(), structuredTerms: _terms(),
        buyerReferences: _kind == BuyV2StoreOfferKind.buyerDiscount ? _buyerIds : const [],
        startsAt: _from!, endsAt: _until!, totalUses: int.parse(_total.text.trim()),
        usesPerCustomer: int.parse(_perCustomer.text.trim())) : StoreCouponCampaign(id: _id, storeId: widget.storeId,
        revision: (widget.campaign?.revision ?? 0) + 1, name: _name.text.trim(),
        percentage: _percentage, discount: _exact(_discount.text)!,
        minimumSpendMinor: _exact(_minimum.text)!,
        maximumSavingMinor: _percentage ? _exact(_maximum.text)! : _exact(_discount.text)!,
        startsAt: _from!, endsAt: _until!, totalUses: int.parse(_total.text.trim()),
        usesPerCustomer: int.parse(_perCustomer.text.trim()));
    } on FormatException catch (e) { setState(() => _error = e.message); return; }
    setState(() { _saving = true; _error = null; _unconfirmedAttempt = campaign; });
    final saved = await widget.session.saveWorkspaceStoreCouponCampaign(campaign,
      expectedStoreId: widget.storeId);
    if (!mounted) return;
    if (saved && _current) { setState(() => _dirty = false); Navigator.of(context).pop(); }
    else { setState(() { _saving = false; _error = 'Save not confirmed. Your entries are kept. Check the saved version before trying again.'; }); }
  }
  Future<void> _close() async {
    if (_saving) return;
    if (_dirty) {
      final leave = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Leave unsaved changes?'),
        content: Text(_unconfirmedAttempt != null
          ? 'The last save is not confirmed. Reopen Store offers to check the saved version. Closing will leave this editor.'
          : widget.campaign == null
            ? 'This coupon has not been saved. Leave without saving it?'
            : 'Your previously saved coupon will stay unchanged.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave'))]));
      if (leave != true || !mounted) return;
    }
    if (mounted) Navigator.of(context).pop();
  }
  String? _entryError(String raw, {bool integer = false, bool name = false, bool allowZero = false}) {
    final text = raw.trim();
    if (name) return text.isEmpty ? 'Enter a coupon name.' : null;
    final number = integer ? (RegExp(r'^\d{1,10}$').hasMatch(text) ? int.tryParse(text) : null) : _exact(text);
    if (number == null || number < (allowZero ? 0 : 1) || number > (integer ? 1000000000 : 9000000000000)) {
      return integer ? 'Enter a whole number above 0.' : 'Enter an amount with up to 2 decimal places.';
    }
    return null;
  }
  String? get _inputProblem {
    String? first;
    void check(String label, TextEditingController value, {bool integer = false, bool name = false, bool zero = false}) {
      final error = _entryError(value.text, integer: integer, name: name, allowZero: zero);
      if (first == null && error != null) first = '$label: $error';
    }
    check('Name', _name, name: true);
    if (_money) {
      check('Discount', _discount);
      if (_percentage && (_exact(_discount.text) ?? 0) > 10000) first ??= 'Discount cannot exceed 100%.';
      if (_percentage) check('Maximum saving', _maximum);
    }
    check('Minimum purchase', _minimum, zero: true);
    if (_kind == BuyV2StoreOfferKind.extraQuantity) {
      check('Buy quantity', _buyQuantity, integer: true); check('Extra quantity', _rewardQuantity, integer: true);
    }
    if (_kind == BuyV2StoreOfferKind.nextPurchase) check('Next-purchase days', _nextDays, integer: true);
    check('Total uses', _total, integer: true); check('Uses per buyer', _perCustomer, integer: true);
    return first;
  }
  Widget _field(String label, String key, TextEditingController controller,
      {bool integer = false, bool name = false, bool allowZero = false}) => Semantics(
    label: label, textField: true, child: TextFormField(
    key: Key(key), controller: controller, style: const TextStyle(fontSize: 14),
    focusNode: name ? _nameFocus : null,
    enabled: !_editingLocked && _current,
    maxLength: name ? 80 : null,
    keyboardType: name ? TextInputType.text : TextInputType.numberWithOptions(decimal: !integer),
    decoration: _couponDecoration(context, label, hint: name ? 'Choose or type a name' : null).copyWith(
      counterText: name ? '' : null,
      suffixIcon: name ? IconButton(tooltip: 'Edit coupon name',
        onPressed: _editingLocked || !_current ? null : () => _nameFocus.requestFocus(),
        icon: const Icon(Icons.edit_outlined, size: 20)) : null,
      ),
    onChanged: (_) => setState(() { _dirty = true; _error = null; }),
    validator: (raw) {
      final error = _entryError(raw ?? '', integer: integer, name: name, allowZero: allowZero);
      if (error != null) return error;
      if (key == 'work-coupon-discount' && _percentage && _exact(raw!)! > 10000) return 'Percentage cannot exceed 100.';
      return null;
    }));
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: widget.session,
    builder: (context, _) {
      final view = View.of(context);
      final exportedClearance = defaultTargetPlatform == TargetPlatform.android && view.viewInsets.bottom == 0
        ? max(36.0, moolAndroidExportedSemanticsClearance(
            viewPadding: EdgeInsets.fromViewPadding(view.viewPadding, view.devicePixelRatio),
            platform: defaultTargetPlatform))
        : 0.0;
      return PopScope(canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) unawaited(_close()); },
      child: Scaffold(backgroundColor: const Color(0xfff7f9fa),
        appBar: AppBar(automaticallyImplyLeading: false, toolbarHeight: 48,
          title: Text(widget.campaign == null ? 'Create coupon' : 'Edit coupon', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          actions: [IconButton(tooltip: 'Close coupon editor', onPressed: _saving ? null : _close,
            icon: const Icon(Icons.close))]),
        bottomNavigationBar: !_current ? null : Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + exportedClearance),
          child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(key: const Key('work-coupon-save'), style: _couponActionStyle(context), onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Please wait…' :
                _unconfirmedAttempt != null ? 'Check saved coupon' : 'Save draft'))))),
        body: !_current ? const Center(child: Text('Your Store session changed. Close and reopen this coupon.'))
          : Form(key: _form, child: ListView(key: const Key('work-coupon-editor'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            children: [
              DropdownButtonFormField<BuyV2StoreOfferKind>(key: const Key('work-coupon-type'),
                initialValue: _kind, isExpanded: true, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                decoration: _couponDecoration(context, 'Offer type'),
                items: [for (final kind in BuyV2StoreOfferKind.values)
                  DropdownMenuItem(value: kind, child: Text(kind.label))],
                onChanged: _editingLocked || !_current ? null : (kind) {
                  if (kind == null) return;
                  setState(() { _kind = kind; _structuredEditing = true; _dirty = true;
                    if (kind == BuyV2StoreOfferKind.productDiscount || !_money) _allProducts = false;
                  });
                }),
              const SizedBox(height: 4), Text(_kind.guide, style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 8),
              _field('Name', 'work-coupon-name', _name, name: true),
              Wrap(spacing: 6, runSpacing: 2, children: [for (final example in _nameExamples)
                ActionChip(key: ValueKey('work-coupon-name-example-$example'),
                  label: Text(example), backgroundColor: const Color(0xffeef2ff),
                  labelStyle: const TextStyle(color: Color(0xff101878), fontSize: 12),
                  tooltip: 'Use $example; you can edit the name',
                  onPressed: _editingLocked || !_current ? null : () => setState(() {
                    _name.text = example;
                    _name.selection = TextSelection.collapsed(offset: example.length);
                    _dirty = true;
                  }))]),
              const SizedBox(height: 4),
              if (_money && _kind != BuyV2StoreOfferKind.productDiscount)
                Wrap(spacing: 6, runSpacing: 2, children: [for (final all in [true, false])
                  ChoiceChip(key: Key(all ? 'work-coupon-scope-all' : 'work-coupon-scope-selected'),
                    label: Text(all ? 'All Store products' : 'Select products / SKUs'),
                    selected: _allProducts == all, selectedColor: const Color(0xff100078),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(color: _allProducts == all ? Colors.white : const Color(0xff101878), fontSize: 12),
                    onSelected: _editingLocked || !_current ? null : (_) => setState(() {
                      _allProducts = all; _structuredEditing = true; _dirty = true;
                    }))])
              else Text(_money ? 'Selected products / SKUs' : 'One qualifying SKU', style: const TextStyle(fontSize: 12)),
              if (!_allProducts) ...[
                OutlinedButton.icon(key: const Key('work-coupon-products'), style: _couponActionStyle(context),
                  onPressed: _editingLocked ? null : () => _pickProducts(), icon: const Icon(Icons.inventory_2_outlined),
                  label: Text(_skuIds.isEmpty ? 'Choose products' : '${_skuIds.length} selected ${_skuIds.length == 1 ? 'SKU' : 'SKUs'}')),
                for (final id in _skuIds.take(2)) Text(_retainedSkus[id]?.title ??
                  widget.session.workspaceCatalogueItems.where((item) => item.id == id).firstOrNull?.title ?? 'Unavailable saved product',
                  style: const TextStyle(fontSize: 12)),
                if (_skuIds.length > 2) Text('+${_skuIds.length - 2} more selected SKUs', style: const TextStyle(fontSize: 12)),
              ],
              Wrap(spacing: 6, runSpacing: 4, children: [for (final channel in ['retail', 'wholesale', 'bulk'])
                FilterChip(label: Text(channel == 'retail' ? 'Retail' : channel == 'wholesale' ? 'Wholesale' : 'Bulk'),
                  labelStyle: TextStyle(color: _channels.contains(channel) ? Colors.white : const Color(0xff101878)),
                  checkmarkColor: Colors.white,
                  selected: _channels.contains(channel), onSelected: _editingLocked ? null : (selected) => setState(() {
                    if (selected) { _channels.add(channel); } else { _channels.remove(channel); }
                    _structuredEditing = true; _dirty = true;
                  }))]),
              const SizedBox(height: 8),
              if (_money) ...[
              _couponPair(context, SegmentedButton<bool>(style: _couponActionStyle(context), showSelectedIcon: false,
                segments: const [ButtonSegment(value: false, label: Text('₹ off')),
                ButtonSegment(value: true, label: Text('% off'))], selected: {_percentage},
                onSelectionChanged: _editingLocked ? null : (value) => setState(() { _percentage = value.single; _discount.clear(); _dirty = true; _error = null; })),
                _field(_percentage ? 'Discount (%)' : 'Discount (₹)', 'work-coupon-discount', _discount)),
              const SizedBox(height: 8),
              ],
              if (_money && _percentage) _couponPair(context,
                _field('Minimum purchase (₹)', 'work-coupon-minimum', _minimum, allowZero: true),
                _field('Maximum saving (₹)', 'work-coupon-maximum', _maximum))
              else _field('Minimum purchase (₹)', 'work-coupon-minimum', _minimum, allowZero: true),
              if (_kind == BuyV2StoreOfferKind.quantityPrice) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(key: const Key('work-coupon-tiers'), style: _couponActionStyle(context), onPressed: _editingLocked ? null : _editTiers,
                  icon: const Icon(Icons.format_list_numbered),
                  label: Text(_tiers.isEmpty ? 'Add quantity price slabs' : '${_tiers.length} quantity price slabs')),
                const Text('Quantities and prices use the selected SKU’s selling unit.', style: TextStyle(fontSize: 12)),
              ],
              if (_kind == BuyV2StoreOfferKind.extraQuantity) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(key: const Key('work-coupon-reward-product'),
                  style: _couponActionStyle(context), onPressed: _editingLocked ? null : () => _pickProducts(reward: true), icon: const Icon(Icons.add_box_outlined),
                  label: Text(_rewardId == null ? 'Choose additional product' : 'Change additional product')),
                if (_rewardId != null) Text(_retainedReward?.title ?? widget.session.workspaceCatalogueItems
                  .where((item) => item.id == _rewardId).firstOrNull?.title ?? 'Unavailable saved product', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8), _couponPair(context,
                  _field('Buy quantity', 'work-coupon-buy-quantity', _buyQuantity, integer: true),
                  _field('Extra quantity', 'work-coupon-reward-quantity', _rewardQuantity, integer: true)),
                const Text('Quantities use each product’s selected selling unit.', style: TextStyle(fontSize: 11)),
              ],
              if (_kind == BuyV2StoreOfferKind.nextPurchase) ...[
                const SizedBox(height: 12), _field('Next purchase within (days)', 'work-coupon-next-days', _nextDays, integer: true),
                const Text('A qualifying completed purchase is required. Eligibility is checked for the buyer.', style: TextStyle(fontSize: 12)),
              ],
              if (_kind == BuyV2StoreOfferKind.buyerDiscount) ...[
                const SizedBox(height: 8), OutlinedButton.icon(key: const Key('work-coupon-buyers'),
                  style: _couponActionStyle(context), onPressed: _editingLocked ? null : _pickBuyers, icon: const Icon(Icons.people_outline),
                  label: Text(_buyerIds.isEmpty ? 'Choose buyers' : '${_buyerIds.length} selected buyers')),
                const Text('Your buyer selection stays private. Eligibility is checked when the buyer shops.', style: TextStyle(fontSize: 12)),
              ],
              if (_kind == BuyV2StoreOfferKind.dealerIntro)
                const Text('For a business buyer’s first eligible order at your Store. Eligibility is checked for the buyer.',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              _couponPair(context,
                OutlinedButton.icon(key: const Key('work-coupon-start'), style: _couponActionStyle(context), onPressed: _editingLocked ? null : () => _date(true),
                  icon: const Icon(Icons.event, size: 18), label: Text(_from == null ? 'Start date' : 'From ${MaterialLocalizations.of(context).formatShortDate(_from!)}')),
                OutlinedButton.icon(key: const Key('work-coupon-end'), style: _couponActionStyle(context), onPressed: _editingLocked ? null : () => _date(false),
                  icon: const Icon(Icons.event_available, size: 18), label: Text(_until == null ? 'End date' : 'Until ${MaterialLocalizations.of(context).formatShortDate(_until!)}'))),
              if (_kind == BuyV2StoreOfferKind.quantityPrice && _from != null && _until != null)
                Text('Price validity: ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_from!))} – '
                  '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_until!))}', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              _couponPair(context, _field('Total uses', 'work-coupon-total-uses', _total, integer: true),
                _field('Uses per buyer', 'work-coupon-customer-uses', _perCustomer, integer: true)),
              const SizedBox(height: 8),
              Text(widget.session.workspaceStoreCoupons == null
                ? 'Your Store funds the offer. One offer for your Store in each Cart. Saved as a private draft; publishing is not available yet.'
                : 'Your Store funds the offer. One offer for your Store in each Cart. Save your draft, then review publishing. Checkout confirms eligibility.',
                style: const TextStyle(fontSize: 12, color: Color(0xff566572), height: 1.4)),
              if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                child: Semantics(liveRegion: true, child: Text(_error!, style: const TextStyle(color: Color(0xff9c2737))))),
              const SizedBox(height: 12),
            ]))));
    });
}

/// Explicit public promotion, never a conversion of the private targeted draft.
class _StoreOfferTierEditor extends StatefulWidget {
  const _StoreOfferTierEditor({required this.initial, required this.sellUnit, required this.owner, required this.current});
  final List<BuyV2StoreOfferTier> initial;
  final String sellUnit;
  final Listenable owner;
  final bool Function() current;
  @override State<_StoreOfferTierEditor> createState() => _StoreOfferTierEditorState();
}
class _StoreOfferTierEditorState extends State<_StoreOfferTierEditor> {
  final _form = GlobalKey<FormState>();
  final _rows = <({TextEditingController quantity, TextEditingController price})>[];
  String? _error;
  void _add([BuyV2StoreOfferTier? value]) => _rows.add((
    quantity: TextEditingController(text: value?.minimumQuantity.toString() ?? ''),
    price: TextEditingController(text: value == null ? '' : _couponAmount(value.priceMinor))));
  @override void initState() { super.initState(); for (final value in widget.initial) { _add(value); } if (_rows.isEmpty) _add(); }
  @override void dispose() { for (final row in _rows) { row.quantity.dispose(); row.price.dispose(); } super.dispose(); }
  int? _price(String raw) {
    if (!RegExp(r'^\d{1,11}(\.\d{1,2})?$').hasMatch(raw.trim())) return null;
    final parts = raw.trim().split('.');
    return int.parse(parts[0]) * 100 + (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  }
  void _done() {
    if (!widget.current() || !_form.currentState!.validate()) return;
    var previous = 0; final tiers = <BuyV2StoreOfferTier>[];
    for (var index = 0; index < _rows.length; index++) {
      final row = _rows[index], quantity = int.tryParse(_rows[index].quantity.text.trim());
      final price = _price(row.price.text);
      if (quantity == null || quantity <= previous || quantity > 1000000000 || price == null || price <= 0 || price > 9000000000000) {
        setState(() => _error = 'Check slab ${index + 1}: use increasing quantities and valid unit prices.'); return;
      }
      previous = quantity; tiers.add(BuyV2StoreOfferTier(minimumQuantity: quantity, priceMinor: price));
    }
    Navigator.pop(context, List<BuyV2StoreOfferTier>.unmodifiable(tiers));
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: widget.owner, builder: (context, _) {
    final view = View.of(context);
    final clearance = defaultTargetPlatform == TargetPlatform.android && view.viewInsets.bottom == 0
      ? max(36.0, moolAndroidExportedSemanticsClearance(
          viewPadding: EdgeInsets.fromViewPadding(view.viewPadding, view.devicePixelRatio), platform: defaultTargetPlatform)) : 0.0;
    final maximumHeight = MediaQuery.sizeOf(context).height * .94;
    final expanded = MediaQuery.viewInsetsOf(context).bottom > 0 || MediaQuery.textScalerOf(context).scale(14) > 18;
    final height = expanded ? maximumHeight : min(maximumHeight, 280.0 + _rows.length * 72 + (_error == null ? 0 : 48));
    return SizedBox(height: height, child: Scaffold(appBar: AppBar(automaticallyImplyLeading: false, toolbarHeight: 48,
      title: const Text('Price slabs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      actions: [IconButton(tooltip: 'Cancel price slabs', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
      bottomNavigationBar: Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + clearance),
        child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(12),
          child: FilledButton(style: _couponActionStyle(context), onPressed: widget.current() ? _done : null, child: const Text('Use price slabs'))))),
      body: !widget.current() ? const Center(child: Text('Your Store session changed. Reopen price slabs.')) : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('Unit: ${widget.sellUnit}', style: const TextStyle(fontSize: 12))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: TextButton.icon(
            style: _couponActionStyle(context), onPressed: _rows.length >= 100 ? null : () => setState(() => _add()),
            icon: const Icon(Icons.add, size: 18), label: const Text('Add price slab'))),
          if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Semantics(liveRegion: true, child: Text(_error!))),
          Expanded(child: Form(key: _form, child: ListView.builder(key: const Key('work-coupon-tier-rows'),
            padding: const EdgeInsets.all(12), itemCount: _rows.length, itemBuilder: (context, index) {
              final row = _rows[index];
              return Padding(key: ObjectKey(row.quantity), padding: const EdgeInsets.only(bottom: 8), child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 24, child: Padding(padding: const EdgeInsets.only(top: 16),
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))),
                Expanded(child: _couponPair(context,
                  TextFormField(controller: row.quantity, style: const TextStyle(fontSize: 14), keyboardType: TextInputType.number,
                    decoration: _couponDecoration(context, 'Min. quantity'),
                    validator: (raw) { final value = int.tryParse(raw?.trim() ?? '');
                      return value == null || value < 1 || value > 1000000000 ? 'Enter a whole quantity above 0.' : null; }),
                  TextFormField(controller: row.price, style: const TextStyle(fontSize: 14), keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _couponDecoration(context, 'Unit price (₹)'),
                    validator: (raw) { final value = _price(raw ?? '');
                      return value == null || value < 1 || value > 9000000000000 ? 'Enter a valid price (up to 2 decimals).' : null; }), minimumWidth: 216)),
                  IconButton(tooltip: 'Remove price slab ${index + 1}', onPressed: _rows.length == 1 ? null : () => setState(() {
                    _rows.removeAt(index);
                    WidgetsBinding.instance.addPostFrameCallback((_) { row.quantity.dispose(); row.price.dispose(); });
                  }), icon: const Icon(Icons.delete_outline, size: 20)),
              ]));
            }))),
        ])));
  });
}

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
