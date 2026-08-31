import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/buy/buy_v2_cart_contracts.dart';
import '../../features/buy/buy_v2_content_contracts.dart';
import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_order_resolution_contracts.dart';
import '../../features/buy/buy_v2_saved_products_store.dart';
import '../../features/buy/buy_v2_session.dart';
import '../../features/journey01/journey_services.dart';
import 'buy_v2_address_form_sheet_motion.dart';
import 'buy_v2_address_sheet_motion.dart';
import 'buy_v2_design.dart';
import 'buy_v2_filter_sheet_motion.dart';
import 'buy_v2_invoice.dart';
import 'buy_v2_payment_sheet_motion.dart';
import 'buy_v2_prescription_sheet_motion.dart';
import 'buy_v2_product_feedback_sheet_motion.dart';
import 'buy_v2_supplier_sheet_motion.dart';

String _productCountLabel(int count) =>
    '$count ${count == 1 ? 'product' : 'products'}';

String _packCountLabel(int count) => '$count ${count == 1 ? 'pack' : 'packs'}';

bool _containsOnlyWholesaleLines(List<BuyV2CartLine> lines) =>
    lines.isNotEmpty &&
    lines.every(
      (line) => line.product.destination == BuyV2Destination.wholesale,
    );

String _checkoutFulfilmentCountLabel(BuyV2FulfilmentGroup group) =>
    group.destination == BuyV2Destination.wholesale
    ? '${_productCountLabel(group.lines.length)} · '
          '${_packCountLabel(group.itemCount)}'
    : _productCountLabel(group.itemCount);

String _checkoutDockCountLabel(BuyV2Session session) =>
    session.checkoutScope == BuyV2CartScope.wholesale ||
        _containsOnlyWholesaleLines(session.checkoutLines)
    ? '${_productCountLabel(session.checkoutLines.length)} · '
          '${_packCountLabel(session.checkoutItemCount)}'
    : _productCountLabel(session.checkoutItemCount);

String _cartHeaderSummary(BuyV2Session session) {
  final lines = session.cartLines;
  final destinations = lines.map((line) => line.product.destination).toSet();
  final quantityLabel =
      session.cartScope == BuyV2CartScope.wholesale ||
          _containsOnlyWholesaleLines(lines)
      ? _packCountLabel(session.scopedItemCount)
      : '${session.scopedItemCount} '
            '${session.scopedItemCount == 1 ? 'item' : 'items'}';
  return '${_productCountLabel(lines.length)} · $quantityLabel · '
      '${_destinationSummary(destinations)} · '
      '${buyV2Money(session.scopedCartTotal)}';
}

