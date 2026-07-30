import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
import 'buy_v2_design.dart';

String _productCountLabel(int count) =>
    '$count ${count == 1 ? 'product' : 'products'}';

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

class BuyV2ProductView extends StatelessWidget {
  const BuyV2ProductView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final product = session.selectedProduct;
    if (product == null) {
      return const SizedBox.shrink();
    }
    final quantity = session.quantityFor(product.id);
    final review = session.customerReviewFor(product.id);
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
                label: product.destination.label,
                onTap: session.closeProduct,
              ),
              const SizedBox(height: 7),
              _BuyV2ProductGallery(
                key: ValueKey('buy-product-packshot-${product.id}'),
                product: product,
                media: [
                  _BuyV2ProductMediaItem(
                    label: 'Product visual',
                    child: BuyV2ProductPackshot(
                      key: const ValueKey('buy-product-gallery-image-0'),
                      product: product,
                      borderRadius: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                product.brand,
                style: context.buyEyebrow.copyWith(fontSize: 8),
              ),
              const SizedBox(height: 2),
              Text(
                product.title,
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
              Text(product.pack, style: context.buyMeta.copyWith(fontSize: 9)),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  _ProductTrustPill(
                    icon: Icons.star_rounded,
                    label: review == null
                        ? 'Be the first to review'
                        : '${review.rating}.0 · Your review',
                    color: BuyV2Colors.orange,
                  ),
                  _ProductTrustPill(
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
              const SizedBox(height: 7),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 7,
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
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 2,
                    child: Text(
                      product.unitPrice,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: context.buyMeta.copyWith(fontSize: 9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _DecisionPanel(
                title: 'Pack, delivery and seller',
                children: [
                  _DecisionRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Pack',
                    value: product.pack,
                  ),
                  _DecisionRow(
                    icon: Icons.schedule_rounded,
                    label: 'Delivery',
                    value: product.deliveryPromise,
                    valueColor: BuyV2Colors.green,
                  ),
                  _DecisionRow(
                    icon: Icons.storefront_outlined,
                    label: product.partnerRole,
                    value: product.seller,
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
              if (product.destination == BuyV2Destination.wholesale) ...[
                const SizedBox(height: 10),
                _DecisionPanel(
                  title: 'Wholesale terms',
                  children: [
                    _DecisionRow(
                      icon: Icons.layers_outlined,
                      label: 'Minimum order',
                      value: 'MOQ ${product.minimumOrder} · case packs',
                    ),
                    _DecisionRow(
                      icon: Icons.local_shipping_outlined,
                      label: 'Freight',
                      value: product.freightIncluded
                          ? 'Included in landed price'
                          : 'Confirmed before payment',
                    ),
                    const _DecisionRow(
                      icon: Icons.payments_outlined,
                      label: 'Payment',
                      value: 'UPI or bank transfer',
                    ),
                    const _DecisionRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Tax',
                      value: 'GST included · invoice provided',
                    ),
                  ],
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
              _ProductReviewsPanel(
                product: product,
                review: review,
                onReview: () =>
                    _showProductReviewSheet(context, session, product),
                onReport: () =>
                    _showProductReportSheet(context, session, product),
                reported: session.hasReportedProduct(product.id),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Container(
          key: const ValueKey('buy-product-action-bar'),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: BuyV2Colors.line)),
          ),
          child: AnimatedSwitcher(
            duration: BuyV2Motion.resolved(context, BuyV2Motion.stateChange),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: quantity > 0
                ? _LargeStepper(
                    key: ValueKey('buy-product-quantity-${product.id}'),
                    quantity: quantity,
                    onDecrease: () => session.decrease(product.id),
                    onIncrease: () => session.increase(product.id),
                  )
                : SizedBox(
                    key: ValueKey('buy-product-add-shell-${product.id}'),
                    width: double.infinity,
                    height: 44,
                    child: Semantics(
                      label: rxBlocked
                          ? 'Use prescription for ${product.title}'
                          : 'Add ${product.title} to cart',
                      button: true,
                      child: FilledButton(
                        key: ValueKey('buy-product-primary-${product.id}'),
                        onPressed: addProduct,
                        child: rxBlocked
                            ? const Text('Use prescription')
                            : const Icon(Icons.add_rounded),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _BuyV2ProductMediaItem {
  const _BuyV2ProductMediaItem({required this.label, required this.child});

  final String label;
  final Widget child;
}

class _BuyV2ProductGallery extends StatefulWidget {
  const _BuyV2ProductGallery({
    super.key,
    required this.product,
    required this.media,
  }) : assert(media.length > 0);

  final BuyV2Product product;
  final List<_BuyV2ProductMediaItem> media;

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
    final galleryHeight = (MediaQuery.sizeOf(context).height * .38).clamp(
      252.0,
      320.0,
    );
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
                      child: Semantics(
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
  final VoidCallback onReview;
  final VoidCallback onReport;
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: ValueKey('buy-review-product-${product.id}'),
                  onPressed: onReview,
                  icon: const Icon(Icons.rate_review_outlined, size: 17),
                  label: Text(review == null ? 'Write review' : 'Edit review'),
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
  var rating = existing?.rating ?? 0;
  var comment = existing?.comment ?? '';
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review ${product.title}', style: context.buyTitle),
                const SizedBox(height: 4),
                Text(
                  'Rate the product you received. Keep personal or medical information out of your review.',
                  style: context.buyMeta,
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: rating == 0
                      ? 'No rating selected'
                      : '$rating star rating selected',
                  liveRegion: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var value = 1; value <= 5; value++)
                        IconButton(
                          key: ValueKey(
                            'buy-review-rating-${product.id}-$value',
                          ),
                          tooltip: '$value stars',
                          onPressed: () => setSheetState(() => rating = value),
                          icon: Icon(
                            value <= rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: BuyV2Colors.orange,
                            size: 30,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey('buy-review-comment-${product.id}'),
                  initialValue: comment,
                  onChanged: (value) => comment = value,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Your review',
                    hintText: 'What was useful, good or needs improvement?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    key: ValueKey('buy-submit-review-${product.id}'),
                    onPressed: () {
                      if (session.submitProductReview(
                        productId: product.id,
                        rating: rating,
                        comment: comment,
                      )) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    child: const Text('Save review'),
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
  String? selectedReason;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report a product issue', style: context.buyTitle),
              const SizedBox(height: 4),
              Text(
                'Tell us which listing detail needs attention.',
                style: context.buyMeta,
              ),
              const SizedBox(height: 9),
              for (final reason in reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: SizedBox(
                    width: double.infinity,
                    child: ChoiceChip(
                      key: ValueKey(
                        'buy-report-reason-${reasons.indexOf(reason)}',
                      ),
                      selected: selectedReason == reason,
                      onSelected: (_) =>
                          setSheetState(() => selectedReason = reason),
                      showCheckmark: true,
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(reason, style: context.buyBody),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 5),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  key: ValueKey('buy-submit-report-${product.id}'),
                  onPressed: selectedReason == null
                      ? null
                      : () {
                          if (session.reportProduct(
                            productId: product.id,
                            reason: selectedReason!,
                          )) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                  child: const Text('Send report'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class BuyV2CartView extends StatelessWidget {
  const BuyV2CartView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final lines = session.cartLines;
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
                      Text(
                        '${_productCountLabel(session.itemCount)} · ${_destinationSummary(session.cartDestinations)} · ${buyV2Money(session.cartTotal)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyMeta.copyWith(fontSize: 8),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: session.clearCart,
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Color(0xFFB42318), fontSize: 10),
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
                  key: PageStorageKey('buy-cart-${session.cartScope.name}'),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    for (final destination in const [
                      BuyV2Destination.shop,
                      BuyV2Destination.medicine,
                      BuyV2Destination.wholesale,
                    ])
                      if (lines.any(
                        (line) => line.product.destination == destination,
                      )) ...[
                        _CartGroupHeader(
                          destination: destination,
                          total: lines
                              .where(
                                (line) =>
                                    line.product.destination == destination,
                              )
                              .fold(0, (sum, line) => sum + line.total),
                        ),
                        for (final line in lines.where(
                          (line) => line.product.destination == destination,
                        ))
                          _CartLine(session: session, line: line),
                        const SizedBox(height: 8),
                      ],
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
                        Text('Total', style: context.buyMeta),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            buyV2Money(session.scopedCartTotal),
                            maxLines: 1,
                            style: const TextStyle(
                              color: BuyV2Colors.navy,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: actionWidth,
                    child: FilledButton(
                      onPressed: session.openCheckout,
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

class BuyV2CheckoutView extends StatelessWidget {
  const BuyV2CheckoutView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final address = session.selectedAddress;
    final destinations = session.checkoutDestinations;
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const PageStorageKey('buy-checkout'),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            children: [
              _ReturnAffordance(label: 'Cart', onTap: session.openCart),
              const SizedBox(height: 7),
              Text(
                'Review order',
                style: context.buyTitle.copyWith(fontSize: 19),
              ),
              const SizedBox(height: 8),
              _SavedAddressReminder(
                address: address,
                onEdit: () => showBuyV2AddressSheet(context, session),
              ),
              const SizedBox(height: 9),
              for (final group in session.checkoutFulfilmentGroups) ...[
                _CheckoutCard(
                  icon: switch (group.destination) {
                    BuyV2Destination.shop => Icons.storefront_outlined,
                    BuyV2Destination.wholesale => Icons.inventory_2_outlined,
                    BuyV2Destination.medicine => Icons.medication_outlined,
                    BuyV2Destination.orders => Icons.receipt_long_outlined,
                  },
                  title:
                      '${group.destination.label} fulfilment · ${group.partner}',
                  detail:
                      '${group.partnerType} · ${_productCountLabel(group.itemCount)} · ${buyV2Money(group.total)}\n${group.promise}',
                ),
                const SizedBox(height: 7),
              ],
              const SizedBox(height: 11),
              _CheckoutCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Payment · ${session.selectedPayment}',
                detail: destinations.contains(BuyV2Destination.wholesale)
                    ? 'UPI, bank transfer or purchase order. Each order keeps its own payment record.'
                    : 'Selected payment method for this order.',
                action: 'Change',
                onTap: () => _showPaymentSheet(context, session),
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
                      _productCountLabel(session.checkoutItemCount),
                      style: context.buyMeta.copyWith(fontSize: 8),
                    ),
                    Text(
                      buyV2Money(session.checkoutTotal),
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
                  onPressed: session.confirmOrder,
                  child: const Text('Place order'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BuyV2ConfirmationView extends StatelessWidget {
  const BuyV2ConfirmationView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 3),
              Text(
                'Delivering to ${session.selectedAddress.recipient} · ${session.selectedAddress.shortLine}',
                textAlign: TextAlign.center,
                style: context.buyMeta,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final order in session.confirmedOrders) ...[
          _CheckoutCard(
            icon: switch (order.destination) {
              BuyV2Destination.shop => Icons.shopping_bag_outlined,
              BuyV2Destination.wholesale => Icons.inventory_2_outlined,
              BuyV2Destination.medicine => Icons.medication_outlined,
              BuyV2Destination.orders => Icons.receipt_long_outlined,
            },
            title: '${order.destination.label} order confirmed',
            detail: '${order.id} · ${order.partner}\n${order.promise}',
          ),
          const SizedBox(height: 8),
        ],
        FilledButton(
          key: const ValueKey('buy-confirmation-orders'),
          onPressed: session.openOrders,
          child: const Text('View orders'),
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

class BuyV2RecoveryView extends StatelessWidget {
  const BuyV2RecoveryView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final kind = session.recoveryKind ?? BuyV2RecoveryKind.networkInterruption;
    final content = switch (kind) {
      BuyV2RecoveryKind.priceUpdate => (
        Icons.price_change_outlined,
        'Price updated',
        'The latest delivered price is shown. Review it before continuing.',
        'Review updated price',
      ),
      BuyV2RecoveryKind.stockUnavailable => (
        Icons.inventory_2_outlined,
        'Stock changed',
        'One product is unavailable. Available alternatives keep the same category and delivery area.',
        'See alternatives',
      ),
      BuyV2RecoveryKind.serviceAreaUnavailable => (
        Icons.location_off_outlined,
        'Delivery area unavailable',
        'This product cannot be delivered to the selected PIN code. Change the address or choose a nearby listing.',
        'Change delivery area',
      ),
      BuyV2RecoveryKind.paymentFailed => (
        Icons.payment_outlined,
        'Payment not completed',
        'No amount was charged. Your Cart and delivery choices are unchanged.',
        'Try payment again',
      ),
      BuyV2RecoveryKind.networkInterruption => (
        Icons.wifi_off_rounded,
        'Connection interrupted',
        'Your Cart is safe. Reconnect to refresh prices, stock and delivery commitments.',
        'Try again',
      ),
      BuyV2RecoveryKind.deliveryDelay => (
        Icons.schedule_rounded,
        'Delivery time changed',
        'The fulfilment partner has shared a new delivery commitment. You can track it or get help.',
        'View latest update',
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('buy-recovery-primary'),
                  onPressed: session.retryRecovery,
                  child: Text(content.$4),
                ),
              ),
              if (kind == BuyV2RecoveryKind.deliveryDelay) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: session.openAssist,
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
  const BuyV2OrdersView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
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
                            '${session.deliveredOrderCount} delivered · '
                            'next Wed, 29 Jul',
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
              IconButton(
                key: const ValueKey('buy-orders-assist'),
                tooltip: 'MoolSocial Assist',
                onPressed: session.openAssist,
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  backgroundColor: BuyV2Colors.softBlue,
                  foregroundColor: BuyV2Colors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.chat_outlined, size: 20),
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
                  child: InkWell(
                    key: ValueKey('buy-orders-tab-${tab.name}'),
                    onTap: () => session.showOrdersTab(tab),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: session.ordersTab == tab
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tab == BuyV2OrdersTab.active ? 'Active' : 'Delivered',
                        style: TextStyle(
                          color: session.ordersTab == tab
                              ? BuyV2Colors.navy
                              : BuyV2Colors.muted,
                          fontWeight: session.ordersTab == tab
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        if (session.visibleOrders.isEmpty)
          _OrdersEmptyState(query: session.query, tab: session.ordersTab)
        else
          for (final order in session.visibleOrders)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _OrderCard(session: session, order: order),
            ),
        const SizedBox(height: 2),
        _OrdersContinuationRail(session: session),
      ],
    );
  }
}

class BuyV2OrderItemsView extends StatelessWidget {
  const BuyV2OrderItemsView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final order = session.selectedOrder;
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
      BuyV2PromotionCard(
        key: const ValueKey('buy-promotion-orders-shop'),
        title: 'Continue shopping',
        detail: 'Browse retail products in Shop',
        icon: Icons.shopping_bag_outlined,
        onTap: () => session.openDestination(BuyV2Destination.shop),
      ),
      BuyV2PromotionCard(
        key: const ValueKey('buy-promotion-orders-wholesale'),
        title: 'Restock a business',
        detail: 'Open independent Wholesale discovery',
        icon: Icons.storefront_outlined,
        accent: BuyV2Colors.green,
        onTap: () => session.openDestination(BuyV2Destination.wholesale),
      ),
      BuyV2PromotionCard(
        key: const ValueKey('buy-promotion-orders-medicine'),
        title: 'Medicine and wellness',
        detail: 'Browse the licensed pharmacy catalogue',
        icon: Icons.local_pharmacy_outlined,
        accent: BuyV2Colors.royal,
        onTap: () => session.openDestination(BuyV2Destination.medicine),
      ),
    ];
    return SizedBox(
      key: const ValueKey('buy-orders-promotions'),
      height: 90,
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

class _LiveTrackingDot extends StatefulWidget {
  const _LiveTrackingDot();

  @override
  State<_LiveTrackingDot> createState() => _LiveTrackingDotState();
}

class _LiveTrackingDotState extends State<_LiveTrackingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: .45,
    upperBound: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isCompleted && !_controller.isAnimating) {
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
    return FadeTransition(
      opacity: _controller,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: BuyV2Colors.green,
          shape: BoxShape.circle,
        ),
        child: SizedBox(width: 8, height: 8),
      ),
    );
  }
}

class BuyV2TrackingView extends StatelessWidget {
  const BuyV2TrackingView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final order = session.selectedOrder;
    return ListView(
      key: PageStorageKey('buy-tracking-${order.id}'),
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 10),
      children: [
        Row(
          children: [
            _ReturnAffordance(label: 'Orders', onTap: session.openOrders),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
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
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: BuyV2Colors.softGreen,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LiveTrackingDot(),
                  SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: BuyV2Colors.green,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                order.promise,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: order.progress),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 650),
                  builder: (context, value, _) => LinearProgressIndicator(
                    minHeight: 6,
                    value: value,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(
                      BuyV2Colors.orange,
                    ),
                  ),
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
        _DecisionPanel(
          title: 'Fulfilment',
          children: [
            _DecisionRow(
              icon: Icons.storefront_outlined,
              label: order.partnerType,
              value: order.partner,
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
          ],
        ),
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
                child: Icon(
                  session.trackingAlertsEnabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  color: BuyV2Colors.navy,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order updates', style: context.buyBody),
                    Text(
                      session.trackingAlertsEnabled
                          ? 'Live status alerts are on'
                          : 'Live status alerts are paused',
                      style: context.buyMeta.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                key: const ValueKey('buy-tracking-alerts-toggle'),
                value: session.trackingAlertsEnabled,
                onChanged: (_) {
                  HapticFeedback.selectionClick();
                  session.toggleTrackingAlerts();
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
                onPressed: () => showBuyV2AddressSheet(context, session),
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
                onPressed: order.status == BuyV2OrderStatus.delivered
                    ? () => session.reorder(order)
                    : session.openAssist,
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
      ],
    );
  }
}

class BuyV2AssistView extends StatefulWidget {
  const BuyV2AssistView({super.key, required this.session});

  final BuyV2Session session;

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
      'Question ready. Choose Chat in app to continue securely.',
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
    final order = session.orders.firstWhere(
      (item) => item.status != BuyV2OrderStatus.delivered,
      orElse: () => session.orders.first,
    );
    final accessibleText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    return ListView(
      key: const PageStorageKey('buy-assist'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      children: [
        _ReturnAffordance(
          label: session.destination == BuyV2Destination.orders
              ? 'Orders'
              : session.destination.label,
          onTap: session.destination == BuyV2Destination.orders
              ? session.openOrders
              : session.returnToCatalogue,
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
                      'Order help, chat and calls in one secure place.',
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
                        'Private in-app support',
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
                              '${order.id} · ${order.promise}',
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
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: order.progress),
                      duration: BuyV2Motion.resolved(
                        context,
                        BuyV2Motion.contentChange,
                      ),
                      builder: (context, value, _) => LinearProgressIndicator(
                        key: const ValueKey('buy-assist-order-progress'),
                        minHeight: 5,
                        value: value,
                        backgroundColor: BuyV2Colors.softBlue,
                        color: BuyV2Colors.green,
                      ),
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
            const intents = [
              ('Where is my order?', Icons.local_shipping_outlined),
              ('Change delivery', Icons.location_on_outlined),
              ('Problem with an item', Icons.inventory_2_outlined),
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
                session.showNotice('In-app support chat selected.');
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
  const BuyV2AccountView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final address = session.selectedAddress;
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
                child: const Text(
                  'DC',
                  style: TextStyle(
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
                    const Text(
                      'Dharmendra Choudhary',
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
                      '${address.phone} · Account contact',
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
          onTap: () => _showPaymentSheet(context, session),
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
          title: 'Security',
          detail: 'Sign-in and account protection',
          onTap: () => context.push('/app/account/security'),
        ),
      ],
    );
  }
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

Future<void> showBuyV2FilterSheet(BuildContext context, BuyV2Session session) {
  final options = switch (session.destination) {
    BuyV2Destination.shop => const [
      ('any', 'Any delivery time', 'Show every available product'),
      ('fast', 'Fast delivery', 'Nearby fulfilment first'),
      ('today', 'Delivered today', 'Confirmed same-day listings'),
      ('lowest', 'Lowest delivered price', 'Price including delivery'),
      ('nearby', 'Nearby sellers', 'Local Mool fulfilment partners'),
      ('returns', 'Easy returns', 'Listings with a clear return option'),
    ],
    BuyV2Destination.wholesale => const [
      ('any', 'Any delivery schedule', 'Show every confirmed trade listing'),
      ('fast', 'Fastest delivery', 'Earliest confirmed dispatch first'),
      ('two-days', 'Within two days', 'Nearby and priority supply'),
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
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .78,
      minChildSize: .45,
      maxChildSize: .92,
      builder: (context, controller) => SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey('buy-filter-list'),
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 5, 16, 18),
          children: [
            Text(
              '${session.destination.label} filters',
              style: context.buyTitle,
            ),
            const SizedBox(height: 10),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: InkWell(
                  key: ValueKey('buy-filter-${option.$1}'),
                  onTap: () {
                    session.chooseFilter(option.$1 == 'any' ? null : option.$1);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.all(12),
                    decoration: buyV2CardDecoration(radius: 15),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                (option.$1 == 'any' &&
                                        session.selectedFilter == null) ||
                                    session.selectedFilter == option.$1
                                ? BuyV2Colors.navy
                                : BuyV2Colors.softBlue,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color:
                                (option.$1 == 'any' &&
                                        session.selectedFilter == null) ||
                                    session.selectedFilter == option.$1
                                ? Colors.white
                                : BuyV2Colors.navy,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(option.$2, style: context.buyBody),
                              Text(option.$3, style: context.buyMeta),
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
          ],
        ),
      ),
    ),
  );
}

Future<void> _showPaymentSheet(BuildContext context, BuyV2Session session) {
  const choices = [
    ('UPI', Icons.qr_code_rounded, 'Pay securely in MoolSocial'),
    ('Bank transfer', Icons.account_balance_outlined, 'Account details'),
    ('Purchase order', Icons.receipt_long_outlined, 'For business workspaces'),
  ];
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment method', style: context.buyTitle),
          const SizedBox(height: 10),
          for (final choice in choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: ListTile(
                minTileHeight: 56,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: BuyV2Colors.line),
                ),
                leading: Icon(choice.$2, color: BuyV2Colors.navy),
                title: Text(
                  choice.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(choice.$3),
                trailing: session.selectedPayment == choice.$1
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: BuyV2Colors.green,
                      )
                    : null,
                onTap: () {
                  session.choosePayment(choice.$1);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
        ],
      ),
    ),
  );
}

Future<void> showBuyV2PrescriptionSheet(
  BuildContext context,
  BuyV2Session session,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          5,
          16,
          14 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add your prescription', style: context.buyTitle),
            const SizedBox(height: 4),
            Text(
              'Choose a saved prescription or add a new one. A pharmacist verifies each matched medicine before payment.',
              style: context.buyMeta,
            ),
            const SizedBox(height: 11),
            _PrescriptionChoice(
              doctor: 'Dr Meera Sharma',
              detail: 'Heart & BP · issued 08 July 2026',
              onTap: () {
                session.approveSavedPrescription('meera');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 7),
            _PrescriptionChoice(
              doctor: 'Dr Arvind Joshi',
              detail: 'Diabetes · issued 19 June 2026',
              onTap: () {
                session.approveSavedPrescription('arvind');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 7),
            InkWell(
              key: const ValueKey('buy-prescription-add-new'),
              onTap: () {
                session.attachNewPrescription();
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: buyV2CardDecoration(radius: 15),
                child: Row(
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: BuyV2Colors.navy,
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
                    const Text(
                      'Add',
                      style: TextStyle(
                        color: BuyV2Colors.navy,
                        fontWeight: FontWeight.w900,
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
  );
}

Future<void> showBuyV2AddressSheet(BuildContext context, BuyV2Session session) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          5,
          16,
          14 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery address', style: context.buyTitle),
            const SizedBox(height: 4),
            Text(
              'Choose a saved address or send an address request.',
              style: context.buyMeta,
            ),
            const SizedBox(height: 10),
            for (final address in session.addresses)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: InkWell(
                  onTap: () {
                    session.chooseAddress(address.id);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: buyV2CardDecoration(
                      radius: 15,
                      color: session.selectedAddressId == address.id
                          ? BuyV2Colors.softOrange
                          : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          address.kind == BuyV2AddressKind.home
                              ? Icons.home_outlined
                              : Icons.work_outline_rounded,
                          color: BuyV2Colors.navy,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(address.label, style: context.buyBody),
                              Text(
                                '${address.recipient} · ${address.phone}\n${address.line}, ${address.shortLine} · ${address.landmark}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: context.buyMeta,
                              ),
                            ],
                          ),
                        ),
                        if (session.selectedAddressId == address.id)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: BuyV2Colors.green,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddressRequestSheet(context, session),
                    icon: const Icon(Icons.ios_share_outlined, size: 18),
                    label: const Text('Request address'),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showAddAddressSheet(context, session),
                    icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                    label: const Text('Add address'),
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

Future<void> _showAddressRequestSheet(
  BuildContext context,
  BuyV2Session session,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request their address', style: context.buyTitle),
            const SizedBox(height: 9),
            const TextField(
              decoration: InputDecoration(labelText: 'Recipient name or phone'),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                _ShareChoice(
                  label: 'WhatsApp',
                  icon: Icons.call_outlined,
                  onTap: () => _copyAddressRequest(context, 'WhatsApp'),
                ),
                const SizedBox(width: 7),
                _ShareChoice(
                  label: 'MoolSocial',
                  icon: Icons.chat_outlined,
                  onTap: () => _copyAddressRequest(context, 'MoolSocial'),
                ),
                const SizedBox(width: 7),
                _ShareChoice(
                  label: 'Device share',
                  icon: Icons.ios_share_outlined,
                  onTap: () => _copyAddressRequest(context, 'Device share'),
                ),
              ],
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showAddAddressSheet(context, session),
                child: const Text('Enter address yourself'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showAddAddressSheet(BuildContext context, BuyV2Session session) {
  final recipientController = TextEditingController();
  final phoneController = TextEditingController();
  final lineController = TextEditingController();
  final pinController = TextEditingController();
  final areaController = TextEditingController();
  final landmarkController = TextEditingController();
  var kind = BuyV2AddressKind.home;
  var locationChoice = 'Manual';
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            5,
            16,
            18 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add address', style: context.buyTitle),
              const SizedBox(height: 9),
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
                      label: Text(option.$2),
                      selected: kind == option.$1,
                      onSelected: (_) => setSheetState(() => kind = option.$1),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  _LocationChoice(
                    label: 'Current',
                    icon: Icons.my_location_rounded,
                    selected: locationChoice == 'Current',
                    onTap: () {
                      setSheetState(() => locationChoice = 'Current');
                      areaController.text = 'Sardarpura, Jodhpur';
                      pinController.text = '342003';
                    },
                  ),
                  const SizedBox(width: 6),
                  _LocationChoice(
                    label: 'Map pin',
                    icon: Icons.map_outlined,
                    selected: locationChoice == 'Map pin',
                    onTap: () =>
                        setSheetState(() => locationChoice = 'Map pin'),
                  ),
                  const SizedBox(width: 6),
                  _LocationChoice(
                    label: 'Google',
                    icon: Icons.place_outlined,
                    selected: locationChoice == 'Google',
                    onTap: () => setSheetState(() => locationChoice = 'Google'),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              TextField(
                controller: recipientController,
                decoration: const InputDecoration(labelText: 'Recipient name'),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Recipient phone'),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: lineController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'House, street and full address',
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'PIN code'),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: TextField(
                      controller: areaController,
                      decoration: const InputDecoration(
                        labelText: 'Area or locality',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              TextField(
                controller: landmarkController,
                decoration: const InputDecoration(labelText: 'Landmark'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final recipient = recipientController.text.trim();
                    final phone = phoneController.text.trim();
                    final line = lineController.text.trim();
                    final pin = pinController.text.trim();
                    final area = areaController.text.trim();
                    final landmark = landmarkController.text.trim();
                    if (recipient.isEmpty ||
                        phone.isEmpty ||
                        line.isEmpty ||
                        pin.length != 6 ||
                        area.isEmpty ||
                        landmark.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complete every delivery detail'),
                        ),
                      );
                      return;
                    }
                    final label = switch (kind) {
                      BuyV2AddressKind.home => 'Home',
                      BuyV2AddressKind.work => 'Work',
                      BuyV2AddressKind.thirdParty => 'Third party',
                      BuyV2AddressKind.other => 'Other place',
                    };
                    session.addAddress(
                      BuyV2Address(
                        id: 'saved-${DateTime.now().microsecondsSinceEpoch}',
                        kind: kind,
                        label: label,
                        recipient: recipient,
                        phone: phone,
                        line: line,
                        area: area,
                        pinCode: pin,
                        landmark: landmark,
                      ),
                    );
                    Navigator.of(
                      context,
                    ).popUntil((route) => route is PageRoute);
                  },
                  child: const Text('Save and deliver here'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReturnAffordance extends StatelessWidget {
  const _ReturnAffordance({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
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
      ),
    );
  }
}

class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel({required this.title, required this.children});

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

class _LargeStepper extends StatelessWidget {
  const _LargeStepper({
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
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: BuyV2Colors.softBlue,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0x28000080)),
      ),
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              tooltip: 'Remove one',
              onPressed: onDecrease,
              icon: const Icon(Icons.remove),
            ),
          ),
          Text(
            '$quantity in cart',
            style: const TextStyle(
              color: BuyV2Colors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: IconButton(
              tooltip: 'Add one',
              onPressed: onIncrease,
              icon: const Icon(Icons.add),
            ),
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
    final scopes = const [
      BuyV2CartScope.all,
      BuyV2CartScope.shop,
      BuyV2CartScope.wholesale,
      BuyV2CartScope.medicine,
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
                        Text(
                          scope == BuyV2CartScope.all
                              ? buyV2Money(session.cartTotal)
                              : '${session.countForDestination(switch (scope) {
                                  BuyV2CartScope.shop => BuyV2Destination.shop,
                                  BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
                                  BuyV2CartScope.medicine => BuyV2Destination.medicine,
                                  BuyV2CartScope.all => BuyV2Destination.shop,
                                })}',
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

class _CartGroupHeader extends StatelessWidget {
  const _CartGroupHeader({required this.destination, required this.total});

  final BuyV2Destination destination;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BuyV2Colors.softOrange, Colors.white, BuyV2Colors.softGreen],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border.all(color: BuyV2Colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: destination == BuyV2Destination.wholesale
                  ? BuyV2Colors.navy
                  : BuyV2Colors.orange,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              switch (destination) {
                BuyV2Destination.shop => Icons.shopping_bag_outlined,
                BuyV2Destination.wholesale => Icons.inventory_2_outlined,
                BuyV2Destination.medicine => Icons.medication_outlined,
                BuyV2Destination.orders => Icons.receipt_long_outlined,
              },
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${destination.label} order',
              style: const TextStyle(
                color: BuyV2Colors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            buyV2Money(total),
            style: const TextStyle(
              color: BuyV2Colors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w900,
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
    return Container(
      key: ValueKey('buy-cart-line-${product.id}'),
      padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: BuyV2Colors.line),
          right: BorderSide(color: BuyV2Colors.line),
          bottom: BorderSide(color: BuyV2Colors.line),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BuyV2Colors.softBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              product.visualLabel,
              style: const TextStyle(
                color: BuyV2Colors.navy,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.buyBody,
                ),
                Text(
                  '${product.variant} · ${product.pack}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.buyMeta.copyWith(fontSize: 8),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.deliveryPromise} · ${product.seller}',
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
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                buyV2Money(line.total),
                style: const TextStyle(
                  color: BuyV2Colors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: BuyV2Colors.softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Remove one',
                      onPressed: () => session.decrease(product.id),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: const Icon(Icons.remove, size: 15),
                    ),
                    Text(
                      '${line.quantity}',
                      style: const TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add one',
                      onPressed: () => session.increase(product.id),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: const Icon(Icons.add, size: 15),
                    ),
                  ],
                ),
              ),
            ],
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
                Text(
                  'Delivering to ${address.label}',
                  style: context.buyBody.copyWith(fontSize: 10),
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
  const _OrderCard({required this.session, required this.order});

  final BuyV2Session session;
  final BuyV2Order order;

  @override
  Widget build(BuildContext context) {
    void activatePrimaryAction() {
      HapticFeedback.selectionClick();
      if (order.status == BuyV2OrderStatus.delivered) {
        session.reorder(order);
      } else {
        session.openTracking(order.id);
      }
    }

    return Material(
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
                order.promise,
                style: const TextStyle(
                  color: BuyV2Colors.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: order.progress),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 500),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE3E5EE),
                    valueColor: const AlwaysStoppedAnimation(BuyV2Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.partner} · ${order.partnerType}',
                style: context.buyMeta.copyWith(fontSize: 8),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    excludeFromSemantics: true,
                    onTap: activatePrimaryAction,
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Container(
                        height: 32,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: BuyV2Colors.navy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          order.status == BuyV2OrderStatus.delivered
                              ? 'Reorder'
                              : 'Track order',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
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
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: order.progress),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 650),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor: BuyV2Colors.softBlue,
                      valueColor: const AlwaysStoppedAnimation(
                        BuyV2Colors.orange,
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
              child: Row(
                children: [
                  Container(
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
                    child: Icon(
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
    required this.doctor,
    required this.detail,
    required this.onTap,
  });

  final String doctor;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: buyV2CardDecoration(radius: 15),
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
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor, style: context.buyBody),
                  Text(detail, style: context.buyMeta),
                  Text('Valid prescription', style: context.buyMeta),
                ],
              ),
            ),
            const Text(
              'Use',
              style: TextStyle(
                color: BuyV2Colors.green,
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

class _ShareChoice extends StatelessWidget {
  const _ShareChoice({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 66,
          alignment: Alignment.center,
          decoration: buyV2CardDecoration(radius: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: BuyV2Colors.navy),
              const SizedBox(height: 3),
              Text(
                label,
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
    );
  }
}

Future<void> _copyAddressRequest(BuildContext context, String channel) async {
  await Clipboard.setData(
    const ClipboardData(text: 'https://moolsocial.com/address/request'),
  );
  if (!context.mounted) return;
  Navigator.of(context).pop();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Address request copied for $channel')),
  );
}

class _LocationChoice extends StatelessWidget {
  const _LocationChoice({
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
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: buyV2CardDecoration(
            radius: 14,
            color: selected ? BuyV2Colors.softOrange : Colors.white,
            border: selected ? BuyV2Colors.orange : BuyV2Colors.line,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: BuyV2Colors.navy, size: 19),
              Text(
                label,
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
    );
  }
}
