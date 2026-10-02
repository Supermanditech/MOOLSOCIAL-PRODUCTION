import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as buy_qr;
import 'package:share_plus/share_plus.dart';

import '../../features/buy/buy_v2_cart_contracts.dart';
import '../../features/buy/buy_v2_content_contracts.dart';
import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_order_resolution_contracts.dart';
import '../../features/buy/buy_v2_saved_products_store.dart';
import '../../features/buy/buy_v2_session.dart';
import '../../features/work/scan_and_pick_contract.dart';
import '../../features/journey01/journey_services.dart';
import 'buy_v2_address_form_sheet_motion.dart';
import 'buy_v2_address_sheet_motion.dart';
import 'buy_v2_catalogue.dart'
    show
        BuyV2ProductCard,
        BuyV2AddFace,
        BuyV2ProductEdgeControls,
        showBuyV2RecentlyViewed,
        showBuyV2ShoppingHelp;
import 'buy_v2_design.dart';
import 'buy_v2_filter_sheet_motion.dart';
import 'buy_v2_invoice.dart';
import 'buy_v2_payment_sheet_motion.dart';
import 'buy_v2_prescription_sheet_motion.dart';
import 'buy_v2_product_feedback_sheet_motion.dart';
import 'buy_v2_product_video.dart';
import 'buy_v2_scanner.dart';
import 'buy_v2_store_address.dart';

typedef BuyV2LiveDeliveryMapBuilder =
    Widget Function(BuildContext context, BuyV2LiveDeliverySnapshot snapshot);

Future<void> _openOrderInvoice(
  BuildContext context, {
  required BuyV2Session session,
  required BuyV2Order order,
  BuyV2InvoiceDownloader? downloader,
}) async {
  if (order.lines.isNotEmpty) {
    showBuyV2InvoicePage(context, order: order, downloader: downloader);
    return;
  }
  final owner = session.customerStateStore?.ownerScope;
  final refresh = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: ValueKey('buy-invoice-items-unavailable-${order.id}'),
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Invoice details missing'),
      titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontSize: 14),
      content: Text(
        'Item details for ${order.id} are missing. '
        'Refresh orders, then reopen this invoice.',
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontSize: 14),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Back'),
        ),
        Align(
          widthFactor: 1,
          heightFactor: 1,
          child: FilledButton(
            key: ValueKey('buy-invoice-refresh-${order.id}'),
            style: BuyV2ActionStyle.button(
              FilledButton.styleFrom(
                textStyle: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontSize: 14),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Refresh orders'),
          ),
        ),
      ],
    ),
  );
  if (refresh == true &&
      context.mounted &&
      session.procurementScopeCurrent &&
      session.customerStateStore?.ownerScope == owner) {
    await session.retryCommerce();
  }
}

String _productCountLabel(int count) =>
    '$count ${count == 1 ? 'product' : 'products'}';

String _packCountLabel(int count) => '$count ${count == 1 ? 'pack' : 'packs'}';

String _itemCountLabel(int count) => '$count ${count == 1 ? 'item' : 'items'}';

bool _containsOnlyWholesaleLines(List<BuyV2CartLine> lines) =>
    lines.isNotEmpty &&
    lines.every(
      (line) => line.product.destination == BuyV2Destination.wholesale,
    );

String _checkoutFulfilmentCountLabel(BuyV2FulfilmentGroup group) =>
    group.destination == BuyV2Destination.wholesale
    ? '${_productCountLabel(group.lines.length)} · '
          '${_packCountLabel(group.itemCount)}'
    : '${_productCountLabel(group.lines.length)} · '
          '${_itemCountLabel(group.itemCount)}';

String _checkoutDockCountLabel(BuyV2Session session) =>
    !session.checkoutRecoveryAmountKnown
    ? 'Original payment'
    : session.collectionCheckoutSelected &&
          session.checkoutLines.isEmpty &&
          session.cartLines.isNotEmpty
    ? 'Cart saved'
    : session.checkoutScope == BuyV2CartScope.wholesale ||
          _containsOnlyWholesaleLines(session.checkoutLines)
    ? '${_productCountLabel(session.checkoutLines.length)} · '
          '${_packCountLabel(session.checkoutItemCount)}'
    : _itemCountLabel(session.checkoutItemCount);

String _cartHeaderSummary(BuyV2Session session) {
  final lines = session.visibleCartLines;
  final quantity = lines.fold<int>(0, (sum, line) => sum + line.quantity);
  final quantityLabel = _containsOnlyWholesaleLines(lines)
      ? _packCountLabel(quantity)
      : _itemCountLabel(quantity);
  final context =
      session.usesMixedCartSelection && session.cartDisplayFilter != 'all'
      ? '${_cartFilterLabel(session.cartDisplayFilter)} · '
      : '';
  return '$context${_productCountLabel(lines.length)} · $quantityLabel';
}

String _cartFilterLabel(String filter) => switch (filter) {
  'shop' => 'Shop',
  'wholesale' => 'Wholesale',
  'bulk' => 'Bulk',
  _ => 'All',
};

String _cartDestinationLabel(
  BuyV2Session session,
  BuyV2Destination destination,
) {
  if (destination != BuyV2Destination.wholesale) return destination.label;
  final lines = session.cartLines.where(
    (line) => line.product.destination == destination,
  );
  final hasBulk = lines.any(
    (line) => line.product.offerClass == BuyV2OfferClass.bulk,
  );
  final hasWholesale = lines.any(
    (line) => line.product.offerClass != BuyV2OfferClass.bulk,
  );
  return hasBulk ? (hasWholesale ? 'Wholesale & Bulk' : 'Bulk') : 'Wholesale';
}

@immutable
class BuyV2GstInvoiceDetails {
  const BuyV2GstInvoiceDetails({
    required this.id,
    required this.legalName,
    required this.gstin,
    required this.billingAddress,
  });

  final String id;
  final String legalName;
  final String gstin;
  final String billingAddress;
}

class BuyV2GstInvoiceController extends ChangeNotifier {
  BuyV2GstInvoiceController({this.store});

  final BuyV2GstInvoiceProfileStore? store;
  final Map<BuyV2Destination, bool> _requested = {
    BuyV2Destination.shop: false,
    BuyV2Destination.wholesale: false,
  };
  final Map<BuyV2Destination, BuyV2GstInvoiceDetails> _selected = {};
  final List<BuyV2GstInvoiceDetails> _savedProfiles = [];
  final Set<BuyV2Destination> _explicitPreference = {};
  int _nextId = 1;
  int _mutationRevision = 0;
  String? _ownerScope;
  bool _restoring = false;
  bool _loadFailed = false;
  bool _busy = false;
  bool _disposed = false;
  String? _message;

  bool requestedFor(BuyV2Destination destination) =>
      _requested[destination] ?? false;

  BuyV2GstInvoiceDetails? detailsFor(BuyV2Destination destination) =>
      _selected[destination];

  List<BuyV2GstInvoiceDetails> get savedProfiles =>
      List.unmodifiable(_savedProfiles);

  bool get persistenceAvailable => store?.ownerScope != null;

  bool get sessionPersistenceOnly =>
      store?.ownerScope?.startsWith('device-review-session:') ?? false;

  bool get restoring => _restoring;
  bool get loadFailed => _loadFailed;

  bool get busy => _busy;

  String? get message => _message;

  void clearMessage() {
    if (_message == null) return;
    _message = null;
    _notify();
  }

  Future<void> restore({bool force = false}) async {
    final profileStore = store;
    final ownerScope = profileStore?.ownerScope;
    if (ownerScope != _ownerScope) {
      _savedProfiles.clear();
      _selected.clear();
      _explicitPreference.clear();
      _requested.updateAll((_, value) => false);
      _mutationRevision++;
      _ownerScope = null;
    }
    if (profileStore == null || ownerScope == null) {
      _notify();
      return;
    }
    if ((!force && ownerScope == _ownerScope) || _restoring) return;
    _ownerScope = ownerScope;
    _restoring = true;
    _loadFailed = false;
    _message = null;
    final mutationRevision = _mutationRevision;
    _notify();
    try {
      final snapshot = await profileStore.read();
      if (_disposed ||
          profileStore.ownerScope != ownerScope ||
          mutationRevision != _mutationRevision) {
        return;
      }
      final restored = <BuyV2GstInvoiceDetails>[];
      final seenIds = <String>{};
      for (final record in snapshot?.profiles ?? const []) {
        final id = record.id.trim();
        final legalName = record.legalName.trim();
        final gstin = record.gstin.trim().toUpperCase();
        final billingAddress = record.billingAddress.trim();
        if (id.isEmpty ||
            legalName.isEmpty ||
            gstin.isEmpty ||
            billingAddress.isEmpty ||
            !seenIds.add(id)) {
          continue;
        }
        restored.add(
          BuyV2GstInvoiceDetails(
            id: id,
            legalName: legalName,
            gstin: gstin,
            billingAddress: billingAddress,
          ),
        );
      }
      _savedProfiles
        ..clear()
        ..addAll(restored);
      _nextId = _nextProfileNumber(restored);
      for (final destination in _selected.keys.toList()) {
        final previous = _selected[destination]!;
        if (!previous.id.startsWith('gst-profile-')) continue;
        final replacement = restored
            .where((p) => p.id == previous.id)
            .firstOrNull;
        if (replacement == null) {
          _selected.remove(destination);
          _requested[destination] = false;
        } else {
          _selected[destination] = replacement;
        }
      }
      applySavedDefaults();
    } on Object {
      if (!_disposed && profileStore.ownerScope == ownerScope) {
        _loadFailed = true;
        _ownerScope = null;
        _message = 'Saved GST details could not be loaded. Try again.';
      }
    } finally {
      if (!_disposed) {
        if (profileStore.ownerScope != ownerScope) {
          _ownerScope = null;
          _savedProfiles.clear();
          _selected.clear();
        }
        _restoring = false;
        _notify();
      }
    }
  }

  int _nextProfileNumber(List<BuyV2GstInvoiceDetails> profiles) {
    var next = 1;
    for (final profile in profiles) {
      final match = RegExp(r'^gst-profile-(\d+)$').firstMatch(profile.id);
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value >= next) next = value + 1;
    }
    return next;
  }

  void setRequested(BuyV2Destination destination, bool requested) {
    if (destination != BuyV2Destination.shop &&
        destination != BuyV2Destination.wholesale) {
      return;
    }
    _explicitPreference.add(destination);
    if (_requested[destination] == requested) return;
    _requested[destination] = requested;
    _message = null;
    _notify();
  }

  void selectSaved(
    BuyV2Destination destination,
    BuyV2GstInvoiceDetails details,
  ) {
    _requested[destination] = true;
    _selected[destination] = details;
    _message = null;
    _notify();
  }

  void applySavedDefaults() {
    if (_savedProfiles.isEmpty) return;
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
    ]) {
      if (_selected[destination] == null &&
          !_explicitPreference.contains(destination)) {
        _selected[destination] = _savedProfiles.first;
        _requested[destination] = true;
      }
    }
  }

  void useForDestinations(
    BuyV2Destination from,
    Iterable<BuyV2Destination> destinations,
  ) {
    final details = _selected[from];
    if (details == null) return;
    for (final destination in destinations) {
      _selected[destination] = details;
      _requested[destination] = _requested[from] ?? true;
    }
    _notify();
  }

  bool applySavedBusinessProfile() {
    const destination = BuyV2Destination.wholesale;
    if (_selected[destination] != null || _savedProfiles.isEmpty) {
      return false;
    }
    _requested[destination] = true;
    _selected[destination] = _savedProfiles.first;
    _message = null;
    _notify();
    return true;
  }

  Future<bool> save({
    required BuyV2Destination destination,
    required String legalName,
    required String gstin,
    required String billingAddress,
    required bool remember,
  }) async {
    if (_busy) return false;
    if (_ownerScope != null && store?.ownerScope != _ownerScope) {
      await restore(force: true);
      _message = 'Your account changed. Review GST details again.';
      _notify();
      return false;
    }
    if (remember && !persistenceAvailable) {
      _message = 'Saved GST details are unavailable. Try again.';
      _notify();
      return false;
    }
    if (legalName.trim().isEmpty ||
        billingAddress.trim().isEmpty ||
        !RegExp(
          r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z]Z[0-9A-Z]$',
        ).hasMatch(gstin.trim().toUpperCase())) {
      _message = 'Check your GSTIN, legal name and billing address.';
      _notify();
      return false;
    }
    final current = _selected[destination];
    final currentIsSaved =
        current != null &&
        _savedProfiles.any((profile) => profile.id == current.id);
    final shouldRemember = remember && persistenceAvailable;
    final details = BuyV2GstInvoiceDetails(
      id: shouldRemember
          ? currentIsSaved
                ? current.id
                : 'gst-profile-${_nextId++}'
          : 'gst-session-${_nextId++}',
      legalName: legalName.trim(),
      gstin: gstin.trim().toUpperCase(),
      billingAddress: billingAddress.trim(),
    );
    if (shouldRemember) {
      final candidate = [
        details,
        ..._savedProfiles.where((item) => item.id != details.id),
      ];
      if (!await _writeProfiles(candidate)) return false;
      _savedProfiles
        ..clear()
        ..addAll(candidate);
    }
    _requested[destination] = true;
    _selected[destination] = details;
    if (shouldRemember) {
      _selected.updateAll(
        (_, value) => value.id == details.id ? details : value,
      );
      applySavedDefaults();
    }
    _message = shouldRemember
        ? sessionPersistenceOnly
              ? 'GST details kept until you close the app.'
              : 'GST details saved.'
        : null;
    _notify();
    return true;
  }

  Future<bool> removeSaved(BuyV2GstInvoiceDetails details) async {
    if (_busy || !persistenceAvailable) return false;
    final candidate = _savedProfiles
        .where((profile) => profile.id != details.id)
        .toList(growable: false);
    if (candidate.length == _savedProfiles.length) return true;
    if (!await _writeProfiles(candidate)) return false;
    _savedProfiles
      ..clear()
      ..addAll(candidate);
    _selected.removeWhere((destination, selected) {
      if (selected.id != details.id) return false;
      _requested[destination] = false;
      return true;
    });
    _message = 'GST details removed.';
    _notify();
    return true;
  }

  Future<bool> _writeProfiles(List<BuyV2GstInvoiceDetails> profiles) async {
    final profileStore = store;
    final ownerScope = profileStore?.ownerScope;
    if (profileStore == null || ownerScope == null) return false;
    _busy = true;
    _message = null;
    _mutationRevision += 1;
    _notify();
    try {
      final saved = await profileStore.write(
        BuyV2GstInvoiceProfileSnapshot(
          profiles: [
            for (final profile in profiles)
              BuyV2GstInvoiceProfileRecord(
                id: profile.id,
                legalName: profile.legalName,
                gstin: profile.gstin,
                billingAddress: profile.billingAddress,
              ),
          ],
        ),
      );
      if (_disposed || profileStore.ownerScope != ownerScope || !saved) {
        _message = 'GST details could not be saved. Try again.';
        return false;
      }
      _ownerScope = ownerScope;
      return true;
    } on Object {
      if (profileStore.ownerScope == ownerScope) {
        _message = 'GST details could not be saved. Try again.';
      }
      return false;
    } finally {
      if (!_disposed) {
        if (profileStore.ownerScope != ownerScope) {
          _selected.clear();
          _savedProfiles.clear();
          _explicitPreference.clear();
          _requested.updateAll((_, value) => false);
          _ownerScope = null;
          _message = 'GST details could not be saved. Try again.';
        }
        _busy = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

String _orderPromiseSummary(BuyV2Order order) =>
    buyV2OrderPromiseSummary(order);

String buyV2OrderArrivalSummary(
  BuyV2Session session,
  BuyV2Order order, {
  bool revised = false,
}) => buyV2OrderEstimateSummary(
  order,
  refreshState: session.orderRefreshState(order.id),
  refreshing: session.orderRefreshBusy(order.id),
  revised: revised,
);

String _orderDeliveryPartnerLabel(BuyV2Order order) {
  final name = order.deliveryPartnerName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return order.status == BuyV2OrderStatus.preparing ||
          order.status == BuyV2OrderStatus.confirmed
      ? 'Not assigned yet'
      : 'Delivery partner details unavailable';
}

typedef _BuyV2PurchaseGroup = ({String? purchaseId, List<BuyV2Order> orders});

List<_BuyV2PurchaseGroup> _purchaseGroupsFor(List<BuyV2Order> orders) {
  final grouped = <String, List<BuyV2Order>>{};
  for (final order in orders) {
    final key = order.purchaseId ?? 'order:${order.id}';
    grouped.putIfAbsent(key, () => []).add(order);
  }
  return [
    for (final entry in grouped.entries)
      (
        purchaseId: entry.value.first.purchaseId,
        orders: List.unmodifiable(entry.value),
      ),
  ];
}

typedef BuyV2PartnerCatalogueHandler =
    void Function(BuyV2Product product, {bool brandOnly});

Future<void> showBuyV2SupplierPolicySheet(
  BuildContext context,
  BuyV2Session session, {
  BuyV2Product? product,
  BuyV2SupplierPolicyAddIntent? intent,
}) async {
  final item = intent?.product ?? product;
  if (item == null) return;
  final policy = intent?.policy ?? session.publishedSupplierPolicyFor(item);
  if (policy == null) return;
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: session,
          builder: (context, _) {
            if (intent != null &&
                !identical(session.pendingSupplierPolicyAdd, intent)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (sheetContext.mounted &&
                    (ModalRoute.of(sheetContext)?.isCurrent ?? false)) {
                  Navigator.of(sheetContext).pop();
                }
              });
              return const SizedBox.shrink();
            }
            return ConstrainedBox(
              key: const ValueKey('buy-supplier-policy-sheet'),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            policy.title,
                            style: context.buyBody.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Text(
                      buyV2CustomerStoreName(item.seller, item.storeId ?? ''),
                      style: context.buyMeta,
                    ),
                    const SizedBox(height: 12),
                    Text(policy.body, style: context.buyBody),
                    if (intent != null) ...[
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        key: const ValueKey(
                          'buy-supplier-policy-accept-and-add',
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: session.supplierPolicyConsentBusy,
                        title: Text(
                          'I accept this policy and add ${intent.quantity} × ${item.customerTitle}',
                          style: context.buyBody,
                        ),
                        onChanged: session.supplierPolicyConsentBusy
                            ? null
                            : (checked) async {
                                if (checked != true) return;
                                final added = await session
                                    .acceptSupplierPolicyAndAdd(intent);
                                if (sheetContext.mounted &&
                                    (ModalRoute.of(sheetContext)?.isCurrent ??
                                        false) &&
                                    (added ||
                                        !identical(
                                          session.pendingSupplierPolicyAdd,
                                          intent,
                                        ))) {
                                  Navigator.of(sheetContext).pop();
                                }
                              },
                      ),
                      if (session.supplierPolicyConsentBusy)
                        const LinearProgressIndicator(minHeight: 2),
                      if (session.notice case final message?)
                        Text(message, style: context.buyMeta),
                    ],
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: BuyV2Colors.ink,
                      ),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(intent == null ? 'Close' : 'Cancel'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  } finally {
    if (intent != null && identical(session.pendingSupplierPolicyAdd, intent)) {
      session.cancelSupplierPolicyAdd();
    }
  }
}

class BuyV2ProductView extends StatelessWidget {
  const BuyV2ProductView({
    super.key,
    required this.session,
    this.scrollController,
    this.bottomContentInset = 0,
    this.trailingAction,
    this.returnLabel,
    this.onReturn,
    this.onAskSeller,
    this.onVisitComparisonProduct,
    this.onOpenPartnerCatalogue,
    this.aggregateCart = false,
    this.wholesaleTradeDecisionAdapter =
        const BuyV2UnavailableWholesaleTradeDecisionAdapter(),
  });

  final BuyV2Session session;
  final ScrollController? scrollController;
  final double bottomContentInset;
  final Widget? trailingAction;
  final String? returnLabel;
  final VoidCallback? onReturn;
  final ValueChanged<BuyV2Product>? onAskSeller;
  final Future<void> Function(BuyV2Product)? onVisitComparisonProduct;
  final BuyV2PartnerCatalogueHandler? onOpenPartnerCatalogue;
  final bool aggregateCart;
  final BuyV2WholesaleTradeDecisionAdapter wholesaleTradeDecisionAdapter;

  @override
  Widget build(BuildContext context) {
    final product = session.selectedProduct;
    if (product == null) {
      return const SizedBox.shrink();
    }
    final quantity = session.quantityFor(product.id);
    final review = session.customerReviewFor(product.id);
    final facts = session.productFactsFor(product);
    final content = session.productContentFor(product);
    final supplierPolicy = session.publishedSupplierPolicyFor(product);
    final trust = session.marketplaceTrustFor(product);
    final productBenefits = session.productBenefitsFor(product);
    final productBenefitsState = session.productBenefitsStateFor(product);
    final variants = session.productVariantsFor(product);
    final purchaseProtection = product.purchaseProtection;
    final returnSummary =
        _nonBlankComplianceValue(purchaseProtection?.summary) ??
        _nonBlankComplianceValue(product.returnPolicy);
    final protectionRemedies =
        (purchaseProtection?.remedies ?? const <String>[])
            .map(_nonBlankComplianceValue)
            .whereType<String>()
            .toList(growable: false);
    final automaticFulfilment =
        product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale;
    final sizeChart =
        automaticFulfilment &&
            content.state == BuyV2ProductContentState.ready &&
            content.sourceId.trim().isNotEmpty &&
            content.sizeChart?.appliesTo(product) == true
        ? content.sizeChart
        : null;
    final wholesale = product.destination == BuyV2Destination.wholesale;
    final shop = product.destination == BuyV2Destination.shop;
    final orderability = facts.orderabilityLabel.toLowerCase();
    final buyerPromise =
        facts.storeOperatingState == BuyV2StoreOperatingState.closed
        ? facts.nextOpeningLabel?.trim().isNotEmpty == true
              ? 'Available when the store opens ${facts.nextOpeningLabel!.trim()}'
              : 'Available when the store reopens'
        : orderability.contains('unavailable') ||
              orderability.contains('out of stock')
        ? 'Currently unavailable'
        : automaticFulfilment
        ? buyV2BuyerDeliveryPromise(facts)
        : facts.deliveryPromise;
    final offerDecision = automaticFulfilment
        ? buyV2ResolveProductOfferDecision(
            product: product,
            facts: facts,
            quantity: session.quantityFor(product.id),
          )
        : null;
    final partnerProducts = switch (product.destination) {
      BuyV2Destination.shop ||
      BuyV2Destination.wholesale => session.partnerCatalogueFor(product),
      BuyV2Destination.medicine => session.sellerContinuationsFor(product),
      BuyV2Destination.orders => const <BuyV2Product>[],
    };
    final rxBlocked =
        product.requiresPrescription &&
        !session.isPrescriptionApproved(product.id);
    void addProduct() {
      HapticFeedback.selectionClick();
      final added = session.addProduct(product.id);
      if (!added && session.pendingPrescriptionProductId == product.id) {
        showBuyV2PrescriptionSheet(context, session);
      }
    }

    final storeAction = automaticFulfilment && onOpenPartnerCatalogue != null
        ? TextButton.icon(
            key: ValueKey(
              '${wholesale ? 'buy-wholesale-store-action' : 'buy-shop-seller-action'}-${product.id}',
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: const Color(0xFFEAF2F0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => onOpenPartnerCatalogue!(product),
            icon: const Icon(
              Icons.storefront_outlined,
              size: 18,
              color: Color(0xFF326C76),
            ),
            label: Text(
              wholesale ? 'Visit supplier' : 'Visit store',
              softWrap: false,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: BuyV2Colors.ink,
                height: 1.2,
              ),
            ),
          )
        : null;

    final storeSummary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductStoreSummary(
          key: ValueKey('buy-product-hero-store-${product.id}'),
          product: product,
          facts: facts,
          action: automaticFulfilment ? null : storeAction,
          location: trust.state == BuyV2MarketplaceTrustState.ready
              ? trust.partnerLocation
              : null,
        ),
        if (trust.state == BuyV2MarketplaceTrustState.ready) ...[
          if (trust.partnerRating case final rating?)
            _DecisionRow(
              icon: Icons.workspace_premium_outlined,
              label: 'Store rating',
              value: rating.toStringAsFixed(1),
              valueColor: BuyV2Colors.green,
            ),
          if (trust.partnerOrderCount case final count?)
            _DecisionRow(
              icon: Icons.inventory_2_outlined,
              label: 'Orders fulfilled',
              value: '$count',
            ),
          if (trust.serviceReliabilityLabel case final reliability?)
            _DecisionRow(
              icon: Icons.local_shipping_outlined,
              label: 'Delivery record',
              value: reliability,
            ),
        ],
      ],
    );
    final sellerActions = _ProductQuickActions(
      session: session,
      product: product,
      onAskSeller: onAskSeller,
      onVisitProduct: onVisitComparisonProduct,
      storeAction: storeAction,
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            key: PageStorageKey('buy-product-${product.id}'),
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              automaticFulfilment ? 0 : 10,
              8,
              automaticFulfilment ? 0 : 10,
              (automaticFulfilment ? 16.0 : 104.0) + bottomContentInset,
            ),
            children:
                [
                      Row(
                        children: [
                          Expanded(
                            child: _ReturnAffordance(
                              label: session.canReturnToComparedProduct
                                  ? session.productReturnLabel!
                                  : returnLabel ??
                                        session.productReturnLabel ??
                                        product.destination.label,
                              minimumHeight: 44,
                              onTap: session.canReturnToComparedProduct
                                  ? session.closeProduct
                                  : onReturn ?? session.closeProduct,
                            ),
                          ),
                          if (automaticFulfilment) ...[
                            IconButton(
                              key: ValueKey(
                                'buy-product-action-${session.isSaved(product.id) ? 'saved' : 'save'}-${product.id}',
                              ),
                              tooltip: session.isSaved(product.id)
                                  ? 'Saved'
                                  : 'Save',
                              onPressed: () => session.toggleSaved(product.id),
                              icon: Icon(
                                session.isSaved(product.id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                              ),
                            ),
                            IconButton(
                              key: ValueKey(
                                'buy-product-action-share-${product.id}',
                              ),
                              tooltip: 'Share',
                              onPressed: () => unawaited(
                                _shareBuyV2Product(
                                  context,
                                  session: session,
                                  product: product,
                                ),
                              ),
                              icon: const Icon(
                                Icons.ios_share_outlined,
                                color: Color(0xFF326C76),
                              ),
                            ),
                          ],
                          ?trailingAction,
                        ],
                      ),
                      const SizedBox(height: 7),
                      BuyV2FiniteDepthReveal(
                        key: ValueKey('buy-product-media-reveal-${product.id}'),
                        stateKey: 'buy-product-media-${product.id}',
                        child: _BuyV2ProductGallery(
                          key: ValueKey('buy-product-packshot-${product.id}'),
                          product: product,
                          session: session,
                          rating: trust.productRating,
                          ratingCount: trust.productRatingCount,
                          compact:
                              wholesale ||
                              (shop &&
                                  !content.media.any(
                                    (media) =>
                                        media.kind ==
                                        BuyV2ProductContentMediaKind
                                            .networkVideo,
                                  )),
                          media: [
                            for (final media
                                in content.media.isEmpty
                                    ? [
                                        BuyV2ProductMediaAsset(
                                          id: '${product.id}-packshot-fallback',
                                          label: 'Catalogue illustration',
                                          semanticLabel:
                                              'Illustration for ${product.customerTitle}. '
                                              'Supplier photo unavailable.',
                                          kind: BuyV2ProductContentMediaKind
                                              .cataloguePackshot,
                                        ),
                                      ]
                                    : content.media)
                              _BuyV2ProductMediaItem(
                                identity:
                                    '${media.id}:${media.kind.name}:${media.source}:${media.binding?.assetRevision}',
                                label:
                                    media.kind ==
                                        BuyV2ProductContentMediaKind
                                            .cataloguePackshot
                                    ? BuyV2ProductPackshot.illustrationLabel(
                                        product,
                                      )
                                    : media.label,
                                zoomable:
                                    media.kind !=
                                    BuyV2ProductContentMediaKind.networkVideo,
                                video:
                                    media.kind ==
                                    BuyV2ProductContentMediaKind.networkVideo,
                                builder: (active) =>
                                    _ProductContentMediaSurface(
                                      product: product,
                                      media: media,
                                      active: active,
                                      onRetry: () => session
                                          .refreshProductContent(product.id),
                                    ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (content.state == BuyV2ProductContentState.ready &&
                          product.mediaAssets.isNotEmpty &&
                          content.customerMessage?.trim().isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            content.customerMessage!,
                            key: ValueKey(
                              'buy-product-media-notice-${product.id}',
                            ),
                            style: context.buyMeta,
                          ),
                        ),
                      BuyV2FiniteIncomingTransition(
                        key: ValueKey('buy-product-title-reveal-${product.id}'),
                        stateKey: 'buy-product-title-${product.id}',
                        child: BuyV2CartAvoidanceRegion(
                          child: Container(
                            width: double.infinity,
                            key: ValueKey(
                              'buy-product-purchase-hero-${product.id}',
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFF3F6F5)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: BuyV2Colors.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (product.brand.trim().isNotEmpty)
                                      Text(
                                        shop
                                            ? product.brandLabel
                                            : '${product.brandLabel} · ${_sellerTypeLabel(product.sellerType)}',
                                        style: context.buyEyebrow.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                    if (!automaticFulfilment)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              facts.orderabilityLabel
                                                  .toLowerCase()
                                                  .startsWith('available')
                                              ? BuyV2Colors.softGreen
                                              : BuyV2Colors.softOrange,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          facts.orderabilityLabel,
                                          style: context.buyMeta.copyWith(
                                            color: BuyV2Colors.green,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (product.brand.trim().isNotEmpty ||
                                    !automaticFulfilment)
                                  const SizedBox(height: 4),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final identity = Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.customerTitle,
                                          key: ValueKey(
                                            'buy-product-title-${product.id}',
                                          ),
                                          style: context.buyTitle.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          product.composition ??
                                              product.customerVariant,
                                          style: context.buyBody.copyWith(
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    );
                                    final purchase = BuyV2CartAvoidanceRegion(
                                      child: wholesale
                                          ? _WholesaleTradePriceSummary(
                                              product: product,
                                              facts: facts,
                                              decision: offerDecision!,
                                              actionWidth:
                                                  !session.businessVerified ||
                                                      !offerDecision.canAdd
                                                  ? double.infinity
                                                  : quantity > 0
                                                  ? _productQuantityWidth(
                                                      context,
                                                      quantity,
                                                    )
                                                  : 44,
                                              action: !session.businessVerified
                                                  ? TextButton(
                                                      key: ValueKey(
                                                        'buy-wholesale-verify-business-${product.id}',
                                                      ),
                                                      onPressed: () => context.push(
                                                        '/app/work/workspace/choose',
                                                      ),
                                                      child: const Text(
                                                        'Verify business',
                                                      ),
                                                    )
                                                  : !offerDecision.canAdd
                                                  ? TextButton(
                                                      key: ValueKey(
                                                        'buy-wholesale-retry-offer-${product.id}',
                                                      ),
                                                      onPressed: () => session
                                                          .refreshProductFacts(
                                                            product.id,
                                                          ),
                                                      child: const Text(
                                                        'Check availability',
                                                      ),
                                                    )
                                                  : SizedBox(
                                                      width: quantity > 0
                                                          ? _productQuantityWidth(
                                                              context,
                                                              quantity,
                                                            )
                                                          : 44,
                                                      child: _ProductOwnedActionPanel(
                                                        key: ValueKey(
                                                          'buy-product-inline-action-${product.id}',
                                                        ),
                                                        product: product,
                                                        quantity: quantity,
                                                        showPurchaseFacts:
                                                            false,
                                                        deliveryDecision:
                                                            buyerPromise,
                                                        addSemanticLabel:
                                                            'Add minimum order of ${_packCountLabel(product.minimumOrder)} of '
                                                            '${product.customerTitle} to Cart for '
                                                            '${buyV2Money(product.minimumOrderTotal(facts.price))}. '
                                                            '${buyV2FulfilmentModeLabel(session.fulfilmentModeFor(product))} · '
                                                            '${buyV2BuyerDeliveryPromise(facts)}',
                                                        rxBlocked: rxBlocked,
                                                        onAdd: addProduct,
                                                        onEdit: () =>
                                                            showBuyV2QuantityEditor(
                                                              context,
                                                              session,
                                                              product,
                                                            ),
                                                        onDecrease: () =>
                                                            session.decrease(
                                                              product.id,
                                                            ),
                                                        onIncrease: () =>
                                                            session.increase(
                                                              product.id,
                                                            ),
                                                      ),
                                                    ),
                                            )
                                          : LayoutBuilder(
                                              builder: (context, constraints) {
                                                final details = Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      product
                                                                  .unitPrice
                                                                  .isNotEmpty &&
                                                              (!shop ||
                                                                  facts.price ==
                                                                      product
                                                                          .price)
                                                          ? '${product.pack} · ${product.unitPrice}'
                                                          : product.pack,
                                                      style: context.buyMeta
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                    ),
                                                    if (product.packTerms !=
                                                            null &&
                                                        (product.minimumOrder >
                                                                1 ||
                                                            product.quantityStep >
                                                                1))
                                                      Text(
                                                        'Minimum ${_packCountLabel(product.minimumOrder)} · Step ${product.quantityStep}',
                                                        key: ValueKey(
                                                          'buy-product-pack-rule-${product.id}',
                                                        ),
                                                        style: context.buyMeta,
                                                      ),
                                                    if (!shop &&
                                                        product.mrp != null &&
                                                        product.mrp! >
                                                            facts.price)
                                                      Text(
                                                        'Save ${buyV2Money(product.mrp! - facts.price)}',
                                                        style: context.buyMeta
                                                            .copyWith(
                                                              color: BuyV2Colors
                                                                  .green,
                                                            ),
                                                      ),
                                                  ],
                                                );
                                                final priceWidth = math.min(
                                                  constraints.maxWidth,
                                                  buyV2ValueTextSize(
                                                        context,
                                                        buyV2Money(facts.price),
                                                        context.buyTitle
                                                            .copyWith(
                                                              fontSize: 24,
                                                            ),
                                                      ).width +
                                                      2,
                                                );
                                                final price = SizedBox(
                                                  width: priceWidth,
                                                  child: _ProductHeroPrice(
                                                    productId: product.id,
                                                    amount: facts.price,
                                                    mrp: facts.stale
                                                        ? null
                                                        : product.mrp,
                                                    fontSize: 24,
                                                  ),
                                                );
                                                Widget summary(
                                                  Widget heading,
                                                ) => automaticFulfilment
                                                    ? heading
                                                    : Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          heading,
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          details,
                                                        ],
                                                      );
                                                if (!shop ||
                                                    !offerDecision!.canAdd) {
                                                  return summary(price);
                                                }
                                                final actionWidth = quantity > 0
                                                    ? _productQuantityWidth(
                                                        context,
                                                        quantity,
                                                      )
                                                    : 44.0;
                                                final action = SizedBox(
                                                  width: actionWidth,
                                                  child: _ProductOwnedActionPanel(
                                                    key: ValueKey(
                                                      'buy-product-inline-action-${product.id}',
                                                    ),
                                                    product: product,
                                                    quantity: quantity,
                                                    showPurchaseFacts: false,
                                                    deliveryDecision:
                                                        buyerPromise,
                                                    rxBlocked: rxBlocked,
                                                    onAdd: addProduct,
                                                    onEdit: () =>
                                                        showBuyV2QuantityEditor(
                                                          context,
                                                          session,
                                                          product,
                                                        ),
                                                    onDecrease: () => session
                                                        .decrease(product.id),
                                                    onIncrease: () => session
                                                        .increase(product.id),
                                                  ),
                                                );
                                                return summary(
                                                  Wrap(
                                                    spacing: 10,
                                                    runSpacing: 6,
                                                    crossAxisAlignment:
                                                        WrapCrossAlignment
                                                            .center,
                                                    children: [price, action],
                                                  ),
                                                );
                                              },
                                            ),
                                    );
                                    final purchaseWidth =
                                        buyV2ValueTextSize(
                                          context,
                                          buyV2Money(facts.price),
                                          context.buyTitle.copyWith(
                                            fontSize: 24,
                                          ),
                                        ).width +
                                        14 +
                                        (quantity > 0
                                            ? _productQuantityWidth(
                                                context,
                                                quantity,
                                              )
                                            : 44);
                                    if (automaticFulfilment &&
                                        MediaQuery.textScalerOf(
                                              context,
                                            ).scale(1) <=
                                            1.3 &&
                                        purchaseWidth <=
                                            constraints.maxWidth - 108 &&
                                        (!wholesale ||
                                            (session.businessVerified &&
                                                offerDecision!.canAdd))) {
                                      return Row(
                                        key: ValueKey(
                                          'buy-product-hero-balanced-${product.id}',
                                        ),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: identity),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: purchaseWidth,
                                            child: purchase,
                                          ),
                                        ],
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        identity,
                                        const SizedBox(height: 6),
                                        purchase,
                                      ],
                                    );
                                  },
                                ),
                                if (automaticFulfilment)
                                  _ProductPriceExtras(
                                    session: session,
                                    product: product,
                                    facts: facts,
                                    content: content,
                                  ),
                                if (!automaticFulfilment)
                                  const SizedBox(height: 8),
                                if (!automaticFulfilment)
                                  _ProductHeroFact(
                                    icon: Icons.storefront_outlined,
                                    value:
                                        '${product.customerSeller(facts.partner)} · ${_sellerTypeLabel(product.sellerType)}',
                                    trailing: storeAction,
                                  ),
                                if (!automaticFulfilment) ...[
                                  const SizedBox(height: 5),
                                  _ProductHeroFact(
                                    key: ValueKey(
                                      'buy-product-hero-delivery-${product.id}',
                                    ),
                                    deliveryArtwork: buyV2DeliveryArtworkFor(
                                      product,
                                      fulfilmentMode: facts.fulfilmentMode,
                                    ),
                                    icon:
                                        product.destination ==
                                            BuyV2Destination.wholesale
                                        ? Icons.local_shipping_outlined
                                        : Icons.schedule_rounded,
                                    value: buyerPromise,
                                    color: BuyV2Colors.green,
                                  ),
                                  if (returnSummary
                                      case final returnPolicy?) ...[
                                    const SizedBox(height: 5),
                                    _ProductHeroFact(
                                      icon: Icons.assignment_return_outlined,
                                      value: returnPolicy,
                                    ),
                                  ],
                                ],
                                if (!automaticFulfilment) ...[
                                  const SizedBox(height: 9),
                                  _ProductOwnedActionPanel(
                                    key: ValueKey(
                                      'buy-product-inline-action-${product.id}',
                                    ),
                                    product: product,
                                    quantity: quantity,
                                    showPurchaseFacts: false,
                                    deliveryDecision: buyerPromise,
                                    rxBlocked: rxBlocked,
                                    onAdd: addProduct,
                                    onEdit: () => showBuyV2QuantityEditor(
                                      context,
                                      session,
                                      product,
                                    ),
                                    onDecrease: () =>
                                        session.decrease(product.id),
                                    onIncrease: () =>
                                        session.increase(product.id),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (supplierPolicy != null)
                        TextButton.icon(
                          key: ValueKey(
                            'buy-product-supplier-policy-${product.id}',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: BuyV2Colors.ink,
                          ),
                          icon: const Icon(Icons.policy_outlined, size: 18),
                          label: Text(supplierPolicy.title),
                          onPressed: () => showBuyV2SupplierPolicySheet(
                            context,
                            session,
                            product: product,
                          ),
                        ),
                      if (variants.length > 1 ||
                          sizeChart != null ||
                          product.hasStructuredVariants) ...[
                        const SizedBox(height: 8),
                        _ProductVariantSelector(
                          session: session,
                          product: product,
                          variants: variants,
                          sizeChart: sizeChart,
                        ),
                      ],
                      if (!wholesale &&
                          (!shop ||
                              review != null ||
                              product.regulatoryTrustFact != null)) ...[
                        const SizedBox(height: 7),
                        BuyV2CartAvoidanceRegion(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            children: [
                              if (!shop)
                                _ProductTrustPill(
                                  icon: Icons.star_rounded,
                                  label: trust.productRating == null
                                      ? 'No customer ratings yet'
                                      : '${trust.productRating!.toStringAsFixed(1)} · '
                                            '${trust.productRatingCount ?? 0} ratings',
                                  color: BuyV2Colors.orange,
                                ),
                              if (review != null)
                                _ProductTrustPill(
                                  icon: Icons.rate_review_outlined,
                                  label: '${review.rating}.0 · Your review',
                                  color: BuyV2Colors.navy,
                                ),
                              if (!automaticFulfilment)
                                const _ProductTrustPill(
                                  icon: Icons.schedule_rounded,
                                  label: 'Delivery promise shown',
                                  color: BuyV2Colors.green,
                                ),
                              if (product.regulatoryTrustFact case final fact?)
                                _ProductTrustPill(
                                  icon: Icons.local_pharmacy_outlined,
                                  label: fact,
                                  color: BuyV2Colors.navy,
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Keep this one product's finite detail panels in one layout.
                      // Async panels above a restored offset must be laid out again;
                      // otherwise a lazy list retains their obsolete loading height.
                      // Media and the purchase hero retain their lazy lifecycle.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (wholesale)
                            Column(
                              children: [
                                if (!session.businessVerified) ...[
                                  _WholesaleVerificationCard(
                                    state: session.businessVerificationState,
                                    onOpenWorkspace: () => context.push(
                                      '/app/work/workspace/choose',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                _WholesaleTradeDecisionPanel(
                                  session: session,
                                  product: product,
                                  facts: facts,
                                  decision: offerDecision!,
                                  buyerPromise: buyerPromise,
                                  storeSummary: storeSummary,
                                  sellerActions: sellerActions,
                                  adapter: wholesaleTradeDecisionAdapter,
                                  onOpenPartnerCatalogue:
                                      onOpenPartnerCatalogue,
                                ),
                              ],
                            )
                          else if (automaticFulfilment)
                            _ProductOfferDecisionPanel(
                              session: session,
                              product: product,
                              facts: facts,
                              decision: offerDecision!,
                              buyerPromise: buyerPromise,
                              storeSummary: storeSummary,
                              sellerActions: sellerActions,
                            )
                          else
                            _DecisionPanel(
                              title: 'Pharmacy and fulfilment',
                              children: [
                                if (partnerProducts.isEmpty ||
                                    onOpenPartnerCatalogue == null)
                                  _DecisionRow(
                                    icon: Icons.local_pharmacy_outlined,
                                    label: product.partnerRole,
                                    value: product.seller,
                                  )
                                else
                                  _DecisionActionRow(
                                    key: ValueKey(
                                      'buy-medicine-pharmacy-action-${product.id}',
                                    ),
                                    icon: Icons.local_pharmacy_outlined,
                                    label: product.partnerRole,
                                    value: product.seller,
                                    detail:
                                        '${partnerProducts.length} other current products · Not medical advice',
                                    semanticLabel:
                                        'View ${partnerProducts.length} more products from ${product.seller} '
                                        'that are available now. Not medical advice',
                                    onTap: () =>
                                        onOpenPartnerCatalogue!(product),
                                  ),
                                _DecisionRow(
                                  icon: Icons.route_outlined,
                                  label: 'Delivery path',
                                  value: product.origin,
                                ),
                                _DecisionRow(
                                  icon: Icons.event_available_outlined,
                                  label: 'Price checked',
                                  value: product.confirmedOn,
                                ),
                              ],
                            ),
                          if ((shop || wholesale) &&
                              (productBenefitsState !=
                                      BuyV2CartBenefitsLoadState.ready ||
                                  productBenefits.isNotEmpty)) ...[
                            const SizedBox(height: 8),
                            BuyV2CartAvoidanceRegion(
                              child: _ProductBenefitsPreview(
                                session: session,
                                product: product,
                                benefits: productBenefits,
                                state: productBenefitsState,
                                customerMessage: session
                                    .productBenefitsMessageFor(product),
                              ),
                            ),
                          ],
                          if (product.destination ==
                              BuyV2Destination.medicine) ...[
                            const SizedBox(height: 10),
                            _DecisionPanel(
                              title: 'Medicine information',
                              children: [
                                _DecisionRow(
                                  icon: Icons.science_outlined,
                                  label: 'Composition',
                                  value:
                                      product.composition ??
                                      product.customerVariant,
                                ),
                                _DecisionRow(
                                  icon: Icons.health_and_safety_outlined,
                                  label: 'Dispensing',
                                  value: product.requiresPrescription
                                      ? 'Valid prescription and pharmacist review required'
                                      : 'No prescription required for this listed pack',
                                ),
                                _DecisionRow(
                                  icon: Icons.info_outline_rounded,
                                  label: 'Important',
                                  value:
                                      product.regulatoryNote ??
                                      'Check the sealed pack before use.',
                                ),
                                if (product.manufacturerVerified)
                                  const _DecisionRow(
                                    icon: Icons.factory_outlined,
                                    label: 'Supply',
                                    value:
                                        'Sealed manufacturer pack · dispensed by the listed licensed pharmacy',
                                  ),
                              ],
                            ),
                          ],
                          if (automaticFulfilment) ...[
                            const SizedBox(height: 12),
                            _ProductAssuranceControls(
                              session: session,
                              product: product,
                              onAskSeller: onAskSeller,
                            ),
                          ],
                          if (!automaticFulfilment &&
                              (!shop || purchaseProtection != null)) ...[
                            const SizedBox(height: 10),
                            _DecisionPanel(
                              title: shop
                                  ? 'Purchase protection'
                                  : 'Product details',
                              children: [
                                if (!shop) ...[
                                  if (automaticFulfilment)
                                    _DecisionRow(
                                      icon: Icons.location_on_outlined,
                                      label: 'Service area',
                                      value:
                                          session
                                              .selectedAddressOrNull
                                              ?.shortLine ??
                                          'Based on your delivery address',
                                    )
                                  else
                                    _DecisionRow(
                                      icon: Icons.route_outlined,
                                      label: 'Where it comes from',
                                      value: product.origin,
                                    ),
                                ],
                                if (purchaseProtection
                                    case final protection?) ...[
                                  if (protectionRemedies.isNotEmpty)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon: Icons.rule_rounded,
                                      label: 'Available options',
                                      value: protectionRemedies.join(' · '),
                                    ),
                                  if (_nonBlankComplianceValue(
                                        protection.windowLabel,
                                      )
                                      case final value?)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon: Icons.schedule_rounded,
                                      label: 'Request window',
                                      value: value,
                                    ),
                                  if (_nonBlankComplianceValue(
                                        protection.conditionsLabel,
                                      )
                                      case final value?)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon: Icons.fact_check_outlined,
                                      label: 'Conditions',
                                      value: value,
                                    ),
                                  if (_nonBlankComplianceValue(
                                        protection.verificationLabel,
                                      )
                                      case final value?)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon: Icons.verified_outlined,
                                      label: 'Verification',
                                      value: value,
                                    ),
                                  if (_nonBlankComplianceValue(
                                        protection.initiationLabel,
                                      )
                                      case final value?)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon: Icons.playlist_add_check_rounded,
                                      label: 'How to request',
                                      value: value,
                                    ),
                                  if (_nonBlankComplianceValue(
                                        protection.approvalLabel,
                                      )
                                      case final value?)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon: Icons.approval_outlined,
                                      label: 'Approval',
                                      value: value,
                                    ),
                                  if (_nonBlankComplianceValue(
                                        protection.pickupLabel,
                                      )
                                      case final value?)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon: Icons.local_shipping_outlined,
                                      label: 'Pickup',
                                      value: value,
                                    ),
                                  if (_nonBlankComplianceValue(
                                        protection.refundMethodLabel,
                                      )
                                      case final value?)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      label: 'Refund method',
                                      value: value,
                                    ),
                                  if (_nonBlankComplianceValue(
                                        protection.refundTimelineLabel,
                                      )
                                      case final value?)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon: Icons.timelapse_rounded,
                                      label: 'Refund timeline',
                                      value: value,
                                    ),
                                  if (_nonBlankComplianceValue(
                                        protection.warrantyLabel,
                                      )
                                      case final value?)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon: Icons.shield_outlined,
                                      label: 'Warranty',
                                      value: value,
                                    ),
                                  if (_nonBlankComplianceValue(
                                        protection.nonReturnableReason,
                                      )
                                      case final value?)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon: Icons.info_outline_rounded,
                                      label: 'Non-returnable',
                                      value: value,
                                    ),
                                  if (_nonBlankComplianceValue(
                                        protection.policyVersion,
                                      )
                                      case final value?)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon: Icons.description_outlined,
                                      label: 'Policy reference',
                                      value: value,
                                    ),
                                  if (_nonBlankComplianceValue(
                                        protection.effectiveFromLabel,
                                      )
                                      case final value?)
                                    _DecisionRow(
                                      stackAtLargeText: shop,
                                      icon: Icons.event_available_outlined,
                                      label: 'Applies from',
                                      value: value,
                                    ),
                                ],
                              ],
                            ),
                          ],
                          if (automaticFulfilment) ...[
                            const SizedBox(height: 12),
                            _ProductContinuationSection(
                              session: session,
                              product: product,
                            ),
                          ],
                          _ProductContentSections(
                            session: session,
                            product: product,
                            content: content,
                          ),
                          const SizedBox(height: 10),
                          _MarketplaceTrustPanel(
                            session: session,
                            product: product,
                            trust: trust,
                            productOnly: automaticFulfilment,
                          ),
                          const SizedBox(height: 10),
                          _ProductReviewsPanel(
                            product: product,
                            review: review,
                            onReview: () => _showProductReviewSheet(
                              context,
                              session,
                              product,
                            ),
                            onReport: session.canReportProduct(product.id)
                                ? () => _showProductReportSheet(
                                    context,
                                    session,
                                    product,
                                  )
                                : null,
                            reported: session.hasReportedProduct(product.id),
                          ),
                          if (!automaticFulfilment) ...[
                            const SizedBox(height: 10),
                            _ProductContinuationSection(
                              session: session,
                              product: product,
                            ),
                          ],
                          if (automaticFulfilment)
                            _ProductDiscoverySections(
                              key: ValueKey(
                                'buy-product-discovery-${product.id}',
                              ),
                              session: session,
                              product: product,
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ]
                    .map<Widget>((child) {
                      if (!automaticFulfilment ||
                          child.key ==
                              ValueKey(
                                'buy-product-media-reveal-${product.id}',
                              )) {
                        return child;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: child,
                      );
                    })
                    .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _ProductStoreSummary extends StatelessWidget {
  const _ProductStoreSummary({
    super.key,
    required this.product,
    required this.facts,
    this.action,
    this.location,
  });
  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final Widget? action;
  final String? location;
  @override
  Widget build(BuildContext context) {
    final status = switch (facts.storeOperatingState) {
      BuyV2StoreOperatingState.open => 'Open for orders',
      BuyV2StoreOperatingState.closed =>
        facts.nextOpeningLabel?.trim().isNotEmpty == true
            ? 'Closed · ${facts.nextOpeningLabel}'
            : 'Currently closed',
      _ => null,
    };
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 3,
          children: [
            Text(
              'Store · ${_sellerTypeLabel(product.sellerType)}',
              style: context.buyMeta.copyWith(fontSize: 11, height: 1.35),
            ),
            if (status != null)
              Text(
                status,
                style: context.buyMeta.copyWith(
                  fontSize: 11,
                  height: 1.35,
                  color:
                      facts.storeOperatingState == BuyV2StoreOperatingState.open
                      ? BuyV2Colors.green
                      : BuyV2Colors.muted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    product.customerSeller(facts.partner),
                    key: ValueKey('buy-product-store-full-name-${product.id}'),
                    softWrap: true,
                    style: context.buyBody.copyWith(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_nonBlankComplianceValue(location) case final value?) ...[
                    const SizedBox(height: 3),
                    Text(
                      value,
                      key: ValueKey(
                        'buy-product-store-full-address-${product.id}',
                      ),
                      softWrap: true,
                      style: context.buyMeta.copyWith(
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              key: ValueKey('buy-product-copy-store-${product.id}'),
              tooltip: 'Copy store details',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(
                Icons.copy_outlined,
                size: 16,
                color: BuyV2Colors.muted,
              ),
              onPressed: () async {
                final details = [
                  product.customerSeller(facts.partner),
                  ?_nonBlankComplianceValue(location),
                ].join('\n');
                try {
                  await Clipboard.setData(ClipboardData(text: details));
                  if (!context.mounted) return;
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Store details copied')),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not copy store details. Try again.'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (MediaQuery.textScalerOf(context).scale(1) > 1.25 &&
            constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [identity, ?action],
          );
        }
        return Row(
          children: [
            Expanded(child: identity),
            if (action != null) const SizedBox(width: 8),
            ?action,
          ],
        );
      },
    );
  }
}

class _ProductInfoRow extends StatelessWidget {
  const _ProductInfoRow({
    required this.label,
    required this.value,
    this.color = BuyV2Colors.ink,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: context.buyMeta.copyWith(fontSize: 11, height: 1.3),
    );
    final valueText = Text(
      value.trim(),
      style: context.buyBody.copyWith(
        fontSize: 13,
        height: 1.3,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (MediaQuery.textScalerOf(context).scale(1) > 1.25 &&
              constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelText, const SizedBox(height: 2), valueText],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: constraints.maxWidth * .26, child: labelText),
              const SizedBox(width: 10),
              Expanded(child: valueText),
            ],
          );
        },
      ),
    );
  }
}

class _PublicProductOrderInformation extends StatefulWidget {
  const _PublicProductOrderInformation({
    required this.session,
    required this.product,
    required this.facts,
    required this.buyerPromise,
    required this.storeSummary,
    required this.sellerActions,
  });
  final BuyV2Session session;
  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final String buyerPromise;
  final Widget storeSummary;
  final Widget sellerActions;
  @override
  State<_PublicProductOrderInformation> createState() =>
      _PublicProductOrderInformationState();
}

class _PublicProductOrderInformationState
    extends State<_PublicProductOrderInformation>
    with WidgetsBindingObserver {
  Timer? _expiry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleExpiry();
  }

  @override
  void didUpdateWidget(covariant _PublicProductOrderInformation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleExpiry();
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    final eligibility = widget.facts.eligibility;
    if (eligibility == null) return;
    final now = widget.session.catalogueNow();
    final boundaries =
        [
            eligibility.expiresAt,
            eligibility.scheduledStart,
          ].whereType<DateTime>().where((value) => value.isAfter(now)).toList()
          ..sort();
    if (boundaries.isEmpty) return;
    final remaining = boundaries.first.difference(now);
    _expiry = Timer(
      remaining > const Duration(days: 1) ? const Duration(days: 1) : remaining,
      () {
        if (!mounted) return;
        setState(() {});
        _scheduleExpiry();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _scheduleExpiry();
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final product = widget.product;
    final facts = widget.facts;
    final buyerPromise = widget.buyerPromise;

    String normalize(String text) =>
        text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final rows = <Widget>[];
    void add(String label, String? value, {Color color = BuyV2Colors.ink}) {
      final clean = _nonBlankComplianceValue(value);
      if (clean != null) {
        rows.add(_ProductInfoRow(label: label, value: clean, color: color));
      }
    }

    final options = session.deliveryOptionsFor(product);
    final hasDelivery = options.any(
      (option) => option != BuyV2DeliveryOption.collection,
    );
    add(
      'Delivery',
      hasDelivery ? buyerPromise : 'Check delivery availability',
      color: hasDelivery ? BuyV2Colors.green : BuyV2Colors.muted,
    );
    if (hasDelivery) {
      final mode = session.fulfilmentModeFor(product);
      final method = session.supportsFulfilment(product, mode)
          ? buyV2FulfilmentModeLabel(mode)
          : 'Scheduled delivery';
      add('Method', method);
      add('Delivery fee', facts.deliveryFeeLabel);
      add('Order cutoff', facts.orderCutoffLabel);
      if (normalize(facts.dispatchPromise ?? '') != normalize(buyerPromise)) {
        add('Dispatch', facts.dispatchPromise);
      }
      add('Provider', facts.deliveryProviderName);
      if (normalize(facts.deliveryServiceLevel ?? '') != normalize(method)) {
        add('Service', facts.deliveryServiceLevel);
      }
    }
    return Container(
      key: ValueKey('buy-automatic-fulfilment-${product.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F8FA)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E7EE), width: .75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Delivery & seller',
            style: context.buyBody.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final address = Text(
                'Deliver to ${session.selectedAddressOrNull?.shortLine ?? 'your address'}',
                style: context.buyBody.copyWith(fontSize: 12, height: 1.35),
              );
              final change = TextButton(
                key: ValueKey('buy-product-change-address-${product.id}'),
                onPressed: () => showBuyV2AddressSheet(context, session),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Change'),
              );
              if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [address, change],
                );
              }
              return Row(
                children: [
                  Expanded(child: address),
                  change,
                ],
              );
            },
          ),
          const SizedBox(height: 1),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: .5, color: BuyV2Colors.line),
            rows[i],
          ],
          const Divider(height: 12, thickness: .5, color: BuyV2Colors.line),
          widget.storeSummary,
          const Divider(height: 10, thickness: .5, color: BuyV2Colors.line),
          widget.sellerActions,
        ],
      ),
    );
  }
}

// Stable public attribute identities, never inferred from translated labels or
// equal values. Structured compliance owns legal facts when both sources supply
// them; content may supply a missing producer fact through this same owner.
const _legalProductAttributeIds = {
  'generic_name',
  'net_quantity',
  'manufacturer_name',
  'manufacturer_address',
  'packer_name',
  'packer_address',
  'importer_name',
  'importer_address',
  'country_of_origin',
  'manufactured_or_packed_on',
  'best_before_or_use_by',
  'fssai_license_number',
  'consumer_care',
};

class BuyV2ProductCompliancePanel extends StatelessWidget {
  const BuyV2ProductCompliancePanel({
    required this.product,
    this.summaryAlreadyShown = false,
    this.inline = false,
    this.sourceFields = const [],
    super.key,
  });

  final BuyV2Product product;
  final bool summaryAlreadyShown;
  final bool inline;
  final List<BuyV2ProductSpecification> sourceFields;

  @override
  Widget build(BuildContext context) {
    final compliance = product.compliance;
    final published = <String, String>{};
    for (final field in sourceFields) {
      final id = field.attributeId;
      if (_legalProductAttributeIds.contains(id) &&
          field.value.trim().isNotEmpty) {
        published.putIfAbsent(id!, () => field.value);
      }
    }
    String? supplied(String id, String? value) =>
        _nonBlankComplianceValue(value) ??
        _nonBlankComplianceValue(published[id]);
    final genericName = supplied('generic_name', compliance?.genericName);
    final netQuantity = supplied('net_quantity', compliance?.netQuantity);
    final manufacturer = supplied(
      'manufacturer_name',
      compliance?.manufacturerName,
    );
    final packer = supplied('packer_name', compliance?.packerName);
    final importer = supplied('importer_name', compliance?.importerName);
    final manufacturerAddress = supplied(
      'manufacturer_address',
      compliance?.manufacturerAddress,
    );
    final packerAddress = supplied('packer_address', compliance?.packerAddress);
    final importerAddress = supplied(
      'importer_address',
      compliance?.importerAddress,
    );
    final countryOfOrigin = supplied(
      'country_of_origin',
      compliance?.countryOfOrigin,
    );
    final manufacturedOrPackedOn = supplied(
      'manufactured_or_packed_on',
      compliance?.manufacturedOrPackedOnLabel,
    );
    final bestBeforeOrUseBy = supplied(
      'best_before_or_use_by',
      compliance?.bestBeforeOrUseByLabel,
    );
    final fssai = supplied(
      'fssai_license_number',
      compliance?.fssaiLicenseNumber,
    );
    final consumerCare = supplied('consumer_care', compliance?.consumerCare);
    if (summaryAlreadyShown &&
        [
          genericName,
          netQuantity,
          manufacturer,
          packer,
          importer,
          manufacturerAddress,
          packerAddress,
          importerAddress,
          countryOfOrigin,
          manufacturedOrPackedOn,
          bestBeforeOrUseBy,
          fssai,
          consumerCare,
        ].every((value) => value == null)) {
      return const SizedBox.shrink();
    }
    final children = <Widget>[
      if (!summaryAlreadyShown || genericName != null)
        _DecisionRow(
          icon: Icons.category_outlined,
          label: genericName == null ? 'Product' : 'Generic name',
          value: genericName ?? product.customerTitle,
        ),
      if (!summaryAlreadyShown || netQuantity != null)
        _DecisionRow(
          icon: Icons.scale_outlined,
          label: netQuantity == null ? 'Pack' : 'Net quantity',
          value: netQuantity ?? product.pack,
        ),
      if (!summaryAlreadyShown && product.mrp != null)
        _DecisionRow(
          icon: Icons.currency_rupee_rounded,
          label: 'MRP (incl. taxes)',
          value: buyV2Money(product.mrp!),
        ),
      if (!summaryAlreadyShown && product.unitPrice.isNotEmpty)
        _DecisionRow(
          icon: Icons.price_check_outlined,
          label: 'Unit price',
          value: product.unitPrice,
        ),
      if (manufacturer case final value?)
        _DecisionRow(
          icon: Icons.factory_outlined,
          label: 'Manufacturer',
          value: value,
        ),
      if (packer case final value?)
        _DecisionRow(
          icon: Icons.inventory_2_outlined,
          label: 'Packer',
          value: value,
        ),
      if (importer case final value?)
        _DecisionRow(
          icon: Icons.public_outlined,
          label: 'Importer',
          value: value,
        ),
      if (countryOfOrigin case final value?)
        _DecisionRow(
          icon: Icons.flag_outlined,
          label: 'Country of origin',
          value: value,
        ),
      if (manufacturedOrPackedOn case final value?)
        _DecisionRow(
          icon: Icons.event_outlined,
          label: 'Manufactured or packed',
          value: value,
        ),
      if (bestBeforeOrUseBy case final value?)
        _DecisionRow(
          icon: Icons.event_available_outlined,
          label: 'Best before / use by',
          value: value,
        ),
      if (fssai case final value?)
        _DecisionRow(
          icon: Icons.verified_outlined,
          label: 'FSSAI licence',
          value: value,
        ),
      if (consumerCare case final value?)
        _DecisionRow(
          icon: Icons.support_agent_outlined,
          label: 'Consumer care',
          value: value,
        ),
      for (final entry in {
        'Manufacturer address': manufacturerAddress,
        'Packer address': packerAddress,
        'Importer address': importerAddress,
      }.entries)
        if (entry.value case final value?)
          _DecisionRow(
            icon: Icons.location_on_outlined,
            label: entry.key,
            value: value,
          ),
    ];
    if (inline) {
      final rows = children.cast<_DecisionRow>().toList();
      const order = [
        'Generic name',
        'Country of origin',
        'Net quantity',
        'Manufacturer',
        'Manufacturer address',
        'Packer',
        'Packer address',
        'Importer',
        'Importer address',
        'Manufactured or packed',
        'Best before / use by',
        'FSSAI licence',
        'Consumer care',
      ];
      rows.sort(
        (a, b) => order.indexOf(a.label).compareTo(order.indexOf(b.label)),
      );
      Widget field(_DecisionRow row) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.label, style: context.buyMeta.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            Text(row.value, style: context.buyBody.copyWith(fontSize: 14)),
          ],
        ),
      );
      final paired = rows
          .where(
            (row) =>
                row.label == 'Generic name' || row.label == 'Country of origin',
          )
          .toList();
      return Column(
        key: ValueKey('buy-product-compliance-${product.id}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (paired.length == 2 &&
              MediaQuery.textScalerOf(context).scale(14) <= 21)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: field(paired.first)),
                const SizedBox(width: 12),
                Expanded(child: field(paired.last)),
              ],
            )
          else
            for (final row in paired) field(row),
          for (final row in rows.where((row) => !paired.contains(row))) ...[
            field(row),
            const Divider(height: 1),
          ],
        ],
      );
    }
    return _DecisionPanel(
      key: ValueKey('buy-product-compliance-${product.id}'),
      title: 'Product and pack information',
      children: children,
    );
  }
}

String? _nonBlankComplianceValue(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

class _ProductHeroFact extends StatelessWidget {
  const _ProductHeroFact({
    required this.icon,
    required this.value,
    this.color = BuyV2Colors.ink,
    this.trailing,
    this.deliveryArtwork,
    super.key,
  });

  final IconData icon;
  final String value;
  final Color color;
  final Widget? trailing;
  final BuyV2DeliveryArtwork? deliveryArtwork;

  @override
  Widget build(BuildContext context) {
    final fact = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (deliveryArtwork case final artwork?)
          BuyV2DeliveryModeIcon(artwork: artwork, size: 17, color: color)
        else
          Icon(icon, size: 17, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            style: context.buyBody.copyWith(
              color: color,
              fontSize: 10,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
    final action = trailing;
    return BuyV2CartAvoidanceRegion(
      child: action == null
          ? fact
          : MediaQuery.textScalerOf(context).scale(1) > 1.25
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [fact, const SizedBox(height: 6), action],
            )
          : Row(
              children: [
                Expanded(child: fact),
                const SizedBox(width: 8),
                action,
              ],
            ),
    );
  }
}

class _ProductQuickActions extends StatelessWidget {
  const _ProductQuickActions({
    required this.session,
    required this.product,
    required this.onAskSeller,
    this.onVisitProduct,
    this.storeAction,
  });

  final BuyV2Session session;
  final Widget? storeAction;
  final BuyV2Product product;
  final ValueChanged<BuyV2Product>? onAskSeller;
  final Future<void> Function(BuyV2Product)? onVisitProduct;

  @override
  Widget build(BuildContext context) {
    final saved = session.isSaved(product.id);
    final sellerType = product.sellerType.toLowerCase();
    final supplierQuestionLabel = sellerType.contains('manufacturer')
        ? 'Ask manufacturer'
        : product.destination == BuyV2Destination.wholesale
        ? 'Ask supplier'
        : 'Ask seller';
    final galleryActions =
        product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale;
    final actions = <({IconData icon, String label, VoidCallback onPressed})>[
      if (!galleryActions)
        (
          icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          label: saved ? 'Saved' : 'Save',
          onPressed: () => session.toggleSaved(product.id),
        ),
      if (!galleryActions)
        (
          icon: Icons.ios_share_outlined,
          label: 'Share',
          onPressed: () => unawaited(
            _shareBuyV2Product(context, session: session, product: product),
          ),
        ),
      (
        icon: Icons.compare_arrows_rounded,
        label: 'Compare',
        onPressed: () => unawaited(
          _showBuyV2ProductComparison(
            context,
            session: session,
            current: product,
            onVisitProduct: onVisitProduct,
          ),
        ),
      ),
      if (onAskSeller != null)
        (
          icon: Icons.chat_bubble_outline_rounded,
          label: supplierQuestionLabel,
          onPressed: () => onAskSeller!(product),
        ),
    ];
    return Semantics(
      key: ValueKey('buy-product-quick-actions-${product.id}'),
      container: true,
      label: 'Product actions for ${product.customerTitle}',
      child: Container(
        decoration: galleryActions
            ? null
            : buyV2CardDecoration(
                color: BuyV2Colors.softBlue.withValues(alpha: .42),
                radius: 15,
              ),
        child: SingleChildScrollView(
          key: ValueKey('buy-product-actions-scroll-${product.id}'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final action in actions)
                _ProductQuickActionButton(
                  key: ValueKey(
                    'buy-product-action-${action.label.toLowerCase().replaceAll(' ', '-')}-${product.id}',
                  ),
                  icon: action.icon,
                  label: action.label == 'Compare'
                      ? 'Compare prices'
                      : action.label.startsWith('Ask ')
                      ? 'Ask'
                      : action.label,
                  semanticLabel: action.label == 'Compare'
                      ? 'Compare prices'
                      : action.label,
                  onPressed: action.onPressed,
                ),
              ?storeAction,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductQuickActionButton extends StatelessWidget {
  const _ProductQuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String? semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BuyV2CartAvoidanceRegion(
      child: Semantics(
        button: true,
        label: semanticLabel ?? label,
        onTap: onPressed,
        excludeSemantics: true,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(13),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF326C76)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: EdgeInsets.zero,
                    child: Text(
                      label,
                      softWrap: false,
                      style: context.buyMeta.copyWith(
                        color: BuyV2Colors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _shareBuyV2Product(
  BuildContext context, {
  required BuyV2Session session,
  required BuyV2Product product,
}) async {
  final facts = session.productFactsFor(product);
  final renderBox = context.findRenderObject() as RenderBox?;
  final origin = renderBox == null
      ? const Rect.fromLTWH(0, 0, 1, 1)
      : renderBox.localToGlobal(Offset.zero) & renderBox.size;
  final productLink = buyV2SharedProductUri(product);
  try {
    await SharePlus.instance.share(
      ShareParams(
        title: product.customerTitle,
        subject: '${product.customerTitle} on MoolSocial',
        text:
            '${product.customerTitle} · ${product.pack}\n'
            '${buyV2Money(facts.price)} · ${buyV2BuyerDeliveryPromise(facts)}\n'
            'Available from ${product.customerSeller(facts.partner)} on MoolSocial.\n'
            '$productLink',
        sharePositionOrigin: origin,
        downloadFallbackEnabled: false,
        mailToFallbackEnabled: false,
      ),
    );
  } on Object {
    session.showNotice('Sharing is unavailable right now. Try again.');
  }
}

Future<void> _showBuyV2ProductComparison(
  BuildContext context, {
  required BuyV2Session session,
  required BuyV2Product current,
  Future<void> Function(BuyV2Product)? onVisitProduct,
}) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: false,
  backgroundColor: Colors.white,
  constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (context) => SizedBox(
    height: MediaQuery.sizeOf(context).height,

    child: _ProductComparisonSheet(
      session: session,
      product: current,
      onVisitProduct: onVisitProduct,
    ),
  ),
);

String _comparisonMoney(int minor) {
  final whole = buyV2Money(minor ~/ 100);
  final fraction = minor % 100;
  return fraction == 0
      ? whole
      : '$whole.${fraction.toString().padLeft(2, '0')}';
}

/// Reuses the existing Compare sheet; only eligible same-pack offers change.
class _ProductComparisonSheet extends StatefulWidget {
  const _ProductComparisonSheet({
    required this.session,
    required this.product,
    this.onVisitProduct,
  });
  final BuyV2Session session;
  final BuyV2Product product;
  final Future<void> Function(BuyV2Product)? onVisitProduct;
  @override
  State<_ProductComparisonSheet> createState() =>
      _ProductComparisonSheetState();
}

class _ProductComparisonSheetState extends State<_ProductComparisonSheet>
    with WidgetsBindingObserver {
  final _scroll = ScrollController();
  BuyV2ComparisonController? _controller;
  Timer? _expiry;
  String? _message;
  bool _opening = false;
  bool _cartChanging = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_parentChanged);
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  void _parentChanged() {
    _controller?.checkContext();
    _changed();
  }

  void _changed() {
    _expiry?.cancel();
    final page = _controller?.page;
    if (page != null) {
      var until = page.validUntil;
      for (final offer in page.offers) {
        if (offer.validUntil.isBefore(until)) until = offer.validUntil;
      }
      final remaining = until.difference(widget.session.catalogueNow());
      if (!remaining.isNegative) {
        _expiry = Timer(remaining + const Duration(milliseconds: 1), _changed);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _parentChanged();
  }

  Future<void> _reload() async {
    final session = widget.session;
    final source = session.comparisonSource;
    final query = session.comparisonQueryFor(widget.product);
    if (source == null || query == null) {
      _controller?.dispose();
      _controller = null;
      _message =
          session.procurementProductUnavailableMessage(widget.product) ??
          (session.selectedAddressOrNull == null
              ? 'Choose a delivery address before comparing prices.'
              : 'Prices from other suppliers are unavailable right now. Try again.');
      _changed();
      return;
    }
    _message = null;
    _controller ??= BuyV2ComparisonController(
      source: source,
      isCurrent: session.comparisonQueryIsCurrent,
      offerPermitted: session.comparisonOfferPermitted,
      now: session.catalogueNow,
    )..addListener(_changed);
    await _controller!.open(query);
  }

  Future<void> _openProduct(BuyV2ComparisonOffer offer) async {
    final controller = _controller;
    final visit = widget.onVisitProduct;
    if (_opening || controller == null || visit == null) return;
    if (!widget.session.admitComparisonProduct(controller, offer)) {
      _message =
          'This offer changed. Refresh the comparison before continuing.';
      _changed();
      return;
    }
    setState(() => _opening = true);
    try {
      await visit(offer.product);
    } finally {
      if (mounted) {
        _opening = false;
        _parentChanged();
      }
    }
  }

  bool _beforeSave(BuyV2ComparisonOffer offer) {
    final controller = _controller;
    if (controller == null ||
        !widget.session.admitComparisonProduct(controller, offer)) {
      _message =
          'This offer changed. Refresh the comparison before continuing.';
      _changed();
      return false;
    }
    return true;
  }

  Future<bool> _beforeCartChange(
    BuyV2ComparisonOffer offer,
    int quantity,
  ) async {
    if (_cartChanging || !_beforeSave(offer)) return false;
    if (quantity == 0) return true;
    _cartChanging = true;
    try {
      final controller = _controller!;
      final session = widget.session;
      final amount =
          BigInt.from(quantity) * BigInt.from(offer.identity.packQuantityMilli);
      final query = amount > BigInt.from(9007199254740991)
          ? null
          : session.comparisonQueryFor(
              widget.product,
              requestedQuantityMilli: amount.toInt(),
              samePack: true,
              scope: controller.query!.scope,
              channel: controller.query!.channel,
              fulfilment: controller.query!.fulfilment,
              sort: controller.query!.sort,
            );
      if (query == null) {
        _message =
            'This quantity is unavailable. Choose an available quantity.';
        _changed();
        return false;
      }
      if (query.key != controller.query!.key) {
        await controller.open(query);
        if (!mounted) return false;
      }
      final refreshed = controller.page?.offers
          .where(
            (value) =>
                value.product.id == offer.product.id &&
                value.storeId == offer.storeId,
          )
          .firstOrNull;
      if (refreshed == null ||
          !session.admitComparisonProduct(controller, refreshed)) {
        _message =
            'This supplier could not confirm that quantity. Refresh the comparison and try again.';
        _changed();
        return false;
      }
      final result = BuyV2ComparisonCalculation.evaluate(
        query: query,
        offer: refreshed,
        now: session.catalogueNow(),
      );
      if (!result.available || result.packCount != quantity) {
        _message =
            'This quantity is unavailable from this supplier. Choose an available quantity.';
        _changed();
        return false;
      }
      final retained = session.cartLines
          .where((line) => line.product.id == refreshed.product.id)
          .firstOrNull;
      if ((retained != null &&
              retained.product.price != refreshed.product.price) ||
          BigInt.from(refreshed.product.price) *
                  BigInt.from(quantity) *
                  BigInt.from(100) !=
              BigInt.from(result.itemSubtotalMinor!)) {
        _message =
            'The Cart price needs to refresh before this offer can be added. Try again.';
        _changed();
        return false;
      }
      _message = null;
      return true;
    } finally {
      _cartChanging = false;
    }
  }

  String _date(DateTime time) {
    final local = time.toLocal();
    final labels = MaterialLocalizations.of(context);
    return '${labels.formatShortMonthDay(local)}${local.year == widget.session.catalogueNow().toLocal().year ? '' : ', ${local.year}'}, '
        '${labels.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  Future<void> _page(bool next) async {
    final controller = _controller;
    if (controller == null) return;
    if (next) {
      await controller.next();
    } else {
      await controller.previous();
    }
    if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    widget.session.removeListener(_parentChanged);
    WidgetsBinding.instance.removeObserver(this);
    _expiry?.cancel();
    _controller?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final query = controller?.query;
    final page = controller?.page;
    final message = _message ?? controller?.message;
    return SafeArea(
      key: const ValueKey('buy-product-comparison-sheet'),
      top: false,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(10, 4, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Compare prices',
                    style: context.buyTitle.copyWith(fontSize: 16),
                  ),
                ),
                IconButton(
                  key: const ValueKey('buy-comparison-refresh'),
                  tooltip: 'Refresh comparison',
                  onPressed: controller?.loading == true
                      ? null
                      : () => unawaited(_reload()),
                  icon: const Icon(Icons.refresh_rounded, size: 21),
                  color: BuyV2ActionStyle.primaryForeground,
                ),
                IconButton(
                  tooltip: 'Close comparison',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  color: BuyV2ActionStyle.primaryForeground,
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  widget.product.customerTitle,
                  style: context.buyBody.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.product.pack}${query == null ? '' : ' · ${_packCountLabel(query.requestedQuantityMilli ~/ query.identity.packQuantityMilli)}'}',
                  style: context.buyMeta.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (message != null)
              Text(message, key: const ValueKey('buy-comparison-message')),
            if (controller?.loading == true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (page != null && query != null) ...[
              if (page.offers.isEmpty)
                const Text(
                  'No other suppliers match this pack, quantity and delivery choice.',
                ),
              if (page.offers.isNotEmpty && controller!.storeOffers.isEmpty)
                const Text(
                  'No new Stores on this page. Continue to more Stores.',
                ),
              Column(
                key: const ValueKey('buy-vertical-product-grid-comparison'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final offer in controller!.storeOffers)
                    Padding(
                      key: ValueKey('buy-product-compare-${offer.product.id}'),
                      padding: const EdgeInsets.only(bottom: 6),
                      child: BuyV2ProductCard(
                        session: widget.session,
                        product: offer.product,
                        compact: true,
                        initialAddQuantity:
                            query.requestedQuantityMilli ~/
                            query.identity.packQuantityMilli,
                        onOpenProduct: (_) {
                          if (!_opening) unawaited(_openProduct(offer));
                        },
                        beforeSave: () => _beforeSave(offer),
                        beforeCartChange: (quantity) =>
                            _beforeCartChange(offer, quantity),
                        comparisonTotal: _comparisonDeliveredTotal(
                          offer,
                          query,
                          widget.session.catalogueNow(),
                        ),
                        comparisonSummary: _ProductComparisonPrices(
                          offer: offer,
                          query: query,
                          page: page,
                          now: widget.session.catalogueNow(),
                          dateLabel: _date,
                        ),
                      ),
                    ),
                ],
              ),
              if (page.previousCursor != null || page.nextCursor != null)
                Wrap(
                  spacing: 8,
                  children: [
                    if (page.previousCursor != null)
                      TextButton(
                        key: const ValueKey('buy-comparison-previous'),
                        onPressed: controller.canGoPrevious
                            ? () => unawaited(_page(false))
                            : null,
                        child: const Text('Previous'),
                      ),
                    if (page.nextCursor != null)
                      TextButton(
                        key: const ValueKey('buy-comparison-next'),
                        onPressed: controller.canGoNext
                            ? () => unawaited(_page(true))
                            : null,
                        child: const Text('More Stores'),
                      ),
                  ],
                ),
              Text(
                'Prices and availability are checked again before checkout.',
                style: context.buyMeta,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _comparisonDeliveredTotal(
  BuyV2ComparisonOffer offer,
  BuyV2ComparisonQuery query,
  DateTime now,
) {
  final result = BuyV2ComparisonCalculation.evaluate(
    query: query,
    offer: offer,
    now: now,
  );
  if (!result.available) return 'Offer changed';
  return result.payableMinor == null
      ? 'Delivered total not confirmed'
      : '${_comparisonMoney(result.payableMinor!)} delivered';
}

class _ProductComparisonPrices extends StatelessWidget {
  const _ProductComparisonPrices({
    required this.offer,
    required this.query,
    required this.page,
    required this.now,
    required this.dateLabel,
  });
  final BuyV2ComparisonOffer offer;
  final BuyV2ComparisonQuery query;
  final BuyV2ComparisonPage page;
  final DateTime now;
  final String Function(DateTime) dateLabel;

  @override
  Widget build(BuildContext context) {
    final result = BuyV2ComparisonCalculation.evaluate(
      query: query,
      offer: offer,
      now: now,
    );
    if (!result.available) {
      return const Text('Offer changed. Refresh comparison.');
    }
    final badges = [
      if (page.isLowestItemPrice(offer, result)) 'Lowest item price',
      if (page.isLowestDelivered(offer, result)) 'Lowest delivered cost',
    ];
    final start = offer.arrivalStart?.toLocal();
    final end = offer.arrivalEnd?.toLocal();
    final sameDay =
        start != null &&
        end != null &&
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final arrival = start == null || end == null
        ? 'Arrival time not confirmed'
        : 'Arrives ${dateLabel(start)} – ${sameDay ? MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(end)) : dateLabel(end)}';
    final style = context.buyMeta.copyWith(
      fontSize: 11,
      height: 1.25,
      color: const Color(0xFF505568),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 2,
          children: [
            Text(
              'Items: ${_comparisonMoney(result.itemSubtotalMinor!)}',
              key: ValueKey('buy-comparison-item-price-${offer.id}'),
              style: style,
            ),
            Text(
              offer.charges.freightMinor == null
                  ? 'Delivery: Not confirmed'
                  : 'Delivery: ${_comparisonMoney(offer.charges.freightMinor!)}',
              style: style,
            ),
          ],
        ),
        Text(arrival, style: style),
        if (badges.isNotEmpty)
          Text(
            badges.join(' · '),
            style: style.copyWith(
              color: const Color(0xFF17652C),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _ProductPriceExtras extends StatefulWidget {
  const _ProductPriceExtras({
    required this.session,
    required this.product,
    required this.facts,
    required this.content,
  });
  final BuyV2Session session;
  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final BuyV2ProductContentSnapshot content;

  @override
  State<_ProductPriceExtras> createState() => _ProductPriceExtrasState();
}

class _ProductPriceExtrasState extends State<_ProductPriceExtras>
    with WidgetsBindingObserver {
  Timer? _expiry;
  bool _detailsExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleExpiry();
  }

  @override
  void didUpdateWidget(covariant _ProductPriceExtras oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) _detailsExpanded = false;
    _scheduleExpiry();
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    final now = widget.session.catalogueNow();
    final ends = [
      widget.content.priceHistory?.validUntil,
      widget.product.packTerms?.priceValidUntil,
    ].whereType<DateTime>().where((end) => end.isAfter(now)).toList()..sort();
    if (ends.isEmpty) return;
    final remaining = ends.first.difference(now);
    if (remaining <= Duration.zero) return;
    // Recheck long-lived data without exceeding platform timer ranges.
    final delay = remaining > const Duration(days: 1)
        ? const Duration(days: 1)
        : remaining;
    _expiry = Timer(delay, () {
      if (!mounted) return;
      setState(() {});
      _scheduleExpiry();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _scheduleExpiry();
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final facts = widget.session.productFactsFor(product);
    final terms = product.packTerms;
    final hasTiers = terms != null && terms.priceTiers.isNotEmpty;
    final mrp = product.mrp;
    final saving =
        !facts.stale && facts.price > 0 && mrp != null && mrp > facts.price;
    final history = widget.content.priceHistory;
    final showDrop =
        widget.content.state == BuyV2ProductContentState.ready &&
        widget.content.sourceId.trim().isNotEmpty &&
        history != null &&
        history.isCurrentFor(
          product,
          facts: facts,
          now: widget.session.catalogueNow(),
        ) &&
        history.previousSellingPriceMinor > history.currentSellingPriceMinor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              key: ValueKey('buy-product-pack-summary-${product.id}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.unitPrice.isNotEmpty && facts.price == product.price
                      ? '${product.pack} · ${product.unitPrice}'
                      : product.pack,
                  style: context.buyMeta.copyWith(fontWeight: FontWeight.w700),
                ),
                if (product.destination == BuyV2Destination.wholesale)
                  Text(
                    'Minimum ${_packCountLabel(product.minimumOrder)} · ${buyV2Money(product.minimumOrderTotal(facts.price))}',
                    style: context.buyMeta,
                  ),
                if (product.packTerms != null &&
                    ((product.destination != BuyV2Destination.wholesale &&
                            product.minimumOrder > 1) ||
                        product.quantityStep > 1))
                  Text(
                    product.destination == BuyV2Destination.wholesale
                        ? 'Step ${product.quantityStep}'
                        : 'Minimum ${_packCountLabel(product.minimumOrder)} · Step ${product.quantityStep}',
                    key: ValueKey('buy-product-pack-rule-${product.id}'),
                    style: context.buyMeta,
                  ),
              ],
            ),
            if (saving)
              Wrap(
                key: ValueKey('buy-product-discount-${product.id}'),
                spacing: 8,
                children: [
                  Text(
                    '${((mrp - facts.price) * 100) ~/ mrp}% off',
                    style: context.buyMeta.copyWith(
                      color: BuyV2Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            TextButton.icon(
              key: ValueKey('buy-product-price-details-${product.id}'),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _detailsExpanded = !_detailsExpanded);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(48, 48),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                foregroundColor: const Color(0xFF326C76),
                visualDensity: VisualDensity.compact,
              ),
              icon: Icon(
                _detailsExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: const Text('Price details'),
            ),
          ],
        ),
        if (_detailsExpanded)
          Container(
            key: ValueKey('buy-product-price-details-inline-${product.id}'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFFF3F7F9), Color(0xFFFAFCFD)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (facts.stale || facts.price <= 0)
                  Text(
                    'Check availability to confirm the current price.',
                    style: context.buyMeta,
                  )
                else ...[
                  if (mrp != null && mrp >= facts.price) ...[
                    _ProductInfoRow(
                      label: 'MRP (incl. taxes)',
                      value: buyV2Money(mrp),
                    ),
                    _ProductInfoRow(
                      label: 'Discount',
                      value: buyV2Money(mrp - facts.price),
                    ),
                  ],
                  _ProductInfoRow(
                    label: hasTiers ? 'Price per ${terms.sellUnit}' : 'Total',
                    value: buyV2Money(facts.price),
                  ),
                  if (hasTiers) ...[
                    for (final tier in terms.priceTiers)
                      _ProductInfoRow(
                        label: '${tier.minimumPacks}+ packs',
                        value: '${buyV2Money(tier.price)} / ${terms.sellUnit}',
                      ),
                    _ProductInfoRow(
                      label: 'Tax',
                      value: terms.pricesIncludeTax == null
                          ? 'Not yet confirmed'
                          : terms.pricesIncludeTax!
                          ? 'Included'
                          : 'Extra',
                    ),
                    _ProductInfoRow(
                      label: 'Freight',
                      value: terms.pricesIncludeFreight == null
                          ? 'Not yet confirmed'
                          : terms.pricesIncludeFreight!
                          ? 'Included'
                          : 'Extra',
                    ),
                    Text(
                      'Item prices only. Final charges are confirmed at checkout.',
                      style: context.buyMeta,
                    ),
                  ] else
                    Text(
                      'Delivery fees and any order discounts are confirmed in Cart.',
                      style: context.buyMeta,
                    ),
                ],
              ],
            ),
          ),
        if (showDrop) ...[
          Text(
            'Price dropped by ${_comparisonMoney(history.previousSellingPriceMinor - history.currentSellingPriceMinor)}',
            key: ValueKey('buy-product-price-drop-${product.id}'),
            style: context.buyBody.copyWith(color: BuyV2Colors.green),
          ),
          Text(
            'Previously ${_comparisonMoney(history.previousSellingPriceMinor)} · '
            '${MaterialLocalizations.of(context).formatMediumDate(history.previousEffectiveAt)}',
            style: context.buyMeta,
          ),
        ],
      ],
    );
  }
}

Future<void> _showProductSizeChart(
  BuildContext context,
  BuyV2Session session,
  BuyV2Product product,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
  builder: (context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) {
      final current = session.findProduct(product.id);
      final content = current == null
          ? null
          : session.productContentFor(current);
      final chart = content?.sizeChart;
      final valid =
          current != null &&
          content?.state == BuyV2ProductContentState.ready &&
          content!.sourceId.trim().isNotEmpty &&
          chart?.appliesTo(current) == true;
      return _ProductInformationSheet(
        title: 'Size chart',
        children: [
          if (!valid)
            const Text('Size chart is unavailable right now.')
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                key: ValueKey('buy-product-size-chart-table-${product.id}'),
                defaultColumnWidth: const FixedColumnWidth(140),
                border: const TableBorder(
                  horizontalInside: BorderSide(color: BuyV2Colors.line),
                ),
                children: [
                  TableRow(
                    children: [
                      for (final label in chart!.columns)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Semantics(
                            header: true,
                            child: Text(
                              label,
                              style: context.buyTitle.copyWith(fontSize: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (final row in chart.rows)
                    TableRow(
                      children: [
                        for (final value in row)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(value, style: context.buyBody),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            for (final instruction in chart.instructions)
              if (instruction.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(instruction, style: context.buyBody),
                ),
          ],
        ],
      );
    },
  ),
);

/// Shared by read-only product information sheets. Existing route,
/// selection, address, Cart and checkout state continue to belong to the session.
class _ProductAssuranceControls extends StatelessWidget {
  const _ProductAssuranceControls({
    required this.session,
    required this.product,
    this.onAskSeller,
  });
  final BuyV2Session session;
  final BuyV2Product product;
  final ValueChanged<BuyV2Product>? onAskSeller;

  Future<void> _support(BuildContext context) => showBuyV2ShoppingHelp(
    context,
    session,
    product: product,
    onAskSeller: onAskSeller == null ? null : () => onAskSeller!(product),
  );

  Future<void> _returns(BuildContext context) async {
    final openHelp = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => AnimatedBuilder(
        animation: session,
        builder: (context, _) {
          final current = session.selectedProduct;
          final lines = current?.id == product.id
              ? _purchaseProtectionLines(current!)
              : <String>[];
          if (lines.isEmpty && current?.id == product.id) {
            final trust = session.marketplaceTrustFor(current!);
            final summary = _nonBlankComplianceValue(trust.returnSummary);
            if (trust.state == BuyV2MarketplaceTrustState.ready &&
                summary != null) {
              lines.add(summary);
            }
          }
          return _ProductInformationSheet(
            title: 'Return policy',
            children: [
              if (lines.isEmpty)
                Text('Return policy unavailable', style: context.buyBody),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(line, style: context.buyBody),
                ),
              TextButton.icon(
                key: const ValueKey('buy-product-how-to-return'),
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.help_outline),
                label: const Text('How to return'),
              ),
            ],
          );
        },
      ),
    );
    if (openHelp == true && context.mounted) await _support(context);
  }

  Future<void> _payment(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => _ProductInformationSheet(
      title: 'Cash on Delivery',
      children: [
        Text(
          'Cash on Delivery availability is not confirmed.',
          style: context.buyBody,
        ),
        const SizedBox(height: 8),
        Text(
          'Review the available payment methods and amount payable at checkout.',
          style: context.buyMeta,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      Widget control(
        String id,
        IconData icon,
        String label,
        VoidCallback action,
      ) => SizedBox(
        child: TextButton(
          key: ValueKey('buy-product-assurance-$id-${product.id}'),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          ),
          onPressed: action,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF326C76)),
              const SizedBox(width: 6),
              Padding(
                padding: EdgeInsets.zero,
                child: Text(
                  label,
                  softWrap: false,
                  style: const TextStyle(
                    color: BuyV2Colors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return Container(
        decoration: BoxDecoration(
          color: BuyV2ActionStyle.primaryFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BuyV2Colors.line, width: .5),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          key: ValueKey('buy-product-assurance-scroll-${product.id}'),
          child: Row(
            key: ValueKey('buy-product-assurance-${product.id}'),
            children: [
              control(
                'returns',
                Icons.assignment_return_outlined,
                'Returns',
                () => _returns(context),
              ),
              control(
                'payment',
                Icons.payments_outlined,
                'Cash on Delivery',
                () => _payment(context),
              ),
              control(
                'support',
                Icons.support_agent_outlined,
                'Customer support',
                () => _support(context),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ProductInformationSheet extends StatelessWidget {
  const _ProductInformationSheet({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.buyTitle.copyWith(fontSize: 18),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProductVariantSelector extends StatelessWidget {
  const _ProductVariantSelector({
    required this.session,
    required this.product,
    required this.variants,
    this.sizeChart,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final List<BuyV2Product> variants;
  final BuyV2ProductSizeChart? sizeChart;

  @override
  Widget build(BuildContext context) {
    if (product.hasStructuredVariants) {
      final loading = session.variantFamilyLoadingFor(product);
      final message = session.variantFamilyMessageFor(product);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StructuredProductVariants(
            session: session,
            product: product,
            variants: variants,
            sizeChart: sizeChart,
          ),
          if (loading || message != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                loading ? 'Loading options…' : message!,
                key: ValueKey('buy-variant-family-status-${product.id}'),
                style: context.buyBody.copyWith(fontSize: 11),
              ),
            ),
          if (session.variantWithdrawn(product))
            Text(
              variants.isEmpty
                  ? 'This product is no longer available.'
                  : 'This option is no longer available. Choose another option.',
              style: context.buyBody.copyWith(fontSize: 11),
            ),
        ],
      );
    }
    return BuyV2CartAvoidanceRegion(
      child: Container(
        key: ValueKey('buy-product-variants-${product.canonicalId}'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF4F2FB), Color(0xFFFAFCFA)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BuyV2Colors.line, width: .5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  product.destination == BuyV2Destination.medicine
                      ? 'Choose an option'
                      : 'Select ${sizeChart?.dimensionLabel ?? 'pack'}',
                  style: context.buyTitle.copyWith(fontSize: 14),
                ),
                if (sizeChart != null)
                  TextButton(
                    key: ValueKey('buy-product-size-chart-${product.id}'),
                    onPressed: () =>
                        _showProductSizeChart(context, session, product),
                    child: const Text('Size chart'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(12) > 18;
                final width = math.min(
                  largeText ? 172.0 : 112.0,
                  constraints.maxWidth * .8,
                );
                return _ProductVariantOptionsRow(
                  key: ValueKey('buy-variant-row-pack-${product.canonicalId}'),
                  selectedIndex: variants.indexWhere(
                    (item) => item.id == product.id,
                  ),
                  itemWidth: width,
                  children: [
                    for (final option in variants)
                      _ProductVariantOption(
                        session: session,
                        option: option,
                        selected: option.id == product.id,
                        width: width,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StructuredProductVariants extends StatelessWidget {
  const _StructuredProductVariants({
    required this.session,
    required this.product,
    required this.variants,
    this.sizeChart,
  });
  final BuyV2Session session;
  final BuyV2Product product;
  final List<BuyV2Product> variants;
  final BuyV2ProductSizeChart? sizeChart;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 18;
    final viewport = MediaQuery.sizeOf(context).width - 32;
    return BuyV2CartAvoidanceRegion(
      child: SingleChildScrollView(
        key: ValueKey('buy-product-variants-${product.canonicalId}'),
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final selected in product.variantAttributes)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _dimension(context, selected, largeText, viewport),
              ),
            if (session.hasVariantFamilySourceFor(product))
              IconButton(
                key: ValueKey('buy-variant-family-refresh-${product.id}'),
                tooltip: 'Refresh product options',
                onPressed: session.variantFamilyLoadingFor(product)
                    ? null
                    : () => unawaited(session.refreshVariantFamily(product)),
                icon: const Icon(Icons.refresh_rounded, size: 18),
              ),
            if (sizeChart != null)
              TextButton(
                key: ValueKey('buy-product-size-chart-${product.id}'),
                onPressed: () =>
                    _showProductSizeChart(context, session, product),
                child: const Text('Size chart'),
              ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _colourSelection(
    BuyV2VariantAttribute dimension,
    BuyV2VariantAttribute option,
  ) {
    final candidate = product.resolveVariantOption(
      variants,
      dimension.dimensionId,
      option.optionId,
    );
    return candidate == null
        ? null
        : () => session.selectProductVariant(candidate.id);
  }

  Widget _dimension(
    BuildContext context,
    BuyV2VariantAttribute selected,
    bool largeText,
    double viewport,
  ) {
    final options = <String, BuyV2VariantAttribute>{};
    for (final option in session.variantOptionsFor(product)) {
      if (option.dimensionId == selected.dimensionId &&
          option.kind == selected.kind) {
        options[option.optionId] = option;
      }
    }
    for (final variant in variants.where(
      (item) => item.hasStructuredVariants && item.isFromSameStoreAs(product),
    )) {
      for (final value in variant.variantAttributes) {
        if (value.dimensionId == selected.dimensionId &&
            value.kind == selected.kind) {
          options.putIfAbsent(value.optionId, () => value);
        }
      }
    }
    final colour = selected.kind == BuyV2VariantDimensionKind.colour;
    final width = colour
        ? 48.0
        : largeText
        ? 172.0
        : 100.0;
    final groupWidth = math.min(
      viewport,
      math.max(colour ? 100.0 : width, options.length * (width + 8) - 8),
    );
    return SizedBox(
      width: groupWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${selected.dimensionLabel}: ${selected.optionLabel}',
              style: context.buyBody.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _ProductVariantOptionsRow(
            key: ValueKey('buy-variant-row-${selected.dimensionId}'),
            selectedIndex: options.keys.toList().indexOf(selected.optionId),
            itemWidth: width,
            children: [
              for (final option in options.values)
                if (colour)
                  _ProductColourOption(
                    value: option,
                    selected: option.optionId == selected.optionId,
                    onSelected: _colourSelection(selected, option),
                  )
                else if (product.resolveVariantOption(
                      variants,
                      selected.dimensionId,
                      option.optionId,
                    )
                    case final candidate?)
                  _ProductVariantOption(
                    session: session,
                    option: candidate,
                    selected: candidate.id == product.id,
                    width: width,
                    optionLabel: option.optionLabel,
                    optionKey:
                        'buy-product-option-${selected.dimensionId}-${option.optionId}',
                  )
                else
                  SizedBox(
                    width: width,
                    child: OutlinedButton(
                      style: BuyV2ActionStyle.button(),
                      key: ValueKey(
                        'buy-product-option-${selected.dimensionId}-${option.optionId}',
                      ),
                      onPressed: null,
                      child: Text(
                        '${option.optionLabel}\n${session.variantFamilyLoadingFor(product) ? 'Checking…' : 'Combination unavailable'}',
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductColourOption extends StatelessWidget {
  const _ProductColourOption({
    required this.value,
    required this.selected,
    required this.onSelected,
  });
  final BuyV2VariantAttribute value;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${value.optionLabel}${onSelected == null ? ', combination unavailable' : ''}',
    checked: selected,
    inMutuallyExclusiveGroup: true,
    enabled: onSelected != null,
    child: Tooltip(
      message: value.optionLabel,
      child: InkResponse(
        key: ValueKey(
          'buy-product-option-${value.dimensionId}-${value.optionId}',
        ),
        onTap: onSelected,
        radius: 24,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? BuyV2Colors.navy : BuyV2Colors.line,
                  width: selected ? 2 : 1,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value.swatchArgb == null
                      ? Colors.transparent
                      : Color(value.swatchArgb!),
                  border: Border.all(color: BuyV2Colors.muted, width: .5),
                ),
                child: onSelected == null
                    ? const Icon(Icons.close, size: 14)
                    : value.swatchArgb == null
                    ? const Icon(Icons.question_mark, size: 14)
                    : null,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ProductVariantOptionsRow extends StatefulWidget {
  const _ProductVariantOptionsRow({
    super.key,
    required this.selectedIndex,
    required this.itemWidth,
    required this.children,
  });
  final int selectedIndex;
  final double itemWidth;
  final List<Widget> children;

  @override
  State<_ProductVariantOptionsRow> createState() =>
      _ProductVariantOptionsRowState();
}

class _ProductVariantOptionsRowState extends State<_ProductVariantOptionsRow> {
  late final ScrollController _controller;
  double get _selectedOffset =>
      math.max(0, widget.selectedIndex) * (widget.itemWidth + 8);

  @override
  void initState() {
    super.initState();
    _controller = ScrollController(initialScrollOffset: _selectedOffset);
  }

  @override
  void didUpdateWidget(covariant _ProductVariantOptionsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.itemWidth != widget.itemWidth ||
        oldWidget.children.length != widget.children.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.jumpTo(
          _selectedOffset.clamp(0.0, _controller.position.maxScrollExtent),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: _controller,
    scrollDirection: Axis.horizontal,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < widget.children.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          widget.children[index],
        ],
      ],
    ),
  );
}

class _ProductVariantOption extends StatelessWidget {
  const _ProductVariantOption({
    required this.session,
    required this.option,
    required this.selected,
    required this.width,
    this.optionLabel,
    this.optionKey,
  });

  final BuyV2Session session;
  final BuyV2Product option;
  final bool selected;
  final double width;
  final String? optionLabel;
  final String? optionKey;

  @override
  Widget build(BuildContext context) {
    final facts = session.productFactsFor(option);
    final decision = buyV2ResolveProductOfferDecision(
      product: option,
      facts: facts,
      quantity: session.quantityFor(option.id),
    );
    final statusColor = decision.canAdd
        ? BuyV2Colors.green
        : BuyV2Colors.orange;
    void select() {
      HapticFeedback.selectionClick();
      session.selectProductVariant(option.id);
    }

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label:
          '${optionLabel ?? option.pack}, ${buyV2Money(facts.price)}, ${decision.statusLabel}',
      onTap: select,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: BorderSide(
              color: selected
                  ? BuyV2ActionStyle.primaryForeground
                  : BuyV2ActionStyle.primaryBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? BuyV2ActionStyle.pressedFill
                  : BuyV2ActionStyle.primaryFill,
            ),
            child: InkWell(
              key: ValueKey(optionKey ?? 'buy-product-variant-${option.id}'),
              onTap: select,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              optionLabel ?? option.pack,
                              style: context.buyBody.copyWith(fontSize: 11),
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: BuyV2Colors.navy,
                            ),
                          ],
                        ],
                      ),
                      ...[
                        const SizedBox(height: 3),
                        Text(
                          buyV2Money(facts.price),
                          style: const TextStyle(
                            color: Color(0xFF24272B),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                      if (!decision.canAdd) ...[
                        const SizedBox(height: 2),
                        Text(
                          decision.statusLabel,
                          style: context.buyMeta.copyWith(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WholesaleVerificationCard extends StatelessWidget {
  const _WholesaleVerificationCard({
    required this.state,
    required this.onOpenWorkspace,
  });

  final BuyV2BusinessVerificationState state;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final title = switch (state) {
      BuyV2BusinessVerificationState.pending =>
        'Business verification is in progress',
      BuyV2BusinessVerificationState.rejected =>
        'Business details need attention',
      BuyV2BusinessVerificationState.unavailable =>
        'Verify your business to order wholesale',
      BuyV2BusinessVerificationState.verified => 'Business verified',
    };
    final detail = switch (state) {
      BuyV2BusinessVerificationState.pending =>
        'You can browse trade packs now. Ordering opens after verification.',
      BuyV2BusinessVerificationState.rejected =>
        'Open your business profile to review the requested details.',
      BuyV2BusinessVerificationState.unavailable =>
        'Use your business account for trade pricing, invoices and eligible payment methods.',
      BuyV2BusinessVerificationState.verified =>
        'Wholesale ordering is available for this business account.',
    };
    return Container(
      key: ValueKey('buy-wholesale-verification-${state.name}'),
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(
        color: BuyV2Colors.softOrange,
        border: BuyV2Colors.orange,
        radius: 15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.buyBody),
          const SizedBox(height: 3),
          Text(detail, style: context.buyMeta),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: BuyV2Metrics.minimumTap,
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: FilledButton.icon(
                style: BuyV2ActionStyle.button(),
                key: const ValueKey('buy-wholesale-open-workspace'),
                onPressed: onOpenWorkspace,
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: const Text('Open business profile'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WholesaleTradeDecisionPanel extends StatefulWidget {
  const _WholesaleTradeDecisionPanel({
    required this.session,
    required this.product,
    required this.facts,
    required this.decision,
    required this.buyerPromise,
    required this.storeSummary,
    required this.sellerActions,
    required this.adapter,
    required this.onOpenPartnerCatalogue,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final BuyV2ProductOfferDecision decision;
  final String buyerPromise;
  final Widget storeSummary;
  final Widget sellerActions;
  final BuyV2WholesaleTradeDecisionAdapter adapter;
  final BuyV2PartnerCatalogueHandler? onOpenPartnerCatalogue;

  @override
  State<_WholesaleTradeDecisionPanel> createState() =>
      _WholesaleTradeDecisionPanelState();
}

class _WholesaleTradeDecisionPanelState
    extends State<_WholesaleTradeDecisionPanel> {
  BuyV2WholesaleTradeSignal? _signal;
  Object? _failure;
  String? _loadedDeliveryLocality;
  var _loading = true;
  var _requestSequence = 0;

  @override
  void initState() {
    super.initState();
    _loadSignal();
  }

  @override
  void didUpdateWidget(covariant _WholesaleTradeDecisionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id ||
        oldWidget.adapter != widget.adapter ||
        _loadedDeliveryLocality !=
            widget.session.selectedAddressOrNull?.shortLine) {
      _loadSignal();
    }
  }

  Future<void> _loadSignal() async {
    final request = ++_requestSequence;
    final deliveryLocality = widget.session.selectedAddressOrNull?.shortLine;
    setState(() {
      _loading = true;
      _failure = null;
      _signal = null;
      _loadedDeliveryLocality = deliveryLocality;
    });
    try {
      final signal = await widget.adapter.load(
        productId: widget.product.id,
        canonicalProductId: widget.product.canonicalId,
        deliveryLocality: deliveryLocality,
      );
      if (!mounted || request != _requestSequence) return;
      if (signal.productId != widget.product.id) {
        setState(() {
          _loading = false;
          _failure = StateError('Trade signal product identity differs.');
        });
        return;
      }
      setState(() {
        _loading = false;
        _signal = signal;
      });
    } catch (error) {
      if (!mounted || request != _requestSequence) return;
      setState(() {
        _loading = false;
        _failure = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final facts = widget.facts;
    final decision = widget.decision;
    final fulfilmentMode = widget.session.fulfilmentModeFor(product);
    final minimumTotal = product.minimumOrderTotal(facts.price);
    final showSignal =
        _loading ||
        _failure != null ||
        _signal?.state != BuyV2WholesaleTradeSignalState.unavailable;
    final signalSummary = !showSignal
        ? ''
        : _loading
        ? 'Checking local market insight.'
        : _failure != null
        ? 'Local market insight could not be loaded.'
        : '${_signal!.headline}. ${_signal!.detail}';

    return Semantics(
      key: ValueKey('buy-wholesale-trade-decision-${product.id}'),
      container: true,
      label:
          '${product.customerTitle}. ${product.pack}. Minimum order '
          '${_packCountLabel(product.minimumOrder)}. ${buyV2Money(facts.price)} per pack. '
          '${buyV2Money(minimumTotal)} minimum order total. '
          '${facts.orderabilityLabel}. ${widget.buyerPromise}. '
          '${buyV2AutomaticFulfilmentLabel(product.destination)}. '
          '${decision.statusLabel}. $signalSummary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSignal) ...[
            const SizedBox(height: 8),
            _WholesaleTradeSignalCard(
              loading: _loading,
              signal: _signal,
              failed: _failure != null,
              onRetry: _loadSignal,
            ),
          ],
          const SizedBox(height: 8),
          _PublicProductOrderInformation(
            session: widget.session,
            product: product,
            facts: facts,
            buyerPromise: widget.buyerPromise,
            storeSummary: widget.storeSummary,
            sellerActions: widget.sellerActions,
          ),
          const SizedBox(height: 8),
          _DecisionPanel(
            key: ValueKey('buy-wholesale-commercial-terms-${product.id}'),
            title: 'Wholesale terms',
            softSurface: true,
            children: [
              _DecisionRow(
                icon: Icons.local_shipping_outlined,
                label: 'Freight',
                deliveryArtwork: buyV2DeliveryArtworkFor(
                  product,
                  fulfilmentMode: fulfilmentMode,
                ),
                value: product.freightIncluded
                    ? 'Included in price'
                    : 'Confirmed before payment',
              ),
              const _DecisionRow(
                icon: Icons.receipt_long_outlined,
                label: 'Tax invoice',
                value: 'GST included · invoice provided',
              ),
              _DecisionRow(
                icon: Icons.event_available_outlined,
                label: 'Price checked',
                value: _signal?.hasCurrentSignal == true
                    ? _signal?.priceValidUntilLabel ?? product.confirmedOn
                    : product.confirmedOn,
              ),
            ],
          ),
          if (!decision.canAdd) ...[
            const SizedBox(height: 8),
            Container(
              key: ValueKey('buy-product-offer-recovery-${product.id}'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BuyV2Colors.softOrange,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BuyV2Colors.orange.withValues(alpha: .34),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    decision.statusLabel,
                    style: context.buyBody.copyWith(
                      color: BuyV2Colors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(decision.detail, style: context.buyMeta),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Align(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: OutlinedButton.icon(
                          key: ValueKey('buy-offer-retry-${product.id}'),
                          style: BuyV2ActionStyle.button(
                            OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            widget.session.refreshProductFacts(product.id);
                            _loadSignal();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Check availability'),
                        ),
                      ),
                      Align(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: FilledButton.icon(
                          key: ValueKey(
                            'buy-offer-change-product-${product.id}',
                          ),
                          style: BuyV2ActionStyle.button(
                            FilledButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                          onPressed: widget.session.closeProduct,
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Change product'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Keep the monetary value intact even with enlarged system text. The parent
/// first gives long prices the full row; only then reduce display size to fit.
class _ProductHeroPrice extends StatelessWidget {
  const _ProductHeroPrice({
    required this.productId,
    required this.amount,
    required this.fontSize,
    this.mrp,
  });
  final String productId;
  final int amount;
  final double fontSize;
  final int? mrp;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final label = buyV2Money(amount);
      final style = context.buyTitle.copyWith(
        color: const Color(0xFF24272B),
        fontSize: fontSize,
      );
      final width = buyV2ValueTextSize(context, label, style).width;
      final ratio = width > 0 && constraints.maxWidth.isFinite
          ? ((constraints.maxWidth - 1) / width).clamp(0.0, 1.0)
          : 1.0;
      final price = Text(
        label,
        key: ValueKey('buy-product-hero-price-$productId'),
        style: style.copyWith(
          fontSize: (fontSize * ratio).clamp(12.0, fontSize),
        ),
        maxLines: 1,
        softWrap: false,
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          price,
          if (mrp != null && mrp! > amount)
            Text(
              buyV2Money(mrp!),
              key: ValueKey('buy-product-hero-mrp-$productId'),
              style: context.buyMeta.copyWith(
                decoration: TextDecoration.lineThrough,
              ),
            ),
        ],
      );
    },
  );
}

class _WholesaleTradePriceSummary extends StatelessWidget {
  const _WholesaleTradePriceSummary({
    required this.product,
    required this.facts,
    required this.decision,
    required this.action,
    required this.actionWidth,
  });

  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final BuyV2ProductOfferDecision decision;
  final Widget action;
  final double actionWidth;

  @override
  Widget build(BuildContext context) {
    final priceWidth =
        buyV2ValueTextSize(
          context,
          buyV2Money(facts.price),
          context.buyTitle.copyWith(fontSize: 24),
        ).width +
        2;
    final price = SizedBox(
      width: priceWidth,
      child: _ProductHeroPrice(
        productId: product.id,
        amount: facts.price,
        mrp: facts.stale ? null : product.mrp,
        fontSize: 24,
      ),
    );
    return Column(
      key: ValueKey('buy-wholesale-price-summary-${product.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                constraints.maxWidth <
                    actionWidth +
                        8 +
                        buyV2ValueTextSize(
                          context,
                          buyV2Money(facts.price),
                          context.buyTitle.copyWith(fontSize: 25),
                        ).width) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  price,
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }
            return Row(children: [price, const SizedBox(width: 8), action]);
          },
        ),
        if (!decision.canAdd)
          Text(
            decision.statusLabel,
            style: context.buyMeta.copyWith(color: BuyV2Colors.orange),
          ),
      ],
    );
  }
}

class _WholesaleTradeSignalCard extends StatelessWidget {
  const _WholesaleTradeSignalCard({
    required this.loading,
    required this.signal,
    required this.failed,
    required this.onRetry,
  });

  final bool loading;
  final BuyV2WholesaleTradeSignal? signal;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ready = !loading && !failed && signal?.hasCurrentSignal == true;
    final headline = loading
        ? 'Checking local market insight'
        : failed
        ? 'Local market insight could not be loaded'
        : signal!.headline;
    final detail = loading
        ? 'Current price, stock and delivery remain available while this loads.'
        : failed
        ? 'Check again or continue with the current price, stock and delivery details.'
        : signal!.detail;
    return Semantics(
      key: const ValueKey('buy-wholesale-local-trade-signal'),
      container: true,
      liveRegion: loading,
      label: '$headline. $detail',
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: ready ? BuyV2Colors.softGreen : BuyV2Colors.softOrange,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (ready ? BuyV2Colors.green : BuyV2Colors.orange).withValues(
              alpha: .32,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  ready ? Icons.trending_up_rounded : Icons.insights_outlined,
                  color: ready ? BuyV2Colors.green : BuyV2Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ready && signal!.localityLabel.isNotEmpty
                            ? '${signal!.localityLabel} market insight'
                            : 'Local market insight',
                        style: context.buyMeta.copyWith(
                          color: BuyV2Colors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        headline,
                        style: context.buyBody.copyWith(
                          color: BuyV2Colors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (loading)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(detail, style: context.buyMeta.copyWith(height: 1.35)),
            if (ready) ...[
              const SizedBox(height: 7),
              Text(
                '${signal!.sourceLabel} · ${signal!.updatedLabel}',
                key: const ValueKey('buy-wholesale-trade-signal-source'),
                style: context.buyMeta.copyWith(
                  color: BuyV2Colors.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ] else if (!loading) ...[
              const SizedBox(height: 8),
              Align(
                widthFactor: 1,
                heightFactor: 1,
                child: OutlinedButton.icon(
                  key: const ValueKey('buy-wholesale-trade-signal-retry'),
                  style: BuyV2ActionStyle.button(
                    OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  ),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Check local insight again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductOfferDecisionPanel extends StatelessWidget {
  const _ProductOfferDecisionPanel({
    required this.session,
    required this.product,
    required this.facts,
    required this.decision,
    required this.buyerPromise,
    required this.storeSummary,
    required this.sellerActions,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final BuyV2ProductOfferDecision decision;
  final String buyerPromise;
  final Widget storeSummary;
  final Widget sellerActions;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey('buy-product-offer-decision-${product.id}'),
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PublicProductOrderInformation(
            session: session,
            product: product,
            facts: facts,
            buyerPromise: buyerPromise,
            storeSummary: storeSummary,
            sellerActions: sellerActions,
          ),
          if (!decision.canAdd) ...[
            const SizedBox(height: 8),
            Container(
              key: ValueKey('buy-product-offer-recovery-${product.id}'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BuyV2Colors.softOrange,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BuyV2Colors.orange.withValues(alpha: .34),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    decision.statusLabel,
                    style: context.buyBody.copyWith(
                      color: BuyV2Colors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(decision.detail, style: context.buyMeta),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Align(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: OutlinedButton.icon(
                          key: ValueKey('buy-offer-retry-${product.id}'),
                          style: BuyV2ActionStyle.button(
                            OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            session.refreshProductFacts(product.id);
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Check availability'),
                        ),
                      ),
                      Align(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: FilledButton.icon(
                          key: ValueKey(
                            'buy-offer-change-product-${product.id}',
                          ),
                          style: BuyV2ActionStyle.button(
                            FilledButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                          onPressed: session.closeProduct,
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Change product'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductDiscoverySections extends StatefulWidget {
  const _ProductDiscoverySections({
    required this.session,
    required this.product,
    super.key,
  });
  final BuyV2Session session;
  final BuyV2Product product;
  @override
  State<_ProductDiscoverySections> createState() =>
      _ProductDiscoverySectionsState();
}

class _ProductDiscoverySectionsState extends State<_ProductDiscoverySections>
    with WidgetsBindingObserver {
  BuyV2CataloguePager<BuyV2Product>? _pager;
  Timer? _expiry;
  int _sequence = 0;
  int _limit = 8;
  bool _restored = false;
  String? _shownCursor;
  String get _scope => 'product-more-${widget.product.id}';
  BuyV2CatalogueQuery get _query => widget.session.catalogueQuery(
    catalogueDestination: widget.product.destination,
    catalogueWholesaleSaleType:
        widget.product.offerClass == BuyV2OfferClass.bulk
        ? BuyV2WholesaleSaleType.bulk
        : BuyV2WholesaleSaleType.wholesale,
    search: '',
    categoryId: 'all',
    refinements: BuyV2DiscoveryRefinements(availableOnly: true),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindPager();
    _scheduleExpiry();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    final saved = PageStorage.maybeOf(
      context,
    )?.readState(context, identifier: _scope);
    if (saved is int && saved >= 8) _limit = saved;
  }

  void _bindPager() {
    if (widget.session.pagedCatalogueEnabled && _pager == null) {
      _pager = widget.session.acquireCatalogueProducts(_scope)
        ..addListener(_changed);
      _shownCursor = _pager!.cursor;
    } else if (!widget.session.pagedCatalogueEnabled && _pager != null) {
      _pager!.removeListener(_changed);
      widget.session.releaseCatalogueProducts(_scope);
      _pager = null;
    }
    final sequence = ++_sequence;
    Future<void>.microtask(() async {
      if (!mounted || sequence != _sequence || _pager == null) return;
      if (_pager!.query != _query ||
          (_pager!.page == null &&
              !_pager!.loading &&
              _pager!.message == null)) {
        await _pager!.open(_query);
      }
    });
  }

  void _changed() {
    if (!mounted) return;
    setState(() {
      if (_shownCursor != _pager?.cursor) {
        _shownCursor = _pager?.cursor;
        _limit = 8;
      }
    });
    _scheduleExpiry();
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    final session = widget.session;
    final now = session.catalogueNow();
    final boundaries = <DateTime>[];
    final history = session.recentlyViewedProductsFor(
      widget.product.destination,
    );
    final earlierProducts = {
      ...session.productContinuationsFor(widget.product).map((p) => p.id),
      ...history.map((p) => p.id),
    };
    final products = [
      ...history,
      ...?_pager?.page?.items,
      if (_pager == null)
        ...session.productDiscoveryFor(
          widget.product,
          excludedProductIds: earlierProducts,
          limit: _limit + 1,
        ),
    ];
    for (final product in products) {
      final eligibility = session.productFactsFor(product).eligibility;
      boundaries.addAll(
        [
          eligibility?.expiresAt,
          eligibility?.scheduledStart,
          product.procurementSupplierGrant?.validUntil,
        ].whereType<DateTime>().where((time) => time.isAfter(now)),
      );
    }
    if (boundaries.isEmpty) return;
    boundaries.sort();
    final delay = boundaries.first.difference(now);
    _expiry = Timer(
      delay > const Duration(days: 1) ? const Duration(days: 1) : delay,
      () {
        if (!mounted) return;
        setState(() {});
        _scheduleExpiry();
      },
    );
  }

  @override
  void didUpdateWidget(covariant _ProductDiscoverySections oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bindPager();
    _scheduleExpiry();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      _scheduleExpiry();
    }
  }

  @override
  void dispose() {
    _sequence++;
    _expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pager?.removeListener(_changed);
    if (_pager != null) widget.session.releaseCatalogueProducts(_scope);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final product = widget.product;
    final similar = session
        .productContinuationsFor(product)
        .map((p) => p.id)
        .toSet();
    final recent = session.productDiscoveryFor(
      product,
      source: session.recentlyViewedProductsFor(product.destination),
      excludedProductIds: similar,
      includeVariants: true,
      limit: 10,
    );
    final page = _pager?.query == _query ? _pager?.page : null;
    final loading =
        _pager != null && (_pager!.query != _query || _pager!.loading);
    final failed = _pager?.query == _query && _pager?.message != null;
    final more = session.productDiscoveryFor(
      product,
      source: _pager == null ? null : page?.items ?? const [],
      excludedProductIds: {...similar, ...recent.map((p) => p.id)},
      limit: _limit + 1,
    );
    final visible = more.take(_limit).toList(growable: false);
    final next = page?.nextCursor != null;
    if (recent.isEmpty &&
        visible.isEmpty &&
        !loading &&
        !failed &&
        !next &&
        session.catalogueAvailable) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 20),
          _ProductContinuationSection(
            session: session,
            product: product,
            products: recent,
            heading: 'Recently viewed',
            sectionId: 'recent',
            headingAction: IconButton(
              key: ValueKey('buy-product-recent-view-all-${product.id}'),
              tooltip: 'View all recently viewed products',
              icon: const Icon(Icons.arrow_forward_rounded),
              onPressed: () => showBuyV2RecentlyViewed(
                context,
                session,
                onOpenProduct: (id) =>
                    session.openProduct(id, preserveComparisonOrigin: true),
              ),
            ),
          ),
        ],
        if (!session.catalogueAvailable) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  session.commerceLoadState == BuyV2CommerceLoadState.loading
                      ? 'Loading more products'
                      : 'More products unavailable',
                  style: context.buyMeta,
                ),
              ),
              if (session.commerceLoadState != BuyV2CommerceLoadState.loading)
                IconButton(
                  tooltip: 'Retry more products',
                  onPressed: session.restoreCommerce,
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
        ] else if (visible.isNotEmpty || loading || failed || next) ...[
          const SizedBox(height: 20),
          Text(
            'More products for you',
            style: context.buyTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          if (failed)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'More products could not refresh',
                    style: context.buyMeta,
                  ),
                ),
                IconButton(
                  tooltip: 'Retry more products',
                  onPressed: loading ? null : _pager?.retry,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = MediaQuery.textScalerOf(context).scale(14) > 21
                  ? 1
                  : 2;
              final width =
                  (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(
                key: ValueKey('buy-product-more-grid-${product.id}'),
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in visible)
                    _ProductContinuationCard(
                      session: session,
                      product: item,
                      width: width,
                    ),
                ],
              );
            },
          ),
          if (more.length > _limit)
            TextButton(
              key: ValueKey('buy-product-more-load-${product.id}'),
              onPressed: () {
                setState(() => _limit += 8);
                PageStorage.maybeOf(
                  context,
                )?.writeState(context, _limit, identifier: _scope);
                _scheduleExpiry();
              },
              child: const Text('Show more products'),
            ),
          if (page?.previousCursor != null || next)
            Wrap(
              spacing: 8,
              children: [
                if (page?.previousCursor != null)
                  TextButton(
                    onPressed: loading ? null : _pager?.previous,
                    child: const Text('Previous products'),
                  ),
                if (next && more.length <= _limit)
                  TextButton(
                    onPressed: loading ? null : _pager?.next,
                    child: const Text('Next products'),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}

class _ProductContinuationSection extends StatefulWidget {
  const _ProductContinuationSection({
    required this.session,
    required this.product,
    this.products,
    this.heading,
    this.headingAction,
    this.sectionId = 'continuation',
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final List<BuyV2Product>? products;
  final String? heading;
  final Widget? headingAction;
  final String sectionId;

  @override
  State<_ProductContinuationSection> createState() =>
      _ProductContinuationSectionState();
}

class _ProductContinuationSectionState
    extends State<_ProductContinuationSection>
    with WidgetsBindingObserver {
  Timer? _expiry;
  BuyV2Session get session => widget.session;
  BuyV2Product get product => widget.product;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleExpiry();
  }

  @override
  void didUpdateWidget(covariant _ProductContinuationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleExpiry();
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    final now = session.catalogueNow();
    final boundaries = <DateTime>[];
    for (final item
        in widget.products ??
            session.productContinuationsFor(product, limit: null)) {
      final eligibility = session.productFactsFor(item).eligibility;
      boundaries.addAll(
        [
          eligibility?.expiresAt,
          eligibility?.scheduledStart,
          item.procurementSupplierGrant?.validUntil,
        ].whereType<DateTime>().where((date) => date.isAfter(now)),
      );
    }
    if (boundaries.isEmpty) return;
    boundaries.sort();
    final remaining = boundaries.first.difference(now);
    _expiry = Timer(
      remaining > const Duration(days: 1) ? const Duration(days: 1) : remaining,
      () {
        if (!mounted) return;
        setState(() {});
        _scheduleExpiry();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      _scheduleExpiry();
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildRail);

  Widget _buildRail(BuildContext context, BoxConstraints constraints) {
    final commerce =
        product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale;
    if (commerce && !session.catalogueAvailable) {
      final loading =
          session.commerceLoadState == BuyV2CommerceLoadState.loading;
      return Row(
        key: ValueKey('buy-product-similar-unavailable-${product.id}'),
        children: [
          Expanded(
            child: Text(
              loading
                  ? 'Loading similar products'
                  : 'Similar products unavailable',
              style: context.buyMeta,
            ),
          ),
          if (!loading)
            IconButton(
              tooltip: 'Retry similar products',
              onPressed: session.restoreCommerce,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      );
    }
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final cardWidth = commerce
        ? math.min(constraints.maxWidth, 148 * textScale.clamp(1.0, 2.0))
        : 132.0;
    final seenFamilies = <String>{product.canonicalId};
    final products =
        (widget.products ??
                session.productContinuationsFor(product, limit: null))
            .where(
              (item) =>
                  !commerce ||
                  buyV2ResolveProductOfferDecision(
                        product: item,
                        facts: session.productFactsFor(item),
                      ).state !=
                      BuyV2ProductOfferDecisionState.unavailable,
            )
            .where(
              (item) =>
                  widget.products != null || seenFamilies.add(item.canonicalId),
            )
            .take(widget.products?.length ?? 6)
            .toList(growable: false);
    if (products.isEmpty) return const SizedBox.shrink();
    final railHeight = products.fold<double>(commerce ? 0 : 174, (
      height,
      item,
    ) {
      if (commerce) {
        final lines = _similarProductLines(context, session, item);
        final needed =
            120 +
            lines.fold<double>(
              0,
              (value, line) =>
                  value +
                  4 +
                  (line.price
                      ? (() {
                          final text = buyV2ValueTextSize(
                            context,
                            line.text,
                            line.style,
                          );
                          final quantity = session.quantityFor(item.id);
                          final control = math.min(
                            cardWidth - 12,
                            quantity > 0
                                ? _productQuantityWidth(context, quantity)
                                : 44.0,
                          );
                          final canAdd = buyV2ResolveProductOfferDecision(
                            product: item,
                            facts: session.productFactsFor(item),
                            quantity: quantity,
                          ).canAdd;
                          final controlHeight = canAdd ? 44.0 : 48.0;
                          return text.width + 6 + control <= cardWidth - 12
                              ? math.max(text.height, controlHeight)
                              : text.height + 4 + controlHeight;
                        })()
                      : buyV2ValueTextSize(
                          context,
                          line.text,
                          line.style,
                          maxWidth: cardWidth - 12,
                          maxLines: line.maxLines,
                        ).height),
            );
        return math.max(height, needed);
      }
      final requiredHeight =
          101 +
          buyV2ValueTextSize(
            context,
            item.title,
            context.buyBody.copyWith(fontSize: 9, height: 1.05),
            maxWidth: 120,
            maxLines: null,
          ).height +
          buyV2ValueTextSize(
            context,
            item.pack,
            context.buyMeta.copyWith(fontSize: 7.5),
            maxWidth: 120,
            maxLines: null,
          ).height +
          buyV2ValueTextSize(
            context,
            buyV2Money(item.price),
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            maxWidth: 102,
            maxLines: null,
          ).height.clamp(18, double.infinity);
      return requiredHeight > height ? requiredHeight : height;
    });

    final (defaultTitle, detail) = switch (product.destination) {
      BuyV2Destination.shop => (
        'Similar products',
        'Explore alternative products and packs',
      ),
      BuyV2Destination.wholesale => (
        'Similar products',
        'Explore alternative products and packs',
      ),
      BuyV2Destination.medicine => (
        'More Medicine essentials',
        'From the Medicine catalogue · not medical advice',
      ),
      BuyV2Destination.orders => ('', ''),
    };
    final title = widget.heading ?? defaultTitle;

    return BuyV2FiniteIncomingTransition(
      stateKey: 'buy-product-${widget.sectionId}-motion-${product.id}',
      child: BuyV2CartAvoidanceRegion(
        child: Container(
          key: ValueKey('buy-product-${widget.sectionId}s-${product.id}'),
          padding: commerce
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(9, 9, 9, 8),
          decoration: commerce ? null : buyV2CardDecoration(radius: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: context.buyTitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (widget.headingAction != null) widget.headingAction!,
                ],
              ),
              if (!commerce) ...[
                const SizedBox(height: 2),
                Text(detail, style: context.buyMeta.copyWith(fontSize: 8)),
              ],
              const SizedBox(height: 7),
              Semantics(
                key: PageStorageKey(
                  'buy-product-${widget.sectionId}-scroll-${product.id}',
                ),
                container: true,
                label: '$title. $detail. Swipe horizontally for more products.',
                child: SizedBox(
                  height: railHeight,
                  child: ListView.separated(
                    key: ValueKey(
                      'buy-product-${widget.sectionId}-lane-${product.id}',
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(width: commerce ? 8 : 7),
                    itemBuilder: (context, index) => _ProductContinuationCard(
                      width: cardWidth,
                      session: session,
                      product: products[index],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<({String text, TextStyle style, int? maxLines, bool price})>
_similarProductLines(
  BuildContext context,
  BuyV2Session session,
  BuyV2Product product,
) {
  final facts = session.productFactsFor(product);
  final trust = session.marketplaceTrustFor(product);
  final body = context.buyBody.copyWith(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  final meta = context.buyMeta.copyWith(fontSize: 12, height: 1.2);
  final rating = trust.state == BuyV2MarketplaceTrustState.ready
      ? trust.productRating
      : null;
  final mrp = product.mrp;
  final validPrice = !facts.stale && facts.price > 0;
  final discounted = validPrice && mrp != null && mrp > facts.price;
  final hasDelivery =
      !facts.stale && session.deliveryOptionsFor(product).isNotEmpty;
  final pack =
      product.variant.trim().isEmpty ||
          product.variant.trim() == product.pack.trim()
      ? product.pack
      : '${product.variant} · ${product.pack}';
  return [
    (text: product.customerTitle, style: body, maxLines: 2, price: false),
    (text: pack, style: meta, maxLines: null, price: false),
    if (rating != null)
      (
        text:
            '${rating.toStringAsFixed(1)} stars${trust.productRatingCount == null ? '' : ' (${trust.productRatingCount})'}',
        style: meta,
        maxLines: null,
        price: false,
      ),
    (
      text: validPrice ? buyV2Money(facts.price) : 'Price unavailable',
      style: body.copyWith(
        fontWeight: FontWeight.w800,
        color: const Color(0xFF24272B),
      ),
      maxLines: null,
      price: true,
    ),
    if (discounted)
      (
        text:
            'MRP ${buyV2Money(mrp)} · ${((mrp - facts.price) * 100 / mrp).floor()}% off',
        style: meta,
        maxLines: null,
        price: false,
      ),
    if (hasDelivery)
      (
        text: buyV2BuyerDeliveryPromise(facts),
        style: meta.copyWith(color: BuyV2Colors.green),
        maxLines: null,
        price: false,
      ),
  ];
}

class _ProductContinuationCard extends StatelessWidget {
  const _ProductContinuationCard({
    required this.session,
    required this.product,
    required this.width,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final double width;

  @override
  Widget build(BuildContext context) {
    final commerce =
        product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale;
    final lines = commerce
        ? _similarProductLines(context, session, product)
        : null;
    final quantity = session.quantityFor(product.id);
    final decision = buyV2ResolveProductOfferDecision(
      product: product,
      facts: session.productFactsFor(product),
      quantity: quantity,
    );
    final controlWidth = math.min(
      width - 12,
      quantity > 0 ? _productQuantityWidth(context, quantity) : 44.0,
    );
    final purchase = SizedBox(
      width: controlWidth,
      child: decision.canAdd
          ? _ProductOwnedActionPanel(
              product: product,
              quantity: quantity,
              showPurchaseFacts: false,
              rxBlocked:
                  product.requiresPrescription &&
                  !session.isPrescriptionApproved(product.id),
              onAdd: () {
                HapticFeedback.selectionClick();
                final added = session.addProduct(product.id);
                if (!added &&
                    session.pendingPrescriptionProductId == product.id) {
                  showBuyV2PrescriptionSheet(context, session);
                }
              },
              onEdit: () => showBuyV2QuantityEditor(context, session, product),
              onDecrease: () => session.decrease(product.id),
              onIncrease: () => session.increase(product.id),
            )
          : SizedBox(
              height: 48,
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => session.openProduct(
                  product.id,
                  preserveComparisonOrigin: true,
                ),
                child: const Text(
                  'Details',
                  maxLines: 1,
                  style: TextStyle(fontSize: 11, height: 1),
                ),
              ),
            ),
    );
    return SizedBox(
      width: width,
      child: Semantics(
        key: ValueKey('buy-product-continuation-${product.id}'),
        container: true,
        explicitChildNodes: true,
        label: 'View ${product.customerTitle} product details',
        button: true,
        onTap: () =>
            session.openProduct(product.id, preserveComparisonOrigin: true),
        child: Semantics(
          explicitChildNodes: true,
          child: Material(
            color: BuyV2Colors.canvas,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: () => session.openProduct(
                product.id,
                preserveComparisonOrigin: true,
              ),
              borderRadius: BorderRadius.circular(13),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: commerce ? 108 : 82,
                      width: double.infinity,
                      child: BuyV2ProductPackshot(
                        product: product,
                        borderRadius: 10,
                      ),
                    ),
                    if (lines != null)
                      for (final line in lines)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: line.price
                              ? Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(line.text, style: line.style),
                                    purchase,
                                  ],
                                )
                              : Text(
                                  line.text,
                                  style: line.style,
                                  maxLines: line.maxLines,
                                  overflow: line.maxLines == null
                                      ? null
                                      : TextOverflow.ellipsis,
                                ),
                        ),
                    if (!commerce) ...[
                      const SizedBox(height: 5),
                      Text(
                        product.customerTitle,
                        style: context.buyBody.copyWith(
                          fontSize: 9,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.pack,
                        style: context.buyMeta.copyWith(fontSize: 7.5),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              buyV2Money(product.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BuyV2Colors.navy,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: BuyV2Colors.navy,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductContentMediaSurface extends StatefulWidget {
  const _ProductContentMediaSurface({
    required this.product,
    required this.media,
    required this.active,
    required this.onRetry,
  });

  final BuyV2Product product;
  final BuyV2ProductMediaAsset media;
  final bool active;
  final VoidCallback onRetry;

  @override
  State<_ProductContentMediaSurface> createState() =>
      _ProductContentMediaSurfaceState();
}

class _ProductContentMediaSurfaceState
    extends State<_ProductContentMediaSurface> {
  int _attempt = 0;
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    final original = widget.media;
    setState(() => _retrying = true);
    try {
      if (original.kind == BuyV2ProductContentMediaKind.network) {
        await NetworkImage(original.source!).evict();
      } else if (original.kind == BuyV2ProductContentMediaKind.asset) {
        await AssetImage(original.source!).evict();
      }
    } finally {
      if (mounted) {
        setState(() {
          _retrying = false;
          _attempt++;
        });
        if (identical(original, widget.media)) widget.onRetry();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final media = widget.media;
    final active = widget.active;
    Widget fallback() => BuyV2ProductPhotoUnavailable(
      key: ValueKey('buy-product-gallery-image-${media.id}'),
      product: product,
      borderRadius: 17,
    );
    Widget failedImage() => product.destination == BuyV2Destination.medicine
        ? fallback()
        : Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.broken_image_outlined),
                const Text('Image unavailable'),
                IconButton(
                  key: ValueKey('buy-product-image-retry-${media.id}'),
                  tooltip: 'Retry image',
                  onPressed: _retrying ? null : _retry,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          );

    if (media.kind == BuyV2ProductContentMediaKind.networkVideo) {
      return BuyV2ProductVideo(product: product, media: media, active: active);
    }
    Widget decodedImage(
      BuildContext context,
      Widget child,
      int? frame,
      bool synchronouslyLoaded,
    ) => frame == null && !synchronouslyLoaded
        ? fallback()
        : Semantics(
            image: true,
            label: media.semanticLabel,
            excludeSemantics: true,
            child: child,
          );
    return KeyedSubtree(
      key: ValueKey(_attempt),
      child: switch (media.kind) {
        BuyV2ProductContentMediaKind.cataloguePackshot => BuyV2ProductPackshot(
          key: ValueKey('buy-product-gallery-image-${media.id}'),
          product: product.copyWith(mediaAssets: const []),
          borderRadius: 17,
          animateFirstFrame: true,
        ),
        BuyV2ProductContentMediaKind.asset => Image.asset(
          media.source!,
          key: ValueKey('buy-product-gallery-asset-${media.id}'),
          fit: BoxFit.contain,
          frameBuilder: decodedImage,
          errorBuilder: (_, _, _) => failedImage(),
        ),
        BuyV2ProductContentMediaKind.network => Image.network(
          media.source!,
          key: ValueKey('buy-product-gallery-network-${media.id}'),
          fit: BoxFit.contain,
          frameBuilder: decodedImage,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorBuilder: (_, _, _) => failedImage(),
        ),
        BuyV2ProductContentMediaKind.networkVideo => throw StateError(
          'Video media is handled before the image switch.',
        ),
      },
    );
  }
}

class _BuyV2ProductMediaItem {
  const _BuyV2ProductMediaItem({
    required this.identity,
    required this.label,
    required this.builder,
    required this.zoomable,
    required this.video,
  });

  final String identity;
  final String label;
  final Widget Function(bool active) builder;
  final bool zoomable;
  final bool video;
}

class _BuyV2ZoomableMedia extends StatefulWidget {
  const _BuyV2ZoomableMedia({
    super.key,
    required this.product,
    required this.label,
    required this.child,
  });

  final BuyV2Product product;
  final String label;
  final Widget child;

  @override
  State<_BuyV2ZoomableMedia> createState() => _BuyV2ZoomableMediaState();
}

class _BuyV2ZoomableMediaState extends State<_BuyV2ZoomableMedia>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transform;
  late final AnimationController _resetController;
  Matrix4Tween? _resetTween;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform = TransformationController()..addListener(_syncZoomState);
    _resetController = AnimationController(
      vsync: this,
      duration: BuyV2Motion.stateChange,
    )..addListener(_applyResetFrame);
  }

  @override
  void dispose() {
    _resetController
      ..removeListener(_applyResetFrame)
      ..dispose();
    _transform
      ..removeListener(_syncZoomState)
      ..dispose();
    super.dispose();
  }

  void _syncZoomState() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed && mounted) {
      setState(() => _zoomed = zoomed);
    }
  }

  void _applyResetFrame() {
    final tween = _resetTween;
    if (tween == null) {
      return;
    }
    _transform.value = tween.transform(
      Curves.easeOutCubic.transform(_resetController.value),
    );
  }

  void _resetMedia() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _resetController.stop();
      _resetTween = null;
      _transform.value = Matrix4.identity();
      return;
    }
    _resetTween = Matrix4Tween(
      begin: _transform.value.clone(),
      end: Matrix4.identity(),
    );
    _resetController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Pinch to zoom ${widget.product.customerTitle}.',
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              key: ValueKey('buy-product-media-zoom-${widget.product.id}'),
              transformationController: _transform,
              minScale: 1,
              maxScale: 2.5,
              panEnabled: _zoomed,
              scaleEnabled: true,
              boundaryMargin: EdgeInsets.zero,
              clipBehavior: Clip.hardEdge,
              onInteractionEnd: (_) {
                if (_transform.value.getMaxScaleOnAxis() <= 1.01) {
                  _resetMedia();
                }
              },
              child: widget.child,
            ),
          ),
          if (_zoomed)
            Positioned(
              right: 8,
              bottom: 8,
              child: Semantics(
                button: true,
                label: 'Reset zoom for ${widget.product.customerTitle}',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BuyV2ActionStyle.primaryFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    elevation: 2,
                    shadowColor: const Color(0x33000040),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: ValueKey(
                        'buy-product-media-reset-${widget.product.id}',
                      ),
                      onTap: _resetMedia,
                      borderRadius: BorderRadius.circular(12),
                      child: const SizedBox(
                        width: BuyV2Metrics.minimumTap,
                        height: BuyV2Metrics.minimumTap,
                        child: Icon(
                          Icons.fit_screen_rounded,
                          color: BuyV2ActionStyle.foreground,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BuyV2ProductGallery extends StatefulWidget {
  const _BuyV2ProductGallery({
    super.key,
    required this.product,
    required this.media,
    required this.session,
    this.rating,
    this.ratingCount,
    this.compact = false,
  }) : assert(media.length > 0);

  final BuyV2Product product;
  final List<_BuyV2ProductMediaItem> media;
  final BuyV2Session session;
  final double? rating;
  final int? ratingCount;
  final bool compact;

  @override
  State<_BuyV2ProductGallery> createState() => _BuyV2ProductGalleryState();
}

class _BuyV2ProductGalleryState extends State<_BuyV2ProductGallery> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // Recreated galleries reset their counter; do not restore an unrelated
    // PageStorage offset behind that counter after Cart or lazy-list disposal.
    _controller = PageController(keepPage: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _BuyV2ProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        oldWidget.product.id != widget.product.id ||
        oldWidget.media.length != widget.media.length ||
        !Iterable.generate(widget.media.length).every(
          (index) =>
              oldWidget.media[index].identity == widget.media[index].identity,
        );
    if (changed || _page >= widget.media.length) {
      _page = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      BuyV2CartAvoidanceRegion(child: _buildGallery(context));

  Widget _buildGallery(BuildContext context) {
    final product = widget.product;
    final referenceLayout =
        product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale;
    final hasMultipleMedia = widget.media.length > 1;
    final hasVideo = widget.media.any((media) => media.video);
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final galleryHeight = referenceLayout
        ? (viewportHeight * (largeText ? .28 : .31)).clamp(144.0, 240.0)
        : widget.compact
        ? viewportHeight < 650 || largeText
              ? (viewportHeight * .23).clamp(128.0, 160.0)
              : (viewportHeight * .29).clamp(174.0, 238.0)
        : (viewportHeight * .38).clamp(252.0, 320.0);
    final badgeMeasure = TextPainter(
      text: TextSpan(
        text: product.badge.trim().isNotEmpty
            ? product.badge
            : '1 of ${widget.media.length}',
        style: DefaultTextStyle.of(context).style.merge(
          const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: 136);
    final mediaTop = referenceLayout
        ? 0.0
        : product.badge.trim().isNotEmpty || hasMultipleMedia
        ? badgeMeasure.height + 8 + 9
        : 0.0;
    badgeMeasure.dispose();
    return Semantics(
      container: true,
      label: hasMultipleMedia
          ? 'Product ${hasVideo ? 'media' : 'image'} gallery for '
                '${product.customerTitle}, ${widget.media.length} items. '
                'Swipe to browse.'
          : 'Product media for ${product.customerTitle}',
      child: Container(
        height: galleryHeight + mediaTop,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: referenceLayout ? const Color(0xFFF5F5F5) : null,
          gradient: referenceLayout
              ? null
              : LinearGradient(
                  colors: [
                    product.destination == BuyV2Destination.medicine
                        ? const Color(0xFFE7F5F1)
                        : BuyV2Colors.softOrange,
                    Colors.white,
                    BuyV2Colors.softGreen,
                  ],
                ),
          borderRadius: referenceLayout
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.circular(22),
          border: referenceLayout ? null : Border.all(color: BuyV2Colors.line),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              top: mediaTop,
              child: PageView.builder(
                key: ValueKey('buy-product-gallery-${product.id}'),
                controller: _controller,
                physics: hasMultipleMedia
                    ? const PageScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: widget.media.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final media = widget.media[index];
                  final child = media.builder(index == _page);
                  return Padding(
                    padding: referenceLayout
                        ? EdgeInsets.only(bottom: hasMultipleMedia ? 28 : 0)
                        : EdgeInsets.fromLTRB(
                            8,
                            9,
                            8,
                            hasMultipleMedia ? 35 : 9,
                          ),
                    child: DecoratedBox(
                      key: ValueKey('buy-product-gallery-image-$index'),
                      decoration: BoxDecoration(
                        color: referenceLayout
                            ? Colors.transparent
                            : Colors.white,
                        borderRadius: BorderRadius.circular(
                          referenceLayout ? 0 : 20,
                        ),
                        boxShadow: referenceLayout
                            ? null
                            : const [
                                BoxShadow(
                                  color: Color(0x1D000040),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: media.zoomable
                            ? _BuyV2ZoomableMedia(
                                key: ValueKey(
                                  'buy-product-media-zoom-owner-'
                                  '${product.id}-$index-${media.identity}',
                                ),
                                product: product,
                                label: media.label,
                                child: child,
                              )
                            : child,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!referenceLayout && product.badge.trim().isNotEmpty)
              Positioned(
                left: 9,
                top: 9,
                child: BuyV2CartAvoidanceRegion(
                  key: ValueKey('buy-product-gallery-badge-${product.id}'),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: product.requiresPrescription
                          ? BuyV2Colors.navy
                          : BuyV2Colors.green,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      product.badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            if (referenceLayout && widget.rating != null)
              Positioned(
                left: 8,
                bottom: hasMultipleMedia ? 32 : 8,
                child: _ProductTrustPill(
                  icon: Icons.star_rounded,
                  label:
                      '${widget.rating!.toStringAsFixed(1)}${widget.ratingCount == null ? '' : ' · ${widget.ratingCount} ratings'}',
                  color: BuyV2Colors.green,
                ),
              ),
            if (hasMultipleMedia) ...[
              Positioned(
                right: referenceLayout ? null : 9,
                left: referenceLayout ? 8 : null,
                top: 9,
                child: Container(
                  key: const ValueKey('buy-product-gallery-count'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: BuyV2ActionStyle.gradient,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${_page + 1} of ${widget.media.length}',
                    semanticsLabel:
                        '${widget.media[_page].video ? 'Video' : 'Photo'} ${_page + 1} of ${widget.media.length}',
                    style: const TextStyle(
                      color: BuyV2ActionStyle.foreground,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 8,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = referenceLayout
                        ? (constraints.maxWidth / (widget.media.length * 2))
                              .clamp(0.0, 4.0)
                        : 4.0;
                    final segmentWidth =
                        ((constraints.maxWidth -
                                    gap * (widget.media.length - 1)) /
                                widget.media.length)
                            .clamp(0.0, 24.0);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (
                          var index = 0;
                          index < widget.media.length;
                          index++
                        ) ...[
                          SizedBox(
                            width: referenceLayout ? segmentWidth : null,
                            child: AnimatedContainer(
                              key: ValueKey('buy-product-gallery-dot-$index'),
                              duration: BuyV2Motion.resolved(
                                context,
                                BuyV2Motion.stateChange,
                              ),
                              width: referenceLayout
                                  ? segmentWidth
                                  : index == _page
                                  ? 18
                                  : 6,
                              height: referenceLayout ? 3 : 6,
                              decoration: BoxDecoration(
                                color: index == _page
                                    ? BuyV2Colors.navy
                                    : BuyV2Colors.muted.withValues(alpha: .35),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          if (index != widget.media.length - 1)
                            SizedBox(width: gap),
                        ],
                        if (!referenceLayout) const SizedBox(width: 8),
                        if (!referenceLayout)
                          Text(
                            widget.media[_page].label,
                            style: const TextStyle(
                              color: BuyV2Colors.ink,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductContentSections extends StatelessWidget {
  const _ProductContentSections({
    required this.session,
    required this.product,
    required this.content,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final BuyV2ProductContentSnapshot content;

  @override
  Widget build(BuildContext context) {
    if (product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale) {
      return _CommerceProductDetails(
        key: ValueKey('commerce-details-${product.id}'),
        session: session,
        product: product,
        content: content,
      );
    }
    if (content.state != BuyV2ProductContentState.ready) {
      final loading = content.state == BuyV2ProductContentState.loading;
      return Container(
        key: ValueKey(
          'buy-product-content-${content.state.name}-${product.id}',
        ),
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: buyV2CardDecoration(
          color: loading ? BuyV2Colors.softBlue : BuyV2Colors.softOrange,
          radius: 15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loading
                  ? 'Loading product details'
                  : 'Product details unavailable',
              style: context.buyBody.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              content.customerMessage ??
                  'More product information is unavailable right now. Price, pack and delivery remain available.',
              style: context.buyMeta,
            ),
            if (!loading) ...[
              const SizedBox(height: 9),
              Align(
                widthFactor: 1,
                heightFactor: 1,
                child: OutlinedButton.icon(
                  style: BuyV2ActionStyle.button(),
                  key: ValueKey('buy-product-content-retry-${product.id}'),
                  onPressed: () => session.refreshProductContent(product.id),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final deduplicateSummary =
        product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale;
    String normalized(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final seenHighlights = <String>{};
    final seenSpecifications = <String>{};
    final summaryValues = {
      product.brand,
      product.brandLabel,
      product.pack,
      product.customerVariant,
      product.unitPrice,
      if (product.returnPolicy != null) product.returnPolicy!,
    }.map(normalized).toSet();
    final summarySpecifications = {
      'brand': product.brandLabel,
      'pack': product.pack,
      'variant': product.customerVariant,
    };
    final highlights = content.highlights
        .map(product.customerContent)
        .where(
          (value) =>
              value.trim().isNotEmpty &&
              (!deduplicateSummary ||
                  !summaryValues.contains(normalized(value))) &&
              seenHighlights.add(normalized(value)),
        )
        .toList(growable: false);
    final specifications = content
        .specificationsFor(product)
        .where(
          (value) =>
              value.label.toLowerCase() != 'brand' ||
              product.brand.trim().isNotEmpty ||
              value.value != product.brandLabel,
        )
        .map(
          (value) => BuyV2ProductSpecification(
            label: value.label,
            value: product.customerContent(value.value),
          ),
        )
        .where(
          (value) =>
              !deduplicateSummary ||
              summarySpecifications[value.label.toLowerCase()] != value.value,
        )
        .where(
          (value) =>
              value.label.trim().isNotEmpty &&
              value.value.trim().isNotEmpty &&
              seenSpecifications.add(
                '${normalized(value.label)}:${normalized(value.value)}',
              ),
        )
        .toList(growable: false);
    final rawDescription = content.description;
    final customerDescription = rawDescription == null
        ? null
        : product.customerContent(rawDescription);
    final description = customerDescription?.trim().isEmpty == true
        ? null
        : deduplicateSummary &&
              customerDescription ==
                  '${product.customerTitle} · ${product.customerVariant}. ${product.pack} at ${product.unitPrice}.'
        ? null
        : customerDescription;

    return Column(
      key: ValueKey('buy-product-content-ready-${product.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (highlights.isNotEmpty ||
            specifications.isNotEmpty ||
            description != null)
          const SizedBox(height: 10),
        if (highlights.isNotEmpty)
          _ProductContentCard(
            title: 'Highlights',
            icon: Icons.auto_awesome_outlined,
            children: [
              for (final highlight in highlights)
                _ProductContentLine(value: highlight),
            ],
          ),
        if (highlights.isNotEmpty &&
            (specifications.isNotEmpty || description != null))
          const SizedBox(height: 8),
        if (specifications.isNotEmpty)
          _ProductContentCard(
            title: 'Specifications',
            icon: Icons.fact_check_outlined,
            children: [
              for (final specification in specifications)
                _DecisionRow(
                  icon: Icons.circle,
                  label: specification.label,
                  value: specification.value,
                ),
            ],
          ),
        if (specifications.isNotEmpty && description != null)
          const SizedBox(height: 8),
        if (description != null)
          _ProductContentCard(
            title: 'Description',
            icon: Icons.notes_rounded,
            children: [
              Text(description, style: context.buyBody.copyWith(fontSize: 10)),
            ],
          ),
      ],
    );
  }
}

class _CommerceProductDetails extends StatefulWidget {
  const _CommerceProductDetails({
    required this.session,
    required this.product,
    required this.content,
    super.key,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final BuyV2ProductContentSnapshot content;

  @override
  State<_CommerceProductDetails> createState() =>
      _CommerceProductDetailsState();
}

class _CommerceProductDetailsState extends State<_CommerceProductDetails> {
  final _tabKeys = List.generate(3, (_) => GlobalKey());
  int _tab = 0;
  bool _expanded = false;
  bool _restored = false;
  String get _storageId => 'buy-details-state-${widget.product.id}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) {
      _revealSelectedTab();
      return;
    }
    _restored = true;
    final saved = PageStorage.maybeOf(
      context,
    )?.readState(context, identifier: _storageId);
    if (saved is (int, bool)) {
      _tab = saved.$1.clamp(0, 2);
      _expanded = saved.$2;
    }
    _revealSelectedTab();
  }

  void _revealSelectedTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tabContext = _tabKeys[_tab].currentContext;
      final target = tabContext?.findRenderObject();
      if (tabContext == null || target == null) return;
      final scrollable = Scrollable.maybeOf(tabContext, axis: Axis.horizontal);
      if (scrollable != null) {
        unawaited(scrollable.position.ensureVisible(target, alignment: .5));
      }
    });
  }

  void _change({int? tab, bool? expanded}) {
    setState(() {
      _tab = tab ?? _tab;
      _expanded = expanded ?? _expanded;
    });
    PageStorage.maybeOf(
      context,
    )?.writeState(context, (_tab, _expanded), identifier: _storageId);
    if (tab != null) _revealSelectedTab();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final content = widget.content;
    final ready = content.state == BuyV2ProductContentState.ready;
    bool legalOwner(BuyV2ProductSpecification field) =>
        _legalProductAttributeIds.contains(field.attributeId) &&
        (field.attributeId != 'net_quantity' ||
            _nonBlankComplianceValue(product.compliance?.netQuantity) != null);
    final legalFields = ready
        ? [
            ...content.highlightsFor(product),
            ...content.specificationsFor(product),
          ].where(legalOwner).toList()
        : <BuyV2ProductSpecification>[];
    String normalized(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final summary = {
      'brand': product.brandLabel,
      'pack': product.pack,
      'variant': product.customerVariant,
    };
    bool meaningful(BuyV2ProductSpecification field) =>
        !legalOwner(field) &&
        field.label.trim().isNotEmpty &&
        field.value.trim().isNotEmpty &&
        normalized(
              summary[field.attributeId ?? normalized(field.label)] ?? '',
            ) !=
            normalized(field.value);
    String identity(BuyV2ProductSpecification field) =>
        field.attributeId ??
        '${normalized(field.label)}:${normalized(field.value)}';
    final seen = <String>{};
    final highlights = ready
        ? content
              .highlightsFor(product)
              .where(meaningful)
              .where((field) => seen.add(identity(field)))
              .toList()
        : <BuyV2ProductSpecification>[];
    final specifications = ready
        ? content
              .specificationsFor(product)
              .where(meaningful)
              .where((field) => seen.add(identity(field)))
              .toList()
        : <BuyV2ProductSpecification>[];
    final summaryValues = {
      ...summary.values,
      product.unitPrice,
      product.returnPolicy ?? '',
    }.map(normalized).toSet();
    final legacyHighlights = ready
        ? content.highlights
              .map(product.customerContent)
              .where(
                (value) =>
                    value.trim().isNotEmpty &&
                    !summaryValues.contains(normalized(value)),
              )
              .toSet()
              .toList()
        : <String>[];
    final suppliedDescription =
        ready && content.description?.trim().isNotEmpty == true
        ? content.description
        : null;
    final generatedDescription =
        '${product.customerTitle} · ${product.customerVariant}. ${product.pack} at ${product.unitPrice}.';
    final description = suppliedDescription == generatedDescription
        ? null
        : suppliedDescription;
    final compliance = product.compliance;
    final hasCompliance =
        legalFields.isNotEmpty ||
        (compliance != null &&
            [
              compliance.genericName,
              compliance.netQuantity,
              compliance.manufacturerName,
              compliance.manufacturerAddress,
              compliance.packerName,
              compliance.packerAddress,
              compliance.importerName,
              compliance.importerAddress,
              compliance.countryOfOrigin,
              compliance.manufacturedOrPackedOnLabel,
              compliance.bestBeforeOrUseByLabel,
              compliance.fssaiLicenseNumber,
              compliance.consumerCare,
            ].any((value) => value?.trim().isNotEmpty == true));
    final hasDetails =
        specifications.isNotEmpty ||
        description?.isNotEmpty == true ||
        hasCompliance;
    final hasSuppliedFacts =
        content.highlights.any((value) => value.trim().isNotEmpty) ||
        [
          ...content.highlightsFor(product),
          ...content.specificationsFor(product),
        ].any(
          (field) =>
              field.label.trim().isNotEmpty && field.value.trim().isNotEmpty,
        ) ||
        content.description?.trim().isNotEmpty == true;
    if (ready &&
        hasSuppliedFacts &&
        !hasDetails &&
        highlights.isEmpty &&
        legacyHighlights.isEmpty) {
      return SizedBox.shrink(
        key: ValueKey(
          'buy-product-content-${content.state.name}-${product.id}',
        ),
      );
    }
    final visibleHighlights = _expanded
        ? highlights
        : highlights.take(4).toList();
    final enlarged = MediaQuery.textScalerOf(context).scale(14) > 21;
    Widget fieldCell(BuyV2ProductSpecification field) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: context.buyMeta.copyWith(fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            product.customerContent(field.value),
            style: context.buyBody.copyWith(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
    Widget empty(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: context.buyBody.copyWith(fontSize: 13, height: 1.4),
      ),
    );
    return Column(
      key: ValueKey('buy-product-content-${content.state.name}-${product.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        if (highlights.isNotEmpty || legacyHighlights.isNotEmpty) ...[
          Text(
            'Product highlights',
            style: context.buyTitle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (
            var index = 0;
            index < visibleHighlights.length;
            index += enlarged ? 1 : 2
          ) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fieldCell(visibleHighlights[index])),
                if (!enlarged) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: index + 1 < visibleHighlights.length
                        ? fieldCell(visibleHighlights[index + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
            const Divider(height: 1),
          ],
          for (final value in legacyHighlights)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                value,
                style: context.buyBody.copyWith(fontSize: 13, height: 1.4),
              ),
            ),
          if (highlights.length > 4)
            TextButton(
              key: ValueKey('buy-product-highlights-expand-${product.id}'),
              onPressed: () => _change(expanded: !_expanded),
              child: Text(_expanded ? 'Show less' : 'Show all highlights'),
            ),
          const SizedBox(height: 12),
        ],
        if (!ready ||
            (!hasDetails &&
                highlights.isEmpty &&
                legacyHighlights.isEmpty)) ...[
          empty(
            content.state == BuyV2ProductContentState.loading
                ? 'Loading product details'
                : 'Product details unavailable',
          ),
          if (!ready &&
              content.customerMessage?.trim().isNotEmpty == true &&
              normalized(content.customerMessage!) !=
                  normalized(
                    content.state == BuyV2ProductContentState.loading
                        ? 'Loading product details'
                        : 'Product details unavailable',
                  ))
            Text(content.customerMessage!, style: context.buyMeta),
          if (content.state != BuyV2ProductContentState.loading &&
              (content.retryable ||
                  content.state == BuyV2ProductContentState.offline))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: ValueKey('buy-product-content-retry-${product.id}'),
                onPressed: () =>
                    widget.session.refreshProductContent(product.id),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ),
        ],
        if (hasDetails)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF5F8FA)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BuyV2Colors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'All details',
                  style: context.buyTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SingleChildScrollView(
                  key: PageStorageKey('buy-product-details-tabs-${product.id}'),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (index, label) in [
                        'Specifications',
                        'Description',
                        'Manufacturer info',
                      ].indexed)
                        Semantics(
                          key: _tabKeys[index],
                          selected: _tab == index,
                          child: TextButton(
                            key: ValueKey(
                              'buy-product-details-tab-$index-${product.id}',
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor:
                                  BuyV2ActionStyle.primaryForeground,
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              textStyle: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontSize: 12,
                                    fontWeight: _tab == index
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                            onPressed: () => _change(tab: index),
                            child: Ink(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BuyV2ActionStyle.selectionSurface(
                                selected: _tab == index,
                                radius: 8,
                              ),
                              child: Text(label),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (_tab == 0) ...[
                  if (specifications.isEmpty)
                    empty('No additional specifications available.'),
                  for (
                    var index = 0;
                    index < specifications.length;
                    index++
                  ) ...[
                    if (specifications[index].groupLabel != null &&
                        (index == 0 ||
                            specifications[index - 1].groupLabel !=
                                specifications[index].groupLabel))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          specifications[index].groupLabel!,
                          style: context.buyTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (enlarged)
                      fieldCell(specifications[index])
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                specifications[index].label,
                                style: context.buyMeta.copyWith(fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Text(
                                product.customerContent(
                                  specifications[index].value,
                                ),
                                style: context.buyBody.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 1),
                  ],
                ],
                if (_tab == 1)
                  empty(
                    description?.isNotEmpty == true
                        ? description!
                        : 'Description unavailable.',
                  ),
                if (_tab == 2)
                  hasCompliance
                      ? BuyV2ProductCompliancePanel(
                          product: product,
                          summaryAlreadyShown: true,
                          inline: true,
                          sourceFields: legalFields,
                        )
                      : empty('Manufacturer information unavailable.'),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProductContentCard extends StatelessWidget {
  const _ProductContentCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => BuyV2CartAvoidanceRegion(
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(radius: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: BuyV2Colors.navy, size: 19),
              const SizedBox(width: 7),
              Text(title, style: context.buyTitle.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

class _ProductContentLine extends StatelessWidget {
  const _ProductContentLine({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: BuyV2Colors.green,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(value, style: context.buyBody.copyWith(fontSize: 10)),
        ),
      ],
    ),
  );
}

class _ProductTrustPill extends StatelessWidget {
  const _ProductTrustPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: BuyV2Colors.ink,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductBenefitsPreview extends StatelessWidget {
  const _ProductBenefitsPreview({
    required this.session,
    required this.product,
    required this.benefits,
    required this.state,
    required this.customerMessage,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final List<BuyV2CartBenefit> benefits;
  final BuyV2CartBenefitsLoadState state;
  final String? customerMessage;

  @override
  Widget build(BuildContext context) {
    if (state == BuyV2CartBenefitsLoadState.ready && benefits.isEmpty) {
      return const SizedBox.shrink();
    }
    final visibleBenefits = benefits.take(3).toList(growable: false);
    if (state == BuyV2CartBenefitsLoadState.idle ||
        state == BuyV2CartBenefitsLoadState.loading) {
      return Container(
        key: ValueKey('buy-product-benefits-loading-${product.id}'),
        padding: const EdgeInsets.all(12),
        decoration: buyV2CardDecoration(
          color: BuyV2Colors.softBlue,
          radius: 15,
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 9),
            Expanded(child: Text('Checking additional benefits')),
          ],
        ),
      );
    }
    if (state == BuyV2CartBenefitsLoadState.offline ||
        state == BuyV2CartBenefitsLoadState.unavailable) {
      return Container(
        key: ValueKey('buy-product-benefits-unavailable-${product.id}'),
        padding: const EdgeInsets.all(12),
        decoration: buyV2CardDecoration(
          color: BuyV2Colors.softOrange,
          radius: 15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional benefits unavailable',
              style: context.buyBody.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              customerMessage ??
                  'Additional benefits could not be checked right now.',
              style: context.buyMeta,
            ),
            const SizedBox(height: 9),
            Align(
              widthFactor: 1,
              heightFactor: 1,
              child: OutlinedButton.icon(
                style: BuyV2ActionStyle.button(),
                key: ValueKey('buy-product-benefits-retry-${product.id}'),
                onPressed: () => session.refreshProductBenefits(product.id),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: ValueKey('buy-product-benefits-ready-${product.id}'),
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(radius: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                color: Color(0xFF326C76),
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Additional checkout benefits',
                  style: context.buyTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Separate from the listed seller price. Eligibility is checked again at Checkout.',
            style: context.buyMeta.copyWith(fontSize: 11, height: 1.35),
          ),
          const SizedBox(height: 8),
          if (visibleBenefits.isEmpty)
            Text(
              'No additional benefits available.',
              key: ValueKey('buy-product-benefits-empty-${product.id}'),
              style: context.buyBody,
            )
          else
            for (final (index, benefit) in visibleBenefits.indexed) ...[
              _ProductBenefitPreviewTile(benefit: benefit),
              if (index != visibleBenefits.length - 1)
                const SizedBox(height: 7),
            ],
        ],
      ),
    );
  }
}

class _ProductBenefitPreviewTile extends StatelessWidget {
  const _ProductBenefitPreviewTile({required this.benefit});

  final BuyV2CartBenefit benefit;

  @override
  Widget build(BuildContext context) {
    final validUntil = benefit.validUntil;
    final paymentMethods = benefit.eligiblePaymentMethods.toList()..sort();
    final sponsor = switch (benefit.sponsor) {
      BuyV2CartBenefitSponsor.retailer => 'Retail partner',
      BuyV2CartBenefitSponsor.wholesaler => 'Wholesale partner',
      BuyV2CartBenefitSponsor.manufacturer => 'Manufacturer',
      BuyV2CartBenefitSponsor.bank => 'Bank offer',
      BuyV2CartBenefitSponsor.financialPartner => 'Payment partner',
      BuyV2CartBenefitSponsor.moolSocial => 'MoolSocial',
    };
    return Container(
      key: ValueKey('buy-product-benefit-${benefit.id}'),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF4F8FA)],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE1E7EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  benefit.title,
                  style: context.buyBody.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (benefit.savingAmount > 0)
                Text(
                  'Save ${buyV2Money(benefit.savingAmount)}',
                  style: context.buyBody.copyWith(
                    color: BuyV2Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(benefit.detail, style: context.buyMeta),
          const SizedBox(height: 4),
          Text(
            [
              '$sponsor · ${benefit.sponsorName}',
              if (benefit.freeDelivery) 'Free delivery',
              if (paymentMethods.isNotEmpty)
                'With ${paymentMethods.join(' or ')}',
              if (validUntil != null)
                'Until ${MaterialLocalizations.of(context).formatShortDate(validUntil)}',
            ].join(' · '),
            style: context.buyMeta.copyWith(
              color: BuyV2Colors.muted,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceTrustPanel extends StatelessWidget {
  const _MarketplaceTrustPanel({
    required this.session,
    required this.product,
    required this.trust,
    this.productOnly = false,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final BuyV2MarketplaceTrustSnapshot trust;
  final bool productOnly;

  @override
  Widget build(BuildContext context) {
    if (trust.state != BuyV2MarketplaceTrustState.ready) {
      final loading = trust.state == BuyV2MarketplaceTrustState.loading;
      return Container(
        key: ValueKey(
          'buy-marketplace-trust-${trust.state.name}-${product.id}',
        ),
        padding: const EdgeInsets.all(12),
        decoration: buyV2CardDecoration(
          color: loading ? BuyV2Colors.softBlue : BuyV2Colors.softOrange,
          radius: 15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loading ? 'Loading ratings and seller' : 'Ratings unavailable',
              style: context.buyBody.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              trust.customerMessage ??
                  'Ratings and seller performance are unavailable right now.',
              style: context.buyMeta,
            ),
            if (!loading) ...[
              const SizedBox(height: 9),
              Align(
                widthFactor: 1,
                heightFactor: 1,
                child: OutlinedButton.icon(
                  style: BuyV2ActionStyle.button(),
                  key: ValueKey('buy-marketplace-trust-retry-${product.id}'),
                  onPressed: () => session.refreshMarketplaceTrust(product.id),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final productRating = trust.productRating;
    final partnerRating = trust.partnerRating;
    return _DecisionPanel(
      key: ValueKey('buy-marketplace-trust-ready-${product.id}'),
      title: productOnly ? 'Customer ratings' : 'Ratings and seller',
      children: [
        if (productOnly)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.star_rounded, size: 16, color: BuyV2Colors.navy),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  productRating == null
                      ? 'No ratings yet'
                      : '${productRating.toStringAsFixed(1)} from ${trust.productRatingCount ?? 0} ratings',
                  style: context.buyBody.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: productRating == null
                        ? BuyV2Colors.muted
                        : BuyV2Colors.green,
                  ),
                ),
              ),
            ],
          )
        else
          _DecisionRow(
            icon: Icons.star_rounded,
            label: 'Customer rating',
            value: productRating == null
                ? 'No customer ratings yet'
                : '${productRating.toStringAsFixed(1)} from '
                      '${trust.productRatingCount ?? 0} ratings',
            valueColor: productRating == null
                ? BuyV2Colors.muted
                : BuyV2Colors.green,
          ),
        if (trust.verifiedBuyerRatingCount case final count?)
          _DecisionRow(
            icon: Icons.verified_outlined,
            label: 'Verified buyer ratings',
            value: '$count',
          ),
        if (!productOnly) ...[
          if (trust.partnerName != session.productFactsFor(product).partner)
            _DecisionRow(
              icon: Icons.storefront_outlined,
              label: 'Seller',
              value:
                  '${product.customerSeller(trust.partnerName)} · ${_sellerTypeLabel(product.sellerType)}',
            ),
          if (partnerRating case final rating?)
            _DecisionRow(
              icon: Icons.workspace_premium_outlined,
              label: 'Store rating',
              value: rating.toStringAsFixed(1),
              valueColor: BuyV2Colors.green,
            ),
          if (product.destination != BuyV2Destination.shop &&
              product.destination != BuyV2Destination.wholesale)
            if (trust.partnerLocation case final location?)
              _DecisionRow(
                icon: Icons.location_on_outlined,
                label: 'Store location',
                value: location,
              ),
          if (trust.partnerOrderCount case final orderCount?)
            _DecisionRow(
              icon: Icons.inventory_2_outlined,
              label: 'Orders fulfilled',
              value: '$orderCount',
            ),
          if (trust.serviceReliabilityLabel case final reliability?)
            _DecisionRow(
              icon: Icons.local_shipping_outlined,
              label: 'Delivery record',
              value: reliability,
            ),
        ],
        if (!productOnly &&
            trust.returnSummary != product.purchaseProtection?.summary &&
            trust.returnSummary != product.returnPolicy)
          if (trust.returnSummary case final returnSummary?)
            _DecisionRow(
              icon: Icons.assignment_return_outlined,
              label: 'Return or replacement',
              value: returnSummary,
            ),
      ],
    );
  }
}

class _ProductReviewsPanel extends StatelessWidget {
  const _ProductReviewsPanel({
    required this.product,
    required this.review,
    required this.onReview,
    required this.onReport,
    required this.reported,
  });

  final BuyV2Product product;
  final BuyV2CustomerReview? review;
  final VoidCallback? onReview;
  final VoidCallback? onReport;
  final bool reported;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('buy-product-reviews-${product.id}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F8FA)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BuyV2Colors.line, width: .5),
      ),
      child: BuyV2CartAvoidanceRegion(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Customer reviews',
                    style: TextStyle(
                      color: BuyV2Colors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (review != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: BuyV2Colors.orange,
                        size: 17,
                      ),
                      Text(
                        '${review!.rating}.0',
                        style: const TextStyle(
                          color: BuyV2Colors.navy,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 5),
            if (review == null)
              Text(
                'Rate your purchase. A written review is optional.',
                style: context.buyMeta.copyWith(fontSize: 11, height: 1.4),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BuyV2Colors.softOrange.withValues(alpha: .65),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your review · ${review!.updatedLabel}',
                      style: context.buyEyebrow.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    if (review!.comment.trim().isNotEmpty)
                      Text(review!.comment, style: context.buyBody),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            if (onReview != null || onReport != null)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    key: ValueKey('buy-review-product-${product.id}'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: BuyV2Colors.ink,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: onReview,
                    icon: Icon(
                      Icons.rate_review_outlined,
                      size: 17,
                      color: onReview == null
                          ? BuyV2Colors.muted
                          : const Color(0xFF326C76),
                    ),
                    label: Text(
                      review == null ? 'Rate or review' : 'Update review',
                    ),
                  ),
                  TextButton.icon(
                    key: ValueKey('buy-report-product-${product.id}'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: BuyV2Colors.ink,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: reported ? null : onReport,
                    icon: Icon(
                      reported
                          ? Icons.check_circle_outline_rounded
                          : Icons.flag_outlined,
                      size: 17,
                      color: reported || onReport == null
                          ? BuyV2Colors.muted
                          : const Color(0xFF326C76),
                    ),
                    label: Text(reported ? 'Reported' : 'Report issue'),
                  ),
                ],
              )
            else
              Text(
                'Reviews and product reports will be available after Shop reconnects.',
                style: context.buyMeta.copyWith(fontSize: 11, height: 1.4),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showPurchaseRatingSheet(
  BuildContext context,
  BuyV2Session session,
  String purchaseId,
) async {
  final bottom = BuyV2AddressSheetMotion.resolveModalActionBottomInset(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: BuyV2ProductFeedbackSheetMotion.resolve(context),
    builder: (context) => AnimatedPadding(
      duration: BuyV2ProductFeedbackSheetMotion.resolveKeyboardInsetDuration(
        context,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + bottom,
      ),
      child: AnimatedBuilder(
        animation: session,
        builder: (context, _) => _ProductReviewSheet(
          session: session,
          purchaseId: purchaseId,
          kind: BuyV2RatingKind.purchase,
          existing: null,
        ),
      ),
    ),
  );
}

Future<void> _showProductReviewSheet(
  BuildContext context,
  BuyV2Session session,
  BuyV2Product product, {
  String? orderId,
  BuyV2RatingKind kind = BuyV2RatingKind.product,
}) async {
  final existing = session.customerReviewFor(product.id);
  var editorOpened =
      session.productReviewUnavailableReason(product.id, kind: kind) == null;
  final exportedBottomClearance =
      BuyV2AddressSheetMotion.resolveModalActionBottomInset(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: BuyV2ProductFeedbackSheetMotion.resolve(context),
    builder: (sheetContext) => AnimatedPadding(
      duration: BuyV2ProductFeedbackSheetMotion.resolveKeyboardInsetDuration(
        sheetContext,
      ),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.viewInsetsOf(sheetContext).bottom +
            exportedBottomClearance,
      ),
      child: AnimatedBuilder(
        animation: session,
        builder: (context, _) {
          final unavailable = session.productReviewUnavailableReason(
            product.id,
            kind: kind,
          );
          if (editorOpened || unavailable == null) {
            // Once editing starts, retain the draft during a failed refresh.
            // Submission independently rechecks eligibility in the session.
            editorOpened = true;
            return _ProductReviewSheet(
              session: session,
              product: product,
              existing: existing,
              orderId: orderId,
              kind: kind,
            );
          }
          final loading =
              session.commerceLoadState == BuyV2CommerceLoadState.loading;
          return SingleChildScrollView(
            key: const ValueKey('buy-product-review-eligibility'),
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ProductFeedbackSheetHeader(
                  icon: Icons.rate_review_outlined,
                  title: 'Rate your purchase',
                  detail: 'After delivery or collection.',
                  closeKey: ValueKey('buy-close-product-review'),
                ),
                const SizedBox(height: 10),
                _ProductFeedbackIdentity(product: product),
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Text(unavailable, style: context.buyBody),
                ),
                const SizedBox(height: 12),
                Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: OutlinedButton.icon(
                    style: BuyV2ActionStyle.button(),
                    key: const ValueKey('buy-review-check-eligibility'),
                    onPressed: loading ? null : session.restoreCommerce,
                    icon: Icon(loading ? Icons.hourglass_top : Icons.refresh),
                    label: Text(loading ? 'Checking purchase' : 'Check again'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

Future<void> _showProductReportSheet(
  BuildContext context,
  BuyV2Session session,
  BuyV2Product product,
) async {
  const reasons = [
    'Product information is incorrect',
    'Price or pack details are incorrect',
    'Product image does not match',
    'Partner information needs attention',
  ];
  final exportedBottomClearance =
      BuyV2AddressSheetMotion.resolveModalActionBottomInset(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: BuyV2ProductFeedbackSheetMotion.resolve(context),
    builder: (sheetContext) => AnimatedPadding(
      duration: BuyV2ProductFeedbackSheetMotion.resolveKeyboardInsetDuration(
        sheetContext,
      ),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.viewInsetsOf(sheetContext).bottom +
            exportedBottomClearance,
      ),
      child: _ProductReportSheet(
        session: session,
        product: product,
        reasons: reasons,
      ),
    ),
  );
}

class _ProductFeedbackSheetHeader extends StatelessWidget {
  const _ProductFeedbackSheetHeader({
    required this.icon,
    required this.title,
    required this.detail,
    required this.closeKey,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Key closeKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: BuyV2Colors.softOrange,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: BuyV2Colors.navy, size: 22),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.buyTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 2),
              Text(detail, style: context.buyMeta),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          key: closeKey,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close $title',
          style: IconButton.styleFrom(
            minimumSize: const Size.square(BuyV2Metrics.minimumTap),
            side: const BorderSide(color: BuyV2Colors.line),
          ),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _ProductFeedbackIdentity extends StatelessWidget {
  const _ProductFeedbackIdentity({required this.product});

  final BuyV2Product product;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey('buy-feedback-product-${product.id}'),
      container: true,
      label:
          '${product.customerTitle}, ${product.pack}, ${product.customerSeller(product.seller)}, product ${product.id}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: BuyV2Colors.softBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BuyV2Colors.line),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: BuyV2Colors.navy,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.customerTitle,
                    style: context.buyBody.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${product.pack} · ${product.customerSeller(product.seller)}',
                    style: context.buyMeta.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _productFeedbackSheetHeight(BuildContext context) {
  final media = MediaQuery.of(context);
  return (media.size.height -
          media.viewInsets.bottom -
          media.viewPadding.vertical -
          56)
      .clamp(300.0, 460.0);
}

class _ProductReviewSheet extends StatefulWidget {
  const _ProductReviewSheet({
    required this.session,
    this.product,
    this.purchaseId,
    required this.existing,
    this.orderId,
    this.kind = BuyV2RatingKind.product,
  });

  final BuyV2Session session;
  final BuyV2Product? product;
  final String? purchaseId;
  final BuyV2CustomerReview? existing;
  final String? orderId;
  final BuyV2RatingKind kind;

  @override
  State<_ProductReviewSheet> createState() => _ProductReviewSheetState();
}

class _ProductReviewSheetState extends State<_ProductReviewSheet> {
  late final TextEditingController _commentController;
  late final FocusNode _commentFocus;
  late int _rating;
  String? _targetId;
  String get _subjectId =>
      widget.product?.id ?? 'purchase:${widget.purchaseId}';
  List<BuyV2RatingTarget> get _targets => widget.purchaseId != null
      ? [?widget.session.purchaseRatingTarget(widget.purchaseId!)]
      : widget.session.ratingTargetsFor(
          _subjectId,
          orderId: widget.orderId,
          kind: widget.kind,
        );

  BuyV2RatingTarget? get _target =>
      _targets.where((t) => t.id == _targetId).firstOrNull;
  late final String? _draftOwnerScope;
  bool _submissionRejected = false;
  bool _submitting = false;

  bool get _canCompose =>
      (widget.purchaseId == null && widget.session.reviewDataEnabled) ||
      _target != null;

  bool get _isValid =>
      _rating >= 1 &&
      _rating <= 5 &&
      _commentController.text.characters.length <= 8000 &&
      ((widget.purchaseId == null && widget.session.reviewDataEnabled) ||
          _target != null);

  @override
  void initState() {
    super.initState();
    _draftOwnerScope = widget.session.reviewDraftOwnerScope;
    _targetId = _targets.length == 1 ? _targets.single.id : null;
    final draft = _canCompose
        ? widget.session.productReviewDraft(_subjectId, targetId: _targetId)
        : null;
    _rating =
        draft?.rating ??
        _target?.rating ??
        (widget.session.reviewDataEnabled ? widget.existing?.rating : null) ??
        0;
    _commentController = TextEditingController(
      text:
          draft?.comment ??
          _target?.comment ??
          (widget.session.reviewDataEnabled
              ? widget.existing?.comment
              : null) ??
          '',
    )..addListener(_retainDraft);
    _commentFocus = FocusNode()..addListener(_focusChanged);
  }

  void _retainDraft() {
    if (!_canCompose) return;
    widget.session.retainProductReviewDraft(
      productId: _subjectId,
      rating: _rating,
      comment: _commentController.text,
      ownerScope: _draftOwnerScope,
      targetId: _targetId,
    );
  }

  void _focusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() {
      _submitting = true;
      _submissionRejected = false;
    });
    final saved = widget.purchaseId != null
        ? await widget.session.submitPurchaseRating(
            purchaseId: widget.purchaseId!,
            rating: _rating,
            comment: _commentController.text,
          )
        : await widget.session.submitProductReviewOnline(
            productId: _subjectId,
            rating: _rating,
            comment: _commentController.text,
            targetId: _targetId,
            kind: widget.kind,
          );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _submitting = false;
        _submissionRejected = true;
      });
    }
  }

  @override
  void dispose() {
    _commentFocus
      ..removeListener(_focusChanged)
      ..dispose();
    _commentController
      ..removeListener(_retainDraft)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_draftOwnerScope != widget.session.reviewDraftOwnerScope) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your account changed. Open your purchase to rate it.'),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
    final stateDuration =
        BuyV2ProductFeedbackSheetMotion.resolveFormStateDuration(context);
    final routeTitle = widget.product == null
        ? 'Review your purchase'
        : 'Review ${widget.product!.customerTitle}';
    return PopScope<void>(
      canPop: !_commentFocus.hasFocus,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _commentFocus.unfocus();
      },
      child: Semantics(
        container: true,
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: '$routeTitle form',
        child: ConstrainedBox(
          key: const ValueKey('buy-product-review-sheet'),
          constraints: BoxConstraints.tightFor(
            height: _productFeedbackSheetHeight(context),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    key: const ValueKey('buy-product-review-fields-scroll'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProductFeedbackSheetHeader(
                          icon: Icons.rate_review_outlined,
                          title: 'Rate your MoolSocial experience',
                          detail: switch (widget.kind) {
                            BuyV2RatingKind.purchase =>
                              "Overall order rating. Add a review if you'd like.",
                            BuyV2RatingKind.product =>
                              "Product rating. Add a review if you'd like.",
                            BuyV2RatingKind.store =>
                              "Store service rating. Add a review if you'd like.",
                            BuyV2RatingKind.delivery =>
                              "Delivery rating. Add a review if you'd like.",
                          },
                          closeKey: const ValueKey('buy-close-product-review'),
                        ),
                        const SizedBox(height: 8),
                        if (widget.product case final product?)
                          _ProductFeedbackIdentity(product: product)
                        else ...[
                          Text(
                            _target?.purchaseLabel ?? 'Your completed purchase',
                            style: context.buyBody,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your overall feedback is shared with the stores in this order.',
                            style: context.buyMeta,
                          ),
                        ],
                        if (_targets.length > 1) ...[
                          const SizedBox(height: 8),
                          Text('Choose your purchase', style: context.buyBody),
                          for (final target in _targets)
                            Semantics(
                              checked: _targetId == target.id,
                              inMutuallyExclusiveGroup: true,
                              child: TextButton.icon(
                                key: ValueKey(
                                  'buy-rating-purchase-${target.id}',
                                ),
                                icon: Icon(
                                  _targetId == target.id
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                ),
                                label: Text(target.purchaseLabel),
                                onPressed: _submitting
                                    ? null
                                    : () {
                                        _retainDraft();
                                        setState(() {
                                          _targetId = target.id;
                                          final draft = widget.session
                                              .productReviewDraft(
                                                _subjectId,
                                                targetId: target.id,
                                              );
                                          _rating =
                                              draft?.rating ??
                                              target.rating ??
                                              0;
                                          _commentController.text =
                                              draft?.comment ?? target.comment;
                                          _submissionRejected = false;
                                        });
                                      },
                              ),
                            ),
                        ] else if (_target != null)
                          Text(_target!.purchaseLabel, style: context.buyMeta),
                        const SizedBox(height: 8),
                        Semantics(
                          label: _rating == 0
                              ? 'No rating selected'
                              : '$_rating star rating selected',
                          liveRegion: true,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var value = 1; value <= 5; value++)
                                AnimatedContainer(
                                  duration: stateDuration,
                                  curve: Curves.easeOut,
                                  decoration: BoxDecoration(
                                    color: value <= _rating
                                        ? BuyV2Colors.softOrange
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: IconButton(
                                    key: ValueKey(
                                      'buy-review-rating-$_subjectId-$value',
                                    ),
                                    tooltip:
                                        '$value ${value == 1 ? 'star' : 'stars'}',
                                    onPressed: _submitting || !_canCompose
                                        ? null
                                        : () => setState(() {
                                            _rating = value;
                                            _retainDraft();
                                            _submissionRejected = false;
                                          }),
                                    icon: Icon(
                                      value <= _rating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: BuyV2Colors.orange,
                                      size: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 9),
                        Semantics(
                          container: true,
                          excludeSemantics: true,
                          textField: true,
                          multiline: true,
                          focusable: true,
                          focused: _commentFocus.hasFocus,
                          isRequired: false,
                          maxValueLength: 8000,
                          currentValueLength:
                              _commentController.text.characters.length,
                          label: 'Your review (optional)',
                          value: _commentController.text,
                          hint: 'Optional. Up to 8000 characters.',
                          onTap: _commentFocus.requestFocus,
                          onFocus: _commentFocus.requestFocus,
                          onSetText: (value) {
                            if (!_canCompose || _submitting) return;
                            final nextValue =
                                LengthLimitingTextInputFormatter(
                                  8000,
                                  maxLengthEnforcement:
                                      MaxLengthEnforcement.enforced,
                                ).formatEditUpdate(
                                  _commentController.value,
                                  TextEditingValue(
                                    text: value,
                                    selection: TextSelection.collapsed(
                                      offset: value.length,
                                    ),
                                  ),
                                );
                            _commentFocus.requestFocus();
                            _commentController.value = nextValue;
                            setState(() => _submissionRejected = false);
                          },
                          child: TextFormField(
                            key: ValueKey('buy-review-comment-$_subjectId'),
                            controller: _commentController,
                            focusNode: _commentFocus,
                            autofocus: false,
                            onChanged: (_) => setState(() {
                              _submissionRejected = false;
                            }),
                            enabled: !_submitting && _canCompose,
                            minLines: 2,
                            maxLines: 4,
                            maxLength: 8000,
                            scrollPadding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.viewInsetsOf(context).bottom + 132,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Your review (optional)',
                              hintText:
                                  'Tell others about your experience (optional)',
                              counterText: '',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Optional · up to 8000 characters',
                                  style: context.buyMeta.copyWith(fontSize: 9),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_commentController.text.characters.length}/8000',
                                style: context.buyMeta.copyWith(fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        AnimatedSwitcher(
                          duration: stateDuration,
                          child: Semantics(
                            key: ValueKey(
                              _submissionRejected
                                  ? 'review-submit-rejected'
                                  : _submitting
                                  ? 'review-submitting'
                                  : _isValid
                                  ? 'review-ready'
                                  : 'review-incomplete',
                            ),
                            liveRegion: true,
                            child: Text(
                              !widget.session.reviewDataEnabled &&
                                      _targetId != null &&
                                      _target == null
                                  ? (widget.session
                                            .productReviewUnavailableReason(
                                              _subjectId,
                                              kind: widget.kind,
                                            ) ??
                                        'This purchase can no longer be rated. Close and try again.')
                                  : _submissionRejected
                                  ? (widget.session.notice ??
                                        'This review could not be saved.')
                                  : _submitting
                                  ? 'Saving your review…'
                                  : _isValid
                                  ? 'You can submit stars only or add a review.'
                                  : 'Choose 1–5 stars to submit your rating.',
                              style: context.buyMeta.copyWith(
                                color: _submissionRejected
                                    ? BuyV2Colors.orange
                                    : _isValid
                                    ? BuyV2Colors.green
                                    : BuyV2Colors.muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stack =
                        constraints.maxWidth < 360 &&
                        MediaQuery.textScalerOf(context).scale(14) > 18;
                    final available = constraints.maxWidth - (stack ? 0 : 8);
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: stack ? available : available / 3,
                          child: TextButton(
                            key: const ValueKey('buy-cancel-product-review'),
                            onPressed: _submitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        SizedBox(
                          width: stack ? available : available * 2 / 3,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Align(
                              widthFactor: 1,
                              heightFactor: 1,
                              child: FilledButton.icon(
                                style: BuyV2ActionStyle.button(),
                                key: ValueKey('buy-submit-review-$_subjectId'),
                                onPressed: _isValid && !_submitting
                                    ? _submit
                                    : null,
                                icon: _submitting
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded, size: 18),
                                label: Text(
                                  _submitting
                                      ? 'Submitting…'
                                      : _target?.reviewId != null ||
                                            widget.existing != null
                                      ? 'Save changes'
                                      : 'Submit rating',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductReportSheet extends StatefulWidget {
  const _ProductReportSheet({
    required this.session,
    required this.product,
    required this.reasons,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final List<String> reasons;

  @override
  State<_ProductReportSheet> createState() => _ProductReportSheetState();
}

class _ProductReportSheetState extends State<_ProductReportSheet> {
  String? _selectedReason;
  bool _submissionRejected = false;
  bool _submitting = false;

  Future<void> _submit() async {
    final reason = _selectedReason;
    if (reason == null || _submitting) return;
    setState(() {
      _submitting = true;
      _submissionRejected = false;
    });
    final reported = await widget.session.reportProductOnline(
      productId: widget.product.id,
      reason: reason,
    );
    if (!mounted) return;
    if (reported) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _submitting = false;
        _submissionRejected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateDuration =
        BuyV2ProductFeedbackSheetMotion.resolveFormStateDuration(context);
    const title = 'Report a product issue';
    return Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: '$title form',
      child: ConstrainedBox(
        key: const ValueKey('buy-product-report-sheet'),
        constraints: BoxConstraints.tightFor(
          height: _productFeedbackSheetHeight(context),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  key: const ValueKey('buy-product-report-reasons-scroll'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _ProductFeedbackSheetHeader(
                        icon: Icons.flag_outlined,
                        title: title,
                        detail:
                            'Choose the one listing detail that needs attention.',
                        closeKey: ValueKey('buy-close-product-report'),
                      ),
                      const SizedBox(height: 8),
                      _ProductFeedbackIdentity(product: widget.product),
                      const SizedBox(height: 8),
                      for (
                        var index = 0;
                        index < widget.reasons.length;
                        index++
                      )
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Semantics(
                            button: true,
                            selected: _selectedReason == widget.reasons[index],
                            label: widget.reasons[index],
                            child: AnimatedContainer(
                              duration: stateDuration,
                              curve: Curves.easeOut,
                              decoration: BoxDecoration(
                                color: _selectedReason == widget.reasons[index]
                                    ? BuyV2Colors.softOrange
                                    : BuyV2Colors.canvas,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      _selectedReason == widget.reasons[index]
                                      ? BuyV2Colors.orange
                                      : Colors.transparent,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: ValueKey('buy-report-reason-$index'),
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _submitting
                                      ? null
                                      : () => setState(() {
                                          _selectedReason =
                                              widget.reasons[index];
                                          _submissionRejected = false;
                                        }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.reasons[index],
                                            style: context.buyBody.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          _selectedReason ==
                                                  widget.reasons[index]
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          color:
                                              _selectedReason ==
                                                  widget.reasons[index]
                                              ? BuyV2Colors.orange
                                              : BuyV2Colors.muted,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      AnimatedSwitcher(
                        duration: stateDuration,
                        child: Semantics(
                          key: ValueKey(
                            _submissionRejected
                                ? 'report-submit-rejected'
                                : _submitting
                                ? 'report-submitting'
                                : _selectedReason == null
                                ? 'report-incomplete'
                                : 'report-ready',
                          ),
                          liveRegion: true,
                          child: Text(
                            _submissionRejected
                                ? (widget.session.notice ??
                                      'This report could not be sent.')
                                : _submitting
                                ? 'Sending your report…'
                                : _selectedReason == null
                                ? 'Choose one reason to enable Send.'
                                : 'Ready to send this listing issue.',
                            style: context.buyMeta.copyWith(
                              color: _submissionRejected
                                  ? BuyV2Colors.orange
                                  : _selectedReason == null
                                  ? BuyV2Colors.muted
                                  : BuyV2Colors.green,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    key: const ValueKey('buy-cancel-product-report'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Align(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: FilledButton.icon(
                          style: BuyV2ActionStyle.button(),
                          key: ValueKey(
                            'buy-submit-report-${widget.product.id}',
                          ),
                          onPressed: _selectedReason == null || _submitting
                              ? null
                              : _submit,
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_outlined, size: 18),
                          label: Text(_submitting ? 'Sending…' : 'Send report'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressSelectionRequired extends StatelessWidget {
  const _AddressSelectionRequired({
    required this.session,
    required this.title,
    required this.detail,
    this.embedded = false,
  });

  final BuyV2Session session;
  final String title;
  final String detail;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      key: const ValueKey('buy-address-selection-required'),
      padding: const EdgeInsets.all(14),
      decoration: buyV2CardDecoration(
        color: BuyV2Colors.softOrange,
        border: const Color(0x55FF9933),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: BuyV2Colors.navy,
            size: 28,
          ),
          const SizedBox(height: 7),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.buyTitle.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(detail, textAlign: TextAlign.center, style: context.buyMeta),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: BuyV2Metrics.minimumTap,
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: FilledButton.icon(
                style: BuyV2ActionStyle.button(),
                key: const ValueKey('buy-choose-address-recovery'),
                onPressed: () => showBuyV2AddressSheet(context, session),
                icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                label: const Text('Choose address'),
              ),
            ),
          ),
        ],
      ),
    );
    if (embedded) return content;
    return ListView(
      key: const PageStorageKey('buy-address-recovery'),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      children: [content],
    );
  }
}

class _MissingOrderSelection extends StatelessWidget {
  const _MissingOrderSelection({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('buy-order-selection-recovery'),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      children: [
        Container(
          key: const ValueKey('buy-order-selection-required'),
          padding: const EdgeInsets.all(14),
          decoration: buyV2CardDecoration(),
          child: Column(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: BuyV2Colors.navy,
                size: 28,
              ),
              const SizedBox(height: 7),
              Text(
                'This order could not be found.',
                textAlign: TextAlign.center,
                style: context.buyTitle.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                'Return to Orders to choose another purchase.',
                textAlign: TextAlign.center,
                style: context.buyMeta,
              ),
              const SizedBox(height: 11),
              SizedBox(
                width: double.infinity,
                height: BuyV2Metrics.minimumTap,
                child: Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: FilledButton(
                    style: BuyV2ActionStyle.button(),
                    key: const ValueKey('buy-return-to-orders-recovery'),
                    onPressed: session.openOrders,
                    child: const Text('View orders'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BuyV2CartView extends StatefulWidget {
  const BuyV2CartView({
    super.key,
    required this.session,
    required this.onBrowseMore,
    this.onBrowseStore,
    this.onOpenOffers,
    this.onVisitComparisonProduct,
    this.storeLabel,
  });

  final BuyV2Session session;
  final VoidCallback onBrowseMore;
  final VoidCallback? onBrowseStore;
  final VoidCallback? onOpenOffers;
  final Future<void> Function(BuyV2Product)? onVisitComparisonProduct;
  final String? storeLabel;

  @override
  State<BuyV2CartView> createState() => _BuyV2CartViewState();
}

class _BuyV2CartViewState extends State<BuyV2CartView> {
  Future<void> _compareCartPrices() async {
    final products = session.cartLines.map((line) => line.product).toList();
    if (products.isEmpty) return;
    final chosen = products.length == 1
        ? products.single
        : await showModalBottomSheet<BuyV2Product>(
            context: context,
            useSafeArea: true,
            showDragHandle: true,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Choose a product to compare'),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final product in products)
                        ListTile(
                          key: ValueKey(
                            'buy-cart-compare-product-${product.id}',
                          ),
                          title: Text(product.customerTitle),
                          subtitle: Text(product.pack),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(context, product),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
    if (!mounted || chosen == null) return;
    final current = session.cartLines
        .where((line) => line.product.id == chosen.id)
        .firstOrNull
        ?.product;
    if (current == null) return;
    await _showBuyV2ProductComparison(
      context,
      session: session,
      current: current,
      onVisitProduct: widget.onVisitComparisonProduct,
    );
  }

  bool _benefitsExpanded = true;
  bool _instructionsFocused = false;
  late BuyV2CartScope _scope;
  late String _displayFilter;
  late ScrollController _scrollController;

  BuyV2Session get session => widget.session;

  @override
  void initState() {
    super.initState();
    _scope = session.cartScope;
    _displayFilter = session.cartDisplayFilter;
    _scrollController = _controllerFor(_scope);
  }

  ScrollController _controllerFor(BuyV2CartScope scope) {
    final controller = ScrollController(
      initialScrollOffset: session.cartScrollOffsetFor(scope),
      keepScrollOffset: false,
    );
    controller.addListener(() {
      session.rememberCartScrollOffset(scope, controller.offset);
    });
    return controller;
  }

  @override
  void didUpdateWidget(covariant BuyV2CartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextScope = session.cartScope;
    if (_displayFilter != session.cartDisplayFilter) {
      _displayFilter = session.cartDisplayFilter;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
    if (_scope == nextScope && oldWidget.session == session) return;
    if (_scrollController.hasClients) {
      oldWidget.session.rememberCartScrollOffset(
        _scope,
        _scrollController.offset,
      );
    }
    _scrollController.dispose();
    _scope = nextScope;
    _scrollController = _controllerFor(_scope);
  }

  @override
  void dispose() {
    if (_scrollController.hasClients) {
      session.rememberCartScrollOffset(_scope, _scrollController.offset);
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = session.cartLines;
    final visibleLines = session.visibleCartLines;
    final destinations =
        const [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        ].where(
          (destination) =>
              lines.any((line) => line.product.destination == destination),
        );
    final header = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 3, 10, 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          decoration: buyV2CardDecoration(radius: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BuyV2Colors.navy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cart',
                      style: context.buyTitle.copyWith(fontSize: 17),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final summary = _cartHeaderSummary(session);
                        final style = context.buyMeta.copyWith(fontSize: 11);
                        final size = buyV2ValueTextSize(
                          context,
                          summary,
                          style,
                          maxWidth: constraints.maxWidth,
                          maxLines: null,
                        );
                        return BuyV2FiniteValueTransition(
                          key: const ValueKey('buy-cart-header-value-motion'),
                          stateKey: summary,
                          text: summary,
                          ownerSize: Size(constraints.maxWidth, size.height),
                          textAlign: TextAlign.start,
                          maxLines: null,
                          style: style,
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('buy-cart-empty'),
                tooltip: session.usesMixedCartSelection
                    ? 'Empty entire cart'
                    : 'Empty cart',
                onPressed: session.itemCount == 0
                    ? null
                    : () => unawaited(_confirmBuyV2CartClear(context, session)),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFB42318),
                ),
              ),
            ],
          ),
        ),
      ),
      _CartScopeBar(session: session),
      const SizedBox(height: 7),
    ];
    final empty = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: BuyV2Colors.navy,
              size: 34,
            ),
            const SizedBox(height: 8),
            Text(
              session.usesMixedCartSelection && session.itemCount > 0
                  ? 'No products in this filter'
                  : session.cartScope == BuyV2CartScope.all
                  ? 'Your cart is empty'
                  : 'Your ${session.cartScope.label} cart is empty',
              textAlign: TextAlign.center,
              style: context.buyTitle.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              session.usesMixedCartSelection && session.itemCount > 0
                  ? 'Choose All to see your Cart products.'
                  : session.cartScope == BuyV2CartScope.all
                  ? 'Browse products to start your order.'
                  : 'Browse ${session.cartScope.label} products to start your order.',
              textAlign: TextAlign.center,
              style: context.buyMeta,
            ),
          ],
        ),
      ),
    );
    final browseStyle = context.buyBody.copyWith(
      color: const Color(0xFF51356B),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    Widget browseAction(String key, String label, VoidCallback action) =>
        TextButton(
          key: ValueKey(key),
          onPressed: action,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: const Color(0xFF51356B),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: browseStyle),
              const Icon(Icons.chevron_right_rounded, size: 12),
            ],
          ),
        );
    final browseMore = Container(
      key: const ValueKey('buy-cart-browse-more-highlight'),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEAF7),
        borderRadius: BorderRadius.circular(7),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                browseAction(
                  'buy-cart-browse-more',
                  'Browse more products',
                  widget.onBrowseMore,
                ),
                browseAction(
                  'buy-cart-compare-prices',
                  'Compare prices',
                  _compareCartPrices,
                ),
                if (widget.onOpenOffers != null)
                  browseAction(
                    'buy-cart-browse-offers',
                    'Offers',
                    widget.onOpenOffers!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final visibleIds = visibleLines.map((line) => line.product.id).toSet();
    final hiddenSelected = lines
        .where((line) => !visibleIds.contains(line.product.id))
        .length;
    final contents = <Widget>[
      if (session.usesMixedCartSelection && hiddenSelected > 0)
        TextButton(
          key: const ValueKey('buy-cart-view-hidden-selection'),
          onPressed: () => session.chooseCartDisplayFilter('all'),
          style: TextButton.styleFrom(
            foregroundColor: BuyV2ActionStyle.primaryForeground,
            alignment: Alignment.centerLeft,
            minimumSize: const Size(44, 44),
          ),
          child: Text(
            'Selected purchase · ${session.scopedCartFamilyTotals.keys.map((d) => _cartDestinationLabel(session, d)).join(' + ')} · View all',
            style: context.buyMeta.copyWith(
              fontSize: 11,
              color: BuyV2ActionStyle.primaryForeground,
            ),
          ),
        ),
      if (visibleLines.isEmpty && session.itemCount > 0)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'No ${_cartFilterLabel(session.cartDisplayFilter)} products in Cart.',
            style: context.buyMeta,
          ),
        ),
      for (final line in visibleLines)
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: _CartLine(session: session, line: line),
        ),
      if (widget.onBrowseStore != null &&
          widget.storeLabel?.trim().isNotEmpty == true)
        Container(
          key: const ValueKey('buy-cart-store-navigation'),
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: buyV2CardDecoration(radius: 12),
          child: Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 18,
                color: BuyV2ActionStyle.primaryForeground,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextButton(
                  key: const ValueKey('buy-cart-continue-store'),
                  onPressed: widget.onBrowseStore,
                  style: TextButton.styleFrom(
                    foregroundColor: BuyV2ActionStyle.primaryForeground,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Text(
                    widget.storeLabel!,
                    key: const ValueKey('buy-cart-continue-store-name'),
                    style: context.buyBody.copyWith(
                      color: BuyV2ActionStyle.primaryForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      browseMore,
      _InlineCartBenefitPanel(
        key: const ValueKey('buy-cart-inline-benefits-owner'),
        session: session,
        expanded: _benefitsExpanded,
        onExpandedChanged: (value) => setState(() => _benefitsExpanded = value),
      ),
      const SizedBox(height: 10),
      Focus(
        key: const ValueKey('buy-cart-instructions-focus-owner'),
        onFocusChange: (focused) {
          if (mounted) setState(() => _instructionsFocused = focused);
        },
        child: _CartDeliveryInstructionSections(
          session: session,
          destinations: destinations.toList(growable: false),
        ),
      ),
      _CartTipSections(session: session),
      _CartBillSummary(session: session),
      const SizedBox(height: 8),
      _CartDiscoverySections(
        session: session,
        destinations: destinations.toList(growable: false),
      ),
      BuyV2SponsoredSlot(
        content: session.sponsoredContentFor(
          BuyV2SponsoredPlacement.cartBeforeSummary,
        ),
      ),
    ];
    final footer = Container(
      key: const ValueKey('buy-cart-action-bar'),
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: BuyV2Colors.line)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (lines.isEmpty && session.itemCount > 0) {
            return Text('Select products to checkout', style: context.buyBody);
          }
          if (lines.isEmpty) {
            return SizedBox(
              width: double.infinity,
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: FilledButton.icon(
                  style: BuyV2ActionStyle.button(
                    FilledButton.styleFrom(
                      minimumSize: const Size(0, BuyV2Metrics.minimumTap),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  key: const ValueKey('buy-empty-cart-browse'),
                  onPressed: widget.onBrowseMore,
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: Text(
                    session.cartScope == BuyV2CartScope.all
                        ? 'Browse products'
                        : 'Browse ${session.cartScope.label}',
                  ),
                ),
              ),
            );
          }
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final compactAccessible =
              constraints.maxWidth < 350 && textScale > 1.2;
          final priceUnavailable = session.scopedProcurementPricesUnavailable;
          final freightIncluded = lines.every(
            (line) => line.product.freightIncluded,
          );
          final freightSummary = freightIncluded
              ? 'Freight included · GST invoice at checkout'
              : 'Freight confirmed before payment · GST invoice at checkout';
          final totalText = priceUnavailable
              ? 'Pending'
              : buyV2Money(session.scopedPayableTotal);
          final totalStyle = TextStyle(
            color: BuyV2Colors.ink,
            fontSize: compactAccessible ? 20 : 22,
            fontWeight: FontWeight.w900,
          );
          final totalSize = buyV2ValueTextSize(context, totalText, totalStyle);
          final currencyInLabel =
              !priceUnavailable && totalSize.width > constraints.maxWidth;
          final displayedTotalText = currencyInLabel
              ? totalText.replaceFirst('₹', '')
              : totalText;
          final displayedTotalSize = currencyInLabel
              ? buyV2ValueTextSize(
                  context,
                  displayedTotalText,
                  totalStyle,
                  maxWidth: constraints.maxWidth,
                  maxLines: null,
                )
              : totalSize;
          final baseTotalLabel = priceUnavailable
              ? 'Price confirmation required'
              : session.scopedTipTotal > 0
              ? '${session.scopedItemCount} ${session.scopedItemCount == 1 ? 'item' : 'items'} selected · total (incl. tip)'
              : '${session.scopedItemCount} ${session.scopedItemCount == 1 ? 'item' : 'items'} selected · total';
          final totalLabel = currencyInLabel
              ? '$baseTotalLabel (₹)'
              : baseTotalLabel;
          final actionWidth = (constraints.maxWidth * .54).clamp(150.0, 190.0);

          void openCheckout() {
            if (!session.openCheckout() &&
                session.selectedAddressOrNull == null) {
              showBuyV2AddressSheet(
                context,
                session,
                continueToCheckoutAfterSelection: true,
              );
            }
          }

          final total = Semantics(
            label: totalText,
            excludeSemantics: true,
            child: BuyV2FiniteValueTransition(
              key: const ValueKey('buy-cart-payable-total-motion'),
              incomingOnly: true,
              stateKey: session.scopedPayableTotal,
              text: displayedTotalText,
              ownerSize: displayedTotalSize,
              maxLines: currencyInLabel ? null : 1,
              textAlign: TextAlign.start,
              style: totalStyle,
            ),
          );
          final review = Align(
            widthFactor: 1,
            heightFactor: 1,
            child: FilledButton(
              style: BuyV2ActionStyle.button(
                FilledButton.styleFrom(
                  minimumSize: const Size(0, BuyV2Metrics.minimumTap),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              onPressed: openCheckout,
              child: const Text('Checkout'),
            ),
          );
          final needsStack =
              textScale > 1.2 ||
              totalSize.width + 10 + actionWidth > constraints.maxWidth;
          if (needsStack) {
            final labelWidth = buyV2ValueTextSize(
              context,
              totalLabel,
              context.buyMeta,
            ).width;
            final totalSummary =
                labelWidth + 8 + totalSize.width <= constraints.maxWidth
                ? Row(
                    children: [
                      Expanded(child: Text(totalLabel, style: context.buyMeta)),
                      const SizedBox(width: 8),
                      total,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(totalLabel, style: context.buyMeta),
                      total,
                    ],
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                totalSummary,
                if (session.cartScope == BuyV2CartScope.wholesale)
                  Text(
                    freightSummary,
                    style: context.buyMeta.copyWith(fontSize: 7.5),
                  ),
                const SizedBox(height: 7),
                review,
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(totalLabel, style: context.buyMeta),
                    total,
                    if (session.cartScope == BuyV2CartScope.wholesale)
                      Text(
                        freightSummary,
                        style: context.buyMeta.copyWith(fontSize: 7.5),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(width: actionWidth, child: review),
            ],
          );
        },
      ),
    );
    final viewport = MediaQuery.sizeOf(context);
    if (viewport.height <= 480 &&
        (session.isStoreProcurement || viewport.width > viewport.height)) {
      return ListView(
        controller: _scrollController,
        key: PageStorageKey('buy-cart-${session.cartScope.name}'),
        padding: const EdgeInsets.only(bottom: 72),
        children: [
          ...header,
          if (lines.isEmpty && visibleLines.isEmpty)
            empty
          else
            for (final content in contents)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: content,
              ),
          footer,
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scaffold consumes its body's MediaQuery insets. Read the actual view
        // when its resized constraints change, preserving the same keyed list.
        final keyboardVisible =
            _instructionsFocused && View.of(context).viewInsets.bottom > 0;
        return Column(
          children: [
            if (!keyboardVisible) ...header,
            Expanded(
              key: const ValueKey('buy-cart-scroll'),
              child: lines.isEmpty && visibleLines.isEmpty
                  ? empty
                  : ListView(
                      controller: _scrollController,
                      key: PageStorageKey('buy-cart-${session.cartScope.name}'),
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 72),
                      children: contents,
                    ),
            ),
            if (!keyboardVisible) footer,
          ],
        );
      },
    );
  }
}

Future<void> _confirmBuyV2CartClear(
  BuildContext context,
  BuyV2Session session,
) async {
  if (session.checkoutRequiresResolution) {
    session.clearCart();
    return;
  }
  final scope = session.usesMixedCartSelection
      ? BuyV2CartScope.all
      : session.cartScope;
  final removeCount = scope == BuyV2CartScope.all
      ? session.itemCount
      : session.countForDestination(_destinationForCartScope(scope)!);
  if (removeCount == 0) return;
  final remainingCount = session.itemCount - removeCount;
  final clearEverything = scope == BuyV2CartScope.all;
  final title = clearEverything
      ? 'Empty entire Cart?'
      : 'Remove ${scope.label} ${removeCount == 1 ? 'item' : 'items'}?';
  final detail = clearEverything
      ? '$removeCount ${removeCount == 1 ? 'item' : 'items'} will be removed from your Cart.'
      : remainingCount > 0
      ? '$removeCount ${scope.label} ${removeCount == 1 ? 'item' : 'items'} will be removed. '
            '$remainingCount other ${remainingCount == 1 ? 'item will' : 'items will'} stay in your Cart.'
      : '$removeCount ${scope.label} ${removeCount == 1 ? 'item' : 'items'} will be removed. '
            'You’ll return to ${scope.label}.';
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      bottom: false,
      child: Semantics(
        container: true,
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: SingleChildScrollView(
          key: const ValueKey('buy-cart-clear-sheet'),
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            8 +
                MediaQuery.viewInsetsOf(sheetContext).bottom +
                BuyV2AddressSheetMotion.resolveModalActionBottomInset(
                  sheetContext,
                ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Color(0xFFB42318),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: sheetContext.buyTitle.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          detail,
                          style: sheetContext.buyMeta.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final keepCart = Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: OutlinedButton(
                      key: const ValueKey('buy-cart-clear-cancel'),
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      style: BuyV2ActionStyle.button(
                        OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      child: const Text('Keep Cart'),
                    ),
                  );
                  final removeItems = Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: FilledButton(
                      key: const ValueKey('buy-cart-clear-confirm'),
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      style: BuyV2ActionStyle.button(
                        FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          foregroundColor: const Color(0xFFB42318),
                        ),
                      ),
                      child: Text(
                        clearEverything
                            ? 'Empty Cart'
                            : 'Remove ${scope.label}',
                      ),
                    ),
                  );
                  final stackActions =
                      constraints.maxWidth < 320 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20;
                  if (stackActions) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        keepCart,
                        const SizedBox(height: 8),
                        removeItems,
                      ],
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [keepCart, const SizedBox(width: 8), removeItems],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (confirmed == true && context.mounted) {
    session.clearCartScope(scope);
  }
}

/// One entry for a combined basket unless the buyer chose distinct recipients.
class BuyV2CheckoutGstDetails extends StatelessWidget {
  const BuyV2CheckoutGstDetails({
    super.key,
    required this.destinations,
    required this.controller,
  });
  final List<BuyV2Destination> destinations;
  final BuyV2GstInvoiceController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (destinations.isEmpty) return const SizedBox.shrink();
      if (controller.restoring) return const LinearProgressIndicator();
      if (controller.loadFailed) {
        return Column(
          children: [
            Text(controller.message ?? 'Saved GST details are unavailable.'),
            TextButton(
              onPressed: () => controller.restore(force: true),
              child: const Text('Try again'),
            ),
          ],
        );
      }
      final identities = destinations
          .map(controller.detailsFor)
          .nonNulls
          .map((p) => p.id)
          .toSet();
      if (identities.length > 1 ||
          destinations.map(controller.requestedFor).toSet().length > 1) {
        return Column(
          children: [
            for (final d in destinations)
              _GstInvoiceCard(destination: d, controller: controller),
          ],
        );
      }
      final ordered = [
        if (destinations.contains(BuyV2Destination.shop)) BuyV2Destination.shop,
        ...destinations.where((d) => d != BuyV2Destination.shop),
      ];
      final destination = ordered.firstWhere(
        (d) => controller.detailsFor(d) != null || controller.requestedFor(d),
        orElse: () => ordered.first,
      );
      return _GstInvoiceCard(
        destination: destination,
        destinations: destinations,
        controller: controller,
      );
    },
  );
}

/// Account Profile reuses the checkout editor and injected account store.
/// The review store remains explicitly session-only until backend integration.
class BuyV2GstProfileSection extends StatefulWidget {
  const BuyV2GstProfileSection({
    super.key,
    required this.store,
    required this.onChanged,
  });
  final BuyV2GstInvoiceProfileStore? store;
  final VoidCallback onChanged;
  @override
  State<BuyV2GstProfileSection> createState() => _BuyV2GstProfileSectionState();
}

class _BuyV2GstProfileSectionState extends State<BuyV2GstProfileSection> {
  late BuyV2GstInvoiceController controller;
  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    controller = BuyV2GstInvoiceController(store: widget.store);
    controller.restore();
  }

  @override
  void didUpdateWidget(covariant BuyV2GstProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      controller.dispose();
      _create();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Card(
      key: const ValueKey('profile-gst-details'),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: BuyV2Colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GST details', style: context.buyTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              controller.loadFailed
                  ? 'Saved GST details are unavailable. Try again.'
                  : controller.savedProfiles.isEmpty
                  ? 'Add your GST details for future purchases. Optional.'
                  : controller.savedProfiles.first.legalName,
            ),
            if (controller.sessionPersistenceOnly)
              const Text('Details are kept until you close the app.'),
            if (controller.savedProfiles.isNotEmpty) ...[
              Text(controller.savedProfiles.first.gstin),
              Text(controller.savedProfiles.first.billingAddress),
            ],
            if (!controller.persistenceAvailable)
              const Text(
                'Account saving is currently unavailable. Try again later.',
              ),
            if (controller.restoring) const LinearProgressIndicator(),
            if (controller.message case final message?
                when message != 'GST details kept until you close the app.')
              Text(message),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  key: const ValueKey('profile-gst-edit'),
                  onPressed:
                      controller.busy ||
                          controller.restoring ||
                          controller.loadFailed ||
                          !controller.persistenceAvailable
                      ? null
                      : () async {
                          await showBuyV2GstInvoiceSheet(
                            context,
                            controller: controller,
                            destination: BuyV2Destination.shop,
                          );
                          if (mounted) widget.onChanged();
                        },
                  child: Text(
                    controller.loadFailed
                        ? 'GST details unavailable'
                        : controller.savedProfiles.isEmpty
                        ? 'Add GST details'
                        : 'Edit',
                  ),
                ),
                if (controller.savedProfiles.isNotEmpty)
                  TextButton(
                    key: const ValueKey('profile-gst-remove'),
                    onPressed: controller.busy
                        ? null
                        : () async {
                            await _confirmRemoveGstProfile(
                              context,
                              controller: controller,
                              profile: controller.savedProfiles.first,
                            );
                            if (mounted) widget.onChanged();
                          },
                    child: const Text('Remove'),
                  ),
                if (controller.loadFailed)
                  TextButton(
                    onPressed: controller.busy
                        ? null
                        : () => controller.restore(force: true),
                    child: const Text('Try again'),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _GstInvoiceCard extends StatelessWidget {
  const _GstInvoiceCard({
    required this.destination,
    required this.controller,
    this.destinations = const [],
  });

  final BuyV2Destination destination;
  final BuyV2GstInvoiceController controller;
  final List<BuyV2Destination> destinations;

  void setRequested(bool value) {
    for (final scope in destinations.isEmpty ? [destination] : destinations) {
      controller.setRequested(scope, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requested = controller.requestedFor(destination);
    final details = controller.detailsFor(destination);
    final gstAdded = details != null;
    final scopeLabel = destinations.isEmpty
        ? '${destination == BuyV2Destination.shop ? 'Shop' : 'Wholesale'} · '
        : '';
    return Container(
      key: ValueKey('buy-gst-invoice-${destination.name}'),
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            button: true,
            toggled: requested,
            label:
                '${scopeLabel}GST invoice. '
                '${requested ? 'Remove GST details' : 'Add GST details'}',
            onTap: () => setRequested(!requested),
            child: ExcludeSemantics(
              child: GestureDetector(
                key: ValueKey('buy-gst-request-${destination.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => setRequested(!requested),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: BuyV2Colors.softBlue,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: BuyV2Colors.navy,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$scopeLabel${gstAdded ? 'GST details' : 'Add GST details'}',
                              style: context.buyBody,
                            ),
                            Text(
                              gstAdded
                                  ? 'Saved recipient details for your purchases.'
                                  : 'GST applies as required. Add GSTIN only for recipient details on the invoice.',
                              style: context.buyMeta,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IgnorePointer(
                        child: Switch.adaptive(
                          value: requested,
                          onChanged: (_) {},
                          activeThumbColor: Colors.white,
                          activeTrackColor: BuyV2Colors.navy,
                          inactiveThumbColor: BuyV2Colors.navy,
                          inactiveTrackColor: Colors.white,
                          trackOutlineColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? Colors.transparent
                                : BuyV2Colors.line,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (requested) ...[
            const SizedBox(height: 9),
            if (controller.restoring) ...[
              const LinearProgressIndicator(
                key: ValueKey('buy-gst-profiles-loading'),
                minHeight: 2,
              ),
              const SizedBox(height: 7),
            ],
            if (controller.savedProfiles.isNotEmpty) ...[
              Text('Saved GST details', style: context.buyMeta),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final profile in controller.savedProfiles)
                    InputChip(
                      side: const BorderSide(
                        color: BuyV2ActionStyle.primaryBorder,
                      ),
                      backgroundColor: BuyV2ActionStyle.primaryFill,
                      key: ValueKey('buy-gst-profile-${profile.id}'),
                      label: Text(profile.legalName),
                      selected: details?.id == profile.id,
                      selectedColor: BuyV2ActionStyle.pressedFill,
                      labelStyle:
                          (Theme.of(context).chipTheme.labelStyle ??
                                  const TextStyle())
                              .copyWith(
                                color: BuyV2ActionStyle.primaryForeground,
                              ),
                      checkmarkColor: BuyV2ActionStyle.primaryForeground,
                      deleteIconColor: details?.id == profile.id
                          ? BuyV2ActionStyle.foreground
                          : Theme.of(context).colorScheme.primary,
                      onSelected: controller.busy
                          ? null
                          : (_) {
                              controller.selectSaved(destination, profile);
                              controller.useForDestinations(
                                destination,
                                destinations,
                              );
                            },
                      onDeleted:
                          controller.persistenceAvailable && !controller.busy
                          ? () => _confirmRemoveGstProfile(
                              context,
                              controller: controller,
                              profile: profile,
                            )
                          : null,
                      deleteButtonTooltipMessage: 'Remove GST details',
                    ),
                ],
              ),
              const SizedBox(height: 7),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: details == null
                    ? BuyV2Colors.softOrange
                    : BuyV2Colors.softGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details?.legalName ?? 'GST invoice details required',
                          style: context.buyBody,
                        ),
                        Text(
                          details == null
                              ? 'Add GSTIN, legal name and billing address.'
                              : '${details.gstin} · ${details.billingAddress}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.buyMeta,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: ValueKey(
                      'buy-gst-${details == null ? 'add' : 'edit'}-'
                      '${destination.name}',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: BuyV2Colors.navy,
                    ),
                    onPressed: () async {
                      await showBuyV2GstInvoiceSheet(
                        context,
                        controller: controller,
                        destination: destination,
                      );
                      controller.useForDestinations(destination, destinations);
                    },
                    child: Text(details == null ? 'Add' : 'Edit'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Recipient and delivery details are recorded where GST invoice rules require them.',
              style: context.buyMeta,
            ),
            if (controller.message case final message?) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      key: const ValueKey('buy-gst-profile-message'),
                      style: context.buyMeta.copyWith(
                        fontSize: 9,
                        color:
                            message == 'GST details saved.' ||
                                message ==
                                    'GST details kept until you close the app.' ||
                                message == 'GST details removed.'
                            ? BuyV2Colors.ink
                            : const Color(0xFFB42318),
                      ),
                    ),
                  ),
                  if (message ==
                          'Saved GST details could not be loaded. Try again.' &&
                      !controller.restoring)
                    TextButton(
                      key: const ValueKey('buy-gst-profiles-retry'),
                      onPressed: controller.restore,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

Future<void> _confirmRemoveGstProfile(
  BuildContext context, {
  required BuyV2GstInvoiceController controller,
  required BuyV2GstInvoiceDetails profile,
}) async {
  final remove = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remove GST details?'),
      content: Text(
        '${profile.legalName} will no longer appear in your saved GST details.',
      ),
      actions: [
        TextButton(
          key: const ValueKey('buy-gst-remove-cancel'),
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Keep'),
        ),
        Align(
          widthFactor: 1,
          heightFactor: 1,
          child: FilledButton(
            style: BuyV2ActionStyle.button(),
            key: const ValueKey('buy-gst-remove-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ),
      ],
    ),
  );
  if (remove == true && context.mounted) {
    await controller.removeSaved(profile);
  }
}

Future<void> showBuyV2GstInvoiceSheet(
  BuildContext context, {
  required BuyV2GstInvoiceController controller,
  required BuyV2Destination destination,
}) {
  final bottomSafeInset =
      BuyV2AddressSheetMotion.resolveModalActionBottomInset(context) + 12.0;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    routeSettings: const RouteSettings(name: 'buy-gst-invoice-details'),
    builder: (context) => _BuyV2GstInvoiceSheet(
      controller: controller,
      destination: destination,
      bottomSafeInset: bottomSafeInset,
    ),
  );
}

class _BuyV2GstInvoiceSheet extends StatefulWidget {
  const _BuyV2GstInvoiceSheet({
    required this.controller,
    required this.destination,
    required this.bottomSafeInset,
  });

  final BuyV2GstInvoiceController controller;
  final BuyV2Destination destination;
  final double bottomSafeInset;

  @override
  State<_BuyV2GstInvoiceSheet> createState() => _BuyV2GstInvoiceSheetState();
}

class _BuyV2GstInvoiceSheetState extends State<_BuyV2GstInvoiceSheet> {
  late final TextEditingController _legalName;
  late final TextEditingController _gstin;
  late final TextEditingController _billingAddress;
  late final FocusNode _legalNameFocus;
  late final FocusNode _gstinFocus;
  late final FocusNode _billingAddressFocus;
  late bool _remember;
  String? _error;

  void _clearEditedError(String _) {
    if (_error != null) setState(() => _error = null);
  }

  void _revealFocusedField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || MediaQuery.viewInsetsOf(context).bottom == 0) return;
      for (final focus in [
        _legalNameFocus,
        _gstinFocus,
        _billingAddressFocus,
      ]) {
        final fieldContext = focus.context;
        if (focus.hasFocus && fieldContext != null) {
          // Focus can precede the keyboard inset animation. Reveal again after
          // the form viewport has reached its final height above the save bar.
          final target = fieldContext.findRenderObject();
          target?.showOnScreen(rect: target.paintBounds.inflate(24));
          break;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final current = widget.controller.detailsFor(widget.destination);
    _legalName = TextEditingController(text: current?.legalName);
    _gstin = TextEditingController(text: current?.gstin);
    _billingAddress = TextEditingController(text: current?.billingAddress);
    _remember = widget.controller.persistenceAvailable;
    _legalNameFocus = FocusNode(debugLabel: 'GST legal name');
    _gstinFocus = FocusNode(debugLabel: 'GSTIN');
    _billingAddressFocus = FocusNode(debugLabel: 'GST billing address');
  }

  @override
  void dispose() {
    _legalName.dispose();
    _gstin.dispose();
    _billingAddress.dispose();
    _legalNameFocus.dispose();
    _gstinFocus.dispose();
    _billingAddressFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final legalName = _legalName.text.trim();
    final gstin = _gstin.text.trim().toUpperCase();
    final address = _billingAddress.text.trim();
    final gstinPattern = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z]Z[0-9A-Z]$',
    );
    if (legalName.length < 3) {
      _legalNameFocus.requestFocus();
      setState(() => _error = 'Enter a legal name with at least 3 characters.');
      return;
    }
    if (!gstinPattern.hasMatch(gstin)) {
      _gstinFocus.requestFocus();
      setState(() => _error = 'Check the 15-character GSTIN format.');
      return;
    }
    if (address.length < 8) {
      _billingAddressFocus.requestFocus();
      setState(() => _error = 'Enter the complete billing address.');
      return;
    }
    setState(() => _error = null);
    final saved = await widget.controller.save(
      destination: widget.destination,
      legalName: legalName,
      gstin: gstin,
      billingAddress: address,
      remember: _remember,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      final message =
          widget.controller.message ??
          'GST details could not be saved. Try again.';
      widget.controller.clearMessage();
      setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final modalBottomInset = media.viewInsets.bottom > 0
        ? 30.0
        : widget.bottomSafeInset;
    return AnimatedPadding(
      key: const ValueKey('buy-gst-invoice-sheet'),
      duration: BuyV2Motion.resolved(context, BuyV2Motion.stateChange),
      curve: Curves.easeOutCubic,
      onEnd: _revealFocusedField,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: modalBottomInset),
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: media.size.height * .9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      key: const ValueKey('buy-gst-form-scroll'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GST invoice details',
                            style: context.buyTitle.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'These details affect the invoice only. GST applies as required.',
                            style: context.buyMeta,
                          ),
                          const SizedBox(height: 12),
                          MergeSemantics(
                            child: Semantics(
                              label: 'Legal name',
                              child: FocusTraversalOrder(
                                order: const NumericFocusOrder(1),
                                child: TextField(
                                  key: const ValueKey('buy-gst-legal-name'),
                                  controller: _legalName,
                                  onChanged: _clearEditedError,
                                  focusNode: _legalNameFocus,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) =>
                                      _gstinFocus.requestFocus(),
                                  decoration: const InputDecoration(
                                    label: Text('Legal name'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          MergeSemantics(
                            child: Semantics(
                              label: 'GSTIN',
                              child: FocusTraversalOrder(
                                order: const NumericFocusOrder(2),
                                child: TextField(
                                  key: const ValueKey('buy-gst-gstin'),
                                  controller: _gstin,
                                  onChanged: _clearEditedError,
                                  focusNode: _gstinFocus,
                                  maxLength: 15,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) =>
                                      _billingAddressFocus.requestFocus(),
                                  decoration: const InputDecoration(
                                    label: Text('GSTIN'),
                                    semanticCounterText:
                                        '15 characters maximum',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          MergeSemantics(
                            child: Semantics(
                              label: 'Billing address',
                              child: FocusTraversalOrder(
                                order: const NumericFocusOrder(3),
                                child: TextField(
                                  key: const ValueKey(
                                    'buy-gst-billing-address',
                                  ),
                                  controller: _billingAddress,
                                  onChanged: _clearEditedError,
                                  focusNode: _billingAddressFocus,
                                  minLines: 2,
                                  maxLines: 3,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) =>
                                      _billingAddressFocus.unfocus(),
                                  decoration: const InputDecoration(
                                    label: Text('Billing address'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (widget.controller.persistenceAvailable)
                            FocusTraversalOrder(
                              order: const NumericFocusOrder(4),
                              child: SwitchListTile.adaptive(
                                key: const ValueKey('buy-gst-remember'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: _remember,
                                activeThumbColor: Colors.white,
                                activeTrackColor: BuyV2Colors.navy,
                                inactiveThumbColor: BuyV2Colors.navy,
                                inactiveTrackColor: Colors.white,
                                trackOutlineColor:
                                    WidgetStateProperty.resolveWith(
                                      (states) =>
                                          states.contains(WidgetState.selected)
                                          ? Colors.transparent
                                          : BuyV2Colors.line,
                                    ),
                                onChanged: widget.controller.busy
                                    ? null
                                    : (value) =>
                                          setState(() => _remember = value),
                                title: Text(
                                  widget.controller.sessionPersistenceOnly
                                      ? 'Use again until you close the app'
                                      : 'Remember these GST details',
                                  style: context.buyBody.copyWith(fontSize: 13),
                                ),
                                subtitle: Text(
                                  widget.controller.sessionPersistenceOnly
                                      ? 'These details are cleared when you close the app.'
                                      : 'Reuse them on a later invoice.',
                                  style: context.buyMeta.copyWith(fontSize: 11),
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'These details will be used for this order only.',
                                key: const ValueKey('buy-gst-session-only'),
                                style: context.buyMeta,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: BuyV2Colors.line)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error case final error?) ...[
                            Semantics(
                              liveRegion: true,
                              label: error,
                              child: Text(
                                error,
                                key: const ValueKey('buy-gst-error'),
                                style: const TextStyle(
                                  color: Color(0xFFB42318),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FocusTraversalOrder(
                              order: const NumericFocusOrder(5),
                              child: Align(
                                widthFactor: 1,
                                heightFactor: 1,
                                child: FilledButton(
                                  style: BuyV2ActionStyle.button(),
                                  key: const ValueKey('buy-gst-save'),
                                  onPressed: widget.controller.busy
                                      ? null
                                      : _save,
                                  child: widget.controller.busy
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Use GST details'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _commercialPaymentTermTitle(
  BuyV2CommercialPaymentTerm term,
) => switch (term.kind) {
  BuyV2CommercialPaymentTermKind.retailAdvance ||
  BuyV2CommercialPaymentTermKind.wholesaleAdvance => 'Full advance',
  BuyV2CommercialPaymentTermKind.bookingBalanceBeforeDispatch =>
    'Booking amount · balance before dispatch',
  BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery =>
    '${term.advancePercent == null ? 'Booking amount' : '${term.advancePercent}% advance'} · balance at delivery',
  BuyV2CommercialPaymentTermKind.paymentOnDelivery => 'Payment at delivery',
  BuyV2CommercialPaymentTermKind.supplierCredit =>
    '${term.advancePercent == null || term.advancePercent == 0 ? 'Supplier credit' : '${term.advancePercent}% advance + credit'} · ${term.netDays} days',
  BuyV2CommercialPaymentTermKind.regulatedCredit =>
    '${term.financierName} credit · ${term.netDays} days',
};

String _commercialPaymentTermDetail(BuyV2CommercialPaymentTerm term) {
  final amounts = term.balanceDue == 0
      ? '${buyV2Money(term.amountDueNow)} payable now'
      : '${buyV2Money(term.amountDueNow)} now · '
            '${buyV2Money(term.balanceDue)} ${term.balanceDueLabel}';
  if (term.kind == BuyV2CommercialPaymentTermKind.regulatedCredit) {
    return '$amounts · APR ${term.annualPercentageRate!.toStringAsFixed(2)}% · '
        'Key facts from ${term.financierName}';
  }
  if (term.kind == BuyV2CommercialPaymentTermKind.supplierCredit) {
    return '$amounts · Published directly by ${term.supplierName}';
  }
  return amounts;
}

class _CheckoutQuoteCard extends StatelessWidget {
  const _CheckoutQuoteCard({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final attempt = session.checkoutPaymentAttempt;
    if (session.checkoutRequiresResolution &&
        attempt == null &&
        !session.collectionCheckoutSelected) {
      final original = session.legacyCheckoutAttempt?.payment.request;
      final stacked =
          original == null || MediaQuery.textScalerOf(context).scale(14) > 18;
      return Container(
        key: const ValueKey('buy-checkout-original-payment-totals'),
        padding: const EdgeInsets.all(11),
        decoration: buyV2CardDecoration(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CartAmountRow(
              label: 'Original total',
              value: original == null
                  ? 'Needs checking'
                  : buyV2Money(original.total),
              strong: true,
              stacked: stacked,
            ),
            if (original != null)
              _CartAmountRow(
                label: 'Original amount due now',
                value: buyV2Money(original.amountDueNow),
                stacked: stacked,
              ),
            if (original != null && original.total > original.amountDueNow)
              _CartAmountRow(
                label: 'Balance due',
                value: buyV2Money(original.total - original.amountDueNow),
                stacked: stacked,
              ),
            Text(
              'Check this payment before choosing again.',
              style: context.buyMeta,
            ),
          ],
        ),
      );
    }
    if (attempt != null) {
      final agreed = attempt.groups.fold<int>(
        0,
        (sum, group) => sum + group.request.total,
      );
      final placed = attempt.groups
          .where(
            (group) => group.state == BuyV2CheckoutSubmissionState.confirmed,
          )
          .fold<int>(0, (sum, group) => sum + group.request.total);
      return Container(
        key: const ValueKey('buy-checkout-committed-totals'),
        padding: const EdgeInsets.all(11),
        decoration: buyV2CardDecoration(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CartAmountRow(
              label: 'Agreed total',
              value: buyV2Money(agreed),
              strong: true,
            ),
            if (placed > 0) ...[
              _CartAmountRow(label: 'Placed orders', value: buyV2Money(placed)),
              _CartAmountRow(
                label: 'Remaining orders',
                value: buyV2Money(agreed - placed),
              ),
            ],
          ],
        ),
      );
    }
    if (!session.checkoutQuoteEnabled) return const SizedBox.shrink();
    final quote = session.checkoutQuote;
    if (session.checkoutQuoteLoadState != BuyV2CommerceLoadState.ready ||
        quote == null ||
        session.checkoutQuoteReviewRequired) {
      final loading = session.checkoutQuoteBusy;
      return Container(
        key: ValueKey(
          'buy-checkout-quote-${session.checkoutQuoteLoadState.name}',
        ),
        padding: const EdgeInsets.all(11),
        decoration: buyV2CardDecoration(radius: 15),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 38,
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.receipt_long_outlined,
                      color: BuyV2Colors.muted,
                    ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loading
                        ? 'Checking the current total'
                        : 'Checkout total needs a refresh',
                    style: context.buyTitle.copyWith(fontSize: 13),
                  ),
                  Text(
                    loading
                        ? 'Confirming tax, freight, delivery and savings.'
                        : session.checkoutQuoteMessage ??
                              'The previous total has expired. Try again.',
                    style: context.buyMeta.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ),
            if (!loading)
              TextButton(
                key: const ValueKey('buy-checkout-quote-retry'),
                onPressed: session.refreshCheckoutQuote,
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    }
    final itemSubtotal = quote.lines.fold<int>(
      0,
      (total, line) => total + line.itemSubtotal,
    );
    final couponSaving = quote.lines.fold<int>(
      0,
      (total, line) => total + line.couponSaving,
    );
    final tip = quote.lines.fold<int>(0, (total, line) => total + line.tip);
    return Container(
      key: const ValueKey('buy-checkout-live-quote'),
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current Checkout total',
                  style: context.buyTitle.copyWith(fontSize: 16),
                ),
              ),
              Text(
                'Checked now',
                style: context.buyMeta.copyWith(
                  color: BuyV2Colors.green,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _CartAmountRow(
            label: 'Items subtotal',
            value: buyV2Money(itemSubtotal),
          ),
          if (couponSaving > 0)
            _CartAmountRow(
              label: 'Coupon saving',
              value: '−${buyV2Money(couponSaving)}',
              valueColor: BuyV2Colors.green,
            ),
          if (session.checkoutQuotedTax > 0)
            _CartAmountRow(
              label: 'GST and taxes',
              value: buyV2Money(session.checkoutQuotedTax),
            ),
          if (session.checkoutQuotedFreight > 0)
            _CartAmountRow(
              label: 'Freight',
              value: buyV2Money(session.checkoutQuotedFreight),
            ),
          if (session.checkoutQuotedDeliveryFee > 0)
            _CartAmountRow(
              label: 'Delivery fee',
              value: buyV2Money(session.checkoutQuotedDeliveryFee),
            ),
          if (tip > 0)
            _CartAmountRow(
              label: 'Optional delivery tips',
              value: buyV2Money(tip),
            ),
          if (session.checkoutQuotedPaymentCharge > 0)
            _CartAmountRow(
              label: 'Payment charge',
              value: buyV2Money(session.checkoutQuotedPaymentCharge),
            ),
          const Divider(height: 16),
          _CartAmountRow(
            label: 'Order total',
            value: buyV2Money(quote.total),
            strong: true,
          ),
          const SizedBox(height: 4),
          Text(
            'Quote ${quote.id} · valid until '
            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(quote.validUntil))}',
            key: const ValueKey('buy-checkout-quote-validity'),
            style: context.buyMeta.copyWith(fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _CheckoutCommercialPaymentTerms extends StatelessWidget {
  const _CheckoutCommercialPaymentTerms({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    if (!session.commercialPaymentTermsEnabled) {
      return const SizedBox.shrink();
    }
    if (session.commercialPaymentTermsLoadState !=
        BuyV2CommerceLoadState.ready) {
      final loading = session.commercialPaymentTermsBusy;
      return Container(
        key: ValueKey(
          'buy-checkout-payment-terms-'
          '${session.commercialPaymentTermsLoadState.name}',
        ),
        padding: const EdgeInsets.all(11),
        decoration: buyV2CardDecoration(radius: 15),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 38,
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: BuyV2Colors.muted,
                    ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loading
                        ? 'Checking payment terms'
                        : 'Payment terms need a refresh',
                    style: context.buyTitle.copyWith(fontSize: 13),
                  ),
                  Text(
                    loading
                        ? 'Matching each delivery with its published terms.'
                        : session.commercialPaymentTermsMessage ??
                              'Reconnect and try again.',
                    style: context.buyMeta.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ),
            if (!loading)
              TextButton(
                key: const ValueKey('buy-checkout-payment-terms-retry'),
                onPressed: session.refreshCommercialPaymentTerms,
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    final groups = session.checkoutFulfilmentGroups;
    return Container(
      key: const ValueKey('buy-checkout-payment-terms'),
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment terms', style: context.buyTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            session.isStoreProcurement
                ? 'Available from this supplier for your Store.'
                : groups.any(
                    (group) => group.destination == BuyV2Destination.wholesale,
                  )
                ? 'Wholesale terms are published by each supplier.'
                : 'Retail orders are paid online before placement.',
            style: context.buyMeta.copyWith(fontSize: 8.5),
          ),
          const SizedBox(height: 8),
          for (
            var groupIndex = 0;
            groupIndex < groups.length;
            groupIndex++
          ) ...[
            _CommercialPaymentTermGroup(
              key: ValueKey(
                'buy-payment-terms-group-${groups[groupIndex].key}',
              ),
              session: session,
              group: groups[groupIndex],
            ),
            if (groupIndex < groups.length - 1) const Divider(height: 18),
          ],
          if (session.isStoreProcurement) ...[
            const Divider(height: 18),
            Row(
              children: [
                Expanded(child: Text('Pay now', style: context.buyBody)),
                Text(
                  buyV2Money(session.checkoutAmountDueNow),
                  key: const ValueKey('buy-checkout-amount-due-now'),
                  style: context.buyTitle.copyWith(fontSize: 15),
                ),
              ],
            ),
            if (session.checkoutBalanceDue > 0) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text('Balance due later', style: context.buyMeta),
                  ),
                  Text(
                    buyV2Money(session.checkoutBalanceDue),
                    key: const ValueKey('buy-checkout-balance-due'),
                    style: context.buyBody,
                  ),
                ],
              ),
            ],
          ],
          if ((!session.isStoreProcurement ||
                  session.checkoutPaymentTermsReviewRequired) &&
              session.commercialPaymentTermsMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              session.commercialPaymentTermsMessage!,
              key: const ValueKey('buy-checkout-payment-terms-message'),
              style: context.buyMeta.copyWith(
                color: BuyV2Colors.orange,
                fontSize: 8.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _storePaymentChoiceLabel(BuyV2CommercialPaymentTerm term) {
  if (term.balanceDue == 0) return 'Pay in full';
  if (term.amountDueNow == 0 && term.netDays == null) return 'Pay on delivery';
  if (term.amountDueNow == 0) {
    return 'Pay within ${term.netDays} days of delivery';
  }
  final deposit = term.advancePercent == null
      ? '${buyV2Money(term.amountDueNow)} to confirm'
      : '${term.advancePercent}% to confirm';
  return term.netDays == null
      ? '$deposit · balance on delivery'
      : '$deposit · balance within ${term.netDays} days of delivery';
}

class _CommercialPaymentTermGroup extends StatefulWidget {
  const _CommercialPaymentTermGroup({
    super.key,
    required this.session,
    required this.group,
  });

  final BuyV2Session session;
  final BuyV2FulfilmentGroup group;

  @override
  State<_CommercialPaymentTermGroup> createState() =>
      _CommercialPaymentTermGroupState();
}

class _CommercialPaymentTermGroupState
    extends State<_CommercialPaymentTermGroup> {
  bool _changing = false;
  BuyV2Session get session => widget.session;
  BuyV2FulfilmentGroup get group => widget.group;

  @override
  Widget build(BuildContext context) {
    final terms = session.commercialPaymentTermsFor(group.key);
    final selected = session.selectedCommercialPaymentTermFor(group.key);
    if (session.isStoreProcurement) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(group.customerPartner, style: context.buyBody),
          const SizedBox(height: 6),
          if (terms.isEmpty)
            Text(
              'No payment arrangement is available for this purchase.',
              key: ValueKey('buy-payment-terms-empty-${group.key}'),
              style: context.buyMeta,
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey(
                'store-payment-selector-${group.key}-${selected?.id}',
              ),
              initialValue: selected?.id,
              isExpanded: true,
              menuMaxHeight: 280,
              itemHeight: null,
              decoration: const InputDecoration(
                labelText: 'Payment arrangement',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              hint: const Text('Choose an arrangement'),
              items: [
                for (final term in terms)
                  DropdownMenuItem(
                    value: term.id,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _storePaymentChoiceLabel(term),
                        style: context.buyBody,
                      ),
                    ),
                  ),
              ],
              onChanged: (id) {
                final term = terms.where((term) => term.id == id).firstOrNull;
                if (term != null) session.chooseCommercialPaymentTerm(term);
              },
            ),
          if (selected != null) ...[
            const SizedBox(height: 6),
            Text(
              _commercialPaymentTermDetail(selected),
              style: context.buyMeta,
            ),
          ],
          if (!terms.any(
            (term) =>
                term.kind == BuyV2CommercialPaymentTermKind.supplierCredit,
          )) ...[
            const SizedBox(height: 8),
            Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                key: ValueKey('store-payment-flexibility-info-${group.key}'),
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'More payment flexibility over time',
                  style: context.buyBody,
                ),
                children: [
                  Text(
                    'Completing purchases and paying this supplier on time may help you qualify for more flexible payment terms. Your supplier decides which options to offer.',
                    style: context.buyMeta,
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${group.destination.label} · ${group.customerPartner}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.buyBody.copyWith(fontSize: 10.5),
        ),
        const SizedBox(height: 4),
        if (terms.isEmpty)
          Text(
            'No payment term is available for this delivery.',
            key: ValueKey('buy-payment-terms-empty-${group.key}'),
            style: context.buyMeta.copyWith(
              color: BuyV2Colors.orange,
              fontSize: 9,
            ),
          )
        else if (selected != null && !_changing)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  key: ValueKey('buy-payment-term-summary-${group.key}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.destination == BuyV2Destination.wholesale
                          ? _commercialPaymentTermTitle(selected)
                          : 'Pay in full online',
                      style: context.buyBody,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _commercialPaymentTermDetail(selected),
                      style: context.buyMeta,
                    ),
                  ],
                ),
              ),
              if (group.destination == BuyV2Destination.wholesale)
                TextButton(
                  key: ValueKey('buy-payment-term-change-${group.key}'),
                  style: TextButton.styleFrom(
                    foregroundColor: BuyV2ActionStyle.primaryForeground,
                    minimumSize: const Size(64, 44),
                    textStyle: context.buyBody.copyWith(
                      fontFamily: 'Inter',
                      fontSize: 11,
                    ),
                  ),
                  onPressed:
                      session.checkoutBusy || session.checkoutRequiresResolution
                      ? null
                      : () => setState(() => _changing = true),
                  child: const Text('Change'),
                ),
            ],
          )
        else
          RadioGroup<String>(
            groupValue: selected?.id,
            onChanged: (termId) {
              final term = terms
                  .where((candidate) => candidate.id == termId)
                  .firstOrNull;
              if (term != null && session.chooseCommercialPaymentTerm(term)) {
                setState(() => _changing = false);
              }
            },
            child: Column(
              children: [
                for (final term in terms)
                  Semantics(
                    selected: selected?.id == term.id,
                    button: true,
                    label:
                        '${_commercialPaymentTermTitle(term)}. '
                        '${_commercialPaymentTermDetail(term)}',
                    child: Material(
                      color: Colors.transparent,
                      child: RadioListTile<String>(
                        key: ValueKey('buy-payment-term-${term.id}'),
                        value: term.id,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: Text(
                          _commercialPaymentTermTitle(term),
                          style: context.buyBody.copyWith(fontSize: 10),
                        ),
                        subtitle: Text(
                          _commercialPaymentTermDetail(term),
                          style: context.buyMeta.copyWith(fontSize: 8.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class BuyV2CheckoutView extends StatefulWidget {
  const BuyV2CheckoutView({
    super.key,
    required this.session,
    required this.gstInvoiceController,
    this.keyboardVisible = false,
    this.paymentHandoff,
  });

  final BuyV2Session session;
  final BuyV2GstInvoiceController gstInvoiceController;
  final bool keyboardVisible;
  final BuyV2PaymentHandoff? paymentHandoff;

  @override
  State<BuyV2CheckoutView> createState() => _BuyV2CheckoutViewState();
}

class _BuyV2CheckoutViewState extends State<BuyV2CheckoutView> {
  final _instructionsKey = GlobalKey<_CheckoutDeliveryInstructionsState>();
  BuyV2Session get session => widget.session;
  BuyV2GstInvoiceController get gstInvoiceController =>
      widget.gstInvoiceController;
  bool get keyboardVisible => widget.keyboardVisible;
  BuyV2PaymentHandoff? get paymentHandoff => widget.paymentHandoff;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([session, gstInvoiceController]),
      builder: (context, _) {
        final destinations = session.checkoutDestinations;
        final wholesaleReceiving =
            destinations.isNotEmpty &&
            destinations.every(
              (destination) => destination == BuyV2Destination.wholesale,
            );
        final invoiceDestinations = destinations
            .where(
              (destination) =>
                  destination == BuyV2Destination.shop ||
                  destination == BuyV2Destination.wholesale,
            )
            .toList(growable: false);
        final missingDetails = invoiceDestinations
            .where(
              (destination) =>
                  gstInvoiceController.requestedFor(destination) &&
                  gstInvoiceController.detailsFor(destination) == null,
            )
            .toList(growable: false);
        final keyboardObscured =
            keyboardVisible || MediaQuery.viewInsetsOf(context).bottom > 0;
        final action = _checkoutPrimaryAction(
          context,
          session: session,
          missingDetails: missingDetails,
          gstInvoiceController: gstInvoiceController,
          paymentHandoff: paymentHandoff,
          reviewInstructions: () => _instructionsKey.currentState?.openEditor(),
        );
        final returnAction = _ReturnAffordance(
          label: 'Cart',
          foreground: BuyV2Colors.ink,
          onTap: session.checkoutBusy
              ? () => session.showNotice(
                  'Please wait while your payment status is checked.',
                )
              : session.goBack,
          tightHitOwner: true,
          hitOwnerKey: const ValueKey('buy-checkout-return-cart'),
          minimumHeight: 44,
        );
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: BuyV2Colors.ink,
              secondary: BuyV2Colors.ink,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: BuyV2Colors.ink,
                textStyle: context.buyBody,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  key: const PageStorageKey('buy-checkout-unified'),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  children: [
                    Row(
                      children: [
                        Flexible(child: returnAction),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Checkout',
                            key: const ValueKey('buy-checkout-heading'),
                            textAlign: TextAlign.end,
                            style: context.buyBody,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _CheckoutAddressStage(
                      key: const ValueKey('buy-checkout-address-stage'),
                      session: session,
                      wholesaleReceiving: wholesaleReceiving,
                    ),
                    const SizedBox(height: 8),
                    _CheckoutOrderDetails(
                      key: const ValueKey('buy-checkout-order-details'),
                      session: session,
                      gstInvoiceController: gstInvoiceController,
                      invoiceDestinations: invoiceDestinations,
                      instructionsKey: _instructionsKey,
                    ),
                    const SizedBox(height: 8),
                    _CheckoutPaymentStage(
                      key: const ValueKey('buy-checkout-payment-stage'),
                      session: session,
                      hasPaymentHandoff: paymentHandoff != null,
                    ),
                  ],
                ),
              ),
              if (!keyboardObscured)
                _CheckoutPrimaryActionBar(
                  session: session,
                  label: action.$1,
                  onPressed: action.$2,
                  busy: session.checkoutBusy,
                ),
            ],
          ),
        );
      },
    );
  }
}

(String, VoidCallback?) _checkoutPrimaryAction(
  BuildContext context, {
  required BuyV2Session session,
  required List<BuyV2Destination> missingDetails,
  required BuyV2GstInvoiceController gstInvoiceController,
  required BuyV2PaymentHandoff? paymentHandoff,
  required VoidCallback reviewInstructions,
}) {
  if (session.checkoutBusy) return ('Checking payment…', null);
  if (session.collectionCheckoutSelected) {
    final controller = session.collectionCheckout;
    if (controller?.unresolved == true) {
      if (controller?.paymentActionUri != null && paymentHandoff != null) {
        return (
          'Pay ${_collectionCheckoutAmount(session)}',
          () => session.continueCollectionPayment(paymentHandoff),
        );
      }
      return ('Check payment', session.reconcileCollectionPurchase);
    }
    if (session.purchaseOrderReviewRequired) {
      return ('Check order agreement', null);
    }
    final basket = session.currentCollectionBasket;
    if (basket != null && controller?.canPlace(basket) == true) {
      return (
        'Pay ${_collectionCheckoutAmount(session)} & place order',
        () async {
          final committedTotal = session.collectionCheckoutQuote?.totalMinor;
          final committedMethod = session.selectedPayment;
          if (!session.showCheckoutStep(BuyV2CheckoutStep.confirm)) return;
          await session.submitCollectionPurchase();
          if (session.view == BuyV2View.checkout &&
              session.collectionCheckoutQuote?.totalMinor == committedTotal &&
              session.selectedPayment == committedMethod &&
              controller?.paymentActionUri != null &&
              paymentHandoff != null) {
            await session.continueCollectionPayment(paymentHandoff);
          }
        },
      );
    }
    return (
      'Check total',
      basket != null &&
              controller?.available == true &&
              session.paymentEligibilityFor(session.selectedPayment).selectable
          ? session.prepareCollectionCheckout
          : null,
    );
  }
  final group = session.currentCheckoutPaymentGroup;
  if (session.checkoutRecoveryBlocked) {
    return (
      'Check payment',
      session.checkoutBusy ? null : session.reconcilePayment,
    );
  }
  if (group != null) {
    if (group.financiallyClosed) {
      return (
        'Review remaining checkout',
        session.reviewRemainingGroupedCheckout,
      );
    }
    if (session.checkoutSubmissionState == BuyV2CheckoutSubmissionState.idle) {
      if (session.checkoutPaymentGroupReviewRequired ||
          !session.catalogueNow().isBefore(
            session.checkoutPaymentAttempt!.quoteValidUntil,
          )) {
        return (
          'Review remaining checkout',
          session.reviewRemainingGroupedCheckout,
        );
      }
      return (
        session.checkoutPaymentActionAmount == 0
            ? 'Place orders'
            : 'Pay ${buyV2Money(session.checkoutPaymentActionAmount)} · Payment ${session.checkoutPaymentNumber} of ${session.checkoutPaymentCount}',
        () async {
          final committedAmount = session.checkoutPaymentActionAmount;
          final committedMethod = session.selectedPayment;
          final attemptId = session.checkoutPaymentAttempt?.id;
          await session.submitOrder();
          if (session.view == BuyV2View.checkout &&
              session.checkoutPaymentAttempt?.id == attemptId &&
              session.checkoutPaymentActionAmount == committedAmount &&
              session.selectedPayment == committedMethod &&
              session.checkoutSubmissionState ==
                  BuyV2CheckoutSubmissionState.paymentActionRequired &&
              paymentHandoff != null) {
            await session.continuePayment(paymentHandoff);
          }
        },
      );
    }
    if (const {
      BuyV2CheckoutSubmissionState.failed,
      BuyV2CheckoutSubmissionState.cancelled,
      BuyV2CheckoutSubmissionState.unavailable,
    }.contains(session.checkoutSubmissionState)) {
      return ('Check payment', session.reconcilePayment);
    }
  }
  if (session.checkoutRequiresResolution &&
      (session.checkoutSubmissionState !=
              BuyV2CheckoutSubmissionState.paymentActionRequired ||
          !session.checkoutRecoveryAmountKnown)) {
    return (
      'Check payment',
      session.checkoutBusy ? null : session.reconcilePayment,
    );
  }
  final selectedPaymentAvailable =
      _buyV2CustomerPaymentChoices(
        session,
      ).any((choice) => choice.$1 == session.selectedPayment) &&
      session.paymentEligibilityFor(session.selectedPayment).selectable;
  switch (session.checkoutSubmissionState) {
    case BuyV2CheckoutSubmissionState.paymentActionRequired:
      return (
        paymentHandoff == null
            ? 'Unavailable'
            : 'Pay ${buyV2Money(session.checkoutPaymentActionAmount)}',
        paymentHandoff == null
            ? null
            : () => session.continuePayment(paymentHandoff),
      );
    case BuyV2CheckoutSubmissionState.paymentPending:
    case BuyV2CheckoutSubmissionState.paymentUnknown:
      return ('Check payment', session.reconcilePayment);
    case BuyV2CheckoutSubmissionState.cancelled:
      return ('Choose again', session.retryCheckoutPayment);
    case BuyV2CheckoutSubmissionState.failed:
    case BuyV2CheckoutSubmissionState.unavailable:
      return ('Try payment again', session.retryCheckoutPayment);
    case BuyV2CheckoutSubmissionState.submitting:
      return ('Checking payment…', null);
    case BuyV2CheckoutSubmissionState.confirmed:
      return ('Order confirmed', null);
    case BuyV2CheckoutSubmissionState.idle:
      if (session.selectedAddressOrNull == null) {
        return (
          'Add delivery address',
          () => _showAddAddressSheet(context, session),
        );
      }
      if (!selectedPaymentAvailable) return ('Choose payment method', null);
      if (session.publicDeliveryInstructionReviewRequired) {
        return ('Review delivery instructions', reviewInstructions);
      }
      if (session.checkoutDeliveryEstimateReviewRequired) {
        return ('Check delivery', session.refreshCheckoutDeliveryEstimates);
      }
      if (missingDetails.isNotEmpty) {
        return (
          'Add GST details',
          () => showBuyV2GstInvoiceSheet(
            context,
            controller: gstInvoiceController,
            destination: missingDetails.first,
          ),
        );
      }
      final reviewBlocked =
          session.purchaseOrderReviewRequired ||
          session.checkoutQuoteReviewRequired ||
          session.checkoutPaymentTermsReviewRequired ||
          session.checkoutPaymentGroupReviewRequired ||
          session.checkoutBenefitReviewRequired ||
          session.checkoutPriceReviewRequired ||
          session.checkoutPromiseReviewRequired;
      final orderWord = session.checkoutFulfilmentGroups.length > 1
          ? 'orders'
          : 'order';
      final label =
          session.selectedPayment == 'Cash on Delivery' ||
              session.checkoutAmountDueNow == 0
          ? 'Place $orderWord'
          : session.canChooseUpiQr && session.useUpiQr
          ? 'Show QR · ${buyV2Money(session.checkoutPaymentActionAmount)}'
          : session.checkoutPaymentCount > 1
          ? 'Pay ${buyV2Money(session.checkoutPaymentActionAmount)} · Payment 1 of ${session.checkoutPaymentCount}'
          : 'Pay ${buyV2Money(session.checkoutPaymentActionAmount)} & place $orderWord';
      return (
        label,
        reviewBlocked
            ? null
            : () async {
                final committedAmount = session.checkoutPaymentActionAmount;
                final committedMethod = session.selectedPayment;
                await session.submitOrder();
                if (session.view == BuyV2View.checkout &&
                    session.checkoutPaymentActionAmount == committedAmount &&
                    session.selectedPayment == committedMethod &&
                    session.checkoutSubmissionState ==
                        BuyV2CheckoutSubmissionState.paymentActionRequired &&
                    paymentHandoff != null) {
                  await session.continuePayment(paymentHandoff);
                }
              },
      );
  }
}

String _collectionCheckoutAmount(BuyV2Session session) {
  final quote = session.collectionCheckoutQuote;
  return quote == null ? 'Total pending' : _collectionMoney(quote.totalMinor);
}

String _buyV2OrderMoney(BuyV2Order order) => order.totalMinor == null
    ? buyV2Money(order.total)
    : _collectionMoney(order.totalMinor!);

class _CheckoutCollectionDetails extends StatelessWidget {
  const _CheckoutCollectionDetails({
    required this.session,
    this.choosingStore = false,
    this.reviewing = false,
  });

  final BuyV2Session session;
  final bool choosingStore;
  final bool reviewing;

  @override
  Widget build(BuildContext context) {
    final store = session.collectionCheckoutStore;
    final quote = session.collectionCheckoutQuote;
    final message = session.collectionCheckoutMessage;
    final resolving = session.checkoutRequiresResolution;
    final notice = message == null
        ? null
        : Semantics(
            liveRegion: true,
            child: Container(
              key: const ValueKey('buy-checkout-collection-notice'),
              padding: const EdgeInsets.all(10),
              decoration: buyV2CardDecoration(
                color: BuyV2Colors.softBlue,
                radius: 12,
              ),
              child: Text(message, style: context.buyBody),
            ),
          );
    final othersRemain = session.cartLines.any(
      (line) => line.product.storeId != store?.id,
    );
    return Column(
      key: const ValueKey('buy-checkout-collection-details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!resolving || MediaQuery.sizeOf(context).height >= 500)
          Text(
            resolving ? 'Payment status' : 'Collect at store',
            style: context.buyBody,
          ),
        if (!resolving) ...[
          const SizedBox(height: 3),
          Text(
            'Collect from this store when your order is ready.',
            style: context.buyMeta,
          ),
        ],
        const SizedBox(height: 10),
        if (resolving && notice != null) ...[
          notice,
          const SizedBox(height: 10),
        ],
        if (choosingStore && session.collectionCheckoutStores.length > 1)
          for (final option in session.collectionCheckoutStores) ...[
            Semantics(
              selected: option.id == store?.id,
              child: _CheckoutCard(
                key: ValueKey('buy-checkout-collection-store-${option.id}'),
                icon: option.id == store?.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                title:
                    '${buyV2CustomerStoreName(option.name, option.id)} · ${option.area}',
                detail: option.address,
                onTap:
                    session.checkoutBusy || session.checkoutRequiresResolution
                    ? null
                    : () => session.chooseCheckoutCollection(
                        true,
                        storeId: option.id,
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ]
        else if (store != null)
          _CheckoutCard(
            key: const ValueKey('buy-checkout-collection-store'),
            icon: Icons.storefront_outlined,
            title:
                '${buyV2CustomerStoreName(store.name, store.id)} · ${store.area}',
            detail: store.address,
            action: reviewing && !choosingStore ? 'Change' : null,
            onTap:
                reviewing &&
                    !choosingStore &&
                    !session.checkoutRequiresResolution
                ? () => session.showCheckoutStep(BuyV2CheckoutStep.address)
                : null,
          ),
        if (store != null && !resolving) ...[
          BuyV2StoreAddress(store: store, showAddress: false),
          const SizedBox(height: 8),
          Text(
            'Check items at the counter, then scan the store’s QR for this order.',
            style: context.buyMeta,
          ),
        ],
        if (othersRemain) ...[
          const SizedBox(height: 6),
          Text('Other store items stay in your Cart.', style: context.buyMeta),
        ],
        if (!resolving && notice != null) ...[
          const SizedBox(height: 10),
          notice,
        ],
        if (reviewing) ...[
          if (session.purchaseOrderRequired && !resolving) ...[
            const SizedBox(height: 12),
            BuyV2PurchaseOrderPanel(session: session),
          ],
          const SizedBox(height: 12),
          for (final line in session.checkoutLines) ...[
            _CheckoutCard(
              key: ValueKey('buy-checkout-collection-line-${line.product.id}'),
              icon: Icons.inventory_2_outlined,
              title: line.product.customerTitle,
              detail:
                  '${line.quantity} × ${line.product.pack} · '
                  '${_collectionMoney(quote?.lineAmountsMinor[line.product.id] ?? line.total * 100)}',
            ),
            const SizedBox(height: 8),
          ],
          if (quote != null) ...[
            _CheckoutPaymentFact(
              label: 'Tax',
              value: _collectionMoney(quote.taxMinor),
            ),
            _CheckoutPaymentFact(
              label: 'Payment charge',
              value: _collectionMoney(quote.paymentChargeMinor),
            ),
            if (quote.discountMinor > 0)
              _CheckoutPaymentFact(
                label: 'Saving',
                value: _collectionMoney(quote.discountMinor),
              ),
            _CheckoutPaymentFact(
              label: 'Total',
              value: _collectionMoney(quote.totalMinor),
            ),
          ],
        ],
      ],
    );
  }
}

class _CheckoutAddressStage extends StatefulWidget {
  const _CheckoutAddressStage({
    super.key,
    required this.session,
    required this.wholesaleReceiving,
  });

  final BuyV2Session session;
  final bool wholesaleReceiving;

  @override
  State<_CheckoutAddressStage> createState() => _CheckoutAddressStageState();
}

class _CheckoutAddressStageState extends State<_CheckoutAddressStage> {
  bool _choosingAddress = false;
  BuyV2Session get session => widget.session;
  bool get wholesaleReceiving => widget.wholesaleReceiving;

  @override
  Widget build(BuildContext context) {
    final addresses = session.addresses;
    final selectedId = session.selectedAddressId;
    final address = session.selectedAddressOrNull;
    final locked = session.checkoutBusy || session.checkoutRequiresResolution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (session.collectionCheckoutStores.isNotEmpty ||
            session.collectionCheckoutSelected) ...[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                side: const BorderSide(color: BuyV2ActionStyle.primaryBorder),
                backgroundColor: BuyV2ActionStyle.primaryFill,
                selectedColor: BuyV2ActionStyle.pressedFill,
                labelStyle: (TextStyle(
                  color: BuyV2ActionStyle.foreground,
                )).copyWith(color: BuyV2ActionStyle.primaryForeground),
                key: const ValueKey('buy-checkout-delivery-choice'),
                showCheckmark: true,
                checkmarkColor: BuyV2ActionStyle.primaryForeground,
                label: const Text('Delivery'),
                selected: !session.collectionCheckoutSelected,
                onSelected: session.checkoutRequiresResolution
                    ? null
                    : (_) => session.chooseCheckoutCollection(false),
              ),
              ChoiceChip(
                side: const BorderSide(color: BuyV2ActionStyle.primaryBorder),
                backgroundColor: BuyV2ActionStyle.primaryFill,
                selectedColor: BuyV2ActionStyle.pressedFill,
                labelStyle: (TextStyle(
                  color: BuyV2ActionStyle.foreground,
                )).copyWith(color: BuyV2ActionStyle.primaryForeground),
                key: const ValueKey('buy-checkout-collection-choice'),
                showCheckmark: true,
                checkmarkColor: BuyV2ActionStyle.primaryForeground,
                label: const Text('Collect at store'),
                selected: session.collectionCheckoutSelected,
                onSelected: session.checkoutRequiresResolution
                    ? null
                    : (_) => session.chooseCheckoutCollection(true),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        if (session.collectionCheckoutSelected)
          _CheckoutCollectionDetails(
            session: session,
            choosingStore: true,
            reviewing: true,
          )
        else if (address != null && (!_choosingAddress || locked))
          _CheckoutCard(
            key: const ValueKey('buy-checkout-confirm-address'),
            icon: Icons.location_on_outlined,
            title: wholesaleReceiving ? 'Receive at' : 'Deliver to',
            detail:
                '${address.recipient} · ${address.phone}\n'
                '${address.line}, ${address.shortLine}',
            action: locked ? null : 'Change',
            onTap: locked
                ? null
                : () => setState(() => _choosingAddress = true),
          )
        else ...[
          Text(
            wholesaleReceiving ? 'Receiving address' : 'Delivery address',
            style: context.buyBody,
          ),
          const SizedBox(height: 6),
          if (addresses.isEmpty)
            Container(
              key: const ValueKey('buy-checkout-address-empty'),
              padding: const EdgeInsets.all(14),
              decoration: buyV2CardDecoration(
                color: BuyV2Colors.softBlue,
                radius: 16,
              ),
              child: Text(
                'Add an address to continue.',
                textAlign: TextAlign.center,
                style: context.buyBody,
              ),
            )
          else
            for (final address in addresses) ...[
              _CheckoutAddressChoice(
                address: address,
                selected: selectedId == address.id,
                onSelect: () {
                  if (locked) return;
                  session.chooseAddress(address.id);
                  setState(() => _choosingAddress = false);
                },
                onEdit: () => _showAddAddressSheet(
                  context,
                  session,
                  existingAddress: address,
                ),
              ),
              const SizedBox(height: 8),
            ],
          SizedBox(
            height: BuyV2Metrics.minimumTap,
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: OutlinedButton.icon(
                style: BuyV2ActionStyle.button(),
                key: const ValueKey('buy-checkout-add-address'),
                onPressed: () => _showAddAddressSheet(context, session),
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(
                  addresses.isEmpty ? 'Add address' : 'Add another address',
                ),
              ),
            ),
          ),
          if (address != null)
            TextButton(
              key: const ValueKey('buy-checkout-address-cancel'),
              onPressed: () => setState(() => _choosingAddress = false),
              child: const Text('Cancel'),
            ),
        ],
      ],
    );
  }
}

class _CheckoutAddressChoice extends StatelessWidget {
  const _CheckoutAddressChoice({
    required this.address,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
  });

  final BuyV2Address address;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey('buy-checkout-address-${address.id}'),
      container: true,
      selected: selected,
      button: true,
      label:
          '${address.label}. ${address.recipient}. ${address.line}, ${address.shortLine}.',
      onTap: onSelect,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? BuyV2Colors.softBlue : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? BuyV2Colors.ink : BuyV2Colors.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 5, 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: BuyV2Colors.ink,
                    size: 22,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address.label, style: context.buyBody),
                        const SizedBox(height: 2),
                        Text(
                          '${address.recipient} · ${address.phone}',
                          style: context.buyMeta.copyWith(
                            color: BuyV2Colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${address.line}, ${address.shortLine}',
                          style: context.buyMeta,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: ValueKey('buy-checkout-address-edit-${address.id}'),
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(58, 44),
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<(String, IconData, String)> _buyV2CustomerPaymentChoices(
  BuyV2Session session,
) {
  final choices =
      (session.supportedPaymentMethods.length > 2
              ? <(String, IconData, String)>[
                  (
                    'UPI',
                    Icons.phone_android_rounded,
                    'Pay using an eligible UPI app. Bank limits apply.',
                  ),
                  (
                    'Cheque',
                    Icons.receipt_long_outlined,
                    'Payment remains pending until the cheque clears.',
                  ),
                  (
                    'Bank transfer',
                    Icons.account_balance_outlined,
                    'Use the verified bank instructions for this purchase.',
                  ),
                  (
                    'NEFT',
                    Icons.account_balance_outlined,
                    'Transfer with the purchase reference; confirmation follows reconciliation.',
                  ),
                  (
                    'RTGS',
                    Icons.account_balance_outlined,
                    'Available subject to bank amount limits and supplier acceptance.',
                  ),
                  (
                    'Cash',
                    Icons.payments_outlined,
                    'Payment requires a confirmed supplier receipt.',
                  ),
                ]
              : [
                  ('UPI', Icons.phone_android_rounded, 'Pay with any UPI app'),
                  ('Card', Icons.credit_card_rounded, 'Debit or credit card'),
                ])
          .followedBy(
            session.isStoreProcurement ||
                    session.supportedPaymentMethods.length <= 2
                ? const <(String, IconData, String)>[]
                : [('Card', Icons.credit_card_rounded, 'Debit or credit card')],
          )
          .where(
            (choice) => session.availablePaymentMethods.contains(choice.$1),
          )
          .map((choice) {
            final eligibility = session.paymentEligibilityFor(choice.$1);
            final cap = eligibility.capability;
            final details = <String>[
              choice.$3,
              if (eligibility.reason != null) eligibility.reason!,
              if (cap?.recipientName != null) 'Pay to: ${cap!.recipientName}.',
              if (cap?.minimumMinor != null)
                'Minimum: ${_comparisonMoney(cap!.minimumMinor!)}.',
              if (cap?.maximumMinor != null)
                'Maximum: ${_comparisonMoney(cap!.maximumMinor!)}.',
              if (cap?.remainingMinor != null)
                'Remaining limit: ${_comparisonMoney(cap!.remainingMinor!)}.',
              if (cap != null &&
                  (cap.minimumMinor == null || cap.maximumMinor == null))
                'Bank/provider limits apply.',
              if (session.selectedPayment == choice.$1 &&
                  session.currentPaymentChargeMinor != null)
                'Quoted payment charge: ${_comparisonMoney(session.currentPaymentChargeMinor!)}.',
            ];
            return (choice.$1, choice.$2, details.join(' '));
          })
          .toList(growable: false);
  return [
    ...choices.where(
      (choice) =>
          choice.$1 == session.selectedPayment &&
          session.paymentEligibilityFor(choice.$1).selectable,
    ),
    ...choices.where(
      (choice) =>
          choice.$1 != session.selectedPayment ||
          !session.paymentEligibilityFor(choice.$1).selectable,
    ),
  ];
}

class _CheckoutPaymentStage extends StatefulWidget {
  const _CheckoutPaymentStage({
    super.key,
    required this.session,
    required this.hasPaymentHandoff,
  });

  final BuyV2Session session;
  final bool hasPaymentHandoff;

  @override
  State<_CheckoutPaymentStage> createState() => _CheckoutPaymentStageState();
}

class _CheckoutPaymentStageState extends State<_CheckoutPaymentStage> {
  bool _choosingPayment = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final choices = _buyV2CustomerPaymentChoices(session);
    final selected = choices
        .where((choice) => choice.$1 == session.selectedPayment)
        .firstOrNull;
    final locked = session.checkoutBusy || session.checkoutRequiresResolution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!session.collectionCheckoutSelected &&
            session.checkoutSubmissionState !=
                BuyV2CheckoutSubmissionState.idle)
          _CheckoutPaymentStateRow(
            session: session,
            hasPaymentHandoff: widget.hasPaymentHandoff,
          ),
        if (!session.collectionCheckoutSelected &&
            (session.checkoutPaymentGroups.isNotEmpty ||
                session.checkoutPaymentAttempt != null ||
                session.checkoutPaymentGroupReviewRequired))
          _CheckoutPaymentGroups(session: session),
        if (selected != null && (!_choosingPayment || locked))
          _CheckoutCard(
            key: const ValueKey('buy-checkout-confirm-payment'),
            icon: selected.$2,
            title: 'Payment · ${selected.$1}',
            detail: selected.$1 == 'Cash on Delivery'
                ? '${buyV2Money(session.checkoutAmountDueNow)} payable on delivery'
                : selected.$3,
            action: locked ? null : 'Change',
            onTap: locked
                ? null
                : () => setState(() => _choosingPayment = true),
          )
        else ...[
          Text('Payment method', style: context.buyBody),
          const SizedBox(height: 6),
          if (choices.isEmpty)
            Text(
              'Payment methods are unavailable right now. Your Cart is retained.',
              style: context.buyMeta,
            )
          else
            for (final choice in choices) ...[
              _BuyV2PaymentChoice(
                choice: choice,
                selected: session.selectedPayment == choice.$1,
                onTap:
                    locked ||
                        !session.paymentEligibilityFor(choice.$1).selectable
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        session.choosePayment(choice.$1);
                        setState(() => _choosingPayment = false);
                      },
              ),
              const SizedBox(height: 6),
            ],
          if (selected != null)
            TextButton(
              key: const ValueKey('buy-checkout-payment-cancel'),
              onPressed: () => setState(() => _choosingPayment = false),
              child: const Text('Cancel'),
            ),
        ],
        if (session.canChooseUpiQr && !locked)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final qr in [false, true])
                  Semantics(
                    checked: session.useUpiQr == qr,
                    inMutuallyExclusiveGroup: true,
                    child: TextButton.icon(
                      key: ValueKey(qr ? 'buy-upi-use-qr' : 'buy-upi-use-app'),
                      onPressed: () => session.chooseUpiQr(qr),
                      icon: Icon(
                        session.useUpiQr == qr
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                      ),
                      label: Text(qr ? 'Scan QR' : 'UPI app'),
                    ),
                  ),
              ],
            ),
          ),
        if (session.upiQrAction case final qr?)
          _CheckoutUpiQr(session: session, action: qr),
        if ((session.currentPaymentChargeMinor ?? 0) > 0)
          _CheckoutPaymentFact(
            label: 'Payment charge',
            value: _comparisonMoney(session.currentPaymentChargeMinor!),
          ),
        if (session.checkoutBalanceDue > 0)
          _CheckoutPaymentFact(
            label: 'Balance due',
            value: buyV2Money(session.checkoutBalanceDue),
          ),
      ],
    );
  }
}

class _CheckoutUpiQr extends StatefulWidget {
  const _CheckoutUpiQr({required this.session, required this.action});
  final BuyV2Session session;
  final BuyV2UpiQrAction action;
  @override
  State<_CheckoutUpiQr> createState() => _CheckoutUpiQrState();
}

class _CheckoutUpiQrState extends State<_CheckoutUpiQr> {
  Timer? _expiry;
  @override
  void initState() {
    super.initState();
    _watchExpiry();
  }

  @override
  void didUpdateWidget(covariant _CheckoutUpiQr oldWidget) {
    super.didUpdateWidget(oldWidget);
    _watchExpiry();
  }

  void _watchExpiry() {
    _expiry?.cancel();
    final remaining = widget.action.expiresAt.difference(
      widget.session.catalogueNow(),
    );
    _expiry = Timer(remaining.isNegative ? Duration.zero : remaining, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.upiQrAction == null) {
      return Text(
        'QR expired. Check payment before trying again.',
        key: const ValueKey('buy-upi-qr-expired'),
        style: context.buyMeta,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Scan with another phone’s UPI app', style: context.buyBody),
        Text(
          '${buyV2Money(widget.session.checkoutPaymentActionAmount)} · MoolSocial',
          style: context.buyBody,
        ),
        Text(
          'Payee: ${widget.action.uri.queryParameters['pn']}',
          textAlign: TextAlign.center,
          style: context.buyMeta,
        ),
        Semantics(
          label:
              'Order payment QR. Scan using another phone. Payment is confirmed only after verification.',
          image: true,
          child: SizedBox.square(
            dimension: 220,
            child: CustomPaint(
              key: const ValueKey('buy-upi-order-qr'),
              painter: _CheckoutUpiQrPainter(widget.action.uri.toString()),
            ),
          ),
        ),
        Text(
          'Authorise in your UPI app, then tap Check payment. Do not pay twice.',
          textAlign: TextAlign.center,
          style: context.buyMeta,
        ),
        Text(
          'Check the payee in your UPI app. Never share your PIN or OTP.',
          textAlign: TextAlign.center,
          style: context.buyMeta,
        ),
      ],
    );
  }
}

class _CheckoutUpiQrPainter extends CustomPainter {
  _CheckoutUpiQrPainter(this.data);
  final String data;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final side = size.shortestSide - 40;
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    final ink = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    for (final element in buy_qr.Barcode.qrCode().make(
      data,
      width: side,
      height: side,
    )) {
      if (element is buy_qr.BarcodeBar && element.black) {
        canvas.drawRect(
          Rect.fromLTWH(
            origin.dx + element.left,
            origin.dy + element.top,
            element.width,
            element.height,
          ),
          ink,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckoutUpiQrPainter oldDelegate) =>
      oldDelegate.data != data;
}

class _CheckoutPaymentFact extends StatelessWidget {
  const _CheckoutPaymentFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: context.buyMeta)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.buyMeta.copyWith(
                color: BuyV2Colors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyDecisionLayout extends StatelessWidget {
  const _BuyDecisionLayout({
    required this.body,
    required this.minimumBodyWidth,
    this.action,
    this.actionWidth = 0,
  });

  final Widget body;
  final Widget? action;
  final double minimumBodyWidth;
  final double actionWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final control = action;
      if (control == null) return body;
      final target = SizedBox(width: actionWidth, child: control);
      if (constraints.maxWidth >= minimumBodyWidth + actionWidth + 8) {
        return Row(
          children: [
            Expanded(child: body),
            const SizedBox(width: 8),
            target,
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight, child: target),
        ],
      );
    },
  );
}

class _CheckoutPaymentGroups extends StatelessWidget {
  const _CheckoutPaymentGroups({required this.session});
  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final groups = session.checkoutPaymentGroups;
    final attempt = session.checkoutPaymentAttempt;
    final count = session.checkoutPaymentCount;
    final orderCount = attempt == null
        ? session.checkoutFulfilmentGroups.length
        : attempt.groups.expand((group) => group.fulfilmentKeys).toSet().length;
    final heading = session.checkoutPaymentGroupReviewRequired
        ? 'Check payment groups'
        : count == 0
        ? 'No payment due now · place orders'
        : '${count == 1 ? '1 payment' : '$count separate payments'} · $orderCount ${orderCount == 1 ? 'order' : 'orders'}';
    return Semantics(
      key: const ValueKey('buy-checkout-payment-groups'),
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: context.buyBody),
            if (session.checkoutPaymentGroupReviewRequired)
              Text(
                'Refresh and review the payment amounts before placing orders.',
                style: context.buyMeta,
              )
            else if (groups.isEmpty)
              Text(
                session.checkoutFulfilmentGroups
                    .map((group) => group.partner)
                    .toSet()
                    .join(' · '),
                style: context.buyMeta,
              )
            else
              for (final group in groups)
                Builder(
                  builder: (context) {
                    final progress = attempt?.groups
                        .where(
                          (value) => value.request.paymentGroupId == group.id,
                        )
                        .firstOrNull;
                    final lines =
                        progress?.request.lines ??
                        session.checkoutFulfilmentGroups
                            .where(
                              (value) =>
                                  group.fulfilmentKeys.contains(value.key),
                            )
                            .expand((value) => value.lines)
                            .toList();
                    final scope = lines
                        .map((line) => line.product.seller)
                        .toSet()
                        .join(' · ');
                    final state = progress?.state;
                    final status =
                        state == BuyV2CheckoutSubmissionState.confirmed
                        ? 'Placed'
                        : state == null ||
                              state == BuyV2CheckoutSubmissionState.idle
                        ? 'Not submitted'
                        : 'Check original payment';
                    final due = group.amountDueNow == 0
                        ? 'No payment due now'
                        : '${buyV2Money(group.amountDueNow)} with ${group.paymentMethod}';
                    final balance = group.total - group.amountDueNow;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '$scope\n$due · $status${balance > 0 ? ' · ${buyV2Money(balance)} due later' : ''}',
                        style: context.buyMeta,
                      ),
                    );
                  },
                ),
            if (session.currentCheckoutPaymentGroup?.state ==
                BuyV2CheckoutSubmissionState.idle)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: BuyV2ActionStyle.primaryForeground,
                  minimumSize: const Size(64, 44),
                  textStyle: context.buyBody.copyWith(fontFamily: 'Inter'),
                ),
                onPressed: session.checkoutBusy
                    ? null
                    : session.reviewRemainingGroupedCheckout,
                child: const Text('Review remaining checkout'),
              ),
            if (count > 1)
              Text(
                'Each payment covers its listed group. Completed orders are kept if another payment fails.',
                style: context.buyMeta,
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutPaymentStateRow extends StatelessWidget {
  const _CheckoutPaymentStateRow({
    required this.session,
    required this.hasPaymentHandoff,
  });

  final BuyV2Session session;
  final bool hasPaymentHandoff;

  @override
  Widget build(BuildContext context) {
    final state = session.checkoutSubmissionState;
    final handoffUnavailable =
        state == BuyV2CheckoutSubmissionState.paymentActionRequired &&
        session.paymentActionUri != null &&
        !hasPaymentHandoff;
    final content = session.checkoutRecoveryBlocked
        ? (
            Icons.help_outline_rounded,
            'Original payment needs checking',
            'Do not pay again. Get order help for this payment.',
          )
        : switch (state) {
            BuyV2CheckoutSubmissionState.submitting => (
              Icons.autorenew_rounded,
              'Checking payment',
              'Please wait. Do not start another payment.',
            ),
            BuyV2CheckoutSubmissionState.paymentActionRequired
                when handoffUnavailable =>
              (
                Icons.cloud_off_outlined,
                'Payment unavailable right now',
                'Check the original payment before choosing again. You can leave safely.',
              ),
            BuyV2CheckoutSubmissionState.paymentActionRequired => (
              Icons.lock_outline_rounded,
              'Ready for secure payment',
              session.checkoutRecoveryAmountKnown
                  ? 'Pay ${buyV2Money(session.checkoutPaymentActionAmount)} to MoolSocial with ${session.checkoutCommittedPaymentMethod}.'
                  : 'The original amount needs checking. Do not pay again.',
            ),
            BuyV2CheckoutSubmissionState.paymentPending => (
              Icons.schedule_rounded,
              'Payment confirmation pending',
              'Do not pay again. Check the same payment for an update.',
            ),
            BuyV2CheckoutSubmissionState.paymentUnknown => (
              Icons.help_outline_rounded,
              'Payment status needs checking',
              'Do not pay again until this payment has been checked.',
            ),
            BuyV2CheckoutSubmissionState.cancelled => (
              Icons.cancel_outlined,
              'Payment cancelled',
              session.checkoutHasGroupedCommitment
                  ? 'Completed groups are kept. Check this original payment before choosing again.'
                  : session.checkoutRequiresResolution
                  ? 'Check the original payment before choosing again. Your Cart is retained.'
                  : 'No order was placed. Your Cart is unchanged.',
            ),
            BuyV2CheckoutSubmissionState.failed => (
              Icons.error_outline_rounded,
              'Payment not completed',
              session.checkoutHasGroupedCommitment
                  ? 'Completed groups are kept. Check this original payment before choosing again.'
                  : session.checkoutRequiresResolution
                  ? 'Check the original payment before choosing again. Your Cart is retained.'
                  : 'No order was placed. Your Cart is unchanged.',
            ),
            BuyV2CheckoutSubmissionState.unavailable => (
              Icons.cloud_off_outlined,
              'Payment unavailable right now',
              'No order was placed. Try again shortly.',
            ),
            BuyV2CheckoutSubmissionState.idle ||
            BuyV2CheckoutSubmissionState.confirmed => (
              Icons.check_circle_outline_rounded,
              '',
              '',
            ),
          };
    final attention =
        handoffUnavailable ||
        state == BuyV2CheckoutSubmissionState.paymentPending ||
        state == BuyV2CheckoutSubmissionState.paymentUnknown ||
        state == BuyV2CheckoutSubmissionState.failed ||
        state == BuyV2CheckoutSubmissionState.unavailable;
    final actionLabel = switch (state) {
      BuyV2CheckoutSubmissionState.paymentActionRequired => 'Leave payment',
      BuyV2CheckoutSubmissionState.paymentPending => 'Not shown?',
      _ => null,
    };
    final actionStyle = Theme.of(context).textTheme.labelLarge!;
    final actionWidth = actionLabel == null
        ? 0.0
        : (buyV2ValueTextSize(context, actionLabel, actionStyle).width + 32)
              .clamp(76.0, double.infinity)
              .toDouble();
    final minimumTextWidth =
        [
          for (final word in content.$2.split(RegExp(r'\s+')))
            buyV2ValueTextSize(context, word, context.buyBody).width,
          for (final word in content.$3.split(RegExp(r'\s+')))
            buyV2ValueTextSize(context, word, context.buyMeta).width,
        ].fold<double>(
          0,
          (width, wordWidth) => wordWidth > width ? wordWidth : width,
        );
    final action = actionLabel == null
        ? null
        : TextButton(
            key: ValueKey(
              state == BuyV2CheckoutSubmissionState.paymentActionRequired
                  ? 'buy-checkout-cancel-payment'
                  : 'buy-checkout-payment-not-shown',
            ),
            onPressed:
                state == BuyV2CheckoutSubmissionState.paymentActionRequired
                ? session.cancelPaymentAttempt
                : session.markPaymentStatusNeedsChecking,
            style: TextButton.styleFrom(minimumSize: const Size(76, 44)),
            child: Text(actionLabel),
          );
    return Semantics(
      key: ValueKey('buy-checkout-payment-state-${state.name}'),
      container: true,
      liveRegion: true,
      label: '${content.$2}. ${content.$3}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: buyV2CardDecoration(
          color: attention ? BuyV2Colors.softOrange : BuyV2Colors.softBlue,
          border: attention ? BuyV2Colors.orange : BuyV2Colors.navy,
          radius: 13,
        ),
        child: _BuyDecisionLayout(
          minimumBodyWidth: minimumTextWidth + 28,
          action: action,
          actionWidth: actionWidth,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state == BuyV2CheckoutSubmissionState.submitting)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                Icon(content.$1, color: BuyV2Colors.muted, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content.$2, style: context.buyBody),
                    Text(content.$3, style: context.buyMeta),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PO approval uses the existing checkout surface; it is not a payment method.
class BuyV2PurchaseOrderPanel extends StatelessWidget {
  const BuyV2PurchaseOrderPanel({
    super.key,
    required this.session,
    this.compact = true,
  });
  final BuyV2Session session;
  final bool compact;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) {
      if (!session.purchaseOrderRequired) return const SizedBox.shrink();
      if (session.checkoutRequiresResolution) return const SizedBox.shrink();
      if (compact) {
        return _CheckoutCard(
          key: const ValueKey('buy-checkout-order-agreement'),
          icon: Icons.receipt_long_outlined,
          title: 'Order approval',
          detail: session.purchaseOrderReviewRequired
              ? 'Review this order’s amount and payment schedule.'
              : 'Approved for this order.',
          action: 'Review',
          onTap: session.checkoutBusy
              ? null
              : () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  useRootNavigator: true,
                  backgroundColor: Colors.white,
                  builder: (context) => SafeArea(
                    top: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .85,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: BuyV2PurchaseOrderPanel(
                          session: session,
                          compact: false,
                        ),
                      ),
                    ),
                  ),
                ),
        );
      }
      final controller = session.purchaseOrder;
      final review = controller?.review;
      final busy = controller?.busy ?? false;
      final address = session.collectionCheckoutSelected
          ? null
          : session.selectedAddressOrNull;
      final store = session.collectionCheckoutSelected
          ? session.collectionCheckoutStore
          : null;
      final current =
          controller != null &&
          (address != null || store != null) &&
          controller.currentFor(
            session.purchaseOrderLines,
            address,
            collectionStore: store,
          );
      return Container(
        key: const ValueKey('buy-purchase-order-panel'),
        padding: const EdgeInsets.all(12),
        decoration: buyV2CardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Order agreement', style: context.buyBody),
            Text(
              'Review the amount and payment schedule for this order.',
              style: context.buyMeta,
            ),
            if (controller == null || controller.identity.value == null)
              Text(
                'Order approval is unavailable right now.',
                style: context.buyMeta,
              ),
            if (review != null) ...[
              Text('Buyer: ${review.buyerName}', style: context.buyBody),
              for (final doc in review.documents) ...[
                const SizedBox(height: 8),
                Text(doc.supplierName, style: context.buyBody),
                Text(
                  controller!.needsReconciliation
                      ? 'Submission status unconfirmed'
                      : !current
                      ? 'Previous terms · review required'
                      : switch (doc.state) {
                          BuyV2PurchaseOrderState.draft =>
                            'Draft for your approval',
                          BuyV2PurchaseOrderState.awaitingSupplier =>
                            'Awaiting supplier response',
                          BuyV2PurchaseOrderState.accepted =>
                            'Supplier accepted',
                          BuyV2PurchaseOrderState.revised =>
                            'Revised terms need your approval',
                          BuyV2PurchaseOrderState.rejected =>
                            'Supplier could not accept',
                        },
                  style: context.buyMeta,
                ),
                if (doc.reference != null)
                  Text(doc.reference!, style: context.buyMeta),
                if (!current || doc.state == BuyV2PurchaseOrderState.revised)
                  for (final line in doc.lines)
                    Text(
                      '${line.quantity} × ${session.findProduct(line.productId)?.title ?? line.productId} · ${line.pack} · ${_comparisonMoney(line.totalMinor)}',
                      style: context.buyMeta,
                    ),
                Text(
                  'Total ${_comparisonMoney(doc.totalMinor)}',
                  style: context.buyBody,
                ),
                Text(doc.terms, style: context.buyMeta),
                if (doc.decisionMessage != null)
                  Text(doc.decisionMessage!, style: context.buyMeta),
                if (doc.state == BuyV2PurchaseOrderState.revised)
                  TextButton(
                    key: ValueKey('buy-po-approve-${doc.id}'),
                    onPressed:
                        busy || !current || controller.needsReconciliation
                        ? null
                        : () => session.approvePurchaseOrderRevision(doc.id),
                    child: const Text('Approve revised terms'),
                  ),
              ],
            ],
            if (controller?.message case final message?)
              Text(message, style: context.buyMeta),
            if (busy) const LinearProgressIndicator(minHeight: 2),
            Wrap(
              spacing: 8,
              children: [
                if (review == null)
                  TextButton(
                    key: const ValueKey('buy-po-review'),
                    onPressed:
                        controller == null ||
                            controller.identity.value == null ||
                            busy
                        ? null
                        : session.reviewPurchaseOrder,
                    child: const Text('Check order agreement'),
                  ),
                if (review != null &&
                    review.documents.every(
                      (doc) => doc.state == BuyV2PurchaseOrderState.draft,
                    ))
                  TextButton(
                    key: const ValueKey('buy-po-issue'),
                    onPressed:
                        busy || !current || controller.needsReconciliation
                        ? null
                        : session.issuePurchaseOrder,
                    child: const Text('Confirm this order'),
                  ),
                if (review != null &&
                    (!current ||
                        review.documents.any(
                          (doc) => doc.state != BuyV2PurchaseOrderState.draft,
                        )))
                  TextButton(
                    key: const ValueKey('buy-po-refresh'),
                    onPressed: busy ? null : controller!.refresh,
                    child: const Text('Check status'),
                  ),
                if (review != null && !current)
                  TextButton(
                    key: const ValueKey('buy-po-review-updated'),
                    onPressed: busy || controller!.needsReconciliation
                        ? null
                        : session.reviewPurchaseOrder,
                    child: const Text('Refresh order agreement'),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _CheckoutOrderDetails extends StatelessWidget {
  const _CheckoutOrderDetails({
    super.key,
    required this.session,
    required this.gstInvoiceController,
    required this.invoiceDestinations,
    required this.instructionsKey,
  });

  final BuyV2Session session;
  final BuyV2GstInvoiceController gstInvoiceController;
  final List<BuyV2Destination> invoiceDestinations;
  final GlobalKey<_CheckoutDeliveryInstructionsState> instructionsKey;

  @override
  Widget build(BuildContext context) {
    if (session.collectionCheckoutSelected) return const SizedBox.shrink();
    final groups = session.checkoutRecoveryAmountKnown
        ? session.checkoutFulfilmentGroups
        : const <BuyV2FulfilmentGroup>[];
    final selectedBenefits = session.selectedCartBenefitsFor(
      session.checkoutDestinations,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (session.purchaseOrderRequired) ...[
          BuyV2PurchaseOrderPanel(session: session),
          const SizedBox(height: 8),
        ],
        if (session.checkoutDeliveryEstimateReviewRequired &&
            !session.checkoutRequiresResolution)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery could not be confirmed. Check again, change the address or edit your basket.',
                  style: context.buyBody,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      key: const ValueKey('buy-delivery-unavailable-address'),
                      onPressed: () => _showAddAddressSheet(
                        context,
                        session,
                        existingAddress: session.selectedAddressOrNull,
                      ),
                      child: const Text('Change address or collection'),
                    ),
                    TextButton(
                      key: const ValueKey('buy-delivery-unavailable-cart'),
                      onPressed: () {
                        session.rememberCartScrollOffset(session.cartScope, 0);
                        session.openCart(scope: session.cartScope);
                      },
                      child: const Text('Edit basket'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        BuyV2CheckoutGstDetails(
          destinations: invoiceDestinations,
          controller: gstInvoiceController,
        ),
        const SizedBox(height: 8),
        if (session.checkoutQuoteEnabled ||
            session.checkoutRequiresResolution) ...[
          _CheckoutQuoteCard(session: session),
          const SizedBox(height: 8),
        ],
        if (session.commercialPaymentTermsEnabled &&
            !session.checkoutRequiresResolution) ...[
          _CheckoutCommercialPaymentTerms(session: session),
          const SizedBox(height: 8),
        ],
        _CheckoutDeliveryInstructions(key: instructionsKey, session: session),
        const SizedBox(height: 8),
        if (session.checkoutBenefitReviewRequired &&
            !session.checkoutRequiresResolution) ...[
          _CartBenefitEligibilityState(session: session),
          const SizedBox(height: 8),
        ],
        if (session.checkoutPriceReviewRequired &&
            !session.checkoutRequiresResolution) ...[
          _CheckoutPriceChangeReview(session: session),
          const SizedBox(height: 8),
        ],
        if (session.checkoutPromiseReviewRequired &&
            !session.checkoutRequiresResolution) ...[
          _CheckoutPromiseChangeReview(session: session),
          const SizedBox(height: 8),
        ],
        Text('Order items', style: context.buyBody),
        const SizedBox(height: 7),
        for (var index = 0; index < groups.length; index++) ...[
          _CheckoutDeliverySummaryCard(
            key: ValueKey('buy-checkout-confirm-delivery-${groups[index].key}'),
            group: groups[index],
            artwork: buyV2DeliveryArtworkForLines(
              groups[index].lines,
              fulfilmentModeFor: session.fulfilmentModeFor,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (selectedBenefits.isNotEmpty &&
            !session.checkoutRequiresResolution) ...[
          const SizedBox(height: 8),
          Container(
            key: const ValueKey('buy-checkout-confirm-benefits'),
            padding: const EdgeInsets.all(12),
            decoration: buyV2CardDecoration(radius: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Coupons and payment offers', style: context.buyBody),
                for (final benefit in selectedBenefits) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${benefit.title} · ${_cartBenefitSponsorLabel(benefit)}',
                    style: context.buyBody,
                  ),
                  Text(
                    benefit.kind == BuyV2CartBenefitKind.paymentOffer
                        ? _paymentOfferStatus(session, benefit)
                        : 'Coupon saving −${buyV2Money(session.couponSavingForDestination(benefit.destination))} included in this total.',
                    style: context.buyMeta,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CheckoutDeliveryInstructions extends StatefulWidget {
  const _CheckoutDeliveryInstructions({super.key, required this.session});

  final BuyV2Session session;

  @override
  State<_CheckoutDeliveryInstructions> createState() =>
      _CheckoutDeliveryInstructionsState();
}

class _CheckoutDeliveryInstructionsState
    extends State<_CheckoutDeliveryInstructions> {
  final _instructionStorage = PageStorageBucket();
  final _expansion = ExpansibleController();
  final _editorKey = GlobalKey<_CartDeliveryInstructionCardState>();
  BuyV2Session get session => widget.session;

  void openEditor() {
    if (session.checkoutBusy || session.checkoutRequiresResolution) return;
    _expansion.expand();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editorKey.currentState?.openEditor(focus: true);
    });
  }

  @override
  void dispose() {
    _expansion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinations = session.checkoutDestinations;
    final saved = [
      if (!session.isStoreProcurement) ?session.publicDeliveryInstruction,
      if (session.isStoreProcurement)
        for (final destination in destinations)
          if (session.deliveryInstructionTextFor(destination) case final note?)
            '${_cartDestinationLabel(session, destination)} · $note',
    ];
    final locked = session.checkoutBusy || session.checkoutRequiresResolution;
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        key: const PageStorageKey('buy-checkout-instructions'),
        controller: _expansion,
        maintainState: true,
        initiallyExpanded: session.publicDeliveryInstructionReviewRequired,
        enabled: !locked,
        expansionAnimationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : null,
        tilePadding: EdgeInsets.zero,
        title: Text('Delivery instructions · optional', style: context.buyBody),
        subtitle: session.publicDeliveryInstructionReviewRequired
            ? Text('Review your previous instructions', style: context.buyMeta)
            : saved.isEmpty
            ? null
            : Text(saved.join('\n'), style: context.buyMeta),
        children: [
          PageStorage(
            bucket: _instructionStorage,
            child: IgnorePointer(
              ignoring: locked,
              child: _CartDeliveryInstructionSections(
                session: session,
                destinations: destinations.toList(growable: false),
                showHeading: false,
                publicEditorKey: _editorKey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutPrimaryActionBar extends StatelessWidget {
  const _CheckoutPrimaryActionBar({
    required this.session,
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final BuyV2Session session;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('buy-checkout-action-bar'),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: BuyV2Colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final countText = _checkoutDockCountLabel(session);
              final countStyle = context.buyMeta.copyWith(fontSize: 8);
              final amountText = session.collectionCheckoutSelected
                  ? _collectionCheckoutAmount(session)
                  : session.checkoutRecoveryAmountKnown
                  ? buyV2Money(session.checkoutPaymentActionAmount)
                  : 'Amount needs checking';
              const amountStyle = TextStyle(
                color: BuyV2Colors.ink,
                fontSize: 19,
                height: 1,
                fontWeight: FontWeight.w900,
              );
              final actionStyle =
                  (Theme.of(context).textTheme.labelLarge ??
                          const TextStyle(fontSize: 14))
                      .merge(
                        FilledButtonTheme.of(
                          context,
                        ).style?.textStyle?.resolve(const <WidgetState>{}),
                      );
              final countWidth = buyV2ValueTextSize(
                context,
                countText,
                countStyle,
              ).width;
              final amountWidth = buyV2ValueTextSize(
                context,
                amountText,
                amountStyle,
              ).width;
              final labelWidth = buyV2ValueTextSize(
                context,
                label,
                actionStyle,
              ).width;
              // Include the Ink surface's one-pixel border on both sides.
              final actionWidth = (labelWidth + 26).clamp(
                164.0.clamp(0.0, constraints.maxWidth),
                constraints.maxWidth,
              );
              final summaryWidth = amountWidth > countWidth
                  ? amountWidth
                  : countWidth;
              final stacked =
                  summaryWidth + 10 + actionWidth > constraints.maxWidth;
              final count = Text(countText, style: countStyle);
              final amount = Text(
                amountText,
                key: session.isStoreProcurement
                    ? null
                    : const ValueKey('buy-checkout-amount-due-now'),
                style: amountStyle,
              );
              final summary =
                  stacked &&
                      countWidth + 10 + amountWidth <= constraints.maxWidth
                  ? Row(
                      children: [
                        Expanded(child: count),
                        const SizedBox(width: 10),
                        amount,
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [count, amount],
                    );
              final action = Align(
                widthFactor: 1,
                heightFactor: 1,
                child: FilledButton(
                  key: ValueKey(
                    'buy-checkout-primary-${session.checkoutStep.name}',
                  ),
                  style:
                      BuyV2ActionStyle.button(
                        FilledButton.styleFrom(
                          textStyle: actionStyle,
                          minimumSize: const Size(0, BuyV2Metrics.minimumTap),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ).copyWith(
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.disabled)
                              ? BuyV2Colors.muted
                              : BuyV2Colors.navy,
                        ),
                        iconColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.disabled)
                              ? BuyV2Colors.muted
                              : BuyV2Colors.navy,
                        ),
                      ),
                  onPressed: onPressed,
                  child: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            color: BuyV2Colors.navy,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Text(label, textAlign: TextAlign.center),
                ),
              );
              return stacked
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [summary, const SizedBox(height: 7), action],
                    )
                  : Row(
                      children: [
                        Expanded(child: summary),
                        const SizedBox(width: 10),
                        SizedBox(width: actionWidth, child: action),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _WholesaleCheckoutReceivingLines extends StatelessWidget {
  const _WholesaleCheckoutReceivingLines({required this.group});

  final BuyV2FulfilmentGroup group;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey('buy-wholesale-checkout-receiving-lines-${group.key}'),
      container: true,
      explicitChildNodes: true,
      label:
          'Products in this Wholesale delivery. '
          '${_productCountLabel(group.lines.length)}. '
          '${_packCountLabel(group.itemCount)}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < group.lines.length; index++) ...[
            _WholesaleCheckoutReceivingLine(line: group.lines[index]),
            if (index != group.lines.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Divider(height: 1, color: BuyV2Colors.line),
              ),
          ],
        ],
      ),
    );
  }
}

class _WholesaleCheckoutReceivingLine extends StatelessWidget {
  const _WholesaleCheckoutReceivingLine({required this.line});

  final BuyV2CartLine line;

  @override
  Widget build(BuildContext context) {
    final product = line.product;
    final quantityLabel = _packCountLabel(line.quantity);
    final semanticLabel =
        '${product.customerTitle}. $quantityLabel. ${product.pack}. '
        'Minimum order ${_packCountLabel(product.minimumOrder)}. '
        '${buyV2Money(product.price)} per pack. ${product.unitPrice}. '
        'Item total ${buyV2Money(line.total)}.';
    return Semantics(
      key: ValueKey('buy-wholesale-checkout-receiving-line-${product.id}'),
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 290 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.2;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product.customerTitle, style: context.buyBody),
              const SizedBox(height: 2),
              Text(
                '$quantityLabel · ${product.pack}',
                style: context.buyMeta.copyWith(
                  color: BuyV2Colors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Minimum order ${product.minimumOrder} packs · '
                '${buyV2Money(product.price)} per pack · ${product.unitPrice}',
                style: context.buyMeta,
              ),
            ],
          );
          final subtotal = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: stacked
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Item total', style: context.buyMeta),
                  const SizedBox(height: 2),
                  Text(
                    buyV2Money(line.total),
                    style: context.buyBody.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          );
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 6), subtotal],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: details),
              const SizedBox(width: 10),
              subtotal,
            ],
          );
        },
      ),
    );
  }
}

class _CheckoutPriceChangeReview extends StatelessWidget {
  const _CheckoutPriceChangeReview({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final changes = session.checkoutPriceChanges;
    return Semantics(
      key: const ValueKey('buy-checkout-price-change-review'),
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: buyV2CardDecoration(
          color: BuyV2Colors.softOrange,
          border: BuyV2Colors.orange,
          radius: 15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prices changed',
              style: context.buyTitle.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 3),
            Text(
              'Review the updated prices and total before placing this order.',
              style: context.buyMeta,
            ),
            const SizedBox(height: 8),
            for (final change in changes) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      change.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.buyBody,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${buyV2Money(change.previousPrice)} → '
                    '${buyV2Money(change.currentPrice)}',
                    style: context.buyMeta.copyWith(
                      color: BuyV2Colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            SizedBox(
              width: double.infinity,
              height: BuyV2Metrics.minimumTap,
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: FilledButton(
                  style: BuyV2ActionStyle.button(),
                  key: const ValueKey('buy-checkout-accept-prices'),
                  onPressed: session.acceptCheckoutPriceChanges,
                  child: const Text('Accept updated prices'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutPromiseChangeReview extends StatelessWidget {
  const _CheckoutPromiseChangeReview({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final changes = session.checkoutDeliveryPromiseChanges;
    return Container(
      key: const ValueKey('buy-checkout-promise-change-review'),
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(
        color: BuyV2Colors.softOrange,
        border: const Color(0x44FF9933),
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery times changed',
            style: context.buyTitle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 3),
          Text(
            'Nothing has been placed. Review the new promises before continuing.',
            style: context.buyMeta,
          ),
          for (final change in changes) ...[
            const SizedBox(height: 8),
            Text(
              'Previous · ${buyV2DeliveryPromiseSummary(promise: change.previousPromise, promisedByLabel: change.previousPromisedByLabel)}',
              style: context.buyMeta,
            ),
            const SizedBox(height: 2),
            Text(
              'Updated · ${buyV2DeliveryPromiseSummary(promise: change.currentPromise, promisedByLabel: change.currentPromisedByLabel)}',
              style: context.buyBody,
            ),
          ],
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: FilledButton(
                style: BuyV2ActionStyle.button(),
                key: const ValueKey('buy-accept-updated-delivery-times'),
                onPressed: session.acceptCheckoutPromiseChanges,
                child: const Text('Accept updated times'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BuyV2ConfirmationView extends StatelessWidget {
  const BuyV2ConfirmationView({
    super.key,
    required this.session,
    this.invoiceDownloader,
  });

  final BuyV2Session session;
  final BuyV2InvoiceDownloader? invoiceDownloader;

  @override
  Widget build(BuildContext context) {
    final purchaseId = session.confirmedPurchaseId;
    final orders = session.confirmedOrders;
    final hasConfirmedPurchase =
        session.checkoutSubmissionState ==
            BuyV2CheckoutSubmissionState.confirmed &&
        purchaseId != null &&
        purchaseId.trim().isNotEmpty &&
        session.confirmedProductCount > 0 &&
        orders.isNotEmpty &&
        orders.every(
          (order) =>
              order.id.trim().isNotEmpty && order.purchaseId == purchaseId,
        );
    if (!hasConfirmedPurchase) {
      return ListView(
        key: const ValueKey('buy-confirmation'),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: BuyV2Colors.navy,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text('Order confirmation unavailable', style: context.buyTitle),
          const SizedBox(height: 8),
          Text(
            'This link does not confirm an order. Check Orders for an existing purchase before trying again.',
            style: context.buyBody,
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BuyV2Metrics.minimumTap,
            ),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: FilledButton(
                style: BuyV2ActionStyle.button(),
                key: const ValueKey('buy-confirmation-view-orders'),
                onPressed: session.openOrders,
                child: const Text('View orders'),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            key: const ValueKey('buy-confirmation-continue-shopping'),
            onPressed: () => session.openDestination(BuyV2Destination.shop),
            child: const Text('Continue shopping'),
          ),
        ],
      );
    }
    final deliveryAddresses = orders.map((order) {
      final recipient = order.recipient?.trim();
      final address = order.addressLine?.trim();
      return recipient == null ||
              recipient.isEmpty ||
              address == null ||
              address.isEmpty
          ? null
          : '$recipient · $address';
    }).toSet();
    final deliveryAddressLabel = deliveryAddresses.contains(null)
        ? 'Delivery address unavailable'
        : deliveryAddresses.length == 1
        ? 'Delivering to ${deliveryAddresses.single}'
        : 'View order details for each delivery address';
    return ListView(
      key: const ValueKey('buy-confirmation'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        Container(
          key: const ValueKey('buy-confirmation-success'),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: buyV2CardDecoration(
            color: BuyV2Colors.softGreen,
            border: const Color(0x33138808),
            radius: 18,
          ),
          child: Column(
            children: [
              _OrderPlacedSuccessMark(
                key: ValueKey(
                  'buy-order-success-${session.confirmedPurchaseId}',
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Order placed',
                style: context.buyTitle.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 3),
              Text(
                '${_productCountLabel(session.confirmedProductCount)} · ${buyV2Money(session.confirmedTotal)}',
                style: context.buyBody,
              ),
              if (session.confirmedBalanceDue > 0) ...[
                const SizedBox(height: 3),
                Text(
                  'Paid now ${buyV2Money(session.confirmedAmountPaidNow)} · '
                  'Balance ${buyV2Money(session.confirmedBalanceDue)}',
                  key: const ValueKey('buy-confirmation-payment-schedule'),
                  style: context.buyMeta.copyWith(
                    color: BuyV2Colors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (session.confirmedPurchaseId case final purchaseId?) ...[
                const SizedBox(height: 2),
                Text(
                  'Order reference · $purchaseId',
                  style: context.buyMeta.copyWith(fontSize: 8.5),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                deliveryAddressLabel,
                textAlign: TextAlign.center,
                style: context.buyMeta,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            'Your deliveries',
            style: context.buyTitle.copyWith(fontSize: 16),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          session.confirmedOrders.length == 1
              ? 'Your delivery has its own status and order details.'
              : 'This purchase is split into ${session.confirmedOrders.length} deliveries, each with its own status.',
          style: context.buyMeta.copyWith(fontSize: 8.5),
        ),
        const SizedBox(height: 7),
        for (final (index, order) in session.confirmedOrders.indexed) ...[
          _PlacedOrderCard(
            order: order,
            deliveryIndex: index,
            deliveryCount: session.confirmedOrders.length,
            onViewInvoice: () => _openOrderInvoice(
              context,
              session: session,
              order: order,
              downloader: invoiceDownloader,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: BuyV2Metrics.minimumTap,
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: FilledButton(
              style: BuyV2ActionStyle.button(),
              key: const ValueKey('buy-confirmation-order-details'),
              onPressed: () {
                if (session.confirmedOrders.length == 1) {
                  session.openTracking(session.confirmedOrders.single.id);
                } else {
                  session.openOrders();
                }
              },
              child: const Text('View order details'),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          key: const ValueKey('buy-confirmation-continue-shopping'),
          onPressed: () => session.openDestination(
            session.isStoreProcurement
                ? BuyV2Destination.wholesale
                : BuyV2Destination.shop,
          ),
          child: Text(
            session.isStoreProcurement
                ? 'Continue restocking'
                : 'Continue shopping',
          ),
        ),
      ],
    );
  }
}

class _PlacedOrderCard extends StatelessWidget {
  const _PlacedOrderCard({
    required this.order,
    required this.deliveryIndex,
    required this.deliveryCount,
    required this.onViewInvoice,
  });

  final BuyV2Order order;
  final int deliveryIndex;
  final int deliveryCount;
  final VoidCallback onViewInvoice;

  @override
  Widget build(BuildContext context) {
    final icon = switch (order.destination) {
      BuyV2Destination.shop => Icons.shopping_bag_outlined,
      BuyV2Destination.wholesale => Icons.inventory_2_outlined,
      BuyV2Destination.medicine => Icons.medication_outlined,
      BuyV2Destination.orders => Icons.receipt_long_outlined,
    };
    return Container(
      key: ValueKey('buy-placed-order-${order.id}'),
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: order.destination == BuyV2Destination.wholesale
                      ? BuyV2Colors.softBlue
                      : BuyV2Colors.softOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: BuyV2Colors.navy, size: 21),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery ${deliveryIndex + 1} of $deliveryCount',
                      style: context.buyBody.copyWith(fontSize: 12),
                    ),
                    Text(
                      '${order.destination.label} · ${order.id}',
                      style: context.buyMeta.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ),
              Text(
                _buyV2OrderMoney(order),
                style: const TextStyle(
                  color: BuyV2Colors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: BuyV2Colors.canvas,
              borderRadius: BorderRadius.circular(11),
            ),
            child: order.lines.isEmpty
                ? Text(order.itemSummary, style: context.buyBody)
                : Column(
                    children: [
                      for (var index = 0; index < order.lines.length; index++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index == order.lines.length - 1 ? 0 : 6,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 25,
                                child: Text(
                                  '${order.lines[index].quantity}×',
                                  style: context.buyMeta.copyWith(
                                    color: BuyV2Colors.navy,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  order.lines[index].product.customerTitle,
                                  style: context.buyBody.copyWith(
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                buyV2Money(order.lines[index].total),
                                style: context.buyBody.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 7),
          Text(
            '${order.customerPartner} · ${order.partnerType}',
            style: context.buyMeta.copyWith(fontSize: 8.5),
          ),
          const SizedBox(height: 2),
          Text(
            'Timing · ${_orderPromiseSummary(order)}',
            style: context.buyBody.copyWith(fontSize: 10),
          ),
          if (order.updatedDeliveryEstimate case final estimate?) ...[
            const SizedBox(height: 2),
            Text(
              'Delayed · new estimate $estimate',
              style: context.buyMeta.copyWith(
                color: BuyV2Colors.orange,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (order.deliveryInstruction case final instruction?) ...[
            const SizedBox(height: 2),
            Text(
              '${_deliveryInstructionOwner(order.destination)} · $instruction',
              style: context.buyMeta.copyWith(fontSize: 8.5),
            ),
          ],
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: ValueKey('buy-confirmation-invoice-${order.id}'),
              onPressed: onViewInvoice,
              style: TextButton.styleFrom(minimumSize: const Size(112, 44)),
              icon: const Icon(Icons.receipt_long_outlined, size: 17),
              label: const Text('View invoice'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderPlacedSuccessMark extends StatefulWidget {
  const _OrderPlacedSuccessMark({super.key});

  @override
  State<_OrderPlacedSuccessMark> createState() =>
      _OrderPlacedSuccessMarkState();
}

class _OrderPlacedSuccessMarkState extends State<_OrderPlacedSuccessMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: .86,
          end: 1.07,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.07,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 28,
      ),
    ]).animate(_controller);
    return Semantics(
      label: 'Order placed successfully',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Transform.scale(
            scale: scale.value,
            child: CustomPaint(
              painter: _OrderPlacedSuccessPainter(_controller.value),
              size: const Size.square(36),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderPlacedSuccessPainter extends CustomPainter {
  const _OrderPlacedSuccessPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 3;
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    final ringProgress = (progress / .46).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * ringProgress,
      false,
      Paint()
        ..color = BuyV2Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final tickProgress = ((progress - .28) / .42).clamp(0.0, 1.0);
    if (tickProgress <= 0) return;
    final start = Offset(size.width * .28, size.height * .52);
    final middle = Offset(size.width * .44, size.height * .67);
    final end = Offset(size.width * .73, size.height * .36);
    final path = Path()..moveTo(start.dx, start.dy);
    if (tickProgress < .45) {
      final local = tickProgress / .45;
      path.lineTo(
        start.dx + (middle.dx - start.dx) * local,
        start.dy + (middle.dy - start.dy) * local,
      );
    } else {
      path.lineTo(middle.dx, middle.dy);
      final local = (tickProgress - .45) / .55;
      path.lineTo(
        middle.dx + (end.dx - middle.dx) * local,
        middle.dy + (end.dy - middle.dy) * local,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = BuyV2Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _OrderPlacedSuccessPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class BuyV2RecoveryView extends StatelessWidget {
  const BuyV2RecoveryView({
    super.key,
    required this.session,
    required this.onOpenOrderHelp,
  });

  final BuyV2Session session;
  final ValueChanged<BuyV2Order> onOpenOrderHelp;

  @override
  Widget build(BuildContext context) {
    final kind = session.recoveryKind ?? BuyV2RecoveryKind.networkInterruption;
    final availabilityIssue = session.checkoutAvailabilityIssue;
    final resolvesCartProduct =
        kind == BuyV2RecoveryKind.stockUnavailable && availabilityIssue != null;
    final resolvesAddress =
        kind == BuyV2RecoveryKind.serviceAreaUnavailable &&
        session.canResolveCheckoutAddress;
    final content = switch (kind) {
      BuyV2RecoveryKind.priceUpdate => (
        Icons.price_change_outlined,
        'Price needs review',
        'Return to where you were and review the current price before continuing. No order has been changed.',
      ),
      BuyV2RecoveryKind.stockUnavailable => (
        Icons.inventory_2_outlined,
        'Availability needs review',
        'Return to where you were to review current availability. No replacement has been selected.',
      ),
      BuyV2RecoveryKind.serviceAreaUnavailable => (
        Icons.location_off_outlined,
        'Delivery availability needs review',
        'Return to review the address and product. No address or product has been changed.',
      ),
      BuyV2RecoveryKind.paymentFailed => (
        Icons.payment_outlined,
        'Payment status needs review',
        'This screen cannot confirm whether money was debited. Check your payment and order status before trying again.',
      ),
      BuyV2RecoveryKind.networkInterruption => (
        Icons.wifi_off_rounded,
        'Connection interrupted',
        'Reconnect, then return to where you were and confirm the latest details before continuing.',
      ),
      BuyV2RecoveryKind.deliveryDelay => (
        Icons.schedule_rounded,
        'Delivery update needs review',
        'Return to the exact order to review tracking. No new delivery commitment is confirmed here.',
      ),
    };
    return ListView(
      key: ValueKey('buy-recovery-${kind.name}'),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 116),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: buyV2CardDecoration(radius: 22),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: BuyV2Colors.softOrange,
                  shape: BoxShape.circle,
                ),
                child: Icon(content.$1, color: BuyV2Colors.navy, size: 29),
              ),
              const SizedBox(height: 12),
              Text(
                content.$2,
                textAlign: TextAlign.center,
                style: context.buyTitle.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 7),
              Text(
                content.$3,
                textAlign: TextAlign.center,
                style: context.buyBody,
              ),
              if (resolvesCartProduct) ...[
                const SizedBox(height: 12),
                Container(
                  key: const ValueKey('buy-recovery-affected-product'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: buyV2CardDecoration(
                    color: BuyV2Colors.softOrange,
                    radius: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(availabilityIssue.title, style: context.buyBody),
                      const SizedBox(height: 2),
                      Text(
                        availabilityIssue.orderabilityLabel,
                        style: context.buyMeta,
                      ),
                    ],
                  ),
                ),
              ],
              if (resolvesAddress) ...[
                const SizedBox(height: 12),
                Container(
                  key: const ValueKey('buy-recovery-affected-address'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: buyV2CardDecoration(
                    color: BuyV2Colors.softBlue,
                    radius: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.selectedAddress.label,
                        style: context.buyBody,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.selectedAddress.shortLine,
                        style: context.buyMeta,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (resolvesCartProduct) ...[
                SizedBox(
                  width: double.infinity,
                  child: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: FilledButton.icon(
                      style: BuyV2ActionStyle.button(),
                      key: const ValueKey('buy-recovery-retry-availability'),
                      onPressed: session.retryCheckoutAvailability,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry availability'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: OutlinedButton(
                      style: BuyV2ActionStyle.button(),
                      key: const ValueKey('buy-recovery-remove-product'),
                      onPressed: session.removeCheckoutIssueProduct,
                      child: const Text('Remove from Cart'),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  key: const ValueKey('buy-recovery-view-product'),
                  onPressed: session.openCheckoutIssueProduct,
                  child: const Text('View product'),
                ),
                TextButton(
                  key: const ValueKey('buy-recovery-return-checkout'),
                  onPressed: session.retryRecovery,
                  child: Text(session.recoveryReturnLabel),
                ),
              ] else if (resolvesAddress) ...[
                SizedBox(
                  width: double.infinity,
                  child: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: FilledButton.icon(
                      style: BuyV2ActionStyle.button(),
                      key: const ValueKey('buy-recovery-change-address'),
                      onPressed: () {
                        session.retryRecovery();
                        showBuyV2AddressSheet(context, session);
                      },
                      icon: const Icon(Icons.location_on_outlined),
                      label: const Text('Change address'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: OutlinedButton(
                      style: BuyV2ActionStyle.button(),
                      key: const ValueKey('buy-recovery-return-checkout'),
                      onPressed: session.retryRecovery,
                      child: Text(session.recoveryReturnLabel),
                    ),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: FilledButton(
                      style: BuyV2ActionStyle.button(),
                      key: const ValueKey('buy-recovery-primary'),
                      onPressed: session.retryRecovery,
                      child: Text(session.recoveryReturnLabel),
                    ),
                  ),
                ),
              if (session.canOpenRecoveryOrderHelp) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: OutlinedButton(
                      style: BuyV2ActionStyle.button(),
                      onPressed: () {
                        if (session.openRecoveryOrderHelp()) {
                          onOpenOrderHelp(session.selectedOrder);
                        }
                      },
                      child: const Text('Get help'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String buyV2OrderRowKey({
  required int groupIndex,
  required String? purchaseId,
  required int orderIndex,
  required String orderId,
}) =>
    'buy-order-row-${purchaseId ?? 'ungrouped-$groupIndex'}-'
    '$orderIndex-$orderId';

String _buyV2PurchaseSummary(BuyV2Session session, List<BuyV2Order> orders) {
  final collections = orders.where((order) => order.collection != null).length;
  if (collections == 0) {
    final count = orders.length;
    final total = orders.fold<int>(0, (sum, order) => sum + order.total);
    return '$count ${count == 1 ? 'delivery' : 'deliveries'} · ${buyV2Money(total)}';
  }
  final count = orders.length;
  final kind = collections == count
      ? (count == 1 ? 'collection' : 'collections')
      : (count == 1 ? 'order' : 'orders');
  var totalMinor = 0;
  for (final order in orders) {
    if (order.collection == null) {
      totalMinor += order.total * 100;
    } else {
      final snapshot = session.collectionSnapshotFor(order.id);
      if (snapshot == null) return '$count $kind · Updating total';
      totalMinor += snapshot.totalMinor;
    }
  }
  return '$count $kind · ${_collectionMoney(totalMinor)}';
}

class BuyV2OrdersView extends StatelessWidget {
  const BuyV2OrdersView({
    super.key,
    required this.session,
    required this.onOpenOrderHelp,
    this.invoiceDownloader,
    this.browseProducts,
  });

  final BuyV2Session session;
  final ValueChanged<BuyV2Order> onOpenOrderHelp;
  final BuyV2InvoiceDownloader? invoiceDownloader;
  final Widget? browseProducts;

  @override
  Widget build(BuildContext context) {
    final visibleOrders = session.visibleOrders;
    final purchaseGroups = _purchaseGroupsFor(visibleOrders);
    return ListView(
      key: const PageStorageKey('buy-orders'),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      children: [
        if (session.canReturnToAccount) ...[
          _ReturnAffordance(
            key: const ValueKey('buy-orders-return-account'),
            label: 'Account',
            onTap: session.returnToAccount,
          ),
          const SizedBox(height: 6),
        ],
        BuyV2CartAvoidanceRegion(
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.fromLTRB(9, 2, 2, 2),
            decoration: buyV2CardDecoration(radius: 15),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PURCHASES',
                        style: context.buyEyebrow.copyWith(fontSize: 7),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Orders',
                            style: context.buyTitle.copyWith(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${session.activeOrderCount} active · '
                              '${session.deliveredOrderCount} delivered',
                              style: context.buyMeta.copyWith(fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        BuyV2CartAvoidanceRegion(
          child: Container(
            key: const ValueKey('buy-orders-tabs'),
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E9F3),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                for (final tab in BuyV2OrdersTab.values)
                  Expanded(
                    child: _OrdersTabButton(
                      tab: tab,
                      selected: session.ordersTab == tab,
                      onTap: () => session.showOrdersTab(tab),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        BuyV2FiniteIncomingTransition(
          stateKey: session.ordersTab,
          child: !session.catalogueAvailable
              ? _OrdersAvailabilityState(session: session)
              : visibleOrders.isEmpty
              ? _OrdersEmptyState(query: session.query, tab: session.ordersTab)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (groupIndex, group)
                        in purchaseGroups.indexed) ...[
                      if (group.purchaseId case final purchaseId?) ...[
                        Container(
                          key: ValueKey('buy-purchase-group-$purchaseId'),
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: buyV2CardDecoration(
                            color: BuyV2Colors.softBlue,
                            radius: 14,
                          ),
                          child: BuyV2CartAvoidanceRegion(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  color: BuyV2Colors.navy,
                                  size: 18,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Purchase $purchaseId',
                                        style: context.buyBody.copyWith(
                                          fontSize: 10.5,
                                        ),
                                      ),
                                      Text(
                                        _buyV2PurchaseSummary(
                                          session,
                                          group.orders,
                                        ),
                                        style: context.buyMeta.copyWith(
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (group.purchaseId case final purchaseId?
                          when session.purchaseRatingTarget(purchaseId) != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: ValueKey('buy-rate-purchase-$purchaseId'),
                            onPressed: () => _showPurchaseRatingSheet(
                              context,
                              session,
                              purchaseId,
                            ),
                            icon: const Icon(
                              Icons.star_outline_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Rate your MoolSocial experience',
                            ),
                          ),
                        ),
                      for (final (orderIndex, order) in group.orders.indexed)
                        Padding(
                          key: ValueKey(
                            buyV2OrderRowKey(
                              groupIndex: groupIndex,
                              purchaseId: group.purchaseId,
                              orderIndex: orderIndex,
                              orderId: order.id,
                            ),
                          ),
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _OrderCard(
                            session: session,
                            order: order,
                            invoiceDownloader: invoiceDownloader,
                          ),
                        ),
                    ],
                  ],
                ),
        ),
        BuyV2SponsoredSlot(
          content: session.sponsoredContentFor(
            BuyV2SponsoredPlacement.ordersAfterHistory,
          ),
        ),
        if (browseProducts case final productGrid?) ...[
          const SizedBox(height: 8),
          BuyV2CartAvoidanceRegion(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Browse more products',
                    style: context.buyTitle.copyWith(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add products now without leaving your purchase history behind.',
                  style: context.buyMeta.copyWith(fontSize: 8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          productGrid,
        ],
        const SizedBox(height: 2),
        _OrdersContinuationRail(session: session),
      ],
    );
  }
}

class _OrdersTabButton extends StatelessWidget {
  const _OrdersTabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final BuyV2OrdersTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = tab == BuyV2OrdersTab.active ? 'Active' : 'Delivered';
    final duration = BuyV2Motion.resolved(context, BuyV2Motion.selection);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label orders',
      child: InkWell(
        key: ValueKey('buy-orders-tab-${tab.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeInOutCubic,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          alignment: Alignment.center,
          decoration: BuyV2ActionStyle.selectionSurface(
            selected: selected,
            radius: 10,
          ),
          child: AnimatedDefaultTextStyle(
            duration: duration,
            curve: Curves.easeInOutCubic,
            style: DefaultTextStyle.of(context).style.copyWith(
              color: selected
                  ? BuyV2ActionStyle.primaryForeground
                  : BuyV2Colors.muted,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
              height: 1.25,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class BuyV2OrderItemsView extends StatelessWidget {
  const BuyV2OrderItemsView({super.key, required this.session});

  final BuyV2Session session;

  String _recordedItemSummary(BuyV2Order order, BuyV2Product product) {
    final lines = order.lines.where((line) => line.product.id == product.id);
    if (lines.isEmpty) {
      return '${product.pack} · Ordered quantity unavailable';
    }
    final quantity = lines.fold<int>(0, (total, line) => total + line.quantity);
    final amount = lines.fold<int>(0, (total, line) => total + line.total);
    return '$quantity × ${product.pack} · ${buyV2Money(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final order = session.selectedOrderOrNull;
    if (order == null) {
      return _MissingOrderSelection(session: session);
    }
    final products = order.lines.isNotEmpty
        ? order.lines.map((line) => line.product).toList(growable: false)
        : session.productsForOrder(order);
    return ListView(
      key: ValueKey('buy-order-items-${order.id}'),
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
      children: [
        _ReturnAffordance(
          label: 'Order ${order.id}',
          onTap: () => session.openTracking(order.id),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: buyV2CardDecoration(
            color: BuyV2Colors.softBlue.withValues(alpha: .65),
            border: const Color(0x26000080),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Items in this order', style: context.buyTitle),
              const SizedBox(height: 3),
              Text(
                '${order.itemSummary} · ${_buyV2OrderMoney(order)}',
                style: context.buyMeta,
              ),
              const SizedBox(height: 5),
              Text(
                '${order.customerPartner} · ${order.partnerType}',
                style: context.buyBody.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (products.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: buyV2CardDecoration(),
            child: Text(
              'Product details are not available for this older order.',
              style: context.buyBody,
            ),
          )
        else
          for (final product in products)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('buy-order-product-${product.id}'),
                  onTap: () => session.openProduct(product.id),
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 104),
                    padding: const EdgeInsets.all(8),
                    decoration: buyV2CardDecoration(radius: 15),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 84,
                          height: 76,
                          child: BuyV2ProductPackshot(product: product),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.brand.trim().isNotEmpty) ...[
                                Text(
                                  product.brand,
                                  style: context.buyEyebrow.copyWith(
                                    fontSize: 8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                product.customerTitle,
                                style: context.buyBody,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _recordedItemSummary(order, product),
                                style: context.buyMeta,
                              ),
                              if (_purchaseProtectionLines(product)
                                  case final policyLines
                                  when policyLines.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'After delivery · ${policyLines.join(' · ')}',
                                  key: ValueKey(
                                    'buy-order-item-policy-${product.id}',
                                  ),
                                  style: context.buyMeta.copyWith(
                                    color: BuyV2Colors.green,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'View product details',
                                style: context.buyMeta.copyWith(
                                  color: BuyV2Colors.navy,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: BuyV2Colors.navy,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _OrdersAvailabilityState extends StatelessWidget {
  const _OrdersAvailabilityState({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final loading = session.commerceLoadState == BuyV2CommerceLoadState.loading;
    return Container(
      key: ValueKey('buy-orders-${session.commerceLoadState.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: buyV2CardDecoration(radius: 15),
      child: Column(
        children: [
          if (loading)
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            const Icon(
              Icons.receipt_long_outlined,
              color: BuyV2Colors.navy,
              size: 28,
            ),
          const SizedBox(height: 8),
          Text(
            loading ? 'Opening Orders' : 'Orders could not refresh',
            textAlign: TextAlign.center,
            style: context.buyTitle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 3),
          Text(
            session.commerceMessage ??
                'Try again shortly. Existing order details remain unchanged.',
            textAlign: TextAlign.center,
            style: context.buyMeta,
          ),
          if (!loading) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: BuyV2Metrics.minimumTap,
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: FilledButton.icon(
                  style: BuyV2ActionStyle.button(),
                  key: const ValueKey('buy-orders-retry'),
                  onPressed: session.retryCommerce,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState({required this.query, required this.tab});

  final String query;
  final BuyV2OrdersTab tab;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    return Container(
      key: const ValueKey('buy-orders-empty'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: buyV2CardDecoration(radius: 15),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: BuyV2Colors.muted,
            size: 28,
          ),
          const SizedBox(height: 7),
          Text(
            hasQuery
                ? 'No orders match this search'
                : tab == BuyV2OrdersTab.active
                ? 'No active orders'
                : 'No delivered orders',
            textAlign: TextAlign.center,
            style: context.buyTitle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 3),
          Text(
            hasQuery
                ? 'Try an order ID, seller or product name.'
                : 'Your orders will appear here.',
            textAlign: TextAlign.center,
            style: context.buyMeta,
          ),
        ],
      ),
    );
  }
}

class _OrdersContinuationRail extends StatelessWidget {
  const _OrdersContinuationRail({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final cards = [
      if (!session.isStoreProcurement)
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-orders-shop'),
          title: 'Continue shopping',
          detail: 'Browse retail products in Shop',
          icon: Icons.shopping_bag_outlined,
          sequenceIndex: 0,
          onTap: () => session.openDestination(BuyV2Destination.shop),
        ),
      BuyV2PromotionCard(
        key: const ValueKey('buy-promotion-orders-wholesale'),
        title: 'Restock a business',
        detail: 'Open independent Wholesale discovery',
        icon: Icons.storefront_outlined,
        accent: BuyV2Colors.green,
        sequenceIndex: 1,
        onTap: () => session.openDestination(BuyV2Destination.wholesale),
      ),
    ];
    return SizedBox(
      key: const ValueKey('buy-orders-promotions'),
      height: cards.fold<double>(90, (height, card) {
        final measured = card.requiredHeight(context);
        return measured > height ? measured : height;
      }),
      child: ListView.separated(
        key: const PageStorageKey('buy-orders-continuation-rail'),
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) =>
            BuyV2CartAvoidanceRegion(child: cards[index]),
      ),
    );
  }
}

String _trackingStatusLabel(BuyV2OrderStatus status) => switch (status) {
  BuyV2OrderStatus.preparing => 'Preparing your order',
  BuyV2OrderStatus.confirmed => 'Supplier confirmed',
  BuyV2OrderStatus.dispatched => 'Dispatched',
  BuyV2OrderStatus.arriving => 'Arriving soon',
  BuyV2OrderStatus.delivered => 'Delivered',
};

String _trackingNextStep(BuyV2OrderStatus status) => switch (status) {
  BuyV2OrderStatus.preparing =>
    'Products are being checked and packed. Dispatch follows next.',
  BuyV2OrderStatus.confirmed =>
    'The supplier is preparing dispatch and will share the next update.',
  BuyV2OrderStatus.dispatched =>
    'The delivery partner will update the route and arrival window.',
  BuyV2OrderStatus.arriving =>
    'Keep the receiving phone available for the delivery partner.',
  BuyV2OrderStatus.delivered =>
    'Delivery is complete. Reorder if you need the same products again.',
};

Future<void> _showBuyV2OrderDeliveryContextSheet(
  BuildContext context,
  BuyV2Session session,
  BuyV2Order order,
  ValueChanged<BuyV2Order> onOpenOrderHelp,
) async {
  final destination = session.destination;
  final view = session.view;
  final orderId = order.id;
  final recipient = order.recipient?.trim();
  final addressLine = order.addressLine?.trim();
  final hasFullAddress = addressLine != null && addressLine.isNotEmpty;
  final bottomViewPadding = BuyV2AddressSheetMotion.resolveBottomSafeInset(
    context,
  );

  Future<void> continueAfterReverse(
    BuildContext sheetContext,
    Future<void> Function() continuation,
  ) async {
    HapticFeedback.selectionClick();
    final routeCompleted = ModalRoute.of(sheetContext)?.completed;
    Navigator.of(sheetContext).pop();
    if (routeCompleted != null) await routeCompleted;
    if (!context.mounted ||
        session.destination != destination ||
        session.view != view ||
        session.selectedOrderId != orderId) {
      return;
    }
    await continuation();
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(
      maxWidth: BuyV2AddressSheetMotion.maxWidth,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: BuyV2AddressSheetMotion.resolve(context),
    builder: (sheetContext) => Semantics(
      key: const ValueKey('buy-order-delivery-sheet'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Delivery address for order $orderId',
      child: RepaintBoundary(
        key: const ValueKey('buy-order-delivery-repaint-boundary'),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(sheetContext).height *
                BuyV2AddressSheetMotion.maxHeightFactor,
          ),
          child: ListView(
            key: const ValueKey('buy-order-delivery-list'),
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 18 + bottomViewPadding),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This order’s delivery',
                          key: const ValueKey('buy-order-delivery-title'),
                          style: sheetContext.buyTitle,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${order.destination.label} · $orderId',
                          key: const ValueKey('buy-order-delivery-id'),
                          style: sheetContext.buyMeta,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const ValueKey('buy-order-delivery-close'),
                    tooltip: 'Close order delivery details',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      maximumSize: const Size(44, 44),
                      foregroundColor: BuyV2Colors.navy,
                      backgroundColor: BuyV2Colors.softBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                key: const ValueKey('buy-order-delivery-facts'),
                padding: const EdgeInsets.all(12),
                decoration: buyV2CardDecoration(radius: 16),
                child: Column(
                  children: [
                    _OrderDeliveryFact(
                      icon: Icons.person_outline_rounded,
                      label: 'Recipient',
                      value: recipient != null && recipient.isNotEmpty
                          ? recipient
                          : 'Not available for this order',
                    ),
                    _OrderDeliveryFact(
                      icon: Icons.location_on_outlined,
                      label: 'Delivering to',
                      value: hasFullAddress
                          ? addressLine
                          : order.destinationLabel,
                    ),
                    if (!hasFullAddress)
                      Text(
                        'Full address unavailable for this order.',
                        style: sheetContext.buyMeta,
                      ),
                    _OrderDeliveryFact(
                      icon: Icons.schedule_outlined,
                      label: 'Delivery window',
                      value: buyV2OrderArrivalSummary(session, order),
                    ),
                    _OrderDeliveryFact(
                      icon: Icons.local_shipping_outlined,
                      label: 'Delivery partner',
                      deliveryArtwork: buyV2DeliveryArtworkForLines(
                        order.lines,
                        fulfilmentModeFor: session.fulfilmentModeFor,
                      ),
                      value: _orderDeliveryPartnerLabel(order),
                    ),
                    if (order.trackingReference case final trackingReference?)
                      _OrderDeliveryFact(
                        icon: Icons.pin_outlined,
                        label: 'Tracking reference',
                        value: trackingReference,
                      ),
                    _OrderDeliveryFact(
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'Recorded instruction',
                      value:
                          order.deliveryInstruction ??
                          'No delivery instruction was recorded for this order.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                key: const ValueKey('buy-order-delivery-boundary'),
                padding: const EdgeInsets.all(12),
                decoration: buyV2CardDecoration(
                  color: BuyV2Colors.softOrange,
                  border: const Color(0x33FF9933),
                  radius: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: BuyV2Colors.navy,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This order stays unchanged',
                            style: sheetContext.buyBody,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Changing a saved address applies to future checkout only. '
                            'It does not change this order.',
                            style: sheetContext.buyMeta,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _OrderDeliveryContinuation(
                key: const ValueKey('buy-order-delivery-manage-future'),
                icon: Icons.edit_location_alt_outlined,
                title: 'Manage addresses for future checkout',
                detail: 'View, add or choose a saved checkout address',
                onTap: () => continueAfterReverse(
                  sheetContext,
                  () => showBuyV2AddressSheet(context, session),
                ),
              ),
              const SizedBox(height: 8),
              _OrderDeliveryContinuation(
                key: const ValueKey('buy-order-delivery-help'),
                icon: Icons.chat_outlined,
                title: 'Get help with this order',
                detail: '$orderId stays attached in Shop Chat',
                primary: true,
                onTap: () => continueAfterReverse(
                  sheetContext,
                  () async => onOpenOrderHelp(order),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DeliveryExceptionCard extends StatelessWidget {
  const _DeliveryExceptionCard({required this.session, required this.order});

  final BuyV2Session session;
  final BuyV2Order order;

  @override
  Widget build(BuildContext context) {
    if (session.deliveryExceptionAdapter == null) {
      return const SizedBox.shrink();
    }
    final snapshot = session.deliveryExceptionFor(order.id);
    final busy = session.deliveryExceptionBusy(order.id);
    if (snapshot == null) {
      return busy
          ? Container(
              key: const ValueKey('buy-delivery-exception-loading'),
              padding: const EdgeInsets.all(12),
              decoration: buyV2CardDecoration(radius: 15),
              child: const Row(
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 9),
                  Expanded(child: Text('Checking delivery updates…')),
                ],
              ),
            )
          : const SizedBox.shrink();
    }
    if (snapshot.state != BuyV2CommerceLoadState.ready) {
      return Container(
        key: ValueKey('buy-delivery-exception-${snapshot.state.name}'),
        padding: const EdgeInsets.all(12),
        decoration: buyV2CardDecoration(
          color: BuyV2Colors.softOrange,
          radius: 15,
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: BuyV2Colors.navy),
            const SizedBox(width: 9),
            Expanded(
              child: Text(snapshot.customerMessage, style: context.buyMeta),
            ),
            TextButton(
              key: const ValueKey('buy-delivery-exception-retry'),
              onPressed: busy
                  ? null
                  : () => session.restoreDeliveryException(order.id),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final kind = snapshot.kind;
    if (kind == null) return const SizedBox.shrink();
    final selectedSlot = session.selectedDeliveryRescheduleSlot(order.id);
    final accent = switch (kind) {
      BuyV2DeliveryExceptionKind.proofOfDeliveryAvailable ||
      BuyV2DeliveryExceptionKind.proofOfDeliveryDisputed =>
        BuyV2Colors.softBlue,
      _ => BuyV2Colors.softOrange,
    };
    return Container(
      key: ValueKey('buy-delivery-exception-${kind.name}'),
      padding: const EdgeInsets.all(12),
      decoration: buyV2CardDecoration(color: accent, radius: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                kind == BuyV2DeliveryExceptionKind.proofOfDeliveryAvailable ||
                        kind ==
                            BuyV2DeliveryExceptionKind.proofOfDeliveryDisputed
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                color: BuyV2Colors.navy,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.headline!,
                      style: context.buyTitle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(snapshot.detail!, style: context.buyMeta),
                  ],
                ),
              ),
              if (busy)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (snapshot.proofReference case final proofReference?) ...[
            const SizedBox(height: 6),
            Text(
              'Proof reference · $proofReference',
              key: const ValueKey('buy-delivery-proof-reference'),
              style: context.buyBody.copyWith(fontSize: 9.5),
            ),
          ],
          if (snapshot.itemisedReceipt case final receipt?) ...[
            const SizedBox(height: 8),
            Text(
              'Items received',
              style: context.buyTitle.copyWith(fontSize: 14),
            ),
            for (final line in receipt.lines)
              Padding(
                key: ValueKey(
                  'buy-receipt-line-${line.productId}-${line.variant}-${line.pack}',
                ),
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.lines
                          .firstWhere(
                            (purchased) =>
                                purchased.product.id == line.productId &&
                                purchased.product.variant == line.variant &&
                                purchased.product.pack == line.pack,
                          )
                          .product
                          .title,
                      style: context.buyBody,
                    ),
                    Text(
                      '${line.variant} · ${line.pack}',
                      style: context.buyMeta,
                    ),
                    Text(
                      'Received ${line.receivedQuantity} of ${line.orderedQuantity}'
                      '${line.missingQuantity > 0 ? ' · Missing ${line.missingQuantity}' : ''}',
                      style: context.buyBody,
                    ),
                  ],
                ),
              ),
          ],
          if (snapshot.rescheduleSlots.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Choose a new delivery time', style: context.buyBody),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final slot in snapshot.rescheduleSlots)
                  Semantics(
                    key: ValueKey('buy-delivery-slot-$slot'),
                    selected: selectedSlot == slot,
                    child: Align(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: OutlinedButton(
                        style:
                            BuyV2ActionStyle.button(
                              OutlinedButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                backgroundColor: selectedSlot == slot
                                    ? BuyV2Colors.softBlue
                                    : Colors.white,
                                foregroundColor: BuyV2Colors.navy,
                                side: BorderSide(
                                  color: selectedSlot == slot
                                      ? BuyV2Colors.navy
                                      : BuyV2Colors.line,
                                ),
                              ),
                            ).copyWith(
                              side: WidgetStatePropertyAll(
                                BorderSide(
                                  color: selectedSlot == slot
                                      ? BuyV2ActionStyle.primaryForeground
                                      : BuyV2ActionStyle.primaryBorder,
                                  width: selectedSlot == slot ? 2 : 1,
                                ),
                              ),
                            ),
                        onPressed: busy
                            ? null
                            : () => session.chooseDeliveryRescheduleSlot(
                                order.id,
                                slot,
                              ),
                        child: Text(slot, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: double.infinity,
                minHeight: BuyV2Metrics.minimumTap,
              ),
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: FilledButton(
                  style: BuyV2ActionStyle.button(),
                  key: const ValueKey('buy-delivery-confirm-reschedule'),
                  onPressed: busy || selectedSlot == null
                      ? null
                      : () => session.confirmDeliveryReschedule(order.id),
                  child: const Text('Confirm new time'),
                ),
              ),
            ),
          ],
          if (kind == BuyV2DeliveryExceptionKind.proofOfDeliveryAvailable) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: double.infinity,
                minHeight: BuyV2Metrics.minimumTap,
              ),
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: OutlinedButton(
                  style: BuyV2ActionStyle.button(),
                  key: const ValueKey('buy-delivery-dispute-proof'),
                  onPressed: busy
                      ? null
                      : () => session.disputeProofOfDelivery(order.id),
                  child: const Text('Report a delivery problem'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 5),
          Text(snapshot.customerMessage, style: context.buyMeta),
        ],
      ),
    );
  }
}

class _BalancePaymentCard extends StatelessWidget {
  const _BalancePaymentCard({
    required this.session,
    required this.order,
    this.paymentHandoff,
  });

  final BuyV2Session session;
  final BuyV2Order order;
  final BuyV2PaymentHandoff? paymentHandoff;

  @override
  Widget build(BuildContext context) {
    final result = session.balancePaymentFor(order.id);
    final busy = session.balancePaymentBusy(order.id);
    if (order.balanceDue <= 0 &&
        result?.state != BuyV2BalancePaymentState.paid) {
      return const SizedBox.shrink();
    }
    final state = result?.state ?? BuyV2BalancePaymentState.upcoming;
    final handoffUnavailable =
        state == BuyV2BalancePaymentState.paymentActionRequired &&
        paymentHandoff == null;
    final amountDue = result?.amountDue ?? order.balanceDue;
    final dueLabel = result?.dueLabel ?? order.balanceDueLabel ?? 'Due later';
    final statusLabel = switch (state) {
      BuyV2BalancePaymentState.upcoming => 'Upcoming balance',
      BuyV2BalancePaymentState.due => 'Balance due',
      BuyV2BalancePaymentState.overdue => 'Balance overdue',
      BuyV2BalancePaymentState.paymentActionRequired =>
        handoffUnavailable
            ? 'Balance payment unavailable'
            : 'Ready for payment',
      BuyV2BalancePaymentState.paymentPending => 'Payment pending',
      BuyV2BalancePaymentState.paid => 'Balance paid',
      BuyV2BalancePaymentState.unknown => 'Payment needs checking',
      BuyV2BalancePaymentState.offline => 'Balance status offline',
      BuyV2BalancePaymentState.unavailable => 'Balance payment unavailable',
    };
    VoidCallback? action;
    String? actionLabel;
    switch (state) {
      case BuyV2BalancePaymentState.due || BuyV2BalancePaymentState.overdue:
        action = () => session.startBalancePayment(order.id);
        actionLabel = 'Pay balance';
      case BuyV2BalancePaymentState.paymentActionRequired:
        final handoff = paymentHandoff;
        if (handoff != null) {
          action = () => session.continueBalancePayment(order.id, handoff);
          actionLabel = 'Continue payment';
        }
      case BuyV2BalancePaymentState.paymentPending ||
          BuyV2BalancePaymentState.unknown:
        action = () => session.reconcileBalancePayment(order.id);
        actionLabel = 'Check payment';
      case BuyV2BalancePaymentState.offline ||
          BuyV2BalancePaymentState.unavailable:
        action = () => session.restoreBalancePayment(order.id);
        actionLabel = 'Retry';
      case BuyV2BalancePaymentState.upcoming || BuyV2BalancePaymentState.paid:
        break;
    }
    return Container(
      key: const ValueKey('buy-tracking-balance-payment'),
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(
        color: state == BuyV2BalancePaymentState.paid
            ? BuyV2Colors.softGreen
            : BuyV2Colors.softBlue,
        radius: 15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: BuyV2Colors.navy,
                size: 21,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: context.buyTitle.copyWith(fontSize: 14),
                ),
              ),
              if (busy)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            state == BuyV2BalancePaymentState.paid
                ? 'No balance remains.'
                : '${buyV2Money(amountDue)} · $dueLabel',
            key: const ValueKey('buy-tracking-balance-amount'),
            style: context.buyBody,
          ),
          const SizedBox(height: 2),
          Text(
            handoffUnavailable
                ? 'Payment cannot open right now. No payment is confirmed. Try again later.'
                : result?.customerMessage ??
                      'Payment becomes available when the supplier confirms it is due.',
            style: context.buyMeta.copyWith(fontSize: 8.5),
          ),
          if (action != null && actionLabel != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: BuyV2Metrics.minimumTap,
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: FilledButton(
                  style: BuyV2ActionStyle.button(),
                  key: ValueKey(
                    'buy-tracking-balance-${actionLabel.toLowerCase().replaceAll(' ', '-')}',
                  ),
                  onPressed: busy ? null : action,
                  child: Text(actionLabel),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BuyV2LiveDeliveryPanel extends StatefulWidget {
  const BuyV2LiveDeliveryPanel({
    required this.session,
    required this.order,
    this.mapBuilder,
    this.pollInterval = const Duration(seconds: 15),
    super.key,
  });

  final BuyV2Session session;
  final BuyV2Order order;
  final BuyV2LiveDeliveryMapBuilder? mapBuilder;
  final Duration pollInterval;

  @override
  State<BuyV2LiveDeliveryPanel> createState() => _BuyV2LiveDeliveryPanelState();
}

class _BuyV2LiveDeliveryPanelState extends State<BuyV2LiveDeliveryPanel>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _mapExpanded = false;

  bool get _isForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didUpdateWidget(covariant BuyV2LiveDeliveryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.session, widget.session) ||
        oldWidget.order.id != widget.order.id ||
        widget.mapBuilder == null) {
      _mapExpanded = false;
    }
    if (!identical(oldWidget.session, widget.session) ||
        oldWidget.order.id != widget.order.id ||
        oldWidget.order.status != widget.order.status ||
        oldWidget.pollInterval != widget.pollInterval) {
      _timer?.cancel();
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    if (!_isForeground) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isForeground) {
        unawaited(widget.session.refreshLiveDelivery(widget.order.id));
      }
    });
    if (!widget.session.liveDeliveryAvailable ||
        widget.order.status == BuyV2OrderStatus.delivered ||
        widget.pollInterval <= Duration.zero) {
      return;
    }
    _timer = Timer.periodic(widget.pollInterval, (_) {
      if (mounted && !widget.session.liveDeliveryBusy(widget.order.id)) {
        unawaited(widget.session.refreshLiveDelivery(widget.order.id));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.session.liveDeliveryFor(widget.order.id);
    final busy = widget.session.liveDeliveryBusy(widget.order.id);
    final refreshMessage = widget.session.liveDeliveryRefreshMessage(
      widget.order.id,
    );
    final ready = snapshot?.state == BuyV2LiveDeliveryState.ready;
    final delivered = snapshot?.state == BuyV2LiveDeliveryState.delivered;
    final updatedAt = snapshot?.lastUpdatedAt;
    final stale =
        ready &&
        updatedAt != null &&
        DateTime.now().difference(updatedAt) > const Duration(minutes: 2);
    final accessibleMap = MediaQuery.textScalerOf(context).scale(10) > 14;
    return Container(
      key: ValueKey('buy-live-delivery-${widget.order.id}'),
      padding: const EdgeInsets.all(10),
      decoration: buyV2CardDecoration(color: BuyV2Colors.softBlue, radius: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: BuyV2Colors.navy,
                size: 21,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  delivered ? 'Delivery completed' : 'Live delivery',
                  style: context.buyTitle.copyWith(fontSize: 14),
                ),
              ),
              if (busy)
                Semantics(
                  label: 'Refreshing delivery location',
                  child: const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (snapshot == null)
            Text('Checking the latest delivery update…', style: context.buyBody)
          else if (!ready) ...[
            Text(snapshot.customerMessage, style: context.buyBody),
            if (widget.session.liveDeliveryAvailable && !delivered) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: BuyV2Metrics.minimumTap,
                child: Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: OutlinedButton.icon(
                    style: BuyV2ActionStyle.button(),
                    key: ValueKey('buy-live-delivery-retry-${widget.order.id}'),
                    onPressed: busy
                        ? null
                        : () => widget.session.refreshLiveDelivery(
                            widget.order.id,
                          ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try again'),
                  ),
                ),
              ),
            ],
          ] else ...[
            if (widget.mapBuilder == null)
              Semantics(
                label:
                    'Delivery map unavailable. ${snapshot.etaLabel}. Delivery details follow.',
                child: Text(
                  'Map view is not available right now.',
                  style: context.buyMeta,
                ),
              )
            else ...[
              Semantics(
                label: 'Delivery partner location map. ${snapshot.etaLabel}.',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    key: ValueKey('buy-live-delivery-map-${widget.order.id}'),
                    height: _mapExpanded ? 280 : (accessibleMap ? 158 : 120),
                    child: widget.mapBuilder!(context, snapshot),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: ValueKey(
                    'buy-live-delivery-map-toggle-${widget.order.id}',
                  ),
                  onPressed: () => setState(() => _mapExpanded = !_mapExpanded),
                  icon: Icon(
                    _mapExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(_mapExpanded ? 'Collapse map' : 'Expand map'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _DecisionRow(
              icon: Icons.schedule_outlined,
              label: 'Arriving',
              value: snapshot.etaLabel!,
            ),
            _DecisionRow(
              icon: Icons.delivery_dining_outlined,
              label: 'Delivery partner',
              deliveryArtwork: buyV2DeliveryArtworkForLines(
                widget.order.lines,
                fulfilmentModeFor: widget.session.fulfilmentModeFor,
              ),
              value: switch (_nonBlankComplianceValue(snapshot.vehicleLabel)) {
                final vehicle? => '${snapshot.driverName!} · $vehicle',
                null => snapshot.driverName!,
              },
            ),
            if (_nonBlankComplianceValue(snapshot.trackingReference)
                case final tracking?)
              _DecisionRow(
                icon: Icons.pin_outlined,
                label: 'Tracking reference',
                value: tracking,
              ),
            _DecisionRow(
              icon: Icons.update_rounded,
              label: 'Last updated',
              value: _liveDeliveryUpdatedLabel(updatedAt!),
            ),
            if (stale || refreshMessage != null) ...[
              const SizedBox(height: 6),
              Container(
                key: ValueKey('buy-live-delivery-update-${widget.order.id}'),
                padding: const EdgeInsets.all(9),
                decoration: buyV2CardDecoration(
                  color: BuyV2Colors.softOrange,
                  radius: 12,
                ),
                child: Text(
                  refreshMessage ??
                      'The courier location has not updated recently. Try again for the latest position.',
                  style: context.buyMeta,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: BuyV2Metrics.minimumTap,
                child: Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: OutlinedButton.icon(
                    style: BuyV2ActionStyle.button(),
                    onPressed: busy
                        ? null
                        : () => widget.session.refreshLiveDelivery(
                            widget.order.id,
                          ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh location'),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

String _liveDeliveryUpdatedLabel(DateTime updatedAt) {
  final elapsed = DateTime.now().difference(updatedAt);
  if (elapsed <= const Duration(seconds: 45)) return 'Just now';
  if (elapsed < const Duration(hours: 1)) {
    final minutes = elapsed.inMinutes.clamp(1, 59);
    return '$minutes min ago';
  }
  final hours = elapsed.inHours;
  return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
}

String _collectionMoney(int minor) =>
    '₹${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';

class _BuyV2CollectionOrderView extends StatefulWidget {
  const _BuyV2CollectionOrderView({
    required this.session,
    required this.order,
    required this.onOpenOrderHelp,
    this.cameraBuilder,
  });

  final BuyV2Session session;
  final BuyV2Order order;
  final ValueChanged<BuyV2Order> onOpenOrderHelp;
  final BuyV2CollectionCameraBuilder? cameraBuilder;

  @override
  State<_BuyV2CollectionOrderView> createState() =>
      _BuyV2CollectionOrderViewState();
}

class _BuyV2CollectionOrderViewState extends State<_BuyV2CollectionOrderView>
    with WidgetsBindingObserver {
  Timer? _poll;
  bool _scanning = false;
  bool _submitting = false;
  bool _foreground = true;
  String? _cameraMessage;
  int _scanGeneration = 0;
  BuyV2CollectionIdentity? _identity;
  final _cameraAnchor = GlobalKey();
  final _headingAnchor = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _identity = widget.session.collectionIdentity?.value;
    widget.session.addListener(_changed);
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  void _changed() {
    if (!mounted) return;
    setState(() {
      final identity = widget.session.collectionIdentity?.value;
      if (!identical(_identity, identity) ||
          !widget.session.collectionOrderBelongsToCurrentAccount(
            widget.order,
          )) {
        _identity = identity;
        _scanGeneration++;
        _scanning = false;
        _submitting = false;
      }
    });
  }

  void _refresh() {
    if (!mounted ||
        !_foreground ||
        _submitting ||
        ModalRoute.of(context)?.isCurrent == false ||
        widget.session.view != BuyV2View.tracking ||
        widget.session.selectedOrderId != widget.order.id) {
      return;
    }
    final snapshot = widget.session.collectionSnapshotFor(widget.order.id);
    if (!_scanning &&
        (snapshot?.state == ScanPickState.collected ||
            snapshot?.state == ScanPickState.cancelled)) {
      return;
    }
    if (!_scanning && !widget.session.collectionBusy(widget.order.id)) {
      unawaited(widget.session.refreshCollectionOrder(widget.order.id));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _refresh();
    } else {
      _foreground = false;
      _scanGeneration++;
      if (mounted) {
        setState(() {
          if (_submitting || state != AppLifecycleState.inactive) {
            _scanning = false;
          }
          _submitting = false;
        });
      }
      widget.session.pauseCollection();
    }
  }

  void _revealCollectionAnchor(GlobalKey anchor) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anchorContext = anchor.currentContext;
      if (!mounted || !_foreground || anchorContext == null) return;
      unawaited(Scrollable.ensureVisible(anchorContext, alignment: 0));
    });
  }

  Future<void> _detected(String raw) async {
    if (!mounted ||
        !_scanning ||
        _submitting ||
        !_foreground ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final session = widget.session;
    final orderId = widget.order.id;
    final generation = ++_scanGeneration;
    setState(() {
      _submitting = true;
      _cameraMessage = null;
    });
    if (!session.canScanCollection(orderId)) {
      await session.refreshCollectionOrder(orderId);
    }
    if (mounted &&
        generation == _scanGeneration &&
        _foreground &&
        identical(widget.session, session) &&
        widget.order.id == orderId &&
        session.canScanCollection(orderId)) {
      await session.authoriseCollection(orderId, raw);
    }
    if (!mounted ||
        generation != _scanGeneration ||
        !identical(widget.session, session) ||
        widget.order.id != orderId) {
      return;
    }
    setState(() {
      _scanning = false;
      _submitting = false;
      if (session.collectionMessageFor(orderId) == null &&
          session.collectionSnapshotFor(orderId)?.state ==
              ScanPickState.awaitingCustomer) {
        _cameraMessage =
            'Order status changed. Check the latest details, then scan again.';
      }
    });
    _revealCollectionAnchor(_headingAnchor);
  }

  @override
  void didUpdateWidget(covariant _BuyV2CollectionOrderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.order.id != widget.order.id) {
      oldWidget.session.removeListener(_changed);
      if (oldWidget.session != widget.session) {
        oldWidget.session.pauseCollection(notify: false);
      }
      _scanGeneration++;
      _identity = widget.session.collectionIdentity?.value;
      widget.session.addListener(_changed);
      _scanning = false;
      _submitting = false;
      _cameraMessage = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh();
      });
    }
  }

  @override
  void dispose() {
    _scanGeneration++;
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.session.removeListener(_changed);
    widget.session.pauseCollection(notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final order = widget.order;
    final owned = session.collectionOrderBelongsToCurrentAccount(order);
    final snapshot = owned ? session.collectionSnapshotFor(order.id) : null;
    final status = session.collectionStatusLabelFor(order.id);
    final message = session.collectionMessageFor(order.id) ?? _cameraMessage;
    final positive =
        status == 'Ready at store' ||
        status == 'Collected' ||
        status.startsWith('Matched');
    final lines = snapshot?.lines ?? const <ScanPickLine>[];
    return ListView.builder(
      key: PageStorageKey('buy-collection-order-${order.id}'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: lines.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          final previewHeight =
              (Scrollable.of(context).position.viewportDimension * .55).clamp(
                80.0,
                320.0,
              );
          return BuyV2CartAvoidanceRegion(
            child: Column(
              key: _headingAnchor,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _ReturnAffordance(
                    key: const ValueKey('buy-collection-return-orders'),
                    label: session.canReturnToShoppingHelp
                        ? 'Shopping help'
                        : 'Orders',
                    minimumHeight: 44,
                    onTap: session.returnToOrders,
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text(
                    'Collect at store',
                    style: context.buyTitle.copyWith(fontSize: 19),
                  ),
                ),
                if (owned) ...[
                  Text(
                    snapshot?.storeName ?? order.customerPartner,
                    style: context.buyBody,
                  ),
                  Text(order.id, style: context.buyMeta),
                ],
                const SizedBox(height: 12),
                Container(
                  key: const ValueKey('buy-collection-status'),
                  padding: const EdgeInsets.all(12),
                  decoration: buyV2CardDecoration(
                    color: positive
                        ? BuyV2Colors.softGreen
                        : const Color(0xFFF0F3F8),
                    radius: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        status,
                        style: context.buyTitle.copyWith(
                          fontSize: 16,
                          color: positive
                              ? BuyV2Colors.green
                              : BuyV2Colors.navy,
                        ),
                      ),
                      if (snapshot != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${snapshot.payment == ScanPickPayment.paid ? 'Paid ' : 'Order total '}${_collectionMoney(snapshot.totalMinor)}',
                          style: context.buyBody,
                        ),
                      ],
                      if (!owned)
                        Text(
                          'Sign in with the account that placed this order.',
                          style: context.buyBody,
                        ),
                      if (status.startsWith('Matched'))
                        Text(
                          'Your order is matched. The store can now hand over your items.',
                          style: context.buyBody,
                        ),
                      if (snapshot?.state == ScanPickState.preparing)
                        Text(
                          'We’ll update this order when the store is ready.',
                          style: context.buyBody,
                        ),
                      if (message != null) ...[
                        const SizedBox(height: 6),
                        Semantics(
                          liveRegion: true,
                          child: Text(message, style: context.buyBody),
                        ),
                      ],
                    ],
                  ),
                ),
                if (owned &&
                    !status.startsWith('Matched') &&
                    snapshot?.state != ScanPickState.collected &&
                    snapshot?.state != ScanPickState.cancelled) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Check your items, then scan at the counter.',
                    style: context.buyBody,
                  ),
                  const SizedBox(height: 8),
                  if (_scanning && !_submitting)
                    KeyedSubtree(
                      key: _cameraAnchor,
                      child: widget.cameraBuilder != null
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: previewHeight,
                              ),
                              child: widget.cameraBuilder!(
                                context,
                                (raw) => unawaited(_detected(raw)),
                              ),
                            )
                          : BuyV2CollectionCamera(
                              key: ValueKey(
                                'buy-collection-camera-${order.id}',
                              ),
                              maximumPreviewHeight: previewHeight,
                              onDetected: (raw) => unawaited(_detected(raw)),
                            ),
                    )
                  else if (_submitting ||
                      session.collectionReconciliationPending(order.id))
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        'Checking this order…',
                        style: context.buyBody,
                      ),
                    )
                  else if (!status.startsWith('Matched'))
                    Align(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: FilledButton.icon(
                        key: const ValueKey('buy-collection-scan'),
                        style: BuyV2ActionStyle.button(
                          FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        onPressed: session.canScanCollection(order.id)
                            ? () {
                                setState(() {
                                  _scanning = true;
                                  _cameraMessage = null;
                                });
                                _revealCollectionAnchor(_cameraAnchor);
                              }
                            : null,
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 22,
                        ),
                        label: const Text(
                          'Scan & Pick',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (_scanning && !_submitting)
                    TextButton(
                      key: const ValueKey('buy-collection-close-camera'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: () => setState(() => _scanning = false),
                      child: const Text('Close camera'),
                    ),
                ],
                if (lines.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Semantics(
                    header: true,
                    child: Text(
                      'Your purchased items',
                      style: context.buyTitle.copyWith(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        }
        if (index <= lines.length) {
          final line = lines[index - 1];
          return BuyV2CartAvoidanceRegion(
            child: Container(
              key: ValueKey('buy-collection-line-${line.lineId}'),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: buyV2CardDecoration(radius: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    line.name,
                    style: context.buyTitle.copyWith(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(line.pack, style: context.buyBody),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text('Quantity ${line.quantity}', style: context.buyBody),
                      Text(
                        _collectionMoney(line.amountMinor),
                        style: context.buyBody,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        return BuyV2CartAvoidanceRegion(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (snapshot?.receipt case final receipt?) ...[
                const SizedBox(height: 8),
                Text(
                  'Collection receipt',
                  style: context.buyTitle.copyWith(
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(receipt.id, style: context.buyBody),
                Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatFullDate(receipt.collectedAt.toLocal()),
                  style: context.buyMeta,
                ),
                if (receipt.invoiceReference case final invoice?)
                  Text('Invoice $invoice', style: context.buyBody),
              ],
              const SizedBox(height: 12),
              Text(
                'Your rights for faulty or incorrect goods remain.',
                style: context.buyMeta.copyWith(fontSize: 11),
              ),
              if (owned)
                TextButton.icon(
                  key: const ValueKey('buy-collection-help'),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () {
                    _scanGeneration++;
                    setState(() {
                      _scanning = false;
                      _submitting = false;
                    });
                    session.pauseCollection();
                    widget.onOpenOrderHelp(order);
                  },
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                  label: const Text('Order help'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class BuyV2TrackingView extends StatelessWidget {
  const BuyV2TrackingView({
    super.key,
    required this.session,
    required this.onOpenOrderHelp,
    this.invoiceDownloader,
    this.paymentHandoff,
    this.liveDeliveryMapBuilder,
    this.collectionCameraBuilder,
    this.onRestoreDeliveryStatus,
  });

  final BuyV2Session session;
  final ValueChanged<BuyV2Order> onOpenOrderHelp;
  final BuyV2InvoiceDownloader? invoiceDownloader;
  final BuyV2PaymentHandoff? paymentHandoff;
  final BuyV2LiveDeliveryMapBuilder? liveDeliveryMapBuilder;
  final BuyV2CollectionCameraBuilder? collectionCameraBuilder;
  final VoidCallback? onRestoreDeliveryStatus;

  @override
  Widget build(BuildContext context) {
    final order = session.selectedOrderOrNull;
    if (order == null) {
      return _MissingOrderSelection(session: session);
    }
    if (order.collection != null) {
      return _BuyV2CollectionOrderView(
        session: session,
        order: order,
        onOpenOrderHelp: onOpenOrderHelp,
        cameraBuilder: collectionCameraBuilder,
      );
    }
    final purchasedQuantity = order.lines.fold<int>(
      0,
      (total, line) => total + line.quantity,
    );
    final unit = order.destination == BuyV2Destination.wholesale
        ? 'pack'
        : 'item';
    // Older saved orders retain the list summary but no line snapshots.
    // Extract only its recognised count prefix; keep unknown summaries intact.
    final legacyCounts = RegExp(
      r'^(\d+ (?:trade )?products?(?: · \d+ (?:items?|packs?))?)(?: · |$)',
    ).firstMatch(order.itemSummary)?.group(1);
    final purchasedSummary = order.lines.isEmpty
        ? legacyCounts ?? order.itemSummary
        : '${order.lines.length} ${order.lines.length == 1 ? 'product' : 'products'} · '
              '$purchasedQuantity $unit${purchasedQuantity == 1 ? '' : 's'}';
    final returnToOrders = IntrinsicWidth(
      child: _ReturnAffordance(
        key: const ValueKey('buy-tracking-return-orders'),
        label: session.canReturnToShoppingHelp
            ? 'Shopping help'
            : session.canReturnToShoppingAlerts
            ? 'Shopping alerts'
            : 'Orders',
        onTap: session.returnToOrders,
      ),
    );
    final orderHeading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.buyTitle.copyWith(fontSize: 16),
        ),
        Text(order.id, style: context.buyMeta.copyWith(fontSize: 8)),
      ],
    );
    final refreshOrder = IconButton(
      key: ValueKey('buy-tracking-refresh-${order.id}'),
      tooltip: 'Refresh order',
      onPressed: session.orderRefreshBusy(order.id)
          ? null
          : () => session.refreshOrder(order.id),
      constraints: const BoxConstraints.tightFor(
        width: BuyV2Metrics.minimumTap,
        height: BuyV2Metrics.minimumTap,
      ),
      icon: session.orderRefreshBusy(order.id)
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded, size: 20),
    );
    final refreshed =
        session.orderRefreshState(order.id) == BuyV2CommerceLoadState.ready;
    final refreshing = session.orderRefreshBusy(order.id);
    final freshnessLabel = refreshing
        ? 'REFRESHING'
        : refreshed
        ? 'UPDATED'
        : 'LAST KNOWN';
    final freshnessColor = refreshed ? BuyV2Colors.green : BuyV2Colors.navy;
    final currentStatus = Semantics(
      label:
          '${refreshing
              ? 'Refreshing'
              : refreshed
              ? 'Updated'
              : 'Last known'} order status: ${_trackingStatusLabel(order.status)}',
      excludeSemantics: true,
      child: Container(
        key: ValueKey('buy-tracking-freshness-${order.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: refreshed ? BuyV2Colors.softGreen : BuyV2Colors.softBlue,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: freshnessColor,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 8, height: 8),
            ),
            const SizedBox(width: 5),
            Text(
              freshnessLabel,
              style: TextStyle(
                color: freshnessColor,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
    return ListView(
      key: PageStorageKey('buy-tracking-${order.id}'),
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 110),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compactHeader =
                constraints.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(10) > 12;
            if (compactHeader) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      returnToOrders,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          refreshOrder,
                          const SizedBox(width: 4),
                          currentStatus,
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  orderHeading,
                ],
              );
            }
            return Row(
              children: [
                returnToOrders,
                const SizedBox(width: 8),
                Expanded(child: orderHeading),
                refreshOrder,
                const SizedBox(width: 4),
                currentStatus,
              ],
            );
          },
        ),
        if (onRestoreDeliveryStatus != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('buy-quick-delivery-restore'),
              onPressed: onRestoreDeliveryStatus,
              icon: BuyV2DeliveryModeIcon(
                artwork: buyV2DeliveryArtworkForLines(
                  order.lines,
                  fulfilmentModeFor: session.fulfilmentModeFor,
                ),
                size: 18,
              ),
              label: const Text('Show delivery status'),
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            ),
          ),
        if (session.orderRefreshState(order.id) case final refreshState?
            when refreshState != BuyV2CommerceLoadState.ready &&
                refreshState != BuyV2CommerceLoadState.loading) ...[
          const SizedBox(height: 6),
          Container(
            key: ValueKey('buy-tracking-refresh-${refreshState.name}'),
            padding: const EdgeInsets.all(10),
            decoration: buyV2CardDecoration(
              color: BuyV2Colors.softOrange,
              border: BuyV2Colors.orange,
              radius: 13,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  color: BuyV2Colors.navy,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.orderRefreshMessage(order.id) ??
                        'Order could not refresh. Last known details are still shown.',
                    style: context.buyMeta,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: BuyV2ActionStyle.gradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _trackingStatusLabel(order.status),
                      style: const TextStyle(
                        color: Color(0xFF855100),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${(order.progress * 100).round()}%',
                    style: const TextStyle(
                      color: BuyV2ActionStyle.foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                buyV2OrderArrivalSummary(session, order),
                key: ValueKey('buy-tracking-estimate-${order.id}'),
                style: const TextStyle(
                  color: BuyV2ActionStyle.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (order.updatedDeliveryEstimate != null) ...[
                const SizedBox(height: 2),
                Text(
                  buyV2OrderArrivalSummary(session, order, revised: true),
                  style: const TextStyle(
                    color: Color(0xFF855100),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BuyV2HonestProgressIndicator(
                  ownerId: order.id,
                  progress: order.progress,
                  statusLabel: _trackingStatusLabel(order.status),
                  isComplete: order.status == BuyV2OrderStatus.delivered,
                  minHeight: 6,
                  backgroundColor: const Color(0x33243850),
                  valueColor: BuyV2Colors.orange,
                  indicatorKey: const ValueKey('buy-tracking-progress'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (order.status != BuyV2OrderStatus.delivered) ...[
          BuyV2LiveDeliveryPanel(
            session: session,
            order: order,
            mapBuilder: liveDeliveryMapBuilder,
          ),
          const SizedBox(height: 6),
        ],
        if (session.deliveryExceptionAdapter != null) ...[
          _DeliveryExceptionCard(session: session, order: order),
          const SizedBox(height: 6),
        ],
        _DecisionPanel(
          title: 'Delivery details',
          children: [
            _DecisionRow(
              icon: Icons.storefront_outlined,
              label: switch (order.destination) {
                BuyV2Destination.wholesale => 'Supplier',
                BuyV2Destination.medicine => 'Pharmacy',
                _ => 'Store',
              },
              value: '${order.customerPartner} · ${order.partnerType}',
            ),
            if (order.buyerName case final buyer?)
              _DecisionRow(
                icon: Icons.business_outlined,
                label: order.buyerType ?? 'Buyer',
                value: buyer,
              ),
            _DecisionRow(
              icon: Icons.local_shipping_outlined,
              label: order.deliveryPartnerType ?? 'Delivery partner',
              deliveryArtwork: buyV2DeliveryArtworkForLines(
                order.lines,
                fulfilmentModeFor: session.fulfilmentModeFor,
              ),
              value: _orderDeliveryPartnerLabel(order),
            ),
            if (order.dispatchPromise case final dispatchPromise?)
              _DecisionRow(
                icon: Icons.inventory_2_outlined,
                label: 'Dispatch promise',
                value: dispatchPromise,
              ),
            if (order.deliveryServiceLevel case final serviceLevel?)
              _DecisionRow(
                icon: Icons.route_outlined,
                label: 'Delivery service',
                value: serviceLevel,
              ),
            if (order.trackingReference case final trackingReference?)
              _DecisionRow(
                icon: Icons.pin_outlined,
                label: 'Tracking reference',
                value: trackingReference,
              ),
            if (order.proofOfDeliveryStatus case final proofStatus?)
              _DecisionRow(
                icon: Icons.verified_outlined,
                label: 'Proof of delivery',
                value: proofStatus,
              ),
            _DecisionRow(
              icon: Icons.location_on_outlined,
              label: 'Delivering to',
              value: order.destinationLabel,
            ),
            _DecisionRow(
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              value: purchasedSummary,
            ),
            if (order.deliveryInstruction != null)
              _DecisionRow(
                icon: Icons.assignment_turned_in_outlined,
                label: _deliveryInstructionOwner(order.destination),
                value: order.deliveryInstruction!,
              ),
            if (order.tip > 0)
              _DecisionRow(
                icon: Icons.volunteer_activism_outlined,
                label: 'Delivery tip',
                value: buyV2Money(order.tip),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (order.paymentMethod != null ||
            order.purchaseOrderReference != null ||
            order.paymentTermLabel != null ||
            order.amountPaidNow != null ||
            order.paymentStatusLabel != null)
          _DecisionPanel(
            title: 'Payment',
            children: [
              if (order.paymentMethod case final paymentMethod?)
                _DecisionRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payment method',
                  value: paymentMethod,
                ),
              if (order.purchaseOrderReference case final reference?)
                _DecisionRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Purchase order',
                  value: reference,
                ),
              if (order.paymentTermLabel case final paymentTerm?)
                _DecisionRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payment term',
                  value: paymentTerm,
                ),
              if (order.amountPaidNow case final paidNow?)
                _DecisionRow(
                  icon: Icons.payments_outlined,
                  label: 'Paid now',
                  value: buyV2Money(paidNow),
                ),
              if (order.paymentStatusLabel case final paymentStatus?)
                _DecisionRow(
                  icon: Icons.verified_outlined,
                  label: 'Payment status',
                  value: paymentStatus,
                ),
            ],
          ),
        if (order.balanceDue > 0 ||
            session.balancePaymentFor(order.id)?.state ==
                BuyV2BalancePaymentState.paid) ...[
          const SizedBox(height: 6),
          _BalancePaymentCard(
            session: session,
            order: order,
            paymentHandoff: paymentHandoff,
          ),
        ],
        const SizedBox(height: 6),
        _TrackingRoute(order: order),
        const SizedBox(height: 6),
        _TrackingTimeline(order: order),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: buyV2CardDecoration(
            color: BuyV2Colors.softOrange,
            border: const Color(0x33FF9933),
            radius: 13,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.next_plan_outlined,
                color: BuyV2Colors.navy,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What happens next',
                      style: TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _trackingNextStep(order.status),
                      style: context.buyMeta.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          key: const ValueKey('buy-tracking-alerts'),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(9, 4, 4, 4),
          decoration: buyV2CardDecoration(radius: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BuyV2Colors.softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: BuyV2FiniteVisualTransition(
                  stateKey: session.trackingAlertsEnabled,
                  ownerSize: const Size.square(34),
                  child: Icon(
                    session.trackingAlertsEnabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: BuyV2Colors.navy,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order updates', style: context.buyBody),
                    Text(
                      session.trackingAlertsBusy
                          ? 'Saving alert preference…'
                          : !session.trackingAlertsAvailable
                          ? 'Order alerts are unavailable'
                          : session.trackingAlertsEnabled
                          ? 'Order alerts are on'
                          : 'Order alerts are paused',
                      style: context.buyMeta.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ),
              if (!session.trackingAlertsAvailable &&
                  !session.trackingAlertsBusy)
                IconButton(
                  key: const ValueKey('buy-tracking-alerts-retry'),
                  tooltip: 'Retry order alerts',
                  onPressed: session.restoreOrderAlerts,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              Switch.adaptive(
                key: const ValueKey('buy-tracking-alerts-toggle'),
                value: session.trackingAlertsEnabled,
                onChanged:
                    session.trackingAlertsBusy ||
                        !session.trackingAlertsAvailable
                    ? null
                    : (enabled) {
                        HapticFeedback.selectionClick();
                        session.setTrackingAlerts(enabled);
                      },
                activeTrackColor: BuyV2Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _TrackingActionGroup(
          actions: [
            _TrackingAction(
              key: const ValueKey('buy-tracking-address'),
              onPressed: () => _showBuyV2OrderDeliveryContextSheet(
                context,
                session,
                order,
                onOpenOrderHelp,
              ),
              icon: Icons.location_on_outlined,
              label: 'Address',
            ),
            _TrackingAction(
              onPressed: () => session.openOrderItems(order.id),
              icon: Icons.inventory_2_outlined,
              label: 'Items',
            ),
            _TrackingAction(
              key: ValueKey(
                order.status == BuyV2OrderStatus.delivered
                    ? 'buy-tracking-reorder'
                    : 'buy-tracking-help',
              ),
              onPressed: order.status == BuyV2OrderStatus.delivered
                  ? () => session.reorder(order)
                  : () => onOpenOrderHelp(order),
              icon: order.status == BuyV2OrderStatus.delivered
                  ? Icons.replay_rounded
                  : Icons.chat_outlined,
              label: order.status == BuyV2OrderStatus.delivered
                  ? 'Reorder'
                  : 'Help',
              primary: true,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          key: ValueKey('buy-tracking-secondary-actions-${order.id}'),
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              key: ValueKey('buy-tracking-manage-order-${order.id}'),
              style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => showBuyV2OrderResolutionSheet(
                context,
                session: session,
                order: order,
                onOpenSupport: () => onOpenOrderHelp(order),
              ),
              icon: const Icon(Icons.assignment_return_outlined, size: 18),
              label: Text(
                order.status == BuyV2OrderStatus.delivered
                    ? 'Return, replace or refund'
                    : 'Manage order',
              ),
            ),
            if (order.invoiceAvailable)
              TextButton.icon(
                key: ValueKey('buy-tracking-invoice-${order.id}'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () => _openOrderInvoice(
                  context,
                  session: session,
                  order: order,
                  downloader: invoiceDownloader,
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Invoice'),
              ),
          ],
        ),
        if (!order.invoiceAvailable)
          Container(
            key: ValueKey('buy-tracking-invoice-pending-${order.id}'),
            padding: const EdgeInsets.all(10),
            decoration: buyV2CardDecoration(
              color: BuyV2Colors.softBlue,
              radius: 13,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: BuyV2Colors.navy,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Invoice is being prepared. Refresh this order for the latest update.',
                    style: context.buyMeta,
                  ),
                ),
              ],
            ),
          ),
        if (order.status == BuyV2OrderStatus.delivered) ...[
          const SizedBox(height: 6),
          _OrderDeliveryContinuation(
            key: const ValueKey('buy-tracking-delivered-help'),
            icon: Icons.support_agent_outlined,
            title: 'Get help with this order',
            detail: 'Prepare a return, replacement or refund question',
            onTap: () => onOpenOrderHelp(order),
          ),
        ],
      ],
    );
  }
}

Future<void> showBuyV2OrderResolutionSheet(
  BuildContext context, {
  required BuyV2Session session,
  required BuyV2Order order,
  required VoidCallback onOpenSupport,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _BuyV2OrderResolutionSheet(
      session: session,
      order: order,
      onOpenSupport: onOpenSupport,
    ),
  );
}

class _BuyV2OrderResolutionSheet extends StatefulWidget {
  const _BuyV2OrderResolutionSheet({
    required this.session,
    required this.order,
    required this.onOpenSupport,
  });

  final BuyV2Session session;
  final BuyV2Order order;
  final VoidCallback onOpenSupport;

  @override
  State<_BuyV2OrderResolutionSheet> createState() =>
      _BuyV2OrderResolutionSheetState();
}

class _BuyV2OrderResolutionSheetState
    extends State<_BuyV2OrderResolutionSheet> {
  BuyV2OrderResolutionKind? selectedKind;
  String? selectedReason;
  final Map<String, int> selectedItemQuantities = {};
  String? selectionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.session.refreshOrderResolution(widget.order.id));
      }
    });
  }

  void openSupport() {
    final action = widget.onOpenSupport;
    Navigator.of(context).pop();
    Future<void>.microtask(action);
  }

  Future<void> submit() async {
    final kind = selectedKind;
    final reason = selectedReason;
    if (kind == null || reason == null) return;
    if (kind != BuyV2OrderResolutionKind.cancel &&
        selectedItemQuantities.isEmpty) {
      setState(() => selectionError = 'Choose at least one product.');
      return;
    }
    final accepted = await widget.session.submitOrderResolution(
      orderId: widget.order.id,
      kind: kind,
      reason: reason,
      itemQuantities: selectedItemQuantities,
    );
    if (!mounted) return;
    if (accepted) {
      Navigator.of(context).pop();
    } else {
      setState(() => selectionError = widget.session.notice);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final snapshot = widget.session.orderResolutionFor(widget.order.id);
        final busy = widget.session.orderResolutionBusy(widget.order.id);
        final result = widget.session.orderResolutionResultFor(widget.order.id);
        final ready = snapshot?.state == BuyV2OrderResolutionState.ready;
        final options = ready
            ? snapshot!.options
            : const <BuyV2OrderResolutionOption>[];
        final selectedOption = options
            .where((option) => option.kind == selectedKind)
            .firstOrNull;
        final orderProducts = widget.order.lines.isNotEmpty
            ? {
                for (final line in widget.order.lines)
                  line.product.id: line.product,
              }.values.toList(growable: false)
            : widget.order.productIds.isNotEmpty
            ? widget.session.productsForOrder(widget.order)
            : const <BuyV2Product>[];
        final canChooseReason =
            selectedOption != null &&
            (selectedOption.kind == BuyV2OrderResolutionKind.cancel ||
                orderProducts.any((product) {
                  final fact = widget.session.orderResolutionEligibilityFor(
                    widget.order.id,
                    selectedOption.kind,
                    product.id,
                  );
                  return fact != null &&
                      fact.unavailableReasonAt(DateTime.now()) == null;
                }));
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const ValueKey('buy-order-resolution-sheet'),
            padding: EdgeInsets.fromLTRB(
              14,
              0,
              14,
              18 +
                  MediaQuery.viewPaddingOf(context).bottom +
                  MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.order.status == BuyV2OrderStatus.delivered
                      ? 'Return, replace or refund'
                      : 'Manage order',
                  style: context.buyTitle.copyWith(fontSize: 19),
                ),
                const SizedBox(height: 3),
                Text(
                  'Order ${widget.order.id} · ${widget.order.itemSummary}',
                  style: context.buyMeta,
                ),
                const SizedBox(height: 12),
                if (snapshot == null ||
                    snapshot.state == BuyV2OrderResolutionState.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  )
                else if (!ready) ...[
                  Container(
                    key: const ValueKey('buy-order-resolution-unavailable'),
                    padding: const EdgeInsets.all(12),
                    decoration: buyV2CardDecoration(
                      color: BuyV2Colors.softOrange,
                      radius: 15,
                    ),
                    child: Text(
                      snapshot.customerMessage ??
                          'Order changes are unavailable right now.',
                      style: context.buyBody,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: OutlinedButton.icon(
                      style: BuyV2ActionStyle.button(),
                      key: const ValueKey('buy-order-resolution-retry'),
                      onPressed: busy
                          ? null
                          : () => widget.session.refreshOrderResolution(
                              widget.order.id,
                            ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: FilledButton.icon(
                      style: BuyV2ActionStyle.button(),
                      key: const ValueKey('buy-order-resolution-support'),
                      onPressed: openSupport,
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Contact supplier'),
                    ),
                  ),
                ] else ...[
                  if (options.length > 1)
                    Text('Choose what you need', style: context.buyBody),
                  const SizedBox(height: 7),
                  for (final option in options) ...[
                    _OrderResolutionOptionTile(
                      option: option,
                      selected: option.kind == selectedKind,
                      onTap: () => setState(() {
                        selectedKind = option.kind;
                        selectedReason = null;
                        selectedItemQuantities.clear();
                        selectionError = null;
                      }),
                    ),
                    const SizedBox(height: 7),
                  ],
                  if (selectedOption != null) ...[
                    const SizedBox(height: 3),
                    if (selectedOption.kind !=
                        BuyV2OrderResolutionKind.cancel) ...[
                      Text(
                        'Purchased-item eligibility',
                        style: context.buyBody,
                      ),
                      const SizedBox(height: 6),
                      if (!canChooseReason) ...[
                        Text(
                          'No items are confirmed eligible for this request. Check again or contact support.',
                          key: const ValueKey(
                            'buy-order-resolution-no-eligible-items',
                          ),
                          style: context.buyBody,
                        ),
                        const SizedBox(height: 6),
                      ],
                      for (final product in orderProducts) ...[
                        _OrderResolutionItemTile(
                          product: product,
                          selectedQuantity:
                              selectedItemQuantities[product.id] ?? 0,
                          eligibility: widget.session
                              .orderResolutionEligibilityFor(
                                widget.order.id,
                                selectedOption.kind,
                                product.id,
                              ),
                          onChanged: busy
                              ? null
                              : (quantity) => setState(() {
                                  if (quantity <= 0) {
                                    selectedItemQuantities.remove(product.id);
                                  } else {
                                    selectedItemQuantities[product.id] =
                                        quantity;
                                  }
                                  selectionError = null;
                                }),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (selectionError case final message?) ...[
                        Text(
                          message,
                          key: const ValueKey(
                            'buy-order-resolution-item-error',
                          ),
                          style: context.buyMeta.copyWith(
                            color: BuyV2Colors.orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Align(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: OutlinedButton.icon(
                          style: BuyV2ActionStyle.button(),
                          key: const ValueKey(
                            'buy-order-resolution-check-eligibility',
                          ),
                          onPressed: busy
                              ? null
                              : () {
                                  setState(() {
                                    selectedItemQuantities.clear();
                                    selectedReason = null;
                                    selectionError = null;
                                  });
                                  unawaited(
                                    widget.session.refreshOrderResolution(
                                      widget.order.id,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Check eligibility again'),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (canChooseReason) ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey(
                          'buy-order-resolution-reason-${selectedOption.kind.name}',
                        ),
                        initialValue: selectedReason,
                        isExpanded: true,
                        isDense: false,
                        itemHeight: null,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final reason in selectedOption.reasons)
                            DropdownMenuItem(
                              value: reason,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(reason),
                              ),
                            ),
                        ],
                        onChanged: busy
                            ? null
                            : (value) => setState(() => selectedReason = value),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: FilledButton(
                          style: BuyV2ActionStyle.button(),
                          key: const ValueKey('buy-order-resolution-submit'),
                          onPressed:
                              busy ||
                                  selectedReason == null ||
                                  !widget.session.orderResolutionItemsAllowed(
                                    orderId: widget.order.id,
                                    kind: selectedOption.kind,
                                    itemQuantities: selectedItemQuantities,
                                  )
                              ? null
                              : submit,
                          child: Text(busy ? 'Sending…' : 'Submit request'),
                        ),
                      ),
                    ],
                  ],
                  if (result != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      result.customerMessage,
                      key: const ValueKey('buy-order-resolution-result'),
                      style: context.buyMeta.copyWith(
                        color: result.accepted
                            ? BuyV2Colors.green
                            : BuyV2Colors.orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: const ValueKey('buy-order-resolution-support-instead'),
                    onPressed: openSupport,
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Contact supplier'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderResolutionItemTile extends StatelessWidget {
  const _OrderResolutionItemTile({
    required this.product,
    required this.selectedQuantity,
    required this.eligibility,
    required this.onChanged,
  });

  final BuyV2Product product;
  final int selectedQuantity;
  final BuyV2OrderResolutionItemEligibility? eligibility;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final fact = eligibility;
    final issue = fact == null
        ? 'Eligibility could not be confirmed. Contact support for help.'
        : fact.unavailableReasonAt(DateTime.now());
    final available = issue == null;
    final selected = available && selectedQuantity > 0;
    final deadline = fact?.eligibleUntil?.toLocal();
    final localizations = MaterialLocalizations.of(context);
    return Semantics(
      container: true,
      label:
          '${product.customerTitle}, ${product.pack}. ${selected ? '$selectedQuantity selected' : 'Not selected'}.',
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 7, 7, 7),
        decoration: buyV2CardDecoration(
          color: selected ? BuyV2Colors.softBlue : Colors.white,
          radius: 13,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  key: ValueKey('buy-order-resolution-item-${product.id}'),
                  value: selected,
                  onChanged: !available || onChanged == null
                      ? null
                      : (value) => onChanged!(value == true ? 1 : 0),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.customerTitle,
                        style: context.buyBody.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(product.pack, style: context.buyMeta),
                    ],
                  ),
                ),
              ],
            ),
            if (fact != null && fact.policyWindow.trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                'Policy window: ${fact.policyWindow}',
                style: context.buyMeta,
              ),
            ],
            if (deadline != null) ...[
              const SizedBox(height: 5),
              Text(
                'Eligible until ${localizations.formatFullDate(deadline)}, '
                '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(deadline))} (local time)',
                style: context.buyMeta,
              ),
            ],
            const SizedBox(height: 5),
            Text(
              issue ?? 'Eligible quantity: ${fact!.eligibleQuantity}',
              key: ValueKey('buy-order-resolution-eligibility-${product.id}'),
              style: context.buyMeta,
            ),
            if (selected) ...[
              const SizedBox(height: 5),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    key: ValueKey(
                      'buy-order-resolution-item-${product.id}-decrease',
                    ),
                    tooltip: 'Decrease ${product.customerTitle} quantity',
                    onPressed: onChanged == null
                        ? null
                        : () => onChanged!(selectedQuantity - 1),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(Icons.remove_rounded, size: 18),
                  ),
                  Text(
                    '$selectedQuantity',
                    style: context.buyBody.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    key: ValueKey(
                      'buy-order-resolution-item-${product.id}-increase',
                    ),
                    tooltip: 'Increase ${product.customerTitle} quantity',
                    onPressed:
                        onChanged == null ||
                            selectedQuantity >= fact!.eligibleQuantity
                        ? null
                        : () => onChanged!(selectedQuantity + 1),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderResolutionOptionTile extends StatelessWidget {
  const _OrderResolutionOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final BuyV2OrderResolutionOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${option.title}. ${option.detail}',
    child: InkWell(
      key: ValueKey('buy-order-resolution-${option.kind.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.all(10),
        decoration: buyV2CardDecoration(
          color: selected ? BuyV2Colors.softBlue : Colors.white,
          radius: 14,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: BuyV2Colors.navy,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: context.buyBody.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(option.detail, style: context.buyMeta),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

typedef BuyV2AssistChatHandler =
    void Function({String? intent, String? details});

class BuyV2AssistView extends StatefulWidget {
  const BuyV2AssistView({
    super.key,
    required this.session,
    required this.onOpenChat,
  });

  final BuyV2Session session;
  final BuyV2AssistChatHandler onOpenChat;

  @override
  State<BuyV2AssistView> createState() => _BuyV2AssistViewState();
}

class _BuyV2AssistViewState extends State<BuyV2AssistView> {
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocus = FocusNode();
  String? _selectedIntent;
  bool _composerFocused = false;

  @override
  void initState() {
    super.initState();
    _composerFocus.addListener(_handleComposerFocus);
  }

  void _handleComposerFocus() {
    if (mounted && _composerFocused != _composerFocus.hasFocus) {
      setState(() => _composerFocused = _composerFocus.hasFocus);
    }
  }

  void _chooseIntent(String intent) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIntent = intent);
    widget.session.showNotice('$intent selected for MoolSocial Assist.');
  }

  void _prepareQuestion() {
    if (_composerController.text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    widget.session.showNotice(
      'Question ready. Choose Chat to select a conversation and continue.',
    );
  }

  @override
  void dispose() {
    _composerFocus.removeListener(_handleComposerFocus);
    _composerFocus.dispose();
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final order = session.assistOrder;
    final accessibleText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    return ListView(
      key: const PageStorageKey('buy-assist'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      children: [
        _ReturnAffordance(
          label: 'Back',
          onTap: session.closeAssist,
          tightHitOwner: true,
          hitOwnerKey: const ValueKey('buy-assist-return'),
        ),
        const SizedBox(height: 8),
        Container(
          key: const ValueKey('buy-assist-hero'),
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
          decoration: BoxDecoration(
            gradient: BuyV2ActionStyle.gradient,
            borderRadius: BorderRadius.circular(19),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000080),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: BuyV2ActionStyle.foreground.withValues(alpha: .22),
                  ),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: BuyV2ActionStyle.foreground,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MoolSocial Assist',
                      style: TextStyle(
                        color: BuyV2ActionStyle.foreground,
                        fontSize: 15,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Topics prepare support; no order changes happen here.',
                      key: const ValueKey('buy-assist-order-change-boundary'),
                      style: TextStyle(
                        color: BuyV2ActionStyle.foreground.withValues(
                          alpha: .78,
                        ),
                        fontSize: 9,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'Cancellation · return · refund help',
                        style: TextStyle(
                          color: BuyV2ActionStyle.foreground,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('buy-assist-current-order'),
            onTap: () {
              HapticFeedback.selectionClick();
              session.openTracking(order.id);
            },
            borderRadius: BorderRadius.circular(17),
            child: Container(
              padding: const EdgeInsets.fromLTRB(11, 10, 10, 10),
              decoration: buyV2CardDecoration(radius: 17, shadow: true),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 39,
                        height: 39,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: BuyV2Colors.softBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: BuyV2Colors.navy,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _trackingStatusLabel(order.status),
                              style: context.buyBody.copyWith(fontSize: 11),
                            ),
                            Text(
                              '${order.id} · ${_orderPromiseSummary(order)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyMeta.copyWith(fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 52,
                          minHeight: 44,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(
                          color: BuyV2Colors.softOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Track',
                          style: TextStyle(
                            color: BuyV2Colors.navy,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: BuyV2HonestProgressIndicator(
                      ownerId: order.id,
                      progress: order.progress,
                      statusLabel: _trackingStatusLabel(order.status),
                      isComplete: order.status == BuyV2OrderStatus.delivered,
                      minHeight: 5,
                      backgroundColor: BuyV2Colors.softBlue,
                      valueColor: BuyV2Colors.green,
                      indicatorKey: const ValueKey('buy-assist-order-progress'),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        '${(order.progress * 100).round()}% complete',
                        style: const TextStyle(
                          color: BuyV2Colors.green,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          _trackingNextStep(order.status),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: context.buyMeta.copyWith(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'What do you need help with?',
          style: context.buyTitle.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final singleColumn = accessibleText || constraints.maxWidth < 330;
            final itemWidth = singleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - 7) / 2;
            final intents = [
              if (order.status == BuyV2OrderStatus.delivered) ...[
                (
                  'Return, replacement or refund',
                  Icons.assignment_return_outlined,
                ),
                ('Problem with an item', Icons.inventory_2_outlined),
                ('Report a delivery issue', Icons.local_shipping_outlined),
              ] else ...[
                ('Where is my order?', Icons.local_shipping_outlined),
                ('Cancel or change order', Icons.cancel_outlined),
                ('Change delivery', Icons.location_on_outlined),
                ('Problem with an item', Icons.inventory_2_outlined),
              ],
              if (order.destination == BuyV2Destination.medicine)
                ('Medicine support', Icons.local_pharmacy_outlined),
            ];
            return Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final intent in intents)
                  SizedBox(
                    width: itemWidth,
                    child: _AssistIntent(
                      label: intent.$1,
                      icon: intent.$2,
                      selected: _selectedIntent == intent.$1,
                      onTap: () => _chooseIntent(intent.$1),
                    ),
                  ),
              ],
            );
          },
        ),
        AnimatedSwitcher(
          duration: BuyV2Motion.resolved(context, BuyV2Motion.stateChange),
          child: _selectedIntent == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey('buy-assist-intent-$_selectedIntent'),
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: BuyV2Colors.softGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_selectedIntent selected. Add details below or choose a secure channel.',
                      style: const TextStyle(
                        color: BuyV2Colors.green,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 9),
        AnimatedContainer(
          key: const ValueKey('buy-assist-composer'),
          duration: BuyV2Motion.resolved(context, BuyV2Motion.stateChange),
          padding: const EdgeInsets.fromLTRB(12, 4, 5, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: _composerFocused ? BuyV2Colors.royal : BuyV2Colors.line,
              width: _composerFocused ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B000040),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            key: const ValueKey('buy-assist-composer-field'),
            controller: _composerController,
            focusNode: _composerFocus,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _prepareQuestion(),
            style: context.buyBody.copyWith(fontSize: 10),
            decoration: InputDecoration(
              hintText: 'Describe what you need help with',
              hintStyle: context.buyMeta.copyWith(fontSize: 9),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: IconButton(
                key: const ValueKey('buy-assist-prepare-question'),
                tooltip: 'Prepare question for in-app support',
                onPressed: _composerController.text.trim().isEmpty
                    ? null
                    : _prepareQuestion,
                style: BuyV2ActionStyle.button(
                  IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    maximumSize: const Size(44, 44),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
                icon: const Icon(Icons.arrow_upward_rounded, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Choose a secure channel',
          style: context.buyTitle.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 6),
        _AssistChannel(
          icon: Icons.chat_outlined,
          title: 'Chat in app',
          detail: 'Continue with support',
          onTap: () {
            HapticFeedback.selectionClick();
            FocusScope.of(context).unfocus();
            widget.onOpenChat(
              intent: _selectedIntent,
              details: _composerController.text,
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: BuyV2Colors.green,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Order details stay inside MoolSocial.',
                textAlign: TextAlign.center,
                style: context.buyMeta.copyWith(fontSize: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class BuyV2AccountView extends StatelessWidget {
  const BuyV2AccountView({
    super.key,
    required this.session,
    this.accountIdentity,
    this.accountAuthenticated = false,
  });

  final BuyV2Session session;
  final AuthenticatedAccountIdentity? accountIdentity;
  final bool accountAuthenticated;

  @override
  Widget build(BuildContext context) {
    final address = session.selectedAddressOrNull;
    return ListView(
      key: const PageStorageKey('buy-account'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [
        _ReturnAffordance(label: 'Back', onTap: session.closeAccount),
        const SizedBox(height: 8),
        Container(
          key: const ValueKey('buy-account-hub'),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: BuyV2ActionStyle.gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: BuyV2Colors.orange, width: 2),
                ),
                child: Text(
                  _buyAccountViewInitials(
                    accountIdentity?.primaryLabel ??
                        (accountAuthenticated
                            ? 'MoolSocial member'
                            : 'MoolSocial guest'),
                  ),
                  style: const TextStyle(
                    color: BuyV2Colors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accountIdentity?.primaryLabel ??
                          (accountAuthenticated
                              ? 'MoolSocial member'
                              : 'MoolSocial guest'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      accountIdentity?.detailLabel ??
                          (accountAuthenticated
                              ? 'Signed in to MoolSocial'
                              : 'Sign in to keep your activity with you'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (address == null)
          _AddressSelectionRequired(
            session: session,
            title: 'Delivery address needed',
            detail: 'Choose or add the address to use for your next order.',
            embedded: true,
          )
        else
          _SavedAddressReminder(
            address: address,
            onEdit: () => showBuyV2AddressSheet(context, session),
          ),
        const SizedBox(height: 8),
        _AccountActionRow(
          key: const ValueKey('buy-account-payment'),
          icon: Icons.account_balance_wallet_outlined,
          title: 'Payment',
          detail: session.selectedPayment,
          onTap: () => showBuyV2PaymentSheet(context, session),
        ),
        _AccountActionRow(
          key: const ValueKey('buy-account-orders'),
          icon: Icons.receipt_long_outlined,
          title: 'Orders',
          detail:
              '${session.activeOrderCount} active · ${session.deliveredOrderCount} delivered',
          onTap: session.openOrdersFromAccount,
        ),
        _AccountActionRow(
          key: const ValueKey('buy-account-prescriptions'),
          icon: Icons.description_outlined,
          title: 'Prescriptions',
          detail: session.prescriptionAttached
              ? '${session.approvedPrescriptionProductCount} matched medicines available'
              : 'Saved family medicine records',
          onTap: () => showBuyV2PrescriptionSheet(context, session),
        ),
        _AccountActionRow(
          key: const ValueKey('buy-account-workspace'),
          icon: Icons.storefront_outlined,
          title: 'Wholesale business profile',
          detail: session.businessVerified
              ? 'Shree Balaji Retail · Business profile complete'
              : 'Business profile required',
          onTap: session.openWholesaleFromAccount,
        ),
        _AccountActionRow(
          key: const ValueKey('buy-account-identity'),
          icon: Icons.badge_outlined,
          title: 'Identity & documents',
          detail: 'Documents and permissions',
          onTap: () => context.push('/app/account/identity'),
        ),
        _AccountActionRow(
          key: const ValueKey('buy-account-security'),
          icon: Icons.security_outlined,
          title: accountAuthenticated
              ? 'Sign out or switch account'
              : 'Sign in to MoolSocial',
          detail: accountAuthenticated
              ? 'Account security and connected services'
              : 'Use one identity across MoolSocial',
          onTap: () => context.push('/app/account/security'),
        ),
      ],
    );
  }
}

String _buyAccountViewInitials(String label) {
  final words = label
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return 'MS';
  if (words.length > 1) {
    return words
        .take(2)
        .map((word) => String.fromCharCode(word.runes.first))
        .join()
        .toUpperCase();
  }
  return String.fromCharCodes(words.single.runes.take(2)).toUpperCase();
}

class _AccountActionRow extends StatelessWidget {
  const _AccountActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $detail',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(13),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: buyV2CardDecoration(radius: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BuyV2Colors.softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: BuyV2Colors.navy, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.buyBody),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.buyMeta,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: BuyV2Colors.muted,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BuyV2FilterSheetAction {
  const BuyV2FilterSheetAction({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
}

Future<void> showBuyV2FilterSheet(
  BuildContext context,
  BuyV2Session session, {
  List<BuyV2FilterSheetAction> actions = const [],
}) async {
  final destination = session.destination;
  final selectedFilter = session.selectedFilter;
  final hasRefinement = destination != BuyV2Destination.orders;
  final routeLabel = actions.isEmpty && !hasRefinement
      ? '${destination.label} filters'
      : '${destination.label} tools and filters';
  final options = switch (destination) {
    BuyV2Destination.shop => const [
      ('any', 'Any delivery time', 'Show every available product'),
      ('fast', 'Fast delivery', 'Nearby delivery first'),
      ('today', 'Delivered today', 'Confirmed same-day listings'),
      (
        'quick-local',
        'Quick local delivery',
        'Nearby delivery with a confirmed short delivery window',
      ),
      (
        'standard-courier',
        'Standard/courier delivery',
        'Scheduled local or remote delivery with a confirmed date or window',
      ),
      ('lowest', 'Lowest delivered price', 'Price including delivery'),
      ('nearby', 'Nearby sellers', 'Nearby Mool partners'),
      ('returns', 'Easy returns', 'Listings with a clear return option'),
    ],
    BuyV2Destination.wholesale => const [
      ('any', 'Any delivery schedule', 'Show every confirmed trade listing'),
      ('fast', 'Fastest delivery', 'Earliest confirmed dispatch first'),
      ('two-days', 'Within two days', 'Nearby and priority supply'),
      (
        'bulk-freight',
        'Bulk freight',
        'Tracked delivery for minimum orders and bulk loads',
      ),
      ('lowest', 'Lowest landed price', 'Product and freight together'),
      ('freight', 'Freight included', 'Delivered price without hidden freight'),
      ('moq', 'Flexible minimums', 'Lower minimum-order listings'),
      ('manufacturer', 'Manufacturer direct', 'Mool manufacturer partners'),
    ],
    BuyV2Destination.medicine => const [
      ('any', 'Any delivery time', 'Show every available health product'),
      ('fast', 'Fastest pharmacy delivery', 'Nearby licensed pharmacies'),
      ('today', 'Delivered today', 'Confirmed same-day medicine supply'),
      ('lowest', 'Lowest delivered price', 'Price including delivery'),
      ('otc', 'No prescription required', 'Listed non-prescription products'),
      ('nearby', 'Nearby pharmacy', 'Licensed local pharmacies'),
      (
        'manufacturer',
        'Manufacturer sealed packs',
        'Sealed packs dispensed by licensed pharmacies',
      ),
    ],
    BuyV2Destination.orders => const <(String, String, String)>[],
  };
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(
      maxWidth: BuyV2FilterSheetMotion.maxWidth,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: BuyV2FilterSheetMotion.resolve(context),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: BuyV2FilterSheetMotion.initialChildSize,
      minChildSize: BuyV2FilterSheetMotion.minChildSize,
      maxChildSize: BuyV2FilterSheetMotion.maxChildSize,
      builder: (sheetContext, controller) => SafeArea(
        top: false,
        child: Semantics(
          key: const ValueKey('buy-filter-sheet-route'),
          container: true,
          scopesRoute: true,
          namesRoute: true,
          label: routeLabel,
          explicitChildNodes: true,
          child: RepaintBoundary(
            key: const ValueKey('buy-filter-sheet-repaint-boundary'),
            child: ListView(
              key: const ValueKey('buy-filter-list'),
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routeLabel,
                            key: const ValueKey('buy-filter-sheet-title'),
                            style: sheetContext.buyTitle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            actions.isEmpty && !hasRefinement
                                ? 'Choose one filter for this catalogue.'
                                : 'Use one tool or choose one catalogue filter.',
                            style: sheetContext.buyMeta,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      key: const ValueKey('buy-filter-close'),
                      tooltip: 'Close filters',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        maximumSize: const Size(44, 44),
                        foregroundColor: BuyV2Colors.navy,
                        backgroundColor: BuyV2Colors.softBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (actions.isNotEmpty || hasRefinement) ...[
                  Text('Tools', style: sheetContext.buyEyebrow),
                  const SizedBox(height: 8),
                  if (hasRefinement)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _BuyV2FilterToolAction(
                        action: BuyV2FilterSheetAction(
                          keyName: 'buy-discovery-refinement',
                          icon: Icons.tune_rounded,
                          title: 'Sort and refine',
                          detail: session.activeDiscoveryRefinementCount == 0
                              ? 'Brand, price, pack, availability and delivery'
                              : '${session.activeDiscoveryRefinementCount} selected',
                          onTap: () {},
                        ),
                        onTap: () async {
                          final routeCompleted = ModalRoute.of(
                            sheetContext,
                          )?.completed;
                          Navigator.of(sheetContext).pop();
                          if (routeCompleted != null) await routeCompleted;
                          if (session.destination != destination ||
                              !context.mounted) {
                            return;
                          }
                          await showBuyV2DiscoveryRefinementSheet(
                            context,
                            session,
                          );
                        },
                      ),
                    ),
                  for (final action in actions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _BuyV2FilterToolAction(
                        action: action,
                        onTap: () async {
                          final routeCompleted = ModalRoute.of(
                            sheetContext,
                          )?.completed;
                          Navigator.of(sheetContext).pop();
                          if (routeCompleted != null) await routeCompleted;
                          if (session.destination != destination) return;
                          action.onTap();
                        },
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Divider(height: 1, color: BuyV2Colors.line),
                  const SizedBox(height: 12),
                  Text('Catalogue filters', style: sheetContext.buyEyebrow),
                  const SizedBox(height: 8),
                ],
                for (final option in options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BuyV2FilterOption(
                      option: option,
                      selected:
                          (option.$1 == 'any' && selectedFilter == null) ||
                          selectedFilter == option.$1,
                      onTap: () async {
                        final routeCompleted = ModalRoute.of(
                          sheetContext,
                        )?.completed;
                        Navigator.of(sheetContext).pop();
                        if (routeCompleted != null) await routeCompleted;
                        if (session.destination != destination) return;
                        session.chooseFilter(
                          option.$1 == 'any' ? null : option.$1,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> showBuyV2DiscoveryRefinementSheet(
  BuildContext context,
  BuyV2Session session, {
  List<BuyV2FilterSheetAction> actions = const [],
}) async {
  final destination = session.destination;
  if (destination == BuyV2Destination.orders) return;
  final savedOnly = session.showingSavedProducts;
  String browseScope() =>
      '${session.destination.name}|${session.saleTypeSignature}|'
      '${session.selectedCategoryId}|${session.query}|'
      '${session.catalogueRegionId}|${session.catalogueAreaScope.name}|'
      '${session.showingSavedProducts}|${session.activeShoppingIntent?.name}';
  final originalScope = browseScope();
  final current = session.discoveryRefinements;
  var draft = BuyV2DiscoveryRefinements(
    brands: current.brands,
    maximumPrice: current.maximumPrice,
    pack: destination == BuyV2Destination.wholesale ? null : current.pack,
    filter: destination == BuyV2Destination.medicine ? current.filter : null,
    fulfilmentMode: destination == BuyV2Destination.medicine
        ? current.fulfilmentMode
        : null,
    sort: current.sort == BuyV2ProductSort.deliveryFastest
        ? BuyV2ProductSort.relevance
        : current.sort,
    availableOnly: current.availableOnly,
  );
  final brands = {...session.discoveryBrands, ...current.brands}.toList()
    ..sort();
  const packFilters = [BuyV2PackFilter.standard, BuyV2PackFilter.multipack];
  final previewScope = 'refinement-preview-${destination.name}';
  final preview =
      session.pagedCatalogueEnabled &&
          !savedOnly &&
          !session.showingMonthlyBasketProducts
      ? session.acquireCatalogueProducts(previewScope)
      : null;
  if (preview != null) {
    unawaited(preview.open(session.catalogueQuery(refinements: draft)));
  }
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(
        maxWidth: BuyV2FilterSheetMotion.maxWidth,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      sheetAnimationStyle: BuyV2FilterSheetMotion.resolve(context),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => AnimatedBuilder(
          animation: Listenable.merge([session, ?preview]),
          builder: (sheetContext, _) {
            final scopeMatches = browseScope() == originalScope;
            final productCount = savedOnly
                ? session.previewSavedProducts(draft).length
                : preview == null
                ? session.previewDiscoveryProducts(draft).length
                : preview.loading || preview.message != null
                ? null
                : preview.page?.totalCount;
            void update(BuyV2DiscoveryRefinements value) {
              setSheetState(() => draft = value);
              if (preview != null && scopeMatches) {
                unawaited(
                  preview.open(session.catalogueQuery(refinements: value)),
                );
              }
            }

            return FractionallySizedBox(
              heightFactor: .92,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sort & filter',
                                  key: const ValueKey(
                                    'buy-discovery-refinement-title',
                                  ),
                                  style: sheetContext.buyTitle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  scopeMatches
                                      ? productCount != null
                                            ? '${savedOnly ? 'Saved: ' : ''}${_productCountLabel(productCount)} found'
                                            : preview?.loading == true
                                            ? 'Checking matching products…'
                                            : 'Count unavailable. Apply to view results.'
                                      : 'Your browsing choices changed. Reopen filters.',
                                  key: const ValueKey(
                                    'buy-discovery-refinement-count',
                                  ),
                                  style: sheetContext.buyMeta,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: const ValueKey(
                              'buy-discovery-refinement-close',
                            ),
                            tooltip: 'Close sort and filters',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: BuyV2Colors.line),
                    Expanded(
                      child: ListView(
                        key: const ValueKey('buy-discovery-refinement-list'),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        children: [
                          _DiscoveryRefinementSection(
                            id: 'sort',
                            title: 'Sort by',
                            summary: _buyV2ProductSortLabel(draft.sort),
                            children: [
                              for (final sort in const [
                                BuyV2ProductSort.relevance,
                                BuyV2ProductSort.priceLowToHigh,
                                BuyV2ProductSort.priceHighToLow,
                              ])
                                _DiscoveryChoice(
                                  key: ValueKey('buy-sort-${sort.name}'),
                                  label: _buyV2ProductSortLabel(sort),
                                  selected: draft.sort == sort,
                                  onTap: () =>
                                      update(draft.copyWith(sort: sort)),
                                ),
                            ],
                          ),
                          _DiscoveryRefinementSection(
                            id: 'price',
                            title: 'Pack price',
                            summary: draft.maximumPrice == null
                                ? 'Any price'
                                : 'Up to ${buyV2Money(draft.maximumPrice!)}',
                            children: [
                              _DiscoveryChoice(
                                key: const ValueKey('buy-refine-price-any'),
                                label: 'Any price',
                                selected: draft.maximumPrice == null,
                                onTap: () =>
                                    update(draft.copyWith(clearPrice: true)),
                              ),
                              for (final limit in session.discoveryPriceLimits)
                                _DiscoveryChoice(
                                  key: ValueKey('buy-refine-price-$limit'),
                                  label: 'Up to ${buyV2Money(limit)}',
                                  selected: draft.maximumPrice == limit,
                                  onTap: () => update(
                                    draft.copyWith(maximumPrice: limit),
                                  ),
                                ),
                            ],
                          ),
                          if (destination != BuyV2Destination.wholesale)
                            _DiscoveryRefinementSection(
                              id: 'pack',
                              title: 'Pack size',
                              summary: draft.pack == null
                                  ? 'Any pack'
                                  : _buyV2PackFilterLabel(draft.pack!),
                              children: [
                                _DiscoveryChoice(
                                  key: const ValueKey('buy-refine-pack-any'),
                                  label: 'Any pack',
                                  selected: draft.pack == null,
                                  onTap: () =>
                                      update(draft.copyWith(clearPack: true)),
                                ),
                                for (final pack in packFilters)
                                  _DiscoveryChoice(
                                    key: ValueKey(
                                      'buy-refine-pack-${pack.name}',
                                    ),
                                    label: _buyV2PackFilterLabel(pack),
                                    selected: draft.pack == pack,
                                    onTap: () =>
                                        update(draft.copyWith(pack: pack)),
                                  ),
                              ],
                            ),
                          _DiscoveryRefinementSection(
                            id: 'brand',
                            title: 'Brand',
                            summary: brands.isEmpty
                                ? 'Not provided'
                                : draft.brands.isEmpty
                                ? 'Any brand'
                                : draft.brands.length == 1
                                ? draft.brands.single
                                : '${draft.brands.length} selected',
                            children: [
                              if (brands.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Brand details have not been provided for these products.',
                                    key: ValueKey(
                                      'buy-refine-brand-unavailable',
                                    ),
                                  ),
                                ),
                              for (final brand in brands)
                                _DiscoveryChoice(
                                  key: ValueKey(
                                    'buy-refine-brand-${brand.toLowerCase().replaceAll(' ', '-')}',
                                  ),
                                  label: brand,
                                  selected: draft.brands.contains(brand),
                                  onTap: () {
                                    final selected = {...draft.brands};
                                    if (!selected.remove(brand)) {
                                      selected.add(brand);
                                    }
                                    update(draft.copyWith(brands: selected));
                                  },
                                ),
                            ],
                          ),
                          SwitchListTile.adaptive(
                            key: const ValueKey(
                              'buy-refine-available-products',
                            ),
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Available to order'),
                            value: draft.availableOnly,
                            onChanged: (value) =>
                                update(draft.copyWith(availableOnly: value)),
                          ),
                          if (actions.isNotEmpty)
                            _DiscoveryRefinementSection(
                              id: 'tools',
                              title: 'Shopping tools',
                              summary: 'Orders, activity and settings',
                              children: [
                                for (final action in actions)
                                  _BuyV2FilterToolAction(
                                    action: action,
                                    onTap: () async {
                                      final completed = ModalRoute.of(
                                        sheetContext,
                                      )?.completed;
                                      Navigator.of(sheetContext).pop();
                                      if (completed != null) await completed;
                                      if (!context.mounted ||
                                          browseScope() != originalScope) {
                                        return;
                                      }
                                      action.onTap();
                                    },
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: BuyV2Colors.line),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              widthFactor: 1,
                              heightFactor: 1,
                              child: OutlinedButton(
                                key: const ValueKey(
                                  'buy-discovery-refinement-clear',
                                ),
                                onPressed: draft.count == 0
                                    ? null
                                    : () => update(BuyV2DiscoveryRefinements()),
                                style: BuyV2ActionStyle.button(
                                  OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                child: const Text('Clear'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Align(
                              widthFactor: 1,
                              heightFactor: 1,
                              child: FilledButton(
                                key: const ValueKey(
                                  'buy-discovery-refinement-done',
                                ),
                                onPressed: !scopeMatches
                                    ? null
                                    : () {
                                        session.applyDiscoveryRefinements(
                                          draft,
                                        );
                                        Navigator.of(sheetContext).pop();
                                      },
                                style: BuyV2ActionStyle.button(
                                  FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                child: const Text('Apply'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  } finally {
    if (preview != null) session.releaseCatalogueProducts(previewScope);
  }
}

class _DiscoveryRefinementSection extends StatelessWidget {
  const _DiscoveryRefinementSection({
    required this.id,
    required this.title,
    required this.summary,
    required this.children,
  });

  final String id;
  final String title;
  final String summary;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: ValueKey('buy-refine-section-$id'),
    tilePadding: EdgeInsets.zero,
    dense: true,
    minTileHeight: 48,
    visualDensity: VisualDensity.compact,
    childrenPadding: const EdgeInsets.only(bottom: 4),
    title: Text(title, style: Theme.of(context).textTheme.titleSmall),
    subtitle: Text(summary, style: context.buyMeta),
    shape: const Border(bottom: BorderSide(color: BuyV2Colors.line)),
    collapsedShape: const Border(bottom: BorderSide(color: BuyV2Colors.line)),
    children: [
      for (final child in children)
        Padding(padding: const EdgeInsets.only(bottom: 4), child: child),
    ],
  );
}

class _DiscoveryChoice extends StatelessWidget {
  const _DiscoveryChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: selected
              ? BuyV2ActionStyle.pressedFill
              : BuyV2ActionStyle.primaryFill,
        ),
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: BuyV2ActionStyle.primaryForeground,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                    color: BuyV2ActionStyle.primaryForeground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

String _buyV2ProductSortLabel(BuyV2ProductSort value) => switch (value) {
  BuyV2ProductSort.relevance => 'Relevance',
  BuyV2ProductSort.priceLowToHigh => 'Price: low to high',
  BuyV2ProductSort.priceHighToLow => 'Price: high to low',
  BuyV2ProductSort.deliveryFastest => 'Fastest delivery',
};

String _buyV2PackFilterLabel(BuyV2PackFilter value) => switch (value) {
  BuyV2PackFilter.standard => 'Standard pack',
  BuyV2PackFilter.multipack => 'Multipack',
  BuyV2PackFilter.bulk => 'Bulk pack',
};

class _BuyV2FilterToolAction extends StatelessWidget {
  const _BuyV2FilterToolAction({required this.action, required this.onTap});

  final BuyV2FilterSheetAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey(action.keyName),
      container: true,
      button: true,
      label: '${action.title}, ${action.detail}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: BuyV2Colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: BuyV2Colors.softBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(action.icon, size: 20, color: BuyV2Colors.navy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(action.title, style: context.buyBody),
                        const SizedBox(height: 2),
                        Text(action.detail, style: context.buyMeta),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: BuyV2Colors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BuyV2FilterOption extends StatelessWidget {
  const _BuyV2FilterOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final (String, String, String) option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey('buy-filter-semantics-${option.$1}'),
      container: true,
      button: true,
      selected: selected,
      label: '${option.$2}${selected ? ', selected' : ''}',
      hint: option.$3,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected
            ? BuyV2ActionStyle.pressedFill
            : BuyV2ActionStyle.primaryFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? BuyV2ActionStyle.primaryForeground
                : BuyV2Colors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('buy-filter-${option.$1}'),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BuyV2ActionStyle.primaryFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : Icons.tune_rounded,
                      color: selected
                          ? BuyV2ActionStyle.primaryForeground
                          : BuyV2ActionStyle.primaryForeground,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(option.$2, style: context.buyBody),
                        const SizedBox(height: 2),
                        Text(option.$3, style: context.buyMeta),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected
                        ? BuyV2ActionStyle.primaryForeground
                        : BuyV2Colors.muted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showBuyV2PaymentSheet(
  BuildContext context,
  BuyV2Session session,
) async {
  final destination = session.destination;
  final view = session.view;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(
      maxWidth: BuyV2PaymentSheetMotion.maxWidth,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: BuyV2PaymentSheetMotion.resolve(context),
    builder: (sheetContext) => ListenableBuilder(
      listenable: session,
      builder: (sheetContext, _) {
        final choices = _buyV2CustomerPaymentChoices(session);
        return Semantics(
          key: const ValueKey('buy-payment-sheet-route'),
          container: true,
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: 'Payment methods',
          child: RepaintBoundary(
            key: const ValueKey('buy-payment-sheet-repaint-boundary'),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.sizeOf(sheetContext).height *
                    BuyV2PaymentSheetMotion.maxHeightFactor,
              ),
              child: ListView(
                key: const ValueKey('buy-payment-sheet-list'),
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  18 +
                      BuyV2AddressSheetMotion.resolveModalActionBottomInset(
                        sheetContext,
                      ),
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment methods',
                              key: const ValueKey('buy-payment-sheet-title'),
                              style: sheetContext.buyTitle,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Choose a payment method for this purchase.',
                              style: sheetContext.buyMeta,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        key: const ValueKey('buy-payment-close'),
                        tooltip: 'Close payment methods',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          maximumSize: const Size(44, 44),
                          foregroundColor: BuyV2Colors.navy,
                          backgroundColor: BuyV2Colors.softBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (choices.isEmpty)
                    Container(
                      key: const ValueKey('buy-payment-unavailable'),
                      padding: const EdgeInsets.all(12),
                      decoration: buyV2CardDecoration(
                        color: BuyV2Colors.softOrange,
                        border: BuyV2Colors.orange,
                        radius: 14,
                      ),
                      child: Text(
                        'Payment methods are unavailable right now. Return to Checkout and try again.',
                        style: sheetContext.buyMeta,
                      ),
                    ),
                  for (final choice in choices)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _BuyV2PaymentChoice(
                        choice: choice,
                        selected: session.selectedPayment == choice.$1,
                        onTap:
                            session.checkoutBusy ||
                                !session
                                    .paymentEligibilityFor(choice.$1)
                                    .selectable
                            ? null
                            : () async {
                                HapticFeedback.selectionClick();
                                final routeCompleted = ModalRoute.of(
                                  sheetContext,
                                )?.completed;
                                Navigator.of(sheetContext).pop();
                                if (routeCompleted != null) {
                                  await routeCompleted;
                                }
                                if (session.destination != destination ||
                                    session.view != view) {
                                  return;
                                }
                                session.choosePayment(choice.$1);
                              },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _BuyV2PaymentChoice extends StatelessWidget {
  const _BuyV2PaymentChoice({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final (String, IconData, String) choice;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = selected
        ? '${choice.$1}, selected, ${choice.$3}'
        : '${choice.$1}, ${choice.$3}';
    return Semantics(
      key: ValueKey('buy-payment-semantics-${choice.$1}'),
      container: true,
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? BuyV2ActionStyle.pressedFill
              : BuyV2ActionStyle.primaryFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected
                  ? BuyV2ActionStyle.primaryForeground
                  : BuyV2Colors.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('buy-payment-${choice.$1}'),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: BuyV2ActionStyle.primaryFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        choice.$2,
                        color: selected
                            ? BuyV2ActionStyle.primaryForeground
                            : BuyV2ActionStyle.primaryForeground,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            choice.$1,
                            style: const TextStyle(
                              color: BuyV2ActionStyle.primaryForeground,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(choice.$3, style: context.buyMeta),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected
                          ? BuyV2ActionStyle.primaryForeground
                          : BuyV2Colors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showBuyV2PrescriptionSheet(
  BuildContext context,
  BuyV2Session session,
) async {
  final destination = session.destination;
  final view = session.view;
  final pendingProductId = session.pendingPrescriptionProductId;
  final bottomViewPadding =
      BuyV2AddressSheetMotion.resolveModalActionBottomInset(context);

  Future<void> finishAfterReverse(
    BuildContext sheetContext,
    VoidCallback action,
  ) async {
    HapticFeedback.selectionClick();
    final routeCompleted = ModalRoute.of(sheetContext)?.completed;
    Navigator.of(sheetContext).pop();
    if (routeCompleted != null) await routeCompleted;
    if (session.destination != destination ||
        session.view != view ||
        session.pendingPrescriptionProductId != pendingProductId) {
      return;
    }
    action();
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(
      maxWidth: BuyV2PrescriptionSheetMotion.maxWidth,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: BuyV2PrescriptionSheetMotion.resolve(context),
    builder: (sheetContext) => Semantics(
      key: const ValueKey('buy-prescription-sheet-route'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Prescription centre',
      child: RepaintBoundary(
        key: const ValueKey('buy-prescription-sheet-repaint-boundary'),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(sheetContext).height *
                BuyV2PrescriptionSheetMotion.maxHeightFactor,
          ),
          child: ListView(
            key: const ValueKey('buy-prescription-sheet-list'),
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 18 + bottomViewPadding),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  const heading = 'Add your prescription';
                  final title = Text(
                    heading,
                    key: const ValueKey('buy-prescription-sheet-title'),
                    style: sheetContext.buyTitle,
                  );
                  final detail = Text(
                    'Use a saved prescription or add one for medicine matching in this session. Pharmacist review is still required before payment.',
                    style: sheetContext.buyMeta,
                  );
                  final close = IconButton(
                    key: const ValueKey('buy-prescription-close'),
                    tooltip: 'Close prescription centre',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      maximumSize: const Size(44, 44),
                      foregroundColor: BuyV2Colors.navy,
                      backgroundColor: BuyV2Colors.softBlue,
                    ),
                  );
                  final longestWord = heading.split(' ').fold<double>(0, (
                    width,
                    word,
                  ) {
                    final measured = buyV2ValueTextSize(
                      sheetContext,
                      word,
                      sheetContext.buyTitle,
                    ).width;
                    return measured > width ? measured : width;
                  });
                  if (longestWord > constraints.maxWidth - 52) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 3),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: detail),
                            const SizedBox(width: 8),
                            close,
                          ],
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [title, const SizedBox(height: 3), detail],
                        ),
                      ),
                      const SizedBox(width: 8),
                      close,
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              _PrescriptionChoice(
                keyName: 'meera',
                doctor: 'Dr Meera Sharma',
                detail: 'Heart & BP · issued 08 July 2026',
                onTap: () => finishAfterReverse(
                  sheetContext,
                  () => session.approveSavedPrescription('meera'),
                ),
              ),
              const SizedBox(height: 8),
              _PrescriptionChoice(
                keyName: 'arvind',
                doctor: 'Dr Arvind Joshi',
                detail: 'Diabetes · issued 19 June 2026',
                onTap: () => finishAfterReverse(
                  sheetContext,
                  () => session.approveSavedPrescription('arvind'),
                ),
              ),
              const SizedBox(height: 8),
              _AddPrescriptionChoice(
                onTap: () => finishAfterReverse(
                  sheetContext,
                  session.attachNewPrescription,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showBuyV2AddressSheet(
  BuildContext context,
  BuyV2Session session, {
  bool continueToCheckoutAfterSelection = false,
}) async {
  final destination = session.destination;
  final view = session.view;
  final selectedAddressId = session.selectedAddressId;
  final addresses = session.addresses;
  final bottomViewPadding = BuyV2AddressSheetMotion.resolveBottomSafeInset(
    context,
  );

  Future<void> chooseAfterReverse(
    BuildContext sheetContext,
    String addressId,
  ) async {
    HapticFeedback.selectionClick();
    final routeCompleted = ModalRoute.of(sheetContext)?.completed;
    Navigator.of(sheetContext).pop();
    if (routeCompleted != null) await routeCompleted;
    if (session.destination != destination ||
        session.view != view ||
        session.selectedAddressId != selectedAddressId ||
        !session.addresses.any((address) => address.id == addressId)) {
      return;
    }
    if (session.chooseAddress(addressId) && continueToCheckoutAfterSelection) {
      session.openCheckout();
    }
  }

  Future<void> addAndContinue(BuildContext sheetContext) async {
    final previousAddressId = session.selectedAddressId;
    await _showAddAddressSheet(sheetContext, session);
    if (!continueToCheckoutAfterSelection ||
        session.selectedAddressId == previousAddressId ||
        !sheetContext.mounted) {
      return;
    }
    final routeCompleted = ModalRoute.of(sheetContext)?.completed;
    Navigator.of(sheetContext).pop();
    if (routeCompleted != null) await routeCompleted;
    if (session.destination == destination && session.view == view) {
      session.openCheckout();
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(
      maxWidth: BuyV2AddressSheetMotion.maxWidth,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: BuyV2AddressSheetMotion.resolve(context),
    builder: (sheetContext) => Semantics(
      key: const ValueKey('buy-address-sheet-route'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Delivery addresses',
      child: RepaintBoundary(
        key: const ValueKey('buy-address-sheet-repaint-boundary'),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(sheetContext).height *
                BuyV2AddressSheetMotion.maxHeightFactor,
          ),
          child: ListView(
            key: const ValueKey('buy-address-sheet-list'),
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 18 + bottomViewPadding),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose delivery address',
                          key: const ValueKey('buy-address-sheet-title'),
                          style: sheetContext.buyTitle,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Select a saved address or add another place.',
                          style: sheetContext.buyMeta,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const ValueKey('buy-address-close'),
                    tooltip: 'Close delivery addresses',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      maximumSize: const Size(44, 44),
                      foregroundColor: BuyV2Colors.navy,
                      backgroundColor: BuyV2Colors.softBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (addresses.isEmpty)
                Container(
                  key: const ValueKey('buy-address-empty'),
                  padding: const EdgeInsets.all(14),
                  decoration: buyV2CardDecoration(
                    color: BuyV2Colors.softBlue,
                    radius: 16,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_off_outlined,
                        color: BuyV2Colors.navy,
                        size: 26,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'No saved addresses',
                        textAlign: TextAlign.center,
                        style: sheetContext.buyBody,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Request an address or add one manually to continue.',
                        textAlign: TextAlign.center,
                        style: sheetContext.buyMeta,
                      ),
                    ],
                  ),
                )
              else
                for (final address in addresses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BuyV2AddressChoice(
                      address: address,
                      selected: selectedAddressId == address.id,
                      onTap: () => chooseAfterReverse(sheetContext, address.id),
                      onEdit: () => _showAddAddressSheet(
                        sheetContext,
                        session,
                        existingAddress: address,
                      ),
                      onDelete: () async {
                        final remove = await showDialog<bool>(
                          context: sheetContext,
                          builder: (dialogContext) => AlertDialog(
                            title: Text('Remove ${address.label} address?'),
                            content: const Text(
                              'Existing orders stay unchanged. You can add this address again later.',
                            ),
                            actions: [
                              TextButton(
                                key: const ValueKey(
                                  'buy-address-delete-cancel',
                                ),
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                child: const Text('Keep address'),
                              ),
                              Align(
                                widthFactor: 1,
                                heightFactor: 1,
                                child: FilledButton(
                                  style: BuyV2ActionStyle.button(),
                                  key: const ValueKey(
                                    'buy-address-delete-confirm',
                                  ),
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text('Remove'),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (remove != true || !sheetContext.mounted) return;
                        if (session.removeAddress(address.id)) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                    ),
                  ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: BuyV2Metrics.minimumTap,
                child: Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: OutlinedButton.icon(
                    style: BuyV2ActionStyle.button(),
                    key: const ValueKey('buy-address-request'),
                    onPressed: () =>
                        _showAddressRequestSheet(sheetContext, session),
                    icon: const Icon(Icons.ios_share_outlined, size: 18),
                    label: const Text('Request an address'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: BuyV2Metrics.minimumTap,
                child: Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: FilledButton.icon(
                    style: BuyV2ActionStyle.button(),
                    key: const ValueKey('buy-address-add'),
                    onPressed: () => addAndContinue(sheetContext),
                    icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                    label: const Text('Add new address'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BuyV2AddressChoice extends StatelessWidget {
  const _BuyV2AddressChoice({
    required this.address,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final BuyV2Address address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final detail =
        '${address.recipient}, ${address.phone}, ${address.line}, '
        '${address.shortLine}, ${address.landmark}';
    final semanticsLabel = selected
        ? '${address.label}, selected, $detail'
        : '${address.label}, $detail';
    final icon = switch (address.kind) {
      BuyV2AddressKind.home => Icons.home_outlined,
      BuyV2AddressKind.work => Icons.work_outline_rounded,
      BuyV2AddressKind.thirdParty => Icons.group_outlined,
      BuyV2AddressKind.other => Icons.location_on_outlined,
    };
    final actionsKey = GlobalKey<PopupMenuButtonState<String>>();
    return Material(
      color: selected
          ? BuyV2ActionStyle.pressedFill
          : BuyV2ActionStyle.primaryFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? BuyV2ActionStyle.primaryForeground
              : BuyV2Colors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 82),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                key: ValueKey('buy-address-semantics-${address.id}'),
                container: true,
                button: true,
                selected: selected,
                label: semanticsLabel,
                onTap: onTap,
                child: ExcludeSemantics(
                  child: InkWell(
                    key: ValueKey('buy-address-${address.id}'),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 10, 8, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: BuyV2ActionStyle.primaryFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: selected
                                  ? BuyV2ActionStyle.primaryForeground
                                  : BuyV2ActionStyle.primaryForeground,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        address.label,
                                        style: const TextStyle(
                                          color: BuyV2ActionStyle
                                              .primaryForeground,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      Container(
                                        key: ValueKey(
                                          'buy-address-selected-${address.id}',
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: BuyV2Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          'Selected',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${address.recipient} · ${address.phone}',
                                  style: context.buyMeta.copyWith(
                                    color: BuyV2Colors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${address.line}, ${address.shortLine} · ${address.landmark}',
                                  style: context.buyMeta,
                                ),
                              ],
                            ),
                          ),
                          if (!selected) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: BuyV2ActionStyle.primaryForeground,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 54,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: BuyV2Colors.line,
              ),
            ),
            Semantics(
              key: ValueKey('buy-address-actions-${address.id}'),
              button: true,
              label: 'Manage ${address.label} address',
              onTap: () => actionsKey.currentState?.showButtonMenu(),
              child: PopupMenuButton<String>(
                key: actionsKey,
                tooltip: 'Manage ${address.label} address',
                constraints: const BoxConstraints(minWidth: 170),
                onSelected: (action) {
                  if (action == 'edit') {
                    onEdit();
                  } else if (action == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    key: ValueKey('buy-address-edit-${address.id}'),
                    value: 'edit',
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 19),
                        SizedBox(width: 9),
                        Text('Edit address'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    key: ValueKey('buy-address-delete-${address.id}'),
                    value: 'delete',
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 19),
                        SizedBox(width: 9),
                        Text('Remove address'),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAddressRequestSheet(
  BuildContext context,
  BuyV2Session session,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(
      maxWidth: BuyV2AddressFormSheetMotion.maxWidth,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: BuyV2AddressFormSheetMotion.resolve(context),
    routeSettings: const RouteSettings(name: 'buy-address-request-form'),
    builder: (sheetContext) => _BuyV2AddressRequestForm(session: session),
  );
}

Future<void> _showAddAddressSheet(
  BuildContext context,
  BuyV2Session session, {
  BuyV2Address? existingAddress,
  String initialRecipient = '',
}) {
  final destination = session.destination;
  final view = session.view;
  final selectedAddressId = session.selectedAddressId;

  bool saveToExistingOwner(BuyV2Address address) {
    if (session.destination != destination ||
        session.view != view ||
        session.selectedAddressId != selectedAddressId) {
      return false;
    }
    if (existingAddress == null) {
      session.addAddress(address);
      return true;
    }
    if (existingAddress.id != address.id) return false;
    return session.updateAddress(address);
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(
      maxWidth: BuyV2AddressFormSheetMotion.maxWidth,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: BuyV2AddressFormSheetMotion.resolve(context),
    routeSettings: const RouteSettings(name: 'buy-address-add-form'),
    builder: (sheetContext) => _BuyV2AddAddressForm(
      existingAddress: existingAddress,
      initialRecipient: initialRecipient,
      onSubmit: saveToExistingOwner,
    ),
  );
}

class _BuyV2AddressRequestForm extends StatefulWidget {
  const _BuyV2AddressRequestForm({required this.session});

  final BuyV2Session session;

  @override
  State<_BuyV2AddressRequestForm> createState() =>
      _BuyV2AddressRequestFormState();
}

class _BuyV2AddressRequestFormState extends State<_BuyV2AddressRequestForm> {
  final recipientController = TextEditingController();
  bool requestBusy = false;

  @override
  void dispose() {
    recipientController.dispose();
    super.dispose();
  }

  Future<void> requestAddress({required bool copyOnly}) async {
    if (requestBusy) return;
    FocusScope.of(context).unfocus();
    setState(() => requestBusy = true);
    final result = await widget.session.createAddressRequest(
      recipient: recipientController.text,
    );
    if (!mounted) return;
    final shareUri = result.shareUri;
    if (shareUri == null) {
      setState(() => requestBusy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.customerMessage)));
      return;
    }
    if (copyOnly) {
      await Clipboard.setData(ClipboardData(text: shareUri.toString()));
      if (!mounted) return;
      setState(() => requestBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Address request link copied. Paste it into a message.',
          ),
        ),
      );
      return;
    }
    final renderBox = context.findRenderObject() as RenderBox?;
    final origin = renderBox == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    try {
      await SharePlus.instance.share(
        ShareParams(
          uri: shareUri,
          title: 'Send delivery address',
          subject: 'MoolSocial delivery address request',
          sharePositionOrigin: origin,
          downloadFallbackEnabled: false,
          mailToFallbackEnabled: false,
        ),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharing is unavailable. Copy the link instead.'),
          ),
        );
      }
    }
    if (mounted) setState(() => requestBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        18 +
        BuyV2AddressFormSheetMotion.resolveBottomSafeInset(context) +
        MediaQuery.viewInsetsOf(context).bottom;
    return Semantics(
      key: const ValueKey('buy-address-request-form-route'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Request an address',
      child: RepaintBoundary(
        key: const ValueKey('buy-address-request-form-repaint-boundary'),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height *
                BuyV2AddressFormSheetMotion.requestMaxHeightFactor,
          ),
          child: ListView(
            key: const ValueKey('buy-address-request-form-list'),
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
            children: [
              _AddressFormHeader(
                title: 'Request an address',
                body:
                    'Create a secure request link and send it to the person receiving the order.',
                closeKey: const ValueKey('buy-address-request-form-close'),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Recipient name (optional)',
                child: TextField(
                  key: const ValueKey('buy-address-request-recipient'),
                  controller: recipientController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    label: ExcludeSemantics(
                      child: Text('Recipient name (optional)'),
                    ),
                    helperText: 'Helps you confirm who the request is for.',
                    helperMaxLines: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ShareChoice(
                    key: const ValueKey('buy-address-request-device-share'),
                    label: requestBusy ? 'Preparing…' : 'Share request',
                    icon: Icons.ios_share_outlined,
                    onTap: () => requestAddress(copyOnly: false),
                  ),
                  const SizedBox(width: 7),
                  _ShareChoice(
                    key: const ValueKey('buy-address-request-copy'),
                    label: 'Copy link',
                    icon: Icons.link_rounded,
                    onTap: () => requestAddress(copyOnly: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: BuyV2Metrics.minimumTap,
                child: Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: OutlinedButton(
                    style: BuyV2ActionStyle.button(),
                    key: const ValueKey('buy-address-request-enter-manually'),
                    onPressed: () => _showAddAddressSheet(
                      context,
                      widget.session,
                      initialRecipient: recipientController.text,
                    ),
                    child: const Text('Add it myself'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyV2AddAddressForm extends StatefulWidget {
  const _BuyV2AddAddressForm({
    required this.onSubmit,
    this.existingAddress,
    this.initialRecipient = '',
  });

  final bool Function(BuyV2Address address) onSubmit;
  final BuyV2Address? existingAddress;
  final String initialRecipient;

  @override
  State<_BuyV2AddAddressForm> createState() => _BuyV2AddAddressFormState();
}

class _BuyV2AddAddressFormState extends State<_BuyV2AddAddressForm> {
  late final TextEditingController recipientController;
  late final TextEditingController phoneController;
  late final TextEditingController lineController;
  late final TextEditingController pinController;
  late final TextEditingController areaController;
  late final TextEditingController landmarkController;

  late BuyV2AddressKind kind;
  String? validationMessage;

  @override
  void initState() {
    super.initState();
    final address = widget.existingAddress;
    recipientController = TextEditingController(
      text: address?.recipient ?? widget.initialRecipient,
    );
    phoneController = TextEditingController(text: address?.phone);
    lineController = TextEditingController(text: address?.line);
    pinController = TextEditingController(text: address?.pinCode);
    areaController = TextEditingController(text: address?.area);
    landmarkController = TextEditingController(text: address?.landmark);
    kind = address?.kind ?? BuyV2AddressKind.home;
  }

  @override
  void dispose() {
    recipientController.dispose();
    phoneController.dispose();
    lineController.dispose();
    pinController.dispose();
    areaController.dispose();
    landmarkController.dispose();
    super.dispose();
  }

  void submit() {
    FocusScope.of(context).unfocus();
    final recipient = recipientController.text.trim();
    final phone = phoneController.text.trim();
    final line = lineController.text.trim();
    final pin = pinController.text.trim();
    final area = areaController.text.trim();
    final landmark = landmarkController.text.trim();
    if (recipient.isEmpty || line.isEmpty || area.isEmpty) {
      setState(() {
        validationMessage = 'Add the recipient, street address and locality.';
      });
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      setState(() => validationMessage = 'Enter a 10-digit phone number.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      setState(() => validationMessage = 'Enter a valid 6-digit PIN code.');
      return;
    }
    final label = switch (kind) {
      BuyV2AddressKind.home => 'Home',
      BuyV2AddressKind.work => 'Work',
      BuyV2AddressKind.thirdParty => 'Third party',
      BuyV2AddressKind.other => 'Other place',
    };
    final existingAddress = widget.existingAddress;
    final added = widget.onSubmit(
      BuyV2Address(
        id:
            existingAddress?.id ??
            'saved-${DateTime.now().microsecondsSinceEpoch}',
        kind: kind,
        label: label,
        recipient: recipient,
        phone: phone,
        line: line,
        area: area,
        pinCode: pin,
        landmark: landmark.isEmpty ? 'No nearby landmark' : landmark,
      ),
    );
    if (!added) {
      setState(() {
        validationMessage =
            'The delivery session changed. Review the address before saving.';
      });
      return;
    }
    Navigator.of(context).popUntil((route) => route is PageRoute);
  }

  @override
  Widget build(BuildContext context) {
    final editingAddress = widget.existingAddress;
    final title = editingAddress == null
        ? 'Add delivery address'
        : 'Edit ${editingAddress.label} address';
    final bottomPadding =
        18 + BuyV2AddressFormSheetMotion.resolveBottomSafeInset(context);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    Widget input({
      required String id,
      required TextEditingController controller,
      required String label,
      TextInputType? keyboardType,
      TextInputAction action = TextInputAction.next,
      int minLines = 1,
      int maxLines = 1,
    }) {
      final field = Builder(
        builder: (fieldContext) => Focus(
          canRequestFocus: false,
          onFocusChange: (focused) {
            if (!focused) return;
            final focusedNode = FocusManager.instance.primaryFocus;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!fieldContext.mounted ||
                  FocusManager.instance.primaryFocus != focusedNode) {
                return;
              }
              void revealEditable(Element element) {
                if (element is StatefulElement &&
                    element.state is EditableTextState) {
                  final editable = element.state as EditableTextState;
                  final selection = editable.widget.controller.selection;
                  if (editable.widget.focusNode.hasFocus && selection.isValid) {
                    editable.bringIntoView(selection.extent);
                  }
                  return;
                }
                element.visitChildren(revealEditable);
              }

              fieldContext.visitChildElements(revealEditable);
            });
          },
          child: TextField(
            key: ValueKey('buy-address-add-$id'),
            controller: controller,
            scrollPadding: const EdgeInsets.symmetric(vertical: 12),
            keyboardType: keyboardType,
            textInputAction: action,
            minLines: minLines,
            maxLines: maxLines,
            decoration: InputDecoration(labelText: largeText ? null : label),
          ),
        ),
      );
      if (!largeText) return field;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(label, style: context.buyMeta.copyWith(fontSize: 12)),
          ),
          const SizedBox(height: 4),
          Semantics(label: label, textField: true, child: field),
        ],
      );
    }

    return Semantics(
      key: const ValueKey('buy-address-add-form-route'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: RepaintBoundary(
        key: const ValueKey('buy-address-add-form-repaint-boundary'),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.sizeOf(context).height *
                  BuyV2AddressFormSheetMotion.addMaxHeightFactor,
            ),
            child: ListView(
              key: const ValueKey('buy-address-add-form-list'),
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
              children: [
                _AddressFormHeader(
                  title: title,
                  body:
                      'Enter the complete address below. You can review it before placing the order.',
                  closeKey: const ValueKey('buy-address-add-form-close'),
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: 'Address type',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final option in const [
                        (BuyV2AddressKind.home, 'Home'),
                        (BuyV2AddressKind.work, 'Work'),
                        (BuyV2AddressKind.thirdParty, 'Third party'),
                        (BuyV2AddressKind.other, 'Other place'),
                      ])
                        ChoiceChip(
                          side: const BorderSide(
                            color: BuyV2ActionStyle.primaryBorder,
                          ),
                          checkmarkColor: BuyV2ActionStyle.primaryForeground,
                          backgroundColor: BuyV2ActionStyle.primaryFill,
                          selectedColor: BuyV2ActionStyle.pressedFill,
                          key: ValueKey('buy-address-add-kind-${option.$2}'),
                          label: Text(option.$2),
                          labelStyle:
                              (context.buyBody.copyWith(
                                color: BuyV2ActionStyle.foreground,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              )).copyWith(
                                color: BuyV2ActionStyle.primaryForeground,
                              ),
                          showCheckmark: false,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          visualDensity: VisualDensity.standard,
                          selected: kind == option.$1,
                          onSelected: (_) => setState(() => kind = option.$1),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                input(
                  id: 'recipient',
                  controller: recipientController,
                  label: 'Recipient name',
                ),
                const SizedBox(height: 9),
                input(
                  id: 'phone',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  label: '10-digit phone number',
                ),
                const SizedBox(height: 9),
                input(
                  id: 'line',
                  controller: lineController,
                  minLines: 2,
                  maxLines: 3,
                  action: TextInputAction.newline,
                  label: 'House, building and street',
                ),
                const SizedBox(height: 9),
                input(
                  id: 'area',
                  controller: areaController,
                  label: 'Area or locality',
                ),
                const SizedBox(height: 9),
                input(
                  id: 'pin',
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  label: '6-digit PIN code',
                ),
                const SizedBox(height: 9),
                input(
                  id: 'landmark',
                  controller: landmarkController,
                  action: TextInputAction.done,
                  label: 'Nearby landmark (optional)',
                ),
                if (validationMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    key: const ValueKey('buy-address-add-validation'),
                    padding: const EdgeInsets.all(12),
                    decoration: buyV2CardDecoration(
                      color: BuyV2Colors.softOrange,
                      border: BuyV2Colors.orange,
                      radius: 14,
                    ),
                    child: Text(validationMessage!, style: context.buyMeta),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: FilledButton(
                      key: const ValueKey('buy-address-add-submit'),
                      style: BuyV2ActionStyle.button(
                        FilledButton.styleFrom(
                          minimumSize: const Size(0, BuyV2Metrics.minimumTap),
                        ),
                      ),
                      onPressed: submit,
                      child: Text(
                        editingAddress == null
                            ? 'Save and deliver here'
                            : 'Save changes',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressFormHeader extends StatelessWidget {
  const _AddressFormHeader({
    required this.title,
    required this.body,
    required this.closeKey,
  });

  final String title;
  final String body;
  final Key closeKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.buyTitle),
              const SizedBox(height: 3),
              Text(body, style: context.buyMeta),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: closeKey,
          tooltip: 'Close $title',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            maximumSize: const Size(44, 44),
            foregroundColor: BuyV2Colors.navy,
            backgroundColor: BuyV2Colors.softBlue,
          ),
        ),
      ],
    );
  }
}

class _ReturnAffordance extends StatelessWidget {
  const _ReturnAffordance({
    super.key,
    required this.label,
    required this.onTap,
    this.tightHitOwner = false,
    this.hitOwnerKey,
    this.minimumHeight = 40,
    this.foreground = BuyV2Colors.navy,
  });

  final String label;
  final VoidCallback onTap;
  final bool tightHitOwner;
  final Key? hitOwnerKey;
  final double minimumHeight;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final affordance = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: BoxConstraints(minHeight: minimumHeight),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BuyV2Colors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left_rounded, color: foreground, size: 19),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (tightHitOwner) {
      return Row(
        children: [
          Flexible(
            child: Semantics(
              key: hitOwnerKey,
              container: true,
              button: true,
              label: label,
              onTap: onTap,
              child: ExcludeSemantics(child: affordance),
            ),
          ),
        ],
      );
    }
    return Align(alignment: Alignment.centerLeft, child: affordance);
  }
}

class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel({
    super.key,
    required this.title,
    required this.children,
    this.softSurface = false,
  });

  final String title;
  final List<Widget> children;
  final bool softSurface;

  @override
  Widget build(BuildContext context) {
    return BuyV2CartAvoidanceRegion(
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 4),
        decoration: softSurface
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF5F8FA)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BuyV2Colors.line, width: .5),
              )
            : buyV2CardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: softSurface
                  ? context.buyTitle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )
                  : context.buyEyebrow,
            ),
            const SizedBox(height: 3),
            for (var index = 0; index < children.length; index++) ...[
              if (softSurface && index > 0)
                const Divider(
                  height: 8,
                  thickness: .5,
                  color: BuyV2Colors.line,
                ),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}

class _DecisionRow extends StatelessWidget {
  const _DecisionRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = BuyV2Colors.ink,
    this.stackAtLargeText = true,
    this.deliveryArtwork,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool stackAtLargeText;
  final BuyV2DeliveryArtwork? deliveryArtwork;

  @override
  Widget build(BuildContext context) {
    if (stackAtLargeText && MediaQuery.textScalerOf(context).scale(1) > 1.25) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (deliveryArtwork case final artwork?)
                  BuyV2DeliveryModeIcon(artwork: artwork, size: 16)
                else
                  Icon(icon, color: BuyV2Colors.navy, size: 16),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    style: context.buyMeta.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 23),
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (deliveryArtwork case final artwork?)
            BuyV2DeliveryModeIcon(artwork: artwork, size: 16)
          else
            Icon(icon, color: BuyV2Colors.navy, size: 16),
          const SizedBox(width: 7),
          SizedBox(
            width: 92,
            child: Text(label, style: context.buyMeta.copyWith(fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionActionRow extends StatelessWidget {
  const _DecisionActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final labelText = Text(
      label,
      style: context.buyMeta.copyWith(
        color: BuyV2Colors.muted,
        fontSize: 8,
        fontWeight: FontWeight.w700,
      ),
    );
    final values = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: BuyV2Colors.ink,
            fontSize: 9,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(detail, style: context.buyMeta.copyWith(fontSize: 7.5)),
      ],
    );
    final actionIcon = Icon(
      Icons.arrow_forward_rounded,
      color: BuyV2Colors.navy,
      size: 18,
    );
    return BuyV2IntentDepth(
      child: Semantics(
        container: true,
        button: true,
        label: semanticLabel,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: BuyV2Metrics.minimumTap,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: largeText
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icon, color: BuyV2Colors.navy, size: 16),
                                const SizedBox(width: 7),
                                Expanded(child: labelText),
                                const SizedBox(width: 5),
                                actionIcon,
                              ],
                            ),
                            const SizedBox(height: 3),
                            Padding(
                              padding: const EdgeInsets.only(left: 23),
                              child: values,
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(icon, color: BuyV2Colors.navy, size: 16),
                            const SizedBox(width: 7),
                            SizedBox(width: 72, child: labelText),
                            Expanded(child: values),
                            const SizedBox(width: 5),
                            actionIcon,
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _sellerTypeLabel(String source) {
  final value = source.trim().toLowerCase();
  if (value.contains('manufacturer')) return 'Manufacturer';
  if (value.contains('wholesaler')) return 'Wholesaler';
  if (value.contains('distributor')) return 'Distributor';
  if (value.contains('retailer')) return 'Retailer';
  if (value.contains('shop')) return 'Dealer';
  if (value.contains('producer')) return 'Producer';
  return 'Seller';
}

class _ProductOwnedActionPanel extends StatelessWidget {
  const _ProductOwnedActionPanel({
    super.key,
    required this.product,
    required this.quantity,
    this.deliveryDecision,
    this.showPurchaseFacts = true,
    this.addSemanticLabel,
    required this.rxBlocked,
    required this.onAdd,
    required this.onEdit,
    required this.onDecrease,
    required this.onIncrease,
  });

  final BuyV2Product product;
  final int quantity;
  final String? deliveryDecision;
  final bool showPurchaseFacts;
  final String? addSemanticLabel;
  final bool rxBlocked;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final commerce =
        product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale;
    final action = SizedBox(
      key: ValueKey('buy-product-action-slot-${product.id}'),
      width: quantity > 0 ? _productQuantityWidth(context, quantity) : 148,
      height: 44,
      child: AnimatedSwitcher(
        duration: BuyV2Motion.resolved(context, BuyV2Motion.stateChange),
        reverseDuration: Duration.zero,
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.025, 0),
            end: Offset.zero,
          ).animate(animation),
          transformHitTests: false,
          textDirection: Directionality.of(context),
          child: child,
        ),
        layoutBuilder: (currentChild, _) =>
            Align(alignment: Alignment.centerRight, child: currentChild),
        child: quantity > 0
            ? _CompactProductStepper(
                key: ValueKey('buy-product-quantity-${product.id}'),
                quantity: quantity,
                minimumOrder: product.minimumOrder,
                quantityStep: product.quantityStep,
                onEdit: onEdit,
                onDecrease: onDecrease,
                onIncrease: onIncrease,
              )
            : commerce && !rxBlocked
            ? SizedBox(
                key: ValueKey('buy-product-add-shell-${product.id}'),
                width: 44,
                height: 44,
                child: Semantics(
                  container: true,
                  label:
                      addSemanticLabel ??
                      'Add ${product.customerTitle} to cart',
                  button: true,
                  excludeSemantics: true,
                  onTap: onAdd,
                  child: TextButton(
                    key: ValueKey('buy-product-primary-${product.id}'),
                    onPressed: onAdd,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                    ),
                    child: const BuyV2AddFace(),
                  ),
                ),
              )
            : SizedBox(
                key: ValueKey('buy-product-add-shell-${product.id}'),
                width: rxBlocked ? 148 : 88,
                height: 44,
                child: Semantics(
                  container: true,
                  label: rxBlocked
                      ? 'Use prescription for ${product.customerTitle}'
                      : addSemanticLabel ??
                            'Add ${product.customerTitle} to cart',
                  button: true,
                  onTap: onAdd,
                  excludeSemantics: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: commerce ? BuyV2ActionStyle.primaryFill : null,
                      borderRadius: BorderRadius.circular(12),
                      border: commerce
                          ? Border.all(color: const Color(0xFFAAA3CE))
                          : null,
                    ),
                    child: Align(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: FilledButton(
                        key: ValueKey('buy-product-primary-${product.id}'),
                        style: BuyV2ActionStyle.button(
                          FilledButton.styleFrom(
                            minimumSize: Size(rxBlocked ? 148 : 88, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                        onPressed: onAdd,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              rxBlocked
                                  ? Icons.description_outlined
                                  : Icons.add_rounded,
                              size: 17,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                rxBlocked ? 'Use prescription' : 'Add',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );

    if (!showPurchaseFacts) {
      return BuyV2CartAvoidanceRegion(
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [action],
          ),
        ),
      );
    }

    final price = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 7,
          runSpacing: 2,
          children: [
            Text(
              buyV2Money(product.price),
              style: const TextStyle(
                color: BuyV2Colors.navy,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (product.mrp case final mrp?)
              Text(
                '₹$mrp',
                style: const TextStyle(
                  color: BuyV2Colors.muted,
                  fontSize: 10,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
        if (product.unitPrice.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            product.unitPrice,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.buyMeta.copyWith(fontSize: 9),
          ),
        ],
        if (deliveryDecision case final delivery?) ...[
          const SizedBox(height: 3),
          Text(
            delivery,
            key: ValueKey('buy-product-action-delivery-${product.id}'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.buyMeta.copyWith(
              color: BuyV2Colors.green,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );

    return BuyV2CartAvoidanceRegion(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: BuyV2Colors.softBlue.withValues(alpha: .42),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0x24000080)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;
              final stack = largeText || constraints.maxWidth < 276;
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    price,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: action),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: price),
                  const SizedBox(width: 8),
                  action,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<void> showBuyV2QuantityEditor(
  BuildContext context,
  BuyV2Session session,
  BuyV2Product product, {
  Future<bool> Function(int)? beforeSave,
}) async {
  final bottomClearance = BuyV2AddressSheetMotion.resolveModalActionBottomInset(
    context,
  );
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    sheetAnimationStyle: BuyV2ProductFeedbackSheetMotion.resolve(context),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        // The keyboard already covers the system navigation clearance.
        bottom: math.max(
          MediaQuery.viewInsetsOf(sheetContext).bottom,
          bottomClearance,
        ),
      ),
      child: _QuantityEditor(
        session: session,
        product: product,
        beforeSave: beforeSave,
      ),
    ),
  );
}

class _QuantityEditor extends StatefulWidget {
  const _QuantityEditor({
    required this.session,
    required this.product,
    this.beforeSave,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final Future<bool> Function(int)? beforeSave;

  @override
  State<_QuantityEditor> createState() => _QuantityEditorState();
}

class _QuantityEditorState extends State<_QuantityEditor> {
  late final TextEditingController _controller;
  String? _error;
  bool _closing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final text = '${widget.session.quantityFor(widget.product.id)}';
    _controller = TextEditingController(text: text)
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_closing || _saving) return;
    setState(() => _saving = true);
    try {
      final error = widget.session.cartQuantityError(
        widget.product.id,
        _controller.text,
      );
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      final accepted = await widget.beforeSave?.call(
        int.parse(_controller.text.trim()),
      );
      if (!mounted || _closing) return;
      if (accepted == false) {
        setState(
          () => _error =
              'This offer or quantity changed. Return to the comparison and refresh.',
        );
        return;
      }
      if (widget.session.setCartQuantity(widget.product.id, _controller.text)) {
        _dismiss();
      } else {
        setState(
          () => _error =
              widget.session.notice ?? 'Quantity could not be updated.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _dismiss() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit quantity', style: context.buyTitle),
          const SizedBox(height: 8),
          Text(widget.product.customerTitle, style: context.buyBody),
          Text(widget.product.pack, style: context.buyMeta),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('buy-quantity-input'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Number of packs',
              helperText:
                  'Minimum ${_packCountLabel(widget.product.minimumOrder)}'
                  '${widget.product.quantityStep > 1 ? ' · Step ${widget.product.quantityStep}' : ''}',
              helperMaxLines: 3,
              errorText: _error,
              errorMaxLines: 4,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          Align(
            widthFactor: 1,
            heightFactor: 1,
            child: FilledButton(
              style: BuyV2ActionStyle.button(),
              key: const ValueKey('buy-quantity-save'),
              onPressed: _saving ? null : _save,
              child: const Text('Update quantity'),
            ),
          ),
          TextButton(onPressed: _dismiss, child: const Text('Cancel')),
        ],
      ),
    );
  }
}

const _productQuantityStyle = TextStyle(
  color: Color(0xFF24272B),
  fontWeight: FontWeight.w900,
);

double _productQuantityWidth(BuildContext context, int quantity) =>
    (buyV2ValueTextSize(context, '$quantity', _productQuantityStyle).width +
            104)
        .clamp(148.0, double.infinity)
        .toDouble();

class _CompactProductStepper extends StatelessWidget {
  const _CompactProductStepper({
    super.key,
    required this.quantity,
    required this.minimumOrder,
    required this.quantityStep,
    required this.onEdit,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final int minimumOrder;
  final int quantityStep;
  final VoidCallback onEdit;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _productQuantityWidth(context, quantity),
      height: 44,
      child: Stack(
        children: [
          Positioned.fill(
            top: 6,
            bottom: 6,
            child: DecoratedBox(
              key: const ValueKey('buy-compact-product-quantity-pill'),
              decoration: BoxDecoration(
                color: BuyV2ActionStyle.primaryFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x28000080)),
              ),
            ),
          ),
          Row(
            children: [
              SizedBox.square(
                dimension: 44,
                child: IconButton(
                  tooltip: quantity <= minimumOrder
                      ? 'Remove from Cart'
                      : quantityStep == 1
                      ? 'Remove one'
                      : 'Remove $quantityStep packs',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  onPressed: onDecrease,
                  icon: const Icon(Icons.remove, size: 20),
                ),
              ),
              Expanded(
                child: TextButton(
                  key: const ValueKey('buy-product-edit-quantity'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: onEdit,
                  child: Semantics(
                    label:
                        'Edit quantity, ${_packCountLabel(quantity)} in Cart',
                    excludeSemantics: true,
                    child: BuyV2FiniteValueTransition(
                      key: const ValueKey('buy-product-quantity-value-motion'),
                      incomingOnly: true,
                      stateKey: quantity,
                      text: '$quantity',
                      ownerSize: buyV2ValueTextSize(
                        context,
                        '$quantity',
                        _productQuantityStyle,
                      ),
                      style: _productQuantityStyle,
                    ),
                  ),
                ),
              ),
              SizedBox.square(
                dimension: 44,
                child: IconButton(
                  tooltip: quantityStep == 1
                      ? 'Add one'
                      : 'Add $quantityStep packs',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  onPressed: onIncrease,
                  icon: const Icon(Icons.add, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartScopeBar extends StatelessWidget {
  const _CartScopeBar({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    if (session.usesMixedCartSelection) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            for (final entry in const {
              'all': 'All',
              'shop': 'Shop',
              'wholesale': 'Wholesale',
              'bulk': 'Bulk',
            }.entries)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  key: ValueKey('buy-cart-filter-${entry.key}'),
                  label: Text(entry.value),
                  labelStyle: TextStyle(
                    color: BuyV2ActionStyle.primaryForeground,
                    fontSize: 12,
                    fontWeight: session.cartDisplayFilter == entry.key
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                  selected: session.cartDisplayFilter == entry.key,
                  elevation: session.cartDisplayFilter == entry.key ? 2 : 0,
                  side: BorderSide.none,
                  showCheckmark: false,
                  backgroundColor: BuyV2ActionStyle.primaryFill,
                  selectedColor: BuyV2ActionStyle.pressedFill,
                  onSelected: (_) => session.chooseCartDisplayFilter(entry.key),
                ),
              ),
          ],
        ),
      );
    }
    final scopes = session.isStoreProcurement
        ? const [BuyV2CartScope.wholesale]
        : session.cartScope == BuyV2CartScope.medicine
        ? const [BuyV2CartScope.medicine]
        : const [
            BuyV2CartScope.all,
            BuyV2CartScope.shop,
            BuyV2CartScope.wholesale,
          ];
    final entries = scopes
        .map((scope) {
          final selected = session.cartScope == scope;
          final label = session.isStoreProcurement
              ? 'Wholesale / Bulk'
              : scope == BuyV2CartScope.all
              ? 'All baskets'
              : scope.label;
          final text = scope == BuyV2CartScope.all
              ? session.procurementPricesUnavailableFor()
                    ? 'Price pending'
                    : buyV2Money(session.cartTotal)
              : '${session.countForDestination(_destinationForCartScope(scope)!)}';
          final labelStyle = TextStyle(
            color: selected
                ? BuyV2ActionStyle.primaryForeground
                : BuyV2Colors.muted,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          );
          final valueStyle = TextStyle(
            color: BuyV2Colors.ink,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          );
          final labelSize = buyV2ValueTextSize(context, label, labelStyle);
          final valueSize = buyV2ValueTextSize(context, text, valueStyle);
          return (
            scope: scope,
            label: label,
            selected: selected,
            text: text,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
            labelSize: labelSize,
            valueSize: valueSize,
            width:
                (labelSize.width > valueSize.width
                    ? labelSize.width
                    : valueSize.width) +
                12,
          );
        })
        .toList(growable: false);
    final height = entries
        .map((entry) => entry.labelSize.height + entry.valueSize.height + 6)
        .reduce((left, right) => left > right ? left : right)
        .clamp(44.0, double.infinity)
        .toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: BuyV2ActionStyle.primaryFill,
          borderRadius: BorderRadius.circular(15),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final equalWidth = constraints.maxWidth / entries.length;
            final equalFits = entries.every(
              (entry) => entry.width <= equalWidth,
            );
            final minimumSum = entries.fold(
              0.0,
              (sum, entry) => sum + entry.width,
            );
            final extra = ((constraints.maxWidth - minimumSum) / entries.length)
                .clamp(0.0, double.infinity);
            final splitRows =
                entries.length == 3 && minimumSum > constraints.maxWidth;
            return Wrap(
              children: [
                for (final entry in entries)
                  SizedBox(
                    width: splitRows
                        ? entry.scope == BuyV2CartScope.all
                              ? constraints.maxWidth
                              : constraints.maxWidth / 2
                        : equalFits
                        ? equalWidth
                        : entry.width + extra,
                    height: height,
                    child: Semantics(
                      button: true,
                      selected: entry.selected,
                      child: InkWell(
                        key: ValueKey('buy-cart-scope-${entry.scope.name}'),
                        onTap: () => session.chooseCartScope(entry.scope),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: entry.selected
                                ? BuyV2ActionStyle.primaryFill
                                : null,
                            boxShadow: entry.selected
                                ? const [
                                    BoxShadow(
                                      color: Color(0xFFFFFFFF),
                                      offset: Offset(-1, -1),
                                      blurRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Color(0x335C6578),
                                      offset: Offset(1, 2),
                                      blurRadius: 3,
                                    ),
                                  ]
                                : null,
                            border: entry.selected
                                ? Border.all(
                                    color: BuyV2ActionStyle.primaryBorder,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                entry.label,
                                maxLines: 1,
                                style: entry.labelStyle,
                              ),
                              BuyV2FiniteValueTransition(
                                key: ValueKey(
                                  'buy-cart-scope-value-motion-${entry.scope.name}',
                                ),
                                incomingOnly: true,
                                stateKey: entry.text,
                                text: entry.text,
                                ownerSize: entry.valueSize,
                                style: entry.valueStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

BuyV2Destination? _destinationForCartScope(BuyV2CartScope scope) =>
    switch (scope) {
      BuyV2CartScope.all => null,
      BuyV2CartScope.shop => BuyV2Destination.shop,
      BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
      BuyV2CartScope.medicine => BuyV2Destination.medicine,
    };

List<String> _purchaseProtectionLines(BuyV2Product product) {
  final protection = product.purchaseProtection;
  if (protection == null) {
    return [?_nonBlankComplianceValue(product.returnPolicy)];
  }
  final remedies = protection.remedies
      .map(_nonBlankComplianceValue)
      .whereType<String>()
      .toList(growable: false);
  return [
    ?_nonBlankComplianceValue(protection.summary),
    if (remedies.isNotEmpty) 'Available options: ${remedies.join(', ')}',
    if (_nonBlankComplianceValue(protection.windowLabel) case final value?)
      'Request window: $value',
    if (_nonBlankComplianceValue(protection.conditionsLabel) case final value?)
      'Conditions: $value',
    if (_nonBlankComplianceValue(protection.verificationLabel)
        case final value?)
      'Verification: $value',
    if (_nonBlankComplianceValue(protection.initiationLabel) case final value?)
      'How to request: $value',
    if (_nonBlankComplianceValue(protection.approvalLabel) case final value?)
      'Approval: $value',
    if (_nonBlankComplianceValue(protection.pickupLabel) case final value?)
      'Pickup: $value',
    if (_nonBlankComplianceValue(protection.refundMethodLabel)
        case final value?)
      'Refund method: $value',
    if (_nonBlankComplianceValue(protection.refundTimelineLabel)
        case final value?)
      'Refund timeline: $value',
    if (_nonBlankComplianceValue(protection.warrantyLabel) case final value?)
      'Warranty: $value',
    if (_nonBlankComplianceValue(protection.nonReturnableReason)
        case final value?)
      'Non-returnable: $value',
    if (_nonBlankComplianceValue(protection.policyVersion) case final value?)
      'Policy reference: $value',
    if (_nonBlankComplianceValue(protection.effectiveFromLabel)
        case final value?)
      'Applies from: $value',
  ];
}

String _cartItemFamilyLabel(BuyV2Destination destination) =>
    switch (destination) {
      BuyV2Destination.shop => 'Products',
      BuyV2Destination.wholesale => 'Packs',
      BuyV2Destination.medicine => 'Medicines',
      BuyV2Destination.orders => 'Products',
    };

String _deliveryInstructionOwner(BuyV2Destination destination) =>
    switch (destination) {
      BuyV2Destination.shop => 'Shop delivery',
      BuyV2Destination.wholesale => 'Wholesale delivery',
      BuyV2Destination.medicine => 'Medicine delivery',
      BuyV2Destination.orders => 'Delivery instructions',
    };

String _paymentOfferStatus(BuyV2Session session, BuyV2CartBenefit offer) {
  final now = DateTime.now();
  final String reason;
  if (offer.validUntil != null && !now.isBefore(offer.validUntil!)) {
    reason = 'Not eligible. This offer has expired.';
  } else if (offer.validFrom != null && now.isBefore(offer.validFrom!)) {
    reason = 'Not eligible yet. This offer has not started.';
  } else if (offer.minimumSpend != null &&
      session.totalForDestination(offer.destination) < offer.minimumSpend!) {
    reason =
        'Not eligible. Minimum ${offer.destination.label} product subtotal '
        '${buyV2Money(offer.minimumSpend!)}.';
  } else if (offer.minimumQuantity != null &&
      session.countForDestination(offer.destination) < offer.minimumQuantity!) {
    reason =
        'Not eligible. Minimum ${_packCountLabel(offer.minimumQuantity!)} '
        'in ${offer.destination.label}.';
  } else if (offer.eligiblePaymentMethods.isNotEmpty &&
      !offer.eligiblePaymentMethods.contains(session.selectedPayment)) {
    reason =
        'Not eligible with ${session.selectedPayment}. Choose '
        '${offer.eligiblePaymentMethods.join(' or ')} to review this offer.';
  } else {
    reason = 'Pending confirmation of payment eligibility and savings.';
  }
  return '$reason Payment savings are not included in this total.';
}

class _InlineCartBenefitPanel extends StatefulWidget {
  const _InlineCartBenefitPanel({
    super.key,
    required this.session,
    required this.expanded,
    required this.onExpandedChanged,
  });

  final BuyV2Session session;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  @override
  State<_InlineCartBenefitPanel> createState() =>
      _InlineCartBenefitPanelState();
}

class _InlineCartBenefitPanelState extends State<_InlineCartBenefitPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool get _expanded => widget.expanded;
  BuyV2Session get session => widget.session;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final destination = _destinationForCartScope(session.cartScope);
    final destinations = const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ].where(session.cartDestinations.contains).toList(growable: false);
    final selectedBenefits = session.selectedCartBenefitsFor(
      destination == null ? session.cartDestinations : {destination},
    );
    return Container(
      key: const ValueKey('buy-cart-benefits'),
      decoration: buyV2CardDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_expanded || destinations.isEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('buy-cart-coupons'),
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onExpandedChanged(!_expanded);
                },
                child: Semantics(
                  button: true,
                  expanded: _expanded,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Coupons and offers',
                                  style: context.buyBody.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: BuyV2ActionStyle.primaryForeground,
                                  ),
                                ),
                                if (selectedBenefits.isNotEmpty)
                                  Text(
                                    '${selectedBenefits.length} selected for review',
                                    style: context.buyMeta.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            _expanded ? Icons.expand_less : Icons.expand_more,
                            color: BuyV2ActionStyle.primaryForeground,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 0, 9, 9),
              child: destinations.isEmpty
                  ? Text(
                      'Add products to see eligible offers.',
                      style: context.buyMeta,
                    )
                  : _CartBenefitsInline(
                      key: ValueKey(
                        'buy-cart-benefits-scope-${session.cartScope.name}',
                      ),
                      session: session,
                      onCollapse: () => widget.onExpandedChanged(false),
                      destinations: destinations,
                      initialDestination:
                          destination != null &&
                              destinations.contains(destination)
                          ? destination
                          : destinations.first,
                    ),
            ),
          if (!_expanded)
            for (final offer in selectedBenefits.where(
              (benefit) => benefit.kind == BuyV2CartBenefitKind.paymentOffer,
            ))
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: Text(
                  '${offer.title} · ${offer.sponsorName}\n'
                  '${_paymentOfferStatus(session, offer)}',
                  key: ValueKey('buy-cart-payment-offer-status-${offer.id}'),
                  style: context.buyMeta.copyWith(fontSize: 10),
                ),
              ),
        ],
      ),
    );
  }
}

String _cartBenefitStrategyLabel(BuyV2CartBenefitStrategy strategy) =>
    switch (strategy) {
      BuyV2CartBenefitStrategy.timedSale => 'Time-bound sale',
      BuyV2CartBenefitStrategy.publishedOffer => 'Published offer',
      BuyV2CartBenefitStrategy.minimumOrder => 'Minimum order savings',
      BuyV2CartBenefitStrategy.loadBased => 'Order-load reward',
      BuyV2CartBenefitStrategy.financialProduct => 'Financial partner offer',
      BuyV2CartBenefitStrategy.partnerCampaign => 'Partner campaign',
      BuyV2CartBenefitStrategy.freeDelivery => 'Free delivery',
    };

String _cartBenefitSponsorLabel(BuyV2CartBenefit benefit) =>
    '${switch (benefit.sponsor) {
      BuyV2CartBenefitSponsor.retailer => 'Retailer',
      BuyV2CartBenefitSponsor.wholesaler => 'Wholesaler',
      BuyV2CartBenefitSponsor.manufacturer => 'Manufacturer',
      BuyV2CartBenefitSponsor.bank => 'Bank',
      BuyV2CartBenefitSponsor.financialPartner => 'Financial partner',
      BuyV2CartBenefitSponsor.moolSocial => 'MoolSocial',
    }} · ${benefit.sponsorName}';

String _cartBenefitEmptyTitle(
  BuyV2Destination destination,
  BuyV2CartBenefitKind kind,
) {
  final owner = switch (destination) {
    BuyV2Destination.shop => 'Shop',
    BuyV2Destination.wholesale => 'trade',
    BuyV2Destination.medicine => 'Medicine',
    BuyV2Destination.orders => 'order',
  };
  return kind == BuyV2CartBenefitKind.coupon
      ? 'No $owner coupons right now'
      : 'No $owner payment offers right now';
}

class _CartBenefitsInline extends StatefulWidget {
  const _CartBenefitsInline({
    super.key,
    required this.session,
    required this.onCollapse,
    required this.destinations,
    required this.initialDestination,
  });

  final BuyV2Session session;
  final VoidCallback onCollapse;
  final List<BuyV2Destination> destinations;
  final BuyV2Destination initialDestination;

  @override
  State<_CartBenefitsInline> createState() => _CartBenefitsInlineState();
}

class _CartBenefitsInlineState extends State<_CartBenefitsInline> {
  late BuyV2Destination _destination = widget.initialDestination;
  late String _filter = widget.session.cartDisplayFilter;
  BuyV2CartBenefitKind _kind = BuyV2CartBenefitKind.coupon;

  @override
  void initState() {
    super.initState();
    _followCartFilter();
    widget.session.addListener(_sessionChanged);
    if (widget.session.liveCartBenefitsEnabled &&
        widget.session.cartBenefitsLoadState !=
            BuyV2CartBenefitsLoadState.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(widget.session.refreshCartBenefits());
      });
    }
  }

  void _followCartFilter() {
    final destination = switch (_filter) {
      'shop' => BuyV2Destination.shop,
      'wholesale' || 'bulk' => BuyV2Destination.wholesale,
      _ => _destination,
    };
    if (widget.destinations.contains(destination)) _destination = destination;
  }

  void _sessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant _CartBenefitsInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_filter != widget.session.cartDisplayFilter) {
      _filter = widget.session.cartDisplayFilter;
      _followCartFilter();
    }
    if (!widget.destinations.contains(_destination)) {
      _destination = widget.initialDestination;
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_sessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coupons = widget.session.cartBenefits(
      kind: BuyV2CartBenefitKind.coupon,
      destination: _destination,
    );
    final paymentOffers = widget.session.cartBenefits(
      kind: BuyV2CartBenefitKind.paymentOffer,
      destination: _destination,
    );
    final benefits = _kind == BuyV2CartBenefitKind.coupon
        ? coupons
        : paymentOffers;
    final selected = widget.session.selectedCartBenefit(
      kind: _kind,
      destination: _destination,
    );
    final opportunity = _kind == BuyV2CartBenefitKind.coupon
        ? widget.session.cartOfferOpportunity(destination: _destination)
        : null;
    Widget cardFor(BuyV2CartBenefit benefit) => _CartBenefitCard(
      benefit: benefit,
      scopeLabel: benefit.scope == BuyV2CartBenefitScope.platform
          ? null
          : widget.session.cartLines
                .where((line) => benefit.appliesTo(line.product))
                .map((line) => line.product.customerTitle)
                .toSet()
                .join(' · '),
      colourIndex: benefits.indexOf(benefit),
      paymentStatus: benefit.kind == BuyV2CartBenefitKind.paymentOffer
          ? _paymentOfferStatus(widget.session, benefit)
          : null,
      selected:
          selected?.id == benefit.id && selected?.sourceId == benefit.sourceId,
      onSelect: () {
        HapticFeedback.selectionClick();
        widget.session.chooseCartBenefit(benefit);
      },
      onRemove: () {
        HapticFeedback.selectionClick();
        widget.session.removeCartBenefit(
          kind: benefit.kind,
          destination: benefit.destination,
        );
      },
    );
    return Column(
      key: const ValueKey('buy-cart-benefits-inline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.destinations.length > 1)
          _CartBenefitDestinationSelector(
            session: widget.session,
            destinations: widget.destinations,
            selected: _destination,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _destination = value);
            },
          ),
        Row(
          children: [
            Expanded(
              child: _CartBenefitKindSelector(
                kind: _kind,
                couponCount: coupons.length,
                paymentOfferCount: paymentOffers.length,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _kind = value);
                },
              ),
            ),
            IconButton(
              key: const ValueKey('buy-cart-coupons'),
              tooltip: 'Collapse coupons and offers',
              onPressed: widget.onCollapse,
              icon: const Icon(Icons.expand_less_rounded, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (widget.session.liveCartBenefitsEnabled &&
            widget.session.cartBenefitsLoadState !=
                BuyV2CartBenefitsLoadState.ready)
          _CartBenefitEligibilityState(session: widget.session)
        else if (benefits.isEmpty)
          _CartBenefitEmptyState(destination: _destination, kind: _kind)
        else if (benefits.length == 1)
          cardFor(benefits.single)
        else
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              key: PageStorageKey(
                'buy-cart-benefits-carousel-${_destination.name}-${_kind.name}',
              ),
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < benefits.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: index == benefits.length - 1 ? 0 : 8,
                      ),
                      child: SizedBox(
                        width: constraints.maxWidth - 18,
                        child: Semantics(
                          container: true,
                          label: 'Offer ${index + 1} of ${benefits.length}',
                          child: cardFor(benefits[index]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (opportunity case final value?)
          ExpansionTile(
            key: const ValueKey('buy-cart-offer-opportunity'),
            dense: true,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 6),
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              'Add ${buyV2Money(value.remainingSpend)} more to qualify',
              style: context.buyBody.copyWith(fontSize: 12),
            ),
            subtitle: Text(
              '${value.benefit.title} · '
              '${value.benefit.scope == BuyV2CartBenefitScope.platform ? '${_destination.label} products' : widget.session.cartLines.where((line) => value.benefit.appliesTo(line.product)).map((line) => value.benefit.scope == BuyV2CartBenefitScope.store ? line.product.seller : '${line.product.customerTitle} · ${line.product.seller}').toSet().join(' · ')}',
              style: context.buyMeta.copyWith(fontSize: 11),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${value.benefit.detail}\n'
                  'Save ${buyV2Money(value.benefit.savingAmount)} on eligible products. '
                  'Minimum ${buyV2Money(value.benefit.minimumSpend!)}. '
                  'Select the coupon when eligible; it is not applied automatically.',
                  style: context.buyMeta.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _CartBenefitDestinationSelector extends StatelessWidget {
  const _CartBenefitDestinationSelector({
    required this.session,
    required this.destinations,
    required this.selected,
    required this.onChanged,
  });

  final BuyV2Session session;
  final List<BuyV2Destination> destinations;
  final BuyV2Destination selected;
  final ValueChanged<BuyV2Destination> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final destination in destinations)
        Expanded(
          child: Semantics(
            button: true,
            selected: selected == destination,
            label:
                '${_cartDestinationLabel(session, destination)} offers, '
                '${_productCountLabel(session.cartLines.where((line) => line.product.destination == destination).length)}, '
                '${session.cartLines.where((line) => line.product.destination == destination).fold<int>(0, (sum, line) => sum + line.quantity)} ${destination == BuyV2Destination.wholesale ? 'packs' : 'items'}, '
                '${session.procurementPricesUnavailableFor(destination) ? 'Price pending' : buyV2Money(session.cartLines.where((line) => line.product.destination == destination).fold<int>(0, (sum, line) => sum + line.total))}',
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                key: ValueKey(
                  'buy-cart-benefit-destination-${destination.name}',
                ),
                onTap: () => onChanged(destination),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: BuyV2Motion.resolved(
                    context,
                    BuyV2Motion.selection,
                  ),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == destination
                        ? BuyV2ActionStyle.pressedFill
                        : BuyV2ActionStyle.primaryFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected == destination
                          ? BuyV2ActionStyle.primaryForeground.withValues(
                              alpha: .32,
                            )
                          : BuyV2Colors.line,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${_cartDestinationLabel(session, destination)} · '
                      '${session.procurementPricesUnavailableFor(destination) ? 'Price pending' : buyV2Money(session.cartLines.where((line) => line.product.destination == destination).fold<int>(0, (sum, line) => sum + line.total))}',
                      maxLines: 1,
                      style: TextStyle(
                        color: selected == destination
                            ? BuyV2ActionStyle.primaryForeground
                            : BuyV2Colors.muted,
                        fontSize: 9,
                        fontWeight: selected == destination
                            ? FontWeight.w900
                            : FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
    final row = Row(
      children: [
        for (var index = 0; index < chips.length; index++) ...[
          if (index > 0) const SizedBox(width: 4),
          chips[index],
        ],
      ],
    );
    return SizedBox(
      key: const ValueKey('buy-cart-benefit-destination-selector'),
      height: BuyV2Metrics.minimumTap,
      child: destinations.length == 1
          ? Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(width: 184, child: row),
            )
          : row,
    );
  }
}

class _CartBenefitKindSelector extends StatelessWidget {
  const _CartBenefitKindSelector({
    required this.kind,
    required this.couponCount,
    required this.paymentOfferCount,
    required this.onChanged,
  });

  final BuyV2CartBenefitKind kind;
  final int couponCount;
  final int paymentOfferCount;
  final ValueChanged<BuyV2CartBenefitKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('buy-cart-benefit-kind-selector'),
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CartBenefitKindButton(
            key: const ValueKey('buy-cart-benefit-kind-coupon'),
            selected: kind == BuyV2CartBenefitKind.coupon,
            label: 'Coupons',
            count: couponCount,
            onTap: () => onChanged(BuyV2CartBenefitKind.coupon),
          ),
          const SizedBox(width: 4),
          _CartBenefitKindButton(
            key: const ValueKey('buy-cart-benefit-kind-payment'),
            selected: kind == BuyV2CartBenefitKind.paymentOffer,
            label: 'Payment offers',
            count: paymentOfferCount,
            onTap: () => onChanged(BuyV2CartBenefitKind.paymentOffer),
          ),
        ],
      ),
    );
  }
}

class _CartBenefitKindButton extends StatelessWidget {
  const _CartBenefitKindButton({
    super.key,
    required this.selected,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: BuyV2ActionStyle.primaryForeground,
        ),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFEAF7) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            count == 0 ? label : '$label ($count)',
            style: TextStyle(
              color: selected ? const Color(0xFF51356B) : BuyV2Colors.muted,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _CartBenefitEligibilityState extends StatelessWidget {
  const _CartBenefitEligibilityState({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final loading =
        session.cartBenefitsLoadState == BuyV2CartBenefitsLoadState.idle ||
        session.cartBenefitsLoadState == BuyV2CartBenefitsLoadState.loading;
    return Container(
      key: ValueKey('buy-cart-benefits-${session.cartBenefitsLoadState.name}'),
      padding: const EdgeInsets.all(12),
      decoration: buyV2CardDecoration(radius: 14),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 38,
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_off_outlined, color: BuyV2Colors.navy),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loading
                      ? 'Checking current eligibility'
                      : 'Coupons and offers need a refresh',
                  style: context.buyTitle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  loading
                      ? 'Matching this Cart with live campaigns.'
                      : session.cartBenefitsMessage ??
                            'Reconnect and try again. Your Cart is unchanged.',
                  style: context.buyMeta.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
          if (!loading) ...[
            const SizedBox(width: 8),
            TextButton(
              key: const ValueKey('buy-cart-benefits-retry'),
              onPressed: session.refreshCartBenefits,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartBenefitEmptyState extends StatelessWidget {
  const _CartBenefitEmptyState({required this.destination, required this.kind});

  final BuyV2Destination destination;
  final BuyV2CartBenefitKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('buy-cart-${kind.name}-empty-${destination.name}'),
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: [
          Icon(
            kind == BuyV2CartBenefitKind.coupon
                ? Icons.local_offer_outlined
                : Icons.account_balance_wallet_outlined,
            color: BuyV2ActionStyle.primaryForeground,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _cartBenefitEmptyTitle(destination, kind),
              style: context.buyMeta.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartBenefitCard extends StatelessWidget {
  const _CartBenefitCard({
    required this.benefit,
    required this.colourIndex,
    required this.selected,
    required this.onSelect,
    required this.onRemove,
    this.paymentStatus,
    this.scopeLabel,
  });

  final BuyV2CartBenefit benefit;
  final int colourIndex;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final String? paymentStatus;
  final String? scopeLabel;

  @override
  Widget build(BuildContext context) {
    const cardGreen = Color(0xFF17652C);
    const cardMuted = Color(0xFF505568);
    final hasCampaignDetails =
        benefit.strategy != BuyV2CartBenefitStrategy.partnerCampaign ||
        benefit.sponsor != BuyV2CartBenefitSponsor.moolSocial ||
        benefit.sponsorName != 'MoolSocial' ||
        benefit.savingAmount > 0 ||
        benefit.freeDelivery ||
        benefit.validFrom != null ||
        benefit.validUntil != null ||
        benefit.offerId != null ||
        benefit.minimumSpend != null ||
        benefit.minimumQuantity != null ||
        benefit.eligiblePaymentMethods.isNotEmpty;
    void activate() => selected ? onRemove() : onSelect();

    const bandColours = [
      Color(0xFFE8D9F5),
      Color(0xFFD8EAF7),
      Color(0xFFF5E1D2),
      Color(0xFFDDEBDD),
      Color(0xFFF4E7BD),
    ];
    final bandColour = bandColours[colourIndex % bandColours.length];

    final action = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Semantics(
        key: ValueKey(
          'buy-cart-benefit-'
          '${selected ? 'remove' : 'select'}-${benefit.id}',
        ),
        label: '${selected ? 'Remove' : 'Select'} ${benefit.title}',
        button: true,
        selected: selected,
        container: true,
        excludeSemantics: true,
        onTap: activate,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: activate,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              key: ValueKey('buy-cart-benefit-action-motion-${benefit.id}'),
              duration: BuyV2Motion.resolved(context, BuyV2Motion.selection),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              child: BuyV2FiniteIncomingTransition(
                key: ValueKey('buy-cart-benefit-action-visual-${benefit.id}'),
                stateKey: selected,
                duration: BuyV2Motion.stateChange,
                child: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: selected ? cardGreen : cardMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return AnimatedContainer(
      key: ValueKey('buy-cart-benefit-${benefit.id}'),
      duration: BuyV2Motion.resolved(context, BuyV2Motion.selection),
      curve: Curves.easeOutCubic,
      decoration: buyV2CardDecoration(radius: 14).copyWith(
        border: Border.all(
          color: selected ? cardGreen.withValues(alpha: .45) : BuyV2Colors.line,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  key: ValueKey('buy-cart-benefit-colour-${benefit.id}'),
                  widthFactor: 1,
                  heightFactor: .35,
                  child: ColoredBox(color: bandColour),
                ),
              ),
            ),
            Positioned(
              right: -9,
              bottom: -9,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Icon(
                    benefit.kind == BuyV2CartBenefitKind.coupon
                        ? Icons.local_offer_outlined
                        : Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: Colors.white.withValues(alpha: .45),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        benefit.kind == BuyV2CartBenefitKind.coupon
                            ? Icons.local_offer_outlined
                            : Icons.account_balance_wallet_outlined,
                        color: BuyV2ActionStyle.primaryForeground,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          benefit.title,
                          style: context.buyBody.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(width: 44, child: action),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (!hasCampaignDetails)
                    Text(
                      benefit.detail,
                      style: context.buyMeta.copyWith(
                        fontSize: 11,
                        color: cardMuted,
                      ),
                    ),
                  if (scopeLabel case final label?) ...[
                    const SizedBox(height: 2),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        'For: $label',
                        key: ValueKey('buy-benefit-products-${benefit.id}'),
                        style: context.buyMeta.copyWith(
                          fontSize: 11,
                          color: BuyV2ActionStyle.primaryForeground,
                        ),
                      ),
                    ),
                  ],
                  if (benefit.savingAmount > 0 ||
                      benefit.freeDelivery ||
                      benefit.minimumSpend != null ||
                      benefit.minimumQuantity != null ||
                      benefit.validUntil != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (benefit.savingAmount > 0)
                          benefit.kind == BuyV2CartBenefitKind.paymentOffer
                              ? 'Potential saving ${buyV2Money(benefit.savingAmount)}'
                              : 'Save ${buyV2Money(benefit.savingAmount)} now',
                        if (benefit.freeDelivery) 'Free delivery',
                        if (benefit.minimumSpend case final minimumSpend?)
                          'Minimum order ${buyV2Money(minimumSpend)}',
                        if (benefit.minimumQuantity case final minimumQuantity?)
                          'Minimum quantity $minimumQuantity',
                        if (benefit.validUntil case final validUntil?)
                          'Ends ${MaterialLocalizations.of(context).formatMediumDate(validUntil)}',
                      ].join(' · '),
                      style: context.buyMeta.copyWith(
                        color: cardGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  if (hasCampaignDetails)
                    ExpansionTile(
                      key: PageStorageKey(
                        'buy-cart-benefit-details-${benefit.id}',
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 6),
                      minTileHeight: 44,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(
                        'Offer details',
                        style: context.buyMeta.copyWith(
                          fontSize: 11,
                          color: cardMuted,
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${benefit.detail}\n${_cartBenefitStrategyLabel(benefit.strategy)} · ${_cartBenefitSponsorLabel(benefit)}',
                            style: context.buyMeta.copyWith(
                              fontSize: 11,
                              color: cardMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (selected && paymentStatus != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      paymentStatus!,
                      key: ValueKey(
                        'buy-payment-offer-selection-status-${benefit.id}',
                      ),
                      style: context.buyMeta.copyWith(
                        fontSize: 10,
                        color: cardMuted,
                      ),
                    ),
                  ],
                  if (selected) const SizedBox(height: 5),
                  if (selected)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final statusLabel =
                            benefit.kind == BuyV2CartBenefitKind.coupon &&
                                benefit.savingAmount > 0
                            ? 'Applied to Cart total'
                            : 'Selected for Checkout review';
                        final statusStyle = context.buyMeta.copyWith(
                          color: cardGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        );
                        final statusHeight = buyV2ValueTextSize(
                          context,
                          statusLabel,
                          statusStyle,
                          maxWidth: (constraints.maxWidth - 19)
                              .clamp(1.0, double.infinity)
                              .toDouble(),
                          maxLines: null,
                        ).height.clamp(20.0, double.infinity).toDouble();

                        final visual = BuyV2FiniteVisualTransition(
                          key: ValueKey(
                            'buy-cart-benefit-status-motion-${benefit.id}',
                          ),
                          stateKey: selected,
                          ownerSize: Size(constraints.maxWidth, statusHeight),
                          alignment: Alignment.centerLeft,
                          child: ExcludeSemantics(
                            child: selected
                                ? Padding(
                                    padding: EdgeInsets.zero,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: cardGreen,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            statusLabel,
                                            style: statusStyle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.expand(),
                          ),
                        );
                        if (!selected) return ExcludeSemantics(child: visual);
                        return Semantics(
                          label: statusLabel,
                          excludeSemantics: true,
                          child: visual,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartDiscoverySections extends StatefulWidget {
  const _CartDiscoverySections({
    required this.session,
    required this.destinations,
  });

  final BuyV2Session session;
  final List<BuyV2Destination> destinations;

  @override
  State<_CartDiscoverySections> createState() => _CartDiscoverySectionsState();
}

class _CartDiscoverySectionsState extends State<_CartDiscoverySections> {
  String _category = 'all';
  String _purchaseType = 'all';
  bool _showDeals = false;
  bool _restored = false;
  int _limit = 24;
  int _candidateCount = 0;
  int _candidateCategoryCount = 0;
  int _browseEpoch = 0;
  int _pageRound = 0;
  bool _loadingMore = false;
  bool _moreGestureHandled = false;
  final _pagers = <String, BuyV2CataloguePager<BuyV2Product>>{};
  final _pagerScopes = <String, String>{};
  String? _scopeOwner;
  int _moreRequest = 0;

  String get _storageId =>
      'buy-cart-category-$_purchaseType-${_showDeals ? 'deals' : 'products'}';

  String get _limitId => '$_storageId-$_category-limit';
  String _pagerScope(String type) =>
      'cart-explore-${widget.session.cartScope.name}-$type';
  BuyV2Destination _typeDestination(String type) => type == 'shop'
      ? BuyV2Destination.shop
      : type == 'medicine'
      ? BuyV2Destination.medicine
      : BuyV2Destination.wholesale;
  List<String> get _pagingTypes {
    final types = widget.session.usesMixedCartSelection
        ? (_purchaseType == 'all'
              ? ['shop', 'wholesale', 'bulk']
              : [_purchaseType])
        : widget.destinations.map((destination) => destination.name).toList();
    return types
        .where(
          (type) =>
              (_category == 'all' ||
                  _category.startsWith('${_typeDestination(type).name}:')) &&
              widget.session.canPageCartDiscovery(_typeDestination(type)),
        )
        .toList();
  }

  BuyV2CatalogueQuery _pagingQuery(String type) => BuyV2CatalogueQuery(
    destination: _typeDestination(type),
    procurementContext: widget.session.procurementContext,
    regionId: widget.session.catalogueRegionId,
    customerLocationKey: widget.session.eligibilityLocationKey,
    areaScope: widget.session.catalogueAreaScope,
    wholesaleSaleType: type == 'bulk'
        ? BuyV2WholesaleSaleType.bulk
        : type == 'wholesale'
        ? BuyV2WholesaleSaleType.wholesale
        : null,
    categoryId: _category == 'all' ? 'all' : _category.split(':').last,
  );
  bool _canPage(String type) {
    final pager = _pagers[type];
    return pager == null ||
        pager.query != _pagingQuery(type) ||
        pager.page == null ||
        pager.message != null ||
        pager.page?.nextCursor != null;
  }

  bool get _canBrowseMore => _hasMoreLoaded || _pagingTypes.any(_canPage);
  bool get _hasMoreLoaded =>
      _candidateCount > _limit ||
      _category == 'all' && _candidateCategoryCount > _limit ~/ 6;
  String get _moreLabel => _loadingMore
      ? 'Loading products…'
      : _pagingTypes.any((type) => _pagers[type]?.message != null)
      ? 'Try again'
      : 'More products';

  Future<void> _browseMore() async {
    if (_loadingMore || !_canBrowseMore) return;
    if (_hasMoreLoaded) {
      setState(() => _limit += 24);
      PageStorage.maybeOf(
        context,
      )?.writeState(context, _limit, identifier: _limitId);
      return;
    }
    final types = _pagingTypes.where(_canPage).toList();
    if (types.isEmpty) return;
    final type = types[_pageRound++ % types.length];
    final epoch = _browseEpoch;
    final request = ++_moreRequest;
    final pager = _pagers.putIfAbsent(type, () {
      final scope = _pagerScope(type);
      _pagerScopes[type] = scope;
      return widget.session.acquireCatalogueProducts(scope);
    });
    final query = _pagingQuery(type);
    setState(() => _loadingMore = true);
    if (pager.query != query || pager.page == null && pager.message == null) {
      await pager.open(query);
    } else if (pager.message != null) {
      await pager.retry();
    } else {
      await pager.next();
    }
    if (!mounted || request != _moreRequest) return;
    if (epoch == _browseEpoch && pager.message == null) {
      for (final product in pager.page?.items ?? const <BuyV2Product>[]) {
        if (widget.session.quantityFor(product.id) == 0) {
          widget.session.refreshProductFacts(product.id);
        }
      }
    }
    setState(() {
      _loadingMore = false;
      if (epoch == _browseEpoch && pager.message == null) _limit += 24;
    });
    if (epoch == _browseEpoch) {
      PageStorage.maybeOf(
        context,
      )?.writeState(context, _limit, identifier: _limitId);
    }
  }

  bool _browseScroll(ScrollNotification notice) {
    if (notice.depth != 0 || notice.metrics.axis != Axis.horizontal) {
      return false;
    }
    if (notice is ScrollStartNotification && notice.dragDetails != null) {
      _moreGestureHandled = false;
    }
    final dragging =
        notice is ScrollUpdateNotification && notice.dragDetails != null ||
        notice is OverscrollNotification &&
            notice.dragDetails != null &&
            notice.overscroll > 0;
    if (dragging &&
        notice.metrics.extentAfter < 32 &&
        !_moreGestureHandled &&
        _canBrowseMore) {
      _moreGestureHandled = true;
      unawaited(_browseMore());
    }
    return false;
  }

  @override
  void dispose() {
    _releasePagers(widget.session);
    super.dispose();
  }

  void _releasePagers(BuyV2Session session) {
    _moreRequest++;
    for (final scope in _pagerScopes.values) {
      session.releaseCatalogueProducts(scope);
    }
    _pagers.clear();
    _pagerScopes.clear();
    _loadingMore = false;
  }

  @override
  void didUpdateWidget(covariant _CartDiscoverySections oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session || _scopeOwner != _pagerScope('')) {
      _releasePagers(oldWidget.session);
      _scopeOwner = _pagerScope('');
      _restoreCategory();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    _scopeOwner = _pagerScope('');
    final storage = PageStorage.maybeOf(context);
    final types = widget.session.cartLines
        .map((line) => widget.session.cartPurchaseTypeFor(line.product))
        .toSet();
    _purchaseType =
        storage?.readState(context, identifier: 'buy-cart-discovery-type')
            as String? ??
        (types.length == 1 && types.single != 'medicine'
            ? types.single
            : 'all');
    _showDeals =
        storage?.readState(context, identifier: 'buy-cart-discovery-deals')
            as bool? ??
        false;
    _restoreCategory();
  }

  void _restoreCategory() {
    _category =
        PageStorage.maybeOf(context)?.readState(context, identifier: _storageId)
            as String? ??
        'all';
    _limit =
        PageStorage.maybeOf(context)?.readState(context, identifier: _limitId)
            as int? ??
        24;
    _browseEpoch++;
    _moreGestureHandled = false;
  }

  void _chooseType(String type) {
    if (_purchaseType == type) return;
    HapticFeedback.selectionClick();
    setState(() {
      _purchaseType = type;
      _restoreCategory();
    });
    PageStorage.maybeOf(
      context,
    )?.writeState(context, type, identifier: 'buy-cart-discovery-type');
  }

  void _toggleDeals() {
    HapticFeedback.selectionClick();
    setState(() {
      _showDeals = !_showDeals;
      _restoreCategory();
    });
    PageStorage.maybeOf(
      context,
    )?.writeState(context, _showDeals, identifier: 'buy-cart-discovery-deals');
  }

  void _chooseCategory(String category) {
    if (_category == category) return;
    HapticFeedback.selectionClick();
    setState(() {
      _category = category;
      _limit = 24;
      _browseEpoch++;
      _moreGestureHandled = false;
    });
    PageStorage.maybeOf(
      context,
    )?.writeState(context, category, identifier: _storageId);
  }

  Widget _choice(String key, String label, bool selected, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          key: ValueKey(key),
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          side: BorderSide.none,
          backgroundColor: BuyV2ActionStyle.primaryFill,
          selectedColor: BuyV2ActionStyle.pressedFill,
          elevation: selected ? 2 : 0,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          labelStyle: TextStyle(
            fontSize: 12,
            color: BuyV2ActionStyle.primaryForeground,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          onSelected: (_) => onTap(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final mixed = session.usesMixedCartSelection;
    final destinations = mixed
        ? [
            BuyV2Destination.shop,
            BuyV2Destination.wholesale,
            if (widget.destinations.contains(BuyV2Destination.medicine))
              BuyV2Destination.medicine,
          ]
        : widget.destinations;
    final hasDeals = destinations.any(
      (destination) => session
          .cartRecommendationsFor(
            destination,
            specialOffersOnly: true,
            limit: 1,
          )
          .isNotEmpty,
    );
    if (_showDeals && !hasDeals) {
      _showDeals = false;
      PageStorage.maybeOf(
        context,
      )?.writeState(context, false, identifier: 'buy-cart-discovery-deals');
      _restoreCategory();
    }
    final products = <BuyV2Product>[];
    final seen = <String>{};
    for (final destination in destinations) {
      for (final product in session.cartRecommendationsFor(
        destination,
        limit: 1000,
        purchaseType: mixed ? _purchaseType : null,
        specialOffersOnly: _showDeals,
      )) {
        if (seen.add(product.id)) products.add(product);
      }
    }
    final basketProducts = session.cartLines
        .map((line) => line.product)
        .toList();
    bool fromBasketStore(BuyV2Product product) =>
        basketProducts.any(product.isFromSameStoreAs);
    final storeFirst = [
      ...products.where(fromBasketStore),
      ...products.where((product) => !fromBasketStore(product)),
    ];
    products
      ..clear()
      ..addAll(storeFirst);
    final categories = <(String, String)>[
      for (final destination in destinations)
        for (final category in session.categoriesFor(destination))
          if (category.id != 'all' &&
              products.any(
                (product) =>
                    product.destination == destination &&
                    product.categoryId == category.id,
              ))
            (
              '${destination.name}:${category.id}',
              mixed && _purchaseType == 'all'
                  ? '${destination == BuyV2Destination.wholesale ? 'Wholesale & Bulk' : destination.label} · ${category.label}'
                  : category.label,
            ),
    ];
    if (!categories.any((category) => category.$1 == _category)) {
      _category = 'all';
      PageStorage.maybeOf(
        context,
      )?.writeState(context, _category, identifier: _storageId);
    }
    final matching = _category == 'all'
        ? products
        : products
              .where(
                (product) =>
                    '${product.destination.name}:${product.categoryId}' ==
                    _category,
              )
              .toList(growable: false);
    _candidateCount = matching.length;
    _candidateCategoryCount = matching
        .map((product) => '${product.destination.name}:${product.categoryId}')
        .toSet()
        .length;
    final storage = PageStorage.maybeOf(context);
    final orderId = '$_storageId-$_category-order';
    final previous =
        storage?.readState(context, identifier: orderId) as List<String>? ??
        const [];
    final byId = {for (final product in matching) product.id: product};
    final ordered = [
      for (final id in previous)
        if (byId.containsKey(id)) byId.remove(id)!,
      ...byId.values,
    ];
    final visible = [
      ...ordered.where(fromBasketStore),
      ...ordered.where((product) => !fromBasketStore(product)),
    ].take(_limit).toList();
    storage?.writeState(
      context,
      visible.map((product) => product.id).toList(),
      identifier: orderId,
    );
    final shelves = <String, List<BuyV2Product>>{};
    for (final product in visible) {
      final id = '${product.destination.name}:${product.categoryId}';
      shelves.putIfAbsent(id, () => []).add(product);
    }
    final categoryLabels = {
      for (final category in categories) category.$1: category.$2,
    };
    return ExpansionTile(
      key: const PageStorageKey('buy-cart-discovery'),
      initiallyExpanded: true,
      iconColor: BuyV2ActionStyle.primaryForeground,
      collapsedIconColor: BuyV2ActionStyle.primaryForeground,
      tilePadding: const EdgeInsets.symmetric(horizontal: 9),
      dense: true,
      visualDensity: VisualDensity.compact,
      childrenPadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _showDeals ? 'Store deals' : 'Explore products',
              style: context.buyBody.copyWith(fontSize: 14),
            ),
          ),
          if (hasDeals)
            TextButton(
              key: const ValueKey('buy-cart-deal-switch'),
              style: TextButton.styleFrom(
                foregroundColor: BuyV2ActionStyle.primaryForeground,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _toggleDeals,
              child: Text(_showDeals ? 'Products' : 'Store deals'),
            ),
        ],
      ),
      children: [
        if (mixed)
          SingleChildScrollView(
            key: const PageStorageKey('buy-cart-discovery-type-scroll'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final type in const ['all', 'shop', 'wholesale', 'bulk'])
                  _choice(
                    'buy-cart-discovery-type-$type',
                    switch (type) {
                      'all' => 'All products',
                      'shop' => 'Retail products',
                      'wholesale' => 'Wholesale packs',
                      _ => 'Bulk lots',
                    },
                    _purchaseType == type,
                    () => _chooseType(type),
                  ),
              ],
            ),
          ),
        if (categories.length > 1 || _category != 'all')
          SingleChildScrollView(
            key: PageStorageKey(
              'buy-cart-category-scroll-$_purchaseType-$_showDeals',
            ),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in [
                  ('all', 'All categories'),
                  ...categories,
                ])
                  _choice(
                    'buy-cart-category-${category.$1}',
                    category.$2,
                    _category == category.$1,
                    () => _chooseCategory(category.$1),
                  ),
              ],
            ),
          ),
        if (visible.isEmpty)
          Padding(
            key: const ValueKey('buy-cart-discovery-empty'),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Text(
              'No ${switch (_purchaseType) {
                'shop' => 'retail ',
                'wholesale' => 'wholesale ',
                'bulk' => 'bulk ',
                _ => '',
              }}${_showDeals ? 'deals' : 'products'} shown here.',
              style: context.buyMeta.copyWith(fontSize: 12),
            ),
          ),
        if (visible.isNotEmpty)
          KeyedSubtree(
            key: PageStorageKey(
              'buy-cart-category-lane-$_purchaseType-$_showDeals-$_category',
            ),
            child: _category != 'all'
                ? _CartProductLane(
                    session: session,
                    destination: visible.first.destination,
                    laneId: 'recommendations',
                    products: visible,
                    showDeal: _showDeals,
                    onBrowseScroll: _browseScroll,
                  )
                : Container(
                    key: ValueKey(
                      'buy-cart-recommendations-${visible.first.destination.name}',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final shelf in shelves.entries.take(_limit ~/ 6))
                          Padding(
                            key: ValueKey(
                              'buy-cart-category-shelf-${shelf.key}',
                            ),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Semantics(
                                        header: true,
                                        child: Text(
                                          categoryLabels[shelf.key] ??
                                              'Other products',
                                          style: context.buyBody.copyWith(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (categoryLabels.containsKey(shelf.key))
                                      TextButton(
                                        key: ValueKey(
                                          'buy-cart-category-view-${shelf.key}',
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: BuyV2ActionStyle
                                              .primaryForeground,
                                          minimumSize: const Size(44, 44),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _chooseCategory(shelf.key),
                                        child: const Text('See all'),
                                      ),
                                  ],
                                ),
                                _CartProductLane(
                                  session: session,
                                  destination: shelf.value.first.destination,
                                  laneId: 'recommendations-${shelf.key}',
                                  products: shelf.value,
                                  showDeal: _showDeals,
                                  onBrowseScroll: _browseScroll,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        if (_canBrowseMore)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('buy-cart-discovery-more'),
              style: TextButton.styleFrom(
                foregroundColor: BuyV2ActionStyle.primaryForeground,
                minimumSize: const Size(44, 44),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _loadingMore ? null : _browseMore,
              icon: const Icon(Icons.expand_more, size: 18),
              label: Text(_moreLabel),
            ),
          ),
      ],
    );
  }
}

class _CartProductLane extends StatelessWidget {
  const _CartProductLane({
    required this.session,
    required this.destination,
    required this.laneId,
    required this.products,
    this.showDeal = false,
    this.onBrowseScroll,
  });

  final BuyV2Session session;
  final BuyV2Destination destination;
  final String laneId;
  final List<BuyV2Product> products;
  final bool showDeal;
  final bool Function(ScrollNotification)? onBrowseScroll;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('buy-cart-$laneId-${destination.name}'),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: onBrowseScroll,
            child: SingleChildScrollView(
              key: PageStorageKey(
                'buy-cart-$laneId-scroll-${destination.name}',
              ),
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < products.length; index++) ...[
                    if (index > 0) const SizedBox(width: 7),
                    _CartRecommendationCard(
                      session: session,
                      product: products[index],
                      showDeal: showDeal,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartRecommendationCard extends StatelessWidget {
  const _CartRecommendationCard({
    required this.session,
    required this.product,
    this.showDeal = false,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final bool showDeal;

  @override
  Widget build(BuildContext context) {
    final facts = session.productFactsFor(product);
    final hasSaving = product.mrp != null && product.mrp! > facts.price;
    final tier = showDeal ? session.nextCartDealTierFor(product) : null;
    final priceWidth = buyV2ValueTextSize(
      context,
      buyV2Money(hasSaving ? product.mrp! : facts.price),
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ).width;
    return SizedBox(
      width: (priceWidth + 60)
          .clamp(
            MediaQuery.textScalerOf(context).scale(1) > 1.6 ? 260.0 : 168.0,
            double.infinity,
          )
          .toDouble(),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: BuyV2Colors.ink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          key: ValueKey('buy-cart-recommendation-${product.id}'),
          onTap: () => session.openProduct(product.id),
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 72,
                        child: BuyV2ProductPackshot(
                          product: product,
                          borderRadius: 10,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        key: ValueKey('buy-save-${product.id}'),
                        tooltip: session.isSaved(product.id)
                            ? 'Remove ${product.customerTitle} from Saved'
                            : 'Save ${product.customerTitle}',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          session.toggleSaved(product.id);
                        },
                        icon: Icon(
                          session.isSaved(product.id)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 20,
                          color: BuyV2ActionStyle.primaryForeground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  product.customerTitle,
                  style: context.buyBody.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    product.destination == BuyV2Destination.medicine
                        ? product.destination.label
                        : _cartFilterLabel(
                            session.cartPurchaseTypeFor(product),
                          ),
                    product.customerVariantPack,
                    if (facts.price == product.price) product.unitPrice,
                  ].where((text) => text.trim().isNotEmpty).join(' · '),
                  style: context.buyMeta.copyWith(fontSize: 11, height: 1.2),
                ),
                if (product.minimumOrder > 1)
                  Text(
                    'Min. qty ${product.minimumOrder}',
                    style: context.buyMeta.copyWith(fontSize: 11, height: 1.2),
                  ),
                Text(
                  product.customerSeller(facts.partner),
                  style: context.buyMeta.copyWith(fontSize: 11, height: 1.2),
                ),
                if (facts.deliveryPromise.trim().isNotEmpty ||
                    facts.deliveryFeeLabel?.trim().isNotEmpty == true)
                  Text(
                    [
                      facts.deliveryPromise,
                      facts.deliveryFeeLabel ?? '',
                    ].where((text) => text.trim().isNotEmpty).join(' · '),
                    style: context.buyMeta.copyWith(fontSize: 11, height: 1.2),
                  ),
                const SizedBox(height: 4),
                if (showDeal && (tier != null || hasSaving))
                  Text(
                    tier != null
                        ? 'Buy ${tier.minimumPacks}+ at ${buyV2Money(tier.price)} each'
                        : 'Save ${buyV2Money(product.mrp! - facts.price)} each',
                    key: ValueKey('buy-cart-deal-${product.id}'),
                    style: context.buyMeta.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: BuyV2ActionStyle.primaryForeground,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            buyV2Money(facts.price),
                            style: const TextStyle(
                              color: BuyV2Colors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (hasSaving)
                            Text(
                              buyV2Money(product.mrp!),
                              style: context.buyMeta.copyWith(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        key: ValueKey('buy-cart-add-${product.id}'),
                        tooltip: 'Add ${product.customerTitle}',
                        onPressed: () {
                          final added = session.addProduct(product.id);
                          if (!added &&
                              session.pendingPrescriptionProductId ==
                                  product.id) {
                            showBuyV2PrescriptionSheet(context, session);
                          }
                        },
                        padding: EdgeInsets.zero,
                        icon: const BuyV2AddFace(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartDeliveryInstructionSections extends StatefulWidget {
  const _CartDeliveryInstructionSections({
    required this.session,
    required this.destinations,
    this.showHeading = true,
    this.publicEditorKey,
  });
  final BuyV2Session session;
  final List<BuyV2Destination> destinations;
  final bool showHeading;
  final GlobalKey<_CartDeliveryInstructionCardState>? publicEditorKey;
  @override
  State<_CartDeliveryInstructionSections> createState() =>
      _CartDeliveryInstructionSectionsState();
}

class _CartDeliveryInstructionSectionsState
    extends State<_CartDeliveryInstructionSections> {
  BuyV2Destination? _selected;
  late String _filter;
  @override
  void initState() {
    super.initState();
    _filter = widget.session.cartDisplayFilter;
    _followFilter();
  }

  void _followFilter() {
    _selected = switch (_filter) {
      'shop' => BuyV2Destination.shop,
      'wholesale' || 'bulk' => BuyV2Destination.wholesale,
      _ => _selected,
    };
  }

  @override
  void didUpdateWidget(covariant _CartDeliveryInstructionSections oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_filter != widget.session.cartDisplayFilter) {
      _filter = widget.session.cartDisplayFilter;
      _followFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final destinations = session.isStoreProcurement
        ? widget.destinations
        : widget.destinations.take(1);
    final eligible = destinations
        .where(
          (destination) =>
              session.deliveryInstructionsFor(destination).isNotEmpty,
        )
        .toList(growable: false);
    if (eligible.isEmpty) return const SizedBox.shrink();
    final selected = eligible.contains(_selected) ? _selected! : eligible.first;
    return Container(
      key: const ValueKey('buy-cart-instruction-panel'),
      padding: const EdgeInsets.fromLTRB(9, 5, 9, 1),
      decoration: buyV2CardDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeading)
            Text(
              'Delivery instructions · optional',
              style: context.buyBody.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BuyV2ActionStyle.primaryForeground,
              ),
            ),
          if (session.isStoreProcurement && eligible.length > 1)
            SingleChildScrollView(
              key: const PageStorageKey('buy-cart-instruction-contexts'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final destination in eligible)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        key: ValueKey(
                          'buy-instruction-context-${destination.name}',
                        ),
                        label: Text(
                          _cartDestinationLabel(session, destination),
                        ),
                        selected: selected == destination,
                        showCheckmark: false,
                        side: BorderSide.none,
                        backgroundColor: BuyV2ActionStyle.primaryFill,
                        selectedColor: BuyV2ActionStyle.pressedFill,
                        elevation: selected == destination ? 2 : 0,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: selected == destination
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: BuyV2ActionStyle.primaryForeground,
                        ),
                        onSelected: (_) {
                          FocusScope.of(context).unfocus();
                          HapticFeedback.selectionClick();
                          setState(() => _selected = destination);
                        },
                      ),
                    ),
                ],
              ),
            ),
          for (final destination in eligible)
            Offstage(
              offstage: destination != selected,
              child: TickerMode(
                enabled: destination == selected,
                child: _CartDeliveryInstructionCard(
                  key:
                      (!session.isStoreProcurement
                          ? widget.publicEditorKey
                          : null) ??
                      ValueKey(
                        'buy-delivery-note-owner-${session.isStoreProcurement ? destination.name : 'delivery'}',
                      ),
                  session: session,
                  destination: destination,
                  showDestination: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartDeliveryInstructionCard extends StatefulWidget {
  const _CartDeliveryInstructionCard({
    super.key,
    required this.session,
    required this.destination,
    required this.showDestination,
  });

  final BuyV2Session session;
  final BuyV2Destination destination;
  final bool showDestination;

  @override
  State<_CartDeliveryInstructionCard> createState() =>
      _CartDeliveryInstructionCardState();
}

class _CartDeliveryInstructionCardState
    extends State<_CartDeliveryInstructionCard>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();
  final _composerKey = GlobalKey();
  final _choiceScrollController = ScrollController();
  bool _revealPending = false;
  bool _editing = false;
  @override
  bool get wantKeepAlive => _editing;
  BuyV2Session get session => widget.session;
  BuyV2Destination get destination => widget.destination;
  bool get showDestination => widget.showDestination;
  String get instructionScope =>
      session.isStoreProcurement ? destination.name : 'delivery';
  String get instructionOwner => session.isStoreProcurement
      ? _deliveryInstructionOwner(destination)
      : 'Delivery instructions';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _noteFocus.addListener(_revealEditor);
  }

  @override
  void didChangeMetrics() => _revealEditor();

  void _revealEditor() {
    if (!_editing || !_noteFocus.hasFocus || _revealPending) return;
    _revealPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealPending = false;
      if (!mounted || !_editing || !_noteFocus.hasFocus) return;
      final editorContext = _composerKey.currentContext;
      if (editorContext == null) return;
      // Keyboard insets settle after focus. Reveal the attached actions too,
      // rather than only the caret, in the resized Cart viewport.
      Scrollable.ensureVisible(
        editorContext,
        alignment: 1,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _closeEditor() {
    setState(() => _editing = false);
    updateKeepAlive();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
      }
    });
  }

  void openEditor({bool focus = false}) {
    if (session.checkoutBusy || session.checkoutRequiresResolution) return;
    if (!_editing) {
      setState(() {
        _noteController.text = session.isStoreProcurement
            ? session.customDeliveryInstructionFor(destination) ?? ''
            : session.publicDeliveryInstruction ??
                  session.previousPublicDeliveryInstructions.join('\n');
        _editing = true;
      });
      updateKeepAlive();
    }
    if (focus) {
      _noteFocus.requestFocus();
      _revealEditor();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _noteFocus.removeListener(_revealEditor);
    _noteFocus.dispose();
    _noteController.dispose();
    _choiceScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noteActionStyle = TextButton.styleFrom(
      // The shared editor remains alive when filtering moves its list row.
      foregroundColor: BuyV2ActionStyle.primaryForeground,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    );
    super.build(context);
    final options = session.deliveryInstructionsFor(destination);
    final selected = session.selectedDeliveryInstructionFor(destination);
    final customNote = session.customDeliveryInstructionFor(destination);
    return Column(
      key: ValueKey('buy-cart-delivery-instructions-$instructionScope'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDestination)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              instructionOwner,
              style: context.buyMeta.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: BuyV2ActionStyle.primaryForeground,
              ),
            ),
          ),
        if (session.publicDeliveryInstructionReviewRequired) ...[
          Text(
            'Your previous instructions differ. Review and save one instruction for this address.',
            style: context.buyBody,
          ),
          for (final note in session.previousPublicDeliveryInstructions)
            Text(note, style: context.buyMeta),
        ],
        RawScrollbar(
          key: ValueKey('buy-instruction-scroll-cue-$instructionScope'),
          controller: _choiceScrollController,
          thumbColor: BuyV2Colors.muted,
          thumbVisibility: true,
          interactive: false,
          thickness: 2.5,
          radius: const Radius.circular(2),
          notificationPredicate: (notification) =>
              notification.depth == 0 &&
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            key: PageStorageKey('buy-instruction-lane-$instructionScope'),
            controller: _choiceScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (session.isStoreProcurement && selected != null)
                  TextButton(
                    key: ValueKey(
                      'buy-cart-instruction-$instructionScope-none',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: BuyV2ActionStyle.primaryForeground,
                      minimumSize: const Size(48, 48),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.only(right: 14),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      session.chooseDeliveryInstruction(
                        destination: destination,
                        instructionId: null,
                      );
                    },
                    child: const Text('Clear'),
                  ),
                TextButton.icon(
                  style: noteActionStyle,
                  key: ValueKey(
                    'buy-cart-instruction-custom-$instructionScope',
                  ),
                  onPressed: openEditor,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Add instructions'),
                ),
                for (var index = 0; index < options.length; index++)
                  Builder(
                    builder: (context) {
                      final option = options[index];
                      final isSelected = selected?.id == option.id;
                      final label = option.label;
                      return Semantics(
                        checked: isSelected,
                        inMutuallyExclusiveGroup: true,
                        label: '$instructionOwner: $label',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: ValueKey(
                              'buy-cart-instruction-$instructionScope-${option.id}',
                            ),
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              session.chooseDeliveryInstruction(
                                destination: destination,
                                instructionId: option.id,
                              );
                            },
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      size: 18,
                                      color: BuyV2ActionStyle.primaryForeground,
                                    ),
                                    const SizedBox(width: 5),
                                    ExcludeSemantics(
                                      child: Text(
                                        label,
                                        softWrap: false,
                                        style: context.buyBody.copyWith(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: BuyV2ActionStyle
                                              .primaryForeground,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        if (_editing)
          KeyedSubtree(
            key: _composerKey,
            child: Container(
              key: ValueKey('buy-cart-instruction-composer-$instructionScope'),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDADDE5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: ValueKey(
                      'buy-cart-instruction-note-$instructionScope',
                    ),
                    controller: _noteController,
                    focusNode: _noteFocus,
                    onChanged: (_) => _revealEditor(),
                    autofocus: true,
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Delivery instructions (optional)',
                      hintText: 'For example, use the side entrance',
                      isDense: true,
                      filled: false,
                      contentPadding: EdgeInsets.fromLTRB(8, 12, 8, 4),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      counterText: '',
                      labelStyle: TextStyle(
                        color: BuyV2ActionStyle.primaryForeground,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        style: noteActionStyle,
                        key: ValueKey(
                          'buy-cart-instruction-clear-draft-$instructionScope',
                        ),
                        onPressed: _noteController.clear,
                        child: const Text('Clear'),
                      ),
                      TextButton(
                        style: noteActionStyle,
                        key: ValueKey(
                          'buy-cart-instruction-save-$instructionScope',
                        ),
                        onPressed: () {
                          if (session.setCustomDeliveryInstruction(
                            destination: destination,
                            text: _noteController.text,
                          )) {
                            FocusScope.of(context).unfocus();
                            _closeEditor();
                          }
                        },
                        child: const Text('Save'),
                      ),
                      TextButton(
                        style: noteActionStyle,
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          _closeEditor();
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else if (customNote != null)
          Text(
            customNote,
            key: ValueKey('buy-cart-instruction-saved-$instructionScope'),
            style: context.buyBody,
          ),
      ],
    );
  }
}

class _CartTipSections extends StatelessWidget {
  const _CartTipSections({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final eligible = session.scopedCartFulfilmentGroups
        .where((group) => session.tipOptionsFor(group.destination).isNotEmpty)
        .toList(growable: false);
    if (eligible.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final group in eligible) ...[
          _CartTipCard(session: session, group: group),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CartTipCard extends StatelessWidget {
  const _CartTipCard({required this.session, required this.group});

  final BuyV2Session session;
  final BuyV2FulfilmentGroup group;

  @override
  Widget build(BuildContext context) {
    final selected = session.tipForGroup(group);
    final options = session.tipOptionsFor(group.destination);
    final title = group.destination == BuyV2Destination.medicine
        ? 'Tip pharmacy delivery partner'
        : 'Tip Shop delivery partner';
    return Container(
      key: ValueKey('buy-cart-tip-${group.key}'),
      padding: const EdgeInsets.all(9),
      decoration: buyV2CardDecoration(
        color: BuyV2Colors.softGreen,
        border: const Color(0x33138808),
        radius: 15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.buyTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            '${group.customerPartner} · optional for this delivery only',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.buyMeta.copyWith(fontSize: 8),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                side: const BorderSide(color: BuyV2ActionStyle.primaryBorder),
                checkmarkColor: BuyV2ActionStyle.primaryForeground,
                backgroundColor: BuyV2ActionStyle.primaryFill,
                selectedColor: BuyV2ActionStyle.pressedFill,
                labelStyle: (TextStyle(
                  color: BuyV2ActionStyle.foreground,
                )).copyWith(color: BuyV2ActionStyle.primaryForeground),
                key: ValueKey('buy-cart-tip-${group.key}-0'),
                label: const Text('No tip'),
                selected: selected == 0,
                onSelected: (_) => session.chooseTip(
                  fulfilmentKey: group.key,
                  destination: group.destination,
                  amount: 0,
                ),
              ),
              for (final option in options)
                ChoiceChip(
                  side: const BorderSide(color: BuyV2ActionStyle.primaryBorder),
                  checkmarkColor: BuyV2ActionStyle.primaryForeground,
                  backgroundColor: BuyV2ActionStyle.primaryFill,
                  selectedColor: BuyV2ActionStyle.pressedFill,
                  labelStyle: (TextStyle(
                    color: BuyV2ActionStyle.foreground,
                  )).copyWith(color: BuyV2ActionStyle.primaryForeground),
                  key: ValueKey('buy-cart-tip-${group.key}-${option.amount}'),
                  label: Text(buyV2Money(option.amount)),
                  selected: selected == option.amount,
                  onSelected: (_) => session.chooseTip(
                    fulfilmentKey: group.key,
                    destination: group.destination,
                    amount: option.amount,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartBillSummary extends StatelessWidget {
  const _CartBillSummary({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    if (session.scopedProcurementPricesUnavailable) {
      return Container(
        key: const ValueKey('buy-cart-bill-summary'),
        padding: const EdgeInsets.all(11),
        decoration: buyV2CardDecoration(radius: 15),
        child: Text(
          'A retained item has no confirmed price. Review or remove it before ordering.',
          style: context.buyMeta,
        ),
      );
    }
    final familyTotals = session.scopedCartFamilyTotals;
    return Container(
      key: const ValueKey('buy-cart-bill-summary'),
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(radius: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: BuyV2Colors.ink,
                size: 20,
              ),
              const SizedBox(width: 7),
              Text(
                'Bill summary',
                style: context.buyTitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          for (final entry in familyTotals.entries)
            _CartAmountRow(
              label:
                  '${_cartDestinationLabel(session, entry.key)} ${_cartItemFamilyLabel(entry.key).toLowerCase()}',
              value: buyV2Money(entry.value),
            ),
          if (session.scopedCartSavings + session.scopedCouponSaving > 0)
            _CartSavingsSummary(session: session),
          if (session.scopedTipTotal > 0)
            _CartAmountRow(
              label: 'Optional delivery tips',
              value: buyV2Money(session.scopedTipTotal),
            ),
          const Divider(height: 16),
          _CartAmountRow(
            label: 'Cart total',
            value: buyV2Money(session.scopedPayableTotal),
            strong: true,
          ),
          const SizedBox(height: 5),
          Text(
            'Delivery charges, if any, are confirmed at checkout.',
            style: context.buyMeta.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CartAmountRow extends StatelessWidget {
  const _CartAmountRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.strong = false,
    this.stacked = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: strong ? context.buyBody : context.buyMeta,
    );
    final valueText = Text(
      value,
      style: TextStyle(
        color: valueColor ?? BuyV2Colors.ink,
        fontSize: strong ? 14 : 12,
        fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelText, const SizedBox(height: 2), valueText],
            )
          : Row(
              children: [
                Expanded(child: labelText),
                valueText,
              ],
            ),
    );
  }
}

class _CartSavingsSummary extends StatelessWidget {
  const _CartSavingsSummary({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final productSaving = session.scopedCartSavings;
    final couponSaving = session.scopedCouponSaving;
    final savings = productSaving + couponSaving;
    return Padding(
      key: const ValueKey('buy-cart-savings-summary'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.savings_outlined,
            color: BuyV2Colors.green,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You save ${buyV2Money(savings)}',
                  style: context.buyBody.copyWith(fontSize: 12),
                ),
                Text(
                  [
                    if (productSaving > 0)
                      'Listed MRP saving ${buyV2Money(productSaving)}',
                    if (couponSaving > 0)
                      'Applied coupon ${buyV2Money(couponSaving)}',
                  ].join(' · '),
                  style: context.buyMeta.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.session, required this.line});

  final BuyV2Session session;
  final BuyV2CartLine line;

  @override
  Widget build(BuildContext context) {
    final product = line.product;
    final priceUnavailable = session.procurementRetainedPriceUnavailable(
      product,
    );
    final facts = session.productFactsFor(product);
    final wholesale = product.destination == BuyV2Destination.wholesale;
    final quantityTier = priceUnavailable
        ? null
        : session.nextCartDealTierFor(product);
    final automaticFulfilment =
        product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale;
    final buyerPromise = automaticFulfilment
        ? buyV2BuyerDeliveryPromise(facts)
        : product.deliveryPromise;
    // Keep the complete illustration disclosure readable in a Cart thumbnail.
    // Its measured width grows with accessibility text instead of hiding media.
    final thumbnailExtent =
        (buyV2ValueTextSize(
                  context,
                  BuyV2ProductPackshot.illustrationLabel(product),
                  const TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ).width.ceilToDouble() +
                10)
            .clamp(76.0, double.infinity)
            .toDouble();
    final productDetailsLabel = 'View ${product.customerTitle} product details';
    void openProductDetails() {
      HapticFeedback.selectionClick();
      session.openProduct(product.id);
    }

    final photo = SizedBox(
      key: ValueKey('buy-cart-packshot-${product.id}'),
      width: thumbnailExtent,
      height: thumbnailExtent,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: openProductDetails,
        child: BuyV2ProductPackshot(product: product, borderRadius: 11),
      ),
    );
    final productDetails = BuyV2IntentDepth(
      key: ValueKey('buy-cart-product-depth-${product.id}'),
      spatial: true,
      child: Semantics(
        key: ValueKey('buy-cart-product-summary-${product.id}'),
        container: true,
        button: true,
        label: productDetailsLabel,
        excludeSemantics: true,
        onTap: openProductDetails,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            key: ValueKey('buy-cart-product-details-${product.id}'),
            onTap: openProductDetails,
            borderRadius: BorderRadius.circular(11),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.customerTitle,
                          style: context.buyBody.copyWith(fontSize: 14),
                        ),
                        Text(
                          product.packTerms != null ||
                                  product.hasStructuredVariants
                              ? product.customerVariantPack
                              : '${product.customerVariant} · ${product.pack}',
                          style: context.buyMeta.copyWith(fontSize: 11),
                        ),
                        Text(
                          product.customerSeller(
                            automaticFulfilment
                                ? facts.partner
                                : product.seller,
                          ),
                          style: context.buyMeta.copyWith(fontSize: 11),
                        ),
                        Text(
                          buyerPromise,
                          style: context.buyMeta.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: BuyV2Colors.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final tradeFacts = wholesale
        ? Semantics(
            key: ValueKey('buy-wholesale-cart-line-facts-${product.id}'),
            container: true,
            label:
                'Minimum order ${_packCountLabel(product.minimumOrder)}. '
                '${buyV2Money(product.price)} per pack. ${product.unitPrice}. '
                '${product.freightIncluded ? 'Freight included in price.' : 'Freight confirmed before payment.'}',
            excludeSemantics: true,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: BuyV2Colors.canvas,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    priceUnavailable
                        ? 'Price unavailable'
                        : 'Minimum order ${_packCountLabel(product.minimumOrder)} · '
                              '${buyV2Money(product.price)} per pack',
                    style: context.buyMeta.copyWith(
                      color: BuyV2Colors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.unitPrice} · '
                    '${product.freightIncluded ? 'Freight included' : 'Freight confirmed later'}',
                    style: context.buyMeta.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          )
        : null;

    const lineTotalStyle = TextStyle(
      color: BuyV2Colors.ink,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    final lineTotalText = priceUnavailable
        ? 'Price pending'
        : buyV2Money(line.total);
    final lineTotalSize = buyV2ValueTextSize(
      context,
      lineTotalText,
      lineTotalStyle,
    );
    const quantityStyle = TextStyle(
      inherit: false,
      fontFamily: 'Inter',
      color: BuyV2Colors.ink,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );
    final quantitySize = buyV2ValueTextSize(
      context,
      '${line.quantity}',
      quantityStyle,
    );
    final price = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (wholesale)
          Text(
            priceUnavailable ? 'Retained item' : 'Item total',
            style: context.buyMeta.copyWith(fontSize: 11),
          ),
        BuyV2FiniteValueTransition(
          key: ValueKey('buy-cart-line-total-motion-${product.id}'),
          incomingOnly: true,
          stateKey: line.total,
          text: lineTotalText,
          ownerSize: lineTotalSize,
          textAlign: TextAlign.end,
          style: lineTotalStyle,
        ),
        if (!wholesale &&
            !priceUnavailable &&
            product.packTerms?.priceTiers.isNotEmpty != true &&
            product.unitPrice.trim().isNotEmpty)
          Text(
            product.unitPrice,
            style: context.buyMeta.copyWith(fontSize: 11),
          ),
        if (product.mrp != null && product.mrp! > product.price)
          Text(
            buyV2Money(product.mrp! * line.quantity),
            style: context.buyMeta.copyWith(
              fontSize: 11,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );

    final quantityControl = SizedBox(
      height: (quantitySize.height + 8).clamp(44.0, double.infinity).toDouble(),
      child: Stack(
        children: [
          Positioned.fill(
            top: 6,
            bottom: 6,
            child: DecoratedBox(
              key: ValueKey('buy-cart-quantity-pill-${product.id}'),
              decoration: BoxDecoration(
                color: BuyV2ActionStyle.primaryFill,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: product.quantityStep > 1
                    ? line.quantity <= product.minimumOrder
                          ? 'Remove ${product.customerTitle} from Cart'
                          : 'Remove ${product.quantityStep} packs'
                    : wholesale
                    ? line.quantity <= product.minimumOrder
                          ? 'Remove ${product.customerTitle} from Cart'
                          : 'Remove one trade pack'
                    : 'Remove one',
                onPressed: () => session.decrease(product.id),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: const Icon(Icons.remove, size: 15),
              ),
              SizedBox(
                key: ValueKey('buy-cart-quantity-${product.id}'),
                width: quantitySize.width
                    .clamp(48.0, double.infinity)
                    .toDouble(),
                height: 48,
                child: Center(
                  child: Semantics(
                    label:
                        '${product.customerTitle}, ${_packCountLabel(line.quantity)} in Cart',
                    excludeSemantics: true,
                    child: BuyV2FiniteValueTransition(
                      key: ValueKey(
                        'buy-cart-line-quantity-motion-${product.id}',
                      ),
                      incomingOnly: true,
                      stateKey: line.quantity,
                      text: '${line.quantity}',
                      ownerSize: Size(
                        quantitySize.width
                            .clamp(44.0, double.infinity)
                            .toDouble(),
                        quantitySize.height
                            .clamp(28.0, double.infinity)
                            .toDouble(),
                      ),
                      style: quantityStyle,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: product.quantityStep > 1
                    ? 'Add ${product.quantityStep} packs'
                    : wholesale
                    ? 'Add one trade pack'
                    : 'Add one',
                onPressed: () => session.increase(product.id),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: const Icon(Icons.add, size: 15),
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      key: ValueKey('buy-cart-line-${product.id}'),
      decoration: buyV2CardDecoration(radius: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (session.usesMixedCartSelection)
                Checkbox(
                  key: ValueKey('buy-cart-select-${product.id}'),
                  value: session.cartProductSelected(product.id),
                  activeColor: BuyV2ActionStyle.primaryForeground,
                  semanticLabel: 'Include ${product.customerTitle} in checkout',
                  onChanged: session.checkoutRequiresResolution
                      ? null
                      : (value) => session.selectCartProduct(
                          product.id,
                          value == true,
                        ),
                ),
              Expanded(
                child: BuyV2ProductEdgeControls(
                  session: session,
                  product: product,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 9, 7),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final metadataWidth =
                    constraints.maxWidth - thumbnailExtent - 8;
                final stackMedia =
                    MediaQuery.textScalerOf(context).scale(1) > 1.2 ||
                    metadataWidth < 160 ||
                    [
                      product.customerTitle,
                      product.customerVariantPack,
                      product.customerSeller(
                        automaticFulfilment ? facts.partner : product.seller,
                      ),
                    ].any(
                      (text) => text
                          .split(RegExp(r'\s+'))
                          .any(
                            (word) =>
                                buyV2ValueTextSize(
                                  context,
                                  word,
                                  context.buyBody.copyWith(fontSize: 14),
                                ).width >
                                metadataWidth - 18,
                          ),
                    );
                final purchaseControls = Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [price, quantityControl],
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (stackMedia) ...[
                      photo,
                      const SizedBox(height: 4),
                      productDetails,
                      purchaseControls,
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          photo,
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [productDetails, purchaseControls],
                            ),
                          ),
                        ],
                      ),
                    if (tradeFacts != null) ...[
                      const SizedBox(height: 4),
                      tradeFacts,
                    ],
                    if (quantityTier != null)
                      TextButton(
                        key: ValueKey('buy-cart-quantity-tier-${product.id}'),
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          foregroundColor: BuyV2ActionStyle.primaryForeground,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: const Size(44, 44),
                        ),
                        onPressed: () => session.setCartQuantity(
                          product.id,
                          '${quantityTier.minimumPacks}',
                        ),
                        child: Text(
                          '${_packCountLabel(quantityTier.minimumPacks - line.quantity)} more'
                          ' → ${buyV2Money(quantityTier.price)}/pack'
                          ' · Item total ${buyV2Money(quantityTier.minimumPacks * quantityTier.price)}'
                          '${product.packTerms?.pricesIncludeTax == null
                              ? ''
                              : product.packTerms!.pricesIncludeTax!
                              ? ' · Tax included'
                              : ' · Tax extra'}'
                          '${product.packTerms?.pricesIncludeFreight == null
                              ? ''
                              : product.packTerms!.pricesIncludeFreight!
                              ? ' · Delivery included'
                              : ' · Delivery extra'}',
                          style: context.buyBody.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedAddressReminder extends StatelessWidget {
  const _SavedAddressReminder({required this.address, required this.onEdit});

  final BuyV2Address address;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final title = 'Delivering to ${address.label}';
    return Container(
      key: const ValueKey('buy-saved-address-reminder'),
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: buyV2CardDecoration(
        color: BuyV2Colors.softGreen,
        border: const Color(0x33138808),
        radius: 13,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: BuyV2Colors.green,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  key: const ValueKey('buy-checkout-delivery-location'),
                  label: title,
                  excludeSemantics: true,
                  child: Text(
                    title,
                    style: context.buyBody.copyWith(fontSize: 10),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address.shortLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.buyMeta.copyWith(fontSize: 8.5),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onEdit();
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(52, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Edit',
              style: TextStyle(
                color: BuyV2Colors.navy,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutDeliverySummaryCard extends StatefulWidget {
  const _CheckoutDeliverySummaryCard({
    super.key,
    required this.group,
    required this.artwork,
  });

  final BuyV2FulfilmentGroup group;
  final BuyV2DeliveryArtwork artwork;

  @override
  State<_CheckoutDeliverySummaryCard> createState() =>
      _CheckoutDeliverySummaryCardState();
}

class _CheckoutDeliverySummaryCardState
    extends State<_CheckoutDeliverySummaryCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: buyV2CardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BuyV2DeliveryModeIcon(
                artwork: widget.artwork,
                color: BuyV2Colors.muted,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _checkoutFulfilmentCountLabel(group),
                  style: context.buyBody,
                ),
              ),
              IconButton(
                key: ValueKey('buy-checkout-items-toggle-${group.key}'),
                tooltip: _expanded ? 'Hide items' : 'Show items',
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: BuyV2Colors.ink,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _CheckoutDeliveryFact(label: 'Store', value: group.customerPartner),
          _CheckoutDeliveryFact(
            label: 'Delivery estimate',
            value: !group.hasDeliveryEstimate
                ? 'Unavailable · Check delivery before placing your order'
                : group.hasPlaceholderDeliveryPromise
                ? group.promisedByLabel!.trim()
                : buyV2DeliveryPromiseSummary(
                    promise: group.promise,
                    promisedByLabel: group.promisedByLabel,
                  ),
          ),
          if (group.dispatchPromise case final dispatch?)
            _CheckoutDeliveryFact(label: 'Dispatch estimate', value: dispatch),
          if (group.deliveryProviderName case final provider?)
            _CheckoutDeliveryFact(label: 'Planned delivery', value: provider),
          if (group.deliveryServiceLevel case final service?)
            _CheckoutDeliveryFact(label: 'Service option', value: service),
          if (_expanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Divider(height: 1),
            ),
            if (group.destination == BuyV2Destination.wholesale)
              _WholesaleCheckoutReceivingLines(group: group),
            for (final line in group.lines) ...[
              if (group.destination != BuyV2Destination.wholesale)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: _BuyDecisionLayout(
                    minimumBodyWidth: MediaQuery.textScalerOf(
                      context,
                    ).scale(120),
                    actionWidth: buyV2ValueTextSize(
                      context,
                      buyV2Money(line.total),
                      context.buyBody.copyWith(fontWeight: FontWeight.w700),
                    ).width,
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${line.quantity}× ${line.product.customerTitle}',
                          style: context.buyBody,
                        ),
                        Text(line.product.pack, style: context.buyMeta),
                      ],
                    ),
                    action: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          buyV2Money(line.total),
                          style: context.buyBody.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_purchaseProtectionLines(line.product) case final protections
                  when protections.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 3),
                  child: Text(
                    protections.first,
                    style: context.buyMeta.copyWith(
                      color: BuyV2Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CheckoutDeliveryFact extends StatelessWidget {
  const _CheckoutDeliveryFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(label, style: context.buyMeta);
    final valueText = Text(
      value,
      style: context.buyMeta.copyWith(
        color: BuyV2Colors.ink,
        fontWeight: FontWeight.w600,
      ),
    );
    if (MediaQuery.textScalerOf(context).scale(1) > 1.25) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [labelText, const SizedBox(height: 3), valueText],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: labelText),
          const SizedBox(width: 7),
          Expanded(child: valueText),
        ],
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stackAction = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final actionLabel = action == null
        ? null
        : Text(
            action!,
            style: const TextStyle(
              color: BuyV2Colors.ink,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: buyV2CardDecoration(radius: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: BuyV2ActionStyle.primaryFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: BuyV2Colors.muted, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.buyBody),
                  const SizedBox(height: 2),
                  Text(detail, style: context.buyMeta),
                  if (stackAction && actionLabel != null) ...[
                    const SizedBox(height: 4),
                    actionLabel,
                  ],
                ],
              ),
            ),
            if (!stackAction && actionLabel != null) ...[
              const SizedBox(width: 8),
              actionLabel,
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.session,
    required this.order,
    this.invoiceDownloader,
  });

  final BuyV2Session session;
  final BuyV2Order order;
  final BuyV2InvoiceDownloader? invoiceDownloader;

  @override
  Widget build(BuildContext context) {
    if (order.collection != null) {
      final owned = session.collectionOrderBelongsToCurrentAccount(order);
      final snapshot = session.collectionSnapshotFor(order.id);
      return BuyV2CartAvoidanceRegion(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Collect at store',
                  style: context.buyTitle.copyWith(fontSize: 16, height: 1.25),
                ),
                if (owned) ...[
                  Text(
                    snapshot?.storeName ?? order.customerPartner,
                    style: context.buyBody,
                  ),
                  Text(order.id, style: context.buyMeta),
                ],
                const SizedBox(height: 6),
                Text(
                  session.collectionStatusLabelFor(order.id),
                  style: context.buyBody,
                ),
                if (snapshot != null)
                  Text(
                    _collectionMoney(snapshot.totalMinor),
                    style: context.buyTitle.copyWith(
                      fontSize: 16,
                      height: 1.25,
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: FilledButton(
                    key: ValueKey('buy-order-primary-${order.id}'),
                    style: BuyV2ActionStyle.button(
                      FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    ),
                    onPressed: owned
                        ? () => session.openTracking(order.id)
                        : null,
                    child: const Text('View order'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    const amountStyle = TextStyle(
      color: BuyV2Colors.ink,
      fontSize: 13,
      fontWeight: FontWeight.w900,
    );
    final amount = _buyV2OrderMoney(order);
    final amountNeedsRow =
        buyV2ValueTextSize(context, amount, amountStyle).width >
        (MediaQuery.sizeOf(context).width - 32) * .45;
    void activatePrimaryAction() {
      HapticFeedback.selectionClick();
      session.openTracking(order.id);
    }

    return BuyV2CartAvoidanceRegion(
      child: BuyV2IntentDepth(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('buy-order-card-${order.id}'),
            onTap: activatePrimaryAction,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: buyV2CardDecoration(radius: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BuyV2TricolourLine(height: 2),
                  const SizedBox(height: 5),
                  if (order.lines.isNotEmpty) ...[
                    for (final line in order.lines.take(2)) ...[
                      Text(
                        line.product.customerTitle,
                        style: context.buyTitle.copyWith(
                          fontSize: 15,
                          height: 1.25,
                        ),
                      ),
                      Text(
                        '${line.product.pack} · Quantity ${line.quantity}',
                        style: context.buyMeta.copyWith(
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (order.lines.length > 2)
                      Text(
                        '+ ${order.lines.length - 2} more ${order.lines.length == 3 ? 'product' : 'products'}',
                        style: context.buyMeta.copyWith(fontSize: 11),
                      ),
                  ],
                  Row(
                    children: [
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: const EdgeInsets.all(6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: order.destination == BuyV2Destination.wholesale
                              ? BuyV2Colors.navy
                              : BuyV2Colors.orange,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          order.destination.label[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.id,
                              style: context.buyMeta.copyWith(fontSize: 8),
                            ),
                            if (order.lines.isEmpty)
                              Text(order.title, style: context.buyBody),
                            Text(
                              order.itemSummary,
                              style: context.buyMeta.copyWith(fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                      if (!amountNeedsRow) Text(amount, style: amountStyle),
                    ],
                  ),
                  if (amountNeedsRow)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(amount, style: amountStyle),
                    ),
                  const SizedBox(height: 5),
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _trackingStatusLabel(order.status),
                            style: const TextStyle(
                              color: BuyV2Colors.green,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${(order.progress * 100).round()}%',
                          style: const TextStyle(
                            color: BuyV2Colors.navy,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    buyV2OrderArrivalSummary(session, order),
                    style: const TextStyle(
                      color: BuyV2Colors.ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (order.updatedDeliveryEstimate != null)
                    Text(
                      buyV2OrderArrivalSummary(session, order, revised: true),
                      style: context.buyMeta.copyWith(
                        color: BuyV2Colors.orange,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: BuyV2HonestProgressIndicator(
                      ownerId: order.id,
                      progress: order.progress,
                      statusLabel: _trackingStatusLabel(order.status),
                      isComplete: order.status == BuyV2OrderStatus.delivered,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE3E5EE),
                      valueColor: BuyV2Colors.green,
                      indicatorKey: ValueKey('buy-order-progress-${order.id}'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.customerPartner} · ${order.partnerType}',
                    style: context.buyMeta.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stackActions =
                          constraints.maxWidth < 270 ||
                          MediaQuery.textScalerOf(context).scale(10) > 12;
                      final invoiceAction = SizedBox(
                        height: 44,
                        child: Align(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: OutlinedButton.icon(
                            style: BuyV2ActionStyle.button(),
                            key: ValueKey('buy-order-invoice-${order.id}'),
                            onPressed: () => _openOrderInvoice(
                              context,
                              session: session,
                              order: order,
                              downloader: invoiceDownloader,
                            ),
                            icon: const Icon(
                              Icons.receipt_long_outlined,
                              size: 17,
                            ),
                            label: const Text('Invoice'),
                          ),
                        ),
                      );
                      final primaryAction = SizedBox(
                        height: 44,
                        child: Align(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: FilledButton(
                            style: BuyV2ActionStyle.button(),
                            key: ValueKey('buy-order-primary-${order.id}'),
                            onPressed: activatePrimaryAction,
                            child: Text(
                              order.status == BuyV2OrderStatus.delivered
                                  ? 'View order'
                                  : 'Track order',
                            ),
                          ),
                        ),
                      );
                      if (stackActions) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            invoiceAction,
                            const SizedBox(height: 6),
                            primaryAction,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: invoiceAction),
                          const SizedBox(width: 6),
                          Expanded(child: primaryAction),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackingRoute extends StatelessWidget {
  const _TrackingRoute({required this.order});

  final BuyV2Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('buy-tracking-route'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: buyV2CardDecoration(radius: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivery route', style: context.buyBody.copyWith(fontSize: 9)),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: BuyV2Colors.navy,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: const SizedBox(
                    key: ValueKey('buy-tracking-route-connector'),
                    height: 5,
                    child: Center(
                      child: Divider(
                        height: 2,
                        thickness: 2,
                        color: BuyV2Colors.softBlue,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.location_on_rounded,
                color: BuyV2Colors.green,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.customerPartner,
                  style: context.buyMeta.copyWith(fontSize: 7.5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.destinationLabel,
                  textAlign: TextAlign.end,
                  style: context.buyMeta.copyWith(fontSize: 7.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingActionGroup extends StatelessWidget {
  const _TrackingActionGroup({required this.actions});

  final List<_TrackingAction> actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 6.0;
      final requiredWidth = actions.fold<double>(44, (width, action) {
        final measured =
            buyV2ValueTextSize(
              context,
              action.label,
              _TrackingAction.labelStyle,
            ).width +
            36;
        return measured > width ? measured : width;
      });
      final columns =
          ((constraints.maxWidth + spacing) / (requiredWidth + spacing))
              .floor()
              .clamp(1, actions.length);
      final cellWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (var index = 0; index < actions.length; index++)
            SizedBox(
              width:
                  index == actions.length - 1 && actions.length % columns == 1
                  ? constraints.maxWidth
                  : cellWidth,
              child: actions[index],
            ),
        ],
      );
    },
  );
}

class _TrackingAction extends StatelessWidget {
  const _TrackingAction({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.primary = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool primary;

  static const labelStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.w900);

  @override
  Widget build(BuildContext context) {
    final foreground = primary
        ? BuyV2ActionStyle.primaryForeground
        : BuyV2ActionStyle.primaryForeground;
    return Semantics(
      button: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BuyV2ActionStyle.primaryFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: primary
                  ? BuyV2ActionStyle.primaryForeground
                  : const Color(0x33000080),
            ),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onPressed();
            },
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: foreground, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: labelStyle.copyWith(color: foreground),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderDeliveryContinuation extends StatelessWidget {
  const _OrderDeliveryContinuation({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final foreground = primary
        ? BuyV2ActionStyle.primaryForeground
        : BuyV2ActionStyle.primaryForeground;
    final detailColor = context.buyMeta.color;
    return Semantics(
      button: true,
      label: '$title. $detail',
      onTap: onTap,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BuyV2ActionStyle.primaryFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: primary
                  ? BuyV2ActionStyle.primaryForeground
                  : const Color(0x33000080),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: foreground, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            detail,
                            style: context.buyMeta.copyWith(color: detailColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: foreground,
                      size: 15,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderDeliveryFact extends StatelessWidget {
  const _OrderDeliveryFact({
    required this.icon,
    required this.label,
    required this.value,
    this.deliveryArtwork,
  });

  final IconData icon;
  final String label;
  final String value;
  final BuyV2DeliveryArtwork? deliveryArtwork;

  @override
  Widget build(BuildContext context) {
    final labelWidth = 72 * MediaQuery.textScalerOf(context).scale(8) / 8;
    final labelText = Text(label, style: context.buyMeta.copyWith(fontSize: 8));
    final valueText = Text(
      value,
      style: const TextStyle(
        color: BuyV2Colors.ink,
        fontSize: 9,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth - labelWidth - 29 < 140;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (deliveryArtwork case final artwork?)
                BuyV2DeliveryModeIcon(artwork: artwork, size: 16)
              else
                Icon(icon, color: BuyV2Colors.navy, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          labelText,
                          const SizedBox(height: 2),
                          valueText,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: labelWidth, child: labelText),
                          const SizedBox(width: 6),
                          Expanded(child: valueText),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline({required this.order});

  final BuyV2Order order;

  @override
  Widget build(BuildContext context) {
    final completedSteps = switch (order.status) {
      BuyV2OrderStatus.preparing => 1,
      BuyV2OrderStatus.confirmed => 0,
      BuyV2OrderStatus.dispatched => 2,
      BuyV2OrderStatus.arriving => 3,
      BuyV2OrderStatus.delivered => 5,
    };
    const steps = [
      ('Confirmed', 'Seller accepted every product'),
      ('Packing', 'Items are being checked and packed'),
      ('Dispatched', 'Partner handed over the order'),
      ('Arriving', 'Delivery is travelling to the address'),
      ('Delivered', 'Delivery confirmation at the address'),
    ];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: buyV2CardDecoration(radius: 13),
      child: Column(
        children: [
          for (final indexed in steps.indexed)
            Padding(
              padding: EdgeInsets.only(
                bottom: indexed.$1 == steps.length - 1 ? 0 : 5,
              ),
              child: Semantics(
                label:
                    '${indexed.$2.$1}. ${indexed.$2.$2}. '
                    '${indexed.$1 < completedSteps
                        ? 'Complete'
                        : indexed.$1 == completedSteps
                        ? 'Last recorded stage'
                        : 'Upcoming'}',
                excludeSemantics: true,
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: BuyV2Motion.resolved(
                        context,
                        BuyV2Motion.stateChange,
                      ),
                      curve: Curves.easeInOutCubic,
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        color: indexed.$1 < completedSteps
                            ? BuyV2Colors.green
                            : indexed.$1 == completedSteps
                            ? BuyV2Colors.softOrange
                            : BuyV2Colors.softBlue,
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                        duration: BuyV2Motion.resolved(
                          context,
                          BuyV2Motion.stateChange,
                        ),
                        child: Icon(
                          key: ValueKey(
                            'tracking-step-${indexed.$1}-$completedSteps',
                          ),
                          indexed.$1 < completedSteps
                              ? Icons.check
                              : indexed.$1 == completedSteps
                              ? Icons.radio_button_checked_rounded
                              : Icons.circle_outlined,
                          size: 13,
                          color: indexed.$1 < completedSteps
                              ? Colors.white
                              : indexed.$1 == completedSteps
                              ? BuyV2Colors.orange
                              : BuyV2Colors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(indexed.$2.$1, style: context.buyBody),
                          Text(indexed.$2.$2, style: context.buyMeta),
                        ],
                      ),
                    ),
                    if (indexed.$1 == completedSteps)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: BuyV2Colors.softOrange,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          'RECORDED',
                          style: TextStyle(
                            color: BuyV2Colors.navy,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AssistIntent extends StatefulWidget {
  const _AssistIntent({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AssistIntent> createState() => _AssistIntentState();
}

class _AssistIntentState extends State<_AssistIntent> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? BuyV2Motion.pressScale : 1,
      duration: BuyV2Motion.resolved(context, BuyV2Motion.press),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('buy-assist-intent-${widget.label}'),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: BuyV2Motion.resolved(context, BuyV2Motion.stateChange),
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: widget.selected ? BuyV2Colors.softGreen : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.selected ? BuyV2Colors.green : BuyV2Colors.line,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 19,
                  color: widget.selected ? BuyV2Colors.green : BuyV2Colors.navy,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: BuyV2Colors.ink,
                      fontSize: 9,
                      height: 1.1,
                      fontWeight: widget.selected
                          ? FontWeight.w900
                          : FontWeight.w800,
                    ),
                  ),
                ),
                if (widget.selected)
                  const Icon(
                    Icons.check_rounded,
                    size: 17,
                    color: BuyV2Colors.green,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistChannel extends StatefulWidget {
  const _AssistChannel({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  State<_AssistChannel> createState() => _AssistChannelState();
}

class _AssistChannelState extends State<_AssistChannel> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? BuyV2Motion.pressScale : 1,
      duration: BuyV2Motion.resolved(context, BuyV2Motion.press),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('buy-assist-channel-${widget.title}'),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: buyV2CardDecoration(radius: 15, shadow: true),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BuyV2Colors.softBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: BuyV2Colors.navy, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.title, style: context.buyBody),
                      Text(widget.detail, style: context.buyMeta),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: BuyV2Colors.muted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrescriptionChoice extends StatelessWidget {
  const _PrescriptionChoice({
    required this.keyName,
    required this.doctor,
    required this.detail,
    required this.onTap,
  });

  final String keyName;
  final String doctor;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = '$doctor, $detail, Saved prescription';
    return Semantics(
      key: ValueKey('buy-prescription-semantics-$keyName'),
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: BuyV2Colors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('buy-prescription-$keyName'),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: BuyV2ActionStyle.primaryFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Rx',
                        style: TextStyle(
                          color: BuyV2ActionStyle.foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctor, style: context.buyBody),
                          Text(detail, style: context.buyMeta),
                          Text('Saved prescription', style: context.buyMeta),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: BuyV2Colors.navy,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPrescriptionChoice extends StatelessWidget {
  const _AddPrescriptionChoice({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const label =
        'Add a new prescription, Match medicines for review in this session';
    return Semantics(
      key: const ValueKey('buy-prescription-add-new-semantics'),
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: BuyV2Colors.softBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: BuyV2Colors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('buy-prescription-add-new'),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: BuyV2ActionStyle.primaryFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.note_add_outlined,
                        color: BuyV2ActionStyle.foreground,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add a new prescription',
                            style: context.buyBody,
                          ),
                          Text(
                            'Match medicines for review in this session',
                            style: context.buyMeta,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: BuyV2Colors.navy,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareChoice extends StatefulWidget {
  const _ShareChoice({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_ShareChoice> createState() => _ShareChoiceState();
}

class _ShareChoiceState extends State<_ShareChoice> {
  bool pressed = false;

  void handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        container: true,
        button: true,
        label: widget.label,
        onTap: handleTap,
        child: ExcludeSemantics(
          child: AnimatedScale(
            scale: pressed ? BuyV2Motion.pressScale : 1,
            duration: BuyV2Motion.resolved(context, BuyV2Motion.press),
            child: InkWell(
              onTap: handleTap,
              onHighlightChanged: (value) {
                if (mounted) setState(() => pressed = value);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                constraints: const BoxConstraints(minHeight: 66),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: buyV2CardDecoration(
                  radius: 14,
                  color: pressed ? BuyV2Colors.softBlue : Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: BuyV2Colors.navy),
                    const SizedBox(height: 3),
                    Text(
                      widget.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