String _destinationSummary(Set<BuyV2Destination> destinations) {
  const order = [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
    BuyV2Destination.medicine,
  ];
  return order
      .where(destinations.contains)
      .map((destination) => destination.label)
      .join(' + ');
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
  int _nextId = 1;
  int _mutationRevision = 0;
  String? _ownerScope;
  bool _restoring = false;
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

  bool get busy => _busy;

  String? get message => _message;

  void clearMessage() {
    if (_message == null) return;
    _message = null;
    _notify();
  }

  Future<void> restore() async {
    final profileStore = store;
    final ownerScope = profileStore?.ownerScope;
    if (profileStore == null ||
        ownerScope == null ||
        ownerScope == _ownerScope ||
        _restoring) {
      return;
    }
    _ownerScope = ownerScope;
    _savedProfiles.clear();
    _selected.clear();
    _restoring = true;
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
    } on Object {
      if (!_disposed && profileStore.ownerScope == ownerScope) {
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

  Future<bool> save({
    required BuyV2Destination destination,
    required String legalName,
    required String gstin,
    required String billingAddress,
    required bool remember,
  }) async {
    if (_busy) return false;
    if (remember && !persistenceAvailable) {
      _message = 'Saved GST details are unavailable. Try again.';
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
      final candidate = [..._savedProfiles];
      final index = candidate.indexWhere((item) => item.id == details.id);
      if (index == -1) {
        candidate.add(details);
      } else {
        candidate[index] = details;
      }
      if (!await _writeProfiles(candidate)) return false;
      _savedProfiles
        ..clear()
        ..addAll(candidate);
    }
    _requested[destination] = true;
    _selected[destination] = details;
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
    _selected.removeWhere((_, selected) => selected.id == details.id);
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
      if (profileStore.ownerScope != ownerScope || !saved) {
        _message = 'GST details could not be saved. Try again.';
        return false;
      }
      return true;
    } on Object {
      if (profileStore.ownerScope == ownerScope) {
        _message = 'GST details could not be saved. Try again.';
      }
      return false;
    } finally {
      if (!_disposed) {
        if (profileStore.ownerScope != ownerScope) {
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

String _fulfilmentPromiseSummary(BuyV2FulfilmentGroup group) =>
    buyV2DeliveryPromiseSummary(
      promise: group.promise,
      promisedByLabel: group.promisedByLabel,
    );

String _orderPromiseSummary(BuyV2Order order) => buyV2DeliveryPromiseSummary(
  promise: order.promise,
  promisedByLabel: order.promisedByLabel,
);

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

class BuyV2ProductView extends StatelessWidget {
  const BuyV2ProductView({
    super.key,
    required this.session,
    this.returnLabel,
    this.onAskSeller,
    this.wholesaleTradeDecisionAdapter =
        const BuyV2UnavailableWholesaleTradeDecisionAdapter(),
  });

  final BuyV2Session session;
  final String? returnLabel;
  final ValueChanged<BuyV2Product>? onAskSeller;
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
    final trust = session.marketplaceTrustFor(product);
    final productBenefits = session.productBenefitsFor(product);
    final productBenefitsState = session.productBenefitsStateFor(product);
    final variants = session.productVariantsFor(product);
    final automaticFulfilment =
        product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale;
    final wholesale = product.destination == BuyV2Destination.wholesale;
    final buyerPromise = automaticFulfilment
        ? buyV2BuyerDeliveryPromise(facts)
        : facts.deliveryPromise;
    final offerDecision = automaticFulfilment
        ? buyV2ResolveProductOfferDecision(product: product, facts: facts)
        : null;
    final partnerProducts = switch (product.destination) {
      BuyV2Destination.shop ||
      BuyV2Destination.medicine => session.sellerContinuationsFor(product),
      BuyV2Destination.wholesale ||
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

    return Column(
      children: [
        Expanded(
          child: ListView(
            key: PageStorageKey('buy-product-${product.id}'),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            children: [
              _ReturnAffordance(
                label: returnLabel ?? product.destination.label,
                onTap: session.closeProduct,
              ),
              const SizedBox(height: 7),
              BuyV2FiniteDepthReveal(
                key: ValueKey('buy-product-media-reveal-${product.id}'),
                stateKey: 'buy-product-media-${product.id}',
                child: _BuyV2ProductGallery(
                  key: ValueKey('buy-product-packshot-${product.id}'),
                  product: product,
                  compact: wholesale,
                  media: [
                    for (final media
                        in content.media.isEmpty
                            ? [
                                BuyV2ProductMediaAsset(
                                  id: '${product.id}-packshot-fallback',
                                  label: 'Product image',
                                  semanticLabel:
                                      '${product.title}, ${product.pack}',
                                  kind: BuyV2ProductContentMediaKind
                                      .cataloguePackshot,
                                ),
                              ]
                            : content.media)
                      _BuyV2ProductMediaItem(
                        label: media.label,
                        child: _ProductContentMediaSurface(
                          product: product,
                          media: media,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              BuyV2FiniteIncomingTransition(
                key: ValueKey('buy-product-title-reveal-${product.id}'),
                stateKey: 'buy-product-title-${product.id}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      style: context.buyEyebrow.copyWith(fontSize: 8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.title,
                      key: ValueKey('buy-product-title-${product.id}'),
                      style: context.buyTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.composition ?? product.variant,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.buyBody.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.pack,
                      style: context.buyMeta.copyWith(fontSize: 9),
                    ),
                    if (!automaticFulfilment) ...[
                      const SizedBox(height: 8),
                      _ProductOwnedActionPanel(
                        key: ValueKey(
                          'buy-product-inline-action-${product.id}',
                        ),
                        product: product,
                        quantity: quantity,
                        deliveryDecision: buyerPromise,
                        rxBlocked: rxBlocked,
                        onAdd: addProduct,
                        onDecrease: () => session.decrease(product.id),
                        onIncrease: () => session.increase(product.id),
                      ),
                    ],
                  ],
                ),
              ),
              if (variants.length > 1) ...[
                const SizedBox(height: 8),
                _ProductVariantSelector(
                  session: session,
                  product: product,
                  variants: variants,
                ),
              ],
              if (automaticFulfilment && !wholesale) ...[
                const SizedBox(height: 7),
                _ProductDecisionGlance(
                  product: product,
                  facts: facts,
                  decision: offerDecision!,
                  buyerPromise: buyerPromise,
                ),
              ],
              if (!wholesale) ...[
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _ProductTrustPill(
                      icon: Icons.star_rounded,
                      label: trust.productRating == null
                          ? 'No verified ratings yet'
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
              ],
              const SizedBox(height: 8),
              if (wholesale)
                Column(
                  children: [
                    if (!session.businessVerified) ...[
                      _WholesaleVerificationCard(
                        state: session.businessVerificationState,
                        onOpenWorkspace: () =>
                            context.push('/app/work/workspace'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _WholesaleTradeDecisionPanel(
                      session: session,
                      product: product,
                      facts: facts,
                      decision: offerDecision!,
                      buyerPromise: buyerPromise,
                      adapter: wholesaleTradeDecisionAdapter,
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
                  quantity: quantity,
                  onAdd: addProduct,
                  onBuyNow: () => session.buyProductNow(product.id),
                  onDecrease: () => session.decrease(product.id),
                  onIncrease: () => session.increase(product.id),
                )
              else
                _DecisionPanel(
                  title: 'Pack, delivery and pharmacy',
                  children: [
                    _DecisionRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Pack',
                      value: product.pack,
                    ),
                    _DecisionRow(
                      icon: Icons.schedule_rounded,
                      label: 'Delivery',
                      value: buyerPromise,
                      valueColor: BuyV2Colors.green,
                    ),
                    if (partnerProducts.isEmpty)
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
                        onTap: () => _showPartnerProductsSheet(
                          context,
                          session,
                          product,
                          partnerProducts,
                        ),
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
              if (product.destination == BuyV2Destination.shop ||
                  product.destination == BuyV2Destination.wholesale) ...[
                const SizedBox(height: 10),
                _ProductBenefitsPreview(
                  session: session,
                  product: product,
                  benefits: productBenefits,
                  state: productBenefitsState,
                  customerMessage: session.productBenefitsMessageFor(product),
                ),
              ],
              if (product.destination == BuyV2Destination.medicine) ...[
                const SizedBox(height: 10),
                _DecisionPanel(
                  title: 'Medicine information',
                  children: [
                    _DecisionRow(
                      icon: Icons.science_outlined,
                      label: 'Composition',
                      value: product.composition ?? product.variant,
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
              const SizedBox(height: 10),
              _DecisionPanel(
                title: 'Product details',
                children: [
                  _DecisionRow(
                    icon: Icons.sell_outlined,
                    label: 'Brand',
                    value: product.brand,
                  ),
                  _DecisionRow(
                    icon: Icons.tune_rounded,
                    label: 'Variant',
                    value: product.variant,
                  ),
                  _DecisionRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Pack size',
                    value: product.pack,
                  ),
                  if (automaticFulfilment)
                    _DecisionRow(
                      icon: Icons.location_on_outlined,
                      label: 'Service area',
                      value:
                          session.selectedAddressOrNull?.shortLine ??
                          'Based on your delivery address',
                    )
                  else
                    _DecisionRow(
                      icon: Icons.route_outlined,
                      label: 'Source route',
                      value: product.origin,
                    ),
                  if (product.returnPolicy case final returnPolicy?)
                    _DecisionRow(
                      icon: Icons.assignment_return_outlined,
                      label: 'After delivery',
                      value: returnPolicy,
                    ),
                ],
              ),
              const SizedBox(height: 10),
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
                onViewSeller:
                    product.destination == BuyV2Destination.shop &&
                        partnerProducts.isNotEmpty
                    ? () => _showPartnerProductsSheet(
                        context,
                        session,
                        product,
                        partnerProducts,
                      )
                    : null,
                sellerProductCount: partnerProducts.length,
              ),
              const SizedBox(height: 10),
              _ProductReviewsPanel(
                product: product,
                review: review,
                onReview: session.canReviewProduct(product.id)
                    ? () => _showProductReviewSheet(context, session, product)
                    : null,
                onReport: session.canReportProduct(product.id)
                    ? () => _showProductReportSheet(context, session, product)
                    : null,
                reported: session.hasReportedProduct(product.id),
              ),
              if (product.destination == BuyV2Destination.shop ||
                  product.destination == BuyV2Destination.wholesale) ...[
                const SizedBox(height: 8),
                _ProductQuickActions(
                  session: session,
                  product: product,
                  onAskSeller: onAskSeller,
                ),
              ],
              const SizedBox(height: 10),
              _ProductContinuationSection(session: session, product: product),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (wholesale)
          _WholesaleTradeActionDock(
            product: product,
            facts: facts,
            decision: offerDecision!,
            quantity: quantity,
            onAdd: addProduct,
            onBuyNow: () => session.buyProductNow(product.id),
            onDecrease: () => session.decrease(product.id),
            onIncrease: () => session.increase(product.id),
            onRetryOffer: () => session.refreshProductFacts(product.id),
            businessVerified: session.businessVerified,
            onOpenWorkspace: () => context.push('/app/work/workspace'),
          ),
      ],
    );
  }
}

class _ProductQuickActions extends StatelessWidget {
  const _ProductQuickActions({
    required this.session,
    required this.product,
    required this.onAskSeller,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final ValueChanged<BuyV2Product>? onAskSeller;

  @override
  Widget build(BuildContext context) {
    final saved = session.isSaved(product.id);
    final compareProducts = <BuyV2Product>[
      product,
      ...session
          .productVariantsFor(product)
          .where((candidate) => candidate.id != product.id),
      ...session.productContinuationsFor(product, limit: 4),
    ];
    final uniqueCompareProducts = <BuyV2Product>[];
    final seenIds = <String>{};
    for (final candidate in compareProducts) {
      if (seenIds.add(candidate.id)) uniqueCompareProducts.add(candidate);
      if (uniqueCompareProducts.length == 4) break;
    }
    final actions = <({IconData icon, String label, VoidCallback onPressed})>[
      (
        icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        label: saved ? 'Saved' : 'Save',
        onPressed: () => session.toggleSaved(product.id),
      ),
      (
        icon: Icons.ios_share_outlined,
        label: 'Share',
        onPressed: () => unawaited(
          _shareBuyV2Product(context, session: session, product: product),
        ),
      ),
      if (uniqueCompareProducts.length > 1)
        (
          icon: Icons.compare_arrows_rounded,
          label: 'Compare',
          onPressed: () => unawaited(
            _showBuyV2ProductComparison(
              context,
              session: session,
              current: product,
              products: uniqueCompareProducts,
            ),
          ),
        ),
      if (onAskSeller != null)
        (
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Ask seller',
          onPressed: () => onAskSeller!(product),
        ),
    ];
    return Semantics(
      key: ValueKey('buy-product-quick-actions-${product.id}'),
      container: true,
      label: 'Product actions for ${product.title}',
      child: Container(
        height: 56,
        decoration: buyV2CardDecoration(
          color: BuyV2Colors.softBlue.withValues(alpha: .42),
          radius: 15,
        ),
        child: Row(
          children: [
            for (final action in actions)
              Expanded(
                child: _ProductQuickActionButton(
                  key: ValueKey(
                    'buy-product-action-${action.label.toLowerCase().replaceAll(' ', '-')}-${product.id}',
                  ),
                  icon: action.icon,
                  label: action.label,
                  onPressed: action.onPressed,
                ),
              ),
          ],
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
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: BuyV2Colors.navy),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.buyMeta.copyWith(
                    color: BuyV2Colors.navy,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    height: 1,
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
  try {
    await SharePlus.instance.share(
      ShareParams(
        title: product.title,
        subject: '${product.title} on MoolSocial',
        text:
            '${product.title} · ${product.pack}\n'
            '${buyV2Money(facts.price)} · ${buyV2BuyerDeliveryPromise(facts)}\n'
            'Available from ${facts.partner} on MoolSocial.',
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
  required List<BuyV2Product> products,
}) async {
  final selectedId = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          14,
          0,
          14,
          18 + MediaQuery.viewPaddingOf(sheetContext).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Compare products',
              style: sheetContext.buyTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 3),
            Text(
              'Review pack, price, delivery and seller details side by side.',
              style: sheetContext.buyMeta,
            ),
            const SizedBox(height: 10),
            for (final product in products) ...[
              _ProductComparisonCard(
                session: session,
                product: product,
                selected: product.id == current.id,
                onView: () => Navigator.of(sheetContext).pop(product.id),
              ),
              if (product != products.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
  if (selectedId != null && selectedId != current.id && context.mounted) {
    session.openProduct(selectedId);
  }
}

class _ProductComparisonCard extends StatelessWidget {
  const _ProductComparisonCard({
    required this.session,
    required this.product,
    required this.selected,
    required this.onView,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final bool selected;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final facts = session.productFactsFor(product);
    return Container(
      key: ValueKey('buy-product-compare-${product.id}'),
      padding: const EdgeInsets.all(10),
      decoration: buyV2CardDecoration(
        color: selected ? BuyV2Colors.softBlue : Colors.white,
        radius: 15,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: 76,
            child: BuyV2ProductPackshot(product: product, borderRadius: 12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.buyBody.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(product.pack, style: context.buyMeta),
                const SizedBox(height: 4),
                Text(
                  '${buyV2Money(facts.price)} · ${buyV2BuyerDeliveryPromise(facts)}',
                  style: context.buyMeta.copyWith(
                    color: BuyV2Colors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(facts.partner, style: context.buyMeta),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: BuyV2Metrics.minimumTap,
            child: TextButton(
              key: ValueKey('buy-product-compare-view-${product.id}'),
              onPressed: selected ? null : onView,
              child: Text(selected ? 'Viewing' : 'View'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductVariantSelector extends StatelessWidget {
  const _ProductVariantSelector({
    required this.session,
    required this.product,
    required this.variants,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final List<BuyV2Product> variants;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('buy-product-variants-${product.canonicalId}'),
      padding: const EdgeInsets.all(10),
      decoration: buyV2CardDecoration(radius: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose an option',
            style: context.buyTitle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            'Choose the pack that fits your order. Price, availability and delivery update with your choice.',
            style: context.buyMeta.copyWith(fontSize: 8),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
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
    );
  }
}

class _ProductVariantOption extends StatelessWidget {
  const _ProductVariantOption({
    required this.session,
    required this.option,
    required this.selected,
    required this.width,
  });

  final BuyV2Session session;
  final BuyV2Product option;
  final bool selected;
  final double width;

  @override
  Widget build(BuildContext context) {
    final facts = session.productFactsFor(option);
    final decision = buyV2ResolveProductOfferDecision(
      product: option,
      facts: facts,
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
          '${option.pack}, ${buyV2Money(facts.price)}, ${decision.statusLabel}',
      onTap: select,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Material(
          color: selected ? BuyV2Colors.softGreen : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: BorderSide(
              color: selected ? BuyV2Colors.green : BuyV2Colors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('buy-product-variant-${option.id}'),
            onTap: select,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      option.pack,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.buyBody.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      buyV2Money(facts.price),
                      style: const TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      decision.statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.buyMeta.copyWith(
                        color: statusColor,
                        fontSize: 7.5,
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

class _ProductDecisionGlance extends StatelessWidget {
  const _ProductDecisionGlance({
    required this.product,
    required this.facts,
    required this.decision,
    required this.buyerPromise,
  });

  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final BuyV2ProductOfferDecision decision;
  final String buyerPromise;

  @override
  Widget build(BuildContext context) {
    final statusColor = decision.canAdd
        ? BuyV2Colors.green
        : BuyV2Colors.orange;
    final surfaceColor = decision.canAdd
        ? BuyV2Colors.softGreen
        : BuyV2Colors.softOrange;
    return Semantics(
      key: ValueKey('buy-product-decision-glance-${product.id}'),
      container: true,
      label:
          '${buyV2Money(facts.price)} delivered price. '
          '${product.pack}. ${decision.statusLabel}. $buyerPromise. '
          '${buyV2AutomaticFulfilmentLabel(product.destination)}.',
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(BuyV2Metrics.radius),
          border: Border.all(color: statusColor.withValues(alpha: .28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DELIVERED PRICE',
                        style: context.buyEyebrow.copyWith(
                          color: BuyV2Colors.navy,
                          fontSize: 8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        buyV2Money(facts.price),
                        style: const TextStyle(
                          color: BuyV2Colors.navy,
                          fontSize: 22,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(
                      BuyV2Metrics.compactRadius,
                    ),
                    border: Border.all(
                      color: statusColor.withValues(alpha: .34),
                    ),
                  ),
                  child: Text(
                    decision.statusLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.buyMeta.copyWith(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: BuyV2Colors.navy,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${product.pack} · $buyerPromise',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.buyBody.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: BuyV2Colors.navy,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Automatic Mool Partner assignment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.buyMeta.copyWith(
                      color: BuyV2Colors.ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
        'Open Workspace to review the requested business details.',
      BuyV2BusinessVerificationState.unavailable =>
        'Use your verified Workspace for trade pricing, invoices and eligible payment methods.',
      BuyV2BusinessVerificationState.verified =>
        'Wholesale ordering is available for this Workspace.',
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
            child: FilledButton.icon(
              key: const ValueKey('buy-wholesale-open-workspace'),
              onPressed: onOpenWorkspace,
              icon: const Icon(Icons.storefront_outlined, size: 18),
              label: const Text('Open Workspace'),
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
    required this.adapter,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final BuyV2ProductOfferDecision decision;
  final String buyerPromise;
  final BuyV2WholesaleTradeDecisionAdapter adapter;

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
    final fulfilmentMode =
        facts.fulfilmentMode ?? buyV2CatalogueFulfilmentModeFor(product);
    final supplierProducts = widget.session.supplierContinuationsFor(product);
    final statusColor = decision.canAdd
        ? BuyV2Colors.green
        : BuyV2Colors.orange;
    final minimumTotal = facts.price * product.minimumOrder;
    final signalSummary = _loading
        ? 'Checking local market insight.'
        : _failure != null
        ? 'Local market insight could not be loaded.'
        : '${_signal!.headline}. ${_signal!.detail}';

    return Semantics(
      key: ValueKey('buy-wholesale-trade-decision-${product.id}'),
      container: true,
      label:
          '${product.title}. ${product.pack}. Minimum order '
          '${product.minimumOrder} packs. ${buyV2Money(facts.price)} per pack. '
          '${buyV2Money(minimumTotal)} minimum order total. '
          '${facts.orderabilityLabel}. ${widget.buyerPromise}. '
          '${buyV2AutomaticFulfilmentLabel(product.destination)}. '
          '${decision.statusLabel}. $signalSummary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WholesaleTradePriceSummary(
            product: product,
            facts: facts,
            decision: decision,
          ),
          const SizedBox(height: 8),
          _WholesaleTradeSignalCard(
            loading: _loading,
            signal: _signal,
            failed: _failure != null,
            onRetry: _loadSignal,
          ),
          const SizedBox(height: 8),
          _DecisionPanel(
            key: ValueKey('buy-automatic-fulfilment-${product.id}'),
            title: 'Order details',
            children: [
              _DecisionRow(
                icon: decision.canAdd
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                label: 'Availability',
                value: decision.statusLabel,
                valueColor: statusColor,
              ),
              _DecisionRow(
                icon: Icons.inventory_2_outlined,
                label: 'Trade pack',
                value: '${product.pack} · MOQ ${product.minimumOrder} packs',
              ),
              _DecisionRow(
                icon: Icons.calculate_outlined,
                label: 'Minimum total',
                value:
                    '${product.minimumOrder} × ${buyV2Money(facts.price)} = '
                    '${buyV2Money(minimumTotal)}',
              ),
              _DecisionRow(
                icon: Icons.straighten_rounded,
                label: 'Unit economics',
                value: product.unitPrice,
              ),
              _DecisionRow(
                icon: Icons.inventory_outlined,
                label: 'Stock',
                value: facts.orderabilityLabel,
                valueColor: statusColor,
              ),
              _DecisionRow(
                icon: Icons.schedule_rounded,
                label: 'Delivery',
                value: widget.buyerPromise,
                valueColor: decision.canAdd ? BuyV2Colors.green : statusColor,
              ),
              if (facts.dispatchPromise case final dispatchPromise?)
                _DecisionRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Dispatch',
                  value: dispatchPromise,
                ),
              if (facts.deliveryProviderName case final provider?)
                _DecisionRow(
                  icon: Icons.local_shipping_outlined,
                  label: 'Delivery provider',
                  value: provider,
                ),
              if (facts.deliveryServiceLevel case final serviceLevel?)
                _DecisionRow(
                  icon: Icons.route_outlined,
                  label: 'Delivery service',
                  value: serviceLevel,
                ),
              _DecisionRow(
                icon: Icons.local_shipping_outlined,
                label: 'Delivery mode',
                value: buyV2FulfilmentModeLabel(fulfilmentMode),
              ),
              _DecisionRow(
                icon: Icons.storefront_outlined,
                label: 'Fulfilment',
                value: buyV2AutomaticFulfilmentLabel(product.destination),
              ),
              if (supplierProducts.isEmpty)
                _DecisionRow(
                  icon: Icons.storefront_outlined,
                  label: product.partnerRole,
                  value: facts.partner,
                )
              else
                _DecisionActionRow(
                  key: ValueKey('buy-wholesale-supplier-action-${product.id}'),
                  icon: Icons.storefront_outlined,
                  label: product.partnerRole,
                  value: facts.partner,
                  detail:
                      '${supplierProducts.length} other current trade packs',
                  semanticLabel:
                      'View ${supplierProducts.length} more products available from ${facts.partner}',
                  onTap: () => _showPartnerProductsSheet(
                    context,
                    widget.session,
                    product,
                    supplierProducts,
                  ),
                ),
              _DecisionRow(
                icon: Icons.local_shipping_outlined,
                label: 'Freight',
                value: product.freightIncluded
                    ? 'Included in landed price'
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
                      OutlinedButton.icon(
                        key: ValueKey('buy-offer-retry-${product.id}'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          widget.session.refreshProductFacts(product.id);
                          _loadSignal();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry offer'),
                      ),
                      FilledButton.icon(
                        key: ValueKey('buy-offer-change-product-${product.id}'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: widget.session.closeProduct,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: const Text('Change product'),
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

class _WholesaleTradePriceSummary extends StatelessWidget {
  const _WholesaleTradePriceSummary({
    required this.product,
    required this.facts,
    required this.decision,
  });

  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final BuyV2ProductOfferDecision decision;

  @override
  Widget build(BuildContext context) {
    final minimumTotal = facts.price * product.minimumOrder;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    return Container(
      key: ValueKey('buy-wholesale-price-summary-${product.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF070773), BuyV2Colors.royal],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000080),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = largeText || constraints.maxWidth < 300;
          final price = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'WHOLESALE PRICE',
                style: TextStyle(
                  color: Color(0xFFBFC3FF),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                buyV2Money(facts.price),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${product.pack} · ${product.unitPrice} · MoolSocial price',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
          final order = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: .18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MOQ ${product.minimumOrder} packs',
                  style: const TextStyle(
                    color: Color(0xFFFFD29F),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${buyV2Money(minimumTotal)} minimum total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  decision.statusLabel,
                  style: TextStyle(
                    color: decision.canAdd
                        ? const Color(0xFFBDEBB8)
                        : const Color(0xFFFFD29F),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [price, const SizedBox(height: 10), order],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: price),
              const SizedBox(width: 10),
              Flexible(child: order),
            ],
          );
        },
      ),
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
              OutlinedButton.icon(
                key: const ValueKey('buy-wholesale-trade-signal-retry'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Check local insight again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WholesaleTradeActionDock extends StatelessWidget {
  const _WholesaleTradeActionDock({
    required this.product,
    required this.facts,
    required this.decision,
    required this.quantity,
    required this.onAdd,
    required this.onBuyNow,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRetryOffer,
    required this.businessVerified,
    required this.onOpenWorkspace,
  });

  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final BuyV2ProductOfferDecision decision;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onBuyNow;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRetryOffer;
  final bool businessVerified;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final orderQuantity = quantity > 0 ? quantity : product.minimumOrder;
    final orderTotal = facts.price * orderQuantity;
    final fulfilmentMode =
        facts.fulfilmentMode ?? buyV2CatalogueFulfilmentModeFor(product);
    final deliveryDecision =
        '${buyV2FulfilmentModeLabel(fulfilmentMode)} · '
        '${buyV2BuyerDeliveryPromise(facts)}';
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          quantity > 0
              ? '$quantity packs in Cart'
              : 'Minimum ${product.minimumOrder} packs · ${product.pack} each',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.buyMeta.copyWith(
            color: BuyV2Colors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          buyV2Money(orderTotal),
          key: const ValueKey('buy-wholesale-dock-total'),
          style: const TextStyle(
            color: BuyV2Colors.navy,
            fontSize: 18,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          deliveryDecision,
          key: ValueKey('buy-wholesale-dock-delivery-${product.id}'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.buyMeta.copyWith(
            color: BuyV2Colors.green,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );

    Widget action;
    if (!businessVerified) {
      action = FilledButton.icon(
        key: ValueKey('buy-wholesale-verify-business-${product.id}'),
        onPressed: onOpenWorkspace,
        icon: const Icon(Icons.verified_user_outlined),
        label: const Text('Verify business'),
      );
    } else if (!decision.canAdd) {
      action = FilledButton.icon(
        key: ValueKey('buy-wholesale-retry-offer-${product.id}'),
        onPressed: onRetryOffer,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry offer'),
      );
    } else if (quantity > 0) {
      action = _CompactProductStepper(
        key: ValueKey('buy-product-quantity-${product.id}'),
        quantity: quantity,
        onDecrease: onDecrease,
        onIncrease: onIncrease,
      );
    } else {
      action = Semantics(
        label:
            'Add minimum order of ${product.minimumOrder} packs of '
            '${product.title} to Cart for ${buyV2Money(orderTotal)}. '
            '$deliveryDecision',
        button: true,
        onTap: onAdd,
        excludeSemantics: true,
        child: FilledButton.icon(
          key: ValueKey('buy-product-primary-${product.id}'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
          onPressed: onAdd,
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: Text('Add ${product.minimumOrder} packs'),
        ),
      );
    }

    final actionGroup = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 50, child: action),
        if (businessVerified && decision.canAdd) ...[
          const SizedBox(height: 5),
          SizedBox(
            height: BuyV2Metrics.minimumTap,
            child: OutlinedButton.icon(
              key: ValueKey('buy-wholesale-buy-now-${product.id}'),
              onPressed: onBuyNow,
              icon: const Icon(Icons.flash_on_rounded, size: 17),
              label: const Text('Buy now'),
            ),
          ),
        ],
      ],
    );

    return Material(
      key: ValueKey('buy-wholesale-action-dock-${product.id}'),
      color: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x26000080),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = largeText || constraints.maxWidth < 330;
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [summary, const SizedBox(height: 8), actionGroup],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: summary),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 148,
                      maxWidth: 190,
                    ),
                    child: actionGroup,
                  ),
                ],
              );
            },
          ),
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
    required this.quantity,
    required this.onAdd,
    required this.onBuyNow,
    required this.onDecrease,
    required this.onIncrease,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final BuyV2ProductOfferDecision decision;
  final String buyerPromise;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onBuyNow;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final statusColor = decision.canAdd
        ? BuyV2Colors.green
        : BuyV2Colors.orange;
    final mrp = product.mrp;
    final fulfilmentMode =
        facts.fulfilmentMode ?? buyV2CatalogueFulfilmentModeFor(product);
    final savings = mrp == null || mrp <= facts.price
        ? null
        : mrp - facts.price;
    return Semantics(
      key: ValueKey('buy-product-offer-decision-${product.id}'),
      container: true,
      label:
          '${product.title}. ${product.variant}. ${product.pack}. '
          '${buyV2Money(facts.price)} delivered price. '
          '${facts.orderabilityLabel}. $buyerPromise. '
          '${buyV2FulfilmentModeLabel(fulfilmentMode)}. '
          '${buyV2AutomaticFulfilmentLabel(product.destination)}. '
          '${decision.statusLabel}. ${decision.detail}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DecisionPanel(
            key: ValueKey('buy-automatic-fulfilment-${product.id}'),
            title: 'Price, pack and delivery',
            children: [
              _DecisionRow(
                icon: decision.canAdd
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                label: 'Availability',
                value: decision.statusLabel,
                valueColor: statusColor,
              ),
              _DecisionRow(
                icon: Icons.tune_rounded,
                label: 'Pack and variant',
                value: '${product.pack} · ${product.variant}',
              ),
              _DecisionRow(
                icon: Icons.currency_rupee_rounded,
                label: 'Delivered price',
                value: '${buyV2Money(facts.price)} · MoolSocial price',
              ),
              if (mrp != null && mrp > facts.price)
                _DecisionRow(
                  icon: Icons.savings_outlined,
                  label: 'Price components',
                  value:
                      'List price ${buyV2Money(mrp)} · Save ${buyV2Money(savings!)}',
                )
              else
                _DecisionRow(
                  icon: Icons.calculate_outlined,
                  label: 'Price components',
                  value: product.unitPrice,
                ),
              _DecisionRow(
                icon: Icons.inventory_outlined,
                label: 'Stock',
                value: facts.orderabilityLabel,
                valueColor: statusColor,
              ),
              _DecisionRow(
                icon: Icons.schedule_rounded,
                label: 'Delivery',
                value: buyerPromise,
                valueColor: decision.canAdd ? BuyV2Colors.green : statusColor,
              ),
              _DecisionRow(
                icon: Icons.local_shipping_outlined,
                label: 'Delivery mode',
                value: buyV2FulfilmentModeLabel(fulfilmentMode),
              ),
              if (facts.storeOperatingState != BuyV2StoreOperatingState.unknown)
                _DecisionRow(
                  icon:
                      facts.storeOperatingState == BuyV2StoreOperatingState.open
                      ? Icons.storefront_outlined
                      : Icons.night_shelter_outlined,
                  label: 'Partner availability',
                  value:
                      facts.storeOperatingState == BuyV2StoreOperatingState.open
                      ? 'Open for orders'
                      : 'Closed · ${facts.nextOpeningLabel}',
                  valueColor:
                      facts.storeOperatingState == BuyV2StoreOperatingState.open
                      ? BuyV2Colors.green
                      : statusColor,
                ),
              if (facts.orderCutoffLabel case final cutoff?)
                _DecisionRow(
                  icon: Icons.timer_outlined,
                  label: 'Order cutoff',
                  value: cutoff,
                ),
              if (facts.deliveryFeeLabel case final deliveryFee?)
                _DecisionRow(
                  icon: Icons.payments_outlined,
                  label: 'Delivery fee',
                  value: deliveryFee,
                ),
              if (facts.dispatchPromise case final dispatchPromise?)
                _DecisionRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Dispatch',
                  value: dispatchPromise,
                ),
              if (facts.deliveryProviderName case final provider?)
                _DecisionRow(
                  icon: Icons.local_shipping_outlined,
                  label: 'Delivery provider',
                  value: provider,
                ),
              if (facts.deliveryServiceLevel case final serviceLevel?)
                _DecisionRow(
                  icon: Icons.route_outlined,
                  label: 'Delivery service',
                  value: serviceLevel,
                ),
              _DecisionRow(
                icon: Icons.storefront_outlined,
                label: 'Fulfilment',
                value: buyV2AutomaticFulfilmentLabel(product.destination),
              ),
              _DecisionRow(
                icon: Icons.location_on_outlined,
                label: 'Deliver to',
                value:
                    session.selectedAddressOrNull?.shortLine ??
                    'Choose a delivery address',
              ),
              const _DecisionRow(
                icon: Icons.verified_outlined,
                label: 'Price published by',
                value: 'MoolSocial',
              ),
              if (product.destination == BuyV2Destination.shop)
                _DecisionRow(
                  icon: Icons.assignment_return_outlined,
                  label: 'Return or replacement',
                  value:
                      product.returnPolicy ??
                      'Damaged or incorrect packs are reviewed at delivery',
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (decision.canAdd)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProductOwnedActionPanel(
                  key: ValueKey('buy-product-inline-action-${product.id}'),
                  product: product,
                  quantity: quantity,
                  deliveryDecision:
                      '${buyV2FulfilmentModeLabel(fulfilmentMode)} · $buyerPromise',
                  rxBlocked: false,
                  onAdd: onAdd,
                  onDecrease: onDecrease,
                  onIncrease: onIncrease,
                ),
                const SizedBox(height: 7),
                SizedBox(
                  height: BuyV2Metrics.minimumTap,
                  child: OutlinedButton.icon(
                    key: ValueKey('buy-product-buy-now-${product.id}'),
                    onPressed: onBuyNow,
                    icon: const Icon(Icons.flash_on_rounded, size: 18),
                    label: const Text('Buy now'),
                  ),
                ),
              ],
            )
          else
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
                      OutlinedButton.icon(
                        key: ValueKey('buy-offer-retry-${product.id}'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          session.refreshProductFacts(product.id);
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry offer'),
                      ),
                      FilledButton.icon(
                        key: ValueKey('buy-offer-change-product-${product.id}'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: session.closeProduct,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: const Text('Change product'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductContinuationSection extends StatelessWidget {
  const _ProductContinuationSection({
    required this.session,
    required this.product,
  });

  final BuyV2Session session;
  final BuyV2Product product;

  @override
  Widget build(BuildContext context) {
    final products = session.productContinuationsFor(product);
    if (products.isEmpty) return const SizedBox.shrink();

    final (title, detail) = switch (product.destination) {
      BuyV2Destination.shop => (
        'You may also like',
        'More products selected for you',
      ),
      BuyV2Destination.wholesale => (
        'More for business restocking',
        'Trade packs for your next order',
      ),
      BuyV2Destination.medicine => (
        'More Medicine essentials',
        'From the Medicine catalogue · not medical advice',
      ),
      BuyV2Destination.orders => ('', ''),
    };

    return BuyV2FiniteIncomingTransition(
      stateKey: 'buy-product-continuation-motion-${product.id}',
      child: Container(
        key: ValueKey('buy-product-continuations-${product.id}'),
        padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
        decoration: buyV2CardDecoration(radius: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.buyTitle.copyWith(fontSize: 14)),
            const SizedBox(height: 2),
            Text(detail, style: context.buyMeta.copyWith(fontSize: 8)),
            const SizedBox(height: 7),
            Semantics(
              container: true,
              label: '$title. $detail. Swipe horizontally for more products.',
              child: SizedBox(
                height: 174,
                child: ListView.separated(
                  key: ValueKey('buy-product-continuation-lane-${product.id}'),
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 7),
                  itemBuilder: (context, index) => _ProductContinuationCard(
                    session: session,
                    product: products[index],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductContinuationCard extends StatelessWidget {
  const _ProductContinuationCard({
    required this.session,
    required this.product,
  });

  final BuyV2Session session;
  final BuyV2Product product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Semantics(
        key: ValueKey('buy-product-continuation-${product.id}'),
        container: true,
        button: true,
        label: 'View ${product.title} product details',
        onTap: () => session.openProduct(product.id),
        child: ExcludeSemantics(
          child: Material(
            color: BuyV2Colors.canvas,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: () => session.openProduct(product.id),
              borderRadius: BorderRadius.circular(13),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 82,
                      width: double.infinity,
                      child: BuyV2ProductPackshot(
                        product: product,
                        borderRadius: 10,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.buyBody.copyWith(
                        fontSize: 9,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.pack,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showPartnerProductsSheet(
  BuildContext context,
  BuyV2Session session,
  BuyV2Product current,
  List<BuyV2Product> products,
) async {
  final supportedDestination =
      current.destination == BuyV2Destination.shop ||
      current.destination == BuyV2Destination.wholesale ||
      current.destination == BuyV2Destination.medicine;
  final exactProducts = products.every(
    (product) =>
        product.id != current.id &&
        product.destination == current.destination &&
        product.seller == current.seller,
  );
  if (!supportedDestination || products.isEmpty || !exactProducts) {
    return;
  }
  final ownerPrefix = switch (current.destination) {
    BuyV2Destination.shop => 'buy-shop-seller',
    BuyV2Destination.wholesale => 'buy-wholesale-supplier',
    BuyV2Destination.medicine => 'buy-medicine-pharmacy',
    BuyV2Destination.orders => 'buy-order-partner',
  };
  final catalogueFactCopy = switch (current.destination) {
    BuyV2Destination.wholesale =>
      'Compare this supplier’s available packs, minimum orders and prices',
    BuyV2Destination.medicine =>
      'Review available packs and prices from this pharmacy · '
          'Not medical advice',
    _ => 'Compare available products and prices from this seller',
  };
  final closeTooltip = switch (current.destination) {
    BuyV2Destination.wholesale => 'Close supplier products',
    BuyV2Destination.medicine => 'Close pharmacy products',
    _ => 'Close seller products',
  };
  final motion = BuyV2SupplierSheetMotion.resolve(context);
  final transitionController = AnimationController(
    vsync: Navigator.of(context),
    duration: motion.duration ?? Duration.zero,
    reverseDuration: motion.reverseDuration ?? Duration.zero,
  );
  try {
    final selectedProductId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(
        maxWidth: BuyV2SupplierSheetMotion.maxWidth,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      transitionAnimationController: transitionController,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: BuyV2SupplierSheetMotion.heightFactor,
        child: SafeArea(
          top: false,
          child: Semantics(
            key: ValueKey('$ownerPrefix-sheet-${current.id}'),
            container: true,
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: 'More from ${current.seller}',
            child: ListView(
              key: ValueKey('$ownerPrefix-sheet-list'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: BuyV2Colors.softOrange,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        color: BuyV2Colors.navy,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'More from ${current.seller}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: sheetContext.buyTitle.copyWith(fontSize: 17),
                          ),
                          const SizedBox(height: 2),
                          Text(catalogueFactCopy, style: sheetContext.buyMeta),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      key: ValueKey('$ownerPrefix-sheet-close'),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      tooltip: closeTooltip,
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(BuyV2Metrics.minimumTap),
                        side: const BorderSide(color: BuyV2Colors.line),
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final product in products) ...[
                  _PartnerProductAction(
                    product: product,
                    ownerPrefix: ownerPrefix,
                  ),
                  if (product != products.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (!transitionController.isDismissed) {
      await transitionController.reverse();
    }
    if (selectedProductId != null) {
      if (!context.mounted) return;
      session.openProduct(selectedProductId);
    }
  } finally {
    transitionController.dispose();
  }
}

class _PartnerProductAction extends StatelessWidget {
  const _PartnerProductAction({
    required this.product,
    required this.ownerPrefix,
  });

  final BuyV2Product product;
  final String ownerPrefix;

  @override
  Widget build(BuildContext context) {
    void selectProduct() {
      HapticFeedback.selectionClick();
      Navigator.of(context).pop(product.id);
    }

    final packFact = switch (product.destination) {
      BuyV2Destination.wholesale =>
        '${product.pack} · MOQ ${product.minimumOrder}',
      BuyV2Destination.medicine =>
        product.requiresPrescription
            ? '${product.pack} · Prescription and pharmacist review required'
            : '${product.pack} · No prescription required for this listed pack',
      _ => product.pack,
    };
    final semanticLabel = switch (product.destination) {
      BuyV2Destination.wholesale =>
        'View ${product.title} from ${product.seller}. ${product.pack}. '
            'MOQ ${product.minimumOrder}. ${buyV2Money(product.price)}. '
            '${product.unitPrice}. Available for Wholesale.',
      BuyV2Destination.medicine =>
        'View ${product.title} from ${product.seller}. $packFact. '
            '${buyV2Money(product.price)}. ${product.unitPrice}. '
            'Available from this pharmacy. Not medical advice.',
      _ =>
        'View ${product.title} from ${product.seller}. ${product.pack}. '
            '${buyV2Money(product.price)}. ${product.unitPrice}. '
            'Available in Shop.',
    };

    return BuyV2IntentDepth(
      key: ValueKey('$ownerPrefix-depth-${product.id}'),
      child: Semantics(
        key: ValueKey('$ownerPrefix-product-${product.id}'),
        container: true,
        button: true,
        label: semanticLabel,
        onTap: selectProduct,
        child: ExcludeSemantics(
          child: Material(
            color: BuyV2Colors.canvas,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: selectProduct,
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 68),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: BuyV2Colors.line),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: BuyV2Colors.navy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyBody.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              packFact,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyMeta,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${buyV2Money(product.price)} · '
                              '${product.unitPrice}',
                              style: context.buyMeta.copyWith(
                                color: BuyV2Colors.green,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: BuyV2Colors.navy,
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
  }
}

class _ProductContentMediaSurface extends StatelessWidget {
  const _ProductContentMediaSurface({
    required this.product,
    required this.media,
  });

  final BuyV2Product product;
  final BuyV2ProductMediaAsset media;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => BuyV2ProductPackshot(
      key: ValueKey('buy-product-gallery-image-${media.id}'),
      product: product,
      borderRadius: 17,
      animateFirstFrame: true,
    );

    return Semantics(
      image: true,
      label: media.semanticLabel,
      excludeSemantics: true,
      child: switch (media.kind) {
        BuyV2ProductContentMediaKind.cataloguePackshot => fallback(),
        BuyV2ProductContentMediaKind.asset => Image.asset(
          media.source!,
          key: ValueKey('buy-product-gallery-asset-${media.id}'),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => fallback(),
        ),
        BuyV2ProductContentMediaKind.network => Image.network(
          media.source!,
          key: ValueKey('buy-product-gallery-network-${media.id}'),
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorBuilder: (_, _, _) => fallback(),
        ),
      },
    );
  }
}

class _BuyV2ProductMediaItem {
  const _BuyV2ProductMediaItem({required this.label, required this.child});

  final String label;
  final Widget child;
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
      label: '${widget.label}. Pinch to zoom ${widget.product.title}.',
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
              child: ExcludeSemantics(child: widget.child),
            ),
          ),
          if (_zoomed)
            Positioned(
              right: 8,
              bottom: 8,
              child: Semantics(
                button: true,
                label: 'Reset zoom for ${widget.product.title}',
                child: Material(
                  color: BuyV2Colors.navy.withValues(alpha: .92),
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
                        color: Colors.white,
                        size: 22,
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
    this.compact = false,
  }) : assert(media.length > 0);

  final BuyV2Product product;
  final List<_BuyV2ProductMediaItem> media;
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
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _BuyV2ProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= widget.media.length) {
      _page = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hasMultipleMedia = widget.media.length > 1;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final galleryHeight = widget.compact
        ? viewportHeight < 650 || largeText
              ? (viewportHeight * .23).clamp(128.0, 160.0)
              : (viewportHeight * .29).clamp(174.0, 238.0)
        : (viewportHeight * .38).clamp(252.0, 320.0);
    return Semantics(
      container: true,
      label: hasMultipleMedia
          ? 'Product image gallery for ${product.title}, '
                '${widget.media.length} images. Swipe to browse.'
          : 'Product media for ${product.title}',
      child: Container(
        height: galleryHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              product.destination == BuyV2Destination.medicine
                  ? const Color(0xFFE7F5F1)
                  : BuyV2Colors.softOrange,
              Colors.white,
              BuyV2Colors.softGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: BuyV2Colors.line),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                key: ValueKey('buy-product-gallery-${product.id}'),
                controller: _controller,
                physics: hasMultipleMedia
                    ? const PageScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: widget.media.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    8,
                    9,
                    8,
                    hasMultipleMedia ? 35 : 9,
                  ),
                  child: DecoratedBox(
                    key: ValueKey('buy-product-gallery-image-$index'),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1D000040),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: _BuyV2ZoomableMedia(
                        key: ValueKey(
                          'buy-product-media-zoom-owner-'
                          '${product.id}-$index',
                        ),
                        product: product,
                        label: widget.media[index].label,
                        child: widget.media[index].child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 9,
              top: 9,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 150),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: product.requiresPrescription
                      ? BuyV2Colors.navy
                      : BuyV2Colors.green,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  product.badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (hasMultipleMedia) ...[
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  key: const ValueKey('buy-product-gallery-count'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: BuyV2Colors.navy.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${_page + 1} of ${widget.media.length}',
                    style: const TextStyle(
                      color: Colors.white,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (
                      var index = 0;
                      index < widget.media.length;
                      index++
                    ) ...[
                      AnimatedContainer(
                        key: ValueKey('buy-product-gallery-dot-$index'),
                        duration: BuyV2Motion.resolved(
                          context,
                          BuyV2Motion.stateChange,
                        ),
                        width: index == _page ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: index == _page
                              ? BuyV2Colors.navy
                              : BuyV2Colors.muted.withValues(alpha: .35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      if (index != widget.media.length - 1)
                        const SizedBox(width: 4),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      widget.media[_page].label,
                      style: const TextStyle(
                        color: BuyV2Colors.ink,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
    if (content.state != BuyV2ProductContentState.ready) {
      final loading = content.state == BuyV2ProductContentState.loading;
      return Container(
        key: ValueKey(
          'buy-product-content-${content.state.name}-${product.id}',
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
              OutlinedButton.icon(
                key: ValueKey('buy-product-content-retry-${product.id}'),
                onPressed: () => session.refreshProductContent(product.id),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      key: ValueKey('buy-product-content-ready-${product.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (content.highlights.isNotEmpty)
          _ProductContentCard(
            title: 'Highlights',
            icon: Icons.auto_awesome_outlined,
            children: [
              for (final highlight in content.highlights)
                _ProductContentLine(value: highlight),
            ],
          ),
        if (content.highlights.isNotEmpty &&
            (content.specifications.isNotEmpty || content.description != null))
          const SizedBox(height: 8),
        if (content.specifications.isNotEmpty)
          _ProductContentCard(
            title: 'Specifications',
            icon: Icons.fact_check_outlined,
            children: [
              for (final specification in content.specifications)
                _DecisionRow(
                  icon: Icons.circle,
                  label: specification.label,
                  value: specification.value,
                ),
            ],
          ),
        if (content.specifications.isNotEmpty && content.description != null)
          const SizedBox(height: 8),
        if (content.description case final description?)
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
  Widget build(BuildContext context) => Container(
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
            Expanded(child: Text('Checking product offers')),
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
              'Product offers unavailable',
              style: context.buyBody.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              customerMessage ?? 'Offers could not be checked right now.',
              style: context.buyMeta,
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              key: ValueKey('buy-product-benefits-retry-${product.id}'),
              onPressed: () => session.refreshProductBenefits(product.id),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
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
                color: BuyV2Colors.navy,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Offers for this product',
                  style: context.buyTitle.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Eligibility is checked again at Checkout.',
            style: context.buyMeta.copyWith(fontSize: 8),
          ),
          const SizedBox(height: 8),
          if (visibleBenefits.isEmpty)
            Text('No product offers right now.', style: context.buyBody)
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
        color: BuyV2Colors.softBlue.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x22000080)),
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
                  style: context.buyBody.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (benefit.savingAmount > 0)
                Text(
                  'Save ${buyV2Money(benefit.savingAmount)}',
                  style: context.buyBody.copyWith(
                    color: BuyV2Colors.green,
                    fontWeight: FontWeight.w900,
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
              color: BuyV2Colors.navy,
              fontSize: 8,
              fontWeight: FontWeight.w800,
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
    required this.onViewSeller,
    required this.sellerProductCount,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final BuyV2MarketplaceTrustSnapshot trust;
  final VoidCallback? onViewSeller;
  final int sellerProductCount;

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
              OutlinedButton.icon(
                key: ValueKey('buy-marketplace-trust-retry-${product.id}'),
                onPressed: () => session.refreshMarketplaceTrust(product.id),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
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
      title: 'Ratings and seller',
      children: [
        _DecisionRow(
          icon: Icons.star_rounded,
          label: 'Customer rating',
          value: productRating == null
              ? 'No verified ratings yet'
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
        _DecisionRow(
          icon: Icons.storefront_outlined,
          label: trust.partnerType,
          value: trust.partnerName,
        ),
        if (onViewSeller != null)
          _DecisionActionRow(
            key: ValueKey('buy-shop-seller-action-${product.id}'),
            icon: Icons.storefront_outlined,
            label: 'Seller products',
            value: 'More from ${trust.partnerName}',
            detail:
                '$sellerProductCount other ${sellerProductCount == 1 ? 'product' : 'products'}',
            semanticLabel:
                'View $sellerProductCount more ${sellerProductCount == 1 ? 'product' : 'products'} from ${trust.partnerName}',
            onTap: onViewSeller!,
          ),
        if (partnerRating case final rating?)
          _DecisionRow(
            icon: Icons.workspace_premium_outlined,
            label: 'Seller rating',
            value: rating.toStringAsFixed(1),
            valueColor: BuyV2Colors.green,
          ),
        if (trust.partnerLocation case final location?)
          _DecisionRow(
            icon: Icons.location_on_outlined,
            label: 'Seller location',
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
            label: 'Fulfilment record',
            value: reliability,
          ),
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
      decoration: buyV2CardDecoration(radius: 16),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
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
              'No customer reviews yet. Share your experience after purchase.',
              style: context.buyMeta.copyWith(fontSize: 9),
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
                    style: context.buyEyebrow.copyWith(fontSize: 8),
                  ),
                  const SizedBox(height: 3),
                  Text(review!.comment, style: context.buyBody),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (onReview != null || onReport != null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('buy-review-product-${product.id}'),
                    onPressed: onReview,
                    icon: const Icon(Icons.rate_review_outlined, size: 17),
                    label: Text(
                      review == null ? 'Write review' : 'Edit review',
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: TextButton.icon(
                    key: ValueKey('buy-report-product-${product.id}'),
                    onPressed: reported ? null : onReport,
                    icon: Icon(
                      reported
                          ? Icons.check_circle_outline_rounded
                          : Icons.flag_outlined,
                      size: 17,
                    ),
                    label: Text(reported ? 'Reported' : 'Report issue'),
                  ),
                ),
              ],
            )
          else
            Text(
              'Reviews and product reports will be available after Shop reconnects.',
              style: context.buyMeta.copyWith(fontSize: 9),
            ),
        ],
      ),
    );
  }
}

Future<void> _showProductReviewSheet(
  BuildContext context,
  BuyV2Session session,
  BuyV2Product product,
) async {
  final existing = session.customerReviewFor(product.id);
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
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _ProductReviewSheet(
        session: session,
        product: product,
        existing: existing,
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
    builder: (sheetContext) => _ProductReportSheet(
      session: session,
      product: product,
      reasons: reasons,
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
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.buyTitle.copyWith(fontSize: 17),
              ),
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

class _ProductReviewSheet extends StatefulWidget {
  const _ProductReviewSheet({
    required this.session,
    required this.product,
    required this.existing,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final BuyV2CustomerReview? existing;

  @override
  State<_ProductReviewSheet> createState() => _ProductReviewSheetState();
}

class _ProductReviewSheetState extends State<_ProductReviewSheet> {
  late final TextEditingController _commentController;
  late final FocusNode _commentFocus;
  late int _rating;
  bool _submissionRejected = false;
  bool _submitting = false;

  bool get _isValid =>
      _rating >= 1 && _rating <= 5 && _commentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 0;
    _commentController = TextEditingController(
      text: widget.existing?.comment ?? '',
    );
    _commentFocus = FocusNode()..addListener(_focusChanged);
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
    final saved = await widget.session.submitProductReviewOnline(
      productId: widget.product.id,
      rating: _rating,
      comment: _commentController.text,
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
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateDuration =
        BuyV2ProductFeedbackSheetMotion.resolveFormStateDuration(context);
    final title = 'Review ${widget.product.title}';
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
        label: '$title form',
        child: ConstrainedBox(
          key: const ValueKey('buy-product-review-sheet'),
          constraints: const BoxConstraints(maxHeight: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProductFeedbackSheetHeader(
                  icon: Icons.rate_review_outlined,
                  title: title,
                  detail:
                      'Rate what you received. Keep personal or medical information out.',
                  closeKey: const ValueKey('buy-close-product-review'),
                ),
                const SizedBox(height: 12),
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
                              'buy-review-rating-${widget.product.id}-$value',
                            ),
                            tooltip: '$value ${value == 1 ? 'star' : 'stars'}',
                            onPressed: _submitting
                                ? null
                                : () => setState(() {
                                    _rating = value;
                                    _submissionRejected = false;
                                  }),
                            icon: Icon(
                              value <= _rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: BuyV2Colors.orange,
                              size: 28,
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
                  isRequired: true,
                  maxValueLength: 500,
                  currentValueLength: _commentController.text.characters.length,
                  label: 'Your review',
                  value: _commentController.text,
                  hint: 'Required. Up to 500 characters.',
                  onTap: _commentFocus.requestFocus,
                  onFocus: _commentFocus.requestFocus,
                  onSetText: (value) {
                    final nextValue =
                        LengthLimitingTextInputFormatter(
                          500,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
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
                    key: ValueKey('buy-review-comment-${widget.product.id}'),
                    controller: _commentController,
                    focusNode: _commentFocus,
                    autofocus: false,
                    onChanged: (_) => setState(() {
                      _submissionRejected = false;
                    }),
                    enabled: !_submitting,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Your review',
                      hintText: 'What was useful, good or needs improvement?',
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
                          'Required · up to 500 characters',
                          style: context.buyMeta.copyWith(fontSize: 9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_commentController.text.characters.length}/500',
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
                      _submissionRejected
                          ? (widget.session.notice ??
                                'This review could not be saved.')
                          : _submitting
                          ? 'Saving your review…'
                          : _isValid
                          ? 'Ready to save to this product.'
                          : 'Choose a rating and write a review to enable Save.',
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        key: const ValueKey('buy-cancel-product-review'),
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          key: ValueKey(
                            'buy-submit-review-${widget.product.id}',
                          ),
                          onPressed: _isValid && !_submitting ? _submit : null,
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(_submitting ? 'Saving…' : 'Save review'),
                        ),
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
        constraints: const BoxConstraints(maxHeight: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ProductFeedbackSheetHeader(
                icon: Icons.flag_outlined,
                title: title,
                detail: 'Choose the one listing detail that needs attention.',
                closeKey: ValueKey('buy-close-product-report'),
              ),
              const SizedBox(height: 11),
              for (var index = 0; index < widget.reasons.length; index++)
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
                          color: _selectedReason == widget.reasons[index]
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
                                  _selectedReason = widget.reasons[index];
                                  _submissionRejected = false;
                                }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
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
                                  _selectedReason == widget.reasons[index]
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color:
                                      _selectedReason == widget.reasons[index]
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      key: const ValueKey('buy-cancel-product-report'),
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        key: ValueKey('buy-submit-report-${widget.product.id}'),
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
            child: FilledButton.icon(
              key: const ValueKey('buy-choose-address-recovery'),
              onPressed: () => showBuyV2AddressSheet(context, session),
              icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
              label: const Text('Choose address'),
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
                child: FilledButton(
                  key: const ValueKey('buy-return-to-orders-recovery'),
                  onPressed: session.openOrders,
                  child: const Text('View orders'),
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
  });

  final BuyV2Session session;
  final VoidCallback onBrowseMore;

  @override
  State<BuyV2CartView> createState() => _BuyV2CartViewState();
}

class _BuyV2CartViewState extends State<BuyV2CartView> {
  late BuyV2CartScope _scope;
  late ScrollController _scrollController;

  BuyV2Session get session => widget.session;

  @override
  void initState() {
    super.initState();
    _scope = session.cartScope;
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
    final destinations =
        const [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        ].where(
          (destination) =>
              lines.any((line) => line.product.destination == destination),
        );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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
                          return BuyV2FiniteValueTransition(
                            key: const ValueKey('buy-cart-header-value-motion'),
                            stateKey: summary,
                            text: summary,
                            ownerSize: Size(constraints.maxWidth, 14),
                            textAlign: TextAlign.start,
                            style: context.buyMeta.copyWith(fontSize: 8),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('buy-cart-empty'),
                  tooltip: 'Empty cart',
                  onPressed: session.clearCart,
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
        Expanded(
          child: lines.isEmpty
              ? const SizedBox.shrink()
              : ListView(
                  controller: _scrollController,
                  key: PageStorageKey('buy-cart-${session.cartScope.name}'),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        key: const ValueKey('buy-cart-browse-more'),
                        onPressed: widget.onBrowseMore,
                        icon: const Icon(Icons.add_shopping_cart_outlined),
                        label: const Text('Browse more products'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final line in lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: _CartLine(session: session, line: line),
                      ),
                    const SizedBox(height: 2),
                    _CartBenefitPanel(session: session),
                    const SizedBox(height: 10),
                    _CartDiscoverySections(
                      session: session,
                      destinations: destinations.toList(growable: false),
                    ),
                    _CartDeliveryInstructionSections(
                      session: session,
                      destinations: destinations.toList(growable: false),
                    ),
                    _CartTipSections(session: session),
                    _CartBillSummary(session: session),
                    const SizedBox(height: 8),
                    _CartSavingsSummary(session: session),
                    BuyV2SponsoredSlot(
                      content: session.sponsoredContentFor(
                        BuyV2SponsoredPlacement.cartBeforeSummary,
                      ),
                    ),
                  ],
                ),
        ),
        Container(
          key: const ValueKey('buy-cart-action-bar'),
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: BuyV2Colors.line)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final actionWidth = (constraints.maxWidth * .54).clamp(
                150.0,
                190.0,
              );
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.cartScope == BuyV2CartScope.wholesale
                              ? session.scopedTipTotal > 0
                                    ? 'Landed total + delivery tip'
                                    : 'Landed cart total'
                              : session.scopedTipTotal > 0
                              ? 'Items + delivery tip'
                              : 'Cart total',
                          style: context.buyMeta,
                        ),
                        BuyV2FiniteValueTransition(
                          key: const ValueKey('buy-cart-payable-total-motion'),
                          stateKey: session.scopedPayableTotal,
                          text: buyV2Money(session.scopedPayableTotal),
                          ownerSize: const Size(112, 30),
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: BuyV2Colors.navy,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (session.cartScope == BuyV2CartScope.wholesale)
                          Text(
                            'Freight included · GST invoice at checkout',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.buyMeta.copyWith(fontSize: 7.5),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: actionWidth,
                    child: FilledButton(
                      onPressed: () {
                        if (!session.openCheckout() &&
                            session.selectedAddressOrNull == null) {
                          showBuyV2AddressSheet(context, session);
                        }
                      },
                      child: const Text('Review order'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GstInvoiceCard extends StatelessWidget {
  const _GstInvoiceCard({required this.destination, required this.controller});

  final BuyV2Destination destination;
  final BuyV2GstInvoiceController controller;

  @override
  Widget build(BuildContext context) {
    final requested = controller.requestedFor(destination);
    final details = controller.detailsFor(destination);
    return Container(
      key: ValueKey('buy-gst-invoice-${destination.name}'),
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BuyV2Colors.softBlue,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: BuyV2Colors.navy,
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add GST details', style: context.buyBody),
                    Text(
                      'GST applies as required. Add GSTIN only for recipient details on the invoice.',
                      style: context.buyMeta.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                key: ValueKey('buy-gst-request-${destination.name}'),
                value: requested,
                onChanged: (value) =>
                    controller.setRequested(destination, value),
              ),
            ],
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
                      key: ValueKey('buy-gst-profile-${profile.id}'),
                      label: Text(profile.legalName),
                      selected: details?.id == profile.id,
                      onSelected: controller.busy
                          ? null
                          : (_) => controller.selectSaved(destination, profile),
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
                          style: context.buyBody.copyWith(fontSize: 10),
                        ),
                        Text(
                          details == null
                              ? 'Add GSTIN, legal name and billing address.'
                              : '${details.gstin} · ${details.billingAddress}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.buyMeta.copyWith(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: ValueKey(
                      'buy-gst-${details == null ? 'add' : 'edit'}-'
                      '${destination.name}',
                    ),
                    onPressed: () => showBuyV2GstInvoiceSheet(
                      context,
                      controller: controller,
                      destination: destination,
                    ),
                    child: Text(details == null ? 'Add' : 'Edit'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Recipient and delivery details are recorded where GST invoice rules require them.',
              style: context.buyMeta.copyWith(fontSize: 8),
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
                            ? BuyV2Colors.navy
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
        FilledButton(
          key: const ValueKey('buy-gst-remove-confirm'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Remove'),
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
    if (legalName.length < 3 || address.length < 8) {
      setState(() => _error = 'Add the legal name and billing address.');
      return;
    }
    if (!gstinPattern.hasMatch(gstin)) {
      setState(() => _error = 'Check the 15-character GSTIN format.');
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
                                  focusNode: _legalNameFocus,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) =>
                                      _gstinFocus.requestFocus(),
                                  decoration: const InputDecoration(
                                    label: ExcludeSemantics(
                                      child: Text('Legal name'),
                                    ),
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
                                    label: ExcludeSemantics(
                                      child: Text('GSTIN'),
                                    ),
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
                                  focusNode: _billingAddressFocus,
                                  minLines: 2,
                                  maxLines: 3,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) =>
                                      _billingAddressFocus.unfocus(),
                                  decoration: const InputDecoration(
                                    label: ExcludeSemantics(
                                      child: Text('Billing address'),
                                    ),
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
                                contentPadding: EdgeInsets.zero,
                                value: _remember,
                                onChanged: widget.controller.busy
                                    ? null
                                    : (value) =>
                                          setState(() => _remember = value),
                                title: Text(
                                  widget.controller.sessionPersistenceOnly
                                      ? 'Use again until you close the app'
                                      : 'Remember these GST details',
                                ),
                                subtitle: Text(
                                  widget.controller.sessionPersistenceOnly
                                      ? 'These details are cleared when you close the app.'
                                      : 'Reuse them on a later invoice.',
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
                          if (_error case final error?) ...[
                            Text(
                              error,
                              key: const ValueKey('buy-gst-error'),
                              style: const TextStyle(
                                color: Color(0xFFB42318),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
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
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FocusTraversalOrder(
                          order: const NumericFocusOrder(5),
                          child: FilledButton(
                            key: const ValueKey('buy-gst-save'),
                            onPressed: widget.controller.busy ? null : _save,
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

String _commercialPaymentTermTitle(BuyV2CommercialPaymentTerm term) =>
    switch (term.kind) {
      BuyV2CommercialPaymentTermKind.retailAdvance ||
      BuyV2CommercialPaymentTermKind.wholesaleAdvance => 'Full advance',
      BuyV2CommercialPaymentTermKind.bookingBalanceBeforeDispatch =>
        'Booking amount · balance before dispatch',
      BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery =>
        'Booking amount · balance at delivery',
      BuyV2CommercialPaymentTermKind.supplierCredit =>
        'Supplier credit · ${term.netDays} days',
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
                      color: BuyV2Colors.navy,
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
          _CartAmountRow(label: 'Products', value: buyV2Money(itemSubtotal)),
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
                      color: BuyV2Colors.navy,
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
            'Retail is paid in full. Wholesale terms are published by each supplier.',
            style: context.buyMeta.copyWith(fontSize: 8.5),
          ),
          const SizedBox(height: 8),
          for (
            var groupIndex = 0;
            groupIndex < groups.length;
            groupIndex++
          ) ...[
            _CommercialPaymentTermGroup(
              session: session,
              group: groups[groupIndex],
            ),
            if (groupIndex < groups.length - 1) const Divider(height: 18),
          ],
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
          if (session.commercialPaymentTermsMessage case final message?) ...[
            const SizedBox(height: 6),
            Text(
              message,
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

class _CommercialPaymentTermGroup extends StatelessWidget {
  const _CommercialPaymentTermGroup({
    required this.session,
    required this.group,
  });

  final BuyV2Session session;
  final BuyV2FulfilmentGroup group;

  @override
  Widget build(BuildContext context) {
    final terms = session.commercialPaymentTermsFor(group.key);
    final selected = session.selectedCommercialPaymentTermFor(group.key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${group.destination.label} · ${group.partner}',
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
        else
          RadioGroup<String>(
            groupValue: selected?.id,
            onChanged: (termId) {
              final term = terms
                  .where((candidate) => candidate.id == termId)
                  .firstOrNull;
              if (term != null) session.chooseCommercialPaymentTerm(term);
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

class BuyV2CheckoutView extends StatelessWidget {
  const BuyV2CheckoutView({
    super.key,
    required this.session,
    required this.gstInvoiceController,
    this.paymentHandoff,
  });

  final BuyV2Session session;
  final BuyV2GstInvoiceController gstInvoiceController;
  final BuyV2PaymentHandoff? paymentHandoff;

  @override
  Widget build(BuildContext context) {
    final address = session.selectedAddressOrNull;
    if (address == null) {
      return _AddressSelectionRequired(
        session: session,
        title: 'Choose a delivery address',
        detail:
            'Your Cart is unchanged. Select or add an address before placing the order.',
      );
    }
    return AnimatedBuilder(
      animation: gstInvoiceController,
      builder: (context, _) {
        final destinations = session.checkoutDestinations;
        final wholesaleReceiving =
            destinations.isNotEmpty &&
            destinations.every(
              (destination) => destination == BuyV2Destination.wholesale,
            );
        final deliveryGroups = session.checkoutFulfilmentGroups;
        final invoiceDestinations = destinations
            .where(
              (destination) =>
                  destination == BuyV2Destination.shop ||
                  destination == BuyV2Destination.wholesale,
            )
            .toList(growable: false);
        final missingDetails = invoiceDestinations.where(
          (destination) =>
              gstInvoiceController.requestedFor(destination) &&
              gstInvoiceController.detailsFor(destination) == null,
        );
        return Column(
          children: [
            Expanded(
              child: ListView(
                key: const PageStorageKey('buy-checkout'),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                children: [
                  _ReturnAffordance(
                    label: 'Cart',
                    onTap: session.checkoutBusy
                        ? () => session.showNotice(
                            'Keep Checkout open while your payment status is checked.',
                          )
                        : () => session.openCart(scope: session.checkoutScope),
                    tightHitOwner: true,
                    hitOwnerKey: const ValueKey('buy-checkout-return-cart'),
                    minimumHeight: 44,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Review order',
                    style: context.buyTitle.copyWith(fontSize: 19),
                  ),
                  if (session.checkoutSubmissionState !=
                          BuyV2CheckoutSubmissionState.idle &&
                      session.checkoutSubmissionState !=
                          BuyV2CheckoutSubmissionState.confirmed) ...[
                    const SizedBox(height: 8),
                    _CheckoutSubmissionStatus(
                      session: session,
                      paymentHandoff: paymentHandoff,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _SavedAddressReminder(
                    address: address,
                    wholesaleReceiving: wholesaleReceiving,
                    onEdit: () => showBuyV2AddressSheet(context, session),
                  ),
                  const SizedBox(height: 9),
                  for (final destination in invoiceDestinations) ...[
                    _GstInvoiceCard(
                      destination: destination,
                      controller: gstInvoiceController,
                    ),
                    const SizedBox(height: 7),
                  ],
                  if (session.checkoutQuoteEnabled) ...[
                    _CheckoutQuoteCard(session: session),
                    const SizedBox(height: 9),
                  ],
                  if (session.commercialPaymentTermsEnabled) ...[
                    _CheckoutCommercialPaymentTerms(session: session),
                    const SizedBox(height: 9),
                  ],
                  if (session.checkoutBenefitReviewRequired) ...[
                    _CartBenefitEligibilityState(session: session),
                    const SizedBox(height: 9),
                  ],
                  if (session.checkoutPriceReviewRequired) ...[
                    _CheckoutPriceChangeReview(session: session),
                    const SizedBox(height: 9),
                  ],
                  if (session.checkoutPromiseReviewRequired) ...[
                    _CheckoutPromiseChangeReview(session: session),
                    const SizedBox(height: 9),
                  ],
                  Semantics(
                    header: true,
                    child: Text(
                      'Delivery plan',
                      style: context.buyTitle.copyWith(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Place this purchase once. Each promise below is retained for its delivery.',
                    style: context.buyMeta.copyWith(fontSize: 8.5),
                  ),
                  const SizedBox(height: 7),
                  for (
                    var index = 0;
                    index < deliveryGroups.length;
                    index++
                  ) ...[
                    _CheckoutCard(
                      key: ValueKey(
                        'buy-checkout-delivery-plan-${deliveryGroups[index].key}',
                      ),
                      icon: switch (deliveryGroups[index].destination) {
                        BuyV2Destination.shop => Icons.storefront_outlined,
                        BuyV2Destination.wholesale =>
                          Icons.inventory_2_outlined,
                        BuyV2Destination.medicine => Icons.medication_outlined,
                        BuyV2Destination.orders => Icons.receipt_long_outlined,
                      },
                      title:
                          'Delivery ${index + 1} · '
                          '${_checkoutFulfilmentCountLabel(deliveryGroups[index])}',
                      detail: [
                        '${deliveryGroups[index].destination.label} fulfilment · '
                            '${_fulfilmentPromiseSummary(deliveryGroups[index])}',
                        '${deliveryGroups[index].destination.label} · ${buyV2Money(deliveryGroups[index].total)}',
                        if (deliveryGroups[index].dispatchPromise
                            case final dispatchPromise?)
                          'Dispatch · $dispatchPromise',
                        if (deliveryGroups[index].deliveryProviderName
                            case final provider?)
                          'Delivery provider · $provider'
                        else
                          'Fulfiller assigned automatically after placement',
                        if (deliveryGroups[index].deliveryServiceLevel
                            case final serviceLevel?)
                          'Service · $serviceLevel',
                        if (session.selectedDeliveryInstructionFor(
                              deliveryGroups[index].destination,
                            )
                            case final instruction?)
                          '${_deliveryInstructionOwner(deliveryGroups[index].destination)} · ${instruction.label}',
                        if (session.tipForGroup(deliveryGroups[index]) > 0)
                          'Optional delivery tip · ${buyV2Money(session.tipForGroup(deliveryGroups[index]))}',
                      ].join('\n'),
                    ),
                    if (deliveryGroups[index].destination ==
                        BuyV2Destination.wholesale) ...[
                      const SizedBox(height: 5),
                      _WholesaleCheckoutReceivingLines(
                        group: deliveryGroups[index],
                      ),
                    ],
                    const SizedBox(height: 7),
                  ],
                  for (final benefit in session.selectedCartBenefitsFor(
                    destinations,
                  )) ...[
                    _CheckoutCard(
                      key: ValueKey(
                        'buy-checkout-benefit-${benefit.destination.name}-'
                        '${benefit.kind.name}',
                      ),
                      icon: benefit.kind == BuyV2CartBenefitKind.coupon
                          ? Icons.local_offer_outlined
                          : Icons.account_balance_wallet_outlined,
                      title:
                          '${benefit.destination.label} '
                          '${benefit.kind == BuyV2CartBenefitKind.coupon ? 'coupon' : 'payment offer'} selected',
                      detail:
                          benefit.kind == BuyV2CartBenefitKind.coupon &&
                              benefit.savingAmount > 0
                          ? '${benefit.title}\n${buyV2Money(benefit.savingAmount)} '
                                'saving from ${benefit.sponsorName} is included '
                                'in this review total.'
                          : '${benefit.title}\n${_cartBenefitSponsorLabel(benefit)}. '
                                'Final eligibility is checked before payment. '
                                'No amount has been deducted from this review total.',
                      action: 'Review',
                      onTap: () => _openCartBenefitsPage(
                        context,
                        session: session,
                        kind: benefit.kind,
                        destination: benefit.destination,
                      ),
                    ),
                    const SizedBox(height: 7),
                  ],
                  const SizedBox(height: 11),
                  _CheckoutCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Payment · ${session.selectedPayment}',
                    detail: destinations.contains(BuyV2Destination.wholesale)
                        ? 'One payment selection for this purchase. Supplier invoices remain attached to their deliveries.'
                        : 'Selected payment method for this purchase.',
                    action: 'Change',
                    onTap: () => showBuyV2PaymentSheet(context, session),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Container(
              key: const ValueKey('buy-checkout-action-bar'),
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: BuyV2Colors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _checkoutDockCountLabel(session),
                          style: context.buyMeta.copyWith(fontSize: 8),
                        ),
                        Text(
                          buyV2Money(session.checkoutAmountDueNow),
                          style: const TextStyle(
                            color: BuyV2Colors.navy,
                            fontSize: 19,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 176,
                    height: 44,
                    child: FilledButton(
                      onPressed:
                          session.checkoutBusy ||
                              session.checkoutRequiresResolution ||
                              session.checkoutQuoteReviewRequired ||
                              session.checkoutPaymentTermsReviewRequired ||
                              session.checkoutBenefitReviewRequired ||
                              session.checkoutPriceReviewRequired ||
                              session.checkoutPromiseReviewRequired
                          ? null
                          : missingDetails.isEmpty
                          ? session.submitOrder
                          : () => showBuyV2GstInvoiceSheet(
                              context,
                              controller: gstInvoiceController,
                              destination: missingDetails.first,
                            ),
                      child: Text(
                        missingDetails.isEmpty
                            ? switch (session.checkoutSubmissionState) {
                                BuyV2CheckoutSubmissionState.submitting =>
                                  'Checking order…',
                                BuyV2CheckoutSubmissionState
                                    .paymentActionRequired =>
                                  'Complete payment above',
                                BuyV2CheckoutSubmissionState.paymentPending =>
                                  'Check payment above',
                                BuyV2CheckoutSubmissionState.paymentUnknown =>
                                  'Check payment above',
                                _ => 'Place order',
                              }
                            : 'Add GST details',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CheckoutSubmissionStatus extends StatelessWidget {
  const _CheckoutSubmissionStatus({
    required this.session,
    required this.paymentHandoff,
  });

  final BuyV2Session session;
  final BuyV2PaymentHandoff? paymentHandoff;

  @override
  Widget build(BuildContext context) {
    final state = session.checkoutSubmissionState;
    final actionRequired =
        state == BuyV2CheckoutSubmissionState.paymentActionRequired;
    final pending = state == BuyV2CheckoutSubmissionState.paymentPending;
    final unknown = state == BuyV2CheckoutSubmissionState.paymentUnknown;
    final submitting = state == BuyV2CheckoutSubmissionState.submitting;
    final bankTransfer =
        session.selectedPayment == 'Bank transfer' &&
        session.bankTransferInstructions != null;
    final title = switch (state) {
      BuyV2CheckoutSubmissionState.submitting => 'Checking your order',
      BuyV2CheckoutSubmissionState.paymentActionRequired =>
        bankTransfer
            ? 'Transfer to place your order'
            : 'Continue securely to payment',
      BuyV2CheckoutSubmissionState.paymentPending =>
        'Payment confirmation is pending',
      BuyV2CheckoutSubmissionState.paymentUnknown =>
        'Payment status needs checking',
      BuyV2CheckoutSubmissionState.cancelled => 'Payment was cancelled',
      BuyV2CheckoutSubmissionState.unavailable =>
        'Ordering is unavailable right now',
      BuyV2CheckoutSubmissionState.failed => 'Your order was not placed',
      BuyV2CheckoutSubmissionState.idle ||
      BuyV2CheckoutSubmissionState.confirmed => '',
    };
    final detail = switch (state) {
      BuyV2CheckoutSubmissionState.submitting =>
        'Keep this screen open while the latest price, payment and order are confirmed.',
      BuyV2CheckoutSubmissionState.paymentActionRequired =>
        bankTransfer
            ? 'Use the exact amount and reference below. Your Cart stays reserved for this single attempt.'
            : 'Your Cart is reserved for this attempt. Complete payment once, then return here.',
      BuyV2CheckoutSubmissionState.paymentPending ||
      BuyV2CheckoutSubmissionState.paymentUnknown =>
        'Do not pay again. Check this payment before trying another method.',
      BuyV2CheckoutSubmissionState.cancelled ||
      BuyV2CheckoutSubmissionState.failed ||
      BuyV2CheckoutSubmissionState.unavailable =>
        'Your Cart is unchanged. Try again or get help if the issue continues.',
      BuyV2CheckoutSubmissionState.idle ||
      BuyV2CheckoutSubmissionState.confirmed => '',
    };
    final needsCheck = pending || unknown;
    return Semantics(
      key: ValueKey('buy-checkout-submission-${state.name}'),
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: buyV2CardDecoration(
          color: actionRequired || needsCheck
              ? BuyV2Colors.softOrange
              : BuyV2Colors.softBlue,
          border: actionRequired || needsCheck
              ? BuyV2Colors.orange
              : BuyV2Colors.navy,
          radius: 15,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (submitting)
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(
                actionRequired
                    ? Icons.open_in_new_rounded
                    : needsCheck
                    ? Icons.schedule_rounded
                    : Icons.info_outline_rounded,
                color: BuyV2Colors.navy,
                size: 22,
              ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.buyBody),
                  const SizedBox(height: 2),
                  Text(detail, style: context.buyMeta),
                  if (bankTransfer && actionRequired) ...[
                    const SizedBox(height: 8),
                    _BankTransferInstructionsCard(
                      instructions: session.bankTransferInstructions!,
                      amount: session.checkoutAmountDueNow,
                    ),
                  ] else if (bankTransfer && needsCheck) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Transfer reference · ${session.paymentReference}',
                      key: const ValueKey(
                        'buy-bank-transfer-pending-reference',
                      ),
                      style: context.buyMeta.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                  if (!submitting) ...[
                    const SizedBox(height: 9),
                    if (actionRequired)
                      SizedBox(
                        width: double.infinity,
                        height: BuyV2Metrics.minimumTap,
                        child: FilledButton.icon(
                          key: const ValueKey('buy-checkout-continue-payment'),
                          onPressed: bankTransfer
                              ? session.markBankTransferSent
                              : paymentHandoff == null
                              ? () {
                                  if (session.cancelPaymentAttempt()) {
                                    showBuyV2PaymentSheet(context, session);
                                  }
                                }
                              : () => session.continuePayment(paymentHandoff!),
                          icon: Icon(
                            bankTransfer || paymentHandoff == null
                                ? Icons.swap_horiz_rounded
                                : Icons.open_in_new_rounded,
                            size: 18,
                          ),
                          label: Text(
                            bankTransfer
                                ? 'I’ve made the transfer'
                                : paymentHandoff == null
                                ? 'Choose another method'
                                : 'Open payment app',
                          ),
                        ),
                      )
                    else if (needsCheck)
                      SizedBox(
                        width: double.infinity,
                        height: BuyV2Metrics.minimumTap,
                        child: FilledButton.icon(
                          key: const ValueKey('buy-checkout-check-payment'),
                          onPressed: session.reconcilePayment,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Check payment'),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: BuyV2Metrics.minimumTap,
                        child: OutlinedButton.icon(
                          key: const ValueKey('buy-checkout-retry-order'),
                          onPressed: session.submitOrder,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Try again'),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (bankTransfer && actionRequired)
                      TextButton.icon(
                        key: const ValueKey('buy-bank-transfer-change-method'),
                        onPressed: () {
                          if (session.cancelPaymentAttempt()) {
                            showBuyV2PaymentSheet(context, session);
                          }
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, size: 17),
                        label: const Text('Choose another method'),
                      ),
                    TextButton.icon(
                      key: const ValueKey('buy-checkout-submission-help'),
                      onPressed: session.openAssist,
                      icon: const Icon(Icons.chat_outlined, size: 17),
                      label: const Text('Get order help'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankTransferInstructionsCard extends StatelessWidget {
  const _BankTransferInstructionsCard({
    required this.instructions,
    required this.amount,
  });

  final BuyV2BankTransferInstructions instructions;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('buy-bank-transfer-instructions'),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: buyV2CardDecoration(color: Colors.white, radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transfer details', style: context.buyBody),
          const SizedBox(height: 5),
          _BankTransferFact(label: 'Amount', value: buyV2Money(amount)),
          _BankTransferFact(
            label: 'Beneficiary',
            value: instructions.beneficiaryName,
          ),
          _BankTransferFact(label: 'Bank', value: instructions.bankName),
          _BankTransferFact(
            label: 'Account number',
            value: instructions.accountNumber,
          ),
          _BankTransferFact(label: 'IFSC', value: instructions.ifsc),
          _BankTransferFact(
            label: 'Transfer reference',
            value: instructions.transferReference,
          ),
          const SizedBox(height: 4),
          Text(
            'Include the transfer reference exactly. Do not make a second transfer while this one is checked.',
            style: context.buyMeta,
          ),
        ],
      ),
    );
  }
}

class _BankTransferFact extends StatelessWidget {
  const _BankTransferFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: context.buyMeta)),
          const SizedBox(width: 6),
          Expanded(
            child: SelectableText(
              value,
              style: context.buyMeta.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
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
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: buyV2CardDecoration(
          color: BuyV2Colors.softBlue.withValues(alpha: .55),
          border: const Color(0x24000080),
          radius: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Products and trade packs',
              style: context.buyBody.copyWith(
                color: BuyV2Colors.navy,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
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
        '${product.title}. $quantityLabel. ${product.pack}. '
        'Minimum order ${product.minimumOrder} packs. '
        '${buyV2Money(product.price)} per pack. ${product.unitPrice}. '
        'Line subtotal ${buyV2Money(line.total)}.';
    return Semantics(
      key: ValueKey('buy-wholesale-checkout-receiving-line-${product.id}'),
      container: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 290 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.2;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.buyBody.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                '$quantityLabel · ${product.pack}',
                style: context.buyMeta.copyWith(
                  color: BuyV2Colors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'MOQ ${product.minimumOrder} · '
                '${buyV2Money(product.price)} per pack · ${product.unitPrice}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.buyMeta.copyWith(fontSize: 8),
              ),
            ],
          );
          final subtotal = Column(
            crossAxisAlignment: stacked
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Line subtotal',
                style: context.buyMeta.copyWith(fontSize: 8),
              ),
              const SizedBox(height: 2),
              Text(
                buyV2Money(line.total),
                style: const TextStyle(
                  color: BuyV2Colors.navy,
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
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
                      color: BuyV2Colors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            SizedBox(
              width: double.infinity,
              height: BuyV2Metrics.minimumTap,
              child: FilledButton(
                key: const ValueKey('buy-checkout-accept-prices'),
                onPressed: session.acceptCheckoutPriceChanges,
                child: const Text('Accept updated prices'),
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
            style: context.buyMeta.copyWith(fontSize: 8.5),
          ),
          for (final change in changes) ...[
            const SizedBox(height: 8),
            Text(
              'Previous · ${buyV2DeliveryPromiseSummary(promise: change.previousPromise, promisedByLabel: change.previousPromisedByLabel)}',
              style: context.buyMeta.copyWith(fontSize: 8.5),
            ),
            const SizedBox(height: 2),
            Text(
              'Updated · ${buyV2DeliveryPromiseSummary(promise: change.currentPromise, promisedByLabel: change.currentPromisedByLabel)}',
              style: context.buyBody.copyWith(
                color: BuyV2Colors.navy,
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              key: const ValueKey('buy-accept-updated-delivery-times'),
              onPressed: session.acceptCheckoutPromiseChanges,
              child: const Text('Accept updated times'),
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
    final address = session.selectedAddressOrNull;
    return ListView(
      key: const ValueKey('buy-confirmation'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: buyV2CardDecoration(
            color: BuyV2Colors.softGreen,
            border: const Color(0x33138808),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: BuyV2Colors.green,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                'Order placed',
                style: context.buyTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                '${_productCountLabel(session.confirmedItemCount)} · ${buyV2Money(session.confirmedTotal)}',
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
                  'Purchase $purchaseId',
                  style: context.buyMeta.copyWith(fontSize: 8.5),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                address == null
                    ? 'Delivery address unavailable'
                    : 'Delivering to ${address.recipient} · ${address.shortLine}',
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
          'Each delivery keeps the promise accepted at Checkout.',
          style: context.buyMeta.copyWith(fontSize: 8.5),
        ),
        const SizedBox(height: 7),
        for (final (index, order) in session.confirmedOrders.indexed) ...[
          _PlacedOrderCard(
            order: order,
            deliveryIndex: index,
            deliveryCount: session.confirmedOrders.length,
            onViewInvoice: () => showBuyV2InvoicePage(
              context,
              order: order,
              downloader: invoiceDownloader,
            ),
            onTrackOrder: () => session.openTracking(order.id),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton(
          key: const ValueKey('buy-confirmation-orders'),
          onPressed: session.openOrders,
          child: const Text('View purchase in Orders'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => session.openDestination(BuyV2Destination.shop),
          child: const Text('Continue shopping'),
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
    required this.onTrackOrder,
  });

  final BuyV2Order order;
  final int deliveryIndex;
  final int deliveryCount;
  final VoidCallback onViewInvoice;
  final VoidCallback onTrackOrder;

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
                buyV2Money(order.total),
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
                                  order.lines[index].product.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.buyBody.copyWith(fontSize: 10),
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
            '${order.partner} · ${order.partnerType}',
            style: context.buyMeta.copyWith(fontSize: 8.5),
          ),
          const SizedBox(height: 2),
          Text(
            'Promised at Checkout · ${_orderPromiseSummary(order)}',
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
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    key: ValueKey('buy-confirmation-invoice-${order.id}'),
                    onPressed: onViewInvoice,
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('View invoice'),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    key: ValueKey('buy-confirmation-track-${order.id}'),
                    onPressed: onTrackOrder,
                    icon: const Icon(Icons.local_shipping_outlined, size: 18),
                    label: const Text('Track delivery'),
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
                  child: FilledButton.icon(
                    key: const ValueKey('buy-recovery-retry-availability'),
                    onPressed: session.retryCheckoutAvailability,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry availability'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const ValueKey('buy-recovery-remove-product'),
                    onPressed: session.removeCheckoutIssueProduct,
                    child: const Text('Remove from Cart'),
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
                  child: FilledButton.icon(
                    key: const ValueKey('buy-recovery-change-address'),
                    onPressed: () {
                      session.retryRecovery();
                      showBuyV2AddressSheet(context, session);
                    },
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Change address'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const ValueKey('buy-recovery-return-checkout'),
                    onPressed: session.retryRecovery,
                    child: Text(session.recoveryReturnLabel),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('buy-recovery-primary'),
                    onPressed: session.retryRecovery,
                    child: Text(session.recoveryReturnLabel),
                  ),
                ),
              if (session.canOpenRecoveryOrderHelp) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      if (session.openRecoveryOrderHelp()) {
                        onOpenOrderHelp(session.selectedOrder);
                      }
                    },
                    child: const Text('Get help'),
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
        Container(
          height: 44,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: 6),
        Container(
          height: 34,
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
                    for (final group in purchaseGroups) ...[
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Purchase $purchaseId',
                                      style: context.buyBody.copyWith(
                                        fontSize: 10.5,
                                      ),
                                    ),
                                    Text(
                                      '${group.orders.length} ${group.orders.length == 1 ? 'delivery' : 'deliveries'} · ${buyV2Money(group.orders.fold<int>(0, (total, order) => total + order.total))}',
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
                      ],
                      for (final order in group.orders)
                        Padding(
                          key: ValueKey('buy-order-row-${order.id}'),
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedDefaultTextStyle(
            duration: duration,
            curve: Curves.easeInOutCubic,
            style: TextStyle(
              color: selected ? BuyV2Colors.navy : BuyV2Colors.muted,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final order = session.selectedOrderOrNull;
    if (order == null) {
      return _MissingOrderSelection(session: session);
    }
    final products = session.productsForOrder(order);
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
                '${order.itemSummary} · ${buyV2Money(order.total)}',
                style: context.buyMeta,
              ),
              const SizedBox(height: 5),
              Text(
                '${order.partner} · ${order.partnerType}',
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
                              Text(
                                product.brand,
                                style: context.buyEyebrow.copyWith(fontSize: 8),
                              ),
                              const SizedBox(height: 2),
                              Text(product.title, style: context.buyBody),
                              const SizedBox(height: 3),
                              Text(
                                '${product.pack} · ${buyV2Money(product.price)}',
                                style: context.buyMeta,
                              ),
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
              child: FilledButton.icon(
                key: const ValueKey('buy-orders-retry'),
                onPressed: session.retryCommerce,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
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
    final accessibleText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final cards = [
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
      BuyV2PromotionCard(
        key: const ValueKey('buy-promotion-orders-medicine'),
        title: 'Medicine and wellness',
        detail: 'Browse the licensed pharmacy catalogue',
        icon: Icons.local_pharmacy_outlined,
        accent: BuyV2Colors.royal,
        sequenceIndex: 2,
        onTap: () => session.openDestination(BuyV2Destination.medicine),
      ),
    ];
    return SizedBox(
      key: const ValueKey('buy-orders-promotions'),
      height: accessibleText ? 108 : 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) => cards[index],
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
                      icon: Icons.location_on_outlined,
                      label: 'Delivering to',
                      value: order.destinationLabel,
                    ),
                    _OrderDeliveryFact(
                      icon: Icons.schedule_outlined,
                      label: 'Delivery window',
                      value: _orderPromiseSummary(order),
                    ),
                    _OrderDeliveryFact(
                      icon: Icons.local_shipping_outlined,
                      label: 'Delivery partner',
                      value: order.deliveryPartnerName ?? 'Not assigned yet',
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
          if (snapshot.rescheduleSlots.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Choose a new delivery time', style: context.buyBody),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final slot in snapshot.rescheduleSlots)
                  ChoiceChip(
                    key: ValueKey('buy-delivery-slot-$slot'),
                    label: Text(slot),
                    selected: selectedSlot == slot,
                    onSelected: busy
                        ? null
                        : (_) => session.chooseDeliveryRescheduleSlot(
                            order.id,
                            slot,
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: BuyV2Metrics.minimumTap,
              child: FilledButton(
                key: const ValueKey('buy-delivery-confirm-reschedule'),
                onPressed: busy || selectedSlot == null
                    ? null
                    : () => session.confirmDeliveryReschedule(order.id),
                child: const Text('Confirm new time'),
              ),
            ),
          ],
          if (kind == BuyV2DeliveryExceptionKind.proofOfDeliveryAvailable) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: BuyV2Metrics.minimumTap,
              child: OutlinedButton(
                key: const ValueKey('buy-delivery-dispute-proof'),
                onPressed: busy
                    ? null
                    : () => session.disputeProofOfDelivery(order.id),
                child: const Text('Report a delivery problem'),
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
    final amountDue = result?.amountDue ?? order.balanceDue;
    final dueLabel = result?.dueLabel ?? order.balanceDueLabel ?? 'Due later';
    final statusLabel = switch (state) {
      BuyV2BalancePaymentState.upcoming => 'Upcoming balance',
      BuyV2BalancePaymentState.due => 'Balance due',
      BuyV2BalancePaymentState.overdue => 'Balance overdue',
      BuyV2BalancePaymentState.paymentActionRequired => 'Ready for payment',
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
            result?.customerMessage ??
                'Payment becomes available when the supplier confirms it is due.',
            style: context.buyMeta.copyWith(fontSize: 8.5),
          ),
          if (action != null && actionLabel != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: BuyV2Metrics.minimumTap,
              child: FilledButton(
                key: ValueKey(
                  'buy-tracking-balance-${actionLabel.toLowerCase().replaceAll(' ', '-')}',
                ),
                onPressed: busy ? null : action,
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
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
  });

  final BuyV2Session session;
  final ValueChanged<BuyV2Order> onOpenOrderHelp;
  final BuyV2InvoiceDownloader? invoiceDownloader;
  final BuyV2PaymentHandoff? paymentHandoff;

  @override
  Widget build(BuildContext context) {
    final order = session.selectedOrderOrNull;
    if (order == null) {
      return _MissingOrderSelection(session: session);
    }
    final returnToOrders = IntrinsicWidth(
      child: _ReturnAffordance(
        key: const ValueKey('buy-tracking-return-orders'),
        label: 'Orders',
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
    final currentStatus = Semantics(
      label: 'Current order status: ${_trackingStatusLabel(order.status)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: BuyV2Colors.softGreen,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: BuyV2Colors.green,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 8, height: 8),
            ),
            SizedBox(width: 5),
            Text(
              'CURRENT',
              style: TextStyle(
                color: BuyV2Colors.green,
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
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 10),
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
                  Row(
                    children: [
                      returnToOrders,
                      const Spacer(),
                      refreshOrder,
                      const SizedBox(width: 4),
                      currentStatus,
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
            gradient: const LinearGradient(
              colors: [Color(0xFF10085F), BuyV2Colors.navy],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                        color: BuyV2Colors.orange,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${(order.progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                _orderPromiseSummary(order),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (order.updatedDeliveryEstimate case final estimate?) ...[
                const SizedBox(height: 2),
                Text(
                  'Delayed · new estimate $estimate',
                  style: const TextStyle(
                    color: BuyV2Colors.orange,
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
                  backgroundColor: Colors.white24,
                  valueColor: BuyV2Colors.orange,
                  indicatorKey: const ValueKey('buy-tracking-progress'),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _trackingNextStep(order.status),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (session.deliveryExceptionAdapter != null) ...[
          _DeliveryExceptionCard(session: session, order: order),
          const SizedBox(height: 6),
        ],
        _DecisionPanel(
          title: 'Fulfilment',
          children: [
            _DecisionRow(
              icon: Icons.storefront_outlined,
              label: order.partnerType,
              value: order.partner,
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
              value:
                  order.deliveryPartnerName ??
                  (order.status == BuyV2OrderStatus.preparing ||
                          order.status == BuyV2OrderStatus.confirmed
                      ? 'Not assigned yet'
                      : 'Details unavailable · Refresh order'),
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
              value: order.itemSummary,
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
            if (order.balanceDue > 0)
              _DecisionRow(
                icon: Icons.event_available_outlined,
                label: 'Balance due',
                value:
                    '${buyV2Money(order.balanceDue)} · '
                    '${order.balanceDueLabel ?? 'Due later'}',
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
        Row(
          children: [
            Expanded(
              child: _TrackingAction(
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
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _TrackingAction(
                onPressed: () => session.openOrderItems(order.id),
                icon: Icons.inventory_2_outlined,
                label: 'Items',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _TrackingAction(
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
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: BuyV2Metrics.minimumTap,
          child: OutlinedButton.icon(
            key: ValueKey('buy-tracking-manage-order-${order.id}'),
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
        ),
        const SizedBox(height: 6),
        if (order.invoiceAvailable)
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              key: ValueKey('buy-tracking-invoice-${order.id}'),
              onPressed: () => showBuyV2InvoicePage(
                context,
                order: order,
                downloader: invoiceDownloader,
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('View invoice'),
            ),
          )
        else
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

  @override
  void initState() {
    super.initState();
    if (widget.session.orderResolutionFor(widget.order.id) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(widget.session.refreshOrderResolution(widget.order.id));
        }
      });
    }
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
    final accepted = await widget.session.submitOrderResolution(
      orderId: widget.order.id,
      kind: kind,
      reason: reason,
    );
    if (accepted && mounted) Navigator.of(context).pop();
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
                  OutlinedButton.icon(
                    key: const ValueKey('buy-order-resolution-retry'),
                    onPressed: busy
                        ? null
                        : () => widget.session.refreshOrderResolution(
                            widget.order.id,
                          ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                  const SizedBox(height: 7),
                  FilledButton.icon(
                    key: const ValueKey('buy-order-resolution-support'),
                    onPressed: openSupport,
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Contact support'),
                  ),
                ] else ...[
                  Text('Choose what you need', style: context.buyBody),
                  const SizedBox(height: 7),
                  for (final option in options) ...[
                    _OrderResolutionOptionTile(
                      option: option,
                      selected: option.kind == selectedKind,
                      onTap: () => setState(() {
                        selectedKind = option.kind;
                        selectedReason = null;
                      }),
                    ),
                    const SizedBox(height: 7),
                  ],
                  if (selectedOption != null) ...[
                    const SizedBox(height: 3),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'buy-order-resolution-reason-${selectedOption.kind.name}',
                      ),
                      initialValue: selectedReason,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final reason in selectedOption.reasons)
                          DropdownMenuItem(
                            value: reason,
                            child: Text(
                              reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: busy
                          ? null
                          : (value) => setState(() => selectedReason = value),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      key: const ValueKey('buy-order-resolution-submit'),
                      onPressed: busy || selectedReason == null ? null : submit,
                      child: Text(busy ? 'Sending…' : 'Submit request'),
                    ),
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
                    onPressed: openSupport,
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Contact support instead'),
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
        constraints: const BoxConstraints(minHeight: 58),
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B075D), BuyV2Colors.royal],
            ),
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
                    color: Colors.white.withValues(alpha: .22),
                  ),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: Colors.white,
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
                        color: Colors.white,
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
                        color: Colors.white.withValues(alpha: .78),
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
                          color: Colors.white,
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
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  maximumSize: const Size(44, 44),
                  backgroundColor: _composerController.text.trim().isEmpty
                      ? BuyV2Colors.canvas
                      : BuyV2Colors.navy,
                  foregroundColor: _composerController.text.trim().isEmpty
                      ? BuyV2Colors.muted
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final vertical = accessibleText || constraints.maxWidth < 330;
            final chat = _AssistChannel(
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
            );
            final call = _AssistChannel(
              icon: Icons.phone_outlined,
              title: 'Call in app',
              detail: 'Speak securely here',
              onTap: () {
                HapticFeedback.selectionClick();
                session.showNotice('In-app support call selected.');
              },
            );
            if (vertical) {
              return Column(children: [chat, const SizedBox(height: 7), call]);
            }
            return Row(
              children: [
                Expanded(child: chat),
                const SizedBox(width: 8),
                Expanded(child: call),
              ],
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
            gradient: const LinearGradient(
              colors: [Color(0xFF0B075D), BuyV2Colors.navy],
            ),
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
          title: 'Wholesale workspace',
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
      ('fast', 'Fast delivery', 'Nearby fulfilment first'),
      ('today', 'Delivered today', 'Confirmed same-day listings'),
      (
        'quick-local',
        'Quick local delivery',
        'Nearby rider fulfilment with a confirmed short delivery window',
      ),
      (
        'standard-courier',
        'Standard/courier delivery',
        'Scheduled local or remote delivery with a confirmed date or window',
      ),
      ('lowest', 'Lowest delivered price', 'Price including delivery'),
      ('nearby', 'Nearby sellers', 'Local Mool fulfilment partners'),
      ('returns', 'Easy returns', 'Listings with a clear return option'),
    ],
    BuyV2Destination.wholesale => const [
      ('any', 'Any delivery schedule', 'Show every confirmed trade listing'),
      ('fast', 'Fastest delivery', 'Earliest confirmed dispatch first'),
      ('two-days', 'Within two days', 'Nearby and priority supply'),
      (
        'bulk-freight',
        'Bulk freight',
        'Tracked Wholesale delivery for MOQ and bulk loads',
      ),
      ('lowest', 'Lowest landed price', 'Product and freight together'),
      ('freight', 'Freight included', 'Delivered price without hidden freight'),
      ('moq', 'Flexible MOQ', 'Lower minimum-order listings'),
      ('manufacturer', 'Manufacturer direct', 'Mool manufacturer partners'),
    ],
    BuyV2Destination.medicine => const [
      ('any', 'Any delivery time', 'Show every available health product'),
      ('fast', 'Fastest pharmacy delivery', 'Nearby licensed pharmacies'),
      ('today', 'Delivered today', 'Confirmed same-day medicine supply'),
      ('lowest', 'Lowest delivered price', 'Price including delivery'),
      ('otc', 'No prescription required', 'Listed non-prescription products'),
      ('nearby', 'Nearby pharmacy', 'Licensed local fulfilment partners'),
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
                          await _showBuyV2DiscoveryRefinementSheet(
                            context,
                            session,
                            destination,
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

Future<void> _showBuyV2DiscoveryRefinementSheet(
  BuildContext context,
  BuyV2Session session,
  BuyV2Destination destination,
) async {
  if (session.destination != destination ||
      destination == BuyV2Destination.orders) {
    return;
  }
  final deliveryModes = switch (destination) {
    BuyV2Destination.shop => const [
      BuyV2FulfilmentMode.quickLocal,
      BuyV2FulfilmentMode.standardCourier,
    ],
    BuyV2Destination.wholesale => const [BuyV2FulfilmentMode.bulkFreight],
    BuyV2Destination.medicine => const [BuyV2FulfilmentMode.standardCourier],
    BuyV2Destination.orders => const <BuyV2FulfilmentMode>[],
  };
  final packFilters = switch (destination) {
    BuyV2Destination.shop || BuyV2Destination.medicine => const [
      BuyV2PackFilter.standard,
      BuyV2PackFilter.multipack,
    ],
    BuyV2Destination.wholesale => const [BuyV2PackFilter.bulk],
    BuyV2Destination.orders => const <BuyV2PackFilter>[],
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
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        void update(VoidCallback action) {
          action();
          setSheetState(() {});
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
                              'Sort and refine',
                              key: const ValueKey(
                                'buy-discovery-refinement-title',
                              ),
                              style: sheetContext.buyTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${session.visibleProducts.length} products match your choices',
                              style: sheetContext.buyMeta,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('buy-discovery-refinement-close'),
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
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      _DiscoveryRefinementSection(
                        title: 'Sort by',
                        children: [
                          for (final sort in BuyV2ProductSort.values)
                            ChoiceChip(
                              key: ValueKey('buy-sort-${sort.name}'),
                              label: Text(_buyV2ProductSortLabel(sort)),
                              selected: session.productSort == sort,
                              onSelected: (_) =>
                                  update(() => session.chooseProductSort(sort)),
                            ),
                        ],
                      ),
                      _DiscoveryRefinementSection(
                        title: 'Delivery',
                        children: [
                          ChoiceChip(
                            key: const ValueKey('buy-refine-delivery-any'),
                            label: const Text('Any delivery'),
                            selected: session.selectedFulfilmentMode == null,
                            onSelected: (_) => update(
                              () => session.chooseFulfilmentMode(null),
                            ),
                          ),
                          for (final mode in deliveryModes)
                            ChoiceChip(
                              key: ValueKey('buy-refine-delivery-${mode.name}'),
                              label: Text(buyV2FulfilmentModeLabel(mode)),
                              selected: session.selectedFulfilmentMode == mode,
                              onSelected: (_) => update(
                                () => session.chooseFulfilmentMode(mode),
                              ),
                            ),
                        ],
                      ),
                      _DiscoveryRefinementSection(
                        title: 'Price',
                        children: [
                          ChoiceChip(
                            key: const ValueKey('buy-refine-price-any'),
                            label: const Text('Any price'),
                            selected: session.maximumProductPrice == null,
                            onSelected: (_) => update(
                              () => session.chooseMaximumProductPrice(null),
                            ),
                          ),
                          for (final limit in session.discoveryPriceLimits)
                            ChoiceChip(
                              key: ValueKey('buy-refine-price-$limit'),
                              label: Text('Up to ${buyV2Money(limit)}'),
                              selected: session.maximumProductPrice == limit,
                              onSelected: (_) => update(
                                () => session.chooseMaximumProductPrice(limit),
                              ),
                            ),
                        ],
                      ),
                      _DiscoveryRefinementSection(
                        title: 'Pack',
                        children: [
                          ChoiceChip(
                            key: const ValueKey('buy-refine-pack-any'),
                            label: const Text('Any pack'),
                            selected: session.selectedPackFilter == null,
                            onSelected: (_) =>
                                update(() => session.choosePackFilter(null)),
                          ),
                          for (final filter in packFilters)
                            ChoiceChip(
                              key: ValueKey('buy-refine-pack-${filter.name}'),
                              label: Text(_buyV2PackFilterLabel(filter)),
                              selected: session.selectedPackFilter == filter,
                              onSelected: (_) => update(
                                () => session.choosePackFilter(filter),
                              ),
                            ),
                        ],
                      ),
                      if (session.discoveryBrands.isNotEmpty)
                        _DiscoveryRefinementSection(
                          title: 'Brand',
                          children: [
                            for (final brand in session.discoveryBrands)
                              FilterChip(
                                key: ValueKey(
                                  'buy-refine-brand-${brand.toLowerCase().replaceAll(' ', '-')}',
                                ),
                                label: Text(brand),
                                selected: session.selectedBrands.contains(
                                  brand,
                                ),
                                onSelected: (_) => update(
                                  () => session.toggleDiscoveryBrand(brand),
                                ),
                              ),
                          ],
                        ),
                      Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: BuyV2Colors.line),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SwitchListTile.adaptive(
                          key: const ValueKey('buy-refine-available-products'),
                          title: const Text('Available products only'),
                          subtitle: const Text(
                            'Hide products that cannot be added right now',
                          ),
                          value: session.availableProductsOnly,
                          onChanged: (value) => update(
                            () => session.setAvailableProductsOnly(value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: BuyV2Colors.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('buy-discovery-refinement-clear'),
                          onPressed: session.activeDiscoveryRefinementCount == 0
                              ? null
                              : () => update(session.clearDiscoveryRefinements),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          key: const ValueKey('buy-discovery-refinement-done'),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: Text(
                            'Show ${session.visibleProducts.length} products',
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
  );
}

class _DiscoveryRefinementSection extends StatelessWidget {
  const _DiscoveryRefinementSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.buyEyebrow),
        const SizedBox(height: 8),
        Wrap(spacing: 7, runSpacing: 7, children: children),
      ],
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
        color: selected ? BuyV2Colors.softBlue : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? BuyV2Colors.navy : BuyV2Colors.line,
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
                      color: selected ? BuyV2Colors.navy : BuyV2Colors.softBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : Icons.tune_rounded,
                      color: selected ? Colors.white : BuyV2Colors.navy,
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
                    color: selected ? BuyV2Colors.navy : BuyV2Colors.muted,
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
  final selectedPayment = session.selectedPayment;
  final choices = [
    (
      'UPI',
      Icons.qr_code_rounded,
      'Use your preferred UPI app when you are ready to pay',
    ),
    (
      'Bank transfer',
      Icons.account_balance_outlined,
      'View transfer details during payment',
    ),
    (
      'Purchase order',
      Icons.receipt_long_outlined,
      session.purchaseOrderEligibleForCheckout
          ? 'Use your verified business Workspace for this wholesale basket'
          : 'Requires a verified business Workspace and a wholesale-only basket',
    ),
  ].where((choice) => session.availablePaymentMethods.contains(choice.$1));
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
    builder: (sheetContext) => Semantics(
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
                          'Choose how you want to pay. No payment is started here.',
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
                    selected: selectedPayment == choice.$1,
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final routeCompleted = ModalRoute.of(
                        sheetContext,
                      )?.completed;
                      Navigator.of(sheetContext).pop();
                      if (routeCompleted != null) await routeCompleted;
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
  final VoidCallback onTap;

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
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? BuyV2Colors.softBlue : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? BuyV2Colors.navy : BuyV2Colors.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('buy-payment-${choice.$1}'),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selected
                            ? BuyV2Colors.navy
                            : BuyV2Colors.softBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        choice.$2,
                        color: selected ? Colors.white : BuyV2Colors.navy,
                        size: 21,
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
                              color: BuyV2Colors.navy,
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
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      color: selected ? BuyV2Colors.green : BuyV2Colors.navy,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add your prescription',
                          key: const ValueKey('buy-prescription-sheet-title'),
                          style: sheetContext.buyTitle,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Use a saved prescription or add one for medicine matching in this session. Pharmacist review is still required before payment.',
                          style: sheetContext.buyMeta,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
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
                  ),
                ],
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
  BuyV2Session session,
) async {
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
    session.chooseAddress(addressId);
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
                              FilledButton(
                                key: const ValueKey(
                                  'buy-address-delete-confirm',
                                ),
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                                child: const Text('Remove'),
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
                child: OutlinedButton.icon(
                  key: const ValueKey('buy-address-request'),
                  onPressed: () =>
                      _showAddressRequestSheet(sheetContext, session),
                  icon: const Icon(Icons.ios_share_outlined, size: 18),
                  label: const Text('Request an address'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: BuyV2Metrics.minimumTap,
                child: FilledButton.icon(
                  key: const ValueKey('buy-address-add'),
                  onPressed: () => _showAddAddressSheet(sheetContext, session),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: const Text('Add new address'),
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
      color: selected ? BuyV2Colors.softBlue : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? BuyV2Colors.navy : BuyV2Colors.line,
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
                              color: selected
                                  ? BuyV2Colors.navy
                                  : BuyV2Colors.softBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: selected ? Colors.white : BuyV2Colors.navy,
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
                                          color: BuyV2Colors.navy,
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
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.buyMeta,
                                ),
                              ],
                            ),
                          ),
                          if (!selected) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: BuyV2Colors.navy,
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
        const SnackBar(content: Text('Address request link copied')),
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
              TextField(
                key: const ValueKey('buy-address-request-recipient'),
                controller: recipientController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Recipient name (optional)',
                  helperText: 'Helps you confirm who the request is for.',
                  helperMaxLines: 2,
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
                child: OutlinedButton(
                  key: const ValueKey('buy-address-request-enter-manually'),
                  onPressed: () =>
                      _showAddAddressSheet(context, widget.session),
                  child: const Text('Add it myself'),
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
  const _BuyV2AddAddressForm({required this.onSubmit, this.existingAddress});

  final bool Function(BuyV2Address address) onSubmit;
  final BuyV2Address? existingAddress;

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
    recipientController = TextEditingController(text: address?.recipient);
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
        18 +
        BuyV2AddressFormSheetMotion.resolveBottomSafeInset(context) +
        MediaQuery.viewInsetsOf(context).bottom;
    return Semantics(
      key: const ValueKey('buy-address-add-form-route'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: RepaintBoundary(
        key: const ValueKey('buy-address-add-form-repaint-boundary'),
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
                body: editingAddress == null
                    ? 'Save where this order should arrive.'
                    : 'Update the delivery details for this saved place.',
                closeKey: const ValueKey('buy-address-add-form-close'),
              ),
              const SizedBox(height: 12),
              Text('Address type', style: context.buyEyebrow),
              const SizedBox(height: 7),
              Wrap(
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
                      key: ValueKey('buy-address-add-kind-${option.$2}'),
                      label: Text(option.$2),
                      selected: kind == option.$1,
                      onSelected: (_) => setState(() => kind = option.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: buyV2CardDecoration(
                  color: BuyV2Colors.softBlue,
                  radius: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.pin_drop_outlined,
                      color: BuyV2Colors.navy,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Enter the complete address below. You can review it before placing the order.',
                        style: context.buyMeta.copyWith(color: BuyV2Colors.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('Delivery contact', style: context.buyEyebrow),
              const SizedBox(height: 7),
              TextField(
                key: const ValueKey('buy-address-add-recipient'),
                controller: recipientController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Recipient name'),
              ),
              const SizedBox(height: 9),
              TextField(
                key: const ValueKey('buy-address-add-phone'),
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '10-digit phone number',
                ),
              ),
              const SizedBox(height: 14),
              Text('Address details', style: context.buyEyebrow),
              const SizedBox(height: 7),
              TextField(
                key: const ValueKey('buy-address-add-line'),
                controller: lineController,
                minLines: 2,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'House, building and street',
                ),
              ),
              const SizedBox(height: 9),
              TextField(
                key: const ValueKey('buy-address-add-area'),
                controller: areaController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Area or locality',
                ),
              ),
              const SizedBox(height: 9),
              TextField(
                key: const ValueKey('buy-address-add-pin'),
                controller: pinController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '6-digit PIN code',
                ),
              ),
              const SizedBox(height: 9),
              TextField(
                key: const ValueKey('buy-address-add-landmark'),
                controller: landmarkController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nearby landmark (optional)',
                ),
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
                height: BuyV2Metrics.minimumTap,
                child: FilledButton(
                  key: const ValueKey('buy-address-add-submit'),
                  onPressed: submit,
                  child: Text(
                    editingAddress == null
                        ? 'Save and deliver here'
                        : 'Save changes',
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
  });

  final String label;
  final VoidCallback onTap;
  final bool tightHitOwner;
  final Key? hitOwnerKey;
  final double minimumHeight;

  @override
  Widget build(BuildContext context) {
    final affordance = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: BoxConstraints(minHeight: minimumHeight),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BuyV2Colors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chevron_left_rounded,
              color: BuyV2Colors.navy,
              size: 19,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: BuyV2Colors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
    if (tightHitOwner) {
      return Row(
        children: [
          Semantics(
            key: hitOwnerKey,
            container: true,
            button: true,
            label: label,
            onTap: onTap,
            child: ExcludeSemantics(child: affordance),
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
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 4),
      decoration: buyV2CardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.buyEyebrow),
          const SizedBox(height: 3),
          ...children,
        ],
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
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: BuyV2Colors.navy, size: 16),
          const SizedBox(width: 7),
          SizedBox(
            width: 72,
            child: Text(label, style: context.buyMeta.copyWith(fontSize: 8)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 9,
                height: 1.2,
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
    return BuyV2IntentDepth(
      child: Semantics(
        container: true,
        button: true,
        label: semanticLabel,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: BuyV2Metrics.minimumTap,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(icon, color: BuyV2Colors.navy, size: 16),
                      const SizedBox(width: 7),
                      SizedBox(
                        width: 72,
                        child: Text(
                          label,
                          style: context.buyMeta.copyWith(fontSize: 8),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BuyV2Colors.ink,
                                fontSize: 9,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              detail,
                              style: context.buyMeta.copyWith(fontSize: 7.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: BuyV2Colors.navy,
                        size: 18,
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
  }
}

class _ProductOwnedActionPanel extends StatelessWidget {
  const _ProductOwnedActionPanel({
    super.key,
    required this.product,
    required this.quantity,
    this.deliveryDecision,
    required this.rxBlocked,
    required this.onAdd,
    required this.onDecrease,
    required this.onIncrease,
  });

  final BuyV2Product product;
  final int quantity;
  final String? deliveryDecision;
  final bool rxBlocked;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final action = SizedBox(
      key: ValueKey('buy-product-action-slot-${product.id}'),
      width: 148,
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
                onDecrease: onDecrease,
                onIncrease: onIncrease,
              )
            : SizedBox(
                key: ValueKey('buy-product-add-shell-${product.id}'),
                width: rxBlocked ? 148 : 88,
                height: 44,
                child: Semantics(
                  container: true,
                  label: rxBlocked
                      ? 'Use prescription for ${product.title}'
                      : 'Add ${product.title} to cart',
                  button: true,
                  onTap: onAdd,
                  excludeSemantics: true,
                  child: FilledButton(
                    key: ValueKey('buy-product-primary-${product.id}'),
                    style: FilledButton.styleFrom(
                      minimumSize: Size(rxBlocked ? 148 : 88, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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
    );

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
        const SizedBox(height: 3),
        Text(
          product.unitPrice,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.buyMeta.copyWith(fontSize: 9),
        ),
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

    return Semantics(
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
    );
  }
}

class _CompactProductStepper extends StatelessWidget {
  const _CompactProductStepper({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BuyV2Colors.softBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x28000080)),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 44,
              child: IconButton(
                tooltip: 'Remove one',
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
              child: Semantics(
                label: '$quantity in cart',
                liveRegion: true,
                excludeSemantics: true,
                child: BuyV2FiniteValueTransition(
                  key: const ValueKey('buy-product-quantity-value-motion'),
                  stateKey: quantity,
                  text: '$quantity',
                  ownerSize: const Size(58, 28),
                  style: const TextStyle(
                    color: BuyV2Colors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            SizedBox.square(
              dimension: 44,
              child: IconButton(
                tooltip: 'Add one',
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
      ),
    );
  }
}

class _CartScopeBar extends StatelessWidget {
  const _CartScopeBar({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final scopes = session.cartScope == BuyV2CartScope.medicine
        ? const [BuyV2CartScope.medicine]
        : const [
            BuyV2CartScope.all,
            BuyV2CartScope.shop,
            BuyV2CartScope.wholesale,
          ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EAF3),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            for (final scope in scopes)
              Expanded(
                child: InkWell(
                  onTap: () => session.chooseCartScope(scope),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: session.cartScope == scope
                          ? BuyV2Colors.navy
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          scope.label,
                          maxLines: 1,
                          style: TextStyle(
                            color: session.cartScope == scope
                                ? Colors.white
                                : BuyV2Colors.muted,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        BuyV2FiniteValueTransition(
                          key: ValueKey(
                            'buy-cart-scope-value-motion-${scope.name}',
                          ),
                          stateKey: scope == BuyV2CartScope.all
                              ? session.cartTotal
                              : session.countForDestination(switch (scope) {
                                  BuyV2CartScope.shop => BuyV2Destination.shop,
                                  BuyV2CartScope.wholesale =>
                                    BuyV2Destination.wholesale,
                                  BuyV2CartScope.medicine =>
                                    BuyV2Destination.medicine,
                                  BuyV2CartScope.all => BuyV2Destination.shop,
                                }),
                          text: scope == BuyV2CartScope.all
                              ? buyV2Money(session.cartTotal)
                              : '${session.countForDestination(switch (scope) {
                                  BuyV2CartScope.shop => BuyV2Destination.shop,
                                  BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
                                  BuyV2CartScope.medicine => BuyV2Destination.medicine,
                                  BuyV2CartScope.all => BuyV2Destination.shop,
                                })}',
                          ownerSize: const Size(60, 14),
                          style: TextStyle(
                            color: session.cartScope == scope
                                ? Colors.white
                                : BuyV2Colors.navy,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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

String _cartFamilyLabel(BuyV2Destination destination) => switch (destination) {
  BuyV2Destination.shop => 'Shop basket',
  BuyV2Destination.wholesale => 'Trade order',
  BuyV2Destination.medicine => 'Medicine order',
  BuyV2Destination.orders => 'Order',
};

String _cartItemFamilyLabel(BuyV2Destination destination) =>
    switch (destination) {
      BuyV2Destination.shop => 'Products',
      BuyV2Destination.wholesale => 'Trade packs',
      BuyV2Destination.medicine => 'Medicines',
      BuyV2Destination.orders => 'Products',
    };

String _cartRelatedTitle(BuyV2Destination destination) => switch (destination) {
  BuyV2Destination.shop => 'Complete your Shop basket',
  BuyV2Destination.wholesale => 'Complete this trade order',
  BuyV2Destination.medicine => 'More from this care category',
  BuyV2Destination.orders => 'More products',
};

String _cartSpecialTitle(BuyV2Destination destination) => switch (destination) {
  BuyV2Destination.shop => 'Special Shop offers',
  BuyV2Destination.wholesale => 'Trade offers for this order',
  BuyV2Destination.medicine => 'Medicine savings available',
  BuyV2Destination.orders => 'Special offers',
};

String _cartMoreTitle(BuyV2Destination destination) => switch (destination) {
  BuyV2Destination.shop => 'You may also like in Shop',
  BuyV2Destination.wholesale => 'More for business restocking',
  BuyV2Destination.medicine => 'More Medicine essentials',
  BuyV2Destination.orders => 'You may also like',
};

String _deliveryInstructionOwner(BuyV2Destination destination) =>
    switch (destination) {
      BuyV2Destination.shop => 'Shop delivery',
      BuyV2Destination.wholesale => 'Trade receiving',
      BuyV2Destination.medicine => 'Medicine handover',
      BuyV2Destination.orders => 'Delivery instruction',
    };

class _CartBenefitPanel extends StatelessWidget {
  const _CartBenefitPanel({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final destination = _destinationForCartScope(session.cartScope);
    final coupons = session.cartBenefits(
      kind: BuyV2CartBenefitKind.coupon,
      destination: destination,
    );
    final paymentOffers = session.cartBenefits(
      kind: BuyV2CartBenefitKind.paymentOffer,
      destination: destination,
    );
    final selectedBenefits = session.selectedCartBenefitsFor(
      destination == null ? session.cartDestinations : {destination},
    );
    final selectedCoupons = selectedBenefits
        .where((benefit) => benefit.kind == BuyV2CartBenefitKind.coupon)
        .length;
    final selectedPaymentOffers = selectedBenefits
        .where((benefit) => benefit.kind == BuyV2CartBenefitKind.paymentOffer)
        .length;
    final liveDetail = session.liveCartBenefitsEnabled
        ? switch (session.cartBenefitsLoadState) {
            BuyV2CartBenefitsLoadState.idle => 'Check current eligibility',
            BuyV2CartBenefitsLoadState.loading => 'Checking eligibility…',
            BuyV2CartBenefitsLoadState.ready => null,
            BuyV2CartBenefitsLoadState.offline => 'Offline · Retry available',
            BuyV2CartBenefitsLoadState.unavailable =>
              'Eligibility unavailable · Retry',
          }
        : null;
    return Container(
      key: const ValueKey('buy-cart-benefits'),
      padding: const EdgeInsets.all(9),
      decoration: buyV2CardDecoration(radius: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coupons and offers',
            style: context.buyTitle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 3),
          Text(
            'Coupons and payment offers stay separate.',
            style: context.buyMeta.copyWith(fontSize: 8),
          ),
          const SizedBox(height: 7),
          LayoutBuilder(
            builder: (context, constraints) {
              final entries = [
                _CartBenefitEntry(
                  key: const ValueKey('buy-cart-coupons'),
                  icon: Icons.local_offer_outlined,
                  title: 'Coupons',
                  detail:
                      liveDetail ??
                      (selectedCoupons > 0
                          ? '$selectedCoupons selected for review'
                          : coupons.isEmpty
                          ? destination == null
                                ? 'Open by Cart segment'
                                : 'No eligible ${destination.label} coupon'
                          : '${coupons.length} available'),
                  onTap: () => _openCartBenefitsPage(
                    context,
                    session: session,
                    kind: BuyV2CartBenefitKind.coupon,
                    destination: destination,
                  ),
                ),
                _CartBenefitEntry(
                  key: const ValueKey('buy-cart-payment-offers'),
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payment offers',
                  detail:
                      liveDetail ??
                      (selectedPaymentOffers > 0
                          ? '$selectedPaymentOffers selected for review'
                          : paymentOffers.isEmpty
                          ? destination == null
                                ? 'Open by Cart segment'
                                : 'No ${destination.label} payment offer'
                          : '${paymentOffers.length} available'),
                  onTap: () => _openCartBenefitsPage(
                    context,
                    session: session,
                    kind: BuyV2CartBenefitKind.paymentOffer,
                    destination: destination,
                  ),
                ),
              ];
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    entries.first,
                    const SizedBox(height: 6),
                    entries.last,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: entries.first),
                  const SizedBox(width: 7),
                  Expanded(child: entries.last),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CartBenefitEntry extends StatelessWidget {
  const _CartBenefitEntry({
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
    return Material(
      color: BuyV2Colors.softBlue,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: BuyV2Colors.navy, size: 19),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.buyBody.copyWith(fontSize: 10)),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return BuyV2FiniteValueTransition(
                          key: ValueKey('buy-cart-benefit-entry-$title-motion'),
                          stateKey: detail,
                          text: detail,
                          ownerSize: Size(constraints.maxWidth, 14),
                          textAlign: TextAlign.start,
                          style: context.buyMeta.copyWith(fontSize: 8),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: BuyV2Colors.navy,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openCartBenefitsPage(
  BuildContext context, {
  required BuyV2Session session,
  required BuyV2CartBenefitKind kind,
  required BuyV2Destination? destination,
}) {
  final destinations = const [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
    BuyV2Destination.medicine,
  ].where(session.cartDestinations.contains).toList(growable: false);
  if (destinations.isEmpty) return Future.value();
  final initialDestination =
      destination != null && destinations.contains(destination)
      ? destination
      : destinations.first;
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) => _CartBenefitsPage(
        session: session,
        destinations: destinations,
        initialDestination: initialDestination,
        initialKind: kind,
      ),
    ),
  );
}

String _cartBenefitContextLabel(BuyV2Destination destination) =>
    switch (destination) {
      BuyV2Destination.shop => 'Shop',
      BuyV2Destination.wholesale => 'Wholesale',
      BuyV2Destination.medicine => 'Medicine',
      BuyV2Destination.orders => 'Orders',
    };

String _cartBenefitStrategyLabel(BuyV2CartBenefitStrategy strategy) =>
    switch (strategy) {
      BuyV2CartBenefitStrategy.timedSale => 'Time-bound sale',
      BuyV2CartBenefitStrategy.publishedOffer => 'Published offer',
      BuyV2CartBenefitStrategy.minimumOrder => 'MOQ reward',
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

String _cartBenefitEmptyDetail(
  BuyV2Destination destination,
  BuyV2CartBenefitKind kind,
) {
  final family = _cartFamilyLabel(destination);
  return kind == BuyV2CartBenefitKind.coupon
      ? 'Nothing eligible for the current $family.'
      : 'Nothing compatible with the current $family.';
}

class _CartBenefitsPage extends StatefulWidget {
  const _CartBenefitsPage({
    required this.session,
    required this.destinations,
    required this.initialDestination,
    required this.initialKind,
  });

  final BuyV2Session session;
  final List<BuyV2Destination> destinations;
  final BuyV2Destination initialDestination;
  final BuyV2CartBenefitKind initialKind;

  @override
  State<_CartBenefitsPage> createState() => _CartBenefitsPageState();
}

class _CartBenefitsPageState extends State<_CartBenefitsPage> {
  late BuyV2Destination _destination = widget.initialDestination;
  late BuyV2CartBenefitKind _kind = widget.initialKind;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_sessionChanged);
    if (widget.session.liveCartBenefitsEnabled &&
        widget.session.cartBenefitsLoadState !=
            BuyV2CartBenefitsLoadState.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(widget.session.refreshCartBenefits());
      });
    }
  }

  void _sessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.session.removeListener(_sessionChanged);
    super.dispose();
  }

  void _completeToCart() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
  }

  void _selectDestination(BuyV2Destination destination) {
    if (_destination == destination) return;
    HapticFeedback.selectionClick();
    setState(() => _destination = destination);
  }

  void _selectKind(BuyV2CartBenefitKind kind) {
    if (_kind == kind) return;
    HapticFeedback.selectionClick();
    setState(() => _kind = kind);
  }

  @override
  Widget build(BuildContext context) {
    final spec = BuyV2ThemeSpec.resolve(_destination, BuyV2View.cart);
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
    final selectedCount = widget.session
        .selectedCartBenefitsFor(widget.destinations.toSet())
        .length;
    final completionLabel = selectedCount == 0
        ? 'Return to Cart'
        : 'Review $selectedCount '
              '${selectedCount == 1 ? 'selection' : 'selections'} in Cart';
    return BuyV2ThemeScope(
      spec: spec,
      child: Scaffold(
        key: const ValueKey('buy-cart-benefits-page'),
        backgroundColor: spec.canvas,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: BuyV2Colors.ink,
          elevation: 0,
          leading: IconButton(
            key: const ValueKey('buy-cart-benefits-back'),
            tooltip: 'Back to Cart',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          titleSpacing: 0,
          title: const Text(
            'Coupons & offers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(3),
            child: BuyV2TricolourLine(height: 3),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: BuyV2Metrics.maxWidth,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      key: ValueKey(
                        'buy-cart-benefits-list-${_destination.name}-'
                        '${_kind.name}',
                      ),
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 20),
                      children: [
                        _CartBenefitDestinationSelector(
                          session: widget.session,
                          destinations: widget.destinations,
                          selected: _destination,
                          onChanged: _selectDestination,
                        ),
                        const SizedBox(height: 5),
                        _CartBenefitKindSelector(
                          kind: _kind,
                          couponCount: coupons.length,
                          paymentOfferCount: paymentOffers.length,
                          onChanged: _selectKind,
                        ),
                        const SizedBox(height: 9),
                        if (widget.session.liveCartBenefitsEnabled &&
                            widget.session.cartBenefitsLoadState !=
                                BuyV2CartBenefitsLoadState.ready)
                          _CartBenefitEligibilityState(session: widget.session)
                        else if (benefits.isEmpty)
                          BuyV2FiniteIncomingTransition(
                            key: const ValueKey(
                              'buy-cart-benefit-empty-motion',
                            ),
                            stateKey:
                                '${_destination.name}|${_kind.name}|empty',
                            child: _CartBenefitEmptyState(
                              destination: _destination,
                              kind: _kind,
                            ),
                          )
                        else ...[
                          Row(
                            key: const ValueKey(
                              'buy-cart-benefit-section-heading',
                            ),
                            children: [
                              Expanded(
                                child: Text(
                                  _kind == BuyV2CartBenefitKind.coupon
                                      ? 'Available coupons'
                                      : 'Available payment offers',
                                  style: context.buyTitle.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                '${benefits.length} for '
                                '${_cartBenefitContextLabel(_destination)}',
                                style: context.buyMeta.copyWith(fontSize: 8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          for (final benefit in benefits)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: BuyV2FiniteIncomingTransition(
                                key: ValueKey(
                                  'buy-cart-benefit-entry-motion-'
                                  '${benefit.id}',
                                ),
                                stateKey:
                                    '${_destination.name}|${_kind.name}|'
                                    '${benefit.id}',
                                child: _CartBenefitCard(
                                  benefit: benefit,
                                  selected:
                                      selected?.id == benefit.id &&
                                      selected?.sourceId == benefit.sourceId,
                                  onSelect: () {
                                    HapticFeedback.selectionClick();
                                    widget.session.chooseCartBenefit(benefit);
                                    setState(() {});
                                  },
                                  onRemove: () {
                                    HapticFeedback.selectionClick();
                                    widget.session.removeCartBenefit(
                                      kind: benefit.kind,
                                      destination: benefit.destination,
                                    );
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            key: const ValueKey('buy-cart-benefit-completion-bar'),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: BuyV2Colors.line)),
            ),
            child: SizedBox(
              height: BuyV2Metrics.minimumTap,
              child: BuyV2IntentDepth(
                key: const ValueKey('buy-cart-benefit-completion-depth'),
                spatial: true,
                child: FilledButton(
                  key: const ValueKey('buy-cart-benefit-completion'),
                  onPressed: _completeToCart,
                  style: FilledButton.styleFrom(
                    backgroundColor: BuyV2Colors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    key: const ValueKey(
                      'buy-cart-benefit-completion-label-motion',
                    ),
                    duration: BuyV2Motion.resolved(
                      context,
                      BuyV2Motion.selection,
                    ),
                    child: FittedBox(
                      key: ValueKey(
                        'buy-cart-benefit-completion-label-$selectedCount',
                      ),
                      fit: BoxFit.scaleDown,
                      child: Text(
                        completionLabel,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
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
                '${_cartBenefitContextLabel(destination)} offers, '
                '${_productCountLabel(session.countForDestination(destination))}, '
                '${buyV2Money(session.totalForDestination(destination))}',
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
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected == destination
                          ? BuyV2Colors.navy.withValues(alpha: .32)
                          : BuyV2Colors.line,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${_cartBenefitContextLabel(destination)} · '
                      '${buyV2Money(session.totalForDestination(destination))}',
                      maxLines: 1,
                      style: TextStyle(
                        color: selected == destination
                            ? BuyV2Colors.navy
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
    return Container(
      key: const ValueKey('buy-cart-benefit-kind-selector'),
      height: BuyV2Metrics.minimumTap,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAF3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CartBenefitKindButton(
              key: const ValueKey('buy-cart-benefit-kind-coupon'),
              selected: kind == BuyV2CartBenefitKind.coupon,
              label: 'Coupons',
              count: couponCount,
              onTap: () => onChanged(BuyV2CartBenefitKind.coupon),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _CartBenefitKindButton(
              key: const ValueKey('buy-cart-benefit-kind-payment'),
              selected: kind == BuyV2CartBenefitKind.paymentOffer,
              label: 'Payment offers',
              count: paymentOfferCount,
              onTap: () => onChanged(BuyV2CartBenefitKind.paymentOffer),
            ),
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
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      animationDuration: BuyV2Motion.resolved(context, BuyV2Motion.selection),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: BuyV2Metrics.minimumTap,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              count == 0 ? label : '$label ($count)',
              maxLines: 1,
              style: TextStyle(
                color: selected ? BuyV2Colors.navy : BuyV2Colors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
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
    final spec = BuyV2ThemeScope.of(context);
    return Container(
      key: ValueKey('buy-cart-${kind.name}-empty-${destination.name}'),
      constraints: const BoxConstraints(maxHeight: 100),
      padding: const EdgeInsets.all(11),
      decoration: buyV2CardDecoration(radius: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: spec.softAccent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              kind == BuyV2CartBenefitKind.coupon
                  ? Icons.local_offer_outlined
                  : Icons.account_balance_wallet_outlined,
              color: BuyV2Colors.navy,
              size: 20,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cartBenefitEmptyTitle(destination, kind),
                  style: context.buyTitle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  _cartBenefitEmptyDetail(destination, kind),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.buyMeta.copyWith(fontSize: 9),
                ),
              ],
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
    required this.selected,
    required this.onSelect,
    required this.onRemove,
  });

  final BuyV2CartBenefit benefit;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final spec = BuyV2ThemeScope.of(context);
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

    return AnimatedContainer(
      key: ValueKey('buy-cart-benefit-${benefit.id}'),
      duration: BuyV2Motion.resolved(context, BuyV2Motion.selection),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 8),
      decoration: buyV2CardDecoration(radius: 14).copyWith(
        border: Border.all(
          color: selected
              ? BuyV2Colors.green.withValues(alpha: .45)
              : BuyV2Colors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: spec.softAccent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  benefit.kind == BuyV2CartBenefitKind.coupon
                      ? Icons.local_offer_outlined
                      : Icons.account_balance_wallet_outlined,
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
                      benefit.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.buyBody.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      benefit.detail,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.buyMeta.copyWith(fontSize: 8.5),
                    ),
                    if (hasCampaignDetails) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${_cartBenefitStrategyLabel(benefit.strategy)} · '
                        '${_cartBenefitSponsorLabel(benefit)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyMeta.copyWith(
                          color: BuyV2Colors.navy,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
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
                            'Save ${buyV2Money(benefit.savingAmount)} now',
                          if (benefit.freeDelivery) 'Free delivery',
                          if (benefit.minimumSpend case final minimumSpend?)
                            'Minimum order ${buyV2Money(minimumSpend)}',
                          if (benefit.minimumQuantity
                              case final minimumQuantity?)
                            'Minimum quantity $minimumQuantity',
                          if (benefit.validUntil case final validUntil?)
                            'Ends ${MaterialLocalizations.of(context).formatMediumDate(validUntil)}',
                        ].join(' · '),
                        style: context.buyMeta.copyWith(
                          color: BuyV2Colors.green,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 72,
                height: BuyV2Metrics.minimumTap,
                child: Semantics(
                  key: ValueKey(
                    'buy-cart-benefit-'
                    '${selected ? 'remove' : 'select'}-${benefit.id}',
                  ),
                  label: '${selected ? 'Remove' : 'Select'} ${benefit.title}',
                  button: true,
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
                        key: ValueKey(
                          'buy-cart-benefit-action-motion-${benefit.id}',
                        ),
                        duration: BuyV2Motion.resolved(
                          context,
                          BuyV2Motion.selection,
                        ),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : BuyV2Colors.navy.withValues(alpha: .38),
                          ),
                        ),
                        child: BuyV2FiniteIncomingTransition(
                          key: ValueKey(
                            'buy-cart-benefit-action-visual-${benefit.id}',
                          ),
                          stateKey: selected,
                          duration: BuyV2Motion.stateChange,
                          child: Text(
                            selected ? 'Remove' : 'Select',
                            style: TextStyle(
                              color: selected
                                  ? BuyV2Colors.muted
                                  : BuyV2Colors.navy,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LayoutBuilder(
            builder: (context, constraints) {
              final visual = BuyV2FiniteVisualTransition(
                key: ValueKey('buy-cart-benefit-status-motion-${benefit.id}'),
                stateKey: selected,
                ownerSize: Size(constraints.maxWidth, 20),
                alignment: Alignment.centerLeft,
                child: ExcludeSemantics(
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 47),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: BuyV2Colors.green,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  benefit.kind == BuyV2CartBenefitKind.coupon &&
                                          benefit.savingAmount > 0
                                      ? 'Applied to Cart total'
                                      : 'Selected for Checkout review',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.buyMeta.copyWith(
                                    color: BuyV2Colors.green,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
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
                label:
                    benefit.kind == BuyV2CartBenefitKind.coupon &&
                        benefit.savingAmount > 0
                    ? 'Applied to Cart total'
                    : 'Selected for Checkout review',
                excludeSemantics: true,
                child: visual,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CartDiscoverySections extends StatelessWidget {
  const _CartDiscoverySections({
    required this.session,
    required this.destinations,
  });

  final BuyV2Session session;
  final List<BuyV2Destination> destinations;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    for (final destination in destinations) {
      final special = session.cartRecommendationsFor(
        destination,
        specialOffersOnly: true,
      );
      final specialIds = special.map((product) => product.id).toSet();
      final related = session.cartRecommendationsFor(
        destination,
        excludedProductIds: specialIds,
      );
      final usedIds = {...specialIds, ...related.map((product) => product.id)};
      final more = session.cartRecommendationsFor(
        destination,
        excludedProductIds: usedIds,
      );
      if (related.isNotEmpty) {
        sections.add(
          _CartProductLane(
            session: session,
            destination: destination,
            laneId: 'related',
            title: _cartRelatedTitle(destination),
            detail:
                'Deals from ${buyV2Money(related.map((product) => product.price).reduce((left, right) => left < right ? left : right))}',
            products: related,
          ),
        );
      }
      if (special.isNotEmpty) {
        sections.add(
          _CartProductLane(
            session: session,
            destination: destination,
            laneId: 'special',
            title: _cartSpecialTitle(destination),
            detail:
                'Available offers for this ${_cartFamilyLabel(destination).toLowerCase()}',
            products: special,
          ),
        );
      }
      if (more.isNotEmpty) {
        sections.add(
          _CartProductLane(
            session: session,
            destination: destination,
            laneId: 'more',
            title: _cartMoreTitle(destination),
            detail: destination == BuyV2Destination.medicine
                ? 'From the Medicine catalogue · not medical advice'
                : 'More from the ${destination.label} catalogue',
            products: more,
          ),
        );
      }
    }
    if (sections.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final section in sections) ...[
          section,
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CartProductLane extends StatelessWidget {
  const _CartProductLane({
    required this.session,
    required this.destination,
    required this.laneId,
    required this.title,
    required this.detail,
    required this.products,
  });

  final BuyV2Session session;
  final BuyV2Destination destination;
  final String laneId;
  final String title;
  final String detail;
  final List<BuyV2Product> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('buy-cart-$laneId-${destination.name}'),
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
      decoration: buyV2CardDecoration(radius: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.buyTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 2),
          Text(detail, style: context.buyMeta.copyWith(fontSize: 8)),
          const SizedBox(height: 7),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 7),
              itemBuilder: (context, index) => _CartRecommendationCard(
                session: session,
                product: products[index],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartRecommendationCard extends StatelessWidget {
  const _CartRecommendationCard({required this.session, required this.product});

  final BuyV2Session session;
  final BuyV2Product product;

  @override
  Widget build(BuildContext context) {
    final hasSaving = product.mrp != null && product.mrp! > product.price;
    return SizedBox(
      width: 132,
      child: Material(
        color: BuyV2Colors.canvas,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          key: ValueKey('buy-cart-recommendation-${product.id}'),
          onTap: () => session.openProduct(product.id),
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 82,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: BuyV2ProductPackshot(
                          product: product,
                          borderRadius: 10,
                        ),
                      ),
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 92),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: BuyV2Colors.green,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            product.badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.buyBody.copyWith(fontSize: 9, height: 1.05),
                ),
                const SizedBox(height: 2),
                Text(
                  product.pack,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.buyMeta.copyWith(fontSize: 7.5),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            buyV2Money(product.price),
                            style: const TextStyle(
                              color: BuyV2Colors.navy,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (hasSaving)
                            Text(
                              buyV2Money(product.mrp!),
                              style: context.buyMeta.copyWith(
                                fontSize: 7,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton.outlined(
                        key: ValueKey('buy-cart-add-${product.id}'),
                        tooltip: 'Add ${product.title}',
                        onPressed: () {
                          final added = session.addProduct(product.id);
                          if (!added &&
                              session.pendingPrescriptionProductId ==
                                  product.id) {
                            showBuyV2PrescriptionSheet(context, session);
                          }
                        },
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add_rounded, size: 20),
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

class _CartDeliveryInstructionSections extends StatelessWidget {
  const _CartDeliveryInstructionSections({
    required this.session,
    required this.destinations,
  });

  final BuyV2Session session;
  final List<BuyV2Destination> destinations;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final destination in destinations) ...[
          _CartDeliveryInstructionCard(
            session: session,
            destination: destination,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CartDeliveryInstructionCard extends StatelessWidget {
  const _CartDeliveryInstructionCard({
    required this.session,
    required this.destination,
  });

  final BuyV2Session session;
  final BuyV2Destination destination;

  @override
  Widget build(BuildContext context) {
    final options = session.deliveryInstructionsFor(destination);
    final selected = session.selectedDeliveryInstructionFor(destination);
    return Container(
      key: ValueKey('buy-cart-delivery-instructions-${destination.name}'),
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
      decoration: buyV2CardDecoration(
        color: destination == BuyV2Destination.wholesale
            ? const Color(0xFFF0F8F3)
            : BuyV2Colors.softBlue,
        radius: 15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _deliveryInstructionOwner(destination),
            style: context.buyTitle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            destination == BuyV2Destination.wholesale
                ? 'Choose one instruction for business receiving.'
                : 'Choose one instruction for this delivery.',
            style: context.buyMeta.copyWith(fontSize: 8),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selected?.id == option.id;
                return Material(
                  color: isSelected ? BuyV2Colors.navy : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    key: ValueKey(
                      'buy-cart-instruction-${destination.name}-${option.id}',
                    ),
                    onTap: () => session.chooseDeliveryInstruction(
                      destination: destination,
                      instructionId: isSelected ? null : option.id,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 138,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _deliveryInstructionIcon(option.id),
                            color: isSelected ? Colors.white : BuyV2Colors.navy,
                            size: 18,
                          ),
                          const Spacer(),
                          Text(
                            option.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : BuyV2Colors.ink,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

IconData _deliveryInstructionIcon(String id) {
  if (id.contains('security')) return Icons.shield_outlined;
  if (id.contains('door')) return Icons.door_front_door_outlined;
  if (id.contains('bell')) return Icons.notifications_off_outlined;
  if (id.contains('loading')) return Icons.local_shipping_outlined;
  if (id.contains('cartons')) return Icons.inventory_2_outlined;
  if (id.contains('receiving')) return Icons.store_mall_directory_outlined;
  if (id.contains('hand') || id.contains('unattended')) {
    return Icons.person_pin_circle_outlined;
  }
  return Icons.phone_in_talk_outlined;
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
            '${group.partner} · optional for this delivery only',
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
                color: BuyV2Colors.navy,
                size: 20,
              ),
              const SizedBox(width: 7),
              Text(
                'Bill summary',
                style: context.buyTitle.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 9),
          for (final entry in familyTotals.entries)
            _CartAmountRow(
              label:
                  '${entry.key.label} ${_cartItemFamilyLabel(entry.key).toLowerCase()}',
              value: buyV2Money(entry.value),
            ),
          if (session.scopedCartSavings > 0)
            _CartAmountRow(
              label: 'Product savings',
              value: '−${buyV2Money(session.scopedCartSavings)}',
              valueColor: BuyV2Colors.green,
            ),
          if (session.scopedCouponSaving > 0)
            _CartAmountRow(
              label: 'Coupon saving',
              value: '−${buyV2Money(session.scopedCouponSaving)}',
              valueColor: BuyV2Colors.green,
            ),
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
            'Delivery charges, if any, are confirmed separately at order review.',
            style: context.buyMeta.copyWith(fontSize: 8),
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
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong ? context.buyBody : context.buyMeta,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? BuyV2Colors.navy,
              fontSize: strong ? 13 : 10,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
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
    final savings = session.scopedCartSavings;
    return Container(
      key: const ValueKey('buy-cart-savings-summary'),
      padding: const EdgeInsets.all(10),
      decoration: buyV2CardDecoration(
        color: savings > 0 ? BuyV2Colors.softGreen : BuyV2Colors.softBlue,
        border: savings > 0 ? const Color(0x33138808) : BuyV2Colors.line,
        radius: 15,
      ),
      child: Row(
        children: [
          Icon(
            savings > 0 ? Icons.savings_outlined : Icons.price_check_outlined,
            color: savings > 0 ? BuyV2Colors.green : BuyV2Colors.navy,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  savings > 0
                      ? 'You save ${buyV2Money(savings)}'
                      : 'Latest listed prices',
                  style: context.buyBody.copyWith(fontSize: 10),
                ),
                Text(
                  savings > 0
                      ? 'Calculated only from listed MRP and current product price.'
                      : 'No additional product saving is shown for these items.',
                  style: context.buyMeta.copyWith(fontSize: 8),
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
    final facts = session.productFactsFor(product);
    final wholesale = product.destination == BuyV2Destination.wholesale;
    final automaticFulfilment =
        product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale;
    final buyerPromise = automaticFulfilment
        ? buyV2BuyerDeliveryPromise(facts)
        : product.deliveryPromise;
    final productDetailsLabel = 'View ${product.title} product details';
    void openProductDetails() {
      HapticFeedback.selectionClick();
      session.openProduct(product.id);
    }

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
              constraints: const BoxConstraints(minHeight: 60),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    key: ValueKey('buy-cart-packshot-${product.id}'),
                    width: 60,
                    height: 60,
                    child: BuyV2ProductPackshot(
                      product: product,
                      borderRadius: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.buyBody,
                        ),
                        Text(
                          '${product.variant} · ${product.pack}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.buyMeta.copyWith(fontSize: 8),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          automaticFulfilment
                              ? '$buyerPromise · MoolSocial price'
                              : '${product.deliveryPromise} · ${product.seller}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BuyV2Colors.green,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 20, right: 2),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: BuyV2Colors.navy,
                    ),
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
                'Minimum order ${product.minimumOrder} packs. '
                '${buyV2Money(product.price)} per pack. ${product.unitPrice}. '
                '${product.freightIncluded ? 'Freight included in landed price.' : 'Freight confirmed before payment.'}',
            excludeSemantics: true,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: BuyV2Colors.softBlue,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MOQ ${product.minimumOrder} packs · '
                    '${buyV2Money(product.price)} per pack',
                    style: context.buyMeta.copyWith(
                      color: BuyV2Colors.navy,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.unitPrice} · '
                    '${product.freightIncluded ? 'Freight included' : 'Freight confirmed later'}',
                    style: context.buyMeta.copyWith(fontSize: 7.5),
                  ),
                ],
              ),
            ),
          )
        : null;

    final productBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        productDetails,
        if (tradeFacts != null) ...[const SizedBox(height: 5), tradeFacts],
      ],
    );

    final price = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (wholesale)
          Text(
            'Landed subtotal',
            style: context.buyMeta.copyWith(fontSize: 7.5),
          ),
        BuyV2FiniteValueTransition(
          key: ValueKey('buy-cart-line-total-motion-${product.id}'),
          stateKey: line.total,
          text: buyV2Money(line.total),
          ownerSize: const Size(78, 22),
          textAlign: TextAlign.end,
          style: const TextStyle(
            color: BuyV2Colors.navy,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (product.mrp != null && product.mrp! > product.price)
          Text(
            buyV2Money(product.mrp! * line.quantity),
            style: context.buyMeta.copyWith(
              fontSize: 8,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );

    final quantityControl = Container(
      height: 44,
      decoration: BoxDecoration(
        color: BuyV2Colors.softBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: wholesale
                ? line.quantity <= product.minimumOrder
                      ? 'Remove ${product.title} from Cart'
                      : 'Remove one trade pack'
                : 'Remove one',
            onPressed: () => session.decrease(product.id),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.remove, size: 15),
          ),
          BuyV2FiniteValueTransition(
            key: ValueKey('buy-cart-line-quantity-motion-${product.id}'),
            stateKey: line.quantity,
            text: '${line.quantity}',
            ownerSize: const Size(24, 28),
            style: const TextStyle(
              color: BuyV2Colors.navy,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            tooltip: wholesale ? 'Add one trade pack' : 'Add one',
            onPressed: () => session.increase(product.id),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.add, size: 15),
          ),
        ],
      ),
    );

    return Container(
      key: ValueKey('buy-cart-line-${product.id}'),
      padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
      decoration: buyV2CardDecoration(radius: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactWholesale =
              wholesale &&
              (constraints.maxWidth < 340 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.2);
          if (compactWholesale) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                productBody,
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: BuyV2Colors.line)),
                  ),
                  child: Row(
                    children: [price, const Spacer(), quantityControl],
                  ),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: productBody),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [price, const SizedBox(height: 5), quantityControl],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SavedAddressReminder extends StatelessWidget {
  const _SavedAddressReminder({
    required this.address,
    required this.onEdit,
    this.wholesaleReceiving = false,
  });

  final BuyV2Address address;
  final VoidCallback onEdit;
  final bool wholesaleReceiving;

  @override
  Widget build(BuildContext context) {
    final title = wholesaleReceiving
        ? 'Receiving location · ${address.label}'
        : 'Delivering to ${address.label}';
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
                  key: ValueKey(
                    wholesaleReceiving
                        ? 'buy-wholesale-checkout-receiving-location'
                        : 'buy-checkout-delivery-location',
                  ),
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
                color: BuyV2Colors.softBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: BuyV2Colors.navy, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.buyBody),
                  const SizedBox(height: 2),
                  Text(detail, style: context.buyMeta.copyWith(fontSize: 9)),
                ],
              ),
            ),
            if (action != null)
              Text(
                action!,
                style: const TextStyle(
                  color: BuyV2Colors.navy,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
    void activatePrimaryAction() {
      HapticFeedback.selectionClick();
      session.openTracking(order.id);
    }

    return BuyV2IntentDepth(
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
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
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
                          Text(order.title, style: context.buyBody),
                          Text(
                            order.itemSummary,
                            style: context.buyMeta.copyWith(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      buyV2Money(order.total),
                      style: const TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
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
                Text(
                  _orderPromiseSummary(order),
                  style: const TextStyle(
                    color: BuyV2Colors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (order.updatedDeliveryEstimate case final estimate?)
                  Text(
                    'Delayed · new estimate $estimate',
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
                  '${order.partner} · ${order.partnerType}',
                  style: context.buyMeta.copyWith(fontSize: 8),
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stackActions =
                        constraints.maxWidth < 270 ||
                        MediaQuery.textScalerOf(context).scale(10) > 12;
                    final invoiceAction = SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        key: ValueKey('buy-order-invoice-${order.id}'),
                        onPressed: () => showBuyV2InvoicePage(
                          context,
                          order: order,
                          downloader: invoiceDownloader,
                        ),
                        icon: const Icon(Icons.receipt_long_outlined, size: 17),
                        label: const Text('Invoice'),
                      ),
                    );
                    final primaryAction = SizedBox(
                      height: 44,
                      child: FilledButton(
                        key: ValueKey('buy-order-primary-${order.id}'),
                        onPressed: activatePrimaryAction,
                        child: Text(
                          order.status == BuyV2OrderStatus.delivered
                              ? 'View order'
                              : 'Track order',
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
                  child: BuyV2HonestProgressIndicator(
                    ownerId: order.id,
                    progress: order.progress,
                    statusLabel: _trackingStatusLabel(order.status),
                    isComplete: order.status == BuyV2OrderStatus.delivered,
                    minHeight: 5,
                    backgroundColor: BuyV2Colors.softBlue,
                    valueColor: BuyV2Colors.orange,
                    indicatorKey: const ValueKey('buy-tracking-route-progress'),
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
                  order.partner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.buyMeta.copyWith(fontSize: 7.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order.destinationLabel,
                maxLines: 1,
                style: context.buyMeta.copyWith(fontSize: 7.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
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

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? Colors.white : BuyV2Colors.navy;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: primary ? BuyV2Colors.navy : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: primary ? BuyV2Colors.navy : const Color(0x33000080),
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
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
    final foreground = primary ? Colors.white : BuyV2Colors.navy;
    final detailColor = primary ? Colors.white70 : context.buyMeta.color;
    return Semantics(
      button: true,
      label: '$title. $detail',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: primary ? BuyV2Colors.navy : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: primary ? BuyV2Colors.navy : const Color(0x33000080),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
    );
  }
}

class _OrderDeliveryFact extends StatelessWidget {
  const _OrderDeliveryFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: BuyV2Colors.navy, size: 16),
          const SizedBox(width: 7),
          SizedBox(
            width: 72,
            child: Text(label, style: context.buyMeta.copyWith(fontSize: 8)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: BuyV2Colors.ink,
                fontSize: 9,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
      BuyV2OrderStatus.confirmed => 2,
      BuyV2OrderStatus.dispatched || BuyV2OrderStatus.arriving => 3,
      BuyV2OrderStatus.delivered => 4,
    };
    const steps = [
      ('Confirmed', 'Seller accepted every product'),
      ('Packing', 'Items are being checked and packed'),
      ('Dispatch', 'Partner will hand over the order'),
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
                        ? 'Current'
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
                          'NOW',
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
                        color: BuyV2Colors.navy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Rx',
                        style: TextStyle(
                          color: Colors.white,
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
                        color: BuyV2Colors.navy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.note_add_outlined,
                        color: Colors.white,
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
